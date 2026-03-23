<template>
  <div class="dashboard-wrapper">
    <AppSidebar @logout="handleLogout" />
    <div class="main">

      <!-- TOPBAR SKELETON -->
      <header v-if="topbarLoading" class="topbar">
        <div class="topbar-left">
          <div class="skel" style="width:140px;height:18px;border-radius:6px;margin-bottom:6px"></div>
          <div class="skel" style="width:100px;height:12px;border-radius:6px"></div>
        </div>
        <div class="topbar-right">
          <div class="skel" style="width:140px;height:38px;border-radius:10px"></div>
          <div class="skel" style="width:110px;height:38px;border-radius:99px"></div>
        </div>
      </header>

      <!-- ACTUAL TOPBAR -->
      <header v-else class="topbar">
        <div class="topbar-left">
          <h1 class="page-title">{{ pageTitle }}</h1>
          <span class="page-sub">{{ pageSubtitle }}</span>
        </div>
        <div class="topbar-right">
          <div class="notif-wrapper">
            <button class="notif-card" @click="showNotifications = !showNotifications">
              <div class="notif-icon-wrap">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9" />
                  <path d="M13.73 21a2 2 0 01-3.46 0" />
                </svg>
                <span class="notif-badge">{{ appStore.unreadCount }}</span>
              </div>
              <div class="notif-text">
                <span class="notif-label">Notifications</span>
                <span class="notif-count">{{ appStore.unreadCount }} new</span>
              </div>
            </button>
            <transition name="dropdown">
              <div v-if="showNotifications" class="notif-dropdown">
                <div class="notif-dropdown-header">
                  <h3 class="notif-dropdown-title">Notifications</h3>
                  <button class="mark-all-btn" @click="appStore.markAllRead()">Mark all as read</button>
                </div>
                <div class="notif-dropdown-list">
                  <div v-if="appStore.notifications.length === 0" class="notif-empty">
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.5"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>
                    <p>No notifications yet</p>
                  </div>
                  <div v-for="notif in appStore.notifications" :key="notif.id"
                    :class="['notif-item', { unread: !notif.read }]"
                    @click="appStore.markRead(notif.id)">
                    <div class="notif-icon-wrap" :style="{ background: notifTypeColor(notif.type).bg }">
                      <span v-html="notifTypeIcon(notif.type)" :style="{ color: notifTypeColor(notif.type).text }"></span>
                    </div>
                    <div class="notif-content">
                      <div class="notif-top">
                        <h4 class="notif-title">{{ notif.title }}</h4>
                        <span class="notif-time">{{ notif.time }}</span>
                      </div>
                      <p class="notif-message">{{ notif.message }}</p>
                      <span class="notif-type-tag" :style="{ background: notifTypeColor(notif.type).bg, color: notifTypeColor(notif.type).text }">{{ notif.type }}</span>
                    </div>
                    <span v-if="!notif.read" class="unread-dot"></span>
                  </div>
                </div>
                <router-link to="/dashboard/notifications" class="view-all-btn" @click="showNotifications = false">
                  View all notifications
                </router-link>
              </div>
            </transition>
          </div>
          <div class="user-wrapper">
            <div class="user-pill" @click="showUserMenu = !showUserMenu">
              <div class="avatar">
                <img v-if="authStore.photo" :src="authStore.photo" class="avatar-photo" alt="profile"/>
                <span v-else>{{ userInitial }}</span>
              </div>
              <div class="user-meta">
                <span class="user-name">{{ userName }}</span>
                <span class="user-role">{{ userRole }}</span>
              </div>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="6 9 12 15 18 9"/>
              </svg>
            </div>
            <transition name="dropdown">
              <div v-if="showUserMenu" class="user-dropdown">
                <button class="dropdown-item logout" @click="handleLogout" :disabled="loggingOut">
                  <span v-if="loggingOut" class="spinner-sm"></span>
                  <svg v-else width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/>
                    <polyline points="16 17 21 12 16 7"/>
                    <line x1="21" y1="12" x2="9" y2="12"/>
                  </svg>
                  {{ loggingOut ? 'Logging out...' : 'Logout' }}
                </button>
              </div>
            </transition>
          </div>
        </div>
      </header>

      <!-- Main scrollable content -->
      <div class="main-scroll">
        <router-view />
      </div>
    </div>

    <div v-if="showUserMenu || showNotifications" class="dropdown-overlay" @click="showUserMenu = false; showNotifications = false"></div>
  </div>
</template>

<script>
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useAdminAppStore } from '@/stores/adminAppStore'
import AppSidebar from '@/components/AppSidebar.vue'

