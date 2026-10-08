import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart' show PickChip, EmptyHint, confirmAsk, askText, lifeSheet, newId, mapList;
import 'cv_model.dart';
import 'cv_pdf.dart';
import 'know_common.dart' show hasArabic;

/// أقسام المحرّر
const _sections = ['info', 'objective', 'exp', 'edu', 'skills', 'langs', 'certs', 'refs'];

String _secName(String k) => switch (k) {
      'info' => t('بياناتك', 'البيانات الشخصية', 'Personal info'),
      'objective' => t('الملخص', 'الملخص المهني', 'Summary'),
      'exp' => t('الخبرات', 'الخبرات', 'Experience'),
      'edu' => t('القراية', 'التعليم', 'Education'),
      'skills' => t('المهارات', 'المهارات', 'Skills'),
      'langs' => t('اللغات', 'اللغات', 'Languages'),
      'certs' => t('الشهادات', 'الشهادات', 'Certificates'),
      'refs' => t('المعرّفين', 'المعرّفون', 'References'),
      _ => k,
    };

IconData _secIcon(String k) => switch (k) {
      'info' => Icons.person_rounded,
      'objective' => Icons.short_text_rounded,
      'exp' => Icons.work_history_rounded,
      'edu' => Icons.school_rounded,
      'skills' => Icons.construction_rounded,
      'langs' => Icons.translate_rounded,
      'certs' => Icons.workspace_premium_rounded,
      'refs' => Icons.contacts_rounded,
      _ => Icons.circle,
    };

String _secTip(String k) => switch (k) {
      'info' => t('اكتب اسمك زي الجواز بالضبط، وإيميل محترم (اسمك.لقبك). صورة شخصية ما ضرورية إلا لو الوظيفة طلبتها.',
          'اكتب اسمك كما في الجواز، واستخدم بريدًا مهنيًا (الاسم.اللقب). الصورة الشخصية غير ضرورية إلا إذا طلبتها الوظيفة.',
          'Write your name exactly as in your passport and use a professional email. A photo is only needed if the employer asks.'),
      'objective' => t('سطرين لتلاتة: إنت منو، كم سنة خبرة، وشنو البتقدمو للشركة. غيّرو حسب كل وظيفة.',
          'سطران إلى ثلاثة: من أنت، وكم سنة خبرة، وما الذي تضيفه للجهة. عدّله حسب كل وظيفة.',
          '2–3 lines: who you are, years of experience and what you bring. Tailor it for each job.'),
      'exp' => t('ابدأ بالأحدث. اكتب إنجازات بأرقام (زوّدت المبيعات 20%) بدل مهام عامة. سطر لكل نقطة.',
          'ابدأ بالأحدث. اكتب إنجازات بالأرقام (رفعت المبيعات 20%) بدل المهام العامة. سطر لكل نقطة.',
          'Newest first. Use measurable achievements ("raised sales 20%") rather than duties. One line per point.'),
      'edu' => t('أعلى مؤهل أول. الثانوي ما ضروري لو عندك جامعة.', 'ابدأ بأعلى مؤهل. لا داعي للثانوية إن كان لديك مؤهل جامعي.',
          'Highest degree first. Skip high school if you have a university degree.'),
      'skills' => t('ركّز على مهارات الوظيفة المطلوبة (برامج، أجهزة، رخص). 6–10 مهارات كفاية.',
          'ركّز على مهارات الوظيفة المطلوبة (برامج، أجهزة، رخص). تكفي 6–10 مهارات.',
          'Focus on skills the job asks for (software, equipment, licences). 6–10 is plenty.'),
      'langs' => t('كن صادق في المستوى؛ ممكن يختبروك في المقابلة.', 'كن صادقًا في المستوى؛ قد تُختبر في المقابلة.',
          'Be honest about your level — it may be tested in the interview.'),
      'certs' => t('الدورات المعتمدة والرخص المهنية بس، مع سنة الحصول.', 'الدورات المعتمدة والرخص المهنية فقط مع سنة الحصول.',
          'Accredited courses and professional licences only, with the year.'),
      'refs' => t('استأذن المعرّف قبل ما تكتب رقمو. أو اختار «عند الطلب».', 'استأذن المعرّف قبل كتابة رقمه، أو اختر «عند الطلب».',
          'Ask your referees first before listing their contact, or choose "on request".'),
      _ => '',
    };

