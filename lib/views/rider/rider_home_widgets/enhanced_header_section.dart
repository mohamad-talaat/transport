import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/views/shared/trip_tracking_shared_widgets.dart';

class EnhancedHeaderSection extends StatelessWidget {
  final MyMapController mapController;
  final RiderType? riderType;
  final RxBool isPlusTrip;
  final RxDouble totalFare;
  final Animation<double> priceAnimation; // إضافة الـ animation هنا

  const EnhancedHeaderSection({
    super.key,
    required this.mapController,
    required this.riderType,
    required this.isPlusTrip,
    required this.totalFare,
    required this.priceAnimation, // متطلب للـ constructor
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    TripTrackingSharedWidgets().getServiceIcon(riderType),
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    riderType != null
                        ? TripTrackingSharedWidgets().getServiceName(riderType!)
                        : 'طلب تاكسي',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Obx(() {
              if (!mapController.isPickupConfirmed.value ||
                  !mapController.isDestinationConfirmed.value) {
                return const SizedBox.shrink();
              }
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isPlusTrip.value
                      ? Colors.amber.shade100
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPlusTrip.value
                        ? Colors.amber.shade300
                        : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPlusTrip.value ? Icons.star : Icons.local_taxi,
                      color: isPlusTrip.value
                          ? Colors.amber.shade700
                          : Colors.blue.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPlusTrip.value ? 'بلس' : 'عادي',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isPlusTrip.value
                            ? Colors.amber.shade700
                            : Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Spacer(),
            Obx(() {
              if (!mapController.isPickupConfirmed.value ||
                  !mapController.isDestinationConfirmed.value) {
                return const SizedBox.shrink();
              }
              return ScaleTransition(
                scale: priceAnimation, // استخدام الـ animation هنا
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${totalFare.value.toStringAsFixed(0)} د.ع',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}