import 'package:flutter/material.dart';

class EnhancedPinWidget extends StatelessWidget {
  final Color color;
  final String label;
  final String number;
  final bool showLabel;
  final double size;

  const EnhancedPinWidget({
    super.key,
    required this.color,
    required this.label,
    this.number = '',
    this.showLabel =true,
    this.size = 25,
  });

  @override
  Widget build(BuildContext context) {
    final double stemHeight = size * 0.5; // طول الخط السفلي (الذيل)
    final double totalHeight = size + stemHeight + (showLabel ? 25 : 0);

    return SizedBox(
      width: size + 20,
      height: totalHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // الذيل (الخط العمودي تحت الدائرة)
          Positioned(
            bottom: 0,
            child: Container(
              width: 3,
              height: stemHeight,
              decoration: BoxDecoration(
                color: color.withOpacity(0.9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // الدائرة
          Positioned(
            bottom: stemHeight - 2, // فوق الذيل قليلًا
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          // الليبل فوق الكل
          if (showLabel)
            Positioned(
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';

// class EnhancedPinWidget extends StatelessWidget {
//   final Color color;
//   final String label;
//   final String number;
//   final bool showLabel;
//   final double size; // هذا هو حجم الدائرة الأساسي للدبوس

//   const EnhancedPinWidget({
//     super.key,
//     required this.color,
//     required this.label,
//     this.number = '',
//     this.showLabel = false,
//     this.size = 40, // حجم افتراضي جيد
//   });

//   @override
//   Widget build(BuildContext context) {
//     // احسب ارتفاعات المكونات لتحديد الارتفاع الكلي للـ Stack
//     final double labelHeight = showLabel ? 25.0 : 0.0; // ارتفاع الليبل
//     final double labelVerticalPadding = showLabel ? 5.0 : 0.0; // هامش الليبل
//     final double stemHeight = size * 0.3; // طول الجزء السفلي للدبوس (الذيل)
//     final double totalHeight = size + stemHeight + labelHeight + labelVerticalPadding + 5; // +5 هامش إضافي

//     return SizedBox(
//       width: size + 20, // عرض الدبوس مع مساحة إضافية لليبل
//       height: totalHeight,
//       child: Stack(
//         alignment: Alignment.bottomCenter,
//         children: [
//           // الليبل (النص العلوي)
//           if (showLabel)
//             Positioned(
//               bottom: size + stemHeight + labelVerticalPadding, // رفع الليبل فوق الدائرة والذيل
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                 decoration: BoxDecoration(
//                   color: color,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.white, width: 1), // حدود بيضاء لتمييز الليبل
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.2),
//                       blurRadius: 4,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Text(
//                   label,
//                   maxLines: 1,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           // الدائرة الرئيسية (جسم الدبوس)
//           Positioned(
//             bottom: stemHeight, // فوق ذيل الدبوس
//             child: Container(
//               width: size,
//               height: size,
//               decoration: BoxDecoration(
//                 color: color,
//                 shape: BoxShape.circle,
//                 border: Border.all(color: Colors.white, width: 2),
//                 boxShadow: [
//                   BoxShadow(
//                     color: color.withOpacity(0.3),
//                     blurRadius: 6,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Center(
//                 child: Text(
//                   number.isNotEmpty ? number : '', // تأكد من عرض الرقم فقط إذا كان موجودًا
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: size * 0.4,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           // ذيل الدبوس (الجزء السفلي)
//           Positioned(
//             bottom: 0,
//             child: Container(
//               width: 4, // زيادة عرض الذيل قليلاً
//               height: stemHeight,
//               decoration: BoxDecoration(
//                 color: color,
//                 borderRadius: const BorderRadius.only(
//                   bottomLeft: Radius.circular(2), // زيادة BorderRadius
//                   bottomRight: Radius.circular(2),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: color.withOpacity(0.3),
//                     blurRadius: 3,
//                     offset: const Offset(0, 1),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

 