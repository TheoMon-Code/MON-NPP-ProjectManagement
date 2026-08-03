// Minimal service worker -- exists so the dashboard can be "installed" to a
// phone/desktop home screen (Add to Home Screen / Install app). Deliberately
// network-first: this is a live dashboard backed by Supabase, so we never
// want to show stale cached data. The cache is only a fallback for the rare
// case of a genuinely offline load of the app shell.
const CACHE_NAME = 'mon-dashboard-shell-v1';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        const copy = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy)).catch(() => {});
        return response;
      })
      .catch(() => caches.match(event.request))
  );
});
