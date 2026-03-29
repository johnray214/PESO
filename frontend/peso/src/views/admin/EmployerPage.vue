<template>
  <div class="page">
    <!-- SKELETON — initial load only -->
    <template v-if="loading && !employers.length">
      <div class="filters-bar" style="margin-bottom: 20px;">
        <div class="skel" style="width: 300px; height: 38px; border-radius: 10px;"></div>
        <div style="display:flex; gap:8px;">
          <div class="skel" style="width: 120px; height: 36px; border-radius: 8px;"></div>
          <div class="skel" style="width: 120px; height: 36px; border-radius: 8px;"></div>
        </div>
      </div>
      <div class="status-tabs" style="margin-bottom: 16px;">
        <div v-for="i in 5" :key="i" class="skel" style="width: 100px; height: 34px; border-radius: 8px;"></div>
      </div>
      <div class="table-card" style="padding: 20px;">
        <div v-for="i in 6" :key="i" class="skel" style="width: 100%; height: 50px; border-radius: 8px; margin-bottom: 10px;"></div>
      </div>
    </template>

    <!-- ACTUAL CONTENT -->
    <template v-else>
      <!-- Filters -->
      <div class="filters-bar">
        <div class="search-box">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <input v-model="search" type="text" placeholder="Search company, industry, contact…" class="search-input"/>
        </div>
        <div class="filter-group">
          <select v-model="filterStatus" class="filter-select">
            <option value="">All Status</option>
            <option value="Verified">Verified</option>
            <option value="Pending">Pending</option>
            <option value="Suspended">Suspended</option>
            <option value="Rejected">Rejected</option>
          </select>
          <select v-model="filterIndustry" class="filter-select">
            <option value="">All Industries</option>
            <option v-for="ind in industryOptions" :key="ind" :value="ind">{{ ind }}</option>
          </select>
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

        <!-- PAGE CHANGE SKELETON — rows only -->
        <template v-if="pageLoading">
          <div style="padding: 16px 20px;">
            <div v-for="i in 15" :key="i" class="skel" style="width: 100%; height: 48px; border-radius: 8px; margin-bottom: 8px;"></div>
          </div>
        </template>

        <template v-else>
          <table class="data-table">
            <thead>
              <tr>
                <th>No.</th>
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
              <tr v-for="(emp, index) in filteredEmployers" :key="emp.id" class="table-row" @click="openDrawer(emp)">
                <td @click.stop style="font-weight: 600; color: #64748b; font-size: 12px; padding-left: 18px;">{{ (currentPage - 1) * 15 + index + 1 }}</td>
                <td>
                  <div class="company-cell">
                    <div class="company-logo" :style="{ background: emp.logoBg }">
                      <img v-if="emp.photo" :src="emp.photo" alt="Logo" style="width:100%;height:100%;object-fit:cover;border-radius:inherit;" />
                      <span v-else>{{ emp.name[0] }}</span>
                    </div>
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
                  <button class="act-btn edit" @click="openDrawer(emp)" title="View">
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </template>

        <!-- Pagination — always visible -->
        <div class="pagination">
          <span class="page-info">Showing {{ (currentPage - 1) * 15 + 1 }}–{{ Math.min(currentPage * 15, totalEmployers) }} of {{ totalEmployers }} employers</span>
          <div class="page-btns">
            <button class="page-btn" :disabled="currentPage === 1 || pageLoading" @click="changePage(currentPage - 1)">‹</button>
            <button
              v-for="p in paginationPages"
              :key="p"
              class="page-btn"
              :class="{ active: currentPage === p }"
              :disabled="pageLoading"
              @click="changePage(p)"
            >
              {{ p }}
            </button>
            <button class="page-btn" :disabled="currentPage === lastPage || pageLoading" @click="changePage(currentPage + 1)">›</button>
          </div>
        </div>

      </div>

      <!-- DRAWER -->
      <transition name="drawer">
        <div v-if="drawerOpen" class="drawer-overlay" @click.self="drawerOpen = false">
          <div class="drawer">
            <div class="drawer-header">
              <div class="company-logo lg" :style="{ background: selected?.logoBg }">
                <img v-if="selected?.photo" :src="selected.photo" alt="Logo" style="width:100%;height:100%;object-fit:cover;border-radius:inherit;" />
                <span v-else>{{ selected?.name[0] }}</span>
              </div>
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
    </template>
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
      loading: true,
      pageLoading: false,
      drawerTabList: ['Info', 'Job Listings', 'Hired'],
      industryOptions: ['Information Technology', 'Food & Beverage', 'Retail', 'Real Estate', 'Healthcare', 'Manufacturing', 'Banking & Finance', 'Telecommunications', 'Utilities', 'Aviation'],
      statusTabs: [
        { label: 'All',       value: 'all',       count: 0, cls: '' },
        { label: 'Verified',  value: 'verified',  count: 0, cls: 'active-cls' },
        { label: 'Pending',   value: 'pending',   count: 0, cls: 'pending-cls' },
        { label: 'Suspended', value: 'suspended', count: 0, cls: 'inactive-cls' },
        { label: 'Rejected',  value: 'rejected',  count: 0, cls: 'inactive-cls' },
      ],
      employers: [],
      currentPage: 1,
      lastPage: 1,
      totalEmployers: 0,
    }
  },
  async mounted() {
    await this.fetchEmployers()
  },
  computed: {
    filteredEmployers() {
      return this.employers.filter(e => {
        const matchTab      = this.activeTab === 'all' || e.status.toLowerCase() === this.activeTab.toLowerCase()
        const matchSearch   = !this.search || e.name.toLowerCase().includes(this.search.toLowerCase()) || (e.industry || '').toLowerCase().includes(this.search.toLowerCase()) || (e.contactPerson || '').toLowerCase().includes(this.search.toLowerCase())
        const matchStatus   = !this.filterStatus || e.status.toLowerCase() === this.filterStatus.toLowerCase()
        const matchIndustry = !this.filterIndustry || e.industry === this.filterIndustry
        return matchTab && matchSearch && matchStatus && matchIndustry
      })
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
    async fetchEmployers(isPaginating = false) {
      if (isPaginating) {
        this.pageLoading = true
      } else {
        this.loading = true
      }

      try {
        const params = { page: this.currentPage }
        if (this.search)           params.search = this.search
        if (this.filterStatus)     params.status = this.filterStatus.toLowerCase()
        if (this.activeTab !== 'all') params.status = this.activeTab.toLowerCase()

        const response = await api.get('/admin/employers', { params })
        const payload  = response.data.data || response.data

        let dataList = []
        if (Array.isArray(payload)) {
          // Flat array response: { success, data: [...] }
          dataList = payload
          this.currentPage    = 1
          this.lastPage       = 1
          this.totalEmployers = payload.length
        } else {
          // Paginated response
          const meta = payload.meta || {}
          this.currentPage    = meta.current_page || payload.current_page || 1
          this.lastPage       = meta.last_page    || payload.last_page    || 1
          this.totalEmployers = meta.total        || payload.total        || 0
          dataList = payload.data || []
        }

        this.employers = dataList.map(emp => ({
          id:            emp.id,
          name:          emp.company_name,
          industry:      emp.industry || 'Not specified',
          location:      'Philippines',
          contactPerson: emp.contact_person || 'N/A',
          contactRole:   'Contact Person',
          email:         emp.email,
          phone:         emp.phone || 'N/A',
          photo:         emp.photo ? (emp.photo.startsWith('http') ? emp.photo : '/storage/' + emp.photo) : null,
          dateJoined:    new Date(emp.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
          status:        (emp.status || 'pending').charAt(0).toUpperCase() + (emp.status || 'pending').slice(1),
          logoBg:        this.getRandomColor(),
          totalHired:    emp.total_hired || 0,
          listings: (emp.job_listings || []).map(jl => ({
            title:      jl.title,
            type:       jl.type,
            slots:      jl.slots,
            posted:     new Date(jl.posted_date || jl.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
            status:     jl.status ? jl.status.charAt(0).toUpperCase() + jl.status.slice(1) : 'Open',
            applicants: jl.applications_count || 0,
            hired:      (jl.applications || []).filter(a => a.status === 'hired').length,
            skills:     (jl.skills || []).map(s => s.skill),
          })),
          hiredApplicants: (emp.hired_applicants || []).map((h, i) => {
            const colors = ['#2563eb', '#22c55e', '#f97316', '#8b5cf6', '#ef4444']
            return { ...h, color: colors[i % colors.length] }
          }),
          emailVerified: !!emp.email_verified_at,
        }))

        this.updateStatusTabCounts()
      } catch (error) {
        console.error('Error fetching employers:', error)
      } finally {
        this.loading     = false
        this.pageLoading = false
      }
    },

    updateStatusTabCounts() {
      this.statusTabs[0].count = this.totalEmployers
      this.statusTabs[1].count = this.employers.filter(e => e.status.toLowerCase() === 'verified').length
      this.statusTabs[2].count = this.employers.filter(e => e.status.toLowerCase() === 'pending').length
      this.statusTabs[3].count = this.employers.filter(e => e.status.toLowerCase() === 'suspended').length
      this.statusTabs[4].count = this.employers.filter(e => e.status.toLowerCase() === 'rejected').length
    },

    getRandomColor() {
      const colors = ['#2563eb', '#22c55e', '#f97316', '#ef4444', '#8b5cf6', '#06b6d4', '#14b8a6']
      return colors[Math.floor(Math.random() * colors.length)]
    },

    statusClass(s) {
      const n = s?.toLowerCase()
      return { verified: 'verified', rejected: 'rejected', suspended: 'rejected', pending: 'pending-s' }[n] || ''
    },

    listingStatusClass(s) {
      return { Open: 'placed', Filled: 'hired', Expired: 'rejected' }[s] || ''
    },

    openDrawer(emp) {
      this.selected   = { ...emp, listings: [...emp.listings], hiredApplicants: [...emp.hiredApplicants] }
      this.drawerTab  = 'Info'
      this.drawerOpen = true
    },

    changePage(page) {
      if (page >= 1 && page <= this.lastPage && !this.pageLoading) {
        this.currentPage = page
        this.fetchEmployers(true)
      }
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

@keyframes shimmer { 0% { background-position: -400px 0; } 100% { background-position: 400px 0; } }
.skel {
  background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%);
  background-size: 400px 100%; animation: shimmer 1.4s infinite linear;
  border-radius: 6px; flex-shrink: 0;
}

.page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  padding: 24px; background: #f8fafc;
  min-height: 100vh; display: flex; flex-direction: column; gap: 16px;
}

.filters-bar { display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; flex: 1; max-width: 360px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-group { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }

.status-tabs { display: flex; gap: 4px; }
.tab-btn { display: flex; align-items: center; gap: 6px; background: none; border: none; padding: 8px 14px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; border-radius: 8px; font-family: inherit; transition: all 0.15s; }
.tab-btn:hover  { background: #f1f5f9; }
.tab-btn.active { background: #eff6ff; color: #2563eb; font-weight: 700; }
.tab-count { font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }
.tab-count.active-cls  { background: #dcfce7; color: #22c55e; }
.tab-count.pending-cls { background: #fff7ed; color: #f97316; }
.tab-count.inactive-cls { background: #f1f5f9; color: #94a3b8; }

.table-card { background: #fff; border-radius: 14px; overflow: hidden; border: 1px solid #f1f5f9; }
.data-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.data-table thead tr { background: #f8fafc; }
.data-table th { text-align: left; padding: 11px 14px; font-size: 11px; font-weight: 700; color: #94a3b8; letter-spacing: 0.04em; text-transform: uppercase; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.table-row { cursor: pointer; transition: background 0.12s; }
.table-row:hover { background: #f8fafc; }
.data-table td { padding: 12px 14px; border-bottom: 1px solid #f8fafc; vertical-align: middle; }

.company-cell { display: flex; align-items: center; gap: 10px; }
.company-logo { width: 34px; height: 34px; border-radius: 9px; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 800; color: #fff; flex-shrink: 0; }
.company-logo.lg { width: 44px; height: 44px; border-radius: 12px; font-size: 18px; }
.company-name { font-size: 13px; font-weight: 700; color: #1e293b; }
.company-loc  { font-size: 11px; color: #94a3b8; margin-top: 1px; }

.industry-tag { background: #f1f5f9; color: #475569; font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }

.contact-name { font-size: 12.5px; font-weight: 600; color: #1e293b; }
.contact-role { font-size: 11px; color: #94a3b8; }

.listings-cell  { display: flex; align-items: center; gap: 6px; }
.listings-count { font-size: 15px; font-weight: 800; color: #1e293b; }
.listings-open  { font-size: 11px; color: #22c55e; background: #dcfce7; padding: 2px 7px; border-radius: 99px; font-weight: 600; }
.hired-count    { font-size: 14px; font-weight: 700; color: #2563eb; }
.date-cell      { color: #94a3b8; font-size: 12px; white-space: nowrap; }

.status-badge { padding: 4px 10px; border-radius: 99px; font-size: 11px; font-weight: 600; white-space: nowrap; }
.verified   { background: #dcfce7; color: #22c55e; }
.pending-s  { background: #fff7ed; color: #f97316; }
.hired      { background: #dbeafe; color: #2563eb; }
.placed     { background: #dcfce7; color: #22c55e; }
.rejected   { background: #fef2f2; color: #ef4444; }

.act-btn { width: 28px; height: 28px; border-radius: 7px; border: none; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.15s; }
.act-btn.edit       { background: #eff6ff; color: #2563eb; }
.act-btn.edit:hover { background: #dbeafe; }

/* PAGINATION */
.pagination { display: flex; align-items: center; justify-content: space-between; padding: 14px 18px; border-top: 1px solid #f1f5f9; }
.page-info { font-size: 12px; color: #94a3b8; }
.page-btns { display: flex; gap: 4px; }
.page-btn {
  width: 30px; height: 30px; border-radius: 7px;
  border: 1px solid #e2e8f0; background: #fff;
  font-size: 12px; color: #64748b; cursor: pointer; font-family: inherit;
  display: flex; align-items: center; justify-content: center; transition: all 0.15s;
}
.page-btn:disabled              { opacity: 0.4; cursor: not-allowed; }
.page-btn.active                { background: #2563eb; color: #fff; border-color: #2563eb; }
.page-btn:hover:not(.active):not(:disabled) { background: #f8fafc; }

/* DRAWER */
.drawer-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.3); z-index: 100; display: flex; justify-content: flex-end; backdrop-filter: blur(2px); }
.drawer { width: 440px; height: 100vh; background: #fff; display: flex; flex-direction: column; overflow: hidden; box-shadow: -8px 0 32px rgba(0,0,0,0.12); }
.drawer-header { display: flex; align-items: center; gap: 12px; padding: 20px; border-bottom: 1px solid #f1f5f9; }
.drawer-title-wrap { flex: 1; }
.drawer-name { font-size: 16px; font-weight: 800; color: #1e293b; }
.drawer-loc  { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.drawer-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 16px; padding: 4px; border-radius: 6px; }
.drawer-close:hover { background: #f1f5f9; color: #1e293b; }

.drawer-tabs { display: flex; border-bottom: 1px solid #f1f5f9; padding: 0 20px; }
.dtab { background: none; border: none; padding: 12px 16px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; font-family: inherit; border-bottom: 2px solid transparent; transition: all 0.15s; margin-bottom: -1px; }
.dtab.active { color: #2563eb; border-bottom-color: #2563eb; font-weight: 700; }

.drawer-body { flex: 1; overflow-y: auto; padding: 20px; }

.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
.info-item { display: flex; flex-direction: column; gap: 3px; }
.info-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
.info-val   { font-size: 13px; font-weight: 500; color: #1e293b; }

.listings-list { display: flex; flex-direction: column; gap: 12px; }
.listing-card  { background: #f8fafc; border-radius: 12px; padding: 14px; border: 1px solid #f1f5f9; }
.listing-top   { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 8px; }
.listing-title { font-size: 14px; font-weight: 700; color: #1e293b; }
.listing-meta  { font-size: 11px; color: #94a3b8; margin-top: 3px; }
.listing-skills { display: flex; gap: 4px; flex-wrap: wrap; margin-bottom: 10px; }
.skill-tag { background: #eff6ff; color: #2563eb; font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; }
.listing-applicants { display: flex; align-items: center; gap: 6px; font-size: 12px; color: #64748b; }
.dot-sep    { color: #cbd5e1; }
.hired-badge { color: #2563eb; font-weight: 600; }

.hired-list { display: flex; flex-direction: column; gap: 10px; }
.hired-row  { display: flex; align-items: center; gap: 10px; padding: 12px; background: #f8fafc; border-radius: 10px; border: 1px solid #f1f5f9; }
.avatar     { width: 34px; height: 34px; border-radius: 50%; color: #fff; font-size: 13px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.avatar.sm  { width: 32px; height: 32px; font-size: 12px; }
.hired-info { flex: 1; }
.hired-name { font-size: 13px; font-weight: 600; color: #1e293b; }
.hired-job  { font-size: 11px; color: #94a3b8; margin-top: 2px; }
.hired-right { display: flex; flex-direction: column; align-items: flex-end; gap: 4px; }
.hired-date  { font-size: 11px; color: #94a3b8; }

.drawer-enter-active, .drawer-leave-active { transition: opacity 0.2s; }
.drawer-enter-active .drawer, .drawer-leave-active .drawer { transition: transform 0.25s cubic-bezier(0.4,0,0.2,1); }
.drawer-enter-from, .drawer-leave-to { opacity: 0; }
.drawer-enter-from .drawer, .drawer-leave-to .drawer { transform: translateX(100%); }
</style>