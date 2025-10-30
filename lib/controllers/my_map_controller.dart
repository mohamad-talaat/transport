import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/services/location_service.dart';
import 'package:transport_app/services/map_services/map_marker_service.dart';
import 'package:transport_app/services/map_services/trip_markers_manager.dart';
import 'package:transport_app/views/rider/rider_widgets/pin_color.dart';

class MyMapController extends GetxController {
  static MyMapController get to => Get.find();

  late final MapController mapController;
  
  MyMapController() {
    try {
      mapController = MapController();
      logger.i('✅ MapController initialized successfully');
    } catch (e) {
      logger.e('❌ Failed to initialize MapController: $e');
      rethrow;
    }
  }

  final RxBool isMapMoving = false.obs;
  final RxBool showConfirmButton = false.obs;
  final Rx<LatLng?> centerPinLocation = Rx<LatLng?>(null);
  final RxString currentStep =
      'none'.obs; // pickup, destination, additional_stop, none
  Timer? _mapMovementTimer;
  final RxList<Marker> markers = <Marker>[].obs;
  // أزلنا circles لأننا لن نستخدمها بشكل مباشر بعد الآن، الماركرات هي الحل
  // final RxList<CircleMarker> circles = <CircleMarker>[].obs;
  final Rx<LatLng> mapCenter =
      const LatLng(30.5090422, 47.7875914).obs; // Basra, Iraq
  final RxDouble mapZoom = 13.0.obs;
  final RxBool isMapReady = false.obs;
  bool _isMapInitialized = false; // لمنع إعادة التهيئة المتكررة
  static const String _riderCurrentLocationMarkerId =
      'rider_current_location_circle';

  final Rx<LatLng?> currentLocation =
      Rx<LatLng?>(null); // موقع المستخدم الحالي (ممكن يكون راكب أو سائق)
  final RxString currentAddress = ''.obs;

  // ✅ متغيرات منفصلة لنقطة الانطلاق
  final Rx<LatLng?> pickupLocation =
      Rx<LatLng?>(null); // نقطة الانطلاق المختارة
  final RxString pickupAddress = ''.obs; // عنوان نقطة الانطلاق

  final RxList<LocationSearchResult> searchResults =
      <LocationSearchResult>[].obs;
  final Rx<LatLng?> selectedLocation =
      Rx<LatLng?>(null); // يستخدم لنقطة الوصول عادةً
  final RxString selectedAddress = ''.obs;
  final RxBool isSearching = false.obs;

  final RxList<AdditionalStop> additionalStops = <AdditionalStop>[].obs;
  final RxInt maxAdditionalStops = 2.obs;

  final Rx<TripModel?> activeTrip = Rx<TripModel?>(null);

  final RxBool isLoading = false.obs;
  final TextEditingController searchController = TextEditingController();

  final LocationService _locationService = LocationService.to;

  Timer? _searchDebounceTimer;

  final RxBool isPickupConfirmed = false.obs;
  final RxBool isDestinationConfirmed = false.obs;

  // 📌 Stack لحفظ الخطوات (للرجوع للخلف)
  final RxList<String> actionHistory = <String>[].obs;

  final RxString currentPinAddress = ''.obs;

  bool _isDisposed = false;

  final Rx<LatLng?> driverLocation = Rx<LatLng?>(null);

  final RxList<Polyline> polylines = <Polyline>[].obs;
  LatLngBounds? _currentTripBounds;
final RxString userRole = 'rider'.obs; // أو 'driver'

  /// ✅ إعداد الخريطة لعرض الرحلة من جانب السائق
  void setupDriverTripView(TripModel trip, LatLng? driverCurrentLocation,
      {double bearing = 0.0}) {
    if (_isDisposed) return;

    logger.i('🗺️ [DRIVER VIEW] Setting up map for trip ${trip.id}');

    // ✅ التحقق من جاهزية الخريطة
    if (!isMapReady.value) {
      logger.w('⚠️ Map not ready yet, waiting...');
      // ✅ إعادة المحاولة بعد 500ms
      Future.delayed(const Duration(milliseconds: 500), () {
        if (isMapReady.value && !_isDisposed) {
          setupDriverTripView(trip, driverCurrentLocation, bearing: bearing);
        }
      });
      return;
    }

    // ✅ تأجيل التحديث حتى بعد اكتمال البناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;

      try {
        polylines.clear();

        TripMarkersManager.setupTripMarkers(
          markers: markers,
          trip: trip,
          driverLocation: driverCurrentLocation,
          driverBearing: bearing,
          isDriverView: true,
        );
        markers.refresh();

        // 📍 حساب وتعيين bounds بعد رسم الماركرز
        _calculateAndFitBounds(trip, driverCurrentLocation);
        
        // 🔍 تكبير/تصغير تلقائي بعد 0.3 ثانية
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!_isDisposed) fitBoundsToDriverTrip();
        });
      } catch (e) {
        logger.e('❌ Error in setupDriverTripView: $e');
      }
    });
  }
