import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/notification_model.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/location_service.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/services/notification/notification_service.dart';
import 'package:transport_app/views/common/chat_service/communication_service.dart';
// نوع الإشعار
// enum NotificationType { tripRequest, chatMessage }

class AppController extends GetxController {
  static AppController get to => Get.find();
  final Rx<RemoteMessage?> latestNotification = Rx<RemoteMessage?>(null);
  final Rx<NotificationType?> latestNotificationType =
      Rx<NotificationType?>(null);
  DateTime? _lastTripNotificationTime;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final RxBool isLoading = false.obs;
  final RxString loadingMessage = ''.obs;

  final RxBool isConnected = true.obs;
  final Rx<ConnectivityResult> connectionType = ConnectivityResult.none.obs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final RxBool isDarkMode = false.obs;
  final Rx<Locale> currentLocale = const Locale('ar', 'EG').obs;
  final RxString currentLanguage = 'ar'.obs;

  final RxBool isInBackground = false.obs;
  final RxInt backgroundDuration = 0.obs;
  Timer? _backgroundTimer;

  final RxBool soundsEnabled = true.obs;
  final RxBool vibrationsEnabled = true.obs;
  final RxBool notificationsEnabled = true.obs;

  final RxString appVersion = '1.0.0'.obs;
  final RxString buildNumber = '1'.obs;

  final RxBool isUnderMaintenance = false.obs;
  final RxBool hasUpdate = false.obs;
  
  // 🔥 Developer Mode (for debugging)
  final RxBool isDeveloperMode = false.obs;
  final RxBool isUpdateRequired = false.obs;
  final RxString updateUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      showLoading('جاري تهيئة التطبيق...');
      _setupFCMListeners();

      await _loadAppSettings();
      await _initConnectivity();
      await _checkAppStatus();

