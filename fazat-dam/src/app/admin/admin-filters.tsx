"use client";
import { useRouter, usePathname } from "next/navigation";
import { useI18n } from "@/lib/i18n/client";
import type { City } from "@/lib/geo";
import { CountryCitySelect } from "@/components/forms";

/** Generic GET filter bar for admin lists: country, city, date range, status, demo. */
export function AdminFilters({ cities, values, statuses, showDates = false, showDemo = false }: {
  cities: City[]; values: Record<string, string | undefined>; statuses?: { value: string; label: string }[]; showDates?: boolean; showDemo?: boolean;
}) {
  const { t } = useI18n();
  const router = useRouter();
  const path = usePathname();
  return (
    <form className="card mb-4 flex flex-col gap-3" onSubmit={(e) => {
      e.preventDefault();
      const q = new URLSearchParams();
      new FormData(e.currentTarget).forEach((v, k) => { if (typeof v === "string" && v) q.set(k, v); });
      router.push(`${path}?${q}`);
    }}>
      <CountryCitySelect cities={cities} defaultCountry={values.country} defaultCity={values.city} required={false} allowAnyCity />
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
        {statuses && (
          <div className="field"><label className="label" htmlFor="f-status">{t.common.status}</label>
            <select id="f-status" name="status" className="input" defaultValue={values.status ?? ""}>
              <option value="">{t.common.all}</option>
              {statuses.map((s) => <option key={s.value} value={s.value}>{s.label}</option>)}
            </select></div>
        )}
        {showDates && <>
          <div className="field"><label className="label" htmlFor="f-from">{t.common.from}</label><input id="f-from" type="date" name="from" className="input latin" defaultValue={values.from} /></div>
          <div className="field"><label className="label" htmlFor="f-to">{t.common.to}</label><input id="f-to" type="date" name="to" className="input latin" defaultValue={values.to} /></div>
        </>}
      </div>
      {showDemo && <label className="flex items-center gap-2 text-sm"><input type="checkbox" name="demo" value="1" defaultChecked={values.demo === "1"} className="h-5 w-5" />{t.admin.includeDemo}</label>}
      <div className="flex gap-2"><button className="btn-navy">{t.common.apply}</button><button type="button" className="btn-ghost" onClick={() => router.push(path)}>{t.common.reset}</button></div>
    </form>
  );
}
