# Security Audit — `status-page`

**Classification:** Internal security review
**Project:** `repos/status-page` — Vue 3 SPA showing platform health from `platform-probe`'s `/api/status` (`status.meddleware.co.uk`)
**Project type:** Vue app (display only)
**Template:** AUDIT_TEMPLATE.md (2026-10-08) + AUDIT_TEMPLATE_TS.md (2026-10-08) + AUDIT_TEMPLATE_VUE.md (2026-10-08) + AUDIT_TEMPLATE_IMG.md (2026-10-08). Not triggered: `AUDIT_TEMPLATE_SUI_CLIENT.md` (no chain code; the chain index it reports on is read by `platform-probe`, not by this page), `AUDIT_TEMPLATE_AUTH.md` / `AUDIT_TEMPLATE_PROXY.md` (the page holds no credential and forwards nothing; the ingress path rule is platform configuration), `AUDIT_TEMPLATE_PLATFORM.md` (the SOPS-encrypted checks Secret that feeds the status snapshot is mounted by `platform-probe`, not by this image; it is recorded in B.2 for completeness and belongs to the platform audit).
**Package manager / lockfile:** npm 11, committed (361 locked packages; 26 production)   **Module format:** ESM (`type: module`)   **Publish model:** image only (`private: true`)
**Runtime targets:** browser   **Peer dependencies:** none
**Build tool:** vite 8.3.3, @vitejs/plugin-vue 6.0.9, vue 3.5.43, vitest 5.0.3 (jsdom 30)   **Hosting:** container image (static-server 0.1.7) behind Cloudflare; no static host   **Embedding hosts:** none
**VITE_\* inventory:** `VITE_API_BASE` only — base URL of the probe API, baked at build, default empty (same-origin), must be empty for the public image (F4); no per-network IDs; not a secret
**Images:** `quay.io/meddleware-org/status-page:0.1.19@sha256:9dd64c5f7437f0947d7b3b74afd4b06669f7b890956c13c06d08c022d1eb2475` (Docker Hub `meddleware/status-page`; best-effort self-hosted registry mirror, see F18)
**Base images:** build `node:24-slim@sha256:0e0ff40c…f9b6`; runtime `quay.io/meddleware-org/static-server:0.1.7@sha256:2e227311…2379` (Go 1.26.9)
**Runtime user:** 65534:65534 (`USER`, `runAsNonRoot`)   **Runtime FS:** read-only root, nothing writable mounted
**Deployed by:** `k8s/base/apps/status` via the overlay `k8s/clusters/meddleware-org/apps` (digest from `config/images.yaml`)
**Build args:** `VITE_API_BASE` (public, empty) and `CSP` (the response-header policy) — none secret
**Deployment status:** image `quay.io/meddleware-org/status-page` (+ Docker Hub; best-effort signed push to the self-hosted registry, currently without credentials) serving `status.meddleware.co.uk` at 0.1.19 (deployed 2026-10-09; live headers and `/api/status` checked 2026-10-09; the snapshot lists Identity & Access, Container Registry and Chain Access → Chain index, all operational)
**Review date:** 2026-09-19 (first pass) · re-verified 2026-10-03 · re-verified 2026-10-09
**Reviewer:** Internal review
**Severity ceiling:** Low — no backend, accounts, secrets or writes; the worst case is misleading status text from a compromised probe.
**Status:** re-verified 2026-10-09 — 21 findings (8 Positive): 7 RESOLVED, 1 MITIGATED, 1 ADJUDICATED, 2 ACCEPTED-RISK, 2 DEFERRED

---

## Executive summary

A display-only page: it polls `/api/status` on its own origin every 15 seconds and renders the
snapshot that `platform-probe` computes. It evaluates nothing, stores nothing, and renders every field
as text after `@meddleware/ui`'s `parseSnapshot` has coerced each status to a known level and
sanitised each name. The image serves `connect-src 'self'` and `script-src 'self'`.

All first-pass findings are resolved or positive. The 2026-10-03 pass found:

- **F12 (Info, RESOLVED 0.1.16)** — the same-origin check in the image workflow spliced the
  `VITE_API_BASE` repository variable into its shell script; it now reads it from `env`.

The first-pass open questions are closed: `npm ci` everywhere (F2), a render-escaping test exists
(C.1), and the CSP is a response header from static-server, not a `<meta>` tag (F11).

The 2026-10-09 re-verification (0.1.19, deployed) re-checked every finding against the code, the
live headers and the live snapshot, and applied the container-image lens:

- **F13 (Low, RESOLVED 0.1.19, `988719c`)** — the release runs the full CI workflow, Trivy scans the
  published image before cosign signs it, the lockfile ships in the image and
  `/THIRD_PARTY_LICENSES` is served.
- **F14 (Info, RESOLVED 0.1.18, `c3ae276`)** — static-server 0.1.7 (Go 1.26.9) base and an explicit
  `USER 65534:65534`.
- **F15 (Low, ACCEPTED-RISK)** — the vitest suite (the render-escaping test) is not run by
  `node-ci.yml`, so neither CI nor the release executes it; it passes locally (2/2).
- **F16–F17 (Info)** — no container probe in CI (ACCEPTED-RISK); the snapshot size is not bounded
  before parsing (ADJUDICATED).
