import 'package:flutter/material.dart';

class PinColors {
  static const String pickup = 'pickup';
  static const String destination = 'destination';
  static const String additionalStop = 'additional_stop';

  static Color getColorForStep(String step) {
    switch (step) {
      case pickup:
        return Colors.black;
      case destination:
        return Colors.red;
      case additionalStop:
        return const Color.fromARGB(235, 237, 158, 23);
      default:
        return Colors.grey;
    }
  }

  static String getLabelForStep(String step) {
    switch (step) {
      case pickup:
        return 'انطلاق';
      case destination:
      case additionalStop:
        return 'وصول';
      default:
        return 'الموقع';
    }
  }

  static int getNumberForStep(String step, {int stopIndex = 0}) {
    switch (step) {
      case pickup:
        return 1;
      case destination:
        return 2;
      case additionalStop:
        return 3 + stopIndex;
      default:
        return 0;
    }
  }
}
