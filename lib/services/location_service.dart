import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../main.dart';

class LocationService extends GetxService {
  static LocationService get to => Get.find();

  // ✅ الموقع الافتراضي: ساحة سعد، البصرة، العراق
  static const LatLng defaultLocation = LatLng(30.5090422, 47.7875914);

  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  final RxString currentAddress = RxString('');

  StreamSubscription<Position>? _locationSubscription;
  final RxBool isTrackingLocation = false.obs;

  final RxBool hasLocationPermission = false.obs;
// --- جديد: حقول كاش للنتيجة الأخيرة من OSRM
double? lastRouteDistanceKm;
int? lastRouteDurationSeconds;
DateTime? lastRouteCalculatedAt;

// --- الدالة التي تستدعي OSRM وترجع المسافة والمدة (meters, seconds)
Future<Map<String, dynamic>?> getAccurateRouteData({
  required LatLng pickup,
  required LatLng destination,
  List<LatLng>? additionalStops,
}) async {
  try {
    final points = [
      '${pickup.longitude},${pickup.latitude}',
      if (additionalStops != null) ...additionalStops.map((w) => '${w.longitude},${w.latitude}'),
      '${destination.longitude},${destination.latitude}',
    ].join(';');

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$points'
      '?overview=false&geometries=geojson&steps=false',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final double distanceMeters = (route['distance'] ?? 0).toDouble();
        final double durationSeconds = (route['duration'] ?? 0).toDouble();
        return {
          'distance_m': distanceMeters,
          'duration_s': durationSeconds,
        };
      }
    }
    return null;
  } catch (e) {
    logger.w('خطأ في الحصول على المسار الدقيق من OSRM: $e');
    return null;
  }
}

