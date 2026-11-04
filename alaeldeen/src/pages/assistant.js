/* AI assistant — answers only about quality, food safety, nutrition and food microbiology.
   Provider order: SITE.ai.proxyUrl (your Cloudflare Worker in front of the Anthropic API) → Puter
   (free, no key; the visitor signs in to Puter once). Replies stream in and always end with
   the signature. */
import { gsap } from "gsap";

const A = window.APP, I = window.ICONS, S = window.SITE;
const { esc, $, $$, pageHead } = A;
const W = (a, e) => (A.lang === "ar" ? a : e);
const SIGN_AR = "مع تحيات م. علاء الدين عمر";
const SIGN_EN = "With regards, Eng. Alaeldeen Omer";
const reduce = () => window.matchMedia("(prefers-reduced-motion: reduce)").matches;

function systemPrompt() {
  return `You are "Quality Lamp Assistant" (مساعد مصباح الجودة) on the professional website of Eng. Alaeldeen Albushra Omer, a food quality & safety and food microbiology specialist.

SCOPE — answer ONLY questions about: food quality (QA/QC), food safety (HACCP, GMP/GHP, PRPs, ISO 22000, FSSC 22000, audits, NCR/CAPA, cleaning & sanitation, pest control, allergens, traceability/recall, food fraud/defense, labelling), nutrition, and food microbiology (pathogens, indicator organisms, sampling, media, counts, shelf life).
If the question is outside this scope, reply with ONE short polite sentence saying you only answer quality, food safety, nutrition and microbiology questions, then the signature. Do not answer it.

STYLE
- Reply in the same language as the user (Arabic: clear Modern Standard Arabic; keep technical codes in English).
- Short, clear and organised: a one-line direct answer first, then the key points as a short list ("- "), optional "## " headings only for longer answers. Aim for under 180 words unless the user asks for detail.
- Practical examples from factories, central kitchens or cafés when useful.

SAFETY RULES
- Never invent critical limits, sanitiser doses, legal limits or microbiological criteria as universal facts. When a number matters, say it must come from the applicable regulation (e.g. SFDA in Saudi Arabia), the product label, the supplier specification or a validated study; you may cite well-known reference values only with their source (e.g. WHO Five Keys: 5–60 °C danger zone).
- For medical or clinical nutrition questions, give general information and advise consulting a qualified professional.
- Do not claim to be a human or certified auditor.

ENDING — always finish the reply with a blank line and then exactly: "${SIGN_AR}" for Arabic replies, or "${SIGN_EN}" for English replies.`;
}

/* ---------- providers ---------- */
let puterPromise = null;
function loadPuter() {
  if (window.puter) return Promise.resolve(true);
  if (!puterPromise) puterPromise = new Promise((res) => { const s = document.createElement("script"); s.src = "https://js.puter.com/v2/"; s.onload = () => res(!!window.puter); s.onerror = () => res(false); document.head.appendChild(s); });
  return puterPromise;
}
async function stream(messages, onDelta) {
  if (window.__AI_MOCK) return window.__AI_MOCK(messages, onDelta, systemPrompt()); // used by tests
  const cfg = S.ai || {};
  if (cfg.proxyUrl) {
    const resp = await fetch(cfg.proxyUrl, { method: "POST", headers: { "content-type": "application/json", "anthropic-version": "2023-06-01" },
      body: JSON.stringify({ model: cfg.model || "claude-sonnet-5-5", max_tokens: 1200, stream: true, system: systemPrompt(), messages }) });
    if (!resp.ok) throw new Error(resp.status === 429 ? "busy" : "server");
    const reader = resp.body.getReader(), dec = new TextDecoder(); let buf = "", full = "";
    for (;;) { const { value, done } = await reader.read(); if (done) break; buf += dec.decode(value, { stream: true });
      let i; while ((i = buf.indexOf("\n")) >= 0) { const line = buf.slice(0, i).trim(); buf = buf.slice(i + 1);
        if (!line.startsWith("data:")) continue; try { const ev = JSON.parse(line.slice(5)); const tx = ev.delta && ev.delta.text; if (tx) { full += tx; onDelta(full); } } catch (e) { /* keep-alive lines */ } } }
    return full;
  }
  if (!(await loadPuter())) throw new Error("load");
  const msgs = [{ role: "system", content: systemPrompt() }, ...messages];
  let resp;
  try { resp = await window.puter.ai.chat(msgs, { model: cfg.puterModel || "claude-sonnet-4-5", stream: true }); }
  catch (e) { resp = await window.puter.ai.chat(msgs, { stream: true }); }
  let full = "";
  for await (const part of resp) { const tx = part && part.text; if (tx) { full += tx; onDelta(full); } }
  return full;
}
const withSign = (txt) => { const ar = /[؀-ۿ]/.test(txt.slice(0, 200)); const sign = ar ? SIGN_AR : SIGN_EN; const clean = txt.trim(); return clean.includes(SIGN_AR) || clean.includes(SIGN_EN) ? clean : `${clean}\n\n${sign}`; };

