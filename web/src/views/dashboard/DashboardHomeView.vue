<script setup lang="ts">
import { computed } from 'vue'
import { useAuthStore } from '../../stores/auth'
import { useApplicantsStore } from '../../stores/applicants'
import { useEmployersStore } from '../../stores/employers'
import { useEventsStore } from '../../stores/events'
import { useNotificationsStore } from '../../stores/notifications'
import { useAuditLogsStore } from '../../stores/auditLogs'

const authStore = useAuthStore()
const applicantsStore = useApplicantsStore()
const employersStore = useEmployersStore()
const eventsStore = useEventsStore()
const notificationsStore = useNotificationsStore()
const auditLogsStore = useAuditLogsStore()

const user = computed(() => authStore.user)
</script>

<template>
  <section class="grid">
    <div class="welcome-card">
      <h2 class="welcome-title">
        Welcome back,
        <span>{{ user?.name ?? 'Guest' }}</span>
      </h2>
      <p class="welcome-body">
        Use this dashboard to manage applicants, employers, events, and outreach
        for your Public Employment Service Office.
      </p>
    </div>

    <div class="stats">
      <div class="stat-card">
        <div class="stat-label">
          Applicants
        </div>
        <div class="stat-value">
          {{ applicantsStore.total }}
        </div>
        <div class="stat-meta">
          {{ applicantsStore.hiredCount }} hired ·
          {{ applicantsStore.notHiredCount }} not hired
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-label">
          Employers
        </div>
        <div class="stat-value">
          {{ employersStore.totalEmployers }}
        </div>
        <div class="stat-meta">
          {{ employersStore.totalJobs }} active job postings
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-label">
          Events
        </div>
        <div class="stat-value">
          {{ eventsStore.activeEvents.length }}
        </div>
        <div class="stat-meta">
          {{ eventsStore.archivedEvents.length }} in archive
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-label">
          Notifications
        </div>
        <div class="stat-value">
          {{ notificationsStore.total }}
        </div>
        <div class="stat-meta">
          {{ auditLogsStore.entries.length }} audit log entries
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.grid {
  display: grid;
  grid-template-columns: minmax(0, 2.1fr) minmax(0, 2fr);
  gap: 1.25rem;
}

.welcome-card {
  border-radius: 1rem;
  padding: 1.4rem 1.5rem;
  background: linear-gradient(135deg, #ffffff, #e5f0fb);
  color: #0f172a;
  box-shadow:
    0 18px 40px rgba(15, 23, 42, 0.08),
    0 0 0 1px rgba(148, 163, 184, 0.18);
}

.welcome-title {
  margin: 0 0 0.5rem;
  font-size: 1.25rem;
  font-weight: 600;
}

.welcome-title span {
  color: #1565c0;
}

.welcome-body {
  margin: 0;
  font-size: 0.9rem;
  color: #64748b;
  max-width: 36rem;
}

.stats {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0.9rem;
}

.stat-card {
  border-radius: 0.85rem;
  padding: 0.85rem 0.95rem;
  background-color: #ffffff;
  border: 1px solid #dbeafe;
  color: #0f172a;
  box-shadow: 0 10px 25px rgba(15, 23, 42, 0.04);
}

.stat-label {
  font-size: 0.8rem;
  color: #64748b;
}

.stat-value {
  font-size: 1.4rem;
  font-weight: 600;
  margin-top: 0.1rem;
}

.stat-meta {
  margin-top: 0.2rem;
  font-size: 0.8rem;
  color: #6b7280;
}

@media (max-width: 900px) {
  .grid {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>

