import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  FirebaseMessaging? _firebaseMessaging;
  FlutterLocalNotificationsPlugin? _localNotifications;

  // قائمة الإشعارات المحلية
  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;

  // إعدادات الإشعارات
  final RxBool notificationsEnabled = true.obs;
  final RxBool soundEnabled = true.obs;
  final RxBool vibrationEnabled = true.obs;

  Future<NotificationService> init() async {
    await _initFirebaseMessaging();
    await _initLocalNotifications();
    await _loadStoredNotifications();
    await _requestPermissions();
    _setupMessageHandlers();
    _startAutoCleanup();
    return this;
  }

  /// تهيئة Firebase Messaging
  Future<void> _initFirebaseMessaging() async {
    try {
      _firebaseMessaging = FirebaseMessaging.instance;

      // الحصول على FCM Token
      String? token = await _firebaseMessaging!.getToken();
      logger.e('FCM Token: $token');
      // إرسال التوكن للخادم
      if (token != null) {
        await _sendTokenToServer(token);
      }

      // مراقبة تحديث التوكن
      _firebaseMessaging!.onTokenRefresh.listen((newToken) {
        _sendTokenToServer(newToken);
      });
    } catch (e) {
      logger.e('خطأ في تهيئة Firebase Messaging: $e');
    }
  }

  /// تهيئة Local Notifications
  Future<void> _initLocalNotifications() async {
    try {
      _localNotifications = FlutterLocalNotificationsPlugin();

      // إعدادات Android
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // إعدادات iOS
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );
    } catch (e) {
      logger.e('خطأ في تهيئة Local Notifications: $e');
    }
  }

  /// طلب الأذونات
  Future<void> _requestPermissions() async {
    try {
      // أذونات Firebase
      NotificationSettings settings =
          await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );

      logger.e('إعدادات الإشعارات: ${settings.authorizationStatus}');

      // أذونات Local Notifications للأندرويد
      await _localNotifications!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      logger.e('خطأ في طلب الأذونات: $e');
    }
  }

  /// إعداد معالجات الرسائل
  void _setupMessageHandlers() {
    // رسالة عندما يكون التطبيق في المقدمة
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // رسالة عند النقر والتطبيق في الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // رسالة عند فتح التطبيق من إشعار
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessageOpenedApp(message);
      }
    });
  }

  /// معالج الرسائل في المقدمة
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    logger.e('رسالة في المقدمة: ${message.messageId}');

    // إنشاء إشعار محلي
    await _showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.notification?.title ?? 'إشعار جديد',
      body: message.notification?.body ?? '',
      data: message.data,
    );

    // إضافة للقائمة
    _addNotification(AppNotification.fromFirebaseMessage(message));
  }

  /// معالج النقر على الإشعار
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    logger.e('تم فتح الإشعار: ${message.messageId}');

    // التنقل حسب نوع الإشعار
    final data = message.data;
    if (data.isNotEmpty) {
      _handleNotificationNavigation(data);
    }
  }

  /// عرض إشعار محلي
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (!notificationsEnabled.value) return;

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'transport_app_channel',
        'تطبيق النقل',
        channelDescription: 'إشعارات تطبيق النقل',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications!.show(
        id,
        title,
        body,
        platformDetails,
        payload: data != null ? jsonEncode(data) : null,
      );
    } catch (e) {
      logger.e('خطأ في عرض الإشعار: $e');
    }
  }

  /// معالج النقر على الإشعار
  void _handleNotificationTap(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        _handleNotificationNavigation(data);
      }
    } catch (e) {
      logger.e('خطأ في معالجة النقر: $e');
    }
  }

  /// التنقل حسب نوع الإشعار
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'trip_update':
        Get.toNamed('/rider-trip-tracking', arguments: data);
        break;
      case 'admin_message':
        Get.toNamed('/rider-notifications');
        break;
      case 'balance_update':
        Get.toNamed('/rider-wallet');
        break;
      default:
        // تجاهل أي route غير معروف لتفادي /not-found
        // يمكن لاحقاً عمل mapping حسب payload
        return;
    }
  }

  /// إرسال التوكن للخادم
  Future<void> _sendTokenToServer(String token) async {
    try {
      // TODO: إرسال التوكن لـ API الخاص بك
      logger.e('إرسال التوكن للخادم: $token');

      // حفظ التوكن محلياً
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      logger.e('خطأ في إرسال التوكن: $e');
    }
  }

  /// إضافة إشعار جديد
  void _addNotification(AppNotification notification) {
    notifications.insert(0, notification);
    if (!notification.isRead) {
      unreadCount.value++;
    }
    _saveNotifications();
  }

  /// إرسال إشعار من Dashboard (Admin Message)
  Future<void> sendAdminMessage({
    required String title,
    required String message,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: message,
        imageUrl: imageUrl,
        data: data ?? {},
        timestamp: DateTime.now(),
        isRead: false,
        type: NotificationType.adminMessage,
        autoDelete: true, // حذف تلقائي بعد 24 ساعة
      );

      _addNotification(notification);

      // عرض إشعار محلي
      await _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: message,
        data: data,
      );
    } catch (e) {
      logger.e('خطأ في إرسال رسالة الإدارة: $e');
    }
  }

  /// إشعار تحديث الرحلة
  Future<void> sendTripNotification({
    required String tripId,
    required String title,
    required String message,
    required TripNotificationType tripType,
    String? recipientId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: message,
        data: {
          'type': 'trip_update',
          'trip_id': tripId,
          'trip_type': tripType.toString(),
          ...?additionalData,
        },
        timestamp: DateTime.now(),
        isRead: false,
        type: NotificationType.tripUpdate,
        recipientId: recipientId,
      );

      _addNotification(notification);

      await _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: message,
        data: notification.data,
      );

      // إرسال إشعار Firebase إذا كان هناك recipientId
      if (recipientId != null) {
        await _sendFirebaseNotification(
          recipientId: recipientId,
          title: title,
          message: message,
          data: notification.data,
        );
      }
    } catch (e) {
      logger.e('خطأ في إشعار الرحلة: $e');
    }
  }

  /// إرسال إشعار Firebase
  Future<void> _sendFirebaseNotification({
    required String recipientId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      // TODO: إرسال إشعار Firebase عبر Cloud Functions
      // هذا يتطلب إعداد Cloud Functions في Firebase
      logger.i('إرسال إشعار Firebase إلى: $recipientId');
      logger.i('العنوان: $title');
      logger.i('الرسالة: $message');
      logger.i('البيانات: $data');
    } catch (e) {
      logger.e('خطأ في إرسال إشعار Firebase: $e');
    }
  }

  /// إشعار طلب رحلة جديد للسائقين
  Future<void> sendNewTripRequestToDrivers({
    required String tripId,
    required String pickupAddress,
    required String destinationAddress,
    required double estimatedFare,
    required List<String> nearbyDriverIds,
  }) async {
    try {
      final title = '🚕 طلب جديد في منطقتك';
      final message =
          'راكب يطلب رحلة من $pickupAddress إلى $destinationAddress. التكلفة المتوقعة: ${estimatedFare.toStringAsFixed(2)} ج.م';

      for (String driverId in nearbyDriverIds) {
        await sendTripNotification(
          tripId: tripId,
          title: title,
          message: message,
          tripType: TripNotificationType.requested,
          recipientId: driverId,
          additionalData: {
            'action': 'show_trip_request',
            'pickup_address': pickupAddress,
            'destination_address': destinationAddress,
            'estimated_fare': estimatedFare,
          },
        );
      }
    } catch (e) {
      logger.e('خطأ في إرسال طلب رحلة للسائقين: $e');
    }
  }

  /// إشعار قبول الرحلة للراكب
  Future<void> sendTripAcceptedToRider({
    required String tripId,
    required String riderId,
    required String driverName,
    required String driverPhone,
    required String estimatedArrivalTime,
  }) async {
    try {
      final title = 'تم العثور على سائق';
      final message =
          '$driverName في الطريق إليك. سيصل خلال $estimatedArrivalTime';

      await sendTripNotification(
        tripId: tripId,
        title: title,
        message: message,
        tripType: TripNotificationType.accepted,
        recipientId: riderId,
        additionalData: {
          'action': 'show_trip_tracking',
          'driver_name': driverName,
          'driver_phone': driverPhone,
          'estimated_arrival': estimatedArrivalTime,
        },
      );
    } catch (e) {
      logger.e('خطأ في إرسال إشعار قبول الرحلة: $e');
    }
  }

  /// إشعار رفض الرحلة لباقي السائقين
  Future<void> sendTripDeclinedToOtherDrivers({
    required String tripId,
    required List<String> otherDriverIds,
  }) async {
    try {
      final title = 'تم قبول الرحلة';
      final message = 'هذا الطلب لم يعد متاحًا';

      for (String driverId in otherDriverIds) {
        await sendTripNotification(
          tripId: tripId,
          title: title,
          message: message,
          tripType: TripNotificationType.declined,
          recipientId: driverId,
          additionalData: {
            'action': 'dismiss',
          },
        );
      }
    } catch (e) {
      logger.e('خطأ في إرسال إشعار رفض الرحلة: $e');
    }
  }

  /// إشعار وصول السائق للراكب
  Future<void> sendDriverArrivedToRider({
    required String tripId,
    required String riderId,
    required String driverName,
  }) async {
    try {
      final title = 'السائق وصل';
      final message = 'سائقك $driverName ينتظرك الآن';

      await sendTripNotification(
        tripId: tripId,
        title: title,
        message: message,
        tripType: TripNotificationType.driverArrived,
        recipientId: riderId,
        additionalData: {
          'action': 'show_trip_details',
          'driver_name': driverName,
        },
      );
    } catch (e) {
      logger.e('خطأ في إرسال إشعار وصول السائق: $e');
    }
  }

  /// إشعار بدء الرحلة للراكب
  Future<void> sendTripStartedToRider({
    required String tripId,
    required String riderId,
    required String destinationAddress,
  }) async {
    try {
      final title = 'بدأت رحلتك';
      final message = 'أنت في الطريق إلى $destinationAddress';

      await sendTripNotification(
        tripId: tripId,
        title: title,
        message: message,
        tripType: TripNotificationType.started,
        recipientId: riderId,
        additionalData: {
          'action': 'show_trip_tracking',
          'destination': destinationAddress,
        },
      );
    } catch (e) {
      logger.e('خطأ في إرسال إشعار بدء الرحلة: $e');
    }
  }

  /// إشعار انتهاء الرحلة للراكب
  Future<void> sendTripCompletedToRider({
    required String tripId,
    required String riderId,
    required double finalFare,
  }) async {
    try {
      final title = 'تم إنهاء الرحلة';
      final message =
          'وصلت إلى وجهتك. التكلفة: ${finalFare.toStringAsFixed(2)} ج.م';

      await sendTripNotification(
        tripId: tripId,
        title: title,
        message: message,
        tripType: TripNotificationType.completed,
        recipientId: riderId,
        additionalData: {
          'action': 'show_payment_screen',
          'final_fare': finalFare,
        },
      );
    } catch (e) {
      logger.e('خطأ في إرسال إشعار انتهاء الرحلة: $e');
    }
  }

  /// إشعار أرباح للسائق
  Future<void> sendEarningsToDriver({
    required String tripId,
    required String driverId,
    required double earnings,
  }) async {
    try {
      final title = 'رحلة مكتملة';
      final message =
          'لقد أنهيت الرحلة. أرباحك: ${earnings.toStringAsFixed(2)} ج.م';

      await sendTripNotification(
        tripId: tripId,
        title: title,
        message: message,
        tripType: TripNotificationType.completed,
        recipientId: driverId,
        additionalData: {
          'action': 'show_earnings',
          'earnings': earnings,
        },
      );
    } catch (e) {
      logger.e('خطأ في إرسال إشعار الأرباح: $e');
    }
  }

  /// إرسال إشعار إداري مع وقت حذف تلقائي
  Future<void> sendAdminMessageWithAutoDelete({
    required String title,
    required String message,
    String? imageUrl,
    Map<String, dynamic>? data,
    Duration autoDeleteAfter = const Duration(hours: 24),
    List<String>? targetUserIds, // إذا كان null، سيتم إرساله لجميع المستخدمين
  }) async {
    try {
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: message,
        imageUrl: imageUrl,
        data: {
          'type': 'admin_message',
          'auto_delete_after': autoDeleteAfter.inSeconds,
          ...?data,
        },
        timestamp: DateTime.now(),
        isRead: false,
        type: NotificationType.adminMessage,
        autoDelete: true,
        autoDeleteAfter: autoDeleteAfter,
        targetUserIds: targetUserIds,
      );

      _addNotification(notification);

      // عرض إشعار محلي
      await _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: message,
        data: notification.data,
      );

      // إرسال إشعار Firebase للمستخدمين المستهدفين
      if (targetUserIds != null) {
        for (String userId in targetUserIds) {
          await _sendFirebaseNotification(
            recipientId: userId,
            title: title,
            message: message,
            data: notification.data,
          );
        }
      } else {
        // إرسال لجميع المستخدمين (يتطلب Cloud Functions)
        logger.i('إرسال إشعار إداري لجميع المستخدمين');
      }

      // جدولة الحذف التلقائي
      Timer(autoDeleteAfter, () {
        deleteNotification(notification.id);
      });
    } catch (e) {
      logger.e('خطأ في إرسال رسالة الإدارة: $e');
    }
  }

  /// إرسال إشعار إداري ثابت (للاختبار)
  Future<void> sendStaticAdminNotification({
    required AdminNotificationType type,
    List<String>? targetUserIds,
  }) async {
    try {
      final notificationData = _getStaticAdminNotificationData(type);

      await sendAdminMessageWithAutoDelete(
        title: notificationData['title'],
        message: notificationData['message'],
        autoDeleteAfter: notificationData['autoDeleteAfter'],
        targetUserIds: targetUserIds,
        data: {
          'notification_type': type.toString(),
          'static_data': true,
        },
      );
    } catch (e) {
      logger.e('خطأ في إرسال الإشعار الإداري الثابت: $e');
    }
  }

  /// الحصول على بيانات الإشعارات الإدارية الثابتة
  Map<String, dynamic> _getStaticAdminNotificationData(
      AdminNotificationType type) {
    switch (type) {
      case AdminNotificationType.welcome:
        return {
          'title': '🎉 مرحباً بك في تطبيق النقل',
          'message': 'نشكرك على استخدام تطبيقنا. نتمنى لك رحلات آمنة ومريحة!',
          'autoDeleteAfter': const Duration(hours: 48),
        };

      case AdminNotificationType.maintenance:
        return {
          'title': '🔧 صيانة مجدولة',
          'message':
              'سيتم إجراء صيانة على النظام غداً من الساعة 2:00 صباحاً حتى 4:00 صباحاً. نعتذر عن أي إزعاج.',
          'autoDeleteAfter': const Duration(hours: 72),
        };

      case AdminNotificationType.update:
        return {
          'title': '📱 تحديث جديد متاح',
          'message':
              'تم إطلاق إصدار جديد من التطبيق مع ميزات محسنة. يرجى تحديث التطبيق للحصول على أفضل تجربة.',
          'autoDeleteAfter': const Duration(hours: 168), // أسبوع
        };

      case AdminNotificationType.promotion:
        return {
          'title': '🎁 عرض خاص',
          'message':
              'احصل على خصم 20% على رحلتك الأولى! استخدم الكود: WELCOME20',
          'autoDeleteAfter': const Duration(hours: 24),
        };

      case AdminNotificationType.emergency:
        return {
          'title': '⚠️ تنبيه مهم',
          'message':
              'يرجى توخي الحذر أثناء القيادة في الظروف الجوية الحالية. سلامتك أولاً.',
          'autoDeleteAfter': const Duration(hours: 12),
        };

      case AdminNotificationType.news:
        return {
          'title': '📰 أخبار التطبيق',
          'message':
              'تم إضافة ميزات جديدة: تتبع الرحلات في الوقت الفعلي، دفع إلكتروني محسن، وتقييمات أفضل.',
          'autoDeleteAfter': const Duration(hours: 96),
        };

      case AdminNotificationType.reminder:
        return {
          'title': '💡 تذكير مهم',
          'message': 'لا تنس تقييم رحلتك الأخيرة لمساعدتنا في تحسين الخدمة.',
          'autoDeleteAfter': const Duration(hours: 24),
        };

      case AdminNotificationType.holiday:
        return {
          'title': '🎉 عيد سعيد',
          'message': 'نتمنى لكم عيداً سعيداً! سنواصل خدمتكم على مدار الساعة.',
          'autoDeleteAfter': const Duration(hours: 48),
        };
    }
  }

  /// الحصول على قائمة أنواع الإشعارات الإدارية
  List<Map<String, dynamic>> getAdminNotificationTypes() {
    return AdminNotificationType.values.map((type) {
      final data = _getStaticAdminNotificationData(type);
      return {
        'type': type,
        'title': data['title'],
        'message': data['message'],
        'description': _getAdminNotificationDescription(type),
        'icon': _getAdminNotificationIcon(type),
        'color': _getAdminNotificationColor(type),
      };
    }).toList();
  }

  /// الحصول على وصف نوع الإشعار الإداري
  String _getAdminNotificationDescription(AdminNotificationType type) {
    switch (type) {
      case AdminNotificationType.welcome:
        return 'رسالة ترحيب للمستخدمين الجدد';
      case AdminNotificationType.maintenance:
        return 'تنبيه بالصيانة المجدولة';
      case AdminNotificationType.update:
        return 'إشعار بتحديث التطبيق';
      case AdminNotificationType.promotion:
        return 'عروض وخصومات خاصة';
      case AdminNotificationType.emergency:
        return 'تنبيهات طارئة ومهمة';
      case AdminNotificationType.news:
        return 'أخبار وميزات جديدة';
      case AdminNotificationType.reminder:
        return 'تذكيرات للمستخدمين';
      case AdminNotificationType.holiday:
        return 'تهاني بمناسبات خاصة';
    }
  }

  /// الحصول على أيقونة نوع الإشعار الإداري
  String _getAdminNotificationIcon(AdminNotificationType type) {
    switch (type) {
      case AdminNotificationType.welcome:
        return '🎉';
      case AdminNotificationType.maintenance:
        return '🔧';
      case AdminNotificationType.update:
        return '📱';
      case AdminNotificationType.promotion:
        return '🎁';
      case AdminNotificationType.emergency:
        return '⚠️';
      case AdminNotificationType.news:
        return '📰';
      case AdminNotificationType.reminder:
        return '💡';
      case AdminNotificationType.holiday:
        return '🎉';
    }
  }

  /// الحصول على لون نوع الإشعار الإداري
  String _getAdminNotificationColor(AdminNotificationType type) {
    switch (type) {
      case AdminNotificationType.welcome:
        return '#4CAF50'; // أخضر
      case AdminNotificationType.maintenance:
        return '#FF9800'; // برتقالي
      case AdminNotificationType.update:
        return '#2196F3'; // أزرق
      case AdminNotificationType.promotion:
        return '#E91E63'; // وردي
      case AdminNotificationType.emergency:
        return '#F44336'; // أحمر
      case AdminNotificationType.news:
        return '#9C27B0'; // بنفسجي
      case AdminNotificationType.reminder:
        return '#FFC107'; // أصفر
      case AdminNotificationType.holiday:
        return '#4CAF50'; // أخضر
    }
  }

  /// قراءة إشعار
  void markAsRead(String notificationId) {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !notifications[index].isRead) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      unreadCount.value--;
      _saveNotifications();
    }
  }

  /// قراءة جميع الإشعارات
  void markAllAsRead() {
    for (int i = 0; i < notifications.length; i++) {
      if (!notifications[i].isRead) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
    }
    unreadCount.value = 0;
    _saveNotifications();
  }

  /// حذف إشعار
  void deleteNotification(String notificationId) {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      if (!notifications[index].isRead) {
        unreadCount.value--;
      }
      notifications.removeAt(index);
      _saveNotifications();
    }
  }

  /// حذف جميع الإشعارات
  void clearAllNotifications() {
    notifications.clear();
    unreadCount.value = 0;
    _saveNotifications();
  }

  /// بدء التنظيف التلقائي
  void _startAutoCleanup() {
    Timer.periodic(const Duration(hours: 1), (timer) {
      _cleanupOldNotifications();
    });
  }

  /// تنظيف الإشعارات القديمة
  void _cleanupOldNotifications() {
    final now = DateTime.now();
    notifications.removeWhere((notification) {
      // حذف الإشعارات الإدارية بعد 24 ساعة
      if (notification.autoDelete) {
        final diff = now.difference(notification.timestamp).inHours;
        return diff >= 24;
      }

      // حذف الإشعارات العادية بعد أسبوع
      final diff = now.difference(notification.timestamp).inDays;
      return diff >= 7;
    });

    _saveNotifications();
  }

  /// حفظ الإشعارات
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = notifications.map((n) => n.toJson()).toList();
      await prefs.setString('notifications', jsonEncode(notificationsJson));
    } catch (e) {
      logger.e('خطأ في حفظ الإشعارات: $e');
    }
  }

  /// تحميل الإشعارات المحفوظة
  Future<void> _loadStoredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsStr = prefs.getString('notifications');

      if (notificationsStr != null) {
        final List<dynamic> notificationsJson = jsonDecode(notificationsStr);
        notifications.value = notificationsJson
            .map((json) => AppNotification.fromJson(json))
            .toList();

        unreadCount.value = notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      logger.e('خطأ في تحميل الإشعارات: $e');
    }
  }

  /// تحديث إعدادات الإشعارات
  Future<void> updateNotificationSettings({
    bool? enabled,
    bool? sound,
    bool? vibration,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (enabled != null) {
      notificationsEnabled.value = enabled;
      await prefs.setBool('notifications_enabled', enabled);
    }

    if (sound != null) {
      soundEnabled.value = sound;
      await prefs.setBool('notifications_sound', sound);
    }

    if (vibration != null) {
      vibrationEnabled.value = vibration;
      await prefs.setBool('notifications_vibration', vibration);
    }
  }

  @override
  void onClose() {
    // تنظيف الموارد
    super.onClose();
  }
}

