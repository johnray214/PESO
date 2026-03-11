<template>
  <div class="page">
    <div class="audit-header">
      <button class="btn-export">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
        Export CSV
      </button>
    </div>

    <!-- Filters -->
    <div class="filters-bar">
      <div class="search-box">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        <input v-model="search" type="text" placeholder="Search by user, action, or detail…" class="search-input"/>
      </div>
      <div class="filter-group">
        <select v-model="filterUser" class="filter-select">
          <option value="">All Users</option>
          <option v-for="u in userOptions" :key="u" :value="u">{{ u }}</option>
        </select>
        <select v-model="filterModule" class="filter-select">
          <option value="">All Modules</option>
          <option v-for="m in moduleOptions" :key="m" :value="m">{{ m }}</option>
        </select>
        <select v-model="filterAction" class="filter-select">
          <option value="">All Actions</option>
          <option value="Created">Created</option>
          <option value="Updated">Updated</option>
          <option value="Deleted">Deleted</option>
          <option value="Logged In">Logged In</option>
          <option value="Status Changed">Status Changed</option>
          <option value="Exported">Exported</option>
        </select>
        <input v-model="filterDateFrom" type="date" class="filter-select date-input" placeholder="From"/>
        <input v-model="filterDateTo" type="date" class="filter-select date-input" placeholder="To"/>
      </div>
    </div>

    <!-- Results Summary -->
    <div class="results-bar">
      <span class="results-count">{{ filteredLogs.length }} log entries</span>
      <button v-if="hasFilters" class="clear-btn" @click="clearFilters">Clear filters</button>
    </div>

    <!-- Log Table -->
    <div class="table-card">
      <table class="data-table">
        <thead>
          <tr>
            <th>Timestamp</th>
            <th>User</th>
            <th>Role</th>
            <th>Action</th>
            <th>Module</th>
            <th>Details</th>
            <th>IP</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="log in paginatedLogs" :key="log.id" class="log-row">
            <td class="timestamp-cell">
              <p class="ts-date">{{ log.date }}</p>
              <p class="ts-time">{{ log.time }}</p>
            </td>
            <td>
              <div class="user-cell">
                <div class="user-avatar" :style="{ background: log.avatarBg }">{{ log.user[0] }}</div>
                <span class="user-name">{{ log.user }}</span>
              </div>
            </td>
            <td><span class="role-badge" :class="roleClass(log.role)">{{ log.role }}</span></td>
            <td><span class="action-badge" :class="actionClass(log.action)">{{ log.action }}</span></td>
            <td><span class="module-badge">{{ log.module }}</span></td>
            <td class="detail-cell">{{ log.detail }}</td>
            <td class="ip-cell">{{ log.ip }}</td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination -->
      <div class="pagination">
        <span class="page-info">Showing {{ (currentPage - 1) * perPage + 1 }}–{{ Math.min(currentPage * perPage, filteredLogs.length) }} of {{ filteredLogs.length }}</span>
        <div class="page-btns">
          <button class="page-btn" :disabled="currentPage === 1" @click="currentPage--">‹</button>
          <button v-for="p in totalPages" :key="p" :class="['page-btn', { active: currentPage === p }]" @click="currentPage = p">{{ p }}</button>
          <button class="page-btn" :disabled="currentPage === totalPages" @click="currentPage++">›</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import api from '@/services/api'

