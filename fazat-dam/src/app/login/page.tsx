import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getDict } from "@/lib/i18n/server";
import { getViewer } from "@/lib/auth";
import { isSupabaseConfigured } from "@/lib/supabase/config";
import { SetupMissing } from "@/components/ui";
import { LoginForm } from "./login-form";

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getDict();
  return { title: t.common.signIn };
}

export default async function LoginPage({ searchParams }: PageProps<"/login">) {
  const { t } = await getDict();
  const sp = await searchParams;
  const next = typeof sp.next === "string" && sp.next.startsWith("/") && !sp.next.startsWith("//") ? sp.next : "/";
  if (await getViewer()) redirect(next);
  return (
    <div className="mx-auto flex max-w-md flex-col gap-4">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src="/brand/logo-full.png" alt={t.meta.name} className="mx-auto w-48" width={495} height={510} />
      {!isSupabaseConfigured() ? <SetupMissing t={t} /> : <LoginForm next={next} linkError={sp.error === "link"} />}
    </div>
  );
}
