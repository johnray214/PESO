<template>
  <div class="page">

    <!-- SKELETON -->
    <template v-if="loading">
      <div class="page-header">
        <div class="skel" style="width:180px;height:22px;border-radius:8px;"></div>
        <div style="display:flex;gap:8px;">
          <div class="skel" style="width:120px;height:36px;border-radius:10px;"></div>
          <div class="skel" style="width:140px;height:36px;border-radius:10px;"></div>
        </div>
      </div>
      <div class="notif-card">
        <div v-for="i in 7" :key="i" style="display:flex;align-items:flex-start;gap:12px;padding:16px 18px;border-bottom:1px solid #f8fafc;">
          <div class="skel" style="width:38px;height:38px;border-radius:10px;flex-shrink:0;"></div>
          <div style="flex:1;display:flex;flex-direction:column;gap:8px;">
            <div style="display:flex;justify-content:space-between;">
              <div class="skel" style="width:55%;height:14px;border-radius:6px;"></div>
              <div class="skel" style="width:60px;height:12px;border-radius:6px;"></div>
            </div>
            <div class="skel" style="width:85%;height:12px;border-radius:6px;"></div>
            <div class="skel" style="width:60px;height:18px;border-radius:6px;"></div>
          </div>
        </div>
      </div>
    </template>

    <!-- ACTUAL CONTENT -->
    <template v-else>

      <!-- Header -->
      <div class="page-header">
        <div>
          <h2 class="page-title">Notifications</h2>
          <p class="page-sub">{{ store.notifications.length }} total · {{ store.unreadCount }} unread</p>
        </div>
        <div style="display:flex;gap:8px;align-items:center;">
          <button class="btn-mark-all" @click="store.markAllRead()" :disabled="store.unreadCount === 0">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
            Mark all read
          </button>
          <button class="btn-delete-all" @click="showDeleteConfirm = true" :disabled="store.notifications.length === 0">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg>
            Clear all
          </button>
        </div>
      </div>

      <!-- Filter tabs -->
      <div class="filter-tabs">
        <button :class="['ftab', { active: activeFilter === 'all' }]" @click="activeFilter = 'all'">
          All <span class="ftab-count">{{ store.notifications.length }}</span>
        </button>
        <button :class="['ftab', { active: activeFilter === 'unread' }]" @click="activeFilter = 'unread'">
          Unread <span class="ftab-count unread-c">{{ store.unreadCount }}</span>
        </button>
      </div>

      <!-- Notifications list -->
      <div class="notif-card">
        <div v-if="filtered.length === 0" class="notif-empty">
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.5"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>
          <p>{{ activeFilter === 'unread' ? 'No unread notifications' : 'No notifications yet' }}</p>
        </div>

        <div
          v-for="notif in filtered"
          :key="notif.id"
          :class="['notif-item', { unread: !notif.read, clickable: !notif.read }]"
          @click="handleClick(notif)"
        >
          <!-- Icon -->
          <div class="notif-icon-wrap" :style="{ background: typeColor(notif.type).bg }">
            <span v-html="typeIcon(notif.type)" :style="{ color: typeColor(notif.type).text }"></span>
          </div>

          <!-- Content -->
          <div class="notif-content">
            <div class="notif-top">
              <h4 class="notif-title">{{ notif.title }}</h4>
              <span class="notif-time">{{ notif.time }}</span>
            </div>
            <p class="notif-message">{{ notif.message }}</p>
            <div style="display:flex;align-items:center;gap:8px;margin-top:4px;">
              <span class="notif-type-tag" :style="{ background: typeColor(notif.type).bg, color: typeColor(notif.type).text }">
                {{ notif.type }}
              </span>
              <span v-if="!notif.read" class="read-hint">Click to navigate</span>
              <span v-else class="read-badge">Read</span>
            </div>
          </div>

          <!-- Right side actions -->
          <div class="notif-actions" @click.stop>
            <!-- Unread dot: click to mark read -->
            <span
              v-if="!notif.read"
              class="unread-dot"
              @click.stop="store.markRead(notif.id)"
              title="Mark as read"
            ></span>
            <!-- Delete button: only show if read -->
            <button v-if="notif.read" class="btn-del-item" @click.stop="promptDeleteSingle(notif)" title="Delete">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/></svg>
            </button>
          </div>
        </div>
      </div>
    </template>

    <!-- DELETE ALL CONFIRM MODAL -->
    <transition name="modal-pop">
      <div v-if="showDeleteConfirm" class="modal-overlay" @click.self="showDeleteConfirm = false">
        <div class="confirm-modal">
          <div class="confirm-icon">
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg>
          </div>
          <h3 class="confirm-title">Clear all read notifications?</h3>
          <p class="confirm-desc">This will permanently remove all read notifications from the feed. Unread notifications will be kept.</p>
          <div class="confirm-btns">
            <button class="confirm-cancel" @click="showDeleteConfirm = false">Cancel</button>
            <button class="confirm-ok" @click="confirmDeleteAll">Clear All</button>
          </div>
        </div>
      </div>
    </transition>

    <!-- DELETE SINGLE CONFIRM MODAL -->
    <transition name="modal-pop">
      <div v-if="showDeleteSingleConfirm" class="modal-overlay" @click.self="showDeleteSingleConfirm = false">
        <div class="confirm-modal">
          <div class="confirm-icon">
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg>
          </div>
          <h3 class="confirm-title">Delete this notification?</h3>
          <p class="confirm-desc">This will permanently remove the notification from your feed. This cannot be undone.</p>
          <div class="confirm-btns">
            <button class="confirm-cancel" @click="showDeleteSingleConfirm = false">Cancel</button>
            <button class="confirm-ok" @click="confirmDeleteSingle">Delete</button>
          </div>
        </div>
      </div>
    </transition>

  </div>
