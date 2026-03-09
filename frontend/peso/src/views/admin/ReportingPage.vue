<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Reporting</h1>
        <p class="page-sub">Generate reports and analytics</p>
      </div>
      <button class="btn-primary" @click="exportReport">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
        Export Report
      </button>
    </div>

    <!-- Filters -->
    <div class="filters-bar">
      <div class="filter-group">
        <label class="filter-label">Date Range:</label>
        <input v-model="dateFrom" type="date" class="filter-input" />
        <span class="filter-sep">to</span>
        <input v-model="dateTo" type="date" class="filter-input" />
      </div>
      <div class="filter-group">
        <select v-model="reportType" class="filter-select">
          <option value="">All Reports</option>
          <option value="placements">Placements</option>
          <option value="registrations">Registrations</option>
          <option value="events">Events</option>
        </select>
        <button class="btn-icon" @click="generateReport">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 11-2.12-9.36L23 10"/></svg>
          Generate
        </button>
      </div>
    </div>

    <!-- Report Cards -->
    <div class="report-grid">
      <div v-for="report in reports" :key="report.title" class="report-card">
        <div class="report-icon" :style="{ background: report.iconBg, color: report.iconColor }">
          <span v-html="report.icon"></span>
        </div>
        <div class="report-info">
          <h3 class="report-title">{{ report.title }}</h3>
          <p class="report-desc">{{ report.desc }}</p>
        </div>
        <button class="download-btn" @click="downloadReport(report.title)">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
        </button>
      </div>
    </div>

    <!-- Chart Section -->
    <div class="chart-section">
      <div class="section-card">
        <div class="card-header">
          <div>
            <h3>Monthly Trends</h3>
            <p class="card-sub">Placement & Registration statistics</p>
          </div>
          <div class="chart-controls">
            <button v-for="range in chartRanges" :key="range.value"
              :class="['range-btn', { active: activeRange === range.value }]"
              @click="activeRange = range.value">
              {{ range.label }}
            </button>
          </div>
        </div>
        <div class="bar-chart">
          <div v-for="(bar, i) in chartBars" :key="i" class="bar-col">
            <div class="bar-stack">
              <div class="bar-segment placement" :style="{ height: bar.placement + '%' }"
                   :title="`Placement: ${bar.placementVal}`"></div>
              <div class="bar-segment registration" :style="{ height: bar.registration + '%' }"
                   :title="`Registration: ${bar.registrationVal}`"></div>
            </div>
            <span class="bar-label">{{ bar.month }}</span>
          </div>
        </div>
        <div class="chart-legend">
          <div class="legend-item">
            <span class="legend-box placement-bg"></span>
            <span>Placements</span>
          </div>
          <div class="legend-item">
            <span class="legend-box registration-bg"></span>
            <span>Registrations</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Summary Table -->
    <div class="table-section">
      <div class="section-card">
        <h3 class="section-title">Report Summary</h3>
        <table class="report-table">
          <thead>
            <tr>
              <th>Month</th>
              <th>Placements</th>
              <th>Registrations</th>
              <th>Events</th>
              <th>Success Rate</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in summaryData" :key="row.month">
              <td class="month-cell">{{ row.month }}</td>
              <td class="num-cell">{{ row.placements }}</td>
              <td class="num-cell">{{ row.registrations }}</td>
              <td class="num-cell">{{ row.events }}</td>
              <td>
                <span class="rate-badge" :class="rateClass(row.rate)">{{ row.rate }}%</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ReportingPage',
  data() {
    return {
      dateFrom: '2024-01-01',
      dateTo: '2024-12-31',
      reportType: '',
      activeRange: '6m',
      chartRanges: [
        { label: '3M', value: '3m' },
        { label: '6M', value: '6m' },
        { label: '1Y', value: '1y' },
      ],
      reports: [
        {
          title: 'Placement Report',
          desc: 'Detailed placement statistics & trends',
          icon: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>`,
          iconBg: '#dbeafe',
          iconColor: '#2563eb',
        },
        {
          title: 'Registration Report',
          desc: 'Jobseeker & employer registrations',
          icon: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>`,
          iconBg: '#fff7ed',
          iconColor: '#f97316',
        },
        {
          title: 'Event Report',
          desc: 'Event participation & outcomes',
          icon: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>`,
          iconBg: '#f0fdf4',
          iconColor: '#22c55e',
        },
        {
          title: 'Employer Report',
          desc: 'Active employers & job postings',
          icon: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>`,
          iconBg: '#eff6ff',
          iconColor: '#3b82f6',
        },
      ],
      chartBars: [
        { month: 'Jan', placement: 55, registration: 45, placementVal: 280, registrationVal: 320 },
        { month: 'Feb', placement: 60, registration: 50, placementVal: 320, registrationVal: 380 },
        { month: 'Mar', placement: 65, registration: 55, placementVal: 360, registrationVal: 420 },
        { month: 'Apr', placement: 58, registration: 48, placementVal: 310, registrationVal: 370 },
        { month: 'May', placement: 70, registration: 60, placementVal: 410, registrationVal: 490 },
        { month: 'Jun', placement: 65, registration: 52, placementVal: 380, registrationVal: 445 },
      ],
      summaryData: [
        { month: 'January', placements: 280, registrations: 320, events: 3, rate: 87 },
        { month: 'February', placements: 320, registrations: 380, events: 4, rate: 84 },
        { month: 'March', placements: 360, registrations: 420, events: 5, rate: 86 },
        { month: 'April', placements: 310, registrations: 370, events: 3, rate: 84 },
        { month: 'May', placements: 410, registrations: 490, events: 6, rate: 84 },
        { month: 'June', placements: 380, registrations: 445, events: 4, rate: 85 },
        { month: 'July', placements: 430, registrations: 510, events: 5, rate: 84 },
        { month: 'August', placements: 390, registrations: 460, events: 3, rate: 85 },
        { month: 'September', placements: 400, registrations: 480, events: 4, rate: 83 },
        { month: 'October', placements: 450, registrations: 530, events: 6, rate: 85 },
        { month: 'November', placements: 475, registrations: 560, events: 5, rate: 85 },
        { month: 'December', placements: 510, registrations: 600, events: 7, rate: 85 },
      ],
    }
  },
  computed: {
    stripStats() {
      return [
        { label: 'Total Reports', value: 48, color: '#1e293b' },
        { label: 'This Month', value: 12, color: '#2563eb' },
        { label: 'Exported', value: 32, color: '#22c55e' },
        { label: 'Pending', value: 4, color: '#f97316' },
      ]
    },
  },
  methods: {
    exportReport() {
      alert('Report exported successfully!')
    },
    downloadReport(title) {
      alert(`Downloading ${title}...`)
    },
    generateReport() {
      alert('Report generated!')
    },
    rateClass(rate) {
      if (rate >= 85) return 'high'
      if (rate >= 80) return 'medium'
      return 'low'
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

.page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  padding: 24px;
  background: #f8fafc;
  min-height: 0;
  display: flex;
  flex-direction: column;
  gap: 20px;
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
  padding: 10px 18px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
  transition: background 0.15s;
}

.btn-primary:hover {
  background: #1d4ed8;
}

.stats-strip {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 14px;
}

.strip-stat {
  background: #fff;
  border-radius: 0;
  padding: 18px 16px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  border: 1px solid #e2e8f0;
  border-left: 4px solid var(--accent, #94a3b8);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  transition: box-shadow 0.2s ease, border-color 0.2s ease;
}

.strip-stat:hover {
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.08);
  border-color: #cbd5e1;
}

.strip-val {
  font-size: 24px;
  font-weight: 800;
  line-height: 1.2;
  letter-spacing: -0.02em;
}

.strip-label {
  font-size: 11.5px;
  color: #64748b;
  margin-top: 6px;
  font-weight: 500;
}

.filters-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
}

