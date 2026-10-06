/// بيانات وأدوات «مساعد الكاتب»: الأنواع، الأدوار، القوالب، الأسماء، الإلهام، والتخزين.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../life/life_common.dart';

export '../life/life_common.dart'
    show newId, dk, todayPlace, mapList, intOf, numOf, parseDk, dayDiff, confirmAsk, askText, lifeSheet, PickChip, LifeDateButton, palette, lifePalette, undoSnack;

final wRnd = math.Random();

/* ───────────── عناصر ثلاثية اللغة ───────────── */

/// عنصر بمفتاح وثلاث صيغ وإيموجي ولون
class WItem {
  final String key, emoji, sd, ar, en;
  final Color color;
  const WItem(this.key, this.emoji, this.sd, this.ar, this.en, [this.color = SD.purple]);
  String get name => t(sd, ar, en);
  String get label => '$emoji $name';
}

WItem wFind(List<WItem> l, String? k) => l.firstWhere((e) => e.key == k, orElse: () => l.first);

const wGenres = [
  WItem('novel', '📚', 'رواية', 'رواية', 'Novel', SD.coffee),
  WItem('short', '📝', 'قصة قصيرة', 'قصة قصيرة', 'Short story', SD.nile),
  WItem('play', '🎭', 'مسرحية', 'مسرحية', 'Stage play', SD.henna),
  WItem('screen', '🎬', 'سيناريو', 'سيناريو', 'Screenplay', SD.indigo),
  WItem('poetry', '🪶', 'شعر', 'شعر', 'Poetry', SD.gold),
  WItem('folk', '🏺', 'حجوة / أحاجي', 'حكاية شعبية / أحاجي سودانية', 'Folk tale (Sudanese ahaji)', SD.orange),
  WItem('scifi', '🚀', 'خيال علمي', 'خيال علمي', 'Science fiction', SD.teal),
  WItem('fantasy', '🐉', 'فانتازيا', 'فانتازيا', 'Fantasy', SD.purple),
  WItem('horror', '👻', 'رعب', 'رعب', 'Horror', SD.red),
  WItem('romance', '💞', 'رومانسي', 'رومانسي', 'Romance', SD.pink),
  WItem('history', '🏛️', 'تاريخي', 'تاريخي', 'Historical', SD.brownLight),
  WItem('kids', '🧸', 'أطفال', 'أدب أطفال', 'Children', SD.green),
];

const wProjStatus = [
  WItem('idea', '💡', 'فكرة', 'فكرة', 'Idea', SD.gold),
  WItem('draft', '✍️', 'بكتب فيها', 'قيد الكتابة', 'Drafting', SD.nile),
  WItem('revise', '🔍', 'مراجعة', 'مراجعة', 'Revising', SD.orange),
  WItem('done', '✅', 'خلصت', 'مكتملة', 'Finished', SD.green),
  WItem('paused', '⏸️', 'واقفة', 'متوقفة', 'Paused', SD.brownLight),
];

const wSceneStatus = [
  WItem('idea', '💡', 'فكرة', 'فكرة', 'Idea', SD.gold),
  WItem('draft', '✍️', 'مسودة', 'مسودة', 'Draft', SD.nile),
  WItem('review', '🔍', 'مراجعة', 'مراجعة', 'Review', SD.orange),
  WItem('ready', '✅', 'جاهز', 'جاهز', 'Ready', SD.green),
];

const wRoles = [
  WItem('hero', '🦸', 'بطل', 'بطل', 'Protagonist', SD.green),
  WItem('villain', '😈', 'خصم', 'خصم', 'Antagonist', SD.red),
  WItem('sidekick', '🤝', 'مساعد', 'مساعد', 'Sidekick', SD.nile),
  WItem('mentor', '🧓', 'مرشد', 'مرشد', 'Mentor', SD.gold),
  WItem('love', '💗', 'محبوب', 'المحبوب', 'Love interest', SD.pink),
  WItem('minor', '👤', 'ثانوي', 'ثانوي', 'Minor', SD.brownLight),
  WItem('custom', '✏️', 'غيرو', 'دور آخر', 'Other', SD.indigo),
];

const wRelTypes = [
  WItem('family', '👪', 'أهل', 'عائلة', 'Family', SD.coffee),
  WItem('friend', '🤝', 'صاحب', 'صداقة', 'Friend', SD.green),
  WItem('enemy', '⚔️', 'عدو', 'عداوة', 'Enemy', SD.red),
  WItem('love', '❤️', 'حب', 'حب', 'Love', SD.pink),
  WItem('mentor', '🎓', 'مرشد', 'إرشاد', 'Mentor', SD.gold),
];

const wNoteKinds = [
  WItem('place', '📍', 'أماكن', 'أماكن', 'Places', SD.nile),
  WItem('item', '🗝️', 'أغراض', 'أغراض', 'Items', SD.gold),
  WItem('lore', '📜', 'تاريخ وأساطير', 'أساطير وتاريخ', 'Lore', SD.purple),
  WItem('research', '🔎', 'بحث', 'بحث', 'Research', SD.teal),
];