// --- دالة الحساب الكلية (معدّلة لتصبح async وتستخدم OSRM إن أمكن)
Future<double> calculateTotalDistanceWithStops({
  required LatLng pickup,
  required LatLng destination,
  List<LatLng>? additionalStops,
}) async {
  // حاول OSRM أولاً
  try {
    final routeData = await getAccurateRouteData(
      pickup: pickup,
      destination: destination,
      additionalStops: additionalStops,
    );

    if (routeData != null && routeData.containsKey('distance_m')) {
      final double distanceKm = (routeData['distance_m'] as double) / 1000.0;
      // خزّن للرجوع إليه لاحقاً
      lastRouteDistanceKm = distanceKm;
      lastRouteDurationSeconds = (routeData['duration_s'] as num).toInt();
      lastRouteCalculatedAt = DateTime.now();
      return distanceKm;
    }
  } catch (e) {
    logger.w('OSRM failed for multi-stop distance: $e');
  }

  // fallback: حساب المسافة بخط مستقيم بين النقاط (الطريقة القديمة)
  if (additionalStops == null || additionalStops.isEmpty) {
    return calculateDistance(pickup, destination);
  }

  double totalDistance = 0.0;
  LatLng currentPoint = pickup;
  for (final stop in additionalStops) {
    totalDistance += calculateDistance(currentPoint, stop);
    currentPoint = stop;
  }

  totalDistance += calculateDistance(currentPoint, destination);
  return totalDistance;
}

  Future<LocationService> init() async {
    await _requestLocationPermission();
    if (hasLocationPermission.value) {
      await getCurrentLocation();
    }
    return this;
  }

  Future<List<LatLng>> getRouteWithMultipleWaypoints(
    LatLng from,
    List<LatLng> waypoints,
    LatLng to,
  ) async {
    try {
      final allPoints = [
        '${from.longitude},${from.latitude}',
        ...waypoints.map((w) => '${w.longitude},${w.latitude}'),
        '${to.longitude},${to.latitude}',
      ].join(';');

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$allPoints'
        '?overview=full&geometries=geojson&steps=false',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;

          return coordinates
              .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();
        }
      }

      return [from, ...waypoints, to];
    } catch (e) {
      logger.w('خطأ في الحصول على المسار مع عدة نقاط وسطى: $e');
      return [from, ...waypoints, to];
    }
  }

  Future<bool> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'إذن الموقع مطلوب',
          'يرجى تفعيل إذن الموقع من الإعدادات',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      hasLocationPermission.value =
          permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always;

      return hasLocationPermission.value;
    } catch (e) {
      logger.w('خطأ في طلب إذن الموقع: $e');
      return false;
    }
  }

  Future<LatLng?> getCurrentLocation() async {
    try {
      if (!hasLocationPermission.value) {
        await _requestLocationPermission();
      }

      if (!hasLocationPermission.value) {
        // ✅ إرجاع الموقع الافتراضي إذا لم يكن هناك إذن
        currentLocation.value = defaultLocation;
        return defaultLocation;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      LatLng location = LatLng(position.latitude, position.longitude);
      currentLocation.value = location;

      await _updateAddressFromLocation(location);

      return location;
    } catch (e) {
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) {
        return LatLng(lastKnownPosition.latitude, lastKnownPosition.longitude);
      }

      logger.w('خطأ في الحصول على الموقع: $e');
      
      // ✅ إرجاع الموقع الافتراضي بدلاً من null
      currentLocation.value = defaultLocation;
      currentAddress.value = 'ساحة سعد، البصرة، العراق';
      
      return defaultLocation;
    }
  }

  void startLocationTracking({
    Function(LatLng)? onLocationUpdate,
    int intervalSeconds = 5,
  }) {
    if (isTrackingLocation.value) return;

    isTrackingLocation.value = true;

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        timeLimit: Duration(seconds: intervalSeconds),
      ),
    ).listen((Position position) {
      LatLng location = LatLng(position.latitude, position.longitude);
      currentLocation.value = location;

      if (onLocationUpdate != null) {
        onLocationUpdate(location);
      }
    });
  }

  void stopLocationTracking() {
    _locationSubscription?.cancel();
    isTrackingLocation.value = false;
  }

  // ✅ تحسين البحث ليكون مركز على البصرة والعراق
  Future<List<LocationSearchResult>> searchLocation(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      List<LocationSearchResult> results = [];

      // ✅ 1. البحث باستخدام Nominatim API (أفضل للعراق والبصرة)
      results.addAll(await _searchWithNominatim(query));

      // ✅ 2. البحث العادي كـ fallback
      if (results.isEmpty) {
        results.addAll(await _searchWithGeocoding(query));
      }

      // ✅ 3. ترتيب النتائج حسب القرب من البصرة
      results.sort((a, b) {
        double distA = calculateDistance(defaultLocation, a.latLng);
        double distB = calculateDistance(defaultLocation, b.latLng);
        return distA.compareTo(distB);
      });

      // ✅ 4. الاحتفاظ بـ 10 نتائج فقط
      if (results.length > 10) {
        results = results.sublist(0, 10);
      }

      return results;
    } catch (e) {
      logger.w('خطأ في البحث: $e');
      return [];
    }
  }

  // ✅ البحث باستخدام Nominatim API (مجاني ويدعم العراق بشكل أفضل)
  Future<List<LocationSearchResult>> _searchWithNominatim(String query) async {
    try {
      String searchQuery = query;
      
      // إضافة البصرة والعراق إذا لم تكن موجودة
      if (!query.toLowerCase().contains('البصرة') && 
          !query.toLowerCase().contains('basra')) {
        searchQuery = '$query البصرة';
      }
      
      if (!query.toLowerCase().contains('العراق') && 
          !query.toLowerCase().contains('iraq')) {
        searchQuery = '$searchQuery العراق';
      }

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'q=${Uri.encodeComponent(searchQuery)}&'
        'format=json&'
        'addressdetails=1&'
        'limit=10&'
        'countrycodes=iq&'  // ✅ العراق فقط
        'viewbox=47.5,30.0,48.5,31.0&'  // ✅ البصرة والمنطقة المحيطة
        'bounded=0&'  // السماح بنتائج خارج الصندوق لكن مع الأولوية للداخل
        'accept-language=ar'
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'TaksiElbasra/1.0',  // ✅ مطلوب لـ Nominatim
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        
        List<LocationSearchResult> results = [];
        
        for (var item in data) {
          try {
            final lat = double.parse(item['lat'].toString());
            final lon = double.parse(item['lon'].toString());
            
            final address = item['address'] ?? {};
            String displayName = item['display_name'] ?? '';
            
            // تنسيق العنوان بشكل أفضل
            List<String> addressParts = [];
            
            if (address['road'] != null) addressParts.add(address['road']);
            if (address['suburb'] != null) addressParts.add(address['suburb']);
            if (address['city'] != null) addressParts.add(address['city']);
            if (address['state'] != null) addressParts.add(address['state']);
            
            String formattedAddress = addressParts.isNotEmpty 
                ? addressParts.join('، ') 
                : displayName;
            
            results.add(LocationSearchResult(
              latLng: LatLng(lat, lon),
              address: formattedAddress,
              name: address['name'] ?? address['road'] ?? query,
              locality: address['city'] ?? address['suburb'] ?? 'البصرة',
              country: 'العراق',
            ));
          } catch (e) {
            logger.w('خطأ في معالجة نتيجة: $e');
          }
        }
        
        return results;
      }
      
      return [];
    } catch (e) {
      logger.w('خطأ في البحث باستخدام Nominatim: $e');
      return [];
    }
  }

  // ✅ البحث العادي كـ Fallback
  Future<List<LocationSearchResult>> _searchWithGeocoding(String query) async {
    try {
      await setLocaleIdentifier('ar_IQ');

      String searchQuery = query;
      if (!query.toLowerCase().contains('البصرة')) {
        searchQuery = '$query، البصرة، العراق';
      }

      List<Location> locations = await locationFromAddress(
        searchQuery,
      ).timeout(const Duration(seconds: 10));

      List<LocationSearchResult> results = [];

      for (Location location in locations.take(5)) {  // ✅ أخذ 5 نتائج فقط
        try {
          await setLocaleIdentifier('ar_IQ');
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark placemark = placemarks.first;
            String address = _formatAddress(placemark);

            results.add(LocationSearchResult(
              latLng: LatLng(location.latitude, location.longitude),
              address: address,
              name: placemark.name ?? query,
              locality: placemark.locality ?? 'البصرة',
              country: placemark.country ?? 'العراق',
            ));
          }
        } catch (e) {
          logger.w('خطأ في تحويل الإحداثيات: $e');
        }
      }

      return results;
    } catch (e) {
      logger.w('خطأ في البحث بـ Geocoding: $e');
      return [];
    }
  }

  Future<String> getAddressFromLocation(LatLng location) async {
    try {
      await setLocaleIdentifier('ar_IQ');

      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      ).timeout(const Duration(seconds: 10));

      if (placemarks.isNotEmpty) {
        return _formatAddress(placemarks.first);
      }

      return 'موقع في البصرة، العراق';
    } on TimeoutException {
      logger.w('انتهت مهلة الحصول على العنوان');
      return 'موقع في البصرة، العراق';
    } catch (e) {
      logger.w('خطأ في الحصول على العنوان: $e');
      return 'موقع في البصرة، العراق';
    }
  }

  Future<void> _updateAddressFromLocation(LatLng location) async {
    String address = await getAddressFromLocation(location);
    currentAddress.value = address;
  }

  String _formatAddress(Placemark placemark) {
    List<String> addressParts = [];

    if (placemark.name != null && placemark.name!.isNotEmpty) {
      addressParts.add(placemark.name!);
    }

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      addressParts.add(placemark.street!);
    }

    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      addressParts.add(placemark.locality!);
    }

    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      addressParts.add(placemark.administrativeArea!);
    }

    return addressParts.isNotEmpty 
        ? addressParts.join('، ') 
        : 'البصرة، العراق';
  }

  /// ✅ حساب المسافة بالكيلومترات (بدقة عالية)
  double calculateDistance(LatLng from, LatLng to) {
    final distanceInMeters = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    return distanceInMeters / 1000.0; // تحويل من متر إلى كيلومتر
  }

