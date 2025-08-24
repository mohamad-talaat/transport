import 'dart:math';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../main.dart';

class MockTestingService extends GetxService {
  static MockTestingService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== مواقع مصر للاختبار (يمكن حذفها والعودة للعراق لاحقاً) =====
  final List<Map<String, dynamic>> egyptLocations = [
    {
      'name': 'القاهرة - وسط البلد',
      'lat': 30.0444,
      'lng': 31.2357,
      'address': 'القاهرة، مصر'
    },
    {
      'name': 'الإسكندرية - المنتزه',
      'lat': 31.2001,
      'lng': 29.9187,
      'address': 'الإسكندرية، مصر'
    },
    {
      'name': 'الجيزة - الهرم',
      'lat': 29.9792,
      'lng': 31.1342,
      'address': 'الجيزة، مصر'
    },
    {
      'name': 'شرم الشيخ - البحر الأحمر',
      'lat': 27.9158,
      'lng': 34.3296,
      'address': 'شرم الشيخ، مصر'
    },
    {
      'name': 'الأقصر - معبد الكرنك',
      'lat': 25.6872,
      'lng': 32.6396,
      'address': 'الأقصر، مصر'
    },
    {
      'name': 'أسوان - السد العالي',
      'lat': 23.5880,
      'lng': 32.8773,
      'address': 'أسوان، مصر'
    },
  ];

  // ===== مواقع العراق (محفوظة للاستخدام لاحقاً) =====
  final List<Map<String, dynamic>> iraqiLocations = [
    {
      'name': 'البصرة - مركز المدينة',
      'lat': 30.5081,
      'lng': 47.7804,
      'address': 'البصرة، العراق'
    },
    {
      'name': 'بغداد - شارع الرشيد',
      'lat': 33.3152,
      'lng': 44.3661,
      'address': 'بغداد، العراق'
    },
    {
      'name': 'الموصل - الجامعة',
      'lat': 36.3498,
      'lng': 43.1375,
      'address': 'الموصل، العراق'
    },
    {
      'name': 'أربيل - المركز التجاري',
      'lat': 36.1901,
      'lng': 43.9930,
      'address': 'أربيل، العراق'
    },
    {
      'name': 'النجف - الحرم العلوي',
      'lat': 32.0000,
      'lng': 44.3333,
      'address': 'النجف، العراق'
    },
    {
      'name': 'كربلاء - الحرم الحسيني',
      'lat': 32.6167,
      'lng': 44.0333,
      'address': 'كربلاء، العراق'
    },
  ];

  // ===== استخدام مواقع مصر حالياً للاختبار =====
  List<Map<String, dynamic>> get currentLocations => egyptLocations;

  /// إنشاء سائق وهمي في مصر (للاختبار)
  Future<void> createMockDriver({
    required String driverId,
    required String driverName,
    required String phoneNumber,
    String? locationName,
  }) async {
    try {
      // اختيار موقع عشوائي في مصر
      final location = locationName != null
          ? currentLocations.firstWhere((loc) => loc['name'] == locationName,
              orElse: () => currentLocations[0])
          : currentLocations[0];

      final driverData = {
        'id': driverId,
        'name': driverName,
        'phone': phoneNumber,
        'email': '$driverId@mock.com',
        'profileImage': null,
        'userType': 'driver',
        'balance': 0.0,
        'createdAt': Timestamp.now(),
        'isActive': true,
        'additionalData': {
          'carType': 'سيدان',
          'carModel': 'تويوتا كامري',
          'carColor': 'أبيض',
          'carYear': '2020',
          'carNumber': 'القاهرة 12345',
          'licenseNumber': 'LIC-$driverId',
          'workingAreas': ['القاهرة', 'الجيزة'],
          'carImage': null,
          'licenseImage': null,
          'idCardImage': null,
          'vehicleRegistrationImage': null,
          'insuranceImage': null,
          'isProfileComplete': true,
          'isOnline': true,
          'isAvailable': true,
          'currentLat': location['lat'],
          'currentLng': location['lng'],
          'lastSeen': Timestamp.now(),
        },
      };

      await _firestore.collection('users').doc(driverId).set(driverData);
      logger.i('تم إنشاء سائق وهمي: $driverName في ${location['name']} (مصر)');
    } catch (e) {
      logger.w('خطأ في إنشاء السائق الوهمي: $e');
    }
  }

