import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/services/unified_image_service.dart';
import 'package:transport_app/services/user_management_service.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/routes/app_routes.dart';

class DriverProfileCompletionView extends StatefulWidget {
  const DriverProfileCompletionView({super.key});

  @override
  State<DriverProfileCompletionView> createState() =>
      _DriverProfileCompletionViewEnhancedState();
}

class _DriverProfileCompletionViewEnhancedState
    extends State<DriverProfileCompletionView> {
  final UserManagementService _userService = Get.find<UserManagementService>();
  final ImageUploadService _imageService = Get.find<ImageUploadService>();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  // final _vehiclePlateController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  final _vehicleNumberController = TextEditingController();
  final _vehicleLetterController = TextEditingController();
  final _vehicleGovernorateController = TextEditingController();

  VehicleType _selectedVehicleType = VehicleType.car;
  bool _isLoading = false;
  bool _isInitializing = true;

  String? _profileImage;
  String? _nationalIdImageFront;
  String? _nationalIdImageBack;
  String? _drivingLicenseImageFront;
  String? _drivingLicenseImageBack;
  String? _vehicleImage;
  // String? _vehicleRegistrationImage;
  // String? _insuranceImage;
  String? _ownershipDocumentImage;

  bool _isVehicleOwned = true;

  @override
  void initState() {
    super.initState();
    _initializeDriverData();
  }

  Future<void> _initializeDriverData() async {
    try {
      setState(() => _isInitializing = true);

      final authController = Get.find<AuthController>();
      final userId = authController.currentUser.value?.id;

      if (userId == null) {
        Get.snackbar('خطأ', 'لم يتم العثور على بيانات المستخدم');
        Get.back();
        return;
      }

      final driver = await _userService.getDriver(userId);

      if (driver != null) {
        _loadDriverDataToForm(driver);
      } else {
        await _createNewDriver(userId, authController.currentUser.value!);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحميل بيانات السائق: $e');
      logger.w('خطأ في تحميل بيانات السائق: $e');
    } finally {
      setState(() => _isInitializing = false);
    }
  }

  void _loadDriverDataToForm(UserModel driver) {
    _nameController.text = driver.name;
    _phoneController.text = driver.phone;
    _emailController.text = driver.email;

    _vehicleModelController.text = driver.vehicleModel ?? '';
    _vehicleColorController.text = driver.vehicleColor ?? '';
    _vehicleYearController.text = driver.vehicleYear.toString() ?? '';
    // _vehiclePlateController.text = driver.vehiclePlateNumber ?? '';
    
    _vehicleNumberController.text = driver.provinceCode ?? '';
    _vehicleLetterController.text = driver.plateLetter ?? '';
    _vehicleGovernorateController.text = driver.provinceName ?? '';

    _emergencyContactController.text = driver.emergencyContact ?? '';

    _profileImage = driver.profileImage;
    _nationalIdImageFront = driver.nationalIdImage;
    _drivingLicenseImageFront = driver.drivingLicenseImage;
    _vehicleImage = driver.vehicleImage;
    // _insuranceImage = driver.insuranceImage;

    if (driver.additionalData != null) {
      final additionalData = driver.additionalData!;
      _nationalIdImageBack = additionalData['nationalIdImageBack'];
      _drivingLicenseImageBack = additionalData['drivingLicenseImageBack'];
      // _vehicleRegistrationImage = additionalData['vehicleRegistrationImage'];
      _ownershipDocumentImage = additionalData['ownershipDocumentImage'];
      _isVehicleOwned = additionalData['isVehicleOwned'] ?? true;
    }

    if (driver.vehicleType != null) {
      _selectedVehicleType = driver.vehicleType!;
    }
  }

  Future<void> _createNewDriver(String userId, UserModel user) async {
    try {
      final driver = await _userService.createDriver(
        id: userId,
        name: user.name,
        phone: user.phone.trim(),
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

    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    _vehicleYearController.dispose();
    // _vehiclePlateController.dispose();

    _vehicleNumberController.dispose();
    _vehicleLetterController.dispose();
    _vehicleGovernorateController.dispose();


    _emergencyContactController.dispose();
    super.dispose();
  }
  


  Future<void> _pickImage(String imageType) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        Get.snackbar(
          'جاري الرفع',
          'يرجى الانتظار...',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // هنا يجب أن تعيد دالة uploadImage الآن URL ImgBB
        final imageUrl = await _imageService.uploadImage(
          imageFile: File(image.path),
          folder: 'driver_documents_iraq', // هذا قد لا يستخدمه ImgBB مباشرة
          fileName: '${imageType}_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (imageUrl != null) {
          setState(() {
            switch (imageType) {
              case 'profile':
                _profileImage = imageUrl; // <--- هنا يتم حفظ الـ URL الصحيح الآن
                break;
              case 'nationalIdFront':
                _nationalIdImageFront = imageUrl;
                break;
              case 'nationalIdBack':
                _nationalIdImageBack = imageUrl;
                break;
              case 'drivingLicenseFront':
                _drivingLicenseImageFront = imageUrl;
                break;
              case 'drivingLicenseBack':
                _drivingLicenseImageBack = imageUrl;
                break;
              case 'vehicle':
                _vehicleImage = imageUrl;
                break;
              // case 'vehicleRegistration':
              //   _vehicleRegistrationImage = imageUrl;
              //   break;
              // case 'insurance':
              //   _insuranceImage = imageUrl;
              //   break;
              case 'ownershipDocument':
                _ownershipDocumentImage = imageUrl;
                break;
            }
          });
          logger.i('تم رفع الصورة بنجاح. URL: $imageUrl');
          Get.snackbar(
            'نجح',
            'تم رفع الصورة بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
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
      Get.snackbar(
        'جاري الحفظ',
        'يرجى الانتظار...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      final data = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'profileImage': _profileImage,
        'nationalIdImage': _nationalIdImageFront,
        'drivingLicenseImage': _drivingLicenseImageFront,
        'vehicleType': _selectedVehicleType.name,
        'vehicleModel': _vehicleModelController.text.trim(),
        'vehicleColor': _vehicleColorController.text.trim(),
        


        // 'vehiclePlateNumber': _vehiclePlateController.text.trim(),
        'provinceCode': _vehicleNumberController.text.trim(),
        'plateLetter': _vehicleLetterController.text.trim(),
        'provinceName': _vehicleGovernorateController.text.trim(),

        'vehicleImage': _vehicleImage,
        // 'vehicleRegistrationImage': _vehicleRegistrationImage,
'vehicleYear': int.tryParse(_vehicleYearController.text.trim()) ?? 0,
        // 'insuranceImage': _insuranceImage,
        'emergencyContact': _emergencyContactController.text.trim(),
        'isProfileComplete': _isProfileComplete(),
        'updatedAt': DateTime.now(),
        'additionalData': {
          'profileImage': _profileImage,
          'nationalIdImageFront': _nationalIdImageFront,
          'nationalIdImageBack': _nationalIdImageBack,
          'drivingLicenseImageFront': _drivingLicenseImageFront,
          'drivingLicenseImageBack': _drivingLicenseImageBack,
          // 'vehicleRegistrationImage': _vehicleRegistrationImage,
          'ownershipDocumentImage': _ownershipDocumentImage,
          'isVehicleOwned': _isVehicleOwned,
          'carModel': _vehicleModelController.text.trim(),
          'carColor': _vehicleColorController.text.trim(),

         // 'carNumber': //_vehiclePlateController.text.trim(),
           "plateNumber": _vehicleNumberController.text.trim(), 
          "plateLetter": _vehicleLetterController.text.trim(),
          "provinceName": _vehicleGovernorateController.text.trim(),
 




          'carType': _selectedVehicleType.name,
          'licenseImage': _drivingLicenseImageFront,
          'idCardImage': _nationalIdImageFront,
          // 'vehicleRegistrationImage': _vehicleRegistrationImage,
          // 'insuranceImage': _insuranceImage,
          'emergencyContact': _emergencyContactController.text.trim(),
          'carImage': _vehicleImage,
        },
      };

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
          duration: const Duration(seconds: 2),
        );

        final updatedDriver = _userService.currentDriver.value;
        if (updatedDriver?.isDriverProfileComplete == true) {
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
        duration: const Duration(seconds: 5),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isProfileComplete() {
    final basicComplete = _nameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _profileImage != null &&
        _nationalIdImageFront != null &&
        _nationalIdImageBack != null &&
        _drivingLicenseImageFront != null &&
        _drivingLicenseImageBack != null &&
        _vehicleModelController.text.isNotEmpty &&
        _vehicleColorController.text.isNotEmpty &&
        _vehicleNumberController.text.isNotEmpty &&

        // _vehiclePlateController.text.isNotEmpty &&
        _vehicleNumberController.text.isNotEmpty &&
        _vehicleLetterController.text.isNotEmpty &&
        _vehicleGovernorateController.text.isNotEmpty &&
        _vehicleImage != null;
        // _vehicleRegistrationImage != null &&
        // _insuranceImage != null;

    if (!_isVehicleOwned && _ownershipDocumentImage == null) {
      return false;
    }

    return basicComplete;
  }

  List<String> _getMissingFields() {
    final List<String> missingFields = [];

    if (_nameController.text.isEmpty) missingFields.add('الاسم الكامل');
    if (_phoneController.text.isEmpty) missingFields.add('رقم الهاتف');
    if (_emailController.text.isEmpty) missingFields.add('البريد الإلكتروني');
    if (_profileImage == null) missingFields.add('الصورة الشخصية');

    if (_nationalIdImageFront == null) {
      missingFields.add('صورة الهوية (الوجه الأمامي)');
    }
    if (_nationalIdImageBack == null) {
      missingFields.add('صورة الهوية (الوجه الخلفي)');
    }

    if (_drivingLicenseImageFront == null) {
      missingFields.add('صورة رخصة القيادة (الوجه الأمامي)');
    }
    if (_drivingLicenseImageBack == null) {
      missingFields.add('صورة رخصة القيادة (الوجه الخلفي)');
    }
    if (_vehicleModelController.text.isEmpty) {
      missingFields.add('موديل السيارة');
    }
    if (_vehicleColorController.text.isEmpty) missingFields.add('لون السيارة');
    if (_vehicleYearController.text.isEmpty) missingFields.add('سنة أصدار السيارة');

    // if (_vehiclePlateController.text.isEmpty) missingFields.add('رقم اللوحة');
    if (_vehicleNumberController.text.isEmpty) {
      missingFields.add('رقم الرخصة');
    }
    if (_vehicleLetterController.text.isEmpty) {
      missingFields.add('رقم السيارة');
    }
    if (_vehicleGovernorateController.text.isEmpty) {
      missingFields.add('منطقة السيارة');
    }
    if (_vehicleImage == null) missingFields.add('صورة السيارة');
    // if (_vehicleRegistrationImage == null) {
    //   missingFields.add('صورة استمارة السيارة');
    // }
    // if (_insuranceImage == null) missingFields.add('صورة التأمين');
    if (!_isVehicleOwned && _ownershipDocumentImage == null) {
      missingFields.add('صورة المكاتبة');
    }

    return missingFields;
  }

  Widget _buildImagePicker(String title, String imageType, String? currentImage,
      {String? subtitle}) {
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
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 8),
            if (currentImage != null) // If there's an image path
              Column(
                children: [
                  // Text('URL الصورة: $currentImage', style: TextStyle(fontSize: 10, color: Colors.blue)),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: currentImage
                              .startsWith('http') // Check if it's a web URL
                          ? Image.network(
                              currentImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                logger.e(
                                    'خطأ تحميل Image.network لـ $imageType: $error');
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.error,
                                      color: Colors.red, size: 48),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                      child: CircularProgressIndicator()),
                                );
                              },
                            )
                          : Image.file(
                              // Otherwise, assume it's a local file path
                              File(
                                  currentImage), // Use Image.file for local paths
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                logger.e(
                                    'خطأ تحميل Image.file لـ $imageType: $error');
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.error,
                                      color: Colors.red, size: 48),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              )
            else // If currentImage is null
              Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey.shade100,
                child: Center(
                  child: Text('لا توجد صورة لـ $title',
                      style: const TextStyle(color: Colors.grey)),
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
        title: const Text('إكمال الملف الشخصي - العراق'),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
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
                      Card(
                        color: driver.isDriverProfileComplete
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
                                    driver.isDriverProfileComplete
                                        ? Icons.check_circle
                                        : Icons.warning,
                                    color: driver.isDriverProfileComplete
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      driver.isDriverProfileComplete
                                          ? 'ملفك الشخصي مكتمل'
                                          : 'يرجى إكمال جميع البيانات المطلوبة',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: driver.isDriverProfileComplete
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (!driver.isDriverProfileComplete) ...[
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
                          prefixIcon: Icon(Icons.person),
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
                          prefixIcon: Icon(Icons.phone),
                          hintText: '+964xxxxxxxxx',
                        ),
                        keyboardType: TextInputType.phone,
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
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
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
                      const SizedBox(height: 8),
                      _buildImagePicker(
                        'الصورة الشخصية',
                        'profile',
                        _profileImage,
                        subtitle: 'صورة واضحة لوجهك بدون نظارة شمسية',
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(height: 8),
                      _buildImagePicker(
                        'صورة الهوية الوطنية (الوجه الأمامي)',
                        'nationalIdFront',
                        _nationalIdImageFront,
                        subtitle: 'صورة واضحة للوجه الأمامي للهوية',
                      ),
                      _buildImagePicker(
                        'صورة الهوية الوطنية (الوجه الخلفي)',
                        'nationalIdBack',
                        _nationalIdImageBack,
                        subtitle: 'صورة واضحة للوجه الخلفي للهوية',
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(height: 8),
                      _buildImagePicker(
                        'صورة رخصة القيادة (الوجه الأمامي)',
                        'drivingLicenseFront',
                        _drivingLicenseImageFront,
                        subtitle: 'صورة واضحة للوجه الأمامي للرخصة',
                      ),
                      _buildImagePicker(
                        'صورة رخصة القيادة (الوجه الخلفي)',
                        'drivingLicenseBack',
                        _drivingLicenseImageBack,
                        subtitle: 'صورة واضحة للوجه الخلفي للرخصة',
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'بيانات المركبة',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ملكية المركبة',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              RadioListTile<bool>(
                                title: const Text('المركبة مملوكة لي'),
                                value: true,
                                groupValue: _isVehicleOwned,
                                onChanged: (value) {
                                  setState(() {
                                    _isVehicleOwned = value ?? true;
                                  });
                                },
                              ),
                              RadioListTile<bool>(
                                title: const Text('المركبة مستأجرة/غير مملوكة'),
                                subtitle: const Text('سيتطلب رفع المكاتبة'),
                                value: false,
                                groupValue: _isVehicleOwned,
                                onChanged: (value) {
                                  setState(() {
                                    _isVehicleOwned = value ?? true;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<VehicleType>(
                        value: _selectedVehicleType,
                        decoration: const InputDecoration(
                          labelText: 'نوع المركبة',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_car),
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
                          prefixIcon: Icon(Icons.car_rental),
                          hintText: 'مثال: تويوتا كورولا ',
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
                        controller: _vehicleYearController,
                        decoration: const InputDecoration(
                          labelText: 'سنة الاصدار',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.car_rental),
                          hintText: 'مثال:2020',
                        ),
                     keyboardType: TextInputType.phone,

                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'يرجى إدخال سنةأصدار السيارة';
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
                          prefixIcon: Icon(Icons.color_lens),
                          hintText: 'مثال: أبيض، أسود، رمادي',
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'يرجى إدخال لون السيارة';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.black87, width: 2),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(1, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // أرقام اللوحة
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _vehicleNumberController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: 'أرقام اللوحة',
                                  labelStyle: const TextStyle(fontSize: 13),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        const BorderSide(color: Colors.black54),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Colors.blueAccent, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 8),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'أدخل الأرقام'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // الحرف (اختياري)
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _vehicleLetterController,
                                maxLength: 1,
                                textAlign: TextAlign.center,
                                textCapitalization:
                                    TextCapitalization.characters,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: 'حرف',
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        const BorderSide(color: Colors.black54),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Colors.blueAccent, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // المحافظة
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _vehicleGovernorateController,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: 'المحافظة',
                                  labelStyle: const TextStyle(fontSize: 13),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        const BorderSide(color: Colors.black54),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Colors.blueAccent, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 8),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'أدخل المحافظة'
                                        : null,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // TextFormField(
                      //   controller: _vehiclePlateController,
                      //   decoration: const InputDecoration(
                      //     labelText: 'رقم اللوحة',
                      //     border: OutlineInputBorder(),
                      //     prefixIcon: Icon(Icons.confirmation_number),
                      //     hintText: 'رقم اللوحة العراقية',
                      //   ),
                      //   validator: (value) {
                      //     if (value?.isEmpty ?? true) {
                      //       return 'يرجى إدخال رقم اللوحة';
                      //     }
                      //     return null;
                      //   },
                      // ),

                      const SizedBox(height: 8),
                      _buildImagePicker(
                        'صورة السيارة',
                        'vehicle',
                        _vehicleImage,
                        subtitle: 'صورة واضحة للسيارة من الخارج',
                      ),
                      // _buildImagePicker(
                      //   'صورة استمارة السيارة',
                      //   'vehicleRegistration',
                      //   _vehicleRegistrationImage,
                      //   subtitle: 'صورة استمارة التسجيل الرسمية للسيارة',
                      // ),
                      // _buildImagePicker(
                      //   'صورة التأمين',
                      //   'insurance',
                      //   _insuranceImage,
                      //   subtitle: 'صورة بوليصة التأمين الساري المفعول',
                      // ),
                      if (!_isVehicleOwned) ...[
                        _buildImagePicker(
                          'صورة المكاتبة',
                          'ownershipDocument',
                          _ownershipDocumentImage,
                          subtitle:
                              'مكاتبة من مالك السيارة تسمح لك بالعمل عليها',
                        ),
                      ],
                      const SizedBox(height: 24),
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
                          prefixIcon: Icon(Icons.emergency),
                          hintText: 'رقم هاتف للتواصل في الحالات الطارئة',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _saveProfile,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'حفظ البيانات',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.green.shade700),
                                const SizedBox(width: 8),
                                const Text(
                                  'ملاحظة مهمة:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• يجب إكمال جميع البيانات المطلوبة\n'
                              '• سيتم مراجعة ملفك من قبل الإدارة خلال 24-48 ساعة\n'
                              '• لن تتمكن من استقبال الطلبات حتى تتم الموافقة\n'
                              '• يمكنك تحديث البيانات في أي وقت\n'
                              '• جميع الصور يجب أن تكون واضحة وحديثة\n'
                              '• المستندات يجب أن تكون صالحة وغير منتهية الصلاحية',
                              style: TextStyle(color: Colors.green),
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
