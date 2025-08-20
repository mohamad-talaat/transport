import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/controllers/auth_controller.dart';

class DriverWalletView extends StatelessWidget {
  DriverWalletView({super.key});

  final DriverController driverController = Get.find();
  final AuthController authController = AuthController.to;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('المحفظة'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showWithdrawDialog(),
            icon: const Icon(Icons.account_balance),
            tooltip: 'سحب الأموال',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await driverController.loadEarningsData();
          await authController.loadUserData(authController.currentUser.value!.id);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 20),
              _buildEarningsOverview(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildTransactionHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue, Colors.blueAccent],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(width: 10),
              const Text(
                'الرصيد الحالي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'متاح للسحب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() => Text(
            '${authController.currentUser.value?.balance.toStringAsFixed(2) ?? '0.00'} ج.م',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          )),
          const SizedBox(height: 10),
          Text(
            'آخر تحديث: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsOverview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إجراءات سريعة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'سحب الأموال',
                  Icons.account_balance,
                  Colors.green,
                  () => _showWithdrawDialog(),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildQuickActionButton(
                  'تاريخ المعاملات',
                  Icons.history,
                  Colors.blue,
                  () => _showTransactionHistory(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'تقرير الأرباح',
                  Icons.assessment,
                  Colors.purple,
                  () => _showEarningsReport(),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildQuickActionButton(
                  'طرق الدفع',
                  Icons.payment,
                  Colors.orange,
                  () => _showPaymentMethods(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'المعاملات الأخيرة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showTransactionHistory(),
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildTransactionItem(
            'رحلة #12345',
            '+ 25.50 ج.م',
            'اليوم 14:30',
            Icons.directions_car,
            Colors.green,
          ),
          _buildTransactionItem(
            'رحلة #12344',
            '+ 18.75 ج.م',
            'اليوم 12:15',
            Icons.directions_car,
            Colors.green,
          ),
          _buildTransactionItem(
            'سحب أموال',
            '- 100.00 ج.م',
            'أمس',
            Icons.account_balance,
            Colors.red,
          ),
          _buildTransactionItem(
            'رحلة #12343',
            '+ 32.00 ج.م',
            'أمس 20:45',
            Icons.directions_car,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, String amount, String date, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog() {
    final TextEditingController amountController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance, color: Colors.green),
            SizedBox(width: 8),
            Text('سحب الأموال'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الرصيد المتاح: ${authController.currentUser.value?.balance.toStringAsFixed(2) ?? '0.00'} ج.م',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ المراد سحبه',
                suffixText: 'ج.م',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'الحد الأدنى للسحب: 50 ج.م',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
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
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount >= 50) {
                Get.back();
                _processWithdraw(amount);
              } else {
                Get.snackbar(
                  'خطأ',
                  'يرجى إدخال مبلغ صحيح (الحد الأدنى 50 ج.م)',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('سحب', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _processWithdraw(double amount) {
    final currentBalance = authController.currentUser.value?.balance ?? 0.0;
    
    if (amount > currentBalance) {
      Get.snackbar(
        'خطأ',
        'المبلغ أكبر من الرصيد المتاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('تأكيد السحب'),
        content: Text('هل تريد سحب ${amount.toStringAsFixed(2)} ج.م؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: معالجة عملية السحب مع الخدمة المالية
              authController.updateBalance(-amount);
              Get.snackbar(
                'تم بنجاح',
                'تم إرسال طلب السحب، سيتم التحويل خلال 24 ساعة',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTransactionHistory() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'تاريخ المعاملات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildTransactionItem(
                    'رحلة #12345',
                    '+ 25.50 ج.م',
                    'اليوم 14:30',
                    Icons.directions_car,
                    Colors.green,
                  ),
                  _buildTransactionItem(
                    'رحلة #12344',
                    '+ 18.75 ج.م',
                    'اليوم 12:15',
                    Icons.directions_car,
                    Colors.green,
                  ),
                  _buildTransactionItem(
                    'سحب أموال',
                    '- 100.00 ج.م',
                    'أمس',
                    Icons.account_balance,
                    Colors.red,
                  ),
                  _buildTransactionItem(
                    'رحلة #12343',
                    '+ 32.00 ج.م',
                    'أمس 20:45',
                    Icons.directions_car,
                    Colors.green,
                  ),
                  _buildTransactionItem(
                    'رحلة #12342',
                    '+ 15.25 ج.م',
                    'أمس 18:20',
                    Icons.directions_car,
                    Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEarningsReport() {
    Get.snackbar(
      'قريباً',
      'تقرير الأرباح سيكون متاحاً قريباً',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  void _showPaymentMethods() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.5,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'طرق الدفع',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPaymentMethodItem(
              'فودافون كاش',
              'المحفظة الرئيسية',
              Icons.phone_android,
              Colors.red,
              true,
            ),
            _buildPaymentMethodItem(
              'البنك الأهلي',
              'حساب ****1234',
              Icons.account_balance,
              Colors.blue,
              false,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // إضافة طريقة دفع جديدة
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text(
                'إضافة طريقة دفع جديدة',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItem(String title, String subtitle, IconData icon, Color color, bool isDefault) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: isDefault ? Border.all(color: Colors.green, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'افتراضي',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // تعديل طريقة الدفع
            },
            icon: const Icon(Icons.edit, size: 20),
          ),
        ],
      ),
    );
  }
}
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(15),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.1),
  //           blurRadius: 10,
  //           offset: const Offset(0, 5),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'نظرة عامة على الأرباح',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         const SizedBox(height: 20),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: _buildEarningOverviewCard(
  //                 'اليوم',
  //                 driverController.todayEarnings,
  //                 Icons.today,
  //                 Colors.green,
  //               ),
  //             ),
  //             const SizedBox(width: 15),
  //             Expanded(
  //               child: _buildEarningOverviewCard(
  //                 'الأسبوع',
  //                 driverController.weekEarnings,
  //                 Icons.date_range,
  //                 Colors.blue,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 15),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: _buildEarningOverviewCard(
  //                 'الشهر',
  //                 driverController.monthEarnings,
  //                 Icons.calendar_month,
  //                 Colors.purple,
  //               ),
  //             ),
  //             const SizedBox(width: 15),
  //             Expanded(
  //               child: Container(
  //                 padding: const EdgeInsets.all(15),
  //                 decoration: BoxDecoration(
  //                   color: Colors.orange.withOpacity(0.1),
  //                   borderRadius: BorderRadius.circular(10),
  //                   border: Border.all(color: Colors.orange.withOpacity(0.3)),
  //                 ),
  //                 child: Column(
  //                   children: [
  //                     const Icon(Icons.drive_eta, color: Colors.orange, size: 30),
  //                     const SizedBox(height: 10),
  //                     Obx(() => Text(
  //                       '${driverController.completedTripsToday.value}',
  //                       style: const TextStyle(
  //                         fontSize: 20,
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.orange,
  //                       ),
  //                     )),
  //                     const Text(
  //                       'رحلات اليوم',
  //                       style: TextStyle(
  //                         fontSize: 12,
  //                         color: Colors.grey,
  //                       ),
  //                       textAlign: TextAlign.center,
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildEarningOverviewCard(String title, RxDouble amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Obx(() => Text(
            '${amount.value.toStringAsFixed(2)} ج.م',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          )),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),);}