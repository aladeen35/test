/// بيانات ثابتة: مدن السودان، العملات، الأمثال السودانية
library;

import 'i18n.dart';

class City {
  final String id, ar, stateAr, en, stateEn;
  final double lat, lng;

  /// رمز الدولة (ISO) والمنطقة الزمنية (IANA)
  final String country, tz;
  const City(this.id, this.ar, this.stateAr, this.lat, this.lng, this.en, this.stateEn, {this.country = 'SD', this.tz = 'Africa/Khartoum'});

  /// مكان من البحث العالمي أو الـ GPS (اسم واحد بلغة البحث)
  const City.place(this.id, String name, String region, this.lat, this.lng, {required this.country, required this.tz})
      : ar = name,
        en = name,
        stateAr = region,
        stateEn = region;

  String get name => isEn ? en : ar;
  String get state => isEn ? stateEn : stateAr;
  bool get inSudan => country == 'SD';

  Map<String, dynamic> toJson() => {'id': id, 'n': ar, 'r': stateAr, 'lat': lat, 'lng': lng, 'c': country, 'tz': tz};
  static City fromJson(Map j) =>
      City.place(j['id'], j['n'], j['r'] ?? '', (j['lat'] as num).toDouble(), (j['lng'] as num).toDouble(), country: j['c'] ?? '', tz: j['tz'] ?? '');
}

/// علم الدولة من رمزها (SD ← 🇸🇩)
String flagOf(String code) => code.length != 2
    ? '🌍'
    : String.fromCharCodes(code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 65));

/// عواصم الولايات والمدن الرئيسية (إحداثيات تقريبية)
const cities = [
  City('khartoum', 'الخرطوم', 'الخرطوم', 15.5007, 32.5599, 'Khartoum', 'Khartoum'),
  City('omdurman', 'أم درمان', 'الخرطوم', 15.6445, 32.4777, 'Omdurman', 'Khartoum'),
  City('bahri', 'الخرطوم بحري', 'الخرطوم', 15.6333, 32.5333, 'Khartoum North', 'Khartoum'),
  City('portsudan', 'بورتسودان', 'البحر الأحمر', 19.6158, 37.2164, 'Port Sudan', 'Red Sea'),
  City('suakin', 'سواكن', 'البحر الأحمر', 19.1059, 37.3321, 'Suakin', 'Red Sea'),
  City('kassala', 'كسلا', 'كسلا', 15.4510, 36.4000, 'Kassala', 'Kassala'),
  City('gedaref', 'القضارف', 'القضارف', 14.0350, 35.3833, 'Gedaref', 'Gedaref'),
  City('madani', 'ود مدني', 'الجزيرة', 14.4012, 33.5199, 'Wad Madani', 'Gezira'),
  City('managil', 'المناقل', 'الجزيرة', 14.2500, 32.9833, 'Al-Managil', 'Gezira'),
  City('sennar', 'سنار', 'سنار', 13.5500, 33.6000, 'Sennar', 'Sennar'),
  City('singa', 'سنجة', 'سنار', 13.1500, 33.9333, 'Singa', 'Sennar'),
  City('damazin', 'الدمازين', 'النيل الأزرق', 11.7891, 34.3592, 'Ad-Damazin', 'Blue Nile'),
  City('kosti', 'كوستي', 'النيل الأبيض', 13.1629, 32.6635, 'Kosti', 'White Nile'),
  City('rabak', 'ربك', 'النيل الأبيض', 13.1800, 32.7400, 'Rabak', 'White Nile'),
  City('dueim', 'الدويم', 'النيل الأبيض', 13.9956, 32.3110, 'Ad-Douiem', 'White Nile'),
  City('atbara', 'عطبرة', 'نهر النيل', 17.7022, 33.9864, 'Atbara', 'River Nile'),
  City('damer', 'الدامر', 'نهر النيل', 17.5928, 33.9592, 'Ad-Damer', 'River Nile'),
  City('shendi', 'شندي', 'نهر النيل', 16.6917, 33.4333, 'Shendi', 'River Nile'),
  City('berber', 'بربر', 'نهر النيل', 18.0167, 33.9833, 'Berber', 'River Nile'),
  City('dongola', 'دنقلا', 'الشمالية', 19.1833, 30.4833, 'Dongola', 'Northern'),
  City('merowe', 'مروي', 'الشمالية', 18.4800, 31.8200, 'Merowe', 'Northern'),
  City('karima', 'كريمة', 'الشمالية', 18.5500, 31.8500, 'Karima', 'Northern'),
  City('halfa', 'وادي حلفا', 'الشمالية', 21.8000, 31.3500, 'Wadi Halfa', 'Northern'),
  City('obeid', 'الأبيض', 'شمال كردفان', 13.1833, 30.2167, 'El Obeid', 'North Kordofan'),
  City('kadugli', 'كادقلي', 'جنوب كردفان', 11.0167, 29.7167, 'Kadugli', 'South Kordofan'),
  City('fula', 'الفولة', 'غرب كردفان', 11.7300, 28.3300, 'Al-Fula', 'West Kordofan'),
  City('babanusa', 'بابنوسة', 'غرب كردفان', 11.3333, 27.8167, 'Babanusa', 'West Kordofan'),
  City('fasher', 'الفاشر', 'شمال دارفور', 13.6279, 25.3494, 'El Fasher', 'North Darfur'),
  City('nyala', 'نيالا', 'جنوب دارفور', 12.0500, 24.8833, 'Nyala', 'South Darfur'),
  City('geneina', 'الجنينة', 'غرب دارفور', 13.4500, 22.4500, 'El Geneina', 'West Darfur'),
  City('zalingei', 'زالنجي', 'وسط دارفور', 12.9000, 23.4833, 'Zalingei', 'Central Darfur'),
  City('daein', 'الضعين', 'شرق دارفور', 11.4600, 26.1300, 'Ed Daein', 'East Darfur'),
];

