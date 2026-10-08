/// محتوى دليل الحج والعمرة — مختصر من صفة حج النبي ﷺ (حديث جابر في صحيح مسلم) وكتب المناسك المعتمدة
/// وإرشادات وزارة الحج والعمرة بالمملكة العربية السعودية. النصوص الشرعية منقولة بلفظها مع مصدرها.
library;

import '../../core/i18n.dart';

class HDua {
  final String text, srcAr, srcEn;
  final String? meaningEn;
  const HDua(this.text, this.srcAr, this.srcEn, {this.meaningEn});
  String get source => tr(srcAr, srcEn);
}

class HStep {
  final String id;
  final String Function() title;
  final List<String> Function() points;
  final List<HDua> duas;
  final String Function()? madhab;
  const HStep(this.id, this.title, this.points, {this.duas = const [], this.madhab});
}

const talbiyah = HDua(
  'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لَا شَرِيكَ لَكَ',
  'متفق عليه (من حديث ابن عمر رضي الله عنهما)',
  'Al-Bukhari & Muslim (from Ibn Umar)',
  meaningEn: 'Here I am, O Allah, here I am. Here I am, You have no partner, here I am. All praise, grace and sovereignty belong to You; You have no partner.',
);

const _rabbana = HDua(
  'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
  'بين الركن اليماني والحجر الأسود — رواه أبو داود، وهي آية من سورة البقرة: 201',
  'Between the Yemeni corner and the Black Stone — Abu Dawud; the words are Qur\'an 2:201',
  meaningEn: 'Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.',
);

const _takbir = HDua('اللَّهُ أَكْبَرُ', 'عند محاذاة الحجر الأسود في كل شوط — رواه البخاري', 'When passing the Black Stone each round — Al-Bukhari',
    meaningEn: 'Allah is the Greatest.');

const _maqam = HDua('وَاتَّخِذُوا مِن مَّقَامِ إِبْرَاهِيمَ مُصَلًّى', 'سورة البقرة: 125 — قرأها النبي ﷺ عند المقام (صحيح مسلم، حديث جابر)',
    'Qur\'an 2:125 — recited by the Prophet ﷺ at the Maqam (Muslim, hadith of Jabir)',
    meaningEn: 'And take the standing place of Ibrahim as a place of prayer.');

const _safaAyah = HDua('إِنَّ الصَّفَا وَالْمَرْوَةَ مِن شَعَائِرِ اللَّهِ', 'سورة البقرة: 158 — تُقرأ عند بداية السعي فقط، ويقول: «أبدأ بما بدأ الله به» (صحيح مسلم)',
    'Qur\'an 2:158 — recited at the start of sa\'i only, then: “I begin with what Allah began with” (Muslim)',
    meaningEn: 'Indeed, as-Safa and al-Marwah are among the symbols of Allah.');

const _safaDhikr = HDua(
  'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ، أَنْجَزَ وَعْدَهُ، وَنَصَرَ عَبْدَهُ، وَهَزَمَ الْأَحْزَابَ وَحْدَهُ',
  'على الصفا والمروة مستقبلًا القبلة، ثلاث مرات يدعو بينها — صحيح مسلم (حديث جابر)',
  'On Safa and Marwah facing the Qibla, three times with du\'a in between — Muslim (hadith of Jabir)',
  meaningEn: 'None has the right to be worshipped but Allah alone… He fulfilled His promise, aided His servant, and defeated the confederates alone.',
);

const _arafah = HDua(
  'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
  '«خير الدعاء دعاء يوم عرفة، وخير ما قلت أنا والنبيون من قبلي…» — رواه الترمذي وحسّنه الألباني',
  '“The best du\'a is the du\'a of the Day of Arafah, and the best that I and the prophets before me said…” — At-Tirmidhi (graded hasan by al-Albani)',
);

