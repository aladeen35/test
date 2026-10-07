import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/prayer.dart';
import 'learn_common.dart';
import 'learn_notify.dart';

/// ليلة واحدة: من المغرب حتى الفجر التالي (لحظات مطلقة)
class NightSpan {
  final DateTime start, fajr;

  /// تاريخ المساء (بتوقيت المكان) الذي تبدأ فيه الليلة
  final DateTime evening;
  const NightSpan(this.evening, this.start, this.fajr);
  Duration get length => fajr.difference(start);
  DateTime get mid => start.add(Duration(seconds: length.inSeconds ~/ 2));
  DateTime get lastThird => fajr.subtract(Duration(seconds: length.inSeconds ~/ 3));
}

/// الليلة التي تبدأ مساء [evening]: مغرب ذلك اليوم ← فجر اليوم التالي
NightSpan nightOf(Map<String, DateTime> Function(DateTime) timesFor, DateTime evening) {
  final a = timesFor(evening);
  final b = timesFor(lAddDays(evening, 1));
  return NightSpan(evening, a['maghrib']!, b['fajr']!);
}

/// مساء الليلة «الحالية»: قبل فجر اليوم تكون ليلة الأمس ما زالت قائمة
DateTime currentEvening(Map<String, DateTime> Function(DateTime) timesFor, DateTime placeToday, DateTime now) {
  final fajr = timesFor(placeToday)['fajr']!;
  return now.isBefore(fajr) ? lAddDays(placeToday, -1) : placeToday;
}

class LastThirdTool extends StatefulWidget {
  const LastThirdTool({super.key});
  @override
  State<LastThirdTool> createState() => _LastThirdToolState();
}

class _LastThirdToolState extends State<LastThirdTool> {
  Timer? _tick;
  bool _tomorrow = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = context.read<AppState>();
      if (_cfg(s)['notify'] == true) _reschedule(s);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _cfg(AppState s) => Map<String, dynamic>.from(s.getData<Map>('last_third_cfg') ?? const {});
  int _before(AppState s) => lInt(_cfg(s)['before']);

  Future<void> _reschedule(AppState s) async {
    final cfg = _cfg(s);
    if (cfg['notify'] != true) {
      await LearnNotifications.scheduleQiyam(const []);
      return;
    }
    final ev = currentEvening(s.timesFor, lToday(), DateTime.now());
    final list = [
      for (var i = 0; i < 7; i++) nightOf(s.timesFor, lAddDays(ev, i)).lastThird.subtract(Duration(minutes: _before(s))),
    ];
    await LearnNotifications.scheduleQiyam(list);
  }

  Future<void> _setNotify(AppState s, bool v) async {
    if (v && !LearnNotifications.supported) {
      toast(t('التنبيهات بتشتغل في الموبايل بس', 'التنبيهات تعمل على الهاتف فقط', 'Alerts work on phones only'));
      return;
    }
    s.setData('last_third_cfg', {..._cfg(s), 'notify': v});
    if (v) await LearnNotifications.requestPermission();
    await _reschedule(s);
    if (v) {
      toast(t('حنصحّيك أول الثلث الأخير للـ7 ليالي الجاية — افتح الأداة كل كم يوم عشان تتجدد', 'سننبّهك عند بداية الثلث الأخير لسبع ليالٍ — افتح الأداة كل بضعة أيام لتتجدّد',
          'You will be alerted for the next 7 nights — open the tool every few days to renew'));
    }
  }

