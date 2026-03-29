<template>
  <div class="layout-wrapper">
    <EmployerSidebar />
    <div class="main-area">
      <EmployerTopbar title="Notifications" subtitle="Stay updated on applicants and job activity" />
      <div class="page">

        <div v-if="isLoading">
          <div class="filters-bar skeleton" style="height: 52px; width: 100%; border-radius: 12px; margin-bottom: 16px;"></div>
          <div class="notif-list-card skeleton" style="height: 500px; width: 100%; border-radius: 14px;"></div>
        </div>

        <div v-else>
        <!-- Tabs + Actions -->
        <div class="filters-bar">
          <div class="notif-tabs">
            <button v-for="tab in notifTabs" :key="tab.value"
              :class="['ntab', { active: activeTab === tab.value }]"
              @click="activeTab = tab.value">
              <span v-html="tab.icon"></span>
              {{ tab.label }}
              <span v-if="tab.unread" class="ntab-badge">{{ tab.unread }}</span>
            </button>
          </div>
          <div class="filter-group">
            <div class="search-box">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
              <input v-model="search" type="text" placeholder="Search notifications…" class="search-input"/>
            </div>
            <select v-model="filterType" class="filter-select">
              <option value="">All Types</option>
              <option value="applicant">Applicant</option>
              <option value="job">Job Listing</option>
              <option value="system">System</option>
              <option value="match">Match</option>
            </select>
            <button class="btn-ghost-sm" @click="markAllRead">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
              Mark all read
            </button>
          </div>
        </div>

        <!-- Stable list card — always in DOM, content swaps, no layout jump -->
        <div class="notif-list-card">

          <!-- Received Tab -->
          <div v-if="activeTab === 'received'">
            <div v-for="n in filteredNotifications" :key="n.id"
              :class="['notif-card', { unread: !n.read }]"
              @click="markRead(n)">
              <div class="notif-icon-wrap" :style="{ background: typeConfig[n.type].bg }">
                <span v-html="typeConfig[n.type].icon" :style="{ color: typeConfig[n.type].color }"></span>
              </div>
              <div class="notif-body">
                <div class="notif-top-row">
                  <span class="notif-title">{{ n.title }}</span>
                  <span class="notif-time">{{ n.time }}</span>
                </div>
                <p class="notif-msg">{{ n.message }}</p>
                <div class="notif-tags">
                  <span class="notif-type-badge" :style="{ background: typeConfig[n.type].bg, color: typeConfig[n.type].color }">{{ n.type }}</span>
                </div>
                <div v-if="n.action" class="notif-action-row">
                </div>
              </div>
              <div v-if="!n.read" class="unread-dot"></div>
            </div>
            <div v-if="filteredNotifications.length === 0" class="empty-state">
              <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.5"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>
              <p>No notifications found</p>
            </div>
          </div>

        </div>

        </div>
      </div>
    </div>

    <!-- COMPOSE MODAL -->
    <transition name="modal">
      <div v-if="showCompose" class="modal-overlay" @click.self="showCompose = false">
        <div class="modal">
          <div class="modal-header">
            <div class="modal-icon-wrap">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
            </div>
            <div>
              <h3 class="modal-title">Send Notification</h3>
              <p class="modal-sub">Notify your applicants about updates</p>
            </div>
            <button class="modal-close" @click="showCompose = false">✕</button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label class="form-label">Recipients</label>
              <select class="form-input" v-model="composeForm.recipients">
                <option value="all">All Applicants</option>
                <option value="shortlisted">Shortlisted Only</option>
                <option value="interview">Invited to Interview</option>
                <option value="hired">Hired</option>
              </select>
            </div>
            <div class="form-group">
              <label class="form-label">Subject</label>
              <input class="form-input" v-model="composeForm.subject" placeholder="e.g. Interview Schedule Update"/>
            </div>
            <div class="form-group">
              <label class="form-label">Message</label>
              <textarea class="form-input" v-model="composeForm.message" rows="4" placeholder="Write your message to applicants…"></textarea>
            </div>
            <div class="form-group">
              <label class="form-label">Schedule</label>
              <div class="schedule-opts">
                <button :class="['sched-opt', { active: composeForm.schedule === 'now' }]" @click="composeForm.schedule = 'now'">Send Now</button>
                <button :class="['sched-opt', { active: composeForm.schedule === 'later' }]" @click="composeForm.schedule = 'later'">Schedule</button>
              </div>
              <input v-if="composeForm.schedule === 'later'" type="datetime-local" class="form-input" style="margin-top:8px"/>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn-ghost" @click="showCompose = false">Cancel</button>
            <button class="btn-primary" @click="showCompose = false">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
              Send Notification
            </button>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
