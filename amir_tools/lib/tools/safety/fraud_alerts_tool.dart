import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../screens/tool_page.dart';
import 'safety_common.dart';

class _Scam {
  final String id, emoji, title, story;
  final List<String> signs, todo;
  final Color color;
  const _Scam(this.id, this.emoji, this.title, this.story, this.signs, this.todo, this.color);
}

List<_Scam> get _scams => [
      _Scam(
        'bank_sms',
        '🏦',
        t('رسايل البنك والتحويل المزيّفة', 'رسائل البنك والتحويل المزيّفة', 'Fake bank / transfer SMS'),
        t('«عزيزي العميل، حسابك اتوقف — ادخل الرابط لتفعيله» أو «وصلك تحويل، أكّد ببياناتك».', '«عزيزي العميل، تم إيقاف حسابك — ادخل الرابط لتفعيله» أو «وصلك تحويل، أكّد ببياناتك».',
            '"Dear customer, your account is suspended — tap the link to reactivate" or "You received a transfer, confirm your details".'),
        [
          t('جاية من رقم عادي أو اسم غريب، وفيها رابط.', 'واردة من رقم عادي أو اسم غريب، وفيها رابط.', 'Comes from an ordinary number or odd sender, with a link.'),
          t('فيها استعجال وتهديد: «خلال 24 ساعة».', 'فيها استعجال وتهديد: «خلال 24 ساعة».', 'Urgency and threats: "within 24 hours".'),
          t('بتطلب الرمز السري أو كود OTP أو رقم البطاقة.', 'تطلب الرمز السري أو كود OTP أو رقم البطاقة.', 'Asks for your PIN, OTP code or card number.'),
        ],
        [
          t('ما تدوس الرابط.', 'لا تضغط الرابط.', 'Do not tap the link.'),
          t('افتح تطبيق البنك بنفسك أو اتصل على الرقم الرسمي.', 'افتح تطبيق البنك بنفسك أو اتصل بالرقم الرسمي.', 'Open the bank app yourself or call the official number.'),
          t('لو دخّلت بياناتك: كلّم البنك طوالي وغيّر كلمة السر.', 'إن أدخلت بياناتك: اتصل بالبنك فورًا وغيّر كلمة السر.', 'If you entered details: call the bank now and change your password.'),
        ],
        SD.gold,
      ),
      _Scam(
        'prize',
        '🎁',
        t('«مبروك فزت بجايزة!»', '«مبروك، ربحت جائزة!»', '"Congratulations, you won!"'),
        t('فزت بعربية أو آيفون أو قروش في سحب ما دخلته — بس ادفع «رسوم» أول.', 'ربحت سيارة أو آيفون أو مالًا في سحب لم تشارك فيه — بشرط دفع «رسوم» أولًا.',
            'You won a car, iPhone or cash in a draw you never entered — just pay a "fee" first.'),
        [
          t('ما شاركت في أي مسابقة.', 'لم تشارك في أي مسابقة.', 'You never entered any contest.'),
          t('بيطلبوا رسوم توصيل/جمارك/تحويل أو بيانات بطاقتك.', 'يطلبون رسوم توصيل أو جمارك أو تحويل، أو بيانات بطاقتك.', 'They ask for delivery/customs/transfer fees or card details.'),
          t('بيستعملوا اسم شركة معروفة وشعارها.', 'يستخدمون اسم شركة معروفة وشعارها.', 'They use a well-known company\'s name and logo.'),
        ],
        [
          t('الجايزة الحقيقية ما بتطلب منك تدفع.', 'الجائزة الحقيقية لا تطلب منك الدفع.', 'A real prize never asks you to pay.'),
          t('اتجاهلها واحظر الرقم.', 'تجاهلها واحظر الرقم.', 'Ignore it and block the number.'),
        ],
        SD.purple,
      ),
      _Scam(
        'wa_code',
        '🔢',
        t('طلب كود واتساب', 'طلب كود واتساب', 'WhatsApp code request'),
        t('صاحبك (حسابه اتسرق) بيكتب ليك: «رسّلت ليك كود 6 أرقام بالغلط، رجّعه لي».', 'صديقك (المخترق حسابه) يكتب لك: «أرسلت لك كودًا من 6 أرقام بالخطأ، أعده لي».',
            'A friend (whose account was hacked) writes: "I sent you a 6-digit code by mistake, send it back".'),
        [
          t('الكود جاك إنت لأن في زول بيحاول يسجّل برقمك إنت.', 'وصلك الكود لأن أحدهم يحاول التسجيل برقمك أنت.', 'The code came to you because someone is trying to register YOUR number.'),
          t('الطلب مستعجل ومن رقم بتعرفه.', 'الطلب مستعجل ومن رقم تعرفه.', 'The request is urgent and from a number you know.'),
        ],
        [
          t('ما تدّي الكود لأي زول أبدًا.', 'لا تعطِ الكود لأي أحد أبدًا.', 'Never share the code with anyone.'),
          t('اتصل على صاحبك مكالمة عادية ونبّهه.', 'اتصل بصديقك مكالمة عادية ونبّهه.', 'Call your friend with a normal call and warn them.'),
          t('شغّل التحقق بخطوتين في واتساب.', 'فعّل التحقق بخطوتين في واتساب.', 'Turn on WhatsApp two-step verification.'),
        ],
        SD.green,
      ),
      _Scam(
        'jobs',
        '✈️',
        t('وظايف بره وتأشيرات وهمية', 'وظائف بالخارج وتأشيرات وهمية', 'Fake jobs abroad & visa scams'),
        t('«مطلوب عمال/سواقين/ممرضين للخليج أو أوروبا، راتب عالي، سكن وتذاكر — ادفع رسوم التأشيرة».',
            '«مطلوب عمال/سائقون/ممرضون للخليج أو أوروبا، راتب مرتفع، سكن وتذاكر — ادفع رسوم التأشيرة».',
            '"Workers/drivers/nurses wanted in the Gulf or Europe, high salary, housing & tickets — pay the visa fee".'),
        [
          t('راتب كبير شديد بدون مقابلة ولا خبرة.', 'راتب مرتفع جدًا دون مقابلة أو خبرة.', 'Very high pay with no interview or experience.'),
          t('بيطلبوا قروش مقدّم «للتأشيرة أو الكشف الطبي أو العقد».', 'يطلبون مالًا مقدمًا «للتأشيرة أو الفحص الطبي أو العقد».', 'Upfront money "for the visa, medical or contract".'),
          t('التواصل واتساب بس، وإيميل مجاني (gmail) بدل إيميل شركة.', 'التواصل عبر واتساب فقط، وبريد مجاني بدل بريد شركة.', 'WhatsApp-only contact and a free email instead of a company domain.'),
          t('بيطلبوا صورة جوازك وبياناتك بسرعة.', 'يطلبون صورة جوازك وبياناتك بسرعة.', 'They rush you for a passport copy and personal data.'),
        ],
        [
          t('اتأكد من الشركة ومكتب الاستقدام إنهم مرخّصين، وتحقق من التأشيرة في الموقع الحكومي الرسمي للبلد.',
              'تحقق من ترخيص الشركة ومكتب الاستقدام، ومن التأشيرة في الموقع الحكومي الرسمي للبلد.',
              'Check the company and recruitment agency are licensed, and verify the visa on the destination country\'s official government site.'),
          t('اسأل سفارة البلد أو ناس شغالين هناك.', 'اسأل سفارة البلد أو أشخاصًا يعملون هناك.', 'Ask the country\'s embassy or people who work there.'),
          t('ما تحوّل قروش لحساب شخصي.', 'لا تحوّل مالًا إلى حساب شخصي.', 'Never transfer money to a personal account.'),
        ],
        SD.nile,
      ),
      _Scam(
        'fake_receipt',
        '🧾',
        t('صورة إشعار تحويل مزوّرة', 'صورة إشعار تحويل مزوّرة', 'Fake transfer receipt screenshot'),
        t('مشتري بيرسّل ليك صورة إشعار «بنكك» أو أي تطبيق ويقول ليك سلّم البضاعة هسي.', 'مشترٍ يرسل لك صورة إشعار تحويل من تطبيق بنكي ويطلب تسليم البضاعة فورًا.',
            'A buyer sends a screenshot of a banking-app transfer and asks you to hand over the goods now.'),
        [
          t('بيستعجلك: «القروش بتنزل بعد شوية، الشبكة طاشة».', 'يستعجلك: «المال سيصل بعد قليل، الشبكة ضعيفة».', 'Rushes you: "the money will arrive soon, network is slow".'),
          t('الصورة بس بدون ما يزيد رصيدك.', 'مجرد صورة دون أن يزيد رصيدك.', 'Only a picture — your balance has not changed.'),
          t('الاسم أو الرقم أو الوقت في الإشعار ما مظبوط.', 'الاسم أو الرقم أو الوقت في الإشعار غير مطابق.', 'Name, account number or time on the receipt does not match.'),
        ],
        [
          t('افتح تطبيقك وشوف الرصيد أو كشف الحساب قبل ما تسلّم أي حاجة.', 'افتح تطبيقك وراجع الرصيد أو الكشف قبل تسليم أي شيء.', 'Open your own app and check the balance/statement before handing anything over.'),
          t('الصورة ما دليل.', 'الصورة ليست دليلًا.', 'A screenshot is not proof.'),
        ],
        SD.henna,
      ),
      _Scam(
        'invest',
        '📈',
        t('استثمار ومضاعفة القروش والعملات الرقمية', 'استثمار ومضاعفة المال والعملات الرقمية', 'Investment & crypto "doubling"'),
        t('«حط 100 دولار تطلع 300 في أسبوع» — منصات وقروبات تيليجرام بصور أرباح.', '«ضع 100 دولار تصبح 300 في أسبوع» — منصات ومجموعات تيليجرام بصور أرباح.',
            '"Put in \$100, get \$300 in a week" — platforms and Telegram groups with profit screenshots.'),
        [
          t('أرباح «مضمونة» وعالية وسريعة.', 'أرباح «مضمونة» ومرتفعة وسريعة.', '"Guaranteed", high and fast returns.'),
          t('بيطلبوا منك تجيب ناس عشان تكسب (هرمي).', 'يطلبون منك جلب أشخاص لتربح (هرمي).', 'You earn by recruiting others (pyramid).'),
          t('لما تجي تسحب: «ادفع رسوم أو ضريبة أول».', 'عند السحب: «ادفع رسومًا أو ضريبة أولًا».', 'When you try to withdraw: "pay a fee or tax first".'),
        ],
        [
          t('ما في استثمار حقيقي بيضمن ربح عالي.', 'لا يوجد استثمار حقيقي يضمن ربحًا مرتفعًا.', 'No real investment guarantees high profit.'),
          t('ما تدفع «رسوم سحب» — كدا بتخسر أكتر.', 'لا تدفع «رسوم سحب» — ستخسر أكثر.', 'Never pay a "withdrawal fee" — you will only lose more.'),
        ],
        SD.orange,
      ),
      _Scam(
        'relative',
        '👪',
        t('منتحل قريب بيطلب قروش', 'منتحل صفة قريب يطلب مالًا', 'Fake relative asking for money'),
        t('«يا أمي ده رقمي الجديد، تلفوني وقع. حوّلي لي ضروري وما بقدر أتكلم هسي».', '«يا أمي هذا رقمي الجديد، سقط هاتفي. حوّلي لي مالًا ضروريًا ولا أستطيع الكلام الآن».',
            '"Mum, this is my new number, I dropped my phone. I need money urgently and can\'t talk now".'),
        [
          t('رقم جديد وطلب مستعجل.', 'رقم جديد وطلب عاجل.', 'New number and an urgent request.'),
          t('ما داير يتكلم صوت.', 'يرفض المكالمة الصوتية.', 'Refuses a voice call.'),
          t('الحساب المطلوب التحويل ليه باسم زول تاني.', 'الحساب المطلوب التحويل إليه باسم شخص آخر.', 'The account to pay is in someone else\'s name.'),
        ],
        [
          t('اتصل على رقمه القديم أو زول قريب منه.', 'اتصل برقمه القديم أو بشخص قريب منه.', 'Call their old number or someone close to them.'),
          t('اسأله سؤال ما بيعرفه غيره.', 'اسأله سؤالًا لا يعرفه غيره.', 'Ask a question only they would know.'),
        ],
        SD.pink,
      ),
      _Scam(
        'charity',
        '🤲',
        t('تبرعات وهمية وقت الأزمات', 'تبرعات وهمية وقت الأزمات', 'Fake charity during crises'),
        t('وقت الحرب والفيضانات بتطلع صفحات بتجمع تبرعات لحسابات شخصية بصور مؤثرة.', 'في الحروب والفيضانات تظهر صفحات تجمع تبرعات لحسابات شخصية بصور مؤثرة.',
            'During wars and floods, pages collect donations into personal accounts using emotional photos.'),
        [
          t('ما في اسم جهة معروفة ولا تقارير صرف.', 'لا اسم جهة معروفة ولا تقارير صرف.', 'No known organisation and no spending reports.'),
          t('الصور منقولة من أحداث تانية.', 'الصور منقولة من أحداث أخرى.', 'Photos copied from other events.'),
          t('ضغط عاطفي: «لو ما اتبرعت هسي…».', 'ضغط عاطفي: «إن لم تتبرع الآن…».', 'Emotional pressure: "if you don\'t give now…".'),
        ],
        [
          t('اتبرع عن طريق جهات معروفة أو ناس بتعرفهم شخصيًا في المنطقة.', 'تبرّع عبر جهات معروفة أو أشخاص تعرفهم شخصيًا في المنطقة.',
              'Give through known organisations or people you personally know on the ground.'),
          t('دوّر على الصور بالبحث العكسي (أداة «التحقق من الأخبار»).', 'ابحث عن الصور بالبحث العكسي (أداة «التحقق من الأخبار»).', 'Reverse-search the photos (see the "News Verification" tool).'),
        ],
        SD.teal,
      ),
      _Scam(
        'phishing',
        '🎣',
        t('روابط التصيّد', 'روابط التصيّد', 'Phishing links'),
        t('رابط بيوديك لصفحة شبه فيسبوك أو البنك أو Google عشان تكتب كلمة السر.', 'رابط يقودك لصفحة تشبه فيسبوك أو البنك أو Google لتكتب كلمة السر.',
            'A link leads to a page that looks like Facebook, your bank or Google so you type your password.'),
        [
          t('اسم الموقع فيه غلطة صغيرة: faceb00k أو paypa1.', 'اسم الموقع فيه خطأ صغير: faceb00k أو paypa1.', 'A tiny typo in the domain: faceb00k or paypa1.'),
          t('اسم الجهة في أول الرابط والنطاق الحقيقي في الآخر: facebook.com.login-xyz.top.', 'اسم الجهة في أول الرابط والنطاق الحقيقي في آخره: facebook.com.login-xyz.top.',
              'Brand at the start, real domain at the end: facebook.com.login-xyz.top.'),
          t('روابط مختصرة (bit.ly…) ما بتوريك الوجهة.', 'روابط مختصرة (bit.ly…) تخفي الوجهة.', 'Short links (bit.ly…) hide the destination.'),
        ],
        [
          t('افحص الرابط بأداة «فاحص الروابط».', 'افحص الرابط بأداة «فاحص الروابط».', 'Check it with the "Link Checker" tool.'),
          t('اكتب عنوان الموقع بنفسك بدل ما تدوس الرابط.', 'اكتب عنوان الموقع بنفسك بدل الضغط على الرابط.', 'Type the address yourself instead of tapping the link.'),
        ],
        SD.red,
      ),
      _Scam(
        'deposit',
        '🏠',
        t('عربون قبل ما تشوف الحاجة', 'عربون قبل المعاينة', 'Deposit before viewing'),
        t('إعلان بيت للإيجار أو عربية أو تلفون بسعر رخيص — «حوّل العربون عشان نحجزه ليك».', 'إعلان منزل للإيجار أو سيارة أو هاتف بسعر رخيص — «حوّل العربون لنحجزه لك».',
            'A cheap house to rent, car or phone advert — "send a deposit so we hold it for you".'),
        [
          t('السعر أرخص من السوق بكتير.', 'السعر أقل من السوق بكثير.', 'Price far below market.'),
          t('البايع «مسافر» وما بيقدر يوريك الحاجة.', 'البائع «مسافر» ولا يستطيع أن يريك الشيء.', 'The seller is "travelling" and cannot show it.'),
        ],
        [
          t('ما تدفع قبل ما تشوف بعينك وتتأكد من الملكية.', 'لا تدفع قبل المعاينة والتحقق من الملكية.', 'Never pay before you see it and verify ownership.'),
        ],
        SD.coffee,
      ),
    ];

