import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

// ═══════════════════════════════════════════════════════════════════
//  منطق الزخرفة (دوال صافية قابلة للاختبار — كل شيء على الجهاز)
// ═══════════════════════════════════════════════════════════════════

final _arLetterRe = RegExp('[ء-يٱ-ۓۺ-ۼ]');
final _latinRe = RegExp('[A-Za-z0-9]');

bool hasArabic(String s) => _arLetterRe.hasMatch(s);
bool hasLatin(String s) => _latinRe.hasMatch(s);

/// يحوّل النص بخريطة أكواد: الأحرف الكبيرة/الصغيرة/الأرقام من نقطة بداية،
/// مع استثناءات (الثقوب) في كتلة الحروف الرياضية. ما ليس في الخريطة يبقى كما هو.
class MathAlpha {
  final int? upper, lower, digit;
  final Map<String, int> holes;
  const MathAlpha({this.upper, this.lower, this.digit, this.holes = const {}});

  String apply(String s) {
    final b = StringBuffer();
    for (final r in s.runes) {
      final ch = String.fromCharCode(r);
      final h = holes[ch];
      if (h != null) {
        b.writeCharCode(h);
      } else if (r >= 0x41 && r <= 0x5A && upper != null) {
        b.writeCharCode(upper! + r - 0x41);
      } else if (r >= 0x61 && r <= 0x7A && lower != null) {
        b.writeCharCode(lower! + r - 0x61);
      } else if (r >= 0x30 && r <= 0x39 && digit != null) {
        b.writeCharCode(digit! + r - 0x30);
      } else {
        b.writeCharCode(r);
      }
    }
    return b.toString();
  }
}

const mathBold = MathAlpha(upper: 0x1D400, lower: 0x1D41A, digit: 0x1D7CE);
const mathItalic = MathAlpha(upper: 0x1D434, lower: 0x1D44E, holes: {'h': 0x210E});
const mathBoldItalic = MathAlpha(upper: 0x1D468, lower: 0x1D482);
const mathScript = MathAlpha(
  upper: 0x1D49C,
  lower: 0x1D4B6,
  holes: {
    'B': 0x212C, 'E': 0x2130, 'F': 0x2131, 'H': 0x210B, 'I': 0x2110, 'L': 0x2112, 'M': 0x2133, 'R': 0x211B, //
    'e': 0x212F, 'g': 0x210A, 'o': 0x2134,
  },
);
const mathBoldScript = MathAlpha(upper: 0x1D4D0, lower: 0x1D4EA);
const mathFraktur = MathAlpha(upper: 0x1D504, lower: 0x1D51E, holes: {'C': 0x212D, 'H': 0x210C, 'I': 0x2111, 'R': 0x211C, 'Z': 0x2128});
const mathBoldFraktur = MathAlpha(upper: 0x1D56C, lower: 0x1D586);
const mathDouble = MathAlpha(upper: 0x1D538, lower: 0x1D552, digit: 0x1D7D8, holes: {'C': 0x2102, 'H': 0x210D, 'N': 0x2115, 'P': 0x2119, 'Q': 0x211A, 'R': 0x211D, 'Z': 0x2124});
const mathSans = MathAlpha(upper: 0x1D5A0, lower: 0x1D5BA, digit: 0x1D7E2);
const mathSansBold = MathAlpha(upper: 0x1D5D4, lower: 0x1D5EE, digit: 0x1D7EC);
const mathSansItalic = MathAlpha(upper: 0x1D608, lower: 0x1D622);
const mathSansBoldItalic = MathAlpha(upper: 0x1D63C, lower: 0x1D656);
const mathMono = MathAlpha(upper: 0x1D670, lower: 0x1D68A, digit: 0x1D7F6);
const fullwidth = MathAlpha(upper: 0xFF21, lower: 0xFF41, digit: 0xFF10);

/// حروف داخل دائرة: Ⓐ ⓐ ① ⓪
String circled(String s) => _mapRunes(s, (r) {
  if (r >= 0x41 && r <= 0x5A) return 0x24B6 + r - 0x41;
  if (r >= 0x61 && r <= 0x7A) return 0x24D0 + r - 0x61;
  if (r == 0x30) return 0x24EA;
  if (r >= 0x31 && r <= 0x39) return 0x2460 + r - 0x31;
  return r;
});

