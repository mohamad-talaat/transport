import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:transport_app/services/app_settings_service.dart';
import 'package:transport_app/services/discount_code_service.dart';
import 'package:transport_app/services/driver_discount_service.dart';
import 'package:transport_app/services/driver_profile_service.dart';
// <-- استيراد مهم
// <-- استيراد مهم
// <-- استيراد مهم
import 'package:transport_app/services/location_service.dart';
import 'package:transport_app/services/notification/notification_service.dart';
import 'package:transport_app/services/unified_image_service.dart';
import 'package:transport_app/services/user_management_service.dart';
import 'package:transport_app/views/common/chat_service/communication_service.dart';
import 'package:transport_app/services/map_services/markers_cleanup_service.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    
    // ===================================================================
    // المرحلة الأولى: حقن الخدمات الأساسية التي لا تعتمد على متحكمات
    // ===================================================================
    Get.put(AuthController(), permanent: true); // 👈 انقل هذا إلى هنا
    Get.lazyPut(() => AppSettingsService());
    Get.putAsync(() => AppSettingsService().init(), permanent: true); // ✅
    // Get.put(FirebaseService(), permanent: true);
    Get.put(LocationService(), permanent: true);
    Get.put(NotificationService(), permanent: true);

    // خدمات الصور يجب أن تكون موجودة قبل ImageUploadService
    // Get.put(ImageUploadService(), permanent: true);
    // Get.put(FreeImageUploadService(), permanent: true);
    Get.put(ImageUploadService(), permanent: true);
    // Get.put(LocalImageService(), permanent: true);
    Get.put(MarkersCleanupService(
      markers: Get.put(MyMapController()).markers,
    ));
    // // الآن يمكننا حقن ImageUploadService لأنه يجد الخدمات التي يعتمد عليها
    // Get.put(ImageUploadService(), permanent: true);

    // ===================================================================
    // المرحلة الثانية: حقن المتحكمات الرئيسية
    // ===================================================================
    // AuthController هو الأهم ويجب أن يكون أولاً لأنه قد يُستخدم من قبل الآخرين
    // Get.put(AuthController(), permanent: true);
    Get.put(MyMapController(), permanent: true);

    // هذه الخدمات تعتمد على AuthController، لذا نضعها بعده
    Get.put(CommunicationService(), permanent: true);
    Get.put(UserManagementService(), permanent: true);
    Get.put(DriverProfileService(), permanent: true);

    // المتحكمات الرئيسية الأخرى التي قد تعتمد على AuthController
    Get.put(TripController(), permanent: true);
    Get.put(DriverController(), permanent: true);

    // ===================================================================
    // المرحلة الثالثة: الخدمات والمتحكمات المؤقتة (Lazy-loaded)
    // ===================================================================
    Get.lazyPut(() => DiscountCodeService());
   Get.lazyPut(() => DriverDiscountService());
    // Get.lazyPut(() => DriverPaymentService());
  }
}
