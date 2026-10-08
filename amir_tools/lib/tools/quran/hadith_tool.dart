import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'quran_common.dart';

/// مجموعة أحاديث من hadith-api
class HCollection {
  final String id, ar, en;
  final double araMb, engMb;
  final bool large;
  const HCollection(this.id, this.ar, this.en, this.araMb, this.engMb, {this.large = false});
  String get name => tr(ar, en);
  double get totalMb => araMb + engMb;
  String file(String lang) => '$lang-$id';
  String cacheName(String lang) => 'hadith-${file(lang)}.json';
  String url(String lang) => '$hadithApiBase/editions/${file(lang)}.min.json';
}

/// الأحجام تقريبية (ميغابايت) كما في المستودع وقت المراجعة
const hadithCollections = [
  HCollection('nawawi', 'الأربعون النووية', "An-Nawawi's Forty Hadith", .05, .04),
  HCollection('qudsi', 'الأحاديث القدسية (الأربعون القدسية)', 'Forty Hadith Qudsi', .06, .04),
  HCollection('bukhari', 'صحيح البخاري', 'Sahih al-Bukhari', 9.4, 4.8, large: true),
  HCollection('muslim', 'صحيح مسلم', 'Sahih Muslim', 8.3, 3.9, large: true),
  HCollection('abudawud', 'سنن أبي داود', 'Sunan Abi Dawud', 6.6, 3.6, large: true),
  HCollection('tirmidhi', 'جامع الترمذي', "Jami' at-Tirmidhi", 6.6, 2.6, large: true),
  HCollection('nasai', 'سنن النسائي', "Sunan an-Nasa'i", 6.4, 3.3, large: true),
  HCollection('ibnmajah', 'سنن ابن ماجه', 'Sunan Ibn Majah', 5.0, 2.6, large: true),
  HCollection('malik', 'موطأ مالك', "Muwatta Malik", 2.0, 1.5, large: true),
];

HCollection collectionById(String id) => hadithCollections.firstWhere((c) => c.id == id, orElse: () => hadithCollections.first);

/// حديث مدمج (عربي + إنجليزي)
class HItem {
  final int number;
  final String ar, en;
  final List<HadithGrade> grades;
  final int section;
  final String norm;
  const HItem(this.number, this.ar, this.en, this.grades, this.section, this.norm);
}

class HMerged {
  final List<HItem> items;
  final Map<int, String> sections;
  const HMerged(this.items, this.sections);
}

/// يدمج النسختين العربية والإنجليزية برقم الحديث
HMerged mergeHadith(List<String> files) {
  final ar = parseHadithEdition(files[0]);
  final en = files.length > 1 && files[1].isNotEmpty ? parseHadithEdition(files[1]) : const HadithBook('', {}, []);
  final enBy = {for (final h in en.hadiths) h.number: h};
  final seen = <int>{};
  final out = <HItem>[];
  void add(Hadith? a, Hadith? e) {
    final n = (a ?? e)!.number;
    if (!seen.add(n)) return;
    final at = a?.text ?? '', et = e?.text ?? '';
    if (at.isEmpty && et.isEmpty) return;
    final g = <HadithGrade>[];
    for (final x in [...?a?.grades, ...?e?.grades]) {
      if (!g.any((y) => y.name == x.name && y.grade == x.grade)) g.add(x);
    }
    out.add(HItem(n, at, et, g, a?.section ?? e?.section ?? 0, '${normalizeArabic(at)} ${et.toLowerCase()}'));
  }

  for (final h in ar.hadiths) {
    add(h, enBy[h.number]);
  }
  for (final h in en.hadiths) {
    if (!seen.contains(h.number)) add(null, h);
  }
  out.sort((a, b) => a.number - b.number);
  return HMerged(out, en.sections.isNotEmpty ? en.sections : ar.sections);
}

/// مرجع الحديث: «المصدر: صحيح البخاري، رقم 1»
String hadithRef(HCollection c, int n) => '${tr('المصدر', 'Source')}: ${c.name}${tr('، رقم', ', #')} $n';
String hadithRefAr(HCollection c, int n) => 'المصدر: ${c.ar}، رقم $n';

String gradesText(List<HadithGrade> g) => g.map((x) => x.name.isEmpty ? x.grade : '${x.name}: ${x.grade}').join(' • ');

