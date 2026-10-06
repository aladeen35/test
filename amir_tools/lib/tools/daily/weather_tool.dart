import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data.dart';
import '../../core/format.dart';
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
    final t = iso.split('T').last;
    final h = int.tryParse(t.split(':').first) ?? 0;
    return '${h % 12 == 0 ? 12 : h % 12}${h < 12 ? 'ص' : 'م'}';
  }

  String _dayName(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) return date;
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return 'الليلة';
    return weekdaysAr[d.weekday - 1];
  }

  List<String> _advice(Weather w) {
    final a = <String>[];
    if (w.temp >= 45) {
      a.add('🔥 حر شديد جدًا: ما تطلع في الضهريّة، أشرب موية كل شوية، وانتبه لضربة الشمس عند الكبار والشفّع.');
    } else if (w.temp >= 40) {
      a.add('☀️ حر: أشرب موية كتير، والبس فاتح وواسع، وقلّل الحركة من 12 لـ 4 العصر.');
    }
    if ((w.uv ?? 0) >= 8) a.add('🕶️ الأشعة فوق البنفسجية عالية: طاقية ونضارة شمس.');
    final dust = w.dustAlert;
    if (dust != null) a.add('🌪️ ${dust.text}.');
    if (w.days.isNotEmpty && w.days.first.rain > 5) a.add('🌧️ في مطرة متوقعة: انتبه للسيول والكهرباء، وغطّي العدّة البرّا.');
    if (w.humidity < 15) a.add('💧 الجو ناشف: رطّب جلدك وأشرب موية.');
    if (a.isEmpty) a.add('😌 الجو معقول الليلة — يوم سعيد!');
    return a;
  }

  @override
  Widget build(BuildContext context) {
    final w = _w;
    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      child: ToolList(children: [
        DropdownButtonFormField<String>(
          initialValue: cities.any((c) => c.id == _city.id) ? _city.id : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'المدينة', prefixIcon: Icon(Icons.location_on_rounded)),
          items: [for (final c in cities) DropdownMenuItem(value: c.id, child: Text('${c.name} — ${c.state}'))],
          onChanged: (v) {
            _city = cityById(v!);
            _load();
          },
        ),
        const SizedBox(height: 12),
        if (_loading && w == null)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
        else if (w == null)
          const NoteBox('ما قدرنا نجيب الطقس — اتأكد من النت واسحب لتحت عشان تعيد.', kind: NoteKind.warn)
        else ...[
          _hero(w),
          if (w.dustAlert != null) NoteBox(w.dustAlert!.text, kind: w.dustAlert!.severe ? NoteKind.danger : NoteKind.warn),
          SCard(
            title: 'نصايح الليلة',
            icon: Icons.tips_and_updates_rounded,
            color: SD.gold,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final a in _advice(w)) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(a, style: const TextStyle(height: 1.5))),
            ]),
          ),
          SCard(
            title: 'التفاصيل',
            icon: Icons.analytics_rounded,
            color: SD.nile,
            child: StatGrid([
              StatChip('${w.humidity.round()}%', 'الرطوبة', color: SD.nileLight, icon: Icons.water_drop_rounded),
              StatChip('${w.wind.round()}', 'الرياح كم/س', color: SD.teal, icon: Icons.air_rounded),
              StatChip(w.uv == null ? '—' : fmt(w.uv, 0), 'UV أقصى', color: SD.orange, icon: Icons.wb_sunny_rounded),
              StatChip(w.pm10 == null ? '—' : '${w.pm10!.round()}', 'غبار PM10', color: SD.henna, icon: Icons.blur_on_rounded),
              StatChip(w.aqi == null ? '—' : '${w.aqi!.round()}', 'جودة الهواء', color: SD.purple, icon: Icons.masks_rounded),
              StatChip('${w.feels.round()}°', 'بيحسّ', color: SD.red, icon: Icons.thermostat_rounded),
            ]),
          ),
          if (w.hours.isNotEmpty)
            SCard(
              title: 'الـ 24 ساعة الجاية',
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
            title: 'الأسبوع',
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
                        '${weatherDesc(d.code).$1}${d.rain > 0 ? ' • ${fmt(d.rain, 1)} مم' : ''}\nشروق ${d.sunrise.isEmpty ? '—' : _hhmm(d.sunrise)} • مغيب ${d.sunset.isEmpty ? '—' : _hhmm(d.sunset)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text('${d.max.round()}° / ${d.min.round()}°', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                ),
            ]),
          ),
          Center(child: Text('المصدر: Open-Meteo • اتحدّث ${fmtTimeAr(w.at)}', style: const TextStyle(fontSize: 12))),
        ],
      ]),
    );
  }

  Widget _hero(Weather w) {
    final (desc, emo) = weatherDesc(w.code);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: SD.sunset, begin: Alignment.topRight, end: Alignment.bottomLeft),
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
              Text('العالية ${w.days.first.max.round()}° • الواطية ${w.days.first.min.round()}°', style: const TextStyle(color: Colors.white70)),
          ]),
        ),
      ]),
    );
  }
}
