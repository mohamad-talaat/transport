// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:transport_app/controllers/auth_controller.dart';
// import 'package:transport_app/controllers/map_controller.dart';
// import 'package:transport_app/controllers/map_controller_copy.dart';
// import 'package:transport_app/controllers/trip_controller.dart';
// import 'package:transport_app/models/trip_model.dart';
// import 'package:transport_app/routes/app_routes.dart';
// import 'package:transport_app/services/location_service.dart';
// import 'package:transport_app/views/rider/rider_widgets/animated_balance.dart';
// import 'package:transport_app/views/rider/rider_widgets/arabic_name.dart';
// import 'package:transport_app/views/rider/rider_widgets/drawer.dart';
// import 'package:transport_app/views/rider/rider_widgets/pin_painter.dart';
// import 'package:transport_app/views/rider/rider_widgets/top_search_bar.dart';

// class RiderHomeView extends StatefulWidget {
//   const RiderHomeView({super.key});

//   @override
//   State<RiderHomeView> createState() => _RiderHomeViewState();
// }

// class _RiderHomeViewState extends State<RiderHomeView>
//     with TickerProviderStateMixin {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   final AuthController authController = Get.find<AuthController>();
//   final MapControllerr mapController =
//       Get.put(MapControllerr(), permanent: true);
//   final TripController tripController = Get.find<TripController>();

//   // Booking state - Clean implementation
//   final RxBool isRoundTrip = false.obs;
//   final RxInt waitingTime = 0.obs;
//   final RxDouble baseFare = 0.0.obs;
//   final RxDouble totalFare = 0.0.obs;
//   bool _isDisposed = false;

//   // Animations
//   late AnimationController _slideController;
//   late AnimationController _priceAnimationController;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _priceAnimation;

//   final DraggableScrollableController _bottomSheetController =
//       DraggableScrollableController();

//   // Iraqi Dinar exchange rate
//   final double iqd_exchange_rate = 1500.0;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _setupLocationListeners();
//     _checkUserProfile();
//   }

//   void _initializeAnimations() {
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );

//     _priceAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 1),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.easeOut,
//     ));

//     _priceAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.1,
//     ).animate(CurvedAnimation(
//       parent: _priceAnimationController,
//       curve: Curves.elasticOut,
//     ));

//     _slideController.forward();
//   }

//   void _setupLocationListeners() {
//     // Listen to confirmed locations for fare calculation
//     ever(mapController.isPickupConfirmed, (bool confirmed) {
//       if (!_isDisposed && confirmed) _calculateFare();
//     });

//     ever(mapController.isDestinationConfirmed, (bool confirmed) {
//       if (!_isDisposed && confirmed) _calculateFare();
//     });

//     ever(mapController.selectedLocation, (LatLng? location) {
//       if (!_isDisposed &&
//           location != null &&
//           mapController.currentLocation.value != null) {
//         _calculateFare();
//       }
//     });

//     // UPDATED: Listen to additional stops changes
//     ever(mapController.additionalStops, (List<AdditionalStop> stops) {
//       _calculateFare();
//     });
//   }

//   void _checkUserProfile() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final user = authController.currentUser.value;
//       if (user != null) {
//         final bool missingName = ((user.name ?? '').trim().isEmpty);
//         final bool missingPhone = ((user.phone ?? '').trim().isEmpty);
//         if (missingName || missingPhone) {
//           Get.toNamed(AppRoutes.RIDER_PROFILE_COMPLETION);
//         }
//       }
//     });
//   }

//   void _calculateFare() {
//     if (_isDisposed ||
//         mapController.currentLocation.value == null ||
//         mapController.selectedLocation.value == null) return;

//     final from = mapController.currentLocation.value!;
//     final to = mapController.selectedLocation.value!;
//     final distanceKm = LocationService.to.calculateDistance(from, to);

//     // Base fare calculation (in USD, then convert to IQD)
//     double fareUSD = 2.0 + (distanceKm * 0.8);

//     // UPDATED: Additional stops from mapController
//     fareUSD += mapController.additionalStops.length * 1.5;

//     // Waiting time
//     fareUSD += waitingTime.value * 0.2;

//     // Round trip
//     if (isRoundTrip.value) {
//       fareUSD *= 1.8;
//     }

