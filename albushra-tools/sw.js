/* ═══════════════════════════════════════════════
   أدوات البشري — Service Worker
   يخزّن التطبيق للعمل دون اتصال (Offline)
   ═══════════════════════════════════════════════ */

const CACHE_NAME = 'albushra-tools-v1';

const APP_SHELL = [
  './',
  './index.html',
  './css/app.css',
  './js/data.js',
  './js/prayer.js',
  './js/tools.js',
  './js/app.js',
  './manifest.webmanifest',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/maskable-512.png',
  './icons/logo.jpg',
];

// واجهات البيانات الحيّة لا تُخزَّن هنا (التطبيق يحفظ آخر نتيجة بنفسه)
const LIVE_APIS = ['open-meteo.com', 'open.er-api.com'];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE_NAME).then((c) => c.addAll(APP_SHELL)).then(() => self.skipWaiting()));
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
  const url = new URL(e.request.url);
  if (LIVE_APIS.some((h) => url.hostname.endsWith(h))) return;

  // الخطوط والمكتبات الخارجية: شبكة أولًا ثم المخزّن
  if (url.origin !== self.location.origin) {
    e.respondWith(
      fetch(e.request)
        .then((res) => { const copy = res.clone(); caches.open(CACHE_NAME).then((c) => c.put(e.request, copy)); return res; })
        .catch(() => caches.match(e.request))
    );
    return;
  }

  // ملفات التطبيق: المخزّن أولًا ثم الشبكة
  e.respondWith(caches.match(e.request, { ignoreSearch: true }).then((cached) => cached || fetch(e.request)));
});

self.addEventListener('notificationclick', (e) => {
  e.notification.close();
  e.waitUntil(self.clients.matchAll({ type: 'window' }).then((list) => (list[0] ? list[0].focus() : self.clients.openWindow('./'))));
});
