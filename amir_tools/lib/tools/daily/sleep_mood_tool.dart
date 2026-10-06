import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'daily_common.dart';

List<(String, String, Color)> get _moods => [
      ('😫', t('تعبان شديد', 'متعب جدًا', 'Exhausted'), SD.red),
      ('😕', t('ما تمام', 'لست بخير', 'Not great'), SD.orange),
      ('😐', tr('عادي', 'Okay'), SD.gold),
      ('🙂', t('كويس', 'جيد', 'Good'), SD.teal),
      ('😄', t('مبسوط شديد', 'سعيد جدًا', 'Great'), SD.green),
    ];

List<String> get _tips => [
      t('نوم البالغين المنصوح بيهو 7 لـ 9 ساعات في الليلة.', 'النوم الموصى به للبالغين من 7 إلى 9 ساعات في الليلة.', 'Adults are advised to sleep 7 to 9 hours a night.'),
      t('نوم وصحيان في نفس المواعيد كل يوم — حتى في الجمعة — بيظبط ساعتك الداخلية.', 'النوم والاستيقاظ في المواعيد نفسها يوميًا — حتى في العطلة — يضبط ساعتك الداخلية.',
          'Sleeping and waking at the same times every day — weekends too — sets your body clock.'),
      t('قلّل الشاي والقهوة والجبنة بعد العصر، الكافيين بيقعد في جسمك ساعات.', 'قلّل الشاي والقهوة بعد العصر، فالكافيين يبقى في جسمك ساعات.',
          'Cut back on tea and coffee after mid-afternoon — caffeine stays in your body for hours.'),
      t('الموبايل والشاشات قبل النوم بساعة بتصعّب النومة — خليهو بعيد.', 'الهاتف والشاشات قبل النوم بساعة تُصعّب النوم — أبعده.',
          'Phones and screens in the hour before bed make it harder to fall asleep — keep them away.'),
      t('الأوضة تكون باردة وضلمة وهادية؛ في الحر المروحة أو المكيف بيفرقوا كتير.', 'اجعل الغرفة باردة ومظلمة وهادئة؛ وفي الحر تُحدث المروحة أو المكيّف فرقًا كبيرًا.',
          'Keep the room cool, dark and quiet; in hot weather a fan or AC makes a big difference.'),
      t('العشا الخفيف قبل النوم بساعتين أحسن من الأكل التقيل.', 'العشاء الخفيف قبل النوم بساعتين أفضل من الوجبة الثقيلة.', 'A light dinner two hours before bed beats a heavy meal.'),
      t('القيلولة القصيرة (20–30 دقيقة) بعد الضهر مفيدة، الطويلة بتخرب نومة الليل.', 'القيلولة القصيرة (20–30 دقيقة) بعد الظهر مفيدة، أما الطويلة فتُفسد نوم الليل.',
          'A short nap (20–30 minutes) after midday helps; long naps ruin night sleep.'),
      t('أذكار النوم والوضوء قبل ما ترقد بيريّحوا القلب.', 'أذكار النوم والوضوء قبل النوم يريحان القلب.', 'Sleep adhkar and making wudu before bed bring calm to the heart.'),
      t('لو المزاج نازل لفترة طويلة أو النوم متلخبط شديد، الكلام مع زول بتثق فيهو أو دكتور ما عيب.',
          'إن استمر انخفاض المزاج طويلًا أو اضطرب النوم كثيرًا، فلا عيب في الحديث مع شخص تثق به أو مع طبيب.',
          "If your mood stays low for long or your sleep is badly disrupted, there's no shame in talking to someone you trust or a doctor."),
    ];

class SleepMoodTool extends StatefulWidget {
  const SleepMoodTool({super.key});
  @override
  State<SleepMoodTool> createState() => _SleepMoodToolState();
}

