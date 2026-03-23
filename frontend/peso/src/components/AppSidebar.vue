<template>
  <aside class="sidebar">
    <!-- Logo always shows — no skeleton here -->
    <div class="logo">
      <div class="logo-icon">
        <img :src="pesoLogo" alt="PESO" class="logo-img" />
      </div>
      <div class="logo-text">
        <span class="logo-title">PESO</span>
        <span class="logo-sub">Job Matching</span>
      </div>
    </div>

    <!-- SKELETON -->
    <nav v-if="loading" class="sidebar-nav">
      <div class="skel-section-label"></div>
      <div v-for="i in 1" :key="'top'+i" class="skel-nav-item">
        <div class="skel skel-icon"></div>
        <div class="skel skel-text"></div>
      </div>

      <div class="skel-section-label mt"></div>
      <div v-for="i in 8" :key="'main'+i" class="skel-nav-item">
        <div class="skel skel-icon"></div>
        <div class="skel skel-text" :style="{ width: (55 + (i % 3) * 15) + 'px' }"></div>
      </div>

      <div class="skel-section-label mt"></div>
      <div v-for="i in 3" :key="'acc'+i" class="skel-nav-item">
        <div class="skel skel-icon"></div>
        <div class="skel skel-text" :style="{ width: (50 + (i % 2) * 20) + 'px' }"></div>
      </div>
    </nav>

    <!-- ACTUAL NAV -->
    <nav v-else class="sidebar-nav">
      <ul class="nav-list">
        <li v-for="item in topNavItems" :key="item.name" class="nav-li">
          <router-link :to="item.path" class="nav-item" exact-active-class="active">
            <span class="nav-icon" v-html="item.icon"></span>
            <span class="nav-text">{{ item.name }}</span>
          </router-link>
        </li>
      </ul>

      <p class="nav-label">MAIN MENU</p>
      <ul class="nav-list">
        <li v-for="item in mainNavItems" :key="item.name" class="nav-li">
          <router-link :to="item.path" class="nav-item" exact-active-class="active" :active-class="item.exact ? '' : 'active'">
            <span class="nav-icon" v-html="item.icon"></span>
            <span class="nav-text">{{ item.name }}</span>
            <span v-if="navBadge(item)" class="nav-badge">{{ navBadge(item) }}</span>
          </router-link>
        </li>
      </ul>

      <p class="nav-label nav-label-bottom">ACCOUNT</p>
      <ul class="nav-list">
        <li class="nav-li">
          <router-link to="/dashboard/profile" class="nav-item" exact-active-class="active">
            <span class="nav-icon">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
            </span>
            <span class="nav-text">Profile</span>
          </router-link>
        </li>

        <li class="nav-li">
          <div class="nav-item nav-dropdown-toggle" :class="{ 'active': usersOpen || isUsersActive }" @click="toggleUsers">
            <span class="nav-icon">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
            </span>
            <span class="nav-text">Users</span>
            <span class="dropdown-arrow" :class="{ open: usersOpen }">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="6 9 12 15 18 9"/></svg>
            </span>
          </div>

          <transition name="dropdown">
            <ul v-if="usersOpen" class="sub-nav">
              <li v-if="authStore.role === 'admin'" class="nav-li">
                <router-link to="/dashboard/users" class="nav-item sub-item" exact-active-class="active">
                  <span class="sub-icon">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                  </span>
                  <span class="nav-text">Staff</span>
                </router-link>
              </li>
              <li class="nav-li">
                <router-link to="/dashboard/verified-employer" class="nav-item sub-item" exact-active-class="active">
                  <span class="sub-icon">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>
                  </span>
                  <span class="nav-text">Employers</span>
                </router-link>
              </li>
              <li class="nav-li">
                <router-link to="/dashboard/jobseekers" class="nav-item sub-item" exact-active-class="active">
                  <span class="sub-icon">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
                  </span>
                  <span class="nav-text">Jobseekers</span>
                </router-link>
              </li>
            </ul>
          </transition>
        </li>
      </ul>
    </nav>
  </aside>
</template>

<script>
import pesoLogo from '@/assets/PESOLOGO.jpg'
import { useAdminAppStore } from '@/stores/adminAppStore'
import { useAuthStore } from '@/stores/auth'

