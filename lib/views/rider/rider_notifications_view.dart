// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:transport_app/services/notification/notification_service.dart';
// import 'package:transport_app/services/notification/unified_notification_service.dart';

// class RiderNotificationsView extends StatelessWidget {
//   const RiderNotificationsView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final notificationService = NotificationService.to;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('الإشعارات'),
//         centerTitle: true,
//         actions: [
//           // Obx(() => Switch(
//           //       value: notificationService.notificationsEnabled.value,
//           //       onChanged: (value) {
//           //         notificationService.toggleNotifications(value);
//           //       },
//           //     )),
//         ],
//       ),
//       body: Obx(() {
//         final items = notificationService.notifications;
//         if (!notificationService.notificationsEnabled.value) {
//           return const Center(
//             child: Text('الإشعارات متوقفة 🔕'),
//           );
//         }

//         if (items.isEmpty) {
//           return const Center(child: Text('لا توجد إشعارات'));
//         }

//         return ListView.separated(
//           itemCount: items.length,
//           separatorBuilder: (_, __) => const Divider(height: 0),
//           itemBuilder: (context, index) {
//             final n = items[index];
//             return ListTile(
//               title: Text(n.title),
//               subtitle: Text(n.body),
//               trailing: n.isRead
//                   ? null
//                   : const Icon(Icons.fiber_new, color: Colors.red, size: 16),
//               onTap: () => notificationService.markRead(n.id),
//             );
//           },
//         );
//       }),
//     );
//   }
// }