import EmployerSidebar from '@/components/EmployerSidebar.vue'
import EmployerTopbar  from '@/components/EmployerTopbar.vue'
import { useEmployerNotificationStore } from '@/stores/employerNotificationStore'

export default {
  name: 'EmployerNotifications',
  components: { EmployerSidebar, EmployerTopbar },

  setup() {
    const notifStore = useEmployerNotificationStore()
    return { notifStore }
  },

  data() {
    return {
      isLoading:   true,
      activeTab:   'received',
      search:      '',
      filterType:  '',
      showCompose: false,
      composeForm: { recipients: 'all', subject: '', message: '', schedule: 'now' },
      notifTabs: [
        { label: 'Received', value: 'received', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>` },
      ],
      sentNotifications: [],
      typeConfig: {
        applicant: { bg: '#eff8ff', color: '#2872A1', icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>` },
        job:       { bg: '#f0fdf4', color: '#22c55e', icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>` },
        system:    { bg: '#f8fafc', color: '#64748b', icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>` },
        match:     { bg: '#faf5ff', color: '#8b5cf6', icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>` },
      },
    }
  },

  computed: {
    unreadCount() { return this.notifStore.unreadCount },

    filteredNotifications() {
      return this.notifStore.notifications.filter((n) => {
        const matchSearch = !this.search || n.title.toLowerCase().includes(this.search.toLowerCase()) || n.message.toLowerCase().includes(this.search.toLowerCase())
        const matchType   = !this.filterType || n.type === this.filterType
        return matchSearch && matchType
      })
    },

    tabBadge() { return this.notifStore.unreadCount },

    stripStats() {
      const ns = this.notifStore.notifications
      return [
        { label: 'Total',     value: ns.length,                                color: '#1e293b' },
        { label: 'Unread',    value: ns.filter((n) => !n.read).length,          color: '#2872A1' },
        { label: 'Matches',   value: ns.filter((n) => n.type === 'match').length,    color: '#8b5cf6' },
        { label: 'Applicant', value: ns.filter((n) => n.type === 'applicant').length, color: '#08BDDE' },
        { label: 'System',    value: ns.filter((n) => n.type === 'system').length,   color: '#64748b' },
      ]
    },
  },

  methods: {
    async markRead(n)  { await this.notifStore.markRead(n) },
    async markAllRead(){ await this.notifStore.markAllRead() },
    typeColor(type)    { return this.typeConfig[type] || this.typeConfig.system },
  },

  async mounted() {
    // Store is cache-first: no-op if topbar already loaded it
    await this.notifStore.fetch()
    this.isLoading = false
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
.layout-wrapper { display: flex; height: 100vh; overflow: hidden; background: #f8fafc; font-family: 'Plus Jakarta Sans', sans-serif; }
.main-area { flex: 1; display: flex; flex-direction: column; min-height: 0; overflow: hidden; }
.page { flex: 1; overflow-y: auto; padding: 24px; display: flex; flex-direction: column; gap: 16px; min-height: 0; }

.stats-strip { display: flex; background: #fff; border-radius: 12px; overflow: hidden; border: 1px solid #f1f5f9; }
.strip-stat { flex: 1; display: flex; flex-direction: column; align-items: center; padding: 14px 12px; border-right: 1px solid #f1f5f9; }
.strip-stat:last-child { border-right: none; }
.strip-val { font-size: 22px; font-weight: 800; line-height: 1; }
.strip-label { font-size: 11px; color: #94a3b8; margin-top: 4px; font-weight: 500; }

.filters-bar { display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
.notif-tabs { display: flex; gap: 4px; background: #f8fafc; padding: 4px; border-radius: 10px; border: 1px solid #f1f5f9; }
.ntab { display: flex; align-items: center; gap: 7px; padding: 8px 14px; border: none; border-radius: 8px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; font-family: inherit; background: none; transition: all 0.15s; }
.ntab.active { background: #fff; color: #2872A1; font-weight: 700; box-shadow: 0 1px 4px rgba(0,0,0,0.08); }
.ntab-badge { background: #2872A1; color: #fff; font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 99px; }
.filter-group { display: flex; align-items: center; gap: 8px; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; min-width: 220px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }
.btn-ghost-sm { display: flex; align-items: center; gap: 6px; background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; font-family: inherit; }
.btn-ghost-sm:hover { background: #f8fafc; }

.notif-list-card { background: #fff; border: 1px solid #f1f5f9; border-radius: 12px; overflow: hidden; flex: 1; min-height: 0; display: flex; flex-direction: column; }
.notif-list-card > div { flex: 1; overflow-y: auto; min-height: 0; }
.notif-list { display: flex; flex-direction: column; }
.notif-card { display: flex; gap: 14px; background: #fff; border-radius: 0; padding: 16px 20px; border: none; border-bottom: 1px solid #f1f5f9; cursor: pointer; transition: background 0.12s; }
.notif-card:last-child { border-bottom: none; }
.notif-card:hover { background: #f8fafc; }
.notif-card.unread { border-left: 3px solid #2872A1; background: #fafcff; }
.notif-icon-wrap { width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.notif-body { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.notif-top-row { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 4px; gap: 8px; }
.notif-title { font-size: 13.5px; font-weight: 700; color: #1e293b; }
.notif-time { font-size: 11px; color: #94a3b8; white-space: nowrap; flex-shrink: 0; }
.notif-msg { font-size: 12.5px; color: #64748b; line-height: 1.5; margin-bottom: 8px; }
.notif-tags { display: flex; gap: 6px; }
.notif-type-badge { font-size: 10px; font-weight: 600; padding: 2px 8px; border-radius: 5px; text-transform: capitalize; }
.unread-dot { width: 8px; height: 8px; border-radius: 50%; background: #2872A1; flex-shrink: 0; margin-top: 6px; }
.notif-action-row { margin-top: 2px; }
.notif-action-btn { background: #eff8ff; color: #2872A1; border: none; border-radius: 7px; padding: 6px 14px; font-size: 12px; font-weight: 600; cursor: pointer; font-family: inherit; }
.notif-action-btn:hover { background: #dbeafe; }

.sent-card { cursor: default; border-radius: 0; }
.sent-badge { font-size: 10px; font-weight: 700; padding: 2px 8px; border-radius: 6px; background: #f0fdf4; color: #22c55e; }
.sent-stats { display: flex; gap: 14px; margin-top: 4px; }
.sent-stat { display: flex; align-items: center; gap: 5px; font-size: 11.5px; color: #94a3b8; font-weight: 500; }

.empty-state { display: flex; flex-direction: column; align-items: center; gap: 10px; padding: 48px; color: #cbd5e1; font-size: 13px; background: #fff; border-radius: 12px; border: 1px solid #f1f5f9; }

/* MODAL */
.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.4); z-index: 100; display: flex; align-items: center; justify-content: center; backdrop-filter: blur(2px); }
.modal { background: #fff; border-radius: 16px; width: 500px; max-width: 95vw; box-shadow: 0 20px 60px rgba(0,0,0,0.15); max-height: 90vh; display: flex; flex-direction: column; }
.modal-header { display: flex; align-items: center; gap: 12px; padding: 20px 24px; border-bottom: 1px solid #f1f5f9; }
.modal-icon-wrap { width: 40px; height: 40px; background: #eff8ff; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.modal-title { font-size: 16px; font-weight: 800; color: #1e293b; }
.modal-sub { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.modal-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 18px; padding: 4px; border-radius: 6px; margin-left: auto; line-height: 1; }
.modal-close:hover { background: #f1f5f9; }
.modal-body { padding: 20px 24px; display: flex; flex-direction: column; gap: 14px; overflow-y: auto; flex: 1; }
.modal-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 16px 24px; border-top: 1px solid #f1f5f9; }
.form-group { display: flex; flex-direction: column; gap: 5px; }
.form-label { font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; }
.form-input { border: 1px solid #e2e8f0; border-radius: 8px; padding: 9px 12px; font-size: 13px; color: #1e293b; font-family: inherit; outline: none; background: #f8fafc; }
.form-input:focus { border-color: #08BDDE; background: #fff; }
.schedule-opts { display: flex; gap: 8px; }
.sched-opt { padding: 8px 18px; border-radius: 8px; border: 2px solid #e2e8f0; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; background: #f8fafc; color: #64748b; transition: all 0.15s; }
.sched-opt.active { border-color: #2872A1; background: #eff8ff; color: #2872A1; }
.btn-ghost { background: #f1f5f9; color: #64748b; border: none; border-radius: 10px; padding: 9px 18px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-ghost:hover { background: #e2e8f0; }
.btn-primary { display: flex; align-items: center; gap: 6px; background: #2872A1; color: #fff; border: none; border-radius: 10px; padding: 9px 18px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-primary:hover { background: #1a5f8a; }
.modal-enter-active, .modal-leave-active { transition: opacity 0.2s; }
.modal-enter-active .modal, .modal-leave-active .modal { transition: transform 0.2s, opacity 0.2s; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
.modal-enter-from .modal, .modal-leave-to .modal { transform: scale(0.95); opacity: 0; }

/* ── SKELETON ────────────────────────────────────────────────────── */
.skeleton {
  background: #e2e8f0;
  background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border: none !important;
}
@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
</style>