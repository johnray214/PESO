<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Archive</h1>
        <p class="page-sub">Soft-deleted records — restore or permanently remove</p>
      </div>
      <button class="btn-danger" @click="confirmClearAll">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a1 1 0 011-1h4a1 1 0 011 1v2"/></svg>
        Clear All
      </button>
    </div>

    <!-- Stats Strip -->
    <div class="stats-strip">
      <div v-for="s in stripStats" :key="s.label" class="strip-stat">
        <span class="strip-val" :style="{ color: s.color }">{{ s.value }}</span>
        <span class="strip-label">{{ s.label }}</span>
      </div>
    </div>

    <!-- Type Tabs -->
    <div class="type-tabs">
      <button v-for="tab in typeTabs" :key="tab.value"
        :class="['tab-btn', { active: activeTab === tab.value }]"
        @click="activeTab = tab.value">
        <span v-html="tab.icon" class="tab-icon"></span>
        {{ tab.label }}
        <span class="tab-count">{{ tab.count }}</span>
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

    <!-- Archive Table -->
    <div class="table-card">
      <table class="data-table">
        <thead>
          <tr>
            <th>Record</th>
            <th>Type</th>
            <th>Deleted By</th>
            <th>Deleted At</th>
            <th>Reason</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="record in filteredRecords" :key="record.id" class="table-row">
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
            <td><span class="type-badge" :style="{ background: typeColor(record.type).bg, color: typeColor(record.type).text }">{{ record.type }}</span></td>
            <td>
              <div class="deleted-by">
                <div class="mini-avatar">{{ record.deletedBy[0] }}</div>
                <span>{{ record.deletedBy }}</span>
              </div>
            </td>
            <td class="date-cell">{{ record.deletedAt }}</td>
            <td class="reason-cell">{{ record.reason }}</td>
            <td>
              <div class="action-btns">
                <button class="act-btn restore" @click="restoreRecord(record)" title="Restore">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 102.13-9.36L1 10"/></svg>
                </button>
                <button class="act-btn delete" @click="permanentDelete(record)" title="Permanently Delete">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/></svg>
                </button>
              </div>
            </td>
          </tr>
          <tr v-if="filteredRecords.length === 0">
            <td colspan="6" class="empty-cell">
              <div class="empty-state">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.5"><polyline points="21 8 21 21 3 21 3 8"/><rect x="1" y="3" width="22" height="5"/><line x1="10" y1="12" x2="14" y2="12"/></svg>
                <p>No archived records found</p>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ArchivePage',
  data() {
    return {
      activeTab: 'all',
      search: '',
      filterDate: '',
      typeTabs: [
        { label: 'All', value: 'all', count: 6, icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>` },
        { label: 'Events', value: 'Event', count: 2, icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>` },
        { label: 'Job Listings', value: 'Job Listing', count: 2, icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>` },
        { label: 'Applicants', value: 'Applicant', count: 1, icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>` },
        { label: 'Employers', value: 'Employer', count: 1, icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>` },
      ],
      records: [
        { id: 1, type: 'Event', name: 'Regional Job Fair Nov 2023', detail: 'Job Fair · 150 slots', deletedBy: 'Admin', deletedAt: 'Dec 01, 2023', reason: 'Event cancelled due to venue issues' },
        { id: 2, type: 'Event', name: 'Cooking & Pastry Workshop', detail: 'Workshop · 40 slots', deletedBy: 'Maria Staff', deletedAt: 'Nov 28, 2023', reason: 'Duplicate entry' },
        { id: 3, type: 'Job Listing', name: 'Data Entry Clerk', detail: 'Accenture PH · Full-time', deletedBy: 'Admin', deletedAt: 'Nov 25, 2023', reason: 'Position filled externally' },
        { id: 4, type: 'Job Listing', name: 'Call Center Agent', detail: 'Nexus Tech · Part-time', deletedBy: 'Admin', deletedAt: 'Nov 20, 2023', reason: 'Company request' },
        { id: 5, type: 'Applicant', name: 'Jose Ramirez', detail: 'Driving · Valenzuela', deletedBy: 'Maria Staff', deletedAt: 'Nov 18, 2023', reason: 'Duplicate registration' },
        { id: 6, type: 'Employer', name: 'FastFood Co.', detail: 'Food & Beverage · Caloocan', deletedBy: 'Admin', deletedAt: 'Nov 15, 2023', reason: 'Invalid business documents' },
      ]
    }
  },
  computed: {
    filteredRecords() {
      return this.records.filter(r => {
        const matchTab = this.activeTab === 'all' || r.type === this.activeTab
        const matchSearch = !this.search || r.name.toLowerCase().includes(this.search.toLowerCase()) || r.deletedBy.toLowerCase().includes(this.search.toLowerCase())
        return matchTab && matchSearch
      })
    },
    stripStats() {
      const r = this.records
      return [
        { label: 'Total Archived', value: r.length, color: '#1e293b' },
        { label: 'Events', value: r.filter(x => x.type === 'Event').length, color: '#f97316' },
        { label: 'Job Listings', value: r.filter(x => x.type === 'Job Listing').length, color: '#2563eb' },
        { label: 'Applicants', value: r.filter(x => x.type === 'Applicant').length, color: '#22c55e' },
        { label: 'Employers', value: r.filter(x => x.type === 'Employer').length, color: '#06b6d4' },
      ]
    }
  },
  methods: {
    typeColor(type) {
      return { Event: { bg: '#fff7ed', text: '#f97316' }, 'Job Listing': { bg: '#dbeafe', text: '#2563eb' }, Applicant: { bg: '#dcfce7', text: '#22c55e' }, Employer: { bg: '#eff6ff', text: '#3b82f6' } }[type] || { bg: '#f1f5f9', text: '#64748b' }
    },
    typeIcon(type) {
      const icons = {
        Event: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>`,
        'Job Listing': `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>`,
        Applicant: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>`,
        Employer: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>`,
      }
      return icons[type] || ''
    },
    restoreRecord(r) { this.records = this.records.filter(rec => rec.id !== r.id) },
    permanentDelete(r) { this.records = this.records.filter(rec => rec.id !== r.id) },
    confirmClearAll() { if (confirm('Permanently delete all archived records?')) this.records = [] }
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

.page { font-family: 'Plus Jakarta Sans', sans-serif; padding: 24px; background: #f8fafc; min-height: 100vh; display: flex; flex-direction: column; gap: 16px; }
.page-header { display: flex; align-items: flex-start; justify-content: space-between; }
.page-title { font-size: 20px; font-weight: 800; color: #1e293b; }
.page-sub { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.btn-danger { display: flex; align-items: center; gap: 6px; background: #fef2f2; color: #ef4444; border: 1px solid #fecaca; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-danger:hover { background: #fee2e2; }

.stats-strip { display: flex; background: #fff; border-radius: 12px; overflow: hidden; border: 1px solid #f1f5f9; }
.strip-stat { flex: 1; display: flex; flex-direction: column; align-items: center; padding: 14px 12px; border-right: 1px solid #f1f5f9; }
.strip-stat:last-child { border-right: none; }
.strip-val { font-size: 22px; font-weight: 800; line-height: 1; }
.strip-label { font-size: 11px; color: #94a3b8; margin-top: 4px; font-weight: 500; }

.type-tabs { display: flex; gap: 4px; flex-wrap: wrap; }
.tab-btn { display: flex; align-items: center; gap: 6px; background: none; border: none; padding: 8px 14px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; border-radius: 8px; font-family: inherit; transition: all 0.15s; }
.tab-btn.active { background: #eff6ff; color: #2563eb; font-weight: 700; }
.tab-icon { display: flex; align-items: center; }
.tab-count { font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }

.filters-bar { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; flex: 1; max-width: 360px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }

.table-card { background: #fff; border-radius: 14px; overflow: hidden; border: 1px solid #f1f5f9; }
.data-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.data-table thead tr { background: #f8fafc; }
.data-table th { text-align: left; padding: 11px 14px; font-size: 11px; font-weight: 700; color: #94a3b8; letter-spacing: 0.04em; text-transform: uppercase; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.table-row { transition: background 0.12s; }
.table-row:hover { background: #f8fafc; }
.data-table td { padding: 12px 14px; border-bottom: 1px solid #f8fafc; vertical-align: middle; }

.record-cell { display: flex; align-items: center; gap: 10px; }
.record-icon { width: 36px; height: 36px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.record-name { font-size: 13px; font-weight: 600; color: #1e293b; }
.record-detail { font-size: 11px; color: #94a3b8; margin-top: 2px; }

.type-badge { font-size: 11px; font-weight: 600; padding: 3px 9px; border-radius: 6px; white-space: nowrap; }

.deleted-by { display: flex; align-items: center; gap: 6px; font-size: 12.5px; color: #475569; }
.mini-avatar { width: 24px; height: 24px; border-radius: 50%; background: #dbeafe; color: #2563eb; font-size: 10px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }

.date-cell { color: #94a3b8; font-size: 12px; white-space: nowrap; }
.reason-cell { font-size: 12px; color: #64748b; max-width: 200px; }

.action-btns { display: flex; gap: 4px; }
.act-btn { width: 28px; height: 28px; border-radius: 7px; border: none; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.15s; }
.act-btn.restore { background: #dcfce7; color: #22c55e; }
.act-btn.restore:hover { background: #bbf7d0; }
.act-btn.delete { background: #fef2f2; color: #ef4444; }
.act-btn.delete:hover { background: #fee2e2; }

.empty-cell { padding: 40px !important; }
.empty-state { display: flex; flex-direction: column; align-items: center; gap: 10px; color: #cbd5e1; font-size: 13px; }
</style>
