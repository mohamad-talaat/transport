import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/models/trip_model.dart';
 
import 'package:transport_app/views/rider/rider_widgets/pin_color.dart';
import 'package:transport_app/views/rider/rider_widgets/pin_painter.dart';

class MapCenterPin extends StatelessWidget {
  final RxString currentStep;
  final RxList<AdditionalStop> additionalStops;

  const MapCenterPin({
    super.key,
    required this.currentStep,
    required this.additionalStops,
  });

  String _getPinType() => currentStep.value == 'destination' ? 'destination' : 'additional_stop';

  String _getPinLabel() {
    if (currentStep.value == 'destination') return 'وجهة';
    if (currentStep.value == 'additional_stop') return 'توقف ${additionalStops.length + 1}';
    if (currentStep.value.startsWith('edit_stop_')) return 'توقف ${int.parse(currentStep.value.split('_').last) + 1}';
    return '';
  }

  String _getPinNumber() {
    int baseNumber = additionalStops.length + 2;
    if (currentStep.value.startsWith('edit_stop_')) {
      return '${int.parse(currentStep.value.split('_').last) + 2}';
    }
    return '$baseNumber';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (currentStep.value == 'none') return const SizedBox.shrink();
      return Center(
        child: SizedBox(
          width: 70,
          height: 70,
          child: IgnorePointer(
            child: EnhancedPinWidget(
              color: PinColors.getColorForStep(_getPinType()),
              label: _getPinLabel(),
              number: _getPinNumber(),
              showLabel: true,
              size: 30,
            ),
          ),
        ),
      );
    });
  }
}