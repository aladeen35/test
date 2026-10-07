import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'learn_common.dart';

/// نسبة الشهادة السودانية: 4 مواد إلزامية + أفضل 3 مواد من المساق = 7 مواد من 700

const certCounted = 7;

/// مادة: [mark] من 100 (null = لم تُدخل)، [compulsory] إلزامية
class CertSubject {
  final String id;
  final double? mark;
  final bool compulsory;
  const CertSubject(this.id, this.mark, this.compulsory);
}

class CertResult {
  final List<String> counted;
  final double sum, pct;
  final int missing;
  const CertResult(this.counted, this.sum, this.pct, this.missing);
}

/// يحسب المجموع: كل الإلزامية (حتى 7) ثم أفضل مواد المساق لتكملة 7 مواد، والقسمة على 700
CertResult certCompute(List<CertSubject> subjects) {
  final comp = subjects.where((x) => x.compulsory && x.mark != null).toList();
  final track = subjects.where((x) => !x.compulsory && x.mark != null).toList()..sort((a, b) => b.mark!.compareTo(a.mark!));
  final picked = <CertSubject>[...comp.take(certCounted)];
  for (final x in track) {
    if (picked.length >= certCounted) break;
    picked.add(x);
  }
  final sum = picked.fold<double>(0, (a, x) => a + x.mark!.clamp(0, 100));
  return CertResult([for (final x in picked) x.id], sum, sum / (certCounted * 100) * 100, certCounted - picked.length);
}

/// التقدير الحرفي (سلّم تقريبي شائع)
String certGrade(double pct) => pct >= 80
    ? 'A'
    : pct >= 70
        ? 'B'
        : pct >= 60
            ? 'C'
            : pct >= 50
                ? 'D'
                : 'F';

/// الدرجات الإضافية اللازمة لبلوغ [target]% (0 إن تحقق)، و[possible] إن أمكن برفع المواد المحسوبة حتى 100
({double extra, double perSubject, bool possible}) certNeeded(CertResult r, List<CertSubject> subjects, double target) {
  final need = target / 100 * certCounted * 100 - r.sum;
  if (need <= 0) return (extra: 0, perSubject: 0, possible: true);
  final counted = subjects.where((x) => r.counted.contains(x.id)).toList();
  var room = counted.fold<double>(0, (a, x) => a + (100 - x.mark!.clamp(0, 100)));
  room += r.missing * 100;
  return (extra: need, perSubject: need / certCounted, possible: need <= room + 1e-9);
}

/// المواد الافتراضية: (المفتاح، إلزامية)
const _defaults = {
  'sci': [('islamic', true), ('arabic', true), ('english', true), ('math_sp', true), ('physics', false), ('chemistry', false), ('biology', false), ('computer', false)],
  'arts': [('islamic', true), ('arabic', true), ('english', true), ('math_el', true), ('history', false), ('geography', false), ('eng_lit', false), ('economics', false)],
};

String _keyName(String k) => switch (k) {
      'islamic' => t('التربية الإسلامية (أو المسيحية)', 'التربية الإسلامية (أو المسيحية)', 'Islamic (or Christian) studies'),
      'arabic' => t('اللغة العربية', 'اللغة العربية', 'Arabic'),
      'english' => t('اللغة الإنجليزية', 'اللغة الإنجليزية', 'English'),
      'math_sp' => t('الرياضيات المتخصصة', 'الرياضيات المتخصصة', 'Specialised mathematics'),
      'math_el' => t('الرياضيات الأساسية', 'الرياضيات الأساسية', 'Elementary mathematics'),
      'physics' => t('الفيزياء', 'الفيزياء', 'Physics'),
      'chemistry' => t('الكيمياء', 'الكيمياء', 'Chemistry'),
      'biology' => t('الأحياء', 'الأحياء', 'Biology'),
      'computer' => t('علوم الحاسوب', 'علوم الحاسوب', 'Computer science'),
      'history' => t('التاريخ', 'التاريخ', 'History'),
      'geography' => t('الجغرافيا', 'الجغرافيا', 'Geography'),
      'eng_lit' => t('الأدب الإنجليزي', 'الأدب الإنجليزي', 'English literature'),
      'economics' => t('الاقتصاد', 'الاقتصاد', 'Economics'),
      _ => k,
    };

class SdCertificateTool extends StatefulWidget {
  const SdCertificateTool({super.key});
  @override
  State<SdCertificateTool> createState() => _SdCertificateToolState();
}

