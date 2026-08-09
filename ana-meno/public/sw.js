/* Service worker for "أنا مِنو 🤔"
 * Strategy:
 *  - App shell + static assets: cache-first with background refresh.
 *  - Supabase / API traffic: network-only (multiplayer is online-only).
 *  - Navigations: network-first, falling back to the cached shell offline.
 */
const CACHE = 'ana-meno-v1';
const SHELL = [
  '/',
  '/index.html',
  '/manifest.webmanifest',
  '/icons/icon.svg',
  '/icons/icon-192.png',
  '/icons/icon-512.png',
  '/fonts/cairo-arabic.woff2',
  '/fonts/cairo-latin.woff2',
  '/assets/characters/mystery.svg',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(SHELL)).then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Never intercept cross-origin (Supabase realtime/REST) or non-GET traffic.
  if (url.origin !== self.location.origin || event.request.method !== 'GET') return;

  // SPA navigations: network first, offline fallback to cached shell.
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE).then((cache) => cache.put('/index.html', copy));
          return res;
        })
        .catch(() => caches.match('/index.html')),
    );
    return;
  }

  // Static assets: cache first, then network (and cache the result).
  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) return cached;
      return fetch(event.request).then((res) => {
        if (res.ok && (url.pathname.startsWith('/assets/') || url.pathname.startsWith('/fonts/')
          || url.pathname.startsWith('/icons/'))) {
          const copy = res.clone();
          caches.open(CACHE).then((cache) => cache.put(event.request, copy));
        }
        return res;
      });
    }),
  );
});
