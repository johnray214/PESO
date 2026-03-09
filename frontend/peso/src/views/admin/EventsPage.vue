<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Events</h1>
        <p class="page-sub">Manage job fairs, seminars, and programs</p>
      </div>
      <div class="header-actions">
        <div class="view-toggle">
          <button :class="['toggle-btn', { active: view === 'list' }]" @click="view = 'list'">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/></svg>
            List
          </button>
          <button :class="['toggle-btn', { active: view === 'calendar' }]" @click="view = 'calendar'">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
            Calendar
          </button>
        </div>
        <button class="btn-primary" @click="openCreateModal">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          Create Event
        </button>
      </div>
    </div>

    <!-- Filters -->
    <div class="filters-bar">
      <div class="search-box">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        <input v-model="search" type="text" placeholder="Search events…" class="search-input"/>
      </div>
      <div class="filter-group">
        <select v-model="filterType" class="filter-select">
          <option value="">All Types</option>
          <option v-for="t in eventTypes" :key="t" :value="t">{{ t }}</option>
        </select>
        <select v-model="filterStatus" class="filter-select">
          <option value="">All Status</option>
          <option value="Upcoming">Upcoming</option>
          <option value="Ongoing">Ongoing</option>
          <option value="Completed">Completed</option>
          <option value="Cancelled">Cancelled</option>
        </select>
      </div>
    </div>

    <!-- Status Tabs -->
    <div class="status-tabs">
      <button v-for="tab in statusTabs" :key="tab.value"
        :class="['tab-btn', { active: activeTab === tab.value }]"
        @click="activeTab = tab.value">
        {{ tab.label }} <span class="tab-count" :class="tab.cls">{{ tab.count }}</span>
      </button>
    </div>

    <!-- LIST VIEW -->
    <div v-if="view === 'list'" class="events-list">
      <div v-for="event in filteredEvents" :key="event.id" class="event-card">
        <div class="event-date-col">
          <div class="date-box" :style="{ background: typeColor(event.type).bg, color: typeColor(event.type).text }">
            <span class="date-day">{{ event.day }}</span>
            <span class="date-month">{{ event.month }}</span>
            <span class="date-year">{{ event.year }}</span>
          </div>
        </div>
        <div class="event-main">
          <div class="event-top">
            <div>
              <div class="event-title-row">
                <h3 class="event-title">{{ event.title }}</h3>
                <span class="type-badge" :style="{ background: typeColor(event.type).bg, color: typeColor(event.type).text }">{{ event.type }}</span>
              </div>
              <p class="event-desc">{{ event.description }}</p>
            </div>
            <span class="status-badge" :class="eventStatusClass(event.status)">{{ event.status }}</span>
          </div>
          <div class="event-meta-row">
            <span class="meta-item">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
              {{ event.venue }}
            </span>
            <span class="meta-item">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
              {{ event.time }}
            </span>
            <span class="meta-item">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
              {{ event.registered }}/{{ event.slots }} registered
            </span>
          </div>
          <div class="slots-bar-wrap">
            <div class="slots-bar">
              <div class="slots-fill" :style="{ width: (event.registered / event.slots * 100) + '%', background: typeColor(event.type).text }"></div>
            </div>
            <span class="slots-pct">{{ Math.round(event.registered / event.slots * 100) }}% full</span>
          </div>
        </div>
        <div class="event-actions">
          <button class="act-btn view" @click="openViewModal(event)" title="View Registrants">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
          </button>
          <button class="act-btn edit" @click="openEditModal(event)" title="Edit">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
          </button>
          <button class="act-btn delete" @click="archiveEvent(event)" title="Archive">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="21 8 21 21 3 21 3 8"/><rect x="1" y="3" width="22" height="5"/><line x1="10" y1="12" x2="14" y2="12"/></svg>
          </button>
        </div>
      </div>
    </div>

    <!-- CALENDAR VIEW -->
    <div v-if="view === 'calendar'" class="calendar-card">
      <div class="cal-header">
        <button class="cal-nav" @click="prevMonth">‹</button>
        <h3 class="cal-month">{{ calMonthLabel }}</h3>
        <button class="cal-nav" @click="nextMonth">›</button>
      </div>
      <div class="cal-grid">
        <div v-for="d in ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']" :key="d" class="cal-day-label">{{ d }}</div>
        <div v-for="(cell, i) in calCells" :key="i"
          :class="['cal-cell', { empty: !cell.day, today: cell.isToday, has: cell.events.length > 0 }]">
          <span v-if="cell.day" class="cal-date">{{ cell.day }}</span>
          <div class="cal-events">
            <div v-for="ev in cell.events.slice(0,2)" :key="ev.id"
              class="cal-event-dot"
              :style="{ background: typeColor(ev.type).text }"
              :title="ev.title">
              {{ ev.title.slice(0,14) }}{{ ev.title.length > 14 ? '…' : '' }}
            </div>
            <div v-if="cell.events.length > 2" class="cal-more">+{{ cell.events.length - 2 }} more</div>
          </div>
        </div>
      </div>
    </div>

    <!-- CREATE / EDIT MODAL -->
    <transition name="modal">
      <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
        <div class="modal">
          <div class="modal-header">
            <h3>{{ editingEvent ? 'Edit Event' : 'Create New Event' }}</h3>
            <button class="drawer-close" @click="showModal = false">✕</button>
          </div>
          <div class="modal-body">
            <div class="form-row">
              <div class="form-group">
                <label class="form-label">Event Title</label>
                <input v-model="form.title" class="form-input" placeholder="e.g. Job Fair 2024"/>
              </div>
              <div class="form-group">
                <label class="form-label">Event Type</label>
                <select v-model="form.type" class="form-input">
                  <option v-for="t in eventTypes" :key="t" :value="t">{{ t }}</option>
                </select>
              </div>
            </div>
            <div class="form-group">
              <label class="form-label">Description</label>
              <textarea v-model="form.description" class="form-textarea" placeholder="Describe the event…" rows="2"></textarea>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label class="form-label">Date</label>
                <input v-model="form.date" type="date" class="form-input"/>
              </div>
              <div class="form-group">
                <label class="form-label">Time</label>
                <input v-model="form.time" type="time" class="form-input"/>
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label class="form-label">Venue</label>
                <input v-model="form.venue" class="form-input" placeholder="e.g. QC Sports Club"/>
              </div>
              <div class="form-group">
                <label class="form-label">Max Slots</label>
                <input v-model="form.slots" type="number" class="form-input" placeholder="200"/>
              </div>
            </div>
            <div class="notify-row">
              <p class="form-label">Notify via notifications:</p>
              <label class="checkbox-label"><input type="checkbox" v-model="form.notifyJobseekers" accent-color="#2563eb"/> Jobseekers</label>
              <label class="checkbox-label"><input type="checkbox" v-model="form.notifyEmployers" accent-color="#2563eb"/> Employers</label>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn-ghost" @click="showModal = false">Cancel</button>
            <button class="btn-primary" @click="saveEvent">{{ editingEvent ? 'Save Changes' : 'Create Event' }}</button>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