/// نموذج الإشعار
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;
  final bool autoDelete;
  final Duration? autoDeleteAfter;
  final List<String>? targetUserIds;
  final String? recipientId;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.data,
    required this.timestamp,
    required this.isRead,
    required this.type,
    this.autoDelete = false,
    this.autoDeleteAfter,
    this.targetUserIds,
    this.recipientId,
  });

  factory AppNotification.fromFirebaseMessage(RemoteMessage message) {
    return AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'إشعار جديد',
      body: message.notification?.body ?? '',
      imageUrl: message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl,
      data: message.data,
      timestamp: DateTime.now(),
      isRead: false,
      type: _getNotificationTypeFromData(message.data),
      autoDelete: message.data['auto_delete'] == 'true',
      autoDeleteAfter: message.data['auto_delete_after'] != null
          ? Duration(seconds: int.parse(message.data['auto_delete_after']!))
          : null,
      recipientId: message.data['recipient_id'],
    );
  }

  static NotificationType _getNotificationTypeFromData(
      Map<String, dynamic> data) {
    switch (data['type']) {
      case 'trip_update':
        return NotificationType.tripUpdate;
      case 'admin_message':
        return NotificationType.adminMessage;
      case 'balance_update':
        return NotificationType.balanceUpdate;
      default:
        return NotificationType.general;
    }
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    NotificationType? type,
    bool? autoDelete,
    Duration? autoDeleteAfter,
    List<String>? targetUserIds,
    String? recipientId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      autoDelete: autoDelete ?? this.autoDelete,
      autoDeleteAfter: autoDeleteAfter ?? this.autoDeleteAfter,
      targetUserIds: targetUserIds ?? this.targetUserIds,
      recipientId: recipientId ?? this.recipientId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type.toString(),
      'autoDelete': autoDelete,
      'autoDeleteAfter': autoDeleteAfter?.inSeconds,
      'targetUserIds': targetUserIds,
      'recipientId': recipientId,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      imageUrl: json['imageUrl'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NotificationType.general,
      ),
      autoDelete: json['autoDelete'] ?? false,
      autoDeleteAfter: json['autoDeleteAfter'] != null
          ? Duration(seconds: json['autoDeleteAfter'])
          : null,
      targetUserIds: List<String>.from(json['targetUserIds'] ?? []),
      recipientId: json['recipientId'],
    );
  }
}

/// أنواع الإشعارات
enum NotificationType {
  general,
  tripUpdate,
  adminMessage,
  balanceUpdate,
}

/// أنواع إشعارات الرحلة
enum TripNotificationType {
  requested,
  accepted,
  driverArrived,
  started,
  completed,
  cancelled,
  declined,
}

/// أنواع الإشعارات الإدارية
enum AdminNotificationType {
  welcome,
  maintenance,
  update,
  promotion,
  emergency,
  news,
  reminder,
  holiday,
}
