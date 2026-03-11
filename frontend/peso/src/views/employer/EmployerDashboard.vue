<template>
  <div class="layout-wrapper">
    <EmployerSidebar />
    <div class="main-area">
      <EmployerTopbar title="Dashboard" subtitle="Welcome back, Nexus Tech 👋" />
      <div class="page">

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

        <!-- Applications Chart + Hiring Funnel -->
        <div class="mid-row">
          <div class="card chart-card">
            <div class="card-header">
              <div><h3>Applications Over Time</h3><p class="card-sub">Monthly applications received — {{ new Date().getFullYear() }}</p></div>
              <div class="legend">
                <span class="legend-item"><span class="legend-line amber"></span> Applications</span>
                <span class="legend-item"><span class="legend-line green"></span> Hired</span>
              </div>
            </div>
            <div class="svg-chart-wrap">
              <svg viewBox="0 0 620 180" preserveAspectRatio="xMidYMid meet" class="svg-chart">
                <defs>
                  <linearGradient id="gradAmber" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#2872A1" stop-opacity="0.18"/><stop offset="100%" stop-color="#2872A1" stop-opacity="0"/></linearGradient>
                  <linearGradient id="gradGreen" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#22c55e" stop-opacity="0.15"/><stop offset="100%" stop-color="#22c55e" stop-opacity="0"/></linearGradient>
                </defs>
                <line v-for="(gl, i) in gridLines" :key="'g'+i" :x1="50" :y1="gl.y" :x2="610" :y2="gl.y" stroke="#f1f5f9" stroke-width="1"/>
                <text v-for="(gl, i) in gridLines" :key="'yl'+i" :x="44" :y="gl.y+4" text-anchor="end" font-size="9" fill="#cbd5e1" font-family="Plus Jakarta Sans, sans-serif">{{ gl.label }}</text>
                <path :d="appArea" fill="url(#gradAmber)"/>
                <path :d="hiredArea" fill="url(#gradGreen)"/>
                <path :d="appLine" fill="none" stroke="#2872A1" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                <path :d="hiredLine" fill="none" stroke="#22c55e" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                <circle v-for="(pt, i) in appPoints" :key="'ad'+i" :cx="pt.x" :cy="pt.y" r="3.5" fill="#fff" stroke="#2872A1" stroke-width="2"/>
                <circle v-for="(pt, i) in hiredPoints" :key="'hd'+i" :cx="pt.x" :cy="pt.y" r="3.5" fill="#fff" stroke="#22c55e" stroke-width="2"/>
                <text v-for="(m, i) in chartData" :key="'xl'+i" :x="getX(i)" :y="173" text-anchor="middle" font-size="9" fill="#94a3b8" font-family="Plus Jakarta Sans, sans-serif">{{ m.label }}</text>
              </svg>
            </div>
            <div class="chart-summary">
              <div class="summary-item"><span class="summary-dot amber-dot"></span><span class="summary-label">Total Applications</span><span class="summary-val amber-val">{{ totalApplications }}</span></div>
              <div class="summary-divider"></div>
              <div class="summary-item"><span class="summary-dot green-dot"></span><span class="summary-label">Total Hired</span><span class="summary-val green-val">{{ totalHired }}</span></div>
              <div class="summary-divider"></div>
              <div class="summary-item"><span class="summary-label">Hire Rate</span><span class="summary-val">{{ hireRate }}%</span></div>
            </div>
          </div>

          <div class="card funnel-card">
            <div class="card-header"><div><h3>Hiring Funnel</h3><p class="card-sub">This month</p></div></div>
            <div class="funnel-list">
              <div v-for="(stage, i) in funnelStages" :key="stage.label" class="funnel-row">
                <div class="funnel-label-row">
                  <span class="funnel-label">{{ stage.label }}</span>
                  <span class="funnel-count" :style="{ color: stage.color }">{{ stage.count }}</span>
                </div>
                <div class="funnel-bar-bg">
                  <div class="funnel-bar-fill" :style="{ width: (stage.count / funnelMax * 100) + '%', background: stage.color, opacity: 1 - i * 0.12 }"></div>
                </div>
              </div>
            </div>
            <div class="funnel-footer">
              <div class="funnel-rate">
                <span class="funnel-rate-label">Conversion Rate</span>
                <span class="funnel-rate-val">{{ conversionRate }}%</span>
              </div>
            </div>
          </div>
        </div>

        <!-- NEW: Trending Skills in Your Industry + Top Matching Applicants -->
        <div class="intel-row">

          <!-- Trending Skills Relevant to My Jobs -->
          <div class="card">
            <div class="card-header">
              <div><h3>Trending Skills in Your Industry</h3><p class="card-sub">Most in-demand skills matching your job listings</p></div>
              <span class="live-badge">Live</span>
            </div>
            <div class="skill-bars">
              <div v-for="(skill, i) in trendingSkills" :key="skill.name" class="skill-bar-row">
                <div class="skill-rank">{{ i + 1 }}</div>
                <div class="skill-info">
                  <div class="skill-name-row">
                    <span class="skill-name">{{ skill.name }}</span>
                    <div style="display:flex;align-items:center;gap:6px">
                      <span class="skill-count">{{ skill.applicants }} applicants</span>
                      <span class="mini-match-badge" :class="skill.hasListing ? 'has-listing' : 'no-listing'">
                        {{ skill.hasListing ? '✓ Hiring' : 'Not listed' }}
                      </span>
                    </div>
                  </div>
                  <div class="skill-track">
                    <div class="skill-fill" :style="{ width: (skill.applicants / trendingSkills[0].applicants * 100) + '%', background: skill.color }"></div>
                  </div>
                </div>
                <span class="mini-trend" :class="skill.up ? 'trend-up' : 'trend-down'">
                  {{ skill.up ? '↑' : '↓' }} {{ skill.change }}
                </span>
              </div>
            </div>
          </div>

          <!-- Trending Jobs in Market -->
          <div class="card">
            <div class="card-header">
              <div><h3>Trending Jobs in the Market</h3><p class="card-sub">High-demand roles — see where you stand</p></div>
              <span class="live-badge">Live</span>
            </div>
            <div class="trending-jobs-list">
              <div v-for="(job, i) in trendingJobs" :key="job.title" class="trending-job-item">
                <div class="tjob-left">
                  <span class="tjob-rank" :style="{ color: i < 3 ? '#2872A1' : '#94a3b8' }">#{{ i + 1 }}</span>
                  <div class="tjob-icon" :style="{ background: job.bg }">
                    <span v-html="job.icon" :style="{ color: job.color }"></span>
                  </div>
                  <div>
                    <p class="tjob-title">{{ job.title }}</p>
                    <p class="tjob-industry">{{ job.industry }}</p>
                  </div>
                </div>
                <div class="tjob-right">
                  <span class="tjob-vacancies">{{ job.vacancies }} open</span>
                  <span class="tjob-yours" :class="job.isYours ? 'is-yours' : 'not-yours'">
                    {{ job.isYours ? '● Yours' : '○ Others' }}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- NEW: Skill Gap for Your Listings + Top Applicants by Skill Match -->
        <div class="intel-row">

          <!-- Skill Gap: What You Need vs What Applicants Offer -->
          <div class="card">
            <div class="card-header">
              <div><h3>Skill Gap Analysis</h3><p class="card-sub">Your job requirements vs. applicant skill supply</p></div>
            </div>
            <div class="gaps-chart">
              <div v-for="gap in skillGaps" :key="gap.skill" class="gap-row">
                <span class="gap-label">{{ gap.skill }}</span>
                <div class="gap-bars">
                  <div class="gap-bar-wrap">
                    <div class="gap-bar demand-bar" :style="{ width: gap.required + '%' }"></div>
                    <span class="gap-pct demand-pct">{{ gap.required }}%</span>
                  </div>
                  <div class="gap-bar-wrap">
                    <div class="gap-bar supply-bar" :style="{ width: gap.available + '%' }"></div>
                    <span class="gap-pct supply-pct">{{ gap.available }}%</span>
                  </div>
                </div>
                <span class="gap-delta" :class="gap.required > gap.available ? 'gap-neg' : 'gap-pos'">
                  {{ gap.required > gap.available ? '−' : '+' }}{{ Math.abs(gap.required - gap.available) }}%
                </span>
              </div>
            </div>
            <div class="gaps-legend">
              <div class="gap-legend-item"><span class="gap-legend-dot demand-dot"></span> Required by Your Jobs</div>
              <div class="gap-legend-item"><span class="gap-legend-dot supply-dot"></span> Available in Applicants</div>
            </div>
          </div>

          <!-- Top Applicants by Skill Match for Your Jobs -->
          <div class="card">
            <div class="card-header">
              <div><h3>Top Applicants by Skill Match</h3><p class="card-sub">Best-fit applicants for your active job listings</p></div>
            </div>
            <div class="match-list">
              <div v-for="applicant in topMatchApplicants" :key="applicant.name" class="match-item">
                <div class="match-avatar" :style="{ background: applicant.color }">{{ applicant.name[0] }}</div>
                <div class="match-info">
                  <div class="match-name-row">
                    <span class="match-name">{{ applicant.name }}</span>
                    <span class="match-score-badge" :class="matchClass(applicant.score)">{{ applicant.score }}% match</span>
                  </div>
                  <p class="match-target">Best for: <strong>{{ applicant.bestFor }}</strong></p>
                  <div class="match-tags">
                    <span v-for="tag in applicant.skills" :key="tag" class="match-tag">{{ tag }}</span>
                  </div>
                </div>
                <div class="match-ring">
                  <svg width="40" height="40" viewBox="0 0 40 40">
                    <circle cx="20" cy="20" r="16" fill="none" stroke="#f1f5f9" stroke-width="4"/>
                    <circle cx="20" cy="20" r="16" fill="none" :stroke="applicant.color" stroke-width="4"
                      :stroke-dasharray="(applicant.score / 100) * 100.5 + ' 100.5'"
                      stroke-dashoffset="25" stroke-linecap="round"/>
                  </svg>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Bottom Row -->
        <div class="bottom-row">
          <div class="card table-card">
            <div class="card-header">
              <div><h3>Recent Applicants</h3><p class="card-sub">Latest applications to your job listings</p></div>
              <a href="#" class="see-all">See All</a>
            </div>
            <table class="data-table">
              <thead><tr><th>Applicant</th><th>Skills</th><th>Applied For</th><th>Date</th><th>Status</th></tr></thead>
              <tbody>
                <tr v-for="a in recentApplicants" :key="a.name">
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

          <div class="card jobs-card">
            <div class="card-header"><h3>Active Listings</h3><a href="#" class="see-all">See All</a></div>
            <div class="jobs-list">
              <div v-for="job in activeJobs" :key="job.title" class="job-item">
                <div class="job-icon" :style="{ background: job.bg }">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" :stroke="job.color" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
                </div>
                <div class="job-info">
                  <p class="job-title">{{ job.title }}</p>
                  <p class="job-meta">{{ job.applicants }} applicants · {{ job.slots }} slots</p>
                </div>
                <div class="job-fill">
                  <div class="fill-bar">
                    <div class="fill-inner" :style="{ width: (job.applicants/job.slots*100)+'%', background: job.color }"></div>
                  </div>
                  <span class="fill-pct" :style="{ color: job.color }">{{ Math.round(job.applicants/job.slots*100) }}%</span>
                </div>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>

