import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/routes/app_routes.dart';

import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/services/notification/notification_service.dart';
import 'package:transport_app/services/unified_image_service.dart';
import 'package:transport_app/views/common/chat_service/chat_page_basic.dart';
import 'package:transport_app/views/driver/driver_payment_confirmation_view.dart';
import 'package:transport_app/views/rider/phone_auth_view.dart';
import 'package:transport_app/views/rider/rider_profile_completion_view.dart';
import 'package:transport_app/views/user_type_selection_view.dart';
import 'package:transport_app/views/rider/verify_otp_view.dart';

import 'package:transport_app/views/splash_view.dart';

import 'package:transport_app/views/rider/rider_home_view.dart';
import 'package:transport_app/views/rider/rider_searching_view.dart';
import 'package:transport_app/views/rider/rider_wallet_view.dart';
import 'package:transport_app/views/rider/rider_trip_history_view.dart';
import 'package:transport_app/views/rider/rider_trip_tracking_view.dart';
import 'package:transport_app/views/rider/rider_profile_view.dart';
 import 'package:transport_app/views/rider/rider_widgets/rider_about_view.dart';
import 'package:transport_app/views/rider/trip_cancellation_reasons_view.dart';
import 'package:transport_app/views/rider/edit_trip_widgets/edit_trip_location_view.dart';
import 'package:transport_app/views/shared/trip_rating_view.dart';

import 'package:transport_app/views/driver/driver_home_view.dart';
import 'package:transport_app/views/driver/driver_trip_tracking_view.dart';
import 'package:transport_app/views/driver/driver_trip_history_view.dart';
import 'package:transport_app/views/driver/driver_wallet_view.dart';
import 'package:transport_app/views/driver/driver_profile_completion_view.dart';

import 'package:transport_app/views/rider/rider_trip_details_view.dart';

import 'package:transport_app/views/rider_type_selection_view.dart';

class AppPages {
  static const INITIAL = AppRoutes.SPLASH;

