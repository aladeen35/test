import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { getDict } from "@/lib/i18n/server";
import { requireViewer } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { cityMap } from "@/lib/geo";
import { cityName, fmtDate, fmtDateTime } from "@/lib/format";
import { TERMINAL_STATUSES, TIMEZONE, type RequestStatus } from "@/lib/constants";
import { transitionRequest, uploadRequestDocument } from "@/app/actions/requests";
import { ActionForm, SubmitButton } from "@/components/forms";
import { BloodChip, Chip, DemoBadge, Empty, MedicalNotice, Notice, StatusBadge } from "@/components/ui";
import { RequestTimeline } from "@/components/request-timeline";
import { AppointmentForm, ConsentControls, RecordDonationForm, SafetyMenu } from "@/components/match-controls";
import { DocLink } from "@/components/doc-link";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.request.track };
}

type MatchRow = {
  match_id: string; donor_alias: string; blood_group: string; is_verified: boolean; status: string; method: "automated" | "manual";
  responded_at: string | null; donor_contact_consent: boolean; requester_contact_consent: boolean; contact_shared_at: string | null;
  appointment_at: string | null; appointment_note: string | null; donation_id: string | null; donation_status: string | null;
};

export default async function RequestPage({ params, searchParams }: PageProps<"/requests/[id]">) {
  const { id } = await params;
  const sp = await searchParams;
  const { t, locale } = await getDict();
  const viewer = await requireViewer(`/requests/${id}`);
  if (!/^[0-9a-f-]{36}$/.test(id)) notFound();
  const supabase = await createClient();
  const { data: r } = await supabase.from("blood_requests").select("*").eq("id", id).maybeSingle();
  if (!r) notFound();
  const isRequester = r.requester_id === viewer.id;
  const [{ data: matches }, { data: docs }, cities] = await Promise.all([
    supabase.rpc("request_matches", { p_request: id }),
    supabase.from("request_documents").select("id, storage_path, file_name, created_at").eq("request_id", id).order("created_at"),
    cityMap(),
  ]);
  const status = r.status as RequestStatus;
  const open = !TERMINAL_STATUSES.includes(status);
  const tz = TIMEZONE[r.country_code as "SD" | "SA"];
  const ms = (matches ?? []) as MatchRow[];

  return (
    <div className="flex flex-col gap-4">
      {sp.new === "1" && <Notice tone="ok">{t.request.submitted.replace("{ref}", r.reference)}</Notice>}
      <div className="card flex flex-wrap items-center gap-4">
        <BloodChip group={r.blood_group} size="lg" />
        <div className="flex flex-1 flex-col gap-1">
          <div className="flex flex-wrap items-center gap-2">
            <h1 className="latin text-xl font-bold text-navy">{r.reference}</h1>
            <StatusBadge status={status} t={t} />
            <Chip tone={r.urgency === "critical" ? "red" : r.urgency === "urgent" ? "amber" : "navy"}>{t.request[`urgency_${r.urgency as "normal"}`]}</Chip>
            {r.is_demo && <DemoBadge t={t} />}
          </div>
          <p className="text-sm text-navy">{r.hospital_name} · {cityName(cities.get(r.city_id), locale)}</p>
          <p className="text-xs text-muted">
            <span className="latin">{r.units}</span> {t.common.units} · {t.request.requiredBy} {fmtDateTime(r.required_by, locale, tz)} · {t.request.created} {fmtDate(r.created_at, locale)}
          </p>
        </div>
      </div>

      {r.review_note && <Notice tone={status === "rejected" ? "error" : "info"}><strong>{t.request.reviewNote}: </strong>{r.review_note}</Notice>}

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        <section className="card lg:col-span-1">
          <h2 className="section-title mb-2">{t.request.timeline}</h2>
          <RequestTimeline status={status} t={t} />
          {isRequester && open && (
            <ActionForm action={transitionRequest} confirmText={t.request.cancelConfirm} className="mt-4">
              <input type="hidden" name="request_id" value={id} />
              <input type="hidden" name="status" value="cancelled" />
              <SubmitButton className="btn-danger w-full">{t.request.cancel}</SubmitButton>
            </ActionForm>
          )}
        </section>

        <section className="flex flex-col gap-3 lg:col-span-2">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <h2 className="section-title">{t.request.matches}</h2>
            {isRequester && ["verified", "matching_donors", "donors_responding"].includes(status) && (
              <Link href={`/donors?country=${r.country_code}&city=${r.city_id}&group=${encodeURIComponent(r.blood_group)}`} className="btn-outline min-h-10 text-sm">{t.request.findMore}</Link>
            )}
          </div>
          {ms.length === 0 ? <Empty>{t.request.noMatches}</Empty> : ms.map((m) => (
            <article key={m.match_id} className="card flex flex-col gap-3">
              <div className="flex flex-wrap items-center gap-2">
                <span className="latin font-bold text-navy">{m.donor_alias}</span>
                <Chip tone={m.status === "accepted" ? "green" : m.status === "pending" ? "amber" : "gray"}>{t.match[m.status as "pending"]}</Chip>
                <Chip tone="navy">{t.match[m.method]}</Chip>
                {m.is_verified && <Chip tone="navy">{t.common.verified}</Chip>}
                {m.donation_status && <Chip tone={m.donation_status === "confirmed" ? "green" : "amber"}>{m.donation_status === "confirmed" ? t.match.donationConfirmed : m.donation_status === "pending_confirmation" ? t.match.donationPending : t.match.donationNotCompleted}</Chip>}
              </div>
              {m.appointment_at && <p className="text-sm text-navy"><strong>{t.match.appointment}:</strong> {fmtDateTime(m.appointment_at, locale, tz)} {m.appointment_note && `— ${m.appointment_note}`}</p>}
              {isRequester && m.status === "accepted" && open && (
                <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                  <ConsentControls matchId={m.match_id} requestId={id} side="requester" mine={m.requester_contact_consent} theirs={m.donor_contact_consent} shared={Boolean(m.contact_shared_at)} />
                  <AppointmentForm matchId={m.match_id} requestId={id} country={r.country_code} />
                </div>
              )}
              {isRequester && m.status === "accepted" && !m.donation_id && <RecordDonationForm matchId={m.match_id} requestId={id} />}
              {isRequester && m.contact_shared_at && <Link href={`/messages/${m.match_id}`} className="btn-ghost self-start text-sm">{t.match.messages}</Link>}
              {isRequester && <SafetyMenu matchId={m.match_id} />}
            </article>
          ))}

          <section className="card flex flex-col gap-2">
            <h2 className="section-title">{t.admin.documents}</h2>
            {(docs ?? []).length === 0 ? <p className="text-sm text-muted">{t.admin.noDocuments}</p> : (
              <ul className="flex flex-col gap-1">{docs!.map((d) => <li key={d.id}><DocLink bucket="request-documents" path={d.storage_path} name={d.file_name} /></li>)}</ul>
            )}
            {isRequester && ["submitted", "under_review"].includes(status) && (
              <ActionForm action={uploadRequestDocument} className="flex flex-col gap-2" resetOnSuccess>
                <input type="hidden" name="request_id" value={id} />
                <input name="documents" type="file" multiple required accept="application/pdf,image/jpeg,image/png,image/webp" className="input py-2" aria-label={t.request.uploadDoc} />
                <span className="hint">{t.request.documentsHint}</span>
                <SubmitButton className="btn-outline">{t.request.uploadDoc}</SubmitButton>
              </ActionForm>
            )}
          </section>
          <p className="text-xs text-muted">{t.request.medicalNote}</p>
        </section>
      </div>
      <MedicalNotice t={t} />
    </div>
  );
}
