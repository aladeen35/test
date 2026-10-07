import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart' show mapList, intOf, confirmAsk, askText, EmptyHint;
import 'extra_common.dart';

/// يبني ملف PDF من صور (يُشغَّل في isolate عبر compute)
/// args: pages = [[bytes, rot]], size = a4|letter|fit, margin (mm), q (جودة JPEG), max (أقصى بكسل)
Future<Uint8List> buildImagesPdf(Map<String, dynamic> a) async {
  final pages = a['pages'] as List;
  final size = a['size'] as String;
  final m = (a['margin'] as num).toDouble() * PdfPageFormat.mm;
  final q = a['q'] as int;
  final maxPx = a['max'] as int;
  final doc = pw.Document(compress: true, title: a['title'] as String?);
  for (final p in pages) {
    final bytes = (p as List)[0] as Uint8List;
    final rot = p[1] as int;
    var im = img.decodeImage(bytes);
    if (im == null) continue;
    im = img.bakeOrientation(im);
    if (rot % 4 != 0) im = img.copyRotate(im, angle: (rot % 4) * 90);
    final longest = math.max(im.width, im.height);
    if (longest > maxPx) {
      im = im.width >= im.height ? img.copyResize(im, width: maxPx, interpolation: img.Interpolation.average) : img.copyResize(im, height: maxPx, interpolation: img.Interpolation.average);
    }
    final jpg = img.encodeJpg(im, quality: q);
    final mem = pw.MemoryImage(jpg);
    final landscape = im.width > im.height;
    PdfPageFormat fmt;
    if (size == 'fit') {
      // الضلع الأطول = طول A4 تقريبًا
      final scale = PdfPageFormat.a4.height / math.max(im.width, im.height);
      fmt = PdfPageFormat(im.width * scale + 2 * m, im.height * scale + 2 * m);
    } else {
      final base = size == 'letter' ? PdfPageFormat.letter : PdfPageFormat.a4;
      fmt = landscape ? base.landscape : base;
    }
    doc.addPage(pw.Page(
      pageFormat: fmt,
      margin: pw.EdgeInsets.all(m),
      build: (_) => pw.Center(child: pw.Image(mem, fit: pw.BoxFit.contain)),
    ));
  }
  return doc.save();
}

class _Pg {
  final int id;
  final Uint8List bytes;
  int rot = 0;
  _Pg(this.id, this.bytes);
}

class ImgPdfTool extends StatefulWidget {
  const ImgPdfTool({super.key});
  @override
  State<ImgPdfTool> createState() => _ImgPdfToolState();
}

class _ImgPdfToolState extends State<ImgPdfTool> {
  final List<_Pg> _pages = [];
  int _seq = 0;
  String _size = 'a4';
  double _margin = 10;
  double _quality = 80;
  bool _busy = false;
  final _nameC = TextEditingController();

  @override
  void dispose() {
    _nameC.dispose();
    super.dispose();
  }

  Future<void> _pick(bool camera) async {
    try {
      final picker = ImagePicker();
      final files = camera
          ? [?await picker.pickImage(source: ImageSource.camera, maxWidth: 2600, maxHeight: 2600, imageQuality: 92)]
          : await picker.pickMultiImage(maxWidth: 2600, maxHeight: 2600, imageQuality: 92);
      if (files.isEmpty) return;
      final added = <_Pg>[];
      for (final f in files) {
        added.add(_Pg(_seq++, await f.readAsBytes()));
      }
      if (!mounted) return;
      setState(() => _pages.addAll(added));
    } catch (e) {
      toast(t('ما قدرنا نجيب الصور', 'تعذّر جلب الصور', 'Could not load the images'));
    }
  }

