import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/models/trip_model.dart';

import 'package:transport_app/views/rider/rider_widgets/pin_color.dart';

class LocationConfirmationPanel extends StatelessWidget {
  final RxString currentStep;
  final RxString centerAddress;
  final RxBool isLoading;
  final RxBool isMapMoving;
  final RxBool isFetchingAddress;
  final VoidCallback onConfirm;
  final RxList<AdditionalStop> additionalStops;

  const LocationConfirmationPanel({
    super.key,
    required this.currentStep,
    required this.centerAddress,
    required this.isLoading,
    required this.isMapMoving,
    required this.isFetchingAddress,
    required this.onConfirm,
    required this.additionalStops,
  });

  String _getPinType() =>
      currentStep.value == 'destination' ? 'destination' : 'additional_stop';

  String _getPinLabel() {
    if (currentStep.value == 'destination') return 'وجهة';
    if (currentStep.value == 'additional_stop') {
      return 'توقف ${additionalStops.length + 1}';
    }
    if (currentStep.value.startsWith('edit_stop_')) {
      return 'توقف ${int.parse(currentStep.value.split('_').last) + 1}';
    }
    return '';
  }

  IconData _getStepIcon() => currentStep.value == 'destination'
      ? Icons.location_on
      : Icons.add_location_alt;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (currentStep.value == 'none') return const SizedBox.shrink();

      return Positioned(
      //  bottom: 100, // Adjust position to not overlap with sheet handle
        left: 16,
        right: 16,
        top: 10,
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
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: PinColors.getColorForStep(_getPinType())
                            .withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: Icon(_getStepIcon(),
                        color: PinColors.getColorForStep(_getPinType()),
                        size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getPinLabel(),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 2),
                        Text(
                          centerAddress.value.isNotEmpty &&
                                  centerAddress.value != 'جاري تحديد الموقع...'
                              ? centerAddress.value
                              : 'جاري تحديد الموقع...',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: centerAddress.value.isNotEmpty &&
                                      centerAddress.value !=
                                          'جاري تحديد الموقع...'
                                  ? Colors.black87
                                  : Colors.orange.shade600),
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
                onPressed: !isLoading.value &&
                        !isMapMoving.value &&
                        !isFetchingAddress.value
                    ? onConfirm
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PinColors.getColorForStep(_getPinType()),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: isLoading.value
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Text('تثبيت ${_getPinLabel()}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    });
  }
}
