import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/services/map_services/map_singleton_service.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/views/rider/rider_widgets/go_to_my_current_location.dart';
import 'package:transport_app/views/shared/trip_tracking_shared_widgets.dart';
import 'dart:math' as math;
import 'package:screenshot/screenshot.dart';

import '../../main.dart';

class RiderTripTrackingView extends StatefulWidget {
  const RiderTripTrackingView({super.key});

  @override
  State<RiderTripTrackingView> createState() => _RiderTripTrackingViewState();
}

class _RiderTripTrackingViewState extends State<RiderTripTrackingView>
    with TickerProviderStateMixin {
  final mapController = Get.find<MyMapController>();
  late final tripController = Get.find<TripController>();
  final authController = Get.find<AuthController>();
  final MapController flutterMapController = MapController();
  final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(false);
  bool _ratingPrompted = false;
  final RxBool _isLoadingDriverData = true.obs;
  StreamSubscription? _tripStreamSubscription;
  StreamSubscription? _driverLocationSubscription;
  bool _followDriver = true;
LatLng? _lastDriverLocation;
final ScreenshotController _screenshotController = ScreenshotController();

  // 🔥 Flag لمنع إعادة تنفيذ setup مرات متعددة
  bool _isViewInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeView();
  }

  /// ✅ دالة موحدة لتهيئة الـ View بشكل صحيح
  Future<void> _initializeView() async {
    if (_isViewInitialized) {
      logger.w('⚠️ View already initialized, skipping...');
      return;
    }

    try {
      logger.i('🔄 بدء تهيئة RiderTripTrackingView');

      final trip = tripController.activeTrip.value;
      if (trip == null) {
        logger.w('❌ لا توجد رحلة نشطة');
        _isLoadingDriverData.value = false;
        return;
      }

      // 1️⃣ جلب بيانات السائق من الـ Firebase إذا لم تكن موجودة
      await _ensureDriverDataLoaded(trip);

      // 2️⃣ الاستماع لتحديثات الرحلة المستمرة
      _listenToTripUpdates(trip.id);

      // 3️⃣ الاستماع للتغييرات في حالة الرحلة
      _listenToTripStatus();

      // 4️⃣ إعداد الخريطة والماركرز مرة واحدة فقط
      await _initializeMapAndMarkers();

      _isViewInitialized = true;
      _isLoadingDriverData.value = false;
      logger.i('✅ تم تهيئة RiderTripTrackingView بنجاح');
    } catch (e) {
      logger.e('❌ خطأ في تهيئة الـ View: $e');
      _isLoadingDriverData.value = false;
    }
  }

  /// 🔥 تهيئة الخريطة مرة واحدة فقط عند فتح الشاشة
  Future<void> _initializeMapAndMarkers() async {
    final trip = tripController.activeTrip.value;
    if (trip == null) return;

    // ⏰ انتظر حتى يتم رسم الـ frame الأول
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // 🔥 إعداد الماركرز مرة واحدة فقط
    mapController.setupRiderTripView(
      trip,
      mapController.currentLocation.value,
      driverLocation: mapController.driverLocation.value,
      driverBearing: 0.0,
    );

    logger.i('✅ تم إعداد ماركرز الرحلة للراكب');

    // ✅ تتبع موقع السائق من Firebase
    _listenToDriverLocation(trip.id);

// ✅ تتبع موقع الراكب محليًا وتحريك الخريطة
    ever(mapController.currentLocation, (location) async {
      if (location != null && mounted) {
        // تحديث ماركر الراكب على الخريطة
        mapController.updateRiderLocation(location);

        // تحريك الكاميرا بسلاسة لموقع الراكب لو متاح
        if (_followDriver == false) {
          // فقط لو المستخدم مش متابع السائق حاليًا
          mapController.animatedMapMove(location, 16.0, this);
        }

        // 🧠 لو حابب ترفع موقع الراكب إلى Firestore (اختياري)
        // await FirebaseFirestore.instance.collection('users')
        //   .doc(authController.currentUser.value!.id)
        //   .update({'currentLocation': {'latitude': location.latitude, 'longitude': location.longitude}});
      }
    });
  }

  /// ✅ الاستماع لموقع السائق من Firebase + تحريك الخريطة بسلاسة
  void _listenToDriverLocation(String tripId) {
    _driverLocationSubscription?.cancel();

    final trip = tripController.activeTrip.value;
    if (trip == null || trip.driverId == null) return;

    logger.d('📍 بدء الاستماع لموقع السائق: ${trip.driverId}');

    _driverLocationSubscription = tripController.firestore
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

            // ✅ تحديث موقع السائق على الخريطة بضمان 100%
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
           // ✅ تحديث موقع السائق وتعديل zoom تلقائيًا
            // final fromLocation = mapController.currentLocation.value ?? driverLocation;
            // final bearing = _calculateBearing(fromLocation, driverLocation);
_lastDriverLocation ??= driverLocation;

final fromLocation = _lastDriverLocation ?? driverLocation;
final bearing = _calculateBearing(fromLocation, driverLocation);
 
            mapController.updateDriverLocation(
              driverLocation,
              bearing: bearing,
              tripId: trip.id,
              trip: trip,
            );
if (_lastDriverLocation == null ||
    _lastDriverLocation!.latitude != driverLat ||
    _lastDriverLocation!.longitude != driverLng) {
  // نفّذ التحديث
}

            // ✅ تحريك الكاميرا بسلاسة لموقع السائق
            if (_followDriver) {
              mapController.animatedMapMove(driverLocation, 16.0, this);
            }

                logger.d('✅ تم تحديث موقع السائق: $driverLocation');
              }
            });
          }
        }
      } catch (e) {
        logger.e('❌ خطأ في تحديث موقع السائق: $e');
      }
    }, onError: (error) {
      logger.e('❌ خطأ في stream موقع السائق: $error');
    });
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

  /// ✅ جلب بيانات السائق من Firebase بشكل صحيح
  Future<void> _ensureDriverDataLoaded(TripModel trip) async {
    logger.d('🔍 فحص بيانات السائق في الرحلة');

    // إذا كانت البيانات موجودة بالفعل، لا نحتاج لجلبها مرة أخرى
    if (trip.driver != null && trip.driver!.name.isNotEmpty) {
      logger.i('✅ بيانات السائق موجودة بالفعل: ${trip.driver!.name}');
      return;
    }

    // إذا لم تكن البيانات موجودة، جلبها من Firebase
    if (trip.driverId != null && trip.driverId!.isNotEmpty) {
      try {
        logger.d('📥 جلب بيانات السائق من Firebase للـ ID: ${trip.driverId}');

        UserModel? fetchedDriver =
            await authController.getUserById(trip.driverId!);

        if (fetchedDriver != null) {
          logger.i('✅ تم جلب بيانات السائق: ${fetchedDriver.name}');

          // تحديث الرحلة مع بيانات السائق
          if (mounted) {
            tripController.activeTrip.value =
                trip.copyWith(driver: fetchedDriver);
            tripController.activeTrip.refresh();
          }
        } else {
          logger
              .w('⚠️ لم يتم العثور على بيانات السائق للـ ID: ${trip.driverId}');
        }
      } catch (e) {
        logger.e('❌ خطأ في جلب بيانات السائق: $e');
      }
    } else {
      logger.w('⚠️ لا يوجد driverId في الرحلة');
    }
  }

  /// ✅ الاستماع لتحديثات الرحلة من Firebase
  void _listenToTripUpdates(String tripId) {
    _tripStreamSubscription?.cancel();

    logger.d('🎧 بدء الاستماع لتحديثات الرحلة: $tripId');

    _tripStreamSubscription = tripController.firestore
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) {
        logger.w('❌ الرحلة لم تعد موجودة');
        return;
      }

      try {
        final data = snapshot.data() as Map<String, dynamic>;
        TripModel updatedTrip = TripModel.fromMap(data);

        logger.d('📡 تحديث جديد للرحلة - الحالة: ${updatedTrip.status.name}');

        // ✅ تحديث بيانات السائق إذا تغيرت أو كانت ناقصة
        if ((updatedTrip.driver == null || updatedTrip.driver!.name.isEmpty) &&
            updatedTrip.driverId != null &&
            updatedTrip.driverId!.isNotEmpty) {
          logger.d('🔄 بيانات السائق ناقصة، جاري الجلب من الـ Stream...');

          UserModel? freshDriver =
              await authController.getUserById(updatedTrip.driverId!);
          if (freshDriver != null) {
            updatedTrip = updatedTrip.copyWith(driver: freshDriver);
            logger.i(
                '✅ تم تحديث بيانات السائق من الـ Stream: ${freshDriver.name}');
          }
        }

        // تحديث الـ activeTrip
        if (mounted) {
          tripController.activeTrip.value = updatedTrip;
          tripController.activeTrip.refresh(); // تأكد من الـ refresh

          // 🔥🔥🔥 هنا النقطة الأساسية: أعد إعداد الماركرز بالرحلة المحدثة
          // تأكد أننا نمرر آخر موقع معروف للسائق
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              mapController.setupRiderTripView(
                updatedTrip, // الرحلة المحدثة
                mapController.currentLocation.value,
                driverLocation: mapController.driverLocation.value, // آخر موقع للسائق
                driverBearing: 0.0, // يمكنك تحديث الـ bearing إذا كان متوفراً
              );
              logger.i('✅ [Rider] تم إعادة إعداد ماركرز الرحلة بعد التحديث');
            }
          });
        }
      } catch (e) {
        logger.e('❌ خطأ في معالجة تحديث الرحلة: $e');
      }
    }, onError: (error) {
      logger.e('❌ خطأ في الاستماع لتحديثات الرحلة: $error');
    });
  }

  @override
  void dispose() {
    logger.i('🧹 Disposing RiderTripTrackingView...');

    // ✅ تنظيف الماركرز عند الخروج من الصفحة
    _cleanupTripMarkers();

    _isExpanded.dispose();
    _tripStreamSubscription?.cancel();
    _driverLocationSubscription?.cancel();

    _isViewInitialized = false;

    super.dispose();
  }

  /// 🔥 تنظيف شامل للماركرز
  void _cleanupTripMarkers() {
    try {
      final trip = tripController.activeTrip.value;
      if (trip != null) {
        mapController.clearTripMarkers(tripId: trip.id);
      } else {
      // لو مفيش رحلة نشطة، نظف جميع الماركرز المتعلقة بالرحلات وماركر السائق العام
      mapController.clearAllTripAndDriverMarkers(); // ✅ دالة جديدة في MyMapController
      }
      logger.i('✅ تم تنظيف جميع ماركرز الرحلة');
    } catch (e) {
      logger.e('خطأ في تنظيف الماركرز: $e');
    }
  }

  /// ✅ الاستماع لحالة الرحلة
  void _listenToTripStatus() {
    ever<TripModel?>(tripController.activeTrip, (trip) {
      if (trip == null) return;

      logger.d('📌 تحديث حالة الرحلة: ${trip.status.name}');

      if (trip.status == TripStatus.completed && !_ratingPrompted) {
        _ratingPrompted = true;
        _cleanupTripMarkers();
        logger.w('🎯 الرحلة اكتملت، الانتقال لصفحة التقييم');

        // ✅ إغلاق جميع الصفحات وفتح صفحة التقييم فوراً
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && Get.currentRoute == AppRoutes.RIDER_TRIP_TRACKING) {
            Get.offAllNamed(
              AppRoutes.TRIP_RATING,
              arguments: {'trip': trip, 'isDriver': false},
            );
          }
        });
      } else if (trip.status == TripStatus.cancelled) {
        logger.w('🚫 الرحلة ملغاة');
        _cleanupTripMarkers();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Get.offAllNamed(AppRoutes.RIDER_HOME);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final trip = tripController.activeTrip.value;

        // ⏳ عرض شاشة التحميل
        if (_isLoadingDriverData.value || trip == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // ✅ التحقق من حالة الرحلة قبل الرسم
        if (trip.status == TripStatus.completed && !_ratingPrompted) {
          _ratingPrompted = true;
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && Get.currentRoute == AppRoutes.RIDER_TRIP_TRACKING) {
              Get.offAllNamed(
                AppRoutes.TRIP_RATING,
                arguments: {'trip': trip, 'isDriver': false},
              );
            }
          });
          return const SizedBox();
        }

        return Screenshot(
  controller: _screenshotController,
  child: Stack(
          children: [
            // 🗺️ الخريطة
            Obx(() => QuickMap.forTracking(
                  mapController.mapController,
                  mapController.mapCenter.value,
                  mapController.markers.toList(),
                )),
            TripTrackingSharedWidgets.buildTopInfoBar(
              context,
              trip,
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height / 3 + 50,
              left: 10,
              child: FloatingActionButton.small(
                heroTag: 'follow_driver',
                backgroundColor: _followDriver ? Colors.green : Colors.grey,
                onPressed: () {
                  setState(() {
                    _followDriver = !_followDriver;
                    if (_followDriver &&
                        mapController.driverLocation.value != null) {
                      mapController.animatedMapMove(
                          mapController.driverLocation.value!, 16.0, this);
                    }
                  });
                  final message = _followDriver
                      ? 'تم تفعيل تتبع السائق'
                      : 'تم إيقاف تتبع السائق';
                  Get.snackbar('التتبع', message,
                      backgroundColor: Colors.blue, colorText: Colors.white);
                },
                child: Icon(
                  _followDriver ? Icons.gps_fixed : Icons.gps_off,
                  color: Colors.white,
                ),
              ),
            ),

            Positioned(
              bottom: MediaQuery.of(context).size.height / 3 + 25,
              right: 10,
              child: Column(
                children: [
                  TripTrackingSharedWidgets().buildCancellationButton(trip),
                  TripTrackingSharedWidgets.buildSmallActionButton(
                    icon: Icons.share,
                    label: 'مشاركةالرحلة',
                    color: Colors.purple,
                 onPressed: () => TripTrackingSharedWidgets.shareTripWithScreenshot(
  trip,
  _screenshotController,
),

                    // onPressed: () => TripTrackingSharedWidgets.shareTrip(trip),
                  ),
                  TripTrackingSharedWidgets.buildSmallActionButton(
                    icon: Icons.route_rounded,
                    label: 'تعديل الرحلة',
                    color: const Color.fromARGB(255, 234, 142, 4),
                    onPressed: () {
                      // if (trip.status != TripStatus.accepted) {
                      //   Get.snackbar('تنبيه', ' لا يمكنك تعديل الرحلةالان',
                      //       backgroundColor: Colors.orange,
                      //       colorText: Colors.white);
                      //   return;
                      // }
                      Get.toNamed(AppRoutes.EDIT_TRIP_LOCATION,
                          arguments: {'trip': trip});
                    },
                  ),
                ],
              ),
            ),
            GoToMyLocationButton(
              onPressed: () {
                if (mapController.currentLocation.value != null) {
                  mapController.mapController.move(
                    mapController.currentLocation.value!,
                    16.0,
                  );
                } else {
                  _centerOnRiderLocation();
                }
              },
            ),
            _buildBottomActionPanel(trip),
            // // ✅ بيانات السائق
            // Positioned(
            //   bottom: 16,
            //   left: 16,
            //   right: 16,
            //   child: _buildDriverInfoBottomSheet(trip),
            // ),
          ],
        ));
      }),
    );
  }

  Widget _buildBottomActionPanel(TripModel trip) {
    // ✅ تأكد من أن trip.rider موجود قبل استخدامه

    return Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: _buildDriverInfoBottomSheet(trip));
  }

  /// ✅ جلب الموقع الحالي للراكب
  Future<void> _centerOnRiderLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      flutterMapController.move(
        LatLng(position.latitude, position.longitude),
        16,
      );

      Get.snackbar(
        'الموقع',
        'تم تحديد موقعك الحالي',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      logger.e('❌ خطأ في جلب الموقع: $e');
      Get.snackbar(
        'خطأ',
        'تعذر تحديد موقعك',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// ✅ عرض بيانات السائق في الـ Bottom Sheet
  Widget _buildDriverInfoBottomSheet(TripModel trip) {
    // ⚠️ تحقق من وجود بيانات السائق قبل العرض
    if (trip.driver == null) {
      logger.w('⚠️ بيانات السائق غير متوفرة في الـ Bottom Sheet');
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تحميل بيانات السائق...'),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 مؤشر السحب (اختياري، ممكن تحذفه)
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // ✅ بيانات السائق
            TripTrackingSharedWidgets.buildUserInfoSectionExpanded(
              user: trip.driver,
              userType: 'driver',
              trip: trip,
              onChatPressed: () => TripTrackingSharedWidgets.openChat(
                trip: trip,
                otherUserId: trip.driverId!,
                otherUserName: trip.driver!.name,
                currentUserType: 'rider',
              ),
              onCallPressed: () =>
                  TripTrackingSharedWidgets.showCallOptions(trip.driver?.phone),
            ),

            const SizedBox(height: 4),
            const Divider(),
            const SizedBox(height: 4),

            // ✅ بيانات المركبة
            TripTrackingSharedWidgets.buildVehicleInfo(trip.driver),

            const SizedBox(height: 4),

            // ✅ قسم التفاصيل الإضافية القابل للتوسيع
            Theme(
              data: ThemeData().copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                // tilePadding: EdgeInsets.zero,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 4.0),

                // childrenPadding: const EdgeInsets.only(top: 2),
                          childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 4),

                leading: Icon(Icons.info_outline,
                    color: Colors.blue.shade700, size: 22),
                title: const Text(
                  'تفاصيل إضافية',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                children: [
                  TripTrackingSharedWidgets.buildDetailRow(
                    icon: Icons.straighten,
                    label: 'المسافة الكلية',
                    value: '${trip.distance.toStringAsFixed(1)} كم',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 3),
                  TripTrackingSharedWidgets.buildDetailRow(
                    icon: Icons.access_time,
                    label: 'الوقت المتوقع',
                    value: '${trip.estimatedDuration.toStringAsFixed(0)} دقيقة',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 3),
                  TripTrackingSharedWidgets.buildDetailRow(
                    icon: Icons.attach_money,
                    label: 'التكلفة',
                    value: '${trip.fare.toStringAsFixed(0)} د.ع',
                    color: Colors.green,
                  ),
                  if (trip.paymentMethod != null) ...[
                    const SizedBox(height: 3),
                    TripTrackingSharedWidgets.buildDetailRow(
                      icon: trip.paymentMethod == 'cash'
                          ? Icons.payments
                          : Icons.credit_card,
                      label: 'طريقة الدفع',
                      value:
                          trip.paymentMethod == 'cash' ? 'نقداً' : 'إلكتروني',
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 3),
                    TripTrackingSharedWidgets.buildDetailRow(
                      icon: Icons.transfer_within_a_station_outlined,
                      label: 'وقت الانتظار',
                      value: '${trip.waitingTime.toStringAsFixed(0)} دقيقة',
                      color: Colors.orange,
                    ),
                  ],
                  const SizedBox(height: 4),
                  TripTrackingSharedWidgets.buildTripPathsDetails(trip),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

   
}
