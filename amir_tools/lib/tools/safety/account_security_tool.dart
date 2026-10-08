import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../screens/tool_page.dart';
import 'safety_common.dart';

class _Item {
  final String id, title;
  final List<String> steps;
  const _Item(this.id, this.title, this.steps);
}

class _Group {
  final String id, title;
  final IconData icon;
  final Color color;
  final List<_Item> items;
  const _Group(this.id, this.title, this.icon, this.color, this.items);
}

List<_Group> get _groups => [
      _Group('whatsapp', tr('واتساب', 'WhatsApp'), Icons.chat_rounded, SD.green, [
        _Item('wa_2sv', t('شغّل التحقق بخطوتين (رمز PIN)', 'فعّل التحقق بخطوتين (رمز PIN)', 'Turn on two-step verification (PIN)'), [
          t('افتح واتساب ← الإعدادات ← الحساب ← التحقق بخطوتين ← تفعيل.', 'افتح واتساب ← الإعدادات ← الحساب ← التحقق بخطوتين ← تفعيل.',
              'Open WhatsApp → Settings → Account → Two-step verification → Turn on.'),
          t('اختار رمز من 6 أرقام بتحفظه — ما تختار سنة ميلادك ولا 123456.', 'اختر رمزًا من 6 أرقام تحفظه — لا تختر سنة ميلادك ولا 123456.',
              'Pick a 6-digit PIN you will remember — not your birth year or 123456.'),
          t('ضيف إيميلك عشان لو نسيت الرمز تقدر ترجّعه.', 'أضف بريدك الإلكتروني لتستعيد الرمز إن نسيته.', 'Add your email so you can reset the PIN if you forget it.'),
          t('بكدا حتى لو زول أخد كود الرسالة ما بيقدر يفتح حسابك بدون الرمز ده.', 'بذلك حتى لو حصل أحد على كود الرسالة لن يفتح حسابك دون هذا الرمز.',
              'Now even if someone gets your SMS code, they cannot register your account without this PIN.'),
        ]),
        _Item('wa_code', t('ما تدّي زول كود التفعيل (6 أرقام)', 'لا تعطِ أحدًا كود التفعيل (6 أرقام)', 'Never share the 6-digit code'), [
          t('الكود البيجيك في رسالة من واتساب ليك إنت بس.', 'الكود الذي يصلك في رسالة من واتساب لك وحدك.', 'The code WhatsApp sends you by SMS is for you only.'),
          t('لو صاحبك ولا «موظف واتساب» طلبه منك — ده احتيال، حتى لو الرسالة من رقم بتعرفه (ممكن يكون اتسرق).',
              'إن طلبه صديق أو «موظف واتساب» فهذا احتيال، حتى لو كانت الرسالة من رقم تعرفه (ربما سُرق).',
              'If a friend or "WhatsApp staff" asks for it, it is a scam — even from a number you know (it may be hacked).'),
          t('أي زول عنده الكود بيقدر يشيل حسابك ويراسل أهلك باسمك.', 'من يملك الكود يستطيع الاستيلاء على حسابك ومراسلة أهلك باسمك.',
              'Whoever has the code can take over your account and message your family as you.'),
        ]),
        _Item('wa_devices', t('راجع «الأجهزة المرتبطة»', 'راجع «الأجهزة المرتبطة»', 'Check "Linked devices"'), [
          t('الإعدادات ← الأجهزة المرتبطة (أو من قائمة ⋮).', 'الإعدادات ← الأجهزة المرتبطة (أو من قائمة ⋮).', 'Settings → Linked devices (or from the ⋮ menu).'),
          t('أي كمبيوتر أو متصفح ما بتعرفه: دوس عليه ← تسجيل الخروج.', 'أي حاسوب أو متصفح لا تعرفه: اضغط عليه ← تسجيل الخروج.',
              'Any computer or browser you do not recognise: tap it → Log out.'),
        ]),
        _Item('wa_privacy', t('ضبط الخصوصية', 'ضبط الخصوصية', 'Tighten privacy'), [
          t('الإعدادات ← الخصوصية ← المجموعات ← «جهات اتصالي» عشان الغرباء ما يضيفوك لقروبات نصب.',
              'الإعدادات ← الخصوصية ← المجموعات ← «جهات اتصالي» حتى لا يضيفك الغرباء لمجموعات احتيال.',
              'Settings → Privacy → Groups → "My contacts" so strangers cannot add you to scam groups.'),
          t('خلّي صورة الملف و«الأخبار/النبذة» لجهات اتصالك بس.', 'اجعل صورة الملف والنبذة لجهات اتصالك فقط.', 'Set profile photo and About to "My contacts".'),
          t('في الخصوصية ← المكالمات: شغّل «إسكات المتصلين المجهولين» لو بتجيك مكالمات نصب.',
              'في الخصوصية ← المكالمات: فعّل «إسكات المتصلين غير المعروفين» إن كانت تصلك مكالمات احتيال.',
              'Privacy → Calls: turn on "Silence unknown callers" if you get scam calls.'),
        ]),
      ]),
      _Group('meta', tr('فيسبوك وإنستغرام', 'Facebook & Instagram'), Icons.facebook_rounded, SD.nile, [
        _Item('fb_2fa', t('شغّل المصادقة الثنائية في فيسبوك', 'فعّل المصادقة الثنائية في فيسبوك', 'Turn on two-factor authentication on Facebook'), [
          t('القائمة ← الإعدادات والخصوصية ← الإعدادات ← مركز الحسابات.', 'القائمة ← الإعدادات والخصوصية ← الإعدادات ← مركز الحسابات.',
              'Menu → Settings & privacy → Settings → Accounts Center.'),
          t('كلمة السر والأمان ← المصادقة الثنائية ← اختار حسابك.', 'كلمة السر والأمان ← المصادقة الثنائية ← اختر حسابك.',
              'Password and security → Two-factor authentication → choose your account.'),
          t('الأحسن تختار «تطبيق المصادقة» بدل الرسائل لو قدرت، واحفظ «رموز الاسترداد» في مكان أمين.',
              'الأفضل اختيار «تطبيق المصادقة» بدل الرسائل إن أمكن، واحفظ «رموز الاسترداد» في مكان آمن.',
              'Prefer an authentication app over SMS if you can, and keep the recovery codes somewhere safe.'),
        ]),
        _Item('fb_sessions', t('شوف وين حسابك فاتح', 'راجع أين سُجّل دخولك', 'Check where you are logged in'), [
          t('مركز الحسابات ← كلمة السر والأمان ← «مكان تسجيل الدخول».', 'مركز الحسابات ← كلمة السر والأمان ← «مكان تسجيل الدخول».',
              'Accounts Center → Password and security → "Where you\'re logged in".'),
          t('اطلع من أي جهاز أو مكان ما بتعرفه.', 'سجّل الخروج من أي جهاز أو مكان لا تعرفه.', 'Log out of any device or location you do not recognise.'),
        ]),
        _Item('fb_alerts', t('شغّل تنبيهات تسجيل الدخول', 'فعّل تنبيهات تسجيل الدخول', 'Turn on login alerts'), [
          t('مركز الحسابات ← كلمة السر والأمان ← تنبيهات تسجيل الدخول.', 'مركز الحسابات ← كلمة السر والأمان ← تنبيهات تسجيل الدخول.',
              'Accounts Center → Password and security → Login alerts.'),
          t('بكدا بتعرف طوالي لو زول دخل حسابك من جهاز جديد.', 'هكذا تعرف فورًا إن دخل أحد حسابك من جهاز جديد.', 'You will know right away if someone logs in from a new device.'),
        ]),
        _Item('ig_2fa', t('شغّل المصادقة الثنائية في إنستغرام', 'فعّل المصادقة الثنائية في إنستغرام', 'Turn on two-factor authentication on Instagram'), [
          t('صفحتك الشخصية ← القائمة ☰ ← مركز الحسابات.', 'ملفك الشخصي ← القائمة ☰ ← مركز الحسابات.', 'Your profile → ☰ menu → Accounts Center.'),
          t('كلمة السر والأمان ← المصادقة الثنائية ← اختار حساب إنستغرام.', 'كلمة السر والأمان ← المصادقة الثنائية ← اختر حساب إنستغرام.',
              'Password and security → Two-factor authentication → pick your Instagram account.'),
        ]),
      ]),
      _Group('google', tr('جيميل وحساب Google', 'Gmail & Google account'), Icons.mail_rounded, SD.red, [
        _Item('g_2sv', t('شغّل «التحقق بخطوتين»', 'فعّل «التحقق بخطوتين»', 'Turn on 2-Step Verification'), [
          t('افتح myaccount.google.com (أو الإعدادات ← Google ← إدارة حسابك).', 'افتح myaccount.google.com (أو الإعدادات ← Google ← إدارة حسابك).',
              'Open myaccount.google.com (or Settings → Google → Manage your account).'),
          t('الأمان ← التحقق بخطوتين ← ابدأ واتّبع الخطوات.', 'الأمان ← التحقق بخطوتين ← ابدأ واتّبع الخطوات.', 'Security → 2-Step Verification → Get started and follow the steps.'),
          t('إيميلك هو مفتاح كل حساباتك — لو اتسرق بيقدروا يغيّروا كلمات سر الباقي.', 'بريدك هو مفتاح بقية حساباتك — إن سُرق أمكنهم تغيير كلمات سر البقية.',
              'Your email is the key to all your other accounts — if it is stolen, they can reset the rest.'),
        ]),
        _Item('g_recovery', t('ضيف رقم وإيميل الاسترداد', 'أضف رقم وبريد الاسترداد', 'Add a recovery phone & email'), [
          t('في صفحة الأمان: «طرق التحقق من هويتك» ← رقم الهاتف وإيميل الاسترداد.', 'في صفحة الأمان: «طرق التحقق من هويتك» ← هاتف وبريد الاسترداد.',
              'On the Security page: "How you sign in / ways to verify it\'s you" → recovery phone and email.'),
          t('خلّيهم محدّثين — لو غيّرت شريحتك حدّث الرقم طوالي.', 'أبقِهما محدّثين — إن غيّرت شريحتك حدّث الرقم فورًا.', 'Keep them current — update the number as soon as you change SIM.'),
        ]),
        _Item('g_checkup', t('اعمل «فحص الأمان»', 'أجرِ «فحص الأمان»', 'Run the Security Checkup'), [
          t('افتح myaccount.google.com/security-checkup.', 'افتح myaccount.google.com/security-checkup.', 'Open myaccount.google.com/security-checkup.'),
          t('بيوريك الأجهزة والتطبيقات الليها صلاحية على حسابك — شيل أي حاجة ما بتعرفها.', 'يعرض الأجهزة والتطبيقات التي لها صلاحية على حسابك — احذف ما لا تعرفه.',
              'It lists devices and apps with access to your account — remove anything you do not recognise.'),
        ]),
        _Item('g_devices', t('راجع «أجهزتك»', 'راجع «أجهزتك»', 'Review "Your devices"'), [
          t('الأمان ← أجهزتك ← إدارة كل الأجهزة.', 'الأمان ← أجهزتك ← إدارة جميع الأجهزة.', 'Security → Your devices → Manage all devices.'),
          t('اطلع من أي جهاز قديم أو ما بتعرفه.', 'سجّل الخروج من أي جهاز قديم أو مجهول.', 'Sign out of any old or unknown device.'),
        ]),
      ]),
      _Group('bank', t('تطبيقات البنك والمحافظ', 'تطبيقات البنوك والمحافظ', 'Bank & wallet apps'), Icons.account_balance_rounded, SD.gold, [
        _Item('bk_official', t('نزّل التطبيق من المتجر الرسمي بس', 'ثبّت التطبيق من المتجر الرسمي فقط', 'Install only from the official store'), [
          t('Google Play أو App Store، أو الرابط الموجود في موقع البنك الرسمي.', 'Google Play أو App Store، أو الرابط في موقع البنك الرسمي.',
              'Google Play or the App Store, or the link on the bank\'s official website.'),
          t('اتأكد من اسم الناشر (البنك نفسه) وما تنزّل ملف APK رسّلوه ليك في واتساب.', 'تحقق من اسم الناشر (البنك نفسه) ولا تثبّت ملف APK أُرسل لك عبر واتساب.',
              'Check the publisher is the bank itself, and never install an APK file sent over WhatsApp.'),
        ]),
        _Item('bk_lock', t('قفل التطبيق برمز أو بصمة', 'قفل التطبيق برمز أو بصمة', 'Lock the app with a PIN or fingerprint'), [
          t('شغّل رمز الدخول/البصمة من إعدادات التطبيق.', 'فعّل رمز الدخول أو البصمة من إعدادات التطبيق.', 'Enable the app PIN or biometrics in its settings.'),
          t('ما تكتب كلمة السر في الملاحظات ولا تدّي تلفونك مفتوح لزول.', 'لا تكتب كلمة السر في الملاحظات ولا تعطِ هاتفك مفتوحًا لأحد.',
              'Do not keep the password in your notes or hand over your phone unlocked.'),
        ]),
        _Item('bk_never', t('ما تدّي زول الرمز السري ولا كود OTP', 'لا تعطِ أحدًا الرمز السري ولا كود OTP', 'Never share your PIN or OTP'), [
          t('البنك ما بيطلب منك الرمز السري ولا كود التحقق ولا رقم البطاقة الكامل في تلفون أو واتساب.',
              'البنك لا يطلب منك الرمز السري ولا كود التحقق ولا رقم البطاقة كاملًا عبر الهاتف أو واتساب.',
              'Banks do not ask for your PIN, one-time code or full card number by phone or WhatsApp.'),
          t('لو اتصل بيك «موظف بنك» اقفل الخط واتصل إنت على الرقم الرسمي الموجود في البطاقة أو موقع البنك.',
              'إن اتصل بك «موظف بنك» فأغلق الخط واتصل أنت على الرقم الرسمي المطبوع على البطاقة أو في موقع البنك.',
              'If a "bank employee" calls, hang up and call the official number on your card or the bank\'s website yourself.'),
        ]),
        _Item('bk_alerts', t('شغّل إشعارات كل عملية', 'فعّل إشعارات كل عملية', 'Turn on alerts for every transaction'), [
          t('شغّل رسائل SMS أو إشعارات التطبيق لكل تحويل وسحب.', 'فعّل رسائل SMS أو إشعارات التطبيق لكل تحويل وسحب.', 'Enable SMS or app notifications for every transfer and withdrawal.'),
          t('أي عملية ما بتعرفها: كلّم البنك طوالي واطلب إيقاف البطاقة/الحساب.', 'أي عملية لا تعرفها: اتصل بالبنك فورًا واطلب إيقاف البطاقة أو الحساب.',
              'Any transaction you do not recognise: call the bank immediately and ask to freeze the card/account.'),
        ]),
        _Item('bk_receipt', t('اتأكد من التحويل في رصيدك، ما من صورة الإشعار', 'تحقق من التحويل في رصيدك لا من صورة الإشعار', 'Confirm transfers in your balance, not a screenshot'), [
          t('صور إشعارات التحويل بتتزوّر بسهولة — افتح تطبيقك وشوف الرصيد أو كشف الحساب.', 'صور إشعارات التحويل تُزوَّر بسهولة — افتح تطبيقك وراجع الرصيد أو الكشف.',
              'Transfer screenshots are easy to fake — open your own app and check the balance or statement.'),
        ]),
      ]),
      _Group('phone', t('تلفونك', 'هاتفك', 'Your phone'), Icons.smartphone_rounded, SD.indigo, [
        _Item('ph_lock', t('قفل الشاشة برمز قوي', 'قفل الشاشة برمز قوي', 'Strong screen lock'), [
          t('الإعدادات ← الأمان (أو قفل الشاشة) ← رمز PIN من 6 أرقام أو كلمة سر، مع البصمة أو الوجه.',
              'الإعدادات ← الأمان (أو قفل الشاشة) ← رمز PIN من 6 أرقام أو كلمة سر، مع البصمة أو الوجه.',
              'Settings → Security (or Screen lock) → a 6-digit PIN or a password, plus fingerprint/face.'),
          t('بلاش 1234 ولا 0000 ولا رسمة سهلة زي حرف L أو Z.', 'تجنّب 1234 و0000 والأنماط السهلة مثل حرف L أو Z.', 'Avoid 1234, 0000 and easy patterns like an L or Z shape.'),
        ]),
        _Item('ph_find', t('شغّل «العثور على جهازي»', 'فعّل «العثور على جهازي»', 'Turn on Find My Device'), [
          t('أندرويد: Find My Device من Google. آيفون: «تحديد الموقع» (Find My).', 'أندرويد: Find My Device من Google. آيفون: «تحديد الموقع» (Find My).',
              'Android: Google Find My Device. iPhone: Find My.'),
          t('لو التلفون ضاع أو اتسرق بتقدر تقفله أو تمسح بياناته من بعيد.', 'إن ضاع الهاتف أو سُرق تستطيع قفله أو مسح بياناته عن بُعد.',
              'If the phone is lost or stolen you can lock or erase it remotely.'),
        ]),
        _Item('ph_updates', t('حدّث النظام والتطبيقات', 'حدّث النظام والتطبيقات', 'Keep system & apps updated'), [
          t('التحديثات بتسد ثغرات أمنية — ما تأجّلها كتير.', 'التحديثات تسد ثغرات أمنية — لا تؤجلها كثيرًا.', 'Updates close security holes — do not postpone them for long.'),
        ]),
        _Item('ph_apk', t('ما تنزّل تطبيقات من رسائل', 'لا تثبّت تطبيقات من الرسائل', 'No apps from messages'), [
          t('ملفات APK الجاية في واتساب أو تيليجرام ممكن تقرأ رسائلك وأكواد البنك.', 'ملفات APK الواردة عبر واتساب أو تيليجرام قد تقرأ رسائلك وأكواد البنك.',
              'APK files sent via WhatsApp or Telegram can read your messages and bank codes.'),
          t('راجع الصلاحيات: أي تطبيق غريب عنده صلاحية «الرسائل» أو «تسهيل الاستخدام» (Accessibility) امسحه.',
              'راجع الأذونات: أي تطبيق غريب لديه إذن «الرسائل» أو «إمكانية الوصول» احذفه.',
              'Check permissions: remove any unknown app with SMS or Accessibility access.'),
        ]),
        _Item('ph_backup', t('اعمل نسخة احتياطية', 'أنشئ نسخة احتياطية', 'Back up your data'), [
          t('واتساب: الإعدادات ← الدردشات ← النسخ الاحتياطي (Google Drive أو iCloud).', 'واتساب: الإعدادات ← الدردشات ← النسخ الاحتياطي (Google Drive أو iCloud).',
              'WhatsApp: Settings → Chats → Chat backup (Google Drive or iCloud).'),
          t('والصور والأرقام كمان — عشان لو التلفون راح ما تفقد حاجة.', 'والصور وجهات الاتصال أيضًا — حتى لا تفقد شيئًا إن ضاع الهاتف.',
              'Photos and contacts too — so you lose nothing if the phone is gone.'),
        ]),
      ]),
      _Group('sim', t('الشريحة (SIM)', 'الشريحة (SIM)', 'SIM card'), Icons.sim_card_rounded, SD.henna, [
        _Item('sim_pin', t('شغّل رمز PIN للشريحة', 'فعّل رمز PIN للشريحة', 'Turn on SIM PIN'), [
          t('أندرويد: الإعدادات ← الأمان (أو إعدادات أمان إضافية) ← قفل شريحة SIM.', 'أندرويد: الإعدادات ← الأمان (أو إعدادات أمان إضافية) ← قفل شريحة SIM.',
              'Android: Settings → Security (or More security settings) → SIM card lock.'),
          t('آيفون: الإعدادات ← الخلوي/بيانات الجوال ← رمز PIN للشريحة.', 'آيفون: الإعدادات ← الخلوي ← رمز PIN للشريحة.', 'iPhone: Settings → Mobile/Cellular → SIM PIN.'),
          t('محتاج الرمز الحالي (غالبًا مكتوب في كرت الشريحة من الشركة). 3 محاولات غلط بتقفل الشريحة وبتحتاج كود PUK من الشركة.',
              'تحتاج الرمز الحالي (غالبًا مطبوع على بطاقة الشريحة من الشركة). 3 محاولات خاطئة تقفل الشريحة وتحتاج كود PUK من الشركة.',
              'You need the current PIN (often printed on the SIM holder card). 3 wrong tries lock the SIM and you will need the PUK code from your operator.'),
          t('الفايدة: لو تلفونك اتسرق ما بيقدروا يستعملوا شريحتك في تلفون تاني ويستلموا أكوادك.',
              'الفائدة: إن سُرق هاتفك لا يستطيعون استخدام شريحتك في هاتف آخر واستلام أكوادك.',
              'Why: if your phone is stolen, they cannot put your SIM in another phone to receive your codes.'),
        ]),
        _Item('sim_swap', t('انتبه لو الشبكة قطعت فجأة', 'انتبه إن انقطعت الشبكة فجأة', 'Watch for sudden "No service"'), [
          t('لو الشبكة قطعت فترة طويلة بدون سبب، كلّم شركة الاتصالات — ممكن زول نقل رقمك لشريحة تانية.',
              'إن انقطعت الشبكة مدة طويلة دون سبب، اتصل بشركة الاتصالات — ربما نقل أحدهم رقمك إلى شريحة أخرى.',
              'If you lose signal for a long time for no reason, call your operator — someone may have moved your number to another SIM.'),
        ]),
      ]),
      _Group('telegram', tr('تيليجرام', 'Telegram'), Icons.send_rounded, SD.teal, [
        _Item('tg_2sv', t('شغّل كلمة سر التحقق بخطوتين', 'فعّل كلمة سر التحقق بخطوتين', 'Turn on two-step verification password'), [
          t('الإعدادات ← الخصوصية والأمان ← التحقق بخطوتين ← عيّن كلمة سر وإيميل استرداد.', 'الإعدادات ← الخصوصية والأمان ← التحقق بخطوتين ← عيّن كلمة سر وبريد استرداد.',
              'Settings → Privacy and Security → Two-Step Verification → set a password and recovery email.'),
        ]),
        _Item('tg_sessions', t('راجع الأجهزة', 'راجع الأجهزة', 'Review devices'), [
          t('الإعدادات ← الأجهزة ← أنهِ أي جلسة ما بتعرفها.', 'الإعدادات ← الأجهزة ← أنهِ أي جلسة لا تعرفها.', 'Settings → Devices → terminate any session you do not recognise.'),
        ]),
      ]),
    ];

