<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Dashboard</h1>
        <p class="page-sub">Overview of your job postings and applicants</p>
      </div>
      <button class="btn-primary" @click="openPostJob">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        Post New Job
      </button>
    </div>

    <!-- Stats Grid -->
    <div class="stats-grid">
      <div v-for="stat in stats" :key="stat.label" class="stat-card">
        <div class="stat-icon" :style="{ background: stat.bg, color: stat.color }">
          <span v-html="stat.icon"></span>
        </div>
        <div class="stat-body">
          <span class="stat-label">{{ stat.label }}</span>
          <span class="stat-value">{{ stat.value }}</span>
          <span class="stat-change" :class="stat.trend">
            {{ stat.change }}
          </span>
        </div>
      </div>
    </div>

    <!-- Two Column Layout -->
    <div class="two-col">
      <!-- Active Job Listings -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Active Job Listings</h3>
          <router-link to="/employer/job-listings" class="link-btn">View all</router-link>
        </div>
        <div class="job-list">
          <div v-for="job in activeJobs" :key="job.id" class="job-item">
            <div class="job-main">
              <h4 class="job-title">{{ job.title }}</h4>
              <p class="job-meta">{{ job.type }} · Posted {{ job.posted }}</p>
            </div>
            <div class="job-stats">
              <span class="job-stat">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                {{ job.applicants }}
              </span>
              <span class="job-views">{{ job.views }} views</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Recent Applicants -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Recent Applicants</h3>
          <router-link to="/employer/applicants" class="link-btn">View all</router-link>
        </div>
        <div class="applicant-list">
          <div v-for="app in recentApplicants" :key="app.id" class="applicant-item">
            <div class="app-avatar" :style="{ background: app.color }">{{ app.name[0] }}</div>
            <div class="app-info">
              <h4 class="app-name">{{ app.name }}</h4>
              <p class="app-job">Applied for {{ app.position }}</p>
            </div>
            <div class="app-right">
              <span class="match-score">{{ app.match }}% match</span>
              <span class="app-time">{{ app.time }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Applicant Status Chart -->
    <div class="card">
      <div class="card-header">
        <h3 class="card-title">Applicant Status Overview</h3>
        <div class="chart-legend">
          <span v-for="leg in legend" :key="leg.label" class="legend-item">
            <span class="legend-dot" :style="{ background: leg.color }"></span>
            {{ leg.label }}
          </span>
        </div>
      </div>
      <div class="chart-area">
        <svg viewBox="0 0 400 200" class="bar-chart">
          <g v-for="(bar, i) in chartBars" :key="i">
            <rect :x="bar.x" :y="bar.y" :width="bar.width" :height="bar.height" :fill="bar.color" rx="4" />
            <text :x="bar.x + bar.width/2" :y="bar.y - 8" text-anchor="middle" class="bar-label">{{ bar.value }}</text>
          </g>
        </svg>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'EmployerDashboard',
  data() {
    return {
      stats: [
        { label: 'Active Job Listings', value: '8', change: '+2 this week', trend: 'up', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>`, bg: '#dbeafe', color: '#2563eb' },
        { label: 'Total Applicants', value: '124', change: '+18 today', trend: 'up', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>`, bg: '#dcfce7', color: '#22c55e' },
        { label: 'For Review', value: '18', change: 'Needs attention', trend: 'neutral', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>`, bg: '#fff7ed', color: '#f97316' },
        { label: 'Hired This Month', value: '12', change: '+4 from last month', trend: 'up', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>`, bg: '#f0fdf4', color: '#22c55e' },
      ],
      activeJobs: [
        { id: 1, title: 'Web Developer', type: 'Full-time', posted: 'Dec 01', applicants: 18, views: 245 },
        { id: 2, title: 'Data Analyst', type: 'Full-time', posted: 'Nov 20', applicants: 12, views: 189 },
        { id: 3, title: 'Customer Support', type: 'Part-time', posted: 'Dec 03', applicants: 25, views: 312 },
      ],
      recentApplicants: [
        { id: 1, name: 'Maria Santos', position: 'Web Developer', match: 92, time: '10 min ago', color: '#2563eb' },
        { id: 2, name: 'Juan Dela Cruz', position: 'Data Analyst', match: 88, time: '1h ago', color: '#22c55e' },
        { id: 3, name: 'Rosa Garcia', position: 'Web Developer', match: 85, time: '2h ago', color: '#f97316' },
        { id: 4, name: 'Carlo Bautista', position: 'Customer Support', match: 90, time: '3h ago', color: '#06b6d4' },
      ],
      legend: [
        { label: 'For Review', color: '#3b82f6' },
        { label: 'Shortlisted', color: '#22c55e' },
        { label: 'Hired', color: '#a855f7' },
        { label: 'Rejected', color: '#ef4444' },
      ],
    }
  },
  computed: {
    chartBars() {
      const data = [
        { label: 'For Review', value: 18, color: '#3b82f6' },
        { label: 'Shortlisted', value: 32, color: '#22c55e' },
        { label: 'Hired', value: 12, color: '#a855f7' },
        { label: 'Rejected', value: 8, color: '#ef4444' },
      ]
      const barWidth = 60
      const gap = 40
      const maxValue = Math.max(...data.map(d => d.value))
      const chartHeight = 150

      return data.map((d, i) => {
        const height = (d.value / maxValue) * chartHeight
        return {
          x: 50 + i * (barWidth + gap),
          y: chartHeight - height + 30,
          width: barWidth,
          height: height,
          color: d.color,
          value: d.value,
        }
      })
    },
  },
  methods: {
    openPostJob() {
      this.$router.push('/employer/job-listings')
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
  gap: 18px;
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
  transition: background 0.15s;
}

.btn-primary:hover {
  background: #1d4ed8;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 16px;
}

.stat-card {
  background: #fff;
  border-radius: 12px;
  padding: 18px;
  display: flex;
  align-items: flex-start;
  gap: 14px;
  border: 1px solid #f1f5f9;
}

.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.stat-body {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.stat-label {
  font-size: 12px;
  color: #94a3b8;
  font-weight: 500;
}

.stat-value {
  font-size: 24px;
  font-weight: 800;
  color: #1e293b;
  margin-top: 4px;
}

.stat-change {
  font-size: 11px;
  margin-top: 4px;
  font-weight: 600;
}

.stat-change.up {
  color: #22c55e;
}

.stat-change.neutral {
  color: #f97316;
}

.two-col {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 18px;
}

.card {
  background: #fff;
  border-radius: 12px;
  padding: 20px;
  border: 1px solid #f1f5f9;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.card-title {
  font-size: 15px;
  font-weight: 800;
  color: #1e293b;
}

.link-btn {
  font-size: 12px;
  color: #2563eb;
  font-weight: 600;
  text-decoration: none;
  transition: color 0.15s;
}

.link-btn:hover {
  color: #1d4ed8;
}

.job-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.job-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px;
  background: #f8fafc;
  border-radius: 10px;
  border: 1px solid #f1f5f9;
}

.job-main {
  display: flex;
  flex-direction: column;
}

.job-title {
  font-size: 13px;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 4px;
}

.job-meta {
  font-size: 11px;
  color: #94a3b8;
}

.job-stats {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
}

.job-stat {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 12px;
  font-weight: 600;
  color: #1e293b;
}

.job-views {
  font-size: 11px;
  color: #94a3b8;
}

.applicant-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.applicant-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px;
  background: #f8fafc;
  border-radius: 10px;
  border: 1px solid #f1f5f9;
}

.app-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 15px;
  font-weight: 700;
  flex-shrink: 0;
}

.app-info {
  flex: 1;
  min-width: 0;
}

.app-name {
  font-size: 13px;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 3px;
}

.app-job {
  font-size: 11px;
  color: #94a3b8;
}

.app-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
}

.match-score {
  font-size: 12px;
  font-weight: 700;
  color: #22c55e;
}

.app-time {
  font-size: 10px;
  color: #cbd5e1;
}

.chart-area {
  margin-top: 20px;
}

.bar-chart {
  width: 100%;
  height: 200px;
}

.bar-label {
  font-size: 13px;
  font-weight: 700;
  fill: #1e293b;
}

.chart-legend {
  display: flex;
  gap: 16px;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: #64748b;
  font-weight: 600;
}

.legend-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

@media (max-width: 1024px) {
  .two-col {
    grid-template-columns: 1fr;
  }
}
</style>
