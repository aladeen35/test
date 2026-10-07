import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart';
import 'biz_common.dart';

/// ظرف افتراضي (نسبة من الدخل)
class _Env {
  final String key, emoji, sd, ar, en;
  final double pct;

  /// 0 = ضروريات، 1 = رغبات، 2 = ادّخار (لمقارنة 50/30/20)
  final int kind;
  const _Env(this.key, this.emoji, this.sd, this.ar, this.en, this.pct, this.kind);
  String get name => t(sd, ar, en);
}

const _defs = [
  _Env('food', '🍲', 'الأكل', 'الطعام', 'Food', 30, 0),
  _Env('rent', '🔑', 'الإيجار', 'الإيجار', 'Rent', 20, 0),
  _Env('utilities', '💡', 'الكهرباء والموية', 'الكهرباء والماء', 'Power & water', 7, 0),
  _Env('transport', '🛺', 'المواصلات', 'المواصلات', 'Transport', 8, 0),
  _Env('school', '📚', 'المدارس', 'التعليم', 'School', 8, 0),
  _Env('family', '💸', 'تحويل للأهل', 'تحويل للأهل', 'Sending to family', 10, 1),
  _Env('sadaqa', '🤲', 'الصدقة', 'الصدقة', 'Charity', 2, 1),
  _Env('saving', '🏦', 'التوفير', 'الادّخار', 'Savings', 10, 2),
  _Env('other', '📦', 'حاجات تانية', 'أخرى', 'Other', 5, 1),
];

const _colors = [SD.orange, SD.indigo, SD.gold, SD.nile, SD.teal, SD.green, SD.nileLight, SD.purple, SD.brownLight, SD.pink, SD.henna, SD.coffee];

_Env? _def(String? k) {
  for (final e in _defs) {
    if (e.key == k) return e;
  }
  return null;
}

class MonthBudgetTool extends StatefulWidget {
  const MonthBudgetTool({super.key});
  @override
  State<MonthBudgetTool> createState() => _MonthBudgetToolState();
}

class _MonthBudgetToolState extends State<MonthBudgetTool> {
  static const _key = 'month_budget_data';
  late int _y, _m;

  @override
  void initState() {
    super.initState();
    final n = todayPlace();
    _y = n.year;
    _m = n.month;
  }

  String get _mk => mk(_y, _m);

  Map<String, dynamic> _data(AppState s) => Map<String, dynamic>.from(s.getData<Map>(_key) ?? const {});
  String _cur(Map d) => ((d['cur'] as String?) ?? '').isEmpty ? 'ج.س' : d['cur'] as String;
  Map<String, dynamic> _months(Map d) => Map<String, dynamic>.from((d['months'] as Map?) ?? const {});

  /// بيانات الشهر؛ لو ما محفوظ ننسخ ظروف ودخل آخر شهر قبله (أو الافتراضي)
  Map<String, dynamic> _month(Map d, String key) {
    final ms = _months(d);
    if (ms[key] is Map) return Map<String, dynamic>.from(ms[key] as Map);
    final earlier = ms.keys.where((k) => k.compareTo(key) < 0).toList()..sort();
    if (earlier.isNotEmpty) {
      final last = Map<String, dynamic>.from(ms[earlier.last] as Map);
      return {'income': last['income'] ?? 0, 'env': mapList(last['env']), 'spend': <Map>[]};
    }
    return {
      'income': 0,
      'env': [for (final e in _defs) {'id': e.key, 'key': e.key, 'v': e.pct, 'pct': true}],
      'spend': <Map>[],
    };
  }

  void _saveMonth(AppState s, Map<String, dynamic> m) {
    final d = _data(s);
    final ms = _months(d)..[_mk] = m;
    s.setData(_key, {...d, 'months': ms});
  }

  String _name(Map e) {
    final n = (e['name'] as String?) ?? '';
    return n.isNotEmpty ? n : (_def(e['key'] as String?)?.name ?? t('ظرف', 'ظرف', 'Envelope'));
  }

  String _emoji(Map e) => _def(e['key'] as String?)?.emoji ?? '✉️';
  double _amount(Map e, double income) => e['pct'] == true ? income * numOf(e['v']) / 100 : numOf(e['v']);
  double _spent(Map m, String id) => mapList(m['spend']).where((x) => x['env'] == id).fold(0.0, (a, x) => a + numOf(x['a']));

