// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import 'package:logger/logger.dart';
// import '../models/discount_code_model.dart';

// class DiscountCodeService extends GetxService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final Logger _logger = Logger();

//   static const String discountCodesCollection = 'discount_codes';
//   static const String usedCodesCollection = 'used_codes';

//   // متغيرات تفاعلية
//   final RxList<DiscountCodeModel> availableCodes = <DiscountCodeModel>[].obs;
//   final RxList<DiscountCodeModel> usedCodes = <DiscountCodeModel>[].obs;
//   final RxBool isLoading = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     _logger.i('تم تهيئة DiscountCodeService');
//   }

//   // ==================== إدارة أكواد الخصم ====================

//   /// إنشاء كود خصم جديد
//   Future<bool> createDiscountCode({
//     required String code,
//     required double discountAmount,
//     required double minimumAmount,
//     required int maxUses,
//     required DateTime expiryDate,
//     required String createdBy,
//     String? description,
//     List<String>? applicableUserIds, // إذا كان الكود مخصص لمستخدمين معينين
//   }) async {
//     try {
//       isLoading.value = true;

//       // التحقق من عدم وجود الكود مسبقاً
//       final existingCode = await _firestore
//           .collection(discountCodesCollection)
//           .where('code', isEqualTo: code.toUpperCase())
//           .get();

//       if (existingCode.docs.isNotEmpty) {
//         _logger.w('الكود موجود مسبقاً: $code');
//         return false;
//       }

//       final discountCode = DiscountCodeModel(
//         id: '', // سيتم تعيينه تلقائياً
//         code: code.toUpperCase(),
//         discountAmount: discountAmount,
//         minimumAmount: minimumAmount,
//         maxUses: maxUses,
//         expiryDate: expiryDate,
//         createdAt: DateTime.now(),
//         createdBy: createdBy,
//         description: description,
//         applicableUserIds: applicableUserIds ?? [],
//       );

//       await _firestore
//           .collection(discountCodesCollection)
//           .add(discountCode.toMap());

//       _logger.i('تم إنشاء كود خصم جديد: $code');
//       return true;
//     } catch (e) {
//       _logger.e('خطأ في إنشاء كود خصم: $e');
//       return false;
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// التحقق من صحة كود الخصم
//   Future<DiscountCodeValidationResult> validateDiscountCode({
//     required String code,
//     required String userId,
//     required double tripAmount,
//   }) async {
//     try {
//       final codeDoc = await _firestore
//           .collection(discountCodesCollection)
//           .where('code', isEqualTo: code.toUpperCase())
//           .where('isActive', isEqualTo: true)
//           .get();

//       if (codeDoc.docs.isEmpty) {
//         return DiscountCodeValidationResult(
//           isValid: false,
//           message: 'كود الخصم غير صحيح',
//         );
//       }


//       final discountCode = DiscountCodeModel.fromMap(
//           codeDoc.docs.first.data(), codeDoc.docs.first.id);
//       final docId = codeDoc.docs.first.id;

//       // التحقق من تاريخ انتهاء الصلاحية
//       if (DateTime.now().isAfter(discountCode.expiryDate)) {
//         return DiscountCodeValidationResult(
//           isValid: false,
//           message: 'كود الخصم منتهي الصلاحية',
//         );
//       }

//       // التحقق من عدد مرات الاستخدام
//       if (discountCode.currentUses >= discountCode.maxUses) {
//         return DiscountCodeValidationResult(
//           isValid: false,
//           message: 'تم استنفاذ كود الخصم',
//         );
//       }

//       // التحقق من الحد الأدنى للمبلغ
//       if (tripAmount < discountCode.minimumAmount) {
//         return DiscountCodeValidationResult(
//           isValid: false,
//           message:
//               'يجب أن يكون مبلغ الرحلة ${discountCode.minimumAmount} دينار على الأقل',
//         );
//       }

