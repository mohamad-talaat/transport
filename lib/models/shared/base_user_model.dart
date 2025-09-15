
/// Base user model that contains common fields for both drivers and riders
abstract class BaseUserModel {
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

  BaseUserModel({
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
  });

  /// Convert model to Map for storage
  Map<String, dynamic> toMap();

  /// Create model from Map
  factory BaseUserModel.fromMap(Map<String, dynamic> map) {
    throw UnimplementedError('fromMap must be implemented by subclasses');
  }

  /// Get user type (driver or rider)
  String get userType;

  /// Check if user is approved and active
  bool get isEligible => isApproved && isActive && !isRejected;

  /// Get user status as string
  String get statusString {
    if (isRejected) return 'rejected';
    if (isApproved) return 'approved';
    if (isVerified) return 'verified';
    return 'pending';
  }

  /// Update user balance
  void updateBalance(double newBalance) {
    balance = newBalance;
  }

  /// Check if user has completed profile
  bool get hasCompleteProfile => isProfileComplete;

  /// Get user creation date as formatted string
  String get formattedCreatedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Get user age in years
  int get age {
    final now = DateTime.now();
    int age = now.year - createdAt.year;
    if (now.month < createdAt.month ||
        (now.month == createdAt.month && now.day < createdAt.day)) {
      age--;
    }
    return age;
  }

  /// Check if user is online (has FCM token)
  bool get isOnline => fcmToken != null && fcmToken!.isNotEmpty;

  /// Get user initials for avatar
  String get initials {
    if (name.isEmpty) return 'U';
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