class _SdCertificateToolState extends State<SdCertificateTool> {
  final _ctrls = <String, TextEditingController>{};
  late final TextEditingController _target;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _target = TextEditingController(text: '${_data(s)['target'] ?? '80'}');
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _target.dispose();
    super.dispose();
  }

  Map<String, dynamic> _data(AppState s) => Map<String, dynamic>.from(s.getData<Map>('sd_certificate_data') ?? const {});
  String _track(AppState s) => _data(s)['track'] == 'arts' ? 'arts' : 'sci';

  List<Map<String, dynamic>> _subjects(AppState s, String track) {
    final all = Map<String, dynamic>.from(_data(s)['subjects'] as Map? ?? const {});
    final l = lMaps(all[track]);
    if (l.isNotEmpty || all.containsKey(track)) return l;
    return [
      for (final d in _defaults[track]!) {'id': '${track}_${d.$1}', 'k': d.$1, 'c': d.$2, 'm': null},
    ];
  }

  void _saveSubjects(AppState s, String track, List<Map<String, dynamic>> l) {
    final d = _data(s);
    final all = Map<String, dynamic>.from(d['subjects'] as Map? ?? const {});
    all[track] = l;
    s.setData('sd_certificate_data', {...d, 'subjects': all});
  }

  /// يُزال المتحكّم ويُتخلّص منه بعد الإطار حتى لا يُستخدم وهو مُتلف
  void _drop(String id) {
    final c = _ctrls.remove(id);
    if (c != null) WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
  }

  String _name(Map x) => (x['n'] as String?)?.trim().isNotEmpty == true ? x['n'] as String : _keyName('${x['k'] ?? ''}');

  TextEditingController _ctrl(Map x) => _ctrls.putIfAbsent(x['id'] as String, () {
        final m = x['m'];
        return TextEditingController(text: m is num ? fmt(m, 1) : '');
      });

  Future<void> _rename(AppState s, String track, Map<String, dynamic>? x) async {
    final c = TextEditingController(text: x == null ? '' : _name(x));
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(x == null ? t('مادة جديدة', 'مادة جديدة', 'New subject') : t('غيّر اسم المادة', 'تعديل اسم المادة', 'Rename subject')),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(labelText: t('اسم المادة', 'اسم المادة', 'Subject name'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('خلاص', 'إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(t('تمام', 'حفظ', 'Save'))),
        ],
      ),
    );
    Future.delayed(const Duration(milliseconds: 600), c.dispose);
    if (r == null || r.isEmpty || !mounted) return;
    final l = _subjects(s, track);
    if (x == null) {
      l.add({'id': lId(), 'n': r, 'c': false, 'm': null});
    } else {
      final i = l.indexWhere((e) => e['id'] == x['id']);
      if (i >= 0) l[i] = {...l[i], 'n': r};
    }
    _saveSubjects(s, track, l);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final track = _track(s);
    final list = _subjects(s, track);
    final subs = [for (final x in list) CertSubject(x['id'] as String, x['m'] is num ? (x['m'] as num).toDouble() : null, x['c'] == true)];
    final r = certCompute(subs);
    final target = parseNum(_target.text, 80).clamp(0, 100).toDouble();
    final need = certNeeded(r, subs, target);
    final compCount = subs.where((x) => x.compulsory).length;
    final countedNames = [for (final x in list) if (r.counted.contains(x['id'])) _name(x)];

    return ToolList(children: [
      lSegmented<String>(
        items: [('sci', t('علمي', 'المساق العلمي', 'Science')), ('arts', t('أدبي', 'المساق الأدبي', 'Arts'))],
        value: track,
        onChanged: (v) => s.setData('sd_certificate_data', {..._data(s), 'track': v}),
      ),
      const SizedBox(height: 12),
      ResultHero(
        label: t('نسبتك في الشهادة السودانية', 'نسبة الشهادة السودانية', 'Sudan certificate percentage'),
        value: '${fmt(r.pct, 2)}%',
        sub: '${fmt(r.sum, 1)} / ${certCounted * 100} · ${t('التقدير', 'التقدير', 'Grade')} ${certGrade(r.pct)}',
      ),
      StatGrid([
        StatChip('${r.counted.length}/$certCounted', t('مواد محسوبة', 'مواد محسوبة', 'Subjects counted'), color: SD.green, icon: Icons.task_alt_rounded),
        StatChip(certGrade(r.pct), t('التقدير', 'التقدير', 'Grade'), color: SD.gold, icon: Icons.workspace_premium_rounded),
        StatChip(r.counted.isEmpty ? '—' : fmt(r.sum / math.max(1, r.counted.length), 1), t('متوسط المادة', 'متوسط المادة', 'Avg per subject'),
            color: SD.nile, icon: Icons.functions_rounded),
      ]),
      const SizedBox(height: 14),
      if (r.missing > 0)
        NoteBox(
            t('فاضل ${r.missing} مادة عشان تكمّل 7 مواد — النسبة محسوبة من 700 برضو.', 'ينقص ${r.missing} مادة لإكمال 7 مواد — النسبة محسوبة من 700.',
                '${r.missing} subject(s) missing to reach 7 — the percentage is still out of 700.'),
            kind: NoteKind.warn),
      SCard(
        title: t('درجاتك (من 100)', 'الدرجات (من 100)', 'Your marks (out of 100)'),
        icon: Icons.edit_note_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            t('🔒 = إلزامية بتنحسب دايمًا · ✓ = داخلة في الـ7', '🔒 = إلزامية تُحسب دائمًا · ✓ = داخلة في السبع', '🔒 = compulsory, always counted · ✓ = among the 7 counted'),
            style: const TextStyle(fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          for (final x in list) _row(context, s, track, list, x, r.counted.contains(x['id'])),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _rename(s, track, null),
                icon: const Icon(Icons.add_rounded),
                label: Text(t('زيد مادة', 'إضافة مادة', 'Add subject'), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  for (final x in list) {
                    _drop(x['id'] as String);
                  }
                  final d = _data(s);
                  final all = Map<String, dynamic>.from(d['subjects'] as Map? ?? const {})..remove(track);
                  s.setData('sd_certificate_data', {...d, 'subjects': all});
                },
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(t('رجّع الافتراضي', 'استعادة الافتراضي', 'Reset defaults'), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ]),
          if (compCount > certCounted)
            NoteBox(t('المواد الإلزامية أكتر من 7!', 'المواد الإلزامية أكثر من 7!', 'More than 7 compulsory subjects!'), kind: NoteKind.warn),
        ]),
      ),
      SCard(
        title: t('المواد الداخلة في الحساب', 'المواد المحسوبة', 'Counted subjects'),
        icon: Icons.checklist_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final x in list)
            if (r.counted.contains(x['id']))
              LBar(_name(x), lNum(x['m']) / 100, fmt(lNum(x['m']), 1), color: x['c'] == true ? SD.gold : SD.green),
          if (r.counted.isEmpty) Text(t('أكتب درجاتك فوق', 'أدخل الدرجات بالأعلى', 'Enter your marks above')),
        ]),
      ),
      SCard(
        title: t('لو عايز نسبة معيّنة؟', 'ماذا لو أردت نسبة معيّنة؟', 'What if: target %'),
        icon: Icons.flag_circle_rounded,
        color: SD.purple,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField(t('النسبة المطلوبة', 'النسبة المستهدفة', 'Target percentage'), _target, suffix: '%', onChanged: (v) {
            s.setData('sd_certificate_data', {..._data(s), 'target': v});
          }),
          if (need.extra <= 0)
            NoteBox(t('مبروك! نسبتك فوق ${fmt(target, 1)}% 🎉', 'تهانينا! نسبتك أعلى من ${fmt(target, 1)}% 🎉', 'Congrats! You are above ${fmt(target, 1)}% 🎉'), kind: NoteKind.tip)
          else ...[
            InfoRow(t('المجموع المطلوب', 'المجموع المطلوب', 'Total needed'), '${fmt(target / 100 * certCounted * 100, 1)} / ${certCounted * 100}'),
            InfoRow(t('ناقصك', 'تحتاج إضافة', 'You need'), '${fmt(need.extra, 1)} ${t('درجة', 'درجة', 'marks')}', valueColor: SD.red),
            InfoRow(t('يعني في كل مادة من السبعة', 'أي في كل مادة من السبع', 'i.e. per counted subject'), '+${fmt(need.perSubject, 1)}'),
            if (!need.possible)
              NoteBox(t('النسبة دي ما ممكنة بالمواد الحالية حتى لو جبت 100 في الكل.', 'هذه النسبة غير ممكنة بالمواد الحالية حتى بالدرجة الكاملة.',
                  'Not reachable with these subjects even with full marks.'), kind: NoteKind.danger),
          ],
        ]),
      ),
      SCard(
        title: t('سلّم التقديرات (تقريبي)', 'سلّم التقديرات (تقريبي)', 'Grade scale (approximate)'),
        icon: Icons.stairs_rounded,
        color: SD.gold,
        child: Column(children: [
          for (final g in const [('A', '80 – 100'), ('B', '70 – 79'), ('C', '60 – 69'), ('D', '50 – 59'), ('F', '< 50')])
            InfoRow(g.$1, g.$2, valueColor: g.$1 == certGrade(r.pct) ? SD.green : null),
        ]),
      ),
      ShareBar(() => [
            '🎓 ${t('نسبة الشهادة السودانية', 'نسبة الشهادة السودانية', 'Sudan certificate')} — ${track == 'sci' ? t('علمي', 'علمي', 'Science') : t('أدبي', 'أدبي', 'Arts')}',
            for (final x in list)
              if (x['m'] is num) '${r.counted.contains(x['id']) ? '✓' : '•'} ${_name(x)}: ${fmt(lNum(x['m']), 1)}',
            '${t('المجموع', 'المجموع', 'Total')}: ${fmt(r.sum, 1)} / ${certCounted * 100}',
            '${t('النسبة', 'النسبة', 'Percentage')}: ${fmt(r.pct, 2)}% (${certGrade(r.pct)})',
            if (countedNames.isNotEmpty) '${t('المحسوبة', 'المواد المحسوبة', 'Counted')}: ${countedNames.join('، ')}',
          ].join('\n')),
      const SizedBox(height: 12),
      NoteBox(t(
          'القاعدة المستخدمة: 4 مواد إلزامية (الدين، العربي، الإنجليزي، الرياضيات) + أحسن 3 مواد من مساقك = 7 مواد، والنسبة = المجموع ÷ 700 × 100.',
          'القاعدة المستخدمة: 4 مواد إلزامية (التربية الدينية، العربية، الإنجليزية، الرياضيات) + أفضل 3 مواد من المساق = 7 مواد، والنسبة = المجموع ÷ 700 × 100.',
          'Rule used: 4 compulsory subjects (religion, Arabic, English, mathematics) + your best 3 track subjects = 7 subjects; percentage = total ÷ 700 × 100.')),
      NoteBox(
          t('لوائح وزارة التربية والتعليم وشروط القبول ممكن تتغيّر من سنة لسنة — اتأكد من الوزارة أو مدرستك. أسماء المواد وسلّم التقديرات هنا تقريبية وتقدر تعدّلها.',
              'لوائح وزارة التربية والتعليم وشروط القبول قد تتغير من عام لآخر — تحقّق من الوزارة أو مدرستك. أسماء المواد وسلّم التقديرات هنا تقريبية وقابلة للتعديل.',
              'Ministry of Education rules and admission requirements can change from year to year — verify with the Ministry or your school. Subject names and the grade scale here are approximate and editable.'),
          kind: NoteKind.warn),
    ]);
  }

  Widget _row(BuildContext context, AppState s, String track, List<Map<String, dynamic>> list, Map<String, dynamic> x, bool counted) {
    final comp = x['c'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: t('إلزامية؟', 'إلزامية؟', 'Compulsory?'),
          onPressed: () {
            final l = _subjects(s, track);
            final i = l.indexWhere((e) => e['id'] == x['id']);
            if (i >= 0) l[i] = {...l[i], 'c': !comp};
            _saveSubjects(s, track, l);
          },
          icon: Icon(comp ? Icons.lock_rounded : Icons.lock_open_rounded, color: comp ? readable(context, SD.gold) : null, size: 20),
        ),
        Expanded(
          child: InkWell(
            onTap: () => _rename(s, track, x),
            child: Row(children: [
              if (counted) ...[Icon(Icons.check_circle_rounded, size: 16, color: readable(context, SD.green)), const SizedBox(width: 4)],
              Expanded(child: Text(_name(x), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: counted ? FontWeight.w800 : FontWeight.w600))),
            ]),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 74,
          child: TextField(
            controller: _ctrl(x),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(hintText: '—', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10)),
            onChanged: (v) {
              final l = _subjects(s, track);
              final i = l.indexWhere((e) => e['id'] == x['id']);
              final n = v.trim().isEmpty ? null : parseNum(v, -1);
              if (i >= 0) l[i] = {...l[i], 'm': n == null || n < 0 ? null : n.clamp(0, 100)};
              _saveSubjects(s, track, l);
            },
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: t('امسح', 'حذف', 'Delete'),
          onPressed: () {
            final l = _subjects(s, track)..removeWhere((e) => e['id'] == x['id']);
            _drop(x['id'] as String);
            _saveSubjects(s, track, l);
          },
          icon: const Icon(Icons.close_rounded, size: 18),
        ),
      ]),
    );
  }
}
