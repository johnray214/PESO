<template>
  <div class="page">
    <div class="builder-layout">

      <!-- LEFT: Report Builder Panel -->
      <div class="builder-panel">

        <!-- Report Type -->
        <div class="builder-section">
          <p class="builder-section-title">Report Type</p>
          <div class="report-type-grid">
            <button v-for="rt in reportTypes" :key="rt.value"
              class="report-type-btn"
              :class="{ active: form.reportType === rt.value }"
              @click="selectReportType(rt.value)">
              <span class="rt-icon" :style="{ background: rt.bg, color: rt.color }" v-html="rt.icon"></span>
              <span class="rt-label">{{ rt.label }}</span>
            </button>
          </div>
        </div>

        <!-- Date Range -->
        <div class="builder-section">
          <p class="builder-section-title">Date Range</p>
          <div class="date-presets">
            <button v-for="p in datePresets" :key="p.value"
              class="preset-btn"
              :class="{ active: form.datePreset === p.value }"
              @click="selectPreset(p)">{{ p.label }}</button>
          </div>
          <div class="date-range-inputs">
            <div class="date-field">
              <label>From</label>
              <input v-model="form.dateFrom" type="date" class="date-input"/>
            </div>
            <div class="date-sep">—</div>
            <div class="date-field">
              <label>To</label>
              <input v-model="form.dateTo" type="date" class="date-input"/>
            </div>
          </div>
        </div>

        <!-- Filters (dynamic based on report type) -->
        <div class="builder-section" v-if="form.reportType">
          <p class="builder-section-title">Filters</p>

          <!-- Placement filters -->
          <template v-if="form.reportType === 'placement'">
            <div class="filter-row">
              <label class="filter-label">Status</label>
              <select v-model="form.filters.status" class="filter-select">
                <option value="">All Statuses</option>
                <option>Placed</option>
                <option>Processing</option>
                <option>Rejected</option>
              </select>
            </div>
            <div class="filter-row">
              <label class="filter-label">Industry</label>
              <select v-model="form.filters.industry" class="filter-select">
                <option value="">All Industries</option>
                <option>BPO / Call Center</option>
                <option>IT / Tech</option>
                <option>Healthcare</option>
                <option>Finance</option>
                <option>Retail</option>
              </select>
            </div>
          </template>

          <!-- Registration filters -->
          <template v-else-if="form.reportType === 'registration'">
            <div class="filter-row">
              <label class="filter-label">Type</label>
              <select v-model="form.filters.regType" class="filter-select">
                <option value="">All Types</option>
                <option>Jobseeker</option>
                <option>Employer</option>
              </select>
            </div>
            <div class="filter-row">
              <label class="filter-label">City / Area</label>
              <select v-model="form.filters.city" class="filter-select">
                <option value="">All Cities</option>
                <option>Quezon City</option>
                <option>Marikina</option>
                <option>Pasig</option>
                <option>Caloocan</option>
                <option>Taguig</option>
              </select>
            </div>
          </template>

          <!-- Skills / Jobs filters -->
          <template v-else-if="form.reportType === 'skills'">
            <div class="filter-row">
              <label class="filter-label">Skill Category</label>
              <select v-model="form.filters.skillCategory" class="filter-select">
                <option value="">All Categories</option>
                <option>IT / Programming</option>
                <option>Customer Service</option>
                <option>Healthcare</option>
                <option>Accounting</option>
                <option>Skilled Trades</option>
              </select>
            </div>
            <div class="filter-row">
              <label class="filter-label">View</label>
              <select v-model="form.filters.skillView" class="filter-select">
                <option value="">Demand & Supply</option>
                <option>Demand Only</option>
                <option>Supply Only</option>
                <option>Gap Analysis</option>
              </select>
            </div>
          </template>

          <!-- Events filters -->
          <template v-else-if="form.reportType === 'events'">
            <div class="filter-row">
              <label class="filter-label">Event Type</label>
              <select v-model="form.filters.eventType" class="filter-select">
                <option value="">All Types</option>
                <option>Job Fair</option>
                <option>Seminar</option>
                <option>Training</option>
              </select>
            </div>
            <div class="filter-row">
              <label class="filter-label">Status</label>
              <select v-model="form.filters.eventStatus" class="filter-select">
                <option value="">All</option>
                <option>Upcoming</option>
                <option>Completed</option>
                <option>Cancelled</option>
              </select>
            </div>
          </template>

          <!-- Employer filters -->
          <template v-else-if="form.reportType === 'employer'">
            <div class="filter-row">
              <label class="filter-label">Verification</label>
              <select v-model="form.filters.verificationStatus" class="filter-select">
                <option value="">All Statuses</option>
                <option>Verified</option>
                <option>Pending</option>
                <option>Rejected</option>
              </select>
            </div>
            <div class="filter-row">
              <label class="filter-label">Industry</label>
              <select v-model="form.filters.industry" class="filter-select">
                <option value="">All Industries</option>
                <option>BPO / Call Center</option>
                <option>IT / Tech</option>
                <option>Healthcare</option>
                <option>Finance</option>
                <option>Retail</option>
              </select>
            </div>
          </template>

          <!-- Skill Match filters -->
          <template v-else-if="form.reportType === 'skillmatch'">
            <div class="filter-row">
              <label class="filter-label">Min Match %</label>
              <div class="range-row">
                <input v-model="form.filters.minMatch" type="range" min="0" max="100" step="5" class="range-input"/>
                <span class="range-val">{{ form.filters.minMatch || 0 }}%</span>
              </div>
            </div>
            <div class="filter-row">
              <label class="filter-label">Job Category</label>
              <select v-model="form.filters.jobCategory" class="filter-select">
                <option value="">All Categories</option>
                <option>IT / Tech</option>
                <option>Healthcare</option>
                <option>Finance</option>
                <option>Customer Service</option>
              </select>
            </div>
          </template>
        </div>

        <!-- Columns to Include -->
        <div class="builder-section" v-if="form.reportType">
          <p class="builder-section-title">Columns to Include</p>
          <div class="columns-list">
            <label v-for="col in availableColumns" :key="col.key" class="col-checkbox">
              <input type="checkbox" v-model="form.columns" :value="col.key"/>
              <span class="col-label">{{ col.label }}</span>
            </label>
          </div>
        </div>

        <!-- Group By -->
        <div class="builder-section" v-if="form.reportType">
          <p class="builder-section-title">Group By</p>
          <div class="groupby-row">
            <button v-for="g in groupByOptions" :key="g.value"
              class="groupby-btn"
              :class="{ active: form.groupBy === g.value }"
              @click="form.groupBy = g.value">{{ g.label }}</button>
          </div>
        </div>

        <!-- Format -->
        <div class="builder-section" v-if="form.reportType">
          <p class="builder-section-title">Export Format</p>
          <div class="format-row">
            <button v-for="fmt in exportFormats" :key="fmt.value"
              class="format-btn"
              :class="{ active: form.exportFormat === fmt.value }"
              @click="form.exportFormat = fmt.value">
              <span v-html="fmt.icon"></span>
              {{ fmt.label }}
            </button>
          </div>
        </div>

        <!-- Actions bottom of options -->
        <div class="builder-section" style="border-top: 1px solid #f1f5f9; background: #fafaf9; border-bottom: none;">
          <div class="header-actions" style="justify-content: flex-end;">
            <button class="btn-secondary" @click="resetForm">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 102.13-9.36L1 10"/></svg>
              Reset
            </button>
            <button class="btn-primary" :disabled="!canGenerate" @click="generateReport">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 11-2.12-9.36L23 10"/></svg>
              Generate Report
            </button>
            <button class="btn-export" :disabled="!reportGenerated" @click="exportReport">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
              Export
            </button>
          </div>
        </div>

      </div>

      <!-- RIGHT: Preview Panel -->
      <div class="preview-panel">

        <!-- Empty state -->
        <div v-if="!reportGenerated" class="preview-empty">
          <div class="empty-icon">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
          </div>
          <p class="empty-title">No report generated yet</p>
          <p class="empty-sub">Select a report type, configure your filters, then click <strong>Generate Report</strong>.</p>
        </div>

        <!-- Report Preview -->
        <div v-else class="report-preview">
          <div class="preview-header">
            <div>
              <div class="preview-badge" :style="{ background: activeReportType?.bg, color: activeReportType?.color }">
                <span v-html="activeReportType?.icon"></span>
                {{ activeReportType?.label }}
              </div>
              <h2 class="preview-title">{{ previewTitle }}</h2>
              <p class="preview-meta">{{ form.dateFrom }} — {{ form.dateTo }} · Grouped by {{ form.groupBy }} · {{ previewRows.length }} records</p>
            </div>
            <div class="preview-export-btns">
              <button class="btn-export-sm" @click="exportReport">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                {{ form.exportFormat.toUpperCase() }}
              </button>
            </div>
          </div>

          <!-- Summary strip -->
          <div class="preview-summary">
            <div v-for="s in previewSummary" :key="s.label" class="preview-sum-item">
              <span class="preview-sum-val" :style="{ color: s.color }">{{ s.value }}</span>
              <span class="preview-sum-label">{{ s.label }}</span>
            </div>
          </div>

          <!-- Chart preview -->
          <div class="preview-chart-wrap" v-if="previewBars.length">
            <div class="preview-bar-chart">
              <div v-for="(bar, i) in previewBars" :key="i" class="preview-bar-col">
                <div class="preview-bar-inner">
                  <div class="preview-bar-fill"
                    :style="{ height: (bar.value / maxBarValue * 100) + '%', background: activeReportType?.color || '#2563eb' }">
                  </div>
                </div>
                <span class="preview-bar-label">{{ bar.label }}</span>
              </div>
            </div>
          </div>

          <!-- Data Table -->
          <div class="preview-table-wrap">
            <table class="preview-table">
              <thead>
                <tr>
                  <th v-for="col in selectedColumns" :key="col.key">{{ col.label }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(row, i) in previewRows" :key="i">
                  <td v-for="col in selectedColumns" :key="col.key">
                    <template v-if="col.key === 'status' || col.key === 'verificationStatus'">
                      <span class="tbl-badge" :class="badgeClass(row[col.key])">{{ row[col.key] }}</span>
                    </template>
                    <template v-else-if="col.key === 'rate' || col.key === 'matchScore'">
                      <span class="tbl-badge" :class="rateClass(row[col.key])">{{ row[col.key] }}%</span>
                    </template>
                    <template v-else>{{ row[col.key] }}</template>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

    </div>
  </div>
</template>

<script>
import api from '@/services/api'

export default {
  name: 'ReportingPage',
  data() {
    return {
      reportGenerated: false,
      form: {
        reportType: '',
        dateFrom: '2024-01-01',
        dateTo: '2024-12-31',
        datePreset: '1y',
        filters: {},
        columns: [],
        groupBy: 'Month',
        exportFormat: 'xlsx',
      },
      reportTypes: [
        { value: 'placement',  label: 'Placement',       bg: '#dbeafe', color: '#2563eb', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>` },
        { value: 'registration',label: 'Registration',  bg: '#fff7ed', color: '#f97316', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>` },
        { value: 'skills',     label: 'Skills & Gaps',   bg: '#faf5ff', color: '#8b5cf6', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>` },
        { value: 'events',     label: 'Events',          bg: '#f0fdf4', color: '#22c55e', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>` },
        { value: 'employer',   label: 'Employers',       bg: '#eff6ff', color: '#3b82f6', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>` },
        { value: 'skillmatch', label: 'Skill Match',     bg: '#ecfdf5', color: '#10b981', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>` },
      ],
      datePresets: [
        { label: 'This Month', value: '1m', from: '2024-12-01', to: '2024-12-31' },
        { label: 'Last 3M',    value: '3m', from: '2024-10-01', to: '2024-12-31' },
        { label: 'Last 6M',    value: '6m', from: '2024-07-01', to: '2024-12-31' },
        { label: 'This Year',  value: '1y', from: '2024-01-01', to: '2024-12-31' },
      ],
      exportFormats: [
        { value: 'xlsx', label: 'Excel',  icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>` },
        { value: 'pdf',  label: 'PDF',    icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>` },
        { value: 'csv',  label: 'CSV',    icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>` },
      ],
      // Column definitions per report type
      columnDefs: {
        placement:    [{ key: 'month', label: 'Month' }, { key: 'name', label: 'Applicant' }, { key: 'company', label: 'Employer' }, { key: 'position', label: 'Position' }, { key: 'industry', label: 'Industry' }, { key: 'status', label: 'Status' }, { key: 'date', label: 'Date' }],
        registration: [{ key: 'month', label: 'Month' }, { key: 'name', label: 'Name' }, { key: 'type', label: 'Type' }, { key: 'city', label: 'City' }, { key: 'skills', label: 'Skills' }, { key: 'date', label: 'Date' }],
        skills:       [{ key: 'skill', label: 'Skill' }, { key: 'demand', label: 'Demand %' }, { key: 'supply', label: 'Supply %' }, { key: 'gap', label: 'Gap' }, { key: 'trend', label: 'Trend' }, { key: 'postings', label: 'Postings' }],
        events:       [{ key: 'title', label: 'Event' }, { key: 'type', label: 'Type' }, { key: 'date', label: 'Date' }, { key: 'location', label: 'Location' }, { key: 'slots', label: 'Slots' }, { key: 'attended', label: 'Attended' }, { key: 'status', label: 'Status' }],
        employer:     [{ key: 'company', label: 'Company' }, { key: 'industry', label: 'Industry' }, { key: 'city', label: 'City' }, { key: 'verificationStatus', label: 'Status' }, { key: 'vacancies', label: 'Vacancies' }, { key: 'date', label: 'Registered' }],
        skillmatch:   [{ key: 'name', label: 'Applicant' }, { key: 'topSkill', label: 'Top Skill' }, { key: 'matchScore', label: 'Match %' }, { key: 'bestFor', label: 'Best For' }, { key: 'city', label: 'City' }],
      },
      groupByOptions: [
        { label: 'Month', value: 'Month' }, { label: 'Week', value: 'Week' },
        { label: 'Industry', value: 'Industry' }, { label: 'City', value: 'City' },
      ],
      // Sample preview data per report type
      sampleData: {
        placement: [
          { month: 'October', name: 'Maria Santos',   company: 'Accenture PH',   position: 'CSR',              industry: 'BPO',        status: 'Placed',      date: 'Oct 14' },
          { month: 'October', name: 'Juan dela Cruz', company: 'Nexus Tech',     position: 'Web Developer',    industry: 'IT',         status: 'Processing',  date: 'Oct 18' },
          { month: 'November',name: 'Ana Reyes',      company: 'MediCare Diag.', position: 'Registered Nurse', industry: 'Healthcare', status: 'Placed',      date: 'Nov 02' },
          { month: 'November',name: 'Pedro Lim',      company: 'SM Supermalls',  position: 'Sales Associate',  industry: 'Retail',     status: 'Placed',      date: 'Nov 10' },
          { month: 'December',name: 'Rosa Garcia',    company: 'BrightPath BPO', position: 'Team Leader',      industry: 'BPO',        status: 'Processing',  date: 'Dec 05' },
          { month: 'December',name: 'Marco Dela Cruz',company: 'Ayala Corp',     position: 'Accountant',       industry: 'Finance',    status: 'Placed',      date: 'Dec 08' },
        ],
        registration: [
          { month: 'October', name: 'Maria Santos',   type: 'Jobseeker', city: 'Quezon City', skills: 'Accounting', date: 'Oct 05' },
          { month: 'October', name: 'Nexus Tech',     type: 'Employer',  city: 'Pasig',       skills: 'IT / Dev',   date: 'Oct 12' },
          { month: 'November',name: 'Ana Reyes',      type: 'Jobseeker', city: 'Marikina',    skills: 'Nursing',    date: 'Nov 01' },
          { month: 'November',name: 'FreshMart',      type: 'Employer',  city: 'Marikina',    skills: 'Retail',     date: 'Nov 15' },
          { month: 'December',name: 'Pedro Lim',      type: 'Jobseeker', city: 'Caloocan',    skills: 'Electrical', date: 'Dec 03' },
          { month: 'December',name: 'BuildRight Co.', type: 'Employer',  city: 'Valenzuela',  skills: 'Construction',date:'Dec 07' },
        ],
        skills: [
          { skill: 'Customer Service',    demand: 85, supply: 80, gap: '-5%',  trend: '↑ 18%', postings: 214 },
          { skill: 'IT / Programming',    demand: 78, supply: 42, gap: '-36%', trend: '↑ 24%', postings: 165 },
          { skill: 'Data Analytics',      demand: 65, supply: 28, gap: '-37%', trend: '↑ 31%', postings: 98 },
          { skill: 'Healthcare / Nursing',demand: 72, supply: 55, gap: '-17%', trend: '↓ 3%',  postings: 130 },
          { skill: 'Accounting / Finance',demand: 60, supply: 58, gap: '-2%',  trend: '↑ 7%',  postings: 142 },
          { skill: 'Skilled Trades',      demand: 55, supply: 30, gap: '-25%', trend: '↑ 12%', postings: 88 },
        ],
        events: [
          { title: 'Job Fair 2024 — QC',      type: 'Job Fair', date: 'Dec 12', location: 'QC Sports Club', slots: 200, attended: 185, status: 'Completed' },
          { title: 'Livelihood Seminar',       type: 'Seminar',  date: 'Dec 18', location: 'City Hall Annex',slots: 80,  attended: 72,  status: 'Completed' },
          { title: 'Skills Training — BPO',    type: 'Training', date: 'Dec 22', location: 'TESDA Center',   slots: 50,  attended: 48,  status: 'Completed' },
          { title: 'IT Job Fair',              type: 'Job Fair', date: 'Jan 15', location: 'SM Megamall',    slots: 300, attended: 0,   status: 'Upcoming' },
          { title: 'Entrepreneurship Forum',   type: 'Seminar',  date: 'Jan 20', location: 'City Hall',      slots: 100, attended: 0,   status: 'Upcoming' },
        ],
        employer: [
          { company: 'Nexus Tech Solutions', industry: 'IT / Software',  city: 'Quezon City', verificationStatus: 'Verified', vacancies: 12, date: 'Mar 5' },
          { company: 'BrightPath BPO Corp.', industry: 'BPO',            city: 'Pasig',       verificationStatus: 'Verified', vacancies: 28, date: 'Feb 28' },
          { company: 'FreshMart Retail',     industry: 'Retail',          city: 'Marikina',    verificationStatus: 'Pending',  vacancies: 8,  date: 'Mar 1' },
          { company: 'MediCare Diagnostics', industry: 'Healthcare',      city: 'Caloocan',    verificationStatus: 'Rejected', vacancies: 0,  date: 'Feb 20' },
          { company: 'BuildRight Const.',    industry: 'Construction',    city: 'Valenzuela',  verificationStatus: 'Pending',  vacancies: 5,  date: 'Mar 7' },
        ],
        skillmatch: [
          { name: 'Maria Santos',   topSkill: 'Vue.js',     matchScore: 96, bestFor: 'Software Developer',   city: 'Quezon City' },
          { name: 'Juan dela Cruz', topSkill: 'Encoding',   matchScore: 91, bestFor: 'Data Entry Clerk',     city: 'Marikina' },
          { name: 'Ana Reyes',      topSkill: 'Patient Care',matchScore: 88,bestFor: 'Registered Nurse',     city: 'Pasig' },
          { name: 'Rosa Garcia',    topSkill: 'QuickBooks', matchScore: 85, bestFor: 'Bookkeeper',           city: 'Taguig' },
          { name: 'Pedro Lim',      topSkill: 'English',    matchScore: 82, bestFor: 'Customer Service Rep', city: 'Caloocan' },
        ],
      },
      summaryDefs: {
        placement:    [{ label: 'Total Records', color: '#1e293b', key: 'total' }, { label: 'Placed',   color: '#22c55e', key: 'placed' }, { label: 'Processing', color: '#f97316', key: 'processing' }],
        registration: [{ label: 'Total Records', color: '#1e293b', key: 'total' }, { label: 'Jobseekers',color: '#2563eb',key:'jobseeker'}, { label: 'Employers', color: '#f97316', key: 'employer' }],
        skills:       [{ label: 'Skills Tracked',color: '#1e293b', key: 'total' }, { label: 'In Demand', color: '#2563eb', key: 'demand' }, { label: 'Skill Gaps',  color: '#ef4444', key: 'gaps' }],
        events:       [{ label: 'Total Events', color: '#1e293b', key: 'total' }, { label: 'Completed', color: '#22c55e', key: 'completed'}, { label: 'Upcoming',  color: '#2563eb', key: 'upcoming' }],
        employer:     [{ label: 'Total Employers',color:'#1e293b', key: 'total' }, { label: 'Verified',  color: '#22c55e', key: 'verified' }, { label: 'Pending',   color: '#f59e0b', key: 'pending' }],
        skillmatch:   [{ label: 'Applicants',   color: '#1e293b', key: 'total' }, { label: 'Avg Match', color: '#10b981', key: 'avg' }, { label: 'High Match (90+)',color:'#22c55e',key:'high'}],
      },
    }
  },
  computed: {
    canGenerate() {
      return this.form.reportType && this.form.dateFrom && this.form.dateTo
    },
    availableColumns() {
      return this.columnDefs[this.form.reportType] || []
    },
    selectedColumns() {
      const all = this.columnDefs[this.form.reportType] || []
      if (!this.form.columns.length) return all
      return all.filter(c => this.form.columns.includes(c.key))
    },
    activeReportType() {
      return this.reportTypes.find(r => r.value === this.form.reportType)
    },
    previewTitle() {
      const names = { placement: 'Placement Report', registration: 'Registration Report', skills: 'Skills & Gaps Report', events: 'Events Report', employer: 'Employer Report', skillmatch: 'Skill Match Report' }
      return names[this.form.reportType] || 'Report'
    },
    previewRows() {
      return this.sampleData[this.form.reportType] || []
    },
    previewSummary() {
      const defs = this.summaryDefs[this.form.reportType] || []
      const rows = this.previewRows
      return defs.map(d => {
        let value
        if (d.key === 'total')      value = rows.length
        else if (d.key === 'placed')     value = rows.filter(r => r.status === 'Placed').length
        else if (d.key === 'processing') value = rows.filter(r => r.status === 'Processing').length
        else if (d.key === 'jobseeker')  value = rows.filter(r => r.type === 'Jobseeker').length
        else if (d.key === 'employer')   value = rows.filter(r => r.type === 'Employer').length
        else if (d.key === 'demand')     value = rows.filter(r => r.demand > 70).length
        else if (d.key === 'gaps')       value = rows.filter(r => (r.demand - r.supply) > 20).length
        else if (d.key === 'completed')  value = rows.filter(r => r.status === 'Completed').length
        else if (d.key === 'upcoming')   value = rows.filter(r => r.status === 'Upcoming').length
        else if (d.key === 'verified')   value = rows.filter(r => r.verificationStatus === 'Verified').length
        else if (d.key === 'pending')    value = rows.filter(r => r.verificationStatus === 'Pending').length
        else if (d.key === 'avg')        value = Math.round(rows.reduce((s,r) => s + (r.matchScore||0), 0) / rows.length) + '%'
        else if (d.key === 'high')       value = rows.filter(r => r.matchScore >= 90).length
        else value = '—'
        return { label: d.label, value, color: d.color }
      })
    },
    previewBars() {
      const rows = this.previewRows
      if (!rows.length) return []
      if (this.form.reportType === 'placement' || this.form.reportType === 'registration') {
        const months = [...new Set(rows.map(r => r.month))]
        return months.map(m => ({ label: m.slice(0,3), value: rows.filter(r => r.month === m).length }))
      }
      if (this.form.reportType === 'skills') {
        return rows.map(r => ({ label: r.skill.split(' ')[0], value: r.postings }))
      }
      if (this.form.reportType === 'events') {
        return rows.map(r => ({ label: r.title.slice(0,6), value: r.attended || r.slots }))
      }
      if (this.form.reportType === 'skillmatch') {
        return rows.map(r => ({ label: r.name.split(' ')[0], value: r.matchScore }))
      }
      return []
    },
    maxBarValue() {
      return Math.max(...this.previewBars.map(b => b.value), 1)
    },
  },
  methods: {
    selectReportType(val) {
      this.form.reportType = val
      this.form.columns = []
      this.form.filters = {}
      this.reportGenerated = false
    },
    selectPreset(preset) {
      this.form.datePreset = preset.value
      this.form.dateFrom = preset.from
      this.form.dateTo = preset.to
    },
    async generateReport() {
      if (!this.canGenerate) return
      this.reportGenerated = false
      try {
        const { data } = await api.post('/admin/reports/generate', {
          type:      this.form.reportType,
          date_from: this.form.dateFrom,
          date_to:   this.form.dateTo,
          group_by:  this.form.groupBy,
          columns:   this.form.columns,
        })
        if (data.data) this.sampleData[this.form.reportType] = data.data
        this.reportGenerated = true
      } catch (e) {
        console.error(e)
        this.reportGenerated = true
      }
    },
    resetForm() {
      this.form = { reportType: '', dateFrom: '2024-01-01', dateTo: '2024-12-31', datePreset: '1y', filters: {}, columns: [], groupBy: 'Month', exportFormat: 'xlsx' }
      this.reportGenerated = false
    },
    async exportReport() {
      try {
        const response = await api.post('/admin/reports/export', {
          type:      this.form.reportType,
          date_from: this.form.dateFrom,
          date_to:   this.form.dateTo,
          format:    this.form.exportFormat,
          columns:   this.form.columns,
        }, { responseType: 'blob' })
        const url = URL.createObjectURL(new Blob([response.data]))
        const a = document.createElement('a')
        a.href = url
        a.download = `${this.form.reportType}_report.${this.form.exportFormat}`
        a.click()
        URL.revokeObjectURL(url)
      } catch (e) {
        console.error(e)
      }
    },
    badgeClass(val) {
      if (!val) return ''
      const v = val.toLowerCase()
      if (v === 'placed' || v === 'completed' || v === 'verified') return 'badge-green'
      if (v === 'processing' || v === 'upcoming' || v === 'pending') return 'badge-amber'
      if (v === 'rejected' || v === 'cancelled') return 'badge-red'
      return ''
    },
    rateClass(val) {
      if (val >= 85) return 'badge-green'
      if (val >= 70) return 'badge-blue'
      return 'badge-amber'
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

.page { font-family: 'Plus Jakarta Sans', sans-serif; padding: 24px; background: #f8fafc; min-height: 100%; display: flex; flex-direction: column; gap: 20px; overflow-y: auto; }
.reporting-header { display: flex; align-items: flex-start; justify-content: space-between; flex-wrap: wrap; gap: 12px; margin-bottom: 8px; }
.header-actions { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.btn-primary { display: flex; align-items: center; gap: 6px; background: #2563eb; color: #fff; border: none; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; transition: background 0.15s; }
.btn-primary:hover:not(:disabled) { background: #1d4ed8; }
.btn-primary:disabled { opacity: 0.4; cursor: not-allowed; }
.btn-secondary { display: flex; align-items: center; gap: 6px; background: #fff; color: #475569; border: 1px solid #e2e8f0; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.btn-secondary:hover { background: #f8fafc; }
.btn-export { display: flex; align-items: center; gap: 6px; background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.btn-export:hover:not(:disabled) { background: #dcfce7; }
.btn-export:disabled { opacity: 0.4; cursor: not-allowed; }

/* LAYOUT */
.builder-layout { display: flex; flex-direction: column; gap: 20px; align-items: stretch; }

/* BUILDER PANEL */
.builder-panel { background: #fff; border: 1px solid #f1f5f9; border-radius: 14px; overflow: hidden; display: flex; flex-direction: column; }
.builder-section { padding: 18px 20px; border-bottom: 1px solid #f1f5f9; }
.builder-section:last-child { border-bottom: none; }
.builder-section-title { font-size: 11px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 12px; }

/* REPORT TYPE GRID */
.report-type-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(130px, 1fr)); gap: 8px; }
.report-type-btn { display: flex; flex-direction: column; align-items: center; gap: 7px; padding: 12px 8px; border: 1.5px solid #f1f5f9; border-radius: 10px; background: #f8fafc; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.report-type-btn:hover { border-color: #e2e8f0; background: #fff; }
.report-type-btn.active { border-color: #2563eb; background: #eff6ff; }
.rt-icon { width: 32px; height: 32px; border-radius: 8px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.rt-label { font-size: 11.5px; font-weight: 600; color: #475569; }
.report-type-btn.active .rt-label { color: #2563eb; }

/* DATE PRESETS */
.date-presets { display: flex; gap: 6px; margin-bottom: 12px; flex-wrap: wrap; }
.preset-btn { padding: 5px 12px; border: 1px solid #e2e8f0; border-radius: 6px; background: #f8fafc; font-size: 12px; font-weight: 600; color: #64748b; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.preset-btn:hover { background: #f1f5f9; }
.preset-btn.active { background: #eff6ff; border-color: #2563eb; color: #2563eb; }
.date-range-inputs { display: flex; align-items: center; gap: 8px; }
.date-field { display: flex; flex-direction: column; gap: 4px; flex: 1; }
.date-field label { font-size: 10.5px; font-weight: 600; color: #94a3b8; }
.date-input { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 7px 10px; font-size: 12px; color: #1e293b; font-family: inherit; outline: none; width: 100%; }
.date-input:focus { border-color: #2563eb; }
.date-sep { color: #94a3b8; font-size: 13px; margin-top: 14px; }

/* FILTERS */
.filter-row { display: flex; flex-direction: column; gap: 4px; margin-bottom: 10px; }
.filter-row:last-child { margin-bottom: 0; }
.filter-label { font-size: 11px; font-weight: 600; color: #64748b; }
.filter-select { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 7px 10px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }
.range-row { display: flex; align-items: center; gap: 10px; }
.range-input { flex: 1; accent-color: #2563eb; }
.range-val { font-size: 12px; font-weight: 700; color: #2563eb; min-width: 32px; }

/* COLUMNS */
.columns-list { display: flex; gap: 12px; flex-wrap: wrap; }
.col-checkbox { display: flex; align-items: center; gap: 8px; cursor: pointer; }
.col-checkbox input[type="checkbox"] { accent-color: #2563eb; width: 14px; height: 14px; }
.col-label { font-size: 12.5px; color: #475569; font-weight: 500; }

/* GROUP BY */
.groupby-row { display: flex; gap: 6px; flex-wrap: wrap; }
.groupby-btn { padding: 5px 12px; border: 1px solid #e2e8f0; border-radius: 6px; background: #f8fafc; font-size: 12px; font-weight: 600; color: #64748b; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.groupby-btn:hover { background: #f1f5f9; }
.groupby-btn.active { background: #eff6ff; border-color: #2563eb; color: #2563eb; }

/* FORMAT */
.format-row { display: flex; gap: 8px; }
.format-btn { display: flex; align-items: center; gap: 6px; padding: 7px 14px; border: 1.5px solid #e2e8f0; border-radius: 8px; background: #f8fafc; font-size: 12.5px; font-weight: 600; color: #64748b; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.format-btn:hover { background: #f1f5f9; }
.format-btn.active { background: #eff6ff; border-color: #2563eb; color: #2563eb; }

/* PREVIEW PANEL */
.preview-panel { background: #fff; border: 1px solid #f1f5f9; border-radius: 14px; min-height: 400px; overflow: hidden; }

.preview-empty { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 80px 40px; text-align: center; gap: 12px; }
.empty-icon { width: 72px; height: 72px; background: #f8fafc; border-radius: 16px; display: flex; align-items: center; justify-content: center; }
.empty-title { font-size: 15px; font-weight: 700; color: #475569; }
.empty-sub { font-size: 13px; color: #94a3b8; line-height: 1.6; max-width: 320px; }

.report-preview { display: flex; flex-direction: column; }
.preview-header { display: flex; align-items: flex-start; justify-content: space-between; padding: 20px 24px 16px; border-bottom: 1px solid #f1f5f9; gap: 12px; }
.preview-badge { display: inline-flex; align-items: center; gap: 6px; padding: 4px 10px; border-radius: 8px; font-size: 11px; font-weight: 700; margin-bottom: 8px; }
.preview-title { font-size: 17px; font-weight: 800; color: #1e293b; }
.preview-meta { font-size: 11.5px; color: #94a3b8; margin-top: 3px; }
.preview-export-btns { display: flex; gap: 6px; flex-shrink: 0; }
.btn-export-sm { display: flex; align-items: center; gap: 5px; background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; border-radius: 8px; padding: 7px 12px; font-size: 12px; font-weight: 700; cursor: pointer; font-family: inherit; }
.btn-export-sm:hover { background: #dcfce7; }

/* SUMMARY STRIP */
.preview-summary { display: flex; padding: 14px 24px; gap: 0; border-bottom: 1px solid #f1f5f9; }
.preview-sum-item { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 2px; border-right: 1px solid #f1f5f9; }
.preview-sum-item:last-child { border-right: none; }
.preview-sum-val { font-size: 22px; font-weight: 800; }
.preview-sum-label { font-size: 11px; color: #94a3b8; font-weight: 500; }

/* CHART */
.preview-chart-wrap { padding: 16px 24px; border-bottom: 1px solid #f1f5f9; }
.preview-bar-chart { display: flex; align-items: flex-end; height: 120px; gap: 8px; }
.preview-bar-col { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 5px; height: 100%; }
.preview-bar-inner { flex: 1; width: 100%; display: flex; align-items: flex-end; }
.preview-bar-fill { width: 100%; border-radius: 4px 4px 0 0; min-height: 4px; transition: height 0.4s ease; }
.preview-bar-label { font-size: 9.5px; color: #94a3b8; font-weight: 500; white-space: nowrap; }

/* TABLE */
.preview-table-wrap { overflow-x: auto; }
.preview-table { width: 100%; border-collapse: collapse; font-size: 12.5px; }
.preview-table thead { background: #f8fafc; }
.preview-table th { text-align: left; padding: 11px 16px; font-size: 11px; font-weight: 700; color: #94a3b8; letter-spacing: 0.04em; text-transform: uppercase; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.preview-table td { padding: 11px 16px; border-bottom: 1px solid #f8fafc; color: #475569; white-space: nowrap; }
.preview-table tr:last-child td { border-bottom: none; }
.preview-table td:first-child { font-weight: 600; color: #1e293b; }

.tbl-badge { display: inline-block; padding: 3px 10px; border-radius: 6px; font-size: 11px; font-weight: 700; }
.badge-green { background: #f0fdf4; color: #22c55e; }
.badge-amber { background: #fffbeb; color: #f59e0b; }
.badge-red   { background: #fef2f2; color: #ef4444; }
.badge-blue  { background: #eff6ff; color: #2563eb; }
</style>