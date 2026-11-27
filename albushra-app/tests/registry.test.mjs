// Guards for the Application Registry: run with `npm test`.
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const reg = JSON.parse(await readFile(new URL("../registry/apps.json", import.meta.url), "utf8"));
const cats = new Set(reg.categories.map((c) => c.id));
const STATUSES = new Set(["live", "beta", "prototype", "soon", "archived", "hidden"]);

test("ids and subdomains are unique", () => {
  const ids = reg.apps.map((a) => a.id);
  assert.equal(new Set(ids).size, ids.length, "duplicate id");
  const subs = reg.apps.map((a) => a.subdomain).filter(Boolean);
  assert.equal(new Set(subs).size, subs.length, "duplicate subdomain");
  for (const s of subs) {
    assert.match(s, /^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/, `bad subdomain ${s}`);
    assert.ok(!["www", "dash"].includes(s), `${s} is reserved`);
  }
});

test("every app is well formed", () => {
  for (const a of reg.apps) {
    assert.ok(cats.has(a.category), `${a.id}: unknown category ${a.category}`);
    assert.ok(STATUSES.has(a.status), `${a.id}: unknown status ${a.status}`);
    assert.ok(a.name?.ar && a.name?.en, `${a.id}: name needs ar + en`);
    if (a.status !== "hidden") assert.ok(a.tagline?.ar && a.tagline?.en, `${a.id}: tagline needs ar + en`);
    if (a.subdomain && a.status !== "hidden") {
      assert.ok(a.route, `${a.id}: has a subdomain but no route`);
      assert.ok(["proxy", "redirect", "dns"].includes(a.route.mode), `${a.id}: bad route mode`);
      if (a.route.mode !== "dns") assert.match(a.route.target, /^https:\/\//, `${a.id}: target must be https`);
      else assert.ok(a.route.record?.type && a.route.record?.content, `${a.id}: dns mode needs route.record`);
    }
  }
});

test("no secrets in the registry", () => {
  const text = JSON.stringify(reg);
  const patterns = [/sk-ant-[A-Za-z0-9_-]{10,}/, /AIza[0-9A-Za-z_-]{30,}/, /eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}/, /ghp_[A-Za-z0-9]{20,}/, /-----BEGIN [A-Z ]*PRIVATE KEY-----/];
  for (const p of patterns) assert.doesNotMatch(text, p);
  for (const a of reg.apps) for (const v of a.envVars || []) assert.doesNotMatch(v, /=/, `${a.id}: envVars holds names only`);
});

test("every public app has privacy facts", async () => {
  const priv = JSON.parse(await readFile(new URL("../registry/privacy.json", import.meta.url), "utf8"));
  for (const a of reg.apps) {
    if (a.status === "hidden") continue;
    const p = priv.apps[a.id];
    assert.ok(p, `${a.id}: missing in registry/privacy.json`);
    if (!p.existing) {
      assert.ok(p.data?.ar?.length && p.data?.en?.length, `${a.id}: privacy data needs ar + en`);
      assert.ok(p.where?.ar && p.where?.en, `${a.id}: privacy "where" needs ar + en`);
    }
  }
});

test("AdSense id is well formed when present", () => {
  const c = reg.company.adsense?.client;
  if (c) assert.match(c, /^ca-pub-\d{16}$/);
});