/// دائرة سالبة: 🅐 (حروف كبيرة فقط) و ⓿ ❶…❾
String negCircled(String s) => _mapRunes(s, (r) {
  final u = _up(r);
  if (u >= 0x41 && u <= 0x5A) return 0x1F150 + u - 0x41;
  if (r == 0x30) return 0x24FF;
  if (r >= 0x31 && r <= 0x39) return 0x2776 + r - 0x31;
  return r;
});

/// مربعات: 🄰 (حروف كبيرة فقط)
String squared(String s) => _mapRunes(s, (r) {
  final u = _up(r);
  return u >= 0x41 && u <= 0x5A ? 0x1F130 + u - 0x41 : r;
});

/// مربعات سالبة: 🅰
String negSquared(String s) => _mapRunes(s, (r) {
  final u = _up(r);
  return u >= 0x41 && u <= 0x5A ? 0x1F170 + u - 0x41 : r;
});

String fullwidthText(String s) => fullwidth.apply(s).replaceAll(' ', '　');

const _smallCaps = 'ᴀʙᴄᴅᴇꜰɢʜɪᴊᴋʟᴍɴᴏᴘǫʀꜱᴛᴜᴠᴡxʏᴢ';
String smallCaps(String s) => _mapRunes(s, (r) {
  final l = r >= 0x41 && r <= 0x5A ? r + 32 : r;
  return l >= 0x61 && l <= 0x7A ? _smallCaps.runes.elementAt(l - 0x61) : r;
});

const _flipLower = 'ɐqɔpǝɟƃɥᴉɾʞlɯuodbɹsʇnʌʍxʎz';
const _flipUpper = {
  'A': '∀', 'B': 'ᗺ', 'C': 'Ɔ', 'D': 'ᗡ', 'E': 'Ǝ', 'F': 'Ⅎ', 'G': '⅁', 'J': 'ſ', 'K': 'ʞ', 'L': '˥', 'M': 'W', 'P': 'Ԁ', //
  'Q': 'Ό', 'R': 'ᴚ', 'T': '┴', 'U': '∩', 'V': 'Λ', 'W': 'M', 'Y': '⅄',
};
const _flipOther = {
  '1': 'Ɩ', '2': 'ᄅ', '3': 'Ɛ', '4': 'ㄣ', '5': 'ϛ', '6': '9', '7': 'ㄥ', '9': '6', //
  '.': '˙', ',': "'", "'": ',', '?': '¿', '!': '¡', '(': ')', ')': '(', '[': ']', ']': '[', '{': '}', '}': '{', '<': '>', '>': '<', '_': '‾', '&': '⅋', '"': '„',
};

/// نص مقلوب: يُعكس الترتيب وتُقلب الحروف
String upsideDown(String s) {
  final b = StringBuffer();
  for (final ch in _graphemes(s).reversed) {
    final r = ch.codeUnitAt(0);
    if (ch.length == 1 && r >= 0x61 && r <= 0x7A) {
      b.write(_flipLower[r - 0x61]);
    } else {
      b.write(_flipUpper[ch] ?? _flipOther[ch] ?? ch);
    }
  }
  return b.toString();
}

/// يضيف علامة مُركّبة (مثل خط الشطب U+0336) بعد كل حرف ظاهر
String combining(String s, String mark) {
  final b = StringBuffer();
  for (final r in s.runes) {
    b.writeCharCode(r);
    if (r != 0x0A) b.write(mark);
  }
  return b.toString();
}

/// يفصل الحروف (المحارف المرئية) بفاصل
String spaced(String s, String sep) {
  final out = <String>[];
  for (final line in s.split('\n')) {
    out.add(line.split(' ').map((w) => _graphemes(w).join(sep)).join(sep == ' ' ? '   ' : ' '));
  }
  return out.join('\n');
}

int _up(int r) => r >= 0x61 && r <= 0x7A ? r - 32 : r;

String _mapRunes(String s, int Function(int) f) {
  final b = StringBuffer();
  for (final r in s.runes) {
    b.writeCharCode(f(r));
  }
  return b.toString();
}

/// تقسيم بسيط إلى محارف مرئية: الحرف الأساسي + العلامات المركّبة بعده
List<String> _graphemes(String s) => Characters(s).toList();

