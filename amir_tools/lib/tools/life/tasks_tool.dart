import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../daily/daily_common.dart' show Bar, BarChart;
import 'life_common.dart';

/// تصنيفات افتراضية: (مفتاح، إيموجي، سوداني، فصحى، إنجليزي)
const _defCats = [
  ('work', '💼', 'شغل', 'عمل', 'Work'),
  ('home', '🏠', 'البيت', 'المنزل', 'Home'),
  ('study', '📚', 'قراية', 'دراسة', 'Study'),
  ('errands', '🛺', 'مشاوير', 'مشاوير', 'Errands'),
  ('shopping', '🛒', 'مقاضي', 'مشتريات', 'Shopping'),
  ('faith', '🕌', 'دين', 'عبادة', 'Faith'),
  ('family', '👨‍👩‍👧', 'الأهل', 'العائلة', 'Family'),
  ('personal', '🙋', 'شخصي', 'شخصي', 'Personal'),
];

String _catLabel(String? k) {
  if (k == null || k.isEmpty) return '';
  for (final c in _defCats) {
    if (c.$1 == k) return '${c.$2} ${t(c.$3, c.$4, c.$5)}';
  }
  return '🏷️ $k';
}

/// الأولوية: 0 عالية، 1 عادية، 2 واطية
String _priLabel(int p) => switch (p) {
      0 => t('عالية', 'عالية', 'High'),
      2 => t('واطية', 'منخفضة', 'Low'),
      _ => t('عادية', 'عادية', 'Normal'),
    };
Color _priColor(int p) => switch (p) {
      0 => SD.red,
      2 => SD.nileLight,
      _ => SD.gold,
    };

enum _F { all, today, upcoming, overdue, done }

class TasksTool extends StatefulWidget {
  const TasksTool({super.key});
  @override
  State<TasksTool> createState() => _TasksToolState();
}

class _TasksToolState extends State<TasksTool> {
  _F _filter = _F.today;
  String? _cat;
  final _quick = TextEditingController();

