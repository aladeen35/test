import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'plan_common.dart';

const _emojis = ['💰', '🏠', '🚗', '🕋', '💍', '🎓', '📱', '💻', '✈️', '🐑', '🛺', '🏥', '🎁', '🛋️', '🌾', '🐄'];
const _milestones = [25, 50, 75, 100];

class SavingsGoalsTool extends StatefulWidget {
  const SavingsGoalsTool({super.key});
  @override
  State<SavingsGoalsTool> createState() => _SavingsGoalsToolState();
}

class _SavingsGoalsToolState extends State<SavingsGoalsTool> {
  String? _sel;

  List<Map<String, dynamic>> _goals(AppState s) => mapList(s.getData<List>('savings_goals_list'));
  void _save(AppState s, List<Map<String, dynamic>> l) => s.setData('savings_goals_list', l);

  static double saved(Map g) => numOf(g['start']) + mapList(g['tx']).fold(0.0, (a, x) => a + numOf(x['a']));

  Map<String, dynamic>? _current(List<Map<String, dynamic>> l) {
    if (l.isEmpty) return null;
    return l.firstWhere((g) => g['id'] == _sel, orElse: () => l.first);
  }

  void _put(AppState s, Map<String, dynamic> g) {
    final l = _goals(s);
    final i = l.indexWhere((x) => x['id'] == g['id']);
    if (i >= 0) {
      l[i] = g;
    } else {
      l.add(g);
    }
    _save(s, l);
  }

