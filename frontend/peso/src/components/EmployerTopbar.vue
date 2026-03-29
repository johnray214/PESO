<template>
  <header class="topbar">
    <div class="topbar-left">
      <template v-if="!authStore.isAppReady">
        <div class="skeleton" style="width: 150px; height: 18px; border-radius: 4px; margin-bottom: 4px;"></div>
        <div class="skeleton" style="width: 100px; height: 12px; border-radius: 4px;"></div>
      </template>
      <template v-else>
        <h1 class="topbar-title">{{ title }}</h1>
        <span class="topbar-sub">{{ subtitle }}</span>
      </template>
    </div>
    <div class="topbar-right">
        <!-- Bell Button -->
        <div class="bell-wrap" ref="bellWrap">
          <template v-if="!authStore.isAppReady">
            <div class="skeleton" style="width: 32px; height: 32px; border-radius: 8px;"></div>
          </template>
          <template v-else>
            <button class="icon-btn" @click="toggleNotifPanel">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                <path d="M13.73 21a2 2 0 01-3.46 0"/>
              </svg>
              <span v-if="notifStore.unreadCount > 0" class="bell-dot">{{ notifStore.unreadCount }}</span>
            </button>
          </template>

        <!-- Notification Dropdown -->
        <transition name="panel">
          <div v-if="showPanel" class="notif-panel">
            <div class="panel-header">
              <span class="panel-title">Notifications</span>
              <button class="panel-mark-all" @click="markAllRead">Mark all read</button>
            </div>
            <div class="panel-list">
              <div v-if="notifStore.loading" class="panel-loading">
                <span class="spin"></span> Loading…
              </div>
              <div v-else-if="notifStore.recentNotifs.length === 0" class="panel-empty">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.5"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>
                <p>No notifications yet</p>
              </div>
              <div v-for="n in notifStore.recentNotifs" :key="n.id"
                :class="['panel-item', { unread: !n.read }]"
                @click="markRead(n)">
                <div class="panel-icon" :style="{ background: typeColors[n.type]?.bg || typeColors.system.bg }">
                  <span v-html="typeColors[n.type]?.icon || typeColors.system.icon"
                        :style="{ color: typeColors[n.type]?.color || typeColors.system.color }"></span>
                </div>
                <div class="panel-item-body">
                  <div class="panel-item-top">
                    <p class="panel-item-title">{{ n.title }}</p>
                    <span class="panel-item-time">{{ n.time }}</span>
                  </div>
                  <p class="panel-item-msg">{{ n.message }}</p>
                  <span class="panel-type-tag" :style="{ background: typeColors[n.type]?.bg, color: typeColors[n.type]?.color }">{{ n.type }}</span>
                </div>
                <span v-if="!n.read" class="panel-unread-dot"></span>
              </div>
            </div>
            <div class="panel-footer">
              <router-link to="/employer/notifications" class="panel-see-all" @click="showPanel = false">
                View all notifications
              </router-link>
            </div>
          </div>
        </transition>
      </div>

      <!-- User Pill with dropdown -->
      <div class="user-wrap" ref="userWrap">
        <button class="user-pill" @click="toggleUserMenu">
          <template v-if="!authStore.isAppReady">
            <div class="company-logo-nav skeleton"></div>
            <div class="user-meta-t" style="gap: 4px; padding: 2px 0;">
              <div class="skeleton" style="width: 90px; height: 14px; border-radius: 4px;"></div>
              <div class="skeleton" style="width: 60px; height: 10px; border-radius: 2px;"></div>
            </div>
            <svg class="caret" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="6 9 12 15 18 9"/></svg>
          </template>
          <template v-else>
            <div class="company-logo-nav" v-if="authStore.user?.photo">
              <img :src="authStore.user.photo" alt="Logo" class="nav-logo-img" />
            </div>
            <div v-else class="avatar-t">{{ companyInitial }}</div>
            <div class="user-meta-t">
              <span class="uname-t">{{ companyName }}</span>
              <span class="urole-t">Employer Account</span>
            </div>
            <svg class="caret" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="6 9 12 15 18 9"/></svg>
          </template>
        </button>

        <!-- User Dropdown -->
        <transition name="panel">
          <div v-if="showUserMenu" class="user-dropdown">
            <div class="user-dropdown-header">
              <div class="company-logo-nav dropdown-pic" v-if="authStore.user?.photo">
                <img :src="authStore.user.photo" alt="Logo" class="nav-logo-img" />
              </div>
              <div v-else class="dropdown-avatar">{{ companyInitial }}</div>
              <div>
                <p class="dropdown-name">{{ companyName }}</p>
                <p class="dropdown-role">Employer Account</p>
              </div>
            </div>
            <div class="dropdown-divider"></div>
            <router-link to="/employer/profile" class="dropdown-item" @click="showUserMenu = false">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>
              Company Profile
            </router-link>
            <router-link to="/employer/notifications" class="dropdown-item" @click="showUserMenu = false">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>
              Notifications
              <span v-if="notifStore.unreadCount > 0" class="dropdown-notif-badge">{{ notifStore.unreadCount }}</span>
            </router-link>
            <div class="dropdown-divider"></div>
            <button class="dropdown-item logout-item" @click="handleLogout" :disabled="loggingOut">
              <span v-if="loggingOut" class="btn-spin"></span>
              <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
              {{ loggingOut ? 'Logging out…' : 'Logout' }}
            </button>
          </div>
        </transition>
      </div>
    </div>
  </header>
