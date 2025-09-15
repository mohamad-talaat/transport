import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/controllers/map_controller.dart';
// import 'package:transport_app/controllers/map_controller_copy.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/location_service.dart';

class DriverTripTrackingView extends StatefulWidget {
  const DriverTripTrackingView({super.key});

  @override
  State<DriverTripTrackingView> createState() => _DriverTripTrackingViewState();
}

class _DriverTripTrackingViewState extends State<DriverTripTrackingView>
    with TickerProviderStateMixin {
  final DriverController driverController = Get.find();
  final MapControllerr mapController = Get.find();
  final LocationService locationService = LocationService.to;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMap();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  void _initializeMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final trip = driverController.currentTrip.value;
      if (trip != null && trip.routePolyline != null) {
        // Use existing MapControllerr API to draw the route polyline
        mapController.drawTripRoute(trip.routePolyline!);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final trip = driverController.currentTrip.value;
        if (trip == null) {
          return const Center(child: Text('لا توجد رحلة نشطة'));
        }

        return Stack(
          children: [
            // Map
            _buildMap(),

            // Top Info Bar
            _buildTopInfoBar(trip),

            // Bottom Action Panel
            _buildBottomActionPanel(trip),
          ],
        );
      }),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: mapController.mapController,
      options: MapOptions(
        initialCenter: const LatLng(30.0444, 31.2357), // Cairo
        initialZoom: 15,
        onMapReady: () {
          mapController.onMapReady();
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        // Route Polyline
        Obx(() {
          final trip = driverController.currentTrip.value;
          if (trip?.routePolyline != null) {
            return PolylineLayer(
              polylines: [
                Polyline<LatLng>(
                  points: trip!.routePolyline!,
                  strokeWidth: 4,
                  color: Colors.blue,
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        }),
        // Markers
        MarkerLayer(
          markers: _buildMarkers(),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    final trip = driverController.currentTrip.value;
    if (trip == null) return [];

    final markers = <Marker>[];

    // Pickup marker
    markers.add(
      Marker(
        point: trip.pickupLocation.latLng,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(
            Icons.my_location,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );

    // Destination marker
    markers.add(
      Marker(
        point: trip.destinationLocation.latLng,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(
            Icons.location_on,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );

    // Driver location marker
    final driverLocation = driverController.currentLocation.value;
    if (driverLocation != null) {
      markers.add(
        Marker(
          point: driverLocation,
          width: 50,
          height: 50,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildTopInfoBar(TripModel trip) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
                Icon(
                  _getStatusIcon(trip.status),
                  color: _getStatusColor(trip.status),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getStatusText(trip.status),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(trip.status),
                    ),
                  ),
                ),
                Text(
                  '${trip.fare.toStringAsFixed(2)} ج.م',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${trip.distance.toStringAsFixed(1)} كم • ${_formatTime(trip.estimatedDuration)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                if ((trip.paymentMethod ?? 'cash') == 'cash')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attach_money,
                            size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'الراكب سيدفع نقداً – يرجى استلام المبلغ',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // تفاصيل الرحلة مع جميع نقاط التوقف
            _buildTripDetails(trip),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetails(TripModel trip) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
              const SizedBox(width: 8),
              Text(
                'تفاصيل الرحلة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // نقطة الانطلاق
          _buildLocationRow(
            icon: Icons.trip_origin,
            iconColor: Colors.black,
            label: 'انطلاق',
            address: trip.pickupLocation.address,
          ),
          const SizedBox(height: 6),
          // نقطة الوصول الرئيسية
          _buildLocationRow(
            icon: Icons.location_on,
            iconColor: Colors.red,
            label: 'وصول 1',
            address: trip.destinationLocation.address,
          ),
          // نقاط الوصول الإضافية إذا وجدت
          if (trip.additionalStops.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...trip.additionalStops.asMap().entries.map((entry) {
              int index = entry.key;
              var stop = entry.value;
              return Column(
                children: [
                  _buildLocationRow(
                    icon: Icons.add_location_alt,
                    iconColor: Colors.orange,
                    label: 'وصول ${index + 2}',
                    address: stop['address'] ?? 'عنوان غير محدد',
                  ),
                  if (index < trip.additionalStops.length - 1)
                    const SizedBox(height: 6),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionPanel(TripModel trip) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trip details
            _buildTripDetails(trip),

            const SizedBox(height: 20),

            // Action buttons
            _buildActionButtons(trip),
          ],
        ),
      ),
    );
  }

  // Deprecated block kept earlier by project; safe to remove unused helpers
  Widget _buildOldTripDetails(TripModel trip) {
    return Column(
      children: [
        // Pickup
        _buildOldLocationRow(
          Icons.my_location,
          Colors.green,
          'موقع الراكب',
          trip.pickupLocation.address,
        ),

        const SizedBox(height: 12),

        // Destination
        _buildOldLocationRow(
          Icons.location_on,
          Colors.red,
          'الوجهة',
          trip.destinationLocation.address,
        ),
      ],
    );
  }

  Widget _buildOldLocationRow(
      IconData icon, Color color, String label, String address) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(TripModel trip) {
    switch (trip.status) {
      case TripStatus.accepted:
        return _buildArrivedButton();

      case TripStatus.driverArrived:
        return _buildStartTripButton();

      case TripStatus.inProgress:
        return _buildEndTripButton();

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildArrivedButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _markAsArrived(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'وصلت إلى الراكب',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStartTripButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _startTrip(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'بدء الرحلة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEndTripButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _endTrip(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'إنهاء الرحلة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _markAsArrived() async {
    try {
      await driverController.markAsArrived();
      Get.snackbar(
        'تم التحديث',
        'تم إعلام الراكب بأنك وصلت',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر تحديث الحالة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _startTrip() async {
    try {
      await driverController.startTrip();
      Get.snackbar(
        'تم بدء الرحلة',
        'جاري التوجه إلى الوجهة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر بدء الرحلة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _endTrip() async {
    try {
      await driverController.endTrip();
      Get.snackbar(
        'تم إنهاء الرحلة',
        'تم إضافة الرحلة إلى أرباحك',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAllNamed(AppRoutes.DRIVER_HOME);
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر إنهاء الرحلة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  IconData _getStatusIcon(TripStatus status) {
    switch (status) {
      case TripStatus.accepted:
        return Icons.directions_car;
      case TripStatus.driverArrived:
        return Icons.location_on;
      case TripStatus.inProgress:
        return Icons.timer;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.accepted:
        return Colors.blue;
      case TripStatus.driverArrived:
        return Colors.orange;
      case TripStatus.inProgress:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.accepted:
        return 'توجه إلى الراكب';
      case TripStatus.driverArrived:
        return 'وصلت إلى الراكب';
      case TripStatus.inProgress:
        return 'جاري التوجه إلى الوجهة';
      default:
        return 'غير معروف';
    }
  }

  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '$minutes دقيقة';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours ساعة ${remainingMinutes > 0 ? '$remainingMinutes دقيقة' : ''}';
    }
  }
}
