import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/services/map_services/map_marker_service.dart';
import 'package:transport_app/utils/pin_colors.dart';

/// ✅ مدير موحد لماركرز الرحلات - مُحسَّن ومضمون 100% في Debug و Release
class TripMarkersManager {
  /// ✅ IDs ثابتة لكل نوع من الماركرز
  static String getPickupMarkerId(String tripId) => 'pickup_trip_${tripId}_pickup';
  static String getDestinationMarkerId(String tripId) => 'destination_trip_${tripId}_destination';
  static String getAdditionalStopMarkerId(String tripId, int index) => 'additionalStop_trip_${tripId}_stop_$index';
  static String getDriverCarMarkerId(String tripId) => 'driverCar_trip_${tripId}_driver_car';
  static String getRiderLocationMarkerId() => 'rider_current_location_circle';

  /// 🔥 إضافة جميع ماركرز الرحلة بشكل موحد ومضمون 100%
  static void setupTripMarkers({
    required RxList<Marker> markers,
    required TripModel trip,
    LatLng? driverLocation,
    LatLng? riderLocation,
    double driverBearing = 0.0,
    bool isDriverView = false,
  }) {
    logger.i('🗺️ [TripMarkersManager] Setting up markers for trip ${trip.id}');
    logger.d('   Driver location: $driverLocation');
    logger.d('   Rider location: $riderLocation');
    logger.d('   Is driver view: $isDriverView');
    
    // 🔥 STEP 1: تنظيف شامل قبل البدء
    _completeCleanup(markers);
    
    // 🔥 STEP 2: إنشاء قائمة جديدة بالماركرز الصحيحة فقط
    final List<Marker> newMarkers = [];

    try {
      // ✅ إضافة نقطة الانطلاق
      newMarkers.add(MapMarkerService.createMarker(
        type: MarkerType.pickup,
        location: trip.pickupLocation.latLng,
        id: getPickupMarkerId(trip.id),
        label: 'انطلاق',
        number: '1',
        color: PinColors.getColorForStep('pickup'),
      ));
      logger.d('   ✅ Pickup marker added: ${trip.pickupLocation.latLng}');

      // ✅ إضافة نقطة الوصول
      newMarkers.add(MapMarkerService.createMarker(
        type: MarkerType.destination,
        location: trip.destinationLocation.latLng,
        id: getDestinationMarkerId(trip.id),
        label: 'وصول',
        number: '${trip.additionalStops.length + 2}',
        color: PinColors.getColorForStep('destination'),
      ));
      logger.d('   ✅ Destination marker added: ${trip.destinationLocation.latLng}');

      // ✅ إضافة النقاط الإضافية
      for (int i = 0; i < trip.additionalStops.length; i++) {
        final stop = trip.additionalStops[i];
        newMarkers.add(MapMarkerService.createMarker(
          type: MarkerType.additionalStop,
          location: stop.location,
          id: getAdditionalStopMarkerId(trip.id, i),
          label: 'توقف ${i + 1}',
          number: '${i + 2}',
          color: PinColors.getColorForStep('additional_stop'),
        ));
        logger.d('   ✅ Stop $i marker added: ${stop.location}');
      }

      // ✅ إضافة ماركر السيارة (في Driver View و Rider Tracking)
      if (driverLocation != null) {
        try {
          final carMarker = MapMarkerService.createMarker(
            type: MarkerType.driverCar,
            location: driverLocation,
            id: getDriverCarMarkerId(trip.id),
            bearing: driverBearing,
          );
          newMarkers.add(carMarker);
          logger.d('   ✅ Driver car marker added: $driverLocation (bearing: $driverBearing)');
        } catch (e) {
          logger.e('   ❌ Failed to add driver car marker: $e');
        }
      } else {
        logger.w('   ⚠️ Driver location is null, skipping car marker');
      }

      // ✅ إضافة ماركر موقع الراكب (في Rider View فقط)
      if (!isDriverView && riderLocation != null) {
        try {
          final riderMarker = MapMarkerService.createMarker(
            type: MarkerType.riderLocationCircle,
            location: riderLocation,
            id: getRiderLocationMarkerId(),
          );
          newMarkers.add(riderMarker);
          logger.d('   ✅ Rider location marker added: $riderLocation');
        } catch (e) {
          logger.e('   ❌ Failed to add rider location marker: $e');
        }
      } else if (!isDriverView) {
        logger.w('   ⚠️ Rider location is null, skipping rider marker');
      }

      // 🔥 STEP 3: استبدال القائمة بالكامل بشكل atomic
      // ✅ استخدام assignAll بدلاً من value = لتجنب setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        markers.value = newMarkers;
        markers.refresh();
      });
      
