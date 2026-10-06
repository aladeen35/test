import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../money/money_common.dart' show CurrencyPicker, curSym;
import 'home_common.dart';

/// ثوابت التقدير الهندسي المعتادة
const _dryMortar = 1.33; // معامل الحجم الجاف للمونة
const _dryConcrete = 1.54; // معامل الحجم الجاف للخرسانة
const _cementDensity = 1440.0; // كجم/م³
const _bagKg = 50.0;

/// نتيجة حساب المونة/الخلطة
class _Mix {
  final double cementKg, sandM3, gravelM3;
  const _Mix(this.cementKg, this.sandM3, [this.gravelM3 = 0]);
  double get bags => cementKg / _bagKg;
}

_Mix _mortar(double wetM3, double ratio) {
  final dry = wetM3 * _dryMortar;
  return _Mix(dry / (1 + ratio) * _cementDensity, dry * ratio / (1 + ratio));
}

_Mix _concrete(double wetM3, double sand, double gravel) {
  final dry = wetM3 * _dryConcrete;
  final sum = 1 + sand + gravel;
  return _Mix(dry / sum * _cementDensity, dry * sand / sum, dry * gravel / sum);
}

class BuildingTool extends StatefulWidget {
  const BuildingTool({super.key});
  @override
  State<BuildingTool> createState() => _BuildingToolState();
}

