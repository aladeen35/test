import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../life/life_common.dart' show mapList, intOf, newId, undoSnack, lifeSheet, ColorDots, EmptyHint, palette, lifePalette;
import 'extra_common.dart';

/// عدد الكلمات
int wordCount(String s) => s.trim().isEmpty ? 0 : s.trim().split(RegExp(r'\s+')).length;

class NotesTool extends StatefulWidget {
  const NotesTool({super.key});
  @override
  State<NotesTool> createState() => _NotesToolState();
}

class _NotesToolState extends State<NotesTool> {
  final _q = TextEditingController();
  int? _color;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _list(AppState s) => mapList(s.getData<List>('notes_list'));
  void _save(AppState s, List<Map<String, dynamic>> l) => s.setData('notes_list', l);

  List<Map<String, dynamic>> _items(Map n) => mapList(n['items']);

  String _plain(Map n) {
    if (n['check'] == true) {
      return _items(n).map((e) => '${e['d'] == true ? '☑' : '☐'} ${e['t'] ?? ''}').join('\n');
    }
    return '${n['body'] ?? ''}';
  }

  int _words(Map n) => wordCount('${n['title'] ?? ''}') + (n['check'] == true ? _items(n).fold(0, (a, e) => a + wordCount('${e['t'] ?? ''}')) : wordCount('${n['body'] ?? ''}'));

  void _upsert(Map<String, dynamic> n) {
    final s = context.read<AppState>();
    final l = _list(s);
    final i = l.indexWhere((x) => x['id'] == n['id']);
    n['u'] = DateTime.now().millisecondsSinceEpoch;
    if (i >= 0) {
      l[i] = n;
    } else {
      l.add(n);
      s.awardDaily('notes', 2, tr('ملاحظة جديدة', 'New note'));
    }
    _save(s, l);
  }

  void _delete(Map<String, dynamic> n) {
    final s = context.read<AppState>();
    final l = _list(s)..removeWhere((x) => x['id'] == n['id']);
    _save(s, l);
    undoSnack(t('الملاحظة اتمسحت', 'حُذفت الملاحظة', 'Note deleted'), () => _save(s, _list(s)..add(n)));
  }

  void _share(Map n) {
    final title = '${n['title'] ?? ''}'.trim();
    SharePlus.instance.share(ShareParams(text: [if (title.isNotEmpty) '📝 $title', _plain(n)].join('\n\n')));
  }

