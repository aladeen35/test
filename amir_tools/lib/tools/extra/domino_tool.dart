import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart' show mapList, intOf, confirmAsk, EmptyHint, PickChip;
import 'extra_common.dart';

/// تقسيم الأسماء على فرق بشكل عادل (الفرق بين أحجام الفرق ≤ 1)
List<List<String>> splitTeams(List<String> names, int n, [math.Random? rnd]) {
  final l = [...names]..shuffle(rnd ?? math.Random());
  final teams = List.generate(n, (_) => <String>[]);
  for (var i = 0; i < l.length; i++) {
    teams[i % n].add(l[i]);
  }
  return teams;
}

class DominoTool extends StatefulWidget {
  const DominoTool({super.key});
  @override
  State<DominoTool> createState() => _DominoToolState();
}

class _DominoToolState extends State<DominoTool> {
  int _tab = 0;
  String _mode = 'teams';
  final List<TextEditingController> _names = [];
  final _targetC = TextEditingController(text: '101');
  final _ptsC = TextEditingController();
  int? _winner;
  final _splitC = TextEditingController();
  int _teamsN = 2;
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    final s = context.read<AppState>();
    _resetNames('teams');
    final sp = Map<String, dynamic>.from(s.getData<Map>('domino_split') ?? const {});
    _splitC.text = (sp['names'] as String?) ?? '';
    _teamsN = intOf(sp['n'], 2).clamp(2, 6);
  }

  void _resetNames(String mode) {
    for (final c in _names) {
      c.dispose();
    }
    _names.clear();
    final def = mode == 'teams'
        ? [t('فريقنا', 'فريقنا', 'Us'), t('فريقهم', 'فريقهم', 'Them')]
        : [t('أنا', 'أنا', 'Me'), t('محمد', 'محمد', 'Mohamed'), t('علي', 'علي', 'Ali')];
    _names.addAll([for (final n in def) TextEditingController(text: n)]);
  }

  @override
  void dispose() {
    for (final c in [..._names, _targetC, _ptsC, _splitC]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic>? _game(AppState s) {
    final m = s.getData<Map>('domino_game');
    return m == null ? null : Map<String, dynamic>.from(m);
  }

  List<String> _gNames(Map g) => [for (final n in (g['names'] as List? ?? const [])) '$n'];
  List<Map<String, dynamic>> _gRounds(Map g) => mapList(g['rounds']);

  List<int> _totals(Map g) {
    final names = _gNames(g);
    final tt = List<int>.filled(names.length, 0);
    for (final r in _gRounds(g)) {
      final w = intOf(r['w'], -1);
      if (w >= 0 && w < tt.length) tt[w] += intOf(r['p']);
    }
    return tt;
  }

  int? _champ(Map g) {
    final tgt = intOf(g['target'], 101);
    final tt = _totals(g);
    if (tgt <= 0 || tt.isEmpty) return null;
    final best = tt.reduce(math.max);
    return best >= tgt ? tt.indexOf(best) : null;
  }

  void _start() {
    final names = [for (final c in _names) c.text.trim()].where((e) => e.isNotEmpty).toList();
    if (names.length < 2) return toast(t('محتاجين طرفين على الأقل', 'يلزم طرفان على الأقل', 'At least 2 sides needed'));
    final s = context.read<AppState>();
    s.setData('domino_game', {
      'mode': _mode,
      'names': names,
      'target': math.max(1, parseNum(_targetC.text, 101).round()),
      'rounds': <Map>[],
      'start': DateTime.now().millisecondsSinceEpoch,
    });
    s.awardDaily('domino', 3, tr('الدومينو', 'Domino'));
    setState(() => _winner = null);
  }

  void _add(Map<String, dynamic> g) {
    final p = parseNum(_ptsC.text).round();
    if (_winner == null) return toast(t('اختار منو كسب الجولة', 'اختر الفائز بالجولة', 'Pick who won the round'));
    if (p <= 0) return toast(t('أكتب النقاط', 'اكتب النقاط', 'Enter the points'));
    final s = context.read<AppState>();
    g['rounds'] = [..._gRounds(g), {'w': _winner, 'p': p}];
    final c = _champ(g);
    if (c != null) {
      final names = _gNames(g);
      final h = mapList(s.getData<List>('domino_history'));
      h.insert(0, {'names': names, 'totals': _totals(g), 'winner': names[c], 'rounds': _gRounds(g).length, 't': DateTime.now().millisecondsSinceEpoch});
      s.setData('domino_history', h.take(40).toList());
      s.bump('domino_games');
      s.award(5, tr('نهاية لعبة دومينو', 'Finished a domino game'));
    }
    s.setData('domino_game', g);
    HapticFeedback.selectionClick();
    _ptsC.clear();
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  void _undo(Map<String, dynamic> g) {
    final s = context.read<AppState>();
    final r = _gRounds(g);
    if (r.isEmpty) return;
    if (_champ(g) != null) {
      final h = mapList(s.getData<List>('domino_history'));
      if (h.isNotEmpty) s.setData('domino_history', h.sublist(1));
    }
    g['rounds'] = r.sublist(0, r.length - 1);
    s.setData('domino_game', g);
    setState(() {});
  }

  void _again(Map<String, dynamic> g) {
    g['rounds'] = <Map>[];
    g['start'] = DateTime.now().millisecondsSinceEpoch;
    context.read<AppState>().setData('domino_game', g);
    setState(() => _winner = null);
  }

  Future<void> _setupAgain(Map<String, dynamic> g) async {
    final ch = _champ(g);
    if (_gRounds(g).isNotEmpty && ch == null) {
      final ok = await confirmAsk(context, t('نقفل اللعبة؟', 'إنهاء اللعبة؟', 'End this game?'),
          t('النقاط الحالية حتمشي.', 'ستُحذف النقاط الحالية.', 'Current scores will be discarded.'));
      if (!ok || !mounted) return;
    }
    _mode = (g['mode'] as String?) ?? 'teams';
    for (final c in _names) {
      c.dispose();
    }
    _names
      ..clear()
      ..addAll([for (final n in _gNames(g)) TextEditingController(text: n)]);
    _targetC.text = '${intOf(g['target'], 101)}';
    if (!mounted) return;
    context.read<AppState>().setData('domino_game', null);
    setState(() {});
  }

  String _summary(Map g) {
    final names = _gNames(g), tt = _totals(g);
    final ch = _champ(g);
    return [
      '🁫 ${t('نتيجة الدومينو', 'نتيجة الدومينو', 'Domino scores')} (${t('الهدف', 'الهدف', 'Target')} ${intOf(g['target'], 101)})',
      for (var i = 0; i < names.length; i++) '${names[i]}: ${tt[i]}',
      '${t('الجولات', 'الجولات', 'Rounds')}: ${_gRounds(g).length}',
      if (ch != null) '🏆 ${t('الكسبان', 'الفائز', 'Winner')}: ${names[ch]}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return ToolList(children: [
      XSeg<int>([(0, t('حساب النقاط', 'حساب النقاط', 'Scores')), (1, t('قسّم الفرق', 'تقسيم الفرق', 'Split teams'))], _tab, (v) => setState(() => _tab = v)),
      const SizedBox(height: 14),
      if (_tab == 0) ...(_game(s) == null ? _setup() : _play(_game(s)!)) else ..._split(s),
      if (_tab == 0) _history(s),
    ]);
  }

  List<Widget> _setup() => [
        SCard(
          title: t('دومينو جديد', 'لعبة دومينو جديدة', 'New domino game'),
          icon: Icons.casino_rounded,
          color: SD.coffee,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            XSeg<String>([('teams', t('فريقين', 'فريقان', 'Two teams')), ('solo', t('أفراد', 'أفراد', 'Individuals'))], _mode, (v) {
              setState(() {
                _mode = v;
                _resetNames(v);
              });
            }),
            const SizedBox(height: 12),
            for (var i = 0; i < _names.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  CircleAvatar(radius: 8, backgroundColor: teamColors[i % teamColors.length]),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _names[i], decoration: const InputDecoration(isDense: true))),
                  if (_mode == 'solo')
                    IconButton(
                      onPressed: _names.length <= 2 ? null : () => setState(() => _names.removeAt(i).dispose()),
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                ]),
              ),
            if (_mode == 'solo' && _names.length < 4)
              OutlinedButton.icon(
                onPressed: () => setState(() => _names.add(TextEditingController())),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(t('زيد لاعب', 'إضافة لاعب', 'Add player')),
              ),
            const SizedBox(height: 10),
            NumField(t('الهدف (أول زول يوصلو بكسب)', 'الهدف (أول من يبلغه يفوز)', 'Target (first to reach wins)'), _targetC, decimal: false),
            NoteBox(
                t('الكسبان في كل جولة بياخد مجموع نقاط (بنط) الحجارة الفضلت مع الباقين — أو على حسب قانون قعدتكم.',
                    'الفائز بكل جولة يأخذ مجموع نقاط الأحجار المتبقية مع الآخرين — أو حسب قواعد مجموعتكم.',
                    'The round winner usually scores the pips left in the others\' hands — or follow your own house rules.'),
                kind: NoteKind.tip),
            FilledButton.icon(onPressed: _start, icon: const Icon(Icons.play_arrow_rounded), label: Text(t('يلا نبدأ', 'ابدأ', 'Start'))),
          ]),
        ),
      ];

  List<Widget> _play(Map<String, dynamic> g) {
    final names = _gNames(g), tt = _totals(g), rounds = _gRounds(g);
    final tgt = intOf(g['target'], 101);
    final ch = _champ(g);
    if (_winner != null && _winner! >= names.length) _winner = null;
    return [
      ResultHero(
        label: ch != null ? '🏆 ${t('الكسبان', 'الفائز', 'Winner')}' : '${t('الجولة', 'الجولة', 'Round')} ${rounds.length + 1} — ${t('الهدف', 'الهدف', 'Target')} $tgt',
        value: ch != null ? names[ch] : tt.join(' — '),
        sub: ch != null ? '${tt[ch]} ${t('نقطة', 'نقطة', 'pts')} • ${rounds.length} ${t('جولة', 'جولة', 'rounds')}' : names.join(' — '),
        colors: ch != null ? SD.sunset : null,
      ),
      SCard(
        title: t('النتيجة', 'النتيجة', 'Score'),
        icon: Icons.scoreboard_rounded,
        color: SD.green,
        child: Column(children: [
          for (var i = 0; i < names.length; i++)
            XBar(names[i], tt[i] / tgt, '${tt[i]} / $tgt', color: teamColors[i % teamColors.length]),
        ]),
      ),
      if (ch == null)
        SCard(
          title: t('جولة جديدة', 'جولة جديدة', 'New round'),
          icon: Icons.add_circle_outline_rounded,
          color: SD.gold,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t('منو كسب الجولة؟', 'من فاز بالجولة؟', 'Who won the round?'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (var i = 0; i < names.length; i++)
                PickChip(names[i], _winner == i, () => setState(() => _winner = i), color: teamColors[i % teamColors.length]),
            ]),
            const SizedBox(height: 10),
            NumField(t('النقاط', 'النقاط', 'Points'), _ptsC, decimal: false),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final q in [5, 10, 15, 20, 25])
                ActionChip(
                  label: Text('+$q'),
                  onPressed: () => setState(() => _ptsC.text = '${parseNum(_ptsC.text).round() + q}'),
                ),
              ActionChip(label: Text(t('صفّر', 'تصفير', 'Clear')), onPressed: () => setState(_ptsC.clear)),
            ]),
            const SizedBox(height: 10),
            FilledButton.icon(onPressed: () => _add(g), icon: const Icon(Icons.add_task_rounded), label: Text(t('سجّل', 'تسجيل', 'Save'))),
          ]),
        )
      else
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: FilledButton.icon(
            onPressed: () => _again(g),
            icon: const Icon(Icons.replay_rounded),
            label: Text(t('لعبة جديدة بنفس الأسماء', 'لعبة جديدة بنفس الأسماء', 'New game, same names')),
          ),
        ),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: rounds.isEmpty ? null : () => _undo(g),
            icon: const Icon(Icons.undo_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('رجّع آخر جولة', 'تراجع', 'Undo round'))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _setupAgain(g),
            icon: const Icon(Icons.settings_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('إعداد جديد', 'إعداد جديد', 'New setup'))),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      if (rounds.isNotEmpty) ...[
        SCard(
          title: t('الجولات', 'سجل الجولات', 'Rounds'),
          icon: Icons.format_list_numbered_rounded,
          color: SD.coffee,
          child: Column(children: [
            for (var r = rounds.length - 1; r >= 0 && r >= rounds.length - 20; r--)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  SizedBox(width: 34, child: Text('${r + 1}', style: const TextStyle(fontWeight: FontWeight.w800))),
                  CircleAvatar(radius: 6, backgroundColor: teamColors[intOf(rounds[r]['w']) % teamColors.length]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      intOf(rounds[r]['w']) < names.length ? names[intOf(rounds[r]['w'])] : '?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('+${intOf(rounds[r]['p'])}', style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
              ),
          ]),
        ),
        ShareBar(() => _summary(g)),
        const SizedBox(height: 14),
      ],
    ];
  }

  Widget _history(AppState s) {
    final h = mapList(s.getData<List>('domino_history'));
    final wins = <String, int>{};
    for (final e in h) {
      final w = '${e['winner'] ?? ''}';
      if (w.isNotEmpty) wins[w] = (wins[w] ?? 0) + 1;
    }
    final top = wins.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return SCard(
      title: t('سجل الألعاب', 'سجل الألعاب', 'Game history'),
      icon: Icons.history_rounded,
      color: SD.indigo,
      child: h.isEmpty
          ? EmptyHint(Icons.emoji_events_outlined, t('لسه ما في ألعاب خلصت', 'لا توجد ألعاب منتهية بعد', 'No finished games yet'))
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final e in top.take(6)) XBadge('🏆 ${e.key} × ${e.value}', color: SD.gold),
              ]),
              const SizedBox(height: 8),
              for (final e in h.take(12))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.emoji_events_rounded, color: SD.gold),
                  title: Text('${e['winner']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    '${[for (final x in (e['totals'] as List? ?? const [])) '$x'].join(' — ')} • ${fmtDateAr(DateTime.fromMillisecondsSinceEpoch(intOf(e['t'])), weekday: false)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              TextButton.icon(
                onPressed: () async {
                  if (await confirmAsk(context, t('نمسح السجل؟', 'مسح السجل؟', 'Clear history?'), t('كل الألعاب القديمة حتتمسح.', 'ستُحذف كل الألعاب السابقة.', 'All past games will be deleted.'))) {
                    s.setData('domino_history', <Map>[]);
                  }
                },
                icon: const Icon(Icons.delete_sweep_rounded),
                label: Text(t('امسح السجل', 'مسح السجل', 'Clear history')),
              ),
            ]),
    );
  }

  /* ───────── تقسيم الفرق ───────── */

  List<String> _parseNames() => _splitC.text
      .split(RegExp(r'[\n,،]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  void _doSplit(AppState s) {
    final names = _parseNames();
    if (names.length < _teamsN) {
      return toast(t('الأسماء أقل من عدد الفرق', 'عدد الأسماء أقل من عدد الفرق', 'Fewer names than teams'));
    }
    final teams = splitTeams(names, _teamsN);
    s.setData('domino_split', {'names': _splitC.text, 'n': _teamsN, 'teams': teams});
    HapticFeedback.mediumImpact();
  }

  List<Widget> _split(AppState s) {
    final sp = Map<String, dynamic>.from(s.getData<Map>('domino_split') ?? const {});
    final teams = [
      for (final tm in (sp['teams'] as List? ?? const [])) [for (final n in (tm as List)) '$n']
    ];
    final count = _parseNames().length;
    String share() => [
          '🎲 ${t('تقسيم الفرق', 'تقسيم الفرق', 'Team split')}',
          for (var i = 0; i < teams.length; i++) '${t('فريق', 'الفريق', 'Team')} ${i + 1}: ${teams[i].join('، ')}',
        ].join('\n');
    return [
      SCard(
        title: t('الأسماء', 'الأسماء', 'Names'),
        icon: Icons.groups_2_rounded,
        color: SD.nile,
        trailing: XBadge('$count', color: SD.nile),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _splitC,
            minLines: 4,
            maxLines: 10,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: t('كل اسم في سطر، أو افصل بفاصلة\nمثلًا: أحمد، عثمان، مصطفى، الطيب', 'كل اسم في سطر، أو افصل بفاصلة\nمثال: أحمد، عثمان، مصطفى، الطيب',
                  'One name per line, or separate with commas\ne.g. Ahmed, Osman, Mustafa, Tayeb'),
            ),
          ),
          const SizedBox(height: 12),
          Text(t('عدد الفرق', 'عدد الفرق', 'Number of teams'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (var n = 2; n <= 6; n++) PickChip('$n', _teamsN == n, () => setState(() => _teamsN = n), color: SD.nile),
          ]),
          if (count >= _teamsN) ...[
            const SizedBox(height: 8),
            Text(
              '${t('كل فريق', 'كل فريق', 'Each team')}: ${count ~/ _teamsN}${count % _teamsN == 0 ? '' : '–${count ~/ _teamsN + 1}'} ${t('أنفار', 'أفراد', 'people')}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65)),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _doSplit(s),
            icon: const Icon(Icons.shuffle_rounded),
            label: Text(teams.isEmpty ? t('قسّم', 'قسّم', 'Split') : t('خلّطهم تاني', 'إعادة الخلط', 'Reshuffle')),
          ),
        ]),
      ),
      if (teams.isNotEmpty) ...[
        for (var i = 0; i < teams.length; i++)
          SCard(
            title: '${t('فريق', 'الفريق', 'Team')} ${i + 1}',
            icon: Icons.shield_rounded,
            color: teamColors[i % teamColors.length],
            trailing: XBadge('${teams[i].length}', color: teamColors[i % teamColors.length]),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              for (final n in teams[i]) Chip(label: Text(n, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ShareBar(share),
      ],
      const SizedBox(height: 14),
      NoteBox(t('التقسيم عشوائي بالكامل وعادل في العدد (الفرق بين الفرق نفر واحد بس).', 'التقسيم عشوائي تمامًا ومتوازن في العدد (الفرق بين الفرق فرد واحد على الأكثر).',
          'Fully random and balanced in size (teams differ by at most one person).')),
    ];
  }
}
