# ── Build stage ───────────────────────────────────────────────────────────────
# Content-Security-Policy served by static-server. The status page is same-origin only: it loads
# its own bundle and polls GET /api/status on its own host, so connect-src is 'self'. If VITE_API_BASE
# points at another origin, pass a CSP build arg that adds it to connect-src. style-src keeps
# 'unsafe-inline' for the inline <style> Vite/Vue emit; there are no inline scripts.
ARG CSP="default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'self'; upgrade-insecure-requests"

FROM node:24-slim@sha256:0e0ff40c39bc087845bfb27465a0df4ea419520094bc35842ff83dd8cbe6f9b6 AS build

WORKDIR /app

# Install deps first so this layer is cached on code-only changes.
COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# VITE_API_BASE defaults empty → relative URL (/api/status). Set at build time
# if the platform-probe API is on a different origin (dev/staging only; in
# production nginx routes /api/ to platform-probe on the same hostname).
ARG VITE_API_BASE=""
ENV VITE_API_BASE=${VITE_API_BASE}

RUN npm run build && npm run licenses

# ── Runtime stage ──────────────────────────────────────────────────────────────
FROM quay.io/meddleware-org/static-server:0.1.7@sha256:2e2273115b7575acbeb01c6d75f867be67125405f1bda5d956ae512d13c92379
ARG CSP
ENV CONTENT_SECURITY_POLICY="${CSP}"

COPY --from=build /app/dist /app/public
# The lockfile lets SBOM scanners see the npm packages the bundle was built from (the bundle itself carries no
# package metadata). It sits outside the served directory; THIRD_PARTY_LICENSES is served with the site.
COPY --from=build /app/package-lock.json /usr/share/doc/status-page/package-lock.json

ENV SERVE_DIR=/app/public \
    SPA_FALLBACK=true \
    CACHE_IMMUTABLE_PREFIX=/assets/

USER 65534:65534

EXPOSE 8080
