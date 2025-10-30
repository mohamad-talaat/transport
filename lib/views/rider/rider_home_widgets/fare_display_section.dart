import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/my_map_controller.dart'; // لـ additionalStops
// قد تحتاجها لحساب التفاصيل الدقيقة

class FareDisplaySection extends StatelessWidget {
  final RxDouble totalFare;
  final MyMapController mapController;
  final RxInt waitingTime;
  final RxBool isRoundTrip;
  final RxBool isPlusTrip;
  final Animation<double> priceAnimation;

  const FareDisplaySection({
    super.key,
    required this.totalFare,
    required this.mapController,
    required this.waitingTime,
    required this.isRoundTrip,
    required this.isPlusTrip,
    required this.priceAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade500, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'التكلفة الإجمالية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AnimatedBuilder(
                animation: priceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: priceAnimation.value,
                    child: Obx(() => Text(
                          '${totalFare.value.toStringAsFixed(0)} د.ع',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 2),
          _buildFareBreakdown(),
        ],
      ),
    );
  }

  Widget _buildFareBreakdown() {
    return Obx(() {
      if (mapController.additionalStops.isNotEmpty ||
          waitingTime.value > 0 ||
          isRoundTrip.value ||
          isPlusTrip.value) {
        // حساب الأجرة الأساسية بطريقة عكسية لاستعراض التفاصيل
        double baseCalculatedFare = totalFare.value;

        if (isPlusTrip.value) {
          baseCalculatedFare -= 1000;
        }
        if (mapController.additionalStops.isNotEmpty) {
          baseCalculatedFare -= (mapController.additionalStops.length * 1000);
        }
        if (waitingTime.value > 0) {
          baseCalculatedFare -= (waitingTime.value * 500);
        }
        if (isRoundTrip.value) {
          baseCalculatedFare /= 1.8;
        }

        // هنا نقوم بتقريب baseCalculatedFare إلى أقرب 250 دينار إذا كنت قد قمت بتقريب TotalFare
        // يجب أن يكون هذا متسقًا مع منطق `_calculateFare` في `RiderHomeView`
        // IraqiCurrencyHelper.roundToNearest250(baseCalculatedFare);
        // ولكن للتوضيح، سنستخدم القيمة كما هي بعد الطرح، ويمكن تعديلها لاحقًا

        return Column(
          children: [
            Container(height: 1, color: Colors.white24),
            const SizedBox(height: 4),
            _buildBreakdownRow('التكلفة الأساسية:',
                '${baseCalculatedFare.toStringAsFixed(0)} د.ع'),
            if (isPlusTrip.value) ...[
              const SizedBox(height: 4),
              _buildBreakdownRow('بلس:', '+1000 د.ع'),
            ],
            if (mapController.additionalStops.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildBreakdownRow(
                  'وجهات إضافية (${mapController.additionalStops.length}):',
                  '+${(mapController.additionalStops.length * 1000).toStringAsFixed(0)} د.ع'),
            ],
            if (waitingTime.value > 0) ...[
              const SizedBox(height: 4),
              _buildBreakdownRow('وقت انتظار (${waitingTime.value} دقيقة):',
                  '+${(waitingTime.value * 50).toStringAsFixed(0)} د.ع'),
            ],
            if (isRoundTrip.value) ...[
              const SizedBox(height: 4),
              _buildBreakdownRow('ذهاب وعودة:', '×1.8'),
            ],
          ],
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildBreakdownRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}