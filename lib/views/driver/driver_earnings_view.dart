import 'package:flutter/material.dart';

class DriverEarningsView extends StatelessWidget {
  const DriverEarningsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أرباح السائق'), centerTitle: true),
      body: const Center(child: Text('أرباح السائق (قريباً)')),
    );
  }
}
