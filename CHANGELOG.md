# Changelog

All notable changes to status-page are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.19] - 2026-10-09

### Changed

- Release gate: the release runs the full CI workflow, the image is scanned (fixable CRITICAL/HIGH fail) before it is signed, third-party licence notices are served at /THIRD_PARTY_LICENSES and the lockfile ships in the image for SBOM tools

## [0.1.18] - 2026-10-09

### Changed

- Image base static-server 0.1.7 (Go 1.26.9) and an explicit non-root USER; merged tooling updates; Node CI workflow added (landing)

## [0.1.17] - 2026-10-09

### Changed

- Depends on ui ^0.1.31 and design-tokens ^0.1.9; image base moved to static-server 0.1.6 (OpenRoot, dotfile refusal)

## [0.1.16] - 2026-10-03

### Changed

- `@meddleware/ui` 0.1.30 and `@meddleware/design-tokens` 0.1.8.
- The same-origin API check in the image workflow reads the variable through `env` instead of
  splicing it into the script; CI gates `npm audit` through an expiring allowlist.

## [0.1.15] - 2026-10-02

### Fixed

- Ships the brand favicon (`/favicon.svg`); browsers no longer log a 404 for `/favicon.ico`.

## [0.1.14] - 2026-10-01

### Security

- Dropped the `<meta>` CSP: the response-header policy (with static-server's per-response nonce) is
  the only policy, so Cloudflare's nonce-tagged JavaScript Detections script is no longer blocked.

## [0.1.13] - 2026-10-01

### Security

- Runs on static-server 0.1.3: a per-response CSP `script-src` nonce (lets Cloudflare's injected
  JavaScript Detections script run without `'unsafe-inline'`), HSTS and Permissions-Policy.

## [0.1.12] - 2026-10-01

### Security

- The image now serves a Content-Security-Policy header (static-server `CONTENT_SECURITY_POLICY`),
  scoped to same-origin: `connect-src 'self'`, `base-uri 'none'`, `form-action 'none'`.

### Changed

- `/api/status` fetches time out after 10 s.

## [0.1.0] - 2026-08-27

### Added

- Initial Vue 3 SPA consuming `/api/status` from
  [`platform-probe`](https://github.com/meddleware-org/platform-probe). Polls every 15 s,
  renders capability-grouped status using `@meddleware/design-tokens` and `@meddleware/ui`.
- `StatusBanner` — hero row: overall status dot + human label + snapshot timestamp.
- `StatusDot` — small coloured indicator mapped to `operational`/`degraded`/`down`/`unknown`.
- `StatusGroup` — card listing component statuses within a capability group.
- Loading skeleton state while the first snapshot loads.
- Error notice via `UiNotice` when polling fails.
- `VITE_API_BASE` build arg for pointing at a remote probe (empty = same-origin in prod).
- Multi-arch Docker image (`linux/amd64`, `linux/arm64`) built on
  `quay.io/meddleware-org/static-server`, with SBOM, SLSA provenance, and keyless cosign
  signatures.
- CI workflow: tag-triggered publish to quay.io, Docker Hub, and self-hosted registry.
