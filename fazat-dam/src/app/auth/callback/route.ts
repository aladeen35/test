import { NextResponse, type NextRequest } from "next/server";
import type { EmailOtpType } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/server";

/**
 * Lands the user after they click the sign-in link in their email.
 * Supports both link styles Supabase can send: ?code=… (PKCE) and ?token_hash=…&type=….
 */
export async function GET(request: NextRequest) {
  const url = request.nextUrl;
  const nextParam = url.searchParams.get("next");
  const next = nextParam && nextParam.startsWith("/") && !nextParam.startsWith("//") ? nextParam : "/";
  const supabase = await createClient();
  const code = url.searchParams.get("code");
  const tokenHash = url.searchParams.get("token_hash");
  const type = url.searchParams.get("type") as EmailOtpType | null;

  let ok = false;
  if (code) ok = !(await supabase.auth.exchangeCodeForSession(code)).error;
  else if (tokenHash && type) ok = !(await supabase.auth.verifyOtp({ token_hash: tokenHash, type })).error;

  const dest = url.clone();
  dest.search = "";
  if (ok) {
    dest.pathname = "/onboarding";
    dest.searchParams.set("next", next);
  } else {
    dest.pathname = "/login";
    dest.searchParams.set("error", "link");
  }
  return NextResponse.redirect(dest);
}
