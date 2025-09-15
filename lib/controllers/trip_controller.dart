// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:transport_app/controllers/map_controller.dart';
// import 'package:transport_app/main.dart';
// import 'package:transport_app/models/trip_model.dart';
// import 'package:transport_app/models/user_model.dart';
// import 'package:transport_app/routes/app_routes.dart';
// import 'package:transport_app/services/location_service.dart';
// import 'package:transport_app/services/app_settings_service.dart';
// import 'package:transport_app/controllers/auth_controller.dart';

// class TripController extends GetxController {
//   static TripController get to => Get.find();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Current trip state
//   final Rx<TripModel?> activeTrip = Rx<TripModel?>(null);
//   final RxBool hasActiveTrip = false.obs;
//   final RxBool isRequestingTrip = false.obs;
//   final Rx<DateTime?> activeSearchUntil = Rx<DateTime?>(null);
//   final RxInt remainingSearchSeconds = 0.obs;

//   // Trip history
//   final RxList<TripModel> tripHistory = <TripModel>[].obs;
//   final RxBool isLoadingHistory = false.obs;

//   // Available drivers
//   final RxList<DriverModel> availableDrivers = <DriverModel>[].obs;

//   // Real-time updates
//   StreamSubscription<DocumentSnapshot>? _tripStreamSubscription;
//   StreamSubscription<QuerySnapshot>? _driversStreamSubscription;
//   Timer? _tripTimeoutTimer;
//   Timer? _searchCountdownTimer;

//   // Controllers
//   final AuthController authController = AuthController.to;
//   final LocationService locationService = LocationService.to;
//   final AppSettingsService appSettingsService = AppSettingsService.to;

//   @override
//   void onInit() {
//     super.onInit();
//     _initializeTripController();
//   }

//   /// تهيئة متحكم الرحلات
//   void _initializeTripController() {
//     // تحقق من وجود رحلة نشطة عند فتح التطبيق
//     _checkActiveTrip();

//     // الاستماع للسائقين المتاحين
//     _listenToAvailableDrivers();

//     // تحديث حالة الرحلة النشطة
//     ever(activeTrip, (TripModel? trip) {
//       hasActiveTrip.value = trip != null && trip.isActive;

//       if (trip != null && trip.isActive) {
//         _startTripTracking(trip);
//       }
//     });
//   }

//   /// التحقق من وجود رحلة نشطة
//   Future<void> _checkActiveTrip() async {
//     try {
//       final user = authController.currentUser.value;
//       if (user == null) return;

//       QuerySnapshot querySnapshot = await _firestore
//           .collection('trips')
//           .where('riderId', isEqualTo: user.id)
//           .where('status',
//               whereIn: ['pending', 'accepted', 'driverArrived', 'inProgress'])
//           .orderBy('createdAt', descending: true)
//           .limit(1)
//           .get();

//       if (querySnapshot.docs.isNotEmpty) {
//         TripModel trip = TripModel.fromMap(
//             querySnapshot.docs.first.data() as Map<String, dynamic>);
//         activeTrip.value = trip;
//         _listenToTripUpdates(trip.id);
//       }
//     } catch (e) {
//       logger.w('خطأ في التحقق من الرحلة النشطة: $e');
//     }
//   }

//   /// الاستماع للسائقين المتاحين
//   void _listenToAvailableDrivers() {
//     _driversStreamSubscription = _firestore
//         .collection('users')
//         .where('userType', isEqualTo: 'driver')
//         .where('additionalData.isOnline', isEqualTo: true)
//         .snapshots()
//         .listen((snapshot) {
//       availableDrivers.clear();
//       for (var doc in snapshot.docs) {
//         try {
//           DriverModel driver = DriverModel.fromMap(doc.data());
//           availableDrivers.add(driver);
//         } catch (e) {
//           logger.w('خطأ في تحويل بيانات السائق: $e');
//         }
//       }
//     });
//   }

//    /// طلب رحلة جديدة
//   Future<void> requestTrip({
//     required LocationPoint pickup,
//     required LocationPoint destination,
//     Map<String, dynamic>? tripDetails,
//   }) async {
//     try {
//       if (isRequestingTrip.value) return; // ✅ منع أي استدعاء إضافي
//       isRequestingTrip.value = true;

//       // ✅ منع تكرار إنشاء رحلتين إذا كانت هناك رحلة نشطة قيد الانتظار
//       if (hasActiveTrip.value &&
//           activeTrip.value != null &&
//           activeTrip.value!.status == TripStatus.pending) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (Get.currentRoute != AppRoutes.RIDER_SEARCHING) {
//             Get.toNamed(AppRoutes.RIDER_SEARCHING, arguments: {
//               'pickup': activeTrip.value!.pickupLocation,
//               'destination': activeTrip.value!.destinationLocation,
//               'estimatedFare': activeTrip.value!.fare,
//               'estimatedDuration': activeTrip.value!.estimatedDuration,
//             });
//           }
//         });
//         isRequestingTrip.value = false; // ✅ مهم
//         return;
//       }

//       // التحقق من المستخدم
//       final user = authController.currentUser.value;
//       if (user == null) {
//         isRequestingTrip.value = false; // ✅ لازم ترجع false
//         throw Exception('يجب تسجيل الدخول أولاً');
//       }

//       // حساب المسافة والتكلفة
//       double distance = locationService.calculateDistance(
//         pickup.latLng,
//         destination.latLng,
//       );

//       int estimatedDuration = locationService.estimateDuration(distance);

//       // استخدام التكلفة من التفاصيل إذا كانت متاحة
//       double fare;
//       if (tripDetails != null && tripDetails.containsKey('totalFare')) {
//         fare = tripDetails['totalFare'] as double;
//       } else {
//         fare = _calculateFare(distance, tripDetails);
//       }

//       // التحقق من كفاية الرصيد
//       if (user.balance < fare) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Get.snackbar(
//             'رصيد غير كافي',
//             'يرجى شحن المحفظة أولاً',
//             snackPosition: SnackPosition.BOTTOM,
//           );
//           Get.toNamed(AppRoutes.RIDER_WALLET);
//         });
//         isRequestingTrip.value = false; // ✅ مهم
//         return;
//       }

//       // الحصول على مسار الرحلة
//       List<LatLng> routePoints = await locationService.getRoute(
//         pickup.latLng,
//         destination.latLng,
//       );

//       // إنشاء الرحلة
//       String tripId = _firestore.collection('trips').doc().id;

