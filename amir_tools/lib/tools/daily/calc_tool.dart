import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// خطأ في التعبير الحسابي
class CalcError implements Exception {
  final String msg;
  CalcError(this.msg);
  @override
  String toString() => msg;
}

/// محلّل تعبيرات حسابية (نزول تعاودي، بدون eval)
class CalcParser {
  final String src;
  final bool deg;
  final double ans;
  int _i = 0;
  bool _pctFlag = false, _termPct = false;
  CalcParser(this.src, {this.deg = true, this.ans = 0});

  static double eval(String s, {bool deg = true, double ans = 0}) {
    final p = CalcParser(s, deg: deg, ans: ans);
    if (s.trim().isEmpty) throw CalcError('فاضي');
    final v = p._expr();
    p._ws();
    if (p._i < p.src.length) throw CalcError('في حاجة غلط في «${p.src.substring(p._i)}»');
    if (v.isNaN) throw CalcError('غير معرّف');
    if (v.isInfinite) throw CalcError('لا نهاية ∞');
    return v;
  }

  void _ws() {
    while (_i < src.length && src[_i] == ' ') {
      _i++;
    }
  }

  String? get _peek {
    _ws();
    return _i < src.length ? src[_i] : null;
  }

  bool _eat(String t) {
    _ws();
    if (src.startsWith(t, _i)) {
      _i += t.length;
      return true;
    }
    return false;
  }

  double _expr() {
    var v = _term();
    while (true) {
      final c = _peek;
      if (c == '+' || c == '-' || c == '−') {
        _i++;
        final r = _term();
        final rr = _termPct ? v * r : r; // 200 + 10% = 220
        v = c == '+' ? v + rr : v - rr;
      } else {
        break;
      }
    }
    _termPct = false;
    return v;
  }

  static const _startChars = '0123456789.(πe√AsclatL';

  double _term() {
    var v = _unary();
    var p = _pctFlag;
    while (true) {
      final c = _peek;
      if (c == '×' || c == '*') {
        _i++;
        v *= _unary();
        p = false;
      } else if (c == '÷' || c == '/') {
        _i++;
        final r = _unary();
        if (r == 0) throw CalcError('ما بنقسم على صفر 🙅');
        v /= r;
        p = false;
      } else if (c != null && _startChars.contains(c)) {
        // ضرب ضمني: 2π ، 3(4) ، 2sin30
        v *= _unary();
        p = false;
      } else {
        break;
      }
    }
    _termPct = p;
    return v;
  }

  double _unary() {
    final c = _peek;
    if (c == '-' || c == '−') {
      _i++;
      final v = -_unary();
      return v;
    }
    if (c == '+') {
      _i++;
      return _unary();
    }
    return _power();
  }

  double _power() {
    final b = _postfix();
    if (_eat('^')) {
      final e = _unary();
      _pctFlag = false;
      final r = math.pow(b, e).toDouble();
      return r;
    }
    return b;
  }

  double _postfix() {
    var v = _primary();
    _pctFlag = false;
    while (true) {
      if (_eat('!')) {
        v = _fact(v);
        _pctFlag = false;
      } else if (_eat('%')) {
        v = v / 100;
        _pctFlag = true;
      } else {
        break;
      }
    }
    return v;
  }

  double _fact(double v) {
    if (v < 0 || v != v.roundToDouble()) throw CalcError('المضروب (!) للأعداد الصحيحة الموجبة بس');
    if (v > 170) throw CalcError('الرقم كبير شديد للمضروب');
    var r = 1.0;
    for (var k = 2; k <= v; k++) {
      r *= k;
    }
    return r;
  }

  double _toRad(double x) => deg ? x * math.pi / 180 : x;
  double _fromRad(double x) => deg ? x * 180 / math.pi : x;

  double _arg() {
    if (_eat('(')) {
      final v = _expr();
      _eat(')'); // نسمح بنسيان القوس الأخير
      return v;
    }
    return _postfix();
  }

