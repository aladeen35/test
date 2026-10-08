/// أدوات مشتركة لقسم «القرآن والحديث»: تطبيع النص العربي، قراءة ملفات البيانات، التنزيل والتخزين.
/// البيانات من مستودعَي fawazahmed0 (quran-api / hadith-api) — تُنزَّل عند أول استخدام ولا تُضمَّن في التطبيق.
library;

import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../screens/privacy_screen.dart' show supportEmail;

const quranApiBase = 'https://raw.githubusercontent.com/fawazahmed0/quran-api/1';
const hadithApiBase = 'https://raw.githubusercontent.com/fawazahmed0/hadith-api/1';

/// تاريخ آخر مراجعة لمحتوى القسم
const lastReviewed = '2026-10';

// ───────────────────────── تطبيع النص العربي ─────────────────────────

/// هل الحرف من التشكيل أو علامات المصحف أو التطويل (يُحذف عند البحث)؟
bool _isMark(int c) =>
    (c >= 0x064B && c <= 0x065F) || c == 0x0670 || (c >= 0x06D6 && c <= 0x06ED) || c == 0x0640 || (c >= 0x0610 && c <= 0x061A);

/// توحيد حرف واحد (أو null إن كان يُحذف)
String? _normChar(int c) {
  if (_isMark(c)) return null;
  switch (c) {
    case 0x0623: // أ
    case 0x0625: // إ
    case 0x0622: // آ
    case 0x0671: // ٱ
      return 'ا';
    case 0x0629: // ة
      return 'ه';
    case 0x0649: // ى
      return 'ي';
  }
  final s = String.fromCharCode(c);
  return s.toLowerCase();
}

/// تطبيع للبحث: حذف التشكيل والتطويل، توحيد الألف، ة→ه، ى→ي، وتوحيد المسافات
String normalizeArabic(String s) {
  final b = StringBuffer();
  var lastSpace = false;
  for (final c in s.runes) {
    final n = _normChar(c);
    if (n == null) continue;
    final sp = n.trim().isEmpty;
    if (sp) {
      if (!lastSpace) b.write(' ');
      lastSpace = true;
    } else {
      b.write(n);
      lastSpace = false;
    }
  }
  return b.toString().trim();
}

/// مواضع تطابق [query] داخل [original] بعد التطبيع — بمؤشرات النص الأصلي (لتلوين النتيجة)
List<(int, int)> matchRanges(String original, String query) {
  final q = normalizeArabic(query);
  if (q.isEmpty) return const [];
  final norm = StringBuffer();
  final map = <int>[]; // موضع كل حرف مطبّع في النص الأصلي (بوحدات UTF-16)
  var lastSpace = false;
  for (var i = 0; i < original.length; i++) {
    final n = _normChar(original.codeUnitAt(i));
    if (n == null) continue;
    final sp = n.trim().isEmpty;
    if (sp && lastSpace) continue;
    norm.write(sp ? ' ' : n);
    map.add(i);
    lastSpace = sp;
  }
  final ns = norm.toString();
  final out = <(int, int)>[];
  var from = 0;
  while (true) {
    final idx = ns.indexOf(q, from);
    if (idx < 0) break;
    final start = map[idx];
    var end = map[idx + q.length - 1] + 1;
    // نضم علامات التشكيل التي تلي آخر حرف
    while (end < original.length && _isMark(original.codeUnitAt(end))) {
      end++;
    }
    out.add((start, end));
    from = idx + q.length;
  }
  return out;
}

/// نص منسّق مع تظليل مواضع البحث
TextSpan highlightSpan(String text, String query, TextStyle base, Color hl) {
  final r = matchRanges(text, query);
  if (r.isEmpty) return TextSpan(text: text, style: base);
  final kids = <TextSpan>[];
  var pos = 0;
  for (final (s, e) in r) {
    if (s > pos) kids.add(TextSpan(text: text.substring(pos, s)));
    kids.add(TextSpan(text: text.substring(s, e), style: TextStyle(backgroundColor: hl.withValues(alpha: .35), fontWeight: FontWeight.w800)));
    pos = e;
  }
  if (pos < text.length) kids.add(TextSpan(text: text.substring(pos)));
  return TextSpan(style: base, children: kids);
}

// ───────────────────────── القرآن ─────────────────────────

class Ayah {
  final int surah, ayah;
  final String text;
  const Ayah(this.surah, this.ayah, this.text);
}

const basmalaSimple = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

