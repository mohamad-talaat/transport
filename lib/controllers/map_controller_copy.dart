// import 'dart:async';
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:transport_app/main.dart';

// import 'package:transport_app/models/trip_model.dart';
// import 'package:transport_app/models/user_model.dart';
// import 'package:transport_app/services/location_service.dart';
// import 'package:transport_app/views/rider/rider_widgets/pin_painter.dart';

// class MapControllerr extends GetxController {
//   static MapControllerr get to => Get.find();

//   // Map controller
//   final MapController mapController = MapController();

//   // Enhanced Pin properties
//   final RxBool isMapMoving = false.obs;
//   final RxBool showConfirmButton = false.obs;
//   final Rx<LatLng?> centerPinLocation = Rx<LatLng?>(null);
//   final RxString currentStep = 'none'.obs;
//   Timer? _mapMovementTimer;

//   // Map state
//   final Rx<LatLng> mapCenter = const LatLng(30.0444, 31.2357).obs;
//   final RxDouble mapZoom = 15.0.obs;
//   final RxBool isMapReady = false.obs;

//   // Markers and overlays
//   final RxList<Marker> markers = <Marker>[].obs;
//   final RxList<Polyline> polylines = <Polyline>[].obs;
//   final RxList<CircleMarker> circles = <CircleMarker>[].obs;

//   // Current location
//   final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
//   final RxString currentAddress = ''.obs;

//   // Search and location selection
//   final RxList<LocationSearchResult> searchResults = <LocationSearchResult>[].obs;
//   final Rx<LatLng?> selectedLocation = Rx<LatLng?>(null);
//   final RxString selectedAddress = ''.obs;
//   final RxBool isSearching = false.obs;

//   // Additional stops - UPDATED with better management
//   final RxList<AdditionalStop> additionalStops = <AdditionalStop>[].obs;
//   final RxInt maxAdditionalStops = 2.obs;

//   // Trip tracking
//   final Rx<TripModel?> activeTrip = Rx<TripModel?>(null);
//   final RxList<LatLng> tripRoute = <LatLng>[].obs;
//   final Rx<LatLng?> driverLocation = Rx<LatLng?>(null);

//   // UI state
//   final RxBool isLoading = false.obs;
//   final TextEditingController searchController = TextEditingController();

//   // Services
//   final LocationService _locationService = LocationService.to;

//   // Route drawing streams
//   StreamSubscription<List<LatLng>>? _routeDrawingSubscription;
//   Timer? _searchDebounceTimer;

//   // Performance optimizations
//   bool _isUpdatingRoute = false;
//   DateTime? _lastRouteUpdate;
//   static const int _routeUpdateCooldown = 1000; // ms

//   // Location confirmation states
//   final RxBool isPickupConfirmed = false.obs;
//   final RxBool isDestinationConfirmed = false.obs;

//   // ADDED: Disposal flag to prevent operations after disposal
//   bool _isDisposed = false;

//   @override
//   void onInit() {
//     super.onInit();
//     _initializeMap();

//     // Optimized listeners with disposal check
//     ever(currentLocation, _onCurrentLocationChanged,
//         condition: () => !_isUpdatingRoute && !_isDisposed);

//     ever(mapCenter, (LatLng center) {
//       if (!_isDisposed) {
//         centerPinLocation.value = center;
//         _onMapMovement();
//       }
//     });

//     ever(selectedLocation, _onSelectedLocationChanged,
//         condition: () => !_isUpdatingRoute && !_isDisposed);

//     ever(additionalStops, (List<AdditionalStop> stops) {
//       if (!_isDisposed) {
//         _updateRouteIfNeededDebounced();
//       }
//     });
//   }

//   void _onCurrentLocationChanged(LatLng? location) {
//     if (_isDisposed || location == null) return;
    
//     _updateCurrentLocationMarker(location);
//     _updateRouteIfNeededDebounced();
//   }

//   void _onSelectedLocationChanged(LatLng? location) {
//     if (_isDisposed || location == null || currentLocation.value == null) return;
    
//     _updateRouteIfNeededDebounced();
//   }

//   void _updateRouteIfNeededDebounced() {
//     if (_isDisposed) return;
    
