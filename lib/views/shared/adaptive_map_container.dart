import 'package:flutter/material.dart';

/// 🎯 Widget ذكي لإدارة حجم الخريطة ديناميكيًا
/// يتكيف تلقائيًا مع وجود محتوى سفلي (طلبات/رحلات)
class AdaptiveMapContainer extends StatelessWidget {
  final Widget mapWidget;
  final Widget? bottomContent;
  final bool hasContent;
  final double? minMapHeightFraction;
  final Duration animationDuration;

  const AdaptiveMapContainer({
    super.key,
    required this.mapWidget,
    this.bottomContent,
    this.hasContent = false,
    this.minMapHeightFraction = 0.60,
    this.animationDuration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = hasContent 
        ? screenHeight * minMapHeightFraction! 
        : screenHeight;

    return Stack(
      children: [
        AnimatedPositioned(
          duration: animationDuration,
          curve: Curves.easeInOutCubic,
          top: 0,
          left: 0,
          right: 0,
          height: mapHeight,
          child: mapWidget,
        ),
        if (hasContent && bottomContent != null)
          AnimatedPositioned(
            duration: animationDuration,
            curve: Curves.easeInOutCubic,
            top: mapHeight - 20,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: bottomContent,
            ),
          ),
      ],
    );
  }
}

/// 🎯 Extension لحساب bounds مع padding ديناميكي
extension MapBoundsHelper on BuildContext {
  EdgeInsets getSmartMapPadding({
    required bool hasBottomContent,
    double bottomContentFraction = 0.40,
  }) {
    final size = MediaQuery.of(this).size;
    final isPortrait = size.height > size.width;
    
    double bottomPadding;
    if (hasBottomContent) {
      bottomPadding = size.height * bottomContentFraction + 20;
    } else {
      bottomPadding = size.height * 0.08;
    }

    return EdgeInsets.only(
      left: size.width * 0.08,
      right: size.width * 0.08,
      top: size.height * (isPortrait ? 0.10 : 0.08),
      bottom: bottomPadding,
    );
  }
}
