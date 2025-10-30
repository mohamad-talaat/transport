import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/controllers/trip_controller.dart';
import 'package:transport_app/main.dart';

import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/services/location_service.dart';
import 'package:transport_app/services/map_services/map_singleton_service.dart';
import 'package:transport_app/views/rider/edit_trip_widgets/edit_mode_buttons.dart';
import 'package:transport_app/views/rider/edit_trip_widgets/edit_stops_list.dart';
import 'package:transport_app/views/rider/edit_trip_widgets/edit_waiting_time_section.dart';
import 'package:transport_app/views/rider/edit_trip_widgets/location_confirmation_panel.dart';
import 'package:transport_app/views/rider/edit_trip_widgets/map_center_pin.dart';
import 'package:transport_app/views/rider/rider_widgets/go_to_my_current_location.dart';
import 'package:transport_app/views/rider/rider_widgets/pin_color.dart';
import 'package:transport_app/views/rider/rider_widgets/pin_painter.dart';

class EditTripLocationView extends StatefulWidget {
  const EditTripLocationView({super.key});

  @override
  State<EditTripLocationView> createState() => _EditTripLocationViewState();
}

class _EditTripLocationViewState extends State<EditTripLocationView> {
  final TripController tripController = Get.find();
  final MyMapController mapController = Get.find<MyMapController>();
  final LocationService locationService = LocationService.to;

  late TripModel originalTrip;
  final RxList<AdditionalStop> _additionalStops = <AdditionalStop>[].obs;
  final Rx<LocationPoint?> _destination = Rx<LocationPoint?>(null);
  final RxString currentStep = 'none'.obs;
  final RxBool isSubmitting = false.obs;
  final RxString centerAddress = '...'.obs;
  final RxBool isFetchingAddress = false.obs;
  final RxBool isMapMoving = false.obs;
  final RxBool isLoading = false.obs;
  final RxMap<int, int> stopWaitingTimes = <int, int>{}.obs;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final RxInt tripWaitingTime = 0.obs;
  Timer? _debounce;

  // ✅ متغير يحفظ آخر موقع ثابت بعد توقف الحركة
  final Rx<LatLng?> _lastStableCenter = Rx<LatLng?>(null);

