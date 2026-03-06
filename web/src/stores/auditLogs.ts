import { ref } from 'vue'
import { defineStore } from 'pinia'

export interface AuditLogEntry {
  id: number
  action: string
  entityType: string
  entityId?: string
  description: string
  performedBy: string
  createdAt: string
}

export interface NewAuditLogEntry {
  action: string
  entityType: string
  entityId?: string
  description: string
  performedBy: string
}

export const useAuditLogsStore = defineStore('audit-logs', () => {
  const entries = ref<AuditLogEntry[]>([])

  function addEntry(payload: NewAuditLogEntry) {
    const now = new Date()
    const entry: AuditLogEntry = {
      id: now.getTime(),
      ...payload,
      createdAt: now.toISOString(),
    }

    entries.value.unshift(entry)
  }

  function clear() {
    entries.value = []
  }

  return {
    entries,
    addEntry,
    clear,
  }
})

