import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/main.dart';

import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/services/location_service.dart';

class MapControllerr extends GetxController {
  static MapControllerr get to => Get.find();

  // Map controller
  final MapController mapController = MapController();

  // Map state
  final Rx<LatLng> mapCenter =
      const LatLng(30.0444, 31.2357).obs; // Cairo default
  final RxDouble mapZoom = 15.0.obs;
  final RxBool isMapReady = false.obs;

  // Markers and overlays
  final RxList<Marker> markers = <Marker>[].obs;
  final RxList<Polyline> polylines = <Polyline>[].obs;
  final RxList<CircleMarker> circles = <CircleMarker>[].obs;

  // Current location
  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  final RxString currentAddress = ''.obs;

  // Search and location selection
  final RxList<LocationSearchResult> searchResults =
      <LocationSearchResult>[].obs;
  final Rx<LatLng?> selectedLocation = Rx<LatLng?>(null);
  final RxString selectedAddress = ''.obs;
  final RxBool isSearching = false.obs;

  // Middle stop (waypoint)
  final Rx<LatLng?> middleStopLocation = Rx<LatLng?>(null);
  final RxString middleStopAddress = ''.obs;

  // Trip tracking
  final Rx<TripModel?> activeTrip = Rx<TripModel?>(null);
  final RxList<LatLng> tripRoute = <LatLng>[].obs;
  final Rx<LatLng?> driverLocation = Rx<LatLng?>(null);

  // UI state
  final RxBool isLoading = false.obs;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController middleStopController = TextEditingController();

  // Services
  final LocationService _locationService = LocationService.to;

  @override
  void onInit() {
    super.onInit();
    _initializeMap();

    // Listen to location updates
    ever(currentLocation, (LatLng? location) {
      if (location != null) {
        _updateCurrentLocationMarker(location);
        // تحديث المسار إذا كان هناك وجهة محددة
        if (selectedLocation.value != null) {
          _updateRouteToSelectedLocation(selectedLocation.value!);
        }
      }
    });
  }

  /// تهيئة الخريطة
  Future<void> _initializeMap() async {
    isLoading.value = true;

    try {
      // الحصول على الموقع الحالي
      LatLng? location = await _locationService.getCurrentLocation();
      if (location != null) {
        currentLocation.value = location;
        mapCenter.value = location;
        currentAddress.value = _locationService.currentAddress.value;
        // تحريك الخريطة إلى الموقع الحالي

        moveToLocation(location);
        isMapReady.value = true;
      } else {
        logger.w("تعذر الحصول على الموقع الحالي");
        Get.snackbar("خطأ", "الموقع غير متاح حالياً");
      }

      isMapReady.value = true;
    } catch (e) {
      logger.f('خطأ في تهيئة الخريطة: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// تحريك الخريطة إلى موقع معين
  void moveToLocation(LatLng location, {double zoom = 16.0}) {
    mapCenter.value = location;
    mapZoom.value = zoom;
    mapController.move(location, zoom);
  }

  /// تهيئة الخريطة عند جاهزيتها
  void onMapReady() {
    isMapReady.value = true;
    if (currentLocation.value != null) {
      moveToLocation(currentLocation.value!);
    }
  }

  /// عرض مسار الرحلة
  void showTripRoute({
    required LatLng pickup,
    required LatLng destination,
    List<LatLng>? routePolyline,
  }) {
    // إضافة علامات المواقع
    markers.clear();
    markers.addAll([
      Marker(
        point: pickup,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 20),
        ),
      ),
      Marker(
        point: destination,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
        ),
      ),
    ]);

    // إضافة مسار الرحلة
    if (routePolyline != null && routePolyline.isNotEmpty) {
      polylines.clear();
      polylines.add(
        Polyline(
          points: routePolyline,
          strokeWidth: 4,
          color: Colors.blue,
        ),
      );
    }

    // تحريك الخريطة لتظهر المسار كاملاً
    final allPoints = [pickup, destination];
    if (routePolyline != null && routePolyline.isNotEmpty) {
      allPoints.addAll(routePolyline);
    }
    _fitBoundsToRoute(allPoints);
  }

  /// تحريك الخريطة إلى موقع معين (طريقة بديلة)
  void _moveToLocationInternal(LatLng location, {double zoom = 16.0}) {
    if (!isMapReady.value) return;

    try {
      mapController.move(location, zoom);
      mapCenter.value = location;
      mapZoom.value = zoom;
    } catch (e) {
      logger.f('خطأ في تحريك الخريطة: $e');
    }
  }

  /// البحث عن موقع
  Future<void> searchLocation(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }

    isSearching.value = true;

    try {
      List<LocationSearchResult> results =
          await _locationService.searchLocationAdvanced(query);

      searchResults.assignAll(results);
    } catch (e) {
      logger.f('خطأ في البحث: $e');
      Get.snackbar(
        'خطأ في البحث',
        'تعذر البحث عن الموقع المطلوب',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSearching.value = false;
    }
  }

