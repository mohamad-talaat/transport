import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/routes/app_routes.dart';

class DriverDrawer extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();
  final DriverController driverController = Get.find<DriverController>();

  DriverDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Drawer(
        elevation: 6,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    Icons.person,
                    'الملف الشخصي',
                    AppRoutes.DRIVER_PROFILE,
                  ),
                  _buildDrawerItem(
                    Icons.account_balance_wallet,
                    'المحفظة',
                    AppRoutes.DRIVER_WALLET,
                  ),
                  _buildDrawerItem(
                    Icons.history,
                    'تاريخ الرحلات',
                    AppRoutes.DRIVER_TRIP_HISTORY,
                  ),
                  const Divider(height: 24, thickness: 0.6),
                  _buildDrawerItem(
                    Icons.settings,
                    'الإعدادات',
                    AppRoutes.DRIVER_SETTINGS,
                  ),
                  const Divider(height: 24, thickness: 0.6),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.red),
                    onTap: () {
                      Get.back();
                      _showLogoutDialog();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade600, Colors.deepOrange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 5,
          bottom: 16,
          left: 16,
          right: 16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Obx(() {
              final profileImage = authController.currentUser.value?.profileImage;
              final hasImage = profileImage != null && profileImage.isNotEmpty;
              
              return CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white.withOpacity(0.9),
                backgroundImage: hasImage ? NetworkImage(profileImage) : null,
                onBackgroundImageError: hasImage ? (_, __) {
                  // في حالة فشل تحميل الصورة
                } : null,
                child: !hasImage
                    ? const Icon(Icons.person, size: 42, color: Colors.orange)
                    : null,
              );
            }),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => Text(
                        authController.currentUser.value?.name ?? 'السائق',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )),
                  const SizedBox(height: 6),
                  Obx(() => Text(
                        authController.currentUser.value?.email ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String? route,
      {bool todo = false, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade700, size: 26),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap ??
          () {
            Get.back();
            if (route != null) {
              Get.toNamed(route);
            } else if (todo) {}
          },
    );
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
