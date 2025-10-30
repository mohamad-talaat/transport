import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/services/map_services/map_singleton_service.dart';
import 'package:transport_app/views/driver/driver_card_request_widgets.dart';
import 'package:transport_app/views/driver/driver_home_drawer.dart';
import 'package:transport_app/views/rider/rider_widgets/go_to_my_current_location.dart';
import 'package:transport_app/views/shared/adaptive_map_container.dart';

final Logger logger = Logger();

class DriverHomeView extends StatefulWidget {
  const DriverHomeView({super.key});

  @override
  State<DriverHomeView> createState() => _DriverHomeViewState();
}

class _DriverHomeViewState extends State<DriverHomeView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final AuthController authController = Get.find<AuthController>();
  final DriverController driverController = Get.find<DriverController>();
  final MyMapController mapController = Get.put(MyMapController(),
      permanent: true);

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  PageController tripRequestsController = PageController();
  Timer? tripRequestTimer;
  int currentTripIndex = 0;

  final ValueNotifier<bool> _isExpansionTileOpen = ValueNotifier<bool>(false);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  RiderType? _riderType;
  final GetStorage storage = GetStorage();

  LatLng? _previousLocation;
  double _currentBearing = 0.0;
  
void _showTripMarkersOnMap(TripModel trip) async {
  logger.i('📍 [DRIVER HOME] Showing markers for trip ${trip.id}');
  mapController.clearTripMarkers();
  
  await Future.delayed(const Duration(milliseconds: 150));
  
  mapController.setupDriverTripView(
    trip,
    driverController.currentLocation.value,
    bearing: _currentBearing,
  );

  final points = <LatLng>[];
  if (driverController.currentLocation.value != null) {
    points.add(driverController.currentLocation.value!);
  }
  points.add(trip.pickupLocation.latLng);
  points.add(trip.destinationLocation.latLng);
  
  if (trip.additionalStops.isNotEmpty) {
    points.addAll(trip.additionalStops.map((s) => s.location));
  }

  if (points.isEmpty) return;

  if (points.length == 1) {
    mapController.mapController.move(points.first, 16.0);
    return;
  }

  final bounds = LatLngBounds.fromPoints(points);
  final padding = context.getSmartMapPadding(
    hasBottomContent: true,
    bottomContentFraction: 0.38,
  );

  final fittedCamera = CameraFit.bounds(
    bounds: bounds,
    padding: padding,
    maxZoom: 17,
  );

  final result = mapController.mapController.fitCamera(fittedCamera);

  if (result == false) {
    final center = LatLng(
      (bounds.north + bounds.south) / 2,
      (bounds.west + bounds.east) / 2,
    );
    mapController.mapController.move(center, 14.5);
  }

  logger.i('✅ Trip markers fitted with smart padding.');
}
void _clearTripMarkers() {
  if (!mounted) return;
  logger.i('🧹 Clearing trip markers from Driver Home');

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    mapController.clearTripMarkers();
    mapController.polylines.clear();

    // ✳️ بعد إزالة الطلبات، رجع الكاميرا لموقع السائق فقط
    final driverLoc = driverController.currentLocation.value;
    if (driverLoc != null) {
      mapController.animatedMapMove(driverLoc, 16.0, this);
      mapController.updateDriverLocationMarker(driverLoc, bearing: _currentBearing);
    }

    logger.i('✅ Trip markers cleared - map reset to driver');
  });
}

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _checkPendingPayment();
    _initializeSlideAnimation();
    _setupTripRequestsListener();
    _loadAndSaveRiderType();
    _setupLocationListeners();
    
    // 🔥 فحص الرحلة النشطة بدون navigation تلقائي
    Future.delayed(const Duration(milliseconds: 500), () async {
      await driverController.checkActiveTrip();
      
      // ✅ لو مفيش رحلة نشطة، ابدأ الاستماع عادي
      if (driverController.currentTrip.value == null && 
          driverController.isOnline.value && 
          !driverController.isOnTrip.value) {
        logger.i('🚀 بدء الاستماع للطلبات');
        driverController.startListeningForRequests();
        driverController.startLocationUpdates();
      }
    });
  }

  void _checkPendingPayment() {
    final paymentLock = storage.read('paymentLock');
    
    if (paymentLock != null && paymentLock['status'] == 'pending') {
      logger.i('💳 Payment pending detected in Home - redirecting...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        driverController.surePayment();
      });
    }
  }

  void _loadAndSaveRiderType() {
    final args = Get.arguments;
    if (args != null && args['type'] != null) {
      _riderType = args['type'];
      _saveSelectedRiderType(_riderType!);
    } else {
      _riderType = _getSavedRiderType();
    }
  }

  void _cleanupMapResources() {
    try {
      logger.i('🧹 بدء تنظيف موارد الخريطة...');
      
      // ✅ تنظيف خارج الإطار التفاعلي
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          mapController.clearTripMarkers();
          mapController.polylines.clear();
          driverController.currentTrip.value = null;
        }
      });
      
      logger.i('✅ تم تنظيف موارد الخريطة بنجاح');
    } catch (e) {
      logger.e('❌ خطأ في تنظيف موارد الخريطة: $e');
    }
  }

  void _setupLocationListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (driverController.currentLocation.value != null) {
        _updateDriverCarMarkerOnly(
          driverController.currentLocation.value!,
          bearing: _currentBearing,
        );
        logger.i('✅ تم إضافة ماركر السيارة الأولي');
      }
    });
