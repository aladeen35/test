import 'dart:convert';
import 'dart:math' as math;

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

const _iterations = 100000;
const _checkPlain = 'amir-vault-ok';

/// اشتقاق المفتاح (يشتغل في isolate منفصل عشان الواجهة ما تهنق)
Future<List<int>> _deriveKey(Map<String, dynamic> a) async {
  final kdf = Pbkdf2.hmacSha256(iterations: a['it'] as int, bits: 256);
  final k = await kdf.deriveKeyFromPassword(password: a['pw'] as String, nonce: List<int>.from(a['salt'] as List));
  return k.extractBytes();
}

final _aes = AesGcm.with256bits();

Future<String> _enc(String plain, List<int> key) async {
  final box = await _aes.encrypt(utf8.encode(plain), secretKey: SecretKeyData(key));
  return base64Encode(box.concatenation());
}

Future<String> _dec(String b64, List<int> key) async {
  final box = SecretBox.fromConcatenation(base64Decode(b64), nonceLength: _aes.nonceLength, macLength: _aes.macAlgorithm.macLength);
  return utf8.decode(await _aes.decrypt(box, secretKey: SecretKeyData(key)));
}

List<int> _randomBytes(int n) {
  final r = math.Random.secure();
  return List.generate(n, (_) => r.nextInt(256));
}

class _Note {
  String title, body;
  int created, updated;
  _Note(this.title, this.body, this.created, this.updated);
  Map<String, dynamic> toJson() => {'t': title, 'b': body, 'c': created, 'u': updated};
  factory _Note.fromJson(Map m) => _Note(m['t'] ?? '', m['b'] ?? '', m['c'] ?? 0, m['u'] ?? 0);
}

class VaultTool extends StatefulWidget {
  const VaultTool({super.key});
  @override
  State<VaultTool> createState() => _VaultToolState();
}