export default {
  name: 'DashboardLayout',
  components: { AppSidebar },
  setup() {
    const route     = useRoute()
    const authStore = useAuthStore()
    const appStore  = useAdminAppStore()

    const loggingOut = ref(false)

    async function handleLogout() {
      if (loggingOut.value) return
      loggingOut.value = true
      await authStore.logout()
      window.location.href = '/admin/login'  // ✅ force full reload to wipe cache
    }

    const pageTitle = computed(() => {
      const name = route.name || 'Dashboard'
      const base = String(name).replace(/-/g, ' ')
      return base.split(' ').filter(Boolean).map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ')
    })

    const pageSubtitle = computed(() => route.meta.subtitle || 'Welcome back 👋')

    const userName = computed(() => {
      const u = authStore.user
      if (!u) return 'Admin'
      return u.first_name ? `${u.first_name} ${u.last_name || ''}`.trim() : u.name || 'Admin'
    })

    const userInitial = computed(() => (userName.value[0] || 'A').toUpperCase())

    const userRole = computed(() => {
      const r = authStore.role
      if (!r) return 'PESO Staff'
      return r.charAt(0).toUpperCase() + r.slice(1)
    })

    return { handleLogout, pageTitle, pageSubtitle, authStore, appStore, userName, userInitial, userRole, loggingOut }
  },

  data() {
    return {
      topbarLoading: true,  // ✅ skeleton flag
      showUserMenu: false,
      showNotifications: false,
    }
  },

  async mounted() {
    // ✅ always show skeleton first
    await this.$nextTick()

    // fetch notifications and count in parallel
    await Promise.all([
      this.appStore.fetchNotifications(),
      this.appStore.fetchApplicantsCount(),
    ])

    // ✅ minimum skeleton visibility
    setTimeout(() => {
      this.topbarLoading = false
    }, 600)
  },

  computed: {
    unreadCount()   { return this.appStore.unreadCount },
    notifications() { return this.appStore.notifications },
  },

  methods: {
    markAsRead(notif)  { this.appStore.markRead(notif.id) },
    markAllRead()      { this.appStore.markAllRead() },
    notifTypeIcon(type) {
      const typeKey = (type || '').toLowerCase()
      const icons = {
        'match':        `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>`,
        'registration': `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><line x1="20" y1="8" x2="20" y2="14"/><line x1="23" y1="11" x2="17" y2="11"/></svg>`,
        'event':        `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>`,
        'status':       `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>`,
        'system':       `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>`,
      }
      return icons[typeKey] || icons['system']
    },
    notifTypeColor(type) {
      const typeKey = (type || '').toLowerCase()
      const colors = {
        'match':        { bg: '#dcfce7', text: '#22c55e' },
        'registration': { bg: '#dbeafe', text: '#2563eb' },
        'event':        { bg: '#fff7ed', text: '#f97316' },
        'status':       { bg: '#fdf4ff', text: '#a21caf' },
        'system':       { bg: '#f1f5f9', text: '#64748b' },
      }
      return colors[typeKey] || colors['system']
    },
  },
}
</script>

<style scoped>
/* ── SKELETON ───────────────────────────────────────────────────────────── */
@keyframes shimmer {
  0%   { background-position: -400px 0; }
  100% { background-position:  400px 0; }
}
.skel {
  background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%);
  background-size: 400px 100%;
  animation: shimmer 1.4s infinite linear;
  border-radius: 6px;
  flex-shrink: 0;
}

.spinner-sm {
  width: 14px; height: 14px;
  border: 2px solid rgba(239, 68, 68, 0.3); border-top-color: #ef4444;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  flex-shrink: 0;
}
@keyframes spin { 100% { transform: rotate(360deg); } }

.dashboard-wrapper {
  display: flex; height: 100vh; overflow: hidden;
  font-family: 'Plus Jakarta Sans', sans-serif;
}
.main {
  flex: 1; min-width: 0; display: flex;
  flex-direction: column; background: #f1eeff;
}
.main-scroll {
  flex: 1; overflow-y: auto; overflow-x: hidden;
  -webkit-overflow-scrolling: touch;
}