  Future<void> _editGoal([Map<String, dynamic>? g]) async {
    final s = context.read<AppState>();
    final nameC = TextEditingController(text: g?['name'] ?? '');
    final targetC = TextEditingController(text: g == null ? '' : rawNum(numOf(g['target'])));
    final startC = TextEditingController(text: g == null ? '' : rawNum(numOf(g['start'])));
    final curC = TextEditingController(text: (g?['cur'] as String?) ?? (s.getData<String>('savings_goals_cur') ?? tr('ج.س', 'SDG')));
    var emoji = (g?['emoji'] as String?) ?? _emojis.first;
    var color = intOf(g?['color'], _goals(s).length);
    DateTime? deadline = parseDk(g?['deadline']);
    final today = todayPlace();
    final ok = await lifeSheet<bool>(
      context,
      g == null ? t('هدف ادخار جديد', 'هدف ادخار جديد', 'New savings goal') : t('عدّل الهدف', 'تعديل الهدف', 'Edit goal'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: nameC,
          decoration: InputDecoration(labelText: t('اسم الهدف', 'اسم الهدف', 'Goal name'), hintText: t('مثلًا: عمرة، ركشة، زواج، لابتوب', 'مثلًا: عمرة، سيارة، زواج، حاسوب', 'e.g. Umrah, car, wedding, laptop')),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final e in _emojis)
            ChoiceChip(label: Text(e, style: const TextStyle(fontSize: 18)), selected: emoji == e, onSelected: (_) => set(() => emoji = e)),
        ]),
        const SizedBox(height: 12),
        NumField(t('المبلغ المطلوب', 'المبلغ المستهدف', 'Target amount'), targetC),
        NumField(t('عندك كم هسي؟ (اختياري)', 'المبلغ الموجود حاليًا (اختياري)', 'Already saved (optional)'), startC),
        TextField(
          controller: curC,
          decoration: InputDecoration(labelText: t('العملة (أكتبها زي ما داير)', 'العملة (كما تريد عرضها)', 'Currency label'), hintText: 'SDG, \$, SAR, ج.س'),
        ),
        const SizedBox(height: 12),
        LifeDateButton(
          label: t('آخر موعد (اختياري)', 'الموعد النهائي (اختياري)', 'Deadline (optional)'),
          value: deadline,
          clearable: true,
          first: today,
          last: DateTime(today.year + 30),
          color: SD.nile,
          onPick: (d) => set(() => deadline = d),
        ),
        const SizedBox(height: 12),
        ColorDots(color, (v) => set(() => color = v)),
        const SizedBox(height: 18),
        sheetButtons(ctx,
            onSave: () {
              if (nameC.text.trim().isEmpty) return toast(t('أكتب اسم الهدف', 'اكتب اسم الهدف', 'Enter a goal name'));
              if (parseNum(targetC.text) <= 0) return toast(t('أكتب المبلغ المطلوب', 'اكتب المبلغ المستهدف', 'Enter the target amount'));
              Navigator.pop(ctx, true);
            },
            onDelete: g == null ? null : () => Navigator.pop(ctx, false)),
      ]),
    );
    final name = nameC.text.trim(), target = parseNum(targetC.text), start = parseNum(startC.text), cur = curC.text.trim();
    nameC.dispose();
    targetC.dispose();
    startC.dispose();
    curC.dispose();
    if (!mounted || ok == null) return;
    if (ok == false && g != null) {
      if (!await confirmAsk(context, t('تمسح الهدف؟', 'حذف الهدف؟', 'Delete goal?'), '${g['emoji']} ${g['name']}')) return;
      _save(s, _goals(s)..removeWhere((x) => x['id'] == g['id']));
      setState(() => _sel = null);
      return;
    }
    final data = <String, dynamic>{
      ...?g,
      'name': name,
      'emoji': emoji,
      'target': target,
      'start': start,
      'cur': cur,
      'deadline': deadline == null ? null : dk(deadline!),
      'color': color,
    };
    if (g == null) {
      data['id'] = newId();
      data['created'] = dk(today);
      data['tx'] = <Map>[];
      data['ms'] = <int>[];
      s.award(5, tr('هدف ادخار جديد', 'New savings goal'));
    }
    s.setData('savings_goals_cur', cur);
    _checkMilestones(s, data);
    _put(s, data);
    setState(() => _sel = data['id']);
  }

  void _checkMilestones(AppState s, Map<String, dynamic> g) {
    final target = numOf(g['target']);
    if (target <= 0) return;
    final pct = saved(g) / target * 100;
    final ms = List<int>.from((g['ms'] as List?)?.map((e) => (e as num).toInt()) ?? const <int>[]);
    for (final m in _milestones) {
      if (pct >= m && !ms.contains(m)) {
        ms.add(m);
        s.award(m == 100 ? 50 : 10, '${tr('هدف ادخار', 'Savings goal')} ${g['name']} $m%');
        toast(m == 100
            ? t('🎉 مبروك! كمّلت هدف «${g['name']}»', '🎉 تهانينا! أكملت هدف «${g['name']}»', '🎉 Congrats! Goal «${g['name']}» reached')
            : t('🏁 وصلت $m% من «${g['name']}» — واصل', '🏁 بلغت $m% من «${g['name']}»', '🏁 You reached $m% of «${g['name']}»'));
      }
    }
    g['ms'] = ms;
  }

  Future<void> _tx(Map<String, dynamic> g, {required bool deposit, Map<String, dynamic>? old}) async {
    final s = context.read<AppState>();
    final aC = TextEditingController(text: old == null ? '' : rawNum(numOf(old['a']).abs()));
    final noteC = TextEditingController(text: old?['note'] ?? '');
    var date = parseDk(old?['d']) ?? todayPlace();
    final cur = (g['cur'] as String?) ?? '';
    final ok = await lifeSheet<bool>(
      context,
      deposit ? t('إيداع في «${g['name']}»', 'إيداع في «${g['name']}»', 'Deposit to «${g['name']}»') : t('سحب من «${g['name']}»', 'سحب من «${g['name']}»', 'Withdraw from «${g['name']}»'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        NumField(t('المبلغ', 'المبلغ', 'Amount'), aC, suffix: cur),
        TextField(controller: noteC, decoration: InputDecoration(labelText: t('ملاحظة (اختياري)', 'ملاحظة (اختياري)', 'Note (optional)'))),
        const SizedBox(height: 12),
        LifeDateButton(label: t('التاريخ', 'التاريخ', 'Date'), value: date, onPick: (d) => set(() => date = d ?? date), color: SD.green, last: todayPlace().add(const Duration(days: 1))),
        const SizedBox(height: 18),
        sheetButtons(ctx, onSave: () {
          if (parseNum(aC.text) <= 0) return toast(t('أكتب المبلغ', 'اكتب المبلغ', 'Enter the amount'));
          Navigator.pop(ctx, true);
        }, onDelete: old == null ? null : () => Navigator.pop(ctx, false)),
      ]),
    );
    final a = parseNum(aC.text), note = noteC.text.trim();
    aC.dispose();
    noteC.dispose();
    if (!mounted || ok == null) return;
    final tx = mapList(g['tx']);
    if (ok == false && old != null) {
      tx.removeWhere((x) => x['id'] == old['id']);
    } else {
      final data = {'a': deposit ? a : -a, 'd': dk(date), 'note': note};
      if (old == null) {
        tx.add({'id': newId(), ...data});
        if (deposit) {
          s.awardDaily('savings_goal_dep', 3, tr('إيداع ادخار', 'Savings deposit'));
          HapticFeedback.selectionClick();
        }
      } else {
        final i = tx.indexWhere((x) => x['id'] == old['id']);
        if (i >= 0) tx[i] = {...tx[i], ...data};
      }
    }
    final ng = {...g, 'tx': tx};
    _checkMilestones(s, ng);
    _put(s, ng);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final goals = _goals(s);
    final g = _current(goals);
    return ToolList(children: [
      if (goals.isNotEmpty)
        SizedBox(
          height: 48,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final x in goals)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: PickChip(
                  '${x['emoji']} ${x['name']} · ${fmt(numOf(x['target']) <= 0 ? 0 : (saved(x) / numOf(x['target']) * 100).clamp(0, 999), 0)}%',
                  x['id'] == g?['id'],
                  () => setState(() => _sel = x['id']),
                  color: palette(intOf(x['color'])),
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: ActionChip(avatar: const Icon(Icons.add_rounded, size: 18), label: Text(t('هدف جديد', 'هدف جديد', 'New goal')), onPressed: () => _editGoal()),
            ),
          ]),
        ),
      const SizedBox(height: 8),
      if (g == null)
        SCard(
          title: t('الادخار للأهداف', 'الادخار للأهداف', 'Savings goals'),
          icon: Icons.savings_rounded,
          color: SD.green,
          child: EmptyHint(
            Icons.savings_outlined,
            t('حدّد هدف (عمرة، ركشة، زواج، بيت…) وسجّل كل قرش بتحوّشه — التطبيق بيحسب ليك كم تحوّش في الشهر عشان تلحق الموعد.',
                'حدّد هدفًا (عمرة، سيارة، زواج، منزل…) وسجّل مدخراتك، وسيحسب التطبيق ما تحتاج ادخاره شهريًا لتبلغه في موعده.',
                'Set a goal (Umrah, car, wedding, home…) and log every saving — the app works out how much to save per month to hit your deadline.'),
            action: FilledButton.icon(onPressed: () => _editGoal(), icon: const Icon(Icons.add_rounded), label: Text(t('أضف هدف', 'أضف هدفًا', 'Add a goal'))),
          ),
        )
      else
        ..._detail(s, g),
      NoteBox(
        t('نصيحة: حوّش أول ما تقبض (ادفع لنفسك أولًا)، وخلّي قروش الهدف بعيدة من قروش المصروف.',
            'نصيحة: ادّخر فور استلام الدخل (ادفع لنفسك أولًا)، وافصل مال الهدف عن مال المصروف.',
            'Tip: save right when you get paid (pay yourself first) and keep goal money apart from spending money.'),
        kind: NoteKind.tip,
      ),
    ]);
  }

  List<Widget> _detail(AppState s, Map<String, dynamic> g) {
    final cur = (g['cur'] as String?) ?? '';
    final target = numOf(g['target']);
    final have = saved(g);
    final remaining = (target - have).clamp(0, double.infinity).toDouble();
    final pct = target <= 0 ? 0.0 : have / target;
    final color = palette(intOf(g['color']));
    final today = todayPlace();
    final deadline = parseDk(g['deadline']);
    final created = parseDk(g['created']) ?? today;
    final daysLeft = deadline == null ? null : dayDiff(today, deadline);
    final tx = mapList(g['tx'])..sort((a, b) => ((b['d'] as String?) ?? '').compareTo((a['d'] as String?) ?? ''));
    final net = tx.fold(0.0, (a, x) => a + numOf(x['a']));
    final deposits = tx.where((x) => numOf(x['a']) > 0).fold(0.0, (a, x) => a + numOf(x['a']));
    final withdrawals = -tx.where((x) => numOf(x['a']) < 0).fold(0.0, (a, x) => a + numOf(x['a']));
    DateTime first = created;
    for (final x in tx) {
      final d = parseDk(x['d']);
      if (d != null && d.isBefore(first)) first = d;
    }
    final months = (dayDiff(first, today) + 1) / 30.44;
    final avgMonthly = tx.isEmpty ? 0.0 : net / (months < 1 ? 1 : months);
    DateTime? projected;
    if (remaining > 0 && avgMonthly > 0) {
      projected = today.add(Duration(days: (remaining / avgMonthly * 30.44).ceil()));
    }
    final ms = List<int>.from((g['ms'] as List?)?.map((e) => (e as num).toInt()) ?? const <int>[]);

    String summary() {
      final b = StringBuffer('${g['emoji']} ${t('هدف ادخار', 'هدف ادخار', 'Savings goal')}: ${g['name']}\n');
      b.writeln('${t('المطلوب', 'المستهدف', 'Target')}: ${money(target, cur)}');
      b.writeln('${t('المحوّش', 'المدّخر', 'Saved')}: ${money(have, cur)} (${fmt(pct * 100, 0)}%)');
      b.writeln('${t('الباقي', 'المتبقي', 'Remaining')}: ${money(remaining, cur)}');
      if (deadline != null) b.writeln('${t('الموعد', 'الموعد', 'Deadline')}: ${fmtDateAr(deadline, weekday: false)}');
      if (deadline != null && daysLeft != null && daysLeft > 0 && remaining > 0) {
        b.writeln('${t('المطلوب في الشهر', 'المطلوب شهريًا', 'Needed per month')}: ${money(remaining / (daysLeft / 30.44 < 1 ? 1 : daysLeft / 30.44), cur)}');
      }
      if (projected != null) b.writeln('${t('بالمعدل الحالي بتكمّل', 'بالمعدّل الحالي ستكتمل في', 'At the current pace you finish')}: ${fmtDateAr(projected, weekday: false)}');
      return b.toString().trim();
    }

    return [
      Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, .45)!], begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: SD.gold, width: 2),
        ),
        child: Row(children: [
          Container(
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            padding: const EdgeInsets.all(4),
            child: RingProgress(pct, color: color, size: 96),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${g['emoji']} ${g['name']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(money(have, cur), maxLines: 1, style: const TextStyle(color: SD.goldLight, fontSize: 26, fontWeight: FontWeight.w800)),
              ),
              Text('${t('من', 'من أصل', 'of')} ${money(target, cur)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SD.cream)),
              if (remaining <= 0)
                Text(t('🎉 الهدف كمل!', '🎉 اكتمل الهدف!', '🎉 Goal reached!'), style: const TextStyle(color: SD.goldLight, fontWeight: FontWeight.w800)),
            ]),
          ),
        ]),
      ),
      ActionRow([
        MiniAction(Icons.add_circle_rounded, t('إيداع', 'إيداع', 'Deposit'), () => _tx(g, deposit: true), color: SD.green),
        MiniAction(Icons.remove_circle_rounded, t('سحب', 'سحب', 'Withdraw'), () => _tx(g, deposit: false), color: SD.red),
        MiniAction(Icons.edit_rounded, t('تعديل', 'تعديل', 'Edit'), () => _editGoal(g), color: SD.nile),
      ]),
      SCard(
        title: t('الحساب', 'التحليل', 'Plan'),
        icon: Icons.insights_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InfoRow(t('الباقي', 'المتبقي', 'Remaining'), money(remaining, cur), icon: Icons.flag_rounded, valueColor: remaining > 0 ? SD.orange : SD.green),
          if (deadline != null) ...[
            InfoRow(t('الموعد', 'الموعد النهائي', 'Deadline'), fmtDateAr(deadline, weekday: false), icon: Icons.event_rounded, hint: daysLeft == null ? null : daysWord(daysLeft)),
            if (remaining > 0 && daysLeft != null && daysLeft > 0) ...[
              InfoRow(t('لازم تحوّش في الشهر', 'المطلوب شهريًا', 'Needed per month'), money(remaining / (daysLeft / 30.44 < 1 ? 1 : daysLeft / 30.44), cur), icon: Icons.calendar_month_rounded),
              InfoRow(t('في الأسبوع', 'أسبوعيًا', 'Per week'), money(remaining / (daysLeft / 7 < 1 ? 1 : daysLeft / 7), cur), icon: Icons.view_week_rounded),
              InfoRow(t('في اليوم', 'يوميًا', 'Per day'), money(remaining / daysLeft, cur, 1), icon: Icons.today_rounded),
            ],
            if (remaining > 0 && daysLeft != null && daysLeft <= 0)
              NoteBox(t('الموعد فات والهدف لسه ما كمل — مدّد الموعد أو زيد المبلغ.', 'انقضى الموعد ولم يكتمل الهدف — مدّد الموعد أو زِد الادخار.', 'The deadline has passed — extend it or save more.'), kind: NoteKind.warn),
          ],
          InfoRow(t('متوسط ادخارك في الشهر', 'متوسط الادخار الشهري', 'Average monthly saving'), tx.isEmpty ? '—' : money(avgMonthly, cur), icon: Icons.trending_up_rounded),
          if (remaining > 0)
            InfoRow(
              t('بالمعدل دا بتكمّل في', 'بهذا المعدّل يكتمل في', 'At this pace you finish'),
              projected == null ? '—' : fmtDateAr(projected, weekday: false),
              icon: Icons.flag_circle_rounded,
              hint: projected == null
                  ? t('سجّل إيداعات عشان نحسب', 'سجّل إيداعات ليُحسب', 'Log deposits to estimate')
                  : (deadline != null && projected.isAfter(deadline) ? t('بعد الموعد — زيد شوية', 'بعد الموعد — زِد الادخار', 'after the deadline — save more') : null),
              valueColor: projected != null && deadline != null && projected.isAfter(deadline) ? SD.red : null,
            ),
          const SizedBox(height: 10),
          StatGrid([
            StatChip(fmt(deposits, 0), t('مجموع الإيداع', 'إجمالي الإيداع', 'Total deposits'), color: SD.green),
            StatChip(fmt(withdrawals, 0), t('مجموع السحب', 'إجمالي السحب', 'Withdrawals'), color: SD.red),
            StatChip('${tx.length}', t('عملية', 'عملية', 'Entries'), color: SD.nile),
          ]),
        ]),
      ),
      SCard(
        title: t('المراحل', 'المراحل', 'Milestones'),
        icon: Icons.emoji_events_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            for (final m in _milestones)
              Expanded(
                child: Column(children: [
                  Icon(ms.contains(m) || pct * 100 >= m ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
                      color: ms.contains(m) || pct * 100 >= m ? SD.gold : Colors.grey, size: 30),
                  Text('$m%', style: const TextStyle(fontWeight: FontWeight.w800)),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(money(target * m / 100, ''), maxLines: 1, style: const TextStyle(fontSize: 11))),
                ]),
              ),
          ]),
          const SizedBox(height: 8),
          PercentBar('${fmt(pct * 100, 1)}%', pct, money(have, cur), color: color),
          Text(t('كل مرحلة بتديك نقاط (والهدف الكامل 50 نقطة)', 'كل مرحلة تمنحك نقاطًا (والهدف الكامل 50 نقطة)', 'Each milestone earns points (full goal = 50)'), style: const TextStyle(fontSize: 11.5)),
        ]),
      ),
      SectionTitle(t('السجل', 'السجل', 'History'), icon: Icons.history_rounded),
      if (tx.isEmpty && numOf(g['start']) == 0)
        EmptyHint(Icons.receipt_long_outlined, t('لسه ما في إيداعات', 'لا توجد عمليات بعد', 'No entries yet'))
      else ...[
        for (final x in tx.take(60))
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              onTap: () => _tx(g, deposit: numOf(x['a']) >= 0, old: x),
              leading: Icon(numOf(x['a']) >= 0 ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: numOf(x['a']) >= 0 ? SD.green : SD.red),
              title: Text(((x['note'] as String?) ?? '').isEmpty ? (numOf(x['a']) >= 0 ? t('إيداع', 'إيداع', 'Deposit') : t('سحب', 'سحب', 'Withdrawal')) : x['note'],
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(parseDk(x['d']) == null ? '' : fmtDateAr(parseDk(x['d'])!), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              trailing: trailAmount(context, '${numOf(x['a']) >= 0 ? '+' : '−'}${money(numOf(x['a']).abs(), cur)}', color: numOf(x['a']) >= 0 ? SD.green : SD.red),
            ),
          ),
        if (numOf(g['start']) > 0)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_rounded, color: SD.gold),
              title: Text(t('رصيد البداية', 'الرصيد الابتدائي', 'Starting amount'), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: trailAmount(context, money(numOf(g['start']), cur)),
            ),
          ),
      ],
      const SizedBox(height: 8),
      ShareBar(summary),
      const SizedBox(height: 8),
    ];
  }
}
