import { NextResponse, type NextRequest } from "next/server";
import { timingSafeEqual } from "node:crypto";
import { dispatchPendingPush } from "@/lib/push";

/**
 * Sends pending Web Push notifications. Call it from a Supabase database webhook on
 * notifications INSERT, or from a scheduler, with: Authorization: Bearer <PUSH_DISPATCH_SECRET>.
 */
export async function POST(req: NextRequest) {
  const secret = process.env.PUSH_DISPATCH_SECRET;
  const given = req.headers.get("authorization")?.replace(/^Bearer\s+/i, "") ?? "";
  if (!secret || given.length !== secret.length || !timingSafeEqual(Buffer.from(given), Buffer.from(secret))) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }
  const result = await dispatchPendingPush(200);
  return NextResponse.json(result);
}
