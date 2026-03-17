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
            <input v-model="search" type="text" :placeholder="activeTab === 'potential' ? 'Search by name or skill…' : 'Search by name, skill, position…'" class="search-input"/>
          </div>
          <div class="filter-group">
            <template v-if="activeTab !== 'potential'">
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
            </template>
            <template v-else>
              <select v-model="potentialJobFilter" @change="potentialPage = 1" class="filter-select">
                <option value="">All Job Listings</option>
                <option v-for="j in jobOptions" :key="j" :value="j">{{ j }}</option>
              </select>
            </template>
            <button class="btn-icon">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
              Export
            </button>
          </div>
        </div>

        <!-- Main Tabs -->
        <div class="main-tabs">
          <button :class="['main-tab', { active: activeTab !== 'potential' }]" @click="activeTab = activeStatusTab">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
            Applied Applicants
            <span class="main-count">{{ applicants.length }}</span>
          </button>
          <button :class="['main-tab', 'potential-tab', { active: activeTab === 'potential' }]" @click="activeTab = 'potential'">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
            Potential Applicants
            <span class="main-count potential-count">{{ potentialApplicants.length }}</span>
          </button>
        </div>

        <!-- ===== APPLIED VIEW ===== -->
        <template v-if="activeTab !== 'potential'">
          <!-- Status sub-tabs -->
          <div class="status-tabs">
            <button v-for="tab in statusTabs" :key="tab.value" :class="['tab-btn', { active: activeTab === tab.value }]" @click="activeTab = tab.value; activeStatusTab = tab.value">
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
                <tr v-for="a in pagedApplicants" :key="a.id" class="table-row" @click="openDrawer(a)">
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
                      <button class="act-btn accept" @click.stop="updateStatus(a, 'Interview')" title="Interview">
                        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
                      </button>
                      <button class="act-btn reject" @click.stop="updateStatus(a, 'Rejected')" title="Reject">
                        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr v-if="pagedApplicants.length === 0">
                  <td colspan="8" class="empty-cell">No applicants found.</td>
                </tr>
              </tbody>
            </table>
            <div class="pagination">
              <span class="page-info">Showing {{ filteredApplicants.length === 0 ? 0 : (appliedPage - 1) * perPage + 1 }}–{{ Math.min(appliedPage * perPage, filteredApplicants.length) }} of {{ filteredApplicants.length }} applicants</span>
              <div class="page-btns">
                <button class="page-btn" :disabled="appliedPage === 1" @click="appliedPage--">‹</button>
                <button v-for="p in appliedTotalPages" :key="p" class="page-btn" :class="{ active: appliedPage === p }" @click="appliedPage = p">{{ p }}</button>
                <button class="page-btn" :disabled="appliedPage === appliedTotalPages" @click="appliedPage++">›</button>
              </div>
            </div>
          </div>
        </template>

        <!-- ===== POTENTIAL VIEW ===== -->
        <template v-if="activeTab === 'potential'">
          <div class="potential-notice">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2" style="flex-shrink:0;margin-top:1px"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            These are registered jobseekers on the platform whose skills match your active job listings — but <strong>&nbsp;have not applied yet</strong>. You can view their profile or send them an invite.
          </div>

          <!-- Job listing quick-filter tabs -->
          <div class="listing-tabs">
            <button class="listing-tab" :class="{ active: potentialJobFilter === '' }" @click="potentialJobFilter = ''; potentialPage = 1">
              All <span class="ltab-count">{{ potentialApplicants.length }}</span>
            </button>
            <button v-for="j in jobOptions" :key="j" class="listing-tab" :class="{ active: potentialJobFilter === j }" @click="potentialJobFilter = j; potentialPage = 1">
              {{ j }} <span class="ltab-count">{{ potentialApplicants.filter(a => a.bestFor === j).length }}</span>
            </button>
          </div>

          <div class="table-card">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Jobseeker</th>
                  <th>Matched Skills</th>
                  <th>Matches Your Listing</th>
                  <th>Skill Match Score</th>
                  <th>Location</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="a in pagedPotential" :key="a.name" class="table-row">
                  <td>
                    <div class="person-cell">
                      <div class="avatar" :style="{ background: a.color }">{{ a.name[0] }}</div>
                      <div>
                        <p class="person-name">{{ a.name }}</p>
                        <p class="person-meta">{{ a.education }}</p>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div class="skill-tags">
                      <span v-for="sk in a.skills" :key="sk" class="skill-tag matched-tag">{{ sk }}</span>
                    </div>
                  </td>
                  <td>
                    <div class="listing-match-cell">
                      <div class="listing-bar" :style="{ background: a.jobColor }"></div>
                      <div>
                        <p class="person-name" style="font-size:12.5px">{{ a.bestFor }}</p>
                        <p class="person-meta">Active listing</p>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div class="score-cell">
                      <div class="score-bar-bg">
                        <div class="score-bar-fill" :style="{ width: a.score + '%', background: scoreColor(a.score) }"></div>
                      </div>
                      <span class="score-val" :style="{ color: scoreColor(a.score) }">{{ a.score }}%</span>
                    </div>
                  </td>
                  <td>
                    <div class="loc-cell">
                      <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                      {{ a.location }}
                    </div>
                  </td>
                  <td>
                    <span class="not-applied-badge">
                      <span class="na-dot"></span>Not Applied
                    </span>
                  </td>
                  <td>
                    <div class="action-btns">
                      <button class="act-btn view" @click.stop="profileModal = a" title="View Profile">
                        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                      </button>
                      <button class="act-btn invite-act" @click.stop="sendInvite(a)" :title="a.invited ? 'Invited' : 'Invite to Apply'" :disabled="a.invited">
                        <svg v-if="!a.invited" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
                        <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr v-if="pagedPotential.length === 0">
                  <td colspan="7" class="empty-cell">No jobseekers match your current filters.</td>
                </tr>
              </tbody>
            </table>
            <div class="pagination">
              <span class="page-info">Showing {{ filteredPotential.length === 0 ? 0 : (potentialPage - 1) * perPage + 1 }}–{{ Math.min(potentialPage * perPage, filteredPotential.length) }} of {{ filteredPotential.length }} potential applicants</span>
              <div class="page-btns">
                <button class="page-btn" :disabled="potentialPage === 1" @click="potentialPage--">‹</button>
                <button v-for="p in potentialTotalPages" :key="p" class="page-btn" :class="{ active: potentialPage === p }" @click="potentialPage = p">{{ p }}</button>
                <button class="page-btn" :disabled="potentialPage === potentialTotalPages" @click="potentialPage++">›</button>
              </div>
            </div>
          </div>
        </template>

      </div>
    </div>

    <!-- DRAWER (Applied applicants) -->
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
              <div class="skill-tags mt4"><span v-for="sk in selected?.skills" :key="sk" class="skill-tag">{{ sk }}</span></div>
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
                <button class="btn-blue">View Document</button>
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
              <button class="btn-blue-full mt12" @click="updateStatus(selected, selected.status)">Save Changes</button>
            </div>
          </div>
        </div>
      </div>
    </transition>

    <!-- PROFILE MODAL (Potential applicants) -->
    <div v-if="profileModal" class="modal-overlay" @click.self="profileModal = null">
      <div class="modal-box">
        <div class="modal-header">
          <div class="modal-avatar" :style="{ background: profileModal.color }">{{ profileModal.name[0] }}</div>
          <div class="modal-info">
            <h4 class="modal-name">{{ profileModal.name }}</h4>
            <p class="modal-edu">{{ profileModal.education }}</p>
            <div class="modal-loc">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
              {{ profileModal.location }}
            </div>
          </div>
          <button class="modal-close" @click="profileModal = null">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>
        <div class="modal-body">
          <div class="modal-row">
            <p class="modal-label">Skills</p>
            <div class="skill-tags"><span v-for="sk in profileModal.skills" :key="sk" class="skill-tag matched-tag">{{ sk }}</span></div>
          </div>
          <div class="modal-row">
            <p class="modal-label">Best Match For</p>
            <div class="listing-match-cell">
              <div class="listing-bar" :style="{ background: profileModal.jobColor }"></div>
              <div>
                <p class="person-name">{{ profileModal.bestFor }}</p>
                <p class="person-meta">Active listing · {{ profileModal.score }}% skill match</p>
              </div>
            </div>
          </div>
          <div class="modal-row">
            <p class="modal-label">Skill Match Score</p>
            <div class="score-cell">
              <div class="score-bar-bg" style="flex:1"><div class="score-bar-fill" :style="{ width: profileModal.score + '%', background: scoreColor(profileModal.score) }"></div></div>
              <span class="score-val" :style="{ color: scoreColor(profileModal.score) }">{{ profileModal.score }}%</span>
            </div>
          </div>
          <div class="modal-row">
            <p class="modal-label">Status</p>
            <span class="not-applied-badge"><span class="na-dot"></span>Not Applied</span>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-blue-full" @click="sendInvite(profileModal); profileModal = null" :disabled="profileModal.invited">
            <template v-if="!profileModal.invited">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="margin-right:6px"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
              Invite to Apply for {{ profileModal.bestFor }}
            </template>
            <template v-else>✓ Invitation Already Sent</template>
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script>
import EmployerSidebar from '@/components/EmployerSidebar.vue'
import EmployerTopbar  from '@/components/EmployerTopbar.vue'
import { useEmployerApplicantsStore } from '@/stores/employerApplicantsStore'