  /// إنشاء راكب وهمي
  Future<void> createMockRider({
    required String riderId,
    required String riderName,
    required String phoneNumber,
  }) async {
    try {
      final riderData = {
        'id': riderId,
        'name': riderName,
        'phone': phoneNumber,
        'email': '$riderId@mock.com',
        'profileImage': null,
        'userType': 'rider',
        'balance': 100.0, // رصيد وهمي
        'createdAt': Timestamp.now(),
        'isActive': true,
        'additionalData': null,
      };

      await _firestore.collection('users').doc(riderId).set(riderData);
      logger.i('تم إنشاء راكب وهمي: $riderName');
    } catch (e) {
      logger.w('خطأ في إنشاء الراكب الوهمي: $e');
    }
  }

  /// إنشاء رحلة وهمية في مصر
  Future<void> createMockTrip({
    required String tripId,
    required String riderId,
    String? pickupLocationName,
    String? destinationLocationName,
  }) async {
    try {
      // اختيار مواقع عشوائية في مصر
      final pickup = pickupLocationName != null
          ? currentLocations.firstWhere(
              (loc) => loc['name'] == pickupLocationName,
              orElse: () => currentLocations[0])
          : currentLocations[0];

      final destination = destinationLocationName != null
          ? currentLocations.firstWhere(
              (loc) => loc['name'] == destinationLocationName,
              orElse: () => currentLocations[1])
          : currentLocations[1];

      // حساب المسافة التقريبية
      final distance = _calculateDistance(
        LatLng(pickup['lat'], pickup['lng']),
        LatLng(destination['lat'], destination['lng']),
      );

      final tripData = {
        'id': tripId,
        'riderId': riderId,
        'driverId': null,
        'pickupLocation': {
          'latLng': {
            'latitude': pickup['lat'],
            'longitude': pickup['lng'],
          },
          'address': pickup['address'],
        },
        'destinationLocation': {
          'latLng': {
            'latitude': destination['lat'],
            'longitude': destination['lng'],
          },
          'address': destination['address'],
        },
        'fare': distance * 15.0, // 15 جنيه لكل كم (مصر)
        'distance': distance,
        'estimatedDuration': (distance * 2).round(), // دقيقة لكل كم
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'acceptedAt': null,
        'startedAt': null,
        'completedAt': null,
        'routePolyline': [],
      };

      await _firestore.collection('trips').doc(tripId).set(tripData);
      logger.i(
          'تم إنشاء رحلة وهمية: من ${pickup['name']} إلى ${destination['name']} (مصر)');
    } catch (e) {
      logger.w('خطأ في إنشاء الرحلة الوهمية: $e');
    }
  }

  /// إنشاء طلب رحلة للسائقين
  Future<void> createMockTripRequest({
    required String tripId,
    required String driverId,
    required String riderId,
  }) async {
    try {
      final requestData = {
        'tripId': tripId,
        'driverId': driverId,
        'riderId': riderId,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(seconds: 30)),
        ),
      };

      await _firestore
          .collection('trip_requests')
          .doc('${tripId}_$driverId')
          .set(requestData);

