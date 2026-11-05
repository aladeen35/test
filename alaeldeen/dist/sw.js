/* Offline cache. Built JS/CSS have hashed names, so they are cached as they are
   fetched (network first) instead of from a fixed list. Bump VERSION on release. */
const VERSION = "ab-v6";
const SHELL = ["./", "index.html", "manifest.webmanifest", "assets/logo-mark.png", "assets/headshot.webp", "assets/fullbody.jpg",
  "assets/favicon.png", "assets/icon-192.png", "assets/icon-512.png", "assets/book-stolen-gold.webp", "assets/book-kingdoms.webp"];
self.addEventListener("install", (e) => { e.waitUntil(caches.open(VERSION).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting())); });
self.addEventListener("activate", (e) => { e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== VERSION).map((k) => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener("fetch", (e) => {
  const req = e.request; if (req.method !== "GET") return;
  const url = new URL(req.url);
  const put = (res) => { if (res && res.ok) { const copy = res.clone(); caches.open(VERSION).then((c) => c.put(req, copy)); } return res; };
  if (url.origin === location.origin) {
    e.respondWith(fetch(req).then(put).catch(() => caches.match(req).then((r) => r || caches.match("index.html"))));
  } else if (/fonts\.(googleapis|gstatic)\.com$/.test(url.hostname)) {
    e.respondWith(caches.match(req).then((r) => r || fetch(req).then(put)));
  }
});