class AccountSecurityTool extends StatefulWidget {
  const AccountSecurityTool({super.key});
  @override
  State<AccountSecurityTool> createState() => _AccountSecurityToolState();
}

class _AccountSecurityToolState extends State<AccountSecurityTool> {
  void _toggle(AppState s, String id, bool v) {
    final done = strList(s.getData('account_security_done'));
    done.remove(id);
    if (v) done.add(id);
    s.setData('account_security_done', done);
    if (v) {
      s.awardDaily('account_security_$id', 5, t('أمّنت حسابك', 'تأمين حساب', 'Secured an account'));
      final groups = _groups;
      final skip = strList(s.getData('account_security_skip'));
      final all = [for (final g in groups) if (!skip.contains(g.id)) ...g.items.map((i) => i.id)];
      if (all.isNotEmpty && all.every(done.contains) && s.getData('account_security_full') != true) {
        s.setData('account_security_full', true);
        s.award(30, t('أمان كامل لحساباتك', 'اكتمال تأمين الحسابات', 'All accounts secured'));
        toast(t('ما شاء الله! حساباتك أمّنتها كلها 🛡️', 'ممتاز! أكملت تأمين حساباتك 🛡️', 'Great! All your accounts are secured 🛡️'));
      }
    }
  }

  void _toggleSkip(AppState s, String gid) {
    final skip = strList(s.getData('account_security_skip'));
    skip.contains(gid) ? skip.remove(gid) : skip.add(gid);
    s.setData('account_security_skip', skip);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final done = strList(s.getData('account_security_done')).toSet();
    final skip = strList(s.getData('account_security_skip')).toSet();
    final groups = _groups;
    final active = groups.where((g) => !skip.contains(g.id)).toList();
    final total = active.fold<int>(0, (a, g) => a + g.items.length);
    final got = active.fold<int>(0, (a, g) => a + g.items.where((i) => done.contains(i.id)).length);
    final pct = total == 0 ? 0 : (got * 100 / total).round();
    final (label, colors) = pct >= 85
        ? (t('حماية ممتازة 💪', 'حماية ممتازة 💪', 'Excellent protection 💪'), const [Color(0xFF0B6B32), Color(0xFF075226), Color(0xFF033815)])
        : pct >= 50
            ? (t('كويس — كمّل الباقي', 'جيد — أكمل الباقي', 'Good — finish the rest'), null)
            : (t('حساباتك محتاجة حماية', 'حساباتك تحتاج حماية', 'Your accounts need protection'), const [Color(0xFF9A2A1A), Color(0xFF6E1D12), Color(0xFF45110A)]);
    final missing = [
      for (final g in active)
        for (final i in g.items)
          if (!done.contains(i.id)) '• ${g.title}: ${i.title}',
    ];

    return ToolList(children: [
      ResultHero(label: t('درجة أمان حساباتك', 'درجة أمان حساباتك', 'Your account security score'), value: '$pct%', sub: '$label — $got/$total', colors: colors),
      SCard(
        title: t('التقدّم حسب المنصة', 'التقدّم حسب المنصة', 'Progress by platform'),
        icon: Icons.insights_rounded,
        child: Column(children: [
          for (final g in active) SafetyProgress(g.title, g.items.where((i) => done.contains(i.id)).length, g.items.length, color: g.color),
          if (skip.isNotEmpty)
            Text(t('مخفي (ما بتستعمله): ${groups.where((g) => skip.contains(g.id)).map((g) => g.title).join('، ')}',
                'مخفي (لا تستخدمه): ${groups.where((g) => skip.contains(g.id)).map((g) => g.title).join('، ')}',
                'Hidden (not used): ${groups.where((g) => skip.contains(g.id)).map((g) => g.title).join(', ')}'),
                style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))),
        ]),
      ),
      NoteBox(
          t('أسماء القوائم بتختلف شوية حسب نسخة التطبيق ونوع التلفون — لو ما لقيت الخيار بالاسم ده، دوّر عليه في «الإعدادات» أو «الأمان».',
              'أسماء القوائم تختلف قليلًا حسب إصدار التطبيق ونوع الهاتف — إن لم تجد الخيار بهذا الاسم فابحث عنه في «الإعدادات» أو «الأمان».',
              'Menu names vary a bit by app version and phone model — if you cannot find an option by this name, look under Settings or Security.'),
          kind: NoteKind.info),
      for (final g in groups)
        SCard(
          title: g.title,
          icon: g.icon,
          color: g.color,
          trailing: TextButton(
            onPressed: () => _toggleSkip(s, g.id),
            child: Text(skip.contains(g.id) ? t('أظهر', 'إظهار', 'Show') : t('ما بستعمله', 'لا أستخدمه', 'Not used'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          child: skip.contains(g.id)
              ? Text(t('مخفية من الدرجة.', 'مستبعدة من الدرجة.', 'Excluded from the score.'))
              : Column(children: [
                  for (final i in g.items)
                    CheckItemTile(title: i.title, steps: i.steps, done: done.contains(i.id), color: g.color, onChanged: (v) => _toggle(s, i.id, v)),
                ]),
        ),
      SCard(
        title: t('كلمات سر قوية', 'كلمات سر قوية', 'Strong passwords'),
        icon: Icons.password_rounded,
        color: SD.indigo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final tip in [
            t('طويلة: 12 حرف أو أكتر — جملة من كم كلمة أسهل في الحفظ وأصعب في الكسر.', 'طويلة: 12 حرفًا أو أكثر — عبارة من عدة كلمات أسهل حفظًا وأصعب كسرًا.',
                'Long: 12+ characters — a phrase of several words is easier to remember and harder to crack.'),
            t('كلمة سر مختلفة لكل حساب مهم، خصوصًا الإيميل والبنك.', 'كلمة سر مختلفة لكل حساب مهم، خصوصًا البريد والبنك.', 'A different password for every important account, especially email and bank.'),
            t('ما تستعمل اسمك ولا رقم تلفونك ولا تاريخ ميلادك.', 'لا تستخدم اسمك أو رقم هاتفك أو تاريخ ميلادك.', 'Never use your name, phone number or birth date.'),
            t('مدير كلمات السر (زي الموجود في Google أو iCloud) بيحفظها ليك بأمان.', 'مدير كلمات السر (مثل المدمج في Google أو iCloud) يحفظها لك بأمان.',
                'A password manager (like the one built into Google or iCloud) stores them safely.'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.check_circle_rounded, size: 18, color: SD.green),
                const SizedBox(width: 8),
                Expanded(child: Text(tip, style: const TextStyle(height: 1.45))),
              ]),
            ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () => ToolPage.open(context, 'password'),
            icon: const Icon(Icons.password_rounded),
            label: Text(t('افتح أداة «كلمات السر» (مولّد وفاحص)', 'افتح أداة «كلمات السر» (مولّد وفاحص)', 'Open the "Passwords" tool (generator & checker)'),
                maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ),
        ]),
      ),
      SCard(
        title: t('حسابك اتسرق؟ اعمل كدا', 'سُرق حسابك؟ افعل هذا', 'Hacked? Do this'),
        icon: Icons.emergency_rounded,
        color: SD.red,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final h in _hacked) StepsExpander(title: h.$1, steps: h.$2, color: SD.red, extra: h.$3),
          NoteBox(
              t('ما تدفع لأي زول بيقول ليك برجّع حسابك مقابل قروش — ده احتيال تاني.', 'لا تدفع لمن يعدك باسترجاع حسابك مقابل المال — هذا احتيال آخر.',
                  'Never pay anyone who promises to recover your account for money — that is another scam.'),
              kind: NoteKind.danger),
        ]),
      ),
      if (missing.isNotEmpty)
        SCard(
          title: t('الباقي عليك', 'المتبقي عليك', 'Still to do'),
          icon: Icons.pending_actions_rounded,
          color: SD.orange,
          child: Text(missing.take(8).join('\n') + (missing.length > 8 ? '\n… +${missing.length - 8}' : ''), style: const TextStyle(height: 1.5)),
        ),
      ShareBar(() => [
            '🛡️ ${t('درجة أمان حساباتي', 'درجة أمان حساباتي', 'My account security score')}: $pct% ($got/$total)',
            if (missing.isNotEmpty) ...[t('الباقي:', 'المتبقي:', 'To do:'), ...missing],
            '',
            t('نصيحة: شغّل التحقق بخطوتين في واتساب وما تدّي زول كود الـ 6 أرقام.', 'نصيحة: فعّل التحقق بخطوتين في واتساب ولا تعطِ أحدًا كود الأرقام الستة.',
                'Tip: turn on WhatsApp two-step verification and never share the 6-digit code.'),
          ].join('\n')),
      const SizedBox(height: 8),
      const ReviewedLine('account_security'),
    ]);
  }

  List<(String, List<String>, Widget?)> get _hacked => [
        (
          tr('واتساب', 'WhatsApp'),
          [
            t('ثبّت واتساب (أو افتحه) وسجّل برقمك من جديد، وأدخل الكود الجايك في SMS — ده بيطلّع الزول من حسابك.',
                'افتح واتساب وسجّل برقمك من جديد وأدخل الكود الوارد في SMS — هذا يُخرج المخترق من حسابك.',
                'Open WhatsApp, register your number again and enter the SMS code — this logs the intruder out.'),
            t('لو طلب منك رمز «التحقق بخطوتين» وإنت ما عملته، يعني الحرامي عمله — في الحالة دي ممكن تحتاج تنتظر 7 أيام قبل ما تقدر تسجّل بدون الرمز.',
                'إن طُلب منك رمز «التحقق بخطوتين» ولم تضعه أنت، فالمخترق وضعه — قد تحتاج حينها للانتظار 7 أيام قبل التسجيل دون الرمز.',
                'If it asks for a two-step PIN you never set, the intruder set it — you may need to wait 7 days before you can register without it.'),
            t('تواصل مع دعم واتساب من: الإعدادات ← المساعدة ← اتصل بنا.', 'تواصل مع دعم واتساب من: الإعدادات ← المساعدة ← اتصل بنا.',
                'Contact WhatsApp support from Settings → Help → Contact us.'),
            t('بعد ما ترجع: شغّل التحقق بخطوتين وراجع الأجهزة المرتبطة.', 'بعد الاستعادة: فعّل التحقق بخطوتين وراجع الأجهزة المرتبطة.',
                'Once back in: turn on two-step verification and check linked devices.'),
          ],
          null,
        ),
        (
          t('نبّه أهلك ومعارفك', 'نبّه أهلك ومعارفك', 'Warn your contacts'),
          [
            t('أرسل ليهم من رقم تاني أو حالة/بوست: «حسابي اتسرق — ما تحوّلوا قروش لأي زول باسمي».', 'أرسل لهم من رقم آخر أو حالة/منشور: «حسابي مخترق — لا تحوّلوا مالًا لأحد باسمي».',
                'Message them from another number or post a status: "My account was hacked — do not send money to anyone using my name."'),
            t('الحرامية غالبًا بيطلبوا تحويل عاجل أو كود من أصحابك.', 'المحتالون غالبًا يطلبون تحويلًا عاجلًا أو كودًا من أصدقائك.',
                'Scammers usually ask your friends for an urgent transfer or a code.'),
          ],
          null,
        ),
        (
          t('غيّر كلمات السر', 'غيّر كلمات السر', 'Change your passwords'),
          [
            t('ابدأ بالإيميل، بعده البنك، بعده فيسبوك والباقي — من جهاز نضيف.', 'ابدأ بالبريد ثم البنك ثم فيسبوك والبقية — من جهاز سليم.',
                'Start with email, then bank, then Facebook and the rest — from a clean device.'),
            t('سجّل خروج من كل الأجهزة التانية، وشغّل التحقق بخطوتين.', 'سجّل الخروج من جميع الأجهزة الأخرى وفعّل التحقق بخطوتين.',
                'Sign out of all other devices and turn on two-step verification.'),
            t('راجع إيميل ورقم الاسترداد ما اتغيّروا، وراجع قواعد «إعادة التوجيه» في الإيميل.', 'تأكد أن بريد ورقم الاسترداد لم يتغيرا، وراجع قواعد إعادة التوجيه في البريد.',
                'Check the recovery email/phone were not changed, and check email forwarding rules.'),
            t('لو فيه قروش: كلّم البنك طوالي.', 'إن كان هناك مال: اتصل بالبنك فورًا.', 'If money is involved: call your bank immediately.'),
          ],
          null,
        ),
        (
          tr('فيسبوك / Google', 'Facebook / Google'),
          [
            t('فيسبوك عنده صفحة مخصوصة للحسابات المخترقة.', 'لدى فيسبوك صفحة مخصصة للحسابات المخترقة.', 'Facebook has a dedicated page for hacked accounts.'),
            t('Google عنده صفحة استرداد الحساب.', 'لدى Google صفحة لاسترداد الحساب.', 'Google has an account recovery page.'),
          ],
          Column(children: [
            LinkTile(tr('فيسبوك: حساب مخترق', 'Facebook: hacked account'), 'https://www.facebook.com/hacked', color: SD.nile),
            LinkTile(tr('Google: استرداد الحساب', 'Google: account recovery'), 'https://accounts.google.com/signin/recovery', color: SD.red),
          ]),
        ),
      ];
}
