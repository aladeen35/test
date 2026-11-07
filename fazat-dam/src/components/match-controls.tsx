"use client";
import { useActionState, useState } from "react";
import { useI18n } from "@/lib/i18n/client";
import { revealContact, setContactConsent, scheduleAppointment, recordDonation, respondToMatch } from "@/app/actions/requests";
import { blockUser, reportMatchParty } from "@/app/actions/account";
import { ActionForm, FormMessage, SubmitButton } from "./forms";
import { REPORT_REASONS } from "@/lib/constants";
import { PhoneIcon } from "./icons";

export function RevealContact({ matchId }: { matchId: string }) {
  const { t } = useI18n();
  const [state, action] = useActionState(revealContact, null);
  const d = state?.data as { name: string; phone: string; method: string } | undefined;
  if (d) {
    const digits = d.phone.replace(/\D/g, "");
    return (
      <div className="flex flex-col gap-2 rounded-xl bg-success-50 p-3 text-sm">
        <span className="font-semibold text-navy">{d.name}</span>
        <span className="latin text-lg font-bold text-navy">+{digits}</span>
        <div className="flex flex-wrap gap-2">
          <a className="btn-navy min-h-10 text-sm" href={`tel:+${digits}`}><PhoneIcon className="h-5 w-5" />{t.donor.contact_phone_call}</a>
          <a className="btn-outline min-h-10 text-sm" href={`https://wa.me/${digits}`} target="_blank" rel="noopener noreferrer">{t.donor.contact_whatsapp}</a>
          <a className="btn-outline min-h-10 text-sm" href={`sms:+${digits}`}>{t.donor.contact_sms}</a>
        </div>
      </div>
    );
  }
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="match_id" value={matchId} />
      <SubmitButton className="btn-navy">{t.match.showContact}</SubmitButton>
      <FormMessage state={state} />
    </form>
  );
}

/** Consent buttons for one side of a match. */
export function ConsentControls({ matchId, requestId, mine, theirs, shared, side }: { matchId: string; requestId?: string; mine: boolean; theirs: boolean; shared: boolean; side: "donor" | "requester" }) {
  const { t } = useI18n();
  return (
    <div className="flex flex-col gap-2">
      {shared ? <span className="text-sm font-semibold text-success">{t.match.contactShared}</span>
        : mine ? <span className="text-sm text-muted">{t.match.waitingOther}</span>
        : <span className="text-sm text-muted">{t.match.contactHidden}</span>}
      <ActionForm action={setContactConsent} className="flex flex-col gap-2">
        <input type="hidden" name="match_id" value={matchId} />
        {requestId && <input type="hidden" name="request_id" value={requestId} />}
        <input type="hidden" name="consent" value={mine ? "false" : "true"} />
        <SubmitButton className={mine ? "btn-ghost text-sm" : "btn-primary"}>
          {mine ? t.match.revokeContact : theirs ? t.match.approveContact : side === "requester" ? t.match.requestContact : t.match.shareContact}
        </SubmitButton>
      </ActionForm>
      {shared && <RevealContact matchId={matchId} />}
    </div>
  );
}

export function RespondForm({ matchId, accepted }: { matchId: string; accepted: boolean }) {
  const { t } = useI18n();
  const [declining, setDeclining] = useState(false);
  if (accepted) {
    return (
      <ActionForm action={respondToMatch} confirmText={t.match.withdraw + "?"}>
        <input type="hidden" name="match_id" value={matchId} />
        <input type="hidden" name="accept" value="false" />
        <SubmitButton className="btn-ghost text-sm">{t.match.withdraw}</SubmitButton>
      </ActionForm>
    );
  }
  return (
    <div className="flex flex-col gap-2">
      <ActionForm action={respondToMatch} className="flex flex-col gap-2">
        <input type="hidden" name="match_id" value={matchId} />
        <input type="hidden" name="accept" value="true" />
        <label className="flex items-start gap-2 text-sm">
          <input type="checkbox" name="share_contact" className="mt-0.5 h-5 w-5 accent-[var(--color-brand)]" />
          {t.match.shareContact}
        </label>
        <p className="hint">{t.match.eligibilityReminder}</p>
        <SubmitButton>{t.match.accept}</SubmitButton>
      </ActionForm>
      {declining ? (
        <ActionForm action={respondToMatch} className="flex flex-col gap-2">
          <input type="hidden" name="match_id" value={matchId} />
          <input type="hidden" name="accept" value="false" />
          <input name="reason" className="input" maxLength={300} placeholder={t.match.declineReason} aria-label={t.match.declineReason} />
          <SubmitButton className="btn-outline">{t.match.decline}</SubmitButton>
        </ActionForm>
      ) : <button type="button" className="btn-ghost" onClick={() => setDeclining(true)}>{t.match.decline}</button>}
    </div>
  );
}

export function AppointmentForm({ matchId, requestId, country }: { matchId: string; requestId: string; country: string }) {
  const { t } = useI18n();
  return (
    <ActionForm action={scheduleAppointment} className="flex flex-col gap-2">
      <input type="hidden" name="match_id" value={matchId} />
      <input type="hidden" name="request_id" value={requestId} />
      <input type="hidden" name="country" value={country} />
      <label className="label" htmlFor={`at-${matchId}`}>{t.match.appointment}</label>
      <input id={`at-${matchId}`} name="at" type="datetime-local" required className="input latin" />
      <input name="note" className="input" maxLength={300} placeholder={t.match.appointmentNote} aria-label={t.match.appointmentNote} />
      <SubmitButton className="btn-outline">{t.match.setAppointment}</SubmitButton>
    </ActionForm>
  );
}

export function RecordDonationForm({ matchId, requestId }: { matchId: string; requestId?: string }) {
  const { t } = useI18n();
  const today = new Date().toISOString().slice(0, 10);
  return (
    <details className="rounded-xl border border-line p-3">
      <summary className="cursor-pointer text-sm font-semibold text-navy">{t.match.recordDonation}</summary>
      <ActionForm action={recordDonation} className="mt-2 flex flex-col gap-2">
        <input type="hidden" name="match_id" value={matchId} />
        {requestId && <input type="hidden" name="request_id" value={requestId} />}
        <label className="label" htmlFor={`don-${matchId}`}>{t.match.donatedOn}</label>
        <input id={`don-${matchId}`} name="donated_on" type="date" max={today} defaultValue={today} required className="input latin" />
        <p className="hint">{t.match.donationPending}</p>
        <SubmitButton className="btn-outline">{t.common.save}</SubmitButton>
      </ActionForm>
    </details>
  );
}

export function SafetyMenu({ matchId }: { matchId: string }) {
  const { t } = useI18n();
  return (
    <details className="text-sm">
      <summary className="cursor-pointer text-muted">{t.common.report} / {t.common.block}</summary>
      <div className="mt-2 flex flex-col gap-3">
        <ActionForm action={reportMatchParty} className="flex flex-col gap-2">
          <input type="hidden" name="match_id" value={matchId} />
          <select name="reason" className="input" required aria-label={t.report.reason}>
            {REPORT_REASONS.map((r) => <option key={r} value={r}>{t.report[r]}</option>)}
          </select>
          <textarea name="details" className="input" maxLength={1000} placeholder={t.report.details} aria-label={t.report.details} />
          <SubmitButton className="btn-outline">{t.common.report}</SubmitButton>
        </ActionForm>
        <ActionForm action={blockUser} confirmText={`${t.common.block}?`}>
          <input type="hidden" name="match_id" value={matchId} />
          <SubmitButton className="btn-danger">{t.common.block}</SubmitButton>
        </ActionForm>
      </div>
    </details>
  );
}
