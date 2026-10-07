import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/pattern.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../screens/shell.dart';
import '../screens/tool_page.dart';
import '../tools/homeplus/gas_tool.dart' show GasStats;
import '../tools/homeplus/hp_common.dart';
import '../tools/homeplus/power_cuts_tool.dart' show cutIntervals;
import '../tools/registry.dart';
import 'calendars.dart';
import 'prayer.dart';

/// ودجات الشاشة الرئيسية في أندرويد (المفضلة، الصلاة، الغاز، القطوعات، الدولار).
///
/// فلاتر يكتب نصوصًا مترجمة جاهزة (JSON واحد لكل ودجت) وكوتلن يعرضها فقط،
/// ويحسب الزمن المتبقي من الساعة الحالية حتى تبقى الودجت صحيحة بدون فتح التطبيق.
/// كل شيء هنا محمي: لا يرمي استثناءً أبدًا، ولا يعمل إلا في أندرويد (لا ويب ولا اختبارات).
class HomeWidgets {
  HomeWidgets._();

  static const _pkg = 'com.albushra.amir_tools.widgets';
  static const favProvider = '$_pkg.FavoritesWidgetProvider';
  static const prayerProvider = '$_pkg.PrayerWidgetProvider';
  static const gasProvider = '$_pkg.GasWidgetProvider';
  static const powerProvider = '$_pkg.PowerCutsWidgetProvider';
  static const fxProvider = '$_pkg.DollarWidgetProvider';

  /// مفتاح الملاح العام (لفتح أداة من رابط الودجت)
  static final navKey = GlobalKey<NavigatorState>();

  static bool? _enabledCache;
  static bool get enabled {
    if (_enabledCache != null) return _enabledCache!;
    var ok = false;
    if (!kIsWeb) {
      try {
        ok = Platform.isAndroid && !Platform.environment.containsKey('FLUTTER_TEST');
      } catch (_) {
        ok = false;
      }
    }
    return _enabledCache = ok;
  }

  static final Map<String, String> _sig = {};
  static Timer? _debounce;
  static bool _attached = false;
  static _Lifecycle? _lifecycle;

