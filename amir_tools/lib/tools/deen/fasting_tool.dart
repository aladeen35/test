import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/calendars.dart';
import 'deen_common.dart';
import 'fast_calendar.dart';
import 'fast_notify.dart';

const _typeColors = {
  FastType.monThu: SD.nile,
  FastType.bid: SD.teal,
  FastType.arafah: SD.gold,
  FastType.ashura: SD.purple,
  FastType.shawwal: SD.green,
};

class FastingTool extends StatefulWidget {
  const FastingTool({super.key});
  @override
  State<FastingTool> createState() => _FastingToolState();
}

class _FastingToolState extends State<FastingTool> {
  late DateTime view;

  @override
  void initState() {
    super.initState();
    final d = deenToday();
    view = DateTime(d.year, d.month);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = context.read<AppState>();
      if (FastNotifications.enabled(s).isNotEmpty) FastNotifications.reschedule(s);
    });
  }

  /* ── البيانات ── */
  Set<String> _log(AppState s) => Set<String>.from(s.getData<List>('fasting_log') ?? const []);
  int _owed(AppState s) => ((s.getData<Map>('fasting_qada') ?? const {})['owed'] as num? ?? 0).toInt();
  List<String> _made(AppState s) => List<String>.from((s.getData<Map>('fasting_qada') ?? const {})['made'] ?? const [])..sort();

  void _saveQada(AppState s, int owed, List<String> made) {
    s.setData('fasting_qada', {'owed': owed < 0 ? 0 : owed, 'made': made});
    setState(() {});
  }

  void _toggleFast(AppState s, DateTime d) {
    final today = deenToday();
    if (d.isAfter(today)) {
      toast(t('ما بتقدر تسجّل يوم لسه ما جا', 'لا يمكن تسجيل يوم لم يأتِ بعد', 'You can\'t log a future day'));
      return;
    }
    final f = fastDay(d, s.hijriShift);
    final log = _log(s);
    final k = dayKey(d);
    if (log.contains(k)) {
      log.remove(k);
    } else {
      if (f.forbidden != null) {
        toast(f.forbidden!, icon: Icons.block);
        return;
      }
      log.add(k);
      s.bump('fasts');
      s.awardDaily('fasting_$k', 10, t('صيام تطوع', 'صيام تطوع', 'Voluntary fast'));
    }
    s.setData('fasting_log', log.toList()..sort());
    setState(() {});
  }

  Future<void> _makeUp(AppState s, {bool pick = false}) async {
    final today = deenToday();
    var d = today;
    if (pick) {
      final r = await showDatePicker(context: context, initialDate: today, firstDate: DateTime(today.year - 5), lastDate: today);
      if (r == null || !mounted) return;
      d = r;
    }
    final f = fastDay(d, s.hijriShift);
    if (f.forbidden != null) {
      toast(f.forbidden!, icon: Icons.block);
      return;
    }
    final made = _made(s);
    final k = dayKey(d);
    if (made.contains(k)) {
      toast(t('اليوم دا متسجّل قبل كدا', 'هذا اليوم مسجّل مسبقًا', 'That day is already logged'));
      return;
    }
    made.add(k);
    s.award(10, t('قضيت يوم صيام', 'قضاء يوم صيام', 'Made up a fast'));
    _saveQada(s, _owed(s), made);
  }

  /* ── الإحصاءات ── */
  int _weekIndex(DateTime d) => (daysBetween(DateTime(2000, 1, 3), d) / 7).floor(); // 3 يناير 2000 كان اثنين

  ({int current, int best}) _streaks(Set<String> log, DateTime today) {
    final weeks = <int>{};
    for (final k in log) {
      final d = parseDayKey(k);
      if (d != null) weeks.add(_weekIndex(d));
    }
    if (weeks.isEmpty) return (current: 0, best: 0);
    final sorted = weeks.toList()..sort();
    var best = 1, run = 1;
    for (var i = 1; i < sorted.length; i++) {
      run = sorted[i] == sorted[i - 1] + 1 ? run + 1 : 1;
      if (run > best) best = run;
    }
    var w = _weekIndex(today);
    if (!weeks.contains(w)) w--;
    var cur = 0;
    while (weeks.contains(w)) {
      cur++;
      w--;
    }
    return (current: cur, best: best);
  }

  Future<void> _pickTime(AppState s) async {
    final m = FastNotifications.remindMinutes(s);
    final r = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
    if (r == null || !mounted) return;
    s.setData('fasting_remind_at', r.hour * 60 + r.minute);
    FastNotifications.reschedule(s);
    setState(() {});
  }

  Future<void> _toggleRemind(AppState s, FastType type, bool on) async {
    final set = FastNotifications.enabled(s);
    on ? set.add(type) : set.remove(type);
    s.setData('fasting_remind', [for (final t in set) t.id]);
    setState(() {});
    if (on && FastNotifications.supported) {
      final ok = await FastNotifications.requestPermission();
      if (!ok) toast(t('فعّل الإشعارات من ضبط التلفون عشان التذكير يشتغل', 'فعّل الإشعارات من إعدادات الهاتف ليعمل التذكير', 'Enable notifications in phone settings for reminders'));
    }
    await FastNotifications.reschedule(s);
  }

  String _remaining(int n) => n == 0 ? tr('اليوم', 'today') : (n == 1 ? t('بكرة', 'غدًا', 'tomorrow') : tr('بعد $n يوم', 'in $n days'));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final shift = s.hijriShift;
    final today = deenToday();
    final log = _log(s);
    final owed = _owed(s);
    final made = _made(s);
    final left = (owed - made.length).clamp(0, 9999);
    final todayF = fastDay(today, shift);
    final st = _streaks(log, today);
    final monthCount = log.where((k) => k.startsWith('${today.year}-${two(today.month)}-')).length;
    final upcoming = upcomingFasts(today, shift, days: 30).take(10).toList();
    final occasions = nextOccasions(today, shift);
    final remind = FastNotifications.enabled(s);
    final rm = FastNotifications.remindMinutes(s);

    return ToolList(children: [
      ResultHero(
        label: t('القضاء الفاضل عليك', 'أيام القضاء المتبقية', 'Qada days remaining'),
        value: '$left',
        sub: '${hijriText(today, shift: shift)} — ${todayF.suggested || todayF.forbidden != null || todayF.ramadan ? todayF.describe() : tr('يوم عادي', 'Regular day')}',
        colors: const [Color(0xFF3B2F8F), Color(0xFF5A3418), Color(0xFF3A1F0C)],
      ),
      if (todayF.forbidden != null) NoteBox(todayF.forbidden!, kind: NoteKind.danger),
      // ── قضاء رمضان ──
      SCard(
        title: t('قضاء رمضان', 'قضاء رمضان', 'Ramadan make-up (qada)'),
        icon: Icons.event_repeat_rounded,
        color: SD.indigo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CountRow(t('الأيام الفاطرها (الدين)', 'الأيام المُفطرة (الدَّين)', 'Days owed'), owed, (v) => _saveQada(s, v, made), max: 999,
              hint: t('كل الأيام الفاتتك من رمضان', 'جميع الأيام الفائتة من رمضان', 'All missed Ramadan days')),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: left > 0 ? () => _makeUp(s) : null,
                icon: const Icon(Icons.check_circle_rounded),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('قضيت الليلة', 'قضيت اليوم', 'Made up today'))),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: left > 0 ? () => _makeUp(s, pick: true) : null,
                icon: const Icon(Icons.calendar_month_rounded),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('يوم تاني', 'يوم آخر', 'Other day'))),
              ),
            ),
          ]),
          if (owed > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: (made.length / owed).clamp(0, 1).toDouble(), minHeight: 8),
            ),
            const SizedBox(height: 4),
            Text(tr('قضيت ${made.length} من $owed', 'Made up ${made.length} of $owed'), style: const TextStyle(fontSize: 12.5)),
          ],
          if (made.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final k in made.reversed.take(12))
                InputChip(
                  label: Text(_fmtKey(k), style: const TextStyle(fontSize: 12)),
                  onDeleted: () => _saveQada(s, owed, made..remove(k)),
                ),
            ]),
          ],
          if (left == 0 && owed > 0)
            NoteBox(t('ما شاء الله، كمّلت القضاء كلو 🎉', 'ما شاء الله، أتممت القضاء كله 🎉', 'Masha\'Allah — all make-up days completed 🎉'), kind: NoteKind.tip),
        ]),
      ),
      // ── تقويم التطوع ──
      SCard(
        title: t('تقويم صيام التطوع', 'تقويم صيام التطوع', 'Voluntary fasts calendar'),
        icon: Icons.calendar_month_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            IconButton(
              onPressed: () => setState(() => view = DateTime(view.year, view.month - 1)),
              icon: Icon(isEn ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
            ),
            Expanded(
              child: Column(children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('${monthsAr[view.month - 1]} ${view.year}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                FittedBox(fit: BoxFit.scaleDown, child: Text(_hijriSpan(view, shift), style: const TextStyle(fontSize: 12))),
              ]),
            ),
            IconButton(
              onPressed: () => setState(() => view = DateTime(view.year, view.month + 1)),
              icon: Icon(isEn ? Icons.chevron_right_rounded : Icons.chevron_left_rounded),
            ),
          ]),
          const SizedBox(height: 6),
          _MonthGrid(view: view, shift: shift, today: today, log: log, onTap: (d) => _toggleFast(s, d)),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 6, children: [
            for (final e in _typeColors.entries) _Legend(e.value, e.key.label),
            _Legend(SD.red, tr('يحرم صومه', 'Forbidden')),
            _Legend(SD.green, tr('صمته ✓', 'Fasted ✓'), filled: true),
          ]),
          const SizedBox(height: 8),
          Text(t('اضغط على أي يوم فات عشان تسجّل إنك صمته أو تلغيه.', 'اضغط على أي يوم مضى لتسجيل صيامه أو إلغائه.', 'Tap any past day to log (or unlog) a fast.'),
              style: const TextStyle(fontSize: 12.5)),
        ]),
      ),
      // ── القادم ──
      SCard(
        title: t('الصيام السنّة الجاي', 'صيام السنّة القادم', 'Upcoming sunnah fasts'),
        icon: Icons.upcoming_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final f in upcoming)
            InfoRow(fmtDateAr(f.date), _remaining(daysBetween(today, f.date)), hint: '${hijriText(f.date, shift: shift)} • ${f.describe()}', icon: Icons.nights_stay_rounded),
          if (upcoming.isEmpty) Text(tr('لا يوجد في الثلاثين يومًا القادمة', 'None in the next 30 days')),
          const SizedBox(height: 10),
          Text(t('المناسبات الكبيرة', 'المناسبات الكبرى', 'Major occasions'), style: const TextStyle(fontWeight: FontWeight.w800)),
          for (final e in occasions.entries.where((e) => e.key != FastType.bid))
            InfoRow(e.key.label, _remaining(daysBetween(today, e.value)), hint: '${fmtDateAr(e.value)} • ${hijriText(e.value, shift: shift)}', valueColor: _typeColors[e.key]),
        ]),
      ),
      // ── الإحصاءات ──
      SCard(
        title: t('إحصائياتك', 'الإحصاءات', 'Stats & streaks'),
        icon: Icons.insights_rounded,
        color: SD.gold,
        child: StatGrid([
          StatChip('${log.length}', t('صيام تطوع', 'صيام تطوع', 'Voluntary fasts'), color: SD.green, icon: Icons.nights_stay_rounded),
          StatChip('$monthCount', t('الشهر دا', 'هذا الشهر', 'This month'), color: SD.nile),
          StatChip('${made.length}', t('أيام قضيتها', 'أيام مقضيّة', 'Qada made up'), color: SD.indigo),
          StatChip('${st.current}', t('أسابيع ورا بعض', 'أسابيع متتالية', 'Week streak'), color: SD.orange, icon: Icons.local_fire_department_rounded),
          StatChip('${st.best}', t('أطول سلسلة', 'أطول سلسلة', 'Best streak'), color: SD.gold),
          StatChip('$left', t('قضاء فاضل', 'قضاء متبقٍ', 'Qada left'), color: SD.red),
        ]),
      ),
      // ── التذكير ──
      SCard(
        title: t('التذكير بالليل', 'التذكير مساءً', 'Evening reminder'),
        icon: Icons.notifications_active_rounded,
        color: SD.teal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!FastNotifications.supported)
            NoteBox(t('التذكير بيشتغل في أندرويد وآيفون بس', 'التذكير يعمل على أندرويد وآيفون فقط', 'Reminders work on Android and iPhone only'), kind: NoteKind.warn),
          for (final type in FastType.values)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: remind.contains(type),
              onChanged: (v) => _toggleRemind(s, type, v),
              title: Text(type.label, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_rounded),
            title: Text(t('وقت التذكير (الليلة القبلها)', 'وقت التذكير (مساء اليوم السابق)', 'Reminder time (evening before)'), maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: FittedBox(fit: BoxFit.scaleDown, child: Text(fmtTimeAr(DateTime(2000, 1, 1, rm ~/ 60, rm % 60)), style: const TextStyle(fontWeight: FontWeight.w800))),
            onTap: () => _pickTime(s),
          ),
          if (FastNotifications.supported)
            OutlinedButton.icon(
              onPressed: FastNotifications.test,
              icon: const Icon(Icons.notifications_rounded),
              label: Text(t('جرّب التنبيه', 'تجربة التنبيه', 'Test notification')),
            ),
        ]),
      ),
      NoteBox(
        t('أيام يحرم صومها: يوم عيد الفطر، ويوم عيد الأضحى، وأيام التشريق (11–13 ذو الحجة) — والتطبيق ما بيقترحها. وما تخصّ يوم الجمعة براه بالصيام (إلا تصوم يوم قبله أو بعده).',
            'أيام يحرم صومها: يوم عيد الفطر، ويوم عيد الأضحى، وأيام التشريق (11–13 ذو الحجة) — ولا يقترحها التطبيق. ويُكره إفراد يوم الجمعة بالصيام إلا مع يوم قبله أو بعده.',
            'Days it is forbidden to fast: Eid al-Fitr, Eid al-Adha and the days of Tashriq (11–13 Dhul-Hijjah) — the app never suggests them. Singling out Friday alone for fasting is disliked (fast a day before or after it too).'),
        kind: NoteKind.danger,
      ),
      NoteBox(
        t('التواريخ الهجرية محسوبة (أم القرى) وممكن تختلف يوم عن الرؤية في بلدك — عدّلها من «الضبط ← تعديل الهجري».',
            'التواريخ الهجرية محسوبة (أم القرى) وقد تختلف يومًا عن الرؤية في بلدك — عدّلها من «الإعدادات ← تعديل الهجري».',
            'Hijri dates are calculated (Umm al-Qura) and may differ by a day from local moon-sighting — adjust in Settings → Hijri adjustment.'),
      ),
    ]);
  }

  String _fmtKey(String k) {
    final d = parseDayKey(k);
    return d == null ? k : '${d.day} ${monthsAr[d.month - 1]} ${d.year}';
  }

  String _hijriSpan(DateTime m, int shift) {
    final a = toHijri(DateTime(m.year, m.month, 1), shift: shift);
    final b = toHijri(DateTime(m.year, m.month + 1, 0), shift: shift);
    return a.m == b.m ? '${hijriMonths[a.m - 1]} ${a.y}' : '${hijriMonths[a.m - 1]} – ${hijriMonths[b.m - 1]} ${b.y}';
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool filled;
  const _Legend(this.color, this.label, {this.filled = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: filled ? color : color.withValues(alpha: .25),
            shape: BoxShape.circle,
            border: Border.all(color: readable(context, color), width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11.5)),
      ]);
}