ever(driverController.currentLocation, (location) {
  if (location != null && mounted) {
    if (_previousLocation != null) {
      _currentBearing = _calculateBearing(_previousLocation!, location);
    }
    _previousLocation = location;
    _updateDriverCarMarkerOnly(location, bearing: _currentBearing);

    // 🔥 هنا التعديل:
    if (driverController.tripRequests.isEmpty &&
        driverController.currentTrip.value == null) {
      mapController.animatedMapMove(location, 16.0, this);
    }
  }
});
    
    // ever(driverController.currentLocation, (location) {
    //   if (location != null && mounted) {
    //     // 🧭 حساب الـ bearing من الموقع السابق للموقع الحالي
    //     if (_previousLocation != null) {
    //       _currentBearing = _calculateBearing(_previousLocation!, location);
    //     }
    //     _previousLocation = location;
        
    //     _updateDriverCarMarkerOnly(location, bearing: _currentBearing);
    //     mapController.animatedMapMove(location, 16.0, this);
    //   }
    // });
  }

  void _updateDriverCarMarkerOnly(LatLng location, {double bearing = 0.0}) {
    mapController.updateDriverLocationMarker(location, bearing: bearing);
  }

  /// 🧭 حساب الـ bearing (الاتجاه) بين موقعين
  /// يستخدم لتدوير أيقونة السيارة لتكون موازية لاتجاه الحركة (زي Uber/Careem)
  double _calculateBearing(LatLng from, LatLng to) {
    // تحويل الدرجات لـ radians
    final lat1 = from.latitude * (3.14159265359 / 180);
    final lat2 = to.latitude * (3.14159265359 / 180);
    final dLng = (to.longitude - from.longitude) * (3.14159265359 / 180);
    
    // حساب الاتجاه باستخدام صيغة Haversine
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - 
              math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    
    // تحويل من radians لدرجات وضمان القيمة بين 0-360
    double bearing = math.atan2(y, x) * (180 / 3.14159265359);
    bearing = (bearing + 360) % 360;
    
    return bearing; // ✅ الآن السيارة ستدور مع اتجاه الحركة تلقائياً
  }

  Future<UserModel?> _getRiderInfo(String riderId) async {
    try {
      final doc = await driverController.firestore
          .collection('users')
          .doc(riderId)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      logger.w('خطأ في جلب بيانات الراكب: $e');
    }
    return null;
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupMapResources();
    _slideController.dispose();
    tripRequestTimer?.cancel();
    tripRequestsController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _initializeSlideAnimation() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupTripRequestsListener() {
    ever(driverController.tripRequests, (List<TripModel> trips) {
      if (!mounted) return;

      if (trips.isNotEmpty) {
        if (currentTripIndex >= trips.length) {
          currentTripIndex = 0;
        }
        _restartTripRequestTimer();
        if (mounted) {
          _showTripMarkersOnMap(trips[currentTripIndex]);
        }

        if (_slideController.status != AnimationStatus.forward &&
            _slideController.status != AnimationStatus.completed) {
          _slideController.forward();
        }
      } else {
        _stopTripRequestTimer();
        currentTripIndex = 0;
        if (mounted) {
          _clearTripMarkers();
        }

        if (_slideController.status != AnimationStatus.reverse &&
            _slideController.status != AnimationStatus.dismissed) {
          _slideController.reverse();
        }
      }
    });
  }

  // void _showTripMarkersOnMap(TripModel trip) {
  //   logger.i('📍 [DRIVER HOME] Showing markers for trip ${trip.id}');
  //   mapController.clearTripMarkers();
  //   mapController.setupDriverTripView(
  //     trip,
  //     driverController.currentLocation.value,
  //     bearing: _currentBearing,
  //   );
  //   logger.i('✅ Trip markers displayed - Total: ${mapController.markers.length}');
  // }

  // void _clearTripMarkers() {
  //   if (!mounted) return;
    
  //   logger.i('🧹 Clearing trip markers from Driver Home');
    
  //   // ✅ تنفيذ بعد إنتهاء البناء
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (!mounted) return;
      
  //     mapController.clearTripMarkers();
  //     mapController.polylines.clear();

  //     if (driverController.currentLocation.value != null) {
  //       mapController.updateDriverLocationMarker(
  //         driverController.currentLocation.value!,
  //         bearing: _currentBearing,
  //       );
  //     }
      
  //     logger.i('✅ Trip markers cleared - Remaining markers: ${mapController.markers.length}');
  //   });
  // }

  void _startTripRequestTimer() {
    _stopTripRequestTimer();
    if (driverController.tripRequests.isNotEmpty) {
      tripRequestTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
        if (driverController.tripRequests.isNotEmpty) {
          if (driverController.tripRequests.length == 1) {
            driverController.tripRequests.clear();
            _stopTripRequestTimer();
            return;
          }

          currentTripIndex =
              (currentTripIndex + 1) % driverController.tripRequests.length;
          if (tripRequestsController.hasClients) {
            tripRequestsController.animateToPage(
              currentTripIndex,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutQuad,
            );
          }
        } else {
          timer.cancel();
        }
      });
    }
  }

  void _restartTripRequestTimer() {
    _stopTripRequestTimer();
    _startTripRequestTimer();
    if (tripRequestsController.hasClients &&
        driverController.tripRequests.isNotEmpty) {
      final targetIndex =
          currentTripIndex.clamp(0, driverController.tripRequests.length - 1);
      tripRequestsController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _stopTripRequestTimer() {
    tripRequestTimer?.cancel();
    tripRequestTimer = null;
  }

  void _goToPreviousTripRequest() {
    if (driverController.tripRequests.isNotEmpty &&
        tripRequestsController.hasClients) {
      int prevIndex =
          (currentTripIndex - 1 + driverController.tripRequests.length) %
              driverController.tripRequests.length;

      tripRequestsController.animateToPage(
        prevIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _showTripMarkersOnMap(driverController.tripRequests[prevIndex]);
    }
  }

  void _goToNextTripRequest() {
    if (driverController.tripRequests.isNotEmpty &&
        tripRequestsController.hasClients) {
      int nextIndex =
          (currentTripIndex + 1) % driverController.tripRequests.length;

      tripRequestsController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _showTripMarkersOnMap(driverController.tripRequests[nextIndex]);
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    key: _scaffoldKey,
    drawer: DriverDrawer(),
    body: Obx(() {
      final hasRequests = driverController.tripRequests.isNotEmpty;
      
      return AdaptiveMapContainer(
        hasContent: hasRequests,
        minMapHeightFraction: 0.62,
        mapWidget: Stack(
          children: [
            QuickMap.forHome(
              mapController.mapController,
              mapController.mapCenter.value ?? const LatLng(30.5, 47.8),
              14,
              mapController.markers,
            ),
            _buildMenuButton(),
            _buildOnlineOfflineToggle(),
            _buildBalanceDisplay(),
            GoToMyLocationButton(onPressed: () {
              if (mapController.currentLocation.value != null) {
                mapController.mapController.move(
                  mapController.currentLocation.value!,
                  16.0,
                );
              }
            }),
          ],
        ),
        bottomContent: hasRequests 
            ? SlideTransition(
                position: _slideAnimation,
                child: _buildTripRequestsSection(),
              )
            : null,
      );
    }),
  );
}

  Widget _buildMenuButton() {
    return Positioned(
      right: 16,
      child: SafeArea(
        child: GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 229, 227, 230),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.menu, color: Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineOfflineToggle() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.topCenter,
        child: Obx(() {
          final isOnline = driverController.isOnline.value;
          return GestureDetector(
            onTap: () => driverController.toggleOnlineStatus(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOnline 
                    ? [Colors.green.shade400, Colors.green.shade700]
                    : [Colors.grey.shade600, Colors.grey.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: (isOnline ? Colors.green : Colors.grey).withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: !isOnline ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.power_settings_new,
                          color: !isOnline ? Colors.grey.shade800 : Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'غير متصل',
                          style: TextStyle(
                            color: !isOnline ? Colors.grey.shade800 : Colors.white70,
                            fontWeight: !isOnline ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: isOnline ? Colors.green.shade700 : Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'متصل',
                          style: TextStyle(
                            color: isOnline ? Colors.green.shade700 : Colors.white70,
                            fontWeight: isOnline ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBalanceDisplay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 25,
      right: 10,
      child: SafeArea(
        child: Obx(() {
          final debt = driverController.currentDebt.value;
          final isHighDebt = debt >= DriverController.MAX_DEBT_LIMIT;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: debt < 0
                    ? (debt <= -DriverController.MAX_DEBT_LIMIT
                        ? [Colors.red.shade400, Colors.red.shade700]
                        : [Colors.blue.shade400, Colors.blue.shade700])
                    : [Colors.orange.shade400, Colors.orange.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  textAlign: TextAlign.center,
                  isHighDebt ? 'تنبيه: الديون مرتفعة' : 'الرصيد',
                  style: TextStyle(
                    color: isHighDebt ? Colors.white : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${debt.toStringAsFixed(2)} د.ع',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        isHighDebt ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTripRequestsSection() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isExpansionTileOpen,
      builder: (context, isExpanded, _) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                if (driverController.tripRequests.length > 1)
                  Positioned(
                    top: 6,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildArrowButton(
                          icon: Icons.keyboard_double_arrow_right_sharp,
                          onTap: _goToPreviousTripRequest,
                        ),
                        Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Text(
                            "تبديل بين الطلبات",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Spacer(),
                        _buildArrowButton(
                          icon: Icons.keyboard_double_arrow_left_sharp,
                          onTap: _goToNextTripRequest,
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 3),
                ExpansionTile(
                  initiallyExpanded: true,
                  onExpansionChanged: (expanded) {
                    _isExpansionTileOpen.value = expanded;
                  },
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'طلبات الرحلات الجديدة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        '${driverController.tripRequests.length} طلب',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  childrenPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  children: driverController.tripRequests.map((trip) {
                    final index = driverController.tripRequests.indexOf(trip);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 1.0),
                      child: TripRequestWidgets.buildTripRequestCard(
                        trip: trip,
                        index: index,
                        getRiderInfo: _getRiderInfo,
                        tripRequestsController: tripRequestsController,
                        isExpansionTileOpen: _isExpansionTileOpen,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildArrowButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onTap,
      ),
    );
  }
}
