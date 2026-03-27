<template>
  <div class="page">

    <!-- Toast -->
    <transition name="toast">
      <div v-if="toast.show" class="toast" :class="toast.type">
        <span class="toast-icon" v-html="toast.icon"></span>
        <span class="toast-msg">{{ toast.text }}</span>
      </div>
    </transition>

    <!-- SKELETON — initial load -->
    <template v-if="loading && !jobseekers.length">
      <div class="filters-bar" style="margin-bottom: 20px;">
        <div class="skel" style="width: 300px; height: 38px; border-radius: 10px;"></div>
        <div style="display:flex; gap:8px;">
          <div class="skel" style="width: 120px; height: 36px; border-radius: 8px;"></div>
        </div>
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
          <input v-model="search" type="text" placeholder="Search by name or email…" class="search-input"/>
        </div>
        <div class="filter-group">
          <select v-model="filterStatus" class="filter-select">
            <option value="">All Status</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>
      </div>

      <!-- Table -->
      <div class="table-card">

        <!-- PAGE CHANGE SKELETON -->
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
                <th>Jobseeker</th>
                <th>Email</th>
                <th>Contact</th>
                <th>Applications</th>
                <th>Registered</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(js, index) in filteredJobseekers" :key="js.id" class="table-row" @click="viewJobseeker(js)">
                <td @click.stop style="font-weight: 600; color: #64748b; font-size: 12px; padding-left: 18px;">{{ (currentPage - 1) * 15 + index + 1 }}</td>
                <td>
                  <div class="person-cell">
                    <div class="person-avatar" :style="{ background: js.avatarBg }">{{ js.firstName[0] }}{{ js.lastName[0] }}</div>
                    <div>
                      <p class="person-name">{{ js.firstName }} {{ js.lastName }}</p>
                      <p class="person-meta">{{ js.city || '—' }}</p>
                    </div>
                  </div>
                </td>
                <td class="email-cell">{{ js.email }}</td>
                <td class="meta-cell">{{ js.phone || '—' }}</td>
                <td class="meta-cell">
                  <span class="app-count-badge">{{ js.applicationsCount }}</span>
                </td>
                <td class="meta-cell">{{ js.registeredDate }}</td>
                <td @click.stop>
                  <span class="jsstatus-badge" :class="`jsstatus-${js.status}`">
                    <span class="jsstatus-dot"></span>
                    {{ js.status.charAt(0).toUpperCase() + js.status.slice(1) }}
                  </span>
                </td>
                <td @click.stop>
                  <div class="action-btns">
                    <!-- View -->
                    <button class="act-btn view" @click="viewJobseeker(js)" title="View Details">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    </button>
                    <!-- Deactivate (active) -->
                    <button v-if="js.status === 'active'" class="act-btn deactivate" @click.stop="confirmAction('deactivate', js)" :disabled="actionLoadingId === js.id" title="Deactivate">
                      <span v-if="actionLoadingId === js.id && pendingAction === 'deactivate'" class="spinner-btn spinner-red"></span>
                      <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/></svg>
                    </button>
                    <!-- Activate (inactive) -->
                    <button v-else class="act-btn activate" @click.stop="quickActivate(js)" :disabled="actionLoadingId === js.id" title="Activate">
                      <span v-if="actionLoadingId === js.id && pendingAction === 'activate'" class="spinner-btn spinner-green"></span>
                      <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
                    </button>
                    <!-- Archive -->
                    <button class="act-btn archive" @click.stop="confirmAction('archive', js)" :disabled="actionLoadingId === js.id" title="Archive">
                      <span v-if="actionLoadingId === js.id && pendingAction === 'archive'" class="spinner-btn spinner-red"></span>
                      <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="21 8 21 21 3 21 3 8"/><rect x="1" y="3" width="22" height="5"/><line x1="10" y1="12" x2="14" y2="12"/></svg>
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="filteredJobseekers.length === 0">
                <td colspan="8" class="empty-cell">
                  <div class="empty-state">
                    <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.5"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
                    <p>No jobseekers found</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </template>

        <!-- Pagination -->
        <div class="pagination">
          <span class="page-info">Showing {{ (currentPage - 1) * 15 + 1 }}–{{ Math.min(currentPage * 15, totalJobseekers) }} of {{ totalJobseekers }} jobseekers</span>
          <div class="page-btns">
            <button class="page-btn" :disabled="currentPage === 1 || pageLoading" @click="changePage(currentPage - 1)">‹</button>
            <button v-for="p in paginationPages" :key="p" class="page-btn" :class="{ active: currentPage === p }" :disabled="pageLoading" @click="changePage(p)">{{ p }}</button>
            <button class="page-btn" :disabled="currentPage === lastPage || pageLoading" @click="changePage(currentPage + 1)">›</button>
          </div>
        </div>

      </div>

      <!-- JOBSEEKER DETAIL MODAL -->
      <transition name="modal">
        <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
          <div class="modal modal-wide">
            <div class="modal-header">
              <div class="modal-title-wrap">
                <div class="modal-avatar" :style="{ background: selectedJobseeker?.avatarBg }">
                  {{ selectedJobseeker?.firstName[0] }}{{ selectedJobseeker?.lastName[0] }}
                </div>
                <div>
                  <h3 class="modal-title">{{ selectedJobseeker?.firstName }} {{ selectedJobseeker?.lastName }}</h3>
                  <p class="modal-sub">Jobseeker Profile</p>
                </div>
              </div>
              <div style="display:flex;align-items:center;gap:10px">
                <span class="jsstatus-badge" :class="`jsstatus-${selectedJobseeker?.status}`">
                  <span class="jsstatus-dot"></span>
                  {{ selectedJobseeker?.status ? selectedJobseeker.status.charAt(0).toUpperCase() + selectedJobseeker.status.slice(1) : '' }}
                </span>
                <button class="modal-close" @click="showModal = false">✕</button>
              </div>
            </div>

            <div class="modal-body" v-if="selectedJobseeker">
              <div class="detail-grid">
                <div class="detail-section">
                  <p class="detail-section-title">Personal Information</p>
                  <div class="detail-rows">
                    <div class="detail-row"><span class="detail-key">Full Name</span><span class="detail-val">{{ selectedJobseeker.firstName }} {{ selectedJobseeker.lastName }}</span></div>
                    <div class="detail-row"><span class="detail-key">Email</span><span class="detail-val">{{ selectedJobseeker.email }}</span></div>
                    <div class="detail-row"><span class="detail-key">Contact</span><span class="detail-val">{{ selectedJobseeker.phone || '—' }}</span></div>
                    <div class="detail-row"><span class="detail-key">City</span><span class="detail-val">{{ selectedJobseeker.city || '—' }}</span></div>
                    <div class="detail-row"><span class="detail-key">Address</span><span class="detail-val">{{ selectedJobseeker.address || '—' }}</span></div>
                    <div class="detail-row"><span class="detail-key">Registered</span><span class="detail-val">{{ selectedJobseeker.registeredDate }}</span></div>
                  </div>
                </div>
                <div class="detail-section">
                  <p class="detail-section-title">Professional Background</p>
                  <div class="detail-rows">
                    <div class="detail-row"><span class="detail-key">Education Level</span><span class="detail-val">{{ selectedJobseeker.educationLevel || '—' }}</span></div>
                    <div class="detail-row"><span class="detail-key">Experience</span><span class="detail-val" style="white-space: normal;">{{ selectedJobseeker.jobExperience || '—' }}</span></div>
                    <div class="detail-row"><span class="detail-key">Applications</span><span class="detail-val">{{ selectedJobseeker.applicationsCount }} total</span></div>
                    <div class="detail-row">
                      <span class="detail-key">Resume</span>
                      <span class="detail-val">
                        <button v-if="selectedJobseeker?.hasResume" type="button" class="resume-view-btn" :disabled="openingResume" @click.stop="viewJobseekerResume(selectedJobseeker)">
                          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                          {{ openingResume ? 'Opening…' : 'View Resume' }}
                        </button>
                        <span v-else style="color:#94a3b8">Not uploaded</span>
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              <div class="detail-section" style="margin-top:4px">
                <p class="detail-section-title">Skills</p>
                <div v-if="selectedJobseeker.skills.length" class="skill-tags mt8">
                  <span v-for="sk in selectedJobseeker.skills" :key="sk" class="skill-tag-lg">{{ sk }}</span>
                </div>
                <p v-else class="no-data-msg">No skills listed yet.</p>
              </div>

              <div class="detail-section" style="margin-top:4px" v-if="selectedJobseeker.applications?.length">
                <p class="detail-section-title">Recent Applications</p>
                <div class="apps-list">
                  <div v-for="app in selectedJobseeker.applications.slice(0, 5)" :key="app.id" class="app-row">
                    <div class="app-info">
                      <p class="app-title">{{ app.jobTitle || 'Unknown Position' }}</p>
                      <p class="app-company">{{ app.company || '—' }}</p>
                    </div>
                    <span class="app-status-badge" :class="appStatusClass(app.status)">{{ app.status }}</span>
                  </div>
                </div>
              </div>

              <div class="status-control-row" v-if="selectedJobseeker.status === 'inactive'">
                <div class="status-control-info">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#d97706" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                  This account is currently inactive.
                </div>
              </div>
            </div>

            <div class="modal-footer">
              <button class="btn-ghost" @click="showModal = false" :disabled="actionLoading">Close</button>
              <template v-if="selectedJobseeker?.status === 'active'">
                <button class="btn-deact" @click="updateStatus('inactive')" :disabled="actionLoading">
                  <span v-if="actionLoading" class="spinner-sm spinner-orange"></span>
                  <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/></svg>
                  Deactivate
                </button>
              </template>
              <template v-else-if="selectedJobseeker?.status === 'inactive'">
                <button class="btn-activate" @click="updateStatus('active')" :disabled="actionLoading">
                  <span v-if="actionLoading" class="spinner-sm"></span>
                  <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  Activate Account
                </button>
              </template>
            </div>
          </div>
        </div>
      </transition>
    </template>

    <!-- ── CONFIRM MODAL ── -->
    <transition name="modal">
      <div v-if="showConfirm" class="modal-overlay" @click.self="showConfirm = false">
        <div class="modal confirm-modal">
          <div class="confirm-icon-wrap" :class="confirmConfig.iconBg">
            <svg v-if="confirmConfig.icon === 'deactivate'" width="26" height="26" viewBox="0 0 24 24" fill="none" :stroke="confirmConfig.iconColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/></svg>
            <svg v-else-if="confirmConfig.icon === 'archive'" width="26" height="26" viewBox="0 0 24 24" fill="none" :stroke="confirmConfig.iconColor" stroke-width="2"><polyline points="21 8 21 21 3 21 3 8"/><rect x="1" y="3" width="22" height="5"/><line x1="10" y1="12" x2="14" y2="12"/></svg>
          </div>
          <div class="confirm-text">
            <h3 class="confirm-title">{{ confirmConfig.title }}</h3>
            <p class="confirm-msg">{{ confirmConfig.message }}</p>
          </div>
          <div class="confirm-actions">
            <button class="btn-ghost" @click="showConfirm = false" :disabled="confirmLoading">Cancel</button>
            <button class="btn-confirm-danger" @click="executeConfirm" :disabled="confirmLoading">
              <span v-if="confirmLoading" class="spinner-sm"></span>
              <span v-else>{{ confirmConfig.btnLabel }}</span>
            </button>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