//     final now = DateTime.now();
//     if (_lastRouteUpdate != null &&
//         now.difference(_lastRouteUpdate!).inMilliseconds < _routeUpdateCooldown) {
//       return;
//     }
//     _lastRouteUpdate = now;
//     _updateRouteIfNeeded();
//   }

//   /// Initialize map
//   Future<void> _initializeMap() async {
//     if (_isDisposed) return;
    
//     isLoading.value = true;

//     try {
//       LatLng? location = await _locationService.getCurrentLocation();
//       if (_isDisposed) return; // Check again after async operation
      
//       if (location != null) {
//         currentLocation.value = location;
//         mapCenter.value = location;
//         currentAddress.value = _locationService.currentAddress.value;
//         moveToLocation(location);
//         isMapReady.value = true;
//       } else {
//         logger.w("تعذر الحصول على الموقع الحالي");
//         if (!_isDisposed) {
//           Get.snackbar("خطأ", "الموقع غير متاح حالياً");
//         }
//       }

//       if (!_isDisposed) {
//         isMapReady.value = true;
//         // Start pickup selection after initialization
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (!_isDisposed && currentLocation.value != null && currentStep.value == 'none') {
//             startLocationSelection('pickup');
//           }
//         });
//       }
//     } catch (e) {
//       logger.f('خطأ في تهيئة الخريطة: $e');
//     } finally {
//       if (!_isDisposed) {
//         isLoading.value = false;
//       }
//     }
//   }

//   /// Move map to location - with disposal check
//   void moveToLocation(LatLng location, {double zoom = 16.0}) {
//     if (_isDisposed) return;
    
//     mapCenter.value = location;
//     mapZoom.value = zoom;
    
//     try {
//       mapController.move(location, zoom);
//     } catch (e) {
//       logger.w('تم تجاهل خطأ في تحريك الخريطة: $e');
//     }
//   }

//   /// Handle map movement - with disposal check
//   void _onMapMovement() {
//     if (_isDisposed) return;
    
//     isMapMoving.value = true;
//     showConfirmButton.value = false;

//     _mapMovementTimer?.cancel();

//     _mapMovementTimer = Timer(const Duration(milliseconds: 800), () {
//       if (_isDisposed) return;
      
//       isMapMoving.value = false;
//       if (currentStep.value != 'none') {
//         showConfirmButton.value = true;
//       }
//     });
//   }

//   /// Start location selection process
//   void startLocationSelection(String step) {
//     if (_isDisposed) return;
    
//     currentStep.value = step;
//     showConfirmButton.value = false;

//     if (step == 'pickup' && currentLocation.value != null) {
//       moveToLocation(currentLocation.value!);
//     } else if (step == 'destination' &&
//         isPickupConfirmed.value &&
//         currentLocation.value != null) {
//       moveToLocation(currentLocation.value!);
//     }
//   }

//   /// FIXED: Confirm pin location with disposal checks
//   Future<void> confirmPinLocation() async {
//     if (_isDisposed || centerPinLocation.value == null || currentStep.value == 'none') {
//       return;
//     }

//     try {
//       isLoading.value = true;
//       showConfirmButton.value = false;

//       final LatLng pinLocation = centerPinLocation.value!;
//       final String address = await _locationService.getAddressFromLocation(pinLocation);

//       if (_isDisposed) return; // Check after async operation

//       switch (currentStep.value) {
//         case 'pickup':
//           await _confirmPickupLocation(pinLocation, address);
//           break;
//         case 'destination':
//           await _confirmDestinationLocation(pinLocation, address);
//           break;
//         case 'additional_stop':
//           await _confirmAdditionalStop(pinLocation, address);
//           break;
//       }
//     } catch (e) {
//       logger.w('خطأ في تأكيد موقع الـ Pin: $e');
//       if (!_isDisposed) {
//         _showError('تعذر تحديد الموقع المطلوب');
//       }
//     } finally {
//       if (!_isDisposed) {
//         isLoading.value = false;
//       }
//     }
//   }

//   /// Confirm pickup location - with disposal checks
//   Future<void> _confirmPickupLocation(LatLng location, String address) async {
//     if (_isDisposed) return;
    
//     currentLocation.value = location;
//     currentAddress.value = address;
//     isPickupConfirmed.value = true;

//     _addLocationMarker(location, 'pickup', address, showLabel: true);
//     currentStep.value = 'destination';

//     await Future.delayed(const Duration(milliseconds: 500));

//     if (!_isDisposed) {
//       _showSuccessSnackbar('تم تحديد الانطلاق', 'يمكنك الآن تحديد الوصول');

//       try {
//         searchController.text = address;
//       } catch (_) {}
//     }
//   }

//   /// Confirm destination location - with disposal checks
//   Future<void> _confirmDestinationLocation(LatLng location, String address) async {
//     if (_isDisposed) return;
    
//     selectedLocation.value = location;
//     selectedAddress.value = address;
//     isDestinationConfirmed.value = true;

//     _addLocationMarker(location, 'destination', address, showLabel: true);
//     currentStep.value = 'none';

//     _updateRouteIfNeeded();
    
//     if (!_isDisposed) {
//       _showSuccessSnackbar('تم تحديد الوصول', address);

//       try {
//         searchController.text = address;
//       } catch (_) {}
//     }
//   }

//   /// Confirm additional stop - with disposal checks
//   Future<void> _confirmAdditionalStop(LatLng location, String address) async {
//     if (_isDisposed || additionalStops.length >= maxAdditionalStops.value) {
//       if (!_isDisposed && additionalStops.length >= maxAdditionalStops.value) {
//         _showError('لا يمكن إضافة أكثر من ${maxAdditionalStops.value} نقاط وسطية');
//       }
//       return;
//     }

//     final int stopNumber = additionalStops.length + 1;
//     final String stopId = 'stop_${DateTime.now().millisecondsSinceEpoch}';

//     final AdditionalStop newStop = AdditionalStop(
//       id: stopId,
//       location: location,
//       address: address,
//       stopNumber: stopNumber,
//     );

//     additionalStops.add(newStop);
//     addAdditionalStopMarker(location, address, stopNumber, stopId);
//     currentStep.value = 'none';

//     if (!_isDisposed) {
//       _showSuccessSnackbar('تم إضافة المحطة الوسطية $stopNumber', address);
//     }
//   }

//   /// Add location marker with enhanced styling - with disposal check
//   void _addLocationMarker(LatLng location, String type, String address,
//       {bool showLabel = false}) {
//     if (_isDisposed) return;
    
//     markers.removeWhere((marker) => marker.key == Key(type));

//     Color pinColor = _getColorForStep(type);
//     String label = _getLabelForStep(type);

//     markers.add(
//       Marker(
//         key: Key(type),
//         point: location,
//         width: 45.0,
//         height: 55.0,
//         child: EnhancedPinWidget(
//           color: pinColor,
//           label: label,
//           showLabel: showLabel,
//           size: 35,
//           zoomLevel: mapZoom.value,
//         ),
//       ),
//     );
//   }

//   /// Get color for step
//   Color _getColorForStep(String step) {
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

//   /// Get label for step
//   String _getLabelForStep(String step) {
//     switch (step) {
//       case 'pickup':
//         return 'الانطلاق';
//       case 'destination':
//         return 'الوصول';
//       case 'additional_stop':
//         return 'المحطة';
//       default:
//         return 'الموقع';
//     }
//   }

//   /// Cancel pin confirmation - with disposal check
//   void cancelPinConfirmation() {
//     if (_isDisposed) return;
    
//     showConfirmButton.value = false;
//     currentStep.value = 'none';
//   }

//   /// Setup map when ready
//   void onMapReady() {
//     if (_isDisposed) return;
    
//     isMapReady.value = true;
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!_isDisposed && currentLocation.value != null) {
//         moveToLocation(currentLocation.value!);
//       }
//     });
//   }

//   /// Search location with debounce - with disposal checks
//   Future<void> searchLocation(String query) async {
//     if (_isDisposed || query.trim().isEmpty) {
//       if (!_isDisposed) {
//         searchResults.clear();
//       }
//       return;
//     }

//     _searchDebounceTimer?.cancel();
//     isSearching.value = true;

//     _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
//       if (_isDisposed) return;
      
//       try {
//         List<LocationSearchResult> results =
//             await _locationService.searchLocationAdvanced(query);

//         if (_isDisposed) return;

//         if (currentLocation.value != null) {
//           results.sort((a, b) {
//             double distanceA = _locationService.calculateDistance(
//               currentLocation.value!,
//               a.latLng,
//             );
//             double distanceB = _locationService.calculateDistance(
//               currentLocation.value!,
//               b.latLng,
//             );
//             return distanceA.compareTo(distanceB);
//           });
//         }

//         if (!_isDisposed) {
//           searchResults.assignAll(results);
//         }
//       } catch (e) {
//         logger.f('خطأ في البحث: $e');
//         if (!_isDisposed) {
//           _showError('تعذر البحث عن الموقع المطلوب');
//         }
//       } finally {
//         if (!_isDisposed) {
//           isSearching.value = false;
//         }
//       }
//     });
//   }

//   /// Select location from search - with disposal check
//   void selectLocationFromSearch(LocationSearchResult result) {
//     if (_isDisposed) return;
    
//     selectedLocation.value = result.latLng;
//     selectedAddress.value = result.address;

//     moveToLocation(result.latLng);
//     _addLocationMarker(result.latLng, 'selected', result.name, showLabel: true);
//     searchResults.clear();

//     try {
//       searchController.text = result.name;
//     } catch (e) {
//       logger.w('تم تجاهل خطأ في تعيين searchController: $e');
//     }
//   }

//   /// Remove additional stop by ID - with disposal check
//   void removeAdditionalStop(String stopId) {
//     if (_isDisposed) return;
    
//     additionalStops.removeWhere((stop) => stop.id == stopId);
//     markers.removeWhere((marker) => marker.key == Key('additional_stop_$stopId'));

//     _renumberAdditionalStops();
//     _updateRouteIfNeeded();

//     _showSuccessSnackbar('تم حذف المحطة', 'تم حذف المحطة الوسطية بنجاح');
//   }

//   /// Renumber additional stops after removal
//   void _renumberAdditionalStops() {
//     if (_isDisposed) return;
    
//     for (int i = 0; i < additionalStops.length; i++) {
//       final stop = additionalStops[i];
//       final newNumber = i + 1;

//       additionalStops[i] = AdditionalStop(
//         id: stop.id,
//         location: stop.location,
//         address: stop.address,
//         stopNumber: newNumber,
//       );

//       markers.removeWhere(
//           (marker) => marker.key == Key('additional_stop_${stop.id}'));
//       addAdditionalStopMarker(stop.location, stop.address, newNumber, stop.id);
//     }
//   }

//   /// Set middle stop from map - with disposal check
//   void setMiddleStopFromMap(LatLng latLng, {String? title}) {
//     if (_isDisposed || additionalStops.length >= maxAdditionalStops.value) {
//       if (!_isDisposed && additionalStops.length >= maxAdditionalStops.value) {
//         _showError('لا يمكن إضافة أكثر من ${maxAdditionalStops.value} نقاط وسطية');
//       }
//       return;
//     }

//     bool isDuplicate = additionalStops.any((stop) =>
//         (stop.location.latitude - latLng.latitude).abs() < 0.0001 &&
//         (stop.location.longitude - latLng.longitude).abs() < 0.0001);

//     if (isDuplicate) {
//       _showError('هذه المحطة موجودة بالفعل');
//       return;
//     }

//     final int stopNumber = additionalStops.length + 1;
//     final String stopId = 'stop_${DateTime.now().millisecondsSinceEpoch}';
//     final String address = title ?? 'محطة وسطى $stopNumber';

//     final AdditionalStop newStop = AdditionalStop(
//       id: stopId,
//       location: latLng,
//       address: address,
//       stopNumber: stopNumber,
//     );

//     additionalStops.add(newStop);
//     addAdditionalStopMarker(latLng, address, stopNumber, stopId);
//     _updateRouteIfNeeded();

//     _showSuccessSnackbar('تم إضافة المحطة $stopNumber', address);
//   }

//   /// Update route if needed - with disposal check
//   void _updateRouteIfNeeded() {
//     if (_isDisposed || _isUpdatingRoute) return;
    
//     if (currentLocation.value != null && selectedLocation.value != null) {
//       _updateRouteToSelectedLocation(selectedLocation.value!);
//     }
//   }

//   /// Update route to selected location with stream - with disposal checks
//   void _updateRouteToSelectedLocation(LatLng destination) {
//     final LatLng? from = currentLocation.value;
//     if (_isDisposed || from == null || _isUpdatingRoute) return;

//     _isUpdatingRoute = true;
//     _routeDrawingSubscription?.cancel();
//     isLoading.value = true;

//     _routeDrawingSubscription = _getRouteStream(from, destination).listen(
//       (routePoints) {
//         if (_isDisposed) return;
        
//         if (routePoints.isNotEmpty) {
//           drawTripRoute(routePoints);
//         }
//         isLoading.value = false;
//         _isUpdatingRoute = false;
//       },
//       onError: (error) {
//         logger.w('خطأ في رسم المسار: $error');
//         if (!_isDisposed) {
//           isLoading.value = false;
//           _isUpdatingRoute = false;
//         }
//       },
//     );
//   }

//   /// Select location from map directly - with disposal check
//   Future<void> selectLocationFromMap(LatLng point) async {
//     if (_isDisposed) return;
    
//     try {
//       if (currentLocation.value == null) {
//         final loc = await _locationService.getCurrentLocation();
//         if (_isDisposed) return;
        
//         if (loc != null) {
//           currentLocation.value = loc;
//         }
//       }

//       selectedLocation.value = point;
//       moveToLocation(point);
//       _addLocationMarker(point, 'selected', 'الوجهة', showLabel: true);

//       final String address = await _locationService.getAddressFromLocation(point);
//       if (_isDisposed) return;
      
//       selectedAddress.value = address;

//       try {
//         searchController.text = address;
//       } catch (_) {}

//       _updateRouteIfNeeded();
//     } catch (e) {
//       logger.w('خطأ في اختيار موقع من الخريطة: $e');
//     }
//   }

//   /// Create a stream for route fetching - with disposal checks
//   Stream<List<LatLng>> _getRouteStream(LatLng from, LatLng destination) async* {
//     if (_isDisposed) return;
    
//     try {
//       List<LatLng> route;

//       if (additionalStops.isNotEmpty) {
//         final sortedStops = List<AdditionalStop>.from(additionalStops)
//           ..sort((a, b) => a.stopNumber.compareTo(b.stopNumber));

//         route = await _locationService.getRouteWithMultipleWaypoints(from,
//             sortedStops.map((stop) => stop.location).toList(), destination);
//       } else {
//         route = await _locationService.getRoute(from, destination);
//       }

//       if (!_isDisposed) {
//         yield route;
//       }
//     } catch (e) {
//       logger.w('خطأ في الحصول على المسار: $e');
//       if (!_isDisposed) {
//         yield [from, destination];
//       }
//     }
//   }

//   /// Update current location marker - with disposal check
//   void _updateCurrentLocationMarker(LatLng location) {
//     if (_isDisposed) return;
    
//     markers.removeWhere((marker) => marker.key == const Key('current_location'));

//     markers.add(
//       Marker(
//         key: const Key('current_location'),
//         point: location,
//         width: 40.0,
//         height: 40.0,
//         child: Container(
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.blue,
//             border: Border.all(color: Colors.white, width: 3),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.3),
//                 blurRadius: 6,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: const Icon(
//             Icons.my_location,
//             color: Colors.white,
//             size: 20,
//           ),
//         ),
//       ),
//     );
//   }

//   /// Add additional stop marker with number and unique ID - with disposal check
//   void addAdditionalStopMarker(
//       LatLng location, String title, int stopNumber, String stopId) {
//     if (_isDisposed) return;
    
//     markers.removeWhere((marker) => marker.key == Key('additional_stop_$stopId'));

//     markers.add(
//       Marker(
//         key: Key('additional_stop_$stopId'),
//         point: location,
//         width: 45,
//         height: 55,
//         child: EnhancedPinWidget(
//           color: Colors.orange,
//           label: 'محطة $stopNumber',
//           showLabel: true,
//           size: 35,
//           zoomLevel: mapZoom.value,
//         ),
//       ),
//     );
//   }

//   /// Add selected location marker (legacy support)
//   void addSelectedLocationMarker(LatLng location, String title) {
//     _addLocationMarker(location, 'selected', title, showLabel: true);
//   }

//   /// Add driver marker - with disposal check
//   void addDriverMarker(LatLng location, DriverModel driver) {
//     if (_isDisposed) return;
    
//     markers.removeWhere((marker) => marker.key == Key('driver_${driver.id}'));

//     markers.add(
//       Marker(
//         key: Key('driver_${driver.id}'),
//         point: location,
//         width: 60.0,
//         height: 60.0,
//         child: Container(
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.green,
//             border: Border.all(color: Colors.white, width: 3),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.3),
//                 blurRadius: 6,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: driver.profileImage != null
//               ? ClipOval(
//                   child: Image.network(
//                     driver.profileImage!,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) {
//                       return const Icon(Icons.person,
//                           color: Colors.white, size: 30);
//                     },
//                   ),
//                 )
//               : const Icon(Icons.directions_car, color: Colors.white, size: 30),
//         ),
//       ),
//     );
//   }

//   /// Draw trip route - with disposal check
//   void drawTripRoute(List<LatLng> routePoints, {List<int>? splitIndices}) {
//     if (_isDisposed || routePoints.isEmpty) return;

//     polylines.clear();

//     if (splitIndices != null && splitIndices.isNotEmpty) {
//       final indices = [
//         0,
//         ...splitIndices.where((i) => i > 0 && i < routePoints.length),
//         routePoints.length - 1
//       ];
//       for (int i = 0; i < indices.length - 1; i++) {
//         final start = indices[i];
//         final end = indices[i + 1];
//         if (end - start < 1) continue;
//         final color = i == 0 ? Colors.green : Colors.red;
//         polylines.add(Polyline(
//             points: routePoints.sublist(start, end + 1),
//             color: color,
//             strokeWidth: 4.0));
//       }
//     } else {
//       polylines.add(
//           Polyline(points: routePoints, color: Colors.blue, strokeWidth: 4.0));
//     }

//     _fitBoundsToRoute(routePoints);
//   }

//   /// Fit map bounds to route - with disposal check
//   void _fitBoundsToRoute(List<LatLng> points) {
//     if (_isDisposed || points.isEmpty) return;

//     double minLat = points.first.latitude;
//     double maxLat = points.first.latitude;
//     double minLng = points.first.longitude;
//     double maxLng = points.first.longitude;

//     for (LatLng point in points) {
//       minLat = math.min(minLat, point.latitude);
//       maxLat = math.max(maxLat, point.latitude);
//       minLng = math.min(minLng, point.longitude);
//       maxLng = math.max(maxLng, point.longitude);
//     }

//     double latPadding = (maxLat - minLat) * 0.1;
//     double lngPadding = (maxLng - minLng) * 0.1;

//     LatLngBounds bounds = LatLngBounds(
//       LatLng(minLat - latPadding, minLng - lngPadding),
//       LatLng(maxLat + latPadding, maxLng + lngPadding),
//     );

//     try {
//       mapController.fitCamera(CameraFit.bounds(bounds: bounds));
//     } catch (e) {
//       logger.f('خطأ في تعديل حدود الخريطة: $e');
//     }
//   }

//   /// Start trip tracking - with disposal check
//   void startTripTracking(TripModel trip) {
//     if (_isDisposed) return;
    
//     activeTrip.value = trip;

//     if (trip.routePolyline != null) {
//       drawTripRoute(trip.routePolyline!);
//     }

//     _addTripMarkers(trip);
//   }

//   /// Add trip markers - with disposal check
//   void _addTripMarkers(TripModel trip) {
//     if (_isDisposed) return;
    
//     markers.add(
//       Marker(
//         key: const Key('pickup_location'),
//         point: trip.pickupLocation.latLng,
//         width: 45.0,
//         height: 55.0,
//         child: EnhancedPinWidget(
//           color: Colors.green,
//           label: 'الانطلاق',
//           showLabel: true,
//           size: 35,
//           zoomLevel: mapZoom.value,
//         ),
//       ),
//     );

//     markers.add(
//       Marker(
//         key: const Key('destination_location'),
//         point: trip.destinationLocation.latLng,
//         width: 45.0,
//         height: 55.0,
//         child: EnhancedPinWidget(
//           color: Colors.red,
//           label: 'الوصول',
//           showLabel: true,
//           size: 35,
//           zoomLevel: mapZoom.value,
//         ),
//       ),
//     );
//   }

//   /// Update driver location - with disposal check
//   void updateDriverLocation(LatLng location) {
//     if (_isDisposed) return;
//     driverLocation.value = location;
//   }

//   /// FIXED: Clear map with proper disposal checks
//   void clearMap() {
//     if (_isDisposed) return;
    
//     // Cancel timers first
//     _mapMovementTimer?.cancel();
//     _searchDebounceTimer?.cancel();
//     _routeDrawingSubscription?.cancel();

//     // Clear observables
//     markers.clear();
//     polylines.clear();
//     circles.clear();
//     selectedLocation.value = null;
//     selectedAddress.value = '';
//     activeTrip.value = null;
//     driverLocation.value = null;
//     isPickupConfirmed.value = false;
//     isDestinationConfirmed.value = false;
//     currentStep.value = 'none';
//     additionalStops.clear();
//     searchResults.clear();

//     // Clear search controller safely
//     try {
//       searchController.clear();
//     } catch (e) {
//       logger.w('تم تجاهل خطأ في مسح searchController: $e');
//     }
//   }

//   /// Clear search - with disposal check
//   void clearSearch() {
//     if (_isDisposed) return;
    
//     try {
//       searchController.clear();
//     } catch (e) {
//       logger.w('تم تجاهل خطأ في مسح searchController في clearSearch: $e');
//     }
//     searchResults.clear();
//     selectedLocation.value = null;
//     selectedAddress.value = '';
//     polylines.clear();
//     markers.removeWhere((marker) => marker.key == const Key('selected_location'));
//   }

//   /// Refresh current location - with disposal check
//   Future<void> refreshCurrentLocation() async {
//     if (_isDisposed) return;
    
//     isLoading.value = true;

//     try {
//       LatLng? location = await _locationService.getCurrentLocation();
//       if (_isDisposed) return;
      
//       if (location != null) {
//         currentLocation.value = location;
//         currentAddress.value = _locationService.currentAddress.value;
//         moveToLocation(location);
//       }
//     } catch (e) {
//       logger.f('خطأ في تحديث الموقع: $e');
//       if (!_isDisposed) {
//         _showError('تعذر تحديث الموقع الحالي');
//       }
//     } finally {
//       if (!_isDisposed) {
//         isLoading.value = false;
//       }
//     }
//   }

//   // Additional options functionality
//   final RxBool showAdditionalOptions = false.obs;

//   /// Toggle additional options visibility - with disposal check
//   void toggleAdditionalOptions() {
//     if (_isDisposed) return;
//     showAdditionalOptions.value = !showAdditionalOptions.value;
//   }

//   /// Add additional stop - with disposal check
//   void addAdditionalStop(LatLng location, String address) {
//     if (_isDisposed) return;
//     setMiddleStopFromMap(location, title: address);
//   }

//   /// Reset map to initial state - with disposal check
//   void resetMap() {
//     if (_isDisposed) return;
    
//     clearMap();
//     if (currentLocation.value != null) {
//       moveToLocation(currentLocation.value!);
//     }
//   }

//   /// Helper methods for cleaner code
//   void _showSuccessSnackbar(String title, String message) {
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

//   @override
//   void onClose() {
//     // Set disposal flag first
//     _isDisposed = true;

//     // Cancel all timers and subscriptions
//     _routeDrawingSubscription?.cancel();
//     _searchDebounceTimer?.cancel();
//     _mapMovementTimer?.cancel();

//     // Dispose text controller
//     try {
//       searchController.dispose();
//     } catch (e) {
//       logger.w('خطأ في dispose searchController: $e');
//     }

//     super.onClose();
//   }
// }

// /// Additional Stop Model
// class AdditionalStop {
//   final String id;
//   final LatLng location;
//   final String address;
//   final int stopNumber;

//   AdditionalStop({
//     required this.id,
//     required this.location,
//     required this.address,
//     required this.stopNumber,
//   });

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is AdditionalStop &&
//           runtimeType == other.runtimeType &&
//           id == other.id;

//   @override
//   int get hashCode => id.hashCode;
// }