const _jamrah = HDua('اللَّهُ أَكْبَرُ', 'مع كل حصاة — صحيح مسلم (حديث جابر)', 'With every pebble — Muslim (hadith of Jabir)');

/// المواقيت الخمسة
List<(String, String)> get miqats => [
      (tr('ذو الحليفة (أبيار علي)', 'Dhul-Hulayfah (Abyar Ali)'), tr('لأهل المدينة ومن مرّ بها', 'For the people of Madinah and those passing by it')),
      (tr('الجُحفة (يُحرم الناس اليوم من رابغ)', 'Al-Juhfah (people now enter ihram at Rabigh)'),
          tr('لأهل الشام ومصر والمغرب ومن جاء من جهتهم', 'For the Levant, Egypt, North Africa and those coming from that direction')),
      (tr('قرن المنازل (السيل الكبير)', 'Qarn al-Manazil (As-Sayl al-Kabir)'), tr('لأهل نجد ومن جاء من جهتها', 'For Najd and those coming from that direction')),
      (tr('يَلَمْلَم (السعدية)', 'Yalamlam (As-Sa\'diyyah)'), tr('لأهل اليمن ومن جاء من جهتها', 'For Yemen and those coming from that direction')),
      (tr('ذات عِرق', 'Dhat Irq'), tr('لأهل العراق ومن جاء من جهتها', 'For Iraq and those coming from that direction')),
    ];

