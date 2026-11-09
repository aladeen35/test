import type { Metadata } from "next";
import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { Notice, PageHeader } from "@/components/ui";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.nav.privacy };
}

const UPDATED = "2026-11-09";
type Section = { h: string; p?: string; list?: string[] };

const AR: Section[] = [
  { h: "1. من نحن", p: "«فزعة دم» منصة مجتمعية إنسانية تربط المتبرعين بالدم بالمرضى وأسرهم داخل السودان وداخل المملكة العربية السعودية. المنصة ليست مقدّم خدمة طبية ولا بنك دم. المنصة من تصميم وتطوير البشري للتكنولوجيا." },
  { h: "2. البيانات التي نجمعها", list: [
    "بيانات الحساب: البريد الإلكتروني أو رقم الجوال المستخدم للدخول، والاسم، والدولة والمدينة، ولغة الواجهة.",
    "رقم جوال للتواصل تدخله بنفسك إن سجّلت بالبريد الإلكتروني.",
    "بيانات المتبرع: فصيلة الدم، حالة التوفر، وسيلة التواصل المفضلة، واختيارياً منشأة التبرع المفضلة وتاريخ آخر تبرع.",
    "بيانات طلب الدم: الفصيلة وعدد الوحدات والمدينة واسم المستشفى والموعد ودرجة الاستعجال، وصلتك بالمريض. لا نطلب اسم المريض الكامل؛ يمكن إدخال الأحرف الأولى فقط.",
    "المستندات الداعمة التي ترفعها (مثل طلب المستشفى) ومستندات اعتماد المنشآت والمبادرات.",
    "سجلات الموافقة: متى وافقت على هذه السياسة وعلى مشاركة وسيلة التواصل.",
    "الرسائل داخل التطبيق والبلاغات التي ترسلها.",
    "بيانات تقنية محدودة: ملف تعريف الجلسة، واشتراك إشعارات الجهاز إن فعّلته.",
  ] },
  { h: "3. لماذا نستخدم بياناتك", list: [
    "إنشاء حسابك والتحقق من دخولك.",
    "مطابقة الطلبات مع متبرعين محتملين في الدولة والمدينة نفسها وبالفصيلة المعلنة.",
    "مراجعة الطلبات والمنشآت والمبادرات قبل نشرها ومنع الاحتيال وإساءة الاستخدام.",
    "إرسال إشعارات تخص طلباتك وتبرعاتك.",
    "إعداد إحصاءات مجمّعة لا تكشف هوية أحد.",
  ], p: "أساس المعالجة هو موافقتك الصريحة عند التسجيل. لا نستخدم بياناتك للإعلانات ولا لأي غرض تسويقي." },
  { h: "4. ما يراه الآخرون", p: "يظهر المتبرع في نتائج البحث برمز مستعار (مثل D-7K3QX) مع فصيلته ومدينته وحالة توفره فقط، ويظهر الاسم الأول فقط إن اختار ذلك. الطلبات الموثّقة تظهر علناً بالفصيلة والمدينة واسم المستشفى والموعد، دون أي بيانات عن المريض أو صاحب الطلب. لا تُعرض أرقام الهواتف ولا البريد ولا العناوين ولا المستندات علناً أبداً." },
  { h: "5. تبادل وسائل التواصل", p: "لا يظهر رقم جوالك لأي طرف إلا إذا وافقت أنت والطرف الآخر معاً على تبادل وسيلة التواصل في طلب محدد. يُسجَّل كل كشف للرقم في سجل التدقيق. يمكنك سحب موافقتك أو حظر الطرف الآخر في أي وقت، ويُغلق التواصل تلقائياً عند إلغاء الطلب أو انتهائه وبعد سبعة أيام من اكتماله." },
  { h: "6. من يطّلع على بياناتك", list: [
    "مشرفو المنصة المخوّلون، لغرض المراجعة والتحقق ومعالجة البلاغات.",
    "طاقم المنشأة الصحية المعتمدة التي اخترتها في طلبك، ويطّلع على ذلك الطلب ومستنداته فقط.",
    "الطرف الآخر في الطلب، في حدود ما وافقت على مشاركته.",
  ] },
  { h: "7. المشاركة مع أطراف أخرى", p: "لا نبيع بياناتك ولا نشاركها مع الرعاة أو المعلنين. نستعين بمزوّدي خدمات تقنية يعالجون البيانات لحسابنا فقط: خدمة قاعدة البيانات والتخزين والدخول (Supabase)، وخدمة استضافة التطبيق، وخدمة إرسال رسائل البريد أو الرسائل النصية الخاصة بالدخول. قد نفصح عن بيانات إذا ألزمنا بذلك نظام نافذ أو أمر من جهة مختصة." },
  { h: "8. مكان التخزين ومدة الاحتفاظ", p: "تُخزَّن البيانات حالياً على خوادم داخل الاتحاد الأوروبي (فرانكفورت)، أي خارج السودان والسعودية. نحتفظ ببياناتك ما دام حسابك قائماً. عند حذف الحساب تُزال بياناتك الشخصية (الاسم والجوال والبريد) ويُحذف ملف المتبرع وتُلغى طلباتك المفتوحة، وقد نحتفظ بسجلات لا تحمل بيانات شخصية لأغراض الإحصاء والتدقيق ومنع الاحتيال." },
  { h: "9. ملفات تعريف الارتباط والتخزين على جهازك", p: "نستخدم ملفات ضرورية فقط: ملف جلسة الدخول، واختيار اللغة، واختيار الشبكة (السودان أو السعودية). ويُحفظ على جهازك مسودة طلب الدم غير المرسل وحالة شاشة الترحيب. لا نستخدم أدوات تتبّع إعلانية ولا تحليلات من أطراف ثالثة." },
  { h: "10. الإشعارات", p: "تصلك الإشعارات داخل التطبيق دائماً. إشعارات الجهاز اختيارية وتُفعَّل بإذنك من المتصفح، ولا تحمل سوى عنوان مختصر ورابط داخل التطبيق، ويمكنك إيقافها في أي وقت من صفحة الإشعارات." },
  { h: "11. حقوقك", list: [
    "الاطلاع على بياناتك وتصحيحها من صفحة «حسابي».",
    "إيقاف ظهورك كمتبرع مؤقتاً أو نهائياً.",
    "سحب موافقتك على مشاركة وسيلة التواصل.",
    "حذف حسابك نهائياً من صفحة «حسابي».",
    "الاعتراض أو الاستفسار عبر وسيلة التواصل المذكورة أدناه، وتقديم شكوى للجهة المختصة بحماية البيانات في بلدك.",
  ] },
  { h: "12. الأطفال", p: "المنصة موجّهة لمن أتمّ 18 عاماً. لا نجمع عن قصد بيانات من هم دون ذلك، وإن علمنا بوجودها حذفناها." },
  { h: "13. أمان البيانات", p: "الاتصال بالمنصة مشفّر (HTTPS). صلاحيات الوصول مطبّقة على مستوى كل سجل في قاعدة البيانات، والمستندات الخاصة تُفتح بروابط مؤقتة قصيرة العمر، والعمليات الحساسة مسجّلة في سجل تدقيق لا يحفظ أرقام الهواتف. لا يوجد نظام آمن بالكامل، وسنبلغ المتأثرين والجهات المختصة عند وقوع اختراق وفق ما تقتضيه الأنظمة." },
  { h: "14. تنبيه طبي", p: "المطابقة في المنصة مبدئية ولا تحدد الأهلية الطبية ولا التوافق السريري. يحدد بنك الدم المعتمد ذلك بعد الفحص. لا تكتب معلومات طبية تفصيلية في خانات الملاحظات أو الرسائل." },
  { h: "15. تعديل هذه السياسة", p: "قد نحدّث هذه السياسة. ننشر النسخة الجديدة في هذه الصفحة مع تاريخ التحديث، ونطلب موافقتك من جديد إذا كان التغيير جوهرياً." },
];

