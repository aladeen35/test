import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'more_common.dart';

/// وحدات الحجم: (المفتاح، العائلة، المعامل إلى الوحدة الأساسية)
const _units = [('g', 'w', 0.001), ('kg', 'w', 1.0), ('ml', 'v', 0.001), ('l', 'v', 1.0), ('pc', 'p', 1.0)];

String _unitLabel(String u) => switch (u) {
      'g' => tr('جرام', 'g'),
      'kg' => t('كيلو', 'كيلوغرام', 'kg'),
      'ml' => tr('مل', 'ml'),
      'l' => tr('لتر', 'L'),
      _ => t('حبة', 'قطعة', 'piece'),
    };

String _baseLabel(String fam) => switch (fam) {
      'w' => t('الكيلو', 'الكيلوغرام', 'kg'),
      'v' => tr('اللتر', 'L'),
      _ => t('الحبة', 'القطعة', 'piece'),
    };

class _Item {
  final n = TextEditingController(), p = TextEditingController(), s = TextEditingController(), c = TextEditingController();
  String unit = 'kg';
  _Item([Map? j]) {
    if (j != null) {
      n.text = j['n'] ?? '';
      p.text = j['p'] ?? '';
      s.text = j['s'] ?? '';
      c.text = j['c'] ?? '';
      unit = j['u'] ?? 'kg';
    }
  }
  Map<String, dynamic> toJson() => {'n': n.text, 'p': p.text, 's': s.text, 'c': c.text, 'u': unit};
  void dispose() {
    n.dispose();
    p.dispose();
    s.dispose();
    c.dispose();
  }

  String get fam => _units.firstWhere((x) => x.$1 == unit).$2;
  double get factor => _units.firstWhere((x) => x.$1 == unit).$3;
  double get price => parseNum(p.text);
  double get count => parseNum(c.text, 1) <= 0 ? 1 : parseNum(c.text, 1);

  /// الكمية الكلية بالوحدة الأساسية (كجم/لتر/حبة)
  double get qty => parseNum(s.text) * factor * count;
  double? get perUnit => price > 0 && qty > 0 ? price / qty : null;
}

class BestPriceTool extends StatefulWidget {
  const BestPriceTool({super.key});
  @override
  State<BestPriceTool> createState() => _BestPriceToolState();
}

