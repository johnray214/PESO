<template>
  <div class="layout-wrapper">
    <EmployerSidebar />
    <div class="main-area">
      <EmployerTopbar title="Dashboard" subtitle="Welcome back 👋" />
      <div class="page">
        <!-- SKELETON LOADER -->
        <div v-if="isLoading">
          <div class="period-bar skeleton" style="height: 52px; width: 100%; border-radius: 14px; margin-bottom: 16px;"></div>
          <div class="stats-grid">
            <div v-for="i in 4" :key="i" class="stat-card skeleton" style="height: 120px; border-radius: 14px;"></div>
          </div>
          <div class="mid-row" style="margin-top: 14px;">
            <div class="card chart-card skeleton" style="height: 380px;"></div>
            <div class="card funnel-card skeleton" style="height: 380px;"></div>
          </div>
          <div class="card potential-card skeleton" style="height: 400px; margin-top: 14px;"></div>
          <div class="bottom-row" style="margin-top: 14px;">
            <div class="card table-card skeleton" style="height: 300px;"></div>
            <div class="card jobs-card skeleton" style="height: 300px;"></div>
          </div>
        </div>

        <div v-else>
        <!-- ── PERIOD FILTER BAR ──────────────────────────────────── -->
        <div class="period-bar">
          <div class="period-pills">
            <button
              v-for="p in periodOptions" :key="p.value"
              :class="['period-pill', { active: activePeriod === p.value }]"
              @click="setPeriod(p.value)"
            >{{ p.label }}</button>
          </div>
          <transition name="fade-slide">
            <div v-if="activePeriod === 'custom'" class="custom-range">
              <input type="date" v-model="customFrom" class="date-input" :max="customTo || undefined"/>
              <span class="date-sep">→</span>
              <input type="date" v-model="customTo" class="date-input" :min="customFrom || undefined"/>
              <button class="apply-btn" :disabled="!customFrom || !customTo" @click="fetchDashboard">Apply</button>
            </div>
          </transition>
          <span v-if="lastUpdated" class="last-updated">Updated {{ lastUpdated }}</span>
        </div>

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
              <div>
                <h3>Applications Over Time</h3>
                <p class="card-sub">Monthly applications received — {{ chartSubLabel }}</p>
              </div>
              <div class="legend">
                <span class="legend-item"><span class="legend-line amber"></span> Applications</span>
                <span class="legend-item"><span class="legend-line green"></span> Hired</span>
              </div>
            </div>

            <div class="svg-chart-wrap" ref="appWrap">
              <transition name="tip">
                <div v-if="appTip" class="chart-tooltip" :style="{ left: appTip.x+'px', top: appTip.y+'px' }">
                  <div class="tooltip-label">{{ appTip.label }}</div>
                  <div class="tooltip-row"><span class="tooltip-dot" style="background:#2872A1"></span>Applications<strong>{{ appTip.applications }}</strong></div>
                  <div class="tooltip-row"><span class="tooltip-dot" style="background:#22c55e"></span>Hired<strong>{{ appTip.hired }}</strong></div>
                </div>
              </transition>

              <svg ref="appSvg"
                   viewBox="0 0 620 180" preserveAspectRatio="xMidYMid meet" class="svg-chart"
                   @mousemove="onAppMove" @mouseleave="appTip = null">
                <defs>
                  <linearGradient id="gradAmber" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="#2872A1" stop-opacity="0.18"/>
                    <stop offset="100%" stop-color="#2872A1" stop-opacity="0"/>
                  </linearGradient>
                  <linearGradient id="gradGreen" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="#22c55e" stop-opacity="0.15"/>
                    <stop offset="100%" stop-color="#22c55e" stop-opacity="0"/>
                  </linearGradient>
                  <clipPath id="appClip">
                    <rect x="50" y="0" height="160"
                          :width="appAnimated ? 560 : 0"
                          :style="{ transition: 'width 1.2s cubic-bezier(.4,0,.2,1)' }"/>
                  </clipPath>
                </defs>

                <line v-for="(gl,i) in dynamicGridLines" :key="'g'+i"
                      :x1="50" :y1="gl.y" :x2="610" :y2="gl.y" stroke="#f1f5f9" stroke-width="1"/>
                <text v-for="(gl,i) in dynamicGridLines" :key="'yl'+i"
                      :x="44" :y="gl.y+4" text-anchor="end" font-size="9"
                      fill="#cbd5e1" font-family="Plus Jakarta Sans, sans-serif">{{ gl.label }}</text>

                <g clip-path="url(#appClip)">
                  <path :d="appArea"   fill="url(#gradAmber)"/>
                  <path :d="hiredArea" fill="url(#gradGreen)"/>
                  <path :d="appLine"   fill="none" stroke="#2872A1" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                  <path :d="hiredLine" fill="none" stroke="#22c55e" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                </g>

                <line v-if="appTip"
                      :x1="getX(appTip.i)" y1="14" :x2="getX(appTip.i)" y2="158"
                      stroke="#1e293b" stroke-width="1" stroke-dasharray="3 3" pointer-events="none" opacity="0.3"/>

                <circle v-for="(pt,i) in appPoints" :key="'ad'+i"
                        :cx="pt.x" :cy="pt.y"
                        :r="appTip && appTip.i===i ? 5.5 : 3.5"
                        fill="#fff" stroke="#2872A1" stroke-width="2"
                        pointer-events="none" style="transition:r 0.12s ease"/>
                <circle v-for="(pt,i) in hiredPoints" :key="'hd'+i"
                        :cx="pt.x" :cy="pt.y"
                        :r="appTip && appTip.i===i ? 5.5 : 3.5"
                        fill="#fff" stroke="#22c55e" stroke-width="2"
                        pointer-events="none" style="transition:r 0.12s ease"/>

                <text v-for="(m,i) in chartData" :key="'xl'+i"
                      :x="getX(i)" :y="173" text-anchor="middle" font-size="9"
                      fill="#94a3b8" font-family="Plus Jakarta Sans, sans-serif">{{ m.label }}</text>

                <rect v-for="(m,i) in chartData" :key="'hit'+i"
                      :x="getX(i) - colW/2" y="0" :width="colW" height="165"
                      fill="transparent" style="cursor:crosshair"/>
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

          <!-- Hiring Funnel -->
          <div class="card funnel-card">
            <div class="card-header">
              <div><h3>Hiring Funnel</h3><p class="card-sub">{{ chartSubLabel }}</p></div>
            </div>
            <div class="funnel-list">
              <div v-for="(stage,i) in funnelStages" :key="stage.label" class="funnel-row">
                <div class="funnel-label-row">
                  <span class="funnel-label">{{ stage.label }}</span>
                  <span class="funnel-count" :style="{ color: stage.color }">{{ stage.count }}</span>
                </div>
                <div class="funnel-bar-bg">
                  <div class="funnel-bar-fill"
                       :style="{
                         width: funnelAnimated ? (stage.count / Math.max(funnelMax,1) * 100)+'%' : '0%',
                         background: stage.color,
                         opacity: 1 - i*0.12,
                         transitionDelay: (i*0.08)+'s'
                       }"></div>
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

        <!-- Potential Applicants Table -->
        <div class="card potential-card">
          <div class="card-header potential-header">
            <div>
              <h3>
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2.5" style="margin-right:6px;vertical-align:-2px"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
                Potential Applicants
              </h3>
              <p class="card-sub">Registered jobseekers whose skills match your job listings — but haven't applied yet</p>
            </div>
            <div class="potential-header-right">
              <div class="potential-controls">
                <div class="search-box">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
                  <input v-model="potentialSearch" @input="resetPotentialPage" type="text" placeholder="Search by name or skill..." class="search-input"/>
                </div>
                <select v-model="potentialJobFilter" @change="resetPotentialPage" class="filter-select">
                  <option value="">All Job Listings</option>
                  <option v-for="j in activeJobs" :key="j.title" :value="j.title">{{ j.title }}</option>
                </select>
              </div>
              <router-link to="/employer/applicants?tab=potential" class="see-all-btn">
                See All
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"/></svg>
              </router-link>
            </div>
          </div>

          <div class="listing-tabs">
            <button class="listing-tab" :class="{ active: potentialJobFilter==='' }" @click="potentialJobFilter=''; resetPotentialPage()">
              All <span class="tab-count">{{ topMatchApplicants.length }}</span>
            </button>
            <button v-for="j in activeJobs" :key="j.title" class="listing-tab"
                    :class="{ active: potentialJobFilter===j.title }"
                    @click="potentialJobFilter=j.title; resetPotentialPage()"
                    :style="potentialJobFilter===j.title ? { borderColor:j.color, color:j.color, background:j.bg } : {}">
              {{ j.title }}
              <span class="tab-count" :style="potentialJobFilter===j.title ? { background:j.color, color:'#fff' } : {}">
                {{ topMatchApplicants.filter(a=>a.bestFor===j.title).length }}
              </span>
            </button>
          </div>

          <table class="potential-table">
            <thead>
              <tr>
                <th style="width:220px">Jobseeker</th>
                <th>Matched Skills</th>
                <th style="width:190px">Matches Your Listing</th>
                <th style="width:160px">Skill Match Score</th>
                <th style="width:130px">Location</th>
                <th style="width:110px">Status</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(a,ri) in pagedPotential" :key="a.name"
                  class="potential-row table-row-anim"
                  :style="{ animationDelay: (ri*0.05)+'s' }">
                <td>
                  <div class="person-cell">
                    <div class="pot-avatar" :style="{ background: a.color }">{{ a.name[0] }}</div>
                    <div>
                      <span class="person-name">{{ a.name }}</span>
                      <span class="person-loc">{{ a.education }}</span>
                    </div>
                  </div>
                </td>
                <td>
                  <div class="skill-tag-group">
                    <span v-for="tag in a.skills" :key="tag" class="skill-tag matched-tag">{{ tag }}</span>
                  </div>
                </td>
                <td>
                  <div class="listing-match-cell">
                    <div class="listing-color-bar" :style="{ background: a.jobColor }"></div>
                    <div>
                      <p class="listing-title">{{ a.bestFor }}</p>
                      <p class="listing-hint">Active listing</p>
                    </div>
                  </div>
                </td>
                <td>
                  <div class="score-cell">
                    <div class="score-track">
                      <div class="score-fill"
                           :style="{
                             width: scoreAnimated ? a.score+'%' : '0%',
                             background: scoreColor(a.score),
                             transitionDelay: (ri*0.06)+'s'
                           }"></div>
                    </div>
                    <span class="score-num" :style="{ color: scoreColor(a.score) }">{{ a.score }}%</span>
                  </div>
                </td>
                <td>
                  <div class="loc-cell">
                    <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                    {{ a.location }}
                  </div>
                </td>
                <td>
                  <span class="not-applied-badge"><span class="na-dot"></span>Not Applied</span>
                </td>
              </tr>
              <tr v-if="filteredPotential.length===0">
                <td colspan="6" class="empty-row">
                  <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.5" style="display:block;margin:0 auto 8px"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                  No jobseekers found matching your current filters.
                </td>
              </tr>
            </tbody>
          </table>

          <div class="table-footer">
            <span class="table-count">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
              Showing {{ Math.min((potentialPage-1)*potentialPerPage+1, Math.max(filteredPotential.length,1)) }}–{{ Math.min(potentialPage*potentialPerPage, filteredPotential.length) }} of {{ filteredPotential.length }} jobseekers
            </span>
            <div class="pot-pagination">
              <button class="pot-page-btn" :disabled="potentialPage===1" @click="potentialPage--">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="15 18 9 12 15 6"/></svg>
              </button>
              <button v-for="p in potentialTotalPages" :key="p" class="pot-page-btn" :class="{ 'pot-page-active': potentialPage===p }" @click="potentialPage=p">{{ p }}</button>
              <button class="pot-page-btn" :disabled="potentialPage===potentialTotalPages" @click="potentialPage++">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 18 15 12 9 6"/></svg>
              </button>
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
                <tr v-for="(a,i) in recentApplicants" :key="a.name"
                    class="table-row-anim" :style="{ animationDelay: (i*0.06)+'s' }">
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
                <tr v-if="!recentApplicants.length">
                  <td colspan="5" class="empty-row">No recent applicants yet.</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="card jobs-card">
            <div class="card-header"><h3>Active Listings</h3><a href="#" class="see-all">See All</a></div>
            <div class="jobs-list">
              <div v-for="(job,i) in activeJobs" :key="job.title"
                   class="job-item slide-in-right" :style="{ animationDelay: (i*0.07)+'s' }">
                <div class="job-icon" :style="{ background: job.bg }">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" :stroke="job.color" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
                </div>
                <div class="job-info">
                  <p class="job-title">{{ job.title }}</p>
                  <p class="job-meta">{{ job.applicants }} applicants · {{ job.slots }} slots</p>
                </div>
                <div class="job-fill">
                  <div class="fill-bar">
                    <div class="fill-inner"
                         :style="{
                           width: jobsAnimated ? Math.min(job.applicants/Math.max(job.slots,1)*100,100)+'%' : '0%',
                           background: job.color,
                           transitionDelay: (i*0.08)+'s'
                         }"></div>
                  </div>
                  <span class="fill-pct" :style="{ color: job.color }">{{ Math.round(job.applicants/Math.max(job.slots,1)*100) }}%</span>
                </div>
              </div>
              <div v-if="!activeJobs.length" class="empty-row" style="padding:24px;text-align:center;color:#94a3b8;font-size:13px;">
                No active listings yet.
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
import employerApi from '@/services/employerApi'
import EmployerSidebar from '@/components/EmployerSidebar.vue'
import EmployerTopbar  from '@/components/EmployerTopbar.vue'

