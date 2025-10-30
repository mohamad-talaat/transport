import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/models/discount_code_model.dart';
import 'package:transport_app/main.dart';

class DiscountCodeService extends GetxService {
  static DiscountCodeService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = AuthController.to;

  Future<({bool isValid, String? message, DiscountCodeModel? code})>
      validateDiscountCode(
    String codeText,
    double tripAmount,
  ) async {
    try {
      final user = _authController.currentUser.value;
      if (user == null) {
        return (isValid: false, message: 'يجب تسجيل الدخول أولاً', code: null);
      }

      final accountAge = DateTime.now().difference(user.createdAt).inDays;
      if (accountAge < 10) {
        return (
          isValid: false,
          message: 'يجب أن يمر 10 أيام على إنشاء الحساب لاستخدام أكواد الخصم',
          code: null
        );
      }

      final querySnapshot = await _firestore
          .collection('discount_codes')
          .where('code', isEqualTo: codeText.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return (isValid: false, message: 'كود الخصم غير صحيح', code: null);
      }

      final discountCode = DiscountCodeModel.fromMap(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );

      if (!discountCode.isValid) {
        if (!discountCode.isActive) {
          return (isValid: false, message: 'كود الخصم غير نشط', code: null);
        }
        if (discountCode.currentUses >= discountCode.maxUses) {
          return (
            isValid: false,
            message: 'تم استخدام الكود بالكامل',
            code: null
          );
        }
        if (DateTime.now().isAfter(discountCode.expiryDate)) {
          return (isValid: false, message: 'انتهت صلاحية الكود', code: null);
        }
      }

      if (!discountCode.canBeUsedBy(user.id)) {
        return (
          isValid: false,
          message: 'لا يمكنك استخدام هذا الكود',
          code: null
        );
      }

      if (tripAmount < discountCode.minimumAmount) {
        return (
          isValid: false,
          message:
              'الحد الأدنى لاستخدام الكود ${discountCode.minimumAmount.toInt()} د.ع',
          code: null
        );
      }

      final usageCheck = await _firestore
          .collection('discount_code_usage')
          .where('userId', isEqualTo: user.id)
          .where('codeId', isEqualTo: discountCode.id)
          .limit(1)
          .get();

      if (usageCheck.docs.isNotEmpty) {
        return (
          isValid: false,
          message: 'لقد استخدمت هذا الكود مسبقاً',
          code: null
        );
      }

      return (isValid: true, message: null, code: discountCode);
    } catch (e) {
      logger.e('خطأ في التحقق من كود الخصم: $e');
      return (
        isValid: false,
        message: 'حدث خطأ، يرجى المحاولة مرة أخرى',
        code: null
      );
    }
  }

  Future<({bool success, double newAmount, String? message})> applyDiscountCode(
    String codeText,
    double originalAmount,
    String tripId,
  ) async {
    try {
      final validation = await validateDiscountCode(codeText, originalAmount);

      if (!validation.isValid || validation.code == null) {
        return (
          success: false,
          newAmount: originalAmount,
          message: validation.message
        );
      }

      final discountCode = validation.code!;
      final discountAmount = discountCode.calculateDiscount(originalAmount);
      final newAmount = originalAmount - discountAmount;

      await _recordCodeUsage(discountCode, tripId, discountAmount);

      await _firestore
          .collection('discount_codes')
          .doc(discountCode.id)
          .update({
        'currentUses': FieldValue.increment(1),
      });

      logger.i(
          '✅ تم تطبيق كود الخصم ${discountCode.code}: خصم ${discountAmount.toInt()} د.ع');

      return (
        success: true,
        newAmount: newAmount,
        message: 'تم تطبيق خصم ${discountAmount.toInt()} د.ع'
      );
    } catch (e) {
      logger.e('خطأ في تطبيق كود الخصم: $e');
      return (
        success: false,
        newAmount: originalAmount,
        message: 'حدث خطأ في تطبيق الكود'
      );
    }
  }

  Future<void> _recordCodeUsage(
    DiscountCodeModel code,
    String tripId,
    double discountAmount,
  ) async {
    final user = _authController.currentUser.value;
    if (user == null) return;

    await _firestore.collection('discount_code_usage').add({
      'userId': user.id,
      'codeId': code.id,
      'code': code.code,
      'tripId': tripId,
      'discountAmount': discountAmount,
      'usedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> createDiscountCode({
    required String code,
    required double discountAmount,
    required double minimumAmount,
    required int maxUses,
    required DateTime expiryDate,
    String? description,
    List<String>? applicableUserIds,
  }) async {
    try {
      final user = _authController.currentUser.value;
      if (user == null) return null;

      final docRef = await _firestore.collection('discount_codes').add({
        'code': code.toUpperCase(),
        'discountAmount': discountAmount,
        'minimumAmount': minimumAmount,
        'maxUses': maxUses,
        'currentUses': 0,
        'expiryDate': Timestamp.fromDate(expiryDate),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.id,
        'description': description,
        'applicableUserIds': applicableUserIds ?? [],
      });

      logger.i('✅ تم إنشاء كود خصم جديد: $code');
      return docRef.id;
    } catch (e) {
      logger.e('خطأ في إنشاء كود الخصم: $e');
      return null;
    }
  }

  Future<List<DiscountCodeModel>> getActiveDiscountCodes() async {
    try {
      final querySnapshot = await _firestore
          .collection('discount_codes')
          .where('isActive', isEqualTo: true)
          .where('expiryDate', isGreaterThan: FieldValue.serverTimestamp())
          .get();

      return querySnapshot.docs
          .map((doc) => DiscountCodeModel.fromMap(doc.data(), doc.id))
          .where((code) => code.currentUses < code.maxUses)
          .toList();
    } catch (e) {
      logger.e('خطأ في جلب أكواد الخصم: $e');
      return [];
    }
  }

  Future<bool> deactivateDiscountCode(String codeId) async {
    try {
      await _firestore.collection('discount_codes').doc(codeId).update({
        'isActive': false,
      });
      return true;
    } catch (e) {
      logger.e('خطأ في إلغاء تفعيل كود الخصم: $e');
      return false;
    }
  }
}
