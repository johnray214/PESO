import { defineStore } from 'pinia'
import api from '@/services/api'
import { useAuthStore } from '@/stores/auth'

export const useAdminAppStore = defineStore('adminApp', {
  state: () => ({
    applicantsCount: null,
    applicantsLoaded: false,
    notifications: [],
    notificationsLoaded: false,
  }),

  getters: {
    unreadCount: (state) => state.notifications.filter(n => !n.read).length,
  },

  actions: {
    // ── Applicants Count ─────────────────────────────────────────────────────
    async fetchApplicantsCount() {
      // Show cached value instantly while fresh data loads
      const cached = localStorage.getItem('reviewing_count')
      if (cached !== null) this.applicantsCount = Number(cached)

      try {
        const { data } = await api.get('/admin/applications/reviewing-count')
        this.applicantsCount = data.count ?? null
        localStorage.setItem('reviewing_count', this.applicantsCount)
        localStorage.setItem('reviewing_count_time', Date.now())
      } catch (e) {
        console.warn('[adminAppStore] Could not fetch reviewing count:', e?.message)
      } finally {
        this.applicantsLoaded = true
      }
    },

    async fetchNotifications() {
      // Show cached notifications instantly while fresh data loads
      const cached = localStorage.getItem('admin_notifications')
      if (cached !== null) {
        try { this.notifications = JSON.parse(cached) } catch { this.notifications = [] }
      }

      try {
        const { data } = await api.get('/admin/activity-feed')
        const list = data?.data ?? data ?? []
        
        const authStore = useAuthStore()
        const readKey = 'admin_read_notifs_' + (authStore.user?.id || 'guest')
        const readIds = JSON.parse(localStorage.getItem(readKey) || '[]')
        
        this.notifications = list.map((n, i) => {
          const id = n.id ?? i
          const isRead = n.read ?? n.is_read ?? false
          return {
            id,
            type:    n.type    ?? n.category ?? 'System',
            title:   n.title   ?? n.subject  ?? 'Notification',
            message: n.message ?? n.body     ?? '',
            time:    n.time    ?? (n.created_at ? formatRelative(n.created_at) : 'just now'),
            read:    isRead || readIds.includes(id),
          }
        })
        localStorage.setItem('admin_notifications', JSON.stringify(this.notifications))
        localStorage.setItem('admin_notifications_time', Date.now())
      } catch (e) {
        console.warn('[adminAppStore] Could not fetch activity feed:', e?.message)
      } finally {
        this.notificationsLoaded = true
      }
    },

    // ── Mark Read ─────────────────────────────────────────────────────────────
    markRead(notifId) {
      const n = this.notifications.find(x => x.id === notifId)
      if (n) {
        n.read = true
        const authStore = useAuthStore()
        const readKey = 'admin_read_notifs_' + (authStore.user?.id || 'guest')
        let readIds = JSON.parse(localStorage.getItem(readKey) || '[]')
        
        if (!readIds.includes(notifId)) {
          readIds.push(notifId)
          localStorage.setItem(readKey, JSON.stringify(readIds))
        }
        // update notifications cache
        localStorage.setItem('admin_notifications', JSON.stringify(this.notifications))
      }
      api.patch(`/admin/activity-feed/${notifId}/read`).catch(() => {})
    },

    // ── Mark All Read ─────────────────────────────────────────────────────────
    markAllRead() {
      const authStore = useAuthStore()
      const readKey = 'admin_read_notifs_' + (authStore.user?.id || 'guest')
      let readIds = JSON.parse(localStorage.getItem(readKey) || '[]')
      
      this.notifications.forEach(n => {
        n.read = true
        if (!readIds.includes(n.id)) readIds.push(n.id)
      })
      localStorage.setItem(readKey, JSON.stringify(readIds))
      // update notifications cache
      localStorage.setItem('admin_notifications', JSON.stringify(this.notifications))
      api.post('/admin/activity-feed/read-all').catch(() => {})
    },
  },
})

// ── Helpers ───────────────────────────────────────────────────────────────────
function formatRelative(dateStr) {
  if (!dateStr) return 'just now'
  const diff = Date.now() - new Date(dateStr).getTime()
  const m = Math.floor(diff / 60000)
  if (m < 1)  return 'just now'
  if (m < 60) return `${m}m ago`
  const h = Math.floor(m / 60)
  if (h < 24) return `${h}h ago`
  return `${Math.floor(h / 24)}d ago`
}