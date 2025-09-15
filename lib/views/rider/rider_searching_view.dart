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

  // Rush/price state
  final RxBool _rushApplied = false.obs;
  late final RxDouble _displayFare;

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
    // تشغيل الطلب بعد أول إطار لتجنب setState أثناء البناء
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    // //  _startSearching();
    // });
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

    // animation للوضع المستعجل
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

    // بدء التحريكات
    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
    _fadeController.forward();
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
    _urgentController.dispose();
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

                    SizedBox(height: isSmall ? 20 : 40),

                    // Action Buttons
                    _buildActionButtons(),
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
                Obx(() => _buildInfoItem(
                      Icons.attach_money,
                      'السعر المتوقع',
                      '${_displayFare.value.toStringAsFixed(2)} د.ع',
                    )),
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
            child: Obx(() {
              if (tripController.isUrgentMode.value) {
                return Column(
                  children: [
                    AnimatedBuilder(
                      animation: _urgentAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _urgentAnimation.value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flash_on,
                                color: Colors.red,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'وضع مستعجل - عميل مهم',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'جاري البحث عن سائق على وجه السرعة...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    const Text(
                      'جارٍ البحث عن سائق...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
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
              }
            }),
          ),
        ],
      );
    });
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          // Rush Button
          Obx(() => _rushApplied.value
              ? const SizedBox.shrink()
              : SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _showRushConfirmationDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.flash_on, size: 20),
                    label: const Text(
                      'أنا مستعجل',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )),

          const SizedBox(height: 12),

          // Cancel Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _cancelSearch(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.grey.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.close, size: 20),
              label: const Text(
                'إلغاء البحث',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRushConfirmationDialog() {
    final rushFare = widget.estimatedFare * 1.2; // زيادة 20%

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.flash_on, color: Colors.red.shade400, size: 28),
            const SizedBox(width: 8),
            const Text(
              'رحلة مستعجلة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'لحصول على فرصة أفضل بقبول الطلب، تم زيادة السعر بنسبة 20%',
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'السعر الجديد:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${rushFare.toStringAsFixed(0)} د.ع',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              _applyRushMode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.flash_on, color: Colors.white, size: 18),
            label: const Text(
              'تأكيد',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _applyRushMode() async {
    try {
      // تفعيل الوضع المستعجل في TripController
      tripController.isUrgentMode.value = true;

      // تشغيل animation للوضع المستعجل
      _urgentController.repeat(reverse: true);

      // حدّث السعر المعروض محلياً لمرة واحدة ثم أخفِ زر الاستعجال
      if (!_rushApplied.value) {
        _displayFare.value = (widget.estimatedFare * 1.2);
        _rushApplied.value = true;
      }

      Get.snackbar(
        'تم التفعيل',
        'تم تفعيل وضع الاستعجال - جاري البحث عن سائق على وجه السرعة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر تفعيل وضع الاستعجال',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _cancelSearch() {
    if (Get.isSnackbarOpen == true) {
      try {
        Get.closeCurrentSnackbar();
      } catch (_) {}
    }

    // توجيه إلى صفحة أسباب الإلغاء
    Get.toNamed('/rider-trip-cancellation-reasons');
  }
}


// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // لتحديث بيانات الرحلة مباشرة
// import 'package:transport_app/controllers/trip_controller.dart';
// import 'package:transport_app/controllers/auth_controller.dart';
// import 'package:transport_app/models/trip_model.dart';
// import 'package:transport_app/routes/app_routes.dart';

// class RiderSearchingView extends StatefulWidget {
//   final LocationPoint pickup;
//   final LocationPoint destination;
//   final double estimatedFare;
//   final int estimatedDuration;
//   final Map<String, dynamic>? tripDetails; // ✅ استقبال تفاصيل الرحلة كاملة

//   const RiderSearchingView({
//     super.key,
//     required this.pickup,
//     required this.destination,
//     required this.estimatedFare,
//     required this.estimatedDuration,
//     this.tripDetails, // ✅ جعلها اختيارية
//   });

//   @override
//   State<RiderSearchingView> createState() => _RiderSearchingViewState();
// }

// class _RiderSearchingViewState extends State<RiderSearchingView>
//     with TickerProviderStateMixin {
//   final TripController tripController = Get.find();
//   final AuthController authController = Get.find();

//   // Rush/price state
//   final RxBool _rushApplied = false.obs;
//   late final RxDouble _displayFare; // ✅ لتحديث السعر المعروض بعد وضع الاستعجال

//   late AnimationController _pulseController;
//   late AnimationController _rotateController;
//   late AnimationController _fadeController;
//   late Animation<double> _pulseAnimation;
//   late Animation<double> _rotateAnimation;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
//     // تهيئة السعر المعروض بقيمة السعر المقدرة
//     _displayFare = widget.estimatedFare.obs;
//     _initializeAnimations();

//     // ✅ تشغيل الطلب إذا لم تكن هناك رحلة نشطة قيد الانتظار بالفعل
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       // تحقق مما إذا كانت الرحلة النشطة الموجودة هي نفسها التي نحاول طلبها
//       // أو إذا لم تكن هناك رحلة نشطة على الإطلاق
//       if (!tripController.isRequestingTrip.value &&
//           (tripController.activeTrip.value == null ||
//               tripController.activeTrip.value?.status != TripStatus.pending ||
//               tripController.activeTrip.value?.id != widget.tripDetails?['id'])) {
//         _startSearching();
//       } else {
//         // إذا كانت هناك رحلة pending بالفعل وكنت في نفس الشاشة،
//         // تأكد من تحديث السعر إذا كان قد تم تطبيق وضع الاستعجال مسبقًا
//         if (tripController.activeTrip.value?.isRush == true) {
//           _rushApplied.value = true;
//           _displayFare.value = tripController.activeTrip.value!.fare;
//         }
//       }
//     });
//   }

//   void _initializeAnimations() {
//     // تحريك نبضي للدائرة
//     _pulseController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     );
//     _pulseAnimation = Tween<double>(
//       begin: 0.8,
//       end: 1.2,
//     ).animate(CurvedAnimation(
//       parent: _pulseController,
//       curve: Curves.easeInOut,
//     ));

//     // دوران للدائرة
//     _rotateController = AnimationController(
//       duration: const Duration(seconds: 3),
//       vsync: this,
//     );
//     _rotateAnimation = Tween<double>(
//       begin: 0,
//       end: 1,
//     ).animate(CurvedAnimation(
//       parent: _rotateController,
//       curve: Curves.linear,
//     ));

//     // تلاشي للرسائل
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeIn,
//     ));

//     // بدء التحريكات
//     _pulseController.repeat(reverse: true);
//     _rotateController.repeat();
//     _fadeController.forward();
//   }

//   void _startSearching() async {
//     try {
//       // ✅ تحقق إضافي هنا قبل الطلب (على الرغم من أن الكنترولر سيتعامل معها)
//       if (tripController.isRequestingTrip.value ||
//           (tripController.hasActiveTrip.value &&
//               tripController.activeTrip.value?.status != TripStatus.initial)) {
//         return; // لا تفعل شيئًا إذا كان هناك طلب بالفعل أو رحلة قيد الانتظار
//       }

//       await tripController.requestTrip(
//         pickup: widget.pickup,
//         destination: widget.destination,
//         tripDetails: widget.tripDetails, // ✅ تمرير التفاصيل الإضافية
//       );
//     } catch (e) {
//       Get.snackbar(
//         'خطأ',
//         'تعذر طلب الرحلة، يرجى المحاولة مرة أخرى',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       Get.back();
//     }
//   }

//   String _formatTime(int minutes) {
//     if (minutes < 60) {
//       return '$minutes دقيقة';
//     } else {
//       final hours = minutes ~/ 60;
//       final remainingMinutes = minutes % 60;
//       return '$hours ساعة ${remainingMinutes > 0 ? '$remainingMinutes دقيقة' : ''}';
//     }
//   }

//   @override
//   void dispose() {
//     _pulseController.dispose();
//     _rotateController.dispose();
//     _fadeController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final double screenHeight = MediaQuery.of(context).size.height;
//     final bool isSmall = screenHeight < 700;
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header
//             _buildHeader(),

//             // Main Content
//             Expanded(
//               child: SingleChildScrollView(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // Searching Animation
//                     _buildSearchingAnimation(small: isSmall),

//                     SizedBox(height: isSmall ? 16 : 40),

//                     // Trip Details
//                     _buildTripDetails(),

//                     SizedBox(height: isSmall ? 16 : 40),

//                     // Search Status
//                     _buildSearchStatus(),

//                     SizedBox(height: isSmall ? 20 : 40),

//                     // Action Buttons
//                     _buildActionButtons(),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       child: Row(
//         children: [
//           IconButton(
//             onPressed: () => Get.back(),
//             icon: const Icon(Icons.arrow_back, color: Colors.black),
//           ),
//           const Expanded(
//             child: Text(
//               'البحث عن سائق',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           const SizedBox(width: 48), // للتوازن
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchingAnimation({bool small = false}) {
//     return AnimatedBuilder(
//       animation: Listenable.merge([_pulseController, _rotateController]),
//       builder: (context, child) {
//         final double outerSize = small ? 90 : 120;
//         final double innerSize = small ? 60 : 80;
//         return Transform.scale(
//           scale: _pulseAnimation.value,
//           child: Transform.rotate(
//             angle: _rotateAnimation.value * 2 * 3.14159,
//             child: Container(
//               width: outerSize,
//               height: outerSize,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     Colors.blue.withOpacity(0.3),
//                     Colors.blue.withOpacity(0.1),
//                   ],
//                 ),
//               ),
//               child: Center(
//                 child: Container(
//                   width: innerSize,
//                   height: innerSize,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.blue,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.blue.withOpacity(0.3),
//                         blurRadius: 20,
//                         spreadRadius: 5,
//                       ),
//                     ],
//                   ),
//                   child: const Icon(
//                     Icons.directions_car,
//                     color: Colors.white,
//                     size: 40,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildTripDetails() {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 30),
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.grey[50],
//           borderRadius: BorderRadius.circular(15),
//           border: Border.all(color: Colors.grey[200]!),
//         ),
//         child: Column(
//           children: [
//             // Pickup
//             Row(
//               children: [
//                 Container(
//                   width: 12,
//                   height: 12,
//                   decoration: const BoxDecoration(
//                     color: Colors.green,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 const SizedBox(width: 15),
//                 Expanded(
//                   child: Text(
//                     widget.pickup.address,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 20),

//             // Destination
//             Row(
//               children: [
//                 Container(
//                   width: 12,
//                   height: 12,
//                   decoration: const BoxDecoration(
//                     color: Colors.red,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 const SizedBox(width: 15),
//                 Expanded(
//                   child: Text(
//                     widget.destination.address,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 20),

//             // Trip Info
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildInfoItem(
//                   Icons.access_time,
//                   'الوقت المتوقع',
//                   _formatTime(widget.estimatedDuration),
//                 ),
//                 Obx(() => _buildInfoItem(
//                       Icons.attach_money,
//                       'السعر المتوقع',
//                       '${_displayFare.value.toStringAsFixed(0)} د.ع', // ✅ Fixed to 0 decimal places for IQD
//                     )),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoItem(IconData icon, String label, String value) {
//     return Column(
//       children: [
//         Icon(icon, color: Colors.blue, size: 24),
//         const SizedBox(height: 8),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey[600],
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSearchStatus() {
//     return Obx(() {
//       final remainingSeconds = tripController.remainingSearchSeconds.value;
//       final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
//       final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

//       return Column(
//         children: [
//           FadeTransition(
//             opacity: _fadeAnimation,
//             child: const Text(
//               'جارٍ البحث عن سائق...',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.blue,
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             'الوقت المتبقي: $minutes:$seconds',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       );
//     });
//   }

//   Widget _buildActionButtons() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 30),
//       child: Column(
//         children: [
//           // Rush Button
//           Obx(() => _rushApplied.value
//               ? const SizedBox.shrink()
//               : SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton.icon(
//                     onPressed: () => _showRushConfirmationDialog(),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red.shade400,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 2,
//                     ),
//                     icon: const Icon(Icons.flash_on, size: 20),
//                     label: const Text(
//                       'أنا مستعجل',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 )),

//           const SizedBox(height: 12),

//           // Cancel Button
//           SizedBox(
//             width: double.infinity,
//             height: 50,
//             child: ElevatedButton.icon(
//               onPressed: () => _cancelSearch(),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.grey.shade300,
//                 foregroundColor: Colors.grey.shade700,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 0,
//               ),
//               icon: const Icon(Icons.close, size: 20),
//               label: const Text(
//                 'إلغاء البحث',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showRushConfirmationDialog() {
//     final rushFare = widget.estimatedFare * 1.2; // زيادة 20%

//     Get.dialog(
//       AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: Row(
//           children: [
//             Icon(Icons.flash_on, color: Colors.red.shade400, size: 28),
//             const SizedBox(width: 8),
//             const Text(
//               'رحلة مستعجلة',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'لحصول على فرصة أفضل بقبول الطلب، سيتم زيادة السعر بنسبة 20%',
//               style: TextStyle(fontSize: 15, height: 1.4),
//             ),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.red.shade200),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'السعر الجديد:',
//                     style: TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   Text(
//                     '${rushFare.toStringAsFixed(0)} د.ع', // ✅ Fixed to 0 decimal places for IQD
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.red.shade600,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text(
//               'إلغاء',
//               style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
//             ),
//           ),
//           ElevatedButton.icon(
//             onPressed: () {
//               Get.back();
//               _applyRushMode();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red.shade400,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             icon: const Icon(Icons.flash_on, color: Colors.white, size: 18),
//             label: const Text(
//               'تأكيد',
//               style:
//                   TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _applyRushMode() async {
//     try {
//       final trip = tripController.activeTrip.value;
//       if (trip != null && trip.status == TripStatus.pending) {
//         // تحديث السعر المعروض محلياً لمرة واحدة ثم أخفِ زر الاستعجال
//         if (!_rushApplied.value) {
//           _displayFare.value = (widget.estimatedFare * 1.2);
//           _rushApplied.value = true;
//         }
//         // ✅ تحديث الرحلة في قاعدة البيانات لتشمل isRush
//         await FirebaseFirestore.instance.collection('trips').doc(trip.id).update({
//           'isRush': true,
//           'fare': _displayFare.value, // تحديث الأجرة النهائية
//           'updatedAt': Timestamp.now(),
//         });
//         // ✅ تحديث كائن الرحلة النشطة محلياً
//         tripController.activeTrip.value = trip.copyWith(
//           isRush: true,
//           fare: _displayFare.value,
//         );

//         Get.snackbar(
//           'تم التفعيل',
//           'تم تفعيل وضع الاستعجال - سيتم إعطاؤك أولوية أعلى',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//           duration: const Duration(seconds: 3),
//         );
//       } else {
//         Get.snackbar(
//           'خطأ',
//           'لا يمكن تفعيل وضع الاستعجال الآن. الرحلة ليست قيد الانتظار.',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//         );
//       }
//     } catch (e) {
//       Get.snackbar(
//         'خطأ',
//         'تعذر تفعيل وضع الاستعجال',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

//   void _cancelSearch() {
//     if (Get.isSnackbarOpen == true) {
//       try {
//         Get.closeCurrentSnackbar();
//       } catch (_) {}
//     }

//     Get.dialog(
//       AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16), // زوايا ناعمة
//         ),
//         title: Row(
//           children: const [
//             Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
//             SizedBox(width: 8),
//             Text(
//               'إلغاء البحث',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//         content: const Text(
//           'هل أنت متأكد أنك تريد إلغاء البحث عن سائق؟',
//           style: TextStyle(fontSize: 15, height: 1.4),
//         ),
//         actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text(
//               'لا',
//               style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
//             ),
//           ),
//           ElevatedButton.icon(
//             onPressed: () {
//               Future.microtask(() async {
//                 if (Get.isSnackbarOpen == true) {
//                   try {
//                     Get.closeCurrentSnackbar();
//                   } catch (_) {}
//                 }
//                 Get.back();
//                 await tripController.cancelTrip();
//               });
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             icon: const Icon(Icons.close, color: Colors.white, size: 18),
//             label: const Text(
//               'نعم، إلغاء',
//               style:
//                   TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }