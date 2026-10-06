import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
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
    final tools = ['qibla', 'adhkar', 'tasbih', 'monthly', 'dates', 'occasions', 'names99'].map(toolById).whereType<ToolDef>().toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 120),
      children: [
        const Center(child: GoldText('الصلاة', size: 34)),
        Center(child: Text('${s.city.name} • ${prayerMethods.firstWhere((m) => m.id == s.prayerMethod).name}',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7)))),
        const GoldDivider(),
        ResultHero(
          label: 'الصلاة الجاية: ${prayerNames[np.key]} • ${fmtTimeAr(toSudan(np.at))}',
          value: '${two(left.inHours)}:${two(left.inMinutes % 60)}:${two(left.inSeconds % 60)}',
          sub: 'باقي عليها — ${hijriText(sudanNow(), shift: s.hijriShift)}',
        ),
        GoldFrame(
          child: Column(children: [
            Row(children: [
              IconButton(tooltip: 'اليوم القبلو', onPressed: () => setState(() => _dayOffset--), icon: const Icon(Icons.chevron_right_rounded)),
              Expanded(
                child: Column(children: [
                  Text(_dayOffset == 0 ? 'الليلة' : _dayOffset == 1 ? 'بكرة' : _dayOffset == -1 ? 'أمبارح' : fmtDateAr(day),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('${fmtDateAr(day, weekday: true)} • ${hijriText(day, shift: s.hijriShift)}', style: const TextStyle(fontSize: 12)),
                ]),
              ),
              IconButton(tooltip: 'اليوم البعدو', onPressed: () => setState(() => _dayOffset++), icon: const Icon(Icons.chevron_left_rounded)),
            ]),
            const SizedBox(height: 6),
            for (final k in prayerKeys) _row(s, k, times[k]!, k == current, prayed.contains(k), day),
            const SizedBox(height: 8),
            if (_dayOffset <= 0 && s.pointsEnabled)
              Text('صلّيت ${prayed.length} من 5 ${prayed.length == 5 ? '— ما شاء الله تبارك الله 🌟' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: SD.gold)),
          ]),
        ),
        SCard(
          title: 'تفاصيل اليوم',
          icon: Icons.wb_twilight_rounded,
          child: Column(children: [
            InfoRow('طول النهار (من الشروق للمغرب)', fmtDuration(dayLen)),
            InfoRow('طول الليل', fmtDuration(const Duration(hours: 24) - dayLen)),
            InfoRow('منتصف الليل الشرعي تقريبًا',
                fmtTimeAr(toSudan(times['maghrib']!.add(times['fajr']!.add(const Duration(days: 1)).difference(times['maghrib']!) ~/ 2)))),
            InfoRow('الثلث الأخير من الليل يبدأ',
                fmtTimeAr(toSudan(times['maghrib']!.add((times['fajr']!.add(const Duration(days: 1)).difference(times['maghrib']!) * 2) ~/ 3)))),
            InfoRow('وقت الضحى (بعد الشروق بـ 15 د)', fmtTimeAr(toSudan(times['sunrise']!.add(const Duration(minutes: 15))))),
            InfoRow('اتجاه القبلة', '${fmt(qiblaBearing(s.city.lat, s.city.lng), 1)}° من الشمال'),
          ]),
        ),
        GoldFrame(title: 'عِدّة الصلاة', child: ToolGrid(tools)),
        const NoteBox('المواقيت محسوبة على جهازك. لو في فرق دقيقة أو اتنين مع مسجد حيّك، عدّلها من «الضبط».', kind: NoteKind.info),
      ],
    );
  }

  Widget _row(AppState s, String k, DateTime t, bool now, bool done, DateTime day) {
    final fard = fardKeys.contains(k);
    final canLog = fard && _dayOffset <= 0 && (_dayOffset < 0 || !t.isAfter(DateTime.now()));
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
        Text(fmtTimeAr(toSudan(t)), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        if (fard && s.pointsEnabled)
          IconButton(
            tooltip: 'صلّيت',
            onPressed: canLog ? () => s.togglePrayed(day, k) : null,
            icon: Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: done ? SD.green : null),
          )
        else
          const SizedBox(width: 48),
      ]),
    );
  }
}
