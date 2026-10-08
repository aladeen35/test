import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'safety_common.dart';

class _Step {
  final String id, title;
  final List<String> how;
  const _Step(this.id, this.title, this.how);
}

List<_Step> get _steps => [
      _Step('source', t('مين المصدر؟', 'ما المصدر؟', 'Who is the source?'), [
        t('الخبر من جهة معروفة ولا «منقول» ساكت؟', 'هل الخبر من جهة معروفة أم «منقول» فقط؟', 'Is it from a known outlet or just "forwarded"?'),
        t('افتح صفحة المصدر نفسه — الحسابات المزيّفة بتقلّد الأسماء والشعارات.', 'افتح صفحة المصدر نفسه — الحسابات المزيفة تقلّد الأسماء والشعارات.',
            'Open the source\'s own page — fake accounts copy names and logos.'),
        t('«مصدر مطّلع» و«قالوا» ما مصدر.', '«مصدر مطّلع» و«قيل» ليست مصادر.', '"An informed source" or "they say" is not a source.'),
      ]),
      _Step('date', t('شوف التاريخ', 'تحقق من التاريخ', 'Check the date'), [
        t('كتير من الأخبار والفيديوهات قديمة وبتتنشر تاني كأنها هسي.', 'كثير من الأخبار والمقاطع قديمة وتُنشر من جديد كأنها حديثة.',
            'Many stories and videos are old and recirculated as if new.'),
        t('دوّر على تاريخ النشر الأصلي، وطقس/لبس الناس في الصورة.', 'ابحث عن تاريخ النشر الأصلي، ولاحظ الطقس وملابس الناس في الصورة.',
            'Look for the original publish date, and clues like weather or clothing in the picture.'),
      ]),
      _Step('image', t('ابحث عن الصورة بحث عكسي', 'ابحث عن الصورة بحثًا عكسيًا', 'Reverse-search the image'), [
        t('ارفع الصورة أو لقطة من الفيديو في Google Lens/Images أو TinEye (الروابط تحت).', 'ارفع الصورة أو لقطة من الفيديو في Google Lens أو TinEye (الروابط أدناه).',
            'Upload the image or a video frame to Google Lens/Images or TinEye (links below).'),
        t('لو لقيتها منشورة قبل سنين أو في بلد تاني — الخبر مضلّل.', 'إن وجدتها منشورة قبل سنوات أو في بلد آخر — فالخبر مضلل.',
            'If it was published years ago or in another country — the story is misleading.'),
      ]),
      _Step('others', t('قارن بمصادر تانية', 'قارن بمصادر أخرى', 'Compare with other outlets'), [
        t('خبر كبير حقيقي بتنقله أكتر من جهة معروفة.', 'الخبر الكبير الحقيقي تنقله أكثر من جهة معروفة.', 'A big true story is reported by several known outlets.'),
        t('لو بس في قروبات واتساب — استنّى.', 'إن كان في مجموعات واتساب فقط — انتظر.', 'If it is only in WhatsApp groups — wait.'),
        t('شوف مواقع التحقق من الأخبار (تحت).', 'راجع مواقع التحقق من الأخبار (أدناه).', 'Check fact-checking sites (below).'),
      ]),
      _Step('emotion', t('انتبه للتلاعب بالمشاعر', 'انتبه للتلاعب بالمشاعر', 'Watch for emotional manipulation'), [
        t('الأخبار الكاذبة بتتعمل عشان تزعّلك أو تخوّفك عشان تنشرها بسرعة.', 'الأخبار الكاذبة تُصاغ لتغضبك أو تخيفك فتنشرها بسرعة.',
            'Fake news is built to anger or scare you so you share fast.'),
        t('«انشرها قبل ما تتمسح!» و«الإعلام ساكت عن ده» علامات خطر.', '«انشرها قبل أن تُحذف!» و«الإعلام يتجاهل هذا» علامات خطر.',
            '"Share before it is deleted!" and "the media hides this" are red flags.'),
      ]),
      _Step('ai', t('علامات صور الذكاء الاصطناعي', 'علامات صور الذكاء الاصطناعي', 'Signs of AI-generated images'), [
        t('أصابع وأيادي غريبة (زايدة أو ناقصة أو ملتوية).', 'أصابع وأيدٍ غريبة (زائدة أو ناقصة أو ملتوية).', 'Odd hands and fingers (extra, missing, twisted).'),
        t('كتابة مشوّهة في اللافتات والملابس.', 'كتابة مشوّهة في اللافتات والملابس.', 'Garbled text on signs and clothing.'),
        t('بشرة ناعمة زيادة ولمعة بلاستيكية، وخلفية مموّهة أو أشياء ذايبة في بعض.', 'بشرة ناعمة جدًا ولمعة بلاستيكية، وخلفية ضبابية أو أشياء متداخلة.',
            'Overly smooth, plastic-like skin; blurry backgrounds or objects melting into each other.'),
        t('ضل وإضاءة ما منطقيين، وأقراط/نظارات مختلفة بين الجهتين.', 'ظل وإضاءة غير منطقيين، وأقراط أو نظارات مختلفة بين الجانبين.',
            'Shadows and lighting that do not make sense; mismatched earrings or glasses.'),
        t('العلامات دي بتقل مع تطور البرامج — ما في علامة أكيدة، فارجع للمصدر.', 'هذه العلامات تقل مع تطور البرامج — لا علامة قاطعة، فارجع إلى المصدر.',
            'These signs fade as tools improve — none is certain, so go back to the source.'),
      ]),
      _Step('content', t('اقرأ الخبر كله', 'اقرأ الخبر كاملًا', 'Read beyond the headline'), [
        t('العنوان أحيانًا ما بيطابق المحتوى.', 'العنوان أحيانًا لا يطابق المحتوى.', 'Headlines sometimes do not match the content.'),
        t('أخطاء إملائية كتيرة وحروف كبيرة وعلامات تعجب!!! علامة خطر.', 'كثرة الأخطاء الإملائية وعلامات التعجب!!! علامة خطر.', 'Lots of typos, ALL CAPS and !!! are red flags.'),
        t('الأرقام والاقتباسات: دوّر عليها في المصدر الأصلي.', 'الأرقام والاقتباسات: ابحث عنها في المصدر الأصلي.', 'Numbers and quotes: look them up in the original source.'),
      ]),
      _Step('health', t('الوصفات والعلاجات «المعجزة»', 'الوصفات والعلاجات «المعجزة»', 'Miracle cures'), [
        t('أي علاج بيقول «بيشفي كل الأمراض» أو «الدكاترة مخبينه» — غالبًا كذب وممكن يضر.', 'أي علاج يدّعي «شفاء كل الأمراض» أو «يخفيه الأطباء» — غالبًا كذب وقد يضر.',
            'Any cure that "heals everything" or "doctors hide" is most likely false and may be harmful.'),
        t('اسأل طبيب أو صيدلي، أو مواقع وزارة الصحة ومنظمة الصحة العالمية.', 'اسأل طبيبًا أو صيدليًا، أو مواقع وزارة الصحة ومنظمة الصحة العالمية.',
            'Ask a doctor or pharmacist, or check health ministry / WHO websites.'),
      ]),
    ];

