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
      <div>
        <template v-if="!authStore.isAppReady">
          <ul class="nav-list">
            <li v-for="i in 1" :key="'skt-'+i" class="nav-li">
              <div class="nav-item">
                <div class="skeleton" style="width: 16px; height: 16px; border-radius: 4px;"></div>
                <div class="skeleton" style="width: 100px; height: 14px; border-radius: 4px; margin-left:10px;"></div>
              </div>
            </li>
          </ul>
          <div class="skeleton" style="width: 60px; height: 10px; border-radius: 2px; margin: 12px 0 6px;"></div>
          <ul class="nav-list">
            <li v-for="i in 3" :key="'skm-'+i" class="nav-li">
              <div class="nav-item">
                <div class="skeleton" style="width: 16px; height: 16px; border-radius: 4px;"></div>
                <div class="skeleton" style="width: 100px; height: 14px; border-radius: 4px; margin-left:10px;"></div>
              </div>
            </li>
          </ul>
          <div class="skeleton" style="width: 60px; height: 10px; border-radius: 2px; margin: 20px 0 6px;"></div>
          <ul class="nav-list">
            <li v-for="i in 1" :key="'skb-'+i" class="nav-li">
              <div class="nav-item">
                <div class="skeleton" style="width: 16px; height: 16px; border-radius: 4px;"></div>
                <div class="skeleton" style="width: 100px; height: 14px; border-radius: 4px; margin-left:10px;"></div>
              </div>
            </li>
          </ul>
        </template>

        <template v-else>
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
          <li class="nav-li">
            <router-link to="/employer/applicants" class="nav-item" exact-active-class="active">
              <span class="nav-icon" v-html="applicantsIcon"></span>
              <span class="nav-text">Applicants</span>
              <span v-if="applicantsStore.reviewingCount > 0" class="nav-badge" title="Applicants under review">{{ applicantsStore.reviewingCount }}</span>
              <span v-if="applicantsStore.totalPotential > 0" class="nav-badge potential-nav-badge" :title="applicantsStore.totalPotential + ' potential matches'">
                {{ applicantsStore.totalPotential }} potential
              </span>
            </router-link>
          </li>

          <!-- Job Listings -->
          <li class="nav-li">
            <router-link to="/employer/job-listings" class="nav-item" exact-active-class="active">
              <span class="nav-icon" v-html="jobListingsIcon"></span>
              <span class="nav-text">Job Listings</span>
            </router-link>
          </li>

          <!-- Notifications -->
          <li class="nav-li">
            <router-link to="/employer/notifications" class="nav-item" exact-active-class="active">
              <span class="nav-icon" v-html="notificationsIcon"></span>
              <span class="nav-text">Notifications</span>
              <span v-if="notifStore.unreadCount > 0" class="nav-badge">{{ notifStore.unreadCount }}</span>
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
        </template>
      </div>
    </nav>

    <div class="sidebar-footer">
      <div class="company-card">
        <template v-if="!authStore.isAppReady">
          <div class="company-logo-nav skeleton"></div>
          <div class="company-info" style="gap: 4px; justify-content: center;">
            <div class="skeleton" style="width: 100px; height: 14px; border-radius: 4px;"></div>
            <div class="skeleton" style="width: 70px; height: 10px; border-radius: 2px;"></div>
          </div>
        </template>
        <template v-else>
          <div class="company-logo-nav" v-if="authStore.user?.photo">
            <img :src="authStore.user.photo" alt="Company Logo" class="nav-logo-img" />
          </div>
          <div v-else class="company-avatar">{{ companyInitial }}</div>
          <div class="company-info">
            <span class="company-name">{{ companyName }}</span>
            <span class="company-role">Employer Account</span>
          </div>
        </template>
        <button class="logout-btn" title="Logout" @click="handleLogout" :disabled="loggingOut">
          <span v-if="loggingOut" class="btn-spin"></span>
          <svg v-else width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/>
            <polyline points="16 17 21 12 16 7"/>
            <line x1="21" y1="12" x2="9" y2="12"/>
          </svg>
        </button>
      </div>
    </div>
  </aside>
</template>

