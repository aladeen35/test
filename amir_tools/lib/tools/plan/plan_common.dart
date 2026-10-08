import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
export '../life/life_common.dart';

/// أدوات مشتركة لقسم «التخطيط» (plan)

/// مبلغ مع رمز العملة الذي كتبه المستخدم
String money(num v, String cur, [int digits = 0]) => '${fmt(v, digits)}${cur.trim().isEmpty ? '' : ' ${cur.trim()}'}';

/// رقم بدون فواصل لتعبئة الحقول
String rawNum(num v) => v == 0 ? '' : fmt(v, 2).replaceAll(',', '');

/// حلقة تقدّم بنسبة في الوسط
class RingProgress extends StatelessWidget {
  final double value;
  final Color color;
  final double size;
  final String? center;
  const RingProgress(this.value, {super.key, this.color = SD.green, this.size = 110, this.center});

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(fit: StackFit.expand, children: [
        CircularProgressIndicator(value: v, strokeWidth: size / 10, color: color, backgroundColor: color.withValues(alpha: .15)),
        Padding(
          padding: EdgeInsets.all(size / 6),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(center ?? '${fmt(value * 100, 0)}%',
                  maxLines: 1, style: TextStyle(fontSize: size / 4.5, fontWeight: FontWeight.w800, color: readable(context, color))),
            ),
          ),
        ),
      ]),
    );
  }
}

/// زر مستدير صغير بنص قصير ضمن صف (يتقلّص بدل التجاوز)
class MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const MiniAction(this.icon, this.label, this.onTap, {super.key, this.color = SD.gold});
  @override
  Widget build(BuildContext context) => OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          foregroundColor: readable(context, color),
          side: BorderSide(color: color.withValues(alpha: .6)),
        ),
        onPressed: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: const TextStyle(fontSize: 12.5))),
        ]),
      );
}

/// صف أزرار متساوية العرض
class ActionRow extends StatelessWidget {
  final List<Widget> children;
  const ActionRow(this.children, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: children[i]),
          ],
        ]),
      );
}

/// نافذة نص متعدد الأسطر
Future<String?> askMultiline(BuildContext context, String title, {String initial = '', String? hint}) async {
  final c = TextEditingController(text: initial);
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: c, autofocus: true, minLines: 3, maxLines: 8, decoration: InputDecoration(hintText: hint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('لا خلاص', 'إلغاء', 'Cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(t('تمام', 'حفظ', 'Save'))),
      ],
    ),
  );
  c.dispose();
  return r;
}

/// صف إجراءات أسفل الورقة: حذف (اختياري) + حفظ
Widget sheetButtons(BuildContext ctx, {required VoidCallback onSave, VoidCallback? onDelete}) => Row(children: [
      if (onDelete != null)
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: SD.red),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('امسح', 'حذف', 'Delete'))),
          ),
        ),
      if (onDelete != null) const SizedBox(width: 10),
      Expanded(
        flex: 2,
        child: FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.check_rounded),
          label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('احفظ', 'حفظ', 'Save'))),
        ),
      ),
    ]);

/// شارة صغيرة ملوّنة بنص قصير
class Tag extends StatelessWidget {
  final String text;
  final Color color;
  const Tag(this.text, {super.key, this.color = SD.gold});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: .45))),
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: readable(context, color))),
      );
}

/// «بعد 5 أيام» / «اليوم» / «قبل 3 أيام»
String daysWord(int d) {
  if (d == 0) return t('الليلة/اليوم', 'اليوم', 'today');
  if (d == 1) return t('بكرة', 'غدًا', 'tomorrow');
  if (d == -1) return t('أمبارح', 'أمس', 'yesterday');
  if (d > 0) return t('بعد $d يوم', 'بعد $d يومًا', 'in $d days');
  return t('قبل ${-d} يوم', 'قبل ${-d} يومًا', '${-d} days ago');
}

/// شهر بعد/قبل [by] شهرًا
(int, int) shiftMonth(int y, int m, int by) {
  var mm = m + by, yy = y;
  while (mm < 1) {
    mm += 12;
    yy--;
  }
  while (mm > 12) {
    mm -= 12;
    yy++;
  }
  return (yy, mm);
}

/// شريط تنقّل بين الفترات (شهر/أسبوع)
class PeriodNav extends StatelessWidget {
  final String label;
  final VoidCallback onPrev, onNext;
  final VoidCallback? onReset;
  const PeriodNav(this.label, {super.key, required this.onPrev, required this.onNext, this.onReset});
  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Row(children: [
      IconButton(onPressed: onPrev, icon: Icon(rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded), tooltip: t('الفات', 'السابق', 'Previous')),
      Expanded(
        child: InkWell(
          onTap: onReset,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
      IconButton(onPressed: onNext, icon: Icon(rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded), tooltip: t('الجاي', 'التالي', 'Next')),
    ]);
  }
}

/// مبلغ في طرف ListTile — يتقلّص بدل أن يتجاوز
Widget trailAmount(BuildContext context, String text, {Color? color, double maxWidth = 130}) => ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w800, color: color == null ? null : readable(context, color))),
      ),
    );

/// شريط نسبة: عنوان + قيمة (القيمة تتقلّص بدل أن تتجاوز)
class PercentBar extends StatelessWidget {
  final String label;
  final double fraction;
  final String trailing;
  final Color color;
  const PercentBar(this.label, this.fraction, this.trailing, {super.key, this.color = SD.green});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(flex: 3, child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(trailing, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, color))),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction.isNaN || fraction.isInfinite ? 0 : fraction.clamp(0, 1).toDouble(),
              minHeight: 9,
              color: color,
              backgroundColor: color.withValues(alpha: .14),
            ),
          ),
        ]),
      );
}
