# ملخص كوليكشنز Firebase للداشبورد

## الكوليكشنز الأساسية

### 1. الراكبين (riders)
```json
{
  "id": "string",
  "name": "string",
  "phone": "string", 
  "email": "string",
  "profileImage": "string (optional)",
  "balance": "number",
  "createdAt": "timestamp",
  "isActive": "boolean",
  "isVerified": "boolean",
  "isApproved": "boolean",
  "approvedAt": "timestamp (optional)",
  "approvedBy": "string (optional)",
  "isRejected": "boolean",
  "rejectedAt": "timestamp (optional)",
  "rejectedBy": "string (optional)",
  "rejectionReason": "string (optional)",
  "isProfileComplete": "boolean",
  "fcmToken": "string (optional)",
  "currentLocation": "string (optional)",
  "favoriteLocations": ["string"],
  "totalTrips": "number",
  "totalSpent": "number"
}
```

### 2. السائقين (drivers)
```json
{
  "id": "string",
  "name": "string",
  "phone": "string",
  "email": "string", 
  "profileImage": "string (optional)",
  "balance": "number",
  "createdAt": "timestamp",
  "isActive": "boolean",
  "isVerified": "boolean",
  "isApproved": "boolean",
  "approvedAt": "timestamp (optional)",
  "approvedBy": "string (optional)",
  "isRejected": "boolean",
  "rejectedAt": "timestamp (optional)",
  "rejectedBy": "string (optional)",
  "rejectionReason": "string (optional)",
  "isProfileComplete": "boolean",
  
  // بيانات السائق المطلوبة
  "nationalId": "string (optional)",
  "nationalIdImage": "string (optional)",
  "drivingLicense": "string (optional)",
  "drivingLicenseImage": "string (optional)",
  "vehicleLicense": "string (optional)",
  "vehicleLicenseImage": "string (optional)",
  "vehicleType": "string (car/motorcycle/van/truck)",
  "vehicleModel": "string (optional)",
  "vehicleColor": "string (optional)",
  "vehiclePlateNumber": "string (optional)",
  "vehicleImage": "string (optional)",
  "insuranceImage": "string (optional)",
  "backgroundCheckImage": "string (optional)",
  
  // حالة السائق
  "status": "string (pending/approved/rejected/suspended)",
  "isOnline": "boolean",
  "isAvailable": "boolean",
  "currentLocation": "string (optional)",
  "currentLatitude": "number (optional)",
  "currentLongitude": "number (optional)",
  
  // إحصائيات
  "totalTrips": "number",
  "totalEarnings": "number",
  "rating": "number",
  "ratingCount": "number",
  
  // بيانات إضافية
  "emergencyContact": "string (optional)",
  "emergencyContactName": "string (optional)",
  "documents": ["string"],
  "vehicleDetails": "object (optional)",
  "fcmToken": "string (optional)"
}
```

### 3. الرحلات (trips)
```json
{
  "id": "string",
  "riderId": "string",
  "driverId": "string (optional)",
  "pickupLocation": {
    "address": "string",
    "latitude": "number",
    "longitude": "number"
  },
  "destinationLocation": {
    "address": "string", 
    "latitude": "number",
    "longitude": "number"
  },
  "status": "string (pending/accepted/started/completed/cancelled)",
  "requestedAt": "timestamp",
  "acceptedAt": "timestamp (optional)",
  "startedAt": "timestamp (optional)",
  "completedAt": "timestamp (optional)",
  "cancelledAt": "timestamp (optional)",
  "cancelledBy": "string (optional)",
  "cancellationReason": "string (optional)",
  "estimatedPrice": "number",
  "finalPrice": "number (optional)",
  "discountCode": "string (optional)",
  "discountAmount": "number (optional)",
  "paymentMethod": "string (cash/card/discount_code)",
  "paymentStatus": "string (pending/completed/failed)",
  "driverRating": "number (optional)",
  "riderRating": "number (optional)",
  "notes": "string (optional)"
}
```

