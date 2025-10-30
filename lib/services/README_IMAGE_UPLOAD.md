# نظام رفع الصور الذكي - دليل الاستخدام

## نظرة عامة

تم إنشاء نظام ذكي لرفع الصور يحل مشكلة Firebase Storage المدفوع ويوفر 3 حلول مختلفة:

1. **الحفظ المحلي** (مجاني) - الصور محفوظة في التطبيق
2. **ImgBB** (مجاني) - رفع للإنترنت مع 32 ميجابايت لكل صورة
3. **Firebase Storage** (مدفوع) - خدمة سحابية احترافية

## الخدمات المضافة

### 1. ImageUploadService

الخدمة الرئيسية التي تختار أفضل حل متاح تلقائياً:

```dart
// استخدام الخدمة الذكية
final imageService = Get.find<ImageUploadService>();

// رفع صورة
final imageUrl = await imageService.uploadImage(
  imageFile: file,
  folder: 'drivers/$driverId/documents',
  fileName: 'license_${DateTime.now().millisecondsSinceEpoch}',
);

// تغيير الطريقة المفضلة
await imageService.setPreferredMethod(ImageUploadService.local);
await imageService.setPreferredMethod(ImageUploadService.imgbb);
await imageService.setPreferredMethod(ImageUploadService.firebaseStorage);
```

### 2. FreeImageUploadService (ImgBB)

خدمة رفع مجانية باستخدام ImgBB:

```dart
final imgbbService = Get.find<FreeImageUploadService>();

// رفع صورة إلى ImgBB
final imageUrl = await imgbbService.uploadImageToImgBB(
  imageFile: file,
  customName: 'my_image',
);
```

### 3. LocalImageService

خدمة حفظ محلي:

```dart
final localService = Get.find<LocalImageService>();

// حفظ صورة محلياً
final imagePath = await localService.saveImageLocally(
  imageFile: file,
  folder: 'drivers/$driverId/documents',
  fileName: 'license_${DateTime.now().millisecondsSinceEpoch}',
);

// الحصول على الصور المحفوظة
final savedImages = await localService.getSavedImages();

// مسح جميع الصور
await localService.clearAllImages();
```

## كيفية الاستخدام

### 1. من خلال الإعدادات

1. اذهب إلى **الإعدادات** في التطبيق
2. اختر **إعدادات رفع الصور**
3. اختر الطريقة المفضلة:
   - **محلي (مجاني)** - سريع ولا يحتاج إنترنت
   - **ImgBB (مجاني)** - رفع للإنترنت
   - **Firebase Storage (مدفوع)** - احترافي وآمن

### 2. برمجياً

```dart
// الحصول على الخدمة
final imageService = Get.find<ImageUploadService>();

// اختيار صورة
final file = await imageService.pickImageFromGallery();
// أو
final file = await imageService.takePhotoWithCamera();

// رفع الصورة
if (file != null) {
  final result = await imageService.uploadImage(
    imageFile: file,
    folder: 'users/$userId/profile',
    fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}',
  );

  if (result != null) {
    logger.w('تم رفع الصورة: $result');
  }
}
```

## إعداد ImgBB (اختياري)

إذا كنت تريد استخدام ImgBB:

1. اذهب إلى [ImgBB API](https://api.imgbb.com/)
2. انقر على "Get API Key"
3. أدخل بريدك الإلكتروني
4. احصل على المفتاح
5. استبدل المفتاح في `lib/services/free_image_upload_service.dart`:

```dart
static const String _imgbbApiKey = 'YOUR_API_KEY_HERE';
```

## المميزات

### الحفظ المحلي

- ✅ مجاني تماماً
- ✅ سريع جداً
- ✅ لا يحتاج إنترنت
- ✅ آمن ومحمي
- ❌ مساحة محدودة
- ❌ لا يمكن مشاركة الصور

### ImgBB

- ✅ مجاني تماماً
- ✅ رفع للإنترنت
- ✅ 32 ميجابايت لكل صورة
- ✅ لا يحتاج تسجيل
- ❌ لا يمكن حذف الصور
- ❌ محدود بـ 32 ميجابايت

### Firebase Storage

- ✅ خدمة احترافية
- ✅ مساحة غير محدودة
- ✅ تحكم كامل
- ✅ أمان عالي
- ❌ مدفوع ($5 شهرياً)
- ❌ يحتاج إعداد معقد

## استكشاف الأخطاء

### إذا فشل رفع الصور:

1. **تحقق من الاتصال**: تأكد من وجود إنترنت
2. **جرب طريقة أخرى**: النظام سيجرب تلقائياً
3. **تحقق من المساحة**: إذا كنت تستخدم الحفظ المحلي
4. **تحقق من API Key**: إذا كنت تستخدم ImgBB

### رسائل الخطأ الشائعة:

- `No AppCheckProvider installed`: Firebase Storage غير مفعل
- `Object does not exist`: الملف غير موجود في Storage
- `TimeoutException`: مشكلة في الاتصال
- `API key invalid`: مفتاح ImgBB غير صحيح

## التوصيات

### للتطوير والاختبار:

```dart
// استخدم الحفظ المحلي
await imageService.setPreferredMethod(ImageUploadService.local);
```

### للتطبيق الإنتاجي:

```dart
// استخدم ImgBB أو Firebase
await imageService.setPreferredMethod(ImageUploadService.imgbb);
// أو
await imageService.setPreferredMethod(ImageUploadService.firebaseStorage);
```

### للاستخدام المختلط:

```dart
// دع النظام يختار تلقائياً
// سيجرب الطريقة المفضلة أولاً، ثم الطرق الأخرى
```

## التحديثات المستقبلية

- [ ] دعم Cloudinary
- [ ] دعم AWS S3
- [ ] ضغط الصور تلقائياً
- [ ] دعم الفيديو
- [ ] مزامنة الصور بين الأجهزة

## الدعم

إذا واجهت أي مشاكل:

1. تحقق من هذا الملف
2. راجع الأخطاء في Console
3. جرب طريقة رفع مختلفة
4. تأكد من إعدادات Firebase/ImgBB

---

**ملاحظة**: جميع الحلول المجانية متاحة ومُختبرة. اختر ما يناسب احتياجاتك!
