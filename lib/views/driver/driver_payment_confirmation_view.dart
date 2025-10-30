import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/routes/app_routes.dart';

class DriverPaymentConfirmationView extends StatefulWidget {
  const DriverPaymentConfirmationView({super.key});

  @override
  State<DriverPaymentConfirmationView> createState() =>
      _DriverPaymentConfirmationViewState();
}

class _DriverPaymentConfirmationViewState
    extends State<DriverPaymentConfirmationView> with WidgetsBindingObserver {
  final _amountController = TextEditingController();
  final _storage = GetStorage();
  late TripModel trip;
  bool _isLoading = false;
  Color _inputColor = Colors.orange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTrip();
    _amountController.addListener(_onAmountChanged);
  }

  void _initTrip() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args?['trip'] != null) {
      trip = args!['trip'];
      _lockPaymentSession();
      _amountController.text = trip.fare.toStringAsFixed(0);
    } else {
      _recoverTripOrRedirect();
    }
  }

  void _lockPaymentSession() {
    _storage.write('paymentLock', {
      'tripId': trip.id,
      'status': 'pending',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _recoverTripOrRedirect() {
    final lock = _storage.read('paymentLock');
    if (lock == null || lock['status'] != 'pending') {
      Get.offAllNamed(AppRoutes.DRIVER_HOME);
      return;
    }

    final controller = Get.find<DriverController>();
    final currentTrip = controller.currentTrip.value;
    
    if (currentTrip?.id == lock['tripId']) {
      trip = currentTrip!;
      _amountController.text = trip.fare.toStringAsFixed(0);
    } else {
      Get.offAllNamed(AppRoutes.DRIVER_HOME);
    }
  }



  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final lock = _storage.read('paymentLock');
      if (lock != null && lock['status'] == 'pending') {
        // لا شيء - ابق في صفحة الدفع
      } else if (lock?['status'] == 'confirmed') {
        Get.offAllNamed(AppRoutes.DRIVER_HOME);
      }
    }
  }

  void _onAmountChanged() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (mounted) {
      setState(() {
        _inputColor = amount > trip.fare ? Colors.red : Colors.orange;
      });
    }
  }

  Future<void> _confirmPayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (amount <= 0) {
      _showError('يرجى إدخال مبلغ صحيح');
      return;
    }

    if (amount > trip.fare) {
      _showError('المبلغ أكبر من قيمة الرحلة');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    _storage.write('paymentLock', {
      'tripId': trip.id,
      'status': 'confirmed',
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      Get.offNamed(AppRoutes.TRIP_RATING, arguments: {
        'trip': trip,
        'isDriver': true,
      });
    }
  }

  void _showError(String message) {
    Get.snackbar('خطأ', message,
        backgroundColor: Colors.red, colorText: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // ✅ منع أي محاولة للخروج
        _showError('يجب تأكيد المبلغ أولاً');
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('تأكيد المبلغ'),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildWarningBanner(),
              const SizedBox(height: 40),
              _buildAmountRow('قيمة الرحلة', trip.fare.toStringAsFixed(0)),
              const SizedBox(height: 30),
              _buildInputSection(),
              const SizedBox(height: 40),
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'يرجى إدخال المبلغ المستلم من الراكب بدقة.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange.shade900,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 4),
              const Text('دينار',
                  style: TextStyle(fontSize: 14, color: Colors.orange)),
            ],
          ),
          Text(label,
              style: const TextStyle(fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المبلغ المستلم',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey.shade600),
                onPressed: () => _amountController.clear(),
              ),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _inputColor,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _confirmPayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'تأكيد المبلغ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    super.dispose();
  }
}
