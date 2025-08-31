import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/trip_model.dart';
import '../models/payment_model.dart';
import '../controllers/auth_controller.dart';
import '../controllers/trip_controller.dart';
import '../controllers/driver_controller.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../main.dart';

class SystemTestService extends GetxService {
  static SystemTestService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController authController = AuthController.to;
  final TripController tripController = TripController.to;
  final DriverController driverController = DriverController.to;
  final FirebaseService firebaseService = FirebaseService.to;
  final LocationService locationService = LocationService.to;

  // نتائج الاختبارات
  final RxMap<String, bool> testResults = <String, bool>{}.obs;
  final RxList<String> testLogs = <String>[].obs;
  final RxBool isTesting = false.obs;

  /// تشغيل جميع الاختبارات
  Future<Map<String, bool>> runAllTests() async {
    isTesting.value = true;
    testResults.clear();
    testLogs.clear();

    try {
      _log('بدء اختبار النظام الشامل...');

      // اختبارات Firebase
      await _testFirebaseConnection();
      await _testFirebaseCollections();

      // اختبارات البحث عن السائقين
      await _testDriverSearch();
      await _testDriverAvailability();

      // اختبارات طلبات الرحلات
      await _testTripRequests();
      await _testTripAcceptance();

      // اختبارات تتبع الرحلات
      await _testTripTracking();
      await _testTripCompletion();

      // اختبارات الدفع
      await _testPaymentSystem();
      await _testDiscountCodes();

      // اختبارات الأداء
      await _testPerformance();
      await _testRealTimeUpdates();

      _log('تم الانتهاء من جميع الاختبارات');
    } catch (e) {
      _log('خطأ في الاختبارات: $e');
    } finally {
      isTesting.value = false;
    }

    return testResults;
  }

  /// اختبار الاتصال بـ Firebase
  Future<void> _testFirebaseConnection() async {
    try {
      _log('اختبار الاتصال بـ Firebase...');

      await _firestore.collection('test').doc('connection').set({
        'timestamp': Timestamp.now(),
        'test': true,
      });

      await _firestore.collection('test').doc('connection').delete();

      testResults['firebase_connection'] = true;
      _log('✅ نجح اختبار الاتصال بـ Firebase');
    } catch (e) {
      testResults['firebase_connection'] = false;
      _log('❌ فشل اختبار الاتصال بـ Firebase: $e');
    }
  }

  /// اختبار المجموعات في Firebase
  Future<void> _testFirebaseCollections() async {
    try {
      _log('اختبار مجاميع Firebase...');

      final collections = [
        'users',
        'trips',
        'trip_requests',
        'payments',
        'discount_codes'
      ];
      bool allCollectionsExist = true;

      for (String collection in collections) {
        try {
          await _firestore.collection(collection).limit(1).get();
        } catch (e) {
          allCollectionsExist = false;
          _log('❌ مجموعة $collection غير موجودة: $e');
        }
      }

      testResults['firebase_collections'] = allCollectionsExist;
      if (allCollectionsExist) {
        _log('✅ جميع مجاميع Firebase موجودة');
      }
    } catch (e) {
      testResults['firebase_collections'] = false;
      _log('❌ فشل اختبار مجاميع Firebase: $e');
    }
  }

  /// اختبار البحث عن السائقين
  Future<void> _testDriverSearch() async {
    try {
      _log('اختبار البحث عن السائقين...');

      // إنشاء موقع اختباري
      const testLocation = LatLng(30.0444, 31.2357); // القاهرة

      // البحث عن السائقين القريبين
      final nearbyDrivers = await firebaseService.getNearbyDrivers(
        center: testLocation,
        radiusKm: 5.0,
      );

      testResults['driver_search'] = true;
      _log(
          '✅ نجح اختبار البحث عن السائقين - تم العثور على ${nearbyDrivers.length} سائق');
    } catch (e) {
      testResults['driver_search'] = false;
      _log('❌ فشل اختبار البحث عن السائقين: $e');
    }
  }

