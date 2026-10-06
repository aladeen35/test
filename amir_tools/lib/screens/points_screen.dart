import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/pattern.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../core/i18n.dart';

/// نقاطي: المستوى، الإنجازات، الإحصائيات، وسجل النقاط
class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final unlocked = s.unlocked;
    final nextXp = s.xpForLevel(s.level + 1);
    return ListView(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 120),
      children: [
        Center(child: GoldText(t('نقاطي', 'نقاطي', 'My points'), size: 34)),
        const GoldDivider(),
        GoldFrame(
          child: Column(children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [SD.goldLight, SD.gold, SD.goldDeep]),
                border: Border.all(color: SD.brownDeep, width: 4),
                boxShadow: [BoxShadow(color: SD.gold.withValues(alpha: .5), blurRadius: 24)],
              ),
              alignment: Alignment.center,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(tr('المستوى', 'Level'), style: const TextStyle(color: SD.brownDeep, fontWeight: FontWeight.w700, fontSize: 13)),
                Text('${s.level}', style: const TextStyle(fontFamily: 'Lalezar', color: SD.brownDeep, fontSize: 44, height: 1)),
              ]),
            ),
            const SizedBox(height: 10),
            GoldText(s.levelTitle, size: 26),
            Text(t('${s.xp} نقطة • فاضل ${nextXp - s.xp} للمستوى ${s.level + 1}', '${s.xp} نقطة • متبقٍّ ${nextXp - s.xp} للمستوى ${s.level + 1}', '${s.xp} XP • ${nextXp - s.xp} to level ${s.level + 1}'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(value: s.levelProgress, minHeight: 12, backgroundColor: SD.brownDeep, valueColor: const AlwaysStoppedAnimation(SD.gold)),
            ),
          ]),
        ),
        StatGrid([
          StatChip('🔥 ${s.streak}', t('يوم ورا يوم', 'أيام متتالية', 'Day streak'), color: SD.orange),
          StatChip('${s.distinctTools}', t('أداة جرّبتها', 'أداة جرّبتها', 'Tools tried'), color: SD.nileLight, icon: Icons.handyman_rounded),
          StatChip('${unlocked.length}/${achievements.length}', tr('إنجاز', 'Achievements'), color: SD.gold, icon: Icons.emoji_events_rounded),
          StatChip(fmt(s.counter('tasbih'), 0), tr('تسبيحة', 'Tasbih'), color: SD.green, icon: Icons.blur_circular_rounded),
          StatChip('${s.counter('full_prayer_days')}', tr('يوم صلوات كاملة', 'Full prayer days'), color: SD.teal, icon: Icons.mosque_rounded),
          StatChip('${s.counter('focus_sessions')}', tr('جلسة تركيز', 'Focus sessions'), color: SD.purple, icon: Icons.center_focus_strong_rounded),
        ]),
        const SizedBox(height: 14),
        GoldFrame(
          title: tr('الإنجازات', 'Achievements'),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: .72,
            children: [
              for (final a in achievements)
                Tooltip(
                  message: a.desc,
                  triggerMode: TooltipTriggerMode.tap,
                  child: Opacity(
                    opacity: unlocked.contains(a.id) ? 1 : .38,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: unlocked.contains(a.id) ? SD.gold.withValues(alpha: .18) : Colors.black12,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: unlocked.contains(a.id) ? SD.gold : Colors.grey),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(unlocked.contains(a.id) ? a.emoji : '🔒', style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(a.title, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SCard(
          title: t('كيف تكسب نقاط؟', 'كيف تكسب النقاط؟', 'How to earn points'),
          icon: Icons.help_outline_rounded,
          child: Column(children: [
            InfoRow(tr('أول استخدام لأي أداة في اليوم', 'First use of a tool each day'), '+5'),
            InfoRow(tr('تسجيل صلاة في وقتها', 'Logging a prayer'), '+10'),
            InfoRow(tr('الصلوات الخمس كاملة', 'All five prayers'), '+20'),
            InfoRow(tr('إكمال الأذكار', 'Completing adhkar'), '+30'),
            InfoRow(tr('كل 100 تسبيحة', 'Every 100 tasbih'), tr('نقاط إضافية', 'Bonus')),
            InfoRow(t('جلسة تركيز أو هدف الموية', 'جلسة تركيز أو هدف الماء', 'Focus session or water goal'), tr('نقاط إضافية', 'Bonus')),
            InfoRow(tr('عادة يومية أو مهمة منجزة', 'Daily habit or finished task'), '+3 / +5'),
            InfoRow(tr('فتح إنجاز جديد', 'Unlocking an achievement'), '+25'),
          ]),
        ),
        SCard(
          title: t('آخر النقاط', 'آخر النقاط', 'Recent points'),
          icon: Icons.history_rounded,
          child: s.xpLog.isEmpty
              ? Text(t('لسه ما كسبت نقاط — افتح أي أداة وابدأ 💪', 'لم تكسب نقاطًا بعد — افتح أي أداة وابدأ 💪', 'No points yet — open any tool to start 💪'))
              : Column(children: [
                  for (final e in s.xpLog.take(15))
                    InfoRow(e['r'] as String, '+${e['x']}',
                        hint: fmtDateAr(DateTime.fromMillisecondsSinceEpoch(e['t'] as int), weekday: false), valueColor: SD.green),
                ]),
        ),
      ],
    );
  }
}
