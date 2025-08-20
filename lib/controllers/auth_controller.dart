import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import '../views/rider/location_permission_screen.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // User state
  final Rx<User?> _firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;

  // Control flag to prevent multiple initializations
  bool _isInitialized = false;

  // Auth data
  final RxString phoneNumber = ''.obs;
  final RxString verificationId = ''.obs;
  final Rx<UserType?> selectedUserType = Rx<UserType?>(null);

  // Controllers
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  /// تهيئة الـ Controller بشكل آمن
  Future<void> _initializeController() async {
    if (_isInitialized) return;

    try {
      // تحميل حالة تسجيل الدخول المحفوظة
      await _loadLoginState();

      // تحديث الـ Firebase User الحالي
      _firebaseUser.value = _auth.currentUser;

      // إذا كان هناك مستخدم، تحميل بياناته
      if (_firebaseUser.value != null) {
        await loadUserData(_firebaseUser.value!.uid);
        if (currentUser.value != null) {
          isLoggedIn.value = true;
        }
      }

      // البدء في الاستماع لتغييرات حالة المستخدم
      _firebaseUser.bindStream(_auth.authStateChanges());
      ever(_firebaseUser, _handleAuthStateChange);

      _isInitialized = true;
    } catch (e) {
      logger.w('خطأ في تهيئة AuthController: $e');
    }
  }

  /// معالجة تغييرات حالة المصادقة
  void _handleAuthStateChange(User? user) async {
    // تجنب التعامل مع التغييرات أثناء التهيئة الأولى
    if (!_isInitialized) return;

    if (user == null) {
      // المستخدم خرج من النظام
      currentUser.value = null;
      isLoggedIn.value = false;
      // مسح البيانات المحفوظة
      await _clearSavedLoginState();
    } else {
      // المستخدم سجل دخول أو تم تحديث بياناته
      await loadUserData(user.uid);

      if (currentUser.value != null) {
        isLoggedIn.value = true;
        // حفظ حالة تسجيل الدخول
        await _saveLoginState();
      }
    }
  }

  /// تحميل بيانات المستخدم من Firestore
  Future<void> loadUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        currentUser.value =
            UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        currentUser.value = null;
      }
    } catch (e) {
      logger.w('خطأ في تحميل بيانات المستخدم: $e');
      currentUser.value = null;
    }
  }

  /// التنقل إلى الصفحة الرئيسية حسب نوع المستخدم (تجاوز أي حوارات وسيطًا)
  void navigateToHome() {
    if (currentUser.value?.userType == UserType.rider) {
      Get.offAllNamed(AppRoutes.RIDER_HOME);
    } else if (currentUser.value?.userType == UserType.driver) {
      Get.offAllNamed(AppRoutes.DRIVER_HOME);
    }
  }

  // لم نعد نستخدم نافذة طلب إذن الموقع عند الدخول

  /// تحديد نوع المستخدم للتسجيل الاجتماعي
  /// يرجع true إذا تم قبول النوع ويمكن المتابعة، وfalse إذا كان هناك تعارض
  Future<bool> selectUserTypeForSocialLogin(UserType type) async {
    // التحقق من وجود حساب سابق
    if (_auth.currentUser != null) {
      DocumentSnapshot existingUser = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (existingUser.exists) {
        final userData = existingUser.data() as Map<String, dynamic>;
        final existingUserType =
            userData['userType'] as String; // تُحفظ كـ 'rider' أو 'driver'

        if (existingUserType != type.name) {
          Get.snackbar(
            'خطأ',
            'لا يمكن تغيير نوع المستخدم. هذا الحساب موجود بالفعل كنوع: ${existingUserType == 'rider' ? 'راكب' : 'سائق'}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        }
      }
    }

    selectedUserType.value = type;
    return true;
  }

  /// تحديد نوع المستخدم للهاتف (قريباً)
  void selectUserType(UserType type) {
    selectedUserType.value = type;
    // TODO: سيتم تفعيل تسجيل الهاتف لاحقاً
    Get.snackbar(
      'قريباً',
      'تسجيل الدخول بالهاتف سيكون متاحاً قريباً',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  /// تسجيل الدخول بـ Google
  Future<void> signInWithGoogle() async {
    if (selectedUserType.value == null) {
      Get.snackbar(
        'خطأ',
        'يرجى اختيار نوع المستخدم أولاً',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      // لضمان ظهور قائمة اختيار الحساب كل مرة
      try {
        await _googleSignIn.disconnect();
      } catch (_) {}
      await _googleSignIn.signOut();
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // تسجيل الدخول بـ Google (سيعرض قائمة الحسابات)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        isLoading.value = false;
        return; // المستخدم ألغى العملية
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // تسجيل الدخول في Firebase
      UserCredential result = await _auth.signInWithCredential(credential);

      if (result.user != null) {
        await _handleSuccessfulLogin(result.user!, {
          'name': googleUser.displayName ?? '',
          'email': googleUser.email,
          'profileImage': googleUser.photoUrl,
        });
      }
    } catch (e) {
      isLoading.value = false;
      logger.w('خطأ في تسجيل الدخول بـ Google: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تسجيل الدخول بـ Google',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// تسجيل الدخول بـ Apple
  Future<void> signInWithApple() async {
    if (selectedUserType.value == null) {
      Get.snackbar(
        'خطأ',
        'يرجى اختيار نوع المستخدم أولاً',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      UserCredential result = await _auth.signInWithCredential(oauthCredential);

      if (result.user != null) {
        String displayName = '';
        if (credential.givenName != null && credential.familyName != null) {
          displayName = '${credential.givenName} ${credential.familyName}';
        }

        await _handleSuccessfulLogin(result.user!, {
          'name': displayName,
          'email': credential.email ?? result.user!.email ?? '',
        });
      }
    } catch (e) {
      isLoading.value = false;
      logger.w('خطأ في تسجيل الدخول بـ Apple: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تسجيل الدخول بـ Apple',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// معالجة تسجيل الدخول الناجح
  Future<void> _handleSuccessfulLogin(
      User firebaseUser, Map<String, dynamic> userInfo) async {
    try {
      // التحقق من وجود حساب سابق
      DocumentSnapshot existingUser =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (existingUser.exists) {
        // المستخدم موجود بالفعل - تحميل بياناته
        await loadUserData(firebaseUser.uid);

        // منع استخدام نفس الحساب لنوع مختلف مما تم اختياره
        if (selectedUserType.value != null &&
            currentUser.value != null &&
            currentUser.value!.userType != selectedUserType.value) {
          final existingType =
              currentUser.value!.userType == UserType.rider ? 'راكب' : 'سائق';
          Get.snackbar(
            'لا يمكن المتابعة',
            'هذا البريد مسجل مسبقاً كـ $existingType. يرجى اختيار نوع مطابق أو استخدام بريد آخر.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          // تسجيل الخروج لمنع الدخول الخاطئ
          await signOut();
          return;
        }

        if (currentUser.value != null) {
          Get.snackbar(
            'أهلاً وسهلاً',
            'مرحباً بعودتك ${currentUser.value!.name}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      } else {
        // مستخدم جديد - إنشاء حساب
        UserModel newUser = UserModel(
          id: firebaseUser.uid,
          name: userInfo['name'] ?? 'مستخدم جديد',
          phone: firebaseUser.phoneNumber ?? '',
          email: userInfo['email'] ?? firebaseUser.email ?? '',
          profileImage: userInfo['profileImage'],
          userType: selectedUserType.value!,
          createdAt: DateTime.now(),
        );

        try {
          // حفظ البيانات في Firestore
          await _firestore
              .collection('users')
              .doc(newUser.id)
              .set(newUser.toMap());
          currentUser.value = newUser;

          Get.snackbar(
            'مرحباً بك',
            'تم إنشاء حسابك بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (firestoreError) {
          logger.w('خطأ في حفظ البيانات في Firestore: $firestoreError');
          throw Exception('فشل في حفظ البيانات. يرجى المحاولة مرة أخرى.');
        }
      }

      // حفظ حالة تسجيل الدخول
      await _saveLoginState();

      isLoggedIn.value = true;
      navigateToHome();
    } catch (e) {
      logger.w('خطأ في معالجة تسجيل الدخول: $e');
      Get.snackbar(
        'خطأ',
        'فشل في حفظ بيانات المستخدم: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// حفظ حالة تسجيل الدخول
  Future<void> _saveLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_id', currentUser.value!.id);
      await prefs.setString(
          'user_type', currentUser.value!.userType.toString());
      await prefs.setString('user_name', currentUser.value!.name);
      await prefs.setString('user_phone', currentUser.value!.phone);
      if (currentUser.value!.email.isNotEmpty) {
        await prefs.setString('user_email', currentUser.value!.email);
      }
      if (currentUser.value!.profileImage != null) {
        await prefs.setString(
            'user_profile_image', currentUser.value!.profileImage!);
      }
    } catch (e) {
      logger.w('خطأ في حفظ حالة تسجيل الدخول: $e');
    }
  }

  /// تحميل حالة تسجيل الدخول
  Future<void> _loadLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedInSaved = prefs.getBool('is_logged_in') ?? false;

      if (isLoggedInSaved) {
        final userId = prefs.getString('user_id');
        final userType = prefs.getString('user_type');

        if (userId != null && userType != null) {
          // تحميل بيانات المستخدم من Firestore
          await loadUserData(userId);

          if (currentUser.value != null) {
            isLoggedIn.value = true;
            selectedUserType.value = UserType.values.firstWhere(
              (e) => e.toString() == userType,
              orElse: () => UserType.rider,
            );
          }
        }
      }
    } catch (e) {
      logger.w('خطأ في تحميل حالة تسجيل الدخول: $e');
    }
  }

  /// إرسال رمز التحقق (للاستخدام المستقبلي)
  Future<void> sendOTP() async {
    // TODO: سيتم تفعيله لاحقاً
    Get.snackbar(
      'قريباً',
      'تسجيل الدخول بالهاتف سيكون متاحاً قريباً',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  /// التحقق من رمز OTP (للاستخدام المستقبلي)
  Future<void> verifyOTP(String otp) async {
    // TODO: سيتم تفعيله لاحقاً
    Get.snackbar(
      'قريباً',
      'تسجيل الدخول بالهاتف سيكون متاحاً قريباً',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  /// تسجيل الدخول بـ Credential (للاستخدام المستقبلي)
  Future<void> signInWithCredential(PhoneAuthCredential credential) async {
    // TODO: سيتم تفعيله لاحقاً
  }

  /// إكمال الملف الشخصي
  Future<void> completeProfile({
    required String name,
    required String email,
    String? profileImage,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_auth.currentUser == null) {
      Get.snackbar(
        'خطأ',
        'يرجى تسجيل الدخول أولاً',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedUserType.value == null) {
      Get.snackbar(
        'خطأ',
        'يرجى اختيار نوع المستخدم',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      UserModel user = UserModel(
        id: _auth.currentUser!.uid,
        name: name,
        phone: phoneNumber.value,
        email: email,
        profileImage: profileImage,
        userType: selectedUserType.value!,
        createdAt: DateTime.now(),
        additionalData: additionalData,
      );

      // حفظ البيانات في Firestore
      await _firestore.collection('users').doc(user.id).set(user.toMap());

      currentUser.value = user;
      isLoggedIn.value = true;

      Get.snackbar(
        'تم بنجاح',
        'تم إنشاء الحساب بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      navigateToHome();
    } catch (e) {
      logger.w('خطأ في حفظ البيانات: $e');
      Get.snackbar(
        'خطأ',
        'فشل في حفظ البيانات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث بيانات المستخدم
  Future<void> updateUser(UserModel updatedUser) async {
    try {
      await _firestore
          .collection('users')
          .doc(updatedUser.id)
          .update(updatedUser.toMap());

      currentUser.value = updatedUser;

      Get.snackbar(
        'تم بنجاح',
        'تم تحديث البيانات بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      logger.w('خطأ في تحديث البيانات: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تحديث البيانات',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// تحديث الرصيد
  Future<void> updateBalance(double amount) async {
    if (currentUser.value == null) return;

    try {
      UserModel updatedUser = currentUser.value!.copyWith(
        balance: currentUser.value!.balance + amount,
      );

      await updateUser(updatedUser);
    } catch (e) {
      logger.w('خطأ في تحديث الرصيد: $e');
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    try {
      // تسجيل الخروج من Google إذا كان مسجل دخول
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      await _auth.signOut();
      currentUser.value = null;
      isLoggedIn.value = false;

      // مسح البيانات المحلية
      _clearControllers();

      // مسح البيانات المحفوظة
      await _clearSavedLoginState();

      // إعادة تعيين تهيئة شاشة الوجهة الأولى للراكب
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('rider_opened_destination_once');
      } catch (_) {}

      Get.offAllNamed(AppRoutes.USER_TYPE_SELECTION);
    } catch (e) {
      logger.w('خطأ في تسجيل الخروج: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تسجيل الخروج',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// مسح البيانات المحفوظة
  Future<void> _clearSavedLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_logged_in');
      await prefs.remove('user_id');
      await prefs.remove('user_type');
      await prefs.remove('user_name');
      await prefs.remove('user_phone');
      await prefs.remove('user_email');
      await prefs.remove('user_profile_image');
    } catch (e) {
      logger.w('خطأ في مسح البيانات المحفوظة: $e');
    }
  }

  /// إعادة إرسال رمز التحقق (للاستخدام المستقبلي)
  Future<void> resendOTP() async {
    Get.snackbar(
      'قريباً',
      'تسجيل الدخول بالهاتف سيكون متاحاً قريباً',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  // String _formatPhoneNumber(String phone) {
  //   phone = phone.replaceAll(RegExp(r'[^\\d]'), '');
  //   if (!phone.startsWith('+964')) {
  //     if (phone.startsWith('964')) {
  //       phone = '+$phone';
  //     } else if (phone.startsWith('0')) {
  //       phone = '+964${phone.substring(1)}';
  //     } else {
  //       phone = '+964$phone';
  //     }
  //   }
  //   return phone;
  // }

  /// مسح المتحكمات
  void _clearControllers() {
    phoneController.clear();
    otpController.clear();
    nameController.clear();
    emailController.clear();
    phoneNumber.value = '';
    verificationId.value = '';
    selectedUserType.value = null;
  }

  @override
  void onClose() {
    phoneController.dispose();
    otpController.dispose();
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }
}
