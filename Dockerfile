# ── Build stage ───────────────────────────────────────────────────────────────
# Content-Security-Policy served by static-server. The status page is same-origin only: it loads
# its own bundle and polls GET /api/status on its own host, so connect-src is 'self'. If VITE_API_BASE
# points at another origin, pass a CSP build arg that adds it to connect-src. style-src keeps
# 'unsafe-inline' for the inline <style> Vite/Vue emit; there are no inline scripts (scripts/check-csp-inline.mjs
# fails the build if one appears).
ARG CSP="default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'self'; upgrade-insecure-requests"

# The build stage runs on the BUILD host's architecture: its output (static files) is architecture-independent,
# so no arm64 step runs under emulation. The final stage only COPYs into the multi-arch static-server image.
FROM --platform=$BUILDPLATFORM node:26-slim@sha256:0d1e33586362bb9e608c4e751e7a9e7edb55c9ac11461ed5666af696cc461dd4 AS build

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
ARG CSP
# The CSP has no 'unsafe-inline' for scripts: the build fails if dist/ ever carries an inline <script>.
RUN node scripts/check-csp-inline.mjs "${CSP}" dist

# ── Runtime stage ──────────────────────────────────────────────────────────────
FROM quay.io/meddleware-org/static-server:0.1.9@sha256:af6cc284dace0d7bcacca61765f1e5efa0681da503c607f6e13ea35ce19edc72
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
