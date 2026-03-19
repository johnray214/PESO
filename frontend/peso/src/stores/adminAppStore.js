import { defineStore } from 'pinia'
import api from '@/services/api'

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
    async fetchApplicantsCount(force = false) {
      if (this.applicantsLoaded && !force) return

      const cached     = localStorage.getItem('reviewing_count')
      const cachedTime = localStorage.getItem('reviewing_count_time')
      if (cached !== null) this.applicantsCount = Number(cached)

      // ✅ skip API if cache is fresh
      const age = cachedTime ? Date.now() - Number(cachedTime) : Infinity
      if (age < 5 * 60 * 1000 && cached !== null) {
        this.applicantsLoaded = true
        return
      }

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

    async fetchNotifications(force = false) {
      if (this.notificationsLoaded && !force) return

      const cached     = localStorage.getItem('admin_notifications')
      const cachedTime = localStorage.getItem('admin_notifications_time')
      if (cached !== null) {
        try { this.notifications = JSON.parse(cached) } catch { this.notifications = [] }
      }

      // ✅ skip API if cache is fresh
      const age = cachedTime ? Date.now() - Number(cachedTime) : Infinity
      if (age < 5 * 60 * 1000 && cached !== null) {
        this.notificationsLoaded = true
        return
      }

      try {
        const { data } = await api.get('/admin/activity-feed')
        const list = data?.data ?? data ?? []
        const readIds = JSON.parse(localStorage.getItem('admin_read_notifs') || '[]')
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
        let readIds = JSON.parse(localStorage.getItem('admin_read_notifs') || '[]')
        if (!readIds.includes(notifId)) {
          readIds.push(notifId)
          localStorage.setItem('admin_read_notifs', JSON.stringify(readIds))
        }
        // update notifications cache
        localStorage.setItem('admin_notifications', JSON.stringify(this.notifications))
      }
      api.patch(`/admin/activity-feed/${notifId}/read`).catch(() => {})
    },

    // ── Mark All Read ─────────────────────────────────────────────────────────
    markAllRead() {
      let readIds = JSON.parse(localStorage.getItem('admin_read_notifs') || '[]')
      this.notifications.forEach(n => {
        n.read = true
        if (!readIds.includes(n.id)) readIds.push(n.id)
      })
      localStorage.setItem('admin_read_notifs', JSON.stringify(readIds))
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