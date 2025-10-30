import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:transport_app/models/user_model.dart';

class UserManagementService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  static const String usersCollection = 'users';

  final Rx<UserModel?> currentRider = Rx<UserModel?>(null);
  final Rx<UserModel?> currentDriver = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _logger.i('تم تهيئة UserManagementService');
  }

  Future<UserModel?> createRider({
    required String id,
    required String name,
    required String phone,
    required String email,
    String? profileImage,
    String? fcmToken,
  }) async {
    try {
      isLoading.value = true;

      final rider = UserModel(
        id: id,
        name: name,
        phone: phone,
        email: email,
        profileImage: profileImage,
        createdAt: DateTime.now(),
        fcmToken: fcmToken,
        userType: UserType.rider,
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

  Future<UserModel?> getRider(String riderId) async {
    try {
      final doc =
          await _firestore.collection(usersCollection).doc(riderId).get();

      if (doc.exists && doc['userType'] == 'rider') {
        final rider = UserModel.fromMap(doc.data()!);
        currentRider.value = rider;
        return rider;
      }
      return null;
    } catch (e) {
      _logger.e('خطأ في جلب بيانات راكب: $e');
      return null;
    }
  }

  Future<UserModel?> createDriver({
    required String id,
    required String name,
    required String phone,
    required String email,
    String? profileImage,
    String? fcmToken,
  }) async {
    try {
      isLoading.value = true;

      final driver = UserModel(
        id: id,
        name: name,
        phone: phone,
        email: email,
        profileImage: profileImage,
        createdAt: DateTime.now(),
        fcmToken: fcmToken,
        driverStatus: DriverStatus.pending,
        userType: UserType.driver,
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

  Future<UserModel?> getDriver(String driverId) async {
    try {
      final doc =
          await _firestore.collection(usersCollection).doc(driverId).get();

      if (doc.exists && doc['userType'] == 'driver') {
        final driver = UserModel.fromMap(doc.data()!);
        currentDriver.value = driver;
        return driver;
      }
      return null;
    } catch (e) {
      _logger.e('خطأ في جلب بيانات سائق: $e');
      return null;
    }
  }

  Stream<List<UserModel>> getAllRiders() {
    return _firestore
        .collection(usersCollection)
        .where('userType', isEqualTo: 'rider')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  Stream<List<UserModel>> getAllDrivers() {
    return _firestore
        .collection(usersCollection)
        .where('userType', isEqualTo: 'driver')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  Stream<List<UserModel>> getAvailableDrivers() {
    return _firestore
        .collection(usersCollection)
        .where('userType', isEqualTo: 'driver')
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .where('isOnline', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

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
