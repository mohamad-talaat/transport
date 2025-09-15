import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/driver_model.dart';
import 'package:transport_app/models/user_model.dart' as user_model;
import 'package:transport_app/services/user_management_service.dart';
import 'package:transport_app/services/image_upload_service.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/routes/app_routes.dart';

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
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  VehicleType _selectedVehicleType = VehicleType.car;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _nationalIdImage;
  String? _drivingLicenseImage;
  String? _vehicleImage;
  String? _insuranceImage;

  @override
  void initState() {
    super.initState();
    _initializeDriverData();
  }

  /// تهيئة بيانات السائق
  Future<void> _initializeDriverData() async {
    try {
      setState(() => _isInitializing = true);

      // الحصول على معرف المستخدم الحالي
      final authController = Get.find<AuthController>();
      final userId = authController.currentUser.value?.id;

      if (userId == null) {
        Get.snackbar('خطأ', 'لم يتم العثور على بيانات المستخدم');
        Get.back();
        return;
      }

      // تحميل بيانات السائق
      final driver = await _userService.getDriver(userId);

      if (driver != null) {
        _loadDriverDataToForm(driver);
      } else {
        // إنشاء سائق جديد إذا لم يكن موجوداً
        await _createNewDriver(userId, authController.currentUser.value!);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحميل بيانات السائق: $e');
      logger.w('خطأ في تحميل بيانات السائق: $e');
    } finally {
      setState(() => _isInitializing = false);
    }
  }

  /// تحميل بيانات السائق إلى النموذج
  void _loadDriverDataToForm(DriverModel driver) {
    _nameController.text = driver.name;
    _phoneController.text = driver.phone;
    _emailController.text = driver.email;
    _nationalIdController.text = driver.nationalId ?? '';
    _drivingLicenseController.text = driver.drivingLicense ?? '';
    _vehicleModelController.text = driver.vehicleModel ?? '';
    _vehicleColorController.text = driver.vehicleColor ?? '';
    _vehiclePlateController.text = driver.vehiclePlateNumber ?? '';
    _emergencyContactController.text = driver.emergencyContact ?? '';

    // _profileImage = driver.profileImage;
    _nationalIdImage = driver.nationalIdImage;
    _drivingLicenseImage = driver.drivingLicenseImage;
    _vehicleImage = driver.vehicleImage;
    _insuranceImage = driver.insuranceImage;

    if (driver.vehicleType != null) {
      _selectedVehicleType = driver.vehicleType!;
    }
  }

  /// إنشاء سائق جديد
  Future<void> _createNewDriver(
      String userId, user_model.UserModel user) async {
    try {
      final driver = await _userService.createDriver(
        id: userId,
        name: user.name,
        phone: user.phone,
        email: user.email,
        profileImage: user.profileImage,
      );

      if (driver != null) {
        _loadDriverDataToForm(driver);
      }
    } catch (e) {
      logger.w('خطأ في إنشاء سائق جديد: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nationalIdController.dispose();
    _drivingLicenseController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    _vehiclePlateController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String imageType) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        // عرض رسالة تقدم
        Get.snackbar(
          'جاري الرفع',
          'يرجى الانتظار...',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );

        final imageUrl = await _imageService.uploadImage(
          imageFile: File(image.path),
          folder: 'driver_documents',
          fileName: '${imageType}_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (imageUrl != null) {
          setState(() {
            switch (imageType) {
              case 'profile':
                // _profileImage = imageUrl;
                break;
              case 'nationalId':
                _nationalIdImage = imageUrl;
                break;
              case 'drivingLicense':
                _drivingLicenseImage = imageUrl;
                break;
              case 'vehicle':
                _vehicleImage = imageUrl;
                break;
              case 'insurance':
                _insuranceImage = imageUrl;
                break;
            }
          });

          Get.snackbar(
            'نجح',
            'تم رفع الصورة بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: Duration(seconds: 2),
          );
        } else {
          Get.snackbar(
            'خطأ',
            'فشل في رفع الصورة، يرجى المحاولة مرة أخرى',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      logger.w('خطأ في رفع الصورة: $e');
      Get.snackbar(
        'خطأ',
        'فشل في رفع الصورة: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
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

    final driver = _userService.currentDriver.value;
    if (driver == null) {
      Get.snackbar(
        'خطأ',
        'لم يتم العثور على بيانات السائق',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // عرض رسالة التحميل
      Get.snackbar(
        'جاري الحفظ',
        'يرجى الانتظار...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
      final data = {
        // البيانات الأساسية
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'nationalId': _nationalIdController.text.trim(),
        'nationalIdImage': _nationalIdImage,
        'drivingLicense': _drivingLicenseController.text.trim(),
        'drivingLicenseImage': _drivingLicenseImage,
        'vehicleType': _selectedVehicleType.name,
        'vehicleModel': _vehicleModelController.text.trim(),
        'vehicleColor': _vehicleColorController.text.trim(),
        'vehiclePlateNumber': _vehiclePlateController.text.trim(),
        'vehicleImage': _vehicleImage,
        'insuranceImage': _insuranceImage,
        'emergencyContact': _emergencyContactController.text.trim(),
        'isProfileComplete': _isProfileComplete(),
        'updatedAt': DateTime.now(),

        // إضافة البيانات للتوافق مع العرض
        'additionalData': {
          'carModel': _vehicleModelController.text.trim(),
          'carColor': _vehicleColorController.text.trim(),
          'carNumber': _vehiclePlateController.text.trim(),
          'carType': _selectedVehicleType.name,
          'licenseNumber': _drivingLicenseController.text.trim(),
          'licenseImage': _drivingLicenseImage,
          'idCardImage': _nationalIdImage,
          'vehicleRegistrationImage': _vehicleImage,
          'insuranceImage': _insuranceImage,
          'emergencyContact': _emergencyContactController.text.trim(),
          'carImage': _vehicleImage,
        },
      };

      // إذا كان الملف مكتمل، ضع الحالة كـ pending
      if (_isProfileComplete()) {
        data['status'] = 'pending';
        data['isApproved'] = false;
        data['isRejected'] = false;
      }

      final success = await _userService.updateDriver(driver.id, data);

      if (success) {
        Get.snackbar(
          'نجح',
          'تم حفظ البيانات بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );

        // التحقق من اكتمال الملف
        final updatedDriver = _userService.currentDriver.value;
        if (updatedDriver?.isProfileFullyComplete == true) {
          Get.snackbar(
            'ممتاز!',
            'تم اكتمال ملفك الشخصي. سيتم مراجعته من قبل الإدارة قريباً.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blue,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        } else {
          Get.snackbar(
            'تم الحفظ',
            'يرجى إكمال جميع البيانات المطلوبة',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }

        // الانتقال للهوم درايفر بعد حفظ البيانات (سواء مكتمل أم لا)
        Future.delayed(const Duration(seconds: 2), () {
          Get.offAllNamed(AppRoutes.DRIVER_HOME);
        });
      } else {
        Get.snackbar(
          'خطأ',
          'فشل في حفظ البيانات، يرجى المحاولة مرة أخرى',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      logger.w('خطأ في حفظ البيانات: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء حفظ البيانات: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
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
        _vehicleModelController.text.isNotEmpty &&
        _vehicleColorController.text.isNotEmpty &&
        _vehiclePlateController.text.isNotEmpty &&
        _vehicleImage != null &&
        _insuranceImage != null;
  }

  /// الحصول على قائمة الحقول الناقصة
  List<String> _getMissingFields() {
    final List<String> missingFields = [];

    if (_nameController.text.isEmpty) missingFields.add('الاسم الكامل');
    if (_phoneController.text.isEmpty) missingFields.add('رقم الهاتف');
    if (_emailController.text.isEmpty) missingFields.add('البريد الإلكتروني');
    if (_nationalIdController.text.isEmpty) {
      missingFields.add('رقم الهوية الوطنية');
    }
    if (_nationalIdImage == null) missingFields.add('صورة الهوية الوطنية');
    if (_drivingLicenseController.text.isEmpty) {
      missingFields.add('رقم رخصة القيادة');
    }
    if (_drivingLicenseImage == null) missingFields.add('صورة رخصة القيادة');
    if (_vehicleModelController.text.isEmpty) {
      missingFields.add('موديل السيارة');
    }
    if (_vehicleColorController.text.isEmpty) missingFields.add('لون السيارة');
    if (_vehiclePlateController.text.isEmpty) missingFields.add('رقم اللوحة');
    if (_vehicleImage == null) missingFields.add('صورة السيارة');
    if (_insuranceImage == null) missingFields.add('صورة التأمين');

    return missingFields;
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
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
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
                  ),
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _pickImage(imageType),
              icon: _isLoading
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
                _isLoading
                    ? 'جاري الرفع...'
                    : (currentImage != null ? 'تغيير الصورة' : 'رفع صورة'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    currentImage != null ? Colors.orange : Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
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
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل البيانات...'),
                ],
              ),
            )
          : Obx(() {
              final driver = _userService.currentDriver.value;
              if (driver == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('فشل في تحميل بيانات السائق'),
                    ],
                  ),
                );
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                              if (!driver.isProfileFullyComplete) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'الحقول الناقصة: ${_getMissingFields().join(', ')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // البيانات الأساسية
                      const Text(
                        'البيانات الأساسية',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
                          if (value?.isEmpty ?? true) {
                            return 'يرجى إدخال رقم الهاتف';
                          }
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
                          if (value?.isEmpty ?? true) {
                            return 'يرجى إدخال البريد الإلكتروني';
                          }
                          if (!GetUtils.isEmail(value!)) {
                            return 'يرجى إدخال بريد إلكتروني صحيح';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // المستندات الشخصية
                      const Text(
                        'المستندات الشخصية',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _nationalIdController,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهوية الوطنية',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'يرجى إدخال رقم الهوية';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      _buildImagePicker('صورة الهوية الوطنية', 'nationalId',
                          _nationalIdImage),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _drivingLicenseController,
                        decoration: const InputDecoration(
                          labelText: 'رقم رخصة القيادة',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'يرجى إدخال رقم رخصة القيادة';
                          }
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      DropdownButtonFormField<VehicleType>(
                        initialValue: _selectedVehicleType,
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
                          if (value?.isEmpty ?? true) {
                            return 'يرجى إدخال موديل السيارة';
                          }
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
                          if (value?.isEmpty ?? true) {
                            return 'يرجى إدخال لون السيارة';
                          }
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
                          if (value?.isEmpty ?? true) {
                            return 'يرجى إدخال رقم اللوحة';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      _buildImagePicker(
                          'صورة السيارة', 'vehicle', _vehicleImage),
                      const SizedBox(height: 8),

                      _buildImagePicker(
                          'صورة التأمين', 'insurance', _insuranceImage),

                      const SizedBox(height: 24),

                      // بيانات الطوارئ
                      const Text(
                        'بيانات الطوارئ',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _emergencyContactController,
                        decoration: const InputDecoration(
                          labelText: 'رقم الطوارئ',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // زر الحفظ
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.blue, // لون الخلفية (الأزرق)
                            foregroundColor: Colors.white, // لون النص/الأيقونات
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  12), // لو عايز زوايا مدورة
                            ),
                          ),
                          onPressed: _isLoading ? null : _saveProfile,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'حفظ البيانات',
                                  style: TextStyle(fontSize: 16),
                                ),
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
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
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
