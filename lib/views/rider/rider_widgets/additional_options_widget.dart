// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:transport_app/controllers/my_map_controller.dart';

// class AdditionalOptionsWidget extends StatelessWidget {
//   const AdditionalOptionsWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final mapController = Get.find<MyMapController>();

//     return Obx(() {
//       return Positioned(
//         top: MediaQuery.of(context).padding.top + 80,
//         right: 16,
//         child: Container(
//           width: 220,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 20,
//                 offset: const Offset(0, 8),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade50,
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(16),
//                     topRight: Radius.circular(16),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.settings,
//                       color: Colors.blue.shade600,
//                       size: 20,
//                     ),
//                     const SizedBox(width: 8),
//                     const Text(
//                       'خيارات إضافية',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                       ),
//                     ),
//                     const Spacer(),
//                     GestureDetector(
//                       child: Icon(
//                         Icons.close,
//                         color: Colors.grey.shade600,
//                         size: 18,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   children: [
//                     _buildOptionTile(
//                       icon: Icons.add_location,
//                       title: 'إضافة محطة وسطية',
//                       subtitle: 'إضافة نقطة توقف',
//                       color: Colors.orange,
//                       onTap: () {
//                         if (mapController.additionalStops.length >=
//                             mapController.maxAdditionalStops.value) {
//                           Get.snackbar(
//                             'تحذير',
//                             'لا يمكن إضافة أكثر من ${mapController.maxAdditionalStops.value} محطات',
//                             snackPosition: SnackPosition.BOTTOM,
//                             backgroundColor: Colors.orange,
//                             colorText: Colors.white,
//                           );
//                         } else if (!mapController.isPickupConfirmed.value ||
//                             !mapController.isDestinationConfirmed.value) {
//                           Get.snackbar(
//                             'تنبيه',
//                             'يجب تحديد نقطة الانطلاق والوصول أولاً',
//                             snackPosition: SnackPosition.BOTTOM,
//                             backgroundColor: Colors.blue,
//                             colorText: Colors.white,
//                           );
//                         } else {
//                           mapController
//                               .startLocationSelection('additional_stop');
//                           Get.snackbar(
//                             'اختر الموقع',
//                             'حرك الخريطة لاختيار المحطة الوسطية',
//                             snackPosition: SnackPosition.TOP,
//                             backgroundColor: Colors.orange,
//                             colorText: Colors.white,
//                           );
//                         }
//                       },
//                     ),
//                     const SizedBox(height: 8),
//                     _buildOptionTile(
//                       icon: Icons.my_location,
//                       title: 'تحديث الموقع الحالي',
//                       subtitle: 'إعادة تحديد موقعك',
//                       color: Colors.blue,
//                       onTap: () {
//                         mapController.refreshCurrentLocation();
//                       },
//                     ),
//                     const SizedBox(height: 8),
//                     if (mapController.additionalStops.isNotEmpty) ...[
//                       _buildInfoTile(
//                         icon: Icons.location_on,
//                         title: 'المحطات الوسطية',
//                         subtitle:
//                             '${mapController.additionalStops.length} محطة',
//                         color: Colors.green,
//                       ),
//                       const SizedBox(height: 8),
//                     ],
//                     if (mapController.isPickupConfirmed.value) ...[
//                       _buildOptionTile(
//                         icon: Icons.trip_origin,
//                         title: 'الانتقال لنقطة الانطلاق',
//                         subtitle: 'عرض موقع الانطلاق',
//                         color: Colors.green,
//                         onTap: () {
//                           if (mapController.currentLocation.value != null) {
//                             mapController.moveToLocation(
//                               mapController.currentLocation.value!,
//                               zoom: 16.0,
//                             );
//                           }
//                         },
//                       ),
//                       const SizedBox(height: 8),
//                     ],
//                     if (mapController.isDestinationConfirmed.value) ...[
//                       _buildOptionTile(
//                         icon: Icons.location_on,
//                         title: 'الانتقال لنقطة الوصول',
//                         subtitle: 'عرض موقع الوصول',
//                         color: Colors.red,
//                         onTap: () {
//                           if (mapController.selectedLocation.value != null) {
//                             mapController.moveToLocation(
//                               mapController.selectedLocation.value!,
//                               zoom: 16.0,
//                             );
//                           }
//                         },
//                       ),
//                       const SizedBox(height: 8),
//                     ],
//                     if (mapController.additionalStops.isNotEmpty) ...[
//                       _buildOptionTile(
//                         icon: Icons.remove_circle_outline,
//                         title: 'حذف المحطات الوسطية',
//                         subtitle: 'حذف جميع المحطات',
//                         color: Colors.orange,
//                         onTap: () {
//                           _showClearStopsDialog(context, mapController);
//                         },
//                       ),
//                       const SizedBox(height: 8),
//                     ],
//                     _buildOptionTile(
//                       icon: Icons.refresh,
//                       title: 'إعادة تعيين الكل',
//                       subtitle: 'البدء من جديد',
//                       color: Colors.red,
//                       onTap: () {
//                         _showResetDialog(context, mapController);
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     });
//   }