City cityById(String id) => cities.firstWhere((c) => c.id == id, orElse: () => cities.first);

class Currency {
  final String code, ar, sym, flag, en;
  const Currency(this.code, this.ar, this.sym, this.flag, this.en);
  String get name => isEn ? en : ar;
}

const currencies = [
  Currency('SDG', 'جنيه سوداني', 'ج.س', '🇸🇩', 'Sudanese Pound'),
  Currency('USD', 'دولار أمريكي', '\$', '🇺🇸', 'US Dollar'),
  Currency('SAR', 'ريال سعودي', 'ر.س', '🇸🇦', 'Saudi Riyal'),
  Currency('AED', 'درهم إماراتي', 'د.إ', '🇦🇪', 'UAE Dirham'),
  Currency('QAR', 'ريال قطري', 'ر.ق', '🇶🇦', 'Qatari Riyal'),
  Currency('KWD', 'دينار كويتي', 'د.ك', '🇰🇼', 'Kuwaiti Dinar'),
  Currency('OMR', 'ريال عماني', 'ر.ع', '🇴🇲', 'Omani Rial'),
  Currency('BHD', 'دينار بحريني', 'د.ب', '🇧🇭', 'Bahraini Dinar'),
  Currency('EGP', 'جنيه مصري', 'ج.م', '🇪🇬', 'Egyptian Pound'),
  Currency('EUR', 'يورو', '€', '🇪🇺', 'Euro'),
  Currency('GBP', 'جنيه إسترليني', '£', '🇬🇧', 'British Pound'),
  Currency('TRY', 'ليرة تركية', '₺', '🇹🇷', 'Turkish Lira'),
  Currency('ETB', 'بر إثيوبي', 'Br', '🇪🇹', 'Ethiopian Birr'),
  Currency('UGX', 'شلن أوغندي', 'USh', '🇺🇬', 'Ugandan Shilling'),
  Currency('SSP', 'جنيه جنوب سوداني', 'SSP', '🇸🇸', 'South Sudanese Pound'),
  Currency('LYD', 'دينار ليبي', 'ل.د', '🇱🇾', 'Libyan Dinar'),
  Currency('CNY', 'يوان صيني', '¥', '🇨🇳', 'Chinese Yuan'),
];

Currency currencyByCode(String c) => currencies.firstWhere((x) => x.code == c, orElse: () => currencies.first);

/// أسعار احتياطية تقريبية مقابل الدولار (تُستبدل تلقائيًا عند الاتصال)
const fallbackRates = <String, double>{
  'USD': 1, 'SDG': 600, 'SAR': 3.75, 'AED': 3.6725, 'QAR': 3.64, 'KWD': 0.307, 'OMR': 0.3845, 'BHD': 0.376,
  'EGP': 48.5, 'EUR': 0.92, 'GBP': 0.79, 'TRY': 34, 'ETB': 120, 'UGX': 3700, 'SSP': 1300, 'LYD': 4.8, 'CNY': 7.2,
};

/// أمثال سودانية — واحد يظهر كل يوم في الصفحة الرئيسية
const sudaneseProverbs = [
  ('إيد على إيد تجدع بعيد', 'التعاون يوصّلك لأبعد مكان', 'Hand in hand throws farther — together we go further.'),
  ('القلم ما بزيل بلم', 'التعليم وحده ما بيغيّر الطبع', 'Schooling alone does not cure foolishness.'),
  ('الفي البر عوّام', 'الكلام ساهل للبعيد من المشكلة', 'The one on the shore is a great swimmer — easy to talk from outside.'),
  ('الجار قبل الدار', 'اختار جارك قبل بيتك', 'Choose the neighbour before the house.'),
  ('أب سنينة يضحك على أب سنينتين', 'الزول بيعيب غيره وهو فيه نفس العيب', 'The one with one tooth laughs at the one with two.'),
  ('الصبر مفتاح الفرج', 'اصبر والفرج جاي', 'Patience is the key to relief.'),
  ('الما بتلحقو جدّعو', 'الحاجة الما بتقدر عليها خليها', "What you can't reach, let it go."),
  ('جدادة الخلا طردت جدادة البيت', 'الغريب ممكن يطلّع صاحب المكان', 'The wild hen chased out the house hen.'),
  ('الشينة منكورة', 'الغلط ما في زول بيعترف بيهو', 'Nobody owns up to a bad deed.'),
  ('دخلوها وصقيرها حام', 'خشّوا في الموضوع والخطر لسه حايم فوقهم', 'They walked into it while the danger was still hovering overhead.'),
  ('الرك على الله', 'التوكل على الله في كل حال', 'Reliance is on God.'),
  ('المال تلتو ولا كتلتو', 'تاخد جزء من حقك أحسن من تضيّعو كلو', 'A third of your money is better than losing it all.'),
];

/// عبارات التحية السودانية حسب الوقت
String sudaneseGreeting(int hour) {
  if (hour < 5) return t('سهران يا', 'ما زلت مستيقظًا يا', 'Still up,');
  if (hour < 12) return t('صباح الخير يا', 'صباح الخير يا', 'Good morning,');
  if (hour < 16) return t('نهارك سعيد يا', 'طاب نهارك يا', 'Good afternoon,');
  if (hour < 19) return t('العصرية الحلوة يا', 'مساء الخير يا', 'Good evening,');
  return t('مساء النور يا', 'مساء النور يا', 'Good evening,');
}
