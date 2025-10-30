import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:transport_app/main.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/driver_profile_service.dart';
import 'package:transport_app/views/account/account_suspended_view.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rx<User?> _firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;

  bool _isInitialized = false;

  final RxString phoneNumber = ''.obs;
  final RxString verificationId = ''.obs;
  final Rx<UserType?> selectedUserType = Rx<UserType?>(null);

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _initializeController();
    saveFCMToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      saveFCMToken();
    });
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      logger.e("Error getting user by ID: $e");
      return null;
    }
  }

  Future<void> _initializeController() async {
    if (_isInitialized) return;

    try {
      await loadLoginState();

      _firebaseUser.value = _auth.currentUser;

      if (_firebaseUser.value != null) {
        await loadUserData(_firebaseUser.value!.uid);
        if (currentUser.value != null) {
          isLoggedIn.value = true;
        }
      }

      _firebaseUser.bindStream(_auth.authStateChanges());
      ever(_firebaseUser, _handleAuthStateChange);

      _isInitialized = true;
    } catch (e) {
      logger.w('خطأ في تهيئة AuthController: $e');
    }
  }

  void _handleAuthStateChange(User? user) async {
    if (!_isInitialized) return;

    if (user == null) {
      currentUser.value = null;
      isLoggedIn.value = false;

      await _clearSavedLoginState();
    } else {
      await loadUserData(user.uid);

      if (currentUser.value != null) {
        isLoggedIn.value = true;

        await _saveLoginState();
      }
    }
  }

  Future<void> loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        currentUser.value = UserModel.fromMap(data);

        // تأكد من أن 'additionalData' موجود قبل الوصول إليه
        final additionalData =
            data['additionalData'] as Map<String, dynamic>? ?? {};

