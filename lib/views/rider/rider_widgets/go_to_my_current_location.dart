import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/my_map_controller.dart';

class GoToMyLocationButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoToMyLocationButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final mapController = Get.find<MyMapController>();
    
    return Positioned(
      bottom: MediaQuery.sizeOf(context).height / 3 + 100,
      left: 10,
      child: Obx(() {
        final currentLoc = mapController.currentLocation.value;
        
        return FloatingActionButton.small(
          heroTag: "location_fab",
          backgroundColor: Colors.white,
          onPressed: () {
            // ✅ استخدام الموقع الحالي من mapController مباشرة
            if (currentLoc != null) {
              mapController.mapController.move(currentLoc, 16.0);
            }
            
            // ✅ تنفيذ onPressed الإضافي إذا كان موجود
            if (onPressed != null) {
              onPressed!();
            }
          },
          child: Icon(
            Icons.my_location, 
            color: currentLoc != null ? Colors.blue.shade700 : Colors.grey,
          ),
        );
      }),
    );
  }
}
