import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'care_common.dart';

const bloodTypes = ['A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−'];

List<(String, String)> get familyRelations => [
      ('me', t('أنا', 'أنا', 'Me')),
      ('spouse', t('الزوج/الزوجة', 'الزوج/الزوجة', 'Spouse')),
      ('father', t('أبوي', 'الأب', 'Father')),
      ('mother', t('أمي', 'الأم', 'Mother')),
      ('son', t('ولدي', 'الابن', 'Son')),
      ('daughter', t('بتي', 'الابنة', 'Daughter')),
      ('grand', t('جدّ/حبوبة', 'الجد/الجدة', 'Grandparent')),
      ('sibling', t('أخ/أخت', 'أخ/أخت', 'Sibling')),
      ('other', t('غيرهم', 'آخر', 'Other')),
    ];

String relationLabel(dynamic id) => familyRelations.firstWhere((r) => r.$1 == id, orElse: () => familyRelations.last).$2;

/// نص «بطاقة الطوارئ» للمشاركة
String emergencyCardText(Map m) {
  final b = StringBuffer('🆘 ${t('بطاقة طوارئ صحية', 'بطاقة طوارئ صحية', 'Medical emergency card')}\n');
  b.writeln('${tr('الاسم', 'Name')}: ${m['name']}');
  final birth = cParse(m['birth']);
  if (birth != null) b.writeln('${t('العمر', 'العمر', 'Age')}: ${ageYears(birth)} (${cDate(birth)})');
  void line(String label, dynamic v) {
    if (cStr(v).trim().isNotEmpty) b.writeln('$label: ${cStr(v).trim()}');
  }

  line(t('فصيلة الدم', 'فصيلة الدم', 'Blood type'), m['blood']);
  line(t('الحساسية', 'الحساسية', 'Allergies'), m['allergies']);
  line(t('أمراض مزمنة', 'أمراض مزمنة', 'Chronic conditions'), m['chronic']);
  final meds = cList(m['meds']);
  if (meds.isNotEmpty) {
    b.writeln('${t('الأدوية', 'الأدوية', 'Medicines')}:');
    for (final x in meds) {
      b.writeln('  • ${x['n']}${cStr(x['d']).isEmpty ? '' : ' — ${x['d']}'}');
    }
  }
  if (cStr(m['emName']).isNotEmpty || cStr(m['emPhone']).isNotEmpty) {
    b.writeln('${t('للطوارئ اتصل', 'جهة اتصال للطوارئ', 'Emergency contact')}: ${cStr(m['emName'])} ${cStr(m['emPhone'])}'.trimRight());
  }
  if (cStr(m['doctor']).isNotEmpty || cStr(m['doctorPhone']).isNotEmpty) {
    b.writeln('${t('الدكتور', 'الطبيب', 'Doctor')}: ${cStr(m['doctor'])} ${cStr(m['doctorPhone'])}'.trimRight());
  }
  line(t('رقم التأمين', 'رقم التأمين', 'Insurance no.'), m['insurance']);
  line(t('ملاحظات', 'ملاحظات', 'Notes'), m['notes']);
  return b.toString().trim();
}

class FamilyHealthTool extends StatefulWidget {
  const FamilyHealthTool({super.key});
  @override
  State<FamilyHealthTool> createState() => _FamilyHealthToolState();
}

class _FamilyHealthToolState extends State<FamilyHealthTool> {
  bool _unlocked = false;
  String? _open;

  List<Map<String, dynamic>> _list(AppState s) => cList(s.getData<List>('family_health_list'));
  bool _locked(AppState s) => s.getData<bool>('family_health_lock') == true && s.pinHash != null;