  @override
  void initState() {
    super.initState();
    originalTrip = Get.arguments['trip'] as TripModel;
    _destination.value = originalTrip.destinationLocation;
    _additionalStops.assignAll(originalTrip.additionalStops.take(2).toList());
    tripWaitingTime.value = originalTrip.waitingTime ?? 0;

    // ✅ الاستماع لتغيير الخطوة
    currentStep.listen((step) {
      if (step != 'none') {
        _sheetController.animateTo(0.25,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeMapForStep(step);
        });
      } else {
        _sheetController.animateTo(0.35,
            duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
        _rebuildMarkers();
      }
    });

    // 🔥 الحل الجذري: استماع مباشر لحركة الخريطة
    mapController.mapController.mapEventStream.listen((event) {
      if (event is MapEventMoveEnd && mounted && currentStep.value != 'none') {
        final center = mapController.mapController.camera.center;
        mapController.mapCenter.value = center;
        _lastStableCenter.value = center;
        _onMapMove(center);
      }
    });

    // ✅ تهيئة الخريطة بالموقع الصحيح
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_destination.value != null) {
        final destLatLng = _destination.value!.latLng;
        mapController.mapController.move(destLatLng, 15);
        mapController.mapCenter.value = destLatLng;
        _lastStableCenter.value = destLatLng;
        _rebuildMarkers();
      } else {
        _initializeMapToCurrentUserLocation();
      }
    });
  }

  // ✅ دالة لتهيئة الخريطة حسب الخطوة
  void _initializeMapForStep(String step) {
    LatLng? targetLocation;

    if (step == 'destination' && _destination.value != null) {
      targetLocation = _destination.value!.latLng;
    } else if (step.startsWith('edit_stop_')) {
      int idx = int.parse(step.split('_').last);
      if (idx < _additionalStops.length) {
        targetLocation = _additionalStops[idx].location;
      }
    }

    if (targetLocation != null) {
      mapController.mapController.move(targetLocation, 15);
      mapController.mapCenter.value = targetLocation;
      _lastStableCenter.value = targetLocation;

      // ✅ جلب العنوان فوراً
      Future.delayed(const Duration(milliseconds: 300), () {
        _onMapMove(targetLocation!);
      });
    }
  }

  Future<void> _initializeMapToCurrentUserLocation() async {
    try {
      final userLocation = await locationService.getCurrentLocation();
      if (userLocation != null && mounted) {
        mapController.mapController.move(userLocation, 15);
        mapController.mapCenter.value = userLocation;
        _lastStableCenter.value = userLocation;

        Future.delayed(const Duration(milliseconds: 300), () {
          _onMapMove(userLocation);
        });
      }
    } catch (e) {
      logger.e('Failed to get initial user location: $e');
    }
  }

  // ✅ دالة محسنة لمعالجة حركة الخريطة
  void _onMapMove(LatLng center) {
    if (currentStep.value == 'none') return;

    // ✅ عرض الإحداثيات فوراً كـ fallback
    centerAddress.value =
        '${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}';
    isMapMoving.value = true;

    // ✅ إلغاء أي debounce سابق
    _debounce?.cancel();

    // ✅ انتظار 150ms فقط
    _debounce = Timer(const Duration(milliseconds: 150), () async {
      if (!mounted || currentStep.value == 'none') return;

      isFetchingAddress.value = true;
      try {
        final address =
            await locationService.getAddressFromLocation(center).timeout(
                  const Duration(seconds: 2),
                  onTimeout: () => 'موقع على الخريطة',
                );

        if (mounted && currentStep.value != 'none') {
          centerAddress.value = address.isNotEmpty ? address : 'موقع محدد';
        }
      } catch (e) {
        if (mounted && currentStep.value != 'none') {
          centerAddress.value = 'موقع محدد على الخريطة';
        }
      } finally {
        if (mounted) {
          isFetchingAddress.value = false;
          isMapMoving.value = false;
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _rebuildMarkers() {
    // ✅ مسح شامل لجميع الماركرز المتعلقة بالرحلة
    mapController.markers.removeWhere((m) {
      if (m.key is ValueKey) {
        final key = (m.key as ValueKey).value.toString();
        return key == 'destination' ||
            key == 'pickup_point' ||
            key.startsWith('stop_') ||
            key.startsWith('additional_stop_') ||
            key.contains('pickup') ||
            key.contains('destination') ||
            key.contains('stop');
      }
      return false;
    });

    // ✅ إضافة ماركر نقطة الانطلاق (ثابتة)
    final pickupMarker = Marker(
      key: const ValueKey('pickup_point'),
      point: originalTrip.pickupLocation.latLng,
      width: 80,
      height: 80,
      child: EnhancedPinWidget(
        color: PinColors.getColorForStep('pickup'),
        label: 'انطلاق',
        number: '1',
        showLabel: true,
        size: 30,
      ),
    );
    mapController.markers.add(pickupMarker);

    // ✅ إضافة ماركر الوجهة إذا كانت محددة
    if (_destination.value != null) {
      final destMarker = Marker(
        key: const ValueKey('destination'),
        point: _destination.value!.latLng,
        width: 80,
        height: 80,
        child: EnhancedPinWidget(
          color: PinColors.getColorForStep('destination'),
          label: 'وصول',
          number: '${_additionalStops.length + 2}',
          showLabel: true,
          size: 30,
        ),
      );
      mapController.markers.add(destMarker);
    }

    // ✅ إضافة ماركرز النقاط الإضافية
    for (int i = 0; i < _additionalStops.length; i++) {
      final stop = _additionalStops[i];
      final stopMarker = Marker(
        key: ValueKey('stop_${stop.id}'),
        point: stop.location,
        width: 80,
        height: 80,
        child: EnhancedPinWidget(
          color: PinColors.getColorForStep('additional_stop'),
          label: 'توقف ${i + 1}',
          number: '${i + 2}',
          showLabel: true,
          size: 30,
        ),
      );
      mapController.markers.add(stopMarker);
    }

    mapController.markers.refresh();
    logger.i(
        '✅ Markers rebuilt: pickup=1, destination=${_destination.value != null}, stops=${_additionalStops.length}');
  }

  Future<void> _confirmCurrentLocation() async {
    // ✅ استخدام آخر موقع محفوظ
    final center = _lastStableCenter.value;

    if (center == null) {
      Get.snackbar('خطأ', 'يرجى تحريك الخريطة قليلاً',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    // ✅ محاولة أخيرة للحصول على عنوان نصي
    String finalAddress = centerAddress.value;

    if (finalAddress == '...' ||
        finalAddress.isEmpty ||
        finalAddress.contains('جاري') ||
        finalAddress.contains(',')) {
      isLoading.value = true;
      try {
        finalAddress =
            await locationService.getAddressFromLocation(center).timeout(
                  const Duration(seconds: 2),
                  onTimeout: () => 'موقع على الخريطة',
                );
      } catch (e) {
        finalAddress = 'موقع على الخريطة';
      } finally {
        isLoading.value = false;
      }
    }

    centerAddress.value = finalAddress;

    // ✅ إذا فشل العنوان، استخدم نص افتراضي
    if (centerAddress.value == 'لم يتمكن من تحديد العنوان' ||
        centerAddress.value == '...') {
      centerAddress.value = 'الموقع المحدد على الخريطة';
    }

    try {
      isLoading.value = true;
      final center = _lastStableCenter.value!;
      final address = centerAddress.value;

      logger.i(
          '✅ Confirming location: ${center.latitude}, ${center.longitude} - $address');

      if (currentStep.value == 'destination') {
        _destination.value = LocationPoint(
            lat: center.latitude, lng: center.longitude, address: address);
        _rebuildMarkers();
        Get.snackbar('تم', 'تم تحديث الوجهة مؤقتاً',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else if (currentStep.value == 'additional_stop') {
        if (_additionalStops.length >= 2) {
          Get.snackbar('تنبيه', 'لا يمكن إضافة أكثر من نقطتي توقف',
              backgroundColor: Colors.orange, colorText: Colors.white);
        } else {
          final newStop = AdditionalStop(
            location: center,
            address: address,
            stopNumber: _additionalStops.length + 2,
            id: 'stop_${DateTime.now().millisecondsSinceEpoch}',
          );
          _additionalStops.add(newStop);
          logger.i('✅ Added stop: ${newStop.id} - ${newStop.address}');
          _rebuildMarkers();
          Get.snackbar('تم', 'تمت إضافة نقطة توقف',
              backgroundColor: Colors.green, colorText: Colors.white);
        }
      } else if (currentStep.value.startsWith('edit_stop_')) {
        int idx = int.parse(currentStep.value.split('_').last);
        if (idx < _additionalStops.length) {
          final oldStop = _additionalStops[idx];
          _additionalStops[idx] =
              oldStop.copyWith(location: center, address: address);
          logger.i('✅ Updated stop $idx: ${_additionalStops[idx].address}');
          _rebuildMarkers();
          Get.snackbar('تم', 'تم تحديث نقطة التوقف',
              backgroundColor: Colors.green, colorText: Colors.white);
        }
      }

      currentStep.value = 'none';
      centerAddress.value = '...';
      _lastStableCenter.value = null;
    } catch (e) {
      logger.e('Error confirming location: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء تثبيت الموقع',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _confirmChanges() async {
    if (_destination.value == null) {
      Get.snackbar('خطأ', 'يجب تحديد الوجهة الجديدة',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (currentStep.value != 'none') {
      Get.snackbar('تنبيه', 'يرجى إنهاء التعديل الحالي قبل الحفظ',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    try {
      isSubmitting.value = true;

      logger.i('💾 Saving changes...');
      logger.i('   - New destination: ${_destination.value!.address}');
      logger.i('   - Stops count: ${_additionalStops.length}');

      final newAdditionalStops = _additionalStops.map((stop) {
        logger.i('   - Stop ${stop.stopNumber}: ${stop.address}');
        return stop.toMap();
      }).toList();

      final success = await tripController.updateTripDestination(
        tripId: originalTrip.id,
        newDestination: _destination.value!,
        newAdditionalStops:
            newAdditionalStops.isEmpty ? null : newAdditionalStops,
        // newWaitingTime:
        //     tripWaitingTime.value > 0 ? tripWaitingTime.value : null,
        newWaitingTime: tripWaitingTime.value, // أرسل أي قيمة حتى لو 0

      );

      if (success && mounted) {
        logger.i('✅ Changes saved successfully');
        await Future.delayed(const Duration(milliseconds: 500));
        Get.back(result: true);
      } else {
        logger.w('⚠️ Failed to save changes');
      }
    } catch (e) {
      logger.e('❌ Error confirming changes: $e');
      Get.snackbar('خطأ', 'فشل تحديث المسار، يرجى المحاولة مرة أخرى',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) isSubmitting.value = false;
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    markers.add(Marker(
      width: 70,
      height: 70,
      point: originalTrip.pickupLocation.latLng,
      child: EnhancedPinWidget(
          color: PinColors.getColorForStep('pickup'),
          label: "انطلاق",
          number: '1',
          showLabel: true,
          size: 30),
    ));

    for (int i = 0; i < _additionalStops.length; i++) {
      final stop = _additionalStops[i];
      markers.add(Marker(
        width: 70,
        height: 70,
        point: stop.location,
        child: EnhancedPinWidget(
            color: PinColors.getColorForStep('additional_stop'),
            label: "توقف ${i + 1}",
            number: '${i + 2}',
            showLabel: true,
            size: 30),
      ));
    }

    if (_destination.value != null) {
      markers.add(Marker(
        width: 70,
        height: 70,
        point: _destination.value!.latLng,
        child: EnhancedPinWidget(
            color: PinColors.getColorForStep('destination'),
            label: "وصول",
            number: '${_additionalStops.length + 2}',
            showLabel: true,
            size: 30),
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('تعديل مسار الرحلة',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Get.back()),
      ),
      body: Stack(
        children: [
          Obx(() => QuickMap.forEditing(
                mapController.mapController,
                mapController.mapCenter.value,
                _buildMarkers(),
                (camera, hasGesture) {
                  if (hasGesture && mounted && currentStep.value != 'none') {
                    // ✅ تحديث الموقع فوراً عند الحركة
                    mapController.mapCenter.value = camera.center;
                    _onMapMove(camera.center);
                  }
                },
              )),
          GoToMyLocationButton(onPressed: () {
            if (mapController.currentLocation.value != null) {
              mapController.mapController.move(
                mapController.currentLocation.value!,
                16.0,
              );
            }
          }),
          MapCenterPin(
              currentStep: currentStep, additionalStops: _additionalStops),
          LocationConfirmationPanel(
            currentStep: currentStep,
            centerAddress: centerAddress,
            isLoading: isLoading,
            isMapMoving: isMapMoving,
            isFetchingAddress: isFetchingAddress,
            onConfirm: _confirmCurrentLocation,
            additionalStops: _additionalStops,
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Obx(() {
              if (currentStep.value == 'none') return const SizedBox.shrink();
              return FloatingActionButton(
                heroTag: 'cancel_selection',
                backgroundColor: Colors.red,
                mini: true,
                onPressed: () {
                  currentStep.value = 'none';
                  centerAddress.value = '...';
                  _lastStableCenter.value = null;
                },
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              );
            }),
          ),
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.50,
            minChildSize: 0.20,
            maxChildSize: 0.50,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              child: Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade500,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(0, -2))
                        ]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2)),
                        ),
                        EditModeButtons(
                          currentStep: currentStep,
                          additionalStopsCount: _additionalStops.length,
                          onSetMode: (mode) {
                            currentStep.value = mode;
                            if (mode == 'destination' &&
                                _destination.value != null) {
                              mapController.mapController
                                  .move(_destination.value!.latLng, 15);
                              Future.delayed(const Duration(milliseconds: 300),
                                  () {
                                _lastStableCenter.value =
                                    _destination.value!.latLng;
                                _onMapMove(_destination.value!.latLng);
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 5),
                        EditStopsList(
                          additionalStops: _additionalStops,
                          currentStep: currentStep,
                          onEdit: (index) {
                            if (index == -1) {
                              currentStep.value = 'none';
                            } else {
                              currentStep.value = 'edit_stop_$index';
                              mapController.mapController
                                  .move(_additionalStops[index].location, 15);
                              Get.snackbar('وضع التعديل',
                                  'حرك الخريطة واختر الموقع الجديد',
                                  backgroundColor: const Color(0xFF2E7D32),
                                  colorText: Colors.white);
                            }
                          },
                          onDelete: (index) {
                            _additionalStops.removeAt(index);
                            stopWaitingTimes.remove(index);
                            if (currentStep.value == 'edit_stop_$index') {
                              currentStep.value = 'none';
                            }
                            Get.snackbar('تم الحذف', 'تم حذف نقطة التوقف',
                                backgroundColor: Colors.red,
                                colorText: Colors.white);
                          },
                        ),
                        const Text(
                          'وقت الانتظار الإضافي للرحلة',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 5),
                        EditWaitingTimeSection(
                          tripWaitingTime: tripWaitingTime,
                        ),
                        const SizedBox(height: 5),
                        ElevatedButton.icon(
                          onPressed:
                              isSubmitting.value ? null : _confirmChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 3,
                          ),
                          icon: isSubmitting.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : const Icon(Icons.check_circle, size: 24),
                          label: Text(
                              isSubmitting.value
                                  ? 'جاري الحفظ...'
                                  : 'حفظ وإرسال التعديل',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