/// حقول عناصر القوائم: (المفتاح، العنوان، متعدد الأسطر)
List<(String, String, bool)> _fields(String sec) => switch (sec) {
      'exp' => [
          ('title', t('المسمى الوظيفي', 'المسمى الوظيفي', 'Job title'), false),
          ('org', t('الشركة / الجهة', 'جهة العمل', 'Company / employer'), false),
          ('place', t('المدينة والبلد', 'المدينة والدولة', 'City & country'), false),
          ('from', t('من (مثلًا 2019)', 'من (مثلًا 2019)', 'From (e.g. 2019)'), false),
          ('to', t('لحدي (أو «حتى الآن»)', 'إلى (أو «حتى الآن»)', 'To (or "Present")'), false),
          ('desc', t('المهام والإنجازات — سطر لكل نقطة', 'المهام والإنجازات — سطر لكل نقطة', 'Duties & achievements — one per line'), true),
        ],
      'edu' => [
          ('degree', t('المؤهل (بكالوريوس محاسبة…)', 'المؤهل (بكالوريوس محاسبة…)', 'Degree (BSc Accounting…)'), false),
          ('school', t('الجامعة / المعهد', 'الجامعة / المعهد', 'University / institute'), false),
          ('year', t('سنة التخرج', 'سنة التخرج', 'Graduation year'), false),
          ('note', t('التقدير أو ملاحظة', 'التقدير أو ملاحظة', 'Grade or note'), false),
        ],
      'skills' => [('n', t('المهارة', 'المهارة', 'Skill'), false)],
      'langs' => [('n', t('اللغة', 'اللغة', 'Language'), false)],
      'certs' => [
          ('n', t('اسم الشهادة / الدورة', 'اسم الشهادة / الدورة', 'Certificate / course'), false),
          ('org', t('الجهة المانحة', 'الجهة المانحة', 'Issuer'), false),
          ('year', t('السنة', 'السنة', 'Year'), false),
        ],
      'refs' => [
          ('n', t('الاسم', 'الاسم', 'Name'), false),
          ('role', t('الوظيفة والجهة', 'الوظيفة والجهة', 'Role & organisation'), false),
          ('contact', t('الرقم أو الإيميل', 'الهاتف أو البريد', 'Phone or email'), false),
        ],
      _ => const [],
    };

String _itemTitle(String sec, Map m) => switch (sec) {
      'exp' => itemStr(m, 'title'),
      'edu' => itemStr(m, 'degree'),
      _ => itemStr(m, 'n'),
    };

String _itemSub(String sec, Map m) => switch (sec) {
      'exp' => [itemStr(m, 'org'), cvPeriod(m)].where((x) => x.isNotEmpty).join(' · '),
      'edu' => [itemStr(m, 'school'), itemStr(m, 'year')].where((x) => x.isNotEmpty).join(' · '),
      'skills' => '${'★' * itemLvl(m)}${'☆' * (5 - itemLvl(m))}',
      'langs' => langLevelUi(itemLvl(m)),
      'certs' => [itemStr(m, 'org'), itemStr(m, 'year')].where((x) => x.isNotEmpty).join(' · '),
      'refs' => [itemStr(m, 'role'), itemStr(m, 'contact')].where((x) => x.isNotEmpty).join(' · '),
      _ => '',
    };

Map<String, dynamic> newCv(String title) => {
      'id': newId(),
      'title': title,
      'lang': isEn ? 'en' : 'ar',
      'tpl': 'modern',
      'updated': DateTime.now().millisecondsSinceEpoch,
    };

class CvTool extends StatefulWidget {
  const CvTool({super.key});
  @override
  State<CvTool> createState() => _CvToolState();
}

class _CvToolState extends State<CvTool> {
  String _sec = 'info';
  bool _busy = false;

  List<Map<String, dynamic>> _all(AppState s) => mapList(s.getData<List>('cv_builder_list'));

