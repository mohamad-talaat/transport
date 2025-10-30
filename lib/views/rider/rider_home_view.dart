import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/app_settings_service.dart';
import 'package:transport_app/services/location_service.dart';
import 'package:transport_app/services/map_services/map_singleton_service.dart';
import 'package:transport_app/services/map_services/map_marker_service.dart';

import 'package:transport_app/views/rider/rider_widgets/drawer.dart';
import 'package:transport_app/views/rider/rider_widgets/go_to_my_current_location.dart';
import 'package:transport_app/views/rider/rider_widgets/top_search_bar.dart';
import 'package:transport_app/views/rider/rider_widgets/center_location_pin.dart';
import 'package:transport_app/views/rider/rider_widgets/location_confirmation_section.dart';
import 'package:transport_app/utils/iraqi_currency_helper.dart';

// ✅ استيراد الـ Widgets الجديدة
import 'package:transport_app/views/rider/rider_home_widgets/booking_bottom_sheet.dart';
import 'package:transport_app/views/rider/rider_home_widgets/balance_display.dart';
import 'package:transport_app/views/rider/rider_home_widgets/selection_cancel_button.dart';

class RiderHomeView extends StatefulWidget {
  const RiderHomeView({super.key});

  @override
  State<RiderHomeView> createState() => _RiderHomeViewState();
}

