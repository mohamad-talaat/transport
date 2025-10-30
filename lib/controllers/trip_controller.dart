import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/models/user_model.dart' as models;
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/location_service.dart';
import 'package:transport_app/services/app_settings_service.dart';
import 'package:transport_app/views/common/chat_service/communication_service.dart';
import 'package:transport_app/utils/iraqi_currency_helper.dart';

class TripController extends GetxController {
  static TripController get to => Get.find();
  final CommunicationService communicationService =
      Get.find<CommunicationService>();
  final MyMapController mapController = Get.find<MyMapController>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final Rx<TripModel?> activeTrip = Rx<TripModel?>(null);
  final RxBool hasActiveTrip = false.obs;
  final RxBool isRequestingTrip = false.obs;
  final Rx<DateTime?> activeSearchUntil = Rx<DateTime?>(null);
  final RxInt remainingSearchSeconds = 0.obs;
  final RxBool isUrgentMode = false.obs;
  final RxList<TripModel> tripHistory = <TripModel>[].obs;
  final RxBool isLoadingHistory = false.obs;
  final RxList<models.UserModel> availableDrivers = <models.UserModel>[].obs;

  StreamSubscription<DocumentSnapshot>? _tripStreamSubscription;
  StreamSubscription<QuerySnapshot>? _driversStreamSubscription;
  StreamSubscription<DocumentSnapshot>? _driverLocationSubscription;

  Timer? _tripTimeoutTimer;
  Timer? _searchCountdownTimer;
  Timer? _tripSearchTimeoutTimer;


  final AuthController authController = AuthController.to;
  final LocationService locationService = LocationService.to;
  final AppSettingsService appSettingsService = AppSettingsService.to;

  @override
  void onInit() {
    super.onInit();
    _initializeTripController();
  }

  void _initializeTripController() {
    // ✅ تحميل الرحلة النشطة عند بدء التطبيق
    checkActiveTrip();

    _listenToAvailableDrivers();
    _startTripRequestsCleanup();

    ever(activeTrip, (TripModel? trip) {
      hasActiveTrip.value = trip != null && trip.isActive;

      if (trip != null && trip.isActive) {
        _startTripTracking(trip);
      }
    });
  }

