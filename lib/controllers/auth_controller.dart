import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
 import 'package:transport_app/main.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/routes/app_routes.dart';

import '../views/rider/location_permission_screen.dart';
 
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
    } else {
      // المستخدم سجل دخول أو تم تحديث بياناته
      await loadUserData(user.uid);
      
      if (currentUser.value != null) {
        isLoggedIn.value = true;
      }
    }
  }

  /// تحميل بيانات المستخدم من Firestore
  Future<void> loadUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        currentUser.value = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        currentUser.value = null;
      }
    } catch (e) {
      logger.w('خطأ في تحميل بيانات المستخدم: $e');
      currentUser.value = null;
    }
  }

  /// التنقل إلى الصفحة الرئيسية حسب نوع المستخدم
  void navigateToHome() {
    // أولاً طلب إذن الموقع
    _showLocationPermissionDialog();
  }

  /// عرض نافذة طلب إذن الموقع
  void _showLocationPermissionDialog() {
    Get.dialog(
      LocationPermissionScreen(
        onPermissionGranted: () {
          // الانتقال للصفحة الرئيسية بعد الحصول على الإذن
          if (currentUser.value?.userType == UserType.rider) {
            Get.offAllNamed(AppRoutes.RIDER_HOME);
          } else if (currentUser.value?.userType == UserType.driver) {
            Get.offAllNamed(AppRoutes.DRIVER_HOME);
          }
        },
        onPermissionDenied: () {
          // الانتقال للصفحة الرئيسية حتى لو تم رفض الإذن
          if (currentUser.value?.userType == UserType.rider) {
            Get.offAllNamed(AppRoutes.RIDER_HOME);
          } else if (currentUser.value?.userType == UserType.driver) {
            Get.offAllNamed(AppRoutes.DRIVER_HOME);
          }
        },
      ),
      barrierDismissible: false,
    );
  }

  /// تحديد نوع المستخدم للتسجيل الاجتماعي
  void selectUserTypeForSocialLogin(UserType type) {
    selectedUserType.value = type;
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

      // تسجيل الدخول بـ Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        isLoading.value = false;
        return; // المستخدم ألغى العملية
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

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

  // /// تسجيل الدخول بـ Apple
  // Future<void> signInWithApple() async {
  //   if (selectedUserType.value == null) {
  //     Get.snackbar(
  //       'خطأ',
  //       'يرجى اختيار نوع المستخدم أولاً',
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: Colors.red,
  //       colorText: Colors.white,
  //     );
  //     return;
  //   }

  //   try {
  //     isLoading.value = true;

  //     final credential = await SignInWithApple.getAppleIDCredential(
  //       scopes: [
  //         AppleIDAuthorizationScopes.email,
  //         AppleIDAuthorizationScopes.fullName,
  //       ],
  //     );

  //     final oauthCredential = OAuthProvider("apple.com").credential(
  //       idToken: credential.identityToken,
  //       accessToken: credential.authorizationCode,
  //     );

  //     UserCredential result = await _auth.signInWithCredential(oauthCredential);
      
  //     if (result.user != null) {
  //       String displayName = '';
  //       if (credential.givenName != null && credential.familyName != null) {
  //         displayName = '${credential.givenName} ${credential.familyName}';
  //       }
        
  //       await _handleSuccessfulLogin(result.user!, {
  //         'name': displayName,
  //         'email': credential.email ?? result.user!.email ?? '',
  //       });
  //     }
  //   } catch (e) {
  //     isLoading.value = false;
  //     logger.w('خطأ في تسجيل الدخول بـ Apple: $e');
  //     Get.snackbar(
  //       'خطأ',
  //       'فشل في تسجيل الدخول بـ Apple',
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: Colors.red,
  //       colorText: Colors.white,
  //     );
  //   }
  // }

  /// معالجة تسجيل الدخول الناجح
  Future<void> _handleSuccessfulLogin(User firebaseUser, Map<String, dynamic> userInfo) async {
    try {
      // تحميل بيانات المستخدم
      await loadUserData(firebaseUser.uid);
      
      if (currentUser.value == null) {
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
      } else {
        Get.snackbar(
          'أهلاً وسهلاً',
          'مرحباً بعودتك ${currentUser.value!.name}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
      
      isLoggedIn.value = true;
      navigateToHome();
      
    } catch (e) {
      logger.w('خطأ في معالجة تسجيل الدخول: $e');
      Get.snackbar(
        'خطأ',
        'فشل في حفظ بيانات المستخدم',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
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
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toMap());

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

  /// تنسيق رقم الهاتف (للعراق)
  String _formatPhoneNumber(String phone) {
    // إزالة أي مسافات أو رموز
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // إضافة رمز العراق إذا لم يكن موجود
    if (!phone.startsWith('+964')) {
      if (phone.startsWith('964')) {
        phone = '+$phone';
      } else if (phone.startsWith('0')) {
        phone = '+964${phone.substring(1)}';
      } else {
        phone = '+964$phone';
      }
    }
    
    return phone;
  }

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