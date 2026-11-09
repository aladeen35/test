import "server-only";
import { cookies } from "next/headers";
import type { CountryCode } from "./constants";
import { getViewer } from "./auth";

export const NETWORK_COOKIE = "net";

/** The network (country) the visitor is browsing: profile country, then cookie, then Saudi Arabia. */
export async function getNetwork(): Promise<CountryCode> {
  const viewer = await getViewer();
  const cookie = (await cookies()).get(NETWORK_COOKIE)?.value;
  if (cookie === "SD" || cookie === "SA") return cookie;
  return viewer?.countryCode ?? "SA";
}
