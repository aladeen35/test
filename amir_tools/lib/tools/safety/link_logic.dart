/// فحص الروابط بدون إنترنت: قواعد تقديرية (Heuristics) فقط — ليست ضمانًا.
///
/// منطق Dart صافٍ (بدون Flutter) حتى يُختبر بسهولة. النصوص المعروضة تُبنى
/// في الواجهة من رموز العلامات [LinkFlag.code].
library;

enum LinkRisk { low, medium, high }

/// علامة واحدة مع وزنها في درجة الخطورة
class LinkFlag {
  final String code;
  final int weight;

  /// تفاصيل (اسم الموقع المقلَّد، الكلمات المشبوهة، الامتداد…)
  final String detail;
  const LinkFlag(this.code, this.weight, [this.detail = '']);
  @override
  String toString() => '$code($weight${detail.isEmpty ? '' : ': $detail'})';
}

class LinkReport {
  final String input;

  /// الرابط بعد التنظيف (كما فُهم)
  final String url;
  final bool valid;
  final String scheme;

  /// المضيف كما هو (بعد تحويل الأحرف الصغيرة)، ونسخته المفكوكة من Punycode
  final String host, hostUnicode;

  /// النطاق الحقيقي (المسجَّل) — الجزء الذي يحدد صاحب الموقع فعلًا
  final String domain;

  /// النطاقات الفرعية قبل النطاق الحقيقي (قد تكون فارغة)
  final String subdomains;
  final String tld;
  final bool isIp;
  final List<LinkFlag> flags;

  /// الجهة الرسمية إن كان النطاق ضمن قائمتنا المؤكدة (مثل google)
  final String? officialBrand;
  const LinkReport({
    required this.input,
    required this.url,
    required this.valid,
    required this.scheme,
    required this.host,
    required this.hostUnicode,
    required this.domain,
    required this.subdomains,
    required this.tld,
    required this.isIp,
    required this.flags,
    this.officialBrand,
  });

  int get score => flags.fold(0, (a, f) => a + f.weight);

  LinkRisk get risk {
    if (!valid) return LinkRisk.medium;
    if (score >= 40) return LinkRisk.high;
    if (score >= 15) return LinkRisk.medium;
    return LinkRisk.low;
  }

  bool has(String code) => flags.any((f) => f.code == code);
  LinkFlag? flag(String code) {
    for (final f in flags) {
      if (f.code == code) return f;
    }
    return null;
  }
}

/* ───────── البيانات ───────── */

/// النطاقات الرسمية المؤكدة لكل جهة (نطاقات مسجّلة فقط)
const brandDomains = <String, List<String>>{
  'whatsapp': ['whatsapp.com', 'whatsapp.net', 'wa.me'],
  'facebook': ['facebook.com', 'fb.com', 'fb.me', 'facebook.net', 'fbcdn.net', 'meta.com', 'messenger.com'],
  'instagram': ['instagram.com', 'instagr.am', 'cdninstagram.com'],
  'google': [
    'google.com', 'gmail.com', 'youtube.com', 'youtu.be', 'googleapis.com', 'gstatic.com', 'googleusercontent.com',
    'googlevideo.com', 'google.co.uk', 'google.com.sa', 'google.ae', 'google.com.eg', 'google.de', 'google.fr',
    'android.com', 'goo.gl', 'g.co',
  ],
  'gmail': ['gmail.com', 'google.com'],
  'youtube': ['youtube.com', 'youtu.be', 'google.com'],
  'paypal': ['paypal.com', 'paypal.me', 'paypalobjects.com'],
  'apple': ['apple.com', 'icloud.com', 'apple.co', 'mzstatic.com'],
  'icloud': ['icloud.com', 'apple.com'],
  'amazon': ['amazon.com', 'amazon.co.uk', 'amazon.de', 'amazon.fr', 'amazon.in', 'amazon.sa', 'amazon.ae', 'amazon.eg', 'amzn.to', 'amazonaws.com'],
  'microsoft': ['microsoft.com', 'live.com', 'outlook.com', 'office.com', 'microsoftonline.com', 'hotmail.com', 'windows.com', 'bing.com'],
  'outlook': ['outlook.com', 'live.com', 'microsoft.com', 'office.com'],
  'netflix': ['netflix.com'],
  'telegram': ['telegram.org', 't.me', 'telegram.me'],
  'twitter': ['twitter.com', 'x.com', 't.co'],
  'tiktok': ['tiktok.com'],
  // بنك الخرطوم (تطبيق بنكك)
  'bankofkhartoum': ['bankofkhartoum.com'],
  'bankak': ['bankofkhartoum.com'],
};

