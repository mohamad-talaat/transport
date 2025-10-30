import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart'; // ستحتاج هذه للاستخدام في الـ snackbar
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:get_storage/get_storage.dart';
import '../main.dart'; // تأكد من أن هذا المسار صحيح لملفك الرئيسي الذي يحتوي على logger

// تعديل الـ enum ليتناسب مع الثلاث طرق
enum ImageUploadMethod {
  local,
  imgbb,
  firebaseStorage, // إضافة Firebase Storage
}

class ImageUploadService extends GetxService {
  static ImageUploadService get to => Get.find();

  static const String _imgbbApiKey = 'a244a04bc666806639ced4e0afed102a';
    static const String _imgbbUploadUrl = 'https://api.imgbb.com/1/upload';

  final ImagePicker _picker = ImagePicker();
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final Rx<ImageUploadMethod> currentMethod = ImageUploadMethod.local.obs; // تغيير الاسم وتعيين قيمة افتراضية

  // ثوابت لتسهيل الوصول إليها من الـ UI
  static const ImageUploadMethod local = ImageUploadMethod.local;
  static const ImageUploadMethod imgbb = ImageUploadMethod.imgbb;
  static const ImageUploadMethod firebaseStorage = ImageUploadMethod.firebaseStorage;

  @override
  void onInit() {
    super.onInit();
    _loadPreferredMethod();
    logger.i('🚀 Image Upload Service مُفعّل - الطريقة: ${currentMethod.value}');
  }

  Future<void> _loadPreferredMethod() async {
    final methodString = GetStorage().read<String>('image_upload_method');
    if (methodString != null) {
      currentMethod.value = ImageUploadMethod.values.firstWhere(
        (e) => e.toString().split('.').last == methodString,
        orElse: () => ImageUploadMethod.local, // قيمة افتراضية إذا لم يتم العثور
      );
    }
  }

  Future<void> setPreferredMethod(ImageUploadMethod method) async {
    currentMethod.value = method;
    await GetStorage().write('image_upload_method', method.toString().split('.').last);
  }

  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      logger.w('خطأ اختيار صورة: $e');
      _showError('تعذر اختيار الصورة');
      return null;
    }
  }

  Future<File?> takePhotoWithCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      logger.w('خطأ التقاط صورة: $e');
      _showError('تعذر التقاط الصورة');
      return null;
    }
  }
 Future<String?> uploadImage({
    required File imageFile,
    required String folder, // هذا الـ folder لن يستخدمه ImgBB بشكل مباشر، لكن قد يكون مفيدًا لتتبعك
    String? fileName, // ImgBB سيتجاهل هذا ويولد اسمه الخاص غالبًا
  }) async {
    try {
      if (!await imageFile.exists()) {
        logger.w('الملف غير موجود في المسار: ${imageFile.path}');
        return null;
      }

      logger.i('بدء رفع الصورة إلى ImgBB.com من: ${imageFile.path}');

      // قراءة الصورة كـ Base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // بناء طلب الـ POST
      final uri = Uri.parse('$_imgbbUploadUrl?key=$_imgbbApiKey');
      final request = http.MultipartRequest('POST', uri)
        ..fields['image'] = base64Image;

      // إرسال الطلب
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final String imageUrl = responseData['data']['url'];
          logger.i('تم رفع الصورة بنجاح إلى ImgBB. URL: $imageUrl');
          return imageUrl;
        } else {
          final String error = responseData['error']['message'] ?? 'خطأ غير معروف من ImgBB';
          logger.e('فشل رفع الصورة إلى ImgBB: $error');
          return null;
        }
      } else {
        logger.e('خطأ في طلب ImgBB. الحالة: ${response.statusCode}, الجسم: ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('خطأ عام في رفع الصورة إلى ImgBB: $e');
      return null;
    }
  }

  Future<String?> uploadImageBytes({
    required Uint8List imageBytes,
    required String folder,
    required String fileName,
    required String fileExtension,
  }) async {
    isUploading.value = true;
    uploadProgress.value = 0.0;

    try {
      switch (currentMethod.value) {
        case ImageUploadMethod.imgbb:
          final url = await _uploadBytesToImgBB(imageBytes, fileName);
          if (url != null) return url;
          return await _saveBytesLocally(
              imageBytes, folder, fileName, fileExtension);
        case ImageUploadMethod.local:
          return await _saveBytesLocally(
              imageBytes, folder, fileName, fileExtension);
        case ImageUploadMethod.firebaseStorage:
           _showError('خدمة Firebase Storage غير مطبقة بعد.');
          return null;
      }
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
    }
    return null;
  }

  Future<String?> _uploadToImgBB(File imageFile, String fileName) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return await _uploadBytesToImgBB(bytes, fileName);
    } catch (e) {
      logger.w('فشل رفع ImgBB: $e');
      return null;
    }
  }
