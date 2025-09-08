import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/base_user_model.dart';

class RiderModel extends BaseUserModel {
  // Rider-specific fields
  final String? currentLocation;
  final List<String> favoriteLocations;
  final int totalTrips;
  final double totalSpent;
  final List<String> paymentMethods;
  final Map<String, dynamic>? preferences;
  final String? emergencyContact;
  final String? emergencyContactName;

  RiderModel({
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
    
    // Rider-specific fields
    this.currentLocation,
    this.favoriteLocations = const [],
    this.totalTrips = 0,
    this.totalSpent = 0.0,
    this.paymentMethods = const [],
    this.preferences,
    this.emergencyContact,
    this.emergencyContactName,
  });

  @override
  String get userType => 'rider';

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
      
      // Rider-specific fields
      'currentLocation': currentLocation,
      'favoriteLocations': favoriteLocations,
      'totalTrips': totalTrips,
      'totalSpent': totalSpent,
      'paymentMethods': paymentMethods,
      'preferences': preferences,
      'emergencyContact': emergencyContact,
      'emergencyContactName': emergencyContactName,
    };
  }

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
      
      // Rider-specific fields
      currentLocation: map['currentLocation'],
      favoriteLocations: List<String>.from(map['favoriteLocations'] ?? []),
      totalTrips: map['totalTrips'] ?? 0,
      totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
      paymentMethods: List<String>.from(map['paymentMethods'] ?? []),
      preferences: map['preferences'],
      emergencyContact: map['emergencyContact'],
      emergencyContactName: map['emergencyContactName'],
    );
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
    List<String>? paymentMethods,
    Map<String, dynamic>? preferences,
    String? emergencyContact,
    String? emergencyContactName,
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
      paymentMethods: paymentMethods ?? this.paymentMethods,
      preferences: preferences ?? this.preferences,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
    );
  }

  // Helper methods
  bool get hasPaymentMethods => paymentMethods.isNotEmpty;
  
  bool get hasFavoriteLocations => favoriteLocations.isNotEmpty;
  
  bool get canBookTrip => isEligible && hasPaymentMethods;
  
  String get averageSpentPerTrip {
    if (totalTrips == 0) return '0.00';
    return (totalSpent / totalTrips).toStringAsFixed(2);
  }
  
  void addFavoriteLocation(String location) {
    if (!favoriteLocations.contains(location)) {
      favoriteLocations.add(location);
    }
  }
  
  void removeFavoriteLocation(String location) {
    favoriteLocations.remove(location);
  }
  
  void addPaymentMethod(String method) {
    if (!paymentMethods.contains(method)) {
      paymentMethods.add(method);
    }
  }
  
  void removePaymentMethod(String method) {
    paymentMethods.remove(method);
  }
}
