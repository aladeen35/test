import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';

/// موضوع إسعاف أولي. الخطوة التي تبدأ بـ «#» عنوان فرعي.
class FaTopic {
  final String id, ar, en, keywords;
  final IconData icon;
  final Color color;
  final List<(String, String)> steps, callWhen, donts;
  const FaTopic({
    required this.id,
    required this.ar,
    required this.en,
    required this.icon,
    required this.color,
    required this.steps,
    required this.callWhen,
    this.donts = const [],
    this.keywords = '',
  });
  String get name => tr(ar, en);
  bool matches(String q) {
    if (q.isEmpty) return true;
    final s = '$ar $en $keywords ${steps.map((e) => '${e.$1} ${e.$2}').join(' ')}'.toLowerCase();
    return q.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).every(s.contains);
  }
}

/// المصادر: إرشادات الإسعافات الأولية الدولية للاتحاد الدولي لجمعيات الصليب الأحمر والهلال الأحمر (IFRC 2020)،
/// منظمة الصحة العالمية (محلول الإرواء، لدغات الثعابين)، والإرشادات العامة للصليب الأحمر البريطاني والأمريكي.
const faSources = [
  'IFRC — International First Aid, Resuscitation and Education Guidelines (2020)',
  'WHO — Oral rehydration salts / home-made solution; Snakebite envenoming fact sheet',
  'British Red Cross & American Red Cross — public first aid guidance',
];