/* tiny, safe markdown: escape first, then headings, lists, bold */
function md(txt) {
  const lines = esc(txt).split("\n"); let html = "", list = null;
  const close = () => { if (list) { html += `</${list}>`; list = null; } };
  for (const raw of lines) {
    const l = raw.replace(/\*\*(.+?)\*\*/g, "<b>$1</b>");
    if (/^#{1,3} /.test(l)) { close(); html += `<h4>${l.replace(/^#{1,3} /, "")}</h4>`; }
    else if (/^\s*[-•*] /.test(l)) { if (list !== "ul") { close(); html += "<ul>"; list = "ul"; } html += `<li>${l.replace(/^\s*[-•*] /, "")}</li>`; }
    else if (/^\s*\d+[.)] /.test(l)) { if (list !== "ol") { close(); html += "<ol>"; list = "ol"; } html += `<li>${l.replace(/^\s*\d+[.)] /, "")}</li>`; }
    else if (!l.trim()) close();
    else if (l.includes(SIGN_AR) || l.includes(SIGN_EN)) { close(); html += `<p class="ai-sign">${l}</p>`; }
    else { close(); html += `<p>${l}</p>`; }
  }
  close(); return html;
}

const SUGGEST = () => W(
  ["ما الفرق بين CCP وOPRP؟", "كيف أكتب تقرير عدم مطابقة جيدًا؟", "ما هي منطقة الخطر الحرارية؟", "كيف أحسب CFU من طبقين بتخفيفين؟", "ما مسببات الحساسية الرئيسية؟", "كم بروتين يحتاج الرياضي يوميًا؟"],
  ["What is the difference between a CCP and an OPRP?", "How do I write a good NCR?", "What is the temperature danger zone?", "How do I calculate CFU from two dilutions?", "What are the major food allergens?", "How much protein does an athlete need daily?"]);

