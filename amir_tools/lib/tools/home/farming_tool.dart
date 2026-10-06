import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart' show PickChip;
import '../money/money_common.dart' show CurrencyPicker, curSym;
import 'home_common.dart';

const feddanM2 = 4200.0;
const zakatNisabKg = 653.0;

/// محصول بقيم افتراضية «نموذجية» قابلة للتعديل (ليست مرجعية)
class _Crop {
  final String key, emoji, sd, ar, en;
  final double seed; // كجم تقاوي للفدان
  final double yieldV; // إنتاج الفدان بالوحدة
  final String unit; // sack | kg
  final double sackKg, urea, dap; // أكياس 50 كجم للفدان
  final bool grain; // حبوب قوت (الزكاة فيها محل اتفاق أوسع)
  const _Crop(this.key, this.emoji, this.sd, this.ar, this.en, this.seed, this.yieldV, this.unit, this.sackKg, this.urea, this.dap, this.grain);
  String get name => t(sd, ar, en);
}

const _crops = [
  _Crop('sorghum', '🌾', 'عيش (ذرة)', 'ذرة رفيعة', 'Sorghum', 3, 5, 'sack', 90, 1, 0, true),
  _Crop('millet', '🌿', 'دخن', 'دخن', 'Millet', 2, 3, 'sack', 90, 0, 0, true),
  _Crop('wheat', '🌾', 'قمح', 'قمح', 'Wheat', 50, 12, 'sack', 100, 2, 1, true),
  _Crop('sesame', '🌱', 'سمسم', 'سمسم', 'Sesame', 2, 250, 'kg', 1, 0, 0, false),
  _Crop('groundnut', '🥜', 'فول سوداني', 'فول سوداني', 'Groundnut', 30, 12, 'sack', 45, 0, 1, false),
  _Crop('sunflower', '🌻', 'عباد الشمس', 'عبّاد الشمس', 'Sunflower', 3, 600, 'kg', 1, 1, 1, false),
  _Crop('cotton', '☁️', 'قطن', 'قطن', 'Cotton', 20, 600, 'kg', 1, 2, 1, false),
  _Crop('onion', '🧅', 'بصل', 'بصل', 'Onion', 2, 200, 'sack', 50, 2, 1, false),
  _Crop('tomato', '🍅', 'طماطم', 'طماطم', 'Tomato', 0.15, 8000, 'kg', 1, 2, 1, false),
  _Crop('custom', '✏️', 'محصول تاني', 'محصول آخر', 'Other crop', 0, 0, 'kg', 1, 0, 0, false),
];

_Crop _crop(String? k) => _crops.firstWhere((c) => c.key == k, orElse: () => _crops.first);

class FarmingTool extends StatefulWidget {
  const FarmingTool({super.key});
  @override
  State<FarmingTool> createState() => _FarmingToolState();
}

