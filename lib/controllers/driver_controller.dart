import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/services/driver_profile_service.dart'
    hide logger, Timestamp;
import 'package:transport_app/services/location_service.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/views/driver/driver_trip_request_dialog.dart';

class DriverController extends GetxController {
  static DriverController get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController authController = AuthController.to;
  final LocationService locationService = LocationService.to;
  final DriverProfileService profileService = Get.find<DriverProfileService>();

  // Driver status
  final RxBool isOnline = false.obs;
  final RxBool isAvailable = true.obs;
  final RxBool isOnTrip = false.obs;

  // Current trip
  final Rx<TripModel?> currentTrip = Rx<TripModel?>(null);

  // Trip requests
  final RxList<TripModel> tripRequests = <TripModel>[].obs;
  final RxList<String> declinedTrips = <String>[].obs;

  // Driver location
  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  Timer? _locationUpdateTimer;

  // Trip history
  final RxList<TripModel> tripHistory = <TripModel>[].obs;
  final RxBool isLoadingHistory = false.obs;

  // Earnings
  final RxDouble todayEarnings = 0.0.obs;
  final RxDouble weekEarnings = 0.0.obs;
  final RxDouble monthEarnings = 0.0.obs;
  final RxInt completedTripsToday = 0.obs;

  // Real-time listeners
  StreamSubscription<QuerySnapshot>? _tripRequestsSubscription;
  StreamSubscription<DocumentSnapshot>? _currentTripSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeDriverController();
  }

  /// تهيئة متحكم السائق
  Future<void> _initializeDriverController() async {
    try {
      // التحقق من اكتمال البروفايل أولاً
      final canReceiveRequests = await _checkProfileCompletion();
      if (!canReceiveRequests) {
        // إذا لم يكمل البروفايل، لا يمكنه استقبال الطلبات
        isOnline.value = false;
        isAvailable.value = false;
        return;
      }

      // تحميل حالة السائق
      await _loadDriverStatus();

      // تحقق من وجود رحلة نشطة
      await _checkActiveTrip();

      // تحميل الإحصائيات
      await _loadEarningsData();

      // بدء الاستماع للطلبات إذا كان السائق متاحاً
      if (isOnline.value) {
        _startListeningForRequests();
        _startLocationUpdates();
      }
    } catch (e) {
      logger.w('خطأ في تهيئة متحكم السائق: $e');
    }
  }

  /// التحقق من اكتمال بروفايل السائق وموافقة الإدارة
  Future<bool> _checkProfileCompletion() async {
    try {
      // هنا نحتاج للوصول لـ AuthController
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser.value?.id;

      if (userId == null) return false;

      // التحقق من اكتمال البروفايل
      final isComplete = await profileService.isProfileComplete(userId);
      if (!isComplete) {
        Get.snackbar(
          'تحذير',
          'يرجى إكمال بيانات البروفايل أولاً',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }

      // التحقق من موافقة الإدارة
      final isApproved = await profileService.isDriverApproved(userId);
      if (!isApproved) {
        Get.snackbar(
          'تحذير',
          'حسابك قيد المراجعة من قبل الإدارة. سيتم إشعارك عند الموافقة.',
          snackPosition: SnackPosition.BOTTOM,
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

  /// تحميل حالة السائق
  Future<void> _loadDriverStatus() async {
    try {
      final driverId = authController.currentUser.value?.id;
      if (driverId == null) return;

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(driverId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final additionalData = data['additionalData'] as Map<String, dynamic>?;

        isOnline.value = additionalData?['isOnline'] ?? false;
        isAvailable.value = additionalData?['isAvailable'] ?? true;

        if (additionalData?['currentLat'] != null &&
            additionalData?['currentLng'] != null) {
          currentLocation.value = LatLng(
            additionalData!['currentLat'].toDouble(),
            additionalData['currentLng'].toDouble(),
          );
        }
      }
    } catch (e) {
      logger.w('خطأ في تحميل حالة السائق: $e');
    }
  }

  /// التحقق من وجود رحلة نشطة
  Future<void> _checkActiveTrip() async {
    try {
      final driverId = authController.currentUser.value?.id;
      if (driverId == null) return;

      QuerySnapshot querySnapshot = await _firestore
          .collection('trips')
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: ['accepted', 'driverArrived', 'inProgress'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        TripModel trip = TripModel.fromMap(
            querySnapshot.docs.first.data() as Map<String, dynamic>);
        currentTrip.value = trip;
        isOnTrip.value = true;
        _startCurrentTripListener(trip.id);
      }
    } catch (e) {
      logger.w('خطأ في التحقق من الرحلة النشطة: $e');
    }
  }

  /// تبديل حالة الاتصال
  Future<void> toggleOnlineStatus() async {
    try {
      // التحقق من اكتمال البروفايل قبل التبديل
      final canReceiveRequests = await _checkProfileCompletion();
      if (!canReceiveRequests) {
        return;
      }

      final driverId = authController.currentUser.value?.id;
      if (driverId == null) return;

      final newStatus = !isOnline.value;

      if (newStatus) {
        // تشغيل الوضع المتصل
        LatLng? location = await locationService.getCurrentLocation();
        if (location == null) {
          Get.snackbar(
            'خطأ',
            'لا يمكن الحصول على موقعك الحالي',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        currentLocation.value = location;

        await _firestore.collection('users').doc(driverId).update({
          'additionalData.isOnline': true,
          'additionalData.isAvailable': true,
          'additionalData.currentLat': location.latitude,
          'additionalData.currentLng': location.longitude,
          'additionalData.lastSeen': DateTime.now(),
        });

        isOnline.value = true;
        isAvailable.value = true;

        _startListeningForRequests();
        _startLocationUpdates();

        Get.snackbar(
          'متصل',
          'أصبحت متاحاً لاستقبال الطلبات',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // إيقاف الوضع المتصل
        await _firestore.collection('users').doc(driverId).update({
          'additionalData.isOnline': false,
          'additionalData.isAvailable': false,
          'additionalData.lastSeen': DateTime.now(),
        });

        isOnline.value = false;
        isAvailable.value = false;

        _stopListeningForRequests();
        _stopLocationUpdates();
        tripRequests.clear();

        Get.snackbar(
          'غير متصل',
          'توقفت عن استقبال الطلبات',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.grey,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      logger.w('خطأ في تغيير حالة الاتصال: $e');
      Get.snackbar(
        'خطأ',
        'تعذر تغيير الحالة، يرجى المحاولة مرة أخرى',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// بدء الاستماع لطلبات الرحلات
  void _startListeningForRequests() {
    final driverId = authController.currentUser.value?.id;
    if (driverId == null) return;

    _tripRequestsSubscription = _firestore
        .collection('trip_requests')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      _handleTripRequestsSnapshot(snapshot);
    });
  }

  /// إيقاف الاستماع لطلبات الرحلات
  void _stopListeningForRequests() {
    _tripRequestsSubscription?.cancel();
    _tripRequestsSubscription = null;
  }

  /// معالجة طلبات الرحلات
  void _handleTripRequestsSnapshot(QuerySnapshot snapshot) async {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final requestData = change.doc.data() as Map<String, dynamic>;
        final tripId = requestData['tripId'];

        // تحقق من أن الطلب لم يتم رفضه مسبقاً
        if (declinedTrips.contains(tripId)) continue;

        // تحقق من انتهاء صلاحية الطلب
        final expiresAt = (requestData['expiresAt'] as DateTime);
        if (DateTime.now().isAfter(expiresAt)) continue;

        // جلب تفاصيل الرحلة
        try {
          DocumentSnapshot tripDoc =
              await _firestore.collection('trips').doc(tripId).get();

          if (tripDoc.exists &&
              (tripDoc.data() as Map<String, dynamic>)['status'] == 'pending') {
            TripModel trip =
                TripModel.fromMap(tripDoc.data() as Map<String, dynamic>);

            // إضافة الطلب إلى القائمة
            if (!tripRequests.any((t) => t.id == trip.id)) {
              tripRequests.add(trip);
              _showTripRequestNotification(trip);
            }
          }
        } catch (e) {
          logger.w('خطأ في جلب تفاصيل الرحلة: $e');
        }
      }
    }
  }

  /// عرض إشعار طلب الرحلة
  void _showTripRequestNotification(TripModel trip) {
    Get.dialog(
      DriverTripRequestDialog(
        trip: trip,
        onAccept: () => _acceptTrip(trip),
        onDecline: () => _declineTrip(trip),
      ),
      barrierDismissible: false,
    );
  }

  /// قبول طلب الرحلة
  Future<void> acceptTrip(TripModel trip) async {
    try {
      // التحقق من اكتمال البروفايل قبل قبول الرحلة
      final canReceiveRequests = await _checkProfileCompletion();
      if (!canReceiveRequests) {
        return;
      }

      // التحقق من أن السائق متصل ومتاح
      if (!isOnline.value || !isAvailable.value) {
        Get.snackbar(
          'غير متاح',
          'يجب أن تكون متصلاً ومتاحاً لقبول الرحلات',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await _acceptTrip(trip);
    } catch (e) {
      logger.w('خطأ في قبول الرحلة: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء قبول الرحلة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// رفض طلب الرحلة
  Future<void> declineTrip(TripModel trip) async {
    try {
      final driverId = authController.currentUser.value?.id;
      if (driverId == null) return;

      // إضافة الرحلة للقائمة المرفوضة
      declinedTrips.add(trip.id);

      // حذف طلب السائق
      await _firestore
          .collection('trip_requests')
          .doc('${trip.id}_$driverId')
          .delete();

      // إزالة من القائمة المحلية
      tripRequests.removeWhere((t) => t.id == trip.id);
    } catch (e) {
      logger.w('خطأ في رفض الرحلة: $e');
    }
  }

  /// قبول طلب الرحلة
  Future<void> _acceptTrip(TripModel trip) async {
    try {
      final driverId = authController.currentUser.value?.id;
      if (driverId == null) return;

      // تحديث حالة الرحلة
      await _firestore.collection('trips').doc(trip.id).update({
        'driverId': driverId,
        'status': TripStatus.accepted.name,
        'acceptedAt': DateTime.now(),
      });

      // تحديث طلب السائق
      await _firestore
          .collection('trip_requests')
          .doc('${trip.id}_$driverId')
          .update({'status': 'accepted'});

      // حذف باقي طلبات هذه الرحلة
      QuerySnapshot otherRequests = await _firestore
          .collection('trip_requests')
          .where('tripId', isEqualTo: trip.id)
          .where('driverId', isNotEqualTo: driverId)
          .get();

      for (var doc in otherRequests.docs) {
        await doc.reference.delete();
      }

      // تحديث حالة السائق
      await _firestore.collection('users').doc(driverId).update({
        'additionalData.isAvailable': false,
      });

      // تحديث الحالة المحلية
      currentTrip.value = trip.copyWith(
        driverId: driverId,
        status: TripStatus.accepted,
        acceptedAt: DateTime.now(),
      );
      isOnTrip.value = true;
      isAvailable.value = false;
      tripRequests.clear();

      _startCurrentTripListener(trip.id);

      Get.snackbar(
        'تم قبول الرحلة',
        'توجه إلى موقع الراكب',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // الانتقال لشاشة تتبع الرحلة
      Get.toNamed(AppRoutes.DRIVER_TRIP_TRACKING);
    } catch (e) {
      logger.w('خطأ في قبول الرحلة: $e');
      Get.snackbar(
        'خطأ',
        'تعذر قبول الرحلة، يرجى المحاولة مرة أخرى',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// رفض طلب الرحلة
  Future<void> _declineTrip(TripModel trip) async {
    try {
      final driverId = authController.currentUser.value?.id;
      if (driverId == null) return;

      // إضافة الرحلة للقائمة المرفوضة
      declinedTrips.add(trip.id);

      // حذف طلب السائق
      await _firestore
          .collection('trip_requests')
          .doc('${trip.id}_$driverId')
          .delete();

      // إزالة من القائمة المحلية
      tripRequests.removeWhere((t) => t.id == trip.id);
    } catch (e) {
      logger.w('خطأ في رفض الرحلة: $e');
    }
  }

  /// بدء الاستماع للرحلة الحالية
  void _startCurrentTripListener(String tripId) {
    _currentTripSubscription?.cancel();

    _currentTripSubscription = _firestore
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        TripModel trip =
            TripModel.fromMap(snapshot.data() as Map<String, dynamic>);
        currentTrip.value = trip;

        // إذا تم إنهاء الرحلة أو إلغاؤها
        if (trip.status == TripStatus.completed ||
            trip.status == TripStatus.cancelled) {
          _handleTripEnded(trip);
        }
      }
    });
  }

  /// إعلام وصول السائق
  Future<void> notifyArrival() async {
    try {
      if (currentTrip.value == null) return;

      await _firestore.collection('trips').doc(currentTrip.value!.id).update({
        'status': TripStatus.driverArrived.name,
      });

      Get.snackbar(
        'تم الإعلام',
        'تم إعلام الراكب بوصولك',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.w('خطأ في إعلام الوصول: $e');
    }
  }

  /// إعلام وصول السائق (اسم بديل)
  Future<void> markAsArrived() async {
    return notifyArrival();
  }

  /// بدء الرحلة
  Future<void> startTrip() async {
    try {
      if (currentTrip.value == null) return;

      await _firestore.collection('trips').doc(currentTrip.value!.id).update({
        'status': TripStatus.inProgress.name,
        'startedAt': DateTime.now(),
      });

      Get.snackbar(
        'بدأت الرحلة',
        'جاري التوجه إلى الوجهة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.purple,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.w('خطأ في بدء الرحلة: $e');
    }
  }

  /// إنهاء الرحلة
  Future<void> completeTrip() async {
    try {
      if (currentTrip.value == null) return;

      await _firestore.collection('trips').doc(currentTrip.value!.id).update({
        'status': TripStatus.completed.name,
        'completedAt': DateTime.now(),
      });

      Get.snackbar(
        'تمت الرحلة',
        'تم إنهاء الرحلة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.w('خطأ في إنهاء الرحلة: $e');
    }
  }

  /// إنهاء الرحلة (اسم بديل)
  Future<void> endTrip() async {
    try {
      isOnTrip.value = false;
      isAvailable.value = true;

      Get.snackbar(
        'تم إنهاء الرحلة',
        'تم إنهاء الرحلة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // العودة للشاشة الرئيسية
      Get.offAllNamed(AppRoutes.DRIVER_HOME);
    } catch (e) {
      logger.w('خطأ في إنهاء الرحلة: $e');
    }
  }

  /// التعامل مع انتهاء الرحلة
  Future<void> _handleTripEnded(TripModel trip) async {
    try {
      final driverId = authController.currentUser.value?.id;
      if (driverId == null) return;

      // تحديث رصيد السائق إذا تمت الرحلة
      if (trip.status == TripStatus.completed) {
        double driverShare = trip.fare * 0.8; // 80% للسائق
        await authController.updateBalance(driverShare);

        // تحديث الإحصائيات
        todayEarnings.value += driverShare;
        completedTripsToday.value++;
      }

      // إعادة تعيين الحالة
      currentTrip.value = null;
      isOnTrip.value = false;

      // إعادة السائق للوضع المتاح
      await _firestore.collection('users').doc(driverId).update({
        'additionalData.isAvailable': true,
      });

      isAvailable.value = true;

      // إضافة الرحلة للتاريخ
      tripHistory.insert(0, trip);

      _currentTripSubscription?.cancel();

      // العودة للشاشة الرئيسية
      Get.offAllNamed(AppRoutes.DRIVER_HOME);
    } catch (e) {
      logger.w('خطأ في معالجة انتهاء الرحلة: $e');
    }
  }

  /// بدء تحديثات الموقع
  void _startLocationUpdates() {
    _locationUpdateTimer?.cancel();

    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (isOnline.value) {
        await _updateDriverLocation();
      }
    });
  }

  /// إيقاف تحديثات الموقع
  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  /// تحديث موقع السائق
  Future<void> _updateDriverLocation() async {
    try {
      final driverId = authController.currentUser.value?.id;
      if (driverId == null) return;

      LatLng? location = await locationService.getCurrentLocation();
      if (location != null) {
        currentLocation.value = location;

        await _firestore.collection('users').doc(driverId).update({
          'additionalData.currentLat': location.latitude,
          'additionalData.currentLng': location.longitude,
          'additionalData.lastSeen': DateTime.now(),
        });
      }
    } catch (e) {
      logger.w('خطأ في تحديث الموقع: $e');
    }
  }

  /// تحميل بيانات الأرباح (public method)
  Future<void> loadEarningsData() async {
    await _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    try {
      final driverId = authController.currentUser.value?.id;
      if (driverId == null) return;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // أرباح اليوم
      QuerySnapshot todayTrips = await _firestore
          .collection('trips')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: TripStatus.completed.name)
          .where('completedAt', isGreaterThanOrEqualTo: todayStart)
          .get();

      double todayTotal = 0.0;
      int todayCount = 0;
      for (var doc in todayTrips.docs) {
        final data = doc.data() as Map<String, dynamic>;
        todayTotal += (data['fare'] as double) * 0.8;
        todayCount++;
      }

      todayEarnings.value = todayTotal;
      completedTripsToday.value = todayCount;

      // أرباح الأسبوع
      QuerySnapshot weekTrips = await _firestore
          .collection('trips')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: TripStatus.completed.name)
          .where('completedAt', isGreaterThanOrEqualTo: weekStart)
          .get();

      double weekTotal = 0.0;
      for (var doc in weekTrips.docs) {
        final data = doc.data() as Map<String, dynamic>;
        weekTotal += (data['fare'] as double) * 0.8;
      }

      weekEarnings.value = weekTotal;

      // أرباح الشهر
      QuerySnapshot monthTrips = await _firestore
          .collection('trips')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: TripStatus.completed.name)
          .where('completedAt', isGreaterThanOrEqualTo: monthStart)
          .get();

      double monthTotal = 0.0;
      for (var doc in monthTrips.docs) {
        final data = doc.data() as Map<String, dynamic>;
        monthTotal += (data['fare'] as double) * 0.8;
      }

      monthEarnings.value = monthTotal;
    } catch (e) {
      logger.w('خطأ في تحميل بيانات الأرباح: $e');
    }
  }

  /// تحميل تاريخ الرحلات
  Future<void> loadTripHistory() async {
    final driverId = authController.currentUser.value?.id;
    if (driverId == null) return;

    try {
      isLoadingHistory.value = true;

      QuerySnapshot querySnapshot = await _firestore
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
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingHistory.value = false;
    }
  }

  /// حساب إحصائيات السائق
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
      'rating': 4.5, // سيتم حسابه من التقييمات لاحقاً
    };
  }

  @override
  void onClose() {
    _tripRequestsSubscription?.cancel();
    _currentTripSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    super.onClose();
  }
}
