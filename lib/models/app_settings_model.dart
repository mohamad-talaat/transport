import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettingsModel {
  final String id;
  final double baseFare;
  final double perKmRate;
  final double minimumFare;
  final double maximumFare;
  final List<String> supportedGovernorates;
  final List<String> unsupportedGovernorates;
  final Map<String, double> governorateRates;
  final bool isActive;
  final DateTime lastUpdated;
  final String updatedBy;
  
  // ✅ معلومات التسعير الإضافي
  final double plusTripSurcharge;
  final double additionalStopCost;
  final double waitingMinuteCost;
  final double roundTripMultiplier;
  
  // ✅ عمولة الأدمن والذروة
  final double adminCommissionPercentage;
  final int adminCommissionMinIqD;
  final int adminCommissionMaxIqD;
  final double rushHourMultiplier;
  final bool autoRushEnabled;
  final int autoRushThreshold;
  final int driverDebtLimitIqD;

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
    this.plusTripSurcharge = 1000.0,
    this.additionalStopCost = 1000.0,
    this.waitingMinuteCost = 50.0,
    this.roundTripMultiplier = 1.8,
    this.adminCommissionPercentage = 10.0,
    this.adminCommissionMinIqD = 250,
    this.adminCommissionMaxIqD = 2000,
    this.rushHourMultiplier = 1.2,
    this.autoRushEnabled = false,
    this.autoRushThreshold = 50,
    this.driverDebtLimitIqD = 15000,
  });

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      id: map['id'] ?? '',
      baseFare: (map['baseFare'] ?? 2000.0).toDouble(),
      perKmRate: (map['perKmRate'] ?? 800.0).toDouble(),
      minimumFare: (map['minimumFare'] ?? 3000.0).toDouble(),
      maximumFare: (map['maximumFare'] ?? 100000.0).toDouble(),
      supportedGovernorates: List<String>.from(map['supportedGovernorates'] ?? []),
      unsupportedGovernorates: List<String>.from(map['unsupportedGovernorates'] ?? []),
      governorateRates: Map<String, double>.from(map['governorateRates'] ?? {}),
      isActive: map['isActive'] ?? true,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: map['updatedBy'] ?? '',
      plusTripSurcharge: (map['plusTripSurcharge'] as num?)?.toDouble() ?? 1000.0,
      additionalStopCost: (map['additionalStopCost'] as num?)?.toDouble() ?? 1000.0,
      waitingMinuteCost: (map['waitingMinuteCost'] as num?)?.toDouble() ?? 50.0,
      roundTripMultiplier: (map['roundTripMultiplier'] as num?)?.toDouble() ?? 1.8,
      adminCommissionPercentage: (map['adminCommissionPercentage'] as num?)?.toDouble() ?? 10.0,
      adminCommissionMinIqD: (map['adminCommissionMinIqD'] as num?)?.toInt() ?? 250,
      adminCommissionMaxIqD: (map['adminCommissionMaxIqD'] as num?)?.toInt() ?? 2000,
      rushHourMultiplier: (map['rushHourMultiplier'] as num?)?.toDouble() ?? 1.2,
      autoRushEnabled: map['autoRushEnabled'] == true,
      autoRushThreshold: (map['autoRushThreshold'] as num?)?.toInt() ?? 50,
      driverDebtLimitIqD: (map['driverDebtLimitIqD'] as num?)?.toInt() ?? 15000,
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
      'plusTripSurcharge': plusTripSurcharge,
      'additionalStopCost': additionalStopCost,
      'waitingMinuteCost': waitingMinuteCost,
      'roundTripMultiplier': roundTripMultiplier,
      'adminCommissionPercentage': adminCommissionPercentage,
      'adminCommissionMinIqD': adminCommissionMinIqD,
      'adminCommissionMaxIqD': adminCommissionMaxIqD,
      'rushHourMultiplier': rushHourMultiplier,
      'autoRushEnabled': autoRushEnabled,
      'autoRushThreshold': autoRushThreshold,
      'driverDebtLimitIqD': driverDebtLimitIqD,
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
    double? plusTripSurcharge,
    double? additionalStopCost,
    double? waitingMinuteCost,
    double? roundTripMultiplier,
    double? adminCommissionPercentage,
    int? adminCommissionMinIqD,
    int? adminCommissionMaxIqD,
    double? rushHourMultiplier,
    bool? autoRushEnabled,
    int? autoRushThreshold,
    int? driverDebtLimitIqD,
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
      plusTripSurcharge: plusTripSurcharge ?? this.plusTripSurcharge,
      additionalStopCost: additionalStopCost ?? this.additionalStopCost,
      waitingMinuteCost: waitingMinuteCost ?? this.waitingMinuteCost,
      roundTripMultiplier: roundTripMultiplier ?? this.roundTripMultiplier,
      adminCommissionPercentage: adminCommissionPercentage ?? this.adminCommissionPercentage,
      adminCommissionMinIqD: adminCommissionMinIqD ?? this.adminCommissionMinIqD,
      adminCommissionMaxIqD: adminCommissionMaxIqD ?? this.adminCommissionMaxIqD,
      rushHourMultiplier: rushHourMultiplier ?? this.rushHourMultiplier,
      autoRushEnabled: autoRushEnabled ?? this.autoRushEnabled,
      autoRushThreshold: autoRushThreshold ?? this.autoRushThreshold,
      driverDebtLimitIqD: driverDebtLimitIqD ?? this.driverDebtLimitIqD,
    );
  }

  double calculateFare(double distanceKm, String? governorate) {
    double fare = baseFare + (distanceKm * perKmRate);

    if (governorate != null && governorateRates.containsKey(governorate)) {
      fare = baseFare + (distanceKm * governorateRates[governorate]!);
    }

    if (fare < minimumFare) fare = minimumFare;
    if (fare > maximumFare) fare = maximumFare;

    return fare;
  }

  /// ✅ حساب عمولة الأدمن بناءً على سعر الرحلة
  int calculateAdminCommission(double tripFare) {
    final commission = (tripFare * (adminCommissionPercentage / 100)).round();
    if (commission < adminCommissionMinIqD) return adminCommissionMinIqD;
    if (commission > adminCommissionMaxIqD) return adminCommissionMaxIqD;
    return commission;
  }

  bool isGovernorateSupported(String governorate) {
    return supportedGovernorates.contains(governorate) &&
        !unsupportedGovernorates.contains(governorate);
  }

  List<String> addSupportedGovernorate(String governorate) {
    List<String> updated = List.from(supportedGovernorates);
    if (!updated.contains(governorate)) {
      updated.add(governorate);
    }
    unsupportedGovernorates.remove(governorate);
    return updated;
  }

  List<String> removeSupportedGovernorate(String governorate) {
    List<String> updated = List.from(supportedGovernorates);
    updated.remove(governorate);
    return updated;
  }

  List<String> addUnsupportedGovernorate(String governorate) {
    List<String> updated = List.from(unsupportedGovernorates);
    if (!updated.contains(governorate)) {
      updated.add(governorate);
    }
    supportedGovernorates.remove(governorate);
    return updated;
  }

  List<String> removeUnsupportedGovernorate(String governorate) {
    List<String> updated = List.from(unsupportedGovernorates);
    updated.remove(governorate);
    return updated;
  }
}

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
