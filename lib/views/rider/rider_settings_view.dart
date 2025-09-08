import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/services/notification_service.dart';
import 'package:transport_app/routes/app_routes.dart';

class RiderSettingsView extends StatelessWidget {
  const RiderSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService.to;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('الإشعارات',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Obx(() => SwitchListTile(
                title: const Text('تفعيل الإشعارات'),
                value: notificationService.notificationsEnabled.value,
                onChanged: (v) =>
                    notificationService.updateNotificationSettings(enabled: v),
              )),
          Obx(() => SwitchListTile(
                title: const Text('الصوت'),
                value: notificationService.soundEnabled.value,
                onChanged: (v) =>
                    notificationService.updateNotificationSettings(sound: v),
              )),
          Obx(() => SwitchListTile(
                title: const Text('الاهتزاز'),
                value: notificationService.vibrationEnabled.value,
                onChanged: (v) => notificationService
                    .updateNotificationSettings(vibration: v),
              )),
          const SizedBox(height: 24),
          // const Text('رفع الصور',
          //     style: TextStyle(fontWeight: FontWeight.bold)),
          // const SizedBox(height: 8),
          // ListTile(
          //   leading: const Icon(Icons.cloud_upload),
          //   title: const Text('إعدادات رفع الصور'),
          //   subtitle: const Text('اختر طريقة رفع الصور المفضلة'),
          //   trailing: const Icon(Icons.arrow_forward_ios),
          //   onTap: () => Get.toNamed(AppRoutes.IMAGE_UPLOAD_SETTINGS),
          // ),
        ],
      ),
    );
  }
}
