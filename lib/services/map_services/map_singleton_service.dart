import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

const String apiKey = 'ZhHIu4uERobVUW4hGLuG'; // مفتاحك من MapTiler

/// 🚀 Map Service - محسّن للسرعة والاعتمادية
class MapService extends GetxService {
  static MapService get to => Get.find();

  late final FMTCStore _cacheStore;
  bool _isInitialized = false;

  /// ✅ التهيئة الأساسية
  @override
  Future<void> onInit() async {
    super.onInit();
    await _initCache();
  }
Future<void> _initCache() async {
  if (_isInitialized) return;

  try {
   await FMTCObjectBoxBackend().initialise();
   

    _cacheStore = FMTCStore('mapCache');
   await _cacheStore.manage.create();
   

    _isInitialized = true;
    debugPrint('✅ FMTC Cache initialized successfully');
  } catch (e) {
    debugPrint('❌ Cache initialization error: $e');
    _isInitialized = false;
  }
}

  // Future<void> _initCache() async {
  //   if (_isInitialized) return;
  //   try {
  //     await FMTCObjectBoxBackend().initialise();

  //     _cacheStore = FMTCStore('mapCache');
  //     // if (!await _cacheStore.manage.()) {
  //       await _cacheStore.manage.create();
  //     // }

  //     _isInitialized = true;
  //     debugPrint('✅ FMTC Cache initialized successfully');
  //   } catch (e) {
  //     debugPrint('❌ Cache initialization error: $e');
  //     _isInitialized = false;
  //   }
  // }

  /// 🌍 تحديد مصدر الخريطة النشط (MapTiler أو OSM)
  final RxString _currentSource = 'maptiler'.obs;

  void _switchToOSM() {
    _currentSource.value = 'osm';
    debugPrint('⚠️ تم التحويل إلى OSM مؤقتًا بسبب خطأ في MapTiler');
  }

  /// 🔁 بناء خريطة محسّنة مع تبديل تلقائي عند الفشل
  Widget buildOptimizedMap({
    required MapController controller,
    required LatLng initialCenter,
    required List<Marker> markers,
    List<Polyline> polylines = const [],
    List<CircleMarker> circles = const [],
    double initialZoom = 15.0,
    double minZoom = 10.0,
    double maxZoom = 18.0,
    Function(MapCamera camera, bool gesture)? onPositionChanged,
  }) {
    return Obx(() {
      final bool useMapTiler = _currentSource.value == 'maptiler';
      final String urlTemplate = useMapTiler
          ? 
          //  'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$apiKey'
           "https://tile.thunderforest.com/neighbourhood/{z}/{x}/{y}.png?apikey=27f5f1e6b61542aea7ec18faec9ee191"
          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
 

      return FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: initialZoom,
          minZoom: minZoom,
          maxZoom: maxZoom,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          onMapEvent: (event) {
            if (event is MapEventMoveEnd) {
              final camera = event.camera;
              onPositionChanged?.call(camera, true);
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: urlTemplate,
            userAgentPackageName: 'com.transport.app',
            tileProvider:
                _isInitialized ? _cacheStore.getTileProvider() : NetworkTileProvider(),
            maxZoom: 18,
            maxNativeZoom: 18,
            retinaMode: false,
            keepBuffer: 1,
            panBuffer: 0,
            errorTileCallback: (tile, error, stackTrace) {
              debugPrint('❌ Tile error: $error');
              if (useMapTiler) _switchToOSM();
            },
            tileDisplay: const TileDisplay.fadeIn(
              duration: Duration(milliseconds: 50),
            ),
          ),
          if (circles.isNotEmpty) CircleLayer(circles: circles),
          if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
          if (markers.isNotEmpty)
            MarkerLayer(markers: markers, rotate: false),
        ],
      );
    });
  }

  /// 🧹 تنظيف الكاش
  Future<void> clearCache() async {
    if (_isInitialized) {
      await _cacheStore.manage.delete();
      await _cacheStore.manage.create();
      debugPrint('🧽 Cache cleared');
    }
  }

  /// 📦 تحميل منطقة محددة (مثل البصرة) للعمل أوفلاين
  Future<void> preloadArea(LatLng center) async {
    if (!_isInitialized) return;
    final region = RectangleRegion(  
      LatLngBounds(
        LatLng(center.latitude - 0.05, center.longitude - 0.05),
        LatLng(center.latitude + 0.05, center.longitude + 0.05),
      ),
    );

    final stream = _cacheStore.download.startForeground(
      region: region as DownloadableRegion<BaseRegion>,
      // minZoom: 12,
      // maxZoom: 17,
      // behavior: CacheBehavior.downloadNewOnly,
    );

    await for (final progress in stream as Stream<DownloadProgress>) {
      debugPrint(
          '📥 Preloading: ${progress.successfulTilesSize}/${progress.skippedTilesCount}');
    }
  }
}

/// 🎯 Helper سريع
class QuickMap {
  static Widget forHome(
    MapController controller,
    LatLng center,
    int zoom,
    List<Marker> markers, {
    List<CircleMarker> circles = const [],
    Function(MapCamera camera, bool gesture)? onPositionChanged,
  }) {
    return MapService.to.buildOptimizedMap(
      controller: controller,
      initialCenter: center,
      markers: markers,
      circles: circles,
      initialZoom: zoom.toDouble(),
      minZoom: 12.0,
      maxZoom: 18.0,
      onPositionChanged: onPositionChanged,
    );
  }

