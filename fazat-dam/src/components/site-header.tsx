import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { getViewer } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { Credit } from "./credit";
import { BellIcon, UserIcon } from "./icons";
import { LangSwitch } from "./header-controls";

export async function SiteHeader() {
  const { t } = await getDict();
  const viewer = await getViewer();
  let unread = 0;
  if (viewer) {
    const supabase = await createClient();
    const { count } = await supabase.from("notifications").select("id", { count: "exact", head: true }).is("read_at", null);
    unread = count ?? 0;
  }
  const links = [
    { href: "/donors", label: t.nav.findDonor },
    { href: "/donate", label: t.nav.donate },
    { href: "/requests/new", label: t.nav.request },
    { href: "/initiatives", label: t.nav.initiatives },
    { href: "/activity", label: t.nav.activity },
  ];
  return (
    <header className="sticky top-0 z-30 bg-surface/85 backdrop-blur-md">
      <div className="mx-auto flex h-[4.5rem] max-w-6xl items-center gap-3 px-4">
        <Link href="/" aria-label={t.meta.name} className="flex shrink-0 items-center gap-2.5">
          <span className="icon-btn h-12 w-12 overflow-hidden p-1">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src="/brand/symbol.png" alt="" width={40} height={40} className="h-10 w-10 rounded-full" />
          </span>
          <span className="text-lg font-bold leading-none text-navy">{t.meta.name}</span>
        </Link>
        <nav aria-label={t.nav.menu} className="ms-4 hidden flex-1 items-center gap-1.5 md:flex">
          {links.map((l) => <Link key={l.href} href={l.href} className="pill min-h-9 bg-transparent shadow-none hover:bg-white">{l.label}</Link>)}
          {viewer?.isAdmin && <Link href="/admin" className="pill min-h-9 bg-transparent text-brand-600 shadow-none hover:bg-white">{t.nav.admin}</Link>}
          {viewer?.roles.includes("institution_staff") && <Link href="/institution" className="pill min-h-9 bg-transparent shadow-none hover:bg-white">{t.nav.institution}</Link>}
        </nav>
        <div className="ms-auto flex items-center gap-2">
          <LangSwitch />
          {viewer ? (
            <>
              <Link href="/notifications" className="icon-btn" aria-label={`${t.nav.notifications}${unread ? ` (${unread})` : ""}`}>
                <BellIcon className="h-5 w-5" />
                {unread > 0 && <span className="absolute end-2.5 top-2.5 h-2.5 w-2.5 rounded-full bg-brand ring-2 ring-white" aria-hidden />}
              </Link>
              <Link href="/profile" className="icon-btn hidden md:inline-flex" aria-label={t.nav.account}><UserIcon className="h-5 w-5" /></Link>
            </>
          ) : (
            <Link href="/login" className="btn-primary min-h-11 px-5 text-sm">{t.common.signIn}</Link>
          )}
        </div>
      </div>
      {viewer?.isAdmin && (
        <div className="md:hidden">
          <div className="mx-auto flex max-w-6xl gap-2 overflow-x-auto px-4 pb-2 text-sm">
            <Link href="/admin" className="pill min-h-8 bg-brand-50 text-brand-600 shadow-none">{t.nav.admin}</Link>
          </div>
        </div>
      )}
    </header>
  );
}

export async function SiteFooter() {
  const { t } = await getDict();
  return (
    <footer className="mt-10 pb-32 md:pb-8">
      <div className="mx-auto max-w-6xl px-4">
        <div className="card flex flex-col gap-3 text-sm text-muted">
          <p className="font-semibold text-navy">{t.meta.slogan}</p>
          <p>{t.legal.medical}</p>
          <nav className="flex flex-wrap gap-2">
            {[["/about", t.nav.about], ["/privacy", t.nav.privacy], ["/terms", t.nav.terms], ["/sponsors", t.nav.sponsors], ["/institution", t.nav.institution]].map(([href, label]) => (
              <Link key={href} href={href} className="pill min-h-9 bg-surface-2 shadow-none hover:text-navy">{label}</Link>
            ))}
          </nav>
          <p className="border-t border-line pt-3 text-xs"><Credit t={t} /></p>
        </div>
      </div>
    </footer>
  );
}
