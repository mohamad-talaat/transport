import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/main.dart';

enum UserType { driver, rider }

class CommunicationService extends GetxService {
  static CommunicationService get to => Get.find();
  String? currentOpenChatId;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  Future<UserModel?> getOtherUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      logger.w('خطأ في الحصول على معلومات المستخدم: $e');
      return null;
    }
  }

  Future<void> makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      Get.snackbar(
        'غير متوفر',
        'رقم الهاتف غير متوفر',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      final Uri phoneUri = Uri.parse('tel:$cleanNumber');
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(
          phoneUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        await _copyPhoneNumber(cleanNumber);
      }
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);

        Get.snackbar(
          'جاري الاتصال',
          'يتم الآن الاتصال بـ $cleanNumber',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          icon: const Icon(Icons.phone, color: Colors.white),
        );
      } else {
        await _copyPhoneNumber(cleanNumber);
      }
    } catch (e) {
      logger.w('خطأ في الاتصال: $e');

      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      await _copyPhoneNumber(cleanNumber);
    }
  }

  Future<void> _copyPhoneNumber(String phoneNumber) async {
    try {
      await Clipboard.setData(ClipboardData(text: phoneNumber));

      Get.snackbar(
        'تم نسخ الرقم',
        'تم نسخ رقم الهاتف ($phoneNumber) للحافظة',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.content_copy, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر نسخ رقم الهاتف',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void openChatPage({
    required String otherUserId,
    required String otherUserName,
    required String tripId,
    UserType? currentUserType,
  }) {
    Get.toNamed('/chat', arguments: {
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'tripId': tripId,
      'currentUserType': currentUserType?.name ?? 'unknown',
    });
  }

  String createChatId(String userId1, String userId2, String tripId) {
    final userIds = [userId1, userId2]..sort();
    return '${userIds[0]}_${userIds[1]}_$tripId';
  }

  Future<bool> sendMessage({
    required String chatId,
    required String message,
    required String tripId,
  }) async {
    if (message.trim().isEmpty) return false;

    final currentUser = _authController.currentUser.value;
    if (currentUser == null) return false;

    try {
      // ✅ أولاً: حفظ الرسالة (سيشغّل Firestore Trigger تلقائياً)
      await _firestore
          .collection('trip_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': currentUser.id,
        'senderName': currentUser.name,
        'senderType': currentUser.userType.name,
        'message': message.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'tripId': tripId,
      });

      // ✅ ثانياً: تحديث lastActivity
      await _firestore.collection('trip_chats').doc(chatId).set({
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      logger.w('خطأ في إرسال الرسالة: $e');
      return false;
    }
  }

  Future<void> updateLastSeen(String chatId) async {
    final parts = chatId.split('_');
    final tripIdPart = parts.isNotEmpty ? parts.last : '';
    final currentUser = _authController.currentUser.value;
    if (currentUser == null) return;

    try {
      await _firestore.collection('trip_chats').doc(chatId).set({
        'participants': {
          currentUser.id: {
            'lastSeen': FieldValue.serverTimestamp(),
            'name': currentUser.name,
            'type':
                currentUser.userType.toString().split('.').last ?? 'unknown',
          }
        },
        'tripId': tripIdPart,
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      logger.w('خطأ في تحديث آخر ظهور: $e');
    }
  }

  Stream<int> getUnreadMessagesCount({
    required String chatId,
    required String currentUserId,
  }) {
    return _firestore
        .collection('trip_chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        final chatDoc =
            await _firestore.collection('trip_chats').doc(chatId).get();

        if (!chatDoc.exists) return 0;

        final chatData = chatDoc.data() as Map<String, dynamic>;
        final participants = chatData['participants'] as Map<String, dynamic>?;
        final lastSeen =
            participants?[currentUserId]?['lastSeen'] as Timestamp?;

        if (lastSeen == null) return snapshot.docs.length;

        return snapshot.docs.where((doc) {
          final messageTime = (doc.data()['timestamp'] as Timestamp?);
          return messageTime != null && messageTime.compareTo(lastSeen) > 0;
        }).length;
      } catch (e) {
        return 0;
      }
    });
  }
}
