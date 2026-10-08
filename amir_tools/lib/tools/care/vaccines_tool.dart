import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'care_common.dart';
import 'care_notify.dart';

/// اقتراح عام للبالغين (ليس جدولًا رسميًا)
class AdultSuggestion {
  final String ar, en, noteAr, noteEn;
  final bool vaccine;
  final int months;
  const AdultSuggestion(this.ar, this.en, this.vaccine, this.months, this.noteAr, this.noteEn);
  String get name => tr(ar, en);
  String get note => tr(noteAr, noteEn);
}

/// اقتراحات عامة متعارف عليها للبالغين فقط — جدول الأطفال في أداة «متابعة نمو الطفل»
const adultSuggestions = [
  AdultSuggestion('جرعة منشّطة للكزاز والدفتيريا (Td)', 'Tetanus–diphtheria booster (Td/Tdap)', true, 120,
      'للبالغين: جرعة منشّطة كل 10 سنوات (وقد يعطيها الطبيب أبكر بعد جرح ملوّث).', 'Adults: a booster every 10 years (a doctor may give it sooner after a dirty wound).'),
  AdultSuggestion('لقاح الإنفلونزا الموسمية', 'Seasonal flu vaccine', true, 12,
      'سنويًا، خاصة لكبار السن والحوامل وأصحاب الأمراض المزمنة والعاملين الصحيين.', 'Yearly, especially for older people, pregnant women, people with chronic illness and health workers.'),
  AdultSuggestion('قياس ضغط الدم', 'Blood pressure check', false, 12,
      'مرة في السنة على الأقل للبالغين، وأكثر لمن عنده ضغط أو عوامل خطر.', 'At least once a year for adults; more often with hypertension or risk factors.'),
  AdultSuggestion('السكر التراكمي HbA1c (لمرضى السكري)', 'HbA1c blood sugar test (diabetics)', false, 6,
      'لمرضى السكري: كل 3–6 أشهر حسب ما يحدده الطبيب.', 'For diabetics: every 3–6 months as your doctor decides.'),
  AdultSuggestion('فحص الأسنان', 'Dental check-up', false, 6,
      'كل 6–12 شهرًا أو حسب نصيحة طبيب الأسنان.', 'Every 6–12 months or as your dentist advises.'),
  AdultSuggestion('فحص العيون', 'Eye check-up', false, 12,
      'سنويًا لمرضى السكري (فحص الشبكية)، وللآخرين حسب نصيحة طبيب العيون.', 'Yearly for diabetics (retina exam); others as the eye doctor advises.'),
];

/// موعد الاستحقاق القادم لسجل
DateTime? vaccineNextDue(Map r) {
  final explicit = cParse(r['next']);
  if (explicit != null) return explicit;
  final done = cParse(r['done']);
  final every = cInt(r['every']);
  if (done != null && every > 0) return addMonths(done, every);
  return null;
}

class VaccinesTool extends StatefulWidget {
  const VaccinesTool({super.key});
  @override
  State<VaccinesTool> createState() => _VaccinesToolState();
}

