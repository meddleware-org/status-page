# Security Policy

## Scope

This policy covers security issues in the `status-page` application source (`src/**`) — the
display-only SPA that renders the `platform-probe` `/api/status` snapshot.

It does not cover `platform-probe` (see its own policy), `@meddleware/ui`/`design-tokens`, or the
network edge.

## Security model (invariants)

These invariants are load-bearing. A report demonstrating that any is violated is in scope and
treated as high severity:

1. **Display-only.** The page performs no health evaluation, inference, or persistence — it renders
   the topology-free snapshot verbatim.
2. **Snapshot fields render as text.** No `/api/status` field is rendered as HTML.
3. **Same-origin API by default; no secret in `VITE_*`.** `VITE_API_BASE` defaults to empty
   (same-origin `/api/`); any override is a trusted URL, and no value is a secret. **Production
   builds MUST leave `VITE_API_BASE` empty** so the page only ever polls its own origin (nginx routes
   `/api/` to `platform-probe`). A non-empty value is for dev/staging cross-origin setups only; baking
   an untrusted origin into a production bundle would point the status display at an unverified probe.
   The publish workflow asserts `VITE_API_BASE` is empty before building the public image.

## Content-Security-Policy

The policy is a response header: the Dockerfile `CSP` build arg, served by static-server as
`CONTENT_SECURITY_POLICY` — `default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';
img-src 'self' data:; font-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none';
form-action 'none'; frame-ancestors 'self'; upgrade-insecure-requests`. There are no inline scripts;
`'unsafe-inline'` is permitted only for styles.

static-server (0.1.3+) appends a fresh `'nonce-…'` to `script-src` on every response. Cloudflare
reads it and tags the inline script its JavaScript Detections injects (always on with Bot Fight
Mode), so that script runs without `'unsafe-inline'`. For the same reason there is **no** `<meta>`
CSP: browsers enforce every policy, and an edge can add its nonce only to the header policy.

## Image signing

All published images are cosign keyless-signed (Sigstore Fulcio/Rekor via GitHub Actions OIDC) with
build provenance — the public `quay.io` / Docker Hub images **and** the self-hosted
`registry.meddleware.co.uk` image (the private registry is CNCF `distribution` v3, which stores the
cosign `.sig` OCI artifact). The private-registry push remains `continue-on-error` (best-effort
secondary), but it is now signed rather than unsigned.

## Supported versions

Only the latest published image receives security fixes.

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities. Report by emailing
**<security@meddleware.co.uk>** with a description, reproduction/PoC if available, and the image tag
or commit SHA tested. You will receive an acknowledgement within **3 business days** and a resolution
plan within **14 days** for confirmed issues; Critical issues (CVSS ≥ 9.0) are prioritised for
same-day acknowledgement.

## Disclosure

Once a fix is released, a security advisory will be published on the GitHub repository. Reporters may
be credited by name unless they prefer to remain anonymous.
