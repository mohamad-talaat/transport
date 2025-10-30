

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditWaitingTimeSection extends StatelessWidget {
  final RxInt tripWaitingTime;
 

  const EditWaitingTimeSection({
    super.key,
    required this.tripWaitingTime,
 
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
      children: [
        Expanded(child: _buildTimeOption(0, 'بدون', Icons.flash_on)),
        const SizedBox(width: 6),
        Expanded(child: _buildTimeOption(5, '5 د', Icons.schedule)),
        const SizedBox(width: 6),
        Expanded(child: _buildTimeOption(10, '10 د', Icons.access_time)),
        const SizedBox(width: 6),
        Expanded(child: _buildTimeOption(15, '15 د', Icons.timer)),
      ],
    ));
  }

  Widget _buildTimeOption(int minutes, String label, IconData icon) {
    final isSelected = tripWaitingTime.value == minutes;
    return GestureDetector(
      onTap: () => tripWaitingTime.value = minutes,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class EditWaitingTimeSection extends StatelessWidget {
//   final RxMap<int, int> stopWaitingTimes;
//   final int stopIndex;
//   final String stopName;

//   const EditWaitingTimeSection({
//     super.key,
//     required this.stopWaitingTimes,
//     required this.stopIndex,
//     required this.stopName,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'وقت الانتظار - $stopName',
//           style: const TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.w600,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Obx(() => Row(
//           children: [
//             Expanded(child: _buildTimeOption(0, 'بدون', Icons.flash_on)),
//             const SizedBox(width: 6),
//             Expanded(child: _buildTimeOption(5, '5 د', Icons.schedule)),
//             const SizedBox(width: 6),
//             Expanded(child: _buildTimeOption(10, '10 د', Icons.access_time)),
//             const SizedBox(width: 6),
//             Expanded(child: _buildTimeOption(15, '15 د', Icons.timer)),
//           ],
//         )),
//       ],
//     );
//   }

//   Widget _buildTimeOption(int minutes, String label, IconData icon) {
//     final isSelected = (stopWaitingTimes[stopIndex] ?? 0) == minutes;
//     return GestureDetector(
//       onTap: () => stopWaitingTimes[stopIndex] = minutes,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
//         decoration: BoxDecoration(
//           color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade50,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
//             width: 1.5,
//           ),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade600),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 color: isSelected ? Colors.white : Colors.grey.shade600,
//                 fontSize: 10,
//                 fontWeight: FontWeight.w600,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// } 