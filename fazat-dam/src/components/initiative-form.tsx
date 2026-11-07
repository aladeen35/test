"use client";
import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { useI18n } from "@/lib/i18n/client";
import { saveInitiative } from "@/app/actions/community";
import type { City } from "@/lib/geo";
import { INITIATIVE_CATEGORIES } from "@/lib/constants";
import { CountryCitySelect, FormMessage, SubmitButton } from "./forms";

export type InitiativeDraft = {
  id: string; category: string; title_ar: string; title_en: string | null; description: string; objectives: string; beneficiaries: string;
  organizer_name: string; organizer_contact: string | null; country_code: string; city_id: string | null; start_date: string; end_date: string | null;
};

export function InitiativeForm({ cities, initial }: { cities: City[]; initial?: InitiativeDraft }) {
  const { t } = useI18n();
  const router = useRouter();
  const [state, action] = useActionState(saveInitiative, null);
  useEffect(() => { if (state?.ok) router.push("/initiatives/mine"); }, [state, router]);
  const today = new Date().toISOString().slice(0, 10);
  return (
    <form action={action} className="card flex flex-col gap-4">
      {initial && <input type="hidden" name="id" value={initial.id} />}
      <div className="field">
        <label className="label" htmlFor="category">{t.initiative.category}</label>
        <select id="category" name="category" className="input" required defaultValue={initial?.category ?? "blood_drive"}>
          {INITIATIVE_CATEGORIES.map((c) => <option key={c} value={c}>{t.initiative[`cat_${c}`]}</option>)}
        </select>
      </div>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="field"><label className="label" htmlFor="title_ar">{t.initiative.titleAr}</label>
          <input id="title_ar" name="title_ar" dir="rtl" className="input" required minLength={4} maxLength={160} defaultValue={initial?.title_ar} /></div>
        <div className="field"><label className="label" htmlFor="title_en">{t.initiative.titleEn} ({t.common.optional})</label>
          <input id="title_en" name="title_en" dir="ltr" className="input" minLength={4} maxLength={160} defaultValue={initial?.title_en ?? ""} /></div>
      </div>
      <div className="field"><label className="label" htmlFor="description">{t.initiative.description}</label>
        <textarea id="description" name="description" className="input min-h-28" required minLength={20} maxLength={4000} defaultValue={initial?.description} /></div>
      <div className="field"><label className="label" htmlFor="objectives">{t.initiative.objectives}</label>
        <textarea id="objectives" name="objectives" className="input min-h-20" required minLength={10} maxLength={2000} defaultValue={initial?.objectives} /></div>
      <div className="field"><label className="label" htmlFor="beneficiaries">{t.initiative.beneficiaries}</label>
        <input id="beneficiaries" name="beneficiaries" className="input" required minLength={4} maxLength={1000} defaultValue={initial?.beneficiaries} /></div>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="field"><label className="label" htmlFor="organizer_name">{t.initiative.organizerName}</label>
          <input id="organizer_name" name="organizer_name" className="input" required minLength={2} maxLength={160} defaultValue={initial?.organizer_name} /></div>
        <div className="field"><label className="label" htmlFor="organizer_contact">{t.initiative.organizerContact}</label>
          <input id="organizer_contact" name="organizer_contact" className="input" maxLength={160} defaultValue={initial?.organizer_contact ?? ""} /></div>
      </div>
      <CountryCitySelect cities={cities} defaultCountry={initial?.country_code} defaultCity={initial?.city_id} allowAnyCity />
      <div className="grid grid-cols-2 gap-4">
        <div className="field"><label className="label" htmlFor="start_date">{t.initiative.startDate}</label>
          <input id="start_date" name="start_date" type="date" className="input latin" required defaultValue={initial?.start_date ?? today} /></div>
        <div className="field"><label className="label" htmlFor="end_date">{t.initiative.endDate}</label>
          <input id="end_date" name="end_date" type="date" className="input latin" defaultValue={initial?.end_date ?? ""} /></div>
      </div>
      <div className="field"><label className="label" htmlFor="documents">{t.initiative.documents}</label>
        <input id="documents" name="documents" type="file" multiple accept="application/pdf,image/jpeg,image/png,image/webp" className="input py-2" />
        <span className="hint">{t.request.documentsHint}</span></div>
      <FormMessage state={state} />
      <div className="flex flex-wrap gap-2">
        <SubmitButton name="intent" value="submit">{t.initiative.submit}</SubmitButton>
        <SubmitButton name="intent" value="draft" className="btn-outline">{t.initiative.asDraft}</SubmitButton>
      </div>
    </form>
  );
}
