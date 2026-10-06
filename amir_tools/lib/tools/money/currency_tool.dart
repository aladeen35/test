import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/net.dart';
import 'money_common.dart';

/// تنسيق سعر صرف بعدد خانات مناسب لحجمه
String fmtRate(double x) {
  final a = x.abs();
  if (a == 0) return '0';
  if (a < 0.001) return fmt(x, 7);
  if (a < 0.1) return fmt(x, 5);
  if (a < 10) return fmt(x, 4);
  return fmt(x, 2);
}

class CurrencyTool extends StatefulWidget {
  const CurrencyTool({super.key});
  @override
  State<CurrencyTool> createState() => _CurrencyToolState();
}

class _CurrencyToolState extends State<CurrencyTool> {
  final _amount = TextEditingController(text: '100');
  final _par = TextEditingController();
  String _from = 'USD', _to = 'SDG';
  bool _loading = false;
  bool _showAllHistory = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _from = s.getData<String>('currency_from') ?? 'USD';
    _to = s.getData<String>('currency_to') ?? 'SDG';
    _amount.text = s.getData<String>('currency_amount') ?? '100';
    if (s.sdgParallel != null) _par.text = fmt(s.sdgParallel, 2).replaceAll(',', '');
    _refresh(false);
  }

  @override
  void dispose() {
    _amount.dispose();
    _par.dispose();
    super.dispose();
  }

  Future<void> _refresh(bool force) async {
    final s = context.read<AppState>();
    setState(() => _loading = true);
    await refreshRates(s, force: force);
    if (!mounted) return;
    setState(() => _loading = false);
    if (force) {
      final at = s.ratesAt;
      toast(at != null && DateTime.now().millisecondsSinceEpoch - at < 60000
          ? 'الأسعار الرسمية اتحدّثت تمام ✓'
          : 'ما قدرنا نحدّث — شغّالين بالأسعار المحفوظة');
    }
  }

  void _saveFromTo(AppState s) {
    s.setData('currency_from', _from);
    s.setData('currency_to', _to);
  }

  void _saveParallel(AppState s) {
    final v = parseNum(_par.text);
    if (v <= 0) {
      toast('أكتب سعر الدولار في السوق الموازي بالجنيه');
      return;
    }
    s.sdgParallel = v;
    s.awardDaily('currency_parallel', 5, 'تحديث سعر السوق الموازي');
    FocusScope.of(context).unfocus();
    toast('حفظنا سعر الموازي: 1 دولار = ${fmt(v)} جنيه ✓');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final amount = parseNum(_amount.text);
    final par = s.useParallel;
    final rate = s.rate(_from, _to);
    final inv = rate == 0 ? 0.0 : 1 / rate;
    final result = amount * rate;
    final fromC = currencyByCode(_from), toC = currencyByCode(_to);
    final offSdg = s.usdRate('SDG', parallel: false);
    final parSdg = s.sdgParallel;
    final gap = parSdg == null ? null : (parSdg - offSdg) / offSdg * 100;
    final hist = (s.getData<List>('parallel_history') ?? [])
        .whereType<Map>()
        .map((m) => (t: DateTime.fromMillisecondsSinceEpoch((m['t'] as num).toInt()), v: (m['v'] as num).toDouble()))
        .toList();
    final at = s.ratesAt;
    final atText = at == null ? 'أسعار احتياطية تقريبية (ما في تحديث لسه)' : _when(DateTime.fromMillisecondsSinceEpoch(at));
    final usesSdg = _from == 'SDG' || _to == 'SDG';
    final otherPar = s.rate(_from, _to, parallel: true), otherOff = s.rate(_from, _to, parallel: false);

    String summary() => [
          '💱 تحويل عملات (${par ? 'السعر الموازي' : 'السعر الرسمي'})',
          '${fmt(amount)} ${fromC.name} = ${fmt(result)} ${toC.name}',
          '1 ${fromC.code} = ${fmtRate(rate)} ${toC.code}',
          '1 ${toC.code} = ${fmtRate(inv)} ${fromC.code}',
          if (parSdg != null) 'الدولار في الموازي: ${fmt(parSdg)} ج.س — الرسمي: ${fmt(offSdg)} ج.س',
          'آخر تحديث للأسعار الرسمية: $atText',
        ].join('\n');

    return ToolList(children: [
      // ── نوع السعر ──
      SCard(
        title: 'أي سعر داير تحسب بيهو؟',
        icon: Icons.swap_horizontal_circle_rounded,
        color: SD.green,
        trailing: IconButton(
          tooltip: 'حدّث الأسعار',
          onPressed: _loading ? null : () => _refresh(true),
          icon: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4))
              : const Icon(Icons.refresh_rounded),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('السعر الموازي'), icon: Icon(Icons.storefront_rounded)),
              ButtonSegment(value: false, label: Text('السعر الرسمي'), icon: Icon(Icons.account_balance_rounded)),
            ],
            selected: {par},
            onSelectionChanged: (v) => s.useParallel = v.first,
          ),
          const SizedBox(height: 8),
          Text('آخر تحديث للرسمي: $atText', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))),
          if (par && parSdg == null)
            const NoteBox('لسه ما كتبت سعر الموازي — بنحسب الجنيه بالسعر الرسمي لحدي ما تكتبو تحت في «سعر السوق الموازي».', kind: NoteKind.warn),
        ]),
      ),

      // ── التحويل ──
      SCard(
        title: 'حوّل قروشك',
        icon: Icons.currency_exchange_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          NumField('المبلغ', _amount, hint: 'أكتب هنا', suffix: fromC.sym, onChanged: (v) {
            s.setData('currency_amount', v);
            setState(() {});
          }),
          Wrap(spacing: 6, children: [
            for (final q in [1, 10, 50, 100, 500, 1000, 10000])
              ActionChip(
                label: Text(fmt(q)),
                onPressed: () => setState(() {
                  _amount.text = '$q';
                  s.setData('currency_amount', '$q');
                }),
              ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: CurrencyPicker('من', _from, (v) => setState(() {
                  _from = v;
                  _saveFromTo(s);
                }))),
            IconButton.filledTonal(
              tooltip: 'بدّل',
              onPressed: () => setState(() {
                final t = _from;
                _from = _to;
                _to = t;
                _saveFromTo(s);
              }),
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
            Expanded(child: CurrencyPicker('إلى', _to, (v) => setState(() {
                  _to = v;
                  _saveFromTo(s);
                }))),
          ]),
        ]),
      ),
      ResultHero(
        label: '${fmt(amount)} ${fromC.flag} ${fromC.name} بيساوي',
        value: '${fmt(result)} ${toC.sym}',
        sub: '${toC.flag} ${toC.name} • ${par ? 'بالسعر الموازي' : 'بالسعر الرسمي'}',
      ),
      SCard(
        title: 'تفاصيل السعر',
        icon: Icons.analytics_rounded,
        color: SD.indigo,
        child: Column(children: [
          InfoRow('1 ${fromC.name}', '${fmtRate(rate)} ${toC.sym}', icon: Icons.arrow_back_rounded),
          InfoRow('1 ${toC.name} (السعر العكسي)', '${fmtRate(inv)} ${fromC.sym}', icon: Icons.sync_alt_rounded),
          InfoRow('المبلغ بالدولار', '${fmt(amount / s.usdRate(_from))} \$', icon: Icons.attach_money_rounded),
          if (usesSdg && parSdg != null) ...[
            InfoRow('نفس المبلغ بالسعر الموازي', '${fmt(amount * otherPar)} ${toC.sym}', icon: Icons.storefront_rounded, valueColor: SD.green),
            InfoRow('نفس المبلغ بالسعر الرسمي', '${fmt(amount * otherOff)} ${toC.sym}', icon: Icons.account_balance_rounded, valueColor: SD.nile),
            InfoRow('الفرق بين السعرين', '${fmt((amount * otherPar - amount * otherOff).abs())} ${toC.sym}',
                icon: Icons.compare_arrows_rounded, valueColor: SD.henna),
          ],
          InfoRow('مبالغ سريعة', '10 = ${fmt(10 * rate)} • 100 = ${fmt(100 * rate)} • 1000 = ${fmt(1000 * rate)}',
              icon: Icons.bolt_rounded, hint: 'من ${fromC.code} إلى ${toC.code}'),
        ]),
      ),
      ShareBar(summary),
      const SizedBox(height: 14),

      // ── الموازي ──
      SCard(
        title: 'سعر السوق الموازي',
        icon: Icons.storefront_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const NoteBox('السعر الموازي ما بنجيبو من النت — إنت بتكتبو حسب السوق عندك (البنك ولا الصرافة ولا التاجر). كل ما تحفظ سعر جديد بنسجّلو في التاريخ.',
              kind: NoteKind.info),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: NumField('1 دولار = كم جنيه؟', _par, suffix: 'ج.س', hint: 'مثلًا 2500')),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: FilledButton.icon(onPressed: () => _saveParallel(s), icon: const Icon(Icons.save_rounded), label: const Text('احفظ')),
            ),
          ]),
          StatGrid([
            StatChip(fmt(offSdg), 'الرسمي ج.س/\$', color: SD.nile, icon: Icons.account_balance_rounded),
            StatChip(parSdg == null ? '—' : fmt(parSdg), 'الموازي ج.س/\$', color: SD.green, icon: Icons.storefront_rounded),
            StatChip(gap == null ? '—' : '${fmt(gap, 1)}%', 'الفجوة', color: (gap ?? 0) > 0 ? SD.red : SD.teal, icon: Icons.trending_up_rounded),
          ]),
          if (gap != null)
            NoteBox(
              gap > 0
                  ? 'الموازي أعلى من الرسمي بـ ${fmt(gap, 1)}% — يعني الدولار في السوق بيجيب ${fmt(parSdg! - offSdg)} جنيه زيادة.'
                  : 'الموازي قريب أو أقل من الرسمي (${fmt(gap, 1)}%).',
              kind: gap > 20 ? NoteKind.warn : NoteKind.tip,
            ),
          if (parSdg != null) ...[
            InfoRow('ريال سعودي في الموازي', '${fmt(parSdg / s.usdRate('SAR'))} ج.س', icon: Icons.flag_rounded),
            InfoRow('درهم إماراتي في الموازي', '${fmt(parSdg / s.usdRate('AED'))} ج.س', icon: Icons.flag_rounded),
            InfoRow('جنيه مصري في الموازي', '${fmt(parSdg / s.usdRate('EGP'))} ج.س', icon: Icons.flag_rounded),
          ],
        ]),
      ),

      // ── التاريخ ──
      SCard(
        title: 'تاريخ الموازي',
        icon: Icons.show_chart_rounded,
        color: SD.teal,
        trailing: hist.isEmpty
            ? null
            : IconButton(
                tooltip: 'امسح التاريخ',
                icon: const Icon(Icons.delete_sweep_rounded),
                onPressed: () => showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('نمسح التاريخ؟'),
                    content: const Text('كل الأسعار المسجّلة حتتمسح (السعر الحالي بيفضل).'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c), child: const Text('لا خلاص')),
                      FilledButton(
                          onPressed: () {
                            s.setData('parallel_history', []);
                            Navigator.pop(c);
                          },
                          child: const Text('أمسح')),
                    ],
                  ),
                ),
              ),
        child: hist.isEmpty
            ? const Text('لسه ما في أسعار محفوظة. احفظ أول سعر فوق وحيظهر هنا الرسم والتغيّر.')
            : _historyView(hist),
      ),

      // ── جداول ──
      SCard(
        title: 'كل العملات مقابل الجنيه',
        icon: Icons.table_chart_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          MiniTable(
            ['العملة', '1 = ج.س', '1000 ج.س ='],
            [
              for (final c in currencies.where((c) => c.code != 'SDG'))
                ['${c.flag} ${c.name}', fmtRate(s.rate(c.code, 'SDG')), '${fmtRate(1000 * s.rate('SDG', c.code))} ${c.sym}'],
            ],
            color: SD.green,
          ),
          const SizedBox(height: 6),
          Text(par ? 'محسوبة بالسعر الموازي للجنيه' : 'محسوبة بالسعر الرسمي', style: const TextStyle(fontSize: 12)),
        ]),
      ),
      SCard(
        title: 'كل العملات مقابل ${fromC.name}',
        icon: Icons.grid_on_rounded,
        color: SD.purple,
        child: MiniTable(
          ['العملة', '1 ${fromC.code} =', '${fmt(amount)} ${fromC.code} =', '1 = ${fromC.code}'],
          [
            for (final c in currencies.where((c) => c.code != _from))
              [
                '${c.flag} ${c.name}',
                fmtRate(s.rate(_from, c.code)),
                fmt(amount * s.rate(_from, c.code)),
                fmtRate(s.rate(c.code, _from)),
              ],
          ],
          color: SD.purple,
        ),
      ),
      const NoteBox('الأسعار الرسمية من مصدر مجاني على النت وبتتحدّث كل 6 ساعات، والموازي حسب ما إنت كتبت. قبل ما تصرف قروش كبيرة اتأكد من الصرافة.',
          kind: NoteKind.warn),
    ]);
  }

  Widget _historyView(List<({DateTime t, double v})> hist) {
    final vals = hist.map((e) => e.v).toList();
    final first = vals.first, last = vals.last;
    final total = (last - first) / first * 100;
    final mx = vals.reduce(math.max), mn = vals.reduce(math.min);
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    final shown = _showAllHistory ? hist.reversed.toList() : hist.reversed.take(8).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(height: 120, child: CustomPaint(painter: SparkPainter(vals, total >= 0 ? SD.red : SD.green))),
      const SizedBox(height: 10),
      StatGrid([
        StatChip(fmt(mx), 'أعلى سعر', color: SD.red, icon: Icons.arrow_upward_rounded),
        StatChip(fmt(mn), 'أقل سعر', color: SD.green, icon: Icons.arrow_downward_rounded),
        StatChip(fmt(avg), 'المتوسط', color: SD.nile, icon: Icons.functions_rounded),
      ]),
      const SizedBox(height: 8),
      InfoRow('التغيّر من أول تسجيل', '${total >= 0 ? '+' : ''}${fmt(total, 2)}%',
          icon: Icons.timeline_rounded, valueColor: total > 0 ? SD.red : SD.green, hint: 'من ${fmt(first)} إلى ${fmt(last)} (${hist.length} تسجيل)'),
      InfoRow('الفترة', '${fmtDateAr(hist.first.t, weekday: false)} ← ${fmtDateAr(hist.last.t, weekday: false)}', icon: Icons.date_range_rounded),
      const SizedBox(height: 6),
      for (var i = 0; i < shown.length; i++) _histRow(hist, hist.length - 1 - i),
      if (hist.length > 8)
        TextButton(
          onPressed: () => setState(() => _showAllHistory = !_showAllHistory),
          child: Text(_showAllHistory ? 'اعرض أقل' : 'اعرض الكل (${hist.length})'),
        ),
      const Text('🔴 طالع = الجنيه بيضعف • 🟢 نازل = الجنيه بيتحسّن', style: TextStyle(fontSize: 12)),
    ]);
  }

  Widget _histRow(List<({DateTime t, double v})> hist, int i) {
    final e = hist[i];
    final prev = i > 0 ? hist[i - 1].v : null;
    final ch = prev == null ? null : (e.v - prev) / prev * 100;
    return InfoRow(
      fmt(e.v),
      ch == null ? 'أول تسجيل' : '${ch >= 0 ? '▲ +' : '▼ '}${fmt(ch, 2)}%',
      hint: '${fmtDateAr(e.t, weekday: true)} • ${fmtTimeAr(e.t)}',
      icon: Icons.circle,
      valueColor: ch == null ? null : (ch > 0 ? SD.red : (ch < 0 ? SD.green : null)),
    );
  }

  String _when(DateTime d) {
    final diff = DateTime.now().difference(d);
    final ago = diff.inMinutes < 1
        ? 'هسي'
        : diff.inMinutes < 60
            ? 'قبل ${diff.inMinutes} دقيقة'
            : diff.inHours < 24
                ? 'قبل ${diff.inHours} ساعة'
                : 'قبل ${diff.inDays} يوم';
    return '${fmtDateAr(d, weekday: false)} ${fmtTimeAr(d)} ($ago)';
  }
}

