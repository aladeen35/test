// Generates an Arabic art-spec sheet for all 30 character cards from
// src/data/characters.json, for illustrators producing custom artwork
// (assets/characters/custom/<id>.png). Run: node scripts/generate-card-specs.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const characters = JSON.parse(readFileSync(join(root, 'src', 'data', 'characters.json'), 'utf8'));

const AR = {
  gender: { male: 'رجل', female: 'امرأة' },
  skinTone: { light: 'فاتحة', tan: 'حنطية', medium: 'سمراء متوسطة', dark: 'داكنة (سمراء)' },
  hairColor: { black: 'أسود', brown: 'بني', gray: 'رمادي', blonde: 'أشقر', covered: 'غير ظاهر (محجبة)' },
  hairStyle: {
    short: 'قصير مرتب',
    receding: 'قصير مع انحسار واضح في مقدمة الرأس',
    bald: 'أصلع تماماً',
    curly: 'مجعد قصير',
    long: 'طويل منسدل',
    bun: 'معقود للأعلى (كعكة)',
    curlyLong: 'طويل مموج غزير',
    hijab: 'حجاب يغطي الشعر بالكامل',
  },
  beardStyle: {
    none: 'بدون لحية (وجه حليق)',
    trimmed: 'لحية خفيفة مهذبة',
    full: 'لحية كثيفة كاملة مع شارب متصل',
  },
  headwear: {
    none: 'لا شيء على الرأس',
    helmet: 'خوذة أمان',
    fireHelmet: 'خوذة إطفاء حمراء عريضة بشعار أصفر',
    chefHat: 'قبعة طهاة بيضاء منفوخة',
    pilotCap: 'قبعة طيار كحلية بحافة سوداء وشعار ذهبي',
    policeCap: 'قبعة شرطة كحلية بنجمة ذهبية',
    hijab: 'حجاب',
    sunHat: 'قبعة قش عريضة الحواف بشريط أحمر',
  },
  clothing: {
    whiteCoat: 'معطف طبي أبيض فوق قميص ملون',
    vest: 'سترة عاكسة برتقالية بخط فضي فوق قميص أزرق بأكمام طويلة',
    chefJacket: 'سترة طهي بيضاء بصفّي أزرار',
    pilotUniform: 'زي طيران رسمي كحلي بشارات كتف ذهبية وربطة عنق',
    policeUniform: 'زي شرطة كحلي رسمي بشارة نجمة على الصدر',
    fireUniform: 'زي إطفاء واقٍ داكن بخطوط عاكسة صفراء وفضية',
    suit: 'بدلة رسمية أنيقة مع قميص أبيض',
    blazer: 'جاكيت شبه رسمي فوق قميص أبيض (بدون ربطة عنق)',
    casual: 'ملابس عصرية غير رسمية (تيشيرت/قميص كاجوال)',
    overalls: 'أفرول عمل جينز أزرق بحمالات فوق قميص ملون',
    apron: 'مريلة خباز بُنيّة فوق قميص',
    stylish: 'إطلالة أنيقة عصرية بلمسات ذهبية',
  },
  accessory: {
    stethoscope: 'سماعة طبية حول الرقبة',
    blueprint: 'مخطط هندسي (ورقة زرقاء برسوم بيضاء)',
    tablet: 'جهاز لوحي مع قلم رقمي',
    spoon: 'ملعقة طهي خشبية',
    laptop: 'حاسوب محمول',
    camera: 'كاميرا تصوير احترافية',
    book: 'كتاب',
    wheat: 'سنابل قمح ذهبية',
    mic: 'ميكروفون صحفي',
    bread: 'رغيف خبز ذهبي',
    briefcase: 'حقيبة أعمال',
    wrench: 'مفتاح ربط معدني',
    bulb: 'مصباح إضاءة (رمز الكهرباء)',
    tape: 'شريط قياس خياطة',
    dentalMirror: 'مرآة فحص أسنان',
    medicine: 'علبة دواء',
    scales: 'ميزان العدالة',
    none: 'بدون إكسسوار',
  },
  accent: {
    '#4FB3E8': 'أزرق سماوي', '#2FBF9B': 'أخضر نعناعي', '#FFC928': 'أصفر شمسي',
    '#F26B5E': 'مرجاني', '#1E63C8': 'أزرق ملكي', '#7C5CBF': 'بنفسجي',
  },
};

