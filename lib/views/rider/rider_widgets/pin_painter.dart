import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Modern Enhanced Pin Painter with Uber/Careem-style design
class EnhancedPinPainter extends CustomPainter {
  final Color color;
  final String label;
  final bool isMoving;
  final bool showLabel;
  final double zoomLevel;

  EnhancedPinPainter({
    required this.color,
    required this.label,
    this.isMoving = false,
    this.showLabel = false,
    required this.zoomLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleFactor = _calculateScaleFactor(zoomLevel);

    // Modern gradient for the pin
    final Paint pinPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color,
          color.withOpacity(0.8),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 3),
        radius: size.width * 0.2 * scaleFactor,
      ));

    // Enhanced shadow with multiple layers
    final Paint shadowPaint1 = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * scaleFactor);

    final Paint shadowPaint2 = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * scaleFactor);

    final double pinRadius = size.width * 0.18 * scaleFactor;
    final Offset pinCenter =
        Offset(size.width / 2, pinRadius + (4 * scaleFactor));

    // Draw layered shadows
    canvas.drawCircle(
        Offset(pinCenter.dx + 2 * scaleFactor, pinCenter.dy + 3 * scaleFactor),
        pinRadius,
        shadowPaint2);
    canvas.drawCircle(
        Offset(pinCenter.dx + 1 * scaleFactor, pinCenter.dy + 2 * scaleFactor),
        pinRadius,
        shadowPaint1);

    // Draw main pin circle
    canvas.drawCircle(pinCenter, pinRadius, pinPaint);

    // Modern pin tip (teardrop shape)
    final Path pinTipPath = Path();
    final double tipHeight = size.height - pinCenter.dy - pinRadius;
    final double tipWidth = pinRadius * 0.7;

    pinTipPath.moveTo(size.width / 2, size.height - (2 * scaleFactor));
    pinTipPath.quadraticBezierTo(
      pinCenter.dx - tipWidth / 2,
      pinCenter.dy + pinRadius - (2 * scaleFactor),
      pinCenter.dx - tipWidth / 3,
      pinCenter.dy + pinRadius * 0.7,
    );
    pinTipPath.quadraticBezierTo(
      pinCenter.dx + tipWidth / 3,
      pinCenter.dy + pinRadius * 0.7,
      pinCenter.dx + tipWidth / 2,
      pinCenter.dy + pinRadius - (2 * scaleFactor),
    );
    pinTipPath.quadraticBezierTo(
      size.width / 2,
      size.height - (2 * scaleFactor),
      size.width / 2,
      size.height - (2 * scaleFactor),
    );
    pinTipPath.close();

    // Shadow for tip
    final Path tipShadowPath = Path();
    tipShadowPath.addPath(pinTipPath, Offset(1 * scaleFactor, 2 * scaleFactor));
    canvas.drawPath(tipShadowPath, shadowPaint1);

    canvas.drawPath(pinTipPath, pinPaint);

    // Modern white border with subtle thickness
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scaleFactor;

    canvas.drawCircle(pinCenter, pinRadius, borderPaint);
    canvas.drawPath(pinTipPath, borderPaint);

    // Inner modern icon (instead of just a dot)
    _drawInnerIcon(canvas, pinCenter, pinRadius * 0.5, scaleFactor);

    // Draw label if needed
    if (showLabel && label.isNotEmpty) {
      _drawModernLabel(canvas, size, pinCenter, pinRadius, scaleFactor);
    }
  }

  void _drawInnerIcon(
      Canvas canvas, Offset center, double iconRadius, double scaleFactor) {
    final Paint iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw a modern location dot with ring
    canvas.drawCircle(center, iconRadius * 0.4, iconPaint);

    final Paint ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scaleFactor;

    canvas.drawCircle(center, iconRadius * 0.7, ringPaint);
  }

  double _calculateScaleFactor(double zoom) {
    const double baseZoom = 13.0;
    const double scaleRate = 0.025; // Slightly more responsive
    double factor = 1.0 + ((zoom - baseZoom) * scaleRate);
    return factor.clamp(0.85, 1.15);
  }

  void _drawModernLabel(Canvas canvas, Size size, Offset pinCenter,
      double pinRadius, double scaleFactor) {
    final TextSpan textSpan = TextSpan(
      text: label,
      style: TextStyle(
        color: Colors.white,
        fontSize: 10 * scaleFactor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.7),
            offset: Offset(0.5 * scaleFactor, 0.5 * scaleFactor),
            blurRadius: 2 * scaleFactor,
          ),
        ],
      ),
    );

    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    );

    textPainter.layout(maxWidth: size.width * 1.8);

    final double labelPadding = 6 * scaleFactor;
    final double labelWidth = textPainter.width + (labelPadding * 2);
    final double labelHeight = textPainter.height + (labelPadding * 1.2);

    final RRect labelBackground = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          pinCenter.dx,
          pinCenter.dy - pinRadius - (labelHeight / 2) - (4 * scaleFactor),
        ),
        width: labelWidth,
        height: labelHeight,
      ),
      Radius.circular(8 * scaleFactor),
    );

    // Modern gradient background for label
    final Paint labelPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.95),
          color.withOpacity(0.85),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(labelBackground.outerRect);

    final Paint labelBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scaleFactor;

    // Draw label with subtle shadow
    final RRect shadowLabel = RRect.fromRectAndRadius(
      labelBackground.outerRect.shift(Offset(1 * scaleFactor, 2 * scaleFactor)),
      Radius.circular(8 * scaleFactor),
    );

    canvas.drawRRect(
        shadowLabel,
        Paint()
          ..color = Colors.black.withOpacity(0.1)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * scaleFactor));

    canvas.drawRRect(labelBackground, labelPaint);
    canvas.drawRRect(labelBackground, labelBorderPaint);

    textPainter.paint(
      canvas,
      Offset(
        pinCenter.dx - textPainter.width / 2,
        pinCenter.dy -
            pinRadius -
            (labelHeight / 2) -
            (4 * scaleFactor) +
            (labelPadding * 0.6),
      ),
    );
  }

  @override
  bool shouldRepaint(EnhancedPinPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.label != label ||
        oldDelegate.isMoving != isMoving ||
        oldDelegate.showLabel != showLabel ||
        oldDelegate.zoomLevel != zoomLevel;
  }
}

