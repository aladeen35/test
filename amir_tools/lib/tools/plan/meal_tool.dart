import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'plan_common.dart';

/// طبق جاهز: الاسم بثلاث لغات + المكوّنات «عربي|English»
class Dish {
  final String id, emoji, sd, ar, en;
  final String meals; // b l d
  final List<String> ings;
  const Dish(this.id, this.emoji, this.sd, this.ar, this.en, this.meals, this.ings);
  String get name => t(sd, ar, en);
}

String ingName(String s) {
  final p = s.split('|');
  return isEn && p.length > 1 ? p[1] : p[0];
}

const builtinDishes = [
  Dish('ful', '🫘', 'فول بالزيت والجبنة', 'فول مدمس', 'Ful (fava beans)', 'bd', ['فول|Fava beans', 'زيت سمسم|Sesame oil', 'جبنة بيضاء|White cheese', 'طماطم|Tomatoes', 'بصل|Onions', 'كمون|Cumin', 'رغيف|Bread']),
  Dish('taamia', '🧆', 'طعمية', 'طعمية', "Ta'amia (falafel)", 'bd', ['كبكبي|Chickpeas', 'بصل|Onions', 'توم|Garlic', 'كزبرة|Coriander', 'زيت قلي|Frying oil', 'رغيف|Bread']),
  Dish('asida_rob', '🥣', 'عصيدة بملاح الروب', 'عصيدة بملاح الروب', 'Asida with rob stew', 'l', ['دقيق ذرة|Sorghum flour', 'روب|Rob (fermented yogurt)', 'دكوة|Peanut butter', 'بصل|Onions', 'زيت|Oil']),
  Dish('asida_taqalia', '🥘', 'عصيدة بملاح التقلية', 'عصيدة بملاح التقلية', 'Asida with taqalia stew', 'l', ['دقيق ذرة|Sorghum flour', 'شرموط (لحمة ناشفة)|Dried meat', 'ويكة|Dried okra (weika)', 'بصل|Onions', 'صلصة|Tomato paste', 'زيت|Oil']),
  Dish('kisra', '🫓', 'كسرة بملاح', 'كسرة مع الملاح', 'Kisra with stew', 'ld', ['دقيق ذرة|Sorghum flour', 'لحمة|Meat', 'بصل|Onions', 'صلصة|Tomato paste', 'زيت|Oil']),
  Dish('gurasa', '🥞', 'قراصة بالدمعة', 'قراصة', 'Gurasa (flatbread)', 'bl', ['دقيق قمح|Wheat flour', 'ملح|Salt', 'لحمة|Meat', 'بصل|Onions', 'صلصة|Tomato paste']),
  Dish('bamia', '🌿', 'ملاح بامية', 'بامية باللحم', 'Okra stew (bamia)', 'l', ['بامية|Okra', 'لحمة|Meat', 'بصل|Onions', 'صلصة|Tomato paste', 'توم|Garlic', 'زيت|Oil']),
  Dish('rijla', '🥬', 'ملاح رجلة', 'رجلة باللحم', 'Purslane stew (rijla)', 'l', ['رجلة|Purslane', 'لحمة|Meat', 'بصل|Onions', 'توم|Garlic', 'زيت|Oil']),
  Dish('molokhia', '🍲', 'ملوخية', 'ملوخية', 'Molokhia', 'l', ['ملوخية|Molokhia', 'فراخ|Chicken', 'توم|Garlic', 'كزبرة ناشفة|Dried coriander', 'زيت|Oil', 'رز|Rice']),
  Dish('salata_aswad', '🍆', 'سلطة أسود', 'سلطة الباذنجان بالدكوة', 'Eggplant & peanut salad', 'ld', ['بادنجان|Eggplant', 'دكوة|Peanut butter', 'توم|Garlic', 'ليمون|Lemon', 'شطة|Chili']),
  Dish('shiya', '🍖', 'شية', 'لحم مشوي', 'Grilled meat (shiya)', 'ld', ['لحمة ضان|Lamb', 'بصل|Onions', 'شطة|Chili', 'ليمون|Lemon', 'فحم|Charcoal']),
  Dish('weika', '🥘', 'ملاح ويكة', 'ملاح الويكة', 'Weika stew', 'l', ['ويكة|Dried okra (weika)', 'شرموط (لحمة ناشفة)|Dried meat', 'بصل|Onions', 'زيت|Oil', 'توم|Garlic']),
  Dish('fateer', '🥐', 'فطير', 'فطير', 'Fateer pastry', 'bd', ['دقيق قمح|Wheat flour', 'سمن|Ghee', 'لبن|Milk', 'سكر|Sugar', 'عسل|Honey']),
  Dish('adas', '🥣', 'عدس', 'شوربة عدس', 'Lentils', 'bd', ['عدس|Lentils', 'بصل|Onions', 'توم|Garlic', 'كمون|Cumin', 'زيت|Oil', 'رغيف|Bread']),
  Dish('balila', '🍵', 'بليلة', 'بليلة', 'Balila (boiled beans)', 'bd', ['كبكبي|Chickpeas', 'لوبيا|Cowpeas', 'ملح|Salt']),
  Dish('eggs', '🍳', 'بيض بالطماطم', 'بيض بالطماطم', 'Eggs with tomato', 'bd', ['بيض|Eggs', 'طماطم|Tomatoes', 'بصل|Onions', 'زيت|Oil', 'رغيف|Bread']),
  Dish('rice_chicken', '🍗', 'رز بالفراخ', 'أرز بالدجاج', 'Rice & chicken', 'l', ['رز|Rice', 'فراخ|Chicken', 'بصل|Onions', 'بهارات|Spices', 'زيت|Oil']),
  Dish('macarona', '🍝', 'مكرونة بالصلصة', 'معكرونة بالصلصة', 'Pasta in tomato sauce', 'ld', ['مكرونة|Pasta', 'صلصة|Tomato paste', 'لحمة مفرومة|Minced meat', 'بصل|Onions', 'زيت|Oil']),
  Dish('zalabia', '🍩', 'زلابية (لقيمات)', 'لقيمات', 'Zalabia (dough balls)', 'b', ['دقيق قمح|Wheat flour', 'خميرة|Yeast', 'سكر|Sugar', 'زيت قلي|Frying oil']),
  Dish('salad', '🥗', 'سلطة خضراء', 'سلطة خضراء', 'Green salad', 'ld', ['طماطم|Tomatoes', 'خيار|Cucumber', 'جرجير|Rocket', 'بصل|Onions', 'ليمون|Lemon']),
];

