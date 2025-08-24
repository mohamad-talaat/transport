import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettingsModel {
  final String id;
  final double baseFare; // السعر الأساسي
  final double perKmRate; // السعر لكل كيلومتر
  final double minimumFare; // الحد الأدنى للسعر
  final double maximumFare; // الحد الأقصى للسعر
  final List<String> supportedGovernorates; // المحافظات المدعومة
  final List<String> unsupportedGovernorates; // المحافظات غير المدعومة
  final Map<String, double> governorateRates; // أسعار خاصة لكل محافظة
  final bool isActive; // هل الإعدادات مفعلة
  final DateTime lastUpdated;
  final String updatedBy; // من قام بالتحديث

  AppSettingsModel({
    required this.id,
    required this.baseFare,
    required this.perKmRate,
    required this.minimumFare,
    required this.maximumFare,
    required this.supportedGovernorates,
    required this.unsupportedGovernorates,
    required this.governorateRates,
    required this.isActive,
    required this.lastUpdated,
    required this.updatedBy,
  });

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      id: map['id'] ?? '',
      baseFare: (map['baseFare'] ?? 10.0).toDouble(),
      perKmRate: (map['perKmRate'] ?? 3.0).toDouble(),
      minimumFare: (map['minimumFare'] ?? 5.0).toDouble(),
      maximumFare: (map['maximumFare'] ?? 100.0).toDouble(),
      supportedGovernorates: List<String>.from(map['supportedGovernorates'] ?? []),
      unsupportedGovernorates: List<String>.from(map['unsupportedGovernorates'] ?? []),
      governorateRates: Map<String, double>.from(map['governorateRates'] ?? {}),
      isActive: map['isActive'] ?? true,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: map['updatedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'minimumFare': minimumFare,
      'maximumFare': maximumFare,
      'supportedGovernorates': supportedGovernorates,
      'unsupportedGovernorates': unsupportedGovernorates,
      'governorateRates': governorateRates,
      'isActive': isActive,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'updatedBy': updatedBy,
    };
  }

  AppSettingsModel copyWith({
    String? id,
    double? baseFare,
    double? perKmRate,
    double? minimumFare,
    double? maximumFare,
    List<String>? supportedGovernorates,
    List<String>? unsupportedGovernorates,
    Map<String, double>? governorateRates,
    bool? isActive,
    DateTime? lastUpdated,
    String? updatedBy,
  }) {
    return AppSettingsModel(
      id: id ?? this.id,
      baseFare: baseFare ?? this.baseFare,
      perKmRate: perKmRate ?? this.perKmRate,
      minimumFare: minimumFare ?? this.minimumFare,
      maximumFare: maximumFare ?? this.maximumFare,
      supportedGovernorates: supportedGovernorates ?? this.supportedGovernorates,
      unsupportedGovernorates: unsupportedGovernorates ?? this.unsupportedGovernorates,
      governorateRates: governorateRates ?? this.governorateRates,
      isActive: isActive ?? this.isActive,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  /// حساب السعر بناءً على المسافة والمحافظة
  double calculateFare(double distanceKm, String? governorate) {
    double fare = baseFare + (distanceKm * perKmRate);
    
    // تطبيق سعر خاص للمحافظة إذا كان موجود
    if (governorate != null && governorateRates.containsKey(governorate)) {
      fare = baseFare + (distanceKm * governorateRates[governorate]!);
    }
    
    // تطبيق الحد الأدنى والأقصى
    if (fare < minimumFare) fare = minimumFare;
    if (fare > maximumFare) fare = maximumFare;
    
    return fare;
  }

  /// التحقق من دعم المحافظة
  bool isGovernorateSupported(String governorate) {
    return supportedGovernorates.contains(governorate) && 
           !unsupportedGovernorates.contains(governorate);
  }

  /// إضافة محافظة مدعومة
  List<String> addSupportedGovernorate(String governorate) {
    List<String> updated = List.from(supportedGovernorates);
    if (!updated.contains(governorate)) {
      updated.add(governorate);
    }
    // إزالة من قائمة المحافظات غير المدعومة إذا كانت موجودة
    unsupportedGovernorates.remove(governorate);
    return updated;
  }

  /// إزالة محافظة من المدعومة
  List<String> removeSupportedGovernorate(String governorate) {
    List<String> updated = List.from(supportedGovernorates);
    updated.remove(governorate);
    return updated;
  }

  /// إضافة محافظة غير مدعومة
  List<String> addUnsupportedGovernorate(String governorate) {
    List<String> updated = List.from(unsupportedGovernorates);
    if (!updated.contains(governorate)) {
      updated.add(governorate);
    }
    // إزالة من قائمة المحافظات المدعومة إذا كانت موجودة
    supportedGovernorates.remove(governorate);
    return updated;
  }

  /// إزالة محافظة من غير المدعومة
  List<String> removeUnsupportedGovernorate(String governorate) {
    List<String> updated = List.from(unsupportedGovernorates);
    updated.remove(governorate);
    return updated;
  }
}

// قائمة المحافظات العراقية
class IraqiGovernorates {
  static const List<String> allGovernorates = [
    'البصرة',
    'بغداد',
    'الموصل',
    'أربيل',
    'السليمانية',
    'دهوك',
    'كركوك',
    'الأنبار',
    'بابل',
    'النجف',
    'كربلاء',
    'واسط',
    'ميسان',
    'ذي قار',
    'القادسية',
    'الديوانية',
    'صلاح الدين',
    'ديالى',
    'الديوانية',
    'النجف الأشرف',
  ];

  static const List<String> defaultSupported = [
    'البصرة',
    'بغداد',
    'الموصل',
    'أربيل',
    'السليمانية',
    'دهوك',
  ];

  static const List<String> defaultUnsupported = [
    'كركوك',
    'الأنبار',
    'بابل',
    'النجف',
    'كربلاء',
    'واسط',
    'ميسان',
    'ذي قار',
    'القادسية',
    'الديوانية',
    'صلاح الدين',
    'ديالى',
  ];
}