export default {
  name: 'EmployerDashboard',
  components: { EmployerSidebar, EmployerTopbar },

  data() {
    return {
      isLoading: true,
      // ── Period filter ─────────────────────────────────────────────
      activePeriod: 'monthly',
      customFrom: '',
      customTo: '',
      lastUpdated: null,
      periodOptions: [
        { value: 'weekly',  label: 'Weekly'  },
        { value: 'monthly', label: 'Monthly' },
        { value: 'yearly',  label: 'Yearly'  },
        { value: 'custom',  label: 'Custom'  },
      ],

      // ── Stats ─────────────────────────────────────────────────────
      stats: [
        { label: 'Total Applicants',    value: '0', sub: '—', iconBg: '#eff8ff', iconColor: '#2872A1', trendVal: '0%', trendUp: true,
          icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>` },
        { label: 'Active Job Listings', value: '0', sub: '—', iconBg: '#eff6ff', iconColor: '#2563eb', trendVal: '0',   trendUp: true,
          icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>` },
        { label: 'Hired This Period',   value: '0', sub: '—', iconBg: '#f0fdf4', iconColor: '#22c55e', trendVal: '0%', trendUp: true,
          icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>` },
        { label: 'Pending Review',      value: '0', sub: '—', iconBg: '#dbeafe', iconColor: '#1a5f8a', trendVal: '0%', trendUp: false,
          icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>` },
      ],

      chartData: [],

      funnelStages: [
        { label: 'Applications Received', count: 0, color: '#2872A1' },
        { label: 'Reviewed',              count: 0, color: '#3b82f6' },
        { label: 'Shortlisted',           count: 0, color: '#8b5cf6' },
        { label: 'Interviewed',           count: 0, color: '#06b6d4' },
        { label: 'Hired',                 count: 0, color: '#22c55e' },
      ],

      topMatchApplicants: [],
      potentialSearch:    '',
      potentialJobFilter: '',
      potentialPage:      1,
      potentialPerPage:   5,

      recentApplicants: [],
      activeJobs:       [],

      // ── animation flags ──────────────────────────────────────────
      appAnimated:    false,
      funnelAnimated: false,
      scoreAnimated:  false,
      jobsAnimated:   false,

      appTip: null,
    }
  },

  async mounted() {
    await this.fetchDashboard()
  },

  computed: {
    // ── Period label ──────────────────────────────────────────────
    chartSubLabel() {
      const map = {
        weekly:  'This week',
        monthly: `${new Date().getFullYear()}`,
        yearly:  'Last 5 years',
        custom:  'Custom range',
      }
      return map[this.activePeriod] || ''
    },

    // ── Chart helpers ─────────────────────────────────────────────
    chartMax()  { return Math.max(...this.chartData.flatMap(d => [d.applications, d.hired]), 1) },
    chartNice() { return this.niceMax(this.chartMax) },

    dynamicGridLines() {
      const steps = 5
      return Array.from({ length: steps+1 }, (_,i) => ({
        y:     14 + (i/steps)*144,
        label: Math.round((this.chartNice/steps) * (steps-i)),
      }))
    },

    colW() { return 560 / Math.max(this.chartData.length-1, 1) },

    totalApplications() { return this.chartData.reduce((s,d) => s+d.applications, 0) },
    totalHired()        { return this.chartData.reduce((s,d) => s+d.hired, 0) },
    hireRate()          { return this.totalApplications ? Math.round(this.totalHired/this.totalApplications*100) : 0 },

    appPoints()   { return this.chartData.map((d,i) => ({ x:this.getX(i), y:this.valToY(d.applications) })) },
    hiredPoints() { return this.chartData.map((d,i) => ({ x:this.getX(i), y:this.valToY(d.hired)        })) },
    appLine()     { return this.buildPath(this.appPoints)   },
    hiredLine()   { return this.buildPath(this.hiredPoints) },
    appArea()     { const p=this.appPoints;   return p.length ? this.buildPath(p)+` L${p[p.length-1].x},158 L${p[0].x},158 Z`:'' },
    hiredArea()   { const p=this.hiredPoints; return p.length ? this.buildPath(p)+` L${p[p.length-1].x},158 L${p[0].x},158 Z`:'' },

    // ── Funnel ────────────────────────────────────────────────────
    funnelMax()      { return Math.max(...this.funnelStages.map(s=>s.count), 1) },
    conversionRate() {
      const top = this.funnelStages[0].count
      const bot = this.funnelStages[this.funnelStages.length-1].count
      return top ? Math.round(bot/top*100) : 0
    },

    // ── Potential applicants ──────────────────────────────────────
    filteredPotential() {
      let list = [...this.topMatchApplicants]
      if (this.potentialSearch) {
        const q = this.potentialSearch.toLowerCase()
        list = list.filter(a =>
          a.name.toLowerCase().includes(q) ||
          a.skills.some(s => s.toLowerCase().includes(q)) ||
          a.bestFor.toLowerCase().includes(q)
        )
      }
      if (this.potentialJobFilter) list = list.filter(a => a.bestFor===this.potentialJobFilter)
      return list.sort((a,b) => b.score-a.score)
    },
    potentialTotalPages() { return Math.max(Math.ceil(this.filteredPotential.length/this.potentialPerPage), 1) },
    pagedPotential() {
      const start = (this.potentialPage-1)*this.potentialPerPage
      return this.filteredPotential.slice(start, start+this.potentialPerPage)
    },
  },

  methods: {
    // ── Period control ────────────────────────────────────────────
    setPeriod(p) {
      this.activePeriod = p
      if (p !== 'custom') this.fetchDashboard()
    },

    // ── Fetch ─────────────────────────────────────────────────────
    async fetchDashboard() {
      try {
        const params = { period: this.activePeriod }
        if (this.activePeriod === 'custom') {
          params.from = this.customFrom
          params.to   = this.customTo
        }

        const { data } = await employerApi.getDashboard(params)
        const d = data.data

        if (d?.stats) {
          const periodLabel = this.chartSubLabel
          this.stats[0].value   = String(d.stats.total_applications || 0)
          this.stats[0].sub     = periodLabel
          this.stats[0].trendVal = (d.stats.trends?.applications ?? '0') + '%'
          this.stats[0].trendUp  = (d.stats.trends?.applications ?? 0) >= 0

          this.stats[1].value   = String(d.stats.open_jobs || 0)
          this.stats[1].sub     = periodLabel
          this.stats[1].trendVal = String(d.stats.trends?.jobs ?? '0')
          this.stats[1].trendUp  = (d.stats.trends?.jobs ?? 0) >= 0

          this.stats[2].value   = String(d.stats.application_status_counts?.hired || 0)
          this.stats[2].sub     = periodLabel
          this.stats[2].trendVal = (d.stats.trends?.hired ?? '0') + '%'
          this.stats[2].trendUp  = (d.stats.trends?.hired ?? 0) >= 0

          this.stats[3].value   = String(d.stats.application_status_counts?.reviewing || 0)
          this.stats[3].sub     = periodLabel
          this.stats[3].trendVal = (d.stats.trends?.reviewing ?? '0') + '%'
          this.stats[3].trendUp  = (d.stats.trends?.reviewing ?? 0) >= 0
        }

        if (d?.chart_data?.length) this.chartData = d.chart_data

        if (d?.active_jobs?.length) {
          const colors = ['#2563eb','#8b5cf6','#d946ef','#22c55e','#2872A1']
          const bgs    = ['#eff6ff','#faf5ff','#fdf4ff','#f0fdf4','#eff8ff']
          this.activeJobs = d.active_jobs.slice(0,5).map((job,i) => ({
            id: job.id, title: job.title,
            applicants: job.applicants, slots: job.slots,
            color: colors[i%colors.length], bg: bgs[i%bgs.length],
          }))
        }

        if (d?.potential_applicants?.length) {
          const colors = ['#2563eb','#8b5cf6','#d946ef','#22c55e','#2872A1','#f97316','#06b6d4','#10b981','#6366f1','#f43f5e']
          this.topMatchApplicants = d.potential_applicants.map((a,i) => ({
            id: a.id, name: a.name,
            color:     colors[i%colors.length],
            score:     a.score,
            bestFor:   a.job_title,
            jobColor:  this.getJobColor(a.job_title),
            skills:    a.skills || [],
            location:  a.location  || 'Unknown',
            education: a.education || 'Not specified',
          }))
        }

        if (d?.recent_applications?.length) {
          const colors = ['#2563eb','#f97316','#8b5cf6','#22c55e','#06b6d4']
          this.recentApplicants = d.recent_applications.slice(0,5).map((a,i) => {
            const js = a.jobseeker || {}
            return {
              name:        js.full_name || 'Unknown',
              location:    js.address   || '',
              skill:       (js.skills||[])[0]?.skill || 'N/A',
              job:         a.job_listing?.title || 'Unknown',
              date:        new Date(a.applied_at).toLocaleDateString('en-US',{ month:'short', day:'2-digit', year:'numeric' }),
              status:      (a.status?.charAt(0).toUpperCase()+a.status?.slice(1)) || 'Reviewing',
              statusClass: a.status?.toLowerCase() || 'reviewing',
              color:       colors[i%colors.length],
            }
          })
        }

        if (d?.stats?.application_status_counts) {
          const c = d.stats.application_status_counts
          this.funnelStages[0].count = d.stats.total_applications || 0
          this.funnelStages[1].count = c.reviewing   || 0
          this.funnelStages[2].count = c.shortlisted || 0
          this.funnelStages[3].count = c.interview   || 0
          this.funnelStages[4].count = c.hired       || 0
        }

        this.lastUpdated = new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })

      } catch (e) {
        console.error('Dashboard fetch error:', e)
      }

      this.isLoading = false
      // Kick off entrance animations
      this.$nextTick(() => {
        setTimeout(() => { this.appAnimated    = true }, 120)
        setTimeout(() => { this.funnelAnimated = true }, 200)
        setTimeout(() => { this.scoreAnimated  = true }, 350)
        setTimeout(() => { this.jobsAnimated   = true }, 280)
      })
    },

    // ── Chart X / Y ──────────────────────────────────────────────
    getX(i)    { return 50 + i*(560/Math.max(this.chartData.length-1,1)) },
    valToY(v)  { return 158 - ((v/this.chartNice)*144) },

    niceMax(raw) {
      if (raw<=0) return 1
      const mag = Math.pow(10, Math.floor(Math.log10(raw)))
      for (const s of [1,2,2.5,5,10]) {
        const c = Math.ceil(raw/(mag*s))*(mag*s)
        if (c>=raw) return c
      }
      return Math.ceil(raw/mag)*mag
    },

    buildPath(pts) {
      if (!pts.length) return ''
      let d = `M${pts[0].x},${pts[0].y}`
      for (let i=1; i<pts.length; i++) {
        const cpx = (pts[i-1].x+pts[i].x)/2
        d += ` C${cpx},${pts[i-1].y} ${cpx},${pts[i].y} ${pts[i].x},${pts[i].y}`
      }
      return d
    },

    _svgPoint(svgEl, clientX, clientY) {
      const pt = svgEl.createSVGPoint()
      pt.x = clientX; pt.y = clientY
      return pt.matrixTransform(svgEl.getScreenCTM().inverse())
    },

    _closestIdx(svgX, count) {
      if (!count) return null
      let best=0, bestDist=Infinity
      for (let i=0; i<count; i++) {
        const dist = Math.abs(svgX-this.getX(i))
        if (dist<bestDist) { bestDist=dist; best=i }
      }
      return bestDist <= this.colW/2+4 ? best : null
    },

    _tipPos(clientX, clientY, wrapEl) {
      const r = wrapEl.getBoundingClientRect()
      let x = clientX-r.left+14
      let y = clientY-r.top-12
      if (x+180>r.width) x = clientX-r.left-188
      if (y<0) y=4
      return { x, y }
    },

    onAppMove(evt) {
      if (!this.chartData.length) return
      const svgPt = this._svgPoint(this.$refs.appSvg, evt.clientX, evt.clientY)
      const idx   = this._closestIdx(svgPt.x, this.chartData.length)
      if (idx===null) { this.appTip=null; return }
      const raw = this.chartData[idx]
      const pos = this._tipPos(evt.clientX, evt.clientY, this.$refs.appWrap)
      this.appTip = {
        i: idx,
        label:        String(raw.label        ?? ''),
        applications: Number(raw.applications ?? 0),
        hired:        Number(raw.hired        ?? 0),
        x: pos.x,
        y: pos.y,
      }
    },

    resetPotentialPage() { this.potentialPage = 1 },
    scoreColor(s) { return s>=90 ? '#16a34a' : s>=80 ? '#2563eb' : '#f97316' },

    getJobColor(title) {
      const map = {
        'Frontend Developer': '#2563eb',
        'Backend Developer':  '#8b5cf6',
        'UI/UX Designer':     '#d946ef',
        'DevOps Engineer':    '#22c55e',
        'Project Manager':    '#2872A1',
      }
      return map[title] || '#2563eb'
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
.layout-wrapper { display: flex; height: 100vh; overflow: hidden; background: #f8fafc; font-family: 'Plus Jakarta Sans', sans-serif; }
.main-area { flex: 1; display: flex; flex-direction: column; min-height: 0; overflow: hidden; }
.page { flex: 1; overflow-y: auto; overflow-x: hidden; padding: 24px; display: flex; flex-direction: column; gap: 16px; min-height: 0; }

/* ── PERIOD FILTER BAR ───────────────────────────────────────────── */
.period-bar {
  display: flex; align-items: center; gap: 12px; flex-wrap: wrap;
  background: #fff; border: 1px solid #f1f5f9; border-radius: 14px;
  padding: 10px 16px;
}
.period-pills { display: flex; gap: 4px; }
.period-pill {
  padding: 6px 16px; border-radius: 8px; border: 1.5px solid #e2e8f0;
  font-size: 12.5px; font-weight: 600; color: #64748b;
  background: #f8fafc; cursor: pointer; font-family: inherit;
  transition: all 0.15s;
}
.period-pill:hover { border-color: #94a3b8; color: #1e293b; }
.period-pill.active { background: #eff8ff; color: #2872A1; border-color: #2872A1; }
.custom-range { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.date-input {
  border: 1.5px solid #e2e8f0; border-radius: 8px;
  padding: 5px 10px; font-size: 12px; color: #1e293b;
  font-family: inherit; outline: none; background: #f8fafc;
  transition: border-color 0.15s;
}
.date-input:focus { border-color: #2872A1; background: #fff; }
.date-sep { font-size: 12px; color: #94a3b8; }
.apply-btn {
  padding: 6px 14px; background: #2872A1; color: #fff; border: none;
  border-radius: 8px; font-size: 12.5px; font-weight: 600; cursor: pointer;
  font-family: inherit; transition: background 0.15s;
}
.apply-btn:hover:not(:disabled) { background: #1a5f8a; }
.apply-btn:disabled { background: #cbd5e1; cursor: not-allowed; }
.last-updated {
  margin-left: auto; font-size: 11px; color: #94a3b8;
  display: flex; align-items: center; gap: 4px;
}
.last-updated::before {
  content: ''; width: 6px; height: 6px; border-radius: 50%;
  background: #22c55e; display: inline-block;
}
.fade-slide-enter-active { transition: all 0.2s ease; }
.fade-slide-leave-active { transition: all 0.15s ease; }
.fade-slide-enter-from, .fade-slide-leave-to { opacity: 0; transform: translateX(-8px); }

/* ── STAT CARDS ──────────────────────────────────────────────────── */
.stats-grid { display: grid; grid-template-columns: repeat(4,1fr); gap: 14px; }
.stat-card { background: #fff; border-radius: 14px; padding: 18px; border: 1px solid #f1f5f9; }
.stat-top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.stat-icon { width: 42px; height: 42px; border-radius: 12px; display: flex; align-items: center; justify-content: center; }
.trend { font-size: 12px; font-weight: 700; padding: 4px 8px; border-radius: 99px; }
.trend.up   { color: #22c55e; background: #f0fdf4; }
.trend.down { color: #ef4444; background: #fef2f2; }
.stat-value { font-size: 26px; font-weight: 800; color: #1e293b; line-height: 1.1; margin-bottom: 4px; }
.stat-label { font-size: 12.5px; color: #64748b; font-weight: 500; margin-bottom: 4px; }
.stat-sub   { font-size: 11px; color: #94a3b8; }

/* ── LAYOUT ──────────────────────────────────────────────────────── */
.mid-row    { display: grid; grid-template-columns: 1fr 260px; gap: 14px; }
.bottom-row { display: grid; grid-template-columns: 1fr 280px; gap: 14px; }

/* ── CARD BASE ───────────────────────────────────────────────────── */
.card { background: #fff; border-radius: 14px; padding: 18px; border: 1px solid #f1f5f9; }
.card-header { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 16px; gap: 8px; }
.card-header h3 { font-size: 14px; font-weight: 700; color: #1e293b; }
.card-sub { font-size: 11px; color: #94a3b8; margin-top: 2px; }
.see-all { font-size: 12px; color: #2872A1; text-decoration: none; font-weight: 600; white-space: nowrap; flex-shrink: 0; }
.see-all:hover { text-decoration: underline; }

/* ── LEGEND ──────────────────────────────────────────────────────── */
.legend { display: flex; align-items: center; gap: 14px; font-size: 11.5px; color: #64748b; flex-wrap: wrap; flex-shrink: 0; }
.legend-item { display: flex; align-items: center; gap: 6px; }
.legend-line { display: inline-block; width: 22px; height: 3px; border-radius: 2px; }
.legend-line.amber { background: #2872A1; }
.legend-line.green { background: #22c55e; }

/* ── CHART ───────────────────────────────────────────────────────── */
.svg-chart-wrap { width: 100%; position: relative; }
.svg-chart { width: 100%; height: 185px; display: block; overflow: visible; cursor: crosshair; }

/* ── TOOLTIP ─────────────────────────────────────────────────────── */
.chart-tooltip {
  position: absolute; pointer-events: none;
  background: #1e293b; color: #f8fafc;
  border-radius: 10px; padding: 10px 14px;
  font-size: 11.5px; min-width: 158px;
  box-shadow: 0 8px 24px rgba(0,0,0,0.22);
  z-index: 50; white-space: nowrap;
}
.tip-enter-active { transition: opacity 0.12s ease, transform 0.12s ease; }
.tip-leave-active { transition: opacity 0.08s ease; }
.tip-enter-from   { opacity:0; transform:translateY(4px) scale(0.97); }
.tip-leave-to     { opacity:0; }
.tooltip-label { font-weight:700; font-size:10px; color:#94a3b8; margin-bottom:7px; letter-spacing:0.5px; text-transform:uppercase; }
.tooltip-row   { display:flex; align-items:center; gap:7px; line-height:2; }
.tooltip-row strong { margin-left:auto; padding-left:14px; font-weight:700; color:#fff; }
.tooltip-dot   { display:inline-block; width:7px; height:7px; border-radius:50%; flex-shrink:0; }

/* ── CHART SUMMARY ───────────────────────────────────────────────── */
.chart-summary { display: flex; align-items: center; margin-top: 14px; padding-top: 14px; border-top: 1px solid #f1f5f9; }
.summary-item { display: flex; align-items: center; gap: 6px; flex: 1; justify-content: center; }
.summary-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.amber-dot { background: #2872A1; }
.green-dot { background: #22c55e; }
.summary-label { font-size: 11px; color: #94a3b8; }
.summary-val   { font-size: 13px; font-weight: 700; color: #1e293b; margin-left: 2px; }
.amber-val { color: #2872A1; }
.green-val { color: #22c55e; }
.summary-divider { width: 1px; height: 28px; background: #f1f5f9; }

/* ── SKELETON ────────────────────────────────────────────────────── */
.skeleton {
  background: #e2e8f0;
  background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border: none !important;
  box-shadow: none !important;
}
@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}

/* ── FUNNEL ──────────────────────────────────────────────────────── */
.funnel-list { display: flex; flex-direction: column; gap: 14px; }
.funnel-row  { display: flex; flex-direction: column; gap: 5px; }
.funnel-label-row { display: flex; justify-content: space-between; align-items: center; }
.funnel-label { font-size: 12px; color: #64748b; font-weight: 500; }
.funnel-count { font-size: 13px; font-weight: 700; }
.funnel-bar-bg   { height: 7px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.funnel-bar-fill { height: 100%; border-radius: 99px; width: 0%; transition: width 0.75s cubic-bezier(.4,0,.2,1); }
.funnel-footer { margin-top: 16px; padding-top: 14px; border-top: 1px solid #f1f5f9; }
.funnel-rate { display: flex; justify-content: space-between; align-items: center; }
.funnel-rate-label { font-size: 12px; color: #94a3b8; }
.funnel-rate-val   { font-size: 16px; font-weight: 800; color: #22c55e; }

/* ── POTENTIAL APPLICANTS ────────────────────────────────────────── */
.potential-card   { padding-bottom: 0; overflow: visible; }
.potential-header { flex-wrap: wrap; gap: 12px; align-items: flex-start; margin-bottom: 12px; }
.potential-header-right { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.potential-controls { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 6px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 6px 10px; }
.search-input { border: none; background: transparent; font-size: 12px; color: #1e293b; outline: none; width: 180px; font-family: 'Plus Jakarta Sans', sans-serif; }
.search-input::placeholder { color: #94a3b8; }
.filter-select { font-size: 12px; color: #475569; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 6px 10px; outline: none; font-family: 'Plus Jakarta Sans', sans-serif; cursor: pointer; }

.see-all-btn {
  display: inline-flex; align-items: center; gap: 5px;
  font-size: 12px; font-weight: 700; color: #2872A1;
  background: #eff8ff; border: 1.5px solid #bae6fd;
  border-radius: 8px; padding: 6px 12px;
  text-decoration: none; white-space: nowrap; flex-shrink: 0;
  transition: all 0.15s;
}
.see-all-btn:hover { background: #dbeafe; border-color: #2872A1; }

.listing-tabs { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; margin-bottom: 16px; }
.listing-tab { display: inline-flex; align-items: center; gap: 6px; font-size: 12px; font-weight: 600; color: #64748b; background: #f8fafc; border: 1.5px solid #e2e8f0; border-radius: 8px; padding: 5px 12px; cursor: pointer; transition: all 0.15s; font-family: 'Plus Jakarta Sans', sans-serif; }
.listing-tab:hover { border-color: #cbd5e1; color: #1e293b; }
.listing-tab.active { color: #2872A1; border-color: #2872A1; background: #eff8ff; }
.tab-count { font-size: 10px; font-weight: 700; background: #e2e8f0; color: #64748b; padding: 1px 6px; border-radius: 99px; }

.potential-table { width: 100%; border-collapse: collapse; }
.potential-table thead tr { background: #f8fafc; border-bottom: 2px solid #f1f5f9; }
.potential-table th { font-size: 10.5px; font-weight: 700; color: #94a3b8; padding: 10px 14px; text-transform: uppercase; letter-spacing: 0.05em; text-align: left; white-space: nowrap; }
.potential-row { transition: background 0.12s; }
.potential-row:hover { background: #fafbff; }
.potential-row td { padding: 14px; border-bottom: 1px solid #f1f5f9; vertical-align: middle; }
.potential-row:last-child td { border-bottom: none; }

.pot-avatar { width: 34px; height: 34px; border-radius: 50%; color: #fff; font-size: 13px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.skill-tag-group { display: flex; flex-wrap: wrap; gap: 4px; }
.matched-tag { background: #eff8ff; color: #1a5f8a; font-size: 11px; font-weight: 600; padding: 3px 8px; border-radius: 6px; white-space: nowrap; border: 1px solid #bae6fd; }
.listing-match-cell { display: flex; align-items: center; gap: 10px; }
.listing-color-bar  { width: 4px; height: 34px; border-radius: 99px; flex-shrink: 0; }
.listing-title { font-size: 12.5px; font-weight: 700; color: #1e293b; }
.listing-hint  { font-size: 10.5px; color: #94a3b8; margin-top: 2px; }
.score-cell  { display: flex; align-items: center; gap: 8px; }
.score-track { flex: 1; height: 6px; background: #f1f5f9; border-radius: 99px; overflow: hidden; min-width: 60px; }
.score-fill  { height: 100%; border-radius: 99px; width: 0%; transition: width 0.75s cubic-bezier(.4,0,.2,1); }
.score-num   { font-size: 12px; font-weight: 700; min-width: 32px; }
.loc-cell { display: flex; align-items: center; gap: 5px; font-size: 12px; color: #475569; white-space: nowrap; }
.not-applied-badge { display: inline-flex; align-items: center; gap: 6px; background: #fef9ec; color: #92400e; font-size: 11px; font-weight: 700; padding: 5px 10px; border-radius: 99px; border: 1px solid #fde68a; white-space: nowrap; }
.na-dot { width: 6px; height: 6px; border-radius: 50%; background: #f59e0b; flex-shrink: 0; }

.table-footer { display: flex; align-items: center; justify-content: space-between; padding: 14px 14px 18px; border-top: 1px solid #f1f5f9; }
.table-count  { display: flex; align-items: center; gap: 6px; font-size: 12px; color: #94a3b8; }
.empty-row    { text-align: center; color: #94a3b8; font-size: 13px; padding: 40px 0 !important; }
.pot-pagination { display: flex; align-items: center; gap: 4px; }
.pot-page-btn { width: 30px; height: 30px; border-radius: 7px; border: 1px solid #e2e8f0; background: #fff; font-size: 12px; font-weight: 600; color: #64748b; cursor: pointer; display: flex; align-items: center; justify-content: center; font-family: 'Plus Jakarta Sans', sans-serif; transition: all 0.15s; }
.pot-page-btn:hover:not(:disabled) { border-color: #2872A1; color: #2872A1; }
.pot-page-btn:disabled { opacity: 0.35; cursor: default; }
.pot-page-active { background: #2872A1 !important; color: #fff !important; border-color: #2872A1 !important; }

/* ── RECENT APPLICANTS TABLE ─────────────────────────────────────── */
.data-table { width: 100%; border-collapse: collapse; font-size: 12.5px; }
.data-table th { text-align: left; padding: 8px 10px; color: #94a3b8; font-weight: 600; font-size: 11px; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.data-table td { padding: 10px; color: #1e293b; border-bottom: 1px solid #f8fafc; vertical-align: middle; }
.data-table tbody tr { transition: background 0.15s; }
.data-table tbody tr:hover { background: #f8fafc; }
.person-cell   { display: flex; align-items: center; gap: 8px; }
.person-avatar { width: 28px; height: 28px; border-radius: 50%; color: #fff; font-size: 11px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.person-name   { display: block; font-weight: 600; font-size: 12.5px; color: #1e293b; }
.person-loc    { display: block; font-size: 10.5px; color: #94a3b8; }
.skill-tag     { background: #f1f5f9; color: #475569; font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
.job-cell      { color: #475569; }
.date-cell     { color: #94a3b8; white-space: nowrap; }

/* ── STATUS BADGES ───────────────────────────────────────────────── */
.status-badge  { padding: 3px 10px; border-radius: 99px; font-size: 11px; font-weight: 600; white-space: nowrap; }
.shortlisted { background: #eff8ff; color: #1a5f8a; }
.reviewing   { background: #eff6ff; color: #3b82f6; }
.interview   { background: #faf5ff; color: #8b5cf6; }
.hired       { background: #f0fdf4; color: #22c55e; }
.rejected    { background: #fef2f2; color: #ef4444; }
.pending     { background: #fff7ed; color: #f97316; }

/* ── ACTIVE LISTINGS ─────────────────────────────────────────────── */
.jobs-list { display: flex; flex-direction: column; gap: 12px; }
.job-item  { display: flex; align-items: center; gap: 10px; }
.job-icon  { width: 34px; height: 34px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.job-info  { flex: 1; min-width: 0; }
.job-title { font-size: 12.5px; font-weight: 600; color: #1e293b; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.job-meta  { font-size: 10.5px; color: #94a3b8; margin-top: 2px; }
.job-fill  { display: flex; align-items: center; gap: 6px; }
.fill-bar  { width: 60px; height: 5px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.fill-inner { height: 100%; border-radius: 99px; width: 0%; transition: width 0.75s cubic-bezier(.4,0,.2,1); }
.fill-pct  { font-size: 11px; font-weight: 700; min-width: 28px; text-align: right; }

/* ── ENTRANCE ANIMATIONS ─────────────────────────────────────────── */
@keyframes slideUp { from { opacity:0; transform:translateY(10px); } to { opacity:1; transform:translateY(0); } }
@keyframes slideInRight { from { opacity:0; transform:translateX(14px); } to { opacity:1; transform:translateX(0); } }
.table-row-anim { animation: slideUp 0.35s ease both; }
.slide-in-right { animation: slideInRight 0.4s ease both; }
</style>