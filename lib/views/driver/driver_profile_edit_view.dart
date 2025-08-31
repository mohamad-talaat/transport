import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/services/driver_profile_service.dart';
import 'package:transport_app/services/image_upload_service.dart';
import 'dart:io';

class DriverProfileEditView extends StatefulWidget {
  const DriverProfileEditView({super.key});

  @override
  State<DriverProfileEditView> createState() => _DriverProfileEditViewState();
}

class _DriverProfileEditViewState extends State<DriverProfileEditView> {
  final AuthController authController = Get.find<AuthController>();
  final DriverProfileService profileService = Get.find<DriverProfileService>();
  final ImageUploadService imageService = Get.find<ImageUploadService>();

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _serviceAreaController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  // Loading states
  bool _isLoading = false;
  final bool _isUploadingProfileImage = false;
  final bool _isUploadingIdCard = false;
  final bool _isUploadingLicense = false;
  final bool _isUploadingVehicle = false;

  // Image files
  File? _profileImageFile;
  File? _idCardImageFile;
  File? _licenseImageFile;
  File? _vehicleImageFile;

  // Dropdown values
  String? _selectedVehicleColor;
  String? _selectedServiceArea;
  bool _isVerified = false;
  bool _isActive = false;

  final List<String> _vehicleColors = [
    'أبيض',
    'أسود',
    'أحمر',
    'أزرق',
    'أخضر',
    'أصفر',
    'رمادي',
    'فضي',
    'بني',
    'أخرى'
  ];

