import 'package:get_storage/get_storage.dart';
import 'package:transport_app/models/trip_model.dart';
 
class RiderTypeStorageService {
  final GetStorage _storage = GetStorage();
  static const String _riderTypeKey = 'selected_rider_type';

  void saveSelectedRiderType(RiderType type) {
    _storage.write(_riderTypeKey, type.name);
  }

  RiderType? getSavedRiderType() {
    final saved = _storage.read(_riderTypeKey);
    if (saved != null) {
      try {
        return RiderType.values.firstWhere((e) => e.name == saved);
      } catch (e) {
        // إذا لم يتم العثور على النوع، قد يكون بسبب تحديث في الـ enum
        return null;
      }
    }
    return null;
  }
}