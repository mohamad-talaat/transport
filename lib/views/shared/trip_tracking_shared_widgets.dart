import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/utils/province_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:transport_app/utils/image_helper.dart';
import 'package:screenshot/screenshot.dart';

/// ملف مشترك لكل الويدجتس والوظائف المستخدمة في تتبع الرحلات
/// يخدم كل من السائق والراكب
class TripTrackingSharedWidgets {
  // ==================== Info Sections ====================

  /// بناء قسم معلومات المستخدم (السائق أو الراكب)
  static Widget buildUserInfoSection({
    required UserModel? user,
    required String userType, // 'driver' or 'rider'
    required TripModel trip,
    required VoidCallback onChatPressed,
    required VoidCallback onCallPressed,
  }) {
    return Row(
      children: [
        ImageHelper.buildAvatar(
          imagePath: user?.profileImage,
          radius: 30,
          fallbackIcon: Icons.person,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? (userType == 'driver' ? 'السائق' : 'الراكب'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (user?.phone != null)
                Text(
                  user!.phone,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
        buildSmallActionButton(
          icon: Icons.chat_bubble_outline,
          label: 'رسالة',
          color: Colors.blue,
          onPressed: onChatPressed,
        ),
        const SizedBox(width: 4),
        buildSmallActionButton(
          icon: Icons.phone,
          label: 'اتصال',
          color: Colors.green,
          onPressed: onCallPressed,
        ),
      ],
    );
  }

  /// بناء قسم معلومات المستخدم الموسع (مع التقييم والرحلات)
  static Widget buildUserInfoSectionExpanded({
    required UserModel? user,
    required String userType,
    required TripModel trip,
    required VoidCallback onChatPressed,
    required VoidCallback onCallPressed,
  }) {
    return Row(
      children: [
        ImageHelper.buildAvatar(
          imagePath: user?.profileImage,
          radius: 30,
          fallbackIcon: Icons.person,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? (userType == 'driver' ? 'السائق' : 'الراكب'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    user?.rating != null && user!.rating! > 0
                        ? user.rating!.toStringAsFixed(1)
                        : 'جديد',
                    style: const TextStyle(
                      //fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        buildSmallActionButton(
          icon: Icons.chat_bubble_outline,
          label: 'رسالة',
          color: Colors.blue,
          onPressed: onChatPressed,
        ),
        const SizedBox(width: 4),
        buildSmallActionButton(
          icon: Icons.phone,
          label: 'اتصال',
          color: Colors.green,
          onPressed: onCallPressed,
        ),
      ],
    );
  }

  // ==================== Vehicle Info ====================

  /// بناء قسم معلومات السيارة (قابل للتوسيع)
  static Widget buildVehicleInfo(UserModel? driver) {
    // استخدام ويدجت ExpansionTile لجعل معلومات السيارة قابلة للتوسيع
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      // استخدام Theme لإزالة الخط الفاصل الافتراضي في ExpansionTile
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 4.0),
          leading:
              Icon(Icons.directions_car_filled, color: Colors.blue.shade700),
          title: const Text(
            'معلومات السيارة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          children: [
            Column(
              children: [
                const SizedBox(height: 4),
                buildInfoRow(
                  icon: Icons.directions_car,
                  label: 'نوع السيارة',
                  value: driver?.vehicleModel ?? 'غير محدد',
                ),
                const SizedBox(height: 8),
                buildInfoRow(
                  icon: Icons.palette,
                  label: 'اللون',
                  value: driver?.vehicleColor ?? 'غير محدد',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.confirmation_number,
                        size: 18, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'رقم اللوحة:',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const Spacer(),
                    buildVehiclePlate(
                      driver?.plateNumber ?? '00000',
                      driver?.provinceName ?? " غير محدد",
                      provinceCode: driver?.provinceCode,
                      letter: driver?.plateLetter,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء لوحة السيارة
  /// لوحة السيارة بثلاث خانات: الأرقام | الحرف | العاصمة
  static Widget buildVehiclePlate(String plateNumber, String provinceName,
      {String? letter, String? provinceCode}) {
    // final digits = plateNumber.padLeft(5, '0');
    // final provinceName = ProvinceHelper.getProvinceName(provinceCode);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          // القسم 1: الأرقام
          Container(
            width: 60,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            child: Text(
              plateNumber,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // القسم 2: الحرف (لو موجود)
          Container(
            width: 25,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            child: Text(
              (letter ?? '').toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // القسم 3: العاصمة
          Container(
            width: 60,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  provinceName ?? 'العاصمة',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Text(
                //   provinceCode ?? '',
                //   style: const TextStyle(fontSize: 10, color: Colors.grey),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Info Rows ====================

  /// بناء صف معلومات
  static Widget buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              fontSize: isHighlighted ? 15 : 14,
              color: isHighlighted ? Colors.blue.shade800 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== Action Buttons ====================

  /// بناء زر إجراء صغير
  static Widget buildSmallActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: color,
          iconSize: 18,
          style: IconButton.styleFrom(
            backgroundColor: color.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(1),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ==================== Top Info Bar ====================

  /// بناء شريط المعلومات العلوي
  static Widget buildTopInfoBar(BuildContext context, TripModel trip) {
    return Positioned(
      top: 25,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: TripTrackingSharedWidgets.getStatusColor(trip.status)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(TripTrackingSharedWidgets.getStatusIcon(trip.status),
                      color:
                          TripTrackingSharedWidgets.getStatusColor(trip.status),
                      size: 16),
                  const SizedBox(width: 6),
                  Text(
                    TripTrackingSharedWidgets.getStatusText(trip.status),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: TripTrackingSharedWidgets.getStatusColor(
                            trip.status)),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${trip.fare.toStringAsFixed(0)} د.ع',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                    fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Map Controls ====================

  /// بناء أدوات التحكم بالخريطة
  static Widget buildNavigationMap({
    required BuildContext context,
    required TripModel trip,
    required VoidCallback onNavigatePressed,
  }) {
    return Positioned(
      bottom: MediaQuery.sizeOf(context).height / 4 - 70,
      right: 10,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: "navigate_fab",
            backgroundColor: Colors.white,
            onPressed: onNavigatePressed,
            child: const Icon(Icons.navigation, color: Colors.orange),
          ),
          const SizedBox(height: 1), // مسافة بسيطة بين الزر والنص
          const Text(
            'تحديد المسار',
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Expandable Details ====================

  /// بناء قسم التفاصيل القابل للتوسيع
  Widget buildExpandableDetails({
    required TripModel trip,
    required ValueNotifier<bool> isExpandedNotifier,
    bool showTripPaths = false,
  }) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        leading:
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 22),
        title: const Text(
          'تفاصيل إضافية',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        onExpansionChanged: (expanded) {
          isExpandedNotifier.value = expanded;
        },
        children: [
          TripTrackingSharedWidgets.buildDetailRow(
            icon: Icons.straighten,
            label: 'المسافة الكلية',
            value: '${trip.distance.toStringAsFixed(1)} كم',
            color: Colors.blue,
          ),
          const SizedBox(height: 6),
          TripTrackingSharedWidgets.buildDetailRow(
            icon: Icons.access_time,
            label: 'الوقت المتوقع',
            value: '${trip.estimatedDuration.toStringAsFixed(0)} دقيقة',
            color: Colors.orange,
          ),
          const SizedBox(height: 6),
          TripTrackingSharedWidgets.buildDetailRow(
            icon: Icons.attach_money,
            label: 'التكلفة',
            value: '${trip.fare.toStringAsFixed(0)} د.ع',
            color: Colors.green,
          ),
          if (trip.paymentMethod != null) ...[
            const SizedBox(height: 6),
            TripTrackingSharedWidgets.buildDetailRow(
              icon: trip.paymentMethod == 'cash'
                  ? Icons.payments
                  : Icons.credit_card,
              label: 'طريقة الدفع',
              value: trip.paymentMethod == 'cash' ? 'نقداً' : 'إلكتروني',
              color: Colors.purple,
            ),
            const SizedBox(height: 6),
            TripTrackingSharedWidgets.buildDetailRow(
              icon: Icons.transfer_within_a_station_outlined,
              label: 'وقت الانتظار',
              value: '${trip.waitingTime.toStringAsFixed(0)} دقيقة',
              color: Colors.orange,
            ),
          ],
          // if (showTripPaths) ...[
          const SizedBox(height: 10),
          buildTripPathsDetails(trip),
          //
          //
          // ],
        ],
      ),
    );
  }

  /// بناء تفاصيل المسارات
  static Widget buildTripPathsDetails(TripModel trip) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 248, 237, 154),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.flag, size: 18, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'انطلاق: ${trip.pickupLocation.address}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.pin_drop, size: 18, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'وصول: ${trip.destinationLocation.address}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (trip.additionalStops.isNotEmpty)
            ...trip.additionalStops.map((stop) => Padding(
                  padding: const EdgeInsets.only(top: 4, left: 26),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on,
                          size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'توقف ${stop.stopNumber}: ${stop.address}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade800),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  // ==================== Chat & Call Functions ====================

  /// فتح المحادثة
  static void openChat({
    required TripModel trip,
    required String otherUserId,
    required String otherUserName,
    required String currentUserType, // 'driver' or 'rider'
  }) {
    Get.toNamed(
      AppRoutes.CHAT,
      arguments: {
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'tripId': trip.id,
        'currentUserType': currentUserType,
      },
    );
  }

  /// نافذة الاختيار بين الهاتف أو واتساب
  static void showCallOptions(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      Get.snackbar('خطأ', 'رقم الهاتف غير متاح',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: const Text('الاتصال عبر الهاتف'),
              onTap: () {
                Get.back();
                makePhoneCall(phoneNumber);
              },
            ),
            ListTile(
              leading: Image.asset("assets/images/whatsapp.png",
                  width: 32,
                  height: 32), //Icon(Icons.whatshot, color: Colors.green),
              title: const Text('الاتصال عبر واتساب'),
              onTap: () {
                Get.back();
                openWhatsApp(phoneNumber);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// الاتصال بالهاتف
  static Future<void> makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      Get.snackbar('خطأ', 'رقم الهاتف غير متاح',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Get.snackbar('خطأ', 'تعذر إجراء الاتصال',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// فتح واتساب
  static Future<void> openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(' ', '').replaceAll('+', '');
    final url = 'https://wa.me/$cleanPhone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication); // يفتح واتساب خارجيًا
    } else {
      Get.snackbar('خطأ', 'تعذر فتح واتساب',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  static Widget buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static IconData getStatusIcon(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
      case TripStatus.accepted:
        return Icons.directions_car;
      case TripStatus.driverArrived:
        return Icons.location_on;
      case TripStatus.inProgress:
        return Icons.route;
      case TripStatus.completed:
        return Icons.check_circle;
      case TripStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  static Color getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.accepted:
        return Colors.blue.shade600;
      case TripStatus.driverArrived:
        return Colors.orange.shade600;
      case TripStatus.inProgress:
        return Colors.green.shade600;
      case TripStatus.completed:
        return Colors.green.shade800;
      case TripStatus.cancelled:
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  static String getStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
      case TripStatus.accepted:
        return 'السائق في الطريق إليك';
      case TripStatus.driverArrived:
        return 'السائق وصل!';
      case TripStatus.inProgress:
        return 'في الطريق إلى الوجهة';
      case TripStatus.completed:
        return 'تم الوصول بنجاح';
      case TripStatus.cancelled:
        return 'تم إلغاء الرحلة';
      default:
        return 'جاري التحديث...';
    }
  }

  static String getStatusDescription(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
      case TripStatus.accepted:
        return 'يرجى الانتظار في مكانك';
      case TripStatus.driverArrived:
        return 'السائق ينتظرك الآن';
      case TripStatus.inProgress:
        return 'استرخِ واستمتع بالرحلة';
      case TripStatus.completed:
        return 'شكراً لاستخدامك تطبيقنا';
      case TripStatus.cancelled:
        return 'يمكنك طلب رحلة جديدة';
      default:
        return '';
    }
  }

  static Future<void> callNumber(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Get.snackbar('خطأ', 'تعذر الاتصال بالرقم',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

//   static Future<void> shareTrip(TripModel trip) async {
//     final trackingUrl = 'https://taksi-elbasra.app/track/${trip.id}';

//     final message = '''
// رحلة تاكسي البصرة

// من: ${trip.pickupLocation.address}
// إلى: ${trip.destinationLocation.address}
// إلى: ${trip.additionalStops.isNotEmpty ? trip.additionalStops.map((s) => s.address).join(', ') : 'لا توجد توقفات إضافية'}


// السائق: ${trip.driver?.name ?? 'غير متوفر'}
// الهاتف: ${trip.driver?.phone ?? 'غير متوفر'}
// السيارة: ${trip.driver?.vehicleModel ?? ''} ${trip.driver?.vehicleColor ?? ''}
// اللوحة: ${trip.driver?.plateNumber ?? 'غير متوفر'} ${trip.driver?.plateLetter ?? 'غير متوفر'} ${trip.driver?.provinceName ?? 'غير متوفر'}

// التكلفة: ${trip.fare.toStringAsFixed(0)} د.ع
// الوقت المتوقع: ${trip.estimatedDuration} دقيقة

// تتبع الرحلة:
// $trackingUrl

// رقم الرحلة: #${trip.id}
// ''';

//     try {
//       await Share.share(
//         message,
//         subject: 'رحلة تاكسي البصرة - #${trip.id}',
//       );
//     } catch (e) {
//       await Clipboard.setData(ClipboardData(text: message));
//       Get.snackbar(
//         'تم النسخ',
//         'تم نسخ تفاصيل الرحلة للحافظة',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//       );
//     }
//   }
static Future<void> shareTripWithScreenshot(
  TripModel trip,
  ScreenshotController screenshotController,
) async {
  try {
    // 🖼️ التقط الصورة
    final imageBytes = await screenshotController.capture();

    if (imageBytes == null) {
      Get.snackbar(
        'خطأ',
        'تعذر أخذ لقطة الشاشة',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // 🗂️ احفظها مؤقتًا
    final directory = await getTemporaryDirectory();
    final imagePath = '${directory.path}/trip_${trip.id}.png';
    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(imageBytes);

    // ✉️ حضّر الرسالة النصية
    final message = '''
🚖 رحلة تاكسي البصرة

من: ${trip.pickupLocation.address}
إلى: ${trip.destinationLocation.address}

السائق: ${trip.driver?.name ?? 'غير متوفر'}
الهاتف: ${trip.driver?.phone ?? 'غير متوفر'}
التكلفة: ${trip.fare.toStringAsFixed(0)} د.ع

رقم الرحلة: #${trip.id}
''';

    // 📤 شارك الصورة + النص
    await Share.shareXFiles([XFile(imageFile.path)], text: message);
  } catch (e) {
    logger.e('❌ خطأ في مشاركة لقطة الرحلة: $e');
    Get.snackbar(
      'خطأ',
      'حدث خطأ أثناء مشاركة الرحلة',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

  static String getProvinceInfo(UserModel? driver) {
    if (driver?.provinceCode != null) {
      return '${ProvinceHelper.getProvinceName(driver!.provinceCode!)} (${driver.provinceCode})';
    } else if (driver?.provinceName != null) {
      return driver!.provinceName!;
    }
    return 'غير محدد';
  }

  static void showNavigationOptions(TripModel trip) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'اختر تطبيق الملاحة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.map, color: Colors.blue, size: 32),
                title: const Text('خرائط جوجل'),
                subtitle: const Text('فتح المسار في خرائط جوجل'),
                onTap: () {
                  Get.back();
                  openGoogleMaps(trip);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.navigation, color: Colors.cyan, size: 32),
                title: const Text('Waze'),
                subtitle: const Text('فتح المسار في Waze'),
                onTap: () {
                  Get.back();
                  openWaze(trip);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> openGoogleMaps(TripModel trip) async {
    final driverLat =
        trip.driver?.currentLatitude ?? trip.pickupLocation.latLng.latitude;
    final driverLng =
        trip.driver?.currentLongitude ?? trip.pickupLocation.latLng.longitude;

    final url =
        'https://www.google.com/maps/dir/?api=1&origin=$driverLat,$driverLng&destination=${trip.destinationLocation.latLng.latitude},${trip.destinationLocation.latLng.longitude}&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('خطأ', 'تعذر فتح خرائط جوجل',
          snackPosition: SnackPosition.TOP);
    }
  }

  static Future<void> openWaze(TripModel trip) async {
    final destLat = trip.destinationLocation.latLng.latitude;
    final destLng = trip.destinationLocation.latLng.longitude;

    final url = 'https://waze.com/ul?ll=$destLat,$destLng&navigate=yes';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('خطأ', 'تعذر فتح Waze', snackPosition: SnackPosition.TOP);
    }
  }

  final mapController = Get.find<MyMapController>();
  late final tripController = Get.find<TripController>();
  final authController = Get.find<AuthController>();
  final MapController flutterMapController = MapController();

  Widget buildTripStatus(TripModel trip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            TripTrackingSharedWidgets.getStatusIcon(trip.status),
            color: Colors.blue.shade700,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   TripTrackingSharedWidgets.getStatusText(trip.status),
                //   style: TextStyle(
                //     fontWeight: FontWeight.bold,
                //     fontSize: 16,
                //     color: Colors.blue.shade900,
                //   ),
                // ),
                const SizedBox(height: 4),
                Text(
                  TripTrackingSharedWidgets.getStatusDescription(trip.status),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCancellationButton(TripModel trip, {bool isDriver = false}) {
    final canCancel = trip.status == TripStatus.pending ||
        trip.status == TripStatus.accepted ||
        trip.status == TripStatus.driverArrived;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TripTrackingSharedWidgets.buildSmallActionButton(
          icon: canCancel ? Icons.cancel_outlined : Icons.help_outline,
          label: canCancel ? 'إلغاء الرحلة' : 'طلب مساعدة',
          color: canCancel
              ? const Color.fromARGB(255, 185, 15, 3)
              : const Color.fromARGB(255, 2, 99, 179),
          onPressed: () {
            if (canCancel) {
              if (isDriver) {
                showDriverCancelReasons();
              } else {
                showRiderCancelReasons();
              }
            } else {
              Get.snackbar(
                'المساعدة',
                'يمكنك التواصل مع خدمة العملاء للمساعدة',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            }
          },
        ),

        
      ],
    );
  }


 
  void showDriverCancelReasons() {
    final reasons = [
      'الراكب لا يرد على الهاتف',
      'الموقع بعيد جداً',
      'ظرف طارئ',
      'الراكب طلب الإلغاء',
      'معلومات الراكب غير صحيحة',
      'عطل في السيارة',
      'أسباب أخرى',
    ];

    Get.bottomSheet(
      SafeArea(
        child: Container(
                constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(Get.context!).height * 0.5,
        ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text('سبب الإلغاء',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: reasons.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.cancel, color: Colors.red),
                      title: Text(reasons[index]),
                      onTap: () async {
                        Get.back(); // ✅ إغلاق الـ BottomSheet أولاً
                        await tripController.cancelTrip(reason: reasons[index], byDriver: true);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void showRiderCancelReasons() {
    final reasons = [
      'السائق بعيد',
      'غيرت رأيي',
      'السائق لا يتحرك نحو نقطة الانطلاق',
      'السائق طلب إلغاء الرحلة',
      'السائق لا يجيب أو غير متوفر',
      'السائق طلب دفعاً نقدياً',
      'أريد تعديل تفاصيل الرحلة',
      'سأستخدم خدمة أخرى',
      'الكابتن لا يملك صورة',
      'لم يظهر رقم السيارة في التطبيق',
      'معلومات السائق غير مطابقة',
      'أسباب أخرى',
    ];

    Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text('سبب الإلغاء',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: reasons.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.cancel, color: Colors.red),
                      title: Text(reasons[index]),
                      onTap: () async {
                        Get.back(); // ✅ إغلاق الـ BottomSheet أولاً
                        await tripController.cancelTrip(reason: reasons[index]);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void showEnhancedRatingDialog(TripModel trip) {
    double rating = 5.0;
    final commentController = TextEditingController();
    List<String> selectedReasons = [];

    final Map<int, List<String>> ratingReasons = {
      5: ['سلوك جيد', 'الالتزام بالمواعيد', 'نظيفة', 'حافظ على السيارة نظيفة'],
      4: ['جيد', 'مقبول', 'وصلنا بأمان'],
      3: ['متوسط', 'القيادة سريعة', 'تأخر قليلاً'],
      2: ['غير مهذب', 'قيادة خطرة', 'طريق خاطئ', 'سيارة غير نظيفة'],
      1: ['سيء جداً', 'قيادة متهورة', 'غير محترم', 'رفض تشغيل العداد'],
    };

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final currentReasons = ratingReasons[rating.toInt()] ?? [];

          return AlertDialog(
            title: const Text('قيّم رحلتك'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('كيف كانت تجربتك؟',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = (i + 1).toDouble();
                            selectedReasons.clear();
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    getRatingText(rating),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: getRatingColor(rating),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (currentReasons.isNotEmpty) ...[
                    const Text('نقاط جيدة:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentReasons.map((reason) {
                        final isSelected = selectedReasons.contains(reason);
                        return FilterChip(
                          label: Text(reason),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedReasons.add(reason);
                              } else {
                                selectedReasons.remove(reason);
                              }
                            });
                          },
                          selectedColor: Colors.blue.shade100,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'تعليق (اختياري)',
                      border: OutlineInputBorder(),
                      hintText: 'أخبرنا المزيد عن تجربتك...',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Get.offNamed(AppRoutes.RIDER_HOME);
                },
                child: const Text('تخطي'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  String finalComment = commentController.text.trim();
                  if (selectedReasons.isNotEmpty) {
                    finalComment =
                        '${selectedReasons.join(', ')}${finalComment.isNotEmpty ? '\n$finalComment' : ''}';
                  }

                  await tripController.rateTrip(
                    trip.id,
                    rating,
                    finalComment.isEmpty ? null : finalComment,
                  );

                  Get.offNamed(AppRoutes.RIDER_HOME);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text('إرسال التقييم'),
              ),
            ],
          );
        },
      ),
    );
  }

  String getRatingText(double rating) {
    if (rating >= 5) return 'جيد جداً';
    if (rating >= 4) return 'جيد';
    if (rating >= 3) return 'مقبول';
    if (rating >= 2) return 'سيء';
    return 'سيء جداً';
  }

  Color getRatingColor(double rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }

  /// ✅ أيقونات للخدمات المختلفة - يعرض نوع الخدمة في كارد الطلبات
  IconData getServiceIcon(RiderType? type) {
    if (type == null) return Icons.local_taxi; // ✅ default إذا null
    switch (type) {
      case RiderType.regularTaxi:
        return Icons.local_taxi;
      case RiderType.delivery:
        return Icons.restaurant_menu;
      case RiderType.lineService:
        return Icons.route;
      case RiderType.external:
        return Icons.link;
    }
  }

  /// ✅ أسماء الخدمات المختلفة - يعرض نوع الخدمة في كارد الطلبات
  String getServiceName(RiderType type) {
    switch (type) {
      case RiderType.regularTaxi:
        return 'طلب تاكسي'; // 🚕
      case RiderType.delivery:
        return 'طلبات توصيل'; // 🍔
      case RiderType.lineService:
        return 'تأجير خطوط'; // 🚌
      case RiderType.external:
        return 'خدمة خارجية'; // 🌐
    }
  }
}
