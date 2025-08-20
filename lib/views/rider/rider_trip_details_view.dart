import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/models/trip_model.dart';

class RiderTripDetailsView extends StatelessWidget {
  const RiderTripDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final TripModel? trip =
        Get.arguments is TripModel ? Get.arguments as TripModel : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الرحلة'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: trip == null
            ? const Center(child: Text('لا توجد بيانات رحلة'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('رقم الرحلة: ${trip.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('المسافة: ${trip.distance.toStringAsFixed(1)} كم'),
                  Text('المدة: ${trip.estimatedDuration} دقيقة'),
                  Text('التكلفة: ${trip.fare.toStringAsFixed(2)} ج.م'),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      child: const Text('رجوع'),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
