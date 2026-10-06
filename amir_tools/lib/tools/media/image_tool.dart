import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'media_common.dart';

/// الضغط نفسه (يشتغل في isolate)
Map<String, dynamic>? _compress(Map<String, dynamic> a) {
  final src = img.decodeImage(a['bytes'] as Uint8List);
  if (src == null) return null;
  var im = img.bakeOrientation(src);
  final ow = im.width, oh = im.height;
  final maxW = a['maxW'] as int;
  if (maxW > 0 && math.max(im.width, im.height) > maxW) {
    // نطبّق الحد على الضلع الأطول عشان الصور الطولية كمان تتصغّر
    im = im.width >= im.height
        ? img.copyResize(im, width: maxW, interpolation: img.Interpolation.average)
        : img.copyResize(im, height: maxW, interpolation: img.Interpolation.average);
  }
  final out = img.encodeJpg(im, quality: a['q'] as int);
  return {'bytes': out, 'w': im.width, 'h': im.height, 'ow': ow, 'oh': oh};
}

class ImageTool extends StatefulWidget {
  const ImageTool({super.key});
  @override
  State<ImageTool> createState() => _ImageToolState();
}

class _ImageToolState extends State<ImageTool> {
  Uint8List? _orig, _out;
  String _name = '';
  int _ow = 0, _oh = 0, _w = 0, _h = 0;
  double _q = 70;
  int _maxW = 1280;
  bool _busy = false;
  int _ms = 0;
  double _perDay = 10;

  static const _widths = [0, 2048, 1600, 1280, 1080, 800, 640];

  Future<void> _pick(ImageSource src) async {
    try {
      final x = await ImagePicker().pickImage(source: src, requestFullMetadata: false);
      if (x == null) return;
      final b = await x.readAsBytes();
      setState(() {
        _orig = b;
        _out = null;
        _name = x.name;
      });
      await _run();
    } catch (e) {
      toast(src == ImageSource.camera ? 'ما قدرنا نفتح الكاميرا — أتأكد من الإذن' : 'ما قدرنا نفتح الصورة');
    }
  }