class _Q {
  final String id, text;
  final int w;
  const _Q(this.id, this.text, this.w);
}

List<_Q> get _questions => [
      _Q('nosource', t('ما معروف مين نشره أول مرة؟', 'لا يُعرف من نشره أولًا؟', 'Unknown who first published it?'), 25),
      _Q('noother', t('ما لقيته في أي جهة أخبار معروفة؟', 'لم تجده لدى أي جهة إخبارية معروفة؟', 'Not reported by any known outlet?'), 20),
      _Q('fwd', t('مكتوب عليه «أُعيد توجيهه عدة مرات»؟', 'عليه وسم «أُعيد توجيهه عدة مرات»؟', 'Labelled "Forwarded many times"?'), 10),
      _Q('share', t('بيقول «انشرها بسرعة» أو «قبل ما تتمسح»؟', 'يقول «انشرها بسرعة» أو «قبل أن تُحذف»؟', 'Says "share fast" or "before it is deleted"?'), 15),
      _Q('emotion', t('خلاك زعلان شديد أو خايف؟', 'أثار غضبك أو خوفك بشدة؟', 'Made you very angry or scared?'), 15),
      _Q('date', t('ما فيه تاريخ أو التاريخ قديم؟', 'بلا تاريخ أو التاريخ قديم؟', 'No date, or an old date?'), 10),
      _Q('image', t('الصورة/الفيديو شكله معدّل أو ذكاء اصطناعي؟', 'الصورة/الفيديو تبدو معدّلة أو بالذكاء الاصطناعي؟', 'Image/video looks edited or AI-made?'), 15),
      _Q('style', t('أخطاء إملائية وعلامات تعجب كتيرة؟', 'أخطاء إملائية وعلامات تعجب كثيرة؟', 'Lots of typos and exclamation marks?'), 10),
      _Q('tooGood', t('خبر غريب شديد أو «سر ما بيقولوه ليك»؟', 'خبر غريب جدًا أو «سر يخفونه عنك»؟', 'Too shocking, or "the secret they hide"?'), 15),
    ];

