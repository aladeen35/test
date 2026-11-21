// ameer.albushra.app — the owner's private command center.
//
// Everything on this host (page, scripts, data) is served by the Worker itself,
// never by Cloudflare Pages, so nothing about it is reachable from a public URL.
// Two locks, both required:
//   1. Cloudflare Access in front of the host (the owner's login).
//   2. This Worker re-verifies the Access JWT and checks the email against the
//      AMEER_OWNER_EMAILS secret. Unset secret = locked (fail closed).
//
// Data comes in through https://albushra.app/__ameer/ingest (no Access there,
// so the GitHub collector, the PC agent and Claude sessions can post) with
// `Authorization: Bearer <AMEER_INGEST_TOKEN>`. Stored in the AMEER KV namespace:
//   snapshot          GitHub + sites + cloud, written by scripts/ameer-collect.mjs
//   device:<id>       one heartbeat per computer (scripts in ameer/agent/)
//   log               newest-first list of work entries (max 200)
//   notes             the owner's own notes from the dashboard (max 100)

import ASSETS from "./ameer-assets.js";

export const AMEER_SUB = "ameer";
const MAX_BODY = 2_000_000;
const DEVICE_RE = /^[a-z0-9][a-z0-9._-]{0,63}$/;

export async function ameerHost(request, env, url, accessIdentity) {
  const who = await accessIdentity(request, env, env.AMEER_ACCESS_AUD || env.ACCESS_AUD);
  if (!who) return locked(401, "تسجيل الدخول عبر Cloudflare Access مطلوب", "Cloudflare Access login required");
  const owners = String(env.AMEER_OWNER_EMAILS || "")
    .split(/[\s,;]+/)
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
  if (!owners.length) return locked(503, "اللوحة مقفلة: لم يُضبط بريد المالك بعد (AMEER_OWNER_EMAILS)", "Locked: AMEER_OWNER_EMAILS is not set");
  if (!owners.includes(String(who).toLowerCase())) return locked(403, "هذا الحساب غير مصرّح له", "This account is not allowed");

  const p = url.pathname;
  if (p.startsWith("/api/")) return api(request, env, p, who);

  const asset = ASSETS[p === "/" ? "/index.html" : p];
  if (!asset || request.method !== "GET") return text("Not found", 404);
  return new Response(asset.body, {
    headers: {
      "content-type": asset.type,
      "cache-control": "private, no-cache",
      "x-robots-tag": "noindex, nofollow",
      "referrer-policy": "no-referrer",
      "x-content-type-options": "nosniff",
      "x-frame-options": "DENY",
      "content-security-policy":
        "default-src 'self'; img-src 'self' data: https://albushra.app https://avatars.githubusercontent.com; " +
        "style-src 'self' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; script-src 'self'; " +
        "connect-src 'self' https://api.open-meteo.com; frame-ancestors 'none'; base-uri 'none'; form-action 'none'",
    },
  });
}

async function api(request, env, p, who) {
  if (!env.AMEER) return json({ ok: false, error: "AMEER KV is not bound" }, 503);
  if (request.method !== "GET" && request.headers.get("x-ameer") !== "1") return json({ ok: false, error: "missing header" }, 400);

  if (p === "/api/state" && request.method === "GET") {
    const [snapshot, log, notes, list] = await Promise.all([
      env.AMEER.get("snapshot", { type: "json" }),
      env.AMEER.get("log", { type: "json" }),
      env.AMEER.get("notes", { type: "json" }),
      env.AMEER.list({ prefix: "device:" }),
    ]);
    const devices = (await Promise.all(list.keys.map((k) => env.AMEER.get(k.name, { type: "json" })))).filter(Boolean);
    return json({ ok: true, me: who, now: new Date().toISOString(), snapshot, devices, log: log || [], notes: notes || [] });
  }

  if (p === "/api/notes" && request.method === "POST") {
    const body = await readJson(request);
    if (!body) return json({ ok: false, error: "bad json" }, 400);
    let notes = (await env.AMEER.get("notes", { type: "json" })) || [];
    if (body.op === "add") {
      const t = clip(body.text, 500);
      if (!t) return json({ ok: false, error: "empty" }, 400);
      notes.unshift({ id: crypto.randomUUID(), text: t, at: new Date().toISOString(), done: false });
    } else if (body.op === "toggle") {
      notes = notes.map((n) => (n.id === body.id ? { ...n, done: !n.done } : n));
    } else if (body.op === "delete") {
      notes = notes.filter((n) => n.id !== body.id);
    } else return json({ ok: false, error: "bad op" }, 400);
    notes = notes.slice(0, 100);
    await env.AMEER.put("notes", JSON.stringify(notes));
    return json({ ok: true, notes });
  }

  if (p === "/api/device" && request.method === "DELETE") {
    const id = new URL(request.url).searchParams.get("id") || "";
    if (!DEVICE_RE.test(id)) return json({ ok: false, error: "bad id" }, 400);
    await env.AMEER.delete("device:" + id);
    return json({ ok: true });
  }

  return json({ ok: false, error: "not found" }, 404);
}

