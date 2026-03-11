<template>
  <div class="layout-wrapper">
    <EmployerSidebar />
    <div class="main-area">
      <EmployerTopbar title="Job Listings" subtitle="Create and manage your open positions" />
      <div class="page">

        <!-- Stats Strip -->
        <div class="stats-strip">
          <div v-for="s in stripStats" :key="s.label" class="strip-stat">
            <span class="strip-val" :style="{ color: s.color }">{{ s.value }}</span>
            <span class="strip-label">{{ s.label }}</span>
          </div>
        </div>

        <!-- Filters + Add -->
        <div class="filters-bar">
          <div class="search-box">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            <input v-model="search" type="text" placeholder="Search by job title, type…" class="search-input"/>
          </div>
          <div class="filter-group">
            <select v-model="filterStatus" class="filter-select">
              <option value="">All Status</option>
              <option value="Open">Open</option>
              <option value="Closed">Closed</option>
              <option value="Draft">Draft</option>
            </select>
            <select v-model="filterType" class="filter-select">
              <option value="">All Types</option>
              <option value="Full-time">Full-time</option>
              <option value="Part-time">Part-time</option>
              <option value="Contract">Contract</option>
              <option value="Internship">Internship</option>
            </select>
            <button class="btn-amber" @click="openModal(null)">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
              Post a Job
            </button>
          </div>
        </div>

        <!-- Jobs Grid -->
        <div class="jobs-grid">
          <div v-for="job in filteredJobs" :key="job.id" class="job-card">
            <div class="job-card-header">
              <div class="job-icon-lg" :style="{ background: job.bg }">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" :stroke="job.color" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
              </div>
              <div class="job-status-wrap">
                <span class="job-status" :class="jobStatusClass(job.status)">{{ job.status }}</span>
              </div>
            </div>
            <h3 class="job-card-title">{{ job.title }}</h3>
            <div class="job-tags">
              <span class="job-tag type-tag">{{ job.type }}</span>
              <span class="job-tag">{{ job.location }}</span>
            </div>
            <p class="job-salary">{{ job.salary }}</p>
            <p class="job-desc">{{ job.description }}</p>
            <div class="job-skills">
              <span v-for="sk in job.skills.slice(0,3)" :key="sk" class="skill-chip">{{ sk }}</span>
              <span v-if="job.skills.length > 3" class="skill-more">+{{ job.skills.length - 3 }}</span>
            </div>

            <!-- Applicants Progress -->
            <div class="applicant-progress">
              <div class="progress-labels">
                <span class="prog-label">{{ job.applicants }} applicants</span>
                <span class="prog-label">{{ job.slots }} slots</span>
              </div>
              <div class="prog-bar-bg">
                <div class="prog-bar-fill" :style="{ width: Math.min(job.applicants/job.slots*100,100)+'%', background: job.color }"></div>
              </div>
            </div>

            <div class="job-card-footer">
              <span class="post-date">Posted {{ job.postedDate }}</span>
              <span class="deadline-badge" :class="{ urgent: job.daysLeft <= 3 }">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                {{ job.daysLeft }}d left
              </span>
            </div>

            <div class="job-card-actions">
              <button class="card-btn view-btn" @click="openDrawer(job)">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                View
              </button>
              <button class="card-btn edit-btn" @click="openModal(job)">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                Edit
              </button>
              <button class="card-btn close-btn" v-if="job.status === 'Open'">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                Close
              </button>
            </div>
          </div>
        </div>

      </div>
    </div>

    <!-- JOB DRAWER -->
    <transition name="drawer">
      <div v-if="drawerOpen" class="drawer-overlay" @click.self="drawerOpen = false">
        <div class="drawer">
          <div class="drawer-header">
            <div class="drawer-icon" :style="{ background: selected?.bg }">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" :stroke="selected?.color" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
            </div>
            <div class="drawer-title-wrap">
              <h2 class="drawer-name">{{ selected?.title }}</h2>
              <p class="drawer-loc">{{ selected?.type }} · {{ selected?.location }}</p>
            </div>
            <span class="job-status" :class="jobStatusClass(selected?.status)">{{ selected?.status }}</span>
            <button class="drawer-close" @click="drawerOpen = false">✕</button>
          </div>
          <div class="drawer-body">
            <div class="info-grid">
              <div class="info-item"><span class="info-label">Salary</span><span class="info-val">{{ selected?.salary }}</span></div>
              <div class="info-item"><span class="info-label">Slots</span><span class="info-val">{{ selected?.slots }} positions</span></div>
              <div class="info-item"><span class="info-label">Posted</span><span class="info-val">{{ selected?.postedDate }}</span></div>
              <div class="info-item"><span class="info-label">Deadline</span><span class="info-val">{{ selected?.daysLeft }} days left</span></div>
              <div class="info-item"><span class="info-label">Applicants</span><span class="info-val">{{ selected?.applicants }}</span></div>
              <div class="info-item"><span class="info-label">Hired</span><span class="info-val">{{ selected?.hired }}</span></div>
            </div>
            <div class="section-label">Description</div>
            <p class="desc-text">{{ selected?.description }}</p>
            <div class="section-label">Required Skills</div>
            <div class="skill-tags mt4">
              <span v-for="sk in selected?.skills" :key="sk" class="skill-chip">{{ sk }}</span>
            </div>
          </div>
        </div>
      </div>
    </transition>

    <!-- POST / EDIT MODAL -->
    <transition name="modal">
      <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
        <div class="modal">
          <div class="modal-header">
            <div class="modal-icon-wrap">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
            </div>
            <div>
              <h3 class="modal-title">{{ editingJob ? 'Edit Job Listing' : 'Post a New Job' }}</h3>
              <p class="modal-sub">{{ editingJob ? 'Update the details of this position' : 'Fill in the details to post a new opening' }}</p>
            </div>
            <button class="modal-close" @click="showModal = false">✕</button>
          </div>
          <div class="modal-body">
            <div class="form-row two">
              <div class="form-group">
                <label class="form-label">Job Title <span class="req">*</span></label>
                <input v-model="form.title" class="form-input" placeholder="e.g. Frontend Developer"/>
              </div>
              <div class="form-group">
                <label class="form-label">Employment Type <span class="req">*</span></label>
                <select v-model="form.type" class="form-input">
                  <option value="">Select type</option>
                  <option>Full-time</option>
                  <option>Part-time</option>
                  <option>Contract</option>
                  <option>Internship</option>
                </select>
              </div>
            </div>
            <div class="form-row two">
              <div class="form-group">
                <label class="form-label">Salary Range</label>
                <input v-model="form.salary" class="form-input" placeholder="e.g. ₱25,000 – ₱35,000/mo"/>
              </div>
              <div class="form-group">
                <label class="form-label">Number of Slots <span class="req">*</span></label>
                <input v-model="form.slots" type="number" class="form-input" placeholder="e.g. 5"/>
              </div>
            </div>
            <div class="form-row two">
              <div class="form-group">
                <label class="form-label">Location</label>
                <input v-model="form.location" class="form-input" placeholder="e.g. Quezon City / Remote"/>
              </div>
              <div class="form-group">
                <label class="form-label">Deadline (Days)</label>
                <input v-model="form.daysLeft" type="number" class="form-input" placeholder="e.g. 30"/>
              </div>
            </div>
            <div class="form-group">
              <label class="form-label">Job Description <span class="req">*</span></label>
              <textarea v-model="form.description" class="form-input textarea" rows="3" placeholder="Describe the role, responsibilities, and requirements…"></textarea>
            </div>
            <div class="form-row two">
              <div class="form-group">
                <label class="form-label">Status <span class="req">*</span></label>
                <select v-model="form.status" class="form-input">
                  <option value="Open">Open</option>
                  <option value="Draft">Draft</option>
                  <option value="Closed">Closed</option>
                </select>
              </div>
              <div class="form-group" style="justify-content: flex-end; padding-top: 18px;">
                <p style="font-size:11px; color:#94a3b8; line-height:1.5;">
                  <strong>Open</strong> — visible to jobseekers<br>
                  <strong>Draft</strong> — saved, not yet published<br>
                  <strong>Closed</strong> — no longer accepting applications
                </p>
              </div>
            </div>
            <div class="form-group">
              <label class="form-label">Required Skills <span class="req">*</span></label>
              <input v-model="form.skillsRaw" class="form-input" placeholder="e.g. Vue.js, Laravel, MySQL (comma-separated)"/>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn-ghost" @click="showModal = false">Cancel</button>
            <button class="btn-amber" @click="saveJob">{{ editingJob ? 'Save Changes' : 'Post Job' }}</button>
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
  name: 'EmployerJobListings',
  components: { EmployerSidebar, EmployerTopbar },
  async mounted() {
    await this.fetchJobs()
  },
  data() {
    return {
      search: '', filterStatus: '', filterType: '',
      drawerOpen: false, selected: null,
      showModal: false, editingJob: null,
      form: { title:'', type:'', salary:'', slots:'', location:'', daysLeft:'', description:'', skillsRaw:'', status:'Open' },
      jobs: [
        { id:1, title:'Frontend Developer',  type:'Full-time',  location:'Quezon City',  salary:'₱30,000–₱45,000/mo', slots:5,  applicants:38, hired:2, status:'Open',   daysLeft:12, postedDate:'Dec 01', description:'Looking for an experienced frontend developer skilled in Vue.js to join our growing product team. You will build and maintain user-facing features.', skills:['Vue.js','JavaScript','CSS','Tailwind'], bg:'#eff6ff', color:'#2563eb' },
        { id:2, title:'Backend Developer',   type:'Full-time',  location:'Remote',       salary:'₱35,000–₱50,000/mo', slots:4,  applicants:29, hired:1, status:'Open',   daysLeft:18, postedDate:'Dec 02', description:'Experienced Laravel developer to build and maintain our REST APIs, optimize database performance, and collaborate with frontend teams.', skills:['Laravel','PHP','MySQL','REST API'], bg:'#faf5ff', color:'#8b5cf6' },
        { id:3, title:'UI/UX Designer',      type:'Full-time',  location:'Hybrid',       salary:'₱25,000–₱40,000/mo', slots:3,  applicants:22, hired:0, status:'Open',   daysLeft:7,  postedDate:'Dec 03', description:'We need a creative UI/UX designer who can translate business requirements into beautiful, user-friendly interfaces.', skills:['Figma','Adobe XD','UI/UX','Prototyping'], bg:'#fdf4ff', color:'#d946ef' },
        { id:4, title:'DevOps Engineer',     type:'Contract',   location:'Remote',       salary:'₱50,000–₱70,000/mo', slots:2,  applicants:14, hired:1, status:'Open',   daysLeft:25, postedDate:'Nov 28', description:'Manage our cloud infrastructure, CI/CD pipelines, and ensure high availability of our production systems.', skills:['AWS','Docker','Kubernetes','Terraform'], bg:'#f0fdf4', color:'#22c55e' },
        { id:5, title:'Project Manager',     type:'Full-time',  location:'Quezon City',  salary:'₱45,000–₱60,000/mo', slots:2,  applicants:18, hired:2, status:'Open',   daysLeft:3,  postedDate:'Nov 25', description:'Lead cross-functional teams to deliver software projects on time. Requires strong Agile/Scrum methodology experience.', skills:['Agile','Scrum','JIRA','Confluence'], bg:'#eff8ff', color:'#2872A1' },
        { id:6, title:'QA Engineer',         type:'Part-time',  location:'Hybrid',       salary:'₱20,000–₱30,000/mo', slots:2,  applicants:11, hired:2, status:'Closed', daysLeft:0,  postedDate:'Nov 15', description:'Test our web applications thoroughly, identify bugs, and ensure quality standards are met across all releases.', skills:['Selenium','JIRA','Test Plans','Bug Tracking'], bg:'#f0fdf4', color:'#16a34a' },
        { id:7, title:'Data Analyst',        type:'Internship', location:'Quezon City',  salary:'₱15,000–₱18,000/mo', slots:3,  applicants:0,  hired:0, status:'Draft',  daysLeft:30, postedDate:'—',       description:'Draft listing for data analyst intern position. Will require proficiency in Excel, basic SQL, and data visualization tools.', skills:['Excel','SQL','Power BI','Python'], bg:'#f8fafc', color:'#94a3b8' },
      ]
    }
  },
  computed: {
    filteredJobs() {
      return this.jobs.filter(j => {
        const matchSearch = !this.search || j.title.toLowerCase().includes(this.search.toLowerCase())
        const matchStatus = !this.filterStatus || j.status === this.filterStatus
        const matchType   = !this.filterType   || j.type   === this.filterType
        return matchSearch && matchStatus && matchType
      })
    },
    stripStats() {
      const j = this.jobs
      return [
        { label: 'Total Listings', value: j.length,                                    color: '#1e293b' },
        { label: 'Open',           value: j.filter(x => x.status === 'Open').length,   color: '#22c55e' },
        { label: 'Closed',         value: j.filter(x => x.status === 'Closed').length, color: '#94a3b8' },
        { label: 'Draft',          value: j.filter(x => x.status === 'Draft').length,  color: '#2872A1' },
        { label: 'Total Slots',    value: j.reduce((s,x) => s + x.slots, 0),           color: '#2563eb' },
      ]
    }
  },
  methods: {
    async fetchJobs() {
      try {
        const params = {}
        if (this.search)       params.search = this.search
        if (this.filterStatus) params.status = this.filterStatus
        if (this.filterType)   params.type   = this.filterType
        const { data } = await api.get('/employer/jobs', { params })
        const colors = [['#eff6ff','#2563eb'],['#faf5ff','#8b5cf6'],['#fdf4ff','#d946ef'],['#f0fdf4','#22c55e'],['#eff8ff','#2872A1']]
        this.jobs = (data.data || data).map((j, idx) => ({
          ...j,
          skills: Array.isArray(j.skills) ? j.skills : (j.skills || '').split(',').map(s => s.trim()).filter(Boolean),
          bg:    colors[idx % colors.length][0],
          color: colors[idx % colors.length][1],
        }))
      } catch (e) { console.error(e) }
    },
    jobStatusClass(s) {
      return { Open:'status-open', Closed:'status-closed', Draft:'status-draft' }[s] || ''
    },
    openDrawer(job) { this.selected = job; this.drawerOpen = true },
    openModal(job) {
      this.editingJob = job
      if (job) this.form = { ...job, skillsRaw: Array.isArray(job.skills) ? job.skills.join(', ') : (job.skills || '') }
      else this.form = { title:'', type:'', salary:'', slots:'', location:'', daysLeft:'', description:'', skillsRaw:'', status:'Open' }
      this.showModal = true
    },
    async saveJob() {
      const skillsArr = this.form.skillsRaw.split(',').map(s => s.trim()).filter(Boolean)
      const colors = [['#eff6ff','#2563eb'],['#faf5ff','#8b5cf6'],['#fdf4ff','#d946ef'],['#f0fdf4','#22c55e'],['#eff8ff','#2872A1']]
      try {
        const payload = { ...this.form, skills: skillsArr }
        if (this.editingJob) {
          const { data } = await api.put(`/employer/jobs/${this.editingJob.id}`, payload)
          const idx = this.jobs.findIndex(j => j.id === this.editingJob.id)
          if (idx !== -1) this.jobs[idx] = { ...this.jobs[idx], ...data.data || data, skills: skillsArr }
        } else {
          const { data } = await api.post('/employer/jobs', payload)
          const [bg, color] = colors[this.jobs.length % colors.length]
          this.jobs.push({ ...data.data || data, skills: skillsArr, applicants: 0, hired: 0, bg, color })
        }
        this.showModal = false
      } catch (e) { console.error(e) }
    },
    async closeJob(job) {
      try {
        await api.patch(`/employer/jobs/${job.id}/close`)
        const idx = this.jobs.findIndex(j => j.id === job.id)
        if (idx !== -1) this.jobs[idx].status = 'Closed'
        if (this.selected?.id === job.id) this.selected.status = 'Closed'
      } catch (e) { console.error(e) }
    },
    async deleteJob(job) {
      try {
        await api.delete(`/employer/jobs/${job.id}`)
        this.jobs = this.jobs.filter(j => j.id !== job.id)
        this.drawerOpen = false
      } catch (e) { console.error(e) }
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

.stats-strip { display: flex; background: #fff; border-radius: 12px; overflow: hidden; border: 1px solid #f1f5f9; }
.strip-stat { flex: 1; display: flex; flex-direction: column; align-items: center; padding: 14px 12px; border-right: 1px solid #f1f5f9; }
.strip-stat:last-child { border-right: none; }
.strip-val { font-size: 22px; font-weight: 800; line-height: 1; }
.strip-label { font-size: 11px; color: #94a3b8; margin-top: 4px; font-weight: 500; }

.filters-bar { display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; flex: 1; max-width: 360px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-group { display: flex; align-items: center; gap: 8px; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }
.btn-amber { display: flex; align-items: center; gap: 6px; background: #2872A1; color: #fff; border: none; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; transition: background 0.15s; }
.btn-amber:hover { background: #1a5f8a; }

.jobs-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; }
.job-card { background: #fff; border-radius: 14px; padding: 18px; border: 1px solid #f1f5f9; display: flex; flex-direction: column; gap: 10px; transition: box-shadow 0.15s; }
.job-card:hover { box-shadow: 0 4px 20px rgba(0,0,0,0.07); }
.job-card-header { display: flex; align-items: center; justify-content: space-between; }
.job-icon-lg { width: 40px; height: 40px; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.job-status { font-size: 11px; font-weight: 700; padding: 3px 10px; border-radius: 99px; }
.status-open   { background: #f0fdf4; color: #22c55e; }
.status-closed { background: #f1f5f9; color: #94a3b8; }
.status-draft  { background: #eff8ff; color: #1a5f8a; }
.job-card-title { font-size: 15px; font-weight: 800; color: #1e293b; line-height: 1.2; }
.job-tags { display: flex; gap: 6px; flex-wrap: wrap; }
.job-tag { font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; background: #f1f5f9; color: #64748b; }
.type-tag { background: #eff6ff; color: #2563eb; }
.job-salary { font-size: 13px; font-weight: 700; color: #2872A1; }
.job-desc { font-size: 12px; color: #64748b; line-height: 1.5; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.job-skills { display: flex; gap: 5px; flex-wrap: wrap; }
.skill-chip { font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; background: #f8fafc; color: #64748b; border: 1px solid #f1f5f9; }
.skill-more { font-size: 11px; color: #94a3b8; }

.applicant-progress { display: flex; flex-direction: column; gap: 5px; }
.progress-labels { display: flex; justify-content: space-between; }
.prog-label { font-size: 11px; color: #94a3b8; }
.prog-bar-bg { height: 5px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.prog-bar-fill { height: 100%; border-radius: 99px; }

.job-card-footer { display: flex; align-items: center; justify-content: space-between; }
.post-date { font-size: 11px; color: #94a3b8; }
.deadline-badge { display: flex; align-items: center; gap: 4px; font-size: 11px; font-weight: 600; color: #64748b; background: #f1f5f9; padding: 3px 8px; border-radius: 99px; }
.deadline-badge.urgent { background: #fef2f2; color: #ef4444; }
.job-card-actions { display: flex; gap: 6px; margin-top: 2px; }
.card-btn { flex: 1; display: flex; align-items: center; justify-content: center; gap: 5px; padding: 8px; border-radius: 8px; font-size: 12px; font-weight: 600; cursor: pointer; font-family: inherit; border: none; transition: all 0.15s; }
.view-btn  { background: #f1f5f9; color: #64748b; }
.view-btn:hover  { background: #e2e8f0; }
.edit-btn  { background: #eff8ff; color: #1a5f8a; }
.edit-btn:hover  { background: #bae6fd; }
.close-btn { background: #fef2f2; color: #ef4444; }
.close-btn:hover { background: #fee2e2; }

/* DRAWER */
.drawer-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.3); z-index: 100; display: flex; justify-content: flex-end; backdrop-filter: blur(2px); }
.drawer { width: 420px; height: 100vh; background: #fff; display: flex; flex-direction: column; overflow: hidden; box-shadow: -8px 0 32px rgba(0,0,0,0.12); }
.drawer-header { display: flex; align-items: center; gap: 12px; padding: 20px; border-bottom: 1px solid #f1f5f9; }
.drawer-icon { width: 46px; height: 46px; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.drawer-title-wrap { flex: 1; }
.drawer-name { font-size: 16px; font-weight: 800; color: #1e293b; }
.drawer-loc { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.drawer-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 16px; padding: 4px; border-radius: 6px; }
.drawer-close:hover { background: #f1f5f9; }
.drawer-body { flex: 1; overflow-y: auto; padding: 20px; display: flex; flex-direction: column; gap: 4px; }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 16px; }
.info-item { display: flex; flex-direction: column; gap: 3px; }
.info-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
.info-val { font-size: 13px; font-weight: 500; color: #1e293b; }
.section-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.06em; margin: 14px 0 8px; }
.desc-text { font-size: 13px; color: #64748b; line-height: 1.6; }
.skill-tags { display: flex; gap: 6px; flex-wrap: wrap; }
.mt4 { margin-top: 4px; }

/* MODAL */
.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.4); z-index: 100; display: flex; align-items: center; justify-content: center; backdrop-filter: blur(2px); }
.modal { background: #fff; border-radius: 16px; width: 560px; max-width: 95vw; box-shadow: 0 20px 60px rgba(0,0,0,0.15); max-height: 90vh; display: flex; flex-direction: column; }
.modal-header { display: flex; align-items: center; gap: 12px; padding: 20px 24px; border-bottom: 1px solid #f1f5f9; }
.modal-icon-wrap { width: 40px; height: 40px; background: #eff8ff; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.modal-title { font-size: 16px; font-weight: 800; color: #1e293b; }
.modal-sub { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.modal-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 18px; padding: 4px; border-radius: 6px; margin-left: auto; line-height: 1; }
.modal-close:hover { background: #f1f5f9; }
.modal-body { padding: 20px 24px; display: flex; flex-direction: column; gap: 14px; overflow-y: auto; flex: 1; }
.modal-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 16px 24px; border-top: 1px solid #f1f5f9; }
.form-row { display: grid; gap: 12px; }
.form-row.two { grid-template-columns: 1fr 1fr; }
.form-group { display: flex; flex-direction: column; gap: 5px; }
.form-label { font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; }
.req { color: #ef4444; }
.form-input { border: 1px solid #e2e8f0; border-radius: 8px; padding: 9px 12px; font-size: 13px; color: #1e293b; font-family: inherit; outline: none; background: #f8fafc; transition: border 0.15s; }
.form-input:focus { border-color: #08BDDE; background: #fff; }
.form-input.textarea { resize: vertical; }
.btn-ghost { background: #f1f5f9; color: #64748b; border: none; border-radius: 10px; padding: 9px 18px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-ghost:hover { background: #e2e8f0; }

.drawer-enter-active, .drawer-leave-active { transition: opacity 0.2s; }
.drawer-enter-active .drawer, .drawer-leave-active .drawer { transition: transform 0.25s cubic-bezier(0.4,0,0.2,1); }
.drawer-enter-from, .drawer-leave-to { opacity: 0; }
.drawer-enter-from .drawer, .drawer-leave-to .drawer { transform: translateX(100%); }
.modal-enter-active, .modal-leave-active { transition: opacity 0.2s; }
.modal-enter-active .modal, .modal-leave-active .modal { transition: transform 0.2s, opacity 0.2s; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
.modal-enter-from .modal, .modal-leave-to .modal { transform: scale(0.95); opacity: 0; }
</style>