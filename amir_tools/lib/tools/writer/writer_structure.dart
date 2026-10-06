import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'writer_common.dart';
import 'writer_data.dart';
import 'writer_editor.dart';
import 'writer_paint.dart';

/// تبويب الهيكل: الفصول ← المشاهد، قوالب الحبكة، منحنى القصة
class StructureTab extends StatelessWidget {
  final Map<String, dynamic> project;
  const StructureTab({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = WStore(s);
    final p = project;
    final pid = p['id'] as String;
    final chs = chaptersOf(p);
    final scenes = allScenes(p);
    final beats = beatsOf(p);
    final tpl = wTemplate(p['tpl'] as String?);

    Future<void> addChapter() async {
      final name = await askText(context, t('فصل جديد', 'فصل جديد', 'New chapter'), hint: t('عنوان الفصل', 'عنوان الفصل', 'Chapter title'));
      if (name == null) return;
      st.edit((x) => sub(x, 'chapters').add({'id': newId(), 'title': name.trim(), 'scenes': []}), id: pid);
    }

    return ToolList(children: [
      if (scenes.isNotEmpty)
        SCard(
          title: t('منحنى القصة', 'منحنى القصة', 'Story arc'),
          icon: Icons.show_chart_rounded,
          color: SD.purple,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            StoryArc(chs),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
              for (final x in wSceneStatus) WTag('${x.label} ${scenes.where((e) => (e['status'] ?? 'idea') == x.key).length}', color: x.color),
            ]),
            const SizedBox(height: 4),
            Text(t('الأرقام تحت = رقم الفصل', 'الأرقام بالأسفل = رقم الفصل', 'Numbers below = chapter number'),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5)),
          ]),
        ),
      SCard(
        title: t('الفصول والمشاهد', 'الفصول والمشاهد', 'Chapters & scenes'),
        icon: Icons.menu_book_rounded,
        color: SD.indigo,
        trailing: IconButton(tooltip: t('فصل جديد', 'فصل جديد', 'New chapter'), onPressed: addChapter, icon: const Icon(Icons.add_circle_rounded, color: SD.gold)),
        child: chs.isEmpty
            ? Text(t('ما في فصول. أضف أول فصل.', 'لا توجد فصول. أضف الفصل الأول.', 'No chapters yet. Add the first one.'))
            : ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorderItem: (o, n) => st.edit((x) {
                  final l = sub(x, 'chapters');
                  l.insert(n, l.removeAt(o));
                }, id: pid),
                children: [
                  for (var i = 0; i < chs.length; i++) _ChapterTile(key: ValueKey(chs[i]['id']), index: i, ch: chs[i], p: p, st: st),
                ],
              ),
      ),
      SCard(
        title: t('قالب الحبكة', 'قالب الحبكة', 'Plot template'),
        icon: Icons.route_rounded,
        color: SD.gold,
        trailing: tpl == null
            ? null
            : IconButton(
                tooltip: t('غيّر القالب', 'تغيير القالب', 'Change template'),
                onPressed: () async {
                  final ok = await confirmAsk(context, t('تشيل القالب؟', 'إزالة القالب؟', 'Remove template?'),
                      t('حتنمسح المحطات والعلامات (المشاهد ما بتتأثر).', 'ستُحذف المحطات وعلاماتها (لا تتأثر المشاهد).', 'Beats and checkmarks will be removed (scenes stay).'));
                  if (ok) st.edit((x) => x..['tpl'] = null..['beats'] = [], id: pid);
                },
                icon: const Icon(Icons.swap_horiz_rounded),
              ),
        child: tpl == null
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(t('اختار قالب عشان تتولّد محطات الحبكة وتربطها بالمشاهد:', 'اختر قالبًا لتوليد محطات الحبكة وربطها بالمشاهد:',
                    'Pick a template to generate plot beats and link them to scenes:')),
                const SizedBox(height: 8),
                for (final x in wTemplates)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(x.emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(x.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${x.beats.length} ${tr('محطة', 'beats')}'),
                    trailing: const Icon(Icons.add_task_rounded),
                    onTap: () => st.edit(
                        (y) => y
                          ..['tpl'] = x.key
                          ..['beats'] = [for (var i = 0; i < x.beats.length; i++) {'i': i, 'done': false, 'scene': null}],
                        id: pid),
                  ),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('${tpl.emoji} ${tpl.name}', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                WProgress(
                  beats.isEmpty ? 0 : beats.where((b) => b['done'] == true).length / beats.length,
                  color: SD.gold,
                  label: '${beats.where((b) => b['done'] == true).length} / ${beats.length}',
                ),
                const SizedBox(height: 6),
                for (var i = 0; i < beats.length; i++) _BeatRow(i: i, beat: beats[i], tpl: tpl, p: p, st: st),
              ]),
      ),
    ]);
  }
}

