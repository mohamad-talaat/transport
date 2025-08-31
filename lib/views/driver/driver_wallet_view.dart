import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/services/driver_discount_service.dart';
import 'package:transport_app/services/firebase_service.dart';
import 'package:transport_app/models/payment_model.dart';
import 'package:transport_app/models/trip_model.dart';

class DriverWalletView extends StatefulWidget {
  const DriverWalletView({super.key});

  @override
  State<DriverWalletView> createState() => _DriverWalletViewState();
}

class _DriverWalletViewState extends State<DriverWalletView> {
  final DriverController driverController = Get.find();
  final AuthController authController = AuthController.to;
  final DriverDiscountService discountService =
      Get.find<DriverDiscountService>();
  final FirebaseService firebaseService = FirebaseService.to;

  // Reactive variables for dynamic data
  final RxList<PaymentModel> recentTransactions = <PaymentModel>[].obs;
  final RxList<TripModel> recentTrips = <TripModel>[].obs;
  final RxBool isLoadingTransactions = false.obs;
  final RxBool isLoadingTrips = false.obs;

  @override
  void initState() {
    super.initState();
    _loadDynamicData();
  }

  /// تحميل البيانات الديناميكية من Firebase
  Future<void> _loadDynamicData() async {
    await _loadRecentTransactions();
    await _loadRecentTrips();
  }

  /// تحميل المعاملات الأخيرة
  Future<void> _loadRecentTransactions() async {
    try {
      isLoadingTransactions.value = true;
      final userId = authController.currentUser.value?.id;
      if (userId == null) return;

      final transactions = await _getRecentTransactions(userId);
      recentTransactions.value = transactions;
    } catch (e) {
      print('خطأ في تحميل المعاملات: $e');
    } finally {
      isLoadingTransactions.value = false;
    }
  }

  /// تحميل الرحلات الأخيرة
  Future<void> _loadRecentTrips() async {
    try {
      isLoadingTrips.value = true;
      final userId = authController.currentUser.value?.id;
      if (userId == null) return;

      final trips = await _getRecentTrips(userId);
      recentTrips.value = trips;
    } catch (e) {
      print('خطأ في تحميل الرحلات: $e');
    } finally {
      isLoadingTrips.value = false;
    }
  }

