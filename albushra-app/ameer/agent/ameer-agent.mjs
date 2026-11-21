#!/usr/bin/env node
// Ameer agent for Mac / Linux (Node.js 18+): sends this computer's status to
// ameer.albushra.app. Replace PASTE_TOKEN_HERE with your AMEER_INGEST_TOKEN
// (or set the AMEER_TOKEN environment variable), then run every 5 minutes:
//   crontab -e   ->   */5 * * * * node ~/ameer-agent.mjs
// It only reads CPU / memory / disk / uptime. It never reads files.
import os from "node:os";
import { statfsSync } from "node:fs";

const TOKEN = process.env.AMEER_TOKEN || "PASTE_TOKEN_HERE";
const URL = "https://albushra.app/__ameer/ingest";
const name = os.hostname();
const id = name.toLowerCase().replace(/[^a-z0-9._-]/g, "-").slice(0, 64);

function cpuTimes() {
  return os.cpus().reduce((a, c) => {
    const t = c.times;
    a.idle += t.idle;
    a.total += t.user + t.nice + t.sys + t.idle + t.irq;
    return a;
  }, { idle: 0, total: 0 });
}
const a = cpuTimes();
await new Promise((r) => setTimeout(r, 1000));
const b = cpuTimes();
const cpu = 100 * (1 - (b.idle - a.idle) / Math.max(1, b.total - a.total));

let disk = null, diskFreeGb = null;
try {
  const s = statfsSync("/");
  disk = 100 * (1 - s.bavail / s.blocks);
  diskFreeGb = (s.bavail * s.bsize) / 1e9;
} catch {}

const data = {
  id, name,
  kind: os.platform() === "darwin" ? "laptop" : "pc",
  os: `${os.type()} ${os.release()}`,
  cpu, mem: 100 * (1 - os.freemem() / os.totalmem()), memTotalGb: os.totalmem() / 2 ** 30,
  disk, diskFreeGb, uptimeH: os.uptime() / 3600, every: 5,
};
const res = await fetch(URL, {
  method: "POST",
  headers: { "content-type": "application/json", authorization: `Bearer ${TOKEN}` },
  body: JSON.stringify({ kind: "device", data }),
});
console.log(res.ok ? `ok: ${name}` : `failed: ${res.status} ${await res.text()}`);
process.exitCode = res.ok ? 0 : 1;