class _BuildingToolState extends State<BuildingTool> {
  final f = FieldBag('building_in', const {
    'len': '10', 'rl': '4', 'rw': '3.5', 'h': '3',
    'doors': '1', 'dw': '0.9', 'dh': '2.1', 'wins': '1', 'ww': '1.2', 'wh': '1.2', 'other': '0',
    'bl': '22', 'bw': '10.5', 'bh': '6.5', 'joint': '1', 'waste': '5',
    'pth': '1.5',
    'sl': '4', 'sw': '3.5', 'st': '12', 'steel': '90',
    'pBrick': '', 'pCement': '', 'pSand': '', 'pGravel': '', 'pSteel': '',
  });
  String mode = 'room', brick = 'red', bond = 'half', mix = '124', cur = 'SDG';
  double ratio = 4;
  int sides = 2;
  bool plaster = true, slab = true;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    f.load(s);
    final m = s.getData<Map>('building_in') ?? const {};
    mode = (m['_mode'] as String?) ?? mode;
    brick = (m['_brick'] as String?) ?? brick;
    bond = (m['_bond'] as String?) ?? bond;
    mix = (m['_mix'] as String?) ?? mix;
    cur = (m['_cur'] as String?) ?? cur;
    ratio = (m['_ratio'] as num?)?.toDouble() ?? ratio;
    sides = (m['_sides'] as num?)?.toInt() ?? sides;
    plaster = m['_plaster'] as bool? ?? plaster;
    slab = m['_slab'] as bool? ?? slab;
  }

  @override
  void dispose() {
    f.dispose();
    super.dispose();
  }

  void _save() {
    f.save(context.read<AppState>(), {
      '_mode': mode, '_brick': brick, '_bond': bond, '_mix': mix, '_cur': cur,
      '_ratio': ratio, '_sides': sides, '_plaster': plaster, '_slab': slab,
    });
    setState(() {});
  }

  void _changed(String _) => _save();

  Widget _num(String key, String label, {String? suffix, bool decimal = true}) => NumField(label, f[key], suffix: suffix, decimal: decimal, onChanged: _changed);

  @override
  Widget build(BuildContext context) {
    final sym = curSym(cur);
    final m = t('م', 'م', 'm'), m2 = t('م²', 'م²', 'm²'), m3 = t('م³', 'م³', 'm³');

    // ── الجدار ──
    final length = switch (mode) { 'room' => 2 * (f.n('rl') + f.n('rw')), _ => f.n('len') };
    final h = f.n('h');
    final gross = length * h;
    final openings = f.n('doors') * f.n('dw') * f.n('dh') + f.n('wins') * f.n('ww') * f.n('wh') + f.n('other');
    final net = math.max(0.0, gross - openings);
    final (bl, bw, bh) = switch (brick) {
      'red' => (0.22, 0.105, 0.065),
      'block' => (0.40, 0.20, 0.20),
      _ => (f.n('bl') / 100, f.n('bw') / 100, f.n('bh') / 100),
    };
    final j = f.n('joint', 1) / 100;
    final full = brick != 'block' && bond == 'full';
    final thick = full ? bl : bw;
    final valid = bl > 0 && bw > 0 && bh > 0;
    final layers = valid ? (thick + j) / (bw + j) : 0.0;
    final perM2 = valid ? layers / ((bl + j) * (bh + j)) : 0.0;
    final units = net * perM2;
    final unitsW = (units * (1 + f.n('waste') / 100)).ceilToDouble();
    final wallVol = net * thick;
    final wetMortar = math.max(0.0, wallVol - units * bl * bw * bh);
    final wm = _mortar(wetMortar, ratio);

    // ── اللياسة ──
    final pArea = net * sides;
    final pWet = pArea * f.n('pth') / 100;
    final pm = _mortar(pWet, 4);

    // ── السقف/البلاطة ──
    final sVol = f.n('sl') * f.n('sw') * f.n('st') / 100;
    final sm = mix == '124' ? _concrete(sVol, 2, 4) : _concrete(sVol, 1.5, 3);
    final steelKg = sVol * f.n('steel');

    // ── الإجماليات ──
    final totalBags = wm.bags + (plaster ? pm.bags : 0) + (slab ? sm.bags : 0);
    final totalSand = wm.sandM3 + (plaster ? pm.sandM3 : 0) + (slab ? sm.sandM3 : 0);
    final totalGravel = slab ? sm.gravelM3 : 0.0;
    final totalSteel = slab ? steelKg : 0.0;
    final pb = f.n('pBrick'), pc = f.n('pCement'), ps = f.n('pSand'), pg = f.n('pGravel'), pst = f.n('pSteel');
    final cBricks = unitsW * pb, cCement = totalBags.ceil() * pc, cSand = totalSand * ps, cGravel = totalGravel * pg, cSteel = totalSteel / 1000 * pst;
    final cost = cBricks + cCement + cSand + cGravel + cSteel;
    String? money(double v) => v > 0 ? '${fmt(v, 0)} $sym' : null;

    final unitName = brick == 'block' ? t('بلكة', 'بلوكة', 'blocks') : t('طوبة', 'طوبة', 'bricks');
    final plural = brick == 'block' ? t('البلك', 'البلوك', 'blocks') : t('الطوب', 'الطوب', 'bricks');
    final bagsTxt = t('شوال', 'كيس', 'bags');

    String summary() {
      final b = StringBuffer('🧱 ${t('تقدير مواد البناء', 'تقدير مواد البناء', 'Building materials estimate')}\n');
      b.writeln('${t('مساحة الحيطة', 'مساحة الجدار', 'Wall area')}: ${fmt(net, 2)} $m2');
      b.writeln('$unitName: ${fmt(unitsW, 0)}');
      b.writeln('${t('أسمنت', 'إسمنت', 'Cement')}: ${fmt(totalBags.ceil(), 0)} $bagsTxt (50 kg)');
      b.writeln('${t('رملة', 'رمل', 'Sand')}: ${fmt(totalSand, 2)} $m3');
      if (slab) {
        b.writeln('${t('خرسانة السقف', 'خرسانة البلاطة', 'Slab concrete')}: ${fmt(sVol, 2)} $m3');
        b.writeln('${t('حصى/خرصانة', 'حصى', 'Gravel')}: ${fmt(totalGravel, 2)} $m3');
        b.writeln('${t('سيخ', 'حديد تسليح', 'Steel')}: ${fmt(totalSteel, 0)} kg');
      }
      if (cost > 0) b.writeln('${t('التكلفة التقريبية', 'التكلفة التقريبية', 'Approx. cost')}: ${fmt(cost, 0)} $sym');
      b.write(t('⚠️ تقدير بس — راجع مهندس', '⚠️ تقدير تقريبي — راجع مهندسًا', '⚠️ Estimate only — confirm with an engineer'));
      return b.toString();
    }

    return ToolList(children: [
      ResultHero(
        label: cost > 0 ? t('التكلفة التقريبية', 'التكلفة التقريبية', 'Approximate cost') : t('عدد $plural', 'عدد $plural', 'Number of $unitName'),
        value: cost > 0 ? '${fmt(cost, 0)} $sym' : fmt(unitsW, 0),
        sub: [
          '${fmt(unitsW, 0)} $unitName',
          '${fmt(totalBags.ceil(), 0)} $bagsTxt ${t('أسمنت', 'إسمنت', 'cement')}',
          '${fmt(totalSand, 1)} $m3 ${t('رملة', 'رمل', 'sand')}',
        ].join(' · '),
        colors: const [SD.henna, SD.coffee, SD.brownDeep],
      ),
      SCard(
        title: t('الحيطة', 'الجدار', 'Walls'),
        icon: Icons.foundation_rounded,
        color: SD.henna,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          HSeg<String>(mode, [('wall', t('حيطة', 'جدار', 'Wall')), ('room', t('غرفة', 'غرفة', 'Room')), ('fence', t('سور', 'سور', 'Fence'))], (v) {
            mode = v;
            _save();
          }),
          if (mode == 'room')
            Pair(_num('rl', t('طول الغرفة', 'طول الغرفة', 'Room length'), suffix: m), _num('rw', t('عرض الغرفة', 'عرض الغرفة', 'Room width'), suffix: m))
          else
            _num('len', mode == 'fence' ? t('طول السور كلو', 'محيط السور', 'Total fence length') : t('طول الحيطة', 'طول الجدار', 'Wall length'), suffix: m),
          _num('h', t('الارتفاع', 'الارتفاع', 'Height'), suffix: m),
          Text(t('الفتحات (بتتخصم)', 'الفتحات (تُخصم)', 'Openings (subtracted)'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _num('doors', mode == 'fence' ? t('بوابات', 'بوابات', 'Gates') : t('أبواب', 'أبواب', 'Doors'), decimal: false)),
            const SizedBox(width: 8),
            Expanded(child: _num('dw', t('العرض', 'العرض', 'Width'), suffix: m)),
            const SizedBox(width: 8),
            Expanded(child: _num('dh', t('الطول', 'الارتفاع', 'Height'), suffix: m)),
          ]),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _num('wins', t('شبابيك', 'نوافذ', 'Windows'), decimal: false)),
            const SizedBox(width: 8),
            Expanded(child: _num('ww', t('العرض', 'العرض', 'Width'), suffix: m)),
            const SizedBox(width: 8),
            Expanded(child: _num('wh', t('الطول', 'الارتفاع', 'Height'), suffix: m)),
          ]),
          _num('other', t('فتحات تانية', 'فتحات أخرى', 'Other openings'), suffix: m2),
          const SizedBox(height: 4),
          Text(t('نوع الطوب', 'نوع الطوب', 'Brick type'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          HSeg<String>(brick, [('red', t('طوب أحمر', 'طوب أحمر', 'Red brick')), ('block', t('بلك', 'بلوك', 'Block')), ('custom', t('مقاس تاني', 'مقاس مخصص', 'Custom'))], (v) {
            brick = v;
            _save();
          }),
          if (brick == 'custom')
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _num('bl', t('الطول', 'الطول', 'Length'), suffix: 'cm')),
              const SizedBox(width: 8),
              Expanded(child: _num('bw', t('العرض', 'العرض', 'Width'), suffix: 'cm')),
              const SizedBox(width: 8),
              Expanded(child: _num('bh', t('السُمك', 'الارتفاع', 'Height'), suffix: 'cm')),
            ])
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(brick == 'red' ? '22 × 10.5 × 6.5 cm' : '40 × 20 × 20 cm', style: const TextStyle(fontSize: 12.5)),
            ),
          if (brick != 'block')
            HSeg<String>(bond, [('half', t('نص طوبة', 'نصف طوبة', 'Half brick')), ('full', t('طوبة كاملة', 'طوبة كاملة', 'One brick'))], (v) {
              bond = v;
              _save();
            }),
          Pair(_num('joint', t('سُمك اللحام', 'سُمك الوصلة', 'Mortar joint'), suffix: 'cm'), _num('waste', t('الهالك', 'نسبة الهدر', 'Waste'), suffix: '%')),
          Text(t('خلطة المونة (أسمنت:رملة)', 'نسبة المونة (إسمنت:رمل)', 'Mortar mix (cement:sand)'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          HSeg<double>(ratio, const [(4, '1 : 4'), (6, '1 : 6')], (v) {
            ratio = v;
            _save();
          }),
          const Divider(),
          QtyRow(t('المساحة الكلية', 'المساحة الإجمالية', 'Gross area'), '${fmt(gross, 2)} $m2', icon: Icons.square_foot_rounded),
          QtyRow(t('الفتحات', 'الفتحات', 'Openings'), '− ${fmt(math.min(openings, gross), 2)} $m2', icon: Icons.door_front_door_rounded),
          QtyRow(t('صافي مساحة الحيطة', 'صافي مساحة الجدار', 'Net wall area'), '${fmt(net, 2)} $m2', icon: Icons.crop_square_rounded, color: SD.green),
          QtyRow(t('سُمك الحيطة', 'سُمك الجدار', 'Wall thickness'), '${fmt(thick * 100, 1)} cm', icon: Icons.width_normal_rounded),
          QtyRow('$unitName / $m2', fmt(perM2, 1), icon: Icons.grid_on_rounded),
          QtyRow('${t('عدد $plural', 'عدد $plural', 'Number of $unitName')} (+${fmt(f.n('waste'), 0)}%)', fmt(unitsW, 0), cost: money(unitsW * pb), icon: Icons.view_module_rounded, color: SD.henna),
          QtyRow(t('مونة مبلولة', 'حجم المونة الرطب', 'Wet mortar'), '${fmt(wetMortar, 3)} $m3', icon: Icons.water_drop_rounded),
          QtyRow(t('أسمنت المونة', 'إسمنت المونة', 'Mortar cement'), '${fmt(wm.bags, 1)} $bagsTxt (${fmt(wm.cementKg, 0)} kg)', icon: Icons.inventory_rounded),
          QtyRow(t('رملة المونة', 'رمل المونة', 'Mortar sand'), '${fmt(wm.sandM3, 2)} $m3', icon: Icons.landscape_rounded),
          if (brick == 'block')
            NoteBox(t('البلك المجوّف بياخد مونة أقل من الحساب دا (الحساب على أساس بلك مصمت).', 'البلوك المفرّغ يحتاج مونة أقل من هذا الحساب (المحسوب بلوك مصمت).',
                'Hollow blocks need less mortar than shown (calculation assumes solid blocks).')),
        ]),
      ),
      SCard(
        title: t('اللياسة (البياض)', 'اللياسة (المحارة)', 'Plastering'),
        icon: Icons.format_paint_rounded,
        color: SD.sandDeep,
        trailing: Switch(value: plaster, onChanged: (v) {
          plaster = v;
          _save();
        }),
        child: !plaster
            ? Text(t('مقفولة — شغّلها عشان تحسب اللياسة', 'معطّلة — فعّلها لحساب اللياسة', 'Off — switch on to include plastering'), style: const TextStyle(fontSize: 12.5))
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                HSeg<int>(sides, [(1, t('وش واحد', 'وجه واحد', 'One side')), (2, t('الوشين', 'الوجهان', 'Both sides'))], (v) {
                  sides = v;
                  _save();
                }),
                _num('pth', t('سُمك اللياسة', 'سُمك اللياسة', 'Plaster thickness'), suffix: 'cm'),
                QtyRow(t('مساحة اللياسة', 'مساحة اللياسة', 'Plaster area'), '${fmt(pArea, 2)} $m2', icon: Icons.square_foot_rounded),
                QtyRow(t('مونة مبلولة', 'حجم المونة الرطب', 'Wet mortar'), '${fmt(pWet, 3)} $m3', icon: Icons.water_drop_rounded),
                QtyRow('${t('أسمنت', 'إسمنت', 'Cement')} (1:4)', '${fmt(pm.bags, 1)} $bagsTxt (${fmt(pm.cementKg, 0)} kg)', icon: Icons.inventory_rounded),
                QtyRow(t('رملة', 'رمل', 'Sand'), '${fmt(pm.sandM3, 2)} $m3', icon: Icons.landscape_rounded),
              ]),
      ),
      SCard(
        title: t('السقف/البلاطة', 'البلاطة الخرسانية', 'Concrete slab'),
        icon: Icons.layers_rounded,
        color: SD.nile,
        trailing: Switch(value: slab, onChanged: (v) {
          slab = v;
          _save();
        }),
        child: !slab
            ? Text(t('مقفولة — شغّلها عشان تحسب السقف', 'معطّلة — فعّلها لحساب البلاطة', 'Off — switch on to include a slab'), style: const TextStyle(fontSize: 12.5))
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Pair(_num('sl', t('الطول', 'الطول', 'Length'), suffix: m), _num('sw', t('العرض', 'العرض', 'Width'), suffix: m)),
                Pair(_num('st', t('السُمك', 'السُمك', 'Thickness'), suffix: 'cm'), _num('steel', t('سيخ لكل م³', 'حديد لكل م³', 'Steel per m³'), suffix: 'kg')),
                HSeg<String>(mix, [('124', '1 : 2 : 4'), ('1153', '1 : 1.5 : 3')], (v) {
                  mix = v;
                  _save();
                }),
                QtyRow(t('حجم الخرسانة', 'حجم الخرسانة', 'Concrete volume'), '${fmt(sVol, 2)} $m3', icon: Icons.view_in_ar_rounded, color: SD.nile),
                QtyRow(t('الحجم الجاف (× 1.54)', 'الحجم الجاف (× 1.54)', 'Dry volume (× 1.54)'), '${fmt(sVol * _dryConcrete, 2)} $m3', icon: Icons.calculate_rounded),
                QtyRow(t('أسمنت', 'إسمنت', 'Cement'), '${fmt(sm.bags, 1)} $bagsTxt (${fmt(sm.cementKg, 0)} kg)', icon: Icons.inventory_rounded),
                QtyRow(t('رملة', 'رمل', 'Sand'), '${fmt(sm.sandM3, 2)} $m3', icon: Icons.landscape_rounded),
                QtyRow(t('حصى (خرصانة)', 'حصى', 'Gravel'), '${fmt(sm.gravelM3, 2)} $m3', icon: Icons.grain_rounded),
                QtyRow(t('سيخ (حديد)', 'حديد تسليح', 'Reinforcement steel'), '${fmt(steelKg, 0)} kg (${fmt(steelKg / 1000, 2)} t)', icon: Icons.linear_scale_rounded),
                NoteBox(t('كمية السيخ بتختلف حسب التصميم (عادةً 80–100 كجم للمتر المكعب في البلاطات) — التصميم الإنشائي عند المهندس.',
                    'كمية الحديد تختلف بحسب التصميم (عادةً 80–100 كجم/م³ للبلاطات) — التصميم الإنشائي يحدده المهندس.',
                    'Steel depends on the design (typically 80–100 kg/m³ for slabs) — the structural engineer decides.')),
              ]),
      ),
      SCard(
        title: t('الأسعار (اختياري)', 'الأسعار (اختياري)', 'Prices (optional)'),
        icon: Icons.sell_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CurrencyPicker(t('العملة', 'العملة', 'Currency'), cur, (v) {
            cur = v;
            _save();
          }),
          const SizedBox(height: 10),
          Pair(_num('pBrick', '${t('سعر ال', 'سعر ال', 'Price per ')}${brick == 'block' ? t('بلكة', 'بلوكة', 'block') : t('طوبة', 'طوبة', 'brick')}', suffix: sym),
              _num('pCement', t('شوال الأسمنت', 'كيس الإسمنت', 'Cement bag'), suffix: sym)),
          Pair(_num('pSand', t('متر الرملة', 'م³ رمل', 'Sand per m³'), suffix: sym), _num('pGravel', t('متر الحصى', 'م³ حصى', 'Gravel per m³'), suffix: sym)),
          _num('pSteel', t('طن السيخ', 'طن الحديد', 'Steel per ton'), suffix: sym),
        ]),
      ),
      SCard(
        title: t('الجملة', 'الإجمالي', 'Totals'),
        icon: Icons.summarize_rounded,
        color: SD.green,
        child: Column(children: [
          QtyRow(unitName, fmt(unitsW, 0), cost: money(cBricks), icon: Icons.view_module_rounded, color: SD.henna),
          QtyRow('${t('أسمنت', 'إسمنت', 'Cement')} (50 kg)', '${fmt(totalBags.ceil(), 0)} $bagsTxt', cost: money(cCement), icon: Icons.inventory_rounded),
          QtyRow(t('رملة', 'رمل', 'Sand'), '${fmt(totalSand, 2)} $m3', cost: money(cSand), icon: Icons.landscape_rounded),
          if (slab) QtyRow(t('حصى', 'حصى', 'Gravel'), '${fmt(totalGravel, 2)} $m3', cost: money(cGravel), icon: Icons.grain_rounded),
          if (slab) QtyRow(t('سيخ', 'حديد', 'Steel'), '${fmt(totalSteel, 0)} kg', cost: money(cSteel), icon: Icons.linear_scale_rounded),
          if (cost > 0) InfoRow(t('التكلفة التقريبية', 'التكلفة التقريبية', 'Approximate cost'), '${fmt(cost, 0)} $sym', icon: Icons.payments_rounded, valueColor: SD.green),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 10),
      NoteBox(
        t('دا تقدير تقريبي بالمعادلات الهندسية المعروفة (معامل جاف 1.33 للمونة و1.54 للخرسانة، كثافة الأسمنت 1440 كجم/م³). الكميات الحقيقية بتفرق حسب الطوب والصنعة — أكّد مع مهندس قبل ما تشتري.',
            'هذا تقدير تقريبي وفق معادلات الحصر المعتادة (معامل جاف 1.33 للمونة و1.54 للخرسانة، كثافة الإسمنت 1440 كجم/م³). تختلف الكميات الفعلية بحسب جودة الطوب والتنفيذ — راجع مهندسًا قبل الشراء.',
            'Approximate estimate using standard quantity formulas (dry factor 1.33 for mortar, 1.54 for concrete, cement density 1440 kg/m³). Actual quantities vary with brick quality and workmanship — confirm with an engineer before buying.'),
        kind: NoteKind.warn,
      ),
    ]);
  }
}