// ─────────────────────────── الزخرفة العربية ───────────────────────────

const tatweel = 'ـ';

/// حروف تتصل بما بعدها (ثنائية الاتصال)
const _dualJoin = 'بتثجحخسشصضطظعغفقكلمنهيئـپچگکیڤڨ';

/// حروف عربية تتصل بما قبلها (كل الحروف ما عدا الهمزة المنفردة)
bool _joinsPrev(String c) => c.isNotEmpty && _arLetterRe.hasMatch(c) && c != 'ء';
bool isArabicMark(int r) => (r >= 0x064B && r <= 0x065F) || r == 0x0670 || (r >= 0x06D6 && r <= 0x06ED && r != 0x06DD && r != 0x06DE && r != 0x06E5 && r != 0x06E6);

/// يقسّم النص إلى (حرف + تشكيله)
List<String> _tokens(String s) {
  final out = <String>[];
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    if (isArabicMark(r) && out.isNotEmpty) {
      out[out.length - 1] += ch;
    } else {
      out.add(ch);
    }
  }
  return out;
}

/// كشيدة/تطويل بين الحروف المتصلة فقط مع احترام الحروف التي لا تتصل بما بعدها
/// (ا د ذ ر ز و ة ء أ إ آ ى…) وعدم كسر «لا».
/// [letterMarks] علامات تُوضع على الحروف (بالتناوب) إن لم يكن عليها تشكيل.
/// [kashidaMarks] علامات توضع على أول كشيدة.
/// [between] رمز يوضع وسط الكشيدة (مثل ♡).
String arabicStretch(String s, {int level = 1, List<String> letterMarks = const [], List<String> kashidaMarks = const [], String? between}) {
  final tk = _tokens(s);
  final b = StringBuffer();
  var mi = 0, ki = 0;
  for (var i = 0; i < tk.length; i++) {
    final t = tk[i];
    final base = String.fromCharCode(t.runes.first);
    b.write(t);
    final isLetter = _arLetterRe.hasMatch(base);
    if (isLetter && letterMarks.isNotEmpty && t.runes.length == 1 && base != 'ء') {
      b.write(letterMarks[mi++ % letterMarks.length]);
    }
    if (i + 1 >= tk.length) continue;
    final next = String.fromCharCode(tk[i + 1].runes.first);
    final lamAlef = base == 'ل' && 'اأإآٱ'.contains(next);
    if (_dualJoin.contains(base) && base != tatweel && _joinsPrev(next) && !lamAlef) {
      if (between != null) {
        b.write('$tatweel$between$tatweel');
      } else {
        b.write(tatweel);
        if (kashidaMarks.isNotEmpty) b.write(kashidaMarks[ki++ % kashidaMarks.length]);
        if (level > 1) b.write(tatweel * (level - 1));
      }
    }
  }
  return b.toString();
}

// ─────────────────────────── الإطارات ───────────────────────────

/// رموز تنعكس تلقائياً في السياق من اليمين لليسار (Bidi_Mirrored)
const _mirror = {
  '(': ')', ')': '(', '[': ']', ']': '[', '{': '}', '}': '{', '<': '>', '>': '<', '«': '»', '»': '«', '‹': '›', '›': '‹', //
  '『': '』', '』': '『', '「': '」', '」': '「', '【': '】', '】': '【', '〔': '〕', '〕': '〔', '《': '》', '》': '《', '〈': '〉', '〉': '〈',
  '⊰': '⊱', '⊱': '⊰', '༺': '༻', '༻': '༺', '⟬': '⟭', '⟭': '⟬', '⫷': '⫸', '⫸': '⫷',
};

String _mirrorRev(String s) => _graphemes(s).reversed.map((g) => _mirror[g] ?? g).join();

class DecorFrame {
  final String id, open, close;
  const DecorFrame(this.id, this.open, this.close);

  /// يلفّ النص. للنص العربي (اتجاه من اليمين لليسار) يُقلب ترتيب الرموز ويُعكس ما ينعكس
  /// حتى يظهر الإطار بالشكل نفسه بصرياً (إطار معكوس).
  String wrap(String text, {bool rtl = false}) => rtl ? '${_mirrorRev(close)} $text ${_mirrorRev(open)}' : '$open $text $close';
}

