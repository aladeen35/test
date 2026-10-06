import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    if (bits < 28) return ('ضعيفة شديد', SD.red, .12);
    if (bits < 36) return ('ضعيفة', SD.henna, .3);
    if (bits < 60) return ('نص نص', SD.gold, .55);
    if (bits < 80) return ('قوية', SD.green, .8);
    return ('قوية شديد 💪', SD.teal, 1);
  }

  /// متوسط زمن الكسر = نص مساحة البحث ÷ المحاولات في الثانية
  static String _crack(double bits, double perSec) => humanTime(math.pow(2, bits - 1) / perSec);

  Widget _crackTable(double bits) => Column(children: [
        InfoRow('هجوم عبر الإنترنت (100 محاولة/ث)', _crack(bits, 100), icon: Icons.public_rounded, hint: 'موقع ما بيقفل الحساب بعد المحاولات الغلط'),
        InfoRow('جهاز عادي، تشفير قوي (10 آلاف/ث)', _crack(bits, 1e4), icon: Icons.computer_rounded, hint: 'لو اتسرقت قاعدة بيانات محمية كويس'),
        InfoRow('كرت شاشة قوي (10 مليار/ث)', _crack(bits, 1e10), icon: Icons.memory_rounded, hint: 'تشفير ضعيف زي MD5'),
        InfoRow('مزرعة أجهزة ضخمة (تريليون/ث)', _crack(bits, 1e12), icon: Icons.dns_rounded),
      ]);

  @override
  Widget build(BuildContext context) {
    final (lvl, col, frac) = _level(_bits);
    return ToolList(children: [
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, icon: Icon(Icons.password_rounded), label: Text('حروف عشوائية')),
          ButtonSegment(value: true, icon: Icon(Icons.short_text_rounded), label: Text('عبارة مرور')),
        ],
        selected: {_phrase},
        onSelectionChanged: (v) {
          _phrase = v.first;
          _generate();
        },
      ),
      const SizedBox(height: 14),
      ResultHero(
        label: 'كلمة السر الجديدة (اضغط ضغطة طويلة للنسخ)',
        value: _pw.isEmpty ? '—' : _pw,
        sub: '${_bits.toStringAsFixed(0)} بت عشوائية • $lvl',
        colors: [col, SD.coffee],
      ),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () => copyText(_pw), icon: const Icon(Icons.copy_rounded), label: const Text('انسخ'))),
        const SizedBox(width: 10),
        Expanded(child: FilledButton.icon(onPressed: _generate, icon: const Icon(Icons.casino_rounded), label: const Text('ولّد تاني'))),
      ]),
      const SizedBox(height: 14),
      SCard(
        title: 'الإعدادات',
        icon: Icons.tune_rounded,
        color: SD.gold,
        child: _phrase ? _phraseOpts() : _charOpts(),
      ),
      SCard(
        title: 'قوتها كم؟',
        icon: Icons.shield_rounded,
        color: col,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: frac, minHeight: 12, color: col, backgroundColor: col.withValues(alpha: .15)),
          ),
          const SizedBox(height: 10),
          StatGrid([
            StatChip('${_pw.length}', 'طول', color: SD.nile, icon: Icons.straighten_rounded),
            StatChip(_bits.toStringAsFixed(0), 'بت إنتروبي', color: SD.purple, icon: Icons.functions_rounded),
            StatChip(lvl, 'التقييم', color: col, icon: Icons.verified_rounded),
          ]),
          const SizedBox(height: 8),
          const Text('الزمن المتوقع عشان زول يخمّنها:', style: TextStyle(fontWeight: FontWeight.w700)),
          _crackTable(_bits),
        ]),
      ),
      _checker(),
      const NoteBox('كلمات السر دي بتتولّد في جهازك بمولّد عشوائي آمن (Random.secure)، وما بنحفظها ولا بنرسلها لأي مكان. احفظها في مكان آمن.', kind: NoteKind.info),
      const NoteBox('نصايح: ما تكرر نفس كلمة السر في أكتر من موقع، وفعّل التحقق بخطوتين في الواتساب والفيسبوك والبنك.', kind: NoteKind.tip),
    ]);
  }

  Widget _charOpts() => Column(children: [
        Row(children: [
          const Text('الطول'),
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
        _sw('حروف صغيرة (a-z)', _lo, (v) => _lo = v),
        _sw('حروف كبيرة (A-Z)', _up, (v) => _up = v),
        _sw('أرقام (0-9)', _di, (v) => _di = v),
        _sw('رموز (!@#…)', _sy, (v) => _sy = v),
        _sw('شيل الحروف المتشابهة (I l 1 O 0)', _noAmb, (v) => _noAmb = v),
      ]);

  Widget _phraseOpts() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Text('عدد الكلمات'),
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
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('الفاصل: ')),
          for (final s in const ['-', '.', '_', ' ', '#'])
            ChoiceChip(
              label: Text(s == ' ' ? 'مسافة' : s),
              selected: _sep == s,
              onSelected: (_) {
                _sep = s;
                _generate();
              },
            ),
        ]),
        _sw('أول حرف كبير', _cap, (v) => _cap = v),
        _sw('أضف رقم في الآخر', _addNum, (v) => _addNum = v),
        NoteBox('عبارة المرور أسهل في الحفظ وقوية لو الكلمات كتيرة. كل كلمة من قائمة ${_words.length} كلمة = ${(math.log(_words.length) / math.ln2).toStringAsFixed(0)} بت.', kind: NoteKind.tip),
      ]);

  Widget _sw(String t, bool v, void Function(bool) set) => SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(t),
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
      if (p.length < 8) issues.add('قصيرة شديد (أقل من 8)');
      if (p.length >= 12) good.add('طولها كويس (${p.length})');
      final kinds = [hasLo, hasUp, hasDi, hasSy, hasAr].where((x) => x).length;
      if (kinds >= 3) good.add('فيها تنوّع ($kinds أنواع حروف)');
      if (kinds == 1) issues.add('نوع واحد بس من الحروف');
      if (_common.any((c) => lowerP == c || (c.length >= 5 && lowerP.contains(c)))) {
        issues.add('فيها كلمة سر مشهورة جداً — أول حاجة بيجربوها');
        bits = math.min(bits, 10);
      }
      if (RegExp(r'(.)\1\1').hasMatch(p)) {
        issues.add('حرف مكرر ورا بعض (زي aaa)');
        bits -= 6;
      }
      const seqs = ['0123456789', 'abcdefghijklmnopqrstuvwxyz', 'qwertyuiop', 'asdfghjkl', 'zxcvbnm', '9876543210'];
      for (final s in seqs) {
        var found = false;
        for (var i = 0; i + 4 <= s.length; i++) {
          if (lowerP.contains(s.substring(i, i + 4))) found = true;
        }
        if (found) {
          issues.add('فيها تسلسل سهل (زي 1234 أو qwer)');
          bits -= 10;
          break;
        }
      }
      if (RegExp(r'(19[5-9]\d|20[0-3]\d)').hasMatch(p)) {
        issues.add('فيها سنة (يمكن سنة ميلادك؟)');
        bits -= 5;
      }
      if (RegExp(r'0?(9|1)\d{8}').hasMatch(p)) {
        issues.add('شكلها فيها رقم تلفون — ده أول حاجة بيجربوها');
        bits -= 15;
      }
      if (RegExp(r'^\d+$').hasMatch(p)) issues.add('كلها أرقام بس');
      if (RegExp(r'^[A-Z][a-z]+\d{1,4}[!@#.]?$').hasMatch(p)) {
        issues.add('النمط المشهور: كلمة + أرقام في الآخر');
        bits -= 8;
      }
    }
    bits = math.max(0, bits);
    final (lvl, col, frac) = _level(bits);
    return SCard(
      title: 'اختبر كلمة سرك',
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
            labelText: 'أكتب كلمة السر هنا',
            prefixIcon: const Icon(Icons.lock_rounded),
            suffixIcon: IconButton(icon: Icon(_show ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _show = !_show)),
          ),
        ),
        const SizedBox(height: 6),
        const Text('🔒 ما بنحفظها ولا بترسل لأي مكان — الفحص كلو في جهازك.', style: TextStyle(fontSize: 12)),
        if (p.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: frac, minHeight: 12, color: col, backgroundColor: col.withValues(alpha: .15)),
          ),
          const SizedBox(height: 8),
          InfoRow('التقييم', lvl, valueColor: col, icon: Icons.verified_rounded),
          InfoRow('القوة التقديرية', '${bits.toStringAsFixed(0)} بت', icon: Icons.functions_rounded),
          InfoRow('الطول', '${p.length} حرف', icon: Icons.straighten_rounded),
          InfoRow('حروف صغيرة / كبيرة', '${hasLo ? '✓' : '✗'} / ${hasUp ? '✓' : '✗'}'),
          InfoRow('أرقام / رموز / عربي', '${hasDi ? '✓' : '✗'} / ${hasSy ? '✓' : '✗'} / ${hasAr ? '✓' : '✗'}'),
          InfoRow('زمن الكسر (جهاز قوي)', _crack(bits, 1e10), icon: Icons.timer_rounded),
          for (final g in good) Padding(padding: const EdgeInsets.only(top: 6), child: Text('✅ $g')),
          for (final i in issues) Padding(padding: const EdgeInsets.only(top: 6), child: Text('⚠️ $i', style: const TextStyle(color: SD.henna))),
          const NoteBox('ده تقدير تقريبي: المهاجمين بيستعملوا قواميس وأنماط ذكية، فالأحسن دايماً كلمة سر عشوائية من المولّد فوق.', kind: NoteKind.warn),
        ],
      ]),
    );
  }
}
