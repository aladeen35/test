import 'package:flutter/material.dart';
import '../../core/i18n.dart';

/// مكتبة الأدعية الصحيحة — النص العربي كما ورد، مع المصدر ومعنى مختصر بالإنجليزية.
/// لا يُضاف هنا إلا نص ثابت متيقَّن من لفظه ومصدره.

enum DuaCat {
  istikhara(Icons.alt_route_rounded),
  travel(Icons.flight_takeoff_rounded),
  home(Icons.home_rounded),
  mosque(Icons.mosque_rounded),
  food(Icons.restaurant_rounded),
  sleep(Icons.bedtime_rounded),
  distress(Icons.healing_rounded),
  sickness(Icons.local_hospital_rounded),
  rain(Icons.water_drop_rounded),
  clothes(Icons.checkroom_rounded),
  toilet(Icons.wash_rounded),
  wudu(Icons.water_rounded),
  parents(Icons.family_restroom_rounded),
  forgiveness(Icons.favorite_rounded);

  final IconData icon;
  const DuaCat(this.icon);

  String get label => switch (this) {
        DuaCat.istikhara => tr('الاستخارة', 'Istikhara'),
        DuaCat.travel => tr('السفر', 'Travel'),
        DuaCat.home => tr('البيت', 'Home'),
        DuaCat.mosque => tr('المسجد', 'Mosque'),
        DuaCat.food => t('الأكل', 'الطعام', 'Eating'),
        DuaCat.sleep => tr('النوم والاستيقاظ', 'Sleep & waking'),
        DuaCat.distress => tr('الكرب والهم', 'Distress & anxiety'),
        DuaCat.sickness => tr('المرض وعيادة المريض', 'Sickness'),
        DuaCat.rain => tr('المطر', 'Rain'),
        DuaCat.clothes => tr('اللباس', 'Clothes'),
        DuaCat.toilet => t('الحمّام', 'الخلاء', 'Toilet'),
        DuaCat.wudu => tr('الوضوء', 'Wudu'),
        DuaCat.parents => tr('للوالدين', 'For parents'),
        DuaCat.forgiveness => tr('الاستغفار', 'Forgiveness'),
      };
}

class Dua {
  final String id;
  final DuaCat cat;

  /// متى يُقال (عربي، إنجليزي)
  final String whenAr, whenEn;
  final String text;

  /// المصدر بالعربية والإنجليزية
  final String srcAr, srcEn;
  final String meaning;

  /// عدد التكرار المسنون إن وُجد
  final int repeat;
  final bool quran;
  const Dua(this.id, this.cat, this.whenAr, this.whenEn, this.text, this.srcAr, this.srcEn, this.meaning, {this.repeat = 1, this.quran = false});

  String get when => tr(whenAr, whenEn);
  String get source => tr(srcAr, srcEn);
}

