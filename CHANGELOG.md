# Changelog

All notable changes to status-page are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.22] - 2026-10-22

### Changed

- Image base: static-server 0.1.11 (Go 1.26.10 standard library, CVE-2026-111943, so the scan-before-sign gate passes)

## [0.1.21] - 2026-10-20

### Changed

- **Image build: native, no QEMU.** The build stage is `FROM --platform=$BUILDPLATFORM node:…-slim`: the
  output is architecture-independent static files, so the release no longer emulates arm64 and
  `docker-publish.yml` no longer has the `docker/setup-qemu-action` step (a privileged binfmt step). The
  runtime stage still starts from the multi-arch static-server image and only receives `COPY`.
  Proof (rootless podman): the 0.1.20 sources with only this Dockerfile change give a served tree (`/app/public`, the lockfile and `THIRD_PARTY_LICENSES`) with the same
  SHA-256 as the published 0.1.20 image (`sha256:8ec62b1b…`), for every file of the amd64 image,
  and for every file the build stage produces in the arm64 image (the static-server binary comes from the base
  image, which rootless podman 4.9 resolves to the host architecture for the final stage; BuildKit does not).
  No file differs.
- Also ships what merged since 0.1.20: the Node 26 build baseline (`node:26-slim`, `@types/node`), the
  static-server 0.1.9 base image, and the dependency updates in `package-lock.json`.

## [0.1.20] - 2026-10-18

### Added

- Build-time inline-script check (`scripts/check-csp-inline.mjs`, `npm run check:csp`): the image build and CI fail if `dist/` carries an inline `<script>` the CSP does not allow
- Container probe in CI (`scripts/smoke.sh`): the built image runs read-only and non-root, and `/`, the security headers and CSP, the bundle cache header, `/THIRD_PARTY_LICENSES`, the SPA fallback, dot-file and method refusals are checked
- Unit tests for the inline-script check

### Changed

- Depends on design-tokens ^0.1.10; image base moved to static-server 0.1.8
- CI runs the vitest suite in the release gate through `node-ci.yml`

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
