// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../services/user_management_service.dart';

// class RiderDrawerView extends StatelessWidget {
//   const RiderDrawerView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Colors.blue.shade600,
//               Colors.blue.shade800,
//             ],
//           ),
//         ),
//         child: Column(
//           children: [
//             _buildHeader(),
//             Expanded(
//               child: Container(
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(20),
//                     topRight: Radius.circular(20),
//                   ),
//                 ),
//                 child: _buildMenuItems(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
//       child: Obx(() {
//         final userService = Get.find<UserManagementService>();
//         final rider = userService.currentRider.value;

//         return Column(
//           children: [
//             // صورة المستخدم
//             Container(
//               width: 80,
//               height: 80,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(color: Colors.white, width: 3),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.2),
//                     blurRadius: 10,
//                     offset: const Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: ClipOval(
//                 child: rider?.profileImage != null
//                     ? Image.network(
//                         rider!.profileImage!,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Container(
//                             color: Colors.grey.shade300,
//                             child: const Icon(
//                               Icons.person,
//                               size: 40,
//                               color: Colors.grey,
//                             ),
//                           );
//                         },
//                       )
//                     : Container(
//                         color: Colors.grey.shade300,
//                         child: const Icon(
//                           Icons.person,
//                           size: 40,
//                           color: Colors.grey,
//                         ),
//                       ),
//               ),
//             ),
//             const SizedBox(height: 16),

//             // اسم المستخدم
//             Text(
//               rider?.name ?? 'مستخدم',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),

//             const SizedBox(height: 8),

//             // البريد الإلكتروني
//             Text(
//               rider?.email ?? 'user@example.com',
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.9),
//                 fontSize: 14,
//               ),
//               textAlign: TextAlign.center,
//             ),

//             const SizedBox(height: 16),

//             // معلومات إضافية
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(
//                     Icons.star,
//                     color: Colors.amber,
//                     size: 16,
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     '${rider?.totalTrips ?? 0} رحلة',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         );
//       }),
//     );
//   }

//   Widget _buildMenuItems() {
//     return ListView(
//       padding: const EdgeInsets.symmetric(vertical: 20),
//       children: [
//         _buildMenuItem(
//           icon: Icons.home,
//           title: 'الرئيسية',
//           onTap: () {
//             Get.back();
//             // Get.offAllNamed('/rider-home');
//           },
//         ),
//         _buildMenuItem(
//           icon: Icons.history,
//           title: 'سجل الرحلات',
//           onTap: () {
//             Get.back();
//             // Get.toNamed('/rider-trips-history');
//           },
//         ),
//         _buildMenuItem(
//           icon: Icons.favorite,
//           title: 'المواقع المفضلة',
//           onTap: () {
//             Get.back();
//             // Get.toNamed('/favorite-locations');
//           },
//         ),
//         _buildMenuItem(
//           icon: Icons.payment,
//           title: 'المدفوعات',
//           onTap: () {
//             Get.back();
//             // Get.toNamed('/rider-payments');
//           },
//         ),
//         _buildMenuItem(
//           icon: Icons.local_offer,
//           title: 'أكواد الخصم',
//           onTap: () {
//             Get.back();
//             // Get.toNamed('/discount-codes');
//           },
//         ),
//         const Divider(height: 32, thickness: 1),
//         _buildMenuItem(
//           icon: Icons.person,
//           title: 'الملف الشخصي',
//           onTap: () {
//             Get.back();
//             // Get.toNamed('/rider-profile');
//           },
//         ),
//         _buildMenuItem(
//           icon: Icons.settings,
//           title: 'الإعدادات',
//           onTap: () {
//             Get.back();
//             // Get.toNamed('/settings');
//           },
//         ),
//         _buildMenuItem(
//           icon: Icons.help,
//           title: 'المساعدة والدعم',
//           onTap: () {
//             Get.back();
//             // Get.toNamed('/help-support');
//           },
//         ),
//         _buildMenuItem(
//           icon: Icons.info,
//           title: 'حول التطبيق',
//           onTap: () {
//             Get.back();
//             // Get.toNamed('/about');
//           },
//         ),
//         const Divider(height: 32, thickness: 1),
//         _buildMenuItem(
//           icon: Icons.logout,
//           title: 'تسجيل الخروج',
//           onTap: () {
//             _showLogoutDialog();
//           },
//           isDestructive: true,
//         ),
//       ],
//     );
//   }

//   Widget _buildMenuItem({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//     bool isDestructive = false,
//   }) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         color: isDestructive ? Colors.red.shade50 : Colors.transparent,
//       ),
//       child: ListTile(
//         leading: Container(
//           width: 40,
//           height: 40,
//           decoration: BoxDecoration(
//             color: isDestructive ? Colors.red.shade100 : Colors.blue.shade50,
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Icon(
//             icon,
//             color: isDestructive ? Colors.red : Colors.blue,
//             size: 20,
//           ),
//         ),
//         title: Text(
//           title,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: isDestructive ? Colors.red : Colors.black87,
//           ),
//         ),
//         trailing: Icon(
//           Icons.arrow_forward_ios,
//           size: 16,
//           color: isDestructive ? Colors.red : Colors.grey,
//         ),
//         onTap: onTap,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//     );
//   }

//   void _showLogoutDialog() {
//     Get.dialog(
//       AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade100,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Icon(
//                 Icons.logout,
//                 color: Colors.red,
//                 size: 24,
//               ),
//             ),
//             const SizedBox(width: 12),
//             const Text('تسجيل الخروج'),
//           ],
//         ),
//         content: const Text(
//           'هل أنت متأكد من تسجيل الخروج؟',
//           style: TextStyle(fontSize: 16),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text(
//               'إلغاء',
//               style: TextStyle(color: Colors.grey),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Get.back();
//               _logout();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: const Text('تسجيل الخروج'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _logout() {
//     // هنا يمكن إضافة منطق تسجيل الخروج
//     // مثلاً: مسح البيانات المحلية، إعادة التوجيه لصفحة تسجيل الدخول
//     Get.snackbar(
//       'تم تسجيل الخروج',
//       'تم تسجيل الخروج بنجاح',
//       backgroundColor: Colors.green,
//       colorText: Colors.white,
//       duration: const Duration(seconds: 2),
//     );

//     // إعادة التوجيه لصفحة تسجيل الدخول
//     // Get.offAllNamed('/login');
//   }
// }