<script>
import api from '@/services/api'
import EmployerSidebar from '@/components/EmployerSidebar.vue'
import EmployerTopbar from '@/components/EmployerTopbar.vue'

export default {
  name: 'EmployerDashboard',
  components: { EmployerSidebar, EmployerTopbar },
  async mounted() {
    try {
      const { data } = await api.get('/employer/dashboard')
      const d = data.data

      // Merge stat values — preserve icon/iconBg/iconColor
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

      // Chart — structure matches
      if (d.monthlyChart?.length)  this.chartData = d.monthlyChart

      // Funnel — preserve color, merge counts
      if (d.funnelStages?.length) {
        this.funnelStages = d.funnelStages.map((s, i) => ({
          ...this.funnelStages[i] || this.funnelStages[0],
          label: s.label,
          count: s.count,
        }))
      }

      // Skills — merge count, keep color
      if (d.trendingSkills?.length) {
        this.trendingSkills = d.trendingSkills.map((s, i) => ({
          ...this.trendingSkills[i] || this.trendingSkills[0],
          name:       s.name,
          applicants: s.applicants || s.count || 0,
        }))
      }

      // Trending jobs — merge, keep bg/color/icon
      if (d.trendingJobs?.length) {
        this.trendingJobs = d.trendingJobs.map((j, i) => ({
          ...this.trendingJobs[i] || this.trendingJobs[0],
          title:    j.title,
          industry: j.industry,
          vacancies:j.vacancies,
        }))
      }

      // Skill gaps — structure matches
      if (d.skillGaps?.length)          this.skillGaps          = d.skillGaps

      // Top match applicants — merge, add color from index
      if (d.topMatchApplicants?.length) {
        const colors = ['#2563eb','#8b5cf6','#d946ef','#22c55e','#2872A1']
        this.topMatchApplicants = d.topMatchApplicants.map((a, i) => ({
          ...a,
          color: a.color || colors[i % colors.length],
        }))
      }

      // Recent applicants — add color & statusClass
      if (d.recentApplicants?.length) {
        const colors = ['#2563eb','#f97316','#8b5cf6','#22c55e','#06b6d4']
        this.recentApplicants = d.recentApplicants.map((a, i) => ({
          ...a,
          color:       a.color || colors[i % colors.length],
          statusClass: (a.status || '').toLowerCase().replace(/\s+/g, ''),
        }))
      }

      // Active jobs — preserve bg/color, merge counts
      if (d.activeJobs?.length) {
        const colors = [['#eff6ff','#2563eb'],['#faf5ff','#8b5cf6'],['#fdf4ff','#d946ef'],['#f0fdf4','#22c55e'],['#eff8ff','#2872A1']]
        this.activeJobs = d.activeJobs.map((j, i) => ({
          ...j,
          bg:    (this.activeJobs[i] || {}).bg    || colors[i % colors.length][0],
          color: (this.activeJobs[i] || {}).color || colors[i % colors.length][1],
        }))
      }
    } catch (e) { console.error(e) }
  },
  data() {
    return {
      stats: [
        { label: 'Total Applicants',   value: '142', sub: '+8 new today',         iconBg: '#eff8ff', iconColor: '#2872A1', trendVal: '14%', trendUp: true,  icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>` },
        { label: 'Active Job Listings',value: '7',   sub: '3 closing soon',        iconBg: '#eff6ff', iconColor: '#2563eb', trendVal: '2',   trendUp: true,  icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>` },
        { label: 'Hired This Month',   value: '12',  sub: '+4 vs last month',      iconBg: '#f0fdf4', iconColor: '#22c55e', trendVal: '25%', trendUp: true,  icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>` },
        { label: 'Pending Review',     value: '28',  sub: 'Awaiting your action',  iconBg: '#dbeafe', iconColor: '#1a5f8a', trendVal: '5%',  trendUp: false, icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>` },
      ],
      chartData: [
        { label: 'Jan', applications: 18, hired: 3 }, { label: 'Feb', applications: 24, hired: 5 },
        { label: 'Mar', applications: 31, hired: 7 }, { label: 'Apr', applications: 22, hired: 4 },
        { label: 'May', applications: 40, hired: 9 }, { label: 'Jun', applications: 35, hired: 8 },
        { label: 'Jul', applications: 48, hired: 11 },{ label: 'Aug', applications: 38, hired: 8 },
        { label: 'Sep', applications: 42, hired: 10 },{ label: 'Oct', applications: 55, hired: 12 },
        { label: 'Nov', applications: 60, hired: 14 },{ label: 'Dec', applications: 68, hired: 15 },
      ],
      gridLines: [
        { y: 14, label: '70' }, { y: 44, label: '55' }, { y: 74, label: '40' },
        { y: 104, label: '25' }, { y: 134, label: '10' }, { y: 158, label: '0' },
      ],
      funnelStages: [
        { label: 'Applications Received', count: 142, color: '#2872A1' },
        { label: 'Reviewed',              count: 98,  color: '#3b82f6' },
        { label: 'Shortlisted',           count: 54,  color: '#8b5cf6' },
        { label: 'Interviewed',           count: 28,  color: '#06b6d4' },
        { label: 'Hired',                 count: 12,  color: '#22c55e' },
      ],
      // NEW: Trending skills relevant to IT/tech employer
      trendingSkills: [
        { name: 'Vue.js / React',       applicants: 88,  change: '28%', up: true,  color: '#2872A1', hasListing: true },
        { name: 'Laravel / Node.js',    applicants: 74,  change: '19%', up: true,  color: '#6366f1', hasListing: true },
        { name: 'UI/UX Design',         applicants: 61,  change: '22%', up: true,  color: '#8b5cf6', hasListing: true },
        { name: 'DevOps / CI/CD',       applicants: 48,  change: '15%', up: true,  color: '#06b6d4', hasListing: false },
        { name: 'Data Analytics',       applicants: 39,  change: '31%', up: true,  color: '#10b981', hasListing: false },
        { name: 'Project Management',   applicants: 34,  change: '4%',  up: false, color: '#f59e0b', hasListing: true },
      ],
      // NEW: Trending jobs in the market vs employer's listings
      trendingJobs: [
        { title: 'Frontend Developer',  industry: 'IT / Tech',      vacancies: 68, isYours: true,  bg: '#eff6ff', color: '#2563eb', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>` },
        { title: 'Backend Developer',   industry: 'IT / Tech',      vacancies: 55, isYours: true,  bg: '#faf5ff', color: '#8b5cf6', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>` },
        { title: 'UI/UX Designer',      industry: 'IT / Design',    vacancies: 42, isYours: true,  bg: '#fdf4ff', color: '#d946ef', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="4"/></svg>` },
        { title: 'DevOps Engineer',     industry: 'IT / Cloud',     vacancies: 38, isYours: false, bg: '#ecfdf5', color: '#10b981', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="2" width="20" height="8" rx="2"/><rect x="2" y="14" width="20" height="8" rx="2"/></svg>` },
        { title: 'Project Manager',     industry: 'IT / Management',vacancies: 30, isYours: true,  bg: '#eff8ff', color: '#2872A1', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>` },
        { title: 'Data Analyst',        industry: 'IT / Data',      vacancies: 27, isYours: false, bg: '#fff7ed', color: '#f97316', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>` },
      ],
      // NEW: Skill gaps for employer's specific job requirements
      skillGaps: [
        { skill: 'Vue.js / React',    required: 85, available: 62 },
        { skill: 'DevOps / CI/CD',    required: 70, available: 38 },
        { skill: 'TypeScript',        required: 75, available: 55 },
        { skill: 'UI/UX Design',      required: 65, available: 60 },
        { skill: 'Project Mgmt',      required: 55, available: 52 },
        { skill: 'Laravel',           required: 80, available: 70 },
      ],
      // NEW: Top applicants matched to employer's active job listings
      topMatchApplicants: [
        { name: 'Maria Santos',   color: '#2563eb', score: 96, bestFor: 'Frontend Developer',  skills: ['Vue.js', 'TypeScript', 'Tailwind'] },
        { name: 'Juan dela Cruz', color: '#8b5cf6', score: 93, bestFor: 'Backend Developer',   skills: ['Laravel', 'MySQL', 'REST API'] },
        { name: 'Ana Reyes',      color: '#d946ef', score: 89, bestFor: 'UI/UX Designer',       skills: ['Figma', 'Prototyping', 'Adobe XD'] },
        { name: 'Pedro Lim',      color: '#22c55e', score: 85, bestFor: 'Project Manager',      skills: ['Agile', 'Jira', 'Team Lead'] },
        { name: 'Rosa Garcia',    color: '#2872A1', score: 81, bestFor: 'Frontend Developer',  skills: ['React', 'CSS', 'Git'] },
      ],
      recentApplicants: [
        { name: 'Maria Santos',   location: 'Quezon City', skill: 'Vue.js',  job: 'Frontend Dev',  date: 'Dec 08', status: 'Shortlisted', statusClass: 'shortlisted', color: '#2563eb' },
        { name: 'Juan dela Cruz', location: 'Marikina',    skill: 'Laravel', job: 'Backend Dev',   date: 'Dec 08', status: 'Reviewing',   statusClass: 'reviewing',   color: '#f97316' },
        { name: 'Ana Reyes',      location: 'Pasig',       skill: 'UI/UX',   job: 'Designer',      date: 'Dec 07', status: 'Interview',   statusClass: 'interview',   color: '#8b5cf6' },
        { name: 'Pedro Lim',      location: 'Caloocan',    skill: 'React',   job: 'Frontend Dev',  date: 'Dec 07', status: 'Hired',       statusClass: 'hired',       color: '#22c55e' },
        { name: 'Rosa Garcia',    location: 'Taguig',      skill: 'Node.js', job: 'Backend Dev',   date: 'Dec 06', status: 'Reviewing',   statusClass: 'reviewing',   color: '#06b6d4' },
      ],
      activeJobs: [
        { title: 'Frontend Developer', applicants: 38, slots: 50, bg: '#eff6ff', color: '#2563eb' },
        { title: 'Backend Developer',  applicants: 29, slots: 40, bg: '#faf5ff', color: '#8b5cf6' },
        { title: 'UI/UX Designer',     applicants: 22, slots: 30, bg: '#fdf4ff', color: '#d946ef' },
        { title: 'DevOps Engineer',    applicants: 14, slots: 20, bg: '#f0fdf4', color: '#22c55e' },
        { title: 'Project Manager',    applicants: 18, slots: 25, bg: '#eff8ff', color: '#2872A1' },
      ],
    }
  },
  computed: {
    totalApplications() { return this.chartData.reduce((s, d) => s + d.applications, 0) },
    totalHired()        { return this.chartData.reduce((s, d) => s + d.hired, 0) },
    hireRate()          { return Math.round(this.totalHired / this.totalApplications * 100) },
    funnelMax()         { return Math.max(...this.funnelStages.map(s => s.count)) },
    conversionRate()    { return Math.round(this.funnelStages[this.funnelStages.length - 1].count / this.funnelStages[0].count * 100) },
    appPoints()         { return this.chartData.map((d, i) => ({ x: this.getX(i), y: this.valToY(d.applications) })) },
    hiredPoints()       { return this.chartData.map((d, i) => ({ x: this.getX(i), y: this.valToY(d.hired) })) },
    appLine()           { return this.buildPath(this.appPoints) },
    hiredLine()         { return this.buildPath(this.hiredPoints) },
    appArea()           { const p = this.appPoints;   return this.buildPath(p) + ` L${p[p.length-1].x},158 L${p[0].x},158 Z` },
    hiredArea()         { const p = this.hiredPoints; return this.buildPath(p) + ` L${p[p.length-1].x},158 L${p[0].x},158 Z` },
  },
  methods: {
    getX(i)   { return 50 + i * (560 / (this.chartData.length - 1)) },
    valToY(v) { return 158 - (v / 75) * 144 },
    buildPath(pts) {
      if (!pts.length) return ''
      let d = `M${pts[0].x},${pts[0].y}`
      for (let i = 1; i < pts.length; i++) {
        const cpx = (pts[i-1].x + pts[i].x) / 2
        d += ` C${cpx},${pts[i-1].y} ${cpx},${pts[i].y} ${pts[i].x},${pts[i].y}`
      }
      return d
    },
    matchClass(score) { return score >= 90 ? 'match-excellent' : score >= 80 ? 'match-good' : 'match-ok' },
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
.layout-wrapper { display: flex; height: 100vh; overflow: hidden; background: #f8fafc; font-family: 'Plus Jakarta Sans', sans-serif; }
.main-area { flex: 1; display: flex; flex-direction: column; min-height: 0; overflow: hidden; }
.page { flex: 1; overflow-y: auto; padding: 24px; display: flex; flex-direction: column; gap: 16px; min-height: 0; }

.stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; }
.stat-card { background: #fff; border-radius: 14px; padding: 18px; border: 1px solid #f1f5f9; }
.stat-top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.stat-icon { width: 42px; height: 42px; border-radius: 12px; display: flex; align-items: center; justify-content: center; }
.trend { font-size: 12px; font-weight: 700; padding: 4px 8px; border-radius: 99px; }
.trend.up { color: #22c55e; background: #f0fdf4; }
.trend.down { color: #ef4444; background: #fef2f2; }
.stat-value { font-size: 26px; font-weight: 800; color: #1e293b; line-height: 1.1; margin-bottom: 4px; }
.stat-label { font-size: 12.5px; color: #64748b; font-weight: 500; margin-bottom: 4px; }
.stat-sub { font-size: 11px; color: #94a3b8; }

.mid-row { display: grid; grid-template-columns: 1fr 260px; gap: 14px; }
.card { background: #fff; border-radius: 14px; padding: 18px; border: 1px solid #f1f5f9; }
.card-header { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 16px; }
.card-header h3 { font-size: 14px; font-weight: 700; color: #1e293b; }
.card-sub { font-size: 11px; color: #94a3b8; margin-top: 2px; }
.legend { display: flex; align-items: center; gap: 14px; font-size: 11.5px; color: #64748b; flex-wrap: wrap; }
.legend-item { display: flex; align-items: center; gap: 6px; }
.legend-line { display: inline-block; width: 22px; height: 3px; border-radius: 2px; }
.legend-line.amber { background: #2872A1; }
.legend-line.green { background: #22c55e; }
.svg-chart-wrap { width: 100%; overflow: hidden; }
.svg-chart { width: 100%; height: 185px; display: block; }
.chart-summary { display: flex; align-items: center; margin-top: 14px; padding-top: 14px; border-top: 1px solid #f1f5f9; }
.summary-item { display: flex; align-items: center; gap: 6px; flex: 1; justify-content: center; }
.summary-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.amber-dot { background: #2872A1; }
.green-dot { background: #22c55e; }
.summary-label { font-size: 11px; color: #94a3b8; }
.summary-val { font-size: 13px; font-weight: 700; color: #1e293b; margin-left: 2px; }
.amber-val { color: #2872A1; }
.green-val { color: #22c55e; }
.summary-divider { width: 1px; height: 28px; background: #f1f5f9; }

.funnel-list { display: flex; flex-direction: column; gap: 14px; }
.funnel-row { display: flex; flex-direction: column; gap: 5px; }
.funnel-label-row { display: flex; justify-content: space-between; align-items: center; }
.funnel-label { font-size: 12px; color: #64748b; font-weight: 500; }
.funnel-count { font-size: 13px; font-weight: 700; }
.funnel-bar-bg { height: 7px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.funnel-bar-fill { height: 100%; border-radius: 99px; transition: width 0.4s ease; }
.funnel-footer { margin-top: 16px; padding-top: 14px; border-top: 1px solid #f1f5f9; }
.funnel-rate { display: flex; justify-content: space-between; align-items: center; }
.funnel-rate-label { font-size: 12px; color: #94a3b8; }
.funnel-rate-val { font-size: 16px; font-weight: 800; color: #22c55e; }

/* INTEL ROWS */
.intel-row { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }

.live-badge { background: #dcfce7; color: #16a34a; font-size: 10px; font-weight: 700; padding: 3px 8px; border-radius: 99px; display: flex; align-items: center; gap: 4px; height: fit-content; white-space: nowrap; }
.live-badge::before { content: ''; width: 6px; height: 6px; background: #16a34a; border-radius: 50%; animation: pulse 1.5s infinite; }
@keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: 0.3; } }

.skill-bars { display: flex; flex-direction: column; gap: 11px; }
.skill-bar-row { display: flex; align-items: center; gap: 10px; }
.skill-rank { font-size: 11px; font-weight: 700; color: #cbd5e1; min-width: 14px; text-align: center; }
.skill-info { flex: 1; }
.skill-name-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px; flex-wrap: wrap; gap: 4px; }
.skill-name { font-size: 12.5px; font-weight: 600; color: #1e293b; }
.skill-count { font-size: 11px; color: #94a3b8; }
.mini-match-badge { font-size: 9.5px; font-weight: 700; padding: 2px 6px; border-radius: 5px; }
.has-listing { background: #dcfce7; color: #16a34a; }
.no-listing  { background: #f1f5f9; color: #94a3b8; }
.skill-track { height: 6px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.skill-fill { height: 100%; border-radius: 99px; }
.mini-trend { font-size: 10.5px; font-weight: 700; padding: 2px 7px; border-radius: 6px; white-space: nowrap; }
.trend-up { background: #f0fdf4; color: #16a34a; }
.trend-down { background: #fef2f2; color: #ef4444; }

.trending-jobs-list { display: flex; flex-direction: column; gap: 8px; }
.trending-job-item { display: flex; align-items: center; justify-content: space-between; padding: 8px 10px; border-radius: 10px; background: #f8fafc; border: 1px solid #f1f5f9; }
.tjob-left { display: flex; align-items: center; gap: 8px; }
.tjob-rank { font-size: 12px; font-weight: 800; min-width: 22px; }
.tjob-icon { width: 30px; height: 30px; border-radius: 8px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.tjob-title { font-size: 12.5px; font-weight: 700; color: #1e293b; }
.tjob-industry { font-size: 10.5px; color: #94a3b8; margin-top: 1px; }
.tjob-right { display: flex; flex-direction: column; align-items: flex-end; gap: 3px; }
.tjob-vacancies { font-size: 11.5px; font-weight: 700; color: #2563eb; }
.tjob-yours { font-size: 10px; font-weight: 700; }
.is-yours  { color: #16a34a; }
.not-yours { color: #94a3b8; }

.gaps-chart { display: flex; flex-direction: column; gap: 12px; margin-bottom: 12px; }
.gap-row { display: flex; align-items: center; gap: 8px; }
.gap-label { font-size: 11.5px; font-weight: 600; color: #475569; min-width: 110px; }
.gap-bars { flex: 1; display: flex; flex-direction: column; gap: 3px; }
.gap-bar-wrap { display: flex; align-items: center; gap: 5px; }
.gap-bar { height: 6px; border-radius: 99px; min-width: 4px; }
.demand-bar { background: #2872A1; }
.supply-bar { background: #22c55e; }
.gap-pct { font-size: 10px; font-weight: 600; min-width: 26px; }
.demand-pct { color: #2872A1; }
.supply-pct { color: #22c55e; }
.gap-delta { font-size: 11px; font-weight: 700; min-width: 36px; text-align: right; }
.gap-neg { color: #ef4444; }
.gap-pos { color: #22c55e; }
.gaps-legend { display: flex; gap: 16px; padding-top: 12px; border-top: 1px solid #f1f5f9; }
.gap-legend-item { display: flex; align-items: center; gap: 6px; font-size: 11.5px; color: #64748b; }
.gap-legend-dot { width: 10px; height: 10px; border-radius: 3px; }
.demand-dot { background: #2872A1; }
.supply-dot { background: #22c55e; }

.match-list { display: flex; flex-direction: column; gap: 10px; }
.match-item { display: flex; align-items: center; gap: 10px; padding: 10px 12px; border-radius: 10px; background: #f8fafc; border: 1px solid #f1f5f9; }
.match-avatar { width: 36px; height: 36px; border-radius: 50%; color: #fff; font-size: 13px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.match-info { flex: 1; min-width: 0; }
.match-name-row { display: flex; align-items: center; justify-content: space-between; margin-bottom: 2px; }
.match-name { font-size: 13px; font-weight: 700; color: #1e293b; }
.match-score-badge { font-size: 10.5px; font-weight: 700; padding: 2px 8px; border-radius: 6px; }
.match-excellent { background: #dcfce7; color: #16a34a; }
.match-good      { background: #dbeafe; color: #2563eb; }
.match-ok        { background: #fff7ed; color: #f97316; }
.match-target { font-size: 11px; color: #64748b; margin-bottom: 5px; }
.match-target strong { color: #1e293b; }
.match-tags { display: flex; flex-wrap: wrap; gap: 4px; }
.match-tag { background: #f1f5f9; color: #475569; font-size: 10.5px; font-weight: 500; padding: 2px 7px; border-radius: 5px; }
.match-ring { flex-shrink: 0; }

.bottom-row { display: grid; grid-template-columns: 1fr 280px; gap: 14px; }
.see-all { font-size: 12px; color: #2872A1; text-decoration: none; font-weight: 600; }
.see-all:hover { text-decoration: underline; }
.data-table { width: 100%; border-collapse: collapse; font-size: 12.5px; }
.data-table th { text-align: left; padding: 8px 10px; color: #94a3b8; font-weight: 600; font-size: 11px; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.data-table td { padding: 10px; color: #1e293b; border-bottom: 1px solid #f8fafc; vertical-align: middle; }
.person-cell { display: flex; align-items: center; gap: 8px; }
.person-avatar { width: 28px; height: 28px; border-radius: 50%; color: #fff; font-size: 11px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.person-name { display: block; font-weight: 600; font-size: 12.5px; color: #1e293b; }
.person-loc { display: block; font-size: 10.5px; color: #94a3b8; }
.skill-tag { background: #f1f5f9; color: #475569; font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
.job-cell { color: #475569; }
.date-cell { color: #94a3b8; white-space: nowrap; }
.status-badge { padding: 3px 10px; border-radius: 99px; font-size: 11px; font-weight: 600; white-space: nowrap; }
.shortlisted { background: #eff8ff; color: #1a5f8a; }
.reviewing   { background: #eff6ff; color: #3b82f6; }
.interview   { background: #faf5ff; color: #8b5cf6; }
.hired       { background: #f0fdf4; color: #22c55e; }
.jobs-list { display: flex; flex-direction: column; gap: 12px; }
.job-item { display: flex; align-items: center; gap: 10px; }
.job-icon { width: 34px; height: 34px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.job-info { flex: 1; min-width: 0; }
.job-title { font-size: 12.5px; font-weight: 600; color: #1e293b; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.job-meta { font-size: 10.5px; color: #94a3b8; margin-top: 2px; }
.job-fill { display: flex; align-items: center; gap: 6px; }
.fill-bar { width: 60px; height: 5px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.fill-inner { height: 100%; border-radius: 99px; }
.fill-pct { font-size: 11px; font-weight: 700; min-width: 28px; text-align: right; }
</style>