// POST https://albushra.app/__ameer/ingest  (Bearer AMEER_INGEST_TOKEN)
//   { "kind": "snapshot", "data": {...} }
//   { "kind": "device", "data": { "id": "home-pc", ... } }
//   { "kind": "log", "data": { "title": "...", "detail": "...", "repo": "...", "url": "...", "source": "claude" } }
export async function ameerIngest(request, env) {
  if (request.method !== "POST") return json({ ok: false, error: "method not allowed" }, 405);
  if (!env.AMEER || !env.AMEER_INGEST_TOKEN) return json({ ok: false, error: "not configured" }, 503);
  const auth = request.headers.get("authorization") || "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7).trim() : "";
  if (!(await sameSecret(token, env.AMEER_INGEST_TOKEN))) return json({ ok: false, error: "unauthorized" }, 401);
  const len = Number(request.headers.get("content-length") || 0);
  if (len > MAX_BODY) return json({ ok: false, error: "too large" }, 413);
  const body = await readJson(request);
  if (!body || typeof body.data !== "object" || !body.data) return json({ ok: false, error: "bad json" }, 400);
  const now = new Date().toISOString();

  if (body.kind === "snapshot") {
    await env.AMEER.put("snapshot", JSON.stringify({ ...body.data, receivedAt: now }));
    return json({ ok: true });
  }
  if (body.kind === "device") {
    const d = body.data;
    const id = String(d.id || "").toLowerCase();
    if (!DEVICE_RE.test(id)) return json({ ok: false, error: "bad device id" }, 400);
    const clean = {
      id,
      name: clip(d.name || id, 60),
      os: clip(d.os, 80),
      kind: ["pc", "laptop", "server", "phone"].includes(d.kind) ? d.kind : "pc",
      cpu: num(d.cpu, 0, 100),
      mem: num(d.mem, 0, 100),
      disk: num(d.disk, 0, 100),
      memTotalGb: num(d.memTotalGb, 0, 4096),
      diskFreeGb: num(d.diskFreeGb, 0, 1e6),
      battery: d.battery == null ? null : num(d.battery, 0, 100),
      charging: d.charging == null ? null : !!d.charging,
      uptimeH: num(d.uptimeH, 0, 1e6),
      ip: clip(request.headers.get("cf-connecting-ip"), 60),
      country: clip(request.headers.get("cf-ipcountry"), 4),
      every: num(d.every, 1, 1440) || 5,
      seen: now,
    };
    await env.AMEER.put("device:" + id, JSON.stringify(clean));
    return json({ ok: true });
  }
  if (body.kind === "log") {
    const d = body.data;
    const title = clip(d.title, 200);
    if (!title) return json({ ok: false, error: "title required" }, 400);
    const entry = {
      id: crypto.randomUUID(),
      at: now,
      title,
      detail: clip(d.detail, 2000),
      repo: clip(d.repo, 100),
      url: /^https:\/\//.test(d.url || "") ? clip(d.url, 500) : "",
      source: clip(d.source || "claude", 30),
      status: ["done", "working", "blocked", "info"].includes(d.status) ? d.status : "done",
    };
    const log = (await env.AMEER.get("log", { type: "json" })) || [];
    log.unshift(entry);
    await env.AMEER.put("log", JSON.stringify(log.slice(0, 200)));
    return json({ ok: true, id: entry.id });
  }
  return json({ ok: false, error: "unknown kind" }, 400);
}

// Constant-time comparison of SHA-256 digests (lengths never leak).
async function sameSecret(a, b) {
  if (!a || !b) return false;
  const enc = new TextEncoder();
  const [x, y] = await Promise.all([crypto.subtle.digest("SHA-256", enc.encode(a)), crypto.subtle.digest("SHA-256", enc.encode(b))]);
  const u = new Uint8Array(x);
  const v = new Uint8Array(y);
  let diff = 0;
  for (let i = 0; i < u.length; i++) diff |= u[i] ^ v[i];
  return diff === 0;
}

async function readJson(request) {
  try {
    return await request.json();
  } catch (e) {
    return null;
  }
}
function clip(s, n) {
  return s == null ? "" : String(s).slice(0, n);
}
function num(v, lo, hi) {
  const n = Number(v);
  return Number.isFinite(n) ? Math.min(hi, Math.max(lo, Math.round(n * 10) / 10)) : null;
}
function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store", "x-robots-tag": "noindex" },
  });
}
function text(s, status) {
  return new Response(s, { status, headers: { "content-type": "text/plain; charset=utf-8", "cache-control": "no-store" } });
}
function locked(status, ar, en) {
  const html = `<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex">
<title>أمير — مقفل</title><body style="margin:0;min-height:100vh;display:grid;place-items:center;background:#0b0d17;color:#e9ecff;font-family:system-ui,sans-serif;text-align:center;padding:16px">
<div><div style="font-size:44px">🔒</div><h1 style="font-size:20px">${ar}</h1><p style="opacity:.6">${en}</p></div></body></html>`;
  return new Response(html, { status, headers: { "content-type": "text/html; charset=utf-8", "cache-control": "no-store", "x-robots-tag": "noindex" } });
}
