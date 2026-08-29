/**
 * Base URL for the `/api/status` endpoint. Defaults to the empty string (same-origin), so
 * nginx routes `/api/` to platform-probe on the same host. Set `VITE_API_BASE` at build time
 * only when the probe is on a different origin (e.g. dev/staging without a local proxy).
 */
export const API_BASE: string = import.meta.env.VITE_API_BASE ?? ''
