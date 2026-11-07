"use client";
import { useRouter } from "next/navigation";
import { useI18n } from "@/lib/i18n/client";
import type { City } from "@/lib/geo";
import { BLOOD_GROUPS } from "@/lib/constants";
import { CountryCitySelect } from "@/components/forms";

export function SearchFilters({ cities, country, city, group, availableOnly }: { cities: City[]; country: string; city: string | null; group: string | null; availableOnly: boolean }) {
  const { t } = useI18n();
  const router = useRouter();
  return (
    <form className="card flex flex-col gap-4" onSubmit={(e) => {
      e.preventDefault();
      const fd = new FormData(e.currentTarget);
      const q = new URLSearchParams();
      for (const k of ["country", "city", "group"]) { const v = fd.get(k); if (typeof v === "string" && v) q.set(k, v); }
      if (!fd.get("available")) q.set("all", "1");
      router.push(`/donors?${q}`);
    }}>
      <CountryCitySelect cities={cities} defaultCountry={country} defaultCity={city} allowAnyCity />
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="field">
          <label className="label" htmlFor="group">{t.common.bloodGroup}</label>
          <select id="group" name="group" className="input latin" defaultValue={group ?? ""}>
            <option value="">{t.common.anyGroup}</option>
            {BLOOD_GROUPS.map((g) => <option key={g} value={g}>{g}</option>)}
          </select>
        </div>
        <label className="flex items-center gap-3 self-end text-sm font-semibold text-navy">
          <input type="checkbox" name="available" defaultChecked={availableOnly} className="h-5 w-5 accent-[var(--color-brand)]" />
          {t.search.availableOnly}
        </label>
      </div>
      <button className="btn-primary">{t.common.search}</button>
    </form>
  );
}
