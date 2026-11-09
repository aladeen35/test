import { getDict } from "@/lib/i18n/server";
import { WaitScreen } from "@/components/wait-screen";

export default async function Loading() {
  const { t } = await getDict();
  return <WaitScreen t={t} />;
}
