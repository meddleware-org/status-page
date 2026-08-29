<script setup lang="ts">
import { UiCard } from '@meddleware/ui'
import type { StatusGroup } from '../types'
import StatusDot from './StatusDot.vue'

defineProps<{
  /** The status group to render, including its name, aggregate status, and components. */
  group: StatusGroup
}>()

const STATUS_LABEL: Record<string, string> = {
  operational: 'Operational',
  degraded: 'Degraded',
  down: 'Down',
  unknown: 'Unknown',
}
</script>

<template>
  <UiCard :title="group.name">
    <ul class="component-list">
      <li v-for="component in group.components" :key="component.name" class="component-row">
        <span class="component-row__name">{{ component.name }}</span>
        <span class="component-row__status">
          <StatusDot :status="component.status" size="sm" />
          <span class="component-row__label">{{ STATUS_LABEL[component.status] }}</span>
        </span>
      </li>
    </ul>
  </UiCard>
</template>

<style scoped>
.component-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.component-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.5rem 0;
  border-bottom: 1px solid var(--border);
  font-size: 0.9375rem;
}

.component-row:last-child {
  border-bottom: none;
}

.component-row__name {
  color: var(--text);
}

.component-row__status {
  display: flex;
  align-items: center;
  gap: 0.4rem;
}

.component-row__label {
  font-size: 0.8125rem;
  color: var(--muted);
}
</style>
