import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/date_input.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../screens/privacy_screen.dart' show supportEmail;
import '../../screens/settings_screen.dart' show hashPin;

/// أدوات مشتركة لقسم «الرعاية الصحية» (اللقاحات، السجل العائلي، كبار السن، الإسعافات، الطوارئ)

/// تاريخ آخر مراجعة للمعلومات الثابتة (أرقام، إرشادات)
const careReviewed = '2026-10';

final _rnd = math.Random();

/// معرّف فريد بسيط
String cId() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_rnd.nextInt(1 << 20).toRadixString(36)}';

/// مفتاح يوم ثابت yyyy-mm-dd
String cKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

/// قراءة مفتاح اليوم
DateTime? cParse(dynamic s) {
  if (s is! String || s.isEmpty) return null;
  final p = s.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

DateTime cToday() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// فرق الأيام التقويمية (b − a)
int cDays(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// يضيف أشهرًا مع ضبط نهاية الشهر (31 يناير + شهر ← 28/29 فبراير)
DateTime addMonths(DateTime d, int months) {
  final total = d.year * 12 + (d.month - 1) + months;
  final y = total ~/ 12, m = total % 12 + 1;
  final last = DateTime(y, m + 1, 0).day;
  return DateTime(y, m, d.day > last ? last : d.day);
}

/// العمر بالسنوات الكاملة
int ageYears(DateTime birth, [DateTime? at]) {
  final n = at ?? cToday();
  var a = n.year - birth.year;
  if (n.month < birth.month || (n.month == birth.month && n.day < birth.day)) a--;
  return a < 0 ? 0 : a;
}

/// قراءة قائمة خرائط من التخزين
List<Map<String, dynamic>> cList(dynamic v) => v is List ? [for (final e in v) if (e is Map) Map<String, dynamic>.from(e)] : <Map<String, dynamic>>[];

int cInt(dynamic v, [int f = 0]) => v is num ? v.toInt() : (v is String ? int.tryParse(v) ?? f : f);

String cStr(dynamic v) => v == null ? '' : v.toString();

/// «5 أكتوبر 2026»
String cDate(DateTime d) => fmtDateAr(d, weekday: false);

/// وصف قصير للمدة المتبقية: «بعد 5 يوم» / «متأخر 3 يوم» / «اليوم»
String cDueLabel(int days) {
  if (days == 0) return t('الليلة', 'اليوم', 'Today');
  if (days == 1) return t('بكرة', 'غدًا', 'Tomorrow');
  if (days < 0) return t('متأخر ${-days} يوم', 'متأخر ${-days} يوم', '${-days} d overdue');
  return t('بعد $days يوم', 'بعد $days يوم', 'in $days d');
}

/// لون الاستحقاق: متأخر أحمر، قريب ذهبي، بعيد أخضر
Color cDueColor(int days) => days < 0 ? SD.red : (days <= 30 ? SD.orange : SD.green);

/// وقت (دقائق من منتصف الليل) بنظام 12 ساعة
String cMins(int mins) => fmtTimeAr(DateTime(2000, 1, 1, (mins ~/ 60) % 24, mins % 60));

/// اتصال هاتفي مباشر
Future<void> callNumber(String number) async {
  final n = number.replaceAll(RegExp(r'[^0-9+*#]'), '');
  if (n.isEmpty) return;
  try {
    if (!await launchUrl(Uri(scheme: 'tel', path: n), mode: LaunchMode.externalApplication)) {
      toast(t('ما قدرنا نفتح الاتصال', 'تعذّر فتح الاتصال', "Couldn't open the dialer"));
    }
  } catch (_) {
    toast(t('ما قدرنا نفتح الاتصال', 'تعذّر فتح الاتصال', "Couldn't open the dialer"));
  }
}

/// «بلّغ عن معلومة غلط/قديمة» — بريد للدعم بمعرّف الأداة والعنصر
Future<void> reportWrong(String toolId, String item) async {
  final uri = Uri(
    scheme: 'mailto',
    path: supportEmail,
    query: 'subject=${Uri.encodeComponent('[$toolId] ${tr('تصحيح معلومة', 'Correction')}: $item')}'
        '&body=${Uri.encodeComponent(tr('المعلومة الصحيحة ومصدرها:\n', 'Correct information and its source:\n'))}',
  );
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) toast(supportEmail);
  } catch (_) {
    toast(supportEmail);
  }
}

/// سطر «آخر مراجعة» مع زر الإبلاغ
class ReviewedLine extends StatelessWidget {
  final String toolId, item;
  const ReviewedLine({super.key, required this.toolId, this.item = ''});
  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .65);
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
      Text('${t('آخر مراجعة', 'آخر مراجعة', 'Last reviewed')}: $careReviewed', style: TextStyle(color: muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
      TextButton.icon(
        onPressed: () => reportWrong(toolId, item.isEmpty ? tr('عام', 'general') : item),
        icon: const Icon(Icons.flag_rounded, size: 18),
        label: Text(t('بلّغ عن معلومة غلط', 'الإبلاغ عن معلومة خاطئة', 'Report wrong info'), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ]);
  }
}

