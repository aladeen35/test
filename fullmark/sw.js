/* فول مارك — Service Worker: عمل كامل بدون إنترنت بعد أول زيارة */
const CACHE = 'fullmark-v6';
const ASSETS = [
  './',
  './index.html',
  './logo.webp',
  './questions.js',
  './config.js',
  './ai.js',
  './mascot.js',
  './party.js',
  './privacy.html',
  './al-bushra-logo.png',
  './net.js',
  './remote.js',
  './peerjs.min.js',
  './sounds/applause.wav',
  './sounds/bonus-loop.wav',
  './sounds/buzz.wav',
  './sounds/correct.wav',
  './sounds/drumroll.wav',
  './sounds/fanfare.wav',
  './sounds/lifeline.wav',
  './sounds/tick.wav',
  './sounds/timeup.wav',
  './sounds/whoosh.wav',
  './sounds/wrong.wav',
  './manifest.webmanifest',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/maskable-512.png',
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => c.addAll(ASSETS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

/* استراتيجية: الكاش أولاً ثم الشبكة، مع تخزين ما يُجلب (يشمل خطوط Google) */
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  e.respondWith(
    caches.match(e.request).then(hit =>
      hit ||
      fetch(e.request).then(res => {
        if (res && (res.ok || res.type === 'opaque')) {
          const copy = res.clone();
          caches.open(CACHE).then(c => c.put(e.request, copy)).catch(() => {});
        }
        return res;
      }).catch(() => caches.match('./index.html'))
    )
  );
});
