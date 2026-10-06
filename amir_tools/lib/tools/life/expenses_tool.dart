import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../daily/daily_common.dart' show Bar, BarChart;
import '../money/money_common.dart' show CurrencyPicker, PercentBar, curSym;
import 'life_common.dart';

/// تصنيف مصروف
class _Cat {
  final String key, emoji, sd, ar, en;
  final Color color;
  const _Cat(this.key, this.emoji, this.sd, this.ar, this.en, this.color);
  String get name => t(sd, ar, en);
}

const _cats = [
  _Cat('food', '🍲', 'أكل وشراب', 'طعام وشراب', 'Food & drinks', SD.orange),
  _Cat('transport', '🛺', 'مواصلات/ركشة', 'مواصلات', 'Transport', SD.nile),
  _Cat('phone', '📱', 'رصيد ونت', 'رصيد وإنترنت', 'Airtime & data', SD.purple),
  _Cat('utilities', '💡', 'كهرباء وموية', 'كهرباء وماء', 'Power & water', SD.gold),
  _Cat('health', '💊', 'علاج', 'علاج ودواء', 'Health', SD.red),
  _Cat('house', '🏠', 'قروش البيت', 'مصروف المنزل', 'Household', SD.coffee),
  _Cat('events', '🎉', 'مناسبات (أفراح وبكيات)', 'مناسبات اجتماعية', 'Social occasions', SD.pink),
  _Cat('rent', '🔑', 'إيجار', 'إيجار', 'Rent', SD.indigo),
  _Cat('school', '📚', 'مدارس وقراية', 'تعليم', 'Education', SD.teal),
  _Cat('clothes', '👕', 'لبس', 'ملابس', 'Clothing', SD.henna),
  _Cat('family', '💸', 'مساعدة الأهل', 'دعم الأهل', 'Family support', SD.green),
  _Cat('sadaqa', '🤲', 'صدقة', 'صدقة', 'Charity', SD.nileLight),
  _Cat('other', '📦', 'حاجات تانية', 'أخرى', 'Other', SD.brownLight),
];

_Cat _cat(String? k) => _cats.firstWhere((c) => c.key == k, orElse: () => _cats.last);

class ExpensesTool extends StatefulWidget {
  const ExpensesTool({super.key});
  @override
  State<ExpensesTool> createState() => _ExpensesToolState();
}

class _ExpensesToolState extends State<ExpensesTool> {
  late int _y, _m;
  String? _catFilter;

  @override
  void initState() {
    super.initState();
    final n = todayPlace();
    _y = n.year;
    _m = n.month;
  }

  List<Map<String, dynamic>> _list(AppState s) => mapList(s.getData<List>('expenses_list'));
  void _save(AppState s, List<Map<String, dynamic>> l) => s.setData('expenses_list', l);
  Map<String, dynamic> _cfg(AppState s) => Map<String, dynamic>.from(s.getData<Map>('expenses_cfg') ?? const {});
  void _setCfg(AppState s, String k, dynamic v) => s.setData('expenses_cfg', {..._cfg(s), k: v});
  String _main(AppState s) => (_cfg(s)['main'] as String?) ?? 'SDG';

  double _inMain(AppState s, Map e, String main) => numOf(e['a']) * (e['cur'] == main ? 1 : s.rate((e['cur'] as String?) ?? 'SDG', main));

  List<Map<String, dynamic>> _ofMonth(List<Map<String, dynamic>> l, int y, int m) {
    final p = mk(y, m);
    return l.where((e) => ((e['d'] as String?) ?? '').startsWith(p)).toList();
  }

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