  Map<String, dynamic>? _current(AppState s, List<Map<String, dynamic>> all) {
    if (all.isEmpty) return null;
    final id = s.getData<String>('cv_builder_current');
    return all.firstWhere((c) => c['id'] == id, orElse: () => all.first);
  }

  void _save(AppState s, Map<String, dynamic> cv) {
    final all = _all(s);
    cv['updated'] = DateTime.now().millisecondsSinceEpoch;
    final i = all.indexWhere((c) => c['id'] == cv['id']);
    if (i < 0) {
      all.insert(0, cv);
    } else {
      all[i] = cv;
    }
    s.setData('cv_builder_list', all);
  }

  void _create(AppState s, {Map<String, dynamic>? from}) {
    final all = _all(s);
    final cv = from == null
        ? newCv('${t('سيرتي', 'سيرتي', 'My CV')} ${all.length + 1}')
        : (Map<String, dynamic>.from(from)
          ..['id'] = newId()
          ..['title'] = '${from['title']} (${t('نسخة', 'نسخة', 'copy')})'
          ..remove('pdf'));
    all.insert(0, cv);
    s.setData('cv_builder_list', all);
    s.setData('cv_builder_current', cv['id']);
    setState(() => _sec = 'info');
    if (from == null) s.awardDaily('cv_builder_new', 3, tr('بدء سيرة ذاتية', 'Started a CV'));
  }

  Future<void> _rename(AppState s, Map<String, dynamic> cv) async {
    final v = await askText(context, t('اسم السيرة (ليك إنت بس)', 'اسم السيرة (للتمييز فقط)', 'CV name (just for you)'), initial: '${cv['title'] ?? ''}');
    if (v == null || v.trim().isEmpty) return;
    _save(s, cv..['title'] = v.trim());
  }

  Future<void> _delete(AppState s, Map<String, dynamic> cv) async {
    if (!await confirmAsk(context, t('نمسح السيرة دي؟', 'حذف هذه السيرة؟', 'Delete this CV?'), '${cv['title']}', ok: t('امسح', 'حذف', 'Delete'))) return;
    final all = _all(s)..removeWhere((c) => c['id'] == cv['id']);
    s.setData('cv_builder_list', all);
    s.setData('cv_builder_current', all.isEmpty ? null : all.first['id']);
  }