export default {
  name: 'AppSidebar',
  setup() {
    const appStore  = useAdminAppStore()
    const authStore = useAuthStore()
    return { appStore, authStore }
  },
  data() {
    return {
      pesoLogo,
      loading: true,
      usersOpen: false,
      topNavItems: [
        { name: 'Dashboard', path: '/dashboard', exact: true, icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>` },
      ],
      mainNavItems: [
        { name: 'Applicants',    path: '/dashboard/applicants',    icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>` },
        { name: 'Employers',     path: '/dashboard/employers',     icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>` },
        { name: 'Events',        path: '/dashboard/events',        icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>` },
        { name: 'Map',           path: '/dashboard/map',           icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6"/><line x1="8" y1="2" x2="8" y2="18"/><line x1="16" y1="6" x2="16" y2="22"/></svg>` },
        { name: 'Notifications', path: '/dashboard/notifications', icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>` },
        { name: 'Reporting',     path: '/dashboard/reporting',     icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>` },
        { name: 'Archive',       path: '/dashboard/archive',       icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="21 8 21 21 3 21 3 8"/><rect x="1" y="3" width="22" height="5"/><line x1="10" y1="12" x2="14" y2="12"/></svg>` },
      ],
    }
  },
  computed: {
    isFullyLoaded() {
      return this.appStore.applicantsLoaded && this.appStore.notificationsLoaded
    },
    isUsersActive() {
      const p = this.$route?.path || ''
      return p.startsWith('/dashboard/users') ||
             p.startsWith('/dashboard/verified-employer') ||
             p.startsWith('/dashboard/jobseekers')
    },
    navBadge() {
      return (item) => {
        if (item.name === 'Applicants') {
          const c = this.appStore.applicantsCount
          return c !== null && c > 0 ? c : null
        }
        if (item.name === 'Notifications') {
          const u = this.appStore.unreadCount
          return u > 0 ? u : null
        }
        return null
      }
    }
  },
  async mounted() {
    await this.$nextTick()
    if (this.isFullyLoaded) {
      this.loading = false
    }
    this.appStore.fetchApplicantsCount()
    if (this.isUsersActive) this.usersOpen = true
  },
  watch: {
    isFullyLoaded(val) {
      if (val) this.loading = false
    },
    '$route'(to) {
      const p = to.path
      if (p.startsWith('/dashboard/users') ||
          p.startsWith('/dashboard/verified-employer') ||
          p.startsWith('/dashboard/jobseekers')) {
        this.usersOpen = true
      }
    }
  },
  methods: {
    toggleUsers() { this.usersOpen = !this.usersOpen }
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.sidebar {
  width: 210px; min-width: 210px; height: 100vh;
  background: #fff; display: flex; flex-direction: column;
  border-right: 1px solid #f1f5f9; flex-shrink: 0;
  font-family: 'Plus Jakarta Sans', sans-serif;
}

.logo { display: flex; align-items: center; gap: 10px; padding: 18px 16px; border-bottom: 1px solid #f1f5f9; }
.logo-icon { width: 36px; height: 36px; background: #dbeafe; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; overflow: hidden; }
.logo-img { width: 100%; height: 100%; object-fit: cover; }
.logo-text { display: flex; flex-direction: column; }
.logo-title { font-size: 15px; font-weight: 800; color: #1e293b; letter-spacing: 0.05em; line-height: 1; }
.logo-sub   { font-size: 10px; color: #94a3b8; font-weight: 500; margin-top: 2px; }

.sidebar-nav { flex: 1; padding: 12px; overflow-y: auto; }

/* ── SKELETON ─────────────────────────────────────────────── */
@keyframes shimmer { 0% { background-position: -400px 0; } 100% { background-position: 400px 0; } }
.skel {
  background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%);
  background-size: 400px 100%; animation: shimmer 1.4s infinite linear;
  border-radius: 6px; flex-shrink: 0;
}
.skel-icon { width: 16px; height: 16px; border-radius: 4px; }
.skel-text { height: 12px; border-radius: 6px; width: 80px; }
.skel-nav-item { display: flex; align-items: center; gap: 10px; padding: 10px 12px; border-radius: 8px; margin-bottom: 2px; }
.skel-section-label {
  height: 8px; width: 70px; border-radius: 4px;
  background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%);
  background-size: 400px 100%; animation: shimmer 1.4s infinite linear;
  margin: 12px 0 8px 12px;
}
.skel-section-label.mt { margin-top: 20px; }

/* ── NAV ──────────────────────────────────────────────────── */
.nav-label { font-size: 10px; font-weight: 700; color: #cbd5e1; padding: 12px 0 6px 0; margin: 0; letter-spacing: 0.1em; }
.nav-label-bottom { margin-top: 8px; padding-top: 12px; }
.nav-list { list-style: none; padding: 0; margin: 0; }
.nav-li { margin-bottom: 2px; }
.nav-item {
  display: flex; align-items: center; gap: 10px;
  padding: 10px 12px; cursor: pointer;
  border-radius: 0 8px 8px 0;
  border-left: 4px solid transparent;
  color: #64748b; font-size: 13.5px; font-weight: 500;
  transition: all 0.15s ease;
  user-select: none; text-decoration: none;
}
.nav-item:hover { background: #f8fafc; color: #1e293b; }
.nav-item.active { background: #eff6ff; color: #1d4ed8; border-left-color: #2563eb; font-weight: 600; }
.nav-item.active .nav-icon { color: #2563eb; }
.nav-dropdown-toggle { cursor: pointer; }
.nav-dropdown-toggle.active { background: #eff6ff; color: #1d4ed8; border-left-color: #2563eb; font-weight: 600; }
.dropdown-arrow { margin-left: auto; display: flex; align-items: center; color: #94a3b8; transition: transform 0.2s ease; }
.dropdown-arrow.open { transform: rotate(180deg); }

.sub-nav { list-style: none; padding: 0; margin: 0; }
.sub-item { padding: 8px 12px 8px 28px; border-left: 4px solid transparent; font-size: 13px; }
.sub-item.active { background: #eff6ff; color: #1d4ed8; border-left-color: #2563eb; font-weight: 600; }
.sub-icon { display: flex; align-items: center; flex-shrink: 0; color: #94a3b8; transition: color 0.15s; }
.sub-item.active .sub-icon, .sub-item:hover .sub-icon { color: #2563eb; }

.nav-icon { display: flex; align-items: center; flex-shrink: 0; }
.nav-text { flex: 1; }
.nav-badge { background: #ef4444; color: #fff; font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 99px; min-width: 20px; text-align: center; }
.nav-item.active .nav-badge { background: #2563eb; }

.dropdown-enter-active { transition: all 0.2s ease; }
.dropdown-leave-active { transition: all 0.15s ease; }
.dropdown-enter-from, .dropdown-leave-to { opacity: 0; transform: translateY(-6px); }
</style>