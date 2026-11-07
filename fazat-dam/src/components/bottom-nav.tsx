"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useI18n } from "@/lib/i18n/client";
import { HomeIcon, SearchIcon, AlertIcon, ListIcon, UserIcon } from "./icons";

export function BottomNav() {
  const { t } = useI18n();
  const path = usePathname();
  const items = [
    { href: "/", label: t.nav.home, Icon: HomeIcon },
    { href: "/donors", label: t.nav.findDonor, Icon: SearchIcon },
    { href: "/requests/new", label: t.nav.request, Icon: AlertIcon, accent: true },
    { href: "/activity", label: t.nav.activity, Icon: ListIcon },
    { href: "/profile", label: t.nav.account, Icon: UserIcon },
  ];
  return (
    <nav aria-label={t.nav.menu} className="fixed inset-x-0 bottom-0 z-40 border-t border-line bg-white/95 pb-[env(safe-area-inset-bottom)] backdrop-blur md:hidden">
      <ul className="mx-auto grid max-w-lg grid-cols-5">
        {items.map(({ href, label, Icon, accent }) => {
          const active = href === "/" ? path === "/" : path.startsWith(href);
          return (
            <li key={href}>
              <Link href={href} aria-current={active ? "page" : undefined}
                className={`flex min-h-16 flex-col items-center justify-center gap-0.5 px-1 text-[0.68rem] font-semibold leading-tight ${active ? "text-brand" : accent ? "text-brand-600" : "text-muted"}`}>
                <Icon className={`h-6 w-6 ${accent ? "rounded-full" : ""}`} />
                <span className="text-center">{label}</span>
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
