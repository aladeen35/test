import '../../core/data.dart';

/// مثل سوداني: النص + المعنى (سوداني، فصحى، إنجليزي)
class Proverb {
  final String text, sd, ar, en;
  const Proverb(this.text, this.sd, this.ar, this.en);
}

/// المعاني بالفصحى لأمثال data.dart (بنفس الترتيب)
const _msaForHome = [
  'التعاون يوصل إلى أبعد الغايات.',
  'التعليم وحده لا يُصلح الطبع ولا يزيل الحماقة.',
  'من كان بعيدًا عن المشكلة سهُل عليه الكلام والتنظير.',
  'اختر الجار قبل أن تختار الدار.',
  'يعيب المرء غيره وفيه العيب نفسه.',
  'بالصبر يأتي الفرج.',
  'ما لا تستطيع إدراكه فاتركه.',
  'قد يُزيح الطارئُ الغريبُ صاحبَ المكان الأصلي.',
  'الفعل القبيح لا يعترف به أحد.',
  'دخلوا في الأمر والخطر ما زال محدقًا بهم.',
  'الاعتماد والتوكل على الله في كل حال.',
  'أن تحصل على جزء من حقك خير من أن تخسره كله.',
];

/// أمثال إضافية معروفة (تُضاف دائمًا في آخر القائمة حتى لا تتغير فهارس المفضلة)
const _more = [
  Proverb('التسوي كريت في القرض تلقاه في جلدها', 'العملتو بيرجع ليك', 'كما تَدين تُدان؛ عاقبة عملك تعود عليك.',
      'What the goat does to the tanning pods shows on its own hide — you reap what you sow.'),
  Proverb('الجمل ما بشوف عوجة رقبتو', 'الزول ما بيشوف عيوبو', 'الإنسان لا يرى عيوب نفسه.', "The camel can't see the bend in its own neck — we don't see our own faults."),
  Proverb('عينك في الفيل وتطعن في ضلّو', 'عارف المشكلة وبتلف حواليها', 'ترى أصل المشكلة وتتجنبه وتعالج مظاهرها.',
      "Your eye is on the elephant yet you stab its shadow — avoiding the real problem."),
  Proverb('الجفلن خلّهن أقرع الواقفات', 'الراح خلّيهو وحافظ على الفضل', 'دع ما فات وحافظ على ما بقي.', 'Let the ones that bolted go; hold on to those still standing.'),
  Proverb('التركي ولا المتورّك', 'الأصلي أرحم من المتشبّه بيهو', 'الظالم الأصيل أهون من المتشبّه به المزايد عليه.',
      'Better the Turk than the one who plays the Turk — the imitator is often worse than the original.'),
  Proverb('كان غلبك سدّها وسّع قدّها', 'لو ما قدرت تصلحها خلّيها وما تشيل همّها', 'إذا عجزت عن إصلاح أمر فلا تُرهق نفسك به.',
      "If you can't patch the hole, widen it — if you can't fix it, stop fretting over it."),
  Proverb('المكتولة ما بتسمع الصايحة', 'الزول الواقع في المصيبة ما بيفرق معاهو الكلام', 'من أصابته المصيبة لا يلتفت إلى الصياح حوله.',
      'The one already struck does not hear the wailing.'),
  Proverb('الضاق لدغة الدبيب بخاف من جرّة الحبل', 'الاتلدغ مرة بقى يخاف من أي حاجة شبهها', 'من جرّب الأذى صار يخشى كل ما يشبهه.',
      'Whoever tasted a snake bite fears the drag of a rope — once bitten, twice shy.'),
  Proverb('العافية درجات', 'الصحة والتحسّن بيجوا شوية شوية', 'الشفاء والتحسّن يأتيان بالتدريج.', 'Recovery comes step by step.'),
  Proverb('الخريف اللين من بشايرو بيّن', 'الحاجة الكويسة بتبان من أولها', 'الخير يظهر من بداياته.', 'A good rainy season shows from its first signs.'),
  Proverb('أم جركم ما بتاكل خريفين', 'الفرصة أو الظلم ما بيدوم', 'الفرصة لا تتكرر، والظلم لا يدوم.', "The locust doesn't eat two rainy seasons — luck (or injustice) doesn't last forever."),
  Proverb('البطن بطرانة', 'أولاد الأم الواحدة ما زي بعض', 'إخوة البطن الواحد يختلفون في طباعهم.', 'One womb bears different natures — siblings differ.'),
  Proverb('جنّاً تعرفو ولا جنّاً ما بتعرفو', 'الشي البتعرفو أخير من المجهول', 'ما تعرفه وإن كان سيئًا خير من مجهول لا تعرفه.', 'Better the devil you know than the devil you don’t.'),
  Proverb('الجمرة بتحرق الواطيها', 'البحس بالوجع صاحبو بس', 'لا يشعر بالألم إلا من يعانيه.', 'The ember burns only the one who steps on it.'),
  Proverb('الدنيا دبنقا دردقي بشيش', 'الدنيا هشّة، عيشها براحة', 'الدنيا هشة كجرة الفخار، فتعامل معها برفق وأناة.', 'Life is a clay jar — roll it gently.'),
  Proverb('جلداً ما جلدك جرّ فيهو الشوك', 'الما حقّك ما بتحرص عليهو', 'لا يحرص المرء على ما ليس له.', "It's not your skin, so drag it through the thorns — people are careless with what isn't theirs."),
  Proverb('سيد الرايحة بفتّش خشم البقرة', 'الفقد حاجة بيفتش في أي حتة', 'صاحب الحاجة المفقودة يبحث عنها في كل مكان حتى غير المعقول.',
      "The one who lost something searches even the cow's mouth."),
  Proverb('الخيل تجقلب والشكر لحمّاد', 'ناس بتتعب وغيرهم بياخد الشكر', 'يتعب قوم وينال غيرهم الثناء.', 'The horses gallop, but Hammad gets the thanks.'),
  Proverb('التور كان وقع بتكتر سكاكينو', 'القوي لمن يقع الكل بيتشطّر عليهو', 'إذا سقط القوي كثر المتطاولون عليه.', 'When the bull falls, the knives multiply.'),
  Proverb('الموية بتكضّب الغطّاس', 'التجربة بتكشف الصاح من الكضب', 'التجربة تكشف صدق الادعاء من كذبه.', "The water exposes the diver's boast — the test reveals the truth."),
  Proverb('الفي إيدو القلم ما بكتب روحو شقي', 'صاحب السلطة بيعمل لمصلحتو', 'صاحب السلطة لا يضرّ نفسه.', "Whoever holds the pen won't write himself down as wretched."),
  Proverb('اللسان الحلو بطلّع الدبيب من جحرو', 'الكلام الطيب بيليّن أصعب زول', 'الكلمة الطيبة تليّن أقسى القلوب.', 'A sweet tongue draws the snake out of its hole.'),
  Proverb('الريسين بغرّقوا المركب', 'القيادة لو كترت الشغل بيخرب', 'تعدد القادة يفسد الأمر.', 'Two captains sink the boat.'),
  Proverb('حبل الكضب قصير', 'الكضب ما بيطوّل وبينكشف', 'الكذب لا يدوم وسرعان ما ينكشف.', 'The rope of lies is short.'),
  Proverb('الما بعرفك بجهلك', 'الما بيعرفك ما بيقدّرك', 'من لا يعرفك لا يعرف قدرك.', "Whoever doesn't know you underestimates you."),
  Proverb('الباب البجيب الريح سدّو واستريح', 'ابعد من سبب المشاكل', 'ابتعد عن مصدر المتاعب تسترح.', 'Shut the door that lets the wind in, and rest.'),
  Proverb('قليل البخت بلقى العضم في الكرشة', 'الما عندو حظ بتجيهو المشاكل من حيث ما يتوقع', 'قليل الحظ يلقى العثرة حيث لا يُتوقع.', 'The unlucky one finds a bone in the tripe.'),
  Proverb('الساقية لسّه مدوّرة', 'الدنيا لسه ماشية والموضوع ما انتهى', 'الحياة مستمرة والأمر لم ينتهِ بعد.', 'The waterwheel is still turning — life goes on, it’s not over yet.'),
  Proverb('الجواب بكفيك عنوانو', 'من أول حاجة بتعرف الباقي', 'تدل البدايات على ما بعدها.', 'The envelope tells you enough about the letter.'),
];

/// القائمة الكاملة: أمثال الصفحة الرئيسية أولًا (بنفس ترتيبها)، ثم الإضافات
final List<Proverb> allProverbs = [
  for (var i = 0; i < sudaneseProverbs.length; i++)
    Proverb(sudaneseProverbs[i].$1, sudaneseProverbs[i].$2, i < _msaForHome.length ? _msaForHome[i] : sudaneseProverbs[i].$2, sudaneseProverbs[i].$3),
  ..._more,
];