/// يقرأ ملف إصدار من quran-api: {"quran":[{"chapter":1,"verse":1,"text":"..."}]}
/// ويتسامح مع صيغ أخرى: قائمة مباشرة، أو خريطة بالسور {"1":{"1":"..."}} أو {"1":["...", ...]}.
/// [stripBasmala]: يحذف البسملة الملصقة ببداية الآية الأولى (عدا الفاتحة والتوبة) كما في بعض الإصدارات.
List<Ayah> parseQuranEdition(String json, {bool stripBasmala = false}) {
  final d = jsonDecode(json);
  final out = <Ayah>[];
  void add(int s, int a, Object? t) {
    if (t == null) return;
    var text = t.toString().trim();
    if (stripBasmala && a == 1 && s != 1 && s != 9) {
      final n = normalizeArabic(text);
      const nb = 'بسم الله الرحمن الرحيم';
      if (n.startsWith('$nb ')) {
        // نحذف بعدد كلمات البسملة الأربع
        final words = text.split(RegExp(r'\s+'));
        if (words.length > 4) text = words.sublist(4).join(' ');
      }
    }
    out.add(Ayah(s, a, text));
  }

  int? toInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v');

  Object? list = d;
  if (d is Map) list = d['quran'] ?? d['verses'] ?? d['data'] ?? d;
  if (list is List) {
    for (final e in list) {
      if (e is! Map) continue;
      final s = toInt(e['chapter'] ?? e['surah'] ?? e['sura']);
      final a = toInt(e['verse'] ?? e['ayah'] ?? e['aya']);
      if (s == null || a == null) continue;
      add(s, a, e['text']);
    }
  } else if (list is Map) {
    for (final se in list.entries) {
      final s = toInt(se.key);
      if (s == null) continue;
      final v = se.value;
      if (v is Map) {
        for (final ae in v.entries) {
          final a = toInt(ae.key);
          if (a != null) add(s, a, ae.value is Map ? (ae.value as Map)['text'] : ae.value);
        }
      } else if (v is List) {
        for (var i = 0; i < v.length; i++) {
          final x = v[i];
          if (x is Map) {
            add(s, toInt(x['verse']) ?? i + 1, x['text']);
          } else {
            add(s, i + 1, x);
          }
        }
      }
    }
  }
  out.sort((a, b) => a.surah != b.surah ? a.surah - b.surah : a.ayah - b.ayah);
  return out;
}

// ───────────────────────── الحديث ─────────────────────────

class HadithGrade {
  final String name, grade;
  const HadithGrade(this.name, this.grade);
}

class Hadith {
  final int number;
  final int? arabicNumber;
  final String text;
  final List<HadithGrade> grades;
  final int section;
  const Hadith(this.number, this.text, {this.arabicNumber, this.grades = const [], this.section = 0});
}

class HadithBook {
  final String name;
  final Map<int, String> sections;
  final List<Hadith> hadiths;
  const HadithBook(this.name, this.sections, this.hadiths);
}

/// يقرأ ملف hadith-api: {"metadata":{"name":..,"sections":{..}},"hadiths":[{"hadithnumber":1,"text":..,"grades":[..],"reference":{"book":..}}]}
HadithBook parseHadithEdition(String json) {
  final d = jsonDecode(json);
  if (d is! Map) return const HadithBook('', {}, []);
  final meta = d['metadata'] is Map ? d['metadata'] as Map : const {};
  final secs = <int, String>{};
  final sm = meta['sections'];
  if (sm is Map) {
    for (final e in sm.entries) {
      final k = int.tryParse('${e.key}');
      if (k != null && '${e.value}'.trim().isNotEmpty) secs[k] = '${e.value}'.trim();
    }
  }
  final list = d['hadiths'];
  final out = <Hadith>[];
  if (list is List) {
    for (final e in list) {
      if (e is! Map) continue;
      final n = e['hadithnumber'];
      final num? nn = n is num ? n : num.tryParse('$n');
      if (nn == null) continue;
      final g = <HadithGrade>[];
      if (e['grades'] is List) {
        for (final x in e['grades']) {
          if (x is Map && '${x['grade'] ?? ''}'.trim().isNotEmpty) g.add(HadithGrade('${x['name'] ?? ''}'.trim(), '${x['grade']}'.trim()));
        }
      }
      final ref = e['reference'];
      final an = e['arabicnumber'];
      out.add(Hadith(nn.toInt(), '${e['text'] ?? ''}'.trim(),
          arabicNumber: an is num ? an.toInt() : null, grades: g, section: ref is Map && ref['book'] is num ? (ref['book'] as num).toInt() : 0));
    }
  }
  return HadithBook('${meta['name'] ?? ''}', secs, out);
}

// ───────────────────────── التنزيل والتخزين ─────────────────────────

/// مجلد بيانات القسم داخل مستندات التطبيق (null على الويب أو عند تعذّره)
Future<Directory?> quranDataDir() => _dirFuture ??= _resolveDir();
Future<Directory?>? _dirFuture;

Future<Directory?> _resolveDir() async {
  if (kIsWeb) return null;
  try {
    final d = Directory('${(await getApplicationDocumentsDirectory()).path}/quran_data');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  } catch (_) {
    return null;
  }
}

