<script setup lang="ts">
// Decorative health dot. It always sits beside a visible status label (which carries the
// meaning), so it is hidden from assistive technology; the level only selects a colour class.
import type { StatusLevel } from '@meddleware/ui'

withDefaults(
  defineProps<{
    /** Current health level — selects the design-token colour. */
    status: StatusLevel
    /** Dot diameter: `sm` (8 px) or `md` (12 px, default). */
    size?: 'sm' | 'md'
  }>(),
  { size: 'md' },
)
</script>

<template>
  <span class="status-dot" :class="[`status-dot--${size}`, `status-dot--${status}`]" aria-hidden="true" />
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
.status-dot--operational {
  background: var(--ok);
}
.status-dot--degraded {
  background: var(--warning);
}
.status-dot--down {
  background: var(--danger);
}
.status-dot--unknown {
  background: var(--muted);
}
</style>