class _Res {
  final String name, url, sub;
  const _Res(this.name, this.url, this.sub);
}

List<_Res> get _imageTools => [
      _Res('Google Images', 'https://www.google.com/imghp', t('ارفع صورة بزر الكاميرا', 'ارفع صورة بزر الكاميرا', 'Upload with the camera button')),
      _Res('Google Lens', 'https://lens.google.com', t('بحث بالصورة', 'بحث بالصورة', 'Search by image')),
      _Res('TinEye', 'https://tineye.com', t('بيوريك أقدم نسخة للصورة', 'يعرض أقدم نسخة للصورة', 'Shows the oldest copies of an image')),
    ];

List<_Res> get _factArabic => [
      _Res(tr('مسبار', 'Misbar'), 'https://misbar.com', t('منصة عربية للتحقق من الأخبار', 'منصة عربية لتدقيق الأخبار', 'Arabic fact-checking platform')),
      _Res(tr('فتبيّنوا', 'Fatabyyano'), 'https://fatabyyano.net', t('منصة عربية للتحقق', 'منصة عربية للتحقق', 'Arabic fact-checking platform')),
    ];

List<_Res> get _factIntl => [
      _Res('AFP Fact Check', 'https://factcheck.afp.com', t('وكالة الأنباء الفرنسية', 'وكالة الأنباء الفرنسية', 'Agence France-Presse')),
      _Res('Google Fact Check Explorer', 'https://toolbox.google.com/factcheck/explorer', t('بحث في تدقيقات منشورة', 'بحث في تدقيقات منشورة', 'Search published fact-checks')),
      _Res('Snopes', 'https://www.snopes.com', t('إنجليزي', 'بالإنجليزية', 'English')),
      _Res('Full Fact', 'https://fullfact.org', t('إنجليزي (بريطانيا)', 'بالإنجليزية (بريطانيا)', 'English (UK)')),
    ];

class NewsCheckTool extends StatefulWidget {
  const NewsCheckTool({super.key});
  @override
  State<NewsCheckTool> createState() => _NewsCheckToolState();
}

class _NewsCheckToolState extends State<NewsCheckTool> {
  final yes = <String>{};
  final stepsDone = <String>{};
  bool scored = false;

  int get _score {
    final total = _questions.fold<int>(0, (a, q) => a + q.w);
    final got = _questions.where((q) => yes.contains(q.id)).fold<int>(0, (a, q) => a + q.w);
    return (got * 100 / total).round();
  }