/// أسماء قصيرة لا تُفحص بالاحتواء (حتى لا تطابق كلمات عادية) بل كجزء مستقل فقط
const shortBrandTokens = <String, String>{'bok': 'bankofkhartoum', 'fb': 'facebook'};

/// الجهات التي نفحص انتحالها (أسماء طويلة كفاية حتى لا تطابق كلمات عادية)
const lookalikeBrands = [
  'whatsapp', 'facebook', 'instagram', 'google', 'gmail', 'youtube', 'paypal', 'apple', 'icloud', 'amazon', 'microsoft',
  'netflix', 'telegram', 'bankofkhartoum', 'bankak',
];

/// السماحية في مسافة التحرير حسب طول الاسم
int _tolerance(String b) => b.length <= 5 ? 0 : (b.length <= 7 ? 1 : 2);

/// خدمات تقصير الروابط (تخفي الوجهة الحقيقية)
const shorteners = {
  'bit.ly', 'bitly.com', 'tinyurl.com', 't.co', 'goo.gl', 'rebrand.ly', 'cutt.ly', 'is.gd', 'ow.ly', 'shorturl.at', 'buff.ly',
  'tiny.cc', 'rb.gy', 'v.gd', 'bl.ink', 't.ly', 'shorte.st', 'adf.ly', 'lnkd.in', 's.id', 'qrco.de', 'short.io', 'tiny.one',
  'clck.ru', 'u.to', 'x.co', 'soo.gd', 'bit.do', 'trib.al', 'urlz.fr', 'surl.li', 'gg.gg',
};

/// امتدادات نطاقات يكثر استخدامها في الاحتيال أو تُشبه امتدادات الملفات
const suspiciousTlds = {
  'zip', 'mov', 'tk', 'ml', 'ga', 'cf', 'gq', 'xyz', 'top', 'click', 'country', 'kim', 'work', 'link', 'loan', 'men', 'date',
  'faith', 'review', 'stream', 'racing', 'win', 'bid', 'cam', 'rest', 'icu', 'buzz', 'sbs', 'cfd', 'monster', 'quest', 'lol',
  'support', 'cyou', 'beauty', 'hair', 'mom', 'boats', 'autos', 'bond', 'help', 'live', 'online', 'site', 'website', 'shop', 'store',
};

/// كلمات تُستعمل كثيرًا في روابط التصيّد
const suspiciousKeywords = [
  'login', 'signin', 'logon', 'verify', 'verification', 'validate', 'update', 'secure', 'security', 'account', 'confirm', 'unlock',
  'suspend', 'suspended', 'password', 'wallet', 'gift', 'free', 'prize', 'winner', 'bonus', 'reward', 'claim', 'lottery', 'airdrop',
  'giveaway', 'promo', 'urgent', 'recover', 'refund', 'invoice', 'billing', 'payment', 'kyc', 'otp',
];

/// امتدادات ملفات خطرة لو نزلت من رابط
const dangerousFileExt = ['apk', 'exe', 'scr', 'bat', 'cmd', 'msi', 'jar', 'vbs', 'ps1', 'dll', 'xapk', 'apks'];

