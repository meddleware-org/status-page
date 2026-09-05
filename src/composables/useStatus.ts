import { ref, onMounted, onUnmounted } from 'vue'
import { parseSnapshot } from '@meddleware/ui'
import type { StatusSnapshot } from '@meddleware/ui'
import { API_BASE } from '../config'

/**
 * Fetch and auto-refresh the status snapshot from `/api/status` every 15 seconds.
 * Never derives or overrides status values — renders exactly what the API returns.
 *
 * @returns `snapshot` — the latest status snapshot (null while loading); `error` — the
 *   last fetch error message (null on success); `loading` — true during the first fetch.
 */
export function useStatus() {
  const snapshot = ref<StatusSnapshot | null>(null)
  const error = ref<string | null>(null)
  const loading = ref(true)

  async function poll() {
    try {
      const res = await window.fetch(`${API_BASE}/api/status`)
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const snap = parseSnapshot(await res.json())
      if (!snap) throw new Error('unexpected response shape')
      snapshot.value = snap
      error.value = null
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'failed to fetch status'
    } finally {
      loading.value = false
    }
  }

  let timer: ReturnType<typeof setInterval>
  onMounted(() => {
    poll()
    timer = setInterval(poll, 15_000)
  })
  onUnmounted(() => clearInterval(timer))

  return { snapshot, error, loading }
}
