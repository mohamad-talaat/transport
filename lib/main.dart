import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart';
import 'package:transport_app/controllers/app_controller.dart';
import 'package:transport_app/routes/app_pages.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/location_service.dart';
import 'package:transport_app/services/notification_service.dart';
import 'package:transport_app/services/app_settings_service.dart';
import 'package:transport_app/services/image_upload_service.dart';
import 'package:transport_app/services/free_image_upload_service.dart';
import 'package:transport_app/services/local_image_service.dart';
import 'package:transport_app/services/smart_image_service.dart';
import 'package:transport_app/services/mock_testing_service.dart';
import 'package:transport_app/services/driver_payment_service.dart';
import 'package:transport_app/services/driver_discount_service.dart';
import 'package:transport_app/services/firebase_service.dart';
import 'package:transport_app/services/driver_profile_service.dart';
import 'package:transport_app/services/user_management_service.dart';
import 'package:transport_app/services/discount_code_service.dart';
import 'package:transport_app/services/notification_test_service.dart';
import 'package:transport_app/controllers/auth_controller.dart';

// تعريف logger في بداية الملف
var logger = Logger(
  printer: PrettyPrinter(),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage for secure local storage
  await GetStorage.init();

  // تهيئة Firebase - إصلاح مشكلة التطبيق المكرر
  try {
    // التحقق من وجود Firebase مسبقاً
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          // options: DefaultFirebaseOptions.currentPlatform,
          );
      logger.i('تم تهيئة Firebase بنجاح');
    } else {
      logger.i('Firebase مهيأ مسبقاً');
    }
  } catch (e) {
    logger.e('خطأ في تهيئة Firebase: $e');
    // معالجة الخطأ بشكل أفضل
    rethrow; // إعادة رمي الخطأ إذا كان حرجاً
  }

  // تهيئة الخدمات
  await initServices();

  runApp(const MyApp());
}

Future<void> initServices() async {
  try {
    // تهيئة الخدمات الأساسية بالترتيب الصحيح مع معالجة الأخطاء

    // 1. AppController (يجب أن يكون الأول)
    Get.put(AppController());
    logger.d('تم تهيئة AppController');

    // 2. AuthController مبكراً لضمان استعادة الجلسة قبل شاشة السبلاش
    Get.put(AuthController(), permanent: true);
    logger.d('تم تهيئة AuthController');

    // 3. NotificationService مع معالجة الأخطاء
    try {
      await Get.putAsync(() => NotificationService().init());
      logger.d('تم تهيئة NotificationService');
    } catch (e) {
      logger.e('خطأ في تهيئة NotificationService: $e');
    }

    // 4. LocationService مع معالجة الأخطاء
    try {
      await Get.putAsync(() => LocationService().init());
      logger.d('تم تهيئة LocationService');
    } catch (e) {
      logger.e('خطأ في تهيئة LocationService: $e');
    }

    // 5. AppSettingsService
    try {
      await Get.putAsync(() => AppSettingsService().init());
      logger.d('تم تهيئة AppSettingsService');
    } catch (e) {
      logger.e('خطأ في تهيئة AppSettingsService: $e');
    }

    // باقي الخدمات مع معالجة الأخطاء
    _initializeRemainingServices();

    logger.i('تم تهيئة جميع الخدمات بنجاح');
  } catch (e) {
    logger.e('خطأ في تهيئة الخدمات: $e');
    // لا توقف التطبيق، لكن اعرض رسالة للمستخدم
  }
}