const _mealKeys = ['b', 'l', 'd'];
String _mealName(String k) => switch (k) {
      'b' => t('فطور', 'فطور', 'Breakfast'),
      'l' => t('غدا', 'غداء', 'Lunch'),
      _ => t('عشا', 'عشاء', 'Dinner'),
    };

/// بداية الأسبوع (السبت)
DateTime weekStart(DateTime d) {
  final back = (d.weekday - DateTime.saturday) % 7;
  return DateTime(d.year, d.month, d.day - back);
}

class MealPlanTool extends StatefulWidget {
  const MealPlanTool({super.key});
  @override
  State<MealPlanTool> createState() => _MealPlanToolState();
}

class _MealPlanToolState extends State<MealPlanTool> {
  late DateTime _week = weekStart(todayPlace());
  final _rnd = math.Random();

  Map<String, dynamic> _weeks(AppState s) => Map<String, dynamic>.from(s.getData<Map>('meal_plan_weeks') ?? const {});
  Map<String, dynamic> _plan(AppState s, DateTime w) => Map<String, dynamic>.from((_weeks(s)[dk(w)] as Map?) ?? const {});
  void _savePlan(AppState s, DateTime w, Map<String, dynamic> p) {
    final all = _weeks(s);
    all[dk(w)] = p;
    // احتفظ بآخر 20 أسبوعًا فقط
    final keys = all.keys.toList()..sort();
    while (keys.length > 20) {
      all.remove(keys.removeAt(0));
    }
    s.setData('meal_plan_weeks', all);
  }

  List<Map<String, dynamic>> _custom(AppState s) => mapList(s.getData<List>('meal_plan_custom'));
  Map<String, dynamic> _cfg(AppState s) => Map<String, dynamic>.from(s.getData<Map>('meal_plan_cfg') ?? const {});
  String _cur(AppState s) => (_cfg(s)['cur'] as String?) ?? tr('ج.س', 'SDG');

