import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../core/i18n.dart';
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
      toast(src == ImageSource.camera
          ? t('ما قدرنا نفتح الكاميرا — أتأكد من الإذن', 'تعذّر فتح الكاميرا — تحقّق من الإذن', "Couldn't open the camera — check the permission")
          : t('ما قدرنا نفتح الصورة', 'تعذّر فتح الصورة', "Couldn't open the image"));
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
        toast(t('الصيغة دي ما مدعومة', 'هذه الصيغة غير مدعومة', 'This format is not supported'));
      } else {
        _out = Uint8List.fromList(r['bytes'] as List<int>);
        _w = r['w'];
        _h = r['h'];
        _ow = r['ow'];
        _oh = r['oh'];
      }
    } catch (_) {
      toast(t('حصلت مشكلة في الضغط، جرّب صورة تانية', 'حدثت مشكلة أثناء الضغط، جرّب صورة أخرى', 'Compression failed, try another image'));
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
        title: t('اختار صورة', 'اختر صورة', 'Pick an image'),
        icon: Icons.add_photo_alternate_rounded,
        color: SD.green,
        child: Row(children: [
          Expanded(child: FilledButton.icon(onPressed: () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library_rounded), label: Text(t('من الاستوديو', 'من المعرض', 'From gallery')))),
          const SizedBox(width: 10),
          if (!kIsWeb)
            Expanded(child: OutlinedButton.icon(onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.photo_camera_rounded), label: Text(t('صوّر', 'التقط صورة', 'Camera')))),
        ]),
      ),
      SCard(
        title: tr('إعدادات الضغط', 'Compression settings'),
        icon: Icons.tune_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text(tr('الجودة', 'Quality')),
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
                ? t('جودة عالية — الفرق في الحجم بسيط', 'جودة عالية — الفرق في الحجم بسيط', 'High quality — small size difference')
                : _q >= 60
                    ? t('متوازنة 👌 — مناسبة للواتساب والفيسبوك', 'متوازنة 👌 — مناسبة للواتساب وفيسبوك', 'Balanced 👌 — good for WhatsApp & Facebook')
                    : _q >= 35
                        ? t('موفّرة — ممكن يظهر تشويش خفيف', 'موفّرة — قد يظهر تشويش خفيف', 'Saver — slight artifacts may appear')
                        : t('موفّرة شديد — الجودة بتنزل واضح', 'موفّرة جداً — تنخفض الجودة بوضوح', 'Max saver — noticeable quality loss'),
            style: const TextStyle(fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          Text(tr('أقصى عرض (الضلع الأطول)', 'Max width (longest side)')),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final w in _widths)
              ChoiceChip(
                label: Text(w == 0 ? tr('الأصلي', 'Original') : '$w px'),
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
      if (o == null)
        NoteBox(
            t('اختار صورة وبنضغطها ليك عشان توفّر الباقة والمساحة، والصورة ما بتطلع من جهازك.',
                'اختر صورة وسنضغطها لك لتوفّر الباقة والمساحة، والصورة لا تغادر جهازك.',
                'Pick an image and we\'ll compress it to save data and storage. The image never leaves your device.'),
            kind: NoteKind.tip),
      if (o != null && c != null && !_busy) ...[
        ResultHero(
          label: saved > 0 ? t('وفّرت', 'وفّرت', 'You saved') : t('الحجم ما نقص', 'لم ينقص الحجم', 'No size reduction'),
          value: saved > 0 ? '${pct.toStringAsFixed(0)}%' : '0%',
          sub: '${fmtBytes(o.length)}  ${isEn ? '→' : '←'}  ${fmtBytes(c.length)}',
          colors: const [SD.green, SD.teal, SD.nile],
        ),
        Row(children: [
          Expanded(child: _preview(tr('قبل', 'Before'), o, '$_ow×$_oh')),
          const SizedBox(width: 10),
          Expanded(child: _preview(tr('بعد', 'After'), c, '$_w×$_h')),
        ]),
        const SizedBox(height: 14),
        SCard(
          title: tr('التفاصيل', 'Details'),
          icon: Icons.analytics_rounded,
          color: SD.nile,
          child: Column(children: [
            InfoRow(tr('الحجم الأصلي', 'Original size'), fmtBytes(o.length), icon: Icons.image_rounded),
            InfoRow(tr('الحجم بعد الضغط', 'Compressed size'), fmtBytes(c.length), icon: Icons.compress_rounded, valueColor: SD.green),
            InfoRow(t('المساحة اللي وفرتها', 'المساحة الموفَّرة', 'Space saved'), saved > 0 ? fmtBytes(saved) : '—', icon: Icons.savings_rounded),
            InfoRow(tr('نسبة الضغط', 'Compression ratio'), saved > 0 ? '1 : ${(o.length / c.length).toStringAsFixed(1)}' : '—', icon: Icons.percent_rounded),
            InfoRow(tr('الأبعاد الأصلية', 'Original dimensions'), '$_ow × $_oh (${(_ow * _oh / 1e6).toStringAsFixed(1)} ${tr('ميغابكسل', 'MP')})', icon: Icons.aspect_ratio_rounded),
            InfoRow(tr('الأبعاد الجديدة', 'New dimensions'), '$_w × $_h (${(_w * _h / 1e6).toStringAsFixed(1)} ${tr('ميغابكسل', 'MP')})', icon: Icons.photo_size_select_large_rounded),
            InfoRow(tr('الصيغة الناتجة', 'Output format'), tr('JPEG بجودة ${_q.round()}%', 'JPEG at ${_q.round()}% quality'), icon: Icons.insert_drive_file_rounded),
            InfoRow(tr('زمن الضغط', 'Compression time'), '$_ms ${tr('ملي ثانية', 'ms')}', icon: Icons.timer_rounded),
          ]),
        ),
        if (saved > 0)
          SCard(
            title: t('وفّر الباقة 📶', 'وفّر الباقة 📶', 'Data savings 📶'),
            icon: Icons.data_saver_on_rounded,
            color: SD.henna,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Text(t('صور برسلها في اليوم', 'صور أرسلها يومياً', 'Photos I send per day')),
                Expanded(child: Slider(value: _perDay, min: 1, max: 50, divisions: 49, label: '${_perDay.round()}', onChanged: (v) => setState(() => _perDay = v))),
                Text('${_perDay.round()}'),
              ]),
              InfoRow(tr('توفير في اليوم', 'Saved per day'), fmtBytes((saved * _perDay).round())),
              InfoRow(tr('توفير في الشهر', 'Saved per month'), '${monthMb.toStringAsFixed(0)} MB', valueColor: SD.green),
              InfoRow(tr('توفير في السنة', 'Saved per year'), '${(monthMb * 12 / 1024).toStringAsFixed(2)} GB'),
              NoteBox(
                  t('ده تقدير لو كل صورك بنفس الحجم ده. الواتساب نفسه بيضغط الصور، فالتوفير الحقيقي أوضح في التلغرام والإيميل والرفع للمواقع.',
                      'هذا تقدير لو كانت كل صورك بنفس هذا الحجم. واتساب نفسه يضغط الصور، لذا يظهر التوفير الحقيقي أكثر في تيليغرام والبريد والرفع للمواقع.',
                      'An estimate assuming all your photos are this size. WhatsApp already compresses images, so the real savings show more on Telegram, email and web uploads.'),
                  kind: NoteKind.info),
            ]),
          ),
        if (saved <= 0)
          NoteBox(
              t('الصورة أصلاً مضغوطة كويس. جرّب تقلّل الجودة أو العرض الأقصى.', 'الصورة مضغوطة جيداً أصلاً. جرّب تقليل الجودة أو العرض الأقصى.',
                  'This image is already well compressed. Try lowering the quality or max width.'),
              kind: NoteKind.warn),
        FilledButton.icon(onPressed: _share, icon: const Icon(Icons.ios_share_rounded), label: Text(tr('احفظ / شارك الصورة المضغوطة', 'Save / share compressed image'))),
        NoteBox(
            t('الصور الشفافة (PNG) بتتحول لـ JPEG وبتفقد الشفافية — ما تستعمل الضغط ده للشعارات.',
                'الصور الشفافة (PNG) تتحوّل إلى JPEG وتفقد شفافيتها — لا تستخدم هذا الضغط للشعارات.',
                'Transparent images (PNG) become JPEG and lose transparency — don\'t use this for logos.'),
            kind: NoteKind.tip),
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