/// لواحق متعددة الأجزاء شائعة (نسخة مختصرة من قائمة اللواحق العامة)
const multiSuffixes = {
  'co.uk', 'org.uk', 'ac.uk', 'gov.uk', 'me.uk', 'ltd.uk', 'plc.uk', 'net.uk',
  'com.sa', 'net.sa', 'org.sa', 'gov.sa', 'edu.sa', 'med.sa', 'sch.sa',
  'com.sd', 'net.sd', 'org.sd', 'gov.sd', 'edu.sd', 'med.sd', 'tv.sd', 'info.sd',
  'com.eg', 'net.eg', 'org.eg', 'gov.eg', 'edu.eg', 'sci.eg',
  'co.ae', 'net.ae', 'org.ae', 'gov.ae', 'ac.ae', 'sch.ae',
  'com.qa', 'net.qa', 'org.qa', 'gov.qa', 'edu.qa', 'com.kw', 'net.kw', 'org.kw', 'gov.kw', 'edu.kw',
  'com.om', 'net.om', 'org.om', 'gov.om', 'co.om', 'com.bh', 'net.bh', 'org.bh', 'gov.bh', 'edu.bh',
  'com.jo', 'net.jo', 'org.jo', 'gov.jo', 'edu.jo', 'com.lb', 'net.lb', 'org.lb', 'gov.lb', 'edu.lb',
  'com.ly', 'net.ly', 'gov.ly', 'com.tr', 'net.tr', 'org.tr', 'gov.tr', 'edu.tr',
  'co.za', 'org.za', 'gov.za', 'ac.za', 'co.ke', 'or.ke', 'go.ke', 'ac.ke', 'com.ng', 'gov.ng', 'edu.ng', 'org.ng',
  'com.gh', 'gov.gh', 'edu.gh', 'com.et', 'gov.et', 'edu.et', 'co.ug', 'go.ug', 'ac.ug', 'co.tz', 'go.tz', 'ac.tz',
  'com.au', 'net.au', 'org.au', 'gov.au', 'edu.au', 'co.nz', 'org.nz', 'govt.nz', 'ac.nz',
  'co.in', 'net.in', 'org.in', 'gov.in', 'ac.in', 'co.jp', 'ne.jp', 'or.jp', 'go.jp', 'ac.jp',
  'com.br', 'net.br', 'org.br', 'gov.br', 'com.mx', 'gob.mx', 'com.ar', 'gob.ar', 'com.cn', 'net.cn', 'org.cn', 'gov.cn',
  'com.my', 'gov.my', 'com.sg', 'gov.sg', 'edu.sg', 'com.pk', 'gov.pk', 'edu.pk', 'com.ma', 'gov.ma', 'com.tn', 'gov.tn',
  'com.dz', 'gov.dz', 'com.iq', 'gov.iq', 'com.ye', 'gov.ye', 'com.sy', 'gov.sy', 'co.il', 'com.hk', 'gov.hk',
  'com.ru', 'co.kr', 'go.kr', 'com.tw', 'gov.tw', 'com.ua', 'gov.ua', 'com.pl', 'co.id', 'go.id', 'ac.id',
};

/* ───────── أدوات مساعدة ───────── */

/// يستخرج أول رابط من نص ملصوق (رسالة واتساب مثلًا)
String extractUrl(String text) {
  final s = text.trim();
  if (s.isEmpty) return '';
  final m = RegExp(r'''((?:https?|ftp|javascript|data|file|intent)://?\S+|www\.\S+)''', caseSensitive: false).firstMatch(s);
  String r;
  if (m != null) {
    r = m.group(1)!;
  } else {
    final tokens = s.split(RegExp(r'\s+'));
    r = tokens.firstWhere((x) => x.contains('.') && !x.startsWith('.') && !x.endsWith('.'), orElse: () => tokens.first);
  }
  // إزالة علامات الترقيم الملتصقة بالنهاية
  r = r.replaceFirst(RegExp(r'''[)\]}>,.;:!?،؛'"»«]+$'''), '');
  r = r.replaceFirst(RegExp(r'''^[(\[{<'"«»]+'''), '');
  return r;
}

/// فك ترميز Punycode (RFC 3492) لجزء واحد بدون «xn--». يرجع null عند الخطأ.
String? punycodeDecode(String input) {
  const base = 36, tMin = 1, tMax = 26, skew = 38, damp = 700;
  int adapt(int delta, int numPoints, bool first) {
    delta = first ? delta ~/ damp : delta ~/ 2;
    delta += delta ~/ numPoints;
    var k = 0;
    while (delta > ((base - tMin) * tMax) ~/ 2) {
      delta ~/= base - tMin;
      k += base;
    }
    return k + ((base - tMin + 1) * delta) ~/ (delta + skew);
  }

  int digitOf(int c) {
    if (c >= 48 && c <= 57) return c - 22;
    if (c >= 65 && c <= 90) return c - 65;
    if (c >= 97 && c <= 122) return c - 97;
    return -1;
  }

  var n = 128, i = 0, bias = 72;
  final out = <int>[];
  final b = input.lastIndexOf('-');
  if (b > 0) {
    for (final c in input.substring(0, b).codeUnits) {
      if (c >= 0x80) return null;
      out.add(c);
    }
  }
  var idx = b > 0 ? b + 1 : 0;
  while (idx < input.length) {
    final oldI = i;
    var w = 1;
    for (var k = base;; k += base) {
      if (idx >= input.length) return null;
      final d = digitOf(input.codeUnitAt(idx++));
      if (d < 0) return null;
      i += d * w;
      final t = k <= bias ? tMin : (k >= bias + tMax ? tMax : k - bias);
      if (d < t) break;
      w *= base - t;
      if (w > 0x7fffffff) return null;
    }
    bias = adapt(i - oldI, out.length + 1, oldI == 0);
    n += i ~/ (out.length + 1);
    i %= out.length + 1;
    if (n > 0x10FFFF) return null;
    out.insert(i, n);
    i++;
  }
  return String.fromCharCodes(out);
}

