import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/controllers/map_controller.dart'
    hide EnhancedPinWidget;
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/location_service.dart';
// import 'package:transport_app/views/rider/rider_widgets/animated_balance.dart';
// import 'package:transport_app/views/rider/rider_widgets/arabic_name.dart';
import 'package:transport_app/views/rider/rider_widgets/drawer.dart';
import 'package:transport_app/views/rider/rider_widgets/pin_painter.dart';
import 'package:transport_app/views/rider/rider_widgets/top_search_bar.dart';

class RiderHomeView extends StatefulWidget {
  const RiderHomeView({super.key});

  @override
  State<RiderHomeView> createState() => _RiderHomeViewState();
}

class _RiderHomeViewState extends State<RiderHomeView>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthController authController = Get.find<AuthController>();
  final MapControllerr mapController =
      Get.put(MapControllerr(), permanent: true);
  final TripController tripController = Get.find<TripController>();

  // Booking state
  final RxBool isRoundTrip = false.obs;
  final RxInt waitingTime = 0.obs;
  final RxDouble baseFare = 0.0.obs;
  final RxDouble totalFare = 0.0.obs;
  final RxString paymentMethod = 'cash'.obs; // 'cash' or 'app'
  bool _isDisposed = false;

  // Bottom Sheet Control
  final RxBool shouldShowBottomSheet = false.obs;

  // Animations
  late AnimationController _slideController;
  late AnimationController _priceAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _priceAnimation;

  final DraggableScrollableController _bottomSheetController =
      DraggableScrollableController();

  // Iraqi Dinar exchange rate
  final double iqd_exchange_rate = 1500.0;

  @override
  void initState() {
    super.initState();

    _initializeAnimations();
    _setupLocationListeners();
    _checkUserProfile();
    _setupBottomSheetControl();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

    // Don't show bottom sheet initially
    // _slideController.forward();
  }

  void _setupBottomSheetControl() {
    // Show bottom sheet only when both pickup and destination are confirmed
    ever(mapController.isPickupConfirmed, (bool confirmed) {
      _updateBottomSheetVisibility();
    });

    ever(mapController.isDestinationConfirmed, (bool confirmed) {
      _updateBottomSheetVisibility();
    });

    // Hide bottom sheet when selecting additional stops
    ever(mapController.currentStep, (String step) {
      if (step == 'additional_stop') {
        _hideBottomSheetForSelection();
      } else if (step == 'none' &&
          mapController.isPickupConfirmed.value &&
          mapController.isDestinationConfirmed.value) {
        _showBottomSheetAfterSelection();
      }
    });
  }

  void _updateBottomSheetVisibility() {
    if (_isDisposed) return;

    bool shouldShow = mapController.isPickupConfirmed.value &&
        mapController.isDestinationConfirmed.value;

    if (shouldShow && !shouldShowBottomSheet.value) {
      shouldShowBottomSheet.value = true;
      _slideController.forward();
      _calculateFare();
    } else if (!shouldShow && shouldShowBottomSheet.value) {
      shouldShowBottomSheet.value = false;
      _slideController.reverse();
    }
  }

  void _hideBottomSheetForSelection() {
    if (_isDisposed || !shouldShowBottomSheet.value) return;

    try {
      _bottomSheetController.animateTo(
        0.0, // fully collapse during selection
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      // Ignore if disposed
    }
  }

  void _showBottomSheetAfterSelection() {
    if (_isDisposed || !shouldShowBottomSheet.value) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed && shouldShowBottomSheet.value) {
        try {
          _bottomSheetController.animateTo(
            0.35,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } catch (e) {
          // Ignore if disposed
        }
      }
    });
  }

  void _setupLocationListeners() {
    ever(mapController.isPickupConfirmed, (bool confirmed) {
      if (!_isDisposed && confirmed) _calculateFare();
    });

    ever(mapController.isDestinationConfirmed, (bool confirmed) {
      if (!_isDisposed && confirmed) _calculateFare();
    });

    ever(mapController.selectedLocation, (LatLng? location) {
      if (!_isDisposed &&
          location != null &&
          mapController.currentLocation.value != null) {
        _calculateFare();
      }
    });

    // إضافة listener للمحطات الإضافية مع تحديث واجهة المستخدم
    ever(mapController.additionalStops, (List<AdditionalStop> stops) {
      if (!_isDisposed) {
        _calculateFare();
        // فرض إعادة بناء الواجهة لضمان ظهور/إخفاء الزر
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed) {
            setState(() {}); // إجبار الـ Widget على إعادة البناء
          }
        });
      }
    });
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

  void _calculateFare() {
    if (_isDisposed ||
        mapController.currentLocation.value == null ||
        mapController.selectedLocation.value == null) return;

    final from = mapController.currentLocation.value!;
    final to = mapController.selectedLocation.value!;
    final distanceKm = LocationService.to.calculateDistance(from, to);

    // Base fare calculation (in USD, then convert to IQD)
    double fareUSD = 2.0 + (distanceKm * 0.8);

    // Additional stops (these are additional destinations, not pickup points)
    fareUSD += mapController.additionalStops.length * 1.5;

    // Waiting time
    fareUSD += waitingTime.value * 0.2;

    // Round trip
    if (isRoundTrip.value) {
      fareUSD *= 1.8;
    }

    baseFare.value = fareUSD * iqd_exchange_rate;
    totalFare.value = baseFare.value;

    _animatePriceChange();
  }

  void _animatePriceChange() {
    if (_isDisposed) return;

    try {
      _priceAnimationController.reset();
      _priceAnimationController.forward();
    } catch (e) {
      // Ignore animation errors if controller is disposed
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // إيقاف اللودينج قبل التخلص من الكونترولر
    try {
      mapController.isLoading.value = false;
    } catch (e) {
      // Ignore if already disposed
    }
    try {
      _slideController.dispose();
    } catch (e) {
      // Ignore disposal errors
    }

    try {
      _priceAnimationController.dispose();
    } catch (e) {
      // Ignore disposal errors
    }

    try {
      _bottomSheetController.dispose();
    } catch (e) {
      // Ignore disposal errors
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: RiderDrawer(authController: authController),
        body: Stack(
          children: [
            _buildOptimizedMap(),
            _buildEnhancedCenterPin(),
            const ExpandableSearchBar(),
            const SearchResultsOverlay(),
            _buildSelectionCancelButton(),

            _buildBalanceDisplay(),
            _buildSideControls(),
            _buildLocationConfirmationSection(),
            // Only show bottom sheet when both locations are confirmed
            Obx(() {
              if (shouldShowBottomSheet.value) {
                return _buildEnhancedBottomSheet();
              }
              return const SizedBox.shrink();
            }),
            _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // إيقاف أي عملية لودينج جارية
    if (mapController.isLoading.value) {
      mapController.isLoading.value = false;
    }

    // تحقق من حالة الشاشة الحالية
    if (mapController.currentStep.value != 'none') {
      mapController.currentStep.value = 'none';
      mapController.showConfirmButton.value = false;
      _showBottomSheetAfterSelection();
      return false; // لا تخرج من التطبيق
    }

    // إذا كان الـ BottomSheet مفتوح، اخفه
    if (shouldShowBottomSheet.value) {
      try {
        _bottomSheetController.animateTo(
          0.20,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return false; // لا تخرج من التطبيق
      } catch (e) {
        // في حالة خطأ، اعرض dialog التأكيد
      }
    }

    // في كل الحالات الأخرى، اعرض dialog التأكيد
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.exit_to_app,
                        color: Colors.orange.shade600, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'الخروج من التطبيق',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'هل تريد الخروج من التطبيق؟\nستفقد أي بيانات رحلة غير محفوظة.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          'لا، البقاء',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // إيقاف اللودينج قبل الخروج
                          mapController.isLoading.value = false;
                          Navigator.of(context).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'نعم، خروج',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Enhanced Balance Display with better styling
  Widget _buildBalanceDisplay() {
    return Positioned(
      top: 110,
      right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: Colors.orange.shade600,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'رصيدك',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Obx(() => Text(
                      '${((authController.currentUser.value?.balance ?? 0.0) * iqd_exchange_rate).toStringAsFixed(0)} د.ع',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedMap() {
    return Obx(() => FlutterMap(
          mapController: mapController.mapController,
          options: MapOptions(
            initialCenter: mapController.mapCenter.value,
            initialZoom: mapController.mapZoom.value,
            minZoom: 5.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture) {
                final distance = LocationService.to.calculateDistance(
                  mapController.mapCenter.value,
                  camera.center,
                );
                if (distance > 0.01) {
                  mapController.mapCenter.value = camera.center;
                  mapController.mapZoom.value = camera.zoom;
                }
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.transport_app',
              maxZoom: 19,
              maxNativeZoom: 18,
            ),
            CircleLayer(circles: mapController.circles),
            PolylineLayer(polylines: mapController.polylines),
            MarkerLayer(markers: mapController.markers),
          ],
        ));
  }

  Widget _buildEnhancedCenterPin() {
    return Obx(() {
      if (mapController.currentStep.value == 'none') {
        return const SizedBox.shrink();
      }

      return Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Center(
            child: EnhancedPinWidget(
              color: _getStepColor(mapController.currentStep.value),
              label: _getStepText(mapController.currentStep.value),
              isMoving: mapController.isMapMoving.value,
              showLabel: false,
              size: 32,
              zoomLevel: mapController.mapZoom.value,
            ),
          ),
        ),
      );
    });
  }

  // Top-right cancel (X) while selecting additional stops only
  Widget _buildSelectionCancelButton() {
    return Obx(() {
      // إظهار زر X فقط عند اختيار نقاط إضافية
      if (mapController.currentStep.value != 'additional_stop')
        return const SizedBox.shrink();
      return Positioned(
        top: 115, // MediaQuery.of(context).padding.top + 8,
        left: 20,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () {
              mapController.currentStep.value = 'none';
              mapController.showConfirmButton.value = false;
              _showBottomSheetAfterSelection();
            },
          ),
        ),
      );
    });
  }

  Color _getStepColor(String step) {
    switch (step) {
      case 'pickup':
        return Colors.black; // Pickup pin and label in black
      case 'destination':
        return const Color(0xFFE53E3E); // Modern red
      case 'additional_stop':
        return const Color(0xFFFF8C00); // Modern orange
      default:
        return const Color(0xFF2196F3); // Modern blue
    }
  }

  String _getStepText(String step) {
    switch (step) {
      case 'pickup':
        return 'انطلاق';
      case 'destination':
        return 'وصول 1';
      case 'additional_stop':
        // وصول 2، وصول 3 حسب عدد المحطات الحالية
        return 'وصول ${mapController.additionalStops.length + 2}';
      default:
        return 'اختر الموقع';
    }
  }

  Widget _buildSideControls() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height / 2 - 30,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.my_location,
            color: Colors.blue.shade600,
            onPressed: () => mapController.refreshCurrentLocation(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        iconSize: 22,
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }

  // Enhanced location confirmation section showing real address
  Widget _buildLocationConfirmationSection() {
    return Obx(() {
      // إبقاء القسم ثابتاً ومرئياً طالما نحن في وضع اختيار موقع
      if (mapController.currentStep.value == 'none') {
        return const SizedBox.shrink();
      }

      return Positioned(
        bottom: 10,
        left: 16,
        right: 16,
        child: Column(
          children: [
            // Current address display with real-time updates
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getStepColor(mapController.currentStep.value)
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getStepIcon(mapController.currentStep.value),
                          color: _getStepColor(mapController.currentStep.value),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStepText(mapController.currentStep.value),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Real-time address display
                            Obx(() {
                              String displayAddress =
                                  mapController.currentPinAddress.value;
                              if (displayAddress.isEmpty) {
                                displayAddress = mapController.isMapMoving.value
                                    ? 'جارٍ تحديد الموقع...'
                                    : 'موقعك الحالي على الخريطة';
                              }
                              return Text(
                                displayAddress,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: mapController.showConfirmButton.value
                    ? _confirmCurrentLocation
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _getStepColor(mapController.currentStep.value),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: _getStepColor(mapController.currentStep.value)
                      .withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon(Icons.check_circle_outline, size: 20),
                    // const SizedBox(width: 8),
                    Text(
                      mapController.showConfirmButton.value
                          ? 'تثبيت ${_getStepText(mapController.currentStep.value)}'
                          : 'جاري تحديد الموقع...',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  IconData _getStepIcon(String step) {
    switch (step) {
      case 'pickup':
        return Icons.trip_origin;
      case 'destination':
        return Icons.location_on;
      case 'additional_stop':
        return Icons.add_location_alt;
      default:
        return Icons.place;
    }
  }

  Future<void> _confirmCurrentLocation() async {
    if (_isDisposed) return;

    // إضافة timeout لمنع اللودينج المستمر
    try {
      await mapController.confirmPinLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (!_isDisposed) {
            mapController.isLoading.value = false;
            _showError('انتهت مهلة العملية، يرجى المحاولة مرة أخرى');
          }
          throw TimeoutException('Pin confirmation timeout');
        },
      );

      if (_isDisposed) return;

      // The bottom sheet visibility will be handled by the listeners
    } catch (e) {
      if (!_isDisposed) {
        mapController.isLoading.value = false;
        logger.w('خطأ في تأكيد الموقع: $e');
      }
    }
  }

  Widget _buildEnhancedBottomSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      top: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: _buildProgressiveBookingSheet(),
      ),
    );
  }

  Widget _buildProgressiveBookingSheet() {
    return DraggableScrollableSheet(
      controller: _bottomSheetController,
      initialChildSize: 0.35,
      minChildSize: 0.0, // collapse fully during selection
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            children: [
              _buildHandle(),
              const SizedBox(height: 8),
              _buildHeaderSection(),
              const SizedBox(height: 16),
              _buildLocationInputSection(),
              const SizedBox(height: 16),
              // Always show additional stops section when available
              Obx(() {
                if (mapController.additionalStops.isNotEmpty) {
                  return Column(
                    children: [
                      _buildAdditionalStopsDisplaySection(),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
              Obx(() {
                if (baseFare.value > 0) {
                  return Column(
                    children: [
                      _buildTripOptionsSection(),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
              Obx(() {
                if (totalFare.value > 0) {
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildFareDisplay(),
                      const SizedBox(height: 16),
                      _buildBookButton(),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                return const SizedBox(height: 24);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.directions_car,
            color: Colors.orange.shade600,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفاصيل الرحلة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'اختر نقاط الانطلاق والوصول',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationInputSection() {
    return Obx(() => Column(
          children: [
            // Main pickup location
            _buildLocationInputField(
              icon: Icons.trip_origin,
              iconColor: const Color(0xFF4CAF50),
              label: 'انطلاق',
              value: mapController.isPickupConfirmed.value
                  ? (mapController.currentAddress.value.isNotEmpty
                      ? mapController.currentAddress.value
                      : 'الموقع الحالي')
                  : 'اختر نقطة الانطلاق',
              isSet: mapController.isPickupConfirmed.value,
              onTap: () => mapController.startLocationSelection('pickup'),
              onRemove: mapController.isPickupConfirmed.value
                  ? () => _removePickupLocation()
                  : null,
            ),

            // Line connector
            Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const SizedBox(width: 28),
                  Container(width: 2, height: 15, color: Colors.grey.shade300),
                ],
              ),
            ),

            // Main destination location
            _buildLocationInputField(
              icon: Icons.location_on,
              iconColor: const Color(0xFFE53E3E),
              label: 'وصول',
              value: mapController.isDestinationConfirmed.value
                  ? (mapController.selectedAddress.value.isNotEmpty
                      ? mapController.selectedAddress.value
                      : 'تم تحديد الوجهة')
                  : 'اختر نقطة الوصول الرئيسية',
              isSet: mapController.isDestinationConfirmed.value,
              onTap: () => mapController.startLocationSelection('destination'),
              onRemove: mapController.isDestinationConfirmed.value
                  ? () => _removeDestinationLocation()
                  : null,
            ),

            // Add additional destination button - مع مراقبة التغييرات
            if (mapController.additionalStops.length <
                    mapController.maxAdditionalStops.value &&
                mapController.isPickupConfirmed.value &&
                mapController.isDestinationConfirmed.value) ...[
              const SizedBox(height: 8),
              _buildAddDestinationButton(),
            ] else if (mapController.additionalStops.length >=
                mapController.maxAdditionalStops.value) ...[
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.grey.shade600, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'تم الوصول للحد الأقصى (${mapController.maxAdditionalStops.value} وجهات)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ));
  }

  // Updated: Build additional stops display section
  Widget _buildAdditionalStopsDisplaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.add_location_alt,
                color: Colors.orange.shade600, size: 18),
            const SizedBox(width: 8),
            const Text(
              'وجهات إضافية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() => Column(
              children:
                  mapController.additionalStops.asMap().entries.map((entry) {
                int index = entry.key;
                AdditionalStop stop = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 2}', // وصول 2, وصول 3, etc.
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'وصول ${index + 2}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stop.address,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 18, color: Colors.red.shade400),
                        onPressed: () =>
                            mapController.removeAdditionalStop(stop.id),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )),
      ],
    );
  }

   void _removePickupLocation() {
    mapController.isPickupConfirmed.value = false;
    mapController.currentAddress.value = '';
    mapController.markers
        .removeWhere((marker) => marker.key == const Key('pickup'));

    // لا تحذف باقي النقاط - فقط امسح الـ polylines
    mapController.polylines.clear();

    // تحقق من وجود نقطة وصول قبل إجبار المستخدم على اختيارها
    if (mapController.isDestinationConfirmed.value) {
      // إذا كان هناك وصول محدد، ابدأ اختيار نقطة انطلاق جديدة
      mapController.startLocationSelection('pickup');
    } else {
      // إذا لم يكن هناك وصول، ابدأ اختيار نقطة انطلاق جديدة
      mapController.startLocationSelection('pickup');
    }

    // أعد حساب التكلفة
    _calculateFare();
  }

  void _removeDestinationLocation() {
    mapController.isDestinationConfirmed.value = false;
    mapController.selectedLocation.value = null;
    mapController.selectedAddress.value = '';
    mapController.markers
        .removeWhere((marker) => marker.key == const Key('destination'));
    mapController.polylines.clear();

    // إخفاء الـ BottomSheet
    _hideBottomSheetForSelection();

    // الانتقال لموقع قريب من الانطلاق بدلاً من موقع بعيد
    if (mapController.currentLocation.value != null) {
      // اجعل الخريطة تتحرك لموقع قريب من نقطة الانطلاق
      final pickup = mapController.currentLocation.value!;
      final nearbyLocation = LatLng(
        pickup.latitude + 0.003, // مسافة قصيرة جداً (حوالي 300 متر)
        pickup.longitude + 0.003,
      );
      mapController.moveToLocation(nearbyLocation, zoom: 15.0);
    }

    // ابدأ اختيار نقطة وصول جديدة فوراً
    mapController.startLocationSelection('destination');

    // أعد حساب التكلفة
    _calculateFare();
  }

  Widget _buildLocationInputField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isSet,
    required VoidCallback onTap,
    VoidCallback? onRemove,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        _hideBottomSheetForSelection();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSet ? FontWeight.w600 : FontWeight.w400,
                      color: isSet ? Colors.black87 : Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ] else if (isSet) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                color: iconColor,
                size: 20,
              ),
            ] else ...[
              const SizedBox(width: 8),
              Icon(
                Icons.edit_location_alt,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddDestinationButton() {
    return GestureDetector(
      onTap: () {
        mapController.startLocationSelection('additional_stop');
        _hideBottomSheetForSelection();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_location_alt,
                color: Colors.orange.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              'إضافة وصول ${mapController.additionalStops.length + 2}',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune, color: Colors.grey.shade600, size: 18),
            const SizedBox(width: 8),
            const Text(
              'خيارات الرحلة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTripTypeSection(),
        const SizedBox(height: 16),
        _buildWaitingTimeSection(),
        const SizedBox(height: 16),
        _buildPaymentMethodSection(),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'طريقة الدفع',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Obx(() => GestureDetector(
                      onTap: () => paymentMethod.value = 'cash',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: paymentMethod.value == 'cash'
                              ? Colors.orange.shade400
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payments,
                              size: 16,
                              color: paymentMethod.value == 'cash'
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'نقدي',
                              style: TextStyle(
                                color: paymentMethod.value == 'cash'
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ),
              Expanded(
                child: Obx(() => GestureDetector(
                      onTap: () => paymentMethod.value = 'app',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: paymentMethod.value == 'app'
                              ? Colors.orange.shade400
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 16,
                              color: paymentMethod.value == 'app'
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'عن طريق التطبيق',
                              style: TextStyle(
                                color: paymentMethod.value == 'app'
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نوع الرحلة',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Obx(() => GestureDetector(
                      onTap: () {
                        isRoundTrip.value = false;
                        _calculateFare();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !isRoundTrip.value
                              ? Colors.orange.shade400
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: !isRoundTrip.value
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ذهاب فقط',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: !isRoundTrip.value
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ),
              Expanded(
                child: Obx(() => GestureDetector(
                      onTap: () {
                        isRoundTrip.value = true;
                        _calculateFare();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isRoundTrip.value
                              ? Colors.orange.shade400
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              size: 16,
                              color: isRoundTrip.value
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ذهاب وعودة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isRoundTrip.value
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'وقت الانتظار المتوقع',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child:
                    _buildWaitingTimeOption(0, 'بدون انتظار', Icons.flash_on)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildWaitingTimeOption(5, '5 دقائق', Icons.schedule)),
            const SizedBox(width: 8),
            Expanded(
                child:
                    _buildWaitingTimeOption(10, '10 دقائق', Icons.access_time)),
            const SizedBox(width: 8),
            Expanded(
                child: _buildWaitingTimeOption(15, '15 دقيقة', Icons.timer)),
          ],
        ),
      ],
    );
  }

  Widget _buildWaitingTimeOption(int minutes, String label, IconData icon) {
    return Obx(() => GestureDetector(
          onTap: () {
            waitingTime.value = minutes;
            _calculateFare();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: waitingTime.value == minutes
                  ? Colors.orange.shade400
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: waitingTime.value == minutes
                    ? Colors.orange.shade400
                    : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: waitingTime.value == minutes
                      ? Colors.white
                      : Colors.grey.shade600,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: waitingTime.value == minutes
                        ? Colors.white
                        : Colors.grey.shade600,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (minutes > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '+${(minutes * 0.2 * iqd_exchange_rate).toStringAsFixed(0)} د.ع',
                    style: TextStyle(
                      color: waitingTime.value == minutes
                          ? Colors.white70
                          : Colors.grey.shade500,
                      fontSize: 8,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ));
  }

  Widget _buildFareDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text(
                'إجمالي التكلفة',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _priceAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _priceAnimation.value,
                child: Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          totalFare.value.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'دينار عراقي',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildFareBreakdown(),
        ],
      ),
    );
  }

  Widget _buildFareBreakdown() {
    return Obx(() {
      if (mapController.additionalStops.isNotEmpty ||
          waitingTime.value > 0 ||
          isRoundTrip.value) {
        return Column(
          children: [
            Container(height: 1, color: Colors.white24),
            const SizedBox(height: 12),
            _buildBreakdownRow('التكلفة الأساسية:',
                '${baseFare.value.toStringAsFixed(0)} د.ع'),
            if (mapController.additionalStops.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildBreakdownRow(
                  'وجهات إضافية (${mapController.additionalStops.length}):',
                  '+${(mapController.additionalStops.length * 1.5 * iqd_exchange_rate).toStringAsFixed(0)} د.ع'),
            ],
            if (waitingTime.value > 0) ...[
              const SizedBox(height: 6),
              _buildBreakdownRow('وقت انتظار (${waitingTime.value} دقيقة):',
                  '+${(waitingTime.value * 0.2 * iqd_exchange_rate).toStringAsFixed(0)} د.ع'),
            ],
            if (isRoundTrip.value) ...[
              const SizedBox(height: 6),
              _buildBreakdownRow('ذهاب وعودة:', '×1.8'),
            ],
          ],
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildBreakdownRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          if (!mapController.isPickupConfirmed.value ||
              !mapController.isDestinationConfirmed.value) {
            _showError('يرجى تحديد نقطة الانطلاق والوصول');
            return;
          }
          // إذا الدفع عن طريق التطبيق، تحقق من الرصيد
          if (paymentMethod.value == 'app') {
            final user = authController.currentUser.value;
            if (user == null ||
                (user.balance * iqd_exchange_rate) < totalFare.value) {
              _showError('رصيدك غير كافٍ، سيتم تحويلك لشحن المحفظة');
              Get.toNamed(AppRoutes.RIDER_WALLET);
              return;
            }
          }
          await _requestTrip();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Colors.orange.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.local_taxi, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text(
              'طلب الرحلة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestTrip({bool isRush = false}) async {
    if (_isDisposed ||
        mapController.currentLocation.value == null ||
        mapController.selectedLocation.value == null) {
      if (!_isDisposed) {
        _showError('يرجى تحديد نقطة البداية والوجهة');
      }
      return;
    }

    final pickupLatLng = mapController.currentLocation.value!;
    final destLatLng = mapController.selectedLocation.value!;

    String pickupAddress = mapController.currentAddress.value;
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
      'additionalStops': mapController.additionalStops
          .map((stop) => {
                'lat': stop.location.latitude,
                'lng': stop.location.longitude,
                'address': stop.address,
                'stopNumber': stop.stopNumber,
              })
          .toList(),
      'isRoundTrip': isRoundTrip.value,
      'waitingTime': waitingTime.value,
      'totalFare': totalFare.value,
      'isRush': isRush,
      'paymentMethod': paymentMethod.value,
    };

    if (!_isDisposed) {
      await tripController.requestTrip(
        pickup: pickup,
        destination: destination,
        tripDetails: tripDetails,
      );
    }
  }

  Widget _buildLoadingOverlay() {
    return Obx(() {
      final bool showOverlay = mapController.isLoading.value;
      if (!showOverlay) return const SizedBox.shrink();

      return Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: Colors.orange.shade400,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'جارٍ التحميل...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // void _showSuccess(String title, String message) {
  //   if (_isDisposed) return;
  //   Get.snackbar(
  //     title,
  //     message,
  //     snackPosition: SnackPosition.BOTTOM,
  //     backgroundColor: Colors.green,
  //     colorText: Colors.white,
  //     duration: const Duration(seconds: 2),
  //     margin: const EdgeInsets.all(16),
  //     borderRadius: 12,
  //   );
  // }

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