List<HStep> get umrahSteps => [
      HStep('u_prep', () => t('قبل الإحرام', 'قبل الإحرام', 'Before ihram'), () => [
            tr('يُسنّ الاغتسال والتنظّف، ويتطيّب الرجل في بدنه لا في ثياب الإحرام.', 'It is Sunnah to take a bath (ghusl) and clean up; men may perfume the body, not the ihram garments.'),
            tr('الرجل يلبس إزارًا ورداءً أبيضين نظيفين، ويخلع المخيط (الملابس المفصّلة على البدن).', 'Men wear two clean white sheets (izar and rida) and remove tailored clothing.'),
            tr('المرأة تُحرم في ثيابها المحتشمة المعتادة بلا لون مخصوص، ولا تلبس النقاب ولا القفازين.', 'Women enter ihram in their usual modest clothes (no special colour), without niqab or gloves.'),
          ]),
      HStep('u_ihram', () => t('الإحرام من الميقات والتلبية', 'الإحرام من الميقات والتلبية', 'Ihram at the miqat & talbiyah'), () => [
            tr('عند الميقات انوِ الدخول في النسك وقل: «لبّيك عمرة»، ثم أكثر من التلبية.', 'At the miqat, make the intention and say “Labbayka ‘Umrah”, then recite the talbiyah often.'),
            tr('من كان مسكنه دون المواقيت يُحرم من مكانه، وأهل مكة يُحرمون للعمرة من الحِلّ (كالتنعيم).',
                'Those living inside the miqat boundary enter ihram from home; residents of Makkah go out to the Hill area (e.g. at-Tan\'im) for Umrah.'),
            tr('المسافر بالطائرة أو الباخرة يُحرم إذا حاذى الميقات، فاسأل حملتك أو المرشد عن الميقات المحاذي لرحلتك؛ وفي الإحرام من جدة للقادمين من جهة البحر خلاف بين العلماء.',
                'Travelling by air or sea, enter ihram when you are parallel to the miqat — ask your group/guide which one applies; scholars differ on entering ihram at Jeddah for those coming across the sea.'),
            tr('تقطع التلبية عند بدء الطواف.', 'Stop the talbiyah when you begin tawaf.'),
          ], duas: const [talbiyah]),
      HStep('u_tawaf', () => t('الطواف سبعة أشواط', 'الطواف سبعة أشواط', 'Tawaf: 7 rounds'), () => [
            tr('ابدأ من الحجر الأسود والكعبة عن يسارك، واختم كل شوط عنده: سبعة أشواط كاملة.', 'Start at the Black Stone with the Ka\'bah on your left, and complete each round there: seven full rounds.'),
            tr('استلم الحجر الأسود أو قبّله إن تيسّر بلا مزاحمة، وإلا أشِر إليه وكبّر.', 'Touch or kiss the Black Stone if easy without pushing; otherwise point to it and say takbir.'),
            tr('استلم الركن اليماني بيدك إن تيسّر، ولا تُشِر إليه عند الزحام.', 'Touch the Yemeni corner if easy; do not point to it when crowded.'),
            tr('للرجل: الاضطباع (كشف الكتف الأيمن) في هذا الطواف كله، والرَّمَل (الإسراع بخطًى قصيرة) في الأشواط الثلاثة الأولى.',
                'Men: idtiba\' (right shoulder uncovered) during this tawaf, and raml (brisk short steps) in the first three rounds.'),
            tr('لا يثبت دعاء مخصوص لكل شوط؛ ادعُ واذكر الله واقرأ القرآن بما تيسّر.', 'There is no fixed du\'a for each round; make any du\'a, dhikr or Qur\'an recitation.'),
            tr('الطواف يكون من وراء حِجر إسماعيل لأنه من الكعبة.', 'Tawaf must be outside the Hijr (Hatim), as it is part of the Ka\'bah.'),
          ], duas: const [_takbir, _rabbana], madhab: () => tr('الطهارة للطواف شرط عند الجمهور، وواجبة عند الحنفية.', 'Wudu for tawaf is a condition according to the majority, and obligatory (wajib) according to the Hanafis.')),
      HStep('u_maqam', () => t('ركعتان خلف مقام إبراهيم', 'ركعتان خلف مقام إبراهيم', 'Two rak\'ahs behind Maqam Ibrahim'), () => [
            tr('بعد الطواف غطِّ كتفك وصلِّ ركعتين خلف المقام إن تيسّر، وإلا ففي أي مكان من المسجد.', 'After tawaf, cover your shoulder and pray two rak\'ahs behind the Maqam if possible, otherwise anywhere in the mosque.'),
            tr('يُسنّ أن تقرأ فيهما سورة الكافرون ثم سورة الإخلاص (صحيح مسلم).', 'It is Sunnah to recite Surat al-Kafirun then al-Ikhlas in them (Muslim).'),
          ], duas: const [_maqam]),
      HStep('u_zamzam', () => t('ماء زمزم', 'ماء زمزم', 'Zamzam water'), () => [
            tr('اشرب من ماء زمزم وادعُ بما تحب، ثم ارجع إلى الحجر الأسود فاستلمه إن تيسّر قبل الذهاب للسعي.',
                'Drink Zamzam and make du\'a, then return to touch the Black Stone if easy before going to sa\'i.'),
          ]),
      HStep('u_sai', () => t('السعي سبعة أشواط', 'السعي سبعة أشواط', 'Sa\'i: 7 laps'), () => [
            tr('ابدأ بالصفا واختم بالمروة: من الصفا إلى المروة شوط، والرجوع شوط ثانٍ.', 'Start at Safa and finish at Marwah: Safa→Marwah is one lap, the return is the second.'),
            tr('على الصفا والمروة استقبل القبلة وكبّر وهلّل وادعُ.', 'On Safa and Marwah, face the Qibla, glorify Allah and make du\'a.'),
            tr('يُسنّ للرجل الإسراع بين العَلَمين الأخضرين.', 'Men should hasten between the two green markers.'),
            tr('لا تُشترط الطهارة للسعي، ولا يثبت دعاء مخصوص لكل شوط.', 'Wudu is not a condition for sa\'i, and there is no fixed du\'a per lap.'),
          ], duas: const [_safaAyah, _safaDhikr], madhab: () => tr('السعي ركن في العمرة والحج عند الجمهور، وواجب عند الحنفية.', 'Sa\'i is a pillar (rukn) according to the majority and wajib according to the Hanafis.')),
      HStep('u_halq', () => t('الحلق أو التقصير', 'الحلق أو التقصير', 'Shaving or trimming'), () => [
            tr('يحلق الرجل رأسه (وهو أفضل) أو يقصّر، والمرأة تقصّ من أطراف شعرها قدر أنملة.', 'Men shave (better) or trim; women cut a fingertip\'s length from the ends of the hair.'),
            tr('بهذا تتم العمرة ويحلّ لك كل ما حُرّم بالإحرام.', 'With this, Umrah is complete and all ihram restrictions are lifted.'),
          ], madhab: () => tr('في قدر التقصير للرجل خلاف: يعمّ الرأس عند المالكية والحنابلة، ويكفي ربعه عند الحنفية، وثلاث شعرات عند الشافعية.',
              'Minimum trimming for men differs: the whole head (Maliki, Hanbali), a quarter (Hanafi), three hairs (Shafi\'i).')),
    ];