import api from '@/services/api'

const CHECK_SVG = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>`
const X_SVG     = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`
const AVATAR_COLORS = ['#2563eb', '#22c55e', '#f97316', '#ef4444', '#8b5cf6', '#06b6d4', '#14b8a6', '#f59e0b']

export default {
  name: 'JobseekersPage',
  async mounted() {
    await this.fetchJobseekers()
  },
  data() {
    return {
      search: '',
      filterStatus: '',
      showModal: false,
      showConfirm: false,
      selectedJobseeker: null,
      loading: false,
      pageLoading: false,
      actionLoading: false,
      actionLoadingId: null,
      pendingAction: null,
      confirmLoading: false,
      confirmTarget: null,
      confirmConfig: {},
      openingResume: false,
      toast: { show: false, text: '', type: 'success', icon: CHECK_SVG, _timer: null },
      jobseekers: [],
      currentPage: 1,
      lastPage: 1,
      totalJobseekers: 0,
    }
  },
  computed: {
    filteredJobseekers() {
      const q = this.search.toLowerCase()
      return this.jobseekers.filter(js => {
        const matchSearch = !q ||
          `${js.firstName} ${js.lastName}`.toLowerCase().includes(q) ||
          js.email.toLowerCase().includes(q)
        const matchStatus = !this.filterStatus || js.status === this.filterStatus
        return matchSearch && matchStatus
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
    async fetchJobseekers(isPaginating = false) {
      if (isPaginating) { this.pageLoading = true } else { this.loading = true }
      try {
        const params = { page: this.currentPage, per_page: 15 }
        if (this.search)       params.search = this.search
        if (this.filterStatus) params.status = this.filterStatus

        const { data } = await api.get('/admin/jobseekers', { params })
        const list = data.data?.data || data.data || []
        this.currentPage     = data.data?.current_page || 1
        this.lastPage        = data.data?.last_page    || 1
        this.totalJobseekers = data.data?.total        || list.length

        this.jobseekers = (Array.isArray(list) ? list : []).map((js, i) => ({
          id:               js.id,
          firstName:        js.first_name        || 'Unknown',
          lastName:         js.last_name         || '',
          email:            js.email             || '—',
          phone:            js.contact           || js.phone || '',
          city:             js.city              || '',
          address:          js.address           || '',
          educationLevel:   js.education_level   || '',
          jobExperience:    js.job_experience    || null,
          skills:           js.skills?.map(s => s.skill || s) || [],
          applicationsCount: js.applications_count || 0,
          hasResume:        !!js.resume_path,
          status:           js.status            || 'active',
          registeredDate:   js.created_at ? new Date(js.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : '—',
          avatarBg:         AVATAR_COLORS[i % AVATAR_COLORS.length],
          applications:     (js.applications || []).map(a => ({
            id:       a.id,
            jobTitle: a.job_listing?.title                  || '',
            company:  a.job_listing?.employer?.company_name || '',
            status:   a.status ? a.status.charAt(0).toUpperCase() + a.status.slice(1) : 'Reviewing',
          })),
        }))
      } catch (e) {
        console.error(e)
        this.showToastMsg('Failed to load jobseekers', 'error')
      } finally {
        this.loading     = false
        this.pageLoading = false
      }
    },

    viewJobseeker(js) {
      this.selectedJobseeker = { ...js }
      this.showModal = true
    },

    /** Open confirmation modal instead of window.confirm */
    confirmAction(type, target) {
      this.confirmTarget = target
      if (type === 'deactivate') {
        this.confirmConfig = {
          icon: 'deactivate',
          iconBg: 'icon-bg-red',
          iconColor: '#ef4444',
          title: 'Deactivate Account?',
          message: `${target.firstName} ${target.lastName}'s account will be deactivated. They won't be able to log in or apply for jobs until reactivated.`,
          btnLabel: 'Deactivate',
          action: 'deactivate',
        }
      } else if (type === 'archive') {
        this.confirmConfig = {
          icon: 'archive',
          iconBg: 'icon-bg-red',
          iconColor: '#ef4444',
          title: 'Archive Jobseeker?',
          message: `${target.firstName} ${target.lastName} will be archived and removed from the active list. You can restore them from the Archive page.`,
          btnLabel: 'Archive',
          action: 'archive',
        }
      }
      this.showConfirm = true
    },

    async executeConfirm() {
      this.confirmLoading = true
      const target = this.confirmTarget
      const action = this.confirmConfig.action
      try {
        if (action === 'deactivate') {
          await api.patch(`/admin/jobseekers/${target.id}/status`, { status: 'inactive' })
          const idx = this.jobseekers.findIndex(j => j.id === target.id)
          if (idx !== -1) this.jobseekers[idx].status = 'inactive'
          this.showToastMsg(`${target.firstName} ${target.lastName} deactivated`, 'success')
        } else if (action === 'archive') {
          await api.delete(`/admin/jobseekers/${target.id}`)
          this.jobseekers = this.jobseekers.filter(j => j.id !== target.id)
          this.showToastMsg(`${target.firstName} ${target.lastName} archived`, 'success')
        }
      } catch (e) {
        console.error(e)
        this.showToastMsg('Action failed. Please try again.', 'error')
      } finally {
        this.confirmLoading = false
        this.showConfirm = false
        this.confirmTarget = null
      }
    },

    async quickActivate(js) {
      if (this.actionLoadingId) return
      this.actionLoadingId = js.id
      this.pendingAction = 'activate'
      try {
        await api.patch(`/admin/jobseekers/${js.id}/status`, { status: 'active' })
        const idx = this.jobseekers.findIndex(j => j.id === js.id)
        if (idx !== -1) this.jobseekers[idx].status = 'active'
        this.showToastMsg(`${js.firstName} ${js.lastName} activated`, 'success')
      } catch (e) {
        console.error(e)
        this.showToastMsg('Failed to activate', 'error')
      } finally {
        this.actionLoadingId = null
        this.pendingAction = null
      }
    },

    async viewJobseekerResume(js) {
      if (!js?.id || !js?.hasResume) return
      this.openingResume = true
      try {
        const res = await api.get(`/admin/jobseekers/${js.id}/documents/resume`, { responseType: 'blob' })
        const blob = new Blob([res.data], { type: 'application/pdf' })
        const url = URL.createObjectURL(blob)
        const win = window.open(url, '_blank', 'noopener,noreferrer')
        if (!win) alert('Pop-up blocked. Allow pop-ups to view the PDF.')
        setTimeout(() => URL.revokeObjectURL(url), 120000)
      } catch (e) {
        console.error(e)
        this.showToastMsg('Could not open resume.', 'error')
      } finally {
        this.openingResume = false
      }
    },

    async updateStatus(status) {
      if (this.actionLoading) return
      this.actionLoading = true
      try {
        await api.patch(`/admin/jobseekers/${this.selectedJobseeker.id}/status`, { status })
        const idx = this.jobseekers.findIndex(j => j.id === this.selectedJobseeker.id)
        if (idx !== -1) this.jobseekers[idx].status = status
        this.selectedJobseeker = { ...this.selectedJobseeker, status }
        this.showToastMsg(`Jobseeker ${status === 'active' ? 'activated' : 'deactivated'}`, 'success')
        this.showModal = false
      } catch (e) {
        console.error(e)
        this.showToastMsg('Failed to update status', 'error')
      } finally {
        this.actionLoading = false
      }
    },

    changePage(page) {
      if (page >= 1 && page <= this.lastPage && !this.pageLoading) {
        this.currentPage = page
        this.fetchJobseekers(true)
      }
    },

    appStatusClass(s) {
      const map = { Reviewing: 'app-reviewing', Shortlisted: 'app-shortlisted', Interview: 'app-interview', Hired: 'app-hired', Rejected: 'app-rejected' }
      return map[s] || ''
    },

    showToastMsg(text, type = 'success') {
      if (this.toast._timer) clearTimeout(this.toast._timer)
      this.toast = { show: true, text, type, icon: type === 'success' ? CHECK_SVG : X_SVG, _timer: setTimeout(() => { this.toast.show = false }, 3500) }
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

@keyframes shimmer { 0% { background-position: -400px 0; } 100% { background-position: 400px 0; } }
@keyframes spin { to { transform: rotate(360deg); } }

.skel { background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%); background-size: 400px 100%; animation: shimmer 1.4s infinite linear; border-radius: 6px; flex-shrink: 0; }

.page { font-family: 'Plus Jakarta Sans', sans-serif; padding: 24px; background: #f8fafc; min-height: 100vh; display: flex; flex-direction: column; gap: 16px; }
.filters-bar { display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; flex: 1; max-width: 360px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-group { display: flex; gap: 8px; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }

.table-card { background: #fff; border-radius: 14px; overflow: hidden; border: 1px solid #f1f5f9; }
.data-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.data-table thead tr { background: #f8fafc; }
.data-table thead { position: sticky; top: 0; z-index: 1; }
.data-table th { text-align: left; padding: 11px 14px; font-size: 11px; font-weight: 700; color: #94a3b8; letter-spacing: 0.04em; text-transform: uppercase; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.table-row { cursor: pointer; transition: background 0.12s; }
.table-row:hover { background: #f8fafc; }
.data-table td { padding: 12px 14px; border-bottom: 1px solid #f8fafc; vertical-align: middle; }

.person-cell { display: flex; align-items: center; gap: 10px; }
.person-avatar { width: 34px; height: 34px; border-radius: 50%; color: #fff; font-size: 11px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.person-name { font-size: 13px; font-weight: 700; color: #1e293b; }
.person-meta { font-size: 11px; color: #94a3b8; margin-top: 1px; }
.email-cell { font-size: 12px; color: #475569; }
.meta-cell  { font-size: 12.5px; color: #475569; }
.app-count-badge { background: #f1f5f9; color: #475569; font-size: 12px; font-weight: 700; padding: 2px 9px; border-radius: 99px; }

.jsstatus-badge { display: inline-flex; align-items: center; gap: 5px; padding: 4px 10px; border-radius: 99px; font-size: 11px; font-weight: 700; white-space: nowrap; }
.jsstatus-dot { width: 6px; height: 6px; border-radius: 50%; flex-shrink: 0; }
.jsstatus-active   { background: #dcfce7; color: #16a34a; }
.jsstatus-active   .jsstatus-dot { background: #22c55e; }
.jsstatus-inactive { background: #fef2f2; color: #dc2626; }
.jsstatus-inactive .jsstatus-dot { background: #ef4444; }

/* ── ACTION BUTTONS ── */
.action-btns { display: flex; gap: 4px; }
.act-btn {
  width: 28px; height: 28px; border-radius: 7px; border: none;
  display: flex; align-items: center; justify-content: center;
  cursor: pointer; transition: all 0.15s; flex-shrink: 0;
}
.act-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.act-btn.view         { background: #f1f5f9; color: #64748b; }
.act-btn.view:hover   { background: #e2e8f0; color: #1e293b; }
.act-btn.activate         { background: #dcfce7; color: #16a34a; }
.act-btn.activate:hover   { background: #bbf7d0; }
.act-btn.deactivate       { background: #fef2f2; color: #ef4444; }
.act-btn.deactivate:hover { background: #fee2e2; }
.act-btn.archive       { background: #fef2f2; color: #ef4444; }
.act-btn.archive:hover { background: #fee2e2; }

/* ── SPINNERS ── */
.spinner-btn {
  width: 11px; height: 11px;
  border: 1.5px solid rgba(0,0,0,0.12); border-top-color: currentColor;
  border-radius: 50%; animation: spin 0.65s linear infinite; display: inline-block;
}
.spinner-red   { color: #ef4444; }
.spinner-green { color: #16a34a; }
.spinner-sm {
  width: 14px; height: 14px; flex-shrink: 0;
  border: 2px solid rgba(255,255,255,0.35); border-top-color: #fff;
  border-radius: 50%; animation: spin 0.65s linear infinite; display: inline-block;
}
.spinner-orange { border: 2px solid rgba(249,115,22,0.3); border-top-color: #f97316; }

/* ── CONFIRM MODAL ── */
.confirm-modal {
  width: 360px !important;
  padding: 0 !important;
  border-radius: 18px !important;
  overflow: hidden;
  display: flex !important;
  flex-direction: column;
}
.confirm-icon-wrap {
  display: flex; align-items: center; justify-content: center;
  padding: 28px 0 20px;
}
.icon-bg-red    { background: #fef2f2; }
.icon-bg-orange { background: #fff7ed; }
.confirm-text { padding: 0 28px 20px; text-align: center; }
.confirm-title { font-size: 16px; font-weight: 800; color: #1e293b; margin-bottom: 8px; }
.confirm-msg   { font-size: 13px; color: #64748b; line-height: 1.6; }
.confirm-actions {
  display: flex; gap: 10px;
  padding: 16px 24px 24px;
  border-top: 1px solid #f1f5f9;
  justify-content: flex-end;
}
.btn-confirm-danger {
  display: flex; align-items: center; justify-content: center; gap: 6px;
  min-width: 100px; padding: 9px 20px;
  background: #ef4444; color: #fff;
  border: none; border-radius: 10px;
  font-size: 13px; font-weight: 700;
  cursor: pointer; font-family: inherit; transition: background 0.15s;
}
.btn-confirm-danger:hover:not(:disabled) { background: #dc2626; }
.btn-confirm-danger:disabled { opacity: 0.7; cursor: not-allowed; }

.empty-cell { padding: 40px !important; }
.empty-state { display: flex; flex-direction: column; align-items: center; gap: 10px; color: #cbd5e1; font-size: 13px; }

.pagination { display: flex; align-items: center; justify-content: space-between; padding: 14px 18px; border-top: 1px solid #f1f5f9; }
.page-info { font-size: 12px; color: #94a3b8; }
.page-btns { display: flex; gap: 4px; }
.page-btn { width: 30px; height: 30px; border-radius: 7px; border: 1px solid #e2e8f0; background: #fff; font-size: 12px; color: #64748b; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; transition: all 0.15s; }
.page-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.page-btn.active { background: #2563eb; color: #fff; border-color: #2563eb; }
.page-btn:hover:not(.active):not(:disabled) { background: #f8fafc; }

.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.4); z-index: 100; display: flex; align-items: center; justify-content: center; backdrop-filter: blur(2px); }
.modal { background: #fff; border-radius: 16px; width: 580px; max-width: 95vw; box-shadow: 0 20px 60px rgba(0,0,0,0.15); max-height: 90vh; display: flex; flex-direction: column; }
.modal-wide { width: 680px; }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 20px 24px; border-bottom: 1px solid #f1f5f9; flex-shrink: 0; }
.modal-title-wrap { display: flex; align-items: center; gap: 12px; }
.modal-avatar { width: 44px; height: 44px; border-radius: 50%; color: #fff; font-size: 14px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.modal-title { font-size: 16px; font-weight: 800; color: #1e293b; }
.modal-sub { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.modal-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 18px; padding: 4px; border-radius: 6px; line-height: 1; }
.modal-close:hover { background: #f1f5f9; color: #1e293b; }
.modal-body { padding: 20px 24px; display: flex; flex-direction: column; gap: 16px; overflow-y: auto; flex: 1; }
.modal-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 16px 24px; border-top: 1px solid #f1f5f9; flex-shrink: 0; }

.detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.detail-section { display: flex; flex-direction: column; gap: 10px; }
.detail-section-title { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.08em; padding-bottom: 6px; border-bottom: 1px solid #f1f5f9; }
.detail-rows { display: flex; flex-direction: column; gap: 8px; }
.detail-row { display: flex; flex-direction: column; gap: 2px; }
.detail-key { font-size: 10.5px; color: #94a3b8; font-weight: 600; }
.detail-val { font-size: 13px; color: #1e293b; font-weight: 500; }

.skill-tags.mt8 { margin-top: 4px; display: flex; flex-wrap: wrap; gap: 6px; }
.skill-tag-lg { background: #eff6ff; color: #2563eb; font-size: 12px; font-weight: 600; padding: 4px 12px; border-radius: 6px; white-space: nowrap; }
.no-data-msg { font-size: 12.5px; color: #cbd5e1; }

.resume-view-btn { background: #2563eb; color: #fff; border: none; border-radius: 10px; padding: 8px 14px; font-size: 12.5px; font-weight: 800; cursor: pointer; font-family: inherit; display: inline-flex; align-items: center; justify-content: center; gap: 8px; transition: background 0.15s, box-shadow 0.15s; box-shadow: 0 4px 14px rgba(37,99,235,0.2); }
.resume-view-btn:hover:not(:disabled) { background: #1d4ed8; }
.resume-view-btn:disabled { background: #93c5fd; cursor: not-allowed; opacity: 0.7; }

.apps-list { display: flex; flex-direction: column; gap: 7px; }
.app-row { display: flex; align-items: center; justify-content: space-between; padding: 8px 12px; background: #f8fafc; border-radius: 9px; border: 1px solid #f1f5f9; }
.app-info { flex: 1; min-width: 0; }
.app-title { font-size: 12.5px; font-weight: 600; color: #1e293b; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.app-company { font-size: 11px; color: #94a3b8; margin-top: 1px; }
.app-status-badge { font-size: 10.5px; font-weight: 700; padding: 3px 9px; border-radius: 99px; white-space: nowrap; flex-shrink: 0; margin-left: 8px; }
.app-reviewing   { background: #dbeafe; color: #1d4ed8; }
.app-shortlisted { background: #1A5F18; color: #a7f3a0; }
.app-interview   { background: #ede9fe; color: #8B5CF6; }
.app-hired       { background: #dcfce7; color: #16a34a; }
.app-rejected    { background: #fef2f2; color: #ef4444; }

.status-control-row { background: #fffbeb; border: 1px solid #fde68a; border-radius: 10px; padding: 11px 14px; display: flex; align-items: center; gap: 8px; font-size: 12.5px; color: #92400e; font-weight: 500; }
.status-control-info { display: flex; align-items: center; gap: 8px; }

.btn-ghost { background: #f1f5f9; color: #64748b; border: none; border-radius: 10px; padding: 9px 18px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-ghost:hover:not(:disabled) { background: #e2e8f0; }
.btn-ghost:disabled { opacity: 0.7; cursor: not-allowed; }
.btn-activate { display: flex; align-items: center; justify-content: center; gap: 6px; background: #22c55e; color: #fff; border: none; border-radius: 10px; padding: 9px 18px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; min-width: 140px; }
.btn-activate:hover:not(:disabled) { background: #16a34a; }
.btn-activate:disabled { opacity: 0.7; cursor: not-allowed; }
.btn-deact { display: flex; align-items: center; justify-content: center; gap: 6px; background: #fff7ed; color: #f97316; border: 1.5px solid #fed7aa; border-radius: 10px; padding: 9px 18px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; min-width: 140px; }
.btn-deact:hover:not(:disabled) { background: #ffedd5; }
.btn-deact:disabled { opacity: 0.7; cursor: not-allowed; }

.toast { position: fixed; top: 20px; right: 24px; z-index: 9999; display: flex; align-items: center; gap: 10px; padding: 12px 18px; border-radius: 12px; font-size: 13px; font-weight: 600; box-shadow: 0 8px 30px rgba(0,0,0,0.12); min-width: 240px; max-width: 380px; }
.toast.success { background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; }
.toast.error   { background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; }
.toast-icon { display: flex; align-items: center; flex-shrink: 0; }
.toast-msg { word-break: break-word; line-height: 1.4; }
.toast-enter-active, .toast-leave-active { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
.toast-enter-from, .toast-leave-to { opacity: 0; transform: translateY(-15px) scale(0.95); }

.modal-enter-active, .modal-leave-active { transition: opacity 0.2s; }
.modal-enter-active .modal, .modal-leave-active .modal { transition: transform 0.2s, opacity 0.2s; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
.modal-enter-from .modal, .modal-leave-to .modal { transform: scale(0.95); opacity: 0; }
</style>