import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/models/user_model.dart';

class PhoneAuthView extends StatelessWidget {
  final AuthController authController = Get.find();

  PhoneAuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildPhoneForm(),
              const Spacer(),
              _buildContinueButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _getUserTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            authController.selectedUserType.value == UserType.rider
                ? Icons.person
                : Icons.drive_eta,
            color: _getUserTypeColor(),
            size: 30,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'ادخل رقم الهاتف',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'سنرسل لك رمز التحقق عبر الرسائل القصيرة',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'رقم الهاتف',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🇮🇶',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '+964',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.grey.shade300,
              ),
              Expanded(
                child: TextField(
                  controller: authController.phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                    _IraqPhoneFormatter(),
                  ],
                  decoration: const InputDecoration(
                    hintText: '7XX XXX XXXX',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                      letterSpacing: 1.0,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'سيتم إرسال رمز التحقق المكون من 6 أرقام إلى هذا الرقم',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Obx(() => Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: authController.isLoading.value
                    ? null
                    : () => _validateAndSendOTP(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getUserTypeColor(),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: authController.isLoading.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'متابعة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                text: 'بالمتابعة، أنت توافق على ',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                children: [
                  TextSpan(
                    text: 'الشروط والأحكام',
                    style: TextStyle(
                      color: _getUserTypeColor(),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' و '),
                  TextSpan(
                    text: 'سياسة الخصوصية',
                    style: TextStyle(
                      color: _getUserTypeColor(),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ));
  }

  void _validateAndSendOTP() {
    String phone = authController.phoneController.text.trim();

    if (phone.isEmpty) {
      Get.snackbar(
        'خطأ',
        'يرجى إدخال رقم الهاتف',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (phone.length < 10) {
      Get.snackbar(
        'خطأ',
        'رقم الهاتف غير مكتمل',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    authController.phoneController.text = _formatIraqiPhone(phone);
    authController.sendOTP();
  }

  String _formatIraqiPhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (!phone.startsWith('+964')) {
      if (phone.startsWith('964')) {
        phone = '+$phone';
      } else if (phone.startsWith('0')) {
        phone = '+964${phone.substring(1)}';
      } else {
        phone = '+964$phone';
      }
    }

    return phone;
  }

  Color _getUserTypeColor() {
    return authController.selectedUserType.value == UserType.rider
        ? Colors.green.shade600
        : Colors.blue.shade600;
  }
}

class _IraqPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(' ', '');

    if (text.length <= 3) {
      return newValue.copyWith(text: text);
    } else if (text.length <= 6) {
      return newValue.copyWith(
        text: '${text.substring(0, 3)} ${text.substring(3)}',
        selection: TextSelection.collapsed(
          offset: text.length + 1,
        ),
      );
    } else {
      return newValue.copyWith(
        text:
            '${text.substring(0, 3)} ${text.substring(3, 6)} ${text.substring(6)}',
        selection: TextSelection.collapsed(
          offset: text.length + 2,
        ),
      );
    }
  }
}