/// فك اسم مضيف كامل (كل جزء يبدأ بـ xn--)
String decodeHost(String host) => host.split('.').map((l) {
      if (l.startsWith('xn--')) return punycodeDecode(l.substring(4)) ?? l;
      return l;
    }).join('.');

/// نوع الكتابة لحرف واحد
String scriptOf(int c) {
  if ((c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A)) return 'latin';
  if (c >= 0x30 && c <= 0x39) return 'digit';
  if (c == 0x2D || c == 0x5F) return 'common';
  if (c >= 0x00C0 && c <= 0x024F) return 'latin';
  if (c >= 0x1E00 && c <= 0x1EFF) return 'latin';
  if (c >= 0x0250 && c <= 0x02AF) return 'latin'; // IPA (ɡ ɑ…) تشبه اللاتينية
  if (c >= 0x0370 && c <= 0x03FF) return 'greek';
  if (c >= 0x0400 && c <= 0x052F) return 'cyrillic';
  if ((c >= 0x0600 && c <= 0x06FF) || (c >= 0x0750 && c <= 0x077F) || (c >= 0x08A0 && c <= 0x08FF) || (c >= 0xFB50 && c <= 0xFDFF) || (c >= 0xFE70 && c <= 0xFEFF)) {
    return 'arabic';
  }
  if (c >= 0x0530 && c <= 0x058F) return 'armenian';
  if (c >= 0x0590 && c <= 0x05FF) return 'hebrew';
  if (c >= 0x4E00 && c <= 0x9FFF) return 'han';
  if (c >= 0xFF00 && c <= 0xFFEF) return 'fullwidth';
  return 'other';
}

/// الكتابات المستعملة في جزء من النطاق (بدون الأرقام والشرطة)
Set<String> scriptsIn(String label) => label.runes.map(scriptOf).where((s) => s != 'digit' && s != 'common').toSet();

/// أحرف تشبه اللاتينية (تُستعمل لانتحال الأسماء)
const homoglyphs = <String, String>{
  // سيريلية
  'а': 'a', 'в': 'b', 'е': 'e', 'ё': 'e', 'к': 'k', 'м': 'm', 'н': 'h', 'о': 'o', 'р': 'p', 'с': 'c', 'т': 't', 'у': 'y',
  'х': 'x', 'ѕ': 's', 'і': 'i', 'ї': 'i', 'ј': 'j', 'ԁ': 'd', 'ӏ': 'l', 'ԛ': 'q', 'ԝ': 'w', 'һ': 'h', 'ɡ': 'g', 'ս': 'u',
  // يونانية
  'α': 'a', 'β': 'b', 'ε': 'e', 'ι': 'i', 'κ': 'k', 'ν': 'v', 'ο': 'o', 'ρ': 'p', 'τ': 't', 'υ': 'u', 'χ': 'x', 'ω': 'w',
  // عربية تشبه حروفًا لاتينية/أرقامًا
  'ا': 'l', '٥': 'o', '٠': 'o', '١': 'l', 'ه': 'o',
  // لاتينية بعلامات
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'í': 'i', 'ì': 'i',
  'î': 'i', 'ï': 'i', 'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ø': 'o', 'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n', 'ý': 'y', 'ł': 'l', 'ı': 'i', 'ś': 's', 'ż': 'z', 'ź': 'z', 'ğ': 'g', 'ş': 's',
};

