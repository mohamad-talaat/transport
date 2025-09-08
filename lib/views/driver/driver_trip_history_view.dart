import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/models/trip_model.dart';

class DriverTripHistoryView extends StatefulWidget {
  const DriverTripHistoryView({super.key});

  @override
  State<DriverTripHistoryView> createState() => _DriverTripHistoryViewState();
}

class _DriverTripHistoryViewState extends State<DriverTripHistoryView> {
  final DriverController driverController = Get.put(DriverController());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await driverController.loadTripHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('تاريخ رحلات السائق'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Obx(() {
          if (driverController.isLoadingHistory.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final trips = driverController.tripHistory;
          if (trips.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('لا توجد رحلات سابقة')),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _TripHistoryTile(trip: trips[index]),
          );
        }),
      ),
    );
  }
}

class _TripHistoryTile extends StatelessWidget {
  final TripModel trip;
  const _TripHistoryTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_taxi, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Text(
                _statusLabel(trip.status),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text('${trip.fare.toStringAsFixed(2)} ج.م',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.my_location, size: 16, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  trip.pickupLocation.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  trip.destinationLocation.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.route, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text('${trip.distance.toStringAsFixed(1)} كم'),
              const SizedBox(width: 12),
              const Icon(Icons.timer, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text('${trip.estimatedDuration} دقيقة'),
            ],
          ),
          if (trip.completedAt != null || trip.createdAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(_formatDate(trip.completedAt ?? trip.createdAt)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _statusLabel(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return 'قيد الطلب';
      case TripStatus.accepted:
        return 'تم القبول';
      case TripStatus.driverArrived:
        return 'السائق وصل';
      case TripStatus.inProgress:
        return 'قيد التنفيذ';
      case TripStatus.completed:
        return 'مكتملة';
      case TripStatus.cancelled:
        return 'ملغاة';
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
