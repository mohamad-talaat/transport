import 'package:flutter/material.dart';
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:transport_app/models/trip_model.dart';

class DestinationChangeApprovalDialog extends StatelessWidget {
  final TripModel trip;

  const DestinationChangeApprovalDialog({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final tripController = TripController.to;

    if (trip.driverApproved != null || !trip.destinationChanged) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.notification_important, color: Colors.orange.shade700, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'طلب تغيير الوجهة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1.5),
          
          const Text(
            'طلب الراكب تغيير وجهة الرحلة:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          // عرض التفاصيل الجديدة المعلقة
          if (trip.toMap().containsKey('pendingDestination'))
            _buildDetailRow(
              icon: Icons.location_on,
              label: 'الوجهة الجديدة:',
              value: (trip.toMap()['pendingDestination'] as Map<String, dynamic>)['address'] ?? 'غير محدد',
              color: Colors.blue,
            ),
          
          if (trip.toMap().containsKey('pendingFare'))
            _buildDetailRow(
              icon: Icons.attach_money,
              label: 'السعر الجديد:',
              value: '${(trip.toMap()['pendingFare'] as num).toStringAsFixed(0)} د.ع',
              color: Colors.green,
            ),
          
          if (trip.toMap().containsKey('pendingDistance'))
            _buildDetailRow(
              icon: Icons.straighten,
              label: 'المسافة الجديدة:',
              value: '${(trip.toMap()['pendingDistance'] as num).toStringAsFixed(1)} كم',
              color: Colors.purple,
            ),
          
          if (trip.toMap().containsKey('pendingWaitingTime'))
            _buildDetailRow(
              icon: Icons.timer,
              label: 'وقت الانتظار:',
              value: '${trip.toMap()['pendingWaitingTime']} دقيقة',
              color: Colors.orange,
            ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    tripController.driverApproveDestinationChange(trip.id, false);
                  },
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text('رفض'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    tripController.driverApproveDestinationChange(trip.id, true);
                  },
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('قبول'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
