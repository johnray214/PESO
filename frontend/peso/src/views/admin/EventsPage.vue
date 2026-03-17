<template>
  <div class="page">
    <!-- Toast -->
    <transition name="toast">
      <div v-if="toast.show" class="toast" :class="toast.type">
        <span class="toast-icon" v-html="toast.icon"></span>
        <span class="toast-msg">{{ toast.text }}</span>
      </div>
    </transition>
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
              {{ event.registered }}/{{ event.slots }} Registered
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
      
      <div v-if="lastPage > 1" class="pagination">
        <span class="page-info">Showing {{ events.length }} of {{ totalEvents }} events</span>
        <div class="page-btns">
          <button class="page-btn" :disabled="currentPage === 1" @click="changePage(currentPage - 1)">‹</button>
          <button 
            v-for="p in paginationPages" 
            :key="p"
            class="page-btn" 
            :class="{ active: currentPage === p }"
            @click="changePage(p)"
          >
            {{ p }}
          </button>
          <button class="page-btn" :disabled="currentPage === lastPage" @click="changePage(currentPage + 1)">›</button>
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
              :style="{ background: statusColor(ev.status).bg, color: statusColor(ev.status).text }"
              :title="ev.title + ' (' + ev.time + ')'">
              <span class="cal-event-time">{{ ev._start_time ? ev._start_time.substring(0, 5) : '' }}</span>
              <span class="cal-event-title">{{ ev.title }}</span>
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
              <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px;">
                <div class="form-group">
                  <label class="form-label">Start Time</label>
                  <input v-model="form.time" type="time" class="form-input"/>
                </div>
                <div class="form-group">
                  <label class="form-label">End Time</label>
                  <input v-model="form.endTime" type="time" class="form-input"/>
                </div>
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
            <button class="btn-ghost" @click="showModal = false" :disabled="savingEvent">Cancel</button>
            <button class="btn-primary" @click="saveEvent" :disabled="savingEvent">
              <span v-if="savingEvent" class="spinner-sm" style="margin-right:4px;"></span>
              {{ editingEvent ? 'Save Changes' : 'Create Event' }}
            </button>
          </div>
        </div>
      </div>
    </transition>

    <!-- VIEW EVENT MODAL -->
    <transition name="modal">
      <div v-if="showViewModal" class="modal-overlay" @click.self="showViewModal = false">
        <div class="modal">
          <div class="modal-header">
            <h3>Registrants - {{ viewingEvent?.title }}</h3>
            <button class="drawer-close" @click="showViewModal = false">✕</button>
          </div>
          <div class="modal-body" style="text-align: center; padding: 40px 20px;">
            <p style="color: #64748b; font-size: 14px;">No registrants yet for this event.</p>
          </div>
        </div>
      </div>
    </transition>

    <!-- ARCHIVE EVENT MODAL -->
    <transition name="modal">
      <div v-if="showArchiveModal" class="modal-overlay" @click.self="showArchiveModal = false">
        <div class="modal archive-modal" style="width: 400px;">
          <div class="modal-body" style="text-align: center; padding: 40px 20px 30px;">
            <div style="background: #fef2f2; width: 64px; height: 64px; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 16px;">
              <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2"><polyline points="21 8 21 21 3 21 3 8"/><rect x="1" y="3" width="22" height="5"/><line x1="10" y1="12" x2="14" y2="12"/></svg>
            </div>
            <h3 style="font-size: 18px; font-weight: 800; color: #1e293b; margin-bottom: 8px;">Archive Event</h3>
            <p style="color: #64748b; font-size: 14px; margin-bottom: 24px; line-height: 1.5;">
              Are you sure you want to archive <strong>"{{ eventToArchive?.title }}"</strong>? This action cannot be undone.
            </p>
            <div style="display: flex; gap: 12px; justify-content: center;">
              <button class="btn-ghost" @click="showArchiveModal = false" style="flex: 1;">Cancel</button>
              <button class="btn-primary" style="background: #ef4444; flex: 1;" @click="confirmArchive">Yes, Archive</button>
            </div>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
import api from '@/services/api'

