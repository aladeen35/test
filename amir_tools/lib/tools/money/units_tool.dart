import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class _U {
  final String name, sym;
  final double f; // كم وحدة أساس في الوحدة الواحدة
  const _U(this.name, this.sym, this.f);
}

class _Cat {
  final String name;
  final IconData icon;
  final Color color;
  final List<_U> units;
  final String? note;
  const _Cat(this.name, this.icon, this.color, this.units, {this.note});
}

List<_Cat> get _cats => <_Cat>[
  _Cat(tr('المساحة', 'Area'), Icons.crop_square_rounded, SD.green, [
    _U(tr('متر مربع', 'Square metre'), tr('م²', 'm²'), 1),
    _U(tr('فدان سوداني', 'Sudanese feddan'), tr('فدان', 'feddan'), 4200),
    _U(tr('قيراط', 'Qirat'), tr('قيراط', 'qirat'), 175),
    _U(tr('هكتار', 'Hectare'), tr('هكتار', 'ha'), 10000),
    _U(tr('إيكر (فدان إنجليزي)', 'Acre'), 'acre', 4046.8564224),
    _U(tr('كيلومتر مربع', 'Square kilometre'), tr('كم²', 'km²'), 1e6),
    _U(tr('ميل مربع', 'Square mile'), 'mi²', 2589988.110336),
    _U(tr('قدم مربع', 'Square foot'), 'ft²', 0.09290304),
    _U(tr('ياردة مربعة', 'Square yard'), 'yd²', 0.83612736),
    _U(tr('سنتيمتر مربع', 'Square centimetre'), tr('سم²', 'cm²'), 1e-4),
  ], note: t('الفدان السوداني = 4200 م² = 24 قيراط (القيراط 175 م²). الإيكر الإنجليزي ≈ 4047 م².', 'الفدان السوداني = 4200 م² = 24 قيراطًا (القيراط 175 م²). الإيكر الإنجليزي ≈ 4047 م².', 'Sudanese feddan = 4200 m² = 24 qirat (1 qirat = 175 m²). An acre ≈ 4047 m².')),
  _Cat(tr('الطول', 'Length'), Icons.straighten_rounded, SD.nile, [
    _U(tr('متر', 'Metre'), tr('م', 'm'), 1),
    _U(tr('سنتيمتر', 'Centimetre'), tr('سم', 'cm'), .01),
    _U(tr('مليمتر', 'Millimetre'), tr('مم', 'mm'), .001),
    _U(tr('كيلومتر', 'Kilometre'), tr('كم', 'km'), 1000),
    _U(tr('بوصة (إنش)', 'Inch'), 'in', .0254),
    _U(tr('قدم', 'Foot'), 'ft', .3048),
    _U(tr('ياردة', 'Yard'), 'yd', .9144),
    _U(tr('ميل', 'Mile'), 'mi', 1609.344),
    _U(tr('ميل بحري', 'Nautical mile'), 'nmi', 1852),
  ]),
  _Cat(tr('الوزن', 'Weight'), Icons.scale_rounded, SD.coffee, [
    _U(tr('كيلوجرام', 'Kilogram'), tr('كجم', 'kg'), 1),
    _U(tr('جرام', 'Gram'), tr('جم', 'g'), .001),
    _U(tr('مليجرام', 'Milligram'), tr('ملجم', 'mg'), 1e-6),
    _U(tr('طن', 'Tonne'), tr('طن', 't'), 1000),
    _U(tr('رطل (باوند)', 'Pound'), 'lb', .45359237),
    _U(tr('أوقية', 'Ounce'), 'oz', .028349523125),
    _U(tr('قنطار', 'Qantar (cotton)'), tr('قنطار', 'qantar'), 44.928),
    _U(t('جوال 50 كيلو', 'جوال 50 كجم', 'Sack 50 kg'), tr('جوال', 'sack'), 50),
    _U(t('جوال 90 كيلو', 'جوال 90 كجم', 'Sack 90 kg'), tr('جوال', 'sack'), 90),
  ], note: t('القنطار هنا = 44.928 كجم (قنطار القطن). الجوال حسب نوعو: 50 ولا 90 كيلو.', 'القنطار هنا = 44.928 كجم (قنطار القطن). الجوال حسب نوعه: 50 أو 90 كجم.', 'Qantar here = 44.928 kg (the cotton qantar). Sacks come in 50 or 90 kg.')),
  _Cat(tr('الحجم والسوائل', 'Volume & liquids'), Icons.water_drop_rounded, SD.teal, [
    _U(tr('لتر', 'Litre'), tr('لتر', 'L'), 1),
    _U(tr('مليلتر', 'Millilitre'), tr('مل', 'mL'), .001),
    _U(tr('متر مكعب', 'Cubic metre'), tr('م³', 'm³'), 1000),
    _U(tr('جالون أمريكي', 'US gallon'), 'US gal', 3.785411784),
    _U(tr('جالون إنجليزي', 'UK gallon'), 'UK gal', 4.54609),
    _U(tr('برميل نفط', 'Oil barrel'), 'bbl', 158.987294928),
    _U(t('جركانة 20 لتر', 'جركن 20 لترًا', 'Jerrycan 20 L'), t('جركانة', 'جركن', 'jerrycan'), 20),
    _U(tr('كوب (أمريكي)', 'Cup (US)'), 'cup', .2365882365),
  ]),
  _Cat(tr('الحرارة', 'Temperature'), Icons.thermostat_rounded, SD.red, [
    _U(tr('سيليزي', 'Celsius'), '°C', 0),
    _U(tr('فهرنهايت', 'Fahrenheit'), '°F', 0),
    _U(tr('كلفن', 'Kelvin'), 'K', 0),
  ]),
  _Cat(tr('السرعة', 'Speed'), Icons.speed_rounded, SD.purple, [
    _U(tr('كيلومتر/ساعة', 'Kilometre/hour'), tr('كم/س', 'km/h'), 1 / 3.6),
    _U(tr('متر/ثانية', 'Metre/second'), tr('م/ث', 'm/s'), 1),
    _U(tr('ميل/ساعة', 'Mile/hour'), 'mph', .44704),
    _U(tr('عقدة', 'Knot'), 'knot', 1852 / 3600),
    _U(tr('قدم/ثانية', 'Foot/second'), 'ft/s', .3048),
  ]),
  _Cat(tr('حجم البيانات', 'Data size'), Icons.sd_storage_rounded, SD.indigo, [
    _U(tr('بايت', 'Byte'), 'B', 1),
    _U(tr('بت', 'Bit'), 'bit', 1 / 8),
    _U(tr('كيلوبايت', 'Kilobyte'), 'KB', 1024),
    _U(tr('ميجابايت', 'Megabyte'), 'MB', 1048576),
    _U(tr('جيجابايت', 'Gigabyte'), 'GB', 1073741824),
    _U(tr('تيرابايت', 'Terabyte'), 'TB', 1099511627776),
  ], note: t('محسوبة بنظام 1024 (زي الموبايل والكمبيوتر). شركات الاتصالات أحيانًا بتحسب بـ 1000.', 'محسوبة بنظام 1024 (كما في الهاتف والحاسوب). قد تحسب شركات الاتصالات بـ 1000.', 'Uses 1024-based units (like phones and computers). Carriers sometimes count in 1000s.')),
];

