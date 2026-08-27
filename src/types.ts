export type StatusLevel = 'operational' | 'degraded' | 'down' | 'unknown'

export interface StatusComponent {
  name: string
  status: StatusLevel
}

export interface StatusGroup {
  name: string
  status: StatusLevel
  components: StatusComponent[]
}

export interface StatusSnapshot {
  generated_at: string
  overall: StatusLevel
  groups: StatusGroup[]
}
