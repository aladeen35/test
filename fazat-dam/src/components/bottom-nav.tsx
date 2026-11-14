"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useI18n } from "@/lib/i18n/client";
import { HomeIcon, SearchIcon, DropIcon, ListIcon, UserIcon } from "./icons";

/** Floating pill tab bar. The active tab grows into a navy pill with its label; the request action is a red disc. */
export function BottomNav() {
  const { t } = useI18n();
  const path = usePathname();
  const items = [
    { href: "/", label: t.nav.home, Icon: HomeIcon },
    { href: "/donors", label: t.nav.findDonor, Icon: SearchIcon },
    null,
    { href: "/activity", label: t.nav.activity, Icon: ListIcon },
    { href: "/profile", label: t.nav.account, Icon: UserIcon },
  ];
  return (
    <nav aria-label={t.nav.menu} className="fixed inset-x-3 bottom-[max(0.75rem,env(safe-area-inset-bottom))] z-40 md:hidden">
      <ul className="mx-auto flex max-w-md items-center justify-between rounded-full bg-white p-2 shadow-[var(--shadow-float)]">
        {items.map((item) => {
          if (!item) {
            const active = path.startsWith("/requests/new");
            return (
              <li key="fab">
                <Link href="/requests/new" aria-current={active ? "page" : undefined} aria-label={t.nav.request}
                  className="flex h-14 w-14 items-center justify-center rounded-full bg-brand text-white shadow-[0_10px_22px_-8px_rgb(198_40_40/0.75)] transition-transform active:scale-95">
                  <DropIcon className="h-7 w-7" />
                </Link>
              </li>
            );
          }
          const { href, label, Icon } = item;
          const active = href === "/" ? path === "/" : path.startsWith(href);
          return (
            <li key={href}>
              <Link href={href} aria-current={active ? "page" : undefined} aria-label={label}
                className={`flex h-12 items-center justify-center gap-2 rounded-full transition-all duration-300 ${
                  active ? "bg-navy px-4 text-white" : "w-12 text-muted hover:text-navy"}`}>
                <Icon className="h-6 w-6" />
                {active && <span className="max-w-[5.5rem] truncate text-xs font-semibold">{label}</span>}
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