  Future<void> _run() async {
    final o = _orig;
    if (o == null) return;
    setState(() => _busy = true);
    final sw = Stopwatch()..start();
    try {
      final r = await compute(_compress, <String, dynamic>{'bytes': o, 'q': _q.round(), 'maxW': _maxW});
      if (r == null) {
        toast('الصيغة دي ما مدعومة');
      } else {
        _out = Uint8List.fromList(r['bytes'] as List<int>);
        _w = r['w'];
        _h = r['h'];
        _ow = r['ow'];
        _oh = r['oh'];
      }
    } catch (_) {
      toast('حصلت مشكلة في الضغط، جرّب صورة تانية');
    }
    _ms = sw.elapsedMilliseconds;
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _share() async {
    final o = _out;
    if (o == null) return;
    final base = _name.contains('.') ? _name.substring(0, _name.lastIndexOf('.')) : 'photo';
    await shareBytes(o, '${base}_amir.jpg', 'image/jpeg');
  }

  @override
  Widget build(BuildContext context) {
    final o = _orig, c = _out;
    final saved = (o != null && c != null) ? o.length - c.length : 0;
    final pct = (o != null && c != null && o.isNotEmpty) ? saved / o.length * 100 : 0.0;
    final monthMb = saved > 0 ? saved * _perDay * 30 / 1048576 : 0.0;
    return ToolList(children: [
      SCard(
        title: 'اختار صورة',
        icon: Icons.add_photo_alternate_rounded,
        color: SD.green,
        child: Row(children: [
          Expanded(child: FilledButton.icon(onPressed: () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library_rounded), label: const Text('من الاستوديو'))),
          const SizedBox(width: 10),
          if (!kIsWeb)
            Expanded(child: OutlinedButton.icon(onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.photo_camera_rounded), label: const Text('صوّر'))),
        ]),
      ),
      SCard(
        title: 'إعدادات الضغط',
        icon: Icons.tune_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Text('الجودة'),
            Expanded(
              child: Slider(
                value: _q,
                min: 10,
                max: 100,
                divisions: 18,
                label: '${_q.round()}%',
                onChanged: (v) => setState(() => _q = v),
                onChangeEnd: (_) => _run(),
              ),
            ),
            Text('${_q.round()}%', style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          Text(
            _q >= 85
                ? 'جودة عالية — الفرق في الحجم بسيط'
                : _q >= 60
                    ? 'متوازنة 👌 — مناسبة للواتساب والفيسبوك'
                    : _q >= 35
                        ? 'موفّرة — ممكن يظهر تشويش خفيف'
                        : 'موفّرة شديد — الجودة بتنزل واضح',
            style: const TextStyle(fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          const Text('أقصى عرض (الضلع الأطول)'),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final w in _widths)
              ChoiceChip(
                label: Text(w == 0 ? 'الأصلي' : '$w px'),
                selected: _maxW == w,
                onSelected: (_) {
                  setState(() => _maxW = w);
                  _run();
                },
              ),
          ]),
        ]),
      ),
      if (_busy) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: SD.gold))),
      if (o == null) const NoteBox('اختار صورة وبنضغطها ليك عشان توفّر الباقة والمساحة، والصورة ما بتطلع من جهازك.', kind: NoteKind.tip),
      if (o != null && c != null && !_busy) ...[
        ResultHero(
          label: saved > 0 ? 'وفّرت' : 'الحجم ما نقص',
          value: saved > 0 ? '${pct.toStringAsFixed(0)}%' : '0%',
          sub: '${fmtBytes(o.length)}  ←  ${fmtBytes(c.length)}',
          colors: const [SD.green, SD.teal, SD.nile],
        ),
        Row(children: [
          Expanded(child: _preview('قبل', o, '$_ow×$_oh')),
          const SizedBox(width: 10),
          Expanded(child: _preview('بعد', c, '$_w×$_h')),
        ]),
        const SizedBox(height: 14),
        SCard(
          title: 'التفاصيل',
          icon: Icons.analytics_rounded,
          color: SD.nile,
          child: Column(children: [
            InfoRow('الحجم الأصلي', fmtBytes(o.length), icon: Icons.image_rounded),
            InfoRow('الحجم بعد الضغط', fmtBytes(c.length), icon: Icons.compress_rounded, valueColor: SD.green),
            InfoRow('المساحة اللي وفرتها', saved > 0 ? fmtBytes(saved) : '—', icon: Icons.savings_rounded),
            InfoRow('نسبة الضغط', saved > 0 ? '1 : ${(o.length / c.length).toStringAsFixed(1)}' : '—', icon: Icons.percent_rounded),
            InfoRow('الأبعاد الأصلية', '$_ow × $_oh (${(_ow * _oh / 1e6).toStringAsFixed(1)} ميغابكسل)', icon: Icons.aspect_ratio_rounded),
            InfoRow('الأبعاد الجديدة', '$_w × $_h (${(_w * _h / 1e6).toStringAsFixed(1)} ميغابكسل)', icon: Icons.photo_size_select_large_rounded),
            InfoRow('الصيغة الناتجة', 'JPEG بجودة ${_q.round()}%', icon: Icons.insert_drive_file_rounded),
            InfoRow('زمن الضغط', '$_ms ملي ثانية', icon: Icons.timer_rounded),
          ]),
        ),
        if (saved > 0)
          SCard(
            title: 'وفّر الباقة 📶',
            icon: Icons.data_saver_on_rounded,
            color: SD.henna,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                const Text('صور برسلها في اليوم'),
                Expanded(child: Slider(value: _perDay, min: 1, max: 50, divisions: 49, label: '${_perDay.round()}', onChanged: (v) => setState(() => _perDay = v))),
                Text('${_perDay.round()}'),
              ]),
              InfoRow('توفير في اليوم', fmtBytes((saved * _perDay).round())),
              InfoRow('توفير في الشهر', '${monthMb.toStringAsFixed(0)} MB', valueColor: SD.green),
              InfoRow('توفير في السنة', '${(monthMb * 12 / 1024).toStringAsFixed(2)} GB'),
              const NoteBox('ده تقدير لو كل صورك بنفس الحجم ده. الواتساب نفسه بيضغط الصور، فالتوفير الحقيقي أوضح في التلغرام والإيميل والرفع للمواقع.', kind: NoteKind.info),
            ]),
          ),
        if (saved <= 0) const NoteBox('الصورة أصلاً مضغوطة كويس. جرّب تقلّل الجودة أو العرض الأقصى.', kind: NoteKind.warn),
        FilledButton.icon(onPressed: _share, icon: const Icon(Icons.ios_share_rounded), label: const Text('احفظ / شارك الصورة المضغوطة')),
        const NoteBox('الصور الشفافة (PNG) بتتحول لـ JPEG وبتفقد الشفافية — ما تستعمل الضغط ده للشعارات.', kind: NoteKind.tip),
      ],
    ]);
  }

  Widget _preview(String label, Uint8List b, String dims) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SD.gold.withValues(alpha: .5)),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => Dialog(child: InteractiveViewer(maxScale: 6, child: Image.memory(b, gaplessPlayback: true))),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(aspectRatio: 1, child: Image.memory(b, fit: BoxFit.cover, gaplessPlayback: true, cacheWidth: 400)),
            ),
          ),
          const SizedBox(height: 4),
          Text('${fmtBytes(b.length)} • $dims', style: const TextStyle(fontSize: 11.5)),
        ]),
      );
}