const decorFrames = <DecorFrame>[
  DecorFrame('javanese', '꧁', '꧂'),
  DecorFrame('tibetan', '༺', '༻'),
  DecorFrame('javanese2', '꧁༺', '༻꧂'),
  DecorFrame('star', '★彡', '彡★'),
  DecorFrame('corner', '『', '』'),
  DecorFrame('lenticular', '【', '】'),
  DecorFrame('guillemet', '«✦', '✦»'),
  DecorFrame('stars', '⋆｡°✩', '✩°｡⋆'),
  DecorFrame('birds', '𓆩', '𓆪'),
  DecorFrame('hearts', '♡', '♡'),
  DecorFrame('moon', '☾', '☽'),
  DecorFrame('flower', '✿', '✿'),
  DecorFrame('angle', '⊱', '⊰'),
  DecorFrame('fleur', '⚜', '⚜'),
  DecorFrame('sakura', '🌸', '🌸'),
  DecorFrame('sudan', '🇸🇩', '🇸🇩'),
  DecorFrame('sparkle', '✨', '✨'),
  DecorFrame('crown', '👑', '👑'),
  DecorFrame('queen', '♛', '♛'),
  DecorFrame('rub', '۞', '۞'),
  DecorFrame('blossom', '❀', '❀'),
  DecorFrame('kawaii', '✧･ﾟ', 'ﾟ･✧'),
  DecorFrame('dots', '•°•', '•°•'),
  DecorFrame('arrows', '⫷', '⫸'),
  DecorFrame('tortoise', '⟬', '⟭'),
  DecorFrame('wings', '╰☆☆', '☆☆╮'),
  DecorFrame('blackheart', '🖤', '🖤'),
];

/// فواصل وخطوط زخرفية جاهزة للنسخ
const decorSeparators = <String>[
  '━━━✦❘༻༺❘✦━━━',
  '•───────•°•❀•°•───────•',
  '⋆⁺₊⋆ ☾ ⋆⁺₊⋆',
  '═══════ ✥.❖.✥ ═══════',
  '◈ ━━━━━━ ⸙ ━━━━━━ ◈',
  '┈┈┈┈┈┈┈ ✿ ┈┈┈┈┈┈┈',
  '❀•°•═════ஓ๑♡๑ஓ═════•°•❀',
  'ꕥ ━━━━━━━━━━━ ꕥ',
  '۞ ════════ ۞',
  '✧･ﾟ: *✧･ﾟ:* *:･ﾟ✧*:･ﾟ✧',
  '▬▬▬▬▬▬▬ ⚜ ▬▬▬▬▬▬▬',
  '🇸🇩━━━━━━━━━━🇸🇩',
];

// ─────────────────────────── قائمة الأنماط ───────────────────────────

enum DecorKind { latin, arabic }

class DecorStyle {
  final String id;
  final DecorKind kind;
  final String Function() name;
  final String Function(String) apply;
  const DecorStyle(this.id, this.kind, this.name, this.apply);
}

