import 'package:cloud_firestore/cloud_firestore.dart';

class DiscountCodeModel {
  final String id;
  final String code;
  final double discountAmount;
  final double minimumAmount;
  final int maxUses;
  final int currentUses;
  final DateTime expiryDate;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;
  final String? description;
  final List<String> applicableUserIds; // المستخدمين المصرح لهم باستخدام الكود

  DiscountCodeModel({
    required this.id,
    required this.code,
    required this.discountAmount,
    required this.minimumAmount,
    required this.maxUses,
    this.currentUses = 0,
    required this.expiryDate,
    this.isActive = true,
    required this.createdAt,
    required this.createdBy,
    this.description,
    this.applicableUserIds = const [],
  });

  factory DiscountCodeModel.fromMap(Map<String, dynamic> map, String id) {
    return DiscountCodeModel(
      id: id,
      code: map['code'] ?? '',
      discountAmount: (map['discountAmount'] ?? 0.0).toDouble(),
      minimumAmount: (map['minimumAmount'] ?? 0.0).toDouble(),
      maxUses: map['maxUses'] ?? 1,
      currentUses: map['currentUses'] ?? 0,
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      description: map['description'],
      applicableUserIds: List<String>.from(map['applicableUserIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discountAmount': discountAmount,
      'minimumAmount': minimumAmount,
      'maxUses': maxUses,
      'currentUses': currentUses,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'description': description,
      'applicableUserIds': applicableUserIds,
    };
  }

  DiscountCodeModel copyWith({
    String? id,
    String? code,
    double? discountAmount,
    double? minimumAmount,
    int? maxUses,
    int? currentUses,
    DateTime? expiryDate,
    bool? isActive,
    DateTime? createdAt,
    String? createdBy,
    String? description,
    List<String>? applicableUserIds,
  }) {
    return DiscountCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      discountAmount: discountAmount ?? this.discountAmount,
      minimumAmount: minimumAmount ?? this.minimumAmount,
      maxUses: maxUses ?? this.maxUses,
      currentUses: currentUses ?? this.currentUses,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      description: description ?? this.description,
      applicableUserIds: applicableUserIds ?? this.applicableUserIds,
    );
  }

  /// حساب قيمة الخصم
  double calculateDiscount(double originalAmount) {
    return discountAmount;
  }

  /// التحقق من صلاحية الكود
  bool get isValid {
    if (!isActive) return false;
    if (currentUses >= maxUses) return false;
    if (DateTime.now().isAfter(expiryDate)) return false;
    return true;
  }

  /// التحقق من إمكانية استخدام الكود من قبل مستخدم معين
  bool canBeUsedBy(String userId) {
    if (!isValid) return false;
    if (applicableUserIds.isNotEmpty && !applicableUserIds.contains(userId)) {
      return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'DiscountCodeModel(id: $id, code: $code, discountAmount: $discountAmount, isValid: $isValid)';
  }
}
