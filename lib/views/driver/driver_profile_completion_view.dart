import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/driver_model.dart';
import '../../services/user_management_service.dart';
import '../../services/image_upload_service.dart';

class DriverProfileCompletionView extends StatefulWidget {
  const DriverProfileCompletionView({super.key});

  @override
  State<DriverProfileCompletionView> createState() =>
      _DriverProfileCompletionViewState();
}

class _DriverProfileCompletionViewState
    extends State<DriverProfileCompletionView> {
  final UserManagementService _userService = Get.find<UserManagementService>();
  final ImageUploadService _imageService = Get.find<ImageUploadService>();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _drivingLicenseController = TextEditingController();
  final _vehicleLicenseController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();

  VehicleType _selectedVehicleType = VehicleType.car;
  bool _isLoading = false;
  String? _profileImage;
  String? _nationalIdImage;
  String? _drivingLicenseImage;
  String? _vehicleLicenseImage;
  String? _vehicleImage;
  String? _insuranceImage;
  String? _backgroundCheckImage;

  @override
  void initState() {
    super.initState();
    _loadCurrentDriverData();
  }

  void _loadCurrentDriverData() {
    final driver = _userService.currentDriver.value;
    if (driver != null) {
      _nameController.text = driver.name;
      _phoneController.text = driver.phone;
      _emailController.text = driver.email;
      _nationalIdController.text = driver.nationalId ?? '';
      _drivingLicenseController.text = driver.drivingLicense ?? '';
      _vehicleLicenseController.text = driver.vehicleLicense ?? '';
      _vehicleModelController.text = driver.vehicleModel ?? '';
      _vehicleColorController.text = driver.vehicleColor ?? '';
      _vehiclePlateController.text = driver.vehiclePlateNumber ?? '';
      _emergencyContactController.text = driver.emergencyContact ?? '';
      _emergencyContactNameController.text = driver.emergencyContactName ?? '';

      _profileImage = driver.profileImage;
      _nationalIdImage = driver.nationalIdImage;
      _drivingLicenseImage = driver.drivingLicenseImage;
      _vehicleLicenseImage = driver.vehicleLicenseImage;
      _vehicleImage = driver.vehicleImage;
      _insuranceImage = driver.insuranceImage;
      _backgroundCheckImage = driver.backgroundCheckImage;

      if (driver.vehicleType != null) {
        _selectedVehicleType = driver.vehicleType!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nationalIdController.dispose();
    _drivingLicenseController.dispose();
    _vehicleLicenseController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    _vehiclePlateController.dispose();
    _emergencyContactController.dispose();
    _emergencyContactNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String imageType) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() => _isLoading = true);

        final imageUrl = await _imageService.uploadImage(
          imageFile: File(image.path),
          folder: 'driver_documents',
          fileName: '${imageType}_${DateTime.now().millisecondsSinceEpoch}',
        );

        setState(() {
          switch (imageType) {
            case 'profile':
              _profileImage = imageUrl;
              break;
            case 'nationalId':
              _nationalIdImage = imageUrl;
              break;
            case 'drivingLicense':
              _drivingLicenseImage = imageUrl;
              break;
            case 'vehicleLicense':
              _vehicleLicenseImage = imageUrl;
              break;
            case 'vehicle':
              _vehicleImage = imageUrl;
              break;
            case 'insurance':
              _insuranceImage = imageUrl;
              break;
            case 'backgroundCheck':
              _backgroundCheckImage = imageUrl;
              break;
          }
        });
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في رفع الصورة: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final driver = _userService.currentDriver.value;
    if (driver == null) {
      Get.snackbar('خطأ', 'لم يتم العثور على بيانات السائق');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'nationalId': _nationalIdController.text.trim(),
        'nationalIdImage': _nationalIdImage,
        'drivingLicense': _drivingLicenseController.text.trim(),
        'drivingLicenseImage': _drivingLicenseImage,
        'vehicleLicense': _vehicleLicenseController.text.trim(),
        'vehicleLicenseImage': _vehicleLicenseImage,
        'vehicleType': _selectedVehicleType.name,
        'vehicleModel': _vehicleModelController.text.trim(),
        'vehicleColor': _vehicleColorController.text.trim(),
        'vehiclePlateNumber': _vehiclePlateController.text.trim(),
        'vehicleImage': _vehicleImage,
        'insuranceImage': _insuranceImage,
        'backgroundCheckImage': _backgroundCheckImage,
        'emergencyContact': _emergencyContactController.text.trim(),
        'emergencyContactName': _emergencyContactNameController.text.trim(),
        'isProfileComplete': _isProfileComplete(),
      };

      final success = await _userService.updateDriver(driver.id, data);

      if (success) {
        Get.snackbar(
          'نجح',
          'تم حفظ البيانات بنجاح',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // التحقق من اكتمال الملف
        final updatedDriver = _userService.currentDriver.value;
        if (updatedDriver?.isProfileFullyComplete == true) {
          Get.snackbar(
            'ممتاز!',
            'تم اكتمال ملفك الشخصي. سيتم مراجعته من قبل الإدارة قريباً.',
            backgroundColor: Colors.blue,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        }
      } else {
        Get.snackbar('خطأ', 'فشل في حفظ البيانات');
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء حفظ البيانات: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isProfileComplete() {
    return _nameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _nationalIdController.text.isNotEmpty &&
        _nationalIdImage != null &&
        _drivingLicenseController.text.isNotEmpty &&
        _drivingLicenseImage != null &&
        _vehicleLicenseController.text.isNotEmpty &&
        _vehicleLicenseImage != null &&
        _vehicleModelController.text.isNotEmpty &&
        _vehicleColorController.text.isNotEmpty &&
        _vehiclePlateController.text.isNotEmpty &&
        _vehicleImage != null &&
        _insuranceImage != null &&
        _backgroundCheckImage != null;
  }

  Widget _buildImagePicker(
      String title, String imageType, String? currentImage) {
    return Card(
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
            if (currentImage != null)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(currentImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _pickImage(imageType),
              icon: const Icon(Icons.upload),
              label: Text(currentImage != null ? 'تغيير الصورة' : 'رفع صورة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إكمال الملف الشخصي'),
        centerTitle: true,
      ),
      body: Obx(() {
        final driver = _userService.currentDriver.value;
        if (driver == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // حالة الملف الشخصي
                Card(
                  color: driver.isProfileFullyComplete
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          driver.isProfileFullyComplete
                              ? Icons.check_circle
                              : Icons.warning,
                          color: driver.isProfileFullyComplete
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            driver.isProfileFullyComplete
                                ? 'ملفك الشخصي مكتمل'
                                : 'يرجى إكمال جميع البيانات المطلوبة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: driver.isProfileFullyComplete
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // البيانات الأساسية
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
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'يرجى إدخال الاسم';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'يرجى إدخال رقم الهاتف';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true)
                      return 'يرجى إدخال البريد الإلكتروني';
                    if (!GetUtils.isEmail(value!))
                      return 'يرجى إدخال بريد إلكتروني صحيح';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // المستندات الشخصية
                const Text(
                  'المستندات الشخصية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _nationalIdController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهوية الوطنية',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'يرجى إدخال رقم الهوية';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                _buildImagePicker(
                    'صورة الهوية الوطنية', 'nationalId', _nationalIdImage),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _drivingLicenseController,
                  decoration: const InputDecoration(
                    labelText: 'رقم رخصة القيادة',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true)
                      return 'يرجى إدخال رقم رخصة القيادة';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                _buildImagePicker('صورة رخصة القيادة', 'drivingLicense',
                    _drivingLicenseImage),

                const SizedBox(height: 24),

                // بيانات المركبة
                const Text(
                  'بيانات المركبة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<VehicleType>(
                  value: _selectedVehicleType,
                  decoration: const InputDecoration(
                    labelText: 'نوع المركبة',
                    border: OutlineInputBorder(),
                  ),
                  items: VehicleType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getVehicleTypeText(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedVehicleType = value);
                    }
                  },
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _vehicleModelController,
                  decoration: const InputDecoration(
                    labelText: 'موديل السيارة',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true)
                      return 'يرجى إدخال موديل السيارة';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _vehicleColorController,
                  decoration: const InputDecoration(
                    labelText: 'لون السيارة',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'يرجى إدخال لون السيارة';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _vehiclePlateController,
                  decoration: const InputDecoration(
                    labelText: 'رقم اللوحة',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'يرجى إدخال رقم اللوحة';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _vehicleLicenseController,
                  decoration: const InputDecoration(
                    labelText: 'رقم رخصة السيارة',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true)
                      return 'يرجى إدخال رقم رخصة السيارة';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                _buildImagePicker('صورة رخصة السيارة', 'vehicleLicense',
                    _vehicleLicenseImage),
                const SizedBox(height: 8),

                _buildImagePicker('صورة السيارة', 'vehicle', _vehicleImage),
                const SizedBox(height: 8),

                _buildImagePicker('صورة التأمين', 'insurance', _insuranceImage),
                const SizedBox(height: 8),

                _buildImagePicker('فحص الخلفية الجنائية', 'backgroundCheck',
                    _backgroundCheckImage),

                const SizedBox(height: 24),

                // بيانات الطوارئ
                const Text(
                  'بيانات الطوارئ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _emergencyContactController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الطوارئ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _emergencyContactNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم جهة الطوارئ',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 32),

                // زر الحفظ
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('حفظ البيانات',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 16),

                // ملاحظة مهمة
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
                        '• يجب إكمال جميع البيانات المطلوبة\n'
                        '• سيتم مراجعة ملفك من قبل الإدارة\n'
                        '• لن تتمكن من استقبال الطلبات حتى تتم الموافقة\n'
                        '• يمكنك تحديث البيانات في أي وقت',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _getVehicleTypeText(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return 'سيارة';
      case VehicleType.motorcycle:
        return 'دراجة نارية';
      case VehicleType.van:
        return 'فان';
      case VehicleType.truck:
        return 'شاحنة';
    }
  }
}