  final List<String> _serviceAreas = [
    'البصرة المركز',
    'القرنة',
    'أبو الخصيب',
    'الزبير',
    'الهارثة',
    'شط العرب',
    'أخرى'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    _licensePlateController.dispose();
    _licenseNumberController.dispose();
    _vehicleYearController.dispose();
    _serviceAreaController.dispose();
    _bankAccountController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentData() async {
    try {
      final user = authController.currentUser.value;
      if (user != null) {
        _nameController.text = user.name ?? '';
        _phoneController.text = user.phone ?? '';
        _emailController.text = user.email ?? '';

        final additionalData = user.additionalData ?? {};
        _vehicleModelController.text = additionalData['vehicleModel'] ?? '';
        _vehicleColorController.text = additionalData['vehicleColor'] ?? '';
        _licensePlateController.text = additionalData['licensePlate'] ?? '';
        _licenseNumberController.text = additionalData['licenseNumber'] ?? '';
        _vehicleYearController.text = additionalData['vehicleYear'] ?? '';
        _serviceAreaController.text = additionalData['serviceArea'] ?? '';
        _bankAccountController.text = additionalData['bankAccount'] ?? '';
        _emergencyContactController.text =
            additionalData['emergencyContact'] ?? '';

        _selectedVehicleColor = additionalData['vehicleColor'];
        _selectedServiceArea = additionalData['serviceArea'];
        _isVerified = additionalData['isVerified'] ?? false;
        _isActive = additionalData['isActive'] ?? false;
      }
    } catch (e) {
      print('خطأ في تحميل البيانات: $e');
    }
  }

  Future<void> _pickImage(String type) async {
    try {
      File? imageFile;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('اختر $type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('من المعرض'),
                onTap: () async {
                  Navigator.pop(context);
                  imageFile = await imageService.pickImageFromGallery();
                  _setImageFile(type, imageFile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('كاميرا'),
                onTap: () async {
                  Navigator.pop(context);
                  imageFile = await imageService.takePhotoWithCamera();
                  _setImageFile(type, imageFile);
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('خطأ في اختيار الصورة: $e');
    }
  }

  void _setImageFile(String type, File? file) {
    if (file != null) {
      setState(() {
        switch (type) {
          case 'profile':
            _profileImageFile = file;
            break;
          case 'idCard':
            _idCardImageFile = file;
            break;
          case 'license':
            _licenseImageFile = file;
            break;
          case 'vehicle':
            _vehicleImageFile = file;
            break;
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final userId = authController.currentUser.value?.id;
      if (userId == null) throw Exception('المستخدم غير موجود');

      // رفع الصور
      String? profileImageUrl;
      String? idCardImageUrl;
      String? licenseImageUrl;
      String? vehicleImageUrl;

      if (_profileImageFile != null) {
        profileImageUrl = await imageService.uploadImage(
          imageFile: _profileImageFile!,
          folder: 'profile_images',
          fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      if (_idCardImageFile != null) {
        idCardImageUrl = await imageService.uploadImage(
          imageFile: _idCardImageFile!,
          folder: 'id_cards',
          fileName: 'idcard_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      if (_licenseImageFile != null) {
        licenseImageUrl = await imageService.uploadImage(
          imageFile: _licenseImageFile!,
          folder: 'licenses',
          fileName: 'license_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      if (_vehicleImageFile != null) {
        vehicleImageUrl = await imageService.uploadImage(
          imageFile: _vehicleImageFile!,
          folder: 'vehicles',
          fileName: 'vehicle_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // تجهيز البيانات للتحديث
      final updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'vehicleModel': _vehicleModelController.text.trim(),
        'vehicleColor':
            _selectedVehicleColor ?? _vehicleColorController.text.trim(),
        'licensePlate': _licensePlateController.text.trim(),
        'licenseNumber': _licenseNumberController.text.trim(),
        'vehicleYear': _vehicleYearController.text.trim(),
        'serviceArea':
            _selectedServiceArea ?? _serviceAreaController.text.trim(),
        'bankAccount': _bankAccountController.text.trim(),
        'emergencyContact': _emergencyContactController.text.trim(),
        'isVerified': _isVerified,
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // إضافة روابط الصور إذا تم رفعها
      if (profileImageUrl != null) updateData['profileImage'] = profileImageUrl;
      if (idCardImageUrl != null) updateData['idCardImage'] = idCardImageUrl;
      if (licenseImageUrl != null) updateData['licenseImage'] = licenseImageUrl;
      if (vehicleImageUrl != null) updateData['vehicleImage'] = vehicleImageUrl;

      // تحديث البيانات في Firebase
      await profileService.updateProfileCompletion(userId, updateData);

      // تحديث حالة اكتمال البروفايل
      await profileService.markProfileComplete(userId);

      // تحديث البيانات المحلية
      await authController.loadUserData(userId);

      Get.snackbar(
        'تم الحفظ',
        'تم حفظ البيانات بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.back();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء حفظ البيانات: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPersonalInfoSection(),
              const SizedBox(height: 20),
              _buildVehicleInfoSection(),
              const SizedBox(height: 20),
              _buildImagesSection(),
              const SizedBox(height: 20),
              _buildSettingsSection(),
              const SizedBox(height: 30),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المعلومات الشخصية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال الاسم';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال رقم الهاتف';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال البريد الإلكتروني';
                }
                if (!GetUtils.isEmail(value)) {
                  return 'يرجى إدخال بريد إلكتروني صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyContactController,
              decoration: const InputDecoration(
                labelText: 'جهة اتصال للطوارئ *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.emergency),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال جهة اتصال للطوارئ';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات المركبة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vehicleModelController,
              decoration: const InputDecoration(
                labelText: 'موديل السيارة *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_car),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال موديل السيارة';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedVehicleColor,
              decoration: const InputDecoration(
                labelText: 'لون السيارة *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.color_lens),
              ),
              items: _vehicleColors.map((color) {
                return DropdownMenuItem(value: color, child: Text(color));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedVehicleColor = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى اختيار لون السيارة';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _licensePlateController,
              decoration: const InputDecoration(
                labelText: 'رقم اللوحة *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال رقم اللوحة';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _licenseNumberController,
              decoration: const InputDecoration(
                labelText: 'رقم الرخصة *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.card_membership),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال رقم الرخصة';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vehicleYearController,
              decoration: const InputDecoration(
                labelText: 'سنة السيارة *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال سنة السيارة';
                }
                final year = int.tryParse(value);
                if (year == null || year < 1990 || year > DateTime.now().year) {
                  return 'سنة غير صحيحة';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedServiceArea,
              decoration: const InputDecoration(
                labelText: 'منطقة العمل *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              items: _serviceAreas.map((area) {
                return DropdownMenuItem(value: area, child: Text(area));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedServiceArea = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى اختيار منطقة العمل';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankAccountController,
              decoration: const InputDecoration(
                labelText: 'الحساب البنكي *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال الحساب البنكي';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الصور المطلوبة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildImageUpload(
              'الصورة الشخصية',
              _profileImageFile,
              authController.currentUser.value?.profileImage,
              () => _pickImage('profile'),
              _isUploadingProfileImage,
            ),
            const SizedBox(height: 16),
            _buildImageUpload(
              'صورة الهوية',
              _idCardImageFile,
              authController.currentUser.value?.additionalData?['idCardImage'],
              () => _pickImage('idCard'),
              _isUploadingIdCard,
            ),
            const SizedBox(height: 16),
            _buildImageUpload(
              'صورة الرخصة',
              _licenseImageFile,
              authController.currentUser.value?.additionalData?['licenseImage'],
              () => _pickImage('license'),
              _isUploadingLicense,
            ),
            const SizedBox(height: 16),
            _buildImageUpload(
              'صورة السيارة',
              _vehicleImageFile,
              authController.currentUser.value?.additionalData?['vehicleImage'],
              () => _pickImage('vehicle'),
              _isUploadingVehicle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUpload(String title, File? file, String? currentUrl,
      VoidCallback onTap, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title *',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isLoading ? null : onTap,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: file != null || currentUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: file != null
                        ? Image.file(file,
                            fit: BoxFit.cover, width: double.infinity)
                        : Image.network(currentUrl!,
                            fit: BoxFit.cover, width: double.infinity),
                  )
                : Center(
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  color: Colors.grey.shade400),
                              const SizedBox(height: 4),
                              Text(
                                'إضافة $title',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إعدادات الحساب',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('الحساب مفعل'),
              subtitle: const Text('يمكنك استقبال الطلبات'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            SwitchListTile(
              title: const Text('التحقق من الهوية'),
              subtitle: const Text('تم التحقق من هويتك'),
              value: _isVerified,
              onChanged: (value) => setState(() => _isVerified = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'حفظ البيانات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
