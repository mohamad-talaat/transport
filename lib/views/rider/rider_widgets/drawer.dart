import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/routes/app_routes.dart';
class _DrawerHeader extends StatelessWidget {
  final AuthController authController;

  const _DrawerHeader({required this.authController});

  @override
  Widget build(BuildContext context) {
    final user = authController.currentUser.value;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
           CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        authController.currentUser.value?.profileImage != null
                            ? NetworkImage(
                                authController.currentUser.value!.profileImage!)
                            : null,
                    child:
                        authController.currentUser.value?.profileImage == null
                            ? const Icon(Icons.person,
                                size: 30, color: Colors.white)
                            : null,
                  ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? 'مستخدم',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user?.phone ?? '',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RiderDrawer extends StatelessWidget {
  final AuthController authController;
  const RiderDrawer({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(authController: authController),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: 'الملف الشخصي',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.RIDER_PROFILE);
                    },
                  ),
                     _buildDrawerItem(
                    icon: Icons.history,
                    title: 'تاريخ الرحلات',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.RIDER_TRIP_HISTORY);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'المحفظة',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.RIDER_WALLET);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications_outlined,
                    title: 'الإشعارات',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.RIDER_NOTIFICATIONS);
                    },
                  ),
                  const Divider(height: 32),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'الإعدادات',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.RIDER_SETTINGS);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'المساعدة والدعم',
                    onTap: () {
                      Get.back();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline,
                    title: 'عن التطبيق',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.RIDER_ABOUT);
                    },
                  ),
                ],
              ),
            ),
           
            _LogoutTile(authController: authController),
          ],
        ),
      ),
    );
  }
  
}
class _LogoutTile extends StatelessWidget {
  final AuthController authController;

  const _LogoutTile({required this.authController});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text(
        'تسجيل الخروج',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: Colors.red,
        ),
      ),
      onTap: () {
        Get.back();
        authController.signOut();
      },
    );
  }
}


class _buildDrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _buildDrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
