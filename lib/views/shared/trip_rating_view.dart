import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/routes/app_routes.dart';
import '../../main.dart'; // ✅ لـ logger
import '../../controllers/my_map_controller.dart';

class TripRatingView extends StatefulWidget {
  const TripRatingView({super.key});

  @override
  State<TripRatingView> createState() => _TripRatingViewState();
}

class _TripRatingViewState extends State<TripRatingView> {
  final TripController tripController = Get.put(TripController());
  final TextEditingController commentController = TextEditingController();
  final MyMapController mapController =
      Get.put(MyMapController(), permanent: true);
  int rating = 0;
  String? selectedReason;
  bool isSubmitting = false;

  late final TripModel trip;
  late final bool isDriver;

  final Map<int, List<String>> driverReasons = {
    1: [
      'سلوك غير لائق',
      'تأخر عن الموعد',
      'أمر بالسير في طريق خاطئ',
      'أزعج أثناء الرحلة'
    ],
    2: [
      'لم يدفع المبلغ بالكامل',
      'طلب تعديل الوجهة أكثر من مرة',
      'تحدث بطريقة غير محترمة',
      'ترك مخلفات في السيارة'
    ],
    3: ['تأخر قليلًا', 'مكالمة طويلة أثناء الرحلة', 'لم يكن واضحًا في الوجهة'],
  };

