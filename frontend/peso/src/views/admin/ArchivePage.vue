<template>
  <div class="page">
    <!-- Toast -->
    <transition name="toast">
      <div v-if="toast.show" class="toast" :class="toast.type">
        <span class="toast-icon" v-html="toast.icon"></span>
        <span class="toast-msg">{{ toast.text }}</span>
      </div>
    </transition>

    <!-- SKELETON — initial counts load -->
    <template v-if="isLoading && !countsFetched">
      <div class="type-tabs" style="margin-bottom: 16px;">
        <div v-for="i in 6" :key="i" class="skel" style="width: 100px; height: 34px; border-radius: 8px;"></div>
      </div>
      <div class="filters-bar" style="margin-bottom: 20px;">
        <div class="skel" style="width: 300px; height: 38px; border-radius: 10px;"></div>
        <div class="skel" style="width: 120px; height: 36px; border-radius: 8px;"></div>
      </div>
      <div class="table-card" style="padding: 20px;">
        <div v-for="i in 5" :key="i" class="skel" style="width: 100%; height: 50px; border-radius: 8px; margin-bottom: 10px;"></div>
      </div>
    </template>

    <!-- ACTUAL CONTENT -->
    <template v-else>
      <!-- Type Tabs -->
      <div class="type-tabs">
        <button v-for="tab in typeTabs" :key="tab.value"
          :class="['tab-btn', { active: activeTab === tab.value }]"
          @click="switchTab(tab.value)">
          <span v-html="tab.icon" class="tab-icon"></span>
          {{ tab.label }}
          <span class="tab-count">{{ tab.count || 0 }}</span>
        </button>
      </div>

      <!-- Filters -->
      <div class="filters-bar">
        <div class="search-box">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <input v-model="search" type="text" placeholder="Search archived records…" class="search-input"/>
        </div>
        <select v-model="filterDate" class="filter-select">
          <option value="">All Time</option>
          <option value="today">Today</option>
          <option value="week">This Week</option>
          <option value="month">This Month</option>
        </select>
      </div>

      <!-- Table — always shown -->
      <div class="table-card">

        <!-- Per-tab skeleton while loading records -->
        <template v-if="tabLoading">
          <div style="padding: 16px 20px;">
            <div v-for="i in 6" :key="i" class="skel" style="width: 100%; height: 48px; border-radius: 8px; margin-bottom: 8px;"></div>
          </div>
        </template>

        <template v-else>
          <table class="data-table">
            <thead>
              <tr>
                <th>Record</th>
                <th>Type</th>
                <th>Deleted At</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="record in filteredRecords" :key="`${record.type}-${record.id}`" class="table-row">
                <td>
                  <div class="record-cell">
                    <div class="record-icon" :style="{ background: typeColor(record.type).bg, color: typeColor(record.type).text }">
                      <span v-html="typeIcon(record.type)"></span>
                    </div>
                    <div>
                      <p class="record-name">{{ record.name }}</p>
                      <p class="record-detail">{{ record.detail }}</p>
                    </div>
                  </div>
                </td>
                <td><span class="type-badge" :style="{ background: typeColor(record.type).bg, color: typeColor(record.type).text }">{{ typeLabel(record.type) }}</span></td>
                <td class="date-cell">{{ record.deletedAt }}</td>
                <td>
                  <div class="action-btns">
                    <button class="act-btn restore" @click="openRestoreModal(record)" title="Restore">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 102.13-9.36L1 10"/></svg>
                    </button>
                    <button class="act-btn view" @click="viewRecord(record)" title="View">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="filteredRecords.length === 0 && !tabLoading">
                <td colspan="4" class="empty-cell">
                  <div class="empty-state">
                    <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.5"><polyline points="21 8 21 21 3 21 3 8"/><rect x="1" y="3" width="22" height="5"/><line x1="10" y1="12" x2="14" y2="12"/></svg>
                    <p>No archived records found</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </template>

      </div>
    </template>

    <!-- Restore Confirmation Modal -->
    <transition name="modal">
      <div v-if="showRestoreModal" class="modal-overlay" @click.self="showRestoreModal = false">
        <div class="modal-box">
          <div class="modal-icon restore-icon">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 102.13-9.36L1 10"/></svg>
          </div>
          <h3 class="modal-title">Restore Record?</h3>
          <p class="modal-desc">Are you sure you want to restore <strong>"{{ recordToRestore?.name }}"</strong>? It will be moved back to the <strong>{{ typeLabel(recordToRestore?.type) }}</strong> section.</p>
          <div class="modal-actions">
            <button class="modal-btn ghost" @click="showRestoreModal = false" :disabled="restoring">Cancel</button>
            <button class="modal-btn confirm-restore" :disabled="restoring" @click="doRestore">
              <span v-if="restoring" class="modal-spinner"></span>
              <span v-else>Yes, Restore</span>
            </button>
          </div>
        </div>
      </div>
    </transition>

    <!-- View Record Modal -->
    <transition name="modal">
      <div v-if="viewingRecord" class="modal-overlay" @click.self="viewingRecord = null">
        <div class="modal-box view-modal">
          <div class="view-modal-header">
            <div class="view-modal-icon" :style="{ background: typeColor(viewingRecord.type).bg, color: typeColor(viewingRecord.type).text }">
              <span v-html="typeIcon(viewingRecord.type)"></span>
            </div>
            <div>
              <h3 class="modal-title" style="margin-bottom:2px">{{ viewingRecord.name }}</h3>
              <span class="type-badge" :style="{ background: typeColor(viewingRecord.type).bg, color: typeColor(viewingRecord.type).text }">{{ viewingRecord.type }}</span>
            </div>
            <button class="modal-close-btn" @click="viewingRecord = null">✕</button>
          </div>
          <div class="view-fields">
            <div class="view-field">
              <span class="view-label">Name</span>
              <span class="view-val">{{ viewingRecord.name }}</span>
            </div>
            <div class="view-field">
              <span class="view-label">Detail</span>
              <span class="view-val">{{ viewingRecord.detail || '—' }}</span>
            </div>
            <div class="view-field">
              <span class="view-label">Type</span>
              <span class="view-val">{{ typeLabel(viewingRecord.type) }}</span>
            </div>
            <div class="view-field">
              <span class="view-label">Deleted At</span>
              <span class="view-val">{{ viewingRecord.deletedAt }}</span>
            </div>
          </div>
          <div class="modal-actions" style="margin-top:8px">
            <button class="modal-btn ghost" @click="viewingRecord = null">Close</button>
            <button class="modal-btn confirm-restore" @click="openRestoreModal(viewingRecord); viewingRecord = null">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 102.13-9.36L1 10"/></svg>
              Restore
            </button>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
