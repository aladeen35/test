import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/calendars.dart';
import 'daily_common.dart';

/// حاسبة الحمل: موعد الولادة المتوقع، عمر الحمل، الثلث، والمحطات المهمة
class PregnancyTool extends StatefulWidget {
  const PregnancyTool({super.key});
  @override
  State<PregnancyTool> createState() => _PregnancyToolState();
}

class _PregnancyToolState extends State<PregnancyTool> {
  late DateTime? _lmp = () {
    final v = context.read<AppState>().getData<String>('preg_lmp');
    return v == null ? null : DateTime.tryParse(v);
  }();

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final today = DateTime.now();
    final d0 = DateTime(today.year, today.month, today.day);
    return ToolList(children: [
      SCard(
        title: tr('أول يوم في آخر دورة', 'First day of last period'),
        icon: Icons.event_rounded,
        color: SD.pink,
        child: DateButton(
          label: tr('التاريخ', 'Date'),
          value: _lmp,
          first: d0.subtract(const Duration(days: 300)),
          last: d0,
          color: SD.pink,
          onPick: (d) {
            setState(() => _lmp = d);
            s.setData('preg_lmp', d.toIso8601String());
          },
        ),
      ),
      if (_lmp != null) ..._result(_lmp!, d0, s),
      NoteBox(
          t('الحساب بقاعدة «نيغلي» (280 يوم من أول يوم في آخر دورة) — تقديري، والسونار والدكتورة هم المرجع.',
              'الحساب بقاعدة «نيغلي» (280 يومًا من أول يوم في آخر دورة) — تقديري، والمرجع هو الموجات فوق الصوتية والطبيبة.',
              "Calculated with Naegele's rule (280 days from the first day of the last period) — an estimate; ultrasound and your doctor are the reference."),
          kind: NoteKind.warn),
    ]);
  }

  List<Widget> _result(DateTime lmp, DateTime today, AppState s) {
    final due = lmp.add(const Duration(days: 280));
    final days = today.difference(lmp).inDays;
    final w = days ~/ 7, d = days % 7;
    final left = due.difference(today).inDays;
    final tri = w < 14
        ? tr('الثلث الأول', 'First trimester')
        : w < 28
            ? t('الثلث التاني', 'الثلث الثاني', 'Second trimester')
            : t('الثلث التالت', 'الثلث الثالث', 'Third trimester');
    final progress = (days / 280).clamp(0.0, 1.0);
    DateTime at(int week) => lmp.add(Duration(days: week * 7));
    final milestones = [
      (tr('نهاية الثلث الأول', 'End of first trimester'), 13),
      (t('سونار تشريح الجنين (18–22 أسبوع)', 'فحص التشريح بالموجات فوق الصوتية (18–22 أسبوعًا)', 'Anatomy scan (weeks 18–22)'), 18),
      (tr('فحص سكر الحمل (24–28 أسبوع)', 'Gestational diabetes test (weeks 24–28)'), 24),
      (t('بداية الثلث التالت', 'بداية الثلث الثالث', 'Start of third trimester'), 28),
      (tr('اكتمال الحمل (Full term)', 'Full term'), 37),
      (tr('الموعد المتوقع', 'Due date'), 40),
      (t('تجاوز الموعد — راجعي الدكتورة', 'تجاوز الموعد — راجعي الطبيبة', 'Overdue — see your doctor'), 42),
    ];
    return [
      ResultHero(
        label: tr('عمر الحمل', 'Pregnancy age'),
        value: tr('$w أسبوع و$d يوم', '$w weeks $d days'),
        sub: '$tri • ${left >= 0 ? t('فاضل $left يوم', 'متبقٍ $left يومًا', '$left days to go') : t('عدّى الموعد بـ ${-left} يوم', 'تجاوز الموعد بـ ${-left} يومًا', '${-left} days past due')}',
        colors: const [Color(0xFFD64578), Color(0xFF8E3A9E), Color(0xFF3B2F8F)],
      ),
      SCard(
        title: tr('التفاصيل', 'Details'),
        icon: Icons.child_friendly_rounded,
        color: SD.pink,
        child: Column(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, minHeight: 12, valueColor: const AlwaysStoppedAnimation(SD.pink)),
          ),
          const SizedBox(height: 6),
          Text(tr('${fmt(progress * 100, 0)}% من الحمل', '${fmt(progress * 100, 0)}% of the pregnancy'), style: const TextStyle(fontWeight: FontWeight.w700)),
          InfoRow(tr('موعد الولادة المتوقع', 'Estimated due date'), fmtDateAr(due)),
          InfoRow(tr('بالهجري', 'Hijri'), hijriText(due, shift: s.hijriShift)),
          InfoRow(tr('الفترة المحتملة للولادة', 'Likely delivery window'), '${fmtDateAr(at(37), weekday: false)} – ${fmtDateAr(at(42), weekday: false)}'),
          InfoRow(tr('الإخصاب التقريبي', 'Approx. conception'), fmtDateAr(lmp.add(const Duration(days: 14)))),
          InfoRow(tr('الشهر (تقريبًا)', 'Month (approx.)'), tr('الشهر ${(days / 30.4).floor() + 1}', 'Month ${(days / 30.4).floor() + 1}')),
          InfoRow(t('الأيام اللي فاتت', 'الأيام المنقضية', 'Days so far'), tr('$days يوم', '$days days')),
        ]),
      ),
      SCard(
        title: tr('محطات مهمة', 'Key milestones'),
        icon: Icons.flag_rounded,
        color: SD.purple,
        child: Column(children: [
          for (final (name, wk) in milestones)
            InfoRow(name, fmtDateAr(at(wk), weekday: false),
                hint: tr('أسبوع $wk', 'Week $wk'), valueColor: at(wk).isBefore(today) ? SD.green : null, icon: at(wk).isBefore(today) ? Icons.check_circle_rounded : Icons.schedule_rounded),
        ]),
      ),
      ShareBar(() => tr('عمر الحمل: $w أسبوع و$d يوم\nموعد الولادة المتوقع: ${fmtDateAr(due)}', 'Pregnancy age: $w weeks $d days\nEstimated due date: ${fmtDateAr(due)}')),
    ];
  }
}