  @override
  void dispose() {
    _quick.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _list(AppState s) => mapList(s.getData<List>('tasks_list'));
  void _save(AppState s, List<Map<String, dynamic>> l) => s.setData('tasks_list', l);

  List<String> _customCats(AppState s) => List<String>.from(s.getData<List>('tasks_cats') ?? const []);

  void _addQuick() {
    final txt = _quick.text.trim();
    if (txt.isEmpty) return;
    final s = context.read<AppState>();
    final today = todayPlace();
    final l = _list(s)
      ..add({
        'id': newId(),
        'title': txt,
        'note': '',
        'pri': 1,
        'due': _filter == _F.today ? dk(today) : (_filter == _F.upcoming ? dk(today.add(const Duration(days: 1))) : null),
        'cat': _cat ?? '',
        'done': false,
        'created': DateTime.now().millisecondsSinceEpoch,
      });
    _save(s, l);
    _quick.clear();
    HapticFeedback.selectionClick();
    setState(() {});
  }

  void _setDone(String id, bool v) {
    final s = context.read<AppState>();
    final l = _list(s);
    final i = l.indexWhere((x) => x['id'] == id);
    if (i < 0) return;
    final x = l[i];
    x['done'] = v;
    x['doneAt'] = v ? DateTime.now().millisecondsSinceEpoch : null;
    final firstTime = v && x['aw'] != true;
    if (firstTime) x['aw'] = true;
    _save(s, l);
    if (v) {
      HapticFeedback.mediumImpact();
      if (firstTime) {
        s.bump('tasks_done');
        s.award(3, '${tr('مهمة', 'Task')}: ${x['title']}');
      }
      undoSnack(t('✅ خلّصتها! عافي منك', '✅ أُنجزت المهمة', '✅ Task done'), () => _setDone(id, false));
    }
    setState(() {});
  }

  void _delete(String id) {
    final s = context.read<AppState>();
    final l = _list(s);
    final i = l.indexWhere((x) => x['id'] == id);
    if (i < 0) return;
    final removed = l.removeAt(i);
    _save(s, l);
    setState(() {});
    undoSnack(t('اتمسحت المهمة', 'حُذفت المهمة', 'Task deleted'), () {
      final l2 = _list(s);
      l2.insert(i.clamp(0, l2.length), removed);
      _save(s, l2);
      if (mounted) setState(() {});
    });
  }

  Future<void> _edit([Map<String, dynamic>? x]) async {
    final s = context.read<AppState>();
    final titleC = TextEditingController(text: x?['title'] ?? '');
    final noteC = TextEditingController(text: x?['note'] ?? '');
    var pri = intOf(x?['pri'], 1);
    DateTime? due = parseDk(x?['due']) ?? (x == null && _filter == _F.today ? todayPlace() : null);
    var cat = (x?['cat'] as String?) ?? (_cat ?? '');
    final customs = _customCats(s);
    final ok = await lifeSheet<bool>(
      context,
      x == null ? t('مهمة جديدة', 'مهمة جديدة', 'New task') : t('عدّل المهمة', 'تعديل المهمة', 'Edit task'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: titleC,
          autofocus: x == null,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: t('شنو المهمة؟', 'عنوان المهمة', 'Task title')),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: noteC,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(labelText: t('ملاحظة (اختياري)', 'ملاحظة (اختياري)', 'Note (optional)')),
        ),
        const SizedBox(height: 14),
        Text(t('الأولوية', 'الأولوية', 'Priority'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          for (final p in [0, 1, 2]) PickChip(_priLabel(p), pri == p, () => set(() => pri = p), color: _priColor(p)),
        ]),
        const SizedBox(height: 14),
        LifeDateButton(label: t('آخر موعد', 'تاريخ الاستحقاق', 'Due date'), value: due, clearable: true, onPick: (d) => set(() => due = d), color: SD.nile),
        const SizedBox(height: 6),
        Wrap(spacing: 6, children: [
          for (final q in [(0, t('الليلة', 'اليوم', 'Today')), (1, t('بكرة', 'غدًا', 'Tomorrow')), (7, t('بعد أسبوع', 'بعد أسبوع', 'In a week'))])
            ActionChip(label: Text(q.$2), onPressed: () => set(() => due = todayPlace().add(Duration(days: q.$1)))),
        ]),
        const SizedBox(height: 14),
        Text(t('التصنيف', 'التصنيف', 'Category'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          PickChip(t('بدون', 'بدون', 'None'), cat.isEmpty, () => set(() => cat = ''), color: SD.coffee),
          for (final c in _defCats) PickChip('${c.$2} ${t(c.$3, c.$4, c.$5)}', cat == c.$1, () => set(() => cat = c.$1), color: SD.teal),
          for (final c in customs) PickChip('🏷️ $c', cat == c, () => set(() => cat = c), color: SD.purple),
          ActionChip(
            avatar: const Icon(Icons.add_rounded, size: 18),
            label: Text(t('تصنيف جديد', 'تصنيف جديد', 'New category')),
            onPressed: () async {
              final n = (await askText(ctx, t('اسم التصنيف', 'اسم التصنيف', 'Category name')))?.trim() ?? '';
              if (n.isEmpty) return;
              if (!customs.contains(n)) {
                customs.add(n);
                s.setData('tasks_cats', customs);
              }
              set(() => cat = n);
            },
          ),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          if (x != null)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: SD.red),
                onPressed: () => Navigator.pop(ctx, false),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(t('امسحها', 'حذف', 'Delete')),
              ),
            ),
          if (x != null) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () {
                if (titleC.text.trim().isEmpty) return toast(t('أكتب المهمة', 'اكتب عنوان المهمة', 'Enter a title'));
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(t('احفظ', 'حفظ', 'Save')),
            ),
          ),
        ]),
      ]),
    );
    final title = titleC.text.trim(), note = noteC.text.trim();
    titleC.dispose();
    noteC.dispose();
    if (!mounted || ok == null) return;
    if (ok == false && x != null) return _delete(x['id']);
    final l = _list(s);
    final data = {'title': title, 'note': note, 'pri': pri, 'due': due == null ? null : dk(due!), 'cat': cat};
    if (x == null) {
      l.add({'id': newId(), ...data, 'done': false, 'created': DateTime.now().millisecondsSinceEpoch});
    } else {
      final i = l.indexWhere((e) => e['id'] == x['id']);
      if (i >= 0) l[i] = {...l[i], ...data};
    }
    _save(s, l);
    setState(() {});
  }

  bool _match(Map x, _F f, DateTime today) {
    final done = x['done'] == true;
    final due = parseDk(x['due']);
    return switch (f) {
      _F.all => !done,
      _F.today => !done && (due == null ? false : dayDiff(today, due) <= 0),
      _F.upcoming => !done && due != null && dayDiff(today, due) > 0,
      _F.overdue => !done && due != null && dayDiff(today, due) < 0,
      _F.done => done,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = _list(s);
    final today = todayPlace();
    final pending = all.where((x) => x['done'] != true).toList();
    final overdue = all.where((x) => _match(x, _F.overdue, today)).length;
    final dueToday = all.where((x) => x['done'] != true && x['due'] == dk(today)).length;
    final doneAll = all.where((x) => x['done'] == true).toList();
    final weekStart = today.subtract(const Duration(days: 6));
    int doneOn(DateTime d) => doneAll.where((x) {
          final ms = intOf(x['doneAt'], 0);
          if (ms == 0) return false;
          final dd = DateTime.fromMillisecondsSinceEpoch(ms);
          return dd.year == d.year && dd.month == d.month && dd.day == d.day;
        }).length;
    final doneWeek = doneAll.where((x) {
      final ms = intOf(x['doneAt'], 0);
      return ms > 0 && !DateTime.fromMillisecondsSinceEpoch(ms).isBefore(weekStart);
    }).length;
    final rate = all.isEmpty ? 0.0 : doneAll.length / all.length;

    var shown = all.where((x) => _match(x, _filter, today)).toList();
    if (_cat != null) shown = shown.where((x) => (x['cat'] ?? '') == _cat).toList();
    if (_filter == _F.done) {
      shown.sort((a, b) => intOf(b['doneAt']).compareTo(intOf(a['doneAt'])));
    } else {
      shown.sort((a, b) {
        final da = a['due'] as String?, db = b['due'] as String?;
        if (da != db) {
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        }
        return intOf(a['pri'], 1).compareTo(intOf(b['pri'], 1));
      });
    }
    final usedCats = {for (final x in all) (x['cat'] as String?) ?? ''}..remove('');

    return ToolList(children: [
      ResultHero(
        label: t('مهامك', 'مهامك', 'Your tasks'),
        value: '${pending.length}',
        sub: pending.isEmpty
            ? t('ما في حاجة معلّقة — مرتاح 😎', 'لا توجد مهام معلّقة 😎', 'Nothing pending 😎')
            : t('$dueToday الليلة · $overdue متأخرة', '$dueToday اليوم · $overdue متأخرة', '$dueToday today · $overdue overdue'),
        colors: const [SD.green, SD.teal, SD.nile],
      ),
      SCard(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        color: SD.green,
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _quick,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addQuick(),
              decoration: InputDecoration(
                hintText: t('ضيف مهمة سريعة…', 'أضف مهمة سريعة…', 'Quick add a task…'),
                prefixIcon: const Icon(Icons.add_task_rounded),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filled(onPressed: _addQuick, icon: const Icon(Icons.send_rounded), tooltip: t('ضيف', 'إضافة', 'Add')),
          IconButton(onPressed: () => _edit(), icon: const Icon(Icons.edit_note_rounded), tooltip: t('بالتفصيل', 'بالتفاصيل', 'With details')),
        ]),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final f in _F.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: PickChip(
                '${_fLabel(f)} (${all.where((x) => _match(x, f, today)).length})',
                _filter == f,
                () => setState(() => _filter = f),
                color: f == _F.overdue ? SD.red : (f == _F.done ? SD.green : SD.nile),
              ),
            ),
        ]),
      ),
      if (usedCats.isNotEmpty) ...[
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: PickChip(t('كل التصنيفات', 'كل التصنيفات', 'All categories'), _cat == null, () => setState(() => _cat = null), color: SD.teal),
            ),
            for (final c in usedCats)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: PickChip(_catLabel(c), _cat == c, () => setState(() => _cat = c), color: SD.teal),
              ),
          ]),
        ),
      ],
      const SizedBox(height: 10),
      if (shown.isEmpty)
        EmptyHint(
          _filter == _F.done ? Icons.inventory_2_outlined : Icons.task_alt_rounded,
          switch (_filter) {
            _F.today => t('ما عندك حاجة الليلة. ضيف مهمة أو أرتاح ☕', 'لا مهام لليوم. أضف مهمة أو استرح ☕', 'Nothing for today. Add one or relax ☕'),
            _F.overdue => t('ما في حاجة متأخرة، عافي منك 👏', 'لا توجد مهام متأخرة 👏', 'Nothing overdue 👏'),
            _F.done => t('لسه ما خلّصت أي مهمة', 'لم تُنجز أي مهمة بعد', 'No completed tasks yet'),
            _ => t('القائمة فاضية', 'القائمة فارغة', 'The list is empty'),
          },
        )
      else
        for (final x in shown) _tile(x, today),
      if (_filter == _F.done && shown.isNotEmpty)
        TextButton.icon(
          onPressed: () async {
            if (!await confirmAsk(context, t('نمسح المنجزة؟', 'حذف المنجزة؟', 'Clear completed?'),
                t('حتتمسح كل المهام المنجزة.', 'ستُحذف جميع المهام المنجزة.', 'All completed tasks will be removed.'))) {
              return;
            }
            final before = _list(s);
            _save(s, before.where((x) => x['done'] != true).toList());
            undoSnack(t('اتمسحت', 'تم الحذف', 'Cleared'), () => _save(s, before));
            setState(() {});
          },
          icon: const Icon(Icons.cleaning_services_rounded),
          label: Text(t('امسح كل المنجزة', 'حذف كل المنجزة', 'Clear all completed')),
        ),
      const SizedBox(height: 8),
      SCard(
        title: t('إحصائياتك', 'الإحصائيات', 'Stats'),
        icon: Icons.insights_rounded,
        color: SD.nile,
        child: Column(children: [
          StatGrid([
            StatChip('${pending.length}', t('معلّقة', 'معلّقة', 'Pending'), color: SD.gold, icon: Icons.pending_actions_rounded),
            StatChip('$overdue', t('متأخرة', 'متأخرة', 'Overdue'), color: SD.red, icon: Icons.running_with_errors_rounded),
            StatChip('$doneWeek', t('خلّصتها الأسبوع دا', 'أُنجزت هذا الأسبوع', 'Done this week'), color: SD.green, icon: Icons.task_alt_rounded),
            StatChip('${doneAll.length}', t('منجزة كلها', 'إجمالي المنجز', 'Total done'), color: SD.teal, icon: Icons.done_all_rounded),
            StatChip('${fmt(rate * 100, 0)}%', t('نسبة الإنجاز', 'نسبة الإنجاز', 'Completion'), color: SD.nile, icon: Icons.pie_chart_rounded),
            StatChip('${s.counter('tasks_done')}', t('من أول ما بديت', 'منذ البداية', 'All time'), color: SD.purple, icon: Icons.emoji_events_rounded),
          ]),
          const SizedBox(height: 14),
          BarChart([
            for (var i = 6; i >= 0; i--)
              () {
                final d = today.subtract(Duration(days: i));
                return Bar(i == 0 ? t('الليلة', 'اليوم', 'Today') : shortDaysL[d.weekday - 1], doneOn(d).toDouble());
              }(),
          ], color: SD.green, height: 140, valueText: (v) => v == 0 ? '' : fmt(v, 0)),
          Text(t('المهام اللي خلّصتها آخر 7 أيام', 'المهام المنجزة في آخر 7 أيام', 'Tasks completed in the last 7 days'), style: const TextStyle(fontSize: 11.5)),
        ]),
      ),
      NoteBox(
        t('اسحب المهمة لجهة البداية عشان تخلّصها، ولجهة النهاية عشان تمسحها. دوس عليها عشان تعدّلها.',
            'اسحب المهمة نحو البداية لإنجازها، ونحو النهاية لحذفها. اضغط عليها لتعديلها.',
            'Swipe a task toward the start to complete it, toward the end to delete. Tap to edit.'),
        kind: NoteKind.tip,
      ),
    ]);
  }

  String _fLabel(_F f) => switch (f) {
        _F.all => t('الكل', 'الكل', 'All'),
        _F.today => t('الليلة', 'اليوم', 'Today'),
        _F.upcoming => t('الجاية', 'القادمة', 'Upcoming'),
        _F.overdue => t('المتأخرة', 'المتأخرة', 'Overdue'),
        _F.done => t('المنجزة', 'المنجزة', 'Done'),
      };

  Widget _tile(Map<String, dynamic> x, DateTime today) {
    final done = x['done'] == true;
    final pri = intOf(x['pri'], 1);
    final pc = _priColor(pri);
    final due = parseDk(x['due']);
    final note = (x['note'] as String?) ?? '';
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .62);
    String? dueText;
    Color dueColor = muted;
    if (due != null) {
      final diff = dayDiff(today, due);
      if (diff == 0) {
        dueText = t('الليلة', 'اليوم', 'Today');
        dueColor = SD.orange;
      } else if (diff == 1) {
        dueText = t('بكرة', 'غدًا', 'Tomorrow');
      } else if (diff < 0) {
        dueText = t('متأخرة ${-diff} يوم', 'متأخرة ${-diff} يوم', '${-diff}d overdue');
        dueColor = SD.red;
      } else {
        dueText = fmtShort(due);
      }
      if (done) dueColor = muted;
    }
    return Dismissible(
      key: ValueKey(x['id']),
      background: _swipeBg(done ? Icons.undo_rounded : Icons.check_rounded, done ? SD.gold : SD.green, AlignmentDirectional.centerStart),
      secondaryBackground: _swipeBg(Icons.delete_rounded, SD.red, AlignmentDirectional.centerEnd),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          _setDone(x['id'], !done);
          return false;
        }
        return true;
      },
      onDismissed: (_) => _delete(x['id']),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: pc.withValues(alpha: .4))),
        child: InkWell(
          onTap: () => _edit(x),
          child: Container(
            decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: pc, width: 5))),
            padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 12, 6),
            child: Row(children: [
              Checkbox(
                value: done,
                activeColor: SD.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                onChanged: (v) => _setDone(x['id'], v ?? false),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${x['title']}',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done ? muted : null,
                      )),
                  if (note.isNotEmpty) Text(note, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: muted)),
                  const SizedBox(height: 3),
                  Wrap(spacing: 10, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    if (pri != 1)
                      Text('● ${_priLabel(pri)}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: readable(context, pc))),
                    if (dueText != null)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.event_rounded, size: 13, color: readable(context, dueColor)),
                        const SizedBox(width: 3),
                        Text(dueText, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: readable(context, dueColor))),
                      ]),
                    if (((x['cat'] as String?) ?? '').isNotEmpty) Text(_catLabel(x['cat']), style: TextStyle(fontSize: 11.5, color: muted)),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _swipeBg(IconData ic, Color c, AlignmentGeometry a) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: a,
        decoration: BoxDecoration(color: c.withValues(alpha: .85), borderRadius: BorderRadius.circular(18)),
        child: Icon(ic, color: Colors.white),
      );
}