/// أنواع النسك
List<(String, String)> get hajjTypes => [
      (tr('التمتّع', 'Tamattu\''), tr('يُحرم بالعمرة في أشهر الحج ويتحلّل منها، ثم يُحرم بالحج يوم الثامن من عامه. وعليه الهدي.',
          'Umrah in the Hajj months, exit ihram, then ihram for Hajj on the 8th of the same year. A sacrifice (hady) is due.')),
      (tr('القِران', 'Qiran'), tr('يُحرم بالعمرة والحج معًا ويبقى على إحرامه إلى يوم النحر. وعليه الهدي.',
          'Ihram for Umrah and Hajj together, staying in ihram until the Day of Sacrifice. A hady is due.')),
      (tr('الإفراد', 'Ifrad'), tr('يُحرم بالحج وحده ويبقى على إحرامه إلى يوم النحر. ولا هدي عليه.', 'Ihram for Hajj only, staying in ihram until the Day of Sacrifice. No hady is due.')),
    ];

List<HStep> get hajjSteps => [
      HStep('h_8', () => t('8 ذو الحجة — يوم التروية', '8 ذو الحجة — يوم التروية', '8 Dhul-Hijjah — Day of Tarwiyah'), () => [
            tr('المتمتّع يُحرم بالحج من مكانه بمكة، والقارن والمفرد باقيان على إحرامهما.', 'The mutamatti\' enters ihram for Hajj from where he is in Makkah; qarin and mufrid remain in ihram.'),
            tr('التوجّه إلى منى وصلاة الظهر والعصر والمغرب والعشاء وفجر التاسع فيها، قصرًا للرباعية بلا جمع.',
                'Go to Mina and pray Dhuhr, Asr, Maghrib, Isha and Fajr of the 9th there, shortening four-rak\'ah prayers without combining.'),
            tr('الإكثار من التلبية.', 'Recite the talbiyah often.'),
          ], duas: const [talbiyah]),
      HStep('h_9', () => t('9 ذو الحجة — يوم عرفة', '9 ذو الحجة — يوم عرفة', '9 Dhul-Hijjah — Day of Arafah'), () => [
            tr('بعد طلوع الشمس التوجّه إلى عرفة، وصلاة الظهر والعصر جمعًا وقصرًا بأذان وإقامتين.', 'After sunrise go to Arafah; pray Dhuhr and Asr combined and shortened (one adhan, two iqamahs).'),
            tr('الوقوف بعرفة ركن الحج الأعظم: تأكّد أنك داخل حدود عرفة (اللوحات الإرشادية)، واجتهد في الدعاء مستقبلًا القبلة.',
                'Standing at Arafah is the greatest pillar of Hajj: make sure you are within its boundaries (sign-posted) and devote yourself to du\'a facing the Qibla.'),
            tr('لا تنصرف قبل غروب الشمس. ولا يُشرع صعود جبل الرحمة.', 'Do not leave before sunset. Climbing Jabal ar-Rahmah is not part of the rites.'),
          ], duas: const [_arafah]),
      HStep('h_muz', () => t('ليلة 10 — مزدلفة', 'ليلة 10 — مزدلفة', 'Night of the 10th — Muzdalifah'), () => [
            tr('بعد الغروب الدفع إلى مزدلفة بسكينة، وصلاة المغرب والعشاء جمعًا وقصر العشاء.', 'After sunset proceed calmly to Muzdalifah; pray Maghrib and Isha combined, shortening Isha.'),
            tr('المبيت بها وصلاة الفجر، ثم الذكر والدعاء حتى الإسفار، والدفع إلى منى قبل طلوع الشمس.', 'Stay the night, pray Fajr, make dhikr and du\'a until it is bright, then leave for Mina before sunrise.'),
            tr('يجوز للضعفة والنساء ومن معهم الدفع آخر الليل.', 'The weak, women and those accompanying them may leave in the latter part of the night.'),
            tr('التقاط الحصى يجوز من أي مكان، ولا يلزم غسله.', 'Pebbles may be picked up anywhere; washing them is not required.'),
          ]),
      HStep('h_10', () => t('10 ذو الحجة — يوم النحر', '10 ذو الحجة — يوم النحر', '10 Dhul-Hijjah — Day of Sacrifice'), () => [
            tr('رمي جمرة العقبة بسبع حصيات متعاقبات مع التكبير، وتُقطع التلبية عند بدء الرمي.', 'Stone Jamrat al-Aqabah with seven pebbles, one after another with takbir; stop the talbiyah when you start.'),
            tr('ذبح الهدي للمتمتّع والقارن.', 'Slaughter the hady (for tamattu\' and qiran).'),
            tr('الحلق أو التقصير.', 'Shave or trim the hair.'),
            tr('طواف الإفاضة (ركن)، ثم السعي للمتمتّع، وللقارن والمفرد إن لم يسعيا بعد طواف القدوم.', 'Tawaf al-Ifadah (a pillar), then sa\'i for the mutamatti\', and for qarin/mufrid if they did not do sa\'i after tawaf al-qudum.'),
            tr('لا حرج في تقديم بعض هذه الأعمال على بعض: «افعل ولا حرج» (متفق عليه).', 'There is no harm in changing the order: “Do it, there is no harm” (Al-Bukhari & Muslim).'),
            tr('التحلل الأول يحصل عند كثير من العلماء بفعل اثنين من ثلاثة: الرمي، والحلق أو التقصير، والطواف؛ فيحلّ كل شيء إلا النساء، وبالثلاثة يحصل التحلل الكامل.',
                'Many scholars hold the first release from ihram comes after two of three acts (stoning, shaving/trimming, tawaf): everything becomes lawful except marital relations; all three bring full release.'),
          ], duas: const [_jamrah]),
      HStep('h_tashreeq', () => t('11–13 ذو الحجة — أيام التشريق', '11–13 ذو الحجة — أيام التشريق', '11–13 Dhul-Hijjah — Days of Tashriq'), () => [
            tr('المبيت بمنى ليالي أيام التشريق.', 'Spend the nights of the Tashriq days in Mina.'),
            tr('رمي الجمرات الثلاث كل يوم بعد الزوال: الصغرى ثم الوسطى ثم العقبة، سبع حصيات لكل جمرة مع التكبير.',
                'Each day after midday stone the three jamarat in order: small, middle, then Aqabah — seven pebbles each with takbir.'),
            tr('يُسنّ الوقوف للدعاء مستقبلًا القبلة بعد الصغرى والوسطى.', 'It is Sunnah to stand making du\'a facing the Qibla after the small and middle jamrah.'),
            tr('من تعجّل خرج من منى يوم 12 قبل الغروب، ومن تأخّر رمى يوم 13.', 'Those in a hurry leave Mina on the 12th before sunset; otherwise stay and stone on the 13th.'),
            tr('يجوز التوكيل في الرمي للعاجز كالمريض وكبير السن.', 'Someone unable (sick, elderly) may appoint another to stone on their behalf.'),
          ], duas: const [_jamrah], madhab: () => tr('المبيت بمنى واجب عند الجمهور وسنّة عند الحنفية، والرمي بعد الزوال هو قول الجمهور.',
              'Staying overnight in Mina is wajib for the majority and Sunnah for the Hanafis; stoning after midday is the majority view.')),
      HStep('h_wada', () => t('طواف الوداع', 'طواف الوداع', 'Farewell tawaf'), () => [
            tr('آخر ما تفعله قبل مغادرة مكة: طواف سبعة أشواط بلا سعي.', 'The last thing before leaving Makkah: seven rounds of tawaf, without sa\'i.'),
            tr('يسقط عن الحائض والنفساء.', 'It is waived for women in menses or postpartum bleeding.'),
          ]),
    ];