  Future<void> _edit(AppState s, [Map<String, dynamic>? m]) async {
    final r = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MemberEditor(initial: m),
    );
    if (r == null || !mounted) return;
    final l = _list(s);
    final i = l.indexWhere((x) => x['id'] == r['id']);
    if (i >= 0) {
      l[i] = r;
    } else {
      l.add(r);
      s.award(5, t('ضفت سجل صحي', 'إضافة سجل صحي', 'Added a health record'));
    }
    s.setData('family_health_list', l);
    setState(() => _open = r['id']);
  }

  Future<void> _delete(AppState s, Map m) async {
    if (!await confirmDelete(context, cStr(m['name']))) return;
    s.setData('family_health_list', _list(s)..removeWhere((x) => x['id'] == m['id']));
    setState(() => _open = null);
  }

  void _card(Map m) {
    showDialog(context: context, builder: (_) => Dialog.fullscreen(child: _EmergencyCard(m)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (_locked(s) && !_unlocked) {
      return ToolList(children: [
        SCard(
          title: t('السجل مقفول', 'السجل مقفل', 'Record locked'),
          icon: Icons.lock_rounded,
          color: SD.henna,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t('السجل الصحي محمي برمز قفل التطبيق.', 'السجل الصحي محمي برمز قفل التطبيق.', 'The health record is protected by the app PIN.')),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                if (await askAppPin(context, s)) setState(() => _unlocked = true);
              },
              icon: const Icon(Icons.lock_open_rounded),
              label: Text(t('افتح', 'فتح', 'Unlock')),
            ),
          ]),
        ),
      ]);
    }
    final list = _list(s);
    final withAllergy = list.where((m) => cStr(m['allergies']).trim().isNotEmpty).length;
    final withChronic = list.where((m) => cStr(m['chronic']).trim().isNotEmpty).length;
    final medsN = list.fold<int>(0, (a, m) => a + cList(m['meds']).length);
    final open = list.where((m) => m['id'] == _open).firstOrNull;

    return ToolList(children: [
      ResultHero(
        label: t('السجل الصحي للأسرة', 'السجل الصحي للأسرة', 'Family health record'),
        value: '${list.length}',
        sub: t('فرد مسجّل — كل البيانات في تلفونك بس', 'فرد مسجل — جميع البيانات على هاتفك فقط', 'members — all data stays on your phone'),
        colors: const [Color(0xFFB4492D), Color(0xFF5A3418), Color(0xFF3A1F0C)],
      ),
      StatGrid([
        StatChip('$withAllergy', t('عندهم حساسية', 'لديهم حساسية', 'With allergies'), color: SD.red, icon: Icons.warning_rounded),
        StatChip('$withChronic', t('أمراض مزمنة', 'أمراض مزمنة', 'Chronic'), color: SD.orange, icon: Icons.monitor_heart_rounded),
        StatChip('$medsN', t('دواء مسجّل', 'دواء مسجل', 'Medicines'), color: SD.teal, icon: Icons.medication_rounded),
      ]),
      const SizedBox(height: 12),
      if (open != null) _detail(s, open),
      SCard(
        title: t('أفراد الأسرة', 'أفراد الأسرة', 'Family members'),
        icon: Icons.family_restroom_rounded,
        color: SD.henna,
        trailing: IconButton(tooltip: t('ضيف', 'إضافة', 'Add'), onPressed: () => _edit(s), icon: const Icon(Icons.person_add_alt_1_rounded)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (list.isEmpty) ...[
            Text(t('ضيف نفسك وأفراد أسرتك: فصيلة الدم، الحساسية، الأدوية ورقم الطوارئ.', 'أضف نفسك وأفراد أسرتك: فصيلة الدم، الحساسية، الأدوية ورقم الطوارئ.',
                'Add yourself and your family: blood type, allergies, medicines and emergency contact.')),
            const SizedBox(height: 10),
            FilledButton.icon(onPressed: () => _edit(s), icon: const Icon(Icons.add_rounded), label: Text(t('ضيف فرد', 'إضافة فرد', 'Add member'))),
          ],
          for (final m in list)
            CTile(
              icon: Icons.person_rounded,
              color: m['id'] == _open ? SD.gold : SD.henna,
              title: cStr(m['name']),
              sub: [
                relationLabel(m['rel']),
                if (cParse(m['birth']) != null) '${ageYears(cParse(m['birth'])!)} ${t('سنة', 'سنة', 'y')}',
                if (cStr(m['allergies']).isNotEmpty) '⚠ ${cStr(m['allergies'])}',
              ].join(' • '),
              badge: cStr(m['blood']).isEmpty ? null : '🩸 ${m['blood']}',
              badgeColor: SD.red,
              onTap: () => setState(() => _open = _open == m['id'] ? null : m['id']),
              actions: [IconButton(tooltip: t('بطاقة الطوارئ', 'بطاقة الطوارئ', 'Emergency card'), onPressed: () => _card(m), icon: const Icon(Icons.badge_rounded))],
            ),
        ]),
      ),
      SCard(
        title: t('الخصوصية والقفل', 'الخصوصية والقفل', 'Privacy & lock'),
        icon: Icons.shield_rounded,
        color: SD.indigo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: s.getData<bool>('family_health_lock') == true,
            onChanged: s.pinHash == null
                ? null
                : (v) async {
                    if (!v && !await askAppPin(context, s)) return;
                    s.setData('family_health_lock', v);
                    setState(() => _unlocked = true);
                  },
            title: Text(t('اقفل السجل برمز التطبيق', 'قفل السجل برمز التطبيق', 'Lock with the app PIN')),
            subtitle: Text(s.pinHash == null
                ? t('اعمل رمز قفل من «الضبط» أول', 'أنشئ رمز قفل من «الإعدادات» أولًا', 'Set an app PIN in Settings first')
                : t('بيطلب الرمز كل ما تفتح الأداة', 'يُطلب الرمز عند كل فتح للأداة', 'Asks for the PIN each time you open the tool')),
          ),
          NoteBox(
            t('بياناتك الصحية محفوظة في تلفونك بس — ما بتترفع لأي سيرفر. خلي بالك لما تشارك البطاقة.', 'بياناتك الصحية محفوظة على هاتفك فقط ولا تُرفع إلى أي خادم. انتبه عند مشاركة البطاقة.',
                'Your health data stays on this phone only — never uploaded. Be careful when sharing the card.'),
            kind: NoteKind.tip,
          ),
        ]),
      ),
      NoteBox(
        t('السجل للتنظيم بس وما بغني عن ملفك في المستشفى أو كلام الدكتور.', 'السجل للتنظيم فقط ولا يغني عن ملفك الطبي أو استشارة الطبيب.',
            'For organisation only — not a replacement for your medical file or your doctor.'),
      ),
    ]);
  }

  Widget _detail(AppState s, Map<String, dynamic> m) {
    final birth = cParse(m['birth']);
    final meds = cList(m['meds']);
    return SCard(
      title: cStr(m['name']),
      icon: Icons.assignment_ind_rounded,
      color: SD.gold,
      trailing: IconButton(tooltip: t('قفّل', 'إغلاق', 'Close'), onPressed: () => setState(() => _open = null), icon: const Icon(Icons.close_rounded)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InfoRow(t('القرابة', 'صلة القرابة', 'Relation'), relationLabel(m['rel']), icon: Icons.people_rounded),
        if (birth != null) InfoRow(t('العمر', 'العمر', 'Age'), '${ageYears(birth)} ${t('سنة', 'سنة', 'years')}', hint: cDate(birth), icon: Icons.cake_rounded),
        InfoRow(t('فصيلة الدم', 'فصيلة الدم', 'Blood type'), cStr(m['blood']).isEmpty ? '—' : cStr(m['blood']), icon: Icons.bloodtype_rounded, valueColor: SD.red),
        InfoRow(t('الحساسية', 'الحساسية', 'Allergies'), cStr(m['allergies']).isEmpty ? '—' : cStr(m['allergies']), icon: Icons.warning_rounded, valueColor: SD.red),
        InfoRow(t('أمراض مزمنة', 'أمراض مزمنة', 'Chronic conditions'), cStr(m['chronic']).isEmpty ? '—' : cStr(m['chronic']), icon: Icons.monitor_heart_rounded),
        for (final x in meds) InfoRow('💊 ${x['n']}', cStr(x['d']).isEmpty ? '—' : cStr(x['d'])),
        if (cStr(m['doctor']).isNotEmpty || cStr(m['doctorPhone']).isNotEmpty)
          _phoneRow(t('الدكتور', 'الطبيب', 'Doctor'), cStr(m['doctor']), cStr(m['doctorPhone']), Icons.medical_services_rounded),
        if (cStr(m['emName']).isNotEmpty || cStr(m['emPhone']).isNotEmpty)
          _phoneRow(t('للطوارئ', 'للطوارئ', 'Emergency contact'), cStr(m['emName']), cStr(m['emPhone']), Icons.contact_emergency_rounded),
        if (cStr(m['insurance']).isNotEmpty) InfoRow(t('رقم التأمين', 'رقم التأمين', 'Insurance no.'), cStr(m['insurance']), icon: Icons.credit_card_rounded),
        if (cStr(m['notes']).isNotEmpty) InfoRow(t('ملاحظات', 'ملاحظات', 'Notes'), cStr(m['notes']), icon: Icons.notes_rounded),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(onPressed: () => _card(m), icon: const Icon(Icons.badge_rounded), label: Text(t('بطاقة الطوارئ', 'بطاقة الطوارئ', 'Emergency card'))),
          OutlinedButton.icon(onPressed: () => _edit(s, m), icon: const Icon(Icons.edit_rounded), label: Text(t('عدّل', 'تعديل', 'Edit'))),
          OutlinedButton.icon(onPressed: () => _delete(s, m), icon: const Icon(Icons.delete_rounded), label: Text(t('امسح', 'حذف', 'Delete'))),
        ]),
      ]),
    );
  }

  Widget _phoneRow(String label, String name, String phone, IconData icon) => Row(children: [
        Expanded(child: InfoRow(label, name.isEmpty ? phone : name, hint: name.isEmpty ? null : phone, icon: icon)),
        if (phone.isNotEmpty) IconButton(tooltip: tr('اتصل', 'Call'), onPressed: () => callNumber(phone), icon: const Icon(Icons.call_rounded, color: SD.green)),
      ]);
}

