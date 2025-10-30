import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:transport_app/models/driver_profile_model.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/services/unified_image_service.dart';

class DriverProfileService extends GetxService {
  static DriverProfileService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageUploadService _imageUploadService = Get.find<ImageUploadService>();

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

  Future<bool> updateDriverProfile(DriverProfileModel profile) async {
    try {
      final updatedData = profile.toMap();
      updatedData['updatedAt'] = FieldValue.serverTimestamp();

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

  Future<bool> isProfileComplete(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;

      if (userData['isProfileComplete'] == true) {
        return true;
      }

      final requiredFields = [
        'name',
        'phone',
        
        'vehicleModel',
        'vehicleColor',
        'provinceCode',
        'provinceName',
        'vehicleYear',
        'profileImage',
        'nationalIdImage',
        'drivingLicenseImage',
        'vehicleImage',
        'emergencyContact'
      ];

      for (String field in requiredFields) {
        if (!userData.containsKey(field) ||
            userData[field] == null ||
            userData[field] == '') {
          return false;
        }
      }

      if (userData['isVerified'] != true || userData['isActive'] != true) {
        return false;
      }

      return true;
    } catch (e) {
      logger.w('خطأ في التحقق من اكتمال بروفايل السائق: $e');
      return false;
    }
  }

  Future<bool> isDriverApproved(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;

      return userData['isApproved'] == true;
    } catch (e) {
      logger.w('خطأ في التحقق من موافقة الإدارة: $e');
      return false;
    }
  }

  Future<List<String>> getMissingFields(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return [];

      final userData = userDoc.data() as Map<String, dynamic>;
      final List<String> missingFields = [];

      if (userData['isProfileComplete'] == true) {
        return [];
      }

      final fieldNames = {
        'name': 'الاسم الكامل',
        'phone': 'رقم الهاتف',
        'email': 'البريد الإلكتروني',
        'vehicleModel': 'موديل السيارة',
        'vehicleColor': 'لون السيارة',
        'licensePlate': 'رقم اللوحة',
        'plateNumber': 'رقم لوحة السيارة',
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
        'emergencyContact': 'جهة اتصال للطوارئ',
         
      
      };

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
      logger.w('خطأ في الحصول على الحقول الناقصة: $e');
      return [];
    }
  }

  Future<double> getProfileCompletionPercentage(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return 0.0;

      final userData = userDoc.data() as Map<String, dynamic>;

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
      logger.w('خطأ في حساب نسبة اكتمال البروفايل: $e');
      return 0.0;
    }
  }

  Future<void> updateProfileCompletion(
      String userId, Map<String, dynamic> data) async {
    try {
      if (!data.containsKey('isProfileComplete')) {
        data['isProfileComplete'] = false;
      }

      if (!data.containsKey('isRejected')) {
        data['isRejected'] = false;
      }

      if (!data.containsKey('isApproved')) {
        data['isApproved'] = false;
      }

      if (!data.containsKey('isVerified')) {
        data['isVerified'] = false;
      }

      if (!data.containsKey('isActive')) {
        data['isActive'] = true;
      }

      if (!data.containsKey('updatedAt')) {
        data['updatedAt'] = DateTime.now();
      }

      if (!data.containsKey('createdAt')) {
        data['createdAt'] = DateTime.now();
      }

      if (!data.containsKey('userType')) {
        data['userType'] = 'driver';
      }

      if (!data.containsKey('balance')) {
        data['balance'] = 0.0;
      }

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
      logger.w('خطأ في تحديث بيانات البروفايل: $e');
      rethrow;
    }
  }

  Future<void> markProfileComplete(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isProfileComplete': true,
        'updatedAt': DateTime.now(),
        'isRejected': false,
        'rejectionReason': null,
      });
    } catch (e) {
      logger.w('خطأ في تحديث حالة اكتمال البروفايل: $e');
      rethrow;
    }
  }

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
      logger.w('خطأ في الموافقة على السائق: $e');
      return false;
    }
  }

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
      logger.w('خطأ في رفض السائق: $e');
      return false;
    }
  }

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

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      logger.w('خطأ في جلب السائقين في الانتظار: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getApprovedDrivers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .where('isProfileComplete', isEqualTo: true)
          .where('isApproved', isEqualTo: true)
          .orderBy('approvedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      logger.w('خطأ في جلب السائقين الموافق عليهم: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRejectedDrivers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .where('isProfileComplete', isEqualTo: true)
          .where('isRejected', isEqualTo: true)
          .orderBy('rejectedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      logger.w('خطأ في جلب السائقين المرفوضين: $e');
      return [];
    }
  }

  Future<bool> canReceiveRequests(String userId) async {
    try {
      final isComplete = await isProfileComplete(userId);
      if (!isComplete) return false;

      final isApproved = await isDriverApproved(userId);
      if (!isApproved) return false;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;

      return userData['isOnline'] == true &&
          userData['isAvailable'] == true &&
          userData['isActive'] == true &&
          userData['isVerified'] == true &&
          userData['isApproved'] == true &&
          userData['isProfileComplete'] == true;
    } catch (e) {
      logger.w('خطأ في التحقق من إمكانية استقبال الطلبات: $e');
      return false;
    }
  }

  Future<bool> isProfileApproved(String driverId) async {
    try {
      final profile = await getDriverProfile(driverId);
      return profile?.isApproved ?? false;
    } catch (e) {
      logger.w('خطأ في التحقق من تفعيل البروفايل: $e');
      return false;
    }
  }

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

  Future<bool> approveDriverProfile(String driverId, String adminId) async {
    try {
      await _firestore.collection('driver_profiles').doc(driverId).update({
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logger.i('تم تفعيل بروفايل السائق بنجاح');
      return true;
    } catch (e) {
      logger.w('خطأ في تفعيل بروفايل السائق: $e');
      return false;
    }
  }

  Future<bool> rejectDriverProfile(
      String driverId, String adminId, String reason) async {
    try {
      await _firestore.collection('driver_profiles').doc(driverId).update({
        'isApproved': false,
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logger.i('تم رفض بروفايل السائق');
      return true;
    } catch (e) {
      logger.w('خطأ في رفض بروفايل السائق: $e');
      return false;
    }
  }

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
