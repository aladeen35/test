import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/prayer.dart';
import 'more_common.dart';

/// مدينة في ساعات العالم (بأسماء عربية وإنجليزية)
class WClock {
  final String id, ar, en, country, tzName;
  final double lat, lng;
  const WClock(this.id, this.ar, this.en, this.country, this.tzName, this.lat, this.lng);
  String get name => isEn ? en : ar;

  Map<String, dynamic> toJson() => {'id': id, 'ar': ar, 'en': en, 'c': country, 'tz': tzName, 'lat': lat, 'lng': lng};
  static WClock fromJson(Map j) => WClock(j['id'] ?? '', j['ar'] ?? '', j['en'] ?? j['ar'] ?? '', j['c'] ?? '', j['tz'] ?? '',
      (j['lat'] as num?)?.toDouble() ?? 0, (j['lng'] as num?)?.toDouble() ?? 0);
  static WClock fromCity(City c) => WClock(c.id, c.ar, c.en, c.country, c.tz, c.lat, c.lng);
}

const _defaults = [
  WClock('khartoum', 'الخرطوم', 'Khartoum', 'SD', 'Africa/Khartoum', 15.5007, 32.5599),
  WClock('makkah', 'مكة المكرمة', 'Makkah', 'SA', 'Asia/Riyadh', 21.4225, 39.8262),
  WClock('dubai', 'دبي', 'Dubai', 'AE', 'Asia/Dubai', 25.2048, 55.2708),
  WClock('cairo', 'القاهرة', 'Cairo', 'EG', 'Africa/Cairo', 30.0444, 31.2357),
  WClock('london', 'لندن', 'London', 'GB', 'Europe/London', 51.5074, -0.1278),
  WClock('newyork', 'نيويورك', 'New York', 'US', 'America/New_York', 40.7128, -74.0060),
];

/// فرق التوقيت عن UTC لمنطقة زمنية في لحظة معيّنة (فارغة = توقيت الجهاز)
Duration tzOffset(String name, DateTime instant) {
  if (name.isNotEmpty) {
    try {
      return tz.getLocation(name).timeZone(instant.millisecondsSinceEpoch).offset;
    } catch (_) {}
  }
  return instant.toLocal().timeZoneOffset;
}

bool tzIsDst(String name, DateTime instant) {
  if (name.isEmpty) return false;
  try {
    return tz.getLocation(name).timeZone(instant.millisecondsSinceEpoch).isDst;
  } catch (_) {
    return false;
  }
}

/// ساعة الحائط في منطقة (حقول DateTime فقط للعرض)
DateTime wallIn(String name, DateTime instant) => instant.toUtc().add(tzOffset(name, instant));

String fmtOffset(Duration d, {bool utc = false}) {
  final neg = d.isNegative;
  final m = d.inMinutes.abs();
  final s = '${neg ? '-' : '+'}${m ~/ 60}${m % 60 == 0 ? '' : ':${two(m % 60)}'}';
  return utc ? 'UTC$s' : s;
}

class WorldClockTool extends StatefulWidget {
  const WorldClockTool({super.key});
  @override
  State<WorldClockTool> createState() => _WorldClockToolState();
}

class _WorldClockToolState extends State<WorldClockTool> {
  Timer? _tick;
  List<WClock> clocks = [];
  String? familyId;
  RangeValues awake = const RangeValues(8, 22);
  double shiftHours = 0;
  bool showSeconds = true;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final saved = s.getData<List>('world_clock_places');
    clocks = saved == null ? [..._defaults] : saved.whereType<Map>().map(WClock.fromJson).toList();
    final cfg = s.getData<Map>('world_clock_cfg');
    if (cfg != null) {
      familyId = cfg['fam'];
      awake = RangeValues((cfg['a0'] as num?)?.toDouble() ?? 8, (cfg['a1'] as num?)?.toDouble() ?? 22);
      showSeconds = cfg['sec'] ?? true;
    }
    familyId ??= clocks.isNotEmpty ? clocks.first.id : null;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _save() {
    final s = context.read<AppState>();
    s.setData('world_clock_places', clocks.map((c) => c.toJson()).toList());
    s.setData('world_clock_cfg', {'fam': familyId, 'a0': awake.start, 'a1': awake.end, 'sec': showSeconds});
  }