/// «الهيكل»: تحويل الأحرف المتشابهة إلى أصلها اللاتيني (paypa1 ← paypal، аpple ← apple)
String skeleton(String s) {
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final ch = String.fromCharCode(r);
    b.write(homoglyphs[ch] ?? ch);
  }
  return b
      .toString()
      .replaceAll('0', 'o')
      .replaceAll('1', 'l')
      .replaceAll('3', 'e')
      .replaceAll('5', 's')
      .replaceAll('rn', 'm')
      .replaceAll('vv', 'w')
      .replaceAll('|', 'l');
}

/// مسافة التحرير (Levenshtein)
int editDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0);
    cur[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      final v1 = prev[j] + 1, v2 = cur[j - 1] + 1, v3 = prev[j - 1] + cost;
      cur[j] = v1 < v2 ? (v1 < v3 ? v1 : v3) : (v2 < v3 ? v2 : v3);
    }
    prev = cur;
  }
  return prev[b.length];
}

/// النطاق المسجَّل (eTLD+1) بطريقة تقريبية
String registrableDomain(String host) {
  final labels = host.split('.').where((l) => l.isNotEmpty).toList();
  if (labels.length <= 2) return labels.join('.');
  final last2 = labels.sublist(labels.length - 2).join('.');
  if (multiSuffixes.contains(last2)) return labels.sublist(labels.length - 3).join('.');
  return last2;
}

bool _isIpv4(String h) {
  final m = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$').firstMatch(h);
  if (m == null) return false;
  for (var i = 1; i <= 4; i++) {
    if (int.parse(m.group(i)!) > 255) return false;
  }
  return true;
}

/// عنوان IP مخفي بصيغة رقم واحد أو ست عشري (http://3232235777 أو 0x7f000001)
bool _isObfuscatedIp(String h) => RegExp(r'^(0x[0-9a-f]+|\d{8,10})$').hasMatch(h) || RegExp(r'^(0x[0-9a-f]{1,2}|0\d+)(\.(0x[0-9a-f]{1,2}|\d+)){3}$').hasMatch(h);

String? officialBrandOf(String domain) {
  for (final e in brandDomains.entries) {
    if (e.value.contains(domain)) return e.key;
  }
  return null;
}

/* ───────── التحليل ───────── */