      hideLoading();
    } catch (e) {
      hideLoading();
      logger.i('خطأ في تهيئة التطبيق: $e');
    }
  }

  void _setupFCMListeners() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleIncomingNotification(message);
    });

    // Background / terminated -> فتح التطبيق عند الضغط على الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationNavigation(message);
    });

    // Initial message (لو التطبيق كان مغلق)
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationNavigation(initialMessage);
    }
  }

  void _handleIncomingNotification(RemoteMessage message) {
    final data = message.data;

    // مثال: نوع الإشعار
    final type = data['type'] ?? 'unknown';
    if (type == 'trip') {
      _showTripNotification();
    } else if (type == 'chat') {
      _showChatNotification(data);
    }

    // تحديث الـ Stream
    latestNotification.value = message;
    latestNotificationType.value = type == 'trip'
        ? NotificationType.tripRequested
        : NotificationType.chatMessage;
  }

  void _showTripNotification() {
    final now = DateTime.now();
    if (_lastTripNotificationTime != null &&
        now.difference(_lastTripNotificationTime!).inSeconds < 5) return;
    _lastTripNotificationTime = now;

    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        '🚗 طلب رحلة جديد!',
        'لديك رحلة جديدة',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.directions_car, color: Colors.white),
        shouldIconPulse: true,
        onTap: (_) => Get.offAllNamed(AppRoutes.DRIVER_HOME),
      );
    }

    _playSound();
  }

  void _showChatNotification(Map<String, dynamic> data) {
    // هنا نفترض انه المستخدم خارج الشات الحالي
    final currentOpenChatId =
        Get.find<CommunicationService>().currentOpenChatId;
    if (currentOpenChatId != data['chatId']) {
      // إشعار صوتي فقط، ممكن تضيف Snackbar أو أي UI إضافي
      _playSound();
    }
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/message.mp3'));
      logger.w('🔊 تم تشغيل صوت الإشعار');
    } catch (e) {
      logger.w('⚠️ خطأ أثناء تشغيل الصوت: $e');
    }
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? 'unknown';

    if (type == 'trip') {
      // فتح صفحة الهوم للسائق مباشرة
      Get.offAllNamed('/driverHome');
    } else if (type == 'chat') {
      // فتح صفحة الشات إذا حابب
      final chatId = data['chatId'];
      if (chatId != null) {
        Get.toNamed('/chat', arguments: {'chatId': chatId});
      }
    }
  }

  Future<void> _loadAppSettings() async {
    try {
      final box = GetStorage();

      isDarkMode.value = box.read('dark_mode') ?? false;
      currentLanguage.value = box.read('language') ?? 'ar';
      soundsEnabled.value = box.read('sounds_enabled') ?? true;
      vibrationsEnabled.value = box.read('vibrations_enabled') ?? true;
      notificationsEnabled.value = box.read('notifications_enabled') ?? true;

      if (currentLanguage.value == 'ar') {
        currentLocale.value = const Locale('ar', 'EG');
        Get.updateLocale(const Locale('ar', 'EG'));
      } else {
        currentLocale.value = const Locale('en', 'US');
        Get.updateLocale(const Locale('en', 'US'));
      }

      _applyTheme();
    } catch (e) {
      logger.i('خطأ في تحميل الإعدادات: $e');
    }
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final current =
          results.isNotEmpty ? results.first : ConnectivityResult.none;

      connectionType.value = current;
      isConnected.value = current != ConnectivityResult.none;

      _connectivitySubscription = Connectivity()
          .onConnectivityChanged
          .listen((List<ConnectivityResult> results) {
        final result =
            results.isNotEmpty ? results.first : ConnectivityResult.none;
        _onConnectivityChanged(result);
      });
    } catch (e) {
      logger.i('خطأ في مراقبة الاتصال: $e');
    }
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    final wasConnected = isConnected.value;
    connectionType.value = result;
    isConnected.value = result != ConnectivityResult.none;

    if (!wasConnected && isConnected.value) {
      _onConnectionRestored();
    } else if (wasConnected && !isConnected.value) {
      _onConnectionLost();
    }
  }

  void _onConnectionRestored() {
    Get.snackbar(
      'تم استعادة الاتصال',
      'تم الاتصال بالإنترنت بنجاح',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.wifi, color: Colors.white),
    );

    _refreshAppData();
  }

  void _onConnectionLost() {
    Get.snackbar(
      'انقطع الاتصال',
      'تحقق من اتصال الإنترنت',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      icon: const Icon(Icons.wifi_off, color: Colors.white),
    );
  }

  Future<void> _checkAppStatus() async {
    try {
      if (isUnderMaintenance.value) {
        _showMaintenanceDialog();
      } else if (hasUpdate.value) {
        _showUpdateDialog();
      }
    } catch (e) {
      logger.i('خطأ في فحص حالة التطبيق: $e');
    }
  }

  void showLoading([String? message]) {
    isLoading.value = true;
    loadingMessage.value = message ?? 'جاري التحميل...';
  }

  void hideLoading() {
    isLoading.value = false;
    loadingMessage.value = '';
  }

  Future<void> toggleTheme() async {
    try {
      isDarkMode.value = !isDarkMode.value;
      _applyTheme();

      final box = GetStorage();
      box.write('dark_mode', isDarkMode.value);

      Get.snackbar(
        'تم تغيير المظهر',
        isDarkMode.value ? 'تم تفعيل المظهر الداكن' : 'تم تفعيل المظهر الفاتح',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      logger.i('خطأ في تغيير الثيم: $e');
    }
  }

  void _applyTheme() {
    if (isDarkMode.value) {
      Get.changeTheme(ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
      ));
    } else {
      Get.changeTheme(ThemeData.light().copyWith(
        primaryColor: Colors.blue,
      ));
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    try {
      currentLanguage.value = languageCode;

      if (languageCode == 'ar') {
        currentLocale.value = const Locale('ar', 'EG');
        Get.updateLocale(const Locale('ar', 'EG'));
      } else {
        currentLocale.value = const Locale('en', 'US');
        Get.updateLocale(const Locale('en', 'US'));
      }

      final box = GetStorage();
      box.write('language', languageCode);

      Get.snackbar(
        languageCode == 'ar' ? 'تم تغيير اللغة' : 'Language Changed',
        languageCode == 'ar'
            ? 'تم تغيير اللغة إلى العربية'
            : 'Language changed to English',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      logger.i('خطأ في تغيير اللغة: $e');
    }
  }

  Future<void> updateSoundSettings({
    bool? sounds,
    bool? vibrations,
    bool? notifications,
  }) async {
    try {
      final box = GetStorage();

      if (sounds != null) {
        soundsEnabled.value = sounds;
        box.write('sounds_enabled', sounds);
      }

      if (vibrations != null) {
        vibrationsEnabled.value = vibrations;
        box.write('vibrations_enabled', vibrations);
      }

      if (notifications != null) {
        notificationsEnabled.value = notifications;
        box.write('notifications_enabled', notifications);

        await NotificationService.to.updateSettings(
          // enabled: notifications,
        );
      }
    } catch (e) {
      logger.i('خطأ في تحديث إعدادات الصوت: $e');
    }
  }

  Future<void> vibrate({int duration = 100}) async {
    if (vibrationsEnabled.value) {
      await HapticFeedback.lightImpact();
    }
  }

  void playSound(String soundType) {
    if (soundsEnabled.value) {
      switch (soundType) {
        case 'notification':
          HapticFeedback.selectionClick();
          break;
        case 'success':
          HapticFeedback.mediumImpact();
          break;
        case 'error':
          HapticFeedback.heavyImpact();
          break;
      }
    }
  }

  void onAppLifecycleStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.hidden:
    }
  }

  void _onAppResumed() {
    isInBackground.value = false;
    _backgroundTimer?.cancel();

    _checkAppStatus();

    if (Get.isRegistered<AuthController>()) {
      final authController = Get.find<AuthController>();
      if (authController.isLoggedIn.value) {
        LocationService.to.getCurrentLocation();
      }
    }
  }

  void _onAppPaused() {
    isInBackground.value = true;
    backgroundDuration.value = 0;

    _backgroundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      backgroundDuration.value++;
    });
  }

  void _onAppDetached() {
    _backgroundTimer?.cancel();
  }

  Future<void> _refreshAppData() async {
    try {
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        if (authController.isLoggedIn.value) {
          await authController
              .loadUserData(authController.currentUser.value!.id);

          await LocationService.to.getCurrentLocation();
        }
      }
    } catch (e) {
      logger.i('خطأ في تحديث البيانات: $e');
    }
  }

  void _showMaintenanceDialog() {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.build, color: Colors.orange),
              SizedBox(width: 8),
              Text('التطبيق تحت الصيانة'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'نعتذر، التطبيق حالياً تحت الصيانة لتحسين الخدمة. سيعود قريباً.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => SystemNavigator.pop(),
              child: const Text('إغلاق التطبيق'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showUpdateDialog() {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => !isUpdateRequired.value,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.system_update, color: Colors.blue),
              SizedBox(width: 8),
              Text('تحديث متاح'),
            ],
          ),
          content: Text(
            isUpdateRequired.value
                ? 'يجب تحديث التطبيق للاستمرار في الاستخدام'
                : 'إصدار جديد من التطبيق متاح. هل تريد التحديث؟',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            if (!isUpdateRequired.value)
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('لاحقاً'),
              ),
            ElevatedButton(
              onPressed: () => _openUpdateUrl(),
              child: const Text('تحديث'),
            ),
          ],
        ),
      ),
      barrierDismissible: !isUpdateRequired.value,
    );
  }

  void _openUpdateUrl() {}

  void showError(String message, {String? title}) {
    playSound('error');
    vibrate(duration: 200);

    Get.snackbar(
      title ?? 'خطأ',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }

  void showSuccess(String message, {String? title}) {
    playSound('success');
    vibrate(duration: 100);

    Get.snackbar(
      title ?? 'نجح',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  void showInfo(String message, {String? title}) {
    Get.snackbar(
      title ?? 'معلومات',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      icon: const Icon(Icons.info, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  void showWarning(String message, {String? title}) {
    Get.snackbar(
      title ?? 'تحذير',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      icon: const Icon(Icons.warning, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }

  bool validateInput(String input, {InputType type = InputType.general}) {
    switch (type) {
      case InputType.phone:
        return RegExp('r^(010|011|012|015)[0-9]{8})').hasMatch(input);
      case InputType.email:
        return RegExp(r'^[^@]+@[^@]+\.[^@]+)').hasMatch(input);
      case InputType.name:
        return input.trim().length >= 2;
      case InputType.general:
        return input.trim().isNotEmpty;
    }
  }

  String formatPhoneNumber(String phone) {
    if (phone.length == 11 && phone.startsWith('0')) {
      return '+20${phone.substring(1)}';
    } else if (phone.length == 10) {
      return '+20$phone';
    }
    return phone;
  }

  String formatCurrency(double amount, {String currency = 'د.ع'}) {
    return '${amount.toStringAsFixed(2)} $currency';
  }

  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} متر';
    } else {
      return '${distanceKm.toStringAsFixed(1)} كم';
    }
  }

  String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes دقيقة';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours ساعة ${remainingMinutes > 0 ? '$remainingMinutes دقيقة' : ''}';
    }
  }

  String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final amPm = hour >= 12 ? 'م' : 'ص';
      final displayHour = hour > 12
          ? hour - 12
          : hour == 0
              ? 12
              : hour;
      return 'اليوم $displayHour:$minute $amPm';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} أيام';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<void> resetApp() async {
    try {
      showLoading('جاري إعادة تعيين التطبيق...');

      if (Get.isRegistered<AuthController>()) {
        await Get.find<AuthController>().signOut();
      }

      final box = GetStorage();
      await box.erase();

      await _loadAppSettings();

      hideLoading();
      showSuccess('تم إعادة تعيين التطبيق بنجاح');

      Get.offAllNamed('/splash');
    } catch (e) {
      hideLoading();
      showError('خطأ في إعادة تعيين التطبيق: $e');
    }
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _backgroundTimer?.cancel();
    super.onClose();
  }
}

enum InputType {
  general,
  phone,
  email,
  name,
}
