<template>
  <div class="lma-page">

    <!-- Toast -->
    <div class="toast-stack" role="status" aria-live="polite">
      <transition-group name="toast">
        <div v-for="t in toasts" :key="t.id" :class="['toast', 'toast-' + t.type]">
          <span class="toast-icon">
            <svg v-if="t.type==='success'" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
            <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          </span>
          <span class="toast-msg">{{ t.message }}</span>
          <button class="toast-close" @click="dismissToast(t.id)">&times;</button>
        </div>
      </transition-group>
    </div>

    <!-- Header -->
    <header class="lma-header">
      <div class="header-left">
        <div class="header-icon">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
        </div>
        <div>
          <h1 class="page-title">LMA Report Generator</h1>
          <p class="page-sub">Upload the Job Vacancies Solicited Excel file to auto-generate the LMA summary</p>
        </div>
      </div>
      <button
        v-if="summary"
        class="btn btn-primary"
        :disabled="downloading"
        @click="downloadReport"
      >
        <svg v-if="!downloading" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
        <span v-else class="btn-spinner"></span>
        {{ downloading ? 'Generating...' : 'Download Excel Report' }}
      </button>
    </header>

    <!-- Upload zone -->
    <div
      v-if="!summary"
      class="upload-zone"
      :class="{ dragging, 'has-file': selectedFile }"
      @dragover.prevent="dragging = true"
      @dragleave.prevent="dragging = false"
      @drop.prevent="onDrop"
      @click="$refs.fileInput.click()"
    >
      <input ref="fileInput" type="file" accept=".xlsx,.xls" hidden @change="onFileChange" />
      <div class="upload-inner">
        <div class="upload-icon-wrap" :class="{ 'upload-icon-ready': !!selectedFile }">
          <svg v-if="!selectedFile" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
          <svg v-else width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
        </div>
        <template v-if="!selectedFile">
          <p class="upload-title">Drop your Excel file here</p>
          <p class="upload-sub">or click to browse — accepts .xlsx / .xls</p>
          <p class="upload-hint">Expected file: <strong>JOB_VACANCIES_SOLICITED</strong> format</p>
        </template>
        <template v-else>
          <p class="upload-title" style="color:#7c3aed">{{ selectedFile.name }}</p>
          <p class="upload-sub">{{ formatBytes(selectedFile.size) }} · Ready to process</p>
          <button class="btn btn-secondary btn-sm" style="margin-top:8px" @click.stop="processFile" :disabled="processing">
            <span v-if="processing" class="btn-spinner"></span>
            {{ processing ? 'Processing...' : 'Process File' }}
          </button>
          <button class="btn-link" @click.stop="resetFile" :disabled="processing">Choose different file</button>
        </template>
      </div>
    </div>

    <!-- Processing skeleton -->
    <template v-if="processing">
      <div class="kpi-grid">
        <div v-for="i in 3" :key="i" class="kpi-card">
          <div class="skel" style="width:40px;height:40px;border-radius:10px;margin-bottom:12px"></div>
          <div class="skel" style="width:80px;height:28px;border-radius:6px;margin-bottom:8px"></div>
          <div class="skel" style="width:130px;height:12px;border-radius:4px"></div>
        </div>
      </div>
      <div class="skel" style="height:260px;border-radius:14px"></div>
      <div class="skel" style="height:220px;border-radius:14px"></div>
    </template>

    <!-- Summary -->
    <template v-else-if="summary">

      <!-- Re-upload bar -->
      <div class="reupload-bar">
        <div class="reupload-left">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
          <span class="reupload-filename">{{ selectedFile.name }}</span>
          <span class="reupload-size">{{ formatBytes(selectedFile.size) }}</span>
        </div>
        <button class="btn-link" @click="resetFile">Upload different file</button>
      </div>

      <!-- KPI Cards -->
      <section class="kpi-grid">
        <article class="kpi-card" style="animation-delay:0s">
          <div class="kpi-icon" style="background:#eff6ff">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 7V5a2 2 0 00-4 0v2"/></svg>
          </div>
          <h2 class="kpi-value">{{ formatNumber(summary.grandTotal) }}</h2>
          <p class="kpi-label">Total Job Vacancies Solicited</p>
          <span class="kpi-sub">Local + Overseas · {{ summary.period }}</span>
        </article>
        <article class="kpi-card" style="animation-delay:0.06s">
          <div class="kpi-icon" style="background:#f0fdf4">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/></svg>
          </div>
          <h2 class="kpi-value">{{ formatNumber(summary.localTotal) }}</h2>
          <p class="kpi-label">Local Vacancies</p>
          <span class="kpi-sub trend-up">{{ summary.localPct }}% of total</span>
        </article>
        <article class="kpi-card" style="animation-delay:0.12s">
          <div class="kpi-icon" style="background:#faf5ff">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#8b5cf6" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 010 20M12 2a15.3 15.3 0 000 20"/></svg>
          </div>
          <h2 class="kpi-value">{{ formatNumber(summary.overseasTotal) }}</h2>
          <p class="kpi-label">Overseas Vacancies</p>
          <span class="kpi-sub trend-purple">{{ summary.overseasPct }}% of total</span>
        </article>
      </section>

      <!-- Table 1 -->
      <section class="card">
        <header class="card-header">
          <div>
            <h3>Table 1. Job Vacancies Solicited</h3>
            <p class="card-sub">Nature of vacancy breakdown · {{ summary.period }}</p>
          </div>
          <span class="table-badge">PESO Santiago City</span>
        </header>
        <div class="table-wrap">
          <table class="lma-table">
            <thead>
              <tr>
                <th>Nature of Vacancy</th>
                <th class="num">No. of Vacancies Solicited</th>
                <th class="num">Percentage</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>Local</td>
                <td class="num">{{ formatNumber(summary.localTotal) }}</td>
                <td class="num">{{ summary.localPct }}%</td>
              </tr>
              <tr>
                <td>Overseas</td>
                <td class="num">{{ formatNumber(summary.overseasTotal) }}</td>
                <td class="num">{{ summary.overseasPct }}%</td>
              </tr>
              <tr class="total-row">
                <td><strong>Total</strong></td>
                <td class="num"><strong>{{ formatNumber(summary.grandTotal) }}</strong></td>
                <td class="num"><strong>100%</strong></td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- Table 4 -->
      <section class="card">
        <header class="card-header">
          <div>
            <h3>Table 4. Top Commonly Solicited Job Vacancies</h3>
            <p class="card-sub">Ranked by total count · Local and Overseas combined</p>
          </div>
          <span class="table-badge">Top {{ summary.topPositions.length }}</span>
        </header>
        <div class="table-wrap">
          <table class="lma-table">
            <thead>
              <tr>
                <th class="rank-col">#</th>
                <th>Position</th>
                <th class="num">Local</th>
                <th class="num">Overseas</th>
                <th class="num">Total</th>
                <th class="num">%</th>
                <th>Industry</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(pos, i) in summary.topPositions"
                :key="pos.name"
                :class="{ 'top5-row': i < 5 }"
              >
                <td class="rank-col">
                  <span class="rank-badge" :class="i < 5 ? 'rank-top' : 'rank-other'">{{ i + 1 }}</span>
                </td>
                <td class="pos-name">{{ pos.name }}</td>
                <td class="num">{{ formatNumber(pos.local) }}</td>
                <td class="num">{{ formatNumber(pos.overseas) }}</td>
                <td class="num"><strong>{{ formatNumber(pos.total) }}</strong></td>
                <td class="num">
                  <div class="pct-cell">
                    <span>{{ pos.pct }}%</span>
                    <div class="pct-bar-track">
                      <div class="pct-bar-fill" :style="{ width: pos.pct + '%' }"></div>
                    </div>
                  </div>
                </td>
                <td class="industry-cell">{{ pos.industry }}</td>
              </tr>
              <!-- Others row -->
              <tr v-if="summary.others" class="others-row">
                <td class="rank-col"><span class="rank-badge rank-other">—</span></td>
                <td class="pos-name" colspan="1">
                  <span class="others-label">Others</span>
                  <span class="others-detail">{{ summary.others.names }}</span>
                </td>
                <td class="num">{{ formatNumber(summary.others.local) }}</td>
                <td class="num">{{ formatNumber(summary.others.overseas) }}</td>
                <td class="num"><strong>{{ formatNumber(summary.others.total) }}</strong></td>
                <td class="num">{{ summary.others.pct }}%</td>
                <td class="industry-cell">—</td>
              </tr>
              <!-- Grand Total -->
              <tr class="total-row">
                <td></td>
                <td><strong>Grand Total</strong></td>
                <td class="num"><strong>{{ formatNumber(summary.localTotal) }}</strong></td>
                <td class="num"><strong>{{ formatNumber(summary.overseasTotal) }}</strong></td>
                <td class="num"><strong>{{ formatNumber(summary.grandTotal) }}</strong></td>
                <td class="num"><strong>100%</strong></td>
                <td></td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- LMI section -->
      <section class="card">
        <header class="card-header">
          <div>
            <h3>Table 5. Institutions Reached (LMI)</h3>
            <p class="card-sub">Labor Market Information · {{ summary.period }}</p>
          </div>
          <span class="table-badge">{{ summary.lmiInstitutions }} Institutions</span>
        </header>
        <div class="table-wrap">
          <table class="lma-table">
            <thead>
              <tr>
                <th class="num">No. of Institutions</th>
                <th>Partner Agencies</th>
                <th>Type of LMI</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(lmi, i) in summary.lmiBreakdown" :key="i">
                <td class="num">{{ lmi.count }}</td>
                <td>{{ lmi.type }}</td>
                <td><span class="lmi-tag">{{ lmi.lmiType }}</span></td>
              </tr>
              <tr class="total-row">
                <td class="num"><strong>{{ summary.lmiInstitutions }}</strong></td>
                <td><strong>Total</strong></td>
                <td></td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- Download CTA -->
      <div class="download-cta">
        <div class="cta-left">
          <div class="cta-icon">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
          </div>
          <div>
            <p class="cta-title">Ready to download</p>
            <p class="cta-sub">Formatted in the stephen LMA template · Excel format</p>
          </div>
        </div>
        <button class="btn btn-primary" :disabled="downloading" @click="downloadReport">
          <svg v-if="!downloading" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
          <span v-else class="btn-spinner"></span>
          {{ downloading ? 'Generating...' : 'Download Excel Report' }}
        </button>
      </div>

    </template>

  </div>
