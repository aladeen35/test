import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'more_common.dart';

/// سلّم الدرجات: 4.0 (الشائع عالميًا وفي السودان) و5.0 (السعودية وبعض الجامعات)
const _scale4 = [
  ('A+', 4.0), ('A', 4.0), ('A-', 3.7), ('B+', 3.3), ('B', 3.0), ('B-', 2.7),
  ('C+', 2.3), ('C', 2.0), ('C-', 1.7), ('D+', 1.3), ('D', 1.0), ('F', 0.0),
];
const _scale5 = [
  ('A+', 5.0), ('A', 4.75), ('B+', 4.5), ('B', 4.0), ('C+', 3.5), ('C', 3.0), ('D+', 2.5), ('D', 2.0), ('F', 1.0),
];

class _Course {
  final n = TextEditingController(), h = TextEditingController();
  String g = 'A';
  _Course([Map? j]) {
    n.text = j?['n'] ?? '';
    h.text = j?['h'] ?? '3';
    g = j?['g'] ?? 'A';
  }
  Map<String, dynamic> toJson() => {'n': n.text, 'h': h.text, 'g': g};
  void dispose() {
    n.dispose();
    h.dispose();
  }
}

class _Subject {
  final n = TextEditingController(), m = TextEditingController(), f = TextEditingController();
  _Subject([Map? j]) {
    n.text = j?['n'] ?? '';
    m.text = j?['m'] ?? '';
    f.text = j?['f'] ?? '100';
  }
  Map<String, dynamic> toJson() => {'n': n.text, 'm': m.text, 'f': f.text};
  void dispose() {
    n.dispose();
    m.dispose();
    f.dispose();
  }
}

class GpaTool extends StatefulWidget {
  const GpaTool({super.key});
  @override
  State<GpaTool> createState() => _GpaToolState();
}

class _GpaToolState extends State<GpaTool> {
  int mode = 0; // 0 جامعة، 1 مدرسة
  bool five = false;
  List<_Course> courses = [];
  List<_Subject> subjects = [];
  final prevG = TextEditingController(), prevH = TextEditingController(), targetG = TextEditingController(), nextH = TextEditingController();
  final targetP = TextEditingController(), remN = TextEditingController(), remF = TextEditingController();

  @override
  void initState() {
    super.initState();
    final d = context.read<AppState>().getData<Map>('gpa_data') ?? {};
    mode = (d['mode'] as num?)?.toInt() ?? 0;
    five = d['five'] ?? false;
    courses = List<Map>.from(d['courses'] ?? []).map(_Course.new).toList();
    subjects = List<Map>.from(d['subjects'] ?? []).map(_Subject.new).toList();
    if (courses.isEmpty) courses = [_Course(), _Course(), _Course()];
    if (subjects.isEmpty) subjects = [_Subject(), _Subject(), _Subject()];
    prevG.text = d['prevG'] ?? '';
    prevH.text = d['prevH'] ?? '';
    targetG.text = d['targetG'] ?? '';
    nextH.text = d['nextH'] ?? '';
    targetP.text = d['targetP'] ?? '';
    remN.text = d['remN'] ?? '';
    remF.text = d['remF'] ?? '100';
  }

