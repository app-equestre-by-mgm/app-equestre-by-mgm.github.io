// Réseau d'abord : l'app installée charge toujours la dernière version, et le cache ne sert que hors ligne.
const C = 'madp-cache';
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));
self.addEventListener('fetch', e => {
  const r = e.request;
  if (r.method !== 'GET' || new URL(r.url).origin !== location.origin) return;
  e.respondWith(
    fetch(r, { cache: 'no-store' }).then(res => {
      if (res.ok && new URL(r.url).origin === location.origin) {
        const cp = res.clone();
        caches.open(C).then(c => c.put(r, cp));
      }
      return res;
    }).catch(() => caches.match(r).then(m => m || caches.match('./')))
  );
});