void _initializeRemainingServices() {
  final services = [
    () => Get.put(ImageUploadService(), permanent: true),
    () => Get.put(FreeImageUploadService(), permanent: true),
    () => Get.put(LocalImageService(), permanent: true),
    () => Get.put(SmartImageService(), permanent: true),
    // () => Get.put(MockTestingService(), permanent: true),
    () => Get.put(DriverPaymentService(), permanent: true),
    () => Get.put(DriverDiscountService(), permanent: true),
    () => Get.put(FirebaseService(), permanent: true),
    () => Get.put(DriverProfileService(), permanent: true),
    () => Get.put(UserManagementService(), permanent: true),
    // () => Get.put(DiscountCodeService(), permanent: true),
    () => Get.put(NotificationTestService(), permanent: true),
  ];

  for (var serviceInit in services) {
    try {
      serviceInit();
    } catch (e) {
      logger.e('خطأ في تهيئة خدمة: $e');
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late AppController appController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // التأكد من وجود AppController
    try {
      appController = Get.find<AppController>();
    } catch (e) {
      logger.e('خطأ في العثور على AppController: $e');
      // إنشاء واحد جديد إذا لم يوجد
      appController = Get.put(AppController());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // تمرير حالة دورة حياة التطبيق للـ AppController مع التحقق من وجوده
    try {
      appController.onAppLifecycleStateChanged(state);
    } catch (e) {
      logger.e('خطأ في معالجة تغيير حالة التطبيق: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppController>(
      builder: (controller) => GetMaterialApp(
        title: 'تطبيق النقل',
        debugShowCheckedModeBanner: false,

        // الثيم
        theme: _getLightTheme(),
        darkTheme: _getDarkTheme(),
        themeMode:
            controller.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,

        // اللغة والتوطين
        locale: controller.currentLocale.value,
        fallbackLocale: const Locale('en', 'US'),
        // الصفحات والتوجيه
        initialRoute: AppRoutes.SPLASH,
        getPages: AppPages.routes,

        // اتجاه النص
        builder: (context, child) {
          return Directionality(
            textDirection: controller.currentLanguage.value == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: _buildAppWrapper(child!, controller),
          );
        },

        // معالج الأخطاء غير المتوقعة
        unknownRoute: GetPage(
          name: '/not-found',
          page: () => _buildNotFoundPage(),
        ),
      ),
    );
  }

  /// إنشاء wrapper للتطبيق مع شاشة التحميل العامة - إصلاح مشكلة Obx
  Widget _buildAppWrapper(Widget child, AppController controller) {
    return Stack(
      children: [
        child,

        // شاشة التحميل العامة
        Obx(() {
          if (controller.isLoading.value) {
            return _buildGlobalLoadingOverlay(controller);
          }
          return const SizedBox.shrink();
        }),

        // شاشة عدم الاتصال
        Obx(() {
          if (!controller.isConnected.value) {
            return _buildOfflineOverlay(controller);
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  /// شاشة التحميل العامة - إصلاح مشكلة Obx
  Widget _buildGlobalLoadingOverlay(AppController controller) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(
              horizontal: 32), // إضافة margin لتجنب overflow
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Obx(() => Text(
                    controller.loadingMessage.value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2, // تحديد عدد الأسطر لتجنب overflow
                    overflow: TextOverflow.ellipsis,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  /// شاشة عدم الاتصال - إصلاح مشكلة overflow
  Widget _buildOfflineOverlay(AppController controller) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.red,
        child: SafeArea(
          child: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'لا يوجد اتصال بالإنترنت',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis, // منع overflow
                ),
              ),
              Obx(() => Text(
                    _getConnectionTypeText(controller.connectionType.value),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  /// صفحة غير موجودة
  Widget _buildNotFoundPage() {
    return Scaffold(
      body: SafeArea(
        // إضافة SafeArea لتجنب مشاكل التخطيط
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'الصفحة غير موجودة',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'لم يتم العثور على الصفحة المطلوبة',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.SPLASH),
                  child: const Text('العودة للرئيسية'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// الحصول على نص نوع الاتصال مع معالجة null safety
  String _getConnectionTypeText(ConnectivityResult? type) {
    if (type == null) return 'غير معروف';

    switch (type) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'بيانات الهاتف';
      case ConnectivityResult.ethernet:
        return 'إيثرنت';
      default:
        return 'غير متصل';
    }
  }

  /// ثيم فاتح
  ThemeData _getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: Colors.blue,
      fontFamily: 'Cairo',

      // ألوان أساسية
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),

      // نصوص
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),

      // شريط التطبيق
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      // الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // البطاقات
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // حقول الإدخال
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  /// ثيم داكن
  ThemeData _getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: Colors.blue,
      fontFamily: 'Cairo',

      // ألوان أساسية
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),

      // نصوص
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),

      // شريط التطبيق
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      // الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // البطاقات
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // حقول الإدخال
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