<script>
import pesoLogo from '@/assets/PESOLOGO.jpg'
import { useRouter } from 'vue-router'
import { useEmployerNotificationStore } from '@/stores/employerNotificationStore'
import { useEmployerApplicantsStore }   from '@/stores/employerApplicantsStore'
import { useEmployerAuthStore }         from '@/stores/employerAuth'

export default {
  name: 'EmployerSidebar',
  setup() {
    const router          = useRouter()
    const notifStore      = useEmployerNotificationStore()
    const applicantsStore = useEmployerApplicantsStore()
    const authStore       = useEmployerAuthStore()
    return { router, notifStore, applicantsStore, authStore }
  },
  data() {
    return {
      pesoLogo,
      loggingOut: false,
      topNavItems: [
        { name: 'Dashboard', path: '/employer/dashboard', icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>` },
      ],
      applicantsIcon:    `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>`,
      jobListingsIcon:   `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>`,
      notificationsIcon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>`,
      bottomNavItems: [
        { name: 'Profile', path: '/employer/profile', icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>` },
      ],
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
    async handleLogout() {
      this.loggingOut = true
      try {
        await this.authStore.logout()
        window.location.href = '/employer/login'
      } finally {
        this.loggingOut = false
      }
    },
  },
  mounted() {
    this.authStore.setAppReady()
    
    // Kick off background fetch for stores (no-op if already loaded)
    this.notifStore.fetch()
    this.applicantsStore.fetch()
  },
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
.nav-item { display: flex; align-items: center; gap: 10px; padding: 10px 12px; cursor: pointer; border-radius: 0 8px 8px 0; border-left: 4px solid transparent; color: #64748b; font-size: 13.5px; font-weight: 500; transition: all 0.15s ease; text-decoration: none; flex-wrap: wrap; }
.nav-item:hover { background: #eff8ff; color: #1e293b; }
.nav-item.active { background: #eff8ff; color: #1a5f8a; border-left-color: #2872A1; font-weight: 600; }
.nav-item.active .nav-icon { color: #2872A1; }
.nav-icon { display: flex; align-items: center; flex-shrink: 0; }
.nav-text { flex: 1; }
.nav-badge { background: #2872A1; color: #fff; font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 99px; min-width: 20px; text-align: center; }

/* Potential badge */
.potential-nav-badge {
  background: #ede9fe;
  color: #7c3aed;
  font-size: 9.5px;
  font-weight: 700;
  padding: 2px 7px;
  border-radius: 99px;
  margin-left: auto;
  white-space: nowrap;
}

.sidebar-footer { padding: 12px; border-top: 1px solid #f1f5f9; }
.company-card { display: flex; align-items: center; gap: 10px; padding: 10px 12px; border-radius: 10px; background: #eff8ff; }
.company-avatar { width: 44px; height: 44px; border-radius: 50%; background: linear-gradient(135deg, #2872A1, #08BDDE); color: #fff; font-size: 15px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.company-logo-nav { width: 44px; height: 44px; border-radius: 50%; overflow: hidden; flex-shrink: 0; box-shadow: 0 0 0 1px #bae6fd; background: #fff; }
.nav-logo-img { width: 100%; height: 100%; object-fit: cover; }
.company-info { display: flex; flex-direction: column; flex: 1; min-width: 0; }
.company-name { font-size: 13px; font-weight: 600; color: #1e293b; line-height: 1.2; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.company-role { font-size: 10px; color: #94a3b8; }
.logout-btn { background: none; border: none; cursor: pointer; color: #94a3b8; display: flex; align-items: center; padding: 4px; border-radius: 6px; transition: all 0.15s; flex-shrink: 0; }
.logout-btn:hover { background: #fee2e2; color: #ef4444; }
.logout-btn:disabled { opacity: 0.65; cursor: not-allowed; }
.btn-spin { display: inline-block; width: 13px; height: 13px; border: 2px solid rgba(148,163,184,0.3); border-top-color: #94a3b8; border-radius: 50%; animation: spin 0.65s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

.skeleton {
  background: #e2e8f0;
  animation: pulse 1.5s infinite;
}
@keyframes pulse {
  0% { opacity: 0.7; }
  50% { opacity: 0.3; }
  100% { opacity: 0.7; }
}
</style>