const EN: Section[] = [
  { h: "1. Who we are", p: "FAZAT DAM is a humanitarian community platform that connects blood donors with patients and their families within Sudan and within Saudi Arabia. It is not a medical service provider or a blood bank. The platform is designed and developed by Al-Bushra Technology." },
  { h: "2. Data we collect", list: [
    "Account data: the email address or mobile number you sign in with, your name, country and city, and interface language.",
    "A contact mobile number that you enter yourself if you sign in by email.",
    "Donor data: blood group, availability, preferred contact method and, optionally, preferred donation facility and last donation date.",
    "Blood request data: group, units, city, hospital name, needed-by time, urgency and your relation to the patient. We never ask for the patient's full name; initials are optional.",
    "Supporting documents you upload (such as a hospital request) and verification documents for facilities and initiatives.",
    "Consent records: when you accepted this policy and when you agreed to share contact details.",
    "In-app messages and reports you send.",
    "Limited technical data: the session cookie and, if you enable it, your device notification subscription.",
  ] },
  { h: "3. Why we use your data", list: [
    "To create your account and verify your sign-in.",
    "To match requests with potential donors in the same country and city with the declared blood group.",
    "To review requests, facilities and initiatives before publication and to prevent fraud and abuse.",
    "To send notifications about your requests and donations.",
    "To produce aggregate statistics that identify no one.",
  ], p: "Processing is based on your explicit consent at registration. We do not use your data for advertising or marketing." },
  { h: "4. What others see", p: "Donors appear in search results as an alias (such as D-7K3QX) with blood group, city and availability only; a first name appears only if the donor opts in. Verified requests are public with blood group, city, hospital name and needed-by time, without any data about the patient or the requester. Phone numbers, emails, addresses and documents are never public." },
  { h: "5. Contact exchange", p: "Your mobile number is shown to no one unless you and the other side both agree to exchange contact details for a specific request. Every reveal is recorded in the audit log. You can withdraw consent or block the other side at any time, and contact closes automatically when a request is cancelled or expires and seven days after it is completed." },
  { h: "6. Who can access your data", list: [
    "Authorised platform administrators, for review, verification and handling reports.",
    "Staff of the approved healthcare facility you selected in your request, who see that request and its documents only.",
    "The other party to a request, limited to what you agreed to share.",
  ] },
  { h: "7. Sharing with other parties", p: "We never sell your data or share it with sponsors or advertisers. We use technical service providers that process data only on our behalf: database, storage and sign-in (Supabase), application hosting, and delivery of sign-in emails or SMS. We may disclose data where an applicable law or a competent authority requires it." },
  { h: "8. Where data is stored and for how long", p: "Data is currently stored on servers in the European Union (Frankfurt), which is outside Sudan and Saudi Arabia. We keep your data while your account exists. When you delete your account, your personal data (name, mobile, email) is removed, your donor profile is deleted and your open requests are cancelled; we may keep records that contain no personal data for statistics, audit and fraud prevention." },
  { h: "9. Cookies and storage on your device", p: "We use strictly necessary cookies only: the sign-in session, your language choice and your network choice (Sudan or Saudi Arabia). Your device also keeps an unsent blood request draft and the welcome-screen state. We use no advertising trackers and no third-party analytics." },
  { h: "10. Notifications", p: "In-app notifications are always delivered. Device notifications are optional, enabled with your browser permission, carry only a short title and an in-app link, and can be turned off at any time from the notifications page." },
  { h: "11. Your rights", list: [
    "View and correct your data on the “My account” page.",
    "Pause or end your visibility as a donor.",
    "Withdraw your consent to share contact details.",
    "Delete your account permanently from “My account”.",
    "Object or ask questions through the contact below, and lodge a complaint with the data protection authority in your country.",
  ] },
  { h: "12. Children", p: "The platform is intended for people aged 18 and over. We do not knowingly collect data from anyone younger and will delete it if we learn of it." },
  { h: "13. Security", p: "Connections are encrypted (HTTPS). Access permissions are enforced on every record in the database, private documents open through short-lived links, and sensitive actions are recorded in an audit log that never stores phone numbers. No system is perfectly secure; if a breach occurs we will notify the people affected and the competent authorities as the law requires." },
  { h: "14. Medical notice", p: "Matching on the platform is preliminary and does not determine medical eligibility or clinical compatibility; the authorised blood bank decides after screening. Do not write detailed medical information in notes or messages." },
  { h: "15. Changes to this policy", p: "We may update this policy. The new version is published on this page with its date, and we ask for your consent again when a change is material." },
];

