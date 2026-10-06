import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../services/prayer.dart';

/// أدوات مشتركة لقسم «تنظيم حياتك»

final _rnd = math.Random();

/// معرّف فريد بسيط
String newId() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_rnd.nextInt(1 << 20).toRadixString(36)}';

/// تاريخ اليوم في المكان المختار (بدون وقت)
DateTime todayPlace() {
  final n = placeNow();
  return DateTime(n.year, n.month, n.day);
}

/// مفتاح يوم ثابت yyyy-mm-dd
String dk(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

/// قراءة مفتاح يوم
DateTime? parseDk(String? s) {
  if (s == null || s.isEmpty) return null;
  final p = s.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// مفتاح شهر yyyy-mm
String mk(int y, int m) => '$y-${two(m)}';

/// فرق الأيام التقويمية بين تاريخين
int dayDiff(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// عدد أيام الشهر
int daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

/// «5 أكتوبر»
String fmtShort(DateTime d) => '${d.day} ${monthsAr[d.month - 1]}';

/// «أكتوبر 2026»
String fmtMonth(int y, int m) => '${monthsAr[(m - 1) % 12]} $y';

/// أسماء الأيام المختصرة (DateTime.weekday 1..7)
List<String> get shortDaysL =>
    isEn ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] : const ['اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد'];

/// لوحة ألوان موحّدة للعناصر (تُحفظ كرقم فهرس)
const lifePalette = [SD.green, SD.nile, SD.teal, SD.gold, SD.orange, SD.henna, SD.red, SD.pink, SD.purple, SD.indigo, SD.coffee, SD.nileLight];
Color palette(int? i) => lifePalette[(i ?? 0).abs() % lifePalette.length];

/// قراءة رقم من JSON بأمان
double numOf(dynamic v, [double f = 0]) => v is num ? v.toDouble() : f;
int intOf(dynamic v, [int f = 0]) => v is num ? v.toInt() : f;

/// قراءة قائمة خرائط من التخزين
List<Map<String, dynamic>> mapList(dynamic v) =>
    v is List ? [for (final e in v) if (e is Map) Map<String, dynamic>.from(e)] : <Map<String, dynamic>>[];

/// رسالة مع زر تراجع
void undoSnack(String msg, VoidCallback onUndo) {
  messengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(label: t('رجّعها', 'تراجع', 'Undo'), onPressed: onUndo),
    ));
}

/// نافذة تأكيد
Future<bool> confirmAsk(BuildContext context, String title, String body, {String? ok, bool danger = true}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t('لا خلاص', 'إلغاء', 'Cancel'))),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: SD.red) : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(ok ?? t('أيوه', 'نعم', 'Yes')),
        ),
      ],
    ),
  );
  return r == true;
}

/// نافذة إدخال نص واحد
Future<String?> askText(BuildContext context, String title, {String initial = '', String? hint, bool number = false}) async {
  final c = TextEditingController(text: initial);
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('لا خلاص', 'إلغاء', 'Cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(t('تمام', 'حفظ', 'Save'))),
      ],
    ),
  );
  c.dispose();
  return r;
}

/// ورقة سفلية قياسية بعنوان، قابلة للتمرير ومراعية للوحة المفاتيح
Future<T?> lifeSheet<T>(BuildContext context, String title, Widget Function(BuildContext ctx, StateSetter set) body) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            body(ctx, set),
          ]),
        ),
      ),
    ),
  );
}

/// زر اختيار تاريخ (ثلاثي اللغة)
class LifeDateButton extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onPick;
  final Color color;
  final bool clearable;
  final DateTime? first, last;
  const LifeDateButton(
      {super.key, required this.label, required this.value, required this.onPick, this.color = SD.henna, this.clearable = false, this.first, this.last});

  @override
  Widget build(BuildContext context) {
    final rc = readable(context, color);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final now = todayPlace();
        final f = first ?? DateTime(now.year - 5);
        final l = last ?? DateTime(now.year + 5, 12, 31);
        var init = value ?? now;
        if (init.isBefore(f)) init = f;
        if (init.isAfter(l)) init = l;
        final d = await showDatePicker(
          context: context,
          initialDate: init,
          firstDate: f,
          lastDate: l,
          helpText: label,
          cancelText: t('خلاص', 'إلغاء', 'Cancel'),
          confirmText: t('تمام', 'موافق', 'OK'),
        );
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Row(children: [
          Icon(Icons.calendar_month_rounded, color: rc),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 12, color: rc, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(value == null ? t('ما محدد — دوس واختار', 'غير محدد — اضغط للاختيار', 'Not set — tap to pick') : fmtDateAr(value!),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ]),
          ),
          if (clearable && value != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: t('امسح', 'مسح', 'Clear'),
              onPressed: () => onPick(null),
              icon: const Icon(Icons.close_rounded),
            )
          else
            Icon(Icons.edit_calendar_rounded, color: color.withValues(alpha: .7)),
        ]),
      ),
    );
  }
}

/// صف اختيار لون من اللوحة
class ColorDots extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const ColorDots(this.value, this.onChanged, {super.key});
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < lifePalette.length; i++)
          GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: lifePalette[i],
                shape: BoxShape.circle,
                border: Border.all(color: i == value ? SD.goldLight : Colors.transparent, width: 3),
                boxShadow: i == value ? [BoxShadow(color: lifePalette[i].withValues(alpha: .6), blurRadius: 8)] : null,
              ),
              child: i == value ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
            ),
          ),
      ]);
}

/// حالة فارغة لطيفة
class EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  const EmptyHint(this.icon, this.text, {super.key, this.action});
  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .55);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(children: [
        Icon(icon, size: 46, color: SD.gold.withValues(alpha: .7)),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center, style: TextStyle(color: muted, fontWeight: FontWeight.w600, height: 1.5)),
        if (action != null) ...[const SizedBox(height: 10), action!],
      ]),
    );
  }
}

/// رقاقة اختيار صغيرة
class PickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const PickChip(this.label, this.selected, this.onTap, {super.key, this.color = SD.green});
  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: color.withValues(alpha: .25),
        side: BorderSide(color: color.withValues(alpha: .4)),
        labelStyle: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w500),
        onSelected: (_) => onTap(),
      );
}