  /// ✅ تحميل الرحلة النشطة للراكب (إن وجدت)
  Future<void> checkActiveTrip() async {
    try {
      final riderId = authController.currentUser.value?.id;
      if (riderId == null) {
        logger.w('⚠️ لا يوجد معرف راكب - تخطي checkActiveTrip');
        return;
      }

      logger.i('🔍 فحص الرحلة النشطة للراكب: $riderId');

      // ✅ البحث عن رحلة نشطة للراكب
      final snapshot = await firestore
          .collection('trips')
          .where('riderId', isEqualTo: riderId)
          .where('status', whereIn: [
            TripStatus.pending.name,
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

        activeTrip.value = trip;
        hasActiveTrip.value = true;

        logger
            .i('✅ تم تحميل رحلة نشطة: ${trip.id} (حالة: ${trip.status.name})');

        // ✅ بدء الاستماع لتحديثات الرحلة
        _startTripTracking(trip);
      } else {
        logger.i('🏠 لا توجد رحلة نشطة للراكب');
        activeTrip.value = null;
        hasActiveTrip.value = false;
      }
    } catch (e) {
      logger.e('❌ خطأ في فحص الرحلة النشطة: $e');
      activeTrip.value = null;
      hasActiveTrip.value = false;
    }
  }

  void _listenToAvailableDrivers() {
    _driversStreamSubscription = firestore
        .collection('users')
        .where('userType', isEqualTo: 'driver')
        .where('additionalData.isOnline', isEqualTo: true)
        .where('additionalData.debtIqD',
            isLessThan: appSettingsService.driverDebtLimitIqD.toDouble())
        .snapshots()
        .listen((snapshot) {
      availableDrivers.clear();
      for (var doc in snapshot.docs) {
        try {
          models.UserModel driver = models.UserModel.fromMap(doc.data());
          availableDrivers.add(driver);
        } catch (e) {
          logger.w('خطأ: $e');
        }
      }
    });
  }

  void _startTripRequestsCleanup() {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      final now = DateTime.now();
      final expired = await firestore
          .collection('trip_requests')
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = firestore.batch();
      for (var doc in expired.docs) {
        // ✅ استخدم set مع merge
        batch.set(
            doc.reference,
            {
              'status': 'expired',
              'expiredAt': Timestamp.fromDate(now),
            },
            SetOptions(merge: true));
      }
      await batch.commit();
    });
  }

  Future<void> requestTrip({
    required LocationPoint pickup,
    required LocationPoint destination,
    Map<String, dynamic>? tripDetails,
  }) async {
    if (isRequestingTrip.value) return;

    isRequestingTrip.value = true;
    try {
      if (!_canRequestTripNow()) return;

      final user = authController.currentUser.value;
      if (user == null) throw Exception('تسجيل دخول مطلوب');

      final existingTrip = await firestore
          .collection('trips')
          .where('riderId', isEqualTo: user.id)
          .where('status', whereIn: ['pending', 'accepted', 'inProgress'])
          .limit(1)
          .get();

      if (existingTrip.docs.isNotEmpty) {
        logger.w('🚫 يوجد بالفعل رحلة نشطة');
        Get.snackbar('رحلة قائمة', 'يوجد لديك رحلة لم تنتهِ بعد.');
        return;
      }
      // ✅ معالجة النقاط الإضافية أولاً قبل أي حسابات
      List<AdditionalStop> processedStops = [];
      if (tripDetails?['additionalStops'] != null) {
        for (var stop in (tripDetails!['additionalStops'] as List)) {
          if (stop is AdditionalStop) {
            if (stop.location.latitude != 0.0 &&
                stop.location.longitude != 0.0) {
              processedStops.add(stop);
            } else {
              logger.e('⚠️ نقطة ${stop.id} بدون إحداثيات صحيحة');
            }
          } else if (stop is Map<String, dynamic>) {
            final parsedStop = AdditionalStop.fromMap(stop);
            if (parsedStop.location.latitude != 0.0 &&
                parsedStop.location.longitude != 0.0) {
              processedStops.add(parsedStop);
            } else {
              logger.e('⚠️ نقطة من Map بدون إحداثيات: $stop');
            }
          }
        }
      }

      // ✅ حساب المسافة مع النقاط الإضافية
      List<LatLng> stopLocations =
          processedStops.map((s) => s.location).toList();
      // double distance = LocationService.to.calculateTotalDistanceWithStops(
      //   pickup: pickup.latLng,
      //   destination: destination.latLng,
      //   additionalStops: stopLocations.isNotEmpty ? stopLocations : null,
      // );
      double distance =
          await LocationService.to.calculateTotalDistanceWithStops(
        pickup: pickup.latLng,
        destination: destination.latLng,
        additionalStops: stopLocations.isNotEmpty ? stopLocations : null,
      );

// الآن حساب المدة: إذا كان لدينا مدة من OSRM وحديثة نستخدمها
      int estimatedDuration;
      if (LocationService.to.lastRouteDurationSeconds != null &&
          LocationService.to.lastRouteCalculatedAt != null &&
          DateTime.now()
                  .difference(LocationService.to.lastRouteCalculatedAt!)
                  .inMinutes <
              5) {
        estimatedDuration =
            (LocationService.to.lastRouteDurationSeconds! / 60).round();
      } else {
        estimatedDuration = locationService.estimateDuration(
          distance,
          withStops: processedStops.isNotEmpty,
        );
      }
      // // ✅ حساب الوقت مع إضافة وقت للنقاط الإضافية
      // int estimatedDuration = locationService.estimateDuration(
      //   distance,
      //   withStops: processedStops.isNotEmpty,
      // );
      // estimatedDuration += processedStops.length * 2;

      double fare = tripDetails?.containsKey('totalFare') == true
          ? tripDetails!['totalFare'] as double
          : calculateFare(distance, tripDetails);

      if (tripDetails?['paymentMethod'] == 'app' && user.balance < fare) {
        Get.snackbar('رصيد ناقص', 'شحّن المحفظة');
        Get.toNamed(AppRoutes.RIDER_WALLET);
        return;
      }

      String tripId = firestore.collection('trips').doc().id;

      // ✅ جلب الـ riderType من الـ user
      RiderType currentRiderType = RiderType.regularTaxi;
      try {
        final savedType = authController.currentUser.value?.riderType;
        if (savedType != null) {
          currentRiderType = RiderType.values.firstWhere(
            (e) => e.name == savedType,
            orElse: () => RiderType.regularTaxi,
          );
        }
      } catch (e) {
        logger.w('⚠️ تعذر جلب riderType: $e');
      }

      TripModel newTrip = TripModel(
        id: tripId,
        riderId: user.id,
        riderName: user.name,
        riderType: currentRiderType, // ✅ إضافة riderType هنا
        pickupLocation: pickup,
        destinationLocation: destination,
        fare: fare,
        distance: distance,
        estimatedDuration: estimatedDuration,
        createdAt: DateTime.now(),
        routePolyline: [],
        isPlusTrip: tripDetails?['isPlusTrip'] ?? false,
        additionalStops: processedStops,
        isRoundTrip: tripDetails?['isRoundTrip'] ?? false,
        waitingTime: tripDetails?['waitingTime'] ?? 0,
        isRush: tripDetails?['isRush'] ?? false,
        paymentMethod: tripDetails?['paymentMethod'],
      );

      await firestore.collection('trips').doc(tripId).set({
        ...newTrip.toMap(),
        'riderId': user.id,
        'riderName': user.name,
        'riderPhone': user.phone,
        'riderPhoto': user.profileImage,
        'riderEmail': user.email,
        'riderRating': user.rating ?? 4.5,
        'additionalStops': processedStops.map((s) => s.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      activeTrip.value = newTrip;
      isUrgentMode.value = false;

      _listenToTripUpdates(tripId);
      await _sendTripRequestsToDrivers(newTrip);
      _startTripSearchTimeout(tripId, const Duration(minutes: 5));
      _startSearchCountdown(const Duration(minutes: 5));
    } catch (e) {
      logger.e('❌ خطأ: $e');
      Get.snackbar('خطأ', 'فشل إنشاء الرحلة');
    } finally {
      isRequestingTrip.value = false;
    }
  }

  // ✅ استماع دائم للتحديثات
  void _listenToTripUpdates(String tripId) {
    _tripStreamSubscription?.cancel();

    _tripStreamSubscription = firestore
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        _clearActiveTripState();
        return;
      }

      final updatedTrip = TripModel.fromMap(snapshot.data()!);
      activeTrip.value = updatedTrip;
      _handleTripStatusChange(updatedTrip);
    });
  }

  // ✅ تطبيق الوضع المستعجل للرحلة الحالية فقط (لا يؤثر على الرحلات القادمة)
  Future<void> applyUrgentModeToCurrentTrip() async {
    final trip = activeTrip.value;
    if (trip == null || trip.status != TripStatus.pending) return;

    try {
      final newFare = trip.fare * 1.2;

      // ✅ تحديث فقط للرحلة الحالية وليس بشكل عام
      await firestore.collection('trips').doc(trip.id).set({
        'isRush': true,
        'fare': newFare,
        'totalFare': newFare,
        'urgentAppliedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ✅ تعيين الوضع فقط لهذه الجلسة (لن يتم حفظها بشكل دائم)
      isUrgentMode.value = true;

      Get.snackbar(
        'تم التحويل للوضع المستعجل',
        'تم زيادة السعر 20% لضمان قبول أسرع',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.e('خطأ في تطبيق الوضع المستعجل: $e');
    }
  }

  Future<void> cancelTrip({String? reason, bool byDriver = false}) async {
    // Get trip details before any state changes
    final trip = activeTrip.value;
    if (trip == null) {
      logger.w('⚠️ cancelTrip: لا توجد رحلة نشطة');
      // For driver cancellation, try to get trip from Firestore
      if (byDriver) {
        try {
          final activeTrips = await firestore
              .collection('trips')
              .where('driverId',
                  isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('status', whereIn: [
                TripStatus.accepted.name,
                TripStatus.inProgress.name,
                TripStatus.pending.name
              ])
              .limit(1)
              .get();

          if (activeTrips.docs.isNotEmpty) {
            final tripId = activeTrips.docs.first.id;
            // Continue with cancellation using this trip
            await _handleTripCancellation(tripId, reason, byDriver);
            return;
          }
        } catch (e) {
          logger.e('Error fetching active trip for driver: $e');
        }
      }
      return;
    }

    // Store trip ID before any operations
    final String tripId = trip.id;
    await _handleTripCancellation(tripId, reason, byDriver);
  }

  Future<void> _handleTripCancellation(
      String tripId, String? reason, bool byDriver) async {
    try {
      // Get trip status first to know if cleanup is needed
      final tripSnapshot =
          await firestore.collection('trips').doc(tripId).get();
      final tripData = tripSnapshot.data();
      final currentStatus = tripData?['status'];

      String cancellationNote = reason ??
          (byDriver ? "تم الإلغاء من قبل السائق" : "تم الإلغاء من قبل الراكب");

      // Update trip status in Firestore
      await firestore.collection('trips').doc(tripId).set({
        'status': TripStatus.cancelled.name,
        'completedAt': FieldValue.serverTimestamp(),
        'notes': cancellationNote,
        'cancelledBy': byDriver ? 'driver' : 'rider',
      }, SetOptions(merge: true));

      // Check if we need to clean up pending requests
      if (currentStatus == TripStatus.pending.name) {
        final requests = await firestore
            .collection('trip_requests')
            .where('tripId', isEqualTo: tripId)
            .get();

        if (requests.docs.isNotEmpty) {
          final batch = firestore.batch();
          for (var doc in requests.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      }

      // Ensure Firebase operations complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Clean up local state
      _cleanupAfterTrip();

      // Handle navigation based on user type
      if (byDriver) {
        if (Get.isBottomSheetOpen ?? false) {
          Get.back();
        }
        await Future.delayed(const Duration(milliseconds: 200));
        Get.offAllNamed(AppRoutes.DRIVER_HOME);
      } else {
        if (Get.isBottomSheetOpen ?? false) {
          Get.back();
        }
        await Future.delayed(const Duration(milliseconds: 200));
        Get.offAllNamed(AppRoutes.RIDER_HOME);
      }

      Get.snackbar('تم الإلغاء', 'تم إلغاء الرحلة بنجاح.');
    } catch (e) {
      logger.e('خطأ في إلغاء الرحلة: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء إلغاء الرحلة');
    }
  }

  // // ✅ استخدم set مع merge
  // Future<void> cancelTrip({String? reason}) async {
  //   final trip = activeTrip.value;
  //   if (trip == null) return;

  //   if ((trip.status == TripStatus.accepted ||
  //           trip.status == TripStatus.driverArrived ||
  //           trip.status == TripStatus.inProgress) &&
  //       reason == null) {
  //     Get.toNamed(AppRoutes.RIDER_TRIP_CANCELLATION_REASONS);
  //     return;
  //   }

  //   try {
  //     String cancellationNote = reason ?? "تم الإلغاء من قبل الراكب";

  //     await firestore.collection('trips').doc(trip.id).set({
  //       'status': TripStatus.cancelled.name,
  //       'completedAt': FieldValue.serverTimestamp(),
  //       'notes': cancellationNote,
  //     }, SetOptions(merge: true));

  //     if (trip.status == TripStatus.pending) {
  //       final requests = await firestore
  //           .collection('trip_requests')
  //           .where('tripId', isEqualTo: trip.id)
  //           .get();
  //       final batch = firestore.batch();
  //       for (var doc in requests.docs) {
  //         batch.delete(doc.reference);
  //       }
  //       await batch.commit();
  //     }

  //     await Future.delayed(const Duration(milliseconds: 300));
  //     _cleanupAfterTrip();
  //     Get.offAllNamed(AppRoutes.RIDER_HOME);
  //     Get.snackbar('تم الإلغاء', 'تم إلغاء الرحلة بنجاح.');
  //   } catch (e) {
  //     logger.e("❌ خطأ: $e");
  //     Get.snackbar('خطأ', 'تعذر إلغاء الرحلة');
  //   }
  // }

  // Future checkActiveTrip() async {
  //   try {
  //     final user = authController.currentUser.value;
  //     if (user == null) {
  //       _clearActiveTripState();
  //       return;
  //     }

  //     final querySnapshot = await firestore
  //         .collection('trips')
  //         .where('riderId', isEqualTo: user.id)
  //         .where('status',
  //             whereIn: ['pending', 'accepted', 'driverArrived', 'inProgress'])
  //         .orderBy('createdAt', descending: true)
  //         .limit(1)
  //         .get();

  //     if (querySnapshot.docs.isEmpty) {
  //       _clearActiveTripState();
  //       return;
  //     }

  //     final tripData = querySnapshot.docs.first.data();
  //     final trip = TripModel.fromMap(tripData);

  //     if (trip.status == TripStatus.pending) {
  //       final timeSinceCreation = DateTime.now().difference(trip.createdAt);
  //       if (timeSinceCreation > const Duration(minutes: 30)) {
  //         logger.w('⚠️ رحلة قديمة، سيتم إلغاؤها');

  //         // ✅ استخدم set مع merge
  //         await firestore.collection('trips').doc(trip.id).set({
  //           'status': TripStatus.cancelled.name,
  //           'notes': 'تم الإلغاء تلقائياً - تجاوزت المدة المسموحة',
  //           'cancelledAt': FieldValue.serverTimestamp(),
  //         }, SetOptions(merge: true));

  //         _clearActiveTripState();
  //         return;
  //       }
  //     }

  //     activeTrip.value = trip;
  //     hasActiveTrip.value = true;
  //     _listenToTripUpdates(trip.id);
  //   } catch (e) {
  //     logger.e('❌ خطأ: $e');
  //     _clearActiveTripState();
  //   }
  // }

  void _startTripTracking(TripModel trip) {
    if (trip.driverId != null) {
      _listenToDriverLocation(trip.driverId!);
    }
  }

  void _listenToDriverLocation(String driverId) {
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = firestore
        .collection('users')
        .doc(driverId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        try {
          final data = snapshot.data()!;
          final lat =
              (data['additionalData']?['currentLat'] as num?)?.toDouble();
          final lng =
              (data['additionalData']?['currentLng'] as num?)?.toDouble();

          if (lat != null && lng != null) {
            LatLng driverLocation = LatLng(lat, lng);
            if (Get.isRegistered<MyMapController>()) {
              Get.find<MyMapController>().updateDriverLocation(driverLocation);
            }
          }
        } catch (e) {
          logger.w('خطأ في تحديث موقع السائق: $e');
        }
      }
    });
  }

  Future<void> _fetchCompleteDriverData(String driverId, TripModel trip) async {
    try {
      final driverDoc = await firestore.collection('users').doc(driverId).get();
      if (driverDoc.exists) {
        final driverData = models.UserModel.fromMap(driverDoc.data()!);

        // ✅ احفظ بيانات السائق في الرحلة
        await firestore.collection('trips').doc(trip.id).set({
          'driverName': driverData.name,
          'driverPhone': driverData.phone,
          'driverPhoto': driverData.profileImage,
          'driverEmail': driverData.email,
          'driverRating': driverData.rating,
          'driverVehicleType': driverData.vehicleType!.name,
          'driverVehicleNumber':
              "${driverData.plateNumber} ${driverData.plateLetter} ${driverData.provinceCode}",
        }, SetOptions(merge: true));

        activeTrip.value = trip.copyWith(driver: driverData);
        _startEnhancedDriverTracking(driverId);
      }
    } catch (e) {
      logger.e('خطأ في جلب بيانات السائق: $e');
    }
  }

  void _startEnhancedDriverTracking(String driverId) {
    _driverLocationSubscription?.cancel();

    _driverLocationSubscription = firestore
        .collection('users')
        .doc(driverId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && activeTrip.value != null) {
        try {
          final data = snapshot.data()!;
          final additionalData =
              data['additionalData'] as Map<String, dynamic>?;

          if (additionalData != null) {
            final currentLat = additionalData['currentLat']?.toDouble();
            final currentLng = additionalData['currentLng']?.toDouble();

            if (currentLat != null && currentLng != null) {
              if (Get.isRegistered<MyMapController>()) {
                Get.find<MyMapController>()
                    .updateDriverLocation(LatLng(currentLat, currentLng));
              }
            }
          }
        } catch (e) {
          logger.w('خطأ في تحديث موقع السائق: $e');
        }
      }
    });
  }

  void _handleTripStatusChange(TripModel trip) {
    switch (trip.status) {
      case TripStatus.accepted:
        if (trip.driverId != null) {
          _fetchCompleteDriverData(trip.driverId!, trip);
        }
        // Get.snackbar('تم قبول الرحلة', 'السائق في الطريق إليك',
        //     backgroundColor: Colors.green, colorText: Colors.white);
        Get.toNamed(AppRoutes.RIDER_TRIP_TRACKING);
        break;

      case TripStatus.driverArrived:
        Get.snackbar('وصل السائق', 'السائق وصل إلى موقعك',
            backgroundColor: Colors.blue, colorText: Colors.white);
        break;

      case TripStatus.inProgress:
        Get.snackbar('بدأت الرحلة', 'جاري التوجه إلى الوجهة',
            backgroundColor: Colors.purple, colorText: Colors.white);
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

  void _handleTripCompleted(TripModel trip) {
    logger.i('🎉 الرحلة انتهت بنجاح');

    if ((trip.paymentMethod ?? 'cash') == 'app') {
      authController.updateBalance(-trip.fare);
    }

    try {
      // ✅ حساب العمولة بناءً على سعر الرحلة
      final int commission = appSettingsService.calculateCommission(trip.fare);
      _increaseDriverDebt(trip.driverId, commission);
    } catch (_) {}

    // ✅ تنظيف كامل للماركرات والاستماعات فوراً
    _cleanupMarkersAfterTripEnd();
    _driverLocationSubscription?.cancel();
    _tripStreamSubscription?.cancel();

    // ✅ مسح الرحلة النشطة
    _clearActiveTrip();
    tripHistory.insert(0, trip);

    // ⚠️ الراكب لا يرجع للهوم - ينتقل مباشرة لصفحة التقييم
    // صفحة RiderTripTrackingView ستتولى الانتقال للتقييم
    logger.i('✅ صفحة تتبع الرحلة ستظهر التقييم تلقائياً');
  }

  void _handleTripCancelled(TripModel trip) {
    logger.i('❌ تم إلغاء الرحلة');

    // ✅ تنظيف كامل للماركرات والاستماعات فوراً
    _cleanupMarkersAfterTripEnd();
    _driverLocationSubscription?.cancel();
    _tripStreamSubscription?.cancel();

    // ✅ مسح الرحلة النشطة
    _clearActiveTrip();
    tripHistory.insert(0, trip);

    // ✅ الرجوع للهوم فوراً بعد التنظيف
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute != AppRoutes.RIDER_HOME) {
        Get.offAllNamed(AppRoutes.RIDER_HOME);
        // ✅ تنظيف إضافي بعد الانتقال
        Future.delayed(const Duration(milliseconds: 300), () {
          if (Get.isRegistered<MyMapController>()) {
            Get.find<MyMapController>().clearAllTripAndDriverMarkers();
          }
        });
      }

      Get.snackbar('تم إلغاء الرحلة', trip.notes ?? 'تم إلغاء الرحلة',
          backgroundColor: Colors.orange, colorText: Colors.white);
    });
  }

  void _showNoDriversFoundMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        'لا يوجد سائقون متاحون',
        'لا يوجد سائقون قريبون حالياً',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        icon: const Icon(Icons.warning, color: Colors.white),
      );
    });
  }

  void _startTripSearchTimeout(String tripId, Duration timeout) {
    _tripSearchTimeoutTimer?.cancel();
    _tripSearchTimeoutTimer = Timer(timeout, () {
      final currentTrip = activeTrip.value;
      if (currentTrip != null &&
          currentTrip.id == tripId &&
          currentTrip.status == TripStatus.pending) {
        cancelTrip(reason: "انتهى وقت البحث عن سائق");
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

  double calculateFare(double distanceKm, Map<String, dynamic>? details) {
    double baseFare = appSettingsService.calculateFare(distanceKm, null);

    if (details != null) {
      List<dynamic> additionalStops = details['additionalStops'] ?? [];
      baseFare += additionalStops.length * 1000;

      int waitingTime = details['waitingTime'] ?? 0;
      baseFare += waitingTime * 500;

      bool isRoundTrip = details['isRoundTrip'] ?? false;
      if (isRoundTrip) baseFare *= 1.8;

      bool isRush = details['isRush'] ?? false;
      if (isRush) baseFare *= 1.2;

      bool isPlusTrip = details['isPlusTrip'] ?? false;
      if (isPlusTrip) baseFare += 1000;
    }

    return IraqiCurrencyHelper.roundToNearest250(baseFare);
  }

  Future<void> _increaseDriverDebt(String? driverId, int amountIqD) async {
    if (driverId == null) return;
    try {
      await firestore.collection('users').doc(driverId).set({
        'additionalData': {
          'debtIqD': FieldValue.increment(amountIqD),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      logger.w('خطأ: $e');
    }
  }

  Future<void> loadTripHistory() async {
    final user = authController.currentUser.value;
    if (user == null) return;

    try {
      isLoadingHistory.value = true;

      QuerySnapshot querySnapshot = await firestore
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
          logger.w('خطأ: $e');
        }
      }
    } catch (e) {
      logger.w('خطأ: $e');
    } finally {
      isLoadingHistory.value = false;
    }
  }

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

  void _clearActiveTripState() {
    try {
      _tripStreamSubscription?.cancel();
      _tripTimeoutTimer?.cancel();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        activeTrip.value = null;
        hasActiveTrip.value = false;
        isRequestingTrip.value = false;
      });
    } catch (e) {
      logger.w('خطأ: $e');
    }
  }

  void _clearActiveTrip() {
    _tripStreamSubscription?.cancel();
    _tripTimeoutTimer?.cancel();
    activeTrip.value = null;
    hasActiveTrip.value = false;
  }

  void _cleanupAfterTrip() {
    _driverLocationSubscription?.cancel();
    _clearActiveTripState();
    _stopSearchCountdown();
    _tripSearchTimeoutTimer?.cancel();

    // ✅ تنظيف كامل للماركرات
    _cleanupMarkersAfterTripEnd();
  }

  /// ✅ تنظيف شامل لجميع ماركرات الرحلة بعد الانتهاء
  void _cleanupMarkersAfterTripEnd() {
    logger.i('🧹 بدء تنظيف ماركرات الرحلة بعد الانتهاء...');

    if (Get.isRegistered<MyMapController>()) {
      final mapCtrl = Get.find<MyMapController>();

      // ✅ مسح جميع ماركرات الرحلة
      mapCtrl.clearTripMarkers();

      // ✅ مسح موقع السائق
      mapCtrl.driverLocation.value = null;

      // ✅ مسح polylines
      mapCtrl.polylines.clear();

      logger.i('✅ تم تنظيف جميع ماركرات الرحلة');
    }
  }

  // Future<void> _checkActiveTrip() async {
  //   try {
  //     final user = authController.currentUser.value;
  //     if (user == null) return;

  //     QuerySnapshot activeTripsQuery = await firestore
  //         .collection('trips')
  //         .where('riderId', isEqualTo: user.id)
  //         .where('status',
  //             whereIn: ['pending', 'accepted', 'driverArrived', 'inProgress'])
  //         .orderBy('createdAt', descending: true)
  //         .get();

  //     if (activeTripsQuery.docs.isEmpty) {
  //       _clearActiveTripState(); // لا توجد رحلات نشطة، نظّف الحالة
  //       return;
  //     }

  //     // وجدنا رحلة أو أكثر، لنتعامل معها
  //     final tripDoc = activeTripsQuery.docs.first;
  //     final trip = TripModel.fromMap(tripDoc.data() as Map<String, dynamic>);

  //     // **الفحص الأمني الحاسم**
  //     // إذا كانت الرحلة في حالة "pending" لأكثر من الوقت المسموح به، قم بإلغائها فوراً
  //     if (trip.status == TripStatus.pending) {
  //       final timeSinceCreation = DateTime.now().difference(trip.createdAt);
  //       if (timeSinceCreation > const Duration(minutes: 5, seconds: 30)) {
  //         // 5 دقائق و 30 ثانية كهامش أمان
  //         logger.w("وجدنا رحلة قديمة معلقة (${trip.id}). سيتم إلغاؤها الآن.");
  //         await firestore.collection('trips').doc(trip.id).update({
  //           'status': TripStatus.cancelled.name,
  //           'notes': 'تم الإلغاء تلقائياً بسبب انتهاء المهلة',
  //         });
  //         _clearActiveTripState(); // ثم نظّف الحالة
  //         return; // توقف هنا
  //       }
  //     }

  //     // إذا مرت من الفحص، فهي رحلة نشطة وصالحة
  //     activeTrip.value = trip;
  //     _listenToTripUpdates(trip.id);
  //   } catch (e) {
  //     logger.e("خطأ فادح أثناء التحقق من الرحلة النشطة: $e");
  //     _clearActiveTripState(); // في حالة حدوث أي خطأ، من الأفضل تنظيف الحالة
  //   }
  // }

  Future<void> cancelActiveTrip({String? reason}) async {
    try {
      final trip = activeTrip.value;
      if (trip == null) return;

      activeTrip.value = null;
      _stopSearchCountdown();

      Get.snackbar(
        'تم الإلغاء',
        reason ?? 'تم الإلغاء من قبل الراكب',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.e("خطأ في إلغاء الرحلة: $e");
    }
  }

  void cancelUrgentMode() {
    isUrgentMode.value = false;
  }

  Future<void> confirmPayment({
    required String tripId,
    required double receivedAmount,
    required String paymentMethod,
    required double expectedAmount,
  }) async {
    try {
      final driverId = authController.currentUser.value!.id;

      await FirebaseFirestore.instance.collection('trips').doc(tripId).update({
        'paymentMethod': paymentMethod,
        'receivedAmount': receivedAmount,
        'expectedAmount': expectedAmount,
        'paymentConfirmedAt': FieldValue.serverTimestamp(),
        'paymentConfirmedBy': driverId,
        'paymentStatus': 'confirmed',
      });

      if (paymentMethod == 'cash') {
        await _updateDriverBalance(driverId, receivedAmount);
      }

      await _sendPaymentConfirmationNotification(tripId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _updateDriverBalance(String driverId, double amount) async {
    await FirebaseFirestore.instance.collection('users').doc(driverId).update({
      'balance': FieldValue.increment(amount),
      'totalEarnings': FieldValue.increment(amount),
    });
  }

  Future<void> _sendPaymentConfirmationNotification(String tripId) async {}

  Future<void> rateTrip(
    String tripId,
    double rating,
    String? comment,
  ) async {
    try {
      await firestore.collection('trip_ratings').doc(tripId).set({
        'tripId': tripId,
        'riderId': authController.currentUser.value?.id,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'شكراً لك',
        'تم إرسال التقييم بنجاح',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.w('خطأ في إرسال التقييم: $e');
      Get.snackbar(
        'خطأ',
        'تعذر إرسال التقييم',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<TripModel?> getTripById(String tripId) async {
    try {
      DocumentSnapshot doc =
          await firestore.collection('trips').doc(tripId).get();

      if (doc.exists) {
        return TripModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      logger.w('خطأ في البحث عن الرحلة: $e');
      return null;
    }
  }

  Future<void> runDiagnostics() async {
    logger.i('🔍 تشغيل التشخيص الشامل...');

    try {
      await firestore.collection('test').doc('diagnostic').set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': 'database_connection'
      });
      logger.i('✅ اتصال قاعدة البيانات: يعمل');

      final onlineDriversQuery = await firestore
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .where('additionalData.isOnline', isEqualTo: true)
          .get();

      logger.i('👥 السائقون المتصلون: ${onlineDriversQuery.docs.length}');

      Get.snackbar(
        'نتائج التشخيص',
        'تم التشخيص بنجاح. السائقون المتصلون: ${onlineDriversQuery.docs.length}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.e('❌ فشل التشخيص: $e');
      Get.snackbar(
        'خطأ في التشخيص',
        'حدث خطأ أثناء التشخيص',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void showNavigationCompleteMessage() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (Get.currentRoute == AppRoutes.RIDER_HOME && !Get.isSnackbarOpen) {
        Get.snackbar(
          'تم بنجاح',
          'تم إلغاء الرحلة والعودة للصفحة الرئيسية',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          isDismissible: true,
          forwardAnimationCurve: Curves.easeOutBack,
          reverseAnimationCurve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  Future<void> updateTripRoute(
      String tripId, LatLng newPickup, LatLng newDestination) async {
    try {
      final routeResult =
          await locationService.getRoute(newPickup, newDestination);
      final distance =
          locationService.calculateDistance(newPickup, newDestination);
      final duration = locationService.estimateDuration(distance);

      await firestore.collection('trips').doc(tripId).update({
        'pickupLocation': {
          'lat': newPickup.latitude,
          'lng': newPickup.longitude,
          'address': await locationService.getAddressFromLocation(newPickup),
        },
        'destinationLocation': {
          'lat': newDestination.latitude,
          'lng': newDestination.longitude,
          'address':
              await locationService.getAddressFromLocation(newDestination),
        },
        'routePolyline': routeResult
            .map((ll) => {
                  'lat': ll.latitude,
                  'lng': ll.longitude,
                })
            .toList(),
        'distance': distance,
        'estimatedDuration': duration,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logger.i('✅ تم تحديث مسار الرحلة');
    } catch (e) {
      logger.e('خطأ في تحديث مسار الرحلة: $e');
      rethrow;
    }
  }

  Future<bool> updateTripDestination({
    required String tripId,
    required LocationPoint newDestination,
    List<Map<String, dynamic>>? newAdditionalStops,
    int? newWaitingTime,
  }) async {
    try {
      final tripDoc = await firestore.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) return false;

      final trip = TripModel.fromMap(tripDoc.data()!);

      LatLng startPoint;
      if (trip.status == TripStatus.inProgress &&
          mapController.driverLocation.value != null) {
        startPoint = mapController.driverLocation.value!;
      } else {
        startPoint = trip.pickupLocation.latLng;
      }

      final destLatLng = LatLng(newDestination.lat, newDestination.lng);

      // ✅ حساب المسافة مع النقاط الإضافية
      double newDistance;

      if (newAdditionalStops != null && newAdditionalStops.isNotEmpty) {
        List<LatLng> stopLocations = [];

        for (var stop in newAdditionalStops) {
          final locData = stop['location'];
          LatLng? stopLatLng;

          if (locData is LatLng) {
            stopLatLng = locData;
          } else if (locData is Map) {
            final lat = (locData['latitude'] ?? locData['lat'] ?? 0.0);
            final lng = (locData['longitude'] ?? locData['lng'] ?? 0.0);
            stopLatLng = LatLng(
              lat is num ? lat.toDouble() : double.parse(lat.toString()),
              lng is num ? lng.toDouble() : double.parse(lng.toString()),
            );
          } else {
            logger.w('تنسيق غير صحيح لنقطة التوقف: $locData');
            continue;
          }

          stopLocations.add(stopLatLng);
        }

        // ✅ استخدام الدالة المحسّنة
        newDistance = await locationService.calculateTotalDistanceWithStops(
          pickup: startPoint,
          destination: destLatLng,
          additionalStops: stopLocations,
        );
      } else {
        newDistance = locationService.calculateDistance(startPoint, destLatLng);
      }

      final effectiveWaitingTime = newWaitingTime ?? trip.waitingTime ?? 0;

      Map<String, dynamic> fareDetails = {
        'additionalStops': newAdditionalStops ?? [],
        'waitingTime': effectiveWaitingTime,
        'isRoundTrip': trip.isRoundTrip,
        'isRush': trip.isRush,
        'isPlusTrip': trip.isPlusTrip,
      };

      double newFare = calculateFare(newDistance, fareDetails);
      // ✅ حساب الوقت مع النقاط الإضافية
      int newDuration = locationService.estimateDuration(
        newDistance,
        withStops: (newAdditionalStops?.length ?? 0) > 0,
      );
      // إضافة وقت لكل نقطة توقف
      newDuration += (newAdditionalStops?.length ?? 0) * 2;

      final updateData = {
        'pendingDestination': newDestination.toMap(),
        'pendingAdditionalStops': newAdditionalStops,
        'pendingWaitingTime': effectiveWaitingTime,
        'pendingFare': newFare,
        'pendingDistance': newDistance,
        'pendingDuration': newDuration,
        'destinationChanged': true,
        'destinationChangedAt': FieldValue.serverTimestamp(),
        'driverNotified': false,
        'driverApproved': null,
      };

      await firestore
          .collection('trips')
          .doc(tripId)
          .set(updateData, SetOptions(merge: true));

      if (trip.driverId != null) {
        String bodyMsg = 'قام الراكب بطلب تغيير وجهة الرحلة\n';
        bodyMsg += 'المسافة الجديدة: ${newDistance.toStringAsFixed(1)} كم\n';
        bodyMsg += 'المدة المتوقعة: $newDuration دقيقة\n';
        if (effectiveWaitingTime > 0) {
          bodyMsg += 'وقت الانتظار: $effectiveWaitingTime دقيقة\n';
        }
        bodyMsg += 'السعر الجديد: ${IraqiCurrencyHelper.formatAmount(newFare)}';

        await firestore.collection('notifications').add({
          'userId': trip.driverId,
          'title': 'طلب تغيير في الوجهة',
          'body': bodyMsg,
          'type': 'destination_change_request',
          'tripId': tripId,
          'data': {
            'newDistance': newDistance,
            'newFare': newFare,
            'newDuration': newDuration,
            'waitingTime': effectiveWaitingTime,
            'hasAdditionalStops':
                newAdditionalStops != null && newAdditionalStops.isNotEmpty,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await firestore
            .collection('trips')
            .doc(tripId)
            .set({'driverNotified': true}, SetOptions(merge: true));
      }

      Get.snackbar('تم إرسال الطلب', 'بانتظار موافقة السائق على التغيير',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 3));

      return true;
    } catch (e) {
      logger.e('خطأ في تحديث الوجهة: $e');
      Get.snackbar('خطأ', 'فشل تحديث الوجهة',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }

  Future<void> driverApproveDestinationChange(
      String tripId, bool approve) async {
    try {
      final tripDoc = await firestore.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) return;

      final tripData = tripDoc.data()!;
      final Map<String, dynamic> update = {
        'driverApproved': approve,
        'driverApprovedAt': FieldValue.serverTimestamp(),
        'destinationChanged': false,
      };

      if (approve) {
        if (tripData.containsKey('pendingDestination')) {
          update['destinationLocation'] = tripData['pendingDestination'];
        }
        if (tripData.containsKey('pendingAdditionalStops')) {
          update['additionalStops'] = tripData['pendingAdditionalStops'];
        }
        if (tripData.containsKey('pendingWaitingTime')) {
          update['waitingTime'] = tripData['pendingWaitingTime'];
        }
        if (tripData.containsKey('pendingFare')) {
          update['fare'] = tripData['pendingFare'];
          update['totalFare'] = tripData['pendingFare'];
        }
        if (tripData.containsKey('pendingDistance')) {
          update['distance'] = tripData['pendingDistance'];
        }
        if (tripData.containsKey('pendingDuration')) {
          update['estimatedDuration'] = tripData['pendingDuration'];
        }

        update['pendingDestination'] = FieldValue.delete();
        update['pendingAdditionalStops'] = FieldValue.delete();
        update['pendingWaitingTime'] = FieldValue.delete();
        update['pendingFare'] = FieldValue.delete();
        update['pendingDistance'] = FieldValue.delete();
        update['pendingDuration'] = FieldValue.delete();
        update['updatedAt'] = FieldValue.serverTimestamp();

        // 🔥 إضافة علم لتحديث الماركرات
        update['markersNeedUpdate'] = true;

        logger.i('✅ سيتم تحديث الوجهة والماركرات');
      } else {
        update['pendingDestination'] = FieldValue.delete();
        update['pendingAdditionalStops'] = FieldValue.delete();
        update['pendingWaitingTime'] = FieldValue.delete();
        update['pendingFare'] = FieldValue.delete();
        update['pendingDistance'] = FieldValue.delete();
        update['pendingDuration'] = FieldValue.delete();
      }

      await firestore
          .collection('trips')
          .doc(tripId)
          .set(update, SetOptions(merge: true));

      final riderId = tripData['riderId'];
      if (riderId != null) {
        String notificationBody = approve
            ? 'وافق السائق على تغيير الوجهة'
            : 'رفض السائق تغيير الوجهة';

        if (approve && tripData.containsKey('pendingFare')) {
          final newFare = tripData['pendingFare'];
          notificationBody +=
              '\nالسعر النهائي: ${IraqiCurrencyHelper.formatAmount(newFare)}';
        }

        await firestore.collection('notifications').add({
          'userId': riderId,
          'title': approve ? 'تمت الموافقة' : 'تم الرفض',
          'body': notificationBody,
          'type': 'destination_change_response',
          'tripId': tripId,
          'approved': approve,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      Get.snackbar(
        approve ? 'تم القبول' : 'تم الرفض',
        approve ? 'تم قبول تغيير الوجهة' : 'تم رفض تغيير الوجهة',
        backgroundColor: approve ? Colors.green : Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.e('❌ خطأ في تحديث الموافقة: $e');
      Get.snackbar('خطأ', 'فشل تحديث الموافقة',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> submitRating({
    required String tripId,
    required int rating,
    required String comment,
    required bool isDriver,
    required String userId,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      if (isDriver) {
        updateData['driverRating'] = rating;
        updateData['driverComment'] = comment;
      } else {
        updateData['riderRating'] = rating;
        updateData['riderComment'] = comment;
      }
      updateData['ratedAt'] = FieldValue.serverTimestamp();

      await firestore.collection('trips').doc(tripId).update(updateData);

      final userRef = firestore.collection('users').doc(userId);

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final totalRating = (data['totalRating'] ?? 0) + rating;
        final ratingCount = (data['ratingCount'] ?? 0) + 1;
        final averageRating = totalRating / ratingCount;

        transaction.update(userRef, {
          'totalRating': totalRating,
          'ratingCount': ratingCount,
          'rating': averageRating,
        });
      });

      logger.i('تم إرسال التقييم وتحديث حساب المستخدم بنجاح');
    } catch (e) {
      logger.e('خطأ في إرسال التقييم: $e');
    }
  }

  DateTime? _lastTripRequestTime;

  bool _canRequestTripNow() {
    final now = DateTime.now();
    if (_lastTripRequestTime != null &&
        now.difference(_lastTripRequestTime!) < const Duration(seconds: 5)) {
      logger.w('🚫 تم تجاهل الطلب: محاولات متكررة خلال أقل من 5 ثوانٍ');
      return false;
    }
    _lastTripRequestTime = now;
    return true;
  }

  Future<void> _sendTripRequestsToDrivers(TripModel trip) async {
    try {
      logger.i('📤 بدء إرسال طلبات لأقرب 5 سائقين');

      // ✅ تحديد نوع الرحلة (plus/regular)
      final bool isPlusTrip = trip.isPlusTrip;
      logger.i('🔹 نوع الرحلة: ${isPlusTrip ? "بلس ⭐" : "عادي 🚕"}');

      // ✅ فلترة السائقين حسب النوع
      Query driversQuery = firestore
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .where('additionalData.isOnline', isEqualTo: true)
          .where('additionalData.isAvailable', isEqualTo: true);

      // ✅ لو الرحلة عادية → فقط السائقين العاديين + البلس
      if (!isPlusTrip) {
        // رحلة عادية → كل السائقين (عادي + بلس)
        logger.i('✅ رحلة عادية → إرسال لجميع السائقين');
      } else {
        // رحلة بلس → فقط سائقين بلس
        logger.i('⭐ رحلة بلس → إرسال فقط لسائقين بلس');
        driversQuery = driversQuery.where('vehicleType', isEqualTo: 'plus');
      }

      final drivers = await driversQuery.get();
 
      if (drivers.docs.isEmpty) {
        logger.w('⚠️ لا يوجد سائقون متاحون');
        _showNoDriversFoundMessage();
        return;
      }

      List<Map<String, dynamic>> driversWithDistance = [];
      
      for (var doc in drivers.docs) {
        final data = doc.data();
final additionalData = (data as Map<String, dynamic>?)?['additionalData'] as Map<String, dynamic>? ?? {};
        final lat = additionalData['currentLat']?.toDouble();
        final lng = additionalData['currentLng']?.toDouble();
        
        if (lat != null && lng != null) {
          final distance = LocationService.to.calculateDistance(
            trip.pickupLocation.latLng,
            LatLng(lat, lng),
          );
          
          // ✅ تصفية: اختر فقط السائقين ضمن 10 كم
          if (distance <= 10.0) {
            driversWithDistance.add({
              'id': doc.id,
              'distance': distance,
            });
          }
        }
      }

      if (driversWithDistance.isEmpty) {
        logger.w('⚠️ لا يوجد سائقون ضمن 10 كم');
        _showNoDriversFoundMessage();
        return;
      }

      driversWithDistance.sort((a, b) => 
        (a['distance'] as double).compareTo(b['distance'] as double)
      );

      const maxDrivers = 5;
      final selectedDrivers = driversWithDistance.take(maxDrivers).toList();

      logger.i('👥 تم اختيار ${selectedDrivers.length} سائق');

      final expiresAt = DateTime.now().add(const Duration(seconds: 25));
      final batch = firestore.batch();
      int sentCount = 0;

      for (var driver in selectedDrivers) {
        final driverId = driver['id'] as String;
        final requestRef = firestore.collection('trip_requests').doc('${trip.id}_$driverId');

        batch.set(requestRef, {
          'tripId': trip.id,
          'driverId': driverId,
          'riderId': trip.riderId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(expiresAt),
          'driverDistance': driver['distance'],
          'tripDetails': {
            'pickupAddress': trip.pickupLocation.address,
            'pickupLat': trip.pickupLocation.lat,
            'pickupLng': trip.pickupLocation.lng,
            'destinationAddress': trip.destinationLocation.address,
            'destinationLat': trip.destinationLocation.lat,
            'destinationLng': trip.destinationLocation.lng,
            'fare': trip.fare,
            'distance': trip.distance,
            'estimatedDuration': trip.estimatedDuration,
            'riderName': trip.riderName,
            'riderType': trip.riderType.name,
            'isPlusTrip': trip.isPlusTrip,
            'isRush': trip.isRush,
            'additionalStops': trip.additionalStops.map((s) => s.toMap()).toList(),
            'isRoundTrip': trip.isRoundTrip,
            'waitingTime': trip.waitingTime,
          },
        });

        sentCount++;
        logger.i('  ✅ $driverId (${driver['distance'].toStringAsFixed(1)}km)');
      }

      await batch.commit();
      logger.i('✅ تم إرسال $sentCount طلب بنجاح');
    } catch (e) {
      logger.e('❌ خطأ في إرسال الطلبات: $e');
    }
  }

  /// 🔒 السائق يقبل الرحلة (Transaction آمن مع Race Condition Protection)
  Future<bool> driverAcceptTrip(String tripId, String driverId) async {
    try {
      logger.i('🚗 محاولة قبول الرحلة $tripId من السائق $driverId');

      return await firestore.runTransaction<bool>((transaction) async {
        final tripRef = firestore.collection('trips').doc(tripId);
        final tripSnap = await transaction.get(tripRef);

        // ✅ فحص: هل الرحلة موجودة؟
        if (!tripSnap.exists) {
          logger.w('❌ الرحلة غير موجودة');
          return false;
        }

        final tripData = tripSnap.data()!;
        final status = tripData['status'];
        
        // ✅ فحص حاسم: هل الرحلة لسه pending؟
        if (status != TripStatus.pending.name) {
          logger.w('❌ الرحلة مُقبولة مسبقاً (Status: $status)');
          Get.snackbar('متأخر!', 'سائق آخر قبل الرحلة',
              backgroundColor: Colors.orange, colorText: Colors.white);
          return false;
        }

        // ✅ قبول الرحلة (atomic update)
        transaction.update(tripRef, {
          'status': TripStatus.accepted.name,
          'driverId': driverId,
          'acceptedAt': FieldValue.serverTimestamp(),
          'lockedBy': driverId, // 🔐 قفل الرحلة
        });

        logger.i('✅ تم قبول الرحلة بنجاح');
        return true;
      }).timeout(const Duration(seconds: 5));
      
    } on TimeoutException {
      logger.e('⏱️ انتهى وقت المعاملة');
      Get.snackbar('خطأ', 'فشل القبول - حاول مرة أخرى',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } catch (e) {
      logger.e('❌ خطأ في قبول الرحلة: $e');
      Get.snackbar('خطأ', 'الرحلة مقبولة من سائق آخر',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      // ✅ تنظيف الطلبات بعد القبول/الرفض
      _cleanupTripRequests(tripId);
    }
  }

  /// ✅ تنظيف طلبات الرحلة بعد القبول
  Future<void> _cleanupTripRequests(String tripId) async {
    try {
      final requests = await firestore
          .collection('trip_requests')
          .where('tripId', isEqualTo: tripId)
          .get();

      if (requests.docs.isEmpty) return;

      final batch = firestore.batch();
      for (var doc in requests.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      logger.i('🧹 تم حذف ${requests.docs.length} طلب');
    } catch (e) {
      logger.w('⚠️ خطأ في تنظيف الطلبات: $e');
    }
  }

  @override
  void onClose() {
    _tripStreamSubscription?.cancel();
    _driversStreamSubscription?.cancel();
    _driverLocationSubscription?.cancel();
    _tripTimeoutTimer?.cancel();
    _searchCountdownTimer?.cancel();
    super.onClose();
  }
}
