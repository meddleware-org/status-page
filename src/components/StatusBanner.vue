<script setup lang="ts">
import type { StatusLevel } from '@meddleware/ui'
import StatusDot from './StatusDot.vue'

defineProps<{
  /** Aggregate system status — drives the banner label and colour. */
  overall: StatusLevel
  /** ISO 8601 timestamp when the snapshot was generated; displayed as a formatted time. */
  generatedAt: string
}>()

const LABEL: Record<StatusLevel, string> = {
  operational: 'All systems operational',
  degraded: 'Partial outage',
  down: 'Major outage',
  unknown: 'Status unknown',
}

function formatTime(iso: string): string {
  try {
    return new Date(iso).toLocaleTimeString(undefined, {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    })
  } catch {
    return iso
  }
}
</script>

<template>
  <div class="banner" :class="`banner--${overall}`">
    <div class="banner__inner">
      <StatusDot :status="overall" size="md" />
      <span class="banner__label">{{ LABEL[overall] }}</span>
    </div>
    <span class="banner__meta">Updated {{ formatTime(generatedAt) }}</span>
  </div>
</template>

<style scoped>
.banner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 0.5rem;
  padding: 1rem 1.25rem;
  border-radius: var(--mw-radius);
  background: var(--surface);
  border: 1px solid var(--border);
  margin-bottom: 2rem;
}

.banner__inner {
  display: flex;
  align-items: center;
  gap: 0.625rem;
}

.banner__label {
  font-size: 1.0625rem;
  font-weight: 600;
  color: var(--text);
}

.banner__meta {
  font-size: 0.8125rem;
  color: var(--muted);
}
</style>
