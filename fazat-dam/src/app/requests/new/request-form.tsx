"use client";
import { useActionState, useEffect, useRef, useState } from "react";
import { useClientValue, useOnline } from "@/lib/hooks";
import { useRouter } from "next/navigation";
import { useI18n } from "@/lib/i18n/client";
import { submitRequest } from "@/app/actions/requests";
import type { City } from "@/lib/geo";
import { RELATIONS, URGENCY } from "@/lib/constants";
import { BloodGroupPicker, CountryCitySelect, FormMessage, SubmitButton } from "@/components/forms";
import { Notice } from "@/components/ui";

type Inst = { id: string; type: string; name_ar: string; name_en: string | null; country_code: string; city_id: string };
const DRAFT_KEY = "fd:request-draft";
const DRAFT_FIELDS = ["relation", "patient_initials", "units", "hospital_name", "required_by", "urgency", "notes"];

export function RequestForm({ cities, institutions, defaultCountry, defaultCity }: { cities: City[]; institutions: Inst[]; defaultCountry: string | null; defaultCity: string | null }) {
  const { t, locale } = useI18n();
  const router = useRouter();
  const [state, action] = useActionState(submitRequest, null);
  const [geo, setGeo] = useState({ country: defaultCountry ?? "", city: defaultCity ?? "" });
  const [restored, setRestored] = useState(false);
  const online = useOnline();
  const formRef = useRef<HTMLFormElement>(null);
  const [minDate] = useState(() => new Date(Date.now() + 5 * 60_000).toISOString().slice(0, 16));
  // Draft autosave: unsent requests survive a lost connection or a closed tab (this device only, no documents).
  const hasDraft = useClientValue(() => { try { return localStorage.getItem(DRAFT_KEY) !== null; } catch { return false; } }, false);

  function restoreDraft() {
    try {
      const draft = JSON.parse(localStorage.getItem(DRAFT_KEY) ?? "null");
      if (!draft || !formRef.current) return;
      for (const k of DRAFT_FIELDS) {
        const el = formRef.current.elements.namedItem(k) as HTMLInputElement | null;
        if (el && draft[k]) el.value = draft[k];
      }
      setRestored(true);
    } catch {}
  }

  useEffect(() => {
    if (state?.ok && state.data?.id) {
      try { localStorage.removeItem(DRAFT_KEY); } catch {}
      router.push(`/requests/${state.data.id}?new=1`);
    }
  }, [state, router]);

  function saveDraft() {
    if (!formRef.current) return;
    const fd = new FormData(formRef.current);
    const draft: Record<string, string> = {};
    for (const k of DRAFT_FIELDS) { const v = fd.get(k); if (typeof v === "string" && v) draft[k] = v; }
    try { localStorage.setItem(DRAFT_KEY, JSON.stringify(draft)); } catch {}
  }

  const insts = institutions.filter((i) => i.country_code === geo.country && (!geo.city || i.city_id === geo.city));

  return (
    <form ref={formRef} action={action} onChange={saveDraft} className="card flex flex-col gap-4">
      {hasDraft && !restored && <button type="button" className="btn-outline self-start" onClick={restoreDraft}>{t.request.draftRestored}</button>}
      {!online && <Notice tone="warn">{t.common.offline} {t.request.draftSaved}</Notice>}
      <div className="field">
        <label className="label" htmlFor="relation">{t.request.relation}</label>
        <select id="relation" name="relation" className="input" required defaultValue="family">
          {RELATIONS.map((r) => <option key={r} value={r}>{t.request[`relation_${r}`]}</option>)}
        </select>
      </div>
      <div className="field">
        <label className="label" htmlFor="patient_initials">{t.request.patientInitials}</label>
        <input id="patient_initials" name="patient_initials" className="input" maxLength={12} />
        <span className="hint">{t.request.patientInitialsHint}</span>
      </div>
      <BloodGroupPicker />
      <div className="grid grid-cols-2 gap-4">
        <div className="field">
          <label className="label" htmlFor="units">{t.request.units}</label>
          <input id="units" name="units" type="number" min={1} max={20} defaultValue={1} required className="input latin" />
        </div>
        <div className="field">
          <label className="label" htmlFor="urgency">{t.request.urgency}</label>
          <select id="urgency" name="urgency" className="input" defaultValue="urgent">
            {URGENCY.map((u) => <option key={u} value={u}>{t.request[`urgency_${u}`]}</option>)}
          </select>
        </div>
      </div>
      <CountryCitySelect cities={cities} defaultCountry={defaultCountry} defaultCity={defaultCity} onChange={(country, city) => setGeo({ country, city })} />
      <div className="field">
        <label className="label" htmlFor="institution">{t.request.institution}</label>
        <select id="institution" name="institution" className="input" defaultValue="">
          <option value="">{t.request.institutionNone}</option>
          {insts.map((i) => <option key={i.id} value={i.id}>{locale === "ar" ? i.name_ar : i.name_en || i.name_ar}</option>)}
        </select>
        <span className="hint">{t.request.institutionHint}</span>
      </div>
      <div className="field">
        <label className="label" htmlFor="hospital_name">{t.request.hospital}</label>
        <input id="hospital_name" name="hospital_name" className="input" required minLength={2} maxLength={160} />
        <span className="hint">{t.request.hospitalHint}</span>
      </div>
      <div className="field">
        <label className="label" htmlFor="required_by">{t.request.requiredBy}</label>
        <input id="required_by" name="required_by" type="datetime-local" className="input latin" required min={minDate} />
      </div>
      <div className="field">
        <label className="label" htmlFor="notes">{t.request.notes}</label>
        <textarea id="notes" name="notes" className="input min-h-20" maxLength={500} />
        <span className="hint">{t.request.notesHint}</span>
      </div>
      <div className="field">
        <label className="label" htmlFor="documents">{t.request.documents}</label>
        <input id="documents" name="documents" type="file" multiple accept="application/pdf,image/jpeg,image/png,image/webp" className="input py-2" />
        <span className="hint">{t.request.documentsHint}</span>
      </div>
      <label className="flex items-start gap-3 text-sm">
        <input type="checkbox" name="declaration" required className="mt-1 h-5 w-5 accent-[var(--color-brand)]" />
        <span>{t.request.declaration}</span>
      </label>
      <FormMessage state={state} />
      <SubmitButton disabled={!online}>{t.request.submit}</SubmitButton>
    </form>
  );
}
