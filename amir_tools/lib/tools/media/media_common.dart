import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/i18n.dart';
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
    toast(t('ما قدرنا نشارك الملف، جرّب تاني', 'تعذّرت مشاركة الملف، حاول مرة أخرى', "Couldn't share the file, try again"));
  }
}

/// تنسيق مدة طويلة جداً (لزمن كسر كلمات السر)
String humanTime(double seconds) {
  if (seconds.isNaN) return '—';
  if (seconds < 1) return tr('في لمح البصر', 'Instantly');
  const min = 60.0, hour = 3600.0, day = 86400.0, year = 31557600.0;
  String n(double v) => v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(v < 10 ? 1 : 0);
  if (seconds < min) return '${n(seconds)} ${tr('ثانية', 'seconds')}';
  if (seconds < hour) return '${n(seconds / min)} ${tr('دقيقة', 'minutes')}';
  if (seconds < day) return '${n(seconds / hour)} ${tr('ساعة', 'hours')}';
  if (seconds < year) return '${n(seconds / day)} ${tr('يوم', 'days')}';
  final y = seconds / year;
  if (y < 100) return '${n(y)} ${tr('سنة', 'years')}';
  if (y < 1e3) return '${n(y / 100)} ${tr('قرن', 'centuries')}';
  if (y < 1e6) return '${n(y / 1e3)} ${tr('ألف سنة', 'thousand years')}';
  if (y < 1e9) return '${n(y / 1e6)} ${tr('مليون سنة', 'million years')}';
  if (y < 1.38e10) return '${n(y / 1e9)} ${tr('مليار سنة', 'billion years')}';
  return tr('أطول من عمر الكون 🌌', 'Longer than the age of the universe 🌌');
}
