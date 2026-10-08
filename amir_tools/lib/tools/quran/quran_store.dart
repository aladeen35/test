/// مخزن نص المصحف والتفاسير (يُحمَّل مرة واحدة في الذاكرة ويُشارك بين الأدوات)
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/i18n.dart';
import '../more/khatma_data.dart' show surahNames;
import 'quran_common.dart';

/// إصدار من quran-api (نص أو تفسير أو ترجمة)
class QEdition {
  final String id, file, nameAr, nameEn, sourceAr, sourceEn;
  final double approxMb;
  final bool rtl;
  const QEdition(this.id, this.file, this.nameAr, this.nameEn, this.sourceAr, this.sourceEn, this.approxMb, {this.rtl = true});
  String get name => tr(nameAr, nameEn);
  String get source => tr(sourceAr, sourceEn);
  String get cacheName => '$file.json';
  String get url => '$quranApiBase/editions/$file.min.json';
}

/// نص المصحف بالرسم الإملائي المبسّط (Tanzil «Quran Simple»)
const quranTextEdition = QEdition('text', 'ara-quransimple', 'نص المصحف (رسم إملائي مبسّط)', "Qur'an text (simple script)",
    'Tanzil «Quran Simple» عبر مستودع fawazahmed0/quran-api', 'Tanzil “Quran Simple” via fawazahmed0/quran-api', 1.5);

/// التفاسير والترجمة المتاحة
const tafsirEditions = [
  QEdition('muyassar', 'ara-kingfahadquranc', 'التفسير الميسّر', 'Al-Muyassar (Arabic tafsir)', 'التفسير الميسّر — مجمع الملك فهد لطباعة المصحف الشريف (عبر Tanzil)',
      'Al-Tafsir al-Muyassar — King Fahd Glorious Qur\'an Printing Complex (via Tanzil)', 2.7),
  QEdition('jalalayn', 'ara-jalaladdinalmah', 'تفسير الجلالين', 'Tafsir al-Jalalayn (Arabic)', 'تفسير الجلالين — جلال الدين المحلّي وجلال الدين السيوطي (عبر Tanzil)',
      'Tafsir al-Jalalayn — Jalal al-Din al-Mahalli & Jalal al-Din al-Suyuti (via Tanzil)', 2.1),
  QEdition('saheeh', 'eng-ummmuhammad', 'ترجمة المعاني بالإنجليزية (صحيح إنترناشيونال)', 'English — Saheeh International',
      'Saheeh International (Umm Muhammad) — ترجمة معاني، عبر Tanzil', 'Saheeh International (Umm Muhammad) — translation of meanings, via Tanzil', 1.1,
      rtl: false),
];

QEdition tafsirById(String id) => tafsirEditions.firstWhere((e) => e.id == id, orElse: () => tafsirEditions.first);

/// اسم السورة بالعربية (1..114)
String surahName(int s) => s >= 1 && s <= surahNames.length ? surahNames[s - 1] : '$s';

/// المرجع: «(سورة البقرة: 255)» أو «(سورة البقرة: 1–5)»
String ayahRef(int s, int a, [int? to]) => '(سورة ${surahName(s)}: ${to != null && to > a ? '$a–$to' : '$a'})';

List<Ayah> _parseText(String s) => parseQuranEdition(s, stripBasmala: true);
List<Ayah> _parsePlain(String s) => parseQuranEdition(s);
List<String> _normAll(List<String> l) => [for (final x in l) normalizeArabic(x)];

class QuranStore {
  QuranStore._();
  static final instance = QuranStore._();

  List<Ayah>? ayat;
  List<String>? _norm;

  /// موضع أول آية لكل سورة في [ayat]
  final Map<int, int> _start = {};
  final Map<int, int> _count = {};

  final Map<String, Map<int, String>> _tafsir = {};

  bool get ready => ayat != null && ayat!.isNotEmpty;

  int ayahCount(int s) => _count[s] ?? 0;

  List<Ayah> surah(int s) {
    final st = _start[s];
    if (!ready || st == null) return const [];
    return ayat!.sublist(st, st + (_count[s] ?? 0));
  }

