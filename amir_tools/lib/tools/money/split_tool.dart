import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'money_common.dart';

class _P {
  final TextEditingController name, paid, share;
  _P(String n, String p, String s)
      : name = TextEditingController(text: n),
        paid = TextEditingController(text: p),
        share = TextEditingController(text: s);
  void dispose() {
    name.dispose();
    paid.dispose();
    share.dispose();
  }
}

class SplitTool extends StatefulWidget {
  const SplitTool({super.key});
  @override
  State<SplitTool> createState() => _SplitToolState();
}

class _SplitToolState extends State<SplitTool> {
  int _mode = 0;
  late final TextEditingController _total, _people, _extra;
  double _round = 0;
  final List<_P> _ps = [];

  @override
  void initState() {
    super.initState();
    final d = Map<String, dynamic>.from(context.read<AppState>().getData<Map>('split_inputs') ?? {});
    _total = TextEditingController(text: d['total'] ?? '45000');
    _people = TextEditingController(text: d['people'] ?? '4');
    _extra = TextEditingController(text: d['extra'] ?? '0');
    _round = ((d['round'] ?? 0) as num).toDouble();
    _mode = d['mode'] ?? 0;
    final ps = (d['ps'] as List?)?.whereType<Map>().toList();
    if (ps == null || ps.isEmpty) {
      _ps.addAll([_P('أحمد', '30000', ''), _P('محمد', '15000', ''), _P('عثمان', '0', ''), _P('مصطفى', '0', '')]);
    } else {
      for (final m in ps) {
        _ps.add(_P('${m['n'] ?? ''}', '${m['p'] ?? ''}', '${m['s'] ?? ''}'));
      }
    }
  }

  @override
  void dispose() {
    _total.dispose();
    _people.dispose();
    _extra.dispose();
    for (final p in _ps) {
      p.dispose();
    }
    super.dispose();
  }

