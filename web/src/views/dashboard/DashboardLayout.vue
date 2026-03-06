<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink, RouterView, useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../../stores/auth'
import { useNotificationsStore } from '../../stores/notifications'
import pesoLogo from '@/assets/images/PESOLOGO.jpg'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const notificationsStore = useNotificationsStore()

const user = computed(() => authStore.user)
const unreadCount = computed(() => notificationsStore.notifications.length)

const latestNotifications = computed(() =>
  [...notificationsStore.notifications]
    .slice(-3)
    .reverse(),
)

function isActivePath(path: string) {
  return route.path === path || route.path.startsWith(`${path}/`)
}

function handleLogout() {
  authStore.logout()
  router.push({ name: 'login' })
}
</script>

<template>
  <div class="layout">
    <aside class="sidebar">
      <div class="sidebar-header">
        <div class="brand-mark">
          <img
            :src="pesoLogo"
            alt="PESO logo"
            class="brand-logo"
          >
        </div>
        <div>
          <div class="brand-title">PESO</div>
          <div class="brand-subtitle">Employment Portal</div>
        </div>
      </div>

      <nav class="nav">
        <RouterLink
          to="/dashboard"
          class="nav-link"
          :class="{ 'nav-link--active': route.path === '/dashboard' || route.path === '/dashboard/' }"
        >
          <span class="nav-dot" />
          <span>Overview</span>
        </RouterLink>

        <RouterLink
          v-if="user?.role === 'admin' || user?.role === 'employer'"
          to="/dashboard/applicants"
          class="nav-link"
          :class="{ 'nav-link--active': isActivePath('/dashboard/applicants') }"
        >
          <span class="nav-dot" />
          <span>Applicants</span>
        </RouterLink>

        <RouterLink
          v-if="user?.role === 'admin'"
          to="/dashboard/employers"
          class="nav-link"
          :class="{ 'nav-link--active': isActivePath('/dashboard/employers') }"
        >
          <span class="nav-dot" />
          <span>Employers &amp; Jobs</span>
        </RouterLink>

        <RouterLink
          v-if="user?.role === 'admin'"
          to="/dashboard/events"
          class="nav-link"
          :class="{ 'nav-link--active': isActivePath('/dashboard/events') }"
        >
          <span class="nav-dot" />
          <span>Events</span>
        </RouterLink>

        <RouterLink
          to="/dashboard/map"
          class="nav-link"
          :class="{ 'nav-link--active': isActivePath('/dashboard/map') }"
        >
          <span class="nav-dot" />
          <span>Map</span>
        </RouterLink>

        <RouterLink
          v-if="user?.role === 'admin'"
          to="/dashboard/notifications"
          class="nav-link"
          :class="{ 'nav-link--active': isActivePath('/dashboard/notifications') }"
        >
          <span class="nav-dot" />
          <span>Notifications</span>
        </RouterLink>

        <RouterLink
          v-if="user?.role === 'admin'"
          to="/dashboard/archive"
          class="nav-link"
          :class="{ 'nav-link--active': isActivePath('/dashboard/archive') }"
        >
          <span class="nav-dot" />
          <span>Archive</span>
        </RouterLink>

        <RouterLink
          v-if="user?.role === 'admin'"
          to="/dashboard/audit-logs"
          class="nav-link"
          :class="{ 'nav-link--active': isActivePath('/dashboard/audit-logs') }"
        >
          <span class="nav-dot" />
          <span>Audit Logs</span>
        </RouterLink>
      </nav>

      <div class="sidebar-footer" v-if="user">
        <div class="user-pill">
          <div class="user-avatar">
            {{ user.name.charAt(0).toUpperCase() }}
          </div>
          <div class="user-meta">
            <div class="user-name">
              {{ user.name }}
            </div>
            <div class="user-role">
              {{ user.role.toUpperCase() }}
            </div>
          </div>
        </div>
      </div>
    </aside>

    <div class="main">
      <header class="topbar">
        <div class="topbar-left">
          <h1 class="page-title">
            PESO Dashboard
          </h1>
          <p class="page-subtitle">
            Manage applicants, employers, events, and notifications.
          </p>
        </div>

        <div class="topbar-right">
          <div class="notifications">
            <div class="notifications-badge">
              <span class="badge-dot" />
              <span class="badge-count">{{ unreadCount }}</span>
            </div>
            <div class="notifications-list">
              <p v-if="latestNotifications.length === 0" class="empty-text">
                No recent notifications
              </p>
              <ul v-else>
                <li
                  v-for="notification in latestNotifications"
                  :key="notification.id"
                  class="notification-item"
                >
                  <div class="notification-title">
                    {{ notification.title }}
                  </div>
                  <div class="notification-meta">
                    {{ notification.target.toUpperCase() }} ·
                    {{ new Date(notification.createdAt).toLocaleString() }}
                  </div>
                </li>
              </ul>
            </div>
          </div>

          <button class="logout-button" type="button" @click="handleLogout">
            Logout
          </button>
        </div>
      </header>

      <main class="content">
        <RouterView />
      </main>
    </div>
  </div>
</template>

