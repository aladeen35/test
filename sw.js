/* هاف مليون ½M — Service Worker */
const CACHE = "hm-planner-v3";
const ASSETS = [
  "./",
  "./index.html",
  "./css/app.css",
  "./js/i18n.js",
  "./js/seed.js",
  "./js/core.js",
  "./js/ai.js",
  "./js/ui.js",
  "./manifest.webmanifest",
  "./icon-192.png",
  "./icon-512.png"
];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", e => {
  const url = new URL(e.request.url);
  // لا نتدخل في نداءات الشبكة الخارجية (Claude API / JSONBin / بلاطات الخرائط)
  if (e.request.method !== "GET") return;
  if (url.origin !== location.origin && !url.hostname.includes("cdnjs") && !url.hostname.includes("fonts.g")) return;

  e.respondWith(
    caches.match(e.request).then(cached => {
      const fetched = fetch(e.request).then(resp => {
        if (resp.ok && (url.origin === location.origin)) {
          const copy = resp.clone();
          caches.open(CACHE).then(c => c.put(e.request, copy));
        }
        return resp;
      }).catch(() => cached);
      return cached || fetched;
    })
  );
});