  String _tm(DateTime x) => fmtTimeAr(toPlace(x));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now();
    final ev0 = currentEvening(s.timesFor, lToday(), now);
    final night = nightOf(s.timesFor, _tomorrow ? lAddDays(ev0, 1) : ev0);
    final third = Duration(seconds: night.length.inSeconds ~/ 3);
    final inLast = !now.isBefore(night.lastThird) && now.isBefore(night.fajr);
    final beforeNight = now.isBefore(night.start);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .65);

    final String heroLabel;
    final String heroValue;
    if (_tomorrow) {
      heroLabel = t('الثلث الأخير ليلة بكرة بيبدأ', 'يبدأ الثلث الأخير ليلة الغد', "Tomorrow night's last third starts");
      heroValue = _tm(night.lastThird);
    } else if (inLast) {
      heroLabel = t('إنت هسي في الثلث الأخير 🌙 فاضل على الفجر', 'أنت الآن في الثلث الأخير 🌙 متبقٍ على الفجر', "You're in the last third now 🌙 Fajr in");
      heroValue = lCountdown(night.fajr.difference(now));
    } else {
      heroLabel = t('فاضل على الثلث الأخير', 'متبقٍ على الثلث الأخير', 'Time until the last third');
      heroValue = lCountdown(night.lastThird.difference(now));
    }

    return ToolList(children: [
      lSegmented<bool>(
        items: [(false, t('الليلة دي', 'الليلة', 'Tonight')), (true, t('ليلة بكرة', 'ليلة الغد', 'Tomorrow'))],
        value: _tomorrow,
        onChanged: (v) => setState(() => _tomorrow = v),
      ),
      const SizedBox(height: 12),
      ResultHero(
        label: heroLabel,
        value: heroValue,
        sub: '${s.city.name} · ${t('ليلة', 'ليلة', 'Night of')} ${fmtDateAr(night.evening)}',
        colors: const [Color(0xFF1F2A5A), Color(0xFF2B1B4A), Color(0xFF140C24)],
      ),
      SCard(
        title: t('تقسيم الليل', 'تقسيم الليل', 'The night divided'),
        icon: Icons.nights_stay_rounded,
        color: SD.indigo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _timeline(context, night, now),
          const SizedBox(height: 12),
          InfoRow(t('المغرب (أول الليل)', 'المغرب (بداية الليل)', 'Maghrib (night begins)'), _tm(night.start), icon: Icons.wb_twilight_rounded),
          InfoRow(t('نص الليل', 'منتصف الليل', 'Midnight (half)'), _tm(night.mid), icon: Icons.brightness_3_rounded),
          InfoRow(t('أول الثلث الأخير', 'بداية الثلث الأخير', 'Last third begins'), _tm(night.lastThird),
              icon: Icons.star_rounded, valueColor: SD.gold),
          InfoRow(t('الفجر (آخر الليل)', 'الفجر (نهاية الليل)', 'Fajr (night ends)'), _tm(night.fajr), icon: Icons.wb_sunny_outlined),
          const SizedBox(height: 8),
          StatGrid([
            StatChip(fmtDuration(night.length), t('طول الليل', 'طول الليل', 'Night length'), color: SD.indigo, icon: Icons.timelapse_rounded),
            StatChip(fmtDuration(third), t('طول التلت', 'طول الثلث', 'One third'), color: SD.gold, icon: Icons.pie_chart_rounded),
            StatChip(
              beforeNight && !_tomorrow ? t('لسه', 'لم يبدأ', 'Not yet') : (inLast && !_tomorrow ? '✓' : '—'),
              t('في الثلث الأخير؟', 'في الثلث الأخير؟', 'In last third?'),
              color: SD.green,
              icon: Icons.nightlight_round,
            ),
          ]),
        ]),
      ),
      SCard(
        title: t('حديث النزول', 'حديث النزول', 'The hadith of descent'),
        icon: Icons.format_quote_rounded,
        color: SD.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text(
            'قال رسول الله ﷺ: «يَنْزِلُ رَبُّنَا تَبَارَكَ وَتَعَالَى كُلَّ لَيْلَةٍ إِلَى السَّمَاءِ الدُّنْيَا حِينَ يَبْقَى ثُلُثُ اللَّيْلِ الآخِرُ، يَقُولُ: مَنْ يَدْعُونِي فَأَسْتَجِيبَ لَهُ، مَنْ يَسْأَلُنِي فَأُعْطِيَهُ، مَنْ يَسْتَغْفِرُنِي فَأَغْفِرَ لَهُ»',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, height: 1.9, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(tr('متفق عليه: رواه البخاري (1145) ومسلم (758) عن أبي هريرة رضي الله عنه', 'Agreed upon: Al-Bukhari (1145) and Muslim (758), narrated by Abu Hurairah'),
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: muted)),
          if (isEn) ...[
            const SizedBox(height: 8),
            Text(
              'Meaning: “Our Lord descends every night to the lowest heaven when the last third of the night remains, saying: Who is calling upon Me that I may answer him? Who is asking of Me that I may give him? Who is seeking My forgiveness that I may forgive him?”',
              style: TextStyle(fontSize: 13, height: 1.5, color: muted),
            ),
          ],
        ]),
      ),
      SCard(
        title: t('الليالي الجاية', 'الليالي القادمة', 'Coming nights'),
        icon: Icons.calendar_view_week_rounded,
        color: SD.nile,
        child: Column(children: [
          for (var i = 0; i < 7; i++)
            Builder(builder: (_) {
              final n = nightOf(s.timesFor, lAddDays(ev0, i));
              return InfoRow(
                '${weekdaysAr[n.evening.weekday - 1]} ${lShort(n.evening)}',
                _tm(n.lastThird),
                hint: '${t('الليل', 'طول الليل', 'Night')} ${fmtDuration(n.length)} · ${t('الفجر', 'الفجر', 'Fajr')} ${_tm(n.fajr)}',
              );
            }),
        ]),
      ),
      SCard(
        title: t('نبّهني', 'التنبيه', 'Alert me'),
        icon: Icons.notifications_active_rounded,
        color: SD.purple,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          lSwitch(
            t('نبّهني أول الثلث الأخير', 'نبّهني عند بداية الثلث الأخير', 'Alert at the start of the last third'),
            _cfg(s)['notify'] == true,
            (v) => _setNotify(s, v),
            sub: t('للـ7 ليالي الجاية', 'للّيالي السبع القادمة', 'For the next 7 nights'),
          ),
          const SizedBox(height: 4),
          Text(t('قبلها بكم دقيقة؟', 'قبلها بكم دقيقة؟', 'How many minutes before?'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          lSegmented<int>(
            items: [(0, t('في وكتو', 'في وقته', 'On time')), (15, '15'), (30, '30')],
            value: const [0, 15, 30].contains(_before(s)) ? _before(s) : 0,
            onChanged: (v) {
              s.setData('last_third_cfg', {..._cfg(s), 'before': v});
              if (_cfg(s)['notify'] == true) _reschedule(s);
            },
          ),
        ]),
      ),
      ShareBar(() => [
            '🌙 ${t('الثلث الأخير من الليل', 'الثلث الأخير من الليل', 'Last third of the night')} — ${s.city.name}',
            '${t('ليلة', 'ليلة', 'Night of')} ${fmtDateAr(night.evening)}',
            '${prayerNames['maghrib']}: ${_tm(night.start)}',
            '${t('نص الليل', 'منتصف الليل', 'Midnight')}: ${_tm(night.mid)}',
            '${t('أول الثلث الأخير', 'بداية الثلث الأخير', 'Last third begins')}: ${_tm(night.lastThird)}',
            '${prayerNames['fajr']}: ${_tm(night.fajr)}',
            '${t('طول الليل', 'طول الليل', 'Night length')}: ${fmtDuration(night.length)}',
          ].join('\n')),
      const SizedBox(height: 12),
      NoteBox(t(
          'الليل هنا محسوب من المغرب لحدي الفجر حسب مواقيت مكانك وطريقة الحساب في الضبط، والتلت الأخير = آخر تلت من المدة دي. نص الليل هنا هو نص المدة دي ما الساعة 12.',
          'يُحسب الليل هنا من المغرب إلى الفجر وفق مواقيت مكانك وطريقة الحساب المختارة، والثلث الأخير هو آخر ثلث من هذه المدة. ومنتصف الليل هو منتصف هذه المدة لا الساعة 12.',
          'The night is counted from Maghrib to Fajr using your place and calculation method; the last third is the final third of that span. “Midnight” here is the midpoint, not 12:00.')),
      NoteBox(
          t('الأوقات تقريبية بالدقايق؛ خلي هامش احتياط قبل الفجر للوتر والسحور.', 'الأوقات تقريبية بالدقائق؛ اترك هامشًا قبل الفجر للوتر والسحور.',
              'Times are approximate to the minute; leave a margin before Fajr for witr and suhoor.'),
          kind: NoteKind.tip),
    ]);
  }

  Widget _timeline(BuildContext context, NightSpan n, DateTime now) {
    final total = n.length.inSeconds.toDouble();
    final pos = total <= 0 ? -1.0 : now.difference(n.start).inSeconds / total;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: 34,
        child: LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth;
          final rtl = Directionality.of(context) == TextDirection.rtl;
          double x(double f) => rtl ? w * (1 - f) : w * f;
          return Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              top: 8,
              bottom: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Row(children: [
                  Expanded(flex: 2, child: Container(color: SD.indigo.withValues(alpha: .55))),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: const BoxDecoration(gradient: LinearGradient(colors: [SD.gold, SD.orange])),
                    ),
                  ),
                ]),
              ),
            ),
            Positioned(left: x(.5) - 1, top: 4, bottom: 4, child: Container(width: 2, color: Colors.white70)),
            if (pos >= 0 && pos <= 1)
              Positioned(
                left: (x(pos) - 7).clamp(0, w - 14).toDouble(),
                top: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  decoration: BoxDecoration(color: SD.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                ),
              ),
          ]);
        }),
      ),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(child: Text('${prayerNames['maghrib']} ${_tm(n.start)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: Text('½ ${_tm(n.mid)}', textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Text('${prayerNames['fajr']} ${_tm(n.fajr)}', textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        ),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: SD.gold, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Expanded(
          child: Text('${t('التلت الأخير', 'الثلث الأخير', 'Last third')}: ${_tm(n.lastThird)} → ${_tm(n.fajr)}',
              maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ),
      ]),
    ]);
  }
}
