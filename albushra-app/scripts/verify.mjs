// Checks every host in the registry over HTTPS and writes a report.
// A route counts as working only if the final response is 2xx/3xx and, when
// the app declares route.expect, the body contains that text.
// Usage: node scripts/verify.mjs [--origins]   (--origins checks the original
// hosts instead of the albushra.app subdomains, useful before DNS is live)

import { readFile, writeFile, mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const ORIGINS = process.argv.includes("--origins");
const reg = JSON.parse(await readFile(join(ROOT, "registry", "apps.json"), "utf8"));
const APEX = reg.company.domain;

const targets = [
  { id: "hub", url: ORIGINS ? reg.hub.pagesOrigin + "/" : `https://${APEX}/`, expect: "albushra" },
  { id: "dash", url: ORIGINS ? reg.hub.pagesOrigin + "/dash/" : `https://dash.${APEX}/`, expect: null },
];
for (const a of reg.apps) {
  if (!a.subdomain || a.status === "hidden") continue;
  // Redirect routes point at the hub itself; nothing separate to check at the origin.
  if (ORIGINS && a.route?.mode === "redirect") continue;
  const url = ORIGINS ? a.route?.target || a.links?.web : `https://${a.subdomain}.${APEX}/`;
  if (url) targets.push({ id: a.id, url, expect: a.route?.expect || null });
}

async function check(t) {
  const started = Date.now();
  try {
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), 20000);
    const res = await fetch(t.url, { signal: ctrl.signal, redirect: "follow" });
    clearTimeout(timer);
    const text = await res.text();
    const okBody = !t.expect || text.toLowerCase().includes(t.expect.toLowerCase());
    return { ...t, status: res.status, finalUrl: res.url, ms: Date.now() - started, ok: res.ok && okBody, note: okBody ? "" : `missing "${t.expect}"` };
  } catch (e) {
    return { ...t, status: 0, ms: Date.now() - started, ok: false, note: String(e.cause?.code || e.message || e) };
  }
}

const results = await Promise.all(targets.map(check));
const lines = results.map((r) => `${r.ok ? "OK  " : "FAIL"} ${String(r.status).padStart(3)} ${r.id.padEnd(16)} ${r.url}${r.note ? "  " + r.note : ""}`);
console.log(lines.join("\n"));
await mkdir(join(ROOT, "dist"), { recursive: true });
await writeFile(join(ROOT, "dist", ORIGINS ? "verify-origins.json" : "verify.json"), JSON.stringify({ at: new Date().toISOString(), results }, null, 2));
const failed = results.filter((r) => !r.ok).length;
console.log(`\n${results.length - failed}/${results.length} reachable`);
if (process.argv.includes("--strict") && failed) process.exit(1);
