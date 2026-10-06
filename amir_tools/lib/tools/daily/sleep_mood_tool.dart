import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'daily_common.dart';

const _moods = [
  ('😫', 'تعبان شديد', SD.red),
  ('😕', 'ما تمام', SD.orange),
  ('😐', 'عادي', SD.gold),
  ('🙂', 'كويس', SD.teal),
  ('😄', 'مبسوط شديد', SD.green),
];

const _tips = [
  'نوم البالغين المنصوح بيهو 7 لـ 9 ساعات في الليلة.',
  'نوم وصحيان في نفس المواعيد كل يوم — حتى في الجمعة — بيظبط ساعتك الداخلية.',
  'قلّل الشاي والقهوة والجبنة بعد العصر، الكافيين بيقعد في جسمك ساعات.',
  'الموبايل والشاشات قبل النوم بساعة بتصعّب النومة — خليهو بعيد.',
  'الأوضة تكون باردة وضلمة وهادية؛ في الحر المروحة أو المكيف بيفرقوا كتير.',
  'العشا الخفيف قبل النوم بساعتين أحسن من الأكل التقيل.',
  'القيلولة القصيرة (20–30 دقيقة) بعد الضهر مفيدة، الطويلة بتخرب نومة الليل.',
  'أذكار النوم والوضوء قبل ما ترقد بيريّحوا القلب.',
  'لو المزاج نازل لفترة طويلة أو النوم متلخبط شديد، الكلام مع زول بتثق فيهو أو دكتور ما عيب.',
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
    final t = await showTimePicker(
      context: context,
      initialTime: isBed ? bed : wake,
      helpText: isBed ? 'رقدت متين؟' : 'صحيت متين؟',
      cancelText: 'خلاص',
      confirmText: 'تمام',
    );
    if (t == null) return;
    setState(() {
      isBed ? bed = t : wake = t;
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
    s.awardDaily('sleep_log', 5, 'سجّلت نومك ومزاجك');
    FocusScope.of(context).unfocus();
    toast('اتسجّل تمام ✓');
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
        title: has ? 'عدّل يومك' : 'نمت كيف؟',
        icon: Icons.bedtime_rounded,
        color: SD.indigo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DateButton(
            label: 'اليوم (صباح الصحيان)',
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
            Expanded(child: OutlinedButton.icon(onPressed: () => _pick(true), icon: const Icon(Icons.nightlight_round), label: Text('رقدت ${_t(bed)}'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () => _pick(false), icon: const Icon(Icons.wb_sunny_rounded), label: Text('صحيت ${_t(wake)}'))),
          ]),
          const SizedBox(height: 12),
          Text('ساعات النوم: ${fmt(hours, 1)} ساعة', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: SD.indigo)),
          Slider(value: hours, min: 0, max: 14, divisions: 28, label: fmt(hours, 1), activeColor: SD.indigo, onChanged: (v) => setState(() => hours = v)),
          const SizedBox(height: 4),
          const Text('مزاجك كيف؟', style: TextStyle(fontWeight: FontWeight.w700)),
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
            decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)', hintText: 'أكتب هنا… مثلًا: سهرت مع الجماعة'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: SD.indigo),
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            label: Text(has ? 'حدّث' : 'سجّل'),
          ),
        ]),
      ),
      if (last14.isEmpty)
        const NoteBox('سجّل نومك ومزاجك كل يوم، وبعد كم يوم بنوريك المتوسطات والرسم والعلاقة بين نومك ومزاجك.', kind: NoteKind.tip)
      else ...[
        StatGrid([
          StatChip(fmt(a7, 1), 'متوسط نوم 7 أيام', color: SD.indigo, icon: Icons.bedtime_rounded),
          StatChip(fmt(a14, 1), 'متوسط 14 يوم', color: SD.purple, icon: Icons.nights_stay_rounded),
          StatChip('${_moods[(m14.round() - 1).clamp(0, 4)].$1} ${fmt(m14, 1)}', 'متوسط المزاج', color: SD.pink, icon: Icons.mood_rounded),
          StatChip(fmt(debt, 1), 'ساعات ناقصة (أسبوع)', color: SD.red, icon: Icons.trending_down_rounded),
          StatChip('± ${fmt(sd, 1)}', 'ثبات النوم', color: SD.teal, icon: Icons.straighten_rounded),
          StatChip('$streak', 'أيام تسجيل ورا بعض', color: SD.orange, icon: Icons.local_fire_department_rounded),
        ]),
        const SizedBox(height: 12),
        SCard(
          title: 'آخر 14 يوم',
          icon: Icons.insights_rounded,
          color: SD.indigo,
          child: Column(children: [
            BarChart(bars, maxValue: 10, goal: 8, color: SD.indigo, valueText: (v) => v == 0 ? '' : fmt(v, 1), dotMax: 5, dotColor: SD.pink, height: 190),
            const SizedBox(height: 6),
            const Text('الأعمدة = ساعات النوم • النقاط الوردية = المزاج • الخط الدهبي = 8 ساعات', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5)),
          ]),
        ),
        SCard(
          title: 'شنو الواضح؟',
          icon: Icons.lightbulb_rounded,
          color: SD.gold,
          child: Column(children: [
            if (avgBed != null) InfoRow('متوسط وقت الرقاد', avgBed, icon: Icons.nightlight_round),
            InfoRow('أطول نومة', '${fmt(last14.map((e) => (e['h'] as num).toDouble()).reduce(math.max), 1)} ساعة', icon: Icons.arrow_upward_rounded),
            InfoRow('أقصر نومة', '${fmt(last14.map((e) => (e['h'] as num).toDouble()).reduce(math.min), 1)} ساعة', icon: Icons.arrow_downward_rounded),
            InfoRow('ليالي 7 ساعات وفوق', '${good.length} من ${last14.length}', icon: Icons.check_circle_rounded, valueColor: SD.green),
            if (good.isNotEmpty && bad.isNotEmpty)
              InfoRow('مزاجك لمن تنوم كويس', '${fmt(avg(good, 'm'), 1)} مقابل ${fmt(avg(bad, 'm'), 1)}',
                  icon: Icons.compare_arrows_rounded,
                  hint: avg(good, 'm') > avg(bad, 'm') ? 'النومة الكويسة بتعدّل مزاجك 👌' : 'ما في فرق واضح لسه',
                  valueColor: SD.pink),
            InfoRow('التقييم', a7 >= 7 && a7 <= 9 ? 'نومك تمام كدا 👍' : (a7 < 7 ? 'نومك قليل — حاول ترقد بدري' : 'نومك كتير شوية'),
                icon: Icons.grade_rounded, valueColor: a7 >= 7 && a7 <= 9 ? SD.green : SD.henna),
          ]),
        ),
        SCard(
          title: 'السجل',
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
                  subtitle: Text('${fmt((e['h'] as num), 1)} ساعة${(e['n'] as String?)?.isNotEmpty == true ? ' — ${e['n']}' : ''}'),
                  onTap: () => setState(() {
                    day = d;
                    _loadDay();
                  }),
                  trailing: IconButton(
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
              '😴 ملخص نومي ومزاجي',
              'متوسط النوم (7 أيام): ${fmt(a7, 1)} ساعة',
              'متوسط النوم (14 يوم): ${fmt(a14, 1)} ساعة',
              'متوسط المزاج: ${fmt(m14, 1)} من 5',
              'ساعات ناقصة الأسبوع: ${fmt(debt, 1)}',
            ].join('\n')),
      ],
      SectionTitle('نصايح لنومة هنية', icon: Icons.tips_and_updates_rounded),
      for (final t in _tips) NoteBox(t, kind: NoteKind.tip),
      const NoteBox('الأداة دي للمتابعة الشخصية بس وما بتشخّص أي حالة. الأرق الطويل أو الحزن المستمر محتاجين دكتور.', kind: NoteKind.warn),
    ]);
  }
}
