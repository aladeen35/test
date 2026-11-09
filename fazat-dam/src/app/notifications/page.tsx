import type { Metadata } from "next";
import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { requireViewer } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { fmtDateTime, pick } from "@/lib/format";
import { markAllRead } from "@/app/actions/account";
import { Empty, PageHeader } from "@/components/ui";
import { PushToggle } from "@/components/push-toggle";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.notifications.title };
}

export default async function NotificationsPage() {
  const { t, locale } = await getDict();
  await requireViewer("/notifications");
  const supabase = await createClient();
  const { data } = await supabase.from("notifications").select("id, title_ar, title_en, body_ar, body_en, link, read_at, created_at").order("created_at", { ascending: false }).limit(100);
  const unread = (data ?? []).some((n) => !n.read_at);
  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-4">
      <PageHeader title={t.notifications.title} action={unread && (
        <form action={markAllRead}><button className="btn-outline min-h-10 text-sm">{t.notifications.markAll}</button></form>
      )} />
      <div className="card"><PushToggle /></div>
      {(data ?? []).length === 0 ? <Empty>{t.notifications.empty}</Empty> : (
        <ul className="flex flex-col gap-2">
          {data!.map((n) => {
            const body = pick(locale, n.body_ar, n.body_en);
            const inner = (
              <>
                <div className="flex items-start gap-2">
                  {!n.read_at && <span className="mt-2 h-2 w-2 shrink-0 rounded-full bg-brand" aria-hidden />}
                  <div className="flex flex-col gap-0.5">
                    <span className={`text-sm ${n.read_at ? "text-navy" : "font-bold text-navy"}`}>{pick(locale, n.title_ar, n.title_en)}</span>
                    {body && <span className="text-sm text-muted">{body}</span>}
                    <span className="text-xs text-muted">{fmtDateTime(n.created_at, locale)}</span>
                  </div>
                </div>
              </>
            );
            return <li key={n.id}>{n.link ? <Link href={n.link} className="card block hover:ring-2 hover:ring-brand-400/30">{inner}</Link> : <div className="card">{inner}</div>}</li>;
          })}
        </ul>
      )}
    </div>
  );
}
