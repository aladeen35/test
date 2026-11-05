/* Shared, online features (Supabase):
   - public like counts (RPC toggle_like / like_counts, one anonymous device id per browser)
   - #/news       quality, food safety and nutrition news, refreshed every 6 hours by an edge function
   - #/community  member posts (reviewed before publishing), comments, reports, moderation for the admin
   Likes and news use plain REST calls; supabase-js (auth) loads only when the community needs it. */
const A = window.APP, I = window.ICONS;
const { esc, $, $$, pageHead } = A;
const W = (a, e) => (A.lang === "ar" ? a : e);
const URL_ = "https://qiogbmeqxgivvbgfgwaz.supabase.co";
const KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFpb2dibWVxeGdpdnZiZ2Znd2F6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM4NTcyNDUsImV4cCI6MjEwOTQzMzI0NX0.KFhqTyWo4myectRRcVTS0NmvEZA51a9ZNY5Rccq3ivM";
const SITE = "https://aladeen35.github.io/test/alaeldeen/";
const H = { apikey: KEY, Authorization: "Bearer " + KEY, "Content-Type": "application/json" };
const rest = (path, opt = {}) => fetch(URL_ + path, { ...opt, headers: { ...H, ...(opt.headers || {}) } }).then((r) => (r.ok ? r.json() : Promise.reject(new Error(r.status))));
const fmt = (d) => { try { return new Date(d).toLocaleDateString(A.lang === "ar" ? "ar-SA-u-ca-gregory-nu-latn" : "en-GB", { day: "numeric", month: "short", year: "numeric" }); } catch { return ""; } };
const paras = (s) => esc(s).split(/\n{2,}/).map((p) => `<p>${p.replace(/\n/g, "<br>")}</p>`).join("");
const strip = (s) => String(s || "").replace(/<[^>]*>/g, " ").replace(/&nbsp;|&#160;/g, " ").replace(/&amp;/g, "&").replace(/\s+/g, " ").trim();

/* ---------- public like counts ---------- */
const device = (() => {
  try { let d = localStorage.getItem("ab:device"); if (!d) { d = crypto.randomUUID(); localStorage.setItem("ab:device", d); } return d; } catch { return null; }
})();
const counts = new Map(); // key -> { n, at }
let want = new Map(), timer = null;
function flush() {
  const batch = want; want = new Map(); timer = null;
  rest("/rest/v1/rpc/like_counts", { method: "POST", body: JSON.stringify({ p_keys: [...batch.keys()] }) })
    .then((rows) => { const got = new Map(rows.map((r) => [r.item_key, Number(r.n)])); batch.forEach((cbs, k) => { const n = got.get(k) || 0; counts.set(k, { n, at: Date.now() }); cbs.forEach((c) => c.res(n)); }); })
    .catch((e) => batch.forEach((cbs) => cbs.forEach((c) => c.rej(e))));
}
const VALID = /^[a-z]+:[A-Za-z0-9_.-]{1,110}$/;
if (window.LIKES && device) {
  window.LIKES.backend = {
    count(k) {
      if (!VALID.test(k)) return Promise.resolve(0);
      const c = counts.get(k); if (c && Date.now() - c.at < 60000) return Promise.resolve(c.n);
      return new Promise((res, rej) => { if (!want.has(k)) want.set(k, []); want.get(k).push({ res, rej }); if (!timer) timer = setTimeout(flush, 40); });
    },
    toggle(k, on) {
      if (!VALID.test(k)) return Promise.resolve(0);
      return rest("/rest/v1/rpc/toggle_like", { method: "POST", body: JSON.stringify({ p_key: k, p_device: device, p_on: on }) }).then((n) => { n = Number(n) || 0; counts.set(k, { n, at: Date.now() }); return n; });
    },
  };
  A.paintLikes && A.paintLikes();
}

/* ---------- auth client (lazy) ---------- */
let sbP = null;
function sb() {
  if (!sbP) sbP = import("@supabase/supabase-js").then(({ createClient }) => createClient(URL_, KEY, { auth: { flowType: "pkce", persistSession: true, autoRefreshToken: true, detectSessionInUrl: true, storageKey: "ab-auth" } }));
  return sbP;
}
// finish a magic-link sign-in (?code=...) and clean the address bar
if (/[?&]code=/.test(location.search)) {
  sb().then((c) => c.auth.getSession()).finally(() => {
    history.replaceState(null, "", location.pathname + (location.hash || "#/community"));
    if ((location.hash || "").startsWith("#/community")) A.route();
  });
}
let me = null; // { id, email, name, role }
async function whoami() {
  const c = await sb(); const { data } = await c.auth.getSession(); const u = data.session && data.session.user;
  if (!u) return (me = null);
  if (me && me.id === u.id) return me;
  const { data: p } = await c.from("profiles").select("display_name, role").eq("id", u.id).maybeSingle();
  return (me = { id: u.id, email: u.email, name: (p && p.display_name) || "", role: (p && p.role) || "member" });
}

const CATS = { quality: ["الجودة", "Quality"], safety: ["سلامة الغذاء", "Food safety"], nutrition: ["التغذية", "Nutrition"], microbiology: ["الميكروبيولوجيا", "Microbiology"], experience: ["تجربة ميدانية", "Field experience"] };
const NCATS = { safety: ["سلامة الغذاء", "Food safety"], recall: ["سحب واستدعاء", "Recalls"], nutrition: ["التغذية", "Nutrition"], regulation: ["تشريعات", "Regulation"], science: ["علوم وأبحاث", "Science"] };
const cat = (m, k) => (m[k] ? W(m[k][0], m[k][1]) : k);
const msg = (el, text, bad) => { if (el) { el.textContent = text; el.className = "note " + (bad ? "cm-bad" : "cm-ok"); } };

/* ---------- news ---------- */
let newsCache = null;
A.pages.news = () => ({
  title: W("أخبار الجودة والغذاء", "Quality & food news"),
  html: `${pageHead(W("أخبار الجودة وسلامة الغذاء", "Quality & food safety news"), W("أخبار عالمية وعربية عن سلامة الغذاء والسحب والتغذية والتشريعات، تُجمع تلقائيًا من مصادرها كل 6 ساعات.", "Global and Arabic news on food safety, recalls, nutrition and regulation, collected automatically from the sources every 6 hours."), [[W("الأخبار", "News")]], "", { eyebrow: W("تحديث تلقائي", "Auto-updated"), after: `<div class="cta" style="justify-content:flex-start"><a class="btn btn-ghost" href="#/community">${esc(W("مجتمع مصباح الجودة", "Quality Lamp community"))}</a></div>` })}
  <section class="sec"><div class="wrap">
    <div class="nw-bar"><div class="seg" role="group" aria-label="language" id="nwLang"><button data-v="" aria-pressed="true">${esc(W("الكل", "All"))}</button><button data-v="ar">العربية</button><button data-v="en">English</button></div>
      <input type="search" id="nwQ" placeholder="${esc(W("ابحث في الأخبار…", "Search news…"))}" aria-label="${esc(W("بحث", "Search"))}"></div>
    <div class="filters" role="group" aria-label="categories" id="nwCat"><button class="chip" data-v="" aria-pressed="true">${esc(W("كل الأقسام", "All topics"))}</button>${Object.keys(NCATS).map((k) => `<button class="chip" data-v="${k}" aria-pressed="false">${esc(cat(NCATS, k))}</button>`).join("")}</div>
    <ol class="nw-list" id="nwList"><li class="empty">${esc(W("جارٍ تحميل الأخبار…", "Loading news…"))}</li></ol>
    <p class="note">${esc(W("الأخبار تُعرض بعناوينها وملخصاتها من مصادرها الأصلية، والرابط يفتح المصدر. لا نتحمل مسؤولية محتوى المواقع الخارجية.", "Headlines and summaries are shown as published by the original sources; links open the source. External sites are responsible for their own content."))}</p>
  </div></section>`,
  after() {
    const f = { lang: "", cat: "", q: "" };
    const draw = () => {
      const q = f.q.toLowerCase();
      const rows = (newsCache || []).filter((n) => (!f.lang || n.lang === f.lang) && (!f.cat || n.category === f.cat) && (!q || (n.title + " " + (n.summary || "") + " " + n.source).toLowerCase().includes(q))).slice(0, 120);
      $("#nwList").innerHTML = rows.length ? rows.map((n) => { const s = strip(n.summary); return `<li class="nw-item" dir="${n.lang === "ar" ? "rtl" : "ltr"}" lang="${n.lang}">
        <div class="nw-meta"><span class="chip">${esc(cat(NCATS, n.category))}</span><span>${esc(n.source)}</span><time datetime="${esc(n.published_at || "")}">${esc(fmt(n.published_at || n.created_at))}</time></div>
        <h3><a href="${esc(n.link)}" target="_blank" rel="noopener nofollow">${esc(strip(n.title))} ${I.external || ""}</a></h3>${s && s !== strip(n.title) ? `<p>${esc(s.slice(0, 260))}${s.length > 260 ? "…" : ""}</p>` : ""}</li>`; }).join("") : `<li class="empty">${esc(newsCache ? W("لا توجد أخبار مطابقة.", "No matching news.") : W("تعذّر تحميل الأخبار الآن. حاول لاحقًا.", "Couldn't load the news right now. Try again later."))}</li>`;
    };
    const pick = (box, key) => box.addEventListener("click", (e) => { const b = e.target.closest("button"); if (!b) return; f[key] = b.dataset.v; $$("button", box).forEach((x) => x.setAttribute("aria-pressed", x === b)); draw(); });
    pick($("#nwLang"), "lang"); pick($("#nwCat"), "cat");
    $("#nwQ").addEventListener("input", (e) => { f.q = e.target.value.trim(); draw(); });
    if (newsCache) return draw();
    rest("/rest/v1/news_items?select=link,title,summary,source,lang,category,published_at,created_at&order=published_at.desc.nullslast&limit=400")
      .then((r) => { newsCache = r; }).catch(() => { newsCache = null; }).finally(() => { if ($("#nwList")) draw(); });
  },
});

/* ---------- community ---------- */
const head = (sub, crumbs) => pageHead(W("مجتمع مصباح الجودة", "Quality Lamp community"), sub || W("مقالات وتجارب من المختصين في الجودة وسلامة الغذاء والتغذية. تُراجَع كل مشاركة قبل نشرها.", "Articles and field experience from quality, food safety and nutrition practitioners. Every post is reviewed before it goes live."), crumbs || [[W("المجتمع", "Community")]], "", { eyebrow: W("مدونة المجتمع", "Community blog"), after: `<div class="cta" style="justify-content:flex-start"><a class="btn btn-gold" href="#/community/new">${esc(W("اكتب مقالًا", "Write a post"))}</a><a class="btn btn-ghost" href="#/news">${esc(W("أخبار الجودة والغذاء", "Quality & food news"))}</a></div>` });
const shell = (sub, crumbs, body) => `${head(sub, crumbs)}<section class="sec"><div class="wrap" id="cmRoot">${body || `<div class="empty">${esc(W("جارٍ التحميل…", "Loading…"))}</div>`}</div></section>`;
const bar = (u, on) => `<div class="cm-bar"><nav class="tabs" aria-label="community">${[["", W("المنشورات", "Posts")], ["new", W("اكتب مقالًا", "Write a post")], ["mine", W("مشاركاتي", "My posts")], ...(u && u.role === "admin" ? [["admin", W("المراجعة", "Review")]] : [])].map(([k, l]) => `<a href="#/community${k ? "/" + k : ""}" role="tab" aria-selected="${on === k}">${esc(l)}</a>`).join("")}</nav>
  <div class="cm-user">${u ? `<span>${I.user || ""}${esc(u.name)}</span><button class="btn btn-ghost sm" id="cmOut">${esc(W("خروج", "Sign out"))}</button>` : `<a class="btn btn-ghost sm" href="#/community/signin">${esc(W("دخول / تسجيل", "Sign in / join"))}</a>`}</div></div>`;
function wireOut() { const b = $("#cmOut"); b && b.addEventListener("click", async () => { const c = await sb(); await c.auth.signOut(); me = null; A.route(); }); }

function signinForm(next) {
  return `<div class="card cm-sign"><h2>${esc(W("ادخل بالبريد الإلكتروني", "Sign in with your email"))}</h2>
    <p class="note">${esc(W("بدون كلمة مرور: نرسل لك رابط دخول. الاسم الذي تكتبه يظهر مع مشاركاتك، وبريدك لا يُعرض لأحد.", "No password: we email you a sign-in link. The name you enter appears with your posts; your email is never shown."))}</p>
    <form class="form" id="cmSignF"><div class="field"><label for="cmName">${esc(W("الاسم الظاهر", "Display name"))}</label><input id="cmName" type="text" required minlength="2" maxlength="60" autocomplete="name"></div>
    <div class="field"><label for="cmMail">${esc(W("البريد الإلكتروني", "Email"))}</label><input id="cmMail" type="email" required autocomplete="email" dir="ltr"></div>
    <div class="field full"><label class="cm-chk"><input type="checkbox" required id="cmAgree"> <span>${esc(W("أوافق على ", "I agree to the "))}<a href="#/privacy">${esc(W("سياسة الخصوصية", "privacy policy"))}</a>${esc(W(" وقواعد المجتمع: محتوى مهني، بلا إساءة أو إعلانات أو بيانات شخصية لغيرك.", " and the community rules: professional content, no abuse, ads or other people's personal data."))}</span></label></div>
    <div class="full row"><button class="btn btn-gold">${esc(W("أرسل رابط الدخول", "Email me a link"))}</button><span class="note" id="cmSignMsg" role="status"></span></div></form></div>`;
}
function wireSignin(next) {
  const f = $("#cmSignF"); if (!f) return;
  f.addEventListener("submit", async (e) => {
    e.preventDefault(); const m = $("#cmSignMsg"); const btn = $("button", f); btn.disabled = true; msg(m, W("جارٍ الإرسال…", "Sending…"));
    try {
      const c = await sb();
      const { error } = await c.auth.signInWithOtp({ email: $("#cmMail").value.trim(), options: { emailRedirectTo: SITE + "#/community/" + (next || ""), data: { name: $("#cmName").value.trim() } } });
      if (error) throw error;
      msg(m, W("أرسلنا رابط الدخول إلى بريدك. افتحه من نفس المتصفح (تحقق من البريد غير المرغوب).", "Check your inbox for the sign-in link and open it in this same browser (check spam too)."));
    } catch (err) { msg(m, /rate|429|seconds/i.test(String(err && (err.message || err.status))) ? W("طلبات كثيرة. انتظر دقيقة ثم حاول مرة أخرى.", "Too many requests. Wait a minute and try again.") : W("تعذّر الإرسال: ", "Couldn't send: ") + (err.message || err), true); btn.disabled = false; }
  });
}

const postCard = (p) => `<article class="cm-post"><div class="nw-meta"><span class="chip">${esc(cat(CATS, p.category))}</span><span>${esc((p.profiles && p.profiles.display_name) || W("عضو", "Member"))}</span><time>${esc(fmt(p.published_at || p.created_at))}</time></div>
  <h3><a href="#/community/p/${p.id}">${esc(p.title)}</a></h3><p>${esc(p.body.slice(0, 220))}${p.body.length > 220 ? "…" : ""}</p></article>`;

async function listView(root, u) {
  const c = await sb();
  const { data, error } = await c.from("posts").select("id,title,body,category,lang,published_at,created_at,profiles(display_name)").eq("status", "published").order("published_at", { ascending: false }).limit(60);
  root.innerHTML = bar(u, "") + `<div class="filters" role="group" id="cmCats"><button class="chip" data-v="" aria-pressed="true">${esc(W("كل الأقسام", "All topics"))}</button>${Object.keys(CATS).map((k) => `<button class="chip" data-v="${k}" aria-pressed="false">${esc(cat(CATS, k))}</button>`).join("")}</div><div class="cm-list" id="cmList"></div>`;
  const draw = (k) => { const rows = (data || []).filter((p) => !k || p.category === k); $("#cmList").innerHTML = rows.length ? rows.map(postCard).join("") : `<div class="empty">${esc(error ? W("تعذّر التحميل الآن.", "Couldn't load right now.") : W("لا توجد منشورات بعد. كن أول من يكتب!", "No posts yet. Be the first to write!"))}<div class="cta" style="justify-content:center"><a class="btn btn-gold" href="#/community/new">${esc(W("اكتب مقالًا", "Write a post"))}</a></div></div>`; };
  $("#cmCats").addEventListener("click", (e) => { const b = e.target.closest("button"); if (!b) return; $$("#cmCats button").forEach((x) => x.setAttribute("aria-pressed", x === b)); draw(b.dataset.v); });
  draw("");
}

async function postView(root, u, id) {
  const c = await sb();
  const { data: p } = await c.from("posts").select("id,title,body,category,lang,status,review_note,author_id,published_at,created_at,profiles(display_name)").eq("id", id).maybeSingle();
  if (!p) { root.innerHTML = bar(u, "") + `<div class="empty">${esc(W("المنشور غير موجود أو لم يُنشر بعد.", "This post doesn't exist or isn't published yet."))}</div>`; return; }
  const { data: cm } = await c.from("comments").select("id,body,status,author_id,created_at,profiles(display_name)").eq("post_id", id).order("created_at");
  const admin = u && u.role === "admin";
  root.innerHTML = bar(u, "") + `<article class="article cm-article" dir="${p.lang === "ar" ? "rtl" : "ltr"}" lang="${p.lang}">
    ${p.status !== "published" ? `<p class="chip ${p.status === "rejected" ? "bad" : ""}">${esc(p.status === "pending" ? W("بانتظار المراجعة", "Awaiting review") : W("مرفوض", "Rejected"))}${p.review_note ? " — " + esc(p.review_note) : ""}</p>` : ""}
    <div class="nw-meta"><span class="chip">${esc(cat(CATS, p.category))}</span><span>${esc((p.profiles && p.profiles.display_name) || "")}</span><time>${esc(fmt(p.published_at || p.created_at))}</time></div>
    <h2 class="cm-title">${esc(p.title)}</h2>${paras(p.body)}
    <div class="row cm-acts">${p.status === "published" ? A.likeBtn("post:" + p.id) + A.shareBtn({ k: W("مجتمع مصباح الجودة", "Quality Lamp community"), t: p.title, b: p.body.slice(0, 260), h: "#/community/p/" + p.id }) : ""}
      ${u && u.id !== p.author_id && p.status === "published" ? `<button class="btn btn-ghost sm" data-report="post:${p.id}">${esc(W("إبلاغ", "Report"))}</button>` : ""}
      ${u && (u.id === p.author_id || admin) ? `<button class="btn btn-ghost sm" id="cmDel">${esc(W("حذف", "Delete"))}</button>` : ""}</div></article>
  <section class="cm-comments"><h3>${esc(W("التعليقات", "Comments"))} <span class="chip">${(cm || []).filter((x) => x.status === "published").length}</span></h3>
    <ol>${(cm || []).map((x) => `<li class="${x.status === "hidden" ? "cm-hidden" : ""}"><div class="nw-meta"><b>${esc((x.profiles && x.profiles.display_name) || "")}</b><time>${esc(fmt(x.created_at))}</time>${x.status === "hidden" ? `<span class="chip bad">${esc(W("مخفي", "Hidden"))}</span>` : ""}</div>${paras(x.body)}
      <div class="row">${u && u.id !== x.author_id && x.status === "published" ? `<button class="lnk" data-report="comment:${x.id}">${esc(W("إبلاغ", "Report"))}</button>` : ""}${admin ? `<button class="lnk" data-hide="${x.id}" data-to="${x.status === "hidden" ? "published" : "hidden"}">${esc(x.status === "hidden" ? W("إظهار", "Show") : W("إخفاء", "Hide"))}</button>` : ""}${u && (u.id === x.author_id || admin) ? `<button class="lnk" data-cdel="${x.id}">${esc(W("حذف", "Delete"))}</button>` : ""}</div></li>`).join("")}</ol>
    ${p.status !== "published" ? "" : u ? `<form id="cmCF" class="cm-cf"><label for="cmC" class="lbl">${esc(W("أضف تعليقًا", "Add a comment"))}</label><textarea id="cmC" rows="3" minlength="2" maxlength="2000" required></textarea><div class="row"><button class="btn btn-gold sm">${esc(W("نشر التعليق", "Post comment"))}</button><span class="note" id="cmCM" role="status"></span></div></form>` : `<p class="note"><a href="#/community/signin">${esc(W("سجّل الدخول للتعليق", "Sign in to comment"))}</a></p>`}</section>`;
  const reload = () => postView(root, u, id);
  const f = $("#cmCF"); f && f.addEventListener("submit", async (e) => { e.preventDefault(); const { error } = await c.from("comments").insert({ post_id: p.id, body: $("#cmC").value.trim() }); if (error) msg($("#cmCM"), /limit|rate/i.test(error.message) ? W("وصلت للحد اليومي للتعليقات.", "Daily comment limit reached.") : error.message, true); else reload(); });
  root.addEventListener("click", async function h(e) {
    const t = e.target.closest("[data-report],[data-hide],[data-cdel],#cmDel"); if (!t) return;
    if (t.dataset.report) { const [type, tid] = t.dataset.report.split(":"); const reason = prompt(W("سبب الإبلاغ (اختياري):", "Reason (optional):")); if (reason === null) return; const { error } = await c.from("reports").insert({ target_type: type, target_id: Number(tid), reason: reason.slice(0, 500) || null }); A.toast ? A.toast(error ? error.message : W("شكرًا، وصل البلاغ للمراجعة.", "Thanks, the report was sent for review.")) : null; return; }
    root.removeEventListener("click", h);
    if (t.dataset.hide) await c.from("comments").update({ status: t.dataset.to }).eq("id", t.dataset.hide);
    if (t.dataset.cdel && confirm(W("حذف التعليق؟", "Delete this comment?"))) await c.from("comments").delete().eq("id", t.dataset.cdel);
    if (t.id === "cmDel") { if (confirm(W("حذف المنشور نهائيًا؟", "Delete this post permanently?"))) { await c.from("posts").delete().eq("id", p.id); location.hash = "#/community"; return; } }
    reload();
  });
}

function writeView(root, u, edit) {
  root.innerHTML = bar(u, "new") + `<form class="form card cm-write" id="cmWF">
    <div class="field full"><label for="cmT">${esc(W("العنوان", "Title"))}</label><input id="cmT" type="text" required minlength="5" maxlength="140" value="${esc((edit && edit.title) || "")}"></div>
    <div class="field"><label for="cmK">${esc(W("القسم", "Topic"))}</label><select id="cmK">${Object.keys(CATS).map((k) => `<option value="${k}" ${edit && edit.category === k ? "selected" : ""}>${esc(cat(CATS, k))}</option>`).join("")}</select></div>
    <div class="field"><label for="cmL">${esc(W("لغة المقال", "Language"))}</label><select id="cmL"><option value="ar">العربية</option><option value="en" ${(edit ? edit.lang : A.lang) === "en" ? "selected" : ""}>English</option></select></div>
    <div class="field full"><label for="cmB">${esc(W("نص المقال", "Post"))}</label><textarea id="cmB" rows="14" required minlength="20" maxlength="8000">${esc((edit && edit.body) || "")}</textarea><span class="hint" id="cmBn"></span></div>
    <p class="note full">${esc(W("اترك سطرًا فارغًا بين الفقرات. يُراجَع المقال قبل النشر، ولا تذكر أسماء منشآت أو أشخاص أو بيانات سرية.", "Leave a blank line between paragraphs. Posts are reviewed before publishing; don't name facilities or people or share confidential data."))}</p>
    <div class="full row"><button class="btn btn-gold">${esc(edit ? W("حفظ التعديل", "Save changes") : W("أرسل للمراجعة", "Send for review"))}</button><span class="note" id="cmWM" role="status"></span></div></form>`;
  const cnt = () => ($("#cmBn").textContent = $("#cmB").value.length + " / 8000"); $("#cmB").addEventListener("input", cnt); cnt();
  $("#cmWF").addEventListener("submit", async (e) => {
    e.preventDefault(); const c = await sb(); const row = { title: $("#cmT").value.trim(), category: $("#cmK").value, lang: $("#cmL").value, body: $("#cmB").value.trim() };
    const { error } = edit ? await c.from("posts").update(row).eq("id", edit.id) : await c.from("posts").insert(row);
    if (error) return msg($("#cmWM"), /limit|rate/i.test(error.message) ? W("وصلت للحد اليومي للمشاركات (5).", "Daily post limit reached (5).") : error.message, true);
    location.hash = "#/community/mine";
  });
}

async function mineView(root, u) {
  const c = await sb();
  const { data } = await c.from("posts").select("id,title,status,review_note,created_at,category,lang,body").eq("author_id", u.id).order("created_at", { ascending: false });
  const st = { pending: W("بانتظار المراجعة", "Awaiting review"), published: W("منشور", "Published"), rejected: W("مرفوض", "Rejected") };
  root.innerHTML = bar(u, "mine") + `<form class="row card cm-name" id="cmNF"><label for="cmN" class="lbl">${esc(W("اسمك الظاهر", "Your display name"))}</label><input id="cmN" type="text" minlength="2" maxlength="60" required value="${esc(u.name)}"><button class="btn btn-ghost sm">${esc(W("حفظ", "Save"))}</button><span class="note" id="cmNM" role="status"></span></form>
    <div class="cm-list">${(data || []).length ? data.map((p) => `<article class="cm-post"><div class="nw-meta"><span class="chip ${p.status === "published" ? "ok" : p.status === "rejected" ? "bad" : ""}">${esc(st[p.status])}</span><time>${esc(fmt(p.created_at))}</time></div><h3><a href="#/community/p/${p.id}">${esc(p.title)}</a></h3>${p.review_note ? `<p class="note">${esc(W("ملاحظة المراجع: ", "Reviewer note: "))}${esc(p.review_note)}</p>` : ""}${p.status === "pending" ? `<a class="lnk" href="#/community/edit/${p.id}">${esc(W("تعديل", "Edit"))}</a>` : ""}</article>`).join("") : `<div class="empty">${esc(W("لم تكتب أي مقال بعد.", "You haven't written anything yet."))}</div>`}</div>`;
  $("#cmNF").addEventListener("submit", async (e) => { e.preventDefault(); const n = $("#cmN").value.trim(); const { error } = await c.from("profiles").update({ display_name: n }).eq("id", u.id); if (!error) me.name = n; msg($("#cmNM"), error ? error.message : W("تم الحفظ", "Saved"), !!error); });
}

async function adminView(root, u) {
  const c = await sb();
  const [{ data: posts }, { data: reps }] = await Promise.all([
    c.from("posts").select("id,title,body,category,lang,created_at,profiles(display_name)").eq("status", "pending").order("created_at"),
    c.from("reports").select("id,target_type,target_id,reason,created_at").order("created_at", { ascending: false }).limit(100),
  ]);
  root.innerHTML = bar(u, "admin") + `<h2 class="cm-h">${esc(W("بانتظار المراجعة", "Awaiting review"))} <span class="chip">${(posts || []).length}</span></h2>
    <div class="cm-list">${(posts || []).map((p) => `<article class="cm-post cm-review" data-id="${p.id}" dir="${p.lang === "ar" ? "rtl" : "ltr"}"><div class="nw-meta"><span class="chip">${esc(cat(CATS, p.category))}</span><span>${esc((p.profiles && p.profiles.display_name) || "")}</span><time>${esc(fmt(p.created_at))}</time></div><h3>${esc(p.title)}</h3><details><summary>${esc(W("اقرأ النص", "Read the post"))}</summary>${paras(p.body)}</details>
      <div class="row"><input class="cm-note" type="text" maxlength="500" placeholder="${esc(W("ملاحظة للكاتب (اختياري)", "Note to the author (optional)"))}"><button class="btn btn-teal sm" data-act="published">${esc(W("نشر", "Publish"))}</button><button class="btn btn-ghost sm" data-act="rejected">${esc(W("رفض", "Reject"))}</button></div></article>`).join("") || `<div class="empty">${esc(W("لا شيء بانتظار المراجعة.", "Nothing waiting for review."))}</div>`}</div>
    <h2 class="cm-h">${esc(W("البلاغات", "Reports"))} <span class="chip">${(reps || []).length}</span></h2>
    <ol class="cm-reps">${(reps || []).map((r) => `<li><span class="chip">${esc(r.target_type === "post" ? W("منشور", "Post") : W("تعليق", "Comment"))} #${r.target_id}</span> ${esc(r.reason || "—")} <time>${esc(fmt(r.created_at))}</time> ${r.target_type === "post" ? `<a class="lnk" href="#/community/p/${r.target_id}">${esc(W("افتح", "Open"))}</a>` : `<button class="lnk" data-hidec="${r.target_id}">${esc(W("إخفاء التعليق", "Hide comment"))}</button>`} <button class="lnk" data-clr="${r.id}">${esc(W("إغلاق البلاغ", "Dismiss"))}</button></li>`).join("") || `<li class="note">${esc(W("لا توجد بلاغات.", "No reports."))}</li>`}</ol>`;
  root.addEventListener("click", async function h(e) {
    const b = e.target.closest("[data-act],[data-clr],[data-hidec]"); if (!b) return; root.removeEventListener("click", h);
    if (b.dataset.act) { const card = b.closest("[data-id]"); const note = $(".cm-note", card).value.trim() || null; await c.from("posts").update({ status: b.dataset.act, review_note: note }).eq("id", card.dataset.id); }
    if (b.dataset.clr) await c.from("reports").delete().eq("id", b.dataset.clr);
    if (b.dataset.hidec) await c.from("comments").update({ status: "hidden" }).eq("id", b.dataset.hidec);
    adminView(root, u);
  });
}

A.pages.community = (sub) => {
  const [view, id] = (sub || "").split("/");
  return {
    title: W("مجتمع مصباح الجودة", "Quality Lamp community"),
    html: shell(),
    async after() {
      const root = $("#cmRoot");
      let u;
      try { u = await whoami(); } catch { root.innerHTML = `<div class="empty">${esc(W("تعذّر الاتصال بالخدمة الآن. حاول لاحقًا.", "Couldn't reach the service right now. Try again later."))}</div>`; return; }
      if (!document.body.contains(root)) return;
      const needs = ["new", "mine", "admin", "edit"].includes(view);
      if ((view === "signin" || needs) && !u) { root.innerHTML = bar(u, view === "signin" ? "" : view) + signinForm(view === "signin" ? "" : view); wireSignin(view === "signin" ? "" : view); return; }
      if (view === "signin") { location.hash = "#/community"; return; }
      try {
        if (view === "p" && id) await postView(root, u, Number(id));
        else if (view === "new") writeView(root, u);
        else if (view === "edit" && id) { const c = await sb(); const { data } = await c.from("posts").select("*").eq("id", Number(id)).eq("author_id", u.id).eq("status", "pending").maybeSingle(); data ? writeView(root, u, data) : (location.hash = "#/community/mine"); }
        else if (view === "mine") await mineView(root, u);
        else if (view === "admin") u.role === "admin" ? await adminView(root, u) : (location.hash = "#/community");
        else await listView(root, u);
      } catch { root.innerHTML = bar(u, "") + `<div class="empty">${esc(W("حدث خطأ أثناء التحميل.", "Something went wrong while loading."))}</div>`; }
      wireOut();
      A.paintLikes && A.paintLikes(root);
      window.MOTION && window.MOTION.apply && window.MOTION.apply(root);
    },
  };
};
