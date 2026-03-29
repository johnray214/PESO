<template>
  <div class="page">
    <!-- Toast -->
    <transition name="toast">
      <div v-if="toast.show" class="toast" :class="toast.type">
        <span class="toast-icon" v-html="toast.icon"></span>
        <span class="toast-msg">{{ toast.text }}</span>
      </div>
    </transition>

    <!-- SKELETON -->
    <template v-if="loading && !events.length">
      <div class="header-actions" style="margin-bottom: 16px;">
        <div class="skel" style="width: 160px; height: 36px; border-radius: 10px;"></div>
        <div class="skel" style="width: 140px; height: 36px; border-radius: 10px; margin-left: auto;"></div>
      </div>
      <div class="filters-bar" style="margin-bottom: 20px;">
        <div class="skel" style="width: 300px; height: 38px; border-radius: 10px;"></div>
        <div style="display:flex; gap:8px;">
          <div class="skel" style="width: 120px; height: 36px; border-radius: 8px;"></div>
          <div class="skel" style="width: 120px; height: 36px; border-radius: 8px;"></div>
        </div>
      </div>
      <div class="status-tabs" style="margin-bottom: 16px;">
        <div v-for="i in 4" :key="i" class="skel" style="width: 100px; height: 34px; border-radius: 8px;"></div>
      </div>
      <div class="events-list">
        <div v-for="i in 3" :key="i" class="skel" style="width: 100%; height: 120px; border-radius: 14px; margin-bottom: 12px;"></div>
      </div>
    </template>

    <!-- ACTUAL CONTENT -->
    <template v-else>
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
        <button class="btn-primary" @click="openCreateModal()">
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
        <div v-if="filteredEvents.length === 0" class="empty-state">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.5"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          <p>No events found.</p>
        </div>

        <div v-for="event in filteredEvents" :key="event.id"
          :class="['event-card', { 'event-card--locked': isLocked(event) }]">

          <div v-if="isLocked(event)" class="locked-ribbon">
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
            {{ event.status === 'Completed' ? 'Completed — read only' : 'Ongoing — read only' }}
          </div>

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
                <div class="slots-fill" :style="{ width: (event.registered / Math.max(event.slots, 1) * 100) + '%', background: typeColor(event.type).text }"></div>
              </div>
              <span class="slots-pct">{{ Math.round(event.registered / Math.max(event.slots, 1) * 100) }}% full</span>
            </div>
          </div>

          <div class="event-actions">
            <button class="act-btn view" @click="openViewModal(event)" title="View Registrants">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
            </button>
            <button
              class="act-btn edit"
              :class="{ 'act-btn--disabled': isLocked(event) }"
              @click="!isLocked(event) && openEditModal(event)"
              :title="isLocked(event) ? 'Cannot edit — event is ' + event.status : 'Edit'"
            >
              <svg v-if="!isLocked(event)" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
              <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
            </button>
            <button
              class="act-btn delete"
              :class="{ 'act-btn--disabled': isLocked(event) }"
              @click="!isLocked(event) && archiveEvent(event)"
              :title="isLocked(event) ? 'Cannot archive — event is ' + event.status : 'Archive'"
            >
              <svg v-if="!isLocked(event)" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="21 8 21 21 3 21 3 8"/><rect x="1" y="3" width="22" height="5"/><line x1="10" y1="12" x2="14" y2="12"/></svg>
              <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
            </button>
          </div>
        </div>

        <div v-if="lastPage > 1" class="pagination">
          <span class="page-info">Showing {{ events.length }} of {{ totalEvents }} events</span>
          <div class="page-btns">
            <button class="page-btn" :disabled="currentPage === 1" @click="changePage(currentPage - 1)">‹</button>
            <button v-for="p in paginationPages" :key="p" class="page-btn" :class="{ active: currentPage === p }" @click="changePage(p)">{{ p }}</button>
            <button class="page-btn" :disabled="currentPage === lastPage" @click="changePage(currentPage + 1)">›</button>
          </div>
        </div>
      </div>

      <!-- CALENDAR VIEW -->
      <div v-if="view === 'calendar'" class="calendar-card">
        <div class="cal-header">
          <button class="cal-nav" @click="prevMonth">‹</button>
          <div class="cal-month-picker" v-click-outside="closeMonthPicker">
            <button class="cal-month-btn" @click="toggleMonthPicker">
              {{ calMonthLabel }}
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"
                :style="{ transform: showMonthPicker ? 'rotate(180deg)' : 'rotate(0deg)', transition: 'transform 0.2s' }">
                <polyline points="6 9 12 15 18 9"/>
              </svg>
            </button>
            <transition name="picker">
              <div v-if="showMonthPicker" class="cal-picker-dropdown">
                <div class="cal-picker-year-row">
                  <button class="cal-picker-nav" @click.stop="pickerYear--">‹</button>
                  <span class="cal-picker-year">{{ pickerYear }}</span>
                  <button class="cal-picker-nav" @click.stop="pickerYear++">›</button>
                </div>
                <div class="cal-picker-months">
                  <button v-for="(m, idx) in monthNames" :key="idx"
                    :class="['cal-picker-month-btn', { active: idx === calMonth && pickerYear === calYear }]"
                    @click.stop="selectMonthYear(idx)">{{ m }}</button>
                </div>
              </div>
            </transition>
          </div>
          <button class="cal-nav" @click="nextMonth">›</button>
        </div>

        <div class="cal-legend">
          <span class="cal-legend-item"><span class="cal-legend-dot" style="background:#dbeafe;border-color:#2563eb"></span> Upcoming</span>
          <span class="cal-legend-item"><span class="cal-legend-dot" style="background:#fff7ed;border-color:#f97316"></span> Ongoing</span>
          <span class="cal-legend-item"><span class="cal-legend-dot" style="background:#dcfce7;border-color:#22c55e"></span> Completed</span>
          <span class="cal-legend-item"><span class="cal-legend-dot" style="background:#fef2f2;border-color:#ef4444"></span> Cancelled</span>
        </div>

        <div class="cal-grid">
          <div v-for="d in ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']" :key="d" class="cal-day-label">{{ d }}</div>
          <div v-for="(cell, i) in calCells" :key="i"
            :class="['cal-cell', { empty: !cell.day, today: cell.isToday, has: cell.events.length > 0 }]"
            @click="onCalendarCellClick(cell, $event)">
            <template v-if="cell.day">
              <span class="cal-date">{{ cell.day }}</span>
              <div class="cal-events">
                <div
                  v-for="ev in cell.events.slice(0, 3)" :key="ev.id"
                  class="cal-event-block"
                  @click.stop="onCalEventClick(ev, cell, $event)"
                  :style="{
                    background: statusColor(ev.status).bg,
                    color: statusColor(ev.status).text,
                    borderLeftColor: statusColor(ev.status).text,
                  }"
                  :title="ev.title + ' (' + ev.time + ')'"
                >
                  <span v-if="ev._start_time" class="cal-event-time">{{ ev._start_time.substring(0, 5) }}</span>
                  <span class="cal-event-title">{{ ev.title }}</span>
                </div>
                <div v-if="cell.events.length > 3" class="cal-overflow" @click.stop="openCtxMenu(cell, $event)">
                  +{{ cell.events.length - 3 }} more
                </div>
              </div>
            </template>
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
                  <input v-model="form.date" type="date" :min="minDate" class="form-input"/>
                  <p v-if="form.date" class="form-date-hint">Selected: {{ formatDateUs(form.date) }}</p>
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

      <!-- VIEW EVENT MODAL (registrants) -->
      <transition name="modal">
        <div v-if="showViewModal" class="modal-overlay" @click.self="showViewModal = false">
          <div class="modal">
            <div class="modal-header">
              <div>
                <h3>{{ viewingEvent?.title }}</h3>
                <div style="display:flex;align-items:center;gap:8px;margin-top:4px;">
                  <span class="status-badge" :class="eventStatusClass(viewingEvent?.status)">{{ viewingEvent?.status }}</span>
                  <span style="font-size:12px;color:#94a3b8;">{{ viewingEvent?.time }} · {{ viewingEvent?.venue }}</span>
                </div>
              </div>
              <button class="drawer-close" @click="showViewModal = false">✕</button>
            </div>
            <div class="modal-body" style="max-height:55vh;overflow-y:auto;padding:16px 20px 24px;">
              <div v-if="viewRegistrantsLoading" style="text-align:center;padding:32px;color:#64748b;font-size:14px;">
                Loading registrants…
              </div>
              <template v-else>
                <p v-if="viewRegistrants.length === 0" style="text-align:center;color:#64748b;font-size:14px;padding:24px 0;">
                  No registrants yet for this event.
                </p>
                <ul v-else class="registrants-list">
                  <li v-for="r in viewRegistrants" :key="r.id" class="registrant-row">
                    <div class="registrant-name">{{ r.name || 'Jobseeker' }}</div>
                    <div class="registrant-meta">{{ r.email }}<span v-if="r.contact"> · {{ r.contact }}</span></div>
                    <div v-if="r.registered_at" class="registrant-time">{{ formatRegTime(r.registered_at) }}</div>
                  </li>
                </ul>
              </template>
            </div>
          </div>
        </div>
      </transition>

      <!-- CALENDAR CONTEXT MENU -->
      <transition name="ctx">
        <div v-if="ctxMenu.show" class="ctx-menu" :style="{ top: ctxMenu.y + 'px', left: ctxMenu.x + 'px' }" v-click-outside="closeCtxMenu">
          <div class="ctx-menu-header">
            <span class="ctx-menu-date">{{ ctxMenu.dateLabel }}</span>
          </div>

          <template v-if="ctxMenu.events.length">
            <div class="ctx-menu-section-label">Events on this day</div>
            <div v-for="ev in ctxMenu.events" :key="ev.id" class="ctx-menu-event-row">
              <span class="ctx-menu-event-dot" :style="{ background: statusColor(ev.status).text }"></span>
              <div class="ctx-menu-event-info">
                <span class="ctx-menu-event-title">{{ ev.title }}</span>
                <span class="ctx-menu-event-meta">{{ ev._start_time ? ev._start_time.substring(0,5) : '' }} · {{ ev.status }}</span>
              </div>
              <button class="ctx-menu-action-btn" @click="ctxViewEvent(ev)">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                View
              </button>
            </div>
          </template>

          <div class="ctx-menu-divider"></div>
          <button class="ctx-menu-create-btn" @click="ctxCreateEvent">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Create New Event on this Day
          </button>
        </div>
      </transition>

      <!-- ARCHIVE CONFIRM MODAL -->
      <transition name="modal">
        <div v-if="showArchiveModal" class="modal-overlay" @click.self="showArchiveModal = false">
          <div class="modal" style="width:400px;">
            <div class="modal-body" style="text-align:center;padding:40px 20px 30px;">
              <div style="background:#fef2f2;width:64px;height:64px;border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto 16px;">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2"><polyline points="21 8 21 21 3 21 3 8"/><rect x="1" y="3" width="22" height="5"/><line x1="10" y1="12" x2="14" y2="12"/></svg>
              </div>
              <h3 style="font-size:18px;font-weight:800;color:#1e293b;margin-bottom:8px;">Archive Event</h3>
              <p style="color:#64748b;font-size:14px;margin-bottom:24px;line-height:1.5;">
                Are you sure you want to archive <strong>"{{ eventToArchive?.title }}"</strong>? This action cannot be undone.
              </p>
              <div style="display:flex;gap:12px;justify-content:center;">
                <button class="btn-ghost" @click="showArchiveModal = false" style="flex:1;">Cancel</button>
                <button class="btn-primary" style="background:#ef4444;flex:1;" @click="confirmArchive">Yes, Archive</button>
              </div>
            </div>
          </div>
        </div>
      </transition>

      <!-- LOCK TOAST -->
      <transition name="toast">
        <div v-if="lockToast.show" class="lock-toast">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
          {{ lockToast.text }}
        </div>
      </transition>
    </template>
  </div>
