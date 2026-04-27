<template>
  <div class="predictive-page">

    <!-- ── PAGE HEADER ─────────────────────────────────────────────── -->
    <div class="page-header">
      <div class="header-left">
        <div class="title-row">
          <div class="ai-icon">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/>
            </svg>
          </div>
          <h1 class="page-title">Predictive Analytics</h1>
          <span class="ai-tag">AI Powered</span>
        </div>
        <p class="page-sub">Employment trend forecasting and skill demand prediction based on live PESO data</p>
      </div>
      <div class="header-right">
        <div class="period-pills">
          <button
            v-for="p in periodOptions" :key="p.value"
            :class="['period-pill', { active: activePeriod === p.value }]"
            @click="setPeriod(p.value)"
          >{{ p.label }}</button>
        </div>
        <button class="btn-analyze" :disabled="analyzing" @click="runPrediction">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M23 4v6h-6"/><path d="M1 20v-6h6"/><path d="M3.51 9a9 9 0 0114.85-3.36L23 10"/><path d="M20.49 15a9 9 0 01-14.85 3.36L1 14"/></svg>
          {{ analyzing ? 'Predicting...' : 'Re-predict' }}
        </button>
        <button class="btn-export" :disabled="!hasData" @click="exportReport">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
          Export Report
        </button>
      </div>
    </div>

    <!-- ── SKELETON ────────────────────────────────────────────────── -->
    <template v-if="loading">
      <div class="kpi-grid">
        <div v-for="i in 4" :key="i" class="kpi-card">
          <div class="skel" style="width:36px;height:36px;border-radius:10px;margin-bottom:12px"></div>
          <div class="skel" style="width:72px;height:26px;border-radius:6px;margin-bottom:8px"></div>
          <div class="skel" style="width:110px;height:12px;border-radius:4px;margin-bottom:6px"></div>
          <div class="skel" style="width:70px;height:11px;border-radius:4px"></div>
        </div>
      </div>
      <div class="main-row">
        <div class="skel" style="height:340px;border-radius:14px;flex:1"></div>
        <div class="skel" style="height:340px;border-radius:14px;width:280px"></div>
      </div>
      <div class="skel" style="height:280px;border-radius:14px"></div>
      <div class="skel" style="height:260px;border-radius:14px"></div>
    </template>

    <!-- ── ACTUAL CONTENT ──────────────────────────────────────────── -->
    <template v-else>

      <!-- KPI Cards -->
      <div class="kpi-grid">
        <div v-for="(kpi, i) in kpis" :key="kpi.label" class="kpi-card" :style="{ animationDelay: (i*0.07)+'s' }">
          <div class="kpi-icon" :style="{ background: kpi.iconBg }">
            <span v-html="kpi.icon" :style="{ color: kpi.iconColor }"></span>
          </div>
          <h2 class="kpi-value">{{ kpi.value }}</h2>
          <p class="kpi-label">{{ kpi.label }}</p>
          <span class="kpi-trend" :class="kpi.up ? 'trend-up' : 'trend-down'">
            {{ kpi.up ? '↑' : '↓' }} {{ kpi.trend }} vs last period
          </span>
        </div>
      </div>

      <!-- Employment Trend Forecast + Confidence Gauge -->
      <div class="main-row">

        <!-- Employment Trend Forecast Chart -->
        <div class="card flex-1">
          <div class="card-header">
            <div>
              <h3>Employment Trend Forecast</h3>
              <p class="card-sub">Historical data + AI-predicted employment trend for the next 6 months</p>
            </div>
            <div class="legend">
              <span class="leg-item"><span class="leg-line" style="background:#2563eb"></span>Actual</span>
              <span class="leg-item"><span class="leg-line leg-dashed" style="border-color:#8b5cf6"></span>Predicted</span>
              <span class="leg-item"><span class="leg-swatch" style="background:#8b5cf615"></span>Confidence band</span>
            </div>
          </div>

          <div class="svg-wrap" ref="trendWrap" @mousemove="onTrendMove" @mouseleave="trendTip=null">
            <transition name="tip">
              <div v-if="trendTip" class="chart-tip" :style="{ left: trendTip.x+'px', top: trendTip.y+'px' }">
                <div class="tip-label">{{ trendTip.label }}</div>
                <div class="tip-row" v-if="trendTip.actual !== null"><span class="tip-dot" style="background:#2563eb"></span>Actual<strong>{{ trendTip.actual }}</strong></div>
                <div class="tip-row" v-if="trendTip.predicted !== null"><span class="tip-dot" style="background:#8b5cf6"></span>Predicted<strong>{{ trendTip.predicted }}</strong></div>
                <div class="tip-row tip-muted" v-if="trendTip.isPredicted"><span></span>CI {{ trendTip.low }}–{{ trendTip.high }}</div>
              </div>
            </transition>

            <svg ref="trendSvg" viewBox="0 0 640 200" preserveAspectRatio="xMidYMid meet" class="chart-svg">
              <defs>
                <linearGradient id="gActual" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stop-color="#2563eb" stop-opacity="0.16"/>
                  <stop offset="100%" stop-color="#2563eb" stop-opacity="0"/>
                </linearGradient>
                <linearGradient id="gPred" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stop-color="#8b5cf6" stop-opacity="0.12"/>
                  <stop offset="100%" stop-color="#8b5cf6" stop-opacity="0"/>
                </linearGradient>
                <clipPath id="trendClip">
                  <rect x="52" y="0" height="175" :width="trendAnimated ? 578 : 0" :style="{ transition:'width 1.2s cubic-bezier(.4,0,.2,1)' }"/>
                </clipPath>
              </defs>

              <!-- Grid -->
              <line v-for="gl in trendGrid" :key="'tg'+gl.y" :x1="52" :y1="gl.y" :x2="630" :y2="gl.y" stroke="#f1f5f9" stroke-width="1"/>
              <text v-for="gl in trendGrid" :key="'tgl'+gl.y" :x="46" :y="gl.y+4" text-anchor="end" font-size="9" fill="#cbd5e1" font-family="Plus Jakarta Sans,sans-serif">{{ gl.label }}</text>

              <!-- Confidence band (predicted range) -->
              <g clip-path="url(#trendClip)">
                <path :d="confidenceBandPath" fill="#8b5cf615"/>
                <!-- Actual area + line -->
                <path :d="actualAreaPath"  fill="url(#gActual)"/>
                <path :d="actualLinePath"  fill="none" stroke="#2563eb" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
                <!-- Predicted dashed line -->
                <path :d="predictedLinePath" fill="none" stroke="#8b5cf6" stroke-width="2" stroke-dasharray="5 3" stroke-linecap="round"/>
                <!-- Divider line -->
                <line :x1="splitX" y1="10" :x2="splitX" y2="168" stroke="#e2e8f0" stroke-width="1.5" stroke-dasharray="4 3"/>
                <text :x="splitX+4" y="14" font-size="8.5" fill="#94a3b8" font-family="Plus Jakarta Sans,sans-serif">Forecast →</text>
              </g>

              <!-- X labels -->
              <text v-for="(pt,i) in allTrendPoints" :key="'txl'+i"
                    :x="pt.x" :y="188" text-anchor="middle" font-size="9"
                    :fill="pt.isPredicted ? '#8b5cf6' : '#94a3b8'"
                    font-family="Plus Jakarta Sans,sans-serif">{{ pt.label }}</text>

              <!-- Hover dots -->
              <circle v-for="(pt,i) in actualDots" :key="'ad'+i"
                      :cx="pt.x" :cy="pt.y" :r="trendTip && trendTip.i===i ? 5 : 3.5"
                      fill="#fff" stroke="#2563eb" stroke-width="2" pointer-events="none"
                      style="transition:r .12s"/>
              <circle v-for="(pt,i) in predictedDots" :key="'pd'+i"
                      :cx="pt.x" :cy="pt.y" :r="trendTip && trendTip.i===(actualTrendData.length+i) ? 5 : 3.5"
                      fill="#fff" stroke="#8b5cf6" stroke-width="2" pointer-events="none"
                      style="transition:r .12s"/>

              <!-- Hit areas -->
              <rect v-for="(pt,i) in allTrendPoints" :key="'th'+i"
                    :x="pt.x - trendColW/2" y="0" :width="trendColW" height="175"
                    fill="transparent" style="cursor:crosshair"/>
            </svg>
          </div>
        </div>

        <!-- Model Confidence Panel -->
        <div class="card" style="width:272px;flex-shrink:0">
          <div class="card-header">
            <div><h3>Model Confidence</h3><p class="card-sub">Prediction reliability scores</p></div>
            <span class="live-badge">AI</span>
          </div>
          <div class="confidence-list">
            <div v-for="mc in modelConfidence" :key="mc.label" class="conf-item">
              <div class="conf-row">
                <span class="conf-label">{{ mc.label }}</span>
                <span class="conf-pct" :style="{ color: mc.color }">{{ mc.pct }}%</span>
              </div>
              <div class="conf-track">
                <div class="conf-fill" :style="{ width: confAnimated ? mc.pct+'%' : '0%', background: mc.color }"></div>
              </div>
              <span class="conf-note">{{ mc.note }}</span>
            </div>
          </div>
          <div class="conf-footer">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            <span>Based on {{ modelDataPoints.toLocaleString() }} historical data points</span>
          </div>
        </div>
      </div>

      <!-- Skill Demand Prediction Heatmap -->
      <div class="card" data-animate="heatmap">
        <div class="card-header">
          <div>
            <h3>Skill Demand Forecast Heatmap</h3>
            <p class="card-sub">Predicted demand intensity per skill per month — next 6 months</p>
          </div>
          <div style="display:flex;gap:8px;align-items:center">
            <span class="heatmap-legend-label">Low</span>
            <div class="heatmap-legend-strip"></div>
            <span class="heatmap-legend-label">High</span>
          </div>
        </div>

        <div class="heatmap-wrap" v-if="heatmapAnimated || true">
          <div class="heatmap-table">
            <!-- Header row -->
            <div class="hm-header-row">
              <div class="hm-skill-col"></div>
              <div v-for="m in forecastMonths" :key="m" class="hm-month-col">{{ m }}</div>
            </div>
            <!-- Data rows -->
            <div v-for="(row, ri) in heatmapData" :key="row.skill" class="hm-row">
              <div class="hm-skill-name">
                <span class="hm-skill-dot" :style="{ background: row.color }"></span>
                {{ row.skill }}
              </div>
              <div v-for="(val, ci) in row.values" :key="ci" class="hm-cell"
                   :style="{ background: heatColor(val), transitionDelay: (ri*0.05+ci*0.02)+'s' }"
                   :title="`${row.skill} · ${forecastMonths[ci]}: ${val}%`">
                <span class="hm-val" :style="{ color: val >= 70 ? '#fff' : '#475569' }">{{ val }}%</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Skill Demand Predictions Grid -->
      <div>
        <div class="section-head">
          <h2 class="section-title">Skill Demand Predictions</h2>
          <span class="section-badge">Next 90 days · AI Forecast</span>
        </div>
        <p class="section-sub">AI-predicted skill demand based on current job postings, applicant profiles, employer growth, and seasonal hiring patterns</p>
        <div class="pred-grid">
          <div v-for="(pred, i) in skillPredictions" :key="pred.skill" class="pred-card" :style="{ animationDelay: (i*0.06)+'s' }">
            <div class="pred-top">
              <div class="pred-icon" :style="{ background: pred.iconBg }">
                <span v-html="pred.icon" :style="{ color: pred.iconColor }"></span>
              </div>
              <span class="pred-conf-badge" :class="pred.confClass">{{ pred.confidence }}</span>
            </div>
            <p class="pred-skill">{{ pred.skill }}</p>
            <p class="pred-industry">{{ pred.industry }}</p>
            <div class="pred-change-row">
              <span class="pred-change" :class="pred.change >= 0 ? 'change-pos' : 'change-neg'">
                {{ pred.change >= 0 ? '↑' : '↓' }} {{ Math.abs(pred.change) }}% projected
              </span>
            </div>
            <div class="pred-bar-track">
              <div class="pred-bar-fill" :style="{ width: predsAnimated ? pred.pct+'%' : '0%', background: pred.iconColor }"></div>
            </div>
            <p class="pred-note">{{ pred.note }}</p>
          </div>
        </div>
      </div>

      <!-- AI Insight Summary Panel -->
      <div class="card ai-insight-card">
        <div class="card-header">
          <div class="ai-header-left">
            <div class="ai-pulse" :class="{ pulsing: analyzing }"></div>
            <h3 style="margin:0">AI Insight Summary</h3>
            <span class="claude-badge">Claude AI</span>
          </div>
          <span class="ai-period-tag">{{ periodLabel }}</span>
        </div>

        <!-- Analyzing -->
        <div v-if="analyzing" class="ai-loading">
          <div class="ai-spinner"><div class="spin-ring"></div>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="2"><path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/></svg>
          </div>
          <p class="ai-loading-title">Analyzing employment trends...</p>
          <p class="ai-loading-sub">Processing jobseeker profiles, employer data, skill gaps, and seasonal patterns</p>
        </div>

        <!-- Empty -->
        <div v-else-if="!insightText" class="ai-empty">
          <div class="ai-empty-icon">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#c4b5fd" stroke-width="1.5"><path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/></svg>
          </div>
          <p class="ai-empty-title">No AI insight generated yet</p>
          <p class="ai-empty-sub">Click "Re-predict" to generate employment trend forecasts and skill demand predictions from your live data.</p>
          <button class="btn-run" @click="runPrediction">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="5 3 19 12 5 21 5 3"/></svg>
            Run Prediction
          </button>
        </div>

        <!-- Result -->
        <div v-else class="ai-result">
          <div class="insight-meta-row">
            <span class="meta-item"><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="12" cy="8" r="5"/><path d="M3 21a9 9 0 0118 0"/></svg>{{ insightMeta.jobseekers.toLocaleString() }} jobseekers</span>
            <span class="meta-item"><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 7V5a2 2 0 00-4 0v2"/></svg>{{ insightMeta.openings.toLocaleString() }} openings</span>
            <span class="meta-item"><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>{{ insightMeta.placementRate }} placement rate</span>
          </div>
          <div class="insight-chips">
            <span v-for="chip in insightChips" :key="chip.text" class="chip" :class="chip.cls">{{ chip.text }}</span>
          </div>
          <div class="insight-divider"></div>
          <div class="insight-text" v-html="formattedInsight"></div>
          <div class="insight-divider"></div>
          <div class="ai-footer">
            <span class="ai-gen-at">Generated {{ insightGeneratedAt }}</span>
            <div style="display:flex;gap:6px">
              <button class="btn-sm-outline" @click="runPrediction">Refresh</button>
              <button class="btn-sm-primary" @click="exportReport">
                <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                Export PDF
              </button>
            </div>
          </div>
        </div>
      </div>

    </template>
  </div>