  Ayah? ayah(int s, int a) {
    final st = _start[s];
    if (!ready || st == null || a < 1 || a > (_count[s] ?? 0)) return null;
    return ayat![st + a - 1];
  }

  void _index(List<Ayah> list) {
    _start.clear();
    _count.clear();
    for (var i = 0; i < list.length; i++) {
      final a = list[i];
      _start.putIfAbsent(a.surah, () => i);
      _count[a.surah] = (_count[a.surah] ?? 0) + 1;
    }
    ayat = list;
  }

  /// للاختبارات: تحميل نص جاهز مباشرة
  @visibleForTesting
  void debugLoad(List<Ayah> list) {
    _index(list);
    _norm = _normAll([for (final a in list) a.text]);
  }

  /// للاختبارات: تحميل تفسير جاهز
  @visibleForTesting
  void debugLoadTafsir(String id, List<Ayah> list) => _tafsir[id] = {for (final a in list) a.surah * 1000 + a.ayah: a.text};

  /// يحمّل النص من الملف المحفوظ إن وُجد
  Future<bool> loadLocal() async {
    if (ready) return true;
    final s = await readCached(quranTextEdition.cacheName);
    if (s == null) return false;
    try {
      final list = await compute(_parseText, s);
      if (list.length < 6000) return false;
      _index(list);
      _norm = await compute(_normAll, [for (final a in list) a.text]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> download({void Function(double?)? onProgress}) async {
    await downloadText(quranTextEdition.url, quranTextEdition.cacheName, onProgress: onProgress);
    return loadLocal();
  }

  Future<void> deleteText() async {
    await deleteCached(quranTextEdition.cacheName);
    ayat = null;
    _norm = null;
    _start.clear();
    _count.clear();
  }

  /// بحث بعد التطبيع؛ يعيد مواضع الآيات المطابقة (بحد أقصى [limit]) والعدد الكلي
  (List<Ayah>, int) search(String q, {int limit = 150}) {
    final n = normalizeArabic(q);
    if (!ready || _norm == null || n.length < 2) return (const [], 0);
    final out = <Ayah>[];
    var total = 0;
    for (var i = 0; i < _norm!.length; i++) {
      if (_norm![i].contains(n)) {
        total++;
        if (out.length < limit) out.add(ayat![i]);
      }
    }
    return (out, total);
  }

  // ── التفاسير ──
  bool tafsirLoaded(String id) => _tafsir.containsKey(id);

  Future<bool> loadTafsirLocal(QEdition e) async {
    if (_tafsir.containsKey(e.id)) return true;
    final s = await readCached(e.cacheName);
    if (s == null) return false;
    try {
      final list = await compute(_parsePlain, s);
      if (list.isEmpty) return false;
      _tafsir[e.id] = {for (final a in list) a.surah * 1000 + a.ayah: a.text};
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> downloadTafsir(QEdition e, {void Function(double?)? onProgress}) async {
    try {
      await downloadText(e.url, e.cacheName, onProgress: onProgress);
    } catch (err) {
      // الترجمة الإنجليزية: إن تغيّر اسم الإصدار نبحث عنه في قائمة الإصدارات
      if (e.rtl) rethrow;
      final alt = await _findEnglishSaheeh();
      if (alt == null) rethrow;
      await downloadText('$quranApiBase/editions/$alt.min.json', e.cacheName, onProgress: onProgress);
    }
    _tafsir.remove(e.id);
    return loadTafsirLocal(e);
  }

  Future<String?> _findEnglishSaheeh() async {
    try {
      final r = await http.get(Uri.parse('$quranApiBase/editions.json')).timeout(const Duration(seconds: 20));
      final j = jsonDecode(r.body) as Map;
      for (final v in j.values) {
        if (v is! Map || '${v['language']}' != 'English') continue;
        final a = '${v['author']}'.toLowerCase();
        if (a.contains('umm muhammad') || a.contains('sahih') || a.contains('saheeh')) return '${v['name']}';
      }
    } catch (_) {}
    return null;
  }

  String? tafsirOf(String id, int s, int a) => _tafsir[id]?[s * 1000 + a];

  Future<void> deleteTafsir(QEdition e) async {
    await deleteCached(e.cacheName);
    _tafsir.remove(e.id);
  }
}
