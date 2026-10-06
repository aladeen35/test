import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../money/money_common.dart' show CurrencyPicker, curSym;
import 'life_common.dart';

/// اتجاه الدين: in = ليك عند زول، out = عليك لزول
enum _V { owedMe, iOwe, people, closed }

class DebtsTool extends StatefulWidget {
  const DebtsTool({super.key});
  @override
  State<DebtsTool> createState() => _DebtsToolState();
}

class _DebtsToolState extends State<DebtsTool> {
  _V _view = _V.owedMe;
  String? _person;

  List<Map<String, dynamic>> _list(AppState s) => mapList(s.getData<List>('debts_list'));
  void _save(AppState s, List<Map<String, dynamic>> l) => s.setData('debts_list', l);
  String _main(AppState s) => s.getData<String>('debts_main') ?? 'SDG';

  double _paid(Map d) => mapList(d['pays']).fold(0.0, (a, p) => a + numOf(p['a']));
  double _rem(Map d) => (numOf(d['a']) - _paid(d)).clamp(0, double.infinity).toDouble();
  double _conv(AppState s, double v, String cur, String main) => cur == main ? v : v * s.rate(cur, main);
  String _key(String p) => p.trim().toLowerCase();

  void _update(String id, Map<String, dynamic> Function(Map<String, dynamic>) f) {
    final s = context.read<AppState>();
    final l = _list(s);
    final i = l.indexWhere((x) => x['id'] == id);
    if (i < 0) return;
    l[i] = f(l[i]);
    _save(s, l);
    setState(() {});
  }

  Future<void> _edit([Map<String, dynamic>? d]) async {
    final s = context.read<AppState>();
    final personC = TextEditingController(text: d?['person'] ?? (_person ?? ''));
    final aC = TextEditingController(text: d == null ? '' : fmt(numOf(d['a']), 2).replaceAll(',', ''));
    final noteC = TextEditingController(text: d?['note'] ?? '');
    var dir = (d?['dir'] as String?) ?? (_view == _V.iOwe ? 'out' : 'in');
    var cur = (d?['cur'] as String?) ?? _main(s);
    var date = parseDk(d?['d']) ?? todayPlace();
    DateTime? due = parseDk(d?['due']);
    final names = {for (final x in _list(s)) (x['person'] as String?) ?? ''}..remove('');
    final ok = await lifeSheet<bool>(
      context,
      d == null ? t('دين جديد', 'دين جديد', 'New debt') : t('عدّل الدين', 'تعديل الدين', 'Edit debt'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 8, children: [
          PickChip(t('📥 ليك عند زول', '📥 لك عند شخص', '📥 Someone owes me'), dir == 'in', () => set(() => dir = 'in'), color: SD.green),
          PickChip(t('📤 عليك لزول', '📤 عليك لشخص', '📤 I owe someone'), dir == 'out', () => set(() => dir = 'out'), color: SD.red),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: personC,
          autofocus: d == null,
          decoration: InputDecoration(labelText: t('اسم الزول', 'اسم الشخص', 'Person\'s name'), prefixIcon: const Icon(Icons.person_rounded)),
        ),
        if (names.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (final n in names.take(12)) ActionChip(label: Text(n), onPressed: () => set(() => personC.text = n)),
          ]),
        ],
        const SizedBox(height: 12),
        NumField(t('المبلغ', 'المبلغ', 'Amount'), aC, suffix: curSym(cur)),
        CurrencyPicker(t('العملة', 'العملة', 'Currency'), cur, (v) => set(() => cur = v)),
        const SizedBox(height: 12),
        LifeDateButton(label: t('تاريخ الدين', 'تاريخ الدين', 'Date'), value: date, onPick: (v) => set(() => date = v ?? date), color: SD.nile),
        const SizedBox(height: 8),
        LifeDateButton(label: t('موعد الترجيع (اختياري)', 'موعد السداد (اختياري)', 'Due date (optional)'), value: due, clearable: true, onPick: (v) => set(() => due = v), color: SD.orange),
        const SizedBox(height: 10),
        TextField(controller: noteC, decoration: InputDecoration(labelText: t('ملاحظة (اختياري)', 'ملاحظة (اختياري)', 'Note (optional)'))),
        const SizedBox(height: 18),
        Row(children: [
          if (d != null)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: SD.red),
                onPressed: () => Navigator.pop(ctx, false),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(t('امسح', 'حذف', 'Delete')),
              ),
            ),
          if (d != null) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () {
                if (personC.text.trim().isEmpty) return toast(t('أكتب اسم الزول', 'اكتب اسم الشخص', 'Enter the name'));
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
    final person = personC.text.trim(), amount = parseNum(aC.text), note = noteC.text.trim();
    personC.dispose();
    aC.dispose();
    noteC.dispose();
    if (!mounted || ok == null) return;
    if (ok == false && d != null) {
      if (!await confirmAsk(context, t('نمسح الدين؟', 'حذف الدين؟', 'Delete debt?'),
          t('حيتمسح الدين وكل الدفعات بتاعتو.', 'سيُحذف الدين وجميع دفعاته.', 'The debt and its payments will be deleted.'))) {
        return;
      }
      final l = _list(s);
      final i = l.indexWhere((x) => x['id'] == d['id']);
      if (i < 0) return;
      final removed = l.removeAt(i);
      _save(s, l);
      setState(() {});
      undoSnack(t('اتمسح الدين', 'حُذف الدين', 'Debt deleted'), () {
        _save(s, _list(s)..add(removed));
        if (mounted) setState(() {});
      });
      return;
    }
    final data = {'person': person, 'dir': dir, 'a': amount, 'cur': cur, 'd': dk(date), 'due': due == null ? null : dk(due!), 'note': note};
    final l = _list(s);
    if (d == null) {
      l.add({'id': newId(), ...data, 'pays': <Map>[], 'closed': false});
      s.awardDaily('debts_log', 2, tr('تسجيل دين', 'Logged a debt'));
    } else {
      final i = l.indexWhere((x) => x['id'] == d['id']);
      if (i >= 0) {
        l[i] = {...l[i], ...data};
        l[i]['closed'] = _rem(l[i]) <= 0.0001;
      }
    }
    _save(s, l);
    setState(() => _view = dir == 'in' ? _V.owedMe : _V.iOwe);
  }

