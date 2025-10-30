import 'package:flutter/material.dart';

class RiderAboutView extends StatelessWidget {
  const RiderAboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عن التطبيق'),
        centerTitle: true,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'تطبيق تاكسي البصرة - إصدار أولي.\nهذا القسم يحتوي على معلومات حول التطبيق وحقوق النشر.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