  @override
  void dispose() {
    for (final c in courses) {
      c.dispose();
    }
    for (final s in subjects) {
      s.dispose();
    }
    for (final c in [prevG, prevH, targetG, nextH, targetP, remN, remF]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    context.read<AppState>().setData('gpa_data', {
      'mode': mode, 'five': five,
      'courses': courses.map((c) => c.toJson()).toList(),
      'subjects': subjects.map((s) => s.toJson()).toList(),
      'prevG': prevG.text, 'prevH': prevH.text, 'targetG': targetG.text, 'nextH': nextH.text,
      'targetP': targetP.text, 'remN': remN.text, 'remF': remF.text,
    });
    setState(() {});
  }

  void _disposeLater(void Function() f) => WidgetsBinding.instance.addPostFrameCallback((_) => f());

  List<(String, double)> get scale => five ? _scale5 : _scale4;
  double get maxG => five ? 5 : 4;
  double _points(String g) => scale.firstWhere((x) => x.$1 == g, orElse: () => scale.first).$2;

  /// التقدير اللفظي حسب المعدل
  (String, Color) _classify(double gpa) {
    final r = gpa / maxG;
    if (r >= .875) return (t('ممتاز', 'ممتاز', 'Excellent'), SD.green);
    if (r >= .75) return (t('جيد جدًا', 'جيد جدًا', 'Very good'), SD.teal);
    if (r >= .625) return (tr('جيد', 'Good'), SD.nile);
    if (r >= .5) return (tr('مقبول', 'Pass'), SD.gold);
    return (t('ضعيف', 'ضعيف', 'Weak'), SD.red);
  }

  @override
  Widget build(BuildContext context) => ToolList(children: [
        SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 0, icon: const Icon(Icons.school_rounded), label: Text(t('الجامعة (GPA)', 'الجامعة (GPA)', 'University GPA'))),
            ButtonSegment(value: 1, icon: const Icon(Icons.menu_book_rounded), label: Text(t('المدرسة (%)', 'المدرسة (%)', 'School (%)'))),
          ],
          selected: {mode},
          onSelectionChanged: (v) {
            mode = v.first;
            _save();
          },
        ),
        const SizedBox(height: 14),
        if (mode == 0) ..._university() else ..._school(),
      ]);

  /* ───────────── الجامعة ───────────── */
  List<Widget> _university() {
    var hours = 0.0, qp = 0.0;
    for (final c in courses) {
      final h = parseNum(c.h.text);
      if (h <= 0) continue;
      hours += h;
      qp += h * _points(c.g);
    }
    final sem = hours > 0 ? qp / hours : null;
    final pg = parseNum(prevG.text), ph = parseNum(prevH.text);
    final hasPrev = pg > 0 && ph > 0 && pg <= maxG;
    final cumH = hours + (hasPrev ? ph : 0);
    final cum = cumH > 0 ? (qp + (hasPrev ? pg * ph : 0)) / cumH : null;
    final shown = hasPrev ? cum : sem;
    final cls = shown == null ? null : _classify(shown);

    // كم تحتاج في الترم الجاي عشان تصل معدل تراكمي مستهدف
    final tg = parseNum(targetG.text), nh = parseNum(nextH.text);
    double? needed;
    if (tg > 0 && nh > 0 && cumH > 0 && cum != null) needed = (tg * (cumH + nh) - cum * cumH) / nh;

    return [
      ResultHero(
        label: hasPrev ? t('معدلك التراكمي', 'المعدل التراكمي', 'Cumulative GPA') : t('معدل الترم', 'المعدل الفصلي', 'Semester GPA'),
        value: shown == null ? '—' : '${fmt(shown, 2)} / ${fmt(maxG, 0)}',
        sub: shown == null
            ? t('ضيف موادك وساعاتها والتقدير', 'أضف المقررات وساعاتها والتقدير', 'Add your courses, credit hours and grades')
            : '${cls!.$1}${hasPrev && sem != null ? ' • ${t('الترم', 'الفصل', 'Semester')}: ${fmt(sem, 2)}' : ''} • ${fmt(cumH, 0)} ${t('ساعة', 'ساعة', 'hrs')}',
        colors: const [Color(0xFF3B2F8F), Color(0xFF0B5C8A), Color(0xFF3A1F0C)],
      ),
      SCard(
        title: t('السلّم', 'سلّم التقديرات', 'Grading scale'),
        icon: Icons.straighten_rounded,
        color: SD.indigo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<bool>(
            segments: const [ButtonSegment(value: false, label: Text('4.0')), ButtonSegment(value: true, label: Text('5.0'))],
            selected: {five},
            onSelectionChanged: (v) {
              five = v.first;
              for (final c in courses) {
                if (!scale.any((x) => x.$1 == c.g)) c.g = 'A';
              }
              _save();
            },
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (final g in scale) Chip(visualDensity: VisualDensity.compact, label: Text('${g.$1} = ${fmt(g.$2, 2)}')),
          ]),
        ]),
      ),
      SCard(
        title: t('مواد الترم', 'مقررات الفصل', 'This semester'),
        icon: Icons.list_alt_rounded,
        color: SD.nile,
        trailing: Text('${fmt(hours, 0)} ${t('ساعة', 'ساعة', 'hrs')}', style: const TextStyle(fontWeight: FontWeight.w800)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < courses.length; i++) _courseRow(i),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: courses.length >= 15
                    ? null
                    : () {
                        courses.add(_Course());
                        _save();
                      },
                icon: const Icon(Icons.add_rounded),
                label: Text(t('ضيف مادة', 'أضف مقررًا', 'Add course')),
              ),
            ),
          ]),
          if (sem != null) ...[
            const SizedBox(height: 8),
            InfoRow(t('النقاط', 'النقاط', 'Quality points'), fmt(qp, 2), icon: Icons.functions_rounded),
            InfoRow(t('معدل الترم', 'المعدل الفصلي', 'Semester GPA'), fmt(sem, 2), icon: Icons.grade_rounded, valueColor: _classify(sem).$2),
          ],
        ]),
      ),
      SCard(
        title: t('المعدل التراكمي', 'المعدل التراكمي', 'Cumulative'),
        icon: Icons.stacked_line_chart_rounded,
        color: SD.teal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: NumField(t('التراكمي القديم', 'المعدل التراكمي السابق', 'Previous GPA'), prevG, onChanged: (_) => _save())),
            const SizedBox(width: 8),
            Expanded(child: NumField(t('ساعاتو', 'ساعاته المكتسبة', 'Hours earned'), prevH, onChanged: (_) => _save())),
          ]),
          if (hasPrev && cum != null) ...[
            InfoRow(t('التراكمي الجديد', 'المعدل التراكمي الجديد', 'New cumulative GPA'), fmt(cum, 2), icon: Icons.trending_up_rounded, valueColor: _classify(cum).$2,
                hint: '${cum >= pg ? '▲' : '▼'} ${fmt((cum - pg).abs(), 2)} ${t('عن القديم', 'عن السابق', 'vs previous')}'),
            InfoRow(t('مجموع الساعات', 'إجمالي الساعات', 'Total hours'), fmt(cumH, 0), icon: Icons.timelapse_rounded),
          ],
          const Divider(height: 24),
          Text(t('عايز توصل معدل كم؟', 'ما المعدل الذي تستهدفه؟', 'Targeting a GPA?'), style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: NumField(t('المعدل المستهدف', 'المعدل المستهدف', 'Target GPA'), targetG, onChanged: (_) => _save())),
            const SizedBox(width: 8),
            Expanded(child: NumField(t('ساعات الترم الجاي', 'ساعات الفصل القادم', 'Next term hours'), nextH, onChanged: (_) => _save())),
          ]),
          if (needed != null)
            NoteBox(
              needed > maxG
                  ? t('صعبة في ترم واحد — محتاج ${fmt(needed, 2)} وده فوق ${fmt(maxG, 0)}. وزّعها على أكتر من ترم.',
                      'غير ممكن في فصل واحد — تحتاج ${fmt(needed, 2)} وهو أعلى من ${fmt(maxG, 0)}. وزّع الهدف على أكثر من فصل.',
                      'Not reachable in one term — you would need ${fmt(needed, 2)}, above ${fmt(maxG, 0)}. Spread it over more terms.')
                  : needed <= 0
                      ? t('إنت أصلًا فوق الهدف 👏', 'أنت فوق الهدف بالفعل 👏', 'You are already above the target 👏')
                      : t('محتاج معدل ترم ${fmt(needed, 2)} على الأقل', 'تحتاج معدلًا فصليًا لا يقل عن ${fmt(needed, 2)}', 'You need at least ${fmt(needed, 2)} next term'),
              kind: needed > maxG ? NoteKind.warn : NoteKind.tip,
            ),
        ]),
      ),
      if (sem != null)
        ShareBar(() => [
              '🎓 ${t('معدلي', 'معدلي', 'My GPA')} (${fmt(maxG, 1)})',
              for (final c in courses)
                if (parseNum(c.h.text) > 0) '• ${c.n.text.trim().isEmpty ? t('مادة', 'مقرر', 'Course') : c.n.text.trim()}: ${c.g} (${c.h.text} ${t('س', 'س', 'h')})',
              '${t('معدل الترم', 'المعدل الفصلي', 'Semester GPA')}: ${fmt(sem, 2)}',
              if (hasPrev && cum != null) '${t('التراكمي', 'التراكمي', 'Cumulative')}: ${fmt(cum, 2)}',
            ].join('\n')),
      const SizedBox(height: 12),
      NoteBox(
          t('الجامعات بتختلف في تحويل الحروف للنقاط (مثلًا F في سلّم الـ5 بعضها 0 وبعضها 1). راجع لائحة جامعتك.',
              'تختلف الجامعات في تحويل التقديرات إلى نقاط (مثلًا F في سلّم الخمس درجات قد تكون 0 أو 1). راجع لائحة جامعتك.',
              'Universities differ in letter-to-point mapping (e.g. F on the 5-point scale may be 0 or 1). Check your university rules.'),
          kind: NoteKind.info),
    ];
  }

  Widget _courseRow(int i) {
    final c = courses[i];
    return Padding(
      key: ObjectKey(c),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 5,
          child: TextField(
            controller: c.n,
            onChanged: (_) => _save(),
            decoration: InputDecoration(labelText: '${t('المادة', 'المقرر', 'Course')} ${i + 1}', isDense: true),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: TextField(
            controller: c.h,
            onChanged: (_) => _save(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: InputDecoration(labelText: t('ساعات', 'ساعات', 'Hrs'), isDense: true),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            key: ValueKey('${c.hashCode}_$five'),
            initialValue: scale.any((x) => x.$1 == c.g) ? c.g : scale.first.$1,
            isDense: true,
            isExpanded: true,
            decoration: InputDecoration(labelText: t('التقدير', 'التقدير', 'Grade'), isDense: true),
            items: [for (final g in scale) DropdownMenuItem(value: g.$1, child: Text(g.$1, textDirection: TextDirection.ltr))],
            onChanged: (v) {
              if (v == null) return;
              c.g = v;
              _save();
            },
          ),
        ),
        MiniIconBtn(Icons.close_rounded,
            onTap: courses.length <= 1
                ? null
                : () {
                    final r = courses.removeAt(i);
                    _disposeLater(r.dispose);
                    _save();
                  }),
      ]),
    );
  }

  /* ───────────── المدرسة ───────────── */
  (String, Color) _letter(double p) {
    if (p >= 90) return ('A — ${t('ممتاز', 'ممتاز', 'Excellent')}', SD.green);
    if (p >= 80) return ('B — ${t('جيد جدًا', 'جيد جدًا', 'Very good')}', SD.teal);
    if (p >= 70) return ('C — ${tr('جيد', 'Good')}', SD.nile);
    if (p >= 60) return ('D — ${tr('مقبول', 'Fair')}', SD.gold);
    if (p >= 50) return ('E — ${t('ناجح', 'ناجح', 'Pass')}', SD.orange);
    return ('F — ${t('راسب', 'راسب', 'Fail')}', SD.red);
  }

  List<Widget> _school() {
    var got = 0.0, full = 0.0;
    final rows = <(String, double)>[];
    for (final s in subjects) {
      final f = parseNum(s.f.text);
      final m = parseNum(s.m.text);
      if (f <= 0 || s.m.text.trim().isEmpty) continue;
      got += m.clamp(0, f);
      full += f;
      rows.add((s.n.text.trim(), m / f * 100));
    }
    final pct = full > 0 ? got / full * 100 : null;
    final letter = pct == null ? null : _letter(pct);

    // كم تحتاج في المواد الباقية
    final tp = parseNum(targetP.text), rn = parseNum(remN.text).round(), rf = parseNum(remF.text, 100);
    double? needAvg;
    if (tp > 0 && rn > 0 && rf > 0) {
      final remFull = rn * rf;
      final needMarks = tp / 100 * (full + remFull) - got;
      needAvg = needMarks / remFull * 100;
    }
    rows.sort((a, b) => b.$2.compareTo(a.$2));

    return [
      ResultHero(
        label: t('النسبة المئوية', 'النسبة المئوية', 'Percentage'),
        value: pct == null ? '—' : '${fmt(pct, 2)}%',
        sub: pct == null ? t('أكتب درجاتك في المواد', 'أدخل درجاتك في المواد', 'Enter your subject marks') : '${letter!.$1} • ${fmt(got, 1)} / ${fmt(full, 0)}',
        colors: const [Color(0xFF007229), Color(0xFF0E8C84), Color(0xFF3A1F0C)],
      ),
      SCard(
        title: t('المواد', 'المواد', 'Subjects'),
        icon: Icons.menu_book_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < subjects.length; i++) _subjectRow(i),
          OutlinedButton.icon(
            onPressed: subjects.length >= 20
                ? null
                : () {
                    subjects.add(_Subject({'f': subjects.isEmpty ? '100' : subjects.last.f.text}));
                    _save();
                  },
            icon: const Icon(Icons.add_rounded),
            label: Text(t('ضيف مادة', 'أضف مادة', 'Add subject')),
          ),
        ]),
      ),
      if (rows.length >= 2)
        SCard(
          title: t('أحسن وأضعف مادة', 'أفضل وأضعف مادة', 'Best & weakest'),
          icon: Icons.insights_rounded,
          color: SD.teal,
          child: Column(children: [
            InfoRow('🏆 ${rows.first.$1.isEmpty ? t('مادة', 'مادة', 'Subject') : rows.first.$1}', '${fmt(rows.first.$2, 1)}%', valueColor: SD.green),
            InfoRow('📉 ${rows.last.$1.isEmpty ? t('مادة', 'مادة', 'Subject') : rows.last.$1}', '${fmt(rows.last.$2, 1)}%', valueColor: rows.last.$2 < 50 ? SD.red : SD.gold),
          ]),
        ),
      SCard(
        title: t('عايز تجيب كم؟', 'ما النسبة المستهدفة؟', 'Hit a target %'),
        icon: Icons.flag_rounded,
        color: SD.orange,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField(t('النسبة المستهدفة', 'النسبة المستهدفة', 'Target percentage'), targetP, suffix: '%', onChanged: (_) => _save()),
          Row(children: [
            Expanded(child: NumField(t('مواد فاضلة', 'المواد المتبقية', 'Remaining subjects'), remN, decimal: false, onChanged: (_) => _save())),
            const SizedBox(width: 8),
            Expanded(child: NumField(t('الدرجة الكاملة لكل مادة', 'الدرجة الكاملة لكل مادة', 'Full mark each'), remF, onChanged: (_) => _save())),
          ]),
          if (needAvg != null)
            NoteBox(
              needAvg > 100
                  ? t('للأسف الهدف دا ما ممكن — محتاج ${fmt(needAvg, 1)}% في الباقي. جرّب هدف أقل.', 'للأسف لا يمكن بلوغ هذا الهدف — تحتاج ${fmt(needAvg, 1)}% في المتبقي. جرّب هدفًا أقل.',
                      'Not reachable — you would need ${fmt(needAvg, 1)}% in the rest. Try a lower target.')
                  : needAvg <= 0
                      ? t('مبروك، ضامن الهدف حتى لو ما جبت حاجة 😄', 'هدفك مضمون مهما كانت درجاتك القادمة 😄', 'Target secured no matter what 😄')
                      : t('محتاج متوسط ${fmt(needAvg, 1)}% في المواد الباقية (${fmt(needAvg * rf / 100, 1)} من ${fmt(rf, 0)} في كل مادة)',
                          'تحتاج متوسط ${fmt(needAvg, 1)}% في المواد المتبقية (${fmt(needAvg * rf / 100, 1)} من ${fmt(rf, 0)} لكل مادة)',
                          'You need an average of ${fmt(needAvg, 1)}% in the remaining subjects (${fmt(needAvg * rf / 100, 1)} of ${fmt(rf, 0)} each)'),
              kind: needAvg > 100 ? NoteKind.warn : NoteKind.tip,
            ),
        ]),
      ),
      if (pct != null)
        ShareBar(() => [
              '📚 ${t('نتيجتي', 'نتيجتي', 'My results')}',
              for (final s in subjects)
                if (parseNum(s.f.text) > 0 && s.m.text.trim().isNotEmpty) '• ${s.n.text.trim().isEmpty ? t('مادة', 'مادة', 'Subject') : s.n.text.trim()}: ${s.m.text}/${s.f.text}',
              '${t('النسبة', 'النسبة', 'Percentage')}: ${fmt(pct, 2)}% (${letter!.$1})',
            ].join('\n')),
      const SizedBox(height: 12),
      NoteBox(
          t('التقديرات (A ≥ 90، B ≥ 80…) عامة — كل نظام تعليمي ليه سلّمو، وبعض الشهادات بتحسب أحسن مواد بس.',
              'التقديرات (A ≥ 90، B ≥ 80…) عامة — لكل نظام تعليمي سلّمه، وبعض الشهادات تحتسب أفضل المواد فقط.',
              'Letter bands (A ≥ 90, B ≥ 80…) are generic — each system has its own, and some certificates count only the best subjects.'),
          kind: NoteKind.info),
    ];
  }

  Widget _subjectRow(int i) {
    final s = subjects[i];
    final f = parseNum(s.f.text), m = parseNum(s.m.text);
    final p = f > 0 && s.m.text.trim().isNotEmpty ? m / f * 100 : null;
    return Padding(
      key: ObjectKey(s),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 4,
          child: TextField(
            controller: s.n,
            onChanged: (_) => _save(),
            decoration: InputDecoration(labelText: '${t('المادة', 'المادة', 'Subject')} ${i + 1}', isDense: true, helperText: p == null ? null : '${fmt(p, 1)}%'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: TextField(
            controller: s.m,
            onChanged: (_) => _save(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: InputDecoration(labelText: t('الدرجة', 'الدرجة', 'Mark'), isDense: true, errorText: p != null && p > 100 ? '>' : null),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: TextField(
            controller: s.f,
            onChanged: (_) => _save(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: InputDecoration(labelText: t('من', 'من', 'Out of'), isDense: true),
          ),
        ),
        MiniIconBtn(Icons.close_rounded,
            onTap: subjects.length <= 1
                ? null
                : () {
                    final r = subjects.removeAt(i);
                    _disposeLater(r.dispose);
                    _save();
                  }),
      ]),
    );
  }
}
