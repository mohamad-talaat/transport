import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/models/driver_profile_model.dart';
import 'package:transport_app/services/driver_profile_service.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/image_upload_service.dart';
import 'package:transport_app/routes/app_routes.dart';

class DriverProfileCompletionView extends StatefulWidget {
  const DriverProfileCompletionView({super.key});

  @override
  State<DriverProfileCompletionView> createState() =>
      _DriverProfileCompletionViewState();
}

class _DriverProfileCompletionViewState
    extends State<DriverProfileCompletionView> {
  final AuthController authController = Get.find<AuthController>();
  final DriverProfileService profileService = Get.find<DriverProfileService>();

  final RxBool isLoading = false.obs;
  final RxDouble completionPercentage = 0.0.obs;
  final RxList<String> missingFields = <String>[].obs;

  @override
  void initState() {
    super.initState();
    _loadProfileStatus();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadProfileStatus() async {
    try {
      isLoading.value = true;

      final userId = authController.currentUser.value?.id;
      if (userId == null) return;

      // حساب نسبة اكتمال البروفايل
      final percentage =
          await profileService.getProfileCompletionPercentage(userId);
      completionPercentage.value = percentage;

      // الحصول على الحقول الناقصة
      final missing = await profileService.getMissingFields(userId);
      missingFields.value = missing;
    } catch (e) {
      print('خطأ في تحميل حالة البروفايل: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              authController.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('إكمال البروفايل'),
        actions: [
          Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: _showLogoutDialog,
        icon: Icon(Icons.logout, color: Colors.white, size: 24),
        padding: const EdgeInsets.all(12),
      ),
    )
        ],
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // منع الرجوع
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildProgressSection(),
              const SizedBox(height: 30),
              _buildMissingFieldsSection(),
              const SizedBox(height: 30),
              _buildActionButtons(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_add,
            size: 60,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(height: 16),
          const Text(
            'مرحباً بك في تكسي البصرة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'لبدء العمل كسائق، يجب إكمال بياناتك الشخصية',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              const Text(
                'نسبة اكتمال البروفايل',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: completionPercentage.value / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              completionPercentage.value >= 100 ? Colors.green : Colors.blue,
            ),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Text(
            '${completionPercentage.value.toInt()}% مكتمل',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: completionPercentage.value >= 100
                  ? Colors.green
                  : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingFieldsSection() {
    if (missingFields.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 12),
                const Text(
                  'مبروك! تم إكمال جميع البيانات المطلوبة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تم إرسال طلبك للإدارة للمراجعة والموافقة. سيتم إشعارك عند الانتهاء من المراجعة.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade600),
              const SizedBox(width: 12),
              const Text(
                'البيانات المطلوبة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...missingFields
              .map((field) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.red.shade400),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            field,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _navigateToProfileEdit(),
            icon: const Icon(Icons.edit),
            label: const Text(
              'إكمال البيانات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (completionPercentage.value >= 100)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _checkAndNavigateToHome(),
              icon: const Icon(Icons.check_circle),
              label: const Text(
                'بدء العمل',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: () => _showHelpDialog(),
            icon: const Icon(Icons.help_outline),
            label: const Text('مساعدة'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToProfileEdit() {
    Get.toNamed(AppRoutes.DRIVER_PROFILE_EDIT);
  }

  Future<void> _checkAndNavigateToHome() async {
    try {
      final userId = authController.currentUser.value?.id;
      if (userId == null) return;

      final isComplete = await profileService.isProfileComplete(userId);
      if (isComplete) {
        Get.offAllNamed(AppRoutes.DRIVER_HOME);
      } else {
        Get.snackbar(
          'خطأ',
          'يرجى إكمال جميع البيانات المطلوبة أولاً',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        await _loadProfileStatus(); // إعادة تحميل الحالة
      }
    } catch (e) {
      print('خطأ في التحقق من اكتمال البروفايل: $e');
    }
  }

  void _showHelpDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('مساعدة'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لبدء العمل كسائق، تحتاج إلى:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• إكمال البيانات الشخصية'),
            Text('• رفع صورة الهوية'),
            Text('• رفع صورة الرخصة'),
            Text('• رفع صورة السيارة'),
            Text('• تحديد منطقة العمل'),
            Text('• إضافة الحساب البنكي'),
            SizedBox(height: 12),
            Text(
              'سيتم مراجعة بياناتك من قبل الإدارة خلال 24 ساعة',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }
}
