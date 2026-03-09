<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Job Listings</h1>
        <p class="page-sub">Manage your active and past job postings</p>
      </div>
      <button class="btn-primary" @click="openModal(null)">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        Post New Job
      </button>
    </div>

    <!-- Filters -->
    <div class="filters-bar">
      <div class="search-box">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        <input v-model="search" type="text" placeholder="Search job listings..." class="search-input"/>
      </div>
      <div class="filter-group">
        <select v-model="filterStatus" class="filter-select">
          <option value="">All Status</option>
          <option value="Open">Open</option>
          <option value="Closed">Closed</option>
        </select>
        <select v-model="filterType" class="filter-select">
          <option value="">All Types</option>
          <option value="Full-time">Full-time</option>
          <option value="Part-time">Part-time</option>
          <option value="Contract">Contract</option>
        </select>
      </div>
    </div>

    <!-- Job Cards -->
    <div class="job-grid">
      <div v-for="job in filteredJobs" :key="job.id" class="job-card" @click="openModal(job)">
        <div class="job-header">
          <div>
            <h3 class="job-title">{{ job.title }}</h3>
            <p class="job-type">{{ job.type }} · {{ job.location }}</p>
          </div>
          <span class="status-badge" :class="job.status === 'Open' ? 'status-open' : 'status-closed'">{{ job.status }}</span>
        </div>
        <div class="job-skills">
          <span v-for="skill in job.skills" :key="skill" class="skill-tag">{{ skill }}</span>
        </div>
        <div class="job-footer">
          <div class="job-stat">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
            <span>{{ job.applicants }} applicants</span>
          </div>
          <div class="job-stat">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
            <span>{{ job.views }} views</span>
          </div>
          <span class="job-posted">Posted {{ job.posted }}</span>
        </div>
      </div>
    </div>

    <!-- Modal -->
    <transition name="modal">
      <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
        <div class="modal">
          <div class="modal-header">
            <h3>{{ editingJob ? 'Edit Job Listing' : 'Post New Job' }}</h3>
            <button class="modal-close" @click="showModal = false">✕</button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label class="form-label">Job Title</label>
              <input v-model="form.title" type="text" class="form-input" placeholder="e.g. Senior Web Developer"/>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label class="form-label">Employment Type</label>
                <select v-model="form.type" class="form-input">
                  <option>Full-time</option>
                  <option>Part-time</option>
                  <option>Contract</option>
                </select>
              </div>
              <div class="form-group">
                <label class="form-label">Location</label>
                <input v-model="form.location" type="text" class="form-input" placeholder="e.g. Quezon City"/>
              </div>
            </div>
            <div class="form-group">
              <label class="form-label">Description</label>
              <textarea v-model="form.description" class="form-textarea" rows="4" placeholder="Job description..."></textarea>
            </div>
            <div class="form-group">
              <label class="form-label">Required Skills (comma-separated)</label>
              <input v-model="form.skills" type="text" class="form-input" placeholder="e.g. Vue.js, Laravel, CSS"/>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label class="form-label">Salary Range (Min)</label>
                <input v-model="form.salaryMin" type="text" class="form-input" placeholder="e.g. 25,000"/>
              </div>
              <div class="form-group">
                <label class="form-label">Salary Range (Max)</label>
                <input v-model="form.salaryMax" type="text" class="form-input" placeholder="e.g. 35,000"/>
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn-ghost" @click="showModal = false">Cancel</button>
            <button class="btn-primary" @click="saveJob">{{ editingJob ? 'Update' : 'Post Job' }}</button>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
export default {
  name: 'EmployerJobListings',
  data() {
    return {
      search: '',
      filterStatus: '',
      filterType: '',
      showModal: false,
      editingJob: null,
      form: { title: '', type: 'Full-time', location: '', description: '', skills: '', salaryMin: '', salaryMax: '' },
      jobs: [
        { id: 1, title: 'Web Developer', type: 'Full-time', location: 'BGC, Taguig', status: 'Open', skills: ['Vue.js', 'Laravel', 'CSS'], applicants: 18, views: 245, posted: 'Dec 01' },
        { id: 2, title: 'Data Analyst', type: 'Full-time', location: 'Makati', status: 'Open', skills: ['Excel', 'SQL', 'Power BI'], applicants: 12, views: 189, posted: 'Nov 20' },
        { id: 3, title: 'Customer Support', type: 'Part-time', location: 'Quezon City', status: 'Open', skills: ['Communication', 'CRM'], applicants: 25, views: 312, posted: 'Dec 03' },
        { id: 4, title: 'Marketing Officer', type: 'Full-time', location: 'Mandaluyong', status: 'Closed', skills: ['Digital Marketing', 'SEO'], applicants: 8, views: 156, posted: 'Oct 15' },
      ],
    }
  },
  computed: {
    filteredJobs() {
      return this.jobs.filter(job => {
        const matchSearch = !this.search || job.title.toLowerCase().includes(this.search.toLowerCase())
        const matchStatus = !this.filterStatus || job.status === this.filterStatus
        const matchType = !this.filterType || job.type === this.filterType
        return matchSearch && matchStatus && matchType
      })
    },
  },
  methods: {
    openModal(job) {
      if (job) {
        this.editingJob = job
        this.form = { ...job, skills: job.skills.join(', ') }
      } else {
        this.editingJob = null
        this.form = { title: '', type: 'Full-time', location: '', description: '', skills: '', salaryMin: '', salaryMax: '' }
      }
      this.showModal = true
    },
    saveJob() {
      this.showModal = false
    },
  },
}
</script>