/// تأكيد الحذف
Future<bool> confirmDelete(BuildContext context, String name) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t('تمسح «$name»؟', 'حذف «$name»؟', 'Delete “$name”?')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('إلغاء', 'Cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t('امسح', 'احذف', 'Delete'))),
      ],
    ),
  );
  return ok == true;
}

/// حقل نصي عادي بحشوة سفلية
class CField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboard;
  final int maxLines;
  final bool ltr;
  final IconData? icon;
  const CField(this.label, this.controller, {super.key, this.hint, this.keyboard, this.maxLines = 1, this.ltr = false, this.icon});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          keyboardType: keyboard ?? (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
          maxLines: maxLines,
          minLines: 1,
          textDirection: ltr ? TextDirection.ltr : null,
          decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: icon == null ? null : Icon(icon)),
        ),
      );
}

/// زر اختيار تاريخ (يستخدم pickDate)
class DateButton extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? first, last;
  final bool clearable;
  const DateButton({super.key, required this.label, required this.value, required this.onChanged, this.first, this.last, this.clearable = true});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final d = await pickDate(
                  context: context,
                  initialDate: value ?? cToday(),
                  firstDate: first ?? DateTime(1900),
                  lastDate: last ?? DateTime(2100),
                  helpText: label,
                );
                if (d != null) onChanged(d);
              },
              icon: const Icon(Icons.event_rounded),
              label: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text('$label: ${value == null ? '—' : cDate(value!)}', maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
          if (clearable && value != null)
            IconButton(tooltip: t('امسح', 'مسح', 'Clear'), onPressed: () => onChanged(null), icon: const Icon(Icons.close_rounded)),
        ]),
      );
}

/// يختار وقتًا يوميًا (دقائق من منتصف الليل)
Future<int?> pickMinutes(BuildContext context, [int initial = 8 * 60]) async {
  final r = await showTimePicker(context: context, initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60));
  return r == null ? null : r.hour * 60 + r.minute;
}

/// يطلب رمز قفل التطبيق (4 أرقام) ويتحقق منه بنفس دالة التشفير
Future<bool> askAppPin(BuildContext context, AppState s) async {
  final want = s.pinHash;
  if (want == null) return true;
  final c = TextEditingController();
  String? err;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) {
        Future<void> submit() async {
          final good = await hashPin(c.text.trim()) == want;
          if (!ctx.mounted) return;
          if (good) {
            Navigator.pop(ctx, true);
          } else {
            setD(() => err = t('الرمز غلط', 'الرمز خاطئ', 'Wrong PIN'));
          }
        }

        return AlertDialog(
          title: Text(t('أدخل رمز قفل التطبيق', 'أدخل رمز قفل التطبيق', 'Enter the app PIN')),
          content: TextField(
            controller: c,
            autofocus: true,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w800),
            decoration: InputDecoration(errorText: err, counterText: ''),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('إلغاء', 'Cancel'))),
            FilledButton(onPressed: submit, child: Text(t('افتح', 'فتح', 'Unlock'))),
          ],
        );
      },
    ),
  );
  c.dispose();
  return ok == true;
}

/// صف قائمة بعنوان وتفاصيل وأزرار على الطرف — بدون تجاوز للنصوص
class CTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? sub, badge;
  final Color? badgeColor;
  final List<Widget> actions;
  final VoidCallback? onTap;
  const CTile({super.key, required this.icon, required this.color, required this.title, this.sub, this.badge, this.badgeColor, this.actions = const [], this.onTap});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .65);
    final bc = readable(context, badgeColor ?? color);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: readable(context, color), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              if (sub != null && sub!.isNotEmpty) Text(sub!, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 12.5)),
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: bc.withValues(alpha: .14), borderRadius: BorderRadius.circular(8), border: Border.all(color: bc.withValues(alpha: .4))),
                  child: Text(badge!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: bc, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
            ]),
          ),
          ...actions,
        ]),
      ),
    );
  }
}

/// شريط تقدّم أفقي بنسبة مئوية
class CBar extends StatelessWidget {
  final String label;
  final double value; // 0..1
  final Color color;
  final String? trailing;
  const CBar(this.label, this.value, {super.key, this.color = SD.green, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
            if (trailing != null) Text(trailing!, style: TextStyle(fontWeight: FontWeight.w800, color: readable(context, color))),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: value.clamp(0, 1).toDouble(), minHeight: 8, color: color, backgroundColor: color.withValues(alpha: .15)),
          ),
        ]),
      );
}
