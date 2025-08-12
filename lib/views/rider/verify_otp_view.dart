import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/models/user_model.dart';
import 'dart:async';

class VerifyOtpView extends StatefulWidget {
  const VerifyOtpView({super.key});

  @override
  _VerifyOtpViewState createState() => _VerifyOtpViewState();
}

class _VerifyOtpViewState extends State<VerifyOtpView> {
  final AuthController authController = Get.find();
  List<TextEditingController> otpControllers = List.generate(6, (index) => TextEditingController());
  List<FocusNode> otpFocusNodes = List.generate(6, (index) => FocusNode());
  
  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade600,
              Colors.blue.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // زر الرجوع
                _buildBackButton(),
                
                const SizedBox(height: 40),
                
                // العنوان والوصف
                _buildHeader(),
                
                const SizedBox(height: 60),
                
                // حقول إدخال OTP
                _buildOtpInputs(),
                
                const SizedBox(height: 40),
                
                // زر التحقق
                _buildVerifyButton(),
                
                const SizedBox(height: 30),
                
                // زر إعادة الإرسال
                _buildResendSection(),
                
                const SizedBox(height: 30),
                
                // معلومات إضافية
                _buildFooterInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تحقق من رقم هاتفك',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Obx(() => Text(
          'أدخل الرمز المرسل إلى ${authController.phoneController.text}',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        )),
        
        const SizedBox(height: 8),
        
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getUserTypeColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getUserTypeColor(),
              width: 1,
            ),
          ),
          child: Text(
            authController.selectedUserType.value == UserType.rider 
                ? '📱 حساب راكب' 
                : '🚗 حساب سائق',
            style: TextStyle(
              fontSize: 14,
              color: _getUserTypeColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildOtpInputs() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'رمز التحقق',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // صف حقول OTP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) => _buildOtpField(index)),
          ),
          
          const SizedBox(height: 20),
          
          // معلومة توضيحية
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1,
              ),
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
                    'أدخل الرمز المكون من 6 أرقام المرسل عبر الرسائل النصية',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: otpFocusNodes[index].hasFocus 
              ? _getUserTypeColor() 
              : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: TextField(
        controller: otpControllers[index],
        focusNode: otpFocusNodes[index],
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: (value) {
          if (value.length == 1) {
            // انتقل للحقل التالي
            if (index < 5) {
              FocusScope.of(context).requestFocus(otpFocusNodes[index + 1]);
            } else {
              // آخر حقل - تحقق من OTP تلقائياً
              FocusScope.of(context).unfocus();
              _verifyOtp();
            }
          } else if (value.isEmpty && index > 0) {
            // ارجع للحقل السابق
            FocusScope.of(context).requestFocus(otpFocusNodes[index - 1]);
          }
          setState(() {}); // تحديث الواجهة
        },
        onTap: () {
          // إذا كان الحقل فارغ ولكن الحقول السابقة مملوءة، انتقل للحقل الصحيح
          for (int i = 0; i < index; i++) {
            if (otpControllers[i].text.isEmpty) {
              FocusScope.of(context).requestFocus(otpFocusNodes[i]);
              return;
            }
          }
        },
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: authController.isLoading.value 
            ? null 
            : _isOtpComplete() ? _verifyOtp : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getUserTypeColor(),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: _getUserTypeColor().withOpacity(0.4),
        ),
        child: authController.isLoading.value
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'تأكيد الرمز',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    ));
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        const Text(
          'لم تستلم الرمز؟',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        
        const SizedBox(height: 12),
        
        _canResend
            ? GestureDetector(
                onTap: _resendOtp,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'إعادة إرسال الرمز',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'إعادة الإرسال بعد $_resendCountdown ثانية',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildFooterInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.security,
            color: Colors.white70,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'رمز التحقق صالح لمدة 5 دقائق فقط لضمان أمان حسابك',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isOtpComplete() {
    return otpControllers.every((controller) => controller.text.isNotEmpty);
  }

  void _verifyOtp() {
    if (!_isOtpComplete()) {
      Get.snackbar(
        'خطأ',
        'يرجى إدخال الرمز كاملاً',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    String otp = otpControllers.map((controller) => controller.text).join();
    authController.verifyOTP(otp);
  }

  void _resendOtp() {
    if (!_canResend) return;
    
    authController.resendOTP();
    _startResendTimer();
    
    // مسح الحقول
    for (var controller in otpControllers) {
      controller.clear();
    }
    
    // العودة للحقل الأول
    FocusScope.of(context).requestFocus(otpFocusNodes[0]);
    
    Get.snackbar(
      'تم الإرسال',
      'تم إرسال رمز التحقق الجديد',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Color _getUserTypeColor() {
    return authController.selectedUserType.value == UserType.rider
        ? Colors.green
        : Colors.orange;
  }
}