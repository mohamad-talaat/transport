import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_storage/get_storage.dart';
 import 'package:transport_app/main.dart';
import 'package:transport_app/services/location_service.dart';
import 'package:transport_app/services/notification_service.dart';
import 'package:transport_app/controllers/auth_controller.dart';

class AppController extends GetxController {
  static AppController get to => Get.find();

  // حالة التطبيق العامة
  final RxBool isLoading = false.obs;
  final RxString loadingMessage = ''.obs;
  
  // اتصال الإنترنت
  final RxBool isConnected = true.obs;
  final Rx<ConnectivityResult> connectionType = ConnectivityResult.none.obs;
   StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // إعدادات التطبيق
  final RxBool isDarkMode = false.obs;
  final Rx<Locale> currentLocale = const Locale('ar', 'EG').obs;
  final RxString currentLanguage = 'ar'.obs;
  
  // حالة التطبيق في الخلفية
  final RxBool isInBackground = false.obs;
  final RxInt backgroundDuration = 0.obs;
  Timer? _backgroundTimer;
  
  // إعدادات التنبيهات والأصوات
  final RxBool soundsEnabled = true.obs;
  final RxBool vibrationsEnabled = true.obs;
  final RxBool notificationsEnabled = true.obs;
  
  // معلومات التطبيق
  final RxString appVersion = '1.0.0'.obs;
  final RxString buildNumber = '1'.obs;
  
  // حالة الصيانة والتحديث
  final RxBool isUnderMaintenance = false.obs;
  final RxBool hasUpdate = false.obs;
  final RxBool isUpdateRequired = false.obs;
  final RxString updateUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  /// تهيئة التطبيق
  Future<void> _initializeApp() async {
    try {
      showLoading('جاري تهيئة التطبيق...');
      
      await _loadAppSettings();
      await _initConnectivity();
      await _checkAppStatus();
      
      hideLoading();
    } catch (e) {
      hideLoading();
      logger.i('خطأ في تهيئة التطبيق: $e');
    }
  }

  /// تحميل إعدادات التطبيق
  Future<void> _loadAppSettings() async {
    try {
      final box = GetStorage();
      
      // تحميل الإعدادات
      isDarkMode.value = box.read('dark_mode') ?? false;
      currentLanguage.value = box.read('language') ?? 'ar';
      soundsEnabled.value = box.read('sounds_enabled') ?? true;
      vibrationsEnabled.value = box.read('vibrations_enabled') ?? true;
      notificationsEnabled.value = box.read('notifications_enabled') ?? true;
      
      // تطبيق اللغة
      if (currentLanguage.value == 'ar') {
        currentLocale.value = const Locale('ar', 'EG');
        Get.updateLocale(const Locale('ar', 'EG'));
      } else {
        currentLocale.value = const Locale('en', 'US');
        Get.updateLocale(const Locale('en', 'US'));
      }
      
      // تطبيق الثيم
      _applyTheme();
      
    } catch (e) {
      logger.i('خطأ في تحميل الإعدادات: $e');
    }
  }

/// تهيئة مراقب الاتصال
Future<void> _initConnectivity() async {
  try {
    // فحص الاتصال الحالي
    final results = await Connectivity().checkConnectivity();
    final current = results.isNotEmpty ? results.first : ConnectivityResult.none;

    connectionType.value = current;
    isConnected.value = current != ConnectivityResult.none;

    // مراقبة تغيرات الاتصال
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _onConnectivityChanged(result);
    });
  } catch (e) {
    logger.i('خطأ في مراقبة الاتصال: $e');
  }
}
 
