"use client";
import { useI18n } from "@/lib/i18n/client";
import { sendManualMatch } from "@/app/actions/requests";
import { ActionForm, SubmitButton } from "@/components/forms";

export function SendRequestButton({ donorId, requests }: { donorId: string; requests: { id: string; reference: string }[] }) {
  const { t } = useI18n();
  return (
    <ActionForm action={sendManualMatch} className="flex flex-col gap-2">
      <input type="hidden" name="donor_id" value={donorId} />
      {requests.length === 1 ? <input type="hidden" name="request_id" value={requests[0].id} /> : (
        <select name="request_id" className="input latin" required aria-label={t.search.chooseRequest}>
          {requests.map((r) => <option key={r.id} value={r.id}>{r.reference}</option>)}
        </select>
      )}
      <SubmitButton className="btn-navy">{t.search.sendRequest}</SubmitButton>
    </ActionForm>
  );
}