/// ذاكرة مؤقتة للويب (لا يوجد نظام ملفات)
final Map<String, String> _webCache = {};

/// للاختبارات: وضع ملف في الذاكرة المؤقتة
void debugPutCache(String name, String text) => _webCache[name] = text;

/// قراءة ملف محفوظ (أو null)
Future<String?> readCached(String name) async {
  if (_webCache.containsKey(name)) return _webCache[name];
  final d = await quranDataDir();
  if (d == null) return null;
  try {
    final f = File('${d.path}/$name');
    if (await f.exists() && await f.length() > 0) return await f.readAsString();
  } catch (_) {}
  return null;
}

/// حجم ملف محفوظ بالبايت (أو null إن لم يكن موجودًا)
Future<int?> cachedSize(String name) async {
  if (_webCache.containsKey(name)) return utf8.encode(_webCache[name]!).length;
  final d = await quranDataDir();
  if (d == null) return null;
  try {
    final f = File('${d.path}/$name');
    if (await f.exists()) return await f.length();
  } catch (_) {}
  return null;
}

Future<void> deleteCached(String name) async {
  _webCache.remove(name);
  final d = await quranDataDir();
  if (d == null) return;
  try {
    final f = File('${d.path}/$name');
    if (await f.exists()) await f.delete();
  } catch (_) {}
}

/// ينزّل [url] ويحفظه باسم [name] مع تقدّم التنزيل؛ يعيد النص أو يرمي خطأ
Future<String> downloadText(String url, String name, {void Function(double? p)? onProgress}) async {
  final client = http.Client();
  try {
    final res = await client.send(http.Request('GET', Uri.parse(url))).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
    final total = res.contentLength ?? 0;
    final bytes = BytesBuilder(copy: false);
    var got = 0;
    await for (final chunk in res.stream.timeout(const Duration(seconds: 40))) {
      bytes.add(chunk);
      got += chunk.length;
      onProgress?.call(total > 0 ? got / total : null);
    }
    final text = utf8.decode(bytes.takeBytes());
    // تحقق أن الملف JSON صالح قبل حفظه
    jsonDecode(text);
    final d = await quranDataDir();
    if (d == null) {
      _webCache[name] = text;
    } else {
      final f = File('${d.path}/$name');
      final tmp = File('${f.path}.part');
      await tmp.writeAsString(text, flush: true);
      await tmp.rename(f.path);
    }
    return text;
  } finally {
    client.close();
  }
}

/// رسالة خطأ تنزيل موحّدة
String get downloadErrorText => t('ما قدرنا ننزّل البيانات — اتأكد من النت وجرّب تاني (محتاج نت أول مرة بس).',
    'تعذّر تنزيل البيانات — تحقّق من الاتصال وأعد المحاولة (يلزم الإنترنت في المرة الأولى فقط).',
    "Couldn't download the data — check your connection and retry (internet is needed the first time only).");

// ───────────────────────── مشاركة وبلاغ ─────────────────────────

Future<void> shareText(String text) async {
  try {
    await SharePlus.instance.share(ShareParams(text: text));
  } catch (_) {
    toast(t('ما قدرنا نشارك', 'تعذّرت المشاركة', "Couldn't share"));
  }
}

/// يفتح بريد البلاغ عن معلومة قديمة أو خاطئة
Future<void> reportIssue(String toolId, String item) async {
  final subject = Uri.encodeComponent('[$toolId] ${tr('معلومة قديمة/خاطئة', 'Outdated/wrong info')}: $item');
  try {
    final ok = await launchUrl(Uri.parse('mailto:$supportEmail?subject=$subject'));
    if (!ok) toast(supportEmail);
  } catch (_) {
    toast(supportEmail);
  }
}

/// سطر «آخر مراجعة» مع زر البلاغ
class ReviewedLine extends StatelessWidget {
  final String toolId, item;
  const ReviewedLine(this.toolId, this.item, {super.key});
  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .65);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 4, bottom: 8),
      child: Row(children: [
        Icon(Icons.history_rounded, size: 16, color: muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text('${t('آخر مراجعة', 'آخر مراجعة', 'Last reviewed')}: $lastReviewed',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: muted)),
        ),
        Flexible(
          child: TextButton.icon(
            onPressed: () => reportIssue(toolId, item),
            icon: Icon(Icons.flag_rounded, size: 16, color: readable(context, SD.henna)),
            label: Text(t('بلّغ عن خطأ', 'الإبلاغ عن خطأ', 'Report an error'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
          ),
        ),
      ]),
    );
  }
}

/// شريط تقدّم التنزيل
class DownloadProgress extends StatelessWidget {
  final String label;
  final double? value;
  const DownloadProgress(this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
            if (value != null) Text('${(value! * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: value, minHeight: 8)),
        ]),
      );
}
