import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/views/rider/rider_widgets/pin_color.dart';
import 'package:transport_app/views/rider/rider_widgets/pin_painter.dart';

class CenterLocationPin extends StatelessWidget {
  final MyMapController mapController;

  const CenterLocationPin({
    super.key,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (mapController.currentStep.value == 'none') {
        return const SizedBox.shrink();
      }

      const double pinSize = 30;
      const bool showLabel = true;

      return Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Center(
            child: SizedBox(
              width: 70, // **زدنا العرض**
              height: 70, // **زدنا الارتفاع**
              child: EnhancedPinWidget(
                color:
                    PinColors.getColorForStep(mapController.currentStep.value),
                label: _getDisplayLabel(),
                showLabel: showLabel,
                size: pinSize,
                // zoomLevel: mapController.mapZoom.value,
                // fixedSizeOnMap: true,
                // baseZoomLevel: 13.0,
                number: _getPinNumber(),
              ),
            ),
          ),
        ),
      );
    });
  }

  String _getDisplayLabel() {
    switch (mapController.currentStep.value) {
      case 'pickup':
        return 'انطلاق';
      case 'destination':
        return 'وصول';
      case 'additional_stop':
        return 'وصول ${mapController.additionalStops.length + 3}';
      default:
        return '';
    }
  }

  String _getPinNumber() {
    switch (mapController.currentStep.value) {
      case 'pickup':
        return '1';
      case 'destination':
        return '2';
      case 'additional_stop':
        return '${mapController.additionalStops.length + 3}';
      default:
        return '';
    }
  }
}
