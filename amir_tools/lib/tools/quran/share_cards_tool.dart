import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../deen/duas_data.dart' show duas;
import '../islam/adhkar_data.dart' show adhkarSets;
import 'quran_common.dart';
import 'quran_store.dart';

/// تصميم بطاقة
class CardDesign {
  final String id, ar, en;
  final List<Color> bg;
  final Color text, accent, frame;
  final int pattern; // 0 نقش نجمي، 1 نجوم ليلية وموج، 2 كثبان، 3 زخرفة إسلامية، 4 بسيط، 5 حِنّة
  const CardDesign(this.id, this.ar, this.en, this.bg, this.text, this.accent, this.frame, this.pattern);
  String get name => tr(ar, en);
}

const cardDesigns = [
  CardDesign('leather', 'جلد وذهب', 'Leather & gold', [Color(0xFF7A4A24), Color(0xFF5A3418), Color(0xFF2E1808)], Color(0xFFFFF1D0), Color(0xFFF2C66B), SD.gold, 0),
  CardDesign('nile', 'ليل النيل', 'Nile night', [Color(0xFF0B2545), Color(0xFF0B5C8A), Color(0xFF13315C)], Colors.white, Color(0xFF9AD1F5), Color(0xFF9AD1F5), 1),
  CardDesign('dunes', 'كثبان الرمل', 'Sand dunes', [Color(0xFFFBEBD0), Color(0xFFF0CF96), Color(0xFFD9A35B)], Color(0xFF3A1F0C), Color(0xFF8A4B14), Color(0xFFB9852F), 2),
  CardDesign('green', 'نقش أخضر', 'Green pattern', [Color(0xFF0B4D2C), Color(0xFF007229), Color(0xFF053B20)], Color(0xFFFFF8E7), Color(0xFFF6D58B), Color(0xFFF6D58B), 3),
  CardDesign('light', 'فاتح بسيط', 'Minimal light', [Color(0xFFFFFFFF), Color(0xFFFAF6EE), Color(0xFFF3ECDD)], Color(0xFF2B2B2B), Color(0xFF8A6A2F), Color(0xFFCDB68A), 4),
  CardDesign('henna', 'حِنّة', 'Henna', [Color(0xFFB4492D), Color(0xFF8E2F1C), Color(0xFF5A1C10)], Color(0xFFFFEFE0), Color(0xFFFFD39B), Color(0xFFFFD39B), 5),
];

/// محتوى البطاقة: نص + مرجع (المرجع إلزامي)
class CardContent {
  final String text, reference;
  final String? heading;
  final bool quran;
  const CardContent(this.text, this.reference, {this.heading, this.quran = false});
  bool get valid => text.trim().isNotEmpty && reference.trim().isNotEmpty;
}

/// عناصر الأذكار والأدعية المتاحة (فقط ما له مصدر مكتوب)
List<(String, CardContent)> dhikrChoices() {
  final out = <(String, CardContent)>[];
  for (final set in adhkarSets) {
    for (final d in set.items) {
      final src = d.source;
      if (src == null || src.trim().isEmpty) continue;
      final label = d.title ?? d.text.split(RegExp(r'\s+')).take(6).join(' ');
      out.add(('${set.name} • $label', CardContent(d.text, '${set.name} — $src', heading: d.title)));
    }
  }
  return out;
}

List<(String, CardContent)> duaChoices() => [
      for (final d in duas)
        if (d.srcAr.trim().isNotEmpty)
          ('${d.cat.label} • ${d.text.split(RegExp(r'\s+')).take(5).join(' ')}', CardContent(d.text, d.quran ? '(${d.srcAr})' : d.srcAr, quran: d.quran)),
    ];

/// بطاقات مشاركة الآيات والأذكار
class ShareCardsTool extends StatefulWidget {
  const ShareCardsTool({super.key});
  @override
  State<ShareCardsTool> createState() => _ShareCardsToolState();
}

