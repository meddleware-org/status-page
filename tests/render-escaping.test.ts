import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'

// Replace the prebuilt @meddleware/ui UiCard (its dist doesn't render under a second Vue runtime in
// tests) with a minimal slot-rendering stub, so we exercise StatusGroup's OWN template escaping.
// StatusDot only imports an erased type from @meddleware/ui, so it renders unmocked.
vi.mock('@meddleware/ui', () => ({
  UiCard: { name: 'UiCard', props: ['title'], template: '<section><slot /></section>' },
}))

import StatusGroup from '../src/components/StatusGroup.vue'

// The /api/status snapshot is attacker-influenceable (a compromised platform-probe could inject
// crafted strings). Invariant I2: every API field renders as text via `{{ }}`, never as markup.
// This proves it for the component name — the one untrusted field StatusGroup renders directly.
const XSS = '<img src=x onerror="alert(1)">'

describe('render-escaping (API strings render as text, never markup)', () => {
  it('renders an attacker-supplied component name as inert text, not an element', () => {
    const w = mount(StatusGroup, {
      props: {
        group: { name: 'Group A', status: 'operational', components: [{ name: XSS, status: 'operational' }] },
      },
    })
    expect(w.find('img').exists()).toBe(false)
    expect(w.text()).toContain(XSS)
  })

  it('renders an unknown status as an empty label rather than markup', () => {
    const w = mount(StatusGroup, {
      props: {
        group: { name: 'G', status: 'operational', components: [{ name: 'svc', status: '<b>x</b>' as never }] },
      },
    })
    // No <b> element is created, and an unrecognised status maps to an empty label (never markup).
    expect(w.find('b').exists()).toBe(false)
    expect(w.find('.component-row__label').text()).toBe('')
  })
})