const wEmojis = ['📖', '🌙', '🌴', '🐪', '🌊', '🏜️', '🔥', '🗝️', '🕌', '🚂', '🌧️', '⭐', '🦁', '🌹', '🧿', '🪐'];

/// صفات الشخصيات (عربي، إنجليزي)
const wTraits = [
  ('شجاع', 'Brave'), ('عنيد', 'Stubborn'), ('كريم', 'Generous'), ('خجول', 'Shy'), ('ذكي', 'Clever'), ('طمّاع', 'Greedy'),
  ('وفيّ', 'Loyal'), ('غيور', 'Jealous'), ('حنون', 'Tender'), ('متهوّر', 'Reckless'), ('صبور', 'Patient'), ('كذّاب', 'Deceitful'),
  ('فضولي', 'Curious'), ('متكبّر', 'Arrogant'), ('ظريف', 'Witty'), ('متشائم', 'Pessimistic'), ('متفائل', 'Optimistic'), ('غامض', 'Mysterious'),
  ('طموح', 'Ambitious'), ('كسول', 'Lazy'), ('حكيم', 'Wise'), ('عصبي', 'Hot-tempered'), ('رحيم', 'Merciful'), ('مخادع', 'Cunning'),
  ('حالم', 'Dreamy'), ('عملي', 'Practical'), ('منعزل', 'Loner'), ('اجتماعي', 'Sociable'), ('قلق', 'Anxious'), ('أمين', 'Honest'),
  ('مضحّي', 'Self-sacrificing'), ('حقود', 'Vengeful'),
];

/// أسماء سودانية/عربية (عربي، إنجليزي)
const wNamesSdM = [
  ('محمد', 'Mohamed'), ('أحمد', 'Ahmed'), ('عثمان', 'Osman'), ('الطيب', 'Eltayeb'), ('حمدان', 'Hamdan'), ('عبد الرحيم', 'Abdelrahim'),
  ('مصطفى', 'Mustafa'), ('إدريس', 'Idris'), ('بابكر', 'Babiker'), ('الأمين', 'Elamin'), ('صلاح', 'Salah'), ('عوض', 'Awad'),
  ('حسن', 'Hassan'), ('الزبير', 'Elzubair'), ('علي', 'Ali'), ('عمر', 'Omar'), ('يوسف', 'Yousif'), ('خالد', 'Khalid'),
  ('المك', 'Elmak'), ('حامد', 'Hamid'), ('سليمان', 'Suleiman'), ('النور', 'Elnour'), ('الفاتح', 'Elfatih'), ('مجذوب', 'Majzoub'),
];
const wNamesSdF = [
  ('فاطمة', 'Fatima'), ('آمنة', 'Amna'), ('عائشة', 'Aisha'), ('مريم', 'Mariam'), ('نفيسة', 'Nafisa'), ('حواء', 'Hawa'),
  ('زينب', 'Zainab'), ('سعاد', 'Suad'), ('بخيتة', 'Bakhita'), ('التاية', 'Eltaya'), ('ستنا', 'Sitana'), ('رقية', 'Rugaya'),
  ('هدى', 'Huda'), ('مهيرة', 'Mahira'), ('عازة', 'Azza'), ('نعمات', 'Neamat'), ('إخلاص', 'Ikhlas'), ('سلمى', 'Salma'),
  ('نور', 'Nour'), ('أسماء', 'Asma'), ('حليمة', 'Halima'), ('الشول', 'Elshol'), ('سارة', 'Sara'), ('ملاذ', 'Malaz'),
];
const wNamesEnM = ['James', 'Oliver', 'Henry', 'Samuel', 'Thomas', 'Daniel', 'Arthur', 'Leo', 'Edward', 'Jack', 'Noah', 'Felix', 'Isaac', 'George', 'Owen', 'Caleb'];
const wNamesEnF = ['Emma', 'Grace', 'Alice', 'Clara', 'Lucy', 'Hannah', 'Ivy', 'Rose', 'Ella', 'Matilda', 'Nora', 'Violet', 'Hazel', 'Ruth', 'Sophie', 'Iris'];
const wSurnamesEn = ['Smith', 'Turner', 'Hughes', 'Walker', 'Bennett', 'Carter', 'Hayes', 'Brooks', 'Fletcher', 'Morgan', 'Reed', 'Shaw', 'Ward', 'Foster', 'Blake', 'Price'];

T wPick<T>(List<T> l) => l[wRnd.nextInt(l.length)];

/// يولّد اسمًا: سوداني (اسم + الأب + الجد) أو إنجليزي
String genName({required bool sudanese, required bool female}) {
  if (!sudanese) return '${wPick(female ? wNamesEnF : wNamesEnM)} ${wPick(wSurnamesEn)}';
  final first = wPick(female ? wNamesSdF : wNamesSdM);
  var f = wPick(wNamesSdM), g = wPick(wNamesSdM);
  while (f == first) {
    f = wPick(wNamesSdM);
  }
  while (g == f) {
    g = wPick(wNamesSdM);
  }
  return isEn ? '${first.$2} ${f.$2} ${g.$2}' : '${first.$1} ${f.$1} ${g.$1}';
}