  Future<void> _addPayment(Map<String, dynamic> d) async {
    final rem = _rem(d);
    final aC = TextEditingController(text: fmt(rem, 2).replaceAll(',', ''));
    final nC = TextEditingController();
    var date = todayPlace();
    final cur = (d['cur'] as String?) ?? 'SDG';
    final ok = await lifeSheet<bool>(
      context,
      t('دفعة جديدة — ${d['person']}', 'دفعة جديدة — ${d['person']}', 'New payment — ${d['person']}'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InfoRow(t('الباقي', 'المتبقي', 'Remaining'), '${fmt(rem, 2)} ${curSym(cur)}', icon: Icons.account_balance_wallet_rounded),
        const SizedBox(height: 10),
        NumField(t('قدر شنو اندفع؟', 'المبلغ المدفوع', 'Amount paid'), aC, suffix: curSym(cur)),
        Wrap(spacing: 6, children: [
          for (final f in [.25, .5, 1.0])
            ActionChip(
              label: Text(f == 1 ? t('كلّو', 'الكل', 'All') : '${(f * 100).round()}%'),
              onPressed: () => set(() => aC.text = fmt(rem * f, 2).replaceAll(',', '')),
            ),
        ]),
        const SizedBox(height: 10),
        TextField(controller: nC, decoration: InputDecoration(labelText: t('ملاحظة (اختياري)', 'ملاحظة (اختياري)', 'Note (optional)'))),
        const SizedBox(height: 10),
        LifeDateButton(label: t('تاريخ الدفعة', 'تاريخ الدفعة', 'Payment date'), value: date, onPick: (v) => set(() => date = v ?? date), color: SD.green),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            if (parseNum(aC.text) <= 0) return toast(t('أكتب المبلغ', 'اكتب المبلغ', 'Enter the amount'));
            Navigator.pop(ctx, true);
          },
          icon: const Icon(Icons.payments_rounded),
          label: Text(t('سجّل الدفعة', 'تسجيل الدفعة', 'Record payment')),
        ),
      ]),
    );
    final a = parseNum(aC.text), note = nC.text.trim();
    aC.dispose();
    nC.dispose();
    if (!mounted || ok != true) return;
    _pay(d, a.clamp(0, rem).toDouble(), note, date);
  }

  void _pay(Map<String, dynamic> d, double a, String note, DateTime date) {
    if (a <= 0) return;
    final s = context.read<AppState>();
    var closedNow = false;
    _update(d['id'], (x) {
      final pays = mapList(x['pays'])..add({'a': a, 'd': dk(date), 'n': note});
      x['pays'] = pays;
      if (_rem(x) <= 0.0001) {
        x['closed'] = true;
        x['closedAt'] = dk(todayPlace());
        closedNow = true;
      }
      return x;
    });
    HapticFeedback.mediumImpact();
    if (closedNow) {
      if (d['dir'] == 'out') s.award(5, tr('سداد دين', 'Paid off a debt'));
      toast(d['dir'] == 'out'
          ? t('🤝 خلّصت الدين! ربنا يبارك ليك', '🤝 سدّدت الدين كاملًا، بارك الله لك', '🤝 Debt fully paid — well done')
          : t('🤝 الدين اتقفل — رجعت قروشك', '🤝 أُغلق الدين — استرددت مالك', '🤝 Debt settled — you got paid back'));
    } else {
      toast(t('اتسجلت الدفعة ✓', 'سُجّلت الدفعة ✓', 'Payment recorded ✓'));
    }
  }

  String _reminder(Map d) {
    final cur = (d['cur'] as String?) ?? 'SDG';
    final amt = '${fmt(_rem(d), 2)} ${curSym(cur)}';
    final date = parseDk(d['d']);
    final due = parseDk(d['due']);
    final p = d['person'];
    if (d['dir'] == 'in') {
      return t(
        'يا زول $p، السلام عليكم 🌷\nإن شاء الله تكون كويس. ما تنسى القروش الـ$amt${date == null ? '' : ' من يوم ${fmtDateAr(date, weekday: false)}'}${due == null ? '' : '، وكان الاتفاق نرجّعها يوم ${fmtDateAr(due, weekday: false)}'}.\nلو ظروفك صعبة هسي ما في مشكلة، بس كلّمني نتفاهم. ربنا يسهّل عليك 🙏',
        'أخي $p، السلام عليكم ورحمة الله 🌷\nأرجو أن تكون بخير. هذا تذكير لطيف بالمبلغ المتبقي $amt${date == null ? '' : ' بتاريخ ${fmtDateAr(date, weekday: false)}'}${due == null ? '' : '، وكان موعد السداد المتفق عليه ${fmtDateAr(due, weekday: false)}'}.\nإن كانت ظروفك صعبة فلا بأس، فقط تواصل معي لنتفاهم. يسّر الله أمرك 🙏',
        'Hi $p, hope you\'re doing well 🌷\nJust a friendly reminder about the remaining $amt${date == null ? '' : ' from ${fmtDateAr(date, weekday: false)}'}${due == null ? '' : ', which we agreed to settle by ${fmtDateAr(due, weekday: false)}'}.\nIf things are tight right now, no worries — just let me know and we\'ll work it out 🙏',
      );
    }
    return t(
      'يا $p، السلام عليكم 🌷\nما نسيت قروشك الـ$amt — إن شاء الله برجّعها ${due == null ? 'قريب' : 'قبل ${fmtDateAr(due, weekday: false)}'}. شكرًا على صبرك ووقفتك معاي 🙏',
      'أخي $p، السلام عليكم 🌷\nلم أنسَ المبلغ المتبقي لك $amt، وسأسدّده بإذن الله ${due == null ? 'قريبًا' : 'قبل ${fmtDateAr(due, weekday: false)}'}. جزاك الله خيرًا على صبرك 🙏',
      'Hi $p 🌷\nI haven\'t forgotten the $amt I owe you — I\'ll pay it back ${due == null ? 'soon' : 'by ${fmtDateAr(due, weekday: false)}'}, God willing. Thanks for your patience 🙏',
    );
  }

  Future<void> _details(Map<String, dynamic> d0) async {
    await lifeSheet<void>(context, '${d0['person']}', (ctx, set) {
      final s = ctx.watch<AppState>();
      final d = _list(s).where((x) => x['id'] == d0['id']).firstOrNull;
      if (d == null) return const SizedBox();
      final cur = (d['cur'] as String?) ?? 'SDG';
      final sym = curSym(cur);
      final rem = _rem(d), paid = _paid(d), total = numOf(d['a']);
      final pays = mapList(d['pays']);
      final due = parseDk(d['due']);
      final today = todayPlace();
      final isIn = d['dir'] == 'in';
      final closed = d['closed'] == true;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: (isIn ? SD.green : SD.red).withValues(alpha: .12), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text(isIn ? t('ليك عندو', 'لك عنده', 'Owes you') : t('عليك ليهو', 'عليك له', 'You owe'), style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${fmt(rem, 2)} $sym', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: readable(ctx, isIn ? SD.green : SD.red))),
            if (closed) Text(t('✅ اتقفل', '✅ مُسدَّد', '✅ Settled'), style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: total == 0 ? 0 : (paid / total).clamp(0, 1).toDouble(), minHeight: 8, color: SD.green, backgroundColor: SD.green.withValues(alpha: .15)),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        InfoRow(t('المبلغ الأصلي', 'المبلغ الأصلي', 'Original amount'), '${fmt(total, 2)} $sym', icon: Icons.request_quote_rounded),
        InfoRow(t('اندفع', 'المدفوع', 'Paid'), '${fmt(paid, 2)} $sym', icon: Icons.payments_rounded, valueColor: SD.green),
        if (parseDk(d['d']) != null) InfoRow(t('التاريخ', 'التاريخ', 'Date'), fmtDateAr(parseDk(d['d'])!), icon: Icons.event_rounded),
        if (due != null)
          InfoRow(
            t('موعد الترجيع', 'موعد السداد', 'Due'),
            fmtDateAr(due),
            icon: Icons.alarm_rounded,
            valueColor: !closed && dayDiff(today, due) < 0 ? SD.red : null,
            hint: closed
                ? null
                : (dayDiff(today, due) < 0
                    ? t('متأخر ${-dayDiff(today, due)} يوم', 'متأخر ${-dayDiff(today, due)} يومًا', '${-dayDiff(today, due)} days overdue')
                    : t('فاضل ${dayDiff(today, due)} يوم', 'متبقٍ ${dayDiff(today, due)} يومًا', '${dayDiff(today, due)} days left')),
          ),
        if (((d['note'] as String?) ?? '').isNotEmpty) InfoRow(t('ملاحظة', 'ملاحظة', 'Note'), '${d['note']}', icon: Icons.notes_rounded),
        const SizedBox(height: 10),
        Text(t('سجل الدفعات', 'سجل الدفعات', 'Payment history'), style: const TextStyle(fontWeight: FontWeight.w800)),
        if (pays.isEmpty)
          Padding(padding: const EdgeInsets.all(8), child: Text(t('لسه ما في دفعات', 'لا توجد دفعات بعد', 'No payments yet')))
        else
          for (var i = pays.length - 1; i >= 0; i--)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_rounded, color: SD.green),
              title: Text('${fmt(numOf(pays[i]['a']), 2)} $sym', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text([
                if (parseDk(pays[i]['d']) != null) fmtDateAr(parseDk(pays[i]['d'])!),
                if (((pays[i]['n'] as String?) ?? '').isNotEmpty) '${pays[i]['n']}',
              ].join(' · ')),
              trailing: IconButton(
                tooltip: t('امسح الدفعة', 'حذف الدفعة', 'Remove payment'),
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => _update(d['id'], (x) {
                  final p = mapList(x['pays'])..removeAt(i);
                  x['pays'] = p;
                  x['closed'] = _rem(x) <= 0.0001;
                  return x;
                }),
              ),
            ),
        const SizedBox(height: 12),
        if (!closed)
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(onPressed: () => _addPayment(d), icon: const Icon(Icons.add_rounded), label: Text(t('دفعة', 'دفعة جزئية', 'Payment'))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  if (!await confirmAsk(ctx, t('نقفل الدين؟', 'إغلاق الدين؟', 'Settle debt?'),
                      t('حنسجّل دفعة بالباقي ${fmt(rem, 2)} $sym ونقفلو.', 'ستُسجَّل دفعة بالمتبقي ${fmt(rem, 2)} $sym ويُغلق الدين.', 'A payment of the remaining ${fmt(rem, 2)} $sym will be recorded.'),
                      danger: false)) {
                    return;
                  }
                  _pay(d, rem, t('سداد كامل', 'سداد كامل', 'Settled'), todayPlace());
                },
                icon: const Icon(Icons.handshake_rounded),
                label: Text(t('اتقفل', 'تسوية', 'Settle')),
              ),
            ),
          ])
        else
          OutlinedButton.icon(
            onPressed: () => _update(d['id'], (x) => x..['closed'] = false),
            icon: const Icon(Icons.lock_open_rounded),
            label: Text(t('افتحو تاني', 'إعادة فتح', 'Reopen')),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            Navigator.pop(ctx);
            await _edit(d);
          },
          icon: const Icon(Icons.edit_rounded),
          label: Text(t('عدّل أو امسح', 'تعديل أو حذف', 'Edit or delete')),
        ),
        if (!closed) ...[
          const SizedBox(height: 14),
          Text(isIn ? t('رسالة تذكير لطيفة', 'رسالة تذكير لطيفة', 'Polite reminder') : t('رسالة طمأنة', 'رسالة طمأنة', 'Reassurance message'),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: SD.gold.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)),
            child: Text(_reminder(d), style: const TextStyle(height: 1.6)),
          ),
          ShareBar(() => _reminder(d)),
        ],
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final main = _main(s);
    final msym = curSym(main);
    final all = _list(s);
    final open = all.where((d) => d['closed'] != true).toList();
    final today = todayPlace();

    double sumDir(String dir) => open.where((d) => d['dir'] == dir).fold(0.0, (a, d) => a + _conv(s, _rem(d), (d['cur'] as String?) ?? 'SDG', main));
    final owedMe = sumDir('in'), iOwe = sumDir('out'), net = owedMe - iOwe;
    final overdue = open.where((d) {
      final due = parseDk(d['due']);
      return due != null && dayDiff(today, due) < 0;
    }).toList();

    // مجاميع حسب العملة
    final perCur = <String, (double, double)>{};
    for (final d in open) {
      final c = (d['cur'] as String?) ?? 'SDG';
      final v = perCur[c] ?? (0.0, 0.0);
      perCur[c] = d['dir'] == 'in' ? (v.$1 + _rem(d), v.$2) : (v.$1, v.$2 + _rem(d));
    }

    // حسب الشخص
    final people = <String, Map<String, dynamic>>{};
    for (final d in all) {
      final k = _key('${d['person']}');
      final p = people.putIfAbsent(k, () => {'name': d['person'], 'in': 0.0, 'out': 0.0, 'n': 0, 'open': 0});
      p['n'] = p['n'] + 1;
      if (d['closed'] != true) {
        p['open'] = p['open'] + 1;
        final v = _conv(s, _rem(d), (d['cur'] as String?) ?? 'SDG', main);
        p[d['dir'] == 'in' ? 'in' : 'out'] = (p[d['dir'] == 'in' ? 'in' : 'out'] as double) + v;
      }
    }
    final peopleSorted = people.values.toList()
      ..sort((a, b) => ((b['in'] as double) + (b['out'] as double)).compareTo((a['in'] as double) + (a['out'] as double)));

    List<Map<String, dynamic>> shown = switch (_view) {
      _V.owedMe => open.where((d) => d['dir'] == 'in').toList(),
      _V.iOwe => open.where((d) => d['dir'] == 'out').toList(),
      _V.closed => all.where((d) => d['closed'] == true).toList(),
      _V.people => <Map<String, dynamic>>[],
    };
    if (_person != null) shown = shown.where((d) => _key('${d['person']}') == _person).toList();
    shown.sort((a, b) => ((a['due'] as String?) ?? '9999').compareTo((b['due'] as String?) ?? '9999'));

    return ToolList(children: [
      ResultHero(
        label: net >= 0 ? t('صافي ليك', 'الصافي لصالحك', 'Net in your favor') : t('صافي عليك', 'الصافي عليك', 'Net you owe'),
        value: '${fmt(net.abs(), 0)} $msym',
        sub: '${t('ليك', 'لك', 'Owed to you')} ${fmt(owedMe, 0)} · ${t('عليك', 'عليك', 'You owe')} ${fmt(iOwe, 0)}',
        colors: net >= 0 ? const [SD.green, SD.teal, SD.nile] : const [SD.red, SD.henna, SD.coffee],
      ),
      StatGrid([
        StatChip(fmt(owedMe, 0), t('ليك عند الناس', 'لك عند الآخرين', 'Owed to you'), color: SD.green, icon: Icons.call_received_rounded),
        StatChip(fmt(iOwe, 0), t('عليك للناس', 'عليك للآخرين', 'You owe'), color: SD.red, icon: Icons.call_made_rounded),
        StatChip('${overdue.length}', t('متأخرة', 'متأخرة', 'Overdue'), color: SD.orange, icon: Icons.alarm_rounded),
      ]),
      const SizedBox(height: 12),
      FilledButton.icon(
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: Text(t('سجّل دين', 'تسجيل دين', 'Add a debt')),
      ),
      if (overdue.isNotEmpty)
        NoteBox(
          t('في ${overdue.length} دين فات موعدو: ${overdue.map((d) => d['person']).toSet().join('، ')}',
              'هناك ${overdue.length} دين تجاوز موعده: ${overdue.map((d) => d['person']).toSet().join('، ')}',
              '${overdue.length} overdue: ${overdue.map((d) => d['person']).toSet().join(', ')}'),
          kind: NoteKind.warn,
        ),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final v in _V.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: PickChip(
                switch (v) {
                  _V.owedMe => '📥 ${t('ليك', 'لك', 'Owed to me')} (${open.where((d) => d['dir'] == 'in').length})',
                  _V.iOwe => '📤 ${t('عليك', 'عليك', 'I owe')} (${open.where((d) => d['dir'] == 'out').length})',
                  _V.people => '👥 ${t('الناس', 'الأشخاص', 'People')} (${people.length})',
                  _V.closed => '✅ ${t('المقفولة', 'المُسدَّدة', 'Settled')} (${all.length - open.length})',
                },
                _view == v,
                () => setState(() => _view = v),
                color: switch (v) { _V.owedMe => SD.green, _V.iOwe => SD.red, _V.people => SD.nile, _V.closed => SD.teal },
              ),
            ),
        ]),
      ),
      if (_person != null && _view != _V.people)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: InputChip(
              avatar: const Icon(Icons.person_rounded, size: 18),
              label: Text('${people[_person]?['name'] ?? _person}'),
              onDeleted: () => setState(() => _person = null),
            ),
          ),
        ),
      const SizedBox(height: 10),
      if (_view == _V.people)
        if (peopleSorted.isEmpty)
          EmptyHint(Icons.people_outline_rounded, t('لسه ما في زول', 'لا يوجد أشخاص بعد', 'No one yet'))
        else
          for (final p in peopleSorted) _personTile(p, msym)
      else if (shown.isEmpty)
        EmptyHint(
          Icons.handshake_outlined,
          switch (_view) {
            _V.owedMe => t('ما في زول عليهو قروش ليك', 'لا ديون لك عند أحد', 'Nobody owes you'),
            _V.iOwe => t('الحمد لله ما عليك ديون 👌', 'الحمد لله، لا ديون عليك 👌', 'You owe nothing 👌'),
            _ => t('ما في ديون مقفولة', 'لا ديون مُسدَّدة', 'No settled debts'),
          },
        )
      else
        for (final d in shown) _debtTile(d, today),
      if (perCur.length > 1 || (perCur.isNotEmpty && perCur.keys.first != main))
        SCard(
          title: t('حسب العملة', 'حسب العملة', 'By currency'),
          icon: Icons.currency_exchange_rounded,
          color: SD.teal,
          child: Column(children: [
            for (final e in perCur.entries)
              InfoRow('${curSym(e.key)} ${e.key}', '+${fmt(e.value.$1, 2)}  /  −${fmt(e.value.$2, 2)}', hint: t('ليك / عليك', 'لك / عليك', 'owed to you / you owe')),
          ]),
        ),
      SCard(
        title: t('عملة المجاميع', 'عملة الإجماليات', 'Totals currency'),
        icon: Icons.tune_rounded,
        color: SD.nile,
        child: CurrencyPicker(t('اعرض المجاميع بـ', 'عرض الإجماليات بـ', 'Show totals in'), main, (v) => s.setData('debts_main', v)),
      ),
      NoteBox(
        '﴿يَا أَيُّهَا الَّذِينَ آمَنُوا إِذَا تَدَايَنتُم بِدَيْنٍ إِلَىٰ أَجَلٍ مُّسَمًّى فَاكْتُبُوهُ﴾ ${isEn ? '\n— Qur\'an 2:282: write down debts with a fixed term.' : '[البقرة: 282]'}',
        kind: NoteKind.info,
      ),
    ]);
  }

  Widget _personTile(Map<String, dynamic> p, String msym) {
    final inn = p['in'] as double, out = p['out'] as double;
    final net = inn - out;
    final c = net > 0 ? SD.green : (net < 0 ? SD.red : SD.teal);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.withValues(alpha: .35))),
      child: ListTile(
        onTap: () => setState(() {
          _person = _key('${p['name']}');
          _view = out > inn ? _V.iOwe : (p['open'] == 0 ? _V.closed : _V.owedMe);
        }),
        leading: CircleAvatar(
          backgroundColor: c.withValues(alpha: .2),
          child: Text('${p['name']}'.characters.first, style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, c))),
        ),
        title: Text('${p['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text([
          if (inn > 0) '${t('ليك', 'لك', 'owes you')} ${fmt(inn, 0)}',
          if (out > 0) '${t('عليك', 'عليك', 'you owe')} ${fmt(out, 0)}',
          t('${p['n']} عملية', '${p['n']} عملية', '${p['n']} records'),
        ].join(' · ')),
        trailing: Text(net == 0 ? '✓' : '${net > 0 ? '+' : '−'}${fmt(net.abs(), 0)} $msym',
            style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, c))),
      ),
    );
  }

  Widget _debtTile(Map<String, dynamic> d, DateTime today) {
    final isIn = d['dir'] == 'in';
    final c = isIn ? SD.green : SD.red;
    final cur = (d['cur'] as String?) ?? 'SDG';
    final total = numOf(d['a']), rem = _rem(d);
    final due = parseDk(d['due']);
    final closed = d['closed'] == true;
    String? dueText;
    var late = false;
    if (due != null && !closed) {
      final diff = dayDiff(today, due);
      late = diff < 0;
      dueText = diff < 0
          ? t('متأخر ${-diff} يوم', 'متأخر ${-diff} يومًا', '${-diff}d overdue')
          : diff == 0
              ? t('موعدو الليلة', 'يستحق اليوم', 'Due today')
              : t('بعد $diff يوم', 'بعد $diff يومًا', 'in $diff days');
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: (late ? SD.orange : c).withValues(alpha: .45))),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _details(d),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: c.withValues(alpha: .18),
                child: Icon(isIn ? Icons.call_received_rounded : Icons.call_made_rounded, color: readable(context, c)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${d['person']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(
                    [
                      if (parseDk(d['d']) != null) fmtShort(parseDk(d['d'])!),
                      ?dueText,
                      if (((d['note'] as String?) ?? '').isNotEmpty) '${d['note']}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: late ? readable(context, SD.orange) : null, fontWeight: late ? FontWeight.w700 : null),
                  ),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${fmt(closed ? total : rem, 2)} ${curSym(cur)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: readable(context, c))),
                if (!closed && rem < total) Text(t('من ${fmt(total, 0)}', 'من ${fmt(total, 0)}', 'of ${fmt(total, 0)}'), style: const TextStyle(fontSize: 11)),
              ]),
            ]),
            if (!closed && rem < total) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: ((total - rem) / total).clamp(0, 1).toDouble(), minHeight: 6, color: c, backgroundColor: c.withValues(alpha: .14)),
              ),
            ],
            if (!closed)
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton.icon(onPressed: () => _addPayment(d), icon: const Icon(Icons.add_rounded, size: 18), label: Text(t('دفعة', 'دفعة', 'Payment'))),
                if (isIn)
                  TextButton.icon(
                    onPressed: () => _details(d),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(t('ذكّرو', 'تذكير', 'Remind')),
                  ),
              ]),
          ]),
        ),
      ),
    );
  }
}
