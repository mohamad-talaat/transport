// ملف: views/splash_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/models/trip_model.dart'; // ✅ إضافة import لـ TripStatus

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  // نستخدم Get.find() لأن الـ Bindings قامت بإنشائها بالفعل
  final AuthController authController = Get.find();
  final TripController tripController = Get.find();
  final DriverController driverController = Get.find();

  @override
  void initState() {
    super.initState();
    // نستخدم addPostFrameCallback لضمان أن كل شيء تم بناؤه قبل التنقل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _decideNextRoute();
    });
  }
Future<void> _decideNextRoute() async {
  await Future.delayed(const Duration(seconds: 2));

  // ✅ انتظار تحميل بيانات المستخدم من GetStorage
  await authController.loadLoginState();
  
  if (!authController.isLoggedIn.value || authController.currentUser.value == null) {
    Get.offAllNamed(AppRoutes.USER_TYPE_SELECTION);
    return;
  }

  final user = authController.currentUser.value!;

  try {
    if (user.userType == UserType.rider) {
      // ✅ تحميل الرحلة النشطة للراكب
      await tripController.checkActiveTrip();
      final activeTrip = tripController.activeTrip.value;
      
      if (activeTrip != null && 
          activeTrip.status != TripStatus.cancelled && 
          activeTrip.status != TripStatus.completed) {
        logger.i('📦 الراكب: رحلة نشطة - الانتقال إلى تتبع الرحلة');
        Get.offAllNamed(AppRoutes.RIDER_TRIP_TRACKING);
      } else {
        logger.i('🏠 الراكب: لا توجد رحلة نشطة - الانتقال للهوم');
        Get.offAllNamed(AppRoutes.Rider_TYPE_SELECTION);
      }
    } 
    else if (user.userType == UserType.driver) {
      // ✅ فحص حالة الدفع المعلق أولاً
      final paymentLock = driverController.storage.read('paymentLock');
      if (paymentLock != null && paymentLock['status'] == 'pending') {
        logger.i('💳 دفع معلق - الانتقال إلى صفحة الدفع');
        await driverController.surePayment();
        return; // surePayment() ستوجه إلى الصفحة الصحيحة
      }
      
      // ✅ تحميل الرحلة النشطة للسائق
      await driverController.checkActiveTrip();
      final currentTrip = driverController.currentTrip.value;
      
      if (currentTrip != null && 
          currentTrip.status != TripStatus.cancelled && 
          currentTrip.status != TripStatus.completed) {
        logger.i('📦 السائق: رحلة نشطة - الانتقال إلم تتبع الرحلة');
        Get.offAllNamed(AppRoutes.DRIVER_TRIP_TRACKING);
      } else {
        logger.i('🏠 السائق: لا توجد رحلة نشطة - الانتقال للهوم');
        Get.offAllNamed(AppRoutes.DRIVER_HOME);
      }
    }
  } catch (e) {
    logger.e('❌ خطأ في تحديد المسار: $e');
    // ✅ في حالة الخطأ، انتقل إلى الصفحة الرئيسية بناءً على نوع المستخدم
    if (user.userType == UserType.rider) {
      Get.offAllNamed(AppRoutes.Rider_TYPE_SELECTION);
    } else if (user.userType == UserType.driver) {
      Get.offAllNamed(AppRoutes.DRIVER_HOME);
    } else {
      Get.offAllNamed(AppRoutes.USER_TYPE_SELECTION);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange, // لون الخلفية
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(Icons.local_taxi, color: Colors.white, size: 80),
            // t.png
            Image.asset("assets/images/t.png", width: 140, height: 140),
            const SizedBox(height: 20),
            const Text("تكسي البصرة",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