class _Q {
  final String text, why;
  final bool scam;
  const _Q(this.text, this.scam, this.why);
}

List<_Q> get _quiz => [
      _Q(t('رسالة من رقم عادي: «حسابك في البنك اتوقف، ادخل الرابط ده عشان تفعّله».', 'رسالة من رقم عادي: «تم إيقاف حسابك البنكي، ادخل هذا الرابط لتفعيله».',
              'SMS from an ordinary number: "Your bank account is suspended, tap this link to reactivate".'), true,
          t('البنوك ما بترسّل روابط تطلب بياناتك. افتح التطبيق بنفسك.', 'البنوك لا ترسل روابط تطلب بياناتك. افتح التطبيق بنفسك.', 'Banks do not send links asking for your details. Open the app yourself.')),
      _Q(t('صاحبك في واتساب: «رسّلت ليك كود بالغلط، رسّله لي».', 'صديقك في واتساب: «أرسلت لك كودًا بالخطأ، أعده لي».', 'Friend on WhatsApp: "I sent you a code by mistake, send it back".'), true,
          t('الكود ده لحسابك إنت — لو رسّلته بيشيلوا واتسابك.', 'هذا الكود لحسابك أنت — إن أرسلته سيستولون على واتسابك.', 'That code is for YOUR account — sending it lets them take your WhatsApp.')),
      _Q(t('طلبت تحويل من تطبيق البنك بنفسك، وجاك كود OTP في رسالة.', 'طلبت تحويلًا من تطبيق البنك بنفسك، ووصلك كود OTP في رسالة.',
              'You started a transfer in your bank app yourself and got an OTP code by SMS.'), false,
          t('ده طبيعي — بس استعمله إنت في التطبيق وما تدّيه لأي زول.', 'هذا طبيعي — لكن استخدمه أنت في التطبيق ولا تعطه لأحد.', 'Normal — but use it yourself in the app and never give it to anyone.')),
      _Q(t('شركة في الخليج: وظيفة بـ 3000 دولار بدون مقابلة، بس حوّل 200 دولار رسوم تأشيرة لحساب شخصي.',
              'شركة في الخليج: وظيفة براتب 3000 دولار دون مقابلة، بشرط تحويل 200 دولار رسوم تأشيرة لحساب شخصي.',
              'Gulf company: \$3,000 job, no interview — just send a \$200 visa fee to a personal account.'), true,
          t('رسوم مقدّمة لحساب شخصي وبدون مقابلة = علامات احتيال واضحة.', 'رسوم مقدمة لحساب شخصي ودون مقابلة = علامات احتيال واضحة.', 'Upfront fee to a personal account and no interview = clear scam signs.')),
      _Q(t('مشتري رسّل ليك صورة إشعار تحويل وقال: «سلّم البضاعة، القروش بتنزل بعد شوية».', 'مشترٍ أرسل صورة إشعار تحويل وقال: «سلّم البضاعة، المال سيصل بعد قليل».',
              'Buyer sends a transfer screenshot: "Hand over the goods, the money will arrive shortly".'), true,
          t('ما تسلّم إلا بعد ما تشوف القروش في رصيدك إنت.', 'لا تسلّم إلا بعد رؤية المال في رصيدك أنت.', 'Only hand over after you see the money in your own balance.')),
      _Q(t('Google رسّلت ليك «هل تحاول تسجيل الدخول؟» وإنت فعلًا بتسجّل في تلفون جديد.', 'أرسلت Google «هل تحاول تسجيل الدخول؟» وأنت فعلًا تسجّل في هاتف جديد.',
              'Google asks "Are you trying to sign in?" while you really are signing in on a new phone.'), false,
          t('ده تأكيد حقيقي لأنك إنت البتسجّل. لو ما كنت إنت — اضغط «لا» وغيّر كلمة السر.', 'هذا تأكيد حقيقي لأنك أنت من يسجّل. إن لم تكن أنت فاضغط «لا» وغيّر كلمة السر.',
              'This is real because it is you. If it is not you — tap "No" and change your password.')),
      _Q(t('منصة استثمار بتضمن ليك 30% ربح كل أسبوع.', 'منصة استثمار تضمن لك ربحًا 30% أسبوعيًا.', 'An investment platform guarantees 30% profit every week.'), true,
          t('ما في استثمار حقيقي بيضمن ربح زي ده.', 'لا يوجد استثمار حقيقي يضمن ربحًا كهذا.', 'No real investment guarantees returns like that.')),
      _Q(t('رقم جديد: «يا أبوي ده رقمي الجديد، حوّل لي قروش ضروري وما بقدر أتكلم».', 'رقم جديد: «يا أبي هذا رقمي الجديد، حوّل لي مالًا ضروريًا ولا أستطيع الكلام».',
              'New number: "Dad, this is my new number, send money urgently, I can\'t talk".'), true,
          t('اتصل على رقمه القديم أو اسأله سؤال خاص قبل أي تحويل.', 'اتصل برقمه القديم أو اسأله سؤالًا خاصًا قبل أي تحويل.', 'Call the old number or ask a private question before sending anything.')),
      _Q(t('«مبروك! فزت بآيفون — ادفع رسوم التوصيل بس».', '«مبروك! ربحت آيفون — ادفع رسوم التوصيل فقط».', '"Congrats! You won an iPhone — just pay delivery".'), true,
          t('الجايزة الحقيقية ما بتطلب قروش.', 'الجائزة الحقيقية لا تطلب مالًا.', 'Real prizes do not ask for money.')),
      _Q(t('صفحة تبرعات للمتضررين بتطلب تحويل لحساب شخصي، وما فيها أي معلومة عن الجهة.', 'صفحة تبرعات للمتضررين تطلب التحويل لحساب شخصي دون أي معلومة عن الجهة.',
              'A donation page for victims asks for transfers to a personal account with no info about who runs it.'), true,
          t('اتبرع عن طريق جهة معروفة أو زول بتعرفه شخصيًا.', 'تبرّع عبر جهة معروفة أو شخص تعرفه شخصيًا.', 'Give through a known organisation or someone you personally know.')),
      _Q(t('رابط: https://faceb00k-login.com/verify', 'رابط: https://faceb00k-login.com/verify', 'Link: https://faceb00k-login.com/verify'), true,
          t('faceb00k بأصفار مش facebook — صفحة تصيّد.', 'faceb00k بأصفار وليس facebook — صفحة تصيّد.', 'faceb00k with zeros is not facebook — a phishing page.')),
      _Q(t('صاحبك اتصل بيك مكالمة صوت وقال ليك بعيد عن الرسايل إنه غيّر رقمه، وبعدها أضاف الرقم الجديد.',
              'اتصل بك صديقك مكالمة صوتية وأخبرك أنه غيّر رقمه، ثم أضاف الرقم الجديد.',
              'Your friend called you by voice to say they changed numbers, then added the new number.'), false,
          t('اتأكدت بصوته — ده الطريق الصاح للتأكد.', 'تأكدت بصوته — هذه هي الطريقة الصحيحة للتحقق.', 'You confirmed by voice — that is the right way to verify.')),
    ];

