import 'package:cloud_firestore/cloud_firestore.dart';

enum DriverStatus { pending, approved, rejected, suspended }

enum VehicleType { car, motorcycle, van, truck }

class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? profileImage;
  late final double balance;
  final DateTime createdAt;
  final bool isActive;
  final bool isVerified;
  final bool isApproved;
  final DateTime? approvedAt;
  final String? approvedBy;
  final bool isRejected;
  final DateTime? rejectedAt;
  final String? rejectedBy;
  final String? rejectionReason;
  final bool isProfileComplete;
  final Map<String, dynamic>? additionalData;
  final String? fcmToken;

  // بيانات السائق المطلوبة
  final String? nationalId; // رقم الهوية الوطنية
  final String? nationalIdImage; // صورة الهوية
  final String? drivingLicense; // رقم رخصة القيادة
  final String? drivingLicenseImage; // صورة رخصة القيادة
  final String? vehicleLicense; // رقم رخصة السيارة
  final String? vehicleLicenseImage; // صورة رخصة السيارة
  final VehicleType? vehicleType; // نوع المركبة
  final String? vehicleModel; // موديل السيارة
  final String? vehicleColor; // لون السيارة
  final String? vehiclePlateNumber; // رقم اللوحة
  final String? vehicleImage; // صورة السيارة
  final String? insuranceImage; // صورة التأمين
  final String? backgroundCheckImage; // صورة فحص الخلفية الجنائية

  // حالة السائق
  final DriverStatus status;
  final bool isOnline; // هل متصل حالياً
  final bool isAvailable; // هل متاح للطلبات
  final String? currentLocation; // الموقع الحالي
  final double? currentLatitude;
  final double? currentLongitude;

  // إحصائيات
  final int totalTrips; // إجمالي الرحلات
  final double totalEarnings; // إجمالي الأرباح
  final double rating; // التقييم
  final int ratingCount; // عدد التقييمات

  // بيانات إضافية
  final String? emergencyContact; // رقم الطوارئ
  final String? emergencyContactName; // اسم جهة الطوارئ
  final List<String> documents; // قائمة المستندات المرفوعة
  final Map<String, dynamic>? vehicleDetails; // تفاصيل إضافية للمركبة

  DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.profileImage,
    this.balance = 0.0,
    required this.createdAt,
    this.isActive = true,
    this.isVerified = false,
    this.isApproved = false,
    this.approvedAt,
    this.approvedBy,
    this.isRejected = false,
    this.rejectedAt,
    this.rejectedBy,
    this.rejectionReason,
    this.isProfileComplete = false,
    this.additionalData,
    this.fcmToken,

    // بيانات السائق
    this.nationalId,
    this.nationalIdImage,
    this.drivingLicense,
    this.drivingLicenseImage,
    this.vehicleLicense,
    this.vehicleLicenseImage,
    this.vehicleType,
    this.vehicleModel,
    this.vehicleColor,
    this.vehiclePlateNumber,
    this.vehicleImage,
    this.insuranceImage,
    this.backgroundCheckImage,

    // الحالة
    this.status = DriverStatus.pending,
    this.isOnline = false,
    this.isAvailable = false,
    this.currentLocation,
    this.currentLatitude,
    this.currentLongitude,

    // الإحصائيات
    this.totalTrips = 0,
    this.totalEarnings = 0.0,
    this.rating = 0.0,
    this.ratingCount = 0,

    // بيانات إضافية
    this.emergencyContact,
    this.emergencyContactName,
    this.documents = const [],
    this.vehicleDetails,
  });

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    return DriverModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      profileImage: map['profileImage'],
      balance: (map['balance'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      isVerified: map['isVerified'] ?? false,
      isApproved: map['isApproved'] ?? false,
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      approvedBy: map['approvedBy'],
      isRejected: map['isRejected'] ?? false,
      rejectedAt: (map['rejectedAt'] as Timestamp?)?.toDate(),
      rejectedBy: map['rejectedBy'],
      rejectionReason: map['rejectionReason'],
      isProfileComplete: map['isProfileComplete'] ?? false,
      additionalData: map['additionalData'],
      fcmToken: map['fcmToken'],

      // بيانات السائق
      nationalId: map['nationalId'],
      nationalIdImage: map['nationalIdImage'],
      drivingLicense: map['drivingLicense'],
      drivingLicenseImage: map['drivingLicenseImage'],
      vehicleLicense: map['vehicleLicense'],
      vehicleLicenseImage: map['vehicleLicenseImage'],
      vehicleType: map['vehicleType'] != null
          ? VehicleType.values.firstWhere(
              (e) => e.toString() == 'VehicleType.${map['vehicleType']}',
              orElse: () => VehicleType.car,
            )
          : null,
      vehicleModel: map['vehicleModel'],
      vehicleColor: map['vehicleColor'],
      vehiclePlateNumber: map['vehiclePlateNumber'],
      vehicleImage: map['vehicleImage'],
      insuranceImage: map['insuranceImage'],
      backgroundCheckImage: map['backgroundCheckImage'],

      // الحالة
      status: DriverStatus.values.firstWhere(
        (e) => e.toString() == 'DriverStatus.${map['status']}',
        orElse: () => DriverStatus.pending,
      ),
      isOnline: map['isOnline'] ?? false,
      isAvailable: map['isAvailable'] ?? false,
      currentLocation: map['currentLocation'],
      currentLatitude: map['currentLatitude']?.toDouble(),
      currentLongitude: map['currentLongitude']?.toDouble(),

      // الإحصائيات
      totalTrips: map['totalTrips'] ?? 0,
      totalEarnings: (map['totalEarnings'] ?? 0.0).toDouble(),
      rating: (map['rating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,

      // بيانات إضافية
      emergencyContact: map['emergencyContact'],
      emergencyContactName: map['emergencyContactName'],
      documents: List<String>.from(map['documents'] ?? []),
      vehicleDetails: map['vehicleDetails'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'profileImage': profileImage,
      'balance': balance,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'isVerified': isVerified,
      'isApproved': isApproved,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'isRejected': isRejected,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'rejectedBy': rejectedBy,
      'rejectionReason': rejectionReason,
      'isProfileComplete': isProfileComplete,
      'additionalData': additionalData,
      'fcmToken': fcmToken,

      // بيانات السائق
      'nationalId': nationalId,
      'nationalIdImage': nationalIdImage,
      'drivingLicense': drivingLicense,
      'drivingLicenseImage': drivingLicenseImage,
      'vehicleLicense': vehicleLicense,
      'vehicleLicenseImage': vehicleLicenseImage,
      'vehicleType': vehicleType?.name,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'vehiclePlateNumber': vehiclePlateNumber,
      'vehicleImage': vehicleImage,
      'insuranceImage': insuranceImage,
      'backgroundCheckImage': backgroundCheckImage,

      // الحالة
      'status': status.name,
      'isOnline': isOnline,
      'isAvailable': isAvailable,
      'currentLocation': currentLocation,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,

      // الإحصائيات
      'totalTrips': totalTrips,
      'totalEarnings': totalEarnings,
      'rating': rating,
      'ratingCount': ratingCount,

      // بيانات إضافية
      'emergencyContact': emergencyContact,
      'emergencyContactName': emergencyContactName,
      'documents': documents,
      'vehicleDetails': vehicleDetails,
    };
  }

  // التحقق من اكتمال الملف الشخصي
  bool get isProfileFullyComplete {
    return nationalId != null &&
        nationalIdImage != null &&
        drivingLicense != null &&
        drivingLicenseImage != null &&
        vehicleLicense != null &&
        vehicleLicenseImage != null &&
        vehicleType != null &&
        vehicleModel != null &&
        vehicleColor != null &&
        vehiclePlateNumber != null &&
        vehicleImage != null &&
        insuranceImage != null &&
        backgroundCheckImage != null;
  }

  // التحقق من إمكانية استقبال الطلبات
  bool get canReceiveRequests {
    return isActive &&
        isApproved &&
        isProfileFullyComplete &&
        status == DriverStatus.approved;
  }

  DriverModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? profileImage,
    double? balance,
    DateTime? createdAt,
    bool? isActive,
    bool? isVerified,
    bool? isApproved,
    DateTime? approvedAt,
    String? approvedBy,
    bool? isRejected,
    DateTime? rejectedAt,
    String? rejectedBy,
    String? rejectionReason,
    bool? isProfileComplete,
    Map<String, dynamic>? additionalData,
    String? fcmToken,
    String? nationalId,
    String? nationalIdImage,
    String? drivingLicense,
    String? drivingLicenseImage,
    String? vehicleLicense,
    String? vehicleLicenseImage,
    VehicleType? vehicleType,
    String? vehicleModel,
    String? vehicleColor,
    String? vehiclePlateNumber,
    String? vehicleImage,
    String? insuranceImage,
    String? backgroundCheckImage,
    DriverStatus? status,
    bool? isOnline,
    bool? isAvailable,
    String? currentLocation,
    double? currentLatitude,
    double? currentLongitude,
    int? totalTrips,
    double? totalEarnings,
    double? rating,
    int? ratingCount,
    String? emergencyContact,
    String? emergencyContactName,
    List<String>? documents,
    Map<String, dynamic>? vehicleDetails,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      isApproved: isApproved ?? this.isApproved,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      isRejected: isRejected ?? this.isRejected,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      additionalData: additionalData ?? this.additionalData,
      fcmToken: fcmToken ?? this.fcmToken,
      nationalId: nationalId ?? this.nationalId,
      nationalIdImage: nationalIdImage ?? this.nationalIdImage,
      drivingLicense: drivingLicense ?? this.drivingLicense,
      drivingLicenseImage: drivingLicenseImage ?? this.drivingLicenseImage,
      vehicleLicense: vehicleLicense ?? this.vehicleLicense,
      vehicleLicenseImage: vehicleLicenseImage ?? this.vehicleLicenseImage,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehiclePlateNumber: vehiclePlateNumber ?? this.vehiclePlateNumber,
      vehicleImage: vehicleImage ?? this.vehicleImage,
      insuranceImage: insuranceImage ?? this.insuranceImage,
      backgroundCheckImage: backgroundCheckImage ?? this.backgroundCheckImage,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      isAvailable: isAvailable ?? this.isAvailable,
      currentLocation: currentLocation ?? this.currentLocation,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      totalTrips: totalTrips ?? this.totalTrips,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      documents: documents ?? this.documents,
      vehicleDetails: vehicleDetails ?? this.vehicleDetails,
    );
  }

  @override
  String toString() {
    return 'DriverModel(id: $id, name: $name, phone: $phone, email: $email, status: $status, isApproved: $isApproved, isProfileComplete: $isProfileComplete)';
  }
}
