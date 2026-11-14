import type { Metadata } from "next";
import Link from "next/link";
import { getDict } from "@/lib/i18n/server";
import { requireViewer } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { fmtDate, fmtDateTime } from "@/lib/format";
import { TIMEZONE, type RequestStatus } from "@/lib/constants";
import { BloodChip, Chip, DemoBadge, Empty, PageHeader, StatusBadge } from "@/components/ui";
import { ConsentControls, RecordDonationForm, RespondForm, SafetyMenu } from "@/components/match-controls";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.activity.title };
}

type Incoming = {
  match_id: string; match_status: string; method: "automated" | "manual"; matched_at: string; donor_contact_consent: boolean;
  requester_contact_consent: boolean; contact_shared_at: string | null; appointment_at: string | null; appointment_note: string | null;
  request_id: string; reference: string; blood_group: string; units: number; city_ar: string; city_en: string; hospital_name: string;
  urgency: "normal" | "urgent" | "critical"; required_by: string; request_status: RequestStatus; donation_status: string | null; is_demo: boolean;
};

export default async function ActivityPage() {
  const { t, locale } = await getDict();
  const viewer = await requireViewer("/activity");
  const supabase = await createClient();
  const isDonor = viewer.roles.includes("donor");
  const [{ data: incoming }, { data: myRequests }, { data: donations }, { data: donor }] = await Promise.all([
    isDonor ? supabase.rpc("my_donation_requests") : Promise.resolve({ data: [] }),
    supabase.from("blood_requests").select("id, reference, blood_group, status, created_at, hospital_name, is_demo").eq("requester_id", viewer.id).order("created_at", { ascending: false }).limit(50),
    supabase.from("donation_records").select("id, donated_on, status, units").eq("donor_id", viewer.id).order("donated_on", { ascending: false }),
    supabase.from("donor_profiles").select("country_code").eq("user_id", viewer.id).maybeSingle(),
  ]);
  const tz = TIMEZONE[(donor?.country_code ?? "SA") as "SD" | "SA"];
  const live = ["verified", "matching_donors", "donors_responding", "donation_arranged"];

  return (
    <div className="flex flex-col gap-6">
      <PageHeader title={t.activity.title} />

      <section className="flex flex-col gap-3">
        <h2 className="section-title">{t.activity.incoming}</h2>
        {!isDonor ? <Empty action={<Link href="/donate" className="btn-navy">{t.donor.register}</Link>}>{t.activity.notDonor}</Empty>
          : (incoming ?? []).length === 0 ? <Empty>{t.activity.incomingEmpty}</Empty>
          : (incoming as Incoming[]).map((m) => {
            const active = live.includes(m.request_status);
            return (
              <article key={m.match_id} className="card flex flex-col gap-3">
                <div className="flex items-center gap-3">
                  <span className="latin flex h-14 w-14 shrink-0 items-center justify-center rounded-full bg-brand text-lg font-bold text-white">{m.blood_group}</span>
                  <div className="flex min-w-0 flex-1 flex-col gap-0.5">
                    <span className="font-bold leading-6 text-navy">{m.hospital_name}</span>
                    <span className="text-xs text-muted">{locale === "ar" ? m.city_ar : m.city_en} · {t.request.requiredBy} {fmtDateTime(m.required_by, locale, tz)}</span>
                    <span className="latin text-xs text-muted/80">{m.reference}</span>
                  </div>
                </div>
                <div className="flex flex-wrap gap-1.5">
                  <Chip tone={m.urgency === "critical" ? "red" : m.urgency === "urgent" ? "amber" : "navy"}>{t.request[`urgency_${m.urgency}`]}</Chip>
                  <Chip tone={m.match_status === "accepted" ? "green" : m.match_status === "pending" ? "amber" : "gray"}>{t.match[m.match_status as "pending"]}</Chip>
                  {m.is_demo && <DemoBadge t={t} />}
                </div>
                {m.appointment_at && <p className="text-sm"><strong>{t.match.appointment}:</strong> {fmtDateTime(m.appointment_at, locale, tz)} {m.appointment_note && `— ${m.appointment_note}`}</p>}
                {m.donation_status && <Chip tone={m.donation_status === "confirmed" ? "green" : "amber"}>{m.donation_status === "confirmed" ? t.match.donationConfirmed : t.match.donationPending}</Chip>}
                {active && (m.match_status === "pending" || m.match_status === "accepted") && (
                  <div className="tile grid grid-cols-1 gap-4 md:grid-cols-2">
                    <RespondForm matchId={m.match_id} accepted={m.match_status === "accepted"} />
                    {m.match_status === "accepted" && (
                      <ConsentControls matchId={m.match_id} side="donor" mine={m.donor_contact_consent} theirs={m.requester_contact_consent} shared={Boolean(m.contact_shared_at)} />
                    )}
                  </div>
                )}
                {m.match_status === "accepted" && !m.donation_status && <RecordDonationForm matchId={m.match_id} />}
                {m.contact_shared_at && <Link href={`/messages/${m.match_id}`} className="btn-ghost self-start text-sm">{t.match.messages}</Link>}
                <SafetyMenu matchId={m.match_id} />
              </article>
            );
          })}
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="section-title">{t.activity.myRequests}</h2>
        {(myRequests ?? []).length === 0 ? <Empty action={<Link href="/requests/new" className="btn-primary">{t.home.needBlood}</Link>}>{t.request.noRequests}</Empty> : (
          <ul className="flex flex-col gap-2">
            {myRequests!.map((r) => (
              <li key={r.id}>
                <Link href={`/requests/${r.id}`} className="card flex items-center gap-3 hover:ring-2 hover:ring-brand-400/30">
                  <BloodChip group={r.blood_group} />
                  <div className="flex flex-1 flex-col">
                    <span className="latin font-bold text-navy">{r.reference}</span>
                    <span className="text-xs text-muted">{r.hospital_name} · {fmtDate(r.created_at, locale)}</span>
                  </div>
                  <StatusBadge status={r.status} t={t} />
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="section-title">{t.activity.history}</h2>
        {(donations ?? []).length === 0 ? <Empty>{t.activity.historyEmpty}</Empty> : (
          <ul className="card divide-y divide-line">
            {donations!.map((d) => (
              <li key={d.id} className="flex items-center justify-between py-2 text-sm">
                <span>{fmtDate(d.donated_on, locale)}</span>
                <Chip tone={d.status === "confirmed" ? "green" : d.status === "pending_confirmation" ? "amber" : "gray"}>
                  {d.status === "confirmed" ? t.match.donationConfirmed : d.status === "pending_confirmation" ? t.match.donationPending : t.match.donationNotCompleted}
                </Chip>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
