import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/services/location_service.dart';

class DriverTripRequestDialog extends StatefulWidget {
  final TripModel trip;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const DriverTripRequestDialog({
    super.key,
    required this.trip,
    this.onAccept,
    this.onDecline,
  });

  @override
  State<DriverTripRequestDialog> createState() =>
      _DriverTripRequestDialogState();
}

class _DriverTripRequestDialogState extends State<DriverTripRequestDialog>
    with TickerProviderStateMixin {
  final DriverController driverController = Get.find();
  final AuthController authController = Get.find();
  final LocationService locationService = LocationService.to;

  late AnimationController _pulseController;
  late AnimationController _countdownController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _countdownAnimation;

  int _remainingSeconds = 30;
  Timer? _countdownTimer;
  double? _distanceToPickup;
  int? _estimatedTimeToPickup;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCountdown();
    _calculateDistanceToPickup();
  }

  void _initializeAnimations() {
    // تحريك نبضي للدائرة
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // تحريك عداد التنازلي
    _countdownController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _countdownAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _countdownController,
      curve: Curves.linear,
    ));

    _pulseController.repeat(reverse: true);
    _countdownController.forward();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _autoDecline();
      }
    });
  }

  void _autoDecline() {
    if (mounted) {
      widget.onDecline?.call();
      Get.back();
    }
  }

  Future<void> _calculateDistanceToPickup() async {
    try {
      final currentLocation = await locationService.getCurrentLocation();
      if (currentLocation != null) {
        final distance = locationService.calculateDistance(
          currentLocation,
          widget.trip.pickupLocation.latLng,
        );
        final time = locationService.estimateDuration(distance);

        setState(() {
          _distanceToPickup = distance;
          _estimatedTimeToPickup = time;
        });
      }
    } catch (e) {
      logger.w('خطأ في حساب المسافة: $e');
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

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with countdown
            _buildHeader(),

            const SizedBox(height: 20),

            // Trip details
            _buildTripDetails(),

            const SizedBox(height: 20),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Countdown circle
        AnimatedBuilder(
          animation: _countdownAnimation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: _countdownAnimation.value,
                    strokeWidth: 4,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _remainingSeconds > 10 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
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
                          size: 30,
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 15),

        // Title and countdown text
        const Text(
          'طلب رحلة جديد',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'الوقت المتبقي: $_remainingSeconds ثانية',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _remainingSeconds > 10 ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Pickup location
          _buildLocationRow(
            Icons.my_location,
            Colors.green,
            'موقع الراكب',
            widget.trip.pickupLocation.address,
          ),

          const SizedBox(height: 16),

          // Destination
          _buildLocationRow(
            Icons.location_on,
            Colors.red,
            'الوجهة',
            widget.trip.destinationLocation.address,
          ),

          const SizedBox(height: 20),

          // Trip info
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  Icons.attach_money,
                  'الأجرة',
                  '${widget.trip.fare.toStringAsFixed(2)} ج.م',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  Icons.straighten,
                  'المسافة',
                  '${widget.trip.distance.toStringAsFixed(1)} كم',
                  Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  Icons.access_time,
                  'وقت الرحلة',
                  _formatTime(widget.trip.estimatedDuration),
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  Icons.directions_car,
                  'المسافة لك',
                  _distanceToPickup != null
                      ? '${_distanceToPickup!.toStringAsFixed(1)} كم'
                      : '...',
                  Colors.purple,
                ),
              ),
            ],
          ),

          if (_estimatedTimeToPickup != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'الوقت المتوقع للوصول: ${_formatTime(_estimatedTimeToPickup!)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationRow(
      IconData icon, Color color, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 4),
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

  Widget _buildInfoCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _countdownTimer?.cancel();
              widget.onDecline?.call();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'رفض',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _countdownTimer?.cancel();
              widget.onAccept?.call();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'قبول',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
