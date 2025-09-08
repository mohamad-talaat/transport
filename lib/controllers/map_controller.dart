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

  // Route drawing streams
  StreamSubscription<List<LatLng>>? _routeDrawingSubscription;
  Timer? _searchDebounceTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeMap();

    // Listen to location updates
    ever(currentLocation, (LatLng? location) {
      if (location != null) {
        _updateCurrentLocationMarker(location);
        // تحديث المسار فوراً عند تغيير الموقع الحالي
        _updateRouteIfNeeded();
      }
    });

    // Listen to selected location changes
    ever(selectedLocation, (LatLng? location) {
      if (location != null && currentLocation.value != null) {
        _updateRouteToSelectedLocation(location);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentLocation.value != null) {
        moveToLocation(currentLocation.value!);
      }
    });
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

  /// البحث عن موقع مع debounce للسرعة
  Future<void> searchLocation(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }

    // Cancel previous search timer
    _searchDebounceTimer?.cancel();

    // Set searching state immediately
    isSearching.value = true;

    // Debounce search to improve performance
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        List<LocationSearchResult> results =
            await _locationService.searchLocationAdvanced(query);

        // ترتيب النتائج حسب المسافة من الموقع الحالي
        if (currentLocation.value != null) {
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
    });
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
    // ملء حقل البحث باسم الوجهة المختارة مع التحقق من الحالة
    if (!isClosed) {
      try {
        searchController.text = result.name;
      } catch (e) {
        logger.w('تم تجاهل خطأ في تعيين searchController: $e');
      }
    }

    // تحديث المسار سيتم تلقائياً عبر ever listener
  }

  /// تعيين محطة وسطى من نتيجة البحث
  void setMiddleStopFromSearch(LocationSearchResult result) {
    middleStopLocation.value = result.latLng;
    middleStopAddress.value = result.address;

    // ملء حقل نص المحطة الوسطى مع التحقق من الحالة
    if (!isClosed) {
      try {
        middleStopController.text = result.name;
      } catch (e) {
        logger.w('تم تجاهل خطأ في تعيين middleStopController: $e');
      }
    }

    // إضافة علامة للمحطة الوسطى
    _addMiddleStopMarker(result.latLng, result.name);

    // مسح نتائج البحث فقط
    searchResults.clear();

    // تحديث المسار
    _updateRouteIfNeeded();
  }

  /// تعيين محطة وسطى من الخريطة مباشرة
  void setMiddleStopFromMap(LatLng latLng, {String? title}) {
    middleStopLocation.value = latLng;
    middleStopAddress.value = title ?? 'محطة وسطى';
    _addMiddleStopMarker(latLng, title ?? 'محطة وسطى');
    _updateRouteIfNeeded();
    Get.snackbar(
      'تم إضافة المحطة',
      'تمت إضافة محطة وسطى بنجاح',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void clearMiddleStop() {
    middleStopLocation.value = null;
    middleStopAddress.value = '';
    markers.removeWhere((m) => m.key == const Key('middle_stop'));

    // تحديث المسار
    _updateRouteIfNeeded();
  }

  /// تحديث المسار إذا كانت هناك حاجة
  void _updateRouteIfNeeded() {
    if (currentLocation.value != null && selectedLocation.value != null) {
      _updateRouteToSelectedLocation(selectedLocation.value!);
    }
  }

  /// رسم المسار مباشرة مع stream للتحديث الفوري
  void _updateRouteToSelectedLocation(LatLng destination) {
    final LatLng? from = currentLocation.value;
    if (from == null) return;

    // Cancel previous route subscription
    _routeDrawingSubscription?.cancel();

    // Start loading
    isLoading.value = true;

    // Create a stream for route drawing
    _routeDrawingSubscription = _getRouteStream(from, destination).listen(
      (routePoints) {
        if (routePoints.isNotEmpty) {
          drawTripRoute(routePoints);
        }
        isLoading.value = false;
      },
      onError: (error) {
        logger.w('خطأ في رسم المسار: $error');
        // Keep the temporary straight line on error
        isLoading.value = false;
      },
    );
  }

  /// اختيار موقع من الخريطة مباشرة وتحديث كل شيء فوراً
  Future<void> selectLocationFromMap(LatLng point) async {
    try {
      // تأكد من وجود الموقع الحالي، لو مش موجود حاول تجيبه سريعاً مرة واحدة
      if (currentLocation.value == null) {
        try {
          final loc = await _locationService.getCurrentLocation();
          if (loc != null) {
            currentLocation.value = loc;
          }
        } catch (_) {}
      }

      selectedLocation.value = point;

      // تحريك الخريطة وإضافة علامة
      moveToLocation(point);
      addSelectedLocationMarker(point, 'الوجهة');

      // جلب العنوان وتعبئة حقل البحث
      final String address =
          await _locationService.getAddressFromLocation(point);
      selectedAddress.value = address;
      // قد يكون الحقل غير موجود مؤقتاً أثناء إعادة البناء
      // تحرّس قبل الكتابة
      if (!isClosed && Get.isRegistered<MapControllerr>()) {
        try {
          searchController.text = address;
        } catch (_) {}
      }

      // تحديث المسار فوراً
      _updateRouteIfNeeded();
    } catch (e) {
      logger.w('خطأ في اختيار موقع من الخريطة: $e');
    }
  }

  /// Create a stream for route fetching
  Stream<List<LatLng>> _getRouteStream(LatLng from, LatLng destination) async* {
    try {
      final bool hasMiddle = middleStopLocation.value != null;

      List<LatLng> route;
      if (hasMiddle) {
        final mid = middleStopLocation.value!;
        // التحقق من صحة المحطة الوسطى
        final total = _locationService.calculateDistance(from, destination);
        final d1 = _locationService.calculateDistance(from, mid);
        final d2 = _locationService.calculateDistance(mid, destination);

        if (d1 + d2 > total * 1.3) {
          Get.snackbar(
            'محطة غير صالحة',
            'المحطة الوسطى يجب أن تكون بين موقعك والوجهة.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          yield [from, destination]; // fallback to straight line
          return;
        }

        route =
            await _locationService.getRouteWithWaypoint(from, mid, destination);
      } else {
        route = await _locationService.getRoute(from, destination);
      }

      yield route;
    } catch (e) {
      logger.w('خطأ في الحصول على المسار: $e');
      yield [from, destination]; // fallback to straight line
    }
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

    // التحقق من أن الـ controller لم يتم التخلص منه قبل استخدامه
    if (!isClosed) {
      try {
        searchController.clear(); // Clear search field
      } catch (e) {
        // تجاهل الخطأ إذا كان الـ controller تم التخلص منه
        logger.w('تم تجاهل خطأ في مسح searchController: $e');
      }
    }
    searchResults.clear();
  }

  /// مسح البحث
  void clearSearch() {
    // التحقق من أن الـ controller لم يتم التخلص منه قبل استخدامه
    if (!isClosed) {
      try {
        searchController.clear();
      } catch (e) {
        // تجاهل الخطأ إذا كان الـ controller تم التخلص منه
        logger.w('تم تجاهل خطأ في مسح searchController في clearSearch: $e');
      }
    }
    searchResults.clear();
    selectedLocation.value = null;
    selectedAddress.value = '';
    polylines.clear(); // Clear any drawn routes

    // Remove selected location marker
    markers
        .removeWhere((marker) => marker.key == const Key('selected_location'));
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
    _routeDrawingSubscription?.cancel();
    _searchDebounceTimer?.cancel();

    // التخلص من الـ controllers بأمان
    // try {
    //   searchController.dispose();
    // } catch (e) {
    //   logger.w('خطأ في التخلص من searchController: $e');
    // }

    // try {
    //   middleStopController.dispose();
    // } catch (e) {
    //   logger.w('خطأ في التخلص من middleStopController: $e');
    // }

    super.onClose();
  }
}
