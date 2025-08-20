import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/models/user_model.dart';

class UserTypeSelectionView extends StatelessWidget {
  final AuthController authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController(), permanent: true);

  UserTypeSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildHeader(),
              const Spacer(),
              _buildUserOptions(),
              const Spacer(),
              _buildOtherOptions(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// الهيدر (اللوجو + عنوان التطبيق)
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.amber.shade400,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(
            "assets/images/taxi.jpg",
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.error, size: 40, color: Colors.red),

            // ClipOval(
            //   child: Image.asset(
            //     "assets/images/taxi.jpg",
            //     fit: BoxFit.cover,
            //   ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'تكسي البصرة',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'اختر وسيلة الدخول للبدء',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// أزرار تسجيل الدخول
  Widget _buildUserOptions() {
    return Column(
      children: [
        _buildSocialButton(
          label: 'تسجيل الدخول باستخدام Google',
          color: Colors.white,
          textColor: Colors.black87,
          icon: Icons.g_mobiledata,
          iconColor: Colors.red,
          isLoading: authController.isLoading.value,
          onTap: () => _showUserTypeDialog('google'),
        ),
        const SizedBox(height: 16),
        _buildSocialButton(
          label: 'تسجيل الدخول باستخدام Apple',
          color: Colors.black,
          textColor: Colors.white,
          icon: Icons.apple,
          iconColor: Colors.white,
          onTap: () => _showUserTypeDialog('apple'),
        ),
      ],
    );
  }

  /// زر تسجيل اجتماعي (Google, Apple)
  Widget _buildSocialButton({
    required String label,
    required Color color,
    required Color textColor,
    required IconData icon,
    required Color iconColor,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(strokeWidth: 2)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// باقي الاختيارات (Phone login أو تسجيل جديد)
  Widget _buildOtherOptions() {
    return Column(
      children: [
        InkWell(
          onTap: () {
            Get.snackbar(
              'قريباً',
              'تسجيل الدخول بالهاتف سيكون متاح لاحقاً',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                'تسجيل الدخول بالهاتف',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'قريباً',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            _showUserTypeDialog('signup');
          },
          child: Text(
            'إنشاء حساب جديد',
            style: TextStyle(
              fontSize: 15,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  /// دايلوج اختيار نوع المستخدم
  void _showUserTypeDialog(String loginType) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'اختر نوع الحساب',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption(
              'راكب',
              'للحجز والاستمتاع بالرحلات',
              Icons.person,
              Colors.green,
              UserType.rider,
              loginType,
            ),
            const SizedBox(height: 16),
            _buildDialogOption(
              'سائق',
              'للعمل وكسب المال',
              Icons.directions_car,
              Colors.blue,
              UserType.driver,
              loginType,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    UserType userType,
    String loginType,
  ) {
    return GestureDetector(
      onTap: () async {
        Get.back();
        final bool canProceed =
            await authController.selectUserTypeForSocialLogin(userType);
        if (!canProceed) return;

        switch (loginType) {
          case 'google':
            await authController.signInWithGoogle();
            break;
          case 'signup':
            Get.snackbar(
              'قريباً',
              'إنشاء الحساب سيكون متاح لاحقاً',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