  /// جلب المعاملات الأخيرة من Firebase
  Future<List<PaymentModel>> _getRecentTransactions(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PaymentModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('خطأ في جلب المعاملات: $e');
      return [];
    }
  }

  /// جلب الرحلات الأخيرة من Firebase
  Future<List<TripModel>> _getRecentTrips(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('driverId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TripModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('خطأ في جلب الرحلات: $e');
      return [];
    }
  }

  /// الحصول على عنوان المعاملة
  String _getTransactionTitle(PaymentModel transaction) {
    switch (transaction.method) {
      case PaymentMethod.wallet:
        return 'شحن محفظة';
      case PaymentMethod.cash:
        return 'دفع نقدي';
      case PaymentMethod.card:
        return 'دفع ببطاقة';
      case PaymentMethod.discountCode:
        return 'كود خصم';
      default:
        return 'معاملة مالية';
    }
  }

  /// الحصول على مبلغ المعاملة
  String _getTransactionAmount(PaymentModel transaction) {
    final prefix = transaction.amount >= 0 ? '+ ' : '- ';
    final amount = transaction.amount.abs();
    return '$prefix${amount.toStringAsFixed(2)} ج.م';
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'أمس ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// الحصول على أيقونة المعاملة
  IconData _getTransactionIcon(PaymentModel transaction) {
    switch (transaction.method) {
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet;
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.discountCode:
        return Icons.discount;
      default:
        return Icons.payment;
    }
  }

  /// الحصول على لون المعاملة
  Color _getTransactionColor(PaymentModel transaction) {
    if (transaction.amount >= 0) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

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
          await authController
              .loadUserData(authController.currentUser.value!.id);
          await _loadDynamicData();
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            'نظرة عامة على الأرباح',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildEarningsCard(
                  'اليوم',
                  Obx(() => Text(
                        '${driverController.todayEarnings.value.toStringAsFixed(2)} ج.م',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      )),
                  Icons.today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildEarningsCard(
                  'الأسبوع',
                  Obx(() => Text(
                        '${driverController.weekEarnings.value.toStringAsFixed(2)} ج.م',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      )),
                  Icons.calendar_view_week,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildEarningsCard(
                  'الشهر',
                  Obx(() => Text(
                        '${driverController.monthEarnings.value.toStringAsFixed(2)} ج.م',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      )),
                  Icons.calendar_month,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildEarningsCard(
                  'الرحلات',
                  Obx(() => Text(
                        '${driverController.completedTripsToday.value} رحلة',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      )),
                  Icons.directions_car,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(
      String title, Widget amount, IconData icon, Color color) {
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
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          amount,
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
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
          Obx(() {
            if (isLoadingTransactions.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (recentTransactions.isEmpty && recentTrips.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد معاملات حديثة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ستظهر هنا المعاملات والرحلات الجديدة',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // عرض المعاملات المالية
                ...recentTransactions
                    .map((transaction) => _buildTransactionItem(
                          _getTransactionTitle(transaction),
                          _getTransactionAmount(transaction),
                          _formatDate(transaction.createdAt),
                          _getTransactionIcon(transaction),
                          _getTransactionColor(transaction),
                        )),

                // عرض الرحلات المكتملة
                ...recentTrips.map((trip) => _buildTransactionItem(
                      'رحلة #${trip.id.substring(0, 8)}',
                      '+ ${(trip.fare * 0.8).toStringAsFixed(2)} ج.م',
                      _formatDate(trip.completedAt ?? trip.createdAt),
                      Icons.directions_car,
                      Colors.green,
                    )),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
      String title, String amount, String date, IconData icon, Color color) {
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
              child: RefreshIndicator(
                onRefresh: _loadDynamicData,
                child: Obx(() {
                  if (isLoadingTransactions.value) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (recentTransactions.isEmpty && recentTrips.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد معاملات',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ستظهر هنا المعاملات والرحلات الجديدة',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    children: [
                      // عرض المعاملات المالية
                      ...recentTransactions
                          .map((transaction) => _buildTransactionItem(
                                _getTransactionTitle(transaction),
                                _getTransactionAmount(transaction),
                                _formatDate(transaction.createdAt),
                                _getTransactionIcon(transaction),
                                _getTransactionColor(transaction),
                              )),

                      // عرض الرحلات المكتملة
                      ...recentTrips.map((trip) => _buildTransactionItem(
                            'رحلة #${trip.id.substring(0, 8)}',
                            '+ ${(trip.fare * 0.8).toStringAsFixed(2)} ج.م',
                            _formatDate(trip.completedAt ?? trip.createdAt),
                            Icons.directions_car,
                            Colors.green,
                          )),
                    ],
                  );
                }),
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

  void _showDiscountCodeDialog() {
    final discountController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.confirmation_number,
                size: 60,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'كود الخصم',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'أدخل كود الخصم الخاص بك',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: discountController,
                decoration: InputDecoration(
                  labelText: 'أدخل كود الخصم',
                  hintText: 'مثال: DRIVER123',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.confirmation_number),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
                inputFormatters: [
                  UpperCaseTextFormatter(),
                ],
              ),
              const SizedBox(height: 24),

              // معلومات إضافية عن كود الخصم
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info,
                            color: Colors.orange.shade700, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'معلومات كود الخصم',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• يمكن استخدام كود واحد فقط لكل سائق\n• الكود صالح لمدة 30 يوم\n• الحد الأقصى للخصم: 50 ج.م',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // زر طلب كود جديد
              OutlinedButton.icon(
                onPressed: () => _requestNewDiscountCode(),
                icon: const Icon(Icons.wechat_sharp, color: Colors.green),
                label: const Text('طلب كود جديد عبر واتساب'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => ElevatedButton(
                          onPressed: discountService.isLoading.value
                              ? null
                              : () async {
                                  if (discountController.text.isNotEmpty) {
                                    final result = await _redeemDiscountCode(
                                        discountController.text);
                                    Get.back();

                                    if (result['success']) {
                                      Get.snackbar(
                                        'تم بنجاح',
                                        result['message'],
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                        duration: const Duration(seconds: 3),
                                      );
                                      // تحديث البيانات
                                      await _refreshAllData();
                                    } else {
                                      Get.snackbar(
                                        'خطأ',
                                        result['message'],
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  } else {
                                    Get.snackbar(
                                      'خطأ',
                                      'يرجى إدخال كود الخصم',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: discountService.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text('استخدام الكود'),
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// طلب كود خصم جديد
  void _requestNewDiscountCode() {
    Get.dialog(
      AlertDialog(
        title: const Text('طلب كود خصم جديد'),
        content: const Text(
          'سيتم إرسال طلب كود خصم جديد عبر واتساب. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              discountService.requestNewDiscountCode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  /// استخدام كود الخصم
  Future<Map<String, dynamic>> _redeemDiscountCode(String code) async {
    try {
      // التحقق من صحة الكود
      if (code.length < 6) {
        return {
          'success': false,
          'message': 'كود الخصم يجب أن يكون 6 أحرف على الأقل',
        };
      }

      // محاكاة استخدام الكود (يمكن استبدالها بالخدمة الحقيقية)
      await Future.delayed(const Duration(seconds: 2));

      // إضافة المبلغ إلى المحفظة
      const discountAmount = 25.0; // مبلغ الخصم
      await authController.updateBalance(discountAmount);

      // تسجيل المعاملة
      await _recordDiscountTransaction(code, discountAmount);

      return {
        'success': true,
        'message':
            'تم استخدام كود الخصم بنجاح! تم إضافة $discountAmount ج.م إلى محفظتك',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء استخدام الكود: $e',
      };
    }
  }

  /// تسجيل معاملة كود الخصم
  Future<void> _recordDiscountTransaction(String code, double amount) async {
    try {
      final userId = authController.currentUser.value?.id;
      if (userId == null) return;

      await FirebaseFirestore.instance.collection('payments').add({
        'userId': userId,
        'amount': amount,
        'method': 'discountCode',
        'description': 'كود خصم: $code',
        'status': 'completed',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      print('خطأ في تسجيل معاملة كود الخصم: $e');
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

  Widget _buildEarningOverviewCard(
      String title, RxDouble amount, IconData icon, Color color) {
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
                  'كود الخصم',
                  Icons.confirmation_number,
                  Colors.orange,
                  () => _showDiscountCodeDialog(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'إحصائيات مفصلة',
                  Icons.analytics,
                  Colors.teal,
                  () => _showDetailedStatistics(),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildQuickActionButton(
                  'تحديث البيانات',
                  Icons.refresh,
                  Colors.indigo,
                  () => _refreshAllData(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'إحصائيات حية',
                  Icons.timeline,
                  Colors.cyan,
                  () => _showLiveStatistics(),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildQuickActionButton(
                  'تقرير مفصل',
                  Icons.assessment,
                  Colors.deepPurple,
                  () => _showDetailedStatistics(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// عرض الإحصائيات الحية
  void _showLiveStatistics() {
    Get.dialog(
      AlertDialog(
        title: const Text('الإحصائيات الحية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatisticRow('إجمالي الرحلات', '${recentTrips.length} رحلة'),
            _buildStatisticRow(
                'إجمالي المعاملات', '${recentTransactions.length} معاملة'),
            _buildStatisticRow('الرصيد الحالي',
                '${authController.currentUser.value?.balance.toStringAsFixed(2) ?? '0.00'} ج.م'),
            _buildStatisticRow('أرباح اليوم',
                '${driverController.todayEarnings.value.toStringAsFixed(2)} ج.م'),
          ],
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

  /// بناء صف إحصائي
  Widget _buildStatisticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }

  /// تحديث جميع البيانات
  Future<void> _refreshAllData() async {
    try {
      Get.dialog(
        const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('جاري تحديث البيانات...'),
            ],
          ),
        ),
      );

      await Future.wait([
        driverController.loadEarningsData(),
        authController.loadUserData(authController.currentUser.value!.id),
        _loadDynamicData(),
      ]);

      Get.back(); // إغلاق dialog التحميل
      Get.snackbar(
        'نجح',
        'تم تحديث جميع البيانات بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // إغلاق dialog التحميل
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تحديث البيانات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// عرض إحصائيات مفصلة
  void _showDetailedStatistics() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
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
                  'إحصائيات مفصلة',
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDetailedStatCard(
                      'إجمالي الرحلات',
                      '${recentTrips.length} رحلة',
                      Icons.directions_car,
                      Colors.blue,
                    ),
                    _buildDetailedStatCard(
                      'إجمالي المعاملات',
                      '${recentTransactions.length} معاملة',
                      Icons.receipt_long,
                      Colors.green,
                    ),
                    _buildDetailedStatCard(
                      'متوسط الرحلة',
                      '25 ج.م',
                      Icons.trending_up,
                      Colors.orange,
                    ),
                    _buildDetailedStatCard(
                      'أفضل يوم',
                      'السبت',
                      Icons.star,
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// تحويل النص إلى أحرف كبيرة
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