  /// اختبار توفر السائقين
  Future<void> _testDriverAvailability() async {
    try {
      _log('اختبار توفر السائقين...');

      // جلب السائقين المتصلين
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .where('additionalData.isOnline', isEqualTo: true)
          .where('additionalData.isAvailable', isEqualTo: true)
          .limit(5)
          .get();

      testResults['driver_availability'] = true;
      _log('✅ نجح اختبار توفر السائقين - ${snapshot.docs.length} سائق متاح');
    } catch (e) {
      testResults['driver_availability'] = false;
      _log('❌ فشل اختبار توفر السائقين: $e');
    }
  }

  /// اختبار طلبات الرحلات
  Future<void> _testTripRequests() async {
    try {
      _log('اختبار طلبات الرحلات...');

      // إنشاء رحلة اختبارية
      final testTrip = TripModel(
        id: 'test_trip_${DateTime.now().millisecondsSinceEpoch}',
        riderId: 'test_rider',
        pickupLocation: LocationPoint(
          lat: 30.0444,
          lng: 31.2357,
          address: 'موقع اختباري - القاهرة',
        ),
        destinationLocation: LocationPoint(
          lat: 30.0561,
          lng: 31.2394,
          address: 'وجهة اختبارية - القاهرة',
        ),
        fare: 25.0,
        distance: 2.5,
        estimatedDuration: 15,
        createdAt: DateTime.now(),
      );

      // حفظ الرحلة
      await _firestore
          .collection('trips')
          .doc(testTrip.id)
          .set(testTrip.toMap());

      // التحقق من حفظ الرحلة
      DocumentSnapshot doc =
          await _firestore.collection('trips').doc(testTrip.id).get();

      if (doc.exists) {
        testResults['trip_requests'] = true;
        _log('✅ نجح اختبار طلبات الرحلات');

        // حذف الرحلة الاختبارية
        await _firestore.collection('trips').doc(testTrip.id).delete();
      } else {
        testResults['trip_requests'] = false;
        _log('❌ فشل في حفظ الرحلة الاختبارية');
      }
    } catch (e) {
      testResults['trip_requests'] = false;
      _log('❌ فشل اختبار طلبات الرحلات: $e');
    }
  }

