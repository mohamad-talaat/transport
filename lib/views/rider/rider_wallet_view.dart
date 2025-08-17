import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/routes/app_routes.dart';

class RiderWalletView extends StatelessWidget {
  const RiderWalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحفظة'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة الرصيد
            _buildBalanceCard(authController),

            const SizedBox(height: 24),

            // أزرار الإجراءات
            _buildActionButtons(),

            const SizedBox(height: 24),

            // سجل العمليات
            _buildTransactionHistory(),
          ],
        ),
      ),
    );
  }

  /// بطاقة الرصيد
  Widget _buildBalanceCard(AuthController authController) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'الرصيد الحالي',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Text(
                '${authController.currentUser.value?.balance.toStringAsFixed(2) ?? '0.00'} ج.م',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              )),
        ],
      ),
    );
  }

  /// أزرار الإجراءات
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAddBalanceDialog(),
            icon: const Icon(Icons.add),
            label: const Text('إضافة رصيد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showWithdrawDialog(),
            icon: const Icon(Icons.remove),
            label: const Text('سحب رصيد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// سجل العمليات
  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'سجل العمليات',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTransactionItem(
          type: 'إضافة رصيد',
          amount: '+50.00',
          date: '2024-01-15',
          isPositive: true,
        ),
        _buildTransactionItem(
          type: 'رحلة',
          amount: '-25.00',
          date: '2024-01-14',
          isPositive: false,
        ),
        _buildTransactionItem(
          type: 'إضافة رصيد',
          amount: '+100.00',
          date: '2024-01-10',
          isPositive: true,
        ),
      ],
    );
  }

  /// عنصر العملية
  Widget _buildTransactionItem({
    required String type,
    required String amount,
    required String date,
    required bool isPositive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPositive
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.add : Icons.remove,
              color: isPositive ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// عرض نافذة إضافة رصيد
  void _showAddBalanceDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('إضافة رصيد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اختر طريقة إضافة الرصيد:'),
            const SizedBox(height: 20),
            _buildPaymentOption(
              icon: Icons.credit_card,
              title: 'بطاقة ائتمان',
              subtitle: 'قريباً',
              onTap: () {
                Get.back();
                Get.snackbar(
                  'قريباً',
                  'سيتم تفعيل هذه الميزة قريباً',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              icon: Icons.confirmation_number,
              title: 'كود شحن',
              subtitle: 'أدخل كود الشحن',
              onTap: () => _showVoucherDialog(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  /// خيار الدفع
  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// عرض نافذة كود الشحن
  void _showVoucherDialog() {
    final voucherController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('كود الشحن'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: voucherController,
              decoration: const InputDecoration(
                labelText: 'أدخل كود الشحن',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'أو اطلب كود شحن من الشركة',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (voucherController.text.isNotEmpty) {
                Get.back();
                _redeemVoucher(voucherController.text);
              }
            },
            child: const Text('استخدام الكود'),
          ),
        ],
      ),
    );
  }

  /// استخدام كود الشحن
  void _redeemVoucher(String code) {
    // TODO: إرسال الكود للخادم للتحقق منه
    Get.snackbar(
      'تم بنجاح',
      'تم إضافة الرصيد بنجاح',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  /// عرض نافذة سحب الرصيد
  void _showWithdrawDialog() {
    Get.snackbar(
      'قريباً',
      'سيتم تفعيل ميزة سحب الرصيد قريباً',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }
}
