import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/trip_controller.dart';

class TripTrackingView extends StatelessWidget {
  const TripTrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    final tripController = Get.find<TripController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع الرحلة'),
        centerTitle: true,
      ),
      body: Obx(() {
        final trip = tripController.activeTrip.value;
        if (trip == null) {
          return const Center(child: Text('لا توجد رحلة نشطة'));
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الحالة: ${trip.statusText}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('التكلفة: ${trip.fare.toStringAsFixed(2)} ج.م'),
                ],
              ),
              const SizedBox(height: 12),
              Text('المسافة: ${trip.distance.toStringAsFixed(1)} كم'),
              Text('المدة: ${trip.estimatedDuration} دقيقة'),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('رجوع'),
              ),
            ],
          ),
        );
      }),
    );
  }
}