class _RiderHomeViewState extends State<RiderHomeView>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthController authController = Get.find<AuthController>();
  final MyMapController mapController =
      Get.put(MyMapController(), permanent: true);
  final TripController tripController =
      Get.put(TripController(), permanent: true);
  final map = MapController();

  final RxBool isPlusTrip = false.obs;
  final RxBool isRoundTrip = false.obs;
  final RxInt waitingTime = 0.obs;
  final RxDouble baseFare = 0.0.obs;
  final RxDouble totalFare = 0.0.obs;
  final RxString paymentMethod = 'cash'.obs;
  final RxString appliedDiscountCode = ''.obs;

  bool _isDisposed = false; 
  final RxBool shouldShowBottomSheet = false.obs;

  late AnimationController _slideController;
  late AnimationController _priceAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _priceAnimation;

  final DraggableScrollableController _bottomSheetController =
      DraggableScrollableController();

  RiderType? riderType;
  final GetStorage storage = GetStorage();
  final AppSettingsService _appSettingsService =
      Get.find<AppSettingsService>(); // ✅ جلب خدمة إعدادات التطبيق

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    if (args != null && args['type'] != null) {
      riderType = args['type'];
      _saveSelectedRiderType(riderType!);
    } else {
      riderType = _getSavedRiderType();
    }

    // ✅ مسح الماركرز القديمة وإبقاء الدائرة الزرقاء فقط
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        // ✅ تنظيف شامل لكل ماركرز الرحلات والسائق
        mapController.clearAllTripAndDriverMarkers();
        
        // ✅ إعادة إضافة ماركر موقع الراكب (الدائرة الزرقاء) إذا كان معروفاً
        if (mapController.currentLocation.value != null) {
          mapController.updateRiderLocation(mapController.currentLocation.value!);
        }
      }
    });

    _initializeAnimations();
    _setupLocationListeners();
    _checkUserProfile();
    _setupConditionalBottomSheetVisibility();
    _setupLocationListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _quickStart();
    });

    // ✅ متابعة ذكية للتغييرات - مع ضمان عدم اختفاء Bottom Sheet
    ever(mapController.actionHistory, (_) {
      // لو فيه pickup & destination مأكدين، احسب الأجرة
      if (mapController.isPickupConfirmed.value &&
          mapController.isDestinationConfirmed.value) {
        _calculateFare();
      }
    });

    // الاستماع للتغييرات لحساب الأجرة
    ever(mapController.isPickupConfirmed, (_) => _calculateFare());
    ever(mapController.isDestinationConfirmed, (_) => _calculateFare());
    ever(mapController.additionalStops, (_) => _calculateFare());
    ever(isPlusTrip, (_) => _calculateFare());
    ever(isRoundTrip, (_) => _calculateFare());
    ever(waitingTime, (_) => _calculateFare());
    // ✅ الاستماع لتغييرات الإعدادات لحساب الأجرة إذا تم تحديثها من الـ backend
    ever(_appSettingsService.currentSettings, (_) => _calculateFare());
  }
    void _saveSelectedRiderType(RiderType type) {
    storage.write('selected_rider_type', type.name);
  }

  RiderType? _getSavedRiderType() {
    final saved = storage.read('selected_rider_type');
    if (saved != null) {
      try {
        return RiderType.values.firstWhere((e) => e.name == saved);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  bool _userMovedMapManually = false;

  void _setupLocationListeners() {
    ever(mapController.currentLocation, (location) {
      if (location != null && !_isDisposed) {
        _updateRiderMarker(location);
      }
    });

    LocationService.to.startLocationTracking(
      onLocationUpdate: (newLocation) {
        if (!_isDisposed) {
          mapController.updateRiderLocation(newLocation);
        }
      },
      intervalSeconds: 3,
    );
  }

  void _updateRiderMarker(LatLng location) {
    final newMarker = MapMarkerService.createMarker(
      type: MarkerType.riderLocationCircle,
      location: location,
      id: 'rider',
    );

    MapMarkerService.updateMarkerInList(mapController.markers, newMarker);
    mapController.markers.refresh();

    // ✅ لو المستخدم ما حرّكش الخريطة يدويًا، خليه في النص
    if (!_userMovedMapManually && !_isDisposed) {
      try {
        mapController.mapController.move(
          location,
          mapController.mapController.camera.zoom,
        );
        mapController.mapCenter.value = location;
      } catch (e) {
        logger.w('خطأ في تحريك الخريطة: $e');
      }
    }
  }

  // void _setupLocationListeners() {
  //   // ✅ الاستماع لتحديثات الموقع الحالي للمستخدم
  //   ever(mapController.currentLocation, (location) {
  //     if (location != null && !_isDisposed) {
  //       _updateRiderMarker(location);
  //     }
  //   });

  //   // ✅ بدء الاستماع لتحديثات GPS
  //   LocationService.to.startLocationTracking(
  //     onLocationUpdate: (newLocation) {
  //       if (!_isDisposed) {
  //         mapController.currentLocation.value = newLocation;
  //       }
  //     },
  //     intervalSeconds: 5,
  //   );
  // }

  // void _updateRiderMarker(LatLng location) {
  //   // ✅ تحديث marker الموقع الحالي للراكب (الدائرة الزرقاء)
  //   final newMarker = MapMarkerService.createMarker(
  //     type: MarkerType.riderLocationCircle,
  //     location: location,
  //     id: 'rider',
  //   );

  //   MapMarkerService.updateMarkerInList(mapController.markers, newMarker);

  //   // ✅ تحريك الخريطة لتبقى الماركر في المنتصف
  //   if (!_isDisposed) {
  //     try {
  //       mapController.mapController.move(
  //         location,
  //         mapController.mapController.camera.zoom,
  //       );
  //       mapController.mapCenter.value = location;
  //     } catch (e) {
  //       logger.w('خطأ في تحريك الخريطة: $e');
  //     }
  //   }
  // }



  Future<void> _quickStart() async {
    if (_isDisposed) return;

    try {
      // ✅ تنظيف شامل للماركرز قبل البدء
      mapController.clearAllTripAndDriverMarkers();
      
      await _checkActiveTripAndRedirect();

      if (_isDisposed || Get.currentRoute != AppRoutes.RIDER_HOME) return;

      await mapController.refreshCurrentLocation();

      if (_isDisposed) return;

      if (mapController.currentLocation.value != null) {
        mapController.startLocationSelection('pickup');
        _hideBottomSheetForSelection();
      }
    } catch (e) {
      logger.e("Error during quick start: $e");
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _slideController.dispose();
    _priceAnimationController.dispose();
    _bottomSheetController.dispose();
    super.dispose();
  }

  void _hideBottomSheetForSelection() {
    if (_isDisposed) return;
    if (shouldShowBottomSheet.value) {
      shouldShowBottomSheet.value = false;
      if (_bottomSheetController.isAttached) {
        _bottomSheetController.animateTo(0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      }
    }
  }

  void _showBottomSheetAfterSelection() {
    if (_isDisposed) return;
    if (!shouldShowBottomSheet.value) {
      shouldShowBottomSheet.value = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed &&
          shouldShowBottomSheet.value &&
          _bottomSheetController.isAttached &&
          _bottomSheetController.size < 0.35) {
        try {
          _bottomSheetController.animateTo(
            0.35,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } catch (e) {
          logger.e("Error animating DraggableScrollableController: $e");
        }
      }
    });
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _priceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _priceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _priceAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  void _setupConditionalBottomSheetVisibility() {
    ever(mapController.currentStep, (String step) {
      if (_isDisposed) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed) return;
        if (step != 'none') {
          _hideBottomSheetForSelection();
        } else {
          _evaluateAndShowBottomSheet();
        }
      });
    });

    ever(mapController.isPickupConfirmed, (_) => _evaluateAndShowBottomSheet());
    ever(mapController.isDestinationConfirmed,
        (_) => _evaluateAndShowBottomSheet());

    // ✅ متابعة actionHistory لضمان عدم اختفاء Bottom Sheet
    ever(mapController.actionHistory, (_) => _evaluateAndShowBottomSheet());
  }

  void _evaluateAndShowBottomSheet() {
    if (_isDisposed) return;

    final bool isSelectionActive = mapController.currentStep.value != 'none';
    final bool hasRequiredLocations = mapController.isPickupConfirmed.value &&
        mapController.isDestinationConfirmed.value;

    if (!isSelectionActive && hasRequiredLocations) {
      _showBottomSheetAfterSelection();
    } else {
      _hideBottomSheetForSelection();
    }
  }

  void _toggleBottomSheet() {
    if (!_isDisposed && shouldShowBottomSheet.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed || !_bottomSheetController.isAttached) {
          return;
        }

        try {
          double currentSize = _bottomSheetController.size;
          double targetSize = currentSize > 0.35 ? 0.35 : 0.1;
          if (currentSize == 0.1) {
            targetSize = 0.35;
          } else if (currentSize == 0.35) targetSize = 0.1;

          _bottomSheetController.animateTo(
            targetSize,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } catch (e) {
          logger.e("Error animating DraggableScrollableController: $e");
        }
      });
    }
  }

  void _checkUserProfile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = authController.currentUser.value;
      if (user != null) {
        final bool missingName = ((user.name).trim().isEmpty);
        final bool missingPhone = ((user.phone).trim().isEmpty);
        if (missingName || missingPhone) {
          Get.toNamed(AppRoutes.RIDER_PROFILE_COMPLETION);
        }
      }
    });
  }

  void _animatePriceChange() {
    if (_isDisposed) return;
    try {
      _priceAnimationController.reset();
      _priceAnimationController.forward();
    } catch (e) {
      // Handle or log error if animation fails to start
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
 onWillPop: () async {
  // 🔹 حالة 1: لو في اختيار جاري (مش مؤكد بعد)
  if (mapController.currentStep.value != 'none') {
    mapController.currentStep.value = 'none';
    mapController.showConfirmButton.value = false;
    return false;
  }

  // 🔹 حالة 2: لو في خطوات محفوظة، ارجع خطوة للخلف
  if (mapController.actionHistory.isNotEmpty) {
    mapController.undoLastAction();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mapController.isPickupConfirmed.value) {
        mapController.startLocationSelection('pickup');
      } else if (!mapController.isDestinationConfirmed.value) {
        mapController.startLocationSelection('destination');
      }
    });

    return false;
  }

  // 🔹 حالة 3: مفيش حاجة متحددة، اخرج فورًا بدون سؤال
  mapController.clearTripMarkersKeepUserLocation();
  isPlusTrip.value = false;
  isRoundTrip.value = false;
  waitingTime.value = 0;
  totalFare.value = 0.0;
  baseFare.value = 0.0;
  paymentMethod.value = 'cash';
  appliedDiscountCode.value = '';
  shouldShowBottomSheet.value = false;

  return true; // ← خروج مباشر بدون أي حوار
},

 
      child: Scaffold(
        key: _scaffoldKey,
        drawer: RiderDrawer(authController: authController),
        body: Stack(
          children: [
            // Map
            Obx(() => QuickMap.forHome(
                  mapController.mapController,
                  mapController.mapCenter.value,
                16  ,    
                mapController.markers,
                
                  onPositionChanged: (camera, hasGesture) {
                    if (hasGesture) {
                      _userMovedMapManually = true;
                    } else {
                      _userMovedMapManually = false;
                    }
                    mapController.mapCenter.value = camera.center;
                  },
                )),

            LocationConfirmationSection(
              mapController: mapController,
              onConfirm: _confirmCurrentLocation,
            ),
            CenterLocationPin(mapController: mapController),
            const ExpandableSearchBar(),
            const SearchResultsOverlay(),
            // ✅ استخدام الـ Widget الجديد للزر إلغاء
            SelectionCancelButton(
              mapController: mapController,
              onCancel: _showBottomSheetAfterSelection,
            ),
            // ✅ استخدام الـ Widget الجديد لعرض الرصيد
            BalanceDisplay(authController: authController),
            GoToMyLocationButton(onPressed: () {
              if (mapController.currentLocation.value != null) {
                mapController.mapController.move(
                  mapController.currentLocation.value!,
                  16.0,
                );
              }
            }), // ✅ استخدام الـ Widget الجديد للـ Bottom Sheet
            Obx(() {
              if (shouldShowBottomSheet.value) {
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  bottom: 5,
                  left: 5,
                  right: 5,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: IntrinsicHeight(
                      child: BookingBottomSheet(
                        bottomSheetController: _bottomSheetController,
                        mapController: mapController,
                        authController: authController,
                        tripController: tripController,
                        riderType: riderType,
                        isPlusTrip: isPlusTrip,
                        isRoundTrip: isRoundTrip,
                        waitingTime: waitingTime,
                        totalFare: totalFare,
                        paymentMethod: paymentMethod,
                        appliedDiscountCode: appliedDiscountCode,
                        onToggleBottomSheet: _toggleBottomSheet,
                        onHideBottomSheet: _hideBottomSheetForSelection,
                        onShowBottomSheet: _showBottomSheetAfterSelection,
                        onCalculateFare: _calculateFare,
                        onAnimatePriceChange: _animatePriceChange,
                        onRequestTrip: _requestTrip,
                        onShowError: _showError,
                        priceAnimation: _priceAnimation,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCurrentLocation() async {
    try {
      await mapController
          .confirmPinLocation()
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      _showError('انتهت مهلة العملية، يرجى المحاولة مرة أخرى');
    } catch (e) {
      _showError('حدث خطأ غير متوقع أثناء تثبيت الموقع');
      logger.w('خطأ في تأكيد الموقع: $e');
    }
  }

  void _calculateFare() {
    if (_isDisposed) return;

    if (mapController.pickupLocation.value == null ||
        mapController.selectedLocation.value == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;

      if (mapController.currentLocation.value == null ||
          mapController.selectedLocation.value == null) {
        return;
      }

      final from = mapController.pickupLocation.value!;
      final to = mapController.selectedLocation.value!;
      final distanceKm = LocationService.to.calculateDistance(from, to);

      // ✅ جلب الإعدادات من AppSettingsService أو استخدام القيم الافتراضية
      final settings = _appSettingsService.currentSettings.value;

      double baseFareAmount = settings?.baseFare ?? 2000.0;
      double pricePerKm = settings?.perKmRate ?? 750.0;
      double minimumFare = settings?.minimumFare ?? 3000.0;
      double plusTripFee = settings?.plusTripSurcharge ?? 1000.0;
      double additionalStopFee = settings?.additionalStopCost ?? 1000.0;
      double waitingMinuteFee = settings?.waitingMinuteCost ?? 50.0;
      double roundTripMult = settings?.roundTripMultiplier ?? 1.75;

      // حساب الأجرة الأساسية
      double fareIQD = baseFareAmount + (distanceKm * pricePerKm);
      fareIQD = math.max(fareIQD, minimumFare);

      if (isPlusTrip.value) {
        fareIQD += plusTripFee;
      }

      fareIQD += mapController.additionalStops.length * additionalStopFee;
      fareIQD += waitingTime.value * waitingMinuteFee;

      if (isRoundTrip.value) {
        fareIQD *= roundTripMult;
      }

      fareIQD = IraqiCurrencyHelper.roundToNearest250(fareIQD);

      baseFare.value = fareIQD;
      totalFare.value = baseFare.value;

      _animatePriceChange();
    });
  }

  Future<void> _checkActiveTripAndRedirect() async {
    await tripController.checkActiveTrip();
    final activeTrip = tripController.activeTrip.value;

    if (activeTrip != null &&
        activeTrip.status != TripStatus.cancelled &&
        activeTrip.status != TripStatus.completed) {
      Get.offNamed(AppRoutes.RIDER_TRIP_TRACKING);

      Get.snackbar(
        'رحلة نشطة',
        'لديك رحلة جارية، تم نقلك لصفحة المتابعة',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _requestTrip({bool isRush = false}) async {
    await tripController.checkActiveTrip();
    final activeTrip = tripController.activeTrip.value;
    if (activeTrip != null &&
        activeTrip.status != TripStatus.cancelled &&
        activeTrip.status != TripStatus.completed) {
      Get.snackbar(
        'رحلة نشطة',
        'لا يمكنك طلب رحلة جديدة، لديك رحلة جارية حالياً',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      Get.offNamed(AppRoutes.RIDER_TRIP_TRACKING);
      return;
    }
    if (_isDisposed ||
        mapController.pickupLocation.value == null ||
        mapController.selectedLocation.value == null) {
      if (!_isDisposed) {
        _showError('يرجى تحديد نقطة البداية والوجهة');
      }
      return;
    }

    // ✅ استخدام نقطة الانطلاق المختارة بدلاً من الكرنت لوكيشن
    final pickupLatLng = mapController.pickupLocation.value!;
    final destLatLng = mapController.selectedLocation.value!;

    String pickupAddress = mapController.pickupAddress.value;
    if (pickupAddress.isEmpty) {
      pickupAddress =
          await LocationService.to.getAddressFromLocation(pickupLatLng);
      if (_isDisposed) return;
    }

    String destinationAddress = mapController.selectedAddress.value;
    if (destinationAddress.isEmpty) {
      destinationAddress =
          await LocationService.to.getAddressFromLocation(destLatLng);
      if (_isDisposed) return;
    }

    final pickup = LocationPoint(
        lat: pickupLatLng.latitude,
        lng: pickupLatLng.longitude,
        address: pickupAddress);

    final destination = LocationPoint(
        lat: destLatLng.latitude,
        lng: destLatLng.longitude,
        address: destinationAddress);

    final tripDetails = {
      'isPlusTrip': isPlusTrip.value,
      'additionalStops': mapController.additionalStops
          .toList(), // ✅ ابعت AdditionalStop مباشرة
      'isRoundTrip': isRoundTrip.value,
      'waitingTime': waitingTime.value,
      'totalFare': totalFare.value,
      'isRush': isRush,
      'paymentMethod': paymentMethod.value,
      'skipPaymentPage': paymentMethod.value == 'cash',
      'discountCode': appliedDiscountCode.value.isNotEmpty
          ? appliedDiscountCode.value
          : null,
    };
    logger.i('تفاصيل الرحلة المرسلة: $tripDetails');

    if (!_isDisposed) {
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        barrierDismissible: false,
      );

      try {
        tripController
            .requestTrip(
          pickup: pickup,
          destination: destination,
          tripDetails: tripDetails,
        )
            .catchError((e) {
          logger.e('خطأ في طلب الرحلة: $e');
        });

        await Future.delayed(const Duration(milliseconds: 500));
        Get.back();

        Get.offNamed(AppRoutes.RIDER_SEARCHING, arguments: {
          'pickup': pickup,
          'destination': destination,
          'estimatedFare': totalFare.value,
          'estimatedDuration': LocationService.to.estimateDuration(
            LocationService.to.calculateDistance(
              pickup.latLng,
              destination.latLng,
            ),
          ),
        });
      } catch (e) {
        Get.back();
        _showError('حدث خطأ، يرجى المحاولة مرة أخرى');
      }
    }
  }

  void _showError(String message) {
    if (_isDisposed) return;

    Get.snackbar(
      'خطأ',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}
