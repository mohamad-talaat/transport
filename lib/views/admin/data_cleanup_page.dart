// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:transport_app/utils/fix_duplicate_fields_script.dart';

// /// صفحة إدارة تنظيف البيانات
// /// استخدمها لتشغيل السكريبت مرة واحدة فقط
// class DataCleanupPage extends StatelessWidget {
//   const DataCleanupPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('تنظيف البيانات المكررة'),
//         backgroundColor: Colors.red.shade700,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // تحذير
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.shade50,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: Colors.orange.shade300, width: 2),
//                 ),
//                 child: Column(
//                   children: [
//                     Icon(Icons.warning_amber_rounded, 
//                         size: 64, 
//                         color: Colors.orange.shade700),
//                     const SizedBox(height: 16),
//                     Text(
//                       '⚠️ تحذير مهم',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.orange.shade900,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       'هذا السكريبت سيعدل بيانات جميع السائقين في قاعدة البيانات.\n'
//                       'تأكد من عمل نسخة احتياطية قبل التنفيذ.',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.orange.shade800,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
              
//               const SizedBox(height: 40),

//               // معاينة
//               ElevatedButton.icon(
//                 onPressed: () async {
//                   await FixDuplicateFieldsScript.preview();
//                   Get.snackbar(
//                     'تم',
//                     'تحقق من Console لرؤية المعاينة',
//                     backgroundColor: Colors.blue,
//                     colorText: Colors.white,
//                   );
//                 },
//                 icon: const Icon(Icons.preview),
//                 label: const Text('معاينة فقط'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                   textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),

//               const SizedBox(height: 16),

//               // تشغيل
//               ElevatedButton.icon(
//                 onPressed: () {
//                   _showConfirmDialog(context);
//                 },
//                 icon: const Icon(Icons.cleaning_services),
//                 label: const Text('تنظيف كل السائقين'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                   textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),

//               const SizedBox(height: 40),

//               // ملاحظات
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'ℹ️ ما الذي سيتم:',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue.shade900,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     _buildInfoItem('توحيد currentLatitude/currentLongitude'),
//                     _buildInfoItem('توحيد vehicleModel/vehicleColor/vehicleType'),
//                     _buildInfoItem('توحيد vehiclePlateNumber'),
//                     _buildInfoItem('حذف الحقول المكررة من additionalData'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoItem(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 4),
//       child: Row(
//         children: [
//           Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(text, style: const TextStyle(fontSize: 14)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showConfirmDialog(BuildContext context) {
//     Get.defaultDialog(
//       title: 'تأكيد التنفيذ',
//       titleStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//       middleText: 'هل أنت متأكد من تنظيف بيانات جميع السائقين؟\n'
//                   'هذا الإجراء لا يمكن التراجع عنه.',
//       textConfirm: 'نعم، نفذ',
//       textCancel: 'إلغاء',
//       confirmTextColor: Colors.white,
//       buttonColor: Colors.red,
//       cancelTextColor: Colors.black,
//       onConfirm: () async {
//         Get.back(); // إغلاق الديالوج
//         await FixDuplicateFieldsScript.run();
//       },
//       onCancel: () {
//         Get.back();
//       },
//     );
//   }
// }
