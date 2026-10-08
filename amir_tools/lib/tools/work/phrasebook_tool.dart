import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart' show EmptyHint, PickChip;
import 'phrasebook_data.dart';

/// عبارات المغترب: سوداني ⇄ فصحى ⇄ إنجليزي — بدون نت
class PhrasebookTool extends StatefulWidget {
  const PhrasebookTool({super.key});
  @override
  State<PhrasebookTool> createState() => _PhrasebookToolState();
}

class _PhrasebookToolState extends State<PhrasebookTool> {
  String _cat = 'travel';
  String _q = '';
  final _search = TextEditingController();
  FlutterTts? _tts;
  String? _speakingId;

  @override
  void dispose() {
    try {
      _tts?.stop();
    } catch (_) {}
    _search.dispose();
    super.dispose();
  }

  List<String> _favs(AppState s) => List<String>.from(s.getData<List>('phrasebook_favs') ?? const []);

  void _toggleFav(AppState s, Phrase p) {
    final f = _favs(s);
    if (f.contains(p.id)) {
      f.remove(p.id);
    } else {
      f.add(p.id);
      s.awardDaily('phrasebook_fav', 2, tr('حفظ عبارة', 'Saved a phrase'));
    }
    s.setData('phrasebook_favs', f);
  }

  Future<void> _speak(String text, String lang, String id) async {
    try {
      if (_speakingId == id) {
        await _tts?.stop();
        if (mounted) setState(() => _speakingId = null);
        return;
      }
      final tts = _tts ??= FlutterTts();
      tts.setCompletionHandler(() => mounted ? setState(() => _speakingId = null) : null);
      tts.setCancelHandler(() => mounted ? setState(() => _speakingId = null) : null);
      tts.setErrorHandler((_) => mounted ? setState(() => _speakingId = null) : null);
      await tts.stop();
      await tts.setLanguage(lang);
      await tts.setSpeechRate(.45);
      setState(() => _speakingId = id);
      await tts.speak(text.replaceAll('…', ''));
      if (mounted) context.read<AppState>().awardDaily('phrasebook_tts', 2, tr('نطق عبارة', 'Listened to a phrase'));
    } catch (_) {
      if (mounted) setState(() => _speakingId = null);
      toast(t('القراءة الصوتية ما متاحة في الجهاز دا', 'القراءة الصوتية غير متاحة في هذا الجهاز', 'Text-to-speech is not available on this device'));
    }
  }

  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'[ً-ْ]'), '');

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final favs = _favs(s);
    final q = _norm(_q.trim());
    final List<Phrase> list;
    if (q.isNotEmpty) {
      list = phrases.where((p) => _norm('${p.sd} ${p.ar} ${p.en} ${p.pron}').contains(q)).toList();
    } else if (_cat == 'fav') {
      list = phrases.where((p) => favs.contains(p.id)).toList();
    } else {
      list = phrases.where((p) => p.cat == _cat).toList();
    }

    return ToolList(children: [
      TextField(
        controller: _search,
        onChanged: (v) => setState(() => _q = v),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: t('فتّش بالعربي أو الإنجليزي', 'ابحث بالعربية أو الإنجليزية', 'Search in Arabic or English'),
          suffixIcon: _q.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() {
                        _q = '';
                        _search.clear();
                      })),
        ),
      ),
      const SizedBox(height: 10),
      if (q.isEmpty)
        Wrap(spacing: 6, runSpacing: 6, children: [
          PickChip('⭐ ${t('المحفوظة', 'المفضلة', 'Favorites')} (${favs.length})', _cat == 'fav', () => setState(() => _cat = 'fav'), color: SD.gold),
          for (final c in phraseCats) PickChip('${c.emoji} ${c.name}', _cat == c.key, () => setState(() => _cat = c.key), color: c.color),
        ]),
      const SizedBox(height: 12),
      if (list.isEmpty)
        EmptyHint(
          _cat == 'fav' && q.isEmpty ? Icons.star_border_rounded : Icons.search_off_rounded,
          _cat == 'fav' && q.isEmpty
              ? t('دوس النجمة جنب أي عبارة عشان تحفظها هنا', 'اضغط النجمة بجانب أي عبارة لحفظها هنا', 'Tap the star on any phrase to keep it here')
              : t('ما لقينا حاجة', 'لا توجد نتائج', 'No results'),
        ),
      for (final p in list) _card(context, s, p, favs.contains(p.id)),
      NoteBox(
          t('النطق الصوتي بيعتمد على محرك الجهاز — لو ما اشتغل نزّل حزمة اللغة من إعدادات الجوال.',
              'يعتمد النطق على محرّك الجهاز — إن لم يعمل فثبّت حزمة اللغة من إعدادات الهاتف.',
              'Speech uses your device\'s engine — if it doesn\'t work, install the language pack in your phone settings.'),
          kind: NoteKind.tip),
      NoteBox(
          t('سطر 🗣️ «انطقها» هو الجملة الإنجليزية مكتوبة بحروف عربية عشان تقدر تقولها — النطق تقريبي، واسمع الصوت 🔊 للدقة.',
              'سطر 🗣️ «النطق» هو الجملة الإنجليزية مكتوبة بحروف عربية لتستطيع قولها — النطق تقريبي، واستمع للصوت 🔊 للدقة.',
              'The 🗣️ "Say it" line spells the English sentence in Arabic letters — it\'s approximate; tap 🔊 to hear it.'),
          kind: NoteKind.info),
    ]);
  }

  Widget _card(BuildContext context, AppState s, Phrase p, bool fav) {
    final cat = phraseCats.firstWhere((c) => c.key == p.cat);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .65);
    Widget line(String text, String tag, String lang, TextDirection dir, {bool big = false}) {
      final id = '${p.id}_$tag';
      final on = _speakingId == id;
      return Row(children: [
        Container(
          width: 30,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(color: cat.color.withValues(alpha: .15), borderRadius: BorderRadius.circular(8)),
          child: FittedBox(fit: BoxFit.scaleDown, child: Text(tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: readable(context, cat.color)))),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              textDirection: dir,
              textAlign: dir == TextDirection.ltr ? TextAlign.left : TextAlign.right,
              style: TextStyle(fontSize: big ? 16.5 : 14.5, fontWeight: big ? FontWeight.w800 : FontWeight.w600, color: big ? null : muted)),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: tr('استمع', 'Listen'),
          onPressed: () => _speak(text, lang, id),
          icon: Icon(on ? Icons.stop_circle_rounded : Icons.volume_up_rounded, size: 20, color: readable(context, cat.color)),
        ),
      ]);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: cat.color.withValues(alpha: .4))),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 4, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          line(p.en, 'EN', 'en-US', TextDirection.ltr, big: true),
          line(p.sd, tr('سو', 'SD'), 'ar', TextDirection.rtl),
          if (p.ar != p.sd) line(p.ar, tr('فص', 'MSA'), 'ar', TextDirection.rtl),
          if (p.pron.isNotEmpty) _pron(context, p, cat.color),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: tr('نسخ', 'Copy'),
              onPressed: () => copyText('${p.en}\n${p.sd}${p.ar != p.sd ? '\n${p.ar}' : ''}${p.pron.isNotEmpty ? '\n🗣️ ${p.pron}' : ''}'),
              icon: const Icon(Icons.copy_rounded, size: 19),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: tr('المفضلة', 'Favorite'),
              onPressed: () => _toggleFav(s, p),
              icon: Icon(fav ? Icons.star_rounded : Icons.star_border_rounded, color: fav ? SD.gold : null),
            ),
          ]),
        ]),
      ),
    );
  }

  /// سطر النطق: الجملة الإنجليزية مكتوبة بحروف عربية
  Widget _pron(BuildContext context, Phrase p, Color c) => Padding(
        padding: const EdgeInsetsDirectional.only(top: 2, bottom: 2, end: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 30,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(color: SD.gold.withValues(alpha: .18), borderRadius: BorderRadius.circular(8)),
            child: const Text('🗣️', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: '${t('انطقها', 'النطق', 'Say it')}: ',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: readable(context, c))),
                TextSpan(text: p.pron, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              ]),
              textDirection: TextDirection.rtl,
            ),
          ),
        ]),
      );
}
