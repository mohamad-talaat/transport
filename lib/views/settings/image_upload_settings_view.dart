// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:transport_app/services/unified_image_service.dart';

// class ImageUploadSettingsView extends StatelessWidget {
//   const ImageUploadSettingsView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final ImageUploadService imageService = Get.find<ImageUploadService>();

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text('إعدادات رفع الصور'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildHeader(),
//             const SizedBox(height: 24),
//             _buildMethodSelection(imageService),
//             const SizedBox(height: 24),
//             _buildMethodInfo(),
//             const SizedBox(height: 24),
//             _buildTestSection(imageService),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.cloud_upload, color: Colors.blue.shade700, size: 28),
//               const SizedBox(width: 12),
//               const Text(
//                 'إعدادات رفع الصور',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'اختر طريقة رفع الصور المفضلة لديك',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey.shade600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMethodSelection(ImageUploadService imageService) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'طريقة رفع الصور',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Obx(() {
//             imageService.currentMethod.value;
//             return Column(
//               children: [
//                 _buildMethodOption(
//                   imageService,
//                   ImageUploadService.local,
//                   'محلي (مجاني)',
//                   'حفظ الصور في التطبيق',
//                   Icons.phone_android,
//                   Colors.green,
//                 ),
//                 const SizedBox(height: 12),
//                 _buildMethodOption(
//                   imageService,
//                   ImageUploadService.imgbb,
//                   'ImgBB (مجاني)',
//                   'رفع الصور إلى الإنترنت',
//                   Icons.cloud,
//                   Colors.blue,
//                 ),
//                 const SizedBox(height: 12),
//                 _buildMethodOption(
//                   imageService,
//                   ImageUploadService.firebaseStorage,
//                   'Firebase Storage (مدفوع)',
//                   'خدمة سحابية احترافية',
//                   Icons.storage,
//                   Colors.orange,
//                 ),
//               ],
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildMethodOption(
//     ImageUploadService imageService,
//  ImageUploadMethod method,
//      String title,
//     String description,
//     IconData icon,
//     Color color,
//   ) {
//     return Obx(() {
//       final isSelected = imageService.currentMethod.value == method;

//       return GestureDetector(
//         onTap: () => imageService.setPreferredMethod(method),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: isSelected ? color : Colors.grey.shade300,
//               width: isSelected ? 2 : 1,
//             ),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(icon, color: color, size: 24),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: isSelected ? color : Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       description,
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               if (isSelected)
//                 Icon(
//                   Icons.check_circle,
//                   color: color,
//                   size: 24,
//                 ),
//             ],
//           ),
//         ),
//       );
//     });
//   }

//   Widget _buildMethodInfo() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'معلومات الطرق',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           _buildInfoItem(
//             'محلي (مجاني)',
//             '• الصور محفوظة في التطبيق\n• لا تحتاج إنترنت\n• مساحة محدودة',
//             Icons.phone_android,
//             Colors.green,
//           ),
//           const SizedBox(height: 16),
//           _buildInfoItem(
//             'ImgBB (مجاني)',
//             '• رفع مجاني للإنترنت\n• 32 ميجابايت لكل صورة\n• لا يمكن حذف الصور',
//             Icons.cloud,
//             Colors.blue,
//           ),
//           const SizedBox(height: 16),
//           _buildInfoItem(
//             'Firebase Storage (مدفوع)',
//             '• خدمة سحابية احترافية\n• مساحة غير محدودة\n• تحكم كامل في الصور',
//             Icons.storage,
//             Colors.orange,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoItem(
//     String title,
//     String description,
//     IconData icon,
//     Color color,
//   ) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, color: color, size: 20),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 description,
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTestSection(ImageUploadService imageService) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'اختبار الرفع',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'اختبر طريقة رفع الصور المحددة',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: () => _testImageUpload(imageService),
//                   icon: const Icon(Icons.upload),
//                   label: const Text('اختبار الرفع'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: () => _clearAllImages(imageService),
//                   icon: const Icon(Icons.clear_all),
//                   label: const Text('مسح الصور'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   void _testImageUpload(ImageUploadService imageService) async {
//     try {
//       final file = await imageService.pickImageFromGallery();
//       if (file != null) {
//         final result = await imageService.uploadImage(
//           imageFile: file,
//           folder: 'test',
//           fileName: 'test_image_${DateTime.now().millisecondsSinceEpoch}',
//         );

//         if (result != null) {
//           Get.snackbar(
//             'نجح',
//             'تم رفع الصورة بنجاح',
//             snackPosition: SnackPosition.BOTTOM,
//             backgroundColor: Colors.green,
//             colorText: Colors.white,
//           );
//         }
//       }
//     } catch (e) {
//       Get.snackbar(
//         'خطأ',
//         'فشل في رفع الصورة',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

//   void _clearAllImages(ImageUploadService imageService) async {
//     final confirmed = await Get.dialog<bool>(
//       AlertDialog(
//         title: const Text('تأكيد المسح'),
//         content: const Text('هل أنت متأكد من مسح جميع الصور المحفوظة؟'),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(result: false),
//             child: const Text('إلغاء'),
//           ),
//           ElevatedButton(
//             onPressed: () => Get.back(result: true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('مسح'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         final localService = Get.find<ImageUploadService>();
//         await localService.clearAllImages();

//         Get.snackbar(
//           'نجح',
//           'تم مسح جميع الصور المحفوظة',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//         );
//       } catch (e) {
//         Get.snackbar(
//           'خطأ',
//           'فشل في مسح الصور',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//         );
//       }
//     }
//   }
// }
