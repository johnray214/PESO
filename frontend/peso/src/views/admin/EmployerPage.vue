<template>
  <div class="page">
    <!-- Filters -->
    <div class="filters-bar">
      <div class="search-box">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        <input v-model="search" type="text" placeholder="Search company, industry, contact…" class="search-input"/>
      </div>
      <div class="filter-group">
        <select v-model="filterStatus" class="filter-select">
          <option value="">All Status</option>
          <option value="Active">Active</option>
          <option value="Inactive">Inactive</option>
          <option value="Pending">Pending Verification</option>
        </select>
        <select v-model="filterIndustry" class="filter-select">
          <option value="">All Industries</option>
          <option v-for="ind in industryOptions" :key="ind" :value="ind">{{ ind }}</option>
        </select>
        <button class="btn-icon">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
          Export
        </button>
      </div>
    </div>

    <!-- Status Tabs -->
    <div class="status-tabs">
      <button v-for="tab in statusTabs" :key="tab.value"
        :class="['tab-btn', { active: activeTab === tab.value }]"
        @click="activeTab = tab.value">
        {{ tab.label }}
        <span class="tab-count" :class="tab.cls">{{ tab.count }}</span>
      </button>
    </div>

    <!-- Table -->
    <div class="table-card">
      <table class="data-table">
        <thead>
          <tr>
            <th><input type="checkbox" class="check"/></th>
            <th>Company</th>
            <th>Industry</th>
            <th>Contact Person</th>
            <th>Job Listings</th>
            <th>Hired</th>
            <th>Date Joined</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="emp in filteredEmployers" :key="emp.id" class="table-row" @click="openDrawer(emp)">
            <td @click.stop><input type="checkbox" class="check"/></td>
            <td>
              <div class="company-cell">
                <div class="company-logo" :style="{ background: emp.logoBg }">{{ emp.name[0] }}</div>
                <div>
                  <p class="company-name">{{ emp.name }}</p>
                  <p class="company-loc">{{ emp.location }}</p>
                </div>
              </div>
            </td>
            <td><span class="industry-tag">{{ emp.industry }}</span></td>
            <td>
              <div class="contact-cell">
                <p class="contact-name">{{ emp.contactPerson }}</p>
                <p class="contact-role">{{ emp.contactRole }}</p>
              </div>
            </td>
            <td>
              <div class="listings-cell">
                <span class="listings-count">{{ emp.listings.length }}</span>
                <span class="listings-open">{{ emp.listings.filter(l => l.status === 'Open').length }} open</span>
              </div>
            </td>
            <td>
              <span class="hired-count">{{ emp.totalHired }}</span>
            </td>
            <td class="date-cell">{{ emp.dateJoined }}</td>
            <td @click.stop>
              <span class="status-badge" :class="statusClass(emp.status)">{{ emp.status }}</span>
            </td>
            <td @click.stop>
              <div class="action-btns">
                <button class="act-btn edit" @click="openDrawer(emp)">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                </button>
                <button class="act-btn delete" @click.stop>
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="21 8 21 21 3 21 3 8"/><rect x="1" y="3" width="22" height="5"/><line x1="10" y1="12" x2="14" y2="12"/></svg>
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
      <div class="pagination">
        <span class="page-info">Showing {{ filteredEmployers.length }} of {{ employers.length }} employers</span>
        <div class="page-btns">
          <button class="page-btn">‹</button>
          <button class="page-btn active">1</button>
          <button class="page-btn">2</button>
          <button class="page-btn">›</button>
        </div>
      </div>
    </div>

    <!-- DRAWER -->
    <transition name="drawer">
      <div v-if="drawerOpen" class="drawer-overlay" @click.self="drawerOpen = false">
        <div class="drawer">
          <div class="drawer-header">
            <div class="company-logo lg" :style="{ background: selected?.logoBg }">{{ selected?.name[0] }}</div>
            <div class="drawer-title-wrap">
              <h2 class="drawer-name">{{ selected?.name }}</h2>
              <p class="drawer-loc">{{ selected?.industry }} · {{ selected?.location }}</p>
            </div>
            <span class="status-badge" :class="statusClass(selected?.status)">{{ selected?.status }}</span>
            <button class="drawer-close" @click="drawerOpen = false">✕</button>
          </div>

          <div class="drawer-tabs">
            <button v-for="dt in drawerTabList" :key="dt" :class="['dtab', { active: drawerTab === dt }]" @click="drawerTab = dt">{{ dt }}</button>
          </div>

          <div class="drawer-body">
            <!-- Info Tab -->
            <div v-if="drawerTab === 'Info'">
              <div class="info-grid">
                <div class="info-item"><span class="info-label">Company</span><span class="info-val">{{ selected?.name }}</span></div>
                <div class="info-item"><span class="info-label">Industry</span><span class="info-val">{{ selected?.industry }}</span></div>
                <div class="info-item"><span class="info-label">Contact</span><span class="info-val">{{ selected?.contactPerson }}</span></div>
                <div class="info-item"><span class="info-label">Role</span><span class="info-val">{{ selected?.contactRole }}</span></div>
                <div class="info-item"><span class="info-label">Email</span><span class="info-val">{{ selected?.email }}</span></div>
                <div class="info-item"><span class="info-label">Phone</span><span class="info-val">{{ selected?.phone }}</span></div>
                <div class="info-item"><span class="info-label">Total Hired</span><span class="info-val">{{ selected?.totalHired }}</span></div>
                <div class="info-item"><span class="info-label">Date Joined</span><span class="info-val">{{ selected?.dateJoined }}</span></div>
              </div>
            </div>

            <!-- Job Listings Tab -->
            <div v-if="drawerTab === 'Job Listings'">
              <div class="listings-list">
                <div v-for="listing in selected?.listings" :key="listing.title" class="listing-card">
                  <div class="listing-top">
                    <div>
                      <p class="listing-title">{{ listing.title }}</p>
                      <p class="listing-meta">{{ listing.type }} · {{ listing.slots }} slots · Posted {{ listing.posted }}</p>
                    </div>
                    <span class="status-badge" :class="listingStatusClass(listing.status)">{{ listing.status }}</span>
                  </div>
                  <div class="listing-skills">
                    <span v-for="sk in listing.skills" :key="sk" class="skill-tag">{{ sk }}</span>
                  </div>
                  <div class="listing-applicants">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                    <span>{{ listing.applicants }} applicants</span>
                    <span class="dot-sep">·</span>
                    <span class="hired-badge">{{ listing.hired }} hired</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Hired Applicants Tab -->
            <div v-if="drawerTab === 'Hired'">
              <div class="hired-list">
                <div v-for="h in selected?.hiredApplicants" :key="h.name" class="hired-row">
                  <div class="avatar sm" :style="{ background: h.color }">{{ h.name[0] }}</div>
                  <div class="hired-info">
                    <p class="hired-name">{{ h.name }}</p>
                    <p class="hired-job">{{ h.job }}</p>
                  </div>
                  <div class="hired-right">
                    <span class="status-badge hired">Hired</span>
                    <p class="hired-date">{{ h.date }}</p>
                  </div>
                </div>
              </div>
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
  name: 'EmployerPage',
  data() {
    return {
      search: '',
      filterStatus: '',
      filterIndustry: '',
      activeTab: 'all',
      drawerOpen: false,
      drawerTab: 'Info',
      selected: null,
      showAddModal: false,
      drawerTabList: ['Info', 'Job Listings', 'Hired'],
      industryOptions: ['Information Technology', 'Food & Beverage', 'Retail', 'Real Estate', 'Healthcare', 'Manufacturing', 'Banking & Finance', 'Telecommunications', 'Utilities', 'Aviation'],
      statusTabs: [
        { label: 'All', value: 'all', count: 0, cls: '' },
        { label: 'Active', value: 'active', count: 0, cls: 'active-cls' },
        { label: 'Pending', value: 'pending', count: 0, cls: 'pending-cls' },
        { label: 'Inactive', value: 'inactive', count: 0, cls: 'inactive-cls' },
      ],
      employers: [],
      loading: true,
    }
  },
  async mounted() {
    await this.fetchEmployers()
  },
  computed: {
    filteredEmployers() {
      return this.employers.filter(e => {
        const matchTab = this.activeTab === 'all' || e.status === this.activeTab
        const matchSearch = !this.search || e.name.toLowerCase().includes(this.search.toLowerCase()) || (e.industry || '').toLowerCase().includes(this.search.toLowerCase()) || (e.contactPerson || '').toLowerCase().includes(this.search.toLowerCase())
        const matchStatus = !this.filterStatus || e.status === this.filterStatus
        const matchIndustry = !this.filterIndustry || e.industry === this.filterIndustry
        return matchTab && matchSearch && matchStatus && matchIndustry
      })
    },
  },
  methods: {
    async fetchEmployers() {
      try {
        this.loading = true
        const response = await api.get('/employers')
        const data = response.data.data || response.data
        
        this.employers = data.map(emp => ({
          id: emp.id,
          name: emp.company_name,
          industry: emp.industry || 'Not specified',
          location: 'Philippines',
          contactPerson: emp.contact_person || 'N/A',
          contactRole: 'Contact Person',
          email: emp.email,
          phone: emp.contact || 'N/A',
          dateJoined: new Date(emp.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
          status: emp.status.charAt(0).toUpperCase() + emp.status.slice(1),
          logoBg: this.getRandomColor(),
          totalHired: emp.total_hired || 0,
          listings: [],
          hiredApplicants: [],
          emailVerified: emp.email_verified_at ? true : false,
        }))

        this.updateStatusTabCounts()
        this.loading = false
      } catch (error) {
        console.error('Error fetching employers:', error)
        this.loading = false
      }
    },
    updateStatusTabCounts() {
      this.statusTabs[0].count = this.employers.length
      this.statusTabs[1].count = this.employers.filter(e => e.status === 'Active').length
      this.statusTabs[2].count = this.employers.filter(e => e.status === 'Pending').length
      this.statusTabs[3].count = this.employers.filter(e => e.status === 'Inactive').length
    },
    getRandomColor() {
      const colors = ['#dbeafe', '#fff7ed', '#eff6ff', '#f0fdf4', '#fdf4ff', '#fef3c7']
      return colors[Math.floor(Math.random() * colors.length)]
    },
    statusClass(s) {
      const normalized = s?.toLowerCase()
      return { 'active': 'active-s', 'inactive': 'inactive-s', 'pending': 'pending-s' }[normalized] || ''
    },
    listingStatusClass(s) {
      return { 'Open': 'placed', 'Filled': 'hired', 'Expired': 'rejected' }[s] || ''
    },
    openDrawer(emp) {
      this.selected = { ...emp, listings: [...emp.listings], hiredApplicants: [...emp.hiredApplicants] }
      this.drawerTab = 'Info'
      this.drawerOpen = true
    }
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

.page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  padding: 24px; background: #f8fafc;
  min-height: 0; display: flex; flex-direction: column; gap: 16px;
}

.btn-primary {
  display: flex; align-items: center; gap: 6px;
  background: #2563eb; color: #fff; border: none; border-radius: 10px;
  padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit;
}
.btn-primary:hover { background: #1d4ed8; }

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
.filter-group { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }
.btn-icon { display: flex; align-items: center; gap: 6px; background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; font-family: inherit; }

.status-tabs { display: flex; gap: 4px; }
.tab-btn { display: flex; align-items: center; gap: 6px; background: none; border: none; padding: 8px 14px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; border-radius: 8px; font-family: inherit; transition: all 0.15s; }
.tab-btn.active { background: #eff6ff; color: #2563eb; font-weight: 700; }
.tab-count { font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }
.tab-count.active-cls { background: #dcfce7; color: #22c55e; }
.tab-count.pending-cls { background: #fff7ed; color: #f97316; }
.tab-count.inactive-cls { background: #f1f5f9; color: #94a3b8; }

.table-card { background: #fff; border-radius: 14px; overflow: hidden; border: 1px solid #f1f5f9; }
.data-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.data-table thead tr { background: #f8fafc; }
.data-table th { text-align: left; padding: 11px 14px; font-size: 11px; font-weight: 700; color: #94a3b8; letter-spacing: 0.04em; text-transform: uppercase; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.table-row { cursor: pointer; transition: background 0.12s; }
.table-row:hover { background: #f8fafc; }
.data-table td { padding: 12px 14px; border-bottom: 1px solid #f8fafc; vertical-align: middle; }
.check { accent-color: #2563eb; cursor: pointer; }

.company-cell { display: flex; align-items: center; gap: 10px; }
.company-logo { width: 36px; height: 36px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 15px; font-weight: 800; color: #2563eb; flex-shrink: 0; }
.company-logo.lg { width: 46px; height: 46px; border-radius: 12px; font-size: 20px; }
.company-name { font-size: 13px; font-weight: 700; color: #1e293b; }
.company-loc { font-size: 11px; color: #94a3b8; margin-top: 1px; }

.industry-tag { background: #f1f5f9; color: #475569; font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }

.contact-name { font-size: 12.5px; font-weight: 600; color: #1e293b; }
.contact-role { font-size: 11px; color: #94a3b8; }

.listings-cell { display: flex; align-items: center; gap: 6px; }
.listings-count { font-size: 15px; font-weight: 800; color: #1e293b; }
.listings-open { font-size: 11px; color: #22c55e; background: #dcfce7; padding: 2px 7px; border-radius: 99px; font-weight: 600; }
.hired-count { font-size: 14px; font-weight: 700; color: #2563eb; }
.date-cell { color: #94a3b8; font-size: 12px; white-space: nowrap; }

.status-badge { padding: 4px 10px; border-radius: 99px; font-size: 11px; font-weight: 600; white-space: nowrap; }
.active-s { background: #dcfce7; color: #22c55e; }
.inactive-s { background: #f1f5f9; color: #94a3b8; }
.pending-s { background: #fff7ed; color: #f97316; }
.hired { background: #dbeafe; color: #2563eb; }
.placed { background: #dcfce7; color: #22c55e; }
.processing { background: #fff7ed; color: #f97316; }
.rejected { background: #fef2f2; color: #ef4444; }

.action-btns { display: flex; gap: 4px; }
.act-btn { width: 28px; height: 28px; border-radius: 7px; border: none; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.15s; }
.act-btn.edit { background: #eff6ff; color: #2563eb; }
.act-btn.delete { background: #fef2f2; color: #ef4444; }

.pagination { display: flex; align-items: center; justify-content: space-between; padding: 14px 18px; border-top: 1px solid #f1f5f9; }
.page-info { font-size: 12px; color: #94a3b8; }
.page-btns { display: flex; gap: 4px; }
.page-btn { width: 30px; height: 30px; border-radius: 7px; border: 1px solid #e2e8f0; background: #fff; font-size: 12px; color: #64748b; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; }
.page-btn.active { background: #2563eb; color: #fff; border-color: #2563eb; }

/* DRAWER */
.drawer-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.3); z-index: 100; display: flex; justify-content: flex-end; backdrop-filter: blur(2px); }
.drawer { width: 440px; height: 100vh; background: #fff; display: flex; flex-direction: column; overflow: hidden; box-shadow: -8px 0 32px rgba(0,0,0,0.12); }
.drawer-header { display: flex; align-items: center; gap: 12px; padding: 20px; border-bottom: 1px solid #f1f5f9; }
.drawer-title-wrap { flex: 1; }
.drawer-name { font-size: 16px; font-weight: 800; color: #1e293b; }
.drawer-loc { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.drawer-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 16px; padding: 4px; border-radius: 6px; }

.drawer-tabs { display: flex; border-bottom: 1px solid #f1f5f9; padding: 0 20px; }
.dtab { background: none; border: none; padding: 12px 16px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; font-family: inherit; border-bottom: 2px solid transparent; transition: all 0.15s; margin-bottom: -1px; }
.dtab.active { color: #2563eb; border-bottom-color: #2563eb; font-weight: 700; }

.drawer-body { flex: 1; overflow-y: auto; padding: 20px; }

.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
.info-item { display: flex; flex-direction: column; gap: 3px; }
.info-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
.info-val { font-size: 13px; font-weight: 500; color: #1e293b; }

.listings-list { display: flex; flex-direction: column; gap: 12px; }
.listing-card { background: #f8fafc; border-radius: 12px; padding: 14px; border: 1px solid #f1f5f9; }
.listing-top { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 8px; }
.listing-title { font-size: 14px; font-weight: 700; color: #1e293b; }
.listing-meta { font-size: 11px; color: #94a3b8; margin-top: 3px; }
.listing-skills { display: flex; gap: 4px; flex-wrap: wrap; margin-bottom: 10px; }
.skill-tag { background: #eff6ff; color: #2563eb; font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; }
.listing-applicants { display: flex; align-items: center; gap: 6px; font-size: 12px; color: #64748b; }
.dot-sep { color: #cbd5e1; }
.hired-badge { color: #2563eb; font-weight: 600; }

.hired-list { display: flex; flex-direction: column; gap: 10px; }
.hired-row { display: flex; align-items: center; gap: 10px; padding: 12px; background: #f8fafc; border-radius: 10px; border: 1px solid #f1f5f9; }
.avatar { width: 34px; height: 34px; border-radius: 50%; color: #fff; font-size: 13px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.avatar.sm { width: 32px; height: 32px; font-size: 12px; }
.hired-info { flex: 1; }
.hired-name { font-size: 13px; font-weight: 600; color: #1e293b; }
.hired-job { font-size: 11px; color: #94a3b8; margin-top: 2px; }
.hired-right { display: flex; flex-direction: column; align-items: flex-end; gap: 4px; }
.hired-date { font-size: 11px; color: #94a3b8; }

.drawer-enter-active, .drawer-leave-active { transition: opacity 0.2s; }
.drawer-enter-active .drawer, .drawer-leave-active .drawer { transition: transform 0.25s cubic-bezier(0.4,0,0.2,1); }
.drawer-enter-from, .drawer-leave-to { opacity: 0; }
.drawer-enter-from .drawer, .drawer-leave-to .drawer { transform: translateX(100%); }
</style>