.filter-group {
  display: flex;
  align-items: center;
  gap: 8px;
}

.filter-label {
  font-size: 13px;
  font-weight: 600;
  color: #475569;
}

.filter-input {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 8px 12px;
  font-size: 13px;
  color: #1e293b;
  font-family: inherit;
  outline: none;
  cursor: pointer;
}

.filter-input:focus {
  border-color: #2563eb;
}

.filter-sep {
  font-size: 12px;
  color: #94a3b8;
}

.filter-select {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 8px 12px;
  font-size: 12.5px;
  color: #475569;
  cursor: pointer;
  outline: none;
  font-family: inherit;
}

.btn-icon {
  display: flex;
  align-items: center;
  gap: 6px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 8px 14px;
  font-size: 12.5px;
  color: #475569;
  cursor: pointer;
  font-family: inherit;
  font-weight: 600;
  transition: all 0.15s;
}

.btn-icon:hover {
  background: #f8fafc;
  border-color: #cbd5e1;
}

.report-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 14px;
}

.report-card {
  background: #fff;
  border: 1px solid #f1f5f9;
  padding: 18px;
  display: flex;
  align-items: center;
  gap: 14px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  transition: box-shadow 0.2s ease;
}

.report-card:hover {
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.08);
}

.report-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.report-info {
  flex: 1;
}

