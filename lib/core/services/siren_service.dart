import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays a looping siren for responders when a new SOS arrives.
/// Auto-stops after [maxDuration] so it can never ring forever.
class SirenService extends ChangeNotifier {
  SirenService._();
  static final SirenService instance = SirenService._();

  AudioPlayer? _player; // created lazily so a missing plugin can never break a build
  Timer? _autoStop;
  bool _playing = false;

  bool get isPlaying => _playing;

  Future<void> play({Duration maxDuration = const Duration(seconds: 25)}) async {
    _autoStop?.cancel();
    _autoStop = Timer(maxDuration, stop);
    if (_playing) return;

    _playing = true;
    notifyListeners();
    try {
      final player = _player ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(1.0);
      await player.play(AssetSource('sounds/siren.wav'));
    } catch (error) {
      // Browsers block audio until the user has interacted with the page.
      debugPrint('Siren could not start: $error');
      _autoStop?.cancel();
      _playing = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _autoStop?.cancel();
    if (!_playing) return;
    _playing = false;
    notifyListeners();
    try {
      await _player?.stop();
    } catch (error) {
      debugPrint('Siren stop failed: $error');
    }
  }
}
