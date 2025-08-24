import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/app_settings_model.dart';
import '../main.dart';

class AppSettingsService extends GetxService {
  static AppSettingsService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable settings
  final Rx<AppSettingsModel?> currentSettings = Rx<AppSettingsModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;

  // Stream subscription
  StreamSubscription<DocumentSnapshot>? _settingsSubscription;

  Future<AppSettingsService> init() async {
    await _loadSettings();
    _listenToSettingsChanges();
    return this;
  }

  /// تحميل الإعدادات من قاعدة البيانات
  Future<void> _loadSettings() async {
    try {
      isLoading.value = true;

      DocumentSnapshot doc = await _firestore
          .collection('app_settings')
          .doc('main_settings')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        currentSettings.value = AppSettingsModel.fromMap(data);
      } else {
        // إنشاء إعدادات افتراضية إذا لم تكن موجودة
        await _createDefaultSettings();
      }
    } catch (e) {
      logger.e('خطأ في تحميل الإعدادات: $e');
      Get.snackbar(
        'خطأ',
        'تعذر تحميل إعدادات التطبيق',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// إنشاء إعدادات افتراضية
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

  /// الاستماع لتغييرات الإعدادات
  void _listenToSettingsChanges() {
    _settingsSubscription?.cancel();

    _settingsSubscription = _firestore
        .collection('app_settings')
        .doc('main_settings')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        data['id'] = snapshot.id;
        currentSettings.value = AppSettingsModel.fromMap(data);
      }
    });
  }

  /// تحديث الإعدادات
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

  /// إضافة محافظة مدعومة
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

  /// إزالة محافظة من المدعومة
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

  /// إضافة محافظة غير مدعومة
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

  /// إزالة محافظة من غير المدعومة
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

  /// تحديث سعر محافظة معينة
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

  /// إزالة سعر خاص لمحافظة
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

  /// حساب السعر بناءً على المسافة والمحافظة
  double calculateFare(double distanceKm, String? governorate) {
    if (currentSettings.value == null) {
      // إعدادات افتراضية إذا لم تكن محملة
      return 10.0 + (distanceKm * 3.0);
    }

    return currentSettings.value!.calculateFare(distanceKm, governorate);
  }

  /// التحقق من دعم المحافظة
  bool isGovernorateSupported(String governorate) {
    if (currentSettings.value == null) return true; // افتراضياً مدعومة

    return currentSettings.value!.isGovernorateSupported(governorate);
  }

  /// الحصول على قائمة المحافظات المدعومة
  List<String> getSupportedGovernorates() {
    if (currentSettings.value == null) {
      return IraqiGovernorates.defaultSupported;
    }

    return currentSettings.value!.supportedGovernorates;
  }

  /// الحصول على قائمة المحافظات غير المدعومة
  List<String> getUnsupportedGovernorates() {
    if (currentSettings.value == null) {
      return IraqiGovernorates.defaultUnsupported;
    }

    return currentSettings.value!.unsupportedGovernorates;
  }

  /// إعادة تعيين الإعدادات إلى الافتراضية
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
