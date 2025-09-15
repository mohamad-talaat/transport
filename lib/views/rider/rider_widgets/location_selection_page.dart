// // location_selection_page.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:transport_app/controllers/map_controller.dart';

// class LocationSelectionPage extends StatelessWidget {
//   final String locationType; // 'additional_stop'
//   final String title;

//   const LocationSelectionPage({
//     super.key,
//     required this.locationType,
//     required this.title,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final MapControllerr mapController = Get.find<MapControllerr>();

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Stack(
//         children: [
//           // Map
//           _buildMap(mapController),
          
//           // Enhanced center pin
//           _buildCenterPin(mapController),
          
//           // Top app bar
//           _buildTopAppBar(context),
          
//           // Bottom confirmation section
//           _buildBottomConfirmationSection(mapController),
//         ],
//       ),
//     );
//   }

//   Widget _buildMap(MapControllerr mapController) {
//     return Obx(() => FlutterMap(
//       mapController: mapController.mapController,
//       options: MapOptions(
//         initialCenter: mapController.mapCenter.value,
//         initialZoom: mapController.mapZoom.value,
//         minZoom: 5.0,
//         maxZoom: 18.0,
//         interactionOptions: const InteractionOptions(
//           flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
//         ),
//         onPositionChanged: (camera, hasGesture) {
//           if (hasGesture) {
//             mapController.mapCenter.value = camera.center;
//             mapController.mapZoom.value = camera.zoom;
//           }
//         },
//       ),
//       children: [
//         TileLayer(
//           urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//           userAgentPackageName: 'com.example.transport_app',
//           maxZoom: 19,
//           maxNativeZoom: 18,
//         ),
//         // Show existing markers
//         MarkerLayer(markers: mapController.markers),
//         PolylineLayer(polylines: mapController.polylines),
//       ],
//     ));
//   }

//   Widget _buildCenterPin(MapControllerr mapController) {
//     return Positioned(
//       top: 0,
//       bottom: 0,
//       left: 0,
//       right: 0,
//       child: IgnorePointer(
//         child: Center(
//           child: Obx(() => EnhancedPinWidget(
//             color: Colors.black,
//             label: _getPinLabel(),
//             isMoving: mapController.isMapMoving.value,
//             showLabel: true,
//             size: 32,
//             zoomLevel: mapController.mapZoom.value,
//           )),
//         ),
//       ),
//     );
//   }

//   String _getPinLabel() {
//     switch (locationType) {
//       case 'additional_stop':
//         return 'وصول ${Get.find<MapControllerr>().additionalStops.length + 2}';
//       default:
//         return 'الموقع';
//     }
//   }

//   Widget _buildTopAppBar(BuildContext context) {
//     return Positioned(
//       top: 0,
//       left: 0,
//       right: 0,
//       child: Container(
//         padding: EdgeInsets.only(
//           top: MediaQuery.of(context).padding.top + 8,
//           left: 16,
//           right: 16,
//           bottom: 16,
//         ),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             // Close button
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 shape: BoxShape.circle,
//               ),
//               child: IconButton(
//                 icon: const Icon(Icons.close, color: Colors.black87),
//                 onPressed: () {
//                   // Return to home without affecting existing selections
//                   Get.find<MapControllerr>().currentStep.value = 'none';
//                   Get.back();
//                 },
//               ),
//             ),
//             const SizedBox(width: 16),
//             // Title
//             Expanded(
//               child: Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBottomConfirmationSection(MapControllerr mapController) {
//     return Positioned(
//       bottom: 0,
//       left: 0,
//       right: 0,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 12,
//               offset: const Offset(0, -4),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Address display
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade50,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.grey.shade200),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         width: 32,
//                         height: 32,
//                         decoration: const BoxDecoration(
//                           color: Colors.black12,
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(
//                           Icons.add_location_alt,
//                           color: Colors.black87,
//                           size: 18,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               _getPinLabel(),
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey.shade600,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                             const SizedBox(height: 2),
//                             Obx(() {
//                               String displayAddress = mapController.currentPinAddress.value;
//                               if (displayAddress.isEmpty) {
//                                 displayAddress = mapController.isMapMoving.value
//                                     ? 'جاري تحديد الموقع...'
//                                     : 'موقعك الحالي على الخريطة';
//                               }
//                               return Text(
//                                 displayAddress,
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.black87,
//                                 ),
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                               );
//                             }),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
//             // Confirm button
//             Obx(() => SizedBox(
//               width: double.infinity,
//               height: 52,
//               child: ElevatedButton(
//                 onPressed: mapController.showConfirmButton.value
//                     ? () => _confirmLocation(mapController)
//                     : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.black87,
//                   foregroundColor: Colors.white,
//                   disabledBackgroundColor: Colors.grey.shade300,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: mapController.showConfirmButton.value ? 4 : 0,
//                 ),
//                 child: Text(
//                   mapController.showConfirmButton.value
//                       ? 'تثبيت ${_getPinLabel()}'
//                       : 'جاري تحديد الموقع...',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             )),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _confirmLocation(MapControllerr mapController) async {
//     try {
//       await mapController.confirmPinLocation();
//       // Return to home after successful confirmation
//       Get.back();
//     } catch (e) {
//       Get.snackbar(
//         'خطأ',
//         'تعذر تثبيت الموقع، يرجى المحاولة مرة أخرى',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }
// }