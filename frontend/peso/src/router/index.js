import { createRouter, createWebHistory } from 'vue-router'  // ✅ createWebHistory removes /#/
import { useAuthStore, ROLES } from '@/stores/auth'
import { useEmployerAuthStore } from '@/stores/employerAuth'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import EmployerLayout from '@/layouts/EmployerLayout.vue'

const routes = [
  // ✅ / now shows EmployerLanding (public page)
  {
    path: '/',
    name: 'home',
    component: () => import('@/views/EmployerLanding.vue'),
  },

  // ✅ Admin login moved to /admin/login
  {
    path: '/admin/login',
    name: 'login',
    component: () => import('@/views/LoginView.vue'),
    meta: { guest: true },
  },
  {
    path: '/admin/forgot-password',
    name: 'admin-forgot-password',
    component: () => import('@/views/AdminForgot.vue'),
    meta: { guest: true },
  },
  {
    path: '/admin/reset-password',
    name: 'admin-reset-password',
    component: () => import('@/views/AdminReset.vue'),
    meta: { guest: true },
  },

  // Employer public pages
  {
    path: '/employer/login',
    name: 'employer-login',
    component: () => import('@/views/EmployerLogin.vue'),
  },
  {
    path: '/employer/register',
    name: 'employer-register',
    component: () => import('@/views/EmployerRegister.vue'),
  },
  {
    path: '/employer/page',
    name: 'employer-page',
    component: () => import('@/views/EmployerLanding.vue'),
  },
  {
    path: '/employer/forgot-password',
    name: 'employer-forgot-password',
    component: () => import('@/views/EmployerForgot.vue'),
  },
  {
    path: '/employer/reset-password',
    name: 'employer-reset-password',
    component: () => import('@/views/EmployerReset.vue'),
  },

  // Jobseeker public pages
  {
    path: '/jobseeker/forgot-password',
    name: 'jobseeker-forgot-password',
    component: () => import('@/views/JobseekerForgot.vue'),
  },
  {
    path: '/jobseeker/reset-password',
    name: 'jobseeker-reset-password',
    component: () => import('@/views/JobseekerReset.vue'),
  },

  // Admin/Staff dashboard
  {
    path: '/dashboard',
    component: DashboardLayout,
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        name: 'dashboard',
        component: () => import('@/views/admin/DashboardPage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF, ROLES.EMPLOYER],
          subtitle: 'Welcome back, Admin 👋',
        },
      },
      {
        path: 'applicants',
        name: 'applicants',
        component: () => import('@/views/admin/ApplicantsPage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF],
          subtitle: 'Manage and monitor all registered jobseekers',
        },
      },
      {
        path: 'employers',
        name: 'employers',
        component: () => import('@/views/admin/EmployerPage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF],
          subtitle: 'Manage companies and their job listings',
        },
      },
      {
        path: 'events',
        name: 'events',
        component: () => import('@/views/admin/EventsPage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF],
          subtitle: 'Manage job fairs, seminars, and programs',
        },
      },
      {
        path: 'map',
        name: 'map',
        component: () => import('@/views/admin/MapPage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF, ROLES.EMPLOYER],
          subtitle: 'View and manage job posting locations across the area',
        },
      },
      {
        path: 'notifications',
        name: 'notifications',
        component: () => import('@/views/admin/NotificationsPage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF],
          subtitle: 'System alerts and messaging to jobseekers & employers',
        },
      },
      {
        path: 'reporting',
        name: 'reporting',
        component: () => import('@/views/admin/ReportingPage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF],
          subtitle: 'Build, preview, and export custom reports',
        },
      },
      {
        path: 'archive',
        name: 'archive',
        component: () => import('@/views/admin/ArchivePage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF],
          subtitle: 'Soft-deleted records — restore or permanently remove',
        },
      },
      {
        path: 'audit-logs',
        name: 'audit-logs',
        component: () => import('@/views/admin/AuditLogsPage.vue'),
        meta: {
          roles: [ROLES.ADMIN],
          subtitle: 'Read-only activity trail of all system actions',
        },
      },
      {
        path: 'profile',
        name: 'profile',
        component: () => import('@/views/admin/ProfilePage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF, ROLES.EMPLOYER],
          subtitle: 'Manage your account settings and preferences',
        },
      },
      {
        path: 'users',
        name: 'users',
        component: () => import('@/views/admin/UsersPage.vue'),
        meta: {
          roles: [ROLES.ADMIN],
          subtitle: 'Manage internal staff accounts and roles',
        },
      },
      {
        path: 'jobseekers',
        name: 'jobseekers',
        component: () => import('@/views/admin/JobseekerPage.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF, ROLES.EMPLOYER],
          subtitle: 'Manage jobseekers accounts',
        },
      },
      {
        path: 'verified-employer',
        name: 'verified-employer',
        component: () => import('@/views/admin/EmployerUser.vue'),
        meta: {
          roles: [ROLES.ADMIN, ROLES.STAFF, ROLES.EMPLOYER],
          subtitle: 'Review and verify employer registrations',
        },
      },
    ],
  },

  // Employer portal
  {
    path: '/employer',
    component: EmployerLayout,
    meta: { requiresAuth: true, employerOnly: true },
    children: [
      {
        path: 'dashboard',
        name: 'employer-dashboard',
        component: () => import('@/views/employer/EmployerDashboard.vue'),
      },
      {
        path: 'applicants',
        name: 'employer-applicants',
        component: () => import('@/views/employer/EmployerApplicants.vue'),
      },
      {
        path: 'job-listings',
        name: 'employer-job-listings',
        component: () => import('@/views/employer/EmployerJoblisting.vue'),
      },
      {
        path: 'profile',
        name: 'employer-profile',
        component: () => import('@/views/employer/EmployerPorfile.vue'),
      },
      {
        path: 'notifications',
        name: 'employer-notifications',
        component: () => import('@/views/employer/EmployerNotifications.vue'),
      },
    ],
  },

  // Catch-all
  {
    path: '/:pathMatch(.*)*',
    redirect: '/',
  },
]

