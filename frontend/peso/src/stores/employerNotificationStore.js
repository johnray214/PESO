import { defineStore } from 'pinia'
import employerApi from '@/services/employerApi'

export const useEmployerNotificationStore = defineStore('employerNotifications', {
  state: () => ({
    notifications: [],
    unreadCount: 0,
    loaded: false,
    loading: false,
  }),

  getters: {
    recentNotifs: (state) => state.notifications.slice(0, 5),
    hasUnread: (state) => state.unreadCount > 0,
  },

  actions: {
    async fetch() {
      if (this.loading) return

      // Show cached notifications instantly while fresh data loads in background
      const cachedNotifs = localStorage.getItem('employer_notifications')
      const cachedCount  = localStorage.getItem('employer_unread_count')
      if (cachedNotifs) {
        try { this.notifications = JSON.parse(cachedNotifs) } catch { this.notifications = [] }
      }
      if (cachedCount !== null) this.unreadCount = Number(cachedCount)

      // Always fetch fresh from backend
      await this._load()
    },

    async refresh() {
      await this._load()
    },

    async _load() {
      this.loading = true

      // load from cache first so notifications show instantly on reload
      const cachedNotifs = localStorage.getItem('employer_notifications')
      const cachedCount  = localStorage.getItem('employer_unread_count')
      if (cachedNotifs) {
        try { this.notifications = JSON.parse(cachedNotifs) } catch { this.notifications = [] }
      }
      if (cachedCount !== null) this.unreadCount = Number(cachedCount)

      try {
        const [notifRes, countRes] = await Promise.all([
          employerApi.getNotifications(),
          employerApi.getUnreadCount(),
        ])

        if (notifRes.data.success) {
          const raw = notifRes.data.data?.data || notifRes.data.data || []
          this.notifications = raw.map((n) => ({
            id:         n.id,
            type:       n.type    || 'system',
            title:      n.title   || 'Notification',
            message:    n.message || '',
            time:       this._formatTime(n.created_at),
            read:       !!n.read,
            created_at: n.created_at,
          }))
          // save to cache
          localStorage.setItem('employer_notifications_time', Date.now())
        }

        if (countRes.data.success) {
          this.unreadCount = countRes.data.data?.unread_count ?? 0
          localStorage.setItem('employer_unread_count', this.unreadCount)
        }

        this.loaded = true
      } catch (e) {
        console.error('[NotificationStore] fetch error:', e)
      } finally {
        this.loading = false
      }
    },

    async markRead(notification) {
      if (notification.read) return
      const item = this.notifications.find((n) => n.id === notification.id)
      if (item) {
        item.read = true
        this.unreadCount = Math.max(0, this.unreadCount - 1)
        localStorage.setItem('employer_notifications', JSON.stringify(this.notifications))
        localStorage.setItem('employer_unread_count', this.unreadCount)
      }
      try {
        await employerApi.markNotificationRead(notification.id)
      } catch (e) {
        if (item) { item.read = false; this.unreadCount++ }
        localStorage.setItem('employer_notifications', JSON.stringify(this.notifications))
        localStorage.setItem('employer_unread_count', this.unreadCount)
        console.error('[NotificationStore] markRead error:', e)
      }
    },

    async markAllRead() {
      const prevUnread = this.unreadCount
      this.notifications.forEach((n) => (n.read = true))
      this.unreadCount = 0
      localStorage.setItem('employer_notifications', JSON.stringify(this.notifications))
      localStorage.setItem('employer_unread_count', 0)
      try {
        await employerApi.markAllAsRead()
      } catch (e) {
        this.unreadCount = prevUnread
        localStorage.setItem('employer_unread_count', prevUnread)
        console.error('[NotificationStore] markAllRead error:', e)
      }
    },

    _formatTime(dateString) {
      if (!dateString) return ''
      const date = new Date(dateString)
      const diff = (Date.now() - date.getTime()) / 1000
      if (diff < 60)     return 'Just now'
      if (diff < 3600)   return `${Math.floor(diff / 60)} min ago`
      if (diff < 86400)  return `${Math.floor(diff / 3600)} hours ago`
      if (diff < 604800) return `${Math.floor(diff / 86400)} days ago`
      return date.toLocaleDateString()
    },
  },
})