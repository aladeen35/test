import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/i18n.dart';

/// منبّه بسيط: اهتزاز + صوت النظام + (اختياريًا) نطق رسالة
class Alarm {
  static FlutterTts? _tts;
  static Timer? _loop;

  static Future<void> ring(String speech, {int times = 6}) async {
    stop();
    var n = 0;
    void beat() {
      try {
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }

    beat();
    _loop = Timer.periodic(const Duration(milliseconds: 700), (t) {
      n++;
      beat();
      if (n >= times) t.cancel();
    });
    if (kIsWeb) return;
    try {
      _tts ??= FlutterTts();
      await _tts!.setLanguage(isEn ? 'en-US' : 'ar');
      await _tts!.speak(speech);
    } catch (_) {/* لا يوجد محرك نطق */}
  }

  static void stop() {
    _loop?.cancel();
    _loop = null;
    try {
      _tts?.stop();
    } catch (_) {}
  }
}

/// إبقاء الشاشة شغالة (بأمان على كل المنصات)
Future<void> keepAwake(bool on) async {
  try {
    await WakelockPlus.toggle(enable: on);
  } catch (_) {}
}
