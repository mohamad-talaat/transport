import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/controllers/map_controller.dart';
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/location_service.dart';

class RiderHomeView extends StatefulWidget {
  const RiderHomeView({super.key});

  @override
  State<RiderHomeView> createState() => _RiderHomeViewState();
}

class _RiderHomeViewState extends State<RiderHomeView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthController authController = Get.find<AuthController>();
  // final MapControllerr mapController = Get.find<MapControllerr>();
  final MapControllerr mapController = Get.put(MapControllerr());
  final TripController tripController = Get.find<TripController>();
  bool _hasOpenedDestinationSheetOnce = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // الخريطة
          _buildMap(),

          // شريط البحث العلوي
          _buildTopSearchBar(context),

          // معلومات المستخدم
          _buildUserInfoHeader(),

          // بطاقة الرصيد
          _buildBalanceCard(),

          // أزرار التحكم الجانبية
          _buildSideControls(),

          // قائمة البحث
          _buildSearchResults(),

          // بطاقة الطلب/الرحلة
          _buildBottomTripCard(),

          // شاشة التحميل
          _buildLoadingOverlay(),
        ],
      ),
      //  bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadDestinationSheetFlag();
  }

  Future<void> _loadDestinationSheetFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasOpenedDestinationSheetOnce =
          prefs.getBool('rider_opened_destination_once') ?? false;

      // افتح نافذة الوجهة تلقائياً لأول مرة فقط، عندما لا تكون هناك رحلة نشطة
      if (!_hasOpenedDestinationSheetOnce &&
          !tripController.hasActiveTrip.value) {
        // انتظر أول frame لضمان أن Build اكتمل
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showDestinationBottomSheet();
          prefs.setBool('rider_opened_destination_once', true);
          _hasOpenedDestinationSheetOnce = true;
        });
      }
    } catch (_) {
      // تجاهل أي خطأ بسيط في القراءة
    }
  }

  /// الخريطة الرئيسية
  Widget _buildMap() {
    return Obx(() => FlutterMap(
          mapController: mapController.mapController,
          options: MapOptions(
            initialCenter: mapController.mapCenter.value,
            initialZoom: mapController.mapZoom.value,
            minZoom: 5.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onTap: (tapPosition, point) => _onMapTap(point),
          ),
          children: [
            // طبقة الخريطة
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.transport_app',
              maxZoom: 19,
            ),

            // الدوائر
            CircleLayer(circles: mapController.circles),

            // الخطوط
            PolylineLayer(polylines: mapController.polylines),

            // العلامات
            MarkerLayer(markers: mapController.markers),
          ],
        ));
  }

  /// شريط البحث العلوي
  Widget _buildTopSearchBar(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // زر القائمة
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),

            // مربع البحث
            Expanded(
              child: TextField(
                controller: mapController.searchController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  hintText: 'ابحث عن موقع...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    mapController.searchLocation(value);
                  } else {
                    mapController.searchResults.clear();
                  }
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    mapController.searchLocation(value);
                  }
                },
              ),
            ),

            // زر البحث
            Obx(() => mapController.isSearching.value
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.teal,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      String query = mapController.searchController.text;
                      if (query.isNotEmpty) {
                        mapController.searchLocation(query);
                      }
                    },
                  )),
          ],
        ),
      ),
    );
  }

  /// بطاقة الرصيد
  Widget _buildBalanceCard() {
    return Positioned(
      top: MediaQuery.of(Get.context!).padding.top + 80,
      right: 16,
      child: Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.RIDER_WALLET),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(authController.currentUser.value?.balance ?? 0.0).toStringAsFixed(2)} ج.م',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )),
    );
  }

  /// أزرار التحكم الجانبية
  Widget _buildSideControls() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(Get.context!).size.height / 2 - 100,
      child: Column(
        children: [
          // زر الموقع الحالي
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location, color: Colors.blue),
              onPressed: () => mapController.refreshCurrentLocation(),
            ),
          ),

          const SizedBox(height: 16),

          // زر التكبير
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.zoom_in, color: Colors.grey),
              onPressed: () {
                double newZoom = mapController.mapZoom.value + 1;
                if (newZoom <= 18) {
                  mapController.mapController.move(
                    mapController.mapCenter.value,
                    newZoom,
                  );
                  mapController.mapZoom.value = newZoom;
                }
              },
            ),
          ),

          const SizedBox(height: 8),

          // زر التصغير
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.zoom_out, color: Colors.grey),
              onPressed: () {
                double newZoom = mapController.mapZoom.value - 1;
                if (newZoom >= 5) {
                  mapController.mapController.move(
                    mapController.mapCenter.value,
                    newZoom,
                  );
                  mapController.mapZoom.value = newZoom;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة طلب الرحلة السفلية
  Widget _buildBottomTripCard() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Obx(() {
        if (tripController.hasActiveTrip.value) {
          return _buildActiveTripCard();
        } else {
          return _buildRequestTripCard();
        }
      }),
    );
  }

  /// بطاقة طلب رحلة جديدة
  Widget _buildRequestTripCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // الموقع الحالي
          Obx(() => _buildLocationItem(
                icon: Icons.my_location,
                color: Colors.green,
                title: 'من',
                address: mapController.currentAddress.value.isNotEmpty
                    ? mapController.currentAddress.value
                    : 'الموقع الحالي',
              )),

          const Divider(height: 32),

          // الوجهة
          Obx(() => _buildLocationItem(
                icon: Icons.location_on,
                color: Colors.red,
                title: 'إلى',
                address: mapController.selectedAddress.value.isNotEmpty
                    ? mapController.selectedAddress.value
                    : 'اختر الوجهة',
                onTap: () => _showDestinationBottomSheet(),
              )),

          const SizedBox(height: 20),

          // زر طلب الرحلة
          Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: mapController.selectedLocation.value != null &&
                          !tripController.isRequestingTrip.value
                      ? _requestTrip
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: tripController.isRequestingTrip.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'طلب رحلة',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              )),
        ],
      ),
    );
  }

  /// بطاقة الرحلة النشطة
  Widget _buildActiveTripCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Obx(() {
        final trip = tripController.activeTrip.value;
        if (trip == null) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // حالة الرحلة
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _getTripStatusColor(trip.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trip.statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _getTripStatusColor(trip.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // معلومات الرحلة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTripInfo(
                  icon: Icons.access_time,
                  label: 'المدة',
                  value: '${trip.estimatedDuration} دقيقة',
                ),
                _buildTripInfo(
                  icon: Icons.straighten,
                  label: 'المسافة',
                  value: '${trip.distance.toStringAsFixed(1)} كم',
                ),
                _buildTripInfo(
                  icon: Icons.attach_money,
                  label: 'التكلفة',
                  value: '${trip.fare.toStringAsFixed(2)} ج.م',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // أزرار التحكم
            Row(
              children: [
                if (trip.status == TripStatus.pending) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => tripController.cancelTrip(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('إلغاء الرحلة'),
                    ),
                  ),
                ],
                if (trip.status != TripStatus.pending) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Get.toNamed(AppRoutes.RIDER_TRIP_TRACKING),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('تتبع الرحلة'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      }),
    );
  }

  /// عنصر الموقع
  Widget _buildLocationItem({
    required IconData icon,
    required Color color,
    required String title,
    required String address,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.edit, color: Colors.grey[400], size: 16),
        ],
      ),
    );
  }

  /// معلومات الرحلة
  Widget _buildTripInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// نتائج البحث
  Widget _buildSearchResults() {
    return Obx(() {
      if (mapController.searchResults.isEmpty) {
        return const SizedBox.shrink();
      }
      return Positioned(
        top: MediaQuery.of(Get.context!).padding.top + 80,
        left: 16,
        right: 16,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: mapController.searchResults.length,
            itemBuilder: (context, index) {
              final result = mapController.searchResults[index];
              return ListTile(
                leading: const Icon(Icons.location_on, color: Colors.red),
                title: Text(
                  result.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  result.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => mapController.selectLocationFromSearch(result),
              );
            },
          ),
        ),
      );
    });
  }

  /// شاشة التحميل
  Widget _buildLoadingOverlay() {
    return Obx(() {
      final bool showOverlay = mapController.isLoading.value;
      if (!showOverlay) return const SizedBox.shrink();

      return Container(
        color: Colors.black.withOpacity(0.3),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    });
  }

  /// عرض معلومات المستخدم في الأعلى
  Widget _buildUserInfoHeader() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage:
                  authController.currentUser.value?.profileImage != null
                      ? NetworkImage(
                          authController.currentUser.value!.profileImage!)
                      : null,
              child: authController.currentUser.value?.profileImage == null
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authController.currentUser.value?.name ?? 'مستخدم',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  authController.currentUser.value?.phone ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // /// شريط التنقل السفلي
  // Widget _buildBottomNavigationBar() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.1),
  //           blurRadius: 10,
  //           offset: const Offset(0, -2),
  //         ),
  //       ],
  //     ),
  //     child: SafeArea(
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceAround,
  //           children: [
  //             _buildBottomNavItem(
  //               icon: Icons.home,
  //               label: 'الرئيسية',
  //               isSelected: true,
  //               onTap: () {},
  //             ),
  //             _buildBottomNavItem(
  //               icon: Icons.history,
  //               label: 'التاريخ',
  //               onTap: () => Get.toNamed(AppRoutes.RIDER_TRIP_HISTORY),
  //             ),
  //             _buildBottomNavItem(
  //               icon: Icons.account_balance_wallet,
  //               label: 'المحفظة',
  //               onTap: () => Get.toNamed(AppRoutes.RIDER_WALLET),
  //             ),
  //             _buildBottomNavItem(
  //               icon: Icons.person,
  //               label: 'الملف',
  //               onTap: () => Get.toNamed(AppRoutes.RIDER_PROFILE),
  //             ),
  //             _buildBottomNavItem(
  //               icon: Icons.menu,
  //               label: 'المزيد',
  //               onTap: () => _showMoreOptions(),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  /// عنصر شريط التنقل السفلي
  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.blue : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// عرض خيارات إضافية
  void _showMoreOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildMoreOptionItem(
              icon: Icons.notifications,
              title: 'الإشعارات',
              onTap: () => Get.toNamed(AppRoutes.RIDER_NOTIFICATIONS),
            ),
            _buildMoreOptionItem(
              icon: Icons.settings,
              title: 'الإعدادات',
              onTap: () => Get.toNamed(AppRoutes.RIDER_SETTINGS),
            ),
            _buildMoreOptionItem(
              icon: Icons.info,
              title: 'عن التطبيق',
              onTap: () => Get.toNamed(AppRoutes.RIDER_ABOUT),
            ),
            _buildMoreOptionItem(
              icon: Icons.logout,
              title: 'تسجيل الخروج',
              onTap: () => authController.signOut(),
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  /// عنصر خيار إضافي
  Widget _buildMoreOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.blue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Get.back();
        onTap();
      },
    );
  }

  /// معالج النقر على الخريطة
  void _onMapTap(LatLng point) {
    mapController.selectedLocation.value = point;
    mapController.addSelectedLocationMarker(point, 'الموقع المحدد');

    // الحصول على العنوان
    LocationService.to.getAddressFromLocation(point).then((address) {
      mapController.selectedAddress.value = address;
    });
  }

  /// عرض قائمة اختيار الوجهة
  void _showDestinationBottomSheet() {
    Get.bottomSheet(
      Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'اختر الوجهة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  autofocus: true,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن الوجهة...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => mapController.searchLocation(value),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: Obx(() => ListView.builder(
                        itemCount: mapController.searchResults.length,
                        itemBuilder: (context, index) {
                          final result = mapController.searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(result.name),
                            subtitle: Text(result.address),
                            onTap: () {
                              mapController.selectLocationFromSearch(result);
                              Get.back();
                            },
                          );
                        },
                      )),
                ),
              ],
            ),
          )),
      isScrollControlled: true,
    );
  }

  /// طلب رحلة جديدة
  void _requestTrip() {
    if (mapController.currentLocation.value == null ||
        mapController.selectedLocation.value == null) {
      Get.snackbar(
        'خطأ',
        'يرجى تحديد نقطة البداية والوجهة',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    tripController.requestTrip(
      pickup: LocationPoint(
        lat: mapController.currentLocation.value!.latitude,
        lng: mapController.currentLocation.value!.longitude,
        address: mapController.currentAddress.value,
      ),
      destination: LocationPoint(
        lat: mapController.selectedLocation.value!.latitude,
        lng: mapController.selectedLocation.value!.longitude,
        address: mapController.selectedAddress.value,
      ),
    );
  }

  /// الحصول على لون حالة الرحلة
  Color _getTripStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return Colors.orange;
      case TripStatus.accepted:
        return Colors.blue;
      case TripStatus.driverArrived:
        return Colors.green;
      case TripStatus.inProgress:
        return Colors.purple;
      case TripStatus.completed:
        return Colors.green;
      case TripStatus.cancelled:
        return Colors.red;
    }
  }

  /// إنشاء القائمة الجانبية
  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('الملف الشخصي'),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.RIDER_PROFILE);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('تاريخ الرحلات'),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.RIDER_TRIP_HISTORY);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('المحفظة'),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.RIDER_WALLET);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('الإعدادات'),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.RIDER_SETTINGS);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('عن التطبيق'),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.RIDER_ABOUT);
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('تسجيل الخروج',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                authController.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
