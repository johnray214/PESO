<template>
  <div class="dashboard-page">

        <!-- Stat Cards -->
        <div class="stats-grid">
          <div v-for="stat in stats" :key="stat.label" class="stat-card">
            <div class="stat-top">
              <div class="stat-icon" :style="{ background: stat.iconBg }">
                <span v-html="stat.icon" :style="{ color: stat.iconColor }"></span>
              </div>
              <span class="trend" :class="stat.trendUp ? 'up' : 'down'">
                {{ stat.trendUp ? '↑' : '↓' }} {{ stat.trendVal }}
              </span>
            </div>
            <h2 class="stat-value">{{ stat.value }}</h2>
            <p class="stat-label">{{ stat.label }}</p>
            <p class="stat-sub">{{ stat.sub }}</p>
          </div>
        </div>

        <!-- Registrations Overview Row -->
        <div class="mid-row">
          <div class="card chart-card">
            <div class="card-header">
              <div>
                <h3>Registrations Overview</h3>
                <p class="card-sub">Monthly jobseeker & employer registrations — {{ new Date().getFullYear() }}</p>
              </div>
              <div class="legend">
                <span class="legend-item"><span class="legend-line blue"></span> Jobseekers</span>
                <span class="legend-item"><span class="legend-line cyan"></span> Employers</span>
              </div>
            </div>
            <div class="svg-chart-wrap">
              <svg viewBox="0 0 620 180" preserveAspectRatio="xMidYMid meet" class="svg-chart">
                <defs>
                  <linearGradient id="gradBlue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="#2563eb" stop-opacity="0.18"/>
                    <stop offset="100%" stop-color="#2563eb" stop-opacity="0"/>
                  </linearGradient>
                  <linearGradient id="gradCyan" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="#06b6d4" stop-opacity="0.15"/>
                    <stop offset="100%" stop-color="#06b6d4" stop-opacity="0"/>
                  </linearGradient>
                </defs>
                <line v-for="(gl, i) in gridLines" :key="'g'+i" :x1="50" :y1="gl.y" :x2="610" :y2="gl.y" stroke="#f1f5f9" stroke-width="1"/>
                <text v-for="(gl, i) in gridLines" :key="'yl'+i" :x="44" :y="gl.y+4" text-anchor="end" font-size="9" fill="#cbd5e1" font-family="Plus Jakarta Sans, sans-serif">{{ gl.label }}</text>
                <path :d="jobseekerArea" fill="url(#gradBlue)"/>
                <path :d="employerArea" fill="url(#gradCyan)"/>
                <path :d="jobseekerLine" fill="none" stroke="#2563eb" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                <path :d="employerLine" fill="none" stroke="#06b6d4" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                <circle v-for="(pt, i) in jobseekerPoints" :key="'jd'+i" :cx="pt.x" :cy="pt.y" r="3.5" fill="#fff" stroke="#2563eb" stroke-width="2"/>
                <circle v-for="(pt, i) in employerPoints" :key="'ed'+i" :cx="pt.x" :cy="pt.y" r="3.5" fill="#fff" stroke="#06b6d4" stroke-width="2"/>
                <text v-for="(m, i) in chartData" :key="'xl'+i" :x="getX(i)" :y="173" text-anchor="middle" font-size="9" fill="#94a3b8" font-family="Plus Jakarta Sans, sans-serif">{{ m.label }}</text>
              </svg>
            </div>
            <div class="chart-summary">
              <div class="summary-item"><span class="summary-dot blue-dot"></span><span class="summary-label">Total Jobseekers</span><span class="summary-val blue-val">{{ totalJobseekers.toLocaleString() }}</span></div>
              <div class="summary-divider"></div>
              <div class="summary-item"><span class="summary-dot cyan-dot"></span><span class="summary-label">Total Employers</span><span class="summary-val cyan-val">{{ totalEmployers.toLocaleString() }}</span></div>
              <div class="summary-divider"></div>
              <div class="summary-item"><span class="summary-label">Peak Month</span><span class="summary-val">Dec</span></div>
            </div>
          </div>

          <!-- Placement Rate Donut — fixed width so it never overflows -->
          <div class="card side-card">
            <div class="card-header">
              <div><h3>Placement Rate</h3><p class="card-sub">This month</p></div>
            </div>
            <div class="donut-wrapper">
              <svg width="150" height="150" viewBox="0 0 150 150">
                <circle cx="75" cy="75" r="55" fill="none" stroke="#f1f5f9" stroke-width="18"/>
                <circle cx="75" cy="75" r="55" fill="none" stroke="#2563eb" stroke-width="18" stroke-dasharray="180 346" stroke-dashoffset="0" stroke-linecap="round" transform="rotate(-90 75 75)"/>
                <circle cx="75" cy="75" r="55" fill="none" stroke="#f97316" stroke-width="18" stroke-dasharray="76 346" stroke-dashoffset="-180" stroke-linecap="round" transform="rotate(-90 75 75)"/>
                <circle cx="75" cy="75" r="55" fill="none" stroke="#06b6d4" stroke-width="18" stroke-dasharray="45 346" stroke-dashoffset="-256" stroke-linecap="round" transform="rotate(-90 75 75)"/>
                <circle cx="75" cy="75" r="55" fill="none" stroke="#ef4444" stroke-width="18" stroke-dasharray="45 346" stroke-dashoffset="-301" stroke-linecap="round" transform="rotate(-90 75 75)"/>
                <text x="75" y="68" text-anchor="middle" font-size="20" font-weight="800" fill="#1e293b">52%</text>
                <text x="75" y="84" text-anchor="middle" font-size="10" fill="#94a3b8">Placed</text>
              </svg>
            </div>
            <div class="donut-legend">
              <div v-for="item in donutItems" :key="item.label" class="donut-row">
                <div class="donut-label-left"><span class="dot" :style="{ background: item.color }"></span><span>{{ item.label }}</span></div>
                <span class="donut-pct" :style="{ color: item.color }">{{ item.pct }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Placement Metrics + Trending Jobs Row -->
        <div class="mid-row">
          <div class="card chart-card">
            <div class="card-header">
              <div><h3>Placement Metrics</h3><p class="card-sub">Monthly placement status breakdown — {{ new Date().getFullYear() }}</p></div>
              <div class="legend">
                <span class="legend-item"><span class="legend-line placement-blue"></span> Placement</span>
                <span class="legend-item"><span class="legend-line processing-orange"></span> Processing</span>
                <span class="legend-item"><span class="legend-line registration-cyan"></span> Registration</span>
                <span class="legend-item"><span class="legend-line rejection-red"></span> Rejection</span>
              </div>
            </div>
            <div class="svg-chart-wrap">
              <svg viewBox="0 0 620 180" preserveAspectRatio="xMidYMid meet" class="svg-chart">
                <defs>
                  <linearGradient id="gradP" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#2563eb" stop-opacity="0.18"/><stop offset="100%" stop-color="#2563eb" stop-opacity="0"/></linearGradient>
                  <linearGradient id="gradPr" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#f97316" stop-opacity="0.15"/><stop offset="100%" stop-color="#f97316" stop-opacity="0"/></linearGradient>
                  <linearGradient id="gradR" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#06b6d4" stop-opacity="0.15"/><stop offset="100%" stop-color="#06b6d4" stop-opacity="0"/></linearGradient>
                  <linearGradient id="gradRej" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#ef4444" stop-opacity="0.15"/><stop offset="100%" stop-color="#ef4444" stop-opacity="0"/></linearGradient>
                </defs>
                <line v-for="(gl, i) in gridLines" :key="'pg'+i" :x1="50" :y1="gl.y" :x2="610" :y2="gl.y" stroke="#f1f5f9" stroke-width="1"/>
                <text v-for="(gl, i) in gridLines" :key="'pyl'+i" :x="44" :y="gl.y+4" text-anchor="end" font-size="9" fill="#cbd5e1" font-family="Plus Jakarta Sans, sans-serif">{{ gl.label }}</text>
                <path :d="placementArea" fill="url(#gradP)"/>
                <path :d="processingArea" fill="url(#gradPr)"/>
                <path :d="registrationArea" fill="url(#gradR)"/>
                <path :d="rejectionArea" fill="url(#gradRej)"/>
                <path :d="placementLine" fill="none" stroke="#2563eb" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                <path :d="processingLine" fill="none" stroke="#f97316" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                <path :d="registrationLine" fill="none" stroke="#06b6d4" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                <path :d="rejectionLine" fill="none" stroke="#ef4444" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                <circle v-for="(pt, i) in placementPoints" :key="'pd'+i" :cx="pt.x" :cy="pt.y" r="3.5" fill="#fff" stroke="#2563eb" stroke-width="2"/>
                <circle v-for="(pt, i) in processingPoints" :key="'prd'+i" :cx="pt.x" :cy="pt.y" r="3.5" fill="#fff" stroke="#f97316" stroke-width="2"/>
                <circle v-for="(pt, i) in registrationPoints" :key="'rd'+i" :cx="pt.x" :cy="pt.y" r="3.5" fill="#fff" stroke="#06b6d4" stroke-width="2"/>
                <circle v-for="(pt, i) in rejectionPoints" :key="'red'+i" :cx="pt.x" :cy="pt.y" r="3.5" fill="#fff" stroke="#ef4444" stroke-width="2"/>
                <text v-for="(m, i) in placementData" :key="'pxl'+i" :x="getXP(i)" :y="173" text-anchor="middle" font-size="9" fill="#94a3b8" font-family="Plus Jakarta Sans, sans-serif">{{ m.label }}</text>
              </svg>
            </div>
            <div class="chart-summary">
              <div class="summary-item"><span class="summary-dot placement-dot"></span><span class="summary-label">Placement</span><span class="summary-val placement-val">{{ totalPlacement }}</span></div>
              <div class="summary-divider"></div>
              <div class="summary-item"><span class="summary-dot processing-dot"></span><span class="summary-label">Processing</span><span class="summary-val processing-val">{{ totalProcessing }}</span></div>
              <div class="summary-divider"></div>
              <div class="summary-item"><span class="summary-dot registration-dot"></span><span class="summary-label">Registration</span><span class="summary-val registration-val">{{ totalRegistration }}</span></div>
              <div class="summary-divider"></div>
              <div class="summary-item"><span class="summary-dot rejection-dot"></span><span class="summary-label">Rejection</span><span class="summary-val rejection-val">{{ totalRejection }}</span></div>
            </div>
          </div>

          <!-- FIX 1: Top Trending Jobs — same fixed width as Placement Rate, clean redesign -->
          <div class="card side-card">
            <div class="card-header">
              <div><h3>Top Trending Jobs</h3><p class="card-sub">Highest demand roles this month</p></div>
              <span class="live-badge">Live</span>
            </div>
            <!-- FIX: vertical stacked list, no grid -->
            <div class="trending-jobs-list">
              <div v-for="(job, i) in trendingJobs" :key="job.title" class="tjob-row">
                <span class="tjob-rank" :style="{ color: i < 3 ? '#2563eb' : '#94a3b8' }">#{{ i + 1 }}</span>
                <div class="tjob-icon" :style="{ background: job.bg }">
                  <span v-html="job.icon" :style="{ color: job.color }"></span>
                </div>
                <div class="tjob-body">
                  <p class="tjob-title">{{ job.title }}</p>
                  <p class="tjob-industry">{{ job.industry }}</p>
                </div>
                <div class="tjob-stats">
                  <span class="tjob-open">{{ job.vacancies }} open</span>
                  <span class="tjob-apps">{{ job.apps }} apps</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- FIX 2: Top Trending Skills — full width, vertical single-column list -->
        <div class="card">
          <div class="card-header">
            <div><h3>Top Trending Skills</h3><p class="card-sub">Most in-demand skills from active job postings this month</p></div>
            <span class="live-badge">Live</span>
          </div>
          <div class="trending-skills-list">
            <div v-for="(skill, i) in trendingSkills" :key="skill.name" class="skill-bar-row">
              <div class="skill-rank">{{ i + 1 }}</div>
              <div class="skill-info">
                <div class="skill-name-row">
                  <span class="skill-name">{{ skill.name }}</span>
                  <span class="skill-count">{{ skill.count }} postings</span>
                </div>
                <div class="skill-track">
                  <div class="skill-fill" :style="{ width: (trendingSkills[0].count > 0 ? skill.count / trendingSkills[0].count * 100 : 0) + '%', background: skill.color }"></div>
                </div>
              </div>
              <span class="mini-trend" :class="skill.up ? 'trend-up' : 'trend-down'">
                {{ skill.up ? '↑' : '↓' }} {{ skill.change }}
              </span>
            </div>
          </div>
        </div>

        <!-- Bottom Row -->
        <div class="bottom-row">
          <div class="card table-card">
            <div class="card-header">
              <div><h3>Recent Applicants</h3><p class="card-sub">Latest jobseeker registrations</p></div>
              <a href="#" class="see-all">See All</a>
            </div>
            <table class="data-table">
              <thead><tr><th>Applicant</th><th>Skills</th><th>Applied For</th><th>Date</th><th>Status</th></tr></thead>
              <tbody>
                <tr v-for="a in applicants" :key="a.name">
                  <td>
                    <div class="person-cell">
                      <div class="person-avatar" :style="{ background: a.color }">{{ a.name[0] }}</div>
                      <div><span class="person-name">{{ a.name }}</span><span class="person-loc">{{ a.location }}</span></div>
                    </div>
                  </td>
                  <td><span class="skill-tag">{{ a.skill }}</span></td>
                  <td class="job-cell">{{ a.job }}</td>
                  <td class="date-cell">{{ a.date }}</td>
                  <td><span class="status-badge" :class="a.statusClass">{{ a.status }}</span></td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="right-col">
            <div class="card events-card">
              <div class="card-header"><h3>Upcoming Events</h3><a href="#" class="see-all">See All</a></div>
              <div class="events-list">
                <div v-for="event in events" :key="event.title" class="event-item">
                  <div class="event-date-box" :style="{ background: event.bg, color: event.color }">
                    <span class="event-day">{{ event.day }}</span>
                    <span class="event-month">{{ event.month }}</span>
                  </div>
                  <div class="event-info">
                    <p class="event-title">{{ event.title }}</p>
                    <p class="event-meta">{{ event.location }} · {{ event.slots }} slots</p>
                  </div>
                  <span class="event-type" :style="{ background: event.bg, color: event.color }">{{ event.type }}</span>
                </div>
              </div>
            </div>
            <div class="card employers-card">
              <div class="card-header"><h3>Top Employers</h3><a href="#" class="see-all">See All</a></div>
              <div class="employers-list">
                <div v-for="(emp, i) in topEmployers" :key="emp.name" class="employer-item">
                  <span class="emp-rank">#{{ i + 1 }}</span>
                  <div class="emp-logo" :style="{ background: emp.bg }">{{ emp.name[0] }}</div>
                  <div class="emp-info"><p class="emp-name">{{ emp.name }}</p><p class="emp-industry">{{ emp.industry }}</p></div>
                  <span class="emp-vacancies">{{ emp.vacancies }} open</span>
                </div>
              </div>
            </div>
          </div>
        </div>

  </div>
</template>

<script>
import api from '@/services/api'

export default {
  name: 'PESODashboard',
  async mounted() {
    try {
      const { data } = await api.get('/admin/dashboard')
      const d = data.data

      // Merge stat values into existing cards (preserves icons & colors)
      if (d.stats) {
        d.stats.forEach((s, i) => {
          if (this.stats[i]) {
            this.stats[i].value    = s.value
            this.stats[i].sub      = s.sub
            this.stats[i].trendVal = s.trendVal != null ? `${s.trendVal}%` : '0%'
            this.stats[i].trendUp  = s.trendUp
            if (s.label) this.stats[i].label = s.label
          }
        })
      }

      // Charts — structure is identical (label, jobseekers, employers / placement, processing…)
      if (d.registrationChart?.length)  this.chartData    = d.registrationChart
      if (d.placementChart?.length)     this.placementData = d.placementChart

      // Trending jobs — merge API fields, keep existing bg/color/icon
      if (d.trendingJobs?.length) {
        this.trendingJobs = d.trendingJobs.map((j, i) => ({
          ...this.trendingJobs[i] || this.trendingJobs[0],
          title:    j.title,
          industry: j.industry,
          vacancies:j.vacancies,
          apps:     j.apps,
        }))
      }

      // Trending skills — merge API count, keep existing color/change/up
      if (d.trendingSkills?.length) {
        this.trendingSkills = d.trendingSkills.map((s, i) => ({
          ...this.trendingSkills[i] || this.trendingSkills[0],
          name:  s.name,
          count: s.count,
        }))
      }

      // Recent applicants — add a color derived from index
      if (d.recentApplicants?.length) {
        const colors = ['#2563eb','#f97316','#22c55e','#8b5cf6','#06b6d4','#ef4444']
        this.applicants = d.recentApplicants.map((a, i) => ({
          ...a,
          color:       a.color || colors[i % colors.length],
          statusClass: a.status ? a.status.toLowerCase() : 'processing',
        }))
      }

      // Upcoming events — add bg/color by event type
      if (d.upcomingEvents?.length) {
        const typeMap = {
          'Job Fair':          { bg: '#dbeafe', color: '#2563eb' },
          'Seminar':           { bg: '#fff7ed', color: '#f97316' },
          'Training':          { bg: '#dcfce7', color: '#16a34a' },
          'Livelihood Program':{ bg: '#fdf4ff', color: '#a21caf' },
          'Workshop':          { bg: '#fef9c3', color: '#ca8a04' },
        }
        this.events = d.upcomingEvents.map(e => ({
          ...e,
          bg:    typeMap[e.type]?.bg    || '#f1f5f9',
          color: typeMap[e.type]?.color || '#64748b',
        }))
      }

      // Top employers — add bg from index
      if (d.topEmployers?.length) {
        const bgs = ['#eff6ff','#fff7ed','#f0fdf4','#faf5ff','#ecfdf5']
        this.topEmployers = d.topEmployers.map((emp, i) => ({
          ...emp,
          bg: bgs[i % bgs.length],
        }))
      }
    } catch (e) {
      console.error('Dashboard load error:', e)
    }
  },
  data() {
    return {
      stats: [
        { label: 'Registered Jobseekers', value: '4,821', sub: '+124 this week', iconBg: '#dbeafe', iconColor: '#2563eb', trendVal: '12%', trendUp: true,  icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>` },
        { label: 'Active Employers',      value: '318',   sub: '+9 this week',   iconBg: '#fff7ed', iconColor: '#f97316', trendVal: '8%',  trendUp: true,  icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>` },
        { label: 'Job Vacancies',         value: '1,054', sub: '+67 this week',  iconBg: '#f0fdf4', iconColor: '#22c55e', trendVal: '19%', trendUp: true,  icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>` },
        { label: 'Successful Placements', value: '2,190', sub: '+88 this month', iconBg: '#eff6ff', iconColor: '#3b82f6', trendVal: '5%',  trendUp: false, icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>` },
      ],
      chartData: [
        { label: 'Jan', jobseekers: 320, employers: 80  }, { label: 'Feb', jobseekers: 380, employers: 110 },
        { label: 'Mar', jobseekers: 420, employers: 130 }, { label: 'Apr', jobseekers: 370, employers: 100 },
        { label: 'May', jobseekers: 490, employers: 160 }, { label: 'Jun', jobseekers: 445, employers: 145 },
        { label: 'Jul', jobseekers: 510, employers: 170 }, { label: 'Aug', jobseekers: 460, employers: 140 },
        { label: 'Sep', jobseekers: 480, employers: 155 }, { label: 'Oct', jobseekers: 530, employers: 175 },
        { label: 'Nov', jobseekers: 560, employers: 190 }, { label: 'Dec', jobseekers: 600, employers: 210 },
      ],
      placementData: [
        { label: 'Jan', placement: 280, processing: 180, registration: 110, rejection: 80  },
        { label: 'Feb', placement: 320, processing: 200, registration: 130, rejection: 95  },
        { label: 'Mar', placement: 360, processing: 190, registration: 145, rejection: 88  },
        { label: 'Apr', placement: 310, processing: 210, registration: 120, rejection: 105 },
        { label: 'May', placement: 410, processing: 220, registration: 155, rejection: 92  },
        { label: 'Jun', placement: 380, processing: 195, registration: 140, rejection: 110 },
        { label: 'Jul', placement: 430, processing: 230, registration: 165, rejection: 98  },
        { label: 'Aug', placement: 390, processing: 205, registration: 135, rejection: 115 },
        { label: 'Sep', placement: 400, processing: 215, registration: 150, rejection: 102 },
        { label: 'Oct', placement: 450, processing: 240, registration: 170, rejection: 95  },
        { label: 'Nov', placement: 475, processing: 250, registration: 180, rejection: 108 },
        { label: 'Dec', placement: 510, processing: 265, registration: 195, rejection: 120 },
      ],
      gridLines: [
        { y: 14, label: '600' }, { y: 44, label: '500' }, { y: 74, label: '400' },
        { y: 104, label: '300' }, { y: 134, label: '200' }, { y: 158, label: '100' },
      ],
      donutItems: [
        { label: 'Placement',   pct: '52%', color: '#2563eb' },
        { label: 'Processing',  pct: '22%', color: '#f97316' },
        { label: 'Registration',pct: '13%', color: '#06b6d4' },
        { label: 'Rejection',   pct: '13%', color: '#ef4444' },
      ],
      trendingSkills: [
        { name: 'Customer Service',     count: 214, change: '18%', up: true,  color: '#2563eb' },
        { name: 'Data Entry / Admin',   count: 188, change: '12%', up: true,  color: '#06b6d4' },
        { name: 'IT / Programming',     count: 165, change: '24%', up: true,  color: '#8b5cf6' },
        { name: 'Accounting / Finance', count: 142, change: '7%',  up: true,  color: '#22c55e' },
        { name: 'Healthcare / Nursing', count: 130, change: '3%',  up: false, color: '#f97316' },
        { name: 'Teaching / Education', count: 98,  change: '5%',  up: true,  color: '#f59e0b' },
      ],
      trendingJobs: [
        { title: 'Customer Service Rep',   industry: 'BPO / Call Center', vacancies: 82, apps: 310, bg: '#dbeafe', color: '#2563eb', icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07A19.5 19.5 0 013.07 9.81a19.79 19.79 0 01-3.07-8.67A2 2 0 012 0h3a2 2 0 012 1.72"/></svg>` },
        { title: 'Software Developer',     industry: 'IT / Tech',         vacancies: 68, apps: 278, bg: '#eff6ff', color: '#6366f1', icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>` },
        { title: 'Bookkeeper/Accountant',  industry: 'Finance',           vacancies: 54, apps: 195, bg: '#f0fdf4', color: '#22c55e', icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6"/></svg>` },
        { title: 'Registered Nurse',       industry: 'Healthcare',        vacancies: 47, apps: 182, bg: '#fff7ed', color: '#f97316', icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>` },
        { title: 'Sales Associate',        industry: 'Retail / Commerce', vacancies: 41, apps: 160, bg: '#fdf4ff', color: '#d946ef', icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 002 1.61h9.72a2 2 0 002-1.61L23 6H6"/></svg>` },
        { title: 'Data Entry Clerk',       industry: 'Admin / Office',    vacancies: 38, apps: 148, bg: '#ecfdf5', color: '#10b981', icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>` },
      ],
      applicants: [
        { name: 'Maria Santos',   location: 'Quezon City', skill: 'Accounting', job: 'Bookkeeper',    date: 'Dec 06', status: 'Matched',   statusClass: 'matched',   color: '#2563eb' },
        { name: 'Juan dela Cruz', location: 'Marikina',    skill: 'IT / Dev',   job: 'Web Developer', date: 'Dec 06', status: 'Pending',   statusClass: 'pending',   color: '#f97316' },
        { name: 'Ana Reyes',      location: 'Pasig',       skill: 'Nursing',    job: 'Medical Staff', date: 'Dec 05', status: 'Matched',   statusClass: 'matched',   color: '#22c55e' },
        { name: 'Pedro Lim',      location: 'Caloocan',    skill: 'Electrical', job: 'Electrician',   date: 'Dec 05', status: 'Reviewing', statusClass: 'reviewing', color: '#3b82f6' },
        { name: 'Rosa Garcia',    location: 'Taguig',      skill: 'Teaching',   job: 'Instructor',    date: 'Dec 04', status: 'Pending',   statusClass: 'pending',   color: '#06b6d4' },
      ],
      events: [
        { day: '12', month: 'DEC', title: 'Job Fair 2024 — Quezon City', location: 'QC Sports Club', slots: 200, type: 'Job Fair', bg: '#dbeafe', color: '#2563eb' },
        { day: '18', month: 'DEC', title: 'Livelihood Seminar Series',   location: 'City Hall Annex', slots: 80,  type: 'Seminar',  bg: '#fff7ed', color: '#f97316' },
        { day: '22', month: 'DEC', title: 'Skills Training — BPO',       location: 'TESDA Center',    slots: 50,  type: 'Training', bg: '#f0fdf4', color: '#22c55e' },
      ],
      topEmployers: [
        { name: 'Accenture PH',   industry: 'BPO / IT Services', vacancies: 42, bg: '#dbeafe' },
        { name: 'Jollibee Foods', industry: 'Food & Beverage',   vacancies: 28, bg: '#fff7ed' },
        { name: 'SM Supermalls',  industry: 'Retail',            vacancies: 35, bg: '#eff6ff' },
        { name: 'Ayala Corp',     industry: 'Real Estate',       vacancies: 19, bg: '#f0fdf4' },
      ],
    }
  },
  computed: {
    totalJobseekers() { return this.chartData.reduce((s, d) => s + d.jobseekers, 0) },
    totalEmployers()  { return this.chartData.reduce((s, d) => s + d.employers,  0) },
    jobseekerPoints() { return this.chartData.map((d, i) => ({ x: this.getX(i),  y: this.valToY(d.jobseekers)  })) },
    employerPoints()  { return this.chartData.map((d, i) => ({ x: this.getX(i),  y: this.valToY(d.employers)   })) },
    jobseekerLine()   { return this.smooth(this.jobseekerPoints) },
    employerLine()    { return this.smooth(this.employerPoints)  },
    jobseekerArea()   { const p = this.jobseekerPoints; return this.smooth(p) + ` L${p[p.length-1].x},158 L${p[0].x},158 Z` },
    employerArea()    { const p = this.employerPoints;  return this.smooth(p) + ` L${p[p.length-1].x},158 L${p[0].x},158 Z` },
    totalPlacement()    { return this.placementData.reduce((s, d) => s + d.placement,    0) },
    totalProcessing()   { return this.placementData.reduce((s, d) => s + d.processing,   0) },
    totalRegistration() { return this.placementData.reduce((s, d) => s + d.registration, 0) },
    totalRejection()    { return this.placementData.reduce((s, d) => s + d.rejection,    0) },
    placementPoints()   { return this.placementData.map((d, i) => ({ x: this.getXP(i), y: this.valToYP(d.placement)    })) },
    processingPoints()  { return this.placementData.map((d, i) => ({ x: this.getXP(i), y: this.valToYP(d.processing)   })) },
    registrationPoints(){ return this.placementData.map((d, i) => ({ x: this.getXP(i), y: this.valToYP(d.registration) })) },
    rejectionPoints()   { return this.placementData.map((d, i) => ({ x: this.getXP(i), y: this.valToYP(d.rejection)    })) },
    placementLine()     { return this.smooth(this.placementPoints)    },
    processingLine()    { return this.smooth(this.processingPoints)   },
    registrationLine()  { return this.smooth(this.registrationPoints) },
    rejectionLine()     { return this.smooth(this.rejectionPoints)    },
    placementArea()     { const p = this.placementPoints;    return this.smooth(p) + ` L${p[p.length-1].x},158 L${p[0].x},158 Z` },
    processingArea()    { const p = this.processingPoints;   return this.smooth(p) + ` L${p[p.length-1].x},158 L${p[0].x},158 Z` },
    registrationArea()  { const p = this.registrationPoints; return this.smooth(p) + ` L${p[p.length-1].x},158 L${p[0].x},158 Z` },
    rejectionArea()     { const p = this.rejectionPoints;    return this.smooth(p) + ` L${p[p.length-1].x},158 L${p[0].x},158 Z` },
  },
  methods: {
    getX(i)    { return 50 + i * (560 / (this.chartData.length    - 1)) },
    valToY(v)  { return 158 - ((v / 700) * 144) },
    getXP(i)   { return 50 + i * (560 / (this.placementData.length - 1)) },
    valToYP(v) { return 158 - ((v / 600) * 144) },
    smooth(pts) {
      if (!pts.length) return ''
      let d = `M${pts[0].x},${pts[0].y}`
      for (let i = 1; i < pts.length; i++) {
        const cpx = (pts[i-1].x + pts[i].x) / 2
        d += ` C${cpx},${pts[i-1].y} ${cpx},${pts[i].y} ${pts[i].x},${pts[i].y}`
      }
      return d
    },
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
.dashboard-page { font-family: 'Plus Jakarta Sans', sans-serif; flex: 1; overflow-y: auto; padding: 20px 24px; display: flex; flex-direction: column; gap: 16px; background: #f1eeff; }

/* STAT CARDS */
.stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; }
.stat-card { background: #fff; border-radius: 14px; padding: 18px; border: 1px solid #f1f5f9; }
.stat-top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.stat-icon { width: 42px; height: 42px; border-radius: 12px; display: flex; align-items: center; justify-content: center; }
.trend { font-size: 12px; font-weight: 700; padding: 4px 8px; border-radius: 99px; }
.trend.up   { color: #22c55e; background: #f0fdf4; }
.trend.down { color: #ef4444; background: #fef2f2; }
.stat-value { font-size: 26px; font-weight: 800; color: #1e293b; line-height: 1.1; margin-bottom: 4px; }
.stat-label { font-size: 12.5px; color: #64748b; font-weight: 500; margin-bottom: 4px; }
.stat-sub   { font-size: 11px; color: #94a3b8; }

/* LAYOUT ROWS */
/* FIX: Use fixed pixel width for side card so it never bleeds into sidebar */
.mid-row { display: grid; grid-template-columns: 1fr 252px; gap: 14px; }
.bottom-row { display: grid; grid-template-columns: 1fr 280px; gap: 14px; }
.right-col  { display: flex; flex-direction: column; gap: 14px; }

/* CARD BASE */
.card { background: #fff; border-radius: 14px; padding: 18px; border: 1px solid #f1f5f9; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
.side-card { background: #fff; border-radius: 14px; padding: 18px; border: 1px solid #f1f5f9; box-shadow: 0 1px 3px rgba(0,0,0,0.04); min-width: 0; overflow: hidden; }
.card-header { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 16px; gap: 8px; }
.card-header h3 { font-size: 14px; font-weight: 700; color: #1e293b; }
.card-sub { font-size: 11px; color: #94a3b8; margin-top: 2px; }
.see-all { font-size: 12px; color: #2563eb; text-decoration: none; font-weight: 600; white-space: nowrap; flex-shrink: 0; }
.see-all:hover { text-decoration: underline; }

/* LIVE BADGE */
.live-badge { background: #dcfce7; color: #16a34a; font-size: 10px; font-weight: 700; padding: 3px 8px; border-radius: 99px; display: flex; align-items: center; gap: 4px; height: fit-content; white-space: nowrap; flex-shrink: 0; }
.live-badge::before { content: ''; width: 6px; height: 6px; background: #16a34a; border-radius: 50%; animation: pulse 1.5s infinite; }
@keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: 0.3; } }

/* LEGEND */
.legend { display: flex; align-items: center; gap: 14px; font-size: 11.5px; color: #64748b; flex-wrap: wrap; flex-shrink: 0; }
.legend-item { display: flex; align-items: center; gap: 6px; }
.legend-line { display: inline-block; width: 22px; height: 3px; border-radius: 2px; }
.legend-line.blue              { background: #2563eb; }
.legend-line.cyan              { background: #06b6d4; }
.legend-line.placement-blue   { background: #2563eb; }
.legend-line.processing-orange { background: #f97316; }
.legend-line.registration-cyan { background: #06b6d4; }
.legend-line.rejection-red    { background: #ef4444; }

/* CHART */
.svg-chart-wrap { width: 100%; overflow: hidden; }
.svg-chart { width: 100%; height: 185px; display: block; }
.chart-summary { display: flex; align-items: center; margin-top: 14px; padding-top: 14px; border-top: 1px solid #f1f5f9; }
.summary-item { display: flex; align-items: center; gap: 6px; flex: 1; justify-content: center; }
.summary-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.blue-dot         { background: #2563eb; }
.cyan-dot         { background: #06b6d4; }
.placement-dot    { background: #2563eb; }
.processing-dot   { background: #f97316; }
.registration-dot { background: #06b6d4; }
.rejection-dot    { background: #ef4444; }
.summary-label { font-size: 11px; color: #94a3b8; }
.summary-val   { font-size: 13px; font-weight: 700; color: #1e293b; margin-left: 2px; }
.blue-val         { color: #2563eb; }
.cyan-val         { color: #06b6d4; }
.placement-val    { color: #2563eb; }
.processing-val   { color: #f97316; }
.registration-val { color: #06b6d4; }
.rejection-val    { color: #ef4444; }
.summary-divider  { width: 1px; height: 28px; background: #f1f5f9; }

/* DONUT */
.donut-wrapper { display: flex; justify-content: center; margin: 4px 0 14px; }
.donut-legend  { display: flex; flex-direction: column; gap: 8px; }
.donut-row     { display: flex; align-items: center; justify-content: space-between; font-size: 12px; color: #64748b; }
.donut-label-left { display: flex; align-items: center; gap: 8px; }
.dot     { display: inline-block; width: 8px; height: 8px; border-radius: 50%; }
.donut-pct { font-size: 12px; font-weight: 700; }

/* FIX: TOP TRENDING JOBS — vertical stacked rows, no 2-col grid */
.trending-jobs-list { display: flex; flex-direction: column; gap: 6px; }
.tjob-row { display: flex; align-items: center; gap: 8px; padding: 7px 8px; border-radius: 9px; background: #f8fafc; border: 1px solid #f1f5f9; }
.tjob-rank { font-size: 11px; font-weight: 800; min-width: 18px; flex-shrink: 0; }
.tjob-icon { width: 28px; height: 28px; border-radius: 7px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.tjob-body { flex: 1; min-width: 0; }
.tjob-title    { font-size: 11.5px; font-weight: 700; color: #1e293b; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.tjob-industry { font-size: 10px; color: #94a3b8; margin-top: 1px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.tjob-stats    { display: flex; flex-direction: column; align-items: flex-end; gap: 1px; flex-shrink: 0; }
.tjob-open { font-size: 11px; font-weight: 700; color: #2563eb; }
.tjob-apps { font-size: 10px; color: #94a3b8; }

/* FIX: TOP TRENDING SKILLS — single column vertical list */
.trending-skills-list { display: flex; flex-direction: column; gap: 12px; }
.skill-bar-row { display: flex; align-items: center; gap: 10px; }
.skill-rank  { font-size: 11px; font-weight: 700; color: #cbd5e1; min-width: 14px; text-align: center; flex-shrink: 0; }
.skill-info  { flex: 1; }
.skill-name-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 5px; }
.skill-name  { font-size: 12.5px; font-weight: 600; color: #1e293b; }
.skill-count { font-size: 11px; color: #94a3b8; }
.skill-track { height: 7px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.skill-fill  { height: 100%; border-radius: 99px; transition: width 0.6s ease; }
.mini-trend  { font-size: 10.5px; font-weight: 700; padding: 2px 7px; border-radius: 6px; white-space: nowrap; flex-shrink: 0; }
.trend-up    { background: #f0fdf4; color: #16a34a; }
.trend-down  { background: #fef2f2; color: #ef4444; }

/* TABLE */
.data-table { width: 100%; border-collapse: collapse; font-size: 12.5px; }
.data-table th { text-align: left; padding: 8px 10px; color: #94a3b8; font-weight: 600; font-size: 11px; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.data-table td { padding: 10px; color: #1e293b; border-bottom: 1px solid #f8fafc; vertical-align: middle; }
.person-cell   { display: flex; align-items: center; gap: 8px; }
.person-avatar { width: 28px; height: 28px; border-radius: 50%; color: #fff; font-size: 11px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.person-name   { display: block; font-weight: 600; font-size: 12.5px; color: #1e293b; }
.person-loc    { display: block; font-size: 10.5px; color: #94a3b8; }
.skill-tag     { background: #f1f5f9; color: #475569; font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
.job-cell      { color: #475569; }
.date-cell     { color: #94a3b8; white-space: nowrap; }
.status-badge  { padding: 3px 10px; border-radius: 99px; font-size: 11px; font-weight: 600; white-space: nowrap; }
.status-badge.matched   { background: #f0fdf4; color: #22c55e; }
.status-badge.pending   { background: #fff7ed; color: #f97316; }
.status-badge.reviewing { background: #eff6ff; color: #3b82f6; }

/* EVENTS */
.events-list { display: flex; flex-direction: column; gap: 10px; }
.event-item  { display: flex; align-items: center; gap: 10px; }
.event-date-box { min-width: 40px; height: 44px; border-radius: 10px; display: flex; flex-direction: column; align-items: center; justify-content: center; flex-shrink: 0; }
.event-day   { font-size: 15px; font-weight: 800; line-height: 1; }
.event-month { font-size: 9px; font-weight: 600; text-transform: uppercase; }
.event-info  { flex: 1; min-width: 0; }
.event-title { font-size: 12px; font-weight: 600; color: #1e293b; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.event-meta  { font-size: 10.5px; color: #94a3b8; margin-top: 2px; }
.event-type  { font-size: 10px; font-weight: 600; padding: 3px 8px; border-radius: 6px; white-space: nowrap; flex-shrink: 0; }

/* EMPLOYERS */
.employers-list  { display: flex; flex-direction: column; gap: 10px; }
.employer-item   { display: flex; align-items: center; gap: 10px; }
.emp-rank        { font-size: 11px; font-weight: 700; color: #cbd5e1; min-width: 16px; }
.emp-logo        { width: 32px; height: 32px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 13px; font-weight: 800; color: #7c3aed; flex-shrink: 0; }
.emp-info        { flex: 1; }
.emp-name        { font-size: 12.5px; font-weight: 600; color: #1e293b; }
.emp-industry    { font-size: 10.5px; color: #94a3b8; }
.emp-vacancies   { font-size: 11px; font-weight: 600; color: #2563eb; background: #dbeafe; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
</style>