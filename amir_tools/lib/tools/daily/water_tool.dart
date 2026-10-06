import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
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
      s.awardDaily('water_goal', 15, 'وصلت هدف الموية');
      toast('💧 روّيت! وصلت هدف الموية الليلة — +15 نقطة');
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
      bars.add(Bar(i == 0 ? 'الليلة' : shortDays[d.weekday - 1], v / 1000, color: v >= goal ? SD.teal : SD.nileLight));
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
              Text('من ${fmt(goal / 1000, 2)} لتر', style: const TextStyle(fontSize: 13)),
              Text('${fmt(p * 100, 0)}%', style: const TextStyle(fontWeight: FontWeight.w800, color: SD.gold)),
            ]),
          ),
          const SizedBox(height: 10),
          Text(
            p >= 1
                ? 'روّيت يا زول! كمّلت هدف الليلة 🎉'
                : (today >= shouldBe ? 'ماشي تمام، واصل كدا 👌' : 'متأخر شوية — المفروض تكون شربت حوالي ${fmt(shouldBe / 1000, 1)} لتر لحد هسي'),
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, color: p >= 1 ? SD.teal : (today >= shouldBe ? SD.green : SD.henna)),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            _cup('كباية', 250, Icons.local_drink_rounded),
            _cup('كوز', 400, Icons.coffee_rounded),
            _cup('قزازة صغيرة', 500, Icons.water_drop_rounded),
            _cup('قزازة كبيرة', 1500, Icons.liquor_rounded),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: NumField('كمية تانية', customC, suffix: 'مل', decimal: false)),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FilledButton(
                onPressed: () {
                  final v = parseNum(customC.text).round();
                  if (v <= 0) return toast('أكتب الكمية بالمل');
                  _add(v);
                  customC.clear();
                  FocusScope.of(context).unfocus();
                },
                child: const Text('ضيف'),
              ),
            ),
          ]),
          if (items.isNotEmpty)
            TextButton.icon(
              onPressed: () => _add(-items.last),
              icon: const Icon(Icons.undo_rounded),
              label: Text('تراجع عن آخر ${items.last} مل'),
            ),
        ]),
      ),
      StatGrid([
        StatChip('${(left / 250).ceil()}', 'كبايات باقية', color: SD.nile, icon: Icons.local_drink_rounded),
        StatChip(fmt(left / 1000, 2), 'لتر باقي', color: SD.nileLight, icon: Icons.water_rounded),
        StatChip('${items.length}', 'مرات الشرب', color: SD.teal, icon: Icons.touch_app_rounded),
        StatChip('$streak', 'أيام ورا بعض', color: SD.orange, icon: Icons.local_fire_department_rounded),
        StatChip('$metDays/7', 'أيام الهدف', color: SD.green, icon: Icons.verified_rounded),
        StatChip(fmt(weekTotal / 7000, 2), 'متوسط لتر/يوم', color: SD.gold, icon: Icons.timeline_rounded),
      ]),
      const SizedBox(height: 12),
      SCard(
        title: 'الأسبوع (باللتر)',
        icon: Icons.bar_chart_rounded,
        color: SD.nile,
        trailing: Text('أحسن يوم ${fmt(best / 1000, 1)} ل', style: const TextStyle(fontSize: 12)),
        child: Column(children: [
          BarChart(bars, goal: goal / 1000, color: SD.nileLight, valueText: (v) => v == 0 ? '' : fmt(v, 1)),
          const SizedBox(height: 6),
          const Text('الخط الدهبي = هدفك اليومي', style: TextStyle(fontSize: 11.5)),
        ]),
      ),
      SCard(
        title: 'هدفك كم؟',
        icon: Icons.tune_rounded,
        color: SD.teal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField('وزنك', wC, suffix: 'كجم', onChanged: (v) {
            final w = parseNum(v);
            if (w > 20 && w < 300) {
              setState(() => weight = w);
              _saveCfg();
            }
          }),
          NumField('رياضة/شغل شاق في اليوم', aC, suffix: 'دقيقة', decimal: false, onChanged: (v) {
            setState(() => activity = parseNum(v).round().clamp(0, 600));
            _saveCfg();
          }),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('الجو حار؟'),
            subtitle: const Text('في السودان غالبًا أيوه 😅 — بنزيد 750 مل'),
            value: hot,
            onChanged: (v) {
              setState(() => hot = v);
              _saveCfg();
            },
          ),
          InfoRow('الهدف المقترح ليك', '${fmt(suggested / 1000, 2)} لتر', icon: Icons.auto_awesome_rounded, valueColor: SD.teal,
              hint: '35 مل لكل كيلو${hot ? ' + 750 للحر' : ''}${activity > 0 ? ' + 350 لكل نص ساعة نشاط' : ''}'),
          InfoRow('يعني بالكبايات', '${(suggested / 250).ceil()} كباية (250 مل)', icon: Icons.local_drink_rounded),
          const SizedBox(height: 8),
          NumField('أو حدّد هدفك براك', gC, suffix: 'مل', decimal: false, hint: 'فاضي = المقترح', onChanged: (v) {
            final g = parseNum(v).round();
            setState(() => customGoal = g >= 500 ? g : null);
            _saveCfg();
          }),
        ]),
      ),
      const NoteBox(
          'نصايح للحر: أشرب على دفعات طول اليوم حتى لو ما عطشان، كتّر من الموية في الهبوب وبعد الشغل في الشمس، وعلامات قلة الموية: بول غامق، صداع، دوخة وتعب. المشروبات الغازية والسكرية ما بتحسب زي الموية.',
          kind: NoteKind.tip),
      const NoteBox('الهدف تقديري عام. مرضى الكلى أو القلب أو اللي عندهم توجيه طبي بتقليل السوائل يمشوا بكلام الدكتور.', kind: NoteKind.warn),
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
