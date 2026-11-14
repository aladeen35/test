"use client";
import { useActionState, useEffect, useRef, useState } from "react";
import { useFormStatus } from "react-dom";
import { useI18n } from "@/lib/i18n/client";
import type { ActionState } from "@/lib/errors";
import type { City } from "@/lib/geo";

export function SubmitButton({ children, className = "btn-primary", pendingText, ...rest }: React.ButtonHTMLAttributes<HTMLButtonElement> & { pendingText?: string }) {
  const { pending } = useFormStatus();
  const { t } = useI18n();
  return (
    <button type="submit" className={className} disabled={pending || rest.disabled} aria-busy={pending} {...rest}>
      {pending ? pendingText ?? t.common.loading : children}
    </button>
  );
}

export function FormMessage({ state }: { state: ActionState }) {
  if (!state) return null;
  if (state.error) return <p role="alert" className="rounded-[var(--radius-tile)] bg-brand-50 px-4 py-3 text-sm text-brand-600">{state.error}</p>;
  if (state.message) return <p role="status" className="rounded-[var(--radius-tile)] bg-success-50 px-4 py-3 text-sm text-success">{state.message}</p>;
  return null;
}

type ServerAction = (prev: ActionState, fd: FormData) => Promise<ActionState>;

/** A form bound to a server action with inline success/error feedback. */
export function ActionForm({
  action, children, className = "flex flex-col gap-4", confirmText, resetOnSuccess = false, onSuccess,
}: {
  action: ServerAction; children: React.ReactNode; className?: string; confirmText?: string; resetOnSuccess?: boolean; onSuccess?: (s: ActionState) => void;
}) {
  const [state, formAction] = useActionState(action, null);
  const ref = useRef<HTMLFormElement>(null);
  useEffect(() => {
    if (state?.ok) {
      if (resetOnSuccess) ref.current?.reset();
      onSuccess?.(state);
    }
  }, [state, resetOnSuccess, onSuccess]);
  return (
    <form
      ref={ref}
      action={formAction}
      className={className}
      onSubmit={(e) => {
        if (confirmText && !window.confirm(confirmText)) e.preventDefault();
      }}
    >
      {children}
      <FormMessage state={state} />
    </form>
  );
}

/** Inline single-button action (approve, cancel …). */
export function ActionButton({
  action, fields, label, className = "btn-outline", confirmText,
}: { action: ServerAction; fields: Record<string, string>; label: string; className?: string; confirmText?: string }) {
  return (
    <ActionForm action={action} confirmText={confirmText} className="inline-flex flex-col gap-2">
      {Object.entries(fields).map(([k, v]) => <input key={k} type="hidden" name={k} value={v} />)}
      <SubmitButton className={className}>{label}</SubmitButton>
    </ActionForm>
  );
}

export function CountryCitySelect({
  cities, defaultCountry, defaultCity, countryName = "country", cityName = "city", required = true, allowAnyCity = false, onChange,
}: {
  cities: City[]; defaultCountry?: string | null; defaultCity?: string | null; countryName?: string; cityName?: string;
  required?: boolean; allowAnyCity?: boolean; onChange?: (country: string, city: string) => void;
}) {
  const { t, locale } = useI18n();
  const [country, setCountry] = useState(defaultCountry ?? "");
  const [city, setCity] = useState(defaultCity ?? "");
  const list = cities.filter((c) => c.country_code === country);
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <div className="field">
        <label className="label" htmlFor={`${countryName}-sel`}>{t.common.country}</label>
        <select id={`${countryName}-sel`} name={countryName} className="input" required={required} value={country}
          onChange={(e) => { setCountry(e.target.value); setCity(""); onChange?.(e.target.value, ""); }}>
          <option value="">{t.common.selectCountry}</option>
          <option value="SD">{t.common.sudan}</option>
          <option value="SA">{t.common.saudi}</option>
        </select>
      </div>
      <div className="field">
        <label className="label" htmlFor={`${cityName}-sel`}>{t.common.city}</label>
        <select id={`${cityName}-sel`} name={cityName} className="input" required={required && !allowAnyCity} value={city} disabled={!country}
          onChange={(e) => { setCity(e.target.value); onChange?.(country, e.target.value); }}>
          <option value="">{allowAnyCity ? t.common.all : t.common.selectCity}</option>
          {list.map((c) => <option key={c.id} value={c.id}>{locale === "ar" ? c.name_ar : c.name_en}</option>)}
        </select>
      </div>
    </div>
  );
}

export function BloodGroupPicker({ name = "blood_group", defaultValue, allowAny = false, required = true }: { name?: string; defaultValue?: string | null; allowAny?: boolean; required?: boolean }) {
  const { t } = useI18n();
  const groups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];
  return (
    <fieldset className="field">
      <legend className="label mb-1.5">{t.common.bloodGroup}</legend>
      <div className="grid grid-cols-4 gap-2">
        {allowAny && (
          <label className="col-span-4 sm:col-span-1">
            <input type="radio" name={name} value="" defaultChecked={!defaultValue} className="peer sr-only" />
            <span className="flex min-h-11 cursor-pointer items-center justify-center rounded-full bg-surface-2 text-sm font-semibold text-navy peer-checked:bg-brand peer-checked:text-white peer-focus-visible:ring-2 peer-focus-visible:ring-brand-400">{t.common.anyGroup}</span>
          </label>
        )}
        {groups.map((g) => (
          <label key={g}>
            <input type="radio" name={name} value={g} defaultChecked={defaultValue === g} required={required && !allowAny} className="peer sr-only" />
            <span className="latin flex min-h-12 cursor-pointer items-center justify-center rounded-full bg-surface-2 font-bold text-navy transition-colors peer-checked:bg-brand peer-checked:shadow-[0_8px_18px_-8px_rgb(198_40_40/0.8)] peer-checked:text-white peer-focus-visible:ring-2 peer-focus-visible:ring-brand-400">{g}</span>
          </label>
        ))}
      </div>
    </fieldset>
  );
}
