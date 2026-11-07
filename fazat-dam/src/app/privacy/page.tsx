import type { Metadata } from "next";
import { getDict } from "@/lib/i18n/server";
import { Notice, PageHeader } from "@/components/ui";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.nav.privacy };
}

const AR = [
  ["ما نجمعه", "رقم الجوال (للتحقق برمز)، الاسم، الدولة والمدينة، فصيلة الدم والتوفر للمتبرعين، وتفاصيل الطلب الضرورية فقط (بدون اسم المريض الكامل). المستندات الداعمة تُحفظ في تخزين خاص."],
  ["ما يُعرض للآخرين", "يظهر المتبرع برمز مستعار وفصيلته ومدينته فقط. لا تُعرض أرقام الهواتف أو العناوين أو المستندات علناً أبداً."],
  ["تبادل وسائل التواصل", "لا يظهر رقمك لأي طرف إلا بعد موافقتك وموافقة الطرف الآخر على طلب محدد، ويُسجَّل كل كشف في سجل التدقيق. يمكنك سحب الموافقة أو الحظر في أي وقت."],
  ["من يطّلع على البيانات", "المراجعون المعتمدون (الإدارة وطاقم المنشأة الصحية المعنية) فقط، ولغرض التحقق من الطلب."],
  ["عدم البيع", "لا نبيع البيانات ولا نشاركها مع الرعاة أو أي جهة تسويقية."],
  ["حذف الحساب", "يمكنك حذف حسابك من صفحة «حسابي»؛ تُلغى طلباتك المفتوحة ويُحذف ملف المتبرع وتُزال بياناتك الشخصية."],
  ["الأمان", "اتصال مشفّر (HTTPS)، صلاحيات على مستوى الصفوف في قاعدة البيانات، روابط مؤقتة للمستندات، وتسجيل تدقيق للعمليات الحساسة."],
];
const EN = [
  ["What we collect", "Mobile number (for code verification), name, country and city, blood group and availability for donors, and only the request details that are necessary (never the patient's full name). Supporting documents are kept in private storage."],
  ["What others see", "Donors appear only as an alias with blood group and city. Phone numbers, addresses and documents are never public."],
  ["Contact exchange", "Your number is shown to no one unless you and the other side both approve for a specific request; every reveal is audit-logged. You can withdraw consent or block at any time."],
  ["Who can access data", "Only authorised reviewers (administrators and staff of the healthcare facility concerned), for verifying the request."],
  ["No selling", "We never sell data or share it with sponsors or marketers."],
  ["Account deletion", "Delete your account from “My account”: open requests are cancelled, your donor profile is deleted and your personal data removed."],
  ["Security", "Encrypted connections (HTTPS), row-level permissions in the database, short-lived document links and audit logging of sensitive actions."],
];

export default async function PrivacyPage() {
  const { t, locale } = await getDict();
  const items = locale === "ar" ? AR : EN;
  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-4">
      <PageHeader title={t.nav.privacy} />
      <Notice tone="warn">{locale === "ar"
        ? "مسودة أولية: يجب مراجعتها قانونياً وفق نظام حماية البيانات الشخصية السعودي والأنظمة الصحية والقوانين السودانية ذات الصلة قبل التشغيل العام."
        : "Initial draft: must be legally reviewed against the Saudi Personal Data Protection Law, healthcare regulations and relevant Sudanese laws before public operation."}</Notice>
      {items.map(([h, p]) => <section key={h} className="card"><h2 className="section-title">{h}</h2><p className="mt-1 text-sm leading-7">{p}</p></section>)}
    </div>
  );
}