/// Modern Numbered Pin Painter for additional stops with enhanced design
class NumberedPinPainter extends CustomPainter {
  final Color color;
  final String label;
  final int number;
  final bool showLabel;
  final double zoomLevel;

  NumberedPinPainter({
    required this.color,
    required this.label,
    required this.number,
    this.showLabel = false,
    required this.zoomLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleFactor = _calculateScaleFactor(zoomLevel);

    // Modern gradient for the pin
    final Paint pinPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.9),
          color,
          color.withOpacity(0.8),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 3),
        radius: size.width * 0.2 * scaleFactor,
      ));

    // Enhanced layered shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scaleFactor);

    final double pinRadius = size.width * 0.18 * scaleFactor;
    final Offset pinCenter =
        Offset(size.width / 2, pinRadius + (4 * scaleFactor));

    // Draw shadow
    canvas.drawCircle(
        Offset(pinCenter.dx + 2 * scaleFactor, pinCenter.dy + 3 * scaleFactor),
        pinRadius,
        shadowPaint);

    // Draw main pin circle
    canvas.drawCircle(pinCenter, pinRadius, pinPaint);

    // Modern pin tip
    final Path pinTipPath = Path();
    final double tipWidth = pinRadius * 0.7;

    pinTipPath.moveTo(size.width / 2, size.height - (2 * scaleFactor));
    pinTipPath.quadraticBezierTo(
      pinCenter.dx - tipWidth / 2,
      pinCenter.dy + pinRadius - (2 * scaleFactor),
      pinCenter.dx - tipWidth / 3,
      pinCenter.dy + pinRadius * 0.7,
    );
    pinTipPath.quadraticBezierTo(
      pinCenter.dx + tipWidth / 3,
      pinCenter.dy + pinRadius * 0.7,
      pinCenter.dx + tipWidth / 2,
      pinCenter.dy + pinRadius - (2 * scaleFactor),
    );
    pinTipPath.close();

    canvas.drawPath(pinTipPath, pinPaint);

    // Modern white border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scaleFactor;

    canvas.drawCircle(pinCenter, pinRadius, borderPaint);
    canvas.drawPath(pinTipPath, borderPaint);

    // Draw number with modern styling
    _drawModernNumber(canvas, pinCenter, pinRadius, scaleFactor);

    // Draw label if needed
    if (showLabel && label.isNotEmpty) {
      _drawModernLabel(canvas, size, pinCenter, pinRadius, scaleFactor);
    }
  }

  void _drawModernNumber(
      Canvas canvas, Offset center, double radius, double scaleFactor) {
    // Background circle for number
    final Paint numberBgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.65, numberBgPaint);

    // Number text with enhanced styling
    final TextSpan numberSpan = TextSpan(
      text: number.toString(),
      style: TextStyle(
        color: color,
        fontSize: 14 * scaleFactor,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        shadows: [
          Shadow(
            color: color.withOpacity(0.2),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );

    final TextPainter numberPainter = TextPainter(
      text: numberSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    numberPainter.layout();
    numberPainter.paint(
      canvas,
      Offset(
        center.dx - numberPainter.width / 2,
        center.dy - numberPainter.height / 2,
      ),
    );
  }

  double _calculateScaleFactor(double zoom) {
    const double baseZoom = 13.0;
    const double scaleRate = 0.025;
    double factor = 1.0 + ((zoom - baseZoom) * scaleRate);
    return factor.clamp(0.85, 1.15);
  }

  void _drawModernLabel(Canvas canvas, Size size, Offset pinCenter,
      double pinRadius, double scaleFactor) {
    final TextSpan textSpan = TextSpan(
      text: label,
      style: TextStyle(
        color: Colors.white,
        fontSize: 10 * scaleFactor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.7),
            offset: Offset(0.5 * scaleFactor, 0.5 * scaleFactor),
            blurRadius: 2 * scaleFactor,
          ),
        ],
      ),
    );

    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    );

    textPainter.layout(maxWidth: size.width * 1.8);

    final double labelPadding = 6 * scaleFactor;
    final double labelWidth = textPainter.width + (labelPadding * 2);
    final double labelHeight = textPainter.height + (labelPadding * 1.2);

    final RRect labelBackground = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          pinCenter.dx,
          pinCenter.dy - pinRadius - (labelHeight / 2) - (4 * scaleFactor),
        ),
        width: labelWidth,
        height: labelHeight,
      ),
      Radius.circular(8 * scaleFactor),
    );

    final Paint labelPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.95),
          color.withOpacity(0.85),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(labelBackground.outerRect);

    final Paint labelBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scaleFactor;

    canvas.drawRRect(labelBackground, labelPaint);
    canvas.drawRRect(labelBackground, labelBorderPaint);

    textPainter.paint(
      canvas,
      Offset(
        pinCenter.dx - textPainter.width / 2,
        pinCenter.dy -
            pinRadius -
            (labelHeight / 2) -
            (4 * scaleFactor) +
            (labelPadding * 0.6),
      ),
    );
  }

  @override
  bool shouldRepaint(NumberedPinPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.label != label ||
        oldDelegate.number != number ||
        oldDelegate.showLabel != showLabel ||
        oldDelegate.zoomLevel != zoomLevel;
  }
}