const router = createRouter({
  history: createWebHistory(), 
  routes,
})

router.beforeEach(async (to, _from, next) => {
  const employerToken = localStorage.getItem('employer_token')

  const isEmployerRoute      = to.matched.some(r => r.meta.employerOnly)
  const isEmployerPublicPage = [
    'employer-login', 'employer-register',
    'employer-forgot-password', 'employer-reset-password'
  ].includes(to.name)
  const isAdminGuestPage     = to.meta.guest

  // employer routes — redirect to employer login if no token
  if (isEmployerRoute && !employerToken) {
    return next({ name: 'employer-login', query: { redirect: to.fullPath } })
  }

  // already logged in employer trying to hit login/register
  if (isEmployerPublicPage && employerToken) {
    return next({ name: 'employer-dashboard' })
  }

  // init employer auth store so user data is in state
  const employerAuthStore = useEmployerAuthStore()
  if (!employerAuthStore.initialized) {
    await employerAuthStore.init()
  }

  // init admin auth store
  const authStore = useAuthStore()
  if (!authStore.initialized) {
    await authStore.init()
  }

  const authenticated = authStore.isAuthenticated

  // already logged in admin trying to hit /admin/login
  if (isAdminGuestPage && authenticated) {
    return next({ name: 'dashboard' })
  }

  // protected admin route — redirect to /admin/login if not authenticated
  if (to.meta.requiresAuth && !authenticated && !isEmployerRoute) {
    return next({ name: 'login', query: { redirect: to.fullPath } })
  }

  // role check
  const allowedRoles = to.meta.roles
  const role = authStore.role?.toLowerCase()
  if (allowedRoles?.length && (!role || !allowedRoles.includes(role))) {
    return next({ name: 'dashboard' })
  }

  next()
})

export default router