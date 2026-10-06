import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/calendars.dart';
import '../life/life_common.dart';
import 'doc_notify.dart';

/// نوع ورقة رسمية
class DocType {
  final String key, emoji, sd, ar, en;
  final IconData icon;
  const DocType(this.key, this.emoji, this.sd, this.ar, this.en, this.icon);
  String get name => t(sd, ar, en);
}

const docTypes = [
  DocType('passport', '🛂', 'الجواز', 'جواز السفر', 'Passport', Icons.menu_book_rounded),
  DocType('iqama', '🪪', 'الإقامة', 'الإقامة', 'Residence permit', Icons.badge_rounded),
  DocType('visa', '✈️', 'الفيزا', 'التأشيرة', 'Visa', Icons.flight_rounded),
  DocType('license', '🚗', 'الرخصة', 'رخصة القيادة', 'Driving license', Icons.directions_car_rounded),
  DocType('nid', '🆔', 'الرقم الوطني', 'البطاقة الوطنية', 'National ID', Icons.perm_identity_rounded),
  DocType('insurance', '🏥', 'التأمين الصحي', 'التأمين الصحي', 'Health insurance', Icons.health_and_safety_rounded),
  DocType('carreg', '📋', 'استمارة العربية', 'استمارة المركبة', 'Car registration', Icons.description_rounded),
  DocType('custom', '📄', 'ورقة تانية', 'مستند آخر', 'Other document', Icons.folder_rounded),
];

DocType docType(String? k) => docTypes.firstWhere((d) => d.key == k, orElse: () => docTypes.last);

/// اسم الورقة المعروض (النوع أو الاسم المخصص + صاحبها)
String docTitle(Map d) {
  final ty = docType(d['type'] as String?);
  final label = (d['label'] as String? ?? '').trim();
  final base = label.isNotEmpty ? label : ty.name;
  final who = (d['person'] as String? ?? '').trim();
  return who.isEmpty ? base : '$base — $who';
}

class DocumentsTool extends StatefulWidget {
  const DocumentsTool({super.key});
  @override
  State<DocumentsTool> createState() => _DocumentsToolState();
}

class _DocumentsToolState extends State<DocumentsTool> {
  String? _person;

  List<Map<String, dynamic>> _list(AppState s) => mapList(s.getData<List>('documents_list'));
  Map<String, dynamic> _cfg(AppState s) => Map<String, dynamic>.from(s.getData<Map>('documents_cfg') ?? const {});
  bool _notify(AppState s) => _cfg(s)['notify'] != false;

  void _save(AppState s, List<Map<String, dynamic>> l) {
    s.setData('documents_list', l);
    DocNotifications.reschedule(s, docTitle);
  }

  int _daysLeft(Map d) {
    final e = parseDk(d['exp'] as String?);
    return e == null ? 99999 : dayDiff(todayPlace(), e);
  }

  Color _color(int left) => left < 0 ? SD.red : left < 30 ? SD.gold : SD.green;

  String _countdown(int left) {
    if (left < 0) return t('منتهي من ${-left} يوم', 'منتهٍ منذ ${-left} يوم', 'Expired ${-left} days ago');
    if (left == 0) return t('بينتهي الليلة!', 'ينتهي اليوم!', 'Expires today!');
    if (left < 60) return t('باقي $left يوم', 'متبقٍ $left يوم', '$left days left');
    final m = left ~/ 30;
    return t('باقي حوالي $m شهر ($left يوم)', 'متبقٍ نحو $m شهر ($left يوم)', '~$m months left ($left days)');
  }