  Future<void> _edit([Map<String, dynamic>? orig]) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final n = orig == null
        ? <String, dynamic>{'id': newId(), 'title': '', 'body': '', 'color': _color ?? 3, 'pin': false, 'check': false, 'items': <Map>[], 'c': now}
        : Map<String, dynamic>.from(orig);
    final titleC = TextEditingController(text: '${n['title'] ?? ''}');
    final bodyC = TextEditingController(text: '${n['body'] ?? ''}');
    final itemC = TextEditingController();
    var items = _items(n);
    final ok = await lifeSheet<bool>(
      context,
      orig == null ? t('ملاحظة جديدة', 'ملاحظة جديدة', 'New note') : t('عدّل الملاحظة', 'تعديل الملاحظة', 'Edit note'),
      (ctx, set) {
        void addItem() {
          final v = itemC.text.trim();
          if (v.isEmpty) return;
          set(() {
            items.add({'t': v, 'd': false});
            itemC.clear();
          });
        }

        final words = wordCount(titleC.text) + (n['check'] == true ? items.fold(0, (a, e) => a + wordCount('${e['t']}')) : wordCount(bodyC.text));
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: titleC,
            onChanged: (_) => set(() {}),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            decoration: InputDecoration(labelText: t('العنوان', 'العنوان', 'Title')),
          ),
          const SizedBox(height: 10),
          XSeg<bool>([(false, t('نص', 'نص', 'Text')), (true, t('قائمة صحّ', 'قائمة مهام', 'Checklist'))], n['check'] == true, (v) {
            set(() {
              if (v && items.isEmpty && bodyC.text.trim().isNotEmpty) {
                items = [for (final line in bodyC.text.split('\n')) if (line.trim().isNotEmpty) {'t': line.trim(), 'd': false}];
              } else if (!v && bodyC.text.trim().isEmpty && items.isNotEmpty) {
                bodyC.text = items.map((e) => e['t']).join('\n');
              }
              n['check'] = v;
            });
          }),
          const SizedBox(height: 10),
          if (n['check'] != true)
            TextField(
              controller: bodyC,
              minLines: 5,
              maxLines: 14,
              onChanged: (_) => set(() {}),
              decoration: InputDecoration(hintText: t('أكتب هنا…', 'اكتب هنا…', 'Write here…')),
            )
          else ...[
            for (var i = 0; i < items.length; i++)
              Row(children: [
                Checkbox(value: items[i]['d'] == true, onChanged: (v) => set(() => items[i]['d'] = v == true)),
                Expanded(
                  child: Text('${items[i]['t']}',
                      style: TextStyle(decoration: items[i]['d'] == true ? TextDecoration.lineThrough : null)),
                ),
                IconButton(onPressed: () => set(() => items.removeAt(i)), icon: const Icon(Icons.close_rounded, size: 20)),
              ]),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: itemC,
                  onSubmitted: (_) => addItem(),
                  decoration: InputDecoration(isDense: true, hintText: t('بند جديد', 'بند جديد', 'New item')),
                ),
              ),
              IconButton.filled(onPressed: addItem, icon: const Icon(Icons.add_rounded)),
            ]),
          ],
          const SizedBox(height: 12),
          Text(t('اللون', 'اللون', 'Colour'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ColorDots(intOf(n['color'], 3), (v) => set(() => n['color'] = v)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: n['pin'] == true,
            onChanged: (v) => set(() => n['pin'] = v),
            title: Text(t('ثبّتها فوق', 'تثبيت في الأعلى', 'Pin to top')),
            secondary: const Icon(Icons.push_pin_rounded),
          ),
          Text('${t('عدد الكلمات', 'عدد الكلمات', 'Words')}: $words',
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: .6))),
          const SizedBox(height: 12),
          Row(children: [
            if (orig != null)
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: SD.red),
                  onPressed: () => Navigator.pop(ctx, false),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('امسح', 'حذف', 'Delete'))),
                ),
              ),
            if (orig != null) const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.check_rounded),
                label: Text(t('احفظ', 'حفظ', 'Save')),
              ),
            ),
          ]),
        ]);
      },
    );
    final title = titleC.text.trim(), body = bodyC.text.trimRight();
    titleC.dispose();
    bodyC.dispose();
    itemC.dispose();
    if (!mounted || ok == null) return;
    if (ok == false && orig != null) return _delete(orig);
    n['title'] = title;
    n['body'] = body;
    n['items'] = items;
    final empty = title.isEmpty && (n['check'] == true ? items.isEmpty : body.trim().isEmpty);
    if (empty) {
      if (orig != null) _delete(orig);
      return;
    }
    _upsert(n);
  }

  void _toggleItem(Map<String, dynamic> n, int i) {
    final items = _items(n);
    if (i >= items.length) return;
    items[i]['d'] = items[i]['d'] != true;
    _upsert({...n, 'items': items});
  }

  String _ago(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return t('هسه', 'الآن', 'just now');
    if (diff.inHours < 24 && d.day == DateTime.now().day) return fmtTimeAr(d);
    return fmtDateAr(d, weekday: false);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = _list(s);
    final q = _q.text.trim().toLowerCase();
    final shown = all.where((n) {
      if (_color != null && intOf(n['color'], 3) != _color) return false;
      if (q.isEmpty) return true;
      return '${n['title']} ${_plain(n)}'.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) {
        final pa = a['pin'] == true, pb = b['pin'] == true;
        if (pa != pb) return pa ? -1 : 1;
        return intOf(b['u']).compareTo(intOf(a['u']));
      });
    final pinned = all.where((n) => n['pin'] == true).length;
    final checks = all.where((n) => n['check'] == true).length;
    final words = all.fold(0, (a, n) => a + _words(n));
    final usedColors = {for (final n in all) intOf(n['color'], 3)}.toList()..sort();

    return ToolList(children: [
      StatGrid([
        StatChip('${all.length}', t('ملاحظة', 'ملاحظة', 'Notes'), color: SD.gold, icon: Icons.sticky_note_2_rounded),
        StatChip('$pinned', t('مثبّتة', 'مثبّتة', 'Pinned'), color: SD.henna, icon: Icons.push_pin_rounded),
        StatChip(fmt(words, 0), t('كلمة', 'كلمة', 'Words'), color: SD.nile, icon: Icons.text_fields_rounded),
      ]),
      const SizedBox(height: 12),
      TextField(
        controller: _q,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: t('فتّش في الملاحظات', 'ابحث في الملاحظات', 'Search notes'),
          suffixIcon: _q.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () => setState(_q.clear),
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
      if (usedColors.length > 1) ...[
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: ChoiceChip(label: Text(t('الكل', 'الكل', 'All')), selected: _color == null, onSelected: (_) => setState(() => _color = null)),
            ),
            for (final c in usedColors)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _color = _color == c ? null : c),
                  child: Container(
                    width: 36,
                    decoration: BoxDecoration(
                      color: lifePalette[c % lifePalette.length],
                      shape: BoxShape.circle,
                      border: Border.all(color: _color == c ? SD.goldLight : Colors.transparent, width: 3),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ],
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.note_add_rounded), label: Text(t('ملاحظة جديدة', 'ملاحظة جديدة', 'New note'))),
      const SizedBox(height: 14),
      if (shown.isEmpty)
        EmptyHint(
          all.isEmpty ? Icons.sticky_note_2_outlined : Icons.search_off_rounded,
          all.isEmpty
              ? t('ما عندك ملاحظات لسه — أكتب فكرة، رقم تلفون، أو قائمة حاجات', 'لا توجد ملاحظات بعد — اكتب فكرة أو رقمًا أو قائمة', 'No notes yet — jot an idea, a number or a list')
              : t('ما لقينا حاجة', 'لا نتائج', 'Nothing found'),
        ),
      for (final n in shown) _card(n),
      if (checks > 0)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${t('قوائم صحّ', 'قوائم مهام', 'Checklists')}: $checks',
              textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55))),
        ),
    ]);
  }

  Widget _card(Map<String, dynamic> n) {
    final c = palette(intOf(n['color'], 3));
    final title = '${n['title'] ?? ''}'.trim();
    final isCheck = n['check'] == true;
    final items = _items(n);
    final done = items.where((e) => e['d'] == true).length;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .6);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.withValues(alpha: .35)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 5, color: c),
            Expanded(child: _cardBody(n, c, title, isCheck, items, done, muted)),
          ]),
        ),
      ),
    );
  }

  Widget _cardBody(Map<String, dynamic> n, Color c, String title, bool isCheck, List<Map<String, dynamic>> items, int done, Color muted) {
    return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _edit(n),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              if (n['pin'] == true) ...[Icon(Icons.push_pin_rounded, size: 16, color: readable(context, c)), const SizedBox(width: 4)],
              Expanded(
                child: Text(title.isEmpty ? t('بدون عنوان', 'بلا عنوان', 'Untitled') : title,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (v) => switch (v) {
                  'pin' => _upsert({...n, 'pin': n['pin'] != true}),
                  'share' => _share(n),
                  _ => _delete(n),
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'pin', child: Text(n['pin'] == true ? t('فك التثبيت', 'إلغاء التثبيت', 'Unpin') : t('ثبّت', 'تثبيت', 'Pin'))),
                  PopupMenuItem(value: 'share', child: Text(t('شارك', 'مشاركة', 'Share'))),
                  PopupMenuItem(value: 'del', child: Text(t('امسح', 'حذف', 'Delete'))),
                ],
              ),
            ]),
            if (!isCheck && '${n['body'] ?? ''}'.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Text('${n['body']}'.trim(), maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.45)),
              ),
            if (isCheck) ...[
              for (var i = 0; i < items.length && i < 5; i++)
                InkWell(
                  onTap: () => _toggleItem(n, i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      Icon(items[i]['d'] == true ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: 20, color: readable(context, c)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('${items[i]['t']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(decoration: items[i]['d'] == true ? TextDecoration.lineThrough : null, color: items[i]['d'] == true ? muted : null)),
                      ),
                    ]),
                  ),
                ),
              if (items.length > 5) Text('+${items.length - 5}', style: TextStyle(color: muted)),
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 4, end: 8),
                  child: XBar(t('تم', 'المنجز', 'Done'), done / items.length, '$done/${items.length}', color: c),
                ),
            ],
            const SizedBox(height: 4),
            Text('${_ago(intOf(n['u'], intOf(n['c'])))} • ${_words(n)} ${t('كلمة', 'كلمة', 'words')}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: muted)),
          ]),
        ),
      );
  }
}
