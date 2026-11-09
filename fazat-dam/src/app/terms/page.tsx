import type { Metadata } from "next";
import { getDict } from "@/lib/i18n/server";
import { MedicalNotice, Notice, PageHeader } from "@/components/ui";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.nav.terms };
}

export default async function TermsPage() {
  const { t, locale } = await getDict();
  const items = locale === "ar" ? [
    "المنصة وسيط مجتمعي مجاني وليست مقدّم خدمة طبية.",
    "يتعهد المستخدم بصحة المعلومات، وتُعد الطلبات الوهمية مخالفة تؤدي لإيقاف الحساب.",
    "يتم التبرع فقط داخل منشآت صحية معتمدة، وتحدد المنشأة أهلية المتبرع والتوافق النهائي.",
    "يُمنع طلب أو عرض أي مقابل مادي للتبرع بالدم.",
    "تحتفظ الإدارة بحق مراجعة الطلبات والمبادرات ورفضها وإيقاف الحسابات المخالفة.",
    t.legal.crossBorder,
  ] : [
    "The platform is a free community intermediary, not a medical service provider.",
    "Users must provide accurate information; fake requests lead to account suspension.",
    "Donations take place only in authorised healthcare facilities, which decide donor eligibility and final compatibility.",
    "Asking for or offering payment for blood donation is prohibited.",
    "Administrators may review and reject requests and initiatives and suspend accounts that break these rules.",
    t.legal.crossBorder,
  ];
  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-4">
      <PageHeader title={t.nav.terms} />
      <Notice tone="warn">{locale === "ar" ? "مسودة أولية تحتاج مراجعة قانونية قبل الإطلاق." : "Initial draft pending legal review before launch."}</Notice>
      <ol className="card list-decimal space-y-2 ps-8 text-sm leading-7">{items.map((i) => <li key={i}>{i}</li>)}</ol>
      <MedicalNotice t={t} />
    </div>
  );
}
