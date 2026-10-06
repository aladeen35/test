import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';
import '../services/prayer.dart';

/// مفتاح عام لرسائل التنبيه السريعة
final messengerKey = GlobalKey<ScaffoldMessengerState>();

void toast(String msg, {IconData? icon}) {
  messengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Expanded(child: Text(msg)),
      ]),
      duration: const Duration(milliseconds: 2200),
    ));
}

/// إنجاز (شارة) في نظام النقاط
class Achievement {
  final String id, title, desc, emoji;
  final bool Function(AppState s) test;
  const Achievement(this.id, this.title, this.desc, this.emoji, this.test);
}

final achievements = <Achievement>[
  Achievement('first', 'أول خطوة', 'استخدم أول أداة', '👣', (s) => s.counter('tools_used') >= 1),
  Achievement('explorer', 'زول مكتشف', 'جرّب 10 أدوات مختلفة', '🧭', (s) => s.distinctTools >= 10),
  Achievement('master', 'سيد العدّة', 'جرّب 25 أداة مختلفة', '🧰', (s) => s.distinctTools >= 25),
  Achievement('tasbih100', 'لسانك رطب', 'سبّح 100 مرة', '📿', (s) => s.counter('tasbih') >= 100),
  Achievement('tasbih1000', 'ذاكر الله', 'سبّح 1000 مرة', '🌿', (s) => s.counter('tasbih') >= 1000),
  Achievement('adhkar', 'محصّن', 'أكمل أذكار الصباح أو المساء', '🛡️', (s) => s.counter('adhkar_done') >= 1),
  Achievement('adhkar7', 'محافظ على الأذكار', 'أكمل الأذكار 7 مرات', '🕌', (s) => s.counter('adhkar_done') >= 7),
  Achievement('salah5', 'يوم كامل', 'سجّل الصلوات الخمس في يوم واحد', '✨', (s) => s.counter('full_prayer_days') >= 1),
  Achievement('salah30', 'شهر من المحافظة', 'سجّل الصلوات الخمس 30 يومًا', '🏅', (s) => s.counter('full_prayer_days') >= 30),
  Achievement('water', 'روّيت', 'وصل هدف الموية في يوم', '💧', (s) => s.counter('water_goal_days') >= 1),
  Achievement('focus', 'مركّز', 'أكمل 5 جلسات تركيز', '🎯', (s) => s.counter('focus_sessions') >= 5),
  Achievement('fav', 'عارف حقك', 'أضف 5 أدوات للمفضلة', '⭐', (s) => s.favorites.length >= 5),
  Achievement('level5', 'فنان', 'وصل المستوى 5', '🎨', (s) => s.level >= 5),
  Achievement('level10', 'أسطورة', 'وصل المستوى 10', '👑', (s) => s.level >= 10),
  Achievement('streak7', 'ما بتغيب', 'افتح التطبيق 7 أيام متتالية', '🔥', (s) => s.streak >= 7),
  Achievement('night', 'سهّار', 'استخدم التطبيق بعد نص الليل', '🌙', (s) => s.counter('night_use') >= 1),
];

const levelTitles = ['زول جديد', 'زول نشيط', 'شاطر', 'حريف', 'فنان', 'عبقري', 'قيدومة', 'كبير القوم', 'أسطورة', 'سلطان الأدوات'];

class AppState extends ChangeNotifier {
  late SharedPreferences _p;
  Map<String, dynamic> _d = {};

  static Future<AppState> load() async {
    final s = AppState();
    s._p = await SharedPreferences.getInstance();
    try {
      s._d = jsonDecode(s._p.getString('amir_state') ?? '{}') as Map<String, dynamic>;
    } catch (_) {
      s._d = {};
    }
    s._touchStreak();
    return s;
  }

  void _save() => _p.setString('amir_state', jsonEncode(_d));

  void _set(String k, dynamic v) {
    _d[k] = v;
    _save();
    notifyListeners();
  }

  /* ── بيانات عامة للأدوات: كل أداة تحفظ ما تريد تحت مفتاحها ── */
  T? getData<T>(String key) => _d['x_$key'] as T?;
  void setData(String key, dynamic value) => _set('x_$key', value);

  /* ── الإعدادات ── */
  bool get onboarded => _d['onboarded'] == true;
  set onboarded(bool v) => _set('onboarded', v);

  String get name => _d['name'] ?? '';
  set name(String v) => _set('name', v.trim());

  String get cityId => _d['city'] ?? 'khartoum';
  set cityId(String v) {
    _d['gps'] = null;
    _set('city', v);
  }

