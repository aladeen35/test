import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { getViewer } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { Logo } from "./ui";
import { BellIcon } from "./icons";
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
    <header className="sticky top-0 z-30 border-b border-line bg-white/95 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-6xl items-center gap-3 px-4">
        <Link href="/" aria-label={t.meta.name} className="shrink-0"><Logo label={t.meta.name} size={40} /></Link>
        <nav aria-label={t.nav.menu} className="ms-4 hidden flex-1 items-center gap-1 md:flex">
          {links.map((l) => <Link key={l.href} href={l.href} className="btn-ghost min-h-10 px-3 text-sm">{l.label}</Link>)}
          {viewer?.isAdmin && <Link href="/admin" className="btn-ghost min-h-10 px-3 text-sm text-brand-600">{t.nav.admin}</Link>}
          {viewer?.roles.includes("institution_staff") && <Link href="/institution" className="btn-ghost min-h-10 px-3 text-sm">{t.nav.institution}</Link>}
        </nav>
        <div className="ms-auto flex items-center gap-1">
          <LangSwitch />
          {viewer ? (
            <>
              <Link href="/notifications" className="btn-ghost relative min-h-10 px-2" aria-label={`${t.nav.notifications}${unread ? ` (${unread})` : ""}`}>
                <BellIcon />
                {unread > 0 && <span className="latin absolute -top-0.5 end-0 min-w-5 rounded-full bg-brand px-1 text-center text-[0.65rem] font-bold leading-5 text-white">{unread > 99 ? "99+" : unread}</span>}
              </Link>
              <Link href="/profile" className="btn-ghost hidden min-h-10 px-3 text-sm md:inline-flex">{t.nav.account}</Link>
            </>
          ) : (
            <Link href="/login" className="btn-primary min-h-10 px-4 text-sm">{t.common.signIn}</Link>
          )}
        </div>
      </div>
      {viewer?.isAdmin && (
        <div className="border-t border-line bg-navy-100/50 md:hidden">
          <div className="mx-auto flex max-w-6xl gap-2 overflow-x-auto px-4 py-1.5 text-sm">
            <Link href="/admin" className="font-semibold text-brand-600">{t.nav.admin}</Link>
          </div>
        </div>
      )}
    </header>
  );
}

export async function SiteFooter() {
  const { t } = await getDict();
  return (
    <footer className="mt-10 border-t border-line bg-white pb-28 md:pb-6">
      <div className="mx-auto flex max-w-6xl flex-col gap-3 px-4 py-6 text-sm text-muted">
        <p className="font-semibold text-navy">{t.meta.slogan}</p>
        <p>{t.legal.medical}</p>
        <nav className="flex flex-wrap gap-4">
          <Link href="/about" className="underline-offset-4 hover:underline">{t.nav.about}</Link>
          <Link href="/privacy" className="underline-offset-4 hover:underline">{t.nav.privacy}</Link>
          <Link href="/terms" className="underline-offset-4 hover:underline">{t.nav.terms}</Link>
          <Link href="/sponsors" className="underline-offset-4 hover:underline">{t.nav.sponsors}</Link>
          <Link href="/institution" className="underline-offset-4 hover:underline">{t.nav.institution}</Link>
        </nav>
      </div>
    </footer>
  );
}
