# إعداد Firebase لحل مشكلة الصلاحيات

## المشكلة
التطبيق يواجه خطأ `permission-denied` عند محاولة الكتابة في Firestore.

## الحل

### 1. تثبيت Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. تسجيل الدخول في Firebase
```bash
firebase login
```

### 3. تهيئة المشروع
```bash
firebase init
```
اختر:
- Firestore
- Hosting (اختياري)

### 4. تطبيق قواعد الأمان
```bash
firebase deploy --only firestore:rules
```

### 5. تطبيق الفهارس
```bash
firebase deploy --only firestore:indexes
```

## قواعد الأمان المطبقة

- **المستخدمون**: يمكنهم قراءة وكتابة بياناتهم الخاصة فقط
- **الرحلات**: يمكن للمستخدمين قراءة وكتابة الرحلات الخاصة بهم
- **الإشعارات**: يمكن للمستخدمين قراءة وكتابة إشعاراتهم
- **المحافظ**: يمكن للمستخدمين قراءة وكتابة محافظهم
- **المعاملات**: يمكن للمستخدمين قراءة وكتابة معاملاتهم

## ملاحظات مهمة

1. تأكد من أن المستخدم مسجل دخول في Firebase Auth قبل الكتابة
2. تأكد من أن معرف المستخدم في المستند يطابق `request.auth.uid`
3. إذا استمرت المشكلة، تحقق من إعدادات Firebase Console

## اختبار القواعد
```bash
firebase emulators:start --only firestore
```
