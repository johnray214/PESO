<template>
  <div class="employer-wrapper">
    <aside class="sidebar">
      <div class="logo">
        <div class="logo-icon">
          <img :src="pesoLogo" alt="PESO" class="logo-img" />
        </div>
        <div class="logo-text">
          <span class="logo-title">PESO</span>
          <span class="logo-sub">Employer Portal</span>
        </div>
      </div>
      <nav class="sidebar-nav">
        <ul class="nav-list">
          <li v-for="item in navItems" :key="item.name" class="nav-li">
            <router-link :to="item.path" class="nav-item" exact-active-class="active">
              <span class="nav-icon" v-html="item.icon"></span>
              <span class="nav-text">{{ item.name }}</span>
              <span v-if="item.badge" class="nav-badge">{{ item.badge }}</span>
            </router-link>
          </li>
        </ul>
      </nav>
    </aside>
    <div class="main">
      <header class="topbar">
        <div class="topbar-left">
          <h1 class="page-title">{{ pageTitle }}</h1>
          <span class="page-sub">Manage your job postings and applicants</span>
        </div>
        <div class="topbar-right">
          <div class="user-wrapper">
            <div class="user-pill" @click="showUserMenu = !showUserMenu">
              <div class="avatar">{{ companyInitial }}</div>
              <div class="user-meta">
                <span class="user-name">{{ companyName }}</span>
                <span class="user-role">Employer</span>
              </div>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="6 9 12 15 18 9"/>
              </svg>
            </div>
            <transition name="dropdown">
              <div v-if="showUserMenu" class="user-dropdown">
                <button class="dropdown-item logout" @click="handleLogout">
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/>
                    <polyline points="16 17 21 12 16 7"/>
                    <line x1="21" y1="12" x2="9" y2="12"/>
                  </svg>
                  Logout
                </button>
              </div>
            </transition>
          </div>
        </div>
      </header>
      <div class="main-scroll">
        <router-view />
      </div>
    </div>
    <div v-if="showUserMenu" class="dropdown-overlay" @click="showUserMenu = false"></div>
  </div>
</template>

<script>
import { computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import pesoLogo from '@/assets/PESOLOGO.jpg'

export default {
  name: 'EmployerLayout',
  setup() {
    const router = useRouter()
    const route = useRoute()

    function handleLogout() {
      localStorage.removeItem('employer_token')
      router.push('/employer/login')
    }

    const pageTitle = computed(() => {
      const name = route.name || 'Dashboard'
      const base = String(name).replace(/-/g, ' ').replace('employer', '').trim()
      return base
        .split(' ')
        .filter(Boolean)
        .map(w => w.charAt(0).toUpperCase() + w.slice(1))
        .join(' ')
    })

    return { handleLogout, pageTitle }
  },
  data() {
    return {
      pesoLogo,
      showUserMenu: false,
      companyName: 'Accenture PH',
      companyInitial: 'A',
      navItems: [
        { name: 'Dashboard', path: '/employer/dashboard', icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>` },
        { name: 'Applicants', path: '/employer/applicants', badge: 18, icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>` },
        { name: 'Job Listings', path: '/employer/job-listings', icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>` },
        { name: 'Profile', path: '/employer/profile', icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>` },
      ],
    }
  },
}
</script>

<style scoped>
.employer-wrapper {
  display: flex;
  height: 100vh;
  overflow: hidden;
  font-family: 'Plus Jakarta Sans', sans-serif;
}

.sidebar {
  width: 210px;
  min-width: 210px;
  height: 100vh;
  background: #fff;
  display: flex;
  flex-direction: column;
  border-right: 1px solid #f1f5f9;
  flex-shrink: 0;
}

.logo {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 18px 16px;
  border-bottom: 1px solid #f1f5f9;
}

.logo-icon {
  width: 36px;
  height: 36px;
  background: #dbeafe;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  overflow: hidden;
}

.logo-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.logo-text {
  display: flex;
  flex-direction: column;
}

.logo-title {
  font-size: 15px;
  font-weight: 800;
  color: #1e293b;
  letter-spacing: 0.05em;
  line-height: 1;
}

.logo-sub {
  font-size: 10px;
  color: #94a3b8;
  font-weight: 500;
  margin-top: 2px;
}

.sidebar-nav {
  flex: 1;
  padding: 12px;
  overflow-y: auto;
}

.nav-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.nav-li {
  margin-bottom: 2px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  cursor: pointer;
  border-radius: 0 8px 8px 0;
  border-left: 4px solid transparent;
  color: #64748b;
  font-size: 13.5px;
  font-weight: 500;
  transition: all 0.15s ease;
  user-select: none;
  text-decoration: none;
}

.nav-item:hover {
  background: #f8fafc;
  color: #1e293b;
}

.nav-item.active {
  background: #eff6ff;
  color: #1d4ed8;
  border-left-color: #2563eb;
  font-weight: 600;
}

.nav-item.active .nav-icon {
  color: #2563eb;
}

.nav-icon {
  display: flex;
  align-items: center;
  flex-shrink: 0;
}

.nav-text {
  flex: 1;
}

.nav-badge {
  background: #ef4444;
  color: #fff;
  font-size: 10px;
  font-weight: 700;
  padding: 2px 7px;
  border-radius: 99px;
  min-width: 20px;
  text-align: center;
}

.nav-item.active .nav-badge {
  background: #2563eb;
  color: #fff;
}

.main {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  background: #f1eeff;
}

.main-scroll {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
}

.topbar {
  background: #fff;
  padding: 14px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid #f1f5f9;
}

.topbar-left {
  display: flex;
  flex-direction: column;
}

.page-title {
  font-size: 18px;
  font-weight: 800;
  color: #1e293b;
  line-height: 1.2;
}

.page-sub {
  font-size: 11px;
  color: #94a3b8;
  margin-top: 2px;
}

.topbar-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-wrapper {
  position: relative;
}

.user-pill {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px 6px 6px;
  background: #f8fafc;
  border-radius: 99px;
  cursor: pointer;
  transition: all 0.15s;
}

.user-pill:hover {
  background: #f1f5f9;
}

.avatar {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  background: linear-gradient(135deg, #2563eb, #3b82f6);
  color: #fff;
  font-size: 12px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
}

.user-meta {
  display: flex;
  flex-direction: column;
}

.user-name {
  font-size: 12px;
  font-weight: 600;
  color: #1e293b;
  line-height: 1.2;
}

.user-role {
  font-size: 10px;
  color: #94a3b8;
}

.user-dropdown {
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
  min-width: 180px;
  z-index: 100;
}

.dropdown-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 14px;
  background: none;
  border: none;
  width: 100%;
  text-align: left;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.15s;
  border-radius: 8px;
  margin: 4px;
}

.dropdown-item:hover {
  background: #f8fafc;
}

.dropdown-item.logout {
  color: #ef4444;
}

.dropdown-item.logout:hover {
  background: #fef2f2;
}

.dropdown-overlay {
  position: fixed;
  inset: 0;
  z-index: 99;
}

.dropdown-enter-active,
.dropdown-leave-active {
  transition: all 0.2s ease;
}

.dropdown-enter-from,
.dropdown-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>
