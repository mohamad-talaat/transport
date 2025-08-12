import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/app_controller.dart';
import 'package:transport_app/routes/app_pages.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/location_service.dart';
import 'package:transport_app/services/notification_service.dart';
import 'package:logger/logger.dart';
 
 var logger = Logger(
  printer: PrettyPrinter(),
); 

// var loggerNoStack = Logger(
//   printer: PrettyPrinter(methodCount: 0),
// );
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Firebase

await Firebase.initializeApp(
  // options: DefaultFirebaseOptions.currentPlatform,
);  
  // تهيئة الخدمات
  await initServices();
  
  runApp(const MyApp());
}

Future<void> initServices() async {
  try {
    // تهيئة الخدمات الأساسية بالترتيب الصحيح
    
    // 1. AppController (يجب أن يكون الأول)
    Get.put(AppController());
    
    // 2. NotificationService
    await Get.putAsync(() => NotificationService().init());
    
    // 3. LocationService
    await Get.putAsync(() => LocationService().init());
    
    logger.i('تم تهيئة جميع الخدمات بنجاح');
    
  } catch (e) {
    logger.i('خطأ في تهيئة الخدمات: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AppController appController = Get.find<AppController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // تمرير حالة دورة حياة التطبيق للـ AppController
    appController.onAppLifecycleStateChanged(state);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => GetMaterialApp(
      title: 'تطبيق النقل',
      debugShowCheckedModeBanner: false,
      
      // الثيم
      theme: _getLightTheme(),
      darkTheme: _getDarkTheme(),
      themeMode: appController.isDarkMode.value 
          ? ThemeMode.dark 
          : ThemeMode.light,
      
      // اللغة والتوطين
      locale: appController.currentLocale.value,
      fallbackLocale: const Locale('en', 'US'),
      
      // الصفحات والتوجيه
      initialRoute: AppRoutes.SPLASH,
      getPages: AppPages.routes,
      
      // اتجاه النص
      builder: (context, child) {
        return Directionality(
          textDirection: appController.currentLanguage.value == 'ar' 
              ? TextDirection.rtl 
              : TextDirection.ltr,
          child: _buildAppWrapper(child!),
        );
      },
      
      // معالج الأخطاء غير المتوقعة
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => _buildNotFoundPage(),
      ),
    ));
  }

  /// إنشاء wrapper للتطبيق مع شاشة التحميل العامة
  Widget _buildAppWrapper(Widget child) {
    return Obx(() => Stack(
      children: [
        child,
        
        // شاشة التحميل العامة
        if (appController.isLoading.value)
          _buildGlobalLoadingOverlay(),
        
        // شاشة عدم الاتصال
        if (!appController.isConnected.value)
          _buildOfflineOverlay(),
      ],
    ));
  }

  /// شاشة التحميل العامة
  Widget _buildGlobalLoadingOverlay() {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
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
                appController.loadingMessage.value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              )),
            ],
          ),
        ),
      ),
    );
  }

  /// شاشة عدم الاتصال
  Widget _buildOfflineOverlay() {
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
                ),
              ),
              Obx(() => Text(
                _getConnectionTypeText(appController.connectionType.value),
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
      body: Center(
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
            ),
            const SizedBox(height: 8),
            Text(
              'لم يتم العثور على الصفحة المطلوبة',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Get.offAllNamed(AppRoutes.SPLASH),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    );
  }

  /// الحصول على نص نوع الاتصال
  String _getConnectionTypeText(ConnectivityResult type) {
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
      cardTheme: CardTheme(
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
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
      cardTheme: CardTheme(
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
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