class _FarmingToolState extends State<FarmingTool> {
  final f = FieldBag('farming_in', {
    'area': '5', 'seed': '3', 'yield': '5', 'sackKg': '90', 'price': '',
    'seedPrice': '', 'urea': '1', 'ureaPrice': '', 'dap': '0', 'dapPrice': '',
    'plough': '', 'labor': '', 'irrig': '', 'harvest': '', 'other': '',
  });
  String crop = 'sorghum', areaUnit = 'f', unit = 'sack', water = 'rain', cur = 'SDG';

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    f.load(s);
    final m = s.getData<Map>('farming_in') ?? const {};
    crop = (m['_crop'] as String?) ?? crop;
    areaUnit = (m['_au'] as String?) ?? areaUnit;
    unit = (m['_unit'] as String?) ?? unit;
    water = (m['_water'] as String?) ?? water;
    cur = (m['_cur'] as String?) ?? cur;
  }

  @override
  void dispose() {
    f.dispose();
    super.dispose();
  }

  void _save() {
    f.save(context.read<AppState>(), {'_crop': crop, '_au': areaUnit, '_unit': unit, '_water': water, '_cur': cur});
    setState(() {});
  }

  void _pickCrop(_Crop c) {
    crop = c.key;
    String n(double v) => v == 0 ? '' : fmt(v, 2).replaceAll(',', '');
    f.set('seed', n(c.seed));
    f.set('yield', n(c.yieldV));
    f.set('sackKg', n(c.sackKg));
    f.set('urea', fmt(c.urea, 2));
    f.set('dap', fmt(c.dap, 2));
    unit = c.unit;
    _save();
  }

  Widget _num(String key, String label, {String? suffix, String? hint}) => NumField(label, f[key], suffix: suffix, hint: hint, onChanged: (_) => _save());

  @override
  Widget build(BuildContext context) {
    final c = _crop(crop);
    final sym = curSym(cur);
    final fdn = t('فدان', 'فدان', 'feddan');
    final unitName = unit == 'sack' ? t('جوال', 'جوال', 'sack') : t('كيلو', 'كجم', 'kg');

    final areaIn = f.n('area');
    final feddans = areaUnit == 'f' ? areaIn : areaIn * 10000 / feddanM2;
    final sackKg = unit == 'sack' ? f.n('sackKg', 1) : 1.0;

    final seedKg = feddans * f.n('seed');
    final seedCost = seedKg * f.n('seedPrice');
    final ureaBags = feddans * f.n('urea'), dapBags = feddans * f.n('dap');
    final fertCost = ureaBags * f.n('ureaPrice') + dapBags * f.n('dapPrice');
    final opsPerF = f.n('plough') + f.n('labor') + f.n('irrig') + f.n('harvest');
    final opsCost = opsPerF * feddans;
    final otherCost = f.n('other');
    final totalCost = seedCost + fertCost + opsCost + otherCost;

    final yieldUnits = feddans * f.n('yield');
    final yieldKg = yieldUnits * sackKg;
    final price = f.n('price');
    final revenue = yieldUnits * price;
    final profit = revenue - totalCost;
    final perF = feddans > 0 ? profit / feddans : 0.0;
    final breakEven = yieldUnits > 0 ? totalCost / yieldUnits : double.nan;

    final rate = switch (water) { 'rain' => .10, 'irr' => .05, _ => .075 };
    final zakatDue = yieldKg >= zakatNisabKg;
    final zakatKg = zakatDue ? yieldKg * rate : 0.0;
    final zakatUnits = zakatDue ? yieldUnits * rate : 0.0;

    String summary() {
      final b = StringBuffer('${c.emoji} ${t('حساب زراعة', 'حساب زراعة', 'Farm budget')}: ${c.name}\n');
      b.writeln('${t('المساحة', 'المساحة', 'Area')}: ${fmt(feddans, 2)} $fdn');
      b.writeln('${t('التكلفة', 'إجمالي التكاليف', 'Total cost')}: ${fmt(totalCost, 0)} $sym');
      b.writeln('${t('الإنتاج المتوقع', 'الإنتاج المتوقع', 'Expected yield')}: ${fmt(yieldUnits, 1)} $unitName');
      if (revenue > 0) {
        b.writeln('${t('الدخل', 'الإيراد', 'Revenue')}: ${fmt(revenue, 0)} $sym');
        b.writeln('${t('الربح', 'صافي الربح', 'Profit')}: ${fmt(profit, 0)} $sym');
      }
      if (breakEven.isFinite) b.writeln('${t('سعر التعادل', 'سعر التعادل', 'Break-even price')}: ${fmt(breakEven, 0)} $sym / $unitName');
      return b.toString().trim();
    }

    return ToolList(children: [
      ResultHero(
        label: revenue > 0 ? (profit >= 0 ? t('الربح المتوقع', 'الربح المتوقع', 'Expected profit') : t('الخسارة المتوقعة', 'الخسارة المتوقعة', 'Expected loss')) : t('التكلفة الكلية', 'إجمالي التكاليف', 'Total cost'),
        value: revenue > 0 ? '${fmt(profit.abs(), 0)} $sym' : '${fmt(totalCost, 0)} $sym',
        sub: [
          '${c.emoji} ${c.name}',
          '${fmt(feddans, 2)} $fdn',
          '${fmt(yieldUnits, 1)} $unitName',
        ].join(' · '),
        colors: revenue > 0 && profit < 0 ? const [SD.red, SD.henna, SD.brownDeep] : const [SD.green, Color(0xFF3E6B1F), SD.brownDeep],
      ),
      SCard(
        title: t('المحصول والمساحة', 'المحصول والمساحة', 'Crop & area'),
        icon: Icons.agriculture_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final x in _crops) PickChip('${x.emoji} ${x.name}', crop == x.key, () => _pickCrop(x), color: SD.green),
          ]),
          const SizedBox(height: 12),
          HSeg<String>(areaUnit, [('f', t('فدان', 'فدان', 'Feddan')), ('h', t('هكتار', 'هكتار', 'Hectare'))], (v) {
            areaUnit = v;
            _save();
          }),
          _num('area', t('المساحة', 'المساحة', 'Area'), suffix: areaUnit == 'f' ? fdn : t('هكتار', 'هكتار', 'ha')),
          Text(
            '= ${fmt(feddans, 2)} $fdn = ${fmt(feddans * feddanM2, 0)} ${t('م²', 'م²', 'm²')}  (${t('الفدان = 4200 م²', 'الفدان = 4200 م²', '1 feddan = 4,200 m²')})',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          _num('seed', t('التقاوي (كيلو للفدان)', 'معدل البذار (كجم/فدان)', 'Seed rate (kg/feddan)'), suffix: 'kg'),
          HSeg<String>(unit, [('sack', t('بالجوال', 'بالجوال', 'In sacks')), ('kg', t('بالكيلو', 'بالكيلوغرام', 'In kg'))], (v) {
            unit = v;
            _save();
          }),
          if (unit == 'sack')
            Pair(_num('yield', t('إنتاج الفدان', 'إنتاجية الفدان', 'Yield / feddan'), suffix: unitName), _num('sackKg', t('وزن الجوال', 'وزن الجوال', 'Sack weight'), suffix: 'kg'))
          else
            _num('yield', t('إنتاج الفدان', 'إنتاجية الفدان', 'Yield / feddan'), suffix: 'kg'),
          _num('price', '${t('سعر ال', 'سعر ال', 'Price per ')}$unitName', suffix: sym),
          NoteBox(
            t('الأرقام الافتراضية قيم نموذجية تقريبية بس وبتفرق كتير حسب المنطقة والري والبذرة والموسم — عدّلها على حسب واقعك أو كلام المرشد الزراعي.',
                'القيم الافتراضية تقريبية نموذجية وليست مرجعية، وتختلف كثيرًا بحسب المنطقة والري والصنف والموسم — عدّلها وفق واقعك أو توصية المرشد الزراعي.',
                'Defaults are rough typical values, not authoritative — they vary widely by region, irrigation, variety and season. Edit them to match your farm or your extension officer\'s advice.'),
            kind: NoteKind.warn,
          ),
        ]),
      ),
      SCard(
        title: t('التكاليف', 'التكاليف', 'Costs'),
        icon: Icons.payments_rounded,
        color: SD.orange,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CurrencyPicker(t('العملة', 'العملة', 'Currency'), cur, (v) {
            cur = v;
            _save();
          }),
          const SizedBox(height: 10),
          _num('seedPrice', t('سعر كيلو التقاوي', 'سعر كجم البذور', 'Seed price per kg'), suffix: sym),
          Pair(_num('urea', t('يوريا (شوال/فدان)', 'يوريا (كيس/فدان)', 'Urea (bags/fd)')), _num('ureaPrice', t('سعر شوال اليوريا', 'سعر كيس اليوريا', 'Urea bag price'), suffix: sym)),
          Pair(_num('dap', t('داب (شوال/فدان)', 'داب (كيس/فدان)', 'DAP (bags/fd)')), _num('dapPrice', t('سعر شوال الداب', 'سعر كيس الداب', 'DAP bag price'), suffix: sym)),
          Text(t('تكاليف الفدان الواحد', 'تكاليف الفدان الواحد', 'Costs per feddan'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Pair(_num('plough', t('الحراتة', 'الحراثة', 'Ploughing'), suffix: sym), _num('labor', t('العمالة', 'العمالة', 'Labor'), suffix: sym)),
          Pair(_num('irrig', t('الري', 'الري', 'Irrigation'), suffix: sym), _num('harvest', t('الحصاد', 'الحصاد', 'Harvest'), suffix: sym)),
          _num('other', t('مصاريف تانية (جملة)', 'مصروفات أخرى (إجمالي)', 'Other costs (total)'), suffix: sym),
        ]),
      ),
      SCard(
        title: t('النتيجة', 'النتائج', 'Results'),
        icon: Icons.insights_rounded,
        color: SD.teal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          HStats([
            (fmt(totalCost, 0), t('التكلفة ($sym)', 'التكاليف ($sym)', 'Cost ($sym)'), SD.orange),
            (fmt(revenue, 0), t('الدخل ($sym)', 'الإيراد ($sym)', 'Revenue ($sym)'), SD.teal),
            (fmt(profit, 0), t('الربح ($sym)', 'الربح ($sym)', 'Profit ($sym)'), profit < 0 ? SD.red : SD.green),
          ]),
          const SizedBox(height: 8),
          QtyRow(t('التقاوي', 'البذور', 'Seeds'), '${fmt(seedKg, 1)} kg', cost: seedCost > 0 ? '${fmt(seedCost, 0)} $sym' : null, icon: Icons.grass_rounded, color: SD.green),
          QtyRow(t('السماد', 'الأسمدة', 'Fertilizer'), '${fmt(ureaBags, 1)} ${t('يوريا', 'يوريا', 'urea')} + ${fmt(dapBags, 1)} ${t('داب', 'داب', 'DAP')}',
              cost: fertCost > 0 ? '${fmt(fertCost, 0)} $sym' : null, icon: Icons.science_rounded),
          QtyRow(t('العمليات', 'العمليات الزراعية', 'Field operations'), '${fmt(opsCost, 0)} $sym', icon: Icons.agriculture_rounded),
          QtyRow(t('الإنتاج المتوقع', 'الإنتاج المتوقع', 'Expected yield'), '${fmt(yieldUnits, 1)} $unitName', cost: unit == 'sack' ? '${fmt(yieldKg, 0)} kg' : null, icon: Icons.inventory_2_rounded, color: SD.gold),
          InfoRow(t('تكلفة الفدان', 'تكلفة الفدان', 'Cost per feddan'), feddans > 0 ? '${fmt(totalCost / feddans, 0)} $sym' : '—', icon: Icons.crop_square_rounded),
          InfoRow(t('ربح الفدان', 'ربح الفدان', 'Profit per feddan'), revenue > 0 ? '${fmt(perF, 0)} $sym' : '—', icon: Icons.trending_up_rounded, valueColor: revenue > 0 ? (perF < 0 ? SD.red : SD.green) : null),
          InfoRow(t('سعر التعادل', 'سعر التعادل', 'Break-even price'), breakEven.isFinite && totalCost > 0 ? '${fmt(breakEven, 0)} $sym / $unitName' : '—',
              icon: Icons.balance_rounded,
              hint: t('أقل سعر تبيع بيهو من غير خسارة', 'أدنى سعر للبيع دون خسارة', 'Lowest selling price without a loss')),
          if (revenue == 0)
            Text(t('أكتب سعر البيع فوق عشان نحسب الدخل والربح', 'أدخل سعر البيع أعلاه لحساب الإيراد والربح', 'Enter a selling price above to compute revenue and profit'), style: const TextStyle(fontSize: 12)),
        ]),
      ),
      SCard(
        title: t('زكاة الزروع', 'زكاة الزروع والثمار', 'Zakat on crops'),
        icon: Icons.volunteer_activism_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          HSeg<String>(water, [('rain', t('مطري 10%', 'بلا كلفة 10%', 'Rain-fed 10%')), ('irr', t('مروي 5%', 'بكلفة 5%', 'Irrigated 5%')), ('mix', t('نص نص 7.5%', 'مناصفة 7.5%', 'Mixed 7.5%'))], (v) {
            water = v;
            _save();
          }),
          InfoRow(t('الإنتاج بالكيلو', 'الإنتاج بالكجم', 'Yield in kg'), '${fmt(yieldKg, 0)} kg', hint: '${t('النصاب', 'النصاب', 'Nisab')} ≈ ${fmt(zakatNisabKg, 0)} kg'),
          if (zakatDue) ...[
            InfoRow(t('الزكاة', 'مقدار الزكاة', 'Zakat due'), '${fmt(zakatKg, 1)} kg', valueColor: SD.green, icon: Icons.mosque_rounded,
                hint: unit == 'sack' ? '≈ ${fmt(zakatUnits, 2)} $unitName' : null),
            if (price > 0) InfoRow(t('قيمتها تقريبًا', 'قيمتها تقريبًا', 'Approx. value'), '${fmt(zakatUnits * price, 0)} $sym'),
          ] else
            NoteBox(t('الإنتاج أقل من النصاب — ما عليه زكاة زروع.', 'الإنتاج دون النصاب — لا تجب فيه زكاة الزروع.', 'Yield is below the nisab — no crop zakat is due.'), kind: NoteKind.tip),
          if (!c.grain)
            NoteBox(
                t('وجوب الزكاة في ${c.name} فيه خلاف بين المذاهب (الحنفية بيوجبوها في كل ما يُزرع للاستغلال، والجمهور بيخصّوها بالحبوب والثمار المدّخرة). اسأل أهل العلم.',
                    'في وجوب الزكاة في ${c.name} خلاف بين المذاهب؛ فالحنفية يوجبونها في كل ما يُقصد بزراعته الاستغلال، والجمهور يخصّونها بالحبوب والثمار المدّخرة. راجع أهل العلم.',
                    'Whether zakat is due on ${c.name} differs among schools: Hanafis apply it to all produce grown for yield, while the majority limit it to stored grains and fruits. Consult a scholar.'),
                kind: NoteKind.warn),
          NoteBox(
            t('العُشر (10%) لما يكون السقي بالمطر أو بلا كلفة، ونص العُشر (5%) لما يكون بكلفة (طلمبات/شراء موية)، و7.5% لو نص بنص. النصاب خمسة أوسق (حوالي 653 كجم). بتطلع يوم الحصاد على كل المحصول — والتفاصيل اسأل عنها أهل العلم.',
                'العُشر (10%) فيما سُقي بلا كلفة كالمطر، ونصف العُشر (5%) فيما سُقي بكلفة، و7.5% إن سُقي بالطريقتين مناصفة. النصاب خمسة أوسق (نحو 653 كجم)، وتُخرج يوم الحصاد. للتفاصيل راجع أهل العلم.',
                'One-tenth (10%) if watered without cost (rain), half of that (5%) if irrigated at cost, and 7.5% if half-and-half. Nisab is five awsuq (≈ 653 kg), paid at harvest. Consult a scholar for details.'),
          ),
          const Text('﴿وَآتُوا حَقَّهُ يَوْمَ حَصَادِهِ﴾ [الأنعام: 141]', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, height: 1.8)),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 10),
      NoteBox(
        t('دا حساب تقديري للتخطيط بس — الإنتاج والأسعار الحقيقية بتعتمد على المطرة والآفات والسوق.',
            'هذا حساب تقديري للتخطيط فقط؛ الإنتاج والأسعار الفعلية تتأثر بالأمطار والآفات والسوق.',
            'This is a planning estimate only — actual yield and prices depend on rain, pests and the market.'),
      ),
    ]);
  }
}