</template>

<script>
import * as XLSX from 'xlsx'
import api from '@/services/api'

const INDUSTRY_MAP = {
  'DOMESTIC HELPER':              'Other community, social and personal service activities',
  'DOMESTIC CLEANER':             'Other community, social and personal service activities',
  'HOUSEMAID':                    'Other community, social and personal service activities',
  'CAREGIVER (HOME-BASED)':       'Health and Social Work',
  'CARETAKER (HOME-BASE)':        'Health and Social Work',
  'STAFF NURSE':                  'Health and Social Work',
  'PHYSICAL THERAPIST':           'Health and Social Work',
  'DERMATOLOGIST':                'Health and Social Work',
  'RADIOLOGIC TECHNOLOGIST':      'Health and Social Work',
  'SERVICE CREW':                 'Hotel and Restaurant',
  'KITCHEN CREW':                 'Hotel and Restaurant',
  'KITCHEN HELPER':               'Hotel and Restaurant',
  'COOK (GENERAL)':               'Hotel and Restaurant',
  'WAITER (GENERAL)':             'Hotel and Restaurant',
  'CASHIER':                      'Wholesale and Retail Trade',
  'MERCHANDISER':                 'Wholesale and Retail Trade',
  'SALES ASSOCIATE PROFESSIONAL': 'Wholesale and Retail Trade',
  'SALES CLERK':                  'Wholesale and Retail Trade',
  'SALESMAN':                     'Wholesale and Retail Trade',
  'SALESLADY':                    'Wholesale and Retail Trade',
  'DELIVERY DRIVER':              'Wholesale and Retail Trade',
  'DELIVERY HELPER':              'Wholesale and Retail Trade',
  'WAREHOUSEMAN':                 'Wholesale and Retail Trade',
  'WAREHOUSE HELPER':             'Wholesale and Retail Trade',
  'PROMO SALESPERSON':            'Wholesale and Retail Trade',
  'CUSTOMER SERVICE ASSISTANT':   'Other community, social and personal service activities',
  'SECURITY GUARD':               'Other community, social and personal service activities',
  'LADY GUARD':                   'Other community, social and personal service activities',
  'SKILLED WORKER (FIELD CROPS)': 'Agriculture',
  'MANICURIST/PEDICURIST':        'Other community, social and personal service activities',
  'HAIRDRESSER':                  'Other community, social and personal service activities',
  'PRODUCTION WORKER':            'Manufacturing',
  'ACCOUNTING STAFF':             'Financial Intermediation',
  'ACCOUNTING CLERK':             'Financial Intermediation',
  'ACCOUNTING ASSISTANT':         'Financial Intermediation',
  'ACCOUNTANT (GENERAL)':         'Financial Intermediation',
}

