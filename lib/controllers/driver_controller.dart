

 import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/services/driver_profile_service.dart';
import 'package:transport_app/services/location_service.dart';
import 'package:transport_app/routes/app_routes.dart';
import '../main.dart';
import '../views/common/chat_service/communication_service.dart' as forChat;

class DriverController extends GetxController {
  static DriverController get to => Get.find();

  static const double ADMIN_COMMISSION = 200.0;
  static const double MAX_DEBT_LIMIT = 15000.0;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final AuthController authController = AuthController.to;
  final LocationService locationService = LocationService.to;
  final DriverProfileService profileService = Get.find<DriverProfileService>();
  final forChat.CommunicationService communicationService =
      Get.find<forChat.CommunicationService>();

  final RxBool isOnline = true.obs;
  final RxBool isAvailable = true.obs;
  final RxBool isOnTrip = false.obs;

  final Rx<TripModel?> currentTrip = Rx<TripModel?>(null);

  final RxList<TripModel> tripRequests = <TripModel>[].obs;
  final RxList<String> declinedTrips = <String>[].obs;

  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  Timer? _locationUpdateTimer;
  final mymapController = MyMapController();
  final RxDouble zoom = 15.0.obs;
  MapController mapController = MapController();

  final RxList<TripModel> tripHistory = <TripModel>[].obs;
  final RxBool isLoadingHistory = false.obs;

  final RxDouble todayEarnings = 0.0.obs;
  final RxDouble weekEarnings = 0.0.obs;
  final RxDouble monthEarnings = 0.0.obs;
  final RxDouble currentDebt = 0.0.obs;

  final RxInt completedTripsToday = 0.obs;

  StreamSubscription<QuerySnapshot>? _tripRequestsSubscription;
  StreamSubscription<DocumentSnapshot>? _currentTripSubscription;
  Timer? _cleanupTimer;
  final GetStorage storage = GetStorage();
  static const String _ONLINE_STATUS_KEY = 'driver_online_status';

  Timer? _autoCancelTimer;

