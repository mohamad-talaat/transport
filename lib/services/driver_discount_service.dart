import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/discount_code_model.dart';
import '../controllers/auth_controller.dart';
import '../main.dart';

class DriverDiscountService extends GetxService {
  static DriverDiscountService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  final RxBool isLoading = false.obs;
  final RxList<DiscountCodeModel> usedDiscountCodes = <DiscountCodeModel>[].obs;

  /// استخدام كود الخصم
  Future<Map<String, dynamic>> redeemDiscountCode(String code) async {
    if (code.trim().isEmpty) {
      return {
        'success': false,
        'message': 'يرجى إدخال كود الخصم',
      };
    }

    final userId = _authController.currentUser.value?.id;
    if (userId == null) {
      return {
        'success': false,
        'message': 'يجب تسجيل الدخول أولاً',
      };
    }

    isLoading.value = true;

    try {
      // البحث عن كود الخصم في قاعدة البيانات
      final discountQuery = await _firestore
          .collection('discount_codes')
          .where('code', isEqualTo: code.toUpperCase())
          .where('isUsed', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (discountQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'كود الخصم غير صحيح أو مستخدم من قبل',
        };
      }

      final discountDoc = discountQuery.docs.first;
      final discountData = discountDoc.data();
      final discountCode =
          DiscountCodeModel.fromMap(discountData, discountDoc.id);

      // التحقق من صلاحية الكود
      if (!discountCode.isValid) {
        return {
          'success': false,
          'message': 'كود الخصم منتهي الصلاحية أو غير صالح',
        };
      }

      // التحقق من تاريخ انتهاء الصلاحية
      if (discountCode.expiryDate != null &&
          DateTime.now().isAfter(discountCode.expiryDate!)) {
        return {
          'success': false,
          'message': 'كود الخصم منتهي الصلاحية',
        };
      }

      // تحديث كود الخصم كمستخدم وتسجيل العملية في معاملة واحدة
      await _firestore.runTransaction((transaction) async {
        // تحديث كود الخصم كمستخدم
        transaction.update(discountDoc.reference, {
          'isUsed': true,
          'usedBy': userId,
          'usedAt': FieldValue.serverTimestamp(),
        });

        // تحديث رصيد السائق
        final userRef = _firestore.collection('users').doc(userId);
        final userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists) {
          throw 'المستخدم غير موجود';
        }

        final currentBalance =
            (userSnapshot.data()?['balance'] ?? 0.0).toDouble();
        final discountAmount = discountCode.discountAmount;
        final newBalance = currentBalance + discountAmount;

        transaction.update(userRef, {
          'balance': newBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // إضافة سجل العملية
        final transactionRef = _firestore.collection('transactions').doc();
        transaction.set(transactionRef, {
          'userId': userId,
          'amount': discountAmount,
          'type': 'credit',
          'status': 'completed',
          'description': 'خصم من كود: ${discountCode.code}',
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {
            'discountCode': discountCode.code,
            'discountId': discountDoc.id,
            'discountAmount': discountCode.discountAmount,
          },
        });
      });

      // تحديث الرصيد في الذاكرة
      if (_authController.currentUser.value != null) {
        _authController.currentUser.value!.balance =
            (_authController.currentUser.value!.balance ?? 0.0) +
                discountCode.discountAmount;
        _authController.currentUser.refresh();
      }

      // إضافة الكود لقائمة الأكواد المستخدمة
      usedDiscountCodes.insert(0, discountCode);
      if (usedDiscountCodes.length > 10) {
        usedDiscountCodes.removeLast();
      }

      return {
        'success': true,
        'message':
            'تم إضافة ${discountCode.discountAmount.toStringAsFixed(2)} ج.م إلى رصيدك',
        'amount': discountCode.discountAmount,
        'code': discountCode.code,
      };
    } catch (e) {
      logger.e('خطأ في استخدام كود الخصم: $e');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء استخدام كود الخصم',
      };
    } finally {
      isLoading.value = false;
    }
  }

  /// تحميل الأكواد المستخدمة
  Future<void> loadUsedDiscountCodes() async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;

    try {
      final query = await _firestore
          .collection('discount_codes')
          .where('usedBy', isEqualTo: userId)
          .orderBy('usedAt', descending: true)
          .limit(10)
          .get();

      final codes = query.docs
          .map((doc) => DiscountCodeModel.fromMap(
                doc.data(),
                doc.id,
              ))
          .toList();

      usedDiscountCodes.assignAll(codes);
    } catch (e) {
      logger.e('خطأ في تحميل الأكواد المستخدمة: $e');
    }
  }

  /// طلب كود خصم جديد
  void requestNewDiscountCode() async {
    const phoneNumber = '+201013280650'; // رقم واتساب الدعم
    const message = 'مرحباً، أريد طلب كود خصم جديد للمحفظة الإلكترونية (سائق)';

    final url = Uri.parse(
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // نسخ الرقم للحافظة
        await Clipboard.setData(const ClipboardData(text: phoneNumber));
        Get.snackbar(
          'تم نسخ الرقم',
          'تم نسخ رقم الواتساب: $phoneNumber',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر فتح واتساب. تم نسخ الرقم: $phoneNumber',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      await Clipboard.setData(const ClipboardData(text: phoneNumber));
    }
  }
}
