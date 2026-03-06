import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { useAuthStore } from './auth'
import { useAuditLogsStore } from './auditLogs'

export type NotificationTarget = 'applicants' | 'employers' | 'all'

export interface NotificationItem {
  id: number
  title: string
  message: string
  target: NotificationTarget
  createdAt: string
}

export const useNotificationsStore = defineStore('notifications', () => {
  const notifications = ref<NotificationItem[]>([])

  const total = computed(() => notifications.value.length)

  function sendNotification(title: string, message: string, target: NotificationTarget) {
    const now = new Date()
    const item: NotificationItem = {
      id: now.getTime(),
      title: title.trim(),
      message: message.trim(),
      target,
      createdAt: now.toISOString(),
    }

    notifications.value.push(item)

    const authStore = useAuthStore()
    const auditStore = useAuditLogsStore()
    auditStore.addEntry({
      action: 'send-notification',
      entityType: 'notification',
      entityId: String(item.id),
      description: `Sent notification "${item.title}" to ${target}`,
      performedBy: authStore.user?.name ?? 'System',
    })
  }

  function clearAll() {
    notifications.value = []
  }

  return {
    notifications,
    total,
    sendNotification,
    clearAll,
  }
})

