import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart' show mapList, numOf, intOf, confirmAsk, EmptyHint;
import 'extra_common.dart';

/// نوع اللعبة
class _Preset {
  final String key;
  final bool low;
  final int limit, target;
  const _Preset(this.key, this.low, this.limit, this.target);

  String get name => switch (key) {
        'konkan' => t('كونكان', 'كونكان', 'Konkan'),
        'hand' => t('هاند', 'هاند', 'Hand'),
        _ => t('على كيفك', 'مخصّص', 'Custom'),
      };

  String get desc => switch (key) {
        'konkan' => t(
            'الأقل نقاط هو الكسبان. أي زول يتعدّى الحد (101 عادةً) يطلع من اللعبة، والآخر الفاضل يكسب. غيّر الحد على حسب قعدتكم.',
            'الأقل نقاطًا هو الفائز. من يتجاوز الحد (101 عادةً) يخرج من اللعبة، وآخر لاعب متبقٍ يفوز. عدّل الحد حسب اتفاقكم.',
            'Lowest score wins. Anyone who goes over the limit (usually 101) is out; the last player standing wins. Change the limit to match your table.'),
        'hand' => t(
            'الأقل نقاط هو الكسبان. حدّدوا الحد البتلعبوا ليهو (أو عدد الجولات) — كل قعدة ليها قوانينها.',
            'الأقل نقاطًا هو الفائز. حدّدوا الحد المتفق عليه (أو عدد الجولات) — لكل مجموعة قواعدها.',
            'Lowest score wins. Set the limit (or number of rounds) your group agrees on — every table has its own house rules.'),
        _ => t('إنت بتحدد: الأعلى ولا الأقل بكسب، والهدف أو الحد، وعدد الجولات.', 'أنت تحدد: هل يفوز الأعلى أم الأقل، والهدف أو الحد، وعدد الجولات.',
            'You choose: highest or lowest wins, the target/limit and the number of rounds.'),
      };
}

const _presets = [
  _Preset('konkan', true, 101, 0),
  _Preset('hand', true, 500, 0),
  _Preset('custom', false, 0, 100),
];

_Preset _preset(String? k) => _presets.firstWhere((p) => p.key == k, orElse: () => _presets.first);

/// حساب حالة اللعبة
class CardGame {
  final Map<String, dynamic> raw;
  CardGame(this.raw);

  String get presetKey => (raw['preset'] as String?) ?? 'konkan';
  bool get low => raw['low'] != false;
  int get limit => intOf(raw['limit']);
  int get target => intOf(raw['target']);
  int get cap => intOf(raw['cap']);
  List<String> get players => [for (final p in (raw['players'] as List? ?? const [])) '$p'];
  List<List<double>> get rounds => [
        for (final r in (raw['rounds'] as List? ?? const []))
          [for (var i = 0; i < players.length; i++) (r is List && i < r.length) ? numOf(r[i]) : 0.0]
      ];

  List<double> get totals {
    final t = List<double>.filled(players.length, 0);
    for (final r in rounds) {
      for (var i = 0; i < t.length; i++) {
        t[i] += r[i];
      }
    }
    return t;
  }

  /// اللاعبين الطالعين (تعدّوا الحد في وضع «الأقل يكسب»)
  List<bool> get out {
    final tt = totals;
    return [for (final v in tt) low && limit > 0 && v > limit];
  }

  int get activeCount => out.where((o) => !o).length;

  bool get over {
    if (players.length < 2 || rounds.isEmpty) return false;
    if (cap > 0 && rounds.length >= cap) return true;
    if (low) return limit > 0 && activeCount <= 1;
    return target > 0 && totals.any((v) => v >= target);
  }

  /// ترتيب اللاعبين (الأفضل أولًا) — الطالعين في الآخر
  List<int> get standing {
    final tt = totals, o = out;
    final idx = List.generate(players.length, (i) => i);
    idx.sort((a, b) {
      if (o[a] != o[b]) return o[a] ? 1 : -1;
      return low ? tt[a].compareTo(tt[b]) : tt[b].compareTo(tt[a]);
    });
    return idx;
  }

  /// الفائزين (قد يتعادل أكثر من واحد)
  List<int> get winners {
    final s = standing;
    if (s.isEmpty) return const [];
    final tt = totals, o = out;
    final best = s.first;
    return [for (final i in s) if (tt[i] == tt[best] && o[i] == o[best]) i];
  }
}

