import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'money_common.dart';

const _ounce = 31.1035;
const _karats = [24, 22, 21, 18];

String get _sdg => tr('ج.س', 'SDG');
String _guineaL() => t('الجنيه الدهب (8 جرام عيار 21)', 'الجنيه الذهب (8 جرامات عيار 21)', 'Gold guinea (8 g of 21K)');

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
          t('🪙 أسعار الدهب (حسب سعر عيار 21 المُدخل)', '🪙 أسعار الذهب (حسب سعر عيار 21 المُدخل)', '🪙 Gold prices (based on the entered 21K price)'),
          for (final k in _karats) tr('عيار $k: ${fmt(pk(k), 0)} ج.س للجرام', '${k}K: ${fmt(pk(k), 0)} SDG per gram'),
          '${tr('الأوقية (24)', 'Ounce (24K)')}: ${fmt(ounce, 0)} $_sdg ≈ ${fmt(ounce * toUsd)} \$',
          '${_guineaL()}: ${fmt(guinea, 0)} $_sdg',
          '${tr('نصاب الزكاة (85 جرام عيار 24)', 'Zakat nisab (85 g of 24K)')}: ${fmt(nisab, 0)} $_sdg',
          if (w > 0) tr('قطعة ${fmt(w)} جرام عيار $_k: ${fmt(piece, 0)} ج.س (منها مصنعية ${fmt(work, 0)})', 'Piece of ${fmt(w)} g ${_k}K: ${fmt(piece, 0)} SDG (incl. ${fmt(work, 0)} workmanship)'),
        ].join('\n');

    return ToolList(children: [
      SCard(
        title: tr('سعر جرام عيار 21 في السوق', 'Market price of 21K per gram'),
        icon: Icons.diamond_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField(tr('سعر الجرام عيار 21 بالجنيه', '21K price per gram (SDG)'), _p21, suffix: _sdg, hint: t('أكتب سعر اليوم من سوق الدهب', 'اكتب سعر اليوم من سوق الذهب', 'Enter today\'s price from the gold market'), onChanged: (v) {
            s.setData('gold_p21', v);
            setState(() {});
          }),
          NoteBox(t('السعر بتكتبو إنت من الصاغة (سوق الدهب في مدينتك) — وبنحفظو ليك للمرة الجاية. باقي العيارات محسوبة منو بالنسبة.', 'أنت تُدخل السعر من الصاغة (سوق الذهب في مدينتك) — ونحفظه لك للمرة القادمة. بقية العيارات محسوبة منه بالتناسب.', 'You enter the price from your local goldsmiths — we keep it for next time. Other karats are derived from it proportionally.'),
              kind: NoteKind.info),
        ]),
      ),
      if (!has)
        NoteBox(t('يلا أكتب سعر جرام عيار 21 فوق عشان نطلّع ليك كل الحسابات.', 'اكتب سعر جرام عيار 21 أعلاه لتظهر لك كل الحسابات.', 'Enter the 21K gram price above to see all calculations.'), kind: NoteKind.tip)
      else ...[
        ResultHero(
          label: tr('جرام عيار 21', '1 gram of 21K'),
          value: '${fmt(p21, 0)} $_sdg',
          sub: '≈ ${fmt(p21 * toUsd)} \$ • ${t('الجنيه الدهب', 'الجنيه الذهب', 'Gold guinea')} ${fmt(guinea, 0)} $_sdg',
          colors: SD.sunset,
        ),
        SCard(
          title: tr('أسعار العيارات', 'Prices by karat'),
          icon: Icons.workspace_premium_rounded,
          color: SD.gold,
          child: Column(children: [
            StatGrid([
              for (final k in _karats) StatChip(fmt(pk(k), 0), tr('عيار $k / جرام', '${k}K / gram'), color: k == 21 ? SD.henna : SD.gold, icon: Icons.circle_rounded),
            ], columns: 2),
            const SizedBox(height: 10),
            MiniTable(
              [tr('العيار', 'Karat'), tr('النقاوة', 'Purity'), tr('جرام ج.س', 'g (SDG)'), tr('10 جرام', '10 g'), tr('جرام \$', 'g (\$)')],
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
          title: t('وحدات تانية', 'وحدات أخرى', 'Other units'),
          icon: Icons.scale_rounded,
          color: SD.coffee,
          child: Column(children: [
            InfoRow(tr('الأوقية عيار 24 (31.1035 جرام)', 'Ounce 24K (31.1035 g)'), '${fmt(ounce, 0)} $_sdg', icon: Icons.public_rounded, hint: '≈ ${fmt(ounce * toUsd)} \$'),
            InfoRow(tr('الأوقية عيار 21', 'Ounce 21K'), '${fmt(p21 * _ounce, 0)} $_sdg', icon: Icons.public_rounded),
            InfoRow(_guineaL(), '${fmt(guinea, 0)} $_sdg', icon: Icons.toll_rounded, hint: '≈ ${fmt(guinea * toUsd)} \$'),
            InfoRow(t('نص جنيه (4 جرام)', 'نصف جنيه (4 جرامات)', 'Half guinea (4 g)'), '${fmt(guinea / 2, 0)} $_sdg', icon: Icons.toll_rounded),
            InfoRow(t('ربع جنيه (2 جرام)', 'ربع جنيه (2 جرام)', 'Quarter guinea (2 g)'), '${fmt(guinea / 4, 0)} $_sdg', icon: Icons.toll_rounded),
            InfoRow(tr('الكيلو عيار 24', '1 kg of 24K'), '${fmt(p24 * 1000, 0)} $_sdg', icon: Icons.inventory_2_rounded),
            InfoRow(tr('بالدولار: جرام 24', 'In USD: 1 g 24K'), '${fmt(p24 * toUsd)} \$', icon: Icons.attach_money_rounded,
                hint: s.useParallel && s.sdgParallel != null ? tr('بالسعر الموازي', 'at parallel rate') : tr('بالسعر الرسمي', 'at official rate')),
          ]),
        ),
        SCard(
          title: t('قيمة قطعة دهب', 'قيمة قطعة ذهب', 'Value of a gold piece'),
          icon: Icons.auto_awesome_rounded,
          color: SD.henna,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: NumField(tr('الوزن', 'Weight'), _w, suffix: tr('جرام', 'g'), onChanged: (v) {
                s.setData('gold_weight', v);
                setState(() {});
              })),
              const SizedBox(width: 10),
              Expanded(child: NumField(tr('مصنعية الجرام', 'Workmanship / gram'), _mus, suffix: _sdg, onChanged: (v) {
                s.setData('gold_mus', v);
                setState(() {});
              })),
            ]),
            ChoiceRow<int>([for (final k in _karats) (k, tr('عيار $k', '${k}K'))], _k, (v) {
              s.setData('gold_k', v);
              setState(() => _k = v);
            }, color: SD.henna),
            InfoRow(t('قيمة الدهب الخام', 'قيمة الذهب الخام', 'Raw gold value'), '${fmt(metal, 0)} $_sdg', icon: Icons.diamond_outlined),
            InfoRow(tr('المصنعية', 'Workmanship'), '${fmt(work, 0)} $_sdg', icon: Icons.handyman_rounded,
                hint: metal == 0 ? null : t('يعني ${fmt(work / metal * 100, 1)}% فوق سعر الدهب', 'أي ${fmt(work / metal * 100, 1)}% فوق سعر الذهب', 'i.e. ${fmt(work / metal * 100, 1)}% above the gold price')),
            InfoRow(tr('السعر الكلي للشراء', 'Total purchase price'), '${fmt(piece, 0)} $_sdg', icon: Icons.shopping_bag_rounded, valueColor: SD.henna),
            InfoRow(t('لو بعتها (بدون مصنعية غالبًا)', 'عند البيع (غالبًا بلا مصنعية)', 'If you sell it (usually no workmanship)'), '${fmt(metal, 0)} $_sdg', icon: Icons.sell_rounded),
            InfoRow(tr('نقاوتها', 'Purity'), t('${fmt(_k / 24 * 100, 1)}% • فيها ${fmt(pureInPiece, 2)} جرام دهب صافي', '${fmt(_k / 24 * 100, 1)}% • تحوي ${fmt(pureInPiece, 2)} جرام ذهب خالص', '${fmt(_k / 24 * 100, 1)}% • contains ${fmt(pureInPiece, 2)} g pure gold'), icon: Icons.science_rounded),
            InfoRow(tr('يعادل', 'Equals'), t('${fmt(w * _k / 21 / 8, 2)} جنيه دهب', '${fmt(w * _k / 21 / 8, 2)} جنيه ذهب', '${fmt(w * _k / 21 / 8, 2)} gold guineas'), icon: Icons.toll_rounded),
            InfoRow(tr('بالدولار', 'In USD'), '${fmt(piece * toUsd)} \$', icon: Icons.attach_money_rounded),
          ]),
        ),
        SCard(
          title: tr('نصاب الزكاة', 'Zakat nisab'),
          icon: Icons.volunteer_activism_rounded,
          color: SD.green,
          child: Column(children: [
            InfoRow(tr('النصاب: 85 جرام عيار 24', 'Nisab: 85 g of 24K'), '${fmt(nisab, 0)} $_sdg', icon: Icons.verified_rounded, valueColor: SD.green),
            InfoRow(tr('يعادل بعيار 21', 'Equivalent in 21K'), '${fmt(85 * 24 / 21, 2)} ${tr('جرام', 'g')}', icon: Icons.swap_vert_rounded),
            InfoRow(tr('يعادل بعيار 18', 'Equivalent in 18K'), '${fmt(85 * 24 / 18, 2)} ${tr('جرام', 'g')}', icon: Icons.swap_vert_rounded),
            InfoRow(t('زكاة قطعتك لو بلغت النصاب (2.5%)', 'زكاة قطعتك إن بلغت النصاب (2.5%)', 'Zakat on your piece if nisab reached (2.5%)'), '${fmt(piece == 0 ? 0 : metal * .025, 0)} $_sdg', icon: Icons.percent_rounded,
                hint: pureInPiece >= 85 ? t('قطعتك براها بلغت النصاب', 'قطعتك وحدها بلغت النصاب', 'Your piece alone reaches nisab') : t('قطعتك براها أقل من النصاب (تُضم لباقي مالك)', 'قطعتك وحدها دون النصاب (تُضم إلى بقية مالك)', 'Your piece alone is below nisab (add it to your other wealth)')),
          ]),
        ),
        ShareBar(summary),
        const SizedBox(height: 12),
        NoteBox(t('الأسعار محسوبة بالنسبة من عيار 21 والسوق الفعلي ممكن يفرق شوية. زكاة دهب الزينة فيها خلاف بين العلماء — اسأل أهل العلم أو ديوان الزكاة.', 'الأسعار محسوبة بالتناسب من عيار 21 وقد يختلف السوق الفعلي قليلًا. في زكاة ذهب الزينة خلاف بين العلماء — اسأل أهل العلم أو جهة الزكاة.', 'Prices are derived proportionally from 21K; the real market may differ slightly. Zakat on worn jewellery is debated among scholars — ask a scholar or your zakat authority.'),
            kind: NoteKind.warn),
      ],
    ]);
  }
}
