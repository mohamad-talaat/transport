import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:transport_app/routes/app_routes.dart';

// Controllers
import 'package:transport_app/controllers/auth_controller.dart';
 import 'package:transport_app/controllers/trip_controller.dart';
//  import 'package:transport_app/controllers/wallet_controller.dart';
import 'package:transport_app/views/complete_profile_view.dart';
import 'package:transport_app/views/rider/phone_auth_view.dart';
import 'package:transport_app/views/rider/user_type_selection_view.dart';
import 'package:transport_app/views/rider/verify_otp_view.dart';

// Views
import 'package:transport_app/views/splash_view.dart';
 
// Rider Views
import 'package:transport_app/views/rider/rider_home_view.dart';
// import 'package:transport_app/views/rider/rider_wallet_view.dart';
// import 'package:transport_app/views/rider/add_balance_view.dart';
// import 'package:transport_app/views/rider/trip_tracking_view.dart';

// // Driver Views
// import 'package:transport_app/views/driver/driver_home_view.dart';
 
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
      page: () => RiderHomeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MapController());
        Get.lazyPut(() => TripController());
      }),
    ),
    // GetPage(
    //   name: AppRoutes.RIDER_WALLET,
    //   page: () => RiderWalletView(),
    //   binding: BindingsBuilder(() {
    //     Get.lazyPut(() => WalletController());
    //   }),
    // ),
    // GetPage(
    //   name: AppRoutes.RIDER_ADD_BALANCE,
    //   page: () => AddBalanceView(),
    // ),
    // GetPage(
    //   name: AppRoutes.RIDER_TRIP_TRACKING,
    //   page: () => TripTrackingView(),
    //   binding: BindingsBuilder(() {
    //     Get.lazyPut(() => MapController());
    //     Get.lazyPut(() => TripController());
    //   }),
    // ),
    
    // Driver Routes
    // GetPage(
    //   name: AppRoutes.DRIVER_HOME,
    //   page: () => DriverHomeView(),
    //   binding: BindingsBuilder(() {
    //     Get.lazyPut(() => MapController());
    //     Get.lazyPut(() => TripController());
    //   }),
    // ),
  ];
}