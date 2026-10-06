import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'med_notify.dart';
import 'more_common.dart';

/// أشكال الدواء
List<(String, IconData)> get medForms => [
      (t('حبوب', 'أقراص', 'Tablets'), Icons.medication_rounded),
      (t('كبسول', 'كبسولات', 'Capsules'), Icons.medication_liquid_rounded),
      (t('شراب', 'شراب', 'Syrup'), Icons.local_drink_rounded),
      (t('حقنة', 'حقنة', 'Injection'), Icons.vaccines_rounded),
      (t('نقط', 'قطرة', 'Drops'), Icons.water_drop_rounded),
      (t('بخاخ', 'بخاخ', 'Inhaler'), Icons.air_rounded),
      (t('مرهم', 'مرهم', 'Cream'), Icons.healing_rounded),
    ];

const _medColors = [SD.teal, SD.red, SD.nile, SD.purple, SD.orange, SD.green, SD.pink, SD.indigo];

class MedicineTool extends StatefulWidget {
  const MedicineTool({super.key});
  @override
  State<MedicineTool> createState() => _MedicineToolState();
}

class _MedicineToolState extends State<MedicineTool> {
  DateTime day = mDateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    // إعادة الجدولة عند الفتح (تتجدد التنبيهات حتى لو مسحها النظام)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<AppState>();
      if (_meds(s).any((m) => m['notify'] != false)) MedNotifications.reschedule(s);
    });
  }

  List<Map<String, dynamic>> _meds(AppState s) => (s.getData<List>('medicine_list') ?? []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();

  Map<String, dynamic> _log(AppState s) => Map<String, dynamic>.from(s.getData<Map>('medicine_log') ?? {});

  List<int> _times(Map m) => List<num>.from(m['times'] ?? []).map((e) => e.toInt()).toList()..sort();

  bool _activeOn(Map m, DateTime d) {
    final st = mParseKey(m['start']);
    final en = mParseKey(m['end']);
    if (st != null && d.isBefore(st)) return false;
    if (en != null && d.isAfter(en)) return false;
    return true;
  }

  /// جرعات يوم معيّن مرتبة بالوقت
  List<({Map<String, dynamic> med, int mins, String key})> _doses(List<Map<String, dynamic>> meds, DateTime d) {
    final r = <({Map<String, dynamic> med, int mins, String key})>[];
    for (final m in meds) {
      if (!_activeOn(m, d)) continue;
      for (final mins in _times(m)) {
        r.add((med: m, mins: mins, key: '${m['id']}_$mins'));
      }
    }
    r.sort((a, b) => a.mins.compareTo(b.mins));
    return r;
  }

  void _saveMeds(AppState s, List<Map<String, dynamic>> meds) {
    s.setData('medicine_list', meds);
    MedNotifications.reschedule(s);
  }

  void _mark(AppState s, DateTime d, String key, int? value, int totalDoses) {
    final log = _log(s);
    final k = mkey(d);
    final m = Map<String, dynamic>.from(log[k] ?? {});
    if (value == null) {
      m.remove(key);
    } else {
      m[key] = value;
    }
    log[k] = m;
    // نحتفظ بآخر 90 يومًا
    final keys = log.keys.toList()..sort();
    for (final old in keys.take(keys.length > 90 ? keys.length - 90 : 0)) {
      log.remove(old);
    }
    s.setData('medicine_log', log);
    if (value != null && value > 0) {
      HapticFeedback.lightImpact();
      s.bump('med_doses');
      s.awardDaily('medicine_log', 5, t('سجّلت جرعة الدواء', 'تسجيل جرعة الدواء', 'Logged a medicine dose'));
      final taken = m.values.where((v) => v is num && v > 0).length;
      if (mkey(d) == mkey(DateTime.now()) && taken >= totalDoses && totalDoses > 0) {
        s.awardDaily('medicine_all', 10, t('كل جرعات اليوم', 'جميع جرعات اليوم', "All of today's doses"));
        toast(t('تمام! أخدت كل جرعات الليلة 💪', 'ممتاز! أخذت جميع جرعات اليوم 💪', "Great! All of today's doses taken 💪"));
      }
    }
    setState(() {});
  }

  Future<void> _edit(AppState s, [Map<String, dynamic>? med]) async {
    final r = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MedEditor(initial: med),
    );
    if (r == null || !mounted) return;
    final meds = _meds(s);
    final i = meds.indexWhere((m) => m['id'] == r['id']);
    if (i >= 0) {
      meds[i] = r;
    } else {
      meds.add(r);
      s.award(5, t('ضفت دواء', 'إضافة دواء', 'Added a medicine'));
    }
    _saveMeds(s, meds);
    if (r['notify'] != false && MedNotifications.supported) {
      final ok = await MedNotifications.requestPermission();
      if (!ok) toast(t('فعّل الإشعارات من ضبط التلفون عشان التنبيه يشتغل', 'فعّل الإشعارات من إعدادات الهاتف ليعمل التنبيه', 'Enable notifications in phone settings for reminders'));
    }
    setState(() {});
  }

  Future<void> _delete(AppState s, Map m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('تمسح ${m['name']}؟', 'حذف ${m['name']}؟', 'Delete ${m['name']}?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t('امسح', 'احذف', 'Delete'))),
        ],
      ),
    );
    if (ok != true) return;
    final meds = _meds(s)..removeWhere((x) => x['id'] == m['id']);
    _saveMeds(s, meds);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final meds = _meds(s);
    final log = _log(s);
    final now = DateTime.now();
    final today = mDateOnly(now);
    final nowMins = now.hour * 60 + now.minute;
    final isToday = mkey(day) == mkey(today);
    final isPast = day.isBefore(today);
    final doses = _doses(meds, day);
    final dayLog = Map<String, dynamic>.from(log[mkey(day)] ?? {});
    final takenN = doses.where((d) => (dayLog[d.key] as num? ?? 0) > 0).length;

    // الجرعة القادمة (اليوم أو بكرة)
    ({Map med, DateTime at})? next;
    final todayLog = Map<String, dynamic>.from(log[mkey(today)] ?? {});
    for (final d in _doses(meds, today)) {
      if (d.mins > nowMins && todayLog[d.key] == null) {
        next = (med: d.med, at: DateTime(today.year, today.month, today.day, d.mins ~/ 60, d.mins % 60));
        break;
      }
    }
    if (next == null) {
      final tm = today.add(const Duration(days: 1));
      final dd = _doses(meds, tm);
      if (dd.isNotEmpty) next = (med: dd.first.med, at: DateTime(tm.year, tm.month, tm.day, dd.first.mins ~/ 60, dd.first.mins % 60));
    }

    // الالتزام في آخر 7 أيام
    final bars = <(String, double)>[];
    var due7 = 0, taken7 = 0;
    for (var i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final ds = _doses(meds, d).where((x) => !(i == 0 && x.mins > nowMins)).toList();
      final l = Map<String, dynamic>.from(log[mkey(d)] ?? {});
      final tk = ds.where((x) => (l[x.key] as num? ?? 0) > 0).length;
      due7 += ds.length;
      taken7 += tk;
      final wd = weekdaysAr[d.weekday - 1];
      bars.add((i == 0 ? tr('اليوم', 'Today') : (isEn ? wd.substring(0, 3) : wd.replaceFirst('ال', '')), ds.isEmpty ? 0 : tk * 100 / ds.length));
    }

    return ToolList(children: [
      ResultHero(
        label: t('الدواء الليلة', 'أدوية اليوم', "Today's medicines"),
        value: doses.isEmpty && isToday ? '—' : '${_doses(meds, today).where((d) => (todayLog[d.key] as num? ?? 0) > 0).length}/${_doses(meds, today).length}',
        sub: next == null
            ? t('ما في جرعات جاية', 'لا توجد جرعات قادمة', 'No upcoming doses')
            : '${t('الجاية', 'القادمة', 'Next')}: ${next.med['name']} — ${fmtTimeAr(next.at)} (${t('بعد', 'بعد', 'in')} ${fmtDuration(next.at.difference(now))})',
        colors: const [Color(0xFF0E8C84), Color(0xFF0B5C8A), Color(0xFF3A1F0C)],
      ),
      // جدول اليوم
      SCard(
        title: t('جدول الجرعات', 'جدول الجرعات', 'Dose schedule'),
        icon: Icons.checklist_rounded,
        color: SD.teal,
        trailing: Text('$takenN/${doses.length}', style: const TextStyle(fontWeight: FontWeight.w800)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            IconButton(
              onPressed: () => setState(() => day = day.subtract(const Duration(days: 1))),
              icon: Icon(isEn ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => day = today),
                child: Column(children: [
                  Text(isToday ? tr('اليوم', 'Today') : fmtDateAr(day), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  if (isToday) Text(fmtDateAr(day), style: const TextStyle(fontSize: 11.5)),
                ]),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => day = day.add(const Duration(days: 1))),
              icon: Icon(isEn ? Icons.chevron_right_rounded : Icons.chevron_left_rounded),
            ),
          ]),
          if (doses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                  meds.isEmpty
                      ? t('ما ضفت أي دواء لسه — دوس «ضيف دواء» تحت', 'لم تُضف أي دواء بعد — اضغط «أضف دواء» أدناه', 'No medicines yet — tap “Add medicine” below')
                      : t('ما في جرعات في اليوم دا', 'لا توجد جرعات في هذا اليوم', 'No doses on this day'),
                  textAlign: TextAlign.center),
            ),
          for (final d in doses) _doseRow(s, d, dayLog, isToday, isPast, nowMins, doses.length),
          if (doses.isNotEmpty && isToday && takenN < doses.length)
            TextButton.icon(
              onPressed: () {
                for (final d in doses) {
                  if (d.mins <= nowMins && dayLog[d.key] == null) _mark(s, day, d.key, DateTime.now().millisecondsSinceEpoch, doses.length);
                }
              },
              icon: const Icon(Icons.done_all_rounded),
              label: Text(t('سجّل كل الفاتت إنها اتأخدت', 'تسجيل كل الجرعات السابقة كمأخوذة', 'Mark all past doses as taken')),
            ),
        ]),
      ),
      if (meds.isNotEmpty) ...[
        StatGrid([
          StatChip(due7 == 0 ? '—' : '${fmt(taken7 * 100 / due7, 0)}%', t('التزام 7 أيام', 'التزام 7 أيام', '7-day rate'),
              color: due7 == 0 || taken7 / due7 >= .8 ? SD.green : SD.henna, icon: Icons.verified_rounded),
          StatChip('${meds.where((m) => _activeOn(m, today)).length}', t('أدوية شغالة', 'أدوية حالية', 'Active'), color: SD.teal, icon: Icons.medication_rounded),
          StatChip('${s.counter('med_doses')}', t('جرعات مسجّلة', 'جرعات مسجّلة', 'Logged'), color: SD.nile, icon: Icons.task_alt_rounded),
        ]),
        const SizedBox(height: 12),
        SCard(
          title: t('الالتزام آخر 7 أيام (%)', 'الالتزام في آخر 7 أيام (%)', 'Adherence, last 7 days (%)'),
          icon: Icons.bar_chart_rounded,
          color: SD.green,
          child: MiniBars(bars, goal: 100, color: SD.teal),
        ),
      ],
      SectionTitle(t('أدويتك', 'أدويتك', 'Your medicines'), icon: Icons.medication_rounded),
      for (final m in meds) _medCard(s, m, today),
      FilledButton.icon(onPressed: () => _edit(s), icon: const Icon(Icons.add_rounded), label: Text(t('ضيف دواء', 'أضف دواء', 'Add medicine'))),
      const SizedBox(height: 14),
      _notifyCard(s, meds),
      NoteBox(
          t('التطبيق دا للتذكير بس، ما بديل للدكتور أو الصيدلي. ما تغيّر الجرعة ولا توقف الدواء من غير ما تشاور الدكتور، وفي حالة طوارئ أمشي أقرب مستشفى طوّالي.',
              'هذه الأداة للتذكير فقط ولا تغني عن الطبيب أو الصيدلي. لا تغيّر الجرعة ولا توقف الدواء دون استشارة الطبيب، وفي الحالات الطارئة توجّه إلى أقرب مستشفى فورًا.',
              'This tool is only a reminder and does not replace your doctor or pharmacist. Do not change or stop a dose without medical advice; in an emergency go to the nearest hospital.'),
          kind: NoteKind.danger),
      NoteBox(
          t('لو نسيت جرعة: أغلب الأدوية تاخدها أول ما تتذكر، إلا لو قرّب موعد الجاية — وقتها خليها وما تضاعف الجرعة. أسأل الصيدلي عن دواك بالتحديد.',
              'إذا نسيت جرعة: معظم الأدوية تؤخذ فور التذكر، إلا إذا اقترب موعد الجرعة التالية — فتجاوزها ولا تضاعف الجرعة. اسأل الصيدلي عن دوائك تحديدًا.',
              'Missed a dose? For most medicines take it when you remember unless the next dose is near — then skip it and never double up. Ask your pharmacist about your specific medicine.'),
          kind: NoteKind.tip),
    ]);
  }

  Widget _doseRow(AppState s, ({Map<String, dynamic> med, int mins, String key}) d, Map dayLog, bool isToday, bool isPast, int nowMins, int total) {
    final v = dayLog[d.key] as num?;
    final taken = v != null && v > 0;
    final skipped = v != null && v <= 0;
    final missed = v == null && (isPast || (isToday && d.mins < nowMins - 30));
    final color = _medColors[((d.med['color'] as num?)?.toInt() ?? 0) % _medColors.length];
    final form = medForms[((d.med['form'] as num?)?.toInt() ?? 0).clamp(0, medForms.length - 1)];
    final (label, lc) = taken
        ? ('${t('اتأخدت', 'أُخذت', 'Taken')}${v > 1000 ? ' ${fmtTimeAr(DateTime.fromMillisecondsSinceEpoch(v.toInt()))}' : ''}', SD.green)
        : skipped
            ? (t('اتخطّت', 'تم تخطيها', 'Skipped'), SD.gold)
            : missed
                ? (t('فاتت!', 'فائتة!', 'Missed!'), SD.red)
                : (t('جاية', 'قادمة', 'Upcoming'), SD.nile);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: taken ? .16 : .07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (missed ? SD.red : color).withValues(alpha: .45)),
      ),
      child: Row(children: [
        Checkbox(
          value: taken,
          activeColor: SD.green,
          onChanged: (x) => _mark(s, day, d.key, x == true ? DateTime.now().millisecondsSinceEpoch : null, total),
        ),
        Icon(form.$2, color: readable(context, color), size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${d.med['name']}', style: TextStyle(fontWeight: FontWeight.w800, decoration: taken ? TextDecoration.lineThrough : null)),
              if ((d.med['dose'] ?? '').toString().isNotEmpty) Text('${d.med['dose']}', style: const TextStyle(fontSize: 12.5)),
              Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: readable(context, lc))),
            ]),
          ),
        ),
        Text(fmtMinutes(d.mins), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        PopupMenuButton<int>(
          icon: const Icon(Icons.more_vert_rounded, size: 20),
          onSelected: (x) => _mark(s, day, d.key, x == 1 ? DateTime.now().millisecondsSinceEpoch : (x == 0 ? 0 : null), total),
          itemBuilder: (_) => [
            PopupMenuItem(value: 1, child: Text(t('أخدتها', 'أخذتها', 'Taken'))),
            PopupMenuItem(value: 0, child: Text(t('تخطّيتها', 'تخطيتها', 'Skipped'))),
            PopupMenuItem(value: -1, child: Text(t('امسح الحالة', 'مسح الحالة', 'Clear'))),
          ],
        ),
      ]),
    );
  }

  Widget _medCard(AppState s, Map<String, dynamic> m, DateTime today) {
    final color = _medColors[((m['color'] as num?)?.toInt() ?? 0) % _medColors.length];
    final form = medForms[((m['form'] as num?)?.toInt() ?? 0).clamp(0, medForms.length - 1)];
    final st = mParseKey(m['start']), en = mParseKey(m['end']);
    final active = _activeOn(m, today);
    final ended = en != null && en.isBefore(today);
    String period;
    if (en == null) {
      period = t('مستمر', 'مستمر', 'Ongoing');
    } else if (ended) {
      period = t('الكورس خلص', 'انتهى الكورس', 'Course finished');
    } else {
      final left = mDaysBetween(today, en) + 1;
      period = t('فاضل $left يوم', 'متبقٍ $left يومًا', '$left days left');
    }
    return SCard(
      title: '${m['name']}',
      icon: form.$2,
      color: color,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        MiniIconBtn(Icons.edit_rounded, color: SD.nile, tip: tr('تعديل', 'Edit'), onTap: () => _edit(s, m)),
        MiniIconBtn(Icons.delete_outline_rounded, tip: tr('حذف', 'Delete'), onTap: () => _delete(s, m)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final mins in _times(m)) Chip(avatar: const Icon(Icons.alarm_rounded, size: 16), label: Text(fmtMinutes(mins)), visualDensity: VisualDensity.compact),
        ]),
        const SizedBox(height: 6),
        if ((m['dose'] ?? '').toString().isNotEmpty) InfoRow(t('الجرعة', 'الجرعة', 'Dose'), '${m['dose']}', icon: Icons.scale_rounded),
        InfoRow(t('المدة', 'المدة', 'Period'), period, icon: Icons.date_range_rounded, valueColor: ended ? SD.gold : (active ? SD.green : SD.nile),
            hint: '${st == null ? '' : fmtDateAr(st, weekday: false)}${en == null ? '' : ' → ${fmtDateAr(en, weekday: false)}'}'),
        if ((m['notes'] ?? '').toString().isNotEmpty) InfoRow(t('ملاحظات', 'ملاحظات', 'Notes'), '${m['notes']}', icon: Icons.sticky_note_2_outlined),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(t('نبّهني في المواعيد', 'تنبيه في المواعيد', 'Remind me')),
          value: m['notify'] != false,
          onChanged: (v) {
            final meds = _meds(s);
            final i = meds.indexWhere((x) => x['id'] == m['id']);
            if (i < 0) return;
            meds[i]['notify'] = v;
            _saveMeds(s, meds);
            if (v) MedNotifications.requestPermission();
            setState(() {});
          },
        ),
      ]),
    );
  }

  Widget _notifyCard(AppState s, List<Map<String, dynamic>> meds) {
    final n = (s.getData<num>('medicine_notif_n') ?? 0).toInt();
    return SCard(
      title: t('التنبيهات', 'التنبيهات', 'Reminders'),
      icon: Icons.notifications_active_rounded,
      color: SD.orange,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!MedNotifications.supported)
          NoteBox(t('التنبيهات بتشتغل في تطبيق الأندرويد والآيفون بس.', 'التنبيهات تعمل في تطبيق أندرويد وآيفون فقط.', 'Reminders work only in the Android and iOS app.'), kind: NoteKind.warn)
        else ...[
          InfoRow(t('تنبيهات مجدولة', 'تنبيهات مجدولة', 'Scheduled reminders'), '$n', icon: Icons.alarm_on_rounded),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await MedNotifications.requestPermission();
                  final c = await MedNotifications.reschedule(s);
                  toast(t('اتجدولت $c تنبيه ✓', 'جُدول $c تنبيهًا ✓', '$c reminders scheduled ✓'));
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(t('جدّد', 'تحديث', 'Refresh')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  await MedNotifications.requestPermission();
                  await MedNotifications.test();
                },
                icon: const Icon(Icons.notifications_rounded),
                label: Text(t('جرّب', 'تجربة', 'Test')),
              ),
            ),
          ]),
          NoteBox(
              t('التنبيه بيجي بتوقيت التلفون، وممكن يتأخر دقايق بسيطة عشان توفير البطارية. لو ما جاك، شيل التطبيق من «توفير البطارية» وافتح الأداة دي مرة عشان تتجدد.',
                  'يصل التنبيه بتوقيت الهاتف وقد يتأخر دقائق قليلة بسبب توفير البطارية. إن لم يصلك، استثنِ التطبيق من «توفير البطارية» وافتح هذه الأداة لتحديث التنبيهات.',
                  "Reminders use the phone's clock and may arrive a few minutes late due to battery saving. If they don't arrive, exclude the app from battery optimization and open this tool to refresh them."),
              kind: NoteKind.info),
        ],
      ]),
    );
  }
}

