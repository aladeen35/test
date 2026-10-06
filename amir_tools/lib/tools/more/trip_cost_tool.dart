import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'more_common.dart';

/// جالون إمبراطوري (يُباع به الوقود في السودان)
const _gallon = 4.54609;

class _Vehicle {
  final String sd, ar, en;
  final double l100;
  final bool diesel;
  final IconData icon;
  const _Vehicle(this.sd, this.ar, this.en, this.l100, this.diesel, this.icon);
  String get name => t(sd, ar, en);
}

const _vehicles = [
  _Vehicle('ركشة', 'ركشة (توك توك)', 'Rickshaw', 3.5, false, Icons.electric_rickshaw_rounded),
  _Vehicle('موتر', 'دراجة نارية', 'Motorbike', 3, false, Icons.two_wheeler_rounded),
  _Vehicle('عربية صغيرة', 'سيارة صغيرة', 'Small car', 6.5, false, Icons.directions_car_rounded),
  _Vehicle('صالون (كورولا)', 'سيدان (كورولا)', 'Sedan (Corolla)', 8, false, Icons.directions_car_filled_rounded),
  _Vehicle('أمجاد', 'ميني فان', 'Minivan', 9, false, Icons.airport_shuttle_rounded),
  _Vehicle('لاندكروزر', 'دفع رباعي', 'SUV / 4x4', 14, false, Icons.directions_car_filled_outlined),
  _Vehicle('بوكس ديزل', 'بيك أب ديزل', 'Diesel pickup', 10, true, Icons.local_shipping_outlined),
  _Vehicle('هايس', 'حافلة صغيرة', 'Minibus', 12, true, Icons.airport_shuttle_outlined),
  _Vehicle('بص سفري', 'حافلة سفر', 'Coach bus', 30, true, Icons.directions_bus_rounded),
  _Vehicle('لوري / دفّار', 'شاحنة', 'Truck', 35, true, Icons.local_shipping_rounded),
];

class TripCostTool extends StatefulWidget {
  const TripCostTool({super.key});
  @override
  State<TripCostTool> createState() => _TripCostToolState();
}

class _TripCostToolState extends State<TripCostTool> {
  final distC = TextEditingController(), consC = TextEditingController(), petrolC = TextEditingController(), dieselC = TextEditingController();
  final paxC = TextEditingController(), extraC = TextEditingController(), speedC = TextEditingController();
  int consMode = 0; // 0 لتر/100كم، 1 كم/لتر
  bool diesel = false, round = false, perGallon = false, road = true;
  String cur = 'SDG';
  Map? from, to;

  @override
  void initState() {
    super.initState();
    final c = context.read<AppState>().getData<Map>('trip_cfg') ?? {};
    distC.text = c['dist'] ?? '';
    consC.text = c['cons'] ?? '8';
    petrolC.text = c['pp'] ?? '3500';
    dieselC.text = c['pd'] ?? '3300';
    paxC.text = c['pax'] ?? '1';
    extraC.text = c['extra'] ?? '';
    speedC.text = c['speed'] ?? '';
    consMode = (c['cm'] as num?)?.toInt() ?? 0;
    diesel = c['diesel'] ?? false;
    round = c['round'] ?? false;
    perGallon = c['gal'] ?? false;
    road = c['road'] ?? true;
    cur = c['cur'] ?? 'SDG';
    from = c['from'] as Map?;
    to = c['to'] as Map?;
  }

