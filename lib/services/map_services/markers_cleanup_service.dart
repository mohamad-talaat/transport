import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

/// ✅ خدمة متقدمة لإدارة الماركرز مع تنظيف تلقائي
class MarkersCleanupService extends GetxService {
  final RxList<Marker> markers;
  final RxString userRole = ''.obs; // 'rider' أو 'driver'
  
  // ✅ تتبع الماركرز النشطة حسب نوع الرحلة
  final RxMap<String, List<String>> activeMarkersByTrip = <String, List<String>>{}.obs;
  
  MarkersCleanupService({
    required this.markers,
  });

  /// ✅ إضافة ماركر مع تتبقي الرحلة
  void addMarker(
    Marker marker,
    String tripId,
  ) {
    // إزالة ماركر قديم بنفس المفتاح
    markers.removeWhere((m) => m.key == marker.key);
    
    // إضافة الماركر الجديد
    markers.add(marker);
    
    // تتبع الماركر حسب الرحلة
    if (!activeMarkersByTrip.containsKey(tripId)) {
      activeMarkersByTrip[tripId] = [];
    }
    activeMarkersByTrip[tripId]?.add(marker.key?.toString() ?? '');
  }

  /// ✅ إزالة جميع الماركرز المرتبطة برحلة معينة
  void clearMarkersForTrip(String tripId) {
    final markerKeysToRemove = activeMarkersByTrip[tripId] ?? [];
    
    for (final keyStr in markerKeysToRemove) {
      markers.removeWhere((m) => m.key?.toString() == keyStr);
    }
    
    // حذف سجل الرحلة
    activeMarkersByTrip.remove(tripId);
  }

  /// ✅ تنظيف شامل عند انتهاء الرحلة
  void cleanupOnTripEnd(String tripId) {
    clearMarkersForTrip(tripId);
  }

  /// ✅ إزالة ماركرز معينة (مثل السائق من الراكب بعد انتهاء الرحلة)
  void removeMarkerByKey(String markerKey) {
    markers.removeWhere((m) => m.key?.toString() == markerKey);
    
    // إزالة من السجل أيضاً
    for (final entry in activeMarkersByTrip.entries) {
      entry.value.removeWhere((key) => key == markerKey);
    }
  }

  /// ✅ تنظيف النقاط الإضافية (additional stops)
  void clearAdditionalStops(String tripId) {
    markers.removeWhere(
      (m) => m.key?.toString().contains('${tripId}_stop_') ?? false,
    );
    
    // إزالة من السجل
    if (activeMarkersByTrip.containsKey(tripId)) {
      activeMarkersByTrip[tripId]?.removeWhere(
        (key) => key.contains('stop_'),
      );
    }
  }

  /// ✅ الحصول على ماركرز رحلة معينة
  List<Marker> getMarkersForTrip(String tripId) {
    final markerKeys = activeMarkersByTrip[tripId] ?? [];
    return markers.where((m) => 
      markerKeys.contains(m.key?.toString())
    ).toList();
  }

  /// ✅ تنظيف شامل للجميع
  void clearAllMarkers() {
    markers.clear();
    activeMarkersByTrip.clear();
  }

  /// ✅ تنظيف الماركرز القديمة (كل ماركر قديم أكثر من وقت معين)
  void cleanupStaleMarkers(Duration staleDuration) {
    // يمكن إضافة timestamp للماركرز للتحقق من القدم
    // هذه دالة للتوسع المستقبلي
  }
}