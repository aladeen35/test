import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../services/prayer.dart';

/// أدوات مشتركة لقسم «دين» (المواريث، الصيام، الأدعية)

/// تاريخ اليوم في المكان المختار (بدون وقت)
DateTime deenToday() {
  final n = placeNow();
  return DateTime(n.year, n.month, n.day);
}

/// مفتاح يوم ثابت yyyy-mm-dd
String dayKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

DateTime? parseDayKey(String? s) {
  if (s == null) return null;
  final p = s.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// إضافة أيام تقويمية (آمن مع التوقيت الصيفي)
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// فرق الأيام التقويمية
int daysBetween(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// سطر عدّاد: عنوان + أزرار − و +
class CountRow extends StatelessWidget {
  final String label;
  final String? hint;
  final int value, max;
  final ValueChanged<int> onChanged;
  final IconData? icon;
  const CountRow(this.label, this.value, this.onChanged, {super.key, this.max = 20, this.hint, this.icon});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .6);
    final active = value > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        if (icon != null) ...[Icon(icon, size: 18, color: active ? readable(context, SD.gold) : muted), const SizedBox(width: 8)],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: active ? FontWeight.w800 : FontWeight.w600)),
            if (hint != null) Text(hint!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 11.5)),
          ]),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline_rounded),
        ),
        SizedBox(
          width: 28,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('$value', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: active ? readable(context, SD.gold) : muted)),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
      ]),
    );
  }
}