  Future<void> _add() async {
    final c = await pickPlace(context, title: t('ضيف ساعة لمدينة', 'أضف ساعة لمدينة', 'Add a city clock'));
    if (c == null || !mounted) return;
    if (clocks.any((x) => x.id == c.id)) {
      toast(t('المدينة دي موجودة أصلًا', 'هذه المدينة موجودة مسبقًا', 'That city is already on the list'));
      return;
    }
    setState(() => clocks.add(WClock.fromCity(c)));
    _save();
    toast(t('اتضافت ${c.name} ✓', 'أُضيفت ${c.name} ✓', '${c.name} added ✓'));
  }

  void _move(int i, int dir) {
    final j = i + dir;
    if (j < 0 || j >= clocks.length) return;
    setState(() {
      final x = clocks.removeAt(i);
      clocks.insert(j, x);
    });
    _save();
  }

  /// هل الوقت نهار في المكان (بين الشروق والمغرب) — بحساب الشمس
  ({bool day, DateTime? rise, DateTime? set}) _sun(WClock c, DateTime instant) {
    try {
      final w = wallIn(c.tzName, instant);
      final pt = prayerTimes(w.year, w.month, w.day, c.lat, c.lng);
      final rise = pt['sunrise']!, set = pt['maghrib']!;
      if (rise.isAfter(set) || rise.year < 1900) throw 0;
      return (day: instant.isAfter(rise) && instant.isBefore(set), rise: rise, set: set);
    } catch (_) {
      final h = wallIn(c.tzName, instant).hour;
      return (day: h >= 6 && h < 18, rise: null, set: null);
    }
  }

  String _dayRel(DateTime wall, DateTime myWall) {
    final d = mDaysBetween(DateTime(myWall.year, myWall.month, myWall.day), DateTime(wall.year, wall.month, wall.day));
    if (d == 0) return tr('اليوم', 'Today');
    if (d == 1) return t('بكرة', 'غدًا', 'Tomorrow');
    if (d == -1) return t('أمبارح', 'أمس', 'Yesterday');
    return fmtDateAr(wall, weekday: false);
  }

  String _diffText(Duration diff) {
    if (diff == Duration.zero) return t('نفس وقتك', 'نفس توقيتك', 'Same as you');
    final m = diff.inMinutes.abs();
    final h = m ~/ 60, mm = m % 60;
    final amount = isEn
        ? '${h > 0 ? '${h}h' : ''}${mm > 0 ? ' ${mm}m' : ''}'.trim()
        : '${h > 0 ? '$h س' : ''}${mm > 0 ? ' $mm د' : ''}'.trim();
    return diff.isNegative
        ? t('ورانا بـ $amount', 'متأخرة عنك $amount', '$amount behind')
        : t('قدّامنا بـ $amount', 'متقدمة عنك $amount', '$amount ahead');
  }