  /// تحديد موقع من نتائج البحث
  void selectLocationFromSearch(LocationSearchResult result) {
    selectedLocation.value = result.latLng;
    selectedAddress.value = result.address;

    // تحريك الخريطة إلى الموقع المحدد
    moveToLocation(result.latLng);

    // إضافة علامة على الموقع المحدد
    addSelectedLocationMarker(result.latLng, result.name);

    // مسح نتائج البحث
    searchResults.clear();
    // ملء حقل البحث باسم الوجهة المختارة
    searchController.text = result.name;

    // تحديث البولي لاين والسهم إذا كان هناك موقع انطلاق محدد
    _updateRouteToSelectedLocation(result.latLng);
  }

  /// تعيين محطة وسطى من نتيجة البحث
  void setMiddleStopFromSearch(LocationSearchResult result) {
    middleStopLocation.value = result.latLng;
    middleStopAddress.value = result.address;

    // ملء حقل نص المحطة الوسطى
    middleStopController.text = result.name;

    // إضافة علامة للمحطة الوسطى
    _addMiddleStopMarker(result.latLng, result.name);

    // مسح نتائج البحث فقط
    searchResults.clear();

    // تحديث المسار إذا كان هناك وجهة محددة
    if (selectedLocation.value != null) {
      _updateRouteToSelectedLocation(selectedLocation.value!);
    }
  }

  void clearMiddleStop() {
    middleStopLocation.value = null;
    middleStopAddress.value = '';
    markers.removeWhere((m) => m.key == const Key('middle_stop'));

    // تحديث المسار إذا كان هناك وجهة محددة
    if (selectedLocation.value != null) {
      _updateRouteToSelectedLocation(selectedLocation.value!);
    }
  }

  /// تحديث المسار إلى الموقع المحدد
  void _updateRouteToSelectedLocation(LatLng destination) {
    // إذا كان هناك موقع انطلاق محدد (الموقع الحالي أو موقع محدد مسبقاً)
    LatLng? startLocation = currentLocation.value;

    if (startLocation != null) {
      // إنشاء مسار مباشر بين نقطة البداية والوجهة
      List<LatLng> routePoints = [startLocation, destination];

      // إضافة محطة وسطى إذا كانت موجودة
      if (middleStopLocation.value != null) {
        routePoints = [startLocation, middleStopLocation.value!, destination];
      }

      // تحديث البولي لاين
      _updateRoutePolyline(routePoints);

      // إضافة سهم اتجاه
      _addDirectionArrow(routePoints);

      // تحريك الخريطة لتظهر المسار كاملاً
      _fitBoundsToRoute(routePoints);
    }
  }

  /// تحديث البولي لاين للمسار
  void _updateRoutePolyline(List<LatLng> routePoints) {
    polylines.clear();
    polylines.add(
      Polyline(
        points: routePoints,
        strokeWidth: 4,
        color: Colors.blue,
      ),
    );
  }