class _VaccinesToolState extends State<VaccinesTool> {
  String _member = ''; // '' = الكل

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = context.read<AppState>();
      if (_records(s).any((r) => r['notify'] != false)) _reschedule(s);
    });
  }

  List<Map<String, dynamic>> _members(AppState s) => cList(s.getData<List>('vaccines_members'));
  List<Map<String, dynamic>> _records(AppState s) => cList(s.getData<List>('vaccines_records'));

  String _memberName(List<Map<String, dynamic>> ms, dynamic id) => cStr(ms.firstWhere((m) => m['id'] == id, orElse: () => {'name': '—'})['name']);

  Future<void> _reschedule(AppState s) async {
    final ms = _members(s);
    final alarms = <CareAlarm>[];
    for (final r in _records(s)) {
      if (r['notify'] == false) continue;
      final due = vaccineNextDue(r);
      if (due == null) continue;
      final who = _memberName(ms, r['m']);
      final title = '💉 ${r['name']} — $who';
      alarms.add(CareAlarm(title, DateTime(due.year, due.month, due.day - 7, 9), body: t('باقي أسبوع على الموعد', 'تبقّى أسبوع على الموعد', 'Due in one week')));
      alarms.add(CareAlarm(title, DateTime(due.year, due.month, due.day, 9), body: t('الموعد الليلة', 'الموعد اليوم', 'Due today')));
    }
    await CareNotifier.checkups.schedule(s, alarms);
  }

  void _save(AppState s, List<Map<String, dynamic>> recs) {
    s.setData('vaccines_records', recs);
    _reschedule(s);
    setState(() {});
  }

  Future<void> _addMember(AppState s) async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('ضيف فرد من الأسرة', 'إضافة فرد من الأسرة', 'Add family member')),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(labelText: tr('الاسم', 'Name'), hintText: t('مثلًا: أبوي، حاجة فاطمة', 'مثلًا: أبي، فاطمة', 'e.g. Dad, Fatima'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(t('ضيف', 'إضافة', 'Add'))),
        ],
      ),
    );
    c.dispose();
    if (name == null || name.isEmpty) return;
    final ms = _members(s)..add({'id': cId(), 'name': name});
    s.setData('vaccines_members', ms);
    setState(() => _member = ms.last['id']);
  }

  Future<void> _deleteMember(AppState s, Map m) async {
    if (!await confirmDelete(context, cStr(m['name']))) return;
    s.setData('vaccines_members', _members(s)..removeWhere((x) => x['id'] == m['id']));
    _save(s, _records(s)..removeWhere((r) => r['m'] == m['id']));
    setState(() => _member = '');
  }

  Future<void> _edit(AppState s, {Map<String, dynamic>? rec, AdultSuggestion? tpl}) async {
    var ms = _members(s);
    if (ms.isEmpty) {
      await _addMember(s);
      ms = _members(s);
      if (ms.isEmpty) return;
    }
    if (!mounted) return;
    final r = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RecordEditor(members: ms, initial: rec, tpl: tpl, member: _member.isEmpty ? ms.first['id'] : _member),
    );
    if (r == null || !mounted) return;
    final recs = _records(s);
    final i = recs.indexWhere((x) => x['id'] == r['id']);
    if (i >= 0) {
      recs[i] = r;
    } else {
      recs.add(r);
      s.award(5, t('ضفت لقاح/فحص', 'إضافة لقاح/فحص', 'Added a vaccine/check-up'));
    }
    _save(s, recs);
    if (r['notify'] != false && CareNotifier.supported) {
      final ok = await CareNotifier.requestPermission();
      if (!ok) toast(t('فعّل الإشعارات من ضبط التلفون عشان التذكير يشتغل', 'فعّل الإشعارات من إعدادات الهاتف ليعمل التذكير', 'Enable notifications in phone settings for reminders'));
    }
  }

  Future<void> _markDone(AppState s, Map<String, dynamic> r) async {
    final d = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        var when = cToday();
        return StatefulBuilder(
          builder: (ctx, setD) => AlertDialog(
            title: Text(t('اتعمل «${r['name']}»؟', 'تم «${r['name']}»؟', 'Done “${r['name']}”?')),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              DateButton(label: t('اتعمل يوم', 'تاريخ الإنجاز', 'Done on'), value: when, clearable: false, last: cToday(), onChanged: (v) => setD(() => when = v ?? when)),
              if (cInt(r['every']) > 0)
                Text('${t('الموعد الجاي', 'الموعد القادم', 'Next due')}: ${cDate(addMonths(when, cInt(r['every'])))}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('إلغاء', 'Cancel'))),
              FilledButton(onPressed: () => Navigator.pop(ctx, when), child: Text(t('تمام', 'تأكيد', 'Confirm'))),
            ],
          ),
        );
      },
    );
    if (d == null) return;
    final recs = _records(s);
    final i = recs.indexWhere((x) => x['id'] == r['id']);
    if (i < 0) return;
    final hist = List<String>.from(recs[i]['hist'] ?? [])..add(cKey(d));
    hist.sort();
    recs[i]
      ..['done'] = cKey(d)
      ..['hist'] = hist.length > 30 ? hist.sublist(hist.length - 30) : hist;
    // موعد صريح انتهى ← يُحسب من الفترة إن وُجدت
    recs[i]['next'] = null;
    s.bump('checkups_done');
    s.awardDaily('vaccines_done', 10, t('سجّلت لقاح/فحص', 'تسجيل لقاح/فحص', 'Logged a vaccine/check-up'));
    _save(s, recs);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ms = _members(s);
    if (_member.isNotEmpty && !ms.any((m) => m['id'] == _member)) _member = '';
    final all = _records(s);
    final recs = _member.isEmpty ? all : all.where((r) => r['m'] == _member).toList();
    final today = cToday();

    final due = <(Map<String, dynamic>, DateTime, int)>[];
    final noDate = <Map<String, dynamic>>[];
    for (final r in recs) {
      final d = vaccineNextDue(r);
      if (d == null) {
        noDate.add(r);
      } else {
        due.add((r, d, cDays(today, d)));
      }
    }
    due.sort((a, b) => a.$2.compareTo(b.$2));
    final overdue = due.where((e) => e.$3 < 0).length;
    final soon = due.where((e) => e.$3 >= 0 && e.$3 <= 30).length;
    final doneYear = recs.fold<int>(0, (a, r) => a + List<String>.from(r['hist'] ?? []).where((k) => k.startsWith('${today.year}-')).length);
    final recent = <(Map<String, dynamic>, DateTime)>[
      for (final r in recs)
        for (final k in List<String>.from(r['hist'] ?? [])) if (cParse(k) != null) (r, cParse(k)!),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    String summary() {
      final b = StringBuffer('💉 ${t('اللقاحات والفحوصات', 'اللقاحات والفحوصات', 'Vaccines & check-ups')}\n');
      for (final e in due) {
        b.writeln('• ${e.$1['name']} — ${_memberName(ms, e.$1['m'])}: ${cDate(e.$2)} (${cDueLabel(e.$3)})');
      }
      for (final r in noDate) {
        b.writeln('• ${r['name']} — ${_memberName(ms, r['m'])}: ${t('بدون موعد', 'بلا موعد', 'no date')}');
      }
      return b.toString().trim();
    }

    return ToolList(children: [
      ResultHero(
        label: t('مواعيد الأسرة الصحية', 'مواعيد الأسرة الصحية', "Family health due dates"),
        value: overdue > 0 ? '$overdue ${t('متأخر', 'متأخر', 'overdue')}' : (due.isEmpty ? '—' : cDueLabel(due.first.$3)),
        sub: due.isEmpty
            ? t('ضيف لقاح أو فحص عشان نذكّرك', 'أضف لقاحًا أو فحصًا لنذكّرك', 'Add a vaccine or check-up to get reminders')
            : '${t('الجاي', 'القادم', 'Next')}: ${due.firstWhere((e) => e.$3 >= 0, orElse: () => due.first).$1['name']} — ${cDate(due.firstWhere((e) => e.$3 >= 0, orElse: () => due.first).$2)}',
        colors: const [Color(0xFF0E8C84), Color(0xFF0B5C8A), Color(0xFF3A1F0C)],
      ),
      StatGrid([
        StatChip('${recs.length}', t('السجلات', 'السجلات', 'Records'), color: SD.nile, icon: Icons.list_alt_rounded),
        StatChip('$overdue', t('متأخرة', 'متأخرة', 'Overdue'), color: SD.red, icon: Icons.warning_amber_rounded),
        StatChip('$soon', t('خلال 30 يوم', 'خلال 30 يومًا', 'Within 30 days'), color: SD.orange, icon: Icons.schedule_rounded),
      ]),
      const SizedBox(height: 12),
      SCard(
        title: t('أفراد الأسرة', 'أفراد الأسرة', 'Family members'),
        icon: Icons.groups_rounded,
        color: SD.teal,
        child: Wrap(spacing: 8, runSpacing: 6, children: [
          ChoiceChip(label: Text(t('الكل', 'الكل', 'All')), selected: _member.isEmpty, onSelected: (_) => setState(() => _member = '')),
          for (final m in ms)
            GestureDetector(
              onLongPress: () => _deleteMember(s, m),
              child: ChoiceChip(
                label: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 160), child: Text(cStr(m['name']), maxLines: 1, overflow: TextOverflow.ellipsis)),
                selected: _member == m['id'],
                onSelected: (_) => setState(() => _member = m['id']),
              ),
            ),
          ActionChip(avatar: const Icon(Icons.person_add_alt_1_rounded, size: 18), label: Text(t('فرد جديد', 'فرد جديد', 'New member')), onPressed: () => _addMember(s)),
        ]),
      ),
      if (ms.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(t('اضغط مطوّلًا على الاسم عشان تمسحه', 'اضغط مطوّلًا على الاسم لحذفه', 'Long-press a name to delete it'),
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))),
        ),
      SCard(
        title: t('المواعيد مرتّبة', 'المواعيد مرتبة', 'Due list'),
        icon: Icons.event_note_rounded,
        color: SD.nile,
        trailing: IconButton(tooltip: t('ضيف', 'إضافة', 'Add'), onPressed: () => _edit(s), icon: const Icon(Icons.add_circle_rounded)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (due.isEmpty && noDate.isEmpty)
            Text(t('لسه ما في سجلات. ضيف من الزر + أو من الاقتراحات تحت.', 'لا توجد سجلات بعد. أضف من الزر + أو من الاقتراحات بالأسفل.', 'No records yet. Add with + or from the suggestions below.')),
          for (final e in due)
            CTile(
              icon: e.$1['kind'] == 'chk' ? Icons.monitor_heart_rounded : Icons.vaccines_rounded,
              color: cDueColor(e.$3),
              title: cStr(e.$1['name']),
              sub: '${_memberName(ms, e.$1['m'])} • ${cDate(e.$2)}${cInt(e.$1['every']) > 0 ? ' • ${t('كل', 'كل', 'every')} ${cInt(e.$1['every'])} ${t('شهر', 'شهر', 'mo')}' : ''}',
              badge: cDueLabel(e.$3),
              badgeColor: cDueColor(e.$3),
              onTap: () => _edit(s, rec: e.$1),
              actions: [
                IconButton(tooltip: t('اتعمل', 'تم', 'Mark done'), onPressed: () => _markDone(s, e.$1), icon: const Icon(Icons.check_circle_rounded, color: SD.green)),
              ],
            ),
          for (final r in noDate)
            CTile(
              icon: Icons.help_outline_rounded,
              color: SD.coffee,
              title: cStr(r['name']),
              sub: '${_memberName(ms, r['m'])} • ${t('حدّد الموعد أو الفترة', 'حدد الموعد أو الفترة', 'Set a date or interval')}',
              onTap: () => _edit(s, rec: r),
              actions: [IconButton(tooltip: t('اتعمل', 'تم', 'Mark done'), onPressed: () => _markDone(s, r), icon: const Icon(Icons.check_circle_rounded, color: SD.green))],
            ),
          if (due.isNotEmpty || noDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            ShareBar(summary),
          ],
        ]),
      ),
      if (recent.isNotEmpty)
        SCard(
          title: t('آخر الإنجازات', 'آخر ما تم', 'Recently done'),
          icon: Icons.history_rounded,
          color: SD.green,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CBar(t('اتعمل السنة دي', 'تم هذا العام', 'Done this year'), recs.isEmpty ? 0 : doneYear / (recs.length).clamp(1, 1 << 30), color: SD.green, trailing: '$doneYear'),
            for (final e in recent.take(10))
              InfoRow(cStr(e.$1['name']), cDate(e.$2), hint: _memberName(ms, e.$1['m']), icon: Icons.check_rounded),
          ]),
        ),
      SCard(
        title: t('اقتراحات عامة للكبار', 'اقتراحات عامة للبالغين', 'General suggestions for adults'),
        icon: Icons.tips_and_updates_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NoteBox(
            t('دي اقتراحات عامة بس — اتّبع كلام دكتورك وجدول وزارة الصحة في بلدك.', 'هذه اقتراحات عامة فقط — اتبع طبيبك والجدول الوطني لوزارة الصحة في بلدك.',
                'General suggestions only — follow your doctor and your national health schedule.'),
            kind: NoteKind.warn,
          ),
          for (final g in adultSuggestions)
            CTile(
              icon: g.vaccine ? Icons.vaccines_rounded : Icons.monitor_heart_rounded,
              color: g.vaccine ? SD.teal : SD.indigo,
              title: g.name,
              sub: g.note,
              actions: [IconButton(tooltip: t('ضيف', 'إضافة', 'Add'), onPressed: () => _edit(s, tpl: g), icon: const Icon(Icons.add_rounded))],
            ),
        ]),
      ),
      NoteBox(
        t('تطعيمات الأطفال وجدولها موجودة في أداة «متابعة نمو الطفل» — ما كررناها هنا.', 'تطعيمات الأطفال وجدولها موجودة في أداة «متابعة نمو الطفل» — لم نكررها هنا.',
            "Children's vaccination schedule lives in the «Child Growth» tool — not repeated here."),
        kind: NoteKind.tip,
      ),
      NoteBox(
        t('التذكير بيجيك قبل أسبوع ويوم الموعد الساعة 9 الصباح. البيانات محفوظة في تلفونك بس.', 'يصلك التذكير قبل أسبوع ويوم الموعد الساعة 9 صباحًا. البيانات محفوظة على هاتفك فقط.',
            'Reminders come one week before and on the due day at 9 AM. Data stays on your phone only.'),
      ),
    ]);
  }
}

