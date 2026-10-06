import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/i18n.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'text_decor.dart';

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
  List<LocaleName> _sttLocales = const [];
  String _partial = '';
  String _prefix = '';
  bool _decor = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      final tts = FlutterTts();
      tts.setStartHandler(() => mounted ? setState(() => _speaking = true) : null);
      tts.setCompletionHandler(() => mounted ? setState(() => _speaking = false) : null);
      tts.setCancelHandler(() => mounted ? setState(() => _speaking = false) : null);
      tts.setErrorHandler((_) => mounted ? setState(() => _speaking = false) : null);
      _tts = tts;
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
    if (old.isEmpty) return toast(t('أكتب نص أول', 'اكتب نصاً أولاً', 'Enter some text first'));
    final n = f(old);
    if (n == old) return toast(t('ما في حاجة اتغيّرت', 'لم يتغيّر شيء', 'Nothing changed'));
    _undo.add(old);
    if (_undo.length > 30) _undo.removeAt(0);
    setState(() => _c.text = n);
    toast(msg);
  }

  Future<void> _speak() async {
    final tts = _tts;
    if (tts == null) return toast(t('القراءة الصوتية ما متاحة في الجهاز ده', 'القراءة الصوتية غير متاحة في هذا الجهاز', 'Text-to-speech is not available on this device'));
    if (_speaking) {
      await tts.stop();
      setState(() => _speaking = false);
      return;
    }
    if (_c.text.trim().isEmpty) return toast(t('أكتب نص عشان نقراهو', 'اكتب نصاً لنقرأه', 'Enter some text to read aloud'));
    try {
      // بالإنجليزي: صوت إنجليزي إلا لو النص أغلبه عربي. بالعربي: صوت عربي لو في أي حرف عربي.
      final arN = _arLetter.allMatches(_c.text).length, laN = _latin.allMatches(_c.text).length;
      final useAr = isEn ? arN > laN : arN > 0;
      if (useAr) {
        var ok = await tts.isLanguageAvailable('ar-SA');
        await tts.setLanguage(ok == true ? 'ar-SA' : 'ar');
      } else {
        await tts.setLanguage('en-US');
      }
      await tts.setSpeechRate(_rate);
      setState(() => _speaking = true);
      await tts.speak(_c.text);
    } catch (_) {
      setState(() => _speaking = false);
      toast(t('ما قدرنا نشغّل القراءة. يمكن محتاج تنزّل حزمة الصوت من إعدادات الجهاز.', 'تعذّر تشغيل القراءة. ربما تحتاج إلى تنزيل حزمة الصوت من إعدادات الجهاز.',
          "Couldn't start speech. You may need to download the voice pack in your device settings."));
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
            if (e.permanent) toast('${t('الإملاء وقف', 'توقف الإملاء', 'Dictation stopped')}: ${e.errorMsg}');
          },
        );
        if (!_sttReady) {
          return toast(t('الإملاء الصوتي ما متاح — اسمح بالمايكروفون أو نزّل خدمة التعرف على الكلام', 'الإملاء الصوتي غير متاح — اسمح بالميكروفون أو نزّل خدمة التعرّف على الكلام',
              'Dictation unavailable — allow the microphone or install a speech recognition service'));
        }
        _sttLocales = await _stt.locales();
      }
      // لغة الإملاء تتبع لغة التطبيق: إنجليزي (en-US) أو عربي
      final locs = _sttLocales;
      String? pick(String id) => locs.where((l) => l.localeId.replaceAll('-', '_').toLowerCase() == id).map((l) => l.localeId).firstOrNull;
      String? starts(String p) => locs.where((l) => l.localeId.toLowerCase().startsWith(p)).map((l) => l.localeId).firstOrNull;
      final sttLocale = isEn
          ? (pick('en_us') ?? starts('en') ?? 'en_US')
          : (pick('ar_sd') ?? pick('ar_sa') ?? starts('ar') ?? 'ar_SA');
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
        listenOptions: SpeechListenOptions(localeId: sttLocale, partialResults: true, cancelOnError: true, listenFor: const Duration(minutes: 1), pauseFor: const Duration(seconds: 5)),
      );
      setState(() => _listening = true);
    } catch (_) {
      setState(() => _listening = false);
      toast(t('ما قدرنا نشغّل الإملاء في الجهاز ده', 'تعذّر تشغيل الإملاء في هذا الجهاز', "Couldn't start dictation on this device"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final txt = _c.text;
    final words = RegExp(r'[^\s]+').allMatches(txt).map((m) => m[0]!).toList();
    final chars = txt.characters.length;
    final noSpace = txt.replaceAll(RegExp(r'\s'), '').characters.length;
    final lines = txt.isEmpty ? 0 : txt.split('\n').length;
    final sentences = txt.split(RegExp(r'[.!?؟…\n]+')).where((s) => s.trim().isNotEmpty).length;
    final paragraphs = txt.split(RegExp(r'\n\s*\n')).where((s) => s.trim().isNotEmpty).length;
    final ar = _arLetter.allMatches(txt).length;
    final la = _latin.allMatches(txt).length;
    final digits = RegExp(r'[0-9٠-٩]').allMatches(txt).length;
    final tash = _tashkeel.allMatches(txt).length;
    final punct = RegExp(r'[.,;:!?؟،؛«»"()\-]').allMatches(txt).length;
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
    String dur(Duration d) => d.inSeconds < 60
        ? '${d.inSeconds} ${tr('ثانية', 'sec')}'
        : '${d.inMinutes} ${tr('د', 'min')} ${d.inSeconds % 60} ${tr('ث', 's')}';
    final dir = ar >= la ? tr('عربي', 'Arabic') : (la > 0 ? tr('لاتيني', 'Latin') : '—');

    return ToolList(children: [
      SegmentedButton<bool>(
        segments: [
          ButtonSegment(value: false, icon: const Icon(Icons.handyman_rounded), label: FittedBox(fit: BoxFit.scaleDown, child: Text(tr('أدوات', 'Tools')))),
          ButtonSegment(value: true, icon: const Icon(Icons.auto_awesome_rounded), label: FittedBox(fit: BoxFit.scaleDown, child: Text(tr('زخرفة', 'Decorate')))),
        ],
        selected: {_decor},
        onSelectionChanged: (v) => setState(() => _decor = v.first),
      ),
      const SizedBox(height: 12),
      SCard(
        title: _decor ? t('أكتب النص اللي داير تزخرفو', 'اكتب النص المراد زخرفته', 'Text to decorate') : tr('النص', 'Text'),
        icon: Icons.edit_note_rounded,
        color: SD.green,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            tooltip: tr('تراجع', 'Undo'),
            onPressed: _undo.isEmpty ? null : () => setState(() => _c.text = _undo.removeLast()),
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: tr('امسح', 'Clear'),
            onPressed: txt.isEmpty
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
            minLines: _decor ? 2 : 6,
            maxLines: _decor ? 5 : 14,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: t('أكتب هنا أو الصق النص…', 'اكتب هنا أو الصق النص…', 'Type or paste text here…'), alignLabelWithHint: true),
          ),
          if (!_decor) ...[
            const SizedBox(height: 10),
            Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _speak,
                icon: Icon(_speaking ? Icons.stop_rounded : Icons.volume_up_rounded),
                label: Text(_speaking ? t('وقّف', 'إيقاف', 'Stop') : t('اقرا لي', 'اقرأ لي', 'Read aloud')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _listening ? SD.red : SD.henna),
                onPressed: _dictate,
                icon: Icon(_listening ? Icons.mic_off_rounded : Icons.mic_rounded),
                label: Text(_listening ? t('وقّف الإملاء', 'أوقف الإملاء', 'Stop dictation') : t('أملي بصوتك', 'أملِ بصوتك', 'Dictate')),
              ),
            ),
          ]),
          Row(children: [
            const Icon(Icons.speed_rounded, size: 18),
            const SizedBox(width: 6),
            Text(tr('سرعة القراءة', 'Speech rate')),
            Expanded(child: Slider(value: _rate, min: .2, max: 1, divisions: 8, label: _rate.toStringAsFixed(1), onChanged: (v) => setState(() => _rate = v))),
          ]),
          if (_listening)
            NoteBox(
                t('بنسمع ليك… اتكلم بوضوح، وبعد 5 ثواني سكات بنوقف براهو 🎙️', 'نستمع إليك… تحدّث بوضوح، وبعد 5 ثوانٍ من الصمت نتوقف تلقائياً 🎙️',
                    'Listening… speak clearly. Stops automatically after 5 seconds of silence 🎙️'),
                kind: NoteKind.info),
          ],
        ]),
      ),
      if (_decor) TextDecorPanel(text: txt),
      if (!_decor && txt.isNotEmpty) ...[
        StatGrid([
          StatChip('${words.length}', tr('كلمة', 'Words'), color: SD.green, icon: Icons.short_text_rounded),
          StatChip('$chars', tr('حرف بالمسافات', 'Chars (with spaces)'), color: SD.nile, icon: Icons.text_fields_rounded),
          StatChip('$noSpace', tr('حرف بدون مسافات', 'Chars (no spaces)'), color: SD.indigo, icon: Icons.abc_rounded),
          StatChip('$sentences', tr('جملة', 'Sentences'), color: SD.henna, icon: Icons.format_quote_rounded),
          StatChip('$lines', tr('سطر', 'Lines'), color: SD.gold, icon: Icons.format_list_numbered_rounded),
          StatChip('$paragraphs', tr('فقرة', 'Paragraphs'), color: SD.coffee, icon: Icons.notes_rounded),
        ]),
        const SizedBox(height: 14),
        SCard(
          title: t('تفاصيل أكتر', 'تفاصيل أكثر', 'More details'),
          icon: Icons.analytics_rounded,
          color: SD.nile,
          child: Column(children: [
            InfoRow(tr('حروف عربية', 'Arabic letters'), '$ar', icon: Icons.translate_rounded),
            InfoRow(tr('حروف لاتينية', 'Latin letters'), '$la', icon: Icons.abc_rounded),
            InfoRow(tr('أرقام', 'Digits'), '$digits', icon: Icons.pin_rounded),
            InfoRow(tr('علامات التشكيل', 'Diacritics'), '$tash', icon: Icons.format_color_text_rounded),
            InfoRow(tr('علامات الترقيم', 'Punctuation'), '$punct', icon: Icons.more_horiz_rounded),
            InfoRow(tr('اللغة الغالبة', 'Main script'), dir, icon: Icons.language_rounded),
            InfoRow(tr('كلمات مختلفة', 'Unique words'), '$unique', icon: Icons.fingerprint_rounded, hint: words.isEmpty ? null : '${tr('التنوّع', 'Variety')}: ${(unique / clean.length.clamp(1, 1 << 30) * 100).toStringAsFixed(0)}%'),
            InfoRow(tr('متوسط طول الكلمة', 'Avg word length'), '${avgLen.toStringAsFixed(1)} ${tr('حرف', 'chars')}', icon: Icons.straighten_rounded),
            InfoRow(tr('أطول كلمة', 'Longest word'), longest, icon: Icons.expand_rounded),
            InfoRow(tr('زمن القراءة الصامتة', 'Silent reading time'), dur(readT),
                icon: Icons.menu_book_rounded, hint: t('حوالي $readWpm كلمة في الدقيقة', 'نحو $readWpm كلمة في الدقيقة', '~$readWpm words per minute')),
            InfoRow(tr('زمن القراءة بصوت (خطبة/كلمة)', 'Speaking time (speech/talk)'), dur(speakT),
                icon: Icons.record_voice_over_rounded, hint: t('حوالي 130 كلمة في الدقيقة', 'نحو 130 كلمة في الدقيقة', '~130 words per minute')),
            InfoRow(tr('رسائل SMS تقريباً', 'SMS messages (approx.)'), '${(chars / (ar > 0 ? 70 : 160)).ceil()}',
                icon: Icons.sms_rounded,
                hint: ar > 0 ? tr('الرسالة العربية 70 حرف', 'Arabic SMS = 70 chars') : tr('الرسالة اللاتينية 160 حرف', 'Latin SMS = 160 chars')),
            InfoRow(tr('الحجم', 'Size'), fmtBytes(_utf8Len(txt)), icon: Icons.sd_storage_rounded),
          ]),
        ),
        if (top.isNotEmpty)
          SCard(
            title: t('أكتر الكلمات تكراراً', 'أكثر الكلمات تكراراً', 'Most frequent words'),
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
      if (!_decor) ...[
      SCard(
        title: tr('حوّل النص', 'Transform text'),
        icon: Icons.auto_fix_high_rounded,
        color: SD.gold,
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          _btn(t('شيل التشكيل', 'أزل التشكيل', 'Remove diacritics'), Icons.format_clear_rounded,
              () => _apply((s) => s.replaceAll(_tashkeel, ''), t('التشكيل اتشال ✓', 'أُزيل التشكيل ✓', 'Diacritics removed ✓'))),
          _btn(tr('وحّد الحروف (أ إ آ ← ا، ى ← ي، ة ← ه)', 'Normalize Arabic (أ إ آ → ا، ى → ي، ة → ه)'), Icons.spellcheck_rounded,
              () => _apply(_normalize, t('اتوحّدت ✓', 'تم التوحيد ✓', 'Normalized ✓'))),
          _btn(tr('أرقام عربية ← 123', '١٢٣ → 123'), Icons.looks_one_rounded, () => _apply((s) => s.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${'٠١٢٣٤٥٦٧٨٩'.indexOf(m[0]!)}'), _done)),
          _btn(tr('123 ← ١٢٣', '123 → ١٢٣'), Icons.looks_two_rounded, () => _apply(toArabicDigits, _done)),
          _btn(t('نضّف المسافات', 'نظّف المسافات', 'Clean up spaces'), Icons.space_bar_rounded,
              () => _apply(_cleanSpaces, t('المسافات اتنضّفت ✓', 'نُظّفت المسافات ✓', 'Spaces cleaned ✓'))),
          _btn(t('شيل الأسطر المكررة', 'احذف الأسطر المكررة', 'Remove duplicate lines'), Icons.filter_list_off_rounded,
              () => _apply((s) => s.split('\n').toSet().join('\n'), _done)),
          _btn(tr('رتّب الأسطر', 'Sort lines'), Icons.sort_by_alpha_rounded,
              () => _apply((s) => (s.split('\n')..sort()).join('\n'), t('اترتّبت ✓', 'رُتّبت ✓', 'Sorted ✓'))),
          _btn(tr('ABC كبيرة', 'UPPERCASE'), Icons.text_increase_rounded, () => _apply((s) => s.toUpperCase(), _done)),
          _btn(tr('abc صغيرة', 'lowercase'), Icons.text_decrease_rounded, () => _apply((s) => s.toLowerCase(), _done)),
          _btn(tr('اعكس النص', 'Reverse text'), Icons.swap_horiz_rounded,
              () => _apply((s) => s.characters.toList().reversed.join(), t('اتعكس ✓', 'عُكس النص ✓', 'Reversed ✓'))),
        ]),
      ),
      if (txt.isNotEmpty) ShareBar(() => _c.text),
      const SizedBox(height: 10),
      NoteBox(
          t('القراءة الصوتية والإملاء بيعتمدوا على خدمات الجهاز (Google/Apple). لو ما اشتغلوا، نزّل حزمة اللغة من إعدادات الجهاز. الإملاء ممكن يحتاج نت.',
              'تعتمد القراءة الصوتية والإملاء على خدمات الجهاز (Google/Apple). إن لم تعمل، نزّل حزمة اللغة من إعدادات الجهاز. قد يحتاج الإملاء إلى إنترنت.',
              'Speech and dictation rely on device services (Google/Apple). If they fail, download the language pack in device settings. Dictation may need internet.'),
          kind: NoteKind.info),
      if (kIsWeb)
        NoteBox(t('في نسخة الويب بعض المتصفحات ما بتدعم الإملاء الصوتي.', 'في نسخة الويب، بعض المتصفحات لا تدعم الإملاء الصوتي.', "On the web, some browsers don't support dictation."),
            kind: NoteKind.warn),
      ],
    ]);
  }

  static String get _done => t('تمام ✓', 'تم ✓', 'Done ✓');

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