- **F18 (Low, DEFERRED)** — registry pushes use long-lived tokens (`OPERATOR_TASKS.md` "Image
  registry credentials").
- **F20 (Info, DEFERRED)** — the best-effort self-hosted mirror job signs its image but does not
  scan it or attach an SBOM attestation, and fails without credentials (maintainer item).
- **F21 (Low, MITIGATED)** — no build-time check that the bundle emits no inline script; the build
  emits none today and `script-src` has no `'unsafe-inline'`, so a future one would fail closed.
- **F19 (Positive)** — the new Chain Access → Chain index check needs no page change; the check
  definitions stay in the SOPS-encrypted `status-checks` Secret that `platform-probe` mounts.

No High or Critical; the severity ceiling is unchanged.

## Threat model / trust boundaries

| Actor | Holds / proves | Can do | Bounded by |
| --- | --- | --- | --- |
| Visitor | nothing | read | display only |
| Dependency author (direct and transitive) | code that runs at build and in the bundle | lockfile, `npm ci`, audit gate, Trivy, 26 production packages with licence texts (B.TS-2, F3) |
| `platform-probe` | the snapshot | send any names and statuses | `parseSnapshot` (known levels, sanitised names); text rendering (I2) |
| Build configuration | `VITE_API_BASE` (repository variable) | point the poll at another origin | empty by default; the publish job fails on any value (F4, F12); CSP `connect-src 'self'` |
| Network | — | tamper in transit | HTTPS with HSTS (zone and static-server) |
| Static host / CDN (Cloudflare, static-server) | headers, served bytes | CSP and HSTS on every path (B.VUE-1, live-checked 2026-10-09); digest-pinned image; cosign signature |
| Base-image publisher, registry, CI publish job | the layers, the manifest for a tag, what is signed | digest-pinned bases and deployment; Trivy then keyless cosign, SBOM and provenance attestations (F13) |
| Holder of the checks Secret (SOPS age key on the node) | which internal endpoints the probe checks, and so which names appear in the snapshot | not this project: mounted by `platform-probe`; the page shows names only, never URLs (F19) |

## Severity scale

Critical / High / Medium / Low / Info / Positive.

## Scope

- **In scope (0.1.19):** `src/**` (`config.ts`, `composables/useStatus.ts`, `StatusBanner`,
  `StatusGroup`, `StatusDot`, `App.vue`, `main.ts`), `index.html`, `Dockerfile`, `.dockerignore`,
  workflows, `scripts/third-party-licenses.mjs`, `SECURITY.md`, and the deployment in
  `k8s/base/apps/status` plus the overlay (read-only).
- **Out of scope:** `platform-probe` and `@meddleware/ui` (own audits; `parseSnapshot` is ui's), the
  contents of the `status-checks` Secret.
- **Environment (2026-10-09, re-run 2026-10-10):** `npm test` 2/2 (vitest 5.0.3; run locally only, F15); `vue-tsc`; stylelint, eslint,
  html-validate; production build; Trivy filesystem scan (vuln, misconfig, secret) in CI; audit gate
  (1 allowlisted dev-tooling advisory, 0 open; `npm audit --omit=dev` 0 vulnerabilities);
  `npm run check:licenses` (26 production packages, all with a licence file). Live: `curl -I` of
  `status.meddleware.co.uk/`, `/api/status` and `/THIRD_PARTY_LICENSES`; repository variables,
  secrets (names) and recent runs read with `gh`.

## Findings

### F1 — Snapshot fields reached the template unvalidated

**Severity:** Low   **Disposition:** RESOLVED — `parseSnapshot` (ui `status.ts`) walks every group
and component, coercing `status` to a known level and sanitising `name`; malformed input lands on the
error path.
**Remediation / evidence:** re-verified 2026-10-09 against ui 0.1.31 (`status.ts` `parseSnapshot`:
rejects a non-object, an unknown `overall`, a non-string `generated_at` and a non-array `groups`;
groups and components that do not parse are dropped); `useStatus` shows the error panel when it
returns `null`. The parser is tested in ui (`status.test.ts`).

### F2 — `npm install` in the image and CI

**Severity:** Low   **Disposition:** RESOLVED — `npm ci` everywhere.
**Remediation / evidence:** the Dockerfile and every `node-ci.yml` job run `npm ci` (re-read
2026-10-09); the release reaches them through the `verify` job (F13).

### F3 — No `npm audit` in CI

**Severity:** Low   **Disposition:** RESOLVED — the audit gate (TS lens B.TS-3, expiring allowlist)
runs in CI and before publishing, alongside Trivy.
**Remediation / evidence:** `node-ci.yml` runs `node .github/audit-gate.mjs` after `npm ci`, and the
release calls `node-ci.yml` (F13). `.github/audit-allowlist.json` holds one entry
(GHSA-vfj7-8cjw-p6xm, `braces`, dev tooling only, expires 2027-01-01); `npm audit --omit=dev` reports
0 vulnerabilities (2026-10-10).

### F4 — Cross-origin API base could be baked in

**Severity:** Low   **Disposition:** RESOLVED — the public publish job fails when `VITE_API_BASE` is
set; the CSP's `connect-src 'self'` would block a cross-origin poll in any case.
**Remediation / evidence:** the "Assert same-origin API base" step is in `docker-publish.yml` and runs
before the build (F12); the repository variable `VITE_API_BASE` is unset (`gh variable list`
2026-10-10: only `QUAY_NAMESPACE` and `DOCKERHUB_NAMESPACE`); the live CSP carries `connect-src 'self'`.

### F5 — No HTML sinks

**Severity:** Positive — no `v-html`, `innerHTML` or `eval`; labels come from fixed maps.

### F6 — No persistence

**Severity:** Positive — the snapshot lives only in memory.

### F7 — No health evaluation in the browser

**Severity:** Positive — the page renders the probe's verdict verbatim.

### F8 — Same-origin default

**Severity:** Positive — `API_BASE` defaults to `''`; it is the only `VITE_*` value.

### F9 — Signed, attested images

**Severity:** Positive — multi-arch, SBOM, SLSA provenance, keyless cosign; digest-pinned bases.

### F10 — Best-effort private-registry push

**Severity:** Positive — `continue-on-error` so the self-hosted registry cannot block the public
publish; that image is also cosign-signed.

### F11 — CSP is a response header

**Severity:** Positive — the policy is a Dockerfile build argument served by static-server with a
per-response script nonce; `index.html` carries no `<meta>` CSP (browsers would enforce both, and the
header is the one that can set `frame-ancestors`).

### F12 — Repository variable spliced into a shell script

**Severity:** Info   **Disposition:** RESOLVED (0.1.16)
**Where:** `.github/workflows/docker-publish.yml`, "Assert same-origin API base"
**Issue / impact:** `${{ vars.VITE_API_BASE }}` was expanded into the `run:` script, so a value
containing shell syntax would have run as code in a job holding registry secrets and an OIDC token.
Only maintainers can set the variable, so this was hardening, not an open path.
**Remediation / evidence:** the value is passed through `env` and quoted; actionlint clean. A sweep of
every workflow found no other step that splices an operator-set value into shell logic (the rest echo
build digests or maintainer variables into the job summary).

### F13 — Release tag ran no checks; image published unscanned; no bundled-package SBOM or notices

**Severity:** Low   **Disposition:** RESOLVED (0.1.19, `988719c`)
**Where:** `.github/workflows/docker-publish.yml`, `Dockerfile`, `scripts/third-party-licenses.mjs`
**Issue:** before 0.1.19 the tag-triggered release did not run CI (the workflow header said keeping
CI green before tagging was the gate), the pushed image was signed without a vulnerability scan, the
image's SBOM could not list the npm packages the bundle was built from (the bundle carries no package
metadata), and the licence texts of the bundled dependencies were not redistributed with the site.
**Impact:** a tag on a red commit could publish and sign an image; a fixable CRITICAL/HIGH base or
library advisory would not have stopped the signature; SBOM and licence tooling saw only the base layers.
**Remediation / evidence:** (a) the `verify` job calls `node-ci.yml` through `workflow_call`
(audit gate, `vue-tsc`, three linters, build, licence check, Trivy filesystem scan) and both publish
jobs `needs: verify`. (b) "Scan the published image" (Trivy v0.74.0, `CRITICAL,HIGH`, `exit-code: 1`,
`ignore-unfixed`) runs after the build and push and **before** "Install cosign" and "Sign images", so a
failing image is never signed (it stays an unsigned tag; the cluster deploys by digest and
`verify-digests.sh` rejects unsigned images). (c) The Dockerfile copies `package-lock.json` to
`/usr/share/doc/status-page/` outside the served directory, so the post-push `anchore/sbom-action`
SBOM (SPDX, attested with cosign) lists the 26 production packages. (d) `npm run licenses` writes
`dist/THIRD_PARTY_LICENSES` in the build stage; it is served (live `curl -I` 2026-10-10: 200,
`text/plain`, 41271 bytes, CSP present); CI runs `check:licenses` (26 production packages, 0 without a
licence file) and `test -s dist/THIRD_PARTY_LICENSES`. The v0.1.19 release run (37971840210) was green
on 2026-10-09 and the image was cosign-verified (`verify-digests.sh`, 16/16). Residual notes: the
scan step's image reference uses `vars.QUAY_NAMESPACE` without the `|| 'meddleware-org'` fallback the
other steps carry (the variable is set, 2026-10-01), and the vitest suite is not part of `node-ci.yml`
(F15).

### F14 — Base on an older Go toolchain; runtime user only inherited

**Severity:** Info   **Disposition:** RESOLVED (0.1.18, `c3ae276`)
**Where:** `Dockerfile`, `k8s/base/apps/status`
**Issue:** the runtime stage was static-server 0.1.6 (built on a Go release with stdlib advisories;
govulncheck on 2026-10-09 found 11 in Go 1.26.7), and the Dockerfile did not state its non-root user.
**Impact:** the served binary carried fixable stdlib advisories; the Dockerfile did not document the
user it relies on.
**Remediation / evidence:** the runtime stage is
`quay.io/meddleware-org/static-server:0.1.7@sha256:2e227311…2379` (Go 1.26.9; the same digest is in the
overlay `images:` block) and the Dockerfile sets `USER 65534:65534`. The pod runs `runAsNonRoot`
(uid/gid 65534), `readOnlyRootFilesystem`, `allowPrivilegeEscalation: false`, all capabilities
dropped, `seccompProfile: RuntimeDefault` and `automountServiceAccountToken: false`; readiness and
liveness probes hit `/`; requests 5m/16Mi, limits 100m/32Mi; a default-deny ingress NetworkPolicy
admits only the nginx-ingress namespace on 8080. The deployed ref is the digest in `config/images.yaml`
(0.1.19, `sha256:9dd64c5f…2475`), stamped into `k8s/clusters/meddleware-org/apps/kustomization.yaml`;
the `status-page:0.1.3` tag in the base Deployment is only the readable default that the overlay
`images:` digest replaces.

### F15 — The vitest suite is not run by CI or the release

**Severity:** Low   **Disposition:** ACCEPTED-RISK
**Where:** `.github/workflows/node-ci.yml`
**Issue:** `node-ci.yml` has no `npm test` step, so neither CI nor the release (which calls it, F13)
executes `tests/render-escaping.test.ts`. The TS lens (Section C) calls a test project that CI never
runs a GAP. The suite passes locally (2/2, vitest 5.0.3, 2026-10-10).
**Impact:** a regression in how `StatusGroup` renders names (invariant I2) would not fail a pull
request or a tag; the lint rules in use do not forbid `v-html`.
**Remediation / evidence:** accepted for a display-only page with Low ceiling: today no template uses
`v-html`, `innerHTML`, `eval` or a URL sink (grep of `src/`, 2026-10-10), `parseSnapshot` (the
validation gate, tested in ui's CI) normalises every status and name before they reach a component,
and the CSP blocks inline script. Adding `npm test` to `node-ci.yml` is one line and is the first
implementation suggestion; it closes this.

### F16 — No container probe of the built image in CI

**Severity:** Info   **Disposition:** ACCEPTED-RISK
**Where:** `.github/workflows/`
**Issue:** the IMG lens (Section C) asks CI to probe the running container: health, served headers
and non-root execution. Neither workflow starts the image. The Dockerfile is covered by the Trivy
filesystem scan (`misconfig` scanner) in `node-ci.yml`; the manifests live in the workspace, not this
repository.
**Impact:** a regression in the served headers or in the user would be found at deployment or in a
manual sweep, not at the pull request.
**Remediation / evidence:** accepted: the image adds no code to static-server, the headers and the
non-root pod were checked by hand on 2026-10-09/10 (Section A, B.VUE-1, F14) and the signed digest is
re-verified by `verify-digests.sh`. A header-probe job is in the implementation suggestions.

### F17 — Snapshot size not bounded before parsing

**Severity:** Info   **Disposition:** ADJUDICATED
**Where:** `src/composables/useStatus.ts`
**Issue:** the TS lens asks that size be checked before parsing untrusted JSON; `res.json()` reads
the whole body, and the fetch has a 10 s timeout but no size cap.
**Impact:** an oversized body from the probe would be parsed in the visitor's browser.
**Remediation / evidence:** not a defect here: the only source is the same-origin probe (a first-party
service the page already trusts for the verdict itself, CSP `connect-src 'self'`), the live snapshot is
about 500 bytes (`content-length: 516`, 2026-10-10), and the worst case is a slow tab, not an escalation.
The shape and types of every field are checked by `parseSnapshot` (F1). The cap would belong to the
probe's response contract.

### F18 — Registry pushes use long-lived tokens

**Severity:** Low   **Disposition:** DEFERRED (maintainer: `OPERATOR_TASKS.md` "Image registry
credentials")
**Where:** repository secrets `QUAY_TOKEN`, `DOCKERHUB_TOKEN` (set 2026-08-27)
**Issue:** the publish job holds the registry credentials (a push cannot be keyless), so a runner
compromise could push to the image repositories. Scope and rotation date of each token are not
recorded in the repository.
**Impact:** an attacker with a token could publish an unsigned image, which digest pinning and
`verify-digests.sh` reject; they could not forge the keyless signature.
**Remediation / evidence:** the maintainer records each token's scope and rotation date in the quay
and Docker Hub consoles. Bounds in place: the actions are pinned by commit SHA, the workflow runs only
on `v*` tags with `contents: read` (plus `id-token` and `attestations` on the publish job), and the
cluster verifies the signature. The documented verification command pins the OIDC issuer and the
identity regexp `https://github.com/meddleware-org/status-page/.*` (repository-wide, any workflow and
ref; `verify-digests.sh` uses the same repository-anchored pattern). Narrowing it to the publish
workflow and tag refs is in the implementation suggestions.

### F19 — Chain index health check needs no page change

**Severity:** Positive — the "Chain Access → Chain index" check (`sui-indexer` `/healthz`, 200 and
`"ok":true`) was added to the `status-checks` Secret on 2026-10-09 and the live snapshot lists it
operational (`curl /api/status`, 2026-10-10: Identity & Access, Container Registry and Chain Access,
each operational). The page rendered it unchanged: groups and components are data, the page holds no
check list and shows names, never URLs. The Secret is SOPS-encrypted (age) and mounted by
`platform-probe`, not by this image (B.2).

### F20 — Self-hosted mirror image is signed but not scanned or attested

**Severity:** Info   **Disposition:** DEFERRED (maintainer: the private-registry mirror job fails
without `PRIVATE_REGISTRY_*` credentials; `OPERATOR_TASKS.md` "Image registry credentials")
**Where:** `.github/workflows/docker-publish.yml`, job `publish-private`
**Issue:** the best-effort mirror job (`continue-on-error`) builds and pushes with BuildKit
provenance and keyless-signs the image, but runs no Trivy scan before signing, attaches no SBOM
attestation and no `attest-build-provenance`. `PRIVATE_REGISTRY_USERNAME`/`_TOKEN` are not set
(`gh secret list`, 2026-10-10), so the job fails at login and publishes nothing today.
**Impact:** none now (nothing is pushed, nothing deploys from the mirror: the cluster uses
`quay.io`). If credentials are restored, a mirror image could be signed without the scan and
attestations of the public path (IMG-M7, IMG-M8).
**Remediation / evidence:** when the maintainer restores or retires the mirror, the job either gains
the scan, SBOM attestation and provenance steps of `publish-public` or is removed; until then it is
listed as best-effort in B.2.

### F21 — No build-time check for inline scripts

**Severity:** Low   **Disposition:** MITIGATED
**Where:** `.github/workflows/node-ci.yml`, `Dockerfile`
**Issue:** B.VUE-1 asks for a build-time check that fails when the build emits an inline script not
covered by the CSP. There is none. Today the build emits none: `dist/index.html` carries one
`<script type="module" src="/assets/…js">` and no inline script (checked 2026-10-10); the only inline
script on the live page is Cloudflare's, injected at the edge and covered by the response nonce.
**Impact:** a future dependency or plugin that injected an inline script would be blocked by the
browser rather than caught in CI.
**Remediation / evidence:** compensating control: `script-src 'self'` plus the nonce, no
`'unsafe-inline'` (live header 2026-10-10), so an uncovered inline script is refused at runtime and the
page fails visibly. A CI step that fails on an inline `<script>` without `src` in `dist/index.html` is
in the implementation suggestions.

## Section A — Invariant verification matrix

| # | Invariant | Enforced at | Proven by | Status |
| --- | --- | --- | --- | --- |
| I1 | No health evaluation in the browser | `useStatus`; label maps | source | HOLDS (F7) |
| I2 | Every API field renders as text | templates; `parseSnapshot` | `render-escaping.test.ts`; ui `status.test.ts` | HOLDS (F1, F5) |
| I3 | No persistence | `useStatus` | source | HOLDS (F6) |
| I4 | Same-origin API only | `config.ts`; publish assertion; CSP `connect-src 'self'` | workflow; Dockerfile | HOLDS (F4, F8, F12) |
| I5 | Polling is bounded | 10 s timeout, 15 s interval | source | HOLDS |

### Lens categories

| Lens | Category | Status |
| --- | --- | --- |
| TS | Compiler strictness | HOLDS — `strict: true`; `noUncheckedIndexedAccess` is off, and nothing in `src/` indexes untrusted data (the shape is walked by ui's `parseSnapshot`); `vue-tsc` runs in CI and in the build |
| TS | Assertions at trust boundaries | HOLDS — no `any`, `!` or `eslint-disable` in `src/` (grep 2026-10-10); the one untrusted value is `res.json()`, passed straight to `parseSnapshot(raw: unknown)` |
| TS | Runtime validation | HOLDS for shape and types (F1); no size cap before parsing — ADJUDICATED (F17) |
| TS | Network I/O | HOLDS — one `fetch`, 10 s `AbortSignal.timeout`; the URL is `API_BASE` + a fixed path, empty base by default (F4) |
| TS | Promise handling | HOLDS — the one `catch` in `poll` sets the visible error; the `catch` in `formatTime` returns the raw string, rendered as text |
| TS | Money, encoding, secrets in output, dynamic code, caller-keyed lookups | N/A or HOLDS — no amounts, no base64, no logging, no `eval`/`new Function`/dynamic `import()`, label maps keyed by the parsed `StatusLevel` union |
| TS | Supply chain | HOLDS — `npm ci`, audit gate (F3), Trivy, lockfile; no lifecycle scripts of its own (B.TS-2) |
| TS | Publishing | HOLDS — `private: true`; image only |
| TS | Test coverage in CI | GAP accepted — the vitest suite is not run by CI (F15) |
| VUE | Untrusted rendering | HOLDS (I2, F5) — no URL sink, no `v-html` |
| VUE | Colour & links | Covered upstream — every colour is a design-token variable (CLAUDE.md invariant 4); contrast per theme × season is gated in design-tokens/ui, and this repository runs no axe sweep of its own; no running-text links |
| VUE | Build-time configuration | HOLDS (I4) — `VITE_API_BASE` is documented in the Dockerfile, README and `.env.example` and its default matches (empty); not a secret |
| VUE | Test hooks, signing UX, shared wallet, lazy boundaries, dual app/library | N/A — no test mode, wallet, library entry or heavy SDK |
| VUE | Browser storage | none of its own (no `localStorage`/`sessionStorage` in `src/`); colour mode through ui |
| VUE | Estimates | N/A — the "Updated hh:mm:ss" label formats the probe's timestamp; no client-computed values |
| VUE | Chain-access layering | N/A — no chain code |
| VUE | Hosting headers (B.VUE-1) | HOLDS — live headers below; inline-script build check absent (F21) |
| IMG | Base images, build context | HOLDS — `node:24-slim` and static-server 0.1.7 digest-pinned; the runtime stage is the first-party static-server; `.dockerignore` excludes `node_modules`, `dist`, `.git`, `.env*.local` |
| IMG | Reproducible build, no secrets in layers | HOLDS — `npm ci`; build args are `VITE_API_BASE` (empty) and `CSP`, none secret; only `dist`, the lockfile and licence notices reach the runtime stage |
| IMG | Runtime user & filesystem | HOLDS — `USER 65534:65534`; pod `runAsNonRoot`, read-only root, no escalation, capabilities dropped, `RuntimeDefault` seccomp, `automountServiceAccountToken: false` (F14) |
| IMG | Runtime configuration | HOLDS — `SERVE_DIR`, `SPA_FALLBACK`, `CACHE_IMMUTABLE_PREFIX` (manifest and image), `CONTENT_SECURITY_POLICY` (image; owner lens VUE B.VUE-1) |
| IMG | Health & resources | HOLDS — probes on `/`; 5m/16Mi requests, 100m/32Mi limits |
| IMG | SBOM & notices | HOLDS — lockfile in the image, SPDX SBOM attested; `/THIRD_PARTY_LICENSES` served (F13) |
| IMG | Scan before sign | HOLDS on the public path (Trivy, then cosign); the mirror job has none (F20) |
| IMG | Verification command | HOLDS with a note — pins issuer and repository, not the workflow file or tag ref (F18) |
| IMG | Deployment pinning | HOLDS — digest from `config/images.yaml` in the overlay |
| IMG | Container probe, inline-script build check | GAPS accepted/mitigated (F16, F21) |

## Section B — Supply-chain, publish-authority & capability matrix

### B.1 Dependency & CVE risk

| Dependency | Pinned version | Liveness dependency? | CVE / audit status | Notes |
| --- | --- | --- | --- | --- |
| `@meddleware/ui` | `^0.1.31` (0.1.31) | `parseSnapshot`, components | clean | latest |
| `@meddleware/design-tokens` | `^0.1.9` (0.1.9) | CSS | clean | latest |
| `vue` | `^3.5.43` | rendering | clean | |
| `vite` / `@vitejs/plugin-vue` | `^8.3.3` / `^6.0.9` | build | clean | |
| `typescript` / `vitest` | `^6.0.0` (6.0.3) / `~5.0.3` | build, test | clean | TypeScript 7 deferred (decision); vitest 5 is the workspace line |
| dev tooling | lockfile | no | GHSA-vfj7-8cjw-p6xm allowlisted to 2027-01-01; `npm audit --omit=dev`: 0 | TS lens B.TS-3 |
| `node:24-slim` (build) | `@sha256:0e0ff40c…f9b6` | no | Trivy filesystem scan in CI; image scan at release (F13) | Node 24 LTS only |
| `static-server` (runtime) | `0.1.7@sha256:2e227311…2379` | serves the page | Go 1.26.9; Trivy image scan at release | first-party |

Shared-dependency matrix (TS lens B.1): the project uses none of the `@mysten/*` packages that
ADR-0001 baselines; `vue` ^3.5.43, `typescript` ^6.0.0 and `vitest` ~5.0.3 are in line with the other
Vue repositories (dashboard, landing, treasury-ui, ui: vue ^3.5.43, TypeScript 6, vitest ~5.0.x; the
`~`/`^` spelling of the TypeScript range varies, which is harmless here). There are no first-party
`0.0.x` ranges (both `@meddleware/*` ranges are `^0.1.x`), and the page builds or signs nothing.

### B.TS-2 Install-time code

`package.json` has no `preinstall`, `install`, `postinstall`, `prepare` or `prepublishOnly` script, no
`overrides` and no `allowScripts`. In the lockfile only `fsevents` (macOS-only optional file watcher
for dev tooling) declares an install script; it is not installed on Linux or in the image build.
`npm ci` in the Dockerfile and in CI.

### B.VUE-1 Hosting headers

The only hosting path is the image behind Cloudflare. Seen with `curl -I https://status.meddleware.co.uk/`
on 2026-10-10 (0.1.19):

| Header | Observed |
| --- | --- |
| `Content-Security-Policy` | `default-src 'self'; script-src 'self' 'nonce-…'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'self'; upgrade-insecure-requests` — the per-response nonce is static-server's, for the edge's own script; `'unsafe-inline'` is for styles only; same header on `/THIRD_PARTY_LICENSES`; no `<meta>` CSP |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` |
| `Referrer-Policy`, `Permissions-Policy`, `X-Content-Type-Options` | `strict-origin-when-cross-origin`; camera, geolocation, microphone, payment off; `nosniff` |
| Framing | `frame-ancestors 'self'` and `X-Frame-Options: SAMEORIGIN` (no embedding by other hosts) |

`/api/status` is served by `platform-probe`, not this image: `Content-Security-Policy: default-src
'none'; frame-ancestors 'none'`, `Cache-Control: no-store`, `nosniff`, `Access-Control-Allow-Origin: *`
(public, read-only; the other sites' status widget reads it). The build-time inline-script check is
absent (F21).

### B.VUE-2 Build inputs and artifacts

Production sourcemaps: none (`vite build` defaults; no `build.sourcemap`). Docker build args are
`VITE_API_BASE` (empty; asserted empty before the public build) and `CSP`; neither is a test-mode
switch (there is no test mode). `.dockerignore` keeps `.env*.local` out of the context (IMG §A).

### B.IMG-1 Publish & attestation

Public path (`publish-public`): multi-arch build (amd64, arm64) with BuildKit provenance (`mode=max`),
Trivy, keyless cosign signature, SPDX SBOM attested with cosign, and GitHub build-provenance
attestations, on quay.io and Docker Hub, none with `continue-on-error`; signed at the index digest.
The self-hosted registry mirror is best-effort (`continue-on-error`), signed but not scanned or
attested, and currently fails for lack of credentials (F20). Verification: the README's `cosign
verify` pins the issuer and the repository identity (F18).

### B.2 Publish authority, capabilities & secret custody

| Authority / secret | Where held | Custody | Gates | Rotation |
| --- | --- | --- | --- | --- |
| `QUAY_TOKEN`, `DOCKERHUB_TOKEN` | GitHub secrets (set 2026-08-27) | robot accounts | image push | scope and rotation date to be recorded (F18) |
| `PRIVATE_REGISTRY_*` | not set | registry robot | best-effort push; the job fails without them | maintainer: restore or retire (F20) |
| image signing | GitHub Actions | cosign keyless | quay.io and Docker Hub (and the mirror when it runs) | n/a |
| `VITE_API_BASE` | repository variable (unset) | not a secret | must be empty (F4) | n/a |
| `status-checks` Secret (`k8s/clusters/meddleware-org/apps/status-checks-secret.enc.yaml`) | cluster, namespace `apps`; SOPS (age) encrypted in the workspace | the age private key stays on the node; the file is safe to commit and keep a durable copy (`OPERATOR_TASKS.md`, done 2026-10-09) | mounted read-only by `platform-probe` only (directory mount, `fsGroup` 65534, mode 0440); this image never sees it | key custody and rotation belong to the platform audit |
| Workflow action pins | `.github/workflows/*` | every action pinned by commit SHA; Dependabot weekly, grouped | `permissions: contents: read`; `id-token` and `attestations: write` only on the publish job | n/a |

## Section C — Test-coverage & hermetic/live split

### C.1 Coverage grade — C (2/2, re-run 2026-10-10)

The render-escaping test mounts `StatusGroup` with HTML in names and asserts it renders as text, and
that an unknown status renders an empty label; `parseSnapshot` itself is tested in ui. Polling has no
unit test (a mocked-`fetch` test would cover the timeout, non-OK and malformed-body paths). The suite
runs locally only: CI does not execute it (F15). Quality gates in CI: `vue-tsc`, stylelint, eslint
(vue-a11y), html-validate, the production build, the licence check and the Trivy filesystem scan; the
linters and html-validate are quality gates, not security evidence.

### C.2 Hermetic vs. live paths

| Path | Hermetic? | Deferred to | Tracking |
| --- | --- | --- | --- |
| Rendering and parsing | yes | — | `npm test` (local); ui tests (CI) |
| Polling against the real probe | no | live sweep | Phase 7 Chromium sweep; live `/api/status` and `/` headers read with `curl` on 2026-10-10 |
| Built image: served headers, `/THIRD_PARTY_LICENSES`, non-root pod | no | live deployment | manual `curl -I` 2026-10-10; `bootstrap/images/verify-digests.sh` (16/16 valid 2026-10-09); F16 |

## Section D — Deployment-readiness gates

### pre-localnet

- [x] builds; type-check, three linters, tests green; no secrets — `vue-tsc`, linters and build in CI; `npm test` 2/2 locally (F15)
- [x] no `v-html`; no dynamic href/src; no secret `VITE_*` value; `VITE_*` inventory matches `.env.example` (F5, F8)
- [x] every `FROM` digest-pinned; `.dockerignore` excludes local env files and installs; lockfile installs (`npm ci`); no secret in `ARG`/`ENV`/`COPY`/`RUN`
- [x] strict type-check; untrusted parser validates every field (F1); no swallowed promises on security paths

### pre-testnet

- [x] deployed with digest pinning; CSP and HSTS verified; `SECURITY.md` present — 0.1.19 digest in `config/images.yaml` and the overlay, headers seen 2026-10-10 (B.VUE-1)
- [x] 0.1.19 deployed (2026-10-09); release run green; cosign signature valid (`verify-digests.sh` 16/16)
- [x] non-root runtime; pod security context complete; probes and limits set (F14)
- [x] audit gate in CI and in the release (via `node-ci.yml`); no install-time code (B.TS-2); nothing to `npm pack` (`private: true`)
- [x] test-mode guards: none needed — no test mode exists (B.VUE-2)
- [x] release gate equals CI for the image (F13)
- [ ] every test project runs in CI — accepted gap, vitest suite not in `node-ci.yml` (F15)
- [ ] container probe in CI — accepted gap (F16); inline-script build check — mitigated, not implemented (F21)

### pre-mainnet

- [x] signed images on every public registry; non-root runtime — SBOM attestation and provenance on quay.io and Docker Hub, no `continue-on-error` on that path (B.IMG-1)
- [x] CSP and HSTS deployed on every hosting path — the only path is the image behind Cloudflare (B.VUE-1)
- [x] image scan clean at the release (Trivy, fixable CRITICAL/HIGH) and `npm audit --omit=dev` 0 on 2026-10-10
- [x] every fetch has a timeout; no raw `btoa`/`atob`; no `any`/`as`/`!` at trust boundaries (Section A)
- [ ] registry token scope and rotation recorded — maintainer-only (F18, `OPERATOR_TASKS.md` "Image registry credentials")
- [ ] self-hosted mirror restored with scan and attestations, or retired — maintainer-only (F20)

## Cross-project themes

- **Supply chain** — signed, attested, digest-pinned images; Trivy (filesystem in CI, image before
  signing at release) plus the npm audit gate; the lockfile and licence notices travel with the image (F13).
- **Workflow hygiene** — operator-set values reach shell steps only through `env` (F12).

## Normative requirements (MUST / MUST NOT)

- **TS-M1–TS-M8** — hold where applicable (TS-M3 and TS-M4 not applicable; exceptions below).
- **VUE-M1–VUE-M9** — M1, M2, M8 hold (M2: no commission IDs, `VITE_API_BASE` is not secret); M3–M7 and
  M9 are not applicable (no test mode, wallet, storage or library entry).
- **IMG-M1–IMG-M8** — hold on the public path (digest-pinned bases, `.dockerignore`, lockfile install,
  no secrets, non-root restricted pod, deploy by digest, signature with SBOM and provenance, scan
  before sign, licence notices, verification command); the self-hosted mirror is best-effort and does
  not meet M7/M8 (F20); the verification command pins the repository, not the workflow (F18).
- **TS-M1–TS-M8 exceptions** — the suite is not run in CI (F15); no size cap before parsing (F17).

## Implementation suggestions (SHOULD / MAY)

- SHOULD add `npm test` to `node-ci.yml`, so CI and the release run the render-escaping test (F15).
- MAY add a `useStatus` test with a mocked `fetch` (timeout, non-OK, malformed body).
- MAY add a CI step that fails on an inline `<script>` without `src` in `dist/index.html` (F21), and a
  job that runs the built image and probes `/`, the headers and the user (F16).
- MAY narrow the documented `cosign verify` identity to the publish workflow and tag refs, e.g.
  `--certificate-identity-regexp '^https://github.com/meddleware-org/status-page/\.github/workflows/docker-publish\.yml@refs/tags/v.*$'`
  (F18).
- MAY give the Trivy step the same `|| 'meddleware-org'` namespace fallback as the other steps (F13).

## Open questions (`OQ#`)

- **OQ1** — (Decided 2026-09-19: `parseSnapshot` is the validation gate — see F1.)
- **OQ2** — Was `npm install` deliberate? (Decided: no — `npm ci` — see F2.)
- **OQ3** — Is the missing test suite intentional? (Decided: no — render-escaping test added; see C.1.)
- **OQ4** — (Decided: the private-registry image is signed — see F10.)
- **OQ5** — Where does the CSP live? (Decided 2026-10-01: the static-server response header with a
  per-response nonce; no `<meta>` CSP — see F11.)

## Risks

- **Probe liveness** — when `platform-probe` is down the page shows the fetch error.
- **Check content** — the page shows what the probe's `status-checks` Secret lists; a wrong or
  missing check shows as a wrong or missing row, not an error (the Secret's custody: B.2).
- **Edge-injected script** — the page relies on Cloudflare's nonce-tagged script being the only inline
  script; a change in the edge product is caught by the CSP, not by CI (F21).

## Re-verification log

- 2026-09-19 — first-pass baseline (F1–F11).
- 2026-10-01 — static-server 0.1.3 base; CSP moved to the response header (F11).
- 2026-10-03 — re-verified under AUDIT_TEMPLATE.md + TS + VUE + IMG (Phase 7): rewritten to the
  current template (stale versions, test grade and OQs corrected). F12 RESOLVED in 0.1.16 (with ui
  0.1.30, design-tokens 0.1.8). Counts: 2/2.
- 2026-10-03 — 0.1.16 deployed; live sweep clean.
- 2026-10-08 — Lens dates reconciled with the registry (`check-template-dates.mjs`): base 2026-10-08, and SUI_CLIENT/GO 2026-10-08 and TS 2026-10-03 where cited. The changes (AUTH/PLATFORM/MCP/DB registered, the GO token row moved to AUTH, JSR in trusted publishing, layered injection guards) alter no disposition here.
- 2026-10-09 — re-verified at 0.1.19 (deployed; run `v0.1.19` green): every finding re-checked
  against the code, workflows, the manifests, the live headers and the live snapshot. F13 (release =
  full CI, Trivy before cosign, lockfile in the image, `/THIRD_PARTY_LICENSES`) and F14 (static-server
  0.1.7, `USER 65534:65534`) RESOLVED; F15 (vitest not in CI) and F16 (no container probe) ACCEPTED-RISK;
  F17 ADJUDICATED; F18 DEFERRED (`OPERATOR_TASKS.md`); F19 (Chain index check) recorded. Added F20
  (mirror job: no scan or attestations; DEFERRED, maintainer) and F21 (no inline-script build check;
  MITIGATED). Added the IMG, TS and VUE lens categories, B.TS-2, B.VUE-1/2, B.IMG-1 and the
  `status-checks` Secret row to B.2, and ticked Section D with evidence. Stale facts corrected
  (static-server 0.1.3 to 0.1.7, ui 0.1.31, design-tokens 0.1.9). PLATFORM lens not triggered: the Secret
  is the platform's and is mounted by `platform-probe`.
