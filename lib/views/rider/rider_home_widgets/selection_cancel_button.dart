import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/my_map_controller.dart';

class SelectionCancelButton extends StatelessWidget {
  final MyMapController mapController;
  final VoidCallback onCancel;

  const SelectionCancelButton({
    super.key,
    required this.mapController,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = mapController.currentStep.value;
      if (step != 'additional_stop') {
        return const SizedBox.shrink();
      }
      return Positioned(
        top: 115,
        left: 20,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () {
              mapController.currentStep.value = 'none';
              mapController.showConfirmButton.value = false;
              onCancel(); // لإعادة إظهار الـ bottom sheet
            },
          ),
        ),
      );
    });
  }
}