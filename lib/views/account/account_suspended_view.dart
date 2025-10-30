import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/routes/app_routes.dart';

class AccountSuspendedView extends StatefulWidget {
  const AccountSuspendedView({super.key});

  @override
  State<AccountSuspendedView> createState() => _AccountSuspendedViewState();
}

class _AccountSuspendedViewState extends State<AccountSuspendedView> {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController appealController = TextEditingController();

  String? suspensionReason;
  DateTime? suspensionEndDate;
  DateTime? suspensionCreatedAt;
  bool isLoadingSuspensionData = true;
  bool isSubmittingAppeal = false;
  bool hasSubmittedAppeal = false;

  @override
  void initState() {
    super.initState();
    _loadSuspensionData();
  }

  Future<void> _loadSuspensionData() async {
    try {
      final user = authController.currentUser.value;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .get();

      if (userDoc.exists) {
        final additionalData =
            userDoc.data()?['additionalData'] as Map<String, dynamic>?;

        setState(() {
          suspensionReason = additionalData?['suspensionReason'];
          suspensionEndDate =
              (additionalData?['suspensionEndDate'] as Timestamp?)?.toDate();
          suspensionCreatedAt =
              (additionalData?['suspensionCreatedAt'] as Timestamp?)?.toDate();
          isLoadingSuspensionData = false;
        });

        if (suspensionEndDate != null &&
            DateTime.now().isAfter(suspensionEndDate!)) {
          _reactivateAccount();
        }
      }

      await _checkExistingAppeal();
    } catch (e) {
      setState(() {
        isLoadingSuspensionData = false;
      });
      logger.w('خطأ في تحميل بيانات التعليق: $e');
    }
  }

  Future<void> _checkExistingAppeal() async {
    try {
      final user = authController.currentUser.value;
      if (user == null) return;

      final appealQuery = await FirebaseFirestore.instance
          .collection('account_appeals')
          .where('userId', isEqualTo: user.id)
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        hasSubmittedAppeal = appealQuery.docs.isNotEmpty;
      });
    } catch (e) {
      logger.w('خطأ في فحص طلبات المراجعة: $e');
    }
  }

  Future<void> _reactivateAccount() async {
    try {
      final user = authController.currentUser.value;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'additionalData.isSuspended': false,
        'additionalData.suspensionReason': FieldValue.delete(),
        'additionalData.suspensionEndDate': FieldValue.delete(),
        'additionalData.suspensionCreatedAt': FieldValue.delete(),
        'additionalData.reactivatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'تم إعادة تفعيل الحساب',
        'تم إعادة تفعيل حسابك بنجاح',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      final userType = authController.currentUser.value?.userType ?? 'rider';
      if (userType == 'driver') {
        Get.offAllNamed(AppRoutes.DRIVER_HOME);
      } else {
        Get.offAllNamed(AppRoutes.RIDER_HOME);
      }
    } catch (e) {
      logger.w('خطأ في إعادة تفعيل الحساب: $e');
    }
  }

  Future<void> _submitAppeal() async {
    if (appealController.text.trim().isEmpty) {
      Get.snackbar(
        'حقل مطلوب',
        'يرجى كتابة سبب طلب المراجعة',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      isSubmittingAppeal = true;
    });

    try {
      final user = authController.currentUser.value;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('account_appeals').add({
        'userId': user.id,
        'userName': user.name,
        'userType': user.userType,
        'appealText': appealController.text.trim(),
        'suspensionReason': suspensionReason,
        'suspensionDate': suspensionCreatedAt != null
            ? Timestamp.fromDate(suspensionCreatedAt!)
            : null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        hasSubmittedAppeal = true;
        isSubmittingAppeal = false;
      });

      Get.snackbar(
        'تم إرسال الطلب',
        'تم إرسال طلب المراجعة بنجاح. سيتم الرد عليك خلال 48 ساعة',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      appealController.clear();
    } catch (e) {
      setState(() {
        isSubmittingAppeal = false;
      });

      Get.snackbar(
        'خطأ',
        'تعذر إرسال طلب المراجعة. يرجى المحاولة لاحقاً',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      logger.w('خطأ في إرسال طلب المراجعة: $e');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getRemainingDays() {
    if (suspensionEndDate == null) return 'غير محدد';

    final remaining = suspensionEndDate!.difference(DateTime.now()).inDays;
    if (remaining <= 0) {
      return 'انتهت فترة التعليق';
    } else if (remaining == 1) {
      return 'يوم واحد متبقي';
    } else {
      return '$remaining أيام متبقية';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('حساب معلق'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: isLoadingSuspensionData
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.block,
                        size: 60,
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'تم تعليق حسابك',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'نأسف لإبلاغك بأنه تم تعليق حسابك مؤقتاً',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تفاصيل التعليق',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                              'السبب:', suspensionReason ?? 'غير محدد'),
                          _buildDetailRow('تاريخ التعليق:',
                              _formatDate(suspensionCreatedAt)),
                          _buildDetailRow(
                              'ينتهي في:', _formatDate(suspensionEndDate)),
                          _buildDetailRow('المتبقي:', _getRemainingDays()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (!hasSubmittedAppeal) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'طلب مراجعة',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'إذا كنت تعتقد أن التعليق غير عادل، يمكنك تقديم طلب مراجعة',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: appealController,
                              maxLines: 4,
                              maxLength: 500,
                              decoration: InputDecoration(
                                hintText: 'اشرح سبب طلب المراجعة...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.blue.shade400),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    isSubmittingAppeal ? null : _submitAppeal,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isSubmittingAppeal
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Text(
                                        'إرسال طلب المراجعة',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 48,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'تم إرسال طلب المراجعة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'سيتم مراجعة طلبك والرد عليك خلال 48 ساعة',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    OutlinedButton(
                      onPressed: () async {
                        await authController.signOut();
                        Get.offAllNamed(AppRoutes.USER_TYPE_SELECTION);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                      ),
                      child: const Text('تسجيل الخروج'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    appealController.dispose();
    super.dispose();
  }
}