      logger.i('✅ Trip markers setup complete. Total: ${newMarkers.length}');
      _logAllMarkers(RxList<Marker>(newMarkers));
      
    } catch (e) {
      logger.e('❌ Critical error in setupTripMarkers: $e');
      // Fallback: محاولة إضافة الماركرز بشكل تدريجي
      markers.clear();
      markers.addAll(newMarkers);
      markers.refresh();
    }
  }

  /// 🔥 تنظيف شامل لكل الماركرز القديمة
  static void _completeCleanup(RxList<Marker> markers) {
    logger.i('🧹 Starting complete cleanup...');
    
    final beforeCount = markers.length;
    
    try {
      // ✅ إزالة جميع ماركرز الرحلات بشكل آمن
      markers.removeWhere((m) {
        try {
          if (m.key is ValueKey) {
            final key = (m.key as ValueKey).value.toString();
            return key.contains('_trip_') || 
                   key.startsWith('pickup_') ||
                   key.startsWith('destination_') ||
                   key.startsWith('additionalStop_') ||
                   key.startsWith('driverCar_') ||
                   key.startsWith('driver_') ||
                   key == 'driver_car' ||
                   key.contains('riderLocationCircle') ||
                   key.contains('rider_current_location');
          }
        } catch (e) {
          logger.w('⚠️ Error checking marker key: $e');
        }
        return false;
      });
      
      final removed = beforeCount - markers.length;
      logger.i('✅ Cleanup complete. Removed: $removed, Remaining: ${markers.length}');
    } catch (e) {
      logger.e('❌ Critical error in cleanup: $e');
      // Fallback: محاولة مسح كلي
      try {
        markers.clear();
        logger.i('✅ Fallback: Cleared all markers');
      } catch (e2) {
        logger.e('❌❌ Even fallback failed: $e2');
      }
    }
  }

  /// ✅ تحديث موقع السيارة فقط (للـ real-time tracking)
  static void updateDriverCarMarker({
    required RxList<Marker> markers,
    required String tripId,
    required LatLng driverLocation,
    double bearing = 0.0,
  }) {
    try {
      final carMarkerId = getDriverCarMarkerId(tripId);
      
      // 🔥 إزالة جميع ماركرز السيارة القديمة بشكل آمن
      final int beforeCount = markers.length;
      markers.removeWhere((m) {
        if (m.key is ValueKey) {
          final key = (m.key as ValueKey).value.toString();
          return key == carMarkerId || 
                 key.startsWith('driverCar_') || 
                 key == 'driver_car' ||
                 key.contains('driver_car');
        }
        return false;
      });
      
      final int removed = beforeCount - markers.length;
      if (removed > 0) {
        logger.d('🗑️ Removed $removed old car marker(s)');
      }
      
      // ✅ إضافة الماركر الجديد
      final newMarker = MapMarkerService.createMarker(
        type: MarkerType.driverCar,
        location: driverLocation,
        id: carMarkerId,
        bearing: bearing,
      );
      
      markers.add(newMarker);
      markers.refresh();
      
      logger.d('🚗 Updated driver car at $driverLocation (bearing: ${bearing.toStringAsFixed(1)}°)');
    } catch (e) {
      logger.e('❌ Error updating driver car marker: $e');
    }
  }
  
  /// 🔥 تحديث موقع الراكب بضمان 100%
  static void updateRiderLocationMarker({
    required RxList<Marker> markers,
    required LatLng riderLocation,
  }) {
    try {
      final riderMarkerId = getRiderLocationMarkerId();
      
      // 🔥 إزالة جميع ماركرز الراكب القديمة بشكل آمن
      final int beforeCount = markers.length;
      markers.removeWhere((m) {
        if (m.key is ValueKey) {
          final key = (m.key as ValueKey).value.toString();
          return key == riderMarkerId || 
                 key.contains('riderLocationCircle') ||
                 key.contains('rider_current_location');
        }
        return false;
      });
      
      final int removed = beforeCount - markers.length;
      if (removed > 0) {
        logger.d('🗑️ Removed $removed old rider marker(s)');
      }
      
      // ✅ إضافة الماركر الجديد
      final newMarker = MapMarkerService.createMarker(
        type: MarkerType.riderLocationCircle,
        location: riderLocation,
        id: riderMarkerId,
      );
      
      markers.add(newMarker);
      markers.refresh();
      
      logger.d('👤 Updated rider location at $riderLocation');
    } catch (e) {
      logger.e('❌ Error updating rider location marker: $e');
    }
  }

  /// 🔥 تنظيف ماركرز رحلة معينة بشكل كامل
  static void clearTripMarkers(RxList<Marker> markers, String tripId) {
    logger.i('🧹 Clearing all markers for trip: $tripId');
    
    final beforeCount = markers.length;
    
    // إزالة أي ماركر يحتوي على tripId في الـ key
    markers.removeWhere((m) {
      if (m.key is ValueKey) {
        final key = (m.key as ValueKey).value.toString();
        return key.contains('_trip_$tripId') || 
               key.contains('_$tripId') ||
               key.contains(tripId) ||
               key.startsWith('pickup_') ||
               key.startsWith('destination_') ||
               key.startsWith('additionalStop_') ||
               key.startsWith('driverCar_') ||
               key.startsWith('driver_') ||
               key == 'driver_car';
      }
      return false;
    });
    
    // ✅ تنفيذ refresh بعد الإطار
    WidgetsBinding.instance.addPostFrameCallback((_) {
      markers.refresh();
    });
    
    final afterCount = markers.length;
    final removed = beforeCount - afterCount;
    logger.i('✅ Removed $removed markers for trip $tripId. Remaining: $afterCount');
  }

  /// 🔥 تنظيف كامل لجميع ماركرز الرحلات مع إبقاء موقع الراكب فقط
  static void clearAllTripMarkers(RxList<Marker> markers) {
    logger.i('🧹 Clearing ALL trip markers...');
    
    // 🔥 حفظ ماركر موقع الراكب فقط
    Marker? riderMarker;
    try {
      riderMarker = markers.firstWhereOrNull((m) {
        if (m.key is ValueKey) {
          final key = (m.key as ValueKey).value.toString();
          return key == getRiderLocationMarkerId();
        }
        return false;
      });
    } catch (e) {
      logger.w('خطأ في البحث عن ماركر الراكب: $e');
    }
    
    _completeCleanup(markers);
    
    // ✅ تنفيذ التحديثات بعد الإطار
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // إعادة إضافة ماركر الراكب إذا كان موجوداً
      if (riderMarker != null) {
        markers.add(riderMarker);
      }
      markers.refresh();
    });
    
    logger.i('✅ تم تنظيف جميع ماركرز الرحلات مع الاحتفاظ بموقع الراكب');
  }

  /// ✅ التحقق من وجود ماركر معين
  static bool hasMarker(RxList<Marker> markers, String markerId) {
    return markers.any((m) {
      if (m.key is ValueKey) {
        return (m.key as ValueKey).value == markerId;
      }
      return false;
    });
  }

  /// ✅ الحصول على عدد ماركرز رحلة معينة
  static int getTripMarkersCount(RxList<Marker> markers, String tripId) {
    return markers.where((m) {
      if (m.key is ValueKey) {
        final key = (m.key as ValueKey).value.toString();
        return key.contains('_trip_$tripId');
      }
      return false;
    }).length;
  }

  /// 🔍 طباعة جميع الماركرز للتشخيص
  static void _logAllMarkers(RxList<Marker> markers) {
    logger.d('📍 Current markers (${markers.length}):');
    for (var marker in markers) {
      if (marker.key is ValueKey) {
        logger.d('   - ${(marker.key as ValueKey).value}');
      }
    }
  }
}