class _VaultToolState extends State<VaultTool> {
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  final _search = TextEditingController();
  List<int>? _key;
  List<_Note> _notes = [];
  bool _busy = false;
  bool _show = false;
  int _fails = 0;

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    _search.dispose();
    _key = null;
    super.dispose();
  }

  AppState get _s => context.read<AppState>();
  Map? get _meta => _s.getData<Map>('vault_meta');

  Future<List<int>> _derive(String pw, List<int> salt, int it) =>
      compute(_deriveKey, <String, dynamic>{'pw': pw, 'salt': salt, 'it': it});

  Future<void> _setup() async {
    final p = _pw.text;
    if (p.length < 6) return toast('كلمة السر لازم تكون 6 حروف على الأقل');
    if (p != _pw2.text) return toast('كلمتين السر ما متطابقات');
    setState(() => _busy = true);
    try {
      final salt = _randomBytes(16);
      final key = await _derive(p, salt, _iterations);
      _s.setData('vault_meta', {'salt': base64Encode(salt), 'it': _iterations, 'check': await _enc(_checkPlain, key), 'created': DateTime.now().millisecondsSinceEpoch});
      _key = key;
      _notes = [];
      await _save();
      _pw.clear();
      _pw2.clear();
      toast('الخزنة جاهزة 🔐');
    } catch (e) {
      toast('حصلت مشكلة في التشفير: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _unlock() async {
    final m = _meta;
    if (m == null) return;
    setState(() => _busy = true);
    try {
      final key = await _derive(_pw.text, base64Decode(m['salt']), (m['it'] as num?)?.toInt() ?? _iterations);
      final chk = await _dec(m['check'], key);
      if (chk != _checkPlain) throw Exception('bad');
      final blob = _s.getData<String>('vault_notes');
      final list = blob == null ? [] : jsonDecode(await _dec(blob, key)) as List;
      _key = key;
      _notes = list.map((e) => _Note.fromJson(e as Map)).toList();
      _fails = 0;
      _pw.clear();
    } catch (_) {
      _fails++;
      toast('كلمة السر غلط ❌');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save() async {
    final k = _key;
    if (k == null) return;
    _s.setData('vault_notes', await _enc(jsonEncode(_notes.map((n) => n.toJson()).toList()), k));
  }

  void _lock() => setState(() {
        _key = null;
        _notes = [];
        _search.clear();
      });

  Future<void> _edit([_Note? n]) async {
    final t = TextEditingController(text: n?.title ?? '');
    final b = TextEditingController(text: n?.body ?? '');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(ctx).bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(n == null ? 'ملاحظة سرية جديدة' : 'عدّل الملاحظة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(controller: t, decoration: const InputDecoration(labelText: 'العنوان', prefixIcon: Icon(Icons.title_rounded))),
          const SizedBox(height: 10),
          TextField(controller: b, minLines: 5, maxLines: 12, decoration: const InputDecoration(labelText: 'أكتب هنا السر بتاعك', alignLabelWithHint: true)),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.lock_rounded), label: const Text('شفّر واحفظ')),
        ]),
      ),
    );
    if (ok == true && (t.text.trim().isNotEmpty || b.text.trim().isNotEmpty)) {
      final now = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        if (n == null) {
          _notes.insert(0, _Note(t.text.trim().isEmpty ? 'بدون عنوان' : t.text.trim(), b.text, now, now));
        } else {
          n
            ..title = t.text.trim().isEmpty ? 'بدون عنوان' : t.text.trim()
            ..body = b.text
            ..updated = now;
        }
      });
      await _save();
      toast('اتحفظت مشفّرة ✓');
    }
    t.dispose();
    b.dispose();
  }

  Future<void> _delete(_Note n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تمسح الملاحظة؟'),
        content: Text('«${n.title}» بتتمسح نهائي.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('امسح')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _notes.remove(n));
      await _save();
    }
  }

  Future<void> _changePassword() async {
    final a = TextEditingController(), b = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('غيّر كلمة السر الرئيسية'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: a, obscureText: true, decoration: const InputDecoration(labelText: 'الجديدة')),
          const SizedBox(height: 10),
          TextField(controller: b, obscureText: true, decoration: const InputDecoration(labelText: 'أكّدها')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('غيّر')),
        ],
      ),
    );
    final p = a.text, p2 = b.text;
    a.dispose();
    b.dispose();
    if (ok != true) return;
    if (p.length < 6) return toast('6 حروف على الأقل');
    if (p != p2) return toast('ما متطابقات');
    setState(() => _busy = true);
    try {
      final salt = _randomBytes(16);
      final key = await _derive(p, salt, _iterations);
      final m = Map<String, dynamic>.from(_meta ?? {});
      m
        ..['salt'] = base64Encode(salt)
        ..['it'] = _iterations
        ..['check'] = await _enc(_checkPlain, key);
      _s.setData('vault_meta', m);
      _key = key;
      await _save();
      toast('كلمة السر اتغيّرت والملاحظات اتشفّرت من جديد ✓');
    } catch (_) {
      toast('ما قدرنا نغيّرها');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تمسح الخزنة كلها؟'),
        content: const Text('كل الملاحظات المشفّرة بتتمسح نهائياً وما في طريقة ترجّعها. متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا خليها')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: SD.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('أيوه امسح')),
        ],
      ),
    );
    if (ok == true) {
      _s.setData('vault_meta', null);
      _s.setData('vault_notes', null);
      _lock();
      toast('الخزنة اتمسحت');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    final m = _meta;
    if (_busy) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: SD.gold),
          SizedBox(height: 14),
          Text('بنشفّر/بنفك… (100 ألف دورة PBKDF2، أصبر ثواني)'),
        ]),
      );
    }
    if (m == null) return _setupView();
    if (_key == null) return _lockedView(m);
    return _openView(m);
  }

  Widget _pwField(TextEditingController c, String label, {VoidCallback? onSubmit}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          obscureText: !_show,
          autocorrect: false,
          enableSuggestions: false,
          onSubmitted: onSubmit == null ? null : (_) => onSubmit(),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.key_rounded),
            suffixIcon: IconButton(icon: Icon(_show ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _show = !_show)),
          ),
        ),
      );

  Widget _setupView() => ToolList(children: [
        const ResultHero(label: 'الخزنة السرية', value: '🔐', sub: 'ملاحظات مشفّرة AES-256 بكلمة سر بتعرفها إنت بس'),
        SCard(
          title: 'أعمل كلمة سر رئيسية',
          icon: Icons.password_rounded,
          color: SD.gold,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _pwField(_pw, 'كلمة السر الرئيسية'),
            _pwField(_pw2, 'أكّدها تاني', onSubmit: _setup),
            FilledButton.icon(onPressed: _setup, icon: const Icon(Icons.lock_rounded), label: const Text('يلا أعمل الخزنة')),
          ]),
        ),
        const NoteBox('تحذير مهم: لو نسيت كلمة السر الرئيسية، الملاحظات بتضيع للأبد. ما في «نسيت كلمة السر» ولا زول يقدر يفكها — لا نحن ولا غيرنا.', kind: NoteKind.danger),
        const NoteBox('كيف بتشتغل: من كلمة السر بنطلع مفتاح 256 بت بـ PBKDF2-HMAC-SHA256 (100,000 دورة + ملح عشوائي)، وبنشفّر الملاحظات بـ AES-GCM. المحفوظ في الجهاز نص مشفّر بس.', kind: NoteKind.info),
        const NoteBox('استعملها لأرقام الحسابات، أرقام سرية، أكواد الاسترجاع… بس ما تعتمد عليها كنسخة وحيدة: لو مسحت التطبيق بتمسح معاهو.', kind: NoteKind.tip),
      ]);

  Widget _lockedView(Map m) {
    final created = DateTime.fromMillisecondsSinceEpoch((m['created'] as num?)?.toInt() ?? 0);
    return ToolList(children: [
      const ResultHero(label: 'الخزنة مقفولة', value: '🔒', sub: 'أكتب كلمة السر الرئيسية عشان تفتحها'),
      SCard(
        title: 'افتح الخزنة',
        icon: Icons.lock_open_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _pwField(_pw, 'كلمة السر', onSubmit: _unlock),
          FilledButton.icon(onPressed: _unlock, icon: const Icon(Icons.lock_open_rounded), label: const Text('افتح')),
          if (_fails > 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text('محاولات غلط: $_fails', style: const TextStyle(color: SD.red))),
        ]),
      ),
      SCard(
        title: 'معلومات الخزنة',
        icon: Icons.info_outline_rounded,
        color: SD.nile,
        child: Column(children: [
          if (created.year > 2000) InfoRow('اتعملت', fmtDateAr(created), icon: Icons.event_rounded),
          InfoRow('التشفير', 'AES-GCM 256', icon: Icons.enhanced_encryption_rounded),
          InfoRow('اشتقاق المفتاح', 'PBKDF2-SHA256 × ${fmt((m['it'] as num?) ?? _iterations, 0)}', icon: Icons.key_rounded),
        ]),
      ),
      TextButton.icon(onPressed: _reset, icon: const Icon(Icons.delete_forever_rounded, color: SD.red), label: const Text('نسيت كلمة السر؟ امسح الخزنة وابدا من جديد', style: TextStyle(color: SD.red))),
    ]);
  }

  Widget _openView(Map m) {
    final q = _search.text.trim();
    final list = q.isEmpty ? _notes : _notes.where((n) => n.title.contains(q) || n.body.contains(q)).toList();
    final chars = _notes.fold<int>(0, (a, n) => a + n.body.length);
    return ToolList(children: [
      Row(children: [
        Expanded(child: FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add_rounded), label: const Text('ملاحظة جديدة'))),
        const SizedBox(width: 10),
        OutlinedButton.icon(onPressed: _lock, icon: const Icon(Icons.lock_rounded), label: const Text('اقفل')),
      ]),
      const SizedBox(height: 12),
      StatGrid([
        StatChip('${_notes.length}', 'ملاحظة', color: SD.gold, icon: Icons.sticky_note_2_rounded),
        StatChip(fmt(chars, 0), 'حرف مشفّر', color: SD.green, icon: Icons.text_fields_rounded),
        StatChip(fmtBytes((_s.getData<String>('vault_notes') ?? '').length), 'حجم المحفوظ', color: SD.nile, icon: Icons.sd_storage_rounded),
      ]),
      const SizedBox(height: 12),
      if (_notes.length > 3)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'فتّش في الملاحظات', prefixIcon: Icon(Icons.search_rounded)),
          ),
        ),
      if (_notes.isEmpty) const NoteBox('الخزنة فاضية. أضف أول ملاحظة سرية 👆', kind: NoteKind.tip),
      for (final n in list)
        SCard(
          title: n.title,
          icon: Icons.lock_rounded,
          color: SD.henna,
          trailing: PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'e') _edit(n);
              if (v == 'c') copyText(n.body);
              if (v == 'd') _delete(n);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'e', child: Text('عدّل')),
              PopupMenuItem(value: 'c', child: Text('انسخ')),
              PopupMenuItem(value: 'd', child: Text('امسح')),
            ],
          ),
          child: InkWell(
            onTap: () => _edit(n),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.body, maxLines: 4, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text('آخر تعديل: ${fmtDateAr(DateTime.fromMillisecondsSinceEpoch(n.updated), weekday: false)} ${fmtTimeAr(DateTime.fromMillisecondsSinceEpoch(n.updated))}',
                  style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))),
            ]),
          ),
        ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: _changePassword, icon: const Icon(Icons.key_rounded), label: const Text('غيّر كلمة السر'))),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.delete_forever_rounded, color: SD.red), label: const Text('امسح الخزنة'))),
      ]),
      const NoteBox('اقفل الخزنة لما تخلص. لو نسيت كلمة السر الرئيسية، البيانات بتضيع نهائي.', kind: NoteKind.warn),
    ]);
  }
}
