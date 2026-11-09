"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useI18n } from "@/lib/i18n/client";
import { HomeIcon, SearchIcon, DropIcon, ListIcon, UserIcon } from "./icons";

export function BottomNav() {
  const { t } = useI18n();
  const path = usePathname();
  const side = [
    { href: "/", label: t.nav.home, Icon: HomeIcon },
    { href: "/donors", label: t.nav.findDonor, Icon: SearchIcon },
    null,
    { href: "/activity", label: t.nav.activity, Icon: ListIcon },
    { href: "/profile", label: t.nav.account, Icon: UserIcon },
  ];
  return (
    <nav aria-label={t.nav.menu} className="fixed inset-x-0 bottom-0 z-40 border-t border-line bg-white/95 pb-[env(safe-area-inset-bottom)] shadow-[0_-4px_20px_rgb(23_43_77/0.06)] backdrop-blur md:hidden">
      <ul className="mx-auto grid max-w-lg grid-cols-5">
        {side.map((item) => {
          if (!item) {
            const active = path.startsWith("/requests/new");
            return (
              <li key="fab" className="relative flex justify-center">
                <Link href="/requests/new" aria-current={active ? "page" : undefined} aria-label={t.nav.request}
                  className="absolute -top-6 flex h-16 w-16 flex-col items-center justify-center rounded-full bg-brand text-white shadow-[0_8px_20px_rgb(198_40_40/0.45)] ring-4 ring-white transition-transform active:scale-95">
                  <DropIcon className="h-7 w-7" />
                </Link>
                <span className="mt-11 pb-1 text-[0.68rem] font-bold text-brand-600" aria-hidden>{t.nav.requestShort}</span>
              </li>
            );
          }
          const { href, label, Icon } = item;
          const active = href === "/" ? path === "/" : path.startsWith(href);
          return (
            <li key={href}>
              <Link href={href} aria-current={active ? "page" : undefined}
                className={`relative flex min-h-16 flex-col items-center justify-center gap-0.5 px-1 text-[0.68rem] font-semibold leading-tight transition-colors ${active ? "text-brand" : "text-muted"}`}>
                {active && <span className="absolute top-0 h-1 w-8 rounded-b-full bg-brand" aria-hidden />}
                <Icon className={`h-6 w-6 transition-transform ${active ? "scale-110" : ""}`} />
                <span className="text-center">{label}</span>
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
