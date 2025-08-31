import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path_util;
import '../main.dart';

class ImageUploadService extends GetxService {
  static ImageUploadService get to => Get.find();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;

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

  /// رفع صورة إلى Firebase Storage
  Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    required String fileName,
  }) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;

      // إنشاء مسار الملف في Storage
      final String fileExtension = path_util.extension(imageFile.path);
      final String fullFileName = '$fileName$fileExtension';
      final Reference storageRef =
          _storage.ref().child('$folder/$fullFileName');

      // رفع الملف مع مراقبة التقدم
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/${fileExtension.replaceAll('.', '')}',
        ),
      );

      // مراقبة تقدم الرفع
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        uploadProgress.value = progress;
      });

      // انتظار اكتمال الرفع
      final TaskSnapshot snapshot = await uploadTask;

      // الحصول على رابط التحميل
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      logger.i('تم رفع الصورة بنجاح: $downloadUrl');
      return downloadUrl;
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

      final String fullFileName = '$fileName$fileExtension';
      final Reference storageRef =
          _storage.ref().child('$folder/$fullFileName');

      // رفع البيانات الخام
      final UploadTask uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/${fileExtension.replaceAll('.', '')}',
        ),
      );

      // مراقبة تقدم الرفع
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        uploadProgress.value = progress;
      });

      // انتظار اكتمال الرفع
      final TaskSnapshot snapshot = await uploadTask;

      // الحصول على رابط التحميل
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      logger.i('تم رفع الصورة بنجاح: $downloadUrl');
      return downloadUrl;
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

  /// حذف صورة من Firebase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return true;

      final Reference storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();

      logger.i('تم حذف الصورة بنجاح');
      return true;
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
}
