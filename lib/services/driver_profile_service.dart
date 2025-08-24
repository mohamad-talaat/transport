import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:transport_app/models/driver_profile_model.dart';
import 'package:transport_app/services/driver_profile_service.dart';
import 'package:transport_app/services/image_upload_service.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/user_model.dart';

class DriverProfileService extends GetxService {
  static DriverProfileService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageUploadService _imageUploadService = Get.find<ImageUploadService>();

  /// جلب بروفايل السائق
  Future<DriverProfileModel?> getDriverProfile(String driverId) async {
    try {
      final doc =
          await _firestore.collection('driver_profiles').doc(driverId).get();

      if (doc.exists) {
        return DriverProfileModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      logger.w('خطأ في جلب بروفايل السائق: $e');
      return null;
    }
  }

  /// إنشاء بروفايل جديد
  Future<bool> createDriverProfile(DriverProfileModel profile) async {
    try {
      await _firestore
          .collection('driver_profiles')
          .doc(profile.driverId)
          .set(profile.toMap());

      logger.i('تم إنشاء بروفايل السائق بنجاح');
      return true;
    } catch (e) {
      logger.w('خطأ في إنشاء بروفايل السائق: $e');
      return false;
    }
  }

  /// تحديث بروفايل السائق
  Future<bool> updateDriverProfile(DriverProfileModel profile) async {
    try {
      final updatedData = profile.toMap();
      updatedData['updatedAt'] = Timestamp.now();

      await _firestore
          .collection('driver_profiles')
          .doc(profile.driverId)
          .update(updatedData);

      logger.i('تم تحديث بروفايل السائق بنجاح');
      return true;
    } catch (e) {
      logger.w('خطأ في تحديث بروفايل السائق: $e');
      return false;
    }
  }

  /// رفع صورة السيارة
  Future<String?> uploadCarPhoto(dynamic imageFile) async {
    try {
      final fileName = 'car_${DateTime.now().millisecondsSinceEpoch}';
      final url = await _imageUploadService.uploadImage(
        imageFile: imageFile,
        folder: 'driver_profiles/car_photos',
        fileName: fileName,
      );
      return url;
    } catch (e) {
      logger.w('خطأ في رفع صورة السيارة: $e');
      return null;
    }
  }

  /// رفع صورة الرخصة
  Future<String?> uploadLicensePhoto(dynamic imageFile) async {
    try {
      final fileName = 'license_${DateTime.now().millisecondsSinceEpoch}';
      final url = await _imageUploadService.uploadImage(
        imageFile: imageFile,
        folder: 'driver_profiles/license_photos',
        fileName: fileName,
      );
      return url;
    } catch (e) {
      logger.w('خطأ في رفع صورة الرخصة: $e');
      return null;
    }
  }

  /// التحقق من اكتمال بروفايل السائق
  Future<bool> isProfileComplete(String userId) async {
    try {
      // جلب بيانات المستخدم
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;

      // التحقق من حقل isProfileComplete أولاً
      if (userData['isProfileComplete'] == true) {
        return true;
      }

      // التحقق من الحقول المطلوبة للسائق
      final requiredFields = [
        'name',
        'phone',
        'email',
        'vehicleModel',
        'vehicleColor',
        'licensePlate',
        'licenseNumber',
        'vehicleYear',
        'profileImage',
        'idCardImage',
        'licenseImage',
        'vehicleImage',
        'isVerified',
        'isActive',
        'serviceArea',
        'bankAccount',
        'emergencyContact'
      ];

      // التحقق من وجود جميع الحقول المطلوبة
      for (String field in requiredFields) {
        if (!userData.containsKey(field) ||
            userData[field] == null ||
            userData[field] == '') {
          return false;
        }
      }

      // التحقق من أن السائق مفعل ومتحقق منه
      if (userData['isVerified'] != true || userData['isActive'] != true) {
        return false;
      }

      return true;
    } catch (e) {
      print('خطأ في التحقق من اكتمال بروفايل السائق: $e');
      return false;
    }
  }

  /// التحقق من موافقة الإدارة على السائق
  Future<bool> isDriverApproved(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;

      // التحقق من أن السائق موافق عليه من الإدارة
      return userData['isApproved'] == true;
    } catch (e) {
      print('خطأ في التحقق من موافقة الإدارة: $e');
      return false;
    }
  }

