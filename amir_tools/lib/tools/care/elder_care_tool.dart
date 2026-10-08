import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'care_common.dart';
import 'care_notify.dart';

const moodEmojis = ['😞', '😕', '😐', '🙂', '😄'];
List<String> get moodLabels => [
      t('تعبان شديد', 'متعب جدًا', 'Very low'),
      t('مش تمام', 'ليس بخير', 'Low'),
      t('عادي', 'عادي', 'Okay'),
      t('كويس', 'جيد', 'Good'),
      t('تمام التمام', 'ممتاز', 'Great'),
    ];

/// ملخص حالة كبير السن للمشاركة في قروب الأسرة
String elderSummary(Map e, DateTime today) {
  final b = StringBuffer('👴 ${t('أخبار', 'أخبار', 'Update on')} ${e['name']} — ${cDate(today)}\n');
  final meds = cList(e['meds']);
  final taken = List<String>.from((e['taken'] is Map ? e['taken'][cKey(today)] : null) ?? []);
  var total = 0;
  for (final m in meds) {
    total += List.from(m['times'] ?? []).length;
  }
  if (meds.isNotEmpty) b.writeln('💊 ${t('الدواء الليلة', 'أدوية اليوم', "Today's doses")}: ${taken.length}/$total');
  final log = cList(e['log']).where((l) => l['d'] == cKey(today)).firstOrNull;
  if (log != null) {
    final mood = cInt(log['mood'], 2).clamp(0, 4);
    b.writeln('${moodEmojis[mood]} ${t('المزاج', 'الحالة', 'Mood')}: ${moodLabels[mood]}');
    if (cStr(log['bp']).isNotEmpty) b.writeln('🩺 ${t('الضغط', 'الضغط', 'BP')}: ${log['bp']}');
    if (cStr(log['sugar']).isNotEmpty) b.writeln('🩸 ${t('السكر', 'السكر', 'Sugar')}: ${log['sugar']}');
    if (cStr(log['note']).isNotEmpty) b.writeln('📝 ${log['note']}');
  }
  final now = DateTime.now();
  final next = cList(e['appts']).where((a) => cInt(a['at']) > now.millisecondsSinceEpoch).toList()..sort((a, b) => cInt(a['at']).compareTo(cInt(b['at'])));
  if (next.isNotEmpty) {
    final at = DateTime.fromMillisecondsSinceEpoch(cInt(next.first['at']));
    b.writeln('📅 ${t('المراجعة الجاية', 'الموعد القادم', 'Next appointment')}: ${next.first['title']} — ${cDate(at)} ${fmtTimeAr(at)}');
  }
  return b.toString().trim();
}

class ElderCareTool extends StatefulWidget {
  const ElderCareTool({super.key});
  @override
  State<ElderCareTool> createState() => _ElderCareToolState();
}

class _ElderCareToolState extends State<ElderCareTool> {
  String _sel = '';
  int _mood = 3;
  final _bp = TextEditingController(), _sugar = TextEditingController(), _note = TextEditingController();
  String _loadedFor = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = context.read<AppState>();
      if (_elders(s).isNotEmpty) _reschedule(s);
    });
  }

  @override
  void dispose() {
    _bp.dispose();
    _sugar.dispose();
    _note.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _elders(AppState s) => cList(s.getData<List>('elder_care_list'));

  Future<void> _reschedule(AppState s) async {
    final alarms = <CareAlarm>[];
    for (final e in _elders(s)) {
      for (final m in cList(e['meds'])) {
        if (m['notify'] == false) continue;
        for (final mins in List.from(m['times'] ?? []).map((x) => cInt(x))) {
          alarms.add(CareAlarm('💊 ${e['name']}: ${m['n']}', DateTime(2000, 1, 1, mins ~/ 60, mins % 60), body: cStr(m['d']).isEmpty ? null : cStr(m['d']), daily: true));
        }
      }
      for (final a in cList(e['appts'])) {
        if (a['notify'] == false) continue;
        final at = DateTime.fromMillisecondsSinceEpoch(cInt(a['at']));
        final title = '📅 ${e['name']}: ${a['title']}';
        final where = [cStr(a['doctor']), cStr(a['place'])].where((x) => x.isNotEmpty).join(' — ');
        alarms.add(CareAlarm(title, DateTime(at.year, at.month, at.day - 1, 20), body: '${t('بكرة', 'غدًا', 'Tomorrow')} ${fmtTimeAr(at)} $where'.trim()));
        alarms.add(CareAlarm(title, at.subtract(const Duration(hours: 2)), body: '${t('بعد ساعتين', 'بعد ساعتين', 'In 2 hours')} $where'.trim()));
      }
    }
    await CareNotifier.elder.schedule(s, alarms);
  }

  void _saveElder(AppState s, Map<String, dynamic> e, {bool notify = false}) {
    final l = _elders(s);
    final i = l.indexWhere((x) => x['id'] == e['id']);
    if (i >= 0) {
      l[i] = e;
    } else {
      l.add(e);
    }
    s.setData('elder_care_list', l);
    if (notify) _reschedule(s);
    setState(() {});
  }

  Future<void> _permission() async {
    if (!CareNotifier.supported) return;
    final ok = await CareNotifier.requestPermission();
    if (!ok) toast(t('فعّل الإشعارات من ضبط التلفون عشان التذكير يشتغل', 'فعّل الإشعارات من إعدادات الهاتف ليعمل التذكير', 'Enable notifications in phone settings for reminders'));
  }

  Future<Map<String, String>?> _form(String title, List<(String key, String label, TextInputType kb)> fields, [Map? init]) async {
    final cs = {for (final f in fields) f.$1: TextEditingController(text: cStr(init?[f.$1]))};
    final r = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final f in fields) CField(f.$2, cs[f.$1]!, keyboard: f.$3, ltr: f.$3 == TextInputType.phone),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, {for (final e in cs.entries) e.key: e.value.text.trim()}), child: Text(t('احفظ', 'حفظ', 'Save'))),
        ],
      ),
    );
    for (final c in cs.values) {
      c.dispose();
    }
    return r;
  }

  Future<void> _addElder(AppState s, [Map<String, dynamic>? e]) async {
    final r = await _form(e == null ? t('ضيف كبير سن', 'إضافة كبير سن', 'Add an elder') : t('تعديل', 'تعديل', 'Edit'), [
      ('name', tr('الاسم', 'Name'), TextInputType.text),
      ('age', t('العمر', 'العمر', 'Age'), TextInputType.number),
      ('notes', t('ملاحظات (أمراض، حساسية…)', 'ملاحظات (أمراض، حساسية…)', 'Notes (conditions, allergies…)'), TextInputType.text),
    ], e);
    if (r == null || r['name']!.isEmpty) return;
    final x = e ?? <String, dynamic>{'id': cId(), 'meds': [], 'appts': [], 'log': [], 'cg': [], 'taken': {}};
    x.addAll(r);
    _saveElder(s, x);
    if (e == null) s.award(5, t('ضفت كبير سن للرعاية', 'إضافة كبير سن للرعاية', 'Added an elder'));
    setState(() => _sel = x['id']);
  }

  Future<void> _addMed(AppState s, Map<String, dynamic> e, [Map<String, dynamic>? med]) async {
    final r = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MedSheet(initial: med),
    );
    if (r == null) return;
    final meds = cList(e['meds']);
    final i = meds.indexWhere((x) => x['id'] == r['id']);
    if (r['_del'] == true) {
      if (i >= 0) meds.removeAt(i);
      e['meds'] = meds;
      _saveElder(s, e, notify: true);
      return;
    }
    if (i >= 0) {
      meds[i] = r;
    } else {
      meds.add(r);
    }
    e['meds'] = meds;
    _saveElder(s, e, notify: true);
    if (r['notify'] != false) await _permission();
  }

  Future<void> _addAppt(AppState s, Map<String, dynamic> e, [Map<String, dynamic>? a]) async {
    final r = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ApptSheet(initial: a),
    );
    if (r == null) return;
    final l = cList(e['appts']);
    final i = l.indexWhere((x) => x['id'] == r['id']);
    if (i >= 0) {
      l[i] = r;
    } else {
      l.add(r);
    }
    e['appts'] = l;
    _saveElder(s, e, notify: true);
    if (r['notify'] != false) await _permission();
  }

  Future<void> _addCg(AppState s, Map<String, dynamic> e, [Map<String, dynamic>? c]) async {
    final r = await _form(t('زول بيرعى', 'مقدّم رعاية', 'Caregiver'), [
      ('name', tr('الاسم', 'Name'), TextInputType.text),
      ('phone', t('التلفون', 'الهاتف', 'Phone'), TextInputType.phone),
      ('role', t('الدور (ولد، ممرض، جار…)', 'الدور (ابن، ممرض، جار…)', 'Role (son, nurse, neighbour…)'), TextInputType.text),
    ], c);
    if (r == null || r['name']!.isEmpty) return;
    final l = cList(e['cg']);
    final i = c == null ? -1 : l.indexWhere((x) => x['id'] == c['id']);
    if (i >= 0) {
      l[i] = {...l[i], ...r};
    } else {
      l.add({'id': cId(), ...r});
    }
    e['cg'] = l;
    _saveElder(s, e);
  }

  void _toggleDose(AppState s, Map<String, dynamic> e, String key) {
    final today = cKey(cToday());
    final taken = Map<String, dynamic>.from(e['taken'] is Map ? e['taken'] : {});
    final l = List<String>.from(taken[today] ?? []);
    if (l.contains(key)) {
      l.remove(key);
    } else {
      l.add(key);
      s.bump('elder_doses');
      s.awardDaily('elder_care_dose', 5, t('تابعت دواء كبير السن', 'متابعة دواء كبير السن', "Tracked an elder's dose"));
    }
    taken[today] = l;
    final keys = taken.keys.toList()..sort();
    for (final k in keys.take(keys.length > 30 ? keys.length - 30 : 0)) {
      taken.remove(k);
    }
    e['taken'] = taken;
    _saveElder(s, e);
  }

  void _saveCheckin(AppState s, Map<String, dynamic> e) {
    final today = cKey(cToday());
    final log = cList(e['log'])..removeWhere((l) => l['d'] == today);
    log.add({'d': today, 'mood': _mood, 'bp': _bp.text.trim(), 'sugar': _sugar.text.trim(), 'note': _note.text.trim()});
    log.sort((a, b) => cStr(a['d']).compareTo(cStr(b['d'])));
    e['log'] = log.length > 120 ? log.sublist(log.length - 120) : log;
    _saveElder(s, e);
    s.awardDaily('elder_care_checkin', 10, t('سجّلت اطمئنان اليوم', 'تسجيل اطمئنان اليوم', 'Daily check-in'));
    toast(t('اتسجّل ✓', 'تم التسجيل ✓', 'Saved ✓'));
  }

  void _loadCheckin(Map<String, dynamic> e) {
    final key = '${e['id']}_${cKey(cToday())}';
    if (_loadedFor == key) return;
    _loadedFor = key;
    final l = cList(e['log']).where((x) => x['d'] == cKey(cToday())).firstOrNull;
    _mood = cInt(l?['mood'], 3).clamp(0, 4);
    _bp.text = cStr(l?['bp']);
    _sugar.text = cStr(l?['sugar']);
    _note.text = cStr(l?['note']);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final elders = _elders(s);
    if (elders.isEmpty) {
      return ToolList(children: [
        ResultHero(
          label: t('رعاية كبار السن', 'رعاية كبار السن', 'Elder care'),
          value: '👵👴',
          sub: t('دواء، مراجعات، اطمئنان يومي، وناس الرعاية — في مكان واحد', 'أدوية ومواعيد واطمئنان يومي ومقدمو الرعاية في مكان واحد', 'Medicines, appointments, daily check-ins and caregivers in one place'),
        ),
        FilledButton.icon(onPressed: () => _addElder(s), icon: const Icon(Icons.person_add_alt_1_rounded), label: Text(t('ضيف حبوبة أو جدّ', 'إضافة كبير سن', 'Add an elder'))),
        const SizedBox(height: 12),
        _notes(),
      ]);
    }
    final e = elders.firstWhere((x) => x['id'] == _sel, orElse: () => elders.first);
    _sel = e['id'];
    _loadCheckin(e);
    final today = cToday();
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;
    final meds = cList(e['meds']);
    final taken = List<String>.from((e['taken'] is Map ? e['taken'][cKey(today)] : null) ?? []);
    final doses = <(Map<String, dynamic>, int)>[
      for (final m in meds)
        for (final mins in List.from(m['times'] ?? []).map((x) => cInt(x))) (m, mins),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    final appts = cList(e['appts'])..sort((a, b) => cInt(a['at']).compareTo(cInt(b['at'])));
    final upcoming = appts.where((a) => cInt(a['at']) >= now.millisecondsSinceEpoch - 3600000).toList();
    final past = appts.where((a) => cInt(a['at']) < now.millisecondsSinceEpoch - 3600000).toList().reversed.toList();
    final log = cList(e['log']).reversed.toList();
    final cg = cList(e['cg']);
    final last7 = log.where((l) => cParse(l['d']) != null && cDays(cParse(l['d'])!, today) < 7).toList();
    final avgMood = last7.isEmpty ? null : last7.fold<int>(0, (a, l) => a + cInt(l['mood'], 2)) / last7.length;

    return ToolList(children: [
      SizedBox(
        height: 48,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final x in elders)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 150), child: Text(cStr(x['name']), maxLines: 1, overflow: TextOverflow.ellipsis)),
                selected: x['id'] == _sel,
                onSelected: (_) => setState(() => _sel = x['id']),
              ),
            ),
          ActionChip(avatar: const Icon(Icons.add_rounded, size: 18), label: Text(t('ضيف', 'إضافة', 'Add')), onPressed: () => _addElder(s)),
        ]),
      ),
      const SizedBox(height: 8),
      ResultHero(
        label: '${cStr(e['name'])}${cStr(e['age']).isEmpty ? '' : ' (${e['age']})'}',
        value: doses.isEmpty ? '—' : '${taken.length}/${doses.length}',
        sub: doses.isEmpty
            ? t('ما في دواء مسجّل', 'لا توجد أدوية مسجلة', 'No medicines yet')
            : '${t('جرعات الليلة', 'جرعات اليوم', "Today's doses")}${upcoming.isEmpty ? '' : ' • ${t('المراجعة الجاية', 'الموعد القادم', 'Next visit')}: ${cDate(DateTime.fromMillisecondsSinceEpoch(cInt(upcoming.first['at'])))}'}',
        colors: const [Color(0xFF8E3A9E), Color(0xFF5A3418), Color(0xFF3A1F0C)],
      ),
      StatGrid([
        StatChip('${meds.length}', t('أدوية', 'أدوية', 'Medicines'), color: SD.teal, icon: Icons.medication_rounded),
        StatChip('${upcoming.length}', t('مواعيد جاية', 'مواعيد قادمة', 'Upcoming'), color: SD.nile, icon: Icons.event_rounded),
        StatChip(avgMood == null ? '—' : moodEmojis[avgMood.round().clamp(0, 4)], t('مزاج الأسبوع', 'حالة الأسبوع', 'Week mood'), color: SD.gold, icon: Icons.mood_rounded),
      ]),
      const SizedBox(height: 12),
      // الدواء
      SCard(
        title: t('جدول الدواء', 'جدول الدواء', 'Medicine schedule'),
        icon: Icons.medication_rounded,
        color: SD.teal,
        trailing: IconButton(tooltip: t('ضيف دواء', 'إضافة دواء', 'Add medicine'), onPressed: () => _addMed(s, e), icon: const Icon(Icons.add_circle_rounded)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (doses.isEmpty) Text(t('ضيف الدواء ومواعيده عشان يجيك تنبيه.', 'أضف الدواء ومواعيده ليصلك تنبيه.', 'Add medicines and times to get reminders.')),
          if (doses.isNotEmpty) CBar(t('الجرعات الليلة', 'جرعات اليوم', "Today's doses"), taken.length / doses.length, color: SD.teal, trailing: '${taken.length}/${doses.length}'),
          for (final d in doses)
            CTile(
              icon: taken.contains('${d.$1['id']}_${d.$2}') ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: taken.contains('${d.$1['id']}_${d.$2}') ? SD.green : (d.$2 < nowMins ? SD.red : SD.teal),
              title: '${cMins(d.$2)} — ${d.$1['n']}',
              sub: cStr(d.$1['d']),
              onTap: () => _toggleDose(s, e, '${d.$1['id']}_${d.$2}'),
              actions: [IconButton(tooltip: t('عدّل', 'تعديل', 'Edit'), onPressed: () => _addMed(s, e, d.$1), icon: const Icon(Icons.edit_rounded, size: 20))],
            ),
          if (meds.isNotEmpty)
            Text(t('اضغط على الجرعة عشان تعلّمها اتاخدت.', 'اضغط على الجرعة لتعليمها كمأخوذة.', 'Tap a dose to mark it taken.'),
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))),
        ]),
      ),
      // المواعيد
      SCard(
        title: t('مراجعات الدكتور', 'مواعيد الطبيب', 'Doctor visits'),
        icon: Icons.event_available_rounded,
        color: SD.nile,
        trailing: IconButton(tooltip: t('ضيف موعد', 'إضافة موعد', 'Add appointment'), onPressed: () => _addAppt(s, e), icon: const Icon(Icons.add_circle_rounded)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (appts.isEmpty) Text(t('ما في مواعيد. التذكير بيجي الليلة القبلها وقبل ساعتين.', 'لا توجد مواعيد. يصل التذكير مساء اليوم السابق وقبل ساعتين.', 'No appointments. Reminders come the evening before and 2 hours before.')),
          for (final a in upcoming)
            () {
              final at = DateTime.fromMillisecondsSinceEpoch(cInt(a['at']));
              final days = cDays(today, at);
              return CTile(
                icon: Icons.local_hospital_rounded,
                color: cDueColor(days),
                title: cStr(a['title']),
                sub: '${cDate(at)} • ${fmtTimeAr(at)}${cStr(a['doctor']).isEmpty ? '' : ' • ${a['doctor']}'}${cStr(a['place']).isEmpty ? '' : ' • ${a['place']}'}',
                badge: cDueLabel(days),
                badgeColor: cDueColor(days),
                onTap: () => _addAppt(s, e, a),
                actions: [
                  IconButton(
                    tooltip: t('امسح', 'حذف', 'Delete'),
                    onPressed: () async {
                      if (!await confirmDelete(context, cStr(a['title']))) return;
                      e['appts'] = cList(e['appts'])..removeWhere((x) => x['id'] == a['id']);
                      _saveElder(s, e, notify: true);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  ),
                ],
              );
            }(),
          if (past.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('${t('مواعيد فاتت', 'مواعيد سابقة', 'Past visits')} (${past.length})', style: const TextStyle(fontWeight: FontWeight.w700)),
              children: [
                for (final a in past.take(20))
                  InfoRow(cStr(a['title']), cDate(DateTime.fromMillisecondsSinceEpoch(cInt(a['at']))), hint: cStr(a['doctor']).isEmpty ? null : cStr(a['doctor'])),
              ],
            ),
        ]),
      ),
      // الاطمئنان اليومي
      SCard(
        title: t('الاطمئنان اليومي', 'الاطمئنان اليومي', 'Daily check-in'),
        icon: Icons.favorite_rounded,
        color: SD.pink,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t('كيف حالو الليلة؟', 'كيف حاله اليوم؟', 'How are they today?'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(children: [
            for (var i = 0; i < 5; i++)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _mood = i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: _mood == i ? SD.gold.withValues(alpha: .3) : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SD.gold.withValues(alpha: _mood == i ? 1 : .3)),
                    ),
                    child: Column(children: [
                      Text(moodEmojis[i], style: const TextStyle(fontSize: 24)),
                      FittedBox(fit: BoxFit.scaleDown, child: Text(moodLabels[i], maxLines: 1, style: const TextStyle(fontSize: 11))),
                    ]),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: CField(t('الضغط (اختياري)', 'الضغط (اختياري)', 'BP (optional)'), _bp, hint: '120/80', ltr: true, keyboard: TextInputType.datetime)),
            const SizedBox(width: 8),
            Expanded(child: NumField(t('السكر (اختياري)', 'السكر (اختياري)', 'Sugar (optional)'), _sugar, hint: 'mg/dL')),
          ]),
          CField(t('ملاحظة', 'ملاحظة', 'Note'), _note, maxLines: 2, hint: t('أكل كويس، نام بدري…', 'أكل جيدًا، نام مبكرًا…', 'Ate well, slept early…')),
          FilledButton.icon(onPressed: () => _saveCheckin(s, e), icon: const Icon(Icons.save_rounded), label: Text(t('سجّل اطمئنان الليلة', 'تسجيل اطمئنان اليوم', "Save today's check-in"))),
          if (log.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final l in log.take(7))
              InfoRow(
                '${moodEmojis[cInt(l['mood'], 2).clamp(0, 4)]} ${cParse(l['d']) == null ? '' : cDate(cParse(l['d'])!)}',
                [if (cStr(l['bp']).isNotEmpty) '🩺 ${l['bp']}', if (cStr(l['sugar']).isNotEmpty) '🩸 ${l['sugar']}'].join('  '),
                hint: cStr(l['note']).isEmpty ? null : cStr(l['note']),
              ),
          ],
        ]),
      ),
      // ناس الرعاية
      SCard(
        title: t('الناس البترعى', 'مقدّمو الرعاية', 'Caregivers'),
        icon: Icons.volunteer_activism_rounded,
        color: SD.green,
        trailing: IconButton(tooltip: t('ضيف', 'إضافة', 'Add'), onPressed: () => _addCg(s, e), icon: const Icon(Icons.add_circle_rounded)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (cg.isEmpty) Text(t('ضيف الأولاد والممرض والجيران عشان تتصل بيهم بضغطة.', 'أضف الأبناء والممرض والجيران للاتصال بضغطة.', 'Add children, nurse and neighbours to call with one tap.')),
          for (final c in cg)
            CTile(
              icon: Icons.person_rounded,
              color: SD.green,
              title: cStr(c['name']),
              sub: [cStr(c['role']), cStr(c['phone'])].where((x) => x.isNotEmpty).join(' • '),
              onTap: () => _addCg(s, e, c),
              actions: [
                if (cStr(c['phone']).isNotEmpty) IconButton(tooltip: tr('اتصل', 'Call'), onPressed: () => callNumber(cStr(c['phone'])), icon: const Icon(Icons.call_rounded, color: SD.green)),
                IconButton(
                  tooltip: t('امسح', 'حذف', 'Delete'),
                  onPressed: () async {
                    if (!await confirmDelete(context, cStr(c['name']))) return;
                    e['cg'] = cList(e['cg'])..removeWhere((x) => x['id'] == c['id']);
                    _saveElder(s, e);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ],
            ),
        ]),
      ),
      SCard(
        title: t('طمّن الأسرة', 'طمئن الأسرة', 'Update the family'),
        icon: Icons.forum_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(elderSummary(e, today), style: const TextStyle(height: 1.5)),
          const SizedBox(height: 10),
          ShareBar(() => elderSummary(e, today)),
        ]),
      ),
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(onPressed: () => _addElder(s, e), icon: const Icon(Icons.edit_rounded), label: Text(t('عدّل البيانات', 'تعديل البيانات', 'Edit details'))),
        OutlinedButton.icon(
          onPressed: () async {
            if (!await confirmDelete(context, cStr(e['name']))) return;
            s.setData('elder_care_list', _elders(s)..removeWhere((x) => x['id'] == e['id']));
            _sel = '';
            _reschedule(s);
            setState(() {});
          },
          icon: const Icon(Icons.delete_rounded),
          label: Text(t('امسح', 'حذف', 'Delete')),
        ),
      ]),
      const SizedBox(height: 12),
      _notes(),
    ]);
  }

  Widget _notes() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        NoteBox(
          t('الأداة دي منفصلة عن «مواعيد الدواء» وبتنبيهاتها الخاصة. البيانات في تلفونك بس.', 'هذه الأداة مستقلة عن «مواعيد الدواء» ولها تنبيهاتها الخاصة. البيانات على هاتفك فقط.',
              'Independent from «Medicine Reminders», with its own alerts. Data stays on your phone.'),
        ),
        NoteBox(
          t('ما تغيّر جرعة ولا توقف دواء بدون الدكتور. لو في دوخة شديدة، ألم صدر، أو تغيّر مفاجئ في الكلام أو الوعي — اتصل بالإسعاف طوالي.',
              'لا تغيّر جرعة ولا توقف دواء دون الطبيب. عند دوخة شديدة أو ألم في الصدر أو تغيّر مفاجئ في الكلام أو الوعي — اتصل بالإسعاف فورًا.',
              "Don't change doses or stop medicines without the doctor. Severe dizziness, chest pain or sudden change in speech or alertness — call emergency services now."),
          kind: NoteKind.warn,
        ),
      ]);
}