export default {
  name: 'EventsPage',
  data() {
    const now = new Date()
    return {
      view: 'list',
      search: '',
      filterType: '',
      filterStatus: '',
      activeTab: 'all',
      showModal: false,
      editingEvent: null,
      calYear: now.getFullYear(),
      calMonth: now.getMonth(),
      form: { title: '', type: 'Job Fair', description: '', date: '', time: '', venue: '', slots: '', notifyJobseekers: true, notifyEmployers: false },
      eventTypes: ['Job Fair', 'Seminar', 'Training', 'Livelihood Program', 'Workshop'],
      statusTabs: [
        { label: 'All', value: 'all', count: 5, cls: '' },
        { label: 'Upcoming', value: 'Upcoming', count: 3, cls: 'upcoming-cls' },
        { label: 'Ongoing', value: 'Ongoing', count: 1, cls: 'ongoing-cls' },
        { label: 'Completed', value: 'Completed', count: 1, cls: 'completed-cls' },
      ],
      events: [
        { id: 1, title: 'Job Fair 2024 — Quezon City', type: 'Job Fair', description: 'Annual job fair connecting top employers with qualified jobseekers.', day: '12', month: 'DEC', year: '2024', date: '2024-12-12', time: '8:00 AM – 5:00 PM', venue: 'QC Sports Club, Quezon City', slots: 200, registered: 158, status: 'Upcoming' },
        { id: 2, title: 'Livelihood Seminar Series', type: 'Seminar', description: 'A series of livelihood seminars for unemployed residents.', day: '18', month: 'DEC', year: '2024', date: '2024-12-18', time: '9:00 AM – 12:00 PM', venue: 'City Hall Annex, Manila', slots: 80, registered: 45, status: 'Upcoming' },
        { id: 3, title: 'BPO Skills Training', type: 'Training', description: 'Hands-on BPO and call center readiness training program.', day: '22', month: 'DEC', year: '2024', date: '2024-12-22', time: '1:00 PM – 5:00 PM', venue: 'TESDA Center, Marikina', slots: 50, registered: 50, status: 'Ongoing' },
        { id: 4, title: 'Carpentry & Welding Workshop', type: 'Workshop', description: 'Practical skills workshop for NCII certification.', day: '01', month: 'DEC', year: '2024', date: '2024-12-01', time: '8:00 AM – 4:00 PM', venue: 'PESO Training Hall', slots: 30, registered: 30, status: 'Completed' },
        { id: 5, title: 'Negosyo sa Barangay Program', type: 'Livelihood Program', description: 'Micro-enterprise training for barangay residents.', day: '28', month: 'DEC', year: '2024', date: '2024-12-28', time: '9:00 AM – 3:00 PM', venue: 'Brgy. Hall, Caloocan', slots: 60, registered: 12, status: 'Upcoming' },
      ]
    }
  },
  computed: {
    filteredEvents() {
      return this.events.filter(e => {
        const matchTab = this.activeTab === 'all' || e.status === this.activeTab
        const matchSearch = !this.search || e.title.toLowerCase().includes(this.search.toLowerCase())
        const matchType = !this.filterType || e.type === this.filterType
        const matchStatus = !this.filterStatus || e.status === this.filterStatus
        return matchTab && matchSearch && matchType && matchStatus
      })
    },
    stripStats() {
      const e = this.events
      return [
        { label: 'Total Events', value: e.length, color: '#1e293b' },
        { label: 'Upcoming', value: e.filter(x => x.status === 'Upcoming').length, color: '#2563eb' },
        { label: 'Ongoing', value: e.filter(x => x.status === 'Ongoing').length, color: '#f97316' },
        { label: 'Completed', value: e.filter(x => x.status === 'Completed').length, color: '#22c55e' },
        { label: 'Total Registered', value: e.reduce((s, x) => s + x.registered, 0), color: '#06b6d4' },
      ]
    },
    calMonthLabel() {
      return new Date(this.calYear, this.calMonth).toLocaleString('default', { month: 'long', year: 'numeric' })
    },
    calCells() {
      const firstDay = new Date(this.calYear, this.calMonth, 1).getDay()
      const daysInMonth = new Date(this.calYear, this.calMonth + 1, 0).getDate()
      const today = new Date()
      const cells = []
      for (let i = 0; i < firstDay; i++) cells.push({ day: null, isToday: false, events: [] })
      for (let d = 1; d <= daysInMonth; d++) {
        const isToday = today.getDate() === d && today.getMonth() === this.calMonth && today.getFullYear() === this.calYear
        const dateStr = `${this.calYear}-${String(this.calMonth+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`
        const dayEvents = this.events.filter(e => e.date === dateStr)
        cells.push({ day: d, isToday, events: dayEvents })
      }
      return cells
    }
  },
  methods: {
    typeColor(type) {
      const map = {
        'Job Fair': { bg: '#dbeafe', text: '#2563eb' },
        'Seminar': { bg: '#fff7ed', text: '#f97316' },
        'Training': { bg: '#dcfce7', text: '#16a34a' },
        'Livelihood Program': { bg: '#fdf4ff', text: '#a21caf' },
        'Workshop': { bg: '#fef9c3', text: '#ca8a04' },
      }
      return map[type] || { bg: '#f1f5f9', text: '#64748b' }
    },
    eventStatusClass(s) {
      return { 'Upcoming': 'upcoming-s', 'Ongoing': 'ongoing-s', 'Completed': 'completed-s', 'Cancelled': 'cancelled-s' }[s] || ''
    },
    openCreateModal() {
      this.editingEvent = null
      this.form = { title: '', type: 'Job Fair', description: '', date: '', time: '', venue: '', slots: '', notifyJobseekers: true, notifyEmployers: false }
      this.showModal = true
    },
    openEditModal(event) {
      this.editingEvent = event
      this.form = { ...event, notifyJobseekers: false, notifyEmployers: false }
      this.showModal = true
    },
    openViewModal(event) { alert(`Viewing registrants for: ${event.title}`) },
    saveEvent() {
      if (this.editingEvent) {
        Object.assign(this.editingEvent, this.form)
      } else {
        this.events.push({ id: Date.now(), ...this.form, registered: 0, day: this.form.date.split('-')[2], month: new Date(this.form.date).toLocaleString('default', { month: 'short' }).toUpperCase(), year: this.form.date.split('-')[0], status: 'Upcoming' })
      }
      this.showModal = false
    },
    archiveEvent(event) { this.events = this.events.filter(e => e.id !== event.id) },
    prevMonth() { if (this.calMonth === 0) { this.calMonth = 11; this.calYear-- } else this.calMonth-- },
    nextMonth() { if (this.calMonth === 11) { this.calMonth = 0; this.calYear++ } else this.calMonth++ },
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
.header-actions { display: flex; align-items: center; gap: 10px; }

.view-toggle { display: flex; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; overflow: hidden; }
.toggle-btn { display: flex; align-items: center; gap: 6px; background: none; border: none; padding: 8px 14px; font-size: 12.5px; font-weight: 500; color: #64748b; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.toggle-btn.active { background: #2563eb; color: #fff; }

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

.filters-bar { display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; flex: 1; max-width: 360px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-group { display: flex; align-items: center; gap: 8px; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }

.status-tabs { display: flex; gap: 4px; }
.tab-btn { display: flex; align-items: center; gap: 6px; background: none; border: none; padding: 8px 14px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; border-radius: 8px; font-family: inherit; transition: all 0.15s; }
.tab-btn.active { background: #eff6ff; color: #2563eb; font-weight: 700; }
.tab-count { font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }
.tab-count.upcoming-cls { background: #dbeafe; color: #2563eb; }
.tab-count.ongoing-cls { background: #fff7ed; color: #f97316; }
.tab-count.completed-cls { background: #dcfce7; color: #22c55e; }

/* EVENT CARDS */
.events-list { display: flex; flex-direction: column; gap: 12px; }
.event-card { background: #fff; border-radius: 14px; padding: 18px; display: flex; gap: 18px; align-items: flex-start; border: 1px solid #f1f5f9; transition: box-shadow 0.15s; }
.event-card:hover { box-shadow: 0 4px 20px rgba(0,0,0,0.06); }

.event-date-col { flex-shrink: 0; }
.date-box { width: 56px; border-radius: 12px; padding: 10px 6px; display: flex; flex-direction: column; align-items: center; gap: 1px; }
.date-day { font-size: 22px; font-weight: 800; line-height: 1; }
.date-month { font-size: 10px; font-weight: 700; text-transform: uppercase; }
.date-year { font-size: 9px; opacity: 0.7; }

.event-main { flex: 1; min-width: 0; }
.event-top { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 8px; }
.event-title-row { display: flex; align-items: center; gap: 8px; margin-bottom: 4px; }
.event-title { font-size: 15px; font-weight: 700; color: #1e293b; }
.type-badge { font-size: 10px; font-weight: 700; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
.event-desc { font-size: 12px; color: #64748b; line-height: 1.4; }

.event-meta-row { display: flex; align-items: center; gap: 16px; margin: 10px 0 8px; flex-wrap: wrap; }
.meta-item { display: flex; align-items: center; gap: 5px; font-size: 12px; color: #94a3b8; }

.slots-bar-wrap { display: flex; align-items: center; gap: 10px; }
.slots-bar { flex: 1; height: 4px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.slots-fill { height: 100%; border-radius: 99px; transition: width 0.3s; }
.slots-pct { font-size: 11px; color: #94a3b8; white-space: nowrap; font-weight: 600; }

.status-badge { padding: 4px 10px; border-radius: 99px; font-size: 11px; font-weight: 600; white-space: nowrap; }
.upcoming-s { background: #dbeafe; color: #2563eb; }
.ongoing-s { background: #fff7ed; color: #f97316; }
.completed-s { background: #dcfce7; color: #22c55e; }
.cancelled-s { background: #fef2f2; color: #ef4444; }

.event-actions { display: flex; flex-direction: column; gap: 6px; }
.act-btn { width: 30px; height: 30px; border-radius: 8px; border: none; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.15s; }
.act-btn.view { background: #f0fdf4; color: #22c55e; }
.act-btn.edit { background: #eff6ff; color: #2563eb; }
.act-btn.delete { background: #fef2f2; color: #ef4444; }

/* CALENDAR */
.calendar-card { background: #fff; border-radius: 14px; padding: 20px; border: 1px solid #f1f5f9; }
.cal-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px; }
.cal-month { font-size: 15px; font-weight: 700; color: #1e293b; }
.cal-nav { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; width: 32px; height: 32px; cursor: pointer; font-size: 16px; color: #64748b; display: flex; align-items: center; justify-content: center; }
.cal-grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; }
.cal-day-label { text-align: center; font-size: 10px; font-weight: 700; color: #94a3b8; padding: 6px 0; text-transform: uppercase; }
.cal-cell { min-height: 80px; border-radius: 8px; padding: 6px; border: 1px solid transparent; transition: background 0.1s; }
.cal-cell:not(.empty):hover { background: #f8fafc; }
.cal-cell.today { border-color: #2563eb; background: #eff6ff; }
.cal-cell.has { background: #fafafa; }
.cal-date { font-size: 12px; font-weight: 600; color: #1e293b; display: block; margin-bottom: 4px; }
.cal-cell.today .cal-date { color: #2563eb; }
.cal-events { display: flex; flex-direction: column; gap: 2px; }
.cal-event-dot { font-size: 9px; font-weight: 600; color: #fff; padding: 2px 5px; border-radius: 4px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.cal-more { font-size: 9px; color: #94a3b8; padding: 1px 4px; }

/* MODAL */
.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.4); z-index: 100; display: flex; align-items: center; justify-content: center; backdrop-filter: blur(2px); }
.modal { background: #fff; border-radius: 16px; width: 540px; max-width: 95vw; box-shadow: 0 20px 60px rgba(0,0,0,0.15); }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 18px 20px; border-bottom: 1px solid #f1f5f9; }
.modal-header h3 { font-size: 16px; font-weight: 800; color: #1e293b; }
.drawer-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 16px; padding: 4px; border-radius: 6px; }
.modal-body { padding: 20px; display: flex; flex-direction: column; gap: 14px; }
.modal-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 16px 20px; border-top: 1px solid #f1f5f9; }

.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.form-group { display: flex; flex-direction: column; gap: 5px; }
.form-label { font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; }
.form-input { border: 1px solid #e2e8f0; border-radius: 8px; padding: 9px 12px; font-size: 13px; color: #1e293b; font-family: inherit; outline: none; background: #f8fafc; }
.form-input:focus { border-color: #93c5fd; background: #fff; }
.form-textarea { border: 1px solid #e2e8f0; border-radius: 8px; padding: 9px 12px; font-size: 13px; color: #1e293b; font-family: inherit; outline: none; resize: vertical; background: #f8fafc; }
.notify-row { display: flex; align-items: center; gap: 16px; }
.checkbox-label { display: flex; align-items: center; gap: 6px; font-size: 13px; color: #475569; cursor: pointer; }

.modal-enter-active, .modal-leave-active { transition: opacity 0.2s; }
.modal-enter-active .modal, .modal-leave-active .modal { transition: transform 0.2s, opacity 0.2s; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
.modal-enter-from .modal, .modal-leave-to .modal { transform: scale(0.95); opacity: 0; }
</style>
