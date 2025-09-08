import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../main.dart';

class ImageUploadService extends GetxService {
  static ImageUploadService get to => Get.find();

  // احصل على API Key مجاني من imgbb.com
  static const String _apiKey = 'a244a04bc666806639ced4e0afed102a'; // ضع هنا الـ API Key
  static const String _baseUrl = 'https://api.imgbb.com/1/upload';

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

  /// رفع صورة إلى ImgBB
  Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    required String fileName,
  }) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;

      if (!await imageFile.exists()) {
        throw Exception('الملف غير موجود');
      }

      logger.i('بدء رفع الصورة إلى ImgBB: $fileName');

      // تحويل الصورة إلى base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // إعداد البيانات
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      request.fields['key'] = _apiKey;
      request.fields['image'] = base64Image;
      request.fields['name'] = fileName;

      // إرسال الطلب
      uploadProgress.value = 0.5; // تقدم وهمي
      final streamedResponse = await request.send();
      uploadProgress.value = 0.8; // تقدم وهمي

      final response = await http.Response.fromStream(streamedResponse);
      uploadProgress.value = 1.0;

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          final imageUrl = jsonResponse['data']['url'];
          logger.i('تم رفع الصورة بنجاح: $imageUrl');
          return imageUrl;
        } else {
          throw Exception('فشل الرفع: ${jsonResponse['error']['message']}');
        }
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('خطأ في رفع الصورة: $e');
      Get.snackbar(
        'خطأ',
        'تعذر رفع الصورة: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
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

      logger.i('بدء رفع الصورة من البيانات الخام إلى ImgBB: $fileName');

      // تحويل البيانات إلى base64
      final base64Image = base64Encode(imageBytes);

      // إعداد البيانات
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      request.fields['key'] = _apiKey;
      request.fields['image'] = base64Image;
      request.fields['name'] = fileName;

      uploadProgress.value = 0.5;
      final streamedResponse = await request.send();
      uploadProgress.value = 0.8;

      final response = await http.Response.fromStream(streamedResponse);
      uploadProgress.value = 1.0;

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          final imageUrl = jsonResponse['data']['url'];
          logger.i('تم رفع الصورة بنجاح: $imageUrl');
          return imageUrl;
        } else {
          throw Exception('فشل الرفع: ${jsonResponse['error']['message']}');
        }
      } else {
        throw Exception('خطأ في الخادم: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('خطأ في رفع الصورة: $e');
      Get.snackbar(
        'خطأ',
        'تعذر رفع الصورة: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
      return null;
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
    }
  }

  /// حذف صورة (ImgBB لا يدعم الحذف عبر API المجاني)
  Future<bool> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return true;
      
      // ImgBB لا يدعم حذف الصور عبر API المجاني
      logger.i('تنبيه: ImgBB لا يدعم حذف الصور عبر API المجاني');
      return true;
    } catch (e) {
      logger.w('تنبيه حذف الصورة: $e');
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

// import 'dart:io';
// import 'dart:typed_data';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path/path.dart' as path_util;
// import '../main.dart';

// class ImageUploadService extends GetxService {
//   static ImageUploadService get to => Get.find();

//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   final ImagePicker _picker = ImagePicker();

//   final RxBool isUploading = false.obs;
//   final RxDouble uploadProgress = 0.0.obs;

//   /// اختيار صورة من المعرض
//   Future<File?> pickImageFromGallery() async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 80,
//         maxWidth: 1024,
//         maxHeight: 1024,
//       );

//       if (image != null) {
//         return File(image.path);
//       }
//       return null;
//     } catch (e) {
//       logger.w('خطأ في اختيار الصورة من المعرض: $e');
//       Get.snackbar(
//         'خطأ',
//         'تعذر اختيار الصورة من المعرض',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       return null;
//     }
//   }

//   /// التقاط صورة بالكاميرا
//   Future<File?> takePhotoWithCamera() async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.camera,
//         imageQuality: 80,
//         maxWidth: 1024,
//         maxHeight: 1024,
//       );

//       if (image != null) {
//         return File(image.path);
//       }
//       return null;
//     } catch (e) {
//       logger.w('خطأ في التقاط الصورة: $e');
//       Get.snackbar(
//         'خطأ',
//         'تعذر التقاط الصورة',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       return null;
//     }
//   }

//   /// رفع صورة إلى Firebase Storage
//   Future<String?> uploadImage({
//     required File imageFile,
//     required String folder,
//     required String fileName,
//   }) async {
//     try {
//       isUploading.value = true;
//       uploadProgress.value = 0.0;

//       // التحقق من وجود الملف
//       if (!await imageFile.exists()) {
//         throw Exception('الملف غير موجود');
//       }

//       // إنشاء مسار الملف في Storage
//       final String fileExtension = path_util.extension(imageFile.path);
//       final String fullFileName = '$fileName$fileExtension';
//       final Reference storageRef =
//           _storage.ref().child('$folder/$fullFileName');

//       logger.i('بدء رفع الصورة: $folder/$fullFileName');

//       // رفع الملف مع مراقبة التقدم
//       final UploadTask uploadTask = storageRef.putFile(
//         imageFile,
//         SettableMetadata(
//           contentType: 'image/${fileExtension.replaceAll('.', '')}',
//           cacheControl: 'max-age=31536000',
//         ),
//       );

//       // مراقبة تقدم الرفع
//       uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
//         final progress = snapshot.bytesTransferred / snapshot.totalBytes;
//         uploadProgress.value = progress;
//         logger.d('تقدم الرفع: ${(progress * 100).toStringAsFixed(1)}%');
//       });

//       // انتظار اكتمال الرفع
//       final TaskSnapshot snapshot = await uploadTask;

//       // التحقق من نجاح الرفع
//       if (snapshot.state != TaskState.success) {
//         throw Exception('فشل في رفع الصورة: ${snapshot.state}');
//       }

//       logger.i('تم رفع الصورة بنجاح، جاري الحصول على الرابط...');

//       // الحصول على رابط التحميل مع إعادة المحاولة
//       String downloadUrl = '';
//       int retryCount = 0;
//       const maxRetries = 3;

//       while (retryCount < maxRetries) {
//         try {
//           downloadUrl = await snapshot.ref.getDownloadURL();
//           logger.i('تم الحصول على رابط التحميل: $downloadUrl');
//           break;
//         } catch (e) {
//           retryCount++;
//           logger.w('فشل في الحصول على الرابط (المحاولة $retryCount): $e');

//           if (retryCount < maxRetries) {
//             // انتظار قصير قبل إعادة المحاولة
//             await Future.delayed(Duration(seconds: retryCount));
//           } else {
//             throw Exception(
//                 'فشل في الحصول على رابط التحميل بعد $maxRetries محاولات: $e');
//           }
//         }
//       }

//       return downloadUrl;
//     } catch (e) {
//       logger.e('خطأ في رفع الصورة: $e');
//       Get.snackbar(
//         'خطأ',
//         'تعذر رفع الصورة: ${e.toString()}',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         duration: Duration(seconds: 5),
//       );
//       return null;
//     } finally {
//       isUploading.value = false;
//       uploadProgress.value = 0.0;
//     }
//   }

//   /// رفع صورة من البيانات الخام (Bytes)
//   Future<String?> uploadImageBytes({
//     required Uint8List imageBytes,
//     required String folder,
//     required String fileName,
//     required String fileExtension,
//   }) async {
//     try {
//       isUploading.value = true;
//       uploadProgress.value = 0.0;

//       final String fullFileName = '$fileName$fileExtension';
//       final Reference storageRef =
//           _storage.ref().child('$folder/$fullFileName');

//       logger.i('بدء رفع الصورة من البيانات الخام: $folder/$fullFileName');

//       // رفع البيانات الخام
//       final UploadTask uploadTask = storageRef.putData(
//         imageBytes,
//         SettableMetadata(
//           contentType: 'image/${fileExtension.replaceAll('.', '')}',
//           cacheControl: 'max-age=31536000',
//         ),
//       );

//       // مراقبة تقدم الرفع
//       uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
//         final progress = snapshot.bytesTransferred / snapshot.totalBytes;
//         uploadProgress.value = progress;
//         logger.d('تقدم الرفع: ${(progress * 100).toStringAsFixed(1)}%');
//       });

//       // انتظار اكتمال الرفع
//       final TaskSnapshot snapshot = await uploadTask;

//       // التحقق من نجاح الرفع
//       if (snapshot.state != TaskState.success) {
//         throw Exception('فشل في رفع الصورة: ${snapshot.state}');
//       }

//       logger.i('تم رفع الصورة بنجاح، جاري الحصول على الرابط...');

//       // الحصول على رابط التحميل مع إعادة المحاولة
//       String downloadUrl = '';
//       int retryCount = 0;
//       const maxRetries = 3;

//       while (retryCount < maxRetries) {
//         try {
//           downloadUrl = await snapshot.ref.getDownloadURL();
//           logger.i('تم الحصول على رابط التحميل: $downloadUrl');
//           break;
//         } catch (e) {
//           retryCount++;
//           logger.w('فشل في الحصول على الرابط (المحاولة $retryCount): $e');

//           if (retryCount < maxRetries) {
//             // انتظار قصير قبل إعادة المحاولة
//             await Future.delayed(Duration(seconds: retryCount));
//           } else {
//             throw Exception(
//                 'فشل في الحصول على رابط التحميل بعد $maxRetries محاولات: $e');
//           }
//         }
//       }

//       return downloadUrl;
//     } catch (e) {
//       logger.e('خطأ في رفع الصورة: $e');
//       Get.snackbar(
//         'خطأ',
//         'تعذر رفع الصورة: ${e.toString()}',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         duration: Duration(seconds: 5),
//       );
//       return null;
//     } finally {
//       isUploading.value = false;
//       uploadProgress.value = 0.0;
//     }
//   }

//   /// حذف صورة من Firebase Storage
//   Future<bool> deleteImage(String imageUrl) async {
//     try {
//       if (imageUrl.isEmpty) return true;

//       final Reference storageRef = _storage.refFromURL(imageUrl);
//       await storageRef.delete();

//       logger.i('تم حذف الصورة بنجاح');
//       return true;
//     } catch (e) {
//       logger.w('خطأ في حذف الصورة: $e');
//       return false;
//     }
//   }

//   /// رفع صورة السيارة
//   Future<String?> uploadCarImage(File imageFile, String driverId) async {
//     return await uploadImage(
//       imageFile: imageFile,
//       folder: 'drivers/$driverId/car',
//       fileName: 'car_image_${DateTime.now().millisecondsSinceEpoch}',
//     );
//   }

//   /// رفع صورة الرخصة
//   Future<String?> uploadLicenseImage(File imageFile, String driverId) async {
//     return await uploadImage(
//       imageFile: imageFile,
//       folder: 'drivers/$driverId/documents',
//       fileName: 'license_${DateTime.now().millisecondsSinceEpoch}',
//     );
//   }

//   /// رفع صورة الهوية
//   Future<String?> uploadIdCardImage(File imageFile, String driverId) async {
//     return await uploadImage(
//       imageFile: imageFile,
//       folder: 'drivers/$driverId/documents',
//       fileName: 'id_card_${DateTime.now().millisecondsSinceEpoch}',
//     );
//   }

//   /// رفع صورة تسجيل السيارة
//   Future<String?> uploadVehicleRegistrationImage(
//       File imageFile, String driverId) async {
//     return await uploadImage(
//       imageFile: imageFile,
//       folder: 'drivers/$driverId/documents',
//       fileName: 'vehicle_registration_${DateTime.now().millisecondsSinceEpoch}',
//     );
//   }

//   /// رفع صورة التأمين
//   Future<String?> uploadInsuranceImage(File imageFile, String driverId) async {
//     return await uploadImage(
//       imageFile: imageFile,
//       folder: 'drivers/$driverId/documents',
//       fileName: 'insurance_${DateTime.now().millisecondsSinceEpoch}',
//     );
//   }
// }