List<String> randomTraits([int n = 3]) {
  final l = [...wTraits]..shuffle(wRnd);
  return [for (final x in l.take(n)) tr(x.$1, x.$2)];
}

/* ───────────── قوالب الحبكة ───────────── */

class WBeat {
  final String ar, en, dAr, dEn;
  const WBeat(this.ar, this.en, this.dAr, this.dEn);
  String get name => tr(ar, en);
  String get desc => tr(dAr, dEn);
}

class WTemplate {
  final String key, emoji, ar, en;
  final List<WBeat> beats;
  const WTemplate(this.key, this.emoji, this.ar, this.en, this.beats);
  String get name => tr(ar, en);
}

const wTemplates = [
  WTemplate('three', '🎬', 'البناء ثلاثي الفصول', 'Three-act structure', [
    WBeat('التمهيد', 'Setup', 'عالم البطل الطبيعي وما ينقصه', "The hero's normal world and what is missing"),
    WBeat('الحدث المحرّك', 'Inciting incident', 'حدث يقلب الحياة العادية', 'An event that disrupts ordinary life'),
    WBeat('نقطة التحوّل الأولى', 'Plot point 1', 'البطل يلتزم بالرحلة — نهاية الفصل الأول', 'The hero commits — end of Act I'),
    WBeat('تصاعد الأحداث', 'Rising action', 'عقبات وتعقيدات متزايدة', 'Obstacles and growing complications'),
    WBeat('منتصف القصة', 'Midpoint', 'كشف أو انقلاب يغيّر الاتجاه', 'A revelation or reversal that shifts direction'),
    WBeat('نقطة التحوّل الثانية', 'Plot point 2', 'أدنى نقطة — نهاية الفصل الثاني', 'The low point — end of Act II'),
    WBeat('الذروة', 'Climax', 'المواجهة الحاسمة', 'The decisive confrontation'),
    WBeat('الحل', 'Resolution', 'العالم الجديد بعد التغيير', 'The new normal after the change'),
  ]),
  WTemplate('hero', '🗡️', 'رحلة البطل (12 مرحلة)', "Hero's Journey (12 stages)", [
    WBeat('العالم العادي', 'Ordinary world', 'حياة البطل قبل المغامرة', "The hero's life before the adventure"),
    WBeat('نداء المغامرة', 'Call to adventure', 'مشكلة أو تحدٍّ يظهر', 'A problem or challenge appears'),
    WBeat('رفض النداء', 'Refusal of the call', 'تردد وخوف', 'Hesitation and fear'),
    WBeat('لقاء المرشد', 'Meeting the mentor', 'من يمنحه النصيحة أو الأداة', 'Someone gives advice or a gift'),
    WBeat('عبور العتبة الأولى', 'Crossing the threshold', 'الدخول إلى العالم الجديد', 'Entering the special world'),
    WBeat('الاختبارات والحلفاء والأعداء', 'Tests, allies, enemies', 'يتعلم قواعد العالم الجديد', 'Learning the rules of the new world'),
    WBeat('الاقتراب من الكهف العميق', 'Approach to the inmost cave', 'الاستعداد للخطر الأكبر', 'Preparing for the greatest danger'),
    WBeat('المحنة', 'The ordeal', 'مواجهة الموت أو أكبر خوف', 'Facing death or the deepest fear'),
    WBeat('المكافأة', 'Reward', 'الحصول على الكنز أو المعرفة', 'Seizing the treasure or knowledge'),
    WBeat('طريق العودة', 'The road back', 'المطاردة أو العواقب', 'The chase or the consequences'),
    WBeat('البعث', 'Resurrection', 'اختبار أخير يطهّر البطل', 'A final test that transforms the hero'),
    WBeat('العودة بالإكسير', 'Return with the elixir', 'يعود متغيّرًا بما ينفع الناس', 'Returning changed, with something to share'),
  ]),
  WTemplate('cat', '🐱', 'أنقذ القطة (15 محطة)', 'Save the Cat (15 beats)', [
    WBeat('الصورة الافتتاحية', 'Opening image', 'لقطة تلخّص البداية', 'A snapshot of the starting point'),
    WBeat('طرح الفكرة', 'Theme stated', 'أحدهم يلمّح إلى درس القصة', 'Someone hints at the lesson'),
    WBeat('التمهيد', 'Set-up', 'البطل وعالمه وعيوبه', 'The hero, their world and flaws'),
    WBeat('المحفّز', 'Catalyst', 'الحدث الذي يغيّر كل شيء', 'The event that changes everything'),
    WBeat('التردد', 'Debate', 'هل يذهب أم لا؟', 'Should they go or not?'),
    WBeat('الدخول للفصل الثاني', 'Break into Two', 'قرار ودخول عالم جديد', 'A choice and a new world'),
    WBeat('القصة الفرعية', 'B Story', 'علاقة تحمل الفكرة', 'A relationship that carries the theme'),
    WBeat('المرح والألعاب', 'Fun and Games', 'وعد الفكرة الأساسية', 'The promise of the premise'),
    WBeat('المنتصف', 'Midpoint', 'نصر زائف أو هزيمة زائفة', 'A false victory or false defeat'),
    WBeat('الأشرار يقتربون', 'Bad Guys Close In', 'الضغط يزداد من الخارج والداخل', 'Pressure builds inside and out'),
    WBeat('ضاع كل شيء', 'All Is Lost', 'أسوأ لحظة', 'The worst moment'),
    WBeat('ليلة الروح المظلمة', 'Dark Night of the Soul', 'اليأس قبل الفهم', 'Despair before insight'),
    WBeat('الدخول للفصل الثالث', 'Break into Three', 'الحل يتضح', 'The solution becomes clear'),
    WBeat('الخاتمة', 'Finale', 'تنفيذ الخطة والتغيّر', 'Executing the plan and changing'),
    WBeat('الصورة الختامية', 'Final image', 'عكس الصورة الافتتاحية', 'Mirror of the opening image'),
  ]),
  WTemplate('kish', '🎋', 'كيشوتنكيتسو (4 أجزاء)', 'Kishōtenketsu (4 parts)', [
    WBeat('كي — التقديم', 'Ki — introduction', 'تعريف الشخصيات والمكان', 'Introduce characters and setting'),
    WBeat('شو — التطوير', 'Shō — development', 'تعميق ما قُدّم دون صراع كبير', 'Develop without major conflict'),
    WBeat('تن — المفاجأة', 'Ten — twist', 'عنصر غير متوقع يغيّر النظرة', 'An unexpected turn reframes things'),
    WBeat('كيتسو — الخلاصة', 'Ketsu — conclusion', 'التوفيق بين ما سبق والمفاجأة', 'Reconcile the twist with what came before'),
  ]),
  WTemplate('freytag', '🔺', 'هرم فريتاغ (5 مراحل)', "Freytag's pyramid (5)", [
    WBeat('العرض', 'Exposition', 'الخلفية والشخصيات', 'Background and characters'),
    WBeat('الحدث الصاعد', 'Rising action', 'تصاعد الصراع', 'The conflict builds'),
    WBeat('الذروة', 'Climax', 'نقطة التحوّل الكبرى', 'The turning point'),
    WBeat('الحدث الهابط', 'Falling action', 'نتائج الذروة', 'Consequences unfold'),
    WBeat('الانفراج / الخاتمة', 'Dénouement', 'حل العقدة والنهاية', 'Resolution and ending'),
  ]),
];

