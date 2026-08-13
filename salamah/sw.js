/* ═══════════════════════════════════════════════
   سلامة — Service Worker
   يخزّن هيكل التطبيق للعمل دون اتصال داخل المطبخ
   ═══════════════════════════════════════════════ */

const CACHE_NAME = 'salamah-v1';

const APP_SHELL = [
  './',
  './index.html',
  './css/style.css',
  './js/data.js',
  './js/app.js',
  './manifest.webmanifest',
  './icons/icon-192.png',
  './icons/icon-512.png',
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME).then((c) => c.addAll(APP_SHELL)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET') return;

  // الخطوط ومصادر الشبكة: شبكة أولًا ثم تخزين للرجوع إليه دون اتصال
  if (new URL(e.request.url).origin !== self.location.origin) {
    e.respondWith(
      fetch(e.request)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE_NAME).then((c) => c.put(e.request, copy));
          return res;
        })
        .catch(() => caches.match(e.request))
    );
    return;
  }

  // ملفات التطبيق: التخزين أولًا ثم الشبكة
  e.respondWith(caches.match(e.request).then((cached) => cached || fetch(e.request)));
});