/// محظورات الإحرام
List<String> get ihramProhibitions => [
      tr('إزالة الشعر وتقليم الأظافر.', 'Removing hair and clipping nails.'),
      tr('استعمال الطيب في البدن أو الثوب أو المأكول.', 'Using perfume on body, clothes or food.'),
      tr('للرجل: لبس المخيط (كالقميص والسراويل والعمائم والبرانس والخفاف) — متفق عليه.', 'Men: wearing tailored clothing (shirts, trousers, turbans, hooded cloaks, leather socks) — Al-Bukhari & Muslim.'),
      tr('للرجل: تغطية الرأس بملاصق، أما الاستظلال بالمظلة أو الخيمة أو السيارة فجائز.', 'Men: covering the head with something attached; shade from an umbrella, tent or vehicle is fine.'),
      tr('للمرأة: النقاب والقفازان، وتستر وجهها عن الرجال الأجانب بغير النقاب.', 'Women: niqab and gloves; she may cover her face from non-mahram men by other means.'),
      tr('قتل صيد البر أو المساعدة عليه.', 'Hunting land game or helping to do so.'),
      tr('عقد النكاح.', 'Contracting a marriage.'),
      tr('الجماع ومقدماته، والجماع قبل التحلل الأول يُفسد الحج.', 'Intercourse and foreplay; intercourse before the first release invalidates the Hajj.'),
    ];

