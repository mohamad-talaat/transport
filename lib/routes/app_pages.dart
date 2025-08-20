import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/routes/app_routes.dart';

// Controllers
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/controllers/map_controller.dart';
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/views/complete_profile_view.dart';
import 'package:transport_app/views/rider/phone_auth_view.dart';
import 'package:transport_app/views/rider/user_type_selection_view.dart';
import 'package:transport_app/views/rider/verify_otp_view.dart';

// Views
import 'package:transport_app/views/splash_view.dart';

// Rider Views
import 'package:transport_app/views/rider/rider_home_view.dart';
import 'package:transport_app/views/rider/rider_wallet_view.dart';
import 'package:transport_app/views/rider/rider_trip_history_view.dart';
import 'package:transport_app/views/rider/trip_tracking_view.dart';
import 'package:transport_app/views/rider/rider_profile_view.dart';
import 'package:transport_app/views/rider/rider_settings_view.dart';
import 'package:transport_app/views/rider/rider_about_view.dart';
import 'package:transport_app/views/rider/rider_notifications_view.dart';
import 'package:transport_app/views/rider/add_balance_view.dart';

// Driver Views
import 'package:transport_app/views/driver/driver_home_view.dart';
import 'package:transport_app/views/driver/driver_trip_tracking_view.dart';
import 'package:transport_app/views/driver/driver_trip_history_view.dart';
import 'package:transport_app/views/driver/driver_wallet_view.dart';
// import 'package:transport_app/views/driver/driver_profile_view.dart';
import 'package:transport_app/views/rider/rider_trip_details_view.dart';

class AppPages {
  static const INITIAL = AppRoutes.SPLASH;

  static final routes = [
    // Routes العامة
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashView(),
    ),
    GetPage(
      name: AppRoutes.USER_TYPE_SELECTION,
      page: () => UserTypeSelectionView(),
    ),
    GetPage(
      name: AppRoutes.PHONE_AUTH,
      page: () => PhoneAuthView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AuthController());
      }),
    ),
    GetPage(
      name: AppRoutes.VERIFY_OTP,
      page: () => const VerifyOtpView(),
    ),
    GetPage(
      name: AppRoutes.COMPLETE_PROFILE,
      page: () => const CompleteProfileView(),
    ),

    // Rider Routes
    GetPage(
      name: AppRoutes.RIDER_HOME,
      page: () => const RiderHomeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MapControllerr());
        Get.lazyPut(() => TripController());
      }),
    ),
    GetPage(
      name: AppRoutes.RIDER_WALLET,
      page: () => const RiderWalletView(),
    ),
    GetPage(
      name: AppRoutes.RIDER_TRIP_HISTORY,
      page: () => const RiderTripHistoryView(),
    ),
    GetPage(
      name: AppRoutes.RIDER_TRIP_TRACKING,
      page: () => const TripTrackingView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => TripController());
      }),
    ),
    GetPage(
      name: AppRoutes.RIDER_PROFILE,
      page: () => const RiderProfileView(),
    ),
    GetPage(
      name: AppRoutes.RIDER_SETTINGS,
      page: () => const RiderSettingsView(),
    ),
    GetPage(
      name: AppRoutes.RIDER_ABOUT,
      page: () => const RiderAboutView(),
    ),
    GetPage(
      name: AppRoutes.RIDER_NOTIFICATIONS,
      page: () => const RiderNotificationsView(),
    ),
    GetPage(
      name: AppRoutes.RIDER_ADD_BALANCE,
      page: () => const AddBalanceView(),
    ),
    GetPage(
      name: AppRoutes.RIDER_TRIP_DETAILS,
      page: () => const RiderTripDetailsView(),
    ),

    // Driver Routes
    GetPage(
      name: AppRoutes.DRIVER_HOME,
      page: () => DriverHomeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DriverController());
        Get.lazyPut(() => MapControllerr());
      }),
    ),
    GetPage(
      name: AppRoutes.DRIVER_TRIP_TRACKING,
      page: () => DriverTripTrackingView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MapControllerr());
      }),
    ),
    GetPage(
      name: AppRoutes.DRIVER_TRIP_HISTORY,
      page: () => DriverTripHistoryView(),
    ),
    GetPage(
      name: AppRoutes.DRIVER_WALLET,
      page: () => DriverWalletView(),
    ),
    GetPage(
      name: AppRoutes.DRIVER_EARNINGS,
      page: () => DriverWalletView(), // نفس شاشة المحفظة مؤقتاً
    ),
    GetPage(
      name: AppRoutes.DRIVER_PROFILE,
      page: () => DriverProfileView(),
    ),
    GetPage(
      name: AppRoutes.DRIVER_SETTINGS,
      page: () => DriverSettingsView(),
    ),
  ];
}

// شاشات إضافية للسائق سيتم إنشاؤها لاحقاً
class DriverProfileView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('شاشة الملف الشخصي للسائق - قيد التطوير'),
      ),
    );
  }
}

class DriverSettingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('شاشة الإعدادات للسائق - قيد التطوير'),
      ),
    );
  }
}
