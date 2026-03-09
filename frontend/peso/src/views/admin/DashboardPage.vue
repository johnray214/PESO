<template>
  <div class="dashboard-page">
    <!-- Content -->
      <div class="content">

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

        <!-- Middle Row -->
        <div class="mid-row">
          <!-- Registrations Chart -->
          <div class="card chart-card">
            <div class="card-header">
              <div>
                <h3>Registrations Overview</h3>
                <p class="card-sub">Monthly jobseeker & employer registrations — {{ new Date().getFullYear() }}</p>
              </div>
              <div class="chart-controls">
                <div class="legend">
                  <span class="legend-item"><span class="legend-line blue"></span> Jobseekers</span>
                  <span class="legend-item"><span class="legend-line cyan"></span> Employers</span>
                </div>
              </div>
            </div>

            <!-- Professional SVG Line Chart -->
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

                <!-- Grid lines -->
                <line v-for="(gl, i) in gridLines" :key="'g'+i"
                  :x1="50" :y1="gl.y" :x2="610" :y2="gl.y"
                  stroke="#f1f5f9" stroke-width="1"/>

                <!-- Y-axis labels -->
                <text v-for="(gl, i) in gridLines" :key="'yl'+i"
                  :x="44" :y="gl.y + 4" text-anchor="end"
                  font-size="9" fill="#cbd5e1" font-family="Plus Jakarta Sans, sans-serif">{{ gl.label }}</text>

                <!-- Jobseekers area fill -->
                <path :d="jobseekerArea" fill="url(#gradBlue)"/>
                <!-- Employers area fill -->
                <path :d="employerArea" fill="url(#gradCyan)"/>

                <!-- Jobseekers line -->
                <path :d="jobseekerLine" fill="none" stroke="#2563eb" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                <!-- Employers line -->
                <path :d="employerLine" fill="none" stroke="#06b6d4" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>

                <!-- Jobseeker dots -->
                <circle v-for="(pt, i) in jobseekerPoints" :key="'jd'+i"
                  :cx="pt.x" :cy="pt.y" r="3.5" fill="#fff" stroke="#2563eb" stroke-width="2"/>
                <!-- Employer dots -->
                <circle v-for="(pt, i) in employerPoints" :key="'ed'+i"
                  :cx="pt.x" :cy="pt.y" r="3.5" fill="#fff" stroke="#06b6d4" stroke-width="2"/>

                <!-- X-axis labels -->
                <text v-for="(month, i) in chartData" :key="'xl'+i"
                  :x="getX(i)" :y="173" text-anchor="middle"
                  font-size="9" fill="#94a3b8" font-family="Plus Jakarta Sans, sans-serif">{{ month.label }}</text>
              </svg>
            </div>

            <!-- Summary row -->
            <div class="chart-summary">
              <div class="summary-item">
                <span class="summary-dot blue-dot"></span>
                <span class="summary-label">Total Jobseekers</span>
                <span class="summary-val blue-val">{{ totalJobseekers.toLocaleString() }}</span>
              </div>
              <div class="summary-divider"></div>
              <div class="summary-item">
                <span class="summary-dot cyan-dot"></span>
                <span class="summary-label">Total Employers</span>
                <span class="summary-val cyan-val">{{ totalEmployers.toLocaleString() }}</span>
              </div>
              <div class="summary-divider"></div>
              <div class="summary-item">
                <span class="summary-label">Peak Month</span>
                <span class="summary-val">Dec</span>
              </div>
            </div>
          </div>

          <!-- Placement Rate Donut -->
          <div class="card donut-card">
            <div class="card-header">
              <div>
                <h3>Placement Rate</h3>
                <p class="card-sub">This month</p>
              </div>
            </div>
            <div class="donut-wrapper">
              <svg width="150" height="150" viewBox="0 0 150 150">
                <circle cx="75" cy="75" r="55" fill="none" stroke="#f1f5f9" stroke-width="18"/>
                <!-- Placement: 52% -->
                <circle cx="75" cy="75" r="55" fill="none" stroke="#2563eb" stroke-width="18"
                  stroke-dasharray="180 346" stroke-dashoffset="0" stroke-linecap="round"
                  transform="rotate(-90 75 75)"/>
                <!-- Processing: 22% -->
                <circle cx="75" cy="75" r="55" fill="none" stroke="#f97316" stroke-width="18"
                  stroke-dasharray="76 346" stroke-dashoffset="-180" stroke-linecap="round"
                  transform="rotate(-90 75 75)"/>
                <!-- Registration: 13% -->
                <circle cx="75" cy="75" r="55" fill="none" stroke="#06b6d4" stroke-width="18"
                  stroke-dasharray="45 346" stroke-dashoffset="-256" stroke-linecap="round"
                  transform="rotate(-90 75 75)"/>
                <!-- Rejection: 13% -->
                <circle cx="75" cy="75" r="55" fill="none" stroke="#ef4444" stroke-width="18"
                  stroke-dasharray="45 346" stroke-dashoffset="-301" stroke-linecap="round"
                  transform="rotate(-90 75 75)"/>
                <text x="75" y="68" text-anchor="middle" font-size="20" font-weight="800" fill="#1e293b">52%</text>
                <text x="75" y="84" text-anchor="middle" font-size="10" fill="#94a3b8">Placed</text>
              </svg>
            </div>
            <div class="donut-legend">
              <div v-for="item in donutItems" :key="item.label" class="donut-row">
                <div class="donut-label-left">
                  <span class="dot" :style="{ background: item.color }"></span>
                  <span>{{ item.label }}</span>
                </div>
                <span class="donut-pct" :style="{ color: item.color }">{{ item.pct }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Placement Metrics Row -->
        <div class="placement-row">
          <div class="card placement-chart-card">
            <div class="card-header">
              <div>
                <h3>Placement Metrics</h3>
                <p class="card-sub">Monthly placement status breakdown — {{ new Date().getFullYear() }}</p>
              </div>
              <div class="chart-controls">
                <div class="legend">
                  <span class="legend-item"><span class="legend-line placement-blue"></span> Placement</span>
                  <span class="legend-item"><span class="legend-line processing-orange"></span> Processing</span>
                  <span class="legend-item"><span class="legend-line registration-cyan"></span> Registration</span>
                  <span class="legend-item"><span class="legend-line rejection-red"></span> Rejection</span>
                </div>
              </div>
            </div>

            <div class="svg-chart-wrap">
              <svg viewBox="0 0 620 180" preserveAspectRatio="xMidYMid meet" class="svg-chart">
                <defs>
                  <linearGradient id="gradPlacement" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="#2563eb" stop-opacity="0.18"/>
                    <stop offset="100%" stop-color="#2563eb" stop-opacity="0"/>
                  </linearGradient>
                  <linearGradient id="gradProcessing" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="#f97316" stop-opacity="0.15"/>
                    <stop offset="100%" stop-color="#f97316" stop-opacity="0"/>
                  </linearGradient>
                  <linearGradient id="gradRegistration" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="#06b6d4" stop-opacity="0.15"/>
                    <stop offset="100%" stop-color="#06b6d4" stop-opacity="0"/>
                  </linearGradient>
                  <linearGradient id="gradRejection" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="#ef4444" stop-opacity="0.15"/>
                    <stop offset="100%" stop-color="#ef4444" stop-opacity="0"/>
                  </linearGradient>
                </defs>

                <line v-for="(gl, i) in gridLines" :key="'g'+i"
                  :x1="50" :y1="gl.y" :x2="610" :y2="gl.y"
                  stroke="#f1f5f9" stroke-width="1"/>

                <text v-for="(gl, i) in gridLines" :key="'yl'+i"
                  :x="44" :y="gl.y + 4" text-anchor="end"
                  font-size="9" fill="#cbd5e1" font-family="Plus Jakarta Sans, sans-serif">{{ gl.label }}</text>

                <path :d="placementArea" fill="url(#gradPlacement)"/>
                <path :d="processingArea" fill="url(#gradProcessing)"/>
                <path :d="registrationArea" fill="url(#gradRegistration)"/>
                <path :d="rejectionArea" fill="url(#gradRejection)"/>

                <path :d="placementLine" fill="none" stroke="#2563eb" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                <path :d="processingLine" fill="none" stroke="#f97316" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                <path :d="registrationLine" fill="none" stroke="#06b6d4" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                <path :d="rejectionLine" fill="none" stroke="#ef4444" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>

                <circle v-for="(pt, i) in placementPoints" :key="'pd'+i"
                  :cx="pt.x" :cy="pt.y" r="3.5" fill="#fff" stroke="#2563eb" stroke-width="2"/>
                <circle v-for="(pt, i) in processingPoints" :key="'prd'+i"
                  :cx="pt.x" :cy="pt.y" r="3.5" fill="#fff" stroke="#f97316" stroke-width="2"/>
                <circle v-for="(pt, i) in registrationPoints" :key="'rd'+i"
                  :cx="pt.x" :cy="pt.y" r="3.5" fill="#fff" stroke="#06b6d4" stroke-width="2"/>
                <circle v-for="(pt, i) in rejectionPoints" :key="'red'+i"
                  :cx="pt.x" :cy="pt.y" r="3.5" fill="#fff" stroke="#ef4444" stroke-width="2"/>

                <text v-for="(month, i) in placementData" :key="'xl'+i"
                  :x="getXPlacement(i)" :y="173" text-anchor="middle"
                  font-size="9" fill="#94a3b8" font-family="Plus Jakarta Sans, sans-serif">{{ month.label }}</text>
              </svg>
            </div>

            <div class="chart-summary">
              <div class="summary-item">
                <span class="summary-dot placement-dot"></span>
                <span class="summary-label">Placement</span>
                <span class="summary-val placement-val">{{ totalPlacement }}</span>
              </div>
              <div class="summary-divider"></div>
              <div class="summary-item">
                <span class="summary-dot processing-dot"></span>
                <span class="summary-label">Processing</span>
                <span class="summary-val processing-val">{{ totalProcessing }}</span>
              </div>
              <div class="summary-divider"></div>
              <div class="summary-item">
                <span class="summary-dot registration-dot"></span>
                <span class="summary-label">Registration</span>
                <span class="summary-val registration-val">{{ totalRegistration }}</span>
              </div>
              <div class="summary-divider"></div>
              <div class="summary-item">
                <span class="summary-dot rejection-dot"></span>
                <span class="summary-label">Rejection</span>
                <span class="summary-val rejection-val">{{ totalRejection }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Bottom Row -->
        <div class="bottom-row">
          <!-- Recent Applicants -->
          <div class="card table-card">
            <div class="card-header">
              <div>
                <h3>Recent Applicants</h3>
                <p class="card-sub">Latest jobseeker registrations</p>
              </div>
              <a href="#" class="see-all">See All</a>
            </div>
            <table class="data-table">
              <thead>
                <tr>
                  <th>Applicant</th>
                  <th>Skills</th>
                  <th>Applied For</th>
                  <th>Date</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="a in applicants" :key="a.name">
                  <td>
                    <div class="person-cell">
                      <div class="person-avatar" :style="{ background: a.color }">{{ a.name[0] }}</div>
                      <div>
                        <span class="person-name">{{ a.name }}</span>
                        <span class="person-loc">{{ a.location }}</span>
                      </div>
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

          <!-- Right Column -->
          <div class="right-col">
            <!-- Upcoming Events -->
            <div class="card events-card">
              <div class="card-header">
                <h3>Upcoming Events</h3>
                <a href="#" class="see-all">See All</a>
              </div>
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

            <!-- Top Employers -->
            <div class="card employers-card">
              <div class="card-header">
                <h3>Top Employers</h3>
                <a href="#" class="see-all">See All</a>
              </div>
              <div class="employers-list">
                <div v-for="(emp, i) in topEmployers" :key="emp.name" class="employer-item">
                  <span class="emp-rank">#{{ i + 1 }}</span>
                  <div class="emp-logo" :style="{ background: emp.bg }">{{ emp.name[0] }}</div>
                  <div class="emp-info">
                    <p class="emp-name">{{ emp.name }}</p>
                    <p class="emp-industry">{{ emp.industry }}</p>
                  </div>
                  <span class="emp-vacancies">{{ emp.vacancies }} open</span>
                </div>
              </div>
            </div>
          </div>
        </div>

      </div>
  </div>
</template>

<script>
export default {
  name: 'PESODashboard',
  data() {
    return {
      stats: [
        {
          label: 'Registered Jobseekers', value: '4,821', sub: '+124 this week',
          iconBg: '#dbeafe', iconColor: '#2563eb', trendVal: '12%', trendUp: true,
          icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>`
        },
        {
          label: 'Active Employers', value: '318', sub: '+9 this week',
          iconBg: '#fff7ed', iconColor: '#f97316', trendVal: '8%', trendUp: true,
          icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>`
        },
        {
          label: 'Job Vacancies', value: '1,054', sub: '+67 posted this week',
          iconBg: '#f0fdf4', iconColor: '#22c55e', trendVal: '19%', trendUp: true,
          icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>`
        },
        {
          label: 'Successful Placements', value: '2,190', sub: '+88 this month',
          iconBg: '#eff6ff', iconColor: '#3b82f6', trendVal: '5%', trendUp: false,
          icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>`
        },
      ],
      chartData: [
        { label: 'Jan', jobseekers: 320, employers: 80 },
        { label: 'Feb', jobseekers: 380, employers: 110 },
        { label: 'Mar', jobseekers: 420, employers: 130 },
        { label: 'Apr', jobseekers: 370, employers: 100 },
        { label: 'May', jobseekers: 490, employers: 160 },
        { label: 'Jun', jobseekers: 445, employers: 145 },
        { label: 'Jul', jobseekers: 510, employers: 170 },
        { label: 'Aug', jobseekers: 460, employers: 140 },
        { label: 'Sep', jobseekers: 480, employers: 155 },
        { label: 'Oct', jobseekers: 530, employers: 175 },
        { label: 'Nov', jobseekers: 560, employers: 190 },
        { label: 'Dec', jobseekers: 600, employers: 210 },
      ],
      donutItems: [
        { label: 'Placement', pct: '52%', color: '#2563eb' },
        { label: 'Processing', pct: '22%', color: '#f97316' },
        { label: 'Registration', pct: '13%', color: '#06b6d4' },
        { label: 'Rejection', pct: '13%', color: '#ef4444' },
      ],
      placementData: [
        { label: 'Jan', placement: 280, processing: 180, registration: 110, rejection: 80 },
        { label: 'Feb', placement: 320, processing: 200, registration: 130, rejection: 95 },
        { label: 'Mar', placement: 360, processing: 190, registration: 145, rejection: 88 },
        { label: 'Apr', placement: 310, processing: 210, registration: 120, rejection: 105 },
        { label: 'May', placement: 410, processing: 220, registration: 155, rejection: 92 },
        { label: 'Jun', placement: 380, processing: 195, registration: 140, rejection: 110 },
        { label: 'Jul', placement: 430, processing: 230, registration: 165, rejection: 98 },
        { label: 'Aug', placement: 390, processing: 205, registration: 135, rejection: 115 },
        { label: 'Sep', placement: 400, processing: 215, registration: 150, rejection: 102 },
        { label: 'Oct', placement: 450, processing: 240, registration: 170, rejection: 95 },
        { label: 'Nov', placement: 475, processing: 250, registration: 180, rejection: 108 },
        { label: 'Dec', placement: 510, processing: 265, registration: 195, rejection: 120 },
      ],
      gridLines: [
        { y: 14, label: '600' },
        { y: 44, label: '500' },
        { y: 74, label: '400' },
        { y: 104, label: '300' },
        { y: 134, label: '200' },
        { y: 158, label: '100' },
      ],
      applicants: [
        { name: 'Maria Santos', location: 'Quezon City', skill: 'Accounting', job: 'Bookkeeper', date: 'Dec 06', status: 'Matched', statusClass: 'matched', color: '#2563eb' },
        { name: 'Juan dela Cruz', location: 'Marikina', skill: 'IT / Dev', job: 'Web Developer', date: 'Dec 06', status: 'Pending', statusClass: 'pending', color: '#f97316' },
        { name: 'Ana Reyes', location: 'Pasig', skill: 'Nursing', job: 'Medical Staff', date: 'Dec 05', status: 'Matched', statusClass: 'matched', color: '#22c55e' },
        { name: 'Pedro Lim', location: 'Caloocan', skill: 'Electrical', job: 'Electrician', date: 'Dec 05', status: 'Reviewing', statusClass: 'reviewing', color: '#3b82f6' },
        { name: 'Rosa Garcia', location: 'Taguig', skill: 'Teaching', job: 'Instructor', date: 'Dec 04', status: 'Pending', statusClass: 'pending', color: '#06b6d4' },
      ],
      events: [
        { day: '12', month: 'DEC', title: 'Job Fair 2024 — Quezon City', location: 'QC Sports Club', slots: 200, type: 'Job Fair', bg: '#dbeafe', color: '#2563eb' },
        { day: '18', month: 'DEC', title: 'Livelihood Seminar Series', location: 'City Hall Annex', slots: 80, type: 'Seminar', bg: '#fff7ed', color: '#f97316' },
        { day: '22', month: 'DEC', title: 'Skills Training — BPO', location: 'TESDA Center', slots: 50, type: 'Training', bg: '#f0fdf4', color: '#22c55e' },
      ],
      topEmployers: [
        { name: 'Accenture PH', industry: 'BPO / IT Services', vacancies: 42, bg: '#dbeafe' },
        { name: 'Jollibee Foods', industry: 'Food & Beverage', vacancies: 28, bg: '#fff7ed' },
        { name: 'SM Supermalls', industry: 'Retail', vacancies: 35, bg: '#eff6ff' },
        { name: 'Ayala Corp', industry: 'Real Estate', vacancies: 19, bg: '#f0fdf4' },
      ],
    }
  },
  computed: {
    totalJobseekers() {
      return this.chartData.reduce((s, d) => s + d.jobseekers, 0)
    },
    totalEmployers() {
      return this.chartData.reduce((s, d) => s + d.employers, 0)
    },
    jobseekerPoints() {
      return this.chartData.map((d, i) => ({ x: this.getX(i), y: this.valToY(d.jobseekers) }))
    },
    employerPoints() {
      return this.chartData.map((d, i) => ({ x: this.getX(i), y: this.valToY(d.employers) }))
    },
    jobseekerLine() { return this.buildSmoothPath(this.jobseekerPoints) },
    employerLine() { return this.buildSmoothPath(this.employerPoints) },
    jobseekerArea() {
      const pts = this.jobseekerPoints
      return this.buildSmoothPath(pts) + ` L${pts[pts.length-1].x},158 L${pts[0].x},158 Z`
    },
    employerArea() {
      const pts = this.employerPoints
      return this.buildSmoothPath(pts) + ` L${pts[pts.length-1].x},158 L${pts[0].x},158 Z`
    },
    totalPlacement() {
      return this.placementData.reduce((s, d) => s + d.placement, 0)
    },
    totalProcessing() {
      return this.placementData.reduce((s, d) => s + d.processing, 0)
    },
    totalRegistration() {
      return this.placementData.reduce((s, d) => s + d.registration, 0)
    },
    totalRejection() {
      return this.placementData.reduce((s, d) => s + d.rejection, 0)
    },
    placementPoints() {
      return this.placementData.map((d, i) => ({ x: this.getXPlacement(i), y: this.valToYPlacement(d.placement) }))
    },
    processingPoints() {
      return this.placementData.map((d, i) => ({ x: this.getXPlacement(i), y: this.valToYPlacement(d.processing) }))
    },
    registrationPoints() {
      return this.placementData.map((d, i) => ({ x: this.getXPlacement(i), y: this.valToYPlacement(d.registration) }))
    },
    rejectionPoints() {
      return this.placementData.map((d, i) => ({ x: this.getXPlacement(i), y: this.valToYPlacement(d.rejection) }))
    },
    placementLine() { return this.buildSmoothPath(this.placementPoints) },
    processingLine() { return this.buildSmoothPath(this.processingPoints) },
    registrationLine() { return this.buildSmoothPath(this.registrationPoints) },
    rejectionLine() { return this.buildSmoothPath(this.rejectionPoints) },
    placementArea() {
      const pts = this.placementPoints
      return this.buildSmoothPath(pts) + ` L${pts[pts.length-1].x},158 L${pts[0].x},158 Z`
    },
    processingArea() {
      const pts = this.processingPoints
      return this.buildSmoothPath(pts) + ` L${pts[pts.length-1].x},158 L${pts[0].x},158 Z`
    },
    registrationArea() {
      const pts = this.registrationPoints
      return this.buildSmoothPath(pts) + ` L${pts[pts.length-1].x},158 L${pts[0].x},158 Z`
    },
    rejectionArea() {
      const pts = this.rejectionPoints
      return this.buildSmoothPath(pts) + ` L${pts[pts.length-1].x},158 L${pts[0].x},158 Z`
    },
  },
  methods: {
    getX(i) { return 50 + i * (560 / (this.chartData.length - 1)) },
    valToY(val) { return 158 - ((val / 700) * 144) },
    getXPlacement(i) { return 50 + i * (560 / (this.placementData.length - 1)) },
    valToYPlacement(val) { return 158 - ((val / 600) * 144) },
    buildSmoothPath(pts) {
      if (!pts.length) return ''
      let d = `M${pts[0].x},${pts[0].y}`
      for (let i = 1; i < pts.length; i++) {
        const prev = pts[i - 1], curr = pts[i]
        const cpx = (prev.x + curr.x) / 2
        d += ` C${cpx},${prev.y} ${cpx},${curr.y} ${curr.x},${curr.y}`
      }
      return d
    },
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

* { box-sizing: border-box; margin: 0; padding: 0; }

.dashboard-page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  display: flex;
  flex-direction: column;
  flex: 1;
  overflow: hidden;
  background: #f1eeff;
}

/* TOPBAR */
.topbar {
  background: #fff;
  padding: 14px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid #f1f5f9;
}

.topbar-left { display: flex; flex-direction: column; }

.page-title {
  font-size: 18px;
  font-weight: 800;
  color: #1e293b;
  line-height: 1.1;
}

.page-sub { font-size: 12px; color: #94a3b8; margin-top: 2px; }

.topbar-right { display: flex; align-items: center; gap: 12px; }

.icon-btn {
  background: none;
  border: none;
  cursor: pointer;
  color: #64748b;
  display: flex;
  align-items: center;
  padding: 7px;
  border-radius: 8px;
  position: relative;
}

.icon-btn:hover { background: #f1f5f9; }

.bell-dot {
  position: absolute;
  top: 2px;
  right: 2px;
  background: #2563eb;
  color: #fff;
  font-size: 9px;
  font-weight: 700;
  padding: 1px 4px;
  border-radius: 99px;
}

.user-pill {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px 6px 6px;
  background: #f8fafc;
  border-radius: 99px;
}

.avatar {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  background: linear-gradient(135deg, #2563eb, #3b82f6);
  color: #fff;
  font-size: 12px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
}

.user-meta { display: flex; flex-direction: column; }
.user-name { font-size: 12px; font-weight: 600; color: #1e293b; line-height: 1.2; }
.user-role { font-size: 10px; color: #94a3b8; }

/* CONTENT */
.content {
  flex: 1;
  overflow-y: auto;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* STAT CARDS */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
}

.stat-card {
  background: #fff;
  border-radius: 14px;
  padding: 18px;
}

.stat-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
}

.stat-icon {
  width: 42px;
  height: 42px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.trend { font-size: 12px; font-weight: 700; padding: 4px 8px; border-radius: 99px; }
.trend.up { color: #22c55e; background: #f0fdf4; }
.trend.down { color: #ef4444; background: #fef2f2; }

.stat-value { font-size: 26px; font-weight: 800; color: #1e293b; line-height: 1.1; margin-bottom: 4px; }
.stat-label { font-size: 12.5px; color: #64748b; font-weight: 500; margin-bottom: 4px; }
.stat-sub { font-size: 11px; color: #94a3b8; }

/* MID ROW */
.mid-row {
  display: grid;
  grid-template-columns: 1fr 260px;
  gap: 14px;
}

.card {
  background: #fff;
  border-radius: 14px;
  padding: 18px;
}

/* Match chart-card to table-card (Recent Applicants) */
.chart-card,
.table-card {
  border: 1px solid #f1f5f9;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

/* Match donut-card to events-card (Upcoming Events) */
.donut-card,
.events-card {
  border: 1px solid #f1f5f9;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.card-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 16px;
}

.card-header h3 { font-size: 14px; font-weight: 700; color: #1e293b; }
.card-sub { font-size: 11px; color: #94a3b8; margin-top: 2px; }

.legend { display: flex; align-items: center; gap: 12px; font-size: 11.5px; color: #64748b; }

.dot {
  display: inline-block;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-right: 4px;
}

/* LEGEND */
.chart-controls { display: flex; align-items: center; gap: 12px; }
.legend { display: flex; align-items: center; gap: 14px; font-size: 11.5px; color: #64748b; }
.legend-item { display: flex; align-items: center; gap: 6px; }
.legend-line {
  display: inline-block;
  width: 22px;
  height: 3px;
  border-radius: 2px;
}
.legend-line.blue { background: #2563eb; }
.legend-line.cyan { background: #06b6d4; }
.legend-line.placement-blue { background: #2563eb; }
.legend-line.processing-orange { background: #f97316; }
.legend-line.registration-cyan { background: #06b6d4; }
.legend-line.rejection-red { background: #ef4444; }

/* SVG LINE CHART */
.svg-chart-wrap {
  width: 100%;
  overflow: hidden;
}

.svg-chart {
  width: 100%;
  height: 185px;
  display: block;
}

.chart-summary {
  display: flex;
  align-items: center;
  gap: 0;
  margin-top: 14px;
  padding-top: 14px;
  border-top: 1px solid #f1f5f9;
}

.summary-item {
  display: flex;
  align-items: center;
  gap: 6px;
  flex: 1;
  justify-content: center;
}

.summary-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.blue-dot { background: #2563eb; }
.cyan-dot { background: #06b6d4; }
.placement-dot { background: #2563eb; }
.processing-dot { background: #f97316; }
.registration-dot { background: #06b6d4; }
.rejection-dot { background: #ef4444; }

.summary-label { font-size: 11px; color: #94a3b8; }
.summary-val { font-size: 13px; font-weight: 700; color: #1e293b; margin-left: 2px; }
.blue-val { color: #2563eb; }
.cyan-val { color: #06b6d4; }
.placement-val { color: #2563eb; }
.processing-val { color: #f97316; }
.registration-val { color: #06b6d4; }
.rejection-val { color: #ef4444; }

.summary-divider {
  width: 1px;
  height: 28px;
  background: #f1f5f9;
}

/* DONUT */
.donut-wrapper { display: flex; justify-content: center; margin: 4px 0 14px; }

.donut-legend { display: flex; flex-direction: column; gap: 8px; }

.donut-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 12px;
  color: #64748b;
}

.donut-label-left { display: flex; align-items: center; gap: 8px; }

.donut-pct { font-size: 12px; font-weight: 700; }

/* PLACEMENT ROW */
.placement-row {
  display: grid;
  grid-template-columns: 1fr;
  gap: 14px;
}

/* BOTTOM ROW */
.bottom-row {
  display: grid;
  grid-template-columns: 1fr 280px;
  gap: 14px;
}

.right-col { display: flex; flex-direction: column; gap: 14px; }

.see-all { font-size: 12px; color: #2563eb; text-decoration: none; font-weight: 600; white-space: nowrap; }
.see-all:hover { text-decoration: underline; }

/* TABLE */
.data-table { width: 100%; border-collapse: collapse; font-size: 12.5px; }

.data-table th {
  text-align: left;
  padding: 8px 10px;
  color: #94a3b8;
  font-weight: 600;
  font-size: 11px;
  border-bottom: 1px solid #f1f5f9;
  white-space: nowrap;
}

.data-table td {
  padding: 10px 10px;
  color: #1e293b;
  border-bottom: 1px solid #f8fafc;
  vertical-align: middle;
}

.person-cell { display: flex; align-items: center; gap: 8px; }

.person-avatar {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  color: #fff;
  font-size: 11px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.person-name { display: block; font-weight: 600; font-size: 12.5px; color: #1e293b; }
.person-loc { display: block; font-size: 10.5px; color: #94a3b8; }

.skill-tag {
  background: #f1f5f9;
  color: #475569;
  font-size: 11px;
  font-weight: 500;
  padding: 3px 8px;
  border-radius: 6px;
  white-space: nowrap;
}

.job-cell { color: #475569; }
.date-cell { color: #94a3b8; white-space: nowrap; }

.status-badge {
  padding: 3px 10px;
  border-radius: 99px;
  font-size: 11px;
  font-weight: 600;
  white-space: nowrap;
}

.status-badge.matched { background: #f0fdf4; color: #22c55e; }
.status-badge.pending { background: #fff7ed; color: #f97316; }
.status-badge.reviewing { background: #eff6ff; color: #3b82f6; }

/* EVENTS */
.events-list { display: flex; flex-direction: column; gap: 10px; }

.event-item {
  display: flex;
  align-items: center;
  gap: 10px;
}

.event-date-box {
  min-width: 40px;
  height: 44px;
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.event-day { font-size: 15px; font-weight: 800; line-height: 1; }
.event-month { font-size: 9px; font-weight: 600; text-transform: uppercase; }

.event-info { flex: 1; min-width: 0; }
.event-title { font-size: 12px; font-weight: 600; color: #1e293b; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.event-meta { font-size: 10.5px; color: #94a3b8; margin-top: 2px; }

.event-type {
  font-size: 10px;
  font-weight: 600;
  padding: 3px 8px;
  border-radius: 6px;
  white-space: nowrap;
}

/* EMPLOYERS */
.employers-list { display: flex; flex-direction: column; gap: 10px; }

.employer-item {
  display: flex;
  align-items: center;
  gap: 10px;
}

.emp-rank { font-size: 11px; font-weight: 700; color: #cbd5e1; min-width: 16px; }

.emp-logo {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: 800;
  color: #7c3aed;
  flex-shrink: 0;
}

.emp-info { flex: 1; }
.emp-name { font-size: 12.5px; font-weight: 600; color: #1e293b; }
.emp-industry { font-size: 10.5px; color: #94a3b8; }

.emp-vacancies {
  font-size: 11px;
  font-weight: 600;
  color: #2563eb;
  background: #dbeafe;
  padding: 3px 8px;
  border-radius: 6px;
  white-space: nowrap;
}
</style>