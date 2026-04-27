<template>
  <div class="page">

    <!-- SKELETON LOADER -->
    <div v-if="isLoading" style="width:100%;display:block;">
      <div class="skeleton" style="height:52px;border-radius:14px;margin-bottom:16px;"></div>

      <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-bottom:16px;">
        <div v-for="i in 3" :key="'s'+i" class="skeleton" style="height:72px;border-radius:14px;"></div>
      </div>

      <div class="skeleton" style="height:140px;border-radius:16px;margin-bottom:20px;"></div>

      <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:14px;">
        <div v-for="i in 6" :key="'g'+i" class="skeleton" style="height:260px;border-radius:14px;"></div>
      </div>
    </div>

    <!-- ERROR STATE -->
    <div v-else-if="fetchError" class="error-state">
      <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="1.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
      <p>Failed to load events</p>
      <button class="btn-retry" @click="fetchEvents()">Retry</button>
    </div>

    <div v-else>

      <!-- ── FILTERS BAR ──────────────────────────────────── -->
      <div class="filters-bar">
        <div class="event-tabs">
          <button
            v-for="tab in tabs" :key="tab.value"
            :class="['etab', { active: activeTab === tab.value }]"
            @click="activeTab = tab.value"
          >
            <span v-html="tab.icon"></span>
            {{ tab.label }}
            <span v-if="tab.count" class="etab-badge">{{ tab.count }}</span>
          </button>
        </div>

        <div class="filter-group">
          <div class="search-box">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            <input v-model="search" type="text" placeholder="Search events…" class="search-input"/>
          </div>

          <select v-model="filterType" class="filter-select">
            <option value="">All Types</option>
            <option value="Job Fair">Job Fair</option>
            <option value="Workshop">Workshop</option>
            <option value="Seminar">Seminar</option>
            <option value="Training">Training</option>
            <option value="Livelihood Program">Livelihood Program</option>
          </select>

          <div class="view-toggle">
            <button :class="['vtoggle', { active: viewMode === 'grid' }]" @click="viewMode = 'grid'">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>
            </button>
            <button :class="['vtoggle', { active: viewMode === 'list' }]" @click="viewMode = 'list'">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
            </button>
          </div>
        </div>
      </div>

      <!-- ── SUMMARY PILLS ──────────────────────────────────── -->
      <div class="stats-row">
        <div v-for="s in summaryStats" :key="s.label" class="stat-pill">
          <div class="stat-pill-icon" :style="{ background: s.bg }">
            <span v-html="s.icon" :style="{ color: s.color }"></span>
          </div>
          <div>
            <div class="stat-pill-value">{{ s.value }}</div>
            <div class="stat-pill-label">{{ s.label }}</div>
          </div>
        </div>
      </div>

      <!-- ── FEATURED BANNER ──────────────────────────────────── -->
      <div v-if="featuredEvent" class="featured-banner">
        <div class="featured-left">
          <div class="featured-badge">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
            Next Up
          </div>
          <h2 class="featured-title">{{ featuredEvent.title }}</h2>
          <p class="featured-meta">
            <span>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
              {{ featuredEvent.date }} · {{ featuredEvent.time }}
            </span>
            <span>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
              {{ featuredEvent.venue }}
            </span>
            <span>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
              {{ featuredEvent.participants }}{{ featuredEvent.maxParticipants ? '/' + featuredEvent.maxParticipants : '' }} registered
            </span>
          </p>
          <div class="featured-actions">
            <button class="btn-details" @click="openEventDetail(featuredEvent)">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
              View Details
            </button>
          </div>
        </div>
        <div class="featured-right">
          <div class="featured-countdown">
            <div class="countdown-label">Starts in</div>
            <div class="countdown-blocks">
              <div v-for="unit in countdown" :key="unit.label" class="cblock">
                <div class="cblock-val">{{ unit.value }}</div>
                <div class="cblock-label">{{ unit.label }}</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- ── EVENTS GRID ──────────────────────────────────── -->
      <div v-if="viewMode === 'grid'" class="events-grid">
        <div
          v-for="(ev, idx) in filteredEvents" :key="ev.id"
          class="event-card"
          :style="{ animationDelay: idx * 0.05 + 's' }"
          @click="openEventDetail(ev)"
        >
          <div class="card-strip" :style="{ background: ev.color }"></div>
          <div class="card-body">
            <div class="card-top-row">
              <span class="event-type-badge" :style="{ background: ev.typeBg, color: ev.typeColor }">{{ ev.type }}</span>
              <span :class="['event-status-dot', ev.status.toLowerCase()]"></span>
              <span class="event-status-label" :class="ev.status.toLowerCase()">{{ ev.status }}</span>
            </div>

            <h3 class="card-title">{{ ev.title }}</h3>
            <p class="card-desc">{{ ev.description }}</p>

            <div class="card-info-list">
              <div class="card-info-row">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                <span>{{ ev.date }} · {{ ev.time }}</span>
              </div>
              <div class="card-info-row">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                <span>{{ ev.venue }}</span>
              </div>
              <div v-if="ev.organizer" class="card-info-row">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                <span>{{ ev.organizer }}</span>
              </div>
            </div>

            <div class="participants-row">
              <div class="participants-bar-wrap">
                <div class="participants-bar">
                  <div class="participants-fill"
                    :style="{ width: ev.maxParticipants ? Math.min((ev.participants / ev.maxParticipants) * 100, 100) + '%' : '0%', background: ev.color }">
                  </div>
                </div>
                <span class="participants-text">
                  {{ ev.participants }}{{ ev.maxParticipants ? '/' + ev.maxParticipants : '' }} registered
                </span>
              </div>
            </div>

            <div class="card-footer">
              <button class="btn-view-sm" @click.stop="openEventDetail(ev)">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                View Details
              </button>
            </div>
          </div>
        </div>

        <div v-if="filteredEvents.length === 0" class="empty-events">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          <p>No events found</p>
          <span>Try adjusting your filters or search</span>
        </div>
      </div>

      <!-- ── LIST VIEW ──────────────────────────────────── -->
      <div v-if="viewMode === 'list'" class="events-list-card">
        <table class="events-table">
          <thead>
            <tr>
              <th>Event</th>
              <th>Type</th>
              <th>Date & Time</th>
              <th>Location</th>
              <th>Participants</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="ev in filteredEvents" :key="ev.id" class="events-row" @click="openEventDetail(ev)">
              <td>
                <div class="list-event-cell">
                  <div class="list-color-bar" :style="{ background: ev.color }"></div>
                  <div>
                    <div class="list-event-title">{{ ev.title }}</div>
                    <div v-if="ev.organizer" class="list-event-org">{{ ev.organizer }}</div>
                  </div>
                </div>
              </td>
              <td><span class="event-type-badge" :style="{ background: ev.typeBg, color: ev.typeColor }">{{ ev.type }}</span></td>
              <td class="date-cell">{{ ev.date }}<br><span style="color:#94a3b8;font-size:11px;">{{ ev.time }}</span></td>
              <td class="loc-cell">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                {{ ev.venue }}
              </td>
              <td>
                <div class="list-participants">
                  <div class="participants-bar" style="width:80px">
                    <div class="participants-fill" :style="{ width: ev.maxParticipants ? Math.min((ev.participants / ev.maxParticipants) * 100, 100) + '%' : '0%', background: ev.color }"></div>
                  </div>
                  <span style="font-size:11px;color:#64748b;font-weight:600;">{{ ev.participants }}{{ ev.maxParticipants ? '/' + ev.maxParticipants : '' }}</span>
                </div>
              </td>
              <td><span :class="['status-badge', ev.status.toLowerCase()]">{{ ev.status }}</span></td>
              <td @click.stop>
                <button class="btn-view-sm" @click="openEventDetail(ev)">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  View
                </button>
              </td>
            </tr>
            <tr v-if="filteredEvents.length === 0">
              <td colspan="7" class="empty-row">No events found</td>
            </tr>
          </tbody>
        </table>

        <div v-if="lastPage > 1" class="pagination">
          <span class="page-info">Showing {{ events.length }} of {{ totalEvents }} events</span>
          <div class="page-btns">
            <button class="page-btn" :disabled="currentPage === 1" @click="changePage(currentPage - 1)">‹</button>
            <button v-for="p in paginationPages" :key="p" class="page-btn" :class="{ active: currentPage === p }" @click="changePage(p)">{{ p }}</button>
            <button class="page-btn" :disabled="currentPage === lastPage" @click="changePage(currentPage + 1)">›</button>
          </div>
        </div>
      </div>

    </div>

    <!-- ── EVENT DETAIL MODAL ──────────────────────────────────── -->
    <transition name="modal">
      <div v-if="showDetailModal" class="modal-overlay" @click.self="showDetailModal = false">
        <div class="modal modal-detail">
          <button class="modal-close" @click="showDetailModal = false">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>

          <div v-if="selectedEvent" class="modal-detail-content">
            <div class="detail-strip" :style="{ background: selectedEvent.color }"></div>
            <div class="detail-body">
              <div class="detail-header-row">
                <span class="event-type-badge" :style="{ background: selectedEvent.typeBg, color: selectedEvent.typeColor }">{{ selectedEvent.type }}</span>
                <span :class="['status-badge', selectedEvent.status.toLowerCase()]">{{ selectedEvent.status }}</span>
              </div>
              <h2 class="detail-title">{{ selectedEvent.title }}</h2>
              <p class="detail-desc">{{ selectedEvent.description || 'No description provided.' }}</p>

              <div class="detail-info-grid">
                <div class="detail-info-item">
                  <div class="detail-info-icon">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                  </div>
                  <div>
                    <div class="detail-info-label">Date</div>
                    <div class="detail-info-value">{{ selectedEvent.date }}</div>
                  </div>
                </div>
                <div class="detail-info-item">
                  <div class="detail-info-icon">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                  </div>
                  <div>
                    <div class="detail-info-label">Time</div>
                    <div class="detail-info-value">{{ selectedEvent.time }}</div>
                  </div>
                </div>
                <div class="detail-info-item">
                  <div class="detail-info-icon">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                  </div>
                  <div>
                    <div class="detail-info-label">Location</div>
                    <div class="detail-info-value">{{ selectedEvent.venue }}</div>
                  </div>
                </div>
                <div v-if="selectedEvent.organizer" class="detail-info-item">
                  <div class="detail-info-icon">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                  </div>
                  <div>
                    <div class="detail-info-label">Organizer</div>
                    <div class="detail-info-value">{{ selectedEvent.organizer }}</div>
                  </div>
                </div>
              </div>

              <div class="detail-participants">
                <div class="detail-participants-header">
                  <span class="detail-info-label">Participants</span>
                  <span class="detail-info-value">
                    {{ selectedEvent.participants }}{{ selectedEvent.maxParticipants ? ' / ' + selectedEvent.maxParticipants : '' }}
                  </span>
                </div>
                <div v-if="selectedEvent.maxParticipants">
                  <div class="participants-bar" style="height:8px;border-radius:99px;">
                    <div class="participants-fill"
                      :style="{ width: Math.min((selectedEvent.participants / selectedEvent.maxParticipants) * 100, 100) + '%', background: selectedEvent.color }">
                    </div>
                  </div>
                  <span class="detail-seats-left">{{ selectedEvent.maxParticipants - selectedEvent.participants }} slots remaining</span>
                </div>
              </div>

              <div class="detail-footer">
                <button class="btn-ghost-modal" @click="showDetailModal = false">Close</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </transition>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import employerApi from '@/services/employerApi'