class _MedSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _MedSheet({this.initial});
  @override
  State<_MedSheet> createState() => _MedSheetState();
}

class _MedSheetState extends State<_MedSheet> {
  late final _n = TextEditingController(text: cStr(widget.initial?['n']));
  late final _d = TextEditingController(text: cStr(widget.initial?['d']));
  late final List<int> _times = List.from(widget.initial?['times'] ?? [8 * 60]).map((x) => cInt(x)).toList();
  late bool _notify = widget.initial?['notify'] != false;

  @override
  void dispose() {
    _n.dispose();
    _d.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t('دواء', 'دواء', 'Medicine'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            CField(tr('اسم الدواء', 'Medicine name'), _n, icon: Icons.medication_rounded),
            CField(t('الجرعة', 'الجرعة', 'Dose'), _d, hint: t('حبة بعد الأكل', 'قرص بعد الأكل', '1 tablet after food')),
            Text(t('المواعيد', 'المواعيد', 'Times'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (var i = 0; i < _times.length; i++)
                InputChip(
                  label: Text(cMins(_times[i])),
                  onPressed: () async {
                    final m = await pickMinutes(context, _times[i]);
                    if (m != null) setState(() => _times[i] = m);
                  },
                  onDeleted: _times.length > 1 ? () => setState(() => _times.removeAt(i)) : null,
                ),
              ActionChip(
                avatar: const Icon(Icons.add_alarm_rounded, size: 18),
                label: Text(t('وقت', 'وقت', 'Time')),
                onPressed: () async {
                  final m = await pickMinutes(context, _times.isEmpty ? 8 * 60 : (_times.last + 8 * 60) % 1440);
                  if (m != null && !_times.contains(m)) setState(() => _times..add(m)..sort());
                },
              ),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _notify,
              onChanged: (v) => setState(() => _notify = v),
              title: Text(t('نبّهني في المواعيد', 'نبّهني في المواعيد', 'Remind me at these times')),
            ),
            Row(children: [
              if (widget.initial != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, {...widget.initial!, 'times': <int>[], 'notify': false, '_del': true}),
                    icon: const Icon(Icons.delete_rounded),
                    label: Text(t('امسح', 'حذف', 'Delete')),
                  ),
                ),
              if (widget.initial != null) const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    if (_n.text.trim().isEmpty) {
                      toast(t('أكتب اسم الدواء', 'اكتب اسم الدواء', 'Enter the medicine name'));
                      return;
                    }
                    Navigator.pop(context, {'id': widget.initial?['id'] ?? cId(), 'n': _n.text.trim(), 'd': _d.text.trim(), 'times': _times, 'notify': _notify});
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: Text(t('احفظ', 'حفظ', 'Save')),
                ),
              ),
            ]),
          ]),
        ),
      );
}