  List<double>? get gps => (_d['gps'] as List?)?.map((e) => (e as num).toDouble()).toList();
  void setGps(double lat, double lng) {
    _d['gps'] = [lat, lng];
    var best = cities.first;
    double bd = 1e9;
    for (final c in cities) {
      final dd = math.pow(c.lat - lat, 2) + math.pow(c.lng - lng, 2);
      if (dd < bd) {
        bd = dd.toDouble();
        best = c;
      }
    }
    _set('city', best.id);
  }

  void clearGps() => _set('gps', null);

  /// المدينة الحالية مع الإحداثيات الدقيقة إن وُجدت
  City get city {
    final c = cityById(cityId);
    final g = gps;
    return g == null ? c : City(c.id, '${c.name} (موقعي)', c.state, g[0], g[1]);
  }

  /// الافتراضي: المظهر التراثي البني (داكن)
  ThemeMode get themeMode => ThemeMode.values[_d['theme'] ?? ThemeMode.dark.index];
  set themeMode(ThemeMode m) => _set('theme', m.index);

  String get prayerMethod => _d['method'] ?? 'egypt';
  set prayerMethod(String v) => _set('method', v);
  bool get hanafi => _d['hanafi'] == true;
  set hanafi(bool v) => _set('hanafi', v);
  Map<String, int> get prayerAdjust => Map<String, int>.from((_d['adjust'] as Map?) ?? {});
  void setPrayerAdjust(String k, int v) {
    final m = prayerAdjust..[k] = v;
    _set('adjust', m);
  }

  int get hijriShift => _d['hijriShift'] ?? 0;
  set hijriShift(int v) => _set('hijriShift', v);

  bool get prayerNotify => _d['prayerNotify'] == true;
  set prayerNotify(bool v) => _set('prayerNotify', v);

  String? get pinHash => _d['pin'];
  set pinHash(String? v) => _set('pin', v);

  /// مواقيت يوم معيّن للمدينة الحالية
  Map<String, DateTime> timesFor(DateTime sudanDate) {
    final c = city;
    return prayerTimes(sudanDate.year, sudanDate.month, sudanDate.day, c.lat, c.lng,
        method: prayerMethod, hanafi: hanafi, adjust: prayerAdjust);
  }

  /// الصلاة القادمة
  ({String key, DateTime at}) nextPrayer() {
    final now = DateTime.now();
    final today = timesFor(sudanNow());
    for (final k in fardKeys) {
      if (today[k]!.isAfter(now)) return (key: k, at: today[k]!);
    }
    final tm = timesFor(sudanNow().add(const Duration(days: 1)));
    return (key: 'fajr', at: tm['fajr']!);
  }

  /* ── العملات ── */
  double? get sdgParallel => (_d['sdgParallel'] as num?)?.toDouble();
  set sdgParallel(double? v) {
    _set('sdgParallel', v);
    if (v != null) {
      final hist = List<Map>.from(getData<List>('parallel_history') ?? []);
      hist.add({'t': DateTime.now().millisecondsSinceEpoch, 'v': v});
      setData('parallel_history', hist.length > 60 ? hist.sublist(hist.length - 60) : hist);
    }
  }

  bool get useParallel => _d['useParallel'] ?? true;
  set useParallel(bool v) => _set('useParallel', v);

  Map<String, double>? get officialRates => (_d['rates'] as Map?)?.map((k, v) => MapEntry(k as String, (v as num).toDouble()));
  int? get ratesAt => _d['ratesAt'];
  void setRates(Map<String, double> r) {
    _d['ratesAt'] = DateTime.now().millisecondsSinceEpoch;
    _set('rates', r);
  }

  /// كم وحدة من العملة مقابل دولار واحد
  double usdRate(String code, {bool? parallel}) {
    final par = parallel ?? useParallel;
    if (code == 'SDG' && par && sdgParallel != null) return sdgParallel!;
    return officialRates?[code] ?? fallbackRates[code] ?? 1;
  }

  /// سعر التحويل: وحدة واحدة من [from] تساوي كم من [to]
  double rate(String from, String to, {bool? parallel}) => usdRate(to, parallel: parallel) / usdRate(from, parallel: parallel);

  /* ── المفضلة والأخيرة ── */
  List<String> get favorites => List<String>.from(_d['favs'] ?? ['currency', 'remit', 'age', 'tasbih', 'qibla', 'flashlight']);
  bool isFav(String id) => favorites.contains(id);
  void toggleFav(String id) {
    final f = favorites;
    f.contains(id) ? f.remove(id) : f.add(id);
    _set('favs', f);
    _checkAchievements();
  }

  void reorderFavs(int oldI, int newI) {
    final f = favorites;
    final x = f.removeAt(oldI);
    f.insert(newI > oldI ? newI - 1 : newI, x);
    _set('favs', f);
  }

  List<String> get recent => List<String>.from(_d['recent'] ?? []);

  /* ── نظام النقاط ── */
  bool get pointsEnabled => _d['points'] ?? true;
  set pointsEnabled(bool v) => _set('points', v);

