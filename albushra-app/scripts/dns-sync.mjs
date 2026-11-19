// Creates the DNS records the ecosystem needs in the albushra.app zone.
// Additive and idempotent: it never deletes or overwrites a record it did not
// create (records it creates carry the comment "albushra-registry").
//
//   apex  albushra.app      AAAA 100::  proxied   -> handled by the router Worker
//   *     *.albushra.app    AAAA 100::  proxied   -> every subdomain to the Worker
//   www   www.albushra.app  AAAA 100::  proxied   -> Worker redirects to apex
//   apps with route.mode == "dns" get their own record (e.g. a Vercel CNAME)
//
// Env: CLOUDFLARE_API_TOKEN (Zone:DNS:Edit + Zone:Read on albushra.app)
// Flags: --dry-run prints the plan only.

import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const DRY = process.argv.includes("--dry-run");
const TOKEN = process.env.CLOUDFLARE_API_TOKEN;
const reg = JSON.parse(await readFile(join(ROOT, "registry", "apps.json"), "utf8"));
const APEX = reg.company.domain;
const TAG = "albushra-registry";

const wanted = [
  { type: "AAAA", name: APEX, content: "100::", proxied: true },
  { type: "AAAA", name: `*.${APEX}`, content: "100::", proxied: true },
  { type: "AAAA", name: `www.${APEX}`, content: "100::", proxied: true },
];
for (const a of reg.apps) {
  if (a.route?.mode === "dns" && a.subdomain && a.route.record) {
    wanted.push({ name: `${a.subdomain}.${APEX}`, ...a.route.record });
  }
}

if (DRY || !TOKEN) {
  console.log(TOKEN ? "dry run:" : "CLOUDFLARE_API_TOKEN not set; plan only:");
  for (const r of wanted) console.log(`  ${r.type.padEnd(5)} ${r.name.padEnd(32)} ${r.content}${r.proxied ? "  (proxied)" : ""}`);
  process.exit(0);
}

async function cf(path, init = {}) {
  const res = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
    ...init,
    headers: { authorization: `Bearer ${TOKEN}`, "content-type": "application/json", ...(init.headers || {}) },
  });
  const body = await res.json();
  if (!body.success) throw new Error(`${path}: ${JSON.stringify(body.errors)}`);
  return body.result;
}

const [zone] = await cf(`/zones?name=${APEX}`);
if (!zone) throw new Error(`zone ${APEX} not found for this token`);
console.log(`zone ${APEX}: ${zone.status}, plan ${zone.plan?.name}`);
const existing = await cf(`/zones/${zone.id}/dns_records?per_page=500`);

let created = 0, kept = 0, updated = 0, conflicts = 0;
for (const r of wanted) {
  const same = existing.filter((e) => e.name === r.name);
  const exact = same.find((e) => e.type === r.type && e.content === r.content && !!e.proxied === !!r.proxied);
  if (exact) { kept++; continue; }
  const ours = same.find((e) => e.type === r.type && (e.comment || "").includes(TAG));
  if (ours) {
    await cf(`/zones/${zone.id}/dns_records/${ours.id}`, { method: "PATCH", body: JSON.stringify({ ...r, ttl: 1, comment: TAG }) });
    updated++;
    console.log(`updated ${r.type} ${r.name}`);
    continue;
  }
  // CNAME cannot coexist with other types; A/AAAA can. Someone else's record wins.
  const blocking = same.find((e) => e.type === "CNAME" || r.type === "CNAME");
  if (blocking) {
    conflicts++;
    console.warn(`kept existing ${blocking.type} ${blocking.name} -> ${blocking.content} (not created by the registry; left untouched)`);
    continue;
  }
  await cf(`/zones/${zone.id}/dns_records`, { method: "POST", body: JSON.stringify({ ...r, ttl: 1, comment: TAG }) });
  created++;
  console.log(`created ${r.type} ${r.name}`);
}

// SSL / security baseline (safe for proxied origins on HTTPS).
const settings = [
  ["ssl", "strict"],
  ["always_use_https", "on"],
  ["min_tls_version", "1.2"],
  ["automatic_https_rewrites", "on"],
  ["tls_1_3", "on"],
  ["brotli", "on"],
];
for (const [id, value] of settings) {
  try {
    await cf(`/zones/${zone.id}/settings/${id}`, { method: "PATCH", body: JSON.stringify({ value }) });
    console.log(`setting ${id} = ${value}`);
  } catch (e) {
    console.warn(`setting ${id}: ${e.message} (token may lack Zone Settings:Edit; set it in the dashboard)`);
  }
}
console.log(`dns: ${created} created, ${updated} updated, ${kept} unchanged, ${conflicts} left as they were`);