List<DecorStyle> get latinStyles => [
  DecorStyle('bold', DecorKind.latin, () => t('عريض', 'عريض', 'Bold'), mathBold.apply),
  DecorStyle('italic', DecorKind.latin, () => t('مايل', 'مائل', 'Italic'), mathItalic.apply),
  DecorStyle('bolditalic', DecorKind.latin, () => t('عريض مايل', 'عريض مائل', 'Bold italic'), mathBoldItalic.apply),
  DecorStyle('script', DecorKind.latin, () => tr('خط يد', 'Script'), mathScript.apply),
  DecorStyle('boldscript', DecorKind.latin, () => tr('خط يد عريض', 'Bold script'), mathBoldScript.apply),
  DecorStyle('fraktur', DecorKind.latin, () => tr('قوطي', 'Fraktur'), mathFraktur.apply),
  DecorStyle('boldfraktur', DecorKind.latin, () => tr('قوطي عريض', 'Bold fraktur'), mathBoldFraktur.apply),
  DecorStyle('double', DecorKind.latin, () => tr('مزدوج الخط', 'Double-struck'), mathDouble.apply),
  DecorStyle('mono', DecorKind.latin, () => tr('آلة كاتبة', 'Monospace'), mathMono.apply),
  DecorStyle('sans', DecorKind.latin, () => tr('بدون زوائد', 'Sans'), mathSans.apply),
  DecorStyle('sansbold', DecorKind.latin, () => tr('بدون زوائد عريض', 'Sans bold'), mathSansBold.apply),
  DecorStyle('sansitalic', DecorKind.latin, () => t('بدون زوائد مايل', 'بدون زوائد مائل', 'Sans italic'), mathSansItalic.apply),
  DecorStyle('sansbolditalic', DecorKind.latin, () => t('بدون زوائد عريض مايل', 'بدون زوائد عريض مائل', 'Sans bold italic'), mathSansBoldItalic.apply),
  DecorStyle('circled', DecorKind.latin, () => tr('داخل دوائر', 'Circled'), circled),
  DecorStyle('negcircled', DecorKind.latin, () => tr('دوائر سوداء', 'Negative circled'), negCircled),
  DecorStyle('squared', DecorKind.latin, () => tr('داخل مربعات', 'Squared'), squared),
  DecorStyle('negsquared', DecorKind.latin, () => tr('مربعات سوداء', 'Negative squared'), negSquared),
  DecorStyle('fullwidth', DecorKind.latin, () => tr('عريض المسافة', 'Fullwidth'), fullwidthText),
  DecorStyle('smallcaps', DecorKind.latin, () => tr('حروف كبيرة صغيرة', 'Small caps'), smallCaps),
  DecorStyle('upside', DecorKind.latin, () => tr('مقلوب', 'Upside-down'), upsideDown),
  DecorStyle('strike', DecorKind.latin, () => t('مشطوب', 'مشطوب', 'Strikethrough'), (s) => combining(s, '̶')),
  DecorStyle('underline', DecorKind.latin, () => t('تحتو خط', 'تحته خط', 'Underline'), (s) => combining(s, '̲')),
  DecorStyle('dunderline', DecorKind.latin, () => t('تحتو خطين', 'تحته خطان', 'Double underline'), (s) => combining(s, '̳')),
  DecorStyle('slash', DecorKind.latin, () => tr('مشطوب بمائل', 'Slashed'), (s) => combining(s, '̸')),
  DecorStyle('bubbles', DecorKind.latin, () => tr('فقاعات', 'Bubbles'), (s) => '°❀ ${circled(s)} ❀°'),
  DecorStyle('sparkles', DecorKind.latin, () => tr('نجيمات', 'Sparkles'), (s) => '✨ ${spaced(mathBoldScript.apply(s), '⋆')} ✨'),
  DecorStyle('hearts', DecorKind.latin, () => tr('قلوب بين الحروف', 'Hearts between'), (s) => spaced(s, '♥')),
  DecorStyle('aesthetic', DecorKind.latin, () => tr('متباعد', 'Aesthetic spaced'), (s) => spaced(fullwidth.apply(s), ' ')),
  DecorStyle('boldframe', DecorKind.latin, () => tr('عريض بإطار', 'Bold framed'), (s) => '꧁ ${mathBold.apply(s)} ꧂'),
];