//     baseFare.value = fareUSD * iqd_exchange_rate;
//     totalFare.value = baseFare.value;

//     _animatePriceChange();
//   }

//   void _animatePriceChange() {
//     if (_isDisposed) return;

//     try {
//       _priceAnimationController.reset();
//       _priceAnimationController.forward();
//     } catch (e) {
//       // Ignore animation errors if controller is disposed
//     }
//   }

//   @override
//   void dispose() {
//     _isDisposed = true;

//     // Dispose animation controllers safely
//     try {
//       _slideController.dispose();
//     } catch (e) {
//       // Ignore disposal errors
//     }

//     try {
//       _priceAnimationController.dispose();
//     } catch (e) {
//       // Ignore disposal errors
//     }

//     try {
//       _bottomSheetController.dispose();
//     } catch (e) {
//       // Ignore disposal errors
//     }

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       drawer: RiderDrawer(authController: authController), //_buildDrawer(),
//       body: Stack(
//         children: [
//           _buildOptimizedMap(),
//           _buildEnhancedCenterPin(),
//           const ExpandableSearchBar(),
//           const SearchResultsOverlay(),
//           BalanceAnimatedText(
//             balance: (authController.currentUser.value?.balance ?? 0.0) *
//                 iqd_exchange_rate,
//           ),
//           _buildSideControls(),
//           _buildConfirmLocationButton(),
//           _buildEnhancedBottomSheet(),
//           _buildLoadingOverlay(),
//         ],
//       ),
//     );
//   }

//   // إضافة المتغير ده في الكلاس اللي فيه الخريطة
//   RxDouble currentZoom = 13.0.obs;

//   Widget _buildOptimizedMap() {
//     return Obx(() => FlutterMap(
//           mapController: mapController.mapController,
//           options: MapOptions(
//             initialCenter: mapController.mapCenter.value,
//             initialZoom: mapController.mapZoom.value,
//             minZoom: 5.0,
//             maxZoom: 18.0,
//             interactionOptions: const InteractionOptions(
//               flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
//             ),
//          //   onTap: (tapPosition, point) => _onMapTap(point),
//             onPositionChanged: (camera, hasGesture) {
//               if (hasGesture) {
//                 final distance = LocationService.to.calculateDistance(
//                   mapController.mapCenter.value,
//                   camera.center,
//                 );
//                 if (distance > 0.01) {
//                   mapController.mapCenter.value = camera.center;
//                   mapController.mapZoom.value = camera.zoom;
//                 }
//               }
//             },
//           ),
//           children: [
//             TileLayer(
//               urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//               userAgentPackageName: 'com.example.transport_app',
//               maxZoom: 19,
//               maxNativeZoom: 18,
//             ),
//             CircleLayer(circles: mapController.circles),
//             PolylineLayer(polylines: mapController.polylines),
//             MarkerLayer(markers: mapController.markers),
//           ],
//         ));
//   }

//   Widget _buildEnhancedCenterPin() {
//     return Obx(() {
//       if (mapController.currentStep.value == 'none') {
//         return const SizedBox.shrink();
//       }

//       return Positioned(
//         top: 0,
//         bottom: 0,
//         left: 0,
//         right: 0,
//         child: IgnorePointer(
//           child: Center(
//             child: EnhancedPinWidget(
//               color: _getStepColor(mapController.currentStep.value),
//               label: _getStepText(mapController.currentStep.value),
//             //  isMoving: mapController.isMapMoving.value,
//               showLabel: false, // Only show before confirmation
//               size: 40,
//               zoomLevel: mapController
//                   .mapZoom.value, // <--- **هذا هو الإضافة المطلوبة**
//             ),
//           ),
//         ),
//       );
//     });
//   }

//   Color _getStepColor(String step) {
//     switch (step) {
//       case 'pickup':
//         return Colors.green;
//       case 'destination':
//         return Colors.red;
//       case 'additional_stop':
//         return Colors.orange;
//       default:
//         return Colors.blue;
//     }
//   }

//   String _getStepText(String step) {
//     switch (step) {
//       case 'pickup':
//         return 'نقطة الانطلاق';
//       case 'destination':
//         return 'الوصول';
//       case 'additional_stop':
//         return 'محطة ';
//       default:
//         return 'اختر الموقع';
//     }
//   }

