import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationTestService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  static const String notificationsCollection = 'notifications';
  static const String fcmServerKey =
      'YOUR_FCM_SERVER_KEY'; // يجب استبدالها بالمفتاح الحقيقي

  // متغيرات تفاعلية
  final RxBool isSendingNotification = false.obs;
  final RxList<String> sentNotifications = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _logger.i('تم تهيئة NotificationTestService');
  }

  // ==================== إرسال التنبيهات ====================

  /// إرسال تنبيه لجميع المستخدمين
 Future<bool> sendNotificationToAllUsers({
  required String title,
  required String body,
  Map<String, dynamic>? data,
}) async {
  try {
    isSendingNotification.value = true;

    final snapshot = await _firestore
        .collection('users')
        .where('fcmToken', isNotEqualTo: null)
        .get();

    final allTokens = <String>[];
    for (var doc in snapshot.docs) {
      final token = doc.data()['fcmToken'] as String?;
      if (token != null && token.isNotEmpty) {
        allTokens.add(token);
      }
    }

    if (allTokens.isEmpty) {
      _logger.w('لا توجد FCM tokens متاحة');
      return false;
    }

    final success = await _sendFCMNotification(
      tokens: allTokens,
      title: title,
      body: body,
      data: data,
    );

    if (success) {
      await _saveNotificationToDatabase(
        title: title,
        body: body,
        data: data,
        sentToAll: true,
      );

      sentNotifications.add('تم إرسال التنبيه لـ ${allTokens.length} مستخدم');
      _logger.i('تم إرسال التنبيه لجميع المستخدمين بنجاح');
    }

    return success;
  } catch (e) {
    _logger.e('خطأ في إرسال التنبيه لجميع المستخدمين: $e');
    return false;
  } finally {
    isSendingNotification.value = false;
  }
}

  /// إرسال تنبيه لمستخدم معين
  Future<bool> sendNotificationToUser({
  required String userId,
  required String title,
  required String body,
  Map<String, dynamic>? data,
}) async {
  try {
    isSendingNotification.value = true;

    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) {
      _logger.w('لم يتم العثور على المستخدم: $userId');
      return false;
    }

    final fcmToken = doc.data()?['fcmToken'] as String?;
    if (fcmToken == null || fcmToken.isEmpty) {
      _logger.w('المستخدم لا يملك FCM token: $userId');
      return false;
    }

    final success = await _sendFCMNotification(
      tokens: [fcmToken],
      title: title,
      body: body,
      data: data,
    );

    if (success) {
      await _saveNotificationToDatabase(
        userId: userId,
        title: title,
        body: body,
        data: data,
        userType: doc.data()?['userType'],
      );

      sentNotifications.add('تم إرسال التنبيه للمستخدم: $userId');
      _logger.i('تم إرسال التنبيه للمستخدم بنجاح: $userId');
    }

    return success;
  } catch (e) {
    _logger.e('خطأ في إرسال التنبيه للمستخدم: $e');
    return false;
  } finally {
    isSendingNotification.value = false;
  }
}


  /// إرسال تنبيه لجميع السائقين
  Future<bool> sendNotificationToAllDrivers({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      isSendingNotification.value = true;

      final driversSnapshot = await _firestore
           .collection('users')
            .where('userType', isEqualTo: 'driver')
          .where('fcmToken', isNotEqualTo: null)
          .where('isActive', isEqualTo: true)
          .get();

      final tokens = <String>[];
      for (var doc in driversSnapshot.docs) {
        final token = doc.data()['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }

      if (tokens.isEmpty) {
        _logger.w('لا توجد FCM tokens متاحة للسائقين');
        return false;
      }

      final success = await _sendFCMNotification(
        tokens: tokens,
        title: title,
        body: body,
        data: data,
      );

      if (success) {
        sentNotifications.add('تم إرسال التنبيه لـ ${tokens.length} سائق');
        _logger.i('تم إرسال التنبيه لجميع السائقين بنجاح');
      }

      return success;
    } catch (e) {
      _logger.e('خطأ في إرسال التنبيه للسائقين: $e');
      return false;
    } finally {
      isSendingNotification.value = false;
    }
  }

  /// إرسال تنبيه لجميع الراكبين
  Future<bool> sendNotificationToAllRiders({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      isSendingNotification.value = true;

      final ridersSnapshot = await _firestore
           .collection('users')
            .where('userType', isEqualTo: 'rider')
          .where('fcmToken', isNotEqualTo: null)
          .where('isActive', isEqualTo: true)
          .get();

      final tokens = <String>[];
      for (var doc in ridersSnapshot.docs) {
        final token = doc.data()['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }

      if (tokens.isEmpty) {
        _logger.w('لا توجد FCM tokens متاحة للراكبين');
        return false;
      }

      final success = await _sendFCMNotification(
        tokens: tokens,
        title: title,
        body: body,
        data: data,
      );

      if (success) {
        sentNotifications.add('تم إرسال التنبيه لـ ${tokens.length} راكب');
        _logger.i('تم إرسال التنبيه لجميع الراكبين بنجاح');
      }

      return success;
    } catch (e) {
      _logger.e('خطأ في إرسال التنبيه للراكبين: $e');
      return false;
    } finally {
      isSendingNotification.value = false;
    }
  }

  // ==================== إرسال FCM ====================

  /// إرسال تنبيه عبر FCM
  Future<bool> _sendFCMNotification({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final url = Uri.parse('https://fcm.googleapis.com/fcm/send');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$fcmServerKey',
      };

      final payload = {
        'registration_ids': tokens,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
        },
        'data': data ?? {},
        'priority': 'high',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final successCount = responseData['success'] as int? ?? 0;
        final failureCount = responseData['failure'] as int? ?? 0;

        _logger.i('FCM Response: Success=$successCount, Failure=$failureCount');
        return successCount > 0;
      } else {
        _logger.e('FCM Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('خطأ في إرسال FCM: $e');
      return false;
    }
  }

  // ==================== حفظ التنبيهات ====================

  /// حفظ التنبيه في قاعدة البيانات
  Future<void> _saveNotificationToDatabase({
    String? userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    bool sentToAll = false,
    String? userType,
  }) async {
    try {
      final notificationData = {
        'title': title,
        'body': body,
        'data': data,
        'isRead': false,
        'createdAt': Timestamp.now(),
        'sentToAll': sentToAll,
        'userType': userType,
      };

      if (userId != null) {
        notificationData['userId'] = userId;
      }

      await _firestore
          .collection(notificationsCollection)
          .add(notificationData);

      _logger.i('تم حفظ التنبيه في قاعدة البيانات');
    } catch (e) {
      _logger.e('خطأ في حفظ التنبيه: $e');
    }
  }

  // ==================== اختبار التنبيهات ====================

  /// اختبار إرسال تنبيه بسيط
  Future<bool> testSimpleNotification() async {
    return await sendNotificationToAllUsers(
      title: 'اختبار التنبيهات',
      body: 'هذا تنبيه تجريبي للتأكد من عمل النظام',
      data: {
        'type': 'test',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// اختبار إرسال تنبيه للسائقين
  Future<bool> testDriverNotification() async {
    return await sendNotificationToAllDrivers(
      title: 'تنبيه للسائقين',
      body: 'هناك طلبات جديدة متاحة',
      data: {
        'type': 'new_trips',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// اختبار إرسال تنبيه للراكبين
  Future<bool> testRiderNotification() async {
    return await sendNotificationToAllRiders(
      title: 'عرض خاص',
      body: 'احصل على خصم 20% على رحلتك القادمة',
      data: {
        'type': 'promotion',
        'discount': '20',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ==================== إحصائيات التنبيهات ====================

  /// جلب إحصائيات التنبيهات
  Future<Map<String, dynamic>> getNotificationStatistics() async {
    try {
      final totalNotifications =
          await _firestore.collection(notificationsCollection).count().get();

      final readNotifications = await _firestore
          .collection(notificationsCollection)
          .where('isRead', isEqualTo: true)
          .count()
          .get();

      final todayNotifications = await _firestore
          .collection(notificationsCollection)
          .where('createdAt',
              isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(days: 1)),
              ))
          .count()
          .get();

      final totalCount = totalNotifications.count ?? 0;
      final readCount = readNotifications.count ?? 0;

      return {
        'totalNotifications': totalCount,
        'readNotifications': readCount,
        'unreadNotifications': totalCount - readCount,
        'todayNotifications': todayNotifications.count ?? 0,
      };
    } catch (e) {
      _logger.e('خطأ في جلب إحصائيات التنبيهات: $e');
      return {
        'totalNotifications': 0,
        'readNotifications': 0,
        'unreadNotifications': 0,
        'todayNotifications': 0,
      };
    }
  }

  /// مسح سجل التنبيهات المرسلة
  void clearSentNotifications() {
    sentNotifications.clear();
  }
}