### 4. المدفوعات (payments)
```json
{
  "id": "string",
  "tripId": "string",
  "riderId": "string",
  "driverId": "string",
  "amount": "number",
  "paymentMethod": "string (cash/card/discount_code)",
  "status": "string (pending/completed/failed)",
  "createdAt": "timestamp",
  "completedAt": "timestamp (optional)",
  "transactionId": "string (optional)",
  "notes": "string (optional)"
}
```

### 5. أكواد الخصم (discount_codes)
```json
{
  "id": "string",
  "code": "string",
  "discountAmount": "number",
  "minimumAmount": "number",
  "maxUses": "number",
  "currentUses": "number",
  "expiryDate": "timestamp",
  "isActive": "boolean",
  "createdAt": "timestamp",
  "createdBy": "string",
  "description": "string (optional)",
  "applicableUserIds": ["string"]
}
```

### 6. الأكواد المستخدمة (used_codes)
```json
{
  "id": "string",
  "codeId": "string",
  "userId": "string",
  "tripId": "string",
  "originalAmount": "number",
  "discountedAmount": "number",
  "usedAt": "timestamp"
}
```

### 7. التنبيهات (notifications)
```json
{
  "id": "string",
  "userId": "string",
  "title": "string",
  "body": "string",
  "type": "string (trip/payment/approval/general)",
  "isRead": "boolean",
  "createdAt": "timestamp",
  "data": "object (optional)"
}
```

## العمليات المطلوبة في الداشبورد

### إدارة الراكبين
- عرض جميع الراكبين
- تفعيل/إلغاء تفعيل راكب
- حذف راكب
- عرض إحصائيات الراكب

### إدارة السائقين
- عرض جميع السائقين
- عرض السائقين في انتظار الموافقة
- الموافقة/رفض سائق
- عرض المستندات المرفوعة
- تفعيل/إلغاء تفعيل سائق
- حذف سائق

### إدارة الرحلات
- عرض جميع الرحلات
- عرض الرحلات حسب الحالة
- عرض تفاصيل رحلة
- إلغاء رحلة
- عرض إحصائيات الرحلات

### إدارة المدفوعات
- عرض جميع المدفوعات
- عرض المدفوعات حسب الحالة
- تأكيد/رفض دفعة
- عرض إحصائيات المدفوعات

### إدارة أكواد الخصم
- إنشاء كود خصم جديد
- عرض جميع الأكواد
- تفعيل/إلغاء تفعيل كود
- حذف كود
- عرض إحصائيات الأكواد

### إدارة التنبيهات
- إرسال تنبيه لجميع المستخدمين
- إرسال تنبيه لمستخدم معين
- عرض سجل التنبيهات

## الإحصائيات المطلوبة

### إحصائيات عامة
- إجمالي عدد الراكبين
- إجمالي عدد السائقين
- إجمالي عدد الرحلات
- إجمالي المدفوعات
- عدد الرحلات اليوم/الأسبوع/الشهر

### إحصائيات السائقين
- عدد السائقين المتصلين
- عدد السائقين المتاحين
- عدد السائقين في انتظار الموافقة
- متوسط تقييم السائقين

### إحصائيات المدفوعات
- إجمالي المدفوعات اليوم/الأسبوع/الشهر
- عدد المدفوعات المعلقة
- متوسط قيمة الرحلة

### إحصائيات أكواد الخصم
- عدد الأكواد النشطة
- عدد الأكواد المستخدمة
- إجمالي الخصومات المطبقة

## ملاحظات مهمة

1. **الأمان**: يجب إعداد قواعد Firestore مناسبة لحماية البيانات
2. **الفهرسة**: إعداد الفهارس المناسبة للاستعلامات السريعة
3. **النسخ الاحتياطي**: إعداد نسخ احتياطي منتظم للبيانات
4. **المراقبة**: مراقبة استخدام قاعدة البيانات والأخطاء
5. **التوسع**: تصميم البنية لتسهيل التوسع المستقبلي
