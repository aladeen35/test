import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'hadith_tool.dart';
import 'hajj_umrah_tool.dart';
import 'quran_search_tool.dart';
import 'share_cards_tool.dart';

List<ToolDef> get quranTools => [
      ToolDef(
        id: 'quran_search',
        name: t('البحث في القرآن والتفسير', 'البحث في القرآن والتفسير', "Qur'an Search & Tafsir"),
        sub: t('دوّر في الآيات واقرأ التفسير', 'ابحث في الآيات واقرأ التفسير', 'Search ayat, read tafsir'),
        cat: ToolCat.quran,
        icon: Icons.menu_book_rounded,
        color: SD.green,
        keywords: 'قرآن القرآن مصحف آية آيات سورة سور بحث تفسير الميسر الجلالين ترجمة معاني تلاوة quran koran mushaf ayah verse surah search tafsir translation saheeh international',
        builder: (_) => const QuranSearchTool(),
      ),
      ToolDef(
        id: 'hadith',
        name: tr('الأحاديث', 'Hadith Collections'),
        sub: t('النووية والقدسية وكتب السنة', 'النووية والقدسية وكتب السنة', 'Nawawi, Qudsi & major books'),
        cat: ToolCat.quran,
        icon: Icons.auto_stories_rounded,
        color: SD.coffee,
        keywords: 'حديث أحاديث سنة الأربعين النووية القدسية البخاري مسلم أبو داود الترمذي النسائي ابن ماجه موطأ مالك hadith sunnah nawawi forty qudsi bukhari muslim abu dawud tirmidhi nasai ibn majah muwatta malik',
        builder: (_) => const HadithTool(),
      ),
      ToolDef(
        id: 'share_cards',
        name: t('بطاقات المشاركة', 'بطاقات المشاركة', 'Verse & Dhikr Cards'),
        sub: t('صمّم بطاقة آية أو ذكر وشاركها', 'صمّم بطاقة آية أو ذكر وشاركها', 'Design & share ayah or dhikr cards'),
        cat: ToolCat.quran,
        icon: Icons.style_rounded,
        color: SD.gold,
        keywords: 'بطاقة بطاقات صورة تصميم آية ذكر دعاء مشاركة واتساب ستوري حالة card cards image design ayah verse dhikr dua share whatsapp story status',
        builder: (_) => const ShareCardsTool(),
      ),
      ToolDef(
        id: 'hajj_umrah',
        name: t('دليل الحج والعمرة', 'دليل الحج والعمرة', 'Hajj & Umrah Guide'),
        sub: t('المناسك خطوة بخطوة', 'المناسك خطوة بخطوة', 'Rites step by step'),
        cat: ToolCat.islam,
        icon: Icons.mosque_rounded,
        color: SD.teal,
        keywords: 'حج عمرة مناسك إحرام ميقات تلبية طواف سعي عرفة مزدلفة منى رمي الجمرات تمتع قران إفراد hajj umrah manasik ihram miqat talbiyah tawaf sai arafah muzdalifah mina jamarat',
        builder: (_) => const HajjUmrahTool(),
      ),
    ];
