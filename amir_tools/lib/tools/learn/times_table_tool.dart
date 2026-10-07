import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'learn_common.dart';

/// أربعة اختيارات مختلفة موجبة، منها الإجابة الصحيحة a×b
List<int> ttChoices(int a, int b, math.Random rnd) {
  final ans = a * b;
  final set = <int>{ans};
  final cands = <int>[
    a * (b + 1), a * (b - 1), (a + 1) * b, (a - 1) * b, ans + 1, ans - 1, ans + 2, ans - 2, ans + 10, ans - 10, (a + 1) * (b + 1),
  ]..shuffle(rnd);
  for (final c in cands) {
    if (set.length >= 4) break;
    if (c > 0) set.add(c);
  }
  var k = 3;
  while (set.length < 4) {
    set.add(ans + k++);
  }
  return set.toList()..shuffle(rnd);
}

/// عدد النجوم من نسبة الصح
int ttStars(int right, int total) {
  if (total == 0) return 0;
  final p = right / total;
  return p >= .9 ? 3 : (p >= .7 ? 2 : (p >= .5 ? 1 : 0));
}

List<String> get _cheers => switch (appLang) {
      Lang.sd => const ['عافي عليك! 👏', 'يا سلام عليك! 🌟', 'إنت شاطر شديد! 💪', 'كدا الكلام! 🔥', 'حريف والله! 🏆', 'تمام التمام! ✨', 'برافو عليك يا بطل! 🎉'],
      Lang.ar => const ['أحسنت! 👏', 'رائع! 🌟', 'ممتاز! 💪', 'هكذا يكون العمل! 🔥', 'بطل! 🏆', 'إجابة صحيحة! ✨', 'برافو! 🎉'],
      Lang.en => const ['Well done! 👏', 'Awesome! 🌟', 'Great job! 💪', "That's it! 🔥", 'Champion! 🏆', 'Correct! ✨', 'Bravo! 🎉'],
    };

class TimesTableTool extends StatefulWidget {
  const TimesTableTool({super.key});
  @override
  State<TimesTableTool> createState() => _TimesTableToolState();
}

class _TimesTableToolState extends State<TimesTableTool> {
  final _rnd = math.Random();
  int _mode = 0; // 0 جدول، 1 اختبار
  int _view = 7;

  // اللعبة
  bool _playing = false, _over = false;
  int _q = 0, _right = 0, _streak = 0, _bestStreakRun = 0;
  int _a = 1, _b = 1;
  List<int> _choices = [];
  int? _picked;
  String _msg = '';
  Timer? _timer;
  int _left = 0;
  final _wrongs = <String>[];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _cfg(AppState s) => Map<String, dynamic>.from(s.getData<Map>('times_table_cfg') ?? const {});
  Set<int> _tables(AppState s) {
    final l = (_cfg(s)['tables'] as List?)?.whereType<num>().map((e) => e.toInt()).toSet();
    return l == null || l.isEmpty ? {2, 3, 4, 5} : l;
  }

  int _count(AppState s) => lInt(_cfg(s)['count'], 10);
  bool _timed(AppState s) => _cfg(s)['timed'] == true;
  int _secs(AppState s) => lInt(_cfg(s)['secs'], 10);
  void _setCfg(AppState s, String k, dynamic v) => s.setData('times_table_cfg', {..._cfg(s), k: v});
  Map<String, dynamic> _best(AppState s) => Map<String, dynamic>.from(s.getData<Map>('times_table_best') ?? const {});

  void _start(AppState s) {
    setState(() {
      _playing = true;
      _over = false;
      _q = 0;
      _right = 0;
      _streak = 0;
      _bestStreakRun = 0;
      _wrongs.clear();
    });
    _next(s);
  }

  void _next(AppState s) {
    final tables = _tables(s).toList();
    _timer?.cancel();
    setState(() {
      _a = tables[_rnd.nextInt(tables.length)];
      _b = 1 + _rnd.nextInt(12);
      if (_rnd.nextBool()) {
        final x = _a;
        _a = _b;
        _b = x;
      }
      _choices = ttChoices(_a, _b, _rnd);
      _picked = null;
      _msg = '';
      _left = _secs(s);
    });
    if (_timed(s)) {
      _timer = Timer.periodic(const Duration(seconds: 1), (tm) {
        if (!mounted) return tm.cancel();
        setState(() => _left--);
        if (_left <= 0) {
          tm.cancel();
          _pick(s, -1);
        }
      });
    }
  }

