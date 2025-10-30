import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/views/rider/rider_home_widgets/add_destination_button_conditional.dart';
import 'package:transport_app/views/rider/rider_home_widgets/fare_display_section.dart';
import 'package:transport_app/views/rider/rider_home_widgets/payment_method_section.dart';
import 'package:transport_app/views/rider/rider_home_widgets/trip_class_section.dart';
import 'package:transport_app/views/rider/rider_home_widgets/trip_type_section.dart';
import 'package:transport_app/views/rider/rider_home_widgets/waiting_time_section.dart';

class CollapsibleTripOptions extends StatelessWidget {
  final MyMapController mapController;
  final RxBool isPlusTrip;
  final RxBool isRoundTrip;
  final RxInt waitingTime;
  final RxString paymentMethod;
  final VoidCallback onCalculateFare;
  final VoidCallback onHideBottomSheet;
  final VoidCallback
      onShowBottomSheet; // لإعادة إظهار الـ Bottom Sheet بعد إلغاء تحديد وجهة إضافية
  final RxDouble totalFare;
  final Animation<double> priceAnimation; // استلام الـ animation

  const CollapsibleTripOptions({
    super.key,
    required this.mapController,
    required this.isPlusTrip,
    required this.isRoundTrip,
    required this.waitingTime,
    required this.paymentMethod,
    required this.onCalculateFare,
    required this.onHideBottomSheet,
    required this.onShowBottomSheet,
    required this.totalFare,
    required this.priceAnimation, // إضافة الـ animation كمتطلب
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 2),
        leading: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.tune,
            color: Colors.orange.shade600,
            size: 25,
          ),
        ),
        title: const Text(
          'خيارات الرحلة',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: const Text(
          'اضغط لعرض المزيد من الخيارات',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        children: [
          AddDestinationButtonConditional(
            mapController: mapController,
            onHideBottomSheet: onHideBottomSheet,
            onShowBottomSheet: onShowBottomSheet,
          ),
          const SizedBox(height: 2),
          TripTypeSection(
            isRoundTrip: isRoundTrip,
            onCalculateFare: onCalculateFare,
          ),
          const SizedBox(height: 2),
          TripClassSection(
            isPlusTrip: isPlusTrip,
            onCalculateFare: onCalculateFare,
          ),
          const SizedBox(height: 2),
          PaymentMethodSection(
            paymentMethod: paymentMethod,
            onCalculateFare: onCalculateFare,
          ),
          const SizedBox(height: 2),
          WaitingTimeSection(
            waitingTime: waitingTime,
            onCalculateFare: onCalculateFare,
          ),
          const SizedBox(height: 5),
          FareDisplaySection(
            totalFare: totalFare,
            mapController: mapController,
            waitingTime: waitingTime,
            isRoundTrip: isRoundTrip,
            isPlusTrip: isPlusTrip,
            priceAnimation: priceAnimation,
          ),
        ],
      ),
    );
  }
}
