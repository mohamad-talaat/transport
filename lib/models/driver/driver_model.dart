import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/base_user_model.dart';

enum DriverStatus { pending, approved, rejected, suspended }

enum VehicleType { car, motorcycle, van, truck }

class DriverModel extends BaseUserModel {
  // Driver-specific fields
  final String? nationalId;
  final String? nationalIdImage;
  final String? drivingLicense;
  final String? drivingLicenseImage;
  final String? vehicleLicense;
  final String? vehicleLicenseImage;
  final VehicleType? vehicleType;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? vehiclePlateNumber;
  final String? vehicleImage;
  final String? insuranceImage;
  final String? backgroundCheckImage;

  // Driver status
  final DriverStatus status;
  @override
  final bool isOnline;
  final bool isAvailable;
  final String? currentLocation;
  final double? currentLatitude;
  final double? currentLongitude;

  // Statistics
  final int totalTrips;
  final double totalEarnings;
  final double rating;
  final int ratingCount;

  // Additional data
  final String? emergencyContact;
  final String? emergencyContactName;
  final List<String> documents;
  final Map<String, dynamic>? vehicleDetails;

  DriverModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.email,
    super.profileImage,
    super.balance = 0.0,
    required super.createdAt,
    super.isActive = true,
    super.isVerified = false,
    super.isApproved = false,
    super.approvedAt,
    super.approvedBy,
    super.isRejected = false,
    super.rejectedAt,
    super.rejectedBy,
    super.rejectionReason,
    super.isProfileComplete = false,
    super.additionalData,
    super.fcmToken,

    // Driver-specific fields
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

    // Status
    this.status = DriverStatus.pending,
    this.isOnline = false,
    this.isAvailable = false,
    this.currentLocation,
    this.currentLatitude,
    this.currentLongitude,

    // Statistics
    this.totalTrips = 0,
    this.totalEarnings = 0.0,
    this.rating = 0.0,
    this.ratingCount = 0,

    // Additional data
    this.emergencyContact,
    this.emergencyContactName,
    this.documents = const [],
    this.vehicleDetails,
  });

  @override
  String get userType => 'driver';

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.additionalData ?? {},
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
      'fcmToken': fcmToken,

      // Driver-specific fields
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

      // Status
      'status': status.name,
      'isOnline': isOnline,
      'isAvailable': isAvailable,
      'currentLocation': currentLocation,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,

      // Statistics
      'totalTrips': totalTrips,
      'totalEarnings': totalEarnings,
      'rating': rating,
      'ratingCount': ratingCount,

      // Additional data
      'emergencyContact': emergencyContact,
      'emergencyContactName': emergencyContactName,
      'documents': documents,
      'vehicleDetails': vehicleDetails,
    };
  }

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

      // Driver-specific fields
      nationalId: map['nationalId'],
      nationalIdImage: map['nationalIdImage'],
      drivingLicense: map['drivingLicense'],
      drivingLicenseImage: map['drivingLicenseImage'],
      vehicleLicense: map['vehicleLicense'],
      vehicleLicenseImage: map['vehicleLicenseImage'],
      vehicleType: map['vehicleType'] != null
          ? VehicleType.values.firstWhere((e) => e.name == map['vehicleType'],
              orElse: () => VehicleType.car)
          : null,
      vehicleModel: map['vehicleModel'],
      vehicleColor: map['vehicleColor'],
      vehiclePlateNumber: map['vehiclePlateNumber'],
      vehicleImage: map['vehicleImage'],
      insuranceImage: map['insuranceImage'],
      backgroundCheckImage: map['backgroundCheckImage'],

      // Status
      status: map['status'] != null
          ? DriverStatus.values.firstWhere((e) => e.name == map['status'],
              orElse: () => DriverStatus.pending)
          : DriverStatus.pending,
      isOnline: map['isOnline'] ?? false,
      isAvailable: map['isAvailable'] ?? false,
      currentLocation: map['currentLocation'],
      currentLatitude: map['currentLatitude']?.toDouble(),
      currentLongitude: map['currentLongitude']?.toDouble(),

      // Statistics
      totalTrips: map['totalTrips'] ?? 0,
      totalEarnings: (map['totalEarnings'] ?? 0.0).toDouble(),
      rating: (map['rating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,

      // Additional data
      emergencyContact: map['emergencyContact'],
      emergencyContactName: map['emergencyContactName'],
      documents: List<String>.from(map['documents'] ?? []),
      vehicleDetails: map['vehicleDetails'],
    );
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

  // Helper methods
  bool get hasCompleteDocuments =>
      nationalId != null &&
      drivingLicense != null &&
      vehicleLicense != null &&
      vehicleType != null &&
      vehicleModel != null &&
      vehiclePlateNumber != null;

  bool get canAcceptTrips =>
      isEligible && isOnline && isAvailable && hasCompleteDocuments;

  String get statusDisplayText {
    switch (status) {
      case DriverStatus.pending:
        return 'في انتظار الموافقة';
      case DriverStatus.approved:
        return 'تمت الموافقة';
      case DriverStatus.rejected:
        return 'مرفوض';
      case DriverStatus.suspended:
        return 'معلق';
    }
  }

  String get vehicleTypeDisplayText {
    switch (vehicleType) {
      case VehicleType.car:
        return 'سيارة';
      case VehicleType.motorcycle:
        return 'دراجة نارية';
      case VehicleType.van:
        return 'فان';
      case VehicleType.truck:
        return 'شاحنة';
      default:
        return 'غير محدد';
    }
  }
}