class _SleepMoodToolState extends State<SleepMoodTool> {
  DateTime day = dateOnly(DateTime.now());
  TimeOfDay bed = const TimeOfDay(hour: 23, minute: 0), wake = const TimeOfDay(hour: 6, minute: 30);
  double hours = 7.5;
  int mood = 4;
  final noteC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDay();
  }

  @override
  void dispose() {
    noteC.dispose();
    super.dispose();
  }

  Map<String, dynamic> _log(AppState s) => Map<String, dynamic>.from(s.getData<Map>('sleep_mood_log') ?? {});

  void _loadDay() {
    final e = _log(context.read<AppState>())[dkey(day)];
    if (e != null) {
      hours = (e['h'] as num).toDouble();
      mood = (e['m'] as num).toInt();
      noteC.text = e['n'] ?? '';
      if (e['b'] != null) bed = TimeOfDay(hour: e['b'] ~/ 60, minute: e['b'] % 60);
      if (e['w'] != null) wake = TimeOfDay(hour: e['w'] ~/ 60, minute: e['w'] % 60);
    } else {
      noteC.clear();
    }
  }

  double _calc(TimeOfDay b, TimeOfDay w) {
    var m = (w.hour * 60 + w.minute) - (b.hour * 60 + b.minute);
    if (m <= 0) m += 24 * 60;
    return (m / 30).round() / 2;
  }

  Future<void> _pick(bool isBed) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isBed ? bed : wake,
      helpText: isBed ? t('رقدت متين؟', 'متى نمت؟', 'When did you go to bed?') : t('صحيت متين؟', 'متى استيقظت؟', 'When did you wake up?'),
      cancelText: t('خلاص', 'إلغاء', 'Cancel'),
      confirmText: t('تمام', 'موافق', 'OK'),
    );
    if (picked == null) return;
    setState(() {
      isBed ? bed = picked : wake = picked;
      hours = _calc(bed, wake);
    });
  }

  void _save() {
    final s = context.read<AppState>();
    final log = _log(s);
    log[dkey(day)] = {'h': hours, 'm': mood, 'n': noteC.text.trim(), 'b': bed.hour * 60 + bed.minute, 'w': wake.hour * 60 + wake.minute};
    final keys = log.keys.toList()..sort();
    for (final old in keys.take(keys.length > 120 ? keys.length - 120 : 0)) {
      log.remove(old);
    }
    s.setData('sleep_mood_log', log);
    s.awardDaily('sleep_log', 5, tr('سجّلت نومك ومزاجك', 'Logged sleep and mood'));
    FocusScope.of(context).unfocus();
    toast(t('اتسجّل تمام ✓', 'تم التسجيل ✓', 'Logged ✓'));
    setState(() {});
  }

  String _t(TimeOfDay t) => fmtTimeAr(DateTime(2000, 1, 1, t.hour, t.minute));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final log = _log(s);
    final now = dateOnly(DateTime.now());
    final has = log.containsKey(dkey(day));

    // آخر 14 يوم
    final bars = <Bar>[];
    final last14 = <Map>[], last7 = <Map>[];
    for (var i = 13; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final e = log[dkey(d)];
      if (e != null) {
        last14.add(e);
        if (i < 7) last7.add(e);
      }
      final h = (e?['h'] as num?)?.toDouble() ?? 0;
      bars.add(Bar('${d.day}', h,
          color: e == null ? SD.indigo.withValues(alpha: .3) : (h >= 7 && h <= 9 ? SD.indigo : (h < 6 ? SD.red : SD.purple)),
          dot: (e?['m'] as num?)?.toDouble()));
    }
    double avg(List<Map> l, String k) => l.isEmpty ? 0 : l.map((e) => (e[k] as num).toDouble()).reduce((a, b) => a + b) / l.length;
    final a7 = avg(last7, 'h'), a14 = avg(last14, 'h'), m14 = avg(last14, 'm');
    final debt = last7.fold<double>(0, (p, e) => p + math.max(0, 8 - (e['h'] as num).toDouble()));
    final good = last14.where((e) => (e['h'] as num) >= 7).toList();
    final bad = last14.where((e) => (e['h'] as num) < 7).toList();
    double sd = 0;
    if (last14.length > 1) {
      sd = math.sqrt(last14.map((e) => math.pow((e['h'] as num) - a14, 2)).reduce((a, b) => a + b) / last14.length);
    }
    // متوسط وقت الرقاد (نزحزح بـ 12 ساعة عشان نص الليل)
    final beds = last14.where((e) => e['b'] != null).map((e) => ((e['b'] as int) + 12 * 60) % (24 * 60)).toList();
    String? avgBed;
    if (beds.isNotEmpty) {
      final m = (beds.reduce((a, b) => a + b) / beds.length).round();
      final real = (m - 12 * 60 + 24 * 60) % (24 * 60);
      avgBed = fmtTimeAr(DateTime(2000, 1, 1, real ~/ 60, real % 60));
    }
    var streak = 0;
    for (var i = log.containsKey(dkey(now)) ? 0 : 1; i < 120; i++) {
      if (log.containsKey(dkey(now.subtract(Duration(days: i))))) {
        streak++;
      } else {
        break;
      }
    }
    final entries = log.keys.toList()..sort((a, b) => b.compareTo(a));

    return ToolList(children: [
      SCard(
        title: has ? t('عدّل يومك', 'عدّل يومك', 'Edit your day') : t('نمت كيف؟', 'كيف نمت؟', 'How did you sleep?'),
        icon: Icons.bedtime_rounded,
        color: SD.indigo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DateButton(
            label: t('اليوم (صباح الصحيان)', 'اليوم (صباح الاستيقاظ)', 'Day (the morning you woke up)'),
            value: day,
            first: now.subtract(const Duration(days: 120)),
            last: now,
            color: SD.indigo,
            onPick: (d) => setState(() {
              day = d;
              _loadDay();
            }),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _pick(true), icon: const Icon(Icons.nightlight_round), label: Text('${t('رقدت', 'نمت', 'Bed')} ${_t(bed)}'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () => _pick(false), icon: const Icon(Icons.wb_sunny_rounded), label: Text('${t('صحيت', 'استيقظت', 'Woke')} ${_t(wake)}'))),
          ]),
          const SizedBox(height: 12),
          Text(tr('ساعات النوم: ${fmt(hours, 1)} ساعة', 'Sleep: ${fmt(hours, 1)} hours'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: SD.indigo)),
          Slider(value: hours, min: 0, max: 14, divisions: 28, label: fmt(hours, 1), activeColor: SD.indigo, onChanged: (v) => setState(() => hours = v)),
          const SizedBox(height: 4),
          Text(t('مزاجك كيف؟', 'كيف مزاجك؟', "How's your mood?"), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            for (var i = 0; i < 5; i++)
              GestureDetector(
                onTap: () => setState(() => mood = i + 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: mood == i + 1 ? _moods[i].$3.withValues(alpha: .2) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: mood == i + 1 ? _moods[i].$3 : Colors.transparent, width: 2),
                  ),
                  child: Text(_moods[i].$1, style: TextStyle(fontSize: mood == i + 1 ? 36 : 28)),
                ),
              ),
          ]),
          Text(_moods[mood - 1].$2, textAlign: TextAlign.center, style: TextStyle(color: _moods[mood - 1].$3, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          TextField(
            controller: noteC,
            maxLines: 2,
            decoration: InputDecoration(
                labelText: tr('ملاحظة (اختياري)', 'Note (optional)'),
                hintText: t('أكتب هنا… مثلًا: سهرت مع الجماعة', 'اكتب هنا… مثلًا: سهرت مع الأصدقاء', 'Write here… e.g. stayed up with friends')),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: SD.indigo),
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            label: Text(has ? t('حدّث', 'حدّث', 'Update') : t('سجّل', 'سجّل', 'Log')),
          ),
        ]),
      ),
      if (last14.isEmpty)
        NoteBox(
            t('سجّل نومك ومزاجك كل يوم، وبعد كم يوم بنوريك المتوسطات والرسم والعلاقة بين نومك ومزاجك.', 'سجّل نومك ومزاجك يوميًا، وبعد أيام سنعرض لك المتوسطات والرسم والعلاقة بين نومك ومزاجك.',
                "Log your sleep and mood daily; after a few days you'll see averages, a chart and how your sleep relates to your mood."),
            kind: NoteKind.tip)
      else ...[
        StatGrid([
          StatChip(fmt(a7, 1), tr('متوسط نوم 7 أيام', '7-day sleep avg'), color: SD.indigo, icon: Icons.bedtime_rounded),
          StatChip(fmt(a14, 1), tr('متوسط 14 يوم', '14-day avg'), color: SD.purple, icon: Icons.nights_stay_rounded),
          StatChip('${_moods[(m14.round() - 1).clamp(0, 4)].$1} ${fmt(m14, 1)}', tr('متوسط المزاج', 'Avg mood'), color: SD.pink, icon: Icons.mood_rounded),
          StatChip(fmt(debt, 1), tr('ساعات ناقصة (أسبوع)', 'Sleep debt (week)'), color: SD.red, icon: Icons.trending_down_rounded),
          StatChip('± ${fmt(sd, 1)}', tr('ثبات النوم', 'Consistency'), color: SD.teal, icon: Icons.straighten_rounded),
          StatChip('$streak', t('أيام تسجيل ورا بعض', 'أيام تسجيل متتالية', 'Logging streak'), color: SD.orange, icon: Icons.local_fire_department_rounded),
        ]),
        const SizedBox(height: 12),
        SCard(
          title: tr('آخر 14 يوم', 'Last 14 days'),
          icon: Icons.insights_rounded,
          color: SD.indigo,
          child: Column(children: [
            BarChart(bars, maxValue: 10, goal: 8, color: SD.indigo, valueText: (v) => v == 0 ? '' : fmt(v, 1), dotMax: 5, dotColor: SD.pink, height: 190),
            const SizedBox(height: 6),
            Text(
                t('الأعمدة = ساعات النوم • النقاط الوردية = المزاج • الخط الدهبي = 8 ساعات', 'الأعمدة = ساعات النوم • النقاط الوردية = المزاج • الخط الذهبي = 8 ساعات',
                    'Bars = hours slept • pink dots = mood • gold line = 8 hours'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5)),
          ]),
        ),
        SCard(
          title: t('شنو الواضح؟', 'ماذا يتضح؟', 'What stands out?'),
          icon: Icons.lightbulb_rounded,
          color: SD.gold,
          child: Column(children: [
            if (avgBed != null) InfoRow(t('متوسط وقت الرقاد', 'متوسط وقت النوم', 'Average bedtime'), avgBed, icon: Icons.nightlight_round),
            InfoRow(t('أطول نومة', 'أطول نوم', 'Longest sleep'), tr('${fmt(last14.map((e) => (e['h'] as num).toDouble()).reduce(math.max), 1)} ساعة', '${fmt(last14.map((e) => (e['h'] as num).toDouble()).reduce(math.max), 1)} h'),
                icon: Icons.arrow_upward_rounded),
            InfoRow(t('أقصر نومة', 'أقصر نوم', 'Shortest sleep'), tr('${fmt(last14.map((e) => (e['h'] as num).toDouble()).reduce(math.min), 1)} ساعة', '${fmt(last14.map((e) => (e['h'] as num).toDouble()).reduce(math.min), 1)} h'),
                icon: Icons.arrow_downward_rounded),
            InfoRow(t('ليالي 7 ساعات وفوق', 'ليالٍ بـ 7 ساعات فأكثر', 'Nights with 7+ hours'), tr('${good.length} من ${last14.length}', '${good.length} of ${last14.length}'),
                icon: Icons.check_circle_rounded, valueColor: SD.green),
            if (good.isNotEmpty && bad.isNotEmpty)
              InfoRow(t('مزاجك لمن تنوم كويس', 'مزاجك عندما تنام جيدًا', 'Mood after good sleep'), tr('${fmt(avg(good, 'm'), 1)} مقابل ${fmt(avg(bad, 'm'), 1)}', '${fmt(avg(good, 'm'), 1)} vs ${fmt(avg(bad, 'm'), 1)}'),
                  icon: Icons.compare_arrows_rounded,
                  hint: avg(good, 'm') > avg(bad, 'm')
                      ? t('النومة الكويسة بتعدّل مزاجك 👌', 'النوم الجيد يحسّن مزاجك 👌', 'Good sleep lifts your mood 👌')
                      : t('ما في فرق واضح لسه', 'لا يوجد فرق واضح بعد', 'No clear difference yet'),
                  valueColor: SD.pink),
            InfoRow(
                tr('التقييم', 'Verdict'),
                a7 >= 7 && a7 <= 9
                    ? t('نومك تمام كدا 👍', 'نومك جيد 👍', 'Your sleep looks good 👍')
                    : (a7 < 7 ? t('نومك قليل — حاول ترقد بدري', 'نومك قليل — حاول النوم مبكرًا', 'Too little sleep — try going to bed earlier') : t('نومك كتير شوية', 'نومك أكثر قليلًا من اللازم', 'A bit more sleep than needed')),
                icon: Icons.grade_rounded,
                valueColor: a7 >= 7 && a7 <= 9 ? SD.green : SD.henna),
          ]),
        ),
        SCard(
          title: tr('السجل', 'Log'),
          icon: Icons.history_rounded,
          color: SD.purple,
          child: Column(children: [
            for (final k in entries.take(14))
              Builder(builder: (_) {
                final e = log[k] as Map;
                final d = DateTime.parse(k);
                final mi = ((e['m'] as num).toInt() - 1).clamp(0, 4);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(_moods[mi].$1, style: const TextStyle(fontSize: 28)),
                  title: Text(fmtDateAr(d)),
                  subtitle: Text('${fmt((e['h'] as num), 1)} ${tr('ساعة', 'h')}${(e['n'] as String?)?.isNotEmpty == true ? ' — ${e['n']}' : ''}'),
                  onTap: () => setState(() {
                    day = d;
                    _loadDay();
                  }),
                  trailing: IconButton(
                    tooltip: t('امسح', 'احذف', 'Delete'),
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () {
                      final l = _log(s)..remove(k);
                      s.setData('sleep_mood_log', l);
                      setState(() {});
                    },
                  ),
                );
              }),
          ]),
        ),
        ShareBar(() => [
              tr('😴 ملخص نومي ومزاجي', '😴 My sleep & mood summary'),
              tr('متوسط النوم (7 أيام): ${fmt(a7, 1)} ساعة', 'Average sleep (7 days): ${fmt(a7, 1)} h'),
              tr('متوسط النوم (14 يوم): ${fmt(a14, 1)} ساعة', 'Average sleep (14 days): ${fmt(a14, 1)} h'),
              tr('متوسط المزاج: ${fmt(m14, 1)} من 5', 'Average mood: ${fmt(m14, 1)} of 5'),
              tr('ساعات ناقصة الأسبوع: ${fmt(debt, 1)}', 'Sleep debt this week: ${fmt(debt, 1)} h'),
            ].join('\n')),
      ],
      SectionTitle(t('نصايح لنومة هنية', 'نصائح لنوم هانئ', 'Tips for better sleep'), icon: Icons.tips_and_updates_rounded),
      for (final tip in _tips) NoteBox(tip, kind: NoteKind.tip),
      NoteBox(
          t('الأداة دي للمتابعة الشخصية بس وما بتشخّص أي حالة. الأرق الطويل أو الحزن المستمر محتاجين دكتور.', 'هذه الأداة للمتابعة الشخصية فقط ولا تشخّص أي حالة. الأرق الطويل أو الحزن المستمر يحتاجان إلى طبيب.',
              "This tool is for personal tracking only and doesn't diagnose anything. Long-term insomnia or persistent sadness need a doctor."),
          kind: NoteKind.warn),
    ]);
  }
}