//   Widget _buildSideControls() {
//     return Positioned(
//       right: 16,
//       top: MediaQuery.of(context).size.height / 2 - 60,
//       child: Column(
//         children: [
//           _buildControlButton(
//             icon: Icons.my_location,
//             color: Colors.blue,
//             onPressed: () => mapController.refreshCurrentLocation(),
//           ),
//           const SizedBox(height: 8),
//           _buildControlButton(
//             icon: Icons.zoom_in,
//             color: Colors.grey.shade600,
//             onPressed: _zoomIn,
//           ),
//           const SizedBox(height: 6),
//           _buildControlButton(
//             icon: Icons.zoom_out,
//             color: Colors.grey.shade600,
//             onPressed: _zoomOut,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildControlButton({
//     required IconData icon,
//     required Color color,
//     required VoidCallback onPressed,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         shape: BoxShape.circle,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: IconButton(
//         iconSize: 20,
//         icon: Icon(icon, color: color),
//         onPressed: onPressed,
//       ),
//     );
//   }

//   void _zoomIn() {
//     double newZoom = mapController.mapZoom.value + 1;
//     if (newZoom <= 18) {
//       mapController.mapController.move(mapController.mapCenter.value, newZoom);
//       mapController.mapZoom.value = newZoom;
//     }
//   }

//   void _zoomOut() {
//     double newZoom = mapController.mapZoom.value - 1;
//     if (newZoom >= 5) {
//       mapController.mapController.move(mapController.mapCenter.value, newZoom);
//       mapController.mapZoom.value = newZoom;
//     }
//   }

