import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/data.dart';
import '../core/i18n.dart';
import '../core/state.dart';
import 'home_widgets.dart';
import 'prayer.dart';

/// تحديث أسعار الصرف الرسمية (مجاني بلا مفتاح) — مرة كل 6 ساعات
Future<void> refreshRates(AppState s, {bool force = false}) async {
  final at = s.ratesAt;
  if (!force && at != null && DateTime.now().millisecondsSinceEpoch - at < 6 * 3600 * 1000) return;
  try {
    final r = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD')).timeout(const Duration(seconds: 12));
    final j = jsonDecode(r.body);
    if (j['result'] == 'success') {
      s.setRates((j['rates'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())));
      HomeWidgets.refreshRates(s);
    }
  } catch (_) {/* دون اتصال: نستخدم المحفوظ */}
}

class Weather {
  final DateTime at;
  final double temp, feels, wind, humidity;
  final int code;
  final double? pm10, dust, aqi, uv;
  final List<WeatherDay> days;
  final List<WeatherHour> hours;
  Weather({required this.at, required this.temp, required this.feels, required this.wind, required this.humidity, required this.code,
      this.pm10, this.dust, this.aqi, this.uv, required this.days, required this.hours});

  Map<String, dynamic> toJson() => {
        'at': at.millisecondsSinceEpoch, 'temp': temp, 'feels': feels, 'wind': wind, 'hum': humidity, 'code': code,
        'pm10': pm10, 'dust': dust, 'aqi': aqi, 'uv': uv,
        'days': days.map((d) => [d.date, d.code, d.max, d.min, d.rain, d.sunrise, d.sunset]).toList(),
        'hours': hours.map((h) => [h.time, h.temp, h.code]).toList(),
      };

  factory Weather.fromJson(Map j) => Weather(
        at: DateTime.fromMillisecondsSinceEpoch(j['at']),
        temp: (j['temp'] as num).toDouble(), feels: (j['feels'] as num).toDouble(), wind: (j['wind'] as num).toDouble(),
        humidity: (j['hum'] as num).toDouble(), code: j['code'],
        pm10: (j['pm10'] as num?)?.toDouble(), dust: (j['dust'] as num?)?.toDouble(), aqi: (j['aqi'] as num?)?.toDouble(), uv: (j['uv'] as num?)?.toDouble(),
        days: (j['days'] as List).map((d) => WeatherDay(d[0], d[1], (d[2] as num).toDouble(), (d[3] as num).toDouble(), (d[4] as num?)?.toDouble() ?? 0, d[5] ?? '', d[6] ?? '')).toList(),
        hours: ((j['hours'] as List?) ?? []).map((h) => WeatherHour(h[0], (h[1] as num).toDouble(), h[2])).toList(),
      );

  /// مستوى الغبار/الهبوب: null = عادي
  ({bool severe, String text})? get dustAlert {
    final v = pm10 ?? dust;
    if (v == null) return null;
    if (v >= 400) return (severe: true, text: t('هبوب وغبار كثيف — خليك في البيت وقفّل الشبابيك', 'عاصفة ترابية وغبار كثيف — ابقَ في المنزل وأغلق النوافذ', 'Heavy dust storm — stay indoors and close the windows'));
    if (v >= 150) return (severe: false, text: t('في غبار — الكمامة مفيدة لو عندك حساسية', 'يوجد غبار — الكمامة مفيدة لمرضى الحساسية', 'Dusty air — a mask helps if you have allergies'));
    return null;
  }
}

class WeatherDay {
  final String date, sunrise, sunset;
  final int code;
  final double max, min, rain;
  WeatherDay(this.date, this.code, this.max, this.min, this.rain, this.sunrise, this.sunset);
}

class WeatherHour {
  final String time;
  final double temp;
  final int code;
  WeatherHour(this.time, this.temp, this.code);
}

/// وصف ورمز حالة الطقس (رموز WMO)
(String, String) weatherDesc(int code) => switch (code) {
      0 => (t('صحو', 'صافٍ', 'Clear'), '☀️'),
      1 => (t('صحو غالبًا', 'صافٍ غالبًا', 'Mostly clear'), '🌤️'),
      2 => (t('غيم متفرق', 'غائم جزئيًا', 'Partly cloudy'), '⛅'),
      3 => (t('غيم', 'غائم', 'Cloudy'), '☁️'),
      45 || 48 => (tr('ضباب', 'Fog'), '🌫️'),
      51 || 53 || 55 => (tr('رذاذ', 'Drizzle'), '🌦️'),
      61 || 80 => (t('مطرة خفيفة', 'مطر خفيف', 'Light rain'), '🌦️'),
      63 || 81 => (t('مطرة', 'مطر', 'Rain'), '🌧️'),
      65 || 82 => (t('مطرة شديدة', 'مطر غزير', 'Heavy rain'), '🌧️'),
      71 || 73 || 75 || 77 || 85 || 86 => (tr('ثلج', 'Snow'), '❄️'),
      95 || 96 || 99 => (t('رعد وبرق', 'عاصفة رعدية', 'Thunderstorm'), '⛈️'),
      _ => ('—', '🌡️'),
    };

