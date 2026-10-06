import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/pattern.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../services/calendars.dart';
import '../services/prayer.dart';
import '../tools/registry.dart';
import 'tool_tile.dart';

/// الصلاة: المواقيت، العدّ التنازلي، تسجيل الصلوات (بنقاط)، وأدوات الصلاة
class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});
  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  Timer? _t;
  int _dayOffset = 0;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final day = sudanNow().add(Duration(days: _dayOffset));
    final times = s.timesFor(day);
    final np = s.nextPrayer();
    final left = np.at.difference(DateTime.now());
    final now = DateTime.now();
    String? current;
    if (_dayOffset == 0) {
      for (final k in prayerKeys) {
        if (!times[k]!.isAfter(now)) current = k;
      }
    }
    final prayed = s.prayedOn(day);
    final dayLen = times['maghrib']!.difference(times['sunrise']!);
    final tools = ['qibla', 'adhkar', 'tasbih', 'khatma', 'monthly', 'dates', 'occasions', 'names99'].map(toolById).whereType<ToolDef>().toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 120),
      children: [
        Center(child: GoldText(tr('الصلاة', 'Prayer'), size: 34)),
        Center(child: Text('${s.city.name} • ${prayerMethods.firstWhere((m) => m.id == s.prayerMethod, orElse: () => prayerMethods.first).name}',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7)))),
        const GoldDivider(),
        ResultHero(
          label: '${t('الصلاة الجاية', 'الصلاة القادمة', 'Next prayer')}: ${prayerNames[np.key]} • ${fmtTimeAr(toSudan(np.at))}',
          value: '${two(left.inHours)}:${two(left.inMinutes % 60)}:${two(left.inSeconds % 60)}',
          sub: '${t('باقي عليها', 'متبقٍّ عليها', 'remaining')} — ${hijriText(sudanNow(), shift: s.hijriShift)}',
        ),
        GoldFrame(
          child: Column(children: [
            Row(children: [
              IconButton(tooltip: t('اليوم القبلو', 'اليوم السابق', 'Previous day'), onPressed: () => setState(() => _dayOffset--), icon: const Icon(Icons.chevron_right_rounded)),
              Expanded(
                child: Column(children: [
                  Text(_dayOffset == 0 ? t('الليلة', 'اليوم', 'Today') : _dayOffset == 1 ? t('بكرة', 'غدًا', 'Tomorrow') : _dayOffset == -1 ? t('أمبارح', 'أمس', 'Yesterday') : fmtDateAr(day),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('${fmtDateAr(day, weekday: true)} • ${hijriText(day, shift: s.hijriShift)}', style: const TextStyle(fontSize: 12)),
                ]),
              ),
              IconButton(tooltip: t('اليوم البعدو', 'اليوم التالي', 'Next day'), onPressed: () => setState(() => _dayOffset++), icon: const Icon(Icons.chevron_left_rounded)),
            ]),
            const SizedBox(height: 6),
            for (final k in prayerKeys) _row(s, k, times[k]!, k == current, prayed.contains(k), day),
            const SizedBox(height: 8),
            if (_dayOffset <= 0 && s.pointsEnabled)
              Text('${t('صلّيت', 'صلّيت', 'Prayed')} ${prayed.length} ${tr('من', 'of')} 5 ${prayed.length == 5 ? '— ${tr('ما شاء الله تبارك الله', 'MashaAllah')} 🌟' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: SD.gold)),
          ]),
        ),
        SCard(
          title: t('تفاصيل اليوم', 'تفاصيل اليوم', 'Day details'),
          icon: Icons.wb_twilight_rounded,
          child: Column(children: [
            InfoRow(tr('طول النهار (من الشروق للمغرب)', 'Daylight (sunrise to sunset)'), fmtDuration(dayLen)),
            InfoRow(tr('طول الليل', 'Night length'), fmtDuration(const Duration(hours: 24) - dayLen)),
            InfoRow(tr('منتصف الليل الشرعي تقريبًا', 'Islamic midnight (approx.)'),
                fmtTimeAr(toSudan(times['maghrib']!.add(times['fajr']!.add(const Duration(days: 1)).difference(times['maghrib']!) ~/ 2)))),
            InfoRow(tr('الثلث الأخير من الليل يبدأ', 'Last third of the night starts'),
                fmtTimeAr(toSudan(times['maghrib']!.add((times['fajr']!.add(const Duration(days: 1)).difference(times['maghrib']!) * 2) ~/ 3)))),
            InfoRow(tr('وقت الضحى (بعد الشروق بـ 15 د)', 'Duha (15 min after sunrise)'), fmtTimeAr(toSudan(times['sunrise']!.add(const Duration(minutes: 15))))),
            InfoRow(tr('اتجاه القبلة', 'Qibla direction'), '${fmt(qiblaBearing(s.city.lat, s.city.lng), 1)}° ${tr('من الشمال', 'from North')}'),
          ]),
        ),
        GoldFrame(title: t('عِدّة الصلاة', 'أدوات الصلاة', 'Prayer tools'), child: ToolGrid(tools)),
        NoteBox(t('المواقيت محسوبة على جهازك. لو في فرق دقيقة أو اتنين مع مسجد حيّك، عدّلها من «الضبط».', 'تُحسب المواقيت على جهازك. إن وُجد فرق دقيقة أو دقيقتين مع مسجد حيّك فعدّلها من «الإعدادات».', 'Times are calculated on your device. If they differ by a minute or two from your local mosque, adjust them in Settings.'), kind: NoteKind.info),
      ],
    );
  }

  Widget _row(AppState s, String k, DateTime at, bool now, bool done, DateTime day) {
    final fard = fardKeys.contains(k);
    final canLog = fard && _dayOffset <= 0 && (_dayOffset < 0 || !at.isAfter(DateTime.now()));
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: now ? SD.gold.withValues(alpha: .25) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: now ? Border.all(color: SD.gold) : null,
      ),
      child: Row(children: [
        Icon(k == 'sunrise' ? Icons.wb_sunny_outlined : Icons.mosque_outlined, color: now ? SD.goldLight : SD.gold, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(prayerNames[k]!, style: TextStyle(fontWeight: now ? FontWeight.w800 : FontWeight.w600, fontSize: 17))),
        Text(fmtTimeAr(toSudan(at)), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        if (fard && s.pointsEnabled)
          IconButton(
            tooltip: t('صلّيت', 'صلّيت', 'Prayed'),
            onPressed: canLog ? () => s.togglePrayed(day, k) : null,
            icon: Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: done ? SD.green : null),
          )
        else
          const SizedBox(width: 48),
      ]),
    );
  }
}