const TOAST_TTL = 6000

export default {
  name: 'LmaConverter',

  data() {
    return {
      selectedFile: null,
      dragging: false,
      processing: false,
      downloading: false,
      summary: null,
      toasts: [],
      toastSeq: 0,
    }
  },

  methods: {

    /* ─── File handling ─── */

    onDrop(e) {
      this.dragging = false
      const file = e.dataTransfer.files[0]
      if (file) this.setFile(file)
    },

    onFileChange(e) {
      const file = e.target.files[0]
      if (file) this.setFile(file)
    },

    setFile(file) {
      if (!file.name.match(/\.(xlsx|xls)$/i)) {
        this.notify('error', 'Please upload an Excel file (.xlsx or .xls)')
        return
      }
      this.selectedFile = file
      this.summary = null
    },

    resetFile() {
      this.selectedFile = null
      this.summary = null
      this.$refs.fileInput.value = ''
    },

    /* ─── Process ─── */

    async processFile() {
      if (!this.selectedFile || this.processing) return
      this.processing = true
      try {
        const data = await this.readExcel(this.selectedFile)
        this.summary = this.buildSummary(data)
        this.notify('success', 'File processed successfully!')
      } catch (e) {
        console.error(e)
        this.notify('error', 'Could not read file. Make sure it\'s the correct JV format.')
      } finally {
        this.processing = false
      }
    },

    readExcel(file) {
      return new Promise((resolve, reject) => {
        const reader = new FileReader()
        reader.onload = (e) => {
          try {
            const wb = XLSX.read(e.target.result, { type: 'array' })
            // Get JV sheet
            const jvSheet = wb.Sheets['JV'] || wb.Sheets[wb.SheetNames[0]]
            const jvRows = XLSX.utils.sheet_to_json(jvSheet, { header: 1, defval: null })

            // Get Form 2 sheet for LMI data
            const form2Sheet = wb.Sheets['Form 2'] || wb.Sheets['Sheet2'] || null
            const form2Rows = form2Sheet
              ? XLSX.utils.sheet_to_json(form2Sheet, { header: 1, defval: null })
              : []

            resolve({ jvRows, form2Rows, sheetNames: wb.SheetNames })
          } catch (err) {
            reject(err)
          }
        }
        reader.onerror = reject
        reader.readAsArrayBuffer(file)
      })
    },

    buildSummary({ jvRows, form2Rows }) {
      // ── Detect LOCAL section ──
      // Find header row with "NO.", "COMPANY NAME", "POSITION", "VACANCY COUNT"
      let localHeaderRow = -1
      let overseasHeaderRow = -1

      for (let i = 0; i < jvRows.length; i++) {
        const row = jvRows[i].map(c => String(c ?? '').trim().toUpperCase())
        const joined = row.join('|')
        if (localHeaderRow === -1 && joined.includes('COMPANY NAME') && joined.includes('VACANCY COUNT')) {
          localHeaderRow = i
        } else if (localHeaderRow !== -1 && joined.includes('COMPANY NAME') && joined.includes('VACANCY COUNT')) {
          overseasHeaderRow = i
          break
        }
      }

      if (localHeaderRow === -1) throw new Error('Could not find data headers in JV sheet')

      // Detect column indices from header row
      const headerRow = jvRows[localHeaderRow].map(c => String(c ?? '').trim().toUpperCase())
      const posCol   = headerRow.findIndex(h => h.includes('POSITION'))
      const countCol = headerRow.findIndex(h => h.includes('VACANCY') && h.includes('COUNT'))

      if (posCol === -1 || countCol === -1) throw new Error('Could not find POSITION or VACANCY COUNT columns')

      // ── Parse LOCAL rows ──
      const localEnd = overseasHeaderRow !== -1 ? overseasHeaderRow : jvRows.length
      const localRows = jvRows.slice(localHeaderRow + 1, localEnd)
      const localMap  = this.aggregatePositions(localRows, posCol, countCol)

      // ── Parse OVERSEAS rows ──
      const overseasMap = {}
      if (overseasHeaderRow !== -1) {
        const overseasRows = jvRows.slice(overseasHeaderRow + 1)
        Object.assign(overseasMap, this.aggregatePositions(overseasRows, posCol, countCol))
      }

      // ── Totals ──
      const localTotal    = Object.values(localMap).reduce((s, v) => s + v, 0)
      const overseasTotal = Object.values(overseasMap).reduce((s, v) => s + v, 0)
      const grandTotal    = localTotal + overseasTotal

      // ── Combined top positions ──
      const allPositions = new Set([...Object.keys(localMap), ...Object.keys(overseasMap)])
      const combined = []
      allPositions.forEach(pos => {
        const local    = localMap[pos]    || 0
        const overseas = overseasMap[pos] || 0
        const total    = local + overseas
        combined.push({ name: pos, local, overseas, total })
      })
      combined.sort((a, b) => b.total - a.total)

      // Top 10 + others
      const top10 = combined.slice(0, 10)
      const rest  = combined.slice(10)

      const topPositions = top10.map(p => ({
        ...p,
        pct:      grandTotal ? +((p.total / grandTotal) * 100).toFixed(1) : 0,
        industry: INDUSTRY_MAP[p.name] || 'Wholesale and Retail Trade',
      }))

      const othersLocal    = rest.reduce((s, p) => s + p.local, 0)
      const othersOverseas = rest.reduce((s, p) => s + p.overseas, 0)
      const othersTotal    = othersLocal + othersOverseas
      const others = othersTotal > 0 ? {
        local:    othersLocal,
        overseas: othersOverseas,
        total:    othersTotal,
        pct:      grandTotal ? +((othersTotal / grandTotal) * 100).toFixed(1) : 0,
        names:    rest.slice(0, 6).map(p => p.name).join(', ') + (rest.length > 6 ? ', etc.' : ''),
      } : null

      // ── LMI from Form 2 ──
      const lmiData  = this.parseLmi(form2Rows)

      // ── Period from filename or sheet ──
      const period = this.detectPeriod(this.selectedFile.name, jvRows)

      return {
        period,
        localTotal,
        overseasTotal,
        grandTotal,
        localPct:    grandTotal ? +((localTotal / grandTotal) * 100).toFixed(1) : 0,
        overseasPct: grandTotal ? +((overseasTotal / grandTotal) * 100).toFixed(1) : 0,
        topPositions,
        others,
        lmiInstitutions: lmiData.total,
        lmiBreakdown:    lmiData.breakdown,
      }
    },

    aggregatePositions(rows, posCol, countCol) {
      const map = {}
      for (const row of rows) {
        const pos   = String(row[posCol] ?? '').trim().replace(/^\t/, '')
        const count = parseFloat(row[countCol])
        if (!pos || isNaN(count) || count <= 0) continue
        // Skip total rows
        if (pos.toUpperCase().includes('TOTAL') || pos.toUpperCase().includes('GRAND')) continue
        map[pos.toUpperCase()] = (map[pos.toUpperCase()] || 0) + count
      }
      return map
    },

    parseLmi(rows) {
      if (!rows.length) return { total: 0, breakdown: [] }
      const typeCounts = {}
      let total = 0
      for (const row of rows) {
        const cells = row.map(c => String(c ?? '').trim())
        // Look for rows that have a number in first cell and institution name
        const num = parseInt(cells[0])
        const type = cells.slice(3).find(c => c.length > 2) || ''
        if (!isNaN(num) && num > 0 && type) {
          typeCounts[type] = (typeCounts[type] || 0) + 1
        }
      }
      // Find total row
      for (const row of rows) {
        const cells = row.map(c => String(c ?? '').trim().toUpperCase())
        if (cells.includes('TOTAL') || cells.includes('GRAND TOTAL')) {
          const num = row.map(c => parseInt(c)).find(n => !isNaN(n) && n > 0)
          if (num) { total = num; break }
        }
      }
      if (!total) total = Object.values(typeCounts).reduce((s, v) => s + v, 0)

      const breakdown = Object.entries(typeCounts).map(([lmiType, count]) => ({
        count,
        type: 'Public & Private Agencies',
        lmiType,
      }))
      if (!breakdown.length) breakdown.push({ count: total, type: 'Public & Private Agencies', lmiType: 'Job Posting' })

      return { total, breakdown }
    },

    detectPeriod(filename, rows) {
      // Try to extract from filename e.g. FEBRUARY_2026
      const months = ['JANUARY','FEBRUARY','MARCH','APRIL','MAY','JUNE',
                      'JULY','AUGUST','SEPTEMBER','OCTOBER','NOVEMBER','DECEMBER']
      const upper = filename.toUpperCase()
      for (const m of months) {
        if (upper.includes(m)) {
          const yearMatch = filename.match(/20\d{2}/)
          return yearMatch ? `${m.charAt(0) + m.slice(1).toLowerCase()} ${yearMatch[0]}` : m.charAt(0) + m.slice(1).toLowerCase()
        }
      }
      // Try to find from sheet rows
      for (const row of rows.slice(0, 15)) {
        const text = row.map(c => String(c ?? '')).join(' ').toUpperCase()
        for (const m of months) {
          if (text.includes(m)) {
            const yearMatch = text.match(/20\d{2}/)
            return yearMatch
              ? `${m.charAt(0) + m.slice(1).toLowerCase()} ${yearMatch[0]}`
              : m.charAt(0) + m.slice(1).toLowerCase()
          }
        }
      }
      return 'Current Period'
    },

    /* ─── Download via Laravel ─── */

    async downloadReport() {
      if (!this.summary || this.downloading) return
      this.downloading = true
      try {
        const response = await api.post(
          '/lma/generate-excel',
          { summary: this.summary },
          { responseType: 'blob' }
        )
        const blob = new Blob([response.data], {
          type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        })
        const url  = URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = `LMA_Report_${this.summary.period.replace(/\s+/g, '_')}.xlsx`
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        URL.revokeObjectURL(url)
        this.notify('success', 'Report downloaded!')
      } catch (e) {
        console.error(e)
        this.notify('error', 'Failed to generate Excel. Please check your connection.')
      } finally {
        this.downloading = false
      }
    },

    /* ─── Helpers ─── */

    formatNumber(n) {
      if (n == null || isNaN(n)) return '—'
      return Number(n).toLocaleString('en-US')
    },

    formatBytes(bytes) {
      if (bytes < 1024) return bytes + ' B'
      if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB'
      return (bytes / 1048576).toFixed(1) + ' MB'
    },

    /* ─── Toasts ─── */

    notify(type, message) {
      const id = ++this.toastSeq
      const timer = setTimeout(() => this.dismissToast(id), TOAST_TTL)
      this.toasts.push({ id, type, message, timer })
    },

    dismissToast(id) {
      const idx = this.toasts.findIndex(t => t.id === id)
      if (idx === -1) return
      clearTimeout(this.toasts[idx].timer)
      this.toasts.splice(idx, 1)
    },
  },

  beforeUnmount() {
    this.toasts.forEach(t => clearTimeout(t.timer))
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

.lma-page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  flex: 1;
  overflow-y: auto;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  background: #f1eeff;
  position: relative;
  min-height: 100%;
}

/* ── Toast ── */
.toast-stack { position: fixed; top: 18px; right: 18px; display: flex; flex-direction: column; gap: 8px; z-index: 1000; max-width: 360px; pointer-events: none; }
.toast { display: flex; align-items: center; gap: 10px; background: #fff; border: 1px solid #e2e8f0; border-left-width: 4px; border-radius: 10px; padding: 10px 14px; font-size: 12.5px; font-weight: 600; color: #334155; box-shadow: 0 8px 20px rgba(15,23,42,.08); pointer-events: auto; }
.toast-success { border-left-color: #16a34a; } .toast-success .toast-icon { color: #16a34a; }
.toast-error   { border-left-color: #ef4444; } .toast-error   .toast-icon { color: #ef4444; }
.toast-icon { display: flex; flex-shrink: 0; }
.toast-msg  { flex: 1; }
.toast-close { border: none; background: transparent; color: #94a3b8; font-size: 18px; cursor: pointer; padding: 0 2px; }
.toast-enter-active, .toast-leave-active { transition: all .25s ease; }
.toast-enter-from, .toast-leave-to { opacity: 0; transform: translateX(20px); }

/* ── Skeleton ── */
@keyframes shimmer { 0% { background-position:-600px 0 } 100% { background-position:600px 0 } }
.skel { background: linear-gradient(90deg,#f1f5f9 25%,#e2e8f0 50%,#f1f5f9 75%); background-size: 600px 100%; animation: shimmer 1.4s infinite linear; border-radius: 6px; display: block; }

/* ── Header ── */
.lma-header { display: flex; align-items: center; justify-content: space-between; background: #fff; border: 1px solid #f1f5f9; border-radius: 14px; padding: 14px 18px; gap: 16px; flex-wrap: wrap; }
.header-left { display: flex; align-items: center; gap: 12px; }
.header-icon { width: 38px; height: 38px; background: #faf5ff; border: 1px solid #e9d5ff; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.page-title { font-size: 16px; font-weight: 800; color: #1e293b; }
.page-sub   { font-size: 11.5px; color: #94a3b8; margin-top: 2px; }

/* ── Buttons ── */
.btn { display: inline-flex; align-items: center; gap: 6px; padding: 7px 14px; border-radius: 8px; font-size: 12px; font-weight: 700; cursor: pointer; transition: all .15s; border: 1.5px solid transparent; white-space: nowrap; font-family: inherit; }
.btn:disabled { opacity: .5; cursor: not-allowed; }
.btn-primary  { background: #2563eb; color: #fff; border-color: #2563eb; }
.btn-primary:hover:not(:disabled) { background: #1d4ed8; }
.btn-secondary { background: #faf5ff; color: #7c3aed; border-color: #e9d5ff; }
.btn-secondary:hover:not(:disabled) { background: #f3e8ff; }
.btn-sm { padding: 5px 12px; font-size: 11.5px; }
.btn-link { background: none; border: none; color: #7c3aed; font-size: 11.5px; font-weight: 600; cursor: pointer; padding: 4px 0; text-decoration: underline; font-family: inherit; }
.btn-link:hover { color: #5b21b6; }
.btn-link:disabled { opacity: .5; cursor: not-allowed; }
.btn-spinner { width: 12px; height: 12px; border: 1.8px solid currentColor; border-top-color: transparent; border-radius: 50%; animation: spin .8s linear infinite; display: inline-block; }
@keyframes spin { to { transform: rotate(360deg); } }

/* ── Upload ── */
.upload-zone { background: #fff; border: 2px dashed #e2e8f0; border-radius: 14px; cursor: pointer; transition: all .2s; }
.upload-zone:hover, .upload-zone.dragging { border-color: #7c3aed; background: #faf5ff; }
.upload-zone.has-file { border-color: #a78bfa; background: #faf5ff; }
.upload-inner { display: flex; flex-direction: column; align-items: center; gap: 8px; padding: 48px 24px; text-align: center; }
.upload-icon-wrap { width: 64px; height: 64px; background: #f8fafc; border-radius: 16px; display: flex; align-items: center; justify-content: center; color: #94a3b8; margin-bottom: 4px; transition: all .2s; }
.upload-icon-ready { background: #faf5ff; color: #7c3aed; }
.upload-title { font-size: 15px; font-weight: 700; color: #1e293b; }
.upload-sub   { font-size: 12.5px; color: #94a3b8; }
.upload-hint  { font-size: 11.5px; color: #94a3b8; background: #f8fafc; padding: 5px 12px; border-radius: 6px; border: 1px solid #f1f5f9; }

/* ── Reupload bar ── */
.reupload-bar { display: flex; align-items: center; justify-content: space-between; background: #faf5ff; border: 1px solid #e9d5ff; border-radius: 10px; padding: 8px 14px; flex-wrap: wrap; gap: 8px; }
.reupload-left { display: flex; align-items: center; gap: 8px; }
.reupload-filename { font-size: 12px; font-weight: 700; color: #5b21b6; }
.reupload-size { font-size: 11px; color: #a78bfa; }

/* ── KPI ── */
.kpi-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; }
.kpi-card { background: #fff; border-radius: 14px; padding: 18px; border: 1px solid #f1f5f9; animation: slideUp .38s ease both; }
.kpi-icon { width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; margin-bottom: 12px; }
.kpi-value { font-size: 26px; font-weight: 800; color: #1e293b; margin-bottom: 4px; font-variant-numeric: tabular-nums; }
.kpi-label { font-size: 12px; color: #64748b; font-weight: 600; margin-bottom: 4px; }
.kpi-sub   { font-size: 11px; font-weight: 600; color: #94a3b8; }
.trend-up     { color: #16a34a !important; }
.trend-purple { color: #7c3aed !important; }

/* ── Card ── */
.card { background: #fff; border-radius: 14px; padding: 18px; border: 1px solid #f1f5f9; }
.card-header { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 14px; gap: 10px; flex-wrap: wrap; }
.card-header h3 { font-size: 13.5px; font-weight: 700; color: #1e293b; }
.card-sub { font-size: 11px; color: #94a3b8; margin-top: 2px; }
.table-badge { font-size: 10.5px; font-weight: 700; padding: 3px 10px; border-radius: 99px; background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe; white-space: nowrap; flex-shrink: 0; }

/* ── Table ── */
.table-wrap { overflow-x: auto; }
.lma-table { width: 100%; border-collapse: collapse; font-size: 12.5px; }
.lma-table th { background: #f8fafc; font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: .3px; padding: 10px 12px; text-align: left; border-bottom: 1px solid #e2e8f0; white-space: nowrap; }
.lma-table td { padding: 10px 12px; border-bottom: 1px solid #f1f5f9; color: #334155; vertical-align: middle; }
.lma-table tr:last-child td { border-bottom: none; }
.lma-table .num { text-align: right; font-variant-numeric: tabular-nums; }
.lma-table .rank-col { width: 48px; text-align: center; }
.rank-badge { display: inline-flex; align-items: center; justify-content: center; width: 22px; height: 22px; border-radius: 6px; font-size: 11px; font-weight: 700; }
.rank-top   { background: #faf5ff; color: #7c3aed; }
.rank-other { background: #f1f5f9; color: #94a3b8; }
.top5-row { background: #fafafe; }
.total-row { background: #f8fafc; }
.total-row td { font-size: 12.5px; }

.pos-name { font-weight: 600; color: #1e293b; }
.pct-cell { display: flex; flex-direction: column; align-items: flex-end; gap: 3px; min-width: 60px; }
.pct-bar-track { width: 50px; height: 4px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.pct-bar-fill  { height: 100%; background: #7c3aed; border-radius: 99px; transition: width .6s ease; }
.industry-cell { font-size: 11px; color: #64748b; max-width: 180px; }

.others-row td { background: #f8fafc; }
.others-label  { font-weight: 600; color: #64748b; margin-right: 6px; }
.others-detail { font-size: 11px; color: #94a3b8; }

.lmi-tag { font-size: 11px; font-weight: 600; background: #f0fdf4; color: #15803d; border: 1px solid #bbf7d0; padding: 2px 8px; border-radius: 99px; }

/* ── Download CTA ── */
.download-cta { display: flex; align-items: center; justify-content: space-between; background: linear-gradient(135deg, #faf5ff, #eff6ff); border: 1.5px solid #e9d5ff; border-radius: 14px; padding: 18px 20px; gap: 16px; flex-wrap: wrap; }
.cta-left { display: flex; align-items: center; gap: 14px; }
.cta-icon { width: 44px; height: 44px; background: #fff; border-radius: 12px; border: 1px solid #e9d5ff; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.cta-title { font-size: 14px; font-weight: 800; color: #1e293b; }
.cta-sub   { font-size: 11.5px; color: #94a3b8; margin-top: 2px; }

/* ── Animations ── */
@keyframes slideUp { from { opacity:0; transform:translateY(10px); } to { opacity:1; transform:translateY(0); } }

/* ── Responsive ── */
@media (max-width: 768px) {
  .lma-page { padding: 14px; }
  .kpi-grid { grid-template-columns: 1fr 1fr; }
  .lma-header { flex-direction: column; align-items: stretch; }
}
@media (max-width: 480px) {
  .kpi-grid { grid-template-columns: 1fr; }
  .download-cta { flex-direction: column; align-items: stretch; }
}
</style>