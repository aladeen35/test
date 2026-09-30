/* نظام البشرى لإدارة الشركة — Service Worker
   يخزن واجهة التطبيق للعمل دون اتصال؛ ملفات مكتبة المستندات تُخزن عند أول تنزيل فقط */
const CACHE = "bushra-os-v3";
const ASSETS = [
  "./", "./index.html", "./css/app.css", "./manifest.webmanifest",
  "./js/data.js", "./js/store.js", "./js/ops.js", "./js/hr.js", "./js/setup.js", "./js/ui.js", "./js/views.js", "./js/views-ops.js", "./js/views-hr.js",
  "./assets/logo.png", "./assets/icon-192.png", "./assets/icon-512.png", "./assets/stamp.png", "./assets/banner.jpg"
];
self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});
self.addEventListener("activate", e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener("fetch", e => {
  const url = new URL(e.request.url);
  if (e.request.method !== "GET") return;
  if (url.origin !== location.origin && !url.hostname.includes("fonts.g")) return;
  e.respondWith(
    caches.match(e.request).then(cached => {
      const fetched = fetch(e.request).then(resp => {
        if (resp.ok && url.origin === location.origin) { const copy = resp.clone(); caches.open(CACHE).then(c => c.put(e.request, copy)); }
        return resp;
      }).catch(() => cached);
      return cached || fetched;
    })
  );
});