//   Widget _buildOptionTile({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: color.withOpacity(0.3)),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 32,
//                 height: 32,
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.2),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   icon,
//                   color: color,
//                   size: 18,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 13,
//                       ),
//                     ),
//                     Text(
//                       subtitle,
//                       style: TextStyle(
//                         color: Colors.grey.shade600,
//                         fontSize: 11,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Icon(
//                 Icons.arrow_forward_ios,
//                 color: Colors.grey.shade400,
//                 size: 14,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoTile({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required Color color,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 32,
//             height: 32,
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.2),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               icon,
//               color: color,
//               size: 18,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 13,
//                   ),
//                 ),
//                 Text(
//                   subtitle,
//                   style: TextStyle(
//                     color: Colors.grey.shade600,
//                     fontSize: 11,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Icon(
//             Icons.info_outline,
//             color: color,
//             size: 16,
//           ),
//         ],
//       ),
//     );
//   }

//   void _showClearStopsDialog(
//       BuildContext context, MyMapController mapController) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(Icons.warning, color: Colors.orange.shade600),
//             const SizedBox(width: 8),
//             const Text('حذف المحطات الوسطية'),
//           ],
//         ),
//         content: Text(
//           'هل تريد حذف جميع المحطات الوسطية (${mapController.additionalStops.length} محطة)؟\nلن يمكن التراجع عن هذا الإجراء.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               'إلغاء',
//               style: TextStyle(color: Colors.grey.shade600),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               mapController.additionalStops.clear();
//               mapController.markers.removeWhere((marker) =>
//                   marker.key.toString().contains('additional_stop_'));

//               Navigator.pop(context);

//               Get.snackbar(
//                 'تم الحذف',
//                 'تم حذف جميع المحطات الوسطية',
//                 snackPosition: SnackPosition.BOTTOM,
//                 backgroundColor: Colors.orange,
//                 colorText: Colors.white,
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.orange,
//             ),
//             child: const Text(
//               'حذف',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showResetDialog(BuildContext context, MyMapController mapController) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(Icons.warning, color: Colors.red.shade600),
//             const SizedBox(width: 8),
//             const Text('إعادة تعيين الخريطة'),
//           ],
//         ),
//         content: const Text(
//           'هل تريد إعادة تعيين الخريطة بالكامل؟\nسيتم حذف جميع المواقع والمحطات المحددة.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               'إلغاء',
//               style: TextStyle(color: Colors.grey.shade600),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);

//               Get.snackbar(
//                 'تم إعادة التعيين',
//                 'تم إعادة تعيين الخريطة بنجاح',
//                 snackPosition: SnackPosition.BOTTOM,
//                 backgroundColor: Colors.green,
//                 colorText: Colors.white,
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//             ),
//             child: const Text(
//               'إعادة تعيين',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