class CardScoresTool extends StatefulWidget {
  const CardScoresTool({super.key});
  @override
  State<CardScoresTool> createState() => _CardScoresToolState();
}

class _CardScoresToolState extends State<CardScoresTool> {
  String _presetKey = 'konkan';
  bool _low = true;
  final _limitC = TextEditingController(text: '101');
  final _targetC = TextEditingController(text: '100');
  final _capC = TextEditingController(text: '');
  final List<TextEditingController> _names = [];
  final List<TextEditingController> _round = [];
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    final s = context.read<AppState>();
    final last = (s.getData<List>('card_scores_names') ?? const []).map((e) => '$e').toList();
    final names = last.length >= 2 ? last : [t('أنا', 'أنا', 'Me'), t('أحمد', 'أحمد', 'Ahmed'), t('عثمان', 'عثمان', 'Osman')];
    for (final n in names.take(8)) {
      _names.add(TextEditingController(text: n));
    }
    final g = _game(s);
    if (g != null) _syncRound(g);
  }

  @override
  void dispose() {
    for (final c in [_limitC, _targetC, _capC, ..._names, ..._round]) {
      c.dispose();
    }
    super.dispose();
  }

  CardGame? _game(AppState s) {
    final m = s.getData<Map>('card_scores_game');
    if (m == null) return null;
    final g = CardGame(Map<String, dynamic>.from(m));
    return g.players.length >= 2 ? g : null;
  }

  void _syncRound(CardGame g) {
    while (_round.length < g.players.length) {
      _round.add(TextEditingController());
    }
    for (final c in _round) {
      c.clear();
    }
  }

  void _pickPreset(String k) {
    final p = _preset(k);
    setState(() {
      _presetKey = k;
      if (k != 'custom') {
        _low = p.low;
        _limitC.text = '${p.limit}';
      }
    });
  }

  void _start() {
    final s = context.read<AppState>();
    final names = [for (final c in _names) c.text.trim()].where((n) => n.isNotEmpty).toList();
    if (names.length < 2) return toast(t('محتاجين لاعبَين على الأقل', 'يلزم لاعبان على الأقل', 'At least 2 players are needed'));
    final low = _presetKey == 'custom' ? _low : _preset(_presetKey).low;
    final game = {
      'preset': _presetKey,
      'low': low,
      'limit': low ? parseNum(_limitC.text).round() : 0,
      'target': low ? 0 : parseNum(_targetC.text).round(),
      'cap': parseNum(_capC.text).round(),
      'players': names,
      'rounds': <List>[],
      'start': DateTime.now().millisecondsSinceEpoch,
    };
    s.setData('card_scores_names', names);
    s.setData('card_scores_game', game);
    s.awardDaily('card_scores', 3, tr('حاسبة الكوتشينة', 'Card scores'));
    _syncRound(CardGame(game));
    setState(() {});
  }

  void _addRound(CardGame g) {
    final s = context.read<AppState>();
    final o = g.out;
    final row = <double>[];
    var any = false;
    for (var i = 0; i < g.players.length; i++) {
      final txt = i < _round.length ? _round[i].text.trim() : '';
      if (txt.isNotEmpty) any = true;
      row.add(o[i] ? 0 : parseNum(txt));
    }
    if (!any) return toast(t('أكتب نقاط الجولة', 'اكتب نقاط الجولة', 'Enter the round scores'));
    final raw = Map<String, dynamic>.from(g.raw);
    raw['rounds'] = [...(raw['rounds'] as List? ?? const []), row];
    final ng = CardGame(raw);
    if (ng.over) _archive(s, ng);
    s.setData('card_scores_game', raw);
    HapticFeedback.selectionClick();
    _syncRound(ng);
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  void _archive(AppState s, CardGame g) {
    final h = mapList(s.getData<List>('card_scores_history'));
    final tt = g.totals;
    h.insert(0, {
      'preset': g.presetKey,
      'players': g.players,
      'totals': tt,
      'winners': [for (final w in g.winners) g.players[w]],
      'rounds': g.rounds.length,
      't': DateTime.now().millisecondsSinceEpoch,
    });
    s.setData('card_scores_history', h.take(40).toList());
    s.bump('card_games');
    s.award(5, tr('نهاية لعبة كوتشينة', 'Finished a card game'));
  }

  void _undo(CardGame g) {
    final s = context.read<AppState>();
    final raw = Map<String, dynamic>.from(g.raw);
    final r = List.from(raw['rounds'] as List? ?? const []);
    if (r.isEmpty) return;
    final wasOver = g.over;
    r.removeLast();
    raw['rounds'] = r;
    if (wasOver) {
      // شيل اللعبة من السجل لأنها رجعت شغّالة
      final h = mapList(s.getData<List>('card_scores_history'));
      if (h.isNotEmpty) s.setData('card_scores_history', h.sublist(1));
    }
    s.setData('card_scores_game', raw);
    setState(() {});
    toast(t('الجولة الأخيرة اتشالت', 'تم التراجع عن آخر جولة', 'Last round undone'));
  }

  void _newSame(CardGame g) {
    final s = context.read<AppState>();
    final raw = Map<String, dynamic>.from(g.raw)
      ..['rounds'] = <List>[]
      ..['start'] = DateTime.now().millisecondsSinceEpoch;
    s.setData('card_scores_game', raw);
    _syncRound(CardGame(raw));
    setState(() {});
  }

  Future<void> _end(CardGame g) async {
    if (g.rounds.isNotEmpty && !g.over) {
      final ok = await confirmAsk(context, t('نقفل اللعبة؟', 'إنهاء اللعبة؟', 'End this game?'),
          t('النقاط الحالية حتمشي وما بتتسجل في السجل.', 'ستُحذف النقاط الحالية ولن تُحفظ في السجل.', 'Current scores will be discarded and not saved to history.'));
      if (!ok || !mounted) return;
    }
    final s = context.read<AppState>();
    _presetKey = g.presetKey;
    _low = g.low;
    _names
      ..forEach((c) => c.dispose())
      ..clear()
      ..addAll([for (final p in g.players) TextEditingController(text: p)]);
    s.setData('card_scores_game', null);
    setState(() {});
  }

  String _fmtN(double v) => fmt(v, 1);

  String _summary(CardGame g) {
    final tt = g.totals, o = g.out;
    final b = StringBuffer()
      ..writeln('🃏 ${_preset(g.presetKey).name} — ${t('نتيجة الكوتشينة', 'نتيجة لعبة الورق', 'Card game scores')}')
      ..writeln('${t('الجولات', 'الجولات', 'Rounds')}: ${g.rounds.length}');
    var rank = 1;
    for (final i in g.standing) {
      b.writeln('${rank++}. ${g.players[i]}: ${_fmtN(tt[i])}${o[i] ? ' (${t('طلع', 'خرج', 'out')})' : ''}');
    }
    if (g.over) b.writeln('🏆 ${t('الكسبان', 'الفائز', 'Winner')}: ${[for (final w in g.winners) g.players[w]].join('، ')}');
    return b.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final g = _game(s);
    return ToolList(children: [
      if (g == null) ..._setup() else ..._play(g),
      _history(s),
    ]);
  }

  List<Widget> _setup() {
    final p = _preset(_presetKey);
    final low = _presetKey == 'custom' ? _low : p.low;
    return [
      SCard(
        title: t('لعبة جديدة', 'لعبة جديدة', 'New game'),
        icon: Icons.style_rounded,
        color: SD.henna,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          XSeg<String>([for (final x in _presets) (x.key, x.name)], _presetKey, _pickPreset),
          NoteBox(p.desc, kind: NoteKind.tip),
          if (_presetKey == 'custom') ...[
            XSeg<bool>([(false, t('الأعلى بكسب', 'الأعلى يفوز', 'Highest wins')), (true, t('الأقل بكسب', 'الأقل يفوز', 'Lowest wins'))], _low,
                (v) => setState(() => _low = v)),
            const SizedBox(height: 12),
          ],
          if (low)
            NumField(t('الحد (البتعدّاه يطلع)', 'الحد (من يتجاوزه يخرج)', 'Limit (over it = out)'), _limitC,
                decimal: false, hint: t('0 = بدون حد', '0 = بدون حد', '0 = no limit'))
          else
            NumField(t('الهدف (أول زول يوصلو بكسب)', 'الهدف (أول من يبلغه يفوز)', 'Target (first to reach wins)'), _targetC, decimal: false),
          NumField(t('عدد الجولات (اختياري)', 'عدد الجولات (اختياري)', 'Number of rounds (optional)'), _capC,
              decimal: false, hint: t('فاضي = لحدي ما تنتهي', 'فارغ = حتى النهاية', 'Empty = play until the end')),
        ]),
      ),
      SCard(
        title: t('اللعّيبة', 'اللاعبون', 'Players'),
        icon: Icons.groups_rounded,
        color: SD.nile,
        trailing: XBadge('${_names.length}/8', color: SD.nile),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < _names.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                CircleAvatar(radius: 14, backgroundColor: teamColors[i % teamColors.length], child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _names[i],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(isDense: true, hintText: '${t('لاعب', 'لاعب', 'Player')} ${i + 1}'),
                  ),
                ),
                IconButton(
                  tooltip: t('شيل', 'حذف', 'Remove'),
                  onPressed: _names.length <= 2
                      ? null
                      : () => setState(() {
                            _names.removeAt(i).dispose();
                          }),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
              ]),
            ),
          if (_names.length < 8)
            OutlinedButton.icon(
              onPressed: () => setState(() => _names.add(TextEditingController())),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(t('زيد لاعب', 'إضافة لاعب', 'Add player')),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _start, icon: const Icon(Icons.play_arrow_rounded), label: Text(t('يلا نبدأ', 'ابدأ اللعبة', 'Start game'))),
        ]),
      ),
    ];
  }

  List<Widget> _play(CardGame g) {
    final tt = g.totals, o = g.out, st = g.standing;
    final over = g.over;
    final leader = st.first;
    final goal = g.low ? g.limit : g.target;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return [
      ResultHero(
        label: over
            ? '🏆 ${t('الكسبان', 'الفائز', 'Winner')}'
            : '${_preset(g.presetKey).name} — ${t('الجولة', 'الجولة', 'Round')} ${g.rounds.length + 1}${g.cap > 0 ? ' / ${g.cap}' : ''}',
        value: over ? [for (final w in g.winners) g.players[w]].join(' • ') : (g.rounds.isEmpty ? '—' : g.players[leader]),
        sub: over
            ? '${_fmtN(tt[g.winners.first])} ${t('نقطة', 'نقطة', 'pts')} — ${g.rounds.length} ${t('جولة', 'جولة', 'rounds')}'
            : (g.rounds.isEmpty
                ? t('دخّل نقاط أول جولة', 'أدخل نقاط الجولة الأولى', 'Enter the first round scores')
                : '${t('المتصدّر', 'المتصدر', 'Leading')} — ${_fmtN(tt[leader])} ${t('نقطة', 'نقطة', 'pts')}'),
        colors: over ? SD.sunset : null,
      ),
      if (over)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: FilledButton.icon(
            onPressed: () => _newSame(g),
            icon: const Icon(Icons.replay_rounded),
            label: Text(t('لعبة جديدة بنفس الناس', 'لعبة جديدة بنفس اللاعبين', 'New game, same players')),
          ),
        ),
      SCard(
        title: t('المجموع', 'المجموع', 'Totals'),
        icon: Icons.leaderboard_rounded,
        color: SD.green,
        trailing: g.low && g.limit > 0 ? XBadge('${t('الحد', 'الحد', 'Limit')} ${g.limit}', color: SD.red) : (!g.low && g.target > 0 ? XBadge('${t('الهدف', 'الهدف', 'Target')} ${g.target}') : null),
        child: Column(children: [
          for (var r = 0; r < st.length; r++)
            Row(children: [
              SizedBox(
                width: 28,
                child: Text(o[st[r]] ? '✗' : (r == 0 && g.rounds.isNotEmpty ? '👑' : '${r + 1}'),
                    textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: XBar(
                  g.players[st[r]],
                  goal > 0 ? tt[st[r]] / goal : 0,
                  _fmtN(tt[st[r]]) + (g.low && g.limit > 0 && !o[st[r]] ? '  (${t('فاضل', 'متبقٍ', 'left')} ${_fmtN(g.limit - tt[st[r]])})' : ''),
                  color: g.low && goal > 0 && tt[st[r]] / goal > .8 ? SD.red : teamColors[st[r] % teamColors.length],
                  dim: o[st[r]],
                ),
              ),
            ]),
        ]),
      ),
      if (!over)
        SCard(
          title: '${t('نقاط الجولة', 'نقاط الجولة', 'Round scores')} ${g.rounds.length + 1}',
          icon: Icons.edit_note_rounded,
          color: SD.gold,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < g.players.length; i++)
              if (!o[i])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    CircleAvatar(radius: 6, backgroundColor: teamColors[i % teamColors.length]),
                    const SizedBox(width: 8),
                    Expanded(child: Text(g.players[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: i < _round.length ? _round[i] : null,
                        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(isDense: true, hintText: '0'),
                      ),
                    ),
                  ]),
                ),
            Text(t('تقدر تكتب سالب (مثلًا -30)', 'يمكنك إدخال قيمة سالبة (مثل -30)', 'Negative values allowed (e.g. -30)'),
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))),
            const SizedBox(height: 10),
            FilledButton.icon(onPressed: () => _addRound(g), icon: const Icon(Icons.add_task_rounded), label: Text(t('سجّل الجولة', 'تسجيل الجولة', 'Save round'))),
          ]),
        ),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: g.rounds.isEmpty ? null : () => _undo(g),
            icon: const Icon(Icons.undo_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('رجّع آخر جولة', 'تراجع عن الجولة', 'Undo round'))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _end(g),
            icon: const Icon(Icons.settings_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('لعبة/لعّيبة جدد', 'إعداد جديد', 'New setup'))),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      if (g.rounds.isNotEmpty)
        SCard(
          title: t('الجولات', 'سجل الجولات', 'Round history'),
          icon: Icons.table_rows_rounded,
          color: SD.coffee,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: rtl,
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(72),
              columnWidths: const {0: FixedColumnWidth(40)},
              border: TableBorder.symmetric(inside: BorderSide(color: SD.gold.withValues(alpha: .25))),
              children: [
                TableRow(children: [
                  _cell('#', bold: true),
                  for (final p in g.players) _cell(p, bold: true),
                ]),
                for (var r = 0; r < g.rounds.length; r++)
                  TableRow(children: [
                    _cell('${r + 1}'),
                    for (var i = 0; i < g.players.length; i++) _cell(_fmtN(g.rounds[r][i])),
                  ]),
                TableRow(decoration: BoxDecoration(color: SD.gold.withValues(alpha: .12)), children: [
                  _cell('Σ', bold: true),
                  for (var i = 0; i < g.players.length; i++) _cell(_fmtN(tt[i]), bold: true),
                ]),
              ],
            ),
          ),
        ),
      if (g.rounds.isNotEmpty) ...[ShareBar(() => _summary(g)), const SizedBox(height: 14)],
    ];
  }

  Widget _cell(String s, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Text(s,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: 13)),
      );

  Widget _history(AppState s) {
    final h = mapList(s.getData<List>('card_scores_history'));
    final wins = <String, int>{};
    for (final e in h) {
      for (final w in (e['winners'] as List? ?? const [])) {
        wins['$w'] = (wins['$w'] ?? 0) + 1;
      }
    }
    final top = wins.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return SCard(
      title: t('سجل القعدات', 'سجل الألعاب', 'Game history'),
      icon: Icons.history_rounded,
      color: SD.indigo,
      trailing: h.isEmpty
          ? null
          : IconButton(
              tooltip: t('امسح السجل', 'مسح السجل', 'Clear history'),
              onPressed: () async {
                if (await confirmAsk(context, t('نمسح السجل؟', 'مسح السجل؟', 'Clear history?'), t('كل الألعاب القديمة حتتمسح.', 'ستُحذف كل الألعاب السابقة.', 'All past games will be deleted.'))) {
                  s.setData('card_scores_history', <Map>[]);
                }
              },
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
      child: h.isEmpty
          ? EmptyHint(Icons.emoji_events_outlined, t('لسه ما في ألعاب خلصت', 'لا توجد ألعاب منتهية بعد', 'No finished games yet'))
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              StatGrid([
                StatChip('${h.length}', t('لعبة', 'لعبة', 'Games'), color: SD.indigo, icon: Icons.style_rounded),
                StatChip(top.isEmpty ? '—' : top.first.key, t('الأكتر كسبًا', 'الأكثر فوزًا', 'Top winner'), color: SD.gold, icon: Icons.emoji_events_rounded),
                StatChip(top.isEmpty ? '0' : '${top.first.value}', t('مرات كسب', 'مرات الفوز', 'Wins'), color: SD.green, icon: Icons.military_tech_rounded),
              ]),
              const SizedBox(height: 10),
              for (final e in h.take(15))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.emoji_events_rounded, color: SD.gold),
                  title: Text('${(e['winners'] as List? ?? const []).join('، ')} 🏆', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    '${_preset(e['preset'] as String?).name} • ${intOf(e['rounds'])} ${t('جولة', 'جولة', 'rounds')} • ${(e['players'] as List? ?? const []).length} ${t('لعّيبة', 'لاعبين', 'players')} • ${fmtDateAr(DateTime.fromMillisecondsSinceEpoch(intOf(e['t'])), weekday: false)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ]),
    );
  }
}
