import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../core/data.dart';
import '../core/i18n.dart';
import '../core/pattern.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../services/net.dart';
import '../services/notifications.dart';

/// يفتح منتقي المكان: بحث عن أي مدينة في العالم، مدن السودان، الـ GPS، والأماكن المحفوظة.
/// يضبط المكان في AppState مباشرة ويعيد جدولة تنبيهات الصلاة.
Future<void> showPlacePicker(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: SD.gold, width: 1.5),
      ),
      builder: (_) => const _PlacePicker(),
    );

class _PlacePicker extends StatefulWidget {
  const _PlacePicker();
  @override
  State<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<_PlacePicker> {
  final _q = TextEditingController();
  Timer? _debounce;
  List<City> _results = [];
  bool _loading = false, _gpsBusy = false;
  String? _err;

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _search(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      if (v.trim().length < 2) return setState(() => _results = []);
      setState(() {
        _loading = true;
        _err = null;
      });
      try {
        final r = await searchPlaces(v);
        if (mounted) setState(() => _results = r);
      } catch (_) {
        if (mounted) setState(() => _err = t('ما قدرنا نفتّش — اتأكد من النت', 'تعذّر البحث — تحقق من الاتصال', "Couldn't search — check your connection"));
      }
      if (mounted) setState(() => _loading = false);
    });
  }

  void _pick(City c) {
    final s = context.read<AppState>();
    if (cities.any((x) => x.id == c.id)) {
      s.cityId = c.id;
    } else {
      s.setPlace(c);
      s.savePlace(c);
    }
    PrayerNotifications.reschedule(s);
    toast('${flagOf(c.country)} ${c.name} ✓');
    Navigator.pop(context);
  }

  Future<void> _gps() async {
    final s = context.read<AppState>();
    setState(() => _gpsBusy = true);
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        toast(t('ما اتدّى إذن الموقع', 'لم يُمنح إذن الموقع', 'Location permission denied'));
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final tzName = await timezoneFor(pos.latitude, pos.longitude);
      // داخل السودان تقريبًا؟ نعطيه رمز السودان ليستعمل طريقة الحساب المعتمدة
      final inSudan = pos.latitude > 8.5 && pos.latitude < 22.5 && pos.longitude > 21.5 && pos.longitude < 39;
      s.setGps(pos.latitude, pos.longitude, tzName: inSudan && tzName.isEmpty ? 'Africa/Khartoum' : tzName, country: inSudan ? 'SD' : '');
      PrayerNotifications.reschedule(s);
      toast(t('تمام — حدّدنا موقعك 📍', 'تم تحديد موقعك 📍', 'Location set 📍'));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      toast(t('ما قدرنا نحدّد الموقع — شغّل الـ GPS', 'تعذّر تحديد الموقع — شغّل GPS', "Couldn't get location — turn on GPS"));
    } finally {
      if (mounted) setState(() => _gpsBusy = false);
    }
  }

  Widget _tile(City c, {IconData icon = Icons.place_rounded}) => ListTile(
        leading: Text(flagOf(c.country), style: const TextStyle(fontSize: 24)),
        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: c.state.isEmpty ? null : Text(c.state, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Icon(icon, color: SD.gold),
        onTap: () => _pick(c),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final saved = s.savedPlaces;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .85,
        maxChildSize: .95,
        builder: (context, sc) => ListView(controller: sc, padding: const EdgeInsets.fromLTRB(16, 12, 16, 30), children: [
          Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: SD.gold, borderRadius: BorderRadius.circular(3)))),
          const SizedBox(height: 10),
          Center(child: GoldText(t('إنت وين؟', 'أين أنت؟', 'Where are you?'), size: 26)),
          Center(child: Text('${t('هسي', 'الآن', 'Now')}: ${flagOf(s.city.country)} ${s.city.name}', style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(height: 12),
          TextField(
            controller: _q,
            autofocus: false,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: t('فتّش عن أي مدينة في العالم…', 'ابحث عن أي مدينة في العالم…', 'Search any city in the world…'),
              prefixIcon: const Icon(Icons.travel_explore_rounded, color: SD.gold),
              suffixIcon: _loading ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))) : null,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _gpsBusy ? null : _gps,
            icon: const Icon(Icons.my_location_rounded),
            label: Text(_gpsBusy ? t('بنحدّد…', 'جارٍ التحديد…', 'Locating…') : t('استخدم موقعي (GPS)', 'استخدم موقعي (GPS)', 'Use my location (GPS)')),
          ),
          if (_err != null) Padding(padding: const EdgeInsets.all(8), child: Text(_err!, style: const TextStyle(color: SD.red))),
          if (_results.isNotEmpty) ...[
            _head(t('نتايج البحث', 'نتائج البحث', 'Results')),
            for (final c in _results) _tile(c),
          ],
          if (saved.isNotEmpty && _results.isEmpty) ...[
            _head(t('أماكن استعملتها', 'أماكن سابقة', 'Recent places')),
            for (final c in saved) _tile(c, icon: Icons.history_rounded),
          ],
          if (_results.isEmpty) ...[
            _head(t('مدن السودان', 'مدن السودان', 'Sudanese cities')),
            for (final c in cities) _tile(c, icon: Icons.chevron_left_rounded),
          ],
        ]),
      ),
    );
  }

  Widget _head(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
        child: Text(text, style: const TextStyle(color: SD.gold, fontWeight: FontWeight.w800, fontSize: 15)),
      );
}
