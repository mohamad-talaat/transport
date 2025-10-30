import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transport_app/routes/app_routes.dart';
import '../../main.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';

/// 🔔 خدمة إشعارات موحدة (دمج FCM + Local)
class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  late FirebaseMessaging _fcm;
  late FlutterLocalNotificationsPlugin _local;
  late AudioPlayer _audio;

  final notifEnabled = true.obs;
  final soundEnabled = true.obs;
  final vibEnabled = true.obs;

  String? _openChatId;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _init();
    _setupSmartListeners(); // 🔥 الاستماع التلقائي لتغييرات Firestore
  }

  Future<void> _init() async {
    try {
      _fcm = FirebaseMessaging.instance;
      _local = FlutterLocalNotificationsPlugin();
      _audio = AudioPlayer();

      await _loadSettings();
      await _requestPerms();
      await _initLocal();
      await _createChannels();
      _setupHandlers();
      await _getToken();

      logger.i('✅ الإشعارات جاهزة');
    } catch (e) {
      logger.e('❌ خطأ: $e');
    }
  }

  Future<void> _requestPerms() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<void> _initLocal() async {
    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );
  }

  Future<void> _createChannels() async {
    final plugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (plugin == null) return;

    await plugin.createNotificationChannel(
      const AndroidNotificationChannel('critical', 'حرجة', importance: Importance.max, playSound: true, enableVibration: true, sound: RawResourceAndroidNotificationSound('notification')),
    );
    await plugin.createNotificationChannel(
      const AndroidNotificationChannel('chat', 'رسائل', importance: Importance.high, playSound: true, sound: RawResourceAndroidNotificationSound('message')),
    );
  }

  void _setupHandlers() {
    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onBackgroundTap);
    _fcm.getInitialMessage().then((msg) { if (msg != null) _onBackgroundTap(msg); });
  }

  Future<void> _onForeground(RemoteMessage msg) async {
    if (!notifEnabled.value) return;

    final type = msg.data['type'] ?? 'general';
    final chatId = msg.data['chatId'];

    // 🔇 لو في الشات نفسه، صوت خفيف فقط
    if (type == 'chat' && chatId == _openChatId) {
      await _playSound('message');
      return;
    }

    // ✅ حالات الإشعارات مع الصوت الصحيح
    String sound = 'message';
    if (type == 'new_trip' || type == 'trip_accepted' || type == 'driver_arrived') {
      sound = 'notification';
    }

    await _show(msg);
    await _playSound(sound);
  }

  Future<void> _show(RemoteMessage msg) async {
    final notif = msg.notification;
    if (notif == null) return;

    final type = msg.data['type'] ?? 'general';
    final isCrit = type == 'new_trip' || type == 'driver_arrived';

    final android = AndroidNotificationDetails(
      isCrit ? 'critical' : 'chat',
      isCrit ? 'حرجة' : 'رسائل',
      importance: isCrit ? Importance.max : Importance.high,
      priority: isCrit ? Priority.max : Priority.high,
      playSound: soundEnabled.value,
      enableVibration: vibEnabled.value,
      sound: isCrit ? const RawResourceAndroidNotificationSound('notification') : const RawResourceAndroidNotificationSound('message'),
    );

    await _local.show(
      msg.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(android: android, iOS: const DarwinNotificationDetails()),
      payload: jsonEncode(msg.data),
    );
  }

  Future<void> _playSound(String name) async {
    if (!soundEnabled.value) return;
    try {
      await _audio.play(AssetSource('sounds/$name.mp3'));
    } catch (_) {}
  }

  void _onBackgroundTap(RemoteMessage msg) => _navigate(msg.data);
  void _onTap(NotificationResponse res) {
    if (res.payload != null) _navigate(jsonDecode(res.payload!));
  }
 void _navigate(Map<String, dynamic> data) {
    final action = data['action'];
    if (action == 'open_chat') {
      Get.toNamed(AppRoutes.CHAT, arguments: data);
    } else if (action == 'new_trip_request') Get.toNamed(AppRoutes.DRIVER_TRIP_TRACKING, arguments: data);
    else if (action == 'open_tracking') Get.toNamed('/trip-tracking', arguments: data);
  }
  // void _navigate(Map<String, dynamic> data) {
  //   final action = data['action'];
  //   if (action == 'open_chat') {
  //     Get.toNamed('/chat', arguments: data);
  //   } else if (action == 'new_trip_request') Get.toNamed('/driver-trip-request', arguments: data);
  //   else if (action == 'open_tracking') Get.toNamed('/trip-tracking', arguments: data);
  // }

  Future<void> _getToken() async {
    final token = await _fcm.getToken();
    if (token != null) await _saveToken(token);
    _fcm.onTokenRefresh.listen(_saveToken);
  }

  Future<void> _saveToken(String token) async {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'fcmToken': token, 'lastTokenUpdate': FieldValue.serverTimestamp()});
    }
    GetStorage().write('fcm_token', token);
  }

  void setOpenChatId(String? id) => _openChatId = id;

  Future<void> _loadSettings() async {
    final s = GetStorage();
    notifEnabled.value = s.read('notif_enabled') ?? true;
    soundEnabled.value = s.read('sound_enabled') ?? true;
    vibEnabled.value = s.read('vib_enabled') ?? true;
  }

  Future<void> updateSettings({bool? notif, bool? sound, bool? vib}) async {
    final s = GetStorage();
    if (notif != null) { notifEnabled.value = notif; await s.write('notif_enabled', notif); }
    if (sound != null) { soundEnabled.value = sound; await s.write('sound_enabled', sound); }
    if (vib != null) { vibEnabled.value = vib; await s.write('vib_enabled', vib); }
  }

  /// 🔥 الاستماع الذكي لتغييرات Firestore (بديل Cloud Functions)
  void _setupSmartListeners() {
    final userId = AuthController.to.currentUser.value?.id;
    if (userId == null) return;

    // 🚗 إشعارات الرحلة
    FirebaseFirestore.instance
      .collection('trips')
      .where('riderId', isEqualTo: userId)
      .snapshots()
      .listen((snap) {
        for (var change in snap.docChanges) {
          if (change.type == DocumentChangeType.modified) {
            final data = change.doc.data()!;
            final status = data['status'];
            
            // ✅ تم قبول الرحلة
            if (status == 'accepted') {
              _showLocalNotification(
                title: '🚗 تم قبول الرحلة',
                body: 'السائق ${data['driverName']} في الطريق إليك',
                sound: 'notification',
              );
            }
            // ✅ وصل السائق
            else if (status == 'driverArrived') {
              _showLocalNotification(
                title: '✅ السائق وصل!',
                body: '${data['driverName']} ينتظرك',
                sound: 'notification',
              );
            }
            // 🚀 بدأت الرحلة
            else if (status == 'inProgress') {
              _showLocalNotification(
                title: '🚀 بدأت رحلتك',
                body: 'أنت في الطريق',
                sound: 'message',
              );
            }
          }
        }
      });

    // 💬 إشعارات الشات (لو مش في الشات)
    FirebaseFirestore.instance
      .collectionGroup('messages')
      .where('senderId', isNotEqualTo: userId)
      .snapshots()
      .listen((snap) {
        for (var change in snap.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data()!;
            final chatId = data['chatId'];
            
            // 🔇 لو مش في نفس الشات، ارسل إشعار
            if (chatId != _openChatId) {
              _showLocalNotification(
                title: '💬 ${data['senderName']}',
                body: data['message'],
                sound: 'message',
              );
            }
          }
        }
      });

    // 🎉 إشعار موافقة الحساب
    FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .listen((snap) {
        if (!snap.exists) return;
        final data = snap.data()!;
        
        // لو تغيرت isApproved من false لـ true
        if (data['isApproved'] == true) {
          _showLocalNotification(
            title: '🎉 تمت الموافقة!',
            body: 'مرحباً بك في تكسي البصرة',
            sound: 'notification',
          );
        }
      });

    // 🚕 إشعارات طلبات الرحلة للسائقين
    final userType = AuthController.to.currentUser.value?.userType;
    if (userType == UserType.driver) {
      FirebaseFirestore.instance
        .collection('trip_requests')
        .where('driverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
          for (var change in snap.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data()!;
              final details = data['tripDetails'] as Map<String, dynamic>;
              
              _showLocalNotification(
                title: '🚗 طلب رحلة جديد',
                body: 'من ${details['pickupAddress']} إلى ${details['destinationAddress']}\nالتكلفة: ${details['fare']} د.ع',
                sound: 'notification',
              );
            }
          }
        });
    }

    logger.i('✅ تم تفعيل الاستماع الذكي للإشعارات');
  }

  /// 🔔 إظهار إشعار محلي مع صوت
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String sound,
  }) async {
    if (!notifEnabled.value) return;

    final isCritical = sound == 'notification';

    await _local.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          isCritical ? 'critical' : 'chat',
          isCritical ? 'حرجة' : 'رسائل',
          importance: isCritical ? Importance.max : Importance.high,
          priority: isCritical ? Priority.max : Priority.high,
          playSound: soundEnabled.value,
          sound: RawResourceAndroidNotificationSound(sound),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );

    await _playSound(sound);
  }

  @override
  void onClose() {
    _audio.dispose();
    super.onClose();
  }
}
