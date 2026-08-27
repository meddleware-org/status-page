# CLAUDE.md — status-page

## Identity

A display-only Vue 3 SPA. All health truth lives in
[`platform-probe`](https://github.com/meddleware-org/platform-probe) — this page just renders
the snapshot it receives.

## Architectural invariants

1. **No health evaluation in the frontend.** Never derive, infer, or override status values.
   Render exactly what `/api/status` returns. The snapshot fields are `operational`, `degraded`,
   `down`, and `unknown` — map them to colour/label, nothing more.

2. **No caching of `/api/status` in the frontend.** The page polls on a timer via
   `useStatus`; there is no service worker, no localStorage persistence, and no stale-while-
   revalidate. The snapshot is always live from the prober.

3. **`VITE_API_BASE` defaults to empty string (same-origin).** In production, nginx routes
   `/api/` to platform-probe on the same hostname — no CORS, no cross-origin complexity. Only
   set `VITE_API_BASE` at build time when the probe is genuinely on a different origin (e.g.
   a dev or staging environment without a local proxy).

4. **All styling via design-token CSS vars.** No hardcoded colour values. Use semantic tokens
   (`--bg`, `--surface`, `--text`, `--muted`, etc.) for theme-aware styles and `--mw-ok-500`,
   `--mw-gold-500`, `--mw-danger-500` for status colours. Never import raw hex values.

5. **No backend, no API routes, no secrets.** This is a static SPA. The only network call it
   makes is `GET /api/status`. It has no server-side rendering, no auth, and no secrets.

## Adding a component

1. Create `src/components/MyComponent.vue` using design-token vars for all colours/spacing.
2. Props must use the types defined in `src/types.ts` — do not widen the `StatusLevel` union
   or add fields not present in the `/api/status` JSON.
3. Export nothing from the component beyond the Vue default — this is a private application,
   not a library.

## What not to do

- Do not add client-side health checks, fetch calls to internal services, or ping-style probes.
- Do not persist the snapshot (localStorage, IndexedDB, service worker cache).
- Do not expose `VITE_API_BASE` or any runtime config in the rendered HTML.
- Do not add npm dependencies beyond the existing stack without a clear reason.
