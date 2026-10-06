import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'writer_chars.dart';
import 'writer_common.dart';
import 'writer_data.dart';
import 'writer_structure.dart';

/// تبويب العالم: أماكن، أغراض، أساطير، بحث + بحث شامل في المشروع
class WorldTab extends StatefulWidget {
  final Map<String, dynamic> project;
  const WorldTab({super.key, required this.project});
  @override
  State<WorldTab> createState() => _WorldTabState();
}

class _Hit {
  final String icon, title, snippet;
  final VoidCallback onTap;
  _Hit(this.icon, this.title, this.snippet, this.onTap);
}

class _WorldTabState extends State<WorldTab> {
  final _q = TextEditingController();
  String? _kind;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  String _snip(String text, String q) {
    final i = text.toLowerCase().indexOf(q);
    if (i < 0) return text.length > 90 ? '${text.substring(0, 90)}…' : text;
    final a = (i - 30).clamp(0, text.length), b = (i + q.length + 50).clamp(0, text.length);
    return '${a > 0 ? '…' : ''}${text.substring(a, b).replaceAll('\n', ' ')}${b < text.length ? '…' : ''}';
  }

  List<_Hit> _search(AppState s, WStore st, Map<String, dynamic> p, String q) {
    final hits = <_Hit>[];
    bool has(String x) => x.toLowerCase().contains(q);
    for (final c in charsOf(p)) {
      final blob = [c['name'], c['age'], c['look'], strList(c['traits']).join(' '), c['back'], c['goal'], c['fear'], c['arc'], c['voice'], c['roleC']].join(' ');
      if (has(blob)) hits.add(_Hit('👤', '${c['name']}', _snip(blob, q), () => editCharacter(context, s, p, c)));
    }
    for (final ch in chaptersOf(p)) {
      if (has('${ch['title'] ?? ''}')) hits.add(_Hit('📘', '${ch['title']}', tr('فصل', 'Chapter'), () {}));
      for (final sc in mapList(ch['scenes'])) {
        final meta = '${sc['title'] ?? ''} ${sc['summary'] ?? ''} ${sc['loc'] ?? ''}';
        final txt = st.text('${sc['id']}');
        if (has(meta) || has(txt)) {
          hits.add(_Hit('🎬', '${sc['title'] ?? ''}', _snip(has(meta) ? meta : txt, q), () => editScene(context, st, p, ch['id'] as String, sc)));
        }
      }
    }
    for (final n in notesOf(p)) {
      final blob = '${n['title'] ?? ''} ${n['body'] ?? ''} ${strList(n['tags']).join(' ')}';
      if (has(blob)) hits.add(_Hit(wFind(wNoteKinds, n['kind']).emoji, '${n['title'] ?? ''}', _snip(blob, q), () => editNote(context, st, p, n)));
    }
    return hits;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = WStore(s);
    final p = widget.project;
    final q = _q.text.trim().toLowerCase();
    final notes = notesOf(p).where((n) => _kind == null || n['kind'] == _kind).toList();
    return ToolList(children: [
      TextField(
        controller: _q,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: t('فتّش في كل المشروع…', 'ابحث في المشروع كله…', 'Search the whole project…'),
          suffixIcon: q.isEmpty
              ? null
              : IconButton(
                  onPressed: () => setState(() => _q.clear()),
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
      const SizedBox(height: 12),
      if (q.isNotEmpty)
        Builder(builder: (context) {
          final hits = _search(s, st, p, q);
          return SCard(
            title: '${t('النتائج', 'النتائج', 'Results')} (${hits.length})',
            icon: Icons.manage_search_rounded,
            color: SD.teal,
            child: hits.isEmpty
                ? Text(t('ما لقينا حاجة.', 'لا توجد نتائج.', 'Nothing found.'))
                : Column(children: [
                    for (final h in hits)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Text(h.icon, style: const TextStyle(fontSize: 22)),
                        title: Text(h.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(h.snippet, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: h.onTap,
                      ),
                  ]),
          );
        }),
      SCard(
        title: t('دفتر العالم', 'دفتر العالم', 'World notes'),
        icon: Icons.public_rounded,
        color: SD.teal,
        trailing: IconButton(
          tooltip: t('ملاحظة جديدة', 'ملاحظة جديدة', 'New note'),
          onPressed: () => editNote(context, st, p, null, kind: _kind),
          icon: const Icon(Icons.add_circle_rounded, color: SD.gold),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            PickChip(t('الكل', 'الكل', 'All'), _kind == null, () => setState(() => _kind = null), color: SD.brownLight),
            for (final k in wNoteKinds)
              PickChip('${k.label} ${notesOf(p).where((n) => n['kind'] == k.key).length}', _kind == k.key, () => setState(() => _kind = k.key), color: k.color),
          ]),
          const SizedBox(height: 10),
          if (notes.isEmpty)
            Text(t('ما في ملاحظات هنا. سجّل أماكن قصتك وأغراضها وتاريخها وبحثك.', 'لا ملاحظات هنا. سجّل أماكن قصتك وأغراضها وتاريخها وبحثك.',
                'No notes here. Record your places, items, lore and research.')),
          for (final n in notes) _NoteCard(n, onTap: () => editNote(context, st, p, n)),
        ]),
      ),
    ]);
  }
}

class _NoteCard extends StatelessWidget {
  final Map<String, dynamic> n;
  final VoidCallback onTap;
  const _NoteCard(this.n, {required this.onTap});
  @override
  Widget build(BuildContext context) {
    final k = wFind(wNoteKinds, n['kind']);
    final tags = strList(n['tags']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: k.color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(14),
            border: BorderDirectional(start: BorderSide(color: k.color, width: 4)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${k.emoji} ${n['title'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
            if ('${n['body'] ?? ''}'.trim().isNotEmpty) ...[
              const SizedBox(height: 3),
              Text('${n['body']}', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.4)),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 5),
              Wrap(spacing: 4, runSpacing: 4, children: [for (final x in tags) WTag('#$x', color: k.color)]),
            ],
          ]),
        ),
      ),
    );
  }
}

