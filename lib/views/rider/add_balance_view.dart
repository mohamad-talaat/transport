import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/wallet_controller.dart';

class AddBalanceView extends StatelessWidget {
  const AddBalanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final walletController = Get.put(WalletController());
    final codeController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('شحن الرصيد'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'أدخل كود الشحن',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'مثال: ABC123XYZ',
                prefixIcon: Icon(Icons.confirmation_number),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => ElevatedButton.icon(
                  onPressed: walletController.isLoading.value
                      ? null
                      : () async {
                          final code = codeController.text.trim();
                          if (code.isEmpty) return;
                          await walletController.redeemVoucher(code);
                          if (!walletController.isLoading.value) {
                            Get.back();
                          }
                        },
                  icon: walletController.isLoading.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: Text(walletController.isLoading.value
                      ? 'جاري المعالجة...'
                      : 'تأكيد الشحن'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
          ],
        ),
      ),
    );
  }
}
