import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'money_common.dart';

class _Item {
  String name;
  double watts, qty, hours;
  _Item(this.name, this.watts, this.qty, this.hours);
  double get wh => watts * qty * hours;
  double get load => watts * qty;
  Map<String, dynamic> toJson() => {'n': name, 'w': watts, 'q': qty, 'h': hours};
  static _Item fromJson(Map m) =>
      _Item('${m['n']}', (m['w'] as num).toDouble(), (m['q'] as num).toDouble(), (m['h'] as num).toDouble());
}

List<_Item> _defaults() => [
      _Item('مكيف صحراوي', 200, 1, 12),
      _Item('ثلاجة', 150, 1, 10),
      _Item('مروحة سقف', 75, 2, 10),
      _Item('لمبات LED', 10, 6, 6),
      _Item('تلفزيون', 100, 1, 5),
      _Item('شاحن موبايل', 10, 3, 3),
      _Item('طلمبة موية', 750, 1, 1),
      _Item('راوتر واي فاي', 10, 1, 24),
    ];

const _icons = <String, IconData>{
  'مكيف': Icons.ac_unit_rounded,
  'ثلاجة': Icons.kitchen_rounded,
  'مروحة': Icons.wind_power_rounded,
  'لمب': Icons.lightbulb_rounded,
  'تلفزيون': Icons.tv_rounded,
  'شاحن': Icons.battery_charging_full_rounded,
  'طلمبة': Icons.water_rounded,
  'راوتر': Icons.router_rounded,
  'مكواة': Icons.iron_rounded,
  'غسالة': Icons.local_laundry_service_rounded,
};

IconData _iconFor(String n) {
  for (final e in _icons.entries) {
    if (n.contains(e.key)) return e.value;
  }
  return Icons.electrical_services_rounded;
}

class PowerTool extends StatefulWidget {
  const PowerTool({super.key});
  @override
  State<PowerTool> createState() => _PowerToolState();
}