export default {
  name: 'EmployerApplicants',
  components: { EmployerSidebar, EmployerTopbar },

  setup() {
    const applicantsStore = useEmployerApplicantsStore()
    return { applicantsStore }
  },

  data() {
    return {
      // Tab state
      activeTab: 'all',
      activeStatusTab: 'all',

      // Applied filters
      search: '', filterJob: '', filterStatus: '',
      appliedPage: 1, perPage: 5,

      // Drawer
      drawerOpen: false, drawerTab: 'Profile', selected: null,

      // Potential filters + pagination
      potentialJobFilter: '', potentialPage: 1,

      // Profile modal (potential)
      profileModal: null,
    }
  },

  computed: {
    // ---- Derive from store ----
    applicants()          { return this.applicantsStore.applicants },
    potentialApplicants() { return this.applicantsStore.potentialApplicants },

    jobOptions() {
      const titles = [...new Set(this.applicants.map((a) => a.jobApplied).filter(Boolean))]
      return titles
    },

    statusTabs() {
      return [
        { label: 'All',         value: 'all',         count: this.applicantsStore.totalApplicants,  cls: '' },
        { label: 'Reviewing',   value: 'Reviewing',   count: this.applicantsStore.reviewingCount,   cls: 'reviewing' },
        { label: 'Shortlisted', value: 'Shortlisted', count: this.applicantsStore.shortlistedCount, cls: 'shortlisted' },
        { label: 'Interview',   value: 'Interview',   count: this.applicantsStore.interviewCount,   cls: 'interview' },
        { label: 'Hired',       value: 'Hired',       count: this.applicantsStore.hiredCount,       cls: 'hired' },
        { label: 'Rejected',    value: 'Rejected',    count: this.applicantsStore.rejectedCount,    cls: 'rejected' },
      ]
    },

    // Applied
    filteredApplicants() {
      return this.applicants.filter((a) => {
        const matchTab    = this.activeTab === 'all' || a.status === this.activeTab
        const matchSearch = !this.search || a.name.toLowerCase().includes(this.search.toLowerCase()) || a.skills.some((s) => s.toLowerCase().includes(this.search.toLowerCase()))
        const matchJob    = !this.filterJob    || a.jobApplied === this.filterJob
        const matchStatus = !this.filterStatus || a.status === this.filterStatus
        return matchTab && matchSearch && matchJob && matchStatus
      })
    },
    appliedTotalPages() { return Math.max(1, Math.ceil(this.filteredApplicants.length / this.perPage)) },
    pagedApplicants() {
      const start = (this.appliedPage - 1) * this.perPage
      return this.filteredApplicants.slice(start, start + this.perPage)
    },

    // Potential
    filteredPotential() {
      let list = [...this.potentialApplicants]
      if (this.search) {
        const q = this.search.toLowerCase()
        list = list.filter((a) => a.name.toLowerCase().includes(q) || a.skills.some((s) => s.toLowerCase().includes(q)) || a.bestFor.toLowerCase().includes(q))
      }
      if (this.potentialJobFilter) list = list.filter((a) => a.bestFor === this.potentialJobFilter)
      return list.sort((a, b) => b.score - a.score)
    },
    potentialTotalPages() { return Math.max(1, Math.ceil(this.filteredPotential.length / this.perPage)) },
    pagedPotential() {
      const start = (this.potentialPage - 1) * this.perPage
      return this.filteredPotential.slice(start, start + this.perPage)
    },
  },

  methods: {
    statusClass(s) { return { Reviewing:'reviewing', Shortlisted:'shortlisted', Interview:'interview', Hired:'hired', Rejected:'rejected' }[s] || '' },
    scoreColor(v)  { return v >= 85 ? '#22c55e' : v >= 70 ? '#2872A1' : '#ef4444' },
    scoreBg(v)     { return v >= 85 ? '#f0fdf4' : v >= 70 ? '#eff8ff' : '#fef2f2' },
    openDrawer(a)  { this.selected = { ...a }; this.drawerTab = 'Profile'; this.drawerOpen = true },

    sendInvite(a) {
      this.applicantsStore.markInvited(a.id)
      // Mirror to local selected if open
      const found = this.potentialApplicants.find((x) => x.id === a.id)
      if (found) found.invited = true
    },

    async updateStatus(applicant, status) {
      try {
        await this.applicantsStore.updateStatus(applicant.id, status)
        if (this.selected?.id === applicant.id) this.selected.status = status
      } catch (e) {
        console.error('Failed to update status:', e)
      }
    },
  },

  mounted() {
    // Cache-first: no-op if sidebar already loaded it
    this.applicantsStore.fetch()
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
.layout-wrapper { display: flex; height: 100vh; overflow: hidden; background: #f8fafc; font-family: 'Plus Jakarta Sans', sans-serif; }
.main-area { flex: 1; display: flex; flex-direction: column; min-height: 0; overflow: hidden; }
.page { flex: 1; overflow-y: auto; overflow-x: hidden; padding: 24px; min-height: 0; }

/* Filters */
.filters-bar { display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; flex: 1; max-width: 360px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-group { display: flex; align-items: center; gap: 8px; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }
.btn-icon { display: flex; align-items: center; gap: 6px; background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; font-family: inherit; }

/* Main Tabs (Applied vs Potential) */
.main-tabs { display: flex; gap: 6px; background: #fff; border: 1px solid #f1f5f9; border-radius: 12px; padding: 5px; width: fit-content; }
.main-tab { display: flex; align-items: center; gap: 7px; padding: 8px 16px; border-radius: 9px; border: none; background: none; font-size: 13px; font-weight: 600; color: #64748b; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.main-tab:hover { background: #f8fafc; color: #1e293b; }
.main-tab.active { background: #eff8ff; color: #1a5f8a; }
.potential-tab.active { background: #faf5ff; color: #7c3aed; }
.main-count { font-size: 10.5px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }
.potential-count { background: #ede9fe; color: #7c3aed; }

/* Status sub-tabs */
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

/* Notice banner */
.potential-notice { background: #eff8ff; border: 1px solid #bae6fd; border-radius: 10px; padding: 11px 14px; font-size: 12.5px; color: #1a5f8a; display: flex; align-items: flex-start; gap: 8px; }

/* Listing quick-filter tabs */
.listing-tabs { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.listing-tab { display: inline-flex; align-items: center; gap: 6px; font-size: 12px; font-weight: 600; color: #64748b; background: #fff; border: 1.5px solid #e2e8f0; border-radius: 8px; padding: 5px 12px; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.listing-tab:hover { border-color: #94a3b8; color: #1e293b; }
.listing-tab.active { color: #2872A1; border-color: #2872A1; background: #eff8ff; }
.ltab-count { font-size: 10px; font-weight: 700; background: #f1f5f9; color: #64748b; padding: 1px 6px; border-radius: 99px; }

/* Table */
.table-card { background: #fff; border-radius: 14px; overflow: visible; border: 1px solid #f1f5f9; }
.data-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.data-table thead tr { background: #f8fafc; }
.data-table th { text-align: left; padding: 11px 14px; font-size: 11px; font-weight: 700; color: #94a3b8; letter-spacing: 0.04em; text-transform: uppercase; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.table-row { cursor: pointer; transition: background 0.12s; }
.table-row:hover { background: #eff8ff; }
.data-table td { padding: 12px 14px; border-bottom: 1px solid #f8fafc; vertical-align: middle; }
.check { accent-color: #2872A1; cursor: pointer; }
.empty-cell { text-align: center; color: #94a3b8; font-size: 13px; padding: 36px !important; }

/* Cells */
.person-cell { display: flex; align-items: center; gap: 10px; }
.avatar { width: 34px; height: 34px; border-radius: 50%; color: #fff; font-size: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.person-name { font-size: 13px; font-weight: 600; color: #1e293b; }
.person-meta { font-size: 11px; color: #94a3b8; margin-top: 1px; }
.skill-tags { display: flex; align-items: center; gap: 4px; flex-wrap: wrap; }
.skill-tag { background: #f1f5f9; color: #475569; font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
.matched-tag { background: #eff8ff; color: #1a5f8a; border: 1px solid #bae6fd; }
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
.not-applied-badge { display: inline-flex; align-items: center; gap: 6px; background: #fef9ec; color: #92400e; font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 99px; border: 1px solid #fde68a; white-space: nowrap; }
.na-dot { width: 6px; height: 6px; border-radius: 50%; background: #f59e0b; flex-shrink: 0; }
.listing-match-cell { display: flex; align-items: center; gap: 9px; }
.listing-bar { width: 4px; height: 32px; border-radius: 99px; flex-shrink: 0; }
.loc-cell { display: flex; align-items: center; gap: 5px; font-size: 12px; color: #475569; white-space: nowrap; }
.action-btns { display: flex; gap: 4px; }
.act-btn { width: 28px; height: 28px; border-radius: 7px; border: none; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.15s; }
.act-btn.view       { background: #f1f5f9; color: #64748b; }
.act-btn.view:hover { background: #e2e8f0; }
.act-btn.accept       { background: #f0fdf4; color: #22c55e; }
.act-btn.accept:hover { background: #dcfce7; }
.act-btn.reject       { background: #fef2f2; color: #ef4444; }
.act-btn.reject:hover { background: #fee2e2; }
.act-btn.invite-act             { background: #eff8ff; color: #2872A1; }
.act-btn.invite-act:hover:not(:disabled) { background: #2872A1; color: #fff; }
.act-btn.invite-act:disabled    { background: #f0fdf4; color: #22c55e; cursor: default; }

/* Pagination */
.pagination { display: flex; align-items: center; justify-content: space-between; padding: 14px 18px; border-top: 1px solid #f1f5f9; }
.page-info { font-size: 12px; color: #94a3b8; }
.page-btns { display: flex; gap: 4px; }
.page-btn { width: 30px; height: 30px; border-radius: 7px; border: 1px solid #e2e8f0; background: #fff; font-size: 12px; color: #64748b; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; transition: all 0.15s; }
.page-btn:hover:not(:disabled) { border-color: #2872A1; color: #2872A1; }
.page-btn.active { background: #2872A1; color: #fff; border-color: #2872A1; }
.page-btn:disabled { opacity: 0.35; cursor: default; }

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
.btn-blue { background: #2872A1; color: #fff; border: none; border-radius: 10px; padding: 9px 20px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }
.status-options { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.status-option { padding: 10px; border-radius: 10px; border: 2px solid transparent; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; transition: all 0.15s; background: #f8fafc; color: #64748b; }
.status-option.active.reviewing   { background: #eff6ff; color: #3b82f6; border-color: #3b82f6; }
.status-option.active.shortlisted { background: #eff8ff; color: #1a5f8a; border-color: #2872A1; }
.status-option.active.interview   { background: #faf5ff; color: #8b5cf6; border-color: #8b5cf6; }
.status-option.active.hired       { background: #f0fdf4; color: #22c55e; border-color: #22c55e; }
.status-option.active.rejected    { background: #fef2f2; color: #ef4444; border-color: #ef4444; }
.notes-area { width: 100%; border: 1px solid #e2e8f0; border-radius: 10px; padding: 10px 12px; font-size: 13px; color: #1e293b; font-family: inherit; resize: vertical; outline: none; background: #f8fafc; }
.notes-area:focus { border-color: #08BDDE; background: #fff; }
.btn-blue-full { width: 100%; background: #2872A1; color: #fff; border: none; border-radius: 10px; padding: 11px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; }
.btn-blue-full:disabled { background: #22c55e; cursor: default; }

/* PROFILE MODAL */
.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.45); z-index: 200; display: flex; align-items: center; justify-content: center; padding: 24px; }
.modal-box { background: #fff; border-radius: 18px; width: 100%; max-width: 440px; box-shadow: 0 20px 60px rgba(0,0,0,0.18); overflow: hidden; }
.modal-header { display: flex; align-items: flex-start; gap: 14px; padding: 20px 20px 16px; border-bottom: 1px solid #f1f5f9; }
.modal-avatar { width: 46px; height: 46px; border-radius: 50%; color: #fff; font-size: 17px; font-weight: 800; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.modal-info { flex: 1; }
.modal-name { font-size: 16px; font-weight: 800; color: #1e293b; margin-bottom: 2px; }
.modal-edu { font-size: 12px; color: #64748b; margin-bottom: 4px; }
.modal-loc { display: flex; align-items: center; gap: 4px; font-size: 11.5px; color: #94a3b8; }
.modal-close { background: #f8fafc; border: 1px solid #f1f5f9; border-radius: 8px; width: 30px; height: 30px; display: flex; align-items: center; justify-content: center; cursor: pointer; flex-shrink: 0; }
.modal-close:hover { background: #f1f5f9; }
.modal-body { padding: 18px 20px; display: flex; flex-direction: column; gap: 16px; }
.modal-row { display: flex; flex-direction: column; gap: 7px; }
.modal-label { font-size: 10.5px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
.modal-footer { padding: 14px 20px 18px; border-top: 1px solid #f1f5f9; }

/* Transitions */
.drawer-enter-active, .drawer-leave-active { transition: opacity 0.2s; }
.drawer-enter-active .drawer, .drawer-leave-active .drawer { transition: transform 0.25s cubic-bezier(0.4,0,0.2,1); }
.drawer-enter-from, .drawer-leave-to { opacity: 0; }
.drawer-enter-from .drawer, .drawer-leave-to .drawer { transform: translateX(100%); }
</style>