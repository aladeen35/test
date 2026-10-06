import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../money/money_common.dart' show CurrencyPicker, MiniTable, PercentBar, curSym;
import 'life_common.dart';

/// الصندوق (الختّة): جمعية ادخار دوّارة — كل شهر الأعضاء يدفعوا سهم، وواحد بيقبض الكل
class SanduqTool extends StatefulWidget {
  const SanduqTool({super.key});
  @override
  State<SanduqTool> createState() => _SanduqToolState();
}

class _SanduqToolState extends State<SanduqTool> {
  /// الجولة المعروضة في بطاقة الدفع (null = الجولة الحالية)
  int? _round;
  final _rnd = math.Random.secure();

  List<Map<String, dynamic>> _list(AppState s) => mapList(s.getData<List>('sanduq_list'));
  void _save(AppState s, List<Map<String, dynamic>> l) => s.setData('sanduq_list', l);

  Map<String, dynamic>? _sel(AppState s) {
    final l = _list(s);
    if (l.isEmpty) return null;
    final id = s.getData<String>('sanduq_sel');
    return l.firstWhere((x) => x['id'] == id, orElse: () => l.first);
  }

  void _update(Map<String, dynamic> sq, void Function(Map<String, dynamic>) f) {
    final s = context.read<AppState>();
    final l = _list(s);
    final i = l.indexWhere((x) => x['id'] == sq['id']);
    if (i < 0) return;
    f(l[i]);
    _save(s, l);
    setState(() {});
  }

  List<Map<String, dynamic>> _members(Map sq) => mapList(sq['members']);

  (int, int) _start(Map sq) {
    final p = ('${sq['start'] ?? ''}').split('-');
    final now = todayPlace();
    return (int.tryParse(p.isNotEmpty ? p[0] : '') ?? now.year, int.tryParse(p.length > 1 ? p[1] : '') ?? now.month);
  }

  DateTime _monthAt(Map sq, int i) {
    final (y, m) = _start(sq);
    return DateTime(y, m + i);
  }

  /// الجولة الحالية (قد تكون سالبة قبل البداية، أو ≥ عدد الأعضاء بعد النهاية)
  int _current(Map sq) {
    final (y, m) = _start(sq);
    final now = todayPlace();
    return (now.year - y) * 12 + (now.month - m);
  }

  Set<String> _paidIn(Map sq, int r) => Set<String>.from(((sq['paid'] as Map?)?['$r'] as List?) ?? const []);

