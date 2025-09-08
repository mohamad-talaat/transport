import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../models/rider_model.dart';
import '../models/driver_model.dart';

class UserManagementService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // كوليكشن واحد فقط
  static const String usersCollection = 'users';

  // متغيرات تفاعلية
  final Rx<RiderModel?> currentRider = Rx<RiderModel?>(null);
  final Rx<DriverModel?> currentDriver = Rx<DriverModel?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _logger.i('تم تهيئة UserManagementService');
  }

  // ==================== إدارة الراكبين ====================

  /// إنشاء راكب جديد
  Future<RiderModel?> createRider({
    required String id,
    required String name,
    required String phone,
    required String email,
    String? profileImage,
    String? fcmToken,
  }) async {
    try {
      isLoading.value = true;

      final rider = RiderModel(
        id: id,
        name: name,
        phone: phone,
        email: email,
        profileImage: profileImage,
        createdAt: DateTime.now(),
        fcmToken: fcmToken,
      );

      await _firestore.collection(usersCollection).doc(id).set({
        ...rider.toMap(),
        'userType': 'rider',
      });

      _logger.i('تم إنشاء راكب جديد: $id');
      currentRider.value = rider;
      return rider;
    } catch (e) {
      _logger.e('خطأ في إنشاء راكب: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب بيانات راكب
  Future<RiderModel?> getRider(String riderId) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(riderId).get();

      if (doc.exists && doc['userType'] == 'rider') {
        final rider = RiderModel.fromMap(doc.data()!);
        currentRider.value = rider;
        return rider;
      }
      return null;
    } catch (e) {
      _logger.e('خطأ في جلب بيانات راكب: $e');
      return null;
    }
  }

  // ==================== إدارة السائقين ====================

  /// إنشاء سائق جديد
  Future<DriverModel?> createDriver({
    required String id,
    required String name,
    required String phone,
    required String email,
    String? profileImage,
    String? fcmToken,
  }) async {
    try {
      isLoading.value = true;

      final driver = DriverModel(
        id: id,
        name: name,
        phone: phone,
        email: email,
        profileImage: profileImage,
        createdAt: DateTime.now(),
        fcmToken: fcmToken,
        status: DriverStatus.pending,
      );

      await _firestore.collection(usersCollection).doc(id).set({
        ...driver.toMap(),
        'userType': 'driver',
      });

      _logger.i('تم إنشاء سائق جديد: $id');
      currentDriver.value = driver;
      return driver;
    } catch (e) {
      _logger.e('خطأ في إنشاء سائق: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب بيانات سائق
  Future<DriverModel?> getDriver(String driverId) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(driverId).get();

      if (doc.exists && doc['userType'] == 'driver') {
        final driver = DriverModel.fromMap(doc.data()!);
        currentDriver.value = driver;
        return driver;
      }
      return null;
    } catch (e) {
      _logger.e('خطأ في جلب بيانات سائق: $e');
      return null;
    }
  }

  // ==================== جلب قوائم المستخدمين ====================

  /// جلب جميع الراكبين
  Stream<List<RiderModel>> getAllRiders() {
    return _firestore
        .collection(usersCollection)
        .where('userType', isEqualTo: 'rider')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RiderModel.fromMap(doc.data()))
            .toList());
  }

  /// جلب جميع السائقين
  Stream<List<DriverModel>> getAllDrivers() {
    return _firestore
        .collection(usersCollection)
        .where('userType', isEqualTo: 'driver')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DriverModel.fromMap(doc.data()))
            .toList());
  }

  /// جلب السائقين المتاحين
  Stream<List<DriverModel>> getAvailableDrivers() {
    return _firestore
        .collection(usersCollection)
        .where('userType', isEqualTo: 'driver')
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .where('isOnline', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DriverModel.fromMap(doc.data()))
            .toList());
  }
  /// تحديث بيانات سائق
  Future<bool> updateDriver(String driverId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(usersCollection).doc(driverId).update(data);
      _logger.i('تم تحديث بيانات السائق: $driverId');
      return true;
    } catch (e) {
      _logger.e('خطأ في تحديث بيانات السائق: $e');
      return false;
    }
  }

  /// تحديث بيانات راكب
  Future<bool> updateRider(String riderId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(usersCollection).doc(riderId).update(data);
      _logger.i('تم تحديث بيانات الراكب: $riderId');
      return true;
    } catch (e) {
      _logger.e('خطأ في تحديث بيانات الراكب: $e');
      return false;
    }
  }


}