List<DecorStyle> get arabicStyles => [
  DecorStyle('ar_t1', DecorKind.arabic, () => t('مطّة خفيفة', 'كشيدة خفيفة', 'Kashida ×1'), (s) => arabicStretch(s)),
  DecorStyle('ar_t2', DecorKind.arabic, () => t('مطّة وسط', 'كشيدة متوسطة', 'Kashida ×2'), (s) => arabicStretch(s, level: 2)),
  DecorStyle('ar_t3', DecorKind.arabic, () => t('مطّة طويلة', 'كشيدة طويلة', 'Kashida ×3'), (s) => arabicStretch(s, level: 3)),
  DecorStyle('ar_tanween', DecorKind.arabic, () => tr('تنوين مزخرف', 'Tanween marks'), (s) => arabicStretch(s, letterMarks: const ['ً', 'ٌ', 'ٍ'])),
  DecorStyle('ar_shadda', DecorKind.arabic, () => tr('شدّة على الكشيدة', 'Shadda kashida'), (s) => arabicStretch(s, level: 2, kashidaMarks: const ['ّ'])),
  DecorStyle('ar_harakat', DecorKind.arabic, () => tr('حركات متناوبة', 'Alternating harakat'), (s) => arabicStretch(s, level: 2, kashidaMarks: const ['َ', 'ُ', 'ِ'])),
  DecorStyle('ar_dots', DecorKind.arabic, () => tr('نقاط عُليا', 'High dots'), (s) => arabicStretch(s, level: 2, kashidaMarks: const ['ۛ'])),
  DecorStyle('ar_quran', DecorKind.arabic, () => tr('علامات صغيرة', 'Small high marks'), (s) => arabicStretch(s, level: 2, kashidaMarks: const ['ۖ', 'ۗ'])),
  DecorStyle('ar_alef', DecorKind.arabic, () => tr('ألف خنجرية', 'Dagger alef'), (s) => arabicStretch(s, letterMarks: const ['ٰ'])),
  DecorStyle('ar_heart', DecorKind.arabic, () => tr('قلوب بين الحروف', 'Hearts in kashida'), (s) => arabicStretch(s, between: '♡')),
  DecorStyle('ar_star', DecorKind.arabic, () => tr('نجوم بين الحروف', 'Stars in kashida'), (s) => arabicStretch(s, between: '★')),
  DecorStyle('ar_spaced', DecorKind.arabic, () => tr('حروف متباعدة', 'Spaced letters'), (s) => spaced(s, ' ')),
  DecorStyle('ar_dotspaced', DecorKind.arabic, () => tr('حروف بنقاط', 'Dotted letters'), (s) => spaced(s, '·')),
  DecorStyle('ar_mix', DecorKind.arabic, () => tr('كشيدة وتشكيل', 'Kashida + marks'), (s) => arabicStretch(s, level: 2, letterMarks: const ['ً', 'ٌ'], kashidaMarks: const ['ّ'])),
  DecorStyle('ar_rub', DecorKind.arabic, () => tr('زخرفة ۞', '۞ ornament'), (s) => const DecorFrame('', '۞', '۞').wrap(arabicStretch(s, level: 2), rtl: true)),
  DecorStyle('ar_flower', DecorKind.arabic, () => tr('ورود وتشكيل', 'Flowers + marks'), (s) => const DecorFrame('', '✿', '✿').wrap(arabicStretch(s, level: 2, kashidaMarks: const ['ً']), rtl: true)),
  DecorStyle('ar_javanese', DecorKind.arabic, () => tr('إطار ꧁꧂ معكوس', 'Mirrored ꧁꧂ frame'), (s) => const DecorFrame('', '꧁༺', '༻꧂').wrap(arabicStretch(s, level: 2), rtl: true)),
  DecorStyle('ar_star2', DecorKind.arabic, () => tr('إطار ★彡 معكوس', 'Mirrored ★彡 frame'), (s) => const DecorFrame('', '★彡', '彡★').wrap(arabicStretch(s), rtl: true)),
];

List<DecorStyle> get allDecorStyles => [...latinStyles, ...arabicStyles];

/// اتجاه النتيجة حسب أول حرف قوي: العربي من اليمين لليسار واللاتيني من اليسار لليمين
TextDirection decorDir(String s) {
  final a = s.indexOf(_arLetterRe), l = s.indexOf(RegExp('[A-Za-z]'));
  return a >= 0 && (l < 0 || a < l) ? TextDirection.rtl : TextDirection.ltr;
}

// ═══════════════════════════════════════════════════════════════════
//  الواجهة
// ═══════════════════════════════════════════════════════════════════

const _favKey = 'text_decor_favs';
const _maxLen = 400;

class TextDecorPanel extends StatefulWidget {
  final String text;
  const TextDecorPanel({super.key, required this.text});
  @override
  State<TextDecorPanel> createState() => _TextDecorPanelState();
}

class _TextDecorPanelState extends State<TextDecorPanel> {
  String _style = 'boldscript';
  String _frame = 'javanese';
  int _seed = 0;
  final _rnd = Random();

  List<String> _favs(AppState s) {
    final raw = s.getData<dynamic>(_favKey);
    if (raw is List) return raw.map((e) => '$e').toList();
    if (raw is String) {
      try {
        return List<String>.from(jsonDecode(raw) as List);
      } catch (_) {}
    }
    return [];
  }

