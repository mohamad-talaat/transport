// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:transport_app/controllers/auth_controller.dart';
// import 'package:transport_app/controllers/driver_controller.dart';
// import 'package:transport_app/services/driver_profile_service.dart';
// import 'package:transport_app/routes/app_routes.dart';

// class DriverHomeView extends StatefulWidget {
//   const DriverHomeView({super.key});

//   @override
//   State<DriverHomeView> createState() => _DriverHomeViewState();
// }

// class _DriverHomeViewState extends State<DriverHomeView> {
//   final AuthController authController = Get.find<AuthController>();
//   final DriverController driverController = Get.find<DriverController>();
//   final DriverProfileService profileService = Get.find<DriverProfileService>();

//   @override
//   void initState() {
//     super.initState();
//     _checkProfileCompletion();
//   }

//   /// التحقق من اكتمال بروفايل السائق
//   Future<void> _checkProfileCompletion() async {
//     try {
//       final userId = authController.currentUser.value?.id;
//       if (userId == null) return;

//       final isComplete = await profileService.isProfileComplete(userId);

//       if (!isComplete) {
//         // إذا لم يكمل البروفايل، توجيه لشاشة الإكمال
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Get.offAllNamed(AppRoutes.DRIVER_PROFILE_COMPLETION);
//         });
//       }
//     } catch (e) {
//       logger.w('خطأ في التحقق من اكتمال البروفايل: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text('الصفحة الرئيسية'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications),
//             onPressed: () {
//               // TODO: فتح الإشعارات
//             },
//           ),
//         ],
//       ),
//       drawer: _buildDrawer(),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildWelcomeSection(),
//             const SizedBox(height: 20),
//             _buildStatusSection(),
//             const SizedBox(height: 20),
//             _buildQuickActions(),
//             const SizedBox(height: 20),
//             _buildRecentTrips(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildWelcomeSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.blue.shade400, Colors.blue.shade600],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 30,
//             backgroundImage: authController.currentUser.value?.profileImage !=
//                     null
//                 ? NetworkImage(authController.currentUser.value!.profileImage!)
//                 : null,
//             child: authController.currentUser.value?.profileImage == null
//                 ? const Icon(Icons.person, size: 30, color: Colors.white)
//                 : null,
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'مرحباً ${authController.currentUser.value?.name ?? 'السائق'}',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'جاهز لاستقبال الطلبات',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.9),
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'حالة العمل',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildStatusCard(
//                   title: 'متصل',
//                   value: 'نعم',
//                   icon: Icons.wifi,
//                   color: Colors.green,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildStatusCard(
//                   title: 'متاح',
//                   value: 'نعم',
//                   icon: Icons.check_circle,
//                   color: Colors.blue,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusCard({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: color, size: 24),
//           const SizedBox(height: 8),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickActions() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'إجراءات سريعة',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           GridView.count(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             crossAxisCount: 2,
//             crossAxisSpacing: 12,
//             mainAxisSpacing: 12,
//             children: [
//               _buildActionCard(
//                 title: 'الملف الشخصي',
//                 icon: Icons.person,
//                 color: Colors.blue,
//                 onTap: () => Get.toNamed(AppRoutes.DRIVER_PROFILE),
//               ),
//               _buildActionCard(
//                 title: 'المحفظة',
//                 icon: Icons.account_balance_wallet,
//                 color: Colors.green,
//                 onTap: () => Get.toNamed(AppRoutes.DRIVER_WALLET),
//               ),
//               _buildActionCard(
//                 title: 'تاريخ الرحلات',
//                 icon: Icons.history,
//                 color: Colors.orange,
//                 onTap: () => Get.toNamed(AppRoutes.DRIVER_TRIP_HISTORY),
//               ),
//               _buildActionCard(
//                 title: 'الإعدادات',
//                 icon: Icons.settings,
//                 color: Colors.purple,
//                 onTap: () {
//                   // TODO: فتح الإعدادات
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionCard({
//     required String title,
//     required IconData icon,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: color.withOpacity(0.3)),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: color, size: 32),
//             const SizedBox(height: 8),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: color,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentTrips() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'الرحلات الأخيرة',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               TextButton(
//                 onPressed: () => Get.toNamed(AppRoutes.DRIVER_TRIP_HISTORY),
//                 child: const Text('عرض الكل'),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           // TODO: عرض الرحلات الأخيرة
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.grey[50],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Center(
//               child: Text(
//                 'لا توجد رحلات حديثة',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }Widget _buildDrawer() {
//   return ClipRRect(
//     borderRadius: const BorderRadius.only(
//       topRight: Radius.circular(20),
//       bottomRight: Radius.circular(20),
//     ),
//     child: Drawer(
//       elevation: 6,
//       child: Column(
//         children: [
//           DrawerHeader(
//             margin: EdgeInsets.zero,
//             padding: EdgeInsets.zero,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.blue.shade600, Colors.blue.shade900],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.25),
//                   blurRadius: 8,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   CircleAvatar(
//                     radius: 36,
//                     backgroundImage:
//                         authController.currentUser.value?.profileImage != null
//                             ? NetworkImage(
//                                 authController.currentUser.value!.profileImage!)
//                             : null,
//                     child: authController.currentUser.value?.profileImage == null
//                         ? const Icon(Icons.person,
//                             size: 42, color: Colors.white)
//                         : null,
//                   ),
//                   const SizedBox(width: 18),
//                   Expanded(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           authController.currentUser.value?.name ?? 'السائق',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 6),
//                         Text(
//                           authController.currentUser.value?.email ?? '',
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.9),
//                             fontSize: 14,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           /// قائمة العناصر
//           Expanded(
//             child: ListView(
//               padding: EdgeInsets.zero,
//               children: [
//                 _buildDrawerItem(Icons.person, 'الملف الشخصي',
//                     AppRoutes.DRIVER_PROFILE),
//                 _buildDrawerItem(Icons.account_balance_wallet, 'المحفظة',
//                     AppRoutes.DRIVER_WALLET),
//                 _buildDrawerItem(
//                     Icons.history, 'تاريخ الرحلات', AppRoutes.DRIVER_TRIP_HISTORY),
//                 const Divider(height: 24, thickness: 0.6),

//                 _buildDrawerItem(Icons.settings, 'الإعدادات', null, todo: true),
//                 _buildDrawerItem(Icons.help_outline, 'المساعدة', null, todo: true),
//                 const Divider(height: 24, thickness: 0.6),

//                 ListTile(
//                   leading: const Icon(Icons.logout, color: Colors.red),
//                   title: const Text(
//                     'تسجيل الخروج',
//                     style: TextStyle(
//                       color: Colors.red,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   trailing: const Icon(Icons.arrow_forward_ios,
//                       size: 16, color: Colors.red),
//                   onTap: () {
//                     Get.back();
//                     _showLogoutDialog();
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// Widget _buildDrawerItem(IconData icon, String title, String? route,
//     {bool todo = false}) {
//   return ListTile(
//     leading: Icon(icon, color: Colors.blue.shade700, size: 26),
//     title: Text(
//       title,
//       style: const TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.w500,
//       ),
//     ),
//     trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
//     onTap: () {
//       Get.back();
//       if (route != null) {
//         Get.toNamed(route);
//       } else if (todo) {
//         // TODO: أضف الوظيفة لاحقاً
//       }
//     },
//   );
// }

//   void _showLogoutDialog() {
//     Get.dialog(
//       AlertDialog(
//         title: const Text('تسجيل الخروج'),
//         content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('إلغاء'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Get.back();
//               authController.signOut();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('تسجيل الخروج'),
//           ),
//         ],
//       ),
//     );
//   }
// }