</template>

<script>
import api from '@/services/api'

export default {
  name: 'PredictiveAnalytics',

  data() {
    return {
      loading: true,
      analyzing: false,
      activePeriod: 'monthly',
      trendAnimated: false,
      confAnimated: false,
      heatmapAnimated: false,
      predsAnimated: false,
      trendTip: null,
      insightText: '',
      insightGeneratedAt: '',
      insightChips: [],
      insightMeta: { jobseekers: 0, openings: 0, placementRate: '0%' },
      modelDataPoints: 0,

      periodOptions: [
        { label: 'Weekly',  value: 'weekly'  },
        { label: 'Monthly', value: 'monthly' },
        { label: 'Yearly',  value: 'yearly'  },
      ],

      kpis: [
        {
          label: 'Predicted Placements (next 30d)', value: '—', trend: '—', up: true,
          iconBg: '#eff6ff', iconColor: '#2563eb',
          icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>`,
        },
        {
          label: 'Forecast Employment Rate', value: '—', trend: '—', up: true,
          iconBg: '#f0fdf4', iconColor: '#16a34a',
          icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>`,
        },
        {
          label: 'Top Emerging Skill', value: '—', trend: '—', up: true,
          iconBg: '#faf5ff', iconColor: '#8b5cf6',
          icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 20V10"/><path d="M12 20V4"/><path d="M6 20v-6"/></svg>`,
        },
        {
          label: 'Skill-Gap Risk Score', value: '—', trend: '—', up: false,
          iconBg: '#fff7ed', iconColor: '#f97316',
          icon: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>`,
        },
      ],

      // Trend chart data — actual (historical) + predicted
      actualTrendData: [],
      predictedTrendData: [],
      forecastMonths: [],
      heatmapData: [],
      skillPredictions: [],
      modelConfidence: [],
    }
  },

  async mounted() {
    await this.$nextTick()
    await this.fetchData()
  },

  computed: {
    hasData() { return this.actualTrendData.length > 0 },

    periodLabel() {
      const map = {
        weekly:  'This week',
        monthly: new Date().toLocaleString('default', { month: 'long', year: 'numeric' }),
        yearly:  'This year',
      }
      return map[this.activePeriod] || ''
    },

    // Chart geometry
    chartW() { return 578 },
    chartH() { return 160 },
    allTrendPoints() {
      const pts = []
      const all = [...this.actualTrendData, ...this.predictedTrendData]
      const n = all.length
      if (!n) return []
      const max = Math.max(...all.map(d => Math.max(d.value, d.high ?? d.value)), 1)
      const nice = this._niceMax(max)
      all.forEach((d, i) => {
        const x = 52 + i * (this.chartW / Math.max(n - 1, 1))
        const y = 168 - ((d.value / nice) * this.chartH)
        pts.push({ x, y, label: d.label, isPredicted: i >= this.actualTrendData.length, i,
          value: d.value, low: d.low ?? null, high: d.high ?? null })
      })
      return pts
    },
    actualDots() {
      return this.allTrendPoints.filter(p => !p.isPredicted)
    },
    predictedDots() {
      return this.allTrendPoints.filter(p => p.isPredicted)
    },
    trendColW() {
      const n = this.allTrendPoints.length
      return n > 1 ? this.chartW / (n - 1) : this.chartW
    },
    splitX() {
      const idx = this.actualTrendData.length - 1
      if (idx < 0 || !this.allTrendPoints.length) return 52
      return this.allTrendPoints[idx]?.x ?? 52
    },
    trendGrid() {
      const all = [...this.actualTrendData, ...this.predictedTrendData]
      const max = Math.max(...all.map(d => Math.max(d.value, d.high ?? d.value)), 1)
      const nice = this._niceMax(max)
      const steps = 4
      return Array.from({ length: steps + 1 }, (_, i) => ({
        y: 10 + (i / steps) * this.chartH,
        label: Math.round((nice / steps) * (steps - i)),
      }))
    },
    actualLinePath() {
      const pts = this.actualDots
      return this._smooth(pts)
    },
    actualAreaPath() {
      const pts = this.actualDots
      if (!pts.length) return ''
      return this._smooth(pts) + ` L${pts[pts.length-1].x},168 L${pts[0].x},168 Z`
    },
    predictedLinePath() {
      const last = this.actualDots[this.actualDots.length - 1]
      const pred = this.predictedDots
      if (!pred.length) return ''
      const all = last ? [last, ...pred] : pred
      return this._smooth(all)
    },
    confidenceBandPath() {
      const all = [...this.actualTrendData, ...this.predictedTrendData]
      const maxV = Math.max(...all.map(d => Math.max(d.value, d.high ?? d.value)), 1)
      const nice = this._niceMax(maxV)
      const pred = this.predictedDots
      if (!pred.length) return ''
      const n = all.length
      const toY = v => 168 - ((v / nice) * this.chartH)
      const toX = i => 52 + i * (this.chartW / Math.max(n - 1, 1))
      const preds = this.predictedTrendData
      const startIdx = this.actualTrendData.length
      const top = preds.map((d, i) => ({ x: toX(startIdx + i), y: toY(d.high ?? d.value) }))
      const bot = [...preds].reverse().map((d, i) => {
        const ri = preds.length - 1 - i
        return { x: toX(startIdx + ri), y: toY(d.low ?? d.value) }
      })
      // include last actual point to connect band
      const lastActual = this.actualDots[this.actualDots.length - 1]
      const startPt = lastActual ? [{ x: lastActual.x, y: toY(this.actualTrendData[this.actualTrendData.length - 1]?.value ?? 0) }] : []
      const allTop = [...startPt, ...top]
      if (!allTop.length) return ''
      let path = `M${allTop[0].x},${allTop[0].y}`
      allTop.slice(1).forEach(p => { path += ` L${p.x},${p.y}` })
      bot.forEach(p => { path += ` L${p.x},${p.y}` })
      if (startPt.length) path += ` L${startPt[0].x},${startPt[0].y}`
      path += ' Z'
      return path
    },

    formattedInsight() {
      if (!this.insightText) return ''
      return this.insightText
        .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
        .replace(/\n\n/g, '</p><p>')
        .replace(/^/, '<p>')
        .replace(/$/, '</p>')
    },
  },

  methods: {
    setPeriod(p) {
      this.activePeriod = p
      this.fetchData()
    },

    async fetchData() {
      this.loading = true
      this._resetAnims()
      try {
        const { data } = await api.get('/admin/predictive-analytics/data', {
          params: { period: this.activePeriod },
        })
        this._applyData(data.data)
      } catch (e) {
        console.warn('Predictive data fetch failed, using mock data:', e)
        this._applyMockData()
      } finally {
        this.loading = false
        await this.$nextTick()
        this._setupObservers()
      }
    },

    async runPrediction() {
      if (this.analyzing) return
      this.analyzing = true
      this.insightText = ''
      this.insightChips = []
      try {
        // Try backend first
        const { data } = await api.post('/admin/predictive-analytics/generate', {
          period:         this.activePeriod,
          actualTrend:    this.actualTrendData,
          predictedTrend: this.predictedTrendData,
          heatmap:        this.heatmapData,
          predictions:    this.skillPredictions,
          kpis:           this.kpis.map(k => ({ label: k.label, value: k.value })),
        })
        this.insightText = data.insight || ''
        this.insightChips = data.chips || []
        this.insightGeneratedAt = this._now()
      } catch (e) {
        // Fallback: call Anthropic directly
        await this._callAnthropicDirect()
      } finally {
        this.analyzing = false
      }
    },

    async _callAnthropicDirect() {
      try {
        const topRising = this.skillPredictions.filter(p => p.change > 10).map(p => `${p.skill} (+${p.change}%)`).join(', ')
        const declining = this.skillPredictions.filter(p => p.change < 0).map(p => `${p.skill} (${p.change}%)`).join(', ')
        const prompt = `You are a labor market analyst for a Philippine PESO (Public Employment Service Office).

Analyze the following predictive analytics data and write a concise 3-paragraph forecast report.

PERIOD: ${this.periodLabel}

KPI FORECASTS:
${this.kpis.map(k => `- ${k.label}: ${k.value} (${k.up ? '+' : '-'}${k.trend})`).join('\n')}

EMPLOYMENT TREND: Historical data shows ${this.actualTrendData.length} months of data. Predicted trend for next ${this.predictedTrendData.length} months.

SKILL DEMAND PREDICTIONS (next 90 days):
- Rising skills: ${topRising || 'none noted'}
- Declining skills: ${declining || 'none noted'}
${this.skillPredictions.map(p => `- ${p.skill} (${p.industry}): ${p.change > 0 ? '+' : ''}${p.change}% change, confidence: ${p.confidence}`).join('\n')}

MODEL CONFIDENCE: ${this.modelConfidence.map(m => `${m.label}: ${m.pct}%`).join(', ')}

Write a professional predictive analysis covering:
1. Overall employment trend outlook and forecast confidence
2. Key emerging and declining skill demands
3. Recommended interventions for PESO in the next quarter

Use **bold** for key terms. Be specific and data-driven. Do not use bullet points. Write for a local government audience.`

        const response = await fetch('https://api.anthropic.com/v1/messages', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            model: 'claude-sonnet-4-20250514',
            max_tokens: 1000,
            messages: [{ role: 'user', content: prompt }],
          }),
        })
        const result = await response.json()
        this.insightText = result.content?.find(b => b.type === 'text')?.text || 'Unable to generate insight.'
        this.insightChips = this._autoChips()
        this.insightGeneratedAt = this._now()
      } catch (err) {
        console.error('Anthropic call failed:', err)
        this.insightText = 'Unable to generate prediction at this time. Please check your connection and try again.'
      }
    },

    _autoChips() {
      const chips = []
      const top = this.skillPredictions.find(p => p.change >= 15)
      if (top) chips.push({ text: `↑ ${top.skill} +${top.change}%`, cls: 'chip-green' })
      const dec = this.skillPredictions.find(p => p.change < 0)
      if (dec) chips.push({ text: `↓ ${dec.skill} ${dec.change}%`, cls: 'chip-red' })
      chips.push({ text: `${this.kpis[0].value} predicted placements`, cls: 'chip-blue' })
      chips.push({ text: `${this.kpis[3].value} risk score`, cls: 'chip-amber' })
      return chips
    },

    async exportReport() {
      if (!this.hasData) return
      try {
        const { data } = await api.post('/admin/predictive-analytics/export-pdf', {
          period:     this.activePeriod,
          kpis:       this.kpis,
          insightText: this.insightText,
          predictions: this.skillPredictions,
          heatmap:     this.heatmapData,
          generatedAt: this.insightGeneratedAt,
        }, { responseType: 'blob' })
        const url  = URL.createObjectURL(new Blob([data], { type: 'application/pdf' }))
        const link = document.createElement('a')
        link.href = url
        link.download = `predictive-analytics-${this.activePeriod}-${new Date().toISOString().split('T')[0]}.pdf`
        link.click()
        URL.revokeObjectURL(url)
      } catch (e) {
        console.error('Export failed:', e)
      }
    },

    _applyData(d) {
      if (!d) return this._applyMockData()
      if (d.kpis?.length) d.kpis.forEach((k, i) => { if (this.kpis[i]) Object.assign(this.kpis[i], k) })
      if (d.actualTrend)    this.actualTrendData    = d.actualTrend
      if (d.predictedTrend) this.predictedTrendData = d.predictedTrend
      if (d.forecastMonths) this.forecastMonths      = d.forecastMonths
      if (d.heatmap)        this.heatmapData         = d.heatmap
      if (d.predictions)    this.skillPredictions    = d.predictions
      if (d.modelConfidence) this.modelConfidence    = d.modelConfidence
      if (d.insightMeta)    this.insightMeta         = d.insightMeta
      this.modelDataPoints = d.modelDataPoints ?? 0
    },

    _applyMockData() {
      // KPIs
      this.kpis[0].value = '342'; this.kpis[0].trend = '8%';  this.kpis[0].up = true
      this.kpis[1].value = '64.3%'; this.kpis[1].trend = '2.1%'; this.kpis[1].up = true
      this.kpis[2].value = 'IT Support'; this.kpis[2].trend = '23%'; this.kpis[2].up = true
      this.kpis[3].value = 'Medium'; this.kpis[3].trend = '5%'; this.kpis[3].up = false

      this.insightMeta = { jobseekers: 4821, openings: 1349, placementRate: '38.4%' }
      this.modelDataPoints = 12840

      // Actual trend (12 months historical)
      this.actualTrendData = [
        { label: 'May 24', value: 210 }, { label: 'Jun', value: 245 },
        { label: 'Jul', value: 230 }, { label: 'Aug', value: 268 },
        { label: 'Sep', value: 255 }, { label: 'Oct', value: 290 },
        { label: 'Nov', value: 310 }, { label: 'Dec', value: 285 },
        { label: 'Jan 25', value: 320 }, { label: 'Feb', value: 298 },
        { label: 'Mar', value: 342 }, { label: 'Apr', value: 365 },
      ]

      // Predicted (6 months)
      this.predictedTrendData = [
        { label: 'May 25', value: 380, low: 355, high: 408 },
        { label: 'Jun',    value: 395, low: 362, high: 430 },
        { label: 'Jul',    value: 412, low: 372, high: 455 },
        { label: 'Aug',    value: 428, low: 380, high: 478 },
        { label: 'Sep',    value: 448, low: 390, high: 508 },
        { label: 'Oct',    value: 465, low: 400, high: 532 },
      ]

      this.forecastMonths = ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct']

      this.heatmapData = [
        { skill: 'IT / Tech Support', color: '#2563eb', values: [72, 78, 84, 88, 91, 93] },
        { skill: 'Healthcare Aide',   color: '#16a34a', values: [55, 60, 65, 68, 72, 75] },
        { skill: 'BPO / Call Center', color: '#8b5cf6', values: [80, 82, 79, 77, 75, 73] },
        { skill: 'Construction',      color: '#f59e0b', values: [60, 58, 62, 68, 72, 70] },
        { skill: 'Food Service',      color: '#f97316', values: [70, 68, 65, 64, 63, 61] },
        { skill: 'Accounting / Finance', color: '#06b6d4', values: [45, 48, 50, 52, 55, 58] },
        { skill: 'Logistics / Driving',  color: '#ef4444', values: [50, 46, 42, 40, 38, 35] },
      ]

      this.skillPredictions = [
        { skill: 'IT / Tech Support', industry: 'Technology', change: 23, pct: 88, confidence: 'High', confClass: 'conf-high', note: 'BPO expansion and digital transformation driving consistent growth.',
          iconBg: '#eff6ff', iconColor: '#2563eb', icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><polyline points="8 21 12 17 16 21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>` },
        { skill: 'Healthcare Aide', industry: 'Healthcare', change: 17, pct: 72, confidence: 'High', confClass: 'conf-high', note: 'Aging population and hospital expansion in NCR sustaining demand.',
          iconBg: '#f0fdf4', iconColor: '#16a34a', icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>` },
        { skill: 'Construction Trades', industry: 'Construction', change: 9, pct: 55, confidence: 'Medium', confClass: 'conf-med', note: 'Infrastructure projects increasing demand for skilled tradespeople.',
          iconBg: '#fffbeb', iconColor: '#f59e0b', icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/></svg>` },
        { skill: 'BPO / Call Center', industry: 'Business Process', change: 4, pct: 42, confidence: 'Medium', confClass: 'conf-med', note: 'Stable growth with new international accounts being onboarded.',
          iconBg: '#faf5ff', iconColor: '#8b5cf6', icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07"/></svg>` },
        { skill: 'Food Service', industry: 'Hospitality', change: -3, pct: 28, confidence: 'Medium', confClass: 'conf-med', note: 'Slight decline as automation enters fast food operations.',
          iconBg: '#fff7ed', iconColor: '#f97316', icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8h1a4 4 0 010 8h-1"/><path d="M2 8h16v9a4 4 0 01-4 4H6a4 4 0 01-4-4V8z"/></svg>` },
        { skill: 'Logistics / Driving', industry: 'Transport', change: -8, pct: 18, confidence: 'Low', confClass: 'conf-low', note: 'Route optimization and automation reducing driver headcount.',
          iconBg: '#fef2f2', iconColor: '#ef4444', icon: `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="1" y="3" width="15" height="13" rx="1"/><path d="M16 8h4l3 5v3h-7V8z"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/></svg>` },
      ]

      this.modelConfidence = [
        { label: 'Short-term (1 month)',  pct: 91, color: '#16a34a', note: 'Very reliable — based on current pipeline' },
        { label: 'Mid-term (3 months)',   pct: 78, color: '#2563eb', note: 'Good confidence — seasonal patterns applied' },
        { label: 'Long-term (6 months)',  pct: 62, color: '#f59e0b', note: 'Moderate — subject to policy changes' },
        { label: 'Skill gap prediction',  pct: 84, color: '#8b5cf6', note: 'High confidence — employer data correlated' },
      ]
    },

    // Chart helpers
    _niceMax(raw) {
      if (raw <= 0) return 1
      const mag = Math.pow(10, Math.floor(Math.log10(raw)))
      for (const s of [1, 2, 2.5, 5, 10]) {
        const c = Math.ceil(raw / (mag * s)) * (mag * s)
        if (c >= raw) return c
      }
      return Math.ceil(raw / mag) * mag
    },
    _smooth(pts) {
      if (!pts.length) return ''
      let d = `M${pts[0].x},${pts[0].y}`
      for (let i = 1; i < pts.length; i++) {
        const cpx = (pts[i-1].x + pts[i].x) / 2
        d += ` C${cpx},${pts[i-1].y} ${cpx},${pts[i].y} ${pts[i].x},${pts[i].y}`
      }
      return d
    },

    heatColor(val) {
      // 0–100 → white to deep blue
      const stops = [
        [0,   '#f8fafc'],
        [25,  '#dbeafe'],
        [50,  '#93c5fd'],
        [75,  '#3b82f6'],
        [100, '#1e3a8a'],
      ]
      val = Math.max(0, Math.min(100, val))
      for (let i = 0; i < stops.length - 1; i++) {
        if (val >= stops[i][0] && val <= stops[i+1][0]) {
          const t = (val - stops[i][0]) / (stops[i+1][0] - stops[i][0])
          return this._mixColors(stops[i][1], stops[i+1][1], t)
        }
      }
      return stops[stops.length - 1][1]
    },
    _mixColors(c1, c2, t) {
      const h = s => parseInt(s.slice(1), 16)
      const r1=h(c1)>>16, g1=(h(c1)>>8)&255, b1=h(c1)&255
      const r2=h(c2)>>16, g2=(h(c2)>>8)&255, b2=h(c2)&255
      const r=Math.round(r1+(r2-r1)*t)
      const g=Math.round(g1+(g2-g1)*t)
      const b=Math.round(b1+(b2-b1)*t)
      return `rgb(${r},${g},${b})`
    },

    onTrendMove(evt) {
      if (!this.allTrendPoints.length) return
      const svg = this.$refs.trendSvg
      if (!svg) return
      const pt = svg.createSVGPoint()
      pt.x = evt.clientX; pt.y = evt.clientY
      const svgPt = pt.matrixTransform(svg.getScreenCTM().inverse())
      const colW = this.trendColW
      let best = null, bestDist = Infinity
      this.allTrendPoints.forEach((p, i) => {
        const d = Math.abs(svgPt.x - p.x)
        if (d < bestDist) { bestDist = d; best = i }
      })
      if (best === null || bestDist > colW / 2 + 4) { this.trendTip = null; return }
      const p = this.allTrendPoints[best]
      const wrap = this.$refs.trendWrap
      const rect = wrap.getBoundingClientRect()
      let x = evt.clientX - rect.left + 14
      let y = evt.clientY - rect.top - 12
      if (x + 180 > rect.width) x = evt.clientX - rect.left - 194
      if (y < 0) y = 4
      const isActual = best < this.actualTrendData.length
      this.trendTip = {
        i: best,
        label: p.label,
        isPredicted: p.isPredicted,
        actual: isActual ? p.value : null,
        predicted: p.isPredicted ? p.value : null,
        low: p.low, high: p.high, x, y,
      }
    },

    _resetAnims() {
      this.trendAnimated = false
      this.confAnimated  = false
      this.heatmapAnimated = false
      this.predsAnimated  = false
      this.trendTip = null
    },

    _setupObservers() {
      const observe = (selector, flag, delay = 80) => {
        const el = typeof selector === 'string'
          ? this.$el.querySelector(selector)
          : selector
        if (!el) { setTimeout(() => { this[flag] = true }, delay); return }
        const obs = new IntersectionObserver(([entry]) => {
          if (entry.isIntersecting) {
            setTimeout(() => { this[flag] = true }, delay)
            obs.disconnect()
          }
        }, { threshold: 0.15 })
        obs.observe(el)
      }
      observe('.svg-wrap',      'trendAnimated', 100)
      observe('.confidence-list', 'confAnimated',   120)
      observe('.heatmap-wrap',  'heatmapAnimated', 150)
      observe('.pred-grid',     'predsAnimated',   100)
    },

    _now() {
      return new Date().toLocaleString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

.predictive-page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  flex: 1; overflow-y: auto;
  padding: 20px 24px;
  display: flex; flex-direction: column; gap: 16px;
  background: #f1eeff;
}

/* ── SKELETON ─────────────────────────────────────────────────────── */
@keyframes shimmer { 0%{background-position:-600px 0} 100%{background-position:600px 0} }
.skel {
  background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%);
  background-size: 600px 100%;
  animation: shimmer 1.4s infinite linear;
  border-radius: 6px; display: block;
}

/* ── PAGE HEADER ──────────────────────────────────────────────────── */
.page-header {
  display: flex; align-items: flex-start; justify-content: space-between;
  background: #fff; border: 1px solid #f1f5f9; border-radius: 14px;
  padding: 14px 18px; gap: 16px; flex-wrap: wrap;
}
.header-left { display: flex; flex-direction: column; gap: 4px; }
.title-row { display: flex; align-items: center; gap: 8px; }
.ai-icon {
  width: 30px; height: 30px; background: #faf5ff; border-radius: 8px;
  display: flex; align-items: center; justify-content: center;
  border: 1px solid #e9d5ff; flex-shrink: 0;
}
.page-title { font-size: 16px; font-weight: 800; color: #1e293b; }
.ai-tag {
  font-size: 10px; font-weight: 700; padding: 2px 8px; border-radius: 99px;
  background: #faf5ff; color: #7c3aed; border: 1px solid #e9d5ff;
}
.page-sub { font-size: 11.5px; color: #94a3b8; }

.header-right { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.period-pills { display: flex; gap: 4px; }
.period-pill {
  padding: 5px 12px; border-radius: 8px; border: 1.5px solid #e2e8f0;
  background: #f8fafc; font-size: 12px; font-weight: 600; color: #64748b;
  cursor: pointer; font-family: inherit; transition: all .15s;
}
.period-pill:hover { border-color: #94a3b8; color: #1e293b; }
.period-pill.active { background: #eff6ff; color: #2563eb; border-color: #2563eb; }

.btn-analyze {
  display: flex; align-items: center; gap: 5px;
  padding: 7px 13px; border-radius: 8px;
  border: 1.5px solid #e9d5ff; background: #faf5ff;
  color: #7c3aed; font-size: 12px; font-weight: 700;
  cursor: pointer; font-family: inherit; transition: all .15s;
}
.btn-analyze:hover:not(:disabled) { background: #f3e8ff; }
.btn-analyze:disabled { opacity: .6; cursor: not-allowed; }

.btn-export {
  display: flex; align-items: center; gap: 5px;
  padding: 7px 14px; border-radius: 8px; border: none;
  background: #2563eb; color: #fff; font-size: 12px; font-weight: 700;
  cursor: pointer; font-family: inherit; transition: background .15s;
}
.btn-export:hover:not(:disabled) { background: #1d4ed8; }
.btn-export:disabled { opacity: .5; cursor: not-allowed; }

/* ── KPI CARDS ────────────────────────────────────────────────────── */
.kpi-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; }
.kpi-card {
  background: #fff; border-radius: 14px; padding: 18px;
  border: 1px solid #f1f5f9; animation: slideUp .38s ease both;
}
.kpi-icon {
  width: 38px; height: 38px; border-radius: 10px;
  display: flex; align-items: center; justify-content: center; margin-bottom: 12px;
}
.kpi-icon span { display: flex; }
.kpi-value { font-size: 24px; font-weight: 800; color: #1e293b; margin-bottom: 4px; }
.kpi-label { font-size: 12px; color: #64748b; font-weight: 500; margin-bottom: 5px; }
.kpi-trend  { font-size: 11px; font-weight: 700; }
.trend-up   { color: #16a34a; }
.trend-down { color: #ef4444; }

/* ── LAYOUT ───────────────────────────────────────────────────────── */
.main-row {
  display: flex; gap: 14px; align-items: flex-start;
}
.flex-1 { flex: 1; min-width: 0; }

/* ── CARD BASE ────────────────────────────────────────────────────── */
.card {
  background: #fff; border-radius: 14px; padding: 18px;
  border: 1px solid #f1f5f9; box-shadow: 0 1px 3px rgba(0,0,0,.04);
}
.card-header {
  display: flex; align-items: flex-start; justify-content: space-between;
  margin-bottom: 16px; gap: 10px;
}
.card-header h3 { font-size: 13.5px; font-weight: 700; color: #1e293b; }
.card-sub { font-size: 11px; color: #94a3b8; margin-top: 2px; }

/* ── LEGEND ───────────────────────────────────────────────────────── */
.legend { display: flex; align-items: center; gap: 12px; flex-shrink: 0; font-size: 11px; color: #64748b; flex-wrap: wrap; }
.leg-item { display: flex; align-items: center; gap: 5px; }
.leg-line { display: inline-block; width: 22px; height: 3px; border-radius: 2px; }
.leg-dashed { border: none; border-top: 2px dashed; height: 0; background: transparent; }
.leg-swatch { display: inline-block; width: 16px; height: 10px; border-radius: 3px; }

/* ── CHART ────────────────────────────────────────────────────────── */
.svg-wrap { width: 100%; position: relative; }
.chart-svg { width: 100%; height: 205px; display: block; overflow: visible; cursor: crosshair; }

/* ── TOOLTIP ──────────────────────────────────────────────────────── */
.chart-tip {
  position: absolute; pointer-events: none;
  background: #1e293b; color: #f8fafc; border-radius: 10px;
  padding: 10px 14px; font-size: 11.5px; min-width: 158px;
  box-shadow: 0 8px 24px rgba(0,0,0,.22); z-index: 50; white-space: nowrap;
}
.tip-enter-active { transition: opacity .12s ease, transform .12s ease; }
.tip-leave-active { transition: opacity .08s ease; }
.tip-enter-from   { opacity: 0; transform: translateY(4px) scale(.97); }
.tip-leave-to     { opacity: 0; }
.tip-label { font-weight: 700; font-size: 10px; color: #94a3b8; margin-bottom: 6px; letter-spacing: .5px; text-transform: uppercase; }
.tip-row   { display: flex; align-items: center; gap: 7px; line-height: 2; }
.tip-row strong { margin-left: auto; padding-left: 12px; font-weight: 700; color: #fff; }
.tip-dot   { display: inline-block; width: 7px; height: 7px; border-radius: 50%; flex-shrink: 0; }
.tip-muted { font-size: 10.5px; color: #94a3b8; }

/* ── MODEL CONFIDENCE ─────────────────────────────────────────────── */
.live-badge {
  background: #faf5ff; color: #7c3aed; font-size: 10px; font-weight: 700;
  padding: 3px 8px; border-radius: 99px; border: 1px solid #e9d5ff;
  flex-shrink: 0;
}
.confidence-list { display: flex; flex-direction: column; gap: 14px; }
.conf-item { display: flex; flex-direction: column; gap: 5px; }
.conf-row  { display: flex; align-items: center; justify-content: space-between; }
.conf-label { font-size: 12px; font-weight: 600; color: #475569; }
.conf-pct   { font-size: 13px; font-weight: 800; }
.conf-track { height: 7px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.conf-fill  { height: 100%; border-radius: 99px; width: 0%; transition: width .75s cubic-bezier(.4,0,.2,1); }
.conf-note  { font-size: 10.5px; color: #94a3b8; }
.conf-footer {
  margin-top: 16px; padding-top: 12px; border-top: 1px solid #f1f5f9;
  display: flex; align-items: center; gap: 5px;
  font-size: 11px; color: #94a3b8;
}

/* ── HEATMAP ──────────────────────────────────────────────────────── */
.heatmap-legend-strip {
  width: 80px; height: 10px; border-radius: 99px;
  background: linear-gradient(to right, #dbeafe, #1e3a8a);
}
.heatmap-legend-label { font-size: 10.5px; color: #94a3b8; }
.heatmap-wrap { overflow-x: auto; }
.heatmap-table { min-width: 500px; display: flex; flex-direction: column; gap: 5px; }
.hm-header-row { display: flex; align-items: center; margin-bottom: 4px; }
.hm-skill-col  { width: 160px; flex-shrink: 0; }
.hm-month-col  { flex: 1; text-align: center; font-size: 11px; font-weight: 600; color: #94a3b8; }
.hm-row { display: flex; align-items: center; gap: 0; }
.hm-skill-name {
  width: 160px; flex-shrink: 0; font-size: 12px; font-weight: 600; color: #475569;
  display: flex; align-items: center; gap: 6px; padding-right: 10px;
}
.hm-skill-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.hm-cell {
  flex: 1; height: 36px; display: flex; align-items: center; justify-content: center;
  border-radius: 5px; margin: 0 2px;
  transition: background .5s ease, transform .15s;
  cursor: default;
}
.hm-cell:hover { transform: scale(1.08); z-index: 2; position: relative; }
.hm-val { font-size: 11px; font-weight: 700; }

/* ── SECTION HEADER ───────────────────────────────────────────────── */
.section-head { display: flex; align-items: center; gap: 10px; margin-bottom: 6px; }
.section-title { font-size: 15px; font-weight: 800; color: #1e293b; }
.section-badge {
  font-size: 10.5px; font-weight: 700; padding: 3px 10px; border-radius: 99px;
  background: #faf5ff; color: #7c3aed; border: 1px solid #e9d5ff;
}
.section-sub { font-size: 12px; color: #94a3b8; margin-bottom: 14px; }

/* ── SKILL PREDICTIONS GRID ───────────────────────────────────────── */
.pred-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; }
.pred-card {
  background: #fff; border: 1px solid #f1f5f9; border-radius: 14px; padding: 18px;
  display: flex; flex-direction: column; gap: 7px;
  animation: slideUp .38s ease both;
  transition: box-shadow .15s, border-color .15s;
}
.pred-card:hover { box-shadow: 0 4px 16px rgba(0,0,0,.07); border-color: #e2e8f0; }
.pred-top { display: flex; align-items: center; justify-content: space-between; }
.pred-icon {
  width: 32px; height: 32px; border-radius: 9px;
  display: flex; align-items: center; justify-content: center; flex-shrink: 0;
}
.pred-icon span { display: flex; }
.pred-skill    { font-size: 13px; font-weight: 800; color: #1e293b; }
.pred-industry { font-size: 11px; color: #94a3b8; }
.pred-change-row { display: flex; align-items: center; }
.pred-change { font-size: 12px; font-weight: 700; }
.change-pos { color: #16a34a; }
.change-neg { color: #ef4444; }
.pred-bar-track { height: 6px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.pred-bar-fill  { height: 100%; border-radius: 99px; width: 0%; transition: width .85s cubic-bezier(.4,0,.2,1); }
.pred-note { font-size: 11px; color: #94a3b8; line-height: 1.5; }

.pred-conf-badge { font-size: 10px; font-weight: 700; padding: 3px 9px; border-radius: 99px; }
.conf-high { background: #f0fdf4; color: #15803d; }
.conf-med  { background: #fffbeb; color: #b45309; }
.conf-low  { background: #fef2f2; color: #dc2626; }

/* ── AI INSIGHT CARD ──────────────────────────────────────────────── */
.ai-insight-card {
  border: 1.5px solid #e9d5ff !important;
}
.ai-header-left { display: flex; align-items: center; gap: 8px; }
.ai-pulse {
  width: 8px; height: 8px; border-radius: 50%; background: #c4b5fd; flex-shrink: 0;
}
.ai-pulse.pulsing { background: #7c3aed; animation: pulse 1.6s infinite; }
@keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.25} }
.claude-badge {
  font-size: 10px; font-weight: 700; padding: 2px 8px; border-radius: 99px;
  background: #7c3aed; color: #fff;
}
.ai-period-tag { font-size: 11px; color: #a78bfa; font-weight: 600; }

.ai-loading {
  display: flex; flex-direction: column; align-items: center; gap: 10px;
  padding: 28px 0; text-align: center;
}
.ai-spinner {
  width: 50px; height: 50px; background: #faf5ff; border-radius: 50%;
  display: flex; align-items: center; justify-content: center; position: relative;
}
.spin-ring {
  position: absolute; inset: 0; border-radius: 50%;
  border: 2.5px solid #e9d5ff; border-top-color: #7c3aed;
  animation: spin 1s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
.ai-loading-title { font-size: 13.5px; font-weight: 700; color: #5b21b6; }
.ai-loading-sub   { font-size: 11.5px; color: #a78bfa; max-width: 260px; line-height: 1.5; }

.ai-empty {
  display: flex; flex-direction: column; align-items: center; gap: 10px;
  padding: 32px 0; text-align: center;
}
.ai-empty-icon {
  width: 56px; height: 56px; background: #faf5ff; border-radius: 14px;
  display: flex; align-items: center; justify-content: center;
}
.ai-empty-title { font-size: 14px; font-weight: 700; color: #475569; }
.ai-empty-sub   { font-size: 12px; color: #94a3b8; max-width: 240px; line-height: 1.6; }
.btn-run {
  display: flex; align-items: center; gap: 6px;
  padding: 9px 18px; background: #7c3aed; color: #fff;
  border: none; border-radius: 9px; font-size: 13px; font-weight: 700;
  cursor: pointer; font-family: inherit; margin-top: 4px; transition: background .15s;
}
.btn-run:hover { background: #6d28d9; }

.ai-result {}
.insight-meta-row { display: flex; gap: 14px; flex-wrap: wrap; margin-bottom: 10px; }
.meta-item { display: flex; align-items: center; gap: 5px; font-size: 11px; color: #64748b; font-weight: 600; }
.insight-chips { display: flex; flex-wrap: wrap; gap: 5px; margin-bottom: 10px; }
.chip {
  font-size: 11px; font-weight: 700; padding: 4px 10px;
  border-radius: 99px; border: 1px solid;
}
.chip-green  { background: #f0fdf4; color: #15803d; border-color: #bbf7d0; }
.chip-red    { background: #fef2f2; color: #dc2626; border-color: #fecaca; }
.chip-blue   { background: #eff6ff; color: #1d4ed8; border-color: #bfdbfe; }
.chip-amber  { background: #fffbeb; color: #b45309; border-color: #fde68a; }
.chip-purple { background: #faf5ff; color: #7c3aed; border-color: #e9d5ff; }

.insight-divider { height: 1px; background: #f1f5f9; margin: 12px 0; }
.insight-text { font-size: 12.5px; color: #475569; line-height: 1.8; }
.insight-text p { margin: 0 0 10px; }
.insight-text p:last-child { margin-bottom: 0; }
.insight-text strong { font-weight: 700; color: #1e293b; }

.ai-footer { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.ai-gen-at  { font-size: 11px; color: #94a3b8; }
.btn-sm-outline {
  display: flex; align-items: center; gap: 5px;
  padding: 6px 12px; border-radius: 8px; font-size: 12px; font-weight: 700;
  background: #f8fafc; border: 1px solid #e2e8f0; color: #64748b;
  cursor: pointer; font-family: inherit; transition: all .15s;
}
.btn-sm-outline:hover { background: #f1f5f9; }
.btn-sm-primary {
  display: flex; align-items: center; gap: 5px;
  padding: 6px 12px; border-radius: 8px; font-size: 12px; font-weight: 700;
  background: #7c3aed; border: none; color: #fff;
  cursor: pointer; font-family: inherit; transition: background .15s;
}
.btn-sm-primary:hover { background: #6d28d9; }

/* ── ANIMATIONS ───────────────────────────────────────────────────── */
@keyframes slideUp { from{opacity:0;transform:translateY(10px)} to{opacity:1;transform:translateY(0)} }
</style>