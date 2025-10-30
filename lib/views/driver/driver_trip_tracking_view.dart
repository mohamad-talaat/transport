import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/map_services/map_singleton_service.dart';
import 'package:transport_app/views/driver/widgets/destination_change_alert.dart';
import 'package:transport_app/views/driver/widgets/hold_to_start_button.dart';
import 'package:transport_app/views/rider/rider_widgets/go_to_my_current_location.dart';
import 'package:transport_app/views/shared/trip_tracking_shared_widgets.dart';
import 'package:transport_app/views/shared/adaptive_map_container.dart';
import 'dart:math' as math;

class DriverTripTrackingView extends StatefulWidget {
  const DriverTripTrackingView({super.key});

  @override
  State<DriverTripTrackingView> createState() => _DriverTripTrackingViewState();
}

class _DriverTripTrackingViewState extends State<DriverTripTrackingView>
    with TickerProviderStateMixin {
  final DriverController driverController = Get.find();
  final MyMapController mapController = Get.find();
  final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(false);
  LatLng? _lastDriverLocation;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // ✅ إعداد الخريطة مرة واحدة فقط
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeMapAndMarkers();
      }
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  StreamSubscription? _tripUpdatesSubscription; // أضف هذا المتغير

  void _listenToTripFullUpdates(String tripId) {
    _tripUpdatesSubscription?.cancel();
    logger.d('🎧 [Driver] بدء الاستماع لتحديثات الرحلة الكاملة: $tripId');

    _tripUpdatesSubscription = driverController.firestore
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) {
        if (!snapshot.exists) {
          logger.w('❌ [Driver] الرحلة لم تعد موجودة في Firestore');
          _navigateToDriverHome(); // العودة للصفحة الرئيسية إذا حذفت الرحلة
        }
        return;
      }

      try {
        final data = snapshot.data();
        if (data != null) {
          // final updatedTrip = TripModel.fromMap(data);
          // // قم بتحديث currentTrip.value في الـ controller
          // // هذا سيقوم تلقائيا بتحديث الـ UI إذا كان currentTrip.value Observable
          // driverController.currentTrip.value = updatedTrip;
          final currentTrip = driverController.currentTrip.value;
          final updatedTrip = TripModel.fromMap(data);

// ✅ حافظ على بيانات الراكب القديمة لو Firestore مرجعها null
          if (updatedTrip.rider == null && currentTrip?.rider != null) {
            updatedTrip.rider = currentTrip!.rider;
          }

          driverController.currentTrip.value = updatedTrip;

          // ✅ إعادة تحديث الماركرز إذا كان هناك تغيير في نقاط الرحلة
          // يمكنك مقارنة النقاط القديمة والجديدة هنا إذا كنت تريد تحسين الأداء
          // لكن الأسهل هو إعادة استدعاء التحديث
          _updateTripMarkers(updatedTrip);
          logger.d('📡 [Driver] تم تحديث بيانات الرحلة من Firestore.');
        }
      } catch (e) {
        logger.e('❌ [Driver] خطأ في معالجة تحديث الرحلة: $e');
      }
    }, onError: (error) {
      logger.e('❌ [Driver] خطأ في stream تحديثات الرحلة: $error');
    });
  }

  /// 🔥 تهيئة الخريطة مرة واحدة فقط عند فتح الشاشة
  Future<void> _initializeMapAndMarkers() async {
    if (!mounted) return;
    try {
      // ✅ انتظار بسيط لتحميل currentTrip
      await Future.delayed(const Duration(milliseconds: 300));

      var trip = driverController.currentTrip.value;
      if (trip == null) {
        logger.w('⚠️ لا توجد رحلة نشطة - إعادة محاولة...');
        // ✅ محاولة واحدة أخرى
        await Future.delayed(const Duration(milliseconds: 500));
        trip = driverController.currentTrip.value;
        if (trip == null) {
          logger.e('❌ فشل تحميل الرحلة - العودة للهوم');
          _navigateToDriverHome();
          return;
        }
      }
      if (_driverLocationSubscription == null) {
        _listenToDriverLocation(trip.id);
      }

      // ✅ بدء الاستماع لتحديثات الرحلة الكاملة
      _listenToTripFullUpdates(trip.id); // استدعاء دالة جديدة
      // ⏰ انتظر حتى يتم رسم الـ frame الأول - زيادة الوقت لـ Release
// في إصدار الريليس ممكن يحصل lag في تحميل الماركرز من الذاكرة
      await Future.delayed(const Duration(milliseconds: 800));

      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 200));
        return mapController.isMapReady.value == false;
      });

      logger.i('📍 [تهيئة] رسم ماركرز الرحلة ${trip.id}');

      // 🔥 إعداد الماركرز مرة واحدة فقط
      _updateTripMarkers(trip);

      // ✅ Force rebuild بعد إعداد الماركرز لضمان ظهور الـ bottom panel
      if (mounted) {
        setState(() {}); // Force rebuild للـ UI
      }

      logger.i('✅ تم إعداد ماركرز الرحلة للسائق');

      // بدء الاستماع لموقع السائق
      _listenToDriverLocation(trip.id);
    } catch (e) {
      logger.e('❌ خطأ في تهيئة الخريطة: $e');
      _navigateToDriverHome();
    }
  }

  /// ✅ دالة لتحديث ماركرز الرحلة بدون rebuild
  void _updateTripMarkers(TripModel trip) {
    if (!mounted) return;

    try {
      mapController.setupDriverTripView(
        trip,
        mapController.currentLocation.value,
        bearing: 0.0,
      );
    } catch (e) {
      logger.e('❌ خطأ في تحديث الماركرز: $e');
    }
  }

  /// ✅ الاستماع لموقع السائق من Firebase
  StreamSubscription? _driverLocationSubscription;

  void _listenToDriverLocation(String tripId) {
    _driverLocationSubscription?.cancel();

    final trip = driverController.currentTrip.value;
    if (trip == null || trip.driverId == null) return;

    logger.d('📍 بدء الاستماع لموقع السائق: ${trip.driverId}');

    _driverLocationSubscription = driverController.firestore
        .collection('users')
        .doc(trip.driverId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;

      try {
        final data = snapshot.data();

        if (data != null && data['currentLocation'] != null) {
          final locationData = data['currentLocation'] as Map<String, dynamic>;
          final driverLat = locationData['latitude'] as double?;
          final driverLng = locationData['longitude'] as double?;

          if (driverLat != null && driverLng != null) {
            final driverLocation = LatLng(driverLat, driverLng);

            // ✅ تحديث موقع السائق وتعديل zoom تلقائيًا
            final fromLocation = _lastDriverLocation ?? driverLocation;
            final bearing = _calculateBearing(fromLocation, driverLocation);
            _lastDriverLocation = driverLocation;
            mapController.updateDriverLocation(
              driverLocation,
              bearing: bearing,
              tripId: trip.id,
              trip: trip,
            );

            logger.d('✅ تم تحديث موقع السائق: $driverLocation');
          }
        }
      } catch (e) {
        logger.e('❌ خطأ في تحديث موقع السائق: $e');
      }
    });
  }

  // 🧭 حساب الـ bearing بين موقعين
  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * (3.14159265359 / 180);
    final lat2 = to.latitude * (3.14159265359 / 180);
    final dLng = (to.longitude - from.longitude) * (3.14159265359 / 180);

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    double bearing = math.atan2(y, x) * (180 / 3.14159265359);
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  /// 🔥 دالة للتنقل إلى صفحة السائق الرئيسية مع التحقق من المسار
  void _navigateToDriverHome() {
    // ✅ التحقق أولاً إذا كنا بالفعل في المسار المطلوب
    if (Get.currentRoute != AppRoutes.DRIVER_HOME) {
      logger.i('➡️ التنقل إلى صفحة السائق الرئيسية: ${AppRoutes.DRIVER_HOME}');
      Get.offAllNamed(AppRoutes.DRIVER_HOME);
    } else {
      logger.i('ℹ️ نحن بالفعل في صفحة السائق الرئيسية.');
    }
  }

  @override
  void dispose() {
    logger.i('🧹 [Driver] بدء dispose لـ DriverTripTrackingView');

    _pulseController.dispose();
    _driverLocationSubscription?.cancel();
    _tripUpdatesSubscription?.cancel();
    _isExpanded.dispose();

    // ✅ تنظيف الماركرز فقط إذا لم تعد الرحلة نشطة
    final trip = driverController.currentTrip.value;
    if (trip == null || !trip.isActive) {
      logger.i('✅ تنظيف ماركرز الرحلة الملغاة');
      if (trip != null) {
        mapController.clearTripMarkers(tripId: trip.id);
      } else {
        mapController.clearTripMarkers();
      }
    } else {
      logger.i('⚠️ الرحلة لسة نشطة - لن يتم تنظيف الماركرز');
    }

    super.dispose();
    logger.i('✅ [Driver] تم dispose بنجاح');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final trip = driverController.currentTrip.value;

        if (trip == null) {
          logger.w('⚠️ [Tracking UI] currentTrip is NULL!');
          return const Center(child: CircularProgressIndicator());
        }

        logger.i(
            '✅ [Tracking UI] Trip loaded: ${trip.id}, Status: ${trip.status.name}');

        return AdaptiveMapContainer(
          hasContent: true,
          minMapHeightFraction: 0.75,
          mapWidget: Stack(
            key: ValueKey(trip.id),
            children: [
              QuickMap.forTracking(
                mapController.mapController,
                mapController.mapCenter.value,
                mapController.markers.toList(),
              ),
              Positioned(
                bottom: 70,
                left: 12,
                child:GoToMyLocationButton(onPressed: () {
                if (mapController.currentLocation.value != null) {
                  mapController.mapController.move(
                    mapController.currentLocation.value!,
                    16.0,
                  );
                }
              })),
              Positioned(
                bottom: 50,
                right: 12,
                child: TripTrackingSharedWidgets().buildCancellationButton(
                  trip,
                  isDriver: true,
                ),
              ),
              TripTrackingSharedWidgets.buildNavigationMap(
                trip: trip,
                onNavigatePressed: () =>
                    TripTrackingSharedWidgets.showNavigationOptions(trip),
                context: context,
              ),
              DestinationChangeAlert(),
            ],
          ),
          bottomContent: _buildBottomActionPanel(trip),
        );
      }),
    );
  }

  Widget _buildBottomActionPanel(TripModel trip) {
    final rider = trip.rider;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 1),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            if (rider != null)
              TripTrackingSharedWidgets.buildUserInfoSectionExpanded(
                user: trip.rider!,
                userType: 'rider',
                trip: trip,
                onChatPressed: () => TripTrackingSharedWidgets.openChat(
                  trip: trip,
                  otherUserId: trip.riderId!,
                  otherUserName: trip.rider!.name,
                  currentUserType: 'driver',
                ),
                onCallPressed: () => TripTrackingSharedWidgets.showCallOptions(
                    trip.driver?.phone),
              )
            else
              const Center(child: Text('جاري تحميل بيانات الراكب...')),
            const SizedBox(height: 1),
            TripTrackingSharedWidgets().buildExpandableDetails(
              trip: trip,
              isExpandedNotifier: _isExpanded,
            ),
            const SizedBox(height: 1),
            _buildActionButtons(trip),
            const SizedBox(height: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(TripModel trip) {
    switch (trip.status) {
      case TripStatus.accepted:
        return _buildArrivedButton();
      case TripStatus.driverArrived:
        return _buildStartTripButton();
      case TripStatus.inProgress:
        return _buildEndTripButton();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildArrivedButton() {
    return Material(
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _markAsArrived,
        child: Ink(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.redAccent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.touch_app, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'وصلت إلى الراكب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartTripButton() {
    return HoldToStartButton(
      onCompleted: _startTrip,
      idleText: 'ركب الزبون/بدء الرحلة',
      holdingText: 'استمر بالضغط',
    );
  }

  Widget _buildEndTripButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final trip = driverController.currentTrip.value;
          if (trip == null) return;

          final confirm = await showGeneralDialog<bool>(
            context: Get.context!,
            barrierDismissible: false,
            barrierColor: Colors.black54,
            transitionDuration: const Duration(milliseconds: 250),
            pageBuilder: (context, animation, secondaryAnimation) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    elevation: 10,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'تأكيد إنهاء الرحلة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'هل أنت متأكد أنك تريد إنهاء الرحلة؟',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  style: OutlinedButton.styleFrom(
                                    side:
                                        BorderSide(color: Colors.grey.shade400),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: const Text(
                                    'إلغاء',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    elevation: 3,
                                  ),
                                  child: const Text(
                                    'نعم، إنهِ الرحلة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: child,
                ),
              );
            },
          );

          if (confirm == true) {
            await driverController.endTrip(trip.id);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          'إنهاء الرحلة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _markAsArrived() async {
    try {
      await driverController.markAsArrived();
      Get.snackbar(
        'تم التحديث',
        'تم إعلام الراكب بأنك وصلت',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر تحديث الحالة',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _startTrip() async {
    try {
      await driverController.startTrip(driverController.currentTrip.value!.id);
      Get.snackbar(
        'تم بدء الرحلة',
        'جاري التوجه إلى الوجهة',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر بدء الرحلة',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