class _BeatRow extends StatelessWidget {
  final int i;
  final Map<String, dynamic> beat, p;
  final WTemplate tpl;
  final WStore st;
  const _BeatRow({required this.i, required this.beat, required this.tpl, required this.p, required this.st});

  @override
  Widget build(BuildContext context) {
    final bi = intOf(beat['i']).clamp(0, tpl.beats.length - 1);
    final b = tpl.beats[bi];
    final scenes = allScenes(p);
    final linked = scenes.where((x) => x['id'] == beat['scene']).firstOrNull;
    final done = beat['done'] == true;
    void upd(void Function(Map<String, dynamic>) fn) => st.edit((x) {
          final l = sub(x, 'beats');
          if (i < l.length) fn(l[i]);
        }, id: p['id'] as String);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Checkbox(value: done, onChanged: (v) => upd((m) => m['done'] = v == true)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${i + 1}. ${b.name}',
                  style: TextStyle(fontWeight: FontWeight.w800, decoration: done ? TextDecoration.lineThrough : null)),
              Text(b.desc, style: const TextStyle(fontSize: 12.5)),
              if (linked != null) ...[
                const SizedBox(height: 3),
                WTag('🎬 ${linked['title'] ?? ''}', color: SD.teal),
              ],
            ]),
          ),
        ),
        IconButton(
          tooltip: t('اربط بمشهد', 'ربط بمشهد', 'Link to scene'),
          icon: Icon(linked == null ? Icons.link_rounded : Icons.link_off_rounded, size: 20),
          onPressed: () async {
            if (linked != null) return upd((m) => m['scene'] = null);
            if (scenes.isEmpty) {
              toast(t('أضف مشاهد أول', 'أضف مشاهد أولًا', 'Add scenes first'));
              return;
            }
            final id = await showModalBottomSheet<String>(
              context: context,
              showDragHandle: true,
              builder: (c) => ListView(shrinkWrap: true, children: [
                for (final sc in scenes)
                  ListTile(
                    leading: Icon(Icons.circle, size: 12, color: wFind(wSceneStatus, sc['status']).color),
                    title: Text('${sc['title'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => Navigator.pop(c, sc['id'] as String),
                  ),
              ]),
            );
            if (id != null) upd((m) => m['scene'] = id);
          },
        ),
      ]),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final int index;
  final Map<String, dynamic> ch, p;
  final WStore st;
  const _ChapterTile({super.key, required this.index, required this.ch, required this.p, required this.st});

  @override
  Widget build(BuildContext context) {
    final pid = p['id'] as String;
    final cid = ch['id'] as String;
    final scenes = mapList(ch['scenes']);
    final wc = scenes.fold<int>(0, (a, b) => a + intOf(b['wc']));
    void editCh(void Function(Map<String, dynamic>) fn) => st.edit((x) {
          for (final c in sub(x, 'chapters')) {
            if (c['id'] == cid) fn(c);
          }
        }, id: pid);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SD.indigo.withValues(alpha: .4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.drag_indicator_rounded)),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${tr('الفصل', 'Chapter')} ${index + 1}${'${ch['title'] ?? ''}'.trim().isEmpty ? '' : ': ${ch['title']}'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              Text('${scenes.length} ${tr('مشهد', 'scenes')} · ${fmt(wc, 0)} ${tr('كلمة', 'words')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            ]),
          ),
          IconButton(
            tooltip: t('مشهد جديد', 'مشهد جديد', 'New scene'),
            onPressed: () => editScene(context, st, p, cid, null),
            icon: const Icon(Icons.add_rounded, color: SD.gold),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'rename') {
                final n = await askText(context, t('عنوان الفصل', 'عنوان الفصل', 'Chapter title'), initial: '${ch['title'] ?? ''}');
                if (n != null) editCh((c) => c['title'] = n.trim());
              } else if (v == 'del') {
                final ok = await confirmAsk(context, t('تمسح الفصل؟', 'حذف الفصل؟', 'Delete chapter?'),
                    t('حتتمسح مشاهدو ونصوصها.', 'ستُحذف مشاهده ونصوصها.', 'Its scenes and texts will be deleted.'));
                if (!ok) return;
                for (final sc in scenes) {
                  st.s.setData('writer_txt_${sc['id']}', null);
                }
                st.edit((x) => sub(x, 'chapters').removeWhere((c) => c['id'] == cid), id: pid);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'rename', child: Text(t('غيّر العنوان', 'إعادة التسمية', 'Rename'))),
              PopupMenuItem(value: 'del', child: Text(t('امسح الفصل', 'حذف الفصل', 'Delete chapter'))),
            ],
          ),
        ]),
        if (scenes.isNotEmpty)
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (o, n) => editCh((c) {
              final l = sub(c, 'scenes');
              l.insert(n, l.removeAt(o));
            }),
            children: [
              for (var j = 0; j < scenes.length; j++) _SceneRow(key: ValueKey(scenes[j]['id']), index: j, sc: scenes[j], p: p, cid: cid, st: st),
            ],
          ),
        const SizedBox(height: 4),
      ]),
    );
  }
}