double _toC(double v, int u) => switch (u) { 1 => (v - 32) * 5 / 9, 2 => v - 273.15, _ => v };
double _fromC(double c, int u) => switch (u) { 1 => c * 9 / 5 + 32, 2 => c + 273.15, _ => c };

String _fmtU(double x) {
  final a = x.abs();
  if (a == 0) return '0';
  if (a >= 1e12 || a < 1e-6) return x.toStringAsExponential(4);
  if (a < .001) return fmt(x, 8);
  if (a < 1) return fmt(x, 6);
  return fmt(x, 4);
}

class UnitsTool extends StatefulWidget {
  const UnitsTool({super.key});
  @override
  State<UnitsTool> createState() => _UnitsToolState();
}

class _UnitsToolState extends State<UnitsTool> {
  final _v = TextEditingController();
  int _cat = 0, _from = 0, _to = 1;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final d = Map<String, dynamic>.from(s.getData<Map>('units_state') ?? {});
    _cat = (d['cat'] ?? 0).clamp(0, _cats.length - 1);
    final n = _cats[_cat].units.length;
    _from = (d['from'] ?? 1).clamp(0, n - 1);
    _to = (d['to'] ?? 0).clamp(0, n - 1);
    _v.text = d['v'] ?? '1';
  }

  @override
  void dispose() {
    _v.dispose();
    super.dispose();
  }

  void _save() {
    context.read<AppState>().setData('units_state', {'cat': _cat, 'from': _from, 'to': _to, 'v': _v.text});
    setState(() {});
  }

  double _conv(double v, int from, int to) {
    if (_cat == 4) return _fromC(_toC(v, from), to);
    final u = _cats[_cat].units;
    return v * u[from].f / u[to].f;
  }

  @override
  Widget build(BuildContext context) {
    final c = _cats[_cat];
    final v = parseNum(_v.text);
    final res = _conv(v, _from, _to);
    final fu = c.units[_from], tu = c.units[_to];

    String summary() => [
          '📏 ${tr('تحويل', 'Convert')} ${c.name}',
          '${_fmtU(v)} ${fu.name} = ${_fmtU(res)} ${tu.name}',
          '',
          for (var i = 0; i < c.units.length; i++)
            if (i != _from) '• ${_fmtU(_conv(v, _from, i))} ${c.units[i].name}',
        ].join('\n');

    return ToolList(children: [
      SizedBox(
        height: 46,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (var i = 0; i < _cats.length; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                avatar: Icon(_cats[i].icon, size: 18, color: _cats[i].color),
                label: Text(_cats[i].name),
                selected: i == _cat,
                selectedColor: _cats[i].color.withValues(alpha: .22),
                onSelected: (_) {
                  _cat = i;
                  _from = 0;
                  _to = 1;
                  _save();
                },
              ),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      SCard(
        title: c.name,
        icon: c.icon,
        color: c.color,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField(tr('القيمة', 'Value'), _v, hint: t('أكتب الرقم هنا', 'اكتب الرقم هنا', 'Type a number'), suffix: fu.sym, onChanged: (_) => _save()),
          Row(children: [
            Expanded(child: _picker(tr('من', 'From'), _from, (x) => _from = x)),
            IconButton.filledTonal(
              tooltip: t('بدّل', 'تبديل', 'Swap'),
              onPressed: () {
                final tmp = _from;
                _from = _to;
                _to = tmp;
                _save();
              },
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
            Expanded(child: _picker(tr('إلى', 'To'), _to, (x) => _to = x)),
          ]),
        ]),
      ),
      ResultHero(
        label: '${_fmtU(v)} ${fu.name} =',
        value: '${_fmtU(res)} ${tu.sym}',
        sub: '${tu.name}${_cat == 4 ? '' : ' • 1 ${fu.sym} = ${_fmtU(_conv(1, _from, _to))} ${tu.sym}'}',
      ),
      SCard(
        title: tr('بكل الوحدات', 'In all units'),
        icon: Icons.format_list_numbered_rounded,
        color: c.color,
        child: Column(children: [
          for (var i = 0; i < c.units.length; i++)
            InfoRow(c.units[i].name, '${_fmtU(_conv(v, _from, i))} ${c.units[i].sym}',
                icon: i == _from ? Icons.radio_button_checked_rounded : (isEn ? Icons.chevron_right_rounded : Icons.chevron_left_rounded),
                valueColor: i == _from ? c.color : (i == _to ? SD.gold : null)),
        ]),
      ),
      if (c.note != null) NoteBox(c.note!, kind: NoteKind.info),
      if (_cat == 0 && v > 0) _areaExtras(v),
      if (_cat == 4) _tempExtras(_toC(v, _from)),
      ShareBar(summary),
      const SizedBox(height: 10),
      NoteBox(t('اضغط ضغطة طويلة على أي رقم عشان تنسخو.', 'اضغط مطوّلًا على أي رقم لنسخه.', 'Long-press any number to copy it.'), kind: NoteKind.tip),
    ]);
  }

  Widget _picker(String label, int value, void Function(int) set) => DropdownButtonFormField<int>(
        key: ValueKey('$_cat-$label-${appLang.name}'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        items: [
          for (var i = 0; i < _cats[_cat].units.length; i++)
            DropdownMenuItem(value: i, child: Text(_cats[_cat].units[i].name, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (x) {
          if (x == null) return;
          set(x);
          _save();
        },
      );

  Widget _areaExtras(double v) {
    final m2 = v * _cats[0].units[_from].f;
    final side = m2 <= 0 ? 0.0 : math.sqrt(m2);
    final fd = m2 / 4200;
    final whole = fd.floor();
    final qir = (m2 - whole * 4200) / 175;
    return SCard(
      title: t('معلومات زيادة عن المساحة', 'معلومات إضافية عن المساحة', 'More about this area'),
      icon: Icons.landscape_rounded,
      color: SD.green,
      child: Column(children: [
        InfoRow(tr('بالفدان والقيراط', 'In feddan & qirat'), tr('$whole فدان و ${fmt(qir, 2)} قيراط', '$whole feddan + ${fmt(qir, 2)} qirat'), icon: Icons.agriculture_rounded),
        InfoRow(t('لو مربع، طول الضلع', 'إن كانت مربعة، طول الضلع', 'If square, side length'), '${fmt(side, 2)} ${tr('م', 'm')}', icon: Icons.square_foot_rounded),
        InfoRow(tr('عدد قطع 300 م² (قطعة سكنية)', 'Number of 300 m² residential plots'), fmt(m2 / 300, 2), icon: Icons.home_work_rounded),
        InfoRow(t('ملاعب كورة (≈ 7140 م²)', 'ملاعب كرة قدم (≈ 7140 م²)', 'Football pitches (≈ 7140 m²)'), fmt(m2 / 7140, 3), icon: Icons.sports_soccer_rounded),
      ]),
    );
  }

  Widget _tempExtras(double c) {
    final desc = c <= 0
        ? t('تلج! 🧊', 'تجمّد! 🧊', 'Freezing! 🧊')
        : c < 15
            ? t('برد شديد بالنسبة لينا 🥶', 'برد شديد 🥶', 'Cold 🥶')
            : c < 25
                ? t('جو لطيف 🌤️', 'جو معتدل 🌤️', 'Pleasant 🌤️')
                : c < 35
                    ? t('دافي / حار شوية ☀️', 'دافئ / حار قليلًا ☀️', 'Warm ☀️')
                    : c < 45
                        ? t('سخانة سودانية أصلية 🔥', 'حرّ شديد 🔥', 'Very hot 🔥')
                        : t('حرّ خطير — أشرب موية كتير 🥵', 'حرّ خطير — اشرب ماءً كثيرًا 🥵', 'Dangerous heat — drink plenty of water 🥵');
    return NoteBox('${fmt(c, 1)}°C: $desc${c >= 100 ? t(' (درجة غليان الموية 100°C)', ' (درجة غليان الماء 100°C)', ' (water boils at 100°C)') : ''}', kind: c >= 40 ? NoteKind.warn : NoteKind.info);
  }
}
