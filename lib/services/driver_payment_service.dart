import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import '../main.dart';

class DriverPaymentService extends GetxService {
  static DriverPaymentService get to => Get.find();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // متغيرات تفاعلية للأرباح
  final Rx<DriverEarningsModel?> currentEarnings = Rx<DriverEarningsModel?>(null);
  final RxList<PaymentModel> recentPayments = <PaymentModel>[].obs;
  final RxBool isLoading = false.obs;

  /// حساب أرباح السائق من رحلة
  Future<double> calculateTripEarnings({
    required String tripId,
    required String driverId,
  }) async {
    try {
      final tripDoc = await _firestore.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) return 0.0;

      final tripData = tripDoc.data()!;
      final tripFare = (tripData['fare'] ?? 0.0).toDouble();
      
      // حساب العمولة الديناميكية
      final commissionRate = _calculateCommissionRate(tripData);
      final commission = tripFare * commissionRate;
      final driverEarnings = tripFare - commission;

      return driverEarnings;
    } catch (e) {
      logger.w('خطأ في حساب أرباح الرحلة: $e');
      return 0.0;
    }
  }

  /// حساب معدل العمولة الديناميكي
  double _calculateCommissionRate(Map<String, dynamic> tripData) {
    final distance = (tripData['distance'] ?? 0.0).toDouble();
    final fare = (tripData['fare'] ?? 0.0).toDouble();
    
    // عمولة أساسية 15%
    double baseCommission = 0.15;
    
    // خصم إضافي للمسافات القصيرة
    if (distance < 5.0) {
      baseCommission += 0.05;
    }
    
    // خصم أقل للرحلات باهظة الثمن
    if (fare > 100.0) {
      baseCommission -= 0.03;
    }
    
    return baseCommission.clamp(0.10, 0.25);
  }

  /// إنشاء عملية دفع للسائق
  Future<PaymentModel?> createDriverPayment({
    required String tripId,
    required String driverId,
    required double amount,
  }) async {
    try {
      isLoading.value = true;
      
      final paymentId = 'payment_${DateTime.now().millisecondsSinceEpoch}';
      
      final payment = PaymentModel(
        id: paymentId,
        userId: driverId,
        tripId: tripId,
        amount: amount,
        status: PaymentStatus.pending,
        method: PaymentMethod.wallet,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('payments').doc(paymentId).set(payment.toMap());
      
      final processedPayment = await _processPayment(payment);
      await _updateDriverEarnings(driverId, amount);
      
      recentPayments.insert(0, processedPayment);
      if (recentPayments.length > 10) {
        recentPayments.removeLast();
      }

      return processedPayment;
    } catch (e) {
      logger.w('خطأ في إنشاء عملية الدفع: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// معالجة الدفع (مبسطة - فقط من المحفظة)
  Future<PaymentModel> _processPayment(PaymentModel payment) async {
    try {
      // تحديث رصيد السائق
      await _firestore.collection('users').doc(payment.userId).update({
        'balance': FieldValue.increment(payment.amount),
      });

      final updatedPayment = payment.copyWith(
        status: PaymentStatus.completed,
        completedAt: DateTime.now(),
        transactionId: 'EARNINGS_${DateTime.now().millisecondsSinceEpoch}',
        gatewayResponse: 'تم إضافة الأرباح بنجاح',
      );

      await _firestore.collection('payments').doc(payment.id).update(updatedPayment.toMap());
      return updatedPayment;
    } catch (e) {
      return payment.copyWith(
        status: PaymentStatus.failed,
        gatewayResponse: 'فشل في معالجة الدفع: $e',
      );
    }
  }

  /// تحديث أرباح السائق
  Future<void> _updateDriverEarnings(String driverId, double amount) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      final earningsDoc = await _firestore.collection('driver_earnings').doc(driverId).get();

      if (earningsDoc.exists) {
        final currentData = earningsDoc.data()!;
        
        await _firestore.collection('driver_earnings').doc(driverId).update({
          'totalEarnings': FieldValue.increment(amount),
          'totalTrips': FieldValue.increment(1),
          'lastUpdated': Timestamp.now(),
        });
      } else {
        final newEarnings = DriverEarningsModel(
          driverId: driverId,
          totalEarnings: amount,
          todayEarnings: amount,
          weekEarnings: amount,
          monthEarnings: amount,
          totalTrips: 1,
          todayTrips: 1,
          weekTrips: 1,
          monthTrips: 1,
          lastUpdated: now,
        );

        await _firestore.collection('driver_earnings').doc(driverId).set(newEarnings.toMap());
      }

      await loadDriverEarnings(driverId);
    } catch (e) {
      logger.w('خطأ في تحديث أرباح السائق: $e');
    }
  }

  /// تحميل أرباح السائق
  Future<void> loadDriverEarnings(String driverId) async {
    try {
      final earningsDoc = await _firestore.collection('driver_earnings').doc(driverId).get();

      if (earningsDoc.exists) {
        currentEarnings.value = DriverEarningsModel.fromMap(earningsDoc.data()!);
      } else {
        currentEarnings.value = DriverEarningsModel(
          driverId: driverId,
          totalEarnings: 0.0,
          todayEarnings: 0.0,
          weekEarnings: 0.0,
          monthEarnings: 0.0,
          totalTrips: 0,
          todayTrips: 0,
          weekTrips: 0,
          monthTrips: 0,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      logger.w('خطأ في تحميل أرباح السائق: $e');
    }
  }

  /// تحميل المدفوعات الأخيرة
  Future<void> loadRecentPayments(String driverId) async {
    try {
      final paymentsQuery = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      recentPayments.value = paymentsQuery.docs
          .map((doc) => PaymentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      logger.w('خطأ في تحميل المدفوعات الأخيرة: $e');
    }
  }

  /// الحصول على إحصائيات السائق
  Map<String, dynamic> getDriverStats() {
    final earnings = currentEarnings.value;
    if (earnings == null) {
      return {
        'totalEarnings': 0.0,
        'todayEarnings': 0.0,
        'weekEarnings': 0.0,
        'monthEarnings': 0.0,
        'totalTrips': 0,
        'todayTrips': 0,
        'weekTrips': 0,
        'monthTrips': 0,
      };
    }

    return {
      'totalEarnings': earnings.totalEarnings,
      'todayEarnings': earnings.todayEarnings,
      'weekEarnings': earnings.weekEarnings,
      'monthEarnings': earnings.monthEarnings,
      'totalTrips': earnings.totalTrips,
      'todayTrips': earnings.todayTrips,
      'weekTrips': earnings.weekTrips,
      'monthTrips': earnings.monthTrips,
    };
  }
}