// Helmet color specifics used by the current art (keep for consistency).
const HELMET_NOTES = {
  'engineer-male': 'الخوذة صفراء',
  'engineer-female': 'الخوذة بيضاء',
  'electrician-male': 'الخوذة برتقالية',
};

const yesNo = (v) => (v ? 'نعم' : 'لا');

let out = `================================================================
مواصفات بطاقات الشخصيات — لعبة «أنا مِنو 🤔»
================================================================

📁 طريقة الإضافة:
- احفظ كل بطاقة باسم رقمها بالضبط: 1.png ، 2.png ، ... ، 30.png
- ضع الملفات داخل: assets/characters/custom/
- أي بطاقة ناقصة تستخدم الرسم الحالي تلقائياً — لا حاجة لأي تعديل بالكود.

🎨 مواصفات فنية موحدة لكل البطاقات:
- المقاس: مربع 1:1 — يُفضّل 1024×1024 بكسل (PNG).
- الإطار: الرأس والكتفان (بورتريه نصفي)، الشخصية في المنتصف.
- الأسلوب: كرتون ثلاثي الأبعاد لامع بنفس أسلوب اللوقو تماماً
  (إضاءة ناعمة، ألوان مشبعة مبهجة، ملامح ودودة).
- كل الشخصيات بالغة (لا أطفال) ومناسبة للعائلة.
- الخلفية: لون واحد بسيط أو تدرج خفيف باللون المقترح لكل بطاقة
  (مذكور تحت كل شخصية) حتى تتناسق اللوحة.
- نفس حجم الرأس ونفس ارتفاع الكتفين في كل البطاقات قدر الإمكان.

⚠️ الأهم على الإطلاق:
أسئلة اللعبة (نظارة؟ لحية؟ خوذة؟ معطف أبيض؟...) تُجاب من هذه المواصفات.
يجب أن تطابق الرسمة كل بند حرفياً — إن رسمت نظارة لشخصية مواصفاتها
«بدون نظارة» تصبح اللعبة غير عادلة.

================================================================
`;

for (const c of characters) {
  const notes = [];
  if (HELMET_NOTES[c.slug]) notes.push(HELMET_NOTES[c.slug]);
  if (c.slug === 'pilot-male') notes.push('النظارة شمسية بنمط الطيارين (تُحسب نظارة)');
  if (c.slug === 'graphic-designer-male') notes.push('الشعر الطويل معقود ككعكة رجالية (Man bun)');

  out += `
🃏 البطاقة رقم ${c.id} — الملف: ${c.id}.png
----------------------------------------------------------------
الاسم:            ${c.name}
المهنة:           ${c.professionAr}
الجنس:            ${AR.gender[c.gender]}
لون البشرة:       ${AR.skinTone[c.skinTone]}
لون الشعر:        ${AR.hairColor[c.hairColor]}
تسريحة الشعر:     ${AR.hairStyle[c.hairStyle]}
نظارة:            ${yesNo(c.hasGlasses)}${c.hasGlasses ? ' — إطار أسود واضح' : ''}
${c.gender === 'male' ? `اللحية:           ${AR.beardStyle[c.beardStyle]}\n` : ''}غطاء الرأس:       ${AR.headwear[c.headwear]}
الملابس:          ${AR.clothing[c.clothing]}
زي مهني رسمي:     ${yesNo(c.uniform)}
الإكسسوار:        ${AR.accessory[c.accessory]}
لون خلفية البطاقة: ${AR.accent[c.accent] ?? c.accent} (${c.accent})
الوصف المختصر:    ${c.visualTraits}
${notes.length ? 'ملاحظات:          ' + notes.join(' · ') + '\n' : ''}`;
}

out += `
================================================================
ملخص سريع للتدقيق (يجب أن تطابق كل رسمة هذه الأعداد الإجمالية):
- 15 رجلاً و15 امرأة.
- يرتدي النظارة: ${characters.filter((c) => c.hasGlasses).length} شخصيات.
- لديه لحية: ${characters.filter((c) => c.beardStyle !== 'none').length} شخصيات.
- يرتدي خوذة: ${characters.filter((c) => ['helmet', 'fireHelmet'].includes(c.headwear)).length} شخصيات.
- محجبات: ${characters.filter((c) => c.headwear === 'hijab').length} شخصيات.
- معطف أبيض: ${characters.filter((c) => c.clothing === 'whiteCoat').length} شخصيات.
================================================================
`;

const dest = join(root, 'docs-card-specs-ar.txt');
writeFileSync(dest, out);
console.log(`Wrote ${dest} (${characters.length} cards)`);