export default async function PrivacyPage() {
  const { t, locale } = await getDict();
  const ar = locale === "ar";
  const items = ar ? AR : EN;
  const contact = process.env.NEXT_PUBLIC_CONTACT_EMAIL;
  return (
    <article className="mx-auto flex max-w-3xl flex-col gap-4">
      <PageHeader title={ar ? "سياسة الخصوصية" : "Privacy policy"} intro={`${ar ? "آخر تحديث" : "Last updated"}: ${UPDATED}`} />
      <Notice tone="warn">{ar
        ? "هذه النسخة لم تُراجَع قانونياً بعد. يجب مراجعتها وفق نظام حماية البيانات الشخصية السعودي (خاصةً نقل البيانات خارج المملكة) والأنظمة الصحية والقوانين السودانية ذات الصلة قبل التشغيل العام."
        : "This version has not been legally reviewed yet. It must be reviewed against the Saudi Personal Data Protection Law (especially transfers outside the Kingdom), healthcare regulations and relevant Sudanese laws before public operation."}</Notice>
      <nav aria-label={ar ? "المحتويات" : "Contents"} className="card">
        <ol className="grid grid-cols-1 gap-1 text-sm sm:grid-cols-2">
          {items.map((s, i) => <li key={s.h}><a href={`#s${i + 1}`} className="text-navy underline-offset-4 hover:underline">{s.h}</a></li>)}
        </ol>
      </nav>
      {items.map((s, i) => (
        <section key={s.h} id={`s${i + 1}`} className="card scroll-mt-24">
          <h2 className="section-title">{s.h}</h2>
          {s.list && <ul className="mt-2 list-disc space-y-1.5 ps-5 text-sm leading-7">{s.list.map((li) => <li key={li}>{li}</li>)}</ul>}
          {s.p && <p className="mt-2 text-sm leading-7">{s.p}</p>}
        </section>
      ))}
      <section className="card">
        <h2 className="section-title">{ar ? "16. التواصل معنا" : "16. Contact us"}</h2>
        <p className="mt-2 text-sm leading-7">
          {contact
            ? <>{ar ? "لأي استفسار أو طلب يخص بياناتك: " : "For any question or request about your data: "}<a href={`mailto:${contact}`} className="latin font-semibold text-brand-600 underline">{contact}</a></>
            : ar ? "سيُضاف بريد التواصل الخاص بالخصوصية هنا قبل الإطلاق العام." : "A privacy contact email will be added here before public launch."}
        </p>
        <p className="mt-2 text-sm"><Link href="/terms" className="font-semibold text-brand-600 underline">{t.nav.terms}</Link></p>
      </section>
    </article>
  );
}
