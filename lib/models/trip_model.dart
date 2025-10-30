
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/models/user_model.dart';

enum TripStatus {
  pending,
  accepted,
  driverArrived,
  inProgress,
  completed,
  cancelled,
}
// ✅ نوع الرحلة الجديد
enum TripType {
  taxi,           // تاكسي عادي
  lineHire,       // تأجير خطوط
  delivery,       // طلبات
}
// ✅ إضافة enum RiderType هنا
enum RiderType {
  regularTaxi,
  lineService,
  delivery,
  external,
}

 
class AdditionalStop {
  final String id;
  final LatLng location;
  final String address;
  final int stopNumber;

  AdditionalStop({
    required this.id,
    required this.location,
    required this.address,
    required this.stopNumber,
  });

  // 3. دالة copyWith لتحديث الكائن بسهولة
  AdditionalStop copyWith({
    String? id,
    LatLng? location,
    String? address,
    int? stopNumber,
  }) {
    return AdditionalStop(
      id: id ?? this.id,
      location: location ?? this.location,
      address: address ?? this.address,
      stopNumber: stopNumber ?? this.stopNumber,
    );
  }

  factory AdditionalStop.fromMap(Map<String, dynamic> map) {
    return AdditionalStop(
      id: map['id'] ?? '',
      location: LatLng(
        (map['location']?['lat'] as num?)?.toDouble() ?? 0.0,
        (map['location']?['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      address: map['address'] ?? '',
      stopNumber: (map['stopNumber'] as num?)?.toInt() ?? 0,
      // 4. قراءة وقت الانتظار من الـ Map مع قيمة افتراضية
     );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'location': {'lat': location.latitude, 'lng': location.longitude},
        'address': address,
        'stopNumber': stopNumber,
       };
}


class LocationPoint {
  final double lat;
  final double lng;
  final String address;

  LocationPoint({
    required this.lat,
    required this.lng,
    required this.address,
  });

  LatLng get latLng => LatLng(lat, lng);

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      lat: map['lat']?.toDouble() ?? 0.0,
      lng: map['lng']?.toDouble() ?? 0.0,
      address: map['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'address': address,
    };
  }
}

class TripModel {
  final String id;
  final String? riderId;
  final String? driverId;
  final bool isPlusTrip;
  final String? riderName;
  final TripType tripType; // ✅ نوع الرحلة
  UserModel? driver; // Keep driver here, but it's populated separately
  UserModel? rider; // <--- ADDED: Field to hold rider UserMoel
    final RiderType riderType; // ✅ إضافة نوع الراكب هنا

  final LocationPoint pickupLocation;
  final LocationPoint destinationLocation;
  final TripStatus status;
  final double fare;
  final double distance;
  final int estimatedDuration;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final List<LatLng>? routePolyline;

  // final List<Map<String, dynamic>> additionalStops;
final List<AdditionalStop> additionalStops;

  final bool isRoundTrip;


  final int waitingTime;
  final bool isRush;
  final String? paymentMethod;
  final bool destinationChanged;
  final DateTime? destinationChangedAt;
  final bool driverNotified;
  final bool? driverApproved;
  final double? newFare;
  final int? driverRating;
  final String? driverComment;
  final int? riderRating;
  final String? riderComment;

  TripModel({
    required this.id,
    required this.riderId,
        this.driver, // <--- ADDED: driver to constructor
    this.rider,  // <--- ADDED: rider to constructor
    this.driverId,
 this.tripType = TripType.taxi,
    this.riderType = RiderType.regularTaxi, // ✅ تعيين قيمة افتراضية
    this.riderName,
    this.isPlusTrip = false,
    required this.pickupLocation,
    required this.destinationLocation,
    this.status = TripStatus.pending,
    required this.fare,
    required this.distance,
    required this.estimatedDuration,
    required this.createdAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.notes,
    this.routePolyline,
    this.additionalStops = const [],
    this.isRoundTrip = false,
    this.waitingTime = 0,
    this.isRush = false,
    this.paymentMethod,
    this.destinationChanged = false,
    this.destinationChangedAt,
    this.driverNotified = false,
    this.driverApproved,
    this.newFare,
    this.driverRating,
    this.driverComment,
    this.riderRating,
    this.riderComment,
  });

  factory TripModel.fromMap(Map<String, dynamic> map) {
    List<LatLng>? polyline;
    if (map['routePolyline'] != null) {
      polyline = (map['routePolyline'] as List)
          .map((point) => LatLng(
                point['lat']?.toDouble() ?? 0.0,
                point['lng']?.toDouble() ?? 0.0,
              ))
          .toList();
    }

    return TripModel(
      id: map['id'] ?? '',
      riderId: map['riderId'] ?? '',
    driverId: map['driverId'] as String?, // Explicitly cast as nullable String
      isPlusTrip: map['isPlusTrip'] ?? false,
      riderName: map['riderName'] as String?,
      pickupLocation: LocationPoint.fromMap(map['pickupLocation'] ?? {}),
      destinationLocation:
          LocationPoint.fromMap(map['destinationLocation'] ?? {}),
      status: TripStatus.values.firstWhere(
        (e) => e.toString() == 'TripStatus.${map['status']}',
        orElse: () => TripStatus.pending,
      ),
          tripType: TripType.values.firstWhere(
        (e) => e.toString() == 'TripType.${map['tripType']}', // ✅ التأكد من جلب TripType بشكل صحيح
        orElse: () => TripType.taxi,
      ),
      riderType: RiderType.values.firstWhere( // ✅ جلب RiderType من الخريطة
        (e) => e.toString() == 'RiderType.${map['riderType']}',
        orElse: () => RiderType.regularTaxi,
      ),
      fare: (map['fare'] ?? 0.0).toDouble(),
      distance: (map['distance'] ?? 0.0).toDouble(),
      estimatedDuration: (map['estimatedDuration'] ?? 0).toInt(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
      startedAt: (map['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      notes: map['notes'],
      routePolyline: polyline,
      // additionalStops:
      //     List<Map<String, dynamic>>.from(map['additionalStops'] ?? []),
additionalStops: (map['additionalStops'] as List<dynamic>?)
    ?.map((stop) => AdditionalStop.fromMap(Map<String, dynamic>.from(stop)))
    .toList() ??
    [],

      isRoundTrip: map['isRoundTrip'] ?? false,
      waitingTime: (map['waitingTime'] ?? 0).toInt(),
      isRush: map['isRush'] ?? false,
      paymentMethod: map['paymentMethod'],
      destinationChanged: map['destinationChanged'] ?? false,
      destinationChangedAt:
          (map['destinationChangedAt'] as Timestamp?)?.toDate(),
      driverNotified: map['driverNotified'] ?? false,
      driverApproved: map['driverApproved'],
      newFare: map['newFare']?.toDouble(),
      driverRating: (map['driverRating'] as num?)?.toInt(),
      driverComment: map['driverComment'],
      riderRating: (map['riderRating'] as num?)?.toInt(),
      riderComment: map['riderComment'],
    );
  }

  Map<String, dynamic> toMap() {
    List<Map<String, double>>? polylineData;
    if (routePolyline != null) {
      polylineData = routePolyline!
          .map((point) => {
                'lat': point.latitude,
                'lng': point.longitude,
              })
          .toList();
    }

    return {
      'id': id,
      'riderId': riderId,
      'driverId': driverId,
      'isPlusTrip': isPlusTrip,
      'riderName': riderName,
      'pickupLocation': pickupLocation.toMap(),
      'destinationLocation': destinationLocation.toMap(),
      'status': status.name,
           'tripType': tripType.name, // ✅ حفظ TripType بالاسم
      'riderType': riderType.name, // ✅ حفظ RiderType بالاسم
      'fare': fare,
      'distance': distance,
      'estimatedDuration': estimatedDuration,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'notes': notes,
      'routePolyline': polylineData,
      // 'additionalStops': additionalStops,
      'additionalStops': additionalStops.map((stop) => stop.toMap()).toList(),

      'isRoundTrip': isRoundTrip,
      'waitingTime': waitingTime,
      'isRush': isRush,
      'paymentMethod': paymentMethod,
      'destinationChanged': destinationChanged,
      'destinationChangedAt': destinationChangedAt != null
          ? Timestamp.fromDate(destinationChangedAt!)
          : null,
      'driverNotified': driverNotified,
      'driverApproved': driverApproved,
      'newFare': newFare,
      'driverRating': driverRating,
      'driverComment': driverComment,
      'riderRating': riderRating,
      'riderComment': riderComment,
    };
  }
 // ✅ إضافة دالة مساعدة لترجمة RiderType (اختياري لكن مفيد)
  String get riderTypeLabel {
    switch (riderType) {
      case RiderType.regularTaxi:
        return 'راكب عادي';
      case RiderType.lineService:
        return 'خدمة خطوط';
      case RiderType.delivery:
        return 'توصيل';
      case RiderType.external:
        return 'عميل خارجي';
    }
  }

 

  String get tripTypeLabel {
    switch (tripType) {
      case TripType.taxi:
        return 'طلب تاكسي ';
      case TripType.lineHire:
        return 'تأجير خطوط';
      case TripType.delivery:
        return 'طلبات';
    }
  }
 

  TripModel copyWith({
    String? id,
    String? riderId,
    String? driverId,
    LocationPoint? pickupLocation,
    LocationPoint? destinationLocation,
    TripStatus? status,
    String? riderName,
        UserModel? driver, // <--- ADDED: driver to copyWith
    UserModel? rider,  // <--- ADDED: rider to copyWith
    double? fare,
    double? distance,
    int? estimatedDuration,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? notes,
    List<LatLng>? routePolyline,
      List<AdditionalStop>? additionalStops, // <-- هنا
 TripType? tripType, // ✅ إضافة tripType لـ copyWith
    RiderType? riderType, // ✅ إضافة riderType لـ copyWith
    //  List<Map<String, dynamic>>? additionalStops,
    bool? isRoundTrip,
    int? waitingTime,
    bool? isRush,
    String? paymentMethod,
    bool? destinationChanged,
    DateTime? destinationChangedAt,
    bool? driverNotified,
    bool? driverApproved,
    double? newFare,
  }) {
    return TripModel(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      driverId: driverId ?? this.driverId,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      status: status ?? this.status,
      driver: driver ?? this.driver, // <--- ADDED: driver assignment
      rider: rider ?? this.rider,   // <--- ADDED: rider assignment
      fare: fare ?? this.fare,
      distance: distance ?? this.distance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      routePolyline: routePolyline ?? this.routePolyline,
    additionalStops: additionalStops ?? this.additionalStops, // <-- نفس السطر الآن تمام
      isRoundTrip: isRoundTrip ?? this.isRoundTrip,
      waitingTime: waitingTime ?? this.waitingTime,
      isRush: isRush ?? this.isRush,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      destinationChanged: destinationChanged ?? this.destinationChanged,
      destinationChangedAt: destinationChangedAt ?? this.destinationChangedAt,
      driverNotified: driverNotified ?? this.driverNotified,
      driverApproved: driverApproved ?? this.driverApproved,
      newFare: newFare ?? this.newFare,
        tripType: tripType ?? this.tripType, // ✅ تعيين tripType
      riderType: riderType ?? this.riderType, // ✅ تعيين riderType
      
    );
  }

  bool get isActive => [
        TripStatus.accepted,
        TripStatus.driverArrived,
        TripStatus.inProgress
      ].contains(status);

  bool get isCompleted =>
      [TripStatus.completed, TripStatus.cancelled].contains(status);

  String get statusText {
    switch (status) {
      case TripStatus.pending:
        return 'في انتظار السائق';
      case TripStatus.accepted:
        return 'تم قبول الرحلة';
      case TripStatus.driverArrived:
        return 'وصل السائق';
      case TripStatus.inProgress:
        return 'جاري التوصيل';
      case TripStatus.completed:
        return 'مكتملة';
      case TripStatus.cancelled:
        return 'ملغاة';
    }
  }
}