WTemplate? wTemplate(String? k) {
  for (final x in wTemplates) {
    if (x.key == k) return x;
  }
  return null;
}

/* ───────────── الإلهام ───────────── */

/// محفّزات الكتابة (سوداني، فصحى، إنجليزي)
const wPrompts = [
  ('ست شاي على شاطئ النيل بتسمع كل يوم أسرار الزباين… لحدي ما سمعت سر بخصها هي.', 'بائعة شاي على ضفة النيل تسمع كل يوم أسرار الزبائن… حتى سمعت سرًا يخصها هي.', 'A tea seller on the Nile bank hears customers\' secrets daily… until one secret is about her.'),
  ('في سوق أم درمان، تاجر قديم بيبيع حاجة ما معروف أصلها، وكل من اشتراها رجع تاني.', 'في سوق أم درمان، تاجر عجوز يبيع شيئًا مجهول الأصل، وكل من اشتراه عاد إليه.', 'In Omdurman souq an old merchant sells an object of unknown origin; everyone who buys it comes back.'),
  ('الحلّة كلها نامت بدري الليلة، إلا بيت واحد نورو ما انطفى.', 'نام الحيّ كله مبكرًا الليلة، إلا بيتًا واحدًا لم تنطفئ أنواره.', 'The whole neighbourhood slept early tonight — except one house whose light never went out.'),
  ('أول مطرة في الخريف جابت معاها زول غريب ما في زول بعرفو.', 'جاءت أول أمطار الخريف ومعها غريب لا يعرفه أحد.', 'The first rain of the rainy season brought a stranger no one recognises.'),
  ('الهبوب غطّى البلد ثلاثة أيام، ولما انكشف لقوا…', 'غطّت الهبوب البلدة ثلاثة أيام، وعندما انقشعت وجدوا…', 'A haboob covered the town for three days; when it cleared they found…'),
  ('ساعة الفطور في رمضان، الصينية فيها كرسي فاضي لزول مات من سنين.', 'عند الإفطار في رمضان، على المائدة مقعد فارغ لشخص مات منذ سنوات.', 'At Ramadan iftar, there is an empty seat for someone who died years ago.'),
  ('في ليلة الحنّة، العروس قالت كلام غيّر العرس كلو.', 'في ليلة الحنّة، قالت العروس كلامًا غيّر الزفاف كله.', 'On the henna night, the bride says something that changes the whole wedding.'),
  ('حبوبة بتحكي أحجية كل ليلة، والليلة الأحجية بقت حقيقية.', 'جدة تحكي أحجية كل ليلة، والليلة صارت الأحجية حقيقة.', 'A grandmother tells a folk tale every night; tonight the tale comes true.'),
  ('قطر حلفا اتأخر يوم كامل في الصحراء، والركاب بدوا يحكوا.', 'تأخر قطار وادي حلفا يومًا كاملًا في الصحراء، فبدأ الركاب يحكون.', 'The Wadi Halfa train stalls a whole day in the desert, and the passengers start telling stories.'),
  ('صياد في المقرن طلّع من الموية صندوق مقفول بقفل نحاس.', 'صياد عند المقرن يُخرج من الماء صندوقًا مغلقًا بقفل نحاسي.', 'A fisherman at the confluence pulls up a box sealed with a brass lock.'),
  ('مغترب راجع بعد عشرين سنة، لقى بيتهم ساكنين فيهو ناس ما بعرفهم.', 'مغترب يعود بعد عشرين عامًا ليجد بيت أهله يسكنه غرباء.', 'An expat returns after twenty years to find strangers living in the family home.'),
  ('جواب قديم لقوه جوه مصحف في بيت الجد.', 'رسالة قديمة وُجدت داخل مصحف في بيت الجد.', 'An old letter is found inside a Qur\'an in grandfather\'s house.'),
  ('أهرامات البجراوية في الليل، والدليل السياحي اختفى.', 'أهرامات البجراوية ليلًا، والمرشد السياحي اختفى.', 'The Meroë pyramids at night — and the tour guide has vanished.'),
  ('سواق ركشة بوصّل نفس الراكبة كل يوم لمكان ما موجود في الخريطة.', 'سائق ركشة يوصل الراكبة نفسها كل يوم إلى مكان غير موجود على الخريطة.', 'A rickshaw driver takes the same passenger daily to a place not on any map.'),
  ('العيد جا، والبيت الكبير اتلمّ فيهو الأهل… ومعاهم سر قديم.', 'جاء العيد واجتمع الأهل في البيت الكبير… ومعهم سر قديم.', 'Eid arrives, the family gathers in the big house… carrying an old secret.'),
  ('شجرة النيم القدّام البيت بتتكلم، بس للشافع الصغير بس.', 'شجرة النيم أمام البيت تتكلم، لكن للطفل الصغير فقط.', 'The neem tree outside the house speaks — but only to the youngest child.'),
  ('مدرّسة في قرية بعيدة لقت في كراسة تلميذ رسومات لحاجات لسه ما حصلت.', 'معلمة في قرية نائية تجد في دفتر تلميذ رسومًا لأحداث لم تقع بعد.', 'A village teacher finds drawings in a pupil\'s notebook of things that haven\'t happened yet.'),
  ('الكهرباء قطعت في كل الخرطوم، إلا في بيت واحد.', 'انقطعت الكهرباء عن الخرطوم كلها، إلا عن بيت واحد.', 'Power is out across Khartoum — except in one house.'),
  ('راعي إبل في كردفان لقى أثر رجلين في الرملة ما بشبه أي مخلوق.', 'راعي إبل في كردفان يجد آثار أقدام في الرمل لا تشبه أي مخلوق.', 'A camel herder in Kordofan finds footprints that match no creature.'),
  ('سفينة في بورتسودان وصلت بدون ولا زول فيها.', 'سفينة تصل ميناء بورتسودان وليس على متنها أحد.', 'A ship docks in Port Sudan with no one aboard.'),
  ('اكتب عن آخر يوم في حياة مدينة.', 'اكتب عن آخر يوم في حياة مدينة.', 'Write about the last day in the life of a city.'),
  ('شخصين بيكرهوا بعض، اتحبسوا في أسانسير ساعتين.', 'شخصان يكره أحدهما الآخر يُحبسان في مصعد ساعتين.', 'Two people who hate each other are stuck in a lift for two hours.'),
  ('زول بصحى كل يوم في نفس اليوم، إلا إنو الناس حولو بتتغير.', 'شخص يستيقظ كل يوم في اليوم نفسه، لكن الناس من حوله يتغيرون.', 'Someone wakes into the same day again and again — but the people around them change.'),
  ('رسالة وصلت متأخرة خمسين سنة.', 'رسالة وصلت متأخرة خمسين عامًا.', 'A letter arrives fifty years late.'),
  ('روبوت بتعلّم الحزن من مراقبة البشر.', 'روبوت يتعلم الحزن من مراقبة البشر.', 'A robot learns grief by watching humans.'),
  ('مكتبة بتظهر بس في الليالي الما فيها قمر.', 'مكتبة لا تظهر إلا في الليالي التي بلا قمر.', 'A library that appears only on moonless nights.'),
  ('شافع لقى خريطة في جيب جلابية جدّو.', 'طفل يجد خريطة في جيب جلباب جده.', 'A child finds a map in the pocket of grandfather\'s jalabiya.'),
  ('آخر إنسان في الأرض سمع طرقة على الباب.', 'آخر إنسان على الأرض يسمع طرقًا على الباب.', 'The last person on Earth hears a knock on the door.'),
  ('اكتب مشهد بدون ولا كلمة حوار.', 'اكتب مشهدًا بلا أي حوار.', 'Write a scene with no dialogue at all.'),
  ('اكتب قصة كاملة في 100 كلمة بالضبط.', 'اكتب قصة كاملة في 100 كلمة بالضبط.', 'Write a complete story in exactly 100 words.'),
  ('بطلك لازم يختار بين الحقيقة وأمان أهلو.', 'على بطلك أن يختار بين الحقيقة وسلامة أهله.', 'Your hero must choose between the truth and the family\'s safety.'),
  ('ذكرى طفولة بتتضح إنها ما حصلت أصلًا.', 'ذكرى طفولة يتضح أنها لم تحدث أصلًا.', 'A childhood memory turns out never to have happened.'),
  ('مدينة فيها الكذب ممنوع بالقانون.', 'مدينة يحظر فيها القانون الكذب.', 'A city where lying is illegal.'),
  ('فنان بيرسم بورتريه، والصورة بتتغير كل يوم.', 'رسّام يرسم وجهًا، واللوحة تتغير كل يوم.', 'A painter\'s portrait changes a little every day.'),
  ('اكتب عن الريحة الأولى الافتكرتها من بيت أهلك.', 'اكتب عن أول رائحة تتذكرها من بيت أهلك.', 'Write about the first smell you remember from your family home.'),
  ('جواز السفر وقع، ومعاهو حياة كاملة ما بتاعتك.', 'سقط جواز سفر، ومعه حياة كاملة ليست لك.', 'You find a lost passport — and with it someone else\'s entire life.'),
  ('عرس في الحلّة والمغني ما جا، فاتلم الناس يحكوا.', 'عرس في الحي ولم يحضر المغني، فاجتمع الناس يحكون.', 'At a neighbourhood wedding the singer never shows, so guests tell stories instead.'),
  ('محطة فضاء فيها بس اتنين، وواحد فيهم ما بشرب الشاي.', 'محطة فضاء فيها شخصان فقط، وأحدهما يخفي شيئًا.', 'A space station with only two crew, and one of them is hiding something.'),
  ('بنت بتقرر تكتب جواب لنفسها بعد عشرة سنين.', 'فتاة تكتب رسالة إلى نفسها بعد عشر سنوات.', 'A girl writes a letter to herself ten years from now.'),
  ('حكاية فاطنة السمحة من وجهة نظر الغول.', 'حكاية فاطمة السمحة من وجهة نظر الغول.', 'Retell the folk tale of "Fatna the Beautiful" from the ogre\'s point of view.'),
];

