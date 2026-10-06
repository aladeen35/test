import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

final _tashkeel = RegExp('[ً-ْٰـ]');
final _arLetter = RegExp('[ء-يٱ-ۓ]');
final _latin = RegExp('[A-Za-z]');

String _normalize(String s) => s
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي');

class TextTool extends StatefulWidget {
  const TextTool({super.key});
  @override
  State<TextTool> createState() => _TextToolState();
}

class _TextToolState extends State<TextTool> {
  final _c = TextEditingController();
  final _undo = <String>[];
  FlutterTts? _tts;
  bool _speaking = false;
  double _rate = .5;
  final _stt = SpeechToText();
  bool _sttReady = false, _listening = false;
  String _sttLocale = '';
  String _partial = '';
  String _prefix = '';

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      final t = FlutterTts();
      t.setStartHandler(() => mounted ? setState(() => _speaking = true) : null);
      t.setCompletionHandler(() => mounted ? setState(() => _speaking = false) : null);
      t.setCancelHandler(() => mounted ? setState(() => _speaking = false) : null);
      t.setErrorHandler((_) => mounted ? setState(() => _speaking = false) : null);
      _tts = t;
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      _tts?.stop();
    } catch (_) {}
    try {
      _stt.cancel();
    } catch (_) {}
    _c.dispose();
    super.dispose();
  }

  void _apply(String Function(String) f, String msg) {
    final old = _c.text;
    if (old.isEmpty) return toast('أكتب نص أول');
    final n = f(old);
    if (n == old) return toast('ما في حاجة اتغيّرت');
    _undo.add(old);
    if (_undo.length > 30) _undo.removeAt(0);
    setState(() => _c.text = n);
    toast(msg);
  }

  Future<void> _speak() async {
    final t = _tts;
    if (t == null) return toast('القراءة الصوتية ما متاحة في الجهاز ده');
    if (_speaking) {
      await t.stop();
      setState(() => _speaking = false);
      return;
    }
    if (_c.text.trim().isEmpty) return toast('أكتب نص عشان نقراهو');
    try {
      final hasAr = _arLetter.hasMatch(_c.text);
      if (hasAr) {
        var ok = await t.isLanguageAvailable('ar-SA');
        await t.setLanguage(ok == true ? 'ar-SA' : 'ar');
      } else {
        await t.setLanguage('en-US');
      }
      await t.setSpeechRate(_rate);
      setState(() => _speaking = true);
      await t.speak(_c.text);
    } catch (_) {
      setState(() => _speaking = false);
      toast('ما قدرنا نشغّل القراءة. يمكن محتاج تنزّل الصوت العربي من إعدادات الجهاز.');
    }
  }

  Future<void> _dictate() async {
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }
    try {
      if (!_sttReady) {
        _sttReady = await _stt.initialize(
          onStatus: (s) {
            if ((s == 'done' || s == 'notListening') && mounted) setState(() => _listening = false);
          },
          onError: (e) {
            if (mounted) setState(() => _listening = false);
            if (e.permanent) toast('الإملاء وقف: ${e.errorMsg}');
          },
        );
        if (!_sttReady) return toast('الإملاء الصوتي ما متاح — اسمح بالمايكروفون أو نزّل خدمة التعرف على الكلام');
        final locs = await _stt.locales();
        String? pick(String id) => locs.where((l) => l.localeId.replaceAll('-', '_').toLowerCase() == id).map((l) => l.localeId).firstOrNull;
        _sttLocale = pick('ar_sd') ?? pick('ar_sa') ?? locs.where((l) => l.localeId.toLowerCase().startsWith('ar')).map((l) => l.localeId).firstOrNull ?? 'ar_SA';
      }
      _prefix = _c.text.isEmpty || _c.text.endsWith(' ') || _c.text.endsWith('\n') ? _c.text : '${_c.text} ';
      _partial = '';
      await _stt.listen(
        onResult: (r) {
          if (!mounted) return;
          setState(() {
            _partial = r.recognizedWords;
            _c.text = _prefix + _partial;
            if (r.finalResult) {
              _prefix = '${_c.text} ';
              _partial = '';
            }
          });
        },
        listenOptions: SpeechListenOptions(localeId: _sttLocale, partialResults: true, cancelOnError: true, listenFor: const Duration(minutes: 1), pauseFor: const Duration(seconds: 5)),
      );
      setState(() => _listening = true);
    } catch (_) {
      setState(() => _listening = false);
      toast('ما قدرنا نشغّل الإملاء في الجهاز ده');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _c.text;
    final words = RegExp(r'[^\s]+').allMatches(t).map((m) => m[0]!).toList();
    final chars = t.characters.length;
    final noSpace = t.replaceAll(RegExp(r'\s'), '').characters.length;
    final lines = t.isEmpty ? 0 : t.split('\n').length;
    final sentences = t.split(RegExp(r'[.!?؟…\n]+')).where((s) => s.trim().isNotEmpty).length;
    final paragraphs = t.split(RegExp(r'\n\s*\n')).where((s) => s.trim().isNotEmpty).length;
    final ar = _arLetter.allMatches(t).length;
    final la = _latin.allMatches(t).length;
    final digits = RegExp(r'[0-9٠-٩]').allMatches(t).length;
    final tash = _tashkeel.allMatches(t).length;
    final punct = RegExp(r'[.,;:!?؟،؛«»"()\-]').allMatches(t).length;
    final clean = words.map((w) => _normalize(w.replaceAll(_tashkeel, '').replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '')).toLowerCase()).where((w) => w.length > 1).toList();
    final freq = <String, int>{};
    for (final w in clean) {
      freq[w] = (freq[w] ?? 0) + 1;
    }
    final top = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final unique = freq.length;
    final longest = words.isEmpty ? '' : words.reduce((a, b) => a.characters.length >= b.characters.length ? a : b);
    final avgLen = words.isEmpty ? 0.0 : words.fold<int>(0, (s, w) => s + w.characters.length) / words.length;
    // سرعة القراءة الصامتة تقريباً 180 كلمة/د للعربي و 230 للإنجليزي، والكلام حوالي 130 كلمة/د
    final readWpm = ar >= la ? 180 : 230;
    Duration mins(double m) => Duration(seconds: (m * 60).round());
    final readT = mins(words.length / readWpm), speakT = mins(words.length / 130);
    String dur(Duration d) => d.inSeconds < 60 ? '${d.inSeconds} ثانية' : '${d.inMinutes} د ${d.inSeconds % 60} ث';
    final dir = ar >= la ? 'عربي' : (la > 0 ? 'لاتيني' : '—');

    return ToolList(children: [
      SCard(
        title: 'النص',
        icon: Icons.edit_note_rounded,
        color: SD.green,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            tooltip: 'تراجع',
            onPressed: _undo.isEmpty ? null : () => setState(() => _c.text = _undo.removeLast()),
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'امسح',
            onPressed: t.isEmpty
                ? null
                : () => setState(() {
                      _undo.add(_c.text);
                      _c.clear();
                    }),
            icon: const Icon(Icons.clear_all_rounded),
          ),
        ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _c,
            minLines: 6,
            maxLines: 14,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'أكتب هنا أو الصق النص…', alignLabelWithHint: true),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _speak,
                icon: Icon(_speaking ? Icons.stop_rounded : Icons.volume_up_rounded),
                label: Text(_speaking ? 'وقّف' : 'اقرا لي'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _listening ? SD.red : SD.henna),
                onPressed: _dictate,
                icon: Icon(_listening ? Icons.mic_off_rounded : Icons.mic_rounded),
                label: Text(_listening ? 'وقّف الإملاء' : 'أملي بصوتك'),
              ),
            ),
          ]),
          Row(children: [
            const Icon(Icons.speed_rounded, size: 18),
            const SizedBox(width: 6),
            const Text('سرعة القراءة'),
            Expanded(child: Slider(value: _rate, min: .2, max: 1, divisions: 8, label: _rate.toStringAsFixed(1), onChanged: (v) => setState(() => _rate = v))),
          ]),
          if (_listening) const NoteBox('بنسمع ليك… اتكلم بوضوح، وبعد 5 ثواني سكات بنوقف براهو 🎙️', kind: NoteKind.info),
        ]),
      ),
      if (t.isNotEmpty) ...[
        StatGrid([
          StatChip('${words.length}', 'كلمة', color: SD.green, icon: Icons.short_text_rounded),
          StatChip('$chars', 'حرف بالمسافات', color: SD.nile, icon: Icons.text_fields_rounded),
          StatChip('$noSpace', 'حرف بدون مسافات', color: SD.indigo, icon: Icons.abc_rounded),
          StatChip('$sentences', 'جملة', color: SD.henna, icon: Icons.format_quote_rounded),
          StatChip('$lines', 'سطر', color: SD.gold, icon: Icons.format_list_numbered_rtl_rounded),
          StatChip('$paragraphs', 'فقرة', color: SD.coffee, icon: Icons.notes_rounded),
        ]),
        const SizedBox(height: 14),
        SCard(
          title: 'تفاصيل أكتر',
          icon: Icons.analytics_rounded,
          color: SD.nile,
          child: Column(children: [
            InfoRow('حروف عربية', '$ar', icon: Icons.translate_rounded),
            InfoRow('حروف لاتينية', '$la', icon: Icons.abc_rounded),
            InfoRow('أرقام', '$digits', icon: Icons.pin_rounded),
            InfoRow('علامات التشكيل', '$tash', icon: Icons.format_color_text_rounded),
            InfoRow('علامات الترقيم', '$punct', icon: Icons.more_horiz_rounded),
            InfoRow('اللغة الغالبة', dir, icon: Icons.language_rounded),
            InfoRow('كلمات مختلفة', '$unique', icon: Icons.fingerprint_rounded, hint: words.isEmpty ? null : 'التنوّع: ${(unique / clean.length.clamp(1, 1 << 30) * 100).toStringAsFixed(0)}%'),
            InfoRow('متوسط طول الكلمة', '${avgLen.toStringAsFixed(1)} حرف', icon: Icons.straighten_rounded),
            InfoRow('أطول كلمة', longest, icon: Icons.expand_rounded),
            InfoRow('زمن القراءة الصامتة', dur(readT), icon: Icons.menu_book_rounded, hint: 'حوالي $readWpm كلمة في الدقيقة'),
            InfoRow('زمن القراءة بصوت (خطبة/كلمة)', dur(speakT), icon: Icons.record_voice_over_rounded, hint: 'حوالي 130 كلمة في الدقيقة'),
            InfoRow('رسائل SMS تقريباً', '${(chars / (ar > 0 ? 70 : 160)).ceil()}', icon: Icons.sms_rounded, hint: ar > 0 ? 'الرسالة العربية 70 حرف' : 'الرسالة اللاتينية 160 حرف'),
            InfoRow('الحجم', fmtBytes(_utf8Len(t)), icon: Icons.sd_storage_rounded),
          ]),
        ),
        if (top.isNotEmpty)
          SCard(
            title: 'أكتر الكلمات تكراراً',
            icon: Icons.leaderboard_rounded,
            color: SD.purple,
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in top.take(12))
                Chip(
                  avatar: CircleAvatar(backgroundColor: SD.gold, child: Text('${e.value}', style: const TextStyle(fontSize: 11, color: SD.black))),
                  label: Text(e.key),
                ),
            ]),
          ),
      ],
      SCard(
        title: 'حوّل النص',
        icon: Icons.auto_fix_high_rounded,
        color: SD.gold,
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          _btn('شيل التشكيل', Icons.format_clear_rounded, () => _apply((s) => s.replaceAll(_tashkeel, ''), 'التشكيل اتشال ✓')),
          _btn('وحّد الحروف (أ إ آ ← ا، ى ← ي، ة ← ه)', Icons.spellcheck_rounded, () => _apply(_normalize, 'اتوحّدت ✓')),
          _btn('أرقام عربية ← 123', Icons.looks_one_rounded, () => _apply((s) => s.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${'٠١٢٣٤٥٦٧٨٩'.indexOf(m[0]!)}'), 'تمام ✓')),
          _btn('123 ← ١٢٣', Icons.looks_two_rounded, () => _apply(toArabicDigits, 'تمام ✓')),
          _btn('نضّف المسافات', Icons.space_bar_rounded, () => _apply(_cleanSpaces, 'المسافات اتنضّفت ✓')),
          _btn('شيل الأسطر المكررة', Icons.filter_list_off_rounded, () => _apply((s) => s.split('\n').toSet().join('\n'), 'تمام ✓')),
          _btn('رتّب الأسطر', Icons.sort_by_alpha_rounded, () => _apply((s) => (s.split('\n')..sort()).join('\n'), 'اترتّبت ✓')),
          _btn('ABC كبيرة', Icons.text_increase_rounded, () => _apply((s) => s.toUpperCase(), 'تمام ✓')),
          _btn('abc صغيرة', Icons.text_decrease_rounded, () => _apply((s) => s.toLowerCase(), 'تمام ✓')),
          _btn('اعكس النص', Icons.swap_horiz_rounded, () => _apply((s) => s.characters.toList().reversed.join(), 'اتعكس ✓')),
        ]),
      ),
      if (t.isNotEmpty) ShareBar(() => _c.text),
      const SizedBox(height: 10),
      const NoteBox('القراءة الصوتية والإملاء بيعتمدوا على خدمات الجهاز (Google/Apple). لو ما اشتغلوا، نزّل حزمة اللغة العربية من إعدادات الجهاز. الإملاء ممكن يحتاج نت.', kind: NoteKind.info),
      if (kIsWeb) const NoteBox('في نسخة الويب بعض المتصفحات ما بتدعم الإملاء الصوتي.', kind: NoteKind.warn),
    ]);
  }

  static int _utf8Len(String s) {
    var n = 0;
    for (final r in s.runes) {
      n += r < 0x80 ? 1 : r < 0x800 ? 2 : r < 0x10000 ? 3 : 4;
    }
    return n;
  }

  static String _cleanSpaces(String s) => s
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r'[ \t ]+'), ' ').trim())
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceAll(RegExp(r' ([،,.؟?!:؛])'), r'$1')
      .trim();

  Widget _btn(String label, IconData icon, VoidCallback onTap) => ActionChip(avatar: Icon(icon, size: 18), label: Text(label), onPressed: onTap);
}