/// معالج تغير حالة الاتصال
void _onConnectivityChanged(ConnectivityResult result) {
  final wasConnected = isConnected.value;
  connectionType.value = result;
  isConnected.value = result != ConnectivityResult.none;

  if (!wasConnected && isConnected.value) {
    // العودة للاتصال
    _onConnectionRestored();
  } else if (wasConnected && !isConnected.value) {
    // انقطاع الاتصال
    _onConnectionLost();
  }
}


  /// معالج استعادة الاتصال
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
    
    // إعادة تحميل البيانات المهمة
    _refreshAppData();
  }

  /// معالج انقطاع الاتصال
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

  /// فحص حالة التطبيق (صيانة، تحديثات)
  Future<void> _checkAppStatus() async {
    try {
      // TODO: استدعاء API للحصول على حالة التطبيق
      // final response = await ApiService.getAppStatus();
      // isUnderMaintenance.value = response.isUnderMaintenance;
      // hasUpdate.value = response.hasUpdate;
      // isUpdateRequired.value = response.isUpdateRequired;
      // updateUrl.value = response.updateUrl;
      
      if (isUnderMaintenance.value) {
        _showMaintenanceDialog();
      } else if (hasUpdate.value) {
        _showUpdateDialog();
      }
      
    } catch (e) {
      logger.i('خطأ في فحص حالة التطبيق: $e');
    }
  }

  /// عرض شاشة التحميل
  void showLoading([String? message]) {
    isLoading.value = true;
    loadingMessage.value = message ?? 'جاري التحميل...';
  }

  /// إخفاء شاشة التحميل
  void hideLoading() {
    isLoading.value = false;
    loadingMessage.value = '';
  }

  /// تغيير الثيم
  Future<void> toggleTheme() async {
    try {
      isDarkMode.value = !isDarkMode.value;
      _applyTheme();
      
      // حفظ الإعداد
      final box = GetStorage();
      box.write('dark_mode', isDarkMode.value);
      
      // إشعار المستخدم
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

  /// تطبيق الثيم
  void _applyTheme() {
    if (isDarkMode.value) {
      Get.changeTheme(ThemeData.dark().copyWith(
        primaryColor: Colors.blue, 
        // primarySwatch: Colors.blue,
       // fontFamily: 'Cairo',
      ));
    } else {
      Get.changeTheme(ThemeData.light().copyWith(        primaryColor: Colors.blue, 

     //   primarySwatch: Colors.blue,
      //  fontFamily: 'Cairo',
      ));
    }
  }

  /// تغيير اللغة
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
      
      // حفظ الإعداد
      final box = GetStorage();
      box.write('language', languageCode);
      
      Get.snackbar(
        languageCode == 'ar' ? 'تم تغيير اللغة' : 'Language Changed',
        languageCode == 'ar' ? 'تم تغيير اللغة إلى العربية' : 'Language changed to English',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      logger.i('خطأ في تغيير اللغة: $e');
    }
  }

  /// تحديث إعدادات الأصوات والاهتزاز
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
        
        // تحديث خدمة الإشعارات
        await NotificationService.to.updateNotificationSettings(
          enabled: notifications,
        );
      }
      
    } catch (e) {
      logger.i('خطأ في تحديث إعدادات الصوت: $e');
    }
  }

  /// اهتزاز الجهاز
  Future<void> vibrate({int duration = 100}) async {
    if (vibrationsEnabled.value) {
      await HapticFeedback.lightImpact();
    }
  }

  /// تشغيل صوت
  void playSound(String soundType) {
    if (soundsEnabled.value) {
      // TODO: تشغيل الصوت المناسب
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

  /// إدارة حالة التطبيق في الخلفية
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
        // TODO: Handle this case.
    }
  }

  /// عند عودة التطبيق للمقدمة
  void _onAppResumed() {
    isInBackground.value = false;
    _backgroundTimer?.cancel();
    
    // فحص التحديثات عند العودة
    _checkAppStatus();
    
    // إعادة تفعيل خدمات الموقع إذا لزم الأمر
    if (Get.isRegistered<AuthController>()) {
      final authController = Get.find<AuthController>();
      if (authController.isLoggedIn.value) {
        LocationService.to.getCurrentLocation();
      }
    }
  }

  /// عند ذهاب التطبيق للخلفية
  void _onAppPaused() {
    isInBackground.value = true;
    backgroundDuration.value = 0;
    
    // بدء حساب مدة البقاء في الخلفية
    _backgroundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      backgroundDuration.value++;
    });
  }

  /// عند إغلاق التطبيق
  void _onAppDetached() {
    _backgroundTimer?.cancel();
  }

  /// تحديث البيانات
  Future<void> _refreshAppData() async {
    try {
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        if (authController.isLoggedIn.value) {
          // تحديث بيانات المستخدم
          // await authController.refreshUserData();
                    await authController.loadUserData(authController.currentUser.value!.id);          

          
          // تحديث الموقع
          await LocationService.to.getCurrentLocation();
        }
      }
    } catch (e) {
      logger.i('خطأ في تحديث البيانات: $e');
    }
  }

  /// عرض حوار الصيانة
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

  /// عرض حوار التحديث
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

  /// فتح رابط التحديث
  void _openUpdateUrl() {
    // TODO: فتح رابط متجر التطبيقات
    // launch(updateUrl.value);
  }

  /// عرض رسالة خطأ عامة
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

  /// عرض رسالة نجاح عامة
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

  /// عرض رسالة معلومات عامة
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

  /// عرض رسالة تحذير عامة
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

  /// فحص صحة البيانات
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

  /// تنسيق رقم الهاتف
  String formatPhoneNumber(String phone) {
    if (phone.length == 11 && phone.startsWith('0')) {
      return '+20${phone.substring(1)}';
    } else if (phone.length == 10) {
      return '+20$phone';
    }
    return phone;
  }

  /// تنسيق المبلغ المالي
  String formatCurrency(double amount, {String currency = 'ج.م'}) {
    return '${amount.toStringAsFixed(2)} $currency';
  }

  /// تنسيق المسافة
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} متر';
    } else {
      return '${distanceKm.toStringAsFixed(1)} كم';
    }
  }

  /// تنسيق الوقت
  String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes دقيقة';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours ساعة ${remainingMinutes > 0 ? '$remainingMinutes دقيقة' : ''}';
    }
  }

  /// تنسيق التاريخ والوقت
  String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      // اليوم
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final amPm = hour >= 12 ? 'م' : 'ص';
      final displayHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
      return 'اليوم $displayHour:$minute $amPm';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} أيام';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// إعادة تعيين التطبيق
  Future<void> resetApp() async {
    try {
      showLoading('جاري إعادة تعيين التطبيق...');
      
      // تسجيل خروج المستخدم
      if (Get.isRegistered<AuthController>()) {
        await Get.find<AuthController>().signOut();
      }
      
      // مسح البيانات المحفوظة
      final box = GetStorage();
      await box.erase();
      
      // إعادة تحميل الإعدادات الافتراضية
      await _loadAppSettings();
      
      hideLoading();
      showSuccess('تم إعادة تعيين التطبيق بنجاح');
      
      // العودة لشاشة البداية
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

/// أنواع المدخلات للتحقق
enum InputType {
  general,
  phone,
  email,
  name,
}