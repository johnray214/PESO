<template>
  <aside class="sidebar">
    <div class="logo">
      <div class="logo-icon">
        <img :src="pesoLogo" alt="PESO" class="logo-img" />
      </div>
      <div class="logo-text">
        <span class="logo-title">PESO</span>
        <span class="logo-sub">Job Matching</span>
      </div>
    </div>
    <nav class="sidebar-nav">
      <!-- Dashboard -->
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
            <span v-if="item.badge" class="nav-badge">{{ item.badge }}</span>
          </router-link>
        </li>
      </ul>

      <p class="nav-label nav-label-bottom">ACCOUNT</p>
      <ul class="nav-list">
        <!-- Profile -->
        <li class="nav-li">
          <router-link to="/dashboard/profile" class="nav-item" exact-active-class="active">
            <span class="nav-icon">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
            </span>
            <span class="nav-text">Profile</span>
          </router-link>
        </li>

        <!-- Users dropdown -->
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

          <!-- Dropdown children -->
          <transition name="dropdown">
            <ul v-if="usersOpen" class="sub-nav">
              <li class="nav-li">
                <router-link to="/dashboard/users" class="nav-item sub-item" exact-active-class="active">
                  <span class="sub-dot"></span>
                  <span class="nav-text">Staff</span>
                </router-link>
              </li>
              <li class="nav-li">
                <router-link to="/dashboard/verified-employer" class="nav-item sub-item" exact-active-class="active">
                  <span class="sub-dot"></span>
                  <span class="nav-text">Employers</span>
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

export default {
  name: 'AppSidebar',
  data() {
    return {
      pesoLogo,
      usersOpen: false,
      topNavItems: [
        { name: 'Dashboard', path: '/dashboard', exact: true, icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>` },
      ],
      mainNavItems: [
        { name: 'Applicants',     path: '/dashboard/applicants',    badge: 24, icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>` },
        { name: 'Employers',      path: '/dashboard/employers',     icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>` },
        { name: 'Events',         path: '/dashboard/events',        icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>` },
        { name: 'Map',            path: '/dashboard/map',           icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6"/><line x1="8" y1="2" x2="8" y2="18"/><line x1="16" y1="6" x2="16" y2="22"/></svg>` },
        { name: 'Notifications',  path: '/dashboard/notifications', badge: 5,  icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>` },
        { name: 'Reporting',      path: '/dashboard/reporting',     icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>` },
        { name: 'Archive',        path: '/dashboard/archive',       icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="21 8 21 21 3 21 3 8"/><rect x="1" y="3" width="22" height="5"/><line x1="10" y1="12" x2="14" y2="12"/></svg>` },
        { name: 'Audit Logs',     path: '/dashboard/audit-logs',    icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>` },
      ],
    }
  },
  computed: {
    isUsersActive() {
      return this.$route?.path?.startsWith('/dashboard/users')
    }
  },
  watch: {
    '$route'(to) {
      if (to.path.startsWith('/dashboard/users')) {
        this.usersOpen = true
      }
    }
  },
  mounted() {
    if (this.$route?.path?.startsWith('/dashboard/users')) {
      this.usersOpen = true
    }
  },
  methods: {
    toggleUsers() {
      this.usersOpen = !this.usersOpen
    }
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.sidebar {
  width: 210px;
  min-width: 210px;
  height: 100vh;
  background: #fff;
  display: flex;
  flex-direction: column;
  border-right: 1px solid #f1f5f9;
  flex-shrink: 0;
  font-family: 'Plus Jakarta Sans', sans-serif;
}

.logo {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 18px 16px;
  border-bottom: 1px solid #f1f5f9;
}
.logo-icon {
  width: 36px; height: 36px;
  background: #dbeafe; border-radius: 10px;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0; overflow: hidden;
}
.logo-img { width: 100%; height: 100%; object-fit: cover; }
.logo-text { display: flex; flex-direction: column; }
.logo-title { font-size: 15px; font-weight: 800; color: #1e293b; letter-spacing: 0.05em; line-height: 1; }
.logo-sub   { font-size: 10px; color: #94a3b8; font-weight: 500; margin-top: 2px; }

.sidebar-nav { flex: 1; padding: 12px; overflow-y: auto; }

.nav-label {
  font-size: 10px; font-weight: 700; color: #cbd5e1;
  padding: 12px 0 6px 0; margin: 0; letter-spacing: 0.1em;
}
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
.nav-item.active {
  background: #eff6ff; color: #1d4ed8;
  border-left-color: #2563eb; font-weight: 600;
}
.nav-item.active .nav-icon { color: #2563eb; }

/* dropdown toggle — no router-link so handle active manually */
.nav-dropdown-toggle { cursor: pointer; }
.nav-dropdown-toggle.active {
  background: #eff6ff; color: #1d4ed8;
  border-left-color: #2563eb; font-weight: 600;
}

.dropdown-arrow {
  margin-left: auto;
  display: flex; align-items: center;
  color: #94a3b8;
  transition: transform 0.2s ease;
}
.dropdown-arrow.open { transform: rotate(180deg); }

/* sub nav */
.sub-nav { list-style: none; padding: 0; margin: 0; }
.sub-item {
  padding: 8px 12px 8px 28px;
  border-left: 4px solid transparent;
  font-size: 13px;
}
.sub-item.active {
  background: #eff6ff; color: #1d4ed8;
  border-left-color: #2563eb; font-weight: 600;
}
.sub-dot {
  width: 6px; height: 6px; border-radius: 50%;
  background: #cbd5e1; flex-shrink: 0;
  transition: background 0.15s;
}
.sub-item.active .sub-dot,
.sub-item:hover .sub-dot { background: #2563eb; }

.nav-icon { display: flex; align-items: center; flex-shrink: 0; }
.nav-text { flex: 1; }

.nav-badge {
  background: #ef4444; color: #fff;
  font-size: 10px; font-weight: 700;
  padding: 2px 7px; border-radius: 99px;
  min-width: 20px; text-align: center;
}
.nav-item.active .nav-badge { background: #2563eb; }

/* dropdown transition */
.dropdown-enter-active { transition: all 0.2s ease; }
.dropdown-leave-active { transition: all 0.15s ease; }
.dropdown-enter-from, .dropdown-leave-to { opacity: 0; transform: translateY(-6px); }
</style>