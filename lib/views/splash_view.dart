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

  bool _hasNavigated = false;

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

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _textController.forward();
      }
    });
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted || _hasNavigated) return;

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

      if (Get.isRegistered<AuthController>()) {
        authController = Get.find<AuthController>();
      } else {
        authController = Get.put(AuthController(), permanent: true);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await Future.delayed(const Duration(milliseconds: 300));
      final user = authController.currentUser.value;

      if (authController.isLoggedIn.value && user != null) {
        if (user.userType == UserType.rider) {
          _navigateToRoute(AppRoutes.RIDER_HOME);
        } else {
          _navigateToRoute(AppRoutes.DRIVER_HOME);
        }
      } else {
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
              Colors.orange.shade400,
              Colors.orange.shade600,
              Colors.orange.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.local_taxi,
                          size: 60,
                          color: Colors.orange.shade500,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 35),

              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 40 * (1 - _textAnimation.value)),
                    child: Opacity(
                      opacity: _textAnimation.value,
                      child:   Column(
                        children: [
                          Text(
                            'تكسي البصرة',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                          //    color: Colors.white,
                              color: Colors.brown[700] , 

                              letterSpacing: 1.3,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'رحلتك تبدأ هنا',
                            style: TextStyle(
                              fontSize: 18,
                             // color: Colors.white70,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade800

                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 90),

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
                              Colors.white,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'جاري التحميل...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
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
