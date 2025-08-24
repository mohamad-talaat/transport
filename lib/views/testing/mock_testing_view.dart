import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/mock_testing_service.dart';
import '../../main.dart';

class MockTestingView extends StatelessWidget {
  const MockTestingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 241, 233),
      appBar: AppBar(
        title: const Text(
          'اختبار وهمي - مصر',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildLocationsList(),
            const SizedBox(height: 24),
            _buildAdvancedTesting(),
          ],
        ),
      ),
    );
  }

  /// الهيدر
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.science, color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اختبار وهمي للتطبيق',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إنشاء بيانات وهمية في مصر للاختبار',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// الإجراءات السريعة
  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'إجراءات سريعة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _createFullScenario(),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('سيناريو كامل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _clearAllData(),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('حذف البيانات'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// قائمة المواقع العراقية
  Widget _buildLocationsList() {
    final mockService = MockTestingService.to;
    final locations = mockService.getCurrentLocations();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'المواقع المصرية المتاحة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...locations
                .map((location) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  location['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${location['lat'].toStringAsFixed(4)}, ${location['lng'].toStringAsFixed(4)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _createDriverAtLocation(location),
                            icon: const Icon(Icons.add_location,
                                color: Colors.blue),
                            tooltip: 'إنشاء سائق في هذا الموقع',
                          ),
                        ],
                      ),
                    ))
                ,
          ],
        ),
      ),
    );
  }

  /// اختبار متقدم
  Widget _buildAdvancedTesting() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'اختبار متقدم',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTestButton(
              'إنشاء سائق في القاهرة',
              Icons.directions_car,
              Colors.blue,
              () => _createDriverAtLocation({
                'name': 'القاهرة - وسط البلد',
                'lat': 30.0444,
                'lng': 31.2357,
              }),
            ),
            const SizedBox(height: 8),
            _buildTestButton(
              'إنشاء سائق في الجيزة',
              Icons.directions_car,
              Colors.green,
              () => _createDriverAtLocation({
                'name': 'الجيزة - الهرم',
                'lat': 29.9792,
                'lng': 31.1342,
              }),
            ),
            const SizedBox(height: 8),
            _buildTestButton(
              'إنشاء راكب وهمي',
              Icons.person,
              Colors.orange,
              () => _createMockRider(),
            ),
            const SizedBox(height: 8),
            _buildTestButton(
              'إنشاء رحلة وهمية',
              Icons.route,
              Colors.purple,
              () => _createMockTrip(),
            ),
            const SizedBox(height: 8),
            _buildTestButton(
              'تحديث موقع السائق',
              Icons.my_location,
              Colors.red,
              () => _updateDriverLocation(),
            ),
          ],
        ),
      ),
    );
  }

  /// زر اختبار
  Widget _buildTestButton(
      String title, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  /// إنشاء سيناريو كامل
  Future<void> _createFullScenario() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await MockTestingService.to.createFullTestScenario();

      Get.back(); // إغلاق dialog التحميل

      Get.snackbar(
        'تم بنجاح',
        'تم إنشاء سيناريو اختبار كامل',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // إغلاق dialog التحميل
      logger.w('خطأ في إنشاء السيناريو: $e');
      Get.snackbar(
        'خطأ',
        'تعذر إنشاء السيناريو',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// حذف جميع البيانات
  Future<void> _clearAllData() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await MockTestingService.to.clearMockData();

      Get.back(); // إغلاق dialog التحميل

      Get.snackbar(
        'تم بنجاح',
        'تم حذف جميع البيانات الوهمية',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // إغلاق dialog التحميل
      logger.w('خطأ في حذف البيانات: $e');
      Get.snackbar(
        'خطأ',
        'تعذر حذف البيانات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// إنشاء سائق في موقع محدد
  Future<void> _createDriverAtLocation(Map<String, dynamic> location) async {
    try {
      final driverId = 'mock_driver_${DateTime.now().millisecondsSinceEpoch}';

             await MockTestingService.to.createMockDriver(
         driverId: driverId,
         driverName: 'سائق ${location['name']}',
         phoneNumber:
             '+201000${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 6)}',
         locationName: location['name'],
       );

      Get.snackbar(
        'تم بنجاح',
        'تم إنشاء سائق في ${location['name']}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.w('خطأ في إنشاء السائق: $e');
      Get.snackbar(
        'خطأ',
        'تعذر إنشاء السائق',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// إنشاء راكب وهمي
  Future<void> _createMockRider() async {
    try {
      final riderId = 'mock_rider_${DateTime.now().millisecondsSinceEpoch}';

             await MockTestingService.to.createMockRider(
         riderId: riderId,
         riderName: 'راكب وهمي',
         phoneNumber:
             '+201000${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 6)}',
       );

      Get.snackbar(
        'تم بنجاح',
        'تم إنشاء راكب وهمي',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.w('خطأ في إنشاء الراكب: $e');
      Get.snackbar(
        'خطأ',
        'تعذر إنشاء الراكب',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// إنشاء رحلة وهمية
  Future<void> _createMockTrip() async {
    try {
      final tripId = 'mock_trip_${DateTime.now().millisecondsSinceEpoch}';
      const riderId = 'mock_rider_1';

      await MockTestingService.to.createMockTrip(
        tripId: tripId,
        riderId: riderId,
        pickupLocationName: 'القاهرة - وسط البلد',
        destinationLocationName: 'الجيزة - الهرم',
      );

      Get.snackbar(
        'تم بنجاح',
        'تم إنشاء رحلة وهمية',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.w('خطأ في إنشاء الرحلة: $e');
      Get.snackbar(
        'خطأ',
        'تعذر إنشاء الرحلة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// تحديث موقع السائق
  Future<void> _updateDriverLocation() async {
    try {
             await MockTestingService.to.updateMockDriverLocation(
         driverId: 'mock_driver_1',
         lat: 30.0444 +
             (Random().nextDouble() - 0.5) * 0.01, // موقع عشوائي قريب من القاهرة
         lng: 31.2357 + (Random().nextDouble() - 0.5) * 0.01,
       );

      Get.snackbar(
        'تم بنجاح',
        'تم تحديث موقع السائق',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.w('خطأ في تحديث الموقع: $e');
      Get.snackbar(
        'خطأ',
        'تعذر تحديث الموقع',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
