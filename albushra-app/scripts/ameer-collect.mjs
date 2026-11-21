// Collects the data for ameer.albushra.app and posts it to the Worker.
//
//   GitHub  - every repository the token can see: recent commits on every
//             branch (Claude's work is detected from the commit trailers
//             "Co-Authored-By: Claude", "Claude-Session: …" and claude/* branches),
//             pull requests, the latest Actions runs.
//   Sites   - every public app in registry/apps.json over HTTPS + the router.
//
// Env: AMEER_GH_TOKEN (read-only fine-grained token), AMEER_INGEST_TOKEN,
//      AMEER_INGEST_URL (default https://albushra.app/__ameer/ingest).
// Without AMEER_INGEST_TOKEN it writes dist/ameer-snapshot.json instead.
//
// This runs in a public repository's Actions log: print counts only, never
// commit messages, repository names of private repos, or anything else private.

import { readFile, writeFile, mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const GH = process.env.AMEER_GH_TOKEN || process.env.GITHUB_TOKEN || "";
const INGEST = process.env.AMEER_INGEST_URL || "https://albushra.app/__ameer/ingest";
const TOKEN = process.env.AMEER_INGEST_TOKEN || "";
const DAYS = 30;
const SINCE = new Date(Date.now() - DAYS * 864e5).toISOString();
const MAX_REPOS = 40;
const MAX_BRANCHES = 40;

let rate = null;
async function gh(path) {
  const res = await fetch("https://api.github.com" + path, {
    headers: {
      accept: "application/vnd.github+json",
      "x-github-api-version": "2022-11-28",
      "user-agent": "albushra-ameer-collector",
      ...(GH ? { authorization: `Bearer ${GH}` } : {}),
    },
  });
  const r = res.headers.get("x-ratelimit-remaining");
  if (r != null) rate = Number(r);
  if (res.status === 404 || res.status === 409) return null; // missing / empty repo
  if (!res.ok) throw new Error(`GitHub ${res.status} on ${path.split("?")[0].replace(/\/repos\/[^/]+\/[^/]+/, "/repos/…")}`);
  return res.json();
}

const CLAUDE_RE = /co-authored-by:\s*claude|claude-session:|claude\.ai\/code|generated with \[claude code\]/i;
const SESSION_RE = /https:\/\/claude\.ai\/code\/(session_[A-Za-z0-9]+)/;
const isClaudeBranch = (b) => /^(claude\/|ccr-)/.test(b || "");

async function collectGithub() {
  if (!GH) return { error: "AMEER_GH_TOKEN is not set", repos: [], commits: [], prs: [], sessions: [] };
  const me = await gh("/user").catch(() => null);
  let list = (await gh("/user/repos?per_page=100&sort=pushed&affiliation=owner,collaborator,organization_member")) || [];
  list = list.filter((r) => !r.archived).slice(0, MAX_REPOS);

  const repos = [];
  const commits = new Map();
  const prs = [];
  for (const r of list) {
    const full = r.full_name;
    const recent = new Date(r.pushed_at) > new Date(SINCE);
    const entry = {
      name: r.name,
      full,
      url: r.html_url,
      private: r.private,
      language: r.language,
      defaultBranch: r.default_branch,
      pushedAt: r.pushed_at,
      openIssues: r.open_issues_count,
      runs: [],
      claudeCommits30: 0,
      commits30: 0,
    };
    repos.push(entry);
    if (!recent) continue;

    const branches = ((await gh(`/repos/${full}/branches?per_page=100`)) || []).map((b) => b.name);
    branches.sort((a, b) => (a === r.default_branch ? -1 : b === r.default_branch ? 1 : isClaudeBranch(b) - isClaudeBranch(a)));
    for (const br of branches.slice(0, MAX_BRANCHES)) {
      const cs = (await gh(`/repos/${full}/commits?sha=${encodeURIComponent(br)}&since=${SINCE}&per_page=100`)) || [];
      for (const c of cs) {
        if (commits.has(c.sha)) continue;
        const msg = c.commit.message || "";
        const claude = CLAUDE_RE.test(msg) || /claude/i.test(c.commit.author?.name || "") || isClaudeBranch(br);
        const s = SESSION_RE.exec(msg);
        commits.set(c.sha, {
          repo: r.name,
          sha: c.sha.slice(0, 7),
          msg: msg.split("\n")[0].slice(0, 200),
          at: c.commit.committer?.date || c.commit.author?.date,
          branch: br,
          url: c.html_url,
          author: c.author?.login || c.commit.author?.name || "",
          claude,
          session: s ? s[1] : null,
          merge: (c.parents || []).length > 1,
        });
      }
    }

    const pulls = (await gh(`/repos/${full}/pulls?state=all&sort=updated&direction=desc&per_page=30`)) || [];
    for (const p of pulls) {
      if (new Date(p.updated_at) < new Date(SINCE)) continue;
      prs.push({
        repo: r.name,
        number: p.number,
        title: p.title.slice(0, 200),
        state: p.state,
        merged: !!p.merged_at,
        at: p.merged_at || p.closed_at || p.updated_at,
        url: p.html_url,
        branch: p.head?.ref,
        claude: isClaudeBranch(p.head?.ref) || CLAUDE_RE.test(p.body || ""),
      });
    }

    const runs = (await gh(`/repos/${full}/actions/runs?per_page=15`))?.workflow_runs || [];
    entry.runs = runs.map((x) => ({
      name: x.name,
      status: x.status,
      conclusion: x.conclusion,
      at: x.updated_at,
      branch: x.head_branch,
      event: x.event,
      url: x.html_url,
    }));
  }

  const all = [...commits.values()].filter((c) => !c.merge).sort((a, b) => new Date(b.at) - new Date(a.at));
  for (const e of repos) {
    const mine = all.filter((c) => c.repo === e.name);
    e.commits30 = mine.length;
    e.claudeCommits30 = mine.filter((c) => c.claude).length;
    e.lastCommit = mine[0] ? { msg: mine[0].msg, at: mine[0].at, branch: mine[0].branch, url: mine[0].url } : null;
  }

  // Group Claude's commits into sessions (by the Claude-Session trailer, else by branch).
  const groups = new Map();
  for (const c of all.filter((x) => x.claude)) {
    const key = c.session || `${c.repo}:${c.branch}`;
    const g = groups.get(key) || { id: key, url: c.session ? `https://claude.ai/code/${c.session}` : null, repos: new Set(), branches: new Set(), commits: 0, first: c.at, last: c.at, msgs: [] };
    g.repos.add(c.repo);
    g.branches.add(`${c.repo}:${c.branch}`);
    g.commits++;
    if (new Date(c.at) < new Date(g.first)) g.first = c.at;
    if (new Date(c.at) > new Date(g.last)) g.last = c.at;
    g.msgs.push(c);
    groups.set(key, g);
  }
  const sessions = [...groups.values()]
    .map((g) => {
      const pr = prs.find((p) => g.branches.has(`${p.repo}:${p.branch}`));
      const oldest = g.msgs[g.msgs.length - 1];
      return {
        id: g.id,
        url: g.url,
        repos: [...g.repos],
        commits: g.commits,
        prs: prs.filter((p) => g.branches.has(`${p.repo}:${p.branch}`)).length,
        first: g.first,
        last: g.last,
        title: pr ? pr.title : oldest.msg,
        latest: g.msgs[0].msg,
      };
    })
    .sort((a, b) => new Date(b.last) - new Date(a.last))
    .slice(0, 60);

  return { login: me?.login || null, repos, commits: all.slice(0, 400), prs: prs.sort((a, b) => new Date(b.at) - new Date(a.at)).slice(0, 150), sessions };
}

async function probe(url, expectJson) {
  const t0 = Date.now();
  try {
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), 15000);
    const res = await fetch(url, { signal: ctrl.signal, redirect: "follow", headers: { "user-agent": "albushra-ameer-collector" } });
    clearTimeout(timer);
    const body = expectJson ? await res.json().catch(() => null) : (await res.arrayBuffer(), null);
    return { ok: res.ok, status: res.status, ms: Date.now() - t0, body };
  } catch (e) {
    return { ok: false, status: 0, ms: Date.now() - t0, body: null };
  }
}

