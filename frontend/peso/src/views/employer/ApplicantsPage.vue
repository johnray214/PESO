<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Applicants</h1>
        <p class="page-sub">Review and manage job applications</p>
      </div>
    </div>

    <!-- Status Tabs -->
    <div class="status-tabs">
      <button v-for="tab in statusTabs" :key="tab.value"
        :class="['status-tab', { active: activeTab === tab.value }]"
        @click="activeTab = tab.value">
        {{ tab.label }}
        <span class="tab-count">{{ tab.count }}</span>
      </button>
    </div>

    <!-- Filters -->
    <div class="filters-bar">
      <div class="search-box">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        <input v-model="search" type="text" placeholder="Search applicants..." class="search-input"/>
      </div>
      <div class="filter-group">
        <select v-model="filterJob" class="filter-select">
          <option value="">All Positions</option>
          <option v-for="job in jobOptions" :key="job" :value="job">{{ job }}</option>
        </select>
        <select v-model="filterMatch" class="filter-select">
          <option value="">All Match Scores</option>
          <option value="high">High (80%+)</option>
          <option value="medium">Medium (60-79%)</option>
          <option value="low">Low (&lt;60%)</option>
        </select>
      </div>
    </div>

    <!-- Applicants Table -->
    <div class="table-card">
      <table class="data-table">
        <thead>
          <tr>
            <th>Applicant</th>
            <th>Position</th>
            <th>Match</th>
            <th>Skills</th>
            <th>Applied</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="app in filteredApplicants" :key="app.id" @click="openDrawer(app)" class="clickable-row">
            <td>
              <div class="applicant-cell">
                <div class="app-avatar" :style="{ background: app.color }">{{ app.name[0] }}</div>
                <div>
                  <p class="app-name">{{ app.name }}</p>
                  <p class="app-email">{{ app.email }}</p>
                </div>
              </div>
            </td>
            <td>{{ app.position }}</td>
            <td>
              <span class="match-badge" :class="matchClass(app.match)">{{ app.match }}%</span>
            </td>
            <td>
              <div class="skills-cell">
                <span v-for="(skill, i) in app.skills.slice(0, 2)" :key="i" class="skill-tag-sm">{{ skill }}</span>
                <span v-if="app.skills.length > 2" class="more-skills">+{{ app.skills.length - 2 }}</span>
              </div>
            </td>
            <td>{{ app.appliedDate }}</td>
            <td>
              <span class="status-badge" :class="statusClass(app.status)">{{ app.status }}</span>
            </td>
            <td @click.stop>
              <div class="action-btns">
                <button class="act-btn view" @click="openDrawer(app)" title="View">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                </button>
                <button class="act-btn accept" @click.stop="updateStatus(app, 'Shortlisted')" title="Shortlist">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
                </button>
                <button class="act-btn reject" @click.stop="updateStatus(app, 'Rejected')" title="Reject">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Drawer -->
    <transition name="drawer">
      <div v-if="drawerOpen" class="drawer-overlay" @click.self="drawerOpen = false">
        <div class="drawer">
          <div class="drawer-header">
            <div class="app-avatar lg" :style="{ background: selected?.color }">{{ selected?.name[0] }}</div>
            <div class="drawer-title-wrap">
              <h2 class="drawer-name">{{ selected?.name }}</h2>
              <p class="drawer-sub">Applied for {{ selected?.position }}</p>
            </div>
            <span class="match-badge-lg" :class="matchClass(selected?.match)">{{ selected?.match }}% match</span>
            <button class="drawer-close" @click="drawerOpen = false">✕</button>
          </div>
          <div class="drawer-body">
            <div class="info-section">
              <h3 class="section-title">Contact Information</h3>
              <div class="info-grid">
                <div class="info-item"><span class="info-label">Email</span><span class="info-val">{{ selected?.email }}</span></div>
                <div class="info-item"><span class="info-label">Phone</span><span class="info-val">{{ selected?.phone }}</span></div>
                <div class="info-item"><span class="info-label">Location</span><span class="info-val">{{ selected?.location }}</span></div>
              </div>
            </div>
            <div class="info-section">
              <h3 class="section-title">Skills</h3>
              <div class="skills-wrap">
                <span v-for="skill in selected?.skills" :key="skill" class="skill-tag">{{ skill }}</span>
              </div>
            </div>
            <div class="info-section">
              <h3 class="section-title">Experience</h3>
              <p class="info-text">{{ selected?.experience }}</p>
            </div>
            <div class="drawer-actions">
              <button class="btn-secondary" @click="updateStatus(selected, 'Rejected')">Reject</button>
              <button class="btn-primary" @click="updateStatus(selected, 'Shortlisted')">Shortlist</button>
              <button class="btn-success" @click="updateStatus(selected, 'Hired')">Mark as Hired</button>
            </div>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
