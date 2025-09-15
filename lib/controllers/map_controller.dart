import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/services/location_service.dart';

class MapControllerr extends GetxController {
  static MapControllerr get to => Get.find();

  // Map controller
  final MapController mapController = MapController();

  // Enhanced Pin properties with modern design
  final RxBool isMapMoving = false.obs;
  final RxBool showConfirmButton = false.obs;
  final Rx<LatLng?> centerPinLocation = Rx<LatLng?>(null);
  final RxString currentStep = 'none'.obs;
  Timer? _mapMovementTimer;

  // Map state with better defaults
  final Rx<LatLng> mapCenter =
      const LatLng(33.3152, 44.3661).obs; // Baghdad coordinates
  final RxDouble mapZoom = 13.0.obs;
  final RxBool isMapReady = false.obs;

  // Enhanced markers and overlays
  final RxList<Marker> markers = <Marker>[].obs;
  final RxList<Polyline> polylines = <Polyline>[].obs;
  final RxList<CircleMarker> circles = <CircleMarker>[].obs;

  // Current location management
  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  final RxString currentAddress = ''.obs;

  // Advanced search and location selection
  final RxList<LocationSearchResult> searchResults =
      <LocationSearchResult>[].obs;
  final Rx<LatLng?> selectedLocation = Rx<LatLng?>(null);
  final RxString selectedAddress = ''.obs;
  final RxBool isSearching = false.obs;

  // Enhanced additional stops management
  final RxList<AdditionalStop> additionalStops = <AdditionalStop>[].obs;
  final RxInt maxAdditionalStops = 2.obs; // Increased from 2 to 3

  // Trip tracking with enhanced features
  final Rx<TripModel?> activeTrip = Rx<TripModel?>(null);
  final RxList<LatLng> tripRoute = <LatLng>[].obs;
  final Rx<LatLng?> driverLocation = Rx<LatLng?>(null);

  // Enhanced UI state management
  final RxBool isLoading = false.obs;
  final TextEditingController searchController = TextEditingController();

  // Services
  final LocationService _locationService = LocationService.to;

  // Enhanced route drawing with better performance
  StreamSubscription<List<LatLng>>? _routeDrawingSubscription;
  Timer? _searchDebounceTimer;

  // Performance optimizations
  bool _isUpdatingRoute = false;
  DateTime? _lastRouteUpdate;
  static const int _routeUpdateCooldown =
      800; // Reduced for better responsiveness

  // Enhanced location confirmation states
  final RxBool isPickupConfirmed = false.obs;
  final RxBool isDestinationConfirmed = false.obs;

  // Disposal management
  bool _isDisposed = false;

  @override
  void onInit() {
    super.onInit();
    _initializeMap();
    _setupEnhancedListeners();
  }

  void _setupEnhancedListeners() {
    // Enhanced current location listener
    ever(currentLocation, _onCurrentLocationChanged,
        condition: () => !_isUpdatingRoute && !_isDisposed);

    // Enhanced map center listener with better debouncing
    ever(mapCenter, (LatLng center) {
      if (!_isDisposed) {
        centerPinLocation.value = center;
        _onMapMovement();
      }
    });

    // Enhanced selected location listener
    ever(selectedLocation, _onSelectedLocationChanged,
        condition: () => !_isUpdatingRoute && !_isDisposed);

    // Enhanced additional stops listener
    ever(additionalStops, (List<AdditionalStop> stops) {
      if (!_isDisposed) {
        _updateRouteIfNeededDebounced();
        _updateStopsMarkers();
      }
    });

    // Enhanced confirmation states listener
    ever(isPickupConfirmed, (bool pickupConfirmed) {
      if (pickupConfirmed && isDestinationConfirmed.value) {
        _updateRouteIfNeededDebounced();
      }
    });

    ever(isDestinationConfirmed, (bool destinationConfirmed) {
      if (destinationConfirmed && isPickupConfirmed.value) {
        _updateRouteIfNeededDebounced();
      }
    });
  }

  // Additional options functionality
  final RxBool showAdditionalOptions = false.obs;

