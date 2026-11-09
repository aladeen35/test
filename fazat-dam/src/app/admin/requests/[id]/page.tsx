import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { getDict } from "@/lib/i18n/server";
import { requireViewer } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { cityMap } from "@/lib/geo";
import { cityName, fmtDate, fmtDateTime } from "@/lib/format";
import { TIMEZONE, type RequestStatus } from "@/lib/constants";
import { runMatching, transitionRequest } from "@/app/actions/requests";
import { ActionForm, SubmitButton } from "@/components/forms";
import { BloodChip, Chip, DemoBadge, Empty, MedicalNotice, Notice, PageHeader, StatusBadge } from "@/components/ui";
import { RequestTimeline } from "@/components/request-timeline";
import { AppointmentForm, RecordDonationForm } from "@/components/match-controls";
import { DocLink } from "@/components/doc-link";
import { SendRequestButton } from "@/app/donors/send-request";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.admin.requests };
}

const NEXT: Partial<Record<RequestStatus, RequestStatus[]>> = {
  submitted: ["under_review", "verified", "rejected"],
  under_review: ["verified", "rejected"],
  verified: ["rejected", "completed"],
  matching_donors: ["donation_arranged", "completed"],
  donors_responding: ["matching_donors", "donation_arranged", "completed"],
  donation_arranged: ["donors_responding", "completed"],
};

