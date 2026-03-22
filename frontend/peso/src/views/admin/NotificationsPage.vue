<template>
  <div class="page">
    <!-- SKELETON -->
    <template v-if="loading">
      <div class="notifications-header" style="display: flex; justify-content: space-between; align-items: center;">
        <div class="main-tabs" style="display: flex; gap: 10px;">
          <div class="skel" style="width: 120px; height: 38px; border-radius: 8px;"></div>
          <div class="skel" style="width: 140px; height: 38px; border-radius: 8px;"></div>
        </div>
        <div class="skel" style="width: 160px; height: 38px; border-radius: 10px;"></div>
      </div>
      <div class="tab-content" style="margin-top: 12px;">
        <div class="notif-list" style="padding: 16px;">
          <div v-for="i in 5" :key="i" class="skel" style="width: 100%; height: 70px; border-radius: 10px; margin-bottom: 10px;"></div>
        </div>
      </div>
    </template>

    <!-- ACTUAL CONTENT -->
    <template v-else>
    <div class="notifications-header" style="display: flex; justify-content: space-between; align-items: center;">
      <div class="main-tabs">
        <button class="main-tab" :class="{ active: activeTab === 'feed' }" @click="activeTab = 'feed'">Activity Feed</button>
        <button class="main-tab" :class="{ active: activeTab === 'sent' }" @click="activeTab = 'sent'">Sent Notifications</button>
      </div>
      <button class="btn-primary" @click="openCompose">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
        Send Notification
      </button>
    </div>

    <!-- NOTIFICATIONS LIST -->
      <div class="tab-content" style="margin-top: 12px;">
        
        <!-- ACTIVITY FEED -->
      <div v-if="activeTab === 'feed'" class="notif-list">
        <div v-if="feedNotifs.length === 0" style="padding: 30px; text-align: center; color: #94a3b8; font-size: 13px;">No recent activity found.</div>
        <div v-for="notif in feedNotifs" :key="notif.id" :class="['notif-row', { unread: !notif.read }]" @click="markAsRead(notif)">
          <div class="notif-icon-wrap" :style="getIconStyle(notif.type)" v-html="getIconPath(notif.type)"></div>
          <div class="notif-body">
            <div class="notif-top">
              <span class="notif-title">{{ notif.title }}</span>
              <span class="notif-time">{{ notif.time }}</span>
            </div>
            <p class="notif-message">{{ notif.message }}</p>
            <div class="notif-tags">
              <span class="notif-type-tag" :style="getTagStyle(notif.type)">{{ notif.type }}</span>
            </div>
          </div>
          <div v-if="!notif.read" class="unread-dot"></div>
        </div>
      </div>

      <!-- SENT NOTIFICATIONS -->
      <div v-if="activeTab === 'sent'" class="sent-list">
        <div v-for="sent in sentNotifs" :key="sent.id" class="sent-card">
          <div class="sent-header">
            <div class="sent-title-row">
              <p class="sent-subject">{{ sent.subject }}</p>
              <span class="status-badge" :class="sent.status === 'Sent' ? 'sent-s' : 'sched-s'">{{ sent.status }}</span>
            </div>
            <p class="sent-time">{{ sent.time }}</p>
          </div>
          <p class="sent-message">{{ sent.message }}</p>
          <div class="sent-footer">
            <div class="sent-recipients">
              <span class="recip-chip" v-for="r in sent.recipients" :key="r">{{ r }}</span>
            </div>
            <div class="sent-stats">
              <span class="stat-chip">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07A19.5 19.5 0 013.07 9.81a19.79 19.79 0 01-3.07-8.63A2 2 0 012.18 1h3a2 2 0 012 1.72 12.84 12.84 0 00.7 2.81 2 2 0 01-.45 2.11L6.59 8a16 16 0 006.35 6.35l.86-.86a2 2 0 012.11-.45 12.84 12.84 0 002.81.7A2 2 0 0122 16.92z"/></svg>
                {{ sent.delivered }} delivered
              </span>
              <span class="stat-chip read-chip">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                {{ sent.read }} read
              </span>
            </div>
          </div>
        </div>
      </div>
      </div>
    </template>

    <!-- COMPOSE MODAL -->
    <transition name="modal">
      <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
        <div class="modal">
          <div class="modal-header">
            <h3>Send Notification</h3>
            <button class="modal-close" @click="showModal = false">✕</button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label class="form-label">Recipients</label>
              <div class="recipient-options">
                <label v-for="opt in recipientOptions" :key="opt.value" class="recip-option" :class="{ selected: form.recipients === opt.value }" @click="form.recipients = opt.value">
                  <span v-html="opt.icon" class="recip-icon"></span>
                  {{ opt.label }}
                </label>
              </div>
            </div>
            <div class="form-group">
              <label class="form-label">Filter By (optional)</label>
              <div class="form-row">
                <select v-model="form.filterSkill" class="form-input">
                  <option value="">All Skills</option>
                  <option>IT / Dev</option>
                  <option>Nursing</option>
                  <option>Accounting</option>
                  <option>Electrical</option>
                </select>
                <select v-model="form.filterLocation" class="form-input">
                  <option value="">All Locations</option>
                  <option>Quezon City</option>
                  <option>Marikina</option>
                  <option>Pasig</option>
                  <option>Taguig</option>
                </select>
              </div>
            </div>
            <div class="form-group">
              <label class="form-label">Subject</label>
              <input v-model="form.subject" class="form-input" placeholder="e.g. Job Fair This December!"/>
            </div>
            <div class="form-group">
              <label class="form-label">Message</label>
              <textarea v-model="form.message" class="form-textarea" placeholder="Write your message here…" rows="4"></textarea>
            </div>
            <div class="form-group">
              <label class="form-label">Schedule</label>
              <div class="schedule-options">
                <label class="sched-opt" :class="{ active: form.schedule === 'now' }">
                  <input type="radio" v-model="form.schedule" value="now"/> Send Now
                </label>
                <label class="sched-opt" :class="{ active: form.schedule === 'later' }">
                  <input type="radio" v-model="form.schedule" value="later"/> Schedule
                </label>
              </div>
              <input v-if="form.schedule === 'later'" v-model="form.scheduleDate" type="datetime-local" class="form-input" style="margin-top: 8px;"/>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn-ghost" @click="showModal = false">Cancel</button>
            <button class="btn-primary" @click="sendNotification">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
              {{ form.schedule === 'later' ? 'Schedule' : 'Send Now' }}
            </button>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