class FraudAlertsTool extends StatefulWidget {
  const FraudAlertsTool({super.key});
  @override
  State<FraudAlertsTool> createState() => _FraudAlertsToolState();
}

class _FraudAlertsToolState extends State<FraudAlertsTool> {
  int tab = 0;
  int qi = 0, score = 0;
  bool? answer;
  bool finished = false;

  void _answer(AppState s, bool saidScam) {
    if (answer != null) return;
    final q = _quiz[qi];
    setState(() {
      answer = saidScam;
      if (saidScam == q.scam) score++;
    });
  }

  void _next(AppState s) {
    if (qi + 1 >= _quiz.length) {
      final best = (s.getData<num>('fraud_alerts_best') ?? 0).toInt();
      if (score > best) s.setData('fraud_alerts_best', score);
      s.setData('fraud_alerts_games', (s.getData<num>('fraud_alerts_games') ?? 0).toInt() + 1);
      s.awardDaily('fraud_alerts_quiz', 10, t('اختبار الاحتيال', 'اختبار الاحتيال', 'Scam quiz'));
      setState(() => finished = true);
      return;
    }
    setState(() {
      qi++;
      answer = null;
    });
  }

  void _restart() => setState(() {
        qi = 0;
        score = 0;
        answer = null;
        finished = false;
      });