  void _save() {
    context.read<AppState>().setData('split_inputs', {
      'total': _total.text, 'people': _people.text, 'extra': _extra.text, 'round': _round, 'mode': _mode,
      'ps': [for (final p in _ps) {'n': p.name.text, 'p': p.paid.text, 's': p.share.text}],
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => ToolList(children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('بالتساوي'), icon: Icon(Icons.people_alt_rounded)),
            ButtonSegment(value: 1, label: Text('منو دفع كم'), icon: Icon(Icons.account_tree_rounded)),
          ],
          selected: {_mode},
          onSelectionChanged: (x) {
            _mode = x.first;
            _save();
          },
        ),
        const SizedBox(height: 14),
        ...(_mode == 0 ? _equal() : _unequal()),
      ]);

  List<Widget> _equal() {
    final total = parseNum(_total.text);
    final n = math.max(1, parseNum(_people.text, 1).round());
    final extra = parseNum(_extra.text);
    final extraAmt = total * extra / 100;
    final grand = total + extraAmt;
    final exact = grand / n;
    final each = _round > 0 ? (exact / _round).ceil() * _round : exact;
    final collected = each * n;
    final surplus = collected - grand;

    String summary() => [
          '🧾 تقسيم الحساب',
          'الحساب: ${fmt(total)}${extra > 0 ? ' + $extra% (${fmt(extraAmt)})' : ''} = ${fmt(grand)}',
          'على $n أشخاص: كل زول يدفع ${fmt(each)} ج.س',
          if (surplus > 0) 'الفايض بعد التقريب: ${fmt(surplus)} (للبقشيش ولا يرجع)',
        ].join('\n');

    return [
      SCard(
        title: 'الحساب',
        icon: Icons.receipt_long_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField('جملة الحساب', _total, suffix: 'ج.س', hint: 'أكتب هنا', onChanged: (_) => _save()),
          Row(children: [
            Expanded(child: NumField('عدد الناس', _people, decimal: false, onChanged: (_) => _save())),
            const SizedBox(width: 10),
            Expanded(child: NumField('خدمة/بقشيش', _extra, suffix: '%', onChanged: (_) => _save())),
          ]),
          Row(children: [
            IconButton.filledTonal(
                onPressed: () {
                  _people.text = '${math.max(1, n - 1)}';
                  _save();
                },
                icon: const Icon(Icons.remove_rounded)),
            Expanded(child: Center(child: Text('$n ${n == 1 ? 'زول' : 'ناس'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))),
            IconButton.filledTonal(
                onPressed: () {
                  _people.text = '${n + 1}';
                  _save();
                },
                icon: const Icon(Icons.add_rounded)),
          ]),
          const SizedBox(height: 10),
          const Text('تقريب نصيب الزول:', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ChoiceRow<double>(const [(0, 'بدون'), (100, 'لأقرب 100'), (500, 'لأقرب 500'), (1000, 'لأقرب 1000')], _round, (x) {
            _round = x;
            _save();
          }),
        ]),
      ),
      ResultHero(label: 'كل زول يدفع', value: '${fmt(each)} ج.س', sub: 'الحساب ${fmt(grand)} على $n'),
      SCard(
        title: 'التفاصيل',
        icon: Icons.list_alt_rounded,
        color: SD.nile,
        child: Column(children: [
          InfoRow('الحساب الأصلي', fmt(total), icon: Icons.receipt_rounded),
          InfoRow('الخدمة/البقشيش ($extra%)', fmt(extraAmt), icon: Icons.room_service_rounded),
          InfoRow('الجملة', fmt(grand), icon: Icons.functions_rounded),
          InfoRow('النصيب بالضبط', fmt(exact, 2), icon: Icons.person_rounded),
          if (_round > 0) ...[
            InfoRow('النصيب بعد التقريب', fmt(each), icon: Icons.rounded_corner_rounded),
            InfoRow('الملموم', fmt(collected), icon: Icons.savings_rounded),
            InfoRow('الفايض', fmt(surplus), icon: Icons.add_card_rounded, valueColor: SD.green, hint: 'خلّوهو بقشيش ولا رجّعوهو لزول'),
          ],
          InfoRow('لو زول واحد زاد', fmt(grand / (n + 1)), icon: Icons.person_add_alt_rounded, hint: '${n + 1} ناس'),
          if (n > 1) InfoRow('لو زول واحد نقص', fmt(grand / (n - 1)), icon: Icons.person_remove_alt_1_rounded, hint: '${n - 1} ناس'),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 10),
      const NoteBox('«الضيافة على الكبير» عادة سودانية جميلة 😄 — بس لو اتفقتو تقسموا، الأداة دي بتخلّي الحساب واضح وما في زول يتظلم.', kind: NoteKind.tip),
    ];
  }

  List<Widget> _unequal() {
    final paid = [for (final p in _ps) parseNum(p.paid.text)];
    final fixed = [for (final p in _ps) p.share.text.trim().isEmpty ? null : parseNum(p.share.text)];
    final total = paid.fold<double>(0, (a, b) => a + b);
    final fixedSum = fixed.whereType<double>().fold<double>(0, (a, b) => a + b);
    final free = fixed.where((e) => e == null).length;
    final eachFree = free == 0 ? 0.0 : (total - fixedSum) / free;
    final shares = [for (final f in fixed) f ?? eachFree];
    final bal = [for (var i = 0; i < _ps.length; i++) paid[i] - shares[i]];
    final names = [for (var i = 0; i < _ps.length; i++) _ps[i].name.text.trim().isEmpty ? 'زول ${i + 1}' : _ps[i].name.text.trim()];
    final sharesSum = shares.fold<double>(0, (a, b) => a + b);
    final mismatch = (sharesSum - total).abs() > .5;

    // التسوية: أكبر مدين يدفع لأكبر دائن
    final debt = <(int, double)>[], cred = <(int, double)>[];
    for (var i = 0; i < bal.length; i++) {
      if (bal[i] < -.005) debt.add((i, -bal[i]));
      if (bal[i] > .005) cred.add((i, bal[i]));
    }
    debt.sort((a, b) => b.$2.compareTo(a.$2));
    cred.sort((a, b) => b.$2.compareTo(a.$2));
    final tx = <(int, int, double)>[];
    var di = 0, ci = 0;
    final dl = [for (final d in debt) d.$2], cl = [for (final c in cred) c.$2];
    while (di < debt.length && ci < cred.length) {
      final a = math.min(dl[di], cl[ci]);
      if (a > .005) tx.add((debt[di].$1, cred[ci].$1, a));
      dl[di] -= a;
      cl[ci] -= a;
      if (dl[di] <= .005) di++;
      if (cl[ci] <= .005) ci++;
    }

    String summary() => [
          '🤝 تسوية الحساب (الجملة ${fmt(total)} ج.س)',
          for (var i = 0; i < _ps.length; i++) '• ${names[i]}: دفع ${fmt(paid[i])} — نصيبو ${fmt(shares[i])}',
          '',
          if (tx.isEmpty) 'الحساب خالص، ما في زول عليه حاجة ✓',
          for (final t in tx) '➜ ${names[t.$1]} يدفع لـ ${names[t.$2]}: ${fmt(t.$3)} ج.س',
        ].join('\n');

    return [
      SCard(
        title: 'الناس والمبالغ',
        icon: Icons.groups_rounded,
        color: SD.indigo,
        trailing: IconButton.filledTonal(
          tooltip: 'أضف زول',
          icon: const Icon(Icons.person_add_rounded),
          onPressed: () {
            _ps.add(_P('', '0', ''));
            _save();
          },
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const NoteBox('أكتب كل زول دفع كم. خانة «نصيبو» خليها فاضية لو القسمة بالتساوي، ولو زول أكل/استهلك مبلغ معيّن أكتبو فيها.', kind: NoteKind.info),
          for (var i = 0; i < _ps.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(10, 10, 4, 0),
              decoration: BoxDecoration(color: SD.indigo.withValues(alpha: .06), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _ps[i].name,
                      decoration: InputDecoration(labelText: 'الاسم', hintText: 'زول ${i + 1}', isDense: true),
                      onChanged: (_) => _save(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _ps.length <= 2
                        ? null
                        : () {
                            _ps.removeAt(i).dispose();
                            _save();
                          },
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: NumField('دفع', _ps[i].paid, suffix: 'ج.س', onChanged: (_) => _save())),
                  const SizedBox(width: 8),
                  Expanded(child: NumField('نصيبو (اختياري)', _ps[i].share, hint: fmt(eachFree), onChanged: (_) => _save())),
                  const SizedBox(width: 6),
                ]),
              ]),
            ),
        ]),
      ),
      if (mismatch)
        NoteBox('مجموع الأنصبة (${fmt(sharesSum)}) ما بيساوي المدفوع (${fmt(total)}). راجع خانات «نصيبو».', kind: NoteKind.danger),
      ResultHero(
        label: 'التسوية',
        value: tx.isEmpty ? 'الحساب خالص ✓' : '${tx.length} ${tx.length == 1 ? 'تحويلة' : 'تحويلات'}',
        sub: 'الجملة ${fmt(total)} ج.س على ${_ps.length} ناس',
      ),
      SCard(
        title: 'منو يدفع لمنو',
        icon: Icons.swap_calls_rounded,
        color: SD.green,
        child: Column(children: [
          if (tx.isEmpty) const Text('ما في زول عليه حاجة لزول — تمام كدا 👌'),
          for (final t in tx)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: Color(0x22007229), child: Icon(Icons.arrow_back_rounded, color: SD.green)),
              title: Text('${names[t.$1]} ← يدفع لـ ${names[t.$2]}', style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: Text('${fmt(t.$3)} ج.س', style: const TextStyle(fontWeight: FontWeight.w800, color: SD.green, fontSize: 16)),
            ),
        ]),
      ),
      SCard(
        title: 'كشف الحساب',
        icon: Icons.table_chart_rounded,
        color: SD.nile,
        child: MiniTable(
          ['الاسم', 'دفع', 'نصيبو', 'الرصيد'],
          [
            for (var i = 0; i < _ps.length; i++)
              [names[i], fmt(paid[i]), fmt(shares[i]), bal[i].abs() < .005 ? 'خالص' : (bal[i] > 0 ? 'ليهو ${fmt(bal[i])}' : 'عليهو ${fmt(-bal[i])}')],
          ],
        ),
      ),
      ShareBar(summary),
    ];
  }
}
