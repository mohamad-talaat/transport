import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/app_settings_model.dart';
import '../main.dart';

class AppSettingsService extends GetxService {
  static AppSettingsService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rx<AppSettingsModel?> currentSettings = Rx<AppSettingsModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;

  StreamSubscription<DocumentSnapshot>? _settingsSubscription;

  Future<AppSettingsService> init() async {
    await _loadSettings();
    _listenToSettingsChanges();
    return this;
  }

  Future<void> _loadSettings() async {
    try {
      isLoading.value = true;

      // جلب الإعدادات العامة
      DocumentSnapshot mainDoc = await _firestore
          .collection('app_settings')
          .doc('main_settings')
          .get();

      // جلب إعدادات الأسعار
      DocumentSnapshot pricingDoc = await _firestore
          .collection('app_settings')
          .doc('pricing')
          .get();

      Map<String, dynamic> data = {};
      
      if (mainDoc.exists) {
        data = mainDoc.data() as Map<String, dynamic>;
        data['id'] = mainDoc.id;
      }

      // دمج إعدادات الأسعار إذا كانت موجودة
      if (pricingDoc.exists) {
        final pricingData = pricingDoc.data() as Map<String, dynamic>;
        data['baseFare'] = pricingData['baseFare'] ?? data['baseFare'] ?? 2000.0;
        data['perKmRate'] = pricingData['pricePerKm'] ?? data['perKmRate'] ?? 800.0;
        data['minimumFare'] = pricingData['minimumFare'] ?? data['minimumFare'] ?? 3000.0;
        data['plusTripSurcharge'] = pricingData['plusTripFee'] ?? 1000.0;
        data['additionalStopCost'] = pricingData['additionalStopFee'] ?? 1000.0;
        data['waitingMinuteCost'] = pricingData['waitingTimeFeePerMinute'] ?? 50.0;
        data['roundTripMultiplier'] = pricingData['roundTripMultiplier'] ?? 1.8;
      }

      if (data.isNotEmpty) {
        currentSettings.value = AppSettingsModel.fromMap(data);
      } else {
        await _createDefaultSettings();
      }
    } catch (e) {
      logger.e('خطأ في تحميل الإعدادات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _createDefaultSettings() async {
    try {
      AppSettingsModel defaultSettings = AppSettingsModel(
        id: 'main_settings',
        baseFare: 10.0,
        perKmRate: 3.0,
        minimumFare: 5.0,
        maximumFare: 100.0,
        supportedGovernorates: IraqiGovernorates.defaultSupported,
        unsupportedGovernorates: IraqiGovernorates.defaultUnsupported,
        governorateRates: {},
        isActive: true,
        lastUpdated: DateTime.now(),
        updatedBy: 'system',
      );

      await _firestore
          .collection('app_settings')
          .doc('main_settings')
          .set(defaultSettings.toMap());

      currentSettings.value = defaultSettings;
    } catch (e) {
      logger.e('خطأ في إنشاء الإعدادات الافتراضية: $e');
    }
  }

  void _listenToSettingsChanges() {
    _settingsSubscription?.cancel();

    // الاستماع للتغييرات في إعدادات الأسعار
    _settingsSubscription = _firestore
        .collection('app_settings')
        .doc('pricing')
        .snapshots()
        .listen((pricingSnapshot) async {
      try {
        // جلب الإعدادات العامة
        DocumentSnapshot mainSnapshot = await _firestore
            .collection('app_settings')
            .doc('main_settings')
            .get();

        Map<String, dynamic> data = {};
        
        if (mainSnapshot.exists) {
          data = mainSnapshot.data() as Map<String, dynamic>;
          data['id'] = mainSnapshot.id;
        }

        // دمج إعدادات الأسعار
        if (pricingSnapshot.exists) {
          final pricingData = pricingSnapshot.data() as Map<String, dynamic>;
          data['baseFare'] = pricingData['baseFare'] ?? data['baseFare'] ?? 2000.0;
          data['perKmRate'] = pricingData['pricePerKm'] ?? data['perKmRate'] ?? 800.0;
          data['minimumFare'] = pricingData['minimumFare'] ?? data['minimumFare'] ?? 3000.0;
          data['plusTripSurcharge'] = pricingData['plusTripFee'] ?? 1000.0;
          data['additionalStopCost'] = pricingData['additionalStopFee'] ?? 1000.0;
          data['waitingMinuteCost'] = pricingData['waitingTimeFeePerMinute'] ?? 50.0;
          data['roundTripMultiplier'] = pricingData['roundTripMultiplier'] ?? 1.8;
        }

        if (data.isNotEmpty) {
          currentSettings.value = AppSettingsModel.fromMap(data);
          logger.i('تم تحديث إعدادات الأسعار');
        }
      } catch (e) {
        logger.e('خطأ في الاستماع للتغييرات: $e');
      }
    });
  }

  Future<bool> updateSettings({
    double? baseFare,
    double? perKmRate,
    double? minimumFare,
    double? maximumFare,
    List<String>? supportedGovernorates,
    List<String>? unsupportedGovernorates,
    Map<String, double>? governorateRates,
    bool? isActive,
    String? updatedBy,
  }) async {
    try {
      isUpdating.value = true;

      if (currentSettings.value == null) {
        throw Exception('الإعدادات غير محملة');
      }

      AppSettingsModel updatedSettings = currentSettings.value!.copyWith(
        baseFare: baseFare,
        perKmRate: perKmRate,
        minimumFare: minimumFare,
        maximumFare: maximumFare,
        supportedGovernorates: supportedGovernorates,
        unsupportedGovernorates: unsupportedGovernorates,
        governorateRates: governorateRates,
        isActive: isActive,
        lastUpdated: DateTime.now(),
        updatedBy: updatedBy ?? 'admin',
      );

      await _firestore
          .collection('app_settings')
          .doc('main_settings')
          .update(updatedSettings.toMap());

      Get.snackbar(
        'تم التحديث',
        'تم تحديث إعدادات التطبيق بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      logger.e('خطأ في تحديث الإعدادات: $e');
      Get.snackbar(
        'خطأ',
        'تعذر تحديث الإعدادات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> addSupportedGovernorate(String governorate,
      {String? updatedBy}) async {
    if (currentSettings.value == null) return false;

    List<String> updatedSupported =
        currentSettings.value!.addSupportedGovernorate(governorate);

    return await updateSettings(
      supportedGovernorates: updatedSupported,
      updatedBy: updatedBy,
    );
  }

  Future<bool> removeSupportedGovernorate(String governorate,
      {String? updatedBy}) async {
    if (currentSettings.value == null) return false;

    List<String> updatedSupported =
        currentSettings.value!.removeSupportedGovernorate(governorate);

    return await updateSettings(
      supportedGovernorates: updatedSupported,
      updatedBy: updatedBy,
    );
  }

  Future<bool> addUnsupportedGovernorate(String governorate,
      {String? updatedBy}) async {
    if (currentSettings.value == null) return false;

    List<String> updatedUnsupported =
        currentSettings.value!.addUnsupportedGovernorate(governorate);

    return await updateSettings(
      unsupportedGovernorates: updatedUnsupported,
      updatedBy: updatedBy,
    );
  }

  Future<bool> removeUnsupportedGovernorate(String governorate,
      {String? updatedBy}) async {
    if (currentSettings.value == null) return false;

    List<String> updatedUnsupported =
        currentSettings.value!.removeUnsupportedGovernorate(governorate);

    return await updateSettings(
      unsupportedGovernorates: updatedUnsupported,
      updatedBy: updatedBy,
    );
  }

  Future<bool> updateGovernorateRate(String governorate, double rate,
      {String? updatedBy}) async {
    if (currentSettings.value == null) return false;

    Map<String, double> updatedRates =
        Map.from(currentSettings.value!.governorateRates);
    updatedRates[governorate] = rate;

    return await updateSettings(
      governorateRates: updatedRates,
      updatedBy: updatedBy,
    );
  }

  Future<bool> removeGovernorateRate(String governorate,
      {String? updatedBy}) async {
    if (currentSettings.value == null) return false;

    Map<String, double> updatedRates =
        Map.from(currentSettings.value!.governorateRates);
    updatedRates.remove(governorate);

    return await updateSettings(
      governorateRates: updatedRates,
      updatedBy: updatedBy,
    );
  }

  double calculateFare(double distanceKm, String? governorate) {
    if (currentSettings.value == null) {
      return 10.0 + (distanceKm * 3.0);
    }

    return currentSettings.value!.calculateFare(distanceKm, governorate);
  }

  /// ✅ حساب العمولة بناءً على سعر الرحلة (وليس المسافة)
  int calculateCommission(double tripFare) {
    if (currentSettings.value == null) {
      return 250; // قيمة افتراضية
    }
    return currentSettings.value!.calculateAdminCommission(tripFare);
  }

  /// ✅ حد ديون السائق من الإعدادات
  int get driverDebtLimitIqD => currentSettings.value?.driverDebtLimitIqD ?? 15000;

  /// ✅ مضاعف وقت الذروة
  double get rushHourMultiplier => currentSettings.value?.rushHourMultiplier ?? 1.2;

  /// ✅ هل الذروة التلقائية مفعلة؟
  bool get isAutoRushEnabled => currentSettings.value?.autoRushEnabled ?? false;

  /// ✅ عدد الطلبات لتفعيل الذروة
  int get autoRushThreshold => currentSettings.value?.autoRushThreshold ?? 50;

  bool isGovernorateSupported(String governorate) {
    if (currentSettings.value == null) return true;

    return currentSettings.value!.isGovernorateSupported(governorate);
  }

  List<String> getSupportedGovernorates() {
    if (currentSettings.value == null) {
      return IraqiGovernorates.defaultSupported;
    }

    return currentSettings.value!.supportedGovernorates;
  }

  List<String> getUnsupportedGovernorates() {
    if (currentSettings.value == null) {
      return IraqiGovernorates.defaultUnsupported;
    }

    return currentSettings.value!.unsupportedGovernorates;
  }

  Future<bool> resetToDefaults({String? updatedBy}) async {
    return await updateSettings(
      baseFare: 10.0,
      perKmRate: 3.0,
      minimumFare: 5.0,
      maximumFare: 100.0,
      supportedGovernorates: IraqiGovernorates.defaultSupported,
      unsupportedGovernorates: IraqiGovernorates.defaultUnsupported,
      governorateRates: {},
      isActive: true,
      updatedBy: updatedBy,
    );
  }

  @override
  void onClose() {
    _settingsSubscription?.cancel();
    super.onClose();
  }
}
