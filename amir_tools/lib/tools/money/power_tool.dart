import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
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
      _Item(tr('مكيف صحراوي', 'Evaporative cooler'), 200, 1, 12),
      _Item(tr('ثلاجة', 'Fridge'), 150, 1, 10),
      _Item(tr('مروحة سقف', 'Ceiling fan'), 75, 2, 10),
      _Item(tr('لمبات LED', 'LED lights'), 10, 6, 6),
      _Item(tr('تلفزيون', 'TV'), 100, 1, 5),
      _Item(tr('شاحن موبايل', 'Phone charger'), 10, 3, 3),
      _Item(t('طلمبة موية', 'مضخة مياه', 'Water pump'), 750, 1, 1),
      _Item(tr('راوتر واي فاي', 'Wi-Fi router'), 10, 1, 24),
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
  'مضخة': Icons.water_rounded,
  'cooler': Icons.ac_unit_rounded,
  'air con': Icons.ac_unit_rounded,
  'fridge': Icons.kitchen_rounded,
  'fan': Icons.wind_power_rounded,
  'light': Icons.lightbulb_rounded,
  'lamp': Icons.lightbulb_rounded,
  'tv': Icons.tv_rounded,
  'charger': Icons.battery_charging_full_rounded,
  'pump': Icons.water_rounded,
  'router': Icons.router_rounded,
  'iron': Icons.iron_rounded,
  'wash': Icons.local_laundry_service_rounded,
};

/// أجهزة بتسحب تيار بداية عالي
bool _isSurge(String n) {
  final l = n.toLowerCase();
  return ['طلمبة', 'مضخة', 'ثلاجة', 'مكيف', 'pump', 'fridge', 'cooler', 'air con'].any(l.contains);
}

String get _kwh => tr('ك.و.س', 'kWh');
String get _kw => tr('ك.و', 'kW');
String get _wt => tr('واط', 'W');
String get _hr => tr('ساعة', 'h');