A.pages.assistant = () => ({
  title: W("مساعد الجودة الذكي", "Quality AI Assistant"),
  html: `${pageHead(W("مساعد الجودة الذكي", "Quality AI Assistant"), W("اسأل عن الجودة وسلامة الغذاء والتغذية والميكروبيولوجيا، وستصلك إجابة مختصرة وواضحة.", "Ask about quality, food safety, nutrition or microbiology and get a short, clear answer."), [[W("المساعد", "Assistant")]], "ai-head", { eyebrow: "Quality Lamp AI" })}
  <section class="sec"><div class="wrap ai-wrap">
    <div class="card ai-chat">
      <div class="ai-log" id="aiLog" role="log" aria-live="polite">
        <div class="ai-msg bot"><span class="ai-av">${I.lamp}</span><div class="ai-bubble">${md(W(`أهلًا بك! أنا مساعد مصباح الجودة. أجيب فقط عن أسئلة الجودة وسلامة الغذاء والتغذية والميكروبيولوجيا.\n\n${SIGN_AR}`, `Welcome! I'm the Quality Lamp assistant. I answer only questions about quality, food safety, nutrition and microbiology.\n\n${SIGN_EN}`))}</div></div>
      </div>
      <div class="ai-suggest" id="aiSuggest">${SUGGEST().map((q) => `<button type="button" class="chip" data-sq="${esc(q)}">${esc(q)}</button>`).join("")}</div>
      <form class="ai-form" id="aiForm" autocomplete="off"><label for="aiQ" class="sr-only">${esc(W("سؤالك", "Your question"))}</label>
        <textarea id="aiQ" rows="2" maxlength="1500" placeholder="${esc(W("اكتب سؤالك هنا…", "Type your question…"))}"></textarea>
        <button class="btn btn-gold" type="submit" id="aiSend">${I.arrow}<span>${esc(W("إرسال", "Send"))}</span></button></form>
      <div class="row" style="justify-content:space-between;margin-top:8px"><p class="note" style="margin:0" id="aiNote">${esc(W("الإجابات تعليمية ولا تحل محل التشريعات أو التحقق الفني. لا تكتب بيانات شخصية.", "Answers are educational and don't replace regulations or technical verification. Don't enter personal data."))}</p><button type="button" class="btn btn-ghost btn-sm" id="aiClear">${I.trash}<span>${esc(W("محادثة جديدة", "New chat"))}</span></button></div>
    </div>
    <aside class="card ai-side"><h3>${esc(W("ماذا يجيب؟", "What it answers"))}</h3>
      <ul class="ticks"><li>${esc(W("الجودة: QA/QC، التدقيق، NCR وCAPA", "Quality: QA/QC, audits, NCR and CAPA"))}</li><li>${esc(W("سلامة الغذاء: HACCP، GMP/GHP، ISO 22000، الحساسية، التنظيف", "Food safety: HACCP, GMP/GHP, ISO 22000, allergens, cleaning"))}</li><li>${esc(W("التغذية: العناصر الغذائية والنظام الصحي", "Nutrition: nutrients and healthy diets"))}</li><li>${esc(W("الميكروبيولوجيا: الممرضات، العينات، الأوساط، العدّ", "Microbiology: pathogens, sampling, media, counts"))}</li></ul>
      <p class="note">${esc(W("يعمل بالذكاء الاصطناعي عبر Puter مجانًا. عند أول سؤال قد تُطلب منك موافقة أو تسجيل دخول مجاني في نافذة منبثقة.", "Runs on AI through Puter for free. On your first question you may be asked to approve or sign in for free in a pop-up."))}</p>
      <a class="more" href="#/library">${esc(W("تصفح المكتبة العلمية", "Browse the library"))} ${I.arrow}</a></aside>
  </div></section>`,
  after() {
    const KEY = "ai:chat"; let hist = []; try { hist = JSON.parse(sessionStorage.getItem(KEY) || "[]"); } catch (e) { hist = []; }
    const log = $("#aiLog"), form = $("#aiForm"), q = $("#aiQ"), send = $("#aiSend");
    const bubble = (role, html) => { const d = document.createElement("div"); d.className = "ai-msg " + role; d.innerHTML = role === "bot" ? `<span class="ai-av">${I.lamp}</span><div class="ai-bubble">${html}</div>` : `<div class="ai-bubble">${html}</div>`; log.appendChild(d); if (!reduce()) gsap.from(d, { y: 16, autoAlpha: 0, duration: 0.5, ease: "cine" }); log.scrollTop = log.scrollHeight; return d.querySelector(".ai-bubble"); };
    hist.forEach((m) => bubble(m.role === "user" ? "user" : "bot", m.role === "user" ? esc(m.content).replace(/\n/g, "<br>") : md(m.content)));
    const save = () => { try { sessionStorage.setItem(KEY, JSON.stringify(hist.slice(-20))); } catch (e) { /* private mode */ } };
    let busy = false;
    const ask = async (text) => {
      text = text.trim(); if (!text || busy) return;
      busy = true; send.disabled = true; q.value = ""; $("#aiSuggest").hidden = true;
      bubble("user", esc(text).replace(/\n/g, "<br>"));
      hist.push({ role: "user", content: text });
      const out = bubble("bot", `<span class="ai-typing" aria-label="${esc(W("يكتب…", "Typing…"))}"><i></i><i></i><i></i></span>`);
      try {
        const full = await stream(hist.slice(-10), (sofar) => { out.innerHTML = md(sofar); log.scrollTop = log.scrollHeight; });
        if (!full || !full.trim()) throw new Error("empty");
        const final = withSign(full); out.innerHTML = md(final); hist.push({ role: "assistant", content: final }); save();
      } catch (e) {
        hist.pop();
        const m = String((e && e.message) || "");
        out.innerHTML = `<p class="err">${esc(m === "load" ? W("تعذّر تحميل خدمة الذكاء الاصطناعي. تحقق من الاتصال ثم أعد المحاولة.", "Couldn't load the AI service. Check your connection and try again.") : /auth|sign/i.test(m) ? W("أكمل الموافقة أو تسجيل الدخول المجاني في النافذة المنبثقة، ثم أعد الإرسال.", "Finish the free approval or sign-in in the pop-up, then send again.") : m === "busy" ? W("الخدمة مزدحمة الآن. انتظر دقيقة ثم أعد المحاولة.", "The service is busy. Wait a minute and try again.") : W("لم يصل رد. أعد المحاولة بعد قليل.", "No reply arrived. Please try again shortly."))}</p>`;
      }
      busy = false; send.disabled = false; q.focus(); log.scrollTop = log.scrollHeight;
    };
    form.addEventListener("submit", (e) => { e.preventDefault(); ask(q.value); });
    q.addEventListener("keydown", (e) => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); ask(q.value); } });
    $$("[data-sq]").forEach((b) => b.addEventListener("click", () => ask(b.dataset.sq)));
    if (hist.length) $("#aiSuggest").hidden = true;
    $("#aiClear").addEventListener("click", () => { hist = []; save(); A.route(); });
  },
});

(A.searchExtra = A.searchExtra || []).push((add) => add("page", W("مساعد الجودة الذكي", "Quality AI Assistant"), W("اسأل عن الجودة والسلامة والتغذية", "Ask about quality, safety, nutrition"), "#/assistant"));
