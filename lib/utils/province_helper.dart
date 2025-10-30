class ProvinceHelper {
  static const Map<String, String> provinces = {
 '11': 'بغداد',
    '12': 'نينوى',
    '13': 'ميسان',
    '14': 'البصرة',
    '15': 'الأنبار',
    '16': 'القادسية',
    '17': 'بابل',
    '18': 'بابل',
    '19': 'كربلاء',
    '20': 'ديالى',
    '21': 'صلاح الدين',
    '22': 'أربيل',
    '23': 'حلبجة',
    '24': 'ذي قار',
    '25': 'كركوك',
    '26': 'صلاح الدين',
    '27': 'ذي قار',
    '30': 'النجف',
    '31': 'واسط',
  };

  static String getProvinceName(String code) {
    return provinces[code] ?? code;
  }

  static String getProvinceCode(String name) {
    for (var entry in provinces.entries) {
      if (entry.value == name) {
        return entry.key;
      }
    }
    return name;
  }

  static List<String> getAllProvinceCodes() {
    return provinces.keys.toList();
  }

  static List<String> getAllProvinceNames() {
    return provinces.values.toList();
  }
}