LinkReport analyzeLink(String rawInput) {
  final input = rawInput.trim();
  var url = extractUrl(input);
  final flags = <LinkFlag>[];
  LinkReport bad() => LinkReport(
      input: input, url: url, valid: false, scheme: '', host: '', hostUnicode: '', domain: '', subdomains: '', tld: '', isIp: false, flags: flags);
  if (url.isEmpty) return bad();

  // المخطط
  var scheme = '';
  var rest = url;
  final sm = RegExp(r'^([a-zA-Z][a-zA-Z0-9+.\-]*):(//)?').firstMatch(url);
  if (sm != null && (sm.group(2) != null || const ['javascript', 'data', 'mailto', 'tel', 'intent', 'file'].contains(sm.group(1)!.toLowerCase()))) {
    scheme = sm.group(1)!.toLowerCase();
    rest = url.substring(sm.end);
  }
  if (const ['javascript', 'data', 'file', 'vbscript'].contains(scheme)) {
    flags.add(LinkFlag('dangerous_scheme', 60, scheme));
    return LinkReport(
        input: input, url: url, valid: true, scheme: scheme, host: '', hostUnicode: '', domain: '', subdomains: '', tld: '', isIp: false, flags: flags);
  }
  if (scheme == 'mailto' || scheme == 'tel') return bad();
  if (scheme.isNotEmpty && scheme != 'http' && scheme != 'https') flags.add(LinkFlag('odd_scheme', 15, scheme));
  if (scheme == 'http') flags.add(const LinkFlag('http', 15));
  if (scheme.isEmpty) flags.add(const LinkFlag('no_scheme', 0));

  // الجهة (authority) حتى أول / ? #
  final endIdx = rest.indexOf(RegExp(r'[/?#\\]'));
  var authority = endIdx < 0 ? rest : rest.substring(0, endIdx);
  final pathPart = endIdx < 0 ? '' : rest.substring(endIdx);
  if (authority.contains('@')) {
    final userInfo = authority.substring(0, authority.lastIndexOf('@'));
    flags.add(LinkFlag('at_sign', 35, userInfo.length > 40 ? '${userInfo.substring(0, 40)}…' : userInfo));
    authority = authority.substring(authority.lastIndexOf('@') + 1);
  }
  var host = authority;
  if (host.startsWith('[')) {
    // IPv6
    final close = host.indexOf(']');
    final h = close > 0 ? host.substring(0, close + 1) : host;
    flags.add(const LinkFlag('ip_host', 30));
    _commonChecks(url, pathPart, flags);
    return LinkReport(
        input: input, url: url, valid: true, scheme: scheme, host: h, hostUnicode: h, domain: h, subdomains: '', tld: '', isIp: true, flags: flags);
  }
  final pm = RegExp(r':(\d*)$').firstMatch(host);
  if (pm != null) {
    final port = int.tryParse(pm.group(1)!);
    host = host.substring(0, pm.start);
    if (port != null && port != 80 && port != 443) flags.add(LinkFlag('port', 10, '$port'));
  }
  host = host.toLowerCase().replaceAll(RegExp(r'\.+$'), '');
  // نقاط عربية/كاملة العرض تُعامل كنقطة
  host = host.replaceAll(RegExp('[。．｡]'), '.');
  if (host.isEmpty) return bad();

  if (_isIpv4(host) || _isObfuscatedIp(host)) {
    flags.add(LinkFlag('ip_host', 30, host));
    _commonChecks(url, pathPart, flags);
    return LinkReport(
        input: input, url: url, valid: true, scheme: scheme, host: host, hostUnicode: host, domain: host, subdomains: '', tld: '', isIp: true, flags: flags);
  }
  if (!host.contains('.') || host.startsWith('.') || host.contains('..') || host.contains(' ')) return bad();

  // Punycode والكتابات المختلطة
  final hostU = decodeHost(host);
  if (host.split('.').any((l) => l.startsWith('xn--'))) {
    // نطاق بحروف غير لاتينية لكنه «يبدو» لاتينيًا (аррӏе) أخطر من نطاق عربي حقيقي
    final looksLatin = hostU.split('.').any((l) => l.runes.any((r) => r > 0x7F) && RegExp(r'^[a-z0-9\-]+$').hasMatch(skeleton(l)));
    final mixedAny = hostU.split('.').any((l) => scriptsIn(l).length > 1);
    flags.add(LinkFlag('punycode', looksLatin || mixedAny ? 30 : 10, hostU));
  }
  final hasNonAscii = hostU.runes.any((r) => r > 0x7F);
  if (hasNonAscii) {
    final mixed = hostU.split('.').where((l) => scriptsIn(l).length > 1).toList();
    if (mixed.isNotEmpty) {
      flags.add(LinkFlag('mixed_script', 40, mixed.join(', ')));
    } else if (!host.contains('xn--')) {
      flags.add(LinkFlag('non_ascii', 10, hostU));
    }
  }

  final domainA = registrableDomain(host);
  final domainU = decodeHost(domainA);
  final labels = host.split('.');
  final domLabels = domainA.split('.').length;
  final subs = labels.length > domLabels ? labels.sublist(0, labels.length - domLabels).join('.') : '';
  final tld = labels.last;
  final official = officialBrandOf(domainA);

  if (shorteners.contains(domainA) || shorteners.contains(host)) flags.add(LinkFlag('shortener', 20, domainA));
  if (suspiciousTlds.contains(tld)) flags.add(LinkFlag('tld', 15, '.${decodeHost(tld)}'));
  final subCount = subs.isEmpty ? 0 : subs.split('.').where((s) => s != 'www').length;
  if (subCount >= 3) flags.add(LinkFlag('many_subdomains', 15, '$subCount'));
  final mainLabel = domainU.split('.').first;
  if ('-'.allMatches(mainLabel).length >= 2) flags.add(LinkFlag('hyphens', 10, mainLabel));
  if (RegExp(r'\d').hasMatch(mainLabel) && RegExp(r'[a-z]').hasMatch(mainLabel) && mainLabel.length > 12) flags.add(LinkFlag('digits_in_name', 5, mainLabel));

  // انتحال الجهات المعروفة
  if (official == null) {
    final brand = _lookalike(domainU, subs, hostU);
    if (brand != null) flags.add(LinkFlag(brand.$2, brand.$2 == 'brand_in_sub' ? 40 : 45, brand.$1));
  }

  if (official == null && !flags.any((f) => f.code.startsWith('brand_'))) {
    final pl = pathPart.toLowerCase();
    for (final b in lookalikeBrands) {
      if (b.length >= 6 && pl.contains(b)) {
        flags.add(LinkFlag('brand_in_path', 10, b));
        break;
      }
    }
  }

  _commonChecks(url, pathPart, flags, official: official != null);

  return LinkReport(
    input: input,
    url: url,
    valid: true,
    scheme: scheme,
    host: host,
    hostUnicode: hostU,
    domain: domainU,
    subdomains: subs.isEmpty ? '' : decodeHost(subs),
    tld: decodeHost(tld),
    isIp: false,
    flags: flags,
    officialBrand: official,
  );
}

