# دليل الإعداد السريع - تطبيق النقل

## 🚀 الإعداد السريع

### 1. إعداد Firebase

1. **إنشاء مشروع Firebase**
   - اذهب إلى [Firebase Console](https://console.firebase.google.com/)
   - أنشئ مشروع جديد
   - اختر اسم المشروع: `transport-app`

2. **إضافة تطبيق Android**
   - Package name: `transport.app.com`
   - تحميل ملف `google-services.json`
   - وضعه في `android/app/`

3. **إضافة تطبيق iOS**
   - Bundle ID: `transport.app.com`
   - تحميل ملف `GoogleService-Info.plist`
   - وضعه في `ios/Runner/`

4. **تحديث Firebase Options**
   - استبدل القيم في `lib/firebase_options.dart`
   - استخدم القيم الحقيقية من Firebase Console

### 2. إعداد الخرائط

1. **Google Maps API Key**
   - اذهب إلى [Google Cloud Console](https://console.cloud.google.com/)
   - أنشئ مشروع جديد أو استخدم مشروع Firebase
   - فعّل Maps SDK for Android و iOS
   - أنشئ API Key

2. **تحديث API Key**
   - Android: `android/app/src/main/AndroidManifest.xml`
   - iOS: `ios/Runner/AppDelegate.swift`

### 3. تشغيل التطبيق

```bash
# تثبيت التبعيات
flutter pub get

# تشغيل التطبيق
flutter run
```

## 📱 اختبار التطبيق

### اختبار الراكب
1. افتح التطبيق
2. اختر "راكب"
3. أدخل رقم الهاتف
4. أدخل رمز التحقق (123456 للاختبار)
5. أكمل الملف الشخصي
6. جرب طلب رحلة

### اختبار السائق
1. افتح التطبيق
2. اختر "سائق"
3. أدخل رقم الهاتف
4. أدخل رمز التحقق (123456 للاختبار)
5. أكمل الملف الشخصي
6. فعّل وضع "متاح"

### اختبار الإدارة
1. افتح التطبيق
2. اختر "إدارة"
3. استخدم بيانات الدخول الافتراضية
4. جرب إرسال إشعار

## 🔧 إعدادات مهمة

### إعدادات Android
- `android/app/build.gradle`: تأكد من `minSdkVersion 23`
- `android/app/src/main/AndroidManifest.xml`: أضف أذونات الموقع

### إعدادات iOS
- `ios/Runner/Info.plist`: أضف أذونات الموقع
- `ios/Runner/AppDelegate.swift`: أضف Google Maps API Key

## 🐛 حل المشاكل الشائعة

### مشكلة Firebase
```
Error: No Firebase App '[DEFAULT]' has been created
```
**الحل**: تأكد من تحديث `firebase_options.dart` بالقيم الصحيحة

### مشكلة الخرائط
```
Error: Maps API key not found
```
**الحل**: تأكد من إضافة API Key في الملفات المطلوبة

### مشكلة الأذونات
```
Error: Location permission denied
```
**الحل**: تأكد من إضافة أذونات الموقع في AndroidManifest.xml و Info.plist

## 📞 الدعم

إذا واجهت أي مشاكل:
1. تحقق من الأخطاء في Console
2. تأكد من إعداد Firebase بشكل صحيح
3. تحقق من API Keys
4. راجع ملف README.md للمزيد من التفاصيل

---

**ملاحظة**: هذا الدليل للإعداد السريع. راجع README.md للمعلومات التفصيلية.