/// مولّد «ماذا لو؟»: شخصية (عربي، إنجليزي، أنثى؟)
const wWhoList = [
  ('ست شاي', 'a tea seller', true), ('صياد في النيل', 'a Nile fisherman', false), ('سواق ركشة', 'a rickshaw driver', false),
  ('مدرّسة متقاعدة', 'a retired teacher', true), ('دكتورة صغيرة', 'a young doctor', true), ('تاجر في السوق', 'a market trader', false),
  ('حبوبة حكّاءة', 'a storytelling grandmother', true), ('مغترب راجع', 'a returning expat', false), ('راعي إبل', 'a camel herder', false),
  ('طالبة جامعة', 'a university student', true), ('عروس', 'a bride', true), ('شيخ خلوة', 'a Qur\'an school sheikh', false),
  ('صحفي', 'a journalist', false), ('مهندسة', 'an engineer', true), ('شافع يتيم', 'an orphan boy', false), ('فنانة تشكيلية', 'a painter', true),
];

/// المكان (عربي، إنجليزي)
const wWhereList = [
  ('على شاطئ النيل وقت الفجر', 'on the Nile bank at dawn'), ('في سوق أم درمان', 'in Omdurman souq'), ('في الحلّة أيام الخريف', 'in the neighbourhood during the rainy season'),
  ('وسط الهبوب', 'in the middle of a haboob'), ('قبل الإفطار في رمضان', 'just before iftar in Ramadan'), ('في ليلة عرس', 'on a wedding night'),
  ('في قطر حلفا', 'on the Wadi Halfa train'), ('عند أهرامات البجراوية', 'at the Meroë pyramids'), ('في ميناء بورتسودان', 'at Port Sudan harbour'),
  ('في مدينة بعيدة في الغربة', 'in a far city abroad'), ('في محطة فضاء', 'on a space station'), ('في قرية منسية', 'in a forgotten village'),
  ('في جزيرة توتي', 'on Tuti Island'), ('في مستشفى بالليل', 'in a hospital at night'),
];

