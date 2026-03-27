<template>
  <div class="page">
    <!-- SKELETON -->
    <template v-if="loading && !applicants.length">
      <div class="filters-bar" style="margin-bottom: 20px;">
        <div class="skel" style="width: 300px; height: 38px; border-radius: 10px;"></div>
        <div style="display:flex; gap:8px;">
          <div class="skel" style="width: 120px; height: 36px; border-radius: 8px;"></div>
          <div class="skel" style="width: 120px; height: 36px; border-radius: 8px;"></div>
          <div class="skel" style="width: 120px; height: 36px; border-radius: 8px;"></div>
        </div>
      </div>
      <div class="status-tabs" style="margin-bottom: 16px;">
        <div v-for="i in 6" :key="i" class="skel" style="width: 100px; height: 34px; border-radius: 8px;"></div>
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
          <input v-model="search" type="text" placeholder="Search applicant, skill, location…" class="search-input"/>
        </div>
        <div class="filter-group">
          <select v-model="filterStatus" class="filter-select">
            <option value="">All Status</option>
            <option value="reviewing">Reviewing</option>
            <option value="shortlisted">Shortlisted</option>
            <option value="interview">Interview</option>
            <option value="hired">Hired</option>
            <option value="rejected">Rejected</option>
          </select>
          <select v-model="filterSkill" class="filter-select">
            <option value="">All Skills</option>
            <option v-for="sk in skillOptions" :key="sk" :value="sk">{{ sk }}</option>
          </select>
          <select v-model="filterDate" class="filter-select">
            <option value="">All Time</option>
            <option value="today">Today</option>
            <option value="week">This Week</option>
            <option value="month">This Month</option>
          </select>
        </div>
      </div>

      <!-- Status Tabs -->
      <div class="status-tabs">
        <button
          v-for="tab in statusTabs"
          :key="tab.value"
          :class="['tab-btn', { active: activeTab === tab.value }]"
          @click="activeTab = tab.value"
        >
          {{ tab.label }}
          <span class="tab-count" :class="tab.value">{{ tab.count }}</span>
        </button>
      </div>

      <!-- Table -->
      <div class="table-card">

        <!-- PAGE CHANGE SKELETON — replaces tbody rows only -->
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
                <th>Applicant</th>
                <th>Skills</th>
                <th>Job Applied</th>
                <th>Employer</th>
                <th>Date</th>
                <th>Status</th>
                <th>Files</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(a, index) in filteredApplicants"
                :key="a.id"
                class="table-row"
                @click="openDrawer(a)"
              >
                <td @click.stop style="font-weight: 600; color: #64748b; font-size: 12px; padding-left: 18px;">{{ (currentPage - 1) * 15 + index + 1 }}</td>
                <td>
                  <div class="person-cell">
                    <div class="avatar" :style="{ background: a.avatarBg }">{{ initials(a.name) }}</div>
                    <div>
                      <p class="person-name">{{ a.name }}</p>
                      <p class="person-meta">{{ a.location }}</p>
                    </div>
                  </div>
                </td>
                <td>
                  <div class="skill-tags">
                    <span v-for="sk in a.skills.slice(0,2)" :key="sk" class="skill-tag">{{ sk }}</span>
                    <span v-if="a.skills.length > 2" class="skill-more">+{{ a.skills.length - 2 }}</span>
                  </div>
                </td>
                <td class="job-cell">{{ a.jobApplied }}</td>
                <td class="employer-cell">{{ a.employer }}</td>
                <td class="date-cell">{{ a.date }}</td>
                <td @click.stop>
                  <span class="status-badge" :class="statusClass(a.status)">{{ a.status }}</span>
                </td>
                <td @click.stop>
                  <div class="file-icons">
                    <button class="file-btn" :class="{ has: a.files.resume }" title="Resume">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                    </button>
                    <button class="file-btn" :class="{ has: a.files.cert }" title="Certificate">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="6"/><path d="M15.477 12.89L17 22l-5-3-5 3 1.523-9.11"/></svg>
                    </button>
                    <button class="file-btn" :class="{ has: a.files.clearance }" title="Clearance">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                    </button>
                  </div>
                </td>
                <td @click.stop>
                  <button class="act-btn view" @click="openDrawer(a)" title="View">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </template>

        <!-- Pagination — always visible -->
        <div v-if="lastPage > 1" class="pagination">
          <span class="page-info">Showing {{ (currentPage - 1) * 15 + 1 }}–{{ Math.min(currentPage * 15, totalApplicants) }} of {{ totalApplicants }} applicants</span>
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
              <div class="drawer-avatar" :style="{ background: selected?.avatarBg }">
                {{ selected ? initials(selected.name) : '' }}
              </div>
              <div class="drawer-title-wrap">
                <h2 class="drawer-name">{{ selected?.name }}</h2>
                <p class="drawer-loc">{{ selected?.location }}</p>
              </div>
              <span v-if="selected" class="status-badge lg" :class="statusClass(selected.status)">{{ selected?.status }}</span>
              <button class="drawer-close" @click="drawerOpen = false">✕</button>
            </div>

            <!-- Drawer Tabs -->
            <div class="drawer-tabs">
              <button v-for="dt in drawerTabList" :key="dt" :class="['dtab', { active: drawerTab === dt }]" @click="drawerTab = dt">{{ dt }}</button>
            </div>

            <div class="drawer-body">
              <!-- Profile Tab -->
              <div v-if="drawerTab === 'Profile'">
                <div class="info-grid">
                  <div class="info-item"><span class="info-label">Full Name</span><span class="info-val">{{ selected?.name }}</span></div>
                  <div class="info-item"><span class="info-label">Location</span><span class="info-val">{{ selected?.location }}</span></div>
                  <div class="info-item"><span class="info-label">Contact</span><span class="info-val">{{ selected?.contact }}</span></div>
                  <div class="info-item"><span class="info-label">Email</span><span class="info-val">{{ selected?.email }}</span></div>
                  <div class="info-item"><span class="info-label">Education</span><span class="info-val">{{ selected?.education }}</span></div>
                  <div class="info-item"><span class="info-label">Experience</span><span class="info-val">{{ selected?.experience }}</span></div>
                </div>
                <div class="section-label">Skills</div>
                <div class="skill-tags mt4">
                  <span v-for="sk in selected?.skills" :key="sk" class="skill-tag">{{ sk }}</span>
                </div>
                <div class="section-label">Job Applied For</div>
                <div class="applied-job-box">
                  <p class="applied-job">{{ selected?.jobApplied }}</p>
                  <p class="applied-employer">{{ selected?.employer }}</p>
                </div>
              </div>

              <!-- Files Tab -->
              <div v-if="drawerTab === 'Files'">
                <div class="files-list">
                  <div v-for="file in fileList" :key="file.label" class="file-row">
                    <div class="file-icon-lg" :class="{ uploaded: selected?.files[file.key] }">
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                    </div>
                    <div class="file-info">
                      <p class="file-name">{{ file.label }}</p>
                      <p class="file-status">{{ selected?.files[file.key] ? 'Uploaded' : 'Not uploaded' }}</p>
                    </div>
                    <button
                      v-if="selected?.files[file.key]"
                      type="button"
                      class="btn-view"
                      @click.stop="viewApplicantDocument(file.key)"
                    >View</button>
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
  name: 'ApplicantsPage',
  async mounted() {
    await this.fetchApplicants()
  },
  data() {
    return {
      search: '',
      filterStatus: '',
      filterSkill: '',
      filterDate: '',
      activeTab: 'all',
      drawerOpen: false,
      drawerTab: 'Profile',
      selected: null,
      loading: false,
      pageLoading: false,  // separate flag for pagination skeleton
      drawerTabList: ['Profile', 'Files'],
      fileList: [
        { label: 'Resume / CV',           key: 'resume'    },
        { label: 'Certificate / Diploma',  key: 'cert'      },
        { label: 'Barangay Clearance',     key: 'clearance' },
      ],
      statusTabs: [
        { label: 'All',         value: 'all',         count: 0 },
        { label: 'Reviewing',   value: 'reviewing',   count: 0 },
        { label: 'Shortlisted', value: 'shortlisted', count: 0 },
        { label: 'Interview',   value: 'interview',   count: 0 },
        { label: 'Hired',       value: 'hired',       count: 0 },
        { label: 'Rejected',    value: 'rejected',    count: 0 },
      ],
      skillOptions: ['Accounting', 'IT / Dev', 'Nursing', 'Electrical', 'Teaching', 'BPO', 'Welding', 'Driving'],
      applicants: [],
      currentPage: 1,
      lastPage: 1,
      totalApplicants: 0,
    }
  },
  computed: {
    paginationPages() {
      const pages = []
      const start = Math.max(1, this.currentPage - 2)
      const end   = Math.min(this.lastPage, this.currentPage + 2)
      for (let i = start; i <= end; i++) pages.push(i)
      return pages
    },
    filteredApplicants() {
      return this.applicants.filter(a => {
        const matchTab    = this.activeTab === 'all' || a.status === this.activeTab
        const matchSearch = !this.search ||
          a.name.toLowerCase().includes(this.search.toLowerCase()) ||
          a.skills.some(s => s.toLowerCase().includes(this.search.toLowerCase())) ||
          a.location.toLowerCase().includes(this.search.toLowerCase())
        const matchStatus = !this.filterStatus || a.status === this.filterStatus
        const matchSkill  = !this.filterSkill  || a.skills.includes(this.filterSkill)
        return matchTab && matchSearch && matchStatus && matchSkill
      })
    },
  },
  methods: {
    async fetchApplicants(isPaginating = false) {
      // Use pageLoading for pagination changes, loading for initial mount
      if (isPaginating) {
        this.pageLoading = true
      } else {
        this.loading = true
      }

      try {
        const params = { page: this.currentPage }
        if (this.search)       params.search    = this.search
        if (this.filterStatus) params.status    = this.filterStatus
        if (this.filterSkill)  params.skill     = this.filterSkill
        if (this.filterDate)   params.date_from = this.filterDate
        if (this.activeTab !== 'all') params.status = this.activeTab

        const { data } = await api.get('/admin/applications', { params })
        const colors = ['#2563eb','#f97316','#22c55e','#06b6d4','#a855f7','#ef4444','#3b82f6','#14b8a6']

        const payload = data.data || {}
        this.currentPage     = payload.current_page || 1
        this.lastPage        = payload.last_page    || 1
        this.totalApplicants = payload.total        || 0

        this.applicants = (payload.data || []).map((a, i) => {
          const js = a.jobseeker   || {}
          const jl = a.job_listing || {}
          return {
            id:          a.id,
            jobseekerId: js.id ?? null,
            name:        `${js.first_name || ''} ${js.last_name || ''}`.trim() || 'Unknown',
            location:    js.address         || 'N/A',
            contact:     js.contact         || 'N/A',
            email:       js.email           || 'N/A',
            education:   js.education_level || 'N/A',
            experience:  js.job_experience  || 'N/A',
            skills:      js.skills?.map(s => s.skill) || [],
            jobApplied:  jl.title                  || 'Unknown',
            employer:    jl.employer?.company_name  || 'Unknown',
            date:        new Date(a.created_at || a.applied_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
            status:      a.status || 'reviewing',
            avatarBg:    colors[i % colors.length],
            notes:       a.notes || '',
            files: {
              resume:    !!js.resume_path,
              cert:      !!js.certificate_path,
              clearance: !!js.barangay_clearance_path,
            },
          }
        })
        this.updateTabCounts()
      } catch (e) {
        console.error(e)
      } finally {
        this.loading     = false
        this.pageLoading = false
      }
    },

    updateTabCounts() {
      this.statusTabs[0].count = this.applicants.length
      this.statusTabs[1].count = this.applicants.filter(a => a.status === 'reviewing').length
      this.statusTabs[2].count = this.applicants.filter(a => a.status === 'shortlisted').length
      this.statusTabs[3].count = this.applicants.filter(a => a.status === 'interview').length
      this.statusTabs[4].count = this.applicants.filter(a => a.status === 'hired').length
      this.statusTabs[5].count = this.applicants.filter(a => a.status === 'rejected').length
    },

    changePage(page) {
      if (page >= 1 && page <= this.lastPage && !this.pageLoading) {
        this.currentPage = page
        this.fetchApplicants(true)  // pass true = paginating
      }
    },

    initials(name) {
      return name.split(' ').map(n => n[0]).slice(0, 2).join('').toUpperCase()
    },

    statusClass(status) {
      if (!status) return ''
      return status.toLowerCase()
    },

    openDrawer(applicant) {
      this.selected   = { ...applicant }
      this.drawerTab  = 'Profile'
      this.drawerOpen = true
    },

    async viewApplicantDocument(fileKey) {
      const jid = this.selected?.jobseekerId
      if (!jid) {
        alert('Applicant record is missing — refresh the list and try again.')
        return
      }
      const typeMap = { resume: 'resume', cert: 'certificate', clearance: 'clearance' }
      const type = typeMap[fileKey]
      if (!type) return
      try {
        const res = await api.get(
          `/admin/jobseekers/${jid}/documents/${type}`,
          { responseType: 'blob' },
        )
        const blob = new Blob([res.data], { type: 'application/pdf' })
        const url  = URL.createObjectURL(blob)
        const win  = window.open(url, '_blank', 'noopener,noreferrer')
        if (!win) alert('Pop-up blocked. Allow pop-ups for this site to view the PDF.')
        setTimeout(() => URL.revokeObjectURL(url), 120000)
      } catch (e) {
        console.error(e)
        alert('Could not open document. It may be missing or you may have lost access.')
      }
    },

    async updateStatus(applicant, status) {
      try {
        await api.patch(`/admin/applications/${applicant.id}/status`, {
          status,
          notes: applicant.notes,
        })
        const idx = this.applicants.findIndex(a => a.id === applicant.id)
        if (idx !== -1) {
          this.applicants[idx].status = status
          this.applicants[idx].notes  = applicant.notes
        }
        if (this.selected?.id === applicant.id) {
          this.selected.status = status
          this.selected.notes  = applicant.notes
        }
        this.updateTabCounts()
      } catch (e) { console.error(e) }
    },

    async uploadFile(applicantId, type, file) {
      const fd = new FormData()
      fd.append('file', file)
      try {
        await api.post(`/admin/applicants/${applicantId}/files/${type}`, fd, {
          headers: { 'Content-Type': 'multipart/form-data' },
        })
        await this.fetchApplicants()
      } catch (e) { console.error(e) }
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
  padding: 24px;
  background: #f8fafc;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* FILTERS */
.filters-bar {
  display: flex; align-items: center; justify-content: space-between;
  gap: 10px; flex-wrap: wrap;
}
.search-box {
  display: flex; align-items: center; gap: 8px;
  background: #fff; border: 1px solid #e2e8f0;
  border-radius: 10px; padding: 8px 12px; flex: 1; max-width: 360px;
}
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-group { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.filter-select {
  background: #fff; border: 1px solid #e2e8f0; border-radius: 8px;
  padding: 8px 12px; font-size: 12.5px; color: #475569;
  cursor: pointer; outline: none; font-family: inherit;
}

/* STATUS TABS */
.status-tabs { display: flex; gap: 4px; }
.tab-btn {
  display: flex; align-items: center; gap: 6px;
  background: none; border: none; padding: 8px 14px;
  font-size: 13px; font-weight: 500; color: #64748b;
  cursor: pointer; border-radius: 8px; font-family: inherit;
  transition: all 0.15s;
}
.tab-btn:hover  { background: #f1f5f9; }
.tab-btn.active { background: #eff6ff; color: #2563eb; font-weight: 700; }

.tab-count {
  font-size: 10px; font-weight: 700; padding: 2px 7px;
  border-radius: 99px; background: #f1f5f9; color: #64748b;
}
.tab-count.reviewing   { background: #dbeafe; color: #1d4ed8; }
.tab-count.shortlisted { background: #eff8ff; color: #1a5f8a; }
.tab-count.interview   { background: #ede9fe; color: #8B5CF6; }
.tab-count.hired       { background: #dcfce7; color: #16a34a; }
.tab-count.rejected    { background: #fef2f2; color: #ef4444; }

/* TABLE */
.table-card { background: #fff; border-radius: 14px; overflow: hidden; border: 1px solid #f1f5f9; }
.data-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.data-table thead tr { background: #f8fafc; }
.data-table th {
  text-align: left; padding: 11px 14px;
  font-size: 11px; font-weight: 700; color: #94a3b8;
  letter-spacing: 0.04em; text-transform: uppercase;
  border-bottom: 1px solid #f1f5f9; white-space: nowrap;
}
.table-row { cursor: pointer; transition: background 0.12s; }
.table-row:hover { background: #f8fafc; }
.data-table td { padding: 12px 14px; border-bottom: 1px solid #f8fafc; vertical-align: middle; }

.person-cell { display: flex; align-items: center; gap: 10px; }
.avatar {
  width: 34px; height: 34px; border-radius: 50%;
  color: #fff; font-size: 12px; font-weight: 700;
  display: flex; align-items: center; justify-content: center; flex-shrink: 0;
}
.person-name { font-size: 13px; font-weight: 600; color: #1e293b; }
.person-meta { font-size: 11px; color: #94a3b8; margin-top: 1px; }

.skill-tags { display: flex; align-items: center; gap: 4px; flex-wrap: wrap; }
.skill-tag  { background: #eff6ff; color: #2563eb; font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
.skill-more { font-size: 11px; color: #94a3b8; }

.job-cell      { color: #475569; font-size: 12.5px; }
.employer-cell { color: #64748b; font-size: 12px; }
.date-cell     { color: #94a3b8; font-size: 12px; white-space: nowrap; }

/* STATUS BADGES */
.status-badge {
  padding: 4px 10px; border-radius: 99px;
  font-size: 11px; font-weight: 600; white-space: nowrap;
  text-transform: capitalize;
}
.status-badge.lg { padding: 5px 14px; font-size: 12px; }
.reviewing   { background: #dbeafe; color: #1d4ed8; }
.shortlisted { background: #eff8ff; color: #1a5f8a; }
.interview   { background: #ede9fe; color: #8B5CF6; }
.hired       { background: #dcfce7; color: #16a34a; }
.rejected    { background: #fef2f2; color: #ef4444; }

/* FILE ICONS */
.file-icons { display: flex; gap: 4px; }
.file-btn {
  width: 26px; height: 26px; border-radius: 6px;
  border: 1px solid #e2e8f0; background: #f8fafc;
  display: flex; align-items: center; justify-content: center;
  cursor: pointer; color: #cbd5e1; transition: all 0.15s;
}
.file-btn.has   { background: #eff6ff; border-color: #bfdbfe; color: #2563eb; }
.file-btn:hover { background: #eff6ff; border-color: #93c5fd; color: #2563eb; }

/* ACTION BUTTON */
.act-btn {
  width: 28px; height: 28px; border-radius: 7px; border: none;
  display: flex; align-items: center; justify-content: center;
  cursor: pointer; transition: all 0.15s;
}
.act-btn.view       { background: #eff6ff; color: #2563eb; }
.act-btn.view:hover { background: #dbeafe; }

/* PAGINATION */
.pagination {
  display: flex; align-items: center; justify-content: space-between;
  padding: 14px 18px; border-top: 1px solid #f1f5f9;
}
.page-info { font-size: 12px; color: #94a3b8; }
.page-btns { display: flex; gap: 4px; }
.page-btn {
  width: 30px; height: 30px; border-radius: 7px;
  border: 1px solid #e2e8f0; background: #fff;
  font-size: 12px; color: #64748b; cursor: pointer; font-family: inherit;
  display: flex; align-items: center; justify-content: center;
  transition: all 0.15s;
}
.page-btn:disabled           { opacity: 0.4; cursor: not-allowed; }
.page-btn.active             { background: #2563eb; color: #fff; border-color: #2563eb; }
.page-btn:hover:not(.active):not(:disabled) { background: #f8fafc; }

/* DRAWER */
.drawer-overlay {
  position: fixed; inset: 0; background: rgba(15,23,42,0.3);
  z-index: 100; display: flex; justify-content: flex-end;
  backdrop-filter: blur(2px);
}
.drawer {
  width: 420px; height: 100vh; background: #fff;
  display: flex; flex-direction: column; overflow: hidden;
  box-shadow: -8px 0 32px rgba(0,0,0,0.12);
}
.drawer-header {
  display: flex; align-items: center; gap: 12px;
  padding: 20px; border-bottom: 1px solid #f1f5f9;
}
.drawer-avatar {
  width: 46px; height: 46px; border-radius: 50%;
  color: #fff; font-size: 16px; font-weight: 700;
  display: flex; align-items: center; justify-content: center; flex-shrink: 0;
}
.drawer-title-wrap { flex: 1; }
.drawer-name { font-size: 16px; font-weight: 800; color: #1e293b; }
.drawer-loc  { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.drawer-close {
  background: none; border: none; cursor: pointer;
  color: #94a3b8; font-size: 16px; padding: 4px; border-radius: 6px;
}
.drawer-close:hover { background: #f1f5f9; color: #1e293b; }

.drawer-tabs { display: flex; border-bottom: 1px solid #f1f5f9; padding: 0 20px; }
.dtab {
  background: none; border: none; padding: 12px 16px;
  font-size: 13px; font-weight: 500; color: #64748b;
  cursor: pointer; font-family: inherit; border-bottom: 2px solid transparent;
  transition: all 0.15s; margin-bottom: -1px;
}
.dtab.active { color: #2563eb; border-bottom-color: #2563eb; font-weight: 700; }

.drawer-body { flex: 1; overflow-y: auto; padding: 20px; }

.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 18px; }
.info-item { display: flex; flex-direction: column; gap: 3px; }
.info-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
.info-val   { font-size: 13px; font-weight: 500; color: #1e293b; }

.section-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.06em; margin: 16px 0 8px; }
.mt4 { margin-top: 4px; }

.applied-job-box  { background: #f8fafc; border-radius: 10px; padding: 12px 14px; border: 1px solid #f1f5f9; }
.applied-job      { font-size: 14px; font-weight: 700; color: #1e293b; }
.applied-employer { font-size: 12px; color: #64748b; margin-top: 3px; }

/* FILES */
.files-list { display: flex; flex-direction: column; gap: 10px; }
.file-row {
  display: flex; align-items: center; gap: 12px;
  padding: 12px 14px; background: #f8fafc;
  border-radius: 10px; border: 1px solid #f1f5f9;
}
.file-icon-lg {
  width: 38px; height: 38px; border-radius: 10px;
  background: #e2e8f0; display: flex; align-items: center; justify-content: center;
  color: #94a3b8; flex-shrink: 0;
}
.file-icon-lg.uploaded { background: #dbeafe; color: #2563eb; }
.file-info   { flex: 1; }
.file-name   { font-size: 13px; font-weight: 600; color: #1e293b; }
.file-status { font-size: 11px; color: #94a3b8; margin-top: 2px; }
.btn-view    { background: #eff6ff; color: #2563eb; border: none; border-radius: 7px; padding: 6px 12px; font-size: 12px; font-weight: 600; cursor: pointer; font-family: inherit; }

/* DRAWER TRANSITION */
.drawer-enter-active, .drawer-leave-active { transition: opacity 0.2s; }
.drawer-enter-active .drawer, .drawer-leave-active .drawer { transition: transform 0.25s cubic-bezier(0.4,0,0.2,1); }
.drawer-enter-from, .drawer-leave-to { opacity: 0; }
.drawer-enter-from .drawer, .drawer-leave-to .drawer { transform: translateX(100%); }
</style>