  Future<void> _create([Map<String, dynamic>? sq]) async {
    final s = context.read<AppState>();
    final nameC = TextEditingController(text: sq?['name'] ?? '');
    final shareC = TextEditingController(text: sq == null ? '' : fmt(numOf(sq['share']), 2).replaceAll(',', ''));
    final membersC = TextEditingController(text: sq == null ? '' : _members(sq).map((m) => m['name']).join('\n'));
    final dayC = TextEditingController(text: sq?['payday'] == null ? '' : '${sq!['payday']}');
    var cur = (sq?['cur'] as String?) ?? 'SDG';
    final now = todayPlace();
    var (sy, sm) = sq == null ? (now.year, now.month) : _start(sq);
    var meName = '';
    if (sq != null) {
      meName = (_members(sq).where((m) => m['id'] == sq['me']).firstOrNull?['name'] as String?) ?? '';
    }
    final meC = TextEditingController(text: meName);
    final ok = await lifeSheet<bool>(
      context,
      sq == null ? t('صندوق جديد', 'صندوق جديد', 'New sanduq') : t('ضبط الصندوق', 'إعدادات الصندوق', 'Sanduq settings'),
      (ctx, set) {
        final names = membersC.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        final share = parseNum(shareC.text);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: nameC,
            decoration: InputDecoration(labelText: t('اسم الصندوق', 'اسم الصندوق', 'Sanduq name'), hintText: t('صندوق ناس الشغل', 'صندوق زملاء العمل', 'Work colleagues')),
          ),
          const SizedBox(height: 10),
          NumField(t('السهم الشهري', 'القسط الشهري للسهم', 'Monthly share'), shareC, suffix: curSym(cur), onChanged: (_) => set(() {})),
          CurrencyPicker(t('العملة', 'العملة', 'Currency'), cur, (v) => set(() => cur = v)),
          const SizedBox(height: 12),
          Text(t('بيبدا شهر', 'شهر البداية', 'Start month'), style: const TextStyle(fontWeight: FontWeight.w700)),
          Row(children: [
            IconButton(
              onPressed: () => set(() {
                sm--;
                if (sm < 1) {
                  sm = 12;
                  sy--;
                }
              }),
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            Expanded(child: Text(fmtMonth(sy, sm), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            IconButton(
              onPressed: () => set(() {
                sm++;
                if (sm > 12) {
                  sm = 1;
                  sy++;
                }
              }),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ]),
          NumField(t('يوم الدفع في الشهر (اختياري)', 'يوم الدفع الشهري (اختياري)', 'Payment day of month (optional)'), dayC, decimal: false, hint: '1 – 28'),
          TextField(
            controller: membersC,
            minLines: 4,
            maxLines: 12,
            onChanged: (_) => set(() {}),
            decoration: InputDecoration(
              labelText: t('الأعضاء — كل اسم في سطر، بترتيب القبض', 'الأعضاء — اسم في كل سطر بترتيب القبض', 'Members — one per line, in payout order'),
              alignLabelWithHint: true,
              helperText: t('الزول البشيل سهمين أكتب اسمو مرتين', 'من له سهمان يُكتب اسمه مرتين', 'Someone with two shares? List them twice'),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: meC,
            decoration: InputDecoration(
              labelText: t('اسمك في القائمة (عشان نعرف دورك)', 'اسمك في القائمة (لمعرفة دورك)', 'Your name in the list (to find your turn)'),
              prefixIcon: const Icon(Icons.person_pin_rounded),
            ),
          ),
          if (names.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              for (final n in names.toSet().take(20)) ActionChip(label: Text(n), onPressed: () => set(() => meC.text = n)),
            ]),
          ],
          const SizedBox(height: 10),
          if (names.isNotEmpty && share > 0)
            NoteBox(
              t('${names.length} أعضاء × ${fmt(share, 0)} = الصرفة ${fmt(share * names.length, 0)} ${curSym(cur)} كل شهر، لمدة ${names.length} شهر (لحدي ${fmtMonth(DateTime(sy, sm + names.length - 1).year, DateTime(sy, sm + names.length - 1).month)}).',
                  '${names.length} أعضاء × ${fmt(share, 0)} = ${fmt(share * names.length, 0)} ${curSym(cur)} شهريًا، لمدة ${names.length} شهرًا.',
                  '${names.length} members × ${fmt(share, 0)} = ${fmt(share * names.length, 0)} ${curSym(cur)} pot each month, for ${names.length} months.'),
              kind: NoteKind.info,
            ),
          Row(children: [
            if (sq != null)
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: SD.red),
                  onPressed: () => Navigator.pop(ctx, false),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(t('امسح', 'حذف', 'Delete')),
                ),
              ),
            if (sq != null) const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () {
                  if (nameC.text.trim().isEmpty) return toast(t('أكتب اسم الصندوق', 'اكتب اسم الصندوق', 'Enter a name'));
                  if (share <= 0) return toast(t('أكتب قيمة السهم', 'اكتب قيمة السهم', 'Enter the share amount'));
                  if (names.length < 2) return toast(t('محتاج عضوين على الأقل', 'يلزم عضوان على الأقل', 'At least two members'));
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
    final name = nameC.text.trim(), share = parseNum(shareC.text), me = meC.text.trim();
    final names = membersC.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final payday = parseNum(dayC.text).round();
    for (final c in [nameC, shareC, membersC, dayC, meC]) {
      c.dispose();
    }
    if (!mounted || ok == null) return;
    final l = _list(s);
    if (ok == false && sq != null) {
      if (!await confirmAsk(context, t('نمسح الصندوق؟', 'حذف الصندوق؟', 'Delete sanduq?'),
          t('حيتمسح «${sq['name']}» وكل سجل الدفع.', 'سيُحذف «${sq['name']}» وكامل سجل الدفع.', '“${sq['name']}” and its payment records will be deleted.'))) {
        return;
      }
      _save(s, l..removeWhere((x) => x['id'] == sq['id']));
      setState(() => _round = null);
      return;
    }
    // نحافظ على معرّفات الأعضاء القدامى بنفس الاسم (عشان سجل الدفع)
    final old = sq == null ? <Map<String, dynamic>>[] : _members(sq);
    final members = <Map<String, dynamic>>[];
    for (final n in names) {
      final i = old.indexWhere((m) => m['name'] == n);
      members.add(i >= 0 ? old.removeAt(i) : {'id': newId(), 'name': n});
    }
    final meId = me.isEmpty ? null : members.where((m) => m['name'] == me).firstOrNull?['id'];
    final data = {
      'name': name,
      'share': share,
      'cur': cur,
      'start': mk(sy, sm),
      'members': members,
      'me': meId,
      'payday': payday >= 1 && payday <= 31 ? payday : null,
    };
    if (sq == null) {
      final id = newId();
      l.add({'id': id, ...data, 'paid': <String, dynamic>{}});
      s.setData('sanduq_sel', id);
      s.award(5, tr('صندوق جديد', 'New sanduq'));
    } else {
      final i = l.indexWhere((x) => x['id'] == sq['id']);
      if (i >= 0) l[i] = {...l[i], ...data};
    }
    _save(s, l);
    setState(() => _round = null);
  }

  void _togglePaid(Map<String, dynamic> sq, int r, String mid) {
    _update(sq, (x) {
      final paid = Map<String, dynamic>.from((x['paid'] as Map?) ?? const {});
      final set = Set<String>.from((paid['$r'] as List?) ?? const []);
      set.contains(mid) ? set.remove(mid) : set.add(mid);
      paid['$r'] = set.toList();
      x['paid'] = paid;
    });
    HapticFeedback.selectionClick();
    final now = _paidIn(_sel(context.read<AppState>()) ?? sq, r);
    if (now.length == _members(sq).length) {
      toast(t('🎉 الكل دفع! الصرفة جاهزة', '🎉 اكتمل الدفع! المبلغ جاهز للتسليم', '🎉 Everyone paid — the pot is ready'));
    }
  }

  Future<void> _draw(Map<String, dynamic> sq) async {
    final cur = _current(sq);
    final ms = _members(sq);
    final from = cur < 0 ? 0 : cur + 1;
    if (from >= ms.length - 1) return toast(t('ما فاضل أدوار للقرعة', 'لا توجد أدوار متبقية للقرعة', 'No remaining turns to draw'));
    if (!await confirmAsk(
        context,
        t('نعمل قرعة؟', 'إجراء قرعة؟', 'Random draw?'),
        cur < 0
            ? t('حنرتّب كل الأعضاء عشوائي.', 'سيُعاد ترتيب جميع الأعضاء عشوائيًا.', 'All members will be shuffled randomly.')
            : t('حنرتّب الأدوار الجاية بس عشوائي (اللي قبضوا ما بيتغيّروا).', 'سيُعاد ترتيب الأدوار القادمة فقط عشوائيًا.', 'Only upcoming turns will be shuffled (past receivers stay).'),
        danger: false,
        ok: t('يلا القرعة', 'إجراء القرعة', 'Draw'))) {
      return;
    }
    final head = ms.sublist(0, from), tail = ms.sublist(from)..shuffle(_rnd);
    _update(sq, (x) => x['members'] = [...head, ...tail]);
    HapticFeedback.heavyImpact();
    toast(t('🎲 القرعة اتعملت', '🎲 تمّت القرعة', '🎲 Draw done'));
  }

  String _scheduleText(Map sq) {
    final ms = _members(sq);
    final sym = curSym((sq['cur'] as String?) ?? 'SDG');
    final pot = numOf(sq['share']) * ms.length;
    final b = StringBuffer('📦 ${sq['name']}\n');
    b.writeln('${t('السهم', 'السهم', 'Share')}: ${fmt(numOf(sq['share']), 0)} $sym · ${t('الصرفة', 'المبلغ الشهري', 'Pot')}: ${fmt(pot, 0)} $sym');
    if (sq['payday'] != null) b.writeln('${t('يوم الدفع', 'يوم الدفع', 'Pay day')}: ${sq['payday']}');
    b.writeln();
    for (var i = 0; i < ms.length; i++) {
      final d = _monthAt(sq, i);
      b.writeln('${i + 1}. ${fmtMonth(d.year, d.month)} ← ${ms[i]['name']}');
    }
    return b.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final l = _list(s);
    final sq = _sel(s);

    final selector = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final x in l)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: PickChip('📦 ${x['name']}', x['id'] == sq?['id'], () {
              s.setData('sanduq_sel', x['id']);
              setState(() => _round = null);
            }, color: SD.gold),
          ),
        ActionChip(avatar: const Icon(Icons.add_rounded, size: 18), label: Text(t('صندوق جديد', 'صندوق جديد', 'New sanduq')), onPressed: () => _create()),
      ]),
    );

