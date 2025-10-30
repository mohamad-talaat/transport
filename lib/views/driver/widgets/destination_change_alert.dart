import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/controllers/trip_controller.dart';

class DestinationChangeAlert extends StatelessWidget {
  // final TripModel trip;

  const DestinationChangeAlert({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tripController = Get.find<TripController>();
    final driverController = Get.find<DriverController>(); // أو TripController

    // // لو مفيش تغيير في الوجهة أو السائق وافق بالفعل
    // if (!trip.destinationChanged || trip.driverApproved != null) {
    //   return const SizedBox.shrink();
    // }

    return Obx(() {
      final trip = driverController.currentTrip.value;

      // لو مفيش رحلة أو تغيير في الوجهة أو السائق وافق بالفعل
      if (trip == null ||
          !trip.destinationChanged ||
          trip.driverApproved != null) {
        return const SizedBox.shrink();
      }
      return Positioned(
        top: 15,
        left: 16,
        right: 16,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان الرئيسي
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_location_alt,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "تم اجراء تعديل علي رحلتك",
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'قام الراكب بتعديل الرحلة',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 10),

              // // ✅ عرض الوجهة الجديدة
              // _buildLocationItem(
              //   icon: Icons.location_on,
              //   label: 'الوجهة الجديدة',
              //   address: trip.destinationLocation.address,
              //   color: PinColors.getColorForStep('destination'),
              // ),

              // // ✅ عرض النقاط الإضافية إذا وجدت (الحد الأقصى 2)
              // if (trip.additionalStops.isNotEmpty) ...[
              //   const SizedBox(height: 2),
              //   ...trip.additionalStops
              //       .take(2)
              //       .toList()
              //       .asMap()
              //       .entries
              //       .map((entry) {
              //     final index = entry.key;
              //     final stop = entry.value;
              //     return Padding(
              //       padding: const EdgeInsets.only(top: 4),
              //       child: _buildLocationItem(
              //         icon: Icons.add_location_alt,
              //         label: 'نقطة توقف ${index + 1}',
              //         address: stop.address,
              //         color: PinColors.getColorForStep('additional_stop'),
              //       ),
              //     );
              //   }),
              // ],

              // const SizedBox(height: 6),

              // // ✅ عرض التفاصيل المالية والمسافة
              // Container(
              //   padding:
              //       const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              //   decoration: BoxDecoration(
              //     color: Colors.blue.shade50,
              //     borderRadius: BorderRadius.circular(10),
              //     border: Border.all(color: Colors.blue.shade200),
              //   ),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceAround,
              //     children: [
              //       _buildInfoChip(
              //         icon: Icons.route,
              //         label: 'المسافة',
              //         value: '${trip.distance.toStringAsFixed(1)} كم',
              //         color: Colors.blue,
              //       ),
              //       Container(
              //         width: 1,
              //         height: 30,
              //         color: Colors.blue.shade300,
              //       ),
              //       _buildInfoChip(
              //         icon: Icons.access_time,
              //         label: 'المدة',
              //         value: '${trip.estimatedDuration} دقيقة',
              //         color: Colors.orange,
              //       ),
              //       Container(
              //         width: 1,
              //         height: 30,
              //         color: Colors.blue.shade300,
              //       ),
              //       _buildInfoChip(
              //         icon: Icons.payments,
              //         label: 'السعر',
              //         value:
              //             '${(trip.newFare ?? 55555555).toStringAsFixed(0)} د.ع',
              //         color: Colors.green,
              //       ),
              //       Container(
              //         width: 1,
              //         height: 30,
              //         color: Colors.blue.shade300,
              //       ),
              //       _buildInfoChip(
              //         icon: Icons.transfer_within_a_station,
              //         label: 'الانتظار',
              //         value:
              //             '${(trip.waitingTime ?? trip.waitingTime) ?? 0} دقيقة',
              //         color: Colors.green,
              //       ),
              //     ],
              //   ),
              // ),

              const SizedBox(height: 6),

              // أزرار الموافقة والرفض
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        tripController.driverApproveDestinationChange(
                            trip.id, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text(
                        'موافق',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        tripController.driverApproveDestinationChange(
                            trip.id, false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.cancel, size: 20),
                      label: const Text(
                        'رفض',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // Widget _buildLocationItem({
  //   required IconData icon,
  //   required String label,
  //   required String address,
  //   required Color color,
  // }) {
  //   return Container(
  //     padding: const EdgeInsets.all(1),
  //     decoration: BoxDecoration(
  //       color: color.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(10),
  //       border: Border.all(color: color.withOpacity(0.3)),
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 5),
  //           decoration: BoxDecoration(
  //             color: color.withOpacity(0.2),
  //             shape: BoxShape.circle,
  //           ),
  //           child: Icon(
  //             icon,
  //             color: color,
  //             size: 18,
  //           ),
  //         ),
  //         const SizedBox(width: 10),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 label,
  //                 style: TextStyle(
  //                   fontSize: 11,
  //                   fontWeight: FontWeight.w600,
  //                   color: Colors.grey.shade700,
  //                 ),
  //               ),
  //               const SizedBox(height: 2),
  //               Text(
  //                 address,
  //                 maxLines: 2,
  //                 overflow: TextOverflow.ellipsis,
  //                 style: const TextStyle(
  //                   fontSize: 13,
  //                   fontWeight: FontWeight.w500,
  //                   color: Colors.black87,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildInfoChip({
  //   required IconData icon,
  //   required String label,
  //   required String value,
  //   required Color color,
  // }) {
  //   return Column(
  //     children: [
  //       Icon(icon, color: color, size: 15),
  //       //const SizedBox(height: 1),
  //       Text(
  //         label,
  //         style: TextStyle(
  //           fontSize: 10,
  //           color: Colors.grey.shade600,
  //         ),
  //       ),
  //       // const SizedBox(height: 2),
  //       Text(
  //         value,
  //         style: TextStyle(
  //           fontSize: 12,
  //           fontWeight: FontWeight.bold,
  //           color: color,
  //         ),
  //       ),
  //     ],
  //   );
  // }


}
