import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/controllers/my_map_controller.dart';
import 'package:transport_app/routes/app_routes.dart';

class BookTripButton extends StatelessWidget {
  final MyMapController mapController;
  final RxString paymentMethod;
  final RxDouble totalFare;
  final AuthController authController;
  final Function({bool isRush}) onRequestTrip;
  final Function(String message) onShowError;

  const BookTripButton({
    super.key,
    required this.mapController,
    required this.paymentMethod,
    required this.totalFare,
    required this.authController,
    required this.onRequestTrip,
    required this.onShowError,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () async {
          if (!mapController.isPickupConfirmed.value ||
              !mapController.isDestinationConfirmed.value) {
            onShowError('يرجى تحديد نقطة الانطلاق والوصول');
            return;
          }

          if (paymentMethod.value == 'app') {
            final user = authController.currentUser.value;
            if (user == null || (user.balance) < totalFare.value) {
              onShowError('رصيدك غير كافٍ، سيتم تحويلك لشحن المحفظة');
              Get.toNamed(AppRoutes.RIDER_WALLET);
              return;
            }
          }

          await onRequestTrip();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Colors.orange.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.local_taxi, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text(
              'طلب الرحلة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