  /// يُستدعى مرة بعد تحميل الحالة: تحديث أولي + متابعة التغييرات + روابط الودجت
  static void attach(AppState s) {
    if (!enabled || _attached) return;
    _attached = true;
    try {
      s.addListener(() => _scheduleRefresh(s));
      _lifecycle = _Lifecycle(() => refreshAll(s));
      WidgetsBinding.instance.addObserver(_lifecycle!);
      HomeWidget.widgetClicked.listen(_handleLink, onError: (_) {});
      HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleLink).catchError((_) {});
    } catch (_) {}
    // بعد أول إطار حتى لا يؤخّر فتح التطبيق
    Future.delayed(const Duration(seconds: 2), () => refreshAll(s));
  }

  static void _scheduleRefresh(AppState s) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () => refreshAll(s));
  }

  /// يحدّث كل الودجات (يتخطّى ما لم تتغيّر بياناته إلا مع [force])
  static Future<void> refreshAll(AppState s, {bool force = false}) async {
    if (!enabled) return;
    await refreshPrayer(s, force: force);
    await refreshGas(s, force: force);
    await refreshPower(s, force: force);
    await refreshRates(s, force: force);
    await refreshFavorites(s, force: force);
  }

  static String get _today {
    final n = placeNow();
    return '${n.year}-${n.month}-${n.day}';
  }

  /// يحفظ JSON ويطلب تحديث الودجت إن تغيّر التوقيع
  /// يحسب التوقيع، وإن تغيّر يحفظ JSON الودجت ويطلب تحديثها
  static Future<void> _push(String key, String provider, String Function() sig, Map<String, dynamic> Function() build, bool force) async {
    if (!enabled) return;
    try {
      final g = sig();
      if (!force && _sig[key] == g) return;
      await HomeWidget.saveWidgetData<String>(key, jsonEncode(build()));
      await HomeWidget.updateWidget(qualifiedAndroidName: provider);
      _sig[key] = g;
    } catch (_) {}
  }

  static int _ms(DateTime wall) => placeTZ(wall).millisecondsSinceEpoch;
  static String _shortDate(DateTime d) => '${d.day} ${monthsAr[d.month - 1]}';
  static bool get _rtl => appLang != Lang.en;

  /* ── 2. الصلاة ── */
  static Future<void> refreshPrayer(AppState s, {bool force = false}) => _push('hw_prayer', prayerProvider, () {
        final c = s.city;
        return [appLang.index, c.lat, c.lng, c.name, s.prayerMethod, s.hanafi, jsonEncode(s.prayerAdjust), s.hijriShift, placeTz, _today].join('|');
      }, () => prayerData(s), force);

  /// مواقيت الأيام السبعة القادمة: [{n: الاسم, t: لحظة الأذان, l: الوقت منسّقًا, h: الهجري}]
  @visibleForTesting
  static Map<String, dynamic> prayerData(AppState s) {
    final now = DateTime.now();
    final ev = <Map<String, dynamic>>[];
    for (var d = 0; d < 7; d++) {
      final times = s.timesFor(sudanNow().add(Duration(days: d)));
      for (final k in fardKeys) {
        final at = times[k]!;
        if (at.isBefore(now.subtract(const Duration(hours: 1)))) continue;
        final wall = toSudan(at);
        ev.add({'n': prayerNames[k], 't': at.millisecondsSinceEpoch, 'l': fmtTimeAr(wall), 'h': hijriText(wall, shift: s.hijriShift)});
      }
    }
    return {
      'rtl': _rtl,
      'city': '📍 ${s.city.name}',
      'lbl': t('الصلاة الجاية', 'الصلاة القادمة', 'Next prayer'),
      'empty': t('افتح التطبيق عشان نحدّث المواقيت', 'افتح التطبيق لتحديث المواقيت', 'Open the app to refresh times'),
      'ev': ev,
    };
  }

  /* ── 3. الغاز ── */
  static Future<void> refreshGas(AppState s, {bool force = false}) => _push(
      'hw_gas', gasProvider, () => '${appLang.index}|$placeTz|${jsonEncode(s.getData<List>('gas_list'))}|${jsonEncode(s.getData<Map>('gas_cfg'))}', () => gasData(s), force);

  /// لحظة النفاد المتوقعة وآخر تعبئة (الأيام الباقية تُحسب في كوتلن من الساعة)
  @visibleForTesting
  static Map<String, dynamic> gasData(AppState s) {
    final list = mapList(s.getData<List>('gas_list'));
    final cfg = Map<String, dynamic>.from(s.getData<Map>('gas_cfg') ?? {});
    list.sort((a, b) => (a['d'] as String? ?? '').compareTo(b['d'] as String? ?? ''));
    final st = GasStats(list, numOf(cfg['def'], 30));
    final last = st.last, out = st.runOut;
    final base = <String, dynamic>{
      'rtl': _rtl,
      'title': t('أنبوبة الغاز', 'أسطوانة الغاز', 'Gas cylinder'),
      'empty': t('سجّل أول تعبئة غاز عشان نحسب ليك 🔥', 'سجّل أول تعبئة غاز ليبدأ الحساب 🔥', 'Log your first gas refill to start 🔥'),
    };
    if (last == null || out == null) return base;
    return {
      ...base,
      'out': _ms(out),
      'last': _ms(last),
      'avg': st.avgDays.round(),
      'est': st.estimated,
      'days': t('يوم فاضل', 'يومًا متبقيًا', 'days left'),
      'outL': '${t('بتكمل', 'تنفد', 'Runs out')}: ${_shortDate(out)}${st.estimated ? ' ${t('(تقريبًا)', '(تقديري)', '(est.)')}' : ''}',
      'lastL': '${t('آخر تعبئة', 'آخر تعبئة', 'Last refill')}: ${_shortDate(last)}',
      'today': t('بتكمل الليلة!', 'تنفد اليوم!', 'Runs out today!'),
      'over': t('المفروض خلصت 🔥', 'يُفترض أنها نفدت 🔥', 'Probably empty 🔥'),
    };
  }

  /* ── 4. قطوعات الكهرباء ── */
  static Future<void> refreshPower(AppState s, {bool force = false}) =>
      _push('hw_power', powerProvider, () => '${appLang.index}|$placeTz|${jsonEncode(s.getData<List>('cuts_slots'))}|$_today', () => powerData(s), force);

  /// انتقالات الأيام القادمة [{on, t, l}] وفترات القطع [{s, e, l}] حسب الجدول
  @visibleForTesting
  static Map<String, dynamic> powerData(AppState s) {
    final slots = mapList(s.getData<List>('cuts_slots'));
    final base = <String, dynamic>{
      'rtl': _rtl,
      'title': t('قطوعات الكهرباء', 'انقطاع الكهرباء', 'Power cuts'),
      'empty': t('ضيف جدول القطوعات في الأداة ⚡', 'أضف جدول الانقطاعات في الأداة ⚡', 'Add your cut schedule in the tool ⚡'),
    };
    if (slots.isEmpty) return base;
    final iv = cutIntervals(slots, pToday().subtract(const Duration(days: 1)), 9);
    final evs = <Map<String, dynamic>>[];
    final sl = <Map<String, dynamic>>[];
    for (final (st, en) in iv) {
      evs.add({'on': false, 't': _ms(st), 'l': fmtTimeAr(st)});
      evs.add({'on': true, 't': _ms(en), 'l': fmtTimeAr(en)});
      sl.add({'s': _ms(st), 'e': _ms(en), 'l': '${fmtTimeAr(st)} – ${fmtTimeAr(en)}'});
    }
    return {
      ...base,
      'on': t('الكهرباء جاية ✅', 'الكهرباء متوفرة ✅', 'Power is on ✅'),
      'off': t('الكهرباء قاطعة ⛔', 'الكهرباء مقطوعة ⛔', 'Power is off ⛔'),
      'sched': t('(حسب الجدول)', '(حسب الجدول)', '(by schedule)'),
      'nextOn': t('بترجع', 'تعود', 'Back at'),
      'nextOff': t('بتقطع', 'تنقطع', 'Cut at'),
      'noNext': t('مافي قطوعات جاية', 'لا انقطاعات قادمة', 'No upcoming cuts'),
      'todayL': t('قطوعات الليلة الفاضلة', 'انقطاعات اليوم المتبقية', 'Remaining cuts today'),
      'none': t('مافي قطوعات تانية الليلة 👌', 'لا انقطاعات أخرى اليوم 👌', 'No more cuts today 👌'),
      'ev': evs,
      'sl': sl,
    };
  }

  /* ── 5. الدولار ── */
  static int? _parallelAt(AppState s) {
    final hist = s.getData<List>('parallel_history');
    if (hist == null || hist.isEmpty || hist.last is! Map) return null;
    return ((hist.last as Map)['t'] as num?)?.toInt();
  }

  static Future<void> refreshRates(AppState s, {bool force = false}) => _push(
      'hw_fx', fxProvider, () => '${appLang.index}|${s.sdgParallel}|${s.officialRates?['SDG']}|${_parallelAt(s)}|${s.ratesAt}', () => fxData(s), force);

  /// الموازي والرسمي منسّقين، ووقت آخر تحديث
  @visibleForTesting
  static Map<String, dynamic> fxData(AppState s) {
    final par = s.sdgParallel;
    final off = s.officialRates?['SDG'];
    final at = [_parallelAt(s), s.ratesAt].whereType<int>().fold<int>(0, math.max);
    String upd = '';
    if (at > 0) {
      final w = toSudan(DateTime.fromMillisecondsSinceEpoch(at));
      upd = '${t('آخر تحديث', 'آخر تحديث', 'Updated')}: ${_shortDate(w)} • ${fmtTimeAr(w)}';
    }
    return {
      'rtl': _rtl,
      'title': t('الدولار بالجنيه', 'الدولار بالجنيه', 'USD in SDG'),
      'parL': t('الموازي', 'الموازي', 'Parallel'),
      'offL': t('الرسمي', 'الرسمي', 'Official'),
      'par': par == null ? '—' : fmt(par, 0),
      'off': off == null ? '—' : fmt(off, 0),
      'upd': upd.isEmpty ? t('افتح الأداة عشان نحدّث', 'افتح الأداة للتحديث', 'Open the tool to update') : upd,
    };
  }

  /* ── 1. المفضلة (بلاطات مرسومة كصور) ── */
  static Future<void> refreshFavorites(AppState s, {bool force = false}) async {
    if (!enabled) return;
    try {
      final all = {for (final x in allTools) x.id: x};
      final tools = <ToolDef>[];
      for (final id in s.favorites) {
        final tool = all[id];
        if (tool != null) tools.add(tool);
        if (tools.length == 8) break;
      }
      final sig = '${appLang.index}|${tools.map((x) => '${x.id}:${x.name}').join(',')}';
      if (!force && _sig['hw_fav'] == sig) return;
      // الرسم مكلف: لا نعيده إلا إن تغيّرت المفضلة أو اللغة (التوقيع محفوظ مع بيانات الودجت)
      final saved = await HomeWidget.getWidgetData<String>('hw_fav_sig');
      final hasData = await HomeWidget.getWidgetData<String>('hw_fav');
      if (!force && saved == sig && hasData != null) {
        _sig['hw_fav'] = sig;
        return;
      }
      final dpr = PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 2.0;
      // سقف الدقة: 8 صور تمر عبر RemoteViews (حد الذاكرة/Binder)
      final ratio = dpr.clamp(1.0, 2.5).toDouble();
      final imgs = <String>[];
      for (var i = 0; i < tools.length; i++) {
        final path = await HomeWidget.renderFlutterWidget(
          WidgetToolTile(tools[i], rtl: _rtl),
          key: 'hw_fav_$i',
          logicalSize: WidgetToolTile.size,
          pixelRatio: ratio,
        );
        imgs.add(path);
      }
      await HomeWidget.saveWidgetData<String>(
          'hw_fav',
          jsonEncode({
            'rtl': _rtl,
            'title': tr('أدوات أمير', 'Ameer Tools'),
            'empty': t('ضيف أدوات للمفضلة ⭐ (اضغط مطوّل على أي أداة)', 'أضف أدوات إلى المفضلة ⭐ (ضغطة مطوّلة على أي أداة)', 'Add favourite tools ⭐ (long-press any tool)'),
            'ids': [for (final x in tools) x.id],
            'names': [for (final x in tools) x.name],
            'imgs': imgs,
          }));
      await HomeWidget.saveWidgetData<String>('hw_fav_sig', sig);
      await HomeWidget.updateWidget(qualifiedAndroidName: favProvider);
      _sig['hw_fav'] = sig;
    } catch (_) {}
  }

  /* ── روابط الودجت: ameertools://tool/<id> و ameertools://tab/<name> ── */
  static Uri? _pending;
  static int _shells = 0;

  static void _handleLink(Uri? uri) {
    if (uri == null || uri.scheme != 'ameertools') return;
    _pending = uri;
    _consume();
  }

  static const _tabs = {'home': 0, 'tools': 1, 'prayer': 2, 'points': 3, 'settings': 4};

  static void _consume() {
    // ننتظر حتى يظهر الهيكل (بعد الترحيب وقفل الرمز)
    if (_shells <= 0) return;
    final uri = _pending;
    final nav = navKey.currentState;
    if (uri == null || nav == null) return;
    _pending = null;
    try {
      final arg = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      nav.popUntil((r) => r.isFirst);
      if (uri.host == 'tab') {
        final i = _tabs[arg];
        if (i != null) Shell.tab.value = i;
      } else if (uri.host == 'tool' && arg.isNotEmpty && toolById(arg) != null) {
        ToolPage.open(nav.context, arg);
      }
    } catch (_) {}
  }
}