/// ✅ دالة لحساب المسافة والمدة الفعلية عبر OSRM مع نقاط توقف
// Future<Map<String, dynamic>> getAccurateRouteData({
//   required LatLng pickup,
//   required LatLng destination,
//   List<LatLng>? additionalStops,
// }) async {
//   try {
//     // ترتيب النقاط
//     final points = [
//       '${pickup.longitude},${pickup.latitude}',
//       if (additionalStops != null)
//         ...additionalStops.map((w) => '${w.longitude},${w.latitude}'),
//       '${destination.longitude},${destination.latitude}',
//     ].join(';');

//     // ✅ طلب من OSRM للقيادة (Driving)
//     final url = Uri.parse(
//       'https://router.project-osrm.org/route/v1/driving/$points'
//       '?overview=full&geometries=geojson&steps=false',
//     );

//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);

//       if (data['routes'] != null && data['routes'].isNotEmpty) {
//         final route = data['routes'][0];
//         final double distanceMeters = route['distance'] ?? 0.0;
//         final double durationSeconds = route['duration'] ?? 0.0;

//         final distanceKm = distanceMeters / 1000.0;
//         final durationMinutes = (durationSeconds / 60).round();

//         final coordinates = (route['geometry']['coordinates'] as List)
//             .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
//             .toList();

