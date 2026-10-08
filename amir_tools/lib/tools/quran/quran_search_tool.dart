import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'quran_common.dart';
import 'quran_store.dart';

const _quranStyle = TextStyle(fontSize: 21, height: 1.9, fontWeight: FontWeight.w500);

/// البحث في القرآن الكريم وتصفّح السور مع التفسير
class QuranSearchTool extends StatefulWidget {
  const QuranSearchTool({super.key});
  @override
  State<QuranSearchTool> createState() => _QuranSearchToolState();
}

class _QuranSearchToolState extends State<QuranSearchTool> {
  final _store = QuranStore.instance;
  final _q = TextEditingController();
  Timer? _debounce;
  bool _checking = true, _busy = false;
  double? _progress;
  String? _error;
  String _mode = 'search';
  int? _surah;
  List<Ayah> _results = const [];
  int _total = 0;
  final Map<String, int?> _sizes = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _store.loadLocal();
    if (mounted) setState(() => _checking = false);
    await _refreshSizes();
  }

  Future<void> _refreshSizes() async {
    for (final e in [quranTextEdition, ...tafsirEditions]) {
      _sizes[e.id] = await cachedSize(e.cacheName);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _error = null;
      _progress = 0;
    });
    try {
      final ok = await _store.download(onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      if (!ok) throw StateError('parse');
      if (mounted) context.read<AppState>().award(5, tr('تنزيل نص المصحف', "Downloaded the Qur'an text"));
    } catch (_) {
      _error = downloadErrorText;
    }
    await _refreshSizes();
    if (mounted) {
      setState(() {
        _busy = false;
        _progress = null;
      });
    }
  }

  void _onQuery(String v) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  void _runSearch() {
    if (!mounted) return;
    final (r, n) = _store.search(_q.text);
    setState(() {
      _results = r;
      _total = n;
    });
    if (n > 0) context.read<AppState>().awardDaily('quran_search', 3, tr('البحث في القرآن', "Searched the Qur'an"));
  }

  void _openAyah(Ayah a) {
    final s = context.read<AppState>();
    s.setData('quran_search_last', [a.surah, a.ayah]);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ChangeNotifierProvider.value(value: s, child: AyahSheet(ayah: a)),
    ).then((_) => _refreshSizes());
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) return const Center(child: CircularProgressIndicator());
    if (!_store.ready) return _downloadView();
    return ToolList(children: [
      SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 'search', icon: const Icon(Icons.search_rounded), label: _seg(tr('بحث', 'Search'))),
          ButtonSegment(value: 'browse', icon: const Icon(Icons.menu_book_rounded), label: _seg(tr('السور', 'Surahs'))),
          ButtonSegment(value: 'files', icon: const Icon(Icons.download_done_rounded), label: _seg(t('الملفات', 'الملفات', 'Files'))),
        ],
        selected: {_mode},
        onSelectionChanged: (v) => setState(() => _mode = v.first),
      ),
      const SizedBox(height: 14),
      ...switch (_mode) {
        'browse' => _browse(),
        'files' => _files(),
        _ => _searchView(),
      },
    ]);
  }

  Widget _seg(String s) => FittedBox(fit: BoxFit.scaleDown, child: Text(s, maxLines: 1));

  Widget _downloadView() => ToolList(children: [
        ResultHero(
          label: t('القرآن الكريم — بحث وتفسير', 'القرآن الكريم — بحث وتفسير', "The Holy Qur'an — search & tafsir"),
          value: '6236',
          sub: t('آية، بحث بدون تشكيل، تصفّح السور، وتفسير', 'آية، بحث دون تشكيل، تصفّح السور، وتفسير', 'ayat · search without diacritics · browse surahs · tafsir'),
        ),
        SCard(
          title: t('نزّل نص المصحف (مرة واحدة)', 'تنزيل نص المصحف (مرة واحدة)', "Download the Qur'an text (once)"),
          icon: Icons.cloud_download_rounded,
          color: SD.green,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              t('النص حوالي ${fmt(quranTextEdition.approxMb, 1)} ميقا، بيتنزّل مرة وحدة وبعدها الأداة بتشتغل بدون نت.',
                  'حجم النص نحو ${fmt(quranTextEdition.approxMb, 1)} ميغابايت، يُنزَّل مرة واحدة ثم تعمل الأداة دون إنترنت.',
                  'About ${fmt(quranTextEdition.approxMb, 1)} MB, downloaded once — then it works offline.'),
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 8),
            Text('${tr('المصدر', 'Source')}: ${quranTextEdition.source}', style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7))),
            const SizedBox(height: 12),
            if (_busy) DownloadProgress(t('بننزّل…', 'جارٍ التنزيل…', 'Downloading…'), _progress),
            if (_error != null) NoteBox(_error!, kind: NoteKind.warn),
            FilledButton.icon(
              onPressed: _busy ? null : _download,
              icon: Icon(_error != null ? Icons.refresh_rounded : Icons.download_rounded),
              label: FittedBox(fit: BoxFit.scaleDown, child: Text(_error != null ? t('جرّب تاني', 'أعد المحاولة', 'Retry') : t('نزّل هسي', 'نزّل الآن', 'Download now'))),
            ),
          ]),
        ),
        NoteBox(
            t('النص بالرسم الإملائي عشان البحث يكون أسهل؛ للتلاوة ارجع للمصحف بالرسم العثماني.',
                'النص بالرسم الإملائي لتسهيل البحث؛ وللتلاوة يُرجع إلى المصحف بالرسم العثماني.',
                'The text uses simple (imla\'i) script to make searching easy; for recitation use a mushaf in Uthmani script.'),
            kind: NoteKind.info),
      ]);

  // ───────── البحث ─────────
  List<Widget> _searchView() {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .65);
    final last = context.read<AppState>().getData<List>('quran_search_last');
    final q = _q.text.trim();
    return [
      TextField(
        controller: _q,
        onChanged: _onQuery,
        onSubmitted: (_) => _runSearch(),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: t('اكتب كلمة أو جزء من آية', 'اكتب كلمة أو جزءًا من آية', 'Type a word or part of an ayah (Arabic)'),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: q.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => setState(() {
                        _q.clear();
                        _results = const [];
                        _total = 0;
                      })),
        ),
      ),
      const SizedBox(height: 6),
      Text(t('البحث بيتجاهل التشكيل وأشكال الألف والتاء المربوطة والياء.', 'يتجاهل البحث التشكيل وصور الألف والتاء المربوطة والألف المقصورة.',
          'Search ignores diacritics and alef/taa-marbuta/yaa variants.'),
          style: TextStyle(fontSize: 12.5, color: muted)),
      const SizedBox(height: 12),
      if (q.length >= 2) ...[
        StatGrid([
          StatChip(fmt(_total, 0), tr('آية مطابقة', 'matching ayat'), color: SD.green, icon: Icons.format_list_numbered_rounded),
          StatChip(fmt(_results.map((e) => e.surah).toSet().length, 0), tr('سورة', 'surahs'), color: SD.nile, icon: Icons.menu_book_rounded),
          StatChip(fmt(_results.length, 0), tr('معروضة', 'shown'), color: SD.gold, icon: Icons.visibility_rounded),
        ]),
        const SizedBox(height: 12),
        if (_total == 0) NoteBox(t('ما لقينا آية فيها الكلمة دي.', 'لم نجد آية تحتوي هذه الكلمة.', 'No ayah contains this text.')),
        if (_total > _results.length)
          NoteBox(t('بنعرض أول ${_results.length} نتيجة — زِد كلمات عشان تضيّق البحث.', 'نعرض أول ${_results.length} نتيجة — أضف كلمات لتضييق البحث.',
              'Showing the first ${_results.length} results — add words to narrow down.')),
        for (final a in _results) _ayahTile(a, q),
      ] else ...[
        if (last != null && last.length == 2 && _store.ayah(last[0], last[1]) != null)
          SCard(
            title: t('آخر آية فتحتها', 'آخر آية فتحتها', 'Last opened ayah'),
            icon: Icons.bookmark_rounded,
            color: SD.gold,
            child: _ayahTile(_store.ayah(last[0], last[1])!, ''),
          ),
        NoteBox(t('مثال: اكتب «الصابرين» أو «رب اشرح لي صدري».', 'مثال: اكتب «الصابرين» أو «رب اشرح لي صدري».', 'Example: type «الصابرين» or «رب اشرح لي صدري».'),
            kind: NoteKind.tip),
      ],
    ];
  }

  Widget _ayahTile(Ayah a, String q) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openAyah(a),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(Icons.auto_stories_rounded, size: 18, color: readable(context, SD.gold)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('سورة ${surahName(a.surah)} • ${tr('آية', 'Ayah')} ${a.ayah}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, SD.goldDeep))),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: .5)),
            ]),
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.rtl,
              child: RichText(
                textAlign: TextAlign.start,
                text: highlightSpan(a.text, q, _quranStyle.copyWith(color: cs.onSurface, fontFamily: 'Tajawal', fontSize: 19), SD.gold),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ───────── تصفّح السور ─────────
  List<Widget> _browse() {
    if (_surah == null) {
      return [
        SectionTitle(tr('سور القرآن الكريم', "Surahs of the Qur'an"), icon: Icons.menu_book_rounded),
        for (var s = 1; s <= 114; s++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => setState(() => _surah = s),
              leading: CircleAvatar(
                backgroundColor: SD.gold.withValues(alpha: .2),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text('$s', style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, SD.goldDeep)))),
              ),
              title: Text('سورة ${surahName(s)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${_store.ayahCount(s)} ${tr('آية', 'ayat')}', maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
      ];
    }
    final s = _surah!;
    final cs = Theme.of(context).colorScheme;
    return [
      Row(children: [
        IconButton(onPressed: () => setState(() => _surah = null), icon: const Icon(Icons.arrow_back_rounded), tooltip: tr('رجوع', 'Back')),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('سورة ${surahName(s)}', style: TextStyle(fontFamily: 'Lalezar', fontSize: 26, color: readable(context, SD.goldDeep))),
          ),
        ),
        IconButton(onPressed: s > 1 ? () => setState(() => _surah = s - 1) : null, icon: const Icon(Icons.skip_previous_rounded), tooltip: tr('السابقة', 'Previous')),
        IconButton(onPressed: s < 114 ? () => setState(() => _surah = s + 1) : null, icon: const Icon(Icons.skip_next_rounded), tooltip: tr('التالية', 'Next')),
      ]),
      Text('${_store.ayahCount(s)} ${tr('آية', 'ayat')} — ${t('اضغط على أي آية للتفسير والمشاركة', 'اضغط على أي آية للتفسير والمشاركة', 'tap any ayah for tafsir & sharing')}',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: cs.onSurface.withValues(alpha: .7))),
      const SizedBox(height: 10),
      if (s != 1 && s != 9)
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(basmalaSimple, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: _quranStyle),
        ),
      for (final a in _store.surah(s))
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openAyah(a),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: a.text),
                  TextSpan(text: ' ﴿${toArabicDigits('${a.ayah}')}﴾', style: TextStyle(color: readable(context, SD.goldDeep), fontWeight: FontWeight.w800)),
                ]),
                style: _quranStyle.copyWith(color: cs.onSurface),
              ),
            ),
          ),
        ),
    ];
  }

  // ───────── إدارة الملفات ─────────
  List<Widget> _files() {
    final used = _sizes.values.whereType<int>().fold<int>(0, (a, b) => a + b);
    return [
      StatGrid([
        StatChip(fmtBytes(used), t('المساحة المستخدمة', 'المساحة المستخدمة', 'Storage used'), color: SD.nile, icon: Icons.sd_storage_rounded),
        StatChip('${_sizes.values.whereType<int>().length}/${tafsirEditions.length + 1}', t('ملفات منزّلة', 'ملفات منزّلة', 'Files downloaded'), color: SD.green,
            icon: Icons.download_done_rounded),
      ], columns: 2),
      const SizedBox(height: 12),
      for (final e in [quranTextEdition, ...tafsirEditions])
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(_sizes[e.id] != null ? Icons.check_circle_rounded : Icons.cloud_outlined, color: readable(context, _sizes[e.id] != null ? SD.green : SD.goldDeep)),
            title: Text(e.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(
                _sizes[e.id] != null
                    ? '${fmtBytes(_sizes[e.id]!)} • ${e.source}'
                    : '${t('ما منزّل', 'غير منزّل', 'Not downloaded')} (≈ ${fmt(e.approxMb, 1)} MB) • ${e.source}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
            trailing: _sizes[e.id] == null
                ? null
                : IconButton(
                    tooltip: tr('حذف', 'Delete'),
                    icon: Icon(Icons.delete_outline_rounded, color: readable(context, SD.red)),
                    onPressed: () => _delete(e),
                  ),
          ),
        ),
      NoteBox(
          t('التفاسير بتتنزّل لما تفتح آية وتختار التفسير. لو مسحت نص المصحف، بتحتاج تنزّله تاني عشان البحث.',
              'تُنزَّل التفاسير عند فتح آية واختيار التفسير. وإن حذفت نص المصحف فستحتاج إلى تنزيله مجددًا للبحث.',
              'Tafsir files download when you open an ayah and pick one. Deleting the Qur\'an text means re-downloading it to search.'),
          kind: NoteKind.info),
      const ReviewedLine('quran_search', 'download sources'),
    ];
  }

  Future<void> _delete(QEdition e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('حذف الملف؟', 'Delete file?')),
        content: Text(e.name),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('حذف', 'Delete'))),
        ],
      ),
    );
    if (ok != true) return;
    if (e.id == quranTextEdition.id) {
      await _store.deleteText();
    } else {
      await _store.deleteTafsir(e);
    }
    await _refreshSizes();
    if (mounted) setState(() {});
  }
}

