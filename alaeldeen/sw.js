/* Offline cache for the site shell. Bump VERSION when files change. */
const VERSION = "ab-v3";
const SHELL = ["./", "index.html", "css/site.css", "css/books.css", "assets/book-stolen-gold.webp", "assets/book-kingdoms.webp", "js/i18n.js", "js/content.js", "js/app.js", "js/tools.js", "js/motion.js", "manifest.webmanifest",
  "assets/logo-mark.png", "assets/headshot.webp", "assets/fullbody.jpg", "assets/favicon.png", "assets/icon-192.png", "assets/icon-512.png"];
self.addEventListener("install", (e) => { e.waitUntil(caches.open(VERSION).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting())); });
self.addEventListener("activate", (e) => { e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== VERSION).map((k) => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener("fetch", (e) => {
  const req = e.request; if (req.method !== "GET") return;
  const url = new URL(req.url);
  if (url.origin === location.origin) {
    // network first for same-origin so updates show; fall back to cache offline
    e.respondWith(fetch(req).then((res) => { const copy = res.clone(); caches.open(VERSION).then((c) => c.put(req, copy)); return res; }).catch(() => caches.match(req).then((r) => r || caches.match("index.html"))));
  } else if (/fonts\.(googleapis|gstatic)\.com$/.test(url.hostname)) {
    e.respondWith(caches.match(req).then((r) => r || fetch(req).then((res) => { const copy = res.clone(); caches.open(VERSION).then((c) => c.put(req, copy)); return res; })));
  }
});
