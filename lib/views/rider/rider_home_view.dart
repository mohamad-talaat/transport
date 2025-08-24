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

class _RiderHomeViewState extends State<RiderHomeView>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthController authController = Get.find<AuthController>();
  final MapControllerr mapController = Get.put(MapControllerr());
  final TripController tripController = Get.find<TripController>();

  bool _hasOpenedDestinationSheetOnce = false;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadDestinationSheetFlag();
    _initializeAnimations();
    // Ensure map recenters to exact current location on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mapController.refreshCurrentLocation();
    });
  }

  String _formatSeconds(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadDestinationSheetFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasOpenedDestinationSheetOnce =
          prefs.getBool('rider_opened_destination_once') ?? false;

      if (!_hasOpenedDestinationSheetOnce &&
          !tripController.hasActiveTrip.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showDestinationBottomSheet();
          prefs.setBool('rider_opened_destination_once', true);
          _hasOpenedDestinationSheetOnce = true;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          _buildMap(),
          _buildTopSearchBar(context),
          _buildUserInfoHeader(),
          _buildBalanceCard(),
          _buildSideControls(),
          _buildSearchResults(),
          _buildBottomTripCard(),
          _buildLoadingOverlay(),
        ],
      ),
    );
  }

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
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.transport_app',
              maxZoom: 19,
            ),
            CircleLayer(circles: mapController.circles),
            PolylineLayer(polylines: mapController.polylines),
            MarkerLayer(markers: mapController.markers),
          ],
        ));
  }

  Widget _buildTopSearchBar(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Builder(
                builder: (ctx) => Container(
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.grey),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: mapController.searchController,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    hintText: 'إلى أين تريد الذهاب؟',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      mapController.searchLocation(value);
                    } else {
                      mapController.searchResults.clear();
                    }
                  },
                ),
              ),
              Obx(() => Container(
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: mapController.isSearching.value
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: () {
                              String query =
                                  mapController.searchController.text;
                              if (query.isNotEmpty) {
                                mapController.searchLocation(query);
                              }
                            },
                          ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoHeader() {
    return Positioned(
        top: MediaQuery.of(context).padding.top + 80,
        left: 10,
        child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: authController
                                  .currentUser.value?.profileImage !=
                              null
                          ? NetworkImage(
                              authController.currentUser.value!.profileImage!)
                          : null,
                      child:
                          authController.currentUser.value?.profileImage == null
                              ? const Icon(Icons.person,
                                  size: 15, color: Colors.white)
                              : null,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مرحباً ${authController.currentUser.value?.name ?? 'مستخدم'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          child: Text(
                            'إلى أين تريد الذهاب؟',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          onPressed: () => _showDestinationBottomSheet(),
                        )
                      ])
                ]))));
  }

  Widget _buildLoadingOverlay() {
    return Obx(() {
      final bool showOverlay = mapController.isLoading.value;
      if (!showOverlay) return const SizedBox.shrink();

      return Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Colors.orange,
                ),
                SizedBox(height: 16),
                Text(
                  'جاري التحميل...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        authController.currentUser.value?.profileImage != null
                            ? NetworkImage(
                                authController.currentUser.value!.profileImage!)
                            : null,
                    child:
                        authController.currentUser.value?.profileImage == null
                            ? const Icon(Icons.person,
                                size: 30, color: Colors.white)
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authController.currentUser.value?.name ?? 'مستخدم',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          authController.currentUser.value?.phone ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: 'الملف الشخصي',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.RIDER_PROFILE);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.history,
                    title: 'تاريخ الرحلات',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.RIDER_TRIP_HISTORY);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'المحفظة',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.RIDER_WALLET);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications_outlined,
                    title: 'الإشعارات',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.RIDER_NOTIFICATIONS);
                    },
                  ),
                  const Divider(height: 32),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'الإعدادات',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.RIDER_SETTINGS);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'المساعدة والدعم',
                    onTap: () {
                      Get.back();
                      // Handle help
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline,
                    title: 'عن التطبيق',
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.RIDER_ABOUT);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red.shade400),
                title: Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Get.back();
                  _showLogoutDialog();
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.red.shade50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _onMapTap(LatLng point) {
    mapController.selectedLocation.value = point;
    mapController.addSelectedLocationMarker(point, 'الموقع المحدد');

    // Draw route polylines when both locations are available
    if (mapController.currentLocation.value != null) {
      _fetchAndDrawRoute();
    }

    LocationService.to.getAddressFromLocation(point).then((address) {
      mapController.selectedAddress.value = address;
      // تعبئة حقل البحث تلقائياً باسم المكان المختار من الخريطة
      mapController.searchController.text = address;
    });
  }

  Future<void> _fetchAndDrawRoute() async {
    if (mapController.currentLocation.value == null ||
        mapController.selectedLocation.value == null) {
      return;
    }

    try {
      mapController.isLoading.value = true;
      final bool hasMiddle = mapController.middleStopLocation.value != null;
      if (hasMiddle) {
        final List<LatLng> route =
            await LocationService.to.getRouteWithWaypoint(
          mapController.currentLocation.value!,
          mapController.middleStopLocation.value!,
          mapController.selectedLocation.value!,
        );
        // ابحث عن أقرب نقطة للـ waypoint لتقسيم المسار بين مقطعين بلونين مختلفين
        final waypoint = mapController.middleStopLocation.value!;
        int splitAt = _findClosestIndex(route, waypoint);
        mapController.drawTripRoute(route, splitIndices: [splitAt]);
      } else {
        final List<LatLng> route = await LocationService.to.getRoute(
          mapController.currentLocation.value!,
          mapController.selectedLocation.value!,
        );
        mapController.drawTripRoute(route);
      }
    } catch (_) {
    } finally {
      mapController.isLoading.value = false;
    }
  }

  int _findClosestIndex(List<LatLng> route, LatLng target) {
    double best = double.infinity;
    int idx = 0;
    for (int i = 0; i < route.length; i++) {
      final dLat = route[i].latitude - target.latitude;
      final dLng = route[i].longitude - target.longitude;
      final dist = (dLat * dLat) + (dLng * dLng);
      if (dist < best) {
        best = dist;
        idx = i;
      }
    }
    return idx;
  }

  void _showDestinationBottomSheet() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'إلى أين تريد الذهاب؟',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      autofocus: true,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن الوجهة...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      onChanged: (value) => mapController.searchLocation(value),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: mapController.searchResults.length,
                    itemBuilder: (context, index) {
                      final result = mapController.searchResults[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: Colors.red.shade400,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            result.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            result.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () async {
                            mapController.selectLocationFromSearch(result);
                            await _fetchAndDrawRoute();
                            Get.back();
                          },
                        ),
                      );
                    },
                  )),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  void _showMiddleStopBottomSheet() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_location_alt,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'إضافة محطة وسطى',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: mapController.middleStopController,
                      autofocus: true,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن المحطة الوسطى...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      onChanged: (value) => mapController.searchLocation(value),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: mapController.searchResults.length,
                    itemBuilder: (context, index) {
                      final result = mapController.searchResults[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_location_alt,
                              color: Colors.orange.shade400,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            result.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            result.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () async {
                            // تعيين المحطة الوسطى وإعادة رسم المسار
                            mapController.setMiddleStopFromSearch(result);
                            await _fetchAndDrawRoute();
                            Get.back();
                            Get.snackbar(
                              'تم إضافة المحطة',
                              'تم إضافة ${result.name} كمحطة وسطى',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                          },
                        ),
                      );
                    },
                  )),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _requestTrip() async {
    if (mapController.currentLocation.value == null ||
        mapController.selectedLocation.value == null) {
      Get.snackbar(
        'خطأ',
        'يرجى تحديد نقطة البداية والوجهة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Build pickup and destination points
    final pickupLatLng = mapController.currentLocation.value!;
    final destLatLng = mapController.selectedLocation.value!;

    String pickupAddress = mapController.currentAddress.value;
    if (pickupAddress.isEmpty) {
      pickupAddress =
          await LocationService.to.getAddressFromLocation(pickupLatLng);
    }

    String destinationAddress = mapController.selectedAddress.value;
    if (destinationAddress.isEmpty) {
      destinationAddress =
          await LocationService.to.getAddressFromLocation(destLatLng);
    }

    final pickup = LocationPoint(
        lat: pickupLatLng.latitude,
        lng: pickupLatLng.longitude,
        address: pickupAddress);
    final destination = LocationPoint(
        lat: destLatLng.latitude,
        lng: destLatLng.longitude,
        address: destinationAddress);

    await tripController.requestTrip(pickup: pickup, destination: destination);

    // Navigate to searching screen
    _showDriverSearching();
  }

  void _showDriverSearching() {
    Get.to(
      () => const DriverSearchingView(),
      transition: Transition.upToDown,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'تسجيل الخروج',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              authController.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

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

  Widget _buildBalanceCard() {
    return Positioned(
      top: MediaQuery.of(Get.context!).padding.top + 80,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Obx(() => GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.RIDER_WALLET),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${(authController.currentUser.value?.balance ?? 0.0).toStringAsFixed(2)} ج.م',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ),
    );
  }

  Widget _buildSideControls() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(Get.context!).size.height / 2 - 80,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildControlButton(
              icon: Icons.my_location,
              color: Colors.blue,
              onPressed: () => mapController.refreshCurrentLocation(),
            ),
            const SizedBox(height: 12),
            _buildControlButton(
              icon: Icons.zoom_in,
              color: Colors.grey.shade600,
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
            const SizedBox(height: 8),
            _buildControlButton(
              icon: Icons.zoom_out,
              color: Colors.grey.shade600,
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
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
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
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBottomTripCard() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Obx(() {
          if (tripController.hasActiveTrip.value) {
            return _buildActiveTripCard();
          } else {
            return SizedBox(
              height: Get.height * 0.35, // صغرت الكارت عشان الخريطة تبان أكتر
              child: buildRequestTripSheet(),
            );
          }
        }),
      ),
    );
  }

  Widget buildRequestTripSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.5, // يبدأ من 50% من الشاشة
      minChildSize: 0.3, // أصغر حجم 30%
      maxChildSize: 0.95, // يتمدد لحد 95%
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController, // مهم علشان يدعم السحب
            padding: const EdgeInsets.all(24),
            children: [
              // مقبض صغير فوق
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Text(
                'تفاصيل الرحلة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // من (الموقع الحالي)
              _buildLocationRow(
                icon: Icons.radio_button_checked,
                color: Colors.green,
                title: 'من',
                subtitle: mapController.currentAddress.value.isNotEmpty
                    ? mapController.currentAddress.value
                    : 'الموقع الحالي',
              ),

              // محطة وسطى
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 28),
                    Container(
                        width: 2, height: 40, color: Colors.grey.shade300),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showMiddleStopBottomSheet(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.orange.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_location_alt,
                                  color: Colors.orange.shade600, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'إضافة محطة وسطى',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // الوجهة
              _buildLocationRow(
                icon: Icons.location_on,
                color: Colors.red,
                title: 'إلى',
                subtitle: mapController.selectedAddress.value.isNotEmpty
                    ? mapController.selectedAddress.value
                    : 'اختر الوجهة',
                onTap: () => _showDestinationBottomSheet(),
              ),

              // تفاصيل المسافة / الوقت / التكلفة
              const SizedBox(height: 16),
              Obx(() {
                if (mapController.selectedLocation.value != null) {
                  final from = mapController.currentLocation.value;
                  final to = mapController.selectedLocation.value;
                  if (from == null || to == null) {
                    return const SizedBox.shrink();
                  }

                  final distanceKm =
                      LocationService.to.calculateDistance(from, to);
                  final durationMin =
                      LocationService.to.estimateDuration(distanceKm);
                  final fare = 10.0 + (distanceKm * 3.0);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTripInfo(
                          icon: Icons.access_time,
                          label: 'المدة المتوقعة',
                          value: '$durationMin دقيقة',
                          color: Colors.blue,
                        ),
                        Container(
                            width: 1, height: 32, color: Colors.grey.shade300),
                        _buildTripInfo(
                          icon: Icons.straighten,
                          label: 'المسافة',
                          value: '${distanceKm.toStringAsFixed(1)} كم',
                          color: Colors.green,
                        ),
                        Container(
                            width: 1, height: 32, color: Colors.grey.shade300),
                        _buildTripInfo(
                          icon: Icons.payments,
                          label: 'التكلفة',
                          value: '${fare.toStringAsFixed(2)} ج.م',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              const SizedBox(height: 24),

              // زر تأكيد الرحلة
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        final inCooldown =
                            tripController.remainingSearchSeconds.value > 0;
                        if (mapController.selectedLocation.value != null &&
                            !tripController.isRequestingTrip.value &&
                            !inCooldown) {
                          _requestTrip();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: tripController.isRequestingTrip.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : (tripController.remainingSearchSeconds.value > 0
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.timer, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'يرجى الانتظار ${_formatSeconds(tripController.remainingSearchSeconds.value)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.local_taxi, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'تأكيد الطلب',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
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
                    subtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.edit_location_alt,
                color: Colors.grey[400],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfo({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTripCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Obx(() {
        final trip = tripController.activeTrip.value;
        if (trip == null) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _getTripStatusColor(trip.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
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
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTripInfo(
                    icon: Icons.access_time,
                    label: 'المدة',
                    value: '${trip.estimatedDuration} دقيقة',
                    color: Colors.blue,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade300,
                  ),
                  _buildTripInfo(
                    icon: Icons.straighten,
                    label: 'المسافة',
                    value: '${trip.distance.toStringAsFixed(1)} كم',
                    color: Colors.green,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade300,
                  ),
                  _buildTripInfo(
                    icon: Icons.payments,
                    label: 'التكلفة',
                    value: '${trip.fare.toStringAsFixed(2)} ج.م',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (trip.status == TripStatus.pending) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => tripController.cancelTrip(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'إلغاء الرحلة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
                if (trip.status != TripStatus.pending) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showDriverSearching(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'تتبع الرحلة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildSearchResults() {
    return Obx(() {
      if (mapController.searchResults.isEmpty) {
        return const SizedBox.shrink();
      }
      return Positioned(
          top: MediaQuery.of(Get.context!).padding.top + 80,
          left: 16,
          right: 16,
          child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: mapController.searchResults.length,
                      itemBuilder: (context, index) {
                        final result = mapController.searchResults[index];
                        return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.red.shade400,
                                size: 16,
                              ),
                            ),
                            title: Text(
                              result.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(result.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                )),
                            onTap: () async {
                              mapController.selectLocationFromSearch(result);
                              await _fetchAndDrawRoute();
                            });
                      }))));
    });
  }
}

// Driver Searching View
class DriverSearchingView extends StatefulWidget {
  const DriverSearchingView({super.key});

  @override
  State<DriverSearchingView> createState() => _DriverSearchingViewState();
}

class _DriverSearchingViewState extends State<DriverSearchingView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _dotsController;
  late Animation<double> _pulseAnimation;
  final AuthController authController = Get.find<AuthController>();
  final MapControllerr mapController = Get.put(MapControllerr());
  final TripController tripController = Get.find<TripController>();

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));

    _pulseController.repeat(reverse: true);
    _dotsController.repeat();
  }

  String _formatSeconds(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'البحث عن سائق',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Trip Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Obx(() {
                    final trip = tripController.activeTrip.value;
                    final pickupAddress =
                        trip?.pickupLocation.address ?? 'جاري تجهيز العنوان...';
                    final destAddress = trip?.destinationLocation.address ??
                        'جاري تجهيز العنوان...';
                    return Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.radio_button_checked,
                                color: Colors.green.shade600,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pickupAddress,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          height: 2,
                          child: Row(
                            children: List.generate(
                              20,
                              (index) => Expanded(
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.red.shade600,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                destAddress,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ),

                const SizedBox(height: 40),

                // Price and Details (dynamic)
                Obx(() {
                  final trip = tripController.activeTrip.value;
                  final duration = trip?.estimatedDuration != null
                      ? '${trip!.estimatedDuration} دقيقة'
                      : '--';
                  final distance = trip?.distance != null
                      ? '${trip!.distance.toStringAsFixed(1)} كم'
                      : '--';
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoCard(
                        icon: Icons.access_time,
                        label: 'المدة',
                        value: duration,
                        color: Colors.blue,
                      ),
                      _buildInfoCard(
                        icon: Icons.straighten,
                        label: 'المسافة',
                        value: distance,
                        color: Colors.green,
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 20),

                Obx(() {
                  final trip = tripController.activeTrip.value;
                  final fareText = trip != null
                      ? '${trip.fare.toStringAsFixed(2)} جنيه مصري'
                      : '--';
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade600
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'إجمالي التكلفة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          fareText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // أزلت الـ Spacer لأنه داخل ScrollView ويسبب قيود غير منتهية
                const SizedBox(height: 16),

                // Searching Animation
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade400,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                Obx(() {
                  final secs = tripController.remainingSearchSeconds.value;
                  final timerText =
                      secs > 0 ? ' — ${_formatSeconds(secs)}' : '';
                  return Text(
                    'جاري البحث عن سائق متاح$timerText',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  );
                }),

                const SizedBox(height: 10),

                AnimatedBuilder(
                  animation: _dotsController,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final opacity =
                            index == ((_dotsController.value * 3).floor() % 3)
                                ? 1.0
                                : 0.3;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade400.withOpacity(opacity),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    );
                  },
                ),

                const SizedBox(height: 30),

                Text(
                  'سيتم إشعارك عند العثور على سائق مناسب',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await tripController.cancelTrip();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'إلغاء الطلب',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          )),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
