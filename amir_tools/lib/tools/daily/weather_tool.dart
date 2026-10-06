import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/net.dart';

/// الطقس والغبار: الحالة الحالية، 24 ساعة، 7 أيام، وتنبيهات الحر والهبوب
class WeatherTool extends StatefulWidget {
  const WeatherTool({super.key});
  @override
  State<WeatherTool> createState() => _WeatherToolState();
}

class _WeatherToolState extends State<WeatherTool> {
  late City _city = context.read<AppState>().city;
  Weather? _w;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() => _loading = true);
    final w = await getWeather(context.read<AppState>(), _city, force: force);
    if (mounted) {
      setState(() {
        _w = w;
        _loading = false;
      });
    }
  }

  String _hhmm(String iso) {
    final tm = iso.split('T').last;
    final h = int.tryParse(tm.split(':').first) ?? 0;
    return '${h % 12 == 0 ? 12 : h % 12}${h < 12 ? tr('ص', 'am') : tr('م', 'pm')}';
  }

  String _dayName(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) return date;
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return t('الليلة', 'اليوم', 'Today');
    return weekdaysAr[d.weekday - 1];
  }

  List<String> _advice(Weather w) {
    final a = <String>[];
    if (w.temp >= 45) {
      a.add(t('🔥 حر شديد جدًا: ما تطلع في الضهريّة، أشرب موية كل شوية، وانتبه لضربة الشمس عند الكبار والشفّع.',
          '🔥 حر شديد جدًا: لا تخرج وقت الظهيرة، واشرب الماء باستمرار، وانتبه لضربة الشمس لدى كبار السن والأطفال.',
          '🔥 Extreme heat: stay in at midday, drink water often, and watch for heatstroke in the elderly and children.'));
    } else if (w.temp >= 40) {
      a.add(t('☀️ حر: أشرب موية كتير، والبس فاتح وواسع، وقلّل الحركة من 12 لـ 4 العصر.', '☀️ حر: اشرب ماءً كثيرًا، والبس ملابس فاتحة وواسعة، وقلّل الحركة من 12 ظهرًا إلى 4 عصرًا.',
          '☀️ Hot: drink plenty of water, wear light loose clothes, and limit activity from 12 to 4 pm.'));
    }
    if ((w.uv ?? 0) >= 8) a.add(t('🕶️ الأشعة فوق البنفسجية عالية: طاقية ونضارة شمس.', '🕶️ الأشعة فوق البنفسجية عالية: قبعة ونظارة شمسية.', '🕶️ High UV: wear a hat and sunglasses.'));
    final dust = w.dustAlert;
    if (dust != null) a.add('🌪️ ${dust.text}.');
    if (w.days.isNotEmpty && w.days.first.rain > 5) {
      a.add(t('🌧️ في مطرة متوقعة: انتبه للسيول والكهرباء، وغطّي العدّة البرّا.', '🌧️ أمطار متوقعة: احذر السيول والكهرباء، وغطِّ الأغراض في الخارج.',
          '🌧️ Rain expected: watch out for flooding and electrical hazards, and cover things left outside.'));
    }
    if (w.humidity < 15) a.add(t('💧 الجو ناشف: رطّب جلدك وأشرب موية.', '💧 الجو جاف: رطّب بشرتك واشرب الماء.', '💧 Very dry air: moisturize your skin and drink water.'));
    if (a.isEmpty) a.add(t('😌 الجو معقول الليلة — يوم سعيد!', '😌 الطقس معتدل اليوم — يومًا سعيدًا!', '😌 Pleasant weather today — have a great day!'));
    return a;
  }

  @override
  Widget build(BuildContext context) {
    final w = _w;
    final s = context.watch<AppState>();
    // المكان الحالي للتطبيق (أي مكان في العالم) + المدينة المعروضة + مدن السودان كخيارات سريعة
    final options = <City>[
      if (!cities.any((c) => c.id == s.city.id)) s.city,
      if (_city.id != s.city.id && !cities.any((c) => c.id == _city.id)) _city,
      ...cities,
    ];
    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      child: ToolList(children: [
        DropdownButtonFormField<String>(
          key: ValueKey('wx_${_city.id}_${options.length}'),
          initialValue: _city.id,
          isExpanded: true,
          decoration: InputDecoration(labelText: tr('المكان', 'Place'), prefixIcon: const Icon(Icons.location_on_rounded)),
          items: [
            for (final c in options)
              DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.inSudan ? '' : '${flagOf(c.country)} '}${c.name}${c.state.isEmpty ? '' : ' — ${c.state}'}', overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) {
            _city = options.firstWhere((c) => c.id == v, orElse: () => _city);
            _load();
          },
        ),
        const SizedBox(height: 12),
        if (_loading && w == null)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
        else if (w == null)
          NoteBox(t('ما قدرنا نجيب الطقس — اتأكد من النت واسحب لتحت عشان تعيد.', 'تعذّر جلب الطقس — تأكد من الاتصال واسحب للأسفل لإعادة المحاولة.',
              "Couldn't load the weather — check your connection and pull down to retry."), kind: NoteKind.warn)
        else ...[
          _hero(w),
          if (w.dustAlert != null) NoteBox(w.dustAlert!.text, kind: w.dustAlert!.severe ? NoteKind.danger : NoteKind.warn),
          SCard(
            title: t('نصايح الليلة', 'نصائح اليوم', "Today's tips"),
            icon: Icons.tips_and_updates_rounded,
            color: SD.gold,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final a in _advice(w)) Padding(padding: const EdgeInsetsDirectional.only(bottom: 6), child: Text(a, style: const TextStyle(height: 1.5))),
            ]),
          ),
          SCard(
            title: tr('التفاصيل', 'Details'),
            icon: Icons.analytics_rounded,
            color: SD.nile,
            child: StatGrid([
              StatChip('${w.humidity.round()}%', tr('الرطوبة', 'Humidity'), color: SD.nileLight, icon: Icons.water_drop_rounded),
              StatChip('${w.wind.round()}', tr('الرياح كم/س', 'Wind km/h'), color: SD.teal, icon: Icons.air_rounded),
              StatChip(w.uv == null ? '—' : fmt(w.uv, 0), tr('UV أقصى', 'Max UV'), color: SD.orange, icon: Icons.wb_sunny_rounded),
              StatChip(w.pm10 == null ? '—' : '${w.pm10!.round()}', tr('غبار PM10', 'Dust PM10'), color: SD.henna, icon: Icons.blur_on_rounded),
              StatChip(w.aqi == null ? '—' : '${w.aqi!.round()}', tr('جودة الهواء', 'Air quality'), color: SD.purple, icon: Icons.masks_rounded),
              StatChip('${w.feels.round()}°', t('بيحسّ', 'المحسوسة', 'Feels like'), color: SD.red, icon: Icons.thermostat_rounded),
            ]),
          ),
          if (w.hours.isNotEmpty)
            SCard(
              title: t('الـ 24 ساعة الجاية', 'الـ 24 ساعة القادمة', 'Next 24 hours'),
              icon: Icons.schedule_rounded,
              color: SD.indigo,
              child: SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: w.hours.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final h = w.hours[i];
                    return Container(
                      width: 62,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: SD.gold.withValues(alpha: .1), borderRadius: BorderRadius.circular(16), border: Border.all(color: SD.gold.withValues(alpha: .4))),
                      child: Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        Text(_hhmm(h.time), style: const TextStyle(fontSize: 12)),
                        Text(weatherDesc(h.code).$2, style: const TextStyle(fontSize: 24)),
                        Text('${h.temp.round()}°', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ]),
                    );
                  },
                ),
              ),
            ),
          SCard(
            title: tr('الأسبوع', 'This week'),
            icon: Icons.date_range_rounded,
            color: SD.green,
            child: Column(children: [
              for (final d in w.days)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    SizedBox(width: 70, child: Text(_dayName(d.date), style: const TextStyle(fontWeight: FontWeight.w700))),
                    Text(weatherDesc(d.code).$2, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${weatherDesc(d.code).$1}${d.rain > 0 ? ' • ${fmt(d.rain, 1)} ${tr('مم', 'mm')}' : ''}\n${tr('شروق', 'Sunrise')} ${d.sunrise.isEmpty ? '—' : _hhmm(d.sunrise)} • ${t('مغيب', 'غروب', 'Sunset')} ${d.sunset.isEmpty ? '—' : _hhmm(d.sunset)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text('${d.max.round()}° / ${d.min.round()}°', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                ),
            ]),
          ),
          Center(child: Text(t('المصدر: Open-Meteo • اتحدّث ${fmtTimeAr(w.at)}', 'المصدر: Open-Meteo • آخر تحديث ${fmtTimeAr(w.at)}', 'Source: Open-Meteo • updated ${fmtTimeAr(w.at)}'), style: const TextStyle(fontSize: 12))),
        ],
      ]),
    );
  }

  Widget _hero(Weather w) {
    final (desc, emo) = weatherDesc(w.code);
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: SD.sunset, begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SD.goldLight, width: 2),
      ),
      child: Row(children: [
        Text(emo, style: const TextStyle(fontSize: 64)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${w.temp.round()}°', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w800, height: 1)),
            Text('$desc • ${_city.name}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            if (w.days.isNotEmpty)
              Text(t('العالية ${w.days.first.max.round()}° • الواطية ${w.days.first.min.round()}°', 'العظمى ${w.days.first.max.round()}° • الصغرى ${w.days.first.min.round()}°',
                  'High ${w.days.first.max.round()}° • Low ${w.days.first.min.round()}°'), style: const TextStyle(color: Colors.white70)),
          ]),
        ),
      ]),
    );
  }
}
