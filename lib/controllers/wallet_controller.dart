import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/views/rider/rider_wallet_view.dart';

class WalletController extends GetxController {
  static WalletController get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  final RxBool isLoading = false.obs;
  final RxBool isLoadingTransactions = false.obs;

  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;

  DocumentSnapshot? _lastDocument;
  final RxBool hasMoreTransactions = true.obs;
  final int _pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    loadTransactions();
  }

  Future<void> loadTransactions({bool refresh = false}) async {
    if (refresh) {
      _lastDocument = null;
      transactions.clear();
      hasMoreTransactions.value = true;
    }

    if (isLoadingTransactions.value || !hasMoreTransactions.value) return;

    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;

    isLoadingTransactions.value = true;

    try {
      Query query = _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMoreTransactions.value = false;
        return;
      }

      final List<TransactionModel> newTransactions = snapshot.docs
          .map((doc) => TransactionModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      if (refresh) {
        transactions.assignAll(newTransactions);
      } else {
        transactions.addAll(newTransactions);
      }

      _lastDocument = snapshot.docs.last;
      hasMoreTransactions.value = snapshot.docs.length == _pageSize;
    } catch (e) {
      logger.e('خطأ في تحميل العمليات المالية: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تحميل العمليات المالية',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoadingTransactions.value = false;
    }
  }

  Future<void> refreshTransactions() async {
    await loadTransactions(refresh: true);
  }

  Future<void> loadMoreTransactions() async {
    await loadTransactions();
  }

  Future<void> redeemVoucher(String voucherCode) async {
    if (voucherCode.trim().isEmpty) {
      Get.snackbar(
        'خطأ',
        'يرجى إدخال كود الشحن',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;

    isLoading.value = true;

    try {
      final voucherQuery = await _firestore
          .collection('vouchers')
          .where('code', isEqualTo: voucherCode.toUpperCase())
          .where('isUsed', isEqualTo: false)
          .limit(1)
          .get();

      if (voucherQuery.docs.isEmpty) {
        Get.snackbar(
          'كود غير صحيح',
          'كود الشحن غير صحيح أو مستخدم من قبل',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final voucherDoc = voucherQuery.docs.first;
      final voucherData = voucherDoc.data();
      final amount = (voucherData['amount'] ?? 0.0).toDouble();

      await _firestore.runTransaction((transaction) async {
        transaction.update(voucherDoc.reference, {
          'isUsed': true,
          'usedBy': userId,
          'usedAt': FieldValue.serverTimestamp(),
        });

        final userRef = _firestore.collection('users').doc(userId);
        final userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists) {
          throw 'المستخدم غير موجود';
        }

        final currentBalance =
            (userSnapshot.data()?['balance'] ?? 0.0).toDouble();
        final newBalance = currentBalance + amount;

        transaction.update(userRef, {
          'balance': newBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        final transactionRef = _firestore.collection('transactions').doc();
        transaction.set(transactionRef, {
          'userId': userId,
          'amount': amount,
          'type': 'credit',
          'status': 'completed',
          'description': 'شحن رصيد بكود: $voucherCode',
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {
            'voucherCode': voucherCode,
            'voucherId': voucherDoc.id,
          },
        });
      });

      if (_authController.currentUser.value != null) {
        _authController.currentUser.value!.balance =
            _authController.currentUser.value!.balance + amount;
        _authController.currentUser.refresh();
      }

      refreshTransactions();

      Get.snackbar(
        'تم بنجاح',
        'تم إضافة ${amount.toStringAsFixed(2)} د.ع إلى رصيدك',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      logger.e('خطأ في استخدام كود الشحن: $e');
      Get.snackbar(
        'خطأ',
        'فشل في استخدام كود الشحن. يرجى المحاولة مرة أخرى',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createTripPayment({
    required String tripId,
    required double amount,
    required String description,
  }) async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) return false;

    isLoading.value = true;

    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userSnapshot = await userRef.get();

      if (!userSnapshot.exists) {
        throw 'المستخدم غير موجود';
      }

      final currentBalance =
          (userSnapshot.data()?['balance'] ?? 0.0).toDouble();

      if (currentBalance < amount) {
        Get.snackbar(
          'رصيد غير كافي',
          'رصيدك الحالي غير كافي لدفع تكلفة الرحلة',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      await _firestore.runTransaction((transaction) async {
        final newBalance = currentBalance - amount;

        transaction.update(userRef, {
          'balance': newBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        final transactionRef = _firestore.collection('transactions').doc();
        transaction.set(transactionRef, {
          'userId': userId,
          'amount': amount,
          'type': 'trip_payment',
          'status': 'completed',
          'description': description,
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {
            'tripId': tripId,
          },
        });
      });

      if (_authController.currentUser.value != null) {
        _authController.currentUser.value!.balance =
            (_authController.currentUser.value!.balance ?? 0.0) - amount;
        _authController.currentUser.refresh();
      }

      refreshTransactions();

      return true;
    } catch (e) {
      logger.e('خطأ في إنشاء عملية الدفع: $e');
      Get.snackbar(
        'خطأ في الدفع',
        'فشل في دفع تكلفة الرحلة',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createRefund({
    required String tripId,
    required double amount,
    required String reason,
  }) async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null) return;

    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists) {
          throw 'المستخدم غير موجود';
        }

        final currentBalance =
            (userSnapshot.data()?['balance'] ?? 0.0).toDouble();
        final newBalance = currentBalance + amount;

        transaction.update(userRef, {
          'balance': newBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        final transactionRef = _firestore.collection('transactions').doc();
        transaction.set(transactionRef, {
          'userId': userId,
          'amount': amount,
          'type': 'refund',
          'status': 'completed',
          'description': 'استرداد: $reason',
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {
            'tripId': tripId,
            'reason': reason,
          },
        });
      });

      if (_authController.currentUser.value != null) {
        _authController.currentUser.value!.balance =
            _authController.currentUser.value!.balance + amount;
        _authController.currentUser.refresh();
      }

      refreshTransactions();

      Get.snackbar(
        'تم الاسترداد',
        'تم إضافة ${amount.toStringAsFixed(2)} د.ع إلى رصيدك',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.e('خطأ في عملية الاسترداد: $e');
      Get.snackbar(
        'خطأ',
        'فشل في عملية الاسترداد',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  bool hasEnoughBalance(double amount) {
    final currentBalance = _authController.currentUser.value?.balance ?? 0.0;
    return currentBalance >= amount;
  }

  double get currentBalance {
    return _authController.currentUser.value?.balance ?? 0.0;
  }

  Future<VoucherModel?> validateVoucher(String voucherCode) async {
    try {
      final voucherQuery = await _firestore
          .collection('vouchers')
          .where('code', isEqualTo: voucherCode.toUpperCase())
          .where('isUsed', isEqualTo: false)
          .limit(1)
          .get();

      if (voucherQuery.docs.isEmpty) {
        return null;
      }

      final voucherDoc = voucherQuery.docs.first;
      return VoucherModel.fromMap(voucherDoc.data(), voucherDoc.id);
    } catch (e) {
      logger.e('خطأ في التحقق من كود الشحن: $e');
      return null;
    }
  }
}

class VoucherModel {
  final String id;
  final String code;
  final double amount;
  final bool isUsed;
  final String? usedBy;
  final DateTime? usedAt;
  final DateTime createdAt;
  final DateTime? expiresAt;

  VoucherModel({
    required this.id,
    required this.code,
    required this.amount,
    required this.isUsed,
    this.usedBy,
    this.usedAt,
    required this.createdAt,
    this.expiresAt,
  });

  factory VoucherModel.fromMap(Map<String, dynamic> map, String id) {
    return VoucherModel(
      id: id,
      code: map['code'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      isUsed: map['isUsed'] ?? false,
      usedBy: map['usedBy'],
      usedAt: map['usedAt']?.toDate(),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      expiresAt: map['expiresAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'amount': amount,
      'isUsed': isUsed,
      'usedBy': usedBy,
      'usedAt': usedAt,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}
