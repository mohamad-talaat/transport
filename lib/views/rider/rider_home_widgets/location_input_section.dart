import 'package:flutter/material.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/views/rider/rider_home_widgets/location_input_field.dart';

class LocationInputSection extends StatelessWidget {
  final MyMapController mapController;
  final VoidCallback onHideBottomSheet;

  const LocationInputSection({
    super.key,
    required this.mapController,
    required this.onHideBottomSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LocationInputField(
          icon: Icons.trip_origin,
          iconColor: const Color.fromARGB(255, 14, 17, 14),
          label: 'انطلاق',
          value: mapController.isPickupConfirmed.value
              ? (mapController.currentAddress.value.isNotEmpty
                  ? mapController.currentAddress.value
                  : 'الموقع الحالي')
              : 'اختر نقطة الانطلاق',
          isSet: mapController.isPickupConfirmed.value,
          onTap: () {
            mapController.startLocationSelection('pickup');
            onHideBottomSheet();
          },
          onRemove: mapController.isPickupConfirmed.value
              ? () => mapController.removePickupLocation()
              : null,
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 0),
          child: Column(
            children: [
              Container(width: 220, height: 2, color: Colors.grey.shade300),
            ],
          ),
        ),
        LocationInputField(
          icon: Icons.location_on,
          iconColor: const Color(0xFFE53E3E),
          label: 'وصول',
          value: mapController.isDestinationConfirmed.value
              ? (mapController.selectedAddress.value.isNotEmpty
                  ? mapController.selectedAddress.value
                  : 'تم تحديد الوجهة')
              : 'اختر نقطة الوصول الرئيسية',
          isSet: mapController.isDestinationConfirmed.value,
          onTap: () {
            mapController.startLocationSelection('destination');
            onHideBottomSheet();
          },
          onRemove: mapController.isDestinationConfirmed.value
              ? () => mapController.removeDestinationLocation()
              : null,
        ),
      ],
    );
  }
}
