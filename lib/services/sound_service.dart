import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  factory SoundService() {
    return _instance;
  }

  SoundService._internal();

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _audioPlayer.setSource(AssetSource('sounds/beep.mp3'));
      _isInitialized = true;
    }
  }

  Future<void> playBeep() async {
    try {
      await initialize();
      await _audioPlayer.resume();
    } catch (e) {
      if (kDebugMode) {
        print('Error playing beep sound: $e');
      }
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