class _PowerToolState extends State<PowerTool> {
  late List<_Item> _items;
  late final TextEditingController _price, _sun, _panel, _backup, _fuel;
  int _battV = 24;
  bool _lithium = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final saved = s.getData<List>('power_items');
    _items = saved == null ? _defaults() : saved.whereType<Map>().map(_Item.fromJson).toList();
    final d = Map<String, dynamic>.from(s.getData<Map>('power_solar') ?? {});
    _price = TextEditingController(text: s.getData<String>('power_price') ?? '');
    _sun = TextEditingController(text: d['sun'] ?? '6');
    _panel = TextEditingController(text: d['panel'] ?? '550');
    _backup = TextEditingController(text: d['backup'] ?? '8');
    _fuel = TextEditingController(text: d['fuel'] ?? '');
    _battV = d['battV'] ?? 24;
    _lithium = d['lithium'] ?? false;
  }

  @override
  void dispose() {
    for (final c in [_price, _sun, _panel, _backup, _fuel]) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveItems() {
    context.read<AppState>().setData('power_items', _items.map((e) => e.toJson()).toList());
    setState(() {});
  }

  void _saveSolar() {
    final s = context.read<AppState>();
    s.setData('power_solar', {'sun': _sun.text, 'panel': _panel.text, 'backup': _backup.text, 'fuel': _fuel.text, 'battV': _battV, 'lithium': _lithium});
    s.setData('power_price', _price.text);
    setState(() {});
  }

  Future<void> _edit([int? i]) async {
    final it = i == null ? null : _items[i];
    final n = TextEditingController(text: it?.name ?? '');
    final w = TextEditingController(text: it == null ? '' : fmt(it.watts).replaceAll(',', ''));
    final q = TextEditingController(text: it == null ? '1' : fmt(it.qty).replaceAll(',', ''));
    final h = TextEditingController(text: it == null ? '' : fmt(it.hours).replaceAll(',', ''));
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(i == null ? 'جهاز جديد' : 'عدّل الجهاز'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: n, decoration: const InputDecoration(labelText: 'اسم الجهاز', hintText: 'مثلًا مكواة')),
            const SizedBox(height: 10),
            NumField('القدرة', w, suffix: 'واط', hint: 'مكتوبة في ديباجة الجهاز'),
            NumField('العدد', q),
            NumField('ساعات التشغيل في اليوم', h, suffix: 'ساعة'),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('تمام')),
        ],
      ),
    );
    if (ok == true && mounted) {
      final item = _Item(n.text.trim().isEmpty ? 'جهاز' : n.text.trim(), parseNum(w.text), math.max(0, parseNum(q.text, 1)), parseNum(h.text).clamp(0, 24).toDouble());
      if (i == null) {
        _items.add(item);
      } else {
        _items[i] = item;
      }
      _saveItems();
    }
    n.dispose();
    w.dispose();
    q.dispose();
    h.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dailyWh = _items.fold<double>(0, (a, e) => a + e.wh);
    final peak = _items.fold<double>(0, (a, e) => a + e.load);
    final dailyKwh = dailyWh / 1000, monthKwh = dailyKwh * 30;
    final price = parseNum(_price.text);
    final sorted = [..._items]..sort((a, b) => b.wh.compareTo(a.wh));

    // ── تصميم الطاقة الشمسية ──
    final sun = parseNum(_sun.text, 6).clamp(1, 12).toDouble();
    final panelW = math.max(50.0, parseNum(_panel.text, 550));
    final backupH = parseNum(_backup.text, 8).clamp(0, 48).toDouble();
    final dod = _lithium ? .8 : .5;
    const sysEff = .75; // فاقد الحرارة والغبار والأسلاك
    final pvW = dailyWh / (sun * sysEff);
    final panels = dailyWh == 0 ? 0 : (pvW / panelW).ceil();
    final pvActual = panels * panelW;
    final inverterW = peak * 1.25;
    final inverterKw = _roundInverter(inverterW / 1000);
    final backupWh = dailyWh / 24 * backupH;
    final battWh = backupWh / dod / .9;
    final battAh = battWh / _battV;
    final series = _battV ~/ 12;
    final strings = battAh == 0 ? 0 : (battAh / 200).ceil();
    final battCount = strings * series;
    final ccA = pvActual / _battV * 1.25;
    final fuelL = dailyKwh * .3;
    final fuelPrice = parseNum(_fuel.text);
    final hasPump = _items.any((e) => e.name.contains('طلمبة') || e.name.contains('ثلاجة') || e.name.contains('مكيف'));

    String summary() => [
          '⚡ حساب الكهرباء',
          'الاستهلاك اليومي: ${fmt(dailyKwh, 2)} ك.و.س • الشهري: ${fmt(monthKwh, 1)} ك.و.س',
          if (price > 0) 'الفاتورة الشهرية ≈ ${fmt(monthKwh * price, 0)} ج.س',
          'أعلى حمل لحظي: ${fmt(peak, 0)} واط',
          '☀️ نظام شمسي مقترح: انفرتر ${fmt(inverterKw, 1)} ك.و • $panels لوح × ${fmt(panelW, 0)} واط (${fmt(pvActual / 1000, 2)} ك.و)',
          '🔋 بطاريات ${_lithium ? 'ليثيوم' : 'رصاص'} ${_battV}V: ${fmt(battAh, 0)} أمبير ساعة ≈ $battCount بطارية 200Ah/12V',
          '🎛️ منظم شحن ≈ ${fmt(ccA, 0)} أمبير',
          '⛽ بالمولد: ≈ ${fmt(fuelL, 1)} لتر جاز في اليوم',
        ].join('\n');

    return ToolList(children: [
      SCard(
        title: 'أجهزة البيت',
        icon: Icons.electrical_services_rounded,
        color: SD.orange,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            tooltip: 'رجّع الافتراضي',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () {
              _items = _defaults();
              _saveItems();
            },
          ),
          IconButton.filledTonal(tooltip: 'أضف جهاز', icon: const Icon(Icons.add_rounded), onPressed: () => _edit()),
        ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_items.isEmpty) const Text('القائمة فاضية — أضف جهاز بالزر فوق.'),
          for (var i = 0; i < _items.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: SD.orange.withValues(alpha: .15), child: Icon(_iconFor(_items[i].name), color: SD.orange)),
              title: Text(_items[i].name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${fmt(_items[i].watts)} واط × ${fmt(_items[i].qty)} × ${fmt(_items[i].hours)} ساعة = ${fmt(_items[i].wh / 1000, 2)} ك.و.س/يوم'),
              onTap: () => _edit(i),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () {
                  _items.removeAt(i);
                  _saveItems();
                },
              ),
            ),
          const Text('دوس على أي جهاز عشان تعدّلو', style: TextStyle(fontSize: 12)),
        ]),
      ),
      SCard(
        title: 'سعر الكهرباء',
        icon: Icons.receipt_rounded,
        color: SD.nile,
        child: NumField('سعر الكيلوواط ساعة', _price, suffix: 'ج.س', hint: 'من فاتورة الكهرباء / الجمرة', onChanged: (_) => _saveSolar()),
      ),
      ResultHero(
        label: 'استهلاكك في الشهر',
        value: '${fmt(monthKwh, 1)} ك.و.س',
        sub: price > 0 ? 'الفاتورة ≈ ${fmt(monthKwh * price, 0)} ج.س في الشهر' : 'أكتب سعر الكيلوواط عشان نحسب ليك القروش',
        colors: SD.sunset,
      ),
      StatGrid([
        StatChip(fmt(dailyKwh, 2), 'ك.و.س في اليوم', color: SD.orange, icon: Icons.today_rounded),
        StatChip(fmt(peak, 0), 'واط حمل كامل', color: SD.red, icon: Icons.bolt_rounded),
        StatChip(price > 0 ? fmt(dailyKwh * price, 0) : '—', 'ج.س في اليوم', color: SD.green, icon: Icons.payments_rounded),
        StatChip(fmt(monthKwh * 12, 0), 'ك.و.س في السنة', color: SD.nile, icon: Icons.calendar_month_rounded),
        StatChip(price > 0 ? fmt(monthKwh * 12 * price, 0) : '—', 'ج.س في السنة', color: SD.henna, icon: Icons.account_balance_wallet_rounded),
        StatChip(fmt(dailyWh / 24, 0), 'واط متوسط', color: SD.teal, icon: Icons.av_timer_rounded),
      ]),
      const SizedBox(height: 14),
      SCard(
        title: 'منو الأكل الكهرباء؟',
        icon: Icons.pie_chart_rounded,
        color: SD.red,
        child: Column(children: [
          for (final e in sorted.take(6))
            PercentBar(
              e.name,
              dailyWh == 0 ? 0 : e.wh / dailyWh,
              '${fmt(dailyWh == 0 ? 0 : e.wh / dailyWh * 100, 1)}%${price > 0 ? ' • ${fmt(e.wh / 1000 * 30 * price, 0)} ج.س/شهر' : ''}',
              color: e == sorted.first ? SD.red : SD.orange,
            ),
        ]),
      ),

      // ── الطاقة الشمسية ──
      SCard(
        title: 'صمّم نظام طاقة شمسية',
        icon: Icons.solar_power_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: NumField('ساعات الشمس', _sun, suffix: 'ساعة', onChanged: (_) => _saveSolar())),
            const SizedBox(width: 10),
            Expanded(child: NumField('قدرة اللوح', _panel, suffix: 'واط', onChanged: (_) => _saveSolar())),
          ]),
          NumField('ساعات تشغيل من البطارية (ليل/قطوعات)', _backup, suffix: 'ساعة', onChanged: (_) => _saveSolar()),
          const Text('جهد البطاريات:', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ChoiceRow<int>(const [(12, '12 فولت'), (24, '24 فولت'), (48, '48 فولت')], _battV, (x) {
            _battV = x;
            _saveSolar();
          }, color: SD.gold),
          ChoiceRow<bool>(const [(false, 'رصاص (تفريغ 50%)'), (true, 'ليثيوم (تفريغ 80%)')], _lithium, (x) {
            _lithium = x;
            _saveSolar();
          }, color: SD.gold),
        ]),
      ),
      SCard(
        title: 'النظام المقترح',
        icon: Icons.settings_input_component_rounded,
        color: SD.green,
        child: Column(children: [
          StatGrid([
            StatChip(fmt(inverterKw, 1), 'ك.و انفرتر', color: SD.indigo, icon: Icons.electrical_services_rounded),
            StatChip('$panels', 'لوح ${fmt(panelW, 0)}W', color: SD.gold, icon: Icons.solar_power_rounded),
            StatChip('$battCount', 'بطارية 200Ah', color: SD.green, icon: Icons.battery_full_rounded),
          ]),
          const SizedBox(height: 8),
          InfoRow('الانفرتر', '${fmt(inverterKw, 1)} ك.و', icon: Icons.electrical_services_rounded, hint: 'أعلى حمل ${fmt(peak, 0)} واط + 25% احتياط'),
          InfoRow('الألواح', '$panels × ${fmt(panelW, 0)} واط = ${fmt(pvActual / 1000, 2)} ك.و', icon: Icons.solar_power_rounded,
              hint: 'المطلوب ${fmt(pvW, 0)} واط (مع فاقد 25% للحرارة والغبار)'),
          InfoRow('طاقة الألواح المتوقعة', '${fmt(pvActual * sun * sysEff / 1000, 2)} ك.و.س/يوم', icon: Icons.wb_sunny_rounded),
          InfoRow('طاقة البطارية المطلوبة', '${fmt(battWh / 1000, 2)} ك.و.س', icon: Icons.battery_charging_full_rounded,
              hint: '${fmt(backupWh / 1000, 2)} ك.و.س لـ ${fmt(backupH)} ساعة ÷ تفريغ ${fmt(dod * 100, 0)}%'),
          InfoRow('سعة البطاريات على ${_battV}V', '${fmt(battAh, 0)} أمبير ساعة', icon: Icons.battery_std_rounded),
          InfoRow('بطاريات 200Ah/12V', '$battCount بطارية', icon: Icons.grid_view_rounded,
              hint: '$strings خط متوازي × $series على التوالي'),
          InfoRow('منظم الشحن (MPPT)', '≈ ${fmt(ccA, 0)} أمبير', icon: Icons.tune_rounded, hint: 'قدرة الألواح ÷ ${_battV}V × 1.25'),
        ]),
      ),
      if (hasPump)
        const NoteBox('الطلمبة والثلاجة والمكيف بتسحب تيار بداية أكبر (2–3 أضعاف). لو بتشغّلهم مع بعض اختار انفرتر أكبر شوية.', kind: NoteKind.warn),
      SCard(
        title: 'لو بالمولد (الجنريتر)',
        icon: Icons.local_gas_station_rounded,
        color: SD.coffee,
        child: Column(children: [
          NumField('سعر لتر الجاز (اختياري)', _fuel, suffix: 'ج.س', onChanged: (_) => _saveSolar()),
          InfoRow('الجاز في اليوم', '≈ ${fmt(fuelL, 1)} لتر', icon: Icons.opacity_rounded, hint: 'على أساس 0.3 لتر لكل ك.و.س تقريبًا'),
          InfoRow('الجاز في الشهر', '≈ ${fmt(fuelL * 30, 0)} لتر', icon: Icons.calendar_month_rounded),
          if (fuelPrice > 0) ...[
            InfoRow('تكلفة الجاز في الشهر', '≈ ${fmt(fuelL * 30 * fuelPrice, 0)} ج.س', icon: Icons.payments_rounded, valueColor: SD.red),
            InfoRow('تكلفة الجاز في السنة', '≈ ${fmt(fuelL * 365 * fuelPrice, 0)} ج.س', icon: Icons.savings_rounded, valueColor: SD.red,
                hint: 'قارنها بسعر نظام الشمسي — غالبًا بيرجّع حقو في كم سنة'),
          ],
          InfoRow('مولد مناسب', '≈ ${fmt(math.max(1, peak * 1.5 / 1000), 1)} ك.ف.أ', icon: Icons.power_rounded, hint: 'أعلى حمل × 1.5'),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 14),
      SCard(
        title: 'نصايح عشان توفّر',
        icon: Icons.tips_and_updates_rounded,
        color: SD.teal,
        child: const Column(children: [
          NoteBox('غيّر اللمبات القديمة لـ LED — بتاكل أقل من ربع الكهرباء.', kind: NoteKind.tip),
          NoteBox('المكيف الصحراوي: نضّف القش وغيّرو كل موسم، وافتح شباك صغير عشان الهوا يتجدد.', kind: NoteKind.tip),
          NoteBox('الثلاجة: بعيد عن الشمس والحيطة، ما تفتحها كتير، وما تدخل فيها أكل سخن.', kind: NoteKind.tip),
          NoteBox('شغّل الطلمبة والمكواة والغسالة وقت الشمس لو عندك طاقة شمسية.', kind: NoteKind.tip),
          NoteBox('قفّل الشواحن والتلفزيون من الفيش بدل الـ standby.', kind: NoteKind.tip),
          NoteBox('نضّف الألواح الشمسية من الغبار كل كم يوم — الهبوب بيقلّل إنتاجها كتير.', kind: NoteKind.tip),
        ]),
      ),
      const NoteBox('الأرقام دي تقدير تقريبي للتخطيط بس. قبل ما تشتري، خلّي فنّي طاقة شمسية موثوق يراجع الأحمال والأسلاك والحماية.', kind: NoteKind.warn),
    ]);
  }

  /// تقريب لأقرب مقاس انفرتر شائع
  double _roundInverter(double kw) {
    const sizes = [0.5, 1, 1.5, 2, 3, 3.5, 5, 6, 8, 10, 12, 15, 20];
    for (final s in sizes) {
      if (kw <= s) return s.toDouble();
    }
    return (kw / 5).ceil() * 5.0;
  }
}