  @override
  void onInit() {
    super.onInit();
    logger.i('🚀 بدء تهيئة DriverController');
    _loadSavedOnlineStatus();
    
    // ✅ التأكد من التهيئة بعد build الأول
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPaymentStatusAndInitialize();
    });
  }
  
  @override
  void onReady() {
    super.onReady();
    // ✅ ضمان إعادة الاستماع عند الرجوع للتطبيق
    if (isOnline.value && !isOnTrip.value && isAvailable.value) {
      logger.i('🔄 onReady: إعادة تفعيل الاستماع');
      startListeningForRequests();
      startLocationUpdates();
    }
    
  // ✅ تأكد إنك بتبدأ الاستماع لو السائق أونلاين فعلاً
  ever(isOnline, (online) {
    if (online && !isOnTrip.value) {
      logger.i('🚀 Auto-starting listeners after state restore');
      startListeningForRequests();
      startLocationUpdates();
    } else {
      logger.i('🛑 Auto-stop listeners (offline or in trip)');
      _tripRequestsSubscription?.cancel();
      _tripRequestsSubscription = null;
      _locationUpdateTimer?.cancel();
      _locationUpdateTimer = null;
    }
  });

  // ✅ في حالة فتح التطبيق لأول مرة بعد الإغلاق
  Future.delayed(const Duration(milliseconds: 500), () {
    if (isOnline.value && !isOnTrip.value) {
      logger.i('🎧 Reinitializing listeners after cold start');
      startListeningForRequests();
      startLocationUpdates();
    }
  });
  }

  Future<void> _checkPaymentStatusAndInitialize() async {
    try {
      final paymentLock = storage.read('paymentLock');
      
      if (paymentLock != null && paymentLock['status'] == 'pending') {
        logger.i('💳 Payment pending detected - forcing navigation to payment page');
        await surePayment();
        return;
      }

      logger.i('🚦 No payment pending. Full initialization.');
      isAvailable.value = true;
      
      await _initializeDriverController();
      _startCleanupTimer();
      _updateDriverLocationOnInit();
      _initializeDebtListener();
      _startAutoTripCancellation();

      ever(currentTrip, (TripModel? trip) {
        if (trip != null) {
          if (trip.status == TripStatus.completed || trip.status == TripStatus.cancelled) {
            logger.i('🧹 تنظيف الماركرز بعد انتهاء الرحلة');
            _cleanupDriverMarkersAfterTripEnd();
          }
        }
      });

      // ✅ بدء الاستماع فوراً بعد التهيئة
      if (isOnline.value && !isOnTrip.value && isAvailable.value) {
        logger.i('🎧 بدء الاستماع للطلبات مباشرة');
        Future.delayed(const Duration(milliseconds: 500), () {
          startListeningForRequests();
          startLocationUpdates();
        });
      }
    } catch (e) {
      logger.e('❌ خطأ في التهيئة: $e');
    }
  }

  Future<void> surePayment() async {
    final paymentLock = storage.read('paymentLock');

    logger.i('💳 surePayment check: $paymentLock');

    if (paymentLock == null || paymentLock['status'] != 'pending') {
      logger.i('🚦 No valid payment pending.');
      return;
    }

    final tripId = paymentLock['tripId'];
    
    try {
      final tripDoc = await firestore.collection('trips').doc(tripId).get();

      if (!tripDoc.exists) {
        logger.w('🚦 Trip not found. Cleaning storage.');
        storage.remove('paymentLock');
        Get.offAllNamed(AppRoutes.DRIVER_HOME);
        return;
      }

      final trip = TripModel.fromMap(tripDoc.data()!);
      currentTrip.value = trip;

      logger.i('💳 Forcing navigation to payment page...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(
          AppRoutes.DRIVER_PAYMENT_CONFIRMATION,
          arguments: {'trip': trip},
        );
      });
    } catch (e) {
      logger.e('❌ surePayment error: $e');
      storage.remove('paymentLock');
      Get.offAllNamed(AppRoutes.DRIVER_HOME);
    }
  }

  /// ✅ تحميل الرحلة النشطة للسائق (إن وجدت)
  Future<void> checkActiveTrip() async {
    try {
      final driverId = authController.currentUser.value?.id;
      if (driverId == null) {
        logger.w('⚠️ لا يوجد معرف سائق - تخطي checkActiveTrip');
        return;
      }

      logger.i('🔍 فحص الرحلة النشطة للسائق: $driverId');

      // ✅ البحث عن رحلة نشطة للسائق (ليست ملغاة أو مكتملة)
      final snapshot = await firestore
          .collection('trips')
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: [
            TripStatus.accepted.name,
            TripStatus.driverArrived.name,
            TripStatus.inProgress.name,
          ])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final tripData = snapshot.docs.first.data();
        final trip = TripModel.fromMap(tripData);
        
        currentTrip.value = trip;
        isOnTrip.value = true;
        isAvailable.value = false;
        
        logger.i('✅ تم تحميل رحلة نشطة: ${trip.id} (حالة: ${trip.status.name})');
        
        // ✅ بدء الاستماع لتحديثات الرحلة بدون navigation
        _startCurrentTripListener(trip.id);
      } else {
        logger.i('🏠 لا توجد رحلة نشطة للسائق');
        currentTrip.value = null;
        isOnTrip.value = false;
        isAvailable.value = true;
      }
    } catch (e) { logger.e('❌ خطأ في فحص الرحلة النشطة: $e');
      currentTrip.value = null;
      isOnTrip.value = false;
      isAvailable.value = true;
    }
  }

  void _loadSavedOnlineStatus() {
    // ✅ فحص إذا كانت أول مرة يفتح فيها التطبيق
    if (!storage.hasData(_ONLINE_STATUS_KEY)) {
      // ✅ أول مرة: السائق غير متصل بشكل افتراضي
      isOnline.value = false;
      _saveOnlineStatus(false);
      logger.i('🆕 أول تشغيل - السائق غير متصل افتراضياً');
    } else {
      // ✅ تحميل الحالة المحفوظة
      final savedStatus = storage.read(_ONLINE_STATUS_KEY);
      isOnline.value = savedStatus ?? false;
      logger.i('✅ تم تحميل حالة الاتصال: ${isOnline.value ? "متصل" : "غير متصل"}');
    }
  }

  Future<void> toggleOnlineStatus() async {
    try {
      final newStatus = !isOnline.value;
      final oldStatus = isOnline.value;
      
      isOnline.value = newStatus;
      _saveOnlineStatus(newStatus);

      final driverId = authController.currentUser.value?.id;
      if (driverId != null) {
        await firestore.collection('users').doc(driverId).set({
          'additionalData': {'isOnline': newStatus},
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (newStatus && !isOnTrip.value) {
          logger.i('🟢 تحويل لمتصل - بدء الاستماع');
          // ✅ تأخير قصير للتأكد من تحديث Firebase
          await Future.delayed(const Duration(milliseconds: 500));
          startListeningForRequests();
          startLocationUpdates();
        } else if (!newStatus) {
          logger.i('🔴 تحويل لغير متصل - إيقاف الاستماع');
          _stopListeningForRequests();
          _locationUpdateTimer?.cancel();
          _locationUpdateTimer = null;
        }
      }

      Get.snackbar(
        'الحالة',
        newStatus ? 'أنت الآن متصل ✅' : 'أنت الآن غير متصل ❌',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: newStatus ? Colors.green : Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.e('❌ خطأ في تبديل حالة الاتصال: $e');
      // ✅ استرجاع الحالة السابقة عند الفشل
      isOnline.value = !isOnline.value;
    }
  }

  Future<void> loadEarningsData() async {
    try {
      final driverId = authController.currentUser.value?.id;
      if (driverId == null) return;

      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final todayDoc = await firestore.collection('driver_earnings').doc('${driverId}_$today').get();

      if (todayDoc.exists) {
        final data = todayDoc.data()!;
        todayEarnings.value = (data['totalEarnings'] ?? 0.0).toDouble();
        completedTripsToday.value = (data['tripsCount'] ?? 0).toInt();
      } else {
        todayEarnings.value = 0.0;
        completedTripsToday.value = 0;
      }

      weekEarnings.value = 0.0;
      monthEarnings.value = 0.0;
    } catch (e) {
      logger.w('خطأ في تحميل بيانات الأرباح: $e');
    }
  }

  Future<void> _loadEarningsData() async {
    await loadEarningsData();
  }


  /// ✅ حفظ حالة الاتصال
  void _saveOnlineStatus(bool status) {
    try {
      storage.write(_ONLINE_STATUS_KEY, status);
      logger.i('✅ تم حفظ حالة الاتصال: $status');
    } catch (e) {
      logger.e('❌ خطأ في حفظ حالة الاتصال: $e');
    }
  }

  void _clearCurrentTripState() {
    _currentTripSubscription?.cancel();
    _currentTripSubscription = null;
    currentTrip.value = null;
    isOnTrip.value = false;
    isAvailable.value = true; // ✅ تأكد أن السائق متاح بعد انتهاء الرحلة
    logger.i('Cleared current trip state.');
    // إعادة بدء الاستماع لطلبات الرحلات إذا كان السائق متصلاً ومتاحًا
    if (isOnline.value && isAvailable.value) {
      startListeningForRequests();
    }
  }

  Future<void> updateDriverDebt(double amount) async {
    try {
      final driverId = authController.currentUser.value?.id;
      if (driverId == null) return;

      await firestore.collection('users').doc(driverId).set({
        'additionalData': {
          'debtIqD': FieldValue.increment(amount.toInt()),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      logger.e('خطأ في تحديث الديون: $e');
    }
  }

  void startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null; // تأكد من تفريغ الـ timer القديم

   _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
  try {
    if (!isOnline.value) {
      timer.cancel();
      _locationUpdateTimer = null;
      return;
    }
    await _updateCurrentLocation();
  } catch (e) {
    logger.w('⚠️ خطأ أثناء تحديث الموقع: $e');
  }
});

  }

  Future<void> _updateCurrentLocation() async {
    try {
      final location = await locationService.getCurrentLocation();
      if (location != null) {
        currentLocation.value = location;

        final driverId = authController.currentUser.value?.id;
        if (driverId != null) {
          await firestore.collection('users').doc(driverId).update({
            'currentLat': location.latitude,
            'currentLng': location.longitude,
            'currentLatitude': location.latitude,
            'currentLongitude': location.longitude,
            'additionalData.currentLat': location.latitude,
            'additionalData.currentLng': location.longitude,
            'additionalData.lastLocationUpdate': FieldValue.serverTimestamp(),
            'lastSeen': FieldValue.serverTimestamp(),
          });

          logger.i(
              '✅ تم تحديث موقع السائق في جميع الحقول: ${location.latitude}, ${location.longitude}');
        }
      }
    } catch (e) {
      logger.w('خطأ في تحديث الموقع: $e');
    }
  }

  void _stopListeningForRequests() {
    _tripRequestsSubscription?.cancel();
    _tripRequestsSubscription = null;
    tripRequests.clear();
    logger.i('🔇 تم إيقاف الاستماع لطلبات الرحلات');
  }

  void _initializeDebtListener() {
    final driverId = authController.currentUser.value?.id;
    if (driverId == null) return;

    firestore.collection('users').doc(driverId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        currentDebt.value = (snapshot.data()?['debt'] ?? 0.0).toDouble();
      }
    });
  }
  final isEndingTrip = false.obs;
Future<void> endTrip(String tripId) async {
  try {
    if (tripId.isEmpty || currentTrip.value == null) {
      logger.w('⚠️ لا يمكن إنهاء الرحلة');
      return;
    }

    final trip = currentTrip.value!;
    isEndingTrip.value = true;

    logger.i('🏁 إنهاء الرحلة: $tripId');

    _currentTripSubscription?.cancel();
    _currentTripSubscription = null;

    await firestore.collection('trips').doc(tripId).update({
      'status': TripStatus.completed.name,
      'completedAt': FieldValue.serverTimestamp(),
    });

    currentTrip.value = null;
    isOnTrip.value = false;
    isAvailable.value = false;

    if (Get.isRegistered<MyMapController>()) {
      Get.find<MyMapController>().clearTripMarkers(tripId: tripId);
    }

    logger.i('💳 الانتقال لصفحة الدفع');
// حفظ حالة الدفع المعلق
try {
  storage.write('paymentLock', {
    'tripId': trip.id,
    'status': 'pending',
    'timestamp': DateTime.now().toIso8601String(),
  });
  logger.i('💳 Payment lock saved for trip: ${trip.id}');
} catch (e) {
  logger.w('⚠️ تعذر حفظ حالة الدفع: $e');
}

await Get.offAllNamed(
  AppRoutes.DRIVER_PAYMENT_CONFIRMATION,
  arguments: {'trip': trip},
);

    isEndingTrip.value = false;

    if (isOnline.value && !isOnTrip.value) {
      isAvailable.value = true;
      startListeningForRequests();
      startLocationUpdates();
    }

    logger.i('✅ تم إنهاء الرحلة');
  } catch (e) {
    isEndingTrip.value = false;
    logger.e('❌ خطأ: $e');
    Get.snackbar('خطأ', 'فشل إنهاء الرحلة',
        backgroundColor: Colors.red, colorText: Colors.white);
  }
}
 
  Future<void> _updateDriverLocationOnInit() async {
    try {
      LatLng? location = await locationService.getCurrentLocation();
      if (location != null) {
        currentLocation.value = location;

        logger.i(
            'تم الحصول على الموقع الحالي: ${location.latitude}, ${location.longitude}');
      }
    } catch (e) {
      logger.w('خطأ في الحصول على الموقع الأولي: $e');
    }
  }

  void ignoreTrip(String tripId) {
    declinedTrips.add(tripId);
    tripRequests.removeWhere((trip) => trip.id == tripId);
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 26), (timer) {
      _cleanupExpiredRequests();
    });
  }

  void _cleanupExpiredRequests() {
    final now = DateTime.now();

    tripRequests.removeWhere((trip) {
      final elapsed = now.difference(trip.createdAt).inSeconds;
      final isExpired = elapsed > 25;

      if (isExpired) {
        logger.i('🗑️ إزالة طلب منتهي الصلاحية: ${trip.id}');
        declinedTrips.remove(trip.id);
      }
      return isExpired;
    });
  }

  bool canAcceptTrip(TripModel trip) {
    if (currentDebt.value >= MAX_DEBT_LIMIT) {
      Get.snackbar(
        'تنبيه',
        'لا يمكنك قبول رحلات جديدة. يرجى سداد ديونك أولاً',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      Get.toNamed(AppRoutes.DRIVER_WALLET);
      return false;
    }
    return true;
  }

  final RxDouble pendingDebt = 0.0.obs;

  Future<void> _initializeDriverController() async {
    try {
      logger.i('📋 فحص اكتمال البروفايل...');
      final canReceiveRequests = await _checkProfileCompletion();
      if (!canReceiveRequests) {
        isAvailable.value = false;
        logger.w('❌ البروفايل غير مكتمل');
        return;
      }

      logger.i('📊 تحميل حالة السائق...');
      await _loadDriverStatus();

      logger.i('🔍 فحص الرحلة النشطة...');
      await checkActiveTrip();

      logger.i('💰 تحميل بيانات الأرباح...');
      await _loadEarningsData();

      // ✅ بدء الاستماع فوراً بعد التهيئة
      if (isOnline.value && !isOnTrip.value && isAvailable.value) {
        logger.i('🎧 بدء الاستماع للطلبات بعد التهيئة مباشرة');
        startListeningForRequests();
        startLocationUpdates();
      }

      logger.i('✅ السائق جاهز 100%');
    } catch (e) {
      logger.e('❌ خطأ في تهيئة السائق: $e');
    }
  }

  Future<void> _loadDriverStatus() async {
    try {
      final driverId = authController.currentUser.value?.id;
      if (driverId == null) return;

      DocumentSnapshot doc =
          await firestore.collection('users').doc(driverId).get();

      // تحديث الموقع إذا كان موجود
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final additionalData = data['additionalData'] as Map<String, dynamic>?;

        if (additionalData?['currentLat'] != null &&
            additionalData?['currentLng'] != null) {
          currentLocation.value = LatLng(
            additionalData!['currentLat'].toDouble(),
            additionalData['currentLng'].toDouble(),
          );
        }
      }

      // تحديث الحالة في Firebase حسب الحالة المحفوظة
      await firestore.collection('users').doc(driverId).set({
        'additionalData': {
          'isOnline': isOnline.value,
          'isAvailable': true,
        },
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      logger
          .i('✅ تم تحميل حالة السائق: ${isOnline.value ? "متصل" : "غير متصل"}');
    } catch (e) {
      logger.w('خطأ في تحميل حالة السائق: $e');
    }
  }

  Future<bool> _checkProfileCompletion() async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser.value?.id;

      if (userId == null) return false;

      final isComplete = await profileService.isProfileComplete(userId);
      if (!isComplete) {
        Get.snackbar(
          'تحذير',
          'يرجى إكمال بيانات البروفايل أولاً',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }

      final isApproved = await profileService.isDriverApproved(userId);
      if (!isApproved) {
        Get.snackbar(
          'تحذير',
          'حسابك قيد المراجعة من قبل الإدارة. سيتم إشعارك عند الموافقة.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }

      return true;
    } catch (e) {
      logger.w('خطأ في التحقق من اكتمال البروفايل: $e');
      return false;
    }
    }

  // Future<void> checkActiveTrip() async {
  //   try {
  //     final driverId = authController.currentUser.value?.id;
  //     if (driverId == null) return;

  //     QuerySnapshot querySnapshot = await firestore
  //         .collection('trips')
  //         .where('driverId', isEqualTo: driverId)
  //         .where('status', whereIn: ['accepted', 'driverArrived', 'inProgress'])
  //         .orderBy('createdAt', descending: true)
  //         .limit(1)
  //         .get();

  //     if (querySnapshot.docs.isNotEmpty) {
  //       TripModel trip = TripModel.fromMap(
  //           querySnapshot.docs.first.data() as Map<String, dynamic>);
  //       currentTrip.value = trip;
  //       isOnTrip.value = true;
  //       isAvailable.value = false; // السائق مشغول برحلة نشطة
  //       _startCurrentTripListener(trip.id);
  //     }
  //   } catch (e) {
  //     logger.w('خطأ في التحقق من الرحلة النشطة: $e');
  //   }
  // }

  Future<void> acceptTrip(TripModel trip) async {
    try {
      final canReceiveRequests = await _checkProfileCompletion();
      if (!canReceiveRequests) {
        return;
      }

      await _acceptTrip(trip);
    } catch (e) {
      logger.w('خطأ في قبول الرحلة: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء قبول الرحلة',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> declineTrip(TripModel trip) async {
    try {
      final driverId = authController.currentUser.value?.id;
      if (driverId == null) return;

      declinedTrips.add(trip.id);

      await firestore
          .collection('trip_requests')
          .doc('${trip.id}_$driverId')
          .delete();

      tripRequests.removeWhere((t) => t.id == trip.id);
    } catch (e) {
      logger.w('خطأ في رفض الرحلة: $e');
    }
  }

  Future<void> notifyArrival() async {
    try {
      if (currentTrip.value == null) return;

      await firestore.collection('trips').doc(currentTrip.value!.id).set({
        'status': TripStatus.driverArrived.name,
        'driverArrivedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (currentTrip.value != null) {
        currentTrip.value = currentTrip.value!.copyWith(
          status: TripStatus.driverArrived,
        );
        currentTrip.refresh();
      }

      Get.snackbar(
        'تم الإعلام',
        'تم إعلام الراكب بوصولك',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.w('خطأ في إعلام الوصول: $e');
    }
  }

  // هذه الدالة تبدو مكررة مع _startCurrentTripListener، يجب توحيدها
  void startTripListener(String tripId) {
    firestore.collection('trips').doc(tripId).snapshots().listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final status = data['status'];

      if (status == TripStatus.completed.name) {
        currentTrip.value = null;
        isOnTrip.value = false;
        isAvailable.value = true; // ✅ تأكد أن السائق متاح
        Get.offAllNamed(AppRoutes.RIDER_HOME); // ربما يجب أن يكون DRIVER_HOME
      }
    });
  }

 Future<void> _acceptTrip(TripModel trip) async {
    try {
      _isAcceptingTrip = true; // ✅ تفعيل الحماية
      
      final driverId = authController.currentUser.value?.id;
      if (driverId == null) {
        logger.e('❌ لا يوجد معرف سائق');
        _isAcceptingTrip = false;
        return;
      }

      final user = authController.currentUser.value;
      if (user == null) {
        logger.e('❌ لا توجد بيانات مستخدم');
        _isAcceptingTrip = false;
        return;
      }

      logger.i('🎯 بدء قبول الرحلة: ${trip.id}');

      // ✅ 1. جلب بيانات الراكب من Firebase
      UserModel? riderUser;
      if (trip.riderId != null && trip.riderId!.isNotEmpty) {
        riderUser = await authController.getUserById(trip.riderId!);
        logger.i('✅ تم جلب بيانات الراكب: ${riderUser?.name}');
      }

      // ✅ 2. إنشاء كائن السائق الكامل
      final UserModel driverUser = UserModel(
        id: driverId,
        name: user.name,
        phone: user.phone,
        profileImage: user.profileImage ?? '',
        email: user.email ?? '',
        rating: user.rating ?? 0.0,
        userType: UserType.driver,
        vehicleType: user.vehicleType,
        plateNumber: user.plateNumber,
        plateLetter: user.plateLetter,
        provinceCode: user.provinceCode,
        createdAt: DateTime.now(),
      );

      // ✅ 2. تحديث currentTrip محلياً قبل أي شيء
      final TripModel acceptedTrip = trip.copyWith(
        driverId: driverId,
        status: TripStatus.accepted,
        driver: driverUser,
        rider: riderUser, // ✅ إضافة بيانات الراكب
      );
      
      currentTrip.value = acceptedTrip;
      isOnTrip.value = true;
      isAvailable.value = false;
      
      logger.i('✅ تم تحديث currentTrip محلياً');
      logger.i('   Trip ID: ${acceptedTrip.id}');
      logger.i('   Driver: ${acceptedTrip.driver?.name}');
      logger.i('   Rider: ${acceptedTrip.rider?.name}'); // ✅ log للتأكد
      logger.i('   Status: ${acceptedTrip.status.name}');

      // ✅ 3. انتظار بسيط للتأكد من التحديث
      await Future.delayed(const Duration(milliseconds: 100));

      // ✅ 4. تحديث Firebase
      await firestore.collection('trips').doc(trip.id).set({
        'driverId': driverId,
        'status': TripStatus.accepted.name,
        'acceptedAt': FieldValue.serverTimestamp(),
        'driverName': user.name,
        'driverPhone': user.phone,
        'driverPhoto': user.profileImage ?? '',
        'driverEmail': user.email ?? '',
        'driverRating': user.rating ?? 0.0,
        'driverVehicleType': user.vehicleType?.name ?? 'غير محدد',
        'driverVehicleNumber':
            "${user.plateNumber ?? ''} ${user.plateLetter ?? ''} ${user.provinceCode ?? ''}".trim(),
        'driverLocation': {
          'lat': currentLocation.value?.latitude,
          'lng': currentLocation.value?.longitude,
        }
      }, SetOptions(merge: true));

      logger.i('✅ تم تحديث Firebase للرحلة');

      // ✅ 5. بدء الاستماع لتحديثات الرحلة
      _startCurrentTripListener(trip.id);
      
      // ✅ 6. إيقاف الاستماع لطلبات جديدة
      _stopListeningForRequests();

      // ✅ 7. الانتقال للصفحة
      logger.i('📍 الانتقال إلى صفحة التتبع...');
      await Get.offNamed(AppRoutes.DRIVER_TRIP_TRACKING);
      
      // ✅ إيقاف الحماية بعد ثانية من فتح الصفحة
      Future.delayed(const Duration(seconds: 1), () {
        _isAcceptingTrip = false;
        logger.i('✅ تم إيقاف حماية القبول');
      });
      
      logger.i('✅ تم قبول الرحلة بنجاح');
    } catch (e) {
      _isAcceptingTrip = false; // ✅ إيقاف عند الخطأ
      logger.e('❌ خطأ في _acceptTrip: $e');
      // إعادة تعيين الحالة عند الفشل
      currentTrip.value = null;
      isOnTrip.value = false;
      isAvailable.value = true;
      
      Get.snackbar(
        'خطأ',
        'فشل قبول الرحلة. حاول مرة أخرى',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> markAsArrived() async {
    try {
      if (currentTrip.value == null) return;

      final trip = currentTrip.value!;
      // final user = authController.currentUser.value; // غير مستخدم

      await firestore.collection('trips').doc(trip.id).set({
        'status': TripStatus.driverArrived.name,
        'driverArrivedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      Get.snackbar('وصلت', 'أُخبرنا الراكب');
    } catch (e) {
      logger.e('خطأ: $e');
    }
  }

  Future<void> startTrip(String tripId) async {
    try {
      if (tripId.isEmpty) return;

      // final user = authController.currentUser.value; // غير مستخدم

      await firestore.collection('trips').doc(tripId).set({
        'status': TripStatus.inProgress.name,
        'startedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      logger.e('خطأ: $e');
    }
  }

  Future<void> loadTripHistory() async {
    final driverId = authController.currentUser.value?.id;
    if (driverId == null) return;

    try {
      isLoadingHistory.value = true;

      QuerySnapshot querySnapshot = await firestore
          .collection('trips')
          .where('driverId', isEqualTo: driverId)
          .where('status',
              whereIn: [TripStatus.completed.name, TripStatus.cancelled.name])
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      tripHistory.clear();
      for (var doc in querySnapshot.docs) {
        try {
          TripModel trip =
              TripModel.fromMap(doc.data() as Map<String, dynamic>);
          tripHistory.add(trip);
        } catch (e) {
          logger.w('خطأ في تحويل بيانات الرحلة: $e');
        }
      }
    } catch (e) {
      logger.w('خطأ في تحميل تاريخ الرحلات: $e');
      Get.snackbar(
        'خطأ',
        'تعذر تحميل تاريخ الرحلات',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Map<String, dynamic> getDriverStatistics() {
    int completedTrips =
        tripHistory.where((trip) => trip.status == TripStatus.completed).length;

    int cancelledTrips =
        tripHistory.where((trip) => trip.status == TripStatus.cancelled).length;

    double totalEarnings = tripHistory
        .where((trip) => trip.status == TripStatus.completed)
        .fold(0.0, (sum, trip) => sum + (trip.fare * 0.8));

    double totalDistance = tripHistory
        .where((trip) => trip.status == TripStatus.completed)
        .fold(0.0, (sum, trip) => sum + trip.distance);

    return {
      'completedTrips': completedTrips,
      'cancelledTrips': cancelledTrips,
      'totalEarnings': totalEarnings,
      'totalDistance': totalDistance,
      'totalTrips': tripHistory.length,
      'rating': 4.5,
    };
  }

  Future<void> _removeAllTripRequests(String tripId) async {
    try {
      final requestsQuery = await firestore
          .collection('trip_requests')
          .where('tripId', isEqualTo: tripId)
          .get();

      final batch = firestore.batch();
      for (var doc in requestsQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      logger.i('✅ تم حذف ${requestsQuery.docs.length} طلب للرحلة $tripId');
    } catch (e) {
      logger.w('خطأ في حذف طلبات الرحلة: $e');
    }
  }

  Future<void> processCompletionWithPrice(String tripId, double finalPrice,
      double originalPrice, String paymentMethod) async {
    try {
      final priceDifference = finalPrice - originalPrice;
      const commissionPercentage = 0.20;
      final adminCommission = finalPrice * commissionPercentage;
      final driverEarnings = finalPrice - adminCommission;

      await firestore.collection('trips').doc(tripId).set({
        'status': TripStatus.completed.name,
        'completedAt': FieldValue.serverTimestamp(),
        'finalPrice': finalPrice,
        'originalPrice': originalPrice,
        'priceDifference': priceDifference,
        'adminCommission': adminCommission,
        'driverEarnings': driverEarnings,
        'paymentMethod': paymentMethod,
      }, SetOptions(merge: true));

      if (paymentMethod == 'cash') {
        await _addDriverDebt(
            authController.currentUser.value!.id, adminCommission);
        await _updateDriverEarnings(
            authController.currentUser.value!.id, driverEarnings);

        if (priceDifference < 0) {
          final refundAmount = priceDifference.abs();
          await _refundRider(currentTrip.value!.riderId!, refundAmount);
        }
      } else {
        await _processElectronicPayment(currentTrip.value!.riderId!, finalPrice,
            driverEarnings, adminCommission);

        if (priceDifference != 0) {
          await _handleElectronicPriceDifference(
              currentTrip.value!.riderId!, priceDifference);
        }
      }

      await _updateTripStatistics(finalPrice, driverEarnings);

      logger.i('✅ تم إكمال الرحلة بنجاح - السعر النهائي: $finalPrice د.ع');
    } catch (e) {
      logger.e('خطأ في معالجة إكمال الرحلة: $e');
      throw Exception('فشل في إكمال الرحلة: $e');
    }
  }

  Future<void> _addDriverDebt(String driverId, double amount) async {
    try {
      await firestore.collection('driver_debts').add({
        'driverId': driverId,
        'amount': amount,
        'type': 'trip_commission',
        'description': 'عمولة رحلة - دفع نقدي',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'tripId': currentTrip.value?.id,
      });

      await firestore.collection('users').doc(driverId).update({
        'additionalData.totalDebt': FieldValue.increment(amount),
      });
    } catch (e) {
      logger.w('خطأ في إضافة دين السائق: $e');
    }
  }

  Future<void> _updateDriverEarnings(String driverId, double earnings) async {
    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await firestore
          .collection('driver_earnings')
          .doc('${driverId}_$todayStr')
          .set({
        'driverId': driverId,
        'date': todayStr,
        'totalEarnings': FieldValue.increment(earnings),
        'tripsCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      todayEarnings.value += earnings;
      completedTripsToday.value += 1;
    } catch (e) {
      logger.w('خطأ في تحديث أرباح السائق: $e');
    }
  }

  Future<void> _refundRider(String riderId, double amount) async {
    try {
      await firestore.collection('users').doc(riderId).update({
        'balance': FieldValue.increment(amount),
      });

      await firestore.collection('transactions').add({
        'userId': riderId,
        'type': 'trip_refund',
        'amount': amount,
        'description': 'استرداد من رحلة - السعر النهائي أقل من المتوقع',
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'tripId': currentTrip.value?.id,
      });
    } catch (e) {
      logger.w('خطأ في استرداد المبلغ للراكب: $e');
    }
  }

  Future<void> _processElectronicPayment(String riderId, double totalAmount,
      double driverEarnings, double adminCommission) async {
    try {
      await firestore.collection('users').doc(riderId).update({
        'balance': FieldValue.increment(-totalAmount),
      });

      await authController.updateBalance(driverEarnings);

      await firestore.collection('admin_earnings').add({
        'amount': adminCommission,
        'source': 'trip_commission',
        'tripId': currentTrip.value?.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.w('خطأ في معالجة الدفع الإلكتروني: $e');
    }
  }

  Future<void> _handleElectronicPriceDifference(
      String riderId, double difference) async {
    try {
      if (difference > 0) {
        await firestore.collection('users').doc(riderId).update({
          'balance': FieldValue.increment(-difference),
        });

        await firestore.collection('transactions').add({
          'userId': riderId,
          'type': 'trip_extra_charge',
          'amount': -difference,
          'description': 'رسوم إضافية - السعر النهائي أعلى من المتوقع',
          'status': 'completed',
          'createdAt': FieldValue.serverTimestamp(),
          'tripId': currentTrip.value?.id,
        });
      } else {
        final refundAmount = difference.abs();
        await firestore.collection('users').doc(riderId).update({
          'balance': FieldValue.increment(refundAmount),
        });

        await firestore.collection('transactions').add({
          'userId': riderId,
          'type': 'trip_refund',
          'amount': refundAmount,
          'description': 'استرداد من رحلة - السعر النهائي أقل من المتوقع',
          'status': 'completed',
          'createdAt': FieldValue.serverTimestamp(),
          'tripId': currentTrip.value?.id,
        });
      }
    } catch (e) {
      logger.w('خطأ في معالجة فرق السعر: $e');
    }
  }

  Future<void> _updateTripStatistics(
      double finalPrice, double driverEarnings) async {
    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await firestore.collection('daily_statistics').doc(todayStr).set({
        'date': todayStr,
        'totalTrips': FieldValue.increment(1),
        'totalRevenue': FieldValue.increment(finalPrice),
        'totalDriverEarnings': FieldValue.increment(driverEarnings),
        'totalAdminEarnings': FieldValue.increment(finalPrice - driverEarnings),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      logger.w('خطأ في تحديث الإحصائيات: $e');
    }
  }

  void startListeningForRequests() {
    // ✅ تأكد من إلغاء الاشتراك السابق
    _tripRequestsSubscription?.cancel();
    _tripRequestsSubscription = null;

    final driverId = authController.currentUser.value?.id;
    if (driverId == null) {
      logger.w('⚠️ لا يمكن بدء الاستماع: معرف السائق غير موجود');
      return;
    }

    if (isOnTrip.value) {
      logger.i('🔇 السائق في رحلة، تم إيقاف الاستماع لطلبات جديدة');
      return;
    }

    if (!isOnline.value) {
      logger.i('🔇 السائق غير متصل، لن يتم الاستماع لطلبات جديدة');
      return;
    }

    logger.i('🎧 [${DateTime.now()}] بدء الاستماع لطلبات الرحلات للسائق: $driverId');
    logger.i('   📍 الحالة: متصل=${isOnline.value}, متاح=${isAvailable.value}, في رحلة=${isOnTrip.value}');

    try {
      _tripRequestsSubscription = firestore
          .collection('trip_requests')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'pending')
          .snapshots(includeMetadataChanges: true) // ✅ تجاهل التغييرات المحلية
          .listen(
        (snapshot) {
          if (snapshot.docs.isEmpty) {
            logger.d('📭 لا توجد طلبات حالياً');
          } else {
            logger.i('📨 [${DateTime.now()}] استلام ${snapshot.docs.length} طلب من Firestore');
          }
          _handleTripRequestsUpdate(snapshot);
        },
        onError: (error) {
          logger.e('❌ خطأ في الاستماع: $error');
          _tripRequestsSubscription?.cancel();
          _tripRequestsSubscription = null;
          
          // ✅ إعادة المحاولة بشكل ذكي
          Future.delayed(const Duration(seconds: 3), () {
            if (isOnline.value && !isOnTrip.value && _tripRequestsSubscription == null) {
              logger.i('🔄 إعادة محاولة الاستماع...');
              startListeningForRequests();
            }
          });
        },
        cancelOnError: false, // ✅ لا تلغي الاشتراك عند الخطأ
      );

      logger.i('✅ تم بدء الاستماع بنجاح');
    } catch (e) {
      logger.e('❌ فشل بدء الاستماع: $e');
    }
  }

  void _handleTripRequestsUpdate(QuerySnapshot snapshot) async {
    try {
      logger.i('📨 تم استلام ${snapshot.docs.length} طلب رحلة');

      final List<TripModel> newRequests = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final tripId = data['tripId'] as String;

          final expiresAt = data['expiresAt'] as Timestamp?;
          if (expiresAt != null &&
              expiresAt.toDate().isBefore(DateTime.now())) {
            logger.i('⏰ طلب منتهي الصلاحية: $tripId');

            doc.reference.delete();
            continue;
          }

          if (declinedTrips.contains(tripId)) {
            logger.i('❌ طلب مرفوض مسبقاً: $tripId');
            continue;
          }

          final tripDoc = await firestore.collection('trips').doc(tripId).get();
          if (!tripDoc.exists) {
            logger.w('⚠️ رحلة غير موجودة: $tripId');
            continue;
          }

          final tripData = tripDoc.data() as Map<String, dynamic>;

          if (tripData['status'] != 'pending') {
            logger.i('✅ رحلة تم قبولها أو إلغاؤها: $tripId');

            doc.reference.delete();
            continue;
          }

          // ✅ إضافة riderType من tripDetails لو موجود
          final tripDetails = data['tripDetails'] as Map<String, dynamic>?;
          if (tripDetails != null && tripDetails['riderType'] != null) {
            tripData['riderType'] = tripDetails['riderType'];
          }
          
          final trip = TripModel.fromMap(tripData);
          newRequests.add(trip);

          logger.i(
              '✨ طلب رحلة صالح: ${trip.id} - من ${trip.pickupLocation.address} إلى ${trip.destinationLocation.address}');
        } catch (e) {
          logger.w('خطأ في معالجة طلب رحلة: $e');
        }
      }

      _updateTripRequestsList(newRequests);
    } catch (e) {
      logger.e('خطأ في معالجة تحديثات طلبات الرحلات: $e');
    }
  }

  void handleTripNotification(TripModel trip) {
    _showNewTripRequestNotification(1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute != AppRoutes.DRIVER_HOME) {
        Get.toNamed(AppRoutes.DRIVER_HOME, arguments: {'tripId': trip.id});
      }
    });
  }

  void _updateTripRequestsList(List<TripModel> newRequests) {
    tripRequests.clear();

    for (var trip in newRequests) {
      if (!tripRequests.any((existingTrip) => existingTrip.id == trip.id)) {
        tripRequests.add(trip);
      }
    }

    logger.i('📋 عدد طلبات الرحلات الحالية: ${tripRequests.length}');

    if (tripRequests.isNotEmpty &&
        isOnline.value &&
        isAvailable.value &&
        !isOnTrip.value) {
      handleTripNotification(tripRequests.last);
    }
  }

  void _showNewTripRequestNotification(int count) {
    final now = DateTime.now();
    DateTime? lastNotificationTime;

    // منع التكرار السريع
    if (lastNotificationTime != null &&
        now.difference(lastNotificationTime).inSeconds < 5) {
      return;
    }
    lastNotificationTime = now;

    // عرض Snackbar إذا التطبيق في foreground
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        '🚗 طلب رحلة جديد!',
        count == 1 ? 'لديك طلب رحلة جديد' : 'لديك $count طلبات رحلة جديدة',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.directions_car, color: Colors.white),
        shouldIconPulse: true,
        onTap: (_) => Get.offAllNamed('/driverHome'), // فتح الهوم عند الضغط
      );
    }

    // تشغيل الصوت
    Future.microtask(() async {
      try {
        final player = AudioPlayer();
        await player.play(AssetSource('sounds/message.mp3'));
        logger.w('🔊 تم تشغيل صوت الإشعار');
      } catch (e) {
        logger.w('⚠️ خطأ أثناء تشغيل الصوت: $e');
      }
    });
  }

  Future<void> acceptTripRequest(TripModel trip) async {
    try {
      if (!canAcceptTrip(trip)) {
        return;
      }

      logger.i('✅ قبول طلب الرحلة: ${trip.id}');

      final driverId = authController.currentUser.value?.id;
      if (driverId == null) throw Exception('معرف السائق غير متوفر');
      final user = authController.currentUser.value; // هذا هو السائق الحالي
      await firestore.collection('trips').doc(trip.id).set({
        'driverId': driverId,
        'status': TripStatus.accepted.name,
        'acceptedAt': FieldValue.serverTimestamp(),
        'driverName': user?.name, // <--- هذا مهم جداً
        'driverPhone': user?.phone,
        'driverPhoto': user?.profileImage,
        'driverEmail': user?.email,
        'driverRating': user?.rating,
        'driverVehicleType': user?.vehicleType!.name,
        'driverVehicleNumber':
            "${user?.plateNumber} ${user?.plateLetter} ${user?.provinceCode}",
        'driverLocation': {
          'lat': currentLocation.value?.latitude,
          'lng': currentLocation.value?.longitude,
        }
      }, SetOptions(merge: true));
      await _removeAllTripRequests(trip.id);

      await firestore.collection('users').doc(driverId).set({
        'additionalData': {
          'isAvailable': false,
          'currentTripId': trip.id,
        }
      }, SetOptions(merge: true));

      currentTrip.value = trip.copyWith(
        driverId: driverId,
        status: TripStatus.accepted,
        acceptedAt: DateTime.now(),
        driver: UserModel(
          id: driverId,
          name: authController.currentUser.value?.name ?? 'السائق',
          phone: authController.currentUser.value?.phone ?? '',
          email: authController.currentUser.value?.email ?? '',
          userType: UserType.driver,
          createdAt:
              authController.currentUser.value?.createdAt ?? DateTime.now(),
        ),
      );

      isOnTrip.value = true;
      isAvailable.value = false;
      tripRequests.clear();
      _stopListeningForRequests(); // توقف عن الاستماع لطلبات جديدة بمجرد قبول رحلة

      _startCurrentTripListener(trip.id);

      Get.offNamed(AppRoutes.DRIVER_TRIP_TRACKING, arguments: trip);

      Get.snackbar(
        '✅ تم قبول الرحلة',
        'تم قبول الرحلة بنجاح، توجه إلى نقطة الالتقاء',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      logger.e('خطأ في قبول الرحلة: $e');
      Get.snackbar(
        'خطأ',
        'تعذر قبول الرحلة: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> declineTripRequest(TripModel trip) async {
    try {
      logger.i('❌ رفض طلب الرحلة: ${trip.id}');

      final driverId = authController.currentUser.value?.id;
      if (driverId == null) return;

      declinedTrips.add(trip.id);

      tripRequests.removeWhere((t) => t.id == trip.id);

      await firestore
          .collection('trip_requests')
          .doc('${trip.id}_$driverId')
          .delete();

      logger.i('✅ تم رفض الطلب وحذفه من القائمة');
    } catch (e) {
      logger.w('خطأ في رفض الرحلة: $e');
    }
  }

  bool _isAcceptingTrip = false; // ✅ Flag لمنع race condition

  void _startCurrentTripListener(String tripId) {
    _currentTripSubscription?.cancel();
    logger.i('🎧 بدء الاستماع لتحديثات الرحلة: $tripId');

    _currentTripSubscription = firestore
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .listen((snapshot) async {
      // ✅ تجاهل أي تحديثات أثناء عملية القبول
      if (_isAcceptingTrip) {
        logger.d('⚠️ تجاهل التحديث أثناء عملية القبول');
        return;
      }
      
      if (!snapshot.exists) {
        logger.w('الرحلة $tripId حُذفت، جاري تنظيف الحالة...');
        _clearCurrentTripState();
        return;
      }

      final data = snapshot.data()!;
      TripModel updatedTrip = TripModel.fromMap(data);

      // ✅ جلب بيانات الراكب والسائق عند كل تحديث للرحلة
      if (updatedTrip.riderId != null &&
          updatedTrip.riderId!.isNotEmpty &&
          updatedTrip.rider == null) {
        UserModel? fetchedRider =
            await authController.getUserById(updatedTrip.riderId!);
        if (fetchedRider != null) {
          updatedTrip = updatedTrip.copyWith(rider: fetchedRider);
          logger.d('Updated trip with fetched rider: ${fetchedRider.name}');
        }
      }

      if (updatedTrip.driverId != null &&
          updatedTrip.driverId!.isNotEmpty &&
          updatedTrip.driver == null) {
        UserModel? fetchedDriver =
            await authController.getUserById(updatedTrip.driverId!);
        if (fetchedDriver != null) {
          updatedTrip = updatedTrip.copyWith(driver: fetchedDriver);
          logger.d('Updated trip with fetched driver: ${fetchedDriver.name}');
        }
      }

      // تحديث Rx<TripModel?>
      currentTrip.value = updatedTrip;
      isOnTrip.value = updatedTrip.isActive;

      logger.i(
          '✅ تم تحديث حالة الرحلة في DriverController: ${updatedTrip.status.name}');

      // ✅ معالجة حالة الإلغاء فقط (ليس completed)
      if (updatedTrip.status == TripStatus.cancelled && !isEndingTrip.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.currentRoute == AppRoutes.DRIVER_TRIP_TRACKING) {
            Get.offAllNamed(AppRoutes.DRIVER_HOME);
            Get.snackbar(
              'تم الإلغاء',
              'الراكب ألغى الرحلة',
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );

            // ✅ إعادة تفعيل الاستماع بعد الإلغاء
            if (isOnline.value) {
              isAvailable.value = true;
              startListeningForRequests();
              startLocationUpdates();
            }
          }
        });
        _clearCurrentTripState();
      }

      // ❌ لا نعالج completed هنا نهائياً - endTrip() هي المسؤولة
    }, onError: (error) {
      logger.e('خطأ في الاستماع لتحديثات الرحلة: $error');
      _clearCurrentTripState();
    });
  }

  Future<void> loadPendingDebt() async {
    try {
      final userId = authController.currentUser.value?.id;
      if (userId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('driver_debts')
          .where('driverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      double totalDebt = 0.0;
      for (var doc in snapshot.docs) {
        totalDebt += (doc.data()['amount'] as num).toDouble();
      }

      pendingDebt.value = totalDebt;
    } catch (e) {
      logger.w('خطأ في تحميل الديون: $e');
    }
  }

  bool canCompleteTrip(TripModel trip, String paymentMethod) {
    final currentBalance = authController.currentUser.value?.balance ?? 0.0;
    final tripFare = trip.fare;

    if (paymentMethod == 'cash') {
      return true;
    } else {
      return currentBalance >= tripFare;
    }
  }

  Map<String, bool> getAvailablePaymentMethods(TripModel trip) {
    final currentBalance = authController.currentUser.value?.balance ?? 0.0;
    final tripFare = trip.fare;

    return {
      'cash': true,
      'app': currentBalance >= tripFare,
    };
  }

  Future<void> completeTripWithPayment(
      TripModel trip, String paymentMethod) async {
    try {
      final tripFare = trip.fare;
      final driverShare = tripFare * 0.8;
      final appCommission = tripFare * 0.2;

      if (paymentMethod == 'cash') {
        await _addAppCommissionDebt(trip.driverId!, appCommission);
        await _updateTripStatus(trip.id, 'completed', paymentMethod);

        Get.snackbar(
          'تم إكمال الرحلة',
          'رحلة نقدية - يرجى تحصيل ${tripFare.toStringAsFixed(2)} د.ع من الراكب\nعمولة التطبيق: ${appCommission.toStringAsFixed(2)} د.ع',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        final currentBalance = authController.currentUser.value?.balance ?? 0.0;

        if (currentBalance >= tripFare) {
          // يتم خصم إجمالي قيمة الرحلة من الراكب (هذا يحدث عادة من جانب الراكب)
          // السائق يحصل على حصته مباشرة في رصيده
          // عمولة التطبيق يتم خصمها من رصيد الراكب أو تعتبر "أرباح" للمنصة
          // هنا نفترض أن رصيد السائق يزداد بحصته
          // (يجب أن يتم تعديل هذا المنطق ليعكس كيفية معالجة المدفوعات في Firebase بشكل دقيق)

          // تحديث رصيد السائق بإضافة حصته من الرحلة
          await authController.updateBalance(driverShare);

          // تسجيل المعاملات
          // يفترض أن هناك آلية لخصم من رصيد الراكب بالفعل
          // هنا نسجل فقط أن السائق حصل على أرباح
          await _recordPaymentTransaction(
              trip.driverId!, driverShare, 'driver_earning', 'أرباح رحلة');

          await _updateTripStatus(trip.id, 'completed', paymentMethod);

          Get.snackbar(
            'تم إكمال الرحلة',
            'تم إضافة ${driverShare.toStringAsFixed(2)} د.ع كأرباح إلى محفظتك',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          throw Exception('الرصيد غير كافٍ للدفع عبر التطبيق');
        }
      }

      await loadEarningsData();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء إكمال الرحلة: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _addAppCommissionDebt(String driverId, double commission) async {
    try {
      await FirebaseFirestore.instance.collection('driver_debts').add({
        'driverId': driverId,
        'amount': commission,
        'type': 'app_commission',
        'description': 'عمولة تطبيق - رحلة نقدية',
        'status': 'pending',
        'createdAt': DateTime.now(),
      });
      // تحديث إجمالي الدين في وثيقة السائق
      await firestore.collection('users').doc(driverId).update({
        'additionalData.totalDebt': FieldValue.increment(commission),
      });
    } catch (e) {
      logger.w('خطأ في إضافة دين العمولة: $e');
    }
  }

  Future<void> _recordPaymentTransaction(
      String userId, double amount, String type, String description) async {
    try {
      await FirebaseFirestore.instance.collection('payments').add({
        'userId': userId,
        'amount': amount,
        'type': type,
        'description': description,
        'method': amount > 0 ? 'wallet_credit' : 'wallet_debit',
        'status': 'completed',
        'createdAt': DateTime.now(),
      });
    } catch (e) {
      logger.w('خطأ في تسجيل المعاملة: $e');
    }
  }

  Future<void> _updateTripStatus(
      String tripId, String status, String paymentMethod) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).set({
        'status': status,
        'paymentMethod': paymentMethod,
        'completedAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      logger.w('خطأ في تحديث حالة الرحلة: $e');
    }
  }

  void showTripCompletionDialog(TripModel trip) {
    final paymentMethod = RxString('cash');

    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('إكمال الرحلة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('قيمة الرحلة: ${trip.fare.toStringAsFixed(2)} د.ع'),
            Text('حصة السائق: ${(trip.fare * 0.8).toStringAsFixed(2)} د.ع'),
            Text('عمولة التطبيق: ${(trip.fare * 0.2).toStringAsFixed(2)} د.ع'),
            const SizedBox(height: 16),
            const Text('طريقة الدفع:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(() => Column(
                  children: [
                    RadioListTile<String>(
                      title: const Row(
                        children: [
                          Icon(Icons.payments, size: 20),
                          SizedBox(width: 8),
                          Text('نقدي'),
                        ],
                      ),
                      subtitle:
                          const Text('السائق يحصل على المال من الراكب مباشرة'),
                      value: 'cash',
                      groupValue: paymentMethod.value,
                      onChanged: (value) => paymentMethod.value = value!,
                      dense: true,
                    ),
                    RadioListTile<String>(
                      title: const Row(
                        children: [
                          Icon(Icons.account_balance_wallet, size: 20),
                          SizedBox(width: 8),
                          Text('عبر التطبيق'),
                        ],
                      ),
                      subtitle: const Text('يتم الدفع من محفظة الراكب'),
                      value: 'app',
                      groupValue: paymentMethod.value,
                      onChanged: (value) {
                        final currentBalance =
                            authController.currentUser.value?.balance ?? 0.0;
                        if (currentBalance >= trip.fare) {
                          paymentMethod.value = value!;
                        } else {
                          Get.snackbar(
                            'رصيد غير كافٍ',
                            'الرصيد الحالي ${currentBalance.toStringAsFixed(2)} د.ع غير كافٍ للدفع من محفظة الراكب',
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                        }
                      },
                      dense: true,
                    ),
                  ],
                )),
            Obx(() => paymentMethod.value == 'cash'
                ? Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      border: Border.all(color: Colors.amber.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info,
                            color: Colors.amber.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تأكد من تحصيل المبلغ من الراكب نقداً',
                            style: TextStyle(
                              color: Colors.amber.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await completeTripWithPayment(trip, paymentMethod.value);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('إكمال الرحلة'),
          ),
        ],
      ),
    );
  }

  Future<void> markDriverArrived(String tripId) async {
    try {
      await firestore.collection('trips').doc(tripId).set({
        'status': 'driverArrived',
        'driverArrivedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (currentTrip.value != null) {
        currentTrip.value = currentTrip.value!.copyWith(
          status: TripStatus.driverArrived,
        );
        currentTrip.refresh();
      }

      Get.snackbar(
        'تم الوصول',
        'تم إعلام الراكب بوصولك.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تحديث الحالة: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  void _startAutoTripCancellation() {
    _autoCancelTimer?.cancel();
    _autoCancelTimer = Timer.periodic(const Duration(minutes: 10), (_) async {
      if (currentTrip.value != null) {
        final trip = currentTrip.value!;
        if (trip.status != TripStatus.driverArrived &&
            trip.status != TripStatus.inProgress) {
          final elapsed = DateTime.now().difference(trip.createdAt);
          if (elapsed.inMinutes >= 30) {
            logger.w('⚠️ إلغاء رحلة متعلقة بعد 1/2 ساعات');
            await firestore.collection('trips').doc(trip.id).update({
              'status': TripStatus.cancelled.name,
              'cancelledAt': FieldValue.serverTimestamp(),
              'cancelReason': 'auto_cancelled_timeout'
            });
            _clearCurrentTripState();
          }
        }
      }
    });
  }

  /// ✅ تنظيف شامل لجميع ماركرات الرحلة بعد الانتهاء (سائق)
  void _cleanupDriverMarkersAfterTripEnd() {
    logger.i('🧹 [سائق] بدء تنظيف ماركرات الرحلة بعد الانتهاء...');
    
    if (Get.isRegistered<MyMapController>()) {
      final mapCtrl = Get.find<MyMapController>();
      
      // ✅ مسح جميع ماركرات الرحلة
      mapCtrl.clearTripMarkers();
      
      // ✅ مسح polylines
      mapCtrl.polylines.clear();
      
      // ✅ إعادة إضافة ماركر السيارة فقط
      if (currentLocation.value != null) {
        mapCtrl.updateDriverLocationMarker(
          currentLocation.value!,
          bearing: 0.0,
        );
      }
      
      logger.i('✅ [سائق] تم تنظيف جميع ماركرات الرحلة');
    }
    
    // ✅ الرجوع للهوم فوراً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute != AppRoutes.DRIVER_HOME) {
        Get.offAllNamed(AppRoutes.DRIVER_HOME);
        logger.i('➡️ [سائق] تم الرجوع للهوم');
      }
    });
  }

  @override
  void onClose() {
    _tripRequestsSubscription?.cancel();
    _currentTripSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _cleanupTimer?.cancel();
    _autoCancelTimer?.cancel();
    super.onClose();
  }
}
