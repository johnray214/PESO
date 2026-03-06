import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'

import LoginView from '../views/LoginView.vue'
import DashboardLayout from '../views/dashboard/DashboardLayout.vue'
import DashboardHomeView from '../views/dashboard/DashboardHomeView.vue'
import ApplicantsView from '../views/dashboard/ApplicantsView.vue'
import EmployersView from '../views/dashboard/EmployersView.vue'
import EventsView from '../views/dashboard/EventsView.vue'
import MapView from '../views/dashboard/MapView.vue'
import NotificationsView from '../views/dashboard/NotificationsView.vue'
import ArchiveView from '../views/dashboard/ArchiveView.vue'
import AuditLogsView from '../views/dashboard/AuditLogsView.vue'

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'login',
    component: LoginView,
    meta: { public: true },
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
        name: 'dashboard-home',
        component: DashboardHomeView,
      },
      {
        path: 'applicants',
        name: 'applicants',
        component: ApplicantsView,
        meta: { roles: ['admin', 'employer'] },
      },
      {
        path: 'employers',
        name: 'employers',
        component: EmployersView,
        meta: { roles: ['admin'] },
      },
      {
        path: 'events',
        name: 'events',
        component: EventsView,
        meta: { roles: ['admin'] },
      },
      {
        path: 'map',
        name: 'map',
        component: MapView,
      },
      {
        path: 'notifications',
        name: 'notifications',
        component: NotificationsView,
        meta: { roles: ['admin'] },
      },
      {
        path: 'archive',
        name: 'archive',
        component: ArchiveView,
        meta: { roles: ['admin'] },
      },
      {
        path: 'audit-logs',
        name: 'audit-logs',
        component: AuditLogsView,
        meta: { roles: ['admin'] },
      },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
})

router.beforeEach((to, from, next) => {
  const isPublic = to.matched.some((record) => record.meta.public)
  const requiresAuth = to.matched.some((record) => record.meta.requiresAuth)

  const storedUser = localStorage.getItem('peso_user')
  const user = storedUser ? JSON.parse(storedUser) as { role?: string } : null

  if (!isPublic && requiresAuth && !user) {
    next({
      name: 'login',
      query: { redirect: to.fullPath },
    })
    return
  }

  const requiredRoles = to.matched
    .flatMap((record) => (record.meta.roles as string[] | undefined) ?? [])

  if (requiresAuth && requiredRoles.length > 0 && user && user.role && !requiredRoles.includes(user.role)) {
    next({ name: 'dashboard-home' })
    return
  }

  if (to.name === 'login' && user) {
    next({ name: 'dashboard-home' })
    return
  }

  next()
})

export default router
