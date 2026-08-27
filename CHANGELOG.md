# Changelog

All notable changes to status-page are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