/// رسم خطّي صغير (Sparkline)
class SparkPainter extends CustomPainter {
  final List<double> vals;
  final Color color;
  SparkPainter(this.vals, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (vals.isEmpty) return;
    final mx = vals.reduce(math.max), mn = vals.reduce(math.min);
    final range = (mx - mn) == 0 ? 1.0 : mx - mn;
    const pad = 8.0;
    Offset pt(int i) {
      final x = vals.length == 1 ? size.width / 2 : pad + (size.width - 2 * pad) * i / (vals.length - 1);
      final y = pad + (size.height - 2 * pad) * (1 - (vals[i] - mn) / range);
      return Offset(x, y);
    }

    final grid = Paint()
      ..color = color.withValues(alpha: .12)
      ..strokeWidth = 1;
    for (var k = 0; k <= 3; k++) {
      final y = pad + (size.height - 2 * pad) * k / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < vals.length; i++) {
      path.lineTo(pt(i).dx, pt(i).dy);
    }
    if (vals.length > 1) {
      final fill = Path.from(path)
        ..lineTo(pt(vals.length - 1).dx, size.height)
        ..lineTo(pt(0).dx, size.height)
        ..close();
      canvas.drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: .35), color.withValues(alpha: 0)])
                .createShader(Offset.zero & size));
      canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round);
    }
    final dot = Paint()..color = color;
    for (var i = 0; i < vals.length; i++) {
      canvas.drawCircle(pt(i), i == vals.length - 1 ? 5 : 2.6, dot);
    }
  }

  @override
  bool shouldRepaint(SparkPainter old) => old.vals != vals || old.color != color;
}
