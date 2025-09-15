import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/image_upload_service.dart';
import 'package:transport_app/main.dart'; // Assuming main.dart contains your logger instance

class RiderProfileCompletionView extends StatefulWidget {
  const RiderProfileCompletionView({super.key});

  @override
  State<RiderProfileCompletionView> createState() =>
      _RiderProfileCompletionViewState();
}

class _RiderProfileCompletionViewState
    extends State<RiderProfileCompletionView> {
  final AuthController auth = Get.find<AuthController>();
  final ImageUploadService _imageService = Get.find<ImageUploadService>(); // Directly find the service

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController(); // Renamed for consistency
  final TextEditingController _phoneController = TextEditingController(); // Renamed for consistency

  bool _isLoading = false; // Renamed for consistency with driver view
  String? _profileImage;

  @override
  void initState() {
    super.initState();
    _initializeRiderData();
  }

  Future<void> _initializeRiderData() async {
    final user = auth.currentUser.value;
    if (user != null) {
      _nameController.text = user.name.trim();
      _phoneController.text = user.phone.trim();
      _profileImage = user.profileImage;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image == null) return; // User cancelled image selection

      setState(() => _isLoading = true); // Use _isLoading for image upload too

      Get.snackbar(
        'جاري الرفع',
        'الرجاء الانتظار...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2), // Shorter duration for image upload feedback
      );

      // Upload the image using the ImageUploadService
      final File file = File(image.path);
      final String? url = await _imageService.uploadImage(
        imageFile: file,
        folder: 'rider_profile', // Consistent folder naming
        fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (url == null) {
        Get.snackbar(
          'خطأ',
          'فشل في رفع الصورة، يرجى المحاولة مرة أخرى',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        logger.w('Image upload returned null for file: ${image.path}');
      } else {
        setState(() => _profileImage = url);
        Get.snackbar(
          'نجح',
          'تم رفع الصورة بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e, st) {
      logger.e('Error uploading image: $e', error: e, stackTrace: st);
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء رفع الصورة: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async { // Renamed for consistency
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'تحقق من البيانات',
        'يرجى ملء جميع الحقول المطلوبة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final user = auth.currentUser.value;
    if (user == null) {
      Get.snackbar(
        'خطأ',
        'لم يتم العثور على بيانات المستخدم',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Get.snackbar(
        'جاري الحفظ',
        'يرجى الانتظار...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profileImage': _profileImage,
        'updatedAt': Timestamp.now(),
        // Consider adding a 'isProfileComplete' flag for riders if needed for logic
      });

      // Update the local user object in AuthController
      final current = auth.currentUser.value!;
      auth.currentUser.value = current.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        profileImage: _profileImage,
      );

      Get.snackbar(
        'نجح',
        'تم حفظ البيانات بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed(AppRoutes.RIDER_HOME);
      });
    } catch (e, st) {
      logger.e('Error saving profile: $e', error: e, stackTrace: st);
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء حفظ البيانات: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper widget for image picker, similar to driver view
  Widget _buildImagePicker(String title, String? currentImage) {
    // For rider, we only have one image picker, so title is simplified
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Center( // Center the image preview
              child: Container(
                height: 120,
                width: 120, // Square image for profile
                decoration: BoxDecoration(
                  shape: BoxShape.circle, // Circular profile image
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: ClipOval( // Clip to oval shape
                  child: currentImage != null
                      ? currentImage.startsWith('http')
                          ? Image.network(
                              currentImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            )
                          : Image.file( // Handle local file path if any (e.g., from failed upload preview)
                              File(currentImage),
                              fit: BoxFit.cover,
                            )
                      : const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 60,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickProfileImage, // Use _pickProfileImage directly
              icon: _isLoading && _imageService.isUploading.value // Show specific upload progress if service is uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.upload),
              label: Text(
                _isLoading && _imageService.isUploading.value
                    ? 'جاري الرفع...'
                    : (currentImage != null ? 'تغيير الصورة' : 'رفع صورة شخصية'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentImage != null ? Colors.orange : Colors.blue, // Match driver view button colors
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the profile is "complete" for the rider (name, phone, image are present)
    final bool isRiderProfileComplete = _nameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _profileImage != null;

    return WillPopScope(
      onWillPop: () async => false, // Prevent going back without saving
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إكمال الملف الشخصي للراكب'),
          centerTitle: true,
          automaticallyImplyLeading: false, // No back button
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile status card
                Card(
                  color: isRiderProfileComplete
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          isRiderProfileComplete ? Icons.check_circle : Icons.warning,
                          color: isRiderProfileComplete ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isRiderProfileComplete
                                ? 'ملفك الشخصي مكتمل'
                                : 'يرجى إكمال بياناتك الأساسية',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isRiderProfileComplete ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Profile Image section
                _buildImagePicker('صورة الملف الشخصي', _profileImage),
                const SizedBox(height: 16),

                // Basic Info Section
                const Text(
                  'البيانات الأساسية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'يرجى إدخال الاسم';
                    if (value!.trim().length < 3) return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    hintText: '+964xxxxxxxxxx',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'يرجى إدخال رقم الهاتف';
                    }
                    if (value!.trim().length < 9) return 'رقم الهاتف يجب أن يكون 9 أرقام على الأقل';
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Blue button for saving
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'حفظ البيانات',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Important Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملاحظة مهمة:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• يجب إكمال جميع البيانات المطلوبة لكي تتمكن من استخدام التطبيق\n'
                        '• يمكنك تحديث البيانات في أي وقت لاحقاً من إعدادات الملف الشخصي',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}