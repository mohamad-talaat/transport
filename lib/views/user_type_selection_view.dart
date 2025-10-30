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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber,
              Colors.orange,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildHeader(),
                const Spacer(),
                _buildUserOptions(),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: Image.asset(
            height: 200,
            width: 200,
            "assets/images/t.png",
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_taxi, size: 40, color: Colors.amber),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'تكسي البصرة',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'مرحبا بك 👋\nاختر وسيلة الدخول للبدء',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
    );
  }

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
        const SizedBox(height: 16),
        _buildSocialButton(
            label: 'تسجيل الدخول باستخدام الهاتق ',
            color: Colors.teal.shade800,
            textColor: Colors.white,
            icon: Icons.phone_android_outlined,
            iconColor: Colors.white,
            onTap: () => Get.snackbar(
                  'قريباً',
                  'تسجيل الدخول بالهاتف سيكون متاح لاحقاً',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                )),
      ],
    );
  }

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
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(strokeWidth: 2)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Widget _buildOtherOptions() {
  //   return Column(
  //     children: [
  //       InkWell(
  //         onTap: () {
  //           Get.snackbar(
  //             'قريباً',
  //             'تسجيل الدخول بالهاتف سيكون متاح لاحقاً',
  //             snackPosition: SnackPosition.TOP,
  //             backgroundColor: Colors.orange,
  //             colorText: Colors.white,
  //           );
  //         },
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(Icons.phone, size: 20, color: Colors.grey.shade700),
  //             const SizedBox(width: 8),
  //             Text(
  //               'تسجيل الدخول بالهاتف',
  //               style: TextStyle(
  //                 fontSize: 15,
  //                 color: Colors.grey.shade700,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //             const SizedBox(width: 6),
  //             Container(
  //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  //               decoration: BoxDecoration(
  //                 color: Colors.orange.shade100,
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Text(
  //                 'قريباً',
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   color: Colors.orange.shade800,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  void _showUserTypeDialog(String loginType) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade200,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر نوع الحساب',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 20),
              _buildUserTypeOption(
                index: 0,
                title: 'راكب',
                subtitle: 'للحجز والاستمتاع بالرحلات',
                icon: Icons.person,
                background: Colors.teal.shade400,
                loginType: loginType,
                userType: UserType.rider,
              ),
              const SizedBox(height: 16),
              _buildUserTypeOption(
                index: 1,
                title: 'سائق',
                subtitle: 'للعمل وكسب المال',
                icon: Icons.directions_car,
                background: Colors.indigo.shade500,
                loginType: loginType,
                userType: UserType.driver,
              ),
              const SizedBox(height: 20),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Get.back(closeOverlays: false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeOption({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color background,
    required UserType userType,
    required String loginType,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero),
      duration: Duration(milliseconds: 500 + (index * 200)),
      curve: Curves.easeOut,
      builder: (context, Offset offset, child) {
        return Transform.translate(
          offset: Offset(0, offset.dy * 30),
          child: Opacity(
            opacity: 1 - offset.dy,
            child: child,
          ),
        );
      },
      child: GestureDetector(
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
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
              break;
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: background.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withOpacity(0.15),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