/// ورقة الآية: النص الكامل + التفسير + النسخ والمشاركة
class AyahSheet extends StatefulWidget {
  final Ayah ayah;
  const AyahSheet({super.key, required this.ayah});
  @override
  State<AyahSheet> createState() => _AyahSheetState();
}

class _AyahSheetState extends State<AyahSheet> {
  final _store = QuranStore.instance;
  late String _ed;
  bool _loading = false, _busy = false;
  double? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ed = context.read<AppState>().getData<String>('quran_search_tafsir') ?? (isEn ? 'saheeh' : 'muyassar');
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _store.loadTafsirLocal(tafsirById(_ed));
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _error = null;
      _progress = 0;
    });
    try {
      final ok = await _store.downloadTafsir(tafsirById(_ed), onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      if (!ok) throw StateError('parse');
    } catch (_) {
      _error = downloadErrorText;
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _progress = null;
      });
    }
  }

  String get _shareText {
    final a = widget.ayah;
    final e = tafsirById(_ed);
    final tf = _store.tafsirOf(_ed, a.surah, a.ayah);
    final b = StringBuffer('﴿${a.text}﴾\n${ayahRef(a.surah, a.ayah)}');
    if (tf != null) b.write('\n\n${e.nameAr}:\n$tf\n— ${e.sourceAr}');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.ayah;
    final e = tafsirById(_ed);
    final tf = _store.tafsirOf(_ed, a.surah, a.ayah);
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: .7);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      maxChildSize: .95,
      minChildSize: .4,
      builder: (context, ctl) => ListView(controller: ctl, padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: [
        Text(ayahRef(a.surah, a.ayah),
            textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Lalezar', fontSize: 22, color: readable(context, SD.goldDeep))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SD.gold.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SD.gold.withValues(alpha: .6)),
          ),
          child: Text('﴿${a.text}﴾', textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: _quranStyle.copyWith(color: cs.onSurface, fontSize: 22)),
        ),
        const SizedBox(height: 10),
        ShareBarCompact(text: () => '﴿${a.text}﴾\n${ayahRef(a.surah, a.ayah)}', shareAll: () => _shareText),
        const SizedBox(height: 14),
        Text(t('التفسير / الترجمة', 'التفسير / الترجمة', 'Tafsir / translation'), style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final x in tafsirEditions)
            ChoiceChip(
              label: Text(x.id == 'saheeh' ? 'English (Saheeh Intl.)' : x.nameAr, maxLines: 1, overflow: TextOverflow.ellipsis),
              selected: _ed == x.id,
              onSelected: (_) {
                setState(() {
                  _ed = x.id;
                  _error = null;
                });
                context.read<AppState>().setData('quran_search_tafsir', x.id);
                _load();
              },
            ),
        ]),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (tf != null) ...[
          Text(tf,
              textDirection: e.rtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: e.rtl ? TextAlign.right : TextAlign.left,
              style: TextStyle(fontSize: 16, height: 1.8, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text('${tr('المصدر', 'Source')}: ${e.source}', style: TextStyle(fontSize: 12.5, color: muted)),
          if (!e.rtl)
            Text(tr('ترجمة لمعاني القرآن وليست قرآنًا.', 'A translation of the meanings, not the Qur\'an itself.'),
                style: TextStyle(fontSize: 12.5, color: muted)),
        ] else ...[
          Text(
              '${e.name} — ${t('ما منزّل لسه', 'غير منزّل بعد', 'not downloaded yet')} (≈ ${fmt(e.approxMb, 1)} MB)',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('${tr('المصدر', 'Source')}: ${e.source}', style: TextStyle(fontSize: 12.5, color: muted)),
          const SizedBox(height: 8),
          if (_busy) DownloadProgress(t('بننزّل التفسير…', 'جارٍ تنزيل التفسير…', 'Downloading…'), _progress),
          if (_error != null) NoteBox(_error!, kind: NoteKind.warn),
          FilledButton.icon(
            onPressed: _busy ? null : _download,
            icon: Icon(_error != null ? Icons.refresh_rounded : Icons.download_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(_error != null ? t('جرّب تاني', 'أعد المحاولة', 'Retry') : t('نزّل التفسير', 'تنزيل التفسير', 'Download'))),
          ),
        ],
      ]),
    );
  }
}

/// زرا نسخ ومشاركة (الآية وحدها، أو مع التفسير)
class ShareBarCompact extends StatelessWidget {
  final String Function() text;
  final String Function() shareAll;
  const ShareBarCompact({super.key, required this.text, required this.shareAll});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => copyText(text()),
            icon: const Icon(Icons.copy_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('انسخ الآية', 'نسخ الآية', 'Copy ayah'))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => shareText(shareAll()),
            icon: const Icon(Icons.share_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('شارك', 'مشاركة', 'Share'))),
          ),
        ),
      ]);
}
