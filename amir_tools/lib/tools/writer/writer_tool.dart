import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'writer_chars.dart';
import 'writer_common.dart';
import 'writer_data.dart';
import 'writer_stats.dart';
import 'writer_structure.dart';
import 'writer_world.dart';

/// استوديو الكاتب: مشاريع، شخصيات، هيكل، عالم، إلهام، إحصائيات
class WriterTool extends StatefulWidget {
  const WriterTool({super.key});
  @override
  State<WriterTool> createState() => _WriterToolState();
}

class _WriterToolState extends State<WriterTool> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _tabs = TabController(length: 6, vsync: this, initialIndex: intOf(s.getData('writer_tab')).clamp(0, 5));
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) s.setData('writer_tab', _tabs.index);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _create() async {
    final s = context.read<AppState>();
    final id = await editProject(context, s, null);
    if (id != null && mounted) _tabs.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = WStore(s);
    final projects = st.projects;
    final cur = st.current;
    Tab tab(IconData ic, String label) => Tab(
          height: 50,
          iconMargin: const EdgeInsets.only(bottom: 2),
          icon: Icon(ic, size: 20),
          child: Text(label, maxLines: 1, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        );
    return Column(children: [
      if (cur != null && projects.length > 1)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: PopupMenuButton<String>(
            tooltip: t('غيّر المشروع', 'تبديل المشروع', 'Switch project'),
            onSelected: (id) => st.currentId = id,
            itemBuilder: (_) => [
              for (final p in projects)
                PopupMenuItem(
                  value: p['id'] as String,
                  child: Text('${p['emoji'] ?? '📖'} ${p['title'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: palette(intOf(cur['color'])).withValues(alpha: .15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SD.gold.withValues(alpha: .4)),
              ),
              child: Row(children: [
                Text('${cur['emoji'] ?? '📖'}', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(child: Text('${cur['title'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
                const Icon(Icons.unfold_more_rounded, size: 20),
              ]),
            ),
          ),
        ),
      TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        indicatorColor: SD.gold,
        tabs: [
          tab(Icons.auto_stories_rounded, t('القصة', 'القصة', 'Story')),
          tab(Icons.people_alt_rounded, t('الشخصيات', 'الشخصيات', 'Cast')),
          tab(Icons.account_tree_rounded, t('الهيكل', 'الهيكل', 'Plot')),
          tab(Icons.public_rounded, t('العالم', 'العالم', 'World')),
          tab(Icons.lightbulb_rounded, t('الإلهام', 'الإلهام', 'Ideas')),
          tab(Icons.insights_rounded, t('إحصائيات', 'الإحصائيات', 'Stats')),
        ],
      ),
      Expanded(
        child: TabBarView(controller: _tabs, children: [
          StoryTab(onCreate: _create),
          cur == null ? NeedProject(_create) : CharsTab(project: cur),
          cur == null ? NeedProject(_create) : StructureTab(project: cur),
          cur == null ? NeedProject(_create) : WorldTab(project: cur),
          const InspireTab(),
          const StatsTab(),
        ]),
      ),
    ]);
  }
}

/* ───────────── تبويب القصة / المشاريع ───────────── */

class StoryTab extends StatelessWidget {
  final VoidCallback onCreate;
  const StoryTab({super.key, required this.onCreate});

  void _share(String text, String subject) => SharePlus.instance.share(ShareParams(text: text, subject: subject));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = WStore(s);
    final projects = st.projects;
    final p = st.current;
    if (p == null) {
      return ToolList(children: [
        ResultHero(
          label: t('استوديو الكاتب', 'استوديو الكاتب', "Writer's Studio"),
          value: '✍️',
          sub: t('رتّب روايتك: شخصيات، فصول، مشاهد، حبكة، وهدف يومي', 'نظّم روايتك: شخصيات، فصول، مشاهد، حبكة، وهدف يومي',
              'Plan your story: characters, chapters, scenes, plot & daily goals'),
          colors: const [SD.purple, SD.indigo, SD.brownDeep],
        ),
        FilledButton.icon(
            onPressed: onCreate, icon: const Icon(Icons.add_rounded), label: Text(t('ابدأ مشروع جديد', 'ابدأ مشروعًا جديدًا', 'Start a new project'))),
        const SizedBox(height: 12),
        NoteBox(t('كل حاجة محفوظة في جهازك وبتشتغل بدون نت.', 'كل البيانات محفوظة على جهازك وتعمل دون إنترنت.', 'Everything is stored on your device and works offline.'),
            kind: NoteKind.tip),
      ]);
    }
    final words = projectWords(p);
    final target = intOf(p['target']);
    final chs = chaptersOf(p);
    final scenes = allScenes(p);
    final chars = charsOf(p);
    final genre = wFind(wGenres, p['genre']);
    final status = wFind(wProjStatus, p['status']);
    final dl = parseDk(p['deadline'] as String?);
    final daysLeft = dl == null ? null : dayDiff(todayPlace(), dl);
    final col = palette(intOf(p['color'], 8));
    final ready = scenes.where((x) => x['status'] == 'ready').length;
    return ToolList(children: [
      // بطاقة المشروع الحالي
      Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [col, Color.lerp(col, Colors.black, .45)!], begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SD.gold, width: 1.6),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text('${p['emoji'] ?? '📖'}', style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p['title'] ?? ''}',
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  WTag(genre.label, color: SD.goldLight),
                  WTag(status.label, color: SD.goldLight),
                ]),
              ]),
            ),
            IconButton(
              tooltip: t('عدّل', 'تعديل', 'Edit'),
              onPressed: () => editProject(context, s, p),
              icon: const Icon(Icons.edit_rounded, color: SD.goldLight),
            ),
          ]),
          if ('${p['logline'] ?? ''}'.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('«${p['logline']}»', style: const TextStyle(color: SD.cream, fontStyle: FontStyle.italic, height: 1.5)),
          ],
          const SizedBox(height: 12),
          if (target > 0)
            DefaultTextStyle.merge(
              style: const TextStyle(color: SD.cream),
              child: WProgress(words / target,
                  color: SD.goldLight, label: '${fmt(words, 0)} / ${fmt(target, 0)} ${tr('كلمة', 'words')} · ${fmt(100 * words / target, 0)}%'),
            ),
          if (daysLeft != null) ...[
            const SizedBox(height: 8),
            Text(
              daysLeft < 0
                  ? t('الموعد فات من ${-daysLeft} يوم', 'تجاوزت الموعد بـ ${-daysLeft} يوم', 'Deadline passed ${-daysLeft} days ago')
                  : '${t('فاضل', 'متبقٍ', 'Left')}: $daysLeft ${tr('يوم', 'days')}'
                      '${target > words && daysLeft > 0 ? ' · ${t('محتاج', 'المطلوب', 'need')} ${fmt((target - words) / daysLeft, 0)} ${tr('كلمة/يوم', 'words/day')}' : ''}',
              style: const TextStyle(color: SD.cream, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ]),
      ),
      StatGrid([
        StatChip(fmt(words, 0), tr('كلمة', 'Words'), color: SD.purple, icon: Icons.notes_rounded),
        StatChip('${chs.length}', t('فصول', 'فصول', 'Chapters'), color: SD.nile, icon: Icons.menu_book_rounded),
        StatChip('${scenes.length}', t('مشاهد', 'مشاهد', 'Scenes'), color: SD.teal, icon: Icons.movie_filter_rounded),
        StatChip('${chars.length}', t('شخصيات', 'شخصيات', 'Characters'), color: SD.henna, icon: Icons.people_alt_rounded),
        StatChip('$ready', t('مشاهد جاهزة', 'مشاهد جاهزة', 'Ready scenes'), color: SD.green, icon: Icons.task_alt_rounded),
        StatChip('${readMinutes(words)}', t('دقائق قراية', 'دقائق قراءة', 'Min to read'), color: SD.gold, icon: Icons.timer_rounded),
      ]),
      const SizedBox(height: 14),
      if ('${p['synopsis'] ?? ''}'.trim().isNotEmpty)
        SCard(
          title: t('الملخّص', 'الملخص', 'Synopsis'),
          icon: Icons.short_text_rounded,
          color: SD.purple,
          child: Text('${p['synopsis']}', style: const TextStyle(height: 1.6)),
        ),
      SCard(
        title: t('صدّر وشارك', 'التصدير والمشاركة', 'Export & share'),
        icon: Icons.ios_share_rounded,
        color: SD.indigo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            t('بيجمع العنوان والفصول ونصوص المشاهد بالترتيب.', 'يجمع العنوان والفصول ونصوص المشاهد بالترتيب.', 'Compiles the title, chapters and scene texts in order.'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => _share(compileManuscript(st, p, markdown: false), '${p['title']}'),
            icon: const Icon(Icons.description_rounded),
            label: Text(t('المخطوطة (نص عادي)', 'المخطوطة (نص عادي)', 'Manuscript (plain text)'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _share(compileManuscript(st, p, markdown: true), '${p['title']}'),
            icon: const Icon(Icons.code_rounded),
            label: Text(t('المخطوطة (Markdown)', 'المخطوطة (Markdown)', 'Manuscript (Markdown)'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: chars.isEmpty ? null : () => _share(compileCharacters(p), '${p['title']}'),
            icon: const Icon(Icons.badge_rounded),
            label: Text(t('بطاقات الشخصيات', 'بطاقات الشخصيات', 'Character sheets'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => copyText(compileManuscript(st, p, markdown: false)),
            icon: const Icon(Icons.copy_rounded),
            label: Text(t('انسخ المخطوطة', 'نسخ المخطوطة', 'Copy manuscript'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
      SCard(
        title: '${t('مشاريعك', 'مشاريعك', 'Your projects')} (${projects.length})',
        icon: Icons.collections_bookmark_rounded,
        color: SD.purple,
        trailing: IconButton(tooltip: t('مشروع جديد', 'مشروع جديد', 'New project'), onPressed: onCreate, icon: const Icon(Icons.add_circle_rounded, color: SD.gold)),
        child: Column(children: [
          for (final x in projects) _ProjectRow(x, selected: x['id'] == p['id'], onTap: () => st.currentId = x['id'] as String),
        ]),
      ),
    ]);
  }
}

class _ProjectRow extends StatelessWidget {
  final Map<String, dynamic> p;
  final bool selected;
  final VoidCallback onTap;
  const _ProjectRow(this.p, {required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final words = projectWords(p);
    final target = intOf(p['target']);
    final col = palette(intOf(p['color'], 8));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: col.withValues(alpha: selected ? .22 : .08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? SD.gold : col.withValues(alpha: .3), width: selected ? 2 : 1),
          ),
          child: Row(children: [
            CircleAvatar(radius: 22, backgroundColor: col.withValues(alpha: .3), child: Text('${p['emoji'] ?? '📖'}', style: const TextStyle(fontSize: 22))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p['title'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text('${wFind(wGenres, p['genre']).name} · ${wFind(wProjStatus, p['status']).name} · ${fmt(words, 0)} ${tr('كلمة', 'words')}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                if (target > 0) ...[const SizedBox(height: 5), WProgress(words / target, color: readable(context, col))],
              ]),
            ),
            if (selected) const Padding(padding: EdgeInsetsDirectional.only(start: 6), child: Icon(Icons.check_circle_rounded, color: SD.gold)),
          ]),
        ),
      ),
    );
  }
}

/// ورقة إنشاء/تعديل مشروع — تُعيد المعرّف عند الحفظ
Future<String?> editProject(BuildContext context, AppState s, Map<String, dynamic>? p) async {
  final st = WStore(s);
  final titleC = TextEditingController(text: '${p?['title'] ?? ''}');
  final logC = TextEditingController(text: '${p?['logline'] ?? ''}');
  final synC = TextEditingController(text: '${p?['synopsis'] ?? ''}');
  final targetC = TextEditingController(text: p == null ? '50000' : '${intOf(p['target'])}');
  var genre = '${p?['genre'] ?? 'novel'}';
  var status = '${p?['status'] ?? 'idea'}';
  var emoji = '${p?['emoji'] ?? '📖'}';
  var color = intOf(p?['color'], 8);
  var deadline = parseDk(p?['deadline'] as String?);
  String? result;
  await lifeSheet<void>(
    context,
    p == null ? t('مشروع جديد', 'مشروع جديد', 'New project') : t('عدّل المشروع', 'تعديل المشروع', 'Edit project'),
    (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      wField(titleC, t('عنوان القصة', 'عنوان القصة', 'Story title')),
      wLabel(t('النوع', 'النوع الأدبي', 'Genre')),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final g in wGenres) PickChip(g.label, genre == g.key, () => set(() => genre = g.key), color: g.color),
      ]),
      const SizedBox(height: 12),
      wField(logC, t('الفكرة في سطر', 'الفكرة في سطر (Logline)', 'Logline'), lines: 2),
      wField(synC, t('الملخّص', 'الملخص', 'Synopsis'), lines: 6),
      NumField(t('عدد الكلمات المستهدف', 'عدد الكلمات المستهدف', 'Target word count'), targetC, decimal: false),
      LifeDateButton(
        label: t('آخر موعد', 'الموعد النهائي', 'Deadline'),
        value: deadline,
        clearable: true,
        color: SD.purple,
        onPick: (d) => set(() => deadline = d),
      ),
      if (deadline != null)
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(onPressed: () => set(() => deadline = null), child: Text(t('شيل الموعد', 'إزالة الموعد', 'Clear deadline'))),
        ),
      wLabel(t('الحالة', 'الحالة', 'Status')),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final g in wProjStatus) PickChip(g.label, status == g.key, () => set(() => status = g.key), color: g.color),
      ]),
      wLabel(t('الغلاف', 'الغلاف', 'Cover')),
      Wrap(spacing: 4, runSpacing: 4, children: [
        for (final e in wEmojis)
          InkWell(
            onTap: () => set(() => emoji = e),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: emoji == e ? SD.gold : Colors.transparent, width: 2),
              ),
              child: Text(e, style: const TextStyle(fontSize: 22)),
            ),
          ),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < lifePalette.length; i++)
          GestureDetector(
            onTap: () => set(() => color = i),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: lifePalette[i],
              child: color == i ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
            ),
          ),
      ]),
      wSheetButtons(
        ctx,
        onDelete: p == null
            ? null
            : () async {
                final ok = await confirmAsk(ctx, t('تمسح المشروع؟', 'حذف المشروع؟', 'Delete project?'),
                    t('حيتمسح كل شي فيهو: الشخصيات والفصول والنصوص.', 'سيُحذف كل محتواه: الشخصيات والفصول والنصوص.', 'Everything in it will be deleted: characters, chapters and texts.'));
                if (!ok) return;
                st.deleteProject(p['id'] as String);
                if (ctx.mounted) Navigator.pop(ctx);
              },
        onSave: () {
          final title = titleC.text.trim().isEmpty ? t('قصة بدون عنوان', 'قصة بلا عنوان', 'Untitled story') : titleC.text.trim();
          final data = {
            'title': title,
            'genre': genre,
            'status': status,
            'emoji': emoji,
            'color': color,
            'logline': logC.text.trim(),
            'synopsis': synC.text.trim(),
            'target': parseNum(targetC.text).round(),
            'deadline': deadline == null ? null : dk(deadline!),
          };
          if (p == null) {
            final id = newId();
            final l = st.projects
              ..insert(0, {
                'id': id,
                ...data,
                'created': DateTime.now().millisecondsSinceEpoch,
                'chars': [],
                'chapters': [
                  {'id': newId(), 'title': tr('البداية', 'Beginning'), 'scenes': []},
                ],
                'notes': [],
                'beats': [],
              });
            st.saveProjects(l);
            st.currentId = id;
            s.awardDaily('writer_new_project', 10, t('بدأت قصة جديدة', 'بدء قصة جديدة', 'Started a new story'));
            result = id;
          } else {
            st.edit((x) => x.addAll(data), id: p['id'] as String);
            result = p['id'] as String;
          }
          Navigator.pop(ctx);
        },
      ),
    ]),
  );
  return result;
}
