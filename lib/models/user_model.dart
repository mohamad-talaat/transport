import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { rider, driver, admin }

enum DriverStatus { pending, approved, rejected, suspended }

enum VehicleType { car, motorcycle, van, truck }

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? phoneNumber;
  final String email;
  final String? profileImage;
  final UserType userType;
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
  final String? fcmToken;

  // Driver Specific Fields
  final String? vehicleYear; // Changed to String? to accommodate mixed data, or int? if strictly numbers
  final String? plateNumber;
  final String? provinceCode;
  final String? plateLetter;
  final String? nationalId;
  final String? nationalIdImage;
  final String? drivingLicense;
  final String? drivingLicenseImage;
  final String? vehicleLicense;
  final String? vehicleLicenseImage;
  final VehicleType? vehicleType;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? vehicleImage;
  final String? insuranceImage;
  final String? backgroundCheckImage;
  final DriverStatus? driverStatus;
  final bool? isOnline;
  final bool? isAvailable;
  final String? currentLocation;
  final double? currentLatitude;
  final double? currentLongitude;
  final int? totalTrips;
  final double? totalEarnings;
  final double? rating;
  final int? ratingCount;
  final String? emergencyContact;
  final String? emergencyContactName;
  final List<String>? workingAreas;
  final String? provinceName;

  // Rider Specific Fields
  final String? riderType; // Renamed from RiderType for Dart conventions
  final List<String>? favoriteLocations;
  final double? totalSpent;

  final Map<String, dynamic>? additionalData;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.phoneNumber,
    required this.email,
    this.profileImage,
    required this.userType,
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
    this.fcmToken,
    this.vehicleYear,
    this.plateNumber,
    this.provinceCode,
    this.plateLetter,
    this.nationalId,
    this.nationalIdImage,
    this.drivingLicense,
    this.drivingLicenseImage,
    this.vehicleLicense,
    this.vehicleLicenseImage,
    this.vehicleType,
    this.vehicleModel,
    this.vehicleColor,
    this.vehicleImage,
    this.insuranceImage,
    this.backgroundCheckImage,
    this.driverStatus,
    this.isOnline,
    this.isAvailable,
    this.currentLocation,
    this.currentLatitude,
    this.currentLongitude,
    this.totalTrips,
    this.totalEarnings,
    this.rating,
    this.ratingCount,
    this.emergencyContact,
    this.emergencyContactName,
    this.workingAreas,
    this.provinceName,
    this.riderType, // Renamed
    this.favoriteLocations,
    this.totalSpent,
    this.additionalData,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Safely get additionalData
    final additionalData = map['additionalData'] as Map<String, dynamic>?;

    // Helper to parse enum safely
    T? parseEnum<T>(dynamic value, List<T> values, T Function(String) fromString, {T? orElse}) {
      if (value == null) return null;
      try {
        // Handle cases like 'UserType.rider' or just 'rider'
        String enumString = value.toString().split('.').last;
        return fromString(enumString);
      } catch (e) {
        return orElse;
      }
    }

    // Helper to safely convert to double
    double? toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    // Helper to safely convert to int
    int? toInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Helper to safely convert to String
    String? toString(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }


    return UserModel(
      id: toString(map['id']) ?? '',
      name: toString(map['name']) ?? '',
      phone: toString(map['phone']) ?? '',
      phoneNumber: toString(map['phoneNumber']),
      email: toString(map['email']) ?? '',
      profileImage: toString(map['profileImage']),
      userType: parseEnum(map['userType'], UserType.values, (s) => UserType.values.firstWhere((e) => e.name == s.toLowerCase()), orElse: UserType.rider)!,
      // Prioritize direct fields, then additionalData, then safe conversion
      plateNumber: toString(map['vehiclePlateNumber']) ?? toString(map['plateNumber']) ?? toString(additionalData?['plateNumber']),
      vehicleYear: toString(map['vehicleYear']) ?? toString(additionalData?['vehicleYear']), // Ensure it's handled as String
      balance: toDouble(map['balance']) ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      isVerified: map['isVerified'] ?? false,
      isApproved: map['isApproved'] ?? false,
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      approvedBy: toString(map['approvedBy']),
      isRejected: map['isRejected'] ?? false,
      rejectedAt: (map['rejectedAt'] as Timestamp?)?.toDate(),
      rejectedBy: toString(map['rejectedBy']),
      rejectionReason: toString(map['rejectionReason']),
      isProfileComplete: map['isProfileComplete'] ?? false,
      fcmToken: toString(map['fcmToken']),
      nationalId: toString(map['nationalId']),
      nationalIdImage: toString(map['nationalIdImage']) ?? toString(additionalData?['nationalIdImageFront']) ?? toString(additionalData?['idCardImage']),
      drivingLicense: toString(map['drivingLicense']),
      drivingLicenseImage: toString(map['drivingLicenseImage']) ?? toString(additionalData?['drivingLicenseImageFront']) ?? toString(additionalData?['licenseImage']),
      vehicleLicense: toString(map['vehicleLicense']),
      vehicleLicenseImage: toString(map['vehicleLicenseImage']),
      vehicleType: parseEnum(
        map['vehicleType'] ?? additionalData?['carType'],
        VehicleType.values,
        (s) => VehicleType.values.firstWhere((e) => e.name == s.toLowerCase()),
      ),
      vehicleModel: toString(map['vehicleModel']) ?? toString(additionalData?['carModel']),
      vehicleColor: toString(map['vehicleColor']) ?? toString(additionalData?['carColor']),
      plateLetter: toString(map['plateLetter']) ?? toString(additionalData?['plateLetter']),
      vehicleImage: toString(map['vehicleImage']) ?? toString(additionalData?['carImage']),
      insuranceImage: toString(map['insuranceImage']) ?? toString(additionalData?['insuranceImage']),
      backgroundCheckImage: toString(map['backgroundCheckImage']),
      driverStatus: parseEnum(
        map['driverStatus'],
        DriverStatus.values,
        (s) => DriverStatus.values.firstWhere((e) => e.name == s.toLowerCase()),
        orElse: DriverStatus.pending,
      ),
      isOnline: map['isOnline'] ?? additionalData?['isOnline'],
      isAvailable: map['isAvailable'] ?? additionalData?['isAvailable'],
      currentLocation: toString(map['currentLocation']),
      currentLatitude: toDouble(map['currentLatitude'] ?? map['currentLat'] ?? additionalData?['currentLat']),
      currentLongitude: toDouble(map['currentLongitude'] ?? map['currentLng'] ?? additionalData?['currentLng']),
      totalTrips: toInt(map['totalTrips']),
      totalEarnings: toDouble(map['totalEarnings']),
      rating: toDouble(map['rating']),
      ratingCount: toInt(map['ratingCount']),
      emergencyContact: toString(map['emergencyContact']) ?? toString(additionalData?['emergencyContact']),
      emergencyContactName: toString(map['emergencyContactName']),
      workingAreas: map['workingAreas'] != null ? List<String>.from(map['workingAreas']) : null,
      provinceCode: toString(map['provinceCode']),
      provinceName: toString(map['provinceName']) ?? toString(additionalData?['provinceName']),
      riderType: toString(map['riderType']), // ✅ Fixed: was RiderType (capital R)
      favoriteLocations: map['favoriteLocations'] != null ? List<String>.from(map['favoriteLocations']) : null,
      totalSpent: toDouble(map['totalSpent']),
      additionalData: map['additionalData'] != null ? Map<String, dynamic>.from(map['additionalData']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'phone': phone,
      'phoneNumber': phoneNumber,
      'email': email,
      'profileImage': profileImage,
      'userType': userType.name,
      'balance': balance,
      'vehicleYear': vehicleYear,
      'plateNumber': plateNumber, // Use plateNumber consistently
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
      'nationalId': nationalId,
      'nationalIdImage': nationalIdImage,
      'drivingLicense': drivingLicense,
      'drivingLicenseImage': drivingLicenseImage,
      'vehicleLicense': vehicleLicense,
      'vehicleLicenseImage': vehicleLicenseImage,
      'vehicleType': vehicleType?.name,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'plateLetter': plateLetter,
      'vehicleImage': vehicleImage,
      'insuranceImage': insuranceImage,
      'backgroundCheckImage': backgroundCheckImage,
      'driverStatus': driverStatus?.name,
      'isOnline': isOnline,
      'isAvailable': isAvailable,
      'currentLocation': currentLocation,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'totalTrips': totalTrips,
      'totalEarnings': totalEarnings,
      'rating': rating,
      'ratingCount': ratingCount,
      'emergencyContact': emergencyContact,
      'emergencyContactName': emergencyContactName,
      'workingAreas': workingAreas,
      'provinceCode': provinceCode,
      'provinceName': provinceName,
      'riderType': riderType, // Renamed
      'lastActive': FieldValue.serverTimestamp(),
      'favoriteLocations': favoriteLocations,
      'totalSpent': totalSpent,
    };

    // Clean additionalData to avoid duplication and add it if not empty
    if (additionalData != null && additionalData!.isNotEmpty) {
      final cleanedAdditionalData = Map<String, dynamic>.from(additionalData!);

      // List of fields that are now top-level and should be removed from additionalData
      final topLevelFields = [
        'currentLat', 'currentLng', 'carModel', 'carColor', 'carType', 'carImage',
        'plateNumber', 'plateLetter', 'provinceName', 'licenseNumber', // This was a field in the snippet, removed from map to avoid confusion.
        'idCardImage', 'drivingLicenseImageFront', 'drivingLicenseImageBack',
        'nationalIdImageFront', 'nationalIdImageBack', 'insuranceImage',
        'isOnline', 'isAvailable', 'emergencyContact', 'vehicleYear'
      ];

      for (var field in topLevelFields) {
        cleanedAdditionalData.remove(field);
      }

      if (cleanedAdditionalData.isNotEmpty) {
        map['additionalData'] = cleanedAdditionalData;
      }
    }

    return map;
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? phoneNumber,
    String? email,
    String? profileImage,
    UserType? userType,
    double? balance,
    DateTime? createdAt,
    String? vehicleYear,
    String? plateNumber,
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
    String? provinceCode,
    String? plateLetter,
    String? vehicleImage,
    String? insuranceImage,
    String? backgroundCheckImage,
    DriverStatus? driverStatus,
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
    List<String>? workingAreas,
    String? provinceName,
    String? riderType,
    List<String>? favoriteLocations,
    double? totalSpent,
    Map<String, dynamic>? additionalData,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      userType: userType ?? this.userType,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      isApproved: isApproved ?? this.isApproved,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      isRejected: isRejected ?? this.isRejected,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
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
      plateLetter: plateLetter ?? this.plateLetter,
      vehicleImage: vehicleImage ?? this.vehicleImage,
      insuranceImage: insuranceImage ?? this.insuranceImage,
      backgroundCheckImage: backgroundCheckImage ?? this.backgroundCheckImage,
      driverStatus: driverStatus ?? this.driverStatus,
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
      workingAreas: workingAreas ?? this.workingAreas,
      provinceCode: provinceCode ?? this.provinceCode,
      provinceName: provinceName ?? this.provinceName,
      riderType: riderType ?? this.riderType,
      favoriteLocations: favoriteLocations ?? this.favoriteLocations,
      totalSpent: totalSpent ?? this.totalSpent,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  bool get isDriver => userType == UserType.driver;
  bool get isRider => userType == UserType.rider;

  bool get isDriverProfileComplete {
    if (!isDriver) return false;
    // Ensure all required driver fields are not null and not empty for Strings
    return nationalId != null &&
        nationalId!.isNotEmpty &&
        nationalIdImage != null &&
        nationalIdImage!.isNotEmpty &&
        drivingLicense != null &&
        drivingLicense!.isNotEmpty &&
        drivingLicenseImage != null &&
        drivingLicenseImage!.isNotEmpty &&
        vehicleLicense != null &&
        vehicleLicense!.isNotEmpty &&
        vehicleLicenseImage != null &&
        vehicleLicenseImage!.isNotEmpty &&
        vehicleType != null &&
        vehicleModel != null &&
        vehicleModel!.isNotEmpty &&
        vehicleColor != null &&
        vehicleColor!.isNotEmpty &&
        vehicleYear != null &&
        vehicleYear!.isNotEmpty &&
        plateNumber != null &&
        plateNumber!.isNotEmpty &&
        vehicleImage != null &&
        vehicleImage!.isNotEmpty &&
        insuranceImage != null &&
        insuranceImage!.isNotEmpty;
        // backgroundCheckImage is optional as per your toMap, but can be added here if truly mandatory
  }


  bool get canReceiveRequests {
    return isDriver &&
        isActive &&
        isApproved &&
        isDriverProfileComplete &&
        driverStatus == DriverStatus.approved;
  }

  bool get isRiderProfileComplete {
    if (!isRider) return false;
    return name.isNotEmpty && phone.isNotEmpty && email.isNotEmpty;
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, userType: $userType, isApproved: $isApproved)';
  }
}