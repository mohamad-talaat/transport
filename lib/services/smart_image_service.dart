import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'image_upload_service.dart';
import 'free_image_upload_service.dart';
import 'local_image_service.dart';

enum ImageUploadMethod {
  firebaseStorage,
  imgbb,
  local,
}

class SmartImageService extends GetxService {
  static SmartImageService get to => Get.find();

  final ImagePicker _picker = ImagePicker();
  
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final Rx<ImageUploadMethod> currentMethod = ImageUploadMethod.local.obs;

  // الخدمات المتاحة
  late final ImageUploadService _firebaseService;
  late final FreeImageUploadService _imgbbService;
  late final LocalImageService _localService;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _loadPreferredMethod();
  }

  /// تهيئة الخدمات
  void _initializeServices() {
    try {
      _firebaseService = Get.find<ImageUploadService>();
    } catch (e) {
      logger.w('Firebase Storage غير متاح: $e');
    }

    try {
      _imgbbService = Get.find<FreeImageUploadService>();
    } catch (e) {
      logger.w('ImgBB Service غير متاح: $e');
    }

    try {
      _localService = Get.find<LocalImageService>();
    } catch (e) {
      logger.w('Local Service غير متاح: $e');
    }
  }

  /// تحميل الطريقة المفضلة
  Future<void> _loadPreferredMethod() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? methodString = prefs.getString('preferred_image_method');
      
      if (methodString != null) {
        currentMethod.value = ImageUploadMethod.values.firstWhere(
          (method) => method.toString() == methodString,
          orElse: () => ImageUploadMethod.local,
        );
      }
    } catch (e) {
      logger.w('خطأ في تحميل الطريقة المفضلة: $e');
      currentMethod.value = ImageUploadMethod.local;
    }
  }

  /// حفظ الطريقة المفضلة
  Future<void> _savePreferredMethod(ImageUploadMethod method) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_image_method', method.toString());
      currentMethod.value = method;
    } catch (e) {
      logger.w('خطأ في حفظ الطريقة المفضلة: $e');
    }
  }

  /// اختيار صورة من المعرض
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      logger.w('خطأ في اختيار الصورة من المعرض: $e');
      Get.snackbar(
        'خطأ',
        'تعذر اختيار الصورة من المعرض',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  /// التقاط صورة بالكاميرا
  Future<File?> takePhotoWithCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      logger.w('خطأ في التقاط الصورة: $e');
      Get.snackbar(
        'خطأ',
        'تعذر التقاط الصورة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  /// رفع صورة بالطريقة الذكية
  Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    required String fileName,
  }) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;

      String? result;
      ImageUploadMethod usedMethod = currentMethod.value;

      // محاولة الرفع بالطريقة المفضلة
      switch (currentMethod.value) {
        case ImageUploadMethod.firebaseStorage:
          result = await _tryFirebaseUpload(imageFile, folder, fileName);
          if (result != null) {
            usedMethod = ImageUploadMethod.firebaseStorage;
            break;
          }
          // إذا فشل، جرب الطريقة التالية
          result = await _tryImgBBUpload(imageFile, folder, fileName);
          if (result != null) {
            usedMethod = ImageUploadMethod.imgbb;
            break;
          }
          // إذا فشل، استخدم المحلي
          result = await _tryLocalUpload(imageFile, folder, fileName);
          usedMethod = ImageUploadMethod.local;
          break;

        case ImageUploadMethod.imgbb:
          result = await _tryImgBBUpload(imageFile, folder, fileName);
          if (result != null) {
            usedMethod = ImageUploadMethod.imgbb;
            break;
          }
          // إذا فشل، جرب Firebase
          result = await _tryFirebaseUpload(imageFile, folder, fileName);
          if (result != null) {
            usedMethod = ImageUploadMethod.firebaseStorage;
            break;
          }
          // إذا فشل، استخدم المحلي
          result = await _tryLocalUpload(imageFile, folder, fileName);
          usedMethod = ImageUploadMethod.local;
          break;

        case ImageUploadMethod.local:
          result = await _tryLocalUpload(imageFile, folder, fileName);
          if (result != null) {
            usedMethod = ImageUploadMethod.local;
            break;
          }
          // إذا فشل، جرب ImgBB
          result = await _tryImgBBUpload(imageFile, folder, fileName);
          if (result != null) {
            usedMethod = ImageUploadMethod.imgbb;
            break;
          }
          // إذا فشل، جرب Firebase
          result = await _tryFirebaseUpload(imageFile, folder, fileName);
          usedMethod = ImageUploadMethod.firebaseStorage;
          break;
      }

      if (result != null) {
        // حفظ الطريقة الناجحة كطريقة مفضلة
        await _savePreferredMethod(usedMethod);
        
        logger.i('تم رفع الصورة بنجاح باستخدام: ${usedMethod.toString()}');
        Get.snackbar(
          'نجح',
          'تم رفع الصورة بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('فشل في رفع الصورة بجميع الطرق المتاحة');
      }

      return result;
    } catch (e) {
      logger.w('خطأ في رفع الصورة: $e');
      Get.snackbar(
        'خطأ',
        'تعذر رفع الصورة، يرجى المحاولة مرة أخرى',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
    }
  }

  /// محاولة الرفع إلى Firebase Storage
  Future<String?> _tryFirebaseUpload(File imageFile, String folder, String fileName) async {
    try {
      return await _firebaseService.uploadImage(
        imageFile: imageFile,
        folder: folder,
        fileName: fileName,
      );
    } catch (e) {
      logger.w('فشل في رفع الصورة إلى Firebase: $e');
      return null;
    }
  }

  /// محاولة الرفع إلى ImgBB
  Future<String?> _tryImgBBUpload(File imageFile, String folder, String fileName) async {
    try {
      return await _imgbbService.uploadImage(
        imageFile: imageFile,
        folder: folder,
        fileName: fileName,
      );
    } catch (e) {
      logger.w('فشل في رفع الصورة إلى ImgBB: $e');
      return null;
    }
  }

  /// محاولة الرفع محلياً
  Future<String?> _tryLocalUpload(File imageFile, String folder, String fileName) async {
    try {
      return await _localService.uploadImage(
        imageFile: imageFile,
        folder: folder,
        fileName: fileName,
      );
    } catch (e) {
      logger.w('فشل في رفع الصورة محلياً: $e');
      return null;
    }
  }

  /// رفع صورة من البيانات الخام (Bytes)
  Future<String?> uploadImageBytes({
    required Uint8List imageBytes,
    required String folder,
    required String fileName,
    required String fileExtension,
  }) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;

      String? result;
      ImageUploadMethod usedMethod = currentMethod.value;

      // محاولة الرفع بالطريقة المفضلة
      switch (currentMethod.value) {
        case ImageUploadMethod.firebaseStorage:
          result = await _firebaseService.uploadImageBytes(
            imageBytes: imageBytes,
            folder: folder,
            fileName: fileName,
            fileExtension: fileExtension,
          );
          if (result != null) {
            usedMethod = ImageUploadMethod.firebaseStorage;
            break;
          }
          result = await _imgbbService.uploadImageBytes(
            imageBytes: imageBytes,
            folder: folder,
            fileName: fileName,
            fileExtension: fileExtension,
          );
          if (result != null) {
            usedMethod = ImageUploadMethod.imgbb;
            break;
          }
          result = await _localService.uploadImageBytes(
            imageBytes: imageBytes,
            folder: folder,
            fileName: fileName,
            fileExtension: fileExtension,
          );
          usedMethod = ImageUploadMethod.local;
          break;

        case ImageUploadMethod.imgbb:
          result = await _imgbbService.uploadImageBytes(
            imageBytes: imageBytes,
            folder: folder,
            fileName: fileName,
            fileExtension: fileExtension,
          );
          if (result != null) {
            usedMethod = ImageUploadMethod.imgbb;
            break;
          }
          result = await _firebaseService.uploadImageBytes(
            imageBytes: imageBytes,
            folder: folder,
            fileName: fileName,
            fileExtension: fileExtension,
          );
          if (result != null) {
            usedMethod = ImageUploadMethod.firebaseStorage;
            break;
          }
          result = await _localService.uploadImageBytes(
            imageBytes: imageBytes,
            folder: folder,
            fileName: fileName,
            fileExtension: fileExtension,
          );
          usedMethod = ImageUploadMethod.local;
          break;

        case ImageUploadMethod.local:
          result = await _localService.uploadImageBytes(
            imageBytes: imageBytes,
            folder: folder,
            fileName: fileName,
            fileExtension: fileExtension,
          );
          if (result != null) {
            usedMethod = ImageUploadMethod.local;
            break;
          }
          result = await _imgbbService.uploadImageBytes(
            imageBytes: imageBytes,
            folder: folder,
            fileName: fileName,
            fileExtension: fileExtension,
          );
          if (result != null) {
            usedMethod = ImageUploadMethod.imgbb;
            break;
          }
          result = await _firebaseService.uploadImageBytes(
            imageBytes: imageBytes,
            folder: folder,
            fileName: fileName,
            fileExtension: fileExtension,
          );
          usedMethod = ImageUploadMethod.firebaseStorage;
          break;
      }

      if (result != null) {
        await _savePreferredMethod(usedMethod);
        logger.i('تم رفع الصورة بنجاح باستخدام: ${usedMethod.toString()}');
      }

      return result;
    } catch (e) {
      logger.w('خطأ في رفع الصورة: $e');
      return null;
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
    }
  }

  /// حذف صورة
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // محاولة الحذف من جميع الخدمات
      bool deleted = false;

      // Firebase Storage
      try {
        deleted = await _firebaseService.deleteImage(imageUrl) || deleted;
      } catch (e) {
        logger.w('فشل في حذف الصورة من Firebase: $e');
      }

      // ImgBB (لا يمكن حذفها)
      try {
        deleted = await _imgbbService.deleteImage(imageUrl) || deleted;
      } catch (e) {
        logger.w('فشل في حذف الصورة من ImgBB: $e');
      }

      // Local
      try {
        deleted = await _localService.deleteImage(imageUrl) || deleted;
      } catch (e) {
        logger.w('فشل في حذف الصورة محلياً: $e');
      }

      return deleted;
    } catch (e) {
      logger.w('خطأ في حذف الصورة: $e');
      return false;
    }
  }

  /// رفع صورة السيارة
  Future<String?> uploadCarImage(File imageFile, String driverId) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: 'drivers/$driverId/car',
      fileName: 'car_image_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// رفع صورة الرخصة
  Future<String?> uploadLicenseImage(File imageFile, String driverId) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: 'drivers/$driverId/documents',
      fileName: 'license_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// رفع صورة الهوية
  Future<String?> uploadIdCardImage(File imageFile, String driverId) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: 'drivers/$driverId/documents',
      fileName: 'id_card_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// رفع صورة تسجيل السيارة
  Future<String?> uploadVehicleRegistrationImage(
      File imageFile, String driverId) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: 'drivers/$driverId/documents',
      fileName: 'vehicle_registration_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// رفع صورة التأمين
  Future<String?> uploadInsuranceImage(File imageFile, String driverId) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: 'drivers/$driverId/documents',
      fileName: 'insurance_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// رفع صورة الملف الشخصي
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: 'users/$userId/profile',
      fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// تغيير طريقة الرفع المفضلة
  Future<void> setPreferredMethod(ImageUploadMethod method) async {
    await _savePreferredMethod(method);
    Get.snackbar(
      'تم التغيير',
      'تم تغيير طريقة رفع الصور المفضلة',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  /// الحصول على معلومات الطريقة الحالية
  String getCurrentMethodInfo() {
    switch (currentMethod.value) {
      case ImageUploadMethod.firebaseStorage:
        return 'Firebase Storage (مدفوع)';
      case ImageUploadMethod.imgbb:
        return 'ImgBB (مجاني)';
      case ImageUploadMethod.local:
        return 'محلي (مجاني)';
    }
  }
}