class _Lifecycle with WidgetsBindingObserver {
  final VoidCallback onResume;
  _Lifecycle(this.onResume);
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}

/// يلفّ الهيكل: يفتح رابط الودجت المعلّق بعد ظهور التطبيق (لا يتجاوز قفل الرمز)
class WidgetLinkGate extends StatefulWidget {
  final Widget child;
  const WidgetLinkGate({super.key, required this.child});
  @override
  State<WidgetLinkGate> createState() => _WidgetLinkGateState();
}

class _WidgetLinkGateState extends State<WidgetLinkGate> {
  @override
  void initState() {
    super.initState();
    HomeWidgets._shells++;
    WidgetsBinding.instance.addPostFrameCallback((_) => HomeWidgets._consume());
  }

  @override
  void dispose() {
    HomeWidgets._shells--;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// بلاطة أداة للودجت (تُرسم صورة PNG): جلد بني، إطار ذهبي، أيقونة الأداة بتدرّج لونها
class WidgetToolTile extends StatelessWidget {
  final ToolDef tool;
  final bool rtl;
  const WidgetToolTile(this.tool, {super.key, this.rtl = true});

  static const size = Size(76, 86);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: SizedBox.fromSize(
        size: size,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A5528), Color(0xFF5E361B)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SD.gold.withValues(alpha: .75), width: 1.2),
          ),
          child: Stack(children: [
            if (tool.sudan) const Positioned(top: 5, left: 5, child: FlagStrip(width: 13, height: 9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(3, 7, 3, 4),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color.lerp(tool.color, Colors.white, .12)!, Color.lerp(tool.color, Colors.black, .3)!],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: SD.goldLight.withValues(alpha: .8), width: 1.2),
                  ),
                  child: Icon(tool.icon, color: Colors.white, size: 23),
                ),
                const SizedBox(height: 5),
                Text(
                  tool.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.1, color: SD.cream),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
