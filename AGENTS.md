# AGENTS.md — status-page

## Purpose

A Vue 3 SPA that displays the live health status of the Meddleware platform. It polls
`/api/status` (served by `platform-probe`) every 15 s and renders a capability-grouped view.
The page is display-only — it never evaluates health itself.

## Package layout

```
src/
  main.ts                  App entry — imports design-token CSS, mounts Vue app
  App.vue                  Root layout: AppHeader (dark) + main + AppFooter; polling state machine
  config.ts                VITE_API_BASE env var (empty = same-origin)
  types.ts                 StatusLevel, StatusComponent, StatusGroup, StatusSnapshot types
  composables/
    useStatus.ts           Polls /api/status every 15 s; returns { snapshot, error, loading }
  components/
    StatusDot.vue          Small coloured circle; status prop → CSS var colour
    StatusBanner.vue       Hero row: overall status dot + human label + generated_at timestamp
    StatusGroup.vue        Card listing a capability group's component statuses
```

## Environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `VITE_API_BASE` | `""` | API origin prefix (empty = same-origin `/api/status`). Set at Docker build time. |

## Build and run

```bash
npm install
npm run dev          # Vite dev server at http://localhost:5173 (proxies /api → :8080)
npm run type-check   # vue-tsc type check only (no emit)
npm run build        # type-check + Vite production build → dist/
```

```bash
# Build Docker image:
docker build -t quay.io/meddleware-org/status-page:v0.1.0 .

# With a non-default API base (dev/staging only):
docker build --build-arg VITE_API_BASE=https://probe.example.com \
  -t status-page:dev .
```

## Invariants (see CLAUDE.md)

- Display-only: no health evaluation, no caching of snapshots, no client-side probes.
- `VITE_API_BASE` defaults empty (same-origin in prod via nginx `/api/` → platform-probe route).
- All colours via design-token CSS vars — no hardcoded hex values.
- No secrets, no server-side rendering, no auth.