//         return {
//           'distance_km': distanceKm,
//           'duration_min': durationMinutes,
//           'route_points': coordinates,
//         };
//       }
//     }

//     // fallback
//     return {
//       'distance_km': 0.0,
//       'duration_min': 0,
//       'route_points': [pickup, ...?additionalStops, destination],
//     };
//   } catch (e) {
//     logger.w('⚠️ خطأ في حساب المسافة الفعلية: $e');
//     return {
//       'distance_km': 0.0,
//       'duration_min': 0,
//       'route_points': [pickup, ...?additionalStops, destination],
//     };
//   }
// }

  
  // // ✅ حساب المسافة الإجمالية مع النقاط الإضافية
  // double calculateTotalDistanceWithStops({
  //   required LatLng pickup,
  //   required LatLng destination,
  //   List<LatLng>? additionalStops,
  // }) {
  //   if (additionalStops == null || additionalStops.isEmpty) {
  //     return calculateDistance(pickup, destination);
  //   }

  //   double totalDistance = 0.0;
  //   LatLng currentPoint = pickup;

  //   // حساب المسافة من نقطة الانطلاق إلى أول نقطة توقف
  //   for (final stop in additionalStops) {
  //     totalDistance += calculateDistance(currentPoint, stop);
  //     currentPoint = stop;
  //   }

  //   // حساب المسافة من آخر نقطة توقف إلى الوجهة النهائية
  //   totalDistance += calculateDistance(currentPoint, destination);

  //   return totalDistance;
  // }

  /// ✅ تقدير الوقت بدقة أعلى (يأخذ في الاعتبار نوع الطريق)
  int estimateDuration(double distanceKm, {bool withStops = false}) {
    // سرعة متوسطة في المدينة: 25-35 كم/ساعة حسب الزحام
    double averageSpeedKmPerHour = 30.0;

    // إذا كانت المسافة قصيرة جداً (<1 كم)، استخدم سرعة أبطأ
    if (distanceKm < 1.0) {
      averageSpeedKmPerHour = 20.0;
    }
    // إذا كانت المسافة متوسطة (1-5 كم)، استخدم السرعة العادية
    else if (distanceKm < 5.0) {
      averageSpeedKmPerHour = 30.0;
    }
    // إذا كانت المسافة كبيرة (>5 كم)، يمكن استخدام سرعة أعلى قليلاً
    else {
      averageSpeedKmPerHour = 35.0;
    }

    // حساب الوقت الأساسي
    double timeInHours = distanceKm / averageSpeedKmPerHour;
    int timeInMinutes = (timeInHours * 60).round();

    // إضافة وقت إضافي لكل نقطة توقف (دقيقة واحدة)
    if (withStops) {
      timeInMinutes += 1;
    }

    // الحد الأدنى للوقت هو دقيقة واحدة
    return timeInMinutes > 0 ? timeInMinutes : 1;
  }

  Future<List<LatLng>> getRoute(LatLng from, LatLng to) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;

          return coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
        }
      }

      return [from, to];
    } catch (e) {
      logger.w('خطأ في الحصول على المسار: $e');
      return [from, to];
    }
  }

  double calculateFare(
    double distanceKm, {
    bool isPlusTrip = false,
    int additionalStops = 0,
    bool isRoundTrip = false,
    int waitingTime = 0,
  }) {
    double baseFare = distanceKm * 2000;
    
    if (isPlusTrip) {
      baseFare *= 1.3;
    }
    
    baseFare += (additionalStops * 1000);
    
    if (isRoundTrip) {
      baseFare *= 2;
    }
    
    baseFare += (waitingTime * 1000);
    
    if (baseFare < 2000) baseFare = 2000;
    
    return baseFare;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  @override
  void onClose() {
    stopLocationTracking();
    super.onClose();
  }
}

class LocationSearchResult {
  final LatLng latLng;
  final String address;
  final String name;
  final String locality;
  final String country;

  LocationSearchResult({
    required this.latLng,
    required this.address,
    required this.name,
    required this.locality,
    required this.country,
  });

  @override
  String toString() => address;
}
