import 'dart:async';
import 'package:flutter/material.dart';

class HoldToStartButton extends StatefulWidget {
  final VoidCallback onCompleted;
  final String idleText;
  final String holdingText;
  final Duration holdDuration;

  const HoldToStartButton({
    super.key,
    required this.onCompleted,
    this.idleText = 'ركب الزبون/بدء الرحلة',
    this.holdingText = 'استمر بالضغط',
    this.holdDuration = const Duration(seconds: 2),
  });

  @override
  State<HoldToStartButton> createState() => _HoldToStartButtonState();
}

class _HoldToStartButtonState extends State<HoldToStartButton> {
  bool _isHolding = false;
  double _holdProgress = 0.0;
  Timer? _holdTimer;

  void _startHoldTimer() {
    _holdTimer?.cancel();
    final increment = 0.05 / widget.holdDuration.inSeconds;

    _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _holdProgress += increment;
        if (_holdProgress >= 1.0) {
          _holdProgress = 1.0;
          timer.cancel();
          _isHolding = false;
          widget.onCompleted();
        }
      });
    });
  }

  void _stopHoldTimer() {
    _holdTimer?.cancel();
    if (mounted) {
      setState(() {
        _isHolding = false;
        _holdProgress = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تدرج اللون يبدأ من البرتقالي ويكمل للأحمر حسب نسبة الضغط
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: [_holdProgress, _holdProgress],
      colors: [
        Colors.orange,
        Colors.redAccent,
      ],
    );

    return GestureDetector(
      onLongPressStart: (_) {
        setState(() => _isHolding = true);
        _startHoldTimer();
      },
      onLongPressEnd: (_) => _stopHoldTimer(),
      onLongPressCancel: () => _stopHoldTimer(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: gradient, // استخدم التدرج هنا
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _isHolding ? widget.holdingText : widget.idleText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// import 'dart:async';
// import 'package:flutter/material.dart';

// class HoldToStartButton extends StatefulWidget {
//   final VoidCallback onCompleted;
//   final String idleText;
//   final String holdingText;
//   final Duration holdDuration;

//   const HoldToStartButton({
//     super.key,
//     required this.onCompleted,
//     this.idleText = 'ركب الزبون/بدء الرحلة',
//     this.holdingText = 'استمر بالضغط',
//     this.holdDuration = const Duration(seconds: 2),
//   });

//   @override
//   State<HoldToStartButton> createState() => _HoldToStartButtonState();
// }

// class _HoldToStartButtonState extends State<HoldToStartButton> {
//   bool _isHolding = false;
//   double _holdProgress = 0.0;
//   Timer? _holdTimer;

//   void _startHoldTimer() {
//     _holdTimer?.cancel();
//     final increment = 0.05 / widget.holdDuration.inSeconds;
    
//     _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }
      
//       setState(() {
//         _holdProgress += increment;
//         if (_holdProgress >= 1.0) {
//           _holdProgress = 1.0;
//           timer.cancel();
//           _isHolding = false;
//           widget.onCompleted();
//         }
//       });
//     });
//   }

//   void _stopHoldTimer() {
//     _holdTimer?.cancel();
//     if (mounted) {
//       setState(() {
//         _isHolding = false;
//         _holdProgress = 0.0;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _holdTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final remainingSeconds = ((1 - _holdProgress) * widget.holdDuration.inSeconds).clamp(0.0, widget.holdDuration.inSeconds.toDouble());
    
//     return GestureDetector(
//       onLongPressStart: (_) {
//         setState(() => _isHolding = true);
//         _startHoldTimer();
//       },
//       onLongPressEnd: (_) => _stopHoldTimer(),
//       onLongPressCancel: () => _stopHoldTimer(),
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(vertical: 14),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           gradient: const LinearGradient(
//             colors: [Colors.orange, Colors.redAccent],
//             begin: Alignment.centerLeft,
//             end: Alignment.centerRight,
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.touch_app, color: Colors.white),
//             const SizedBox(width: 8),
//             Text(
//               _isHolding
//                   ? '${widget.holdingText} (${remainingSeconds.toStringAsFixed(1)}s)'
//                   : widget.idleText,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
