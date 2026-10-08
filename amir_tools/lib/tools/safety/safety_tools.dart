import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'account_security_tool.dart';
import 'fraud_alerts_tool.dart';
import 'link_check_tool.dart';
import 'news_check_tool.dart';

List<ToolDef> get safetyTools => [
      ToolDef(
        id: 'account_security',
        name: t('حماية حساباتك', 'حماية حساباتك', 'Account Security'),
        sub: t('واتساب وفيسبوك وجيميل والبنك', 'واتساب وفيسبوك وجيميل والبنك', 'WhatsApp, Facebook, Gmail & bank'),
        cat: ToolCat.safety,
        icon: Icons.admin_panel_settings_rounded,
        color: SD.green,
        keywords:
            'حماية أمان حساب حسابات واتساب فيسبوك انستغرام إنستغرام جيميل قوقل جوجل بنك بنكك تحقق بخطوتين مصادقة ثنائية رمز PIN شريحة سيم قفل الشاشة اختراق اتسرق تيليجرام '
            'account security whatsapp facebook instagram gmail google bank two-step verification 2fa pin sim lock screen hacked recovery telegram',
        builder: (_) => const AccountSecurityTool(),
      ),
      ToolDef(
        id: 'fraud_alerts',
        name: t('تنبيهات الاحتيال', 'تنبيهات الاحتيال', 'Scam Awareness'),
        sub: t('اعرف النصب قبل ما يقع', 'اكتشف الاحتيال قبل وقوعه', 'Spot scams before they hit'),
        cat: ToolCat.safety,
        icon: Icons.report_gmailerrorred_rounded,
        color: SD.red,
        keywords:
            'احتيال نصب نصابين حرامية خداع رسالة بنك تحويل إشعار مزور جائزة فزت كود واتساب وظيفة تأشيرة فيزا غربة استثمار مضاعفة عملات رقمية كريبتو تبرعات تصيد اختبار '
            'scam fraud fake bank sms transfer receipt prize lottery whatsapp code job visa abroad investment crypto doubling relative charity phishing quiz',
        builder: (_) => const FraudAlertsTool(),
      ),
      ToolDef(
        id: 'news_check',
        name: t('التحقق من الأخبار', 'التحقق من الأخبار', 'News Verification'),
        sub: t('اتأكد قبل ما ترسل', 'تحقق قبل أن ترسل', 'Check before you forward'),
        cat: ToolCat.safety,
        icon: Icons.fact_check_rounded,
        color: SD.nile,
        keywords:
            'أخبار خبر كاذب شائعات شائعة إشاعة تحقق تدقيق مصدر صورة فيديو بحث عكسي ذكاء اصطناعي مسبار فتبينوا نشر إعادة توجيه '
            'news fake rumor rumour fact check verify source reverse image search ai image misbar fatabyyano forward misinformation',
        builder: (_) => const NewsCheckTool(),
      ),
      ToolDef(
        id: 'link_check',
        name: t('فاحص الروابط', 'فاحص الروابط', 'Link Checker'),
        sub: t('الرابط ده آمن ولا نصب؟', 'هل الرابط آمن أم احتيال؟', 'Is this link safe or a scam?'),
        cat: ToolCat.safety,
        icon: Icons.link_off_rounded,
        color: SD.orange,
        keywords:
            'رابط روابط لينك فحص تصيد موقع مزيف مختصر نطاق دومين آمن خطر احتيال '
            'link url checker phishing fake site domain shortener bit.ly punycode homoglyph safe suspicious scam',
        builder: (_) => const LinkCheckTool(),
      ),
    ];
