import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../models/rider_model.dart';
import '../models/driver_model.dart';

class UserManagementService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // كوليكشنز منفصلة
  static const String ridersCollection = 'riders';
  static const String driversCollection = 'drivers';
  static const String tripsCollection = 'trips';
  static const String paymentsCollection = 'payments';
  static const String discountCodesCollection = 'discount_codes';
  static const String notificationsCollection = 'notifications';

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

      await _firestore.collection(ridersCollection).doc(id).set(rider.toMap());

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
      final doc =
          await _firestore.collection(ridersCollection).doc(riderId).get();

      if (doc.exists) {
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

  /// تحديث بيانات راكب
  Future<bool> updateRider(String riderId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(ridersCollection).doc(riderId).update(data);

      // تحديث البيانات المحلية
      if (currentRider.value?.id == riderId) {
        final updatedRider = currentRider.value!.copyWith(
          name: data['name'] ?? currentRider.value!.name,
          phone: data['phone'] ?? currentRider.value!.phone,
          email: data['email'] ?? currentRider.value!.email,
          profileImage:
              data['profileImage'] ?? currentRider.value!.profileImage,
          balance: data['balance'] ?? currentRider.value!.balance,
          isProfileComplete: data['isProfileComplete'] ??
              currentRider.value!.isProfileComplete,
          fcmToken: data['fcmToken'] ?? currentRider.value!.fcmToken,
        );
        currentRider.value = updatedRider;
      }

      _logger.i('تم تحديث بيانات راكب: $riderId');
      return true;
    } catch (e) {
      _logger.e('خطأ في تحديث بيانات راكب: $e');
      return false;
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

      await _firestore
          .collection(driversCollection)
          .doc(id)
          .set(driver.toMap());

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
      final doc =
          await _firestore.collection(driversCollection).doc(driverId).get();

      if (doc.exists) {
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

  /// تحديث بيانات سائق
  Future<bool> updateDriver(String driverId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(driversCollection).doc(driverId).update(data);

      // تحديث البيانات المحلية
      if (currentDriver.value?.id == driverId) {
        final updatedDriver = currentDriver.value!.copyWith(
          name: data['name'] ?? currentDriver.value!.name,
          phone: data['phone'] ?? currentDriver.value!.phone,
          email: data['email'] ?? currentDriver.value!.email,
          profileImage:
              data['profileImage'] ?? currentDriver.value!.profileImage,
          balance: data['balance'] ?? currentDriver.value!.balance,
          nationalId: data['nationalId'] ?? currentDriver.value!.nationalId,
          nationalIdImage:
              data['nationalIdImage'] ?? currentDriver.value!.nationalIdImage,
          drivingLicense:
              data['drivingLicense'] ?? currentDriver.value!.drivingLicense,
          drivingLicenseImage: data['drivingLicenseImage'] ??
              currentDriver.value!.drivingLicenseImage,
          vehicleLicense:
              data['vehicleLicense'] ?? currentDriver.value!.vehicleLicense,
          vehicleLicenseImage: data['vehicleLicenseImage'] ??
              currentDriver.value!.vehicleLicenseImage,
          vehicleType: data['vehicleType'] != null
              ? VehicleType.values
                  .firstWhere((e) => e.name == data['vehicleType'])
              : currentDriver.value!.vehicleType,
          vehicleModel:
              data['vehicleModel'] ?? currentDriver.value!.vehicleModel,
          vehicleColor:
              data['vehicleColor'] ?? currentDriver.value!.vehicleColor,
          vehiclePlateNumber: data['vehiclePlateNumber'] ??
              currentDriver.value!.vehiclePlateNumber,
          vehicleImage:
              data['vehicleImage'] ?? currentDriver.value!.vehicleImage,
          insuranceImage:
              data['insuranceImage'] ?? currentDriver.value!.insuranceImage,
          backgroundCheckImage: data['backgroundCheckImage'] ??
              currentDriver.value!.backgroundCheckImage,
          status: data['status'] != null
              ? DriverStatus.values.firstWhere((e) => e.name == data['status'])
              : currentDriver.value!.status,
          isApproved: data['isApproved'] ?? currentDriver.value!.isApproved,
          isProfileComplete: data['isProfileComplete'] ??
              currentDriver.value!.isProfileComplete,
          fcmToken: data['fcmToken'] ?? currentDriver.value!.fcmToken,
        );
        currentDriver.value = updatedDriver;
      }

      _logger.i('تم تحديث بيانات سائق: $driverId');
      return true;
    } catch (e) {
      _logger.e('خطأ في تحديث بيانات سائق: $e');
      return false;
    }
  }

  /// تحديث حالة السائق (للموافقة/الرفض)
  Future<bool> updateDriverStatus({
    required String driverId,
    required DriverStatus status,
    required bool isApproved,
    String? approvedBy,
    String? rejectionReason,
  }) async {
    try {
      final data = {
        'status': status.name,
        'isApproved': isApproved,
        'approvedAt': isApproved ? Timestamp.now() : null,
        'approvedBy': approvedBy,
        'isRejected': !isApproved,
        'rejectedAt': !isApproved ? Timestamp.now() : null,
        'rejectedBy': approvedBy,
        'rejectionReason': rejectionReason,
      };

      await _firestore.collection(driversCollection).doc(driverId).update(data);

      _logger.i('تم تحديث حالة سائق: $driverId - $status');
      return true;
    } catch (e) {
      _logger.e('خطأ في تحديث حالة سائق: $e');
      return false;
    }
  }

  // ==================== جلب قوائم المستخدمين ====================

  /// جلب جميع الراكبين
  Stream<List<RiderModel>> getAllRiders() {
    return _firestore
        .collection(ridersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RiderModel.fromMap(doc.data()))
            .toList());
  }

  /// جلب جميع السائقين
  Stream<List<DriverModel>> getAllDrivers() {
    return _firestore
        .collection(driversCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DriverModel.fromMap(doc.data()))
            .toList());
  }

  /// جلب السائقين المتاحين
  Stream<List<DriverModel>> getAvailableDrivers() {
    return _firestore
        .collection(driversCollection)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .where('isOnline', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DriverModel.fromMap(doc.data()))
            .toList());
  }

  /// جلب السائقين في انتظار الموافقة
  Stream<List<DriverModel>> getPendingDrivers() {
    return _firestore
        .collection(driversCollection)
        .where('status', isEqualTo: DriverStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DriverModel.fromMap(doc.data()))
            .toList());
  }

  // ==================== حذف البيانات ====================

  /// حذف راكب
  Future<bool> deleteRider(String riderId) async {
    try {
      await _firestore.collection(ridersCollection).doc(riderId).delete();

      if (currentRider.value?.id == riderId) {
        currentRider.value = null;
      }

      _logger.i('تم حذف راكب: $riderId');
      return true;
    } catch (e) {
      _logger.e('خطأ في حذف راكب: $e');
      return false;
    }
  }

  /// حذف سائق
  Future<bool> deleteDriver(String driverId) async {
    try {
      await _firestore.collection(driversCollection).doc(driverId).delete();

      if (currentDriver.value?.id == driverId) {
        currentDriver.value = null;
      }

      _logger.i('تم حذف سائق: $driverId');
      return true;
    } catch (e) {
      _logger.e('خطأ في حذف سائق: $e');
      return false;
    }
  }

  // ==================== إحصائيات ====================

  /// جلب إحصائيات المستخدمين
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final ridersSnapshot =
          await _firestore.collection(ridersCollection).get();
      final driversSnapshot =
          await _firestore.collection(driversCollection).get();

      final pendingDrivers = driversSnapshot.docs
          .where((doc) => doc.data()['status'] == DriverStatus.pending.name)
          .length;

      final approvedDrivers = driversSnapshot.docs
          .where((doc) => doc.data()['isApproved'] == true)
          .length;

      return {
        'totalRiders': ridersSnapshot.docs.length,
        'totalDrivers': driversSnapshot.docs.length,
        'pendingDrivers': pendingDrivers,
        'approvedDrivers': approvedDrivers,
      };
    } catch (e) {
      _logger.e('خطأ في جلب إحصائيات المستخدمين: $e');
      return {
        'totalRiders': 0,
        'totalDrivers': 0,
        'pendingDrivers': 0,
        'approvedDrivers': 0,
      };
    }
  }

  // ==================== تنظيف البيانات ====================

  /// حذف جميع البيانات (للتطوير فقط)
  Future<bool> clearAllData() async {
    try {
      _logger.w('بدء حذف جميع البيانات...');

      // حذف جميع الراكبين
      final ridersSnapshot =
          await _firestore.collection(ridersCollection).get();
      for (var doc in ridersSnapshot.docs) {
        await doc.reference.delete();
      }

      // حذف جميع السائقين
      final driversSnapshot =
          await _firestore.collection(driversCollection).get();
      for (var doc in driversSnapshot.docs) {
        await doc.reference.delete();
      }

      // حذف الرحلات
      final tripsSnapshot = await _firestore.collection(tripsCollection).get();
      for (var doc in tripsSnapshot.docs) {
        await doc.reference.delete();
      }

      // حذف المدفوعات
      final paymentsSnapshot =
          await _firestore.collection(paymentsCollection).get();
      for (var doc in paymentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // حذف أكواد الخصم
      final discountSnapshot =
          await _firestore.collection(discountCodesCollection).get();
      for (var doc in discountSnapshot.docs) {
        await doc.reference.delete();
      }

      // حذف التنبيهات
      final notificationsSnapshot =
          await _firestore.collection(notificationsCollection).get();
      for (var doc in notificationsSnapshot.docs) {
        await doc.reference.delete();
      }

      // إعادة تعيين المتغيرات المحلية
      currentRider.value = null;
      currentDriver.value = null;

      _logger.i('تم حذف جميع البيانات بنجاح');
      return true;
    } catch (e) {
      _logger.e('خطأ في حذف البيانات: $e');
      return false;
    }
  }
}
