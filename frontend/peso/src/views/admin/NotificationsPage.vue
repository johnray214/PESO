<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Notifications</h1>
        <p class="page-sub">System alerts and send messages to jobseekers & employers</p>
      </div>
      <button class="btn-primary" @click="openCompose">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
        Send Notification
      </button>
    </div>

    <!-- Main Tabs -->
    <div class="main-tabs">
      <button v-for="tab in mainTabs" :key="tab.value" :class="['main-tab', { active: activeMainTab === tab.value }]" @click="activeMainTab = tab.value">
        <span v-html="tab.icon" class="tab-icon"></span>
        {{ tab.label }}
        <span v-if="tab.badge" class="tab-badge">{{ tab.badge }}</span>
      </button>
    </div>

    <!-- RECEIVED TAB -->
    <div v-if="activeMainTab === 'received'" class="tab-content">
      <div class="filters-bar">
        <div class="search-box">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <input v-model="search" type="text" placeholder="Search notifications…" class="search-input"/>
        </div>
        <div class="filter-group">
          <select v-model="filterNotifType" class="filter-select">
            <option value="">All Types</option>
            <option value="match">Job Match</option>
            <option value="registration">New Registration</option>
            <option value="event">Event</option>
            <option value="status">Status Change</option>
            <option value="system">System</option>
          </select>
          <button class="btn-ghost-sm" @click="markAllRead">Mark all read</button>
        </div>
      </div>

      <div class="notif-list">
        <div
          v-for="notif in filteredNotifs"
          :key="notif.id"
          :class="['notif-row', { unread: !notif.read }]"
          @click="markRead(notif)"
        >
          <div class="notif-icon-wrap" :style="{ background: notifTypeColor(notif.type).bg }">
            <span v-html="notifTypeIcon(notif.type)" :style="{ color: notifTypeColor(notif.type).text }"></span>
          </div>
          <div class="notif-body">
            <div class="notif-top">
              <p class="notif-title">{{ notif.title }}</p>
              <span class="notif-time">{{ notif.time }}</span>
            </div>
            <p class="notif-message">{{ notif.message }}</p>
            <div class="notif-tags">
              <span class="notif-type-tag" :style="{ background: notifTypeColor(notif.type).bg, color: notifTypeColor(notif.type).text }">{{ notif.type }}</span>
            </div>
          </div>
          <div v-if="!notif.read" class="unread-dot"></div>
        </div>
      </div>
    </div>

    <!-- SENT TAB -->
    <div v-if="activeMainTab === 'sent'" class="tab-content">
      <div class="sent-list">
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
                <label v-for="opt in recipientOptions" :key="opt.value" class="recip-option" :class="{ selected: form.recipients.includes(opt.value) }" @click="toggleRecipient(opt.value)">
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
export default {
  name: 'NotificationsPage',
  data() {
    return {
      activeMainTab: 'received',
      search: '',
      filterNotifType: '',
      showModal: false,
      form: { recipients: ['jobseekers'], filterSkill: '', filterLocation: '', subject: '', message: '', schedule: 'now', scheduleDate: '' },
      recipientOptions: [
        { value: 'jobseekers', label: 'All Jobseekers', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>` },
        { value: 'employers', label: 'All Employers', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>` },
        { value: 'specific', label: 'Specific Users', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/></svg>` },
      ],
      mainTabs: [
        { label: 'Received', value: 'received', badge: 3, icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>` },
        { label: 'Sent', value: 'sent', badge: null, icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>` },
      ],
      notifications: [
        { id: 1, type: 'match', title: 'New Job Match Found', message: 'Maria Santos matches the Web Developer posting at Accenture PH (92% match score).', time: '2 min ago', read: false },
        { id: 2, type: 'registration', title: 'New Jobseeker Registered', message: 'Carlo Bautista has registered as a new jobseeker. Skills: Driving, Delivery.', time: '15 min ago', read: false },
        { id: 3, type: 'event', title: 'Event Reminder', message: 'Job Fair 2024 — Quezon City is happening in 3 days. 158/200 slots filled.', time: '1 hour ago', read: false },
        { id: 4, type: 'status', title: 'Applicant Status Updated', message: 'Ana Reyes has been marked as Placed at Makati Medical Center.', time: '3 hours ago', read: true },
        { id: 5, type: 'registration', title: 'New Employer Registered', message: 'Nexus Tech has registered as a new employer. Pending verification.', time: '5 hours ago', read: true },
        { id: 6, type: 'system', title: 'System Backup Complete', message: 'Monthly data backup completed successfully. All records archived.', time: 'Yesterday', read: true },
        { id: 7, type: 'match', title: '3 New Job Matches', message: 'Pedro Lim matches 3 new job listings posted today in Caloocan and Valenzuela.', time: 'Yesterday', read: true },
      ],
      sentNotifs: [
        { id: 1, subject: 'Job Fair This December!', message: 'We are excited to invite you to the annual Job Fair 2024 happening on December 12 at QC Sports Club.', recipients: ['All Jobseekers', 'All Employers'], time: 'Dec 05, 2023 — 9:00 AM', delivered: 4821, read: 2140, status: 'Sent' },
        { id: 2, subject: 'New IT Job Vacancies Available', message: 'Several IT companies have posted new job openings this week. Check the listings now and apply!', recipients: ['IT / Dev Jobseekers'], time: 'Dec 03, 2023 — 2:00 PM', delivered: 342, read: 198, status: 'Sent' },
        { id: 3, subject: 'Livelihood Seminar on Dec 18', message: 'Join our Livelihood Seminar Series on December 18 at City Hall Annex. Free registration!', recipients: ['All Jobseekers'], time: 'Dec 10, 2023 — 8:00 AM', delivered: 0, read: 0, status: 'Scheduled' },
      ]
    }
  },
  computed: {
    filteredNotifs() {
      return this.notifications.filter(n => {
        const matchSearch = !this.search || n.title.toLowerCase().includes(this.search.toLowerCase()) || n.message.toLowerCase().includes(this.search.toLowerCase())
        const matchType = !this.filterNotifType || n.type === this.filterNotifType
        return matchSearch && matchType
      })
    },
    stripStats() {
      const n = this.notifications
      return [
        { label: 'Total', value: n.length, color: '#1e293b' },
        { label: 'Unread', value: n.filter(x => !x.read).length, color: '#2563eb' },
        { label: 'Job Matches', value: n.filter(x => x.type === 'match').length, color: '#22c55e' },
        { label: 'Registrations', value: n.filter(x => x.type === 'registration').length, color: '#f97316' },
        { label: 'Sent Today', value: 2, color: '#06b6d4' },
      ]
    }
  },
  methods: {
    notifTypeColor(type) {
      return { match: { bg: '#dcfce7', text: '#22c55e' }, registration: { bg: '#dbeafe', text: '#2563eb' }, event: { bg: '#fff7ed', text: '#f97316' }, status: { bg: '#fdf4ff', text: '#a21caf' }, system: { bg: '#f1f5f9', text: '#64748b' } }[type] || { bg: '#f1f5f9', text: '#64748b' }
    },
    notifTypeIcon(type) {
      const icons = {
        match: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>`,
        registration: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><line x1="20" y1="8" x2="20" y2="14"/><line x1="23" y1="11" x2="17" y2="11"/></svg>`,
        event: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>`,
        status: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>`,
        system: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>`,
      }
      return icons[type] || icons.system
    },
    markRead(notif) { notif.read = true },
    markAllRead() { this.notifications.forEach(n => n.read = true) },
    toggleRecipient(val) {
      const idx = this.form.recipients.indexOf(val)
      if (idx > -1) this.form.recipients.splice(idx, 1)
      else this.form.recipients.push(val)
    },
    openCompose() { this.form = { recipients: ['jobseekers'], filterSkill: '', filterLocation: '', subject: '', message: '', schedule: 'now', scheduleDate: '' }; this.showModal = true },
    sendNotification() {
      this.sentNotifs.unshift({ id: Date.now(), subject: this.form.subject, message: this.form.message, recipients: this.form.recipients.map(r => r === 'jobseekers' ? 'All Jobseekers' : r === 'employers' ? 'All Employers' : 'Specific Users'), time: 'Just now', delivered: this.form.schedule === 'now' ? 4821 : 0, read: 0, status: this.form.schedule === 'now' ? 'Sent' : 'Scheduled' })
      this.showModal = false
      this.activeMainTab = 'sent'
    }
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

.page { font-family: 'Plus Jakarta Sans', sans-serif; padding: 24px; background: #f8fafc; min-height: 0; display: flex; flex-direction: column; gap: 16px; }
.page-header { display: flex; align-items: flex-start; justify-content: space-between; }
.page-title { font-size: 20px; font-weight: 800; color: #1e293b; }
.page-sub { font-size: 12px; color: #94a3b8; margin-top: 2px; }
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