async function collectSites() {
  const reg = JSON.parse(await readFile(join(ROOT, "registry", "apps.json"), "utf8"));
  const apex = reg.company.domain;
  const targets = [{ id: "hub", name: { ar: "الموقع الرئيسي", en: "Main site" }, url: `https://${apex}/`, icon: `https://${apex}/brand/mark-192.png` }];
  for (const a of reg.apps) {
    if (!a.subdomain || a.status === "hidden") continue;
    targets.push({ id: a.id, name: a.name, url: `https://${a.subdomain}.${apex}/`, icon: a.icon ? `https://${apex}/icons/${a.icon}` : null });
  }
  const out = [];
  for (let i = 0; i < targets.length; i += 6) {
    const batch = await Promise.all(targets.slice(i, i + 6).map(async (t) => ({ ...t, ...(await probe(t.url)), body: undefined })));
    out.push(...batch);
  }
  const router = await probe(`https://${apex}/__router/health`, true);
  return { sites: out, cloud: { router: { ok: router.ok && !!router.body?.ok, ms: router.ms, generated: router.body?.generated || null } } };
}

const [github, siteData] = await Promise.all([
  collectGithub().catch((e) => ({ error: String(e.message || e), repos: [], commits: [], prs: [], sessions: [] })),
  collectSites(),
]);
github.rate = rate;
const snapshot = { generatedAt: new Date().toISOString(), github, ...siteData };

console.log(
  `repos=${github.repos.length} commits=${github.commits.length} claude=${github.commits.filter((c) => c.claude).length} ` +
    `prs=${github.prs.length} sessions=${github.sessions.length} sites=${siteData.sites.length} up=${siteData.sites.filter((s) => s.ok).length} ` +
    `rate=${rate}${github.error ? " github-error=yes" : ""}`,
);

if (!TOKEN) {
  await mkdir(join(ROOT, "dist"), { recursive: true });
  await writeFile(join(ROOT, "dist", "ameer-snapshot.json"), JSON.stringify(snapshot, null, 2));
  console.log("AMEER_INGEST_TOKEN not set: wrote dist/ameer-snapshot.json (not uploaded)");
} else {
  const res = await fetch(INGEST, {
    method: "POST",
    headers: { "content-type": "application/json", authorization: `Bearer ${TOKEN}`, "user-agent": "albushra-ameer-collector" },
    body: JSON.stringify({ kind: "snapshot", data: snapshot }),
  });
  console.log(`ingest: HTTP ${res.status}`);
  if (!res.ok) process.exitCode = 1;
}
