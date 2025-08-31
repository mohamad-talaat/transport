import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../main.dart';

class FreeImageUploadService extends GetxService {
  static FreeImageUploadService get to => Get.find();

  final ImagePicker _picker = ImagePicker();
  
  // ImgBB API Key - يمكنك الحصول على واحد مجاني من https://api.imgbb.com/
  // هذا مفتاح تجريبي، يرجى استبداله بمفتاحك الخاص
  static const String _imgbbApiKey = '2d207eac8c6e6d8b3c4c4c4c4c4c4c4c'; // استبدل بمفتاحك
  
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

  /// رفع صورة إلى ImgBB (مجاني)
  Future<String?> uploadImageToImgBB({
    required File imageFile,
    String? customName,
  }) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;

      // تحويل الصورة إلى base64
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // إعداد البيانات للرفع
      final Map<String, String> data = {
        'key': _imgbbApiKey,
        'image': base64Image,
        'name': customName ?? 'image_${DateTime.now().millisecondsSinceEpoch}',
      };

      // رفع الصورة إلى ImgBB
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: data,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final String imageUrl = responseData['data']['url'];
          logger.i('تم رفع الصورة بنجاح: $imageUrl');
          return imageUrl;
        } else {
          throw Exception('فشل في رفع الصورة: ${responseData['error']?.message ?? 'خطأ غير معروف'}');
        }
      } else {
        throw Exception('خطأ في الاتصال: ${response.statusCode}');
      }
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

  /// رفع صورة مع محاكاة التقدم
  Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    required String fileName,
  }) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;

      // محاكاة التقدم
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        uploadProgress.value = i / 100;
      }

      // رفع الصورة
      final String? imageUrl = await uploadImageToImgBB(
        imageFile: imageFile,
        customName: '$folder/$fileName',
      );

      return imageUrl;
    } catch (e) {
      logger.w('خطأ في رفع الصورة: $e');
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

      // محاكاة التقدم
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        uploadProgress.value = i / 100;
      }

      // تحويل البيانات إلى base64
      final String base64Image = base64Encode(imageBytes);

      // إعداد البيانات للرفع
      final Map<String, String> data = {
        'key': _imgbbApiKey,
        'image': base64Image,
        'name': '$folder/$fileName$fileExtension',
      };

      // رفع الصورة إلى ImgBB
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: data,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final String imageUrl = responseData['data']['url'];
          logger.i('تم رفع الصورة بنجاح: $imageUrl');
          return imageUrl;
        } else {
          throw Exception('فشل في رفع الصورة: ${responseData['error']?.message ?? 'خطأ غير معروف'}');
        }
      } else {
        throw Exception('خطأ في الاتصال: ${response.statusCode}');
      }
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

  /// حذف صورة (لا يمكن حذفها من ImgBB المجاني)
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // لا يمكن حذف الصور من ImgBB المجاني
      // يمكن إضافة منطق لحذفها من قاعدة البيانات المحلية
      logger.i('لا يمكن حذف الصور من ImgBB المجاني');
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

  /// رفع صورة الملف الشخصي
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    return await uploadImage(
      imageFile: imageFile,
      folder: 'users/$userId/profile',
      fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
