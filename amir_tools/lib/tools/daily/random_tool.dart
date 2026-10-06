import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
    if (l.isEmpty) return toast('أكتب أسماء أول');
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
    if (l.length < _teams) return toast('الأسماء أقل من عدد الفرق');
    setState(() => _teamsOut = [for (var t = 0; t < _teams; t++) [for (var i = t; i < l.length; i += _teams) l[i]]]);
  }

  @override
  Widget build(BuildContext context) {
    final sum = _diceOut.fold(0, (a, b) => a + b);
    return ToolList(children: [
      SCard(
        title: 'سحب اسم (الختّة والصندوق)',
        icon: Icons.how_to_vote_rounded,
        color: SD.orange,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _names, maxLines: 5, onChanged: (_) => _save(), decoration: const InputDecoration(hintText: 'أكتب كل اسم في سطر')),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _removeWinner,
            onChanged: (v) => setState(() => _removeWinner = v!),
            title: const Text('شيل الفايز من القائمة (للصندوق والختّة)'),
          ),
          FilledButton.icon(onPressed: _pick, icon: const Icon(Icons.shuffle_rounded), label: Text('اسحب (${_list.length} اسم)')),
        ]),
      ),
      ResultHero(label: 'الفايز', value: _winner, sub: _history.length > 1 ? 'قبلو: ${_history.skip(1).take(5).join('، ')}' : null, colors: SD.sunset),
      SCard(
        title: 'قسّم الشلة لفرق',
        icon: Icons.groups_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Text('عدد الفرق:'),
            Expanded(child: Slider(value: _teams.toDouble(), min: 2, max: 6, divisions: 4, label: '$_teams', onChanged: (v) => setState(() => _teams = v.round()))),
            Text('$_teams', style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          OutlinedButton(onPressed: _split, child: const Text('قسّم')),
          for (var t = 0; t < _teamsOut.length; t++) InfoRow('الفريق ${t + 1} (${_teamsOut[t].length})', _teamsOut[t].join('، ')),
        ]),
      ),
      SCard(
        title: 'نرد وعملة ورقم',
        icon: Icons.casino_rounded,
        color: SD.red,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Text('عدد الزهر:'),
            for (final n in [1, 2, 3])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(label: Text('$n'), selected: _dice == n, onSelected: (_) => setState(() => _dice = n)),
              ),
            const Spacer(),
            FilledButton(onPressed: () => setState(() => _diceOut = [for (var i = 0; i < _dice; i++) _rnd.nextInt(6) + 1]), child: const Text('🎲 ارمِ')),
          ]),
          if (_diceOut.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_diceOut.map((d) => '⚀⚁⚂⚃⚄⚅'[d - 1]).join(' '), textAlign: TextAlign.center, style: const TextStyle(fontSize: 56)),
            InfoRow('المجموع', '$sum'),
          ],
          const Divider(),
          Row(children: [
            Expanded(child: Text('العملة: $_coin', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            FilledButton(onPressed: () => setState(() => _coin = _rnd.nextBool() ? 'صورة 🦅' : 'كتابة ✍️'), child: const Text('🪙 قلّب')),
          ]),
          const Divider(),
          Row(children: [
            Expanded(child: NumField('من', _min, decimal: false)),
            const SizedBox(width: 8),
            Expanded(child: NumField('لغاية', _max, decimal: false)),
          ]),
          OutlinedButton(
            onPressed: () {
              final a = int.tryParse(_min.text) ?? 1, b = int.tryParse(_max.text) ?? 100;
              if (b < a) return toast('الرقم التاني لازم يكون أكبر');
              setState(() => _number = '${a + _rnd.nextInt(b - a + 1)}');
            },
            child: Text('رقم عشوائي: $_number'),
          ),
        ]),
      ),
      const NoteBox('السحب بيستخدم مولّد عشوائي آمن (Random.secure) — ما في زول بقدر يتحكم في النتيجة.', kind: NoteKind.info),
    ]);
  }
}