  int get xp => _d['xp'] ?? 0;
  int get level => (math.sqrt(xp / 40)).floor() + 1;
  int xpForLevel(int l) => 40 * (l - 1) * (l - 1);
  double get levelProgress => ((xp - xpForLevel(level)) / (xpForLevel(level + 1) - xpForLevel(level))).clamp(0, 1).toDouble();
  String get levelTitle => levelTitles[math.min(level - 1, levelTitles.length - 1)];

  List<String> get unlocked => List<String>.from(_d['ach'] ?? []);
  Map<String, int> get _counters => Map<String, int>.from((_d['counters'] as Map?) ?? {});
  int counter(String k) => _counters[k] ?? 0;
  int get distinctTools => (List.from(_d['usedTools'] ?? [])).length;
  int get streak => _d['streak'] ?? 0;

  /// سجل النقاط الأخير (للعرض في صفحة نقاطي)
  List<Map> get xpLog => List<Map>.from(_d['xpLog'] ?? []);

  /// منح نقاط مع سبب
  void award(int amount, String reason) {
    if (!pointsEnabled || amount <= 0) return;
    final before = level;
    _d['xp'] = xp + amount;
    final log = xpLog..insert(0, {'r': reason, 'x': amount, 't': DateTime.now().millisecondsSinceEpoch});
    _d['xpLog'] = log.take(50).toList();
    _save();
    if (level > before) {
      toast('🎉 مبروك! وصلت المستوى $level — $levelTitle', icon: Icons.emoji_events);
    }
    _checkAchievements();
    notifyListeners();
  }

  /// زيادة عدّاد (تسبيح، أذكار، جلسات…) يُستخدم للإنجازات
  void bump(String key, [int by = 1]) {
    final c = _counters..[key] = (counter(key)) + by;
    _d['counters'] = c;
    _save();
    _checkAchievements();
  }

  /// منح نقاط مرة واحدة في اليوم لنفس المفتاح
  void awardDaily(String key, int amount, String reason) {
    final today = _dayKey(DateTime.now());
    final m = Map<String, dynamic>.from(_d['daily'] ?? {});
    if (m[key] == today) return;
    m[key] = today;
    _d['daily'] = m;
    award(amount, reason);
  }

  /// يُستدعى عند فتح أي أداة
  void useTool(String id, String name) {
    final r = recent..remove(id)..insert(0, id);
    _d['recent'] = r.take(12).toList();
    final used = Set<String>.from(_d['usedTools'] ?? [])..add(id);
    _d['usedTools'] = used.toList();
    final h = DateTime.now().hour;
    if (h < 4) bump('night_use');
    bump('tools_used');
    awardDaily('tool_$id', 5, 'استخدام $name');
    _save();
    notifyListeners();
  }

  void _checkAchievements() {
    final u = unlocked;
    var changed = false;
    for (final a in achievements) {
      if (!u.contains(a.id) && a.test(this)) {
        u.add(a.id);
        changed = true;
        Future.microtask(() => toast('${a.emoji} إنجاز جديد: ${a.title}'));
        if (pointsEnabled) _d['xp'] = xp + 25;
      }
    }
    if (changed) {
      _d['ach'] = u;
      _save();
      notifyListeners();
    }
  }

  void _touchStreak() {
    final today = _dayKey(DateTime.now());
    final last = _d['lastOpen'];
    if (last == today) return;
    final yest = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    _d['streak'] = last == yest ? streak + 1 : 1;
    _d['lastOpen'] = today;
    _save();
  }

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
  static String dayKey(DateTime d) => _dayKey(d);

  /* ── سجل الصلاة ── */
  Set<String> prayedOn(DateTime d) => Set<String>.from((_d['prayed'] as Map?)?[_dayKey(d)] ?? []);
  void togglePrayed(DateTime d, String key) {
    final all = Map<String, dynamic>.from(_d['prayed'] ?? {});
    final s = prayedOn(d);
    final adding = !s.contains(key);
    adding ? s.add(key) : s.remove(key);
    all[_dayKey(d)] = s.toList();
    _d['prayed'] = all;
    _save();
    if (adding) {
      awardDaily('pray_${key}_${_dayKey(d)}', 10, 'صلاة ${prayerNames[key]}');
      if (s.length == 5) {
        bump('full_prayer_days');
        award(20, 'الصلوات الخمس كاملة');
      }
    }
    notifyListeners();
  }

  /* ── النسخ الاحتياطي ── */
  String exportJson() => const JsonEncoder.withIndent('  ').convert(_d);
  void importJson(String s) {
    _d = jsonDecode(s) as Map<String, dynamic>;
    _save();
    notifyListeners();
  }

  Future<void> reset() async {
    _d = {};
    await _p.remove('amir_state');
    notifyListeners();
  }
}