  /// اختبار قبول الرحلات
  Future<void> _testTripAcceptance() async {
    try {
      _log('اختبار قبول الرحلات...');

      // إنشاء رحلة اختبارية
      final testTripId =
          'test_acceptance_${DateTime.now().millisecondsSinceEpoch}';
      final testDriverId =
          'test_driver_${DateTime.now().millisecondsSinceEpoch}';

      await _firestore.collection('trips').doc(testTripId).set({
        'id': testTripId,
        'riderId': 'test_rider',
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      // محاكاة قبول الرحلة
      await firebaseService.acceptTripRequest(
        tripId: testTripId,
        driverId: testDriverId,
      );

      // التحقق من تحديث الحالة
      DocumentSnapshot tripDoc =
          await _firestore.collection('trips').doc(testTripId).get();
      final tripData = tripDoc.data() as Map<String, dynamic>?;

      if (tripData != null && tripData['status'] == 'accepted') {
        testResults['trip_acceptance'] = true;
        _log('✅ نجح اختبار قبول الرحلات');
      } else {
        testResults['trip_acceptance'] = false;
        _log('❌ فشل في تحديث حالة الرحلة');
      }

      // تنظيف البيانات الاختبارية
      await _firestore.collection('trips').doc(testTripId).delete();
    } catch (e) {
      testResults['trip_acceptance'] = false;
      _log('❌ فشل اختبار قبول الرحلات: $e');
    }
  }

  /// اختبار تتبع الرحلات
  Future<void> _testTripTracking() async {
    try {
      _log('اختبار تتبع الرحلات...');

      // اختبار تحديث موقع السائق
      const testLocation = LatLng(30.0444, 31.2357);
      const testDriverId = 'test_driver_tracking';

      await firebaseService.updateDriverLocation(
        driverId: testDriverId,
        location: testLocation,
      );

      // التحقق من تحديث الموقع
      DocumentSnapshot driverDoc =
          await _firestore.collection('users').doc(testDriverId).get();

      if (driverDoc.exists) {
        final data = driverDoc.data() as Map<String, dynamic>;
        final additionalData = data['additionalData'] as Map<String, dynamic>?;

        if (additionalData?['currentLat'] == testLocation.latitude &&
            additionalData?['currentLng'] == testLocation.longitude) {
          testResults['trip_tracking'] = true;
          _log('✅ نجح اختبار تتبع الرحلات');
        } else {
          testResults['trip_tracking'] = false;
          _log('❌ فشل في تحديث موقع السائق');
        }
      } else {
        testResults['trip_tracking'] = false;
        _log('❌ السائق الاختباري غير موجود');
      }
    } catch (e) {
      testResults['trip_tracking'] = false;
      _log('❌ فشل اختبار تتبع الرحلات: $e');
    }
  }

  /// اختبار إنهاء الرحلات
  Future<void> _testTripCompletion() async {
    try {
      _log('اختبار إنهاء الرحلات...');

      final testTripId =
          'test_completion_${DateTime.now().millisecondsSinceEpoch}';

      // إنشاء رحلة اختبارية
      await _firestore.collection('trips').doc(testTripId).set({
        'id': testTripId,
        'riderId': 'test_rider',
        'driverId': 'test_driver',
        'status': 'inProgress',
        'fare': 25.0,
        'createdAt': Timestamp.now(),
      });

      // محاكاة إنهاء الرحلة
      await firebaseService.updateTripStatus(
        tripId: testTripId,
        status: TripStatus.completed,
        additionalData: {
          'completedAt': Timestamp.now(),
          'finalFare': 25.0,
        },
      );

      // التحقق من إنهاء الرحلة
      DocumentSnapshot tripDoc =
          await _firestore.collection('trips').doc(testTripId).get();
      final tripData = tripDoc.data() as Map<String, dynamic>?;

      if (tripData != null && tripData['status'] == 'completed') {
        testResults['trip_completion'] = true;
        _log('✅ نجح اختبار إنهاء الرحلات');
      } else {
        testResults['trip_completion'] = false;
        _log('❌ فشل في إنهاء الرحلة');
      }

      // تنظيف البيانات الاختبارية
      await _firestore.collection('trips').doc(testTripId).delete();
    } catch (e) {
      testResults['trip_completion'] = false;
      _log('❌ فشل اختبار إنهاء الرحلات: $e');
    }
  }

  /// اختبار نظام الدفع
  Future<void> _testPaymentSystem() async {
    try {
      _log('اختبار نظام الدفع...');

      final testPayment = await firebaseService.createPayment(
        userId: 'test_user',
        tripId: 'test_trip',
        amount: 25.0,
        method: PaymentMethod.wallet,
      );

      if (testPayment.id.isNotEmpty) {
        testResults['payment_system'] = true;
        _log('✅ نجح اختبار نظام الدفع');

        // حذف عملية الدفع الاختبارية
        await _firestore.collection('payments').doc(testPayment.id).delete();
      } else {
        testResults['payment_system'] = false;
        _log('❌ فشل في إنشاء عملية الدفع');
      }
    } catch (e) {
      testResults['payment_system'] = false;
      _log('❌ فشل اختبار نظام الدفع: $e');
    }
  }

  /// اختبار أكواد الخصم
  Future<void> _testDiscountCodes() async {
    try {
      _log('اختبار أكواد الخصم...');

      // إنشاء كود خصم اختباري
      final testCodeId =
          'test_discount_${DateTime.now().millisecondsSinceEpoch}';
      await _firestore.collection('discount_codes').doc(testCodeId).set({
        'code': 'TEST123',
        'amount': 10.0,
        'isUsed': false,
        'isActive': true,
        'createdAt': Timestamp.now(),
        'expiresAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      });

      // اختبار استخدام الكود
      final result = await firebaseService.redeemDiscountCode(
        code: 'TEST123',
        userId: 'test_user',
      );

      if (result['success']) {
        testResults['discount_codes'] = true;
        _log('✅ نجح اختبار أكواد الخصم');
      } else {
        testResults['discount_codes'] = false;
        _log('❌ فشل في استخدام كود الخصم: ${result['message']}');
      }

      // تنظيف البيانات الاختبارية
      await _firestore.collection('discount_codes').doc(testCodeId).delete();
    } catch (e) {
      testResults['discount_codes'] = false;
      _log('❌ فشل اختبار أكواد الخصم: $e');
    }
  }

  /// اختبار الأداء
  Future<void> _testPerformance() async {
    try {
      _log('اختبار الأداء...');

      final stopwatch = Stopwatch()..start();

      // اختبار سرعة جلب البيانات
      await _firestore.collection('users').limit(10).get();
      await _firestore.collection('trips').limit(10).get();

      stopwatch.stop();

      if (stopwatch.elapsedMilliseconds < 5000) {
        // أقل من 5 ثواني
        testResults['performance'] = true;
        _log('✅ نجح اختبار الأداء - ${stopwatch.elapsedMilliseconds}ms');
      } else {
        testResults['performance'] = false;
        _log('❌ بطء في الأداء - ${stopwatch.elapsedMilliseconds}ms');
      }
    } catch (e) {
      testResults['performance'] = false;
      _log('❌ فشل اختبار الأداء: $e');
    }
  }

  /// اختبار التحديثات المباشرة
  Future<void> _testRealTimeUpdates() async {
    try {
      _log('اختبار التحديثات المباشرة...');

      bool updateReceived = false;
      Timer? timeoutTimer;

      // بدء الاستماع للتحديثات
      final subscription =
          _firestore.collection('test_updates').snapshots().listen((snapshot) {
        updateReceived = true;
        timeoutTimer?.cancel();
      });

      // إنشاء تحديث اختباري
      await _firestore.collection('test_updates').add({
        'timestamp': Timestamp.now(),
        'test': true,
      });

      // انتظار التحديث لمدة 5 ثواني
      timeoutTimer = Timer(const Duration(seconds: 5), () {
        subscription.cancel();
      });

      await Future.delayed(const Duration(seconds: 6));

      if (updateReceived) {
        testResults['realtime_updates'] = true;
        _log('✅ نجح اختبار التحديثات المباشرة');
      } else {
        testResults['realtime_updates'] = false;
        _log('❌ فشل في استقبال التحديثات المباشرة');
      }

      subscription.cancel();

      // تنظيف البيانات الاختبارية
      QuerySnapshot testDocs =
          await _firestore.collection('test_updates').get();
      for (var doc in testDocs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      testResults['realtime_updates'] = false;
      _log('❌ فشل اختبار التحديثات المباشرة: $e');
    }
  }

  /// الحصول على تقرير الاختبارات
  Map<String, dynamic> getTestReport() {
    final passedTests = testResults.values.where((result) => result).length;
    final totalTests = testResults.length;
    final successRate = totalTests > 0 ? (passedTests / totalTests) * 100 : 0;

    return {
      'total_tests': totalTests,
      'passed_tests': passedTests,
      'failed_tests': totalTests - passedTests,
      'success_rate': successRate,
      'results': testResults,
      'logs': testLogs,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// تسجيل رسالة في سجل الاختبارات
  void _log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    testLogs.add(logMessage);
    logger.i(logMessage);
  }

  /// تنظيف البيانات الاختبارية
  Future<void> cleanupTestData() async {
    try {
      _log('تنظيف البيانات الاختبارية...');

      // حذف الرحلات الاختبارية
      QuerySnapshot testTrips = await _firestore
          .collection('trips')
          .where('riderId', isEqualTo: 'test_rider')
          .get();

      for (var doc in testTrips.docs) {
        await doc.reference.delete();
      }

      // حذف طلبات الرحلات الاختبارية
      QuerySnapshot testRequests = await _firestore
          .collection('trip_requests')
          .where('riderId', isEqualTo: 'test_rider')
          .get();

      for (var doc in testRequests.docs) {
        await doc.reference.delete();
      }

      // حذف عمليات الدفع الاختبارية
      QuerySnapshot testPayments = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: 'test_user')
          .get();

      for (var doc in testPayments.docs) {
        await doc.reference.delete();
      }

      _log('تم تنظيف البيانات الاختبارية');
    } catch (e) {
      _log('خطأ في تنظيف البيانات الاختبارية: $e');
    }
  }
}
