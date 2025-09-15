import 'package:flutter/material.dart';

class BalanceAnimatedText extends StatefulWidget {
  final double balance;

  const BalanceAnimatedText({super.key, required this.balance});

  @override
  _BalanceAnimatedTextState createState() => _BalanceAnimatedTextState();
}

class _BalanceAnimatedTextState extends State<BalanceAnimatedText> {
  double oldBalance = 0.0;

  @override
  void didUpdateWidget(BalanceAnimatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // لما الرصيد يتغير نخزن القديم
    if (oldWidget.balance != widget.balance) {
      oldBalance = oldWidget.balance;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: oldBalance, end: widget.balance),
      duration: const Duration(milliseconds: 1200), // حركة أهدى
      curve: Curves.easeOutCubic, // انسيابية أجمل
      builder: (context, value, child) {
        return Text(
          '${value.toStringAsFixed(0)} د.ع',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        );
      },
    );
  }
}