  /// Toggle additional options visibility - with disposal check
  void toggleAdditionalOptions() {
    if (_isDisposed) return;
    showAdditionalOptions.value = !showAdditionalOptions.value;
  }

  /// Select location from map directly - with disposal check
  Future<void> selectLocationFromMap(LatLng point) async {
    if (_isDisposed) return;

    try {
      if (currentLocation.value == null) {
        final loc = await _locationService.getCurrentLocation();
        if (_isDisposed) return;

        if (loc != null) {
          currentLocation.value = loc;
        }
      }

      selectedLocation.value = point;
      moveToLocation(point);
      _addLocationMarker(point, 'selected', 'الوجهة', showLabel: true);

      final String address =
          await _locationService.getAddressFromLocation(point);
      if (_isDisposed) return;

      selectedAddress.value = address;

      try {
        searchController.text = address;
      } catch (_) {}

      _updateRouteIfNeeded();
    } catch (e) {
      logger.w('خطأ في اختيار موقع من الخريطة: $e');
    }
  }

  /// Get color for step
  Color _getColorForStep(String step) {
    switch (step) {
      case 'pickup':
        return Colors.green;
      case 'destination':
        return Colors.red;
      case 'additional_stop':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  /// Get label for step
  String _getLabelForStep(String step) {
    switch (step) {
      case 'pickup':
        return 'الانطلاق';
      case 'destination':
        return 'الوصول';
      case 'additional_stop':
        return 'المحطة';
      default:
        return 'الموقع';
    }
  }

  /// Add location marker with enhanced styling - with disposal check
  void _addLocationMarker(LatLng location, String type, String address,
      {bool showLabel = false}) {
    if (_isDisposed) return;

    markers.removeWhere((marker) => marker.key == Key(type));

    Color pinColor = _getColorForStep(type);
    String label = _getLabelForStep(type);

    markers.add(
      Marker(
        key: Key(type),
        point: location,
        width: 45.0,
        height: 55.0,
        child: EnhancedPinWidget(
          color: pinColor,
          label: label,
          showLabel: showLabel,
          size: 35,
          zoomLevel: mapZoom.value,
        ),
      ),
    );
  }

  /// Reset map to initial state - with disposal check
  void resetMap() {
    if (_isDisposed) return;

    clearMap();
    if (currentLocation.value != null) {
      moveToLocation(currentLocation.value!);
    }
  }

  void _onCurrentLocationChanged(LatLng? location) {
    if (_isDisposed || location == null) return;

    _updateCurrentLocationMarker(location);
    _updateRouteIfNeededDebounced();
  }

  void _onSelectedLocationChanged(LatLng? location) {
    if (_isDisposed || location == null || currentLocation.value == null)
      return;

    _updateRouteIfNeededDebounced();
  }

  // void _onConfirmationStateChanged(List<dynamic> states) {
  //   if (_isDisposed) return;

  //   final bool pickup = states[0] as bool;
  //   final bool destination = states[1] as bool;

  //   if (pickup && destination) {
  //     _updateRouteIfNeededDebounced();
  //   }
  // }

  void _updateRouteIfNeededDebounced() {
    if (_isDisposed) return;

    final now = DateTime.now();
    if (_lastRouteUpdate != null &&
        now.difference(_lastRouteUpdate!).inMilliseconds <
            _routeUpdateCooldown) {
      return;
    }
    _lastRouteUpdate = now;
    _updateRouteIfNeeded();
  }

  /// Enhanced map initialization with better error handling
  Future<void> _initializeMap() async {
    if (_isDisposed) return;

    isLoading.value = true;

    try {
      LatLng? location = await _locationService.getCurrentLocation();
      if (_isDisposed) return;

      if (location != null) {
        currentLocation.value = location;
        mapCenter.value = location;
        currentAddress.value = _locationService.currentAddress.value;
        moveToLocation(location);
        isMapReady.value = true;

        // Auto-start pickup selection
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed &&
              currentLocation.value != null &&
              currentStep.value == 'none') {
            startLocationSelection('pickup');
          }
        });
      } else {
        logger.w("تعذر الحصول على الموقع الحالي");
        if (!_isDisposed) {
          _showError("الموقع غير متاح حالياً");
        }
      }

      if (!_isDisposed) {
        isMapReady.value = true;
      }
    } catch (e) {
      logger.f('خطأ في تهيئة الخريطة: $e');
      if (!_isDisposed) {
        _showError('تعذر تحميل الخريطة');
      }
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  /// Enhanced map movement with smooth transitions
  void moveToLocation(LatLng location, {double zoom = 16.0}) {
    if (_isDisposed) return;

    mapCenter.value = location;
    mapZoom.value = zoom;

    try {
      mapController.move(location, zoom);
    } catch (e) {
      logger.w('تم تجاهل خطأ في تحريك الخريطة: $e');
    }
  }

  /// Enhanced location selection with better flow
  void startLocationSelection(String step) {
    if (_isDisposed) return;

    currentStep.value = step;
    showConfirmButton.value = false;
    // Collapse any bottom sheets via UI listener

    // Smart positioning based on step type
    switch (step) {
      case 'pickup':
        if (currentLocation.value != null) {
          moveToLocation(currentLocation.value!);
        }
        break;
      case 'destination':
        if (isPickupConfirmed.value && currentLocation.value != null) {
          // Move slightly away from pickup for better UX
          final pickup = currentLocation.value!;
          final offset = LatLng(
            pickup.latitude + 0.01,
            pickup.longitude + 0.01,
          );
          moveToLocation(offset);
        }
        break;
      case 'additional_stop':
        if (currentLocation.value != null && selectedLocation.value != null) {
          // Position between pickup and destination
          final pickup = currentLocation.value!;
          final dest = selectedLocation.value!;
          final midpoint = LatLng(
            (pickup.latitude + dest.latitude) / 2,
            (pickup.longitude + dest.longitude) / 2,
          );
          moveToLocation(midpoint);
        }
        break;
    }
  }

  /// Enhanced pin location confirmation with better UX
  Future<void> confirmPinLocation() async {
    if (_isDisposed ||
        centerPinLocation.value == null ||
        currentStep.value == 'none') {
      return;
    }

    try {
      isLoading.value = true;
      showConfirmButton.value = false;

      final LatLng pinLocation = centerPinLocation.value!;
      final String address =
          await _locationService.getAddressFromLocation(pinLocation);

      if (_isDisposed) return;

      switch (currentStep.value) {
        case 'pickup':
          await _confirmPickupLocation(pinLocation, address);
          break;
        case 'destination':
          await _confirmDestinationLocation(pinLocation, address);
          break;
        case 'additional_stop':
          await _confirmAdditionalStop(pinLocation, address);
          break;
      }
    } catch (e) {
      logger.w('خطأ في تأكيد موقع الـ Pin: $e');
      if (!_isDisposed) {
        _showError('تعذر تحديد الموقع المطلوب');
      }
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  /// Enhanced pickup confirmation with modern styling
  Future<void> _confirmPickupLocation(LatLng location, String address) async {
    if (_isDisposed) return;

    currentLocation.value = location;
    currentAddress.value = address;
    isPickupConfirmed.value = true;

    _addEnhancedLocationMarker(location, 'pickup', address, showLabel: true);
    currentStep.value = 'destination'; // Auto-transition to destination

    await Future.delayed(const Duration(milliseconds: 500));

    if (!_isDisposed) {
      _showSuccessSnackbar('تم تثبيت نقطة الانطلاق', 'يمكنك الآن تحديد الوصول');

      try {
        searchController.text = address;
      } catch (_) {}
    }
  }

  /// Enhanced destination confirmation
  Future<void> _confirmDestinationLocation(
      LatLng location, String address) async {
    if (_isDisposed) return;

    selectedLocation.value = location;
    selectedAddress.value = address;
    isDestinationConfirmed.value = true;

    _addEnhancedLocationMarker(location, 'destination', address,
        showLabel: true);
    currentStep.value = 'none';

    _updateRouteIfNeeded();

    if (!_isDisposed) {
      _showSuccessSnackbar('تم تثبيت نقطة الوصول', address);

      try {
        searchController.text = address;
      } catch (_) {}
    }
  }

  /// Enhanced additional stop confirmation
  Future<void> _confirmAdditionalStop(LatLng location, String address) async {
    if (_isDisposed || additionalStops.length >= maxAdditionalStops.value) {
      if (!_isDisposed && additionalStops.length >= maxAdditionalStops.value) {
        _showError(
            'لا يمكن إضافة أكثر من ${maxAdditionalStops.value} نقاط وسطية');
      }
      return;
    }

    final int stopNumber = additionalStops.length + 1;
    final String stopId = 'stop_${DateTime.now().millisecondsSinceEpoch}';

    final AdditionalStop newStop = AdditionalStop(
      id: stopId,
      location: location,
      address: address,
      stopNumber: stopNumber,
    );

    additionalStops.add(newStop);
    _addEnhancedAdditionalStopMarker(location, address, stopNumber, stopId);
    currentStep.value = 'none';

    if (!_isDisposed) {
      _showSuccessSnackbar('تم إضافة المحطة الوسطية $stopNumber', address);
    }
  }

  /// Enhanced location marker with modern styling
  void _addEnhancedLocationMarker(LatLng location, String type, String address,
      {bool showLabel = false}) {
    if (_isDisposed) return;

    markers.removeWhere((marker) => marker.key == Key(type));

    Color pinColor = PinColors.getColorForStep(type);
    if (type == 'pickup') {
      pinColor = Colors.black; // pickup should be black
    }
    String label = PinColors.getLabelForStep(type);

    markers.add(
      Marker(
        key: Key(type),
        point: location,
        width: 45.0,
        height: 55.0,
        child: EnhancedPinWidget(
          color: pinColor,
          label: label,
          showLabel: true, // show labels only after confirmation
          size: 30,
          zoomLevel: mapZoom.value,
        ),
      ),
    );
  }

  /// Enhanced additional stop marker
  void _addEnhancedAdditionalStopMarker(
      LatLng location, String address, int stopNumber, String stopId) {
    if (_isDisposed) return;

    markers
        .removeWhere((marker) => marker.key == Key('additional_stop_$stopId'));

    markers.add(
      Marker(
        key: Key('additional_stop_$stopId'),
        point: location,
        width: 42,
        height: 55,
        child: NumberedPinWidget(
          color: PinColors.additionalStop,
          label: 'وصول $stopNumber',
          number: stopNumber,
          showLabel: true,
          size: 28,
          zoomLevel: mapZoom.value,
        ),
      ),
    );
  }

  /// Enhanced stops markers update
  void _updateStopsMarkers() {
    if (_isDisposed) return;

    // Remove old additional stop markers
    markers.removeWhere(
        (marker) => marker.key.toString().contains('additional_stop_'));

    // Re-add with correct numbering
    for (int i = 0; i < additionalStops.length; i++) {
      final stop = additionalStops[i];
      _addEnhancedAdditionalStopMarker(
          stop.location, stop.address, i + 1, stop.id);
    }
  }

  /// Enhanced remove additional stop with better UX
  void removeAdditionalStop(String stopId) {
    if (_isDisposed) return;

    additionalStops.removeWhere((stop) => stop.id == stopId);
    markers
        .removeWhere((marker) => marker.key == Key('additional_stop_$stopId'));

    _renumberAdditionalStops();
    _updateRouteIfNeeded();

    _showSuccessSnackbar('تم حذف المحطة', 'تم حذف المحطة الوسطية بنجاح');
  }

  /// Enhanced renumbering with better performance
  void _renumberAdditionalStops() {
    if (_isDisposed) return;

    for (int i = 0; i < additionalStops.length; i++) {
      final stop = additionalStops[i];
      final newNumber = i + 1;

      if (stop.stopNumber != newNumber) {
        additionalStops[i] = AdditionalStop(
          id: stop.id,
          location: stop.location,
          address: stop.address,
          stopNumber: newNumber,
        );
      }
    }

    _updateStopsMarkers();
  }

  /// Enhanced current location marker with modern design
  void _updateCurrentLocationMarker(LatLng location) {
    if (_isDisposed) return;

    markers
        .removeWhere((marker) => marker.key == const Key('current_location'));

    markers.add(
      Marker(
        key: const Key('current_location'),
        point: location,
        width: 44.0,
        height: 44.0,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                PinColors.current.withOpacity(0.8),
                PinColors.current,
              ],
            ),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: PinColors.current.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.my_location,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  /// Enhanced route updating with better performance
  void _updateRouteIfNeeded() {
    if (_isDisposed || _isUpdatingRoute) return;

    // Only draw route when both pickup and destination are confirmed
    if (isPickupConfirmed.value && isDestinationConfirmed.value) {
      if (currentLocation.value != null && selectedLocation.value != null) {
        _updateRouteToSelectedLocation(selectedLocation.value!);
      }
    } else {
      polylines.clear();
    }
  }

  /// Enhanced route drawing with multiple waypoints support
  void _updateRouteToSelectedLocation(LatLng destination) {
    final LatLng? from = currentLocation.value;
    if (_isDisposed || from == null || _isUpdatingRoute) return;

    _isUpdatingRoute = true;
    _routeDrawingSubscription?.cancel();
    isLoading.value = true;

    _routeDrawingSubscription =
        _getEnhancedRouteStream(from, destination).listen(
      (routePoints) {
        if (_isDisposed) return;

        if (routePoints.isNotEmpty) {
          _drawEnhancedTripRoute(routePoints);
        }
        isLoading.value = false;
        _isUpdatingRoute = false;
      },
      onError: (error) {
        logger.w('خطأ في رسم المسار: $error');
        if (!_isDisposed) {
          isLoading.value = false;
          _isUpdatingRoute = false;
        }
      },
    );
  }

  /// Enhanced route stream with better waypoint handling
  Stream<List<LatLng>> _getEnhancedRouteStream(
      LatLng from, LatLng destination) async* {
    if (_isDisposed) return;

    try {
      List<LatLng> route;

      if (additionalStops.isNotEmpty) {
        // Sort stops by their intended sequence
        final sortedStops = List<AdditionalStop>.from(additionalStops)
          ..sort((a, b) => a.stopNumber.compareTo(b.stopNumber));

        route = await _locationService.getRouteWithMultipleWaypoints(
          from,
          sortedStops.map((stop) => stop.location).toList(),
          destination,
        );
      } else {
        route = await _locationService.getRoute(from, destination);
      }

      if (!_isDisposed) {
        yield route;
      }
    } catch (e) {
      logger.w('خطأ في الحصول على المسار: $e');
      if (!_isDisposed) {
        // Fallback to straight line
        yield [from, destination];
      }
    }
  }

  /// Enhanced route drawing with color coding
  void _drawEnhancedTripRoute(List<LatLng> routePoints,
      {List<int>? splitIndices}) {
    if (_isDisposed || routePoints.isEmpty) return;

    polylines.clear();

    if (splitIndices != null && splitIndices.isNotEmpty) {
      // Multi-segment route with different colors
      final indices = [
        0,
        ...splitIndices.where((i) => i > 0 && i < routePoints.length),
        routePoints.length - 1
      ];

      for (int i = 0; i < indices.length - 1; i++) {
        final start = indices[i];
        final end = indices[i + 1];
        if (end - start < 1) continue;

        Color segmentColor;
        if (i == 0) {
          segmentColor = PinColors.pickup; // Green for first segment
        } else if (i == indices.length - 2) {
          segmentColor = PinColors.destination; // Red for last segment
        } else {
          segmentColor = PinColors.additionalStop; // Orange for middle segments
        }

        polylines.add(Polyline(
          points: routePoints.sublist(start, end + 1),
          color: segmentColor,
          strokeWidth: 5.0,
          borderStrokeWidth: 8.0,
          borderColor: segmentColor.withOpacity(0.3),
        ));
      }
    } else {
      // Single route
      polylines.add(
        Polyline(
          points: routePoints,
          color: PinColors.current,
          strokeWidth: 5.0,
          borderStrokeWidth: 8.0,
          borderColor: PinColors.current.withOpacity(0.3),
        ),
      );
    }

    _fitBoundsToRoute(routePoints);
  }

  /// Draw trip route (public method)
  void drawTripRoute(List<LatLng> routePoints) {
    if (_isDisposed || routePoints.isEmpty) return;

    tripRoute.assignAll(routePoints);
    _drawEnhancedTripRoute(routePoints);
  }

  /// Update driver location
  void updateDriverLocation(LatLng location) {
    if (_isDisposed) return;

    driverLocation.value = location;

    // Update driver marker if exists
    markers.removeWhere((marker) => marker.key.toString().contains('driver_'));

    markers.add(
      Marker(
        key: const Key('driver_current'),
        point: location,
        width: 60.0,
        height: 60.0,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: PinColors.driver,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: PinColors.driver.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_car,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  /// Setup map when ready
  void onMapReady() {
    if (_isDisposed) return;

    isMapReady.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && currentLocation.value != null) {
        moveToLocation(currentLocation.value!);
      }
    });
  }

  /// Enhanced bounds fitting with better padding
  void _fitBoundsToRoute(List<LatLng> points) {
    if (_isDisposed || points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    // Enhanced padding calculation
    double latPadding = (maxLat - minLat) * 0.15; // Increased padding
    double lngPadding = (maxLng - minLng) * 0.15;

    // Minimum padding to ensure visibility
    latPadding = math.max(latPadding, 0.005);
    lngPadding = math.max(lngPadding, 0.005);

    LatLngBounds bounds = LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    try {
      mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    } catch (e) {
      logger.f('خطأ في تعديل حدود الخريطة: $e');
    }
  }

  /// Enhanced search with better performance
  Future<void> searchLocation(String query) async {
    if (_isDisposed || query.trim().isEmpty) {
      if (!_isDisposed) {
        searchResults.clear();
      }
      return;
    }

    _searchDebounceTimer?.cancel();
    isSearching.value = true;

    _searchDebounceTimer = Timer(const Duration(milliseconds: 400), () async {
      if (_isDisposed) return;

      try {
        List<LocationSearchResult> results =
            await _locationService.searchLocationAdvanced(query);

        if (_isDisposed) return;

        if (currentLocation.value != null) {
          // Enhanced sorting by distance and relevance
          results.sort((a, b) {
            double distanceA = _locationService.calculateDistance(
              currentLocation.value!,
              a.latLng,
            );
            double distanceB = _locationService.calculateDistance(
              currentLocation.value!,
              b.latLng,
            );
            return distanceA.compareTo(distanceB);
          });
        }

        if (!_isDisposed) {
          searchResults.assignAll(results.take(8).toList()); // Limit results
        }
      } catch (e) {
        logger.f('خطأ في البحث: $e');
        if (!_isDisposed) {
          _showError('تعذر البحث عن الموقع المطلوب');
        }
      } finally {
        if (!_isDisposed) {
          isSearching.value = false;
        }
      }
    });
  }

  /// Enhanced location selection from search
  void selectLocationFromSearch(LocationSearchResult result) {
    if (_isDisposed) return;

    selectedLocation.value = result.latLng;
    selectedAddress.value = result.address;

    moveToLocation(result.latLng);
    _addEnhancedLocationMarker(result.latLng, 'selected', result.name,
        showLabel: true);
    searchResults.clear();

    try {
      searchController.text = result.name;
    } catch (e) {
      logger.w('تم تجاهل خطأ في تعيين searchController: $e');
    }
  }

// Add this property after other observables
  final RxString currentPinAddress = ''.obs;

  /// Update the _onMapMovement method to include real-time address updates
  void _onMapMovement() {
    if (_isDisposed) return;

    isMapMoving.value = true;
    showConfirmButton.value = false;

    // Clear current address while moving
    currentPinAddress.value = '';

    _mapMovementTimer?.cancel();

    _mapMovementTimer = Timer(const Duration(milliseconds: 600), () async {
      if (_isDisposed) return;

      isMapMoving.value = false;
      if (currentStep.value != 'none') {
        showConfirmButton.value = true;

        // Update pin location address in real-time
        try {
          final address = await getCurrentPinLocationAddress();
          if (!_isDisposed) {
            currentPinAddress.value = address;
          }
        } catch (e) {
          logger.w('خطأ في تحديث عنوان الموقع: $e');
          if (!_isDisposed) {
            currentPinAddress.value = 'موقعك الحالي على الخريطة';
          }
        }
      }
    });
  }

  /// Get current pin location address for display
  Future<String> getCurrentPinLocationAddress() async {
    if (_isDisposed || centerPinLocation.value == null) {
      return 'الموقع غير محدد';
    }

    try {
      final String address = await _locationService
          .getAddressFromLocation(centerPinLocation.value!);
      return address.isNotEmpty ? address : 'موقعك الحالي على الخريطة';
    } catch (e) {
      logger.w('خطأ في الحصول على عنوان الموقع: $e');
      return 'موقعك الحالي على الخريطة';
    }
  }

  /// Updated method to clear the pin address when clearing map
  void clearMap() {
    if (_isDisposed) return;

    // Cancel all timers and subscriptions
    _mapMovementTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _routeDrawingSubscription?.cancel();

    // Clear all observables
    markers.clear();
    polylines.clear();
    circles.clear();
    selectedLocation.value = null;
    selectedAddress.value = '';
    activeTrip.value = null;
    driverLocation.value = null;
    isPickupConfirmed.value = false;
    isDestinationConfirmed.value = false;
    currentStep.value = 'none';
    additionalStops.clear();
    searchResults.clear();
    isLoading.value = false; // ensure no lingering loading overlay

    // Clear pin address
    currentPinAddress.value = '';

    // Clear search controller safely
    try {
      searchController.clear();
    } catch (e) {
      logger.w('تم تجاهل خطأ في مسح searchController: $e');
    }
  }
// Add this method to MapControllerr class in map_controller.dart

  /// Enhanced location refresh with better UX
  Future<void> refreshCurrentLocation() async {
    if (_isDisposed) return;

    isLoading.value = true;

    try {
      LatLng? location = await _locationService.getCurrentLocation();
      if (_isDisposed) return;

      if (location != null) {
        currentLocation.value = location;
        currentAddress.value = _locationService.currentAddress.value;
        moveToLocation(location);
        _showSuccessSnackbar('تم تحديث الموقع', 'تم تحديث موقعك الحالي');
      }
    } catch (e) {
      logger.f('خطأ في تحديث الموقع: $e');
      if (!_isDisposed) {
        _showError('تعذر تحديث الموقع الحالي');
      }
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  /// Enhanced trip tracking with modern markers
  void startTripTracking(TripModel trip) {
    if (_isDisposed) return;

    activeTrip.value = trip;

    if (trip.routePolyline != null) {
      _drawEnhancedTripRoute(trip.routePolyline!);
    }

    _addTripMarkers(trip);
  }

  /// Enhanced trip markers
  void _addTripMarkers(TripModel trip) {
    if (_isDisposed) return;

    markers.add(
      Marker(
        key: const Key('trip_pickup'),
        point: trip.pickupLocation.latLng,
        width: 50.0,
        height: 65.0,
        child: EnhancedPinWidget(
          color: PinColors.pickup,
          label: 'الانطلاق',
          showLabel: true,
          size: 40,
          zoomLevel: mapZoom.value,
        ),
      ),
    );

    markers.add(
      Marker(
        key: const Key('trip_destination'),
        point: trip.destinationLocation.latLng,
        width: 50.0,
        height: 65.0,
        child: EnhancedPinWidget(
          color: PinColors.destination,
          label: 'الوصول',
          showLabel: true,
          size: 40,
          zoomLevel: mapZoom.value,
        ),
      ),
    );
  }

  /// Enhanced driver marker with modern styling
  void addDriverMarker(LatLng location, DriverModel driver) {
    if (_isDisposed) return;

    markers.removeWhere((marker) => marker.key == Key('driver_${driver.id}'));

    markers.add(
      Marker(
        key: Key('driver_${driver.id}'),
        point: location,
        width: 65.0,
        height: 65.0,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                PinColors.driver.withOpacity(0.8),
                PinColors.driver,
              ],
            ),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: PinColors.driver.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: driver.profileImage != null
              ? ClipOval(
                  child: Image.network(
                    driver.profileImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person,
                          color: Colors.white, size: 32);
                    },
                  ),
                )
              : const Icon(Icons.directions_car, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  /// Helper methods for better UX
  void _showSuccessSnackbar(String title, String message) {
    if (_isDisposed) return;

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: PinColors.pickup,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  void _showError(String message) {
    if (_isDisposed) return;

    Get.snackbar(
      'خطأ',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: PinColors.destination,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  @override
  void onClose() {
    // Set disposal flag first
    _isDisposed = true;

    // Cancel all timers and subscriptions
    _routeDrawingSubscription?.cancel();
    _searchDebounceTimer?.cancel();
    _mapMovementTimer?.cancel();

    // Dispose text controller
    try {
      searchController.dispose();
    } catch (e) {
      logger.w('خطأ في dispose searchController: $e');
    }

    super.onClose();
  }
}

/// Enhanced Additional Stop Model
class AdditionalStop {
  final String id;
  final LatLng location;
  final String address;
  final int stopNumber;

  AdditionalStop({
    required this.id,
    required this.location,
    required this.address,
    required this.stopNumber,
  });

  // Enhanced copy method for better state management
  AdditionalStop copyWith({
    String? id,
    LatLng? location,
    String? address,
    int? stopNumber,
  }) {
    return AdditionalStop(
      id: id ?? this.id,
      location: location ?? this.location,
      address: address ?? this.address,
      stopNumber: stopNumber ?? this.stopNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdditionalStop &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AdditionalStop(id: $id, stopNumber: $stopNumber, address: $address)';
  }
}

/// Pin Colors Helper Class
class PinColors {
  static const Color pickup = Color(0xFF4CAF50); // Green
  static const Color destination = Color(0xFFE53935); // Red
  static const Color current = Color(0xFF2196F3); // Blue
  static const Color additionalStop = Color(0xFFFF9800); // Orange
  static const Color driver = Color(0xFF9C27B0); // Purple
  static const Color selected = Color(0xFF607D8B); // Blue Grey

  static Color getColorForStep(String step) {
    switch (step) {
      case 'pickup':
        return pickup;
      case 'destination':
        return destination;
      case 'additional_stop':
        return additionalStop;
      case 'selected':
        return selected;
      default:
        return current;
    }
  }

  static String getLabelForStep(String step) {
    switch (step) {
      case 'pickup':
        return 'انطلاق';
      case 'destination':
        return 'وصول 1';
      case 'additional_stop':
        return 'وصول إضافي';
      case 'selected':
        return 'الموقع المختار';
      default:
        return 'الموقع الحالي';
    }
  }
}

/// Enhanced Pin Widget (you might need to create this)
class EnhancedPinWidget extends StatelessWidget {
  final Color color;
  final String label;
  final bool showLabel;
  final double size;
  final double zoomLevel;

  const EnhancedPinWidget({
    super.key,
    required this.color,
    required this.label,
    this.showLabel = false,
    this.size = 40,
    this.zoomLevel = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        Icons.location_on,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
}

/// Numbered Pin Widget for additional stops
class NumberedPinWidget extends StatelessWidget {
  final Color color;
  final String label;
  final int number;
  final bool showLabel;
  final double size;
  final double zoomLevel;

  const NumberedPinWidget({
    super.key,
    required this.color,
    required this.label,
    required this.number,
    this.showLabel = false,
    this.size = 40,
    this.zoomLevel = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