  String _card(_Scam sc) => [
        '⚠️ ${t('تنبيه احتيال', 'تنبيه احتيال', 'Scam alert')}: ${sc.emoji} ${sc.title}',
        sc.story,
        '',
        '🔎 ${t('العلامات', 'العلامات', 'Signs')}:',
        ...sc.signs.map((x) => '• $x'),
        '',
        '✅ ${t('اعمل شنو', 'ماذا تفعل', 'What to do')}:',
        ...sc.todo.map((x) => '• $x'),
      ].join('\n');

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return ToolList(children: [
      SegmentedButton<int>(
        segments: [
          ButtonSegment(value: 0, icon: const Icon(Icons.list_alt_rounded), label: Text(t('الأنواع', 'الأنواع', 'Scams'), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ButtonSegment(value: 1, icon: const Icon(Icons.quiz_rounded), label: Text(t('اختبر نفسك', 'اختبر نفسك', 'Quiz'), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
        selected: {tab},
        onSelectionChanged: (v) => setState(() => tab = v.first),
      ),
      const SizedBox(height: 14),
      if (tab == 0) ..._catalogue(context) else ..._quizView(context, s),
      const ReviewedLine('fraud_alerts'),
    ]);
  }

  List<Widget> _catalogue(BuildContext context) => [
        NoteBox(
            t('القاعدة الذهبية: أي زول بيستعجلك وبيطلب قروش أو كود أو بياناتك — وقّف واتأكد من طريق تاني.',
                'القاعدة الذهبية: أي جهة تستعجلك وتطلب مالًا أو كودًا أو بياناتك — توقف وتحقق بطريق آخر.',
                'Golden rule: anyone rushing you for money, a code or your details — stop and verify another way.'),
            kind: NoteKind.warn),
        for (final sc in _scams)
          SCard(
            title: '${sc.emoji}  ${sc.title}',
            color: sc.color,
            trailing: IconButton(
              tooltip: t('شارك التنبيه', 'مشاركة التنبيه', 'Share warning'),
              icon: const Icon(Icons.share_rounded),
              onPressed: () => SharePlus.instance.share(ShareParams(text: '${_card(sc)}\n\n— ${tr('من تطبيق أدوات أمير', 'via Ameer Tools app')} 🇸🇩')),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(sc.story, style: const TextStyle(fontStyle: FontStyle.italic, height: 1.45)),
              const SizedBox(height: 8),
              StepsExpander(title: t('كيف تعرفه؟', 'كيف تكتشفه؟', 'How to spot it'), steps: sc.signs, color: SD.orange, icon: Icons.search_rounded),
              StepsExpander(title: t('تعمل شنو؟', 'ماذا تفعل؟', 'What to do'), steps: sc.todo, color: SD.green, icon: Icons.task_alt_rounded),
              if (sc.id == 'phishing')
                OutlinedButton.icon(
                  onPressed: () => ToolPage.open(context, 'link_check'),
                  icon: const Icon(Icons.link_rounded),
                  label: Text(t('افتح فاحص الروابط', 'افتح فاحص الروابط', 'Open Link Checker'), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              if (sc.id == 'charity')
                OutlinedButton.icon(
                  onPressed: () => ToolPage.open(context, 'news_check'),
                  icon: const Icon(Icons.fact_check_rounded),
                  label: Text(t('افتح التحقق من الأخبار', 'افتح التحقق من الأخبار', 'Open News Verification'), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ]),
          ),
        NoteBox(
            t('لو اتعرضت لاحتيال: بلّغ البنك طوالي واطلب إيقاف العملية، واحفظ الرسايل والأرقام، وبلّغ الشرطة/الجهة المختصة في بلدك.',
                'إن تعرضت لاحتيال: أبلغ البنك فورًا واطلب إيقاف العملية، واحتفظ بالرسائل والأرقام، وأبلغ الشرطة أو الجهة المختصة في بلدك.',
                'If you were scammed: tell your bank right away to stop the transaction, keep the messages and numbers, and report to the police or relevant authority in your country.'),
            kind: NoteKind.info),
      ];

  List<Widget> _quizView(BuildContext context, AppState s) {
    final best = (s.getData<num>('fraud_alerts_best') ?? 0).toInt();
    final games = (s.getData<num>('fraud_alerts_games') ?? 0).toInt();
    final n = _quiz.length;
    if (finished) {
      final pct = (score * 100 / n).round();
      return [
        ResultHero(
          label: t('نتيجتك', 'نتيجتك', 'Your score'),
          value: '$score / $n',
          sub: pct >= 90
              ? t('عينك مفتّحة — صعب يضحكوا عليك 👏', 'يقظ جدًا — يصعب خداعك 👏', 'Sharp eye — hard to fool 👏')
              : pct >= 60
                  ? t('كويس، بس راجع الأنواع تاني', 'جيد، لكن راجع الأنواع مرة أخرى', 'Good — review the scam types again')
                  : t('محتاج تراجع الأنواع كويس', 'تحتاج مراجعة الأنواع جيدًا', 'You should review the scam types'),
        ),
        StatGrid([
          StatChip('$best/$n', t('أحسن نتيجة', 'أفضل نتيجة', 'Best score'), color: SD.gold, icon: Icons.emoji_events_rounded),
          StatChip('$games', t('مرات اللعب', 'مرات اللعب', 'Games played'), color: SD.nile, icon: Icons.replay_rounded),
          StatChip('$pct%', t('الدقة', 'الدقة', 'Accuracy'), color: SD.green, icon: Icons.percent_rounded),
        ]),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _restart, icon: const Icon(Icons.replay_rounded), label: Text(t('العب تاني', 'العب مجددًا', 'Play again'))),
        const SizedBox(height: 12),
        ShareBar(() => t('جبت $score من $n في اختبار «ده احتيال ولا لا؟» 🛡️ — جرّبه إنت كمان!', 'حصلت على $score من $n في اختبار «هل هذا احتيال؟» 🛡️ — جرّبه أنت أيضًا!',
            'I scored $score/$n on the "Is this a scam?" quiz 🛡️ — try it too!')),
      ];
    }
    final q = _quiz[qi];
    final correct = answer != null && answer == q.scam;
    return [
      SafetyProgress('${t('سؤال', 'سؤال', 'Question')} ${qi + 1} ${t('من', 'من', 'of')} $n', qi + (answer == null ? 0 : 1), n, color: SD.gold),
      SCard(
        title: t('ده احتيال ولا لا؟', 'هل هذا احتيال؟', 'Is this a scam?'),
        icon: Icons.help_rounded,
        color: SD.purple,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(q.text, style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: SD.red, foregroundColor: Colors.white),
                onPressed: answer == null ? () => _answer(s, true) : null,
                icon: const Icon(Icons.dangerous_rounded),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('احتيال', 'احتيال', 'Scam'))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: SD.green, foregroundColor: Colors.white),
                onPressed: answer == null ? () => _answer(s, false) : null,
                icon: const Icon(Icons.verified_rounded),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(t('سليم', 'سليم', 'Legit'))),
              ),
            ),
          ]),
          if (answer != null) ...[
            const SizedBox(height: 12),
            NoteBox(
              '${correct ? t('صاح! ✓', 'إجابة صحيحة ✓', 'Correct ✓') : t('غلط ✗', 'إجابة خاطئة ✗', 'Wrong ✗')} — '
              '${q.scam ? t('ده احتيال.', 'هذا احتيال.', 'This is a scam.') : t('ده سليم.', 'هذا سليم.', 'This is legit.')} ${q.why}',
              kind: correct ? NoteKind.tip : NoteKind.danger,
            ),
            FilledButton.icon(
              onPressed: () => _next(s),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(qi + 1 >= n ? t('النتيجة', 'النتيجة', 'See result') : t('اللي بعده', 'التالي', 'Next')),
            ),
          ],
        ]),
      ),
      StatGrid([
        StatChip('$score', t('صاح', 'صحيحة', 'Correct'), color: SD.green, icon: Icons.check_rounded),
        StatChip('$best/$n', t('أحسن نتيجة', 'أفضل نتيجة', 'Best'), color: SD.gold, icon: Icons.emoji_events_rounded),
      ], columns: 2),
    ];
  }
}
