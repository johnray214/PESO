import { defineStore } from 'pinia'
import api from '@/services/api'
import { getEcho } from '@/services/echo'

export const useAdminAppStore = defineStore('adminApp', {
  state: () => ({
    applicantsCount: null,
    applicantsLoaded: false,
    notifications: [],
    notificationsLoaded: false,
    _pusherListening: false,
  }),

  getters: {
    unreadCount: (state) => state.notifications.filter(n => !n.read).length,
  },

  actions: {
    // ── Applicants Count ─────────────────────────────────────────────────────
    async fetchApplicantsCount() {
      if (this.applicantsLoaded) return

      try {
        const { data } = await api.get('/admin/applications/reviewing-count')
        this.applicantsCount = data.count ?? null
      } catch (e) {
        console.warn('[adminAppStore] Could not fetch reviewing count:', e?.message)
      } finally {
        this.applicantsLoaded = true
      }
    },

    // ── Database-Backed Notifications Fetch ──────────────────────────────────
    async fetchNotifications(forceRefresh = false) {
      if (this.notificationsLoaded && !forceRefresh) return

      try {
        const { data } = await api.get('/admin/activity-feed')
        const list = data?.data ?? data ?? []

        this.notifications = list.map((n, i) => ({
          id:      n.id ?? i,
          type:    n.type    ?? n.category ?? 'System',
          title:   n.title   ?? n.subject  ?? 'Notification',
          message: n.message ?? n.body     ?? '',
          time:    n.time    ?? 'just now',
          read:    !!n.read,
        }))
      } catch (e) {
        console.warn('[adminAppStore] Could not fetch activity feed:', e?.message)
      } finally {
        this.notificationsLoaded = true
      }

      this._listenPusher()
    },

    // ── Real-time Pusher Listener ─────────────────────────────────────────────
    _listenPusher() {
      if (this._pusherListening) return
      this._pusherListening = true

      try {
        const echo = getEcho()
        echo.channel('admin-feed').listen('.AdminActivityEvent', (payload) => {
          this.notifications.unshift({
            id:      payload.id,
            type:    payload.type    ?? 'System',
            title:   payload.title   ?? 'Notification',
            message: payload.message ?? '',
            time:    'just now',
            read:    false,
          })

          if (payload.type === 'Status' && payload.title === 'New Application' && this.applicantsCount !== null) {
            this.applicantsCount++
          }
        })
      } catch (e) {
        console.warn('[adminAppStore] Pusher listen error:', e?.message)
      }
    },

    // ── Mark Read ─────────────────────────────────────────────────────────────
    async markRead(notifId) {
      const n = this.notifications.find(x => x.id === notifId)
      if (n) {
        n.read = true
      }
      try {
        await api.patch(`/admin/activity-feed/${notifId}/read`)
      } catch (e) {
        console.warn('[adminAppStore] markRead failed:', e?.message)
      }
    },

    // ── Mark All Read ─────────────────────────────────────────────────────────
    async markAllRead() {
      const unreadIds = this.notifications.filter(n => !n.read).map(n => n.id)
      this.notifications.forEach(n => { n.read = true })
      try {
        await api.post('/admin/activity-feed/read-all', { ids: unreadIds })
      } catch (e) {
        console.warn('[adminAppStore] markAllRead failed:', e?.message)
      }
    },

    // ── Delete single ─────────────────────────────────────────────────────────
    async deleteNotif(notifId) {
      this.notifications = this.notifications.filter(n => n.id !== notifId)
      try {
        await api.delete(`/admin/activity-feed/${notifId}`)
      } catch (e) {
        console.warn('[adminAppStore] deleteNotif failed:', e?.message)
      }
    },

    // ── Delete all read ───────────────────────────────────────────────────────
    async deleteAll() {
      const readIds = this.notifications.filter(n => n.read).map(n => n.id)
      this.notifications = this.notifications.filter(n => !n.read)
      try {
        await api.post('/admin/activity-feed/clear-read', { ids: readIds })
      } catch (e) {
        console.warn('[adminAppStore] deleteAll failed:', e?.message)
      }
    },
  },
})