import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class LocalImageService extends GetxService {
  static LocalImageService get to => Get.find();

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

  /// الحصول على مجلد التطبيق
  Future<Directory> get _appDirectory async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory imagesDir = Directory('${appDir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  /// حفظ صورة محلياً
  Future<String?> saveImageLocally({
    required File imageFile,
    required String folder,
    required String fileName,
  }) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;

      // محاكاة التقدم
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 50));
        uploadProgress.value = i / 100;
      }

      final Directory appDir = await _appDirectory;
      final Directory folderDir = Directory('${appDir.path}/$folder');
      
      if (!await folderDir.exists()) {
        await folderDir.create(recursive: true);
      }

      final String fileExtension = path.extension(imageFile.path);
      final String fullFileName = '$fileName$fileExtension';
      final String filePath = '${folderDir.path}/$fullFileName';

      // نسخ الصورة إلى المجلد المحلي
      await imageFile.copy(filePath);

      // حفظ معلومات الصورة في SharedPreferences
      await _saveImageInfo(filePath, folder, fileName);

      logger.i('تم حفظ الصورة محلياً: $filePath');
      return filePath;
    } catch (e) {
      logger.w('خطأ في حفظ الصورة: $e');
      Get.snackbar(
        'خطأ',
        'تعذر حفظ الصورة',
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

  /// حفظ معلومات الصورة
  Future<void> _saveImageInfo(String filePath, String folder, String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedImages = prefs.getStringList('saved_images') ?? [];
      
      final Map<String, dynamic> imageInfo = {
        'path': filePath,
        'folder': folder,
        'fileName': fileName,
        'uploadedAt': DateTime.now().toIso8601String(),
      };
      
      savedImages.add(json.encode(imageInfo));
      await prefs.setStringList('saved_images', savedImages);
    } catch (e) {
      logger.w('خطأ في حفظ معلومات الصورة: $e');
    }
  }

  /// رفع صورة (محلياً)
  Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    required String fileName,
  }) async {
    return await saveImageLocally(
      imageFile: imageFile,
      folder: folder,
      fileName: fileName,
    );
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

      // محاكاة التقدم
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 50));
        uploadProgress.value = i / 100;
      }

      final Directory appDir = await _appDirectory;
      final Directory folderDir = Directory('${appDir.path}/$folder');
      
      if (!await folderDir.exists()) {
        await folderDir.create(recursive: true);
      }

      final String fullFileName = '$fileName$fileExtension';
      final String filePath = '${folderDir.path}/$fullFileName';

      // حفظ البيانات الخام
      final File file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // حفظ معلومات الصورة
      await _saveImageInfo(filePath, folder, fileName);

      logger.i('تم حفظ الصورة محلياً: $filePath');
      return filePath;
    } catch (e) {
      logger.w('خطأ في حفظ الصورة: $e');
      return null;
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
    }
  }

  /// حذف صورة محلياً
  Future<bool> deleteImage(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        
        // حذف المعلومات من SharedPreferences
        await _removeImageInfo(imagePath);
        
        logger.i('تم حذف الصورة: $imagePath');
        return true;
      }
      return false;
    } catch (e) {
      logger.w('خطأ في حذف الصورة: $e');
      return false;
    }
  }

  /// حذف معلومات الصورة
  Future<void> _removeImageInfo(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedImages = prefs.getStringList('saved_images') ?? [];
      
      savedImages.removeWhere((imageInfo) {
        final Map<String, dynamic> info = json.decode(imageInfo);
        return info['path'] == imagePath;
      });
      
      await prefs.setStringList('saved_images', savedImages);
    } catch (e) {
      logger.w('خطأ في حذف معلومات الصورة: $e');
    }
  }

  /// الحصول على جميع الصور المحفوظة
  Future<List<Map<String, dynamic>>> getSavedImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedImages = prefs.getStringList('saved_images') ?? [];
      
      return savedImages.map((imageInfo) {
        return Map<String, dynamic>.from(json.decode(imageInfo));
      }).toList();
    } catch (e) {
      logger.w('خطأ في الحصول على الصور المحفوظة: $e');
      return [];
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

  /// مسح جميع الصور المحفوظة
  Future<void> clearAllImages() async {
    try {
      final Directory appDir = await _appDirectory;
      if (await appDir.exists()) {
        await appDir.delete(recursive: true);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_images');
      
      logger.i('تم مسح جميع الصور المحفوظة');
    } catch (e) {
      logger.w('خطأ في مسح الصور: $e');
    }
  }
}