class _MonthGrid extends StatelessWidget {
  final DateTime view, today;
  final int shift;
  final Set<String> log;
  final ValueChanged<DateTime> onTap;
  const _MonthGrid({required this.view, required this.shift, required this.today, required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final first = DateTime(view.year, view.month, 1);
    final days = DateTime(view.year, view.month + 1, 0).day;
    final lead = first.weekday - 1; // الاثنين أولًا
    final names = isEn ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S'] : const ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .55);
    return Column(children: [
      Row(children: [
        for (final n in names) Expanded(child: Center(child: Text(n, style: TextStyle(fontWeight: FontWeight.w800, color: muted, fontSize: 12)))),
      ]),
      const SizedBox(height: 4),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: .82,
        children: [
          for (var i = 0; i < lead; i++) const SizedBox(),
          for (var d = 1; d <= days; d++) _cell(context, DateTime(view.year, view.month, d)),
        ],
      ),
    ]);
  }

  Widget _cell(BuildContext context, DateTime d) {
    final f = fastDay(d, shift);
    final fasted = log.contains(dayKey(d));
    final isToday = dayKey(d) == dayKey(today);
    final Color? c = f.forbidden != null ? SD.red : (f.types.isNotEmpty ? _typeColors[f.types.first] : null);
    final onS = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onTap(d),
      child: Container(
        decoration: BoxDecoration(
          color: fasted ? SD.green.withValues(alpha: .85) : (c ?? Colors.transparent).withValues(alpha: c == null ? 0 : .18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday ? SD.gold : (c == null ? onS.withValues(alpha: .12) : readable(context, c).withValues(alpha: .6)),
            width: isToday ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('${d.day}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: fasted ? Colors.white : null)),
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(fasted ? '✓' : '${f.hijri.d}', style: TextStyle(fontSize: 10, color: fasted ? Colors.white : onS.withValues(alpha: .6))),
            ),
          ),
        ]),
      ),
    );
  }
}
