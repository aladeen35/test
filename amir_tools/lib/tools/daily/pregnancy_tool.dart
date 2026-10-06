import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
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
        title: 'أول يوم في آخر دورة',
        icon: Icons.event_rounded,
        color: SD.pink,
        child: DateButton(
          label: 'التاريخ',
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
      const NoteBox('الحساب بقاعدة «نيغلي» (280 يوم من أول يوم في آخر دورة) — تقديري، والسونار والدكتورة هم المرجع.', kind: NoteKind.warn),
    ]);
  }

  List<Widget> _result(DateTime lmp, DateTime today, AppState s) {
    final due = lmp.add(const Duration(days: 280));
    final days = today.difference(lmp).inDays;
    final w = days ~/ 7, d = days % 7;
    final left = due.difference(today).inDays;
    final tri = w < 14 ? 'الثلث الأول' : w < 28 ? 'الثلث التاني' : 'الثلث التالت';
    final progress = (days / 280).clamp(0.0, 1.0);
    DateTime at(int week) => lmp.add(Duration(days: week * 7));
    final milestones = [
      ('نهاية الثلث الأول', 13),
      ('سونار تشريح الجنين (18–22 أسبوع)', 18),
      ('فحص سكر الحمل (24–28 أسبوع)', 24),
      ('بداية الثلث التالت', 28),
      ('اكتمال الحمل (Full term)', 37),
      ('الموعد المتوقع', 40),
      ('تجاوز الموعد — راجعي الدكتورة', 42),
    ];
    return [
      ResultHero(
        label: 'عمر الحمل',
        value: '$w أسبوع و$d يوم',
        sub: '$tri • ${left >= 0 ? 'فاضل $left يوم' : 'عدّى الموعد بـ ${-left} يوم'}',
        colors: const [Color(0xFFD64578), Color(0xFF8E3A9E), Color(0xFF3B2F8F)],
      ),
      SCard(
        title: 'التفاصيل',
        icon: Icons.child_friendly_rounded,
        color: SD.pink,
        child: Column(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, minHeight: 12, valueColor: const AlwaysStoppedAnimation(SD.pink)),
          ),
          const SizedBox(height: 6),
          Text('${fmt(progress * 100, 0)}% من الحمل', style: const TextStyle(fontWeight: FontWeight.w700)),
          InfoRow('موعد الولادة المتوقع', fmtDateAr(due)),
          InfoRow('بالهجري', hijriText(due, shift: s.hijriShift)),
          InfoRow('الفترة المحتملة للولادة', '${fmtDateAr(at(37), weekday: false)} – ${fmtDateAr(at(42), weekday: false)}'),
          InfoRow('الإخصاب التقريبي', fmtDateAr(lmp.add(const Duration(days: 14)))),
          InfoRow('الشهر (تقريبًا)', 'الشهر ${(days / 30.4).floor() + 1}'),
          InfoRow('الأيام اللي فاتت', '$days يوم'),
        ]),
      ),
      SCard(
        title: 'محطات مهمة',
        icon: Icons.flag_rounded,
        color: SD.purple,
        child: Column(children: [
          for (final (name, wk) in milestones)
            InfoRow(name, fmtDateAr(at(wk), weekday: false),
                hint: 'أسبوع $wk', valueColor: at(wk).isBefore(today) ? SD.green : null, icon: at(wk).isBefore(today) ? Icons.check_circle_rounded : Icons.schedule_rounded),
        ]),
      ),
      ShareBar(() => 'عمر الحمل: $w أسبوع و$d يوم\nموعد الولادة المتوقع: ${fmtDateAr(due)}'),
    ];
  }
}
