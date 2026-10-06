import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

const _cats = ['عائلة', 'طوارئ', 'صحة', 'خدمات', 'شغل', 'أخرى'];

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
      if (!await launchUrl(u, mode: LaunchMode.externalApplication)) toast('ما قدرنا نفتح التطبيق');
    } catch (_) {
      toast('ما قدرنا نفتح التطبيق');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = _list(s);
    final shown = all.where((c) => _filter == null || c['c'] == _filter).toList();
    return ToolList(children: [
      SCard(
        title: 'أضف رقم',
        icon: Icons.person_add_alt_1_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'الاسم', hintText: 'دكتور، كهربائي، الحاجة…')),
          const SizedBox(height: 10),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(labelText: 'الرقم', hintText: '0912345678 أو +249…'),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 6, children: [for (final c in _cats) ChoiceChip(label: Text(c), selected: _cat == c, onSelected: (_) => setState(() => _cat = c))]),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) return toast('أكتب الاسم والرقم');
              s.setData('contacts_list', [...all, {'n': _name.text.trim(), 'p': _phone.text.trim(), 'c': _cat}]);
              _name.clear();
              _phone.clear();
              toast('اتحفظ ✓');
            },
            icon: const Icon(Icons.save_rounded),
            label: const Text('احفظ'),
          ),
        ]),
      ),
      Wrap(spacing: 6, children: [
        ChoiceChip(label: Text('الكل (${all.length})'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
        for (final c in _cats)
          if (all.any((x) => x['c'] == c)) ChoiceChip(label: Text(c), selected: _filter == c, onSelected: (_) => setState(() => _filter = c)),
      ]),
      const SizedBox(height: 10),
      if (shown.isEmpty)
        const NoteBox('ما في أرقام لسه. احفظ أرقام الدكتور والكهربائي والسبّاك والأقارب عشان تلقاها بسرعة حتى من غير نت.', kind: NoteKind.tip)
      else
        SCard(
          title: 'أرقامك',
          icon: Icons.contacts_rounded,
          child: Column(children: [
            for (final c in shown)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: SD.gold, child: Text((c['n'] as String).characters.first, style: const TextStyle(color: SD.brownDeep))),
                title: Text(c['n'], style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${c['p']} • ${c['c']}', textDirection: TextDirection.ltr, textAlign: TextAlign.right),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(tooltip: 'اتصل', icon: const Icon(Icons.call_rounded, color: SD.green), onPressed: () => _open(Uri(scheme: 'tel', path: c['p']))),
                  IconButton(
                    tooltip: 'واتساب',
                    icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                    onPressed: () => _open(Uri.parse('https://wa.me/${_intl(c['p'])}')),
                  ),
                  IconButton(
                    tooltip: 'امسح',
                    icon: const Icon(Icons.delete_outline_rounded, color: SD.red),
                    onPressed: () => s.setData('contacts_list', all..remove(c)),
                  ),
                ]),
              ),
          ]),
        ),
      const NoteBox('ما ضفنا أرقام طوارئ جاهزة عشان ممكن تختلف من ولاية لولاية — احفظ أرقام منطقتك بنفسك.', kind: NoteKind.info),
    ]);
  }
}
