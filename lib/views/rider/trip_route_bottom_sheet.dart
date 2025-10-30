import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:transport_app/models/trip_model.dart';

class TripRouteBottomSheet extends StatelessWidget {
  final TripModel trip;

  const TripRouteBottomSheet({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.route, color: Colors.blue.shade700, size: 28),
              const SizedBox(width: 12),
              const Text('مسار الرحلة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          _buildLocationCard(
            icon: Icons.my_location,
            iconColor: Colors.green,
            title: 'نقطة الاستلام',
            address: trip.pickupLocation.address,
            canEdit: false,
          ),
          const SizedBox(height: 12),
          if (trip.additionalStops.isNotEmpty)
            ...trip.additionalStops.map((stop) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildLocationCard(
                    icon: Icons.location_on,
                    iconColor: Colors.orange,
                    title: 'محطة إضافية',
                    address: stop.address ?? 'غير محدد',
                    canEdit: false,
                  ),
                )),
          _buildLocationCard(
            icon: Icons.location_on,
            iconColor: Colors.red,
            title: 'الوجهة',
            address: trip.destinationLocation.address,
            canEdit: true,
            onEdit: () => _changeDestination(context, trip),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip(Icons.straighten, 'المسافة',
                    '${trip.distance.toStringAsFixed(1)} كم', Colors.blue),
                _buildInfoChip(Icons.access_time, 'الوقت',
                    '${trip.estimatedDuration} د', Colors.orange),
                _buildInfoChip(Icons.attach_money, 'التكلفة',
                    '${trip.fare.toStringAsFixed(0)} د.ع', Colors.green),
              ],
            ),
          ),
          if (trip.destinationChanged) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تم تغيير الوجهة',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900)),
                        const SizedBox(height: 4),
                        Text(
                          trip.driverApproved == null
                              ? 'في انتظار موافقة السائق'
                              : trip.driverApproved!
                                  ? 'وافق السائق'
                                  : 'رفض السائق',
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange.shade800),
                        ),
                        if (trip.newFare != null)
                          Text(
                              'السعر الجديد: ${trip.newFare!.toStringAsFixed(0)} د.ع',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('إغلاق',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String address,
    required bool canEdit,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(address,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (canEdit)
            IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit, color: Colors.blue.shade600),
                tooltip: 'تعديل'),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _changeDestination(BuildContext context, TripModel trip) {
    Get.back();
    final mapController = Get.find<MyMapController>();
    final tripController = Get.find<TripController>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.edit_location, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            const Text('تغيير الوجهة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'هل تريد تغيير وجهة الرحلة؟ سيتم إشعار السائق فورًا وإعادة حساب التكلفة.',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange.shade400, size: 48),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              mapController.startLocationSelection('destination');

              ever(mapController.isDestinationConfirmed, (confirmed) async {
                if (confirmed && mapController.selectedLocation.value != null) {
                  final newDest = LocationPoint(
                    lat: mapController.selectedLocation.value!.latitude,
                    lng: mapController.selectedLocation.value!.longitude,
                    address: mapController.selectedAddress.value,
                  );
                  await tripController.updateTripDestination(
                      tripId: trip.id, newDestination: newDest);
                }
              });
            },
            icon: const Icon(Icons.map),
            label: const Text('اختيار من الخريطة'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade400,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