//       // التحقق من المستخدمين المصرح لهم
//       if (discountCode.applicableUserIds.isNotEmpty &&
//           !discountCode.applicableUserIds.contains(userId)) {
//         return DiscountCodeValidationResult(
//           isValid: false,
//           message: 'كود الخصم غير متاح لك',
//         );
//       }

//       // التحقق من عدم استخدام الكود من قبل
//       final usedCodeDoc = await _firestore
//           .collection(usedCodesCollection)
//           .where('codeId', isEqualTo: docId)
//           .where('userId', isEqualTo: userId)
//           .get();

//       if (usedCodeDoc.docs.isNotEmpty) {
//         return DiscountCodeValidationResult(
//           isValid: false,
//           message: 'لقد استخدمت هذا الكود مسبقاً',
//         );
//       }

//       return DiscountCodeValidationResult(
//         isValid: true,
//         message: 'كود الخصم صحيح',
//         discountCode: discountCode,
//         docId: docId,
//       );
//     } catch (e) {
//       _logger.e('خطأ في التحقق من كود الخصم: $e');
//       return DiscountCodeValidationResult(
//         isValid: false,
//         message: 'حدث خطأ أثناء التحقق من الكود',
//       );
//     }
//   }

//   /// استخدام كود الخصم
//   Future<bool> useDiscountCode({
//     required String codeId,
//     required String userId,
//     required String tripId,
//     required double originalAmount,
//     required double discountedAmount,
//   }) async {
//     try {
//       // تحديث عدد مرات الاستخدام
//       await _firestore.collection(discountCodesCollection).doc(codeId).update({
//         'currentUses': FieldValue.increment(1),
//       });

//       // تسجيل استخدام الكود
//       await _firestore.collection(usedCodesCollection).add({
//         'codeId': codeId,
//         'userId': userId,
//         'tripId': tripId,
//         'originalAmount': originalAmount,
//         'discountedAmount': discountedAmount,
//         'usedAt': Timestamp.now(),
//       });

//       _logger.i('تم استخدام كود الخصم: $codeId بواسطة: $userId');
//       return true;
//     } catch (e) {
//       _logger.e('خطأ في استخدام كود الخصم: $e');
//       return false;
//     }
//   }

//   // ==================== جلب الأكواد ====================

//   /// جلب جميع أكواد الخصم المتاحة
//   Stream<List<DiscountCodeModel>> getAvailableDiscountCodes() {
//     return _firestore
//         .collection(discountCodesCollection)
//         .where('isActive', isEqualTo: true)
//         .where('expiryDate', isGreaterThan: Timestamp.now())
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//             .map((doc) => DiscountCodeModel.fromMap(doc.data(), doc.id))
//             .toList());
//   }

//   /// جلب أكواد الخصم المستخدمة من قبل مستخدم معين
//   Future<List<DiscountCodeModel>> getUserUsedCodes(String userId) async {
//     try {
//       final usedCodesSnapshot = await _firestore
//           .collection(usedCodesCollection)
//           .where('userId', isEqualTo: userId)
//           .get();

//       final codeIds = usedCodesSnapshot.docs
//           .map((doc) => doc.data()['codeId'] as String)
//           .toList();

//       if (codeIds.isEmpty) return [];

//       final codesSnapshot = await _firestore
//           .collection(discountCodesCollection)
//           .where(FieldPath.documentId, whereIn: codeIds)
//           .get();

//       return codesSnapshot.docs
//           .map((doc) => DiscountCodeModel.fromMap(doc.data(), doc.id))
//           .toList();
//     } catch (e) {
//       _logger.e('خطأ في جلب الأكواد المستخدمة: $e');
//       return [];
//     }
//   }

//   /// جلب إحصائيات أكواد الخصم
//   Future<Map<String, dynamic>> getDiscountCodeStatistics() async {
//     try {
//       final totalCodesSnapshot =
//           await _firestore.collection(discountCodesCollection).get();

