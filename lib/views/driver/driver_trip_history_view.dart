import 'package:flutter/material.dart';

class DriverTripHistoryView extends StatelessWidget {
  const DriverTripHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('تاريخ رحلات السائق'), centerTitle: true),
      body: const Center(child: Text('تاريخ الرحلات (قريباً)')),
    );
  }
}