// ── State ──────────────────────────────────────────────────────────
const isLoading       = ref(true)
const fetchError      = ref(false)
const activeTab       = ref('all')
const search          = ref('')
const filterType      = ref('')
const viewMode        = ref('grid')
const showDetailModal = ref(false)
const selectedEvent   = ref(null)
const now             = ref(new Date())
let clockTimer        = null

// ── Pagination ─────────────────────────────────────────────────────
const events      = ref([])
const currentPage = ref(1)
const lastPage    = ref(1)
const totalEvents = ref(0)

// ── Type → color map ───────────────────────────────────────────────
const TYPE_MAP = {
  'Job Fair':           { color: '#1a5f8a', bg: '#eff8ff', strip: '#2872A1' },
  'Workshop':           { color: '#7c3aed', bg: '#faf5ff', strip: '#a855f7' },
  'Seminar':            { color: '#c2410c', bg: '#fff7ed', strip: '#f97316' },
  'Training':           { color: '#15803d', bg: '#f0fdf4', strip: '#22c55e' },
  'Livelihood Program': { color: '#0e7490', bg: '#f0fdff', strip: '#06b6d4' },
}
const FALLBACK = { color: '#475569', bg: '#f8fafc', strip: '#94a3b8' }

// ── Helpers ────────────────────────────────────────────────────────
function formatDate(dateStr) {
  if (!dateStr) return ''
  // Strip time part if present
  const clean = dateStr.includes('T') ? dateStr.split('T')[0] : dateStr
  const [y, m, d] = clean.split('-').map(Number)
  const date = new Date(y, m - 1, d)  // local date, no timezone shift
  return date.toLocaleDateString('en-US', { month: 'short', day: '2-digit', year: 'numeric' })
}