export default {
  name: 'EmployerApplicants',
  data() {
    return {
      search: '',
      filterJob: '',
      filterMatch: '',
      activeTab: 'all',
      drawerOpen: false,
      selected: null,
      statusTabs: [
        { label: 'All', value: 'all', count: 38 },
        { label: 'For Review', value: 'For Review', count: 18 },
        { label: 'Shortlisted', value: 'Shortlisted', count: 12 },
        { label: 'Hired', value: 'Hired', count: 6 },
        { label: 'Rejected', value: 'Rejected', count: 2 },
      ],
      jobOptions: ['Web Developer', 'Data Analyst', 'Customer Support'],
      applicants: [
        { id: 1, name: 'Maria Santos', email: 'maria@email.com', phone: '0917-123-4567', location: 'Quezon City', position: 'Web Developer', match: 92, skills: ['Vue.js', 'Laravel', 'CSS'], appliedDate: 'Dec 08', status: 'For Review', color: '#2563eb', experience: '3 years in web development' },
        { id: 2, name: 'Juan Dela Cruz', email: 'juan@email.com', phone: '0918-234-5678', location: 'Manila', position: 'Data Analyst', match: 88, skills: ['Excel', 'SQL', 'Python', 'Power BI'], appliedDate: 'Dec 07', status: 'Shortlisted', color: '#22c55e', experience: '2 years in data analysis' },
        { id: 3, name: 'Rosa Garcia', email: 'rosa@email.com', phone: '0919-345-6789', location: 'Makati', position: 'Web Developer', match: 85, skills: ['React', 'Node.js', 'MongoDB'], appliedDate: 'Dec 06', status: 'For Review', color: '#f97316', experience: '4 years full-stack development' },
        { id: 4, name: 'Carlo Bautista', email: 'carlo@email.com', phone: '0920-456-7890', location: 'Pasig', position: 'Customer Support', match: 90, skills: ['Communication', 'CRM', 'Problem Solving'], appliedDate: 'Dec 06', status: 'For Review', color: '#06b6d4', experience: '1 year in customer service' },
        { id: 5, name: 'Ana Reyes', email: 'ana@email.com', phone: '0921-567-8901', location: 'Taguig', position: 'Data Analyst', match: 78, skills: ['Excel', 'Tableau', 'Statistics'], appliedDate: 'Dec 05', status: 'Hired', color: '#a855f7', experience: '2 years as data analyst' },
      ],
    }
  },
  computed: {
    filteredApplicants() {
      return this.applicants.filter(app => {
        const matchTab = this.activeTab === 'all' || app.status === this.activeTab
        const matchSearch = !this.search || app.name.toLowerCase().includes(this.search.toLowerCase()) || app.position.toLowerCase().includes(this.search.toLowerCase())
        const matchJob = !this.filterJob || app.position === this.filterJob
        const matchMatch = !this.filterMatch || this.matchFilter(app.match, this.filterMatch)
        return matchTab && matchSearch && matchJob && matchMatch
      })
    },
  },
  methods: {
    matchFilter(score, filter) {
      if (filter === 'high') return score >= 80
      if (filter === 'medium') return score >= 60 && score < 80
      if (filter === 'low') return score < 60
      return true
    },
    matchClass(score) {
      if (score >= 80) return 'match-high'
      if (score >= 60) return 'match-medium'
      return 'match-low'
    },
    statusClass(status) {
      const map = { 'For Review': 'status-review', 'Shortlisted': 'status-shortlisted', 'Hired': 'status-hired', 'Rejected': 'status-rejected' }
      return map[status] || ''
    },
    openDrawer(app) {
      this.selected = { ...app }
      this.drawerOpen = true
    },
    updateStatus(app, newStatus) {
      app.status = newStatus
      this.drawerOpen = false
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

.status-tabs {
  display: flex;
  gap: 8px;
  border-bottom: 2px solid #f1f5f9;
}

.status-tab {
  background: none;
  border: none;
  border-bottom: 2px solid transparent;
  padding: 10px 16px;
  font-size: 13px;
  font-weight: 600;
  color: #64748b;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.15s;
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: -2px;
}

.status-tab:hover {
  color: #1e293b;
}

.status-tab.active {
  color: #2563eb;
  border-bottom-color: #2563eb;
}

.tab-count {
  background: #f1f5f9;
  color: #64748b;
  font-size: 10px;
  font-weight: 700;
  padding: 2px 6px;
  border-radius: 99px;
}

.status-tab.active .tab-count {
  background: #dbeafe;
  color: #2563eb;
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

.table-card {
  background: #fff;
  border-radius: 12px;
  border: 1px solid #f1f5f9;
  overflow: hidden;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
}

.data-table thead {
  background: #f8fafc;
  border-bottom: 1px solid #f1f5f9;
}

.data-table th {
  padding: 12px 16px;
  text-align: left;
  font-size: 11px;
  font-weight: 700;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.data-table td {
  padding: 14px 16px;
  font-size: 13px;
  color: #1e293b;
  border-bottom: 1px solid #f8fafc;
}

.clickable-row {
  cursor: pointer;
  transition: background 0.15s;
}

.clickable-row:hover {
  background: #f8fafc;
}

.applicant-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.app-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 14px;
  font-weight: 700;
  flex-shrink: 0;
}

.app-avatar.lg {
  width: 56px;
  height: 56px;
  font-size: 22px;
}

.app-name {
  font-size: 13px;
  font-weight: 700;
  color: #1e293b;
}

.app-email {
  font-size: 11px;
  color: #94a3b8;
}

.match-badge {
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 700;
}

.match-high {
  background: #dcfce7;
  color: #16a34a;
}

.match-medium {
  background: #fef3c7;
  color: #d97706;
}

.match-low {
  background: #fee2e2;
  color: #dc2626;
}

.match-badge-lg {
  padding: 6px 14px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 800;
}

.skills-cell {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
}

.skill-tag-sm {
  background: #eff6ff;
  color: #2563eb;
  font-size: 10px;
  font-weight: 600;
  padding: 3px 8px;
  border-radius: 6px;
}

.more-skills {
  font-size: 10px;
  color: #94a3b8;
  font-weight: 600;
}

.status-badge {
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 700;
  text-transform: capitalize;
}

.status-review {
  background: #fff7ed;
  color: #f97316;
}

.status-shortlisted {
  background: #dcfce7;
  color: #16a34a;
}

.status-hired {
  background: #fdf4ff;
  color: #a21caf;
}

.status-rejected {
  background: #fee2e2;
  color: #dc2626;
}

.action-btns {
  display: flex;
  gap: 6px;
}

.act-btn {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s;
}

.act-btn.view {
  background: #eff6ff;
  color: #2563eb;
}

.act-btn.view:hover {
  background: #dbeafe;
}

.act-btn.accept {
  background: #dcfce7;
  color: #16a34a;
}

.act-btn.accept:hover {
  background: #bbf7d0;
}

.act-btn.reject {
  background: #fee2e2;
  color: #dc2626;
}

.act-btn.reject:hover {
  background: #fecaca;
}

.drawer-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.3);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  backdrop-filter: blur(2px);
}

.drawer {
  width: 500px;
  max-height: 90vh;
  background: #fff;
  border-radius: 16px;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
}

.drawer-header {
  padding: 24px;
  border-bottom: 1px solid #f1f5f9;
  display: flex;
  align-items: center;
  gap: 14px;
  position: relative;
}

.drawer-title-wrap {
  flex: 1;
}

.drawer-name {
  font-size: 18px;
  font-weight: 800;
  color: #1e293b;
}

.drawer-sub {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 2px;
}

.drawer-close {
  position: absolute;
  top: 16px;
  right: 16px;
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

.drawer-close:hover {
  background: #f1f5f9;
  color: #1e293b;
}

.drawer-body {
  padding: 24px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.info-section {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.section-title {
  font-size: 13px;
  font-weight: 800;
  color: #1e293b;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.info-label {
  font-size: 11px;
  color: #94a3b8;
  font-weight: 600;
}

.info-val {
  font-size: 13px;
  color: #1e293b;
  font-weight: 600;
}

.info-text {
  font-size: 13px;
  color: #64748b;
  line-height: 1.6;
}

.skills-wrap {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.skill-tag {
  background: #eff6ff;
  color: #2563eb;
  font-size: 11px;
  font-weight: 600;
  padding: 5px 10px;
  border-radius: 6px;
}

.drawer-actions {
  display: flex;
  gap: 8px;
  margin-top: 8px;
}

.btn-secondary {
  flex: 1;
  padding: 10px 16px;
  border: 1px solid #e2e8f0;
  background: #fff;
  color: #64748b;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.15s;
}

.btn-secondary:hover {
  background: #f8fafc;
}

.btn-success {
  flex: 1;
  padding: 10px 16px;
  border: none;
  background: #22c55e;
  color: #fff;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
  transition: background 0.15s;
}

.btn-success:hover {
  background: #16a34a;
}

.drawer-enter-active,
.drawer-leave-active {
  transition: all 0.3s ease;
}

.drawer-enter-from,
.drawer-leave-to {
  opacity: 0;
  transform: scale(0.95);
}
</style>