  void _shift(int by) {
    var m = _m + by, y = _y;
    while (m < 1) {
      m += 12;
      y--;
    }
    while (m > 12) {
      m -= 12;
      y++;
    }
    setState(() {
      _y = y;
      _m = m;
    });
  }

  Future<void> _editIncome(AppState s, Map<String, dynamic> m, String cur) async {
    final v = await askText(context, t('دخل الشهر ($cur)', 'دخل الشهر ($cur)', 'Monthly income ($cur)'),
        initial: numOf(m['income']) > 0 ? fmt(numOf(m['income']), 2).replaceAll(',', '') : '', number: true, hint: t('الماهية + أي دخل تاني', 'الراتب وأي دخل آخر', 'Salary + any other income'));
    if (v == null || !mounted) return;
    _saveMonth(s, {...m, 'income': parseNum(v)});
    s.awardDaily('month_budget_plan', 3, tr('تخطيط ميزانية الشهر', 'Planned monthly budget'));
  }

  Future<void> _editEnv(AppState s, Map<String, dynamic> m, String cur, [Map<String, dynamic>? e]) async {
    final income = numOf(m['income']);
    final nameC = TextEditingController(text: e == null ? '' : _name(e));
    final vC = TextEditingController(text: e == null ? '' : fmt(numOf(e['v']), 2).replaceAll(',', ''));
    var isPct = e == null ? true : e['pct'] == true;
    final ok = await lifeSheet<bool>(
      context,
      e == null ? t('ظرف جديد', 'ظرف جديد', 'New envelope') : '${_emoji(e)} ${_name(e)}',
      (ctx, set) {
        final v = parseNum(vC.text);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: nameC, decoration: InputDecoration(labelText: t('اسم الظرف', 'اسم الظرف', 'Envelope name'))),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: true, label: Text(t('نسبة %', 'نسبة %', 'Percent'))),
              ButtonSegment(value: false, label: Text(t('مبلغ', 'مبلغ', 'Amount'))),
            ],
            selected: {isPct},
            onSelectionChanged: (x) => set(() => isPct = x.first),
          ),
          const SizedBox(height: 12),
          NumField(isPct ? t('النسبة من الدخل', 'النسبة من الدخل', 'Share of income') : t('المبلغ', 'المبلغ', 'Amount'), vC, suffix: isPct ? '%' : cur, onChanged: (_) => set(() {})),
          if (isPct && income > 0) Text('= ${money(income * v / 100, cur)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          if (!isPct && income > 0) Text('= ${pct(v / income * 100, 1)} ${t('من الدخل', 'من الدخل', 'of income')}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(children: [
            if (e != null)
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: SD.red),
                  onPressed: () => Navigator.pop(ctx, false),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(t('امسح', 'حذف', 'Delete'), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            if (e != null) const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () {
                  if (nameC.text.trim().isEmpty) return toast(t('أكتب اسم الظرف', 'اكتب اسم الظرف', 'Enter a name'));
                  Navigator.pop(ctx, true);
                },
                icon: const Icon(Icons.check_rounded),
                label: Text(t('احفظ', 'حفظ', 'Save')),
              ),
            ),
          ]),
        ]);
      },
    );
    final name = nameC.text.trim(), v = parseNum(vC.text);
    nameC.dispose();
    vC.dispose();
    if (!mounted || ok == null) return;
    final cur2 = _month(_data(s), _mk);
    final env = mapList(cur2['env']);
    if (ok == false && e != null) {
      env.removeWhere((x) => x['id'] == e['id']);
      final spend = mapList(cur2['spend'])..removeWhere((x) => x['env'] == e['id']);
      _saveMonth(s, {...cur2, 'env': env, 'spend': spend});
      return;
    }
    if (e == null) {
      env.add({'id': newId(), 'key': 'custom', 'name': name, 'v': v, 'pct': isPct});
    } else {
      final i = env.indexWhere((x) => x['id'] == e['id']);
      if (i >= 0) {
        env[i] = {...env[i], 'v': v, 'pct': isPct};
        if (name != _name(e)) env[i]['name'] = name;
      }
    }
    _saveMonth(s, {...cur2, 'env': env});
  }

  Future<void> _spend(AppState s, Map<String, dynamic> m, String cur, Map<String, dynamic> e) async {
    final aC = TextEditingController();
    final noteC = TextEditingController();
    final today = todayPlace();
    final isCurrent = _y == today.year && _m == today.month;
    var date = isCurrent ? today : DateTime(_y, _m, 1);
    final income = numOf(m['income']);
    final left = _amount(e, income) - _spent(m, e['id'] as String);
    final ok = await lifeSheet<bool>(
      context,
      '${_emoji(e)} ${t('صرف من', 'صرف من', 'Spend from')} ${_name(e)}',
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${t('الفاضل في الظرف', 'المتبقي في الظرف', 'Left in envelope')}: ${money(left, cur)}', style: TextStyle(fontWeight: FontWeight.w700, color: readable(ctx, left < 0 ? SD.red : SD.green))),
        const SizedBox(height: 10),
        NumField(t('المبلغ', 'المبلغ', 'Amount'), aC, suffix: cur),
        TextField(controller: noteC, decoration: InputDecoration(labelText: t('في شنو؟ (اختياري)', 'الوصف (اختياري)', 'What for? (optional)'))),
        const SizedBox(height: 12),
        LifeDateButton(
          label: t('التاريخ', 'التاريخ', 'Date'),
          value: date,
          first: DateTime(_y, _m, 1),
          last: DateTime(_y, _m, daysInMonth(_y, _m)),
          onPick: (v) => set(() => date = v ?? date),
          color: SD.orange,
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () {
            if (parseNum(aC.text) <= 0) return toast(t('أكتب المبلغ', 'اكتب المبلغ', 'Enter the amount'));
            Navigator.pop(ctx, true);
          },
          icon: const Icon(Icons.check_rounded),
          label: Text(t('سجّل', 'تسجيل', 'Save')),
        ),
      ]),
    );
    final a = parseNum(aC.text), note = noteC.text.trim();
    aC.dispose();
    noteC.dispose();
    if (!mounted || ok != true) return;
    final mm = _month(_data(s), _mk);
    final spend = mapList(mm['spend'])..add({'id': newId(), 'env': e['id'], 'a': a, 'note': note, 'd': dk(date)});
    _saveMonth(s, {...mm, 'spend': spend});
    HapticFeedback.selectionClick();
    s.awardDaily('month_budget_log', 3, tr('تسجيل صرف الشهر', 'Logged monthly spending'));
    final amt = _amount(e, numOf(mm['income']));
    final now = _spent({...mm, 'spend': spend}, e['id'] as String);
    if (amt > 0 && now > amt) {
      toast('⚠️ ${_name(e)}: ${t('عدّيت الظرف', 'تجاوزت الظرف', 'envelope exceeded')}');
    } else if (amt > 0 && now >= amt * .8) {
      toast('⚠️ ${_name(e)}: ${t('قرّب يخلص', 'اقترب من النفاد', 'almost used up')} (${pct(now / amt * 100)})');
    }
  }

  void _deleteSpend(AppState s, Map<String, dynamic> x) {
    final mm = _month(_data(s), _mk);
    final spend = mapList(mm['spend']);
    final i = spend.indexWhere((y) => y['id'] == x['id']);
    if (i < 0) return;
    spend.removeAt(i);
    _saveMonth(s, {...mm, 'spend': spend});
    undoSnack(t('اتمسح', 'حُذف', 'Deleted'), () {
      final m2 = _month(_data(s), _mk);
      _saveMonth(s, {...m2, 'spend': mapList(m2['spend'])..add(x)});
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final d = _data(s);
    final cur = _cur(d);
    final m = _month(d, _mk);
    final income = numOf(m['income']);
    final env = mapList(m['env']);
    final spend = mapList(m['spend'])..sort((a, b) => ((b['d'] as String?) ?? '').compareTo((a['d'] as String?) ?? ''));
    final today = todayPlace();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final isCurrent = _y == today.year && _m == today.month;
    final isPast = DateTime(_y, _m).isBefore(DateTime(today.year, today.month));

    final allocated = env.fold(0.0, (a, e) => a + _amount(e, income));
    final spent = spend.fold(0.0, (a, x) => a + numOf(x['a']));
    final remaining = income - spent;
    final daysLeft = isCurrent ? daysInMonth(_y, _m) - today.day + 1 : (isPast ? 0 : daysInMonth(_y, _m));
    final perDay = daysLeft > 0 && remaining > 0 ? remaining / daysLeft : 0.0;

    final warnings = <Widget>[];
    for (final e in env) {
      final amt = _amount(e, income), sp = _spent(m, e['id'] as String);
      if (amt <= 0) {
        if (sp > 0) warnings.add(NoteBox('${_emoji(e)} ${_name(e)}: ${t('صرفت ${money(sp, cur)} من ظرف ما ليهو مبلغ', 'صُرف ${money(sp, cur)} من ظرف بلا مبلغ', 'spent ${money(sp, cur)} from an unfunded envelope')}', kind: NoteKind.warn));
        continue;
      }
      if (sp > amt) {
        warnings.add(NoteBox('${_emoji(e)} ${_name(e)}: ${t('عدّيت بـ ${money(sp - amt, cur)}', 'تجاوزت بمقدار ${money(sp - amt, cur)}', 'over by ${money(sp - amt, cur)}')}', kind: NoteKind.danger));
      } else if (sp >= amt * .8) {
        warnings.add(NoteBox('${_emoji(e)} ${_name(e)}: ${t('صرفت ${pct(sp / amt * 100)} — فاضل ${money(amt - sp, cur)}', 'صُرف ${pct(sp / amt * 100)} — المتبقي ${money(amt - sp, cur)}', '${pct(sp / amt * 100)} used — ${money(amt - sp, cur)} left')}', kind: NoteKind.warn));
      }
    }

    // 50/30/20
    final split = [0.0, 0.0, 0.0];
    for (final e in env) {
      split[_def(e['key'] as String?)?.kind ?? 1] += _amount(e, income);
    }

    // سجل الشهور
    final hist = _months(d).keys.toList()..sort((a, b) => b.compareTo(a));

    String summary() {
      final b = StringBuffer('📒 ${t('ميزانية', 'ميزانية', 'Budget')} ${fmtMonth(_y, _m)}\n');
      b.writeln('${t('الدخل', 'الدخل', 'Income')}: ${money(income, cur)}');
      b.writeln('${t('المصروف', 'المصروف', 'Spent')}: ${money(spent, cur)}${income > 0 ? ' (${pct(spent / income * 100)})' : ''}');
      b.writeln('${t('الفاضل', 'المتبقي', 'Remaining')}: ${money(remaining, cur)}');
      if (isCurrent && perDay > 0) b.writeln('${t('في اليوم لحدي آخر الشهر', 'المسموح يوميًا', 'Per day till month end')}: ${money(perDay, cur)}');
      b.writeln('');
      for (final e in env) {
        b.writeln('${_emoji(e)} ${_name(e)}: ${money(_spent(m, e['id'] as String), cur)} / ${money(_amount(e, income), cur)}');
      }
      return b.toString().trim();
    }

    return ToolList(children: [
      Row(children: [
        IconButton(onPressed: () => _shift(-1), icon: Icon(rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded), tooltip: t('الشهر الفات', 'الشهر السابق', 'Previous month')),
        Expanded(
          child: InkWell(
            onTap: () => setState(() {
              _y = today.year;
              _m = today.month;
            }),
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(fmtMonth(_y, _m), maxLines: 1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          ),
        ),
        IconButton(onPressed: () => _shift(1), icon: Icon(rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded), tooltip: t('الشهر الجاي', 'الشهر التالي', 'Next month')),
      ]),
      ResultHero(
        label: t('الفاضل من الدخل', 'المتبقي من الدخل', 'Left from income'),
        value: money(remaining, cur),
        sub: [
          '${t('الدخل', 'الدخل', 'Income')} ${money(income, cur)}',
          '${t('صرفت', 'المصروف', 'Spent')} ${money(spent, cur)}',
          if (isCurrent && perDay > 0) '${t('في اليوم', 'يوميًا', 'per day')} ${money(perDay, cur)} × $daysLeft',
        ].join(' · '),
        colors: remaining < 0 ? const [SD.red, SD.henna, SD.brownDeep] : const [SD.nile, SD.indigo, SD.brownDeep],
      ),
      Row(children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _editIncome(s, m, cur),
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(income > 0 ? t('غيّر الدخل', 'تعديل الدخل', 'Edit income') : t('أكتب الدخل', 'أدخل الدخل', 'Set income'))),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _editEnv(s, m, cur),
            icon: const Icon(Icons.add_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('ظرف جديد', 'ظرف جديد', 'New envelope'))),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      StatGrid([
        StatChip(compact(allocated), t('موزّع', 'المُخصّص', 'Allocated'), color: SD.gold, icon: Icons.mail_rounded),
        StatChip(compact(income - allocated), t('ما موزّع', 'غير مُخصّص', 'Unallocated'), color: income - allocated < 0 ? SD.red : SD.teal, icon: Icons.inbox_rounded),
        StatChip(income > 0 ? pct(spent / income * 100) : '—', t('من الدخل اتصرف', 'نسبة المصروف', 'of income spent'), color: SD.orange, icon: Icons.pie_chart_rounded),
      ]),
      const SizedBox(height: 8),
      if (income <= 0)
        NoteBox(t('أكتب دخلك الشهري أول عشان الظروف بالنسبة تتحسب.', 'أدخل دخلك الشهري أولًا لتُحسب الظروف المحددة بالنسبة.', 'Enter your monthly income first so percentage envelopes get amounts.'), kind: NoteKind.info),
      if (income > 0 && allocated > income + 0.01)
        NoteBox(t('وزّعت أكتر من دخلك بـ ${money(allocated - income, cur)}', 'المُخصّص يزيد على الدخل بـ ${money(allocated - income, cur)}', 'Allocated exceeds income by ${money(allocated - income, cur)}'), kind: NoteKind.danger),
      ...warnings,
      SCard(
        title: t('الظروف', 'الظروف', 'Envelopes'),
        icon: Icons.mail_outline_rounded,
        color: SD.indigo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t('دوس على الظرف عشان تسجّل صرف، والقلم للتعديل.', 'اضغط على الظرف لتسجيل صرف، والقلم للتعديل.', 'Tap an envelope to log spending; the pencil edits it.'), style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          for (var i = 0; i < env.length; i++) _envTile(s, m, cur, env[i], income, _colors[i % _colors.length]),
          if (env.isEmpty) EmptyHint(Icons.mail_outline_rounded, t('ما في ظروف', 'لا توجد ظروف', 'No envelopes')),
        ]),
      ),
      if (income > 0)
        SCard(
          title: t('قاعدة 50/30/20', 'قاعدة 50/30/20', 'The 50/30/20 rule'),
          icon: Icons.balance_rounded,
          color: SD.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              t('اقتراح: 50% للضروريات (أكل، إيجار، كهرباء، مواصلات، مدارس)، 30% للباقي (الأهل، الصدقة، الحاجات التانية)، و20% للتوفير.',
                  'اقتراح: 50% للضروريات، و30% للالتزامات والرغبات (الأهل، الصدقة، أخرى)، و20% للادّخار.',
                  'Suggestion: 50% needs (food, rent, utilities, transport, school), 30% the rest (family, charity, other), 20% savings.'),
              style: const TextStyle(fontSize: 12.5, height: 1.5),
            ),
            const SizedBox(height: 6),
            for (final (i, label, target) in [
              (0, t('ضروريات', 'الضروريات', 'Needs'), 50.0),
              (1, t('الباقي', 'الالتزامات والرغبات', 'Other'), 30.0),
              (2, t('توفير', 'الادّخار', 'Savings'), 20.0),
            ])
              BizBar(
                '$label — ${t('المقترح', 'المقترح', 'suggested')} ${money(income * target / 100, cur)}',
                split[i] / income,
                '${pct(split[i] / income * 100)} / ${pct(target)}',
                color: [SD.orange, SD.purple, SD.green][i],
              ),
            if (split[2] / income < .1)
              NoteBox(t('حاول توفّر ولو 10% — حتى لو قليل، الاستمرار هو المهم.', 'حاول ادّخار 10% على الأقل؛ فالاستمرار أهم من المقدار.', 'Try to save at least 10% — consistency matters more than size.'), kind: NoteKind.tip),
          ]),
        ),
      SectionTitle(t('صرف الشهر', 'مصروفات الشهر', 'This month\'s spending'), icon: Icons.receipt_long_rounded),
      if (spend.isEmpty)
        EmptyHint(Icons.receipt_long_outlined, t('ما سجّلت أي صرف في الشهر دا', 'لا مصروفات مسجّلة لهذا الشهر', 'No spending logged this month'))
      else
        SCard(
          child: Column(children: [
            for (final x in spend.take(60))
              () {
                final e = env.where((y) => y['id'] == x['env']).firstOrNull;
                return MiniRow(
                  ((x['note'] as String?) ?? '').isNotEmpty ? x['note'] as String : (e == null ? '—' : _name(e)),
                  money(numOf(x['a']), cur),
                  sub: '${e == null ? '' : '${_emoji(e)} ${_name(e)} · '}${parseDk(x['d']) == null ? '' : fmtShort(parseDk(x['d'])!)}',
                  trailing: iconBtn(Icons.delete_outline_rounded, t('امسح', 'حذف', 'Delete'), () => _deleteSpend(s, x)),
                );
              }(),
          ]),
        ),
      if (hist.isNotEmpty)
        SCard(
          title: t('الشهور الفاتت', 'سجل الشهور', 'Month history'),
          icon: Icons.history_rounded,
          color: SD.coffee,
          child: Column(children: [
            for (final k in hist.take(12))
              () {
                final mm = Map<String, dynamic>.from(_months(d)[k] as Map);
                final inc = numOf(mm['income']);
                final sp = mapList(mm['spend']).fold(0.0, (a, x) => a + numOf(x['a']));
                final p = k.split('-');
                final y = int.tryParse(p[0]) ?? _y, mo = int.tryParse(p.length > 1 ? p[1] : '') ?? _m;
                return InkWell(
                  onTap: () => setState(() {
                    _y = y;
                    _m = mo;
                  }),
                  child: BizBar(fmtMonth(y, mo), inc <= 0 ? 0 : sp / inc, '${compact(sp)} / ${compact(inc)}',
                      color: inc > 0 && sp > inc ? SD.red : SD.coffee,
                      hint: inc > 0 ? '${t('وفّرت', 'المتبقي', 'Left')} ${money(inc - sp, cur)}' : null),
                );
              }(),
          ]),
        ),
      SCard(
        title: t('الضبط', 'الإعدادات', 'Settings'),
        icon: Icons.tune_rounded,
        color: SD.nile,
        child: CurField(cur, (v) => s.setData(_key, {..._data(s), 'cur': v})),
      ),
      ShareBar(summary),
      const SizedBox(height: 8),
      NoteBox(
        t('كل شهر جديد بياخد ظروف ودخل الشهر القبلو تلقائي، وتقدر تعدّلها. والصدقة ما بتنقّص مال 🤲',
            'كل شهر جديد يبدأ بظروف ودخل الشهر السابق تلقائيًا، ويمكنك تعديلها. و«ما نقصت صدقة من مال».',
            'Each new month starts with the previous month\'s envelopes and income; edit as needed.'),
        kind: NoteKind.tip,
      ),
    ]);
  }

  Widget _envTile(AppState s, Map<String, dynamic> m, String cur, Map<String, dynamic> e, double income, Color color) {
    final amt = _amount(e, income), sp = _spent(m, e['id'] as String);
    final frac = amt <= 0 ? (sp > 0 ? 1.0 : 0.0) : sp / amt;
    final c = frac > 1 ? SD.red : (frac >= .8 ? SD.orange : color);
    return Row(children: [
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _spend(s, m, cur, e),
          child: BizBar(
            '${_emoji(e)} ${_name(e)}${e['pct'] == true ? ' (${pct(numOf(e['v']), 1)})' : ''}',
            frac,
            '${compact(sp)} / ${compact(amt)}',
            color: c,
            hint: amt > 0 ? (sp > amt ? t('عدّى بـ ${money(sp - amt, cur)}', 'تجاوز بـ ${money(sp - amt, cur)}', 'Over by ${money(sp - amt, cur)}') : t('فاضل ${money(amt - sp, cur)}', 'متبقٍ ${money(amt - sp, cur)}', '${money(amt - sp, cur)} left')) : null,
          ),
        ),
      ),
      iconBtn(Icons.edit_rounded, t('عدّل', 'تعديل', 'Edit'), () => _editEnv(s, m, cur, e)),
    ]);
  }
}
