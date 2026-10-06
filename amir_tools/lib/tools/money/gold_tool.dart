import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'money_common.dart';

const _ounce = 31.1035;
const _karats = [24, 22, 21, 18];

class GoldTool extends StatefulWidget {
  const GoldTool({super.key});
  @override
  State<GoldTool> createState() => _GoldToolState();
}

class _GoldToolState extends State<GoldTool> {
  late final TextEditingController _p21, _w, _mus;
  int _k = 21;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _p21 = TextEditingController(text: s.getData<String>('gold_p21') ?? '');
    _w = TextEditingController(text: s.getData<String>('gold_weight') ?? '10');
    _mus = TextEditingController(text: s.getData<String>('gold_mus') ?? '0');
    _k = s.getData<int>('gold_k') ?? 21;
  }

  @override
  void dispose() {
    _p21.dispose();
    _w.dispose();
    _mus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p21 = parseNum(_p21.text);
    double pk(int k) => p21 * k / 21;
    final toUsd = s.rate('SDG', 'USD');
    final p24 = pk(24);
    final ounce = p24 * _ounce;
    final guinea = 8 * p21;
    final w = parseNum(_w.text), mus = parseNum(_mus.text);
    final metal = w * pk(_k), work = w * mus, piece = metal + work;
    final nisab = 85 * p24;
    final pureInPiece = w * _k / 24;
    final has = p21 > 0;

    String summary() => [
          '🪙 أسعار الدهب (حسب سعر عيار 21 المُدخل)',
          for (final k in _karats) 'عيار $k: ${fmt(pk(k), 0)} ج.س للجرام',
          'الأوقية (24): ${fmt(ounce, 0)} ج.س ≈ ${fmt(ounce * toUsd)} \$',
          'الجنيه الدهب (8 جرام عيار 21): ${fmt(guinea, 0)} ج.س',
          'نصاب الزكاة (85 جرام عيار 24): ${fmt(nisab, 0)} ج.س',
          if (w > 0) 'قطعة ${fmt(w)} جرام عيار $_k: ${fmt(piece, 0)} ج.س (منها مصنعية ${fmt(work, 0)})',
        ].join('\n');

    return ToolList(children: [
      SCard(
        title: 'سعر جرام عيار 21 في السوق',
        icon: Icons.diamond_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField('سعر الجرام عيار 21 بالجنيه', _p21, suffix: 'ج.س', hint: 'أكتب سعر اليوم من سوق الدهب', onChanged: (v) {
            s.setData('gold_p21', v);
            setState(() {});
          }),
          const NoteBox('السعر بتكتبو إنت من الصاغة (سوق أم درمان ولا السوق العربي…) — وبنحفظو ليك للمرة الجاية. باقي العيارات محسوبة منو بالنسبة.',
              kind: NoteKind.info),
        ]),
      ),
      if (!has)
        const NoteBox('يلا أكتب سعر جرام عيار 21 فوق عشان نطلّع ليك كل الحسابات.', kind: NoteKind.tip)
      else ...[
        ResultHero(
          label: 'جرام عيار 21',
          value: '${fmt(p21, 0)} ج.س',
          sub: '≈ ${fmt(p21 * toUsd)} \$ • الجنيه الدهب ${fmt(guinea, 0)} ج.س',
          colors: SD.sunset,
        ),
        SCard(
          title: 'أسعار العيارات',
          icon: Icons.workspace_premium_rounded,
          color: SD.gold,
          child: Column(children: [
            StatGrid([
              for (final k in _karats) StatChip(fmt(pk(k), 0), 'عيار $k / جرام', color: k == 21 ? SD.henna : SD.gold, icon: Icons.circle_rounded),
            ], columns: 2),
            const SizedBox(height: 10),
            MiniTable(
              ['العيار', 'النقاوة', 'جرام ج.س', '10 جرام', 'جرام \$'],
              [
                for (final k in _karats)
                  ['$k', '${fmt(k / 24 * 100, 1)}% (${fmt(k / 24 * 1000, 0)})', fmt(pk(k), 0), fmt(pk(k) * 10, 0), fmt(pk(k) * toUsd)],
              ],
              color: SD.gold,
              highlight: 2,
            ),
          ]),
        ),
        SCard(
          title: 'وحدات تانية',
          icon: Icons.scale_rounded,
          color: SD.coffee,
          child: Column(children: [
            InfoRow('الأوقية عيار 24 (31.1035 جرام)', '${fmt(ounce, 0)} ج.س', icon: Icons.public_rounded, hint: '≈ ${fmt(ounce * toUsd)} دولار'),
            InfoRow('الأوقية عيار 21', '${fmt(p21 * _ounce, 0)} ج.س', icon: Icons.public_rounded),
            InfoRow('الجنيه الدهب (8 جرام عيار 21)', '${fmt(guinea, 0)} ج.س', icon: Icons.toll_rounded, hint: '≈ ${fmt(guinea * toUsd)} دولار'),
            InfoRow('نص جنيه (4 جرام)', '${fmt(guinea / 2, 0)} ج.س', icon: Icons.toll_rounded),
            InfoRow('ربع جنيه (2 جرام)', '${fmt(guinea / 4, 0)} ج.س', icon: Icons.toll_rounded),
            InfoRow('الكيلو عيار 24', '${fmt(p24 * 1000, 0)} ج.س', icon: Icons.inventory_2_rounded),
            InfoRow('بالدولار: جرام 24', '${fmt(p24 * toUsd)} \$', icon: Icons.attach_money_rounded,
                hint: s.useParallel && s.sdgParallel != null ? 'بالسعر الموازي' : 'بالسعر الرسمي'),
          ]),
        ),
        SCard(
          title: 'قيمة قطعة دهب',
          icon: Icons.auto_awesome_rounded,
          color: SD.henna,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: NumField('الوزن', _w, suffix: 'جرام', onChanged: (v) {
                s.setData('gold_weight', v);
                setState(() {});
              })),
              const SizedBox(width: 10),
              Expanded(child: NumField('مصنعية الجرام', _mus, suffix: 'ج.س', onChanged: (v) {
                s.setData('gold_mus', v);
                setState(() {});
              })),
            ]),
            ChoiceRow<int>([for (final k in _karats) (k, 'عيار $k')], _k, (v) {
              s.setData('gold_k', v);
              setState(() => _k = v);
            }, color: SD.henna),
            InfoRow('قيمة الدهب الخام', '${fmt(metal, 0)} ج.س', icon: Icons.diamond_outlined),
            InfoRow('المصنعية', '${fmt(work, 0)} ج.س', icon: Icons.handyman_rounded,
                hint: metal == 0 ? null : 'يعني ${fmt(work / metal * 100, 1)}% فوق سعر الدهب'),
            InfoRow('السعر الكلي للشراء', '${fmt(piece, 0)} ج.س', icon: Icons.shopping_bag_rounded, valueColor: SD.henna),
            InfoRow('لو بعتها (بدون مصنعية غالبًا)', '${fmt(metal, 0)} ج.س', icon: Icons.sell_rounded),
            InfoRow('نقاوتها', '${fmt(_k / 24 * 100, 1)}% • فيها ${fmt(pureInPiece, 2)} جرام دهب صافي', icon: Icons.science_rounded),
            InfoRow('يعادل', '${fmt(w * _k / 21 / 8, 2)} جنيه دهب', icon: Icons.toll_rounded),
            InfoRow('بالدولار', '${fmt(piece * toUsd)} \$', icon: Icons.attach_money_rounded),
          ]),
        ),
        SCard(
          title: 'نصاب الزكاة',
          icon: Icons.volunteer_activism_rounded,
          color: SD.green,
          child: Column(children: [
            InfoRow('النصاب: 85 جرام عيار 24', '${fmt(nisab, 0)} ج.س', icon: Icons.verified_rounded, valueColor: SD.green),
            InfoRow('يعادل بعيار 21', '${fmt(85 * 24 / 21, 2)} جرام', icon: Icons.swap_vert_rounded),
            InfoRow('يعادل بعيار 18', '${fmt(85 * 24 / 18, 2)} جرام', icon: Icons.swap_vert_rounded),
            InfoRow('زكاة قطعتك لو بلغت النصاب (2.5%)', '${fmt(piece == 0 ? 0 : metal * .025, 0)} ج.س', icon: Icons.percent_rounded,
                hint: pureInPiece >= 85 ? 'قطعتك براها بلغت النصاب' : 'قطعتك براها أقل من النصاب (تُضم لباقي مالك)'),
          ]),
        ),
        ShareBar(summary),
        const SizedBox(height: 12),
        const NoteBox('الأسعار محسوبة بالنسبة من عيار 21 والسوق الفعلي ممكن يفرق شوية. زكاة ذهب الزينة فيها خلاف بين العلماء — اسأل أهل العلم أو ديوان الزكاة.',
            kind: NoteKind.warn),
      ],
    ]);
  }
}
