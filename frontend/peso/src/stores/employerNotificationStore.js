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
    /** Load from API only if not yet loaded (cache-first). */
    async fetch() {
      if (this.loaded || this.loading) return
      await this._load()
    },

    /** Force reload from API (e.g. on page focus or manual refresh). */
    async refresh() {
      await this._load()
    },

    async _load() {
      this.loading = true
      try {
        const [notifRes, countRes] = await Promise.all([
          employerApi.getNotifications(),
          employerApi.getUnreadCount(),
        ])

        if (notifRes.data.success) {
          const raw = notifRes.data.data?.data || notifRes.data.data || []
          this.notifications = raw.map((n) => ({
            id:         n.id,
            type:       n.type || 'system',
            title:      n.title || 'Notification',
            message:    n.message || '',
            time:       this._formatTime(n.created_at),
            read:       !!n.read,
            created_at: n.created_at,
          }))
        }

        if (countRes.data.success) {
          this.unreadCount = countRes.data.data?.unread_count ?? 0
        }

        this.loaded = true
      } catch (e) {
        console.error('[NotificationStore] fetch error:', e)
      } finally {
        this.loading = false
      }
    },

    /** Mark a single notification as read. */
    async markRead(notification) {
      if (notification.read) return
      // Optimistic update
      const item = this.notifications.find((n) => n.id === notification.id)
      if (item) {
        item.read = true
        this.unreadCount = Math.max(0, this.unreadCount - 1)
      }
      try {
        await employerApi.markNotificationRead(notification.id)
      } catch (e) {
        // Rollback
        if (item) { item.read = false; this.unreadCount++ }
        console.error('[NotificationStore] markRead error:', e)
      }
    },

    /** Mark all notifications as read. */
    async markAllRead() {
      // Optimistic update
      const prevUnread = this.unreadCount
      this.notifications.forEach((n) => (n.read = true))
      this.unreadCount = 0
      try {
        await employerApi.markAllAsRead()
      } catch (e) {
        // Rollback
        this.unreadCount = prevUnread
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
