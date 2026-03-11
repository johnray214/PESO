<template>
  <div class="layout-wrapper">
    <EmployerSidebar />
    <div class="main-area">
      <EmployerTopbar title="Applicants" subtitle="Review and manage people who applied to your job listings" />
      <div class="page">

        <!-- Filters -->
        <div class="filters-bar">
          <div class="search-box">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            <input v-model="search" type="text" placeholder="Search by name, skill, position…" class="search-input"/>
          </div>
          <div class="filter-group">
            <select v-model="filterJob" class="filter-select">
              <option value="">All Positions</option>
              <option v-for="j in jobOptions" :key="j" :value="j">{{ j }}</option>
            </select>
            <select v-model="filterStatus" class="filter-select">
              <option value="">All Status</option>
              <option value="Reviewing">Reviewing</option>
              <option value="Shortlisted">Shortlisted</option>
              <option value="Interview">Interview</option>
              <option value="Hired">Hired</option>
              <option value="Rejected">Rejected</option>
            </select>
            <button class="btn-icon">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
              Export
            </button>
          </div>
        </div>

        <!-- Status Tabs -->
        <div class="status-tabs">
          <button v-for="tab in statusTabs" :key="tab.value" :class="['tab-btn', { active: activeTab === tab.value }]" @click="activeTab = tab.value">
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
                <th>Applicant</th>
                <th>Skills</th>
                <th>Applied For</th>
                <th>Applied Date</th>
                <th>Match Score</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="a in filteredApplicants" :key="a.id" class="table-row" @click="openDrawer(a)">
                <td @click.stop><input type="checkbox" class="check"/></td>
                <td>
                  <div class="person-cell">
                    <div class="avatar" :style="{ background: a.avatarBg }">{{ a.name[0] }}</div>
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
                <td class="date-cell">{{ a.date }}</td>
                <td @click.stop>
                  <div class="score-cell">
                    <div class="score-bar-bg">
                      <div class="score-bar-fill" :style="{ width: a.matchScore + '%', background: scoreColor(a.matchScore) }"></div>
                    </div>
                    <span class="score-val" :style="{ color: scoreColor(a.matchScore) }">{{ a.matchScore }}%</span>
                  </div>
                </td>
                <td @click.stop>
                  <span class="status-badge" :class="statusClass(a.status)">{{ a.status }}</span>
                </td>
                <td @click.stop>
                  <div class="action-btns">
                    <button class="act-btn view" @click="openDrawer(a)" title="View">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    </button>
                    <button class="act-btn accept" @click.stop title="Move to Interview">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
                    </button>
                    <button class="act-btn reject" @click.stop title="Reject">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
          <div class="pagination">
            <span class="page-info">Showing {{ filteredApplicants.length }} of {{ applicants.length }} applicants</span>
            <div class="page-btns">
              <button class="page-btn">‹</button>
              <button class="page-btn active">1</button>
              <button class="page-btn">2</button>
              <button class="page-btn">›</button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- DRAWER -->
    <transition name="drawer">
      <div v-if="drawerOpen" class="drawer-overlay" @click.self="drawerOpen = false">
        <div class="drawer">
          <div class="drawer-header">
            <div class="drawer-avatar" :style="{ background: selected?.avatarBg }">{{ selected?.name[0] }}</div>
            <div class="drawer-title-wrap">
              <h2 class="drawer-name">{{ selected?.name }}</h2>
              <p class="drawer-loc">{{ selected?.location }} · {{ selected?.jobApplied }}</p>
            </div>
            <span class="status-badge" :class="statusClass(selected?.status)">{{ selected?.status }}</span>
            <button class="drawer-close" @click="drawerOpen = false">✕</button>
          </div>

          <!-- Match Score Banner -->
          <div class="match-banner" :style="{ background: scoreBg(selected?.matchScore) }">
            <div class="match-info">
              <span class="match-label">Match Score</span>
              <span class="match-val" :style="{ color: scoreColor(selected?.matchScore) }">{{ selected?.matchScore }}%</span>
            </div>
            <div class="match-bar-bg">
              <div class="match-bar-fill" :style="{ width: selected?.matchScore + '%', background: scoreColor(selected?.matchScore) }"></div>
            </div>
          </div>

          <div class="drawer-tabs">
            <button v-for="dt in ['Profile', 'Resume', 'Status']" :key="dt" :class="['dtab', { active: drawerTab === dt }]" @click="drawerTab = dt">{{ dt }}</button>
          </div>

          <div class="drawer-body">
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
              <div class="section-label">Applied Position</div>
              <div class="applied-box">
                <p class="applied-job">{{ selected?.jobApplied }}</p>
                <p class="applied-date">Applied {{ selected?.date }}</p>
              </div>
            </div>

            <div v-if="drawerTab === 'Resume'">
              <div class="resume-placeholder">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
                <p class="resume-msg">Resume / CV</p>
                <button class="btn-amber">View Document</button>
              </div>
            </div>

            <div v-if="drawerTab === 'Status'">
              <div class="section-label">Update Status</div>
              <div class="status-options">
                <button v-for="st in ['Reviewing','Shortlisted','Interview','Hired','Rejected']" :key="st"
                  :class="['status-option', statusClass(st), { active: selected?.status === st }]"
                  @click="selected.status = st">{{ st }}</button>
              </div>
              <div class="section-label mt16">Internal Notes</div>
              <textarea class="notes-area" placeholder="Add notes about this applicant…" rows="4" v-model="selected.notes"></textarea>
              <button class="btn-amber-full mt12">Save Changes</button>
            </div>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