  void _pick(AppState s, int v) {
    if (_picked != null) return;
    _timer?.cancel();
    final ok = v == _a * _b;
    setState(() {
      _picked = v;
      if (ok) {
        _right++;
        _streak++;
        _bestStreakRun = math.max(_bestStreakRun, _streak);
        _msg = _cheers[_rnd.nextInt(_cheers.length)];
      } else {
        _streak = 0;
        _wrongs.add('$_a × $_b = ${_a * _b}');
        _msg = v < 0
            ? t('الوكت خلص! الإجابة ${_a * _b}', 'انتهى الوقت! الإجابة ${_a * _b}', "Time's up! It's ${_a * _b}")
            : t('معليش، الصاح ${_a * _b} — المرة الجاية بتجيبها 💪', 'لا بأس، الصحيح ${_a * _b} — ستعرفها المرة القادمة 💪', 'Not quite — it’s ${_a * _b}. You’ll get it next time 💪');
      }
    });
    Future.delayed(Duration(milliseconds: ok ? 700 : 1500), () {
      if (!mounted || !_playing) return;
      if (_q + 1 >= _count(s)) {
        _finish(s);
      } else {
        _q++;
        _next(s);
      }
    });
  }

  void _finish(AppState s) {
    _timer?.cancel();
    final total = _count(s);
    final b = _best(s);
    final newBest = _right > lInt(b['score']) || (_right == lInt(b['score']) && total < lInt(b['total'], 999));
    s.setData('times_table_best', {
      'score': newBest ? _right : lInt(b['score']),
      'total': newBest ? total : lInt(b['total'], total),
      'streak': math.max(_bestStreakRun, lInt(b['streak'])),
      'games': lInt(b['games']) + 1,
    });
    final hist = lMaps(s.getData<List>('times_table_hist'))
      ..insert(0, {'d': lDk(lToday()), 'r': _right, 'n': total, 's': ttStars(_right, total)});
    s.setData('times_table_hist', hist.take(20).toList());
    if (_right > 0) s.award(math.min(20, _right), tr('جدول الضرب', 'Times tables'));
    s.bump('times_table_right', _right);
    setState(() {
      _playing = false;
      _over = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return ToolList(children: [
      lSegmented<int>(
        items: [(0, t('الجدول', 'الجدول', 'Table')), (1, t('العب واختبر', 'اختبار', 'Quiz game'))],
        value: _mode,
        onChanged: (v) {
          _timer?.cancel();
          setState(() {
            _mode = v;
            _playing = false;
            _over = false;
          });
        },
      ),
      const SizedBox(height: 14),
      if (_mode == 0) ..._table() else if (_playing) ..._game(s) else if (_over) ..._result(s) else ..._setup(s),
    ]);
  }

  /* ── عرض الجدول ── */
  List<Widget> _table() => [
        Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
          for (var n = 1; n <= 12; n++)
            ChoiceChip(label: Text('$n'), selected: _view == n, onSelected: (_) => setState(() => _view = n)),
        ]),
        const SizedBox(height: 14),
        SCard(
          title: '${t('جدول', 'جدول', 'Table of')} $_view',
          icon: Icons.grid_on_rounded,
          color: SD.orange,
          child: LayoutBuilder(builder: (context, c) {
            const gap = 8.0;
            final w = (c.maxWidth - gap) / 2;
            return Wrap(spacing: gap, runSpacing: gap, children: [
              for (var i = 1; i <= 12; i++)
                Container(
                  width: w,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: (i.isEven ? SD.gold : SD.orange).withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SD.gold.withValues(alpha: .4)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('$_view × $i = ${_view * i}',
                        textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ),
            ]);
          }),
        ),
        NoteBox(
            t('حيلة: جدول 9 — أرقام الناتج مجموعها 9 (9×4=36 ← 3+6=9). وجدول 5 دايمًا بينتهي بـ0 أو 5.',
                'حيلة: في جدول 9 مجموع أرقام الناتج 9 (9×4=36 ← 3+6=9)، وجدول 5 ينتهي دائمًا بـ0 أو 5.',
                'Trick: in the 9 table the digits add up to 9 (9×4=36 → 3+6=9); the 5 table always ends in 0 or 5.'),
            kind: NoteKind.tip),
      ];

  /* ── إعداد اللعبة ── */
  List<Widget> _setup(AppState s) {
    final tables = _tables(s);
    final best = _best(s);
    final hist = lMaps(s.getData<List>('times_table_hist'));
    return [
      StatGrid([
        StatChip(best.isEmpty ? '—' : '${lInt(best['score'])}/${lInt(best['total'])}', t('أحسن نتيجة', 'أفضل نتيجة', 'Best score'), color: SD.gold, icon: Icons.emoji_events_rounded),
        StatChip('${lInt(best['streak'])}', t('أطول سلسلة صاح', 'أطول سلسلة صحيحة', 'Best streak'), color: SD.orange, icon: Icons.local_fire_department_rounded),
        StatChip('${lInt(best['games'])}', t('مرات اللعب', 'مرات اللعب', 'Games'), color: SD.nile, icon: Icons.sports_esports_rounded),
      ]),
      const SizedBox(height: 14),
      SCard(
        title: t('اختار الجداول', 'اختر الجداول', 'Pick tables'),
        icon: Icons.checklist_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (var n = 1; n <= 12; n++)
              FilterChip(
                label: Text('$n'),
                selected: tables.contains(n),
                onSelected: (v) {
                  final x = {...tables};
                  v ? x.add(n) : x.remove(n);
                  if (x.isNotEmpty) _setCfg(s, 'tables', (x.toList()..sort()));
                },
              ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: () => _setCfg(s, 'tables', [for (var n = 1; n <= 12; n++) n]),
                child: Text(t('الكل', 'الكل', 'All'), maxLines: 1),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => _setCfg(s, 'tables', [2, 3, 4, 5]),
                child: Text(t('السهلة', 'السهلة', 'Easy'), maxLines: 1),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => _setCfg(s, 'tables', [6, 7, 8, 9]),
                child: Text(t('الصعبة', 'الصعبة', 'Hard'), maxLines: 1),
              ),
            ),
          ]),
          const Divider(),
          Text(t('عدد الأسئلة', 'عدد الأسئلة', 'Questions'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          lSegmented<int>(items: const [(10, '10'), (20, '20'), (30, '30')], value: const [10, 20, 30].contains(_count(s)) ? _count(s) : 10, onChanged: (v) => _setCfg(s, 'count', v)),
          const SizedBox(height: 6),
          lSwitch(t('بالوكت ⏱️', 'بمؤقّت ⏱️', 'With timer ⏱️'), _timed(s), (v) => _setCfg(s, 'timed', v),
              sub: t('وكت محدد لكل سؤال', 'وقت محدد لكل سؤال', 'Time limit per question')),
          if (_timed(s))
            LStepper(t('ثواني لكل سؤال', 'ثوانٍ لكل سؤال', 'Seconds per question'), _secs(s), (v) => _setCfg(s, 'secs', v), min: 3, max: 30),
        ]),
      ),
      SizedBox(
        height: 60,
        child: FilledButton.icon(
          onPressed: () => _start(s),
          icon: const Icon(Icons.play_circle_fill_rounded, size: 28),
          label: Text(t('يلا نلعب!', 'ابدأ اللعب!', "Let's play!"), style: const TextStyle(fontSize: 20)),
        ),
      ),
      if (hist.isNotEmpty) ...[
        const SizedBox(height: 14),
        SCard(
          title: t('آخر مرات اللعب', 'آخر الجولات', 'Recent games'),
          icon: Icons.history_rounded,
          color: SD.teal,
          child: Column(children: [
            for (final h in hist.take(8))
              InfoRow(
                lParseDk(h['d'] as String?) == null ? '—' : lShort(lParseDk(h['d'] as String?)!),
                '${lInt(h['r'])}/${lInt(h['n'])}  ${'⭐' * lInt(h['s'])}',
              ),
          ]),
        ),
      ],
    ];
  }

  /* ── اللعب ── */
  List<Widget> _game(AppState s) {
    final total = _count(s);
    return [
      Row(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: _q / total, minHeight: 10),
          ),
        ),
        const SizedBox(width: 10),
        Text('${_q + 1}/$total', style: const TextStyle(fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 10),
      StatGrid([
        StatChip('$_right', t('صاح', 'صحيح', 'Right'), color: SD.green, icon: Icons.check_circle_rounded),
        StatChip('$_streak 🔥', t('ورا بعض', 'متتالية', 'Streak'), color: SD.orange),
        StatChip(_timed(s) ? '$_left' : '∞', t('ثواني', 'ثوانٍ', 'Seconds'), color: _left <= 3 && _timed(s) ? SD.red : SD.nile, icon: Icons.timer_rounded),
      ]),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: SD.sunset),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: SD.goldLight, width: 2),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('$_a × $_b = ?', textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, c) {
        const gap = 12.0;
        final w = (c.maxWidth - gap) / 2;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final v in _choices)
            SizedBox(
              width: w,
              height: 76,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _picked == null
                      ? SD.nile
                      : (v == _a * _b ? SD.green : (v == _picked ? SD.red : SD.nile.withValues(alpha: .4))),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => _pick(s, v),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text('$v', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900))),
              ),
            ),
        ]);
      }),
      const SizedBox(height: 14),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Text(_msg, key: ValueKey(_msg), textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      ),
      const SizedBox(height: 10),
      TextButton.icon(
        onPressed: () {
          _timer?.cancel();
          setState(() => _playing = false);
        },
        icon: const Icon(Icons.stop_circle_outlined),
        label: Text(t('وقّف اللعبة', 'إيقاف اللعبة', 'Stop game')),
      ),
    ];
  }

  /* ── النتيجة ── */
  List<Widget> _result(AppState s) {
    final total = _count(s);
    final stars = ttStars(_right, total);
    final best = _best(s);
    final msg = switch (stars) {
      3 => t('ما شاء الله عليك، إنت نمرة واحد! 🏆', 'ما شاء الله، أنت الأول! 🏆', 'Amazing — you’re number one! 🏆'),
      2 => t('شغل نضيف! شوية كمان وبتبقى حريف 💪', 'عمل جيد! قليل من التدريب وتتقنها 💪', 'Nice work! A little more practice 💪'),
      1 => t('كويس! راجع الجدول وتعال تاني 🌱', 'جيد! راجع الجدول وحاول مجددًا 🌱', 'Good! Review the table and try again 🌱'),
      _ => t('ما تزعل، كل يوم بتتحسّن 🤗', 'لا تحزن، ستتحسن كل يوم 🤗', 'Don’t worry, you improve every day 🤗'),
    };
    return [
      ResultHero(label: msg, value: '$_right / $total', sub: '${'⭐' * stars}${'☆' * (3 - stars)}'),
      StatGrid([
        StatChip('${fmt(total == 0 ? 0 : _right / total * 100, 0)}%', t('نسبة الصاح', 'نسبة الصواب', 'Accuracy'), color: SD.green),
        StatChip('$_bestStreakRun', t('أطول سلسلة', 'أطول سلسلة', 'Best streak'), color: SD.orange),
        StatChip('${lInt(best['score'])}/${lInt(best['total'])}', t('الرقم القياسي', 'أفضل نتيجة', 'Record'), color: SD.gold),
      ]),
      const SizedBox(height: 14),
      if (_wrongs.isNotEmpty)
        SCard(
          title: t('راجع ديل', 'راجع هذه', 'Review these'),
          icon: Icons.replay_rounded,
          color: SD.red,
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final w in _wrongs.toSet())
              Chip(label: Text(w, textDirection: TextDirection.ltr)),
          ]),
        ),
      Row(children: [
        Expanded(
          child: FilledButton.icon(onPressed: () => _start(s), icon: const Icon(Icons.replay_rounded), label: Text(t('العب تاني', 'العب مجددًا', 'Play again'), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _over = false),
            icon: const Icon(Icons.tune_rounded),
            label: Text(t('الإعدادات', 'الإعدادات', 'Settings'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      ShareBar(() => '✖️ ${t('جدول الضرب', 'جدول الضرب', 'Times tables')}: $_right/$total ${'⭐' * stars}\n'
          '${t('الجداول', 'الجداول', 'Tables')}: ${(_tables(s).toList()..sort()).join(', ')}'),
    ];
  }
}
