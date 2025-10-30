import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart';
import 'package:transport_app/controllers/app_controller.dart';
import 'package:transport_app/routes/app_pages.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/binding/app_bindings.dart';
import 'package:transport_app/services/deep_link_service.dart';
import 'package:transport_app/services/map_services/map_singleton_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:transport_app/services/notification/notification_service.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);


void connectToLocalEmulator() {
  FirebaseFunctions.instance.useFunctionsEmulator("192.168.1.8", 5001);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // مهم جداً
  
    await Firebase.initializeApp();  
    connectToLocalEmulator();

await FMTCObjectBoxBackend().initialise(); // 🧠 ضروري قبل أي استخدام للخريطة
// await FMTCTileProvider.instance('mapStore').manage.create();
  //  printAndCopyFcmToken();
  await GetStorage.init();


  // ✅ تهيئة خدمة الإشعارات
  Get.put(NotificationService(), permanent: true);
  
  // معالجة الإشعارات في الخلفية`
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  

  
  Get.put(AppController(), permanent: true);

  // ✅ تحميل الماب مرة واحدة في بداية التطبيق
  // Get.put(MapSingletonService(), permanent: true);
  // ✅ استبدل MapSingletonService بـ MapService
  await Get.putAsync(() async => MapService(), permanent: true);
  Get.put(DeepLinkService(), permanent: true);
  runApp(const MyApp());
}
 
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // يمكنك التعامل مع الرسائل هنا إذا احتجت
  logger.w('📩 إشعار في الخلفية: ${message.data}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدم Get.put هنا لضمان وجود AppController قبل بناء GetMaterialApp
    // final AppController controller = Get.put(AppController());
    // الاستماع للإشعارات أثناء التطبيق شغال (foreground)

    // التعامل مع فتح التطبيق من إشعار (background / terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Get.offAllNamed(AppRoutes.DRIVER_HOME);
    });
    return GetMaterialApp(
      title: 'تطبيق النقل',
      debugShowCheckedModeBanner: false,

      // --- التعديل الجذري هنا ---
      initialBinding: AppBindings(), // استخدام الـ Bindings المركزية
      initialRoute: AppRoutes.SPLASH, // دائماً ابدأ من Splash
      // --------------------------

      getPages: AppPages.routes,

      // ... باقي الكود الخاص بالثيمات واللغة يبقى كما هو
      theme: _getLightTheme(),
      darkTheme: _getDarkTheme(),
      themeMode:
          AppController.to.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
      locale: AppController.to.currentLocale.value,
      fallbackLocale: const Locale('ar', 'IQ'),
      builder: (context, child) {
        return Directionality(
          textDirection: AppController.to.currentLanguage.value == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        );
      },
    );
  }

  // ... دوال الثيمات تبقى كما هي
  ThemeData _getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: Colors.blue,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
    );
  }

  ThemeData _getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: Colors.blue,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
    );
  }
}
