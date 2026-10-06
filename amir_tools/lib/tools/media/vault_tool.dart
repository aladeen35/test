import 'dart:convert';
import 'dart:math' as math;

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
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
    if (p.length < 6) return toast(t('كلمة السر لازم تكون 6 حروف على الأقل', 'يجب أن تكون كلمة السر 6 أحرف على الأقل', 'Password must be at least 6 characters'));
    if (p != _pw2.text) return toast(t('كلمتين السر ما متطابقات', 'كلمتا السر غير متطابقتين', "Passwords don't match"));
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
      toast(t('الخزنة جاهزة 🔐', 'الخزنة جاهزة 🔐', 'Vault ready 🔐'));
    } catch (e) {
      toast('${t('حصلت مشكلة في التشفير', 'حدثت مشكلة في التشفير', 'Encryption error')}: $e');
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
      toast(t('كلمة السر غلط ❌', 'كلمة السر خاطئة ❌', 'Wrong password ❌'));
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
    final ti = TextEditingController(text: n?.title ?? '');
    final b = TextEditingController(text: n?.body ?? '');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(ctx).bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(n == null ? tr('ملاحظة سرية جديدة', 'New secret note') : t('عدّل الملاحظة', 'تعديل الملاحظة', 'Edit note'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(controller: ti, decoration: InputDecoration(labelText: tr('العنوان', 'Title'), prefixIcon: const Icon(Icons.title_rounded))),
          const SizedBox(height: 10),
          TextField(controller: b, minLines: 5, maxLines: 12, decoration: InputDecoration(labelText: t('أكتب هنا السر بتاعك', 'اكتب سرّك هنا', 'Write your secret here'), alignLabelWithHint: true)),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.lock_rounded), label: Text(tr('شفّر واحفظ', 'Encrypt & save'))),
        ]),
      ),
    );
    if (ok == true && (ti.text.trim().isNotEmpty || b.text.trim().isNotEmpty)) {
      final now = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        if (n == null) {
          _notes.insert(0, _Note(ti.text.trim().isEmpty ? tr('بدون عنوان', 'Untitled') : ti.text.trim(), b.text, now, now));
        } else {
          n
            ..title = ti.text.trim().isEmpty ? tr('بدون عنوان', 'Untitled') : ti.text.trim()
            ..body = b.text
            ..updated = now;
        }
      });
      await _save();
      toast(t('اتحفظت مشفّرة ✓', 'حُفظت مشفّرة ✓', 'Saved encrypted ✓'));
    }
    ti.dispose();
    b.dispose();
  }

  Future<void> _delete(_Note n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('تمسح الملاحظة؟', 'حذف الملاحظة؟', 'Delete note?')),
        content: Text(t('«${n.title}» بتتمسح نهائي.', 'ستُحذف «${n.title}» نهائياً.', '"${n.title}" will be deleted permanently.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('لا', 'No'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t('امسح', 'احذف', 'Delete'))),
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
        title: Text(tr('غيّر كلمة السر الرئيسية', 'Change master password')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: a, obscureText: true, decoration: InputDecoration(labelText: tr('الجديدة', 'New password'))),
          const SizedBox(height: 10),
          TextField(controller: b, obscureText: true, decoration: InputDecoration(labelText: tr('أكّدها', 'Confirm'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('غيّر', 'Change'))),
        ],
      ),
    );
    final p = a.text, p2 = b.text;
    a.dispose();
    b.dispose();
    if (ok != true) return;
    if (p.length < 6) return toast(tr('6 حروف على الأقل', 'At least 6 characters'));
    if (p != p2) return toast(t('ما متطابقات', 'غير متطابقتين', "Don't match"));
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
      toast(t('كلمة السر اتغيّرت والملاحظات اتشفّرت من جديد ✓', 'تغيّرت كلمة السر وأُعيد تشفير الملاحظات ✓', 'Password changed and notes re-encrypted ✓'));
    } catch (_) {
      toast(t('ما قدرنا نغيّرها', 'تعذّر تغييرها', "Couldn't change it"));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('تمسح الخزنة كلها؟', 'حذف الخزنة كلها؟', 'Delete the whole vault?')),
        content: Text(t('كل الملاحظات المشفّرة بتتمسح نهائياً وما في طريقة ترجّعها. متأكد؟', 'ستُحذف كل الملاحظات المشفّرة نهائياً ولا توجد طريقة لاستعادتها. هل أنت متأكد؟',
            'All encrypted notes will be permanently deleted with no way to recover them. Are you sure?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('لا خليها', 'لا، أبقِها', 'No, keep it'))),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: SD.red), onPressed: () => Navigator.pop(ctx, true), child: Text(t('أيوه امسح', 'نعم، احذف', 'Yes, delete'))),
        ],
      ),
    );
    if (ok == true) {
      _s.setData('vault_meta', null);
      _s.setData('vault_notes', null);
      _lock();
      toast(t('الخزنة اتمسحت', 'حُذفت الخزنة', 'Vault deleted'));
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    final m = _meta;
    if (_busy) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: SD.gold),
          const SizedBox(height: 14),
          Text(t('بنشفّر/بنفك… (100 ألف دورة PBKDF2، أصبر ثواني)', 'جارٍ التشفير/فك التشفير… (100 ألف دورة PBKDF2، انتظر ثوانٍ)', 'Encrypting/decrypting… (100k PBKDF2 rounds, a few seconds)'),
              textAlign: TextAlign.center),
        ]),
      );
    }
    if (m == null) return _setupView();
    if (_key == null) return _lockedView(m);
    return _openView(m);
  }

  Widget _pwField(TextEditingController c, String label, {VoidCallback? onSubmit}) => Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 10),
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
        ResultHero(
            label: tr('الخزنة السرية', 'Secret Vault'),
            value: '🔐',
            sub: t('ملاحظات مشفّرة AES-256 بكلمة سر بتعرفها إنت بس', 'ملاحظات مشفّرة AES-256 بكلمة سر لا يعرفها سواك', 'AES-256 encrypted notes with a password only you know')),
        SCard(
          title: t('أعمل كلمة سر رئيسية', 'أنشئ كلمة سر رئيسية', 'Create a master password'),
          icon: Icons.password_rounded,
          color: SD.gold,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _pwField(_pw, tr('كلمة السر الرئيسية', 'Master password')),
            _pwField(_pw2, t('أكّدها تاني', 'أكّدها مرة أخرى', 'Confirm it'), onSubmit: _setup),
            FilledButton.icon(onPressed: _setup, icon: const Icon(Icons.lock_rounded), label: Text(t('يلا أعمل الخزنة', 'أنشئ الخزنة', 'Create vault'))),
          ]),
        ),
        NoteBox(
            t('تحذير مهم: لو نسيت كلمة السر الرئيسية، الملاحظات بتضيع للأبد. ما في «نسيت كلمة السر» ولا زول يقدر يفكها — لا نحن ولا غيرنا.',
                'تحذير مهم: إن نسيت كلمة السر الرئيسية فستضيع الملاحظات للأبد. لا يوجد «نسيت كلمة السر» ولا يستطيع أحد فكّها — لا نحن ولا غيرنا.',
                "Important: if you forget the master password, your notes are lost forever. There's no \"forgot password\" and nobody can decrypt them — not us, not anyone."),
            kind: NoteKind.danger),
        NoteBox(
            t('كيف بتشتغل: من كلمة السر بنطلع مفتاح 256 بت بـ PBKDF2-HMAC-SHA256 (100,000 دورة + ملح عشوائي)، وبنشفّر الملاحظات بـ AES-GCM. المحفوظ في الجهاز نص مشفّر بس.',
                'كيف تعمل: نشتق من كلمة السر مفتاح 256 بت عبر PBKDF2-HMAC-SHA256 (100,000 دورة + ملح عشوائي)، ونشفّر الملاحظات بـ AES-GCM. المحفوظ في الجهاز نص مشفّر فقط.',
                'How it works: a 256-bit key is derived from your password with PBKDF2-HMAC-SHA256 (100,000 rounds + random salt), and notes are encrypted with AES-GCM. Only ciphertext is stored on the device.'),
            kind: NoteKind.info),
        NoteBox(
            t('استعملها لأرقام الحسابات، أرقام سرية، أكواد الاسترجاع… بس ما تعتمد عليها كنسخة وحيدة: لو مسحت التطبيق بتمسح معاهو.',
                'استخدمها لأرقام الحسابات والأرقام السرية وأكواد الاسترجاع… لكن لا تعتمد عليها كنسخة وحيدة: إن حذفت التطبيق ستُحذف معه.',
                "Use it for account numbers, PINs, recovery codes… but don't rely on it as the only copy: uninstalling the app deletes it too."),
            kind: NoteKind.tip),
      ]);

  Widget _lockedView(Map m) {
    final created = DateTime.fromMillisecondsSinceEpoch((m['created'] as num?)?.toInt() ?? 0);
    return ToolList(children: [
      ResultHero(
          label: t('الخزنة مقفولة', 'الخزنة مقفلة', 'Vault locked'),
          value: '🔒',
          sub: t('أكتب كلمة السر الرئيسية عشان تفتحها', 'اكتب كلمة السر الرئيسية لفتحها', 'Enter your master password to open it')),
      SCard(
        title: tr('افتح الخزنة', 'Open vault'),
        icon: Icons.lock_open_rounded,
        color: SD.gold,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _pwField(_pw, tr('كلمة السر', 'Password'), onSubmit: _unlock),
          FilledButton.icon(onPressed: _unlock, icon: const Icon(Icons.lock_open_rounded), label: Text(tr('افتح', 'Open'))),
          if (_fails > 0) Padding(padding: const EdgeInsetsDirectional.only(top: 8), child: Text('${t('محاولات غلط', 'محاولات خاطئة', 'Wrong attempts')}: $_fails', style: const TextStyle(color: SD.red))),
        ]),
      ),
      SCard(
        title: tr('معلومات الخزنة', 'Vault info'),
        icon: Icons.info_outline_rounded,
        color: SD.nile,
        child: Column(children: [
          if (created.year > 2000) InfoRow(t('اتعملت', 'أُنشئت', 'Created'), fmtDateAr(created), icon: Icons.event_rounded),
          InfoRow(tr('التشفير', 'Encryption'), 'AES-GCM 256', icon: Icons.enhanced_encryption_rounded),
          InfoRow(tr('اشتقاق المفتاح', 'Key derivation'), 'PBKDF2-SHA256 × ${fmt((m['it'] as num?) ?? _iterations, 0)}', icon: Icons.key_rounded),
        ]),
      ),
      TextButton.icon(onPressed: _reset, icon: const Icon(Icons.delete_forever_rounded, color: SD.red), label: Text(t('نسيت كلمة السر؟ امسح الخزنة وابدا من جديد', 'نسيت كلمة السر؟ احذف الخزنة وابدأ من جديد', 'Forgot the password? Delete the vault and start over'),
            style: const TextStyle(color: SD.red))),
    ]);
  }

  Widget _openView(Map m) {
    final q = _search.text.trim();
    final list = q.isEmpty ? _notes : _notes.where((n) => n.title.contains(q) || n.body.contains(q)).toList();
    final chars = _notes.fold<int>(0, (a, n) => a + n.body.length);
    return ToolList(children: [
      Row(children: [
        Expanded(child: FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add_rounded), label: Text(tr('ملاحظة جديدة', 'New note')))),
        const SizedBox(width: 10),
        OutlinedButton.icon(onPressed: _lock, icon: const Icon(Icons.lock_rounded), label: Text(t('اقفل', 'أقفل', 'Lock'))),
      ]),
      const SizedBox(height: 12),
      StatGrid([
        StatChip('${_notes.length}', tr('ملاحظة', 'Notes'), color: SD.gold, icon: Icons.sticky_note_2_rounded),
        StatChip(fmt(chars, 0), tr('حرف مشفّر', 'Encrypted chars'), color: SD.green, icon: Icons.text_fields_rounded),
        StatChip(fmtBytes((_s.getData<String>('vault_notes') ?? '').length), t('حجم المحفوظ', 'حجم المحفوظ', 'Stored size'), color: SD.nile, icon: Icons.sd_storage_rounded),
      ]),
      const SizedBox(height: 12),
      if (_notes.length > 3)
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 12),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: t('فتّش في الملاحظات', 'ابحث في الملاحظات', 'Search notes'), prefixIcon: const Icon(Icons.search_rounded)),
          ),
        ),
      if (_notes.isEmpty) NoteBox(t('الخزنة فاضية. أضف أول ملاحظة سرية 👆', 'الخزنة فارغة. أضف أول ملاحظة سرية 👆', 'The vault is empty. Add your first secret note 👆'), kind: NoteKind.tip),
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
            itemBuilder: (_) => [
              PopupMenuItem(value: 'e', child: Text(t('عدّل', 'تعديل', 'Edit'))),
              PopupMenuItem(value: 'c', child: Text(t('انسخ', 'نسخ', 'Copy'))),
              PopupMenuItem(value: 'd', child: Text(t('امسح', 'حذف', 'Delete'))),
            ],
          ),
          child: InkWell(
            onTap: () => _edit(n),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.body, maxLines: 4, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text('${tr('آخر تعديل', 'Last edited')}: ${fmtDateAr(DateTime.fromMillisecondsSinceEpoch(n.updated), weekday: false)} ${fmtTimeAr(DateTime.fromMillisecondsSinceEpoch(n.updated))}',
                  style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))),
            ]),
          ),
        ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: _changePassword, icon: const Icon(Icons.key_rounded), label: Text(tr('غيّر كلمة السر', 'Change password')))),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.delete_forever_rounded, color: SD.red), label: Text(t('امسح الخزنة', 'احذف الخزنة', 'Delete vault')))),
      ]),
      NoteBox(
          t('اقفل الخزنة لما تخلص. لو نسيت كلمة السر الرئيسية، البيانات بتضيع نهائي.', 'أقفل الخزنة عند الانتهاء. إن نسيت كلمة السر الرئيسية فستضيع البيانات نهائياً.',
              'Lock the vault when done. If you forget the master password, the data is lost for good.'),
          kind: NoteKind.warn),
    ]);
  }
}
