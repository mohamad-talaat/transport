import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/models/user_model.dart';

class UserTypeSelectionView extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());

  UserTypeSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo والعنوان
              _buildHeader(),

              const Spacer(),

              // خيارات المستخدم
              _buildUserOptions(),

              const Spacer(),

              // روابط التسجيل
              _buildSignUpLinks(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // أيقونة التاكسي
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.amber.shade400,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_taxi,
            size: 50,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 24),

        // العنوان
        const Text(
          'تكسي البصرة',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'مرحباً بك',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          'سجل الدخول للاستمتاع بخدماتنا',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildUserOptions() {
    return Column(
      children: [
        // تسجيل الدخول بـ Google
        _buildGoogleSignInButton(),

        const SizedBox(height: 16),

        // تسجيل الدخول بـ Apple
        _buildAppleSignInButton(),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: () {
          _showUserTypeDialog('google');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة Google
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'تسجيل الدخول باستخدام Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleSignInButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: () {
          _showUserTypeDialog('apple');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة Apple
            Icon(
              Icons.apple,
              size: 20,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Text(
              'تسجيل الدخول باستخدام Apple',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpLinks() {
    return Column(
      children: [
        // تسجيل الدخول بالهاتف (قريباً)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'تسجيل الدخول بالهاتف',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
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
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // تسجيل حساب جديد
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     const Text(
        //       'ليس لديك حساب؟ ',
        //       style: TextStyle(
        //         fontSize: 14,
        //         color: Colors.grey,
        //       ),
        //     ),
        //     GestureDetector(
        //       onTap: () {
        //         _showUserTypeDialog('signup');
        //       },
        //       child: Container(
        //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        //         decoration: BoxDecoration(
        //           border: Border.all(color: Colors.blue),
        //           borderRadius: BorderRadius.circular(6),
        //         ),
        //         child: const Text(
        //           'إنشاء حساب جديد',
        //           style: TextStyle(
        //             fontSize: 14,
        //             color: Colors.blue,
        //             fontWeight: FontWeight.w600,
        //           ),
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }

  void _showUserTypeDialog(String loginType) {
    Get.dialog(
      AlertDialog(
        title: const Text(
          'اختر نوع الحساب',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
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
              Icons.drive_eta,
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
      onTap: () {
        Get.back();
        authController.selectUserTypeForSocialLogin(userType);

        // تنفيذ نوع تسجيل الدخول المحدد
        switch (loginType) {
          case 'google':
            authController.signInWithGoogle();
            break;
            // case 'apple':
            //   authController.signInWithApple();
            break;
          case 'signup':
            // TODO: يمكن إضافة صفحة التسجيل لاحقاً
            Get.snackbar(
              'قريباً',
              'إنشاء الحساب بطرق أخرى سيكون متاحاً قريباً',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
            break;
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
