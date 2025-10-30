import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/routes/app_routes.dart';

/// 🔗 خدمة Deep Linking - لفتح روابط Google Maps والمواقع الجغرافية
class DeepLinkService extends GetxService {
  static DeepLinkService get to => Get.find();

  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;

  @override
  void onInit() {
    super.onInit();
    _initDeepLinks();
  }

  /// تهيئة Deep Links
  void _initDeepLinks() {
    _checkInitialLink();
    _listenToLinks();
  }

  /// فحص الرابط الأولي عند فتح التطبيق
  Future<void> _checkInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        logger.i('🔗 Initial link detected: $uri');
        _handleDeepLink(uri);
      }
    } catch (e) {
      logger.w('❌ خطأ في قراءة الرابط الأولي: $e');
    }
  }

  /// الاستماع للروابط الجديدة
  void _listenToLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        logger.i('🔗 New link received: $uri');
        _handleDeepLink(uri);
      },
      onError: (e) {
        logger.w('❌ خطأ في Deep Link: $e');
      },
    );
  }

  /// معالجة الرابط
  void _handleDeepLink(Uri uri) {
    logger.i('📎 Processing Deep Link: $uri');

    if (_isGoogleMapsLink(uri)) {
      _handleGoogleMapsLink(uri);
    } else if (_isGeoLink(uri)) {
      _handleGeoLink(uri);
    } else if (_isAppLink(uri)) {
      _handleAppLink(uri);
    } else {
      logger.w('⚠️ رابط غير مدعوم: $uri');
      Get.snackbar(
        'رابط غير مدعوم',
        'هذا الرابط لا يمكن فتحه في التطبيق',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// فحص إذا كان رابط Google Maps
  bool _isGoogleMapsLink(Uri uri) {
    return uri.host.contains('google.com') ||
        uri.host.contains('maps.google') ||
        uri.host.contains('goo.gl') ||
        uri.host.contains('maps.app.goo.gl');
  }

  /// فحص إذا كان رابط Geo
  bool _isGeoLink(Uri uri) {
    return uri.scheme == 'geo';
  }

  /// فحص إذا كان رابط التطبيق الخاص
  bool _isAppLink(Uri uri) {
    return uri.scheme == 'taksi' || uri.host.contains('taksi-elbasra.app');
  }

  /// معالجة رابط Google Maps
  void _handleGoogleMapsLink(Uri uri) {
    try {
      LatLng? location;

      // 1️⃣ استخراج من query parameter 'q'
      // مثال: https://www.google.com/maps?q=30.5090422,47.7875914
      if (uri.queryParameters.containsKey('q')) {
        final q = uri.queryParameters['q']!;
        location = _parseCoordinates(q);
      }

      // 2️⃣ استخراج من query parameter 'll'
      // مثال: https://maps.google.com/?ll=30.5090422,47.7875914
      else if (uri.queryParameters.containsKey('ll')) {
        final ll = uri.queryParameters['ll']!;
        location = _parseCoordinates(ll);
      }

      // 3️⃣ استخراج من path مباشرة
      // مثال: https://maps.google.com/@30.5090422,47.7875914,17z
      else if (uri.path.contains('@')) {
        final coords = uri.path.split('@').last.split(',');
        if (coords.length >= 2) {
          location = LatLng(
            double.parse(coords[0]),
            double.parse(coords[1]),
          );
        }
      }

      // 4️⃣ استخراج من query string مباشرة
      // مثال: https://maps.app.goo.gl/xxxxx?g_ep=...
      else if (uri.query.isNotEmpty) {
        final parts = uri.query.split('=');
        if (parts.length > 1 && parts[0] == 'q') {
          location = _parseCoordinates(parts[1]);
        }
      }

      if (location != null) {
        _openLocationInApp(location, 'Google Maps');
      } else {
        Get.snackbar(
          'خطأ',
          'لا يمكن قراءة الموقع من الرابط',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      logger.w('❌ خطأ في معالجة رابط Google Maps: $e');
      Get.snackbar(
        'خطأ',
        'رابط غير صحيح',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// معالجة رابط Geo
  void _handleGeoLink(Uri uri) {
    try {
      // مثال: geo:30.5090422,47.7875914
      final coords = uri.path.split(',');
      if (coords.length >= 2) {
        final location = LatLng(
          double.parse(coords[0]),
          double.parse(coords[1]),
        );
        _openLocationInApp(location, 'Geo Link');
      }
    } catch (e) {
      logger.w('❌ خطأ في معالجة Geo Link: $e');
    }
  }

  /// معالجة رابط التطبيق الخاص
  void _handleAppLink(Uri uri) {
    try {
      // مثال: taksi://location?lat=30.5090422&lng=47.7875914
      if (uri.path.contains('location') || uri.host == 'location') {
        final lat = uri.queryParameters['lat'];
        final lng = uri.queryParameters['lng'];

        if (lat != null && lng != null) {
          final location = LatLng(
            double.parse(lat),
            double.parse(lng),
          );
          _openLocationInApp(location, 'App Link');
        }
      }
    } catch (e) {
      logger.w('❌ خطأ في معالجة App Link: $e');
    }
  }

  /// استخراج الإحداثيات من نص
  LatLng? _parseCoordinates(String text) {
    try {
      // إزالة المسافات والرموز الزائدة
      final cleaned = text
          .replaceAll(' ', '')
          .replaceAll('+', '')
          .replaceAll('(', '')
          .replaceAll(')', '');
      final parts = cleaned.split(',');

      if (parts.length >= 2) {
        return LatLng(
          double.parse(parts[0]),
          double.parse(parts[1]),
        );
      }
    } catch (e) {
      logger.w('❌ خطأ في parse coordinates: $e');
    }
    return null;
  }

  /// فتح الموقع في التطبيق
  void _openLocationInApp(LatLng location, String source) {
    logger.i('✅ Opening location from $source: ${location.latitude}, ${location.longitude}');

    // التأكد من أننا في صفحة الرئيسية للراكب
    if (Get.currentRoute != AppRoutes.RIDER_HOME) {
      Get.toNamed(AppRoutes.RIDER_HOME);
    }

    // الانتظار لحظة حتى يتم بناء الصفحة
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        // الحصول على MapController
        final mapController = Get.find<MyMapController>();

        // تحديد الموقع كوجهة
        mapController.moveToLocation(location, zoom: 16.0);

        // إذا كانت نقطة الانطلاق محددة بالفعل، نحدد هذا كوجهة
        if (mapController.isPickupConfirmed.value) {
          mapController.startLocationSelection('destination');
        }

        Get.snackbar(
          '📍 موقع من رابط خارجي',
          'تم فتح الموقع في التطبيق',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        logger.e('❌ خطأ في فتح الموقع: $e');
      }
    });
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }
}