export default {
  name: 'AuditLogsPage',
  async mounted() {
    await this.fetchLogs()
  },
  data() {
    return {
      search: '',
      filterUser: '',
      filterModule: '',
      filterAction: '',
      filterDateFrom: '',
      filterDateTo: '',
      currentPage: 1,
      perPage: 10,
      userOptions: ['Admin', 'Maria Staff', 'Juan Staff', 'Employer: Accenture', 'Employer: Jollibee'],
      moduleOptions: ['Applicants', 'Employers', 'Events', 'Job Listings', 'Notifications', 'Users', 'System'],
      logs: [
        { id: 1, date: 'Dec 06, 2023', time: '10:42 AM', user: 'Admin', role: 'Admin', action: 'Status Changed', module: 'Applicants', detail: 'Changed Maria Santos status from Processing → Hired', ip: '192.168.1.1', avatarBg: '#2563eb' },
        { id: 2, date: 'Dec 06, 2023', time: '10:30 AM', user: 'Admin', role: 'Admin', action: 'Created', module: 'Events', detail: 'Created new event: Job Fair 2024 — Quezon City', ip: '192.168.1.1', avatarBg: '#2563eb' },
        { id: 3, date: 'Dec 06, 2023', time: '09:55 AM', user: 'Employer: Accenture', role: 'Employer', action: 'Created', module: 'Job Listings', detail: 'Posted new listing: Web Developer (5 slots)', ip: '203.177.12.5', avatarBg: '#06b6d4' },
        { id: 4, date: 'Dec 06, 2023', time: '09:20 AM', user: 'Maria Staff', role: 'Staff', action: 'Logged In', module: 'System', detail: 'User logged in successfully', ip: '192.168.1.5', avatarBg: '#f97316' },
        { id: 5, date: 'Dec 05, 2023', time: '04:15 PM', user: 'Admin', role: 'Admin', action: 'Deleted', module: 'Events', detail: 'Archived event: Regional Job Fair Nov 2023', ip: '192.168.1.1', avatarBg: '#2563eb' },
        { id: 6, date: 'Dec 05, 2023', time: '03:44 PM', user: 'Maria Staff', role: 'Staff', action: 'Updated', module: 'Applicants', detail: 'Updated profile of Juan dela Cruz (contact info)', ip: '192.168.1.5', avatarBg: '#f97316' },
        { id: 7, date: 'Dec 05, 2023', time: '02:10 PM', user: 'Employer: Jollibee', role: 'Employer', action: 'Created', module: 'Job Listings', detail: 'Posted new listing: Store Crew (20 slots)', ip: '210.5.100.22', avatarBg: '#22c55e' },
        { id: 8, date: 'Dec 05, 2023', time: '11:30 AM', user: 'Admin', role: 'Admin', action: 'Status Changed', module: 'Employers', detail: 'Changed Nexus Tech status to Pending Verification', ip: '192.168.1.1', avatarBg: '#2563eb' },
        { id: 9, date: 'Dec 05, 2023', time: '10:00 AM', user: 'Admin', role: 'Admin', action: 'Exported', module: 'Applicants', detail: 'Exported applicant list to CSV (4,821 records)', ip: '192.168.1.1', avatarBg: '#2563eb' },
        { id: 10, date: 'Dec 04, 2023', time: '05:00 PM', user: 'Juan Staff', role: 'Staff', action: 'Created', module: 'Applicants', detail: 'Registered new applicant: Rosa Garcia', ip: '192.168.1.8', avatarBg: '#a855f7' },
        { id: 11, date: 'Dec 04, 2023', time: '03:22 PM', user: 'Admin', role: 'Admin', action: 'Deleted', module: 'Job Listings', detail: 'Archived listing: Call Center Agent at Nexus Tech', ip: '192.168.1.1', avatarBg: '#2563eb' },
        { id: 12, date: 'Dec 04, 2023', time: '01:45 PM', user: 'Maria Staff', role: 'Staff', action: 'Updated', module: 'Events', detail: 'Updated slots for BPO Skills Training from 40 → 50', ip: '192.168.1.5', avatarBg: '#f97316' },
      ]
    }
  },
  computed: {
    filteredLogs() {
      return this.logs.filter(l => {
        const matchSearch = !this.search || l.user.toLowerCase().includes(this.search.toLowerCase()) || l.detail.toLowerCase().includes(this.search.toLowerCase()) || l.action.toLowerCase().includes(this.search.toLowerCase())
        const matchUser = !this.filterUser || l.user === this.filterUser
        const matchModule = !this.filterModule || l.module === this.filterModule
        const matchAction = !this.filterAction || l.action === this.filterAction
        return matchSearch && matchUser && matchModule && matchAction
      })
    },
    paginatedLogs() {
      const start = (this.currentPage - 1) * this.perPage
      return this.filteredLogs.slice(start, start + this.perPage)
    },
    totalPages() {
      return Math.max(1, Math.ceil(this.filteredLogs.length / this.perPage))
    },
    hasFilters() {
      return this.search || this.filterUser || this.filterModule || this.filterAction || this.filterDateFrom || this.filterDateTo
    },
    stripStats() {
      const l = this.logs
      return [
        { label: 'Total Logs', value: l.length, color: '#1e293b' },
        { label: 'Created', value: l.filter(x => x.action === 'Created').length, color: '#22c55e' },
        { label: 'Updated', value: l.filter(x => x.action === 'Updated').length, color: '#2563eb' },
        { label: 'Deleted', value: l.filter(x => x.action === 'Deleted').length, color: '#ef4444' },
        { label: 'Status Changed', value: l.filter(x => x.action === 'Status Changed').length, color: '#f97316' },
      ]
    }
  },
  methods: {
    async fetchLogs() {
      try {
        const params = {}
        if (this.search)         params.search     = this.search
        if (this.filterUser)     params.user       = this.filterUser
        if (this.filterModule)   params.module     = this.filterModule
        if (this.filterAction)   params.action     = this.filterAction
        if (this.filterDateFrom) params.date_from  = this.filterDateFrom
        if (this.filterDateTo)   params.date_to    = this.filterDateTo
        params.page     = this.currentPage
        params.per_page = this.perPage
        const { data } = await api.get('/admin/audit-logs', { params })
        this.logs = data.data?.data || data.data || data
      } catch (e) { console.error(e) }
    },
    roleClass(role) { return { Admin: 'role-admin', Staff: 'role-staff', Employer: 'role-employer' }[role] || '' },
    actionClass(action) { return { Created: 'act-created', Updated: 'act-updated', Deleted: 'act-deleted', 'Logged In': 'act-login', 'Status Changed': 'act-status', Exported: 'act-export' }[action] || '' },
    clearFilters() {
      this.search = ''; this.filterUser = ''; this.filterModule = ''; this.filterAction = ''
      this.filterDateFrom = ''; this.filterDateTo = ''; this.currentPage = 1
      this.fetchLogs()
    }
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

.page { font-family: 'Plus Jakarta Sans', sans-serif; padding: 24px; background: #f8fafc; min-height: 0; display: flex; flex-direction: column; gap: 16px; }
.audit-header { display: flex; align-items: flex-start; justify-content: space-between; }
.btn-export { display: flex; align-items: center; gap: 6px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; color: #475569; cursor: pointer; font-family: inherit; }
.btn-export:hover { background: #f8fafc; }

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

.filters-bar { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; flex: 1; min-width: 200px; max-width: 300px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-group { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 10px; font-size: 12px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }
.date-input { font-family: inherit; }

.results-bar { display: flex; align-items: center; gap: 10px; }
.results-count { font-size: 12px; color: #94a3b8; font-weight: 600; }
.clear-btn { background: none; border: none; font-size: 12px; color: #2563eb; cursor: pointer; font-family: inherit; font-weight: 600; }
.clear-btn:hover { text-decoration: underline; }

.table-card { background: #fff; border-radius: 14px; overflow: hidden; border: 1px solid #f1f5f9; }
.data-table { width: 100%; border-collapse: collapse; font-size: 12.5px; }
.data-table thead tr { background: #f8fafc; }
.data-table th { text-align: left; padding: 11px 14px; font-size: 10.5px; font-weight: 700; color: #94a3b8; letter-spacing: 0.04em; text-transform: uppercase; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.log-row { transition: background 0.12s; border-bottom: 1px solid #f8fafc; }
.log-row:hover { background: #f8fafc; }
.data-table td { padding: 11px 14px; vertical-align: middle; }

.timestamp-cell { white-space: nowrap; }
.ts-date { font-size: 12.5px; font-weight: 600; color: #1e293b; }
.ts-time { font-size: 11px; color: #94a3b8; margin-top: 1px; }

.user-cell { display: flex; align-items: center; gap: 8px; }
.user-avatar { width: 26px; height: 26px; border-radius: 50%; color: #fff; font-size: 10px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.user-name { font-size: 12.5px; font-weight: 600; color: #1e293b; white-space: nowrap; }

.role-badge { font-size: 10.5px; font-weight: 700; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
.role-admin { background: #dbeafe; color: #2563eb; }
.role-staff { background: #fff7ed; color: #f97316; }
.role-employer { background: #dcfce7; color: #16a34a; }

.action-badge { font-size: 10.5px; font-weight: 700; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
.act-created { background: #dcfce7; color: #16a34a; }
.act-updated { background: #dbeafe; color: #2563eb; }
.act-deleted { background: #fef2f2; color: #ef4444; }
.act-login { background: #f1f5f9; color: #64748b; }
.act-status { background: #fff7ed; color: #f97316; }
.act-export { background: #fdf4ff; color: #a21caf; }

.module-badge { font-size: 11px; font-weight: 500; color: #475569; background: #f1f5f9; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
.detail-cell { font-size: 12px; color: #64748b; max-width: 280px; line-height: 1.4; }
.ip-cell { font-size: 11px; color: #94a3b8; font-family: monospace; white-space: nowrap; }

.pagination { display: flex; align-items: center; justify-content: space-between; padding: 14px 18px; border-top: 1px solid #f1f5f9; }
.page-info { font-size: 12px; color: #94a3b8; }
.page-btns { display: flex; gap: 4px; }
.page-btn { min-width: 30px; height: 30px; border-radius: 7px; border: 1px solid #e2e8f0; background: #fff; font-size: 12px; color: #64748b; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; padding: 0 6px; }
.page-btn.active { background: #2563eb; color: #fff; border-color: #2563eb; }
.page-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.page-btn:hover:not(.active):not(:disabled) { background: #f8fafc; }
</style>