</template>

<script>
import { useEmployerNotificationStore } from '@/stores/employerNotificationStore'
import { useEmployerAuthStore }         from '@/stores/employerAuth'

export default {
  name: 'EmployerTopbar',
  props: {
    title:    { type: String, default: 'Dashboard' },
    subtitle: { type: String, default: '' },
  },
  setup() {
    const notifStore  = useEmployerNotificationStore()
    const authStore   = useEmployerAuthStore()
    return { notifStore, authStore }
  },
  data() {
    return {
      showPanel:    false,
      showUserMenu: false,
      loggingOut:   false,
      typeColors: {
        applicant: { bg: '#eff8ff', color: '#2872A1', icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>` },
        job:       { bg: '#f0fdf4', color: '#22c55e', icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>` },
        system:    { bg: '#f1f5f9', color: '#64748b', icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>` },
        match:     { bg: '#faf5ff', color: '#8b5cf6', icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>` },
      },
    }
  },
  computed: {
    companyName() {
      const u = this.authStore.user
      return u?.company_name || u?.name || u?.legal_name || 'Employer'
    },
    companyInitial() {
      const name = this.authStore.user?.company_name || this.authStore.user?.name || this.authStore.user?.legal_name || 'E'
      return name[0].toUpperCase()
    },

  },
  methods: {
    toggleNotifPanel() {
      this.showPanel    = !this.showPanel
      this.showUserMenu = false
      if (this.showPanel) this.notifStore.fetch()
    },
    toggleUserMenu() {
      this.showUserMenu = !this.showUserMenu
      this.showPanel    = false
    },
    async markRead(n)  { await this.notifStore.markRead(n) },
    async markAllRead(){ await this.notifStore.markAllRead() },
    async handleLogout() {
      this.loggingOut = true
      try {
        await this.authStore.logout()
        window.location.href = '/employer/login'
      } finally {
        this.loggingOut = false
      }
    },
    handleOutsideClick(e) {
      if (this.$refs.bellWrap && !this.$refs.bellWrap.contains(e.target)) this.showPanel    = false
      if (this.$refs.userWrap && !this.$refs.userWrap.contains(e.target)) this.showUserMenu = false
    },
  },
  mounted() {
    this.authStore.setAppReady()

    document.addEventListener('click', this.handleOutsideClick)
    // Kick off background fetch so badge is ready
    this.notifStore.fetch()
  },
  beforeUnmount() {
    document.removeEventListener('click', this.handleOutsideClick)
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
.topbar { background: #fff; padding: 14px 24px; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid #f1f5f9; flex-shrink: 0; font-family: 'Plus Jakarta Sans', sans-serif; position: relative; z-index: 50; }
.topbar-left { display: flex; flex-direction: column; }
.topbar-title { font-size: 18px; font-weight: 800; color: #1e293b; line-height: 1.1; }
.topbar-sub { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.topbar-right { display: flex; align-items: center; gap: 12px; }

/* Bell */
.bell-wrap { position: relative; }
.icon-btn { background: none; border: none; cursor: pointer; color: #64748b; display: flex; align-items: center; padding: 7px; border-radius: 8px; position: relative; transition: background 0.15s; }
.icon-btn:hover { background: #f1f5f9; }
.bell-dot { position: absolute; top: 2px; right: 2px; background: #2872A1; color: #fff; font-size: 9px; font-weight: 700; padding: 1px 4px; border-radius: 99px; min-width: 16px; text-align: center; }

/* Dropdown Panel */
.notif-panel { position: absolute; top: calc(100% + 10px); right: 0; width: 360px; background: #fff; border-radius: 14px; box-shadow: 0 8px 32px rgba(0,0,0,0.14); border: 1px solid #f1f5f9; z-index: 200; overflow: hidden; }
.panel-header { display: flex; align-items: center; justify-content: space-between; padding: 14px 16px; border-bottom: 1px solid #f1f5f9; }
.panel-title { font-size: 14px; font-weight: 800; color: #1e293b; }
.panel-mark-all { background: none; border: none; font-size: 12px; color: #2872A1; font-weight: 600; cursor: pointer; font-family: inherit; }
.panel-mark-all:hover { text-decoration: underline; }
.panel-list { display: flex; flex-direction: column; max-height: 320px; overflow-y: auto; }
.panel-loading { display: flex; align-items: center; gap: 8px; padding: 20px 16px; font-size: 12.5px; color: #94a3b8; }
.panel-empty { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 32px 16px; gap: 10px; color: #94a3b8; font-size: 13px; }
.panel-item { display: flex; align-items: flex-start; gap: 12px; padding: 14px 16px; cursor: pointer; transition: background 0.15s; border-bottom: 1px solid #f8fafc; position: relative; }
.panel-item:hover { background: #f8fafc; }
.panel-item.unread { background: #eff6ff; }
.panel-item.unread:hover { background: #dbeafe; }
.panel-icon { width: 36px; height: 36px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.panel-item-body { flex: 1; min-width: 0; }
.panel-item-top { display: flex; align-items: flex-start; justify-content: space-between; gap: 8px; margin-bottom: 4px; }
.panel-item-title { font-size: 13px; font-weight: 700; color: #1e293b; line-height: 1.3; margin: 0; }
.panel-type-tag { display: inline-block; font-size: 10px; font-weight: 600; padding: 3px 8px; border-radius: 6px; text-transform: capitalize; margin-top: 4px; }
.panel-item-msg { font-size: 12px; color: #64748b; line-height: 1.4; margin: 0 0 6px 0; white-space: normal; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; text-overflow: ellipsis; }
.panel-item-time { font-size: 11px; color: #94a3b8; white-space: nowrap; }
.panel-unread-dot { width: 7px; height: 7px; border-radius: 50%; background: #2872A1; flex-shrink: 0; margin-top: 4px; }
.panel-footer { padding: 12px 16px; border-top: 1px solid #f1f5f9; text-align: center; }
.panel-see-all { font-size: 12.5px; font-weight: 600; color: #2872A1; text-decoration: none; }
.panel-see-all:hover { text-decoration: underline; }

/* Spinner */
.spin { display: inline-block; width: 14px; height: 14px; border: 2px solid #e2e8f0; border-top-color: #2872A1; border-radius: 50%; animation: spin 0.7s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

/* User pill + dropdown */
.user-wrap { position: relative; }
.user-pill { display: flex; align-items: center; gap: 8px; padding: 6px 10px 6px 6px; background: #eff8ff; border-radius: 99px; border: none; cursor: pointer; font-family: inherit; transition: background 0.15s; }
.user-pill:hover { background: #dbeafe; }
.avatar-t { width: 38px; height: 38px; border-radius: 50%; background: linear-gradient(135deg, #2872A1, #08BDDE); color: #fff; font-size: 15px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.company-logo-nav { width: 38px; height: 38px; border-radius: 50%; overflow: hidden; flex-shrink: 0; background: #fff; border: 1px solid #bae6fd; }
.company-logo-nav.dropdown-pic { width: 46px; height: 46px; }
.nav-logo-img { width: 100%; height: 100%; object-fit: cover; }
.user-meta-t { display: flex; flex-direction: column; text-align: left; }
.uname-t { font-size: 12px; font-weight: 600; color: #1e293b; line-height: 1.2; max-width: 120px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.urole-t { font-size: 10px; color: #94a3b8; }
.caret { color: #94a3b8; flex-shrink: 0; }
.user-dropdown { position: absolute; top: calc(100% + 10px); right: 0; width: 230px; background: #fff; border-radius: 14px; box-shadow: 0 8px 32px rgba(0,0,0,0.14); border: 1px solid #f1f5f9; z-index: 200; overflow: hidden; }
.user-dropdown-header { display: flex; align-items: center; gap: 10px; padding: 14px 16px; background: #f8fafc; }
.dropdown-avatar { width: 46px; height: 46px; border-radius: 50%; background: linear-gradient(135deg, #2872A1, #08BDDE); color: #fff; font-size: 18px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.dropdown-name { font-size: 13px; font-weight: 700; color: #1e293b; line-height: 1.2; }
.dropdown-role { font-size: 11px; color: #94a3b8; margin-top: 2px; }
.dropdown-divider { height: 1px; background: #f1f5f9; }
.dropdown-item { display: flex; align-items: center; gap: 10px; padding: 11px 16px; font-size: 13px; font-weight: 500; color: #475569; text-decoration: none; cursor: pointer; transition: background 0.12s; background: none; border: none; width: 100%; font-family: inherit; }
.dropdown-item:hover { background: #f8fafc; color: #1e293b; }
.logout-item { color: #ef4444; }
.logout-item:hover { background: #fef2f2; color: #dc2626; }
.logout-item:disabled { opacity: 0.65; cursor: not-allowed; }
.btn-spin { display: inline-block; width: 13px; height: 13px; border: 2px solid rgba(239,68,68,0.3); border-top-color: #ef4444; border-radius: 50%; animation: spin 0.65s linear infinite; flex-shrink: 0; }
.dropdown-notif-badge { margin-left: auto; background: #2872A1; color: #fff; font-size: 9px; font-weight: 700; padding: 2px 6px; border-radius: 99px; }

/* Transition */
.panel-enter-active, .panel-leave-active { transition: opacity 0.15s, transform 0.15s; }
.panel-enter-from, .panel-leave-to { opacity: 0; transform: translateY(-6px); }

.skeleton {
  background: #e2e8f0;
  border-radius: 4px;
  animation: pulse 1.5s infinite;
}
@keyframes pulse {
  0% { opacity: 0.6; }
  50% { opacity: 0.3; }
  100% { opacity: 0.6; }
}
</style>