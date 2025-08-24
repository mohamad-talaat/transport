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
import 'package:transport_app/views/rider/rider_searching_view.dart';
import 'package:transport_app/views/rider/rider_wallet_view.dart';
import 'package:transport_app/views/rider/rider_trip_history_view.dart';
import 'package:transport_app/views/rider/trip_tracking_view.dart';
import 'package:transport_app/views/rider/rider_profile_view.dart';
import 'package:transport_app/views/rider/rider_settings_view.dart';
import 'package:transport_app/views/rider/rider_about_view.dart';
import 'package:transport_app/views/rider/rider_notifications_view.dart';
import 'package:transport_app/views/rider/add_balance_view.dart';

// Driver Views
import 'package:transport_app/views/driver/driver_home_improved_view.dart';
import 'package:transport_app/views/driver/driver_trip_tracking_view.dart';
import 'package:transport_app/views/driver/driver_trip_history_view.dart';
import 'package:transport_app/views/driver/driver_wallet_view.dart';
import 'package:transport_app/views/driver/driver_profile_completion_view.dart';
import 'package:transport_app/views/driver/driver_profile_edit_view.dart';
// import 'package:transport_app/views/driver/driver_profile_view.dart';
import 'package:transport_app/views/rider/rider_trip_details_view.dart';

// Admin Views
import 'package:transport_app/views/admin/admin_dashboard_view.dart';

// Settings Views
import 'package:transport_app/views/settings/image_upload_settings_view.dart';

// Services
import 'package:transport_app/services/image_upload_service.dart';
import 'package:transport_app/services/mock_testing_service.dart';

// Testing Views
import 'package:transport_app/views/testing/mock_testing_view.dart';
import 'package:transport_app/services/notification_service.dart';

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
      name: AppRoutes.RIDER_SEARCHING,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return RiderSearchingView(
          pickup: args?['pickup'],
          destination: args?['destination'],
          estimatedFare: args?['estimatedFare'] ?? 0.0,
          estimatedDuration: args?['estimatedDuration'] ?? 0,
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
      name: AppRoutes.DRIVER_PROFILE_COMPLETION,
      page: () => const DriverProfileCompletionView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ImageUploadService());
      }),
    ),
    GetPage(
      name: AppRoutes.DRIVER_HOME,
      page: () => const DriverHomeImprovedView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DriverController());
        Get.lazyPut(() => MapControllerr());
      }),
    ),
    GetPage(
      name: AppRoutes.DRIVER_TRIP_TRACKING,
      page: () => const DriverTripTrackingView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MapControllerr());
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
      page: () => const DriverWalletView(), // نفس شاشة المحفظة مؤقتاً
    ),
    GetPage(
      name: AppRoutes.DRIVER_PROFILE,
      page: () => const DriverProfileView(),
    ),
    GetPage(
      name: AppRoutes.DRIVER_PROFILE_EDIT,
      page: () => const DriverProfileEditView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ImageUploadService());
      }),
    ),
    GetPage(
      name: AppRoutes.DRIVER_SETTINGS,
      page: () => const DriverSettingsView(),
    ),

    // Admin Routes
    GetPage(
      name: AppRoutes.ADMIN_DASHBOARD,
      page: () => const AdminDashboardView(),
      binding: BindingsBuilder(() {
        // AppSettingsService is already initialized in main.dart
      }),
    ),

    // Settings Routes
    GetPage(
      name: AppRoutes.IMAGE_UPLOAD_SETTINGS,
      page: () => const ImageUploadSettingsView(),
    ),

    // Testing Routes
    GetPage(
      name: AppRoutes.MOCK_TESTING,
      page: () => const MockTestingView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MockTestingService());
      }),
    ),
  ];
}

// شاشات إضافية للسائق سيتم إنشاؤها لاحقاً
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
          const SizedBox(height: 8),
          Obx(() => SwitchListTile(
                title: const Text('تفعيل الإشعارات'),
                value: notificationService.notificationsEnabled.value,
                onChanged: (v) =>
                    notificationService.updateNotificationSettings(enabled: v),
              )),
          Obx(() => SwitchListTile(
                title: const Text('الصوت'),
                value: notificationService.soundEnabled.value,
                onChanged: (v) =>
                    notificationService.updateNotificationSettings(sound: v),
              )),
          Obx(() => SwitchListTile(
                title: const Text('الاهتزاز'),
                value: notificationService.vibrationEnabled.value,
                onChanged: (v) => notificationService
                    .updateNotificationSettings(vibration: v),
              )),
          const SizedBox(height: 24),
          const Text('رفع الصور',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('إعدادات رفع الصور'),
            subtitle: const Text('اختر طريقة رفع الصور المفضلة'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Get.toNamed(AppRoutes.IMAGE_UPLOAD_SETTINGS),
          ),
        ],
      ),
    );
  }
}