/// ✅ تحديث موقع الراكب في الوقت الفعلي أثناء الرحلة - محسّن للـ Release Mode
void updateRiderLocation(LatLng location) {
  if (_isDisposed) return;

  currentLocation.value = location;

  // ✅ تأجيل التحديث حتى بعد اكتمال البناء
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_isDisposed) return;
    
    // لو مفيش رحلة نشطة، استخدم الماركر العادي
    if (activeTrip.value == null) {
      _updateRiderCurrentLocationMarker(location);
    } else {
      // لو فيه رحلة نشطة، استخدم TripMarkersManager لتحديث ماركر الراكب داخل الرحلة
      TripMarkersManager.updateRiderLocationMarker(
        markers: markers,
        riderLocation: location,
      );
    }

    markers.refresh();
    logger.i('📍 تم تحديث موقع الراكب: ${location.latitude}, ${location.longitude}');
  });
}

  /// ✅ إعداد الخريطة لعرض الرحلة من جانب الراكب
  void setupRiderTripView(TripModel trip, LatLng? riderCurrentLocation,
      {LatLng? driverLocation, double driverBearing = 0.0}) {
    if (_isDisposed) return;

    logger.i('🗺️ [RIDER VIEW] Setting up map for trip ${trip.id}');

    // ✅ تأجيل التحديث حتى بعد اكتمال البناء لتجنب setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;

      polylines.clear();

      TripMarkersManager.setupTripMarkers(
        markers: markers,
        trip: trip,
        riderLocation: riderCurrentLocation,
        driverLocation: driverLocation,
        driverBearing: driverBearing,
        isDriverView: false,
      );
      markers.refresh();

      // 📍 حساب وتعيين bounds
      _calculateAndFitBounds(trip, driverLocation ?? riderCurrentLocation);
      
      // 🔍 تكبير/تصغير تلقائي
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_isDisposed) fitBoundsToDriverTrip();
      });
    });
  }

  /// ✅ تحديث موقع السائق في الوقت الفعلي - محسّن للـ Release Mode
  void updateDriverLocation(LatLng location,
      {double bearing = 0.0, String? tripId, TripModel? trip}) {
    if (_isDisposed) return;

    driverLocation.value = location;

    // ✅ تأجيل التحديث حتى بعد اكتمال البناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      
      // إذا كان هناك tripId، استخدم المدير الموحد
      if (tripId != null && tripId.isNotEmpty) {
        TripMarkersManager.updateDriverCarMarker(
          markers: markers,
          tripId: tripId,
          driverLocation: location,
          bearing: bearing,
        );
        
        // 🔍 تحديث bounds لو فيه trip
        if (trip != null && _currentTripBounds != null) {
          _calculateAndFitBounds(trip, location);
        }
      } else {
        markers.refresh();
        // للاستخدام في Driver Home (بدون tripId)
        updateDriverLocationMarker(location, bearing: bearing);
      }
    });
  }

  @override
  void onInit() {
    super.onInit();
    _initializeMap();
    _setupEnhancedListeners();
    _setupRiderLocationTracking(); // ✅ تفعيل تتبع موقع الراكب
  }

  /// ✅ تفعيل تتبع موقع الراكب الحي
  void _setupRiderLocationTracking() {
    final user = AuthController.to.currentUser.value;
    if (user == null || !user.isRider) return;

    // ✅ الاستماع لتغييرات الموقع من LocationService
    ever(LocationService.to.currentLocation, (LatLng? newLocation) {
      if (newLocation != null && !_isDisposed) {
        updateRiderLocation(newLocation);
      }
    });

    // ✅ بدء تتبع الموقع كل 5 ثواني
    LocationService.to.startLocationTracking(
      onLocationUpdate: (location) {
        if (!_isDisposed) {
          updateRiderLocation(location);
        }
      },
      intervalSeconds: 5,
    );

    logger.i('✅ تم تفعيل تتبع موقع الراكب');
  }

  void showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  void showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }

  @override
  void onClose() {
    _isDisposed = true;
    _mapMovementTimer?.cancel();
    _searchDebounceTimer?.cancel();
    mapController.dispose();
    searchController.dispose();
    super.onClose();
  }

