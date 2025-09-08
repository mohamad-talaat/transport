import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/models/trip_model.dart';

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

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // تشغيل الطلب بعد أول إطار لتجنب setState أثناء البناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSearching();
    });
  }

  void _initializeAnimations() {
    // تحريك نبضي للدائرة
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

    // دوران للدائرة
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

    // تلاشي للرسائل
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

    // بدء التحريكات
    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
    _fadeController.forward();
  }

  void _startSearching() async {
    try {
      // إذا كانت هناك رحلة نشطة قيد الانتظار، لا تطلب مرة أخرى
      if (tripController.hasActiveTrip.value &&
          tripController.activeTrip.value != null &&
          tripController.activeTrip.value!.status == TripStatus.pending) {
        return;
      }

      await tripController.requestTrip(
        pickup: widget.pickup,
        destination: widget.destination,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر طلب الرحلة، يرجى المحاولة مرة أخرى',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      Get.back();
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
    _rotateController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isSmall = screenHeight < 700;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Searching Animation
                    _buildSearchingAnimation(small: isSmall),

                    SizedBox(height: isSmall ? 16 : 40),

                    // Trip Details
                    _buildTripDetails(),

                    SizedBox(height: isSmall ? 16 : 40),

                    // Search Status
                    _buildSearchStatus(),

                    SizedBox(height: isSmall ? 20 : 60),

                    // Cancel Button
                    _buildCancelButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          const Expanded(
            child: Text(
              'البحث عن سائق',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // للتوازن
        ],
      ),
    );
  }

  Widget _buildSearchingAnimation({bool small = false}) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _rotateController]),
      builder: (context, child) {
        final double outerSize = small ? 90 : 120;
        final double innerSize = small ? 60 : 80;
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value * 2 * 3.14159,
            child: Container(
              width: outerSize,
              height: outerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.blue.withOpacity(0.1),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: innerSize,
                  height: innerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripDetails() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            // Pickup
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    widget.pickup.address,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Destination
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    widget.destination.address,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Trip Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  Icons.access_time,
                  'الوقت المتوقع',
                  _formatTime(widget.estimatedDuration),
                ),
                _buildInfoItem(
                  Icons.attach_money,
                  'السعر المتوقع',
                  '${widget.estimatedFare.toStringAsFixed(2)} ج.م',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchStatus() {
    return Obx(() {
      final remainingSeconds = tripController.remainingSearchSeconds.value;
      final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
      final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

      return Column(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: const Text(
              'جارٍ البحث عن سائق...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'الوقت المتبقي: $minutes:$seconds',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCancelButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _cancelSearch(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade400,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'إلغاء البحث',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
void _cancelSearch() {
  if (Get.isSnackbarOpen == true) {
    try {
      Get.closeCurrentSnackbar();
    } catch (_) {}
  }

  Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // زوايا ناعمة
      ),
      title: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
          SizedBox(width: 8),
          Text(
            'إلغاء البحث',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: const Text(
        'هل أنت متأكد أنك تريد إلغاء البحث عن سائق؟',
        style: TextStyle(fontSize: 15, height: 1.4),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text(
            'لا',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Future.microtask(() async {
              if (Get.isSnackbarOpen == true) {
                try {
                  Get.closeCurrentSnackbar();
                } catch (_) {}
              }
              Get.back();
              await tripController.cancelTrip();
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.close, color: Colors.white, size: 18),
          label: const Text(
            'نعم، إلغاء',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

}
