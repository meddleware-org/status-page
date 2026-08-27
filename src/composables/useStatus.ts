import { ref, onMounted, onUnmounted } from 'vue'
import type { StatusSnapshot } from '../types'
import { API_BASE } from '../config'

export function useStatus() {
  const snapshot = ref<StatusSnapshot | null>(null)
  const error = ref<string | null>(null)
  const loading = ref(true)

  async function poll() {
    try {
      const res = await window.fetch(`${API_BASE}/api/status`)
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      snapshot.value = (await res.json()) as StatusSnapshot
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