  String _safeName(String s) {
    final n = s.trim().replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t]'), '_');
    return n.isEmpty ? 'scan_${DateTime.now().millisecondsSinceEpoch ~/ 1000}' : n;
  }

  Future<void> _make() async {
    if (_pages.isEmpty || _busy) return;
    final s = context.read<AppState>();
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final base = _safeName(_nameC.text.isEmpty ? '${tr('مستند', 'Document')} ${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}${two(now.minute)}' : _nameC.text);
      final bytes = await compute(buildImagesPdf, {
        'pages': [for (final p in _pages) [p.bytes, p.rot]],
        'size': _size,
        'margin': _margin,
        'q': _quality.round(),
        'max': _quality >= 85 ? 2400 : (_quality >= 60 ? 1800 : 1300),
        'title': base,
      });
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/pdfs');
      await dir.create(recursive: true);
      var path = '${dir.path}/$base.pdf';
      var i = 2;
      while (await File(path).exists()) {
        path = '${dir.path}/$base ($i).pdf';
        i++;
      }
      await File(path).writeAsBytes(bytes, flush: true);
      final list = mapList(s.getData<List>('img_pdf_files'));
      list.insert(0, {'name': path.split('/').last, 'path': path, 'pages': _pages.length, 'size': bytes.length, 't': now.millisecondsSinceEpoch});
      s.setData('img_pdf_files', list.take(60).toList());
      s.awardDaily('img_pdf', 4, tr('الصور إلى PDF', 'Images to PDF'));
      s.bump('pdfs_made');
      if (!mounted) return;
      setState(() {
        _pages.clear();
        _nameC.clear();
      });
      toast('${t('الملف جاهز', 'تم إنشاء الملف', 'PDF ready')} ✓ ${fmtBytes(bytes.length)}', icon: Icons.picture_as_pdf_rounded);
      await _shareFile(path);
    } catch (e) {
      toast(t('حصلت مشكلة في عمل الملف', 'حدث خطأ أثناء إنشاء الملف', 'Something went wrong creating the PDF'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareFile(String path) async {
    try {
      if (!await File(path).exists()) {
        return toast(t('الملف ما موجود', 'الملف غير موجود', 'File not found'));
      }
      await SharePlus.instance.share(ShareParams(files: [XFile(path, mimeType: 'application/pdf')]));
    } catch (_) {
      toast(t('ما قدرنا نشارك الملف', 'تعذرت المشاركة', 'Could not share the file'));
    }
  }

  Future<void> _rename(Map<String, dynamic> e) async {
    final s = context.read<AppState>();
    final old = '${e['name']}'.replaceAll(RegExp(r'\.pdf$'), '');
    final v = await askText(context, t('اسم الملف', 'اسم الملف', 'File name'), initial: old);
    if (v == null || v.trim().isEmpty || v.trim() == old) return;
    try {
      final f = File('${e['path']}');
      final np = '${f.parent.path}/${_safeName(v)}.pdf';
      if (await File(np).exists()) return toast(t('في ملف بنفس الاسم', 'يوجد ملف بالاسم نفسه', 'A file with that name exists'));
      await f.rename(np);
      final l = mapList(s.getData<List>('img_pdf_files'));
      final i = l.indexWhere((x) => x['path'] == e['path']);
      if (i >= 0) l[i] = {...l[i], 'path': np, 'name': np.split('/').last};
      s.setData('img_pdf_files', l);
    } catch (_) {
      toast(t('ما قدرنا نغيّر الاسم', 'تعذّرت إعادة التسمية', 'Rename failed'));
    }
  }

  Future<void> _delete(Map<String, dynamic> e) async {
    final s = context.read<AppState>();
    if (!await confirmAsk(context, t('نمسح الملف؟', 'حذف الملف؟', 'Delete file?'), '${e['name']}')) return;
    try {
      final f = File('${e['path']}');
      if (await f.exists()) await f.delete();
    } catch (_) {}
    s.setData('img_pdf_files', mapList(s.getData<List>('img_pdf_files'))..removeWhere((x) => x['path'] == e['path']));
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return ToolList(children: [
        NoteBox(t('الأداة دي شغّالة في تطبيق الموبايل بس (أندرويد/آيفون).', 'هذه الأداة متاحة في تطبيق الجوال فقط (أندرويد/آيفون).', 'This tool works in the mobile app only (Android/iOS).'), kind: NoteKind.warn),
      ]);
    }
    final s = context.watch<AppState>();
    final files = mapList(s.getData<List>('img_pdf_files'));
    final totalSize = files.fold(0, (a, e) => a + intOf(e['size']));
    return ToolList(children: [
      Row(children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _busy ? null : () => _pick(false),
            icon: const Icon(Icons.photo_library_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('من الصور', 'من المعرض', 'Gallery'))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy ? null : () => _pick(true),
            icon: const Icon(Icons.photo_camera_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('صوّر', 'الكاميرا', 'Camera'))),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      SCard(
        title: t('الصفحات', 'الصفحات', 'Pages'),
        icon: Icons.collections_rounded,
        color: SD.henna,
        trailing: _pages.isEmpty
            ? null
            : IconButton(
                tooltip: t('امسح الكل', 'مسح الكل', 'Clear all'),
                onPressed: _busy ? null : () => setState(_pages.clear),
                icon: const Icon(Icons.delete_sweep_rounded),
              ),
        child: _pages.isEmpty
            ? EmptyHint(Icons.add_photo_alternate_outlined,
                t('اختار صور (ورق، فواتير، شهادات…) وحوّلها لملف PDF واحد', 'اختر صورًا (أوراق، فواتير، شهادات…) وحوّلها إلى ملف PDF واحد', 'Pick photos (papers, receipts, certificates…) and turn them into one PDF'))
            : ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorderItem: (from, to) => setState(() => _pages.insert(to, _pages.removeAt(from))),
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    Padding(
                      key: ValueKey(_pages[i].id),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.drag_indicator_rounded)),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: RotatedBox(
                              quarterTurns: _pages[i].rot,
                              child: Image.memory(_pages[i].bytes, fit: BoxFit.cover, cacheWidth: 160, gaplessPlayback: true,
                                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image_rounded)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('${t('صفحة', 'صفحة', 'Page')} ${i + 1}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                        IconButton(
                          tooltip: t('لفّ', 'تدوير', 'Rotate'),
                          onPressed: () => setState(() => _pages[i].rot = (_pages[i].rot + 1) % 4),
                          icon: const Icon(Icons.rotate_90_degrees_cw_rounded),
                        ),
                        IconButton(
                          tooltip: t('شيل', 'حذف', 'Remove'),
                          onPressed: () => setState(() => _pages.removeAt(i)),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ]),
                    ),
                ],
              ),
      ),
      if (_pages.length > 1)
        NoteBox(t('اسحب من المقبض ⠿ عشان ترتّب الصفحات', 'اسحب من المقبض ⠿ لإعادة ترتيب الصفحات', 'Drag the ⠿ handle to reorder pages'), kind: NoteKind.tip),
      SCard(
        title: t('الإعدادات', 'الإعدادات', 'Settings'),
        icon: Icons.tune_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t('مقاس الصفحة', 'مقاس الصفحة', 'Page size'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          XSeg<String>([('a4', 'A4'), ('letter', 'Letter'), ('fit', t('قدر الصورة', 'بحجم الصورة', 'Fit image'))], _size, (v) => setState(() => _size = v)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text(t('الهوامش', 'الهوامش', 'Margins'), style: const TextStyle(fontWeight: FontWeight.w700))),
            Text('${_margin.round()} mm'),
          ]),
          Slider(value: _margin, min: 0, max: 30, divisions: 6, onChanged: (v) => setState(() => _margin = v)),
          Row(children: [
            Expanded(child: Text(t('الجودة (أقل = ملف أصغر)', 'الجودة (أقل = ملف أصغر)', 'Quality (lower = smaller file)'), style: const TextStyle(fontWeight: FontWeight.w700))),
            Text('${_quality.round()}%'),
          ]),
          Slider(value: _quality, min: 30, max: 95, divisions: 13, onChanged: (v) => setState(() => _quality = v)),
          TextField(
            controller: _nameC,
            decoration: InputDecoration(labelText: t('اسم الملف (اختياري)', 'اسم الملف (اختياري)', 'File name (optional)'), suffixText: '.pdf'),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _pages.isEmpty || _busy ? null : _make,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4))
                : const Icon(Icons.picture_as_pdf_rounded),
            label: Text(_busy
                ? t('بنجهّز في الملف…', 'جارٍ الإنشاء…', 'Creating…')
                : '${t('اعمل PDF', 'إنشاء PDF', 'Create PDF')}${_pages.isEmpty ? '' : ' (${_pages.length})'}'),
          ),
        ]),
      ),
      SCard(
        title: t('ملفاتي', 'ملفاتي', 'My PDFs'),
        icon: Icons.folder_rounded,
        color: SD.gold,
        trailing: files.isEmpty ? null : XBadge('${files.length} • ${fmtBytes(totalSize)}'),
        child: files.isEmpty
            ? EmptyHint(Icons.picture_as_pdf_outlined, t('لسه ما عملت ملفات', 'لا توجد ملفات بعد', 'No PDFs yet'))
            : Column(children: [
                for (final e in files)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.picture_as_pdf_rounded, color: SD.red),
                    title: Text('${e['name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${intOf(e['pages'])} ${t('صفحة', 'صفحة', 'pages')} • ${fmtBytes(intOf(e['size']))} • ${fmtDateAr(DateTime.fromMillisecondsSinceEpoch(intOf(e['t'])), weekday: false)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) => switch (v) {
                        'share' => _shareFile('${e['path']}'),
                        'rename' => _rename(e),
                        _ => _delete(e),
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'share', child: Text(t('شارك / افتح', 'مشاركة / فتح', 'Share / open'))),
                        PopupMenuItem(value: 'rename', child: Text(t('غيّر الاسم', 'إعادة تسمية', 'Rename'))),
                        PopupMenuItem(value: 'del', child: Text(t('امسح', 'حذف', 'Delete'))),
                      ],
                    ),
                    onTap: () => _shareFile('${e['path']}'),
                  ),
              ]),
      ),
      NoteBox(t('الملفات بتتحفظ جوه التطبيق — شاركها لواتساب أو احفظها في ملفاتك من زر المشاركة.', 'تُحفظ الملفات داخل التطبيق — شاركها عبر واتساب أو احفظها في ملفاتك من زر المشاركة.',
          'PDFs are stored inside the app — use Share to send them on WhatsApp or save them to your files.')),
    ]);
  }
}