  void _toggleFav(AppState s, String v) {
    final l = _favs(s);
    if (l.contains(v)) {
      l.remove(v);
      toast(t('اتشال من المفضّلة', 'أُزيل من المفضّلة', 'Removed from favorites'));
    } else {
      l.insert(0, v);
      if (l.length > 60) l.removeRange(60, l.length);
      toast(t('اتضاف للمفضّلة ⭐', 'أُضيف إلى المفضّلة ⭐', 'Added to favorites ⭐'));
    }
    s.setData(_favKey, l);
    setState(() {});
  }

  Future<void> _copy(AppState s, String v) async {
    await copyText(v);
    s.awardDaily('text_decor', 3, tr('زخرفة النصوص', 'Text decoration'));
  }

  void _share(String v) => SharePlus.instance.share(ShareParams(text: v));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final raw = widget.text.trim();
    final sample = raw.isEmpty;
    var src = sample ? (isEn ? 'Ameer Tools 2026' : 'أدوات أمير') : raw;
    final cut = src.characters.length > _maxLen;
    if (cut) src = src.characters.take(_maxLen).toString();
    final ar = hasArabic(src), la = hasLatin(src);
    final styles = [if (la) ...latinStyles, if (ar) ...arabicStyles];
    final favs = _favs(s);
    final rtl = decorDir(src) == TextDirection.rtl;
    if (styles.isNotEmpty && !styles.any((x) => x.id == _style)) _style = styles.first.id;
    final st = styles.where((x) => x.id == _style).firstOrNull;
    final fr = decorFrames.where((f) => f.id == _frame).firstOrNull;
    var custom = st == null ? src : st.apply(src);
    if (fr != null) custom = fr.wrap(custom, rtl: rtl);

    Widget card(String name, String value, {Color color = SD.gold}) =>
        _DecorCard(name: name, value: value, color: color, fav: favs.contains(value), onCopy: () => _copy(s, value), onShare: () => _share(value), onFav: () => _toggleFav(s, value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sample)
          NoteBox(
            t('أكتب نصّك فوق وشوف الزخارف هنا. هسي دي أمثلة.', 'اكتب نصّك في الأعلى لترى الزخارف هنا. هذه أمثلة.', 'Type your text above to decorate it. These are examples.'),
            kind: NoteKind.tip,
          ),
        if (cut) NoteBox(t('النص طويل، زخرفنا أول $_maxLen حرف بس.', 'النص طويل، زُخرفت أول $_maxLen حرفاً فقط.', 'Long text: only the first $_maxLen characters are decorated.'), kind: NoteKind.warn),
        // ── التركيب المخصص
        SCard(
          title: t('ركّب زخرفتك', 'ركّب زخرفتك', 'Build your own'),
          icon: Icons.tune_rounded,
          color: SD.henna,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (styles.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: ValueKey('st$_style$_seed${styles.length}'),
                  initialValue: _style,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: tr('النمط', 'Style'), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  items: [
                    for (final x in styles)
                      DropdownMenuItem(
                        value: x.id,
                        child: Text(x.name(), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _style = v ?? _style),
                ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                key: ValueKey('fr$_frame$_seed'),
                initialValue: _frame,
                isExpanded: true,
                decoration: InputDecoration(labelText: tr('الإطار', 'Frame'), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                items: [
                  DropdownMenuItem(
                    value: 'none',
                    child: Text(t('بدون إطار', 'بلا إطار', 'No frame'), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  for (final f in decorFrames)
                    DropdownMenuItem(
                      value: f.id,
                      child: Text('${f.open}  …  ${f.close}', maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr),
                    ),
                ],
                onChanged: (v) => setState(() => _frame = v ?? _frame),
              ),
              const SizedBox(height: 10),
              _ResultBox(custom),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() {
                        if (styles.isNotEmpty) _style = styles[_rnd.nextInt(styles.length)].id;
                        _frame = decorFrames[_rnd.nextInt(decorFrames.length)].id;
                        _seed++;
                      }),
                      icon: const Icon(Icons.casino_rounded),
                      label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('زخرفة عشوائية', 'زخرفة عشوائية', 'Random'))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(tooltip: tr('نسخ', 'Copy'), onPressed: () => _copy(s, custom), icon: const Icon(Icons.copy_rounded)),
                  IconButton.filledTonal(tooltip: t('شارك', 'مشاركة', 'Share'), onPressed: () => _share(custom), icon: const Icon(Icons.share_rounded)),
                  IconButton.filledTonal(
                    tooltip: tr('المفضّلة', 'Favorite'),
                    onPressed: () => _toggleFav(s, custom),
                    icon: Icon(favs.contains(custom) ? Icons.star_rounded : Icons.star_border_rounded, color: favs.contains(custom) ? SD.gold : null),
                  ),
                ],
              ),
            ],
          ),
        ),
        // ── المفضّلة
        if (favs.isNotEmpty) ...[SectionTitle(t('مفضّلاتي', 'المفضّلة', 'My favorites'), icon: Icons.star_rounded), for (final f in favs) card(tr('مفضّلة', 'Favorite'), f, color: SD.gold)],
        // ── العربية
        if (ar) ...[
          SectionTitle(t('زخرفة عربية', 'زخرفة عربية', 'Arabic decoration'), icon: Icons.auto_awesome_rounded),
          for (final x in arabicStyles)
            if (x.apply(src) != src) card(x.name(), x.apply(src), color: SD.green),
        ],
        // ── اللاتينية
        if (la) ...[
          SectionTitle(t('خطوط إنجليزية', 'خطوط لاتينية', 'Fancy Latin fonts'), icon: Icons.font_download_rounded),
          for (final x in latinStyles)
            if (x.apply(src) != src) card(x.name(), x.apply(src), color: SD.nile),
        ],
        // ── الإطارات
        SectionTitle(t('إطارات', 'إطارات', 'Frames'), icon: Icons.crop_free_rounded),
        for (final f in decorFrames) card('${f.open} ${f.close}', f.wrap(src, rtl: rtl), color: SD.purple),
        // ── الفواصل
        SectionTitle(t('فواصل وخطوط', 'فواصل وخطوط', 'Separators & lines'), icon: Icons.horizontal_rule_rounded),
        for (final (i, sep) in decorSeparators.indexed) card('${tr('فاصل', 'Separator')} ${i + 1}', sep, color: SD.coffee),
        NoteBox(
          t(
            'بعض الزخارف ممكن تظهر مربعات في أجهزة أو تطبيقات ما بتدعم الخطوط دي. كل شي بيتعمل في جهازك بدون نت.',
            'قد تظهر بعض الزخارف كمربعات في أجهزة أو تطبيقات لا تدعم هذه الرموز. كل شيء يتم على جهازك دون إنترنت.',
            'Some styles may show as boxes on devices or apps lacking these symbols. Everything runs on your device, offline.',
          ),
          kind: NoteKind.info,
        ),
      ],
    );
  }
}

