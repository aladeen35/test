import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/i18n.dart';
import '../core/pattern.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// الرابط العام لسياسة الخصوصية (GitHub Pages من مجلد docs/ في المستودع)
const privacyPolicyUrl = 'https://aladeen35.github.io/test/privacy-policy.html';
const supportEmail = 'aladeen35@gmail.com';

/// سياسة الخصوصية داخل التطبيق — نفس نص الصفحة المنشورة، وتعمل بدون إنترنت
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static void open(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()));

  @override
  Widget build(BuildContext context) {
    final sections = <(IconData, Color, String, List<String>)>[
      (
        Icons.verified_user_rounded,
        SD.green,
        t('الخلاصة', 'الخلاصة', 'Summary'),
        [
          t('ما في تسجيل دخول، ولا إعلانات، ولا أدوات تتبّع أو تحليلات، وما عندنا خوادم بنحفظ فيها بياناتك. أي حاجة بتكتبها في التطبيق بتتحفظ في تلفونك بس.',
              'لا نطلب تسجيل دخول، ولا نعرض إعلانات، ولا نستخدم أدوات تتبّع أو تحليلات، ولا نملك خوادم تُحفظ فيها بياناتك. كل ما تُدخله في التطبيق يُحفظ على جهازك فقط.',
              'No sign-in, no ads, no tracking or analytics SDKs, and no servers that store your data. Everything you enter in the app stays on your device.'),
        ]
      ),
      (
        Icons.phone_android_rounded,
        SD.nile,
        t('البيانات المحفوظة في تلفونك', 'البيانات المحفوظة على جهازك', 'Data stored on your device'),
        [
          t('اسمك (لو كتبتو)، والمدينة، والمفضلة، والنقاط، والعادات، والمهام، والمصاريف، والديون، وسجلات الصحة، ومواعيد الدواء، والقصص، والخزنة وغيرها. كلها في تلفونك وبتنمسح لو مسحت التطبيق.',
              'اسمك (اختياري)، والمدينة المختارة، والمفضلة، والنقاط، والعادات، والمهام، والمصاريف، والديون، وسجلات الصحة، ومواعيد الدواء، والقصص والشخصيات، ومحتوى الخزنة، وغيرها. تبقى في ذاكرة التطبيق على هاتفك وتُحذف عند حذف التطبيق.',
              'Your name (optional), selected city, favourites, points, habits, tasks, expenses, debts, health logs, medicine schedules, stories and characters, vault content and similar data are stored locally and removed when you uninstall the app.'),
          t('النسخة الاحتياطية بتعمل ملف إنت البتحفظو وبتقرر وين تختو.', 'ميزة «النسخة الاحتياطية» تُنشئ ملفًا تحتفظ به أنت وتقرر أين تضعه.',
              'The backup feature creates a file that you keep and control.'),
        ]
      ),
      (
        Icons.public_rounded,
        SD.teal,
        t('الاتصال بالنت', 'الاتصال بالإنترنت', 'Internet connections'),
        [
          t('Open-Meteo: للطقس وجودة الهوا والبحث عن المدن. بنرسل ليها اسم المدينة أو إحداثياتها التقريبية بس.',
              'Open-Meteo: لجلب الطقس وجودة الهواء والبحث عن المدن. يُرسل إليها اسم المدينة أو إحداثياتها التقريبية فقط.',
              'Open-Meteo: weather, air quality and city search. Only the city name or its approximate coordinates are sent.'),
          t('ExchangeRate-API: لأسعار العملات الرسمية. ما بنرسل ليها أي حاجة عنك.', 'ExchangeRate-API: لجلب أسعار العملات الرسمية. لا تُرسل إليها أي بيانات عنك.',
              'ExchangeRate-API: official currency rates. No data about you is sent.'),
          t('GitHub: لتنزيل ملفات اللغة لاستخراج النص، ونص المصحف والتفاسير والأحاديث، أول مرة بس.', 'GitHub: لتنزيل ملفات اللغة لاستخراج النص، ونص المصحف والتفاسير وكتب الحديث، عند أول استخدام فقط.',
              'GitHub: one-time downloads of OCR language data and the Qur\'an, tafsir and hadith texts.'),
          t('كل الاتصالات مشفّرة (HTTPS).', 'كل الاتصالات مشفّرة عبر HTTPS.', 'All connections are encrypted with HTTPS.'),
        ]
      ),
      (
        Icons.admin_panel_settings_rounded,
        SD.orange,
        t('الأذونات', 'الأذونات', 'Permissions'),
        [
          t('الموقع (اختياري): لمواقيت الصلاة والقبلة والطقس، وبس والتطبيق فاتح. وممكن تختار المدينة بإيدك.',
              'الموقع (اختياري): لتحديد مدينتك لمواقيت الصلاة والقبلة والطقس، فقط والتطبيق مفتوح. ويمكنك اختيار المدينة يدويًا.',
              'Location (optional): finds your city for prayer times, qibla and weather, only while the app is open. You can pick a city manually.'),
          t('الكاميرا: لرمز QR واستخراج النص وتحويل الصور لـ PDF والمراية والكشاف. الصور بتتعالج في تلفونك وما بترفع.', 'الكاميرا: لمسح رمز QR والتصوير لاستخراج النص أو التحويل إلى PDF والمرآة والكشاف. تُعالج الصور على الجهاز ولا تُرفع.',
              'Camera: QR scanning, OCR and images-to-PDF photos, the mirror and the flashlight. Images are processed on-device and never uploaded.'),
          t('المايك: لمسجّل الصوت (التسجيلات بتتحفظ في تلفونك بس)، ولمقياس الضوضاء (ما بيتسجّل) وللكتابة بالصوت عن طريق خدمة نظام تلفونك.', 'الميكروفون: لمسجّل الصوت (تُحفظ التسجيلات على جهازك فقط)، ولمقياس الضوضاء (يُحلَّل لحظيًا ولا يُسجَّل) وللكتابة بالصوت عبر خدمة نظام هاتفك.',
              'Microphone: voice recorder (recordings stay on your device), noise meter (analysed live, never recorded) and voice typing through your phone\'s system speech service.'),
          t('الإشعارات: لتنبيهات الأذان والدواء والفواتير والأوراق والصيام، بتتجدول في تلفونك.', 'الإشعارات: لتنبيهات الأذان والدواء والفواتير والمستندات والصيام، وتُجدول على جهازك.',
              'Notifications: prayer, medicine, bill, document and fasting reminders, scheduled on your device.'),
        ]
      ),
      (
        Icons.share_rounded,
        SD.henna,
        t('المشاركة', 'مشاركة البيانات', 'Sharing'),
        [
          t('ما بنبيع ولا بنشارك بياناتك مع أي زول. المشاركة الوحيدة هي الإنت بتعملها بزر «مشاركة».',
              'لا نبيع بياناتك ولا نشاركها مع أي طرف. المشاركة الوحيدة هي ما تشاركه أنت بنفسك عبر زر «مشاركة».',
              'We do not sell or share your data. The only sharing is what you choose to share through your phone\'s share menu.'),
        ]
      ),
      (
        Icons.child_care_rounded,
        SD.purple,
        t('الأطفال', 'الأطفال', 'Children'),
        [
          t('التطبيق ما موجّه للأطفال تحت 13 سنة، وما بنجمع عنهم أي بيانات.', 'التطبيق غير موجّه للأطفال دون 13 عامًا، ولا نجمع عمدًا أي بيانات عنهم.',
              'The app is not directed at children under 13, and we do not knowingly collect any data from them.'),
        ]
      ),
    ];

    return SudanBackground(
      child: Scaffold(
        appBar: AppBar(title: Text(t('سياسة الخصوصية', 'سياسة الخصوصية', 'Privacy policy'))),
        body: ToolList(children: [
          Text('${tr('آخر تحديث', 'Last updated')}: 2026-10-08 • Ameer Tools (com.albushra.amir_tools)',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 10),
          for (final (icon, color, title, paras) in sections)
            SCard(
              title: title,
              icon: icon,
              color: color,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final p in paras) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(p, style: const TextStyle(height: 1.6))),
              ]),
            ),
          SCard(
            title: t('التواصل', 'التواصل', 'Contact'),
            icon: Icons.mail_rounded,
            color: SD.gold,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse('mailto:$supportEmail')),
                icon: const Icon(Icons.alternate_email_rounded),
                label: const FittedBox(fit: BoxFit.scaleDown, child: Text(supportEmail)),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => launchUrl(Uri.parse(privacyPolicyUrl), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new_rounded),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('افتح الصفحة في المتصفح', 'فتح الصفحة في المتصفح', 'Open in browser'))),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
