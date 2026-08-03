/* ExaPDF 서비스워커 — 오프라인으로 열리게 한다.
 *
 * Flutter 가 제 서비스워커를 **폐기했다.** 지금 나오는
 * `flutter_service_worker.js` 는 설치되자마자 스스로를 등록 해제하는
 * 정리용 파일이라, 그대로 두면 오프라인에서 앱이 아예 안 열린다.
 * 매일 여는 책 앱에서 지하철에 들어갔다고 안 열리면 곤란하다.
 *
 * 방침
 *  - 앱 껍데기(HTML·엔진·에셋)는 **캐시 먼저**. 두 번째부터는 순식간에 뜬다
 *  - `/api/` 는 **망 먼저**. 계정·요금제·OCR 결과는 늘 최신이어야 한다
 *  - 캐시 이름에 판올림 번호를 넣어, 새 판이 뜨면 옛 캐시를 통째로 버린다
 */
'use strict';

const VERSION = 'exapdf-v1';
const SHELL = 'shell-' + VERSION;
const RUNTIME = 'runtime-' + VERSION;

/** 없으면 앱이 뜨지 않는 것들. 나머지는 쓰면서 채운다 */
const CORE = [
  './',
  './index.html',
  './main.dart.js',
  './flutter.js',
  './flutter_bootstrap.js',
  './manifest.json',
  './favicon.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(SHELL);
      // 하나가 없다고 설치 전체가 실패하면 안 된다 —
      // Flutter 산출물은 판올림마다 파일 이름이 바뀐다
      await Promise.allSettled(CORE.map((u) => cache.add(new Request(u, { cache: 'reload' }))));
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const names = await caches.keys();
      await Promise.all(
        names
          .filter((n) => n.endsWith('-exapdf') === false && !n.endsWith(VERSION))
          .map((n) => caches.delete(n)),
      );
      // 지금 열려 있는 화면부터 바로 맡는다. 안 그러면 다음에 열 때까지 논다
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  // 계정·요금제·OCR 결과는 낡으면 안 된다. 망을 먼저 본다
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(fetch(req).catch(() => caches.match(req)));
    return;
  }

  event.respondWith(
    (async () => {
      const hit = await caches.match(req, { ignoreSearch: true });
      if (hit) {
        // 뒤에서 조용히 새로 받아 둔다. 다음에 열 때 최신이 된다
        event.waitUntil(refresh(req));
        return hit;
      }
      try {
        const res = await fetch(req);
        if (res.ok) {
          const cache = await caches.open(RUNTIME);
          cache.put(req, res.clone());
        }
        return res;
      } catch (e) {
        // 화면 이동인데 망이 없으면 앱 껍데기를 돌려준다
        if (req.mode === 'navigate') {
          const shell = await caches.match('./index.html');
          if (shell) return shell;
        }
        throw e;
      }
    })(),
  );
});

async function refresh(req) {
  try {
    const res = await fetch(req);
    if (!res.ok) return;
    const cache = await caches.open(RUNTIME);
    await cache.put(req, res);
  } catch (e) {
    // 망이 없으면 그냥 둔다. 캐시로 이미 답했다
  }
}