</template>

<script>
import api from '@/services/api'

export default {
  name: 'EventsPage',

  directives: {
    'click-outside': {
      mounted(el, binding) {
        el._clickOutside = (e) => { if (!el.contains(e.target)) binding.value(e) }
        document.addEventListener('mousedown', el._clickOutside)
      },
      unmounted(el) {
        document.removeEventListener('mousedown', el._clickOutside)
      },
    },
  },

  async mounted() {
    await this.fetchEvents()
  },

  data() {
    const now = new Date()
    const todayISO = new Date(now.getTime() - (now.getTimezoneOffset() * 60000)).toISOString().split('T')[0]
    return {
      minDate: todayISO,
      view: 'list',
      search: '',
      filterType: '',
      filterStatus: '',
      activeTab: 'all',
      showModal: false,
      showViewModal: false,
      showArchiveModal: false,
      loading: true,
      editingEvent: null,
      viewingEvent: null,
      viewRegistrants: [],
      viewRegistrantsLoading: false,
      eventToArchive: null,
      toast: { show: false, text: '', type: 'success', icon: '', _timer: null },
      lockToast: { show: false, text: '', _timer: null },
      calYear: now.getFullYear(),
      calMonth: now.getMonth(),
      showMonthPicker: false,
      pickerYear: now.getFullYear(),
      monthNames: ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],
      // Context menu for calendar cells
      ctxMenu: { show: false, x: 0, y: 0, dateLabel: '', dateStr: '', events: [] },
      form: { title: '', type: 'Job Fair', description: '', date: '', time: '', endTime: '', venue: '', slots: '' },
      savingEvent: false,
      eventTypes: ['Job Fair', 'Seminar', 'Training', 'Livelihood Program', 'Workshop'],
      statusTabs: [
        { label: 'All',       value: 'all',       count: 0, cls: '' },
        { label: 'Upcoming',  value: 'Upcoming',  count: 0, cls: 'upcoming-cls' },
        { label: 'Ongoing',   value: 'Ongoing',   count: 0, cls: 'ongoing-cls' },
        { label: 'Completed', value: 'Completed', count: 0, cls: 'completed-cls' },
      ],
      events: [],
      currentPage: 1,
      lastPage: 1,
      totalEvents: 0,
    }
  },

  computed: {
    isHiddenFromList() {
      return (event) => {
        if (event.status !== 'Completed') return false
        if (!event.date) return false
        const eventDate = new Date(event.date)
        eventDate.setHours(0, 0, 0, 0)
        const cutoff = new Date()
        cutoff.setDate(cutoff.getDate() - 1)
        cutoff.setHours(0, 0, 0, 0)
        return eventDate <= cutoff
      }
    },

    isLocked() {
      return (event) => ['Ongoing', 'Completed'].includes(event.status)
    },

    filteredEvents() {
      return this.events.filter(e => {
        if (this.isHiddenFromList(e)) return false
        const matchTab    = this.activeTab === 'all' || e.status === this.activeTab
        const matchSearch = !this.search       || e.title.toLowerCase().includes(this.search.toLowerCase())
        const matchType   = !this.filterType   || e.type   === this.filterType
        const matchStatus = !this.filterStatus || e.status === this.filterStatus
        return matchTab && matchSearch && matchType && matchStatus
      })
    },

    // Calendar filtering: applies search + type + status dropdown + active tab
    calFilteredEvents() {
      return this.events.filter(e => {
        const matchSearch = !this.search       || e.title.toLowerCase().includes(this.search.toLowerCase())
        const matchType   = !this.filterType   || e.type   === this.filterType
        const matchStatus = !this.filterStatus || e.status === this.filterStatus
        const matchTab    = this.activeTab === 'all' || e.status === this.activeTab
        return matchSearch && matchType && matchStatus && matchTab
      })
    },

    calMonthLabel() {
      return new Date(this.calYear, this.calMonth).toLocaleString('default', { month: 'long', year: 'numeric' })
    },

    calCells() {
      const firstDay    = new Date(this.calYear, this.calMonth, 1).getDay()
      const daysInMonth = new Date(this.calYear, this.calMonth + 1, 0).getDate()
      const today       = new Date()
      const cells       = []
      for (let i = 0; i < firstDay; i++) cells.push({ day: null, isToday: false, events: [], dateStr: null })
      for (let d = 1; d <= daysInMonth; d++) {
        const isToday = today.getDate() === d && today.getMonth() === this.calMonth && today.getFullYear() === this.calYear
        const dateStr = `${this.calYear}-${String(this.calMonth + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`
        // Use calFilteredEvents so filters apply to calendar
        const dayEvents = this.calFilteredEvents.filter(e => e.date === dateStr)
        cells.push({ day: d, isToday, events: dayEvents, dateStr })
      }
      return cells
    },

    paginationPages() {
      const pages = []
      const start = Math.max(1, this.currentPage - 2)
      const end   = Math.min(this.lastPage, this.currentPage + 2)
      for (let i = start; i <= end; i++) pages.push(i)
      return pages
    },
  },

  methods: {
    // ── Data ────────────────────────────────────────────────────────
    async fetchEvents() {
      this.loading = true
      try {
        const params = { page: this.currentPage }
        if (this.search)       params.search = this.search
        if (this.filterType)   params.type   = this.filterType
        if (this.filterStatus) params.status = this.filterStatus.toLowerCase()

        const response = await api.get('/admin/events', { params })
        const payload  = response.data?.data || response.data

        this.currentPage = payload.current_page || 1
        this.lastPage    = payload.last_page    || 1
        this.totalEvents = payload.total        || 0

        const dataList   = payload.data || payload
        const timeFormat = (time) => time ? new Date(`2000-01-01T${time}`).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }) : ''

        this.events = dataList.map(e => ({
          id:          e.id,
          title:       e.title,
          type:        e.type,
          description: e.description,
          date:        e.event_date ? e.event_date.split('T')[0] : '',
          day:         String(new Date(e.event_date).getDate()).padStart(2, '0'),
          month:       new Date(e.event_date).toLocaleString('default', { month: 'short' }).toUpperCase(),
          year:        String(new Date(e.event_date).getFullYear()),
          time:        e.end_time ? `${timeFormat(e.start_time)} - ${timeFormat(e.end_time)}` : timeFormat(e.start_time),
          venue:       e.location,
          slots:       e.max_participants   || 0,
          registered:  e.participants_count || 0,
          status:      e.status ? e.status.charAt(0).toUpperCase() + e.status.slice(1) : 'Upcoming',
          _start_time: e.start_time,
          _end_time:   e.end_time,
        }))

        this.updateTabCounts()
      } catch (err) {
        console.error('Error fetching events:', err)
      } finally {
        this.loading = false
      }
    },

    updateTabCounts() {
      const visible = this.events.filter(e => !this.isHiddenFromList(e))
      this.statusTabs[0].count = visible.length
      this.statusTabs[1].count = this.events.filter(e => e.status === 'Upcoming').length
      this.statusTabs[2].count = this.events.filter(e => e.status === 'Ongoing').length
      this.statusTabs[3].count = this.events.filter(e => e.status === 'Completed').length
    },

    // ── Month/Year picker ─────────────────────────────────────────────
    toggleMonthPicker() {
      this.pickerYear = this.calYear
      this.showMonthPicker = !this.showMonthPicker
    },
    closeMonthPicker() { this.showMonthPicker = false },
    selectMonthYear(monthIdx) {
      this.calMonth = monthIdx
      this.calYear  = this.pickerYear
      this.showMonthPicker = false
    },

    // ── Calendar interactions ─────────────────────────────────────────
    /**
     * Click on the blank area of a cell (not on an event chip).
     * - No events → open create modal directly
     * - Has events → open context menu
     */
    onCalendarCellClick(cell, evt) {
      if (!cell.day || !cell.dateStr) return
      if (evt.target.closest && evt.target.closest('.cal-event-block')) return
      if (evt.target.closest && evt.target.closest('.cal-overflow')) return

      if (cell.events.length === 0) {
        if (cell.dateStr < this.minDate) {
          this.showToastMsg('Cannot create events on past dates.', 'error')
          return
        }
        this.openCreateModal(cell.dateStr)
      } else {
        this.openCtxMenu(cell, evt)
      }
    },

    /**
     * Click directly on an event chip.
     * - Completed → open view modal immediately (no context menu needed)
     * - Upcoming / Ongoing → open context menu (so user can also create new on same day)
     */
    onCalEventClick(ev, cell, evt) {
      if (ev.status === 'Completed') {
        this.openViewModal(ev)
      } else {
        this.openCtxMenu(cell, evt)
      }
    },

    openCtxMenu(cell, evt) {
      const MENU_W = 265
      const MENU_H = 60 + cell.events.length * 52 + 50 // approximate

      // Try to position below the cell, centered
      const cellEl = evt.currentTarget?.closest?.('.cal-cell') || evt.currentTarget
      const cellRect = cellEl ? cellEl.getBoundingClientRect() : { left: evt.clientX, top: evt.clientY, width: 0, height: 0 }

      let x = cellRect.left + cellRect.width / 2 - MENU_W / 2
      let y = cellRect.bottom + 6

      // Clamp horizontally
      if (x + MENU_W > window.innerWidth - 8) x = window.innerWidth - MENU_W - 8
      if (x < 8) x = 8
      // Flip up if too close to bottom
      if (y + MENU_H > window.innerHeight - 8) y = cellRect.top - MENU_H - 6

      const dateObj   = new Date(cell.dateStr + 'T00:00:00')
      const dateLabel = dateObj.toLocaleDateString('en-US', { weekday: 'short', month: 'long', day: 'numeric', year: 'numeric' })

      this.ctxMenu = { show: true, x, y, dateLabel, dateStr: cell.dateStr, events: cell.events }
    },

    closeCtxMenu() { this.ctxMenu.show = false },

    ctxViewEvent(ev) {
      this.closeCtxMenu()
      this.openViewModal(ev)
    },

    ctxCreateEvent() {
      this.closeCtxMenu()
      this.openCreateModal(this.ctxMenu.dateStr)
    },

    // ── Lock helpers ─────────────────────────────────────────────────
    showLockMessage(event) {
      const msg = event.status === 'Completed'
        ? 'This event is completed and can no longer be edited or archived.'
        : 'This event is currently ongoing and cannot be edited or archived.'
      if (this.lockToast._timer) clearTimeout(this.lockToast._timer)
      this.lockToast = { show: true, text: msg, _timer: setTimeout(() => { this.lockToast.show = false }, 3000) }
    },

    // ── Colors ──────────────────────────────────────────────────────
    typeColor(type) {
      const map = {
        'Job Fair':           { bg: '#dbeafe', text: '#2563eb' },
        'Seminar':            { bg: '#fff7ed', text: '#f97316' },
        'Training':           { bg: '#dcfce7', text: '#16a34a' },
        'Livelihood Program': { bg: '#fdf4ff', text: '#a21caf' },
        'Workshop':           { bg: '#fef9c3', text: '#ca8a04' },
      }
      return map[type] || { bg: '#f1f5f9', text: '#64748b' }
    },

    statusColor(status) {
      const map = {
        'Upcoming':  { bg: '#dbeafe', text: '#2563eb' },
        'Ongoing':   { bg: '#fff7ed', text: '#f97316' },
        'Completed': { bg: '#dcfce7', text: '#16a34a' },
        'Cancelled': { bg: '#fef2f2', text: '#ef4444' },
      }
      return map[status] || { bg: '#f1f5f9', text: '#64748b' }
    },

    eventStatusClass(s) {
      return { Upcoming: 'upcoming-s', Ongoing: 'ongoing-s', Completed: 'completed-s', Cancelled: 'cancelled-s' }[s] || ''
    },

    // ── Modal openers ────────────────────────────────────────────────
    openCreateModal(prefillIsoDate = '') {
      this.editingEvent = null
      this.form = { title: '', type: 'Job Fair', description: '', date: prefillIsoDate || '', time: '', endTime: '', venue: '', slots: '' }
      this.showModal = true
    },

    formatDateUs(iso) {
      if (!iso || typeof iso !== 'string') return ''
      const parts = iso.split('-')
      if (parts.length !== 3) return iso
      const [y, m, d] = parts
      return `${m}/${d}/${y}`
    },

    openEditModal(event) {
      if (this.isLocked(event)) { this.showLockMessage(event); return }
      this.editingEvent = event
      this.form = {
        title:       event.title,
        type:        event.type,
        description: event.description,
        date:        event.date,
        time:        event._start_time ? event._start_time.substring(0, 5) : '',
        endTime:     event._end_time   ? event._end_time.substring(0, 5)   : '',
        venue:       event.venue,
        slots:       event.slots,
      }
      this.showModal = true
    },

    async openViewModal(event) {
      this.viewingEvent = event
      this.showViewModal = true
      this.viewRegistrants = []
      this.viewRegistrantsLoading = true
      try {
        const { data } = await api.get(`/admin/events/${event.id}/registrations`)
        const body = data?.data ?? data
        this.viewRegistrants = Array.isArray(body) ? body : (body?.data || [])
      } catch (e) {
        console.error(e)
        this.viewRegistrants = []
      } finally {
        this.viewRegistrantsLoading = false
      }
    },

    formatRegTime(iso) {
      if (!iso) return ''
      try { return new Date(iso).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' }) }
      catch { return iso }
    },

    // ── Save ─────────────────────────────────────────────────────────
    async saveEvent() {
      if (this.savingEvent) return
      
      if (!this.form.date || this.form.date < this.minDate) {
        this.showToastMsg('Event date cannot be in the past.', 'error')
        return
      }

      this.savingEvent = true
      try {
        const payload = {
          title:            this.form.title,
          description:      this.form.description,
          type:             this.form.type,
          location:         this.form.venue,
          event_date:       this.form.date,
          start_time:       this.form.time,
          end_time:         this.form.endTime || null,
          max_participants: this.form.slots ? parseInt(this.form.slots, 10) : null,
          status:           'upcoming',
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
        this.savingEvent = false
      }
    },

    // ── Archive ──────────────────────────────────────────────────────
    archiveEvent(event) {
      if (this.isLocked(event)) { this.showLockMessage(event); return }
      this.eventToArchive = event
      this.showArchiveModal = true
    },

    async confirmArchive() {
      if (!this.eventToArchive) return
      try {
        await api.delete(`/admin/events/${this.eventToArchive.id}`)
        this.events = this.events.filter(e => e.id !== this.eventToArchive.id)
        this.updateTabCounts()
        this.showArchiveModal = false
        this.eventToArchive  = null
        this.showToastMsg('Event archived successfully', 'success')
      } catch (e) {
        console.error(e)
        this.showToastMsg('Failed to archive event', 'error')
      }
    },

    // ── Toast ────────────────────────────────────────────────────────
    showToastMsg(text, type = 'success') {
      const CHECK = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>`
      const X     = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`
      if (this.toast._timer) clearTimeout(this.toast._timer)
      this.toast = { show: true, text, type, icon: type === 'success' ? CHECK : X, _timer: setTimeout(() => { this.toast.show = false }, 3500) }
    },

    // ── Calendar nav ─────────────────────────────────────────────────
    prevMonth() { if (this.calMonth === 0) { this.calMonth = 11; this.calYear-- } else this.calMonth-- },
    nextMonth() { if (this.calMonth === 11) { this.calMonth = 0; this.calYear++ } else this.calMonth++ },

    changePage(page) {
      if (page >= 1 && page <= this.lastPage) {
        this.currentPage = page
        this.fetchEvents()
      }
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

@keyframes shimmer { 0% { background-position: -400px 0; } 100% { background-position: 400px 0; } }
.skel { background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%); background-size: 400px 100%; animation: shimmer 1.4s infinite linear; border-radius: 6px; flex-shrink: 0; }

.page { font-family: 'Plus Jakarta Sans', sans-serif; padding: 24px; background: #f8fafc; min-height: 0; display: flex; flex-direction: column; gap: 16px; }
.header-actions { display: flex; align-items: center; gap: 10px; }

.view-toggle { display: flex; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; overflow: hidden; }
.toggle-btn { display: flex; align-items: center; gap: 6px; background: none; border: none; padding: 8px 14px; font-size: 12.5px; font-weight: 500; color: #64748b; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.toggle-btn.active { background: #2563eb; color: #fff; }

.btn-primary { display: flex; align-items: center; gap: 6px; background: #2563eb; color: #fff; border: none; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; transition: background 0.15s; }
.btn-primary:hover { background: #1d4ed8; }
.btn-ghost { background: #f1f5f9; color: #64748b; border: none; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }

/* Toast */
.toast { position: fixed; top: 20px; right: 24px; z-index: 9999; display: flex; align-items: center; gap: 10px; padding: 12px 18px; border-radius: 12px; font-size: 13px; font-weight: 600; box-shadow: 0 8px 30px rgba(0,0,0,0.12); min-width: 240px; max-width: 380px; font-family: 'Plus Jakarta Sans', sans-serif; }
.toast.success { background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; }
.toast.error   { background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; }
.toast-icon { display: flex; align-items: center; flex-shrink: 0; }
.toast-msg { word-break: break-word; line-height: 1.4; }
.toast-enter-active, .toast-leave-active { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
.toast-enter-from, .toast-leave-to { opacity: 0; transform: translateY(-15px) scale(0.95); }
.lock-toast { position: fixed; bottom: 24px; left: 50%; transform: translateX(-50%); z-index: 9999; display: flex; align-items: center; gap: 8px; background: #1e293b; color: #f8fafc; padding: 10px 18px; border-radius: 10px; font-size: 13px; font-weight: 600; box-shadow: 0 8px 30px rgba(0,0,0,0.22); white-space: nowrap; pointer-events: none; }

/* Filters */
.filters-bar { display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; flex: 1; max-width: 360px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-group { display: flex; align-items: center; gap: 8px; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }

/* Status tabs */
.status-tabs { display: flex; gap: 4px; }
.tab-btn { display: flex; align-items: center; gap: 6px; background: none; border: none; padding: 8px 14px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; border-radius: 8px; font-family: inherit; transition: all 0.15s; }
.tab-btn.active { background: #eff6ff; color: #2563eb; font-weight: 700; }
.tab-count { font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }
.tab-count.upcoming-cls  { background: #dbeafe; color: #2563eb; }
.tab-count.ongoing-cls   { background: #fff7ed; color: #f97316; }
.tab-count.completed-cls { background: #dcfce7; color: #22c55e; }

/* Empty state */
.empty-state { display: flex; flex-direction: column; align-items: center; gap: 10px; padding: 48px 20px; background: #fff; border-radius: 14px; border: 1px solid #f1f5f9; color: #94a3b8; font-size: 13px; }

/* EVENT CARDS */
.events-list { display: flex; flex-direction: column; gap: 12px; }
.event-card { background: #fff; border-radius: 14px; padding: 18px; display: flex; gap: 18px; align-items: flex-start; border: 1px solid #f1f5f9; transition: box-shadow 0.15s; position: relative; overflow: hidden; }
.event-card:hover { box-shadow: 0 4px 20px rgba(0,0,0,0.06); }
.event-card--locked { background: #fafafa; border-color: #f1f5f9; padding-top: 36px; }
.event-card--locked .event-title { color: #64748b; }
.event-card--locked .event-desc  { color: #cbd5e1; }
.locked-ribbon { position: absolute; top: 0; left: 0; right: 0; background: #f8fafc; border-bottom: 1px solid #f1f5f9; font-size: 10px; font-weight: 700; color: #94a3b8; padding: 4px 14px; display: flex; align-items: center; gap: 5px; text-transform: uppercase; letter-spacing: 0.04em; }

.event-date-col { flex-shrink: 0; }
.date-box { width: 56px; border-radius: 12px; padding: 10px 6px; display: flex; flex-direction: column; align-items: center; gap: 1px; }
.date-day   { font-size: 22px; font-weight: 800; line-height: 1; }
.date-month { font-size: 10px; font-weight: 700; text-transform: uppercase; }
.date-year  { font-size: 9px; opacity: 0.7; }

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
.upcoming-s  { background: #dbeafe; color: #2563eb; }
.ongoing-s   { background: #fff7ed; color: #f97316; }
.completed-s { background: #dcfce7; color: #22c55e; }
.cancelled-s { background: #fef2f2; color: #ef4444; }

.event-actions { display: flex; flex-direction: column; gap: 6px; }
.act-btn { width: 30px; height: 30px; border-radius: 8px; border: none; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.15s; }
.act-btn.view   { background: #f0fdf4; color: #22c55e; }
.act-btn.edit   { background: #eff6ff; color: #2563eb; }
.act-btn.delete { background: #fef2f2; color: #ef4444; }
.act-btn.view:hover   { background: #dcfce7; }
.act-btn.edit:hover:not(.act-btn--disabled)   { background: #dbeafe; }
.act-btn.delete:hover:not(.act-btn--disabled) { background: #fee2e2; }
.act-btn--disabled { background: #f1f5f9 !important; color: #cbd5e1 !important; cursor: not-allowed !important; opacity: 0.7; }

/* ── CALENDAR ───────────────────────────────────────────────────── */
.calendar-card { background: #fff; border-radius: 14px; padding: 20px; border: 1px solid #f1f5f9; }
.cal-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
.cal-nav { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; width: 32px; height: 32px; cursor: pointer; font-size: 16px; color: #64748b; display: flex; align-items: center; justify-content: center; }
.cal-nav:hover { background: #e2e8f0; }

.cal-month-picker { position: relative; }
.cal-month-btn { display: flex; align-items: center; gap: 6px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 6px 14px; font-size: 15px; font-weight: 700; color: #1e293b; cursor: pointer; font-family: inherit; transition: background 0.15s; }
.cal-month-btn:hover { background: #eff6ff; border-color: #bfdbfe; color: #2563eb; }
.cal-picker-dropdown { position: absolute; top: calc(100% + 6px); left: 50%; transform: translateX(-50%); background: #fff; border: 1px solid #e2e8f0; border-radius: 12px; box-shadow: 0 8px 30px rgba(0,0,0,0.12); padding: 12px; z-index: 200; width: 220px; }
.cal-picker-year-row { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px solid #f1f5f9; }
.cal-picker-year { font-size: 14px; font-weight: 800; color: #1e293b; }
.cal-picker-nav { background: #f1f5f9; border: none; border-radius: 6px; width: 26px; height: 26px; cursor: pointer; font-size: 14px; color: #64748b; display: flex; align-items: center; justify-content: center; font-family: inherit; }
.cal-picker-nav:hover { background: #e2e8f0; }
.cal-picker-months { display: grid; grid-template-columns: repeat(3, 1fr); gap: 4px; }
.cal-picker-month-btn { padding: 7px 4px; border: none; border-radius: 7px; background: none; font-size: 12px; font-weight: 600; color: #475569; cursor: pointer; font-family: inherit; transition: all 0.12s; text-align: center; }
.cal-picker-month-btn:hover { background: #eff6ff; color: #2563eb; }
.cal-picker-month-btn.active { background: #2563eb; color: #fff; }
.picker-enter-active, .picker-leave-active { transition: opacity 0.15s, transform 0.15s; }
.picker-enter-from, .picker-leave-to { opacity: 0; transform: translateX(-50%) translateY(-6px); }

.cal-legend { display: flex; align-items: center; gap: 14px; margin-bottom: 14px; flex-wrap: wrap; }
.cal-legend-item { display: flex; align-items: center; gap: 5px; font-size: 11px; color: #64748b; font-weight: 500; }
.cal-legend-dot { width: 10px; height: 10px; border-radius: 3px; border: 1.5px solid transparent; display: inline-block; }

.cal-grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; }
.cal-day-label { text-align: center; font-size: 10px; font-weight: 700; color: #94a3b8; padding: 6px 0; text-transform: uppercase; }
.cal-cell { min-height: 110px; border-radius: 8px; border: 1px solid #e2e8f0; background: #fff; overflow: hidden; transition: background 0.12s; }
.cal-cell:not(.empty) { position: relative; cursor: pointer; }
.cal-cell.empty { border-color: transparent; background: transparent; }
.cal-cell:not(.empty):hover { background: #f8fafc; }
.cal-cell.today { border-color: #2563eb; box-shadow: inset 0 0 0 1px #2563eb; }
.cal-cell.today:not(.has) { background: #eff6ff; }

.cal-date { position: absolute; top: 5px; left: 6px; z-index: 3; font-size: 11px; font-weight: 700; color: #1e293b; line-height: 1; padding: 2px 6px; border-radius: 5px; background: rgba(255,255,255,0.92); box-shadow: 0 1px 3px rgba(15,23,42,0.07); pointer-events: none; }
.cal-cell.today .cal-date { color: #1d4ed8; }

.cal-events { position: absolute; inset: 0; padding: 26px 4px 4px 4px; display: flex; flex-direction: column; gap: 2px; overflow: hidden; }

/* Single-line event chip */
.cal-event-block { display: flex; align-items: center; gap: 4px; width: 100%; height: 20px; flex-shrink: 0; border-left: 2px solid; border-radius: 4px; padding: 0 5px; overflow: hidden; cursor: pointer; box-sizing: border-box; transition: filter 0.1s; }
.cal-event-block:hover { filter: brightness(0.93); }
.cal-event-time { font-size: 9px; font-weight: 800; opacity: 0.85; white-space: nowrap; flex-shrink: 0; line-height: 1; }
.cal-event-title { font-size: 10px; font-weight: 700; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; line-height: 1; flex: 1; min-width: 0; }
.cal-overflow { font-size: 9px; font-weight: 700; color: #94a3b8; padding: 1px 5px; line-height: 1.6; cursor: pointer; }
.cal-overflow:hover { color: #2563eb; }

/* ── Context Menu ────────────────────────────────────────────────── */
.ctx-menu {
  position: fixed; z-index: 500;
  background: #fff; border: 1px solid #e2e8f0; border-radius: 12px;
  box-shadow: 0 10px 40px rgba(0,0,0,0.15); width: 265px;
  overflow: hidden; font-family: 'Plus Jakarta Sans', sans-serif;
}
.ctx-menu-header { padding: 10px 14px 8px; border-bottom: 1px solid #f1f5f9; background: #f8fafc; }
.ctx-menu-date { font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.04em; }
.ctx-menu-section-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; padding: 8px 14px 4px; }
.ctx-menu-event-row { display: flex; align-items: center; gap: 8px; padding: 7px 14px; transition: background 0.1s; }
.ctx-menu-event-row:hover { background: #f8fafc; }
.ctx-menu-event-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.ctx-menu-event-info { flex: 1; min-width: 0; }
.ctx-menu-event-title { display: block; font-size: 12px; font-weight: 700; color: #1e293b; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.ctx-menu-event-meta  { display: block; font-size: 10px; color: #94a3b8; margin-top: 1px; }
.ctx-menu-action-btn { flex-shrink: 0; display: flex; align-items: center; gap: 4px; background: #f1f5f9; border: none; border-radius: 6px; padding: 4px 8px; font-size: 11px; font-weight: 600; color: #475569; cursor: pointer; font-family: inherit; transition: background 0.12s; white-space: nowrap; }
.ctx-menu-action-btn:hover { background: #dbeafe; color: #2563eb; }
.ctx-menu-divider { height: 1px; background: #f1f5f9; }
.ctx-menu-create-btn { display: flex; align-items: center; gap: 8px; width: 100%; padding: 10px 14px; background: none; border: none; cursor: pointer; font-size: 13px; font-weight: 600; color: #2563eb; font-family: inherit; transition: background 0.12s; text-align: left; }
.ctx-menu-create-btn:hover { background: #eff6ff; }
.ctx-enter-active, .ctx-leave-active { transition: opacity 0.15s, transform 0.15s; }
.ctx-enter-from, .ctx-leave-to { opacity: 0; transform: scale(0.96) translateY(-4px); }

/* Registrants modal */
.registrants-list { list-style: none; margin: 0; padding: 0; }
.registrant-row { padding: 12px 0; border-bottom: 1px solid #f1f5f9; }
.registrant-row:last-child { border-bottom: none; }
.registrant-name { font-size: 14px; font-weight: 700; color: #1e293b; }
.registrant-meta { font-size: 12px; color: #64748b; margin-top: 2px; }
.registrant-time { font-size: 11px; color: #94a3b8; margin-top: 4px; }

/* MODAL */
.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.4); z-index: 100; display: flex; align-items: center; justify-content: center; backdrop-filter: blur(2px); }
.modal { background: #fff; border-radius: 16px; width: 540px; max-width: 95vw; box-shadow: 0 20px 60px rgba(0,0,0,0.15); }
.modal-header { display: flex; align-items: flex-start; justify-content: space-between; padding: 18px 20px; border-bottom: 1px solid #f1f5f9; gap: 12px; }
.modal-header h3 { font-size: 16px; font-weight: 800; color: #1e293b; }
.drawer-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 16px; padding: 4px; border-radius: 6px; flex-shrink: 0; }
.modal-body { padding: 20px; display: flex; flex-direction: column; gap: 14px; }
.modal-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 16px 20px; border-top: 1px solid #f1f5f9; }

.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.form-group { display: flex; flex-direction: column; gap: 5px; }
.form-label { font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; }
.form-input { border: 1px solid #e2e8f0; border-radius: 8px; padding: 9px 12px; font-size: 13px; color: #1e293b; font-family: inherit; outline: none; background: #f8fafc; }
.form-date-hint { margin: 0; font-size: 12px; color: #64748b; }
.form-input:focus { border-color: #93c5fd; background: #fff; }
.form-textarea { border: 1px solid #e2e8f0; border-radius: 8px; padding: 9px 12px; font-size: 13px; color: #1e293b; font-family: inherit; outline: none; resize: vertical; background: #f8fafc; }

.modal-enter-active, .modal-leave-active { transition: opacity 0.2s; }
.modal-enter-active .modal, .modal-leave-active .modal { transition: transform 0.2s, opacity 0.2s; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
.modal-enter-from .modal, .modal-leave-to .modal { transform: scale(0.95); opacity: 0; }

.spinner-sm { width: 14px; height: 14px; flex-shrink: 0; border: 2px solid rgba(255,255,255,0.4); border-top-color: #fff; border-radius: 50%; animation: spin 0.7s linear infinite; display: inline-block; }
@keyframes spin { to { transform: rotate(360deg); } }

.pagination { display: flex; align-items: center; justify-content: space-between; padding: 14px 18px; background: #fff; border-radius: 14px; margin-top: 12px; border: 1px solid #f1f5f9; }
.page-info { font-size: 12px; color: #94a3b8; }
.page-btns { display: flex; gap: 4px; }
.page-btn { width: 30px; height: 30px; border-radius: 7px; border: 1px solid #e2e8f0; background: #fff; font-size: 12px; color: #64748b; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; }
.page-btn.active { background: #2563eb; color: #fff; border-color: #2563eb; }
.page-btn:disabled { opacity: 0.35; cursor: default; }
</style>