  Future<void> _editItem(AppState s, Map<String, dynamic> cv, String sec, [int? index]) async {
    final items = cvList(cv, sec);
    final item = index == null ? <String, dynamic>{'lvl': sec == 'langs' ? 3 : 4} : Map<String, dynamic>.from(items[index]);
    final fields = _fields(sec);
    final ctrls = {for (final f in fields) f.$1: TextEditingController(text: itemStr(item, f.$1))};
    var lvl = itemLvl(item);
    final ok = await lifeSheet<bool>(
      context,
      '${index == null ? t('ضيف', 'إضافة', 'Add') : t('عدّل', 'تعديل', 'Edit')}: ${_secName(sec)}',
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final f in fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: ctrls[f.$1],
              minLines: f.$3 ? 3 : 1,
              maxLines: f.$3 ? 8 : 1,
              textInputAction: f.$3 ? TextInputAction.newline : TextInputAction.next,
              decoration: InputDecoration(labelText: f.$2),
            ),
          ),
        if (sec == 'skills' || sec == 'langs') ...[
          Text(
            '${t('المستوى', 'المستوى', 'Level')}: ${sec == 'langs' ? langLevelUi(lvl) : '$lvl / 5'}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Slider(value: lvl.toDouble(), min: 1, max: 5, divisions: 4, label: '$lvl', onChanged: (v) => set(() => lvl = v.round())),
        ],
        const SizedBox(height: 6),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.check_rounded),
          label: Text(t('حفظ', 'حفظ', 'Save')),
        ),
      ]),
    );
    if (ok == true) {
      for (final f in fields) {
        item[f.$1] = ctrls[f.$1]!.text.trim();
      }
      if (sec == 'skills' || sec == 'langs') item['lvl'] = lvl;
      final hasContent = fields.any((f) => itemStr(item, f.$1).isNotEmpty);
      if (hasContent) {
        if (index == null) {
          items.add(item);
        } else {
          items[index] = item;
        }
        _save(s, cv..[sec] = items);
      }
    }
    for (final c in ctrls.values) {
      c.dispose();
    }
  }

  void _move(AppState s, Map<String, dynamic> cv, String sec, int i, int d) {
    final items = cvList(cv, sec);
    final j = i + d;
    if (j < 0 || j >= items.length) return;
    final x = items.removeAt(i);
    items.insert(j, x);
    _save(s, cv..[sec] = items);
  }

  void _removeItem(AppState s, Map<String, dynamic> cv, String sec, int i) {
    final items = cvList(cv, sec)..removeAt(i);
    _save(s, cv..[sec] = items);
  }

  String _safeName(String s) {
    final n = s.replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return n.isEmpty ? 'CV' : (n.length > 60 ? n.substring(0, 60) : n);
  }

  Future<void> _exportPdf(AppState s, Map<String, dynamic> cv) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final reg = pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
      final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Bold.ttf'));
      final bytes = await buildCvPdf(cv, reg, bold);
      final base = _safeName('CV - ${cvStr(cv, 'name').isEmpty ? '${cv['title']}' : cvStr(cv, 'name')}${cvRtl(cv) ? ' (AR)' : ' (EN)'}');
      s.awardDaily('cv_builder_pdf', 6, tr('تصدير سيرة ذاتية PDF', 'Exported a CV as PDF'));
      s.bump('pdfs_made');
      if (kIsWeb) {
        await SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, name: '$base.pdf', mimeType: 'application/pdf')]));
        return;
      }
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/documents/cvs');
      await dir.create(recursive: true);
      final path = '${dir.path}/$base.pdf';
      await File(path).writeAsBytes(bytes, flush: true);
      _save(s, cv..['pdf'] = {'path': path, 'size': bytes.length, 't': DateTime.now().millisecondsSinceEpoch});
      toast('${t('السيرة جاهزة', 'تم إنشاء السيرة', 'CV ready')} ✓ ${fmtBytes(bytes.length)}', icon: Icons.picture_as_pdf_rounded);
      await SharePlus.instance.share(ShareParams(files: [XFile(path, mimeType: 'application/pdf')], text: cvStr(cv, 'name')));
    } catch (e) {
      toast(t('حصلت مشكلة في عمل الـ PDF', 'حدث خطأ أثناء إنشاء ملف PDF', 'Something went wrong creating the PDF'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareSaved(Map<String, dynamic> cv) async {
    final p = cv['pdf'];
    if (p is! Map) return;
    try {
      final path = '${p['path']}';
      if (!await File(path).exists()) return toast(t('الملف ما موجود — صدّرو تاني', 'الملف غير موجود — أعد التصدير', 'File not found — export again'));
      await SharePlus.instance.share(ShareParams(files: [XFile(path, mimeType: 'application/pdf')]));
    } catch (_) {
      toast(t('ما قدرنا نشارك الملف', 'تعذرت المشاركة', 'Could not share the file'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = _all(s);
    final cv = _current(s, all);

    if (cv == null) {
      return ToolList(children: [
        EmptyHint(
          Icons.description_rounded,
          t('اعمل سيرتك الذاتية بالعربي أو الإنجليزي، وطلّعها PDF جاهزة للتقديم.', 'أنشئ سيرتك الذاتية بالعربية أو الإنجليزية وصدّرها PDF جاهزًا للتقديم.',
              'Build your CV in Arabic or English and export a ready-to-send PDF.'),
          action: FilledButton.icon(onPressed: () => _create(s), icon: const Icon(Icons.add_rounded), label: Text(t('سيرة جديدة', 'سيرة جديدة', 'New CV'))),
        ),
        NoteBox(_secTip('objective'), kind: NoteKind.tip),
      ]);
    }

    final (pct, missing) = cvCompleteness(cv);
    final pdf = cv['pdf'];

    return ToolList(children: [
      // ── السير المحفوظة ──
      SCard(
        title: t('سيرك المحفوظة', 'السير المحفوظة', 'Saved CVs'),
        icon: Icons.folder_copy_rounded,
        trailing: IconButton(
          tooltip: t('سيرة جديدة', 'سيرة جديدة', 'New CV'),
          onPressed: () => _create(s),
          icon: const Icon(Icons.add_circle_rounded, color: SD.gold),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final c in all)
              PickChip('${c['lang'] == 'en' ? '🇬🇧' : '🇸🇩'} ${c['title'] ?? ''}', c['id'] == cv['id'], () => s.setData('cv_builder_current', c['id']), color: SD.gold),
          ]),
          const SizedBox(height: 6),
          Wrap(alignment: WrapAlignment.end, children: [
            TextButton.icon(onPressed: () => _rename(s, cv), icon: const Icon(Icons.edit_rounded, size: 18), label: Text(t('سمّيها', 'تسمية', 'Rename'))),
            TextButton.icon(onPressed: () => _create(s, from: cv), icon: const Icon(Icons.copy_all_rounded, size: 18), label: Text(t('انسخها', 'نسخ', 'Duplicate'))),
            TextButton.icon(onPressed: () => _delete(s, cv), icon: const Icon(Icons.delete_outline_rounded, size: 18), label: Text(t('امسح', 'حذف', 'Delete'))),
          ]),
        ]),
      ),

      // ── اللغة والقالب ──
      SCard(
        title: t('اللغة والشكل', 'اللغة والقالب', 'Language & template'),
        icon: Icons.palette_rounded,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'ar', label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('عربي', 'العربية', 'Arabic')))),
              const ButtonSegment(value: 'en', label: FittedBox(fit: BoxFit.scaleDown, child: Text('English'))),
            ],
            selected: {cvRtl(cv) ? 'ar' : 'en'},
            onSelectionChanged: (v) => _save(s, cv..['lang'] = v.first),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'classic', label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('كلاسيك', 'كلاسيكي', 'Classic')))),
              ButtonSegment(value: 'modern', label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('حديث', 'حديث', 'Modern')))),
              ButtonSegment(value: 'compact', label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('مختصر', 'مختصر', 'Compact')))),
            ],
            selected: {cvStr(cv, 'tpl').isEmpty ? 'modern' : cvStr(cv, 'tpl')},
            onSelectionChanged: (v) => _save(s, cv..['tpl'] = v.first),
          ),
          const SizedBox(height: 8),
          Text(
            t('اكتب المحتوى بنفس لغة السيرة — العناوين بتتغير براها.', 'اكتب المحتوى بلغة السيرة نفسها — العناوين تتغير تلقائيًا.',
                'Write the content in the CV\'s language — headings switch automatically.'),
            style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65)),
          ),
        ]),
      ),

      // ── الاكتمال ──
      SCard(
        title: '${t('اكتمال السيرة', 'اكتمال السيرة', 'Completeness')}: ${(pct * 100).round()}%',
        icon: Icons.task_alt_rounded,
        color: pct >= 1 ? SD.green : SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: pct, minHeight: 10, color: pct >= 1 ? SD.green : SD.gold, backgroundColor: SD.gold.withValues(alpha: .15)),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('${t('ناقص', 'ينقص', 'Missing')}: ${missing.join('، ')}', style: const TextStyle(fontSize: 13, height: 1.5)),
          ],
        ]),
      ),

      // ── المحرّر ──
      SizedBox(
        height: 46,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final k in _sections)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: ChoiceChip(
                avatar: Icon(_secIcon(k), size: 18),
                label: Text(_secName(k)),
                selected: _sec == k,
                selectedColor: SD.gold.withValues(alpha: .3),
                onSelected: (_) => setState(() => _sec = k),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 10),
      SCard(
        key: ValueKey('${cv['id']}_$_sec'),
        title: _secName(_sec),
        icon: _secIcon(_sec),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NoteBox(_secTip(_sec), kind: NoteKind.tip),
          ..._editor(s, cv),
        ]),
      ),

      // ── المعاينة ──
      SCard(
        title: t('معاينة', 'معاينة مباشرة', 'Live preview'),
        icon: Icons.visibility_rounded,
        child: CvPreview(cv),
      ),

      // ── التصدير ──
      FilledButton.icon(
        onPressed: _busy ? null : () => _exportPdf(s, cv),
        icon: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)) : const Icon(Icons.picture_as_pdf_rounded),
        label: Text(t('طلّع PDF وشاركو', 'تصدير PDF ومشاركته', 'Export PDF & share')),
      ),
      if (pdf is Map) ...[
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _shareSaved(cv),
          icon: const Icon(Icons.share_rounded),
          label: Text(
            '${t('شارك آخر نسخة', 'مشاركة آخر نسخة', 'Share last PDF')} (${fmtBytes((pdf['size'] as num?)?.toInt() ?? 0)})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      const SizedBox(height: 12),
      ShareBar(() => cvPlainText(cv)),
      const SizedBox(height: 10),
      NoteBox(
          t('الملف بيتحفظ في جهازك بس (مجلد documents/cvs) — ما بنرسل بياناتك لأي جهة.', 'يُحفظ الملف على جهازك فقط (مجلد documents/cvs) — لا نرسل بياناتك لأي جهة.',
              'Files are saved on your device only (documents/cvs) — your data is not sent anywhere.'),
          kind: NoteKind.info),
    ]);
  }

  List<Widget> _editor(AppState s, Map<String, dynamic> cv) {
    if (_sec == 'info') {
      Widget f(String k, String label, {TextInputType? type, TextDirection? dir}) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              key: ValueKey('${cv['id']}_$k'),
              initialValue: cvStr(cv, k),
              keyboardType: type,
              textDirection: dir,
              decoration: InputDecoration(labelText: label),
              onChanged: (v) => _save(s, cv..[k] = v),
            ),
          );
      return [
        f('name', t('الاسم الكامل', 'الاسم الكامل', 'Full name')),
        f('jobTitle', t('المسمى الوظيفي (محاسب، مهندس…)', 'المسمى الوظيفي (محاسب، مهندس…)', 'Job title (Accountant, Engineer…)')),
        f('phone', t('رقم التلفون', 'رقم الهاتف', 'Phone'), type: TextInputType.phone, dir: TextDirection.ltr),
        f('email', t('الإيميل', 'البريد الإلكتروني', 'Email'), type: TextInputType.emailAddress, dir: TextDirection.ltr),
        f('city', t('المدينة والبلد', 'المدينة والدولة', 'City & country')),
        f('nationality', t('الجنسية (اختياري)', 'الجنسية (اختياري)', 'Nationality (optional)')),
        f('birth', t('تاريخ الميلاد (اختياري)', 'تاريخ الميلاد (اختياري)', 'Date of birth (optional)')),
        f('link', t('لينكدإن أو موقع (اختياري)', 'لينكدإن أو موقع (اختياري)', 'LinkedIn or website (optional)'), type: TextInputType.url, dir: TextDirection.ltr),
      ];
    }
    if (_sec == 'objective') {
      final len = cvStr(cv, 'objective').length;
      return [
        TextFormField(
          key: ValueKey('${cv['id']}_objective'),
          initialValue: cvStr(cv, 'objective'),
          minLines: 4,
          maxLines: 10,
          maxLength: 600,
          decoration: InputDecoration(
            labelText: t('الملخص المهني', 'الملخص المهني', 'Professional summary'),
            hintText: cvRtl(cv)
                ? 'محاسب بخبرة 6 سنوات في الشركات التجارية، متمكن من…'
                : 'Accountant with 6 years of experience in trading companies, skilled in…',
          ),
          onChanged: (v) => _save(s, cv..['objective'] = v),
        ),
        if (len > 0 && len < 40)
          Text(t('زوّد شوية — سطرين على الأقل', 'أضف المزيد — سطرين على الأقل', 'Add a bit more — at least two lines'),
              style: TextStyle(color: readable(context, SD.henna), fontSize: 12.5)),
      ];
    }
    final items = cvList(cv, _sec);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .65);
    return [
      if (_sec == 'refs')
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: cv['refsOnRequest'] == true,
          onChanged: (v) => _save(s, cv..['refsOnRequest'] = v),
          title: Text(t('أكتب «تُقدَّم عند الطلب» بدل الأسماء', 'اكتب «تُقدَّم عند الطلب» بدل الأسماء', 'Show "Available upon request" instead')),
        ),
      if (items.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(t('لسه ما ضفت حاجة هنا', 'لم تُضف شيئًا بعد', 'Nothing added yet'), textAlign: TextAlign.center, style: TextStyle(color: muted)),
        ),
      for (var i = 0; i < items.length; i++)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
          decoration: BoxDecoration(color: SD.gold.withValues(alpha: .08), borderRadius: BorderRadius.circular(14), border: Border.all(color: SD.gold.withValues(alpha: .3))),
          child: Row(children: [
            Expanded(
              child: InkWell(
                onTap: () => _editItem(s, cv, _sec, i),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_itemTitle(_sec, items[i]).isEmpty ? '—' : _itemTitle(_sec, items[i]),
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (_itemSub(_sec, items[i]).isNotEmpty)
                    Text(_itemSub(_sec, items[i]), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 12.5)),
                ]),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: t('لفوق', 'تحريك للأعلى', 'Move up'),
              onPressed: i == 0 ? null : () => _move(s, cv, _sec, i, -1),
              icon: const Icon(Icons.arrow_upward_rounded, size: 18),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: t('امسح', 'حذف', 'Delete'),
              onPressed: () => _removeItem(s, cv, _sec, i),
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ]),
        ),
      OutlinedButton.icon(
        onPressed: () => _editItem(s, cv, _sec),
        icon: const Icon(Icons.add_rounded),
        label: Text('${t('ضيف', 'إضافة', 'Add')} — ${_secName(_sec)}', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ];
  }
}

