import { test } from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { ameerHost, ameerIngest, AMEER_SUB } from "../worker/ameer.js";

function kv() {
  const m = new Map();
  return {
    m,
    async get(k, o) { const v = m.get(k); return v == null ? null : o?.type === "json" ? JSON.parse(v) : v; },
    async put(k, v) { m.set(k, v); },
    async delete(k) { m.delete(k); },
    async list({ prefix }) { return { keys: [...m.keys()].filter((k) => k.startsWith(prefix)).map((name) => ({ name })) }; },
  };
}
const OWNER = "owner@example.com";
const as = (email) => async () => email;
const env = () => ({ AMEER: kv(), AMEER_OWNER_EMAILS: OWNER, AMEER_INGEST_TOKEN: "s3cret-token" });
const get = (path, init) => { const u = new URL("https://ameer.albushra.app" + path); return [new Request(u, init), u]; };

test("the subdomain is reserved from the registry", async () => {
  const reg = JSON.parse(await readFile(new URL("../registry/apps.json", import.meta.url), "utf8"));
  assert.ok(!reg.apps.some((a) => a.subdomain === AMEER_SUB));
});

test("no Access login -> 401, nothing served", async () => {
  const [r, u] = get("/api/state");
  const res = await ameerHost(r, env(), u, as(null));
  assert.equal(res.status, 401);
});

test("fails closed when AMEER_OWNER_EMAILS is not set", async () => {
  const e = env(); delete e.AMEER_OWNER_EMAILS;
  const [r, u] = get("/");
  assert.equal((await ameerHost(r, e, u, as(OWNER))).status, 503);
});

test("another Access identity -> 403", async () => {
  const [r, u] = get("/");
  assert.equal((await ameerHost(r, env(), u, as("someone@else.com"))).status, 403);
});

test("owner gets the page with a strict CSP", async () => {
  const [r, u] = get("/");
  const res = await ameerHost(r, env(), u, as("Owner@Example.com"));
  assert.equal(res.status, 200);
  assert.match(res.headers.get("content-security-policy"), /frame-ancestors 'none'/);
  assert.match(await res.text(), /ameer\.js/);
});

test("ingest rejects a wrong token and accepts the right one", async () => {
  const e = env();
  const body = JSON.stringify({ kind: "device", data: { id: "Home-PC", name: "Home PC", cpu: 150, mem: 40 } });
  const bad = await ameerIngest(new Request("https://albushra.app/__ameer/ingest", { method: "POST", headers: { authorization: "Bearer nope" }, body }), e);
  assert.equal(bad.status, 401);
  const ok = await ameerIngest(new Request("https://albushra.app/__ameer/ingest", { method: "POST", headers: { authorization: "Bearer s3cret-token" }, body }), e);
  assert.equal(ok.status, 200);
  const d = JSON.parse(e.AMEER.m.get("device:home-pc"));
  assert.equal(d.cpu, 100);

  await ameerIngest(new Request("https://albushra.app/__ameer/ingest", { method: "POST", headers: { authorization: "Bearer s3cret-token" }, body: JSON.stringify({ kind: "log", data: { title: "Built the dashboard", url: "javascript:alert(1)" } }) }), e);
  const [r, u] = get("/api/state");
  const st = await (await ameerHost(r, e, u, as(OWNER))).json();
  assert.equal(st.devices.length, 1);
  assert.equal(st.log[0].title, "Built the dashboard");
  assert.equal(st.log[0].url, "");
});

test("notes need the same-origin header", async () => {
  const e = env();
  const [r1, u1] = get("/api/notes", { method: "POST", body: JSON.stringify({ op: "add", text: "x" }) });
  assert.equal((await ameerHost(r1, e, u1, as(OWNER))).status, 400);
  const [r2, u2] = get("/api/notes", { method: "POST", headers: { "x-ameer": "1" }, body: JSON.stringify({ op: "add", text: "Call the bank" }) });
  const j = await (await ameerHost(r2, e, u2, as(OWNER))).json();
  assert.equal(j.notes[0].text, "Call the bank");
});