import api from '@/services/api'
import { useAdminAppStore } from '@/stores/adminAppStore'

export default {
  name: 'NotificationsPage',
  async mounted() {
    await this.fetchNotifications()
    const store = useAdminAppStore()
    await store.fetchNotifications()
    this.loading = false
  },
  computed: {
    feedNotifs() {
      return useAdminAppStore().notifications
    }
  },
  data() {
    return {
      activeTab: 'feed',
      showModal: false,
      loading: true,
      form: { recipients: 'jobseekers', filterSkill: '', filterLocation: '', subject: '', message: '', schedule: 'now', scheduleDate: '' },
      recipientOptions: [
        { value: 'jobseekers', label: 'All Jobseekers', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>` },
        { value: 'employers', label: 'All Employers', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>` },
        { value: 'specific', label: 'Specific Users', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/></svg>` },
      ],
      sentNotifs: []
    }
  },
  methods: {
    async fetchNotifications() {
      try {
        const res = await api.get('/admin/notifications')
        const items = res.data.data?.data || res.data.data || res.data
        this.sentNotifs = items.map(n => ({
          id: n.id,
          subject: n.subject,
          message: n.message,
          recipients: [n.recipients === 'jobseekers' ? 'All Jobseekers' : n.recipients === 'employers' ? 'All Employers' : 'Specific Users'],
          time: new Date(n.created_at).toLocaleString(),
          delivered: 0,
          read: 0,
          status: n.status ? n.status.charAt(0).toUpperCase() + n.status.slice(1) : 'Sent'
        }))
      } catch (err) {
        console.error('Error fetching notifications:', err)
      }
    },
    openCompose() { 
      this.form = { recipients: 'jobseekers', filterSkill: '', filterLocation: '', subject: '', message: '', schedule: 'now', scheduleDate: '' }; 
      this.showModal = true 
    },
    async sendNotification() {
      try {
        await api.post('/admin/notifications', {
          subject: this.form.subject,
          message: this.form.message,
          recipients: this.form.recipients,
          scheduled_at: this.form.schedule === 'later' && this.form.scheduleDate ? this.form.scheduleDate : null
        })
        await this.fetchNotifications()
        this.showModal = false
      } catch (e) {
        console.error('Failed to send notification:', e)
      }
    },
    async markAsRead(notif) {
      if (notif.read) return;
      const store = useAdminAppStore()
      store.markRead(notif.id)
    },
    getIconStyle(type) {
      if (type === 'Registration') return { background: '#dbeafe', color: '#2563eb' }
      if (type === 'Status') return { background: '#fef9c3', color: '#ca8a04' }
      if (type === 'Event') return { background: '#dcfce7', color: '#16a34a' }
      return { background: '#f8fafc', color: '#64748b' }
    },
    getTagStyle(type) {
      if (type === 'Registration') return { background: '#eff6ff', color: '#2563eb' }
      if (type === 'Status') return { background: '#fefce8', color: '#ca8a04' }
      if (type === 'Event') return { background: '#f0fdf4', color: '#16a34a' }
      return { background: '#f8fafc', color: '#64748b' }
    },
    getIconPath(type) {
      if (type === 'Registration') return `<svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>`
      if (type === 'Status') return `<svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>`
      if (type === 'Event') return `<svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>`
      return `<svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>`
    }
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

@keyframes shimmer { 0% { background-position: -400px 0; } 100% { background-position: 400px 0; } }
.skel {
  background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%);
  background-size: 400px 100%; animation: shimmer 1.4s infinite linear;
  border-radius: 6px; flex-shrink: 0;
}

.page { font-family: 'Plus Jakarta Sans', sans-serif; padding: 24px; background: #f8fafc; min-height: 0; display: flex; flex-direction: column; gap: 16px; }
.btn-primary { display: flex; align-items: center; gap: 6px; background: #2563eb; color: #fff; border: none; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-primary:hover { background: #1d4ed8; }
.btn-ghost { background: #f1f5f9; color: #64748b; border: none; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }

.stats-strip {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 14px;
}
.strip-stat {
  background: #fff;
  border-radius: 0;
  padding: 18px 16px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  border: 1px solid #e2e8f0;
  border-left: 4px solid var(--accent, #94a3b8);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  transition: box-shadow 0.2s ease, border-color 0.2s ease;
}
.strip-stat:hover {
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.08);
  border-color: #cbd5e1;
}
.strip-val { font-size: 24px; font-weight: 800; line-height: 1.2; letter-spacing: -0.02em; }
.strip-label { font-size: 11.5px; color: #64748b; margin-top: 6px; font-weight: 500; }

.main-tabs { display: flex; gap: 4px; background: #fff; border-radius: 12px; padding: 6px; border: 1px solid #f1f5f9; width: fit-content; }
.main-tab { display: flex; align-items: center; gap: 8px; background: none; border: none; padding: 9px 18px; font-size: 13px; font-weight: 600; color: #64748b; cursor: pointer; border-radius: 8px; font-family: inherit; transition: all 0.15s; }
.main-tab.active { background: #2563eb; color: #fff; }
.tab-icon { display: flex; align-items: center; }
.tab-badge { background: #ef4444; color: #fff; font-size: 10px; font-weight: 700; padding: 2px 6px; border-radius: 99px; }
.main-tab.active .tab-badge { background: rgba(255,255,255,0.3); }

.tab-content { display: flex; flex-direction: column; gap: 12px; }

.filters-bar { display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; flex: 1; max-width: 360px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-group { display: flex; align-items: center; gap: 8px; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }
.btn-ghost-sm { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; font-family: inherit; }

/* NOTIFICATIONS */
.notif-list { background: #fff; border-radius: 14px; overflow: hidden; border: 1px solid #f1f5f9; }
.notif-row { display: flex; align-items: flex-start; gap: 14px; padding: 16px 18px; border-bottom: 1px solid #f8fafc; cursor: pointer; transition: background 0.12s; position: relative; }
.notif-row:last-child { border-bottom: none; }
.notif-row:hover { background: #f8fafc; }
.notif-row.unread { background: #f8faff; }

.notif-icon-wrap { width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.notif-body { flex: 1; min-width: 0; }
.notif-top { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 4px; gap: 8px; }
.notif-title { font-size: 13.5px; font-weight: 700; color: #1e293b; }
.notif-time { font-size: 11px; color: #94a3b8; white-space: nowrap; flex-shrink: 0; }
.notif-message { font-size: 12.5px; color: #64748b; line-height: 1.5; margin-bottom: 8px; }
.notif-tags { display: flex; gap: 6px; }
.notif-type-tag { font-size: 10px; font-weight: 600; padding: 2px 8px; border-radius: 5px; text-transform: capitalize; }
.unread-dot { width: 8px; height: 8px; background: #2563eb; border-radius: 50%; flex-shrink: 0; margin-top: 6px; }

/* SENT */
.sent-list { display: flex; flex-direction: column; gap: 12px; }
.sent-card { background: #fff; border-radius: 14px; padding: 18px; border: 1px solid #f1f5f9; }
.sent-header { margin-bottom: 10px; }
.sent-title-row { display: flex; align-items: center; justify-content: space-between; margin-bottom: 4px; }
.sent-subject { font-size: 15px; font-weight: 700; color: #1e293b; }
.status-badge { padding: 4px 10px; border-radius: 99px; font-size: 11px; font-weight: 600; white-space: nowrap; }
.sent-s { background: #dcfce7; color: #22c55e; }
.sched-s { background: #fff7ed; color: #f97316; }
.sent-time { font-size: 11px; color: #94a3b8; }
.sent-message { font-size: 13px; color: #64748b; line-height: 1.5; margin-bottom: 12px; }
.sent-footer { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 8px; }
.sent-recipients { display: flex; gap: 6px; flex-wrap: wrap; }
.recip-chip { background: #eff6ff; color: #2563eb; font-size: 11px; font-weight: 600; padding: 3px 10px; border-radius: 6px; }
.sent-stats { display: flex; gap: 8px; }
.stat-chip { display: flex; align-items: center; gap: 5px; font-size: 11.5px; color: #64748b; background: #f1f5f9; padding: 4px 10px; border-radius: 6px; }
.read-chip { color: #2563eb; background: #eff6ff; }

/* MODAL */
.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.4); z-index: 100; display: flex; align-items: center; justify-content: center; backdrop-filter: blur(2px); }
.modal { background: #fff; border-radius: 16px; width: 540px; max-width: 95vw; box-shadow: 0 20px 60px rgba(0,0,0,0.15); }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 18px 20px; border-bottom: 1px solid #f1f5f9; }
.modal-header h3 { font-size: 16px; font-weight: 800; color: #1e293b; }
.modal-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 16px; padding: 4px; border-radius: 6px; }
.modal-body { padding: 20px; display: flex; flex-direction: column; gap: 16px; max-height: 65vh; overflow-y: auto; }
.modal-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 16px 20px; border-top: 1px solid #f1f5f9; }

.form-group { display: flex; flex-direction: column; gap: 6px; }
.form-label { font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; }
.form-input { border: 1px solid #e2e8f0; border-radius: 8px; padding: 9px 12px; font-size: 13px; color: #1e293b; font-family: inherit; outline: none; background: #f8fafc; }
.form-input:focus { border-color: #93c5fd; background: #fff; }
.form-textarea { border: 1px solid #e2e8f0; border-radius: 8px; padding: 9px 12px; font-size: 13px; color: #1e293b; font-family: inherit; outline: none; resize: vertical; background: #f8fafc; }
.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }

.recipient-options { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
.recip-option { display: flex; align-items: center; gap: 8px; padding: 10px 12px; border-radius: 10px; border: 2px solid #e2e8f0; cursor: pointer; font-size: 12.5px; color: #475569; font-weight: 500; transition: all 0.15s; background: #f8fafc; }
.recip-option.selected { border-color: #2563eb; background: #eff6ff; color: #2563eb; }
.recip-icon { display: flex; align-items: center; }

.schedule-options { display: flex; gap: 10px; }
.sched-opt { display: flex; align-items: center; gap: 8px; padding: 8px 16px; border-radius: 8px; border: 2px solid #e2e8f0; cursor: pointer; font-size: 13px; color: #475569; font-family: inherit; transition: all 0.15s; }
.sched-opt.active { border-color: #2563eb; background: #eff6ff; color: #2563eb; }
.sched-opt input { accent-color: #2563eb; }

.modal-enter-active, .modal-leave-active { transition: opacity 0.2s; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
</style>
