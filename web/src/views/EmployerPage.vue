<template>
  <div class="layout-wrapper">
    <AppSidebar active-page="Employers" />
    <div class="main-area">
      <AppTopbar title="Employers" subtitle="Manage companies and their job listings" />
      <div class="page">
<div class="page-header">
      <div>
        <h1 class="page-title">Employers</h1>
        <p class="page-sub">Manage companies and their job listings</p>
      </div>
      <button class="btn-primary" @click="showAddModal = true">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        Add Employer
      </button>
    </div>

    <!-- Stats Strip -->
    <div class="stats-strip">
      <div v-for="s in stripStats" :key="s.label" class="strip-stat">
        <span class="strip-val" :style="{ color: s.color }">{{ s.value }}</span>
        <span class="strip-label">{{ s.label }}</span>
      </div>
    </div>

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
    </div>
  </div>
</template>

<script>
import AppSidebar from './AppSidebar.vue'
import AppTopbar from './AppTopbar.vue'

export default {
  components: { AppSidebar, AppTopbar },
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
      industryOptions: ['BPO / IT Services', 'Food & Beverage', 'Retail', 'Real Estate', 'Healthcare', 'Manufacturing'],
      statusTabs: [
        { label: 'All', value: 'all', count: 5, cls: '' },
        { label: 'Active', value: 'Active', count: 3, cls: 'active-cls' },
        { label: 'Pending', value: 'Pending', count: 1, cls: 'pending-cls' },
        { label: 'Inactive', value: 'Inactive', count: 1, cls: 'inactive-cls' },
      ],
      employers: [
        {
          id: 1, name: 'Accenture PH', industry: 'BPO / IT Services', location: 'BGC, Taguig',
          contactPerson: 'Mark Reyes', contactRole: 'HR Manager', email: 'hr@accenture.ph',
          phone: '02-8888-1234', dateJoined: 'Jan 10, 2023', status: 'Active',
          logoBg: '#dbeafe', totalHired: 42,
          listings: [
            { title: 'Web Developer', type: 'Full-time', slots: 5, posted: 'Dec 01', status: 'Open', skills: ['Vue.js', 'Laravel'], applicants: 18, hired: 3 },
            { title: 'Data Analyst', type: 'Full-time', slots: 3, posted: 'Nov 20', status: 'Filled', skills: ['Excel', 'SQL', 'Power BI'], applicants: 12, hired: 3 },
            { title: 'Customer Support', type: 'Part-time', slots: 10, posted: 'Dec 03', status: 'Open', skills: ['Communication', 'CRM'], applicants: 25, hired: 0 },
          ],
          hiredApplicants: [
            { name: 'Maria Santos', job: 'Bookkeeper', date: 'Dec 06', color: '#2563eb' },
            { name: 'Rosa Garcia', job: 'Instructor', date: 'Dec 04', color: '#06b6d4' },
          ]
        },
        {
          id: 2, name: 'Jollibee Foods', industry: 'Food & Beverage', location: 'Ortigas, Pasig',
          contactPerson: 'Ana Villanueva', contactRole: 'Recruitment Head', email: 'recruit@jollibee.com.ph',
          phone: '02-7700-8888', dateJoined: 'Mar 05, 2023', status: 'Active',
          logoBg: '#fff7ed', totalHired: 28,
          listings: [
            { title: 'Store Crew', type: 'Part-time', slots: 20, posted: 'Dec 02', status: 'Open', skills: ['Customer Service', 'Cashiering'], applicants: 40, hired: 10 },
            { title: 'Delivery Driver', type: 'Full-time', slots: 8, posted: 'Nov 28', status: 'Open', skills: ['Driving', 'Navigation'], applicants: 15, hired: 2 },
          ],
          hiredApplicants: [
            { name: 'Carlo Bautista', job: 'Delivery Driver', date: 'Dec 03', color: '#ef4444' },
          ]
        },
        {
          id: 3, name: 'SM Supermalls', industry: 'Retail', location: 'Mandaluyong',
          contactPerson: 'Jose Castillo', contactRole: 'HR Officer', email: 'hr@smsupermalls.com',
          phone: '02-8700-0700', dateJoined: 'Feb 14, 2023', status: 'Active',
          logoBg: '#eff6ff', totalHired: 35,
          listings: [
            { title: 'Electrician', type: 'Full-time', slots: 4, posted: 'Dec 05', status: 'Open', skills: ['Electrical', 'PEC Standards'], applicants: 8, hired: 0 },
            { title: 'Sales Associate', type: 'Full-time', slots: 15, posted: 'Nov 15', status: 'Filled', skills: ['Sales', 'Customer Service'], applicants: 30, hired: 15 },
          ],
          hiredApplicants: [
            { name: 'Pedro Lim', job: 'Electrician', date: 'Dec 05', color: '#3b82f6' },
          ]
        },
        {
          id: 4, name: 'Nexus Tech', industry: 'BPO / IT Services', location: 'Cebu City',
          contactPerson: 'Carla Mendoza', contactRole: 'CEO', email: 'carla@nexustech.ph',
          phone: '032-888-5678', dateJoined: 'Jun 22, 2023', status: 'Pending',
          logoBg: '#f0fdf4', totalHired: 5,
          listings: [
            { title: 'Web Developer', type: 'Full-time', slots: 2, posted: 'Dec 06', status: 'Open', skills: ['Vue.js', 'Node.js'], applicants: 4, hired: 0 },
          ],
          hiredApplicants: []
        },
        {
          id: 5, name: 'Makati Medical', industry: 'Healthcare', location: 'Makati City',
          contactPerson: 'Dr. Santos', contactRole: 'Admin Director', email: 'admin@makatimed.net.ph',
          phone: '02-8888-8999', dateJoined: 'Apr 01, 2022', status: 'Inactive',
          logoBg: '#fdf4ff', totalHired: 19,
          listings: [],
          hiredApplicants: [
            { name: 'Ana Reyes', job: 'Staff Nurse', date: 'Dec 05', color: '#22c55e' },
          ]
        },
      ]
    }
  },
  computed: {
    filteredEmployers() {
      return this.employers.filter(e => {
        const matchTab = this.activeTab === 'all' || e.status === this.activeTab
        const matchSearch = !this.search || e.name.toLowerCase().includes(this.search.toLowerCase()) || e.industry.toLowerCase().includes(this.search.toLowerCase()) || e.contactPerson.toLowerCase().includes(this.search.toLowerCase())
        const matchStatus = !this.filterStatus || e.status === this.filterStatus
        const matchIndustry = !this.filterIndustry || e.industry === this.filterIndustry
        return matchTab && matchSearch && matchStatus && matchIndustry
      })
    },
    stripStats() {
      const all = this.employers
      return [
        { label: 'Total Employers', value: all.length, color: '#1e293b' },
        { label: 'Active', value: all.filter(e => e.status === 'Active').length, color: '#22c55e' },
        { label: 'Pending', value: all.filter(e => e.status === 'Pending').length, color: '#f97316' },
        { label: 'Inactive', value: all.filter(e => e.status === 'Inactive').length, color: '#94a3b8' },
        { label: 'Total Job Listings', value: all.reduce((s, e) => s + e.listings.length, 0), color: '#2563eb' },
      ]
    }
  },
  methods: {
    statusClass(s) {
      return { 'Active': 'active-s', 'Inactive': 'inactive-s', 'Pending': 'pending-s' }[s] || ''
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

/* ── Shell layout ── */
.layout-wrapper {
  display: flex;
  height: 100vh;
  overflow: hidden;
  background: #f8fafc;
  font-family: 'Plus Jakarta Sans', sans-serif;
}
.main-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.page {
  flex: 1;
  overflow-y: auto;
}

@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

/* ── LAYOUT ── */

















.nav-item.active 








/* ── MAIN AREA ── */




















.page-header { display: flex; align-items: flex-start; justify-content: space-between; }
.page-title { font-size: 20px; font-weight: 800; color: #1e293b; }
.page-sub { font-size: 12px; color: #94a3b8; margin-top: 2px; }

.btn-primary {
  display: flex; align-items: center; gap: 6px;
  background: #2563eb; color: #fff; border: none; border-radius: 10px;
  padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit;
}
.btn-primary:hover { background: #1d4ed8; }

.stats-strip { display: flex; background: #fff; border-radius: 12px; overflow: hidden; border: 1px solid #f1f5f9; }
.strip-stat { flex: 1; display: flex; flex-direction: column; align-items: center; padding: 14px 12px; border-right: 1px solid #f1f5f9; }
.strip-stat:last-child { border-right: none; }
.strip-val { font-size: 22px; font-weight: 800; line-height: 1; }
.strip-label { font-size: 11px; color: #94a3b8; margin-top: 4px; font-weight: 500; }

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

.page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  padding: 24px;
  background: #f8fafc;
  min-height: 100%;
  display: flex;
  flex-direction: column;
  gap: 16px;
}
</style>