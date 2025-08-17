import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/routes/app_routes.dart';

import '../main.dart';
import '../models/user_model.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _fadeAnimation;

  bool _hasNavigated = false; // Flag to prevent multiple navigations

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeApp();
  }

  void _initAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    // بدء الأنيميشن
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _textController.forward();
      }
    });
  }

  Future<void> _initializeApp() async {
    try {
      // انتظار لمدة ثانيتين على الأقل لعرض الشاشة
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted || _hasNavigated) return;

      // فحص حالة المستخدم
      await _checkUserStatus();
    } catch (e) {
      logger.t('خطأ في تهيئة التطبيق: $e');
      if (!_hasNavigated && mounted) {
        _navigateToUserTypeSelection();
      }
    }
  }

  Future<void> _checkUserStatus() async {
    if (_hasNavigated || !mounted) return;

    try {
      AuthController authController;

      // التحقق من وجود AuthController أو إنشاؤه
      if (Get.isRegistered<AuthController>()) {
        authController = Get.find<AuthController>();
      } else {
        // إنشاء AuthController بدون تشغيل _setInitialScreen فوراً
        authController = Get.put(AuthController(), permanent: true);

        // انتظار قصير للسماح للـ controller بالتهيئة
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // انتظار تحميل البيانات المحفوظة
      await Future.delayed(const Duration(milliseconds: 500));

      // التحقق من حالة المستخدم
      final user = authController.currentUser.value;

      if (authController.isLoggedIn.value && user != null) {
        // المستخدم مسجل دخول
        // لديه نوع مستخدم - الانتقال للصفحة الرئيسية
        if (user.userType == UserType.rider) {
          _navigateToRoute(AppRoutes.RIDER_HOME);
        } else {
          _navigateToRoute(AppRoutes.DRIVER_HOME);
        }
      } else {
        // المستخدم غير مسجل دخول
        _navigateToUserTypeSelection();
      }
    } catch (e) {
      logger.t('خطأ في فحص حالة المستخدم: $e');
      if (!_hasNavigated && mounted) {
        _navigateToUserTypeSelection();
      }
    }
  }

  void _navigateToUserTypeSelection() {
    _navigateToRoute(AppRoutes.USER_TYPE_SELECTION);
  }

  void _navigateToRoute(String route) {
    if (_hasNavigated || !mounted) return;

    _hasNavigated = true;

    // التأكد من أن الRoute الحالي ليس نفس الRoute المطلوب
    if (Get.currentRoute != route) {
      Get.offAllNamed(route);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
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
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo مع Animation
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.directions_car,
                          size: 60,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // النصوص مع Animation
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - _textAnimation.value)),
                    child: Opacity(
                      opacity: _textAnimation.value,
                      child: const Column(
                        children: [
                          Text(
                            'تطبيق النقل',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'رحلتك تبدأ هنا',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 100),

              // مؤشر التحميل
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textAnimation.value,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'جاري التحميل...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white60,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
