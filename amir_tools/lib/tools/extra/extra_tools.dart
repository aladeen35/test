import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../registry.dart';
import 'card_scores_tool.dart';
import 'domino_tool.dart';
import 'img_pdf_tool.dart';
import 'mirror_tool.dart';
import 'notes_tool.dart';
import 'recorder_tool.dart';
import 'travel_list_tool.dart';

List<ToolDef> get extraTools => [
      ToolDef(
        id: 'card_scores',
        name: t('حاسبة نقاط الكوتشينة', 'حاسبة نقاط الورق', 'Card Game Scores'),
        sub: t('كونكان وهاند وأي لعبة', 'كونكان وهاند وغيرها', 'Konkan, Hand & more'),
        cat: ToolCat.fun,
        icon: Icons.style_rounded,
        color: SD.henna,
        sudan: true,
        keywords: 'كوتشينة كوتشينه ورق كونكان كنكان هاند نقاط حساب جولة لعبة قعدة لاعبين فائز cards card game konkan conquian hand score keeper points rounds players winner',
        builder: (_) => const CardScoresTool(),
      ),
      ToolDef(
        id: 'domino',
        name: t('الضمنة وتقسيم الفرق', 'الدومينو وتقسيم الفرق', 'Domino & Team Split'),
        sub: t('عدّ النقاط وقسّم الفرق بالقرعة', 'حساب النقاط وتقسيم الفرق عشوائيًا', 'Score keeper & random teams'),
        cat: ToolCat.fun,
        icon: Icons.casino_rounded,
        color: SD.coffee,
        keywords: 'دومينو دومنة ضمنة نقاط فريق فرق تقسيم قرعة عشوائي 101 domino dominoes score teams split random shuffle draw',
        builder: (_) => const DominoTool(),
      ),
      ToolDef(
        id: 'notes',
        name: t('ملاحظات سريعة', 'ملاحظات سريعة', 'Quick Notes'),
        sub: t('أفكار وقوائم وأرقام', 'أفكار وقوائم وأرقام', 'Ideas, lists & numbers'),
        cat: ToolCat.life,
        icon: Icons.sticky_note_2_rounded,
        color: SD.gold,
        keywords: 'ملاحظات ملاحظة مذكرة نوتة كتابة قائمة مهام تثبيت بحث notes note memo notepad checklist todo pin search write',
        builder: (_) => const NotesTool(),
      ),
      ToolDef(
        id: 'img_pdf',
        name: t('الصور لـ PDF', 'الصور إلى PDF', 'Images to PDF'),
        sub: t('حوّل الأوراق والصور لملف واحد', 'حوّل الصور والمستندات إلى ملف واحد', 'Turn photos & papers into one PDF'),
        cat: ToolCat.media,
        icon: Icons.picture_as_pdf_rounded,
        color: SD.red,
        keywords: 'pdf بي دي اف صور ملف مستند سكانر مسح ضوئي تحويل أوراق شهادة فاتورة images to pdf scanner scan document convert photos jpg',
        builder: (_) => const ImgPdfTool(),
      ),
      ToolDef(
        id: 'recorder',
        name: t('مسجّل الصوت', 'مسجّل الصوت', 'Voice Recorder'),
        sub: t('سجّل واسمع وشارك', 'سجّل واستمع وشارك', 'Record, play & share'),
        cat: ToolCat.media,
        icon: Icons.mic_rounded,
        color: SD.pink,
        keywords: 'تسجيل مسجل صوت ريكورد مايك ميكروفون محاضرة ملاحظة صوتية voice recorder record audio memo microphone lecture m4a',
        builder: (_) => const RecorderTool(),
      ),
      ToolDef(
        id: 'mirror',
        name: t('المراية', 'المرآة', 'Mirror'),
        sub: t('الكاميرا الأمامية مع نور', 'الكاميرا الأمامية مع إضاءة', 'Front camera with ring light'),
        cat: ToolCat.device,
        icon: Icons.face_retouching_natural_rounded,
        color: SD.purple,
        keywords: 'مراية مرآة مرايه كاميرا أمامية سيلفي مكياج إضاءة نور mirror front camera selfie makeup ring light zoom',
        builder: (_) => const MirrorTool(),
      ),
      ToolDef(
        id: 'travel_list',
        name: t('قائمة تجهيز السفر', 'قائمة تجهيز السفر', 'Travel Packing List'),
        sub: t('عمرة، سودان، غربة، شفّع', 'عمرة، السودان، اغتراب، أطفال', 'Umrah, Sudan, expat, kids'),
        cat: ToolCat.work,
        icon: Icons.luggage_rounded,
        color: SD.nile,
        keywords: 'سفر شنطة حقيبة تجهيز قائمة عمرة حج سودان مغترب غربة أطفال جواز تذاكر هدايا travel packing list luggage suitcase umrah hajj sudan expat kids passport checklist',
        builder: (_) => const TravelListTool(),
      ),
    ];
