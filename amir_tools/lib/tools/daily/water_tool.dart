import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'daily_common.dart';

class WaterTool extends StatefulWidget {
  const WaterTool({super.key});
  @override
  State<WaterTool> createState() => _WaterToolState();
}

class _WaterToolState extends State<WaterTool> {
  double weight = 70;
  bool hot = true;
  int activity = 0;
  int? customGoal;
  final wC = TextEditingController(), aC = TextEditingController(), gC = TextEditingController(), customC = TextEditingController();

  @override
  void initState() {
    super.initState();
    final c = context.read<AppState>().getData<Map>('water_cfg');
    if (c != null) {
      weight = (c['w'] as num?)?.toDouble() ?? 70;
      hot = c['hot'] ?? true;
      activity = (c['act'] as num?)?.toInt() ?? 0;
      customGoal = (c['goal'] as num?)?.toInt();
    }
    wC.text = fmt(weight, 1);
    aC.text = activity == 0 ? '' : '$activity';
    gC.text = customGoal?.toString() ?? '';
  }

  @override
  void dispose() {
    wC.dispose();
    aC.dispose();
    gC.dispose();
    customC.dispose();
    super.dispose();
  }

  int get suggested {
    final v = weight * 35 + (hot ? 750 : 0) + (activity / 30) * 350;
    return ((v / 50).round() * 50).clamp(1000, 7000).toInt();
  }

  int get goal => customGoal ?? suggested;

  void _saveCfg() => context.read<AppState>().setData('water_cfg', {'w': weight, 'hot': hot, 'act': activity, 'goal': customGoal});

  Map<String, dynamic> _log(AppState s) => Map<String, dynamic>.from(s.getData<Map>('water_log') ?? {});

  List<int> _items(AppState s) {
    final m = s.getData<Map>('water_items');
    if (m == null || m['d'] != dkey(DateTime.now())) return [];
    return List<int>.from((m['i'] as List).map((e) => (e as num).toInt()));
  }