/// Modern Enhanced Pin Widget with improved animation lifecycle
class EnhancedPinWidget extends StatefulWidget {
  final Color color;
  final String label;
  final bool isMoving;
  final bool showLabel;
  final double size;
  final double zoomLevel;

  const EnhancedPinWidget({
    super.key,
    required this.color,
    required this.label,
    this.isMoving = false,
    this.showLabel = false,
    this.size = 38,
    required this.zoomLevel,
  });

  @override
  State<EnhancedPinWidget> createState() => _EnhancedPinWidgetState();
}

class _EnhancedPinWidgetState extends State<EnhancedPinWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _translateAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -0.2),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _updateAnimation();
  }

  @override
  void didUpdateWidget(EnhancedPinWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMoving != widget.isMoving) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (!mounted) return;

    try {
      if (widget.isMoving) {
        if (_animationController.status != AnimationStatus.forward &&
            _animationController.status != AnimationStatus.completed) {
          _animationController.forward();
        }
      } else {
        if (_animationController.status != AnimationStatus.reverse &&
            _animationController.status != AnimationStatus.dismissed) {
          _animationController.reverse();
        }
      }
    } catch (e) {
      // Ignore animation errors if controller is disposed
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double dynamicSize = _calculateDynamicSize();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: Offset(
              0,
              _translateAnimation.value.dy * dynamicSize,
            ),
            child: Container(
              width: dynamicSize,
              height: dynamicSize * 1.3,
              child: CustomPaint(
                painter: EnhancedPinPainter(
                  color: widget.color,
                  label: widget.label,
                  isMoving: widget.isMoving,
                  showLabel: widget.showLabel,
                  zoomLevel: widget.zoomLevel,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateDynamicSize() {
    const double baseZoom = 13.0;
    const double sizeRate = 0.025;
    double sizeFactor = 1.0 + ((widget.zoomLevel - baseZoom) * sizeRate);
    sizeFactor = sizeFactor.clamp(0.85, 1.15);
    return widget.size * sizeFactor;
  }
}

/// Modern Numbered Pin Widget
class NumberedPinWidget extends StatefulWidget {
  final Color color;
  final String label;
  final int number;
  final bool showLabel;
  final double size;
  final double zoomLevel;

  const NumberedPinWidget({
    super.key,
    required this.color,
    required this.label,
    required this.number,
    this.showLabel = false,
    this.size = 38,
    required this.zoomLevel,
  });

  @override
  State<NumberedPinWidget> createState() => _NumberedPinWidgetState();
}

class _NumberedPinWidgetState extends State<NumberedPinWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double dynamicSize = _calculateDynamicSize();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: dynamicSize,
            height: dynamicSize * 1.3,
            child: CustomPaint(
              painter: NumberedPinPainter(
                color: widget.color,
                label: widget.label,
                number: widget.number,
                showLabel: widget.showLabel,
                zoomLevel: widget.zoomLevel,
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateDynamicSize() {
    const double baseZoom = 13.0;
    const double sizeRate = 0.025;
    double sizeFactor = 1.0 + ((widget.zoomLevel - baseZoom) * sizeRate);
    sizeFactor = sizeFactor.clamp(0.85, 1.15);
    return widget.size * sizeFactor;
  }
}

/// Modern Pin Colors with enhanced palette
class PinColors {
  // Modern color palette inspired by Google Maps and Uber
  static const Color pickup = Color(0xFF34C759); // Modern green
  static const Color destination = Color(0xFFFF3B30); // Modern red
  static const Color additionalStop = Color(0xFFFF9500); // Modern orange
  static const Color current = Color(0xFF007AFF); // Modern blue
  static const Color driver = Color(0xFF5856D6); // Modern purple

  static Color getColorForStep(String step) {
    switch (step) {
      case 'pickup':
        return pickup;
      case 'destination':
        return destination;
      case 'additional_stop':
        return additionalStop;
      case 'driver':
        return driver;
      default:
        return current;
    }
  }

  static String getLabelForStep(String step) {
    switch (step) {
      case 'pickup':
        return 'الانطلاق';
      case 'destination':
        return 'الوصول';
      case 'additional_stop':
        return 'محطة';
      case 'driver':
        return 'السائق';
      default:
        return 'الموقع';
    }
  }

  static IconData getIconForStep(String step) {
    switch (step) {
      case 'pickup':
        return Icons.trip_origin;
      case 'destination':
        return Icons.location_on;
      case 'additional_stop':
        return Icons.add_location_alt;
      case 'driver':
        return Icons.directions_car;
      default:
        return Icons.place;
    }
  }
}
