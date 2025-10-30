@echo off
echo.
echo ==================================================
echo ✅ تم إصلاح المشاكل التالية:
echo 1. ✅ إضافة متغيرات منفصلة لـ pickup location و pickup address
echo 2. ✅ تعديل دالة _requestTrip لاستخدام نقطة الانطلاق المختارة
echo 3. ✅ إصلاح مشكلة عدم ظهور الماركرز في driver_tracking_view
echo 4. ✅ إضافة مستمع لتحديثات الرحلة في driver_tracking_view
echo.
echo 📋 ملخص التعديلات:
echo - تم إضافة pickupLocation و pickupAddress في MyMapController
echo - تم تعديل confirmPickupLocation لحفظ نقطة الانطلاق
echo - تم تعديل _requestTrip لاستخدام pickupLocation بدلاً من currentLocation
echo - تم إضافة مستمع لتحديثات الرحلة في driver_tracking_view
echo ==================================================
echo.
set /p user_input="💬 ما هي التعليمات التالية؟ (اكتب 'exit' للخروج): "
if "%user_input%"=="exit" (
    echo 👋 شكراً لك! تم الانتهاء من الجلسة.
    exit /b
)
echo تم استلام التعليمات: %user_input%
