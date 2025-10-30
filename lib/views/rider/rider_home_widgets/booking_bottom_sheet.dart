import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/views/rider/rider_home_widgets/additional_stops_display.dart';
import 'package:transport_app/views/rider/rider_home_widgets/book_trip_button.dart';
import 'package:transport_app/views/rider/rider_home_widgets/collapsible_trip_options.dart';
import 'package:transport_app/views/rider/rider_home_widgets/enhanced_header_section.dart';
import 'package:transport_app/views/rider/rider_home_widgets/location_input_section.dart';

class BookingBottomSheet extends StatelessWidget {
  final MyMapController mapController;
  final AuthController authController;
  final TripController tripController;
  final RiderType? riderType;
  final RxBool isPlusTrip;
  final RxBool isRoundTrip;
  final RxInt waitingTime;
  final RxDouble totalFare;
  final RxString paymentMethod;
  final RxString appliedDiscountCode;
  final VoidCallback onHideBottomSheet;
  final VoidCallback onShowBottomSheet;
  final VoidCallback onCalculateFare;
  final VoidCallback onAnimatePriceChange;
  final Function({bool isRush}) onRequestTrip;
  final Function(String message) onShowError;
  final Animation<double> priceAnimation;

  const BookingBottomSheet({
    super.key,
    required this.mapController,
    required this.authController,
    required this.tripController,
    this.riderType,
    required this.isPlusTrip,
    required this.isRoundTrip,
    required this.waitingTime,
    required this.totalFare,
    required this.paymentMethod,
    required this.appliedDiscountCode,
    required this.onHideBottomSheet,
    required this.onShowBottomSheet,
    required this.onCalculateFare,
    required this.onAnimatePriceChange,
    required this.onRequestTrip,
    required this.onShowError,
    required this.priceAnimation,
    required DraggableScrollableController bottomSheetController,
    required void Function() onToggleBottomSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 المؤشر (ممكن تحذفه لو مش محتاج شكل السحب)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 🔹 رأس الصفحة (العنوان + السعر)
            EnhancedHeaderSection(
              mapController: mapController,
              riderType: riderType,
              isPlusTrip: isPlusTrip,
              totalFare: totalFare,
              priceAnimation: priceAnimation,
            ),

            const SizedBox(height: 1),

            // 🔹 إدخال المواقع
            LocationInputSection(
              mapController: mapController,
              onHideBottomSheet: onHideBottomSheet,
            ),

            const SizedBox(height: 1),

            // 🔹 نقاط التوقف الإضافية
            Obx(() {
              if (mapController.additionalStops.isNotEmpty) {
                return AdditionalStopsDisplaySection(
                    mapController: mapController);
              }
              return const SizedBox.shrink();
            }),

            const SizedBox(height: 2),

            // 🔹 قسم قابل للفتح والإغلاق
            CollapsibleTripOptions(
              mapController: mapController,
              isPlusTrip: isPlusTrip,
              isRoundTrip: isRoundTrip,
              waitingTime: waitingTime,
              paymentMethod: paymentMethod,
              onCalculateFare: onCalculateFare,
              onHideBottomSheet: onHideBottomSheet,
              onShowBottomSheet: onShowBottomSheet,
              priceAnimation: priceAnimation,
              totalFare: totalFare,
            ),

            const SizedBox(height: 10),

            // 🔹 زر الحجز
            BookTripButton(
              mapController: mapController,
              paymentMethod: paymentMethod,
              totalFare: totalFare,
              authController: authController,
              onRequestTrip: onRequestTrip,
              onShowError: onShowError,
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
 