  /// اسم + إيموجي + مكوّنات أي طبق (جاهز أو خاص)
  (String, String, List<String>)? _dish(AppState s, String? id) {
    if (id == null) return null;
    for (final d in builtinDishes) {
      if (d.id == id) return (d.emoji, d.name, [for (final i in d.ings) ingName(i)]);
    }
    for (final c in _custom(s)) {
      if (c['id'] == id) return ('🍽️', '${c['name']}', List<String>.from((c['ings'] as List?)?.map((e) => '$e') ?? const <String>[]));
    }
    return null;
  }

  double _cost(AppState s, String id) {
    for (final c in _custom(s)) {
      if (c['id'] == id) return numOf(c['cost']);
    }
    return numOf((Map<String, dynamic>.from(_cfg(s)['costs'] as Map? ?? const {}))[id]);
  }

  List<(String, String)> _allDishes(AppState s, [String? meal]) => [
        for (final d in builtinDishes)
          if (meal == null || d.meals.contains(meal)) (d.id, '${d.emoji} ${d.name}'),
        for (final c in _custom(s)) ('${c['id']}', '🍽️ ${c['name']}'),
      ];

  Future<void> _pickSlot(int day, String meal) async {
    final s = context.read<AppState>();
    final key = 'd${day}_$meal';
    final p = _plan(s, _week);
    var showAll = false;
    final r = await lifeSheet<String>(
      context,
      '${weekdaysAr[_week.add(Duration(days: day)).weekday - 1]} · ${_mealName(meal)}',
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final d in _allDishes(s, showAll ? null : meal)) PickChip(d.$2, p[key] == d.$1, () => Navigator.pop(ctx, d.$1), color: SD.orange),
        ]),
        const SizedBox(height: 8),
        if (!showAll)
          TextButton.icon(onPressed: () => set(() => showAll = true), icon: const Icon(Icons.expand_more_rounded), label: Text(t('كل الأطباق', 'كل الأطباق', 'All dishes'))),
        const SizedBox(height: 8),
        ActionRow([
          MiniAction(Icons.casino_rounded, t('اختار لي', 'اقتراح عشوائي', 'Surprise me'), () {
            final l = _allDishes(s, meal);
            Navigator.pop(ctx, l[_rnd.nextInt(l.length)].$1);
          }, color: SD.purple),
          MiniAction(Icons.clear_rounded, t('فاضي', 'إفراغ', 'Clear'), () => Navigator.pop(ctx, ''), color: SD.red),
        ]),
      ]),
    );
    if (r == null || !mounted) return;
    if (r.isEmpty) {
      p.remove(key);
    } else {
      p[key] = r;
      s.awardDaily('meal_plan', 3, tr('تخطيط الوجبات', 'Meal planning'));
    }
    _savePlan(s, _week, p);
    setState(() {});
  }

  void _fillRandom(AppState s) {
    final p = _plan(s, _week);
    for (var d = 0; d < 7; d++) {
      for (final m in _mealKeys) {
        final k = 'd${d}_$m';
        if (p[k] != null) continue;
        final l = _allDishes(s, m);
        // تجنّب تكرار نفس الطبق في اليوم السابق لنفس الوجبة
        String id;
        var tries = 0;
        do {
          id = l[_rnd.nextInt(l.length)].$1;
        } while (d > 0 && p['d${d - 1}_$m'] == id && tries++ < 5);
        p[k] = id;
      }
    }
    _savePlan(s, _week, p);
    s.awardDaily('meal_plan', 3, tr('تخطيط الوجبات', 'Meal planning'));
    setState(() {});
  }

  Future<void> _copyLast(AppState s) async {
    final last = _plan(s, _week.subtract(const Duration(days: 7)));
    if (last.isEmpty) return toast(t('الأسبوع الفات فاضي', 'الأسبوع السابق فارغ', 'Last week is empty'));
    if (_plan(s, _week).isNotEmpty &&
        !await confirmAsk(context, t('تنسخ الأسبوع الفات؟', 'نسخ الأسبوع السابق؟', 'Copy last week?'), t('الجدول الحالي بيتبدّل', 'سيُستبدل الجدول الحالي', 'The current plan will be replaced'))) {
      return;
    }
    _savePlan(s, _week, last);
    setState(() {});
  }

  Future<void> _editCustom([Map<String, dynamic>? c]) async {
    final s = context.read<AppState>();
    final nC = TextEditingController(text: c?['name'] ?? '');
    final iC = TextEditingController(text: ((c?['ings'] as List?) ?? const []).join('\n'));
    final costC = TextEditingController(text: c == null ? '' : rawNum(numOf(c['cost'])));
    final ok = await lifeSheet<bool>(
      context,
      c == null ? t('طبق جديد', 'طبق جديد', 'New dish') : t('عدّل الطبق', 'تعديل الطبق', 'Edit dish'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: nC, decoration: InputDecoration(labelText: t('اسم الطبق', 'اسم الطبق', 'Dish name'))),
        const SizedBox(height: 10),
        TextField(
          controller: iC,
          minLines: 3,
          maxLines: 8,
          decoration: InputDecoration(labelText: t('المكوّنات (كل واحد في سطر)', 'المكوّنات (كل مكوّن في سطر)', 'Ingredients (one per line)')),
        ),
        const SizedBox(height: 10),
        NumField(t('التكلفة التقريبية للطبق (اختياري)', 'التكلفة التقريبية (اختياري)', 'Approx. cost (optional)'), costC, suffix: _cur(s)),
        const SizedBox(height: 8),
        sheetButtons(ctx, onSave: () {
          if (nC.text.trim().isEmpty) return toast(t('أكتب اسم الطبق', 'اكتب اسم الطبق', 'Enter the dish name'));
          Navigator.pop(ctx, true);
        }, onDelete: c == null ? null : () => Navigator.pop(ctx, false)),
      ]),
    );
    final name = nC.text.trim(), ings = iC.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(), cost = parseNum(costC.text);
    nC.dispose();
    iC.dispose();
    costC.dispose();
    if (!mounted || ok == null) return;
    final l = _custom(s);
    if (ok == false && c != null) {
      l.removeWhere((x) => x['id'] == c['id']);
    } else if (c == null) {
      l.add({'id': 'c_${newId()}', 'name': name, 'ings': ings, 'cost': cost});
    } else {
      final i = l.indexWhere((x) => x['id'] == c['id']);
      if (i >= 0) l[i] = {...l[i], 'name': name, 'ings': ings, 'cost': cost};
    }
    s.setData('meal_plan_custom', l);
    setState(() {});
  }

  Future<void> _costs() async {
    final s = context.read<AppState>();
    final cfg = _cfg(s);
    final costs = Map<String, dynamic>.from(cfg['costs'] as Map? ?? const {});
    final budgetC = TextEditingController(text: rawNum(numOf(cfg['budget'])));
    final curC = TextEditingController(text: _cur(s));
    final cs = {for (final d in builtinDishes) d.id: TextEditingController(text: rawNum(numOf(costs[d.id])))};
    final ok = await lifeSheet<bool>(
      context,
      t('الميزانية والتكاليف', 'الميزانية والتكاليف', 'Budget & costs'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        NumField(t('ميزانية الأكل في الأسبوع (اختياري)', 'ميزانية الطعام الأسبوعية (اختياري)', 'Weekly food budget (optional)'), budgetC),
        TextField(controller: curC, decoration: InputDecoration(labelText: t('العملة', 'العملة', 'Currency label'))),
        const SizedBox(height: 12),
        Text(t('تكلفة كل طبق للأسرة (تقريبًا)', 'التكلفة التقريبية لكل طبق للأسرة', 'Approx. cost of each dish for the family'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final d in builtinDishes) NumField('${d.emoji} ${d.name}', cs[d.id]!),
        sheetButtons(ctx, onSave: () => Navigator.pop(ctx, true)),
      ]),
    );
    final budget = parseNum(budgetC.text), cur = curC.text.trim();
    final nc = {for (final e in cs.entries) if (parseNum(e.value.text) > 0) e.key: parseNum(e.value.text)};
    budgetC.dispose();
    curC.dispose();
    for (final c in cs.values) {
      c.dispose();
    }
    if (ok != true || !mounted) return;
    s.setData('meal_plan_cfg', {...cfg, 'budget': budget, 'cur': cur, 'costs': nc});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final plan = _plan(s, _week);
    final today = todayPlace();
    final cur = _cur(s);
    final budget = numOf(_cfg(s)['budget']);
    // تجميع المكوّنات
    final ings = <String, int>{};
    var est = 0.0;
    var unknownCost = 0;
    for (final id in plan.values) {
      final d = _dish(s, '$id');
      if (d == null) continue;
      for (final i in d.$3) {
        ings[i] = (ings[i] ?? 0) + 1;
      }
      final c = _cost(s, '$id');
      if (c > 0) {
        est += c;
      } else {
        unknownCost++;
      }
    }
    final ingList = ings.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final weekEnd = _week.add(const Duration(days: 6));
    final weekLabel = '${fmtShort(_week)} – ${fmtShort(weekEnd)}';

    String planText() {
      final b = StringBuffer('🍽️ ${t('وجبات الأسبوع', 'وجبات الأسبوع', 'Weekly meals')} ($weekLabel)\n');
      for (var d = 0; d < 7; d++) {
        final day = _week.add(Duration(days: d));
        final parts = [
          for (final m in _mealKeys)
            if (_dish(s, plan['d${d}_$m'] as String?) != null) '${_mealName(m)}: ${_dish(s, plan['d${d}_$m'] as String?)!.$2}'
        ];
        if (parts.isNotEmpty) b.writeln('• ${weekdaysAr[day.weekday - 1]}: ${parts.join(' | ')}');
      }
      return b.toString().trim();
    }

    String shopText() {
      final b = StringBuffer('🛒 ${t('مشتريات الأسبوع', 'مشتريات الأسبوع', 'Shopping for the week')} ($weekLabel)\n');
      for (final e in ingList) {
        b.writeln('☐ ${e.key}${e.value > 1 ? ' (×${e.value} ${t('أطباق', 'أطباق', 'dishes')})' : ''}');
      }
      return b.toString().trim();
    }

    return ToolList(children: [
      PeriodNav(weekLabel,
          onPrev: () => setState(() => _week = _week.subtract(const Duration(days: 7))),
          onNext: () => setState(() => _week = _week.add(const Duration(days: 7))),
          onReset: () => setState(() => _week = weekStart(today))),
      ActionRow([
        MiniAction(Icons.casino_rounded, t('عبّي عشوائي', 'تعبئة عشوائية', 'Auto-fill'), () => _fillRandom(s), color: SD.purple),
        MiniAction(Icons.copy_all_rounded, t('انسخ الفات', 'نسخ السابق', 'Copy last'), () => _copyLast(s), color: SD.nile),
        MiniAction(Icons.delete_sweep_rounded, t('فضّي', 'إفراغ', 'Clear'), () async {
          if (plan.isEmpty) return;
          if (!await confirmAsk(context, t('تفضّي الأسبوع؟', 'إفراغ الأسبوع؟', 'Clear this week?'), weekLabel)) return;
          _savePlan(s, _week, {});
          setState(() {});
        }, color: SD.red),
      ]),
      for (var d = 0; d < 7; d++) _dayCard(s, d, plan, today),
      SCard(
        title: t('قائمة مشتريات الأسبوع', 'قائمة مشتريات الأسبوع', 'Weekly shopping list'),
        icon: Icons.shopping_cart_rounded,
        color: SD.green,
        child: ingList.isEmpty
            ? Text(t('اختار الوجبات فوق والقائمة بتتعمل براها.', 'اختر الوجبات أعلاه وستُنشأ القائمة تلقائيًا.', 'Pick meals above and the list builds itself.'))
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final e in ingList) Tag('${e.key}${e.value > 1 ? ' ×${e.value}' : ''}', color: SD.green),
                ]),
                const SizedBox(height: 6),
                Text(t('الرقم = في كم طبق داخل — قدّر الكمية حسب أسرتك.', 'الرقم = عدد الأطباق التي يدخل فيها؛ قدّر الكمية حسب أسرتك.', 'The number = how many dishes use it; size quantities for your family.'),
                    style: const TextStyle(fontSize: 11.5)),
                const SizedBox(height: 10),
                ShareBar(shopText),
              ]),
      ),
      SCard(
        title: t('الميزانية', 'الميزانية', 'Budget'),
        icon: Icons.account_balance_wallet_rounded,
        color: SD.gold,
        trailing: TextButton(onPressed: _costs, child: Text(t('ضبط', 'ضبط', 'Set'))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InfoRow(t('التكلفة المتوقعة للأسبوع', 'التكلفة المتوقعة للأسبوع', 'Estimated weekly cost'), est > 0 ? money(est, cur) : '—', icon: Icons.calculate_rounded,
              hint: unknownCost > 0 ? '$unknownCost ${t('وجبة بلا تكلفة', 'وجبة بلا تكلفة', 'meals without a cost')}' : null),
          if (budget > 0) ...[
            PercentBar('${money(est, cur)} / ${money(budget, cur)}', est / budget, '${fmt(est / budget * 100, 0)}%', color: est > budget ? SD.red : SD.green),
            if (est > budget)
              NoteBox(t('الخطة دي أغلى من الميزانية بـ ${money(est - budget, cur)}', 'الخطة تتجاوز الميزانية بمقدار ${money(est - budget, cur)}', 'This plan is over budget by ${money(est - budget, cur)}'), kind: NoteKind.warn),
          ] else
            Text(t('حدّد ميزانية وتكلفة الأطباق من «ضبط» عشان نحسب ليك.', 'حدّد الميزانية وتكلفة الأطباق من «ضبط».', 'Set a budget and dish costs via «Set».'), style: const TextStyle(fontSize: 12.5)),
        ]),
      ),
      SCard(
        title: t('أطباقي', 'أطباقي الخاصة', 'My dishes'),
        icon: Icons.restaurant_menu_rounded,
        color: SD.orange,
        trailing: IconButton(onPressed: () => _editCustom(), icon: const Icon(Icons.add_rounded), tooltip: t('طبق جديد', 'طبق جديد', 'New dish')),
        child: _custom(s).isEmpty
            ? Text(t('أضف أطباق بيتكم بمكوّناتها (مثلًا: مديدة، كمونية، سخينة…)', 'أضف أطباقك الخاصة بمكوّناتها.', 'Add your own dishes with their ingredients.'))
            : Column(children: [
                for (final c in _custom(s))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _editCustom(c),
                    leading: const Text('🍽️', style: TextStyle(fontSize: 22)),
                    title: Text('${c['name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(((c['ings'] as List?) ?? const []).join('، '), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    trailing: numOf(c['cost']) > 0 ? trailAmount(context, money(numOf(c['cost']), cur), maxWidth: 100) : null,
                  ),
              ]),
      ),
      if (plan.isNotEmpty) ShareBar(planText),
      const SizedBox(height: 8),
      NoteBox(
          t('نوّع بين البقوليات والخضار واللحوم، وخلي الأكل البايت يدخل في وجبة اليوم الجاي عشان ما يضيع.', 'نوّع بين البقوليات والخضار واللحوم، واستفد من بقايا الطعام في وجبة اليوم التالي.',
              'Mix legumes, vegetables and meat, and reuse leftovers the next day.'),
          kind: NoteKind.tip),
    ]);
  }

  Widget _dayCard(AppState s, int d, Map<String, dynamic> plan, DateTime today) {
    final day = _week.add(Duration(days: d));
    final isToday = day == today;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isToday ? SD.gold : SD.gold.withValues(alpha: .3), width: isToday ? 2 : 1)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text('${weekdaysAr[day.weekday - 1]} · ${fmtShort(day)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
            if (isToday) Tag(t('الليلة', 'اليوم', 'Today'), color: SD.gold),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            for (final m in _mealKeys) ...[
              if (m != 'b') const SizedBox(width: 6),
              Expanded(child: _slot(s, d, m, plan['d${d}_$m'] as String?)),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _slot(AppState s, int d, String m, String? id) {
    final dish = _dish(s, id);
    final c = switch (m) { 'b' => SD.orange, 'l' => SD.green, _ => SD.indigo };
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pickSlot(d, m),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: c.withValues(alpha: dish == null ? .05 : .15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withValues(alpha: .4)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(_mealName(m), maxLines: 1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: readable(context, c)))),
          Text(dish?.$1 ?? '＋', style: const TextStyle(fontSize: 18)),
          Text(dish?.$2 ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, height: 1.15)),
        ]),
      ),
    );
  }
}
