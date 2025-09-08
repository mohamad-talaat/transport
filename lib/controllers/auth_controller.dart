import 'dart:async';
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
 
// import '../views/rider/location_permission_screen.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // وضع الاختبار (محاكاة)
  final RxBool mockMode = false.obs;

  /// 🔹 الدخول كضيف Rider
  Future<void> signInAsGuest() async {
    try {
      mockMode.value = true; // ✅ نفعل وضع الاختبار

      UserModel guestUser = UserModel(
        id: "guest_rider",
        name: "ضيف راكب",
        email: "guest_rider@test.com",
        phone: "",
        profileImage: "",
        userType: UserType.rider,
        balance: 5000,
        isActive: true,
        isApproved: true,
        isRejected: false,
        isVerified: true,
        createdAt: DateTime.now(),
      );

      currentUser.value = guestUser;
      selectedUserType.value = UserType.rider;
      isLoggedIn.value = true;

      // 🔥 نبدأ رحلة وهمية مباشرة
      await simulateTripFlow(guestUser.id);

      await simulateMultipleTrips("guest_rider", [
        {
          "pickup": {"lat": 30.82, "lng": 29.00, "address": "Pickup Point A"},
          "destination": {
            "lat": 30.90,
            "lng": 29.05,
            "address": "Destination A"
          },
          "fare": 20.0,
        },
        {
          "pickup": {"lat": 30.70, "lng": 29.10, "address": "Pickup Point B"},
          "destination": {
            "lat": 30.75,
            "lng": 29.15,
            "address": "Destination B"
          },
          "fare": 35.0,
        },
        {
          "pickup": {"lat": 30.60, "lng": 29.20, "address": "Pickup Point C"},
          "destination": {
            "lat": 30.65,
            "lng": 29.30,
            "address": "Destination C"
          },
          "fare": 50.0,
        },
      ]);

      // ✅ هنا بعد ما تخلص simulateTripFlow
      navigateToHome();
    } catch (e) {
      Get.snackbar("خطأ", "فشل الدخول كضيف راكب: $e");
    }
  }

  /// 🔹 الدخول كضيف Driver
  Future<void> signInAsGuestDriver() async {
    try {
      mockMode.value = true; // ✅ نفعل وضع الاختبار

      UserModel guestDriver = UserModel(
        id: "guest_driver",
        name: "ضيف سائق",
        email: "guest_driver@test.com",
        phone: "",
        profileImage: "",
        userType: UserType.driver,
        balance: 5000,
        isActive: true,
        isApproved: true,
        isRejected: false,
        isVerified: true,
        createdAt: DateTime.now(),
      );

      currentUser.value = guestDriver;
      selectedUserType.value = UserType.driver;
      isLoggedIn.value = true;
      navigateToHome();
      // ✅ السواق الوهمي مش بيعمل رحلة، بس يبقى ظاهر أونلاين
    } catch (e) {
      Get.snackbar("خطأ", "فشل الدخول كضيف سائق: $e");
    }
  }

  /// 🔹 محاكاة رحلات متعددة
  Future<void> simulateMultipleTrips(
      String riderId, List<Map<String, dynamic>> trips) async {
    if (!mockMode.value) return;

    for (var i = 0; i < trips.length; i++) {
      final trip = trips[i];
      final tripId = "mock_trip_${DateTime.now().millisecondsSinceEpoch}_$i";
      final tripRef = _firestore.collection("trips").doc(tripId);

      // 1. طلب الرحلة
      await tripRef.set({
        "id": tripId,
        "riderId": riderId,
        "driverId": "guest_driver",
        "status": "requested",
        "createdAt": DateTime.now(),
        "pickupLocation": trip["pickup"],
        "destinationLocation": trip["destination"],
        "fare": trip["fare"],
      });

      // 2. قبول الرحلة
      await Future.delayed(const Duration(seconds: 2));
      await tripRef.update({
        "status": "accepted",
        "acceptedAt": DateTime.now(),
      });

      // 3. بدء الرحلة
      await Future.delayed(const Duration(seconds: 2));
      await tripRef.update({
        "status": "ongoing",
        "startedAt": DateTime.now(),
      });

      // 4. إنهاء الرحلة
      await Future.delayed(const Duration(seconds: 2));
      await tripRef.update({
        "status": "completed",
        "completedAt": DateTime.now(),
      });
    }
  }

  /// 🔹 محاكاة رحلة كاملة
  Future<void> simulateTripFlow(String riderId) async {
    if (!mockMode.value) return;

    final tripId = "mock_trip_${DateTime.now().millisecondsSinceEpoch}";
    final tripRef = _firestore.collection("trips").doc(tripId);

    // 1. طلب الرحلة
    await tripRef.set({
      "id": tripId,
      "riderId": riderId,
      "driverId": "guest_driver",
      "status": "requested",
      "createdAt": DateTime.now(),
      "pickupLocation": {"lat": 30.82, "lng": 29.00, "address": "Pickup Point"},
      "destinationLocation": {
        "lat": 30.83,
        "lng": 29.01,
        "address": "Destination"
      },
      "fare": 15.0,
    });

    // 2. قبول الرحلة
    await Future.delayed(const Duration(seconds: 2));
    await tripRef.update({
      "status": "accepted",
      "acceptedAt": DateTime.now(),
    });

    // 3. بدء الرحلة
    await Future.delayed(const Duration(seconds: 2));
    await tripRef.update({
      "status": "ongoing",
      "startedAt": DateTime.now(),
    });

    // 4. إنهاء الرحلة
    await Future.delayed(const Duration(seconds: 2));
    await tripRef.update({
      "status": "completed",
      "completedAt": DateTime.now(),
    });
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

  Future<void> loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        currentUser.value = UserModel.fromMap(data);

        // تحديث حالة الملف الشخصي
        final additionalData =
            data['additionalData'] as Map<String, dynamic>? ?? {};

        // التحقق من اكتمال الملف للسائق
        if (data['userType'] == 'driver') {
          bool isComplete = _isProfileComplete(data, additionalData);

          // إذا كان الملف مكتمل لكن لم يتم وضع العلامة
          if (isComplete && data['isProfileComplete'] != true) {
            await _firestore.collection('users').doc(uid).update({
              'isProfileComplete': true,
              'status': 'pending',
              'updatedAt': FieldValue.serverTimestamp(),
            });

            // إعادة تحميل البيانات المحدثة
            final updatedDoc =
                await _firestore.collection('users').doc(uid).get();
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

// إضافة دالة التحقق من اكتمال الملف
  bool _isProfileComplete(
      Map<String, dynamic> data, Map<String, dynamic> additionalData) {
    return data['name'] != null &&
        data['name'].toString().isNotEmpty &&
        data['phone'] != null &&
        data['phone'].toString().isNotEmpty &&
        data['email'] != null &&
        data['email'].toString().isNotEmpty &&
        data['nationalId'] != null &&
        data['nationalId'].toString().isNotEmpty &&
        data['nationalIdImage'] != null &&
        data['drivingLicense'] != null &&
        data['drivingLicense'].toString().isNotEmpty &&
        data['drivingLicenseImage'] != null &&
        data['vehicleModel'] != null &&
        data['vehicleModel'].toString().isNotEmpty &&
        data['vehicleColor'] != null &&
        data['vehicleColor'].toString().isNotEmpty &&
        data['vehiclePlateNumber'] != null &&
        data['vehiclePlateNumber'].toString().isNotEmpty &&
        data['vehicleImage'] != null &&
        data['insuranceImage'] != null;
  }

  /// التنقل إلى الصفحة الرئيسية حسب نوع المستخدم (تجاوز أي حوارات وسيطًا)
  void navigateToHome() {
    if (currentUser.value?.userType == UserType.rider) {
      Get.offAllNamed(AppRoutes.RIDER_HOME);
    } else if (currentUser.value?.userType == UserType.driver) {
      _checkDriverProfileAndNavigate();
    }
  }

  /// التحقق من اكتمال بروفايل السائق والتوجيه
  Future<void> _checkDriverProfileAndNavigate() async {
    try {
      final userId = currentUser.value?.id;
      if (userId == null) {
        Get.offAllNamed(AppRoutes.DRIVER_HOME);
        return;
      }
      // ✅ لو احنا في وضع محاكاة (ضيف سائق)، يدخل مباشرة للهوم
      if (mockMode.value && userId == "guest_driver") {
        Get.offAllNamed(AppRoutes.DRIVER_HOME);
        return;
      }

      // التحقق من اكتمال البروفايل
      final profileService = Get.find<DriverProfileService>();
      final isComplete = await profileService.isProfileComplete(userId);

      if (!isComplete) {
        // إذا لم يكمل البروفايل، توجيه لشاشة الإكمال
        Get.offAllNamed(AppRoutes.DRIVER_PROFILE_COMPLETION);
        return;
      }

      // التحقق من موافقة الإدارة
      final isApproved = await profileService.isDriverApproved(userId);

      if (!isApproved) {
        // إذا لم يتم الموافقة عليه، توجيه لشاشة الإكمال مع رسالة
        Get.offAllNamed(AppRoutes.DRIVER_PROFILE_COMPLETION);
        return;
      }

      // إذا اكتمل البروفايل وتمت الموافقة، توجيه للشاشة الرئيسية
      Get.offAllNamed(AppRoutes.DRIVER_HOME);
    } catch (e) {
      logger.w('خطأ في التحقق من بروفايل السائق: $e');
      // في حالة الخطأ، توجيه للشاشة الرئيسية
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

      // تسجيل خروج كامل لضمان اختيار الحساب
      try {
        await _auth.signOut();
      } catch (_) {}

      // استخدام مزود Google من FirebaseAuth مباشرة (v6+)
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');

      UserCredential result = await _auth.signInWithProvider(googleProvider);

      if (result.user != null) {
        // جمع بيانات المستخدم بطريقة آمنة
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
        duration: Duration(seconds: 4),
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
        duration: Duration(seconds: 3),
      );
    }
  }

  /// تسجيل الدخول بـ Apple - مُحسّن
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
          // لا تعرض رسالة خطأ عند الإلغاء
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
        duration: Duration(seconds: 3),
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
        duration: Duration(seconds: 4),
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
        duration: Duration(seconds: 3),
      );
    }
  }

  /// معالجة تسجيل الدخول الناجح - مُحسّنة
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
            duration: Duration(seconds: 4),
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
            duration: Duration(seconds: 2),
          );
        }
      } else {
        // مستخدم جديد - إنشاء حساب
        await _createNewUser(firebaseUser, userInfo);
      }

      // حفظ حالة تسجيل الدخول
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
        duration: Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// إنشاء مستخدم جديد (يُخزن في drivers/riders بدل users)
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

    // بيانات إضافية للسائق
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
        duration: Duration(seconds: 2),
      );
    } catch (firestoreError) {
      logger.w('خطأ في حفظ البيانات في Firestore: $firestoreError');
      throw Exception('فشل في حفظ البيانات. يرجى المحاولة مرة أخرى.');
    }
  }

  /// Firestore write مع retry logic
  Future<void> _firestoreWriteWithRetry(Future<void> Function() operation,
      {int maxRetries = 3}) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        await operation();
        return; // نجحت العملية
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          rethrow; // فشلت جميع المحاولات
        }
        // انتظار قبل المحاولة التالية
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
  }

  /// حفظ حالة تسجيل الدخول
  Future<void> _saveLoginState() async {
    try {
      final box = GetStorage();
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
    } catch (e) {
      logger.w('خطأ في حفظ حالة تسجيل الدخول: $e');
    }
  }

  /// تحميل حالة تسجيل الدخول
  Future<void> _loadLoginState() async {
    try {
      final box = GetStorage();
      final isLoggedInSaved = box.read('is_logged_in') ?? false;

      if (isLoggedInSaved) {
        final String? userId = box.read('user_id');
        final String? userType = box.read('user_type');

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

  // /// تسجيل الدخول بـ Credential (للاستخدام المستقبلي)
  // Future<void> signInWithCredential(PhoneAuthCredential credential) async {
  //   // TODO: سيتم تفعيله لاحقاً
  // }

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
      // تسجيل الخروج من Google بشكل آمن (isSignedIn أزيلت في v7)
      // لا حاجة لتسجيل خروج منفصل من GoogleSignIn في v7

      await _auth.signOut();
      currentUser.value = null;
      isLoggedIn.value = false;

      // مسح البيانات المحلية
      _clearControllers();

      // مسح البيانات المحفوظة
      await _clearSavedLoginState();

      // إعادة تعيين تهيئة شاشة الوجهة الأولى للراكب
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

  /// مسح البيانات المحفوظة
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

  /// تحديث حالة الموافقة على السائق (للأدمن)
  Future<bool> approveDriver(String driverId) async {
    try {
      final adminId = currentUser.value?.id;
      if (adminId == null) throw Exception('لم يتم العثور على معرف الأدمن');

      final Map<String, dynamic> approvedData = {
        'isApproved': true,
        'approvedAt': DateTime.now(),
        'status': 'approved',
        'approvedBy': adminId,
        'isRejected': false,
        'rejectionReason': null,
        'updatedAt': DateTime.now(),
      };

      // حاول على drivers أولاً ثم users للتوافقية
      try {
        await _firestore
            .collection('drivers')
            .doc(driverId)
            .update(approvedData);
      } catch (_) {
        await _firestore.collection('users').doc(driverId).update(approvedData);
      }

      return true;
    } catch (e) {
      logger.w('خطأ في الموافقة على السائق: $e');
      return false;
    }
  }

  /// رفض السائق (للأدمن)
  Future<bool> rejectDriver(String driverId, String reason) async {
    try {
      final adminId = currentUser.value?.id;
      if (adminId == null) throw Exception('لم يتم العثور على معرف الأدمن');

      final Map<String, dynamic> rejectedData = {
        'isRejected': true,
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': DateTime.now(),
        'rejectedBy': adminId,
        'isApproved': false,
        'updatedAt': DateTime.now(),
      };

      try {
        await _firestore
            .collection('drivers')
            .doc(driverId)
            .update(rejectedData);
      } catch (_) {
        await _firestore.collection('users').doc(driverId).update(rejectedData);
      }

      return true;
    } catch (e) {
      logger.w('خطأ في رفض السائق: $e');
      return false;
    }
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
