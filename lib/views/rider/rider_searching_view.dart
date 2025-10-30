import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/routes/app_routes.dart';

import '../../main.dart';

class RiderSearchingView extends StatefulWidget {
  final LocationPoint pickup;
  final LocationPoint destination;
  final double estimatedFare;
  final int estimatedDuration;

  const RiderSearchingView({
    super.key,
    required this.pickup,
    required this.destination,
    required this.estimatedFare,
    required this.estimatedDuration,
  });

  @override
  State<RiderSearchingView> createState() => _RiderSearchingViewState();
}

class _RiderSearchingViewState extends State<RiderSearchingView>
    with TickerProviderStateMixin {
  final TripController tripController = Get.find();
  final AuthController authController = Get.find();

  final RxBool _rushApplied = false.obs;
  late final RxDouble _displayFare;

  final RxInt _countdownSeconds = 30.obs;
  Timer? _countdownTimer;
  final RxBool _isTimerRunning = true.obs;

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late AnimationController _urgentController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _urgentAnimation;

  @override
  void initState() {
    super.initState();
    _displayFare = widget.estimatedFare.obs;
    _initializeAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCountdownTimer();
      _listenToTripUpdates();
    });
  }

  void _listenToTripUpdates() {
    Worker? worker;

    worker = ever(tripController.activeTrip, (TripModel? trip) {
      if (!mounted) return;

      if (trip != null && trip.status != TripStatus.pending) {
        worker?.dispose();
        _stopCountdownTimer();
        _stopAllAnimations();

        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;

          switch (trip.status) {
            case TripStatus.accepted:
            case TripStatus.driverArrived:
            case TripStatus.inProgress:
              if (Get.currentRoute == AppRoutes.RIDER_SEARCHING) {
                _stopCountdownTimer();

                Get.offNamed(AppRoutes.RIDER_TRIP_TRACKING);

                Future.delayed(const Duration(milliseconds: 500), () {
                  if (!Get.isSnackbarOpen) {
                    Get.snackbar(
                      '✅ تم قبول الرحلة',
                      'السائق ${trip.driver?.name ?? "في الطريق"} إليك',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                    );
                  }
                });
              }
              break;

            case TripStatus.cancelled:
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                
                if (Get.currentRoute == AppRoutes.RIDER_SEARCHING) {
                  _stopCountdownTimer();
                  _stopAllAnimations();
                  
                  Get.offAllNamed(AppRoutes.RIDER_HOME);
                  
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (!Get.isSnackbarOpen) {
                      Get.snackbar(
                        'تم الإلغاء',
                        trip.notes ?? 'تم إلغاء الرحلة',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                      );
                    }
                  });
                }
              });
              break;

            default:
              break;
          }
        });
      }
    });
  }

  void _autoTimeoutCancelTrip() async {
    if (!mounted) return;

    final trip = tripController.activeTrip.value;

    if (trip == null || trip.status != TripStatus.pending) {
      logger.i('⚠️ الرحلة موجودة بالفعل أو ليست pending، لا نلغي');
      return;
    }

    try {
      logger.w('⏰ انتهى وقت البحث');

      _stopCountdownTimer();
      _stopAllAnimations();

      await tripController.cancelTrip(reason: ' ⏰ انتهى وقت البحث');
    } catch (e) {
      logger.w('خطأ في timeout: $e');
    }
  }

  void _applyRushMode() async {
    _displayFare.value = widget.estimatedFare * 1.2;
    _rushApplied.value = true;

    // ✅ تطبيق الوضع المستعجل للرحلة الحالية فقط
    await tripController.applyUrgentModeToCurrentTrip();

    _urgentController.repeat(reverse: true);
  }

  void _startCountdownTimer() {
    _countdownSeconds.value = 30;
    _isTimerRunning.value = true;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds.value > 0) {
        _countdownSeconds.value--;
      } else {
        timer.cancel();
        _isTimerRunning.value = false;
        final trip = tripController.activeTrip.value;
        if (trip == null || trip.status == TripStatus.pending) {
          _autoTimeoutCancelTrip();
        }
      }
    });
  }

  void _stopCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _isTimerRunning.value = false;
  }

  void _stopAllAnimations() {
    try {
      _pulseController.stop();
      _rotateController.stop();
      _urgentController.stop();
    } catch (e) {
      logger.w('خطأ في إيقاف الأنيميشنز: $e');
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _urgentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _urgentAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _urgentController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
    _fadeController.forward();
  }

  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '$minutes د';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours س ${remainingMinutes > 0 ? '$remainingMinutes د' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height;
    
    // تحديد أحجام ديناميكية حسب ارتفاع الشاشة
    final headerH = h * 0.08;
    final animSize = h * 0.15;
   
    final cardPad = h * 0.02;
    final btnH = h * 0.065;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            SizedBox(
              height: headerH,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _cancelSearch(),
                    icon: const Icon(Icons.arrow_back, size: 22),
                    padding: EdgeInsets.zero,
                  ),
                  const Expanded(
                    child: Text(
                      'البحث عن سائق',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Animation
                    _buildCompactAnimation(animSize),
                    
                    // Trip Details
                    _buildCompactTripDetails(cardPad),
                    _buildTripSummary(), 

                    // Search Status
                    _buildCompactSearchStatus(),
                    
                    // Action Buttons
                    _buildCompactActionButtons(btnH),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactAnimation(double size) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _rotateController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value * 0.9,
          child: Transform.rotate(
            angle: _rotateAnimation.value * 2 * 3.14159,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.25),
                    Colors.blue.withOpacity(0.08),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: size * 0.65,
                  height: size * 0.65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: size * 0.35,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
Widget _buildTripSummary() {
  return FadeTransition(
    opacity: _fadeAnimation,
    child: Column(
      children: [
        const Text(
          'ملخص الرحلة',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
        const SizedBox(height: 4),
        Text(
          'من ${widget.pickup.address.split(',').first} إلى ${widget.destination.address.split(',').first}',
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget _buildCompactTripDetails(double pad) {
  final trip = tripController.activeTrip.value;

  return FadeTransition(
    opacity: _fadeAnimation,
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: pad * 1.2, vertical: pad * 1.3),
      margin: EdgeInsets.symmetric(vertical: pad * 0.5),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationRow(Colors.green, widget.pickup.address),
          const SizedBox(height: 10),
          _buildLocationRow(Colors.red, widget.destination.address),

          const SizedBox(height: 12),
          Divider(color: Colors.grey[300], height: 1),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactInfo(Icons.access_time, _formatTime(widget.estimatedDuration)),
              Obx(() => _buildCompactInfo(Icons.attach_money, '${_displayFare.value.toStringAsFixed(0)} د.ع')),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactInfo(Icons.route, trip?.distance != null
                  ? '${trip!.distance.toStringAsFixed(1)} كم'
                  : 'المسافة غير متوفرة'),
              _buildCompactInfo(Icons.more_horiz, (trip?.additionalStops.isNotEmpty ?? false)
                  ? '${trip!.additionalStops.length} نقاط إضافية'
                  : 'لا توجد نقاط إضافية'),
            ],
          ),
        ],
      ),
    ),
  );
}


  Widget _buildLocationRow(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInfo(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blue, size: 16),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCompactSearchStatus() {
    return Obx(() {
      final mins = (_countdownSeconds.value ~/ 60).toString().padLeft(2, '0');
      final secs = (_countdownSeconds.value % 60).toString().padLeft(2, '0');

      return FadeTransition(
        opacity: _fadeAnimation,
        child: Obx(() {
          if (tripController.isUrgentMode.value) {
            return AnimatedBuilder(
              animation: _urgentAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _urgentAnimation.value * 0.95,
                  child: Column(
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on, color: Colors.red, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'وضع مستعجل',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'جاري البحث بسرعة...',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return Column(
              children: [
                const Text(
                  'جارٍ البحث عن سائق...',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time,
                      color: _countdownSeconds.value <= 5 ? Colors.red : Colors.grey[600],
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$mins:$secs',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _countdownSeconds.value <= 5 ? Colors.red : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: LinearProgressIndicator(
                    value: _countdownSeconds.value / 30.0,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _countdownSeconds.value <= 5 ? Colors.red : Colors.blue,
                    ),
                    minHeight: 3,
                  ),
                ),
              ],
            );
          }
        }),
      );
    });
  }

  Widget _buildCompactActionButtons(double btnH) {
    return Column(
      children: [
        Obx(() => _rushApplied.value
            ? const SizedBox.shrink()
            : SizedBox(
                width: double.infinity,
                height: btnH,
                child: ElevatedButton.icon(
                  onPressed: () => _showRushConfirmationDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: const Text('أنا مستعجل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              )),
        SizedBox(height: btnH * 0.2),
        SizedBox(
          width: double.infinity,
          height: btnH,
          child: ElevatedButton.icon(
            onPressed: () => _cancelSearch(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.grey.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('إلغاء البحث', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  void _showRushConfirmationDialog() {
    final rushFare = widget.estimatedFare * 1.2;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Icon(Icons.flash_on, color: Colors.red.shade400, size: 22),
            const SizedBox(width: 6),
            const Text('رحلة مستعجلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سيتم إنشاء طلب مستعجل بزيادة 20% في السعر',
              style: TextStyle(fontSize: 13, height: 1.3),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('السعر الجديد:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                    '${rushFare.toStringAsFixed(0)} د.ع',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              _applyRushMode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.flash_on, color: Colors.white, size: 14),
            label: const Text('تأكيد', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _cancelSearch() async {
    if (!mounted) return;

    _stopCountdownTimer();
    _stopAllAnimations();

    if (Get.isSnackbarOpen == true) {
      try {
        Get.closeCurrentSnackbar();
      } catch (_) {}
    }

    await tripController.cancelTrip(reason: 'الراكب ألغى البحث عن سائق');
  }

  @override
  void deactivate() {
    _stopCountdownTimer();
    _stopAllAnimations();
    super.deactivate();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    _urgentController.dispose();
    super.dispose();
  }
}