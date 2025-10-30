import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/my_map_controller.dart';

class AddDestinationButtonConditional extends StatelessWidget {
  final MyMapController mapController;
  final VoidCallback onHideBottomSheet;
  final VoidCallback onShowBottomSheet;

  const AddDestinationButtonConditional({
    super.key,
    required this.mapController,
    required this.onHideBottomSheet,
    required this.onShowBottomSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!mapController.isPickupConfirmed.value ||
          !mapController.isDestinationConfirmed.value) {
        return const SizedBox.shrink();
      }

      if (mapController.additionalStops.length <
          mapController.maxAdditionalStops.value) {
        return GestureDetector(
          onTap: () {
            mapController.startLocationSelection('additional_stop');
            onHideBottomSheet();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_location_alt,
                    color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'إضافة وصول ${mapController.additionalStops.length + 2}',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade600, size: 16),
              const SizedBox(width: 8),
              Text(
                'تم الوصول للحد الأقصى (${mapController.maxAdditionalStops.value} وجهات إضافية)',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }
    });
  }
}