/// بطاقة طوارئ بخط كبير
class _EmergencyCard extends StatelessWidget {
  final Map m;
  const _EmergencyCard(this.m);

  @override
  Widget build(BuildContext context) {
    final birth = cParse(m['birth']);
    final meds = cList(m['meds']);
    Widget big(String label, String value, {Color? color}) => value.trim().isEmpty
        ? const SizedBox()
        : Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.3, color: color == null ? null : readable(context, color))),
            ]),
          );
    return Scaffold(
      appBar: AppBar(
        title: Text(t('بطاقة الطوارئ', 'بطاقة الطوارئ', 'Emergency card'), maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: t('شارك', 'مشاركة', 'Share'),
            onPressed: () => SharePlus.instance.share(ShareParams(text: emergencyCardText(m))),
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: SD.red.withValues(alpha: .12), borderRadius: BorderRadius.circular(20), border: Border.all(color: SD.red, width: 2)),
          child: Row(children: [
            const Icon(Icons.emergency_rounded, color: SD.red, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cStr(m['name']), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                if (birth != null) Text('${ageYears(birth)} ${t('سنة', 'سنة', 'years')} — ${cDate(birth)}', style: const TextStyle(fontSize: 17)),
              ]),
            ),
            if (cStr(m['blood']).isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: SD.red, borderRadius: BorderRadius.circular(14)),
                child: Text(cStr(m['blood']), textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              ),
          ]),
        ),
        const SizedBox(height: 18),
        big(t('⚠ الحساسية', '⚠ الحساسية', '⚠ Allergies'), cStr(m['allergies']), color: SD.red),
        big(t('أمراض مزمنة', 'أمراض مزمنة', 'Chronic conditions'), cStr(m['chronic'])),
        big(t('الأدوية الحالية', 'الأدوية الحالية', 'Current medicines'), meds.map((x) => '• ${x['n']}${cStr(x['d']).isEmpty ? '' : ' — ${x['d']}'}').join('\n')),
        big(t('للطوارئ اتصل على', 'جهة اتصال للطوارئ', 'Emergency contact'), '${cStr(m['emName'])}\n${cStr(m['emPhone'])}'.trim()),
        if (cStr(m['emPhone']).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: SD.green, foregroundColor: Colors.white),
              onPressed: () => callNumber(cStr(m['emPhone'])),
              icon: const Icon(Icons.call_rounded),
              label: Text(tr('اتصل', 'Call')),
            ),
          ),
        big(t('الدكتور', 'الطبيب', 'Doctor'), '${cStr(m['doctor'])}\n${cStr(m['doctorPhone'])}'.trim()),
        big(t('رقم التأمين', 'رقم التأمين', 'Insurance no.'), cStr(m['insurance'])),
        big(t('ملاحظات', 'ملاحظات', 'Notes'), cStr(m['notes'])),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded), label: Text(t('قفّل', 'إغلاق', 'Close'))),
      ]),
    );
  }
}

