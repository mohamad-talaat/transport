import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

 

class RiderTypeSelectionView extends StatefulWidget {
  const RiderTypeSelectionView({super.key});

  @override
  State<RiderTypeSelectionView> createState() => _RiderTypeSelectionViewState();
}

class _RiderTypeSelectionViewState extends State<RiderTypeSelectionView>
    with TickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();
  RiderType? selectedType;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _showExitConfirmationDialog,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.amber.shade50,
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  // هنا التعديل
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // نحسب ارتفاع الكارت كنسبة من الشاشة
                        final double cardHeight =
                            (constraints.maxHeight * 0.22).clamp(120, 180);
                        final double spacing =
                            (constraints.maxHeight * 0.02).clamp(8, 16);

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _buildRiderTypeCard(
                                type: RiderType.regularTaxi,
                                // title: 'نقل أمر مكان داخل البصرة',
                                // subtitle: 'نفس السعر',
                                // icon: Icons.local_taxi,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade400,
                                    Colors.orange.shade600
                                  ],
                                ),
                                image: 'assets/images/1.jpeg',
                                height: cardHeight,
                              ),
                              SizedBox(height: spacing),
                              _buildRiderTypeCard(
                                type: RiderType.delivery,
                                // title: 'توصيل مطاعم البصرة',
                                // subtitle: 'اضغط هنا لتوصيل طلب زيون',
                                // icon: Icons.restaurant_menu,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade400,
                                    Colors.purple.shade600
                                  ],
                                ),
                                image: 'assets/images/4.jpeg',
                                height: cardHeight,
                              ),
                              SizedBox(height: spacing),
                              _buildRiderTypeCard(
                                type: RiderType.lineService,
                                // title: 'خطوط الطلاب والموظفين',
                                // subtitle: 'يمكنك طلب خط توصيل من هنا',
                                // icon: Icons.route,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.green.shade600
                                  ],
                                ),
                                image: 'assets/images/3.jpeg',
                                height: cardHeight,
                              ),
                              SizedBox(height: spacing),
                              _buildRiderTypeCard(
                                type: RiderType.external,
                                // title: 'إتاحة هنا',
                                // subtitle: 'مفوض الحكومة',
                                // icon: Icons.link,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.blue.shade600
                                  ],
                                ),
                                image: 'assets/images/2.jpeg',
                                height: cardHeight,
                                isExternal: true,
                                externalUrl:
                                    'https://example.com/external-service',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.exit_to_app,
                        color: Colors.orange.shade600, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'الخروج من التطبيق',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'هل تريد الخروج من التطبيق؟\nستفقد أي بيانات رحلة غير محفوظة.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          'لا، البقاء',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'نعم، خروج',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          const Text(
            'اختر نوع الخدمة',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'حدد الخدمة التي تريد استخدامها',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternalLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'خطأ',
          'تعذر فتح الرابط',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر فتح الرابط: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  _proceedWithSelection(RiderType type) async {
    try {
      final user = authController.currentUser.value;
      if (user == null) return;

      if (type == RiderType.regularTaxi ||
          type == RiderType.delivery ||
          type == RiderType.lineService) {
        // 👇 ابدأ التحديث لكن من غير await
        authController.updateUserRiderType(type.name);

        // 👇 انتقل مباشرة للهوم
Get.toNamed(
  AppRoutes.RIDER_HOME,
  arguments: {'type': type},
);
        return;
      }

      if (type == RiderType.external) {
        Get.snackbar(
          'رابط خارجي',
          'سيتم فتح الخدمة في تطبيق آخر',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء المتابعة: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildRiderTypeCard({
    required RiderType type,
    // required String title,
    // required String subtitle,
    // required IconData icon,
    required Gradient gradient,
    required String image,
    required double height,
    bool isExternal = false,
    String? externalUrl,
  }) {
    final bool isSelected = selectedType == type;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1 + (value * 0.03),
          child: GestureDetector(
            onTap: () {
              if (isExternal && externalUrl != null) {
                _openExternalLink(externalUrl);
              } else {
                setState(() {
                  selectedType = type;
                });
                _proceedWithSelection(type);
              }
            },
            child: Container(
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    gradient.colors.first.withOpacity(0.45),
                    gradient.colors.last.withOpacity(0.45),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: isSelected ? 18 : 6,
                    offset: Offset(0, isSelected ? 8 : 4),
                  ),
                ],
                border: Border.all(
                  color: isSelected ? Colors.white70 : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      image,
                      fit: BoxFit.fill,
                      color: Colors.white.withOpacity(0.05),
                      colorBlendMode: BlendMode.lighten,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey.shade100),
                    ),
                    if (isSelected)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    // محتوى الكارت
                    // Padding(
                    //   padding: const EdgeInsets.all(16),
                    //   child: const Row(
                    //     children: [
                    //       // Container(
                    //       //   width: 56,
                    //       //   height: 56,
                    //       //   decoration: BoxDecoration(
                    //       //     color: Colors.white.withOpacity(0.8),
                    //       //     shape: BoxShape.circle,
                    //       //   ),
                    //       //   child: Icon(icon,
                    //       //       color: gradient.colors.last, size: 28),
                    //       // ),
                    //       SizedBox(width: 16),
                    //       // Expanded(
                    //       //   child: Column(
                    //       //     mainAxisAlignment: MainAxisAlignment.center,
                    //       //     crossAxisAlignment: CrossAxisAlignment.start,
                    //       //     children: [
                    //       //       Text(
                    //       //         title,
                    //       //         style: const TextStyle(
                    //       //           fontSize: 18,
                    //       //           fontWeight: FontWeight.bold,
                    //       //           color: Colors.black87,
                    //       //         ),
                    //       //       ),
                    //       //       const SizedBox(height: 4),
                    //       //       Text(
                    //       //         subtitle,
                    //       //         style: TextStyle(
                    //       //           fontSize: 14,
                    //       //           color: Colors.grey.shade700,
                    //       //         ),
                    //       //       ),
                    //       //     ],
                    //       //   ),
                    //       // ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
