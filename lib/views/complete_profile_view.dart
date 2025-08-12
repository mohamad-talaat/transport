import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/models/user_model.dart';

class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({super.key});

  @override
  _CompleteProfileViewState createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  final AuthController authController = Get.find();
  final _formKey = GlobalKey<FormState>();
  
  // Text Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carPlateController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  
  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  File? _licenseImage;
  File? _carImage;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _carModelController.dispose();
    _carPlateController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade600,
              Colors.blue.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // زر الرجوع
                  _buildBackButton(),
                  
                  const SizedBox(height: 20),
                  
                  // العنوان
                  _buildHeader(),
                  
                  const SizedBox(height: 40),
                  
                  // نموذج البيانات
                  _buildProfileForm(),
                  
                  const SizedBox(height: 30),
                  
                  // زر الإكمال
                  _buildCompleteButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إكمال الملف الشخصي',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 12),
        
        const Text(
          'أكمل بياناتك للبدء في استخدام التطبيق',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getUserTypeColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getUserTypeColor(),
              width: 1,
            ),
          ),
          child: Text(
            authController.selectedUserType.value == UserType.rider 
                ? '📱 حساب راكب' 
                : '🚗 حساب سائق',
            style: TextStyle(
              fontSize: 14,
              color: _getUserTypeColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة الملف الشخصي
          _buildProfileImageSection(),
          
          const SizedBox(height: 24),
          
          // الاسم
          _buildTextField(
            controller: _nameController,
            label: 'الاسم الكامل',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال الاسم';
              }
              if (value.trim().length < 3) {
                return 'الاسم يجب أن يكون 3 أحرف على الأقل';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // البريد الإلكتروني
          _buildTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني (اختياري)',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!GetUtils.isEmail(value)) {
                  return 'البريد الإلكتروني غير صحيح';
                }
              }
              return null;
            },
          ),
          
          // حقول إضافية للسائق
          if (authController.selectedUserType.value == UserType.driver) ...[
            const SizedBox(height: 24),
            _buildDriverSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      children: [
        const Text(
          'الصورة الشخصية',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 16),
        
        GestureDetector(
          onTap: () => _pickImage(ImageType.profile),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(
                color: _getUserTypeColor(),
                width: 3,
              ),
            ),
            child: _profileImage != null
                ? ClipOval(
                    child: Image.file(
                      _profileImage!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: Colors.grey.shade600,
                  ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'انقر لإضافة صورة',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'بيانات السيارة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // نوع السيارة
        _buildTextField(
          controller: _carModelController,
          label: 'نوع السيارة',
          icon: Icons.directions_car,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال نوع السيارة';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // لوحة السيارة
        _buildTextField(
          controller: _carPlateController,
          label: 'رقم لوحة السيارة',
          icon: Icons.confirmation_number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال رقم لوحة السيارة';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // رقم رخصة القيادة
        _buildTextField(
          controller: _licenseNumberController,
          label: 'رقم رخصة القيادة',
          icon: Icons.card_membership,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال رقم رخصة القيادة';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 24),
        
        // صورة رخصة القيادة
        _buildImageUploadSection(
          title: 'صورة رخصة القيادة',
          image: _licenseImage,
          onTap: () => _pickImage(ImageType.license),
        ),
        
        const SizedBox(height: 16),
        
        // صورة السيارة
        _buildImageUploadSection(
          title: 'صورة السيارة',
          image: _carImage,
          onTap: () => _pickImage(ImageType.car),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _getUserTypeColor()),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        
        const SizedBox(height: 8),
        
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      image,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 32,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'انقر لإضافة صورة',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _completeProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getUserTypeColor(),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: _getUserTypeColor().withOpacity(0.4),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'إكمال التسجيل',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _pickImage(ImageType type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        setState(() {
          switch (type) {
            case ImageType.profile:
              _profileImage = File(image.path);
              break;
            case ImageType.license:
              _licenseImage = File(image.path);
              break;
            case ImageType.car:
              _carImage = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر اختيار الصورة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // التحقق من الصورة الشخصية
    if (_profileImage == null) {
      Get.snackbar(
        'خطأ',
        'يرجى إضافة الصورة الشخصية',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // التحقق من بيانات السائق
    if (authController.selectedUserType.value == UserType.driver) {
      if (_licenseImage == null || _carImage == null) {
        Get.snackbar(
          'خطأ',
          'يرجى إضافة صورة رخصة القيادة وصورة السيارة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await authController.completeProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        profileImage: _profileImage.toString(),
        carModel: _carModelController.text.trim(),
        carPlate: _carPlateController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim(),
        licenseImage: _licenseImage,
        carImage: _carImage,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر إكمال التسجيل: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getUserTypeColor() {
    return authController.selectedUserType.value == UserType.rider
        ? Colors.green
        : Colors.orange;
  }
}

enum ImageType { profile, license, car }