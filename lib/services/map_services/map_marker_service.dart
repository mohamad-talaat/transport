import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/views/rider/rider_widgets/pin_color.dart';
import 'package:transport_app/views/rider/rider_widgets/pin_painter.dart';

/// أنواع الـ Markers
enum MarkerType {
  riderLocationCircle,
  driverCar,
  pickup,
  destination,
  additionalStop,
}

/// 🎯 خدمة موحّدة لإدارة جميع الـ Markers على الخريطة - محسّنة للـ Release Mode
class MapMarkerService extends GetxService {
  static MapMarkerService get to => Get.find();

  /// ✅ دالة موحّدة لإنشاء/تحديث أي Marker - مضمونة 100% في Debug & Release
  static Marker createMarker({
    required MarkerType type,
    required LatLng location,
    String? id,
    String? label,
    String? number,
    Color? color,
    double bearing = 0.0,
    VoidCallback? onTap,
  }) {
    try {
      final markerKey = ValueKey('${type.name}_${id ?? location.hashCode}');

      return Marker(
        key: markerKey,
        point: location,
        width: _getMarkerWidth(type),
        height: _getMarkerHeight(type),
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: onTap,
          child: _buildMarkerWidget(
            type: type,
            label: label,
            number: number,
            color: color,
            bearing: bearing,
          ),
        ),
      );
    } catch (e) {
      logger.e('❌ Error creating marker: $e');
      // Fallback: إرجاع ماركر بسيط
      return Marker(
        key: ValueKey('fallback_${type.name}_${location.hashCode}'),
        point: location,
        width: 30,
        height: 30,
        child: Icon(Icons.location_on, color: Colors.red, size: 30),
      );
    }
  }

  /// 🎨 بناء الـ widget للماركر بشكل آمن ومحسّن
  static Widget _buildMarkerWidget({
    required MarkerType type,
    String? label,
    String? number,
    Color? color,
    double bearing = 0.0,
  }) {
    try {
      switch (type) {
        case MarkerType.riderLocationCircle:
          return _buildRiderLocationWidget();

        case MarkerType.driverCar:
          return _buildDriverCarWidget(bearing);

        case MarkerType.pickup:
        case MarkerType.destination:
        case MarkerType.additionalStop:
          return _buildPinWidget(
            label: label ?? '',
            number: number ?? '',
            color: color ?? PinColors.getColorForStep(type.name),
          );
      }
    } catch (e) {
      logger.e('❌ Error building marker widget: $e');
      // Fallback widget
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.error, color: Colors.white, size: 20),
      );
    }
  }

  /// 🔵 بناء ماركر موقع الراكب (الدائرة الزرقاء)
  static Widget _buildRiderLocationWidget() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(seconds: 1),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.shade900, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 3,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        );
      },
      onEnd: () {},
    );
  }

  /// 🚗 بناء ماركر السيارة مع الدوران
  static Widget _buildDriverCarWidget(double bearing) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        key: ValueKey('car_rotation_$bearing'),
        tween: Tween(begin: bearing, end: bearing),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        builder: (context, angle, child) {
          return Transform.rotate(
            angle: angle * (math.pi / 180),
            child: Image.asset( 
              'assets/images/car.png',
              // height: 30,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                logger.e('❌ Error loading car image: $error');
                return Icon(Icons.directions_car,
                    color: Colors.blue, size: 25);
              },
            ),
          );
        },
      ),
    );
  }

  /// 📍 بناء ماركر Pin (نقاط الانطلاق/الوصول/التوقف)
  static Widget _buildPinWidget({
    required String label,
    required String number,
    required Color color,
  }) {
    return RepaintBoundary(
      child: EnhancedPinWidget(
        label: label,
        number: number,
        color: color,
        showLabel: true,
        size: 30,
      ),
    );
  }

  /// 📏 الحصول على عرض الماركر
  static double _getMarkerWidth(MarkerType type) {
    switch (type) {
      case MarkerType.riderLocationCircle:
        return 15;
      case MarkerType.driverCar:
        return 35; // زيادة الحجم قليلاً للوضوح
      case MarkerType.pickup:
      case MarkerType.destination:
      case MarkerType.additionalStop:
        return 70;
    }
  }

  /// 📏 الحصول على ارتفاع الماركر
  static double _getMarkerHeight(MarkerType type) {
    return _getMarkerWidth(type);
  }

  /// 🧭 حساب اتجاه السيارة (Bearing) من الحركة
  static double calculateBearingFromMovement(
    LatLng previousLocation,
    LatLng currentLocation,
  ) {
    try {
      final lat1 = previousLocation.latitude * (math.pi / 180);
      final lat2 = currentLocation.latitude * (math.pi / 180);
      final dLng = (currentLocation.longitude - previousLocation.longitude) *
          (math.pi / 180);

      final y = math.sin(dLng) * math.cos(lat2);
      final x = math.cos(lat1) * math.sin(lat2) -
          math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

      final bearing = math.atan2(y, x) * (180 / math.pi);
      return (bearing + 360) % 360;
    } catch (e) {
      logger.e('❌ Error calculating bearing: $e');
      return 0.0;
    }
  }

  /// 📏 حساب المسافة بين نقطتين (بالمتر)
  static double calculateDistance(LatLng p1, LatLng p2) {
    try {
      const double R = 6371e3; // metres
      final double phi1 = p1.latitude * math.pi / 180;
      final double phi2 = p2.latitude * math.pi / 180;
      final double deltaPhi = (p2.latitude - p1.latitude) * math.pi / 180;
      final double deltaLambda = (p2.longitude - p1.longitude) * math.pi / 180;

      final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
          math.cos(phi1) *
              math.cos(phi2) *
              math.sin(deltaLambda / 2) *
              math.sin(deltaLambda / 2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

      return R * c; // in metres
    } catch (e) {
      logger.e('❌ Error calculating distance: $e');
      return 0.0;
    }
  }

  /// 🔥 تحديث ماركر في القائمة بشكل atomic ومضمون
  static void updateMarkerInList(
    RxList<Marker> markers,
    Marker newMarker,
  ) {
    try {
      final keyToFind = newMarker.key;

      // 🔥 Step 1: احذف كل الماركرز بنفس الـ key
      final Map<dynamic, Marker> uniqueMarkers = {};

      for (final marker in markers) {
        if (marker.key != keyToFind) {
          uniqueMarkers[marker.key] = marker;
        }
      }

      // 🔥 Step 2: ضيف الماركر الجديد
      uniqueMarkers[keyToFind] = newMarker;

      // 🔥 Step 3: امسح القائمة القديمة وحط الجديدة
      markers.clear();
      markers.addAll(uniqueMarkers.values);
      markers.refresh();

      logger.d('✅ Marker updated successfully');
    } catch (e) {
      logger.e('❌ Error updating marker: $e');
    }
  }

  /// 🗑️ حذف ماركر من القائمة بشكل ذكي
  static void removeMarkerFromList(
    RxList<Marker> markers,
    String markerId,
  ) {
    try {
      final int beforeCount = markers.length;

      markers.removeWhere((m) {
        if (m.key is ValueKey) {
          final keyValue = (m.key as ValueKey).value.toString();
          final shouldRemove = keyValue.contains(markerId);
          if (shouldRemove) {
            logger.d('🗑️ حذف Marker: $keyValue (مطابق لـ: $markerId)');
          }
          return shouldRemove;
        }
        return false;
      });

      final int afterCount = markers.length;
      final int removed = beforeCount - afterCount;
      logger.d(
          '✅ removeMarkerFromList - ID: $markerId | قبل: $beforeCount | بعد: $afterCount | تم حذف: $removed');

      markers.refresh();
    } catch (e) {
      logger.e('❌ Error removing marker: $e');
    }
  }

  /// 🧹 مسح جميع الماركرز
  static void clearAllMarkers(RxList<Marker> markers) {
    try {
      markers.clear();
      markers.refresh();
      logger.i('✅ All markers cleared');
    } catch (e) {
      logger.e('❌ Error clearing markers: $e');
    }
  }
}
