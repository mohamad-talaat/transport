#!/usr/bin/env python3
"""
Interactive user input script for collecting next instructions.
"""

def get_user_input():
    """Get the next user instruction."""
    print("\n" + "="*50)
    print("✅ تم إصلاح المشاكل التالية:")
    print("1. ✅ إضافة متغيرات منفصلة لـ pickup location و pickup address")
    print("2. ✅ تعديل دالة _requestTrip لاستخدام نقطة الانطلاق المختارة")
    print("3. ✅ إصلاح مشكلة عدم ظهور الماركرز في driver_tracking_view")
    print("4. ✅ إضافة مستمع لتحديثات الرحلة في driver_tracking_view")
    print("\n📋 ملخص التعديلات:")
    print("- تم إضافة pickupLocation و pickupAddress في MyMapController")
    print("- تم تعديل confirmPickupLocation لحفظ نقطة الانطلاق")
    print("- تم تعديل _requestTrip لاستخدام pickupLocation بدلاً من currentLocation")
    print("- تم إضافة مستمع لتحديثات الرحلة في driver_tracking_view")
    print("="*50)
    
    while True:
        try:
            user_input = input("\n💬 ما هي التعليمات التالية؟ (اكتب 'exit' للخروج): ").strip()
            
            if user_input.lower() == 'exit':
                print("👋 شكراً لك! تم الانتهاء من الجلسة.")
                return None
                
            if user_input:
                return user_input
            else:
                print("⚠️  يرجى إدخال تعليمة صحيحة.")
                
        except KeyboardInterrupt:
            print("\n👋 تم إلغاء العملية.")
            return None
        except Exception as e:
            print(f"❌ خطأ في الإدخال: {e}")
            return None

if __name__ == "__main__":
    get_user_input()