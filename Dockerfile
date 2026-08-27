# ── Build stage ───────────────────────────────────────────────────────────────
FROM node:22-slim AS build

WORKDIR /app

# Install deps first so this layer is cached on code-only changes.
COPY package.json ./
RUN npm install

COPY . .

# VITE_API_BASE defaults empty → relative URL (/api/status). Set at build time
# if the platform-probe API is on a different origin (dev/staging only; in
# production nginx routes /api/ to platform-probe on the same hostname).
ARG VITE_API_BASE=""
ENV VITE_API_BASE=${VITE_API_BASE}

RUN npm run build

# ── Runtime stage ──────────────────────────────────────────────────────────────
FROM quay.io/meddleware-org/static-server:0.1.0

COPY --from=build /app/dist /app/public

ENV SERVE_DIR=/app/public \
    SPA_FALLBACK=true \
    CACHE_IMMUTABLE_PREFIX=/assets/

USER 65534:65534

EXPOSE 8080
