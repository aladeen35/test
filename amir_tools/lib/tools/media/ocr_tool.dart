import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// لغات التعرّف: ملفات tessdata_fast تُنزَّل مرة واحدة عند أول استخدام (لا تُضمَّن في التطبيق لتقليل الحجم)
const _langFiles = {'ara': 'ara.traineddata', 'eng': 'eng.traineddata'};
const _tessBase = 'https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/main/';

/// تجهيز الصورة: تدرّج رمادي، تكبير الصور الصغيرة، تحسين التباين — يرفع دقة التعرّف
Future<String> _prepare(String path) async {
  final bytes = await File(path).readAsBytes();
  final out = await compute((Uint8List b) {
    var im = img.decodeImage(b);
    if (im == null) return b;
    im = img.bakeOrientation(im);
    if (im.width < 1200) im = img.copyResize(im, width: 1600, interpolation: img.Interpolation.cubic);
    if (im.width > 3000) im = img.copyResize(im, width: 2600);
    im = img.grayscale(im);
    im = img.adjustColor(im, contrast: 1.25);
    return Uint8List.fromList(img.encodePng(im));
  }, bytes);
  final f = File('${(await getTemporaryDirectory()).path}/ocr_${DateTime.now().millisecondsSinceEpoch}.png');
  await f.writeAsBytes(out);
  return f.path;
}

/// استخراج النص من الصور (OCR) بالعربي والإنجليزي — يعمل على الجهاز دون رفع الصور لأي خادم
class OcrTool extends StatefulWidget {
  const OcrTool({super.key});
  @override
  State<OcrTool> createState() => _OcrToolState();
}

class _OcrToolState extends State<OcrTool> {
  String _lang = 'ara+eng';
  String? _imagePath;
  final _text = TextEditingController();
  bool _busy = false;
  String _status = '';
  double? _progress;
  Duration? _took;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _supported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// يتأكد من وجود ملفات اللغة المطلوبة وينزّل الناقص منها
  Future<bool> _ensureLangs() async {
    final dir = Directory(await FlutterTesseractOcr.getTessdataPath());
    if (!await dir.exists()) await dir.create(recursive: true);
    for (final code in _lang.split('+')) {
      final f = File('${dir.path}/${_langFiles[code]}');
      if (await f.exists() && await f.length() > 100000) continue;
      setState(() {
        _status = t('بننزّل ملف لغة ${code == 'ara' ? 'العربي' : 'الإنجليزي'} (مرة واحدة بس)…', 'جارٍ تنزيل ملف اللغة ${code == 'ara' ? 'العربية' : 'الإنجليزية'} (مرة واحدة فقط)…',
            'Downloading ${code == 'ara' ? 'Arabic' : 'English'} language data (one time only)…');
        _progress = 0;
      });
      try {
        final req = await http.Client().send(http.Request('GET', Uri.parse('$_tessBase${_langFiles[code]}')));
        if (req.statusCode != 200) throw Exception('HTTP ${req.statusCode}');
        final total = req.contentLength ?? 0;
        final sink = f.openWrite();
        var got = 0;
        await for (final chunk in req.stream) {
          sink.add(chunk);
          got += chunk.length;
          if (total > 0 && mounted) setState(() => _progress = got / total);
        }
        await sink.close();
      } catch (_) {
        if (await f.exists()) await f.delete();
        if (mounted) {
          setState(() {
            _status = t('ما قدرنا ننزّل ملف اللغة — محتاج نت أول مرة بس.', 'تعذّر تنزيل ملف اللغة — يلزم اتصال بالإنترنت في المرة الأولى فقط.',
                "Couldn't download the language data — internet is needed the first time only.");
            _progress = null;
          });
        }
        return false;
      }
    }
    setState(() => _progress = null);
    return true;
  }

  Future<void> _pick(ImageSource src) async {
    if (!_supported) return toast(t('استخراج النص شغّال في تطبيق الموبايل بس', 'استخراج النص متاح في تطبيق الجوال فقط', 'Text extraction works in the mobile app only'));
    try {
      final x = await ImagePicker().pickImage(source: src, requestFullMetadata: false);
      if (x == null) return;
      setState(() => _imagePath = x.path);
      await _run();
    } catch (_) {
      toast(t('ما قدرنا نفتح الصورة', 'تعذّر فتح الصورة', "Couldn't open the image"));
    }
  }

