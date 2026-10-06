import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'counter_tool.dart';
import 'debts_tool.dart';
import 'expenses_tool.dart';
import 'habits_tool.dart';
import 'sanduq_tool.dart';
import 'tasks_tool.dart';

List<ToolDef> get lifeTools => [
      ToolDef(
        id: 'habits',
        name: t('متتبع العادات', 'متتبع العادات', 'Habit Tracker'),
        sub: t('ما تكسر السلسلة', 'لا تقطع السلسلة', 'Don\'t break the chain'),
        cat: ToolCat.life,
        icon: Icons.track_changes_rounded,
        color: SD.green,
        keywords: 'عادات عادة سلسلة متتبع يومي هدف habit habits streak tracker routine',
        builder: (_) => const HabitsTool(),
      ),
      ToolDef(
        id: 'tasks',
        name: t('المهام', 'المهام', 'Tasks'),
        sub: t('شنو عندك الليلة؟', 'ماذا لديك اليوم؟', 'What\'s on today?'),
        cat: ToolCat.life,
        icon: Icons.task_alt_rounded,
        color: SD.nile,
        keywords: 'مهام مهمة قائمة شغل تذكير انجاز todo tasks to-do list checklist',
        builder: (_) => const TasksTool(),
      ),
      ToolDef(
        id: 'expenses',
        name: t('المصاريف اليومية', 'المصروفات اليومية', 'Daily Expenses'),
        sub: t('القروش مشت وين؟', 'أين ذهب المال؟', 'Where did the money go?'),
        cat: ToolCat.life,
        icon: Icons.receipt_long_rounded,
        color: SD.orange,
        keywords: 'مصاريف مصروف صرف ميزانية قروش فلوس جنيه expenses budget spending money',
        builder: (_) => const ExpensesTool(),
      ),
      ToolDef(
        id: 'debts',
        name: t('الديون', 'الديون', 'Debts'),
        sub: t('ليك وعليك', 'لك وعليك', 'Owed & owing'),
        cat: ToolCat.life,
        icon: Icons.handshake_rounded,
        color: SD.henna,
        keywords: 'ديون دين سلف سلفة قرض استلاف تذكير debts debt loan iou owe',
        builder: (_) => const DebtsTool(),
      ),
      ToolDef(
        id: 'sanduq',
        name: t('الصندوق', 'الصندوق', 'Sanduq'),
        sub: t('الختّة وجمعية الادخار', 'جمعية الادخار الدوّارة', 'Rotating savings group'),
        cat: ToolCat.life,
        icon: Icons.savings_rounded,
        color: SD.gold,
        sudan: true,
        keywords: 'صندوق ختة ختّة جمعية ادخار قرعة دور sanduq savings rosca rotating circle',
        builder: (_) => const SanduqTool(),
      ),
      ToolDef(
        id: 'counter',
        name: t('العدّاد', 'العدّاد', 'Tally Counter'),
        sub: t('عدّ أي حاجة', 'عُدّ أي شيء', 'Count anything'),
        cat: ToolCat.life,
        icon: Icons.exposure_plus_1_rounded,
        color: SD.indigo,
        keywords: 'عداد عدد عد جوالات زوار حساب counter tally count clicker',
        builder: (_) => const CounterTool(),
      ),
    ];
