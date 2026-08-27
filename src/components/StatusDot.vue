<script setup lang="ts">
import type { StatusLevel } from '../types'

const props = defineProps<{ status: StatusLevel; size?: 'sm' | 'md' }>()

const COLOR_MAP: Record<StatusLevel, string> = {
  operational: 'var(--mw-ok-500)',
  degraded: 'var(--mw-gold-500)',
  down: 'var(--mw-danger-500)',
  unknown: 'var(--muted)',
}
</script>

<template>
  <span
    class="status-dot"
    :class="`status-dot--${props.size ?? 'md'}`"
    :style="{ background: COLOR_MAP[props.status] }"
    :aria-label="props.status"
  />
</template>

<style scoped>
.status-dot {
  display: inline-block;
  border-radius: 50%;
  flex-shrink: 0;
}
.status-dot--sm {
  width: 8px;
  height: 8px;
}
.status-dot--md {
  width: 12px;
  height: 12px;
}
</style>