  /// الحصول على قائمة الحقول الناقصة
  Future<List<String>> getMissingFields(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return [];

      final userData = userDoc.data() as Map<String, dynamic>;
      final List<String> missingFields = [];

      // التحقق من حقل isProfileComplete أولاً
      if (userData['isProfileComplete'] == true) {
        return [];
      }

      // قائمة الحقول المطلوبة مع أسمائها العربية
      final fieldNames = {
        'name': 'الاسم الكامل',
        'phone': 'رقم الهاتف',
        'email': 'البريد الإلكتروني',
        'vehicleModel': 'موديل السيارة',
        'vehicleColor': 'لون السيارة',
        'licensePlate': 'رقم اللوحة',
        'licenseNumber': 'رقم الرخصة',
        'vehicleYear': 'سنة السيارة',
        'profileImage': 'الصورة الشخصية',
        'idCardImage': 'صورة الهوية',
        'licenseImage': 'صورة الرخصة',
        'vehicleImage': 'صورة السيارة',
        'isVerified': 'التحقق من الهوية',
        'isActive': 'تفعيل الحساب',
        'serviceArea': 'منطقة العمل',
        'bankAccount': 'الحساب البنكي',
        'emergencyContact': 'جهة اتصال للطوارئ'
      };

      // التحقق من كل حقل
      fieldNames.forEach((field, arabicName) {
        if (!userData.containsKey(field) ||
            userData[field] == null ||
            userData[field] == '' ||
            (field == 'isVerified' && userData[field] != true) ||
            (field == 'isActive' && userData[field] != true)) {
          missingFields.add(arabicName);
        }
      });

      return missingFields;
    } catch (e) {
      print('خطأ في الحصول على الحقول الناقصة: $e');
      return [];
    }
  }

  /// حساب نسبة اكتمال البروفايل
  Future<double> getProfileCompletionPercentage(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return 0.0;

      final userData = userDoc.data() as Map<String, dynamic>;

      // التحقق من حقل isProfileComplete أولاً
      if (userData['isProfileComplete'] == true) {
        return 100.0;
      }

      final requiredFields = [
        'name',
        'phone',
        'email',
        'vehicleModel',
        'vehicleColor',
        'licensePlate',
        'licenseNumber',
        'vehicleYear',
        'profileImage',
        'idCardImage',
        'licenseImage',
        'vehicleImage',
        'isVerified',
        'isActive',
        'serviceArea',
        'bankAccount',
        'emergencyContact'
      ];

      int completedFields = 0;
      for (String field in requiredFields) {
        if (userData.containsKey(field) &&
            userData[field] != null &&
            userData[field] != '' &&
            (field != 'isVerified' || userData[field] == true) &&
            (field != 'isActive' || userData[field] == true)) {
          completedFields++;
        }
      }

      return (completedFields / requiredFields.length) * 100;
    } catch (e) {
      print('خطأ في حساب نسبة اكتمال البروفايل: $e');
      return 0.0;
    }
  }

  /// تحديث حالة اكتمال البروفايل
  Future<void> updateProfileCompletion(
      String userId, Map<String, dynamic> data) async {
    try {
      // إضافة حقل isProfileComplete إذا لم يكن موجوداً
      if (!data.containsKey('isProfileComplete')) {
        data['isProfileComplete'] = false;
      }

      // إضافة حقل isRejected إذا لم يكن موجوداً
      if (!data.containsKey('isRejected')) {
        data['isRejected'] = false;
      }

      // إضافة حقل isApproved إذا لم يكن موجوداً
      if (!data.containsKey('isApproved')) {
        data['isApproved'] = false;
      }

      // إضافة حقل isVerified إذا لم يكن موجوداً
      if (!data.containsKey('isVerified')) {
        data['isVerified'] = false;
      }

      // إضافة حقل isActive إذا لم يكن موجوداً
      if (!data.containsKey('isActive')) {
        data['isActive'] = true;
      }

      // إضافة حقل updatedAt إذا لم يكن موجوداً
      if (!data.containsKey('updatedAt')) {
        data['updatedAt'] = DateTime.now();
      }

      // إضافة حقل createdAt إذا لم يكن موجوداً
      if (!data.containsKey('createdAt')) {
        data['createdAt'] = DateTime.now();
      }

      // إضافة حقل userType إذا لم يكن موجوداً
      if (!data.containsKey('userType')) {
        data['userType'] = 'driver';
      }

      // إضافة حقل balance إذا لم يكن موجوداً
      if (!data.containsKey('balance')) {
        data['balance'] = 0.0;
      }

      // إضافة حقل additionalData إذا لم يكن موجوداً
      if (!data.containsKey('additionalData')) {
        data['additionalData'] = {
          'isOnline': false,
          'isAvailable': true,
          'isOnTrip': false,
          'currentLat': null,
          'currentLng': null,
          'lastSeen': DateTime.now(),
          'isProfileComplete': false,
          'carType': '',
          'carModel': '',
          'carColor': '',
          'carYear': '',
          'carNumber': '',
          'licenseNumber': '',
          'workingAreas': [],
          'carImage': null,
          'licenseImage': null,
          'idCardImage': null,
          'vehicleRegistrationImage': null,
          'insuranceImage': null,
          'serviceArea': '',
          'bankAccount': '',
          'emergencyContact': '',
          'isVerified': false,
          'isActive': true,
          'isApproved': false,
          'isRejected': false,
          'rejectionReason': null,
          'approvedAt': null,
          'approvedBy': null,
          'rejectedAt': null,
          'rejectedBy': null,
          'profileImage': null,
          'name': '',
          'phone': '',
          'email': '',
          'vehicleModel': '',
          'vehicleColor': '',
          'licensePlate': '',
          'vehicleYear': '',
          'vehicleImage': null,
          'licenseNumber': '',
        };
      }

      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      print('خطأ في تحديث بيانات البروفايل: $e');
      throw e;
    }
  }

  /// تحديث حالة اكتمال البروفايل
  Future<void> markProfileComplete(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isProfileComplete': true,
        'updatedAt': DateTime.now(),
        'isRejected': false,
        'rejectionReason': null,
      });
    } catch (e) {
      print('خطأ في تحديث حالة اكتمال البروفايل: $e');
      throw e;
    }
  }

  /// تحديث حالة الموافقة على السائق (للأدمن)
  Future<bool> approveDriver(String userId, String adminId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isApproved': true,
        'approvedAt': DateTime.now(),
        'approvedBy': adminId,
        'isRejected': false,
        'rejectionReason': null,
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      print('خطأ في الموافقة على السائق: $e');
      return false;
    }
  }

  /// رفض السائق (للأدمن)
  Future<bool> rejectDriver(
      String userId, String adminId, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isRejected': true,
        'rejectionReason': reason,
        'rejectedAt': DateTime.now(),
        'rejectedBy': adminId,
        'isApproved': false,
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      print('خطأ في رفض السائق: $e');
      return false;
    }
  }

  /// جلب السائقين في انتظار المراجعة
  Future<List<Map<String, dynamic>>> getPendingDrivers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .where('isProfileComplete', isEqualTo: true)
          .where('isApproved', isEqualTo: false)
          .where('isRejected', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('خطأ في جلب السائقين في الانتظار: $e');
      return [];
    }
  }

  /// جلب السائقين الموافق عليهم
  Future<List<Map<String, dynamic>>> getApprovedDrivers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .where('isProfileComplete', isEqualTo: true)
          .where('isApproved', isEqualTo: true)
          .orderBy('approvedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('خطأ في جلب السائقين الموافق عليهم: $e');
      return [];
    }
  }

  /// جلب السائقين المرفوضين
  Future<List<Map<String, dynamic>>> getRejectedDrivers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .where('isProfileComplete', isEqualTo: true)
          .where('isRejected', isEqualTo: true)
          .orderBy('rejectedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('خطأ في جلب السائقين المرفوضين: $e');
      return [];
    }
  }

  /// التحقق من إمكانية استقبال الطلبات
  Future<bool> canReceiveRequests(String userId) async {
    try {
      // التحقق من اكتمال البروفايل
      final isComplete = await isProfileComplete(userId);
      if (!isComplete) return false;

      // التحقق من موافقة الإدارة
      final isApproved = await isDriverApproved(userId);
      if (!isApproved) return false;

      // التحقق من أن السائق متصل ومتاح
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;

      // التحقق من أن السائق متصل ومتاح للعمل
      return userData['isOnline'] == true &&
          userData['isAvailable'] == true &&
          userData['isActive'] == true &&
          userData['isVerified'] == true &&
          userData['isApproved'] == true &&
          userData['isProfileComplete'] == true;
    } catch (e) {
      print('خطأ في التحقق من إمكانية استقبال الطلبات: $e');
      return false;
    }
  }

  /// التحقق من تفعيل بروفايل السائق
  Future<bool> isProfileApproved(String driverId) async {
    try {
      final profile = await getDriverProfile(driverId);
      return profile?.isApproved ?? false;
    } catch (e) {
      logger.w('خطأ في التحقق من تفعيل البروفايل: $e');
      return false;
    }
  }

  /// الحصول على حالة بروفايل السائق
  Future<String> getProfileStatus(String driverId) async {
    try {
      final profile = await getDriverProfile(driverId);
      if (profile == null) return 'غير موجود';
      return profile.profileStatus;
    } catch (e) {
      logger.w('خطأ في الحصول على حالة البروفايل: $e');
      return 'خطأ';
    }
  }

  /// تحديث حالة الموافقة على البروفايل (للأدمن)
  Future<bool> approveDriverProfile(String driverId, String adminId) async {
    try {
      await _firestore.collection('driver_profiles').doc(driverId).update({
        'isApproved': true,
        'approvedAt': Timestamp.now(),
        'approvedBy': adminId,
        'updatedAt': Timestamp.now(),
      });

      logger.i('تم تفعيل بروفايل السائق بنجاح');
      return true;
    } catch (e) {
      logger.w('خطأ في تفعيل بروفايل السائق: $e');
      return false;
    }
  }

  /// رفض بروفايل السائق (للأدمن)
  Future<bool> rejectDriverProfile(
      String driverId, String adminId, String reason) async {
    try {
      await _firestore.collection('driver_profiles').doc(driverId).update({
        'isApproved': false,
        'rejectionReason': reason,
        'rejectedAt': Timestamp.now(),
        'rejectedBy': adminId,
        'updatedAt': Timestamp.now(),
      });

      logger.i('تم رفض بروفايل السائق');
      return true;
    } catch (e) {
      logger.w('خطأ في رفض بروفايل السائق: $e');
      return false;
    }
  }

  /// جلب جميع بروفايلات السائقين في انتظار المراجعة
  Future<List<DriverProfileModel>> getPendingProfiles() async {
    try {
      final querySnapshot = await _firestore
          .collection('driver_profiles')
          .where('isComplete', isEqualTo: true)
          .where('isApproved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DriverProfileModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      logger.w('خطأ في جلب البروفايلات المعلقة: $e');
      return [];
    }
  }

  /// جلب جميع بروفايلات السائقين المفعلة
  Future<List<DriverProfileModel>> getApprovedProfiles() async {
    try {
      final querySnapshot = await _firestore
          .collection('driver_profiles')
          .where('isApproved', isEqualTo: true)
          .orderBy('approvedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DriverProfileModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      logger.w('خطأ في جلب البروفايلات المفعلة: $e');
      return [];
    }
  }
}
