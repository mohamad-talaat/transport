import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverProfileView extends StatelessWidget {
  DriverProfileView({super.key});

  final AuthController authController = AuthController.to;
  final DriverController driverController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildPersonalInfo(),
              const SizedBox(height: 20),
              _buildVehicleInfo(),
              const SizedBox(height: 20),
              _buildStatistics(),
              const SizedBox(height: 20),
              _buildActions(),
              const SizedBox(height: 20),
              _buildDebugSection(), // إضافة قسم للتصحيح
            ],
          ),
        ),
      ),
    );
  }

  // إضافة قسم للتصحيح وحل مشكلة cache
  Widget _buildDebugSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'إعدادات التطبيق',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _clearAppCache(),
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('مسح Cache'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _resetUserData(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('إعادة تعيين'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // مسح cache التطبيق
  Future<void> _clearAppCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // مسح البيانات المحفوظة
      await prefs.clear();

      Get.snackbar(
        'تم المسح',
        'تم مسح cache التطبيق بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // إعادة تحميل البيانات
      await authController
          .loadUserData(authController.currentUser.value?.id ?? '');
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء مسح cache: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // إعادة تعيين بيانات المستخدم
  Future<void> _resetUserData() async {
    try {
      Get.dialog(
        AlertDialog(
          title: const Text('تأكيد إعادة التعيين'),
          content: const Text('هل أنت متأكد من إعادة تعيين جميع البيانات؟'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                Get.back();
                await _performReset();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('إعادة تعيين'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('خطأ في إعادة التعيين: $e');
    }
  }

  Future<void> _performReset() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // مسح جميع البيانات المحفوظة
      await prefs.clear();

      // إعادة تحميل بيانات المستخدم من Firebase
      if (authController.currentUser.value?.id != null) {
        await authController
            .loadUserData(authController.currentUser.value!.id!);
      }

      Get.snackbar(
        'تم إعادة التعيين',
        'تم إعادة تعيين جميع البيانات بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // إعادة تحميل الصفحة
      Get.forceAppUpdate();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء إعادة التعيين: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue, Colors.blueAccent],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Expanded(
                child: Text(
                  'الملف الشخصي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () => _showEditProfile(),
                icon: const Icon(Icons.edit, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Obx(() => Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      image:
                          authController.currentUser.value?.profileImage != null
                              ? DecorationImage(
                                  image: NetworkImage(authController
                                      .currentUser.value!.profileImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child:
                        authController.currentUser.value?.profileImage == null
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.white)
                            : null,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    authController.currentUser.value?.name ?? 'السائق',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Obx(() {
                    final user = authController.currentUser.value;
                    String statusText = 'سائق نشط';
                    Color statusColor = Colors.white.withOpacity(0.8);

                    if (user?.isApproved == true) {
                      statusText = 'سائق موافق عليه';
                      statusColor = Colors.green.shade200;
                    } else if (user?.isRejected == true) {
                      statusText = 'تم رفض الطلب';
                      statusColor = Colors.red.shade200;
                    } else {
                      statusText = 'في انتظار الموافقة';
                      statusColor = Colors.orange.shade200;
                    }

                    return Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 16,
                      ),
                    );
                  }),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'المعلومات الشخصية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Obx(() => Column(
                children: [
                  _buildInfoItem(
                    'الاسم',
                    authController.currentUser.value?.name ?? '',
                    Icons.person,
                  ),
                  _buildInfoItem(
                    'البريد الإلكتروني',
                    authController.currentUser.value?.email ?? '',
                    Icons.email,
                  ),
                  _buildInfoItem(
                    'رقم الهاتف',
                    authController.currentUser.value?.phone ?? '',
                    Icons.phone,
                  ),
                  _buildInfoItem(
                    'تاريخ التسجيل',
                    _formatDate(authController.currentUser.value?.createdAt ??
                        DateTime.now()),
                    Icons.date_range,
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildVehicleInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'معلومات المركبة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showEditVehicle(),
                child: const Text('تعديل'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() {
            final user = authController.currentUser.value;
            final additionalData = user?.additionalData ?? {};

            return Column(
              children: [
                _buildInfoItem(
                  'نوع السيارة',
                  additionalData['carType'] ?? 'غير محدد',
                  Icons.directions_car,
                ),
                _buildInfoItem(
                  'موديل السيارة',
                  additionalData['carModel'] ?? 'غير محدد',
                  Icons.model_training,
                ),
                _buildInfoItem(
                  'لون السيارة',
                  additionalData['carColor'] ?? 'غير محدد',
                  Icons.color_lens,
                ),
                _buildInfoItem(
                  'سنة الصنع',
                  additionalData['carYear'] ?? 'غير محدد',
                  Icons.calendar_today,
                ),
                _buildInfoItem(
                  'رقم اللوحة',
                  additionalData['carNumber'] ?? 'غير محدد',
                  Icons.confirmation_number,
                ),
                _buildInfoItem(
                  'رقم الرخصة',
                  additionalData['licenseNumber'] ?? 'غير محدد',
                  Icons.credit_card,
                ),
                _buildInfoItem(
                  'مناطق العمل',
                  (additionalData['workingAreas'] as List<dynamic>?)
                          ?.join(', ') ??
                      'غير محدد',
                  Icons.location_on,
                ),
              ],
            );
          }),
          const SizedBox(height: 15),
          // صورة السيارة
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              image: authController
                          .currentUser.value?.additionalData?['carImage'] !=
                      null
                  ? DecorationImage(
                      image: NetworkImage(authController
                          .currentUser.value!.additionalData!['carImage']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child:
                authController.currentUser.value?.additionalData?['carImage'] ==
                        null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car,
                                size: 50, color: Colors.grey),
                            SizedBox(height: 10),
                            Text(
                              'لا توجد صورة للمركبة',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : null,
          ),
          const SizedBox(height: 15),
          // قسم الوثائق
          const Text(
            'الوثائق المرفوعة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Obx(() {
            final additionalData =
                authController.currentUser.value?.additionalData ?? {};
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDocumentItem(
                        'رخصة القيادة',
                        additionalData['licenseImage'],
                        Icons.card_membership,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDocumentItem(
                        'الهوية الشخصية',
                        additionalData['idCardImage'],
                        Icons.badge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildDocumentItem(
                        'تسجيل السيارة',
                        additionalData['vehicleRegistrationImage'],
                        Icons.description,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDocumentItem(
                        'التأمين',
                        additionalData['insuranceImage'],
                        Icons.security,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(String title, String? imageUrl, IconData icon) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: imageUrl != null ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: imageUrl != null ? Colors.green : Colors.grey.shade300,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: imageUrl != null ? Colors.green : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: imageUrl != null
                  ? Colors.green.shade700
                  : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            imageUrl != null ? 'مرفوع' : 'غير مرفوع',
            style: TextStyle(
              fontSize: 10,
              color: imageUrl != null ? Colors.green : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الإحصائيات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Obx(() {
            final stats = driverController.getDriverStatistics();
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'الرحلات المكتملة',
                        '${stats['completedTrips']}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildStatCard(
                        'الربح اليومي',
                        '${stats['todayEarnings']} جنيه',
                        Icons.attach_money,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'الربح الأسبوعي',
                        '${stats['weekEarnings']} جنيه',
                        Icons.trending_up,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildStatCard(
                        'الربح الشهري',
                        '${stats['monthEarnings']} جنيه',
                        Icons.account_balance_wallet,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الإجراءات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            'تعديل الملف الشخصي',
            Icons.edit,
            Colors.blue,
            () => _showEditProfile(),
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            'تعديل معلومات المركبة',
            Icons.directions_car,
            Colors.green,
            () => _showEditVehicle(),
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            'إعدادات التطبيق',
            Icons.settings,
            Colors.orange,
            () => _showSettings(),
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            'تسجيل الخروج',
            Icons.logout,
            Colors.red,
            () => _logout(),
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            'تحديث البيانات',
            Icons.refresh,
            Colors.blue,
            () => _refreshProfile(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditProfile() {
    Get.toNamed(AppRoutes.DRIVER_PROFILE_EDIT);
  }

  void _showEditVehicle() {
    // TODO: تنفيذ تعديل معلومات المركبة
    Get.snackbar(
      'قريباً',
      'سيتم إضافة هذه الميزة قريباً',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showSettings() {
    // TODO: تنفيذ الإعدادات
    Get.snackbar(
      'قريباً',
      'سيتم إضافة هذه الميزة قريباً',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _logout() {
    Get.dialog(
      AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              authController.signOut();
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _refreshProfile() async {
    try {
      Get.dialog(
        const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('جاري تحديث البيانات...'),
            ],
          ),
        ),
      );

      // تحديث بيانات المستخدم من Firebase
      if (authController.currentUser.value?.id != null) {
        await authController.loadUserData(authController.currentUser.value!.id!);
      }

      // تحديث إحصائيات السائق
      await driverController.loadEarningsData();

      Get.back(); // إغلاق dialog التحميل

      Get.snackbar(
        'تم التحديث',
        'تم تحديث البيانات بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // إغلاق dialog التحميل
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تحديث البيانات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