IconData _iconFor(String n) {
  final l = n.toLowerCase();
  for (final e in _icons.entries) {
    if (l.contains(e.key)) return e.value;
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
        title: Text(i == null ? tr('جهاز جديد', 'New appliance') : t('عدّل الجهاز', 'تعديل الجهاز', 'Edit appliance')),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: n, decoration: InputDecoration(labelText: tr('اسم الجهاز', 'Appliance name'), hintText: tr('مثلًا مكواة', 'e.g. Iron'))),
            const SizedBox(height: 10),
            NumField(tr('القدرة', 'Power'), w, suffix: _wt, hint: t('مكتوبة في ديباجة الجهاز', 'مدوّنة على لوحة بيانات الجهاز', 'Printed on the device label')),
            NumField(tr('العدد', 'Quantity'), q),
            NumField(tr('ساعات التشغيل في اليوم', 'Hours per day'), h, suffix: _hr),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(t('تمام', 'موافق', 'OK'))),
        ],
      ),
    );
    if (ok == true && mounted) {
      final item = _Item(n.text.trim().isEmpty ? tr('جهاز', 'Appliance') : n.text.trim(), parseNum(w.text), math.max(0, parseNum(q.text, 1)), parseNum(h.text).clamp(0, 24).toDouble());
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
    final hasPump = _items.any((e) => _isSurge(e.name));

    String summary() => [
          '⚡ ${t('حساب الكهربا', 'حساب الكهرباء', 'Power calculation')}',
          tr('الاستهلاك اليومي: ${fmt(dailyKwh, 2)} ك.و.س • الشهري: ${fmt(monthKwh, 1)} ك.و.س', 'Daily use: ${fmt(dailyKwh, 2)} kWh • monthly: ${fmt(monthKwh, 1)} kWh'),
          if (price > 0) '${tr('الفاتورة الشهرية', 'Monthly bill')} ≈ ${fmt(monthKwh * price, 0)}',
          tr('أعلى حمل لحظي: ${fmt(peak, 0)} واط', 'Peak load: ${fmt(peak, 0)} W'),
          tr('☀️ نظام شمسي مقترح: انفرتر ${fmt(inverterKw, 1)} ك.و • $panels لوح × ${fmt(panelW, 0)} واط (${fmt(pvActual / 1000, 2)} ك.و)', '☀️ Suggested solar: ${fmt(inverterKw, 1)} kW inverter • $panels panels × ${fmt(panelW, 0)} W (${fmt(pvActual / 1000, 2)} kW)'),
          tr('🔋 بطاريات ${_lithium ? 'ليثيوم' : 'رصاص'} ${_battV}V: ${fmt(battAh, 0)} أمبير ساعة ≈ $battCount بطارية 200Ah/12V', '🔋 ${_lithium ? 'Lithium' : 'Lead-acid'} batteries ${_battV}V: ${fmt(battAh, 0)} Ah ≈ $battCount × 200Ah/12V'),
          tr('🎛️ منظم شحن ≈ ${fmt(ccA, 0)} أمبير', '🎛️ Charge controller ≈ ${fmt(ccA, 0)} A'),
          t('⛽ بالمولد: ≈ ${fmt(fuelL, 1)} لتر جاز في اليوم', '⛽ بالمولّد: ≈ ${fmt(fuelL, 1)} لتر ديزل يوميًا', '⛽ By generator: ≈ ${fmt(fuelL, 1)} L diesel per day'),
        ].join('\n');

    return ToolList(children: [
      SCard(
        title: t('أجهزة البيت', 'أجهزة المنزل', 'Home appliances'),
        icon: Icons.electrical_services_rounded,
        color: SD.orange,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            tooltip: t('رجّع الافتراضي', 'استعادة الافتراضي', 'Reset to defaults'),
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () {
              _items = _defaults();
              _saveItems();
            },
          ),
          IconButton.filledTonal(tooltip: t('أضف جهاز', 'إضافة جهاز', 'Add appliance'), icon: const Icon(Icons.add_rounded), onPressed: () => _edit()),
        ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_items.isEmpty) Text(t('القائمة فاضية — أضف جهاز بالزر فوق.', 'القائمة فارغة — أضف جهازًا بالزر أعلاه.', 'The list is empty — add an appliance with the button above.')),
          for (var i = 0; i < _items.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: SD.orange.withValues(alpha: .15), child: Icon(_iconFor(_items[i].name), color: SD.orange)),
              title: Text(_items[i].name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${fmt(_items[i].watts)} $_wt × ${fmt(_items[i].qty)} × ${fmt(_items[i].hours)} $_hr = ${fmt(_items[i].wh / 1000, 2)} $_kwh/${tr('يوم', 'day')}'),
              onTap: () => _edit(i),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () {
                  _items.removeAt(i);
                  _saveItems();
                },
              ),
            ),
          Text(t('دوس على أي جهاز عشان تعدّلو', 'اضغط على أي جهاز لتعديله', 'Tap any appliance to edit it'), style: const TextStyle(fontSize: 12)),
        ]),
      ),
      SCard(
        title: tr('سعر الكهرباء', 'Electricity price'),
        icon: Icons.receipt_rounded,
        color: SD.nile,
        child: NumField(tr('سعر الكيلوواط ساعة', 'Price per kWh'), _price, hint: t('من فاتورة الكهربا / الجمرة', 'من فاتورة الكهرباء', 'From your electricity bill'), onChanged: (_) => _saveSolar()),
      ),
      ResultHero(
        label: tr('استهلاكك في الشهر', 'Your monthly usage'),
        value: '${fmt(monthKwh, 1)} $_kwh',
        sub: price > 0 ? tr('الفاتورة ≈ ${fmt(monthKwh * price, 0)} في الشهر', 'Bill ≈ ${fmt(monthKwh * price, 0)} per month') : t('أكتب سعر الكيلوواط عشان نحسب ليك القروش', 'اكتب سعر الكيلوواط لنحسب لك التكلفة', 'Enter the kWh price to see the cost'),
        colors: SD.sunset,
      ),
      StatGrid([
        StatChip(fmt(dailyKwh, 2), tr('ك.و.س في اليوم', 'kWh per day'), color: SD.orange, icon: Icons.today_rounded),
        StatChip(fmt(peak, 0), tr('واط حمل كامل', 'W full load'), color: SD.red, icon: Icons.bolt_rounded),
        StatChip(price > 0 ? fmt(dailyKwh * price, 0) : '—', tr('تكلفة اليوم', 'Cost per day'), color: SD.green, icon: Icons.payments_rounded),
        StatChip(fmt(monthKwh * 12, 0), tr('ك.و.س في السنة', 'kWh per year'), color: SD.nile, icon: Icons.calendar_month_rounded),
        StatChip(price > 0 ? fmt(monthKwh * 12 * price, 0) : '—', tr('تكلفة السنة', 'Cost per year'), color: SD.henna, icon: Icons.account_balance_wallet_rounded),
        StatChip(fmt(dailyWh / 24, 0), tr('واط متوسط', 'W average'), color: SD.teal, icon: Icons.av_timer_rounded),
      ]),
      const SizedBox(height: 14),
      SCard(
        title: t('منو الأكل الكهربا؟', 'ما الذي يستهلك الكهرباء؟', 'What uses the power?'),
        icon: Icons.pie_chart_rounded,
        color: SD.red,
        child: Column(children: [
          for (final e in sorted.take(6))
            PercentBar(
              e.name,
              dailyWh == 0 ? 0 : e.wh / dailyWh,
              '${fmt(dailyWh == 0 ? 0 : e.wh / dailyWh * 100, 1)}%${price > 0 ? ' • ${fmt(e.wh / 1000 * 30 * price, 0)}/${tr('شهر', 'mo')}' : ''}',
              color: e == sorted.first ? SD.red : SD.orange,
            ),
        ]),
      ),

      // ── الطاقة الشمسية ──
      SCard(
        title: t('صمّم نظام طاقة شمسية', 'صمّم نظام طاقة شمسية', 'Design a solar system'),
        icon: Icons.solar_power_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: NumField(tr('ساعات الشمس', 'Sun hours'), _sun, suffix: _hr, onChanged: (_) => _saveSolar())),
            const SizedBox(width: 10),
            Expanded(child: NumField(tr('قدرة اللوح', 'Panel power'), _panel, suffix: _wt, onChanged: (_) => _saveSolar())),
          ]),
          NumField(t('ساعات تشغيل من البطارية (ليل/قطوعات)', 'ساعات التشغيل من البطارية (الليل/الانقطاعات)', 'Battery backup hours (night/outages)'), _backup, suffix: _hr, onChanged: (_) => _saveSolar()),
          Text(tr('جهد البطاريات:', 'Battery voltage:'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ChoiceRow<int>([(12, tr('12 فولت', '12 V')), (24, tr('24 فولت', '24 V')), (48, tr('48 فولت', '48 V'))], _battV, (x) {
            _battV = x;
            _saveSolar();
          }, color: SD.gold),
          ChoiceRow<bool>([(false, tr('رصاص (تفريغ 50%)', 'Lead-acid (50% DoD)')), (true, tr('ليثيوم (تفريغ 80%)', 'Lithium (80% DoD)'))], _lithium, (x) {
            _lithium = x;
            _saveSolar();
          }, color: SD.gold),
        ]),
      ),
      SCard(
        title: tr('النظام المقترح', 'Suggested system'),
        icon: Icons.settings_input_component_rounded,
        color: SD.green,
        child: Column(children: [
          StatGrid([
            StatChip(fmt(inverterKw, 1), tr('ك.و انفرتر', 'kW inverter'), color: SD.indigo, icon: Icons.electrical_services_rounded),
            StatChip('$panels', tr('لوح ${fmt(panelW, 0)}W', 'panels ${fmt(panelW, 0)}W'), color: SD.gold, icon: Icons.solar_power_rounded),
            StatChip('$battCount', tr('بطارية 200Ah', 'batteries 200Ah'), color: SD.green, icon: Icons.battery_full_rounded),
          ]),
          const SizedBox(height: 8),
          InfoRow(tr('الانفرتر', 'Inverter'), '${fmt(inverterKw, 1)} $_kw', icon: Icons.electrical_services_rounded, hint: tr('أعلى حمل ${fmt(peak, 0)} واط + 25% احتياط', 'Peak ${fmt(peak, 0)} W + 25% margin')),
          InfoRow(tr('الألواح', 'Panels'), '$panels × ${fmt(panelW, 0)} $_wt = ${fmt(pvActual / 1000, 2)} $_kw', icon: Icons.solar_power_rounded,
              hint: tr('المطلوب ${fmt(pvW, 0)} واط (مع فاقد 25% للحرارة والغبار)', 'Needed ${fmt(pvW, 0)} W (incl. 25% heat & dust losses)')),
          InfoRow(tr('طاقة الألواح المتوقعة', 'Expected panel output'), '${fmt(pvActual * sun * sysEff / 1000, 2)} $_kwh/${tr('يوم', 'day')}', icon: Icons.wb_sunny_rounded),
          InfoRow(tr('طاقة البطارية المطلوبة', 'Required battery energy'), '${fmt(battWh / 1000, 2)} $_kwh', icon: Icons.battery_charging_full_rounded,
              hint: tr('${fmt(backupWh / 1000, 2)} ك.و.س لـ ${fmt(backupH)} ساعة ÷ تفريغ ${fmt(dod * 100, 0)}%', '${fmt(backupWh / 1000, 2)} kWh for ${fmt(backupH)} h ÷ ${fmt(dod * 100, 0)}% DoD')),
          InfoRow(tr('سعة البطاريات على ${_battV}V', 'Battery capacity at ${_battV}V'), '${fmt(battAh, 0)} ${tr('أمبير ساعة', 'Ah')}', icon: Icons.battery_std_rounded),
          InfoRow(tr('بطاريات 200Ah/12V', '200Ah/12V batteries'), tr('$battCount بطارية', '$battCount batteries'), icon: Icons.grid_view_rounded,
              hint: tr('$strings خط متوازي × $series على التوالي', '$strings parallel strings × $series in series')),
          InfoRow(tr('منظم الشحن (MPPT)', 'Charge controller (MPPT)'), '≈ ${fmt(ccA, 0)} ${tr('أمبير', 'A')}', icon: Icons.tune_rounded, hint: tr('قدرة الألواح ÷ ${_battV}V × 1.25', 'Panel power ÷ ${_battV}V × 1.25')),
        ]),
      ),
      if (hasPump)
        NoteBox(t('الطلمبة والثلاجة والمكيف بتسحب تيار بداية أكبر (2–3 أضعاف). لو بتشغّلهم مع بعض اختار انفرتر أكبر شوية.', 'المضخة والثلاجة والمكيف تسحب تيار بدء أكبر (2–3 أضعاف). إن شغّلتها معًا فاختر انفرترًا أكبر قليلًا.', 'Pumps, fridges and coolers draw 2–3× surge current at start-up. If they run together, pick a slightly bigger inverter.'), kind: NoteKind.warn),
      SCard(
        title: t('لو بالمولد (الجنريتر)', 'بالمولّد الكهربائي', 'With a generator'),
        icon: Icons.local_gas_station_rounded,
        color: SD.coffee,
        child: Column(children: [
          NumField(t('سعر لتر الجاز (اختياري)', 'سعر لتر الديزل (اختياري)', 'Diesel price per litre (optional)'), _fuel, onChanged: (_) => _saveSolar()),
          InfoRow(t('الجاز في اليوم', 'الديزل يوميًا', 'Diesel per day'), '≈ ${fmt(fuelL, 1)} ${tr('لتر', 'L')}', icon: Icons.opacity_rounded, hint: tr('على أساس 0.3 لتر لكل ك.و.س تقريبًا', 'Assuming about 0.3 L per kWh')),
          InfoRow(t('الجاز في الشهر', 'الديزل شهريًا', 'Diesel per month'), '≈ ${fmt(fuelL * 30, 0)} ${tr('لتر', 'L')}', icon: Icons.calendar_month_rounded),
          if (fuelPrice > 0) ...[
            InfoRow(t('تكلفة الجاز في الشهر', 'تكلفة الديزل شهريًا', 'Diesel cost per month'), '≈ ${fmt(fuelL * 30 * fuelPrice, 0)}', icon: Icons.payments_rounded, valueColor: SD.red),
            InfoRow(t('تكلفة الجاز في السنة', 'تكلفة الديزل سنويًا', 'Diesel cost per year'), '≈ ${fmt(fuelL * 365 * fuelPrice, 0)}', icon: Icons.savings_rounded, valueColor: SD.red,
                hint: t('قارنها بسعر نظام الشمسي — غالبًا بيرجّع حقو في كم سنة', 'قارنها بسعر النظام الشمسي — غالبًا يسترد ثمنه خلال سنوات قليلة', 'Compare with a solar system\'s price — it usually pays back in a few years')),
          ],
          InfoRow(tr('مولد مناسب', 'Suitable generator'), '≈ ${fmt(math.max(1, peak * 1.5 / 1000), 1)} ${tr('ك.ف.أ', 'kVA')}', icon: Icons.power_rounded, hint: tr('أعلى حمل × 1.5', 'Peak load × 1.5')),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 14),
      SCard(
        title: t('نصايح عشان توفّر', 'نصائح للتوفير', 'Saving tips'),
        icon: Icons.tips_and_updates_rounded,
        color: SD.teal,
        child: Column(children: [
          NoteBox(t('غيّر اللمبات القديمة لـ LED — بتاكل أقل من ربع الكهربا.', 'استبدل المصابيح القديمة بمصابيح LED — تستهلك أقل من ربع الكهرباء.', 'Switch old bulbs to LED — they use under a quarter of the power.'), kind: NoteKind.tip),
          NoteBox(t('المكيف الصحراوي: نضّف القش وغيّرو كل موسم، وافتح شباك صغير عشان الهوا يتجدد.', 'المكيف الصحراوي: نظّف القش وغيّره كل موسم، وافتح نافذة صغيرة ليتجدد الهواء.', 'Evaporative cooler: clean/replace the pads each season and open a small window for fresh air.'), kind: NoteKind.tip),
          NoteBox(t('الثلاجة: بعيد عن الشمس والحيطة، ما تفتحها كتير، وما تدخل فيها أكل سخن.', 'الثلاجة: أبعدها عن الشمس والجدار، ولا تكثر فتحها، ولا تضع فيها طعامًا ساخنًا.', 'Fridge: keep it out of the sun and off the wall, open it less, and never put hot food in.'), kind: NoteKind.tip),
          NoteBox(t('شغّل الطلمبة والمكواة والغسالة وقت الشمس لو عندك طاقة شمسية.', 'شغّل المضخة والمكواة والغسالة وقت الشمس إن كان لديك نظام شمسي.', 'With solar, run the pump, iron and washer while the sun is up.'), kind: NoteKind.tip),
          NoteBox(t('قفّل الشواحن والتلفزيون من الفيش بدل الـ standby.', 'افصل الشواحن والتلفزيون من المقبس بدل وضع الاستعداد.', 'Unplug chargers and the TV instead of leaving them on standby.'), kind: NoteKind.tip),
          NoteBox(t('نضّف الألواح الشمسية من الغبار كل كم يوم — الهبوب بيقلّل إنتاجها كتير.', 'نظّف الألواح الشمسية من الغبار كل بضعة أيام — العواصف الترابية تقلل إنتاجها كثيرًا.', 'Dust off solar panels every few days — dust storms cut output a lot.'), kind: NoteKind.tip),
        ]),
      ),
      NoteBox(t('الأرقام دي تقدير تقريبي للتخطيط بس. قبل ما تشتري، خلّي فنّي طاقة شمسية موثوق يراجع الأحمال والأسلاك والحماية.', 'هذه الأرقام تقدير تقريبي للتخطيط فقط. قبل الشراء، اطلب من فنّي طاقة شمسية موثوق مراجعة الأحمال والأسلاك والحماية.', 'These numbers are rough planning estimates. Before buying, have a trusted solar technician check loads, wiring and protection.'), kind: NoteKind.warn),
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