/// نص المشاركة الكامل مع المرجع
String hadithShareText(HCollection c, int n, String ar, String en, List<HadithGrade> g) {
  final b = StringBuffer();
  if (ar.isNotEmpty) b.writeln(ar);
  if (en.isNotEmpty) b.writeln('\n$en');
  b.writeln('\n— ${hadithRefAr(c, n)} (${c.en} #$n)');
  if (g.isNotEmpty) b.writeln('${tr('الحكم', 'Grade')}: ${gradesText(g)}');
  return b.toString().trim();
}

/// كتب الأحاديث: الأربعون النووية والقدسية وكتب السنة الكبرى (عربي + إنجليزي)
class HadithTool extends StatefulWidget {
  const HadithTool({super.key});
  @override
  State<HadithTool> createState() => _HadithToolState();
}

class _HadithToolState extends State<HadithTool> {
  final Map<String, int?> _sizes = {};
  String? _busyId;
  double? _progress;
  String? _errorId;
  bool _favsOpen = false;

  // القارئ
  HCollection? _open;
  HMerged? _data;
  bool _loading = false;
  final _q = TextEditingController();
  Timer? _debounce;
  List<HItem> _view = const [];
  int _section = -1;
  int _shown = 30;

  @override
  void initState() {
    super.initState();
    _refreshSizes();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  Future<void> _refreshSizes() async {
    for (final c in hadithCollections) {
      final a = await cachedSize(c.cacheName('ara'));
      final e = await cachedSize(c.cacheName('eng'));
      _sizes[c.id] = a == null ? null : a + (e ?? 0);
    }
    if (mounted) setState(() {});
  }

  bool _has(HCollection c) => _sizes[c.id] != null;

  List<Map> get _favs => List<Map>.from(context.read<AppState>().getData<List>('hadith_favs') ?? const []);

  Future<void> _download(HCollection c) async {
    if (c.large) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(c.name),
          content: Text(t(
              'الكتاب ده كبير: حوالي ${fmt(c.totalMb, 1)} ميقا (عربي + إنجليزي). الأحسن تنزّله على واي فاي. بعد التنزيل بيشتغل بدون نت.',
              'هذا الكتاب كبير: نحو ${fmt(c.totalMb, 1)} ميغابايت (عربي + إنجليزي). يُفضّل التنزيل عبر Wi‑Fi. بعد التنزيل يعمل دون إنترنت.',
              'This book is large: about ${fmt(c.totalMb, 1)} MB (Arabic + English). Wi‑Fi is recommended. Works offline after download.')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('إلغاء', 'Cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t('نزّل', 'تنزيل', 'Download'))),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() {
      _busyId = c.id;
      _errorId = null;
      _progress = 0;
    });
    try {
      final total = c.totalMb;
      await downloadText(c.url('ara'), c.cacheName('ara'), onProgress: (p) {
        if (mounted && p != null) setState(() => _progress = p * c.araMb / total);
      });
      await downloadText(c.url('eng'), c.cacheName('eng'), onProgress: (p) {
        if (mounted && p != null) setState(() => _progress = (c.araMb + p * c.engMb) / total);
      });
      if (mounted) context.read<AppState>().award(5, '${tr('تنزيل', 'Downloaded')} ${c.name}');
    } catch (_) {
      await deleteCached(c.cacheName('ara'));
      await deleteCached(c.cacheName('eng'));
      _errorId = c.id;
    }
    _busyId = null;
    _progress = null;
    await _refreshSizes();
  }

  Future<void> _delete(HCollection c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('حذف الكتاب من الجهاز؟', 'Delete this book from the device?')),
        content: Text('${c.name} — ${fmtBytes(_sizes[c.id] ?? 0)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('حذف', 'Delete'))),
        ],
      ),
    );
    if (ok != true) return;
    await deleteCached(c.cacheName('ara'));
    await deleteCached(c.cacheName('eng'));
    await _refreshSizes();
  }

  Future<void> _openBook(HCollection c) async {
    setState(() {
      _open = c;
      _loading = true;
      _data = null;
      _q.clear();
      _section = -1;
      _shown = 30;
    });
    try {
      final ar = await readCached(c.cacheName('ara'));
      final en = await readCached(c.cacheName('eng'));
      if (ar == null) throw StateError('missing');
      final m = await compute(mergeHadith, [ar, en ?? '']);
      if (!mounted || _open != c) return;
      _data = m;
      _filter();
      context.read<AppState>().awardDaily('hadith', 3, tr('قراءة الأحاديث', 'Read hadith'));
    } catch (_) {
      toast(t('ما قدرنا نفتح الكتاب — نزّله تاني', 'تعذّر فتح الكتاب — أعد تنزيله', "Couldn't open the book — download it again"));
      _open = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _filter() {
    final d = _data;
    if (d == null) return;
    final q = _q.text.trim();
    final nq = normalizeArabic(q);
    final num = int.tryParse(q);
    _view = d.items.where((h) {
      if (_section >= 0 && h.section != _section) return false;
      if (q.isEmpty) return true;
      if (num != null) return h.number == num;
      return nq.length >= 2 && h.norm.contains(nq);
    }).toList();
    _shown = 30;
  }

  void _toggleFav(HCollection c, HItem h) {
    final s = context.read<AppState>();
    final favs = _favs;
    final i = favs.indexWhere((f) => f['b'] == c.id && f['n'] == h.number);
    if (i >= 0) {
      favs.removeAt(i);
      toast(t('اتشال من المفضلة', 'أُزيل من المفضلة', 'Removed from favourites'));
    } else {
      favs.insert(0, {
        'b': c.id,
        'n': h.number,
        'ar': h.ar,
        'en': h.en,
        'g': [for (final g in h.grades) [g.name, g.grade]],
      });
      toast(t('اتحفظ في المفضلة ✓', 'حُفظ في المفضلة ✓', 'Saved to favourites ✓'), icon: Icons.favorite_rounded);
      s.bump('hadith_fav');
    }
    s.setData('hadith_favs', favs);
    setState(() {});
  }

  bool _isFav(String b, int n) => _favs.any((f) => f['b'] == b && f['n'] == n);

  @override
  Widget build(BuildContext context) {
    if (_open != null) return _reader();
    return _home();
  }

  // ───────── الصفحة الرئيسية ─────────
  Widget _home() {
    final favs = _favs;
    final downloaded = hadithCollections.where(_has).length;
    final used = _sizes.values.whereType<int>().fold<int>(0, (a, b) => a + b);
    return ToolList(children: [
      ResultHero(
        label: t('كتب الحديث الشريف', 'كتب الحديث الشريف', 'Hadith collections'),
        value: '${hadithCollections.length}',
        sub: t('كتب — عربي وإنجليزي، بحث ومفضلة، وبتشتغل بدون نت بعد التنزيل', 'كتب — عربي وإنجليزي، بحث ومفضلة، وتعمل دون إنترنت بعد التنزيل',
            'books — Arabic & English, search, favourites, offline after download'),
      ),
      StatGrid([
        StatChip('$downloaded', t('منزّلة', 'منزّلة', 'Downloaded'), color: SD.green, icon: Icons.download_done_rounded),
        StatChip('${favs.length}', tr('المفضلة', 'Favourites'), color: SD.pink, icon: Icons.favorite_rounded),
        StatChip(fmtBytes(used), t('المساحة', 'المساحة', 'Storage'), color: SD.nile, icon: Icons.sd_storage_rounded),
      ]),
      const SizedBox(height: 14),
      if (favs.isNotEmpty)
        SCard(
          title: '${tr('المفضلة', 'Favourites')} (${favs.length})',
          icon: Icons.favorite_rounded,
          color: SD.pink,
          trailing: IconButton(
            icon: Icon(_favsOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            onPressed: () => setState(() => _favsOpen = !_favsOpen),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final f in (_favsOpen ? favs : favs.take(3)))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.format_quote_rounded),
                title: Text('${f['ar'] ?? ''}'.isNotEmpty ? '${f['ar']}' : '${f['en'] ?? ''}',
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(hadithRef(collectionById('${f['b']}'), f['n'] as int), maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => _favSheet(f),
              ),
            if (!_favsOpen && favs.length > 3)
              TextButton(onPressed: () => setState(() => _favsOpen = true), child: Text(tr('عرض الكل', 'Show all'))),
          ]),
        ),
      SectionTitle(t('الكتب الصغيرة', 'الكتب المختصرة', 'Short collections'), icon: Icons.auto_stories_rounded),
      for (final c in hadithCollections.where((c) => !c.large)) _bookCard(c),
      SectionTitle(t('كتب السنة الكبيرة (اختيارية)', 'كتب السنة الكبرى (اختيارية)', 'Major collections (optional)'), icon: Icons.library_books_rounded),
      NoteBox(
          t('الكتب دي كبيرة (بين 3.5 و14 ميقا)، نزّل البتحتاجه بس.', 'هذه الكتب كبيرة (بين 3.5 و14 ميغابايت)، نزّل ما تحتاجه فقط.',
              'These books are large (3.5–14 MB each) — download only what you need.'),
          kind: NoteKind.warn),
      for (final c in hadithCollections.where((c) => c.large)) _bookCard(c),
      NoteBox(
          t('النصوص والأحكام منقولة كما هي من مصدر البيانات (hadith-api)، والتطبيق ما بيألّف ولا بيصحّح أحاديث. الترقيم حسب المصدر وممكن يختلف شوية عن بعض الطبعات.',
              'النصوص والأحكام منقولة كما هي من مصدر البيانات (hadith-api)، ولا يؤلّف التطبيق أحاديث ولا يحكم عليها. الترقيم وفق المصدر وقد يختلف قليلًا عن بعض الطبعات.',
              'Texts and gradings are shown exactly as in the data source (hadith-api); the app never writes or grades hadith. Numbering follows the source and may differ slightly from some printed editions.'),
          kind: NoteKind.info),
      Text('${tr('مصدر البيانات', 'Data source')}: github.com/fawazahmed0/hadith-api',
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65))),
      const ReviewedLine('hadith', 'collection sizes / source'),
    ]);
  }

  Widget _bookCard(HCollection c) {
    final has = _has(c);
    final busy = _busyId == c.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(has ? Icons.menu_book_rounded : Icons.cloud_download_outlined, color: readable(context, has ? SD.green : SD.goldDeep)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                Text(
                    has
                        ? '${t('منزّل', 'منزّل', 'Downloaded')} • ${fmtBytes(_sizes[c.id]!)}'
                        : '≈ ${fmt(c.totalMb, c.totalMb < 1 ? 2 : 1)} MB • ${tr('عربي + إنجليزي', 'Arabic + English')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5)),
              ]),
            ),
            if (has)
              IconButton(
                tooltip: tr('حذف', 'Delete'),
                onPressed: busy ? null : () => _delete(c),
                icon: Icon(Icons.delete_outline_rounded, color: readable(context, SD.red)),
              ),
          ]),
          if (busy) DownloadProgress(t('بننزّل…', 'جارٍ التنزيل…', 'Downloading…'), _progress),
          if (_errorId == c.id) NoteBox(downloadErrorText, kind: NoteKind.warn),
          const SizedBox(height: 8),
          has
              ? FilledButton.icon(
                  onPressed: () => _openBook(c),
                  icon: const Icon(Icons.chrome_reader_mode_rounded),
                  label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('افتح واقرأ', 'افتح واقرأ', 'Open & read'))),
                )
              : OutlinedButton.icon(
                  onPressed: _busyId != null ? null : () => _download(c),
                  icon: Icon(_errorId == c.id ? Icons.refresh_rounded : Icons.download_rounded),
                  label: FittedBox(
                      fit: BoxFit.scaleDown, child: Text(_errorId == c.id ? t('جرّب تاني', 'أعد المحاولة', 'Retry') : t('نزّل', 'تنزيل', 'Download'))),
                ),
        ]),
      ),
    );
  }

  void _favSheet(Map f) {
    final c = collectionById('${f['b']}');
    final n = f['n'] as int;
    final g = [for (final x in (f['g'] as List? ?? const [])) HadithGrade('${(x as List)[0]}', '${x[1]}')];
    final h = HItem(n, '${f['ar'] ?? ''}', '${f['en'] ?? ''}', g, 0, '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .7,
        maxChildSize: .95,
        builder: (ctx, ctl) => ListView(controller: ctl, padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: [
          _HadithCard(c: c, h: h, query: '', fav: true, onFav: () {
            _toggleFav(c, h);
            Navigator.pop(ctx);
          }),
        ]),
      ),
    );
  }

  // ───────── القارئ ─────────
  Widget _reader() {
    final c = _open!;
    final d = _data;
    final header = <Widget>[
      Row(children: [
        IconButton(onPressed: () => setState(() => _open = null), icon: const Icon(Icons.arrow_back_rounded), tooltip: tr('رجوع', 'Back')),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(c.name, style: TextStyle(fontFamily: 'Lalezar', fontSize: 24, color: readable(context, SD.goldDeep))),
          ),
        ),
      ]),
      if (_loading || d == null)
        const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
      else ...[
        TextField(
          controller: _q,
          textInputAction: TextInputAction.search,
          onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 400), () {
              if (mounted) setState(_filter);
            });
          },
          decoration: InputDecoration(
            labelText: t('دوّر بكلمة أو رقم الحديث', 'ابحث بكلمة أو رقم الحديث', 'Search a word or hadith number'),
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 10),
        if (d.sections.length > 1)
          DropdownButtonFormField<int>(
            key: ValueKey('sec_${c.id}'),
            initialValue: _section,
            isExpanded: true,
            decoration: InputDecoration(labelText: t('الكتاب / الباب', 'الكتاب / الباب', 'Book / chapter')),
            items: [
              DropdownMenuItem(value: -1, child: Text(tr('الكل', 'All'), maxLines: 1, overflow: TextOverflow.ellipsis)),
              for (final e in d.sections.entries) DropdownMenuItem(value: e.key, child: Text('${e.key}. ${e.value}', maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() {
              _section = v ?? -1;
              _filter();
            }),
          ),
        const SizedBox(height: 10),
        StatGrid([
          StatChip(fmt(d.items.length, 0), t('حديث في الكتاب', 'حديثًا في الكتاب', 'in the book'), color: SD.green),
          StatChip(fmt(_view.length, 0), t('نتيجة', 'نتيجة', 'results'), color: SD.gold),
        ], columns: 2),
        const SizedBox(height: 10),
        if (_view.isEmpty) NoteBox(t('ما في نتائج.', 'لا توجد نتائج.', 'No results.')),
      ],
    ];
    final shown = _view.length < _shown ? _view.length : _shown;
    final more = _view.length > shown;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: header.length + (d == null ? 0 : shown) + (more ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i < header.length) return header[i];
        final j = i - header.length;
        if (j >= shown) {
          return OutlinedButton.icon(
            onPressed: () => setState(() => _shown += 30),
            icon: const Icon(Icons.expand_more_rounded),
            label: Text('${tr('عرض المزيد', 'Show more')} (${_view.length - shown})'),
          );
        }
        final h = _view[j];
        return _HadithCard(c: c, h: h, query: _q.text.trim(), fav: _isFav(c.id, h.number), onFav: () => _toggleFav(c, h), section: d!.sections[h.section]);
      },
    );
  }
}