  double _primary() {
    _ws();
    if (_i >= src.length) throw CalcError('التعبير ناقص');
    final c = src[_i];
    if (c == '(') {
      _i++;
      final saved = _termPct;
      final v = _expr();
      _termPct = saved;
      _eat(')');
      return v;
    }
    if ('0123456789.'.contains(c)) return _number();
    if (_eat('π')) return math.pi;
    if (_eat('Ans')) return ans;
    if (_eat('√')) {
      final v = _postfixNoPct();
      if (v < 0) throw CalcError('ما في جذر لعدد سالب');
      return math.sqrt(v);
    }
    // الدوال
    const fns = ['asin', 'acos', 'atan', 'sin', 'cos', 'tan', 'log', 'ln'];
    for (final f in fns) {
      if (_eat(f)) {
        final x = _arg();
        switch (f) {
          case 'sin':
            return _clean(math.sin(_toRad(x)));
          case 'cos':
            return _clean(math.cos(_toRad(x)));
          case 'tan':
            if (deg && ((x - 90) % 180).abs() < 1e-12) throw CalcError('ظل 90° غير معرّف');
            return _clean(math.tan(_toRad(x)));
          case 'asin':
            if (x.abs() > 1) throw CalcError('asin بين -1 و 1 بس');
            return _clean(_fromRad(math.asin(x)));
          case 'acos':
            if (x.abs() > 1) throw CalcError('acos بين -1 و 1 بس');
            return _clean(_fromRad(math.acos(x)));
          case 'atan':
            return _clean(_fromRad(math.atan(x)));
          case 'log':
            if (x <= 0) throw CalcError('اللوغاريتم للأعداد الموجبة بس');
            return math.log(x) / math.ln10;
          case 'ln':
            if (x <= 0) throw CalcError('ln للأعداد الموجبة بس');
            return math.log(x);
        }
      }
    }
    if (_eat('e')) return math.e;
    throw CalcError('ما فهمت «$c»');
  }

  double _postfixNoPct() {
    final v = _postfix();
    _pctFlag = false;
    return v;
  }

  double _clean(double v) => v.abs() < 1e-14 ? 0 : v;

  double _number() {
    final st = _i;
    while (_i < src.length && '0123456789.'.contains(src[_i])) {
      _i++;
    }
    // أس علمي: 1.5e+21
    if (_i + 1 < src.length && src[_i] == 'e' && (src[_i + 1] == '+' || src[_i + 1] == '-' || '0123456789'.contains(src[_i + 1]))) {
      final save = _i;
      _i++;
      if (src[_i] == '+' || src[_i] == '-') _i++;
      final ds = _i;
      while (_i < src.length && '0123456789'.contains(src[_i])) {
        _i++;
      }
      if (_i == ds) _i = save;
    }
    final t = src.substring(st, _i);
    final v = double.tryParse(t);
    if (v == null) throw CalcError('رقم غلط «$t»');
    return v;
  }
}

/// تنسيق نتيجة الآلة الحاسبة
String calcFmt(double v) {
  if (v == 0) return '0';
  final a = v.abs();
  if (a >= 1e15 || a < 1e-9) return v.toStringAsExponential(8).replaceFirst(RegExp(r'\.?0+e'), 'e');
  final r = double.parse(v.toStringAsPrecision(12));
  return fmt(r, 10);
}

String _raw(double v) {
  final a = v.abs();
  if (v == 0) return '0';
  if (a >= 1e15 || a < 1e-9) return v.toStringAsExponential(10);
  var s = double.parse(v.toStringAsPrecision(12)).toString();
  if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
  return s;
}

class CalcTool extends StatefulWidget {
  const CalcTool({super.key});
  @override
  State<CalcTool> createState() => _CalcToolState();
}