class _ShareCardsToolState extends State<ShareCardsTool> {
  final _store = QuranStore.instance;
  final _boundary = GlobalKey();
  String _src = 'dhikr';
  String _design = 'leather';
  bool _tall = false;
  double _font = 22;
  int _surah = 1, _ayah = 1, _count = 1;
  int _dhikr = 0, _dua = 0;
  bool _checking = true, _busy = false, _downloading = false;
  double? _progress;
  String? _error;

  late final List<(String, CardContent)> _dhikrList = dhikrChoices();
  late final List<(String, CardContent)> _duaList = duaChoices();

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final saved = s.getData<Map>('share_cards_prefs');
    if (saved != null) {
      _design = '${saved['d'] ?? _design}';
      _tall = saved['t'] == true;
      _font = ((saved['f'] as num?) ?? _font).toDouble().clamp(14, 36);
      _src = '${saved['s'] ?? _src}';
    }
    _store.loadLocal().whenComplete(() {
      if (mounted) setState(() => _checking = false);
    });
  }

  void _save() => context.read<AppState>().setData('share_cards_prefs', {'d': _design, 't': _tall, 'f': _font, 's': _src});

  CardDesign get _d => cardDesigns.firstWhere((x) => x.id == _design, orElse: () => cardDesigns.first);

  CardContent? get _content {
    switch (_src) {
      case 'ayah':
        if (!_store.ready) return null;
        final n = _store.ayahCount(_surah);
        if (n == 0) return null;
        final a = _ayah.clamp(1, n);
        final to = math.min(n, a + _count - 1);
        final parts = [
          for (var i = a; i <= to; i++) '${_store.ayah(_surah, i)!.text} ﴿${_ar(i)}﴾',
        ];
        return CardContent(parts.join(' '), ayahRef(_surah, a, to), quran: true);
      case 'dua':
        if (_duaList.isEmpty) return null;
        return _duaList[_dua.clamp(0, _duaList.length - 1)].$2;
      default:
        if (_dhikrList.isEmpty) return null;
        return _dhikrList[_dhikr.clamp(0, _dhikrList.length - 1)].$2;
    }
  }

  String _ar(int n) => n.toString().split('').map((c) => '٠١٢٣٤٥٦٧٨٩'[int.parse(c)]).join();

  Future<void> _downloadQuran() async {
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0;
    });
    try {
      final ok = await _store.download(onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      if (!ok) throw StateError('parse');
    } catch (_) {
      _error = downloadErrorText;
    }
    if (mounted) {
      setState(() {
        _downloading = false;
        _progress = null;
      });
    }
  }

  Future<void> _share() async {
    final c = _content;
    // لا مشاركة دون مرجع
    if (c == null || !c.valid) {
      return toast(t('البطاقة لازم يكون فيها المصدر', 'يجب أن تتضمن البطاقة المصدر', 'A card must include its reference'));
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final b = _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (b == null) throw StateError('no boundary');
      final ratio = 1080 / b.size.width;
      final img = await b.toImage(pixelRatio: ratio);
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      if (bd == null) throw StateError('no bytes');
      final bytes = bd.buffer.asUint8List();
      final name = 'ameer_card_${DateTime.now().millisecondsSinceEpoch}.png';
      XFile f;
      if (kIsWeb) {
        f = XFile.fromData(bytes, name: name, mimeType: 'image/png');
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$name');
        await file.writeAsBytes(bytes, flush: true);
        f = XFile(file.path, mimeType: 'image/png', name: name);
      }
      await SharePlus.instance.share(ShareParams(files: [f], text: c.reference));
      if (mounted) context.read<AppState>().awardDaily('share_cards', 5, tr('مشاركة بطاقة', 'Shared a card'));
    } catch (_) {
      toast(t('ما قدرنا نشارك الصورة، جرّب تاني', 'تعذّرت مشاركة الصورة، حاول مرة أخرى', "Couldn't share the image, try again"));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _content;
    return ToolList(children: [
      SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 'ayah', label: _seg(tr('آية', 'Ayah'))),
          ButtonSegment(value: 'dhikr', label: _seg(tr('ذكر', 'Dhikr'))),
          ButtonSegment(value: 'dua', label: _seg(tr('دعاء', 'Dua'))),
        ],
        selected: {_src},
        onSelectionChanged: (v) {
          setState(() => _src = v.first);
          _save();
        },
      ),
      const SizedBox(height: 14),
      SCard(
        title: t('اختار النص', 'اختر النص', 'Choose the text'),
        icon: Icons.format_quote_rounded,
        color: SD.green,
        child: _picker(),
      ),
      if (c != null) ...[
        LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          return Center(
            child: SizedBox(
              width: _tall ? w * .72 : w,
              child: RepaintBoundary(
                key: _boundary,
                child: AspectRatio(aspectRatio: _tall ? 9 / 16 : 1, child: VerseCard(content: c, design: _d, fontSize: _font)),
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _busy || !c.valid ? null : _share,
          icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.ios_share_rounded),
          label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('شارك البطاقة كصورة', 'مشاركة البطاقة كصورة', 'Share card as image'))),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => copyText('${c.text}\n${c.reference}'),
          icon: const Icon(Icons.copy_rounded),
          label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('انسخ النص مع المصدر', 'نسخ النص مع المصدر', 'Copy text with reference'))),
        ),
        const SizedBox(height: 14),
      ],
      SCard(
        title: t('التصميم', 'التصميم', 'Design'),
        icon: Icons.palette_rounded,
        color: SD.purple,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final d in cardDesigns)
              ChoiceChip(
                avatar: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: d.bg), border: Border.all(color: d.frame)),
                ),
                label: Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                selected: _design == d.id,
                onSelected: (_) {
                  setState(() => _design = d.id);
                  _save();
                },
              ),
          ]),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, icon: const Icon(Icons.crop_square_rounded), label: _seg(t('مربّع 1:1', 'مربع 1:1', 'Square 1:1'))),
              ButtonSegment(value: true, icon: const Icon(Icons.crop_portrait_rounded), label: _seg(t('ستوري 9:16', 'قصة 9:16', 'Story 9:16'))),
            ],
            selected: {_tall},
            onSelectionChanged: (v) {
              setState(() => _tall = v.first);
              _save();
            },
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.format_size_rounded, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Slider(
                value: _font,
                min: 14,
                max: 36,
                divisions: 22,
                label: _font.round().toString(),
                onChanged: (v) => setState(() => _font = v),
                onChangeEnd: (_) => _save(),
              ),
            ),
            SizedBox(width: 32, child: FittedBox(fit: BoxFit.scaleDown, child: Text('${_font.round()}', style: const TextStyle(fontWeight: FontWeight.w800)))),
          ]),
          Text(t('لو النص طويل بيصغر براه عشان يدخل في البطاقة.', 'إن طال النص يُصغَّر تلقائيًا ليتسع في البطاقة.', 'Long texts shrink automatically to fit the card.'),
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65))),
        ]),
      ),
      NoteBox(
          t('المصدر بيتطبع دايمًا في البطاقة وما بنسمح بمشاركتها من غيره. النصوص منقولة من بيانات التطبيق ومن نص المصحف المنزّل بدون أي تعديل.',
              'يُطبع المصدر دائمًا في البطاقة ولا تُتاح مشاركتها دونه. النصوص منقولة من بيانات التطبيق ومن نص المصحف المنزّل دون تعديل.',
              'The reference is always printed on the card and it cannot be shared without it. Texts come unchanged from the app data and the downloaded Qur\'an text.'),
          kind: NoteKind.info),
    ]);
  }

  Widget _seg(String s) => FittedBox(fit: BoxFit.scaleDown, child: Text(s, maxLines: 1));

  Widget _picker() {
    switch (_src) {
      case 'ayah':
        if (_checking) return const Center(child: CircularProgressIndicator());
        if (!_store.ready) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t('عشان تختار آية، نزّل نص المصحف مرة وحدة (≈ 1.5 ميقا) — نفس الملف البتستعمله أداة «البحث في القرآن».',
                'لاختيار آية، نزّل نص المصحف مرة واحدة (≈ 1.5 ميغابايت) — وهو الملف نفسه الذي تستخدمه أداة «البحث في القرآن».',
                "To pick an ayah, download the Qur'an text once (≈ 1.5 MB) — the same file used by the Qur'an Search tool."),
                style: const TextStyle(height: 1.5)),
            const SizedBox(height: 10),
            if (_downloading) DownloadProgress(t('بننزّل…', 'جارٍ التنزيل…', 'Downloading…'), _progress),
            if (_error != null) NoteBox(_error!, kind: NoteKind.warn),
            FilledButton.icon(
              onPressed: _downloading ? null : _downloadQuran,
              icon: const Icon(Icons.download_rounded),
              label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('نزّل نص المصحف', 'تنزيل نص المصحف', "Download Qur'an text"))),
            ),
          ]);
        }
        final n = _store.ayahCount(_surah);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<int>(
            initialValue: _surah,
            isExpanded: true,
            decoration: InputDecoration(labelText: tr('السورة', 'Surah')),
            items: [
              for (var s = 1; s <= 114; s++)
                DropdownMenuItem(value: s, child: Text('$s. سورة ${surahName(s)}', maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() {
              _surah = v ?? 1;
              _ayah = 1;
              _count = 1;
            }),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _stepper(tr('من آية', 'From ayah'), _ayah, 1, n, (v) {
              _ayah = v;
              _count = math.max(1, math.min(_count, n - v + 1));
            })),
            const SizedBox(width: 10),
            Expanded(child: _stepper(t('عدد الآيات', 'عدد الآيات', 'Ayat count'), _count, 1, math.min(5, n - _ayah + 1), (v) => _count = v)),
          ]),
        ]);
      case 'dua':
        return _listPicker(_duaList, _dua, (i) => _dua = i);
      default:
        return _listPicker(_dhikrList, _dhikr, (i) => _dhikr = i);
    }
  }

  Widget _listPicker(List<(String, CardContent)> list, int sel, void Function(int) set) => DropdownButtonFormField<int>(
        key: ValueKey('pick_$_src'),
        initialValue: sel.clamp(0, math.max(0, list.length - 1)),
        isExpanded: true,
        decoration: InputDecoration(labelText: tr('النص', 'Text')),
        items: [
          for (var i = 0; i < list.length; i++)
            DropdownMenuItem(value: i, child: Text(list[i].$1, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) => setState(() => set(v ?? 0)),
      );

  Widget _stepper(String label, int v, int min, int max, void Function(int) set) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: SD.gold.withValues(alpha: .5))),
      child: Column(children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: .7))),
        Row(children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: v > min ? () => setState(() => set(v - 1)) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: Text('$v', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: v < max ? () => setState(() => set(v + 1)) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ]),
      ]),
    );
  }
}