class _SceneRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> sc, p;
  final String cid;
  final WStore st;
  const _SceneRow({super.key, required this.index, required this.sc, required this.p, required this.cid, required this.st});

  @override
  Widget build(BuildContext context) {
    final status = wFind(wSceneStatus, sc['status']);
    final pov = charName(p, sc['pov'] as String?);
    final info = [
      status.name,
      if (pov.isNotEmpty) '👁 $pov',
      if ('${sc['loc'] ?? ''}'.trim().isNotEmpty) '📍 ${sc['loc']}',
      '${fmt(intOf(sc['wc']), 0)} ${tr('كلمة', 'w')}',
    ].join(' · ');
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => editScene(context, st, p, cid, sc),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 2, 0, 2),
          child: Row(children: [
            ReorderableDragStartListener(
              index: index,
              child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.drag_handle_rounded, size: 20, color: status.color)),
            ),
            Container(width: 4, height: 34, decoration: BoxDecoration(color: status.color, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${sc['title'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(info, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)),
              ]),
            ),
            IconButton(
              tooltip: t('اكتب', 'اكتب', 'Write'),
              onPressed: () => SceneEditor.open(context, st.s, p['id'] as String, cid, sc['id'] as String),
              icon: const Icon(Icons.edit_note_rounded, color: SD.gold),
            ),
          ]),
        ),
      ),
    );
  }
}