/// الصراع (مذكر، مؤنث، إنجليزي)
const wConflictList = [
  ('لقى رسالة بتكشف سر العيلة', 'لقت رسالة بتكشف سر العيلة', 'finds a letter revealing a family secret'),
  ('فقد ذاكرتو فجأة', 'فقدت ذاكرتها فجأة', 'suddenly loses their memory'),
  ('لازم يختار بين حبيبتو وأهلو', 'لازم تختار بين حبيبها وأهلها', 'must choose between love and family'),
  ('بقى يسمع أفكار الناس', 'بقت تسمع أفكار الناس', 'starts hearing people\'s thoughts'),
  ('اتّهموه بجريمة ما عملها', 'اتّهموها بجريمة ما عملتها', 'is accused of a crime they did not commit'),
  ('ورث دين كبير من زول ما بعرفو', 'ورثت دين كبير من زول ما بتعرفو', 'inherits a huge debt from a stranger'),
  ('لقى طفل تايه', 'لقت طفل تايه', 'finds a lost child'),
  ('اكتشف إنو الزمن واقف إلا عندو', 'اكتشفت إنو الزمن واقف إلا عندها', 'discovers time has stopped for everyone else'),
  ('عندو يوم واحد يرجّع حاجة اتسرقت', 'عندها يوم واحد ترجّع حاجة اتسرقت', 'has one day to recover something stolen'),
  ('قابل نسخة تانية من نفسو', 'قابلت نسخة تانية من نفسها', 'meets another version of themselves'),
  ('لازم يكتم سر ممكن يدمّر الحلة', 'لازم تكتم سر ممكن يدمّر الحلة', 'must keep a secret that could destroy the community'),
  ('وعد زول بيموت بوعد صعب', 'وعدت زول بيموت بوعد صعب', 'made a hard promise to a dying person'),
];

