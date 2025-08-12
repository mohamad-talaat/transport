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
      await _sendTokenToServer(token!);
          
      // مراقبة تحديث التوكن
      _firebaseMessaging!.onTokenRefresh.listen(_sendTokenToServer);
      
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
      NotificationSettings settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );
      
      logger.e('إعدادات الإشعارات: ${settings.authorizationStatus}');
      
      // أذونات Local Notifications للأندرويد
      await _localNotifications!
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
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
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((message) {
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
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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
    final route = data['route'];
    
    switch (type) {
      case 'trip_update':
        Get.toNamed('/trip-tracking', arguments: data);
        break;
      case 'admin_message':
        Get.toNamed('/notifications');
        break;
      case 'balance_update':
        Get.toNamed('/wallet');
        break;
      default:
        if (route != null) {
          Get.toNamed(route);
        }
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
        },
        timestamp: DateTime.now(),
        isRead: false,
        type: NotificationType.tripUpdate,
      );
      
      _addNotification(notification);
      
      await _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: message,
        data: notification.data,
      );
      
    } catch (e) {
      logger.e('خطأ في إشعار الرحلة: $e');
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
  });

  factory AppNotification.fromFirebaseMessage(RemoteMessage message) {
    return AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'إشعار جديد',
      body: message.notification?.body ?? '',
      imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
      data: message.data,
      timestamp: DateTime.now(),
      isRead: false,
      type: _getNotificationTypeFromData(message.data),
      autoDelete: message.data['auto_delete'] == 'true',
    );
  }

  static NotificationType _getNotificationTypeFromData(Map<String, dynamic> data) {
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
}