/// (اسم الجهة، نوع العلامة) أو null
(String, String)? _lookalike(String domainU, String subs, String hostU) {
  final main = domainU.split('.').first;
  final sk = skeleton(main);
  final tokens = sk.split(RegExp(r'[^a-z0-9]+')).where((x) => x.isNotEmpty).toList();
  // 1) الاسم الرئيسي يحتوي اسم جهة أو يشبهه
  for (final b in lookalikeBrands) {
    if (sk == b) return (b, 'brand_lookalike');
    if (b.length >= 6 && sk.contains(b)) return (b, 'brand_lookalike');
    final tol = _tolerance(b);
    if (tol == 0) {
      if (tokens.contains(b)) return (b, 'brand_lookalike');
      continue;
    }
    for (final tk in {sk, ...tokens}) {
      if ((tk.length - b.length).abs() <= tol && editDistance(tk, b) <= tol) return (b, 'brand_lookalike');
    }
  }
  if (tokens.length > 1) {
    for (final tk in tokens) {
      final b = shortBrandTokens[tk];
      if (b != null) return (b, 'brand_lookalike');
    }
  }
  // 2) اسم الجهة في النطاق الفرعي أو كنطاق كامل داخل الفرعي (paypal.com.evil.xyz)
  if (subs.isNotEmpty) {
    final ss = skeleton(subs);
    final stokens = ss.split(RegExp(r'[^a-z0-9]+')).where((x) => x.isNotEmpty).toSet();
    for (final b in lookalikeBrands) {
      if (b.length >= 6 ? ss.contains(b) : stokens.contains(b)) return (b, 'brand_in_sub');
    }
    for (final tk in stokens) {
      final b = shortBrandTokens[tk];
      if (b != null) return (b, 'brand_in_sub');
    }
  }
  return null;
}

void _commonChecks(String url, String path, List<LinkFlag> flags, {bool official = false}) {
  final lower = url.toLowerCase();
  if (url.length > 200) {
    flags.add(LinkFlag('long_url', 15, '${url.length}'));
  } else if (url.length > 100) {
    flags.add(LinkFlag('long_url', 8, '${url.length}'));
  }
  // كلمات التصيّد (أقل وزنًا في المواقع الرسمية)
  final tokens = lower.split(RegExp(r'[^a-z0-9]+')).where((x) => x.isNotEmpty).toList();
  final found = <String>{};
  for (final k in suspiciousKeywords) {
    for (final tk in tokens) {
      if (tk == k || (k.length >= 5 && tk.contains(k))) {
        found.add(k);
        break;
      }
    }
  }
  if (found.isNotEmpty && !official) {
    final w = (found.length * 8).clamp(8, 24);
    flags.add(LinkFlag('keywords', w, found.take(6).join(', ')));
  }
  // ملف تنفيذي/تطبيق
  final p = path.split(RegExp(r'[?#]')).first.toLowerCase();
  final em = RegExp(r'\.([a-z0-9]{2,5})$').firstMatch(p);
  if (em != null && dangerousFileExt.contains(em.group(1))) flags.add(LinkFlag('file_download', 30, '.${em.group(1)}'));
  // إعادة توجيه مخفية داخل الرابط
  if (RegExp(r'[?&](url|redirect|redirect_uri|next|goto|target|dest|continue)=(https?|%68%74%74%70)', caseSensitive: false).hasMatch(url)) {
    flags.add(const LinkFlag('redirect_param', 10));
  }
  if ('%'.allMatches(url).length > 10) flags.add(const LinkFlag('encoded', 8));
}