class _HadithCard extends StatefulWidget {
  final HCollection c;
  final HItem h;
  final String query;
  final bool fav;
  final VoidCallback onFav;
  final String? section;
  const _HadithCard({required this.c, required this.h, required this.query, required this.fav, required this.onFav, this.section});
  @override
  State<_HadithCard> createState() => _HadithCardState();
}

class _HadithCardState extends State<_HadithCard> {
  bool _en = true;
  @override
  Widget build(BuildContext context) {
    final h = widget.h;
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: .7);
    final q = int.tryParse(widget.query) == null ? widget.query : '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: SD.gold.withValues(alpha: .2), borderRadius: BorderRadius.circular(12)),
              child: Text('#${h.number}', style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, SD.goldDeep))),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.section ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: muted)),
            ),
            IconButton(
              tooltip: tr('المفضلة', 'Favourite'),
              onPressed: widget.onFav,
              icon: Icon(widget.fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: readable(context, SD.pink)),
            ),
          ]),
          if (h.ar.isNotEmpty)
            Directionality(
              textDirection: TextDirection.rtl,
              child: RichText(text: highlightSpan(h.ar, q, TextStyle(fontFamily: 'Tajawal', fontSize: 17, height: 1.8, color: cs.onSurface), SD.gold)),
            ),
          if (h.en.isNotEmpty) ...[
            const Divider(height: 20),
            InkWell(
              onTap: () => setState(() => _en = !_en),
              child: Row(children: [
                Icon(_en ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18, color: muted),
                const SizedBox(width: 4),
                Expanded(child: Text('English', style: TextStyle(fontSize: 12.5, color: muted, fontWeight: FontWeight.w700))),
              ]),
            ),
            if (_en)
              Directionality(
                textDirection: TextDirection.ltr,
                child: RichText(text: highlightSpan(h.en, q, TextStyle(fontFamily: 'Tajawal', fontSize: 15, height: 1.6, color: cs.onSurface), SD.gold)),
              ),
          ],
          const SizedBox(height: 10),
          if (h.grades.isNotEmpty)
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final g in h.grades)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: SD.green.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: readable(context, SD.green).withValues(alpha: .4)),
                  ),
                  child: Text(g.name.isEmpty ? g.grade : '${g.name}: ${g.grade}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
            ]),
          const SizedBox(height: 6),
          Text(hadithRef(widget.c, h.number), style: TextStyle(fontSize: 12.5, color: muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ShareBar(() => hadithShareText(widget.c, h.number, h.ar, h.en, h.grades)),
        ]),
      ),
    );
  }
}
