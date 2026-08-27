<script setup lang="ts">
import { AppHeader, AppFooter, UiNotice, ColorModeControl, useColorMode } from '@meddleware/ui'
import { useStatus } from './composables/useStatus'
import StatusBanner from './components/StatusBanner.vue'
import StatusGroup from './components/StatusGroup.vue'

const { snapshot, error, loading } = useStatus()
const { mode, set } = useColorMode()
</script>

<template>
  <div class="layout">
    <AppHeader variant="dark">
      <template #brand>
        <span class="brand">meddleware</span>
      </template>
      <template #center>
        <span class="page-title">Service Status</span>
      </template>
      <template #actions>
        <ColorModeControl :model-value="mode" @update:model-value="set" />
      </template>
    </AppHeader>

    <main class="main">
      <div class="container">
        <template v-if="loading">
          <div class="skeleton-banner" />
          <div class="skeleton-group" />
          <div class="skeleton-group" />
        </template>

        <template v-else-if="error">
          <UiNotice type="error">
            Could not load status: {{ error }}
          </UiNotice>
        </template>

        <template v-else-if="snapshot">
          <StatusBanner :overall="snapshot.overall" :generated-at="snapshot.generated_at" />
          <div class="groups">
            <StatusGroup v-for="group in snapshot.groups" :key="group.name" :group="group" />
          </div>
        </template>
      </div>
    </main>

    <AppFooter>
      <template #center>
        <span class="footer-note">Checks run server-side every 15 s. Results are cached — this page never probes internal services directly.</span>
      </template>
    </AppFooter>
  </div>
</template>

<style scoped>
.layout {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  background: var(--bg);
  color: var(--text);
  font-family: var(--mw-font-sans);
}

.brand {
  font-weight: 700;
  letter-spacing: -0.02em;
  color: var(--mw-panel-dark-text);
}

.page-title {
  font-size: 0.9375rem;
  color: var(--mw-panel-dark-muted);
}

.main {
  flex: 1;
  padding: 2rem 1rem;
}

.container {
  max-width: 720px;
  margin: 0 auto;
}

.groups {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

/* Loading skeletons */
.skeleton-banner,
.skeleton-group {
  border-radius: var(--mw-radius);
  background: var(--lift);
  animation: pulse 1.4s ease-in-out infinite;
}

.skeleton-banner {
  height: 64px;
  margin-bottom: 2rem;
}

.skeleton-group {
  height: 120px;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.footer-note {
  font-size: 0.8125rem;
  color: var(--muted);
}
</style>

<style>
*, *::before, *::after {
  box-sizing: border-box;
}

body {
  margin: 0;
}
</style>
