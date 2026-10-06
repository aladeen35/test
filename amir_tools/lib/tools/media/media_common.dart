import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/state.dart';

/// يشارك بايتات ملف (صورة مثلاً): يكتبها في مجلد مؤقت على الجوال، أو يشاركها مباشرة على الويب.
Future<void> shareBytes(Uint8List bytes, String fileName, String mime, {String? text}) async {
  try {
    XFile f;
    if (kIsWeb) {
      f = XFile.fromData(bytes, name: fileName, mimeType: mime);
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      f = XFile(file.path, mimeType: mime, name: fileName);
    }
    await SharePlus.instance.share(ShareParams(files: [f], text: text));
  } catch (e) {
    toast('ما قدرنا نشارك الملف، جرّب تاني');
  }
}

/// تنسيق مدة طويلة جداً (لزمن كسر كلمات السر)
String humanTime(double seconds) {
  if (seconds.isNaN) return '—';
  if (seconds < 1) return 'في لمح البصر';
  const min = 60.0, hour = 3600.0, day = 86400.0, year = 31557600.0;
  String n(double v) => v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(v < 10 ? 1 : 0);
  if (seconds < min) return '${n(seconds)} ثانية';
  if (seconds < hour) return '${n(seconds / min)} دقيقة';
  if (seconds < day) return '${n(seconds / hour)} ساعة';
  if (seconds < year) return '${n(seconds / day)} يوم';
  final y = seconds / year;
  if (y < 100) return '${n(y)} سنة';
  if (y < 1e3) return '${n(y / 100)} قرن';
  if (y < 1e6) return '${n(y / 1e3)} ألف سنة';
  if (y < 1e9) return '${n(y / 1e6)} مليون سنة';
  if (y < 1.38e10) return '${n(y / 1e9)} مليار سنة';
  return 'أطول من عمر الكون 🌌';
}