/* TOPBAR */
.topbar {
  background: #fff; padding: 14px 24px;
  display: flex; align-items: center; justify-content: space-between;
  border-bottom: 1px solid #f1f5f9;
}
.topbar-left  { display: flex; flex-direction: column; }
.topbar-right { display: flex; align-items: center; gap: 12px; }
.page-title   { font-size: 18px; font-weight: 800; color: #1e293b; line-height: 1.1; }
.page-sub     { font-size: 12px; color: #94a3b8; margin-top: 2px; }

.icon-btn { background: none; border: none; cursor: pointer; color: #64748b; display: flex; align-items: center; padding: 7px; border-radius: 8px; position: relative; }
.icon-btn:hover { background: #f1f5f9; }

.notif-wrapper { position: relative; }
.notif-card { display: flex; align-items: center; gap: 10px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 14px; cursor: pointer; transition: all 0.15s; font-family: inherit; }
.notif-card:hover { background: #eff6ff; border-color: #2563eb; }
.notif-icon-wrap { position: relative; display: flex; align-items: center; color: #64748b; }
.notif-badge { position: absolute; top: 2px; right: 4px; background: #ef4444; color: #fff; font-size: 9px; font-weight: 700; padding: 2px 5px; border-radius: 99px; min-width: 16px; text-align: center; }
.notif-text   { display: flex; flex-direction: column; }
.notif-label  { font-size: 12px; font-weight: 600; color: #1e293b; line-height: 1.2; }
.notif-count  { font-size: 10px; color: #94a3b8; }

.user-wrapper { position: relative; }
.user-pill { display: flex; align-items: center; gap: 8px; padding: 6px 12px 6px 6px; background: #f8fafc; border-radius: 99px; cursor: pointer; transition: all 0.15s; }
.user-pill:hover { background: #f1f5f9; }
.avatar { width: 30px; height: 30px; border-radius: 50%; background: linear-gradient(135deg, #2563eb, #3b82f6); color: #fff; font-size: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center; overflow: hidden; }
.avatar-photo { width: 100%; height: 100%; object-fit: cover; border-radius: 50%; }
.user-meta  { display: flex; flex-direction: column; }
.user-name  { font-size: 12px; font-weight: 600; color: #1e293b; line-height: 1.2; }
.user-role  { font-size: 10px; color: #94a3b8; }

/* NOTIFICATIONS DROPDOWN */
.notif-dropdown { position: absolute; top: calc(100% + 8px); right: 0; width: 380px; max-height: 500px; background: #fff; border: 1px solid #e2e8f0; border-radius: 12px; box-shadow: 0 12px 32px rgba(0,0,0,0.12); z-index: 100; display: flex; flex-direction: column; }
.notif-dropdown-header { padding: 16px 18px; border-bottom: 1px solid #f1f5f9; display: flex; align-items: center; justify-content: space-between; }
.notif-dropdown-title  { font-size: 15px; font-weight: 800; color: #1e293b; margin: 0; }
.mark-all-btn { background: none; border: none; color: #2563eb; font-size: 12px; font-weight: 600; cursor: pointer; font-family: inherit; }
.mark-all-btn:hover { color: #1d4ed8; }
.notif-dropdown-list { overflow-y: auto; max-height: 380px; }
.notif-item { display: flex; align-items: flex-start; gap: 12px; padding: 14px 16px; cursor: pointer; transition: background 0.15s; position: relative; border-bottom: 1px solid #f8fafc; }
.notif-item:hover { background: #f8fafc; }
.notif-item.unread { background: #eff6ff; }
.notif-item.unread:hover { background: #dbeafe; }
.notif-icon-wrap { width: 36px; height: 36px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.notif-content { flex: 1; min-width: 0; }
.notif-top { display: flex; align-items: flex-start; justify-content: space-between; gap: 8px; margin-bottom: 4px; }
.notif-title   { font-size: 13px; font-weight: 700; color: #1e293b; line-height: 1.3; margin: 0; }
.notif-time    { font-size: 11px; color: #94a3b8; white-space: nowrap; }
.notif-message { font-size: 12px; color: #64748b; line-height: 1.4; margin: 0 0 6px 0; }
.notif-type-tag { display: inline-block; font-size: 10px; font-weight: 600; padding: 3px 8px; border-radius: 6px; text-transform: capitalize; }
.unread-dot { position: absolute; top: 50%; transform: translateY(-50%); right: 16px; width: 8px; height: 8px; border-radius: 50%; background: #2563eb; flex-shrink: 0; }
.view-all-btn { display: block; text-align: center; padding: 12px; border-top: 1px solid #f1f5f9; color: #2563eb; font-size: 13px; font-weight: 600; text-decoration: none; transition: background 0.15s; }
.view-all-btn:hover { background: #f8fafc; }
.notif-empty { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 32px 16px; gap: 10px; color: #94a3b8; font-size: 13px; }

/* USER DROPDOWN */
.user-dropdown { position: absolute; top: calc(100% + 8px); right: 0; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; box-shadow: 0 8px 24px rgba(0,0,0,0.12); min-width: 180px; z-index: 100; }
.dropdown-item { display: flex; align-items: center; gap: 8px; padding: 10px 14px; background: none; border: none; width: 100%; text-align: left; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; transition: all 0.15s; border-radius: 8px; margin: 4px; }
.dropdown-item:hover { background: #f8fafc; }
.dropdown-item.logout { color: #ef4444; }
.dropdown-item.logout:hover { background: #fef2f2; }

.dropdown-overlay { position: fixed; inset: 0; z-index: 99; }

.dropdown-enter-active, .dropdown-leave-active { transition: all 0.2s ease; }
.dropdown-enter-from, .dropdown-leave-to { opacity: 0; transform: translateY(-10px); }
</style>