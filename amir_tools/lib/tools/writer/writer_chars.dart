import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'writer_common.dart';
import 'writer_data.dart';
import 'writer_paint.dart';

/// تبويب الشخصيات
class CharsTab extends StatefulWidget {
  final Map<String, dynamic> project;
  const CharsTab({super.key, required this.project});
  @override
  State<CharsTab> createState() => _CharsTabState();
}

class _CharsTabState extends State<CharsTab> {
  bool _sd = !isEn, _female = false;
  List<String> _names = [];

  void _gen() => setState(() => _names = [for (var i = 0; i < 5; i++) genName(sudanese: _sd, female: _female)]);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = widget.project;
    final chars = charsOf(p);
    return ToolList(children: [
      SCard(
        title: '${t('الشخصيات', 'الشخصيات', 'Characters')} (${chars.length})',
        icon: Icons.people_alt_rounded,
        color: SD.purple,
        trailing: IconButton(
          tooltip: t('شخصية جديدة', 'شخصية جديدة', 'New character'),
          onPressed: () => editCharacter(context, s, p, null),
          icon: const Icon(Icons.person_add_alt_1_rounded, color: SD.gold),
        ),
        child: chars.isEmpty
            ? Text(t('لسه ما في شخصيات. أضف بطلك الأول!', 'لا توجد شخصيات بعد. أضف بطلك الأول!', 'No characters yet. Add your first hero!'))
            : Column(children: [for (final c in chars) _CharCard(c, p, onTap: () => editCharacter(context, s, p, c))]),
      ),
      if (chars.length >= 2)
        SCard(
          title: t('خريطة العلاقات', 'خريطة العلاقات', 'Relationship map'),
          icon: Icons.hub_rounded,
          color: SD.indigo,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            RelationMap(chars),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
              for (final r in wRelTypes) WTag(r.label, color: r.color),
            ]),
          ]),
        ),
      SCard(
        title: t('مولّد الأسماء', 'مولّد الأسماء', 'Name generator'),
        icon: Icons.casino_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            PickChip(t('سوداني/عربي', 'سوداني/عربي', 'Sudanese/Arabic'), _sd, () => setState(() => _sd = true), color: SD.green),
            PickChip(t('إنجليزي', 'إنجليزي', 'English'), !_sd, () => setState(() => _sd = false), color: SD.nile),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            PickChip(t('ولد', 'ذكر', 'Male'), !_female, () => setState(() => _female = false), color: SD.indigo),
            PickChip(t('بت', 'أنثى', 'Female'), _female, () => setState(() => _female = true), color: SD.pink),
          ]),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: _gen, icon: const Icon(Icons.auto_awesome_rounded), label: Text(t('ولّد أسماء', 'توليد أسماء', 'Generate names'))),
          for (final n in _names)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(n, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(tooltip: t('انسخ', 'نسخ', 'Copy'), onPressed: () => copyText(n), icon: const Icon(Icons.copy_rounded, size: 20)),
                IconButton(
                  tooltip: t('اعملها شخصية', 'إنشاء شخصية', 'Make character'),
                  onPressed: () => editCharacter(context, s, p, null, name: n),
                  icon: const Icon(Icons.person_add_rounded, size: 20),
                ),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

class _CharCard extends StatelessWidget {
  final Map<String, dynamic> c, p;
  final VoidCallback onTap;
  const _CharCard(this.c, this.p, {required this.onTap});
  @override
  Widget build(BuildContext context) {
    final role = wFind(wRoles, c['role']);
    final name = '${c['name'] ?? ''}'.trim();
    final traits = strList(c['traits']);
    final rels = mapList(c['rels']);
    final goal = '${c['goal'] ?? ''}'.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: role.color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: role.color.withValues(alpha: .35)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: role.color,
              child: Text(name.isEmpty ? '?' : name.characters.first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(name.isEmpty ? '—' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                  if ('${c['age'] ?? ''}'.trim().isNotEmpty)
                    Text(' ${c['age']}', maxLines: 1, style: const TextStyle(fontSize: 12)),
                ]),
                const SizedBox(height: 4),
                Wrap(spacing: 4, runSpacing: 4, children: [
                  WTag('${role.emoji} ${roleName(c)}', color: role.color),
                  for (final tr0 in traits.take(4)) WTag(tr0, color: SD.brownLight),
                ]),
                if (goal.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('🎯 $goal', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                ],
                for (final r in rels.take(3))
                  Text(
                    '${wFind(wRelTypes, r['type']).emoji} ${charName(p, r['to'] as String?)}${'${r['note'] ?? ''}'.trim().isEmpty ? '' : ' — ${r['note']}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// ورقة إنشاء/تعديل شخصية
Future<void> editCharacter(BuildContext context, AppState s, Map<String, dynamic> p, Map<String, dynamic>? c, {String? name}) async {
  final st = WStore(s);
  final pid = p['id'] as String;
  final id = (c?['id'] as String?) ?? newId();
  final nameC = TextEditingController(text: name ?? '${c?['name'] ?? ''}');
  final roleC = TextEditingController(text: '${c?['roleC'] ?? ''}');
  final ageC = TextEditingController(text: '${c?['age'] ?? ''}');
  final lookC = TextEditingController(text: '${c?['look'] ?? ''}');
  final backC = TextEditingController(text: '${c?['back'] ?? ''}');
  final goalC = TextEditingController(text: '${c?['goal'] ?? ''}');
  final fearC = TextEditingController(text: '${c?['fear'] ?? ''}');
  final arcC = TextEditingController(text: '${c?['arc'] ?? ''}');
  final voiceC = TextEditingController(text: '${c?['voice'] ?? ''}');
  final traitC = TextEditingController();
  final relNoteC = TextEditingController();
  var role = '${c?['role'] ?? (charsOf(p).isEmpty ? 'hero' : 'minor')}';
  final traits = strList(c?['traits']);
  final rels = mapList(c?['rels']);
  final others = charsOf(p).where((x) => x['id'] != id).toList();
  String? relTo;
  var relType = 'friend';
  var female = false;

  void addTrait(String v, StateSetter set) {
    final x = v.trim();
    if (x.isEmpty || traits.contains(x)) return;
    set(() => traits.add(x));
  }

  await lifeSheet<void>(
    context,
    c == null ? t('شخصية جديدة', 'شخصية جديدة', 'New character') : t('عدّل الشخصية', 'تعديل الشخصية', 'Edit character'),
    (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      wField(
        nameC,
        t('الاسم', 'الاسم', 'Name'),
        suffix: IconButton(
          tooltip: t('اسم عشوائي', 'اسم عشوائي', 'Random name'),
          icon: const Icon(Icons.casino_rounded),
          onPressed: () {
            female = !female;
            nameC.text = genName(sudanese: !isEn, female: female);
          },
        ),
      ),
      wLabel(t('الدور', 'الدور', 'Role')),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final r in wRoles) PickChip(r.label, role == r.key, () => set(() => role = r.key), color: r.color),
      ]),
      if (role == 'custom') ...[const SizedBox(height: 8), wField(roleC, t('اكتب الدور', 'اكتب الدور', 'Custom role'))],
      const SizedBox(height: 10),
      wField(ageC, t('العمر', 'العمر', 'Age')),
      wField(lookC, t('الشكل والمظهر', 'المظهر', 'Appearance'), lines: 3),
      wLabel(t('الصفات', 'السمات الشخصية', 'Personality traits')),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final x in traits) WTag(x, color: SD.purple, onDelete: () => set(() => traits.remove(x))),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(
          child: TextField(
            controller: traitC,
            decoration: InputDecoration(hintText: t('صفة جديدة…', 'سمة جديدة…', 'New trait…'), isDense: true),
            onSubmitted: (v) {
              addTrait(v, set);
              traitC.clear();
            },
          ),
        ),
        IconButton(
          tooltip: t('أضف', 'إضافة', 'Add'),
          onPressed: () {
            addTrait(traitC.text, set);
            traitC.clear();
          },
          icon: const Icon(Icons.add_rounded),
        ),
        IconButton(
          tooltip: t('اقترح صفات', 'اقتراح سمات', 'Suggest traits'),
          onPressed: () {
            for (final x in randomTraits(3)) {
              addTrait(x, set);
            }
          },
          icon: const Icon(Icons.auto_awesome_rounded, color: SD.gold),
        ),
      ]),
      const SizedBox(height: 10),
      wField(backC, t('الخلفية والماضي', 'الخلفية', 'Backstory'), lines: 5),
      wField(goalC, t('هدفو / دافعو', 'الهدف / الدافع', 'Goal / motivation'), lines: 3),
      wField(fearC, t('خوفو / عيبو', 'الخوف / العيب', 'Fear / flaw'), lines: 3),
      wField(arcC, t('تطوّر الشخصية', 'قوس تطور الشخصية', 'Arc notes'), lines: 3),
      wField(voiceC, t('طريقة كلامو', 'أسلوب الكلام', 'Voice / speech style'), lines: 2),
      wLabel(t('العلاقات', 'العلاقات', 'Relationships')),
      for (final r in rels)
        Row(children: [
          Text(wFind(wRelTypes, r['type']).emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${wFind(wRelTypes, r['type']).name} ↔ ${charName(p, r['to'] as String?)}${'${r['note'] ?? ''}'.trim().isEmpty ? '' : ' — ${r['note']}'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(onPressed: () => set(() => rels.remove(r)), icon: const Icon(Icons.close_rounded, size: 18)),
        ]),
      if (others.isEmpty)
        Text(t('أضف شخصيات تانية عشان تربط العلاقات.', 'أضف شخصيات أخرى لربط العلاقات.', 'Add other characters to link relationships.'),
            style: const TextStyle(fontSize: 12.5))
      else ...[
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final o in others)
            PickChip('${o['name'] ?? '?'}', relTo == o['id'], () => set(() => relTo = o['id'] as String), color: SD.nile),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final r in wRelTypes) PickChip(r.label, relType == r.key, () => set(() => relType = r.key), color: r.color),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: TextField(
              controller: relNoteC,
              decoration: InputDecoration(hintText: t('ملاحظة عن العلاقة', 'ملاحظة عن العلاقة', 'Relationship note'), isDense: true),
            ),
          ),
          IconButton(
            tooltip: t('أضف العلاقة', 'إضافة العلاقة', 'Add relationship'),
            onPressed: relTo == null
                ? null
                : () => set(() {
                      rels.add({'to': relTo, 'type': relType, 'note': relNoteC.text.trim()});
                      relNoteC.clear();
                      relTo = null;
                    }),
            icon: const Icon(Icons.add_link_rounded),
          ),
        ]),
      ],
      wSheetButtons(
        ctx,
        onDelete: c == null
            ? null
            : () async {
                final ok = await confirmAsk(ctx, t('تمسح الشخصية؟', 'حذف الشخصية؟', 'Delete character?'), '${c['name'] ?? ''}');
                if (!ok) return;
                st.edit((x) {
                  final l = sub(x, 'chars')..removeWhere((e) => e['id'] == id);
                  for (final o in l) {
                    sub(o, 'rels').removeWhere((r) => r['to'] == id);
                  }
                }, id: pid);
                if (ctx.mounted) Navigator.pop(ctx);
              },
        onSave: () {
          final data = {
            'id': id,
            'name': nameC.text.trim().isEmpty ? t('بدون اسم', 'بلا اسم', 'Unnamed') : nameC.text.trim(),
            'role': role,
            'roleC': roleC.text.trim(),
            'age': ageC.text.trim(),
            'look': lookC.text.trim(),
            'traits': traits,
            'back': backC.text.trim(),
            'goal': goalC.text.trim(),
            'fear': fearC.text.trim(),
            'arc': arcC.text.trim(),
            'voice': voiceC.text.trim(),
            'rels': rels,
          };
          st.edit((x) {
            final l = sub(x, 'chars');
            final i = l.indexWhere((e) => e['id'] == id);
            i < 0 ? l.add(data) : l[i] = data;
          }, id: pid);
          Navigator.pop(ctx);
        },
      ),
    ]),
  );
}