//   Widget _buildConfirmLocationButton() {
//     return Positioned(
//       bottom: MediaQuery.of(context).size.height * 0.52,
//       left: 0,
//       right: 0,
//       child: Obx(() => AnimatedSlide(
//             duration: const Duration(milliseconds: 300),
//             offset: mapController.showConfirmButton.value
//                 ? Offset.zero
//                 : const Offset(0, 2),
//             child: AnimatedOpacity(
//               duration: const Duration(milliseconds: 300),
//               opacity: mapController.showConfirmButton.value ? 1.0 : 0.0,
//               child: mapController.showConfirmButton.value
//                   ? Center(
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.08),
//                               blurRadius: 6,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                           border: Border.all(
//                             color: Colors.orange.shade300,
//                             width: 0.8,
//                           ),
//                         ),
//                         child: Material(
//                           color: Colors.transparent,
//                           child: InkWell(
//                             borderRadius: BorderRadius.circular(16),
//                             onTap: _confirmCurrentLocation,
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                                 vertical: 8,
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Container(
//                                     width: 28,
//                                     height: 28,
//                                     decoration: BoxDecoration(
//                                       color: Colors.orange.shade400,
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: const Icon(
//                                       Icons.check,
//                                       color: Colors.white,
//                                       size: 14,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 6),
//                                   Text(
//                                     'تثبيت نقطة ${_getStepText(mapController.currentStep.value)}',
//                                     style: TextStyle(
//                                       color: Colors.orange.shade700,
//                                       fontWeight: FontWeight.w600,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     )
//                   : const SizedBox.shrink(),
//             ),
//           )),
//     );
//   }

//   void _onMapTap(LatLng point) async {
//     mapController.selectedLocation.value = point;
//     FocusScope.of(context).unfocus();
//     mapController.searchResults.clear();
//   }

//   Future<void> _confirmCurrentLocation() async {
//     if (_isDisposed) return;

//     await mapController.confirmPinLocation();
//     if (_isDisposed) return;

//     _minimizeBottomSheet();

//     // Show bottom sheet again after confirmation
//     Future.delayed(const Duration(milliseconds: 800), () {
//       if (!_isDisposed) {
//         _expandBottomSheet();
//       }
//     });
//   }

//   // تحديث دالة _expandBottomSheet و _minimizeBottomSheet:
//   // FIXED: Safe bottom sheet operations with disposal checks
//   void _expandBottomSheet() {
//     if (_isDisposed) return;

//     try {
//       _bottomSheetController.animateTo(
//         0.35,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     } catch (e) {
//       // Ignore if disposed
//     }
//   }

//   void _minimizeBottomSheet() {
//     if (_isDisposed) return;

//     try {
//       _bottomSheetController.animateTo(
//         0.20,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     } catch (e) {
//       // Ignore if disposed
//     }
//   }

//   Widget _buildEnhancedBottomSheet() {
//     return Positioned(
//       bottom: 0,
//       left: 0,
//       right: 0,
//       top: 0,
//       child: SlideTransition(
//         position: _slideAnimation,
//         child: _buildProgressiveBookingSheet(),
//       ),
//     );
//   }

//   Widget _buildProgressiveBookingSheet() {
//     return DraggableScrollableSheet(
//       controller: _bottomSheetController,
//       initialChildSize: 0.35,
//       minChildSize: 0.20,
//       maxChildSize: 0.9,
//       expand: false,
//       builder: (context, scrollController) {
//         return Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.08),
//                 blurRadius: 12,
//                 offset: const Offset(0, -8),
//               ),
//             ],
//           ),
//           child: ListView(
//             controller: scrollController,
//             padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 1),
//             children: [
//               _buildHandle(),
//               const Text(
//                 'تفاصيل الرحلة',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 3),
//               _buildLocationInputSection(),
//               Obx(() {
//                 if (baseFare.value > 0) {
//                   return Column(
//                     children: [
//                       const SizedBox(height: 7),
//                       _buildTripOptionsSection(),
//                     ],
//                   );
//                 }
//                 return const SizedBox.shrink();
//               }),
//               Obx(() {
//                 if (totalFare.value > 0) {
//                   return Column(
//                     children: [
//                       const SizedBox(height: 10),
//                       _buildFareDisplay(),
//                       const SizedBox(height: 10),
//                       _buildBookButton(),
//                     ],
//                   );
//                 }
//                 return const SizedBox.shrink();
//               }),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildHandle() {
//     return Center(
//       child: Container(
//         width: 40,
//         height: 4,
//         margin: const EdgeInsets.only(bottom: 16),
//         decoration: BoxDecoration(
//           color: Colors.grey.shade300,
//           borderRadius: BorderRadius.circular(2),
//         ),
//       ),
//     );
//   }

//   Widget _buildLocationInputSection() {
//     return Column(
//       children: [
//         // Pickup location
//         Obx(() => _buildLocationInputField(
//               icon: Icons.radio_button_checked,
//               iconColor: Colors.green,
//               label: 'نقطة الانطلاق',
//               value: mapController.isPickupConfirmed.value
//                   ? mapController.currentAddress.value.isNotEmpty
//                       ? mapController.currentAddress.value
//                       : 'الموقع الحالي'
//                   : 'اختر نقطة الانطلاق',
//               isSet: mapController.isPickupConfirmed.value,
//               onTap: () => mapController.startLocationSelection('pickup'),
//             )),

//         // Line connector
//         Container(
//           margin: const EdgeInsets.symmetric(vertical: 1),
//           child: Row(
//             children: [
//               const SizedBox(width: 28),
//               Container(width: 2, height: 15, color: Colors.grey.shade300),
//             ],
//           ),
//         ),

//         // Destination location
//         Obx(() => _buildLocationInputField(
//               icon: Icons.location_on,
//               iconColor: Colors.red,
//               label: 'نقطة الوصول',
//               value: mapController.isDestinationConfirmed.value
//                   ? mapController.selectedAddress.value.isNotEmpty
//                       ? mapController.selectedAddress.value
//                       : 'تم تحديد الوجهة'
//                   : 'اختر نقطة الوصول',
//               isSet: mapController.isDestinationConfirmed.value,
//               onTap: () => mapController.startLocationSelection('destination'),
//             )),
//       ],
//     );
//   }

//   Widget _buildLocationInputField({
//     required IconData icon,
//     required Color iconColor,
//     required String label,
//     required String value,
//     required bool isSet,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: () {
//         onTap();
//         _minimizeBottomSheet();
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
//         child: Row(
//           children: [
//             Container(
//               width: 32,
//               height: 32,
//               decoration: BoxDecoration(
//                 color: iconColor.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, color: iconColor, size: 18),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     label,
//                     style: TextStyle(
//                       fontSize: 10,
//                       color: Colors.grey[600],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     value,
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: isSet ? FontWeight.w600 : FontWeight.w400,
//                       color: isSet ? Colors.black87 : Colors.grey,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//             Icon(
//               isSet ? Icons.check_circle : Icons.edit_location_alt,
//               color: isSet ? Colors.green : Colors.grey[400],
//               size: 18,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTripOptionsSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'خيارات الرحلة',
//           style: TextStyle(
//             fontSize: 15,
//             fontWeight: FontWeight.bold,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 16),
//         _buildAdditionalStopsSection(),
//         const SizedBox(height: 16),
//         _buildTripTypeSection(),
//         const SizedBox(height: 16),
//         _buildWaitingTimeSection(),
//       ],
//     );
//   }

//   // UPDATED: Build additional stops section with proper display
//   Widget _buildAdditionalStopsSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'نقاط وصول إضافية',
//           style: TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.w600,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 8),

//         // UPDATED: Show existing additional stops from mapController
//         Obx(() => Column(
//               children: mapController.additionalStops
//                   .map((stop) => Container(
//                         margin: const EdgeInsets.only(bottom: 8),
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.orange.shade50,
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.orange.shade200),
//                         ),
//                         child: Row(
//                           children: [
//                             Container(
//                               width: 24,
//                               height: 24,
//                               decoration: BoxDecoration(
//                                 color: Colors.orange.shade600,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Center(
//                                 child: Text(
//                                   '${stop.stopNumber}',
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'محطة ${stop.stopNumber}',
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.orange.shade700,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                   Text(
//                                     stop.address,
//                                     style: const TextStyle(fontSize: 12),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             IconButton(
//                               icon: Icon(Icons.close,
//                                   size: 16, color: Colors.red.shade400),
//                               onPressed: () =>
//                                   mapController.removeAdditionalStop(stop.id),
//                             ),
//                           ],
//                         ),
//                       ))
//                   .toList(),
//             )),

//         // UPDATED: Add additional stop button with proper limit check
//         Obx(() {
//           if (mapController.additionalStops.length <
//               mapController.maxAdditionalStops.value) {
//             return _buildAddStopButton(
//                 'إضافة محطة  ${mapController.additionalStops.length + 1}');
//           }
//           return Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade100,
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.grey.shade300),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.info, color: Colors.grey.shade600, size: 16),
//                 const SizedBox(width: 8),
//                 Text(
//                   'الحد الأقصى ${mapController.maxAdditionalStops.value} محطات وسطية',
//                   style: TextStyle(
//                     color: Colors.grey.shade600,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }),
//       ],
//     );
//   }

