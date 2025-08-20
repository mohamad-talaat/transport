import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/controllers/map_controller.dart';
import 'package:transport_app/models/trip_model.dart';
// import 'package:url_launcher/url_launcher.dart'; // سيتم تفعيله عند إضافة المكتبة

class DriverTripTrackingView extends StatelessWidget {
  DriverTripTrackingView({Key? key}) : super(key: key);

  final DriverController driverController = Get.find();
  final MapControllerr mapController = Get.put(MapControllerr());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final trip = driverController.currentTrip.value;
          if (trip == null) {
            return const Center(
              child: Text('لا توجد رحلة نشطة'),
            );
          }

          return Stack(
            children: [
              _buildMap(trip),
              _buildHeader(),
              _buildTripDetails(trip),
              _buildActionButtons(trip),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMap(TripModel trip) {
    return FlutterMap(
      mapController: mapController.mapController,
      options: MapOptions(
        initialCenter: trip.pickupLocation.latLng,
        initialZoom: 15.0,
        minZoom: 10.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.transport_app',
        ),
        MarkerLayer(
          markers: [
            // Pickup marker
            Marker(
              point: trip.pickupLocation.latLng,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            // Destination marker
            Marker(
              point: trip.destinationLocation.latLng,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        PolylineLayer(
          polylines: trip.routePolyline != null
              ? [
                  Polyline(
                    points: trip.routePolyline!,
                    color: Colors.blue,
                    strokeWidth: 4.0,
                  ),
                ]
              : [],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back),
            ),
            const Expanded(
              child: Text(
                'تتبع الرحلة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Obx(() {
              final trip = driverController.currentTrip.value;
              if (trip == null) return const SizedBox();
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(trip.status),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  trip.statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.accepted:
        return Colors.orange;
      case TripStatus.driverArrived:
        return Colors.blue;
      case TripStatus.inProgress:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTripDetails(TripModel trip) {
    return Positioned(
      bottom: 150,
      left: 15,
      right: 15,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الراكب',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'تقييم: ⭐ 4.8',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _makePhoneCall('01234567890'), // TODO: Get actual phone
                      icon: const Icon(Icons.phone, color: Colors.green),
                    ),
                    IconButton(
                      onPressed: () => _sendMessage('01234567890'), // TODO: Get actual phone
                      icon: const Icon(Icons.message, color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    trip.pickupLocation.address,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    trip.destinationLocation.address,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${trip.distance.toStringAsFixed(1)} كم',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'المسافة',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                ),
                Column(
                  children: [
                    Text(
                      '${trip.estimatedDuration} د',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'الوقت المتوقع',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                ),
                Column(
                  children: [
                    Text(
                      '${trip.fare.toStringAsFixed(2)} ج.م',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Text(
                      'الأجرة',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(TripModel trip) {
    return Positioned(
      bottom: 20,
      left: 15,
      right: 15,
      child: _getActionButtonsForStatus(trip.status),
    );
  }

  Widget _getActionButtonsForStatus(TripStatus status) {
    switch (status) {
      case TripStatus.accepted:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _openNavigation(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.navigation, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'التنقل إلى الراكب',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => driverController.notifyArrival(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Icon(Icons.location_on, color: Colors.white),
            ),
          ],
        );

      case TripStatus.driverArrived:
        return ElevatedButton(
          onPressed: () => driverController.startTrip(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'بدء الرحلة',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        );

      case TripStatus.inProgress:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _openNavigation(toDestination: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.navigation, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'التنقل إلى الوجهة',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _showCompleteDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Icon(Icons.check, color: Colors.white),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  void _openNavigation({bool toDestination = false}) async {
    final trip = driverController.currentTrip.value;
    if (trip == null) return;

    final destination = toDestination 
        ? trip.destinationLocation.latLng 
        : trip.pickupLocation.latLng;

    final url = 'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving';

    // TODO: تفعيل url_launcher
    /*
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Get.snackbar(
        'خطأ',
        'تعذر فتح تطبيق الخرائط',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    */
    
    Get.snackbar(
      'التنقل',
      'سيتم فتح خرائط جوجل: ${destination.latitude}, ${destination.longitude}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    // TODO: تفعيل url_launcher
    /*
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Get.snackbar(
        'خطأ',
        'تعذر إجراء المكالمة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    */
    
    Get.snackbar(
      'اتصال',
      'اتصال بالرقم: $phoneNumber',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _sendMessage(String phoneNumber) async {
    final url = 'sms:$phoneNumber';
    // TODO: تفعيل url_launcher
    /*
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Get.snackbar(
        'خطأ',
        'تعذر إرسال الرسالة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    */
    
    Get.snackbar(
      'رسالة',
      'إرسال رسالة إلى: $phoneNumber',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _showCompleteDialog() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('إنهاء الرحلة'),
          ],
        ),
        content: const Text('هل وصلت إلى الوجهة وتريد إنهاء الرحلة؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              driverController.completeTrip();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('نعم، إنهاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}