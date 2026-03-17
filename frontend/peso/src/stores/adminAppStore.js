import { defineStore } from 'pinia'
import api from '@/services/api'

export const useAdminAppStore = defineStore('adminApp', {
  state: () => ({
    // ── Applicants ───────────────────────────────────────────────────────────
    applicantsCount: null,   // null = not loaded yet
    applicantsLoaded: false,

    // ── Notifications ────────────────────────────────────────────────────────
    notifications: [],
    notificationsLoaded: false,
  }),

  getters: {
    unreadCount: (state) => state.notifications.filter(n => !n.read).length,
  },

  actions: {
    // ── Applicants count ─────────────────────────────────────────────────────
    async fetchApplicantsCount(force = false) {
      if (this.applicantsLoaded && !force) return
      try {
        const { data } = await api.get('/admin/jobseekers', { params: { page: 1, per_page: 1 } })
        // Backend usually wraps in data.data (paginated)
        const total = data?.data?.total ?? data?.total ?? data?.meta?.total ?? null
        if (total !== null) this.applicantsCount = total
      } catch (e) {
        console.warn('[adminAppStore] Could not fetch applicants count:', e?.message)
      } finally {
        this.applicantsLoaded = true
      }
    },

    // ── Notifications ─────────────────────────────────────────────────────────
    async fetchNotifications(force = false) {
      if (this.notificationsLoaded && !force) return
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
      } catch (e) {
        console.warn('[adminAppStore] Could not fetch activity feed:', e?.message)
      } finally {
        this.notificationsLoaded = true
      }
    },

    markRead(notifId) {
      const n = this.notifications.find(x => x.id === notifId)
      if (n) {
        n.read = true
        let readIds = JSON.parse(localStorage.getItem('admin_read_notifs') || '[]')
        if (!readIds.includes(notifId)) {
          readIds.push(notifId)
          localStorage.setItem('admin_read_notifs', JSON.stringify(readIds))
        }
      }
      api.patch(`/admin/activity-feed/${notifId}/read`).catch(() => {})
    },

    markAllRead() {
      let readIds = JSON.parse(localStorage.getItem('admin_read_notifs') || '[]')
      this.notifications.forEach(n => {
        n.read = true
        if (!readIds.includes(n.id)) readIds.push(n.id)
      })
      localStorage.setItem('admin_read_notifs', JSON.stringify(readIds))
      api.post('/admin/activity-feed/read-all').catch(() => {})
    },
  },
})

// ── Helpers ──────────────────────────────────────────────────────────────────
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