//       TripModel newTrip = TripModel(
//         id: tripId,
//         riderId: user.id,
//         pickupLocation: pickup,
//         destinationLocation: destination,
//         fare: fare,
//         distance: distance,
//         estimatedDuration: estimatedDuration,
//         createdAt: DateTime.now(),
//         routePolyline: routePoints,
//         // إضافة البيانات الإضافية
//         additionalStops: tripDetails?['additionalStops'] ?? [],
//         isRoundTrip: tripDetails?['isRoundTrip'] ?? false,
//         waitingTime: tripDetails?['waitingTime'] ?? 0,
//         isRush: tripDetails?['isRush'] ?? false,
//       );

//       // حفظ الرحلة في قاعدة البيانات
//       await _firestore.collection('trips').doc(tripId).set(newTrip.toMap());

//       if (authController.mockMode.value) {
//         await AuthController.to.simulateTripFlow(user.id);
//       }

//       // تحديث الحالة المحلية
//       activeTrip.value = newTrip;

//       // بدء الاستماع لتحديثات الرحلة
//       _listenToTripUpdates(tripId);

//       // الانتقال لشاشة البحث
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         Get.toNamed(AppRoutes.RIDER_SEARCHING, arguments: {
//           'pickup': pickup,
//           'destination': destination,
//           'estimatedFare': fare,
//           'estimatedDuration': estimatedDuration,
//         });
//       });

//       // إشعار السائقين المتاحين
//       await _notifyAvailableDrivers(newTrip);

//       // بدء عداد زمني لإلغاء الرحلة تلقائياً إذا لم يتم قبولها
//       _startTripTimeoutTimer(newTrip);

//       // بدء عدّاد مرئي 5 دقائق
//       _startSearchCountdown(const Duration(minutes: 5));
//     } catch (e) {
//       logger.w('خطأ في طلب الرحلة: $e');
//       if (activeTrip.value == null) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Get.snackbar(
//             'خطأ',
//             'تعذر طلب الرحلة، يرجى المحاولة مرة أخرى',
//             snackPosition: SnackPosition.BOTTOM,
//             backgroundColor: Colors.red,
//             colorText: Colors.white,
//           );
//         });
//       }
//     } finally {
//       isRequestingTrip.value = false; // ✅ هيترجع في كل الحالات
//     }
//   }

//   /// حساب تكلفة الرحلة

//   double _calculateFare(double distanceKm, Map<String, dynamic>? details) {
//     double baseFare = appSettingsService.calculateFare(distanceKm, null);

//     if (details != null) {
//       // إضافة تكلفة المحطات الإضافية
//       List<dynamic> additionalStops = details['additionalStops'] ?? [];
//       baseFare += additionalStops.length * 1.5 * 1500; // 1.5 دولار × سعر الصرف

//       // إضافة تكلفة الانتظار
//       int waitingTime = details['waitingTime'] ?? 0;
//       baseFare += waitingTime * 0.2 * 1500;

//       // ذهاب وعودة
//       bool isRoundTrip = details['isRoundTrip'] ?? false;
//       if (isRoundTrip) {
//         baseFare *= 1.8;
//       }

//       // رحلة مستعجلة
//       bool isRush = details['isRush'] ?? false;
//       if (isRush) {
//         baseFare *= 1.2;
//       }
//     }

//     return baseFare;
//   }

//   /// إشعار السائقين المتاحين
//   Future<void> _notifyAvailableDrivers(TripModel trip) async {
//     try {
//       // جلب السائقين المتصلين مباشرة من Firestore (ديناميكياً)
//       QuerySnapshot driversSnapshot = await _firestore
//           .collection('users')
//           .where('userType', isEqualTo: 'driver')
//           .where('additionalData.isOnline', isEqualTo: true)
//           .get();

//       // نصف قطر البحث عن السائقين بالكيلومتر (يمكن لاحقاً سحبه من AppSettings)
//       const double searchRadiusKm = 5.0;

//       // حساب المسافة وترشيح السائقين القريبين
//       final List<({DriverModel driver, double distanceKm})> candidates = [];
//       for (var doc in driversSnapshot.docs) {
//         try {
//           final data = doc.data() as Map<String, dynamic>;
//           final DriverModel driver = DriverModel.fromMap(data);
//           if (driver.currentLat != null && driver.currentLng != null) {
//             final LatLng driverLoc =
//                 LatLng(driver.currentLat!, driver.currentLng!);
//             final double distanceKm = locationService.calculateDistance(
//                 trip.pickupLocation.latLng, driverLoc);
//             if (distanceKm <= searchRadiusKm) {
//               candidates.add((driver: driver, distanceKm: distanceKm));
//             }
//           }
//         } catch (_) {}
//       }

//       // ترتيب حسب الأقرب
//       candidates.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

//       if (candidates.isEmpty) {
//         logger.i('لا يوجد سائقون قريبون ضمن $searchRadiusKm كم');
//         return;
//       }

//       // إرسال طلبات للسائقين الأقرب أولاً (مثلاً أول 10)
//       final int maxDrivers = candidates.length < 10 ? candidates.length : 10;
//       for (int i = 0; i < maxDrivers; i++) {
//         final driver = candidates[i].driver;
//         await _firestore
//             .collection('trip_requests')
//             .doc('${trip.id}_${driver.id}')
//             .set({
//           'tripId': trip.id,
//           'driverId': driver.id,
//           'riderId': trip.riderId,
//           'status': 'pending',
//           'createdAt': Timestamp.now(),
//           'expiresAt': Timestamp.fromDate(
//               DateTime.now().add(const Duration(seconds: 30))),
//         });
//       }
//     } catch (e) {
//       logger.w('خطأ في إشعار السائقين: $e');
//     }
//   }

//   /// بدء عداد إلغاء الرحلة التلقائي
//   void _startTripTimeoutTimer(TripModel trip) {
//     _tripTimeoutTimer?.cancel();

//     _tripTimeoutTimer = Timer(const Duration(minutes: 5), () {
//       if (activeTrip.value?.id == trip.id &&
//           activeTrip.value?.status == TripStatus.pending) {
//         _cancelTripTimeout();
//       }
//     });
//   }

//   void _startSearchCountdown(Duration total) {
//     _searchCountdownTimer?.cancel();
//     final end = DateTime.now().add(total);
//     activeSearchUntil.value = end;
//     remainingSearchSeconds.value = total.inSeconds;

//     _searchCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
//       final now = DateTime.now();
//       if (activeSearchUntil.value == null) {
//         t.cancel();
//         remainingSearchSeconds.value = 0;
//         return;
//       }
//       final diff = activeSearchUntil.value!.difference(now).inSeconds;
//       if (diff <= 0) {
//         t.cancel();
//         remainingSearchSeconds.value = 0;
//       } else {
//         remainingSearchSeconds.value = diff;
//       }
//     });
//   }

//   void _stopSearchCountdown() {
//     _searchCountdownTimer?.cancel();
//     _searchCountdownTimer = null;
//     remainingSearchSeconds.value = 0;
//     activeSearchUntil.value = null;
//   }

//   /// إلغاء الرحلة بسبب انتهاء الوقت
//   Future<void> _cancelTripTimeout() async {
//     try {
//       if (activeTrip.value != null) {
//         await _firestore.collection('trips').doc(activeTrip.value!.id).update({
//           'status': TripStatus.cancelled.name,
//           'completedAt': Timestamp.now(),
//           'notes': 'تم الإلغاء تلقائياً - لم يتم العثور على سائق متاح',
//         });

//         Get.snackbar(
//           'تم إلغاء الرحلة',
//           'لم يتم العثور على سائق متاح',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.orange,
//           colorText: Colors.white,
//         );
//         // عند انتهاء المهلة: نظّف وابعد المستخدم للواجهة الرئيسية
//         _stopSearchCountdown();
//         Get.offAllNamed(AppRoutes.RIDER_HOME);
//       }
//     } catch (e) {
//       logger.w('خطأ في إلغاء الرحلة التلقائي: $e');
//     }
//   }

//   /// الاستماع لتحديثات الرحلة
//   void _listenToTripUpdates(String tripId) {
//     _tripStreamSubscription?.cancel();

//     _tripStreamSubscription = _firestore
//         .collection('trips')
//         .doc(tripId)
//         .snapshots()
//         .listen((snapshot) {
//       if (snapshot.exists) {
//         TripModel updatedTrip =
//             TripModel.fromMap(snapshot.data() as Map<String, dynamic>);
//         activeTrip.value = updatedTrip;

//         // إلغاء العداد الزمني إذا تم قبول الرحلة
//         if (updatedTrip.status != TripStatus.pending) {
//           _tripTimeoutTimer?.cancel();
//         }

//         // التعامل مع تغيير الحالة
//         _handleTripStatusChange(updatedTrip);
//       } else {
//         // تم حذف الرحلة
//         _clearActiveTrip();
//       }
//     });
//   }

//   /// التعامل مع تغيير حالة الرحلة
//   void _handleTripStatusChange(TripModel trip) {
//     switch (trip.status) {
//       case TripStatus.accepted:
//         Get.snackbar(
//           'تم قبول الرحلة',
//           'السائق في الطريق إليك',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//         );
//         _showAcceptanceInfo(trip);
//         break;

//       case TripStatus.driverArrived:
//         Get.snackbar(
//           'وصل السائق',
//           'السائق وصل إلى موقعك',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.blue,
//           colorText: Colors.white,
//         );
//         break;

//       case TripStatus.inProgress:
//         Get.snackbar(
//           'بدأت الرحلة',
//           'جاري التوجه إلى الوجهة',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.purple,
//           colorText: Colors.white,
//         );
//         break;

//       case TripStatus.completed:
//         _handleTripCompleted(trip);
//         break;

//       case TripStatus.cancelled:
//         _handleTripCancelled(trip);
//         break;

//       default:
//         break;
//     }
//   }

//   /// عرض معلومات السائق والراكب عند قبول الرحلة
//   void _showAcceptanceInfo(TripModel trip) async {
//     try {
//       // جلب بيانات السائق والراكب
//       UserModel? rider = authController.currentUser.value;
//       DriverModel? driver;
//       if (trip.driverId != null) {
//         final snap =
//             await _firestore.collection('users').doc(trip.driverId).get();
//         if (snap.exists) {
//           driver = DriverModel.fromMap(snap.data()!);
//         }
//       }

//       if (Get.context == null) return;

//       Get.dialog(
//         AlertDialog(
//           title: const Text('تفاصيل الأمان'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (driver != null) ...[
//                 const Align(
//                     alignment: Alignment.centerRight,
//                     child: Text('بيانات السائق:',
//                         style: TextStyle(fontWeight: FontWeight.bold))),
//                 ListTile(
//                   leading: driver.profileImage != null
//                       ? CircleAvatar(
//                           backgroundImage: NetworkImage(driver.profileImage!))
//                       : const CircleAvatar(child: Icon(Icons.person)),
//                   title: Text(driver.name ?? 'سائق'),
//                   subtitle: Text(driver.phone ?? ''),
//                 ),
//                 const SizedBox(height: 8),
//               ],
//               if (rider != null) ...[
//                 const Align(
//                     alignment: Alignment.centerRight,
//                     child: Text('بياناتك كراكب:',
//                         style: TextStyle(fontWeight: FontWeight.bold))),
//                 ListTile(
//                   leading: rider.profileImage != null
//                       ? CircleAvatar(
//                           backgroundImage: NetworkImage(rider.profileImage!))
//                       : const CircleAvatar(child: Icon(Icons.person)),
//                   title: Text(rider.name ?? 'راكب'),
//                   subtitle: Text(rider.phone ?? ''),
//                 ),
//               ],
//             ],
//           ),
//           actions: [
//             TextButton(onPressed: () => Get.back(), child: const Text('إغلاق')),
//           ],
//         ),
//       );
//     } catch (e) {
//       logger.w('خطأ أثناء عرض تفاصيل القبول: $e');
//     }
//   }

//   /// التعامل مع إنهاء الرحلة
//   void _handleTripCompleted(TripModel trip) {
//     // خصم التكلفة من رصيد المستخدم
//     authController.updateBalance(-trip.fare);

//     Get.snackbar(
//       'تمت الرحلة',
//       'وصلت بأمان إلى وجهتك',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.green,
//       colorText: Colors.white,
//     );

//     _clearActiveTrip();

//     // إضافة الرحلة إلى التاريخ
//     tripHistory.insert(0, trip);
//   }

//   /// التعامل مع إلغاء الرحلة
//   void _handleTripCancelled(TripModel trip) {
//     Get.snackbar(
//       'تم إلغاء الرحلة',
//       trip.notes ?? 'تم إلغاء الرحلة',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.orange,
//       colorText: Colors.white,
//     );

//     _clearActiveTrip();

//     // إضافة الرحلة إلى التاريخ
//     tripHistory.insert(0, trip);
//   }

//   /// بدء تتبع الرحلة
//   void _startTripTracking(TripModel trip) {
//     if (trip.driverId != null) {
//       // الاستماع لموقع السائق
//       _listenToDriverLocation(trip.driverId!);
//     }
//   }

//   /// الاستماع لموقع السائق
//   void _listenToDriverLocation(String driverId) {
//     _firestore.collection('users').doc(driverId).snapshots().listen((snapshot) {
//       if (snapshot.exists) {
//         try {
//           DriverModel driver = DriverModel.fromMap(snapshot.data()!);
//           if (driver.currentLat != null && driver.currentLng != null) {
//             LatLng driverLocation =
//                 LatLng(driver.currentLat!, driver.currentLng!);
//             // تحديث موقع السائق على الخريطة
//             Get.find<MapControllerr>().updateDriverLocation(driverLocation);
//           }
//         } catch (e) {
//           logger.w('خطأ في تحديث موقع السائق: $e');
//         }
//       }
//     });
//   }

//   /// إلغاء الرحلة
//   Future<void> cancelTrip() async {
//     final trip = activeTrip.value;
//     if (trip == null) return;

//     try {
//       // يمكن إلغاء الرحلة فقط إذا كانت في حالة الانتظار
//       if (trip.status != TripStatus.pending) {
//         Get.snackbar(
//           'لا يمكن الإلغاء',
//           'لا يمكن إلغاء الرحلة في هذه المرحلة',
//           snackPosition: SnackPosition.BOTTOM,
//         );
//         return;
//       }

//       // تحديث حالة الرحلة إلى ملغاة
//       await _firestore.collection('trips').doc(trip.id).update({
//         'status': TripStatus.cancelled.name,
//         'completedAt': Timestamp.now(),
//         'notes': 'تم الإلغاء من قبل الراكب',
//       });

//       // مسح الحالة المحلية
//       _clearActiveTrip();
//       _stopSearchCountdown(); // إذا ألغى الراكب بنفسه

//       // Get.snackbar(
//       //   'تم الإلغاء',
//       //   'تم إلغاء الرحلة بنجاح',
//       //   snackPosition: SnackPosition.BOTTOM,
//       // );
//       Get.offAllNamed(AppRoutes.RIDER_HOME);
//     } catch (e) {
//       logger.w('خطأ في إلغاء الرحلة: $e');
//       Get.snackbar(
//         'خطأ',
//         'تعذر إلغاء الرحلة، يرجى المحاولة مرة أخرى',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

//   /// تحميل تاريخ الرحلات
//   Future<void> loadTripHistory() async {
//     final user = authController.currentUser.value;
//     if (user == null) return;

//     try {
//       isLoadingHistory.value = true;

//       QuerySnapshot querySnapshot = await _firestore
//           .collection('trips')
//           .where('riderId', isEqualTo: user.id)
//           .where('status', whereIn: ['completed', 'cancelled'])
//           .orderBy('createdAt', descending: true)
//           .limit(50)
//           .get();

//       tripHistory.clear();
//       for (var doc in querySnapshot.docs) {
//         try {
//           TripModel trip =
//               TripModel.fromMap(doc.data() as Map<String, dynamic>);
//           tripHistory.add(trip);
//         } catch (e) {
//           logger.w('خطأ في تحويل بيانات الرحلة: $e');
//         }
//       }
//     } catch (e) {
//       logger.w('خطأ في تحميل تاريخ الرحلات: $e');
//       Get.snackbar(
//         'خطأ',
//         'تعذر تحميل تاريخ الرحلات',
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     } finally {
//       isLoadingHistory.value = false;
//     }
//   }

//   /// مسح الرحلة النشطة
//   void _clearActiveTrip() {
//     _tripStreamSubscription?.cancel();
//     _tripTimeoutTimer?.cancel();
//     activeTrip.value = null;
//     hasActiveTrip.value = false;

//     // مسح الخريطة
//     Get.find<MapControllerr>().clearMap();
//   }

//   /// تقييم الرحلة
//   Future<void> rateTrip(String tripId, double rating, String? comment) async {
//     try {
//       await _firestore.collection('trip_ratings').doc(tripId).set({
//         'tripId': tripId,
//         'riderId': authController.currentUser.value?.id,
//         'rating': rating,
//         'comment': comment,
//         'createdAt': Timestamp.now(),
//       });

//       Get.snackbar(
//         'شكراً لك',
//         'تم إرسال التقييم بنجاح',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//       );
//     } catch (e) {
//       logger.w('خطأ في إرسال التقييم: $e');
//       Get.snackbar(
//         'خطأ',
//         'تعذر إرسال التقييم',
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     }
//   }

//   /// البحث عن رحلة بالمعرف
//   Future<TripModel?> getTripById(String tripId) async {
//     try {
//       DocumentSnapshot doc =
//           await _firestore.collection('trips').doc(tripId).get();

//       if (doc.exists) {
//         return TripModel.fromMap(doc.data() as Map<String, dynamic>);
//       }
//       return null;
//     } catch (e) {
//       logger.w('خطأ في البحث عن الرحلة: $e');
//       return null;
//     }
//   }

//   /// حساب إحصائيات الرحلات
//   Map<String, dynamic> getTripStatistics() {
//     int completedTrips =
//         tripHistory.where((trip) => trip.status == TripStatus.completed).length;

//     int cancelledTrips =
//         tripHistory.where((trip) => trip.status == TripStatus.cancelled).length;

//     double totalSpent = tripHistory
//         .where((trip) => trip.status == TripStatus.completed)
//         .fold(0.0, (sum, trip) => sum + trip.fare);

//     double totalDistance = tripHistory
//         .where((trip) => trip.status == TripStatus.completed)
//         .fold(0.0, (sum, trip) => sum + trip.distance);

//     return {
//       'completedTrips': completedTrips,
//       'cancelledTrips': cancelledTrips,
//       'totalSpent': totalSpent,
//       'totalDistance': totalDistance,
//       'totalTrips': tripHistory.length,
//     };
//   }

//   @override
//   void onClose() {
//     _tripStreamSubscription?.cancel();
//     _driversStreamSubscription?.cancel();
//     _tripTimeoutTimer?.cancel();
//     super.onClose();
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/controllers/map_controller.dart';
// import 'package:transport_app/controllers/map_controller_copy.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/location_service.dart';
import 'package:transport_app/services/app_settings_service.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/views/rider/driver_info_widget.dart';

class TripController extends GetxController {
  static TripController get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current trip state
  final Rx<TripModel?> activeTrip = Rx<TripModel?>(null);
  final RxBool hasActiveTrip = false.obs;
  final RxBool isRequestingTrip = false.obs;
  final Rx<DateTime?> activeSearchUntil = Rx<DateTime?>(null);
  final RxInt remainingSearchSeconds = 0.obs;

  // Urgent mode
  final RxBool isUrgentMode = false.obs;

  // Trip history
  final RxList<TripModel> tripHistory = <TripModel>[].obs;
  final RxBool isLoadingHistory = false.obs;

  // Available drivers
  final RxList<DriverModel> availableDrivers = <DriverModel>[].obs;

  // Real-time updates
  StreamSubscription<DocumentSnapshot>? _tripStreamSubscription;
  StreamSubscription<QuerySnapshot>? _driversStreamSubscription;
  Timer? _tripTimeoutTimer;
  Timer? _searchCountdownTimer;

  // Controllers
  final AuthController authController = AuthController.to;
  final LocationService locationService = LocationService.to;
  final AppSettingsService appSettingsService = AppSettingsService.to;

  @override
  void onInit() {
    super.onInit();
    _initializeTripController();
  }

  /// تهيئة متحكم الرحلات
  void _initializeTripController() {
    // تحقق من وجود رحلة نشطة عند فتح التطبيق
    _checkActiveTrip();

    // الاستماع للسائقين المتاحين
    _listenToAvailableDrivers();

    // تحديث حالة الرحلة النشطة
    ever(activeTrip, (TripModel? trip) {
      hasActiveTrip.value = trip != null && trip.isActive;

      if (trip != null && trip.isActive) {
        _startTripTracking(trip);
      }
    });
  }

  /// التحقق من وجود رحلة نشطة
  Future<void> _checkActiveTrip() async {
    try {
      final user = authController.currentUser.value;
      if (user == null) return;

      QuerySnapshot querySnapshot = await _firestore
          .collection('trips')
          .where('riderId', isEqualTo: user.id)
          .where('status',
              whereIn: ['pending', 'accepted', 'driverArrived', 'inProgress'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        TripModel trip = TripModel.fromMap(
            querySnapshot.docs.first.data() as Map<String, dynamic>);
        activeTrip.value = trip;
        _listenToTripUpdates(trip.id);
      }
    } catch (e) {
      logger.w('خطأ في التحقق من الرحلة النشطة: $e');
    }
  }

  /// الاستماع للسائقين المتاحين
  void _listenToAvailableDrivers() {
    _driversStreamSubscription = _firestore
        .collection('users')
        .where('userType', isEqualTo: 'driver')
        .where('additionalData.isOnline', isEqualTo: true)
        .where('additionalData.debtIqD',
            isLessThan: appSettingsService.driverDebtLimitIqD)
        .snapshots()
        .listen((snapshot) {
      availableDrivers.clear();
      for (var doc in snapshot.docs) {
        try {
          DriverModel driver = DriverModel.fromMap(doc.data());
          availableDrivers.add(driver);
        } catch (e) {
          logger.w('خطأ في تحويل بيانات السائق: $e');
        }
      }
    });
  }

  /// طلب رحلة جديدة
  Future<void> requestTrip({
    required LocationPoint pickup,
    required LocationPoint destination,
    Map<String, dynamic>? tripDetails,
  }) async {
    try {
      if (isRequestingTrip.value) {
        logger.i(
            'Attempted to request trip while another request is in progress.');
        return; // منع أي استدعاء إضافي إذا كان طلب آخر قيد المعالجة
      }
      isRequestingTrip.value = true;

      // ✅ التعديل الرئيسي هنا: منع طلب رحلة جديدة إذا كانت هناك أي رحلة نشطة بالفعل
      if (activeTrip.value != null && activeTrip.value!.isActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'خطأ',
            'لديك رحلة نشطة حالياً. لا يمكنك طلب رحلة جديدة.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          // يمكنك هنا توجيه المستخدم إلى شاشة الرحلة النشطة إذا لزم الأمر
          // Get.offAllNamed(AppRoutes.RIDER_HOME); // أو أي مسار آخر مناسب
        });
        isRequestingTrip.value = false; // ✅ مهم جداً لإعادة تعيين الحالة
        return;
      }

      // التحقق من المستخدم
      final user = authController.currentUser.value;
      if (user == null) {
        isRequestingTrip.value = false; // ✅ لازم ترجع false
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      // حساب المسافة والتكلفة
      double distance = locationService.calculateDistance(
        pickup.latLng,
        destination.latLng,
      );

      int estimatedDuration = locationService.estimateDuration(distance);

      // استخدام التكلفة من التفاصيل إذا كانت متاحة
      double fare;
      if (tripDetails != null && tripDetails.containsKey('totalFare')) {
        fare = tripDetails['totalFare'] as double;
      } else {
        fare = _calculateFare(distance, tripDetails);
      }

      // التحقق من كفاية الرصيد
      if (user.balance < fare) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'رصيد غير كافي',
            'يرجى شحن المحفظة أولاً',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          Get.toNamed(AppRoutes.RIDER_WALLET);
        });
        isRequestingTrip.value = false; // ✅ مهم
        return;
      }

      // الحصول على مسار الرحلة
      List<LatLng> routePoints = await locationService.getRoute(
        pickup.latLng,
        destination.latLng,
      );

      // إنشاء الرحلة
      String tripId = _firestore.collection('trips').doc().id;

      TripModel newTrip = TripModel(
        id: tripId,
        riderId: user.id,
        pickupLocation: pickup,
        destinationLocation: destination,
        fare: fare,
        distance: distance,
        estimatedDuration: estimatedDuration,
        createdAt: DateTime.now(),
        routePolyline: routePoints,
        // إضافة البيانات الإضافية
        // additionalStops: (tripDetails?['additionalStops'] as List<dynamic>?)
        //         ?.map((e) => LocationPoint.fromMap(e as Map<String, dynamic>))
        //         .toList() ??
        //     [],
        isRoundTrip: tripDetails?['isRoundTrip'] ?? false,
        waitingTime: tripDetails?['waitingTime'] ?? 0,
        isRush: tripDetails?['isRush'] ?? false,
        paymentMethod: tripDetails?['paymentMethod'],
      );

      // حفظ الرحلة في قاعدة البيانات
      await _firestore.collection('trips').doc(tripId).set(newTrip.toMap());

      // ✅ تعديل: تمرير معرف الرحلة الجديدة لمحاكاة التدفق
      if (authController.mockMode.value) {
        await AuthController.to.simulateTripFlow(newTrip.id);
      }

      // تحديث الحالة المحلية
      activeTrip.value = newTrip;

      // بدء الاستماع لتحديثات الرحلة
      _listenToTripUpdates(tripId);

      // الانتقال لشاشة البحث
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.toNamed(AppRoutes.RIDER_SEARCHING, arguments: {
          'pickup': pickup,
          'destination': destination,
          'estimatedFare': fare,
          'estimatedDuration': estimatedDuration,
          'tripDetails': newTrip.toMap(), // تمرير الرحلة كلها
        });
      });

      // إشعار السائقين المتاحين
      await _notifyAvailableDrivers(newTrip);

      // بدء عداد زمني لإلغاء الرحلة تلقائياً إذا لم يتم قبولها (إلا إذا كان الوضع مستعجل)
      if (!isUrgentMode.value) {
        _startTripTimeoutTimer(newTrip);
      }

      // بدء عدّاد مرئي 5 دقائق (إلا إذا كان الوضع مستعجل)
      if (!isUrgentMode.value) {
        _startSearchCountdown(const Duration(minutes: 5));
      }
    } catch (e) {
      logger.w('خطأ في طلب الرحلة: $e');
      // عرض رسالة الخطأ فقط إذا لم يكن هناك بالفعل رحلة نشطة أو لم تظهر رسالة بسببها
      if (activeTrip.value == null || !activeTrip.value!.isActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'خطأ',
            'تعذر طلب الرحلة، يرجى المحاولة مرة أخرى',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        });
      }
    } finally {
      isRequestingTrip.value = false; // ✅ هيترجع في كل الحالات
    }
  }

  /// طلب رحلة في الوضع المستعجل
  Future<void> requestUrgentTrip({
    required LocationPoint pickup,
    required LocationPoint destination,
    Map<String, dynamic>? tripDetails,
  }) async {
    isUrgentMode.value = true;

    // إضافة رسوم إضافية للوضع المستعجل
    Map<String, dynamic> urgentDetails = Map.from(tripDetails ?? {});
    urgentDetails['isUrgent'] = true;
    urgentDetails['urgentFee'] = 5.0; // رسوم إضافية 5 دولار

    await requestTrip(
      pickup: pickup,
      destination: destination,
      tripDetails: urgentDetails,
    );
  }

  /// إلغاء الوضع المستعجل
  void cancelUrgentMode() {
    isUrgentMode.value = false;
  }

  /// حساب تكلفة الرحلة
  double _calculateFare(double distanceKm, Map<String, dynamic>? details) {
    double baseFare = appSettingsService.calculateFare(distanceKm, null);

    if (details != null) {
      // إضافة تكلفة المحطات الإضافية
      List<dynamic> additionalStops = details['additionalStops'] ?? [];
      baseFare += additionalStops.length * 1.5 * 1500; // 1.5 دولار × سعر الصرف

      // إضافة تكلفة الانتظار
      int waitingTime = details['waitingTime'] ?? 0;
      baseFare += waitingTime * 0.2 * 1500;

      // ذهاب وعودة
      bool isRoundTrip = details['isRoundTrip'] ?? false;
      if (isRoundTrip) {
        baseFare *= 1.8;
      }

      // رحلة مستعجلة
      bool isRush = details['isRush'] ?? false;
      if (isRush) {
        baseFare *= 1.2;
      }
    }

    return baseFare;
  }

  /// إشعار السائقين المتاحين
  Future<void> _notifyAvailableDrivers(TripModel trip) async {
    try {
      // جلب السائقين المتصلين مباشرة من Firestore (ديناميكياً)
      QuerySnapshot driversSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .where('additionalData.isOnline', isEqualTo: true)
          .get();

      // نصف قطر البحث عن السائقين بالكيلومتر (يمكن لاحقاً سحبه من AppSettings)
      const double searchRadiusKm = 5.0;

      // حساب المسافة وترشيح السائقين القريبين
      final List<({DriverModel driver, double distanceKm})> candidates = [];
      for (var doc in driversSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final DriverModel driver = DriverModel.fromMap(data);
          if (driver.currentLat != null && driver.currentLng != null) {
            final LatLng driverLoc =
                LatLng(driver.currentLat!, driver.currentLng!);
            final double distanceKm = locationService.calculateDistance(
                trip.pickupLocation.latLng, driverLoc);
            if (distanceKm <= searchRadiusKm) {
              candidates.add((driver: driver, distanceKm: distanceKm));
            }
          }
        } catch (_) {}
      }

      // ترتيب حسب الأقرب
      candidates.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      if (candidates.isEmpty) {
        logger.i('لا يوجد سائقون قريبون ضمن $searchRadiusKm كم');
        return;
      }

      // إرسال طلبات للسائقين الأقرب أولاً (مثلاً أول 10)
      final int maxDrivers = candidates.length < 10 ? candidates.length : 10;
      for (int i = 0; i < maxDrivers; i++) {
        final driver = candidates[i].driver;
        await _firestore
            .collection('trip_requests')
            .doc('${trip.id}_${driver.id}')
            .set({
          'tripId': trip.id,
          'driverId': driver.id,
          'riderId': trip.riderId,
          'status': 'pending',
          'createdAt': Timestamp.now(),
          'expiresAt': Timestamp.fromDate(
              DateTime.now().add(const Duration(seconds: 30))),
        });
      }
    } catch (e) {
      logger.w('خطأ في إشعار السائقين: $e');
    }
  }

  /// بدء عداد إلغاء الرحلة التلقائي
  void _startTripTimeoutTimer(TripModel trip) {
    _tripTimeoutTimer?.cancel();

    _tripTimeoutTimer = Timer(const Duration(minutes: 5), () {
      if (activeTrip.value?.id == trip.id &&
          activeTrip.value?.status == TripStatus.pending) {
        _cancelTripTimeout();
      }
    });
  }

  void _startSearchCountdown(Duration total) {
    _searchCountdownTimer?.cancel();
    final end = DateTime.now().add(total);
    activeSearchUntil.value = end;
    remainingSearchSeconds.value = total.inSeconds;

    _searchCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final now = DateTime.now();
      if (activeSearchUntil.value == null) {
        t.cancel();
        remainingSearchSeconds.value = 0;
        return;
      }
      final diff = activeSearchUntil.value!.difference(now).inSeconds;
      if (diff <= 0) {
        t.cancel();
        remainingSearchSeconds.value = 0;
      } else {
        remainingSearchSeconds.value = diff;
      }
    });
  }

  void _stopSearchCountdown() {
    _searchCountdownTimer?.cancel();
    _searchCountdownTimer = null;
    remainingSearchSeconds.value = 0;
    activeSearchUntil.value = null;
  }

  /// إلغاء الرحلة بسبب انتهاء الوقت
  Future<void> _cancelTripTimeout() async {
    try {
      if (activeTrip.value != null) {
        await _firestore.collection('trips').doc(activeTrip.value!.id).update({
          'status': TripStatus.cancelled.name,
          'completedAt': Timestamp.now(),
          'notes': 'تم الإلغاء تلقائياً - لم يتم العثور على سائق متاح',
        });

        Get.snackbar(
          'تم إلغاء الرحلة',
          'لم يتم العثور على سائق متاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        // عند انتهاء المهلة: نظّف وابعد المستخدم للواجهة الرئيسية
        _stopSearchCountdown();
        Get.offAllNamed(AppRoutes.RIDER_HOME);
      }
    } catch (e) {
      logger.w('خطأ في إلغاء الرحلة التلقائي: $e');
    }
  }

  /// الاستماع لتحديثات الرحلة
  void _listenToTripUpdates(String tripId) {
    _tripStreamSubscription?.cancel();

    _tripStreamSubscription = _firestore
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        TripModel updatedTrip =
            TripModel.fromMap(snapshot.data() as Map<String, dynamic>);
        activeTrip.value = updatedTrip;

        // إلغاء العداد الزمني إذا تم قبول الرحلة
        if (updatedTrip.status != TripStatus.pending) {
          _tripTimeoutTimer?.cancel();
        }

        // التعامل مع تغيير الحالة
        _handleTripStatusChange(updatedTrip);
      } else {
        // تم حذف الرحلة
        _clearActiveTrip();
      }
    });
  }

  /// التعامل مع تغيير حالة الرحلة
  void _handleTripStatusChange(TripModel trip) {
    switch (trip.status) {
      case TripStatus.pending:
        // لا حاجة لعمل شيء في حالة الانتظار
        break;
      case TripStatus.accepted:
        Get.snackbar(
          'تم قبول الرحلة',
          'السائق في الطريق إليك',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _showAcceptanceInfo(trip);
        break;

      case TripStatus.driverArrived:
        Get.snackbar(
          'وصل السائق',
          'السائق وصل إلى موقعك',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
        break;

      case TripStatus.inProgress:
        Get.snackbar(
          'بدأت الرحلة',
          'جاري التوجه إلى الوجهة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.purple,
          colorText: Colors.white,
        );
        break;

      case TripStatus.completed:
        _handleTripCompleted(trip);
        break;

      case TripStatus.cancelled:
        _handleTripCancelled(trip);
        break;
    }
  }

  /// عرض معلومات السائق والراكب عند قبول الرحلة
  void _showAcceptanceInfo(TripModel trip) async {
    try {
      // جلب بيانات السائق والراكب
      UserModel? rider = authController.currentUser.value;
      DriverModel? driver;
      if (trip.driverId != null) {
        final snap =
            await _firestore.collection('users').doc(trip.driverId).get();
        if (snap.exists) {
          driver = DriverModel.fromMap(snap.data()!);
        }
      }

      if (Get.context == null) return;

      // عرض معلومات السائق للراكب
      if (rider != null && driver != null) {
        Get.dialog(
          Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: DriverInfoWidget(
                driver: driver,
                vehicleInfo: '${driver.carModel} - ${driver.carColor}',
                rating: driver.additionalData?['rating']?.toDouble(),
                onCall: () {
                  Get.back();
                  // TODO: إضافة منطق الاتصال
                  Get.snackbar(
                    'اتصال',
                    'جاري الاتصال بـ ${driver!.name}',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                },
                onMessage: () {
                  Get.back();
                  // TODO: إضافة منطق الرسائل
                  Get.snackbar(
                    'رسالة',
                    'جاري فتح المحادثة مع ${driver!.name}',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.blue,
                    colorText: Colors.white,
                  );
                },
              ),
            ),
          ),
          barrierDismissible: true,
        );
      }
    } catch (e) {
      logger.w('خطأ أثناء عرض تفاصيل القبول: $e');
    }
  }

  /// التعامل مع إنهاء الرحلة
  void _handleTripCompleted(TripModel trip) {
    // خصم التكلفة من رصيد المستخدم إذا كانت طريقة الدفع عبر التطبيق
    if ((trip.paymentMethod ?? 'cash') == 'app') {
      authController.updateBalance(-trip.fare);
    }

    // إضافة عمولة التطبيق على السائق كدين
    try {
      final int commission = appSettingsService.commissionIqD(trip.distance);
      _increaseDriverDebt(trip.driverId, commission);
    } catch (_) {}

    Get.snackbar(
      'تمت الرحلة',
      'وصلت بأمان إلى وجهتك',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    _clearActiveTrip();

    // إضافة الرحلة إلى التاريخ
    tripHistory.insert(0, trip);
  }

  /// زيادة مديونية السائق
  Future<void> _increaseDriverDebt(String? driverId, int amountIqD) async {
    if (driverId == null) return;
    try {
      await _firestore.collection('users').doc(driverId).set({
        'additionalData': {
          'debtIqD': FieldValue.increment(amountIqD),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      logger.w('خطأ في زيادة مديونية السائق: $e');
    }
  }

  /// التعامل مع إلغاء الرحلة
  void _handleTripCancelled(TripModel trip) {
    Get.snackbar(
      'تم إلغاء الرحلة',
      trip.notes ?? 'تم إلغاء الرحلة',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );

    _clearActiveTrip();

    // إضافة الرحلة إلى التاريخ
    tripHistory.insert(0, trip);
  }

  /// بدء تتبع الرحلة
  void _startTripTracking(TripModel trip) {
    if (trip.driverId != null) {
      // الاستماع لموقع السائق
      _listenToDriverLocation(trip.driverId!);
    }
  }

  /// الاستماع لموقع السائق
  void _listenToDriverLocation(String driverId) {
    _firestore.collection('users').doc(driverId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        try {
          DriverModel driver = DriverModel.fromMap(snapshot.data()!);
          if (driver.currentLat != null && driver.currentLng != null) {
            LatLng driverLocation =
                LatLng(driver.currentLat!, driver.currentLng!);
            // تحديث موقع السائق على الخريطة
            Get.find<MapControllerr>().updateDriverLocation(driverLocation);
          }
        } catch (e) {
          logger.w('خطأ في تحديث موقع السائق: $e');
        }
      }
    });
  }

  /// إلغاء الرحلة
  Future<void> cancelTrip() async {
    final trip = activeTrip.value;
    if (trip == null) return;

    try {
      // يمكن إلغاء الرحلة فقط إذا كانت في حالة الانتظار أو القبول قبل أن تبدأ فعليًا
      // إذا كانت accepted ولكن السائق لم يصل بعد، يمكن الإلغاء مع غرامة محتملة
      if (trip.status == TripStatus.inProgress ||
          trip.status == TripStatus.driverArrived) {
        Get.snackbar(
          'لا يمكن الإلغاء',
          'لا يمكن إلغاء الرحلة بعد أن بدأت أو وصل السائق.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      String cancellationNote = 'تم الإلغاء من قبل الراكب';
      // يمكن إضافة منطق لفرض غرامة إذا كانت الرحلة مقبولة بالفعل
      if (trip.status == TripStatus.accepted) {
        cancellationNote = 'تم الإلغاء من قبل الراكب بعد قبول السائق.';
        // TODO: تطبيق غرامة إلغاء إذا كان التطبيق يتطلب ذلك
      }

      // تحديث حالة الرحلة إلى ملغاة
      await _firestore.collection('trips').doc(trip.id).update({
        'status': TripStatus.cancelled.name,
        'completedAt': Timestamp.now(),
        'notes': cancellationNote,
      });

      // مسح الحالة المحلية
      _clearActiveTrip();
      _stopSearchCountdown(); // إذا ألغى الراكب بنفسه

      // استخدام Get.back() بدلاً من Get.offAllNamed لتجنب إعادة إنشاء الكونترولرز
      Get.back();
    } catch (e) {
      logger.w('خطأ في إلغاء الرحلة: $e');
      Get.snackbar(
        'خطأ',
        'تعذر إلغاء الرحلة، يرجى المحاولة مرة أخرى',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// إلغاء الرحلة مع سبب محدد
  Future<void> cancelTripWithReason(String reason) async {
    final trip = activeTrip.value;
    if (trip == null) return;

    try {
      // يمكن إلغاء الرحلة فقط إذا كانت في حالة الانتظار أو القبول
      if (trip.status == TripStatus.inProgress ||
          trip.status == TripStatus.driverArrived) {
        Get.snackbar(
          'لا يمكن الإلغاء',
          'لا يمكن إلغاء الرحلة بعد أن بدأت أو وصل السائق.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      String cancellationNote = 'تم الإلغاء من قبل الراكب - السبب: $reason';

      // تحديث حالة الرحلة إلى ملغاة
      await _firestore.collection('trips').doc(trip.id).update({
        'status': TripStatus.cancelled.name,
        'completedAt': Timestamp.now(),
        'notes': cancellationNote,
        'cancellationReason': reason,
      });

      // مسح الحالة المحلية
      _clearActiveTrip();
      _stopSearchCountdown();

      // استخدام Get.back() بدلاً من Get.offAllNamed لتجنب إعادة إنشاء الكونترولرز
      Get.back();

      Get.snackbar(
        'تم إلغاء الرحلة',
        'تم إلغاء الرحلة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.w('خطأ في إلغاء الرحلة: $e');
      Get.snackbar(
        'خطأ',
        'تعذر إلغاء الرحلة، يرجى المحاولة مرة أخرى',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// تحميل تاريخ الرحلات
  Future<void> loadTripHistory() async {
    final user = authController.currentUser.value;
    if (user == null) return;

    try {
      isLoadingHistory.value = true;

      QuerySnapshot querySnapshot = await _firestore
          .collection('trips')
          .where('riderId', isEqualTo: user.id)
          .where('status', whereIn: ['completed', 'cancelled'])
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      tripHistory.clear();
      for (var doc in querySnapshot.docs) {
        try {
          TripModel trip =
              TripModel.fromMap(doc.data() as Map<String, dynamic>);
          tripHistory.add(trip);
        } catch (e) {
          logger.w('خطأ في تحويل بيانات الرحلة: $e');
        }
      }
    } catch (e) {
      logger.w('خطأ في تحميل تاريخ الرحلات: $e');
      Get.snackbar(
        'خطأ',
        'تعذر تحميل تاريخ الرحلات',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingHistory.value = false;
    }
  }

  /// مسح الرحلة النشطة
  void _clearActiveTrip() {
    _tripStreamSubscription?.cancel();
    _tripTimeoutTimer?.cancel();
    activeTrip.value = null;
    hasActiveTrip.value = false;

    // مسح الخريطة
    Get.find<MapControllerr>().clearMap();
  }

  /// تقييم الرحلة
  Future<void> rateTrip(String tripId, double rating, String? comment) async {
    try {
      await _firestore.collection('trip_ratings').doc(tripId).set({
        'tripId': tripId,
        'riderId': authController.currentUser.value?.id,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.now(),
      });

      Get.snackbar(
        'شكراً لك',
        'تم إرسال التقييم بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.w('خطأ في إرسال التقييم: $e');
      Get.snackbar(
        'خطأ',
        'تعذر إرسال التقييم',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// البحث عن رحلة بالمعرف
  Future<TripModel?> getTripById(String tripId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('trips').doc(tripId).get();

      if (doc.exists) {
        return TripModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      logger.w('خطأ في البحث عن الرحلة: $e');
      return null;
    }
  }

  /// حساب إحصائيات الرحلات
  Map<String, dynamic> getTripStatistics() {
    int completedTrips =
        tripHistory.where((trip) => trip.status == TripStatus.completed).length;

    int cancelledTrips =
        tripHistory.where((trip) => trip.status == TripStatus.cancelled).length;

    double totalSpent = tripHistory
        .where((trip) => trip.status == TripStatus.completed)
        .fold(0.0, (sum, trip) => sum + trip.fare);

    double totalDistance = tripHistory
        .where((trip) => trip.status == TripStatus.completed)
        .fold(0.0, (sum, trip) => sum + trip.distance);

    return {
      'completedTrips': completedTrips,
      'cancelledTrips': cancelledTrips,
      'totalSpent': totalSpent,
      'totalDistance': totalDistance,
      'totalTrips': tripHistory.length,
    };
  }

  // ✅ دالة مساعدة لتحويل حالة الرحلة إلى نص عربي للعرض

  @override
  void onClose() {
    _tripStreamSubscription?.cancel();
    _driversStreamSubscription?.cancel();
    _tripTimeoutTimer?.cancel();
    _searchCountdownTimer?.cancel(); // ✅ مهم لإيقاف العداد عند إغلاق الكنترولر
    super.onClose();
  }
}
