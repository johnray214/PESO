<template>
  <div class="page">

    <!-- SKELETON -->
    <template v-if="pageLoading">
      <div class="builder-layout">
        <div class="builder-panel" style="background: transparent; border: none; padding: 0; gap: 20px; display: flex; flex-direction: column;">
          <div v-for="i in 4" :key="i" class="builder-section skel" style="height: 120px; border-radius: 12px; margin: 0;"></div>
        </div>
        <div class="preview-panel skel" style="height: 700px; border-radius: 16px; min-height: unset;"></div>
      </div>
    </template>

    <!-- ACTUAL CONTENT -->
    <div class="builder-layout" v-else>

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

            <button class="preset-btn preset-btn-custom"
              :class="{ active: form.datePreset === 'custom' }"
              @click="selectCustomRange">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
              Custom
            </button>

            <button class="preset-btn preset-btn-none"
              :class="{ active: form.datePreset === 'none' }"
              @click="selectNoDateRange">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/></svg>
              No Range
            </button>
          </div>

          <div v-if="form.datePreset !== 'custom' && form.datePreset !== 'none'" class="date-selected-label">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
            <span>{{ form.dateFrom }}</span>
            <span class="date-label-sep">→</span>
            <span>{{ form.dateTo }}</span>
          </div>

          <div v-if="form.datePreset === 'custom'" class="date-range-inputs">
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

          <div v-if="form.datePreset === 'none'" class="no-date-notice">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            All available data will be included
          </div>
        </div>

        <!-- Filters -->
        <div class="builder-section" v-if="form.reportType">
          <p class="builder-section-title">Filters</p>

          <template v-if="form.reportType === 'placement'">
            <div class="filter-row">
              <label class="filter-label">Status</label>
              <select v-model="form.filters.status" class="filter-select">
                <option value="">All Statuses</option>
                <option>Placed</option><option>Processing</option><option>Rejected</option>
              </select>
            </div>
            <div class="filter-row">
              <label class="filter-label">Industry</label>
              <select v-model="form.filters.industry" class="filter-select">
                <option value="">All Industries</option>
                <option>BPO / Call Center</option><option>IT / Tech</option><option>Healthcare</option><option>Finance</option><option>Retail</option>
              </select>
            </div>
          </template>

          <template v-else-if="form.reportType === 'registration'">
            <div class="filter-row">
              <label class="filter-label">Type</label>
              <select v-model="form.filters.regType" class="filter-select">
                <option value="">All Types</option><option>Jobseeker</option><option>Employer</option>
              </select>
            </div>
            <div class="filter-row">
              <label class="filter-label">City / Area</label>
              <select v-model="form.filters.city" class="filter-select">
                <option value="">All Cities</option>
                <option>Quezon City</option><option>Marikina</option><option>Pasig</option><option>Caloocan</option><option>Taguig</option>
              </select>
            </div>
          </template>

          <template v-else-if="form.reportType === 'skills'">
            <div class="filter-row">
              <label class="filter-label">Skill Category</label>
              <select v-model="form.filters.skillCategory" class="filter-select">
                <option value="">All Categories</option>
                <option>IT / Programming</option><option>Customer Service</option><option>Healthcare</option><option>Accounting</option><option>Skilled Trades</option>
              </select>
            </div>
            <div class="filter-row">
              <label class="filter-label">View</label>
              <select v-model="form.filters.skillView" class="filter-select">
                <option value="">Demand &amp; Supply</option><option>Demand Only</option><option>Supply Only</option><option>Gap Analysis</option>
              </select>
            </div>
          </template>

          <template v-else-if="form.reportType === 'events'">
            <div class="filter-row">
              <label class="filter-label">Event Type</label>
              <select v-model="form.filters.eventType" class="filter-select">
                <option value="">All Types</option><option>Job Fair</option><option>Seminar</option><option>Training</option>
              </select>
            </div>
            <div class="filter-row">
              <label class="filter-label">Status</label>
              <select v-model="form.filters.eventStatus" class="filter-select">
                <option value="">All</option><option>Upcoming</option><option>Completed</option><option>Cancelled</option>
              </select>
            </div>
          </template>

          <!-- ✅ FIXED: Added Suspended option -->
          <template v-else-if="form.reportType === 'employer'">
            <div class="filter-row">
              <label class="filter-label">Verification</label>
              <select v-model="form.filters.verificationStatus" class="filter-select">
                <option value="">All Statuses</option>
                <option>Verified</option>
                <option>Pending</option>
                <option>Rejected</option>
                <option>Suspended</option>
              </select>
            </div>
            <div class="filter-row">
              <label class="filter-label">Industry</label>
              <select v-model="form.filters.industry" class="filter-select">
                <option value="">All Industries</option>
                <option>BPO / Call Center</option><option>IT / Tech</option><option>Healthcare</option><option>Finance</option><option>Retail</option>
              </select>
            </div>
          </template>

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
                <option>IT / Tech</option><option>Healthcare</option><option>Finance</option><option>Customer Service</option>
              </select>
            </div>
          </template>

          <template v-else-if="form.reportType === 'feedback'">
            <div class="filter-row">
              <label class="filter-label">Rating</label>
              <select v-model="form.filters.rating" class="filter-select">
                <option value="">All Ratings</option>
                <option value="5">5 Stars ★★★★★</option>
                <option value="4">4 Stars ★★★★☆</option>
                <option value="3">3 Stars ★★★☆☆</option>
                <option value="2">2 Stars ★★☆☆☆</option>
                <option value="1">1 Star  ★☆☆☆☆</option>
              </select>
            </div>
            <div class="filter-row">
              <label class="filter-label">Submitted By</label>
              <select v-model="form.filters.submittedBy" class="filter-select">
                <option value="">All</option><option>Jobseeker</option><option>Employer</option>
              </select>
            </div>
          </template>
        </div>

        <!-- Columns -->
        <div class="builder-section" v-if="form.reportType">
          <p class="builder-section-title">Columns to Include</p>
          <div class="columns-list">
            <label v-for="col in availableColumns" :key="col.key" class="col-checkbox">
              <input type="checkbox" v-model="form.columns" :value="col.key"/>
              <span class="col-label">{{ col.label }}</span>
            </label>
          </div>
        </div>


        <!-- Export Format -->
        <div class="builder-section" v-if="form.reportType">
          <p class="builder-section-title">Export Format</p>
          <div class="format-row">
            <button v-for="fmt in exportFormats" :key="fmt.value"
              class="format-btn"
              :class="[{ active: form.exportFormat === fmt.value }, `format-btn-${fmt.value}`]"
              @click="form.exportFormat = fmt.value">
              <span v-html="fmt.icon"></span>{{ fmt.label }}
            </button>
          </div>
        </div>

        <!-- Actions -->
        <div class="builder-section action-section">
          <!-- ✅ FIXED: Error message shown when API fails -->
          <div v-if="errorMessage" class="error-banner">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            {{ errorMessage }}
          </div>
          <div class="header-actions">
            <button class="btn-secondary" @click="resetForm">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 102.13-9.36L1 10"/></svg>
              Reset
            </button>
            <button class="btn-primary" :class="{ generating: isGenerating }" :disabled="!canGenerate || isGenerating" @click="generateReport">
              <span class="btn-primary-inner">
                <span v-if="isGenerating" class="spin-icon">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/></svg>
                </span>
                <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 11-2.12-9.36L23 10"/></svg>
                {{ isGenerating ? 'Generating...' : 'Generate Report' }}
              </span>
            </button>
            <button class="btn-export" :class="`btn-export-${form.exportFormat}`"
              :disabled="!reportGenerated || isGenerating || isExporting" @click="exportReport">
              <span v-if="isExporting" class="spin-icon" style="display:inline-flex">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/></svg>
              </span>
              <span v-else v-html="activeExportFormat?.icon"></span>
              {{ isExporting ? 'Exporting...' : 'Export ' + activeExportFormat?.label }}
            </button>
          </div>
        </div>

      </div>

      <!-- RIGHT: Preview Panel -->
      <div class="preview-panel">

        <div v-if="!reportGenerated && !isGenerating" class="preview-empty">
          <div class="empty-icon">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
          </div>
          <p class="empty-title">No report generated yet</p>
          <p class="empty-sub">Select a report type, configure your filters, then click <strong>Generate Report</strong>.</p>
        </div>

        <div v-else-if="isGenerating" class="preview-loading">
          <div class="loading-spinner">
            <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="spinner-svg"><path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/></svg>
          </div>
          <p class="loading-text">Generating your report...</p>
          <p class="loading-sub">Fetching and processing data</p>
        </div>

        <div v-else class="report-preview">
          <div class="preview-header">
            <div>
              <div class="preview-badge" :style="{ background: activeReportType?.bg, color: activeReportType?.color }">
                <span v-html="activeReportType?.icon"></span>{{ activeReportType?.label }}
              </div>
              <h2 class="preview-title">{{ previewTitle }}</h2>
              <p class="preview-meta">
                <template v-if="form.datePreset !== 'none'">{{ form.dateFrom }} — {{ form.dateTo }} · </template>
                <template v-else>All dates · </template>
                 Grouped by month · {{ previewRows.length }} records
              </p>
            </div>
            <div class="preview-export-btns">
              <button class="btn-export-sm" :class="`btn-export-sm-${form.exportFormat}`" :disabled="isExporting" @click="exportReport">
                <span v-if="isExporting" class="spin-icon" style="display:inline-flex">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/></svg>
                </span>
                <template v-else>
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                </template>
                {{ isExporting ? 'Exporting...' : activeExportFormat?.label }}
              </button>
            </div>
          </div>

          <div class="preview-summary">
            <div v-for="s in previewSummary" :key="s.label" class="preview-sum-item">
              <span class="preview-sum-val" :style="{ color: s.color }">{{ s.value }}</span>
              <span class="preview-sum-label">{{ s.label }}</span>
            </div>
          </div>

          <div class="preview-chart-wrap" v-if="previewBars.length">
            <div class="preview-bar-chart">
              <div v-for="(bar, i) in visibleBars" :key="i" class="preview-bar-col">
                <span class="preview-bar-val">{{ bar.value }}</span>
                <div class="preview-bar-inner">
                  <div class="preview-bar-fill" :style="{ height: (bar.value / maxBarValue * 100) + '%', background: activeReportType?.color || '#2563eb' }"></div>
                </div>
                <span class="preview-bar-label">{{ bar.label }}</span>
              </div>
            </div>
          </div>

          <!-- ✅ FIXED: empty state when no rows match the filter -->
          <div v-if="previewRows.length === 0" class="preview-no-results">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            <p>No records match the selected filters.</p>
          </div>

          <div v-else class="preview-table-wrap">
            <table class="preview-table">
              <thead>
                <tr>
                  <th>No.</th>
                  <th v-for="col in selectedColumns" :key="col.key">{{ col.label }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(row, i) in previewRows" :key="i">
                  <td style="font-weight: 600; color: #64748b; font-size: 12px; padding-left: 18px;">{{ i + 1 }}</td>
                  <td v-for="col in selectedColumns" :key="col.key">
                    <template v-if="col.key === 'status' || col.key === 'verificationStatus'">
                      <span class="tbl-badge" :class="badgeClass(row[col.key])">{{ row[col.key] }}</span>
                    </template>
                    <template v-else-if="col.key === 'rate' || col.key === 'matchScore'">
                      <span class="tbl-badge" :class="rateClass(row[col.key])">{{ row[col.key] }}%</span>
                    </template>
                    <template v-else-if="col.key === 'rating'">
                      <span class="star-rating">{{ '★'.repeat(row[col.key]) }}{{ '☆'.repeat(5 - row[col.key]) }}</span>
                    </template>
                    <!-- ✅ FIXED: skills may come back as array of objects from API -->
                    <template v-else-if="col.key === 'skills'">
                      <template v-if="Array.isArray(row[col.key])">
                        <span v-for="(sk, si) in row[col.key]" :key="si" class="skill-tag">{{ typeof sk === 'object' ? sk.skill : sk }}</span>
                      </template>
                      <template v-else>{{ row[col.key] }}</template>
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
  mounted() {
    setTimeout(() => {
      this.pageLoading = false
    }, 800)
  },
  data() {
    const now        = new Date()
    const currentDay = now.getDay()
    const diffToMon  = now.getDate() - currentDay + (currentDay === 0 ? -6 : 1)
    const monday     = new Date(now.setDate(diffToMon))
    const weekStart  = `${monday.getFullYear()}-${String(monday.getMonth() + 1).padStart(2, '0')}-${String(monday.getDate()).padStart(2, '0')}`

    now.setTime(new Date().getTime()) // Reset 'now' after modifying it for weekStart
    const yyyy = now.getFullYear()
    const mm   = String(now.getMonth() + 1).padStart(2, '0')
    const dd   = String(now.getDate()).padStart(2, '0')
    const today = `${yyyy}-${mm}-${dd}`
    const yearStart = `${yyyy}-01-01`
    const monthStart = `${yyyy}-${mm}-01`

    const d3 = new Date(now); d3.setMonth(d3.getMonth() - 3)
    const threeAgo = `${d3.getFullYear()}-${String(d3.getMonth()+1).padStart(2,'0')}-01`

    const d6 = new Date(now); d6.setMonth(d6.getMonth() - 6)
    const sixAgo = `${d6.getFullYear()}-${String(d6.getMonth()+1).padStart(2,'0')}-01`

    return {
      pageLoading: true,
      reportGenerated: false,
      isGenerating:    false,
      isExporting:     false,
      errorMessage:    null, // ✅ ADDED: tracks API errors

      form: {
        reportType:   '',
        dateFrom:     yearStart,
        dateTo:       today,
        datePreset:   '1y',
        filters:      {},
        columns:      [],
        exportFormat: 'xlsx',
      },

      datePresets: [
        { label: 'This Week',  value: '1w', from: weekStart,  to: today },
        { label: 'This Month', value: '1m', from: monthStart, to: today },
        { label: 'Last 3M',    value: '3m', from: threeAgo,   to: today },
        { label: 'Last 6M',    value: '6m', from: sixAgo,     to: today },
        { label: 'This Year',  value: '1y', from: yearStart,  to: today },
      ],

      reportTypes: [
        { value: 'placement',    label: 'Placement',     bg: '#dbeafe', color: '#2563eb', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>` },
        { value: 'registration', label: 'Registration',  bg: '#fff7ed', color: '#f97316', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>` },
        { value: 'skills',       label: 'Skills & Gaps', bg: '#faf5ff', color: '#8b5cf6', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>` },
        { value: 'events',       label: 'Events',        bg: '#f0fdf4', color: '#22c55e', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>` },
        { value: 'employer',     label: 'Employers',     bg: '#eff6ff', color: '#3b82f6', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>` },
        { value: 'skillmatch',   label: 'Skill Match',   bg: '#ecfdf5', color: '#10b981', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>` },
        { value: 'feedback',     label: 'Feedback',      bg: '#fdf4ff', color: '#a855f7', icon: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>` },
      ],

      exportFormats: [
        { value: 'xlsx', label: 'Excel', icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="8" y1="13" x2="16" y2="13"/><line x1="8" y1="17" x2="16" y2="17"/></svg>` },
        { value: 'pdf',  label: 'PDF',   icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><path d="M9 13h1a1 1 0 010 2H9v-2z"/></svg>` },
      ],

      columnDefs: {
        placement:    [{ key:'month',label:'Month' },{ key:'name',label:'Applicant' },{ key:'company',label:'Employer' },{ key:'position',label:'Position' },{ key:'industry',label:'Industry' },{ key:'status',label:'Status' },{ key:'date',label:'Date' }],
        registration: [{ key:'month',label:'Month' },{ key:'name',label:'Name' },{ key:'sex',label:'Sex' },{ key:'type',label:'Type' },{ key:'city',label:'City' },{ key:'skills',label:'Skills' },{ key:'date',label:'Date' }],
        skills:       [{ key:'skill',label:'Skill' },{ key:'demand',label:'Demand %' },{ key:'supply',label:'Supply %' },{ key:'gap',label:'Gap' },{ key:'trend',label:'Trend' },{ key:'postings',label:'Postings' }],
        events:       [{ key:'title',label:'Event' },{ key:'type',label:'Type' },{ key:'date',label:'Date' },{ key:'sex',label:'Sex' },{ key:'location',label:'Location' },{ key:'slots',label:'Slots' },{ key:'attended',label:'Attended' },{ key:'status',label:'Status' }],
        employer:     [{ key:'company',label:'Company' },{ key:'industry',label:'Industry' },{ key:'city',label:'City' },{ key:'verificationStatus',label:'Status' },{ key:'vacancies',label:'Vacancies' },{ key:'date',label:'Registered' }],
        skillmatch:   [{ key:'name',label:'Applicant' },{ key:'topSkill',label:'Top Skill' },{ key:'matchScore',label:'Match %' },{ key:'bestFor',label:'Best For' },{ key:'city',label:'City' }],
        feedback:     [{ key:'name',label:'Submitted By' },{ key:'type',label:'User Type' },{ key:'rating',label:'Rating' },{ key:'comment',label:'Comment' },{ key:'category',label:'Category' },{ key:'date',label:'Date' }],
      },

      groupByOptions: [
        { label: 'Month',    value: 'Month'    },
        { label: 'Week',     value: 'Week'     },
        { label: 'Industry', value: 'Industry' },
        { label: 'City',     value: 'City'     },
      ],

      // ✅ FIXED: liveData holds real API results; sampleData is only shown before first successful generate
      liveData: {},

      // Fallback sample data shown only on initial empty state (never used after first API success)
      sampleData: {
        placement: [
          { month:'January',  name:'Maria Santos',    company:'Accenture PH',    position:'CSR',              industry:'BPO',       status:'Placed',     date:'Jan 14, 2026' },
          { month:'January',  name:'Juan dela Cruz',  company:'Nexus Tech',      position:'Web Developer',    industry:'IT',        status:'Processing', date:'Jan 18, 2026' },
          { month:'February', name:'Ana Reyes',       company:'MediCare Diag.', position:'Registered Nurse', industry:'Healthcare', status:'Placed',     date:'Feb 02, 2026' },
          { month:'February', name:'Pedro Lim',       company:'SM Supermalls',   position:'Sales Associate',  industry:'Retail',    status:'Placed',     date:'Feb 10, 2026' },
          { month:'March',    name:'Rosa Garcia',     company:'BrightPath BPO',  position:'Team Leader',      industry:'BPO',       status:'Processing', date:'Mar 05, 2026' },
          { month:'March',    name:'Marco Dela Cruz', company:'Ayala Corp',      position:'Accountant',       industry:'Finance',   status:'Placed',     date:'Mar 08, 2026' },
        ],
        registration: [
          { month:'January',  name:'Maria Santos',  sex:'Female', type:'Jobseeker', city:'Quezon City', skills:'Accounting',   date:'Jan 05, 2026' },
          { month:'January',  name:'Nexus Tech',    sex:'—',      type:'Employer',  city:'Pasig',       skills:'IT / Dev',     date:'Jan 12, 2026' },
          { month:'February', name:'Ana Reyes',     sex:'Female', type:'Jobseeker', city:'Marikina',    skills:'Nursing',      date:'Feb 01, 2026' },
          { month:'February', name:'FreshMart',     sex:'—',      type:'Employer',  city:'Marikina',    skills:'Retail',       date:'Feb 15, 2026' },
          { month:'March',    name:'Pedro Lim',     sex:'Male',   type:'Jobseeker', city:'Caloocan',    skills:'Electrical',   date:'Mar 03, 2026' },
          { month:'March',    name:'BuildRight Co.',sex:'—',      type:'Employer',  city:'Valenzuela',  skills:'Construction', date:'Mar 07, 2026' },
        ],
        skills: [
          { skill:'Customer Service',    demand:85, supply:80, gap:'-5%',  trend:'↑ 18%', postings:214 },
          { skill:'IT / Programming',    demand:78, supply:42, gap:'-36%', trend:'↑ 24%', postings:165 },
          { skill:'Data Analytics',      demand:65, supply:28, gap:'-37%', trend:'↑ 31%', postings:98  },
          { skill:'Healthcare / Nursing',demand:72, supply:55, gap:'-17%', trend:'↓ 3%',  postings:130 },
          { skill:'Accounting / Finance',demand:60, supply:58, gap:'-2%',  trend:'↑ 7%',  postings:142 },
          { skill:'Skilled Trades',      demand:55, supply:30, gap:'-25%', trend:'↑ 12%', postings:88  },
        ],
        events: [
          { title:'Job Fair 2026 — QC',    type:'Job Fair', date:'Feb 12, 2026', sex:'—', location:'QC Sports Club',  slots:200, attended:185, status:'Completed' },
          { title:'Livelihood Seminar',     type:'Seminar',  date:'Feb 18, 2026', sex:'—', location:'City Hall Annex', slots:80,  attended:72,  status:'Completed' },
          { title:'Skills Training — BPO', type:'Training', date:'Mar 05, 2026', sex:'—', location:'TESDA Center',    slots:50,  attended:48,  status:'Ongoing'   },
          { title:'IT Job Fair',           type:'Job Fair', date:'Apr 15, 2026', sex:'—', location:'SM Megamall',     slots:300, attended:0,   status:'Upcoming'  },
          { title:'Entrepreneurship Forum',type:'Seminar',  date:'Apr 20, 2026', sex:'—', location:'City Hall',       slots:100, attended:0,   status:'Upcoming'  },
        ],
        employer: [
          { company:'Nexus Tech Solutions', industry:'IT / Software', city:'Quezon City', verificationStatus:'Verified',  vacancies:12, date:'Jan 5, 2026'  },
          { company:'BrightPath BPO Corp.', industry:'BPO',           city:'Pasig',       verificationStatus:'Verified',  vacancies:28, date:'Jan 28, 2026' },
          { company:'FreshMart Retail',     industry:'Retail',         city:'Marikina',    verificationStatus:'Pending',   vacancies:8,  date:'Feb 1, 2026'  },
          { company:'MediCare Diagnostics', industry:'Healthcare',     city:'Caloocan',    verificationStatus:'Rejected',  vacancies:0,  date:'Feb 20, 2026' },
          { company:'BuildRight Const.',    industry:'Construction',   city:'Valenzuela',  verificationStatus:'Suspended', vacancies:0,  date:'Mar 7, 2026'  },
        ],
        skillmatch: [
          { name:'Maria Santos',  topSkill:'Vue.js',       matchScore:96, bestFor:'Software Developer',   city:'Quezon City' },
          { name:'Juan dela Cruz',topSkill:'Encoding',     matchScore:91, bestFor:'Data Entry Clerk',     city:'Marikina'    },
          { name:'Ana Reyes',     topSkill:'Patient Care', matchScore:88, bestFor:'Registered Nurse',     city:'Pasig'       },
          { name:'Rosa Garcia',   topSkill:'QuickBooks',   matchScore:85, bestFor:'Bookkeeper',           city:'Taguig'      },
          { name:'Pedro Lim',     topSkill:'English',      matchScore:82, bestFor:'Customer Service Rep', city:'Caloocan'    },
        ],
        feedback: [
          { name:'Maria Santos',   type:'Jobseeker', rating:5, comment:'Very helpful and easy to use!',        category:'System',     date:'Jan 10' },
          { name:'Nexus Tech',     type:'Employer',  rating:4, comment:'Good platform, minor UX issues.',      category:'Platform',   date:'Jan 15' },
          { name:'Ana Reyes',      type:'Jobseeker', rating:5, comment:'Found a job in less than a week!',     category:'Placement',  date:'Feb 03' },
          { name:'Pedro Lim',      type:'Jobseeker', rating:3, comment:'Job listings could be more updated.',  category:'Listings',   date:'Feb 20' },
          { name:'BrightPath BPO', type:'Employer',  rating:4, comment:'Quality applicants, great filtering.', category:'Applicants', date:'Mar 05' },
          { name:'Rosa Garcia',    type:'Jobseeker', rating:2, comment:'Had trouble uploading my resume.',     category:'System',     date:'Mar 10' },
        ],
      },

      summaryDefs: {
        placement:    [{ label:'Total Records',   color:'#1e293b', key:'total'     }, { label:'Placed',          color:'#22c55e', key:'placed'     }, { label:'Processing',       color:'#f97316', key:'processing' }],
        registration: [{ label:'Total Records',   color:'#1e293b', key:'total'     }, { label:'Jobseekers',      color:'#2563eb', key:'jobseeker'  }, { label:'Employers',        color:'#f97316', key:'employer'   }],
        skills:       [{ label:'Skills Tracked',  color:'#1e293b', key:'total'     }, { label:'In Demand',       color:'#2563eb', key:'demand'     }, { label:'Skill Gaps',       color:'#ef4444', key:'gaps'       }],
        events:       [{ label:'Total Events',    color:'#1e293b', key:'total'     }, { label:'Completed',       color:'#22c55e', key:'completed'  }, { label:'Upcoming',         color:'#2563eb', key:'upcoming'   }],
        employer:     [{ label:'Total Employers', color:'#1e293b', key:'total'     }, { label:'Verified',        color:'#22c55e', key:'verified'   }, { label:'Pending',          color:'#f59e0b', key:'pending'    }],
        skillmatch:   [{ label:'Applicants',      color:'#1e293b', key:'total'     }, { label:'Avg Match',       color:'#10b981', key:'avg'        }, { label:'High Match (90+)', color:'#22c55e', key:'high'       }],
        feedback:     [{ label:'Total Feedback',  color:'#1e293b', key:'total'     }, { label:'Avg Rating',      color:'#a855f7', key:'avgRating'  }, { label:'5-Star Reviews',   color:'#22c55e', key:'fiveStar'   }],
      },
    }
  },

  computed: {
    canGenerate() {
      if (!this.form.reportType) return false
      if (this.form.datePreset === 'none') return true
      return !!(this.form.dateFrom && this.form.dateTo)
    },

    availableColumns() { return this.columnDefs[this.form.reportType] || [] },

    selectedColumns() {
      const all = this.columnDefs[this.form.reportType] || []
      return this.form.columns.length ? all.filter(c => this.form.columns.includes(c.key)) : all
    },

    activeReportType()   { return this.reportTypes.find(r => r.value === this.form.reportType) },
    activeExportFormat() { return this.exportFormats.find(f => f.value === this.form.exportFormat) },

    previewTitle() {
      const n = {
        placement:    'Placement Report',
        registration: 'Registration Report',
        skills:       'Skills & Gaps Report',
        events:       'Events Report',
        employer:     'Employer Report',
        skillmatch:   'Skill Match Report',
        feedback:     'Feedback Report',
      }
      return n[this.form.reportType] || 'Report'
    },

    // ✅ FIXED: use liveData after a successful generate, otherwise sampleData
    previewRows() {
      const source = this.reportGenerated
        ? (this.liveData[this.form.reportType] ?? [])
        : (this.sampleData[this.form.reportType] ?? [])

      if (Array.isArray(source)) return source
      if (source?.data && Array.isArray(source.data)) return source.data
      return []
    },

    previewSummary() {
      const defs = this.summaryDefs[this.form.reportType] || []
      const rows = this.previewRows
      return defs.map(d => {
        let v
        if      (d.key === 'total')      v = rows.length
        else if (d.key === 'placed')     v = rows.filter(r => r.status === 'Placed').length
        else if (d.key === 'processing') v = rows.filter(r => r.status === 'Processing').length
        else if (d.key === 'jobseeker')  v = rows.filter(r => r.type === 'Jobseeker').length
        else if (d.key === 'employer')   v = rows.filter(r => r.type === 'Employer').length
        else if (d.key === 'demand')     v = rows.filter(r => r.demand >= 70).length
        else if (d.key === 'gaps')       v = rows.filter(r => (r.demand - r.supply) >= 20).length
        else if (d.key === 'completed')  v = rows.filter(r => r.status === 'Completed').length
        else if (d.key === 'upcoming')   v = rows.filter(r => r.status === 'Upcoming').length
        else if (d.key === 'verified')   v = rows.filter(r => r.verificationStatus === 'Verified').length
        else if (d.key === 'pending')    v = rows.filter(r => r.verificationStatus === 'Pending').length
        else if (d.key === 'avg')        v = rows.length ? Math.round(rows.reduce((s, r) => s + (r.matchScore || 0), 0) / rows.length) + '%' : '0%'
        else if (d.key === 'high')       v = rows.filter(r => r.matchScore >= 90).length
        else if (d.key === 'avgRating')  v = rows.length ? (rows.reduce((s, r) => s + (r.rating || 0), 0) / rows.length).toFixed(1) + '★' : '0★'
        else if (d.key === 'fiveStar')   v = rows.filter(r => r.rating === 5).length
        else v = '—'
        return { label: d.label, value: v, color: d.color }
      })
    },

    previewBars() {
      const rows = this.previewRows
      if (!rows.length) return []
      if (['placement', 'registration'].includes(this.form.reportType)) {
        const months = [...new Set(rows.map(r => r.month))]
        return months.map(m => ({ label: m.slice(0, 3), value: rows.filter(r => r.month === m).length }))
      }
      if (this.form.reportType === 'skills')     return rows.map(r => ({ label: r.skill.split(' ')[0], value: r.postings }))
      if (this.form.reportType === 'events')     return rows.map(r => ({ label: r.title.slice(0, 6),   value: r.attended || r.slots }))
      if (this.form.reportType === 'skillmatch') return rows.map(r => ({ label: r.name.split(' ')[0],  value: r.matchScore }))
      if (this.form.reportType === 'feedback')   return rows.map(r => ({ label: r.name.split(' ')[0],  value: r.rating }))
      return []
    },

    maxBarValue() { return Math.max(...this.previewBars.map(b => b.value), 1) },

    // ✅ Cap to 12 bars max so the chart never overflows the container
    visibleBars() { return this.previewBars.slice(0, 12) },
  },

  methods: {
    selectReportType(val) {
      this.form.reportType = val
      this.form.columns    = []
      this.form.filters    = {}
      this.reportGenerated = false
      this.errorMessage    = null
    },

    selectPreset(p)    { this.form.datePreset = p.value; this.form.dateFrom = p.from; this.form.dateTo = p.to },
    selectCustomRange(){ this.form.datePreset = 'custom' },
    selectNoDateRange(){ this.form.datePreset = 'none'; this.form.dateFrom = ''; this.form.dateTo = '' },

    //           stores result in liveData so sampleData is never polluted
    async generateReport() {
      if (!this.canGenerate) return
      this.reportGenerated = false
      this.isGenerating    = true
      this.errorMessage    = null

      try {
        const payload = {
          type:     this.form.reportType,
          group_by: this.form.groupBy,
          columns:  this.form.columns,
          filters:  this.form.filters,
        }
        if (this.form.datePreset !== 'none') {
          payload.date_from = this.form.dateFrom
          payload.date_to   = this.form.dateTo
        }

        // ✅ FIXED: path is /reports — the axios baseURL already includes /api/admin
        //           so do NOT add /admin/ again here
        const { data } = await api.post('/admin/reports', payload)

        // Backend returns { success, report, data: [...] }
        this.liveData[this.form.reportType] = Array.isArray(data.data) ? data.data : []
        this.reportGenerated = true

      } catch (e) {
        console.error('Report generation failed:', e)
        const msg = e?.response?.data?.message || 'Failed to generate report. Please try again.'
        this.errorMessage = msg
        // ✅ FIXED: do NOT set reportGenerated = true on failure
      } finally {
        this.isGenerating = false
      }
    },

    resetForm() {
      const now       = new Date()
      const yyyy      = now.getFullYear()
      const yearStart = `${yyyy}-01-01`
      const today     = `${yyyy}-${String(now.getMonth()+1).padStart(2,'0')}-${String(now.getDate()).padStart(2,'0')}`

      this.form = {
        reportType:   '',
        dateFrom:     yearStart,
        dateTo:       today,
        datePreset:   '1y',
        filters:      {},
        columns:      [],
        exportFormat: 'xlsx',
      }
      this.reportGenerated = false
      this.isGenerating    = false
      this.errorMessage    = null
      this.liveData        = {}
    },

    async exportReport() {
      if (!this.reportGenerated) return
      this.isExporting = true
      try {
        const payload = {
          type:    this.form.reportType,
          format:  this.form.exportFormat,
          columns: this.form.columns,
          filters: this.form.filters,
        }
        if (this.form.datePreset !== 'none') {
          payload.date_from = this.form.dateFrom
          payload.date_to   = this.form.dateTo
        }

        const res = await api.post('/admin/reports/export', payload, { responseType: 'blob' })
        const mimeType = this.form.exportFormat === 'pdf'
          ? 'application/pdf'
          : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        const blob = new Blob([res.data], { type: mimeType })
        const url  = URL.createObjectURL(blob)
        const a    = document.createElement('a')
        a.href     = url
        a.download = `${this.form.reportType}_report_${new Date().toISOString().slice(0,10)}.${this.form.exportFormat}`
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
      } catch (e) {
        console.error('Export failed:', e)
        this.errorMessage = 'Export failed. Please try again.'
      } finally {
        this.isExporting = false
      }
    },

    badgeClass(val) {
      if (!val) return ''
      const v = val.toLowerCase()
      if (['placed', 'completed', 'verified'].includes(v)) return 'badge-green'
      if (['processing', 'pending'].includes(v)) return 'badge-amber'
      if (v === 'upcoming') return 'badge-blue'
      if (v === 'ongoing') return 'badge-orange'
      if (['rejected', 'cancelled'].includes(v)) return 'badge-red'
      if (v === 'suspended') return 'badge-purple'
      return ''
    },

    rateClass(val) {
      return val >= 85 ? 'badge-green' : val >= 70 ? 'badge-blue' : 'badge-amber'
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

@keyframes shimmer { 0% { background-position: -400px 0; } 100% { background-position: 400px 0; } }
.skel {
  background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%);
  background-size: 400px 100%; animation: shimmer 1.4s infinite linear;
  border-radius: 6px; flex-shrink: 0;
}

.page { font-family:'Plus Jakarta Sans',sans-serif; padding:24px; background:#f8fafc; min-height:100%; display:flex; flex-direction:column; gap:20px; overflow-y:auto; }
.header-actions { display:flex; gap:8px; align-items:center; flex-wrap:wrap; }

/* ── Error Banner ─────────────────────────────────────────── */
.error-banner { display:flex; align-items:center; gap:8px; padding:10px 14px; background:#fef2f2; border:1px solid #fecaca; border-radius:8px; font-size:12.5px; color:#dc2626; font-weight:500; margin-bottom:10px; }

/* ── Buttons ──────────────────────────────────────────────── */
.btn-primary { display:flex; align-items:center; gap:6px; background:linear-gradient(135deg,#2563eb,#1d4ed8); color:#fff; border:none; border-radius:10px; padding:9px 16px; font-size:13px; font-weight:600; cursor:pointer; font-family:inherit; transition:all .2s; box-shadow:0 2px 8px rgba(37,99,235,.3); }
.btn-primary:hover:not(:disabled) { background:linear-gradient(135deg,#1d4ed8,#1e40af); box-shadow:0 4px 16px rgba(37,99,235,.4); transform:translateY(-1px); }
.btn-primary:disabled { opacity:.45; cursor:not-allowed; transform:none; box-shadow:none; }
.btn-primary.generating { background:linear-gradient(135deg,#3b82f6,#2563eb); }
.btn-primary-inner { display:flex; align-items:center; gap:6px; }
@keyframes spin { to { transform:rotate(360deg); } }
.spin-icon { display:inline-flex; animation:spin .8s linear infinite; }
.spinner-svg { animation:spin .9s linear infinite; color:#2563eb; }
.btn-secondary { display:flex; align-items:center; gap:6px; background:#fff; color:#475569; border:1px solid #e2e8f0; border-radius:10px; padding:9px 16px; font-size:13px; font-weight:600; cursor:pointer; font-family:inherit; transition:all .15s; }
.btn-secondary:hover { background:#f8fafc; }
.btn-export { display:flex; align-items:center; gap:6px; border-radius:10px; padding:9px 16px; font-size:13px; font-weight:600; cursor:pointer; font-family:inherit; transition:all .15s; border:1px solid; }
.btn-export:disabled { opacity:.4; cursor:not-allowed; }
.btn-export-xlsx { background:#f0fdf4; color:#16a34a; border-color:#bbf7d0; }
.btn-export-xlsx:hover:not(:disabled) { background:#dcfce7; }
.btn-export-pdf  { background:#fef2f2; color:#dc2626; border-color:#fecaca; }
.btn-export-pdf:hover:not(:disabled)  { background:#fee2e2; }

/* ── Layout ───────────────────────────────────────────────── */
.builder-layout { display:flex; flex-direction:column; gap:20px; }
.builder-panel { background:#fff; border:1px solid #f1f5f9; border-radius:14px; overflow:hidden; display:flex; flex-direction:column; }
.builder-section { padding:18px 20px; border-bottom:1px solid #f1f5f9; }
.action-section { border-top:1px solid #f1f5f9; background:#fafaf9; border-bottom:none; }
.builder-section-title { font-size:11px; font-weight:700; color:#94a3b8; text-transform:uppercase; letter-spacing:.06em; margin-bottom:12px; display:flex; align-items:center; gap:6px; }
.section-tooltip { width:15px; height:15px; background:#e2e8f0; color:#64748b; border-radius:50%; font-size:10px; font-weight:700; cursor:help; display:inline-flex; align-items:center; justify-content:center; }

/* ── Report type ──────────────────────────────────────────── */
.report-type-grid { display:flex; gap:5px; }
.report-type-btn { flex:1; min-width:0; display:flex; flex-direction:column; align-items:center; gap:5px; padding:10px 2px; border:1.5px solid #f1f5f9; border-radius:10px; background:#f8fafc; cursor:pointer; font-family:inherit; transition:all .15s; }
.report-type-btn:hover { border-color:#e2e8f0; background:#fff; }
.report-type-btn.active { border-color:#2563eb; background:#eff6ff; }
.rt-icon { width:26px; height:26px; border-radius:6px; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
.rt-icon svg { width:14px; height:14px; }
.rt-label { font-size:9.5px; font-weight:600; color:#475569; text-align:center; line-height:1.2; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; width:100%; padding:0 2px; }
.report-type-btn.active .rt-label { color:#2563eb; }

/* ── Date presets ─────────────────────────────────────────── */
.date-presets { display:flex; gap:6px; flex-wrap:wrap; margin-bottom:10px; }
.preset-btn { display:flex; align-items:center; gap:5px; padding:5px 11px; border:1px solid #e2e8f0; border-radius:6px; background:#f8fafc; font-size:12px; font-weight:600; color:#64748b; cursor:pointer; font-family:inherit; transition:all .15s; }
.preset-btn:hover { background:#f1f5f9; }
.preset-btn.active { background:#eff6ff; border-color:#2563eb; color:#2563eb; }
.preset-btn-custom { border-style:solid; }
.preset-btn-custom.active { background:#faf5ff; border-color:#8b5cf6; color:#8b5cf6; }
.preset-btn-none { border-style:dashed; }
.preset-btn-none.active { background:#fff7ed; border-color:#f97316; color:#f97316; border-style:solid; }

/* ── Date display ─────────────────────────────────────────── */
.date-selected-label { display:flex; align-items:center; gap:6px; font-size:12px; color:#475569; font-weight:600; padding:7px 10px; background:#f8fafc; border-radius:8px; border:1px solid #e2e8f0; }
.date-label-sep { color:#94a3b8; }
.date-range-inputs { display:flex; align-items:center; gap:8px; margin-top:4px; }
.date-field { display:flex; flex-direction:column; gap:4px; flex:1; }
.date-field label { font-size:10.5px; font-weight:600; color:#94a3b8; }
.date-input { background:#f8fafc; border:1px solid #e2e8f0; border-radius:8px; padding:7px 10px; font-size:12px; color:#1e293b; font-family:inherit; outline:none; width:100%; }
.date-input:focus { border-color:#2563eb; }
.date-sep { color:#94a3b8; font-size:13px; margin-top:14px; }
.no-date-notice { display:flex; align-items:center; gap:6px; font-size:12px; color:#94a3b8; font-weight:500; padding:8px 10px; background:#f8fafc; border-radius:8px; border:1px dashed #e2e8f0; margin-top:4px; }

/* ── Filters ──────────────────────────────────────────────── */
.filter-row { display:flex; flex-direction:column; gap:4px; margin-bottom:10px; }
.filter-row:last-child { margin-bottom:0; }
.filter-label { font-size:11px; font-weight:600; color:#64748b; }
.filter-select { background:#f8fafc; border:1px solid #e2e8f0; border-radius:8px; padding:7px 10px; font-size:12.5px; color:#475569; cursor:pointer; outline:none; font-family:inherit; }
.range-row { display:flex; align-items:center; gap:10px; }
.range-input { flex:1; accent-color:#2563eb; }
.range-val { font-size:12px; font-weight:700; color:#2563eb; min-width:32px; }

/* ── Columns ──────────────────────────────────────────────── */
.columns-list { display:flex; gap:12px; flex-wrap:wrap; }
.col-checkbox { display:flex; align-items:center; gap:8px; cursor:pointer; }
.col-checkbox input[type="checkbox"] { accent-color:#2563eb; width:14px; height:14px; }
.col-label { font-size:12.5px; color:#475569; font-weight:500; }

/* ── Group By ─────────────────────────────────────────────── */
.groupby-row { display:flex; gap:6px; flex-wrap:wrap; margin-bottom:6px; }
.groupby-btn { padding:5px 12px; border:1px solid #e2e8f0; border-radius:6px; background:#f8fafc; font-size:12px; font-weight:600; color:#64748b; cursor:pointer; font-family:inherit; transition:all .15s; }
.groupby-btn:hover { background:#f1f5f9; }
.groupby-btn.active { background:#eff6ff; border-color:#2563eb; color:#2563eb; }
.groupby-hint { font-size:11px; color:#94a3b8; }

/* ── Export format ────────────────────────────────────────── */
.format-row { display:flex; gap:8px; }
.format-btn { display:flex; align-items:center; gap:6px; padding:8px 16px; border-radius:8px; font-size:13px; font-weight:700; cursor:pointer; font-family:inherit; transition:all .15s; border:1.5px solid #e2e8f0; background:#f8fafc; color:#64748b; }
.format-btn:hover { background:#f1f5f9; }
.format-btn-xlsx.active { background:#f0fdf4; border-color:#16a34a; color:#16a34a; }
.format-btn-pdf.active  { background:#fef2f2; border-color:#dc2626; color:#dc2626; }

/* ── Preview panel ────────────────────────────────────────── */
.preview-panel { background:#fff; border:1px solid #f1f5f9; border-radius:14px; min-height:400px; overflow:hidden; }
.preview-empty { display:flex; flex-direction:column; align-items:center; justify-content:center; padding:80px 40px; text-align:center; gap:12px; }
.empty-icon { width:72px; height:72px; background:#f8fafc; border-radius:16px; display:flex; align-items:center; justify-content:center; }
.empty-title { font-size:15px; font-weight:700; color:#475569; }
.empty-sub { font-size:13px; color:#94a3b8; line-height:1.6; max-width:320px; }
.preview-loading { display:flex; flex-direction:column; align-items:center; justify-content:center; padding:80px 40px; gap:14px; }
.loading-spinner { width:64px; height:64px; background:#eff6ff; border-radius:16px; display:flex; align-items:center; justify-content:center; color:#2563eb; }
.loading-text { font-size:15px; font-weight:700; color:#1e293b; }
.loading-sub  { font-size:12.5px; color:#94a3b8; }
.report-preview { display:flex; flex-direction:column; }
.preview-header { display:flex; align-items:flex-start; justify-content:space-between; padding:20px 24px 16px; border-bottom:1px solid #f1f5f9; gap:12px; }
.preview-badge { display:inline-flex; align-items:center; gap:6px; padding:4px 10px; border-radius:8px; font-size:11px; font-weight:700; margin-bottom:8px; }
.preview-title { font-size:17px; font-weight:800; color:#1e293b; }
.preview-meta { font-size:11.5px; color:#94a3b8; margin-top:3px; }
.preview-export-btns { display:flex; gap:6px; flex-shrink:0; }
.btn-export-sm { display:flex; align-items:center; gap:5px; border-radius:8px; padding:7px 12px; font-size:12px; font-weight:700; cursor:pointer; font-family:inherit; border:1px solid; }
.btn-export-sm-xlsx { background:#f0fdf4; color:#16a34a; border-color:#bbf7d0; }
.btn-export-sm-xlsx:hover { background:#dcfce7; }
.btn-export-sm-pdf  { background:#fef2f2; color:#dc2626; border-color:#fecaca; }
.btn-export-sm-pdf:hover  { background:#fee2e2; }
.preview-summary { display:flex; padding:14px 24px; border-bottom:1px solid #f1f5f9; }
.preview-sum-item { flex:1; display:flex; flex-direction:column; align-items:center; gap:2px; border-right:1px solid #f1f5f9; }
.preview-sum-item:last-child { border-right:none; }
.preview-sum-val { font-size:22px; font-weight:800; }
.preview-sum-label { font-size:11px; color:#94a3b8; font-weight:500; }
.preview-chart-wrap { padding:12px 24px 0; border-bottom:1px solid #f1f5f9; }
.preview-bar-chart { display:flex; align-items:flex-end; height:90px; gap:4px; overflow:hidden; }
.preview-bar-col { flex:0 1 calc(100% / 8); max-width:72px; min-width:28px; display:flex; flex-direction:column; align-items:center; gap:3px; height:100%; }
.preview-bar-val { font-size:8.5px; font-weight:700; color:#94a3b8; line-height:1; }
.preview-bar-inner { flex:1; width:100%; display:flex; align-items:flex-end; }
.preview-bar-fill { width:100%; max-width:90px; border-radius:3px 3px 0 0; min-height:3px; transition:height .4s ease; opacity:.85; }
.preview-bar-label { font-size:8.5px; color:#94a3b8; font-weight:500; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; max-width:100%; padding-bottom:6px; }

/* ── No results ───────────────────────────────────────────── */
.preview-no-results { display:flex; flex-direction:column; align-items:center; gap:10px; padding:48px 24px; color:#94a3b8; font-size:13px; font-weight:500; }

/* ── Table ────────────────────────────────────────────────── */
.preview-table-wrap { overflow-x:auto; }
.preview-table { width:100%; border-collapse:collapse; font-size:12.5px; }
.preview-table thead { background:#f8fafc; }
.preview-table th { text-align:left; padding:11px 16px; font-size:11px; font-weight:700; color:#94a3b8; letter-spacing:.04em; text-transform:uppercase; border-bottom:1px solid #f1f5f9; white-space:nowrap; }
.preview-table td { padding:11px 16px; border-bottom:1px solid #f8fafc; color:#475569; white-space:nowrap; }
.preview-table tr:last-child td { border-bottom:none; }
.preview-table td:first-child { font-weight:600; color:#1e293b; }

/* ── Badges ───────────────────────────────────────────────── */
.tbl-badge { display:inline-block; padding:3px 10px; border-radius:6px; font-size:11px; font-weight:700; }
.badge-green  { background:#f0fdf4; color:#22c55e; }
.badge-amber  { background:#fffbeb; color:#f59e0b; }
.badge-red    { background:#fef2f2; color:#ef4444; }
.badge-blue   { background:#eff6ff; color:#2563eb; }
.badge-purple { background:#faf5ff; color:#8b5cf6; }
.badge-orange { background:#fff7ed; color:#f97316; }
.star-rating { color:#f59e0b; font-size:13px; letter-spacing:1px; }
.skill-tag { display:inline-block; background:#f1f5f9; color:#475569; font-size:10.5px; font-weight:600; padding:2px 7px; border-radius:4px; margin:1px 2px 1px 0; }
</style>