/// يولّد فكرة «ماذا لو»
String genWhatIf() {
  final w = wPick(wWhoList), p = wPick(wWhereList), c = wPick(wConflictList);
  if (isEn) return 'What if ${w.$2}, ${p.$2}, ${c.$3}?';
  return t('شنو لو ${w.$1} ${p.$1} ${w.$3 ? c.$2 : c.$1}؟', 'ماذا لو أنّ ${w.$1} ${p.$1} ${w.$3 ? c.$2 : c.$1}؟', '');
}

/* ───────────── عدّ الكلمات ───────────── */

final _wordRe = RegExp(r'\S+');
int wordCount(String s) => _wordRe.allMatches(s).length;

/// دقائق القراءة (≈200 كلمة/دقيقة)
int readMinutes(int words) => words == 0 ? 0 : (words / 200).ceil();

/* ───────────── التخزين ───────────── */

/// يحوّل قائمة داخل خريطة إلى قائمة خرائط قابلة للتعديل ويعيد ربطها
List<Map<String, dynamic>> sub(Map<String, dynamic> m, String k) {
  final l = mapList(m[k]);
  m[k] = l;
  return l;
}

List<String> strList(dynamic v) => v is List ? [for (final e in v) '$e'] : <String>[];

class WStore {
  final AppState s;
  WStore(this.s);

  List<Map<String, dynamic>> get projects => mapList(s.getData<List>('writer_projects'));
  void saveProjects(List<Map<String, dynamic>> l) => s.setData('writer_projects', l);

  String? get currentId {
    final id = s.getData<String>('writer_current');
    final l = projects;
    if (l.isEmpty) return null;
    return l.any((p) => p['id'] == id) ? id : l.first['id'] as String?;
  }

  set currentId(String? id) => s.setData('writer_current', id);

  Map<String, dynamic>? get current {
    final id = currentId;
    if (id == null) return null;
    return projects.firstWhere((p) => p['id'] == id);
  }

  /// تعديل المشروع الحالي ثم الحفظ
  void edit(void Function(Map<String, dynamic> p) fn, {String? id}) {
    final l = projects;
    final pid = id ?? currentId;
    final i = l.indexWhere((p) => p['id'] == pid);
    if (i < 0) return;
    fn(l[i]);
    l[i]['upd'] = DateTime.now().millisecondsSinceEpoch;
    saveProjects(l);
  }

  void deleteProject(String id) {
    final l = projects;
    final p = l.firstWhere((x) => x['id'] == id, orElse: () => {});
    for (final sc in allScenes(p)) {
      s.setData('writer_txt_${sc['id']}', null);
    }
    l.removeWhere((x) => x['id'] == id);
    saveProjects(l);
  }

  String text(String sceneId) => s.getData<String>('writer_txt_$sceneId') ?? '';
  void setText(String sceneId, String v) => s.setData('writer_txt_$sceneId', v);

  /* الإحصائيات */
  Map<String, dynamic> get stats => Map<String, dynamic>.from(s.getData<Map>('writer_stats') ?? const {});
  int get dailyGoal => intOf(stats['goal'], 500);
  set dailyGoal(int v) => s.setData('writer_stats', {...stats, 'goal': v});
  Map<String, int> get days => {for (final e in ((stats['days'] as Map?) ?? const {}).entries) '${e.key}': intOf(e.value)};
  int wordsOn(DateTime d) => days[dk(d)] ?? 0;
  int get today => wordsOn(todayPlace());
  int get week {
    final n = todayPlace();
    var sum = 0;
    for (var i = 0; i < 7; i++) {
      sum += wordsOn(n.subtract(Duration(days: i)));
    }
    return sum;
  }

