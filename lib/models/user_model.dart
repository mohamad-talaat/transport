import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { rider, driver }

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? profileImage;
  final UserType userType;
  late final double balance;
  final DateTime createdAt;
  final bool isActive;
  final bool isVerified; // حالة تأكيد الإدارة
  final bool isApproved; // حالة موافقة الإدارة
  final DateTime? approvedAt; // تاريخ الموافقة
  final String? approvedBy; // من وافق عليه
  final bool isRejected; // حالة رفض الإدارة
  final DateTime? rejectedAt; // تاريخ الرفض
  final String? rejectedBy; // من رفض الطلب
  final String? rejectionReason; // سبب الرفض
  final bool isProfileComplete; // هل اكتمل الملف الشخصي
  final Map<String, dynamic>? additionalData;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
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
    this.additionalData,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      profileImage: map['profileImage'],
      userType: UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${map['userType']}',
        orElse: () => UserType.rider,
      ),
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'profileImage': profileImage,
      'userType': userType.name,
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
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? profileImage,
    UserType? userType,
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
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
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
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}

class DriverModel extends UserModel {
  final String carType;
  final String carNumber;
  final String licenseNumber;
  final String? carImage;
  final bool isOnline;
  final double? currentLat;
  final double? currentLng;

  // بيانات إضافية جديدة
  final String carModel; // موديل السيارة
  final String carColor; // لون السيارة
  final String carYear; // سنة السيارة
  final List<String> workingAreas; // مناطق العمل
  final String? licenseImage; // صورة الرخصة
  final String? idCardImage; // صورة الهوية
  final bool isProfileComplete; // هل اكتمل الملف الشخصي
  final String? vehicleRegistrationImage; // صورة تسجيل السيارة
  final String? insuranceImage; // صورة التأمين

  DriverModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.email,
    super.profileImage,
    super.balance,
    required super.createdAt,
    super.isActive,
    super.isVerified,
    super.isApproved,
    super.approvedAt,
    super.approvedBy,
    super.isRejected,
    super.rejectedAt,
    super.rejectedBy,
    super.rejectionReason,
    required this.carType,
    required this.carNumber,
    required this.licenseNumber,
    this.carImage,
    this.isOnline = false,
    this.currentLat,
    this.currentLng,
    required this.carModel,
    required this.carColor,
    required this.carYear,
    required this.workingAreas,
    this.licenseImage,
    this.idCardImage,
    this.isProfileComplete = false,
    this.vehicleRegistrationImage,
    this.insuranceImage,
  }) : super(
          userType: UserType.driver,
          additionalData: {
            'carType': carType,
            'carNumber': carNumber,
            'licenseNumber': licenseNumber,
            'carImage': carImage,
            'isOnline': isOnline,
            'currentLat': currentLat,
            'currentLng': currentLng,
            'carModel': carModel,
            'carColor': carColor,
            'carYear': carYear,
            'workingAreas': workingAreas,
            'licenseImage': licenseImage,
            'idCardImage': idCardImage,
            'isProfileComplete': isProfileComplete,
            'vehicleRegistrationImage': vehicleRegistrationImage,
            'insuranceImage': insuranceImage,
          },
        );

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    final user = UserModel.fromMap(map);
    final additionalData = map['additionalData'] as Map<String, dynamic>? ?? {};

    return DriverModel(
      id: user.id,
      name: user.name,
      phone: user.phone,
      email: user.email,
      profileImage: user.profileImage,
      balance: user.balance,
      createdAt: user.createdAt,
      isActive: user.isActive,
      isVerified: user.isVerified,
      isApproved: user.isApproved,
      approvedAt: user.approvedAt,
      approvedBy: user.approvedBy,
      isRejected: user.isRejected,
      rejectedAt: user.rejectedAt,
      rejectedBy: user.rejectedBy,
      rejectionReason: user.rejectionReason,
      carType: additionalData['carType'] ?? '',
      carNumber: additionalData['carNumber'] ?? '',
      licenseNumber: additionalData['licenseNumber'] ?? '',
      carImage: additionalData['carImage'],
      isOnline: additionalData['isOnline'] ?? false,
      currentLat: additionalData['currentLat']?.toDouble(),
      currentLng: additionalData['currentLng']?.toDouble(),
      carModel: additionalData['carModel'] ?? '',
      carColor: additionalData['carColor'] ?? '',
      carYear: additionalData['carYear'] ?? '',
      workingAreas: List<String>.from(additionalData['workingAreas'] ?? []),
      licenseImage: additionalData['licenseImage'],
      idCardImage: additionalData['idCardImage'],
      isProfileComplete: additionalData['isProfileComplete'] ?? false,
      vehicleRegistrationImage: additionalData['vehicleRegistrationImage'],
      insuranceImage: additionalData['insuranceImage'],
    );
  }

  @override
  DriverModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? profileImage,
    UserType? userType,
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
    Map<String, dynamic>? additionalData,
    String? carType,
    String? carNumber,
    String? licenseNumber,
    String? carImage,
    bool? isOnline,
    double? currentLat,
    double? currentLng,
    String? carModel,
    String? carColor,
    String? carYear,
    List<String>? workingAreas,
    String? licenseImage,
    String? idCardImage,
    bool? isProfileComplete,
    String? vehicleRegistrationImage,
    String? insuranceImage,
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
      carType: carType ?? this.carType,
      carNumber: carNumber ?? this.carNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      carImage: carImage ?? this.carImage,
      isOnline: isOnline ?? this.isOnline,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      carModel: carModel ?? this.carModel,
      carColor: carColor ?? this.carColor,
      carYear: carYear ?? this.carYear,
      workingAreas: workingAreas ?? this.workingAreas,
      licenseImage: licenseImage ?? this.licenseImage,
      idCardImage: idCardImage ?? this.idCardImage,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      vehicleRegistrationImage:
          vehicleRegistrationImage ?? this.vehicleRegistrationImage,
      insuranceImage: insuranceImage ?? this.insuranceImage,
    );
  }
}