    if (sq == null) {
      return ToolList(children: [
        SCard(
          title: t('الصندوق (الختّة)', 'الصندوق (جمعية الادخار)', 'Sanduq (rotating savings)'),
          icon: Icons.savings_rounded,
          color: SD.gold,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              t('الصندوق: مجموعة ناس كل شهر بيدفعوا سهم ثابت، وكل شهر زول واحد بيقبض الصرفة كلها بالدور لحدي ما الكل يقبض. نظّم صندوقك هنا: الأعضاء، ترتيب القبض أو القرعة، ومين دفع ومين لسه.',
                  'الصندوق جمعية ادخار دوّارة: يدفع الأعضاء قسطًا ثابتًا كل شهر، ويقبض أحدهم المبلغ كاملًا بالدور حتى يقبض الجميع. نظّم هنا الأعضاء وترتيب القبض أو القرعة ومتابعة الدفع.',
                  'A sanduq is a rotating savings group: every member pays a fixed share monthly and one member takes the whole pot each month, in turn, until everyone has received. Manage members, payout order or a random draw, and who has paid.'),
              style: const TextStyle(height: 1.6),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: () => _create(), icon: const Icon(Icons.add_rounded), label: Text(t('أعمل صندوق جديد', 'إنشاء صندوق جديد', 'Create a sanduq'))),
          ]),
        ),
      ]);
    }

    final ms = _members(sq);
    final n = ms.length;
    final cur = (sq['cur'] as String?) ?? 'SDG';
    final sym = curSym(cur);
    final share = numOf(sq['share']);
    final pot = share * n;
    final current = _current(sq);
    final started = current >= 0, finished = current >= n;
    final int r = (_round ?? current).clamp(0, math.max(0, n - 1)).toInt();
    final paid = _paidIn(sq, r);
    final rMonth = _monthAt(sq, r);
    final meIdx = ms.indexWhere((m) => m['id'] == sq['me']);
    final totalPaidAll = [for (var i = 0; i < n; i++) _paidIn(sq, i).length].fold<int>(0, (a, b) => a + b);
    final payday = sq['payday'];

    String heroLabel, heroValue, heroSub;
    if (!started) {
      heroLabel = t('الصندوق لسه ما بدا', 'لم يبدأ الصندوق بعد', 'Not started yet');
      heroValue = fmtMonth(_monthAt(sq, 0).year, _monthAt(sq, 0).month);
      heroSub = t('بيبدا بعد ${-current} شهر — أول قابض: ${ms.first['name']}', 'يبدأ بعد ${-current} شهر — أول من يقبض: ${ms.first['name']}',
          'Starts in ${-current} month(s) — first receiver: ${ms.first['name']}');
    } else if (finished) {
      heroLabel = t('الصندوق كمّل', 'اكتمل الصندوق', 'Completed');
      heroValue = '✅';
      heroSub = t('كل الـ$n أعضاء قبضوا. ربنا يبارك', 'قبض جميع الأعضاء الـ$n', 'All $n members have received');
    } else {
      heroLabel = t('قابض الشهر دا (${current + 1}/$n)', 'مستلم هذا الشهر (${current + 1}/$n)', 'This month\'s receiver (${current + 1}/$n)');
      heroValue = '${ms[current]['name']}';
      heroSub = '${t('الصرفة', 'المبلغ', 'Pot')}: ${fmt(pot, 0)} $sym${current + 1 < n ? ' · ${t('الجاي', 'التالي', 'Next')}: ${ms[current + 1]['name']}' : ''}';
    }

    return ToolList(children: [
      selector,
      const SizedBox(height: 10),
      ResultHero(label: heroLabel, value: heroValue, sub: heroSub, colors: const [SD.gold, SD.goldDeep, SD.coffee]),
      StatGrid([
        StatChip('$n', t('أعضاء', 'الأعضاء', 'Members'), color: SD.nile, icon: Icons.groups_rounded),
        StatChip(fmt(share, 0), '${t('السهم', 'السهم', 'Share')} ($sym)', color: SD.teal, icon: Icons.payments_rounded),
        StatChip(fmt(pot, 0), '${t('الصرفة', 'المبلغ', 'Pot')} ($sym)', color: SD.gold, icon: Icons.savings_rounded),
      ]),
      const SizedBox(height: 12),
      if (meIdx >= 0)
        SCard(
          title: t('دورك إنت', 'دورك', 'Your turn'),
          icon: Icons.person_pin_rounded,
          color: SD.green,
          child: Column(children: [
            InfoRow(t('ترتيبك', 'ترتيبك', 'Your position'), '${meIdx + 1} / $n', icon: Icons.format_list_numbered_rounded),
            InfoRow(t('بتقبض في', 'تقبض في', 'You receive in'), fmtMonth(_monthAt(sq, meIdx).year, _monthAt(sq, meIdx).month),
                icon: Icons.event_available_rounded,
                valueColor: SD.green,
                hint: meIdx < current
                    ? t('قبضت قبل ${current - meIdx} شهر', 'قبضت قبل ${current - meIdx} شهر', 'Received ${current - meIdx} month(s) ago')
                    : meIdx == current
                        ? t('الشهر دا دورك! 🎉', 'هذا الشهر دورك! 🎉', 'It\'s your turn this month! 🎉')
                        : t('بعد ${meIdx - current} شهر', 'بعد ${meIdx - current} شهر', 'in ${meIdx - current} month(s)')),
            InfoRow(t('بتقبض', 'ستقبض', 'You receive'), '${fmt(pot, 0)} $sym', icon: Icons.savings_rounded),
            InfoRow(t('جملة البتدفعو', 'إجمالي ما تدفعه', 'You pay in total'), '${fmt(pot, 0)} $sym', icon: Icons.outbox_rounded,
                hint: t('$n شهر × ${fmt(share, 0)}', '$n شهرًا × ${fmt(share, 0)}', '$n months × ${fmt(share, 0)}')),
            InfoRow(
              meIdx < n / 2 ? t('إنت زي المستلف', 'أنت كالمقترض', 'You\'re effectively borrowing') : t('إنت زي المدّخر', 'أنت كالمدّخر', 'You\'re effectively saving'),
              meIdx < n / 2 ? t('قبضت بدري وبتسدد بعدين', 'تقبض مبكرًا وتسدّد لاحقًا', 'early payout, pay later') : t('بتدّخر وبتقبض آخر', 'تدّخر ثم تقبض لاحقًا', 'save now, receive later'),
              icon: Icons.balance_rounded,
            ),
          ]),
        )
      else
        NoteBox(t('حدّد اسمك من «الضبط» عشان نوريك دورك متين.', 'حدّد اسمك من «الإعدادات» لنعرض دورك.', 'Set your name in Settings to see your turn.'), kind: NoteKind.tip),
      SCard(
        title: t('مين دفع؟', 'من دفع؟', 'Who paid?'),
        icon: Icons.fact_check_rounded,
        color: SD.teal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            IconButton(
              onPressed: r > 0 ? () => setState(() => _round = r - 1) : null,
              icon: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Column(children: [
                Text('${t('الجولة', 'الجولة', 'Round')} ${r + 1} — ${fmtMonth(rMonth.year, rMonth.month)}',
                    textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('${t('القابض', 'المستلم', 'Receiver')}: ${ms[r]['name']}${payday == null ? '' : ' · ${t('يوم الدفع', 'يوم الدفع', 'pay day')} $payday'}',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5)),
              ]),
            ),
            IconButton(
              onPressed: r < n - 1 ? () => setState(() => _round = r + 1) : null,
              icon: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
            ),
          ]),
          PercentBar(
            t('اتجمع ${fmt(paid.length * share, 0)} من ${fmt(pot, 0)} $sym', 'جُمع ${fmt(paid.length * share, 0)} من ${fmt(pot, 0)} $sym', 'Collected ${fmt(paid.length * share, 0)} of ${fmt(pot, 0)} $sym'),
            n == 0 ? 0 : paid.length / n,
            '${paid.length}/$n',
            color: paid.length == n ? SD.green : SD.teal,
          ),
          for (var i = 0; i < n; i++)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: paid.contains(ms[i]['id']),
              onChanged: (_) => _togglePaid(sq, r, ms[i]['id']),
              title: Text('${ms[i]['name']}${ms[i]['id'] == sq['me'] ? ' (${t('إنت', 'أنت', 'you')})' : ''}',
                  style: TextStyle(fontWeight: i == r ? FontWeight.w800 : FontWeight.w600)),
              secondary: i == r ? const Text('💰') : null,
            ),
          Row(children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => _update(sq, (x) {
                  final p = Map<String, dynamic>.from((x['paid'] as Map?) ?? const {});
                  p['$r'] = ms.map((m) => m['id']).toList();
                  x['paid'] = p;
                }),
                icon: const Icon(Icons.done_all_rounded),
                label: Text(t('الكل دفع', 'الجميع دفع', 'All paid')),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _update(sq, (x) {
                  final p = Map<String, dynamic>.from((x['paid'] as Map?) ?? const {});
                  p.remove('$r');
                  x['paid'] = p;
                }),
                icon: const Icon(Icons.remove_done_rounded),
                label: Text(t('امسح العلامات', 'مسح العلامات', 'Clear marks')),
              ),
            ),
          ]),
          if (paid.length < n)
            Text(
              '${t('لسه ما دفعوا', 'لم يدفعوا بعد', 'Still to pay')}: ${ms.where((m) => !paid.contains(m['id'])).map((m) => m['name']).join(isEn ? ', ' : '، ')}',
              style: TextStyle(fontSize: 12.5, color: readable(context, SD.orange), fontWeight: FontWeight.w700),
            ),
        ]),
      ),
      SCard(
        title: t('جدول القبض', 'جدول القبض', 'Payout schedule'),
        icon: Icons.table_chart_rounded,
        color: SD.nile,
        trailing: Text(t('$totalPaidAll دفعة', '$totalPaidAll دفعة', '$totalPaidAll payments'), style: const TextStyle(fontSize: 12)),
        child: MiniTable(
          ['#', t('الشهر', 'الشهر', 'Month'), t('القابض', 'المستلم', 'Receiver'), t('الصرفة', 'المبلغ', 'Pot'), t('الدفع', 'الدفع', 'Paid')],
          [
            for (var i = 0; i < n; i++)
              [
                '${i + 1}',
                fmtMonth(_monthAt(sq, i).year, _monthAt(sq, i).month),
                '${ms[i]['name']}${ms[i]['id'] == sq['me'] ? ' ⭐' : ''}',
                fmt(pot, 0),
                () {
                  final c = _paidIn(sq, i).length;
                  return c == n ? '✅' : (c == 0 ? (i < current ? '⚠️' : '—') : '$c/$n');
                }(),
              ],
          ],
          color: SD.nile,
          highlight: started && !finished ? current : null,
        ),
      ),
      SCard(
        title: t('ترتيب القبض', 'ترتيب القبض', 'Payout order'),
        icon: Icons.swap_vert_rounded,
        color: SD.purple,
        trailing: TextButton.icon(onPressed: () => _draw(sq), icon: const Icon(Icons.casino_rounded), label: Text(t('قرعة', 'قرعة', 'Draw'))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t('اسحب الاسم لفوق أو تحت عشان تغيّر الدور', 'اسحب الاسم لتغيير ترتيبه', 'Drag a name to change its turn'), style: const TextStyle(fontSize: 12)),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (a, b) => _update(sq, (x) {
              final m = _members(x);
              final it = m.removeAt(a);
              m.insert(b, it);
              x['members'] = m;
            }),
            children: [
              for (var i = 0; i < n; i++)
                ListTile(
                  key: ValueKey(ms[i]['id']),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 15,
                    backgroundColor: (i == current ? SD.gold : SD.purple).withValues(alpha: .25),
                    child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                  title: Text('${ms[i]['name']}${ms[i]['id'] == sq['me'] ? ' ⭐' : ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(fmtMonth(_monthAt(sq, i).year, _monthAt(sq, i).month), style: const TextStyle(fontSize: 11.5)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      tooltip: t('غيّر الاسم', 'تعديل الاسم', 'Rename'),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      onPressed: () async {
                        final v = (await askText(context, t('اسم العضو', 'اسم العضو', 'Member name'), initial: '${ms[i]['name']}'))?.trim() ?? '';
                        if (v.isEmpty) return;
                        _update(sq, (x) {
                          final m = _members(x);
                          m[i]['name'] = v;
                          x['members'] = m;
                        });
                      },
                    ),
                    IconButton(
                      tooltip: t('شيلو', 'إزالة', 'Remove'),
                      icon: const Icon(Icons.person_remove_rounded, size: 18),
                      onPressed: n <= 2
                          ? null
                          : () async {
                              if (!await confirmAsk(context, t('نشيل العضو؟', 'إزالة العضو؟', 'Remove member?'), '${ms[i]['name']}')) return;
                              _update(sq, (x) {
                                final m = _members(x)..removeAt(i);
                                x['members'] = m;
                              });
                            },
                    ),
                    ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle_rounded)),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final v = (await askText(context, t('عضو جديد', 'عضو جديد', 'New member')))?.trim() ?? '';
                  if (v.isEmpty) return;
                  _update(sq, (x) => x['members'] = [..._members(x), {'id': newId(), 'name': v}]);
                },
                icon: const Icon(Icons.person_add_rounded),
                label: Text(t('ضيف عضو', 'إضافة عضو', 'Add member')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _create(sq),
                icon: const Icon(Icons.settings_rounded),
                label: Text(t('الضبط', 'الإعدادات', 'Settings')),
              ),
            ),
          ]),
        ]),
      ),
      ShareBar(() => _scheduleText(sq)),
      const SizedBox(height: 8),
      NoteBox(
        t('الصندوق قايم على الأمانة: سجّل الدفع أول بأول، واتفقوا من البداية على يوم الدفع وعلى الحاصل لو زول اتأخر.',
            'يقوم الصندوق على الأمانة: سجّل الدفعات أولًا بأول، واتفقوا مسبقًا على يوم الدفع وعلى ما يحدث عند التأخر.',
            'A sanduq runs on trust: record payments promptly and agree up front on the pay day and what happens if someone is late.'),
        kind: NoteKind.tip,
      ),
    ]);
  }
}