class _RecordEditor extends StatefulWidget {
  final List<Map<String, dynamic>> members;
  final Map<String, dynamic>? initial;
  final AdultSuggestion? tpl;
  final String member;
  const _RecordEditor({required this.members, this.initial, this.tpl, required this.member});
  @override
  State<_RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<_RecordEditor> {
  late final _name = TextEditingController(text: widget.initial?['name'] ?? widget.tpl?.name ?? '');
  late final _notes = TextEditingController(text: widget.initial?['notes'] ?? widget.tpl?.note ?? '');
  late final _every = TextEditingController(text: () {
    final e = cInt(widget.initial?['every'], widget.tpl?.months ?? 0);
    return e > 0 ? '$e' : '';
  }());
  late String _m = widget.initial?['m'] ?? widget.member;
  late String _kind = widget.initial?['kind'] ?? (widget.tpl == null ? 'vac' : (widget.tpl!.vaccine ? 'vac' : 'chk'));
  late DateTime? _done = cParse(widget.initial?['done']);
  late DateTime? _next = cParse(widget.initial?['next']);
  late bool _useDate = cParse(widget.initial?['next']) != null;
  late bool _notify = widget.initial?['notify'] != false;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _every.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final every = parseNum(_every.text).toInt();
    final computed = !_useDate && _done != null && every > 0 ? addMonths(_done!, every) : null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.initial == null ? t('لقاح أو فحص جديد', 'لقاح أو فحص جديد', 'New vaccine or check-up') : t('تعديل', 'تعديل', 'Edit'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: widget.members.any((m) => m['id'] == _m) ? _m : widget.members.first['id'],
            isExpanded: true,
            decoration: InputDecoration(labelText: t('لمنو؟', 'لمن؟', 'For whom?')),
            items: [for (final m in widget.members) DropdownMenuItem(value: m['id'] as String, child: Text(cStr(m['name']), maxLines: 1, overflow: TextOverflow.ellipsis))],
            onChanged: (v) => setState(() => _m = v ?? _m),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'vac', icon: const Icon(Icons.vaccines_rounded), label: Text(tr('لقاح', 'Vaccine'))),
              ButtonSegment(value: 'chk', icon: const Icon(Icons.monitor_heart_rounded), label: Text(tr('فحص', 'Check-up'))),
            ],
            selected: {_kind},
            onSelectionChanged: (v) => setState(() => _kind = v.first),
          ),
          const SizedBox(height: 10),
          CField(tr('الاسم', 'Name'), _name, hint: t('مثلًا: لقاح الكبد، فحص الكوليسترول', 'مثلًا: لقاح الكبد، فحص الكوليسترول', 'e.g. Hepatitis B, cholesterol test')),
          DateButton(label: t('آخر مرة اتعمل', 'آخر مرة', 'Last done'), value: _done, last: cToday(), onChanged: (v) => setState(() => _done = v)),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(t('كل كم شهر', 'كل عدة أشهر', 'Interval'))),
              ButtonSegment(value: true, label: Text(t('تاريخ محدد', 'تاريخ محدد', 'Fixed date'))),
            ],
            selected: {_useDate},
            onSelectionChanged: (v) => setState(() => _useDate = v.first),
          ),
          const SizedBox(height: 10),
          if (_useDate)
            DateButton(label: t('الموعد الجاي', 'الموعد القادم', 'Next due'), value: _next, onChanged: (v) => setState(() => _next = v))
          else ...[
            NumField(t('يتكرر كل (شهر)', 'يتكرر كل (شهر)', 'Repeats every (months)'), _every, decimal: false, onChanged: (_) => setState(() {})),
            if (computed != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('${t('الموعد الجاي', 'الموعد القادم', 'Next due')}: ${cDate(computed)}', style: const TextStyle(fontWeight: FontWeight.w800)),
              )
            else if (every > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(t('حدّد «آخر مرة» عشان نحسب الموعد', 'حدد «آخر مرة» لحساب الموعد', 'Set “Last done” to compute the due date'), style: const TextStyle(fontSize: 12.5)),
              ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _notify,
            onChanged: (v) => setState(() => _notify = v),
            title: Text(t('ذكّرني', 'ذكّرني', 'Remind me')),
            subtitle: Text(t('قبل أسبوع ويوم الموعد', 'قبل أسبوع ويوم الموعد', 'A week before and on the day')),
          ),
          CField(t('ملاحظات', 'ملاحظات', 'Notes'), _notes, maxLines: 3),
          const SizedBox(height: 6),
          FilledButton.icon(
            onPressed: () {
              final name = _name.text.trim();
              if (name.isEmpty) {
                toast(t('أكتب الاسم', 'اكتب الاسم', 'Enter a name'));
                return;
              }
              Navigator.pop(context, {
                'id': widget.initial?['id'] ?? cId(),
                'm': _m,
                'name': name,
                'kind': _kind,
                'done': _done == null ? null : cKey(_done!),
                'next': _useDate && _next != null ? cKey(_next!) : null,
                'every': every.clamp(0, 600),
                'notify': _notify,
                'notes': _notes.text.trim(),
                'hist': List<String>.from(widget.initial?['hist'] ?? (_done == null ? [] : [cKey(_done!)])),
              });
            },
            icon: const Icon(Icons.save_rounded),
            label: Text(t('احفظ', 'حفظ', 'Save')),
          ),
        ]),
      ),
    );
  }
}