/// إزالة التشكيل لتسهيل البحث
String stripTashkeel(String s) => s
    .replaceAll(RegExp('[ً-ٰٟۖ-ۭـ]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه');

const duas = <Dua>[
  // ── الاستخارة ──
  Dua(
    'istikhara',
    DuaCat.istikhara,
    'إذا همّ أحدكم بالأمر فليركع ركعتين من غير الفريضة ثم ليقل:',
    'When you are deciding on a matter, pray two non-obligatory rak\'ahs, then say:',
    'اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ بِعِلْمِكَ، وَأَسْتَقْدِرُكَ بِقُدْرَتِكَ، وَأَسْأَلُكَ مِنْ فَضْلِكَ الْعَظِيمِ، فَإِنَّكَ تَقْدِرُ وَلَا أَقْدِرُ، وَتَعْلَمُ وَلَا أَعْلَمُ، وَأَنْتَ عَلَّامُ الْغُيُوبِ، اللَّهُمَّ إِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الْأَمْرَ خَيْرٌ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي -أَوْ قَالَ: عَاجِلِ أَمْرِي وَآجِلِهِ- فَاقْدُرْهُ لِي وَيَسِّرْهُ لِي، ثُمَّ بَارِكْ لِي فِيهِ، وَإِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الْأَمْرَ شَرٌّ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي -أَوْ قَالَ: فِي عَاجِلِ أَمْرِي وَآجِلِهِ- فَاصْرِفْهُ عَنِّي وَاصْرِفْنِي عَنْهُ، وَاقْدُرْ لِيَ الْخَيْرَ حَيْثُ كَانَ، ثُمَّ أَرْضِنِي بِهِ.\n(ويسمّي حاجته)',
    'رواه البخاري',
    'Al-Bukhari',
    'O Allah, I seek Your guidance through Your knowledge and Your power, and ask of Your great bounty. If You know this matter is good for my religion, livelihood and outcome, decree it for me, make it easy and bless it; if it is bad for me, turn it away from me and me from it, decree good for me wherever it is, and make me content with it. (Name the matter.)',
  ),
  // ── السفر ──
  Dua(
    'travel',
    DuaCat.travel,
    'إذا استوى على راحلته خارجًا إلى سفر',
    'When setting off on a journey (on your mount/vehicle)',
    'اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ، وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ، اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى، وَمِنَ الْعَمَلِ مَا تَرْضَى، اللَّهُمَّ هَوِّنْ عَلَيْنَا سَفَرَنَا هَذَا، وَاطْوِ عَنَّا بُعْدَهُ، اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ، وَالْخَلِيفَةُ فِي الْأَهْلِ، اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ وَعْثَاءِ السَّفَرِ، وَكَآبَةِ الْمَنْظَرِ، وَسُوءِ الْمُنْقَلَبِ فِي الْمَالِ وَالْأَهْلِ',
    'رواه مسلم',
    'Muslim',
    'Allah is the Greatest (×3). Glory be to Him who subjected this to us, which we could not have done ourselves, and to our Lord we shall return. O Allah, we ask You on this journey for righteousness, piety and deeds that please You; make this journey easy and shorten its distance. You are the Companion on the journey and the Guardian of the family. I seek refuge in You from the hardship of travel, a distressing sight, and a bad return to wealth and family.',
  ),
  Dua(
    'travel_return',
    DuaCat.travel,
    'عند الرجوع من السفر يقولهنّ ويزيد:',
    'On returning from the journey, say the same and add:',
    'آيِبُونَ تَائِبُونَ عَابِدُونَ لِرَبِّنَا حَامِدُونَ',
    'رواه مسلم',
    'Muslim',
    'Returning, repenting, worshipping, and praising our Lord.',
  ),
  // ── البيت ──
  Dua(
    'leave_home',
    DuaCat.home,
    'عند الخروج من البيت',
    'When leaving home',
    'بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'رواه أبو داود والترمذي',
    'Abu Dawud, al-Tirmidhi',
    'In the name of Allah, I place my trust in Allah, and there is no might nor power except with Allah.',
  ),
  Dua(
    'leave_home2',
    DuaCat.home,
    'عند الخروج من البيت',
    'When leaving home',
    'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ أَنْ أَضِلَّ أَوْ أُضَلَّ، أَوْ أَزِلَّ أَوْ أُزَلَّ، أَوْ أَظْلِمَ أَوْ أُظْلَمَ، أَوْ أَجْهَلَ أَوْ يُجْهَلَ عَلَيَّ',
    'رواه أبو داود والترمذي',
    'Abu Dawud, al-Tirmidhi',
    'O Allah, I seek refuge in You from going astray or being led astray, from slipping or being made to slip, from wronging or being wronged, and from acting foolishly or being treated foolishly.',
  ),
  Dua(
    'enter_home',
    DuaCat.home,
    'عند دخول البيت: ذِكر الله عند الدخول وعند الطعام',
    'Entering home: mention Allah on entering and at meals',
    'إِذَا دَخَلَ الرَّجُلُ بَيْتَهُ، فَذَكَرَ اللَّهَ عِنْدَ دُخُولِهِ وَعِنْدَ طَعَامِهِ، قَالَ الشَّيْطَانُ: لَا مَبِيتَ لَكُمْ، وَلَا عَشَاءَ',
    'رواه مسلم (حديث)',
    'Muslim (hadith)',
    'When a man enters his house and mentions Allah on entering and at his meal, Satan says (to his companions): "No place to stay and no dinner for you."',
  ),
  Dua(
    'enter_home_salam',
    DuaCat.home,
    'السلام عند دخول البيوت',
    'Greeting with salam when entering houses',
    'فَإِذَا دَخَلْتُم بُيُوتًا فَسَلِّمُوا عَلَىٰ أَنفُسِكُمْ تَحِيَّةً مِّنْ عِندِ اللَّهِ مُبَارَكَةً طَيِّبَةً',
    'سورة النور: 61',
    'Qur\'an, An-Nur 24:61',
    'When you enter houses, greet one another with a greeting from Allah, blessed and good.',
    quran: true,
  ),
  // ── المسجد ──
  Dua(
    'enter_mosque',
    DuaCat.mosque,
    'عند دخول المسجد',
    'When entering the mosque',
    'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
    'رواه مسلم',
    'Muslim',
    'O Allah, open for me the gates of Your mercy.',
  ),
  Dua(
    'leave_mosque',
    DuaCat.mosque,
    'عند الخروج من المسجد',
    'When leaving the mosque',
    'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
    'رواه مسلم',
    'Muslim',
    'O Allah, I ask You of Your bounty.',
  ),
  // ── الطعام ──
  Dua(
    'before_eat',
    DuaCat.food,
    'قبل الأكل',
    'Before eating',
    'بِسْمِ اللَّهِ',
    'رواه البخاري ومسلم',
    'Al-Bukhari, Muslim',
    'In the name of Allah.',
  ),
  Dua(
    'forgot_bismillah',
    DuaCat.food,
    'إذا نسي التسمية في أوله',
    'If you forgot to say it at the start',
    'بِسْمِ اللَّهِ أَوَّلَهُ وَآخِرَهُ',
    'رواه أبو داود والترمذي',
    'Abu Dawud, al-Tirmidhi',
    'In the name of Allah, at its beginning and its end.',
  ),
  Dua(
    'after_eat',
    DuaCat.food,
    'بعد الفراغ من الطعام',
    'After eating',
    'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا، وَرَزَقَنِيهِ، مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
    'رواه أبو داود والترمذي',
    'Abu Dawud, al-Tirmidhi',
    'Praise be to Allah who fed me this and provided it for me without any might or power on my part.',
  ),
  Dua(
    'after_eat2',
    DuaCat.food,
    'بعد الطعام (عند رفع المائدة)',
    'After eating (when the meal is cleared)',
    'الْحَمْدُ لِلَّهِ كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ، غَيْرَ مَكْفِيٍّ وَلَا مُوَدَّعٍ وَلَا مُسْتَغْنًى عَنْهُ رَبَّنَا',
    'رواه البخاري',
    'Al-Bukhari',
    'Praise be to Allah, abundant, good and blessed praise; (praise) that is never sufficient, never abandoned and never dispensed with, our Lord.',
  ),
  // ── النوم ──
  Dua(
    'sleep',
    DuaCat.sleep,
    'عند النوم',
    'Before sleeping',
    'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
    'رواه البخاري',
    'Al-Bukhari',
    'In Your name, O Allah, I die and I live.',
  ),
  Dua(
    'sleep2',
    DuaCat.sleep,
    'عند النوم: بعد الوضوء والاضطجاع على الشق الأيمن',
    'Before sleeping: after wudu, lying on the right side',
    'اللَّهُمَّ أَسْلَمْتُ وَجْهِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ، اللَّهُمَّ آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ',
    'رواه البخاري ومسلم',
    'Al-Bukhari, Muslim',
    'O Allah, I submit myself to You, entrust my affair to You and rely on You, out of hope and fear of You. There is no refuge or escape from You except to You. I believe in Your Book which You revealed and in Your Prophet whom You sent.',
  ),
  Dua(
    'wake',
    DuaCat.sleep,
    'عند الاستيقاظ',
    'On waking up',
    'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
    'رواه البخاري',
    'Al-Bukhari',
    'Praise be to Allah who gave us life after causing us to die, and to Him is the resurrection.',
  ),
  // ── الكرب ──
  Dua(
    'karb',
    DuaCat.distress,
    'دعاء الكرب',
    'Dua in times of distress (al-karb)',
    'لَا إِلَهَ إِلَّا اللَّهُ الْعَظِيمُ الْحَلِيمُ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ الْعَرْشِ الْعَظِيمِ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ السَّمَاوَاتِ وَرَبُّ الْأَرْضِ وَرَبُّ الْعَرْشِ الْكَرِيمِ',
    'رواه البخاري ومسلم',
    'Al-Bukhari, Muslim',
    'There is no god but Allah, the Mighty, the Forbearing. There is no god but Allah, Lord of the Mighty Throne. There is no god but Allah, Lord of the heavens, Lord of the earth and Lord of the Noble Throne.',
  ),
  Dua(
    'yunus',
    DuaCat.distress,
    'دعوة ذي النون (يونس عليه السلام)',
    'The supplication of Yunus (Jonah)',
    'لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
    'سورة الأنبياء: 87',
    'Qur\'an, Al-Anbiya 21:87',
    'There is no god but You, glory be to You; indeed I have been among the wrongdoers.',
    quran: true,
  ),
  Dua(
    'hamm',
    DuaCat.distress,
    'من الهمّ والحزن',
    'For worry and grief',
    'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ، وَغَلَبَةِ الرِّجَالِ',
    'رواه البخاري',
    'Al-Bukhari',
    'O Allah, I seek refuge in You from worry and grief, from incapacity and laziness, from miserliness and cowardice, from the burden of debt and from being overpowered by men.',
  ),
  Dua(
    'hasbuna',
    DuaCat.distress,
    'عند الخوف والشدة',
    'In fear and hardship',
    'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
    'سورة آل عمران: 173 — ورواه البخاري',
    'Qur\'an, Al Imran 3:173; al-Bukhari',
    'Allah is sufficient for us, and He is the best Disposer of affairs.',
    quran: true,
  ),
  // ── المرض ──
  Dua(
    'visit_sick',
    DuaCat.sickness,
    'عند عيادة المريض',
    'When visiting a sick person',
    'لَا بَأْسَ، طَهُورٌ إِنْ شَاءَ اللَّهُ',
    'رواه البخاري',
    'Al-Bukhari',
    'No harm — (it is) a purification, if Allah wills.',
  ),
  Dua(
    'visit_sick7',
    DuaCat.sickness,
    'للمريض (سبع مرات)',
    'For a sick person (7 times)',
    'أَسْأَلُ اللَّهَ الْعَظِيمَ، رَبَّ الْعَرْشِ الْعَظِيمِ، أَنْ يَشْفِيَكَ',
    'رواه أبو داود والترمذي',
    'Abu Dawud, al-Tirmidhi',
    'I ask Allah the Mighty, Lord of the Mighty Throne, to cure you.',
    repeat: 7,
  ),
  Dua(
    'ruqya',
    DuaCat.sickness,
    'رقية المريض',
    'Supplication over a sick person',
    'اللَّهُمَّ رَبَّ النَّاسِ، أَذْهِبِ الْبَاسَ، اشْفِهِ وَأَنْتَ الشَّافِي، لَا شِفَاءَ إِلَّا شِفَاؤُكَ، شِفَاءً لَا يُغَادِرُ سَقَمًا',
    'رواه البخاري ومسلم',
    'Al-Bukhari, Muslim',
    'O Allah, Lord of mankind, remove the harm and heal him; You are the Healer. There is no healing but Your healing — a healing that leaves no illness behind.',
  ),
  Dua(
    'own_pain',
    DuaCat.sickness,
    'لمن يجد ألمًا: يضع يده على موضع الألم ويقول «بسم الله» ثلاثًا، ثم سبع مرات:',
    'For your own pain: place your hand on it, say "Bismillah" 3 times, then 7 times:',
    'أَعُوذُ بِاللَّهِ وَقُدْرَتِهِ مِنْ شَرِّ مَا أَجِدُ وَأُحَاذِرُ',
    'رواه مسلم',
    'Muslim',
    'I seek refuge in Allah and His power from the evil of what I feel and what I fear.',
    repeat: 7,
  ),
  // ── المطر ──
  Dua(
    'rain',
    DuaCat.rain,
    'عند نزول المطر',
    'When it rains',
    'اللَّهُمَّ صَيِّبًا نَافِعًا',
    'رواه البخاري',
    'Al-Bukhari',
    'O Allah, (make it) a beneficial rain.',
  ),
  Dua(
    'after_rain',
    DuaCat.rain,
    'بعد نزول المطر',
    'After the rain',
    'مُطِرْنَا بِفَضْلِ اللَّهِ وَرَحْمَتِهِ',
    'رواه البخاري ومسلم',
    'Al-Bukhari, Muslim',
    'We have been given rain by the grace and mercy of Allah.',
  ),
  Dua(
    'heavy_rain',
    DuaCat.rain,
    'عند كثرة المطر والخوف من ضرره',
    'When rain is excessive and harmful',
    'اللَّهُمَّ حَوَالَيْنَا وَلَا عَلَيْنَا',
    'رواه البخاري ومسلم',
    'Al-Bukhari, Muslim',
    'O Allah, around us and not upon us.',
  ),
  // ── اللباس ──
  Dua(
    'wear',
    DuaCat.clothes,
    'عند لبس الثوب',
    'When putting on clothes',
    'الْحَمْدُ لِلَّهِ الَّذِي كَسَانِي هَذَا الثَّوْبَ وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
    'رواه أبو داود',
    'Abu Dawud',
    'Praise be to Allah who clothed me with this garment and provided it for me without any might or power on my part.',
  ),
  Dua(
    'new_clothes',
    DuaCat.clothes,
    'عند لبس ثوب جديد',
    'When wearing new clothes',
    'اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ كَسَوْتَنِيهِ، أَسْأَلُكَ مِنْ خَيْرِهِ وَخَيْرِ مَا صُنِعَ لَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّهِ وَشَرِّ مَا صُنِعَ لَهُ',
    'رواه أبو داود والترمذي',
    'Abu Dawud, al-Tirmidhi',
    'O Allah, praise is Yours; You clothed me with it. I ask You for its good and the good it was made for, and seek refuge in You from its evil and the evil it was made for.',
  ),
  // ── الخلاء ──
  Dua(
    'enter_toilet',
    DuaCat.toilet,
    'عند دخول الخلاء',
    'Before entering the toilet',
    'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْخُبُثِ وَالْخَبَائِثِ',
    'رواه البخاري ومسلم',
    'Al-Bukhari, Muslim',
    'O Allah, I seek refuge in You from male and female devils (all evil and evil ones).',
  ),
  Dua(
    'leave_toilet',
    DuaCat.toilet,
    'عند الخروج من الخلاء',
    'When leaving the toilet',
    'غُفْرَانَكَ',
    'رواه أبو داود والترمذي',
    'Abu Dawud, al-Tirmidhi',
    '(I ask) Your forgiveness.',
  ),
  // ── الوضوء ──
  Dua(
    'after_wudu',
    DuaCat.wudu,
    'بعد الفراغ من الوضوء',
    'After completing wudu',
    'أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
    'رواه مسلم',
    'Muslim',
    'I bear witness that there is no god but Allah alone, without partner, and I bear witness that Muhammad is His servant and Messenger.',
  ),
  Dua(
    'after_wudu2',
    DuaCat.wudu,
    'زيادة بعد الشهادتين',
    'Addition after the testimony',
    'اللَّهُمَّ اجْعَلْنِي مِنَ التَّوَّابِينَ، وَاجْعَلْنِي مِنَ الْمُتَطَهِّرِينَ',
    'رواه الترمذي',
    'Al-Tirmidhi',
    'O Allah, make me among those who repent often and among those who purify themselves.',
  ),
  // ── للوالدين ──
  Dua(
    'parents1',
    DuaCat.parents,
    'دعاء للوالدين من القرآن',
    'For parents, from the Qur\'an',
    'رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
    'سورة الإسراء: 24',
    'Qur\'an, Al-Isra 17:24',
    'My Lord, have mercy on them both as they raised me when I was small.',
    quran: true,
  ),
  Dua(
    'parents2',
    DuaCat.parents,
    'دعاء إبراهيم عليه السلام',
    'The supplication of Ibrahim (Abraham)',
    'رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ',
    'سورة إبراهيم: 41',
    'Qur\'an, Ibrahim 14:41',
    'Our Lord, forgive me, my parents and the believers on the Day the reckoning is established.',
    quran: true,
  ),
  Dua(
    'parents3',
    DuaCat.parents,
    'دعاء نوح عليه السلام',
    'The supplication of Nuh (Noah)',
    'رَّبِّ اغْفِرْ لِي وَلِوَالِدَيَّ وَلِمَن دَخَلَ بَيْتِيَ مُؤْمِنًا وَلِلْمُؤْمِنِينَ وَالْمُؤْمِنَاتِ',
    'سورة نوح: 28',
    'Qur\'an, Nuh 71:28',
    'My Lord, forgive me, my parents, whoever enters my house as a believer, and the believing men and women.',
    quran: true,
  ),
  // ── الاستغفار ──
  Dua(
    'sayyid_istighfar',
    DuaCat.forgiveness,
    'سيّد الاستغفار',
    'The master supplication for forgiveness',
    'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
    'رواه البخاري',
    'Al-Bukhari',
    'O Allah, You are my Lord; there is no god but You. You created me and I am Your servant, keeping Your covenant and promise as best I can. I seek refuge in You from the evil I have done. I acknowledge Your favour upon me and I acknowledge my sin, so forgive me, for none forgives sins but You.',
  ),
  Dua(
    'adam',
    DuaCat.forgiveness,
    'دعاء آدم وحواء عليهما السلام',
    'The supplication of Adam and Hawwa',
    'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
    'سورة الأعراف: 23',
    'Qur\'an, Al-A\'raf 7:23',
    'Our Lord, we have wronged ourselves; if You do not forgive us and have mercy on us, we will surely be among the losers.',
    quran: true,
  ),
  Dua(
    'abrar',
    DuaCat.forgiveness,
    'من دعاء أولي الألباب',
    'From the supplication of the people of understanding',
    'رَبَّنَا فَاغْفِرْ لَنَا ذُنُوبَنَا وَكَفِّرْ عَنَّا سَيِّئَاتِنَا وَتَوَفَّنَا مَعَ الْأَبْرَارِ',
    'سورة آل عمران: 193',
    'Qur\'an, Al Imran 3:193',
    'Our Lord, forgive us our sins, remove from us our misdeeds, and take us (in death) with the righteous.',
    quran: true,
  ),
  Dua(
    'rahimin',
    DuaCat.forgiveness,
    'دعاء قرآني',
    'A Qur\'anic supplication',
    'رَّبِّ اغْفِرْ وَارْحَمْ وَأَنتَ خَيْرُ الرَّاحِمِينَ',
    'سورة المؤمنون: 118',
    'Qur\'an, Al-Mu\'minun 23:118',
    'My Lord, forgive and have mercy, for You are the best of the merciful.',
    quran: true,
  ),
];