/// البطاقة نفسها (تُرسم ثم تُحوَّل لصورة)
class VerseCard extends StatelessWidget {
  final CardContent content;
  final CardDesign design;
  final double fontSize;
  const VerseCard({super.key, required this.content, required this.design, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final d = design;
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final scale = w / 340; // كل المقاسات نسبية لعرض البطاقة
      final pad = 26.0 * scale;
      return ClipRRect(
        borderRadius: BorderRadius.circular(18 * scale),
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: d.bg, begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _CardPatternPainter(d))),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(10 * scale),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12 * scale),
                    border: Border.all(color: d.frame.withValues(alpha: .85), width: 1.6 * scale),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, pad, pad, pad * .8),
                child: Column(children: [
                  Text('❁', style: TextStyle(color: d.accent, fontSize: 18 * scale)),
                  if (content.heading != null)
                    Text(content.heading!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: d.accent, fontSize: 13 * scale, fontWeight: FontWeight.w800, fontFamily: 'Tajawal')),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: w - pad * 2,
                          child: Text(
                            content.quran ? '﴿${content.text}﴾' : content.text,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(color: d.text, fontSize: fontSize * scale * .85, height: 1.75, fontFamily: 'Tajawal', fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  Container(height: 1.2 * scale, width: w * .3, color: d.accent.withValues(alpha: .7)),
                  SizedBox(height: 6 * scale),
                  // المرجع — يُطبع دائمًا
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: w - pad * 2,
                      child: Text(content.reference,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(color: d.accent, fontSize: 13 * scale, fontWeight: FontWeight.w800, fontFamily: 'Tajawal')),
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Text('أدوات أمير • Ameer Tools',
                      maxLines: 1, style: TextStyle(color: d.text.withValues(alpha: .55), fontSize: 8.5 * scale, fontFamily: 'Tajawal')),
                ]),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

class _CardPatternPainter extends CustomPainter {
  final CardDesign d;
  _CardPatternPainter(this.d);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width / 400
      ..color = d.accent.withValues(alpha: .13);
    final w = size.width, h = size.height;
    switch (d.pattern) {
      case 0: // نجوم ثمانية في الأركان (جلد وذهب)
      case 3: // شبكة نجوم إسلامية
        final step = w / (d.pattern == 3 ? 6 : 4);
        for (var y = d.pattern == 3 ? 0.0 : -step / 2; y < h + step; y += step) {
          for (var x = 0.0; x < w + step; x += step) {
            if (d.pattern == 0 && y > step && y < h - step * 1.5) continue;
            _star(canvas, Offset(x, y), step * .32, p);
          }
        }
      case 1: // نجوم ليلية وموج النيل
        final rnd = math.Random(7);
        final dot = Paint()..color = Colors.white.withValues(alpha: .35);
        for (var i = 0; i < 40; i++) {
          canvas.drawCircle(Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * .45), rnd.nextDouble() * w / 260 + w / 700, dot);
        }
        final wave = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w / 240
          ..color = d.accent.withValues(alpha: .18);
        for (var k = 0; k < 3; k++) {
          final path = Path();
          final by = h * (.82 + k * .05);
          path.moveTo(0, by);
          for (var x = 0.0; x <= w; x += w / 40) {
            path.lineTo(x, by + math.sin(x / w * math.pi * 4 + k) * h * .012);
          }
          canvas.drawPath(path, wave);
        }
      case 2: // كثبان
        for (var k = 0; k < 3; k++) {
          final fill = Paint()..color = const Color(0xFF8A4B14).withValues(alpha: .07 + k * .03);
          final path = Path()..moveTo(0, h);
          final base = h * (.78 + k * .07);
          path.lineTo(0, base);
          path.quadraticBezierTo(w * (.3 + k * .1), base - h * .08, w * .6, base);
          path.quadraticBezierTo(w * .85, base + h * .04, w, base - h * .03);
          path.lineTo(w, h);
          path.close();
          canvas.drawPath(path, fill);
        }
        canvas.drawCircle(Offset(w * .82, h * .14), w * .07, Paint()..color = const Color(0xFFE2702B).withValues(alpha: .18));
      case 4: // بسيط: زخرفة ركنية خفيفة
        final c = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w / 300
          ..color = d.accent.withValues(alpha: .25);
        for (final o in [Offset(w * .1, h * .08), Offset(w * .9, h * .92)]) {
          _star(canvas, o, w * .05, c);
        }
      case 5: // نقش حِنّة: نقاط ودوائر
        final c = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w / 320
          ..color = d.accent.withValues(alpha: .16);
        for (final o in [Offset(0, 0), Offset(w, 0), Offset(0, h), Offset(w, h)]) {
          for (var r = w * .06; r < w * .3; r += w * .05) {
            canvas.drawCircle(o, r, c);
          }
        }
        final dot = Paint()..color = d.accent.withValues(alpha: .2);
        for (var x = w * .1; x < w; x += w * .1) {
          canvas.drawCircle(Offset(x, h * .035), w / 160, dot);
          canvas.drawCircle(Offset(x, h * .965), w / 160, dot);
        }
    }
  }

  /// نجمة ثمانية (مربعان متداخلان)
  void _star(Canvas c, Offset o, double r, Paint p) {
    for (final rot in [0.0, math.pi / 4]) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = rot + i * math.pi / 2;
        final pt = o + Offset(math.cos(a) * r, math.sin(a) * r);
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      c.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _CardPatternPainter old) => old.d.id != d.id;
}