class _BestPriceToolState extends State<BestPriceTool> {
  List<_Item> items = [];
  final needC = TextEditingController();
  String cur = '';

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final saved = s.getData<Map>('best_price');
    if (saved != null) {
      items = List<Map>.from(saved['items'] ?? []).map(_Item.new).toList();
      needC.text = saved['need'] ?? '';
      cur = saved['cur'] ?? '';
    }
    while (items.length < 2) {
      items.add(_Item());
    }
  }

  @override
  void dispose() {
    for (final i in items) {
      i.dispose();
    }
    needC.dispose();
    super.dispose();
  }

  void _save() {
    context.read<AppState>().setData('best_price', {'items': items.map((e) => e.toJson()).toList(), 'need': needC.text, 'cur': cur});
    setState(() {});
  }

  void _example() {
    for (final i in items) {
      i.dispose();
    }
    items = [
      _Item({'n': t('جوال سكر', 'كيس سكر', 'Sugar sack'), 'p': '95000', 's': '50', 'u': 'kg', 'c': '1'}),
      _Item({'n': t('كيلو سكر بالقطاعي', 'كيلو سكر بالتجزئة', 'Sugar by the kilo'), 'p': '2300', 's': '1', 'u': 'kg', 'c': '1'}),
      _Item({'n': t('كيس 10 كيلو', 'كيس 10 كيلو', '10 kg bag'), 'p': '21000', 's': '10', 'u': 'kg', 'c': '1'}),
    ];
    needC.text = '50';
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final valid = <int>[];
    for (var i = 0; i < items.length; i++) {
      if (items[i].perUnit != null) valid.add(i);
    }
    // نقارن داخل كل عائلة وحدات (وزن/حجم/حبات)
    final fams = <String, List<int>>{};
    for (final i in valid) {
      fams.putIfAbsent(items[i].fam, () => []).add(i);
    }
    final best = <String, int>{};
    final worst = <String, int>{};
    fams.forEach((f, l) {
      l.sort((a, b) => items[a].perUnit!.compareTo(items[b].perUnit!));
      best[f] = l.first;
      worst[f] = l.last;
    });
    final mainFam = fams.isEmpty ? null : (fams.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length))).first.key;
    final need = parseNum(needC.text);
    final curTxt = cur.trim().isEmpty ? '' : ' ${cur.trim()}';

    return ToolList(children: [
      if (mainFam != null && fams[mainFam]!.length >= 2)
        Builder(builder: (_) {
          final b = items[best[mainFam]!], w = items[worst[mainFam]!];
          final save = (1 - b.perUnit! / w.perUnit!) * 100;
          return ResultHero(
            label: '🏆 ${t('الأوفر', 'الأوفر', 'Best value')}: ${b.n.text.trim().isEmpty ? '#${best[mainFam]! + 1}' : b.n.text.trim()}',
            value: '${fmt(b.perUnit, 2)}$curTxt',
            sub: '${t('سعر', 'سعر', 'per')} ${_baseLabel(mainFam)} • ${t('أوفر من الأغلى بـ', 'أوفر من الأغلى بنسبة', 'saves vs priciest')} ${fmt(save, 1)}%',
            colors: const [Color(0xFF007229), Color(0xFF0B5C8A), Color(0xFF3A1F0C)],
          );
        })
      else
        ResultHero(
          label: t('أيهما أوفر؟', 'أيهما أوفر؟', 'Which is cheaper?'),
          value: '—',
          sub: t('أكتب السعر والحجم لمنتجين على الأقل', 'أدخل السعر والحجم لمنتجين على الأقل', 'Enter price and size for at least two products'),
        ),
      for (var i = 0; i < items.length; i++) _itemCard(i, best, fams, curTxt),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: items.length >= 6
                ? null
                : () {
                    setState(() => items.add(_Item()..unit = items.last.unit));
                    _save();
                  },
            icon: const Icon(Icons.add_rounded),
            label: Text(t('ضيف منتج', 'أضف منتجًا', 'Add product')),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(onPressed: _example, icon: const Icon(Icons.lightbulb_outline_rounded), label: Text(t('مثال: السكر', 'مثال: السكر', 'Example: sugar'))),
        ),
      ]),
      const SizedBox(height: 14),
      if (mainFam != null && fams[mainFam]!.length >= 2)
        SCard(
          title: t('الترتيب من الأرخص', 'الترتيب من الأرخص', 'Ranking (cheapest first)'),
          icon: Icons.leaderboard_rounded,
          color: SD.green,
          child: Column(children: [
            for (final f in fams.keys)
              for (final (rank, i) in fams[f]!.indexed)
                InfoRow(
                  '${rank + 1}. ${items[i].n.text.trim().isEmpty ? '${t('منتج', 'منتج', 'Product')} ${i + 1}' : items[i].n.text.trim()}',
                  '${fmt(items[i].perUnit, 2)}$curTxt / ${_baseLabel(f)}',
                  icon: rank == 0 ? Icons.emoji_events_rounded : Icons.circle_outlined,
                  valueColor: rank == 0 ? SD.green : null,
                  hint: rank == 0
                      ? t('الأرخص', 'الأرخص', 'Cheapest')
                      : '+${fmt((items[i].perUnit! / items[best[f]!].perUnit! - 1) * 100, 1)}% ${t('أغلى من الأرخص', 'أغلى من الأرخص', 'more than cheapest')}',
                ),
          ]),
        ),
      SCard(
        title: t('محتاج كم؟', 'كم تحتاج؟', 'How much do you need?'),
        icon: Icons.shopping_cart_rounded,
        color: SD.orange,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField('${t('الكمية', 'الكمية', 'Quantity')} (${mainFam == null ? '' : _baseLabel(mainFam)})', needC, onChanged: (_) => _save()),
          TextField(
            controller: TextEditingController(text: cur),
            decoration: InputDecoration(labelText: t('العملة (اختياري)', 'العملة (اختياري)', 'Currency (optional)'), hintText: t('جنيه، ريال…', 'جنيه، ريال…', 'SDG, SAR…')),
            onChanged: (v) {
              cur = v;
              context.read<AppState>().setData('best_price', {'items': items.map((e) => e.toJson()).toList(), 'need': needC.text, 'cur': cur});
            },
            onSubmitted: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          if (need > 0 && mainFam != null)
            for (final i in fams[mainFam]!)
              InfoRow(
                items[i].n.text.trim().isEmpty ? '${t('منتج', 'منتج', 'Product')} ${i + 1}' : items[i].n.text.trim(),
                '${fmt(items[i].perUnit! * need, 0)}$curTxt',
                icon: i == best[mainFam] ? Icons.check_circle_rounded : Icons.shopping_bag_outlined,
                valueColor: i == best[mainFam] ? SD.green : null,
                hint: i == best[mainFam]
                    ? '${t('عدد العبوات', 'عدد العبوات', 'Packs')}: ${fmt(need / items[i].qty, 2)}'
                    : '${t('بتدفع زيادة', 'تدفع زيادة', 'Extra cost')}: ${fmt((items[i].perUnit! - items[best[mainFam]!].perUnit!) * need, 0)}$curTxt • ${t('عدد العبوات', 'عدد العبوات', 'Packs')}: ${fmt(need / items[i].qty, 2)}',
              ),
        ]),
      ),
      if (fams.length > 1)
        NoteBox(t('في منتجات بوحدات ما بتتقارن (وزن مع حجم أو حبات) — قارنّاها كل مجموعة براها.', 'توجد منتجات بوحدات غير قابلة للمقارنة (وزن مع حجم أو قطع) — قورنت كل مجموعة على حدة.',
            'Some products use incomparable units (weight vs volume vs pieces) — each group is compared separately.'), kind: NoteKind.warn),
      NoteBox(
          t('الأرخص للكيلو ما دايمًا الأحسن: شوف الصلاحية، مكان التخزين، وهل حتستهلك الكمية الكبيرة قبل ما تخرب. الشراء بالجملة مع الجيران أو الأهل بيوفّر أكتر.',
              'الأرخص للكيلو ليس الأفضل دائمًا: انتبه للصلاحية ومكان التخزين وهل ستستهلك الكمية الكبيرة قبل أن تفسد. الشراء بالجملة مع الجيران أو الأهل يوفّر أكثر.',
              "Cheapest per kg isn't always best: check expiry, storage, and whether you'll use a bulk amount before it spoils. Buying in bulk with neighbours or family saves more."),
          kind: NoteKind.tip),
      if (valid.length >= 2)
        ShareBar(() => [
              '🛒 ${t('أيهما أوفر؟', 'أيهما أوفر؟', 'Which is cheaper?')}',
              for (final f in fams.keys)
                for (final i in fams[f]!)
                  '${i == best[f] ? '🏆' : '•'} ${items[i].n.text.trim().isEmpty ? '#${i + 1}' : items[i].n.text.trim()}: ${fmt(items[i].perUnit, 2)}$curTxt / ${_baseLabel(f)}',
            ].join('\n')),
    ]);
  }

  Widget _itemCard(int i, Map<String, int> best, Map<String, List<int>> fams, String curTxt) {
    final it = items[i];
    final isBest = best[it.fam] == i && (fams[it.fam]?.length ?? 0) >= 2;
    final pu = it.perUnit;
    final color = isBest ? SD.green : _colors[i % _colors.length];
    return SCard(
      title: '${isBest ? '🏆 ' : ''}${t('منتج', 'منتج', 'Product')} ${i + 1}',
      icon: Icons.shopping_basket_rounded,
      color: color,
      trailing: MiniIconBtn(Icons.close_rounded,
          tip: tr('حذف', 'Remove'),
          onTap: items.length <= 2
              ? null
              : () {
                  setState(() => items.removeAt(i).dispose());
                  _save();
                }),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: it.n,
          onChanged: (_) => _save(),
          decoration: InputDecoration(labelText: t('الاسم', 'الاسم', 'Name'), hintText: t('جوال سكر 50 كيلو', 'كيس سكر 50 كغ', '50 kg sugar sack'), isDense: true),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: NumField('${t('السعر', 'السعر', 'Price')}${curTxt.isEmpty ? '' : ' ($curTxt)'}', it.p, onChanged: (_) => _save())),
          const SizedBox(width: 8),
          Expanded(child: NumField(t('الحجم/الوزن', 'الحجم/الوزن', 'Size'), it.s, onChanged: (_) => _save(), suffix: _unitLabel(it.unit))),
        ]),
        Row(children: [
          Expanded(
            flex: 3,
            child: Wrap(spacing: 4, runSpacing: 4, children: [
              for (final u in _units)
                ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(_unitLabel(u.$1)),
                  selected: it.unit == u.$1,
                  onSelected: (_) {
                    setState(() => it.unit = u.$1);
                    _save();
                  },
                ),
            ]),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: NumField(t('العدد في العبوة', 'العدد في العبوة', 'Count/pack'), it.c, decimal: false, hint: '1', onChanged: (_) => _save())),
        ]),
        if (pu != null)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
            child: Text(
              '${fmt(pu, 2)}$curTxt / ${_baseLabel(it.fam)}${it.fam == 'w' ? '  •  ${fmt(pu / 10, 2)}$curTxt / 100 ${tr('جم', 'g')}' : it.fam == 'v' ? '  •  ${fmt(pu / 10, 2)}$curTxt / 100 ${tr('مل', 'ml')}' : ''}',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, color)),
            ),
          ),
      ]),
    );
  }
}

const _colors = [SD.nile, SD.henna, SD.purple, SD.orange, SD.indigo, SD.teal];