const firstAidTopics = <FaTopic>[
  FaTopic(
    id: 'cpr',
    ar: 'الإنعاش القلبي (CPR) — باليدين فقط',
    en: 'CPR basics — hands-only',
    icon: Icons.favorite_rounded,
    color: SD.red,
    keywords: 'انعاش قلب توقف تنفس ضغطات صدر اغماء cpr cardiac arrest heart compressions aed',
    steps: [
      ('تأكد أن المكان آمن لك وللمصاب.', 'Make sure the scene is safe for you and the person.'),
      ('كلّمه بصوت عالٍ واهزز كتفيه بلطف. إن لم يستجب، اصرخ طلبًا للمساعدة.', 'Shout and gently tap the shoulders. If there is no response, shout for help.'),
      ('اتصل بالإسعاف فورًا (ضع الهاتف على مكبّر الصوت) واطلب من أحد إحضار جهاز الصدمات (AED) إن وُجد.', 'Call emergency services now (use speakerphone) and send someone for an AED if available.'),
      ('افتح مجرى الهواء برفع الذقن وانظر هل يتنفس بشكل طبيعي — لا تزد على 10 ثوانٍ. الشهقات المتقطعة ليست تنفسًا طبيعيًا.', 'Open the airway (tilt head, lift chin) and check for normal breathing for no more than 10 seconds. Occasional gasps are NOT normal breathing.'),
      ('إن لم يتنفس طبيعيًا: ضع كعب يدك في منتصف الصدر، واليد الأخرى فوقها، وذراعاك مستقيمتان.', 'If not breathing normally: put the heel of your hand in the centre of the chest, the other hand on top, arms straight.'),
      ('اضغط بقوة وسرعة: عمق 5–6 سم للبالغ، بمعدل 100–120 ضغطة في الدقيقة، واترك الصدر يرتفع كاملًا بين الضغطات.', 'Push hard and fast: 5–6 cm deep in adults, 100–120 compressions per minute, letting the chest fully rise between pushes.'),
      ('استمر دون توقف حتى يصل الإسعاف أو يبدأ المصاب في التنفس الطبيعي أو تُرهَق تمامًا (بدّل مع شخص آخر كل دقيقتين إن أمكن).', 'Keep going without stopping until help arrives, the person starts breathing normally, or you are exhausted (swap with someone every 2 minutes if possible).'),
      ('عند وصول جهاز AED: شغّله واتبع تعليماته الصوتية فورًا.', 'When an AED arrives: switch it on and follow its voice prompts straight away.'),
      ('المدرَّبون فقط: 30 ضغطة ثم نفَسان. غير المدرَّب يكتفي بالضغطات المتواصلة.', 'Trained rescuers only: 30 compressions then 2 rescue breaths. If untrained, give continuous compressions only.'),
    ],
    callWhen: [
      ('دائمًا: أي شخص لا يستجيب ولا يتنفس طبيعيًا — اتصل بالإسعاف قبل أي شيء.', 'Always: anyone unresponsive and not breathing normally — call emergency services first.'),
    ],
    donts: [
      ('لا تتوقف عن الضغطات لتفحص النبض مرارًا.', "Don't keep stopping compressions to check for a pulse."),
      ('لا تخف من إيذائه — عدم فعل شيء أخطر بكثير.', "Don't be afraid of hurting them — doing nothing is far more dangerous."),
    ],
  ),
  FaTopic(
    id: 'bleeding',
    ar: 'النزيف',
    en: 'Bleeding',
    icon: Icons.bloodtype_rounded,
    color: SD.red,
    keywords: 'نزيف دم جرح قطع bleeding blood wound cut',
    steps: [
      ('احمِ نفسك: البس قفازات أو كيسًا بلاستيكيًا على يدك إن أمكن.', 'Protect yourself: wear gloves or put a plastic bag over your hand if possible.'),
      ('اضغط مباشرة وبقوة على الجرح بقطعة قماش نظيفة أو ضمادة.', 'Press directly and firmly on the wound with a clean cloth or dressing.'),
      ('استمر في الضغط دون رفع القماش لتتفقد الجرح. إن تشبّع بالدم ضع قطعة أخرى فوقه واستمر.', "Keep pressing without lifting to check. If it soaks through, add another cloth on top and keep pressing."),
      ('اربط ضمادة بإحكام فوق القماش عندما يخف النزيف.', 'Bandage firmly over the dressing once bleeding slows.'),
      ('إن ظهرت علامات صدمة (شحوب، برودة، دوخة، تعرّق): مدّده على ظهره وغطّه ليبقى دافئًا.', 'If there are signs of shock (pale, cold, dizzy, sweaty): lay them down and keep them warm.'),
      ('النزيف الشديد جدًا من طرف (ذراع/رجل) ولم يتوقف بالضغط: المدرَّب يستعمل رباطًا ضاغطًا (تورنيكيه) فوق الجرح ويسجل وقت ربطه.', 'Life-threatening limb bleeding not stopped by pressure: a trained person may apply a tourniquet above the wound and note the time.'),
    ],
    callWhen: [
      ('نزيف غزير أو متدفق أو لا يتوقف بعد 10 دقائق من الضغط.', 'Heavy or spurting bleeding, or bleeding that does not stop after 10 minutes of pressure.'),
      ('جرح كبير أو عميق، أو جسم مغروس فيه.', 'A large or deep wound, or an object stuck in it.'),
      ('علامات صدمة: شحوب، تعرّق بارد، تنفس سريع، تشوّش.', 'Signs of shock: pale, cold sweat, fast breathing, confusion.'),
    ],
    donts: [
      ('لا تنزع جسمًا مغروسًا في الجرح — اضغط حوله.', "Don't pull out an object stuck in the wound — press around it."),
      ('لا تضع بُنًّا أو رمادًا أو أعشابًا على الجرح.', "Don't put coffee, ash or herbs on the wound."),
    ],
  ),
  FaTopic(
    id: 'burns',
    ar: 'الحروق',
    en: 'Burns',
    icon: Icons.local_fire_department_rounded,
    color: SD.orange,
    keywords: 'حرق حروق نار ماء مغلي زيت كاوية burn scald fire hot water oil',
    steps: [
      ('أبعده عن مصدر الحرارة وأطفئ أي نار في ملابسه (أوقف، انبطح، تدحرج).', 'Move away from the heat source; put out burning clothes (stop, drop, roll).'),
      ('برّد الحرق فورًا بماء جارٍ بارد أو فاتر (غير مثلّج) لمدة 20 دقيقة على الأقل.', 'Cool the burn right away under cool or lukewarm running water (not ice-cold) for at least 20 minutes.'),
      ('انزع الخواتم والساعات والملابس الضيقة قرب الحرق بسرعة قبل التورّم — إلا ما كان ملتصقًا بالجلد.', 'Quickly remove rings, watches and tight clothing near the burn before swelling — unless stuck to the skin.'),
      ('غطِّ الحرق بغلاف بلاستيكي نظيف (نايلون الطعام) أو قماش نظيف لا يترك وبرًا، دون ربط محكم.', 'Cover loosely with cling film or a clean non-fluffy cloth.'),
      ('حافظ على دفء بقية الجسم، خاصة الأطفال، حتى لا يبرد أثناء التبريد.', 'Keep the rest of the body warm, especially children, while cooling the burn.'),
    ],
    callWhen: [
      ('حرق كبير (أكبر من كف المصاب)، أو عميق، أو في الوجه أو اليدين أو القدمين أو الأعضاء التناسلية أو المفاصل.', 'Large burns (bigger than the casualty\'s palm), deep burns, or burns on the face, hands, feet, genitals or joints.'),
      ('حروق كيميائية أو كهربائية، أو استنشاق دخان، أو صعوبة تنفس.', 'Chemical or electrical burns, smoke inhalation or breathing difficulty.'),
      ('المصاب طفل صغير أو كبير في السن.', 'The casualty is a young child or an older person.'),
    ],
    donts: [
      ('لا تضع ثلجًا أو معجون أسنان أو زبدة أو زيتًا أو بيضًا.', "Don't use ice, toothpaste, butter, oil or egg."),
      ('لا تفقأ الفقاعات.', "Don't burst blisters."),
    ],
  ),
  FaTopic(
    id: 'choking',
    ar: 'الاختناق (الشرقة)',
    en: 'Choking',
    icon: Icons.no_food_rounded,
    color: SD.purple,
    keywords: 'شرقة اختناق غصة بلع طفل رضيع choking airway blocked infant baby child back blows abdominal thrusts heimlich',
    steps: [
      ('#البالغ والطفل (فوق سنة)', '#Adult & child (over 1 year)'),
      ('إن كان يستطيع الكحة أو الكلام: شجّعه على الكحة بقوة ولا تتدخل.', 'If they can cough or speak: encourage them to keep coughing; do not interfere.'),
      ('إن لم يستطع التنفس أو الكلام أو الكحة: قف خلفه وأمِله للأمام، واضرب بين لوحي الكتف بكعب يدك حتى 5 ضربات قوية.', "If they can't breathe, speak or cough: stand behind, lean them forward and give up to 5 firm back blows between the shoulder blades with the heel of your hand."),
      ('إن لم ينجح: قف خلفه، ضع قبضتك فوق السرّة وتحت عظم الصدر، أمسكها بيدك الأخرى واسحب بقوة للداخل والأعلى حتى 5 مرات (ضغطات البطن).', 'If that fails: stand behind, place a fist between the navel and the breastbone, grasp it with your other hand and pull sharply inwards and upwards up to 5 times (abdominal thrusts).'),
      ('كرّر 5 ضربات ظهر ثم 5 ضغطات بطن حتى يخرج الجسم أو يفقد الوعي.', 'Repeat 5 back blows and 5 abdominal thrusts until the object comes out or they become unresponsive.'),
      ('للحامل المتقدمة أو البدين جدًا: اضغط على الصدر بدل البطن.', 'For late pregnancy or very large people: use chest thrusts instead of abdominal thrusts.'),
      ('#الرضيع (أقل من سنة)', '#Infant (under 1 year)'),
      ('ضعه على ساعدك ووجهه للأسفل ورأسه أخفض من جسمه، مع سند الرأس والفك.', 'Lay the baby face-down along your forearm, head lower than the body, supporting the head and jaw.'),
      ('اضرب بين لوحي الكتف حتى 5 ضربات بكعب اليد.', 'Give up to 5 back blows between the shoulder blades with the heel of your hand.'),
      ('إن لم ينجح: اقلبه على ظهره واضغط بإصبعين في منتصف الصدر تحت خط الحلمتين حتى 5 ضغطات.', 'If that fails: turn the baby face-up and give up to 5 chest thrusts with two fingers in the centre of the chest, just below the nipple line.'),
      ('كرّر حتى يخرج الجسم. لا تضغط على بطن الرضيع أبدًا.', "Repeat until the object comes out. Never do abdominal thrusts on a baby."),
      ('#إن فقد الوعي', '#If they become unresponsive'),
      ('اتصل بالإسعاف وابدأ الإنعاش القلبي فورًا.', 'Call emergency services and start CPR straight away.'),
    ],
    callWhen: [
      ('إن لم يخرج الجسم بعد الدورة الأولى من الضربات والضغطات، أو فقد الوعي.', 'If the object is not out after the first cycles of blows and thrusts, or they become unresponsive.'),
      ('بعد أي ضغطات بطن — يجب أن يفحصه طبيب حتى لو تحسّن.', 'After any abdominal thrusts — they must be checked by a doctor even if they seem fine.'),
    ],
    donts: [
      ('لا تُدخل إصبعك عشوائيًا في الفم لتبحث عن الجسم.', "Don't sweep blindly inside the mouth with your finger."),
      ('لا تقلب الطفل الكبير رأسًا على عقب أو تهزّه.', "Don't hang an older child upside down or shake them."),
    ],
  ),
  FaTopic(
    id: 'fainting',
    ar: 'الإغماء',
    en: 'Fainting',
    icon: Icons.airline_seat_flat_rounded,
    color: SD.indigo,
    keywords: 'اغماء دوخة وقع غيبوبة faint fainting dizzy collapse',
    steps: [
      ('إن شعر بالدوخة: اجعله يجلس أو يستلقي فورًا حتى لا يسقط.', 'If they feel faint: get them to sit or lie down straight away so they do not fall.'),
      ('إن أُغمي عليه: مدّده على ظهره وارفع رجليه (إن لم تكن هناك إصابة).', 'If they have fainted: lay them on their back and raise their legs (if no injury).'),
      ('فكّ الملابس الضيقة ووفّر هواءً نقيًا وأبعد الزحام.', 'Loosen tight clothing, give fresh air and keep the crowd back.'),
      ('عادةً يفيق خلال دقيقة أو اثنتين. دعه يجلس ببطء بعد الإفاقة.', 'They usually recover within a minute or two. Let them sit up slowly afterwards.'),
      ('إن لم يفق لكنه يتنفس طبيعيًا: ضعه في وضعية الإفاقة (على جنبه). إن لم يتنفس طبيعيًا: ابدأ الإنعاش القلبي.', "If they don't wake but breathe normally: place them in the recovery position (on their side). If not breathing normally: start CPR."),
    ],
    callWhen: [
      ('لم يستعد وعيه بسرعة، أو أُصيب أثناء السقوط.', "They don't come round quickly, or were injured in the fall."),
      ('ألم في الصدر، خفقان، صعوبة تنفس، أو تشنجات.', 'Chest pain, palpitations, breathing difficulty or seizures.'),
      ('حامل، أو مريض سكري، أو كبير في السن، أو تكرر الإغماء.', 'Pregnant, diabetic, elderly, or repeated fainting.'),
    ],
    donts: [
      ('لا ترشّ الماء على وجهه ولا تعطه شيئًا بالفم وهو فاقد الوعي.', "Don't splash water on the face or give anything by mouth while unresponsive."),
    ],
  ),
  FaTopic(
    id: 'fracture',
    ar: 'الكسور والالتواءات',
    en: 'Fractures & sprains',
    icon: Icons.accessibility_new_rounded,
    color: SD.coffee,
    keywords: 'كسر التواء ملخ فك عظم fracture broken bone sprain strain twist ankle',
    steps: [
      ('دعه لا يحرّك الجزء المصاب، وثبّته في الوضع الذي وجدته عليه.', 'Keep the injured part still and support it in the position found.'),
      ('ثبّت الطرف بلفّ وسادة أو ملابس حوله، أو برباط معلّق للذراع.', 'Support it with padding or clothing, or a sling for an arm.'),
      ('للكدمات والالتواءات: ضع كمادة باردة (ثلج ملفوف بقماش) نحو 20 دقيقة.', 'For bruises and sprains: apply a cold pack (ice wrapped in cloth) for about 20 minutes.'),
      ('للكسر المفتوح (العظم ظاهر أو جرح فوقه): غطِّ الجرح بقماش نظيف واضغط حوله لا فوق العظم.', 'Open fracture (bone visible or wound over it): cover with a clean cloth and press around it, not on the bone.'),
      ('راقب علامات الصدمة وأبقه دافئًا.', 'Watch for signs of shock and keep them warm.'),
    ],
    callWhen: [
      ('كسر مفتوح، أو تشوّه واضح، أو الطرف بارد/أزرق/فاقد الإحساس.', 'Open fracture, obvious deformity, or the limb is cold, blue or numb.'),
      ('إصابة الرقبة أو الظهر أو الحوض أو الفخذ — لا تحرّكه واتصل بالإسعاف.', "Neck, back, pelvis or thigh injury — don't move them; call emergency services."),
    ],
    donts: [
      ('لا تحاول تعديل العظم أو إرجاعه.', "Don't try to straighten or push the bone back."),
      ('لا تضع الثلج مباشرة على الجلد.', "Don't put ice directly on the skin."),
      ('لا تدلّك مكان الإصابة.', "Don't massage the injury."),
    ],
  ),
  FaTopic(
    id: 'nosebleed',
    ar: 'نزيف الأنف (الرعاف)',
    en: 'Nosebleed',
    icon: Icons.face_rounded,
    color: SD.henna,
    keywords: 'رعاف نزيف انف دم nosebleed nose bleed epistaxis',
    steps: [
      ('اجلسه وأمِل رأسه للأمام (لا للخلف).', 'Sit them down and lean their head FORWARD (not back).'),
      ('اضغط على الجزء الطري من الأنف (تحت العظم) بإحكام مدة 10–15 دقيقة متواصلة.', 'Pinch the soft part of the nose (below the bone) firmly for 10–15 minutes without letting go.'),
      ('يتنفس من فمه ويبصق الدم بدل بلعه.', 'Breathe through the mouth and spit out blood rather than swallow it.'),
      ('يمكن وضع كمادة باردة على جسر الأنف.', 'A cold pack on the bridge of the nose may help.'),
      ('بعد التوقف: لا يتمخّط ولا يجهد نفسه لبضع ساعات.', "Once stopped: avoid blowing the nose or straining for a few hours."),
    ],
    callWhen: [
      ('النزيف استمر أكثر من 20–30 دقيقة رغم الضغط، أو غزير جدًا.', 'Bleeding lasts more than 20–30 minutes despite pressure, or is very heavy.'),
      ('بعد ضربة على الرأس، أو المريض يتناول مميعات الدم.', 'After a head injury, or the person takes blood thinners.'),
    ],
    donts: [
      ('لا تُمل رأسه للخلف ولا تجعله يستلقي — يبتلع الدم.', "Don't tilt the head back or lie them down — they swallow blood."),
    ],
  ),
  FaTopic(
    id: 'heat',
    ar: 'ضربة الشمس والإجهاد الحراري',
    en: 'Heat stroke & heat exhaustion',
    icon: Icons.wb_sunny_rounded,
    color: SD.orange,
    keywords: 'ضربة شمس حر سخانة صيف هبوط اجهاد حراري heat stroke exhaustion sun summer hot',
    steps: [
      ('#الإجهاد الحراري (تعرّق غزير، دوخة، صداع، غثيان، تشنج عضلي)', '#Heat exhaustion (heavy sweating, dizziness, headache, nausea, cramps)'),
      ('انقله إلى مكان ظليل وبارد ومدّده وارفع رجليه قليلًا.', 'Move them to a cool shaded place, lie them down and raise their legs slightly.'),
      ('أعطه رشفات من الماء أو محلول الإرواء (ORS) إن كان واعيًا.', 'Give sips of water or oral rehydration solution (ORS) if alert.'),
      ('برّده بقماش مبلّل ومروحة، وخفّف ملابسه.', 'Cool them with wet cloths and fanning; loosen clothing.'),
      ('#ضربة الشمس (حالة طارئة: حرارة عالية جدًا، جلد حار، تشوّش، تصرّف غريب، إغماء أو تشنج)', '#Heat stroke — EMERGENCY (very high temperature, hot skin, confusion, odd behaviour, collapse or seizure)'),
      ('اتصل بالإسعاف فورًا.', 'Call emergency services immediately.'),
      ('برّده بأسرع ما يمكن: الأفضل غمر جسمه حتى الرقبة في ماء بارد. إن لم يمكن: صبّ الماء البارد على جسمه باستمرار مع التهوية، وضع كمادات باردة على الرقبة والإبطين وأعلى الفخذين.', 'Cool them as fast as possible: ideally immerse the body up to the neck in cold water. If not possible: keep pouring cold water over them with fanning, and put cold packs on the neck, armpits and groin.'),
      ('إن كان واعيًا ويستطيع البلع: رشفات ماء بارد. إن فقد الوعي ويتنفس: وضعية الإفاقة. إن لم يتنفس: الإنعاش القلبي.', 'If alert and able to swallow: sips of cool water. Unresponsive but breathing: recovery position. Not breathing: CPR.'),
      ('#الوقاية في حرّ السودان', '#Prevention in hot climates'),
      ('اشرب ماءً كثيرًا قبل العطش، تجنّب الشمس وقت الظهيرة، البس ملابس فاتحة واسعة، وانتبه للأطفال وكبار السن.', 'Drink water before you feel thirsty, avoid midday sun, wear light loose clothing, and watch children and older people.'),
    ],
    callWhen: [
      ('أي علامة لضربة الشمس: تشوّش، كلام غير مفهوم، إغماء، تشنج، جلد حار.', 'Any sign of heat stroke: confusion, slurred speech, collapse, seizure, hot skin.'),
      ('الإجهاد الحراري لم يتحسن خلال 30 دقيقة من التبريد والسوائل.', 'Heat exhaustion not improving within 30 minutes of cooling and fluids.'),
    ],
    donts: [
      ('لا تعطه دواء الحرارة (باراسيتامول/أسبرين) لعلاج ضربة الشمس — لا ينفع، التبريد هو العلاج.', "Don't give fever medicine (paracetamol/aspirin) for heat stroke — it won't help; cooling is the treatment."),
      ('لا تُعطِ سوائل لشخص غير واعٍ.', "Don't give fluids to someone who is not fully alert."),
    ],
  ),
  FaTopic(
    id: 'dehydration',
    ar: 'الجفاف والإسهال',
    en: 'Dehydration & diarrhoea',
    icon: Icons.water_drop_rounded,
    color: SD.nile,
    keywords: 'جفاف اسهال استفراغ محلول ارواء ملح سكر dehydration diarrhea diarrhoea vomiting ors oral rehydration',
    steps: [
      ('أفضل علاج: محلول الإرواء الفموي (ORS) من الصيدلية — يُحضّر حسب التعليمات على الكيس.', 'Best treatment: oral rehydration salts (ORS) sachet from a pharmacy, mixed as the packet says.'),
      ('إن لم يتوفر — المحلول المنزلي (منظمة الصحة العالمية): 1 لتر ماء نظيف (مغلي ومبرّد) + 6 ملاعق صغيرة مسطّحة سكر + نصف ملعقة صغيرة مسطّحة ملح. حرّك حتى يذوب.', 'If unavailable — WHO home-made solution: 1 litre of clean (boiled and cooled) water + 6 level teaspoons of sugar + ½ level teaspoon of salt. Stir until dissolved.'),
      ('أعطه رشفات صغيرة متكررة. إن تقيأ انتظر 10 دقائق ثم أكمل ببطء.', 'Give small frequent sips. If they vomit, wait 10 minutes then continue slowly.'),
      ('استمر في الرضاعة الطبيعية للرضيع، وفي الأكل العادي حسب القدرة.', 'Keep breastfeeding babies, and continue normal food as tolerated.'),
      ('يُحضّر المحلول المنزلي طازجًا ويُرمى بعد 24 ساعة.', 'Make the home solution fresh and throw it away after 24 hours.'),
    ],
    callWhen: [
      ('خمول شديد أو صعوبة في الإفاقة، أو لا يستطيع الشرب، أو يتقيأ كل شيء.', 'Very drowsy or hard to wake, cannot drink, or vomits everything.'),
      ('عينان غائرتان، فم جاف جدًا، لا بول لساعات طويلة، أو دم في البراز.', 'Sunken eyes, very dry mouth, no urine for many hours, or blood in the stool.'),
      ('الرضّع والأطفال الصغار وكبار السن — اطلب المساعدة مبكرًا.', 'Babies, young children and older people — seek help early.'),
    ],
    donts: [
      ('لا تزد الملح أو السكر عن المقادير — الزيادة مضرّة.', "Don't add more salt or sugar than stated — too much is harmful."),
      ('المشروبات الغازية والعصائر المحلّاة ليست بديلًا عن محلول الإرواء.', 'Fizzy drinks and sweet juices are not a substitute for ORS.'),
    ],
  ),
  FaTopic(
    id: 'bites',
    ar: 'لدغة العقرب أو الثعبان',
    en: 'Scorpion sting & snake bite',
    icon: Icons.pest_control_rounded,
    color: SD.green,
    keywords: 'عقرب ثعبان دبيب حية لدغة لسعة سم scorpion snake bite sting venom',
    steps: [
      ('#لدغة الثعبان', '#Snake bite'),
      ('ابتعد عن الثعبان. حاول تذكّر شكله أو صوّره من مسافة آمنة فقط.', 'Move away from the snake. Try to remember what it looks like, or photo it from a safe distance only.'),
      ('طمئن المصاب وأبقه هادئًا وساكنًا قدر الإمكان — الحركة تنشر السم.', 'Reassure the person and keep them calm and as still as possible — movement spreads venom.'),
      ('انزع الخواتم والساعات والأحذية الضيقة من الطرف المصاب قبل التورّم.', 'Remove rings, watches and tight shoes from the bitten limb before it swells.'),
      ('ثبّت الطرف المصاب (جبيرة أو رباط تعليق) وانقله إلى المستشفى فورًا — العلاج هو المصل المضاد في المستشفى.', 'Immobilise the bitten limb (splint or sling) and get to hospital urgently — antivenom at hospital is the treatment.'),
      ('#لدغة العقرب', '#Scorpion sting'),
      ('اغسل المكان بالماء والصابون، وضع كمادة باردة ملفوفة بقماش لتخفيف الألم.', 'Wash the area with soap and water and apply a cold pack wrapped in cloth for pain.'),
      ('أبقه هادئًا وساكنًا وراقبه. الأطفال وكبار السن أكثر عرضة للخطر — خذهم للمستشفى مبكرًا.', 'Keep them calm and still and watch closely. Children and older people are at higher risk — take them to hospital early.'),
    ],
    callWhen: [
      ('أي لدغة ثعبان — اذهب للمستشفى فورًا حتى لو بدا بخير.', 'Any snake bite — go to hospital immediately even if they seem fine.'),
      ('بعد لدغة عقرب: طفل صغير، أو تعرّق غزير، أو تقيؤ، أو صعوبة تنفس أو بلع، أو ارتعاش أو حركات غريبة، أو خفقان.', 'After a scorpion sting: a young child, heavy sweating, vomiting, difficulty breathing or swallowing, twitching or abnormal movements, or palpitations.'),
    ],
    donts: [
      ('لا تجرح مكان اللدغة ولا تمصّ السم.', "Do NOT cut the bite or suck out the venom."),
      ('لا تربط رباطًا ضاغطًا (تورنيكيه) ولا تضع ثلجًا على لدغة الثعبان.', "Don't apply a tourniquet or ice to a snake bite."),
      ('لا تحاول قتل الثعبان أو الإمساك به، ولا تعتمد على الأعشاب أو «الحجر الأسود» أو الكيّ.', "Don't try to kill or catch the snake, and don't rely on herbs, 'black stone' or burning."),
    ],
  ),
  FaTopic(
    id: 'poisoning',
    ar: 'التسمم',
    en: 'Poisoning',
    icon: Icons.science_rounded,
    color: SD.purple,
    keywords: 'تسمم سم مبيد كلور دواء جرعة زائدة gas poisoning poison overdose chemical bleach pesticide kerosene',
    steps: [
      ('تأكد أن المكان آمن (غاز، دخان، مواد كيميائية). إن كان غازًا: أخرجه للهواء الطلق إن أمكن بأمان.', 'Make sure the scene is safe (gas, fumes, chemicals). For gas: get them to fresh air if it is safe.'),
      ('اعرف ماذا أخذ وكم ومتى، واحتفظ بالعلبة أو العبوة لتريها للإسعاف.', 'Find out what, how much and when; keep the container to show the medics.'),
      ('اتصل بالإسعاف أو مركز السموم واتبع تعليماتهم.', 'Call emergency services or a poison centre and follow their advice.'),
      ('على الجلد: انزع الملابس الملوّثة واغسل بماء جارٍ كثير.', 'On the skin: remove contaminated clothing and rinse with plenty of running water.'),
      ('إن فقد الوعي ويتنفس: وضعية الإفاقة. إن لم يتنفس: الإنعاش القلبي بالضغطات فقط.', 'Unresponsive but breathing: recovery position. Not breathing: hands-only CPR.'),
    ],
    callWhen: [
      ('دائمًا عند الشك في تسمم، خاصة الأطفال، أو النعاس، أو صعوبة التنفس، أو التشنج، أو حروق بالفم.', 'Always when poisoning is suspected — especially children, drowsiness, breathing difficulty, seizures or mouth burns.'),
    ],
    donts: [
      ('لا تجعله يتقيأ.', "Don't make them vomit."),
      ('لا تعطه حليبًا أو أي شيء بالفم إلا بتعليمات مختص.', "Don't give milk or anything by mouth unless a professional tells you to."),
    ],
  ),
  FaTopic(
    id: 'seizure',
    ar: 'التشنجات (نوبة الصرع)',
    en: 'Seizures',
    icon: Icons.bolt_rounded,
    color: SD.indigo,
    keywords: 'تشنج صرع نوبة تشنجات حمى seizure epilepsy fit convulsion febrile',
    steps: [
      ('حافظ على هدوئك وانظر إلى الساعة لتحسب مدة النوبة.', 'Stay calm and note the time the seizure started.'),
      ('أبعد الأشياء الصلبة والحادة من حوله، وضع شيئًا لينًا تحت رأسه.', 'Move hard or sharp objects away and put something soft under the head.'),
      ('فكّ ما حول الرقبة من ملابس ضيقة.', 'Loosen anything tight around the neck.'),
      ('بعد انتهاء النوبة: ضعه على جنبه (وضعية الإفاقة) وتأكد أنه يتنفس، وابقَ معه حتى يستعيد وعيه كاملًا.', 'When it stops: turn them on their side (recovery position), check breathing and stay until fully aware.'),
      ('للأطفال مع الحمى: خفّف ملابسهم ولا تبرّدهم بماء بارد جدًا.', 'Children with fever: remove excess clothing; do not cool with very cold water.'),
    ],
    callWhen: [
      ('النوبة استمرت أكثر من 5 دقائق، أو تكررت دون إفاقة بينها.', 'The seizure lasts more than 5 minutes, or repeats without recovery in between.'),
      ('أول نوبة في حياته، أو أُصيب، أو حدثت في الماء، أو حامل، أو مريض سكري.', 'First ever seizure, injured, happened in water, pregnant, or diabetic.'),
      ('صعوبة في التنفس أو لا يفيق بعد انتهائها.', 'Breathing difficulty or not waking after it ends.'),
    ],
    donts: [
      ('لا تضع أي شيء في فمه (لا ملعقة ولا إصبع) — لن يبلع لسانه.', "Don't put anything in their mouth (no spoon, no finger) — they will not swallow their tongue."),
      ('لا تمسكه بقوة لإيقاف الحركة.', "Don't hold them down or try to stop the movements."),
      ('لا تعطه ماءً أو طعامًا حتى يفيق تمامًا.', "Don't give food or drink until fully alert."),
    ],
  ),
  FaTopic(
    id: 'electric',
    ar: 'الصعق الكهربائي',
    en: 'Electric shock',
    icon: Icons.electrical_services_rounded,
    color: SD.gold,
    keywords: 'كهرباء صعق سلك تيار electric shock electrocution wire current',
    steps: [
      ('لا تلمس المصاب ما دام ملامسًا للكهرباء.', "Don't touch the person while they are still in contact with the current."),
      ('افصل الكهرباء من المفتاح العمومي أو انزع القابس.', 'Switch off the power at the mains or unplug the device.'),
      ('إن لم يمكن (كهرباء منزلية فقط): قف على شيء جاف عازل وأبعد المصدر بعصا خشبية جافة.', "If you can't (household power only): stand on something dry and insulating and push the source away with a dry wooden stick."),
      ('خطوط الضغط العالي: ابتعد تمامًا واتصل بالإسعاف وشركة الكهرباء — لا تقترب.', 'High-voltage lines: keep well away and call emergency services and the power company — do not approach.'),
      ('بعد الأمان: افحص التنفس، وابدأ الإنعاش القلبي إن لم يتنفس طبيعيًا. برّد أي حروق بالماء.', 'Once safe: check breathing and start CPR if not breathing normally. Cool any burns with water.'),
    ],
    callWhen: [
      ('أي صعق كهربائي يحتاج تقييمًا طبيًا — حتى لو بدا بخير، قد تتأثر ضربات القلب.', 'Any electric shock needs a medical check — even if they look fine, heart rhythm may be affected.'),
    ],
    donts: [
      ('لا تستعمل شيئًا مبللًا أو معدنيًا لإبعاد المصدر.', "Don't use anything wet or metal to move the source."),
    ],
  ),
  FaTopic(
    id: 'eye',
    ar: 'إصابات العين',
    en: 'Eye injuries',
    icon: Icons.visibility_rounded,
    color: SD.teal,
    keywords: 'عين عيون كيماويات غبار رمل جسم غريب eye chemical dust sand foreign body',
    steps: [
      ('#مادة كيميائية في العين', '#Chemical in the eye'),
      ('اغسل العين فورًا بماء نظيف جارٍ لمدة 15–20 دقيقة على الأقل، مع فتح الجفن، وأمِل الرأس بحيث يسيل الماء بعيدًا عن العين الأخرى.', 'Rinse immediately with clean running water for at least 15–20 minutes, holding the eyelid open and tilting the head so water runs away from the other eye.'),
      ('ثم اذهب للطوارئ ومعك اسم المادة.', 'Then go to the emergency department with the name of the chemical.'),
      ('#غبار أو رمل', '#Dust or sand'),
      ('لا تفرك. اغمض وافتح العين، واغسلها بماء نظيف.', "Don't rub. Blink and rinse with clean water."),
      ('#جسم مغروس أو ضربة', '#Embedded object or blow to the eye'),
      ('لا تنزع الجسم المغروس. غطِّ العين بكوب أو غطاء دون ضغط واذهب للطوارئ.', "Don't remove an embedded object. Cover the eye with a cup or shield without pressing and go to emergency."),
      ('للضربة: كمادة باردة بلطف دون ضغط على العين.', 'For a blow: a gentle cold compress without pressure on the eye.'),
    ],
    callWhen: [
      ('أي مادة كيميائية في العين، أو جسم مغروس، أو جرح، أو نزيف داخل العين، أو تغيّر في النظر أو ألم شديد.', 'Any chemical in the eye, embedded object, cut, bleeding in the eye, change in vision or severe pain.'),
    ],
    donts: [
      ('لا تفرك العين ولا تضع فيها كحلًا أو حليبًا أو أعشابًا.', "Don't rub the eye or put kohl, milk or herbs in it."),
    ],
  ),
  FaTopic(
    id: 'allergy',
    ar: 'الحساسية الشديدة',
    en: 'Severe allergic reaction',
    icon: Icons.coronavirus_rounded,
    color: SD.pink,
    keywords: 'حساسية تورم انتفاخ لسعة نحل ادرينالين allergy allergic anaphylaxis swelling bee sting adrenaline epipen',
    steps: [
      ('علامات الخطر (صدمة الحساسية): تورّم الوجه أو اللسان أو الحلق، صعوبة تنفس أو صفير، دوخة أو إغماء، طفح منتشر.', 'Danger signs (anaphylaxis): swelling of face, tongue or throat, breathing difficulty or wheeze, dizziness or collapse, widespread rash.'),
      ('اتصل بالإسعاف فورًا.', 'Call emergency services immediately.'),
      ('إن كان معه قلم أدرينالين (EpiPen أو غيره): ساعده على استعماله في الجانب الخارجي للفخذ فورًا.', 'If they have an adrenaline auto-injector (EpiPen etc.): help them use it in the outer thigh straight away.'),
      ('إن صعب عليه التنفس: يجلس. إن شعر بالدوخة أو الإغماء: يستلقي وترفع رجلاه.', 'Breathing difficulty: let them sit up. Feeling faint: lie them down with legs raised.'),
      ('إن لم يتحسن بعد 5 دقائق ويوجد قلم ثانٍ: يُعطى الثاني.', 'If no improvement after 5 minutes and a second injector is available: give the second one.'),
      ('إن فقد الوعي ولم يتنفس طبيعيًا: ابدأ الإنعاش القلبي.', 'If unresponsive and not breathing normally: start CPR.'),
      ('#حساسية خفيفة', '#Mild reaction'),
      ('أبعد المسبّب، ويمكن أخذ مضاد الهيستامين الموصوف له، وراقبه لاحتمال تطوّرها.', 'Remove the trigger, they may take their prescribed antihistamine, and watch for worsening.'),
    ],
    callWhen: [
      ('أي تورّم في الفم أو الحلق، أو صعوبة تنفس أو بلع، أو دوخة أو إغماء.', 'Any swelling of the mouth or throat, difficulty breathing or swallowing, dizziness or collapse.'),
      ('حتى بعد استعمال قلم الأدرينالين وتحسّنه — يجب الذهاب للمستشفى.', 'Even after using adrenaline and improving — they must go to hospital.'),
    ],
    donts: [
      ('لا تجعله يقف أو يمشي فجأة إن كان دائخًا.', "Don't let them stand or walk suddenly if faint."),
      ('لا تنتظر لترى إن كانت ستتحسن وحدها عند وجود علامات الخطر.', "Don't wait to see if it settles when danger signs are present."),
    ],
  ),
];
