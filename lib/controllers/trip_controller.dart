import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/controllers/map_controller.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/location_service.dart';
import 'package:transport_app/services/app_settings_service.dart';
import 'package:transport_app/controllers/auth_controller.dart';

class TripController extends GetxController {
  static TripController get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current trip state
  final Rx<TripModel?> activeTrip = Rx<TripModel?>(null);
  final RxBool hasActiveTrip = false.obs;
  final RxBool isRequestingTrip = false.obs;
  final Rx<DateTime?> activeSearchUntil = Rx<DateTime?>(null);
  final RxInt remainingSearchSeconds = 0.obs;

  // Trip history
  final RxList<TripModel> tripHistory = <TripModel>[].obs;
  final RxBool isLoadingHistory = false.obs;

  // Available drivers
  final RxList<DriverModel> availableDrivers = <DriverModel>[].obs;

  // Real-time updates
  StreamSubscription<DocumentSnapshot>? _tripStreamSubscription;
  StreamSubscription<QuerySnapshot>? _driversStreamSubscription;
  Timer? _tripTimeoutTimer;
  Timer? _searchCountdownTimer;

  // Controllers
  final AuthController authController = AuthController.to;
  final LocationService locationService = LocationService.to;
  final AppSettingsService appSettingsService = AppSettingsService.to;

  @override
  void onInit() {
    super.onInit();
    _initializeTripController();
  }

  /// تهيئة متحكم الرحلات
  void _initializeTripController() {
    // تحقق من وجود رحلة نشطة عند فتح التطبيق
    _checkActiveTrip();

    // الاستماع للسائقين المتاحين
    _listenToAvailableDrivers();

    // تحديث حالة الرحلة النشطة
    ever(activeTrip, (TripModel? trip) {
      hasActiveTrip.value = trip != null && trip.isActive;

      if (trip != null && trip.isActive) {
        _startTripTracking(trip);
      }
    });
  }

  /// التحقق من وجود رحلة نشطة
  Future<void> _checkActiveTrip() async {
    try {
      final user = authController.currentUser.value;
      if (user == null) return;

      QuerySnapshot querySnapshot = await _firestore
          .collection('trips')
          .where('riderId', isEqualTo: user.id)
          .where('status',
              whereIn: ['pending', 'accepted', 'driverArrived', 'inProgress'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        TripModel trip = TripModel.fromMap(
            querySnapshot.docs.first.data() as Map<String, dynamic>);
        activeTrip.value = trip;
        _listenToTripUpdates(trip.id);
      }
    } catch (e) {
      logger.w('خطأ في التحقق من الرحلة النشطة: $e');
    }
  }

  /// الاستماع للسائقين المتاحين
  void _listenToAvailableDrivers() {
    _driversStreamSubscription = _firestore
        .collection('users')
        .where('userType', isEqualTo: 'driver')
        .where('additionalData.isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      availableDrivers.clear();
      for (var doc in snapshot.docs) {
        try {
          DriverModel driver = DriverModel.fromMap(doc.data());
          availableDrivers.add(driver);
        } catch (e) {
          logger.w('خطأ في تحويل بيانات السائق: $e');
        }
      }
    });
  }

  /// طلب رحلة جديدة
  Future<void> requestTrip({
    required LocationPoint pickup,
    required LocationPoint destination,
  }) async {
    try {
      if (isRequestingTrip.value) return; // ✅ منع أي استدعاء إضافي
isRequestingTrip.value = true;
      // منع تكرار إنشاء رحلتين إذا كانت هناك رحلة نشطة قيد الانتظار
      if (hasActiveTrip.value &&
          activeTrip.value != null &&
          activeTrip.value!.status == TripStatus.pending) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // تأكد من الذهاب لصفحة البحث إن لم يكن هناك تنقل سابق
          if (Get.currentRoute != AppRoutes.RIDER_SEARCHING) {
            Get.toNamed(AppRoutes.RIDER_SEARCHING, arguments: {
              'pickup': activeTrip.value!.pickupLocation,
              'destination': activeTrip.value!.destinationLocation,
              'estimatedFare': activeTrip.value!.fare,
              'estimatedDuration': activeTrip.value!.estimatedDuration,
            });
          }
        });
        return;
      }

      isRequestingTrip.value = true;

      // التحقق من الرصيد
      final user = authController.currentUser.value;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      // حساب المسافة والتكلفة
      double distance = locationService.calculateDistance(
        pickup.latLng,
        destination.latLng,
      );

      int estimatedDuration = locationService.estimateDuration(distance);
      double fare = _calculateFare(distance);

      // التحقق من كفاية الرصيد
      if (user.balance < fare) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'رصيد غير كافي',
            'يرجى شحن المحفظة أولاً',
            snackPosition: SnackPosition.BOTTOM,
          );
          // Get.toNamed(AppRoutes.RIDER_ADD_BALANCE);
          Get.toNamed(AppRoutes.RIDER_WALLET);
        });
        return;
      }

      // الحصول على مسار الرحلة
      List<LatLng> routePoints = await locationService.getRoute(
        pickup.latLng,
        destination.latLng,
      );

      // إنشاء الرحلة
      String tripId = _firestore.collection('trips').doc().id;

      TripModel newTrip = TripModel(
        id: tripId,
        riderId: user.id,
        pickupLocation: pickup,
        destinationLocation: destination,
        fare: fare,
        distance: distance,
        estimatedDuration: estimatedDuration,
        createdAt: DateTime.now(),
        routePolyline: routePoints,
      );

      // حفظ الرحلة في قاعدة البيانات
      await _firestore.collection('trips').doc(tripId).set(newTrip.toMap());
