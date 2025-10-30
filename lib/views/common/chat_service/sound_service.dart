import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:transport_app/main.dart';

class SoundService extends GetxService {
  static SoundService get to => Get.find();
  final AudioPlayer _player = AudioPlayer();

  Future<void> playMessageSound() async {
    try {
      await _player.play(AssetSource('sounds/message.mp3'));
    } catch (e) {
      logger.d('❌ خطأ: $e');
    }
  }

  Future<void> playNewTripSound() async {
    try {
      await _player.play(AssetSource('sounds/new_trip.mp3'));
    } catch (e) {
      logger.d('❌ خطأ: $e');
    }
  }

  Future<void> playDriverArrivedSound() async {
    try {
      await _player.play(AssetSource('sounds/driver_arrived.mp3'));
    } catch (e) {
      logger.d('❌ خطأ: $e');
    }
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