  void _add(int ml) {
    if (ml == 0) return;
    final s = context.read<AppState>();
    final k = dkey(DateTime.now());
    final log = _log(s);
    final before = (log[k] as num?)?.toInt() ?? 0;
    final after = (before + ml).clamp(0, 20000);
    log[k] = after;
    final keys = log.keys.toList()..sort();
    for (final old in keys.take(keys.length > 90 ? keys.length - 90 : 0)) {
      log.remove(old);
    }
    s.setData('water_log', log);
    final items = _items(s);
    if (ml > 0) {
      items.add(ml);
    } else if (items.isNotEmpty) {
      items.removeLast();
    }
    s.setData('water_items', {'d': k, 'i': items});
    if (ml > 0) HapticFeedback.lightImpact();
    if (before < goal && after >= goal && s.getData<String>('water_bumped') != k) {
      s.setData('water_bumped', k);
      s.bump('water_goal_days');
      s.awardDaily('water_goal', 15, t('وصلت هدف الموية', 'وصلت هدف الماء', 'Reached water goal'));
      toast(t('💧 روّيت! وصلت هدف الموية الليلة — +15 نقطة', '💧 أحسنت! وصلت هدف الماء اليوم — +15 نقطة', "💧 Hydrated! You hit today's water goal — +15 points"));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now();
    final log = _log(s);
    final today = (log[dkey(now)] as num?)?.toInt() ?? 0;
    final items = _items(s);
    final p = today / goal;
    final left = (goal - today).clamp(0, 99999);

    // الوتيرة: من 7 الصباح لـ 10 بالليل
    final wakeMins = (now.hour * 60 + now.minute - 7 * 60).clamp(0, 15 * 60);
    final shouldBe = (goal * wakeMins / (15 * 60)).round();

    // الأسبوع والسلسلة
    final bars = <Bar>[];
    var weekTotal = 0, metDays = 0, best = 0;
    for (var i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final v = (log[dkey(d)] as num?)?.toInt() ?? 0;
      weekTotal += v;
      if (v >= goal) metDays++;
      if (v > best) best = v;
      bars.add(Bar(i == 0 ? t('الليلة', 'اليوم', 'Today') : shortDays[d.weekday - 1], v / 1000, color: v >= goal ? SD.teal : SD.nileLight));
    }
    var streak = 0;
    for (var i = today >= goal ? 0 : 1; i < 90; i++) {
      final v = (log[dkey(now.subtract(Duration(days: i)))] as num?)?.toInt() ?? 0;
      if (v >= goal) {
        streak++;
      } else {
        break;
      }
    }

    return ToolList(children: [
      SCard(
        color: SD.nileLight,
        child: Column(children: [
          ProgressRing(
            progress: p,
            color: p >= 1 ? SD.teal : SD.nileLight,
            size: 210,
            stroke: 16,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('💧', style: TextStyle(fontSize: 30)),
              Text(fmt(today / 1000, 2), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: SD.nileLight)),
              Text(tr('من ${fmt(goal / 1000, 2)} لتر', 'of ${fmt(goal / 1000, 2)} L'), style: const TextStyle(fontSize: 13)),
              Text('${fmt(p * 100, 0)}%', style: const TextStyle(fontWeight: FontWeight.w800, color: SD.gold)),
            ]),
          ),
          const SizedBox(height: 10),
          Text(
            p >= 1
                ? t('روّيت يا زول! كمّلت هدف الليلة 🎉', 'أحسنت! أكملت هدف اليوم 🎉', "Well hydrated! Today's goal done 🎉")
                : (today >= shouldBe
                    ? t('ماشي تمام، واصل كدا 👌', 'أنت على المسار، واصل 👌', "You're on track, keep it up 👌")
                    : t('متأخر شوية — المفروض تكون شربت حوالي ${fmt(shouldBe / 1000, 1)} لتر لحد هسي', 'متأخر قليلًا — كان ينبغي أن تشرب نحو ${fmt(shouldBe / 1000, 1)} لتر حتى الآن',
                        "A bit behind — you should've had about ${fmt(shouldBe / 1000, 1)} L by now")),
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, color: p >= 1 ? SD.teal : (today >= shouldBe ? SD.green : SD.henna)),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            _cup(t('كباية', 'كوب', 'Glass'), 250, Icons.local_drink_rounded),
            _cup(t('كوز', 'كوب كبير', 'Mug'), 400, Icons.coffee_rounded),
            _cup(t('قزازة صغيرة', 'زجاجة صغيرة', 'Small bottle'), 500, Icons.water_drop_rounded),
            _cup(t('قزازة كبيرة', 'زجاجة كبيرة', 'Large bottle'), 1500, Icons.liquor_rounded),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: NumField(t('كمية تانية', 'كمية أخرى', 'Other amount'), customC, suffix: tr('مل', 'ml'), decimal: false)),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 10),
              child: FilledButton(
                onPressed: () {
                  final v = parseNum(customC.text).round();
                  if (v <= 0) return toast(t('أكتب الكمية بالمل', 'اكتب الكمية بالمل', 'Enter the amount in ml'));
                  _add(v);
                  customC.clear();
                  FocusScope.of(context).unfocus();
                },
                child: Text(t('ضيف', 'أضف', 'Add')),
              ),
            ),
          ]),
          if (items.isNotEmpty)
            TextButton.icon(
              onPressed: () => _add(-items.last),
              icon: const Icon(Icons.undo_rounded),
              label: Text(tr('تراجع عن آخر ${items.last} مل', 'Undo last ${items.last} ml')),
            ),
        ]),
      ),
      StatGrid([
        StatChip('${(left / 250).ceil()}', t('كبايات باقية', 'أكواب متبقية', 'Glasses left'), color: SD.nile, icon: Icons.local_drink_rounded),
        StatChip(fmt(left / 1000, 2), t('لتر باقي', 'لتر متبقٍ', 'Liters left'), color: SD.nileLight, icon: Icons.water_rounded),
        StatChip('${items.length}', tr('مرات الشرب', 'Drinks'), color: SD.teal, icon: Icons.touch_app_rounded),
        StatChip('$streak', t('أيام ورا بعض', 'أيام متتالية', 'Day streak'), color: SD.orange, icon: Icons.local_fire_department_rounded),
        StatChip('$metDays/7', tr('أيام الهدف', 'Goal days'), color: SD.green, icon: Icons.verified_rounded),
        StatChip(fmt(weekTotal / 7000, 2), tr('متوسط لتر/يوم', 'Avg L/day'), color: SD.gold, icon: Icons.timeline_rounded),
      ]),
      const SizedBox(height: 12),
      SCard(
        title: tr('الأسبوع (باللتر)', 'This week (liters)'),
        icon: Icons.bar_chart_rounded,
        color: SD.nile,
        trailing: Text(t('أحسن يوم ${fmt(best / 1000, 1)} ل', 'أفضل يوم ${fmt(best / 1000, 1)} ل', 'Best day ${fmt(best / 1000, 1)} L'), style: const TextStyle(fontSize: 12)),
        child: Column(children: [
          BarChart(bars, goal: goal / 1000, color: SD.nileLight, valueText: (v) => v == 0 ? '' : fmt(v, 1)),
          const SizedBox(height: 6),
          Text(t('الخط الدهبي = هدفك اليومي', 'الخط الذهبي = هدفك اليومي', 'Gold line = your daily goal'), style: const TextStyle(fontSize: 11.5)),
        ]),
      ),
      SCard(
        title: t('هدفك كم؟', 'كم هدفك؟', "What's your goal?"),
        icon: Icons.tune_rounded,
        color: SD.teal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField(tr('وزنك', 'Your weight'), wC, suffix: tr('كجم', 'kg'), onChanged: (v) {
            final w = parseNum(v);
            if (w > 20 && w < 300) {
              setState(() => weight = w);
              _saveCfg();
            }
          }),
          NumField(t('رياضة/شغل شاق في اليوم', 'رياضة/عمل شاق يوميًا', 'Exercise/hard work per day'), aC, suffix: tr('دقيقة', 'min'), decimal: false, onChanged: (v) {
            setState(() => activity = parseNum(v).round().clamp(0, 600));
            _saveCfg();
          }),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('الجو حار؟', 'Hot weather?')),
            subtitle: Text(t('في السودان غالبًا أيوه 😅 — بنزيد 750 مل', 'في السودان غالبًا نعم 😅 — نضيف 750 مل', 'Adds 750 ml for hot climates (most of the year in Sudan 😅)')),
            value: hot,
            onChanged: (v) {
              setState(() => hot = v);
              _saveCfg();
            },
          ),
          InfoRow(t('الهدف المقترح ليك', 'الهدف المقترح لك', 'Suggested goal'), tr('${fmt(suggested / 1000, 2)} لتر', '${fmt(suggested / 1000, 2)} L'),
              icon: Icons.auto_awesome_rounded,
              valueColor: SD.teal,
              hint: tr('35 مل لكل كيلو${hot ? ' + 750 للحر' : ''}${activity > 0 ? ' + 350 لكل نص ساعة نشاط' : ''}',
                  '35 ml per kg${hot ? ' + 750 for heat' : ''}${activity > 0 ? ' + 350 per half hour of activity' : ''}')),
          InfoRow(t('يعني بالكبايات', 'أي بالأكواب', 'In glasses'), tr('${(suggested / 250).ceil()} كباية (250 مل)', '${(suggested / 250).ceil()} glasses (250 ml)'), icon: Icons.local_drink_rounded),
          const SizedBox(height: 8),
          NumField(t('أو حدّد هدفك براك', 'أو حدّد هدفك بنفسك', 'Or set your own goal'), gC,
              suffix: tr('مل', 'ml'), decimal: false, hint: t('فاضي = المقترح', 'فارغ = المقترح', 'Empty = suggested'), onChanged: (v) {
            final g = parseNum(v).round();
            setState(() => customGoal = g >= 500 ? g : null);
            _saveCfg();
          }),
        ]),
      ),
      NoteBox(
          t('نصايح للحر: أشرب على دفعات طول اليوم حتى لو ما عطشان، كتّر من الموية في الهبوب وبعد الشغل في الشمس، وعلامات قلة الموية: بول غامق، صداع، دوخة وتعب. المشروبات الغازية والسكرية ما بتحسب زي الموية.',
              'نصائح للحر: اشرب على دفعات طوال اليوم حتى لو لم تكن عطشانًا، وأكثر من الماء في العواصف الترابية وبعد العمل في الشمس. علامات نقص الماء: بول داكن، صداع، دوخة وتعب. المشروبات الغازية والسكرية لا تُحسب كالماء.',
              "Heat tips: sip through the day even if you're not thirsty, drink more during dust storms and after working in the sun. Signs of dehydration: dark urine, headache, dizziness and fatigue. Fizzy and sugary drinks don't count as water."),
          kind: NoteKind.tip),
      NoteBox(
          t('الهدف تقديري عام. مرضى الكلى أو القلب أو اللي عندهم توجيه طبي بتقليل السوائل يمشوا بكلام الدكتور.', 'الهدف تقديري عام. مرضى الكلى أو القلب أو من لديهم توجيه طبي بتقليل السوائل يتبعون إرشادات الطبيب.',
              'The goal is a general estimate. People with kidney or heart conditions, or told to limit fluids, should follow their doctor.'),
          kind: NoteKind.warn),
    ]);
  }

  Widget _cup(String name, int ml, IconData ic) => ActionChip(
        avatar: Icon(ic, color: SD.nileLight, size: 20),
        label: Text('$name +$ml'),
        backgroundColor: SD.nileLight.withValues(alpha: .10),
        side: BorderSide(color: SD.nileLight.withValues(alpha: .35)),
        onPressed: () => _add(ml),
      );
}
