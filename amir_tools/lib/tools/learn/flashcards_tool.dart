import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'learn_common.dart';

/* ── منطق صناديق لايتنر ── */

/// فترات المراجعة بالأيام لكل صندوق (1..5)
const leitnerDays = [0, 1, 2, 4, 8, 16];

/// يحدّث البطاقة بعد الإجابة: صح ← الصندوق التالي، غلط ← الصندوق 1
Map<String, dynamic> leitnerAnswer(Map<String, dynamic> card, bool knew, DateTime today) {
  final box = lInt(card['x'], 1).clamp(1, 5);
  final nb = knew ? math.min(5, box + 1) : 1;
  return {
    ...card,
    'x': nb,
    'd': lDk(lAddDays(today, leitnerDays[nb])),
    'r': lInt(card['r']) + (knew ? 1 : 0),
    'w': lInt(card['w']) + (knew ? 0 : 1),
  };
}

bool cardDue(Map card, DateTime today) {
  final d = lParseDk(card['d'] as String?);
  return d == null || !d.isAfter(today);
}

/// يقرأ بطاقات من نص: سطر لكل بطاقة «وجه | ظهر» (أو Tab)
List<(String, String)> parseCards(String text) {
  final out = <(String, String)>[];
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final sep = line.contains('|') ? '|' : (line.contains('\t') ? '\t' : null);
    if (sep == null) continue;
    final i = line.indexOf(sep);
    final f = line.substring(0, i).trim(), b = line.substring(i + 1).trim();
    if (f.isNotEmpty && b.isNotEmpty) out.add((f, b));
  }
  return out;
}

String deckToText(String name, List<Map<String, dynamic>> cards) =>
    ['🗂️ $name', for (final c in cards) '${c['f']} | ${c['b']}'].join('\n');

List<Map<String, dynamic>> _sampleDecks() => [
      {
        'id': 'sample_en',
        'n': t('كلمات إنجليزي', 'مفردات إنجليزية', 'Arabic words'),
        'cards': [
          for (final (i, p) in (isEn
                  ? const [('كتاب', 'Book'), ('مدرسة', 'School'), ('شجرة', 'Tree'), ('ماء', 'Water'), ('شمس', 'Sun'), ('صديق', 'Friend')]
                  : const [('Book', 'كتاب'), ('School', 'مدرسة'), ('Tree', 'شجرة'), ('Water', 'موية / ماء'), ('Sun', 'شمس'), ('Friend', 'صاحب / صديق')])
              .indexed)
            {'id': 'en_$i', 'f': p.$1, 'b': p.$2, 'x': 1},
        ],
      },
      {
        'id': 'sample_caps',
        'n': t('عواصم الدول', 'عواصم الدول', 'Capitals'),
        'cards': [
          for (final (i, p) in (isEn
                  ? const [('Sudan', 'Khartoum'), ('Egypt', 'Cairo'), ('Ethiopia', 'Addis Ababa'), ('Saudi Arabia', 'Riyadh'), ('Kenya', 'Nairobi')]
                  : const [('السودان', 'الخرطوم'), ('مصر', 'القاهرة'), ('إثيوبيا', 'أديس أبابا'), ('السعودية', 'الرياض'), ('كينيا', 'نيروبي')])
              .indexed)
            {'id': 'cap_$i', 'f': p.$1, 'b': p.$2, 'x': 1},
        ],
      },
    ];

class FlashcardsTool extends StatefulWidget {
  const FlashcardsTool({super.key});
  @override
  State<FlashcardsTool> createState() => _FlashcardsToolState();
}

class _FlashcardsToolState extends State<FlashcardsTool> with SingleTickerProviderStateMixin {
  String? _deckId;
  bool _studying = false;
  List<String> _queue = [];
  int _idx = 0, _knew = 0, _missed = 0;
  final _requeued = <String>{};
  late final AnimationController _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _decks(AppState s) {
    final raw = s.getData<List>('flashcards_decks');
    return raw == null ? _sampleDecks() : lMaps(raw);
  }

  void _saveDecks(AppState s, List<Map<String, dynamic>> d) => s.setData('flashcards_decks', d);

  Map<String, dynamic>? _deck(AppState s) {
    for (final d in _decks(s)) {
      if (d['id'] == _deckId) return d;
    }
    return null;
  }

  List<Map<String, dynamic>> _cards(Map d) => lMaps(d['cards']);