  Future<void> _edit([Map<String, dynamic>? e]) async {
    final s = context.read<AppState>();
    final aC = TextEditingController(text: e == null ? '' : fmt(numOf(e['a']), 2).replaceAll(',', ''));
    final noteC = TextEditingController(text: e?['note'] ?? '');
    var cur = (e?['cur'] as String?) ?? (_cfg(s)['last'] as String?) ?? _main(s);
    var cat = (e?['cat'] as String?) ?? (_cfg(s)['lastCat'] as String?) ?? 'food';
    final now = todayPlace();
    var date = parseDk(e?['d']) ??
        ((_y == now.year && _m == now.month) ? now : DateTime(_y, _m, daysInMonth(_y, _m)));
    final ok = await lifeSheet<bool>(
      context,
      e == null ? t('مصروف جديد', 'مصروف جديد', 'New expense') : t('عدّل المصروف', 'تعديل المصروف', 'Edit expense'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        NumField(t('المبلغ', 'المبلغ', 'Amount'), aC, suffix: curSym(cur)),
        CurrencyPicker(t('العملة', 'العملة', 'Currency'), cur, (v) => set(() => cur = v)),
        const SizedBox(height: 14),
        Text(t('صرفتها في شنو؟', 'التصنيف', 'Category'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final c in _cats) PickChip('${c.emoji} ${c.name}', cat == c.key, () => set(() => cat = c.key), color: c.color),
        ]),
        const SizedBox(height: 12),
        TextField(controller: noteC, decoration: InputDecoration(labelText: t('ملاحظة (اختياري)', 'ملاحظة (اختياري)', 'Note (optional)'))),
        const SizedBox(height: 12),
        LifeDateButton(label: t('التاريخ', 'التاريخ', 'Date'), value: date, onPick: (d) => set(() => date = d ?? date), color: SD.orange, last: now.add(const Duration(days: 1))),
        const SizedBox(height: 18),
        Row(children: [
          if (e != null)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: SD.red),
                onPressed: () => Navigator.pop(ctx, false),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(t('امسح', 'حذف', 'Delete')),
              ),
            ),
          if (e != null) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () {
                if (parseNum(aC.text) <= 0) return toast(t('أكتب المبلغ', 'اكتب المبلغ', 'Enter the amount'));
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(t('احفظ', 'حفظ', 'Save')),
            ),
          ),
        ]),
      ]),
    );
    final amount = parseNum(aC.text), note = noteC.text.trim();
    aC.dispose();
    noteC.dispose();
    if (!mounted || ok == null) return;
    final l = _list(s);
    if (ok == false && e != null) return _delete(e['id']);
    final data = {'a': amount, 'cur': cur, 'cat': cat, 'note': note, 'd': dk(date)};
    if (e == null) {
      l.add({'id': newId(), ...data});
      s.awardDaily('expenses_log', 3, tr('تسجيل المصاريف', 'Logged expenses'));
      HapticFeedback.selectionClick();
    } else {
      final i = l.indexWhere((x) => x['id'] == e['id']);
      if (i >= 0) l[i] = {...l[i], ...data};
    }
    _save(s, l);
    s.setData('expenses_cfg', {..._cfg(s), 'last': cur, 'lastCat': cat});
    setState(() {
      _y = date.year;
      _m = date.month;
    });
  }

  void _delete(String id) {
    final s = context.read<AppState>();
    final l = _list(s);
    final i = l.indexWhere((x) => x['id'] == id);
    if (i < 0) return;
    final removed = l.removeAt(i);
    _save(s, l);
    setState(() {});
    undoSnack(t('اتمسح المصروف', 'حُذف المصروف', 'Expense deleted'), () {
      _save(s, _list(s)..add(removed));
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final main = _main(s);
    final sym = curSym(main);
    final all = _list(s);
    final month = _ofMonth(all, _y, _m);
    final py = _m == 1 ? _y - 1 : _y, pm = _m == 1 ? 12 : _m - 1;
    final prev = _ofMonth(all, py, pm);
    double sum(Iterable<Map> l) => l.fold(0.0, (a, e) => a + _inMain(s, e, main));
    final total = sum(month), prevTotal = sum(prev);
    final today = todayPlace();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final isCurrent = _y == today.year && _m == today.month;
    final isFuture = DateTime(_y, _m).isAfter(DateTime(today.year, today.month));
    final days = isCurrent ? today.day : daysInMonth(_y, _m);
    final avg = isFuture ? 0.0 : total / days;
    final projected = isCurrent ? avg * daysInMonth(_y, _m) : total;
    final usd = main == 'USD' ? total : total * s.rate(main, 'USD');
    final budget = numOf(_cfg(s)['budget']);
    final change = prevTotal > 0 ? (total - prevTotal) / prevTotal : null;
    // مقارنة بنفس الفترة من الشهر الفات (للشهر الحالي)
    final prevSame = isCurrent ? sum(prev.where((e) => (parseDk(e['d'])?.day ?? 99) <= today.day)) : prevTotal;

    final byCat = <String, double>{};
    for (final e in month) {
      final k = _cat(e['cat']).key;
      byCat[k] = (byCat[k] ?? 0) + _inMain(s, e, main);
    }
    final catsSorted = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    var shown = [...month]..sort((a, b) => ((b['d'] as String?) ?? '').compareTo((a['d'] as String?) ?? ''));
    if (_catFilter != null) shown = shown.where((e) => _cat(e['cat']).key == _catFilter).toList();
    final byDay = <String, List<Map<String, dynamic>>>{};
    for (final e in shown) {
      byDay.putIfAbsent((e['d'] as String?) ?? '', () => []).add(e);
    }

    String summary() {
      final b = StringBuffer('${t('💰 مصاريف', '💰 مصروفات', '💰 Expenses')} ${fmtMonth(_y, _m)}\n');
      b.writeln('${t('المجموع', 'الإجمالي', 'Total')}: ${fmt(total, 0)} $sym${main == 'USD' ? '' : ' (≈ \$${fmt(usd, 0)})'}');
      b.writeln('${t('المتوسط اليومي', 'المتوسط اليومي', 'Daily average')}: ${fmt(avg, 0)} $sym');
      for (final c in catsSorted) {
        b.writeln('${_cat(c.key).emoji} ${_cat(c.key).name}: ${fmt(c.value, 0)} $sym (${fmt(total == 0 ? 0 : c.value / total * 100, 0)}%)');
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
            child: Text(fmtMonth(_y, _m), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ),
        IconButton(onPressed: () => _shift(1), icon: Icon(rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded), tooltip: t('الشهر الجاي', 'الشهر التالي', 'Next month')),
      ]),
      ResultHero(
        label: t('صرفت الشهر دا', 'إجمالي مصروف الشهر', 'Spent this month'),
        value: '${fmt(total, 0)} $sym',
        sub: [
          if (main != 'USD') '≈ \$${fmt(usd, 2)}',
          '${t('في اليوم', 'يوميًا', 'per day')} ${fmt(avg, 0)} $sym',
          '${month.length} ${t('عملية', 'عملية', 'entries')}',
        ].join(' · '),
        colors: const [SD.orange, SD.henna, SD.coffee],
      ),
      FilledButton.icon(
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_card_rounded),
        label: Text(t('سجّل مصروف', 'سجّل مصروفًا', 'Add expense')),
      ),
      const SizedBox(height: 14),
      SCard(
        title: t('الميزانية', 'الميزانية الشهرية', 'Monthly budget'),
        icon: Icons.account_balance_wallet_rounded,
        color: SD.green,
        trailing: TextButton(
          onPressed: () async {
            final v = await askText(context, t('ميزانية الشهر ($sym)', 'الميزانية الشهرية ($sym)', 'Monthly budget ($sym)'),
                initial: budget > 0 ? fmt(budget, 0).replaceAll(',', '') : '', number: true, hint: t('فاضي = بلا ميزانية', 'فارغ = بدون ميزانية', 'Empty = no budget'));
            if (v == null) return;
            _setCfg(s, 'budget', parseNum(v) > 0 ? parseNum(v) : null);
          },
          child: Text(budget > 0 ? t('غيّر', 'تعديل', 'Change') : t('حدّد', 'تحديد', 'Set')),
        ),
        child: budget <= 0
            ? Text(t('حدّد ميزانية شهرية عشان ننبّهك قبل ما القروش تخلص.', 'حدّد ميزانية شهرية لننبّهك قبل تجاوزها.', 'Set a monthly budget to get warned before overspending.'))
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                PercentBar(
                  '${fmt(total, 0)} / ${fmt(budget, 0)} $sym',
                  total / budget,
                  '${fmt(total / budget * 100, 0)}%',
                  color: total > budget ? SD.red : (total > budget * .8 ? SD.orange : SD.green),
                ),
                InfoRow(t('الباقي', 'المتبقي', 'Remaining'), '${fmt(budget - total, 0)} $sym',
                    icon: Icons.savings_rounded, valueColor: budget - total < 0 ? SD.red : SD.green),
                if (isCurrent && budget - total > 0)
                  InfoRow(t('تقدر تصرف في اليوم', 'المسموح يوميًا', 'You can spend per day'),
                      '${fmt((budget - total) / (daysInMonth(_y, _m) - today.day + 1), 0)} $sym',
                      icon: Icons.today_rounded, hint: t('لحدي آخر الشهر', 'حتى نهاية الشهر', 'until month end')),
                if (isCurrent) InfoRow(t('لو مشيت كدا حتصرف', 'المتوقع بنهاية الشهر', 'Projected month total'), '${fmt(projected, 0)} $sym', icon: Icons.trending_up_rounded,
                    valueColor: projected > budget ? SD.red : null),
                if (total > budget)
                  NoteBox(t('⚠️ عديت الميزانية بـ ${fmt(total - budget, 0)} $sym — خفّف شوية يا زول', '⚠️ تجاوزت الميزانية بمقدار ${fmt(total - budget, 0)} $sym',
                      '⚠️ Over budget by ${fmt(total - budget, 0)} $sym'), kind: NoteKind.danger)
                else if (total > budget * .8)
                  NoteBox(t('قربت تخلّص الميزانية — فاضل ${fmt(budget - total, 0)} $sym بس', 'اقتربت من حدّ الميزانية — المتبقي ${fmt(budget - total, 0)} $sym',
                      'Close to your budget — only ${fmt(budget - total, 0)} $sym left'), kind: NoteKind.warn)
                else if (isCurrent && projected > budget)
                  NoteBox(t('بالمعدل دا حتعدّي الميزانية آخر الشهر', 'بهذا المعدّل ستتجاوز الميزانية بنهاية الشهر', 'At this pace you\'ll exceed the budget by month end'), kind: NoteKind.warn),
              ]),
      ),
      SCard(
        title: t('مقارنة بالشهر الفات', 'مقارنة بالشهر السابق', 'Vs. last month'),
        icon: Icons.compare_arrows_rounded,
        color: SD.nile,
        child: Column(children: [
          InfoRow(fmtMonth(py, pm), '${fmt(prevTotal, 0)} $sym', icon: Icons.history_rounded),
          if (isCurrent && prevTotal > 0)
            InfoRow(t('نفس الفترة الشهر الفات', 'نفس الفترة من الشهر السابق', 'Same period last month'), '${fmt(prevSame, 0)} $sym',
                icon: Icons.date_range_rounded, hint: t('لحدي يوم ${today.day}', 'حتى اليوم ${today.day}', 'up to day ${today.day}')),
          InfoRow(
            t('الفرق', 'الفرق', 'Change'),
            change == null ? '—' : '${change >= 0 ? '▲' : '▼'} ${fmt(change.abs() * 100, 0)}%',
            icon: Icons.percent_rounded,
            valueColor: change == null ? null : (change > 0 ? SD.red : SD.green),
            hint: change == null
                ? t('ما في بيانات للشهر الفات', 'لا بيانات للشهر السابق', 'No data for last month')
                : (change > 0
                    ? t('صرفت أكتر من الشهر الفات', 'أنفقت أكثر من الشهر السابق', 'You spent more than last month')
                    : t('صرفت أقل — عافي منك', 'أنفقت أقل من الشهر السابق', 'You spent less — nice')),
          ),
        ]),
      ),
      if (catsSorted.isNotEmpty)
        SCard(
          title: t('صرفت في شنو؟', 'التوزيع حسب التصنيف', 'By category'),
          icon: Icons.donut_small_rounded,
          color: SD.orange,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            BarChart([
              for (final c in catsSorted.take(7)) Bar(_cat(c.key).emoji, c.value, color: _cat(c.key).color),
            ], color: SD.orange, height: 160, valueText: (v) => _compact(v)),
            const SizedBox(height: 8),
            for (final c in catsSorted)
              InkWell(
                onTap: () => setState(() => _catFilter = _catFilter == c.key ? null : c.key),
                child: PercentBar(
                  '${_cat(c.key).emoji} ${_cat(c.key).name}${_catFilter == c.key ? '  ✓' : ''}',
                  total == 0 ? 0 : c.value / total,
                  '${fmt(c.value, 0)} · ${fmt(total == 0 ? 0 : c.value / total * 100, 0)}%',
                  color: _cat(c.key).color,
                ),
              ),
            Text(t('دوس على تصنيف عشان تفلتر القائمة', 'اضغط على تصنيف لتصفية القائمة', 'Tap a category to filter the list'), style: const TextStyle(fontSize: 11.5)),
          ]),
        ),
      SectionTitle(t('العمليات', 'العمليات', 'Entries'), icon: Icons.receipt_long_rounded,
          trailing: _catFilter == null
              ? null
              : ActionChip(label: Text('${_cat(_catFilter).emoji} ✕'), onPressed: () => setState(() => _catFilter = null))),
      if (shown.isEmpty)
        EmptyHint(Icons.receipt_long_outlined, t('ما في مصاريف مسجّلة في الشهر دا', 'لا توجد مصروفات مسجّلة لهذا الشهر', 'No expenses recorded this month'))
      else
        for (final day in byDay.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Row(children: [
              Expanded(child: Text(parseDk(day.key) == null ? day.key : fmtDateAr(parseDk(day.key)!), style: const TextStyle(fontWeight: FontWeight.w800, color: SD.gold))),
              Text('${fmt(sum(day.value), 0)} $sym', style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ),
          for (final e in day.value) _tile(s, e, main),
        ],
      const SizedBox(height: 10),
      SCard(
        title: t('العملة الأساسية', 'العملة الأساسية', 'Main currency'),
        icon: Icons.currency_exchange_rounded,
        color: SD.teal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CurrencyPicker(t('اعرض المجاميع بـ', 'عرض الإجماليات بـ', 'Show totals in'), main, (v) => _setCfg(s, 'main', v)),
          const SizedBox(height: 6),
          Text(
            t('المصاريف بعملات تانية بتتحوّل بسعر الصرف المحفوظ في التطبيق${main == 'SDG' ? (s.useParallel && s.sdgParallel != null ? ' (السعر الموازي)' : ' (السعر الرسمي)') : ''}.',
                'تُحوَّل المصروفات بالعملات الأخرى بسعر الصرف المحفوظ في التطبيق.', 'Expenses in other currencies are converted using the app\'s saved exchange rates.'),
            style: const TextStyle(fontSize: 12),
          ),
        ]),
      ),
      if (month.isNotEmpty) ShareBar(summary),
      const SizedBox(height: 8),
      NoteBox(
        t('سجّل أول بأول حتى الحاجات الصغيرة (رصيد، ركشة، شاي) — هي البتاكل القروش من غير ما تحس.',
            'سجّل أولًا بأول حتى المصروفات الصغيرة؛ فهي التي تستنزف المال دون أن تشعر.',
            'Log as you go, even small things (airtime, rides, tea) — they add up quietly.'),
        kind: NoteKind.tip,
      ),
    ]);
  }

  String _compact(double v) {
    if (v == 0) return '';
    if (v >= 1e6) return '${fmt(v / 1e6, 1)}M';
    if (v >= 1e3) return '${fmt(v / 1e3, 1)}K';
    return fmt(v, 0);
  }

  Widget _tile(AppState s, Map<String, dynamic> e, String main) {
    final c = _cat(e['cat']);
    final cur = (e['cur'] as String?) ?? 'SDG';
    final note = (e['note'] as String?) ?? '';
    return Dismissible(
      key: ValueKey(e['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: AlignmentDirectional.centerEnd,
        decoration: BoxDecoration(color: SD.red.withValues(alpha: .85), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _delete(e['id']),
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.color.withValues(alpha: .35))),
        child: ListTile(
          onTap: () => _edit(e),
          leading: CircleAvatar(backgroundColor: c.color.withValues(alpha: .2), child: Text(c.emoji, style: const TextStyle(fontSize: 20))),
          title: Text(note.isEmpty ? c.name : note, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: note.isEmpty ? null : Text(c.name, style: const TextStyle(fontSize: 12)),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${fmt(numOf(e['a']), 2)} ${curSym(cur)}', style: const TextStyle(fontWeight: FontWeight.w800)),
            if (cur != main) Text('≈ ${fmt(_inMain(s, e, main), 0)} ${curSym(main)}', style: const TextStyle(fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}