if (authController.mockMode.value) {
  await AuthController.to.simulateTripFlow(user.id);
}

      // تحديث الحالة المحلية
      activeTrip.value = newTrip;

      // بدء الاستماع لتحديثات الرحلة
      _listenToTripUpdates(tripId);

      // الانتقال لشاشة البحث أولاً
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.toNamed(AppRoutes.RIDER_SEARCHING, arguments: {
          'pickup': pickup,
          'destination': destination,
          'estimatedFare': fare,
          'estimatedDuration': estimatedDuration,
        });
      });

      // إشعار السائقين المتاحين بعد الانتقال
    //  WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _notifyAvailableDrivers(newTrip);
    //  });

      // بدء عداد زمني لإلغاء الرحلة تلقائياً إذا لم يتم قبولها
      _startTripTimeoutTimer(newTrip);

      // بدء عدّاد مرئي 5 دقائق
      _startSearchCountdown(const Duration(minutes: 5));
    } catch (e) {
      logger.w('خطأ في طلب الرحلة: $e');
      if (activeTrip.value == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'خطأ',
            'تعذر طلب الرحلة، يرجى المحاولة مرة أخرى',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        });
      }
    } finally {
      isRequestingTrip.value = false;
    }
  }

  /// حساب تكلفة الرحلة
  double _calculateFare(double distanceKm) {
    // استخدام إعدادات التطبيق لحساب السعر
    return appSettingsService.calculateFare(distanceKm, null);
  }

  /// إشعار السائقين المتاحين
  Future<void> _notifyAvailableDrivers(TripModel trip) async {
    try {
      // جلب السائقين المتصلين مباشرة من Firestore (ديناميكياً)
      QuerySnapshot driversSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .where('additionalData.isOnline', isEqualTo: true)
          .get();

      // نصف قطر البحث عن السائقين بالكيلومتر (يمكن لاحقاً سحبه من AppSettings)
      const double searchRadiusKm = 5.0;

      // حساب المسافة وترشيح السائقين القريبين
      final List<({DriverModel driver, double distanceKm})> candidates = [];
      for (var doc in driversSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final DriverModel driver = DriverModel.fromMap(data);
          if (driver.currentLat != null && driver.currentLng != null) {
            final LatLng driverLoc =
                LatLng(driver.currentLat!, driver.currentLng!);
            final double distanceKm = locationService.calculateDistance(
                trip.pickupLocation.latLng, driverLoc);
            if (distanceKm <= searchRadiusKm) {
              candidates.add((driver: driver, distanceKm: distanceKm));
            }
          }
        } catch (_) {}
      }

      // ترتيب حسب الأقرب
      candidates.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      if (candidates.isEmpty) {
        logger.i('لا يوجد سائقون قريبون ضمن $searchRadiusKm كم');
        return;
      }

      // إرسال طلبات للسائقين الأقرب أولاً (مثلاً أول 10)
      final int maxDrivers = candidates.length < 10 ? candidates.length : 10;
      for (int i = 0; i < maxDrivers; i++) {
        final driver = candidates[i].driver;
        await _firestore
            .collection('trip_requests')
            .doc('${trip.id}_${driver.id}')
            .set({
          'tripId': trip.id,
          'driverId': driver.id,
          'riderId': trip.riderId,
          'status': 'pending',
          'createdAt': Timestamp.now(),
          'expiresAt': Timestamp.fromDate(
              DateTime.now().add(const Duration(seconds: 30))),
        });
      }
    } catch (e) {
      logger.w('خطأ في إشعار السائقين: $e');
    }
  }

  /// بدء عداد إلغاء الرحلة التلقائي
  void _startTripTimeoutTimer(TripModel trip) {
    _tripTimeoutTimer?.cancel();

    _tripTimeoutTimer = Timer(const Duration(minutes: 5), () {
      if (activeTrip.value?.id == trip.id &&
          activeTrip.value?.status == TripStatus.pending) {
        _cancelTripTimeout();
      }
    });
  }

  void _startSearchCountdown(Duration total) {
    _searchCountdownTimer?.cancel();
    final end = DateTime.now().add(total);
    activeSearchUntil.value = end;
    remainingSearchSeconds.value = total.inSeconds;

    _searchCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final now = DateTime.now();
      if (activeSearchUntil.value == null) {
        t.cancel();
        remainingSearchSeconds.value = 0;
        return;
      }
      final diff = activeSearchUntil.value!.difference(now).inSeconds;
      if (diff <= 0) {
        t.cancel();
        remainingSearchSeconds.value = 0;
      } else {
        remainingSearchSeconds.value = diff;
      }
    });
  }

  void _stopSearchCountdown() {
    _searchCountdownTimer?.cancel();
    _searchCountdownTimer = null;
    remainingSearchSeconds.value = 0;
    activeSearchUntil.value = null;
  }

  /// إلغاء الرحلة بسبب انتهاء الوقت
  Future<void> _cancelTripTimeout() async {
    try {
      if (activeTrip.value != null) {
        await _firestore.collection('trips').doc(activeTrip.value!.id).update({
          'status': TripStatus.cancelled.name,
          'completedAt': Timestamp.now(),
          'notes': 'تم الإلغاء تلقائياً - لم يتم العثور على سائق متاح',
        });

        Get.snackbar(
          'تم إلغاء الرحلة',
          'لم يتم العثور على سائق متاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        // عند انتهاء المهلة: نظّف وابعد المستخدم للواجهة الرئيسية
        _stopSearchCountdown();
        Get.offAllNamed(AppRoutes.RIDER_HOME);
      }
    } catch (e) {
      logger.w('خطأ في إلغاء الرحلة التلقائي: $e');
    }
  }

  /// الاستماع لتحديثات الرحلة
  void _listenToTripUpdates(String tripId) {
    _tripStreamSubscription?.cancel();

    _tripStreamSubscription = _firestore
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        TripModel updatedTrip =
            TripModel.fromMap(snapshot.data() as Map<String, dynamic>);
        activeTrip.value = updatedTrip;

        // إلغاء العداد الزمني إذا تم قبول الرحلة
        if (updatedTrip.status != TripStatus.pending) {
          _tripTimeoutTimer?.cancel();
        }

        // التعامل مع تغيير الحالة
        _handleTripStatusChange(updatedTrip);
      } else {
        // تم حذف الرحلة
        _clearActiveTrip();
      }
    });
  }

  /// التعامل مع تغيير حالة الرحلة
  void _handleTripStatusChange(TripModel trip) {
    switch (trip.status) {
      case TripStatus.accepted:
        Get.snackbar(
          'تم قبول الرحلة',
          'السائق في الطريق إليك',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        break;

      case TripStatus.driverArrived:
        Get.snackbar(
          'وصل السائق',
          'السائق وصل إلى موقعك',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
        break;

      case TripStatus.inProgress:
        Get.snackbar(
          'بدأت الرحلة',
          'جاري التوجه إلى الوجهة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.purple,
          colorText: Colors.white,
        );
        break;

      case TripStatus.completed:
        _handleTripCompleted(trip);
        break;

      case TripStatus.cancelled:
        _handleTripCancelled(trip);
        break;

      default:
        break;
    }
  }

  /// التعامل مع إنهاء الرحلة
  void _handleTripCompleted(TripModel trip) {
    // خصم التكلفة من رصيد المستخدم
    authController.updateBalance(-trip.fare);

    Get.snackbar(
      'تمت الرحلة',
      'وصلت بأمان إلى وجهتك',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    _clearActiveTrip();

    // إضافة الرحلة إلى التاريخ
    tripHistory.insert(0, trip);
  }

  /// التعامل مع إلغاء الرحلة
  void _handleTripCancelled(TripModel trip) {
    Get.snackbar(
      'تم إلغاء الرحلة',
      trip.notes ?? 'تم إلغاء الرحلة',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );

    _clearActiveTrip();

    // إضافة الرحلة إلى التاريخ
    tripHistory.insert(0, trip);
  }

  /// بدء تتبع الرحلة
  void _startTripTracking(TripModel trip) {
    if (trip.driverId != null) {
      // الاستماع لموقع السائق
      _listenToDriverLocation(trip.driverId!);
    }
  }

  /// الاستماع لموقع السائق
  void _listenToDriverLocation(String driverId) {
    _firestore.collection('users').doc(driverId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        try {
          DriverModel driver = DriverModel.fromMap(snapshot.data()!);
          if (driver.currentLat != null && driver.currentLng != null) {
            LatLng driverLocation =
                LatLng(driver.currentLat!, driver.currentLng!);
            // تحديث موقع السائق على الخريطة
            Get.find<MapControllerr>().updateDriverLocation(driverLocation);
          }
        } catch (e) {
          logger.w('خطأ في تحديث موقع السائق: $e');
        }
      }
    });
  }

  /// إلغاء الرحلة
  Future<void> cancelTrip() async {
    final trip = activeTrip.value;
    if (trip == null) return;

    try {
      // يمكن إلغاء الرحلة فقط إذا كانت في حالة الانتظار
      if (trip.status != TripStatus.pending) {
        Get.snackbar(
          'لا يمكن الإلغاء',
          'لا يمكن إلغاء الرحلة في هذه المرحلة',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // تحديث حالة الرحلة إلى ملغاة
      await _firestore.collection('trips').doc(trip.id).update({
        'status': TripStatus.cancelled.name,
        'completedAt': Timestamp.now(),
        'notes': 'تم الإلغاء من قبل الراكب',
      });

      // مسح الحالة المحلية
      _clearActiveTrip();
      _stopSearchCountdown(); // إذا ألغى الراكب بنفسه

      // Get.snackbar(
      //   'تم الإلغاء',
      //   'تم إلغاء الرحلة بنجاح',
      //   snackPosition: SnackPosition.BOTTOM,
      // );
      Get.offAllNamed(AppRoutes.RIDER_HOME);
    } catch (e) {
      logger.w('خطأ في إلغاء الرحلة: $e');
      Get.snackbar(
        'خطأ',
        'تعذر إلغاء الرحلة، يرجى المحاولة مرة أخرى',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// تحميل تاريخ الرحلات
  Future<void> loadTripHistory() async {
    final user = authController.currentUser.value;
    if (user == null) return;

    try {
      isLoadingHistory.value = true;

      QuerySnapshot querySnapshot = await _firestore
          .collection('trips')
          .where('riderId', isEqualTo: user.id)
          .where('status', whereIn: ['completed', 'cancelled'])
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
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingHistory.value = false;
    }
  }

  /// مسح الرحلة النشطة
  void _clearActiveTrip() {
    _tripStreamSubscription?.cancel();
    _tripTimeoutTimer?.cancel();
    activeTrip.value = null;
    hasActiveTrip.value = false;

    // مسح الخريطة
    Get.find<MapControllerr>().clearMap();
  }

  /// تقييم الرحلة
  Future<void> rateTrip(String tripId, double rating, String? comment) async {
    try {
      await _firestore.collection('trip_ratings').doc(tripId).set({
        'tripId': tripId,
        'riderId': authController.currentUser.value?.id,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.now(),
      });

      Get.snackbar(
        'شكراً لك',
        'تم إرسال التقييم بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.w('خطأ في إرسال التقييم: $e');
      Get.snackbar(
        'خطأ',
        'تعذر إرسال التقييم',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// البحث عن رحلة بالمعرف
  Future<TripModel?> getTripById(String tripId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('trips').doc(tripId).get();

      if (doc.exists) {
        return TripModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      logger.w('خطأ في البحث عن الرحلة: $e');
      return null;
    }
  }

  /// حساب إحصائيات الرحلات
  Map<String, dynamic> getTripStatistics() {
    int completedTrips =
        tripHistory.where((trip) => trip.status == TripStatus.completed).length;

    int cancelledTrips =
        tripHistory.where((trip) => trip.status == TripStatus.cancelled).length;

    double totalSpent = tripHistory
        .where((trip) => trip.status == TripStatus.completed)
        .fold(0.0, (sum, trip) => sum + trip.fare);

    double totalDistance = tripHistory
        .where((trip) => trip.status == TripStatus.completed)
        .fold(0.0, (sum, trip) => sum + trip.distance);

    return {
      'completedTrips': completedTrips,
      'cancelledTrips': cancelledTrips,
      'totalSpent': totalSpent,
      'totalDistance': totalDistance,
      'totalTrips': tripHistory.length,
    };
  }

  @override
  void onClose() {
    _tripStreamSubscription?.cancel();
    _driversStreamSubscription?.cancel();
    _tripTimeoutTimer?.cancel();
    super.onClose();
  }
}