function formatTime(start, end) {
  const fmt = (t) => t ? new Date(`2000-01-01T${t}`).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }) : ''
  return end ? `${fmt(start)} – ${fmt(end)}` : fmt(start)
}

function mapEvent(e) {
  const ts = TYPE_MAP[e.type] || FALLBACK

  // Normalize event_date to YYYY-MM-DD regardless of what Laravel sends
  let rawDate = e.event_date || ''
  if (rawDate.includes('T')) rawDate = rawDate.split('T')[0]  // strip time part

  let eventDateTime = null
  if (rawDate) {
    const timeStr    = e.start_time ? e.start_time : '00:00:00'
    const normalized = timeStr.length === 5 ? timeStr + ':00' : timeStr
    eventDateTime    = new Date(`${rawDate}T${normalized}`)
    if (isNaN(eventDateTime.getTime())) {
      eventDateTime = new Date(rawDate.replace(/-/g, '/'))
    }
  }

  return {
    id:              e.id,
    title:           e.title          || '',
    description:     e.description    || '',
    type:            e.type           || '',
    venue:           e.location       || '',
    organizer:       e.organizer      || '',
    date:            formatDate(rawDate),   // 👈 use rawDate here too
    time:            formatTime(e.start_time, e.end_time),
    event_date:      eventDateTime,
    participants:    e.participants_count || 0,
    maxParticipants: e.max_participants  || 0,
    status:          e.status
                       ? e.status.charAt(0).toUpperCase() + e.status.slice(1)
                       : 'Upcoming',
    color:     ts.strip,
    typeBg:    ts.bg,
    typeColor: ts.color,
  }
}

