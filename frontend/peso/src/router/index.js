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
    component: () => import(/* webpackChunkName: "employer-login" */ '@/views/employer/LoginView.vue'),
    meta: { guest: true },
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
        meta: { roles: [ROLES.ADMIN, ROLES.STAFF, ROLES.EMPLOYER] },
      },
      {
        path: 'applicants',
        name: 'applicants',
        component: () => import(/* webpackChunkName: "applicants" */ '@/views/admin/ApplicantsPage.vue'),
        meta: { roles: [ROLES.ADMIN, ROLES.STAFF] },
      },
      {
        path: 'employers',
        name: 'employers',
        component: () => import(/* webpackChunkName: "employers" */ '@/views/admin/EmployerPage.vue'),
        meta: { roles: [ROLES.ADMIN, ROLES.STAFF] },
      },
      {
        path: 'events',
        name: 'events',
        component: () => import(/* webpackChunkName: "events" */ '@/views/admin/EventsPage.vue'),
        meta: { roles: [ROLES.ADMIN, ROLES.STAFF] },
      },
      {
        path: 'map',
        name: 'map',
        component: () => import(/* webpackChunkName: "map" */ '@/views/admin/MapPage.vue'),
        meta: { roles: [ROLES.ADMIN, ROLES.STAFF, ROLES.EMPLOYER] },
      },
      {
        path: 'notifications',
        name: 'notifications',
        component: () => import(/* webpackChunkName: "notifications" */ '@/views/admin/NotificationsPage.vue'),
        meta: { roles: [ROLES.ADMIN] },
      },
      {
        path: 'reporting',
        name: 'reporting',
        component: () => import(/* webpackChunkName: "reporting" */ '@/views/admin/ReportingPage.vue'),
        meta: { roles: [ROLES.ADMIN, ROLES.STAFF] },
      },
      {
        path: 'archive',
        name: 'archive',
        component: () => import(/* webpackChunkName: "archive" */ '@/views/admin/ArchivePage.vue'),
        meta: { roles: [ROLES.ADMIN, ROLES.STAFF] },
      },
      {
        path: 'audit-logs',
        name: 'audit-logs',
        component: () => import(/* webpackChunkName: "audit" */ '@/views/admin/AuditLogsPage.vue'),
        meta: { roles: [ROLES.ADMIN, ROLES.STAFF] },
      },
      {
        path: 'profile',
        name: 'profile',
        component: () => import(/* webpackChunkName: "profile" */ '@/views/admin/ProfilePage.vue'),
        meta: { roles: [ROLES.ADMIN, ROLES.STAFF, ROLES.EMPLOYER] },
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
        meta: { roles: [ROLES.ADMIN, ROLES.STAFF, ROLES.EMPLOYER] },
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
        component: () => import(/* webpackChunkName: "employer-dashboard" */ '@/views/employer/DashboardPage.vue'),
      },
      {
        path: 'applicants',
        name: 'employer-applicants',
        component: () => import(/* webpackChunkName: "employer-applicants" */ '@/views/employer/ApplicantsPage.vue'),
      },
      {
        path: 'job-listings',
        name: 'employer-job-listings',
        component: () => import(/* webpackChunkName: "employer-jobs" */ '@/views/employer/JobListingsPage.vue'),
      },
      {
        path: 'profile',
        name: 'employer-profile',
        component: () => import(/* webpackChunkName: "employer-profile" */ '@/views/employer/ProfilePage.vue'),
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
  const isEmployerRoute = to.path.startsWith('/employer') && to.path !== '/employer/login'

  if (to.meta.employerOnly && !employerToken) {
    return next({ name: 'employer-login', query: { redirect: to.fullPath } })
  }

  if (to.name === 'employer-login' && employerToken) {
    return next({ name: 'employer-dashboard' })
  }

  const authStore = useAuthStore()
  if (!authStore.initialized) {
    await authStore.init()
  }

  const authenticated = authStore.isAuthenticated
  if (to.meta.guest && authenticated && to.name !== 'employer-login') {
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
