import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../services/net.dart';

/// مفتاح يوم محلي ثابت (yyyy-mm-dd) — يصلح للفرز
String mkey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

DateTime mDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// يقرأ مفتاح اليوم إلى تاريخ
DateTime? mParseKey(String? k) {
  if (k == null || k.isEmpty) return null;
  final p = k.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// فرق الأيام التقويمية (يتجاهل التوقيت الصيفي)
int mDaysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// المسافة بخط مستقيم (هافرساين) بالكيلومتر
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a.toDouble()).clamp(0.0, 1.0));
}

/// وقت (دقائق من منتصف الليل) بنظام 12 ساعة
String fmtMinutes(int mins) {
  final h = (mins ~/ 60) % 24, m = mins % 60;
  return fmtTimeAr(DateTime(2000, 1, 1, h, m));
}

/// حلقة تقدّم دائرية بمحتوى في الوسط
class MoreRing extends StatelessWidget {
  final double progress;
  final Color color;
  final double size, stroke;
  final Widget child;
  const MoreRing({super.key, required this.progress, required this.color, required this.child, this.size = 200, this.stroke = 14});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(progress.clamp(0, 1).toDouble(), color, Theme.of(context).colorScheme.onSurface.withValues(alpha: .08), stroke),
          child: Center(child: child),
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double p, stroke;
  final Color c, bg;
  _RingPainter(this.p, this.c, this.bg, this.stroke);
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    canvas.drawArc(
        r,
        0,
        math.pi * 2,
        false,
        Paint()
          ..color = bg
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);
    if (p > 0) {
      canvas.drawArc(
          r,
          -math.pi / 2,
          math.pi * 2 * p,
          false,
          Paint()
            ..shader = SweepGradient(
              colors: [c.withValues(alpha: .6), c, c.withValues(alpha: .6)],
              transform: const GradientRotation(-math.pi / 2),
            ).createShader(r)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.p != p || o.c != c;
}

/// أعمدة صغيرة بسيطة (ودجت لا رسّام) — تتبع اتجاه اللغة تلقائيًا
class MiniBars extends StatelessWidget {
  final List<(String label, double value)> bars;
  final double? goal;
  final Color color;
  final double height;
  const MiniBars(this.bars, {super.key, this.goal, this.color = SD.teal, this.height = 120});

  @override
  Widget build(BuildContext context) {
    var mx = goal ?? 0;
    for (final b in bars) {
      mx = math.max(mx, b.$2);
    }
    if (mx <= 0) mx = 1;
    final on = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      height: height,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final b in bars)
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (b.$2 > 0) Text(fmt(b.$2, 0), style: TextStyle(fontSize: 10, color: on.withValues(alpha: .7))),
              const SizedBox(height: 2),
              Container(
                width: 22,
                height: math.max(3, (height - 40) * b.$2 / mx),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: goal != null && b.$2 >= goal! ? [SD.green, SD.green.withValues(alpha: .55)] : [color, color.withValues(alpha: .5)],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(b.$1, style: TextStyle(fontSize: 10, color: on.withValues(alpha: .7)), maxLines: 1, overflow: TextOverflow.clip),
            ]),
          ),
      ]),
    );
  }
}

/// زر اختيار تاريخ موحّد
class MDateButton extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime first, last;
  final ValueChanged<DateTime> onPick;
  final Color color;
  final VoidCallback? onClear;
  const MDateButton(
      {super.key, required this.label, required this.value, required this.first, required this.last, required this.onPick, this.color = SD.teal, this.onClear});

  @override
  Widget build(BuildContext context) {
    final c = readable(context, color);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final now = DateTime.now();
        var init = value ?? now;
        if (init.isBefore(first)) init = first;
        if (init.isAfter(last)) init = last;
        final d = await showDatePicker(context: context, initialDate: init, firstDate: first, lastDate: last, helpText: label);
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Row(children: [
          Icon(Icons.calendar_month_rounded, color: c, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 11.5, color: c, fontWeight: FontWeight.w700)),
              Text(value == null ? t('ما محدد', 'غير محدد', 'Not set') : fmtDateAr(value!, weekday: false),
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
            ]),
          ),
          if (value != null && onClear != null)
            IconButton(visualDensity: VisualDensity.compact, onPressed: onClear, icon: const Icon(Icons.close_rounded, size: 18)),
        ]),
      ),
    );
  }
}

/// نافذة البحث عن أي مدينة في العالم (مع مدن السودان دون إنترنت)
Future<City?> pickPlace(BuildContext context, {String? title}) => showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PlacePicker(title: title ?? t('اختار مدينة', 'اختر مدينة', 'Choose a city')),
    );

class _PlacePicker extends StatefulWidget {
  final String title;
  const _PlacePicker({required this.title});
  @override
  State<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<_PlacePicker> {
  final q = TextEditingController();
  Timer? _deb;
  List<City> results = [];
  bool loading = false;
  String? error;

  @override
  void dispose() {
    _deb?.cancel();
    q.dispose();
    super.dispose();
  }

  void _search(String v) {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 450), () async {
      if (v.trim().length < 2) {
        if (mounted) setState(() => results = []);
        return;
      }
      setState(() {
        loading = true;
        error = null;
      });
      try {
        final r = await searchPlaces(v);
        if (!mounted) return;
        setState(() {
          results = r;
          loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          loading = false;
          error = t('ما قدرنا نبحث — اتأكد من النت', 'تعذّر البحث — تأكد من الاتصال بالإنترنت', "Couldn't search — check your connection");
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final txt = q.text.trim().toLowerCase();
    final local = txt.isEmpty
        ? cities.take(8).toList()
        : cities.where((c) => c.ar.contains(txt) || c.en.toLowerCase().contains(txt)).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .75,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: q,
              autofocus: true,
              onChanged: (v) {
                setState(() {});
                _search(v);
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: t('أكتب اسم المدينة (أي بلد)', 'اكتب اسم المدينة (أي دولة)', 'Type a city name (any country)'),
                suffixIcon: loading ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))) : null,
              ),
            ),
          ),
          if (error != null) Padding(padding: const EdgeInsets.all(8), child: Text(error!, style: const TextStyle(color: SD.red))),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(8, 8, 8, 24), children: [
              for (final c in results)
                ListTile(
                  leading: Text(flagOf(c.country), style: const TextStyle(fontSize: 24)),
                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text([c.state, c.tz].where((x) => x.isNotEmpty).join(' • ')),
                  onTap: () => Navigator.pop(context, c),
                ),
              if (local.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 4),
                  child: Text(t('مدن السودان', 'مدن السودان', 'Sudanese cities'), style: const TextStyle(fontWeight: FontWeight.w800, color: SD.gold)),
                ),
                for (final c in local)
                  ListTile(
                    leading: const Text('🇸🇩', style: TextStyle(fontSize: 24)),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(c.state),
                    onTap: () => Navigator.pop(context, c),
                  ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

/// زر صغير لإضافة/حذف عنصر في قائمة
class MiniIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final String? tip;
  const MiniIconBtn(this.icon, {super.key, this.onTap, this.color = SD.red, this.tip});
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tip,
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
        icon: Icon(icon, color: onTap == null ? null : readable(context, color)),
      );
}