  final Map<int, List<String>> riderReasons = {
    1: ['قيادة خطيرة', 'معاملة سيئة', 'سيارة غير نظيفة', 'رائحة كريهة'],
    2: ['تأخر كثير', 'عدم اتباع المسار', 'مكيف لا يعمل', 'سيارة قديمة'],
    3: ['محادثة مزعجة', 'موسيقى عالية', 'توقف غير مبرر'],
  };

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    trip = args['trip'] as TripModel;
    isDriver = args['isDriver'] as bool? ?? false;
   // اعتراض الـ back system events
  // SystemChannels.platform.setMessageHandler((message) async {
  //   if (message == 'SystemNavigator.pop') {
  //     if (!isSubmitting) {
  //       await _skipRating();
  //     }
  //     return ''; // منع الخروج
  //   }
  //   return null;
  // });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
  onWillPop: () async {
    if (!isSubmitting) {
      await _skipRating(); // تنفيذ نفس زر الإكس
    }
    return false; // منع الخروج
  },
      // onWillPop: () async => false, // 🔒 منع الرجوع من صفحة التقييم
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTripSummary(),
                    const SizedBox(height: 30),
                    _buildRatingStars(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: rating > 0 && rating <= 3
                          ? Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: _buildReasons(),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),
                    _buildCommentField(),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
  return Stack(
    children: [
      Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 247, 186, 56),
            Color.fromARGB(255, 235, 147, 15)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const Icon(Icons.star_rounded, size: 60, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            isDriver ? 'قيّم الراكب' : 'قيّم السائق',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ملاحظاتك تساعدنا على تحسين التجربة للجميع',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
      ),

      // 🔹 زر الإغلاق (❌)
     Positioned(
  top: 8,
  right: 8,
  child: IconButton(
    icon: const Icon(Icons.close, color: Colors.white, size: 30),
    onPressed: () async {
      setState(() => isSubmitting = true);

      try {
        // تنظيف markers فقط
        if (Get.isRegistered<MyMapController>()) {
          mapController.clearTripMarkers(tripId: trip.id);
        }

        // إذا تريد تقييم رمزي بدون التأثير على المعدل
        const int neutralRating = 5;
        const String neutralComment = 'لم يقم المستخدم بإرسال تقييم';
        final targetUserId = isDriver ? trip.riderId : trip.driverId;
        if (targetUserId != null) {
          await tripController.submitRating(
            tripId: trip.id,
            rating: neutralRating,
            comment: neutralComment,
            isDriver: isDriver,
            userId: targetUserId,
          );
        }

        // الانتقال للهوم
        if (mounted) {
          Get.offAllNamed(isDriver ? AppRoutes.DRIVER_HOME : AppRoutes.RIDER_HOME);
        }
      } catch (e) {
        Get.snackbar('خطأ', 'حدث خطأ أثناء التجاوز',
            backgroundColor: Colors.red, colorText: Colors.white);
      } finally {
        if (mounted) setState(() => isSubmitting = false);
      }
    },
  ),
),

    ],
    );
  }

  Widget _buildTripSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          _infoRow('المسافة:', '${trip.distance.toStringAsFixed(1)} كم'),
          const Divider(height: 20),
          _infoRow('الأجرة:', '${trip.fare.toStringAsFixed(0)} د.ع',
              valueStyle: const TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(value, style: valueStyle ?? const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildRatingStars() {
    return Column(
      children: [
        Text(
          isDriver
              ? 'كيف كانت تجربتك مع الراكب؟'
              : 'كيف كانت تجربتك مع السائق؟',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return GestureDetector(
              onTap: () => setState(() => rating = starValue),
              child: AnimatedScale(
                scale: rating == starValue ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  rating >= starValue
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 45,
                  color: Colors.amber,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildReasons() {
    final reasons =
        isDriver ? (driverReasons[rating] ?? []) : (riderReasons[rating] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ما السبب؟',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: reasons.map((reason) {
            final isSelected = selectedReason == reason;
            return GestureDetector(
              onTap: () =>
                  setState(() => selectedReason = isSelected ? null : reason),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.orange.shade100
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isSelected
                          ? Colors.orange.shade700
                          : Colors.transparent,
                      width: 2),
                ),
                child: Text(reason,
                    style: TextStyle(
                        color: isSelected
                            ? Colors.orange.shade900
                            : Colors.black87)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    return TextField(
      controller: commentController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: isDriver
            ? 'أضف تعليقًا عن الراكب (اختياري)'
            : 'أضف تعليقًا عن السائق (اختياري)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

// Widget _buildBottomButtons() {
//   return Container(
//     padding: const EdgeInsets.all(16),
//     decoration: const BoxDecoration(
//       color: Colors.white,
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black12, 
//           blurRadius: 10, 
//           offset: Offset(0, -2)
//         )
//       ],
//     ),
//     child: Row(
//       children: [
//         // 🔙 زر الرجوع (نفس عمل زر الإكس)
//         Expanded(
//           child: OutlinedButton(
//             onPressed: isSubmitting ? null : _skipRating,
//             style: OutlinedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               side: BorderSide(color: Colors.orange.shade700, width: 2),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12)),
//             ),
//             child: const Text(
//               'رجوع',
//               style: TextStyle(
//                 fontSize: 18, 
//                 fontWeight: FontWeight.bold, 
//                 color: Colors.orange
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         // ⭐ زر الإرسال
//         Expanded(
//           child: ElevatedButton(
//             onPressed: rating == 0 || isSubmitting ? null : _submitRating,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.orange.shade700,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12)),
//             ),
//             child: isSubmitting
//                 ? const SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(
//                         color: Colors.white, strokeWidth: 2))
//                 : const Text(
//                     'إرسال التقييم',
//                     style: TextStyle(
//                         fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//           ),
//         ),
//       ],
//     ),
//   );
// }

Future<void> _skipRating() async {
  setState(() => isSubmitting = true);
  try {
    // ✅ تنظيف الماركرز فقط
    if (Get.isRegistered<MyMapController>()) {
      mapController.clearTripMarkers(tripId: trip.id);
    }

    // ❌ لا تعمل أي تقييم أو استدعاء لـ submitRating هنا
    // فقط خروج بدون تقييم
    if (mounted) {
      Get.offAllNamed(isDriver ? AppRoutes.DRIVER_HOME : AppRoutes.RIDER_HOME);
    }

    logger.i('🟡 المستخدم تخطى صفحة التقييم بدون إرسال أي تقييم.');
  } catch (e) {
    Get.snackbar('خطأ', 'حدث خطأ أثناء الرجوع',
        backgroundColor: Colors.red, colorText: Colors.white);
  } finally {
    if (mounted) setState(() => isSubmitting = false);
  }
}

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: rating == 0 ? null : _submitRating,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('إرسال التقييم',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }



Future<void> _submitRating() async {
  if (isSubmitting) return; // ✅ منع الضغط المتكرر
  setState(() => isSubmitting = true);

  try {
    final comment = commentController.text.trim();
    final fullComment = selectedReason != null
        ? '$selectedReason${comment.isNotEmpty ? ' - $comment' : ''}'
        : comment;
    final targetUserId = isDriver ? trip.riderId : trip.driverId;
    
    if (targetUserId == null) {
      Get.snackbar('خطأ', 'معرف المستخدم غير موجود',
          backgroundColor: Colors.red, colorText: Colors.white);
      setState(() => isSubmitting = false);
      return;
    }

    await tripController.submitRating(
      tripId: trip.id,
      rating: rating,
      comment: fullComment,
      isDriver: isDriver,
      userId: targetUserId,
    );

    // ✅ مسح ماركرات الرحلة
    if (Get.isRegistered<MyMapController>()) {
      mapController.clearTripMarkers(tripId: trip.id);
    }

    // 🔒 مسح storage وإعادة تفعيل السائق
    if (isDriver && Get.isRegistered<DriverController>()) {
      final driverCtrl = Get.find<DriverController>();
      driverCtrl.storage.remove('activeTripId');
      driverCtrl.storage.remove('activeTripStatus');
      
      // ✅ إعادة تعيين حالة السائق للمتاح
      driverCtrl.isAvailable.value = true;
      driverCtrl.isOnTrip.value = false;
      driverCtrl.currentTrip.value = null;
      
      // ✅ إعادة تشغيل الاستماع للطلبات إذا كان السائق متصل
      if (driverCtrl.isOnline.value) {
        driverCtrl.startListeningForRequests();
        driverCtrl.startLocationUpdates();
        logger.i('🎧 Driver available again - listening for new requests');
      }
      
      logger.i('🔒 Storage cleared after rating - driver ready for new trips');
    }

    // ✅ عرض رسالة نجاح
    Get.snackbar('شكراً', 'تم إرسال تقييمك بنجاح',
        backgroundColor: Colors.green, colorText: Colors.white,
        duration: const Duration(seconds: 2));

    // ✅ الانتقال للهوم بعد تأخير بسيط
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      Get.offAllNamed(isDriver ? AppRoutes.DRIVER_HOME : AppRoutes.RIDER_HOME);
    }
  } catch (e) {
    Get.snackbar('خطأ', 'حدث خطأ أثناء إرسال التقييم',
        backgroundColor: Colors.red, colorText: Colors.white);
  } finally {
    if (mounted) {
      setState(() => isSubmitting = false);
    }
  }
}
   
  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
}