//       final activeCodesSnapshot = await _firestore
//           .collection(discountCodesCollection)
//           .where('isActive', isEqualTo: true)
//           .get();

//       final expiredCodesSnapshot = await _firestore
//           .collection(discountCodesCollection)
//           .where('expiryDate', isLessThan: Timestamp.now())
//           .get();

//       final usedCodesSnapshot =
//           await _firestore.collection(usedCodesCollection).get();

//       return {
//         'totalCodes': totalCodesSnapshot.docs.length,
//         'activeCodes': activeCodesSnapshot.docs.length,
//         'expiredCodes': expiredCodesSnapshot.docs.length,
//         'totalUses': usedCodesSnapshot.docs.length,
//       };
//     } catch (e) {
//       _logger.e('خطأ في جلب إحصائيات أكواد الخصم: $e');
//       return {
//         'totalCodes': 0,
//         'activeCodes': 0,
//         'expiredCodes': 0,
//         'totalUses': 0,
//       };
//     }
//   }

//   // ==================== إدارة الأكواد ====================

//   /// تحديث كود الخصم
//   Future<bool> updateDiscountCode(
//       String codeId, Map<String, dynamic> data) async {
//     try {
//       await _firestore
//           .collection(discountCodesCollection)
//           .doc(codeId)
//           .update(data);

//       _logger.i('تم تحديث كود الخصم: $codeId');
//       return true;
//     } catch (e) {
//       _logger.e('خطأ في تحديث كود الخصم: $e');
//       return false;
//     }
//   }

//   /// حذف كود الخصم
//   Future<bool> deleteDiscountCode(String codeId) async {
//     try {
//       await _firestore.collection(discountCodesCollection).doc(codeId).delete();

//       _logger.i('تم حذف كود الخصم: $codeId');
//       return true;
//     } catch (e) {
//       _logger.e('خطأ في حذف كود الخصم: $e');
//       return false;
//     }
//   }

//   /// إلغاء تفعيل كود الخصم
//   Future<bool> deactivateDiscountCode(String codeId) async {
//     try {
//       await _firestore
//           .collection(discountCodesCollection)
//           .doc(codeId)
//           .update({'isActive': false});

//       _logger.i('تم إلغاء تفعيل كود الخصم: $codeId');
//       return true;
//     } catch (e) {
//       _logger.e('خطأ في إلغاء تفعيل كود الخصم: $e');
//       return false;
//     }
//   }

//   // ==================== إنشاء أكواد تلقائية ====================

//   /// إنشاء كود خصم تلقائي
//   String generateDiscountCode() {
//     const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
//     final random = DateTime.now().millisecondsSinceEpoch;
//     final code = StringBuffer();

//     for (int i = 0; i < 8; i++) {
//       code.write(chars[random % chars.length]);
//     }

//     return code.toString();
//   }

//   /// إنشاء كود خصم مخصص لمستخدم معين
//   Future<bool> createPersonalDiscountCode({
//     required String userId,
//     required double discountAmount,
//     required double minimumAmount,
//     required DateTime expiryDate,
//     String? description,
//   }) async {
//     final code = generateDiscountCode();

//     return await createDiscountCode(
//       code: code,
//       discountAmount: discountAmount,
//       minimumAmount: minimumAmount,
//       maxUses: 1, // استخدام واحد فقط
//       expiryDate: expiryDate,
//       createdBy: 'system',
//       description: description ?? 'كود خصم مخصص',
//       applicableUserIds: [userId],
//     );
//   }
// }

// // نموذج نتيجة التحقق من كود الخصم
// class DiscountCodeValidationResult {
//   final bool isValid;
//   final String message;
//   final DiscountCodeModel? discountCode;
//   final String? docId;

//   DiscountCodeValidationResult({
//     required this.isValid,
//     required this.message,
//     this.discountCode,
//     this.docId,
//   });
// }