class _MemberEditor extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _MemberEditor({this.initial});
  @override
  State<_MemberEditor> createState() => _MemberEditorState();
}

class _MemberEditorState extends State<_MemberEditor> {
  late final Map<String, TextEditingController> _c = {
    for (final k in ['name', 'allergies', 'chronic', 'doctor', 'doctorPhone', 'emName', 'emPhone', 'insurance', 'notes']) k: TextEditingController(text: cStr(widget.initial?[k])),
  };
  late final List<(TextEditingController, TextEditingController)> _meds = [
    for (final x in cList(widget.initial?['meds'])) (TextEditingController(text: cStr(x['n'])), TextEditingController(text: cStr(x['d']))),
  ];
  late String _rel = cStr(widget.initial?['rel']).isEmpty ? 'me' : cStr(widget.initial?['rel']);
  late String _blood = cStr(widget.initial?['blood']);
  late DateTime? _birth = cParse(widget.initial?['birth']);

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    for (final m in _meds) {
      m.$1.dispose();
      m.$2.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(widget.initial == null ? t('فرد جديد', 'فرد جديد', 'New member') : t('تعديل', 'تعديل', 'Edit'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            CField(tr('الاسم', 'Name'), _c['name']!, icon: Icons.person_rounded),
            DropdownButtonFormField<String>(
              initialValue: _rel,
              isExpanded: true,
              decoration: InputDecoration(labelText: t('القرابة', 'صلة القرابة', 'Relation')),
              items: [for (final r in familyRelations) DropdownMenuItem(value: r.$1, child: Text(r.$2, maxLines: 1, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => _rel = v ?? _rel),
            ),
            const SizedBox(height: 10),
            DateButton(label: t('تاريخ الميلاد', 'تاريخ الميلاد', 'Birth date'), value: _birth, last: cToday(), onChanged: (v) => setState(() => _birth = v)),
            Text(t('فصيلة الدم', 'فصيلة الدم', 'Blood type'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final b in [...bloodTypes, ''])
                ChoiceChip(
                  label: Text(b.isEmpty ? t('ما معروفة', 'غير معروفة', 'Unknown') : b, textDirection: b.isEmpty ? null : TextDirection.ltr),
                  selected: _blood == b,
                  onSelected: (_) => setState(() => _blood = b),
                ),
            ]),
            const SizedBox(height: 12),
            CField(t('الحساسية (أدوية، أكل…)', 'الحساسية (أدوية، طعام…)', 'Allergies (drugs, food…)'), _c['allergies']!, maxLines: 2, icon: Icons.warning_rounded,
                hint: t('مثلًا: بنسلين، فول سوداني', 'مثلًا: البنسلين، الفول السوداني', 'e.g. penicillin, peanuts')),
            CField(t('أمراض مزمنة', 'أمراض مزمنة', 'Chronic conditions'), _c['chronic']!, maxLines: 2, icon: Icons.monitor_heart_rounded,
                hint: t('مثلًا: سكري، ضغط، أزمة', 'مثلًا: السكري، الضغط، الربو', 'e.g. diabetes, hypertension, asthma')),
            Row(children: [
              Expanded(child: Text(t('الأدوية الحالية', 'الأدوية الحالية', 'Current medicines'), style: const TextStyle(fontWeight: FontWeight.w700))),
              TextButton.icon(
                onPressed: () => setState(() => _meds.add((TextEditingController(), TextEditingController()))),
                icon: const Icon(Icons.add_rounded),
                label: Text(t('دواء', 'دواء', 'Medicine')),
              ),
            ]),
            for (var i = 0; i < _meds.length; i++)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: CField(tr('الدواء', 'Medicine'), _meds[i].$1)),
                const SizedBox(width: 6),
                Expanded(flex: 2, child: CField(t('الجرعة', 'الجرعة', 'Dose'), _meds[i].$2)),
                IconButton(
                  onPressed: () => setState(() {
                    final x = _meds.removeAt(i);
                    x.$1.dispose();
                    x.$2.dispose();
                  }),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
              ]),
            const SizedBox(height: 6),
            CField(t('اسم الدكتور', 'اسم الطبيب', 'Doctor name'), _c['doctor']!, icon: Icons.medical_services_rounded),
            CField(t('تلفون الدكتور', 'هاتف الطبيب', 'Doctor phone'), _c['doctorPhone']!, keyboard: TextInputType.phone, ltr: true, icon: Icons.phone_rounded),
            CField(t('اسم زول للطوارئ', 'جهة اتصال للطوارئ', 'Emergency contact name'), _c['emName']!, icon: Icons.contact_emergency_rounded),
            CField(t('رقمو', 'رقم جهة الطوارئ', 'Emergency contact phone'), _c['emPhone']!, keyboard: TextInputType.phone, ltr: true, icon: Icons.phone_rounded),
            CField(t('رقم التأمين', 'رقم التأمين الصحي', 'Insurance number'), _c['insurance']!, ltr: true, icon: Icons.credit_card_rounded),
            CField(t('ملاحظات', 'ملاحظات', 'Notes'), _c['notes']!, maxLines: 3, icon: Icons.notes_rounded),
            FilledButton.icon(
              onPressed: () {
                final name = _c['name']!.text.trim();
                if (name.isEmpty) {
                  toast(t('أكتب الاسم', 'اكتب الاسم', 'Enter a name'));
                  return;
                }
                Navigator.pop(context, {
                  'id': widget.initial?['id'] ?? cId(),
                  for (final e in _c.entries) e.key: e.value.text.trim(),
                  'rel': _rel,
                  'blood': _blood,
                  'birth': _birth == null ? null : cKey(_birth!),
                  'meds': [
                    for (final x in _meds)
                      if (x.$1.text.trim().isNotEmpty) {'n': x.$1.text.trim(), 'd': x.$2.text.trim()},
                  ],
                });
              },
              icon: const Icon(Icons.save_rounded),
              label: Text(t('احفظ', 'حفظ', 'Save')),
            ),
          ]),
        ),
      );
}