//   Widget _buildAddStopButton(String label) {
//     return GestureDetector(
//       onTap: () {
//         mapController.startLocationSelection('additional_stop');
//         _minimizeBottomSheet();
//       },
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.orange.shade50,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: Colors.orange.shade200, width: 1),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.add_location_alt,
//                 color: Colors.orange.shade600, size: 16),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: TextStyle(
//                 color: Colors.orange.shade700,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTripTypeSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'نوع الرحلة',
//           style: TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.w600,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.grey.shade50,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey.shade200),
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 child: Obx(() => GestureDetector(
//                       onTap: () {
//                         isRoundTrip.value = false;
//                         _calculateFare();
//                       },
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         decoration: BoxDecoration(
//                           color: !isRoundTrip.value
//                               ? Colors.orange.shade400
//                               : Colors.transparent,
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Text(
//                           'ذهاب فقط',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: !isRoundTrip.value
//                                 ? Colors.white
//                                 : Colors.grey.shade600,
//                             fontWeight: FontWeight.w500,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                     )),
//               ),
//               Expanded(
//                 child: Obx(() => GestureDetector(
//                       onTap: () {
//                         isRoundTrip.value = true;
//                         _calculateFare();
//                       },
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         decoration: BoxDecoration(
//                           color: isRoundTrip.value
//                               ? Colors.orange.shade400
//                               : Colors.transparent,
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Text(
//                           'ذهاب وعودة',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: isRoundTrip.value
//                                 ? Colors.white
//                                 : Colors.grey.shade600,
//                             fontWeight: FontWeight.w500,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                     )),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildWaitingTimeSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'التوقف في الطريق',
//           style: TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.w600,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Expanded(child: _buildWaitingTimeOption(0, 'بدون توقف')),
//             const SizedBox(width: 8),
//             Expanded(child: _buildWaitingTimeOption(5, '5 دقائق')),
//             const SizedBox(width: 8),
//             Expanded(child: _buildWaitingTimeOption(10, '10 دقائق')),
//             const SizedBox(width: 8),
//             Expanded(child: _buildWaitingTimeOption(15, '15 دقيقة')),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildWaitingTimeOption(int minutes, String label) {
//     return Obx(() => GestureDetector(
//           onTap: () {
//             waitingTime.value = minutes;
//             _calculateFare();
//           },
//           child: Container(
//             padding: const EdgeInsets.symmetric(vertical: 10),
//             decoration: BoxDecoration(
//               color: waitingTime.value == minutes
//                   ? Colors.orange.shade400
//                   : Colors.grey.shade50,
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                 color: waitingTime.value == minutes
//                     ? Colors.orange.shade400
//                     : Colors.grey.shade200,
//               ),
//             ),
//             child: Column(
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     color: waitingTime.value == minutes
//                         ? Colors.white
//                         : Colors.grey.shade600,
//                     fontSize: 10,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 if (minutes > 0) ...[
//                   const SizedBox(height: 2),
//                   Text(
//                     '+${(minutes * 0.2 * iqd_exchange_rate).toStringAsFixed(0)} د.ع',
//                     style: TextStyle(
//                       color: waitingTime.value == minutes
//                           ? Colors.white70
//                           : Colors.grey.shade500,
//                       fontSize: 8,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ));
//   }

//   Widget _buildFareDisplay() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.orange.shade400, Colors.orange.shade600],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         children: [
//           const Text(
//             'إجمالي التكلفة',
//             style: TextStyle(color: Colors.white, fontSize: 14),
//           ),
//           const SizedBox(height: 8),
//           AnimatedBuilder(
//             animation: _priceAnimation,
//             builder: (context, child) {
//               return Transform.scale(
//                 scale: _priceAnimation.value,
//                 child: Obx(() => Text(
//                       '${totalFare.value.toStringAsFixed(0)} دينار عراقي',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     )),
//               );
//             },
//           ),
//           const SizedBox(height: 8),
//           _buildFareBreakdown(),
//         ],
//       ),
//     );
//   }

//   Widget _buildFareBreakdown() {
//     return Obx(() {
//       if (mapController.additionalStops.isNotEmpty ||
//           waitingTime.value > 0 ||
//           isRoundTrip.value) {
//         return Column(
//           children: [
//             const Divider(color: Colors.white24),
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text('التكلفة الأساسية:',
//                     style: TextStyle(color: Colors.white70, fontSize: 12)),
//                 Text('${baseFare.value.toStringAsFixed(0)} د.ع',
//                     style:
//                         const TextStyle(color: Colors.white70, fontSize: 12)),
//               ],
//             ),
//             // UPDATED: Use mapController.additionalStops
//             if (mapController.additionalStops.isNotEmpty) ...[
//               const SizedBox(height: 4),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                       'محطات إضافية (${mapController.additionalStops.length}):',
//                       style:
//                           const TextStyle(color: Colors.white70, fontSize: 12)),
//                   Text(
//                       '+${(mapController.additionalStops.length * 1.5 * iqd_exchange_rate).toStringAsFixed(0)} د.ع',
//                       style:
//                           const TextStyle(color: Colors.white70, fontSize: 12)),
//                 ],
//               ),
//             ],
//             if (waitingTime.value > 0) ...[
//               const SizedBox(height: 4),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text('وقت انتظار (${waitingTime.value} دقيقة):',
//                       style:
//                           const TextStyle(color: Colors.white70, fontSize: 12)),
//                   Text(
//                       '+${(waitingTime.value * 0.2 * iqd_exchange_rate).toStringAsFixed(0)} د.ع',
//                       style:
//                           const TextStyle(color: Colors.white70, fontSize: 12)),
//                 ],
//               ),
//             ],
//             if (isRoundTrip.value) ...[
//               const SizedBox(height: 4),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text('ذهاب وعودة:',
//                       style: TextStyle(color: Colors.white70, fontSize: 12)),
//                   Text('×1.8',
//                       style:
//                           const TextStyle(color: Colors.white70, fontSize: 12)),
//                 ],
//               ),
//             ],
//           ],
//         );
//       }
//       return const SizedBox.shrink();
//     });
//   }

//   Widget _buildBookButton() {
//     return SizedBox(
//       width: double.infinity,
//       height: 56,
//       child: ElevatedButton(
//         onPressed: () async {
//           if (!mapController.isPickupConfirmed.value ||
//               !mapController.isDestinationConfirmed.value) {
//             _showError('يرجى تحديد نقطة الانطلاق والوصول');
//             return;
//           }
//           await _requestTrip();
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.orange.shade400,
//           foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           elevation: 0,
//         ),
//         child: const Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.local_taxi, size: 20),
//             SizedBox(width: 8),
//             Text(
//               'طلب الرحلة',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // UPDATED: Request trip with additional stops from mapController
//   Future<void> _requestTrip({bool isRush = false}) async {
//     if (_isDisposed ||
//         mapController.currentLocation.value == null ||
//         mapController.selectedLocation.value == null) {
//       if (!_isDisposed) {
//         _showError('يرجى تحديد نقطة البداية والوجهة');
//       }
//       return;
//     }

//     // Build pickup and destination points
//     final pickupLatLng = mapController.currentLocation.value!;
//     final destLatLng = mapController.selectedLocation.value!;

//     String pickupAddress = mapController.currentAddress.value;
//     if (pickupAddress.isEmpty) {
//       pickupAddress =
//           await LocationService.to.getAddressFromLocation(pickupLatLng);
//       if (_isDisposed) return; // Check after async operation
//     }

//     String destinationAddress = mapController.selectedAddress.value;
//     if (destinationAddress.isEmpty) {
//       destinationAddress =
//           await LocationService.to.getAddressFromLocation(destLatLng);
//       if (_isDisposed) return; // Check after async operation
//     }

//     final pickup = LocationPoint(
//         lat: pickupLatLng.latitude,
//         lng: pickupLatLng.longitude,
//         address: pickupAddress);

//     final destination = LocationPoint(
//         lat: destLatLng.latitude,
//         lng: destLatLng.longitude,
//         address: destinationAddress);

//     // UPDATED: Add trip details with additional stops from mapController
//     final tripDetails = {
//       'additionalStops': mapController.additionalStops
//           .map((stop) => {
//                 'lat': stop.location.latitude,
//                 'lng': stop.location.longitude,
//                 'address': stop.address,
//                 'stopNumber': stop.stopNumber,
//               })
//           .toList(),
//       'isRoundTrip': isRoundTrip.value,
//       'waitingTime': waitingTime.value,
//       'totalFare': totalFare.value,
//       'isRush': isRush,
//     };

//     if (!_isDisposed) {
//       await tripController.requestTrip(
//         pickup: pickup,
//         destination: destination,
//         tripDetails: tripDetails,
//       );
//     }
//   }

//   Widget _buildLoadingOverlay() {
//     return Obx(() {
//       final bool showOverlay = mapController.isLoading.value;
//       if (!showOverlay) return const SizedBox.shrink();

//       return Container(
//         color: Colors.black.withOpacity(0.25),
//         child: Center(
//           child: Container(
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 18,
//                   offset: const Offset(0, 8),
//                 ),
//               ],
//             ),
//             child: const Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 SizedBox(
//                   width: 36,
//                   height: 36,
//                   child: CircularProgressIndicator(color: Colors.orange),
//                 ),
//                 SizedBox(height: 16),
//                 Text(
//                   'جاري التحميل...',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     });
//   }

//   // Helper methods
//   void _showSuccess(String title, String message) {
//     if (_isDisposed) return;
//     Get.snackbar(
//       title,
//       message,
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.green,
//       colorText: Colors.white,
//       duration: const Duration(seconds: 2),
//     );
//   }

//   void _showError(String message) {
//     if (_isDisposed) return;

//     Get.snackbar(
//       'خطأ',
//       message,
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//     );
//   }
// }
