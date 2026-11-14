import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getDict } from "@/lib/i18n/server";
import { requireViewer } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { fmtDateTime } from "@/lib/format";
import { sendMessage } from "@/app/actions/requests";
import { ActionForm, SubmitButton } from "@/components/forms";
import { Notice, PageHeader } from "@/components/ui";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.match.messages };
}

export default async function MessagesPage({ params }: PageProps<"/messages/[matchId]">) {
  const { matchId } = await params;
  const { t, locale } = await getDict();
  const viewer = await requireViewer(`/messages/${matchId}`);
  if (!/^[0-9a-f-]{36}$/.test(matchId)) notFound();
  const supabase = await createClient();
  const [{ data: messages, error }, { data: canSend }] = await Promise.all([
    supabase.from("messages").select("id, sender_id, body, created_at").eq("match_id", matchId).order("created_at").limit(200),
    supabase.rpc("can_message", { _match: matchId }),
  ]);
  if (error) notFound();
  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-4">
      <PageHeader title={t.match.messages} intro={t.match.contactHidden} />
      <div className="card flex min-h-64 flex-col gap-2">
        {(messages ?? []).length === 0 && <p className="text-sm text-muted">{t.match.noMessages}</p>}
        {(messages ?? []).map((m) => {
          const mine = m.sender_id === viewer.id;
          return (
            <div key={m.id} className={`max-w-[80%] rounded-3xl px-4 py-2.5 text-sm ${mine ? "self-end bg-navy text-white" : "self-start bg-surface-2 text-navy"}`}>
              <p className="whitespace-pre-wrap break-words" dir="auto">{m.body}</p>
              <p className={`mt-1 text-[0.65rem] ${mine ? "text-white/70" : "text-muted"}`}>{fmtDateTime(m.created_at, locale)}</p>
            </div>
          );
        })}
      </div>
      {canSend ? (
        <ActionForm action={sendMessage} resetOnSuccess className="flex gap-2">
          <input type="hidden" name="match_id" value={matchId} />
          <input name="body" required maxLength={1000} className="input flex-1" placeholder={t.match.messagePlaceholder} aria-label={t.match.messagePlaceholder} dir="auto" />
          <SubmitButton>{t.match.send}</SubmitButton>
        </ActionForm>
      ) : <Notice>{t.match.contactHidden}</Notice>}
    </div>
  );
}
