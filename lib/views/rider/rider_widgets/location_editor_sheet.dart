import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/my_map_controller.dart';

class LocationEditorBottomSheet extends StatelessWidget {
  final VoidCallback? onUpdate;

  const LocationEditorBottomSheet({super.key, this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final mapController = Get.find<MyMapController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text('تعديل المسار',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildField(Icons.trip_origin, Colors.green, 'الانطلاق',
              mapController.currentAddress.value, () {
            Get.back();
            mapController.startLocationSelection('pickup');
          }),
          const SizedBox(height: 12),
          _buildField(Icons.location_on, Colors.red, 'الوصول',
              mapController.selectedAddress.value, () {
            Get.back();
            mapController.startLocationSelection('destination');
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                onUpdate?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('تأكيد', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(IconData icon, Color color, String label, String value,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: () async {
        final mapController = Get.find<MyMapController>();

        Get.back();

        await Future.delayed(const Duration(milliseconds: 800));

        if (!Get.isRegistered<MyMapController>()) return;

        mapController.isMapMoving.value = false;
        mapController.isLoading.value = false;
        mapController.showConfirmButton.value = false;
        mapController.currentStep.value = 'none';

        await Future.delayed(const Duration(milliseconds: 400));

        if (Get.isRegistered<MyMapController>()) {
          onTap();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text(value.isEmpty ? 'اضغط للاختيار' : value,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.edit, size: 18, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}