<style scoped>
.layout {
  height: 100vh;
  display: grid;
  grid-template-columns: 260px minmax(0, 1fr);
  background:
    radial-gradient(circle at top left, #e3f2fd, transparent 55%),
    radial-gradient(circle at bottom right, #bfdbfe, transparent 55%),
    #f3f4f6;
  overflow: hidden;
}

.sidebar {
  position: relative;
  display: flex;
  flex-direction: column;
  padding: 1.5rem 1.25rem 4.5rem;
  background: linear-gradient(180deg, #0d47a1, #1565c0 40%, #1d4ed8 100%);
  color: #e5e7eb;
  border-right: 1px solid rgba(15, 23, 42, 0.4);
}

.sidebar-header {
  display: flex;
  align-items: center;
  gap: 0.85rem;
  margin-bottom: 1.75rem;
}

.brand-mark {
  width: 36px;
  height: 36px;
  border-radius: 999px;
  background: radial-gradient(circle at 30% 30%, #cfe5f7, #1565c0);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 12px 25px rgba(21, 101, 192, 0.6);
}

.brand-logo {
  width: 100%;
  height: 100%;
  border-radius: 999px;
  object-fit: cover;
}

.brand-initials {
  font-weight: 800;
  color: #0b1120;
}

.brand-title {
  font-weight: 700;
  letter-spacing: 0.08em;
  font-size: 0.85rem;
  text-transform: uppercase;
}

.brand-subtitle {
  font-size: 0.8rem;
  color: #9ca3af;
}

.nav {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.nav-link {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  padding: 0.5rem 0.75rem;
  border-radius: 0.75rem;
  color: #dbeafe;
  text-decoration: none;
  font-size: 0.9rem;
  transition:
    background-color 0.12s ease,
    color 0.12s ease,
    transform 0.08s ease;
}

.nav-link:hover {
  background-color: rgba(15, 23, 42, 0.72);
  color: #e5e7eb;
  transform: translateX(1px);
}

.nav-link--active {
  background: linear-gradient(135deg, rgba(248, 250, 252, 0.16), rgba(239, 246, 255, 0.32));
  color: #f9fafb;
}

.nav-link--active .nav-dot {
  background: linear-gradient(135deg, #1565c0, #2563eb);
}

.nav-dot {
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background-color: rgba(148, 163, 184, 0.8);
}

.sidebar-footer {
  position: fixed;
  left: 0;
  bottom: 1.5rem;
  width: 260px;
  padding: 0 1.25rem;
  box-sizing: border-box;
}

.user-pill {
  display: flex;
  align-items: center;
  gap: 0.65rem;
  padding: 0.5rem 0.75rem;
  background-color: rgba(15, 23, 42, 0.85);
  border-radius: 999px;
}

.user-avatar {
  width: 30px;
  height: 30px;
  border-radius: 999px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #1565c0, #2563eb);
  color: #ecfeff;
  font-size: 0.9rem;
  font-weight: 700;
}

.user-meta {
  display: flex;
  flex-direction: column;
}

.user-name {
  font-size: 0.85rem;
  font-weight: 600;
}

.user-role {
  font-size: 0.75rem;
  color: #9ca3af;
}

.main {
  display: flex;
  flex-direction: column;
  background-color: transparent;
}

.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1.1rem 1.75rem 0.9rem;
  border-bottom: 1px solid rgba(148, 163, 184, 0.35);
  backdrop-filter: blur(16px);
  background: linear-gradient(to right, rgba(255, 255, 255, 0.95), rgba(248, 250, 252, 0.9));
}

.topbar-left {
  display: flex;
  flex-direction: column;
  gap: 0.15rem;
}

.page-title {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 600;
  color: #0f172a;
}

.page-subtitle {
  margin: 0;
  font-size: 0.8rem;
  color: #64748b;
}

.topbar-right {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.notifications {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.notifications-badge {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.25rem 0.45rem;
  border-radius: 999px;
  background-color: rgba(248, 250, 252, 0.95);
  border: 1px solid rgba(21, 101, 192, 0.6);
}

.badge-dot {
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: radial-gradient(circle at 30% 30%, #f59e0b, #fbbf24);
  box-shadow: 0 0 0 4px rgba(245, 158, 11, 0.3);
}

.badge-count {
  font-size: 0.8rem;
  color: #0f172a;
  min-width: 1ch;
  text-align: center;
}

.notifications-list {
  max-width: 260px;
  font-size: 0.75rem;
  color: #1f2937;
}

.empty-text {
  margin: 0;
  color: #9ca3af;
}

.notification-item {
  list-style: none;
  padding: 0.1rem 0;
}

.notification-title {
  font-weight: 500;
}

.notification-meta {
  font-size: 0.7rem;
  color: #9ca3af;
}

.logout-button {
  border-radius: 999px;
  border: none;
  padding: 0.45rem 0.9rem;
  font-size: 0.8rem;
  font-weight: 500;
  background: #0f172a;
  color: #f9fafb;
  cursor: pointer;
  border: 1px solid rgba(15, 23, 42, 0.9);
  transition:
    background-color 0.12s ease,
    color 0.12s ease,
    transform 0.08s ease,
    box-shadow 0.08s ease;
}

.logout-button:hover {
  background-color: #ef4444;
  color: #fef2f2;
  border-color: #fecaca;
  box-shadow: 0 12px 24px rgba(248, 113, 113, 0.45);
  transform: translateY(-1px);
}

.content {
  padding: 1.25rem 1.75rem 1.75rem;
  min-height: 0;
  overflow: auto;
}

@media (max-width: 900px) {
  .layout {
    grid-template-columns: 220px minmax(0, 1fr);
  }

  .topbar {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }

  .notifications-list {
    display: none;
  }
}

@media (max-width: 720px) {
  .layout {
    grid-template-columns: minmax(0, 1fr);
  }

  .sidebar {
    display: none;
  }

  .topbar {
    padding-inline: 1.1rem;
  }

  .content {
    padding-inline: 1.1rem;
  }
}
</style>

