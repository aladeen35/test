import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'cv_tool.dart';
import 'dialect_tool.dart';
import 'holidays_tool.dart';
import 'links_tool.dart';
import 'terms_tool.dart';

List<ToolDef> get knowTools => [
      ToolDef(
        id: 'sd_dialect',
        name: t('قاموس اللهجة السودانية', 'قاموس اللهجة السودانية', 'Sudanese Dialect Dictionary'),
        sub: t('كلامنا بالفصحى والإنجليزي', 'العامية السودانية بالفصحى والإنجليزية', 'Sudanese words in MSA & English'),
        cat: ToolCat.learn,
        icon: Icons.record_voice_over_rounded,
        color: SD.henna,
        sudan: true,
        keywords: 'قاموس لهجة سودانية عامية كلمات معنى زول شنو كدا ياخ هسي داير عديل تب ملاح كسرة عنقريب جبنة كلمة اليوم ترجمة dictionary sudanese dialect arabic colloquial slang words meaning translate word of the day',
        builder: (_) => const DialectTool(),
      ),
      ToolDef(
        id: 'official_terms',
        name: t('قاموس المصطلحات الرسمية', 'قاموس المصطلحات الرسمية', 'Official Terms Glossary'),
        sub: t('كلام الورق الرسمي ببساطة', 'مصطلحات المعاملات بشرح مبسّط', 'Paperwork terms made simple'),
        cat: ToolCat.work,
        icon: Icons.gavel_rounded,
        color: SD.nile,
        keywords: 'مصطلحات رسمية إقرار تعهد تفويض توكيل تصديق توثيق كفيل كفالة إقامة تأشيرة خروج وعودة حسن سير وسلوك استمارة مخالصة نهاية خدمة عقد عمل فترة تجربة حوالة كشف حساب ايبان سويفت glossary official terms paperwork bank iban swift visa residency sponsor contract probation power of attorney attestation',
        builder: (_) => const TermsTool(),
      ),
      ToolDef(
        id: 'cv_builder',
        name: t('منشئ السيرة الذاتية', 'منشئ السيرة الذاتية', 'CV Builder'),
        sub: t('سيرتك PDF بالعربي أو الإنجليزي', 'سيرة ذاتية PDF بالعربية أو الإنجليزية', 'Arabic or English CV as PDF'),
        cat: ToolCat.work,
        icon: Icons.badge_rounded,
        color: SD.gold,
        keywords: 'سيرة ذاتية سي في cv resume pdf وظيفة تقديم خبرات مهارات تعليم لغات شهادات قالب job application template skills experience education',
        builder: (_) => const CvTool(),
      ),
      ToolDef(
        id: 'holidays',
        name: t('العطل والمناسبات الرسمية', 'العطل والمناسبات الرسمية', 'Public Holidays'),
        sub: t('كم فاضل للعيد والعطلة الجاية', 'العد التنازلي للعطل والأعياد', 'Countdown to the next holiday'),
        cat: ToolCat.daily,
        icon: Icons.celebration_rounded,
        color: SD.green,
        keywords: 'عطل عطلة إجازة رسمية أعياد عيد الفطر الأضحى الضحية عرفة رأس السنة الهجرية المولد رمضان الاستقلال اليوم الوطني يوم التأسيس عد تنازلي holidays public holiday eid fitr adha arafah hijri new year mawlid ramadan independence national day countdown',
        builder: (_) => const HolidaysTool(),
      ),
      ToolDef(
        id: 'official_links',
        name: t('روابط الجهات الرسمية', 'روابط الجهات الرسمية والخدمية', 'Official & Service Links'),
        sub: t('مواقع رسمية موثوقة بس', 'مواقع رسمية موثوقة فقط', 'Trusted official websites only'),
        cat: ToolCat.work,
        icon: Icons.travel_explore_rounded,
        color: SD.teal,
        keywords: 'روابط مواقع رسمية حكومية أبشر قوى مساند جوازات إقامة تأشيرة لاجئين مفوضية صليب أحمر هلال أحمر صحة official links websites government absher qiwa unhcr icrc ifrc who unicef iom refugees visa residency portal',
        builder: (_) => const LinksTool(),
      ),
    ];