/// أخطاء شائعة
List<String> get commonMistakes => [
      tr('تجاوز الميقات دون إحرام لمن قصد الحج أو العمرة.', 'Passing the miqat without ihram while intending Hajj or Umrah.'),
      tr('الاضطباع طوال وقت الإحرام، والسنة أنه في طواف العمرة والقدوم فقط.', 'Keeping the right shoulder uncovered all the time — it is only for the tawaf of Umrah/arrival.'),
      tr('الطواف داخل حِجر إسماعيل.', 'Making tawaf inside the Hijr (Hatim).'),
      tr('مزاحمة الناس وإيذاؤهم لتقبيل الحجر الأسود.', 'Pushing and harming people to kiss the Black Stone.'),
      tr('التزام أدعية مخصوصة لكل شوط من الكتيّبات.', 'Insisting on booklet du\'as specific to each round.'),
      tr('الوقوف خارج حدود عرفة، أو الانصراف منها قبل الغروب.', 'Standing outside the boundaries of Arafah, or leaving before sunset.'),
      tr('رمي الجمرات بحصى كبيرة أو بالأحذية، أو الرمي بالسبع دفعة واحدة.', 'Throwing large stones or shoes at the jamarat, or all seven pebbles at once.'),
      tr('ترك طواف الوداع لغير الحائض والنفساء، أو الإقامة الطويلة بمكة بعده.', 'Skipping the farewell tawaf (unless excused), or staying long in Makkah after it.'),
    ];
