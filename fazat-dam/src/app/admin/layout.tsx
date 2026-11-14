import Link from "next/link";
import { redirect } from "next/navigation";
import { getDict } from "@/lib/i18n/server";
import { requireViewer } from "@/lib/auth";

export default async function AdminLayout({ children }: LayoutProps<"/admin">) {
  const { t } = await getDict();
  const viewer = await requireViewer("/admin");
  const staff = viewer.roles.includes("institution_staff");
  if (!viewer.isAdmin && !staff) redirect("/");
  const items = viewer.isAdmin ? [
    ["/admin", t.admin.overview], ["/admin/requests", t.admin.requests], ["/admin/users", t.admin.users], ["/admin/donors", t.admin.donors],
    ["/admin/institutions", t.admin.institutions], ["/admin/initiatives", t.admin.initiatives], ["/admin/sponsors", t.admin.sponsors],
    ["/admin/donations", t.admin.donations], ["/admin/reports", t.admin.reports], ["/admin/notifications", t.admin.notifications],
    ["/admin/settings", t.admin.settings], ["/admin/audit", t.admin.audit],
  ] : [["/institution", t.institution.dashboard]];
  return (
    <div className="flex flex-col gap-4 md:flex-row">
      <nav aria-label={t.admin.title} className="md:w-56 md:shrink-0">
        <ul className="-mx-4 flex gap-2 overflow-x-auto px-4 pb-2 [scrollbar-width:none] md:mx-0 md:px-0 md:sticky md:top-20 md:flex-col md:overflow-visible">
          {items.map(([href, label]) => (
            <li key={href}><Link href={href} className="pill min-h-10 whitespace-nowrap md:w-full md:justify-start md:bg-transparent md:shadow-none md:hover:bg-white">{label}</Link></li>
          ))}
        </ul>
      </nav>
      <div className="min-w-0 flex-1">{children}</div>
    </div>
  );
}