  static final routes = [
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
    // GetPage(
    //   name: AppRoutes.COMPLETE_PROFILE,
    //   page: () => const CompleteProfileView(),
    // ),
    GetPage(
      name: AppRoutes.RIDER_HOME,
       page: () => const RiderHomeView(),
     // page: () => const RiderHomeViewOptimized(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MyMapController());
        Get.lazyPut(() => TripController());
      }),
    ),
    GetPage(
      name: AppRoutes.RIDER_SEARCHING,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final pickupArg = args?['pickup'];
        final destinationArg = args?['destination'];
        final estimatedFareArg = (args?['estimatedFare'] ?? 0.0) as num;
        final estimatedDurationArg = (args?['estimatedDuration'] ?? 0) as int;

        final trip = Get.isRegistered<TripController>()
            ? TripController.to.activeTrip.value
            : null;
        final pickup = pickupArg ?? trip?.pickupLocation;
        final destination = destinationArg ?? trip?.destinationLocation;
        final estimatedFare = pickupArg != null && destinationArg != null
            ? estimatedFareArg.toDouble()
            : (trip?.fare ?? 0.0);
        final estimatedDuration = pickupArg != null && destinationArg != null
            ? estimatedDurationArg
            : (trip?.estimatedDuration ?? 0);

        if (pickup == null || destination == null) {
          Future.microtask(() {
            Get.snackbar(
              'بيانات غير مكتملة',
              'يرجى اختيار نقطة الانطلاق والوجهة أولاً',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            if (Get.currentRoute == AppRoutes.RIDER_SEARCHING) {
              Get.offAllNamed(AppRoutes.RIDER_HOME);
            }
          });
          return const RiderHomeView();
         //  return const RiderHomeViewOptimized();
        }

        return RiderSearchingView(
          pickup: pickup,
          destination: destination,
          estimatedFare: estimatedFare.toDouble(),
          estimatedDuration: estimatedDuration,
        );
      },
      binding: BindingsBuilder(() {
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
      page: () => const RiderTripTrackingView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => TripController());
      }),
    ),
    GetPage(
      name: AppRoutes.RIDER_PROFILE,
      page: () => const RiderProfileView(),
    ),
    GetPage(
      name: AppRoutes.RIDER_PROFILE_COMPLETION,
      page: () => const RiderProfileCompletionView(),
    ),
  //   GetPage(
  //     name: AppRoutes.RIDER_SETTINGS,
  //     page: () => const RiderSettingsView(),
  //   ),
  // GetPage(
  //     name: AppRoutes.RIDER_NOTIFICATIONS,
  //     page: () => const RiderNotificationsView(),
  //   ), 
    
       GetPage(
      name: AppRoutes.RIDER_ABOUT,
      page: () => const RiderAboutView(),
    ),
  
    // GetPage(
    //   name: AppRoutes.RIDER_ADD_BALANCE,
    //   page: () => const AddBalanceView(),
    // ),
    GetPage(
      name: AppRoutes.RIDER_TRIP_DETAILS,
      page: () => const RiderTripDetailsView(),
    ),
    GetPage(
      name: AppRoutes.RIDER_TRIP_CANCELLATION_REASONS,
      page: () => const TripCancellationReasonsView(),
    ),
    GetPage(
      name: AppRoutes.DRIVER_PROFILE_COMPLETION,
      page: () => const DriverProfileCompletionView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ImageUploadService());
      }),
    ),
    GetPage(
      name: AppRoutes.DRIVER_HOME,
      page: () => const DriverHomeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DriverController());
        Get.lazyPut(() => MyMapController());
      }),
    ),
    // GetPage(
    //   name: AppRoutes.DRIVER_PAYMENT_DETAILS,
    //   page: () => const DriverPaymentCollectionView(),
    // ),
    GetPage(
      name: AppRoutes.DRIVER_PAYMENT_CONFIRMATION,
      page: () => const DriverPaymentConfirmationView(),
    ),
    GetPage(
      name: AppRoutes.DRIVER_TRIP_TRACKING,
      page: () => const DriverTripTrackingView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MyMapController());
      }),
    ),
    GetPage(
      name: AppRoutes.DRIVER_TRIP_HISTORY,
      page: () => const DriverTripHistoryView(),
    ),
    GetPage(
      name: AppRoutes.DRIVER_WALLET,
      page: () => const DriverWalletView(),
    ),
    GetPage(
      name: AppRoutes.DRIVER_EARNINGS,
      page: () => const DriverWalletView(),
    ),
    GetPage(
      name: AppRoutes.DRIVER_PROFILE,
      page: () => const DriverProfileCompletionView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ImageUploadService());
      }),
    ),
    GetPage(
      name: AppRoutes.DRIVER_SETTINGS,
      page: () => const DriverSettingsView(),
    ),
    // GetPage(
    //   name: AppRoutes.IMAGE_UPLOAD_SETTINGS,
    //   page: () => const ImageUploadSettingsView(),
    // ),
    GetPage(
      name: AppRoutes.Rider_TYPE_SELECTION,
      page: () => const RiderTypeSelectionView(),
    ),
    GetPage(
      name: AppRoutes.CHAT,
      page: () => const ChatPage(),
      binding: BindingsBuilder(() {}),
    ),
    GetPage(
      name: AppRoutes.TRIP_RATING,
      page: () => const TripRatingView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => TripController());
      }),
    ),
    GetPage(
      name: AppRoutes.EDIT_TRIP_LOCATION,
      page: () => const EditTripLocationView(),
    ),
    // Admin Tools
    // GetPage(
    //   name: AppRoutes.DATA_CLEANUP,
    //   page: () => const DataCleanupPage(),
    // ),
  ];
}

class DriverProfileView extends StatelessWidget {
  const DriverProfileView({super.key});

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
  const DriverSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService.to;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('الإشعارات',
              style: TextStyle(fontWeight: FontWeight.bold)),
          // const SizedBox(height: 8),
          // Obx(() => SwitchListTile(
          //       title: const Text('تفعيل الإشعارات'),
          //       value: notificationService.notifEnabled.value,
          //       onChanged: (v) =>
          //           notificationService.updateSettings(enabled: v),
          //     )),
          Obx(() => SwitchListTile(
                title: const Text('الصوت'),
                value: notificationService.soundEnabled.value,
                onChanged: (v) => notificationService.updateSettings(sound: v),
              )),
          // Obx(() => SwitchListTile(
          //       title: const Text('الاهتزاز'),
          //       value: notificationService.vibrationEnabled.value,
          //       onChanged: (v) =>
          //           notificationService.updateSettings(vibration: v),
          //     )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
