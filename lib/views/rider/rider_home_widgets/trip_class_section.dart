import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TripClassSection extends StatelessWidget {
  final RxBool isPlusTrip;
  final VoidCallback onCalculateFare;

  const TripClassSection({
    super.key,
    required this.isPlusTrip,
    required this.onCalculateFare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('فئة الرحلة',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Obx(() => Row(
              children: [
                Expanded(
                    child: GestureDetector(
                  onTap: () {
                    isPlusTrip.value = false;
                    onCalculateFare();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !isPlusTrip.value
                          ? Colors.orange.shade400
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_taxi,
                            color: !isPlusTrip.value
                                ? Colors.white
                                : Colors.grey.shade600,
                            size: 16),
                        const SizedBox(width: 4),
                        Text('عادي',
                            style: TextStyle(
                                color: !isPlusTrip.value
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: GestureDetector(
                  onTap: () {
                    isPlusTrip.value = true;
                    onCalculateFare();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isPlusTrip.value
                          ? Colors.orange.shade400
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star,
                            color: isPlusTrip.value
                                ? Colors.white
                                : Colors.grey.shade600,
                            size: 16),
                        const SizedBox(width: 4),
                        Text('بلس',
                            style: TextStyle(
                                color: isPlusTrip.value
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 2),
                        Text('+1000',
                            style: TextStyle(
                                color: isPlusTrip.value
                                    ? Colors.white70
                                    : Colors.grey.shade500,
                                fontSize: 10)),
                      ],
                    ),
                  ),
                )),
              ],
            )),
      ],
    );
  }
}