  String _clockText(DateTime w, {bool secs = false}) {
    final h = w.hour % 12 == 0 ? 12 : w.hour % 12;
    final am = w.hour < 12;
    return '$h:${two(w.minute)}${secs ? ':${two(w.second)}' : ''} ${isEn ? (am ? 'AM' : 'PM') : (am ? 'ص' : 'م')}';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final realNow = DateTime.now();
    final now = realNow.add(Duration(minutes: (shiftHours * 60).round()));
    final me = WClock('me', s.city.ar, s.city.en, s.city.country, s.city.tz, s.city.lat, s.city.lng);
    final myOff = placeOffset(now);
    final myWall = now.toUtc().add(myOff);
    final mySun = _sun(me, now);
    final shifted = shiftHours != 0;

    return ToolList(children: [
      ResultHero(
        label: '${flagOf(s.city.country)} ${t('الساعة عندك في', 'الوقت الآن في', 'Your time in')} ${s.city.name}${shifted ? ' (${t('مخطط', 'مخطط', 'planned')})' : ''}',
        value: _clockText(myWall, secs: showSeconds && !shifted),
        sub: '${fmtDateAr(myWall)} • ${fmtOffset(myOff, utc: true)} ${mySun.day ? '☀️' : '🌙'}',
      ),
      // تخطيط: حرّك الوقت لتشوف الساعة في كل مكان
      SCard(
        title: t('خطّط موعد (حرّك الوقت)', 'خطّط لموعد (حرّك الوقت)', 'Plan a time (shift the clock)'),
        icon: Icons.tune_rounded,
        color: SD.indigo,
        trailing: shifted
            ? TextButton(onPressed: () => setState(() => shiftHours = 0), child: Text(t('هسي', 'الآن', 'Now')))
            : null,
        child: Column(children: [
          Slider(
            value: shiftHours,
            min: -12,
            max: 24,
            divisions: 72,
            label: shiftHours == 0 ? t('هسي', 'الآن', 'Now') : '${shiftHours > 0 ? '+' : ''}${fmt(shiftHours, 1)} ${tr('س', 'h')}',
            onChanged: (v) => setState(() => shiftHours = v),
          ),
          Text(
            shifted
                ? t('لمّن تكون الساعة عندك ${_clockText(myWall)} — شوف الساعات تحت', 'عندما تكون الساعة عندك ${_clockText(myWall)} — انظر الساعات أدناه',
                    'When it is ${_clockText(myWall)} for you — see the clocks below')
                : t('حرّك المؤشر عشان تعرف الساعة كم في كل مدينة في وقت معيّن', 'حرّك المؤشر لتعرف الوقت في كل مدينة في لحظة معيّنة',
                    'Drag to see what time it will be in every city'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5),
          ),
        ]),
      ),
      SectionTitle(t('ساعاتك', 'الساعات', 'Your clocks'), icon: Icons.public_rounded,
          trailing: IconButton.filledTonal(onPressed: _add, icon: const Icon(Icons.add_rounded), tooltip: t('ضيف مدينة', 'أضف مدينة', 'Add city'))),
      if (clocks.isEmpty)
        NoteBox(t('ما في ساعات — دوس + وضيف مدينة', 'لا توجد ساعات — اضغط + لإضافة مدينة', 'No clocks yet — tap + to add a city')),
      for (var i = 0; i < clocks.length; i++) _clockCard(clocks[i], i, now, myWall, myOff),
      if (clocks.length < _defaults.length || _defaults.any((d) => !clocks.any((c) => c.id == d.id)))
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                for (final d in _defaults) {
                  if (!clocks.any((c) => c.id == d.id)) clocks.add(d);
                }
              });
              _save();
            },
            icon: const Icon(Icons.restore_rounded),
            label: Text(t('رجّع المدن الأساسية', 'استعادة المدن الافتراضية', 'Restore default cities')),
          ),
        ),
      const SizedBox(height: 8),
      _callHelper(now),
      SCard(
        title: t('ضبط', 'الإعدادات', 'Settings'),
        icon: Icons.settings_rounded,
        color: SD.coffee,
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t('أعرض الثواني', 'عرض الثواني', 'Show seconds')),
          value: showSeconds,
          onChanged: (v) {
            setState(() => showSeconds = v);
            _save();
          },
        ),
      ),
      NoteBox(
          t('الساعات بتتحسب من الجهاز وبتعرف التوقيت الصيفي براها (بدون نت). النهار والليل محسوبين من الشروق والمغرب في كل مدينة.',
              'تُحسب الساعات محليًا على الجهاز مع مراعاة التوقيت الصيفي تلقائيًا (دون إنترنت). النهار والليل محسوبان من الشروق والغروب في كل مدينة.',
              'Clocks are computed on-device and handle daylight saving automatically (offline). Day/night uses each city\'s sunrise and sunset.'),
          kind: NoteKind.info),
    ]);
  }

  Widget _clockCard(WClock c, int i, DateTime now, DateTime myWall, Duration myOff) {
    final off = tzOffset(c.tzName, now);
    final wall = now.toUtc().add(off);
    final sun = _sun(c, now);
    final dst = tzIsDst(c.tzName, now);
    final diff = off - myOff;
    final h = wall.hour;
    final awakeNow = h >= awake.start && h < awake.end;
    final fam = c.id == familyId;
    final color = sun.day ? SD.gold : SD.indigo;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: sun.day
              ? [const Color(0xFFF2C66B).withValues(alpha: .28), const Color(0xFF8A5528).withValues(alpha: .18)]
              : [const Color(0xFF2B2466).withValues(alpha: .55), const Color(0xFF3A1F0C).withValues(alpha: .35)],
        ),
        border: Border.all(color: fam ? SD.green : color.withValues(alpha: .55), width: fam ? 2 : 1.2),
      ),
      child: Row(children: [
        Column(children: [
          Text(sun.day ? '☀️' : '🌙', style: const TextStyle(fontSize: 28)),
          Text(flagOf(c.country), style: const TextStyle(fontSize: 18)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
              if (fam) ...[const SizedBox(width: 6), const Icon(Icons.favorite_rounded, color: SD.green, size: 16)],
            ]),
            Text('${_dayRel(wall, myWall)} • ${_diffText(diff)}', style: const TextStyle(fontSize: 12.5)),
            Text(
              [
                fmtOffset(off, utc: true),
                if (dst) t('توقيت صيفي', 'توقيت صيفي', 'DST'),
                if (sun.rise != null) '🌅 ${fmtTimeAr(wallIn(c.tzName, sun.rise!))}',
                if (sun.set != null) '🌇 ${fmtTimeAr(wallIn(c.tzName, sun.set!))}',
              ].join('  •  '),
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65)),
            ),
            if (!awakeNow)
              Text(t('😴 غالبًا نايمين هسي', '😴 على الأرجح نائمون الآن', '😴 Probably asleep now'),
                  style: TextStyle(fontSize: 11.5, color: readable(context, SD.henna), fontWeight: FontWeight.w700)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_clockText(wall, secs: showSeconds && shiftHours == 0),
              textDirection: TextDirection.ltr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: readable(context, color))),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (v) {
              switch (v) {
                case 'up':
                  _move(i, -1);
                case 'down':
                  _move(i, 1);
                case 'fam':
                  setState(() => familyId = c.id);
                  _save();
                case 'copy':
                  copyText('${c.name}: ${_clockText(wall)} — ${fmtDateAr(wall)} (${fmtOffset(off, utc: true)})');
                case 'del':
                  setState(() {
                    clocks.removeAt(i);
                    if (familyId == c.id) familyId = clocks.isEmpty ? null : clocks.first.id;
                  });
                  _save();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'fam', child: Text(t('دي مدينة أهلي (للاتصال)', 'مدينة الأهل (لأفضل وقت اتصال)', 'Family city (for calls)'))),
              if (i > 0) PopupMenuItem(value: 'up', child: Text(t('طلّعها فوق', 'نقل لأعلى', 'Move up'))),
              if (i < clocks.length - 1) PopupMenuItem(value: 'down', child: Text(t('نزّلها تحت', 'نقل لأسفل', 'Move down'))),
              PopupMenuItem(value: 'copy', child: Text(tr('نسخ الوقت', 'Copy time'))),
              PopupMenuItem(value: 'del', child: Text(t('امسحها', 'حذف', 'Remove'), style: const TextStyle(color: SD.red))),
            ],
          ),
        ]),
      ]),
    );
  }

  /// أنسب وقت للاتصال بالأهل: الطرفين صاحيين (بين ساعة الصحيان والنوم)
  Widget _callHelper(DateTime now) {
    final fam = clocks.where((c) => c.id == familyId).firstOrNull;
    final a0 = awake.start.round(), a1 = awake.end.round();
    Widget body;
    if (fam == null) {
      body = Text(t('اختار مدينة أهلك من قائمة (…) في أي ساعة', 'اختر مدينة الأهل من قائمة (…) في أي ساعة', 'Pick a family city from the (…) menu on any clock'));
    } else {
      // نقسّم الـ 24 ساعة القادمة إلى أنصاف ساعات
      final start = DateTime.fromMillisecondsSinceEpoch((now.millisecondsSinceEpoch ~/ 1800000) * 1800000);
      final slots = <(DateTime, bool)>[];
      for (var k = 0; k < 48; k++) {
        final at = start.add(Duration(minutes: 30 * k));
        final hf = wallIn(fam.tzName, at);
        final mine = toPlace(at);
        bool ok(DateTime w) {
          final x = w.hour + w.minute / 60;
          return x >= a0 && x < a1;
        }

        slots.add((at, ok(mine) && ok(hf)));
      }
      // تجميع الفترات المتصلة
      final windows = <(DateTime, DateTime)>[];
      DateTime? ws;
      for (var k = 0; k < slots.length; k++) {
        if (slots[k].$2 && ws == null) ws = slots[k].$1;
        if (!slots[k].$2 && ws != null) {
          windows.add((ws, slots[k].$1));
          ws = null;
        }
      }
      if (ws != null) windows.add((ws, slots.last.$1.add(const Duration(minutes: 30))));
      final goodNow = slots.first.$2;
      String myT(DateTime at) => fmtTimeAr(toPlace(at));
      String famT(DateTime at) => fmtTimeAr(wallIn(fam.tzName, at));
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (goodNow ? SD.green : SD.henna).withValues(alpha: .14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Icon(goodNow ? Icons.call_rounded : Icons.phone_disabled_rounded, color: readable(context, goodNow ? SD.green : SD.henna)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                goodNow
                    ? t('هسي وقت مناسب — كلّم ناس ${fam.name} 📞', 'الآن وقت مناسب للاتصال بـ${fam.name} 📞', 'Good time to call ${fam.name} now 📞')
                    : t('هسي ما مناسب — في واحد فيكم غالبًا نايم', 'الوقت الآن غير مناسب — أحدكما غالبًا نائم', 'Not ideal now — one of you is likely asleep'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        // شريط الـ 24 ساعة
        Row(children: [
          for (final sl in slots)
            Expanded(
              child: Container(
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: .5),
                decoration: BoxDecoration(
                  color: sl.$2 ? SD.green : SD.henna.withValues(alpha: .25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(tr('الآن', 'Now'), style: const TextStyle(fontSize: 11)),
          Text(t('بعد 24 ساعة', 'بعد 24 ساعة', '+24h'), style: const TextStyle(fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        if (windows.isEmpty)
          NoteBox(t('ما في وقت مشترك صاحيين فيهو الاتنين — جرّب توسّع ساعات الصحيان', 'لا يوجد وقت مشترك يكون فيه الطرفان مستيقظين — جرّب توسيع ساعات اليقظة',
              'No shared waking hours — try widening the awake range'), kind: NoteKind.warn),
        for (final w in windows)
          InfoRow(
            '${myT(w.$1)} – ${myT(w.$2)}',
            '${famT(w.$1)} – ${famT(w.$2)}',
            icon: Icons.schedule_rounded,
            hint: '${t('عندك', 'بتوقيتك', 'Your time')} • ${t('عندهم في', 'بتوقيت', 'Their time in')} ${fam.name}: ${fmtDuration(w.$2.difference(w.$1))}',
            valueColor: SD.green,
          ),
      ]);
    }
    return SCard(
      title: t('أحسن وقت تتصل بأهلك', 'أفضل وقت للاتصال بالأهل', 'Best time to call family'),
      icon: Icons.family_restroom_rounded,
      color: SD.green,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        body,
        const SizedBox(height: 10),
        Text('${t('ساعات الصحيان', 'ساعات اليقظة', 'Awake hours')}: ${fmtMinutes(a0 * 60)} – ${fmtMinutes(a1 * 60 % 1440)}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        RangeSlider(
          values: awake,
          min: 0,
          max: 24,
          divisions: 24,
          labels: RangeLabels(fmtMinutes(a0 * 60), fmtMinutes(a1 * 60 % 1440)),
          onChanged: (v) {
            if (v.end - v.start < 2) return;
            setState(() => awake = v);
          },
          onChangeEnd: (_) => _save(),
        ),
      ]),
    );
  }
}