/// جلب الطقس وجودة الهواء لمدينة (مع تخزين 30 دقيقة)
Future<Weather?> getWeather(AppState s, City c, {bool force = false}) async {
  final key = 'wx_${c.lat.toStringAsFixed(2)}_${c.lng.toStringAsFixed(2)}';
  final cached = s.getData<Map>(key);
  Weather? old;
  if (cached != null) {
    try {
      old = Weather.fromJson(cached);
    } catch (_) {}
  }
  if (!force && old != null && DateTime.now().difference(old.at).inMinutes < 30) return old;
  try {
    final q = 'latitude=${c.lat}&longitude=${c.lng}&timezone=auto';
    final res = await Future.wait([
      http.get(Uri.parse('https://api.open-meteo.com/v1/forecast?$q&current=temperature_2m,apparent_temperature,weather_code,relative_humidity_2m,wind_speed_10m'
          '&hourly=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,uv_index_max,precipitation_sum,sunrise,sunset&forecast_days=7')),
      http.get(Uri.parse('https://air-quality-api.open-meteo.com/v1/air-quality?$q&current=pm10,dust,us_aqi')),
    ]).timeout(const Duration(seconds: 15));
    final f = jsonDecode(res[0].body);
    Map? a;
    try {
      a = jsonDecode(res[1].body)['current'];
    } catch (_) {}
    final cur = f['current'], d = f['daily'], h = f['hourly'];
    // أوقات Open-Meteo بتوقيت الخرطوم المحلي: نقارنها بساعة الحائط السودانية
    final wall = sudanNow().subtract(const Duration(hours: 1));
    final nowIdx = (h['time'] as List).indexWhere((t) => DateTime.parse('${t}Z').isAfter(wall));
    final start = nowIdx < 0 ? 0 : nowIdx;
    final w = Weather(
      at: DateTime.now(),
      temp: (cur['temperature_2m'] as num).toDouble(),
      feels: (cur['apparent_temperature'] as num).toDouble(),
      wind: (cur['wind_speed_10m'] as num).toDouble(),
      humidity: (cur['relative_humidity_2m'] as num).toDouble(),
      code: cur['weather_code'],
      pm10: (a?['pm10'] as num?)?.toDouble(),
      dust: (a?['dust'] as num?)?.toDouble(),
      aqi: (a?['us_aqi'] as num?)?.toDouble(),
      uv: ((d['uv_index_max'] as List?)?.first as num?)?.toDouble(),
      days: [
        for (var i = 0; i < (d['time'] as List).length; i++)
          WeatherDay(d['time'][i], d['weather_code'][i], (d['temperature_2m_max'][i] as num).toDouble(), (d['temperature_2m_min'][i] as num).toDouble(),
              ((d['precipitation_sum']?[i] ?? 0) as num).toDouble(), d['sunrise']?[i] ?? '', d['sunset']?[i] ?? ''),
      ],
      hours: [
        for (var i = start; i < start + 24 && i < (h['time'] as List).length; i++)
          WeatherHour(h['time'][i], (h['temperature_2m'][i] as num).toDouble(), h['weather_code'][i]),
      ],
    );
    s.setData(key, w.toJson());
    return w;
  } catch (_) {
    return old;
  }
}


/// البحث عن أي مدينة في العالم (Open-Meteo Geocoding، بلا مفاتيح)
Future<List<City>> searchPlaces(String query) async {
  final q = query.trim();
  if (q.length < 2) return [];
  final lang = isEn ? 'en' : 'ar';
  final r = await http
      .get(Uri.parse('https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(q)}&count=15&language=$lang&format=json'))
      .timeout(const Duration(seconds: 12));
  final j = jsonDecode(r.body);
  return [
    for (final e in (j['results'] as List? ?? []))
      City.place(
        'geo_${e['id']}',
        e['name'] ?? '',
        [e['admin1'], e['country']].whereType<String>().where((x) => x.isNotEmpty).join('، '),
        (e['latitude'] as num).toDouble(),
        (e['longitude'] as num).toDouble(),
        country: e['country_code'] ?? '',
        tz: e['timezone'] ?? '',
      ),
  ];
}

/// المنطقة الزمنية لإحداثيات (للـ GPS) — فارغة إن تعذّر الاتصال
Future<String> timezoneFor(double lat, double lng) async {
  try {
    final r = await http
        .get(Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&timezone=auto&forecast_days=1&daily=sunrise'))
        .timeout(const Duration(seconds: 10));
    return (jsonDecode(r.body)['timezone'] as String?) ?? '';
  } catch (_) {
    return '';
  }
}
