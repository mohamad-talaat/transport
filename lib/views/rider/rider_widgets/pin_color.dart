import 'package:flutter/material.dart';

class PinColors {
  static const Color pickup = Color.fromARGB(255, 0, 21, 1);
  static const Color destination = Color(0xFFE53935);
  static const Color current = Color(0xFF2196F3);
  static const Color additionalStop = Color(0xFFFF9800);
  static const Color driver = Color(0xFF9C27B0);
  static const Color selected = Color(0xFF607D8B);

  static Color getColorForStep(String step) {
    switch (step) {
      case 'pickup':
        return const Color.fromARGB(255, 2, 2, 2);
      case 'destination':
        return destination;
      case 'additional_stop':
        return additionalStop;
      case 'selected':
        return const Color.fromARGB(255, 10, 216, 75);
      default:
        return current;
    }
  }

  static String getLabelForStep(String step) {
    switch (step) {
      case 'pickup':
        return 'انطلاق';
      case 'destination':
        return 'وصول';
      case 'additional_stop':
        return ' وصول إضافي ';

      default:
        return 'الموقع الحالي';
    }
  }
}
