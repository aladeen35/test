import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// القرعة: سحب اسم، تقسيم فرق، نرد، عملة، رقم عشوائي
class RandomTool extends StatefulWidget {
  const RandomTool({super.key});
  @override
  State<RandomTool> createState() => _RandomToolState();
}

class _RandomToolState extends State<RandomTool> {
  final _rnd = math.Random.secure();
  late final _names = TextEditingController(text: context.read<AppState>().getData<String>('random_names') ?? '');
  final _min = TextEditingController(text: '1'), _max = TextEditingController(text: '100');
  String _winner = '—';
  bool _removeWinner = false;
  int _teams = 2, _dice = 2;
  List<List<String>> _teamsOut = [];
  List<int> _diceOut = [];
  String _coin = '—', _number = '—';
  final _history = <String>[];
  Timer? _anim;

  List<String> get _list => _names.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  @override
  void dispose() {
    _anim?.cancel();
    _names.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _save() => context.read<AppState>().setData('random_names', _names.text);

  void _pick() {
    final l = _list;
    if (l.isEmpty) return toast(t('أكتب أسماء أول', 'اكتب الأسماء أولًا', 'Enter some names first'));
    var i = 0;
    _anim?.cancel();
    _anim = Timer.periodic(const Duration(milliseconds: 70), (t) {
      setState(() => _winner = l[_rnd.nextInt(l.length)]);
      HapticFeedback.selectionClick();
      if (++i > 18) {
        t.cancel();
        final w = l[_rnd.nextInt(l.length)];
        setState(() {
          _winner = w;
          _history.insert(0, w);
          if (_removeWinner) {
            l.remove(w);
            _names.text = l.join('\n');
            _save();
          }
        });
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _split() {
    final l = _list..shuffle(_rnd);
    if (l.length < _teams) return toast(tr('الأسماء أقل من عدد الفرق', 'Fewer names than teams'));
    setState(() => _teamsOut = [for (var t = 0; t < _teams; t++) [for (var i = t; i < l.length; i += _teams) l[i]]]);
  }

  @override
  Widget build(BuildContext context) {
    final sum = _diceOut.fold(0, (a, b) => a + b);
    return ToolList(children: [
      SCard(
        title: t('سحب اسم (الختّة والصندوق)', 'سحب اسم (القرعة والجمعية)', 'Draw a name (savings circle & lottery)'),
        icon: Icons.how_to_vote_rounded,
        color: SD.orange,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
              controller: _names,
              maxLines: 5,
              onChanged: (_) => _save(),
              decoration: InputDecoration(hintText: t('أكتب كل اسم في سطر', 'اكتب كل اسم في سطر', 'One name per line'))),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _removeWinner,
            onChanged: (v) => setState(() => _removeWinner = v!),
            title: Text(t('شيل الفايز من القائمة (للصندوق والختّة)', 'احذف الفائز من القائمة (للجمعية والقرعة)', 'Remove the winner from the list (for savings circles)')),
          ),
          FilledButton.icon(
              onPressed: _pick, icon: const Icon(Icons.shuffle_rounded), label: Text(tr('اسحب (${_list.length} اسم)', 'Draw (${_list.length} names)'))),
        ]),
      ),
      ResultHero(
          label: t('الفايز', 'الفائز', 'Winner'),
          value: _winner,
          sub: _history.length > 1 ? '${t('قبلو', 'قبله', 'Before')}: ${_history.skip(1).take(5).join(tr('، ', ', '))}' : null,
          colors: SD.sunset),
      SCard(
        title: t('قسّم الشلة لفرق', 'قسّم المجموعة إلى فرق', 'Split the group into teams'),
        icon: Icons.groups_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text(tr('عدد الفرق:', 'Teams:')),
            Expanded(child: Slider(value: _teams.toDouble(), min: 2, max: 6, divisions: 4, label: '$_teams', onChanged: (v) => setState(() => _teams = v.round()))),
            Text('$_teams', style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          OutlinedButton(onPressed: _split, child: Text(tr('قسّم', 'Split'))),
          for (var k = 0; k < _teamsOut.length; k++)
            InfoRow(tr('الفريق ${k + 1} (${_teamsOut[k].length})', 'Team ${k + 1} (${_teamsOut[k].length})'), _teamsOut[k].join(tr('، ', ', '))),
        ]),
      ),
      SCard(
        title: tr('نرد وعملة ورقم', 'Dice, coin & number'),
        icon: Icons.casino_rounded,
        color: SD.red,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text(t('عدد الزهر:', 'عدد النرد:', 'Dice:')),
            for (final n in [1, 2, 3])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(label: Text('$n'), selected: _dice == n, onSelected: (_) => setState(() => _dice = n)),
              ),
            const Spacer(),
            FilledButton(onPressed: () => setState(() => _diceOut = [for (var i = 0; i < _dice; i++) _rnd.nextInt(6) + 1]), child: Text(tr('🎲 ارمِ', '🎲 Roll'))),
          ]),
          if (_diceOut.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_diceOut.map((d) => '⚀⚁⚂⚃⚄⚅'[d - 1]).join(' '), textAlign: TextAlign.center, style: const TextStyle(fontSize: 56)),
            InfoRow(tr('المجموع', 'Total'), '$sum'),
          ],
          const Divider(),
          Row(children: [
            Expanded(child: Text('${tr('العملة', 'Coin')}: $_coin', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            FilledButton(
                onPressed: () => setState(() => _coin = _rnd.nextBool() ? tr('صورة 🦅', 'Heads 🦅') : tr('كتابة ✍️', 'Tails ✍️')),
                child: Text(t('🪙 قلّب', '🪙 اقلب', '🪙 Flip'))),
          ]),
          const Divider(),
          Row(children: [
            Expanded(child: NumField(tr('من', 'From'), _min, decimal: false)),
            const SizedBox(width: 8),
            Expanded(child: NumField(t('لغاية', 'إلى', 'To'), _max, decimal: false)),
          ]),
          OutlinedButton(
            onPressed: () {
              final a = int.tryParse(_min.text) ?? 1, b = int.tryParse(_max.text) ?? 100;
              if (b < a) return toast(t('الرقم التاني لازم يكون أكبر', 'يجب أن يكون الرقم الثاني أكبر', 'The second number must be larger'));
              setState(() => _number = '${a + _rnd.nextInt(b - a + 1)}');
            },
            child: Text('${tr('رقم عشوائي', 'Random number')}: $_number'),
          ),
        ]),
      ),
      NoteBox(
          t('السحب بيستخدم مولّد عشوائي آمن (Random.secure) — ما في زول بقدر يتحكم في النتيجة.', 'يستخدم السحب مولّدًا عشوائيًا آمنًا (Random.secure) — لا يمكن لأحد التحكم في النتيجة.',
              'Draws use a secure random generator (Random.secure) — nobody can rig the result.'),
          kind: NoteKind.info),
    ]);
  }
}