Future<String?> _uploadBytesToImgBB(Uint8List bytes, String fileName) async {
  try {
    logger.i('📸 تحويل الصورة إلى Base64...');
    uploadProgress.value = 0.3;
    // لا نحتاج لتحويلها إلى Base64 إذا استخدمنا MultipartRequest مباشرة للملفات
    //final base64Image = base64Encode(bytes);
    //logger.i('✅ تم التحويل، حجم البيانات: ${base64Image.length} حرف');

    uploadProgress.value = 0.5;
    logger.i('🌐 إرسال الطلب إلى ImgBB API باستخدام MultipartRequest...');

    // 1. إنشاء طلب MultipartRequest
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.imgbb.com/1/upload'),
    );

    // 2. إضافة مفتاح API كـ field
    request.fields['key'] = _imgbbApiKey;

    // 3. إضافة اسم الملف كـ field (اختياري، لكن جيد)
    request.fields['name'] = fileName;

    // 4. إضافة ملف الصورة نفسه كـ MultipartFile
    request.files.add(
      http.MultipartFile.fromBytes(
        'image', // هذا هو اسم الـ field الذي تتوقعه ImgBB لبيانات الصورة
        bytes,
        filename: '$fileName.jpg', // يمكن تغيير الامتداد حسب نوع الصورة
        // contentType: MediaType('image', 'jpeg'), // يمكن تحديد نوع المحتوى إذا لزم الأمر
      ),
    );

    // 5. إرسال الطلب
    final streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('انتهى وقت الانتظار للرفع');
          },
        );

    // 6. انتظار الاستجابة
    final response = await http.Response.fromStream(streamedResponse);

    uploadProgress.value = 0.9;
    logger.i('📥 استجابة من ImgBB - Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      logger.i('📋 Response Body: ${json.toString()}');

      if (json['success'] == true &&
          json['data'] != null &&
          json['data']['url'] != null) {
        final imageUrl = json['data']['url'] as String;
        uploadProgress.value = 1.0;
        logger.i('✅ رابط الصورة: $imageUrl');
        return imageUrl;
      } else {
        logger.e('❌ ImgBB فشل: ${json['error']?['message'] ?? 'خطأ غير معروف'}');
      }
    } else {
      logger.e('❌ HTTP Error ${response.statusCode}: ${response.body}');
    }
    return null;
  } on TimeoutException catch (e) {
    logger.e('⏱️ انتهى وقت الانتظار: $e');
    return null;
  } catch (e) {
    logger.e('❌ فشل رفع ImgBB: $e');
    return null;
  }
}
 

  Future<String?> _saveLocally(
      File imageFile, String folder, String fileName) async {
    try {
      final dir = await _getStorageDir(folder);
      final ext = path.extension(imageFile.path);
      final filePath = '${dir.path}/$fileName$ext';

      await imageFile.copy(filePath);
      await _saveImageInfo(filePath, folder, fileName);

      logger.i('حفظ محلي: $filePath');
      return filePath;
    } catch (e) {
      logger.w('فشل الحفظ المحلي: $e');
      return null;
    }
  }

  Future<String?> _saveBytesLocally(
    Uint8List bytes,
    String folder,
    String fileName,
    String ext,
  ) async {
    try {
      final dir = await _getStorageDir(folder);
      final filePath = '${dir.path}/$fileName$ext';

      await File(filePath).writeAsBytes(bytes);
      await _saveImageInfo(filePath, folder, fileName);

      logger.i('حفظ محلي: $filePath');
      return filePath;
    } catch (e) {
      logger.w('فشل الحفظ المحلي: $e');
      return null;
    }
  }

  Future<Directory> _getStorageDir(String folder) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/images/$folder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _saveImageInfo(
      String filePath, String folder, String fileName) async {
    try {
      final box = GetStorage();
      final List<dynamic> saved = box.read('saved_images') ?? [];
      saved.add(jsonEncode({
        'path': filePath,
        'folder': folder,
        'fileName': fileName,
        'uploadedAt': DateTime.now().toIso8601String(),
      }));
      box.write('saved_images', saved);
    } catch (e) {
      logger.w('فشل حفظ معلومات: $e');
    }
  }

  Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        await _removeImageInfo(imagePath);
        return true;
      }
      return true; // الصورة غير موجودة، يعتبر حذفًا ناجحًا
    } catch (e) {
      logger.w('فشل حذف: $e');
      return false;
    }
  }

  Future<void> _removeImageInfo(String imagePath) async {
    try {
      final box = GetStorage();
      final List<dynamic> saved = box.read('saved_images') ?? [];
      saved.removeWhere((info) {
        final data = jsonDecode(info);
        return data['path'] == imagePath;
      });
      box.write('saved_images', saved);
    } catch (e) {
      logger.w('فشل حذف معلومات: $e');
    }
  }

  // دالة لمسح جميع الصور المحفوظة محليًا
  Future<void> clearAllImages() async {
    try {
      final box = GetStorage();
      final List<dynamic> saved = box.read('saved_images') ?? [];
      
      for (var infoJson in saved) {
        final data = jsonDecode(infoJson);
        final String filePath = data['path'];
        await deleteImage(filePath); // استخدام دالة الحذف الموجودة
      }
      
      // مسح قائمة الصور المحفوظة في GetStorage
      await box.remove('saved_images');

      // محاولة حذف مجلد الصور بالكامل (اختياري، قد يسبب مشاكل إذا كانت هناك ملفات أخرى)
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }

      logger.i('تم مسح جميع الصور المحلية بنجاح.');
    } catch (e) {
      logger.e('خطأ في مسح جميع الصور المحلية: $e');
      rethrow; // إعادة رمي الخطأ للتعامل معه في الـ UI
    }
  }

  void _showError(String msg) {
    Get.snackbar(
      'خطأ',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // الدوال المتخصصة
  Future<String?> uploadCarImage(File f, String id) => uploadImage(
      imageFile: f,
      folder: 'drivers/$id/car',
      fileName: 'car_${DateTime.now().millisecondsSinceEpoch}');

  Future<String?> uploadLicenseImage(File f, String id) => uploadImage(
      imageFile: f,
      folder: 'drivers/$id/docs',
      fileName: 'license_${DateTime.now().millisecondsSinceEpoch}');

  Future<String?> uploadIdCardImage(File f, String id) => uploadImage(
      imageFile: f,
      folder: 'drivers/$id/docs',
      fileName: 'id_${DateTime.now().millisecondsSinceEpoch}');

  Future<String?> uploadVehicleRegistrationImage(File f, String id) =>
      uploadImage(
          imageFile: f,
          folder: 'drivers/$id/docs',
          fileName: 'reg_${DateTime.now().millisecondsSinceEpoch}');

  Future<String?> uploadInsuranceImage(File f, String id) => uploadImage(
      imageFile: f,
      folder: 'drivers/$id/docs',
      fileName: 'ins_${DateTime.now().millisecondsSinceEpoch}');

  Future<String?> uploadProfileImage(File f, String id) => uploadImage(
      imageFile: f,
      folder: 'users/$id/profile',
      fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}');
}
 