class _ResultBox extends StatelessWidget {
  final String value;
  const _ResultBox(this.value);
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (dark ? Colors.black : Colors.white).withValues(alpha: dark ? .18 : .6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SD.gold.withValues(alpha: .4)),
      ),
      child: SelectableText(
        value,
        maxLines: 4,
        minLines: 1,
        textAlign: TextAlign.center,
        textDirection: decorDir(value),
        style: TextStyle(fontSize: 22, height: 1.5, color: dark ? SD.goldLight : SD.brown),
      ),
    );
  }
}

class _DecorCard extends StatelessWidget {
  final String name, value;
  final Color color;
  final bool fav;
  final VoidCallback onCopy, onShare, onFav;
  const _DecorCard({required this.name, required this.value, required this.color, required this.fav, required this.onCopy, required this.onShare, required this.onFav});

  @override
  Widget build(BuildContext context) {
    final c = readable(context, color);
    return SCard(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, color: c),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: tr('المفضّلة', 'Favorite'),
                onPressed: onFav,
                icon: Icon(fav ? Icons.star_rounded : Icons.star_border_rounded, color: fav ? SD.gold : null),
              ),
              IconButton(visualDensity: VisualDensity.compact, tooltip: t('شارك', 'مشاركة', 'Share'), onPressed: onShare, icon: const Icon(Icons.share_rounded)),
              IconButton(visualDensity: VisualDensity.compact, tooltip: tr('نسخ', 'Copy'), onPressed: onCopy, icon: const Icon(Icons.copy_rounded)),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8, top: 2),
            child: SelectableText(value, maxLines: 4, minLines: 1, textAlign: TextAlign.center, textDirection: decorDir(value), style: const TextStyle(fontSize: 21, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
