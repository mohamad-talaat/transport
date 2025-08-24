import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../models/trip_model.dart';
import '../models/user_model.dart';
import '../models/payment_model.dart';
import '../models/discount_code_model.dart';
import '../main.dart';

class FirebaseService extends GetxService {
  static FirebaseService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream controllers for real-time updates
  final StreamController<List<TripModel>> _tripRequestsController =
      StreamController<List<TripModel>>.broadcast();
  final StreamController<TripModel?> _currentTripController =
      StreamController<TripModel?>.broadcast();
  final StreamController<List<DriverModel>> _availableDriversController =
      StreamController<List<DriverModel>>.broadcast();

  // Reactive variables
  final RxList<TripModel> tripRequests = <TripModel>[].obs;
  final Rx<TripModel?> currentTrip = Rx<TripModel?>(null);
  final RxList<DriverModel> availableDrivers = <DriverModel>[].obs;
  final RxBool isLoading = false.obs;

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _tripRequestsSubscription;
  StreamSubscription<DocumentSnapshot>? _currentTripSubscription;
  StreamSubscription<QuerySnapshot>? _availableDriversSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeStreams();
  }

  /// تهيئة Streams للبيانات المباشرة
  void _initializeStreams() {
    // Stream للطلبات الجديدة
    _tripRequestsController.stream.listen((requests) {
      tripRequests.value = requests;
    });

    // Stream للرحلة الحالية
    _currentTripController.stream.listen((trip) {
      currentTrip.value = trip;
    });

    // Stream للسائقين المتاحين
    _availableDriversController.stream.listen((drivers) {
      availableDrivers.value = drivers;
    });
  }

  /// بدء الاستماع لطلبات الرحلات للسائق
  void startListeningForTripRequests(String driverId) {
    _tripRequestsSubscription?.cancel();

    _tripRequestsSubscription = _firestore
        .collection('trip_requests')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      _handleTripRequestsUpdate(snapshot);
    });
  }

  /// معالجة تحديثات طلبات الرحلات
  Future<void> _handleTripRequestsUpdate(QuerySnapshot snapshot) async {
    List<TripModel> requests = [];

    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final requestData = change.doc.data() as Map<String, dynamic>;
        final tripId = requestData['tripId'];

        try {
          // جلب تفاصيل الرحلة
          DocumentSnapshot tripDoc =
              await _firestore.collection('trips').doc(tripId).get();

          if (tripDoc.exists) {
            final tripData = tripDoc.data() as Map<String, dynamic>;
            if (tripData['status'] == 'pending') {
              TripModel trip = TripModel.fromMap(tripData);
              requests.add(trip);
            }
          }
        } catch (e) {
          logger.w('خطأ في جلب تفاصيل الرحلة: $e');
        }
      }
    }

    _tripRequestsController.add(requests);
  }

  /// بدء الاستماع للرحلة الحالية
  void startListeningForCurrentTrip(String tripId) {
    _currentTripSubscription?.cancel();

    _currentTripSubscription = _firestore
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        TripModel trip =
            TripModel.fromMap(snapshot.data() as Map<String, dynamic>);
        _currentTripController.add(trip);
      } else {
        _currentTripController.add(null);
      }
    });
  }

  /// بدء الاستماع للسائقين المتاحين
  void startListeningForAvailableDrivers() {
    _availableDriversSubscription?.cancel();

    _availableDriversSubscription = _firestore
        .collection('users')
        .where('userType', isEqualTo: 'driver')
        .where('additionalData.isOnline', isEqualTo: true)
        .where('additionalData.isAvailable', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      List<DriverModel> drivers = [];

      for (var doc in snapshot.docs) {
        try {
          DriverModel driver = DriverModel.fromMap(doc.data());
          drivers.add(driver);
        } catch (e) {
          logger.w('خطأ في تحويل بيانات السائق: $e');
        }
      }

      _availableDriversController.add(drivers);
    });
  }

  /// إنشاء طلب رحلة جديد
  Future<TripModel> createTripRequest({
    required String riderId,
    required LocationPoint pickup,
    required LocationPoint destination,
    required double fare,
    required double distance,
    required int estimatedDuration,
    required List<LatLng> routePolyline,
  }) async {
    try {
      isLoading.value = true;

      String tripId = _firestore.collection('trips').doc().id;

      TripModel newTrip = TripModel(
        id: tripId,
        riderId: riderId,
        pickupLocation: pickup,
        destinationLocation: destination,
        fare: fare,
        distance: distance,
        estimatedDuration: estimatedDuration,
        createdAt: DateTime.now(),
        routePolyline: routePolyline,
      );

      await _firestore.collection('trips').doc(tripId).set(newTrip.toMap());

      return newTrip;
    } catch (e) {
      logger.w('خطأ في إنشاء طلب الرحلة: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// إرسال طلبات للسائقين المتاحين
  Future<void> sendTripRequestsToDrivers({
    required String tripId,
    required String riderId,
    required List<DriverModel> nearbyDrivers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final expiresAt = DateTime.now().add(timeout);

      for (DriverModel driver in nearbyDrivers) {
        await _firestore
            .collection('trip_requests')
            .doc('${tripId}_${driver.id}')
            .set({
          'tripId': tripId,
          'driverId': driver.id,
          'riderId': riderId,
          'status': 'pending',
          'createdAt': Timestamp.now(),
          'expiresAt': Timestamp.fromDate(expiresAt),
        });
      }
    } catch (e) {
      logger.w('خطأ في إرسال طلبات السائقين: $e');
      rethrow;
    }
  }

  /// قبول طلب الرحلة
  Future<void> acceptTripRequest({
    required String tripId,
    required String driverId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // تحديث حالة الرحلة
        final tripRef = _firestore.collection('trips').doc(tripId);
        transaction.update(tripRef, {
          'driverId': driverId,
          'status': TripStatus.accepted.name,
          'acceptedAt': Timestamp.now(),
        });

        // تحديث طلب السائق
        final requestRef =
            _firestore.collection('trip_requests').doc('${tripId}_$driverId');
        transaction.update(requestRef, {'status': 'accepted'});

        // حذف باقي طلبات هذه الرحلة
        final otherRequestsQuery = _firestore
            .collection('trip_requests')
            .where('tripId', isEqualTo: tripId)
            .where('driverId', isNotEqualTo: driverId);

        final otherRequestsSnapshot = await otherRequestsQuery.get();
        for (var doc in otherRequestsSnapshot.docs) {
          transaction.delete(doc.reference);
        }

        // تحديث حالة السائق
        final driverRef = _firestore.collection('users').doc(driverId);
        transaction.update(driverRef, {
          'additionalData.isAvailable': false,
        });
      });
    } catch (e) {
      logger.w('خطأ في قبول طلب الرحلة: $e');
      rethrow;
    }
  }

  /// رفض طلب الرحلة
  Future<void> declineTripRequest({
    required String tripId,
    required String driverId,
  }) async {
    try {
      await _firestore
          .collection('trip_requests')
          .doc('${tripId}_$driverId')
          .delete();
    } catch (e) {
      logger.w('خطأ في رفض طلب الرحلة: $e');
      rethrow;
    }
  }

  /// تحديث حالة الرحلة
  Future<void> updateTripStatus({
    required String tripId,
    required TripStatus status,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status.name,
        'updatedAt': Timestamp.now(),
      };

      if (additionalData != null) {
        updateData.addAll(additionalData);
      }

      await _firestore.collection('trips').doc(tripId).update(updateData);
    } catch (e) {
      logger.w('خطأ في تحديث حالة الرحلة: $e');
      rethrow;
    }
  }

  /// تحديث موقع السائق
  Future<void> updateDriverLocation({
    required String driverId,
    required LatLng location,
  }) async {
    try {
      await _firestore.collection('users').doc(driverId).update({
        'additionalData.currentLat': location.latitude,
        'additionalData.currentLng': location.longitude,
        'additionalData.lastSeen': Timestamp.now(),
      });
    } catch (e) {
      logger.w('خطأ في تحديث موقع السائق: $e');
      rethrow;
    }
  }

  /// جلب السائقين القريبين
  Future<List<DriverModel>> getNearbyDrivers({
    required LatLng center,
    required double radiusKm,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .where('additionalData.isOnline', isEqualTo: true)
          .where('additionalData.isAvailable', isEqualTo: true)
          .get();

      List<DriverModel> nearbyDrivers = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final additionalData =
              data['additionalData'] as Map<String, dynamic>?;

          if (additionalData?['currentLat'] != null &&
              additionalData?['currentLng'] != null) {
            final driverLat = additionalData!['currentLat'].toDouble();
            final driverLng = additionalData['currentLng'].toDouble();
            final driverLocation = LatLng(driverLat, driverLng);

            // حساب المسافة
            final distance = _calculateDistance(center, driverLocation);

            if (distance <= radiusKm) {
              DriverModel driver = DriverModel.fromMap(data);
              nearbyDrivers.add(driver);
            }
          }
        } catch (e) {
          logger.w('خطأ في تحويل بيانات السائق: $e');
        }
      }

      // ترتيب حسب المسافة
      nearbyDrivers.sort((a, b) {
        final distanceA =
            _calculateDistance(center, LatLng(a.currentLat!, a.currentLng!));
        final distanceB =
            _calculateDistance(center, LatLng(b.currentLat!, b.currentLng!));
        return distanceA.compareTo(distanceB);
      });

      return nearbyDrivers;
    } catch (e) {
      logger.w('خطأ في جلب السائقين القريبين: $e');
      return [];
    }
  }

  /// حساب المسافة بين نقطتين
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // نصف قطر الأرض بالكيلومتر

    final lat1Rad = point1.latitude * (pi / 180);
    final lat2Rad = point2.latitude * (pi / 180);
    final deltaLat = (point2.latitude - point1.latitude) * (pi / 180);
    final deltaLng = (point2.longitude - point1.longitude) * (pi / 180);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// إنشاء عملية دفع
  Future<PaymentModel> createPayment({
    required String userId,
    required String tripId,
    required double amount,
    required PaymentMethod method,
  }) async {
    try {
      final paymentId = 'payment_${DateTime.now().millisecondsSinceEpoch}';

      final payment = PaymentModel(
        id: paymentId,
        userId: userId,
        tripId: tripId,
        amount: amount,
        status: PaymentStatus.pending,
        method: method,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('payments')
          .doc(paymentId)
          .set(payment.toMap());

      return payment;
    } catch (e) {
      logger.w('خطأ في إنشاء عملية الدفع: $e');
      rethrow;
    }
  }

  /// استخدام كود الخصم
  Future<Map<String, dynamic>> redeemDiscountCode({
    required String code,
    required String userId,
  }) async {
    try {
      // البحث عن كود الخصم
      final discountQuery = await _firestore
          .collection('discount_codes')
          .where('code', isEqualTo: code.toUpperCase())
          .where('isUsed', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (discountQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'كود الخصم غير صحيح أو مستخدم من قبل',
        };
      }

      final discountDoc = discountQuery.docs.first;
      final discountData = discountDoc.data();
      final discountCode =
          DiscountCodeModel.fromMap(discountData, discountDoc.id);

      // التحقق من صلاحية الكود
      if (!discountCode.isValid) {
        return {
          'success': false,
          'message': 'كود الخصم منتهي الصلاحية أو غير صالح',
        };
      }

      // تطبيق الكود في معاملة واحدة
      await _firestore.runTransaction((transaction) async {
        // تحديث كود الخصم كمستخدم
        transaction.update(discountDoc.reference, {
          'isUsed': true,
          'usedBy': userId,
          'usedAt': FieldValue.serverTimestamp(),
        });

        // تحديث رصيد المستخدم
        final userRef = _firestore.collection('users').doc(userId);
        final userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists) {
          throw 'المستخدم غير موجود';
        }

        final currentBalance =
            (userSnapshot.data()?['balance'] ?? 0.0).toDouble();
        final discountAmount = discountCode.amount;
        final newBalance = currentBalance + discountAmount;

        transaction.update(userRef, {
          'balance': newBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });

      return {
        'success': true,
        'message': 'تم تطبيق كود الخصم بنجاح',
        'amount': discountCode.amount,
      };
    } catch (e) {
      logger.w('خطأ في استخدام كود الخصم: $e');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء تطبيق كود الخصم',
      };
    }
  }

  /// جلب إحصائيات السائق
  Future<Map<String, dynamic>> getDriverStatistics({
    required String driverId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      QuerySnapshot tripsSnapshot = await _firestore
          .collection('trips')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: TripStatus.completed.name)
          .where('completedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('completedAt',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double totalEarnings = 0.0;
      int completedTrips = 0;
      double totalDistance = 0.0;

      for (var doc in tripsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalEarnings += (data['fare'] ?? 0.0).toDouble() * 0.8; // 80% للسائق
        totalDistance += (data['distance'] ?? 0.0).toDouble();
        completedTrips++;
      }

      return {
        'totalEarnings': totalEarnings,
        'completedTrips': completedTrips,
        'totalDistance': totalDistance,
        'averageEarningsPerTrip':
            completedTrips > 0 ? totalEarnings / completedTrips : 0.0,
      };
    } catch (e) {
      logger.w('خطأ في جلب إحصائيات السائق: $e');
      return {
        'totalEarnings': 0.0,
        'completedTrips': 0,
        'totalDistance': 0.0,
        'averageEarningsPerTrip': 0.0,
      };
    }
  }

  /// إيقاف جميع الـ Streams
  void stopAllStreams() {
    _tripRequestsSubscription?.cancel();
    _currentTripSubscription?.cancel();
    _availableDriversSubscription?.cancel();
  }

  @override
  void onClose() {
    stopAllStreams();
    _tripRequestsController.close();
    _currentTripController.close();
    _availableDriversController.close();
    super.onClose();
  }
}