// ── Fetch ──────────────────────────────────────────────────────────
async function fetchEvents(page = 1) {
  isLoading.value  = true
  fetchError.value = false
  try {
    const { data } = await employerApi.getEvents({ page })
    const payload  = data.data

    currentPage.value = payload.current_page || 1
    lastPage.value    = payload.last_page    || 1
    totalEvents.value = payload.total        || 0
    events.value      = (payload.data || []).map(mapEvent)
  } catch (e) {
    console.error('[EmployerEvents] fetch error:', e)
    fetchError.value = true
  } finally {
    isLoading.value = false
  }
}

function changePage(page) {
  if (page >= 1 && page <= lastPage.value) fetchEvents(page)
}

const paginationPages = computed(() => {
  const pages = [], start = Math.max(1, currentPage.value - 2), end = Math.min(lastPage.value, currentPage.value + 2)
  for (let i = start; i <= end; i++) pages.push(i)
  return pages
})

// ── Tabs ───────────────────────────────────────────────────────────
const tabs = computed(() => [
  { value: 'all',       label: 'All Events', count: events.value.length,
    icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>' },
  { value: 'upcoming',  label: 'Upcoming',   count: events.value.filter(e => e.status === 'Upcoming').length,
    icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>' },
  { value: 'ongoing',   label: 'Ongoing',    count: events.value.filter(e => e.status === 'Ongoing').length,
    icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="5 3 19 12 5 21 5 3"/></svg>' },
])

// ── Summary stats ──────────────────────────────────────────────────
const summaryStats = computed(() => [
  { label: 'Total Events', value: totalEvents.value || events.value.length,
    icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>',
    bg: '#eff8ff', color: '#2872A1' },
  { label: 'Upcoming',  value: events.value.filter(e => e.status === 'Upcoming').length,
    icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>',
    bg: '#eff6ff', color: '#3b82f6' },
  { label: 'Ongoing',   value: events.value.filter(e => e.status === 'Ongoing').length,
    icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="5 3 19 12 5 21 5 3"/></svg>',
    bg: '#fff7ed', color: '#f97316' },
])

// ── Featured ───────────────────────────────────────────────────────
const featuredEvent = computed(() => {
  const ongoing = events.value.filter(e => e.status === 'Ongoing')
  if (ongoing.length) return ongoing[0]

  return events.value
    .filter(e => e.status === 'Upcoming' && e.event_date)
    .sort((a, b) => a.event_date - b.event_date)[0] || null
})

// ── Countdown ──────────────────────────────────────────────────────
const countdown = computed(() => {
  if (!featuredEvent.value?.event_date) return []
  const diff = featuredEvent.value.event_date - now.value
  if (diff <= 0) return [{ value: '00', label: 'days' }, { value: '00', label: 'hrs' }, { value: '00', label: 'min' }]
  return [
    { value: String(Math.floor(diff / 86400000)).padStart(2, '0'),                     label: 'days' },
    { value: String(Math.floor((diff % 86400000) / 3600000)).padStart(2, '0'),         label: 'hrs'  },
    { value: String(Math.floor((diff % 3600000) / 60000)).padStart(2, '0'),            label: 'min'  },
  ]
})

// ── Filtered (client-side within the loaded page) ──────────────────
const filteredEvents = computed(() => {
  // Never show completed events to employers
  let list = events.value.filter(e => e.status !== 'Completed' && e.status !== 'Cancelled')

  if (activeTab.value === 'upcoming') list = list.filter(e => e.status === 'Upcoming')
  if (activeTab.value === 'ongoing')  list = list.filter(e => e.status === 'Ongoing')
  if (filterType.value)               list = list.filter(e => e.type === filterType.value)
  if (search.value.trim()) {
    const q = search.value.toLowerCase()
    list = list.filter(e =>
      e.title.toLowerCase().includes(q) ||
      e.venue.toLowerCase().includes(q) ||
      (e.organizer && e.organizer.toLowerCase().includes(q))
    )
  }
  return list
})

// ── Actions ────────────────────────────────────────────────────────
function openEventDetail(ev) {
  selectedEvent.value   = ev
  showDetailModal.value = true
}

// ── Lifecycle ──────────────────────────────────────────────────────
onMounted(() => {
  fetchEvents()
  clockTimer = setInterval(() => { now.value = new Date() }, 60000)
})
onUnmounted(() => clearInterval(clockTimer))
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; }

.page { 
  padding: 20px; 
  font-family: 'Plus Jakarta Sans', sans-serif; 
  background: #f8fafc; 
  min-height: 100vh; 
  width: 100%;        /* 👈 add this */
  box-sizing: border-box; /* 👈 add this */
}
/* ── SKELETON ── */
.skeleton { 
  background: linear-gradient(90deg, #e2e8f0 25%, #cbd5e1 50%, #e2e8f0 75%); 
  background-size: 200% 100%; 
  animation: shimmer 1.5s infinite; 
  border: none !important; 
  box-shadow: none !important;
  display: block;  /* 👈 force block */
  width: 100%;     /* 👈 force full width */
}@keyframes shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }

/* ── ERROR ── */
.error-state { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 12px; padding: 80px 20px; }
.error-state p { font-size: 14px; font-weight: 600; color: #94a3b8; margin: 0; }
.btn-retry { font-size: 12.5px; font-weight: 700; color: #2872A1; background: #eff8ff; border: 1.5px solid #bae6fd; border-radius: 8px; padding: 7px 18px; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.btn-retry:hover { background: #dbeafe; }

/* ── FILTERS BAR ── */
.filters-bar { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px; background: #fff; border: 1px solid #e8eef4; border-radius: 14px; padding: 10px 16px; margin-bottom: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
.event-tabs { display: flex; gap: 4px; flex-wrap: wrap; }
.etab { display: inline-flex; align-items: center; gap: 6px; font-size: 12.5px; font-weight: 600; color: #64748b; background: transparent; border: 1.5px solid transparent; border-radius: 8px; padding: 6px 12px; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.etab:hover { background: #f8fafc; color: #1e293b; }
.etab.active { color: #2872A1; border-color: #2872A1; background: #eff8ff; }
.etab-badge { font-size: 10px; font-weight: 700; background: #e2e8f0; color: #64748b; padding: 1px 6px; border-radius: 99px; }
.etab.active .etab-badge { background: #2872A1; color: #fff; }
.filter-group { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 6px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 6px 10px; }
.search-input { border: none; background: transparent; font-size: 12px; color: #1e293b; outline: none; width: 160px; font-family: inherit; }
.search-input::placeholder { color: #94a3b8; }
.filter-select { font-size: 12px; color: #475569; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 6px 10px; outline: none; font-family: inherit; cursor: pointer; }
.view-toggle { display: flex; border: 1px solid #e2e8f0; border-radius: 8px; overflow: hidden; }
.vtoggle { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; background: #fff; border: none; cursor: pointer; color: #94a3b8; transition: all 0.12s; }
.vtoggle:hover { background: #f8fafc; color: #475569; }
.vtoggle.active { background: #eff8ff; color: #2872A1; }

/* ── SUMMARY PILLS ── */
.stats-row { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; margin-bottom: 16px; }
.stat-pill { display: flex; align-items: center; gap: 12px; background: #fff; border: 1px solid #e8eef4; border-radius: 14px; padding: 14px 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
.stat-pill-icon { width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.stat-pill-value { font-size: 20px; font-weight: 800; color: #1e293b; line-height: 1.1; }
.stat-pill-label { font-size: 11px; color: #94a3b8; font-weight: 500; margin-top: 2px; }

/* ── FEATURED BANNER ── */
.featured-banner { display: flex; align-items: stretch; justify-content: space-between; background: linear-gradient(135deg, #1a4d72 0%, #2872A1 60%, #3b8bbf 100%); border-radius: 16px; padding: 24px 28px; margin-bottom: 20px; gap: 20px; box-shadow: 0 4px 20px rgba(40,114,161,0.25); overflow: hidden; position: relative; }
.featured-banner::before { content: ''; position: absolute; top: -40px; right: -40px; width: 200px; height: 200px; border-radius: 50%; background: rgba(255,255,255,0.05); pointer-events: none; }
.featured-left { flex: 1; }
.featured-badge { display: inline-flex; align-items: center; gap: 5px; background: rgba(255,255,255,0.15); color: #fff; font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 99px; margin-bottom: 10px; letter-spacing: 0.03em; }
.featured-title { font-size: 20px; font-weight: 800; color: #fff; margin: 0 0 10px; }
.featured-meta { display: flex; gap: 16px; flex-wrap: wrap; font-size: 12.5px; color: rgba(255,255,255,0.75); margin-bottom: 16px; }
.featured-meta span { display: flex; align-items: center; gap: 5px; }
.featured-actions { display: flex; gap: 10px; }
.btn-details { display: inline-flex; align-items: center; gap: 6px; background: rgba(255,255,255,0.15); color: #fff; font-size: 12.5px; font-weight: 600; padding: 9px 18px; border-radius: 9px; border: 1.5px solid rgba(255,255,255,0.3); cursor: pointer; font-family: inherit; transition: all 0.15s; }
.btn-details:hover { background: rgba(255,255,255,0.25); }
.featured-right { display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.featured-countdown { text-align: center; }
.countdown-label { font-size: 11px; color: rgba(255,255,255,0.6); font-weight: 600; margin-bottom: 10px; text-transform: uppercase; letter-spacing: 0.05em; }
.countdown-blocks { display: flex; gap: 8px; }
.cblock { background: rgba(255,255,255,0.12); border: 1px solid rgba(255,255,255,0.18); border-radius: 10px; padding: 10px 14px; text-align: center; min-width: 56px; }
.cblock-val { font-size: 24px; font-weight: 800; color: #fff; line-height: 1; }
.cblock-label { font-size: 9px; color: rgba(255,255,255,0.55); font-weight: 600; text-transform: uppercase; letter-spacing: 0.06em; margin-top: 3px; }

/* ── EVENTS GRID ── */
.events-grid { 
  display: grid; 
  grid-template-columns: repeat(3, 1fr); 
  gap: 14px; 
  min-height: 320px;
  align-content: start;  /* 👈 prevents vertical stretch collapse */
}

.empty-events { 
  grid-column: 1 / -1; 
  min-height: 280px;   /* 👈 give it a real height */
  display: flex; 
  flex-direction: column; 
  align-items: center; 
  justify-content: center; 
  padding: 60px 20px; 
  gap: 10px; 
}
.event-card { background: #fff; border: 1px solid #e8eef4; border-radius: 14px; overflow: hidden; cursor: pointer; transition: all 0.2s; animation: slideUp 0.35s ease both; box-shadow: 0 1px 4px rgba(0,0,0,0.04); }
.event-card:hover { transform: translateY(-3px); box-shadow: 0 8px 24px rgba(40,114,161,0.12); border-color: #bae6fd; }
.card-strip { height: 4px; width: 100%; }
.card-body { padding: 16px; }
.card-top-row { display: flex; align-items: center; gap: 6px; margin-bottom: 10px; }
.event-type-badge { font-size: 10.5px; font-weight: 700; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
.event-status-dot { width: 6px; height: 6px; border-radius: 50%; flex-shrink: 0; margin-left: auto; }
.event-status-dot.upcoming  { background: #3b82f6; }
.event-status-dot.ongoing   { background: #22c55e; animation: pulse 1.5s infinite; }
.event-status-dot.completed { background: #94a3b8; }
.event-status-dot.cancelled { background: #ef4444; }
@keyframes pulse { 0%,100% { opacity:1; } 50% { opacity:0.4; } }
.event-status-label { font-size: 11px; font-weight: 600; }
.event-status-label.upcoming  { color: #3b82f6; }
.event-status-label.ongoing   { color: #22c55e; }
.event-status-label.completed { color: #94a3b8; }
.event-status-label.cancelled { color: #ef4444; }
.card-title { font-size: 14px; font-weight: 700; color: #1e293b; margin: 0 0 5px; line-height: 1.3; }
.card-desc { font-size: 11.5px; color: #94a3b8; margin: 0 0 12px; line-height: 1.5; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.card-info-list { display: flex; flex-direction: column; gap: 5px; margin-bottom: 12px; }
.card-info-row { display: flex; align-items: center; gap: 6px; font-size: 11.5px; color: #475569; }
.participants-row { margin-bottom: 12px; }
.participants-bar-wrap { display: flex; align-items: center; gap: 6px; }
.participants-bar { flex: 1; height: 5px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.participants-fill { height: 100%; border-radius: 99px; transition: width 0.75s cubic-bezier(.4,0,.2,1); }
.participants-text { font-size: 10.5px; font-weight: 600; color: #64748b; white-space: nowrap; }
.card-footer { display: flex; align-items: center; border-top: 1px solid #f1f5f9; padding-top: 12px; }
.btn-view-sm { flex: 1; display: inline-flex; align-items: center; justify-content: center; gap: 5px; font-size: 12px; font-weight: 700; color: #2872A1; background: #eff8ff; border: 1.5px solid #bae6fd; border-radius: 8px; padding: 7px 12px; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.btn-view-sm:hover { background: #dbeafe; border-color: #2872A1; }
.empty-events p { font-size: 14px; font-weight: 600; color: #94a3b8; margin: 0; }
.empty-events span { font-size: 12px; color: #cbd5e1; }

/* ── LIST VIEW ── */
.events-list-card { background: #fff; border: 1px solid #e8eef4; border-radius: 14px; overflow: hidden; box-shadow: 0 1px 4px rgba(0,0,0,0.04); }
.events-table { width: 100%; border-collapse: collapse; font-size: 12.5px; }
.events-table th { text-align: left; padding: 10px 14px; color: #94a3b8; font-weight: 700; font-size: 11px; border-bottom: 1.5px solid #f1f5f9; text-transform: uppercase; letter-spacing: 0.05em; background: #f8fafc; }
.events-row { cursor: pointer; transition: background 0.12s; }
.events-row:hover { background: #fafbff; }
.events-row td { padding: 14px; border-bottom: 1px solid #f8fafc; vertical-align: middle; }
.events-row:last-child td { border-bottom: none; }
.list-event-cell { display: flex; align-items: center; gap: 10px; }
.list-color-bar { width: 4px; height: 38px; border-radius: 99px; flex-shrink: 0; }
.list-event-title { font-size: 13px; font-weight: 700; color: #1e293b; }
.list-event-org { font-size: 11px; color: #94a3b8; margin-top: 2px; }
.list-participants { display: flex; align-items: center; gap: 8px; }
.date-cell { color: #475569; white-space: nowrap; }
.loc-cell { display: flex; align-items: center; gap: 5px; font-size: 12px; color: #475569; }
.empty-row { text-align: center; color: #94a3b8; font-size: 13px; padding: 40px 0 !important; }
.pagination { display: flex; align-items: center; justify-content: space-between; padding: 14px 18px; border-top: 1px solid #f1f5f9; }
.page-info { font-size: 12px; color: #94a3b8; }
.page-btns { display: flex; gap: 4px; }
.page-btn { width: 30px; height: 30px; border-radius: 7px; border: 1px solid #e2e8f0; background: #fff; font-size: 12px; color: #64748b; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; transition: all 0.12s; }
.page-btn:hover:not(:disabled) { border-color: #2872A1; color: #2872A1; }
.page-btn.active { background: #2872A1; color: #fff; border-color: #2872A1; }
.page-btn:disabled { opacity: 0.35; cursor: default; }

/* ── STATUS BADGES ── */
.status-badge { padding: 3px 10px; border-radius: 99px; font-size: 11px; font-weight: 600; white-space: nowrap; }
.upcoming  { background: #eff6ff; color: #3b82f6; }
.ongoing   { background: #f0fdf4; color: #22c55e; }
.completed { background: #f8fafc; color: #64748b; }
.cancelled { background: #fef2f2; color: #ef4444; }

/* ── MODAL ── */
.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.4); display: flex; align-items: center; justify-content: center; z-index: 1000; padding: 20px; backdrop-filter: blur(4px); }
.modal { background: #fff; border-radius: 18px; width: 100%; max-width: 460px; box-shadow: 0 20px 60px rgba(0,0,0,0.18); overflow: hidden; position: relative; }
.modal-detail { max-width: 520px; }
.modal-close { position: absolute; top: 14px; right: 14px; width: 30px; height: 30px; border-radius: 8px; background: #f8fafc; border: 1px solid #e2e8f0; display: flex; align-items: center; justify-content: center; cursor: pointer; color: #64748b; z-index: 2; transition: all 0.12s; }
.modal-close:hover { background: #fef2f2; color: #ef4444; border-color: #fecaca; }
.detail-strip { height: 5px; }
.detail-body { padding: 24px; }
.detail-header-row { display: flex; gap: 8px; margin-bottom: 10px; }
.detail-title { font-size: 18px; font-weight: 800; color: #1e293b; margin: 0 0 8px; }
.detail-desc { font-size: 12.5px; color: #64748b; margin: 0 0 20px; line-height: 1.6; }
.detail-info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 20px; }
.detail-info-item { display: flex; align-items: flex-start; gap: 10px; }
.detail-info-icon { width: 32px; height: 32px; background: #eff8ff; border-radius: 8px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.detail-info-label { font-size: 10.5px; color: #94a3b8; font-weight: 600; text-transform: uppercase; letter-spacing: 0.04em; }
.detail-info-value { font-size: 13px; font-weight: 600; color: #1e293b; margin-top: 2px; }
.detail-participants { margin-bottom: 20px; }
.detail-participants-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.detail-seats-left { font-size: 11px; color: #94a3b8; margin-top: 5px; display: block; }
.detail-footer { display: flex; gap: 10px; padding-top: 16px; border-top: 1px solid #f1f5f9; }
.btn-ghost-modal { font-size: 12.5px; font-weight: 600; color: #64748b; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 9px; padding: 10px 18px; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.btn-ghost-modal:hover { background: #f1f5f9; }

/* ── ANIMATIONS ── */
@keyframes slideUp { from { opacity:0; transform:translateY(10px); } to { opacity:1; transform:translateY(0); } }
.modal-enter-active, .modal-leave-active { transition: all 0.2s ease; }
.modal-enter-from, .modal-leave-to { opacity: 0; transform: scale(0.95); }

/* ── RESPONSIVE ── */
@media (max-width: 1100px) { .events-grid { grid-template-columns: repeat(2, 1fr); } .stats-row { grid-template-columns: repeat(3, 1fr); } }
@media (max-width: 700px)  { .events-grid { grid-template-columns: 1fr; } .stats-row { grid-template-columns: 1fr; } .featured-right { display: none; } .filters-bar { flex-direction: column; align-items: flex-start; } }
</style>