if (data['userType'] == 'driver') {
  // Re-fetch the user model to ensure it uses the latest data and its own logic
  UserModel? updatedUserModel = await getUserById(uid);
  if (updatedUserModel != null && updatedUserModel.isDriverProfileComplete && !(data['isProfileComplete'] ?? false)) {
    await _firestore.collection('users').doc(uid).update({
      'isProfileComplete': true,
      'status': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Reload current user value after update
    final updatedDoc = await _firestore.collection('users').doc(uid).get();
    if (updatedDoc.exists) {
      currentUser.value = UserModel.fromMap(updatedDoc.data()!);
    }
  }
}
      } else {
        currentUser.value = null;
      }
    } catch (e) {
      logger.w('خطأ في تحميل بيانات المستخدم: $e');
      currentUser.value = null;
    }
  }

  
  void navigateToHome() {
    if (currentUser.value?.userType == UserType.rider) {
      Get.offAllNamed(AppRoutes.RIDER_HOME);
    } else if (currentUser.value?.userType == UserType.driver) {
      _checkDriverProfileAndNavigate();
    }
  }

  Future<void> saveFCMToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && currentUser.value != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.value!.id)
            .update({
          'fcmToken': fcmToken,
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      logger.w('Error saving FCM token: $e');
    }
  }

  Future<void> _checkDriverProfileAndNavigate() async {
    try {
      final userId = currentUser.value?.id;
      if (userId == null) {
        Get.offAllNamed(AppRoutes.DRIVER_HOME);
        return;
      }

      final profileService = Get.find<DriverProfileService>();
      final isComplete = await profileService.isProfileComplete(userId);

      if (!isComplete) {
        Get.offAllNamed(AppRoutes.DRIVER_PROFILE_COMPLETION);
        return;
      }

      final isApproved = await profileService.isDriverApproved(userId);

      if (!isApproved) {
        Get.offAllNamed(AppRoutes.DRIVER_PROFILE_COMPLETION);
        return;
      }

      Get.offAllNamed(AppRoutes.DRIVER_HOME);
    } catch (e) {
      logger.w('خطأ في التحقق من بروفايل السائق: $e');

      Get.offAllNamed(AppRoutes.DRIVER_HOME);
    }
  }

  Future<bool> selectUserTypeForSocialLogin(UserType type) async {
    if (_auth.currentUser != null) {
      DocumentSnapshot existingUser = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (existingUser.exists) {
        final userData = existingUser.data() as Map<String, dynamic>;
        final existingUserType = userData['userType'] as String;

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

  void selectUserType(UserType type) {
    selectedUserType.value = type;

    Get.snackbar(
      'قريباً',
      'تسجيل الدخول بالهاتف سيكون متاحاً قريباً',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

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

      try {
        await _auth.signOut();
      } catch (_) {}

      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');

      UserCredential result = await _auth.signInWithProvider(googleProvider);

      if (result.user != null) {
        Map<String, dynamic> userInfo = {
          'name': result.user!.displayName ?? '',
          'email': result.user!.email ?? '',
          'profileImage': result.user!.photoURL,
        };

        await _handleSuccessfulLogin(result.user!, userInfo);
      } else {
        throw Exception('فشل في تسجيل الدخول');
      }
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String errorMessage = 'فشل في تسجيل الدخول بـ Google';

      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
              'يوجد حساب بهذا البريد الإلكتروني مع طريقة دخول مختلفة';
          break;
        case 'invalid-credential':
          errorMessage = 'بيانات اعتماد غير صالحة';
          break;
        case 'operation-not-allowed':
          errorMessage = 'تسجيل الدخول بـ Google غير مفعل';
          break;
        case 'user-disabled':
          errorMessage = 'تم تعطيل هذا الحساب';
          break;
        case 'user-not-found':
          errorMessage = 'لم يتم العثور على المستخدم';
          break;
        case 'wrong-password':
          errorMessage = 'كلمة مرور خاطئة';
          break;
        case 'too-many-requests':
          errorMessage = 'تم تجاوز عدد المحاولات المسموح بها. حاول لاحقاً';
          break;
        default:
          errorMessage = 'خطأ في تسجيل الدخول: ${e.message}';
      }

      logger.w('Firebase Auth Error: ${e.code} - ${e.message}');
      Get.snackbar(
        'خطأ في المصادقة',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      isLoading.value = false;
      logger.w('خطأ في تسجيل الدخول بـ Google: $e');

      String errorMessage = 'خطأ غير متوقع في تسجيل الدخول';
      if (e.toString().contains('network')) {
        errorMessage = 'خطأ في الاتصال بالإنترنت';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'تم إلغاء عملية تسجيل الدخول';
      }

      Get.snackbar(
        'خطأ',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

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
        } else if (result.user!.displayName != null) {
          displayName = result.user!.displayName!;
        }

        Map<String, dynamic> userInfo = {
          'name': displayName,
          'email': credential.email ?? result.user!.email ?? '',
          'profileImage': result.user!.photoURL,
        };

        await _handleSuccessfulLogin(result.user!, userInfo);
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      isLoading.value = false;
      String errorMessage = 'فشل في تسجيل الدخول بـ Apple';

      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          return;
        case AuthorizationErrorCode.failed:
          errorMessage = 'فشلت عملية المصادقة مع Apple';
          break;
        case AuthorizationErrorCode.invalidResponse:
          errorMessage = 'استجابة غير صالحة من Apple';
          break;
        case AuthorizationErrorCode.notHandled:
          errorMessage = 'لم تتم معالجة الطلب';
          break;
        case AuthorizationErrorCode.unknown:
          errorMessage = 'خطأ غير معروف في تسجيل الدخول بـ Apple';
          break;
        default:
          errorMessage = 'خطأ في تسجيل الدخول بـ Apple: ${e.code}';
      }

      logger.w('Apple Sign-In Error: ${e.code} - ${e.message}');
      Get.snackbar(
        'خطأ',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      logger.w('Firebase Auth Error with Apple: ${e.code} - ${e.message}');
      Get.snackbar(
        'خطأ في المصادقة',
        'فشل في ربط حساب Apple مع Firebase: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      isLoading.value = false;
      logger.w('خطأ في تسجيل الدخول بـ Apple: $e');
      Get.snackbar(
        'خطأ',
        'خطأ غير متوقع في تسجيل الدخول بـ Apple',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _handleSuccessfulLogin(
      User firebaseUser, Map<String, dynamic> userInfo) async {
    try {
      DocumentSnapshot existingUser =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (existingUser.exists) {
        await loadUserData(firebaseUser.uid);

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
            duration: const Duration(seconds: 4),
          );

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
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        await _createNewUser(firebaseUser, userInfo);
      }

      await _saveLoginState();

      isLoggedIn.value = true;
      navigateToHome();
    } catch (e) {
      logger.w('خطأ في معالجة تسجيل الدخول: $e');
      Get.snackbar(
        'خطأ',
        'فشل في حفظ بيانات المستخدم. يرجى المحاولة مرة أخرى.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _createNewUser(
      User firebaseUser, Map<String, dynamic> userInfo) async {
    Map<String, dynamic> userData = {
      'id': firebaseUser.uid,
      'name': userInfo['name']?.toString().trim() ?? 'مستخدم جديد',
      'phone': firebaseUser.phoneNumber ?? '',
      'email': userInfo['email']?.toString().trim() ?? firebaseUser.email ?? '',
      'profileImage': userInfo['profileImage']?.toString(),
      'userType': selectedUserType.value!.name,
      'balance': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'isVerified': false,
      'isApproved': false,
      'isRejected': false,
    };

    if (selectedUserType.value == UserType.driver) {
      userData.addAll({
        'additionalData': {
          'carType': '',
          'carModel': '',
          'carColor': '',
          'carYear': '',
          'carNumber': '',
          'licenseNumber': '',
          'workingAreas': [],
          'carImage': null,
          'licenseImage': null,
          'idCardImage': null,
          'vehicleRegistrationImage': null,
          'insuranceImage': null,
          'isOnline': false,
          'isAvailable': true,
          'currentLat': null,
          'currentLng': null,
        },
        'isProfileComplete': false,
      });
    }

    try {
      await _firestoreWriteWithRetry(() =>
          _firestore.collection('users').doc(firebaseUser.uid).set(userData));
      await loadUserData(firebaseUser.uid);

      Get.snackbar(
        'مرحباً بك',
        'تم إنشاء حسابك بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (firestoreError) {
      logger.w('خطأ في حفظ البيانات في Firestore: $firestoreError');
      throw Exception('فشل في حفظ البيانات. يرجى المحاولة مرة أخرى.');
    }
  }

  Future<void> _firestoreWriteWithRetry(Future<void> Function() operation,
      {int maxRetries = 3}) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        await operation();
        return;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          rethrow;
        }

        await Future.delayed(Duration(seconds: retryCount));
      }
    }
  }

Future<void> _saveLoginState() async {
    try {
      final box = GetStorage();
      if (currentUser.value != null) { // Add null check here
        box.write('is_logged_in', true);
        box.write('user_id', currentUser.value!.id);
        box.write('user_type', currentUser.value!.userType.toString());
        box.write('user_name', currentUser.value!.name);
        box.write('user_phone', currentUser.value!.phone);
        if (currentUser.value!.email.isNotEmpty) {
          box.write('user_email', currentUser.value!.email);
        }
        if (currentUser.value!.profileImage != null) {
          box.write('user_profile_image', currentUser.value!.profileImage!);
        }
      } else {
        logger.w('Cannot save login state: currentUser.value is null.');
        await _clearSavedLoginState(); // Clear any potentially stale state
      }
    } catch (e) {
      logger.w('خطأ في حفظ حالة تسجيل الدخول: $e');
    }
  }

  Future<void> loadLoginState() async {
    try {
      final box = GetStorage();
      final isLoggedInSaved = box.read('is_logged_in') ?? false;

      if (isLoggedInSaved) {
        final String? userId = box.read('user_id');
        final String? userType = box.read('user_type');

        if (userId != null && userType != null) {
          logger.i('✅ تحميل بيانات المستخدم من التخزين: $userId');
          await loadUserData(userId);

          if (currentUser.value != null) {
            isLoggedIn.value = true;
            selectedUserType.value = UserType.values.firstWhere(
              (e) => e.toString() == userType,
              orElse: () => UserType.rider,
            );
            logger.i('✅ تم تحميل بيانات المستخدم بنجاح');
          } else {
            logger.w('⚠️ فشل في تحميل بيانات المستخدم - مسح التخزين');
            await _clearSavedLoginState();
          }
        } else {
          logger.w('⚠️ بيانات تسجيل دخول غير كاملة - مسح التخزين');
          await _clearSavedLoginState();
        }
      } else {
        logger.i('🆕 لا توجد حالة تسجيل دخول محفوظة');
      }
    } catch (e) {
      logger.e('❌ خطأ في تحميل حالة تسجيل الدخول: $e');
      await _clearSavedLoginState();
    }
  }

  Future<void> sendOTP() async {
    Get.snackbar(
      'قريباً',
      'تسجيل الدخول بالهاتف سيكون متاحاً قريباً',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  Future<void> verifyOTP(String otp) async {
    Get.snackbar(
      'قريباً',
      'تسجيل الدخول بالهاتف سيكون متاحاً قريباً',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

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

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      currentUser.value = null;
      isLoggedIn.value = false;

      await _clearSavedLoginState();

      try {
        final box = GetStorage();
        await box.remove('rider_opened_destination_once');
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

  Future<void> _clearSavedLoginState() async {
    try {
      final box = GetStorage();
      await box.remove('is_logged_in');
      await box.remove('user_id');
      await box.remove('user_type');
      await box.remove('user_name');
      await box.remove('user_phone');
      await box.remove('user_email');
      await box.remove('user_profile_image');
    } catch (e) {
      logger.w('خطأ في مسح البيانات المحفوظة: $e');
    }
  }

  Future<void> resendOTP() async {
    Get.snackbar(
      'قريباً',
      'تسجيل الدخول بالهاتف سيكون متاحاً قريباً',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  // دالة مساعدة لتحديث حالة السائق (للموافقة والرفض)
  Future<bool> _updateDriverStatus(
      String driverId, Map<String, dynamic> statusData) async {
    try {
      final adminId = currentUser.value?.id;
      if (adminId == null) {
        throw Exception('لم يتم العثور على معرف الأدمن');
      }

      final Map<String, dynamic> dataToUpdate = {
        ...statusData,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(driverId).update(dataToUpdate);
      return true;
    } catch (e) {
      logger.w('خطأ في تحديث حالة السائق: $e');
      return false;
    }
  }

  Future<bool> approveDriver(String driverId) async {
    final Map<String, dynamic> approvedData = {
      'isApproved': true,
      'approvedAt': FieldValue.serverTimestamp(),
      'status': 'approved',
      'approvedBy': currentUser.value?.id,
      'isRejected': false,
      'rejectionReason': FieldValue.delete(), // حذف سبب الرفض عند الموافقة
    };
    return _updateDriverStatus(driverId, approvedData);
  }

  Future<bool> rejectDriver(String driverId, String reason) async {
    final Map<String, dynamic> rejectedData = {
      'isRejected': true,
      'status': 'rejected',
      'rejectionReason': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedBy': currentUser.value?.id,
      'isApproved': false,
    };
    return _updateDriverStatus(driverId, rejectedData);
  }

  Future<void> updateUserRiderType(String riderType) async {
    try {
      final user = currentUser.value;
      if (user == null || user.userType != UserType.rider) return;

      await _firestore.collection('users').doc(user.id).update({
        'riderType': riderType,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      currentUser.value = user.copyWith(riderType: riderType);

      logger.i('✅ تم تحديث نوع السائق إلى: $riderType');
    } catch (e) {
      logger.e('خطأ في تحديث نوع السائق: $e');
      rethrow;
    }
  }

  Future<bool> checkAccountSuspension() async {
    try {
      final user = currentUser.value;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.id).get();
      if (!userDoc.exists) return false;

      final additionalData =
          userDoc.data()?['additionalData'] as Map<String, dynamic>?;
      final isSuspended = additionalData?['isSuspended'] ?? false;

      if (isSuspended) {
        final suspensionEndDate =
            (additionalData?['suspensionEndDate'] as Timestamp?)?.toDate();

        // إذا انتهت فترة التعليق، قم بإعادة تنشيط الحساب
        if (suspensionEndDate != null &&
            DateTime.now().isAfter(suspensionEndDate)) {
          await _firestore.collection('users').doc(user.id).update({
            'additionalData.isSuspended': false,
            'additionalData.suspensionReason': FieldValue.delete(),
            'additionalData.suspensionEndDate': FieldValue.delete(),
            'additionalData.suspensionCreatedAt': FieldValue.delete(),
            'additionalData.reactivatedAt': FieldValue.serverTimestamp(),
          });

          return false; // لم يعد معلقاً
        }

        // إذا كان الحساب معلقًا ولم تنته فترة التعليق
        Get.offAll(() => const AccountSuspendedView());
        return true;
      }

      return false; // الحساب غير معلق
    } catch (e) {
      logger.w('خطأ في فحص حالة التعليق: $e');
      return false;
    }
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