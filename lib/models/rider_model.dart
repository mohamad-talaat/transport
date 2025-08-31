import 'package:cloud_firestore/cloud_firestore.dart';

class RiderModel {
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
  final String? fcmToken; // للتنبيهات
  final String? currentLocation; // الموقع الحالي
  final List<String> favoriteLocations; // المواقع المفضلة
  final int totalTrips; // إجمالي الرحلات
  final double totalSpent; // إجمالي المدفوع

  RiderModel({
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
    this.currentLocation,
    this.favoriteLocations = const [],
    this.totalTrips = 0,
    this.totalSpent = 0.0,
  });

  factory RiderModel.fromMap(Map<String, dynamic> map) {
    return RiderModel(
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
      currentLocation: map['currentLocation'],
      favoriteLocations: List<String>.from(map['favoriteLocations'] ?? []),
      totalTrips: map['totalTrips'] ?? 0,
      totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
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
      'currentLocation': currentLocation,
      'favoriteLocations': favoriteLocations,
      'totalTrips': totalTrips,
      'totalSpent': totalSpent,
    };
  }

  RiderModel copyWith({
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
    String? currentLocation,
    List<String>? favoriteLocations,
    int? totalTrips,
    double? totalSpent,
  }) {
    return RiderModel(
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
      currentLocation: currentLocation ?? this.currentLocation,
      favoriteLocations: favoriteLocations ?? this.favoriteLocations,
      totalTrips: totalTrips ?? this.totalTrips,
      totalSpent: totalSpent ?? this.totalSpent,
    );
  }

  @override
  String toString() {
    return 'RiderModel(id: $id, name: $name, phone: $phone, email: $email, balance: $balance, isApproved: $isApproved, isProfileComplete: $isProfileComplete)';
  }
}
