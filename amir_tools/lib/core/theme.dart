import 'package:flutter/material.dart';

/// ألوان مستوحاة من السودان: العلم، النيل، الرمال، الحِنّة، الذهب، وثياب السودانيات الملوّنة.
class SD {
  static const green = Color(0xFF007229); // أخضر العلم
  static const red = Color(0xFFD21034); // أحمر العلم
  static const black = Color(0xFF141414);
  static const nile = Color(0xFF0B5C8A); // النيل الأزرق
  static const nileLight = Color(0xFF2E9BD6);
  static const sand = Color(0xFFF6E7C8); // رمال الشمالية
  static const sandDeep = Color(0xFFE3BF86);
  static const gold = Color(0xFFD4A017); // ذهب سوق أم درمان
  static const henna = Color(0xFFB4492D); // الحِنّة
  static const coffee = Color(0xFF6B3E26); // الجبنة
  static const indigo = Color(0xFF3B2F8F); // التوب
  static const teal = Color(0xFF0E8C84);
  static const purple = Color(0xFF8E3A9E);
  static const pink = Color(0xFFD64578);
  static const orange = Color(0xFFE2702B);

  // تراثي: خشب وجلد بني مع ذهب (المظهر الافتراضي)
  static const brown = Color(0xFF5A3418);
  static const brownDeep = Color(0xFF3A1F0C);
  static const brownLight = Color(0xFF7A4A24);
  static const leather = Color(0xFF6B3F1F);
  static const goldLight = Color(0xFFF6D58B);
  static const goldDeep = Color(0xFFB9852F);
  static const cream = Color(0xFFF8E9CF);

  static const night = brownDeep;
  static const nightCard = Color(0xFF55321A);

  /// تدرّج النص الذهبي
  static const goldText = [Color(0xFFFFE7A8), Color(0xFFF2C66B), Color(0xFFD99A3A)];

  /// تدرّج البطاقة الرئيسية (فجر على النيل)
  static const heroLight = [Color(0xFF007229), Color(0xFF0B5C8A), Color(0xFF3B2F8F)];
  static const heroDark = [Color(0xFF7A4A24), Color(0xFF5A3418), Color(0xFF3A1F0C)];
  static const sunset = [Color(0xFFD4A017), Color(0xFFE2702B), Color(0xFFB4492D)];
}

/// يفتّح اللون الغامق ليُقرأ فوق الخلفية البنية في المظهر الداكن
Color readable(BuildContext context, Color c) {
  if (Theme.of(context).brightness != Brightness.dark) return c;
  final l = c.computeLuminance();
  return l > .35 ? c : Color.lerp(c, Colors.white, l < .08 ? .55 : .4)!;
}

/// ألوان مميزة لكل أداة
const toolColors = <String, Color>{
  'green': SD.green, 'red': SD.red, 'nile': SD.nile, 'gold': SD.gold, 'henna': SD.henna,
  'coffee': SD.coffee, 'indigo': SD.indigo, 'teal': SD.teal, 'purple': SD.purple,
  'pink': SD.pink, 'orange': SD.orange, 'black': SD.black,
};

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: SD.brown,
    brightness: b,
    primary: dark ? SD.goldLight : SD.brown,
    onPrimary: dark ? SD.brownDeep : Colors.white,
    secondary: SD.gold,
    tertiary: SD.green,
    surface: dark ? SD.nightCard : const Color(0xFFFFF4E0),
    onSurface: dark ? SD.cream : const Color(0xFF3A1F0C),
    surfaceContainerHighest: dark ? const Color(0xFF6A4123) : const Color(0xFFF3E1BF),
    outline: SD.goldDeep,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Tajawal', brightness: b);
  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: base.textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface, fontFamily: 'Tajawal'),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: dark ? SD.goldLight : SD.brown,
      titleTextStyle: TextStyle(fontFamily: 'Lalezar', fontSize: 26, color: dark ? SD.goldLight : SD.brown),
      iconTheme: IconThemeData(color: dark ? SD.goldLight : SD.brown),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: SD.gold.withValues(alpha: .5))),
    ),
    dividerColor: SD.gold.withValues(alpha: .25),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF3F2410) : const Color(0xFFFFFAF0),
      labelStyle: TextStyle(color: dark ? SD.goldLight.withValues(alpha: .85) : SD.brown),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: SD.gold.withValues(alpha: dark ? .35 : .55))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: SD.gold, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SD.gold,
        foregroundColor: SD.brownDeep,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: dark ? SD.goldLight : SD.brown,
        side: const BorderSide(color: SD.gold),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: dark ? SD.goldLight : SD.brown)),
    chipTheme: ChipThemeData(
      backgroundColor: dark ? SD.leather : const Color(0xFFFFF4E0),
      side: BorderSide(color: SD.gold.withValues(alpha: .6)),
      labelStyle: TextStyle(fontFamily: 'Tajawal', color: dark ? SD.cream : SD.brown, fontWeight: FontWeight.w700),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: const WidgetStatePropertyAll(TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
        side: WidgetStatePropertyAll(BorderSide(color: SD.gold.withValues(alpha: .7))),
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? SD.gold : null),
        foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? SD.brownDeep : (dark ? SD.cream : SD.brown)),
      ),
    ),
    sliderTheme: const SliderThemeData(activeTrackColor: SD.gold, thumbColor: SD.gold),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: SD.gold),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? SD.gold : null),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? SD.green : null),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dark ? SD.brown : const Color(0xFFFFF4E0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: SD.gold)),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: dark ? SD.brown : const Color(0xFFFFF4E0)),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: SD.brownDeep,
      contentTextStyle: const TextStyle(fontFamily: 'Tajawal', color: SD.goldLight, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: SD.gold)),
    ),
  );
}