/// ورقة إنشاء/تعديل مشهد
Future<void> editScene(BuildContext context, WStore st, Map<String, dynamic> p, String cid, Map<String, dynamic>? sc) async {
  final pid = p['id'] as String;
  final id = (sc?['id'] as String?) ?? newId();
  final titleC = TextEditingController(text: '${sc?['title'] ?? ''}');
  final sumC = TextEditingController(text: '${sc?['summary'] ?? ''}');
  final locC = TextEditingController(text: '${sc?['loc'] ?? ''}');
  String? pov = sc?['pov'] as String?;
  var status = '${sc?['status'] ?? 'idea'}';
  final present = strList(sc?['present']);
  var chapter = cid;
  final chars = charsOf(p);
  final chs = chaptersOf(p);
  final places = notesOf(p).where((n) => n['kind'] == 'place').map((n) => '${n['title'] ?? ''}').where((x) => x.isNotEmpty).toList();
  var openEditor = false;

  Map<String, dynamic> data() => {
        'id': id,
        'title': titleC.text.trim().isEmpty ? '${t('مشهد', 'مشهد', 'Scene')} ${allScenes(p).length + (sc == null ? 1 : 0)}' : titleC.text.trim(),
        'summary': sumC.text.trim(),
        'loc': locC.text.trim(),
        'pov': pov,
        'present': present,
        'status': status,
        'wc': intOf(sc?['wc']),
      };

  void save() {
    final d = data();
    st.edit((x) {
      final l = sub(x, 'chapters');
      for (final c in l) {
        sub(c, 'scenes').removeWhere((e) => e['id'] == id);
      }
      final target = l.firstWhere((c) => c['id'] == chapter, orElse: () => l.first);
      final scs = sub(target, 'scenes');
      // يحافظ على الموضع إن لم يتغيّر الفصل
      final orig = chs.firstWhere((c) => c['id'] == chapter, orElse: () => {});
      final oi = mapList(orig['scenes']).indexWhere((e) => e['id'] == id);
      if (oi >= 0 && oi <= scs.length) {
        scs.insert(oi, d);
      } else {
        scs.add(d);
      }
    }, id: pid);
  }

  await lifeSheet<void>(
    context,
    sc == null ? t('مشهد جديد', 'مشهد جديد', 'New scene') : t('تفاصيل المشهد', 'تفاصيل المشهد', 'Scene details'),
    (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      wField(titleC, t('عنوان المشهد', 'عنوان المشهد', 'Scene title')),
      wField(sumC, t('ملخّص المشهد', 'ملخص المشهد', 'Summary'), lines: 4),
      wField(locC, t('المكان', 'المكان', 'Location')),
      if (places.isNotEmpty)
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final pl in places) ActionChip(label: Text('📍 $pl'), onPressed: () => set(() => locC.text = pl)),
        ]),
      wLabel(t('الحالة', 'الحالة', 'Status')),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final x in wSceneStatus) PickChip(x.label, status == x.key, () => set(() => status = x.key), color: x.color),
      ]),
      if (chars.isNotEmpty) ...[
        wLabel(t('الراوي / وجهة النظر', 'وجهة النظر (POV)', 'POV character')),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final c in chars) PickChip('${c['name'] ?? ''}', pov == c['id'], () => set(() => pov = pov == c['id'] ? null : c['id'] as String), color: SD.purple),
        ]),
        wLabel(t('الشخصيات الموجودة', 'الشخصيات الحاضرة', 'Characters present')),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final c in chars)
            FilterChip(
              label: Text('${c['name'] ?? ''}'),
              selected: present.contains(c['id']),
              onSelected: (v) => set(() => v ? present.add(c['id'] as String) : present.remove(c['id'])),
            ),
        ]),
      ],
      if (chs.length > 1) ...[
        wLabel(t('الفصل', 'الفصل', 'Chapter')),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (var i = 0; i < chs.length; i++)
            PickChip('${i + 1}. ${chs[i]['title'] ?? ''}', chapter == chs[i]['id'], () => set(() => chapter = chs[i]['id'] as String), color: SD.indigo),
        ]),
      ],
      const SizedBox(height: 12),
      FilledButton.tonalIcon(
        onPressed: () {
          openEditor = true;
          save();
          Navigator.pop(ctx);
        },
        icon: const Icon(Icons.edit_note_rounded),
        label: Text(t('افتح المحرر واكتب', 'افتح المحرر واكتب', 'Open the editor & write'), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      wSheetButtons(
        ctx,
        onDelete: sc == null
            ? null
            : () async {
                final ok = await confirmAsk(ctx, t('تمسح المشهد؟', 'حذف المشهد؟', 'Delete scene?'), '${sc['title'] ?? ''}');
                if (!ok) return;
                st.s.setData('writer_txt_$id', null);
                st.edit((x) {
                  for (final c in sub(x, 'chapters')) {
                    sub(c, 'scenes').removeWhere((e) => e['id'] == id);
                  }
                  for (final b in sub(x, 'beats')) {
                    if (b['scene'] == id) b['scene'] = null;
                  }
                }, id: pid);
                if (ctx.mounted) Navigator.pop(ctx);
              },
        onSave: () {
          save();
          Navigator.pop(ctx);
        },
      ),
    ]),
  );
  if (openEditor && context.mounted) await SceneEditor.open(context, st.s, pid, chapter, id);
}
