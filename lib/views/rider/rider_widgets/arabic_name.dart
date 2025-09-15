// أضف هذا الكلاس في ملف map_controller.dart في الأعلى
class ArabicLocationHelper {
  static final Map<String, String> _translations = {
    'Street': 'شارع',
    'Road': 'طريق',
    'Avenue': 'جادة',
    'Boulevard': 'بوليفارد',
    'Square': 'ميدان',
    'District': 'منطقة',
    'Neighborhood': 'حي',
    'City': 'مدينة',
    'Bridge': 'جسر',
    'Market': 'سوق',
    'School': 'مدرسة',
    'Hospital': 'مستشفى',
    'Mosque': 'مسجد',
    'Park': 'حديقة',
    'Restaurant': 'مطعم',
    'Hotel': 'فندق',
    'Bank': 'بنك',
    'Mall': 'مول',
    'Station': 'محطة',
    'Airport': 'مطار',
    'University': 'جامعة',
    'Building': 'مبنى',
    'Complex': 'مجمع',
    'Center': 'مركز',
    'North': 'شمال',
    'South': 'جنوب',
    'East': 'شرق',
    'West': 'غرب',
    'Current Location': 'الموقع الحالي',
    'Selected Location': 'الموقع المحدد',
    'Destination': 'الوجهة',
  };

  static String translateToArabic(String text) {
    if (text.isEmpty) return text;
    
    String result = text;
    
    // ترجمة الكلمات المعروفة
    _translations.forEach((english, arabic) {
      result = result.replaceAll(RegExp(english, caseSensitive: false), arabic);
    });
    
    // إذا لم يتم العثور على ترجمة، أعد النص كما هو مع إضافة "موقع" في البداية
    if (result == text && !_isArabic(text)) {
      return 'موقع - $text';
    }
    
    return result;
  }

  static bool _isArabic(String text) {
    // تحقق من وجود حروف عربية في النص
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }
}

// استخدم هذه الدالة في كل مكان تحتاج فيه لعرض اسم موقع
String translateLocationName(String locationName) {
  return ArabicLocationHelper.translateToArabic(locationName);
}