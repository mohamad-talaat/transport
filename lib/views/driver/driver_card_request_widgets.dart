import 'package:flutter/material.dart';
import 'package:transport_app/controllers/driver_controller.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/utils/pin_colors.dart';
import 'package:transport_app/views/shared/trip_tracking_shared_widgets.dart';

class TripRequestWidgets {
  static Widget buildTripRequestCard({
    required TripModel trip,
    required int index,
    required Future<UserModel?> Function(String riderId) getRiderInfo,
    required PageController tripRequestsController,
    required ValueNotifier<bool> isExpansionTileOpen,
  }) {
return Padding(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
  child: Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: SingleChildScrollView( // 👈 أضف دي هنا
      physics: const BouncingScrollPhysics(),
      child: FutureBuilder<UserModel?>(
        future: getRiderInfo(trip.riderId!),
        builder: (context, snapshot) {
          final rider = snapshot.data;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRiderInfoSection(rider, trip),
              const SizedBox(height: 2),
              _buildTripLocations(trip),
              const SizedBox(height: 2),
              buildExtraOptions(
                trip: trip,
                isExpansionTileOpen: isExpansionTileOpen,
              ),
              const Divider(height: 5, thickness: 1),

              _buildTripStats(trip),
               HoldToAcceptButton(trip: trip),
            ],
          );
        },
      ),
    ),
  ),
);
}

  static Widget _buildRiderInfoSection(UserModel? rider, TripModel trip) {
    return Row(
      children: [
        // CircleAvatar(
        //   radius: 28,
        //   backgroundImage: rider?.profileImage != null
        //       ? NetworkImage(rider!.profileImage!)
        //       : null,
        //   backgroundColor: Colors.blue.shade200,
        //   child: rider?.profileImage == null
        //       ? const Icon(Icons.person, size: 32, color: Colors.white)
        //       : null,
        // ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rider?.name ?? 'راكب غير معروف',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1F2937),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Row(
              //   children: [
              //     Icon(
              //       trip.paymentMethod == 'cash'
              //           ? Icons.payments_outlined
              //           : Icons.credit_card,
              //       size: 16,
              //       color: Colors.grey.shade600,
              //     ),
              //     const SizedBox(width: 4),
              //     Text(
              //       trip.paymentMethod == 'cash' ? 'دفع كاش' : 'دفع إلكتروني',
              //       style: TextStyle(
              //         fontSize: 13,
              //         color: Colors.grey.shade600,
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
     
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade600],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                TripTrackingSharedWidgets().getServiceIcon(trip.riderType),
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                 TripTrackingSharedWidgets().getServiceName(trip.riderType),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
           
      ],
    );
  }

  static formatDuration(int minutes) {
    int totalMinutes = minutes.round();

    if (totalMinutes < 60) {
      return "$totalMinutes دقيقة";
    } else {
      int hours = totalMinutes ~/ 60;
      int remainingMinutes = totalMinutes % 60;

      if (remainingMinutes == 0) {
        return "$hours ${hours == 1 ? 'ساعة' : 'ساعات'}";
      } else {
        return "$hours ${hours == 1 ? 'ساعة' : 'ساعات'} و $remainingMinutes دقيقة";
      }
    }
  }

  static Widget _buildTripLocations(TripModel trip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          buildLocationRow(
            PinColors.pickup,
            trip.pickupLocation.address,
          ),
          const SizedBox(height: 3),
          buildLocationRow(
            PinColors.destination,
            trip.destinationLocation.address,
          ),
        ],
      ),
    );
  }

  static Widget _buildTripStats(TripModel trip) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          icon: Icons.straighten,
          label: 'المسافة',
          value: '${trip.distance.toStringAsFixed(1)} كم',
          color: Colors.blue,
        ),
        _buildStatItem(
          icon: Icons.access_time,
          label: 'المدة',
          value: formatDuration(trip.estimatedDuration),
          color: Colors.orange,
        ),
        _buildStatItem(
          icon: Icons.attach_money,
          label: 'الأجرة',
          value: '${trip.fare.toStringAsFixed(0)} د.ع',
          color: Colors.green,
        ),
      ],
    );
  }

  static Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static Widget buildLocationRow(
    String step,
    String address, {
    int stopIndex = 0,
  }) {
    final color = PinColors.getColorForStep(step);
    final baseLabel = PinColors.getLabelForStep(step);

    String label;
    if (step == 'additional_stop' || step == "additionalStops") {
      label = "$baseLabel ${stopIndex + 2}";
    } else {
      label = baseLabel;
    }

    return Row(
      children: [
        Container(
          width: 50,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static Widget buildExtraOptions({
    required TripModel trip,
    required ValueNotifier<bool> isExpansionTileOpen,
  }) {
    int optionsCount = 0;
    if (trip.additionalStops.isNotEmpty) optionsCount++;
    if (trip.waitingTime > 0) optionsCount++;
    if (trip.isRush) optionsCount++;
    if (trip.isRoundTrip) optionsCount++;

    if (optionsCount == 0) {
      return const SizedBox.shrink();
    }

    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8, bottom: 1),
        leading: Icon(
          Icons.info_outline,
          color: Colors.blue.shade700,
          size: 22,
        ),
        title: Row(
          children: [
            Text(
              "خيارات إضافية",
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$optionsCount',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onExpansionChanged: (bool expanded) {
          isExpansionTileOpen.value = expanded; // ✅ تحديث الـ ValueNotifier هنا
        },
        children: [
          // لو حبيت يكون فيه SingleChildScrollView داخل ExpansionTile لو المحتوى كتير
          // ممكن تضيفه هنا:
          // SingleChildScrollView(
          //   physics: const NeverScrollableScrollPhysics(), // مهم لمنع تداخل التمرير
          //   child: Column(
          //     children: [
          if (trip.additionalStops.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "📍 نقاط إضافية:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            ...trip.additionalStops.asMap().entries.map((entry) {
              final index = entry.key;
              final stop = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                       stop.address.isNotEmpty ? stop.address : 'عنوان غير محدد',
                         style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 12, thickness: 0.5),
          ],
          if (trip.waitingTime > 0) ...[
            _buildCompactDetailRow(
              icon: Icons.schedule,
              iconColor: Colors.deepPurple,
              label: 'وقت الانتظار',
              value: '${trip.waitingTime} دقيقة',
            ),
            const SizedBox(height: 6),
          ],
          if (trip.isRush) ...[
            _buildCompactDetailRow(
              icon: Icons.flash_on,
              iconColor: Colors.red,
              label: 'رحلة مستعجلة',
              value: 'أولوية عالية',
              isHighlight: true,
            ),
            const SizedBox(height: 6),
          ],
          if (trip.isRoundTrip) ...[
            _buildCompactDetailRow(
              icon: Icons.repeat,
              iconColor: Colors.purple,
              label: 'نوع الرحلة',
              value: 'ذهاب وعودة',
              isHighlight: true,
            ),
            const SizedBox(height: 6),
          ],
          _buildCompactDetailRow(
            icon: Icons.info_outline,
            iconColor: Colors.blueGrey,
            label: 'حالة الرحلة',
            value: _getTripStatusText(trip.status),
          ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  static Widget _buildCompactDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      decoration: BoxDecoration(
        color: isHighlight
            ? iconColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighlight
              ? iconColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isHighlight ? iconColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  static String _getTripStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return 'معلقة';
      case TripStatus.accepted:
        return 'مقبولة';
      case TripStatus.inProgress:
        return 'جارية';
      case TripStatus.completed:
        return 'مكتملة';
      case TripStatus.cancelled:
        return 'ملغاة';
      default:
        return status.toString();
    }
  }
}

class HoldToAcceptButton extends StatefulWidget {
  final TripModel trip;

  const HoldToAcceptButton({super.key, required this.trip});

  @override
  State<HoldToAcceptButton> createState() => _HoldToAcceptButtonState();
}

class _HoldToAcceptButtonState extends State<HoldToAcceptButton>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _holdController;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..forward();

    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isCompleted) {
        _isCompleted = true;
        DriverController.to.acceptTrip(widget.trip);
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _holdController.forward();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_isCompleted) {
      _holdController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    const double height = 40;

    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([_progressController, _holdController]),
        builder: (context, child) {
          final progressFill = _progressController.value;
          final holdFill = _holdController.value;

          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 153, 0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  FractionallySizedBox(
                    widthFactor: progressFill,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange, Colors.redAccent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: holdFill,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                  const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "اضغط مطولاً للقبول",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}