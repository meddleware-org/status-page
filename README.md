# status-page

A Vue 3 SPA that displays the live status of the Meddleware platform. It polls
[`platform-probe`](https://github.com/meddleware-org/platform-probe)'s `/api/status`
endpoint every 15 s and renders the result as a capability-grouped status board. The page
never probes any service directly — all health evaluation is server-side in platform-probe.

- **Runtime base:** `quay.io/meddleware-org/static-server` (zero OS footprint, nginx-based)
- **Stack:** Vue 3 + Vite + `@meddleware/design-tokens` + `@meddleware/ui`
- **License:** BSD Zero Clause ([0BSD](LICENSE))

## Dev

```bash
npm install
npm run dev     # http://localhost:5173 — proxies /api → http://localhost:8080
```

The Vite dev proxy forwards `/api` to `localhost:8080`. Run platform-probe locally alongside:

```bash
# In a separate terminal (from the platform-probe repo):
CHECKS_CONFIG_FILE=config.example.json go run ./cmd/server
```

## Build

```bash
npm run type-check   # vue-tsc type check only
npm run build        # type-check + Vite production build → dist/
```

## Environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `VITE_API_BASE` | `""` | API origin prefix. Empty = same-origin `/api/status`. Set at build time to point at a remote platform-probe in dev or staging. |

In production, nginx routes `/api/` to platform-probe on the same hostname, so `VITE_API_BASE`
stays empty (the default).

## Verifying published images

Images are multi-arch, carry an SBOM + SLSA provenance, and are signed with keyless
[cosign](https://docs.sigstore.dev/):

```bash
cosign verify \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp 'https://github.com/meddleware-org/status-page/.*' \
  quay.io/meddleware-org/status-page:<tag>
```

## License

[0BSD](LICENSE) — BSD Zero Clause License.