      logger.i('تم إنشاء طلب رحلة للسائق: $driverId');
    } catch (e) {
      logger.w('خطأ في إنشاء طلب الرحلة: $e');
    }
  }

  /// تحديث موقع السائق الوهمي
  Future<void> updateMockDriverLocation({
    required String driverId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _firestore.collection('users').doc(driverId).update({
        'additionalData.currentLat': lat,
        'additionalData.currentLng': lng,
        'additionalData.lastSeen': Timestamp.now(),
      });

      logger.i('تم تحديث موقع السائق الوهمي: $driverId');
    } catch (e) {
      logger.w('خطأ في تحديث موقع السائق: $e');
    }
  }

  /// تغيير حالة السائق الوهمي
  Future<void> updateMockDriverStatus({
    required String driverId,
    bool? isOnline,
    bool? isAvailable,
  }) async {
    try {
      final updates = <String, dynamic>{
        'additionalData.lastSeen': Timestamp.now(),
      };

      if (isOnline != null) {
        updates['additionalData.isOnline'] = isOnline;
      }
      if (isAvailable != null) {
        updates['additionalData.isAvailable'] = isAvailable;
      }

      await _firestore.collection('users').doc(driverId).update(updates);

      logger.i('تم تحديث حالة السائق الوهمي: $driverId');
    } catch (e) {
      logger.w('خطأ في تحديث حالة السائق: $e');
    }
  }

  /// إنشاء سيناريو اختبار كامل في مصر
  Future<void> createFullTestScenario() async {
    try {
      // إنشاء سائقين وهميين في مصر
      await createMockDriver(
        driverId: 'mock_driver_1',
        driverName: 'أحمد السائق',
        phoneNumber: '+201000123456',
        locationName: 'القاهرة - وسط البلد',
      );

      await createMockDriver(
        driverId: 'mock_driver_2',
        driverName: 'محمد السائق',
        phoneNumber: '+201000123457',
        locationName: 'الجيزة - الهرم',
      );

      // إنشاء راكب وهمي
      await createMockRider(
        riderId: 'mock_rider_1',
        riderName: 'علي الراكب',
        phoneNumber: '+201000123458',
      );

      // إنشاء رحلة وهمية في مصر
      await createMockTrip(
        tripId: 'mock_trip_1',
        riderId: 'mock_rider_1',
        pickupLocationName: 'القاهرة - وسط البلد',
        destinationLocationName: 'الجيزة - الهرم',
      );

      // إنشاء طلبات رحلة
      await createMockTripRequest(
        tripId: 'mock_trip_1',
        driverId: 'mock_driver_1',
        riderId: 'mock_rider_1',
      );

      await createMockTripRequest(
        tripId: 'mock_trip_1',
        driverId: 'mock_driver_2',
        riderId: 'mock_rider_1',
      );

      logger.i('تم إنشاء سيناريو اختبار كامل بنجاح');
    } catch (e) {
      logger.w('خطأ في إنشاء سيناريو الاختبار: $e');
    }
  }

  /// حذف جميع البيانات الوهمية
  Future<void> clearMockData() async {
    try {
      // حذف المستخدمين الوهميين
      final usersQuery =
          await _firestore.collection('users').where('email', whereIn: [
        'mock_driver_1@mock.com',
        'mock_driver_2@mock.com',
        'mock_rider_1@mock.com',
      ]).get();

      for (var doc in usersQuery.docs) {
        await doc.reference.delete();
      }

      // حذف الرحلات الوهمية
      final tripsQuery = await _firestore
          .collection('trips')
          .where('id', whereIn: ['mock_trip_1']).get();

      for (var doc in tripsQuery.docs) {
        await doc.reference.delete();
      }

      // حذف طلبات الرحلات الوهمية
      final requestsQuery = await _firestore
          .collection('trip_requests')
          .where('tripId', whereIn: ['mock_trip_1']).get();

      for (var doc in requestsQuery.docs) {
        await doc.reference.delete();
      }

      logger.i('تم حذف جميع البيانات الوهمية');
    } catch (e) {
      logger.w('خطأ في حذف البيانات الوهمية: $e');
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

  /// الحصول على قائمة المواقع الحالية (مصر)
  List<Map<String, dynamic>> getCurrentLocations() {
    return currentLocations;
  }

  /// الحصول على قائمة المواقع العراقية (محفوظة)
  List<Map<String, dynamic>> getIraqiLocations() {
    return iraqiLocations;
  }

  /// ===== للعودة للعراق لاحقاً: غير هذا السطر =====
  /// List<Map<String, dynamic>> get currentLocations => iraqiLocations;
}
