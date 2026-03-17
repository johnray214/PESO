import { createRouter, createWebHashHistory } from 'vue-router'
import { useAuthStore, ROLES } from '@/stores/auth'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import EmployerLayout from '@/layouts/EmployerLayout.vue'

const routes = [
  {
    path: '/login',
    name: 'login',
    component: () => import(/* webpackChunkName: "login" */ '@/views/LoginView.vue'),
    meta: { guest: true },
  },
  { 
    path: '/employer/login',
    name: 'employer-login', 
    component: () => import('@/views/EmployerLogin.vue') 
  },
  { 
    path: '/employer/register', 
    name: 'employer-register',
    component: () => import('@/views/EmployerRegister.vue') 
  },
  {
    path: '/employer/page', 
    name: 'employer-page',
    component: () => import('@/views/EmployerLanding.vue') 
  },
  { 
    path: '/employer/forgot-password',
    name: 'employer-forgot-password',
    component: () => import('@/views/EmployerForgot.vue')
  },
  {
    path: '/',
    redirect: '/dashboard',
  },
  {
    path: '/dashboard',
    component: DashboardLayout,
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        name: 'dashboard',
        component: () => import(/* webpackChunkName: "dashboard" */ '@/views/admin/DashboardPage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF, ROLES.EMPLOYER],
          subtitle: 'Welcome back, Admin 👋',
        },
      },
      {
        path: 'applicants',
        name: 'applicants',
        component: () => import(/* webpackChunkName: "applicants" */ '@/views/admin/ApplicantsPage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF],
          subtitle: 'Manage and monitor all registered jobseekers',
        },
      },
      {
        path: 'employers',
        name: 'employers',
        component: () => import(/* webpackChunkName: "employers" */ '@/views/admin/EmployerPage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF],
          subtitle: 'Manage companies and their job listings',
        },
      },
      {
        path: 'events',
        name: 'events',
        component: () => import(/* webpackChunkName: "events" */ '@/views/admin/EventsPage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF],
          subtitle: 'Manage job fairs, seminars, and programs',
        },
      },
      {
        path: 'map',
        name: 'map',
        component: () => import(/* webpackChunkName: "map" */ '@/views/admin/MapPage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF, ROLES.EMPLOYER],
          subtitle: 'View and manage job posting locations across the area',
        },
      },
      {
        path: 'notifications',
        name: 'notifications',
        component: () => import(/* webpackChunkName: "notifications" */ '@/views/admin/NotificationsPage.vue'),
        meta: {
          roles: [ROLES.ADMIN],
          subtitle: 'System alerts and messaging to jobseekers & employers',
        },
      },
      {
        path: 'reporting',
        name: 'reporting',
        component: () => import(/* webpackChunkName: "reporting" */ '@/views/admin/ReportingPage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF],
          subtitle: 'Build, preview, and export custom reports',
        },
      },
      {
        path: 'archive',
        name: 'archive',
        component: () => import(/* webpackChunkName: "archive" */ '@/views/admin/ArchivePage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF],
          subtitle: 'Soft-deleted records — restore or permanently remove',
        },
      },
      {
        path: 'audit-logs',
        name: 'audit-logs',
        component: () => import(/* webpackChunkName: "audit" */ '@/views/admin/AuditLogsPage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF],
          subtitle: 'Read-only activity trail of all system actions',
        },
      },
      {
        path: 'profile',
        name: 'profile',
        component: () => import(/* webpackChunkName: "profile" */ '@/views/admin/ProfilePage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF, ROLES.EMPLOYER],
          subtitle: 'Manage your account settings and preferences',
        },
      },
      {
        path: 'jobs',
        name: 'jobs',
        component: () => import(/* webpackChunkName: "dashboard" */ '@/views/admin/DashboardPage.vue'),
        meta: { roles: [ROLES.EMPLOYER] },
      },
      {
        path: 'users',
        name: 'users',
        component: () => import(/* webpackChunkName: "profile" */ '@/views/admin/UsersPage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF, ROLES.EMPLOYER],
          subtitle: 'Manage internal staff accounts and roles',
        },
      },
      {
        path: 'verified-employer',
        name: 'verified-employer',
        component: () => import(/* webpackChunkName: "profile" */ '@/views/admin/EmployerUser.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF, ROLES.EMPLOYER],
          subtitle: 'Review and verify employer registrations',
        },
      },
      {
        path: 'hired',
        name: 'hired',
        component: () => import(/* webpackChunkName: "dashboard" */ '@/views/admin/DashboardPage.vue'),
        meta: { roles: [ROLES.EMPLOYER] },
      },
    ],
  },
  {
    path: '/employer',
    component: EmployerLayout,
    meta: { requiresAuth: true, employerOnly: true },
    children: [
      {
        path: 'dashboard',
        name: 'employer-dashboard',
        component: () => import(/* webpackChunkName: "employer-dashboard" */ '@/views/employer/EmployerDashboard.vue'),
      },
      {
        path: 'applicants',
        name: 'employer-applicants',
        component: () => import(/* webpackChunkName: "employer-applicants" */ '@/views/employer/EmployerApplicants.vue'),
      },
      {
        path: 'job-listings',
        name: 'employer-job-listings',
        component: () => import(/* webpackChunkName: "employer-jobs" */ '@/views/employer/EmployerJoblisting.vue'),
      },
      {
        path: 'profile',
        name: 'employer-profile',
        component: () => import(/* webpackChunkName: "employer-profile" */ '@/views/employer/EmployerPorfile.vue'),
      },
       {
        path: 'notifications',
        name: 'employer-notificaitons',
        component: () => import(/* webpackChunkName: "employer-profile" */ '@/views/employer/EmployerNotifications.vue'),
      },
    ],
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/dashboard',
  },
]

const router = createRouter({
  history: createWebHashHistory(),
  routes,
})

router.beforeEach(async (to, _from, next) => {
  const employerToken = localStorage.getItem('employer_token')
  
  // Check if this is an employer-only route (check current or any parent)
  const isEmployerRoute = to.matched.some(record => record.meta.employerOnly)
  const isEmployerLoginPage = to.name === 'employer-login' || to.name === 'employer-register'

  if (isEmployerRoute && !employerToken) {
    return next({ name: 'employer-login', query: { redirect: to.fullPath } })
  }

  if (isEmployerLoginPage && employerToken) {
    return next({ name: 'employer-dashboard' })
  }

  const authStore = useAuthStore()
  if (!authStore.initialized) {
    await authStore.init()
  }

  const authenticated = authStore.isAuthenticated
  if (to.meta.guest && authenticated && !isEmployerLoginPage) {
    return next({ name: 'dashboard' })
  }
  if (to.meta.requiresAuth && !authenticated && !isEmployerRoute) {
    return next({ name: 'login', query: { redirect: to.fullPath } })
  }

  const allowedRoles = to.meta.roles
  const role = authStore.role
  if (allowedRoles?.length && (!role || !allowedRoles.includes(role))) {
    return next({ name: 'dashboard' })
  }

  next()
})

export default router
