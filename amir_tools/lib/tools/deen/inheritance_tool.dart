import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'deen_common.dart';
import 'inheritance_engine.dart';

/// حاسبة المواريث — واجهة
class InheritanceTool extends StatefulWidget {
  const InheritanceTool({super.key});
  @override
  State<InheritanceTool> createState() => _InheritanceToolState();
}

/// مفاتيح الأعداد المحفوظة
const _countKeys = [
  'wives', 'sons', 'daughters', 'sonsSons', 'sonsDaughters', 'fullBrothers', 'fullSisters', 'patBrothers', 'patSisters', 'matSiblings',
  'husband', 'father', 'mother', 'grandfather', 'patGrandmother', 'matGrandmother',
];

class _InheritanceToolState extends State<InheritanceTool> {
  final estate = TextEditingController();
  final funeral = TextEditingController();
  final debts = TextEditingController();
  final wasiyya = TextEditingController();
  String currency = 'SDG';
  bool male = true;
  final c = <String, int>{for (final k in _countKeys) k: 0};
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final m = context.read<AppState>().getData<Map>('inheritance_input');
    if (m == null) return;
    estate.text = (m['estate'] ?? '').toString();
    funeral.text = (m['funeral'] ?? '').toString();
    debts.text = (m['debts'] ?? '').toString();
    wasiyya.text = (m['wasiyya'] ?? '').toString();
    currency = (m['cur'] ?? 'SDG').toString();
    if (!currencies.any((x) => x.code == currency)) currency = 'SDG';
    male = m['male'] != false;
    final counts = m['c'];
    if (counts is Map) {
      for (final k in _countKeys) {
        final v = counts[k];
        if (v is num) c[k] = v.toInt();
      }
    }
  }

  @override
  void dispose() {
    for (final x in [estate, funeral, debts, wasiyya]) {
      x.dispose();
    }
    super.dispose();
  }

  void _save() {
    context.read<AppState>().setData('inheritance_input', {
      'estate': estate.text,
      'funeral': funeral.text,
      'debts': debts.text,
      'wasiyya': wasiyya.text,
      'cur': currency,
      'male': male,
      'c': c,
    });
    setState(() {});
  }

  void _set(String k, int v) {
    c[k] = v;
    _save();
  }

  Heirs get _heirs => Heirs(
        husband: !male && c['husband']! > 0,
        wives: male ? c['wives']! : 0,
        sons: c['sons']!,
        daughters: c['daughters']!,
        sonsSons: c['sonsSons']!,
        sonsDaughters: c['sonsDaughters']!,
        father: c['father']! > 0,
        mother: c['mother']! > 0,
        grandfather: c['grandfather']! > 0,
        patGrandmother: c['patGrandmother']! > 0,
        matGrandmother: c['matGrandmother']! > 0,
        fullBrothers: c['fullBrothers']!,
        fullSisters: c['fullSisters']!,
        patBrothers: c['patBrothers']!,
        patSisters: c['patSisters']!,
        matSiblings: c['matSiblings']!,
      );

  String _unsupportedText(Unsupported u) => switch (u) {
        Unsupported.invalid => t('في خطأ في المدخلات: راجع الزوج/الزوجات والأعداد.', 'المدخلات غير صحيحة: راجع الزوج/الزوجات والأعداد.',
            'Invalid input: check the spouse(s) and the counts.'),
        Unsupported.noHeirs => t(
            'ما في ورثة من الأصناف دي. الحالة دي فيها ذوو الأرحام أو بيت المال وفيها خلاف — لازم تراجع عالم شرعي أو المحكمة.',
            'لا يوجد ورثة من هذه الأصناف. قد يرث ذوو الأرحام أو بيت المال وفي ذلك خلاف — راجع عالمًا شرعيًا أو المحكمة الشرعية.',
            'No heirs from these categories. Distant kin (dhawu al-arham) or the public treasury may inherit, and scholars differ — consult a scholar or Sharia court.'),
        Unsupported.grandfatherSiblings => t(
            'الجد مع الإخوة الأشقاء أو لأب: مسألة فيها خلاف كبير بين المذاهب (المقاسمة أو ثلث الباقي أو السدس، ورأي حجب الإخوة بالجد). ما بنحسبها عشان ما نغلطك — راجع عالم شرعي أو المحكمة.',
            'الجد مع الإخوة الأشقاء أو لأب: مسألة خلافية بين المذاهب (المقاسمة أو ثلث الباقي أو السدس، وقول بحجب الإخوة بالجد). لا نحسبها تجنبًا للخطأ — راجع عالمًا شرعيًا أو المحكمة الشرعية.',
            'Grandfather with full/paternal siblings: the schools differ (sharing, 1/3 of the remainder or 1/6, or the view that he excludes them). This case needs a scholar — consult a scholar or Sharia court.'),
        Unsupported.akdariyya => t(
            'دي المسألة الأكدرية (زوج، أم، جد، أخت): لها طريقة خاصة وفيها خلاف — راجع عالم شرعي أو المحكمة.',
            'هذه المسألة الأكدرية (زوج، أم، جد، أخت): لها طريقة قسمة خاصة وفيها خلاف — راجع عالمًا شرعيًا أو المحكمة الشرعية.',
            'This is the Akdariyya case (husband, mother, grandfather, sister): it has a special, disputed method — consult a scholar or Sharia court.'),
        Unsupported.mushtaraka => t(
            'دي المسألة المشتركة (الحِماريّة): زوج، أم أو جدة، إخوة لأم اتنين فأكثر، وأخ شقيق. فيها خلاف: المالكية والشافعية بيشرّكوا الأشقاء مع الإخوة لأم في الثلث، والحنفية والحنابلة بيسقطوهم — راجع عالم شرعي أو المحكمة.',
            'هذه المسألة المشتركة (الحِماريّة): زوج، وأم أو جدة، واثنان فأكثر من الإخوة لأم، وأخ شقيق. فيها خلاف: المالكية والشافعية يُشرِّكون الأشقاء مع الإخوة لأم في الثلث، والحنفية والحنابلة يُسقطونهم — راجع عالمًا شرعيًا أو المحكمة الشرعية.',
            'This is the Mushtaraka (Himariyya) case: husband, mother or grandmother, 2+ maternal siblings and a full brother. Malikis and Shafi\'is let the full siblings share the 1/3; Hanafis and Hanbalis exclude them — consult a scholar or Sharia court.'),
      };

  @override
  Widget build(BuildContext context) {
    final cur = currencyByCode(currency);
    final est = netEstate(parseNum(estate.text), parseNum(funeral.text), parseNum(debts.text), parseNum(wasiyya.text));
    final h = _heirs;
    final res = computeInheritance(h);
    final hasEstate = parseNum(estate.text) > 0;

    return ToolList(children: [
      NoteBox(
        t('⚠️ الحاسبة دي للتعليم والتقريب بس. قسمة التركة الحقيقية لازم تتأكد منها عند عالم شرعي أو المحكمة الشرعية، لأنو في تفاصيل وأحوال ما بتظهر هنا.',
            '⚠️ هذه الحاسبة تعليمية تقريبية. يجب التحقق من قسمة التركة الفعلية لدى عالم شرعي أو المحكمة الشرعية، فقد توجد تفاصيل وأحوال لا تظهر هنا.',
            '⚠️ Educational estimate only. Verify any real estate division with a qualified scholar or a Sharia court — real cases can have details not covered here.'),
        kind: NoteKind.danger,
      ),
      SCard(
        title: t('التركة', 'التركة', 'Estate'),
        icon: Icons.account_balance_wallet_rounded,
        color: SD.coffee,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField(t('جملة التركة', 'إجمالي التركة', 'Total estate'), estate, onChanged: (_) => _save(), suffix: cur.code),
          DropdownButtonFormField<String>(
            initialValue: currency,
            isExpanded: true,
            decoration: InputDecoration(labelText: tr('العملة', 'Currency')),
            items: [
              for (final x in currencies)
                DropdownMenuItem(value: x.code, child: Text('${x.flag} ${x.name} (${x.code})', maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) {
              currency = v ?? 'SDG';
              _save();
            },
          ),
          const SizedBox(height: 10),
          NumField(t('مصاريف التجهيز والدفن', 'تكاليف التجهيز والدفن', 'Funeral costs'), funeral, onChanged: (_) => _save(), suffix: cur.code),
          NumField(t('الديون على الميت', 'الديون', 'Debts'), debts, onChanged: (_) => _save(), suffix: cur.code),
          NumField(t('الوصية', 'الوصية', 'Bequest (wasiyya)'), wasiyya,
              onChanged: (_) => _save(), suffix: cur.code, hint: t('لغير وارث، وبحد أقصى التلت', 'لغير وارث، وبحد أقصى الثلث', 'For a non-heir, max 1/3')),
          if (est.capped)
            NoteBox(
              t('الوصية زادت عن التلت، فاتحسبت التلت بس (${fmt(est.bequest)}). الزيادة محتاجة موافقة الورثة.',
                  'الوصية تجاوزت الثلث فحُسبت بالثلث فقط (${fmt(est.bequest)}). الزيادة تتوقف على إجازة الورثة.',
                  'The bequest exceeds 1/3, so only 1/3 is applied (${fmt(est.bequest)}). Any excess needs the heirs\' consent.'),
              kind: NoteKind.warn,
            ),
        ]),
      ),
      SCard(
        title: tr('المتوفى والزوجية', 'Deceased & spouse'),
        icon: Icons.person_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: FittedBox(fit: BoxFit.scaleDown, child: Text(tr('رجل', 'Male'))), icon: const Icon(Icons.man_rounded)),
              ButtonSegment(value: false, label: FittedBox(fit: BoxFit.scaleDown, child: Text(tr('امرأة', 'Female'))), icon: const Icon(Icons.woman_rounded)),
            ],
            selected: {male},
            onSelectionChanged: (v) {
              male = v.first;
              _save();
            },
          ),
          const SizedBox(height: 8),
          if (male)
            CountRow(t('الزوجات', 'الزوجات', 'Wives'), c['wives']!, (v) => _set('wives', v), max: 4, icon: Icons.favorite_rounded)
          else
            CountRow(tr('الزوج', 'Husband'), c['husband']!, (v) => _set('husband', v), max: 1, icon: Icons.favorite_rounded),
        ]),
      ),
      SCard(
        title: t('الأولاد', 'الفروع', 'Descendants'),
        icon: Icons.family_restroom_rounded,
        color: SD.green,
        child: Column(children: [
          CountRow(tr('الأبناء', 'Sons'), c['sons']!, (v) => _set('sons', v)),
          CountRow(tr('البنات', 'Daughters'), c['daughters']!, (v) => _set('daughters', v)),
          CountRow(tr('أبناء الابن', 'Son\'s sons'), c['sonsSons']!, (v) => _set('sonsSons', v)),
          CountRow(tr('بنات الابن', 'Son\'s daughters'), c['sonsDaughters']!, (v) => _set('sonsDaughters', v)),
        ]),
      ),
      SCard(
        title: t('الأهل الكبار', 'الأصول', 'Ascendants'),
        icon: Icons.elderly_rounded,
        color: SD.henna,
        child: Column(children: [
          CountRow(tr('الأب', 'Father'), c['father']!, (v) => _set('father', v), max: 1),
          CountRow(tr('الأم', 'Mother'), c['mother']!, (v) => _set('mother', v), max: 1),
          CountRow(tr('الجد (أبو الأب)', 'Paternal grandfather'), c['grandfather']!, (v) => _set('grandfather', v), max: 1),
          CountRow(tr('الجدة (أم الأب)', 'Father\'s mother'), c['patGrandmother']!, (v) => _set('patGrandmother', v), max: 1),
          CountRow(tr('الجدة (أم الأم)', 'Mother\'s mother'), c['matGrandmother']!, (v) => _set('matGrandmother', v), max: 1),
        ]),
      ),
      SCard(
        title: t('الأخوان والأخوات', 'الإخوة والأخوات', 'Siblings'),
        icon: Icons.groups_rounded,
        color: SD.indigo,
        child: Column(children: [
          CountRow(tr('إخوة أشقاء', 'Full brothers'), c['fullBrothers']!, (v) => _set('fullBrothers', v)),
          CountRow(tr('أخوات شقيقات', 'Full sisters'), c['fullSisters']!, (v) => _set('fullSisters', v)),
          CountRow(tr('إخوة لأب', 'Paternal half-brothers'), c['patBrothers']!, (v) => _set('patBrothers', v)),
          CountRow(tr('أخوات لأب', 'Paternal half-sisters'), c['patSisters']!, (v) => _set('patSisters', v)),
          CountRow(tr('إخوة لأم (ذكور وإناث)', 'Maternal half-siblings'), c['matSiblings']!, (v) => _set('matSiblings', v),
              hint: tr('يُحسبون مجموعة واحدة', 'Counted as one group')),
        ]),
      ),
      ..._result(res, est, cur, hasEstate),
      NoteBox(
        t('الترتيب الشرعي: أول حاجة مصاريف التجهيز والدفن، بعدها الديون، بعدها الوصية (لغير وارث وفي حدود التلت)، والباقي للورثة. الحاسبة على مذهب الجمهور ومتوافقة مع المالكية في الحالات المدعومة.',
            'الترتيب الشرعي: تُخرج تكاليف التجهيز والدفن أولًا، ثم الديون، ثم الوصية (لغير وارث وفي حدود الثلث)، والباقي للورثة. الحساب على قول الجمهور ويوافق المالكية في الحالات المدعومة.',
            'Order: funeral costs first, then debts, then the bequest (to a non-heir, within 1/3); the rest goes to the heirs. Calculated per the majority (Sunni) view, compatible with the Maliki school for supported cases.'),
      ),
    ]);
  }

  List<Widget> _result(InheritanceResult res, ({double net, double bequest, bool capped}) est, Currency cur, bool hasEstate) {
    if (res.unsupported == Unsupported.noHeirs && !_heirs.any) {
      return [
        NoteBox(t('ضيف الورثة عشان تظهر القسمة.', 'أضف الورثة لتظهر القسمة.', 'Add the heirs to see the division.'), kind: NoteKind.tip),
      ];
    }
    if (res.unsupported != null) {
      return [
        SCard(
          title: t('راجع عالم أو المحكمة', 'استشر عالمًا أو المحكمة', 'Consult a scholar / court'),
          icon: Icons.gavel_rounded,
          color: SD.red,
          child: NoteBox(_unsupportedText(res.unsupported!), kind: NoteKind.danger),
        ),
      ];
    }
    final net = est.net;
    final inherit = res.rows.where((r) => !r.blocked).toList();
    final blocked = res.rows.where((r) => r.blocked).toList();
    String money(Frac f) => hasEstate ? '${fmt(f.value * net)} ${cur.sym}' : '—';
    String pct(Frac f) => '${fmt(f.value * 100, 2)}%';

    String summary() {
      final b = StringBuffer('${tr('قسمة التركة', 'Estate division')} — ${tr('صافي', 'Net')}: ${hasEstate ? '${fmt(net)} ${cur.code}' : '—'}\n');
      if (res.awl) b.writeln(tr('عالت المسألة من ${res.base} إلى ${res.awlTo}', '\'Awl: base ${res.base} raised to ${res.awlTo}'));
      if (res.radd) b.writeln(tr('فيها رَدّ', 'Includes radd'));
      for (final r in inherit) {
        b.writeln('• ${heirName(r.key, r.count)}${r.count > 1 ? ' ×${r.count}' : ''}: ${r.share} (${pct(r.share)}) ${hasEstate ? '= ${money(r.share)}' : ''} — ${r.term}');
      }
      for (final r in blocked) {
        b.writeln('• ${heirName(r.key, r.count)}: ${tr('محجوب', 'excluded')}');
      }
      b.write(tr('⚠️ للتعليم فقط — تحقق عند عالم أو محكمة شرعية', '⚠️ Educational only — verify with a scholar or Sharia court'));
      return b.toString();
    }

    return [
      ResultHero(
        label: t('الصافي للورثة', 'الصافي القابل للقسمة', 'Net for heirs'),
        value: hasEstate ? '${fmt(net)} ${cur.sym}' : '—',
        sub: hasEstate
            ? '${tr('بعد', 'After')}: ${tr('التجهيز', 'funeral')} ${fmt(parseNum(funeral.text))} • ${tr('الديون', 'debts')} ${fmt(parseNum(debts.text))} • ${tr('الوصية', 'bequest')} ${fmt(est.bequest)}'
            : t('اكتب قيمة التركة عشان تظهر المبالغ', 'أدخل قيمة التركة لتظهر المبالغ', 'Enter the estate value to see amounts'),
      ),
      if (res.awl)
        NoteBox(
          t('في «عَوْل»: الفروض زادت على التركة، فأصل المسألة ${res.base} عال إلى ${res.awlTo} ونقص نصيب كل واحد بالنسبة.',
              'في المسألة «عَوْل»: زادت الفروض على التركة، فعال أصلها من ${res.base} إلى ${res.awlTo} ونقصت الأنصبة بالنسبة.',
              '\'Awl (proportional reduction): the fixed shares exceed the estate, so the base ${res.base} is raised to ${res.awlTo} and every share shrinks proportionally.'),
          kind: NoteKind.warn,
        ),
      if (res.radd)
        NoteBox(
          t('في «رَدّ»: فضل باقي وما في عاصب، فرجع لأصحاب الفروض غير الزوجين بنسبة فروضهم. لو في عصبة أبعد (ابن أخ، عم، ابن عم) هم أولى بالباقي — راجع عالم.',
              'في المسألة «رَدّ»: بقي فائض ولا عاصب، فيُردّ على أصحاب الفروض غير الزوجين بنسبة فروضهم. إن وُجد عاصب أبعد (ابن أخ، عم، ابن عم) فهو أولى بالباقي — راجع عالمًا.',
              'Radd (return): there is a surplus and no residuary heir, so it returns to the fixed-share heirs (not spouses) in proportion. If farther agnates exist (nephews, uncles, cousins) they take it instead — consult a scholar.'),
          kind: NoteKind.info,
        ),
      if (res.unallocated.isPositive)
        NoteBox(
          t('فضل ${res.unallocated} (${pct(res.unallocated)}) ما ليهو وارث من الأصناف دي: بيمشي لعصبة أبعد أو ذوي الأرحام أو بيت المال حسب المذهب — راجع عالم أو المحكمة.',
              'بقي ${res.unallocated} (${pct(res.unallocated)}) بلا وارث من هذه الأصناف: يذهب لعاصب أبعد أو ذوي الأرحام أو بيت المال بحسب المذهب — راجع عالمًا أو المحكمة.',
              '${res.unallocated} (${pct(res.unallocated)}) is left with no heir from these categories: it goes to farther agnates, distant kin or the treasury depending on the school — consult a scholar or court.'),
          kind: NoteKind.danger,
        ),
      SCard(
        title: t('الأنصبة', 'الأنصبة', 'Shares'),
        icon: Icons.pie_chart_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final r in inherit) _ShareTile(r, money: money, pct: pct, hasEstate: hasEstate),
          for (final r in blocked) _ShareTile(r, money: money, pct: pct, hasEstate: hasEstate),
          const SizedBox(height: 10),
          ShareBar(summary),
        ]),
      ),
    ];
  }
}

