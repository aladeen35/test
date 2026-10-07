import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'fidya_tool.dart';
import 'flashcards_tool.dart';
import 'hifz_tool.dart';
import 'last_third_tool.dart';
import 'sd_certificate_tool.dart';
import 'times_table_tool.dart';

List<ToolDef> get learnTools => [
      ToolDef(
        id: 'hifz',
        name: tr('حفظ القرآن ومراجعته', "Qur'an Memorization"),
        sub: t('ورد يومي ومراجعة بالدور', 'ورد يومي ومراجعة دورية', 'Daily portion & spaced review'),
        cat: ToolCat.islam,
        icon: Icons.auto_stories_rounded,
        color: SD.green,
        keywords:
            'حفظ القرآن قرآن مراجعة ورد تثبيت جزء أجزاء صفحة صفحات مصحف خلوة تحفيظ سورة جزء عم تبارك الناس الفاتحة حافظ hifz quran memorization memorize review revision juz page mushaf surah portion streak',
        builder: (_) => const HifzTool(),
      ),
      ToolDef(
        id: 'last_third',
        name: tr('ثلث الليل الأخير', 'Last Third of the Night'),
        sub: t('متين يبدأ الثلث الأخير الليلة', 'وقت بداية الثلث الأخير الليلة', 'When the last third begins tonight'),
        cat: ToolCat.islam,
        icon: Icons.nights_stay_rounded,
        color: SD.indigo,
        keywords:
            'ثلث الليل الأخير الثلث الأخير قيام الليل تهجد وتر نزول منتصف الليل نص الليل سحور دعاء استغفار last third night qiyam tahajjud witr midnight descent dua suhoor',
        builder: (_) => const LastThirdTool(),
      ),
      ToolDef(
        id: 'fidya',
        name: tr('الفدية والكفارات', 'Fidya & Kaffarat'),
        sub: t('فدية الصيام وكفارة اليمين ورمضان', 'فدية الصيام وكفارتا اليمين ورمضان', 'Fasting fidya, oath & Ramadan expiation'),
        cat: ToolCat.islam,
        icon: Icons.volunteer_activism_rounded,
        color: SD.henna,
        keywords:
            'فدية كفارة كفارات يمين حلف قسم رمضان صيام إطعام مسكين مساكين مد صاع كسوة صيام شهرين ستين جماع كبير السن مريض fidya kaffara kaffarah expiation oath ramadan fasting feeding poor mudd saa',
        builder: (_) => const FidyaTool(),
      ),
      ToolDef(
        id: 'sd_certificate',
        name: t('نسبة الشهادة السودانية', 'نسبة الشهادة السودانية', 'Sudan Certificate %'),
        sub: t('أحسن 7 مواد من 700', 'أفضل 7 مواد من 700', 'Best 7 subjects out of 700'),
        cat: ToolCat.learn,
        icon: Icons.school_rounded,
        color: SD.nile,
        sudan: true,
        keywords:
            'الشهادة السودانية شهادة نسبة مجموع درجات مواد علمي أدبي قبول جامعة تقدير امتحانات ثانوي sudan certificate percentage marks grades science arts admission university secondary exam',
        builder: (_) => const SdCertificateTool(),
      ),
      ToolDef(
        id: 'flashcards',
        name: tr('بطاقات المذاكرة', 'Flashcards'),
        sub: t('احفظ بالبطاقات وصناديق لايتنر', 'احفظ بالبطاقات وصناديق لايتنر', 'Study with Leitner boxes'),
        cat: ToolCat.learn,
        icon: Icons.style_rounded,
        color: SD.purple,
        keywords:
            'بطاقات مذاكرة كروت حفظ مراجعة كلمات مفردات إنجليزي امتحان لايتنر تكرار متباعد flashcards cards study revise vocabulary words exam leitner spaced repetition deck',
        builder: (_) => const FlashcardsTool(),
      ),
      ToolDef(
        id: 'times_table',
        name: tr('جدول الضرب', 'Times Tables'),
        sub: t('للشفع: جدول ولعبة بنجوم', 'للأطفال: جدول ولعبة بالنجوم', 'For kids: table & star quiz'),
        cat: ToolCat.learn,
        icon: Icons.calculate_rounded,
        color: SD.orange,
        keywords:
            'جدول الضرب ضرب حساب رياضيات أطفال شفع لعبة اختبار نجوم مدرسة times table multiplication math kids children quiz game stars school',
        builder: (_) => const TimesTableTool(),
      ),
    ];
