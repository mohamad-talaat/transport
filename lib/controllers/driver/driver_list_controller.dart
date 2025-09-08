import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/main.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';

class DriverListController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  // Reactive variables
  final RxList<DriverModel> drivers = <DriverModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Search and filter
  final RxString searchQuery = ''.obs;
  final RxString selectedStatus = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadDrivers();
  }

  @override
  void onClose() {
    // Clean up any resources
    super.onClose();
  }

  /// Load all drivers
  Future<void> _loadDrivers() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final List<DriverModel> allDrivers =
          await _firebaseService.getAllDrivers();
      drivers.assignAll(allDrivers);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'خطأ في تحميل السائقين: $e';
      logger.w('Error loading drivers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load available drivers
  Future<void> loadAvailableDrivers() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final List<DriverModel> availableDrivers =
          await _firebaseService.getAvailableDrivers();
      drivers.assignAll(availableDrivers);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'خطأ في تحميل السائقين المتاحين: $e';
      logger.w('Error loading available drivers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load drivers by status
  Future<void> loadDriversByStatus(String status) async {
    try {
      isLoading.value = true;
      hasError.value = false;

      if (status == 'all') {
        await _loadDrivers();
      } else {
        final List<DriverModel> statusDrivers =
            await _firebaseService.getDriversByStatus(status);
        drivers.assignAll(statusDrivers);
      }

      selectedStatus.value = status;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'خطأ في تحميل السائقين: $e';
      logger.w('Error loading drivers by status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Search drivers by name
  Future<void> searchDrivers(String query) async {
    try {
      if (query.isEmpty) {
        await _loadDrivers();
        return;
      }

      isLoading.value = true;
      hasError.value = false;

      final List<DriverModel> searchResults =
          await _firebaseService.searchDrivers(query);
      drivers.assignAll(searchResults);
      searchQuery.value = query;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'خطأ في البحث: $e';
      logger.w('Error searching drivers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Update driver status
  Future<void> updateDriverStatus({
    required String driverId,
    required String status,
    String? approvedBy,
  }) async {
    try {
      isLoading.value = true;
      hasError.value = false;

      await _firebaseService.updateDriverStatus(
        driverId: driverId,
        status: status,
        approvedBy: approvedBy,
      );

      // Refresh the list
      await _loadDrivers();

      Get.snackbar(
        'نجح',
        'تم تحديث حالة السائق بنجاح',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'خطأ في تحديث حالة السائق: $e';
      logger.w('Error updating driver status: $e');

      Get.snackbar(
        'خطأ',
        'فشل في تحديث حالة السائق',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh drivers list
  Future<void> refreshDrivers() async {
    await _loadDrivers();
  }

  /// Clear search
  void clearSearch() {
    searchQuery.value = '';
    _loadDrivers();
  }

  /// Get filtered drivers based on current filters
  List<DriverModel> get filteredDrivers {
    List<DriverModel> filtered = drivers;

    // Apply status filter
    if (selectedStatus.value != 'all') {
      filtered = filtered
          .where((driver) =>
              driver.additionalData?['status'] == selectedStatus.value)
          .toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered
          .where((driver) => driver.name
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  /// Get drivers count by status
  int getDriversCountByStatus(String status) {
    if (status == 'all') return drivers.length;

    return drivers
        .where((driver) => driver.additionalData?['status'] == status)
        .length;
  }

  /// Get online drivers count
  int get onlineDriversCount => drivers
      .where((driver) => driver.additionalData?['isOnline'] == true)
      .length;

  /// Get available drivers count
  int get availableDriversCount => drivers
      .where((driver) => driver.additionalData?['isAvailable'] == true)
      .length;

  /// Get pending approval drivers count
  int get pendingDriversCount => drivers
      .where((driver) => driver.additionalData?['status'] == 'pending')
      .length;
}
