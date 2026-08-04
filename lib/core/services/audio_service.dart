import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  static AudioService get instance => _instance;
  AudioService._internal();

  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isTicking = false;

  Future<void> playTick() async {
    try {
      if (_isTicking) return;
      _isTicking = true;
      await _tickPlayer.setSourceUrl('https://actions.google.com/sounds/v1/tools/clock_ticking.ogg');
      await _tickPlayer.setReleaseMode(ReleaseMode.loop);
      await _tickPlayer.resume();
    } catch (e) {
      debugPrint('AudioService playTick error: $e');
    }
  }

  Future<void> stopTick() async {
    try {
      _isTicking = false;
      await _tickPlayer.stop();
    } catch (e) {
      debugPrint('AudioService stopTick error: $e');
    }
  }

  Future<void> playExplosionOrWhistle() async {
    try {
      await stopTick();
      await _sfxPlayer.stop();
      await _sfxPlayer.setSourceUrl('https://actions.google.com/sounds/v1/cartoon/boing_cartoon.ogg');
      await _sfxPlayer.resume();
    } catch (e) {
      debugPrint('AudioService playExplosion error: $e');
    }
  }

  Future<void> playVictory() async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setSourceUrl('https://actions.google.com/sounds/v1/cartoon/tada_fanfare.ogg');
      await _sfxPlayer.resume();
    } catch (e) {
      debugPrint('AudioService playVictory error: $e');
    }
  }
}