export default async function ReviewRequest({ params }: PageProps<"/admin/requests/[id]">) {
  const { id } = await params;
  const { t, locale } = await getDict();
  const viewer = await requireViewer(`/admin/requests/${id}`);
  if (!/^[0-9a-f-]{36}$/.test(id)) notFound();
  const supabase = await createClient();
  const { data: r } = await supabase.from("blood_requests").select("*").eq("id", id).maybeSingle();
  if (!r) notFound();
  const { data: canReview } = await supabase.rpc("can_review_request", { _request: id });
  if (!canReview) redirect("/");
  const [{ data: matches }, { data: docs }, { data: requester }, cities, { data: candidates }] = await Promise.all([
    supabase.rpc("request_matches", { p_request: id }),
    supabase.from("request_documents").select("id, storage_path, file_name").eq("request_id", id),
    viewer.isAdmin && r.requester_id ? supabase.from("profiles").select("full_name, phone, account_status").eq("id", r.requester_id).maybeSingle() : Promise.resolve({ data: null }),
    cityMap(),
    ["verified", "matching_donors", "donors_responding"].includes(r.status)
      ? supabase.rpc("search_donors", { p_country: r.country_code, p_city: r.city_id, p_blood_group: r.blood_group, p_available_only: true, p_limit: 20 })
      : Promise.resolve({ data: [] }),
  ]);
  const status = r.status as RequestStatus;
  const tz = TIMEZONE[r.country_code as "SA"];
  const matchedAliases = new Set((matches ?? []).map((m: { donor_alias: string }) => m.donor_alias));
  return (
    <div className="flex flex-col gap-4">
      <PageHeader title={r.reference} />
      <div className="card flex flex-wrap items-center gap-3">
        <BloodChip group={r.blood_group} size="lg" />
        <div className="flex flex-1 flex-col gap-1 text-sm">
          <div className="flex flex-wrap gap-2"><StatusBadge status={status} t={t} /><Chip tone={r.urgency === "critical" ? "red" : "amber"}>{t.request[`urgency_${r.urgency as "normal"}`]}</Chip>{r.is_demo && <DemoBadge t={t} />}</div>
          <span>{r.hospital_name} · {cityName(cities.get(r.city_id), locale)} · <span className="latin">{r.units}</span> {t.common.units}</span>
          <span className="text-muted">{t.request.requiredBy} {fmtDateTime(r.required_by, locale, tz)} · {t.request.created} {fmtDate(r.created_at, locale)}</span>
          <span className="text-muted">{t.request.relation}: {t.request[`relation_${r.requester_relation as "self"}`]}{r.patient_initials ? ` · ${r.patient_initials}` : ""}</span>
          {r.notes && <span><strong>{t.request.notes}:</strong> {r.notes}</span>}
          {requester && <span><strong>{t.admin.requester}:</strong> {requester.full_name} · <span className="latin">+{requester.phone}</span></span>}
        </div>
      </div>
      {r.review_note && <Notice><strong>{t.request.reviewNote}:</strong> {r.review_note}</Notice>}

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        <section className="card flex flex-col gap-3">
          <RequestTimeline status={status} t={t} />
          {(NEXT[status] ?? []).length > 0 && (
            <ActionForm action={transitionRequest} className="flex flex-col gap-2">
              <input type="hidden" name="request_id" value={id} />
              <label className="label" htmlFor="st">{t.common.status}</label>
              <select id="st" name="status" className="input" required>
                {(NEXT[status] ?? []).map((s) => <option key={s} value={s}>{t.status[s]}</option>)}
              </select>
              <textarea name="note" className="input" maxLength={500} placeholder={t.request.reviewNote} aria-label={t.request.reviewNote} />
              <SubmitButton className="btn-navy">{t.common.confirm}</SubmitButton>
            </ActionForm>
          )}
          {["verified", "matching_donors", "donors_responding"].includes(status) && (
            <ActionForm action={runMatching}>
              <input type="hidden" name="request_id" value={id} />
              <SubmitButton>{t.admin.runMatching}</SubmitButton>
            </ActionForm>
          )}
          <h3 className="font-bold text-navy">{t.admin.documents}</h3>
          {(docs ?? []).length === 0 ? <p className="text-sm text-muted">{t.admin.noDocuments}</p> :
            <ul className="flex flex-col gap-1">{docs!.map((d) => <li key={d.id}><DocLink bucket="request-documents" path={d.storage_path} name={d.file_name} /></li>)}</ul>}
        </section>

        <section className="flex flex-col gap-3 lg:col-span-2">
          <h2 className="section-title">{t.request.matches}</h2>
          {(matches ?? []).length === 0 ? <Empty>{t.request.noMatches}</Empty> : (matches as {
            match_id: string; donor_alias: string; status: string; method: "manual"; appointment_at: string | null; donation_id: string | null; donation_status: string | null; is_verified: boolean;
          }[]).map((m) => (
            <article key={m.match_id} className="card flex flex-col gap-2">
              <div className="flex flex-wrap items-center gap-2">
                <span className="latin font-bold">{m.donor_alias}</span>
                <Chip tone={m.status === "accepted" ? "green" : m.status === "pending" ? "amber" : "gray"}>{t.match[m.status as "pending"]}</Chip>
                <Chip>{t.match[m.method]}</Chip>
                {m.donation_status && <Chip tone={m.donation_status === "confirmed" ? "green" : "amber"}>{m.donation_status === "confirmed" ? t.match.donationConfirmed : t.match.donationPending}</Chip>}
              </div>
              {m.appointment_at && <p className="text-sm">{t.match.appointment}: {fmtDateTime(m.appointment_at, locale, tz)}</p>}
              {m.status === "accepted" && (
                <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                  <AppointmentForm matchId={m.match_id} requestId={id} country={r.country_code} />
                  {!m.donation_id && <RecordDonationForm matchId={m.match_id} requestId={id} />}
                </div>
              )}
            </article>
          ))}

          {(candidates ?? []).length > 0 && (
            <section className="card flex flex-col gap-2">
              <h3 className="font-bold text-navy">{t.search.title}</h3>
              <ul className="grid grid-cols-1 gap-2 md:grid-cols-2">
                {(candidates as { donor_id: string; display_name: string; blood_group: string; is_verified: boolean }[]).filter((c) => !matchedAliases.has(c.display_name.split(" · ").pop()!)).map((c) => (
                  <li key={c.donor_id} className="flex items-center gap-2 rounded-xl border border-line p-2">
                    <BloodChip group={c.blood_group} />
                    <span className="latin flex-1 text-sm font-semibold">{c.display_name}</span>
                    <SendRequestButton donorId={c.donor_id} requests={[{ id, reference: r.reference }]} />
                  </li>
                ))}
              </ul>
            </section>
          )}
          <MedicalNotice t={t} />
        </section>
      </div>
    </div>
  );
}
