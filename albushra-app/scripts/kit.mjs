// "About the developer & ecosystem" and "Privacy policy" pages for every app.
//
// Each page is ONE self-contained HTML file (inline CSS, inline logo, no
// required network), so the same file works:
//   - on albushra.app            /about/, /privacy/, /apps/<id>/about/, /apps/<id>/privacy/
//   - inside every proxied app   <sub>.albushra.app/_albushra/about | /_albushra/privacy (router)
//   - bundled in offline/Android apps (copy kit/<id>/about.html + privacy.html)
//
// Content: company facts from registry/apps.json, per-app privacy facts from
// registry/privacy.json. Arabic first, English with the language button.

import { readFile } from "node:fs/promises";
import { join } from "node:path";

export async function createKit({ ROOT, registry, apps }) {
  const { company } = registry;
  const APEX = company.domain;
  const priv = JSON.parse(await readFile(join(ROOT, "registry", "privacy.json"), "utf8"));
  const logo = "data:image/webp;base64," + (await readFile(join(ROOT, "site", "brand", "mark-160.webp"))).toString("base64");
  const email = company.contact?.email || "";
  const devName = { ar: "م. علاء الدين البشري", en: "Eng. Alaeldeen Albushra" };
  const dedication = { ar: "صدقة جارية عن الوالد أ. البشري محمد الحسن — رحمه الله", en: "An ongoing charity in memory of the late Mr. Albushra Mohamed Elhassan" };
  const summary = {
    ar: "تصميم وبناء وتشغيل تطبيقات ويب وأندرويد عربية أصيلة: من قارئ القرآن الكريم إلى منصات التعليم، وشبكة المتبرعين بالدم، وألعاب التراث والأسرة، وأدوات الجودة وسلامة الغذاء.",
    en: "Designing, building and running authentic Arabic web and Android apps: from a Quran reader to learning platforms, a blood-donor network, heritage and family games, and food-safety tools.",
  };
  const stats = [
    { n: apps.length, l: { ar: "منتجًا رقميًا", en: "products" } },
    { n: apps.filter((a) => (a.platforms || []).includes("Android")).length, l: { ar: "تطبيق أندرويد", en: "Android apps" } },
    { n: apps.filter((a) => a.category === "games" || a.category === "kids").length, l: { ar: "لعبة", en: "games" } },
    { n: apps.filter((a) => a.subdomain && a.route?.mode === "proxy").length, l: { ar: "تطبيق ويب", en: "web apps" } },
  ];

  const esc = (s = "") => String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  const t2 = (o) => (o && typeof o === "object" ? o : { ar: o || "", en: o || "" });
  const bi = (o, tag = "span", cls = "") => {
    const x = t2(o);
    const c = cls ? " " + cls : "";
    return `<${tag} lang="ar" class="ar${c}">${esc(x.ar)}</${tag}><${tag} lang="en" class="en${c}">${esc(x.en)}</${tag}>`;
  };
  const appUrl = (a) => (a.subdomain ? `https://${a.subdomain}.${APEX}/` : a.links?.web || `https://${APEX}/apps/${a.id}/`);
  const I = {
    back: '<path d="M9 6l6 6-6 6"/>',
    code: '<path d="M8 7l-5 5 5 5"/><path d="M16 7l5 5-5 5"/>',
    heart: '<path d="M12 21s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 11c0 5.6-7 10-7 10z" fill="currentColor"/>',
    open: '<path d="M14 4h6v6"/><path d="M20 4l-9 9"/><path d="M19 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h5"/>',
    play: '<path d="M5 3.5l14 8.5-14 8.5z" fill="currentColor"/>',
    share: '<circle cx="18" cy="5" r="2.5"/><circle cx="6" cy="12" r="2.5"/><circle cx="18" cy="19" r="2.5"/><path d="M8.2 10.8l7.6-4.4M8.2 13.2l7.6 4.4"/>',
    copy: '<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V5a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1v10a1 1 0 0 0 1 1h3"/>',
    link: '<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1"/><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>',
    shield: '<path d="M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6z"/><path d="M9 12l2 2 4-4"/>',
    mail: '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3.5 6l8.5 7 8.5-7"/>',
    info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8h.01"/>',
  };
  const ic = (n, s = 20) => `<svg width="${s}" height="${s}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${I[n]}</svg>`;

  const CSS = `
:root{--bg:#0d1828;--bg2:#13233a;--card:rgba(255,255,255,.045);--line:rgba(255,255,255,.1);--text:#eef4ff;--muted:#9fb0c8;--teal:#19c3b1;--teal2:#0e8f8a;--gold:#f6b73c;--rose:#ff6b7d;color-scheme:dark}
*{box-sizing:border-box}html{-webkit-text-size-adjust:100%}
body{margin:0;background:var(--bg);color:var(--text);font:400 16px/1.75 "Tajawal","IBM Plex Sans Arabic","Segoe UI",Tahoma,system-ui,sans-serif;padding-bottom:calc(24px + env(safe-area-inset-bottom))}
html[data-lang=ar] .en,html[data-lang=en] .ar{display:none!important}
a{color:inherit}
.top{position:relative;overflow:hidden;padding:calc(18px + env(safe-area-inset-top)) 18px 26px;background:linear-gradient(135deg,#0f4c5c,#12304a 55%,#0f1d33);border-radius:0 0 26px 26px}
.top::before,.top::after{content:"";position:absolute;border-radius:50%;background:rgba(255,255,255,.06)}
.top::before{width:190px;height:190px;inset-inline-end:-50px;top:-80px}.top::after{width:70px;height:70px;inset-inline-end:30px;top:10px;background:rgba(0,0,0,.18)}
.bar{position:relative;z-index:1;display:flex;align-items:center;gap:14px;max-width:720px;margin:0 auto}
.icon-btn{flex:none;display:grid;place-items:center;width:48px;height:48px;border-radius:14px;border:1px solid rgba(255,255,255,.22);background:rgba(255,255,255,.08);color:#fff;text-decoration:none;cursor:pointer;font:700 14px inherit}
html[dir=rtl] .flip{transform:scaleX(-1)}
.bar h1{margin:0;font-size:22px;line-height:1.3}.bar p{margin:2px 0 0;color:#c9d6e8;font-size:13px}
.bar .grow{flex:1;min-width:0}
main{max-width:720px;margin:0 auto;padding:0 16px}
.card{margin-top:18px;padding:22px 18px;border-radius:22px;background:var(--card);border:1px solid var(--line)}
.hero{text-align:center}
.mark{width:118px;height:118px;border-radius:50%;margin:0 auto 12px;display:grid;place-items:center;background:radial-gradient(circle,#13294a,#0a1426);box-shadow:0 0 0 2px rgba(34,199,242,.35),0 0 40px rgba(34,199,242,.25)}
.mark img{width:100px;height:100px}
.hero h2{margin:0;font-size:24px}.hero .sub{margin:0;color:var(--muted);letter-spacing:.04em}
.chip{display:inline-flex;align-items:center;gap:8px;margin:14px 0 4px;padding:6px 16px;border-radius:999px;border:1px solid rgba(25,195,177,.45);background:rgba(25,195,177,.08);color:#5fe0d2;font-weight:700;font-size:14px}
.ded{display:flex;align-items:center;gap:12px;margin:14px 0;padding:12px 14px;border-radius:14px;background:rgba(255,255,255,.04);border:1px solid var(--line);text-align:start;font-weight:700;font-size:15px}
.ded svg{color:var(--rose);flex:none}
.hero .desc{color:#c7d3e6;margin:6px 0 0}
.sec{margin-top:26px}
.sec h3{margin:0;font-size:19px;padding-inline-start:12px;border-inline-start:4px solid var(--teal);line-height:1.4}
.sec .hint{margin:2px 0 12px;color:var(--muted);font-size:13px;padding-inline-start:16px}
.btn{display:flex;align-items:center;justify-content:center;gap:10px;min-height:58px;padding:10px 16px;border-radius:18px;border:1px solid var(--line);background:var(--card);color:var(--text);font:700 16px inherit;text-decoration:none;cursor:pointer;width:100%}
.btn.primary{background:linear-gradient(90deg,#0f5d6b,#14b8a6);border-color:transparent;color:#fff;box-shadow:0 12px 30px -16px rgba(20,184,166,.9)}
.btn svg{color:var(--teal)}.btn.primary svg{color:#fff}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:10px}
.linkbox{display:flex;align-items:center;gap:12px;margin-top:10px;padding:14px 16px;border-radius:18px;background:var(--card);border:1px solid var(--line)}
.linkbox .grow{flex:1;min-width:0}.linkbox small{display:block;color:var(--muted);font-size:12.5px}
.linkbox b{direction:ltr;unicode-bidi:isolate;display:block;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.linkbox svg{color:var(--teal);flex:none}
.copy{flex:none;width:44px;height:44px;border:0;border-radius:12px;background:rgba(25,195,177,.1);color:var(--teal);display:grid;place-items:center;cursor:pointer}
.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:8px}
.stat{padding:14px 6px;text-align:center;border-radius:16px;background:var(--card);border:1px solid var(--line)}
.stat b{display:block;font-size:26px;line-height:1.2;color:#5fe0d2}.stat span{font-size:12.5px;color:var(--muted)}
.app{display:flex;gap:14px;align-items:center}
.app img{width:60px;height:60px;border-radius:16px;background:#0a1426;object-fit:contain}
.app h4{margin:0;font-size:17px}.app p{margin:0;color:var(--muted);font-size:14px}
.list{margin:8px 0 0;padding:0;list-style:none;display:grid;gap:8px}
.list li{display:flex;gap:10px;align-items:flex-start;padding:10px 12px;border-radius:14px;background:rgba(255,255,255,.03);border:1px solid var(--line)}
.list li svg{color:var(--teal);flex:none;margin-top:4px}
.prose p{margin:0 0 10px;color:#d4deec}
.prose h4{margin:18px 0 6px;font-size:16px;color:#fff}
.note{margin-top:12px;padding:12px 14px;border-radius:14px;border:1px dashed rgba(246,183,60,.45);color:#f3d79b;font-size:14px}
footer{max-width:720px;margin:28px auto 0;padding:0 16px;color:var(--muted);font-size:13px;text-align:center}
footer a{color:#7fe3d8}
.toast{position:fixed;left:50%;bottom:calc(24px + env(safe-area-inset-bottom));transform:translateX(-50%);padding:10px 18px;border-radius:999px;background:#0f5d6b;color:#fff;font-weight:700;opacity:0;transition:opacity .2s;pointer-events:none}
.toast.on{opacity:1}
@media (max-width:420px){.stats{grid-template-columns:repeat(2,1fr)}}
@media (prefers-reduced-motion:reduce){*{transition:none!important}}
:focus-visible{outline:3px solid #5fe0d2;outline-offset:2px}`;

  const JS = `(function(){var d=document.documentElement;try{var l=new URLSearchParams(location.search).get('lang')||localStorage.getItem('ab-lang');if(l==='en'){d.setAttribute('data-lang','en');d.lang='en';d.dir='ltr';}}catch(e){}
function setL(l){d.setAttribute('data-lang',l);d.lang=l;d.dir=l==='en'?'ltr':'rtl';try{localStorage.setItem('ab-lang',l)}catch(e){}}
document.addEventListener('click',function(e){var t=e.target.closest('[data-act]');if(!t)return;var a=t.getAttribute('data-act');
if(a==='lang'){setL(d.getAttribute('data-lang')==='en'?'ar':'en');}
if(a==='back'){e.preventDefault();var h=t.getAttribute('data-home');if(history.length>1&&document.referrer&&new URL(document.referrer).host===location.host)history.back();else location.href=h;}
if(a==='share'){var u=t.getAttribute('data-url');if(navigator.share)navigator.share({title:document.title,url:u}).catch(function(){});else copy(u);}
if(a==='copy'){copy(t.getAttribute('data-url'));}});
function copy(u){(navigator.clipboard?navigator.clipboard.writeText(u):Promise.reject()).then(toast,function(){var i=document.createElement('input');i.value=u;document.body.appendChild(i);i.select();try{document.execCommand('copy')}catch(e){}i.remove();toast();});}
function toast(){var t=document.querySelector('.toast');t.classList.add('on');setTimeout(function(){t.classList.remove('on')},1600);}})();`;

  // Ecosystem-wide page shell. `home` = where "back" goes when there is no history.
  function shell({ title, h1, sub, home, body, canonical }) {
    return `<!doctype html>
<html lang="ar" dir="rtl" data-lang="ar">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#0d1828">
<title>${esc(title)}</title>
${canonical ? `<link rel="canonical" href="${esc(canonical)}">` : ""}
<link rel="icon" href="${logo}">
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700;800&display=swap" rel="stylesheet">
<style>${CSS}</style>
<script>${JS}</script>
</head>
<body>
<header class="top"><div class="bar">
  <a class="icon-btn" href="${esc(home)}" data-act="back" data-home="${esc(home)}" aria-label="رجوع / Back"><span class="flip">${ic("back", 22)}</span></a>
  <div class="grow"><h1>${bi(h1)}</h1><p>${bi(sub)}</p></div>
  <button class="icon-btn" type="button" data-act="lang" aria-label="Language / اللغة">${bi({ ar: "EN", en: "ع" })}</button>
</div></header>
<main>
${body}
</main>
<footer>© ${new Date().getFullYear()} ${bi(company.name)} · <a href="https://${APEX}/">${APEX}</a></footer>
<div class="toast" role="status">${bi({ ar: "تم نسخ الرابط", en: "Link copied" })}</div>
</body>
</html>
`;
  }

  // ---------- About the developer & ecosystem ----------
  // mode: "hub" (albushra.app pages), "router" (<sub>.albushra.app/_albushra/*),
  // "file" (copied next to each other inside an offline app).
  const link = (app, page, mode) =>
    !app ? `https://${APEX}/${page}/` : mode === "router" ? `/_albushra/${page}` : mode === "file" ? `${page}.html` : `https://${APEX}/apps/${app.id}/${page}/`;

  function about(app = null, mode = "hub") {
    const home = app ? appUrl(app) : `https://${APEX}/`;
    const L = app?.links || {};
    const play = L.play || L.testing || "https://play.google.com/store/apps/details?id=sa.mushaf.albushra";
    const privacyHref = link(app, "privacy", mode);
    const body = `
<section class="card hero">
  <div class="mark"><img src="${logo}" width="100" height="100" alt=""></div>
  <h2>${bi(company.name)}</h2>
  <p class="sub">Albushra Technology</p>
  <div class="chip">${ic("code", 18)}${bi({ ar: `تطوير وإشراف: ${devName.ar}`, en: `Developed and supervised by ${devName.en}` })}</div>
  <div class="ded">${ic("heart", 22)}${bi(dedication)}</div>
  <p class="desc">${bi(summary)}</p>
</section>

${
  app
    ? `<section class="sec">
  <h3>${bi({ ar: "عن هذا التطبيق", en: "About this app" })}</h3>
  <p class="hint">${bi({ ar: "جزء من منظومة البشري للتكنولوجيا", en: "Part of the Albushra Technology ecosystem" })}</p>
  <div class="card app" style="margin-top:0">
    <img src="https://${APEX}/icons/${esc(app.icon || "albushra-news.webp")}" width="60" height="60" alt="" onerror="this.src='${logo}'">
    <div><h4>${bi(app.name)}</h4><p>${bi(app.tagline)}</p>${app.resolvedVersion?.value ? `<p dir="ltr" style="text-align:start">v${esc(app.resolvedVersion.value)}</p>` : ""}</div>
  </div>
</section>`
    : ""
}

<section class="sec">
  <h3>${bi({ ar: "تنزيل التطبيقات والموقع الرسمي", en: "Apps and the official website" })}</h3>
  <p class="hint">${bi({ ar: "روابط الوصول المباشر والتحميل السريع", en: "Direct access and quick downloads" })}</p>
  <a class="btn primary" href="https://${APEX}/">${ic("open")}${bi({ ar: "زيارة موقع وتطبيقات البشرى (Albushra.app)", en: "Visit Albushra apps (Albushra.app)" })}</a>
  <div class="grid2">
    <a class="btn" href="${esc(play)}" rel="noopener">${ic("play")}Google Play</a>
    <button class="btn" type="button" data-act="share" data-url="https://${APEX}/">${ic("share")}${bi({ ar: "مشاركة الرابط", en: "Share link" })}</button>
  </div>
  <div class="linkbox">${ic("link", 22)}<div class="grow"><small>${bi({ ar: "رابط الموقع والتحميل المباشر", en: "Website and direct downloads" })}</small><b>https://${APEX}</b></div><button class="copy" type="button" data-act="copy" data-url="https://${APEX}/" aria-label="نسخ / Copy">${ic("copy")}</button></div>
</section>

<section class="sec">
  <h3>${bi({ ar: "مؤشرات منظومة البشري", en: "The Albushra ecosystem in numbers" })}</h3>
  <p class="hint">${bi({ ar: "منتجات منشورة تحت نطاق واحد", en: "Products published under one domain" })}</p>
  <div class="stats">${stats.map((s) => `<div class="stat"><b>${s.n}</b>${bi(s.l)}</div>`).join("")}</div>
</section>

<section class="sec">
  <h3>${bi({ ar: "الخصوصية والتواصل", en: "Privacy and contact" })}</h3>
  <p class="hint">${bi({ ar: "بياناتك لك، ونجيب على أسئلتك", en: "Your data is yours, and we answer your questions" })}</p>
  <a class="btn" href="${esc(privacyHref)}">${ic("shield")}${bi({ ar: "سياسة الخصوصية", en: "Privacy policy" })}</a>
  ${email ? `<a class="btn" style="margin-top:10px" href="mailto:${esc(email)}">${ic("mail")}<span dir="ltr">${esc(email)}</span></a>` : ""}
</section>`;
    return shell({
      title: app ? `عن المطور والمنظومة — ${t2(app.name).ar}` : `عن المطور والمنظومة — ${company.name.ar}`,
      h1: { ar: "عن المطور والمنظومة", en: "About the developer" },
      sub: { ar: `${company.name.ar} — Albushra.app`, en: "Albushra Technology — Albushra.app" },
      home,
      body,
      canonical: app ? `https://${APEX}/apps/${app.id}/about/` : `https://${APEX}/about/`,
    });
  }

  // ---------- Privacy policy ----------
  const updated = priv.updated;
  function privacy(app = null, mode = "hub") {
    const p = app ? priv.apps[app.id] || null : null;
    const home = app ? appUrl(app) : `https://${APEX}/`;
    const aboutHref = link(app, "about", mode);
    const li = (arr) => `<ul class="list">${arr.map((x) => `<li>${ic("shield", 16)}<span>${esc(x)}</span></li>`).join("")}</ul>`;
    const bil = (o, fn) => `<div lang="ar" class="ar">${fn(o?.ar || [])}</div><div lang="en" class="en">${fn(o?.en || [])}</div>`;
    let inner;
    if (p?.existing) {
      inner = `<section class="card prose">
  <p>${bi({ ar: "لهذا التطبيق سياسة خصوصية تفصيلية خاصة به. اضغط لفتحها:", en: "This app has its own detailed privacy policy. Open it here:" })}</p>
  <a class="btn primary" href="${esc(p.existing)}">${ic("shield")}${bi({ ar: "سياسة الخصوصية التفصيلية", en: "Detailed privacy policy" })}</a>
</section>`;
    } else if (app && p) {
      inner = `<section class="card app">
  <img src="https://${APEX}/icons/${esc(app.icon || "albushra-news.webp")}" width="60" height="60" alt="" onerror="this.src='${logo}'">
  <div><h4>${bi(app.name)}</h4><p>${bi({ ar: `آخر تحديث: ${updated}`, en: `Last updated: ${updated}` })}</p></div>
</section>
<section class="sec prose">
  <h3>${bi({ ar: "البيانات التي يتعامل معها التطبيق", en: "What data the app handles" })}</h3>
  ${bil(p.data, li)}
  <h4>${bi({ ar: "أين تُحفظ", en: "Where it is kept" })}</h4>
  <p>${bi(p.where)}</p>
  <h4>${bi({ ar: "خدمات أطراف ثالثة", en: "Third-party services" })}</h4>
  ${(p.third?.ar || []).length ? bil(p.third, li) : `<p>${bi({ ar: "لا يستخدم التطبيق خدمات خارجية تتلقى بياناتك.", en: "The app uses no outside service that receives your data." })}</p>`}
  ${p.account ? `<h4>${bi({ ar: "حسابك وحذفه", en: "Your account and deleting it" })}</h4><p>${bi({ ar: "يمكنك طلب نسخة من بياناتك أو حذف حسابك وكل بياناته في أي وقت بمراسلتنا، وننفّذ الطلب خلال ٣٠ يومًا.", en: "You can ask for a copy of your data or for your account and all its data to be deleted at any time by writing to us; we act within 30 days." })}</p>` : ""}
  ${p.kids ? `<h4>${bi({ ar: "الأطفال", en: "Children" })}</h4><p>${bi({ ar: "يراعي التطبيق خصوصية الأطفال: لا إعلانات موجّهة لهم، ولا نجمع منهم أكثر مما يلزم لعمل التطبيق، ولا نبيع لهم شيئًا.", en: "The app respects children's privacy: no ads targeted at them, nothing collected beyond what the app needs, and nothing sold to them." })}</p>` : ""}
  <h4>${bi({ ar: "ما لا نفعله", en: "What we never do" })}</h4>
  <p>${bi({ ar: "لا نبيع بياناتك، ولا نشاركها للإعلانات، ولا نستخدمها لغير تشغيل التطبيق.", en: "We never sell your data, share it for advertising, or use it for anything but running the app." })}</p>
</section>`;
    }
    const general = `<section class="sec prose">
  <h3>${bi({ ar: app ? "مبادئ عامة في كل تطبيقات البشري" : "مبادئ الخصوصية في منظومة البشري", en: app ? "Principles across all Albushra apps" : "Privacy across the Albushra ecosystem" })}</h3>
  <p>${bi({ ar: "الخصوصية افتراضيًا: لا حسابات إلا عند الحاجة، ولا بيانات تُجمع دون سبب، وأغلب تطبيقاتنا تحفظ بياناتها على جهازك فقط.", en: "Private by default: accounts only when needed, no data collected without a reason, and most of our apps keep their data on your device only." })}</p>
  <p>${bi({ ar: `تُقدَّم المواقع عبر Cloudflare تحت نطاق ${APEX}، وتُستضاف على GitHub Pages أو Vercel أو Cloudflare. هذه الخدمات تسجّل بيانات تقنية مؤقتة (مثل عنوان IP ونوع المتصفح) لأغراض الأمان والتشغيل فقط.`, en: `Sites are served through Cloudflare under ${APEX} and hosted on GitHub Pages, Vercel or Cloudflare. These services keep short-lived technical logs (such as IP address and browser type) for security and operation only.` })}</p>
  <p>${bi({ ar: "تفضيلات اللغة والمظهر تُحفظ في متصفحك فقط.", en: "Language and theme preferences stay in your browser." })}</p>
  ${!app ? `<p>${bi({ ar: "لكل تطبيق صفحة خصوصية تبيّن ما يتعامل معه بالتحديد:", en: "Each app has a privacy page that states exactly what it handles:" })}</p>
  <ul class="list">${apps.map((a) => `<li>${ic("shield", 16)}<a href="https://${APEX}/apps/${a.id}/privacy/">${bi(a.name)}</a></li>`).join("")}</ul>` : ""}
  <h4>${bi({ ar: "التواصل", en: "Contact" })}</h4>
  <p>${bi({ ar: "الجهة المسؤولة: البشري للتكنولوجيا.", en: "Responsible party: Albushra Technology." })} ${email ? `<a href="mailto:${esc(email)}" dir="ltr">${esc(email)}</a>` : ""}</p>
  <p>${bi({ ar: "قد نحدّث هذه الصفحة عند تغيّر التطبيق، ويظهر تاريخ آخر تحديث أعلاها.", en: "We may update this page when the app changes; the last-updated date is shown at the top." })}</p>
</section>
<section class="sec"><a class="btn" href="${esc(aboutHref)}">${ic("info")}${bi({ ar: "عن المطور والمنظومة", en: "About the developer" })}</a></section>`;
    return shell({
      title: app ? `سياسة الخصوصية — ${t2(app.name).ar}` : `سياسة الخصوصية — ${company.name.ar}`,
      h1: { ar: "سياسة الخصوصية", en: "Privacy policy" },
      sub: app ? { ar: t2(app.name).ar, en: t2(app.name).en } : { ar: `${company.name.ar} — Albushra.app`, en: "Albushra Technology — Albushra.app" },
      home,
      body: (inner || "") + general,
      canonical: app ? `https://${APEX}/apps/${app.id}/privacy/` : `https://${APEX}/privacy/`,
    });
  }

  const missing = apps.filter((a) => !priv.apps[a.id]).map((a) => a.id);
  return { about, privacy, missing };
}
