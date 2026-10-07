import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../services/prayer.dart';

/// أدوات مشتركة لقسم «القراية» وأدوات الدين المضافة معه

final _rnd = math.Random();

/// معرّف فريد بسيط
String lId() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_rnd.nextInt(1 << 20).toRadixString(36)}';

/// تاريخ اليوم في المكان المختار (بدون وقت)
DateTime lToday() {
  final n = placeNow();
  return DateTime(n.year, n.month, n.day);
}

/// مفتاح يوم ثابت yyyy-mm-dd
String lDk(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

/// قراءة مفتاح يوم
DateTime? lParseDk(String? s) {
  if (s == null || s.isEmpty) return null;
  final p = s.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// فرق الأيام التقويمية بين تاريخين
int lDayDiff(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

DateTime lAddDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// «5 أكتوبر»
String lShort(DateTime d) => '${d.day} ${monthsAr[d.month - 1]}';

double lNum(dynamic v, [double f = 0]) => v is num ? v.toDouble() : f;
int lInt(dynamic v, [int f = 0]) => v is num ? v.toInt() : f;

List<Map<String, dynamic>> lMaps(dynamic v) =>
    v is List ? [for (final e in v) if (e is Map) Map<String, dynamic>.from(e)] : <Map<String, dynamic>>[];

/// شريط تقدّم بعنوان وقيمة
class LBar extends StatelessWidget {
  final String label, trailing;
  final double fraction;
  final Color color;
  final double height;
  const LBar(this.label, this.fraction, this.trailing, {super.key, this.color = SD.green, this.height = 10});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
            const SizedBox(width: 8),
            Text(trailing, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, color))),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction.isNaN ? 0 : fraction.clamp(0, 1).toDouble(),
              minHeight: height,
              color: color,
              backgroundColor: color.withValues(alpha: .14),
            ),
          ),
        ]),
      );
}

/// زر +/− لعدد صحيح
class LStepper extends StatelessWidget {
  final String label;
  final int value, min, max;
  final ValueChanged<int> onChanged;
  final String? suffix;
  const LStepper(this.label, this.value, this.onChanged, {super.key, this.min = 0, this.max = 999, this.suffix});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, maxWidth: 90),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('$value${suffix == null ? '' : ' $suffix'}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
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

/// زر سطر عريض مع نص قابل للتقليص
Widget lSwitch(String title, bool value, ValueChanged<bool> onChanged, {String? sub}) => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: sub == null ? null : Text(sub, maxLines: 3, overflow: TextOverflow.ellipsis),
      value: value,
      onChanged: onChanged,
    );

/// «3 ساعات 12 دقيقة» مع الثواني للعدّاد
String lCountdown(Duration d) {
  final s = d.inSeconds.abs();
  return '${two(s ~/ 3600)}:${two((s % 3600) ~/ 60)}:${two(s % 60)}';
}

/// نص اختيار بين خيارات قليلة (≤3) بأزرار مقسّمة مع تقليص النص
Widget lSegmented<T>({required List<(T, String)> items, required T value, required ValueChanged<T> onChanged}) => SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        segments: [
          for (final it in items)
            ButtonSegment<T>(value: it.$1, label: FittedBox(fit: BoxFit.scaleDown, child: Text(it.$2, maxLines: 1))),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );

/// لاحقة «يوم/أيام»
String lDays(int n) => isEn ? '$n ${n == 1 ? 'day' : 'days'}' : '$n ${n >= 3 && n <= 10 ? 'أيام' : 'يوم'}';