  int get streak {
    var d = todayPlace();
    if (wordsOn(d) == 0) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (wordsOn(d) > 0) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  /// تسجيل كلمات جديدة كُتبت (فرق موجب فقط)
  void addWords(int delta) {
    if (delta <= 0) return;
    final st = stats;
    final m = Map<String, dynamic>.from((st['days'] as Map?) ?? const {});
    final k = dk(todayPlace());
    final before = intOf(m[k]);
    m[k] = before + delta;
    // الاحتفاظ بآخر 120 يومًا فقط
    if (m.length > 120) {
      final keys = m.keys.toList()..sort();
      for (final old in keys.take(m.length - 120)) {
        m.remove(old);
      }
    }
    s.setData('writer_stats', {...st, 'days': m});
    s.bump('words_written', delta);
    s.awardDaily('writer_write', 5, t('كتبت في قصتك', 'الكتابة في قصتك', 'Wrote in your story'));
    final goal = dailyGoal;
    if (goal > 0 && before < goal && before + delta >= goal) {
      s.awardDaily('writer_goal', 20, t('حققت هدف الكتابة', 'تحقيق هدف الكتابة اليومي', 'Daily writing goal reached'));
      toast(t('🎉 حققت هدفك اليوم! ما شاء الله', '🎉 حققت هدف اليوم!', '🎉 Daily goal reached!'));
    }
  }
}

/* ───────────── مساعدات المشروع ───────────── */

List<Map<String, dynamic>> chaptersOf(Map<String, dynamic>? p) => p == null ? [] : mapList(p['chapters']);
List<Map<String, dynamic>> charsOf(Map<String, dynamic>? p) => p == null ? [] : mapList(p['chars']);
List<Map<String, dynamic>> notesOf(Map<String, dynamic>? p) => p == null ? [] : mapList(p['notes']);
List<Map<String, dynamic>> beatsOf(Map<String, dynamic>? p) => p == null ? [] : mapList(p['beats']);

List<Map<String, dynamic>> allScenes(Map<String, dynamic>? p) => [for (final c in chaptersOf(p)) ...mapList(c['scenes'])];

int projectWords(Map<String, dynamic>? p) => allScenes(p).fold(0, (a, b) => a + intOf(b['wc']));

String charName(Map<String, dynamic>? p, String? id) {
  if (id == null) return '';
  for (final c in charsOf(p)) {
    if (c['id'] == id) return '${c['name'] ?? ''}';
  }
  return '';
}

String roleName(Map c) {
  if (c['role'] == 'custom' && '${c['roleC'] ?? ''}'.trim().isNotEmpty) return '${c['roleC']}';
  return wFind(wRoles, c['role']).name;
}

/* ───────────── التصدير ───────────── */

String compileManuscript(WStore st, Map<String, dynamic> p, {required bool markdown}) {
  final b = StringBuffer();
  final title = '${p['title'] ?? ''}';
  b.writeln(markdown ? '# $title' : title.toUpperCase());
  if (!markdown) b.writeln('=' * math.min(40, math.max(title.length, 8)));
  final log = '${p['logline'] ?? ''}'.trim();
  if (log.isNotEmpty) b.writeln(markdown ? '\n> $log' : '\n$log');
  b.writeln();
  final chs = chaptersOf(p);
  for (var i = 0; i < chs.length; i++) {
    final ch = chs[i];
    final ct = '${ch['title'] ?? ''}'.trim();
    final head = '${tr('الفصل', 'Chapter')} ${i + 1}${ct.isEmpty ? '' : ': $ct'}';
    b.writeln(markdown ? '\n## $head\n' : '\n$head\n${'-' * math.min(30, head.length)}\n');
    final scs = mapList(ch['scenes']);
    for (var j = 0; j < scs.length; j++) {
      final sc = scs[j];
      if (markdown && '${sc['title'] ?? ''}'.trim().isNotEmpty) b.writeln('### ${sc['title']}\n');
      final txt = st.text('${sc['id']}').trim();
      if (txt.isNotEmpty) b.writeln('$txt\n');
      if (j < scs.length - 1) b.writeln(markdown ? '\n***\n' : '\n* * *\n');
    }
  }
  return b.toString().trimRight();
}

String compileCharacters(Map<String, dynamic> p) {
  final b = StringBuffer('${tr('الشخصيات', 'Characters')} — ${p['title'] ?? ''}\n');
  for (final c in charsOf(p)) {
    b.writeln('\n■ ${c['name'] ?? ''} (${roleName(c)})');
    void line(String label, dynamic v) {
      final s = v is List ? v.join('، ') : '${v ?? ''}'.trim();
      if (s.isNotEmpty) b.writeln('  • $label: $s');
    }

    line(tr('العمر', 'Age'), c['age']);
    line(tr('المظهر', 'Appearance'), c['look']);
    line(tr('الصفات', 'Traits'), c['traits']);
    line(tr('الخلفية', 'Backstory'), c['back']);
    line(tr('الهدف/الدافع', 'Goal/motivation'), c['goal']);
    line(tr('الخوف/العيب', 'Fear/flaw'), c['fear']);
    line(tr('تطوّر الشخصية', 'Arc'), c['arc']);
    line(tr('طريقة الكلام', 'Voice'), c['voice']);
    for (final r in mapList(c['rels'])) {
      final note = '${r['note'] ?? ''}'.trim();
      line('${wFind(wRelTypes, r['type']).name} ↔ ${charName(p, r['to'])}', note.isEmpty ? '—' : note);
    }
  }
  return b.toString().trimRight();
}