export default {
  name: 'EventsPage',
  async mounted() {
    await this.fetchEvents()
  },
  data() {
    const now = new Date()
    return {
      view: 'list',
      search: '',
      filterType: '',
      filterStatus: '',
      activeTab: 'all',
      showModal: false,
      showViewModal: false,
      showArchiveModal: false,
      editingEvent: null,
      viewingEvent: null,
      eventToArchive: null,
      toast: { show: false, text: '', type: 'success', icon: '', _timer: null },
      calYear: now.getFullYear(),
      calMonth: now.getMonth(),
      form: { title: '', type: 'Job Fair', description: '', date: '', time: '', endTime: '', venue: '', slots: '', notifyJobseekers: true, notifyEmployers: false },
      savingEvent: false,
      eventTypes: ['Job Fair', 'Seminar', 'Training', 'Livelihood Program', 'Workshop'],
      statusTabs: [
        { label: 'All', value: 'all', count: 0, cls: '' },
        { label: 'Upcoming', value: 'Upcoming', count: 0, cls: 'upcoming-cls' },
        { label: 'Ongoing', value: 'Ongoing', count: 0, cls: 'ongoing-cls' },
        { label: 'Completed', value: 'Completed', count: 0, cls: 'completed-cls' },
      ],
      events: [],
      currentPage: 1,
      lastPage: 1,
      totalEvents: 0,
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
    },
    paginationPages() {
      const pages = []
      const start = Math.max(1, this.currentPage - 2)
      const end = Math.min(this.lastPage, this.currentPage + 2)
      for (let i = start; i <= end; i++) pages.push(i)
      return pages
    },
  },
  methods: {
    async fetchEvents() {
      try {
        const params = { page: this.currentPage }
        if (this.search)       params.search = this.search
        if (this.filterType)   params.type   = this.filterType
        if (this.activeTab !== 'all') params.status = this.activeTab.toLowerCase()
        else if (this.filterStatus)   params.status = this.filterStatus.toLowerCase()

        const response = await api.get('/admin/events', { params })
        const payload = response.data?.data || response.data
        
        this.currentPage = payload.current_page || 1
        this.lastPage = payload.last_page || 1
        this.totalEvents = payload.total || 0

        const dataList = payload.data || payload

        const timeFormat = (time) => time ? new Date(`2000-01-01T${time}`).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }) : '';

        this.events = dataList.map(e => ({
          id: e.id,
          title: e.title,
          type: e.type,
          description: e.description,
          date: e.event_date ? e.event_date.split('T')[0] : '',
          day: String(new Date(e.event_date).getDate()).padStart(2, '0'),
          month: new Date(e.event_date).toLocaleString('default', { month: 'short' }).toUpperCase(),
          year: String(new Date(e.event_date).getFullYear()),
          time: e.end_time ? `${timeFormat(e.start_time)} - ${timeFormat(e.end_time)}` : timeFormat(e.start_time),
          venue: e.location,
          slots: e.max_participants || 0,
          registered: e.participants_count || 0,
          status: e.status ? e.status.charAt(0).toUpperCase() + e.status.slice(1) : 'Upcoming',
          _start_time: e.start_time,
          _end_time: e.end_time
        }))
        this.updateTabCounts()
      } catch (err) { console.error('Error fetching events:', err) }
    },
    updateTabCounts() {
      this.statusTabs[0].count = this.totalEvents
      this.statusTabs[1].count = this.events.filter(e => e.status.toLowerCase() === 'upcoming').length
      this.statusTabs[2].count = this.events.filter(e => e.status.toLowerCase() === 'ongoing').length
      this.statusTabs[3].count = this.events.filter(e => e.status.toLowerCase() === 'completed').length
    },
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
    statusColor(status) {
      const map = {
        'Upcoming': { bg: '#dbeafe', text: '#2563eb' },
        'Ongoing': { bg: '#fff7ed', text: '#f97316' },
        'Completed': { bg: '#dcfce7', text: '#16a34a' },
        'Cancelled': { bg: '#fef2f2', text: '#ef4444' },
      }
      return map[status] || { bg: '#f1f5f9', text: '#64748b' }
    },
    eventStatusClass(s) {
      return { 'Upcoming': 'upcoming-s', 'Ongoing': 'ongoing-s', 'Completed': 'completed-s', 'Cancelled': 'cancelled-s' }[s] || ''
    },
    openCreateModal() {
      this.editingEvent = null
      this.form = { title: '', type: 'Job Fair', description: '', date: '', time: '', endTime: '', venue: '', slots: '', notifyJobseekers: true, notifyEmployers: false }
      this.showModal = true
    },
    openEditModal(event) {
      this.editingEvent = event
      this.form = { 
        title: event.title, 
        type: event.type, 
        description: event.description, 
        date: event.date, 
        time: event._start_time ? event._start_time.substring(0, 5) : '', 
        endTime: event._end_time ? event._end_time.substring(0, 5) : '',
        venue: event.venue, 
        slots: event.slots, 
        notifyJobseekers: false, 
        notifyEmployers: false 
      }
      this.showModal = true
    },
    openViewModal(event) { 
      this.viewingEvent = event;
      this.showViewModal = true;
    },
    async saveEvent() {
      if (this.savingEvent) return;
      this.savingEvent = true;
      try {
        const payload = {
          title: this.form.title,
          description: this.form.description,
          type: this.form.type,
          location: this.form.venue,
          event_date: this.form.date,
          start_time: this.form.time,
          end_time: this.form.endTime,
          max_participants: this.form.slots,
          status: 'upcoming'
        }

        if (this.editingEvent) {
          await api.put(`/admin/events/${this.editingEvent.id}`, payload)
        } else {
          await api.post('/admin/events', payload)
        }
        
        await this.fetchEvents()
        this.showModal = false
        this.showToastMsg('Event saved successfully!', 'success')
      } catch (e) { 
        console.error(e)
        this.showToastMsg('Failed to save event', 'error')
      } finally {
        this.savingEvent = false;
      }
    },
    archiveEvent(event) {
      this.eventToArchive = event;
      this.showArchiveModal = true;
    },
    async confirmArchive() {
      if (!this.eventToArchive) return;
      try {
        await api.delete(`/admin/events/${this.eventToArchive.id}`)
        this.events = this.events.filter(e => e.id !== this.eventToArchive.id)
        this.updateTabCounts()
        this.showArchiveModal = false;
        this.eventToArchive = null;
        this.showToastMsg('Event archived successfully', 'success')
      } catch (e) { 
        console.error(e)
        this.showToastMsg('Failed to archive event', 'error')
      }
    },
    showToastMsg(text, type = 'success') {
      const CHECK = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>`
      const X = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`
      if (this.toast._timer) clearTimeout(this.toast._timer)
      this.toast = { show: true, text, type, icon: type === 'success' ? CHECK : X, _timer: setTimeout(() => { this.toast.show = false }, 3500) }
    },
    prevMonth() { if (this.calMonth === 0) { this.calMonth = 11; this.calYear-- } else this.calMonth-- },
    nextMonth() { if (this.calMonth === 11) { this.calMonth = 0; this.calYear++ } else this.calMonth++ },
    changePage(page) {
      if (page >= 1 && page <= this.lastPage) {
        this.currentPage = page
        this.fetchEvents()
      }
    }
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

