import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/services/driver_profile_service.dart';

class DriverManagementView extends StatefulWidget {
  const DriverManagementView({super.key});

  @override
  State<DriverManagementView> createState() => _DriverManagementViewState();
}

class _DriverManagementViewState extends State<DriverManagementView>
    with SingleTickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();
  final DriverProfileService profileService = Get.find<DriverProfileService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;
  final RxBool isLoading = false.obs;
  final RxList<UserModel> pendingDrivers = <UserModel>[].obs;
  final RxList<UserModel> approvedDrivers = <UserModel>[].obs;
  final RxList<UserModel> rejectedDrivers = <UserModel>[].obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDrivers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers() async {
    try {
      isLoading.value = true;

      // جلب السائقين في انتظار المراجعة
      final pendingQuery = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .where('isProfileComplete', isEqualTo: true)
          .where('isApproved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      pendingDrivers.value = pendingQuery.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();

      // جلب السائقين الموافق عليهم
      final approvedQuery = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .where('isApproved', isEqualTo: true)
          .orderBy('approvedAt', descending: true)
          .get();

      approvedDrivers.value = approvedQuery.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();

      // جلب السائقين المرفوضين
      final rejectedQuery = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'driver')
          .where('isRejected', isEqualTo: true)
          .orderBy('rejectedAt', descending: true)
          .get();

      rejectedDrivers.value = rejectedQuery.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('خطأ في تحميل السائقين: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تحميل بيانات السائقين',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _approveDriver(UserModel driver) async {
    try {
      final adminId = authController.currentUser.value?.id;
      if (adminId == null) throw Exception('لم يتم العثور على معرف الأدمن');

      // تحديث حالة السائق
      await _firestore.collection('users').doc(driver.id).update({
        'isApproved': true,
        'approvedAt': DateTime.now(),
        'approvedBy': adminId,
        'isRejected': false, // إلغاء حالة الرفض إذا كانت موجودة
        'rejectionReason': null,
        'updatedAt': DateTime.now(),
      });

      // إرسال إشعار للسائق
      await _sendDriverNotification(
        driver.id,
        'تمت الموافقة على طلبك',
        'مبروك! تمت الموافقة على طلبك كسائق في التطبيق. يمكنك الآن البدء في العمل.',
      );

      Get.snackbar(
        'تمت الموافقة',
        'تمت الموافقة على السائق ${driver.name} بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await _loadDrivers(); // إعادة تحميل البيانات
    } catch (e) {
      print('خطأ في الموافقة على السائق: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء الموافقة على السائق',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _rejectDriver(UserModel driver) async {
    final reasonController = TextEditingController();

    final result = await Get.dialog<String>(
      AlertDialog(
        title: const Text('رفض السائق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل أنت متأكد من رفض السائق ${driver.name}؟'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: reasonController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('رفض'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final adminId = authController.currentUser.value?.id;
        if (adminId == null) throw Exception('لم يتم العثور على معرف الأدمن');

        await _firestore.collection('users').doc(driver.id).update({
          'isRejected': true,
          'rejectionReason': result,
          'rejectedAt': DateTime.now(),
          'rejectedBy': adminId,
          'isApproved': false, // إلغاء حالة الموافقة إذا كانت موجودة
          'updatedAt': DateTime.now(),
        });

        // إرسال إشعار للسائق
        await _sendDriverNotification(
          driver.id,
          'تم رفض طلبك',
          'للأسف، تم رفض طلبك كسائق. السبب: $result. يمكنك إعادة التقديم بعد 30 يوم.',
        );

        Get.snackbar(
          'تم الرفض',
          'تم رفض السائق ${driver.name}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );

        await _loadDrivers(); // إعادة تحميل البيانات
      } catch (e) {
        print('خطأ في رفض السائق: $e');
        Get.snackbar(
          'خطأ',
          'حدث خطأ أثناء رفض السائق',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('إدارة السائقين'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadDrivers,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.pending),
              text: 'في الانتظار',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'موافق عليهم',
            ),
            Tab(
              icon: Icon(Icons.cancel),
              text: 'مرفوضين',
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildDriversList(pendingDrivers, 'pending'),
            _buildDriversList(approvedDrivers, 'approved'),
            _buildDriversList(rejectedDrivers, 'rejected'),
          ],
        );
      }),
    );
  }

  Widget _buildDriversList(RxList<UserModel> drivers, String status) {
    if (drivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'pending'
                  ? Icons.pending
                  : status == 'approved'
                      ? Icons.check_circle
                      : Icons.cancel,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              status == 'pending'
                  ? 'لا يوجد سائقين في الانتظار'
                  : status == 'approved'
                      ? 'لا يوجد سائقين موافق عليهم'
                      : 'لا يوجد سائقين مرفوضين',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        final driver = drivers[index];
        return _buildDriverCard(driver, status);
      },
    );
  }

  Widget _buildDriverCard(UserModel driver, String status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: driver.profileImage != null
                      ? NetworkImage(driver.profileImage!)
                      : null,
                  child: driver.profileImage == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        driver.phone,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        driver.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 16),
            _buildDriverDetails(driver),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDriverDetails(driver),
                    icon: const Icon(Icons.info),
                    label: const Text('التفاصيل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (status == 'pending') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveDriver(driver),
                      icon: const Icon(Icons.check),
                      label: const Text('موافقة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectDriver(driver),
                      icon: const Icon(Icons.close),
                      label: const Text('رفض'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'في الانتظار';
        icon = Icons.pending;
        break;
      case 'approved':
        color = Colors.green;
        text = 'موافق عليه';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        text = 'مرفوض';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = 'غير محدد';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverDetails(UserModel driver) {
    final additionalData = driver.additionalData ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تفاصيل المركبة:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
            'موديل السيارة', additionalData['vehicleModel'] ?? 'غير محدد'),
        _buildDetailRow(
            'لون السيارة', additionalData['vehicleColor'] ?? 'غير محدد'),
        _buildDetailRow(
            'رقم اللوحة', additionalData['licensePlate'] ?? 'غير محدد'),
        _buildDetailRow(
            'رقم الرخصة', additionalData['licenseNumber'] ?? 'غير محدد'),
        _buildDetailRow(
            'سنة السيارة', additionalData['vehicleYear'] ?? 'غير محدد'),
        _buildDetailRow(
            'منطقة العمل', additionalData['serviceArea'] ?? 'غير محدد'),
        _buildDetailRow(
            'الحساب البنكي', additionalData['bankAccount'] ?? 'غير محدد'),
        _buildDetailRow('جهة اتصال للطوارئ',
            additionalData['emergencyContact'] ?? 'غير محدد'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// إرسال إشعار للسائق
  Future<void> _sendDriverNotification(String driverId, String title, String message) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': driverId,
        'title': title,
        'message': message,
        'type': 'driver_status_update',
        'isRead': false,
        'createdAt': DateTime.now(),
      });
    } catch (e) {
      print('خطأ في إرسال الإشعار: $e');
    }
  }

  /// عرض تفاصيل السائق
  void _showDriverDetails(UserModel driver) {
    Get.dialog(
      AlertDialog(
        title: Text('تفاصيل السائق: ${driver.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('الاسم', driver.name),
              _buildDetailRow('البريد الإلكتروني', driver.email),
              _buildDetailRow('رقم الهاتف', driver.phone),
              _buildDetailRow('تاريخ التسجيل', _formatDate(driver.createdAt)),
              if (driver.isApproved == true)
                _buildDetailRow('تاريخ الموافقة', _formatDate(driver.approvedAt ?? DateTime.now())),
              if (driver.isRejected == true)
                _buildDetailRow('سبب الرفض', driver.rejectionReason ?? 'غير محدد'),
              const SizedBox(height: 16),
              const Text(
                'معلومات المركبة:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._buildVehicleDetails(driver),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  /// بناء تفاصيل المركبة
  List<Widget> _buildVehicleDetails(UserModel driver) {
    final additionalData = driver.additionalData ?? {};
    final details = [
      _buildDetailRow('موديل السيارة', additionalData['vehicleModel'] ?? 'غير محدد'),
      _buildDetailRow('لون السيارة', additionalData['vehicleColor'] ?? 'غير محدد'),
      _buildDetailRow('رقم اللوحة', additionalData['licensePlate'] ?? 'غير محدد'),
      _buildDetailRow('رقم الرخصة', additionalData['licenseNumber'] ?? 'غير محدد'),
      _buildDetailRow('سنة السيارة', additionalData['vehicleYear'] ?? 'غير محدد'),
      _buildDetailRow('منطقة العمل', additionalData['serviceArea'] ?? 'غير محدد'),
    ];
    return details;
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
