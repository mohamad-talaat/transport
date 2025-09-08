import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/rider_model.dart';
import '../../services/firebase_service.dart';

class RiderListController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  // Reactive variables
  final RxList<RiderModel> riders = <RiderModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Search and filter
  final RxString searchQuery = ''.obs;
  final RxString selectedStatus = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadRiders();
  }

  @override
  void onClose() {
    // Clean up any resources
    super.onClose();
  }

  /// Load all riders
  Future<void> _loadRiders() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final List<RiderModel> allRiders = await _firebaseService.getAllRiders();
      riders.assignAll(allRiders);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'خطأ في تحميل الركاب: $e';
      logger.w('Error loading riders: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load active riders
  Future<void> loadActiveRiders() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final List<RiderModel> activeRiders =
          await _firebaseService.getActiveRiders();
      riders.assignAll(activeRiders);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'خطأ في تحميل الركاب النشطين: $e';
      logger.w('Error loading active riders: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load riders by status
  Future<void> loadRidersByStatus(String status) async {
    try {
      isLoading.value = true;
      hasError.value = false;

      if (status == 'all') {
        await _loadRiders();
      } else {
        final List<RiderModel> statusRiders =
            await _firebaseService.getRidersByStatus(status);
        riders.assignAll(statusRiders);
      }

      selectedStatus.value = status;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'خطأ في تحميل الركاب: $e';
      logger.w('Error loading riders by status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Search riders by name
  Future<void> searchRiders(String query) async {
    try {
      if (query.isEmpty) {
        await _loadRiders();
        return;
      }

      isLoading.value = true;
      hasError.value = false;

      final List<RiderModel> searchResults =
          await _firebaseService.searchRiders(query);
      riders.assignAll(searchResults);
      searchQuery.value = query;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'خطأ في البحث: $e';
      logger.w('Error searching riders: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Update rider status
  Future<void> updateRiderStatus({
    required String riderId,
    required String status,
    String? approvedBy,
  }) async {
    try {
      isLoading.value = true;
      hasError.value = false;

      await _firebaseService.updateRiderStatus(
        riderId: riderId,
        status: status,
        approvedBy: approvedBy,
      );

      // Refresh the list
      await _loadRiders();

      Get.snackbar(
        'نجح',
        'تم تحديث حالة الراكب بنجاح',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'خطأ في تحديث حالة الراكب: $e';
      logger.w('Error updating rider status: $e');

      Get.snackbar(
        'خطأ',
        'فشل في تحديث حالة الراكب',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh riders list
  Future<void> refreshRiders() async {
    await _loadRiders();
  }

  /// Clear search
  void clearSearch() {
    searchQuery.value = '';
    _loadRiders();
  }

  /// Get filtered riders based on current filters
  List<RiderModel> get filteredRiders {
    List<RiderModel> filtered = riders;

    // Apply status filter
    if (selectedStatus.value != 'all') {
      filtered = filtered
          .where((rider) =>
              rider.additionalData?['status'] == selectedStatus.value)
          .toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered
          .where((rider) => rider.name
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  /// Get riders count by status
  int getRidersCountByStatus(String status) {
    if (status == 'all') return riders.length;

    return riders
        .where((rider) => rider.additionalData?['status'] == status)
        .length;
  }

  /// Get active riders count
  int get activeRidersCount =>
      riders.where((rider) => rider.additionalData?['isActive'] == true).length;

  /// Get verified riders count
  int get verifiedRidersCount =>
      riders.where((rider) => rider.isVerified == true).length;

  /// Get pending approval riders count
  int get pendingRidersCount => riders
      .where((rider) => rider.additionalData?['status'] == 'pending')
      .length;
}