  /// إضافة سهم اتجاه للمسار
  void _addDirectionArrow(List<LatLng> routePoints) {
    if (routePoints.length < 2) return;

    // إزالة الأسهم السابقة
    markers.removeWhere((m) => m.key.toString().contains('direction_arrow'));

    // إضافة سهم في منتصف المسار
    for (int i = 0; i < routePoints.length - 1; i++) {
      LatLng start = routePoints[i];
      LatLng end = routePoints[i + 1];

      // حساب نقطة منتصف المسار
      LatLng midPoint = LatLng(
        (start.latitude + end.latitude) / 2,
        (start.longitude + end.longitude) / 2,
      );

      // حساب اتجاه السهم
      double bearing = _calculateBearing(start, end);

      markers.add(
        Marker(
          key: Key('direction_arrow_$i'),
          point: midPoint,
          width: 30,
          height: 30,
          child: Transform.rotate(
            angle: bearing * (math.pi / 180), // تحويل الدرجات إلى راديان
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      );
    }
  }

  /// حساب اتجاه السهم بين نقطتين
  double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * (math.pi / 180);
    double lat2 = end.latitude * (math.pi / 180);
    double dLon = (end.longitude - start.longitude) * (math.pi / 180);

    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    double bearing = math.atan2(y, x) * (180 / math.pi);
    return (bearing + 360) % 360;
  }

  /// إضافة علامة الموقع الحالي
  void _updateCurrentLocationMarker(LatLng location) {
    // إزالة علامة الموقع الحالي السابقة
    markers
        .removeWhere((marker) => marker.key == const Key('current_location'));

    // إضافة علامة الموقع الحالي الجديدة
    markers.add(
      Marker(
        key: const Key('current_location'),
        point: location,
        width: 40.0,
        height: 40.0,
        //  builder: (ctx) => Container(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.my_location,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  void _addMiddleStopMarker(LatLng location, String title) {
    markers.removeWhere((marker) => marker.key == const Key('middle_stop'));
    markers.add(
      Marker(
        key: const Key('middle_stop'),
        point: location,
        width: 50,
        height: 50,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.stop_circle, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  /// إضافة علامة الموقع المحدد
  void addSelectedLocationMarker(LatLng location, String title) {
    // إزالة علامة الموقع المحدد السابقة
    markers
        .removeWhere((marker) => marker.key == const Key('selected_location'));

    // إضافة علامة الموقع المحدد الجديدة
    markers.add(
      Marker(
        key: const Key('selected_location'),
        point: location,
        width: 60.0,
        height: 60.0,
        child: SizedBox(
          width: 60,
          height: 60,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// إضافة علامة السائق
  void addDriverMarker(LatLng location, DriverModel driver) {
    // إزالة علامة السائق السابقة
    markers.removeWhere((marker) => marker.key == Key('driver_${driver.id}'));

    markers.add(
      Marker(
        key: Key('driver_${driver.id}'),
        point: location,
        width: 60.0,
        height: 60.0,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
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
                          color: Colors.white, size: 30);
                    },
                  ),
                )
              : const Icon(Icons.directions_car, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  /// رسم مسار الرحلة (يدعم تقسيم المسار وتلوين كل مقطع بلون مختلف)
  void drawTripRoute(List<LatLng> routePoints, {List<int>? splitIndices}) {
    if (routePoints.isEmpty) return;

    // مسح المسارات السابقة
    polylines.clear();

    // تقسيم المسار عند نقاط محددة (مثلاً: [indexOfMiddle])
    if (splitIndices != null && splitIndices.isNotEmpty) {
      final indices = [
        0,
        ...splitIndices.where((i) => i > 0 && i < routePoints.length),
        routePoints.length - 1
      ];
      for (int i = 0; i < indices.length - 1; i++) {
        final start = indices[i];
        final end = indices[i + 1];
        if (end - start < 1) continue;
        final color = i == 0
            ? Colors.green // من الموقع الحالي حتى المحطة الوسطى
            : Colors.red; // من المحطة الوسطى حتى الوجهة
        polylines.add(Polyline(
            points: routePoints.sublist(start, end + 1),
            color: color,
            strokeWidth: 4.0));
      }
    } else {
      polylines.add(
          Polyline(points: routePoints, color: Colors.blue, strokeWidth: 4.0));
    }

    _fitBoundsToRoute(routePoints);
  }

  /// تعديل حدود الخريطة لتشمل المسار
  void _fitBoundsToRoute(List<LatLng> points) {
    if (points.isEmpty) return;

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

    // إضافة هامش
    double latPadding = (maxLat - minLat) * 0.1;
    double lngPadding = (maxLng - minLng) * 0.1;

    LatLngBounds bounds = LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    try {
      mapController.fitCamera(CameraFit.bounds(bounds: bounds));
      //fitBoundsToRoute(points);
      // mapController.fitBounds(
      //   bounds,
      //   options: FitBoundsOptions(
      //     padding: EdgeInsets.all(20),
      //     maxZoom: 18.0,
      //     inside: true,
      //     forceIntegerZoomLevel: true,
      //   ),
      // );
      // mapCenter.value = bounds.center;
    } catch (e) {
      logger.f('خطأ في تعديل حدود الخريطة: $e');
    }
  }

  /// بدء تتبع رحلة
  void startTripTracking(TripModel trip) {
    activeTrip.value = trip;

    // رسم مسار الرحلة
    if (trip.routePolyline != null) {
      drawTripRoute(trip.routePolyline!);
    }

    // إضافة علامات نقاط البداية والنهاية
    _addTripMarkers(trip);
  }

  /// إضافة علامات الرحلة
  void _addTripMarkers(TripModel trip) {
    // علامة نقطة البداية
    markers.add(
      Marker(
        key: const Key('pickup_location'),
        point: trip.pickupLocation.latLng,
        width: 40.0,
        height: 40.0,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 20),
        ),
      ),
    );

    // علامة نقطة الوجهة
    markers.add(
      Marker(
        key: const Key('destination_location'),
        point: trip.destinationLocation.latLng,
        width: 40.0,
        height: 40.0,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  /// تحديث موقع السائق
  void updateDriverLocation(LatLng location) {
    driverLocation.value = location;

    // تحديث علامة السائق إذا كانت موجودة
    if (activeTrip.value != null && activeTrip.value!.driverId != null) {
      // سيتم إضافة تفاصيل السائق لاحقاً
    }
  }

  /// مسح الخريطة
  void clearMap() {
    markers.clear();
    polylines.clear();
    circles.clear();
    selectedLocation.value = null;
    selectedAddress.value = '';
    activeTrip.value = null;
    driverLocation.value = null;
  }

  /// تحديث الموقع الحالي
  Future<void> refreshCurrentLocation() async {
    isLoading.value = true;

    try {
      LatLng? location = await _locationService.getCurrentLocation();

      currentLocation.value = location;
      currentAddress.value = _locationService.currentAddress.value;
      moveToLocation(location!);
    } catch (e) {
      logger.f('خطأ في تحديث الموقع: $e');
      Get.snackbar(
        'خطأ',
        'تعذر تحديث الموقع الحالي',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    middleStopController.dispose();
    super.onClose();
  }
}