class _CalcToolState extends State<CalcTool> {
  String expr = '';
  bool deg = true, second = false, justEvaluated = false;
  double ans = 0;
  String? error;
  List<Map<String, dynamic>> hist = [];

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    deg = s.getData<bool>('calc_deg') ?? true;
    ans = (s.getData<num>('calc_ans') ?? 0).toDouble();
    hist = List<Map<String, dynamic>>.from((s.getData<List>('calc_hist') ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
  }

  double? get _preview {
    try {
      return CalcParser.eval(_balanced(expr), deg: deg, ans: ans);
    } catch (_) {
      return null;
    }
  }

  String _balanced(String e) {
    final open = '('.allMatches(e).length - ')'.allMatches(e).length;
    return open > 0 ? e + ')' * open : e;
  }

  void _press(String k) {
    HapticFeedback.selectionClick();
    setState(() {
      error = null;
      const ops = ['+', '−', '×', '÷', '^', '%', '!'];
      if (justEvaluated) {
        if (ops.contains(k)) {
          expr = 'Ans';
        } else {
          expr = '';
        }
        justEvaluated = false;
      }
      switch (k) {
        case 'AC':
          expr = '';
        case '⌫':
          if (expr.isEmpty) break;
          for (final t in ['asin(', 'acos(', 'atan(', 'sin(', 'cos(', 'tan(', 'log(', 'ln(', 'Ans']) {
            if (expr.endsWith(t)) {
              expr = expr.substring(0, expr.length - t.length);
              return;
            }
          }
          expr = expr.substring(0, expr.length - 1);
        case '=':
          _evaluate();
        case 'x²':
          expr += '^2';
        case 'sin' || 'cos' || 'tan':
          expr += '${second ? 'a' : ''}$k(';
          second = false;
        case 'log' || 'ln':
          expr += '$k(';
        default:
          expr += k;
      }
    });
  }

  void _evaluate() {
    if (expr.trim().isEmpty) return;
    try {
      final e = _balanced(expr);
      final v = CalcParser.eval(e, deg: deg, ans: ans);
      ans = v;
      hist.insert(0, {'e': e, 'r': v, 't': DateTime.now().millisecondsSinceEpoch, 'd': deg});
      if (hist.length > 60) hist = hist.sublist(0, 60);
      final s = context.read<AppState>();
      s.setData('calc_hist', hist);
      s.setData('calc_ans', v);
      expr = _raw(v);
      justEvaluated = true;
    } on CalcError catch (er) {
      error = er.msg;
    } catch (_) {
      error = 'في حاجة غلط في الحساب';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pv = _preview;
    final muted = cs.onSurface.withValues(alpha: .55);
    return ToolList(children: [
      SCard(
        color: SD.nile,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              _tag(deg ? 'DEG' : 'RAD', SD.gold),
              const SizedBox(width: 6),
              if (second) _tag('2nd', SD.henna),
              const Spacer(),
              Text('Ans = ${calcFmt(ans)}', style: TextStyle(color: muted, fontSize: 12)),
            ]),
            const SizedBox(height: 10),
            GestureDetector(
              onLongPress: () => copyText(expr),
              child: Text(
                expr.isEmpty ? '0' : expr,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: expr.length > 18 ? 24 : 34, fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onLongPress: pv == null ? null : () => copyText(_raw(pv)),
              child: Text(
                error ?? (pv != null && !justEvaluated ? '= ${calcFmt(pv)}' : ' '),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 20, color: error != null ? SD.red : SD.gold, fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ),
      ),
      _keypad(),
      if (justEvaluated) _extras(ans),
      SectionTitle('السجل', icon: Icons.history_rounded, trailing: hist.isEmpty
          ? null
          : TextButton.icon(
              onPressed: () {
                setState(() => hist.clear());
                context.read<AppState>().setData('calc_hist', hist);
              },
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const Text('امسح'),
            )),
      if (hist.isEmpty)
        const NoteBox('لسه ما حسبت حاجة. أي عملية تعملها بتتحفظ هنا — دوس عليها عشان تستخدم النتيجة، ودوسة طويلة ترجّع العملية كلها.', kind: NoteKind.tip)
      else
        SCard(
          color: SD.teal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(children: [
            for (final h in hist.take(30))
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(h['e'] as String, textDirection: TextDirection.ltr, textAlign: TextAlign.right, style: TextStyle(color: muted)),
                subtitle: Text('= ${calcFmt((h['r'] as num).toDouble())}',
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: SD.teal)),
                leading: const Icon(Icons.replay_rounded, size: 20),
                onTap: () => setState(() {
                  if (justEvaluated) {
                    expr = '';
                    justEvaluated = false;
                  }
                  expr += _raw((h['r'] as num).toDouble());
                  error = null;
                }),
                onLongPress: () => setState(() {
                  expr = h['e'] as String;
                  justEvaluated = false;
                  error = null;
                }),
              ),
          ]),
        ),
      const NoteBox('النسبة: «200+10%» = 220 و«200×10%» = 20 زي آلة الدكان. والدوال المثلثية بالدرجات أو الراديان حسب زر DEG/RAD.'),
    ]);
  }

