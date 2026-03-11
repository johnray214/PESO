<template>
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
        <li v-for="item in topNavItems" :key="item.name" class="nav-li">
          <router-link :to="item.path" class="nav-item" exact-active-class="active">
            <span class="nav-icon" v-html="item.icon"></span>
            <span class="nav-text">{{ item.name }}</span>
          </router-link>
        </li>
      </ul>

      <p class="nav-label">MANAGE</p>
      <ul class="nav-list">
        <li v-for="item in mainNavItems" :key="item.name" class="nav-li">
          <router-link :to="item.path" class="nav-item" exact-active-class="active">
            <span class="nav-icon" v-html="item.icon"></span>
            <span class="nav-text">{{ item.name }}</span>
            <span v-if="item.badge" class="nav-badge">{{ item.badge }}</span>
          </router-link>
        </li>
      </ul>

      <p class="nav-label nav-label-bottom">ACCOUNT</p>
      <ul class="nav-list">
        <li v-for="item in bottomNavItems" :key="item.name" class="nav-li">
          <router-link :to="item.path" class="nav-item" exact-active-class="active">
            <span class="nav-icon" v-html="item.icon"></span>
            <span class="nav-text">{{ item.name }}</span>
          </router-link>
        </li>
      </ul>
    </nav>

    <div class="sidebar-footer">
      <div class="company-card">
        <div class="company-avatar">N</div>
        <div class="company-info">
          <span class="company-name">Nexus Tech</span>
          <span class="company-role">Employer Account</span>
        </div>
      </div>
    </div>
  </aside>
</template>

<script>
import pesoLogo from '@/assets/PESOLOGO.jpg'

export default {
  name: 'EmployerSidebar',
  data() {
    return {
      pesoLogo,
      topNavItems: [
        { name: 'Dashboard', path: '/employer/dashboard', icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>` },
      ],
      mainNavItems: [
        { name: 'Applicants',   path: '/employer/applicants',    badge: 8, icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>` },
        { name: 'Job Listings', path: '/employer/job-listings',  badge: 0, icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>` },
        { name: 'Notifications',path: '/employer/notifications', badge: 3, icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>` },
      ],
      bottomNavItems: [
        { name: 'Profile', path: '/employer/profile', icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>` },
      ],
    }
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
.sidebar { width: 210px; min-width: 210px; height: 100vh; background: #fff; display: flex; flex-direction: column; border-right: 1px solid #f1f5f9; flex-shrink: 0; font-family: 'Plus Jakarta Sans', sans-serif; }
.logo { display: flex; align-items: center; gap: 10px; padding: 18px 16px; border-bottom: 1px solid #f1f5f9; }
.logo-icon { width: 36px; height: 36px; background: #dbeafe; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; overflow: hidden; }
.logo-img { width: 100%; height: 100%; object-fit: cover; }
.logo-text { display: flex; flex-direction: column; }
.logo-title { font-size: 15px; font-weight: 800; color: #1e293b; letter-spacing: 0.05em; line-height: 1; }
.logo-sub { font-size: 10px; color: #2872A1; font-weight: 600; margin-top: 2px; }
.sidebar-nav { flex: 1; padding: 12px; overflow-y: auto; }
.nav-label { font-size: 10px; font-weight: 700; color: #cbd5e1; padding: 12px 0 6px; margin: 0; letter-spacing: 0.1em; }
.nav-label-bottom { margin-top: 8px; padding-top: 12px; }
.nav-list { list-style: none; padding: 0; margin: 0; }
.nav-li { margin-bottom: 2px; }
.nav-item { display: flex; align-items: center; gap: 10px; padding: 10px 12px; cursor: pointer; border-radius: 0 8px 8px 0; border-left: 4px solid transparent; color: #64748b; font-size: 13.5px; font-weight: 500; transition: all 0.15s ease; text-decoration: none; }
.nav-item:hover { background: #eff8ff; color: #1e293b; }
.nav-item.active { background: #eff8ff; color: #1a5f8a; border-left-color: #2872A1; font-weight: 600; }
.nav-item.active .nav-icon { color: #2872A1; }
.nav-icon { display: flex; align-items: center; flex-shrink: 0; }
.nav-text { flex: 1; }
.nav-badge { background: #2872A1; color: #fff; font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 99px; min-width: 20px; text-align: center; }
.sidebar-footer { padding: 12px; border-top: 1px solid #f1f5f9; }
.company-card { display: flex; align-items: center; gap: 10px; padding: 10px 12px; border-radius: 10px; background: #eff8ff; }
.company-avatar { width: 32px; height: 32px; border-radius: 50%; background: linear-gradient(135deg, #2872A1, #08BDDE); color: #fff; font-size: 13px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.company-info { display: flex; flex-direction: column; flex: 1; min-width: 0; }
.company-name { font-size: 13px; font-weight: 600; color: #1e293b; line-height: 1.2; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.company-role { font-size: 10px; color: #94a3b8; }
</style>