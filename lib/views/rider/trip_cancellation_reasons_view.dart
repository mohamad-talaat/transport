import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:transport_app/routes/app_routes.dart';

class TripCancellationReasonsView extends StatefulWidget {
  const TripCancellationReasonsView({super.key});

  @override
  State<TripCancellationReasonsView> createState() =>
      _TripCancellationReasonsViewState();
}

class _TripCancellationReasonsViewState
    extends State<TripCancellationReasonsView> {
  final TripController tripController = Get.find<TripController>();
  String? selectedReason;
  bool isCancelling = false;

  final List<Map<String, String>> cancellationReasons = [
    {
      'id': 'changed_mind',
      'title': 'غيرت رأيي',
      'description': 'قررت عدم الحاجة للرحلة',
      'icon': '🤔',
    },
    {
      'id': 'driver_delay',
      'title': 'تأخر السائق',
      'description': 'السائق تأخر عن الموعد المحدد',
      'icon': '⏰',
    },
    {
      'id': 'in_hurry',
      'title': 'أنا في عجلة من أمري',
      'description': 'أحتاج لوسيلة نقل أسرع',
      'icon': '🏃‍♂️',
    },
    {
      'id': 'cash_payment',
      'title': 'السائق طلب الدفع نقدي',
      'description': 'السائق يريد الدفع نقداً بدلاً من التطبيق',
      'icon': '💵',
    },
    {
      'id': 'wrong_driver',
      'title': 'السائق غير مناسب',
      'description': 'السائق لا يبدو مناسباً للرحلة',
      'icon': '👤',
    },
    {
      'id': 'vehicle_issue',
      'title': 'مشكلة في السيارة',
      'description': 'السيارة في حالة غير جيدة',
      'icon': '🚗',
    },
    {
      'id': 'safety_concern',
      'title': 'مخاوف أمنية',
      'description': 'لا أشعر بالأمان مع هذا السائق',
      'icon': '🛡️',
    },
    {
      'id': 'price_dispute',
      'title': 'خلاف على السعر',
      'description': 'السائق يطلب سعر مختلف عن المتفق عليه',
      'icon': '💰',
    },
    {
      'id': 'other',
      'title': 'سبب آخر',
      'description': 'سبب مختلف لم يذكر في القائمة',
      'icon': '📝',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // appBar: AppBar(
      //   title: const Text(
      //     'سبب إلغاء الرحلة',
      //     style: TextStyle(
      //       fontWeight: FontWeight.bold,
      //       color: Colors.white,
      //     ),
      //   ),
      //   backgroundColor: Colors.red,
      //   elevation: 0,
      //   centerTitle: true,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back, color: Colors.white),
      //     onPressed: () => Get.back(),
      //   ),
      // ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange[700],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 20,
                ),
                const Icon(
                  Icons.cancel_outlined,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'لماذا تريد إلغاء الرحلة؟',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'اختر السبب الذي يوضح لماذا تريد إلغاء هذه الرحلة',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Reasons List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cancellationReasons.length,
              itemBuilder: (context, index) {
                final reason = cancellationReasons[index];
                final isSelected = selectedReason == reason['id'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedReason = reason['id'];
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.red.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isSelected ? Colors.red : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.red.shade100
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  reason['icon']!,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reason['title']!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.red.shade700
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    reason['description']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected
                                          ? Colors.red.shade600
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Selection indicator
                            if (isSelected)
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              )
                            else
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Cancel Trip Button (only visible when reason is selected)
                if (selectedReason != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: isCancelling ? null : _cancelTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isCancelling
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'إلغاء الرحلة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                // Back Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  Future<void> _cancelTrip() async {
    if (selectedReason == null) return;

    setState(() {
      isCancelling = true;
    });

    try {
      final reason = cancellationReasons
          .firstWhere((r) => r['id'] == selectedReason)['title']!;

      await tripController.cancelTripWithReason(reason);

      // Navigate back to home
      Get.offAllNamed(AppRoutes.RIDER_HOME);
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر إلغاء الرحلة، يرجى المحاولة مرة أخرى',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        isCancelling = false;
      });
    }
  }
}