</template>

<script>
import { useAdminAppStore } from '@/stores/adminAppStore'
import { useRouter } from 'vue-router'

export default {
  name: 'NotificationsPage',

  async mounted() {
    this.store = useAdminAppStore()
    this.router = useRouter()
    await this.store.fetchNotifications(true)
    this.loading = false
  },

  data() {
    return {
      loading: true,
      activeFilter: 'all',
      showDeleteConfirm: false,
      showDeleteSingleConfirm: false,
      singleDeleteTargetId: null,
      store: null,
      router: null,
    }
  },

  computed: {
    filtered() {
      if (!this.store) return []
      if (this.activeFilter === 'unread') return this.store.notifications.filter(n => !n.read)
      return this.store.notifications
    },
  },

  methods: {
    handleClick(notif) {
      // Only navigate if the notification is unread
      if (notif.read) return

      this.store.markRead(notif.id)

      const type  = (notif.type  || '').toLowerCase()
      const title = (notif.title || '').toLowerCase()

      if (type === 'registration' || title.includes('jobseeker') || title.includes('registered')) {
        this.router.push('/dashboard/jobseekers')
      } else if (title.includes('application') || title.includes('applied') || type === 'status') {
        this.router.push('/dashboard/applicants')
      } else if (type === 'event' || title.includes('event')) {
        this.router.push('/dashboard/events')
      } else if (title.includes('job') || title.includes('listing') || type === 'match') {
        this.router.push('/dashboard/joblisting')
      } else if (title.includes('employer')) {
        this.router.push('/dashboard/employers')
      }
      // read notifications: don't navigate, just stay
    },

    confirmDeleteAll() {
      // Direct assignment instead of method call in case Pinia actions didn't HMR properly
      if (typeof this.store.deleteAll === 'function') {
        this.store.deleteAll()
      } else {
        try {
          const authUser = JSON.parse(localStorage.getItem('admin_user') || '{}')
          const delKey = 'admin_del_notifs_' + (authUser?.id || 'guest')
          const delIds = JSON.parse(localStorage.getItem(delKey) || '[]')
          
          const unreadNotifs = []
          this.store.notifications.forEach(n => {
            if (n.read) {
              if (!delIds.includes(n.id)) delIds.push(n.id)
            } else {
              unreadNotifs.push(n)
            }
          })
          localStorage.setItem(delKey, JSON.stringify(delIds))
          
          this.store.notifications = unreadNotifs
          localStorage.setItem('admin_notifications', JSON.stringify(unreadNotifs))
        } catch(e) {
          console.warn('Delete persistence error:', e)
        }
      }
      this.showDeleteConfirm = false
    },

    promptDeleteSingle(notif) {
      this.singleDeleteTargetId = notif.id
      this.showDeleteSingleConfirm = true
    },

    confirmDeleteSingle() {
      if (typeof this.store.deleteNotif === 'function') {
        this.store.deleteNotif(this.singleDeleteTargetId)
      } else {
        this.store.notifications = this.store.notifications.filter(n => n.id !== this.singleDeleteTargetId)
        localStorage.setItem('admin_notifications', JSON.stringify(this.store.notifications))
        
        // Also persist the deletion manually in case store wasn't updated
        try {
          const authUser = JSON.parse(localStorage.getItem('admin_user') || '{}')
          const delKey = 'admin_del_notifs_' + (authUser?.id || 'guest')
          const delIds = JSON.parse(localStorage.getItem(delKey) || '[]')
          if (!delIds.includes(this.singleDeleteTargetId)) {
            delIds.push(this.singleDeleteTargetId)
            localStorage.setItem(delKey, JSON.stringify(delIds))
          }
        } catch(e) {
          console.warn('Delete persistence error:', e)
        }
      }
      this.showDeleteSingleConfirm = false
      this.singleDeleteTargetId = null
    },

    typeIcon(type) {
      const t = (type || '').toLowerCase()
      const icons = {
        'job':          `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2" ry="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg>`,
        'match':        `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>`,
        'registration': `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><line x1="20" y1="8" x2="20" y2="14"/><line x1="23" y1="11" x2="17" y2="11"/></svg>`,
        'event':        `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>`,
        'status':       `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>`,
        'system':       `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>`,
      }
      return icons[t] || icons['system']
    },

    typeColor(type) {
      const t = (type || '').toLowerCase()
      const colors = {
        'job':          { bg: '#f0fdf4', text: '#22c55e' },
        'match':        { bg: '#dcfce7', text: '#22c55e' },
        'registration': { bg: '#dbeafe', text: '#2563eb' },
        'event':        { bg: '#fff7ed', text: '#f97316' },
        'status':       { bg: '#fdf4ff', text: '#a21caf' },
        'system':       { bg: '#f1f5f9', text: '#64748b' },
      }
      return colors[t] || colors['system']
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

@keyframes shimmer { 0% { background-position: -400px 0; } 100% { background-position: 400px 0; } }
.skel {
  background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%);
  background-size: 400px 100%; animation: shimmer 1.4s infinite linear;
  border-radius: 6px; flex-shrink: 0;
}

.page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  padding: 24px; background: #f8fafc;
  min-height: 100vh; display: flex; flex-direction: column; gap: 16px;
}

/* HEADER */
.page-header { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px; }
.page-title  { font-size: 20px; font-weight: 800; color: #1e293b; }
.page-sub    { font-size: 12px; color: #94a3b8; margin-top: 3px; }

.btn-mark-all {
  display: flex; align-items: center; gap: 7px;
  background: #fff; border: 1.5px solid #e2e8f0; border-radius: 10px;
  padding: 8px 14px; font-size: 12.5px; font-weight: 600; color: #2563eb;
  cursor: pointer; font-family: inherit; transition: all 0.15s;
}
.btn-mark-all:hover:not(:disabled) { background: #eff6ff; border-color: #93c5fd; }
.btn-mark-all:disabled { opacity: 0.45; cursor: not-allowed; }

.btn-delete-all {
  display: flex; align-items: center; gap: 7px;
  background: #fff; border: 1.5px solid #fecaca; border-radius: 10px;
  padding: 8px 14px; font-size: 12.5px; font-weight: 600; color: #ef4444;
  cursor: pointer; font-family: inherit; transition: all 0.15s;
}
.btn-delete-all:hover:not(:disabled) { background: #fef2f2; border-color: #ef4444; }
.btn-delete-all:disabled { opacity: 0.4; cursor: not-allowed; }

/* FILTER TABS */
.filter-tabs { display: flex; gap: 6px; }
.ftab {
  display: flex; align-items: center; gap: 7px;
  background: #fff; border: 1.5px solid #e2e8f0; border-radius: 9px;
  padding: 7px 14px; font-size: 12.5px; font-weight: 600; color: #64748b;
  cursor: pointer; font-family: inherit; transition: all 0.15s;
}
.ftab:hover { border-color: #94a3b8; color: #1e293b; }
.ftab.active { background: #eff6ff; border-color: #2563eb; color: #2563eb; }
.ftab-count { font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }
.unread-c   { background: #dbeafe; color: #2563eb; }

/* NOTIFICATION CARD */
.notif-card { background: #fff; border: 1px solid #e2e8f0; border-radius: 14px; overflow: hidden; box-shadow: 0 2px 12px rgba(0,0,0,0.05); }

.notif-item {
  display: flex; align-items: flex-start; gap: 12px;
  padding: 16px 18px; transition: background 0.15s;
  position: relative; border-bottom: 1px solid #f8fafc;
}
.notif-item:last-child { border-bottom: none; }
.notif-item:hover { background: #f8fafc; }
.notif-item.unread { background: #eff6ff; }
.notif-item.unread:hover { background: #dbeafe; }
.notif-item.clickable { cursor: pointer; }
.notif-item:not(.clickable) { cursor: default; }

.notif-icon-wrap { width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }

.notif-content { flex: 1; min-width: 0; }
.notif-top { display: flex; align-items: flex-start; justify-content: space-between; gap: 8px; margin-bottom: 4px; }
.notif-title   { font-size: 13px; font-weight: 700; color: #1e293b; line-height: 1.3; margin: 0; }
.notif-time    { font-size: 11px; color: #94a3b8; white-space: nowrap; flex-shrink: 0; }
.notif-message { font-size: 12px; color: #64748b; line-height: 1.5; margin: 0 0 2px 0; }
.notif-type-tag { display: inline-block; font-size: 10px; font-weight: 600; padding: 3px 8px; border-radius: 6px; text-transform: capitalize; }
.read-hint  { font-size: 10px; color: #2563eb; font-weight: 500; }
.read-badge { font-size: 10px; color: #94a3b8; font-weight: 500; }

/* Right-side actions */
.notif-actions { display: flex; align-items: center; gap: 6px; flex-shrink: 0; margin-top: 2px; }

.unread-dot {
  width: 9px; height: 9px; border-radius: 50%; background: #2563eb; flex-shrink: 0;
  cursor: pointer; transition: transform 0.15s;
}
.unread-dot:hover { transform: scale(1.4); }

.btn-del-item {
  width: 26px; height: 26px; border-radius: 7px; border: 1px solid #f1f5f9;
  background: #fff; color: #cbd5e1; display: flex; align-items: center;
  justify-content: center; cursor: pointer; transition: all 0.15s; flex-shrink: 0;
}
.btn-del-item:hover { background: #fef2f2; border-color: #fecaca; color: #ef4444; }

.notif-empty { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 52px 24px; gap: 12px; color: #94a3b8; font-size: 13px; font-weight: 500; }

/* CONFIRM MODAL */
.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.45); z-index: 200; display: flex; align-items: center; justify-content: center; padding: 24px; backdrop-filter: blur(3px); }
.confirm-modal { background: #fff; border-radius: 20px; width: 100%; max-width: 380px; padding: 32px 28px 24px; box-shadow: 0 24px 64px rgba(0,0,0,0.2); display: flex; flex-direction: column; align-items: center; text-align: center; gap: 12px; }
.confirm-icon  { width: 58px; height: 58px; border-radius: 50%; background: #fef2f2; border: 2px solid #fecaca; display: flex; align-items: center; justify-content: center; }
.confirm-title { font-size: 16px; font-weight: 800; color: #1e293b; }
.confirm-desc  { font-size: 13px; color: #64748b; line-height: 1.6; max-width: 300px; }
.confirm-btns  { display: flex; gap: 10px; width: 100%; margin-top: 6px; }
.confirm-cancel { flex: 1; padding: 10px; border-radius: 10px; border: 1.5px solid #e2e8f0; background: #fff; font-size: 13px; font-weight: 600; color: #64748b; cursor: pointer; font-family: inherit; }
.confirm-cancel:hover { background: #f8fafc; }
.confirm-ok { flex: 1.5; padding: 10px; border-radius: 10px; border: none; background: linear-gradient(135deg,#ef4444,#dc2626); font-size: 13px; font-weight: 700; color: #fff; cursor: pointer; font-family: inherit; }
.confirm-ok:hover { filter: brightness(1.08); }

.modal-pop-enter-active { transition: all 0.22s cubic-bezier(0.34,1.56,0.64,1); }
.modal-pop-leave-active { transition: all 0.15s ease-in; }
.modal-pop-enter-from, .modal-pop-leave-to { opacity: 0; transform: scale(0.9); }
</style>