class _ShareTile extends StatelessWidget {
  final HeirShare r;
  final String Function(Frac) money, pct;
  final bool hasEstate;
  const _ShareTile(this.r, {required this.money, required this.pct, required this.hasEstate});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .65);
    final color = r.blocked ? SD.red : (r.asaba ? SD.green : SD.gold);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: readable(context, color).withValues(alpha: .35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Text('${heirName(r.key, r.count)}${r.count > 1 ? ' × ${r.count}' : ''}',
                maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(r.blocked ? '0' : r.share.toString(),
                  textDirection: TextDirection.ltr, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: readable(context, color))),
            ),
          ),
        ]),
        if (!r.blocked) ...[
          const SizedBox(height: 4),
          Wrap(spacing: 12, runSpacing: 2, children: [
            Text(pct(r.share), style: TextStyle(fontWeight: FontWeight.w700, color: muted)),
            if (hasEstate) Text(money(r.share), style: const TextStyle(fontWeight: FontWeight.w800)),
            if (r.count > 1)
              Text('${tr('للفرد', 'each')}: ${r.each}${hasEstate ? ' = ${money(r.each)}' : ''}', style: TextStyle(color: muted, fontSize: 12.5)),
          ]),
        ],
        const SizedBox(height: 6),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(r.term, textAlign: TextAlign.start, style: TextStyle(fontWeight: FontWeight.w700, color: readable(context, color), fontSize: 13)),
        ),
        Text(r.why, style: TextStyle(color: muted, fontSize: 12.5, height: 1.4)),
      ]),
    );
  }
}