  @override
  void dispose() {
    for (final c in [distC, consC, petrolC, dieselC, paxC, extraC, speedC]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    context.read<AppState>().setData('trip_cfg', {
      'dist': distC.text, 'cons': consC.text, 'pp': petrolC.text, 'pd': dieselC.text, 'pax': paxC.text, 'extra': extraC.text,
      'speed': speedC.text, 'cm': consMode, 'diesel': diesel, 'round': round, 'gal': perGallon, 'road': road, 'cur': cur,
      'from': from, 'to': to,
    });
    setState(() {});
  }

  Map _placeJson(City c) => {'n': c.name, 'lat': c.lat, 'lng': c.lng, 'c': c.country};

  Future<void> _pick(bool isFrom) async {
    final c = await pickPlace(context, title: isFrom ? t('مسافر من وين؟', 'من أين؟', 'From where?') : t('ماشي وين؟', 'إلى أين؟', 'To where?'));
    if (c == null) return;
    if (isFrom) {
      from = _placeJson(c);
    } else {
      to = _placeJson(c);
    }
    _applyPlaces();
  }

  double? get _straight {
    if (from == null || to == null) return null;
    return haversineKm((from!['lat'] as num).toDouble(), (from!['lng'] as num).toDouble(), (to!['lat'] as num).toDouble(), (to!['lng'] as num).toDouble());
  }

  void _applyPlaces() {
    final s = _straight;
    if (s != null) distC.text = fmt(s * (road ? 1.3 : 1), 0).replaceAll(',', '');
    _save();
  }

  void _useVehicle(_Vehicle v) {
    consMode = 0;
    consC.text = fmt(v.l100, 1);
    diesel = v.diesel;
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final sym = currencyByCode(cur).sym;
    final oneWay = parseNum(distC.text);
    final dist = oneWay * (round ? 2 : 1);
    final cons = parseNum(consC.text);
    final l100 = cons <= 0 ? 0.0 : (consMode == 0 ? cons : 100 / cons);
    final priceIn = parseNum(diesel ? dieselC.text : petrolC.text);
    final pricePerL = perGallon ? priceIn / _gallon : priceIn;
    final pax = parseNum(paxC.text, 1).round().clamp(1, 100);
    final extra = parseNum(extraC.text);
    final speed = parseNum(speedC.text, 80) <= 0 ? 80.0 : parseNum(speedC.text, 80);

    final liters = dist * l100 / 100;
    final fuelCost = liters * pricePerL;
    final total = fuelCost + extra;
    final ok = dist > 0 && l100 > 0;
    final co2 = liters * (diesel ? 2.68 : 2.31);
    final hours = dist / speed;
    final straight = _straight;

    return ToolList(children: [
      ResultHero(
        label: t('تكلفة المشوار', 'تكلفة الرحلة', 'Trip cost'),
        value: ok ? '${fmt(total, 0)} $sym' : '—',
        sub: ok
            ? '${fmt(liters, 1)} ${tr('لتر', 'L')} • ${fmt(dist, 0)} ${tr('كم', 'km')}${pax > 1 ? ' • ${fmt(total / pax, 0)} $sym ${t('للنفر', 'للشخص', 'per person')}' : ''}'
            : t('أكتب المسافة والاستهلاك', 'أدخل المسافة والاستهلاك', 'Enter distance and consumption'),
        colors: const [Color(0xFFE2702B), Color(0xFFB4492D), Color(0xFF3A1F0C)],
      ),
      SCard(
        title: t('المسافة', 'المسافة', 'Distance'),
        icon: Icons.route_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: _placeBtn(true)),
            IconButton(
              tooltip: t('بدّل', 'تبديل', 'Swap'),
              onPressed: () {
                final x = from;
                from = to;
                to = x;
                _save();
              },
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
            Expanded(child: _placeBtn(false)),
          ]),
          if (straight != null) ...[
            const SizedBox(height: 8),
            InfoRow(t('بخط مستقيم', 'بخط مستقيم', 'Straight line'), '${fmt(straight, 0)} ${tr('كم', 'km')}', icon: Icons.straighten_rounded),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(t('قدّر طول الشارع (+30%)', 'تقدير طول الطريق (+30%)', 'Estimate road distance (+30%)')),
              subtitle: Text(t('الشارع دايمًا أطول من الخط المستقيم', 'الطريق أطول دائمًا من الخط المستقيم', 'Roads are always longer than a straight line')),
              value: road,
              onChanged: (v) {
                road = v;
                _applyPlaces();
              },
            ),
          ],
          const SizedBox(height: 8),
          NumField(t('المسافة (ذهاب)', 'المسافة (ذهاب)', 'Distance (one way)'), distC, suffix: tr('كم', 'km'), onChanged: (_) => _save()),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t('مشوار وجيّة (ذهاب وعودة)', 'ذهاب وعودة', 'Round trip')),
            value: round,
            onChanged: (v) {
              round = v;
              _save();
            },
          ),
          if (straight != null)
            NoteBox(
                t('المسافة من الإحداثيات تقريبية (خط مستقيم). لو عارف المسافة الحقيقية بالعداد أو الخريطة، أكتبها فوق.',
                    'المسافة المحسوبة من الإحداثيات تقريبية (خط مستقيم). إن كنت تعرف المسافة الفعلية من العداد أو الخريطة فأدخلها أعلاه.',
                    'Distance from coordinates is approximate (straight line). If you know the real road distance, type it above.'),
                kind: NoteKind.warn),
        ]),
      ),
      SCard(
        title: t('العربية والوقود', 'المركبة والوقود', 'Vehicle & fuel'),
        icon: Icons.local_gas_station_rounded,
        color: SD.orange,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final v in _vehicles)
              ActionChip(avatar: Icon(v.icon, size: 18), label: Text(v.name), onPressed: () => _useVehicle(v)),
          ]),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text(t('لتر/100 كم', 'لتر/100 كم', 'L/100 km'))),
              ButtonSegment(value: 1, label: Text(t('كم/لتر', 'كم/لتر', 'km/L'))),
            ],
            selected: {consMode},
            onSelectionChanged: (v) {
              final c = parseNum(consC.text);
              if (c > 0) consC.text = fmt(100 / c, 1);
              consMode = v.first;
              _save();
            },
          ),
          const SizedBox(height: 10),
          NumField(t('الاستهلاك', 'الاستهلاك', 'Consumption'), consC, suffix: consMode == 0 ? tr('ل/100كم', 'L/100km') : tr('كم/ل', 'km/L'), onChanged: (_) => _save(),
              hint: consMode == 0 ? '8' : '12'),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(t('بنزين', 'بنزين', 'Petrol'))),
              ButtonSegment(value: true, label: Text(t('جازولين (ديزل)', 'ديزل', 'Diesel'))),
            ],
            selected: {diesel},
            onSelectionChanged: (v) {
              diesel = v.first;
              _save();
            },
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: cur,
                isExpanded: true,
                decoration: InputDecoration(labelText: t('العملة', 'العملة', 'Currency')),
                items: [for (final c in currencies) DropdownMenuItem(value: c.code, child: Text('${c.flag} ${c.code}'))],
                onChanged: (v) {
                  if (v == null) return;
                  cur = v;
                  _save();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: Text(tr('لتر', 'Liter'))),
                  ButtonSegment(value: true, label: Text(t('جالون', 'جالون', 'Gallon'))),
                ],
                selected: {perGallon},
                onSelectionChanged: (v) {
                  perGallon = v.first;
                  _save();
                },
              ),
            ),
          ]),
          const SizedBox(height: 10),
          NumField('${t('سعر', 'سعر', 'Price of')} ${diesel ? t('الجازولين', 'الديزل', 'diesel') : t('البنزين', 'البنزين', 'petrol')} / ${perGallon ? t('جالون', 'جالون', 'gallon') : tr('لتر', 'liter')}',
              diesel ? dieselC : petrolC,
              suffix: sym, onChanged: (_) => _save()),
          if (perGallon) Text('= ${fmt(pricePerL, 1)} $sym / ${tr('لتر', 'L')} (${t('الجالون', 'الجالون', '1 gallon')} = 4.546 ${tr('لتر', 'L')})', style: const TextStyle(fontSize: 12)),
        ]),
      ),
      SCard(
        title: t('الركاب والمصاريف', 'الركاب والمصاريف', 'Passengers & extras'),
        icon: Icons.groups_rounded,
        color: SD.purple,
        child: Column(children: [
          Row(children: [
            Expanded(child: NumField(t('عدد النفرات', 'عدد الأشخاص', 'People'), paxC, decimal: false, onChanged: (_) => _save())),
            const SizedBox(width: 8),
            Expanded(child: NumField(t('مصاريف تانية', 'مصاريف أخرى', 'Extra costs'), extraC, suffix: sym, hint: t('رسوم، أكل…', 'رسوم، طعام…', 'tolls, food…'), onChanged: (_) => _save())),
          ]),
          NumField(t('متوسط السرعة (اختياري)', 'متوسط السرعة (اختياري)', 'Average speed (optional)'), speedC, suffix: tr('كم/س', 'km/h'), hint: '80', onChanged: (_) => _save()),
        ]),
      ),
      if (ok) ...[
        StatGrid([
          StatChip(fmt(liters, 1), tr('لتر', 'Liters'), color: SD.orange, icon: Icons.local_gas_station_rounded),
          StatChip(fmt(liters / _gallon, 1), t('جالون', 'جالون', 'Gallons'), color: SD.henna, icon: Icons.oil_barrel_rounded),
          StatChip(fmt(fuelCost, 0), '${t('الوقود', 'الوقود', 'Fuel')} $sym', color: SD.gold, icon: Icons.payments_rounded),
          StatChip(fmt(total / pax, 0), '${t('للنفر', 'للشخص', 'Per person')} $sym', color: SD.purple, icon: Icons.person_rounded),
          StatChip(fmt(total / dist, 1), '$sym / ${tr('كم', 'km')}', color: SD.nile, icon: Icons.speed_rounded),
          StatChip(fmt(co2, co2 < 100 ? 1 : 0), t('كجم CO₂', 'كغ CO₂', 'kg CO₂'), color: SD.green, icon: Icons.eco_rounded),
        ]),
        const SizedBox(height: 12),
        SCard(
          title: t('التفاصيل', 'التفاصيل', 'Details'),
          icon: Icons.receipt_long_rounded,
          color: SD.coffee,
          child: Column(children: [
            InfoRow(t('المسافة الكلية', 'المسافة الكلية', 'Total distance'), '${fmt(dist, 0)} ${tr('كم', 'km')}', hint: round ? t('ذهاب وعودة', 'ذهاب وعودة', 'Round trip') : null),
            InfoRow(t('الاستهلاك', 'الاستهلاك', 'Consumption'), '${fmt(l100, 1)} ${tr('ل/100كم', 'L/100km')} • ${fmt(100 / l100, 1)} ${tr('كم/ل', 'km/L')}'),
            InfoRow(t('قروش الوقود', 'تكلفة الوقود', 'Fuel cost'), '${fmt(fuelCost, 0)} $sym'),
            if (extra > 0) InfoRow(t('مصاريف تانية', 'مصاريف أخرى', 'Extras'), '${fmt(extra, 0)} $sym'),
            InfoRow(t('الجملة', 'الإجمالي', 'Total'), '${fmt(total, 0)} $sym', valueColor: SD.orange),
            if (pax > 1) InfoRow(t('على كل نفر', 'على كل شخص', 'Each person pays'), '${fmt(total / pax, 0)} $sym', valueColor: SD.purple, hint: '÷ $pax'),
            InfoRow(t('زمن السواقة التقريبي', 'زمن القيادة التقريبي', 'Approx. driving time'), fmtDuration(Duration(minutes: (hours * 60).round())),
                hint: '${t('بسرعة', 'بسرعة', 'at')} ${fmt(speed, 0)} ${tr('كم/س', 'km/h')}'),
            InfoRow(t('انبعاثات الكربون', 'انبعاثات ثاني أكسيد الكربون', 'CO₂ emissions'), '${fmt(co2, 1)} ${t('كجم', 'كغ', 'kg')}',
                hint: '${diesel ? '2.68' : '2.31'} ${t('كجم لكل لتر', 'كغ لكل لتر', 'kg per liter')}'),
          ]),
        ),
        ShareBar(() => [
              '🚗 ${t('تكلفة المشوار', 'تكلفة الرحلة', 'Trip cost')}${from != null && to != null ? ': ${from!['n']} → ${to!['n']}' : ''}',
              '${t('المسافة', 'المسافة', 'Distance')}: ${fmt(dist, 0)} ${tr('كم', 'km')}${round ? ' (${t('ذهاب وعودة', 'ذهاب وعودة', 'round trip')})' : ''}',
              '${t('الوقود', 'الوقود', 'Fuel')}: ${fmt(liters, 1)} ${tr('لتر', 'L')} = ${fmt(fuelCost, 0)} $sym',
              if (extra > 0) '${t('مصاريف تانية', 'مصاريف أخرى', 'Extras')}: ${fmt(extra, 0)} $sym',
              '${t('الجملة', 'الإجمالي', 'Total')}: ${fmt(total, 0)} $sym',
              if (pax > 1) '${t('على كل نفر', 'على كل شخص', 'Per person')}: ${fmt(total / pax, 0)} $sym',
            ].join('\n')),
        const SizedBox(height: 12),
      ],
      NoteBox(
          t('السعر الافتراضي للوقود تقريبي — غيّرو لسعر محطتك وبنحفظو ليك. الاستهلاك بيزيد مع التكييف، الحمولة، والشوارع الترابية.',
              'سعر الوقود الافتراضي تقريبي — عدّله لسعر محطتك وسيُحفظ. يزيد الاستهلاك مع التكييف والحمولة والطرق الترابية.',
              'Default fuel prices are rough — set your local price and it will be saved. Consumption rises with A/C, heavy loads and dirt roads.'),
          kind: NoteKind.tip),
    ]);
  }

  Widget _placeBtn(bool isFrom) {
    final p = isFrom ? from : to;
    final c = isFrom ? SD.green : SD.red;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pick(isFrom),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: c.withValues(alpha: .08), borderRadius: BorderRadius.circular(14), border: Border.all(color: c.withValues(alpha: .35))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isFrom ? tr('من', 'From') : tr('إلى', 'To'), style: TextStyle(fontSize: 11.5, color: readable(context, c), fontWeight: FontWeight.w700)),
          Text(p == null ? t('اختار مدينة', 'اختر مدينة', 'Pick a city') : '${flagOf(p['c'] ?? '')} ${p['n']}',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}
