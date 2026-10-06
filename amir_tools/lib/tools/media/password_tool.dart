import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'media_common.dart';

/// قائمة كلمات بسيطة لعبارات المرور (256 كلمة = 8 بت لكل كلمة)
const _words = [
  'able', 'acid', 'aged', 'also', 'apex', 'arch', 'army', 'atom', 'aunt', 'away', 'baby', 'bake', 'ball', 'band', 'bank', 'barn',
  'base', 'bath', 'beam', 'bean', 'bear', 'beef', 'bell', 'belt', 'bike', 'bird', 'blue', 'boat', 'body', 'bold', 'bone', 'book',
  'boot', 'bowl', 'brag', 'brew', 'brick', 'bulb', 'bull', 'bush', 'cake', 'calm', 'camel', 'camp', 'card', 'cart', 'cash', 'cave',
  'chef', 'chip', 'city', 'clay', 'clip', 'club', 'coal', 'coat', 'code', 'coin', 'cold', 'cook', 'cool', 'corn', 'crab', 'crew',
  'crop', 'cube', 'cup', 'cute', 'dark', 'date', 'dawn', 'deal', 'deer', 'desk', 'dial', 'dice', 'dish', 'dock', 'doll', 'dome',
  'door', 'dove', 'drum', 'duck', 'dune', 'dust', 'eagle', 'earth', 'echo', 'edge', 'emu', 'epic', 'face', 'fair', 'farm', 'fast',
  'fern', 'film', 'fire', 'fish', 'flag', 'flat', 'foam', 'fog', 'fork', 'fort', 'fox', 'frog', 'fuel', 'game', 'gate', 'gear',
  'gift', 'glad', 'glow', 'goat', 'gold', 'golf', 'grape', 'grass', 'gulf', 'hail', 'hall', 'hand', 'harp', 'hawk', 'heat', 'herb',
  'hill', 'hive', 'honey', 'hook', 'horn', 'horse', 'hunt', 'iced', 'idea', 'iron', 'item', 'jade', 'jazz', 'jeep', 'joke', 'juice',
  'jump', 'kale', 'keen', 'kick', 'king', 'kite', 'knee', 'knot', 'lake', 'lamb', 'lamp', 'land', 'lark', 'lava', 'leaf', 'lemon',
  'lime', 'lion', 'loaf', 'loom', 'lucky', 'lunar', 'mango', 'map', 'mask', 'meal', 'mild', 'milk', 'mint', 'moon', 'moss', 'mule',
  'nest', 'nile', 'noon', 'note', 'oak', 'oasis', 'ocean', 'olive', 'onion', 'orbit', 'oven', 'owl', 'palm', 'park', 'path', 'peach',
  'pearl', 'pen', 'pine', 'pipe', 'plum', 'pond', 'pony', 'pool', 'quiet', 'rain', 'reef', 'rice', 'ring', 'river', 'road', 'robe',
  'rock', 'roof', 'rope', 'rose', 'ruby', 'safe', 'sail', 'salt', 'sand', 'seed', 'shell', 'ship', 'silk', 'sky', 'snow', 'sofa',
  'soup', 'star', 'stem', 'stone', 'sugar', 'sun', 'swan', 'table', 'tea', 'tent', 'tiger', 'tile', 'toast', 'tower', 'tree', 'tulip',
  'vase', 'vine', 'wave', 'well', 'whale', 'wheat', 'wind', 'wing', 'wolf', 'wood', 'wool', 'yard', 'yarn', 'zebra', 'zinc', 'zone',
];

const _lower = 'abcdefghijklmnopqrstuvwxyz';
const _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const _digits = '0123456789';
const _symbols = r'!@#$%^&*()-_=+[]{};:,.?/~';
const _ambiguous = 'Il1O0o|`\'"';

const _common = [
  '123456', '123456789', '12345678', '12345', '1234567', '1234567890', '111111', '000000', '123123', '654321', '666666', '121212',
  'password', 'passw0rd', 'qwerty', 'qwerty123', 'abc123', 'iloveyou', 'admin', 'welcome', 'letmein', 'monkey', 'dragon', 'football',
  '1q2w3e4r', '1qaz2wsx', 'asdfgh', 'zxcvbn', 'sudan', 'sudan123', 'khartoum', 'omdurman', 'allah', 'muhammad', 'mohamed', 'ahmed',
  'love', 'princess', 'master', 'superman', 'hello', 'freedom', 'whatever', 'shadow', '112233', '987654321', '147258369', 'aaaaaa',
];

class PasswordTool extends StatefulWidget {
  const PasswordTool({super.key});
  @override
  State<PasswordTool> createState() => _PasswordToolState();
}

