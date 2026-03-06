import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { useAuthStore } from './auth'
import { useAuditLogsStore } from './auditLogs'

export interface EventItem {
  id: number
  title: string
  description: string
  date: string
  location: string
  latitude?: number
  longitude?: number
  isDeleted: boolean
  createdAt: string
}

export interface EventPayload {
  title: string
  description: string
  date: string
  location: string
  latitude?: number
  longitude?: number
}

const initialEvents: EventItem[] = [
  {
    id: 100,
    title: 'Local Job Fair',
    description: 'Multi-employer job fair hosted by PESO.',
    date: new Date().toISOString().slice(0, 10),
    location: 'Municipal Gymnasium',
    latitude: 14.6,
    longitude: 120.98,
    isDeleted: false,
    createdAt: new Date().toISOString(),
  },
]

export const useEventsStore = defineStore('events', () => {
  const events = ref<EventItem[]>([...initialEvents])

  const activeEvents = computed(() =>
    events.value.filter((event) => !event.isDeleted),
  )
  const archivedEvents = computed(() =>
    events.value.filter((event) => event.isDeleted),
  )

  function createEvent(payload: EventPayload) {
    const now = new Date()
    const item: EventItem = {
      id: now.getTime(),
      title: payload.title.trim(),
      description: payload.description.trim(),
      date: payload.date,
      location: payload.location.trim(),
      latitude: payload.latitude,
      longitude: payload.longitude,
      isDeleted: false,
      createdAt: now.toISOString(),
    }

    events.value.push(item)

    const authStore = useAuthStore()
    const auditStore = useAuditLogsStore()
    auditStore.addEntry({
      action: 'create',
      entityType: 'event',
      entityId: String(item.id),
      description: `Created event "${item.title}"`,
      performedBy: authStore.user?.name ?? 'System',
    })
  }

  function updateEvent(id: number, updates: Partial<EventPayload>) {
    const index = events.value.findIndex((event) => event.id === id)
    if (index === -1) return

    const before = events.value[index]
    const updated: EventItem = {
      ...before,
      ...updates,
      title: updates.title !== undefined ? updates.title.trim() : before.title,
      description:
        updates.description !== undefined
          ? updates.description.trim()
          : before.description,
      location:
        updates.location !== undefined
          ? updates.location.trim()
          : before.location,
    }

    events.value[index] = updated

    const authStore = useAuthStore()
    const auditStore = useAuditLogsStore()
    auditStore.addEntry({
      action: 'update',
      entityType: 'event',
      entityId: String(updated.id),
      description: `Updated event "${updated.title}"`,
      performedBy: authStore.user?.name ?? 'System',
    })
  }

  function softDeleteEvent(id: number) {
    const index = events.value.findIndex((event) => event.id === id)
    if (index === -1) return

    const item = events.value[index]
    if (item.isDeleted) return

    item.isDeleted = true

    const authStore = useAuthStore()
    const auditStore = useAuditLogsStore()
    auditStore.addEntry({
      action: 'delete',
      entityType: 'event',
      entityId: String(item.id),
      description: `Archived event "${item.title}"`,
      performedBy: authStore.user?.name ?? 'System',
    })
  }

  function restoreEvent(id: number) {
    const index = events.value.findIndex((event) => event.id === id)
    if (index === -1) return

    const item = events.value[index]
    if (!item.isDeleted) return

    item.isDeleted = false

    const authStore = useAuthStore()
    const auditStore = useAuditLogsStore()
    auditStore.addEntry({
      action: 'restore',
      entityType: 'event',
      entityId: String(item.id),
      description: `Restored event "${item.title}" from archive`,
      performedBy: authStore.user?.name ?? 'System',
    })
  }

  return {
    events,
    activeEvents,
    archivedEvents,
    createEvent,
    updateEvent,
    softDeleteEvent,
    restoreEvent,
  }
})