import api from '@/services/api'
import EmployerSidebar from '@/components/EmployerSidebar.vue'
import EmployerTopbar from '@/components/EmployerTopbar.vue'

export default {
  name: 'EmployerApplicants',
  components: { EmployerSidebar, EmployerTopbar },
  async mounted() {
    await this.fetchApplicants()
  },
  data() {
    return {
      search: '', filterJob: '', filterStatus: '',
      activeTab: 'all', drawerOpen: false, drawerTab: 'Profile', selected: null,
      jobOptions: ['Frontend Developer', 'Backend Developer', 'UI/UX Designer', 'DevOps Engineer', 'Project Manager'],
      statusTabs: [
        { label: 'All',         value: 'all',         count: 12, cls: '' },
        { label: 'Reviewing',   value: 'Reviewing',   count: 4,  cls: 'reviewing' },
        { label: 'Shortlisted', value: 'Shortlisted', count: 3,  cls: 'shortlisted' },
        { label: 'Interview',   value: 'Interview',   count: 2,  cls: 'interview' },
        { label: 'Hired',       value: 'Hired',       count: 2,  cls: 'hired' },
        { label: 'Rejected',    value: 'Rejected',    count: 1,  cls: 'rejected' },
      ],
      applicants: [
        { id:1, name:'Maria Santos',   location:'Quezon City', contact:'09171234567', email:'maria@email.com', education:'BS Computer Science', experience:'3 years', skills:['Vue.js','JavaScript','CSS'], jobApplied:'Frontend Developer', date:'Dec 08, 2024', matchScore:92, status:'Shortlisted', avatarBg:'#2563eb', notes:'' },
        { id:2, name:'Juan dela Cruz', location:'Marikina',    contact:'09189876543', email:'juan@email.com',  education:'BS IT',               experience:'4 years', skills:['Laravel','PHP','MySQL'],    jobApplied:'Backend Developer',  date:'Dec 08, 2024', matchScore:85, status:'Reviewing',   avatarBg:'#f97316', notes:'' },
        { id:3, name:'Ana Reyes',      location:'Pasig',       contact:'09201122334', email:'ana@email.com',   education:'BS Fine Arts',         experience:'5 years', skills:['Figma','UI/UX','Adobe XD'], jobApplied:'UI/UX Designer',     date:'Dec 07, 2024', matchScore:88, status:'Interview',   avatarBg:'#8b5cf6', notes:'' },
        { id:4, name:'Pedro Lim',      location:'Caloocan',    contact:'09334455667', email:'pedro@email.com', education:'BS Computer Eng',      experience:'2 years', skills:['React','TypeScript'],       jobApplied:'Frontend Developer', date:'Dec 07, 2024', matchScore:79, status:'Hired',       avatarBg:'#22c55e', notes:'' },
        { id:5, name:'Rosa Garcia',    location:'Taguig',      contact:'09455566778', email:'rosa@email.com',  education:'BS IT',               experience:'3 years', skills:['Node.js','Express','MongoDB'], jobApplied:'Backend Developer', date:'Dec 06, 2024', matchScore:74, status:'Reviewing',   avatarBg:'#06b6d4', notes:'' },
        { id:6, name:'Carlo Bautista', location:'Valenzuela',  contact:'09566677889', email:'carlo@email.com', education:'BS Computer Science', experience:'6 years', skills:['AWS','Docker','Kubernetes'],  jobApplied:'DevOps Engineer',    date:'Dec 05, 2024', matchScore:96, status:'Hired',       avatarBg:'#10b981', notes:'' },
        { id:7, name:'Lea Mendoza',    location:'Parañaque',   contact:'09677788990', email:'lea@email.com',   education:'MBA',                 experience:'8 years', skills:['Agile','Scrum','JIRA'],      jobApplied:'Project Manager',    date:'Dec 04, 2024', matchScore:81, status:'Shortlisted', avatarBg:'#d946ef', notes:'' },
        { id:8, name:'Noel Santos',    location:'Las Piñas',   contact:'09788899001', email:'noel@email.com',  education:'BS Architecture',     experience:'1 year',  skills:['Figma','Sketch'],            jobApplied:'UI/UX Designer',     date:'Dec 03, 2024', matchScore:62, status:'Rejected',    avatarBg:'#ef4444', notes:'' },
      ]
    }
  },
  computed: {
    filteredApplicants() {
      return this.applicants.filter(a => {
        const matchTab    = this.activeTab === 'all' || a.status === this.activeTab
        const matchSearch = !this.search || a.name.toLowerCase().includes(this.search.toLowerCase()) || a.skills.some(s => s.toLowerCase().includes(this.search.toLowerCase()))
        const matchJob    = !this.filterJob    || a.jobApplied === this.filterJob
        const matchStatus = !this.filterStatus || a.status === this.filterStatus
        return matchTab && matchSearch && matchJob && matchStatus
      })
    },
    
  },
  methods: {
    async fetchApplicants() {
      try {
        const params = {}
        if (this.search)       params.search = this.search
        if (this.filterJob)    params.job    = this.filterJob
        if (this.filterStatus) params.status = this.filterStatus
        if (this.activeTab !== 'all') params.status = this.activeTab
        const { data } = await api.get('/employer/applicants', { params })
        const colors = ['#2563eb','#f97316','#22c55e','#06b6d4','#a855f7','#ef4444','#3b82f6','#14b8a6']
        this.applicants = (data.data || data || []).map((a, i) => ({
          ...a,
          avatarBg: a.avatarBg || colors[i % colors.length],
        }))
        this.updateTabCounts()
      } catch (e) { console.error(e) }
    },
    updateTabCounts() {
      this.statusTabs[0].count = this.applicants.length
      this.statusTabs[1].count = this.applicants.filter(a => a.status === 'Reviewing').length
      this.statusTabs[2].count = this.applicants.filter(a => a.status === 'Shortlisted').length
      this.statusTabs[3].count = this.applicants.filter(a => a.status === 'Interview').length
      this.statusTabs[4].count = this.applicants.filter(a => a.status === 'Hired').length
      this.statusTabs[5].count = this.applicants.filter(a => a.status === 'Rejected').length
    },
    statusClass(s) {
      return { Reviewing:'reviewing', Shortlisted:'shortlisted', Interview:'interview', Hired:'hired', Rejected:'rejected' }[s] || ''
    },
    scoreColor(v) { return v >= 85 ? '#22c55e' : v >= 70 ? '#2872A1' : '#ef4444' },
    scoreBg(v)    { return v >= 85 ? '#f0fdf4' : v >= 70 ? '#eff8ff' : '#fef2f2' },
    openDrawer(a) { this.selected = { ...a }; this.drawerTab = 'Profile'; this.drawerOpen = true },
    async updateStatus(applicant, status) {
      try {
        await api.patch(`/employer/applicants/${applicant.id}/status`, {
          status,
          notes: applicant.notes || this.selected?.notes,
        })
        const idx = this.applicants.findIndex(a => a.id === applicant.id)
        if (idx !== -1) this.applicants[idx].status = status
        if (this.selected?.id === applicant.id) this.selected.status = status
        this.updateTabCounts()
      } catch (e) { console.error(e) }
    },
    async saveDrawerChanges() {
      if (!this.selected) return
      await this.updateStatus(this.selected, this.selected.status)
    },
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
.layout-wrapper { display: flex; height: 100vh; overflow: hidden; background: #f8fafc; font-family: 'Plus Jakarta Sans', sans-serif; }
.main-area { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
.page { flex: 1; overflow-y: auto; padding: 24px; display: flex; flex-direction: column; gap: 16px; }



.filters-bar { display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; flex: 1; max-width: 360px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-group { display: flex; align-items: center; gap: 8px; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }
.btn-icon { display: flex; align-items: center; gap: 6px; background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; font-family: inherit; }

.status-tabs { display: flex; gap: 4px; }
.tab-btn { display: flex; align-items: center; gap: 6px; background: none; border: none; padding: 8px 14px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; border-radius: 8px; font-family: inherit; }
.tab-btn:hover { background: #f1f5f9; }
.tab-btn.active { background: #eff8ff; color: #1a5f8a; font-weight: 700; }
.tab-count { font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }
.tab-count.reviewing   { background: #eff6ff; color: #3b82f6; }
.tab-count.shortlisted { background: #eff8ff; color: #1a5f8a; }
.tab-count.interview   { background: #faf5ff; color: #8b5cf6; }
.tab-count.hired       { background: #f0fdf4; color: #22c55e; }
.tab-count.rejected    { background: #fef2f2; color: #ef4444; }

.table-card { background: #fff; border-radius: 14px; overflow: hidden; border: 1px solid #f1f5f9; }
.data-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.data-table thead tr { background: #f8fafc; }
.data-table th { text-align: left; padding: 11px 14px; font-size: 11px; font-weight: 700; color: #94a3b8; letter-spacing: 0.04em; text-transform: uppercase; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.table-row { cursor: pointer; transition: background 0.12s; }
.table-row:hover { background: #eff8ff; }
.data-table td { padding: 12px 14px; border-bottom: 1px solid #f8fafc; vertical-align: middle; }
.check { accent-color: #2872A1; cursor: pointer; }

.person-cell { display: flex; align-items: center; gap: 10px; }
.avatar { width: 34px; height: 34px; border-radius: 50%; color: #fff; font-size: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.person-name { font-size: 13px; font-weight: 600; color: #1e293b; }
.person-meta { font-size: 11px; color: #94a3b8; margin-top: 1px; }
.skill-tags { display: flex; align-items: center; gap: 4px; flex-wrap: wrap; }
.skill-tag { background: #f1f5f9; color: #475569; font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
.skill-more { font-size: 11px; color: #94a3b8; }
.job-cell { color: #475569; font-size: 12.5px; }
.date-cell { color: #94a3b8; font-size: 12px; white-space: nowrap; }

.score-cell { display: flex; align-items: center; gap: 8px; }
.score-bar-bg { width: 60px; height: 5px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.score-bar-fill { height: 100%; border-radius: 99px; }
.score-val { font-size: 12px; font-weight: 700; min-width: 32px; }

.status-badge { padding: 4px 10px; border-radius: 99px; font-size: 11px; font-weight: 600; white-space: nowrap; }
.reviewing   { background: #eff6ff; color: #3b82f6; }
.shortlisted { background: #eff8ff; color: #1a5f8a; }
.interview   { background: #faf5ff; color: #8b5cf6; }
.hired       { background: #f0fdf4; color: #22c55e; }
.rejected    { background: #fef2f2; color: #ef4444; }

.action-btns { display: flex; gap: 4px; }
.act-btn { width: 28px; height: 28px; border-radius: 7px; border: none; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.15s; }
.act-btn.view   { background: #f1f5f9; color: #64748b; }
.act-btn.view:hover   { background: #e2e8f0; }
.act-btn.accept { background: #f0fdf4; color: #22c55e; }
.act-btn.accept:hover { background: #dcfce7; }
.act-btn.reject { background: #fef2f2; color: #ef4444; }
.act-btn.reject:hover { background: #fee2e2; }

.pagination { display: flex; align-items: center; justify-content: space-between; padding: 14px 18px; border-top: 1px solid #f1f5f9; }
.page-info { font-size: 12px; color: #94a3b8; }
.page-btns { display: flex; gap: 4px; }
.page-btn { width: 30px; height: 30px; border-radius: 7px; border: 1px solid #e2e8f0; background: #fff; font-size: 12px; color: #64748b; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; }
.page-btn.active { background: #2872A1; color: #fff; border-color: #2872A1; }

/* DRAWER */
.drawer-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.3); z-index: 100; display: flex; justify-content: flex-end; backdrop-filter: blur(2px); }
.drawer { width: 420px; height: 100vh; background: #fff; display: flex; flex-direction: column; overflow: hidden; box-shadow: -8px 0 32px rgba(0,0,0,0.12); }
.drawer-header { display: flex; align-items: center; gap: 12px; padding: 20px; border-bottom: 1px solid #f1f5f9; }
.drawer-avatar { width: 46px; height: 46px; border-radius: 50%; color: #fff; font-size: 16px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.drawer-title-wrap { flex: 1; }
.drawer-name { font-size: 16px; font-weight: 800; color: #1e293b; }
.drawer-loc { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.drawer-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 16px; padding: 4px; border-radius: 6px; }
.drawer-close:hover { background: #f1f5f9; color: #1e293b; }

.match-banner { padding: 14px 20px; }
.match-info { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.match-label { font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; }
.match-val { font-size: 18px; font-weight: 800; }
.match-bar-bg { height: 6px; background: rgba(0,0,0,0.08); border-radius: 99px; overflow: hidden; }
.match-bar-fill { height: 100%; border-radius: 99px; }

.drawer-tabs { display: flex; border-bottom: 1px solid #f1f5f9; padding: 0 20px; }
.dtab { background: none; border: none; padding: 12px 16px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; font-family: inherit; border-bottom: 2px solid transparent; transition: all 0.15s; margin-bottom: -1px; }
.dtab.active { color: #1a5f8a; border-bottom-color: #2872A1; font-weight: 700; }
.drawer-body { flex: 1; overflow-y: auto; padding: 20px; }

.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 18px; }
.info-item { display: flex; flex-direction: column; gap: 3px; }
.info-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
.info-val { font-size: 13px; font-weight: 500; color: #1e293b; }
.section-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.06em; margin: 16px 0 8px; }
.mt4 { margin-top: 4px; }
.mt12 { margin-top: 12px; }
.mt16 { margin-top: 16px; }
.applied-box { background: #eff8ff; border-radius: 10px; padding: 12px 14px; border: 1px solid #bae6fd; }
.applied-job { font-size: 14px; font-weight: 700; color: #1e293b; }
.applied-date { font-size: 12px; color: #94a3b8; margin-top: 3px; }

.resume-placeholder { display: flex; flex-direction: column; align-items: center; gap: 12px; padding: 40px 20px; }
.resume-msg { font-size: 14px; font-weight: 600; color: #94a3b8; }
.btn-amber { background: #2872A1; color: #fff; border: none; border-radius: 10px; padding: 9px 20px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }

.status-options { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.status-option { padding: 10px; border-radius: 10px; border: 2px solid transparent; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; transition: all 0.15s; background: #f8fafc; color: #64748b; }
.status-option.active.reviewing   { background: #eff6ff; color: #3b82f6; border-color: #3b82f6; }
.status-option.active.shortlisted { background: #eff8ff; color: #1a5f8a; border-color: #2872A1; }
.status-option.active.interview   { background: #faf5ff; color: #8b5cf6; border-color: #8b5cf6; }
.status-option.active.hired       { background: #f0fdf4; color: #22c55e; border-color: #22c55e; }
.status-option.active.rejected    { background: #fef2f2; color: #ef4444; border-color: #ef4444; }
.notes-area { width: 100%; border: 1px solid #e2e8f0; border-radius: 10px; padding: 10px 12px; font-size: 13px; color: #1e293b; font-family: inherit; resize: vertical; outline: none; background: #f8fafc; }
.notes-area:focus { border-color: #08BDDE; background: #fff; }
.btn-amber-full { width: 100%; background: #2872A1; color: #fff; border: none; border-radius: 10px; padding: 11px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }

.drawer-enter-active, .drawer-leave-active { transition: opacity 0.2s; }
.drawer-enter-active .drawer, .drawer-leave-active .drawer { transition: transform 0.25s cubic-bezier(0.4,0,0.2,1); }
.drawer-enter-from, .drawer-leave-to { opacity: 0; }
.drawer-enter-from .drawer, .drawer-leave-to .drawer { transform: translateX(100%); }
</style>