class _PasswordToolState extends State<PasswordTool> {
  final _rng = math.Random.secure();
  bool _phrase = false;
  double _len = 16;
  bool _lo = true, _up = true, _di = true, _sy = true, _noAmb = true;
  double _wordsN = 5;
  String _sep = '-';
  bool _cap = true, _addNum = true;
  String _pw = '';
  double _bits = 0;

  final _check = TextEditingController();
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _check.dispose();
    super.dispose();
  }

  String _strip(String s) => _noAmb ? s.split('').where((c) => !_ambiguous.contains(c)).join() : s;

  void _generate() {
    if (_phrase) {
      final n = _wordsN.round();
      final w = List.generate(n, (_) {
        final x = _words[_rng.nextInt(_words.length)];
        return _cap ? x[0].toUpperCase() + x.substring(1) : x;
      });
      var bits = n * math.log(_words.length) / math.ln2;
      if (_addNum) {
        w.add('${_rng.nextInt(100)}');
        bits += math.log(100) / math.ln2;
      }
      _pw = w.join(_sep);
      _bits = bits;
    } else {
      final sets = <String>[
        if (_lo) _strip(_lower),
        if (_up) _strip(_upper),
        if (_di) _strip(_digits),
        if (_sy) _strip(_symbols),
      ];
      if (sets.isEmpty) {
        _pw = '';
        _bits = 0;
        setState(() {});
        return;
      }
      final pool = sets.join();
      final n = _len.round();
      // حرف واحد على الأقل من كل مجموعة، والباقي عشوائي، وبعدين نخلطهم
      final chars = <String>[for (final s in sets) s[_rng.nextInt(s.length)]];
      while (chars.length < n) {
        chars.add(pool[_rng.nextInt(pool.length)]);
      }
      chars.shuffle(_rng);
      _pw = chars.take(n).join();
      _bits = n * math.log(pool.length) / math.ln2;
    }
    setState(() {});
  }

  static (String, Color, double) _level(double bits) {
    if (bits < 28) return (t('ضعيفة شديد', 'ضعيفة جداً', 'Very weak'), SD.red, .12);
    if (bits < 36) return (tr('ضعيفة', 'Weak'), SD.henna, .3);
    if (bits < 60) return (t('نص نص', 'متوسطة', 'Fair'), SD.gold, .55);
    if (bits < 80) return (tr('قوية', 'Strong'), SD.green, .8);
    return (t('قوية شديد 💪', 'قوية جداً 💪', 'Very strong 💪'), SD.teal, 1);
  }

  /// متوسط زمن الكسر = نص مساحة البحث ÷ المحاولات في الثانية
  static String _crack(double bits, double perSec) => humanTime(math.pow(2, bits - 1) / perSec);

  Widget _crackTable(double bits) => Column(children: [
        InfoRow(tr('هجوم عبر الإنترنت (100 محاولة/ث)', 'Online attack (100 guesses/s)'), _crack(bits, 100),
            icon: Icons.public_rounded,
            hint: t('موقع ما بيقفل الحساب بعد المحاولات الغلط', 'موقع لا يقفل الحساب بعد المحاولات الخاطئة', "A site that doesn't lock after wrong attempts")),
        InfoRow(tr('جهاز عادي، تشفير قوي (10 آلاف/ث)', 'Normal PC, strong hashing (10k/s)'), _crack(bits, 1e4),
            icon: Icons.computer_rounded,
            hint: t('لو اتسرقت قاعدة بيانات محمية كويس', 'لو سُرقت قاعدة بيانات محمية جيداً', 'If a well-protected database leaks')),
        InfoRow(tr('كرت شاشة قوي (10 مليار/ث)', 'Strong GPU (10 billion/s)'), _crack(bits, 1e10),
            icon: Icons.memory_rounded, hint: t('تشفير ضعيف زي MD5', 'تشفير ضعيف مثل MD5', 'Weak hashing like MD5')),
        InfoRow(tr('مزرعة أجهزة ضخمة (تريليون/ث)', 'Huge cracking farm (1 trillion/s)'), _crack(bits, 1e12), icon: Icons.dns_rounded),
      ]);

  @override
  Widget build(BuildContext context) {
    final (lvl, col, frac) = _level(_bits);
    return ToolList(children: [
      SegmentedButton<bool>(
        segments: [
          ButtonSegment(value: false, icon: const Icon(Icons.password_rounded), label: Text(tr('حروف عشوائية', 'Random characters'))),
          ButtonSegment(value: true, icon: const Icon(Icons.short_text_rounded), label: Text(tr('عبارة مرور', 'Passphrase'))),
        ],
        selected: {_phrase},
        onSelectionChanged: (v) {
          _phrase = v.first;
          _generate();
        },
      ),
      const SizedBox(height: 14),
      ResultHero(
        label: t('كلمة السر الجديدة (اضغط ضغطة طويلة للنسخ)', 'كلمة السر الجديدة (اضغط مطوّلاً للنسخ)', 'New password (long-press to copy)'),
        value: _pw.isEmpty ? '—' : _pw,
        sub: '${_bits.toStringAsFixed(0)} ${tr('بت عشوائية', 'random bits')} • $lvl',
        colors: [col, SD.coffee],
      ),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () => copyText(_pw), icon: const Icon(Icons.copy_rounded), label: Text(tr('انسخ', 'Copy')))),
        const SizedBox(width: 10),
        Expanded(child: FilledButton.icon(onPressed: _generate, icon: const Icon(Icons.casino_rounded), label: Text(t('ولّد تاني', 'ولّد مجدداً', 'Generate again')))),
      ]),
      const SizedBox(height: 14),
      SCard(
        title: tr('الإعدادات', 'Settings'),
        icon: Icons.tune_rounded,
        color: SD.gold,
        child: _phrase ? _phraseOpts() : _charOpts(),
      ),
      SCard(
        title: t('قوتها كم؟', 'ما مدى قوتها؟', 'How strong is it?'),
        icon: Icons.shield_rounded,
        color: col,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: frac, minHeight: 12, color: col, backgroundColor: col.withValues(alpha: .15)),
          ),
          const SizedBox(height: 10),
          StatGrid([
            StatChip('${_pw.length}', tr('طول', 'Length'), color: SD.nile, icon: Icons.straighten_rounded),
            StatChip(_bits.toStringAsFixed(0), tr('بت إنتروبي', 'Entropy bits'), color: SD.purple, icon: Icons.functions_rounded),
            StatChip(lvl, tr('التقييم', 'Rating'), color: col, icon: Icons.verified_rounded),
          ]),
          const SizedBox(height: 8),
          Text(t('الزمن المتوقع عشان زول يخمّنها:', 'الزمن المتوقع لتخمينها:', 'Expected time to guess it:'), style: const TextStyle(fontWeight: FontWeight.w700)),
          _crackTable(_bits),
        ]),
      ),
      _checker(),
      NoteBox(
          t('كلمات السر دي بتتولّد في جهازك بمولّد عشوائي آمن (Random.secure)، وما بنحفظها ولا بنرسلها لأي مكان. احفظها في مكان آمن.',
              'تُولَّد كلمات السر هذه في جهازك بمولّد عشوائي آمن (Random.secure)، ولا نحفظها ولا نرسلها لأي مكان. احفظها في مكان آمن.',
              "These passwords are generated on your device with a secure random generator (Random.secure). We don't store or send them anywhere. Keep them somewhere safe."),
          kind: NoteKind.info),
      NoteBox(
          t('نصايح: ما تكرر نفس كلمة السر في أكتر من موقع، وفعّل التحقق بخطوتين في الواتساب والفيسبوك والبنك.',
              'نصائح: لا تكرر كلمة السر نفسها في أكثر من موقع، وفعّل التحقق بخطوتين في واتساب وفيسبوك والبنك.',
              "Tips: don't reuse the same password on multiple sites, and turn on two-step verification for WhatsApp, Facebook and your bank."),
          kind: NoteKind.tip),
    ]);
  }

  Widget _charOpts() => Column(children: [
        Row(children: [
          Text(tr('الطول', 'Length')),
          Expanded(
            child: Slider(
              value: _len,
              min: 6,
              max: 64,
              divisions: 58,
              label: '${_len.round()}',
              onChanged: (v) {
                _len = v;
                _generate();
              },
            ),
          ),
          Text('${_len.round()}', style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        _sw(tr('حروف صغيرة (a-z)', 'Lowercase (a-z)'), _lo, (v) => _lo = v),
        _sw(tr('حروف كبيرة (A-Z)', 'Uppercase (A-Z)'), _up, (v) => _up = v),
        _sw(tr('أرقام (0-9)', 'Digits (0-9)'), _di, (v) => _di = v),
        _sw(tr('رموز (!@#…)', 'Symbols (!@#…)'), _sy, (v) => _sy = v),
        _sw(t('شيل الحروف المتشابهة (I l 1 O 0)', 'استبعد الحروف المتشابهة (I l 1 O 0)', 'Exclude look-alikes (I l 1 O 0)'), _noAmb, (v) => _noAmb = v),
      ]);

  Widget _phraseOpts() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text(tr('عدد الكلمات', 'Number of words')),
          Expanded(
            child: Slider(
              value: _wordsN,
              min: 3,
              max: 10,
              divisions: 7,
              label: '${_wordsN.round()}',
              onChanged: (v) {
                _wordsN = v;
                _generate();
              },
            ),
          ),
          Text('${_wordsN.round()}', style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        Wrap(spacing: 8, children: [
          Padding(padding: const EdgeInsetsDirectional.only(top: 8), child: Text(tr('الفاصل: ', 'Separator: '))),
          for (final s in const ['-', '.', '_', ' ', '#'])
            ChoiceChip(
              label: Text(s == ' ' ? tr('مسافة', 'Space') : s),
              selected: _sep == s,
              onSelected: (_) {
                _sep = s;
                _generate();
              },
            ),
        ]),
        _sw(tr('أول حرف كبير', 'Capitalize words'), _cap, (v) => _cap = v),
        _sw(t('أضف رقم في الآخر', 'أضف رقماً في النهاية', 'Add a number at the end'), _addNum, (v) => _addNum = v),
        NoteBox(
            t('عبارة المرور أسهل في الحفظ وقوية لو الكلمات كتيرة. كل كلمة من قائمة ${_words.length} كلمة = ${(math.log(_words.length) / math.ln2).toStringAsFixed(0)} بت.',
                'عبارة المرور أسهل في الحفظ وقوية إذا كثرت كلماتها. كل كلمة من قائمة ${_words.length} كلمة = ${(math.log(_words.length) / math.ln2).toStringAsFixed(0)} بت.',
                'Passphrases are easier to remember and strong with enough words. Each word from a ${_words.length}-word list = ${(math.log(_words.length) / math.ln2).toStringAsFixed(0)} bits.'),
            kind: NoteKind.tip),
      ]);

  Widget _sw(String label, bool v, void Function(bool) set) => SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: v,
        onChanged: (x) {
          set(x);
          _generate();
        },
      );

  // ---------- فحص كلمة سر المستخدم ----------
  Widget _checker() {
    final p = _check.text;
    final issues = <String>[];
    final good = <String>[];
    var pool = 0;
    final hasLo = RegExp(r'[a-z]').hasMatch(p), hasUp = RegExp(r'[A-Z]').hasMatch(p);
    final hasDi = RegExp(r'\d').hasMatch(p), hasAr = RegExp(r'[؀-ۿ]').hasMatch(p);
    final hasSy = RegExp(r'[^a-zA-Z\d؀-ۿ\s]').hasMatch(p);
    if (hasLo) pool += 26;
    if (hasUp) pool += 26;
    if (hasDi) pool += 10;
    if (hasSy) pool += 32;
    if (hasAr) pool += 36;
    if (p.contains(' ')) pool += 1;
    var bits = p.isEmpty || pool == 0 ? 0.0 : p.length * math.log(pool) / math.ln2;

    final lowerP = p.toLowerCase();
    if (p.isNotEmpty) {
      if (p.length < 8) issues.add(t('قصيرة شديد (أقل من 8)', 'قصيرة جداً (أقل من 8)', 'Too short (under 8)'));
      if (p.length >= 12) good.add(t('طولها كويس (${p.length})', 'طولها جيد (${p.length})', 'Good length (${p.length})'));
      final kinds = [hasLo, hasUp, hasDi, hasSy, hasAr].where((x) => x).length;
      if (kinds >= 3) good.add(t('فيها تنوّع ($kinds أنواع حروف)', 'فيها تنوّع ($kinds أنواع من الحروف)', 'Good variety ($kinds character types)'));
      if (kinds == 1) issues.add(t('نوع واحد بس من الحروف', 'نوع واحد فقط من الحروف', 'Only one character type'));
      if (_common.any((c) => lowerP == c || (c.length >= 5 && lowerP.contains(c)))) {
        issues.add(t('فيها كلمة سر مشهورة جداً — أول حاجة بيجربوها', 'تحتوي كلمة سر شائعة جداً — أول ما يُجرَّب', 'Contains a very common password — tried first'));
        bits = math.min(bits, 10);
      }
      if (RegExp(r'(.)\1\1').hasMatch(p)) {
        issues.add(t('حرف مكرر ورا بعض (زي aaa)', 'حرف مكرر متتالٍ (مثل aaa)', 'Repeated characters (like aaa)'));
        bits -= 6;
      }
      const seqs = ['0123456789', 'abcdefghijklmnopqrstuvwxyz', 'qwertyuiop', 'asdfghjkl', 'zxcvbnm', '9876543210'];
      for (final s in seqs) {
        var found = false;
        for (var i = 0; i + 4 <= s.length; i++) {
          if (lowerP.contains(s.substring(i, i + 4))) found = true;
        }
        if (found) {
          issues.add(t('فيها تسلسل سهل (زي 1234 أو qwer)', 'تحتوي تسلسلاً سهلاً (مثل 1234 أو qwer)', 'Contains an easy sequence (like 1234 or qwer)'));
          bits -= 10;
          break;
        }
      }
      if (RegExp(r'(19[5-9]\d|20[0-3]\d)').hasMatch(p)) {
        issues.add(t('فيها سنة (يمكن سنة ميلادك؟)', 'تحتوي سنة (ربما سنة ميلادك؟)', 'Contains a year (your birth year?)'));
        bits -= 5;
      }
      if (RegExp(r'0?(9|1)\d{8}').hasMatch(p)) {
        issues.add(t('شكلها فيها رقم تلفون — ده أول حاجة بيجربوها', 'يبدو أنها تحتوي رقم هاتف — وهذا أول ما يُجرَّب', 'Looks like it has a phone number — tried early'));
        bits -= 15;
      }
      if (RegExp(r'^\d+$').hasMatch(p)) issues.add(t('كلها أرقام بس', 'كلها أرقام فقط', 'Digits only'));
      if (RegExp(r'^[A-Z][a-z]+\d{1,4}[!@#.]?$').hasMatch(p)) {
        issues.add(t('النمط المشهور: كلمة + أرقام في الآخر', 'النمط الشائع: كلمة + أرقام في النهاية', 'Common pattern: word + digits at the end'));
        bits -= 8;
      }
    }
    bits = math.max(0, bits);
    final (lvl, col, frac) = _level(bits);
    return SCard(
      title: tr('اختبر كلمة سرك', 'Test your password'),
      icon: Icons.fact_check_rounded,
      color: SD.henna,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: _check,
          obscureText: !_show,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => setState(() {}),
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: t('أكتب كلمة السر هنا', 'اكتب كلمة السر هنا', 'Type a password here'),
            prefixIcon: const Icon(Icons.lock_rounded),
            suffixIcon: IconButton(icon: Icon(_show ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _show = !_show)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
            t('🔒 ما بنحفظها ولا بترسل لأي مكان — الفحص كلو في جهازك.', '🔒 لا نحفظها ولا تُرسل لأي مكان — الفحص كله في جهازك.',
                "🔒 Not stored or sent anywhere — checked entirely on your device."),
            style: const TextStyle(fontSize: 12)),
        if (p.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: frac, minHeight: 12, color: col, backgroundColor: col.withValues(alpha: .15)),
          ),
          const SizedBox(height: 8),
          InfoRow(tr('التقييم', 'Rating'), lvl, valueColor: col, icon: Icons.verified_rounded),
          InfoRow(tr('القوة التقديرية', 'Estimated strength'), '${bits.toStringAsFixed(0)} ${tr('بت', 'bits')}', icon: Icons.functions_rounded),
          InfoRow(tr('الطول', 'Length'), '${p.length} ${tr('حرف', 'chars')}', icon: Icons.straighten_rounded),
          InfoRow(tr('حروف صغيرة / كبيرة', 'Lower / upper'), '${hasLo ? '✓' : '✗'} / ${hasUp ? '✓' : '✗'}'),
          InfoRow(tr('أرقام / رموز / عربي', 'Digits / symbols / Arabic'), '${hasDi ? '✓' : '✗'} / ${hasSy ? '✓' : '✗'} / ${hasAr ? '✓' : '✗'}'),
          InfoRow(tr('زمن الكسر (جهاز قوي)', 'Crack time (strong GPU)'), _crack(bits, 1e10), icon: Icons.timer_rounded),
          for (final g in good) Padding(padding: const EdgeInsetsDirectional.only(top: 6), child: Text('✅ $g')),
          for (final i in issues) Padding(padding: const EdgeInsetsDirectional.only(top: 6), child: Text('⚠️ $i', style: const TextStyle(color: SD.henna))),
          NoteBox(
              t('ده تقدير تقريبي: المهاجمين بيستعملوا قواميس وأنماط ذكية، فالأحسن دايماً كلمة سر عشوائية من المولّد فوق.',
                  'هذا تقدير تقريبي: يستخدم المهاجمون قواميس وأنماطاً ذكية، فالأفضل دائماً كلمة سر عشوائية من المولّد أعلاه.',
                  'A rough estimate: attackers use dictionaries and smart patterns, so a random password from the generator above is always best.'),
              kind: NoteKind.warn),
        ],
      ]),
    );
  }
}
