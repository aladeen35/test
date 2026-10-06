import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'money_common.dart';

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

const _cats = <_Cat>[
  _Cat('المساحة', Icons.crop_square_rounded, SD.green, [
    _U('متر مربع', 'م²', 1),
    _U('فدان سوداني', 'فدان', 4200),
    _U('قيراط', 'قيراط', 175),
    _U('هكتار', 'هكتار', 10000),
    _U('إيكر (فدان إنجليزي)', 'acre', 4046.8564224),
    _U('كيلومتر مربع', 'كم²', 1e6),
    _U('ميل مربع', 'mi²', 2589988.110336),
    _U('قدم مربع', 'ft²', 0.09290304),
    _U('ياردة مربعة', 'yd²', 0.83612736),
    _U('سنتيمتر مربع', 'سم²', 1e-4),
  ], note: 'الفدان السوداني = 4200 م² = 24 قيراط (القيراط 175 م²). الإيكر الإنجليزي ≈ 4047 م².'),
  _Cat('الطول', Icons.straighten_rounded, SD.nile, [
    _U('متر', 'م', 1),
    _U('سنتيمتر', 'سم', .01),
    _U('مليمتر', 'مم', .001),
    _U('كيلومتر', 'كم', 1000),
    _U('بوصة (إنش)', 'in', .0254),
    _U('قدم', 'ft', .3048),
    _U('ياردة', 'yd', .9144),
    _U('ميل', 'mi', 1609.344),
    _U('ميل بحري', 'nmi', 1852),
  ]),
  _Cat('الوزن', Icons.scale_rounded, SD.coffee, [
    _U('كيلوجرام', 'كجم', 1),
    _U('جرام', 'جم', .001),
    _U('مليجرام', 'ملجم', 1e-6),
    _U('طن', 'طن', 1000),
    _U('رطل (باوند)', 'lb', .45359237),
    _U('أوقية', 'oz', .028349523125),
    _U('قنطار', 'قنطار', 44.928),
    _U('جوال 50 كيلو', 'جوال', 50),
    _U('جوال 90 كيلو', 'جوال', 90),
  ], note: 'القنطار هنا = 44.928 كجم (قنطار القطن). الجوال حسب نوعو: 50 ولا 90 كيلو.'),
  _Cat('الحجم والسوائل', Icons.water_drop_rounded, SD.teal, [
    _U('لتر', 'لتر', 1),
    _U('مليلتر', 'مل', .001),
    _U('متر مكعب', 'م³', 1000),
    _U('جالون أمريكي', 'US gal', 3.785411784),
    _U('جالون إنجليزي', 'UK gal', 4.54609),
    _U('برميل نفط', 'bbl', 158.987294928),
    _U('جركانة 20 لتر', 'جركانة', 20),
    _U('كوب (أمريكي)', 'cup', .2365882365),
  ]),
  _Cat('الحرارة', Icons.thermostat_rounded, SD.red, [
    _U('سيليزي', '°C', 0),
    _U('فهرنهايت', '°F', 0),
    _U('كلفن', 'K', 0),
  ]),
  _Cat('السرعة', Icons.speed_rounded, SD.purple, [
    _U('كيلومتر/ساعة', 'كم/س', 1 / 3.6),
    _U('متر/ثانية', 'م/ث', 1),
    _U('ميل/ساعة', 'mph', .44704),
    _U('عقدة', 'knot', 1852 / 3600),
    _U('قدم/ثانية', 'ft/s', .3048),
  ]),
  _Cat('حجم البيانات', Icons.sd_storage_rounded, SD.indigo, [
    _U('بايت', 'B', 1),
    _U('بت', 'bit', 1 / 8),
    _U('كيلوبايت', 'KB', 1024),
    _U('ميجابايت', 'MB', 1048576),
    _U('جيجابايت', 'GB', 1073741824),
    _U('تيرابايت', 'TB', 1099511627776),
  ], note: 'محسوبة بنظام 1024 (زي الموبايل والكمبيوتر). شركات الاتصالات أحيانًا بتحسب بـ 1000.'),
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
          '📏 تحويل ${c.name}',
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
              padding: const EdgeInsets.only(left: 8),
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
          NumField('القيمة', _v, hint: 'أكتب الرقم هنا', suffix: fu.sym, onChanged: (_) => _save()),
          Row(children: [
            Expanded(child: _picker('من', _from, (x) => _from = x)),
            IconButton.filledTonal(
              tooltip: 'بدّل',
              onPressed: () {
                final t = _from;
                _from = _to;
                _to = t;
                _save();
              },
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
            Expanded(child: _picker('إلى', _to, (x) => _to = x)),
          ]),
        ]),
      ),
      ResultHero(
        label: '${_fmtU(v)} ${fu.name} =',
        value: '${_fmtU(res)} ${tu.sym}',
        sub: '${tu.name}${_cat == 4 ? '' : ' • 1 ${fu.sym} = ${_fmtU(_conv(1, _from, _to))} ${tu.sym}'}',
      ),
      SCard(
        title: 'بكل الوحدات',
        icon: Icons.format_list_numbered_rounded,
        color: c.color,
        child: Column(children: [
          for (var i = 0; i < c.units.length; i++)
            InfoRow(c.units[i].name, '${_fmtU(_conv(v, _from, i))} ${c.units[i].sym}',
                icon: i == _from ? Icons.radio_button_checked_rounded : Icons.chevron_left_rounded,
                valueColor: i == _from ? c.color : (i == _to ? SD.gold : null)),
        ]),
      ),
      if (c.note != null) NoteBox(c.note!, kind: NoteKind.info),
      if (_cat == 0 && v > 0) _areaExtras(v),
      if (_cat == 4) _tempExtras(_toC(v, _from)),
      ShareBar(summary),
      const SizedBox(height: 10),
      const NoteBox('اضغط ضغطة طويلة على أي رقم عشان تنسخو.', kind: NoteKind.tip),
    ]);
  }

  Widget _picker(String label, int value, void Function(int) set) => DropdownButtonFormField<int>(
        key: ValueKey('$_cat-$label'),
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
      title: 'معلومات زيادة عن المساحة',
      icon: Icons.landscape_rounded,
      color: SD.green,
      child: Column(children: [
        InfoRow('بالفدان والقيراط', '$whole فدان و ${fmt(qir, 2)} قيراط', icon: Icons.agriculture_rounded),
        InfoRow('لو مربع، طول الضلع', '${fmt(side, 2)} م', icon: Icons.square_foot_rounded),
        InfoRow('عدد قطع 300 م² (قطعة سكنية)', fmt(m2 / 300, 2), icon: Icons.home_work_rounded),
        InfoRow('ملاعب كورة (≈ 7140 م²)', fmt(m2 / 7140, 3), icon: Icons.sports_soccer_rounded),
      ]),
    );
  }

  Widget _tempExtras(double c) {
    final desc = c <= 0
        ? 'تلج! 🧊'
        : c < 15
            ? 'برد شديد بالنسبة للسودان 🥶'
            : c < 25
                ? 'جو لطيف 🌤️'
                : c < 35
                    ? 'دافي / حار شوية ☀️'
                    : c < 45
                        ? 'سخانة سودانية أصلية 🔥'
                        : 'حرّ خطير — أشرب موية كتير 🥵';
    return NoteBox('${fmt(c, 1)}°C: $desc${c >= 100 ? ' (درجة غليان الموية 100°C)' : ''}', kind: c >= 40 ? NoteKind.warn : NoteKind.info);
  }
}