// ✅ تهيئة الخريطة وجلب الموقع الأولي
  Future<void> _initializeMap() async {
    if (_isMapInitialized && isMapReady.value) {
      return;
    }

    isLoading.value = true;
    try {
      LatLng? location = await _locationService.getCurrentLocation();
      if (_isDisposed) return;

    if (location != null) {
  currentLocation.value = location;
  mapCenter.value = location;
  currentAddress.value = _locationService.currentAddress.value;
// UserModel? user;
final user = AuthController.to.currentUser.value;

 if (user != null && activeTrip.value == null) {
  if (user.isRider) {
    _updateRiderCurrentLocationMarker(location);
  } else if (user.isDriver) {
    updateDriverLocationMarker(location);
  }
}


  moveToLocation(location);
  isMapReady.value = true;
  _isMapInitialized = true;

} else {
        showErrorSnackbar("خطأ", "الموقع غير متاح حالياً");
      }
    } catch (e) {
      logger.f('خطأ في تهيئة الخريطة: $e');
      showErrorSnackbar("خطأ", 'تعذر تحميل الخريطة');
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  // ✅ تحديث ماركر الموقع الحالي للراكب (الدائرة الزرقاء)
  void _updateRiderCurrentLocationMarker(LatLng location) {
    // 🔥 فقط أضف الماركر لو مافيش رحلة نشطة
    // عشان مايتعارضش مع setupTripMarkers
    if (activeTrip.value == null) {
      TripMarkersManager.updateRiderLocationMarker(
        markers: markers,
        riderLocation: location,
      );
      logger.i('✅ تم إضافة/تحديث ماركر الموقع الحالي للراكب (دائرة)');
    } else {
      logger.d('⚠️ تخطي تحديث rider marker - فيه رحلة نشطة');
    }
  }

  // ✅ إضافة/تحديث ماركر بنوع معين (pickup, destination, additional_stop)
  // هذه الدالة ستضيف الـ PINs فقط
  void _addPinMarker({
    required LatLng location,
    required MarkerType
        markerType, // يجب أن تكون pickup, destination, additionalStop
    required String id,
    String? label,
    String? number,
    Color? color,
  }) {
    // نتأكد إن النوع صح عشان ما نضيفش دائرة عن طريق الخطأ
    assert(
      markerType == MarkerType.pickup ||
          markerType == MarkerType.destination ||
          markerType == MarkerType.additionalStop,
      'Can only add Pin Markers with _addPinMarker',
    );

    final newMarker = MapMarkerService.createMarker(
      type: markerType,
      location: location,
      id: id,
      label: label,
      number: number,
      color: color ?? PinColors.getColorForStep(markerType.name),
    );
    MapMarkerService.updateMarkerInList(markers, newMarker);
    logger.i('✅ تم إضافة ماركر ${markerType.name} (Pin) (ID: $id)');
  }

  /// ✅ تحديث ماركر السيارة في Driver Home فقط (بدون tripId)
  void updateDriverLocationMarker(LatLng location, {double bearing = 0.0}) {
    if (_isDisposed) return;

    // ✅ إزالة جميع ماركرز السيارة القديمة
    markers.removeWhere((m) {
      if (m.key is ValueKey) {
        final k = (m.key as ValueKey).value.toString();
        return k == 'driver_car' ||
            k.contains('driverCar_') ||
            k.startsWith('driver_car');
      }
      return false;
    });

    // ✅ إضافة ماركر واحد فقط بـ ID ثابت
    final newMarker = MapMarkerService.createMarker(
      type: MarkerType.driverCar,
      location: location,
      id: 'driver_car', // ✅ ID ثابت بدون timestamp
      bearing: bearing,
    );

    markers.add(newMarker);
    markers.refresh();
  }

  // ✅ إزالة ماركر الانطلاق
  void removePickupLocation() {
    isPickupConfirmed.value = false;
    // currentLocation.value = null; // لا نغير الموقع الحالي للراكب
    currentAddress.value = '';
    MapMarkerService.removeMarkerFromList(
        markers, 'pickup_point'); // استخدم الـ ID الثابت
    showSuccessSnackbar('تم حذف نقطة الانطلاق', 'اختر نقطة جديدة من الخريطة');
    Future.delayed(const Duration(milliseconds: 300), () {
      startLocationSelection('pickup');
    });
  }

  // ✅ إزالة ماركر الوصول
  void removeDestinationLocation() {
    isDestinationConfirmed.value = false;
    selectedLocation.value = null;
    selectedAddress.value = '';
    MapMarkerService.removeMarkerFromList(
        markers, 'destination_point'); // استخدم الـ ID الثابت
    showSuccessSnackbar('تم حذف نقطة الوصول', 'اختر نقطة جديدة من الخريطة');
    Future.delayed(const Duration(milliseconds: 300), () {
      startLocationSelection('destination');
    });
  }

  // ✅ دالة عامة لتأكيد نقطة الانطلاق
  Future<void> confirmPickupLocation(LatLng location, String address) async {
    if (_isDisposed) return;
    // ✅ حفظ نقطة الانطلاق في المتغيرات المنفصلة
    pickupLocation.value = location;
    pickupAddress.value = address;

    // لا نغير currentLocation.value هنا لأن ده موقع الراكب نفسه، مش نقطة الانطلاق
    // currentLocation.value = location; // لا
    currentAddress.value = address;
    isPickupConfirmed.value = true;
    actionHistory.add('pickup'); // 📌 حفظ الخطوة

    // ✅ حذف نقطة الانطلاق القديمة قبل إضافة الجديدة
    markers.removeWhere((m) => m.key.toString().contains('pickup_point'));

    // إضافة ماركر الانطلاق (الـ Pin)
    _addPinMarker(
      location: location,
      markerType: MarkerType.pickup,
      id: 'pickup_point', // ID ثابت
      label: 'انطلاق',
      number: '1',
      color: PinColors.getColorForStep('pickup'),
    );

    currentStep.value = 'none'; // انتهت خطوة اختيار نقطة الانطلاق
    showSuccessSnackbar(
        'تم تثبيت نقطة الانطلاق', 'يمكنك الآن اختيار نقطة الوصول');
    if (!isDestinationConfirmed.value && selectedLocation.value == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_isDisposed) {
        startLocationSelection('destination');
      }
    }
  }

  // ✅ دالة عامة لتأكيد نقطة الوصول
  Future<void> confirmDestinationLocation(
      LatLng location, String address) async {
    if (_isDisposed) return;
    selectedLocation.value = location;
    selectedAddress.value = address;
    isDestinationConfirmed.value = true;
    actionHistory.add('destination'); // 📌 حفظ الخطوة

    // ✅ حذف نقطة الوصول القديمة قبل إضافة الجديدة
    markers.removeWhere((m) => m.key.toString().contains('destination_point'));

    _addPinMarker(
      location: location,
      markerType: MarkerType.destination,
      id: 'destination_point', // ID ثابت
      label: 'وصول',
      number: '2',
      color: PinColors.getColorForStep('destination'),
    );
    currentStep.value = 'none'; // انتهت خطوة اختيار نقطة الوصول
    showSuccessSnackbar('تم تثبيت نقطة الوصول', address);
  }

 
  // ✅ إضافة نقطة توقف إضافية
  Future<void> _confirmAdditionalStop(LatLng location, String address) async {
    if (_isDisposed || additionalStops.length >= maxAdditionalStops.value) {
      showErrorSnackbar('لا يمكن إضافة المزيد من نقاط التوقف',
          'الحد الأقصى هو ${maxAdditionalStops.value}');
      return;
    }

    final int stopNumber =
        additionalStops.length + 3; // +2 للـ pickup و destination
    final String stopId =
        'stop_${DateTime.now().millisecondsSinceEpoch}'; // ID فريد لكل توقف جديد
    final AdditionalStop newStop = AdditionalStop(
      id: stopId,
      location: location,
      address: address,
      stopNumber: stopNumber,
    );
    additionalStops.add(newStop);
    actionHistory.add('stop_${newStop.id}'); // 📌 حفظ الخطوة

    _updateStopsMarkers(); // لتحديث كل ماركرات التوقف
    currentStep.value = 'none';

    showSuccessSnackbar('تم إضافة نقطة توقف', address);
  }

  // ✅ تحديث ماركرات نقاط التوقف الإضافية
  void _updateStopsMarkers() {
    // إزالة جميع ماركرات التوقف الإضافية القديمة
    markers.removeWhere((m) => m.key.toString().contains('additional_stop_'));

    // إضافة ماركرات جديدة لكل نقطة توقف
    for (int i = 0; i < additionalStops.length; i++) {
      final stop = additionalStops[i];
      _addPinMarker(
        location: stop.location,
        markerType: MarkerType.additionalStop,
        id: 'additional_stop_${stop.id}', // ID ثابت لكل نقطة
        label: 'توقف',
        number: (i + 3).toString(), // بدءًا من 3
        color: PinColors.getColorForStep('additional_stop'),
      );
    }
    markers.refresh(); // للتأكد من تحديث الـ UI
  }

 
  Future<void> refreshCurrentLocation() async {
    isLoading.value = true;
    try {
      LatLng? location = await _locationService.getCurrentLocation();
      if (_isDisposed) return;
      if (location != null) {
        currentLocation.value = location;
        _updateRiderCurrentLocationMarker(
            location); // تحديث ماركر الموقع الحالي للراكب
        moveToLocation(location, zoom: 16.0);
        // لا نبدأ اختيار نقطة الانطلاق تلقائيًا هنا، هذا يتم يدوياً
      } else {
        showErrorSnackbar("خطاء", 'تعذر تحديث الموقع الحالي');
      }
    } finally {
      if (!_isDisposed) isLoading.value = false;
    }
  }

  // 🔙 الرجوع خطوة واحدة للخلف (undo)
  bool undoLastAction() {
    if (actionHistory.isEmpty) return false;

    final lastAction = actionHistory.removeLast();
    logger.i('🔙 إلغاء الخطوة: $lastAction');

    if (lastAction.startsWith('stop_')) {
      // مسح نقطة توقف إضافية
      final stopId = lastAction.replaceFirst('stop_', '');
      logger.d('🗑️ حذف Stop ID: additional_stop_$stopId');
      additionalStops.removeWhere((stop) => stop.id == stopId);
      MapMarkerService.removeMarkerFromList(markers, 'additional_stop_$stopId');
      _updateStopsMarkers();
    } else if (lastAction == 'destination') {
      // مسح نقطة الوصول
      logger.d('🗑️ حذف Destination Marker: destination_point');
      isDestinationConfirmed.value = false;
      selectedLocation.value = null;
      selectedAddress.value = '';
      MapMarkerService.removeMarkerFromList(markers, 'destination_point');
    } else if (lastAction == 'pickup') {
      // مسح نقطة الانطلاق
      logger.d('🗑️ حذف Pickup Marker: pickup_point');
      isPickupConfirmed.value = false;
      pickupLocation.value = null;
      pickupAddress.value = '';
      MapMarkerService.removeMarkerFromList(markers, 'pickup_point');
    }

    markers.refresh(); // ✅ تحديث الخريطة فوراً
    logger.i('✅ تم حذف الماركر - عدد الماركرز المتبقية: ${markers.length}');
    return true;
  }

  // ✅ مسح جميع Markers وإعادة تعيين الحالات
  void clearMap() {
    actionHistory.clear(); // 📌 مسح السجل
    MapMarkerService.clearAllMarkers(markers);
    // circles.clear(); // لم نعد نستخدم circles
    selectedLocation.value = null;
    selectedAddress.value = '';
    isPickupConfirmed.value = false;
    isDestinationConfirmed.value = false;
    currentStep.value = 'none';
    showConfirmButton.value = false;
    additionalStops.clear();
    searchController.clear();
    logger.i('تم مسح الخريطة بنجاح');
    // بعد المسح، نعيد إضافة ماركر الموقع الحالي للراكب إذا كان معروفاً
    if (currentLocation.value != null) {
      _updateRiderCurrentLocationMarker(currentLocation.value!);
    }
    polylines.clear();
    markers.refresh();
  }

   void _onMapMovement() {
    if (_isDisposed) return;

    if (!isMapMoving.value) {
      isMapMoving.value = true;
      showConfirmButton.value = false;
      currentPinAddress.value = 'جاري تحديد الموقع...';
    }

    _mapMovementTimer?.cancel();
    _mapMovementTimer = Timer(const Duration(milliseconds: 50), () async {
      if (_isDisposed) return;

      isMapMoving.value = false;
      if (currentStep.value == 'none') {
        return;
      }

      try {
        final currentCenter =
            mapController.camera.center; // استخدم مركز الكاميرا مباشرة
        final address =
            await _locationService.getAddressFromLocation(currentCenter);

        if (!_isDisposed) {
          currentPinAddress.value =
              address.isNotEmpty ? address : 'الموقع الحالي على الخريطة';
          showConfirmButton.value = true;
          centerPinLocation.value = currentCenter;
        }
      } catch (e) {
        if (!_isDisposed) {
          currentPinAddress.value = 'موقعك الحالي على الخريطة';
          showConfirmButton.value = true;
        }
      }
    });
  }

  // ✅ بدء عملية اختيار الموقع (pickup, destination, additional_stop)
  void startLocationSelection(String step) {
    if (_isDisposed) return;
    currentStep.value = step;
    showConfirmButton.value = false;
    currentPinAddress.value = '';

    LatLng? targetLocation;
    double targetZoom = 16.5;

    if (step == 'pickup' && currentLocation.value != null) {
      targetLocation = currentLocation.value; // اذهب لموقع المستخدم الحالي
    } else if (step == 'destination' && selectedLocation.value != null) {
      targetLocation = selectedLocation.value; // اذهب لآخر نقطة وصول محددة
    } else {
      targetLocation = mapCenter.value; // ابقَ حيث أنت على الخريطة
    }

    // تأكد من أن targetLocation ليس null قبل التحريك
    if (targetLocation != null) {
      moveToLocation(targetLocation, zoom: targetZoom);
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_isDisposed && currentStep.value == step) {
        _onMapMovement();
      }
    });
  }

  // ✅ الاستماع لتغييرات مركز الخريطة لتحديث العنوان
  void _setupEnhancedListeners() {
    debounce(mapCenter, (LatLng center) {
      if (!_isDisposed) {
        _onMapMovement();
      }
    }, time: const Duration(milliseconds: 300));
  }

  // ✅ تأكيد الموقع المحدد بالـ pin في منتصف الشاشة
  Future<void> confirmPinLocation() async {
    if (_isDisposed || currentStep.value == 'none' || isMapMoving.value) {
      return;
    }

    final LatLng pinLocation = mapController.camera.center;
    isLoading.value = true;
    showConfirmButton.value = false;

    try {
      String address = currentPinAddress.value;
      if (address.isEmpty || address == 'جاري تحديد الموقع...') {
        address = await _locationService.getAddressFromLocation(pinLocation);
      }
      if (_isDisposed) return;

      switch (currentStep.value) {
        case 'pickup':
          await confirmPickupLocation(pinLocation, address);
          break;
        case 'destination':
          await confirmDestinationLocation(pinLocation, address); // دالة واحدة
          break;
        case 'additional_stop':
          await _confirmAdditionalStop(pinLocation, address);
          break;
      }
    } catch (e) {
      logger.e('خطأ في تأكيد موقع الـ Pin: $e');
      showErrorSnackbar("خطاء", 'تعذر تحديد الموقع المطلوب');
    } finally {
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  // ✅ إزالة نقطة توقف إضافية
  void removeAdditionalStop(String stopId) {
    additionalStops.removeWhere((stop) => stop.id == stopId);
    _updateStopsMarkers(); // إعادة رسم الماركرات
    showSuccessSnackbar('تم حذف نقطة التوقف', 'تم تحديث المسار');
  }
void moveToLocation(LatLng location, {double zoom = 16.0}) async {
  if (_isDisposed) return;

  // انتظار جاهزية الخريطة
  if (!isMapReady.value) {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  try {
    mapController.move(location, zoom);
  } catch (e) {
    logger.w('⚠️ تم تجاهل خطأ في تحريك الخريطة: $e');
  }
}

  // void moveToLocation(LatLng location, {double zoom = 16.0}) {
  //   if (_isDisposed || !isMapReady.value) return;
  //   try {
  //     mapController.move(location, zoom);
  //   } catch (e) {
  //     logger.w('تم تجاهل خطأ في تحريك الخريطة: $e');
  //   }
  // }

  void resetMapToInitialState() {
    clearMap();
    _isMapInitialized = false; // للسماح بإعادة التهيئة الكاملة
    isMapReady.value = false;
    _initializeMap();
  }

  /// ✅ مسح جميع Markers المتعلقة بالرحلة وإبقاء فقط marker الموقع الحالي
  void clearTripMarkersKeepUserLocation() {
    actionHistory.clear(); // 📌 مسح السجل
    // حفظ marker الموقع الحالي للراكب
    Marker? userLocationMarker;
    try {
      userLocationMarker = markers.firstWhereOrNull((m) {
        if (m.key is ValueKey) {
          final key = (m.key as ValueKey).value.toString();
          return key.contains('riderLocationCircle') || key == 'rider';
        }
        return false;
      });
    } catch (e) {
      logger.w('خطأ في البحث عن marker الموقع: $e');
    }

    // مسح كل شيء
    markers.clear();
    polylines.clear();

    // إعادة إضافة marker الموقع الحالي فقط
    if (userLocationMarker != null) {
      markers.add(userLocationMarker);
    } else if (currentLocation.value != null) {
      // إذا لم يكن موجود، أنشئ واحد جديد
      _updateRiderCurrentLocationMarker(currentLocation.value!);
    }

    // إعادة تعيين الحالات
    selectedLocation.value = null;
    selectedAddress.value = '';
    isPickupConfirmed.value = false;
    isDestinationConfirmed.value = false;
    currentStep.value = 'none';
    additionalStops.clear();

    logger.i('✅ تم تنظيف جميع ماركرز الرحلة مع الاحتفاظ بموقع المستخدم');
  }

  // ✅ دالة للحفاظ على MapController نشطًا
  void keepMapAlive() {
    // هذه الدالة قد لا تكون ضرورية بالقدر الذي تعتقد
    // GetXController يقوم بإدارة دورة الحياة بشكل جيد.
  }

  /// ✅ مسح جميع الـ Markers عند الانتهاء
  void clearAllLocationMarkers() {
    MapMarkerService.clearAllMarkers(markers);
  }
  
  void animatedMapMove(
  LatLng destLocation,
  double destZoom,
  TickerProvider vsync,
) {
  // 📍 1. لو مفيش موقع حالي، نخرج
  if (currentLocation.value == null) return;

  final current = currentLocation.value!;
  final distanceMoved = const Distance().as(
    LengthUnit.Meter,
    current,
    destLocation,
  );

  // 📏 2. لو الفرق في المسافة صغير (أقل من 5 متر مثلاً) → متعملش animation
  if (distanceMoved < 5) return;

  // 🔍 3. خليك على نفس الزوم الحالي لو المستخدم مكبّر أو مصغّر الخريطة
  final double effectiveZoom =
      (destZoom - mapZoom.value).abs() < 0.01 ? mapZoom.value : destZoom;

  final latTween = Tween<double>(
    begin: current.latitude,
    end: destLocation.latitude,
  );
  final lngTween = Tween<double>(
    begin: current.longitude,
    end: destLocation.longitude,
  );

  final controller = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: vsync,
  );

  final animation = CurvedAnimation(
    parent: controller,
    curve: Curves.easeInOut,
  );

controller.addListener(() {
  if (_isDisposed) {
    controller.stop();
    controller.dispose();
    return;
  }
  mapController.move(
    LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
    effectiveZoom,
  );
});


  controller.addStatusListener((status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      controller.dispose();
    }
  });

  controller.forward();
}

    // ✅ دالة لمسح نقطة الانطلاق
  void clearPickupLocation() {
    pickupLocation.value = null;
    pickupAddress.value = '';
    isPickupConfirmed.value = false;

    // مسح ماركر نقطة الانطلاق من الخريطة
    markers.removeWhere(
        (marker) => marker.key?.toString().contains('pickup_point') == true);
  }

  void _calculateAndFitBounds(TripModel trip, LatLng? driverLocation) {
    final List<LatLng> points = [
      trip.pickupLocation.latLng,
      trip.destinationLocation.latLng,
      ...trip.additionalStops.map((s) => s.location),
      if (driverLocation != null) driverLocation,
    ];

    if (points.length > 1) {
      try {
        _currentTripBounds = LatLngBounds.fromPoints(points);
      } catch (e) {
        logger.w('⚠️ خطأ في حساب bounds: $e');
      }
    }
  }

// 🔍 تكبير/تصغير الخريطة تلقائيًا لاستيعاب جميع النقاط
  void fitBoundsToDriverTrip() {
    if (_currentTripBounds == null || _isDisposed || !isMapReady.value) {
      return;
    }

    try {
      mapController.fitCamera(
        CameraFit.bounds(
          bounds: _currentTripBounds!,
          padding: const EdgeInsets.all(80.0), // هامش كافٍ حول المسار
          maxZoom: 17.0, // حد أقصى للتكبير
        ),
      );
      logger.i('✅ تم تعديل zoom لاستيعاب جميع النقاط');
    } catch (e) {
      logger.w('⚠️ خطأ في fit bounds: $e');
    }
  }

 

/// ✅ مسح جميع Markers المتعلقة بالرحلة وماركر السائق (السيارة)
void clearAllTripAndDriverMarkers() {
  if (_isDisposed) return;

  // إزالة جميع ماركرز الرحلات (بما في ذلك نقاط الانطلاق، الوصول، التوقف)
  TripMarkersManager.clearAllTripMarkers(markers);

  // إزالة ماركر السائق العام (السيارة)
  markers.removeWhere((m) {
    if (m.key is ValueKey) {
      final k = (m.key as ValueKey).value.toString();
      // 'driver_car' هو الـ ID الثابت لماركر السائق في Driver Home
      return k == 'driver_car' || k.startsWith('driverCar_') || k.startsWith('driver_car_trip_');
    }
    return false;
  });

  // إزالة ماركر الموقع الحالي للراكب إذا كان موجوداً
  markers.removeWhere((m) {
    if (m.key is ValueKey) {
      final k = (m.key as ValueKey).value.toString();
      return k.contains('riderLocationCircle');
    }
    return false;
  });


  polylines.clear();
  _currentTripBounds = null;
  selectedLocation.value = null;
  selectedAddress.value = '';
  isPickupConfirmed.value = false;
  isDestinationConfirmed.value = false;
  currentStep.value = 'none';
  additionalStops.clear();

  markers.refresh(); // ✅ تحديث الـ UI
  logger.i('✅ تم تنظيف جميع ماركرز الرحلات والسائق');
}


// تعديل دالة clearTripMarkers الحالية لتستدعي الدالة الجديدة
@override
void clearTripMarkers({String? tripId}) {
  if (_isDisposed) return;

  if (tripId != null && tripId.isNotEmpty) {
    // إذا تم تحديد tripId، نظف ماركرز تلك الرحلة فقط
    TripMarkersManager.clearTripMarkers(markers, tripId);

    // وتأكد من إزالة ماركر السائق إذا كان تابعاً لهذه الرحلة
    markers.removeWhere((m) {
      if (m.key is ValueKey) {
        final k = (m.key as ValueKey).value.toString();
        // ID ماركر السائق أثناء الرحلة يكون على شكل 'driverCar_trip_TRIP_ID'
        return k == 'driverCar_trip_$tripId';
      }
      return false;
    });

  } else {
    // إذا لم يتم تحديد tripId، قم بتنظيف جميع ماركرز الرحلات والسائق العام
    clearAllTripAndDriverMarkers();
  }

  polylines.clear();
  _currentTripBounds = null;
  markers.refresh();
  logger.i('✅ تم تنظيف ماركرز الرحلة (أو كل الماركرز إذا لم يحدد TripId)');
}
  // /// ✅ تنظيف ماركرز رحلة معينة
  // void clearTripMarkers({String? tripId}) {
  //   if (tripId != null && tripId.isNotEmpty) {
  //     TripMarkersManager.clearTripMarkers(markers, tripId);
  //   } else {
  //     // تنظيف جميع ماركرز الرحلات باستخدام الـ manager
  //     TripMarkersManager.clearAllTripMarkers(markers);
  //     markers.refresh();
  //   }

  //   polylines.clear();
  //   _currentTripBounds = null;
  //   logger.i('✅ تم تنظيف ماركرز الرحلة');
  // }

  // ✅ دالة البحث عن الموقع
  Future<void> searchLocation(String query) async {
    if (_isDisposed || query.trim().isEmpty) return;

    isSearching.value = true;
    _searchDebounceTimer?.cancel();

    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await _locationService.searchLocation(query);
        if (!_isDisposed) {
          searchResults.value = results;
        }
      } catch (e) {
        logger.e('خطأ في البحث: $e');
        searchResults.clear();
      } finally {
        if (!_isDisposed) {
          isSearching.value = false;
        }
      }
    });
  }

  // ✅ دالة اختيار نتيجة البحث - فقط الانتقال للموقع بدون تثبيت
  void selectSearchResult(LocationSearchResult result) {
    if (_isDisposed) return;

    // تحريك الخريطة للموقع فقط
    moveToLocation(result.latLng, zoom: 16.0);

    // حفظ العنوان لاستخدامه عند التثبيت
    currentPinAddress.value = result.address;
    
    // إظهار زر التأكيد ليتمكن المستخدم من التحرك والتثبيت
    showConfirmButton.value = true;

    // مسح نتائج البحث
    searchResults.clear();
    searchController.clear();
  }
}
