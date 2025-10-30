// حل مشكلة زرار التثبيت - بدون تعليق أو اختفاء

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/views/rider/rider_widgets/pin_color.dart';

class LocationConfirmationSection extends StatelessWidget {
  final Function() onConfirm;
  final MyMapController mapController;

  const LocationConfirmationSection({
    super.key,
    required this.onConfirm,
    required this.mapController,
  });

  IconData _getStepIcon(String step) {
    switch (step) {
      case 'pickup':
        return Icons.trip_origin;
      case 'destination':
        return Icons.location_on;
      case 'additional_stop':
        return Icons.add_location_alt;
      default:
        return Icons.location_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (mapController.currentStep.value == 'none') {
        return const SizedBox.shrink();
      }

      // حساب الـ enabled مرة واحدة فقط
      final bool isButtonEnabled = !mapController.isLoading.value;
      final String currentAddress = mapController.currentPinAddress.value;
      final bool hasAddress =
          currentAddress.isNotEmpty && currentAddress != 'جاري تحديد الموقع...';

      return Positioned(
        bottom: 10,
        left: 16,
        right: 16,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: PinColors.getColorForStep(
                              mapController.currentStep.value)
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStepIcon(mapController.currentStep.value),
                      color: PinColors.getColorForStep(
                          mapController.currentStep.value),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          PinColors.getLabelForStep(
                              mapController.currentStep.value),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasAddress ? currentAddress : 'جاري تحديد الموقع...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: hasAddress
                                ? Colors.black87
                                : Colors.orange.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isButtonEnabled ? onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isButtonEnabled
                      ? PinColors.getColorForStep(
                          mapController.currentStep.value)
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: mapController.isLoading.value
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Text(
                        'تثبيت ${PinColors.getLabelForStep(mapController.currentStep.value)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
