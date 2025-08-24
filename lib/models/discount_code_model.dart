
class DiscountCodeModel {
  final String id;
  final String code;
  final double amount;
  final String type; // 'fixed' or 'percentage'
  final double? percentage; // for percentage type
  final bool isUsed;
  final String? usedBy;
  final DateTime? usedAt;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? description;
  final bool isActive;

  DiscountCodeModel({
    required this.id,
    required this.code,
    required this.amount,
    required this.type,
    this.percentage,
    required this.isUsed,
    this.usedBy,
    this.usedAt,
    required this.createdAt,
    this.expiresAt,
    this.description,
    required this.isActive,
  });

  factory DiscountCodeModel.fromMap(Map<String, dynamic> map, String id) {
    return DiscountCodeModel(
      id: id,
      code: map['code'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: map['type'] ?? 'fixed',
      percentage: map['percentage']?.toDouble(),
      isUsed: map['isUsed'] ?? false,
      usedBy: map['usedBy'],
      usedAt: map['usedAt']?.toDate(),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      expiresAt: map['expiresAt']?.toDate(),
      description: map['description'],
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'amount': amount,
      'type': type,
      'percentage': percentage,
      'isUsed': isUsed,
      'usedBy': usedBy,
      'usedAt': usedAt,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'description': description,
      'isActive': isActive,
    };
  }

  DiscountCodeModel copyWith({
    String? id,
    String? code,
    double? amount,
    String? type,
    double? percentage,
    bool? isUsed,
    String? usedBy,
    DateTime? usedAt,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? description,
    bool? isActive,
  }) {
    return DiscountCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      percentage: percentage ?? this.percentage,
      isUsed: isUsed ?? this.isUsed,
      usedBy: usedBy ?? this.usedBy,
      usedAt: usedAt ?? this.usedAt,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  /// حساب قيمة الخصم
  double calculateDiscount(double originalAmount) {
    if (type == 'percentage' && percentage != null) {
      return originalAmount * (percentage! / 100);
    } else {
      return amount;
    }
  }

  /// التحقق من صلاحية الكود
  bool get isValid {
    if (!isActive) return false;
    if (isUsed) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }
}
