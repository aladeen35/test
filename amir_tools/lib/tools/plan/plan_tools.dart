import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'basket_tool.dart';
import 'meal_tool.dart';
import 'sadaqa_tool.dart';
import 'savings_tool.dart';
import 'study_tool.dart';
import 'trip_tool.dart';

List<ToolDef> get planTools => [
      ToolDef(
        id: 'savings_goals',
        name: tr('الادخار للأهداف', 'Savings Goals'),
        sub: t('حوّش لعمرتك وركشتك وزواجك', 'ادّخر لأهدافك خطوة بخطوة', 'Save step by step for your goals'),
        cat: ToolCat.money,
        icon: Icons.savings_rounded,
        color: SD.green,
        keywords: 'ادخار تحويش توفير هدف أهداف حصالة صندوق عمرة حج زواج عربية سيارة ركشة بيت موعد إيداع سحب savings saving goal goals target piggy bank deposit withdraw deadline progress',
        builder: (_) => const SavingsGoalsTool(),
      ),
      ToolDef(
        id: 'sadaqa',
        name: t('الصدقة الشهرية', 'الصدقة الشهرية', 'Monthly Charity Planner'),
        sub: t('خطة وسجل لصدقتك التطوعية', 'خطة وسجل للصدقة التطوعية', 'Plan & log voluntary charity'),
        cat: ToolCat.islam,
        icon: Icons.volunteer_activism_rounded,
        color: SD.teal,
        keywords: 'صدقة صدقات تطوع إنفاق انفاق خير فقراء مساكين أيتام مسجد أقارب سجل خطة نسبة sadaqa sadaqah charity giving donation voluntary needy orphans mosque plan log',
        builder: (_) => const SadaqaTool(),
      ),
      ToolDef(
        id: 'basket_compare',
        name: t('مقارنة سلة المشتريات', 'مقارنة سلة المشتريات', 'Basket Price Compare'),
        sub: t('ياتو محل أرخص؟', 'أيّ متجر أرخص؟', 'Which shop is cheapest?'),
        cat: ToolCat.money,
        icon: Icons.shopping_basket_rounded,
        color: SD.orange,
        keywords: 'مقارنة أسعار سلة مشتريات دكان بقالة سوق محل أرخص توفير سعر basket compare price prices shop shops cheapest grocery market savings split',
        builder: (_) => const BasketCompareTool(),
      ),
      ToolDef(
        id: 'meal_plan',
        name: t('مخطط وجبات الأسرة', 'مخطط وجبات الأسرة', 'Family Meal Planner'),
        sub: t('فطور وغدا وعشا الأسبوع', 'وجبات الأسبوع وقائمة المشتريات', 'Weekly meals & shopping list'),
        cat: ToolCat.home,
        icon: Icons.restaurant_menu_rounded,
        color: SD.henna,
        sudan: true,
        keywords: 'وجبات أكل طبخ فطور غدا غداء عشا عشاء أسبوع عصيدة كسرة ملاح فول طعمية قراصة بامية ملوخية مشتريات ميزانية meal meals plan planner menu breakfast lunch dinner week cooking recipes shopping list budget sudanese food',
        builder: (_) => const MealPlanTool(),
      ),
      ToolDef(
        id: 'trip_plan',
        name: t('مخطط الرحلة', 'مخطط الرحلة', 'Trip Planner'),
        sub: t('المحطات والبرنامج والميزانية', 'المحطات والبرنامج والميزانية', 'Stops, itinerary & budget'),
        cat: ToolCat.work,
        icon: Icons.flight_takeoff_rounded,
        color: SD.nile,
        keywords: 'رحلة سفر سفرية مخطط برنامج محطات حجز تذكرة فيزا تأشيرة جواز ميزانية عمرة إجازة trip travel planner itinerary stops booking ticket visa passport budget vacation countdown documents',
        builder: (_) => const TripPlanTool(),
      ),
      ToolDef(
        id: 'study_plan',
        name: t('جدول المذاكرة', 'جدول المذاكرة', 'Study Planner'),
        sub: t('مواعيد الامتحانات وخطة المراجعة', 'الامتحانات وخطة المراجعة', 'Exams & revision plan'),
        cat: ToolCat.learn,
        icon: Icons.school_rounded,
        color: SD.indigo,
        keywords: 'مذاكرة دراسة جدول امتحان امتحانات مراجعة مواد شهادة جامعة مدرسة حصص تنبيه study planner exam exams revision timetable subjects school university sessions reminder',
        builder: (_) => const StudyPlanTool(),
      ),
    ];
