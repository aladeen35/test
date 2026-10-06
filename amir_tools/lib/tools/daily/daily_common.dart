import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/date_input.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';

/// زر اختيار تاريخ بشكل موحّد
class DateButton extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime first, last;
  final ValueChanged<DateTime> onPick;
  final Color color;
  final IconData icon;
  const DateButton({
    super.key,
    required this.label,
    required this.value,
    required this.first,
    required this.last,
    required this.onPick,
    this.color = SD.henna,
    this.icon = Icons.calendar_month_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final init = value ?? (last.isBefore(DateTime.now()) ? last : DateTime.now());
        final d = await pickDate(
          context: context,
          initialDate: init.isBefore(first) ? first : (init.isAfter(last) ? last : init),
          firstDate: first,
          lastDate: last,
          helpText: label,
          cancelText: t('خلاص', 'إلغاء', 'Cancel'),
          confirmText: t('تمام', 'موافق', 'OK'),
          initialEntryMode: DatePickerEntryMode.calendar,
        );
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Row(children: [
          Icon(icon, color: readable(context, color)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 12, color: readable(context, color), fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(value == null ? t('دوس هنا واختار التاريخ', 'اضغط هنا واختر التاريخ', 'Tap here to pick a date') : fmtDateAr(value!),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
          ),
          Icon(Icons.edit_calendar_rounded, color: color.withValues(alpha: .7)),
        ]),
      ),
    );
  }
}

/// عمود في رسم الأعمدة البسيط
class Bar {
  final String label;
  final double value;
  final Color? color;

  /// قيمة ثانوية اختيارية تُرسم كنقطة (مثل المزاج)
  final double? dot;
  const Bar(this.label, this.value, {this.color, this.dot});
}

/// رسم أعمدة بسيط مع خط هدف اختياري
class BarChart extends StatelessWidget {
  final List<Bar> bars;
  final double? goal;
  final double? maxValue;
  final Color color;
  final double height;
  final String Function(double)? valueText;

  /// أقصى قيمة لمحور النقاط (مثل المزاج 5)
  final double dotMax;
  final Color dotColor;
  const BarChart(this.bars,
      {super.key, this.goal, this.maxValue, this.color = SD.nile, this.height = 170, this.valueText, this.dotMax = 5, this.dotColor = SD.pink});

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarPainter(bars, goal, maxValue, color, on, valueText, dotMax, dotColor, Directionality.of(context)),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<Bar> bars;
  final double? goal, maxValue;
  final Color color, on;
  final String Function(double)? valueText;
  final double dotMax;
  final Color dotColor;
  final TextDirection dir;
  _BarPainter(this.bars, this.goal, this.maxValue, this.color, this.on, this.valueText, this.dotMax, this.dotColor, this.dir);

  void _text(Canvas c, String s, Offset center, double size, Color col, {FontWeight w = FontWeight.w600}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, color: col, fontWeight: w, fontFamily: 'Tajawal')),
      textDirection: dir,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    const top = 18.0, bottom = 22.0;
    final h = size.height - top - bottom;
    var mx = maxValue ?? 0;
    for (final b in bars) {
      mx = math.max(mx, b.value);
    }
    if (goal != null) mx = math.max(mx, goal! * 1.1);
    if (mx <= 0) mx = 1;
    final slot = size.width / bars.length;
    final bw = math.min(28.0, slot * .6);
    final dots = <Offset>[];
    for (var i = 0; i < bars.length; i++) {
      final b = bars[i];
      // من اليمين لليسار (RTL): العنصر الأول على اليمين
      final idx = dir == TextDirection.rtl ? bars.length - 1 - i : i;
      final cx = slot * idx + slot / 2;
      final bh = (b.value / mx) * h;
      final col = b.color ?? color;
      // خلفية العمود
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - bw / 2, top, bw, h), const Radius.circular(8)),
        Paint()..color = col.withValues(alpha: .08),
      );
      if (bh > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(cx - bw / 2, top + h - bh, bw, bh), const Radius.circular(8)),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [col, col.withValues(alpha: .55)],
            ).createShader(Rect.fromLTWH(cx - bw / 2, top + h - bh, bw, bh)),
        );
        if (valueText != null) {
          _text(canvas, valueText!(b.value), Offset(cx, top + h - bh - 8), 9.5, on.withValues(alpha: .75));
        }
      }
      _text(canvas, b.label, Offset(cx, size.height - bottom / 2), 10, on.withValues(alpha: .7));
      if (b.dot != null) dots.add(Offset(cx, top + h - (b.dot! / dotMax) * h));
    }
    if (goal != null) {
      final y = top + h - (goal! / mx) * h;
      final p = Paint()
        ..color = SD.gold
        ..strokeWidth = 1.5;
      for (double x = 0; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(x + 4, y), p);
      }
    }
    if (dots.length > 1) {
      final path = Path()..moveTo(dots.first.dx, dots.first.dy);
      for (final d in dots.skip(1)) {
        path.lineTo(d.dx, d.dy);
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = dotColor.withValues(alpha: .6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    for (final d in dots) {
      canvas.drawCircle(d, 4.5, Paint()..color = dotColor);
      canvas.drawCircle(d, 2, Paint()..color = on.withValues(alpha: .2));
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => true;
}

/// حلقة تقدّم دائرية بمحتوى في الوسط
class ProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  final double size, stroke;
  final Widget child;
  const ProgressRing({super.key, required this.progress, required this.color, required this.child, this.size = 220, this.stroke = 14});

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

/// مفتاح يوم محلي ثابت (yyyy-mm-dd) للفرز
String dkey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// فرق الأيام التقويمية (يتجاهل التوقيت الصيفي)
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// تنسيق مدة كـ 00:00:00
String clock(Duration d, {bool cs = false}) {
  final neg = d.isNegative;
  d = d.abs();
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  final c = (d.inMilliseconds % 1000) ~/ 10;
  final base = h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  return '${neg ? '-' : ''}$base${cs ? '.${two(c)}' : ''}';
}

/// أسماء الأيام المختصرة (DateTime.weekday 1..7)
List<String> get shortDays => isEn
    ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    : const ['اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد'];