/* ───────────── محرر الدواء ───────────── */
class _MedEditor extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _MedEditor({this.initial});
  @override
  State<_MedEditor> createState() => _MedEditorState();
}

class _MedEditorState extends State<_MedEditor> {
  final nameC = TextEditingController(), doseC = TextEditingController(), notesC = TextEditingController(), daysC = TextEditingController();
  List<int> times = [8 * 60];
  int form = 0, color = 0;
  DateTime start = mDateOnly(DateTime.now());
  DateTime? end;
  bool notify = true;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    if (m != null) {
      nameC.text = m['name'] ?? '';
      doseC.text = m['dose'] ?? '';
      notesC.text = m['notes'] ?? '';
      times = List<num>.from(m['times'] ?? []).map((e) => e.toInt()).toList();
      form = (m['form'] as num?)?.toInt() ?? 0;
      color = (m['color'] as num?)?.toInt() ?? 0;
      start = mParseKey(m['start']) ?? start;
      end = mParseKey(m['end']);
      notify = m['notify'] != false;
    } else {
      color = DateTime.now().millisecond % _medColors.length;
    }
  }

  @override
  void dispose() {
    for (final c in [nameC, doseC, notesC, daysC]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addTime([int? index]) async {
    final init = index == null ? const TimeOfDay(hour: 8, minute: 0) : TimeOfDay(hour: times[index] ~/ 60, minute: times[index] % 60);
    final tm = await showTimePicker(context: context, initialTime: init, helpText: t('وقت الجرعة', 'وقت الجرعة', 'Dose time'));
    if (tm == null) return;
    final v = tm.hour * 60 + tm.minute;
    setState(() {
      if (index != null) times.removeAt(index);
      if (!times.contains(v)) times.add(v);
      times.sort();
    });
  }

  void _preset(List<int> hours) => setState(() => times = hours.map((h) => h * 60).toList());

  @override
  Widget build(BuildContext context) {
    final today = mDateOnly(DateTime.now());
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .88,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
          Text(widget.initial == null ? t('دواء جديد', 'دواء جديد', 'New medicine') : t('تعديل الدواء', 'تعديل الدواء', 'Edit medicine'),
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(controller: nameC, decoration: InputDecoration(labelText: t('اسم الدواء', 'اسم الدواء', 'Medicine name'), hintText: t('بندول، أموكسيل…', 'باراسيتامول، أموكسيسيلين…', 'Paracetamol, Amoxicillin…'))),
          const SizedBox(height: 10),
          TextField(controller: doseC, decoration: InputDecoration(labelText: t('الجرعة', 'الجرعة', 'Dose'), hintText: t('حبة وحدة 500 ملجم / 5 مل', 'قرص واحد 500 ملغ / 5 مل', '1 tablet 500 mg / 5 ml'))),
          const SizedBox(height: 12),
          Text(t('الشكل', 'الشكل', 'Form'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < medForms.length; i++)
              ChoiceChip(avatar: Icon(medForms[i].$2, size: 18), label: Text(medForms[i].$1), selected: form == i, onSelected: (_) => setState(() => form = i)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Text(t('اللون', 'اللون', 'Color'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            for (var i = 0; i < _medColors.length; i++)
              GestureDetector(
                onTap: () => setState(() => color = i),
                child: Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  decoration: BoxDecoration(color: _medColors[i], shape: BoxShape.circle, border: Border.all(color: color == i ? SD.gold : Colors.transparent, width: 3)),
                ),
              ),
          ]),
          const SizedBox(height: 14),
          Text('${t('المواعيد', 'المواعيد', 'Times')} (${times.length} ${t('مرات في اليوم', 'مرات يوميًا', 'per day')})', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            ActionChip(label: Text(t('مرة (8ص)', 'مرة (8ص)', 'Once (8 AM)')), onPressed: () => _preset([8])),
            ActionChip(label: Text(t('مرتين (كل 12 س)', 'مرتان (كل 12 س)', 'Twice (12h)')), onPressed: () => _preset([8, 20])),
            ActionChip(label: Text(t('3 مرات (كل 8 س)', '3 مرات (كل 8 س)', '3× (8h)')), onPressed: () => _preset([6, 14, 22])),
            ActionChip(label: Text(t('3 مع الأكل', '3 مع الوجبات', '3× with meals')), onPressed: () => _preset([8, 14, 20])),
            ActionChip(label: Text(t('4 مرات (كل 6 س)', '4 مرات (كل 6 س)', '4× (6h)')), onPressed: () => _preset([0, 6, 12, 18])),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < times.length; i++)
              InputChip(
                avatar: const Icon(Icons.alarm_rounded, size: 18),
                label: Text(fmtMinutes(times[i])),
                onPressed: () => _addTime(i),
                onDeleted: times.length > 1 ? () => setState(() => times.removeAt(i)) : null,
              ),
            ActionChip(avatar: const Icon(Icons.add_alarm_rounded, size: 18), label: Text(t('ضيف وقت', 'أضف وقتًا', 'Add time')), onPressed: () => _addTime()),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: MDateButton(
                label: t('من يوم', 'البداية', 'Start'),
                value: start,
                first: today.subtract(const Duration(days: 365)),
                last: today.add(const Duration(days: 365)),
                onPick: (d) => setState(() {
                  start = d;
                  if (end != null && end!.isBefore(d)) end = d;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MDateButton(
                label: t('لحدي يوم', 'النهاية', 'End'),
                value: end,
                first: start,
                last: start.add(const Duration(days: 3650)),
                color: SD.henna,
                onPick: (d) => setState(() => end = d),
                onClear: () => setState(() => end = null),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final n in [3, 5, 7, 10, 14, 30])
              ActionChip(label: Text('$n ${t('أيام', 'أيام', 'days')}'), onPressed: () => setState(() => end = start.add(Duration(days: n - 1)))),
            ActionChip(label: Text(t('مستمر', 'مستمر', 'Ongoing')), onPressed: () => setState(() => end = null)),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: notesC,
            maxLines: 2,
            decoration: InputDecoration(labelText: t('ملاحظات', 'ملاحظات', 'Notes'), hintText: t('بعد الأكل، مع موية كتيرة…', 'بعد الأكل، مع كمية كافية من الماء…', 'After meals, with plenty of water…')),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t('نبّهني في المواعيد', 'التنبيه في المواعيد', 'Remind me at these times')),
            value: notify,
            onChanged: (v) => setState(() => notify = v),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              if (nameC.text.trim().isEmpty) return toast(t('أكتب اسم الدواء', 'اكتب اسم الدواء', 'Enter the medicine name'));
              if (times.isEmpty) return toast(t('ضيف وقت واحد على الأقل', 'أضف وقتًا واحدًا على الأقل', 'Add at least one time'));
              Navigator.pop(context, <String, dynamic>{
                'id': widget.initial?['id'] ?? DateTime.now().millisecondsSinceEpoch,
                'name': nameC.text.trim(),
                'dose': doseC.text.trim(),
                'notes': notesC.text.trim(),
                'form': form,
                'color': color,
                'times': [...times]..sort(),
                'start': mkey(start),
                'end': end == null ? null : mkey(end!),
                'notify': notify,
              });
            },
            icon: const Icon(Icons.save_rounded),
            label: Text(tr('حفظ', 'Save')),
          ),
        ]),
      ),
    );
  }
}