<style scoped>
.page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  padding: 24px;
  background: #f8fafc;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
}

.page-title {
  font-size: 20px;
  font-weight: 800;
  color: #1e293b;
}

.page-sub {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 2px;
}

.btn-primary {
  display: flex;
  align-items: center;
  gap: 6px;
  background: #2563eb;
  color: #fff;
  border: none;
  border-radius: 10px;
  padding: 9px 16px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
}

.btn-primary:hover {
  background: #1d4ed8;
}

.filters-bar {
  display: flex;
  gap: 10px;
  align-items: center;
}

.search-box {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 8px 14px;
  flex: 1;
  max-width: 400px;
}

.search-input {
  border: none;
  outline: none;
  background: none;
  font-size: 13px;
  color: #1e293b;
  font-family: inherit;
  width: 100%;
}

.filter-group {
  display: flex;
  gap: 8px;
}

.filter-select {
  padding: 8px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 500;
  background: #fff;
  color: #1e293b;
  cursor: pointer;
  font-family: inherit;
}

.job-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 16px;
}

.job-card {
  background: #fff;
  border-radius: 12px;
  padding: 18px;
  border: 1px solid #f1f5f9;
  cursor: pointer;
  transition: all 0.15s;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.job-card:hover {
  border-color: #2563eb;
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.1);
}

.job-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}

.job-title {
  font-size: 15px;
  font-weight: 800;
  color: #1e293b;
  margin-bottom: 4px;
}

.job-type {
  font-size: 11px;
  color: #94a3b8;
}

.status-badge {
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 700;
}

.status-open {
  background: #dcfce7;
  color: #16a34a;
}

.status-closed {
  background: #fee2e2;
  color: #dc2626;
}

.job-skills {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.skill-tag {
  background: #eff6ff;
  color: #2563eb;
  font-size: 10px;
  font-weight: 600;
  padding: 4px 8px;
  border-radius: 6px;
}

.job-footer {
  display: flex;
  align-items: center;
  gap: 16px;
  padding-top: 12px;
  border-top: 1px solid #f8fafc;
}

.job-stat {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 12px;
  color: #64748b;
  font-weight: 600;
}

.job-posted {
  margin-left: auto;
  font-size: 11px;
  color: #cbd5e1;
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.3);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  backdrop-filter: blur(2px);
}

.modal {
  width: 600px;
  max-height: 90vh;
  background: #fff;
  border-radius: 16px;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
}

.modal-header {
  padding: 20px 24px;
  border-bottom: 1px solid #f1f5f9;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.modal-header h3 {
  font-size: 17px;
  font-weight: 800;
  color: #1e293b;
}

.modal-close {
  background: #f8fafc;
  border: none;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 18px;
  color: #64748b;
  transition: all 0.15s;
}

.modal-close:hover {
  background: #f1f5f9;
}

.modal-body {
  padding: 24px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-label {
  font-size: 12px;
  font-weight: 700;
  color: #1e293b;
}

.form-input,
.form-textarea {
  padding: 10px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-family: inherit;
  color: #1e293b;
}

.form-input:focus,
.form-textarea:focus {
  outline: none;
  border-color: #2563eb;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.modal-footer {
  padding: 16px 24px;
  border-top: 1px solid #f1f5f9;
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}

.btn-ghost {
  padding: 9px 16px;
  border: 1px solid #e2e8f0;
  background: #fff;
  color: #64748b;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
}

.btn-ghost:hover {
  background: #f8fafc;
}

.modal-enter-active,
.modal-leave-active {
  transition: all 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
  transform: scale(0.95);
}
</style>