  static Widget forTracking(
    MapController controller,
    LatLng center,
    List<Marker> markers, {
    List<Polyline> polylines = const [],
    Function(MapCamera camera, bool gesture)? onPositionChanged,
  }) {
    return MapService.to.buildOptimizedMap(
      controller: controller,
      initialCenter: center,
      markers: markers,
      polylines: polylines,
      initialZoom: 15.0,
      minZoom: 10.0,
      maxZoom: 18.0,
      onPositionChanged: onPositionChanged,
    );
  }
     static Widget forEditing(
    MapController controller,
    LatLng center,
    List<Marker> markers,
    PositionCallback? onPositionChanged,

  ) {
    return MapService.to.buildOptimizedMap(
      controller: controller,
      initialCenter: center,
      markers: markers,
      initialZoom: 16.0,
      minZoom: 12.0,
      maxZoom: 18.0,
      onPositionChanged: onPositionChanged,

    );
  }
} 


///////////////////////////////////////////////////////////////////////////////////
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:get/get.dart';
// import 'package:http/io_client.dart'; 
// import 'package:transport_app/main.dart';


// // استخدم متغيرات البيئة أو طرق آمنة أخرى.
// const String mapTilerApiKey = 'ZhHIu4uERobVUW4hGLuG';

// /// 🚀 Map Service - محسّن للسرعة القصوى بدون Cache
// class MapService extends GetxService {
//   static MapService get to => Get.find();

//   @override
//   Future<void> onInit() async {
//     super.onInit();
//     logger.w('MapService initialized without tile caching.');
//   }

//   /// بناء خريطة محسّنة
//   Widget buildOptimizedMap({
//     required MapController controller,
//     required LatLng initialCenter,
//     required List<Marker> markers,
//     List<Polyline> polylines = const [],
//     List<CircleMarker> circles = const [],
//     double initialZoom = 15.0,
//     double minZoom = 12.0,
//     double maxZoom = 18.0,
//     PositionCallback? onPositionChanged,
//   }) {
//     // تحديد TileProvider
//     // ✅ التغيير هنا: استخدام IOClient()
//     final TileProvider tileProvider = NetworkTileProvider(
//       httpClient: IOClient(), 
//     );

//     logger.i('🗺️ بناء الخريطة - Center: $initialCenter, Zoom: $initialZoom, Markers: ${markers.length}');
    
//     return FlutterMap(
//       mapController: controller,
//       options: MapOptions(
//         initialCenter: initialCenter,
//         initialZoom: initialZoom,
//         minZoom: minZoom,
//         maxZoom: maxZoom,
//         interactionOptions: const InteractionOptions(
//           flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
//         ),
//         onMapEvent: (event) {
//           if (event is MapEventMove || event is MapEventMoveEnd) {
//             final camera = event.camera;
//             final hasGesture = event.source != MapEventSource.mapController;
//             onPositionChanged?.call(camera, hasGesture);
//           }
//         },
//         onMapReady: () {
//           logger.i('✅ الخريطة جاهزة!');
//         },
//       ),
//       children: [
//         // ✅ TileLayer محسّن للسرعة (بدون Cache)
//         TileLayer(
//           urlTemplate:
//               'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$mapTilerApiKey',
//           userAgentPackageName: 'transport.app.com',
//           tileProvider: tileProvider, 

//           // ✅ إعدادات السرعة القصوى
//           maxNativeZoom: 18,
//           minNativeZoom: 5,
//           maxZoom: 18,

//           // 🚀 أهم التحسينات للسرعة
//           keepBuffer: 1,
//           panBuffer: 0,
//           retinaMode: false,

//           // ✅ Fade سريع جداً
//           tileDisplay: const TileDisplay.fadeIn(
//             duration: Duration(milliseconds: 50),
//           ),
//         ),

//         if (circles.isNotEmpty) CircleLayer(circles: circles),
//         if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
//         if (markers.isNotEmpty) MarkerLayer(markers: markers, rotate: false),
//       ],
//     );
//   }

 
// }

// /// 🎯 Helper للاستخدام السريع (ممتاز كما هو)
// class QuickMap {
//   static Widget forHome(
//     MapController controller,
//     LatLng center,
//     int zoom,
//     List<Marker> markers, {
//     List<CircleMarker> circles = const [],
//     PositionCallback? onPositionChanged,
//   }) {
//     return MapService.to.buildOptimizedMap(
//       controller: controller,
//       initialCenter: center,
//       markers: markers,
//       circles: circles,
//       initialZoom: zoom.toDouble(),
//       minZoom: 12.0,
//       maxZoom: 18.0,
//       onPositionChanged: onPositionChanged,
//     );
//   }

//   static Widget forTracking(
//     MapController controller,
//     LatLng center,
//     List<Marker> markers, {
//     List<Polyline> polylines = const [],
//     PositionCallback? onPositionChanged,
//   }) {
//     // ✅ التحقق من صحة المدخلات
//     return MapService.to.buildOptimizedMap(
//       controller: controller,
//       initialCenter: center,
//       markers: markers,
//       polylines: polylines,
//       initialZoom: 11.0,
//       minZoom: 10.0,
//       maxZoom: 18.0,
//       onPositionChanged: onPositionChanged,
//     );
//   }

//   static Widget forEditing(
//     MapController controller,
//     LatLng center,
//     List<Marker> markers,
//     PositionCallback? onPositionChanged,

//   ) {
//     return MapService.to.buildOptimizedMap(
//       controller: controller,
//       initialCenter: center,
//       markers: markers,
//       initialZoom: 16.0,
//       minZoom: 12.0,
//       maxZoom: 18.0,
//       onPositionChanged: onPositionChanged,

//     );
//   }
// } 

