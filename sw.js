/* Informe François — service worker
   HTML: network-first (siempre lo más nuevo con conexión).
   Resto: cache-first. Sube CACHE al cambiar assets del núcleo. */
const CACHE = "if-v17";
const CORE = ["./", "./index.html", "./manifest.json", "./icon.svg",
              "./icon-192.png", "./icon-512.png", "./apple-touch-icon.png", "./icon-maskable-512.png"];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(CORE)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys()
      .then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET") return;

  /* La sincronía va siempre a la red: si se cacheara, la app leería
     siempre la misma respuesta vieja de Supabase. */
  const url = new URL(req.url);
  const propio = url.origin === self.location.origin;
  const libreria = url.hostname === "cdn.jsdelivr.net";
  if (!propio && !libreria) return;

  const esHTML = req.mode === "navigate" ||
    (req.headers.get("accept") || "").includes("text/html");

  if (esHTML) {
    e.respondWith(
      fetch(req)
        .then(res => {
          const copia = res.clone();
          caches.open(CACHE).then(c => c.put(req, copia)).catch(() => {});
          return res;
        })
        .catch(() => caches.match(req).then(r => r || caches.match("./index.html")))
    );
    return;
  }

  e.respondWith(
    caches.match(req).then(r => r || fetch(req).then(res => {
      const copia = res.clone();
      caches.open(CACHE).then(c => c.put(req, copia)).catch(() => {});
      return res;
    }).catch(() => r))
  );
});
