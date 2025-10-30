import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WaitingTimeSection extends StatelessWidget {
  final RxInt waitingTime;
  final VoidCallback onCalculateFare;

  const WaitingTimeSection({
    super.key,
    required this.waitingTime,
    required this.onCalculateFare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'وقت الانتظار المتوقع',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Row(
              children: [
                Expanded(
                    child: _buildWaitingTimeOption(
                        0, 'بدون انتظار', Icons.flash_on)),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        _buildWaitingTimeOption(5, '5 دقائق', Icons.schedule)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildWaitingTimeOption(
                        10, '10 دقائق', Icons.access_time)),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        _buildWaitingTimeOption(15, '15 دقيقة', Icons.timer)),
              ],
            )),
      ],
    );
  }

  Widget _buildWaitingTimeOption(int minutes, String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        waitingTime.value = minutes;
        onCalculateFare();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
        decoration: BoxDecoration(
          color: waitingTime.value == minutes
              ? Colors.orange.shade400
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: waitingTime.value == minutes
                ? Colors.orange.shade400
                : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: waitingTime.value == minutes
                  ? Colors.white
                  : Colors.grey.shade600,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: waitingTime.value == minutes
                    ? Colors.white
                    : Colors.grey.shade600,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (minutes > 0) ...[
              const SizedBox(height: 1),
              Text(
                '+${(minutes * 50).toStringAsFixed(0)} د.ع',
                style: TextStyle(
                  color: waitingTime.value == minutes
                      ? Colors.white70
                      : Colors.grey.shade500,
                  fontSize: 8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}