  Future<void> _run() async {
    if (_imagePath == null || _busy) return;
    setState(() {
      _busy = true;
      _took = null;
    });
    final sw = Stopwatch()..start();
    try {
      if (!await _ensureLangs()) return;
      setState(() => _status = t('بنقرا النص…', 'جارٍ قراءة النص…', 'Reading text…'));
      final prepared = await _prepare(_imagePath!);
      final text = await FlutterTesseractOcr.extractText(prepared, language: _lang, args: {'psm': '3', 'preserve_interword_spaces': '1'});
      _text.text = text.trim();
      sw.stop();
      if (!mounted) return;
      setState(() {
        _took = sw.elapsed;
        _status = _text.text.isEmpty
            ? t('ما لقينا نص واضح — جرّب صورة أوضح وإضاءة أحسن', 'لم يُعثر على نص واضح — جرّب صورة أوضح وإضاءة أفضل', 'No clear text found — try a sharper, better-lit photo')
            : t('تمام ✓', 'تم ✓', 'Done ✓');
      });
      if (_text.text.isNotEmpty) context.read<AppState>().awardDaily('ocr', 5, tr('استخراج نص من صورة', 'Extracted text from image'));
    } catch (e) {
      if (mounted) setState(() => _status = t('حصلت مشكلة في القراءة', 'حدثت مشكلة أثناء القراءة', 'Something went wrong while reading'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = RegExp(r'\S+').allMatches(_text.text).length;
    return ToolList(children: [
      if (!_supported)
        NoteBox(t('الأداة دي شغّالة في تطبيق الموبايل (أندرويد وآيفون) بس.', 'هذه الأداة تعمل في تطبيق الجوال (أندرويد وآيفون) فقط.', 'This tool works in the mobile app (Android & iPhone) only.'),
            kind: NoteKind.warn),
      SCard(
        title: t('لغة النص', 'لغة النص', 'Text language'),
        icon: Icons.translate_rounded,
        color: SD.teal,
        child: SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 'ara', label: FittedBox(fit: BoxFit.scaleDown, child: Text(tr('عربي', 'Arabic')))),
            ButtonSegment(value: 'eng', label: FittedBox(fit: BoxFit.scaleDown, child: Text(tr('إنجليزي', 'English')))),
            ButtonSegment(value: 'ara+eng', label: FittedBox(fit: BoxFit.scaleDown, child: Text(tr('الاتنين', 'Both')))),
          ],
          selected: {_lang},
          onSelectionChanged: (v) {
            setState(() => _lang = v.first);
            if (_imagePath != null) _run();
          },
        ),
      ),
      Row(children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _busy ? null : () => _pick(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('صوّر', 'التقاط صورة', 'Camera'))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy ? null : () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('من المعرض', 'من المعرض', 'Gallery'))),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      if (_imagePath != null && !kIsWeb)
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(border: Border.all(color: SD.gold)),
            child: Image.file(File(_imagePath!), fit: BoxFit.contain, width: double.infinity),
          ),
        ),
      if (_busy || _status.isNotEmpty) ...[
        const SizedBox(height: 10),
        if (_busy) LinearProgressIndicator(value: _progress),
        Padding(padding: const EdgeInsets.all(8), child: Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
      ],
      SCard(
        title: t('النص المستخرج', 'النص المستخرج', 'Extracted text'),
        icon: Icons.text_snippet_rounded,
        color: SD.gold,
        trailing: _took == null ? null : Text('${fmt(_took!.inMilliseconds / 1000, 1)} ${tr('ث', 's')}', style: const TextStyle(fontSize: 12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _text,
            minLines: 6,
            maxLines: 18,
            onChanged: (_) => setState(() {}),
            textDirection: _lang == 'eng' ? TextDirection.ltr : TextDirection.rtl,
            decoration: InputDecoration(hintText: t('النص حيظهر هنا وتقدر تعدّلو', 'سيظهر النص هنا ويمكنك تعديله', 'Text appears here — you can edit it')),
          ),
          const SizedBox(height: 8),
          Text('${tr('الكلمات', 'Words')}: $words • ${tr('الأحرف', 'Characters')}: ${_text.text.length}', style: const TextStyle(fontSize: 12.5)),
          const SizedBox(height: 10),
          ShareBar(() => _text.text),
        ]),
      ),
      NoteBox(
          t('للنتيجة الأحسن: صوّر الورقة مستقيمة وفي إضاءة كويسة، وخلي الكلام واضح وكبير. الخط اليدوي صعب يتقري.',
              'لأفضل نتيجة: صوّر الورقة مستقيمة وفي إضاءة جيدة، واجعل الكتابة واضحة وكبيرة. الخط اليدوي صعب القراءة.',
              'For best results: shoot the page straight, in good light, with large clear text. Handwriting is hard to read.'),
          kind: NoteKind.tip),
      NoteBox(
          t('الصور بتتقري في تلفونك بس وما بترسل لأي مكان. ملفات اللغة بتتنزّل مرة واحدة (حوالي 1–4 ميغا).',
              'تُقرأ الصور على هاتفك فقط ولا تُرسل إلى أي مكان. تُنزَّل ملفات اللغة مرة واحدة (نحو 1–4 ميغابايت).',
              'Images are processed on your phone only and never uploaded. Language data downloads once (about 1–4 MB).'),
          kind: NoteKind.info),
    ]);
  }
}