/// معاينة مصغّرة للسيرة (تحاكي قالب الـ PDF)
class CvPreview extends StatelessWidget {
  final Map cv;
  const CvPreview(this.cv, {super.key});

  @override
  Widget build(BuildContext context) {
    final rtl = cvRtl(cv);
    final tpl = cvStr(cv, 'tpl').isEmpty ? 'modern' : cvStr(cv, 'tpl');
    final modern = tpl == 'modern', compact = tpl == 'compact';
    const ink = Color(0xFF222222), grey = Color(0xFF666666);
    final accent = modern ? SD.gold : (compact ? SD.brown : ink);
    final base = compact ? 10.5 : 11.5;

    Text tx(String s, {double? size, bool b = false, Color color = ink, TextAlign? align}) => Text(
          s,
          textAlign: align,
          textDirection: !rtl && hasArabic(s) ? TextDirection.rtl : null,
          style: TextStyle(fontSize: size ?? base, fontWeight: b ? FontWeight.w800 : FontWeight.w500, color: color, height: 1.45, fontFamily: 'Tajawal'),
        );

    Widget heading(String key) {
      final label = cvLabel(cv, key);
      if (modern) {
        return Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Row(children: [
            Container(width: 4, height: 15, color: SD.gold),
            const SizedBox(width: 6),
            Flexible(child: tx(label, size: base + 2, b: true, color: SD.brown)),
            const SizedBox(width: 6),
            Expanded(child: Container(height: 1, color: SD.goldLight)),
          ]),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          tx(compact ? label : label.toUpperCase(), size: base + 1.5, b: true, color: accent),
          Container(height: compact ? .7 : 1.2, color: compact ? const Color(0xFFCCCCCC) : ink),
        ]),
      );
    }

    final name = cvStr(cv, 'name'), job = cvStr(cv, 'jobTitle');
    final contacts = cvContacts(cv);
    // كل وسيلة تواصل بنص مستقل حتى لا تنقلب الأرقام داخل السطر العربي
    Widget contactWrap(Color color, WrapAlignment align) => Wrap(alignment: align, spacing: 10, runSpacing: 2, children: [
          for (final c in contacts)
            Text(c,
                textDirection: hasArabic(c) ? TextDirection.rtl : TextDirection.ltr,
                style: TextStyle(fontSize: 10, color: color, height: 1.4, fontFamily: 'Tajawal')),
        ]);
    final children = <Widget>[];
    if (modern) {
      children.add(Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: SD.brown, border: Border(bottom: BorderSide(color: SD.gold, width: 3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          tx(name.isEmpty ? (rtl ? 'اسمك هنا' : 'Your name') : name, size: 19, b: true, color: Colors.white),
          if (job.isNotEmpty) tx(job, size: 13, b: true, color: SD.goldLight),
          if (contacts.isNotEmpty) contactWrap(SD.cream, WrapAlignment.start),
        ]),
      ));
    } else {
      children.addAll([
        tx(name.isEmpty ? (rtl ? 'اسمك هنا' : 'Your name') : name, size: 19, b: true, color: compact ? SD.brownDeep : ink, align: compact ? null : TextAlign.center),
        if (job.isNotEmpty) tx(job, size: 12.5, color: compact ? SD.brown : grey, align: compact ? null : TextAlign.center),
        if (contacts.isNotEmpty) contactWrap(grey, compact ? WrapAlignment.start : WrapAlignment.center),
        const SizedBox(height: 4),
        Container(height: compact ? 2 : 1.2, color: compact ? SD.gold : ink),
      ]);
    }
    final obj = cvStr(cv, 'objective');
    if (obj.isNotEmpty) children.addAll([heading('objective'), tx(obj)]);
    final exp = cvList(cv, 'exp');
    if (exp.isNotEmpty) {
      children.add(heading('exp'));
      for (final e in exp) {
        children.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: tx(itemStr(e, 'title'), b: true)),
          if (cvPeriod(e).isNotEmpty) Flexible(child: tx(cvPeriod(e), size: base - 1, color: grey)),
        ]));
        final org = [itemStr(e, 'org'), itemStr(e, 'place')].where((x) => x.isNotEmpty).join(' — ');
        if (org.isNotEmpty) children.add(tx(org, color: modern ? SD.brown : grey, b: modern));
        for (final p in cvBullets(itemStr(e, 'desc'))) {
          children.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 7), child: Container(width: 4, height: 4, decoration: BoxDecoration(color: accent, shape: BoxShape.circle))),
            const SizedBox(width: 5),
            Expanded(child: tx(p)),
          ]));
        }
        children.add(const SizedBox(height: 4));
      }
    }
    final edu = cvList(cv, 'edu');
    if (edu.isNotEmpty) {
      children.add(heading('edu'));
      for (final e in edu) {
        children.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: tx(itemStr(e, 'degree'), b: true)),
          if (itemStr(e, 'year').isNotEmpty) Flexible(child: tx(itemStr(e, 'year'), size: base - 1, color: grey)),
        ]));
        final sch = [itemStr(e, 'school'), itemStr(e, 'note')].where((x) => x.isNotEmpty).join(' — ');
        if (sch.isNotEmpty) children.add(tx(sch, color: grey));
      }
    }
    final skills = cvList(cv, 'skills');
    if (skills.isNotEmpty) {
      children.add(heading('skills'));
      children.add(Wrap(spacing: 6, runSpacing: 6, children: [
        for (final k in skills)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(border: Border.all(color: accent.withValues(alpha: .6)), borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(child: tx(itemStr(k, 'n'), size: base - .5)),
              const SizedBox(width: 4),
              for (var i = 1; i <= 5; i++)
                Container(
                  width: 6,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: .7),
                  decoration: BoxDecoration(color: i <= itemLvl(k) ? (modern ? SD.gold : SD.brown) : const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)),
                ),
            ]),
          ),
      ]));
    }
    final langs = cvList(cv, 'langs');
    if (langs.isNotEmpty) {
      children.add(heading('langs'));
      children.add(tx(langs.map((l) => '${itemStr(l, 'n')}: ${langLevel(cv, itemLvl(l))}').join('   ·   ')));
    }
    final certs = cvList(cv, 'certs');
    if (certs.isNotEmpty) {
      children.add(heading('certs'));
      for (final c in certs) {
        children.add(tx([itemStr(c, 'n'), itemStr(c, 'org'), itemStr(c, 'year')].where((x) => x.isNotEmpty).join(' — ')));
      }
    }
    final refs = cvList(cv, 'refs');
    if (cv['refsOnRequest'] == true) {
      children.addAll([heading('refs'), tx(cvLabel(cv, 'refsOnRequest'), color: grey)]);
    } else if (refs.isNotEmpty) {
      children.add(heading('refs'));
      for (final r in refs) {
        children.add(tx([itemStr(r, 'n'), itemStr(r, 'role'), itemStr(r, 'contact')].where((x) => x.isNotEmpty).join(' — ')));
      }
    }

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}