  void _updateDeck(AppState s, Map<String, dynamic> deck) {
    final l = _decks(s);
    final i = l.indexWhere((e) => e['id'] == deck['id']);
    if (i >= 0) {
      l[i] = deck;
    } else {
      l.add(deck);
    }
    _saveDecks(s, l);
  }

  Future<String?> _ask(String title, {String initial = '', String? label}) async {
    final c = TextEditingController(text: initial);
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(labelText: label ?? title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('خلاص', 'إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(t('تمام', 'حفظ', 'Save'))),
        ],
      ),
    );
    Future.delayed(const Duration(milliseconds: 600), c.dispose);
    return r == null || r.isEmpty ? null : r;
  }

  Future<(String, String)?> _askCard({String f = '', String b = ''}) async {
    final cf = TextEditingController(text: f), cb = TextEditingController(text: b);
    final r = await showDialog<(String, String)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(f.isEmpty ? t('بطاقة جديدة', 'بطاقة جديدة', 'New card') : t('عدّل البطاقة', 'تعديل البطاقة', 'Edit card')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: cf, autofocus: true, maxLines: 3, minLines: 1, decoration: InputDecoration(labelText: t('الوش (السؤال)', 'الوجه (السؤال)', 'Front (question)'))),
          const SizedBox(height: 10),
          TextField(controller: cb, maxLines: 3, minLines: 1, decoration: InputDecoration(labelText: t('الضهر (الإجابة)', 'الظهر (الإجابة)', 'Back (answer)'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('خلاص', 'إلغاء', 'Cancel'))),
          FilledButton(
            onPressed: () => cf.text.trim().isEmpty || cb.text.trim().isEmpty ? null : Navigator.pop(ctx, (cf.text.trim(), cb.text.trim())),
            child: Text(t('تمام', 'حفظ', 'Save')),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      cf.dispose();
      cb.dispose();
    });
    return r;
  }

  Future<void> _import(AppState s, Map<String, dynamic> deck) async {
    final c = TextEditingController();
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('استيراد من نص', 'استيراد من نص', 'Import from text')),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: c,
            autofocus: true,
            minLines: 6,
            maxLines: 12,
            decoration: InputDecoration(
              hintText: 'Apple | تفاحة\nCat | كديس',
              helperText: t('سطر لكل بطاقة: الوش | الضهر', 'سطر لكل بطاقة: الوجه | الظهر', 'One card per line: front | back'),
              helperMaxLines: 2,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('خلاص', 'إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(t('استورد', 'استيراد', 'Import'))),
        ],
      ),
    );
    Future.delayed(const Duration(milliseconds: 600), c.dispose);
    if (r == null || !mounted) return;
    final parsed = parseCards(r);
    if (parsed.isEmpty) {
      toast(t('ما لقيت بطاقات — أكتب «الوش | الضهر»', 'لم توجد بطاقات — اكتب «الوجه | الظهر»', 'No cards found — use “front | back”'));
      return;
    }
    final cards = _cards(deck)..addAll([for (final p in parsed) {'id': lId(), 'f': p.$1, 'b': p.$2, 'x': 1}]);
    _updateDeck(s, {...deck, 'cards': cards});
    toast('${t('اتزادت', 'أُضيفت', 'Added')} ${parsed.length} ${t('بطاقة', 'بطاقة', 'cards')} ✓');
  }

  void _startStudy(AppState s, Map<String, dynamic> deck, {required bool all}) {
    final today = lToday();
    final cards = _cards(deck).where((c) => all || cardDue(c, today)).toList()
      ..sort((a, b) => lInt(a['x'], 1).compareTo(lInt(b['x'], 1)));
    if (cards.isEmpty) {
      toast(t('ما في بطاقات مستحقة الليلة 👌', 'لا بطاقات مستحقة اليوم 👌', 'Nothing due today 👌'));
      return;
    }
    setState(() {
      _queue = [for (final c in cards) c['id'] as String];
      _idx = 0;
      _knew = 0;
      _missed = 0;
      _requeued.clear();
      _studying = true;
      _flip.value = 0;
    });
  }

  void _answer(AppState s, Map<String, dynamic> deck, bool knew) {
    final id = _queue[_idx];
    final cards = _cards(deck);
    final i = cards.indexWhere((c) => c['id'] == id);
    if (i >= 0) cards[i] = leitnerAnswer(cards[i], knew, lToday());
    _updateDeck(s, {...deck, 'cards': cards, 'last': lDk(lToday())});
    setState(() {
      if (knew) {
        _knew++;
      } else {
        _missed++;
        if (_requeued.add(id)) _queue.add(id);
      }
      _idx++;
      _flip.value = 0;
    });
    if (_idx >= _queue.length) {
      s.bump('flashcards_reviewed', _knew + _missed);
      s.awardDaily('flashcards_${deck['id']}', 10, tr('مذاكرة البطاقات', 'Flashcards study'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final deck = _deck(s);
    if (deck == null) return _deckList(s);
    if (_studying) return _study(s, deck);
    return _deckView(s, deck);
  }

  /* ── قائمة المجموعات ── */
  Widget _deckList(AppState s) {
    final decks = _decks(s);
    final today = lToday();
    final allCards = [for (final d in decks) ..._cards(d)];
    final due = allCards.where((c) => cardDue(c, today)).length;
    final mastered = allCards.where((c) => lInt(c['x'], 1) >= 5).length;
    return ToolList(children: [
      StatGrid([
        StatChip('${decks.length}', t('مجموعات', 'مجموعات', 'Decks'), color: SD.nile, icon: Icons.folder_copy_rounded),
        StatChip('$due', t('مستحقة الليلة', 'مستحقة اليوم', 'Due today'), color: SD.orange, icon: Icons.alarm_rounded),
        StatChip('$mastered', t('محفوظة تمام', 'متقنة', 'Mastered'), color: SD.green, icon: Icons.verified_rounded),
      ]),
      const SizedBox(height: 14),
      for (final d in decks) _deckTile(s, d, today),
      FilledButton.icon(
        onPressed: () async {
          final n = await _ask(t('اسم المجموعة', 'اسم المجموعة', 'Deck name'));
          if (n == null || !mounted) return;
          final id = lId();
          _updateDeck(s, {'id': id, 'n': n, 'cards': <Map>[]});
          setState(() => _deckId = id);
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(t('مجموعة جديدة', 'مجموعة جديدة', 'New deck')),
      ),
      const SizedBox(height: 12),
      NoteBox(
          t('نظام لايتنر: البطاقة الجاوبتها صح بتطلع للصندوق الجاي وبتتأخر مراجعتها (1، 2، 4، 8، 16 يوم)، والغلط بترجع للصندوق الأول.',
              'نظام لايتنر: البطاقة الصحيحة تنتقل للصندوق التالي وتتباعد مراجعتها (1، 2، 4، 8، 16 يومًا)، والخاطئة تعود للصندوق الأول.',
              'Leitner system: a card you know moves up a box and is reviewed less often (1, 2, 4, 8, 16 days); a missed card goes back to box 1.'),
          kind: NoteKind.tip),
    ]);
  }

  Widget _deckTile(AppState s, Map<String, dynamic> d, DateTime today) {
    final cards = _cards(d);
    final due = cards.where((c) => cardDue(c, today)).length;
    final m = cards.isEmpty ? 0.0 : cards.fold<int>(0, (a, c) => a + lInt(c['x'], 1) - 1) / (cards.length * 4);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => setState(() => _deckId = d['id'] as String),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(Icons.style_rounded, color: readable(context, SD.gold)),
              const SizedBox(width: 10),
              Expanded(child: Text('${d['n']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
              if (due > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: SD.orange.withValues(alpha: .2), borderRadius: BorderRadius.circular(10)),
                  child: Text('$due ${t('مستحقة', 'مستحقة', 'due')}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: readable(context, SD.orange))),
                ),
            ]),
            LBar('${cards.length} ${t('بطاقة', 'بطاقة', 'cards')}', m, '${fmt(m * 100, 0)}%', color: SD.green, height: 7),
          ]),
        ),
      ),
    );
  }

  /* ── تفاصيل مجموعة ── */
  Widget _deckView(AppState s, Map<String, dynamic> deck) {
    final cards = _cards(deck);
    final today = lToday();
    final due = cards.where((c) => cardDue(c, today)).length;
    final r = cards.fold<int>(0, (a, c) => a + lInt(c['r'])), w = cards.fold<int>(0, (a, c) => a + lInt(c['w']));
    final boxes = List.generate(5, (i) => cards.where((c) => lInt(c['x'], 1).clamp(1, 5) == i + 1).length);
    final last = lParseDk(deck['last'] as String?);
    return ToolList(children: [
      Row(children: [
        IconButton(onPressed: () => setState(() => _deckId = null), icon: const Icon(Icons.arrow_back_rounded), tooltip: t('ورا', 'رجوع', 'Back')),
        Expanded(child: Text('${deck['n']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
        PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'rename') {
              final n = await _ask(t('اسم المجموعة', 'اسم المجموعة', 'Deck name'), initial: '${deck['n']}');
              if (n != null && mounted) _updateDeck(s, {...deck, 'n': n});
            } else if (v == 'reset') {
              _updateDeck(s, {...deck, 'cards': [for (final c in cards) {'id': c['id'], 'f': c['f'], 'b': c['b'], 'x': 1}]});
            } else if (v == 'delete') {
              final l = _decks(s)..removeWhere((e) => e['id'] == deck['id']);
              _saveDecks(s, l);
              setState(() => _deckId = null);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'rename', child: Text(t('غيّر الاسم', 'إعادة تسمية', 'Rename'))),
            PopupMenuItem(value: 'reset', child: Text(t('صفّر التقدّم', 'تصفير التقدم', 'Reset progress'))),
            PopupMenuItem(value: 'delete', child: Text(t('امسح المجموعة', 'حذف المجموعة', 'Delete deck'))),
          ],
        ),
      ]),
      const SizedBox(height: 8),
      StatGrid([
        StatChip('${cards.length}', t('بطاقة', 'بطاقة', 'Cards'), color: SD.nile, icon: Icons.style_rounded),
        StatChip('$due', t('مستحقة', 'مستحقة', 'Due'), color: SD.orange, icon: Icons.alarm_rounded),
        StatChip(r + w == 0 ? '—' : '${fmt(r / (r + w) * 100, 0)}%', t('نسبة الصاح', 'نسبة الصواب', 'Accuracy'), color: SD.green, icon: Icons.insights_rounded),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: cards.isEmpty ? null : () => _startStudy(s, deck, all: false),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text('${t('ذاكر المستحق', 'راجع المستحق', 'Study due')} ($due)', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: cards.isEmpty ? null : () => _startStudy(s, deck, all: true),
            icon: const Icon(Icons.all_inclusive_rounded),
            label: Text(t('كلها', 'الكل', 'All cards'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      SCard(
        title: t('الصناديق', 'صناديق لايتنر', 'Leitner boxes'),
        icon: Icons.inventory_2_rounded,
        color: SD.indigo,
        child: Column(children: [
          for (var i = 0; i < 5; i++)
            LBar('${t('صندوق', 'الصندوق', 'Box')} ${i + 1} · ${t('كل', 'كل', 'every')} ${lDays(leitnerDays[i + 1])}', cards.isEmpty ? 0 : boxes[i] / cards.length, '${boxes[i]}',
                color: [SD.red, SD.orange, SD.gold, SD.teal, SD.green][i], height: 8),
          if (last != null)
            InfoRow(t('آخر مذاكرة', 'آخر مراجعة', 'Last studied'), fmtDateAr(last)),
        ]),
      ),
      SCard(
        title: t('البطاقات', 'البطاقات', 'Cards'),
        icon: Icons.view_agenda_rounded,
        color: SD.gold,
        trailing: IconButton(
          tooltip: t('زيد بطاقة', 'إضافة بطاقة', 'Add card'),
          onPressed: () async {
            final r = await _askCard();
            if (r == null || !mounted) return;
            _updateDeck(s, {...deck, 'cards': [...cards, {'id': lId(), 'f': r.$1, 'b': r.$2, 'x': 1}]});
          },
          icon: const Icon(Icons.add_circle_rounded),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (cards.isEmpty) Text(t('ما في بطاقات لسه — زيد بطاقة أو استورد من نص.', 'لا بطاقات بعد — أضف بطاقة أو استورد من نص.', 'No cards yet — add one or import from text.')),
          for (final c in cards)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: [SD.red, SD.orange, SD.gold, SD.teal, SD.green][lInt(c['x'], 1).clamp(1, 5) - 1],
                child: Text('${lInt(c['x'], 1).clamp(1, 5)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              title: Text('${c['f']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${c['b']}', maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () async {
                final r = await _askCard(f: '${c['f']}', b: '${c['b']}');
                if (r == null || !mounted) return;
                _updateDeck(s, {...deck, 'cards': [for (final x in cards) x['id'] == c['id'] ? {...x, 'f': r.$1, 'b': r.$2} : x]});
              },
              trailing: IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onPressed: () => _updateDeck(s, {...deck, 'cards': [for (final x in cards) if (x['id'] != c['id']) x]}),
              ),
            ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () => _import(s, deck),
            icon: const Icon(Icons.file_download_rounded),
            label: Text(t('استيراد من نص', 'استيراد من نص', 'Import from text'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
      ShareBar(() => deckToText('${deck['n']}', cards)),
    ]);
  }

  /* ── وضع المذاكرة ── */
  Widget _study(AppState s, Map<String, dynamic> deck) {
    final done = _idx >= _queue.length;
    if (done) {
      final total = _knew + _missed;
      return ToolList(children: [
        ResultHero(
          label: t('خلّصت المذاكرة! 👏', 'انتهت المراجعة! 👏', 'Session complete! 👏'),
          value: '$_knew / $total',
          sub: total == 0 ? null : '${fmt(_knew / total * 100, 0)}% ${t('صاح', 'صحيح', 'correct')}',
        ),
        FilledButton.icon(
          onPressed: () => setState(() => _studying = false),
          icon: const Icon(Icons.check_rounded),
          label: Text(t('رجوع للمجموعة', 'العودة للمجموعة', 'Back to deck')),
        ),
      ]);
    }
    final card = _cards(deck).firstWhere((c) => c['id'] == _queue[_idx], orElse: () => {'f': '?', 'b': '?'});
    final shown = _flip.value > .5;
    return ToolList(children: [
      Row(children: [
        IconButton(onPressed: () => setState(() => _studying = false), icon: const Icon(Icons.close_rounded), tooltip: t('وقّف', 'إيقاف', 'Stop')),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: _idx / _queue.length, minHeight: 8),
          ),
        ),
        const SizedBox(width: 10),
        Text('${_idx + 1}/${_queue.length}', style: const TextStyle(fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 14),
      GestureDetector(
        onTap: () => _flip.value < .5 ? _flip.forward().then((_) => mounted ? setState(() {}) : null) : _flip.reverse().then((_) => mounted ? setState(() {}) : null),
        child: AnimatedBuilder(
          animation: _flip,
          builder: (context, _) {
            final a = _flip.value * math.pi;
            final back = a > math.pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(a),
              child: back
                  ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: _face('${card['b']}', true))
                  : _face('${card['f']}', false),
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      if (!shown)
        OutlinedButton.icon(
          onPressed: () => _flip.forward().then((_) => mounted ? setState(() {}) : null),
          icon: const Icon(Icons.flip_rounded),
          label: Text(t('اقلب البطاقة', 'اقلب البطاقة', 'Flip card')),
        )
      else
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: SD.red, foregroundColor: Colors.white),
              onPressed: () => _answer(s, deck, false),
              icon: const Icon(Icons.close_rounded),
              label: Text(t('ما عرفتها', 'لم أعرفها', "Didn't know"), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: SD.green, foregroundColor: Colors.white),
              onPressed: () => _answer(s, deck, true),
              icon: const Icon(Icons.check_rounded),
              label: Text(t('عرفتها', 'عرفتها', 'Knew it'), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ]),
      const SizedBox(height: 12),
      Text(
        '${t('صاح', 'صحيح', 'Right')}: $_knew · ${t('غلط', 'خطأ', 'Wrong')}: $_missed',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ]);
  }

  Widget _face(String text, bool back) => Container(
        constraints: const BoxConstraints(minHeight: 220),
        padding: const EdgeInsets.all(22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: back ? const [Color(0xFF0E8C84), Color(0xFF0B5C8A)] : const [Color(0xFF8A5528), Color(0xFF5A3418)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: SD.gold, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(back ? t('الإجابة', 'الإجابة', 'Answer') : t('السؤال', 'السؤال', 'Question'),
              style: TextStyle(color: SD.cream.withValues(alpha: .75), fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.3)),
          if (!back) ...[
            const SizedBox(height: 14),
            Text(t('اضغط عشان تقلبها', 'اضغط للقلب', 'Tap to flip'), style: TextStyle(color: SD.cream.withValues(alpha: .6), fontSize: 12.5)),
          ],
        ]),
      );
}
