import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// التصنيفات (المفتاح المحفوظ عربي ثابت؛ المعروض حسب اللغة)
const _cats = ['عائلة', 'طوارئ', 'صحة', 'خدمات', 'شغل', 'أخرى'];

String _catLabel(Object? c) => switch (c) {
      'عائلة' => tr('عائلة', 'Family'),
      'طوارئ' => tr('طوارئ', 'Emergency'),
      'صحة' => tr('صحة', 'Health'),
      'خدمات' => tr('خدمات', 'Services'),
      'شغل' => t('شغل', 'عمل', 'Work'),
      'أخرى' => tr('أخرى', 'Other'),
      _ => '${c ?? ''}',
    };

/// أرقام مهمة مع اتصال وواتساب سريع (محفوظة في الجهاز)
class ContactsTool extends StatefulWidget {
  const ContactsTool({super.key});
  @override
  State<ContactsTool> createState() => _ContactsToolState();
}

class _ContactsToolState extends State<ContactsTool> {
  final _name = TextEditingController(), _phone = TextEditingController();
  String _cat = _cats.first;
  String? _filter;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  List<Map> _list(AppState s) => List<Map>.from(s.getData<List>('contacts_list') ?? []);

  /// تحويل الرقم لصيغة دولية لواتساب (السودان 249 افتراضيًا)
  String _intl(String p) {
    var d = p.replaceAll(RegExp(r'[^\d+]'), '');
    if (d.startsWith('+')) return d.substring(1);
    if (d.startsWith('00')) return d.substring(2);
    if (d.startsWith('0')) return '249${d.substring(1)}';
    if (d.length == 9) return '249$d';
    return d;
  }

  Future<void> _open(Uri u) async {
    try {
      if (!await launchUrl(u, mode: LaunchMode.externalApplication)) toast(t('ما قدرنا نفتح التطبيق', 'تعذّر فتح التطبيق', "Couldn't open the app"));
    } catch (_) {
      toast(t('ما قدرنا نفتح التطبيق', 'تعذّر فتح التطبيق', "Couldn't open the app"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = _list(s);
    final shown = all.where((c) => _filter == null || c['c'] == _filter).toList();
    return ToolList(children: [
      SCard(
        title: t('أضف رقم', 'أضف رقمًا', 'Add a number'),
        icon: Icons.person_add_alt_1_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
              controller: _name,
              decoration: InputDecoration(labelText: tr('الاسم', 'Name'), hintText: t('دكتور، كهربائي، الحاجة…', 'طبيب، كهربائي، الوالدة…', 'Doctor, electrician, Mum…'))),
          const SizedBox(height: 10),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: tr('الرقم', 'Phone number'), hintText: tr('0912345678 أو +249…', '+249… or 0912345678')),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 6, children: [for (final c in _cats) ChoiceChip(label: Text(_catLabel(c)), selected: _cat == c, onSelected: (_) => setState(() => _cat = c))]),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) return toast(t('أكتب الاسم والرقم', 'اكتب الاسم والرقم', 'Enter the name and number'));
              s.setData('contacts_list', [...all, {'n': _name.text.trim(), 'p': _phone.text.trim(), 'c': _cat}]);
              _name.clear();
              _phone.clear();
              toast(t('اتحفظ ✓', 'تم الحفظ ✓', 'Saved ✓'));
            },
            icon: const Icon(Icons.save_rounded),
            label: Text(tr('احفظ', 'Save')),
          ),
        ]),
      ),
      Wrap(spacing: 6, children: [
        ChoiceChip(label: Text('${tr('الكل', 'All')} (${all.length})'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
        for (final c in _cats)
          if (all.any((x) => x['c'] == c)) ChoiceChip(label: Text(_catLabel(c)), selected: _filter == c, onSelected: (_) => setState(() => _filter = c)),
      ]),
      const SizedBox(height: 10),
      if (shown.isEmpty)
        NoteBox(
            t('ما في أرقام لسه. احفظ أرقام الدكتور والكهربائي والسبّاك والأقارب عشان تلقاها بسرعة حتى من غير نت.',
                'لا توجد أرقام بعد. احفظ أرقام الطبيب والكهربائي والسبّاك والأقارب لتجدها بسرعة حتى دون إنترنت.',
                'No numbers yet. Save your doctor, electrician, plumber and relatives so you can find them fast, even offline.'),
            kind: NoteKind.tip)
      else
        SCard(
          title: tr('أرقامك', 'Your numbers'),
          icon: Icons.contacts_rounded,
          child: Column(children: [
            for (final c in shown)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: SD.gold, child: Text((c['n'] as String).characters.first, style: const TextStyle(color: SD.brownDeep))),
                title: Text(c['n'], style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('\u2066${c['p']}\u2069 • ${_catLabel(c['c'])}', textAlign: TextAlign.start),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(tooltip: tr('اتصل', 'Call'), icon: const Icon(Icons.call_rounded, color: SD.green), onPressed: () => _open(Uri(scheme: 'tel', path: c['p']))),
                  IconButton(
                    tooltip: tr('واتساب', 'WhatsApp'),
                    icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                    onPressed: () => _open(Uri.parse('https://wa.me/${_intl(c['p'])}')),
                  ),
                  IconButton(
                    tooltip: t('امسح', 'احذف', 'Delete'),
                    icon: const Icon(Icons.delete_outline_rounded, color: SD.red),
                    onPressed: () => s.setData('contacts_list', all..remove(c)),
                  ),
                ]),
              ),
          ]),
        ),
      NoteBox(
          t('ما ضفنا أرقام طوارئ جاهزة عشان ممكن تختلف من ولاية لولاية ومن بلد لبلد — احفظ أرقام منطقتك بنفسك. الأرقام المحلية من غير مفتاح دولة بنعتبرها سودانية (+249) في واتساب.',
              'لم نضف أرقام طوارئ جاهزة لأنها تختلف من ولاية لأخرى ومن بلد لآخر — احفظ أرقام منطقتك بنفسك. الأرقام المحلية دون مفتاح الدولة تُعامل كسودانية (+249) في واتساب.',
              "We didn't preload emergency numbers since they vary by region and country — save your local ones yourself. For WhatsApp, numbers without a country code are treated as Sudanese (+249)."),
          kind: NoteKind.info),
    ]);
  }
}
