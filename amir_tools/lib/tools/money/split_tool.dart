import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'money_common.dart';

String _anon(int i) => t('زول $i', 'شخص $i', 'Person $i');

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
      _ps.addAll([_P(tr('أحمد', 'Ahmed'), '30000', ''), _P(tr('محمد', 'Mohamed'), '15000', ''), _P(tr('عثمان', 'Osman'), '0', ''), _P(tr('مصطفى', 'Mustafa'), '0', '')]);
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
          segments: [
            ButtonSegment(value: 0, label: Text(tr('بالتساوي', 'Equally')), icon: const Icon(Icons.people_alt_rounded)),
            ButtonSegment(value: 1, label: Text(t('منو دفع كم', 'من دفع كم', 'Who paid what')), icon: const Icon(Icons.account_tree_rounded)),
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
          '🧾 ${t('قسمة الحساب', 'تقسيم الحساب', 'Bill split')}',
          '${tr('الحساب', 'Bill')}: ${fmt(total)}${extra > 0 ? ' + $extra% (${fmt(extraAmt)})' : ''} = ${fmt(grand)}',
          t('على $n أشخاص: كل زول يدفع ${fmt(each)}', 'على $n أشخاص: يدفع كل شخص ${fmt(each)}', 'Split $n ways: each pays ${fmt(each)}'),
          if (surplus > 0) t('الفايض بعد التقريب: ${fmt(surplus)} (للبقشيش ولا يرجع)', 'الفائض بعد التقريب: ${fmt(surplus)} (بقشيش أو يُعاد)', 'Surplus after rounding: ${fmt(surplus)} (tip or refund)'),
        ].join('\n');

    return [
      SCard(
        title: tr('الحساب', 'The bill'),
        icon: Icons.receipt_long_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField(tr('جملة الحساب', 'Bill total'), _total, hint: t('أكتب هنا', 'اكتب هنا', 'Type here'), onChanged: (_) => _save()),
          Row(children: [
            Expanded(child: NumField(t('عدد الناس', 'عدد الأشخاص', 'People'), _people, decimal: false, onChanged: (_) => _save())),
            const SizedBox(width: 10),
            Expanded(child: NumField(tr('خدمة/بقشيش', 'Service/tip'), _extra, suffix: '%', onChanged: (_) => _save())),
          ]),
          Row(children: [
            IconButton.filledTonal(
                onPressed: () {
                  _people.text = '${math.max(1, n - 1)}';
                  _save();
                },
                icon: const Icon(Icons.remove_rounded)),
            Expanded(child: Center(child: Text(t('$n ${n == 1 ? 'زول' : 'ناس'}', '$n ${n == 1 ? 'شخص' : 'أشخاص'}', '$n ${n == 1 ? 'person' : 'people'}'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))),
            IconButton.filledTonal(
                onPressed: () {
                  _people.text = '${n + 1}';
                  _save();
                },
                icon: const Icon(Icons.add_rounded)),
          ]),
          const SizedBox(height: 10),
          Text(t('تقريب نصيب الزول:', 'تقريب نصيب الفرد:', 'Round each share:'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ChoiceRow<double>([(0, tr('بدون', 'None')), (100, tr('لأقرب 100', 'To 100')), (500, tr('لأقرب 500', 'To 500')), (1000, tr('لأقرب 1000', 'To 1000'))], _round, (x) {
            _round = x;
            _save();
          }),
        ]),
      ),
      ResultHero(label: t('كل زول يدفع', 'يدفع كل شخص', 'Each person pays'), value: fmt(each), sub: tr('الحساب ${fmt(grand)} على $n', 'Bill ${fmt(grand)} ÷ $n')),
      SCard(
        title: tr('التفاصيل', 'Details'),
        icon: Icons.list_alt_rounded,
        color: SD.nile,
        child: Column(children: [
          InfoRow(tr('الحساب الأصلي', 'Original bill'), fmt(total), icon: Icons.receipt_rounded),
          InfoRow(tr('الخدمة/البقشيش ($extra%)', 'Service/tip ($extra%)'), fmt(extraAmt), icon: Icons.room_service_rounded),
          InfoRow(tr('الجملة', 'Total'), fmt(grand), icon: Icons.functions_rounded),
          InfoRow(tr('النصيب بالضبط', 'Exact share'), fmt(exact, 2), icon: Icons.person_rounded),
          if (_round > 0) ...[
            InfoRow(tr('النصيب بعد التقريب', 'Rounded share'), fmt(each), icon: Icons.rounded_corner_rounded),
            InfoRow(t('الملموم', 'المجموع المُحصَّل', 'Collected'), fmt(collected), icon: Icons.savings_rounded),
            InfoRow(t('الفايض', 'الفائض', 'Surplus'), fmt(surplus), icon: Icons.add_card_rounded, valueColor: SD.green, hint: t('خلّوهو بقشيش ولا رجّعوهو لزول', 'اتركوه بقشيشًا أو أعيدوه لأحدكم', 'Leave it as a tip or refund someone')),
          ],
          InfoRow(t('لو زول واحد زاد', 'لو زاد شخص واحد', 'If one more joins'), fmt(grand / (n + 1)), icon: Icons.person_add_alt_rounded, hint: t('${n + 1} ناس', '${n + 1} أشخاص', '${n + 1} people')),
          if (n > 1) InfoRow(t('لو زول واحد نقص', 'لو نقص شخص واحد', 'If one drops out'), fmt(grand / (n - 1)), icon: Icons.person_remove_alt_1_rounded, hint: t('${n - 1} ناس', '${n - 1} أشخاص', '${n - 1} people')),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 10),
      NoteBox(t('«الضيافة على الكبير» عادة سودانية جميلة 😄 — بس لو اتفقتو تقسموا، الأداة دي بتخلّي الحساب واضح وما في زول يتظلم.', '«الضيافة على الكبير» عادة سودانية جميلة 😄 — لكن إن اتفقتم على التقسيم، فهذه الأداة تجعل الحساب واضحًا ولا يُظلم أحد.', '“The eldest pays” is a lovely Sudanese custom 😄 — but if you agree to split, this keeps it clear and fair for everyone.'), kind: NoteKind.tip),
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
    final names = [for (var i = 0; i < _ps.length; i++) _ps[i].name.text.trim().isEmpty ? _anon(i + 1) : _ps[i].name.text.trim()];
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
          '🤝 ${tr('تسوية الحساب', 'Settle up')} (${tr('الجملة', 'total')} ${fmt(total)})',
          for (var i = 0; i < _ps.length; i++) t('• ${names[i]}: دفع ${fmt(paid[i])} — نصيبو ${fmt(shares[i])}', '• ${names[i]}: دفع ${fmt(paid[i])} — نصيبه ${fmt(shares[i])}', '• ${names[i]}: paid ${fmt(paid[i])} — share ${fmt(shares[i])}'),
          '',
          if (tx.isEmpty) t('الحساب خالص، ما في زول عليه حاجة ✓', 'الحساب مُسوّى، لا أحد مدين بشيء ✓', 'All settled, nobody owes anything ✓'),
          for (final x in tx) '➜ ${tr('${names[x.$1]} يدفع لـ ${names[x.$2]}', '${names[x.$1]} pays ${names[x.$2]}')}: ${fmt(x.$3)}',
        ].join('\n');

    return [
      SCard(
        title: t('الناس والمبالغ', 'الأشخاص والمبالغ', 'People & amounts'),
        icon: Icons.groups_rounded,
        color: SD.indigo,
        trailing: IconButton.filledTonal(
          tooltip: t('أضف زول', 'إضافة شخص', 'Add person'),
          icon: const Icon(Icons.person_add_rounded),
          onPressed: () {
            _ps.add(_P('', '0', ''));
            _save();
          },
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NoteBox(t('أكتب كل زول دفع كم. خانة «نصيبو» خليها فاضية لو القسمة بالتساوي، ولو زول أكل/استهلك مبلغ معيّن أكتبو فيها.', 'اكتب كم دفع كل شخص. اترك خانة «نصيبه» فارغة إن كانت القسمة بالتساوي، وإن استهلك أحدهم مبلغًا محددًا فاكتبه فيها.', 'Enter what each person paid. Leave “Share” empty for an equal split, or type a fixed amount if someone consumed a specific amount.'), kind: NoteKind.info),
          for (var i = 0; i < _ps.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 4, 0),
              decoration: BoxDecoration(color: SD.indigo.withValues(alpha: .06), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _ps[i].name,
                      decoration: InputDecoration(labelText: tr('الاسم', 'Name'), hintText: _anon(i + 1), isDense: true),
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
                  Expanded(child: NumField(tr('دفع', 'Paid'), _ps[i].paid, onChanged: (_) => _save())),
                  const SizedBox(width: 8),
                  Expanded(child: NumField(t('نصيبو (اختياري)', 'نصيبه (اختياري)', 'Share (optional)'), _ps[i].share, hint: fmt(eachFree), onChanged: (_) => _save())),
                  const SizedBox(width: 6),
                ]),
              ]),
            ),
        ]),
      ),
      if (mismatch)
        NoteBox(t('مجموع الأنصبة (${fmt(sharesSum)}) ما بيساوي المدفوع (${fmt(total)}). راجع خانات «نصيبو».', 'مجموع الأنصبة (${fmt(sharesSum)}) لا يساوي المدفوع (${fmt(total)}). راجع خانات «نصيبه».', 'Shares total (${fmt(sharesSum)}) doesn\'t match amount paid (${fmt(total)}). Check the “Share” fields.'), kind: NoteKind.danger),
      ResultHero(
        label: tr('التسوية', 'Settlement'),
        value: tx.isEmpty ? t('الحساب خالص ✓', 'الحساب مُسوّى ✓', 'All settled ✓') : '${tx.length} ${tx.length == 1 ? tr('تحويلة', 'transfer') : tr('تحويلات', 'transfers')}',
        sub: t('الجملة ${fmt(total)} على ${_ps.length} ناس', 'الإجمالي ${fmt(total)} على ${_ps.length} أشخاص', 'Total ${fmt(total)} among ${_ps.length} people'),
      ),
      SCard(
        title: t('منو يدفع لمنو', 'من يدفع لمن', 'Who pays whom'),
        icon: Icons.swap_calls_rounded,
        color: SD.green,
        child: Column(children: [
          if (tx.isEmpty) Text(t('ما في زول عليه حاجة لزول — تمام كدا 👌', 'لا أحد مدين لأحد — كل شيء تمام 👌', 'Nobody owes anybody — all good 👌')),
          for (final x in tx)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: Color(0x22007229), child: Icon(Icons.arrow_forward_rounded, color: SD.green)),
              title: Text(tr('${names[x.$1]} ← يدفع لـ ${names[x.$2]}', '${names[x.$1]} → pays ${names[x.$2]}'), style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: Text(fmt(x.$3), style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, SD.green), fontSize: 16)),
            ),
        ]),
      ),
      SCard(
        title: tr('كشف الحساب', 'Statement'),
        icon: Icons.table_chart_rounded,
        color: SD.nile,
        child: MiniTable(
          [tr('الاسم', 'Name'), tr('دفع', 'Paid'), t('نصيبو', 'نصيبه', 'Share'), tr('الرصيد', 'Balance')],
          [
            for (var i = 0; i < _ps.length; i++)
              [names[i], fmt(paid[i]), fmt(shares[i]), bal[i].abs() < .005 ? t('خالص', 'مُسوّى', 'Settled') : (bal[i] > 0 ? t('ليهو ${fmt(bal[i])}', 'له ${fmt(bal[i])}', 'Gets ${fmt(bal[i])}') : t('عليهو ${fmt(-bal[i])}', 'عليه ${fmt(-bal[i])}', 'Owes ${fmt(-bal[i])}'))],
          ],
        ),
      ),
      ShareBar(summary),
    ];
  }
}