  Widget _tag(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: c.withValues(alpha: .18), borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12)),
      );

  Widget _extras(double v) {
    final isInt = v == v.roundToDouble() && v.abs() < 9e15;
    return SCard(
      title: 'النتيجة بأشكال تانية',
      icon: Icons.auto_awesome_rounded,
      color: SD.gold,
      child: Column(children: [
        InfoRow('بالصيغة العلمية', v.toStringAsExponential(6), valueColor: SD.gold),
        InfoRow('مقرّبة لرقمين', fmt(v, 2)),
        if (!isInt && v.abs() < 1e12) InfoRow('كنسبة مئوية', '${fmt(v * 100, 4)}%'),
        if (isInt && v.abs() < 1e12) ...[
          InfoRow('بالثنائي (Binary)', v.toInt().toRadixString(2)),
          InfoRow('بالسداسي عشري (Hex)', v.toInt().toRadixString(16).toUpperCase()),
        ],
        if (v != 0) InfoRow('المقلوب 1/x', calcFmt(1 / v)),
        if (v >= 0) InfoRow('الجذر التربيعي', calcFmt(math.sqrt(v))),
        InfoRow('المربع', calcFmt(v * v)),
      ]),
    );
  }

  Widget _keypad() {
    final sci = [
      ['2nd', deg ? 'DEG' : 'RAD', 'sin', 'cos', 'tan'],
      ['ln', 'log', '√', 'x²', '^'],
      ['π', 'e', '!', '(', ')'],
    ];
    final main = [
      ['7', '8', '9', '⌫', 'AC'],
      ['4', '5', '6', '×', '÷'],
      ['1', '2', '3', '+', '−'],
      ['0', '.', '%', 'Ans', '='],
    ];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(children: [
        for (final r in sci) _row(r, small: true),
        const SizedBox(height: 6),
        for (final r in main) _row(r),
        const SizedBox(height: 10),
      ]),
    );
  }

  Widget _row(List<String> keys, {bool small = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(children: [for (final k in keys) Expanded(child: _key(k, small))]),
      );

  Widget _key(String k, bool small) {
    final cs = Theme.of(context).colorScheme;
    Color bg, fg;
    String label = k;
    if (k == '=') {
      bg = SD.green;
      fg = Colors.white;
    } else if (k == 'AC') {
      bg = SD.red.withValues(alpha: .85);
      fg = Colors.white;
    } else if (k == '⌫') {
      bg = SD.henna.withValues(alpha: .2);
      fg = SD.henna;
    } else if (['+', '−', '×', '÷', '%'].contains(k)) {
      bg = SD.gold.withValues(alpha: .22);
      fg = SD.gold;
    } else if (small) {
      bg = SD.nile.withValues(alpha: .14);
      fg = cs.onSurface;
      if (k == '2nd' && second) {
        bg = SD.henna;
        fg = Colors.white;
      }
      if (second && ['sin', 'cos', 'tan'].contains(k)) label = '$k⁻¹';
    } else {
      bg = cs.onSurface.withValues(alpha: .07);
      fg = cs.onSurface;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.5),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (k == '2nd') {
              setState(() => second = !second);
            } else if (k == 'DEG' || k == 'RAD') {
              setState(() => deg = !deg);
              context.read<AppState>().setData('calc_deg', deg);
            } else {
              _press(k);
            }
          },
          onLongPress: k == '⌫' ? () => _press('AC') : null,
          child: SizedBox(
            height: small ? 46 : 62,
            child: Center(
              child: Text(label, style: TextStyle(fontSize: small ? 16 : 26, fontWeight: FontWeight.w700, color: fg)),
            ),
          ),
        ),
      ),
    );
  }
}