.page { font-family: 'Plus Jakarta Sans', sans-serif; padding: 24px; background: #f8fafc; min-height: 0; display: flex; flex-direction: column; gap: 16px; }
.header-actions { display: flex; align-items: center; gap: 10px; }

.view-toggle { display: flex; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; overflow: hidden; }
.toggle-btn { display: flex; align-items: center; gap: 6px; background: none; border: none; padding: 8px 14px; font-size: 12.5px; font-weight: 500; color: #64748b; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.toggle-btn.active { background: #2563eb; color: #fff; }

.btn-primary { display: flex; align-items: center; gap: 6px; background: #2563eb; color: #fff; border: none; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-primary:hover { background: #1d4ed8; }
.btn-ghost { background: #f1f5f9; color: #64748b; border: none; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }

/* Toast */
.toast {
  position: fixed; top: 20px; right: 24px; z-index: 9999;
  display: flex; align-items: center; gap: 10px;
  padding: 12px 18px; border-radius: 12px;
  font-size: 13px; font-weight: 600; box-shadow: 0 8px 30px rgba(0,0,0,0.12);
  min-width: 240px; max-width: 380px; font-family: 'Plus Jakarta Sans', sans-serif;
}
.toast.success { background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; }
.toast.error   { background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; }
.toast-icon { display: flex; align-items: center; flex-shrink: 0; }
.toast-msg { word-break: break-word; line-height: 1.4; }
.toast-enter-active, .toast-leave-active { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
.toast-enter-from, .toast-leave-to { opacity: 0; transform: translateY(-15px) scale(0.95); }

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
.cal-events { display: flex; flex-direction: column; gap: 3px; }
.cal-event-dot { 
  display: flex; 
  align-items: center; 
  gap: 4px; 
  font-size: 10px; 
  font-weight: 600; 
  padding: 3px 6px; 
  border-radius: 4px; 
  white-space: nowrap; 
  overflow: hidden; 
  border-left: 2px solid currentColor;
}
.cal-event-time { font-size: 9px; opacity: 0.8; font-weight: 700; flex-shrink: 0; }
.cal-event-title { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.cal-more { font-size: 10px; font-weight: 600; color: #64748b; padding: 2px 4px; text-align: center; cursor: pointer; }

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

.spinner-sm {
  width: 14px; height: 14px; flex-shrink: 0;
  border: 2px solid rgba(255,255,255,0.4); border-top-color: #fff;
  border-radius: 50%; animation: spin 0.7s linear infinite; display: inline-block;
}
@keyframes spin { to { transform: rotate(360deg); } }

.pagination { display: flex; align-items: center; justify-content: space-between; padding: 14px 18px; background: #fff; border-radius: 14px; margin-top: 12px; border: 1px solid #f1f5f9; }
.page-info { font-size: 12px; color: #94a3b8; }
.page-btns { display: flex; gap: 4px; }
.page-btn { width: 30px; height: 30px; border-radius: 7px; border: 1px solid #e2e8f0; background: #fff; font-size: 12px; color: #64748b; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; }
.page-btn.active { background: #2563eb; color: #fff; border-color: #2563eb; }
</style>