  Future<void> _edit([Map<String, dynamic>? d]) async {
    final s = context.read<AppState>();
    final people = {for (final x in _list(s)) (x['person'] as String? ?? '').trim()}..removeWhere((e) => e.isEmpty);
    var type = (d?['type'] as String?) ?? 'passport';
    final labelC = TextEditingController(text: d?['label'] ?? '');
    final personC = TextEditingController(text: d?['person'] ?? '');
    final numC = TextEditingController(text: d?['no'] ?? '');
    final notesC = TextEditingController(text: d?['notes'] ?? '');
    final remindC = TextEditingController(text: '${(d?['remind'] as num?)?.toInt() ?? 30}');
    DateTime? exp = parseDk(d?['exp'] as String?);
    final today = todayPlace();
    final ok = await lifeSheet<bool>(
      context,
      d == null ? t('ورقة جديدة', 'مستند جديد', 'New document') : t('عدّل الورقة', 'تعديل المستند', 'Edit document'),
      (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t('النوع', 'النوع', 'Type'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final ty in docTypes) PickChip('${ty.emoji} ${ty.name}', type == ty.key, () => set(() => type = ty.key), color: SD.nile),
        ]),
        const SizedBox(height: 12),
        if (type == 'custom')
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(controller: labelC, decoration: InputDecoration(labelText: t('اسم الورقة', 'اسم المستند', 'Document name'))),
          ),
        TextField(
            controller: personC,
            decoration: InputDecoration(
                labelText: t('حقت منو؟ (فاضي = أنا)', 'لمن؟ (فارغ = أنا)', 'Whose? (empty = me)'),
                hintText: t('مثلاً: أمي، محمد', 'مثلًا: الوالدة، محمد', 'e.g. Mom, Mohamed'))),
        if (people.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final p in people) ActionChip(label: Text(p, maxLines: 1, overflow: TextOverflow.ellipsis), onPressed: () => set(() => personC.text = p)),
          ]),
        ],
        const SizedBox(height: 10),
        TextField(controller: numC, decoration: InputDecoration(labelText: t('الرقم (اختياري)', 'الرقم (اختياري)', 'Number (optional)'))),
        const SizedBox(height: 12),
        LifeDateButton(
          label: t('تاريخ الانتهاء', 'تاريخ الانتهاء', 'Expiry date'),
          value: exp,
          first: DateTime(today.year - 20),
          last: DateTime(today.year + 30),
          color: SD.nile,
          onPick: (v) => set(() => exp = v),
        ),
        if (exp != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 6, start: 4),
            child: Text('${tr('بالهجري', 'Hijri')}: ${hijriText(exp!, shift: s.hijriShift)}', style: const TextStyle(fontSize: 13)),
          ),
        const SizedBox(height: 12),
        NumField(t('ذكّرني قبل كم يوم؟', 'التذكير قبل كم يوم؟', 'Remind me how many days before?'), remindC, decimal: false, hint: '30'),
        TextField(
            controller: notesC,
            maxLines: 2,
            decoration: InputDecoration(labelText: t('ملاحظات (مكان التجديد، الرسوم…)', 'ملاحظات (مكان التجديد، الرسوم…)', 'Notes (where to renew, fees…)'))),
        const SizedBox(height: 18),
        Row(children: [
          if (d != null)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: SD.red),
                onPressed: () => Navigator.pop(ctx, false),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(t('امسح', 'حذف', 'Delete'), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          if (d != null) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () {
                if (exp == null) return toast(t('اختار تاريخ الانتهاء', 'اختر تاريخ الانتهاء', 'Pick the expiry date'));
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(t('احفظ', 'حفظ', 'Save'), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ]),
      ]),
    );
    final data = {
      'type': type,
      'label': labelC.text.trim(),
      'person': personC.text.trim(),
      'no': numC.text.trim(),
      'notes': notesC.text.trim(),
      'remind': parseNum(remindC.text, 30).round().clamp(0, 365),
      'exp': exp == null ? null : dk(exp!),
    };
    for (final c in [labelC, personC, numC, notesC, remindC]) {
      c.dispose();
    }
    if (!mounted || ok == null) return;
    final l = _list(s);
    if (ok == false && d != null) {
      final i = l.indexWhere((x) => x['id'] == d['id']);
      if (i < 0) return;
      final removed = l.removeAt(i);
      _save(s, l);
      setState(() {});
      undoSnack(t('اتمسحت الورقة', 'حُذف المستند', 'Document deleted'), () {
        _save(s, _list(s)..add(removed));
        if (mounted) setState(() {});
      });
      return;
    }
    if (d == null) {
      l.add({'id': newId(), ...data});
      s.award(5, tr('إضافة مستند رسمي', 'Added a document'));
      if (_notify(s)) DocNotifications.requestPermission();
    } else {
      final i = l.indexWhere((x) => x['id'] == d['id']);
      if (i >= 0) l[i] = {...l[i], ...data};
    }
    _save(s, l);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = _list(s)..sort((a, b) => _daysLeft(a).compareTo(_daysLeft(b)));
    final people = <String>{for (final x in all) (x['person'] as String? ?? '').trim()};
    final showPeople = people.length > 1;
    final me = t('أنا', 'أنا', 'Me');
    final list = _person == null ? all : all.where((x) => (x['person'] as String? ?? '').trim() == _person).toList();
    final expired = all.where((x) => _daysLeft(x) < 0).length;
    final soon = all.where((x) {
      final l = _daysLeft(x);
      return l >= 0 && l < 30;
    }).length;

    return ToolList(children: [
      if (all.isNotEmpty)
        StatGrid([
          StatChip('$expired', t('منتهية', 'منتهية', 'Expired'), color: SD.red, icon: Icons.error_outline_rounded),
          StatChip('$soon', t('قرّبت', 'قريبة', 'Due soon'), color: SD.gold, icon: Icons.hourglass_bottom_rounded),
          StatChip('${all.length - expired - soon}', t('سليمة', 'سارية', 'Valid'), color: SD.green, icon: Icons.verified_rounded),
        ]),
      if (all.isNotEmpty) const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: Text(t('أضف ورقة', 'إضافة مستند', 'Add document'), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      const SizedBox(height: 12),
      if (showPeople)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            PickChip(t('الكل', 'الكل', 'All'), _person == null, () => setState(() => _person = null), color: SD.gold),
            for (final p in people) PickChip(p.isEmpty ? me : p, _person == p, () => setState(() => _person = p), color: SD.gold),
          ]),
        ),
      if (all.isEmpty)
        EmptyHint(
            Icons.folder_shared_rounded,
            t('ضيف جوازك وإقامتك ورخصتك عشان نذكّرك قبل ما تنتهي',
                'أضف جوازك وإقامتك ورخصتك لنذكّرك قبل انتهائها', 'Add your passport, residence permit and license to get reminded before they expire')),
      for (final d in list) _tile(context, s, d, me),
      SCard(
        title: t('التنبيهات', 'التنبيهات', 'Reminders'),
        icon: Icons.notifications_active_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _notify(s),
            title: Text(t('ذكّرني قبل الانتهاء', 'ذكّرني قبل الانتهاء', 'Remind me before expiry')),
            subtitle: Text(DocNotifications.supported
                ? t('تنبيه قبل المدة اللي اخترتها، وقبل أسبوع، ويوم الانتهاء', 'تنبيه قبل المدة المختارة، وقبل أسبوع، ويوم الانتهاء',
                    'Alerts before your chosen days, one week before, and on the day')
                : t('التنبيهات شغالة في أندرويد وآيفون بس', 'التنبيهات متاحة على أندرويد وآيفون فقط', 'Notifications work on Android and iOS only')),
            onChanged: (v) async {
              s.setData('documents_cfg', {..._cfg(s), 'notify': v});
              if (v) await DocNotifications.requestPermission();
              await DocNotifications.reschedule(s, docTitle);
            },
          ),
          if (DocNotifications.supported)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () async {
                  await DocNotifications.requestPermission();
                  await DocNotifications.test();
                },
                icon: const Icon(Icons.notifications_rounded),
                label: Text(t('جرّب التنبيه', 'تجربة التنبيه', 'Test notification')),
              ),
            ),
        ]),
      ),
      NoteBox(
          t('التواريخ الهجرية حسابية (أم القرى) — ممكن تفرق يوم. دايماً راجع التاريخ المكتوب في الورقة نفسها.',
              'التواريخ الهجرية حسابية (أم القرى) وقد تختلف بيوم. راجع دائمًا التاريخ المدوّن على المستند.',
              'Hijri dates are calculated (Umm al-Qura) and may differ by a day. Always check the date printed on the document.'),
          kind: NoteKind.tip),
    ]);
  }

  Widget _tile(BuildContext context, AppState s, Map<String, dynamic> d, String me) {
    final ty = docType(d['type'] as String?);
    final left = _daysLeft(d);
    final c = _color(left);
    final rc = readable(context, c);
    final exp = parseDk(d['exp'] as String?);
    final label = (d['label'] as String? ?? '').trim();
    final who = (d['person'] as String? ?? '').trim();
    final notes = (d['notes'] as String? ?? '').trim();
    final no = (d['no'] as String? ?? '').trim();
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .65);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c.withValues(alpha: .55), width: 1.4)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _edit(d),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: c.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)),
              child: Icon(ty.icon, color: rc),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${ty.emoji} ${label.isNotEmpty ? label : ty.name}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                Text('👤 ${who.isEmpty ? me : who}${no.isEmpty ? '' : ' · #$no'}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 12.5)),
                const SizedBox(height: 4),
                Text(_countdown(left), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: rc, fontWeight: FontWeight.w800)),
                if (exp != null) ...[
                  Text(fmtDateAr(exp, weekday: false), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                  Text(hijriText(exp, shift: s.hijriShift), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: muted)),
                ],
                if (notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('📝 $notes', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: muted)),
                  ),
              ]),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 54,
              child: Column(children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(left.abs() > 9999 ? '—' : '${left.abs()}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: rc)),
                ),
                FittedBox(fit: BoxFit.scaleDown, child: Text(tr('يوم', 'days'), style: TextStyle(fontSize: 11, color: rc))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
