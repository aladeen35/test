import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../services/prayer.dart';

export '../life/life_common.dart';

/// أدوات مشتركة لقسم «البيت+» (الغاز، المولّد، العربية، القطوعات، المخزن)

/// ساعة الحائط الآن في المكان المختار (DateTime محلّي الحقول، صالح للمقارنة مع تواريخ مبنية بـ DateTime(...))
DateTime pNow() {
  final n = placeNow();
  return DateTime(n.year, n.month, n.day, n.hour, n.minute, n.second);
}

/// تاريخ اليوم في المكان المختار بدون وقت
DateTime pToday() {
  final n = placeNow();
  return DateTime(n.year, n.month, n.day);
}

/// يحوّل «ساعة حائط» في المكان المختار إلى لحظة مجدولة للتنبيه
tz.TZDateTime placeTZ(DateTime wall) {
  if (placeTz.isNotEmpty) {
    try {
      final loc = tz.getLocation(placeTz);
      return tz.TZDateTime(loc, wall.year, wall.month, wall.day, wall.hour, wall.minute);
    } catch (_) {}
  }
  // توقيت الجهاز
  final local = DateTime(wall.year, wall.month, wall.day, wall.hour, wall.minute);
  return tz.TZDateTime.from(local.toUtc(), tz.UTC);
}

/// وقت من دقائق منتصف الليل: «4:30 م»
String minsLabel(int mins) => fmtTimeAr(DateTime(2000, 1, 1, (mins ~/ 60) % 24, mins % 60));

/// «5 أيام» / «يوم واحد»
String daysLabel(int d) {
  final a = d.abs();
  if (isEn) return a == 1 ? '1 day' : '$a days';
  if (a == 1) return t('يوم واحد', 'يوم واحد', '1 day');
  if (a == 2) return t('يومين', 'يومان', '2 days');
  if (a >= 3 && a <= 10) return '$a ${t('أيام', 'أيام', 'days')}';
  return '$a ${t('يوم', 'يومًا', 'days')}';
}

/// اختيار وقت (دقائق من منتصف الليل)
Future<int?> pickMins(BuildContext context, int initial, {String? help}) async {
  final r = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: (initial ~/ 60) % 24, minute: initial % 60),
    helpText: help,
    cancelText: t('خلاص', 'إلغاء', 'Cancel'),
    confirmText: t('تمام', 'موافق', 'OK'),
  );
  return r == null ? null : r.hour * 60 + r.minute;
}

/// شريط تقدّم ملوّن مع عنوان ونسبة
class HpBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final String? left, right;
  final double height;
  const HpBar(this.value, {super.key, this.color = SD.green, this.left, this.right, this.height = 12});

  @override
  Widget build(BuildContext context) {
    final rc = readable(context, color);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      if (left != null || right != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            if (left != null)
              Expanded(child: Text(left!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
            if (right != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(right!,
                    maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.w800, color: rc, fontSize: 13)),
              ),
            ],
          ]),
        ),
      ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: value.isNaN ? 0 : value.clamp(0.0, 1.0),
          minHeight: height,
          color: color,
          backgroundColor: color.withValues(alpha: .15),
        ),
      ),
    ]);
  }
}

/// حقل نص قصير (للعملة أو الاسم)
class HpTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? hint;
  const HpTextField(this.label, this.controller, {super.key, this.onChanged, this.hint});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(controller: controller, onChanged: onChanged, decoration: InputDecoration(labelText: label, hintText: hint)),
      );
}

/// مفتاح تشغيل مع عنوان وشرح (بدون تجاوز للنص)
class HpSwitch extends StatelessWidget {
  final String title;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const HpSwitch(this.title, this.value, this.onChanged, {super.key, this.sub});
  @override
  Widget build(BuildContext context) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: sub == null ? null : Text(sub!),
        value: value,
        onChanged: onChanged,
      );
}

/// صف سجلّ في قائمة تاريخية: أيقونة + عنوان + وصف + قيمة + حذف
class HpLogTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? sub, value;
  final VoidCallback? onDelete, onTap;
  const HpLogTile({super.key, required this.icon, required this.color, required this.title, this.sub, this.value, this.onDelete, this.onTap});

  @override
  Widget build(BuildContext context) {
    final rc = readable(context, color);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          CircleAvatar(radius: 17, backgroundColor: color.withValues(alpha: .18), child: Icon(icon, size: 18, color: rc)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (sub != null) Text(sub!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: muted)),
            ]),
          ),
          if (value != null) ...[
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(value!, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w800, color: rc)),
              ),
            ),
          ],
          if (onDelete != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: t('امسح', 'حذف', 'Delete'),
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline_rounded, color: muted, size: 20),
            ),
        ]),
      ),
    );
  }
}

/// أعمدة بسيطة (اتجاه السعر مثلًا)
class HpMiniBars extends StatelessWidget {
  final List<(String, double)> bars;
  final Color color;
  const HpMiniBars(this.bars, {super.key, this.color = SD.gold});
  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox();
    final mx = bars.map((b) => b.$2).fold<double>(0, (a, b) => b > a ? b : a);
    return SizedBox(
      height: 120,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final b in bars)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(fmt(b.$2, 0), maxLines: 1, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                const SizedBox(height: 2),
                Container(
                  height: mx <= 0 ? 2 : 2 + 70 * (b.$2 / mx),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                ),
                const SizedBox(height: 4),
                FittedBox(fit: BoxFit.scaleDown, child: Text(b.$1, maxLines: 1, style: const TextStyle(fontSize: 10))),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// عدّاد صغير (− قيمة +) مع عنوان
class HpStepper extends StatelessWidget {
  final String label, unit;
  final int value, min, max, step;
  final ValueChanged<int> onChanged;
  const HpStepper(
      {super.key, required this.label, required this.value, required this.unit, required this.min, required this.max, required this.onChanged, this.step = 1});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(label, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value - step >= min ? () => onChanged(value - step) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, maxWidth: 80),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('$value $unit', maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value + step <= max ? () => onChanged(value + step) : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ]),
      );
}