/// ورقة إنشاء/تعديل ملاحظة عالم
Future<void> editNote(BuildContext context, WStore st, Map<String, dynamic> p, Map<String, dynamic>? n, {String? kind, String? body, String? title}) async {
  final pid = p['id'] as String;
  final id = (n?['id'] as String?) ?? newId();
  final titleC = TextEditingController(text: title ?? '${n?['title'] ?? ''}');
  final bodyC = TextEditingController(text: body ?? '${n?['body'] ?? ''}');
  final tagsC = TextEditingController(text: strList(n?['tags']).join(', '));
  var k = '${n?['kind'] ?? kind ?? 'place'}';
  await lifeSheet<void>(
    context,
    n == null ? t('ملاحظة جديدة', 'ملاحظة جديدة', 'New note') : t('عدّل الملاحظة', 'تعديل الملاحظة', 'Edit note'),
    (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final x in wNoteKinds) PickChip(x.label, k == x.key, () => set(() => k = x.key), color: x.color),
      ]),
      const SizedBox(height: 12),
      wField(titleC, t('العنوان', 'العنوان', 'Title')),
      wField(bodyC, t('التفاصيل', 'التفاصيل', 'Details'), lines: 8),
      wField(tagsC, t('وسوم (افصل بفاصلة)', 'وسوم (مفصولة بفواصل)', 'Tags (comma separated)')),
      wSheetButtons(
        ctx,
        onDelete: n == null
            ? null
            : () async {
                final ok = await confirmAsk(ctx, t('تمسح الملاحظة؟', 'حذف الملاحظة؟', 'Delete note?'), '${n['title'] ?? ''}');
                if (!ok) return;
                st.edit((x) => sub(x, 'notes').removeWhere((e) => e['id'] == id), id: pid);
                if (ctx.mounted) Navigator.pop(ctx);
              },
        onSave: () {
          final d = {
            'id': id,
            'kind': k,
            'title': titleC.text.trim().isEmpty ? t('بدون عنوان', 'بلا عنوان', 'Untitled') : titleC.text.trim(),
            'body': bodyC.text.trim(),
            'tags': [for (final x in tagsC.text.split(RegExp(r'[,،]'))) if (x.trim().isNotEmpty) x.trim()],
          };
          st.edit((x) {
            final l = sub(x, 'notes');
            final i = l.indexWhere((e) => e['id'] == id);
            i < 0 ? l.insert(0, d) : l[i] = d;
          }, id: pid);
          Navigator.pop(ctx);
        },
      ),
    ]),
  );
}

/* ───────────── تبويب الإلهام ───────────── */

class InspireTab extends StatefulWidget {
  const InspireTab({super.key});
  @override
  State<InspireTab> createState() => _InspireTabState();
}

class _InspireTabState extends State<InspireTab> {
  String? _whatIf;

  String _prompt(int i) => t(wPrompts[i].$1, wPrompts[i].$2, wPrompts[i].$3);

  void _keep(BuildContext context, WStore st, String text) {
    final p = st.current;
    if (p == null) {
      copyText(text);
      return;
    }
    editNote(context, st, p, null, kind: 'research', title: t('فكرة', 'فكرة', 'Idea'), body: text);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = WStore(s);
    _whatIf ??= genWhatIf();
    final now = todayPlace();
    final daily = (now.difference(DateTime(now.year)).inDays + now.year) % wPrompts.length;
    Widget actions(String text) => Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          IconButton(tooltip: t('انسخ', 'نسخ', 'Copy'), onPressed: () => copyText(text), icon: const Icon(Icons.copy_rounded, size: 20)),
          IconButton(
            tooltip: t('شارك', 'مشاركة', 'Share'),
            onPressed: () => SharePlus.instance.share(ShareParams(text: text)),
            icon: const Icon(Icons.share_rounded, size: 20),
          ),
          IconButton(
            tooltip: t('احفظها في المشروع', 'حفظ في المشروع', 'Save to project'),
            onPressed: () => _keep(context, st, text),
            icon: const Icon(Icons.bookmark_add_rounded, size: 20, color: SD.gold),
          ),
        ]);
    return ToolList(children: [
      SCard(
        title: t('شنو لو…؟', 'ماذا لو…؟', 'What if…?'),
        icon: Icons.psychology_alt_rounded,
        color: SD.purple,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_whatIf!, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.6)),
          actions(_whatIf!),
          FilledButton.icon(
            onPressed: () => setState(() => _whatIf = genWhatIf()),
            icon: const Icon(Icons.casino_rounded),
            label: Text(t('فكرة تانية', 'فكرة أخرى', 'Another idea')),
          ),
        ]),
      ),
      SCard(
        title: t('محفّز اليوم', 'محفّز اليوم', "Today's prompt"),
        icon: Icons.wb_sunny_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_prompt(daily), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.6)),
          actions(_prompt(daily)),
        ]),
      ),
      SCard(
        title: '${t('محفّزات الكتابة', 'محفزات الكتابة', 'Writing prompts')} (${wPrompts.length})',
        icon: Icons.format_list_numbered_rounded,
        color: SD.indigo,
        child: Column(children: [
          for (var i = 0; i < wPrompts.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 4, 0),
              decoration: BoxDecoration(
                color: SD.indigo.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('${i + 1}. ${_prompt(i)}', style: const TextStyle(height: 1.5)),
                actions(_prompt(i)),
              ]),
            ),
        ]),
      ),
    ]);
  }
}
