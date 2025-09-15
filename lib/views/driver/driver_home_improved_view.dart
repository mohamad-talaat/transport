import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/services/firebase_service.dart';
import 'package:transport_app/services/driver_profile_service.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/models/trip_model.dart';

class DriverHomeImprovedView extends StatefulWidget {
  const DriverHomeImprovedView({super.key});

  @override
  State<DriverHomeImprovedView> createState() => _DriverHomeImprovedViewState();
}

class _DriverHomeImprovedViewState extends State<DriverHomeImprovedView>
    with TickerProviderStateMixin {
  final DriverController driverController = Get.put(DriverController());
  final AuthController authController = AuthController.to;
  final FirebaseService firebaseService = FirebaseService.to;
  final DriverProfileService profileService = Get.find();

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;

  bool _isApproved = false;
  bool _isProfileComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startListeningForRequests();
    _checkProfileCompletion();
    _refreshApprovalStatus();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseController.repeat(reverse: true);
  }

  void _startListeningForRequests() {
    final driverId = authController.currentUser.value?.id;
    if (driverId != null) {
      firebaseService.startListeningForTripRequests(driverId);
    }
  }

  Future<void> _checkProfileCompletion() async {
    try {
      final userId = authController.currentUser.value?.id;
      if (userId == null) return;

      // التحقق من اكتمال الملف الشخصي
      final isComplete = await profileService.isProfileComplete(userId);

      // التحقق من الموافقة الإدارية (اعتمد على users.isApproved)
      final isApproved = await profileService.isDriverApproved(userId);

      setState(() {
        _isProfileComplete = isComplete;
        _isApproved = isApproved;
      });

      // إظهار رسائل حسب الحالة
      if (!isComplete) {
        Get.snackbar(
          'ملف غير مكتمل',
          'يرجى إكمال جميع البيانات المطلوبة في ملفك الشخصي',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
      } else if (!isApproved) {
        Get.snackbar(
          'في انتظار الموافقة',
          'حسابك قيد المراجعة من قبل الإدارة. سيتم إشعارك عند الموافقة.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
      }
    } catch (e) {
      logger.w('خطأ في التحقق من اكتمال البروفايل: $e');
    }
  }

  /// تحديث حالة الموافقة والملف الشخصي
  Future<void> _refreshApprovalStatus() async {
    try {
      final userId = authController.currentUser.value?.id;
      if (userId == null) return;

      final isComplete = await profileService.isProfileComplete(userId);
      final isApproved = await profileService.isDriverApproved(userId);

      if (mounted) {
        setState(() {
          _isProfileComplete = isComplete;
          _isApproved = isApproved;
        });
      }
    } catch (e) {
      logger.w('خطأ في تحديث حالة الموافقة: $e');
    }
  }

  Widget _buildStatusCard() {
    // تحديد الحالة والرسالة المناسبة
    String title;
    String message;
    Color color;
    IconData icon;

    if (!_isProfileComplete) {
      title = 'ملف غير مكتمل';
      message =
          'يرجى إكمال جميع البيانات المطلوبة في ملفك الشخصي لتتمكن من استقبال الرحلات';
      color = Colors.red.shade600;
      icon = Icons.person_off;
    } else if (!_isApproved) {
      title = 'في انتظار الموافقة';
      message =
          'حسابك قيد المراجعة من قبل الإدارة. سيتم إشعارك عند الموافقة لتتمكن من استقبال الرحلات';
      color = Colors.orange.shade600;
      icon = Icons.pending_actions;
    } else {
      title = 'جاهز للعمل';
      message = 'يمكنك الآن استقبال الرحلات';
      color = Colors.green.shade600;
      icon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'جزء البحث عن الرحلات مخفي حتى تكتمل جميع المتطلبات',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (!_isProfileComplete) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.toNamed(AppRoutes.DRIVER_PROFILE_COMPLETION);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('إكمال الملف'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _refreshApprovalStatus();
                    Get.snackbar(
                      'تم التحديث',
                      'تم تحديث حالة الملف والموافقة',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث الحالة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await driverController.loadEarningsData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildModernHeader(),
                const SizedBox(height: 20),
                _buildOnlineStatusCard(),
                const SizedBox(height: 20),
                _buildEarningsSection(),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 20),
                if (_isProfileComplete && _isApproved) ...[
                  _buildTripRequestsSection(),
                ] else ...[
                  _buildStatusCard(),
                ],
                const SizedBox(height: 100), // مساحة للـ bottom navigation
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF3B82F6),
            Color(0xFF60A5FA),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Obx(() => CircleAvatar(
                    radius: 35,
                    backgroundImage: (authController
                                .currentUser.value?.profileImage?.isNotEmpty ??
                            false)
                        ? NetworkImage(
                            authController.currentUser.value!.profileImage!)
                        : null,
                    child: (authController
                                .currentUser.value?.profileImage?.isNotEmpty ??
                            false)
                        ? null
                        : const Icon(Icons.person,
                            size: 35, color: Colors.white),
                  )),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => Text(
                        'مرحباً، ${authController.currentUser.value?.name ?? 'السائق'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                  const SizedBox(height: 4),
                  Obx(() => Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: driverController.isOnline.value
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            driverController.isOnline.value
                                ? 'متصل ونشط'
                                : 'غير متصل',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildHeaderButton(
                  icon: Icons.settings,
                  onTap: () => Get.toNamed(AppRoutes.DRIVER_SETTINGS),
                ),
                const SizedBox(width: 8),
                _buildHeaderButton(
                  icon: Icons.logout,
                  onTap: () => _showLogoutDialog(),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 20),
          _buildBalanceCard(),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 24),
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'رصيد المحفظة',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                      '${authController.currentUser.value?.balance.toStringAsFixed(2) ?? '0.00'} ج.م',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Get.toNamed(AppRoutes.DRIVER_WALLET),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'شحن',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'حالة الاتصال',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                          driverController.isOnline.value
                              ? 'أنت متاح لاستقبال الطلبات'
                              : 'أنت غير متصل حالياً',
                          style: TextStyle(
                            fontSize: 14,
                            color: driverController.isOnline.value
                                ? const Color(0xFF059669)
                                : const Color(0xFF6B7280),
                          ),
                        )),
                  ],
                ),
              ),
              Obx(() {
                return Transform.scale(
                  scale: driverController.isOnline.value
                      ? _pulseAnimation.value
                      : 1.0,
                  child: Switch(
                    value: driverController.isOnline.value,
                    onChanged: (value) {
                      driverController.toggleOnlineStatus();
                    },
                  ),
                );
              })
            ],
          ),
          if (driverController.isOnline.value) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Color(0xFF059669),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'سيتم إشعارك فوراً عند وصول طلب جديد',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEarningsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الأرباح اليومية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEarningsCard(
                  title: 'اليوم',
                  amount: driverController.todayEarnings.value,
                  icon: Icons.today,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEarningsCard(
                  title: 'الأسبوع',
                  amount: driverController.weekEarnings.value,
                  icon: Icons.calendar_view_week,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEarningsCard(
                  title: 'الشهر',
                  amount: driverController.monthEarnings.value,
                  icon: Icons.calendar_month,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEarningsCard(
                  title: 'الرحلات',
                  amount: driverController.completedTripsToday.value.toDouble(),
                  icon: Icons.directions_car,
                  color: const Color(0xFFF59E0B),
                  isCount: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    bool isCount = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isCount
                ? amount.toInt().toString()
                : '${amount.toStringAsFixed(2)} ج.م',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إجراءات سريعة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'المحفظة',
                  subtitle: 'شحن وإدارة الرصيد',
                  icon: Icons.account_balance_wallet,
                  color: const Color(0xFF3B82F6),
                  onTap: () => Get.toNamed(AppRoutes.DRIVER_WALLET),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'التقييمات',
                  subtitle: 'تقييمات العملاء',
                  icon: Icons.star,
                  color: const Color(0xFFF59E0B),
                  onTap: () => Get.toNamed(AppRoutes.DRIVER_PROFILE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'التاريخ',
                  subtitle: 'رحلات سابقة',
                  icon: Icons.history,
                  color: const Color(0xFF10B981),
                  onTap: () => Get.toNamed(AppRoutes.DRIVER_TRIP_HISTORY),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'كود الخصم',
                  subtitle: 'استخدام كود خصم',
                  icon: Icons.discount,
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _showDiscountCodeDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripRequestsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'طلبات الرحلات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (firebaseService.tripRequests.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد طلبات حالياً',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ستظهر هنا طلبات الرحلات الجديدة',
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

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: firebaseService.tripRequests.length,
              itemBuilder: (context, index) {
                final trip = firebaseService.tripRequests[index];
                return _buildTripRequestCard(trip);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTripRequestCard(TripModel trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'طلب رحلة جديد',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trip.distance.toStringAsFixed(1)} كم • ${trip.estimatedDuration} دقيقة',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${trip.fare.toStringAsFixed(2)} ج.م',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLocationRow(
            icon: Icons.my_location,
            title: 'من',
            address: trip.pickupLocation.address,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 8),
          _buildLocationRow(
            icon: Icons.location_on,
            title: 'إلى',
            address: trip.destinationLocation.address,
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _declineTrip(trip),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'رفض',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptTrip(trip),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'قبول',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String title,
    required String address,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'الرئيسية',
                isActive: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.history,
                label: 'التاريخ',
                isActive: false,
                onTap: () => Get.toNamed(AppRoutes.DRIVER_TRIP_HISTORY),
              ),
              _buildNavItem(
                icon: Icons.account_balance_wallet,
                label: 'المحفظة',
                isActive: false,
                onTap: () => Get.toNamed(AppRoutes.DRIVER_WALLET),
              ),
              _buildNavItem(
                icon: Icons.person,
                label: 'الملف',
                isActive: false,
                onTap: () => Get.toNamed(AppRoutes.DRIVER_PROFILE),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFF3B82F6) : Colors.grey[400],
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? const Color(0xFF3B82F6) : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _acceptTrip(TripModel trip) {
    driverController.acceptTrip(trip);
  }

  void _declineTrip(TripModel trip) {
    driverController.declineTrip(trip);
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () {
              // تجنب خطأ GetX عند عدم وجود Snackbar مُهيأ
              if (Get.isSnackbarOpen) {
                try {
                  Get.closeCurrentSnackbar();
                } catch (_) {}
              }
              Get.back();
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (Get.isSnackbarOpen) {
                try {
                  Get.closeCurrentSnackbar();
                } catch (_) {}
              }
              Get.back();
              authController.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  void _showDiscountCodeDialog() {
    final TextEditingController codeController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.discount, color: Color(0xFF8B5CF6)),
            SizedBox(width: 8),
            Text('كود الخصم'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'أدخل كود الخصم الذي حصلت عليه من الإدارة',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: 'أدخل كود الخصم',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.confirmation_number),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.trim().isEmpty) {
                Get.snackbar(
                  'خطأ',
                  'يرجى إدخال كود الخصم',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              Get.back();
              _redeemDiscountCode(codeController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  void _redeemDiscountCode(String code) async {
    final userId = authController.currentUser.value?.id;
    if (userId == null) return;

    try {
      final result = await firebaseService.redeemDiscountCode(
        code: code,
        userId: userId,
      );

      if (result['success']) {
        Get.snackbar(
          'نجح',
          'تم تطبيق كود الخصم بنجاح! تم إضافة ${result['amount']} ج.م إلى رصيدك',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );

        // تحديث رصيد المستخدم في الواجهة
        // سيتم تحديث البيانات تلقائياً من Firebase
      } else {
        Get.snackbar(
          'خطأ',
          result['message'],
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تطبيق كود الخصم',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