import api from '@/services/api'

export default {
  name: 'ArchivePage',
  async mounted() {
    await this.fetchCounts()
  },
  data() {
    return {
      activeTab: 'all',
      search: '',
      filterDate: '',
      countsFetched: false,
      isLoading: false,
      tabLoading: false,
      typeTabs: [
        { label: 'All',          value: 'all',          count: 0, icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>` },
        { label: 'Employers',    value: 'employers',    count: 0, icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>` },
        { label: 'Jobseekers',   value: 'jobseekers',   count: 0, icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>` },
        { label: 'Events',       value: 'events',       count: 0, icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>` },
        { label: 'Users',        value: 'users',        count: 0, icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>` },
      ],
      records: [],
      toast: { show: false, text: '', type: 'success', icon: '', _timer: null },
      showRestoreModal: false,
      recordToRestore: null,
      restoring: false,
      viewingRecord: null,
    }
  },
  computed: {
    filteredRecords() {
      return this.records.filter(r => {
        return !this.search || r.name.toLowerCase().includes(this.search.toLowerCase())
      })
    },
  },
  methods: {
    /** Single call with type=all — backend returns everything at once. */
    async fetchCounts() {
      this.isLoading = true
      this.records = []
      try {
        const { data } = await api.get('/admin/archive', { params: { type: 'all' } })

        // Records already normalized by backend
        const list = data.data || []
        this.records = Array.isArray(list) ? list.map(item => ({
          id:        item.id,
          type:      item.type,
          name:      item.name,
          detail:    item.detail || '',
          deletedAt: item.deleted_at
            ? new Date(item.deleted_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
            : '—',
          itemData: item,
        })) : []

        // Use counts returned by backend
        const counts = data.counts || {}
        const tabMap = { employers: 1, jobseekers: 2, job_listings: 3, events: 4, users: 5 }
        let total = 0
        Object.entries(tabMap).forEach(([key, idx]) => {
          const count = counts[key] || 0
          this.typeTabs[idx].count = count
          total += count
        })
        this.typeTabs[0].count = total
        this.countsFetched = true
      } catch (e) {
        console.error(e)
      } finally {
        this.isLoading = false
      }
    },

    /** Fetch records for a specific tab switch (1 call). */
    async fetchTabRecords(type) {
      if (type === 'all') {
        // Already loaded on mount — just switch tab
        this.activeTab = 'all'
        return
      }
      this.tabLoading = true
      this.records = []
      try {
        const { data } = await api.get('/admin/archive', { params: { type } })
        const list = data.data?.data || data.data || []
        this.records = (Array.isArray(list) ? list : []).map(item => this.mapItem(item, type))
      } catch (e) {
        console.error(e)
      } finally {
        this.tabLoading = false
      }
    },

    switchTab(value) {
      this.activeTab = value
      this.search = ''
      if (value === 'all') {
        this.fetchCounts()
      } else {
        this.fetchTabRecords(value)
      }
    },

    mapItem(item, type) {
      let name = 'Unknown', detail = ''
      if (type === 'employers')    { name = item.company_name || 'Employer';   detail = item.email || '' }
      else if (type === 'jobseekers')   { name = `${item.first_name || ''} ${item.last_name || ''}`.trim() || 'Jobseeker'; detail = item.email || '' }
      else if (type === 'events')       { name = item.title || 'Event';        detail = item.location || '' }
      else if (type === 'users')        { name = item.name || `${item.first_name || ''} ${item.last_name || ''}`.trim() || 'User'; detail = item.email || '' }
      return {
        id:        item.id,
        type,
        name,
        detail,
        deletedAt: item.deleted_at ? new Date(item.deleted_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : '—',
        itemData:  item,
      }
    },

    typeLabel(type) {
      const map = { employers: 'Employers', jobseekers: 'Jobseekers', events: 'Events', users: 'Users' }
      return map[type] || (type ? type.charAt(0).toUpperCase() + type.slice(1) : '')
    },

    typeColor(type) {
      return {
        events:       { bg: '#fff7ed', text: '#f97316' },
        job_listings: { bg: '#dbeafe', text: '#2563eb' },
        jobseekers:   { bg: '#dcfce7', text: '#22c55e' },
        employers:    { bg: '#eff6ff', text: '#3b82f6' },
        users:        { bg: '#f3e8ff', text: '#9333ea' },
      }[type] || { bg: '#f1f5f9', text: '#64748b' }
    },

    typeIcon(type) {
      const icons = {
        events:       `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>`,
        job_listings: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>`,
        jobseekers:   `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>`,
        employers:    `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>`,
        users:        `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>`,
      }
      return icons[type] || ''
    },

    openRestoreModal(r) {
      this.recordToRestore = r
      this.restoring = false  // ← always reset before showing
      this.showRestoreModal = true
    },

    async doRestore() {
      const r = this.recordToRestore
      if (!r) return
      this.restoring = true
      try {
        await api.post(`/admin/archive/${r.type}/${r.id}/restore`)
        // Remove from list immediately
        this.records = this.records.filter(record => !(record.id === r.id && record.type === r.type))
        // Decrement count on the tab
        const tabIdx = this.typeTabs.findIndex(t => t.value === r.type)
        if (tabIdx !== -1 && this.typeTabs[tabIdx].count > 0) this.typeTabs[tabIdx].count--
        this.typeTabs[0].count = Math.max(0, this.typeTabs[0].count - 1)
        this.showToastMsg(`${r.name} restored successfully`, 'success')
      } catch (e) {
        console.error(e)
        this.showToastMsg('Failed to restore record', 'error')
      } finally {
        this.restoring = false       // ← always clear spinner
        this.showRestoreModal = false
        this.recordToRestore = null
      }
    },

    viewRecord(r) {
      this.viewingRecord = r
    },

    showToastMsg(text, type = 'success') {
      const CHECK = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>`
      const X     = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`
      if (this.toast._timer) clearTimeout(this.toast._timer)
      this.toast = { show: true, text, type, icon: type === 'success' ? CHECK : X, _timer: setTimeout(() => { this.toast.show = false }, 3500) }
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

@keyframes shimmer { 0% { background-position: -400px 0; } 100% { background-position: 400px 0; } }
@keyframes spin    { to { transform: rotate(360deg); } }

.skel { background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%); background-size: 400px 100%; animation: shimmer 1.4s infinite linear; border-radius: 6px; flex-shrink: 0; }

.page { font-family: 'Plus Jakarta Sans', sans-serif; padding: 24px; background: #f8fafc; min-height: 100vh; display: flex; flex-direction: column; gap: 16px; }

/* TABS */
.type-tabs { display: flex; gap: 4px; flex-wrap: wrap; }
.tab-btn { display: flex; align-items: center; gap: 6px; background: none; border: none; padding: 8px 14px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; border-radius: 8px; font-family: inherit; transition: all 0.15s; }
.tab-btn:hover  { background: #f1f5f9; }
.tab-btn.active { background: #eff6ff; color: #2563eb; font-weight: 700; }
.tab-icon { display: flex; align-items: center; }
.tab-count { font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }

/* FILTERS */
.filters-bar { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; flex: 1; max-width: 360px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }

/* TABLE */
.table-card { background: #fff; border-radius: 14px; overflow: hidden; border: 1px solid #f1f5f9; }
.data-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.data-table thead tr { background: #f8fafc; }
.data-table th { text-align: left; padding: 11px 14px; font-size: 11px; font-weight: 700; color: #94a3b8; letter-spacing: 0.04em; text-transform: uppercase; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.table-row { transition: background 0.12s; }
.table-row:hover { background: #f8fafc; }
.data-table td { padding: 12px 14px; border-bottom: 1px solid #f8fafc; vertical-align: middle; }

.record-cell { display: flex; align-items: center; gap: 10px; }
.record-icon { width: 36px; height: 36px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.record-name   { font-size: 13px; font-weight: 600; color: #1e293b; }
.record-detail { font-size: 11px; color: #94a3b8; margin-top: 2px; }
.type-badge { font-size: 11px; font-weight: 600; padding: 3px 9px; border-radius: 6px; white-space: nowrap; }
.date-cell  { color: #94a3b8; font-size: 12px; white-space: nowrap; }

.action-btns { display: flex; gap: 4px; }
.act-btn { width: 28px; height: 28px; border-radius: 7px; border: none; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.15s; }
.act-btn.restore       { background: #dcfce7; color: #22c55e; }
.act-btn.restore:hover { background: #bbf7d0; }
.act-btn.view          { background: #eff6ff; color: #2563eb; }
.act-btn.view:hover    { background: #dbeafe; }

.empty-cell { padding: 40px !important; }
.empty-state { display: flex; flex-direction: column; align-items: center; gap: 10px; color: #cbd5e1; font-size: 13px; }

/* TOAST */
.toast { position: fixed; top: 20px; right: 24px; z-index: 9999; display: flex; align-items: center; gap: 10px; padding: 12px 18px; border-radius: 12px; font-size: 13px; font-weight: 600; box-shadow: 0 8px 30px rgba(0,0,0,0.12); min-width: 240px; max-width: 380px; }
.toast.success { background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; }
.toast.error   { background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; }
.toast-icon { display: flex; align-items: center; flex-shrink: 0; }
.toast-msg { word-break: break-word; line-height: 1.4; }
.toast-enter-active, .toast-leave-active { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
.toast-enter-from, .toast-leave-to { opacity: 0; transform: translateY(-15px) scale(0.95); }

/* MODALS */
.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.45); z-index: 1000; display: flex; align-items: center; justify-content: center; backdrop-filter: blur(3px); }
.modal-box { background: #fff; border-radius: 18px; padding: 28px 28px 24px; width: 420px; max-width: 95vw; box-shadow: 0 20px 60px rgba(0,0,0,0.15); display: flex; flex-direction: column; align-items: center; text-align: center; gap: 10px; }
.modal-icon { width: 56px; height: 56px; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-bottom: 4px; }
.restore-icon { background: #dcfce7; }
.modal-title { font-size: 17px; font-weight: 800; color: #1e293b; margin: 0; }
.modal-desc { font-size: 13.5px; color: #64748b; line-height: 1.6; margin: 0; }
.modal-actions { display: flex; gap: 10px; width: 100%; margin-top: 8px; }
.modal-btn { flex: 1; padding: 10px 18px; border-radius: 10px; border: none; font-size: 13.5px; font-weight: 700; cursor: pointer; font-family: inherit; transition: all 0.15s; display: flex; align-items: center; justify-content: center; gap: 6px; }
.modal-btn.ghost { background: #f1f5f9; color: #64748b; }
.modal-btn.ghost:hover:not(:disabled) { background: #e2e8f0; }
.modal-btn.confirm-restore { background: #22c55e; color: #fff; }
.modal-btn.confirm-restore:hover:not(:disabled) { background: #16a34a; }
.modal-btn:disabled { opacity: 0.6; cursor: not-allowed; }
.modal-spinner { width: 16px; height: 16px; border: 2px solid rgba(255,255,255,0.4); border-top-color: #fff; border-radius: 50%; animation: spin 0.65s linear infinite; }
.modal-close-btn { margin-left: auto; background: none; border: none; font-size: 18px; color: #94a3b8; cursor: pointer; padding: 4px 6px; border-radius: 6px; line-height: 1; }
.modal-close-btn:hover { background: #f1f5f9; color: #1e293b; }

.view-modal { align-items: stretch; text-align: left; gap: 14px; max-width: 460px; }
.view-modal-header { display: flex; align-items: center; gap: 12px; }
.view-modal-icon { width: 40px; height: 40px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.view-fields { display: flex; flex-direction: column; gap: 0; border: 1px solid #f1f5f9; border-radius: 10px; overflow: hidden; }
.view-field { display: flex; align-items: flex-start; gap: 10px; padding: 10px 14px; border-bottom: 1px solid #f8fafc; }
.view-field:last-child { border-bottom: none; }
.view-label { font-size: 11px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.04em; min-width: 90px; padding-top: 1px; }
.view-val { font-size: 13px; color: #1e293b; font-weight: 500; flex: 1; }

.modal-enter-active, .modal-leave-active { transition: all 0.22s cubic-bezier(0.4,0,0.2,1); }
.modal-enter-from, .modal-leave-to { opacity: 0; transform: scale(0.95) translateY(10px); }
</style>