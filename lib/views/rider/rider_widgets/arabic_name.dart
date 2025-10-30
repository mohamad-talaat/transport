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

    _translations.forEach((english, arabic) {
      result = result.replaceAll(RegExp(english, caseSensitive: false), arabic);
    });

    if (result == text && !_isArabic(text)) {
      return 'موقع - $text';
    }

    return result;
  }

  static bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }
}

String translateLocationName(String locationName) {
  return ArabicLocationHelper.translateToArabic(locationName);
}