.report-title {
  font-size: 14px;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 3px;
}

.report-desc {
  font-size: 11.5px;
  color: #64748b;
}

.download-btn {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 8px;
  color: #64748b;
  cursor: pointer;
  display: flex;
  align-items: center;
  transition: all 0.15s;
}

.download-btn:hover {
  background: #eff6ff;
  border-color: #2563eb;
  color: #2563eb;
}

.chart-section,
.table-section {
  display: grid;
  gap: 14px;
}

.section-card {
  background: #fff;
  border: 1px solid #f1f5f9;
  padding: 20px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.card-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 20px;
}

.card-header h3 {
  font-size: 15px;
  font-weight: 700;
  color: #1e293b;
}

.card-sub {
  font-size: 11.5px;
  color: #94a3b8;
  margin-top: 2px;
}

.chart-controls {
  display: flex;
  gap: 4px;
}

.range-btn {
  background: none;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  padding: 6px 12px;
  font-size: 12px;
  font-weight: 600;
  color: #64748b;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.15s;
}

.range-btn:hover {
  background: #f8fafc;
}

.range-btn.active {
  background: #eff6ff;
  border-color: #2563eb;
  color: #2563eb;
}

.bar-chart {
  display: flex;
  align-items: flex-end;
  gap: 16px;
  height: 220px;
  padding: 0 12px;
  margin-bottom: 16px;
}

.bar-col {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.bar-stack {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column-reverse;
  gap: 4px;
}

.bar-segment {
  width: 100%;
  border-radius: 4px 4px 0 0;
  transition: all 0.2s;
  cursor: pointer;
}

.bar-segment:hover {
  opacity: 0.8;
}

.bar-segment.placement {
  background: #2563eb;
}

.bar-segment.registration {
  background: #f97316;
}

.bar-label {
  font-size: 11px;
  color: #94a3b8;
  font-weight: 500;
}

.chart-legend {
  display: flex;
  justify-content: center;
  gap: 20px;
  padding-top: 16px;
  border-top: 1px solid #f1f5f9;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #64748b;
  font-weight: 500;
}

.legend-box {
  width: 12px;
  height: 12px;
  border-radius: 3px;
}

.legend-box.placement-bg {
  background: #2563eb;
}

.legend-box.registration-bg {
  background: #f97316;
}

.section-title {
  font-size: 15px;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 16px;
  padding-bottom: 12px;
  border-bottom: 1px solid #f1f5f9;
}

.report-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.report-table thead {
  background: #f8fafc;
}

.report-table th {
  text-align: left;
  padding: 12px 14px;
  font-size: 11px;
  font-weight: 700;
  color: #94a3b8;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  border-bottom: 1px solid #f1f5f9;
}

.report-table td {
  padding: 12px 14px;
  border-bottom: 1px solid #f8fafc;
  color: #475569;
}

.month-cell {
  font-weight: 600;
  color: #1e293b;
}

.num-cell {
  font-variant-numeric: tabular-nums;
}

.rate-badge {
  display: inline-block;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 700;
}

.rate-badge.high {
  background: #f0fdf4;
  color: #22c55e;
}

.rate-badge.medium {
  background: #eff6ff;
  color: #3b82f6;
}

.rate-badge.low {
  background: #fff7ed;
  color: #f97316;
}
</style>
