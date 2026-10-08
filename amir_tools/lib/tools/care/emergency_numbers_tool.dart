import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'care_common.dart';
import 'emergency_data.dart';

class EmergencyNumbersTool extends StatefulWidget {
  const EmergencyNumbersTool({super.key});
  @override
  State<EmergencyNumbersTool> createState() => _EmergencyNumbersToolState();
}

class _EmergencyNumbersToolState extends State<EmergencyNumbersTool> {
  List<Map<String, dynamic>> _custom(AppState s) => cList(s.getData<List>('emergency_numbers_custom'));

  Future<void> _addCustom(AppState s, [Map<String, dynamic>? init]) async {
    final n = TextEditingController(text: cStr(init?['name'])), p = TextEditingController(text: cStr(init?['phone']));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('رقم طوارئ خاص بيك', 'رقم طوارئ خاص', 'Personal emergency number')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          CField(tr('الاسم', 'Name'), n, hint: t('مستشفى الحي، صيدلية 24 ساعة…', 'مستشفى الحي، صيدلية 24 ساعة…', 'Local hospital, 24h pharmacy…')),
          CField(t('الرقم', 'الرقم', 'Number'), p, keyboard: TextInputType.phone, ltr: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t('احفظ', 'حفظ', 'Save'))),
        ],
      ),
    );
    final name = n.text.trim(), phone = p.text.trim();
    n.dispose();
    p.dispose();
    if (ok != true || name.isEmpty || phone.isEmpty) return;
    final l = _custom(s);
    final i = init == null ? -1 : l.indexWhere((x) => x['id'] == init['id']);
    if (i >= 0) {
      l[i] = {'id': init!['id'], 'name': name, 'phone': phone};
    } else {
      l.add({'id': cId(), 'name': name, 'phone': phone});
      s.award(3, t('ضفت رقم طوارئ', 'إضافة رقم طوارئ', 'Added an emergency number'));
    }
    s.setData('emergency_numbers_custom', l);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final placeCode = s.city.country.toUpperCase();
    final override = s.getData<String>('emergency_numbers_country');
    final code = override ?? placeCode;
    final country = emergencyFor(code);
    final custom = _custom(s);
    final first = country?.numbers.first;

    String summary() {
      final b = StringBuffer('🆘 ${t('أرقام الطوارئ', 'أرقام الطوارئ', 'Emergency numbers')}${country == null ? '' : ' — ${country.name}'}\n');
      for (final n in country?.numbers ?? const <EmNumber>[]) {
        b.writeln('${n.number} — ${n.kind.label}${n.note == null ? '' : ' (${n.note})'}');
      }
      for (final c in custom) {
        b.writeln('${c['phone']} — ${c['name']}');
      }
      b.writeln('${t('آخر مراجعة', 'آخر مراجعة', 'Last reviewed')}: $careReviewed — ${t('اتأكد محليًا', 'تحقق محليًا', 'verify locally')}');
      return b.toString().trim();
    }

    return ToolList(children: [
      NoteBox(
        t('الأرقام دي منشورة رسميًا بس ممكن تتغيّر أو تختلف بين المدن — اتأكد منها محليًا وخلّي الأرقام القريبة منك محفوظة.',
            'هذه الأرقام منشورة رسميًا لكنها قد تتغير أو تختلف بين المدن — تحقق منها محليًا واحفظ الأرقام القريبة منك.',
            'These are officially published numbers but they can change or differ by city — verify locally and save the ones near you.'),
        kind: NoteKind.warn,
      ),
      SCard(
        title: t('الدولة', 'الدولة', 'Country'),
        icon: Icons.public_rounded,
        color: SD.nile,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<String>(
            initialValue: country?.code,
            isExpanded: true,
            hint: Text(t('اختار الدولة', 'اختر الدولة', 'Choose a country')),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.flag_rounded)),
            items: [
              for (final c in emergencyCountries)
                DropdownMenuItem(value: c.code, child: Text('${c.code == 'EU' ? '🇪🇺' : flagOf(c.code)} ${c.name}', maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => s.setData('emergency_numbers_country', v),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: Text(
                override == null
                    ? '${t('اتختارت من مكانك', 'اختيرت حسب مكانك', 'Picked from your place')}: ${s.city.name} ${flagOf(placeCode)}'
                    : t('اخترتها بإيدك', 'اختيار يدوي', 'Chosen manually'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65)),
              ),
            ),
            if (override != null)
              TextButton(onPressed: () => s.setData('emergency_numbers_country', null), child: Text(t('حسب مكاني', 'حسب مكاني', 'Use my place'))),
          ]),
        ]),
      ),
      if (country == null)
        NoteBox(
          t('دولتك لسه ما في الجدول. اسأل عن أرقام الطوارئ المحلية وضيفها تحت في «أرقامك».', 'دولتك ليست في الجدول بعد. اسأل عن أرقام الطوارئ المحلية وأضفها بالأسفل في «أرقامك».',
              "Your country isn't in the table yet. Ask for the local emergency numbers and add them below under «Your numbers»."),
          kind: NoteKind.info,
        )
      else ...[
        if (first != null)
          InkWell(
            onTap: () => callNumber(first.number),
            borderRadius: BorderRadius.circular(26),
            child: ResultHero(
              label: '${first.kind.label} — ${country.name}',
              value: first.number,
              sub: '📞 ${t('اضغط عشان تتصل', 'اضغط للاتصال', 'Tap to call')}',
              colors: const [Color(0xFFD21034), Color(0xFF8A1A1A), Color(0xFF3A1F0C)],
            ),
          ),
        SCard(
          title: '${country.code == 'EU' ? '🇪🇺' : flagOf(country.code)} ${country.name}',
          icon: Icons.emergency_rounded,
          color: SD.red,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final n in country.numbers)
              CTile(
                icon: n.kind.icon,
                color: n.kind == EmKind.police ? SD.nile : (n.kind == EmKind.fire ? SD.orange : (n.kind == EmKind.health || n.kind == EmKind.crisis ? SD.teal : SD.red)),
                title: n.kind.label,
                sub: n.note,
                onTap: () => callNumber(n.number),
                actions: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 6),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: SD.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      onPressed: () => callNumber(n.number),
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: Text(n.number, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  IconButton(
                    tooltip: t('الرقم غلط؟', 'الرقم خاطئ؟', 'Wrong number?'),
                    onPressed: () => reportWrong('emergency_numbers', '${country.code} ${n.number} (${n.kind.en})'),
                    icon: const Icon(Icons.flag_outlined, size: 20),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            ReviewedLine(toolId: 'emergency_numbers', item: country.code),
          ]),
        ),
      ],
      SCard(
        title: t('أرقامك', 'أرقامك الخاصة', 'Your numbers'),
        icon: Icons.contact_phone_rounded,
        color: SD.green,
        trailing: IconButton(tooltip: t('ضيف', 'إضافة', 'Add'), onPressed: () => _addCustom(s), icon: const Icon(Icons.add_circle_rounded)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (custom.isEmpty)
            Text(t('ضيف أقرب مستشفى، الإسعاف المحلي، صيدلية الليل…', 'أضف أقرب مستشفى، الإسعاف المحلي، الصيدلية المناوبة…', 'Add your nearest hospital, local ambulance, night pharmacy…')),
          for (final c in custom)
            CTile(
              icon: Icons.local_phone_rounded,
              color: SD.green,
              title: cStr(c['name']),
              sub: cStr(c['phone']),
              onTap: () => _addCustom(s, c),
              actions: [
                IconButton(tooltip: tr('اتصل', 'Call'), onPressed: () => callNumber(cStr(c['phone'])), icon: const Icon(Icons.call_rounded, color: SD.green)),
                IconButton(
                  tooltip: t('امسح', 'حذف', 'Delete'),
                  onPressed: () async {
                    if (!await confirmDelete(context, cStr(c['name']))) return;
                    s.setData('emergency_numbers_custom', _custom(s)..removeWhere((x) => x['id'] == c['id']));
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ],
            ),
          const SizedBox(height: 8),
          ShareBar(summary),
        ]),
      ),
      NoteBox(
        t('لأرقام أهلك وأصحابك استعمل أداة «أرقام مهمة».', 'لأرقام الأهل والأصدقاء استخدم أداة «أرقام مهمة».', 'For family and friends, use the «Important numbers» tool.'),
        kind: NoteKind.tip,
      ),
      NoteBox(
        t('وقت الطوارئ: قول مكانك بالضبط، نوع المشكلة، وعدد المصابين — وما تقفل الخط لحدي ما يقولوا ليك.', 'عند الطوارئ: اذكر موقعك بدقة ونوع المشكلة وعدد المصابين — ولا تغلق الخط حتى يُطلب منك.',
            'In an emergency: give your exact location, what happened and how many are hurt — stay on the line until told to hang up.'),
      ),
    ]);
  }
}