  void _record(AppState s) {
    if (scored) return;
    scored = true;
    s.setData('news_check_tests', (s.getData<num>('news_check_tests') ?? 0).toInt() + 1);
    s.awardDaily('news_check', 5, t('اتأكدت من خبر', 'تحقّق من خبر', 'Checked a story'));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final score = _score;
    final tests = (s.getData<num>('news_check_tests') ?? 0).toInt();
    final (label, advice, colors) = score >= 45
        ? (
            t('خطر عالي — ما ترسله', 'خطر مرتفع — لا ترسله', 'High risk — do not forward'),
            t('غالبًا مضلّل. ما ترسله، واسأل الرسّله ليك عن مصدره.', 'غالبًا مضلل. لا ترسله، واسأل من أرسله عن مصدره.', 'Likely misleading. Do not forward; ask the sender for the source.'),
            const [Color(0xFF9A2A1A), Color(0xFF6E1D12), Color(0xFF45110A)]
          )
        : score >= 20
            ? (
                t('مشكوك فيه — اتأكد أول', 'مشكوك فيه — تحقق أولًا', 'Doubtful — verify first'),
                t('اعمل خطوات التحقق تحت قبل ما ترسله.', 'نفّذ خطوات التحقق أدناه قبل إرساله.', 'Do the verification steps below before forwarding.'),
                const [Color(0xFFB9852F), Color(0xFF8A5528), Color(0xFF5A3418)]
              )
            : (
                t('خطر قليل', 'خطر منخفض', 'Low risk'),
                t('يبدو معقول — بس برضو تأكد من المصدر لو مهم.', 'يبدو معقولًا — لكن تحقق من المصدر إن كان مهمًا.', 'Looks reasonable — still check the source if it matters.'),
                const [Color(0xFF0B6B32), Color(0xFF075226), Color(0xFF033815)]
              );
    return ToolList(children: [
      SCard(
        title: t('اختبار «قبل ما ترسل»', 'اختبار «قبل أن ترسل»', '"Before you forward" test'),
        icon: Icons.forward_to_inbox_rounded,
        color: SD.orange,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t('جاوب على الخبر اللي وصلك:', 'أجب عن الخبر الذي وصلك:', 'Answer about the message you got:'),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7))),
          const SizedBox(height: 6),
          for (final q in _questions)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: yes.contains(q.id),
              onChanged: (v) => setState(() {
                v ? yes.add(q.id) : yes.remove(q.id);
                _record(s);
              }),
              title: Text(q.text, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ]),
      ),
      ResultHero(label: t('درجة الخطورة', 'درجة الخطورة', 'Risk score'), value: '$score%', sub: '$label\n$advice', colors: colors),
      if (yes.isNotEmpty)
        ShareBar(() => [
              '🔎 ${t('فحص خبر قبل النشر', 'فحص خبر قبل النشر', 'Checked a message before forwarding')}: $score% — $label',
              for (final q in _questions)
                if (yes.contains(q.id)) '⚠️ ${q.text}',
              '',
              t('ما ترسل أي خبر قبل ما تتأكد من مصدره 🙏', 'لا ترسل أي خبر قبل التحقق من مصدره 🙏', 'Do not forward anything before checking its source 🙏'),
            ].join('\n')),
      const SizedBox(height: 12),
      SCard(
        title: t('خطوات التحقق', 'خطوات التحقق', 'Verification steps'),
        icon: Icons.fact_check_rounded,
        color: SD.nile,
        child: Column(children: [
          SafetyProgress(t('خلصت', 'أنجزت', 'Done'), stepsDone.length, _steps.length, color: SD.nile),
          for (final st in _steps)
            CheckItemTile(
              title: st.title,
              steps: st.how,
              done: stepsDone.contains(st.id),
              color: SD.nile,
              onChanged: (v) => setState(() => v ? stepsDone.add(st.id) : stepsDone.remove(st.id)),
            ),
        ]),
      ),
      SCard(
        title: t('البحث العكسي عن الصور', 'البحث العكسي عن الصور', 'Reverse image search'),
        icon: Icons.image_search_rounded,
        color: SD.teal,
        child: Column(children: [for (final r in _imageTools) LinkTile(r.name, r.url, sub: r.sub, icon: Icons.image_search_rounded, color: SD.teal)]),
      ),
      SCard(
        title: t('مواقع التحقق من الأخبار', 'مواقع تدقيق الأخبار', 'Fact-checking sites'),
        icon: Icons.travel_explore_rounded,
        color: SD.indigo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(tr('بالعربي', 'Arabic'), style: const TextStyle(fontWeight: FontWeight.w800)),
          for (final r in _factArabic) LinkTile(r.name, r.url, sub: r.sub, icon: Icons.verified_rounded, color: SD.indigo),
          const SizedBox(height: 6),
          Text(tr('عالمية', 'International'), style: const TextStyle(fontWeight: FontWeight.w800)),
          for (final r in _factIntl) LinkTile(r.name, r.url, sub: r.sub, icon: Icons.verified_rounded, color: SD.indigo),
        ]),
      ),
      StatGrid([
        StatChip('$tests', t('أخبار فحصتها', 'أخبار فحصتها', 'Stories checked'), color: SD.orange, icon: Icons.fact_check_rounded),
        StatChip('${stepsDone.length}/${_steps.length}', t('خطوات اليوم', 'خطوات الآن', 'Steps now'), color: SD.nile, icon: Icons.checklist_rounded),
      ], columns: 2),
      const SizedBox(height: 8),
      NoteBox(
          t('الدرجة دي تقدير مساعد بس، ما حكم نهائي على الخبر. المواقع الخارجية مسؤولة عن محتواها.', 'هذه الدرجة تقدير مساعد فقط وليست حكمًا نهائيًا. المواقع الخارجية مسؤولة عن محتواها.',
              'This score is only a helper estimate, not a verdict. External sites are responsible for their own content.'),
          kind: NoteKind.info),
      const ReviewedLine('news_check', item: 'links'),
    ]);
  }
}