class _ApptSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _ApptSheet({this.initial});
  @override
  State<_ApptSheet> createState() => _ApptSheetState();
}

class _ApptSheetState extends State<_ApptSheet> {
  late final _title = TextEditingController(text: cStr(widget.initial?['title']));
  late final _doctor = TextEditingController(text: cStr(widget.initial?['doctor']));
  late final _place = TextEditingController(text: cStr(widget.initial?['place']));
  late DateTime _at = widget.initial == null
      ? DateTime(cToday().year, cToday().month, cToday().day + 1, 10)
      : DateTime.fromMillisecondsSinceEpoch(cInt(widget.initial!['at']));
  late bool _notify = widget.initial?['notify'] != false;

  @override
  void dispose() {
    _title.dispose();
    _doctor.dispose();
    _place.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t('موعد دكتور', 'موعد طبيب', 'Doctor visit'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            CField(t('الموضوع', 'الموضوع', 'Purpose'), _title, hint: t('مراجعة السكري', 'مراجعة السكري', 'Diabetes follow-up')),
            CField(t('الدكتور', 'الطبيب', 'Doctor'), _doctor),
            CField(t('المكان', 'المكان', 'Place'), _place, hint: t('المستشفى / العيادة', 'المستشفى / العيادة', 'Hospital / clinic')),
            DateButton(
              label: t('اليوم', 'التاريخ', 'Date'),
              value: _at,
              clearable: false,
              first: DateTime(2020),
              onChanged: (d) => setState(() => _at = d == null ? _at : DateTime(d.year, d.month, d.day, _at.hour, _at.minute)),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final m = await pickMinutes(context, _at.hour * 60 + _at.minute);
                if (m != null) setState(() => _at = DateTime(_at.year, _at.month, _at.day, m ~/ 60, m % 60));
              },
              icon: const Icon(Icons.access_time_rounded),
              label: Text('${t('الساعة', 'الوقت', 'Time')}: ${fmtTimeAr(_at)}'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _notify,
              onChanged: (v) => setState(() => _notify = v),
              title: Text(t('ذكّرني', 'ذكّرني', 'Remind me')),
              subtitle: Text(t('الليلة القبلها وقبل ساعتين', 'مساء اليوم السابق وقبل ساعتين', 'The evening before and 2 hours before')),
            ),
            FilledButton.icon(
              onPressed: () {
                if (_title.text.trim().isEmpty) {
                  toast(t('أكتب الموضوع', 'اكتب الموضوع', 'Enter the purpose'));
                  return;
                }
                Navigator.pop(context, {
                  'id': widget.initial?['id'] ?? cId(),
                  'title': _title.text.trim(),
                  'doctor': _doctor.text.trim(),
                  'place': _place.text.trim(),
                  'at': _at.millisecondsSinceEpoch,
                  'notify': _notify,
                });
              },
              icon: const Icon(Icons.save_rounded),
              label: Text(t('احفظ', 'حفظ', 'Save')),
            ),
          ]),
        ),
      );
}
