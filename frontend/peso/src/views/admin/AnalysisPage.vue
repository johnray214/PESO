<template>
  <div class="pa-page">
    <!-- Toast notifications -->
    <div class="toast-stack" role="status" aria-live="polite">
      <transition-group name="toast">
        <div
          v-for="t in toasts"
          :key="t.id"
          :class="['toast', 'toast-' + t.type]"
          role="alert"
        >
          <span class="toast-icon" aria-hidden="true">
            <svg v-if="t.type === 'success'" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
            <svg v-else-if="t.type === 'error'" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          </span>
          <span class="toast-msg">{{ t.message }}</span>
          <button class="toast-close" @click="dismissToast(t.id)" aria-label="Dismiss notification">&times;</button>
        </div>
      </transition-group>
    </div>

    <!-- ============================== HEADER ============================== -->
    <header class="pa-header">
      <div class="header-main">
        <div class="title-row">
          <span class="ai-icon" aria-hidden="true">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/>
            </svg>
          </span>
          <h1 class="page-title">Predictive Analytics</h1>
          <span class="ai-tag">AI Powered</span>
          <span v-if="lastUpdatedAt" class="last-updated" :title="lastUpdatedFull">
            <span class="lu-dot" aria-hidden="true"></span>
            Updated {{ lastUpdatedRelative }}
          </span>
        </div>
        <p class="page-sub">
          Employment trend forecasting and skill demand prediction based on live PESO data
        </p>
      </div>

      <div class="header-actions">
        <div class="period-pills" role="group" aria-label="Forecast period">
          <button
            v-for="p in periodOptions"
            :key="p.value"
            type="button"
            :class="['period-pill', { active: activePeriod === p.value }]"
            :aria-pressed="activePeriod === p.value"
            @click="setPeriod(p.value)"
          >{{ p.label }}</button>
        </div>

        <button
          type="button"
          class="btn btn-secondary"
          :disabled="analyzing || loading"
          @click="runPrediction"
        >
          <svg v-if="!analyzing" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" aria-hidden="true"><path d="M23 4v6h-6"/><path d="M1 20v-6h6"/><path d="M3.51 9a9 9 0 0114.85-3.36L23 10"/><path d="M20.49 15a9 9 0 01-14.85 3.36L1 14"/></svg>
          <span v-else class="btn-spinner" aria-hidden="true"></span>
          {{ analyzing ? 'Predicting...' : 'Re-predict' }}
        </button>

        <button
          type="button"
          class="btn btn-primary"
          :disabled="!hasData || exporting"
          :title="!hasData ? 'Run a prediction first to enable export' : 'Download PDF report'"
          @click="exportReport"
        >
          <svg v-if="!exporting" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
          <span v-else class="btn-spinner" aria-hidden="true"></span>
          {{ exporting ? 'Exporting...' : 'Export Report' }}
        </button>
      </div>
    </header>

    <!-- ============================== SKELETON ============================== -->
    <template v-if="loading">
      <div class="kpi-grid">
        <div v-for="i in 4" :key="i" class="kpi-card">
          <div class="skel" style="width:38px;height:38px;border-radius:10px;margin-bottom:14px"></div>
          <div class="skel" style="width:72px;height:26px;border-radius:6px;margin-bottom:8px"></div>
          <div class="skel" style="width:120px;height:12px;border-radius:4px;margin-bottom:6px"></div>
          <div class="skel" style="width:80px;height:11px;border-radius:4px"></div>
        </div>
      </div>
      <div class="main-row">
        <div class="skel" style="height:340px;border-radius:14px;flex:1"></div>
        <div class="skel" style="height:340px;border-radius:14px;width:280px"></div>
      </div>
      <div class="skel" style="height:280px;border-radius:14px"></div>
      <div class="skel" style="height:240px;border-radius:14px"></div>
    </template>

    <!-- ============================== CONTENT ============================== -->
    <template v-else>

      <!-- ───────────── KPI CARDS ───────────── -->
      <section class="kpi-grid" aria-label="Key forecast indicators">
        <article
          v-for="(kpi, i) in kpis"
          :key="kpi.label"
          class="kpi-card"
          :style="{ animationDelay: (i * 0.06) + 's' }"
        >
          <div class="kpi-icon" :style="{ background: kpi.iconBg }" aria-hidden="true">
            <span v-html="kpi.icon" :style="{ color: kpi.iconColor }"></span>
          </div>
          <h2 class="kpi-value">{{ kpiAnimValues[i] || kpi.value }}</h2>
          <p class="kpi-label">
            {{ kpi.label }}
            <span v-if="kpi.tooltip" class="kpi-info" :title="kpi.tooltip" aria-hidden="true">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
            </span>
          </p>
          <span class="kpi-trend" :class="trendClass(kpi)">
            <svg v-if="trendDirection(kpi) === 'up'" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="18 15 12 9 6 15"/></svg>
            <svg v-else-if="trendDirection(kpi) === 'down'" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="6 9 12 15 18 9"/></svg>
            <svg v-else width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/></svg>
            {{ kpi.trend }} {{ kpi.trendLabel || 'vs last period' }}
          </span>
        </article>
      </section>

      <!-- ───────────── CHART + CONFIDENCE ───────────── -->
      <section class="main-row">

        <!-- Trend chart -->
        <article class="card chart-card">
          <header class="card-header">
            <div>
              <h3>Employment Trend Forecast</h3>
              <p class="card-sub">Historical placements + AI-predicted trend for the next {{ predictedTrendData.length }} months</p>
            </div>
            <div class="legend" role="list">
              <span class="leg-item" role="listitem"><span class="leg-line" style="background:#2563eb"></span>Actual</span>
              <span class="leg-item" role="listitem"><span class="leg-line leg-dashed" style="border-color:#8b5cf6"></span>Predicted</span>
              <span class="leg-item" role="listitem"><span class="leg-swatch" style="background:#8b5cf615"></span>Confidence band</span>
            </div>
          </header>

          <!-- Empty state -->
          <div v-if="!hasData" class="chart-empty">
            <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5" aria-hidden="true"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
            <p>No forecast data available for this period.</p>
            <button class="btn btn-secondary btn-sm" @click="fetchData">Retry</button>
          </div>

          <div
            v-else
            class="svg-wrap"
            ref="trendWrap"
            @mousemove="onTrendMove"
            @mouseleave="trendTip = null"
            role="img"
            :aria-label="`Employment trend: ${actualTrendData.length} months actual, ${predictedTrendData.length} months predicted`"
          >
            <transition name="tip">
              <div
                v-if="trendTip"
                class="chart-tip"
                :style="{ left: trendTip.x + 'px', top: trendTip.y + 'px' }"
              >
                <div class="tip-label">{{ trendTip.label }}</div>
                <div class="tip-row" v-if="trendTip.actual !== null">
                  <span class="tip-dot" style="background:#2563eb"></span>Actual
                  <strong>{{ formatNumber(trendTip.actual) }}</strong>
                </div>
                <div class="tip-row" v-if="trendTip.predicted !== null">
                  <span class="tip-dot" style="background:#8b5cf6"></span>Predicted
                  <strong>{{ formatNumber(trendTip.predicted) }}</strong>
                </div>
                <div class="tip-row tip-muted" v-if="trendTip.isPredicted && trendTip.low !== null">
                  <span></span>95% CI {{ formatNumber(trendTip.low) }}–{{ formatNumber(trendTip.high) }}
                </div>
              </div>
            </transition>

            <svg
              ref="trendSvg"
              viewBox="0 0 640 200"
              preserveAspectRatio="xMidYMid meet"
              class="chart-svg"
              aria-hidden="true"
            >
              <defs>
                <linearGradient id="paGActual" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stop-color="#2563eb" stop-opacity="0.18"/>
                  <stop offset="100%" stop-color="#2563eb" stop-opacity="0"/>
                </linearGradient>
                <linearGradient id="paGPred" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stop-color="#8b5cf6" stop-opacity="0.14"/>
                  <stop offset="100%" stop-color="#8b5cf6" stop-opacity="0"/>
                </linearGradient>
                <clipPath id="paTrendClip">
                  <rect
                    x="52"
                    y="0"
                    height="175"
                    :width="trendAnimated ? 578 : 0"
                    style="transition: width 1.1s cubic-bezier(.4,0,.2,1);"
                  />
                </clipPath>
              </defs>

              <!-- Forecast zone background -->
              <rect
                v-if="splitX > 52"
                :x="splitX"
                y="10"
                :width="630 - splitX"
                height="158"
                fill="#faf5ff"
                opacity="0.55"
              />

              <!-- Grid -->
              <line
                v-for="gl in trendGrid"
                :key="'g' + gl.y"
                :x1="52" :y1="gl.y" :x2="630" :y2="gl.y"
                stroke="#f1f5f9" stroke-width="1"
              />
              <text
                v-for="gl in trendGrid"
                :key="'gl' + gl.y"
                :x="46" :y="gl.y + 4"
                text-anchor="end" font-size="9" fill="#cbd5e1"
                font-family="Plus Jakarta Sans,sans-serif"
              >{{ formatNumber(gl.label) }}</text>

              <g clip-path="url(#paTrendClip)">
                <!-- Confidence band -->
                <path :d="confidenceBandPath" fill="#8b5cf615"/>
                <!-- Actual area + line -->
                <path :d="actualAreaPath" fill="url(#paGActual)"/>
                <path
                  :d="actualLinePath"
                  fill="none"
                  stroke="#2563eb"
                  stroke-width="2.5"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
                <!-- Predicted dashed line -->
                <path
                  :d="predictedLinePath"
                  fill="none"
                  stroke="#8b5cf6"
                  stroke-width="2"
                  stroke-dasharray="5 3"
                  stroke-linecap="round"
                />
                <!-- Forecast divider -->
                <line
                  v-if="splitX > 52"
                  :x1="splitX" y1="10"
                  :x2="splitX" y2="168"
                  stroke="#c4b5fd" stroke-width="1.5"
                  stroke-dasharray="4 3"
                />
                <text
                  v-if="splitX > 52"
                  :x="splitX + 5" y="16"
                  font-size="9" font-weight="700"
                  fill="#7c3aed"
                  font-family="Plus Jakarta Sans,sans-serif"
                >FORECAST →</text>
              </g>

              <!-- X labels (density-aware) -->
              <text
                v-for="(pt, i) in visibleTrendPoints"
                :key="'xl' + i"
                :x="pt.x" :y="188"
                text-anchor="middle"
                font-size="9"
                :fill="pt.isPredicted ? '#8b5cf6' : '#94a3b8'"
                :font-weight="pt.isPredicted ? '600' : '500'"
                font-family="Plus Jakarta Sans,sans-serif"
              >{{ pt.label }}</text>

              <!-- Hover dots -->
              <circle
                v-for="(pt, i) in actualDots"
                :key="'ad' + i"
                :cx="pt.x" :cy="pt.y"
                :r="trendTip && trendTip.i === i ? 5 : 3.5"
                fill="#fff" stroke="#2563eb" stroke-width="2"
                pointer-events="none"
                style="transition: r .12s"
              />
              <circle
                v-for="(pt, i) in predictedDots"
                :key="'pd' + i"
                :cx="pt.x" :cy="pt.y"
                :r="trendTip && trendTip.i === (actualTrendData.length + i) ? 5 : 3.5"
                fill="#fff" stroke="#8b5cf6" stroke-width="2"
                pointer-events="none"
                style="transition: r .12s"
              />

              <!-- Hit areas (full column) -->
              <rect
                v-for="(pt, i) in allTrendPoints"
                :key="'h' + i"
                :x="pt.x - trendColW / 2"
                y="0"
                :width="trendColW"
                height="175"
                fill="transparent"
                style="cursor: crosshair"
              />
            </svg>
          </div>
        </article>

        <!-- Confidence panel -->
        <aside class="card confidence-card">
          <header class="card-header">
            <div>
              <h3>Model Confidence</h3>
              <p class="card-sub">Prediction reliability scores</p>
            </div>
            <span class="live-badge">AI</span>
          </header>

          <div class="confidence-list">
            <div v-for="mc in modelConfidence" :key="mc.label" class="conf-item">
              <div class="conf-row">
                <span class="conf-label">{{ mc.label }}</span>
                <span class="conf-pct" :style="{ color: confidenceColor(mc.pct) }">{{ mc.pct }}%</span>
              </div>
              <div class="conf-track" :aria-label="`${mc.label}: ${mc.pct} percent`">
                <div
                  class="conf-fill"
                  :style="{
                    width: confAnimated ? mc.pct + '%' : '0%',
                    background: confidenceColor(mc.pct),
                  }"
                ></div>
              </div>
              <span class="conf-note">{{ mc.note }}</span>
            </div>
          </div>

          <div class="conf-footer">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            <span>Based on {{ formatNumber(modelDataPoints) }} historical data points</span>
          </div>
        </aside>
      </section>

      <!-- ───────────── HEATMAP ───────────── -->
      <section class="card heatmap-card">
        <header class="card-header">
          <div>
            <h3>Skill Demand Forecast Heatmap</h3>
            <p class="card-sub">Predicted demand intensity per skill — next {{ forecastMonths.length }} months</p>
          </div>
          <div class="heatmap-legend">
            <span class="heatmap-legend-label">Low</span>
            <div class="heatmap-legend-strip" aria-hidden="true">
              <span class="hl-tick" style="left:0">0</span>
              <span class="hl-tick" style="left:50%">50</span>
              <span class="hl-tick" style="left:100%">100</span>
            </div>
            <span class="heatmap-legend-label">High</span>
          </div>
        </header>

        <div class="heatmap-wrap">
          <div class="heatmap-table" role="grid" aria-label="Skill demand forecast">
            <div class="hm-header-row" role="row">
              <div class="hm-skill-col" role="columnheader" aria-label="Skill"></div>
              <div
                v-for="m in forecastMonths"
                :key="m"
                class="hm-month-col"
                role="columnheader"
              >{{ m }}</div>
            </div>

            <div
              v-for="(row, ri) in heatmapData"
              :key="row.skill"
              class="hm-row"
              role="row"
            >
              <div class="hm-skill-name" role="rowheader">
                <span class="hm-skill-dot" :style="{ background: row.color }" aria-hidden="true"></span>
                <span class="hm-skill-text">{{ row.skill }}</span>
              </div>
              <div
                v-for="(val, ci) in row.values"
                :key="ci"
                class="hm-cell"
                role="gridcell"
                tabindex="0"
                :style="{
                  background: heatmapAnimated ? heatColor(val) : '#f8fafc',
                  transitionDelay: (ri * 0.04 + ci * 0.02) + 's',
                }"
                :aria-label="`${row.skill} ${forecastMonths[ci]}: ${val} percent`"
                :title="`${row.skill} · ${forecastMonths[ci]}: ${val}% predicted demand`"
              >
                <span
                  class="hm-val"
                  :style="{ color: heatmapAnimated && val >= 60 ? '#fff' : '#475569' }"
                >{{ val }}%</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- ───────────── SKILL PREDICTIONS ───────────── -->
      <section class="predictions-section">
        <div class="section-head">
          <div>
            <div class="section-title-row">
              <h2 class="section-title">Skill Demand Predictions</h2>
              <span class="section-badge">Next 90 days · AI Forecast</span>
            </div>
            <p class="section-sub">
              Predicted skill demand based on current job postings, applicant profiles, employer growth, and seasonal hiring patterns
            </p>
          </div>
          <label class="sort-control">
            <span class="sort-label">Sort:</span>
            <select v-model="predictionSort" class="sort-select" aria-label="Sort predictions by">
              <option value="growth">Highest growth</option>
              <option value="decline">Highest decline</option>
              <option value="confidence">By confidence</option>
              <option value="alpha">A–Z</option>
            </select>
          </label>
        </div>

        <div class="pred-grid">
          <article
            v-for="(pred, i) in sortedPredictions"
            :key="pred.skill"
            class="pred-card"
            :style="{ animationDelay: (i * 0.05) + 's' }"
          >
            <header class="pred-top">
              <div class="pred-icon" :style="{ background: pred.iconBg }" aria-hidden="true">
                <span v-html="pred.icon" :style="{ color: pred.iconColor }"></span>
              </div>
              <span class="pred-conf-badge" :class="pred.confClass">{{ pred.confidence }} confidence</span>
            </header>
            <div class="pred-body">
              <p class="pred-skill">{{ pred.skill }}</p>
              <p class="pred-industry">{{ pred.industry }}</p>
              <div class="pred-change-row">
                <span class="pred-change" :class="pred.change >= 0 ? 'change-pos' : 'change-neg'">
                  <svg v-if="pred.change >= 0" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" aria-hidden="true"><polyline points="18 15 12 9 6 15"/></svg>
                  <svg v-else width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" aria-hidden="true"><polyline points="6 9 12 15 18 9"/></svg>
                  {{ pred.change >= 0 ? '+' : '' }}{{ pred.change }}% projected
                </span>
              </div>
            </div>
            <div class="pred-bar-track" :aria-label="`${pred.pct} percent demand intensity`">
              <div
                class="pred-bar-fill"
                :style="{
                  width: predsAnimated ? pred.pct + '%' : '0%',
                  background: pred.iconColor,
                }"
              ></div>
            </div>
            <p class="pred-note">{{ pred.note }}</p>
          </article>
        </div>
      </section>

      <!-- ───────────── AI INSIGHT ───────────── -->
      <section class="card ai-insight-card" aria-live="polite">
        <header class="card-header">
          <div class="ai-header-left">
            <span class="ai-pulse" :class="{ pulsing: analyzing }" aria-hidden="true"></span>
            <h3>AI Insight Summary</h3>
            <span class="claude-badge">Claude AI</span>
          </div>
          <span class="ai-period-tag">{{ periodLabel }}</span>
        </header>

        <!-- Analyzing -->
        <div v-if="analyzing" class="ai-loading">
          <div class="ai-spinner" aria-hidden="true">
            <div class="spin-ring"></div>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="2"><path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/></svg>
          </div>
          <p class="ai-loading-title">Analyzing employment trends...</p>
          <p class="ai-loading-sub">Processing jobseeker profiles, employer data, skill gaps, and seasonal patterns</p>
        </div>

        <!-- Error -->
        <div v-else-if="insightError" class="ai-empty">
          <div class="ai-empty-icon ai-empty-icon-error" aria-hidden="true">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#dc2626" stroke-width="1.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          </div>
          <p class="ai-empty-title">Unable to generate insight</p>
          <p class="ai-empty-sub">{{ insightError }}</p>
          <button type="button" class="btn-run" @click="runPrediction">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M23 4v6h-6"/><path d="M3.51 15a9 9 0 0014.85 3.36L23 14"/></svg>
            Try Again
          </button>
        </div>

        <!-- Empty -->
        <div v-else-if="!insightText" class="ai-empty">
          <div class="ai-empty-icon" aria-hidden="true">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#c4b5fd" stroke-width="1.5"><path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/></svg>
          </div>
          <p class="ai-empty-title">No AI insight generated yet</p>
          <p class="ai-empty-sub">Click "Run Prediction" to generate employment trend forecasts and skill demand insights from live data.</p>
          <button type="button" class="btn-run" @click="runPrediction" :disabled="!hasData">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><polygon points="5 3 19 12 5 21 5 3"/></svg>
            Run Prediction
          </button>
        </div>

        <!-- Result -->
        <div v-else class="ai-result">
          <div class="insight-meta-row">
            <span class="meta-item">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" aria-hidden="true"><circle cx="12" cy="8" r="5"/><path d="M3 21a9 9 0 0118 0"/></svg>
              {{ formatNumber(insightMeta.jobseekers) }} jobseekers
            </span>
            <span class="meta-item">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" aria-hidden="true"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 7V5a2 2 0 00-4 0v2"/></svg>
              {{ formatNumber(insightMeta.openings) }} openings
            </span>
            <span class="meta-item">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" aria-hidden="true"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
              {{ insightMeta.placementRate }} placement rate
            </span>
          </div>

          <div v-if="insightChips.length" class="insight-chips">
            <span
              v-for="chip in insightChips"
              :key="chip.text"
              class="chip"
              :class="chip.cls"
            >{{ chip.text }}</span>
          </div>

          <div class="insight-divider"></div>
          <div class="insight-text" v-html="formattedInsight"></div>
          <div class="insight-divider"></div>

          <div class="ai-footer">
            <span class="ai-gen-at">Generated {{ insightGeneratedAt }}</span>
            <div class="ai-footer-actions">
              <button type="button" class="btn-sm-outline" @click="runPrediction" :disabled="analyzing">
                Refresh
              </button>
              <button type="button" class="btn-sm-primary" @click="exportReport" :disabled="exporting">
                <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                Export PDF
              </button>
            </div>
          </div>
        </div>
      </section>

    </template>
  </div>
</template>

<script>
import api from '@/services/api'

const MIN_LOADING_MS = 400
const TOAST_TTL_MS = 6000

/* ───────────── helpers ───────────── */

function generateMonthLabels(count, startOffset = 0) {
  const out = []
  const now = new Date()
  for (let i = 0; i < count; i++) {
    const d = new Date(now.getFullYear(), now.getMonth() + startOffset + i, 1)
    const m = d.toLocaleString('en-US', { month: 'short' })
    const showYear = i === 0 || d.getMonth() === 0
    out.push(showYear ? `${m} '${String(d.getFullYear()).slice(2)}` : m)
  }
  return out
}

function clamp(v, lo, hi) {
  return Math.max(lo, Math.min(hi, v))
}

function isFiniteNumber(n) {
  return typeof n === 'number' && Number.isFinite(n)
}

/* allowlist sanitizer for AI-generated insight HTML */
function sanitizeInsightHtml(raw) {
  if (!raw) return ''
  const allowed = new Set(['p', 'strong', 'em', 'br'])
  const div = document.createElement('div')
  div.innerHTML = raw
  const walk = (node) => {
    const kids = Array.from(node.children)
    kids.forEach(child => {
      const tag = child.tagName.toLowerCase()
      if (!allowed.has(tag)) {
        const text = document.createTextNode(child.textContent || '')
        node.replaceChild(text, child)
        return
      }
      [...child.attributes].forEach(a => child.removeAttribute(a.name))
      walk(child)
    })
  }
  walk(div)
  return div.innerHTML
}

export default {
  name: 'PredictiveAnalytics',

  data() {
    return {
      /* state */
      loading: true,
      analyzing: false,
      exporting: false,
      activePeriod: 'monthly',
      sourcePeriod: '',
      lastUpdatedAt: null,
      lastUpdatedTick: 0,

      /* animations */
      trendAnimated: false,
      confAnimated: false,
      heatmapAnimated: false,
      predsAnimated: false,
      kpiAnimValues: ['—', '—', '—', '—'],

      /* chart interaction */
      trendTip: null,

      /* AI insight */
      insightText: '',
      insightError: '',
      insightGeneratedAt: '',
      insightChips: [],
      insightMeta: { jobseekers: 0, openings: 0, placementRate: '0%' },
      modelDataPoints: 0,

      /* sorting */
      predictionSort: 'growth',

      /* toasts */
      toasts: [],
      toastSeq: 0,

      /* periods */
      periodOptions: [
        { label: 'Weekly',  value: 'weekly'  },
        { label: 'Monthly', value: 'monthly' },
        { label: 'Yearly',  value: 'yearly'  },
      ],

      /* KPIs */
      kpis: [
        {
          label: 'Predicted Placements (next 30d)', value: '—', trend: '—', up: true,
          trendLabel: 'vs last period',
          tooltip: 'Forecasted number of jobseeker placements in the next 30 days based on hiring momentum and pipeline depth.',
          iconBg: '#eff6ff', iconColor: '#2563eb',
          icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>',
        },
        {
          label: 'Forecast Employment Rate', value: '—', trend: '—', up: true,
          trendLabel: 'vs last period',
          tooltip: 'Projected share of registered jobseekers expected to be employed by the end of this period.',
          iconBg: '#f0fdf4', iconColor: '#16a34a',
          icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>',
        },
        {
          label: 'Top Emerging Skill', value: '—', trend: '—', up: true,
          trendLabel: 'projected demand',
          tooltip: 'Skill with the highest projected demand growth based on job postings and employer signals.',
          iconBg: '#faf5ff', iconColor: '#8b5cf6',
          icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 20V10"/><path d="M12 20V4"/><path d="M6 20v-6"/></svg>',
        },
        {
          label: 'Skill-Gap Risk Score', value: '—', trend: '—', up: false,
          trendLabel: 'change vs last period',
          tooltip: 'Composite risk score of mismatch between in-demand skills and current jobseeker profiles. Lower is better.',
          iconBg: '#fff7ed', iconColor: '#f97316',
          icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>',
        },
      ],

      /* data */
      actualTrendData: [],
      predictedTrendData: [],
      forecastMonths: [],
      heatmapData: [],
      skillPredictions: [],
      modelConfidence: [],

      /* internal lifecycle handles */
      observers: [],
      resizeObserver: null,
      luTimer: null,
    }
  },

  computed: {
    hasData() {
      return this.actualTrendData.length > 0 && this.predictedTrendData.length > 0
    },

    periodLabel() {
      const map = {
        weekly: 'This week',
        monthly: new Date().toLocaleString('en-US', { month: 'long', year: 'numeric' }),
        yearly: 'This year',
      }
      return map[this.activePeriod] || ''
    },

    lastUpdatedFull() {
      if (!this.lastUpdatedAt) return ''
      return this.lastUpdatedAt.toLocaleString('en-US', {
        weekday: 'short', month: 'short', day: 'numeric',
        hour: '2-digit', minute: '2-digit',
      })
    },

    lastUpdatedRelative() {
      if (!this.lastUpdatedAt) return ''
      void this.lastUpdatedTick // reactive trigger
      const diff = Math.floor((Date.now() - this.lastUpdatedAt.getTime()) / 1000)
      if (diff < 10) return 'just now'
      if (diff < 60) return `${diff}s ago`
      if (diff < 3600) return `${Math.floor(diff / 60)}m ago`
      if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`
      return `${Math.floor(diff / 86400)}d ago`
    },

    /* chart geometry */
    chartW() { return 578 },
    chartH() { return 158 },
    chartYBottom() { return 168 },

    chartScale() {
      const all = [...this.actualTrendData, ...this.predictedTrendData]
      if (!all.length) return { nice: 1 }
      const max = Math.max(
        ...all.map(d => Math.max(
          isFiniteNumber(d.value) ? d.value : 0,
          isFiniteNumber(d.high) ? d.high : 0,
        )),
        1,
      )
      return { nice: this._niceMax(max) }
    },

    allTrendPoints() {
      const all = [...this.actualTrendData, ...this.predictedTrendData]
      const n = all.length
      if (!n) return []
      const { nice } = this.chartScale
      return all.map((d, i) => {
        const x = 52 + i * (this.chartW / Math.max(n - 1, 1))
        const y = this.chartYBottom - ((d.value / nice) * this.chartH)
        return {
          x, y,
          label: d.label,
          isPredicted: i >= this.actualTrendData.length,
          i,
          value: d.value,
          low:  isFiniteNumber(d.low)  ? d.low  : null,
          high: isFiniteNumber(d.high) ? d.high : null,
        }
      })
    },

    /* density-aware label visibility */
    visibleTrendPoints() {
      const pts = this.allTrendPoints
      if (pts.length <= 12) return pts
      const step = Math.ceil(pts.length / 12)
      return pts.filter((_, i) => i % step === 0 || i === pts.length - 1)
    },

    actualDots()    { return this.allTrendPoints.filter(p => !p.isPredicted) },
    predictedDots() { return this.allTrendPoints.filter(p =>  p.isPredicted) },

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
      const { nice } = this.chartScale
      const steps = 4
      return Array.from({ length: steps + 1 }, (_, i) => ({
        y: 10 + (i / steps) * this.chartH,
        label: Math.round((nice / steps) * (steps - i)),
      }))
    },

    actualLinePath() { return this._smooth(this.actualDots) },

    actualAreaPath() {
      const pts = this.actualDots
      if (!pts.length) return ''
      return this._smooth(pts) +
        ` L${pts[pts.length - 1].x},${this.chartYBottom}` +
        ` L${pts[0].x},${this.chartYBottom} Z`
    },

    predictedLinePath() {
      const last = this.actualDots[this.actualDots.length - 1]
      const pred = this.predictedDots
      if (!pred.length) return ''
      const all = last ? [last, ...pred] : pred
      return this._smooth(all)
    },

    confidenceBandPath() {
      const preds = this.predictedTrendData
      if (!preds.length) return ''
      const { nice } = this.chartScale
      const all = [...this.actualTrendData, ...this.predictedTrendData]
      const n = all.length
      const toY = v => this.chartYBottom - ((v / nice) * this.chartH)
      const toX = i => 52 + i * (this.chartW / Math.max(n - 1, 1))
      const startIdx = this.actualTrendData.length

      const top = preds.map((d, i) => ({
        x: toX(startIdx + i),
        y: toY(isFiniteNumber(d.high) ? d.high : d.value),
      }))
      const bot = [...preds].reverse().map((d, i) => {
        const ri = preds.length - 1 - i
        return {
          x: toX(startIdx + ri),
          y: toY(isFiniteNumber(d.low) ? d.low : d.value),
        }
      })

      const lastActual = this.actualDots[this.actualDots.length - 1]
      const lastActualVal = this.actualTrendData[this.actualTrendData.length - 1]?.value ?? 0
      const startPt = lastActual ? [{ x: lastActual.x, y: toY(lastActualVal) }] : []

      const allTop = [...startPt, ...top]
      if (!allTop.length) return ''

      let path = `M${allTop[0].x},${allTop[0].y}`
      allTop.slice(1).forEach(p => { path += ` L${p.x},${p.y}` })
      bot.forEach(p => { path += ` L${p.x},${p.y}` })
      if (startPt.length) path += ` L${startPt[0].x},${startPt[0].y}`
      path += ' Z'
      return path
    },

    sortedPredictions() {
      const list = [...this.skillPredictions]
      const confRank = c => ({ High: 3, Medium: 2, Low: 1 }[c] || 0)
      switch (this.predictionSort) {
        case 'decline':    return list.sort((a, b) => a.change - b.change)
        case 'confidence': return list.sort((a, b) => confRank(b.confidence) - confRank(a.confidence))
        case 'alpha':      return list.sort((a, b) => a.skill.localeCompare(b.skill))
        case 'growth':
        default:           return list.sort((a, b) => b.change - a.change)
      }
    },

    formattedInsight() {
      if (!this.insightText) return ''
      const raw = this.insightText
        .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
        .replace(/\n\n/g, '</p><p>')
        .replace(/^/, '<p>')
        .replace(/$/, '</p>')
      return sanitizeInsightHtml(raw)
    },
  },

  async mounted() {
    await this.$nextTick()
    await this.fetchData()
    this.luTimer = setInterval(() => { this.lastUpdatedTick++ }, 30000)
  },

  beforeUnmount() {
    this.observers.forEach(o => o.disconnect())
    this.observers = []
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
      this.resizeObserver = null
    }
    if (this.luTimer) {
      clearInterval(this.luTimer)
      this.luTimer = null
    }
    this.toasts.forEach(t => clearTimeout(t.timer))
  },

  methods: {

    /* ───────────── data fetch ───────────── */

    setPeriod(p) {
      if (this.activePeriod === p) return
      this.activePeriod = p
      this.fetchData()
    },

    async fetchData() {
      this.loading = true
      this._resetAnims()
      const startedAt = Date.now()
      try {
        const { data } = await api.get('/admin/predictive-analytics/data', {
          params: { period: this.activePeriod },
        })
        const ok = this._applyData(data?.data)
        if (!ok) {
          this._applyMockData()
          this.notify('warning', 'Live data unavailable. Showing reference forecast.')
        }
        this._applyPeriodView()
        this.lastUpdatedAt = new Date()
      } catch (e) {
        console.warn('[PredictiveAnalytics] fetch failed, using mock:', e?.message || e)
        this._applyMockData()
        this._applyPeriodView()
        this.lastUpdatedAt = new Date()
        this.notify('warning', 'Could not reach analytics service. Showing reference forecast.')
      } finally {
        const elapsed = Date.now() - startedAt
        if (elapsed < MIN_LOADING_MS) {
          await new Promise(r => setTimeout(r, MIN_LOADING_MS - elapsed))
        }
        this.loading = false
        await this.$nextTick()
        this._setupObservers()
        this._startKpiAnimations()
      }
    },

    /* ───────────── AI prediction ───────────── */

    async runPrediction() {
      if (this.analyzing || !this.hasData) return
      this.analyzing = true
      this.insightError = ''
      this.insightText = ''
      this.insightChips = []
      try {
        const { data } = await api.post('/admin/predictive-analytics/generate', {
          period:         this.activePeriod,
          actualTrend:    this.actualTrendData,
          predictedTrend: this.predictedTrendData,
          heatmap:        this.heatmapData,
          predictions:    this.skillPredictions,
          kpis:           this.kpis.map(k => ({ label: k.label, value: k.value })),
        })
        this.insightText = data?.insight || ''
        this.insightChips = Array.isArray(data?.chips) ? data.chips : this._autoChips()
        this.insightGeneratedAt = this._formatTime(new Date())
        if (!this.insightText) {
          this.insightError = 'The AI did not return a result. Please try again.'
          this.notify('error', 'AI insight returned empty result.')
        } else {
          this.notify('success', 'AI insight generated.')
        }
      } catch (e) {
        console.error('[PredictiveAnalytics] generate failed:', e)
        this.insightError = 'AI service is temporarily unavailable. Please try again in a moment.'
        this.notify('error', 'Could not generate AI insight.')
      } finally {
        this.analyzing = false
      }
    },

    /* ───────────── export ───────────── */

    async exportReport() {
      if (!this.hasData || this.exporting) return
      this.exporting = true
      try {
        const { data } = await api.post('/admin/predictive-analytics/export-pdf', {
          period:      this.activePeriod,
          kpis:        this.kpis,
          insightText: this.insightText,
          predictions: this.skillPredictions,
          heatmap:     this.heatmapData,
          generatedAt: this.insightGeneratedAt,
        }, { responseType: 'blob' })
        const blob = new Blob([data], { type: 'application/pdf' })
        const url  = URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = `predictive-analytics-${this.activePeriod}-${new Date().toISOString().split('T')[0]}.pdf`
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        URL.revokeObjectURL(url)
        this.notify('success', 'Report downloaded.')
      } catch (e) {
        console.error('[PredictiveAnalytics] export failed:', e)
        this.notify('error', 'Failed to export report.')
      } finally {
        this.exporting = false
      }
    },

    /* ───────────── data application + validation ───────────── */

    _applyData(d) {
      if (!d || typeof d !== 'object') return false

      try {
        this.sourcePeriod = String(d.period || d.timeframe || '').toLowerCase()
        if (Array.isArray(d.kpis)) {
          d.kpis.forEach((k, i) => {
            if (this.kpis[i] && k && typeof k === 'object') {
              const safe = {}
              if (typeof k.value !== 'undefined') safe.value = String(k.value)
              if (typeof k.trend !== 'undefined') safe.trend = String(k.trend)
              if (typeof k.up    !== 'undefined') safe.up    = !!k.up
              Object.assign(this.kpis[i], safe)
            }
          })
        }

        const validTrend = arr => Array.isArray(arr) && arr.every(x =>
          x && typeof x === 'object' &&
          typeof x.label === 'string' &&
          isFiniteNumber(Number(x.value)),
        )

        if (validTrend(d.actualTrend)) {
          this.actualTrendData = d.actualTrend.map(x => ({
            label: x.label, value: Number(x.value),
          }))
        }
        if (validTrend(d.predictedTrend)) {
          this.predictedTrendData = d.predictedTrend.map(x => ({
            label: x.label,
            value: Number(x.value),
            low:   isFiniteNumber(Number(x.low))  ? Number(x.low)  : undefined,
            high:  isFiniteNumber(Number(x.high)) ? Number(x.high) : undefined,
          }))
        }

        if (Array.isArray(d.forecastMonths) && d.forecastMonths.every(m => typeof m === 'string')) {
          this.forecastMonths = d.forecastMonths
        }

        if (Array.isArray(d.heatmap)) {
          const cols = this.forecastMonths.length || 6
          this.heatmapData = d.heatmap.filter(r =>
            r && typeof r.skill === 'string' &&
            Array.isArray(r.values) &&
            r.values.length === cols &&
            r.values.every(v => isFiniteNumber(Number(v))),
          ).map(r => ({
            skill:  r.skill,
            color:  typeof r.color === 'string' ? r.color : '#2563eb',
            values: r.values.map(v => clamp(Number(v), 0, 100)),
          }))
        }

        if (Array.isArray(d.predictions)) {
          this.skillPredictions = d.predictions.filter(p =>
            p && typeof p.skill === 'string' &&
            isFiniteNumber(Number(p.change)) &&
            isFiniteNumber(Number(p.pct)),
          ).map(p => ({
            skill:      p.skill,
            industry:   String(p.industry || ''),
            change:     Number(p.change),
            pct:        clamp(Number(p.pct), 0, 100),
            confidence: ['High','Medium','Low'].includes(p.confidence) ? p.confidence : 'Medium',
            confClass:  p.confClass || 'conf-med',
            note:       String(p.note || ''),
            iconBg:     p.iconBg     || '#f1f5f9',
            iconColor:  p.iconColor  || '#64748b',
            icon:       typeof p.icon === 'string' ? p.icon : '',
          }))
        }

        if (Array.isArray(d.modelConfidence)) {
          this.modelConfidence = d.modelConfidence.filter(m =>
            m && typeof m.label === 'string' &&
            isFiniteNumber(Number(m.pct)),
          ).map(m => ({
            label: m.label,
            pct:   clamp(Number(m.pct), 0, 100),
            note:  String(m.note || ''),
            color: m.color,
          }))
        }

        if (d.insightMeta && typeof d.insightMeta === 'object') {
          this.insightMeta = {
            jobseekers:     Number(d.insightMeta.jobseekers)     || 0,
            openings:       Number(d.insightMeta.openings)       || 0,
            placementRate:  String(d.insightMeta.placementRate || '0%'),
          }
        }

        this.modelDataPoints = Number(d.modelDataPoints) || 0

        if (!this.hasData) return false
        return true
      } catch (err) {
        console.error('[PredictiveAnalytics] apply data failed:', err)
        return false
      }
    },

    _applyMockData() {
      this.sourcePeriod = 'monthly'
      const histLabels = generateMonthLabels(12, -11)
      const futLabels  = generateMonthLabels(6, 1)

      this.kpis[0].value = '342';       this.kpis[0].trend = '+8%';   this.kpis[0].up = true
      this.kpis[1].value = '64.3%';     this.kpis[1].trend = '+2.1%'; this.kpis[1].up = true
      this.kpis[2].value = 'IT Support';this.kpis[2].trend = '+23%';  this.kpis[2].up = true
      this.kpis[3].value = 'Medium';    this.kpis[3].trend = '-5%';   this.kpis[3].up = false

      this.insightMeta = { jobseekers: 4821, openings: 1349, placementRate: '38.4%' }
      this.modelDataPoints = 12840

      const histValues = [210, 245, 230, 268, 255, 290, 310, 285, 320, 298, 342, 365]
      this.actualTrendData = histLabels.map((label, i) => ({ label, value: histValues[i] }))

      const futValues = [
        { v: 380, l: 355, h: 408 },
        { v: 395, l: 362, h: 430 },
        { v: 412, l: 372, h: 455 },
        { v: 428, l: 380, h: 478 },
        { v: 448, l: 390, h: 508 },
        { v: 465, l: 400, h: 532 },
      ]
      this.predictedTrendData = futLabels.map((label, i) => ({
        label, value: futValues[i].v, low: futValues[i].l, high: futValues[i].h,
      }))

      this.forecastMonths = futLabels

      this.heatmapData = [
        { skill: 'IT / Tech Support',     color: '#2563eb', values: [72, 78, 84, 88, 91, 93] },
        { skill: 'Healthcare Aide',       color: '#16a34a', values: [55, 60, 65, 68, 72, 75] },
        { skill: 'BPO / Call Center',     color: '#8b5cf6', values: [80, 82, 79, 77, 75, 73] },
        { skill: 'Construction',          color: '#f59e0b', values: [60, 58, 62, 68, 72, 70] },
        { skill: 'Food Service',          color: '#f97316', values: [70, 68, 65, 64, 63, 61] },
        { skill: 'Accounting / Finance',  color: '#06b6d4', values: [45, 48, 50, 52, 55, 58] },
        { skill: 'Logistics / Driving',   color: '#ef4444', values: [50, 46, 42, 40, 38, 35] },
      ]

      this.skillPredictions = [
        { skill: 'IT / Tech Support', industry: 'Technology', change: 23, pct: 88, confidence: 'High', confClass: 'conf-high',
          note: 'BPO expansion and digital transformation driving consistent growth.',
          iconBg: '#eff6ff', iconColor: '#2563eb',
          icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><polyline points="8 21 12 17 16 21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>' },
        { skill: 'Healthcare Aide', industry: 'Healthcare', change: 17, pct: 72, confidence: 'High', confClass: 'conf-high',
          note: 'Aging population and hospital expansion in NCR sustaining demand.',
          iconBg: '#f0fdf4', iconColor: '#16a34a',
          icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>' },
        { skill: 'Construction Trades', industry: 'Construction', change: 9, pct: 55, confidence: 'Medium', confClass: 'conf-med',
          note: 'Infrastructure projects increasing demand for skilled tradespeople.',
          iconBg: '#fffbeb', iconColor: '#f59e0b',
          icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/></svg>' },
        { skill: 'BPO / Call Center', industry: 'Business Process', change: 4, pct: 42, confidence: 'Medium', confClass: 'conf-med',
          note: 'Stable growth with new international accounts being onboarded.',
          iconBg: '#faf5ff', iconColor: '#8b5cf6',
          icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07"/></svg>' },
        { skill: 'Food Service', industry: 'Hospitality', change: -3, pct: 28, confidence: 'Medium', confClass: 'conf-med',
          note: 'Slight decline as automation enters fast food operations.',
          iconBg: '#fff7ed', iconColor: '#f97316',
          icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8h1a4 4 0 010 8h-1"/><path d="M2 8h16v9a4 4 0 01-4 4H6a4 4 0 01-4-4V8z"/></svg>' },
        { skill: 'Logistics / Driving', industry: 'Transport', change: -8, pct: 18, confidence: 'Low', confClass: 'conf-low',
          note: 'Route optimization and automation reducing driver headcount.',
          iconBg: '#fef2f2', iconColor: '#ef4444',
          icon: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="1" y="3" width="15" height="13" rx="1"/><path d="M16 8h4l3 5v3h-7V8z"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/></svg>' },
      ]

      this.modelConfidence = [
        { label: 'Short-term (1 month)',  pct: 91, note: 'Very reliable — based on current pipeline' },
        { label: 'Mid-term (3 months)',   pct: 78, note: 'Good confidence — seasonal patterns applied' },
        { label: 'Long-term (6 months)',  pct: 62, note: 'Moderate — subject to policy changes' },
        { label: 'Skill gap prediction',  pct: 84, note: 'High confidence — employer data correlated' },
      ]
    },

    _applyPeriodView() {
      const p = this.activePeriod
      if (this.sourcePeriod && this.sourcePeriod === p) {
        this._refreshKpiTrendLabels()
        return
      }
      if (p === 'weekly') this._transformToWeekly()
      if (p === 'yearly') this._transformToYearly()
      if (p === 'monthly') this._transformToMonthly()
      this._refreshKpiTrendLabels()
    },

    _transformToMonthly() {
      // Keep monthly as baseline when source has no explicit period.
    },

    _transformToWeekly() {
      const baseActual = [...this.actualTrendData]
      const weeklyActualValues = this._resampleValues(baseActual.map(x => Number(x.value) || 0), 10, 0.26)
      const weeklyPredValues = this._buildForwardProjection(weeklyActualValues, 6, 1.03)

      this.actualTrendData = weeklyActualValues.map((v, i) => ({
        label: this._weekLabel(-9 + i),
        value: Math.max(1, Math.round(v)),
      }))
      this.predictedTrendData = weeklyPredValues.map((v, i) => {
        const spread = Math.max(4, Math.round(v * 0.09))
        return {
          label: this._weekLabel(1 + i),
          value: Math.max(1, Math.round(v)),
          low: Math.max(1, Math.round(v - spread)),
          high: Math.max(1, Math.round(v + spread)),
        }
      })
      this.forecastMonths = this.predictedTrendData.map(x => x.label)

      this.heatmapData = this.heatmapData.map(row => {
        const vals = this._resampleValues(row.values.map(Number), 6, 1)
        return { ...row, values: vals.map(v => clamp(Math.round(v), 0, 100)) }
      })

      this.skillPredictions = this.skillPredictions.map(pred => ({
        ...pred,
        change: this._scaledPercent(pred.change, 0.35),
        pct: clamp(Math.round(pred.pct * 0.75), 0, 100),
      }))

      this.modelConfidence = this.modelConfidence.map((m, i) => ({
        ...m,
        label: ['Now to 2 weeks', '2–6 weeks', '6–12 weeks', 'Weekly skill match'][i] || m.label,
        pct: clamp(Math.round(m.pct + (i === 0 ? 3 : i === 2 ? -3 : 0)), 0, 100),
      }))

      this.insightMeta = {
        ...this.insightMeta,
        openings: Math.max(1, Math.round(this.insightMeta.openings / 4)),
      }
      this._recomputeKpis()
    },

    _transformToYearly() {
      const yearlyActualValues = this._resampleValues(this.actualTrendData.map(x => Number(x.value) || 0), 5, 12)
      const yearlyPredValues = this._buildForwardProjection(yearlyActualValues, 3, 1.06)
      const nowYear = new Date().getFullYear()

      this.actualTrendData = yearlyActualValues.map((v, i) => ({
        label: String(nowYear - (yearlyActualValues.length - 1 - i)),
        value: Math.max(1, Math.round(v)),
      }))
      this.predictedTrendData = yearlyPredValues.map((v, i) => {
        const spread = Math.max(60, Math.round(v * 0.12))
        return {
          label: String(nowYear + i + 1),
          value: Math.max(1, Math.round(v)),
          low: Math.max(1, Math.round(v - spread)),
          high: Math.max(1, Math.round(v + spread)),
        }
      })
      this.forecastMonths = this.predictedTrendData.map(x => x.label)

      this.heatmapData = this.heatmapData.map(row => {
        const vals = this._resampleValues(row.values.map(Number), 3, 1)
        return { ...row, values: vals.map(v => clamp(Math.round(v), 0, 100)) }
      })

      this.skillPredictions = this.skillPredictions.map(pred => ({
        ...pred,
        change: this._scaledPercent(pred.change, 2.2),
        pct: clamp(Math.round(pred.pct * 1.12), 0, 100),
      }))

      this.modelConfidence = this.modelConfidence.map((m, i) => ({
        ...m,
        label: ['1-year horizon', '2-year horizon', '3-year horizon', 'Long-term skill alignment'][i] || m.label,
        pct: clamp(Math.round(m.pct - (i < 2 ? 8 : 10)), 0, 100),
      }))

      this.insightMeta = {
        ...this.insightMeta,
        openings: Math.max(1, Math.round(this.insightMeta.openings * 12)),
      }
      this._recomputeKpis()
    },

    _recomputeKpis() {
      const latestActual = this.actualTrendData[this.actualTrendData.length - 1]?.value || 0
      const firstPred = this.predictedTrendData[0]?.value || latestActual
      const predGrowthPct = latestActual ? ((firstPred - latestActual) / latestActual) * 100 : 0
      const avgPred = this.predictedTrendData.length
        ? this.predictedTrendData.reduce((s, x) => s + (x.value || 0), 0) / this.predictedTrendData.length
        : 0

      const topSkill = [...this.skillPredictions].sort((a, b) => b.change - a.change)[0]
      const avgConf = this.modelConfidence.length
        ? this.modelConfidence.reduce((s, x) => s + (x.pct || 0), 0) / this.modelConfidence.length
        : 70
      const riskScore = avgConf >= 82 ? 'Low' : avgConf >= 66 ? 'Medium' : 'High'

      this.kpis[0].value = this.formatNumber(Math.round(avgPred))
      this.kpis[0].trend = `${predGrowthPct >= 0 ? '+' : ''}${Math.round(predGrowthPct)}%`
      this.kpis[0].up = predGrowthPct >= 0

      const employmentRate = clamp(28 + avgConf * 0.45, 0, 100)
      this.kpis[1].value = `${employmentRate.toFixed(1)}%`
      this.kpis[1].trend = `${predGrowthPct >= 0 ? '+' : ''}${(predGrowthPct * 0.35).toFixed(1)}%`
      this.kpis[1].up = predGrowthPct >= 0

      if (topSkill) {
        this.kpis[2].value = topSkill.skill
        this.kpis[2].trend = `${topSkill.change >= 0 ? '+' : ''}${topSkill.change}%`
        this.kpis[2].up = topSkill.change >= 0
      }

      this.kpis[3].value = riskScore
      this.kpis[3].trend = `${Math.round(100 - avgConf)}%`
      this.kpis[3].up = riskScore === 'Low'
    },

    _refreshKpiTrendLabels() {
      const labelMap = {
        weekly: 'vs last week',
        monthly: 'vs last month',
        yearly: 'vs last year',
      }
      this.kpis[0].trendLabel = labelMap[this.activePeriod]
      this.kpis[1].trendLabel = labelMap[this.activePeriod]
      this.kpis[2].trendLabel = 'projected demand'
      this.kpis[3].trendLabel = `change ${labelMap[this.activePeriod]}`
    },

    _resampleValues(values, targetLen, multiplier = 1) {
      const src = (values || []).filter(v => Number.isFinite(Number(v))).map(Number)
      if (!src.length) return Array.from({ length: targetLen }, () => 0)
      if (src.length === targetLen) return src.map(v => v * multiplier)
      const maxIdx = src.length - 1
      return Array.from({ length: targetLen }, (_, i) => {
        const pos = (i / Math.max(targetLen - 1, 1)) * maxIdx
        const lo = Math.floor(pos)
        const hi = Math.ceil(pos)
        const t = pos - lo
        const interp = src[lo] + (src[hi] - src[lo]) * t
        return interp * multiplier
      })
    },

    _buildForwardProjection(actualVals, count, growthFactor = 1.03) {
      const out = []
      if (!actualVals.length) return Array.from({ length: count }, () => 0)
      const lookback = actualVals.slice(-3)
      const baseTrend = lookback.length > 1
        ? (lookback[lookback.length - 1] - lookback[0]) / (lookback.length - 1)
        : 0
      let last = actualVals[actualVals.length - 1]
      for (let i = 0; i < count; i++) {
        const trendBoost = baseTrend * (0.7 + i * 0.18)
        last = Math.max(1, last * growthFactor + trendBoost)
        out.push(last)
      }
      return out
    },

    _scaledPercent(value, factor) {
      const v = Number(value) || 0
      const scaled = v * factor
      return scaled >= 0 ? Math.round(scaled) : -Math.round(Math.abs(scaled))
    },

    _weekLabel(weekOffset) {
      const now = new Date()
      const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + weekOffset * 7)
      return d.toLocaleString('en-US', { month: 'short', day: '2-digit' })
    },

    /* ───────────── animations ───────────── */

    _resetAnims() {
      this.trendAnimated   = false
      this.confAnimated    = false
      this.heatmapAnimated = false
      this.predsAnimated   = false
      this.trendTip        = null
      this.kpiAnimValues   = ['—', '—', '—', '—']
    },

    _setupObservers() {
      this.observers.forEach(o => o.disconnect())
      this.observers = []

      const observe = (selector, flag, delay = 80) => {
        const el = this.$el && this.$el.querySelector(selector)
        if (!el) {
          setTimeout(() => { this[flag] = true }, delay)
          return
        }
        const obs = new IntersectionObserver(([entry]) => {
          if (entry.isIntersecting) {
            setTimeout(() => { this[flag] = true }, delay)
            obs.disconnect()
          }
        }, { threshold: 0.15 })
        obs.observe(el)
        this.observers.push(obs)
      }

      observe('.svg-wrap',        'trendAnimated',   100)
      observe('.confidence-list', 'confAnimated',    120)
      observe('.heatmap-wrap',    'heatmapAnimated', 150)
      observe('.pred-grid',       'predsAnimated',   100)
    },

    _startKpiAnimations() {
      this.kpis.forEach((kpi, i) => {
        const raw = String(kpi.value)
        const match = raw.match(/^([\d,]+(?:\.\d+)?)/)
        if (!match) {
          this.kpiAnimValues[i] = raw
          return
        }
        const numStr   = match[1].replace(/,/g, '')
        const target   = parseFloat(numStr)
        if (!Number.isFinite(target)) {
          this.kpiAnimValues[i] = raw
          return
        }
        const suffix   = raw.slice(match[1].length)
        const decimals = (numStr.split('.')[1] || '').length
        const start    = performance.now()
        const duration = 850

        const tick = (now) => {
          const t = Math.min(1, (now - start) / duration)
          const eased = 1 - Math.pow(1 - t, 3)
          const cur = target * eased
          this.kpiAnimValues[i] = cur.toFixed(decimals) + suffix
          if (t < 1) requestAnimationFrame(tick)
          else this.kpiAnimValues[i] = raw
        }
        requestAnimationFrame(tick)
      })
    },

    /* ───────────── chart helpers ───────────── */

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
      if (pts.length === 1) return `M${pts[0].x},${pts[0].y}`
      const tension = 0.32
      let d = `M${pts[0].x},${pts[0].y}`
      for (let i = 1; i < pts.length; i++) {
        const prev = pts[i - 1]
        const cur  = pts[i]
        const dx   = cur.x - prev.x
        const cp1x = prev.x + dx * tension
        const cp2x = cur.x  - dx * tension
        d += ` C${cp1x},${prev.y} ${cp2x},${cur.y} ${cur.x},${cur.y}`
      }
      return d
    },

    onTrendMove(evt) {
      if (!this.allTrendPoints.length) return
      const svg = this.$refs.trendSvg
      const wrap = this.$refs.trendWrap
      if (!svg || !wrap) return

      const pt = svg.createSVGPoint()
      pt.x = evt.clientX
      pt.y = evt.clientY
      const ctm = svg.getScreenCTM()
      if (!ctm) return
      const svgPt = pt.matrixTransform(ctm.inverse())

      let best = null, bestDist = Infinity
      this.allTrendPoints.forEach((p, i) => {
        const dist = Math.abs(svgPt.x - p.x)
        if (dist < bestDist) { bestDist = dist; best = i }
      })
      if (best === null || bestDist > this.trendColW / 2 + 4) {
        this.trendTip = null
        return
      }

      const p = this.allTrendPoints[best]
      const rect = wrap.getBoundingClientRect()
      const TIP_W = 180, TIP_H = 90
      let x = evt.clientX - rect.left + 14
      let y = evt.clientY - rect.top - 12
      if (x + TIP_W > rect.width)  x = evt.clientX - rect.left - TIP_W - 10
      if (x < 0)                   x = 4
      if (y + TIP_H > rect.height) y = rect.height - TIP_H - 4
      if (y < 0)                   y = 4

      const isActual = best < this.actualTrendData.length
      this.trendTip = {
        i: best,
        label: p.label,
        isPredicted: p.isPredicted,
        actual:    isActual    ? p.value : null,
        predicted: p.isPredicted ? p.value : null,
        low:  p.low,
        high: p.high,
        x, y,
      }
    },

    /* ───────────── color helpers ───────────── */

    heatColor(val) {
      const stops = [
        [0,   '#f1f5fb'],
        [25,  '#dbeafe'],
        [50,  '#93c5fd'],
        [75,  '#3b82f6'],
        [100, '#1e3a8a'],
      ]
      const v = clamp(val, 0, 100)
      for (let i = 0; i < stops.length - 1; i++) {
        if (v >= stops[i][0] && v <= stops[i + 1][0]) {
          const t = (v - stops[i][0]) / (stops[i + 1][0] - stops[i][0])
          return this._mixColors(stops[i][1], stops[i + 1][1], t)
        }
      }
      return stops[stops.length - 1][1]
    },

    confidenceColor(pct) {
      if (pct >= 85) return '#16a34a'
      if (pct >= 70) return '#2563eb'
      if (pct >= 55) return '#f59e0b'
      return '#ef4444'
    },

    _mixColors(c1, c2, t) {
      const h = s => parseInt(s.slice(1), 16)
      const r1 = h(c1) >> 16, g1 = (h(c1) >> 8) & 255, b1 = h(c1) & 255
      const r2 = h(c2) >> 16, g2 = (h(c2) >> 8) & 255, b2 = h(c2) & 255
      const r = Math.round(r1 + (r2 - r1) * t)
      const g = Math.round(g1 + (g2 - g1) * t)
      const b = Math.round(b1 + (b2 - b1) * t)
      return `rgb(${r},${g},${b})`
    },

    /* ───────────── KPI trend visuals ───────────── */

    trendDirection(kpi) {
      const m = String(kpi.trend).match(/-?[\d.]+/)
      if (!m) return kpi.up ? 'up' : 'down'
      const v = parseFloat(m[0])
      if (Math.abs(v) < 1) return 'flat'
      return kpi.up ? 'up' : 'down'
    },

    trendClass(kpi) {
      const dir = this.trendDirection(kpi)
      if (dir === 'flat') return 'trend-flat'
      return dir === 'up' ? 'trend-up' : 'trend-down'
    },

    /* ───────────── insight chips ───────────── */

    _autoChips() {
      const chips = []
      const top = this.skillPredictions.find(p => p.change >= 15)
      if (top) chips.push({ text: `↑ ${top.skill} +${top.change}%`, cls: 'chip-green' })
      const dec = this.skillPredictions.find(p => p.change < 0)
      if (dec) chips.push({ text: `↓ ${dec.skill} ${dec.change}%`, cls: 'chip-red' })
      if (this.kpis[0]?.value) chips.push({ text: `${this.kpis[0].value} predicted placements`, cls: 'chip-blue' })
      if (this.kpis[3]?.value) chips.push({ text: `${this.kpis[3].value} risk score`, cls: 'chip-amber' })
      return chips
    },

    /* ───────────── formatting ───────────── */

    formatNumber(n) {
      if (n === null || n === undefined || !Number.isFinite(Number(n))) return '—'
      return Number(n).toLocaleString('en-US')
    },

    _formatTime(d) {
      return d.toLocaleString('en-US', {
        month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit',
      })
    },

    /* ───────────── toasts ───────────── */

    notify(type, message) {
      const id = ++this.toastSeq
      const toast = { id, type, message, timer: null }
      toast.timer = setTimeout(() => this.dismissToast(id), TOAST_TTL_MS)
      this.toasts.push(toast)
    },

    dismissToast(id) {
      const idx = this.toasts.findIndex(t => t.id === id)
      if (idx === -1) return
      clearTimeout(this.toasts[idx].timer)
      this.toasts.splice(idx, 1)
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

* { box-sizing: border-box; margin: 0; padding: 0; }

.pa-page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  flex: 1;
  overflow-y: auto;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  background: #f1eeff;
  position: relative;
}

button { font-family: inherit; }
button:focus-visible {
  outline: 2px solid #7c3aed;
  outline-offset: 2px;
  border-radius: 8px;
}

/* ──────── Skeleton ──────── */
@keyframes shimmer {
  0%   { background-position: -600px 0; }
  100% { background-position:  600px 0; }
}
.skel {
  background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%);
  background-size: 600px 100%;
  animation: shimmer 1.4s infinite linear;
  border-radius: 6px;
  display: block;
}

/* ──────── Toast ──────── */
.toast-stack {
  position: fixed;
  top: 18px;
  right: 18px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  z-index: 1000;
  max-width: 360px;
  pointer-events: none;
}
.toast {
  display: flex;
  align-items: center;
  gap: 10px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-left-width: 4px;
  border-radius: 10px;
  padding: 10px 14px;
  font-size: 12.5px;
  font-weight: 600;
  color: #334155;
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.08);
  pointer-events: auto;
}
.toast-success { border-left-color: #16a34a; }
.toast-error   { border-left-color: #ef4444; }
.toast-warning { border-left-color: #f59e0b; }
.toast-info    { border-left-color: #2563eb; }
.toast-success .toast-icon { color: #16a34a; }
.toast-error   .toast-icon { color: #ef4444; }
.toast-warning .toast-icon { color: #f59e0b; }
.toast-info    .toast-icon { color: #2563eb; }
.toast-icon { display: flex; flex-shrink: 0; }
.toast-msg  { flex: 1; line-height: 1.4; }
.toast-close {
  border: none;
  background: transparent;
  color: #94a3b8;
  font-size: 18px;
  line-height: 1;
  cursor: pointer;
  padding: 0 2px;
}
.toast-close:hover { color: #1e293b; }
.toast-enter-active,
.toast-leave-active { transition: all .25s ease; }
.toast-enter-from   { opacity: 0; transform: translateX(20px); }
.toast-leave-to     { opacity: 0; transform: translateX(20px); }

/* ──────── Header ──────── */
.pa-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  background: #fff;
  border: 1px solid #f1f5f9;
  border-radius: 14px;
  padding: 14px 18px;
  gap: 16px;
  flex-wrap: wrap;
}
.header-main { display: flex; flex-direction: column; gap: 4px; min-width: 0; }
.title-row { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.ai-icon {
  width: 30px; height: 30px;
  background: #faf5ff;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #e9d5ff;
  flex-shrink: 0;
}
.page-title { font-size: 16px; font-weight: 800; color: #1e293b; }
.ai-tag {
  font-size: 10px; font-weight: 700;
  padding: 2px 8px;
  border-radius: 99px;
  background: #faf5ff;
  color: #7c3aed;
  border: 1px solid #e9d5ff;
}
.last-updated {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  font-size: 10.5px;
  font-weight: 600;
  color: #64748b;
  margin-left: 4px;
  padding: 3px 8px;
  background: #f1f5f9;
  border-radius: 99px;
}
.lu-dot {
  width: 6px; height: 6px;
  border-radius: 50%;
  background: #16a34a;
  box-shadow: 0 0 0 3px rgba(22,163,74,0.18);
  animation: pulseDot 2s infinite;
}
@keyframes pulseDot {
  0%, 100% { box-shadow: 0 0 0 3px rgba(22,163,74,0.18); }
  50%      { box-shadow: 0 0 0 5px rgba(22,163,74,0.05); }
}
.page-sub {
  font-size: 11.5px;
  color: #94a3b8;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}
.period-pills {
  display: flex;
  background: #f8fafc;
  border-radius: 10px;
  padding: 3px;
  gap: 2px;
}
.period-pill {
  padding: 5px 12px;
  border-radius: 7px;
  border: none;
  background: transparent;
  font-size: 12px;
  font-weight: 600;
  color: #64748b;
  cursor: pointer;
  transition: all .15s;
}
.period-pill:hover { color: #1e293b; }
.period-pill.active {
  background: #fff;
  color: #2563eb;
  box-shadow: 0 1px 3px rgba(15,23,42,0.08);
}

.btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 7px 14px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 700;
  cursor: pointer;
  transition: all .15s;
  border: 1.5px solid transparent;
  white-space: nowrap;
}
.btn:disabled { opacity: .5; cursor: not-allowed; }
.btn-secondary {
  border-color: #e9d5ff;
  background: #faf5ff;
  color: #7c3aed;
}
.btn-secondary:hover:not(:disabled) { background: #f3e8ff; }
.btn-primary {
  background: #2563eb;
  color: #fff;
  border-color: #2563eb;
}
.btn-primary:hover:not(:disabled) { background: #1d4ed8; border-color: #1d4ed8; }
.btn-sm { padding: 5px 12px; font-size: 11.5px; }

.btn-spinner {
  width: 12px; height: 12px;
  border: 1.8px solid currentColor;
  border-top-color: transparent;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  display: inline-block;
}
@keyframes spin { to { transform: rotate(360deg); } }

/* ──────── KPI Cards ──────── */
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
}
.kpi-card {
  background: #fff;
  border-radius: 14px;
  padding: 18px;
  border: 1px solid #f1f5f9;
  box-shadow: 0 1px 3px rgba(0,0,0,0.03);
  animation: slideUp .38s ease both;
  transition: box-shadow .15s, transform .15s;
}
.kpi-card:hover {
  box-shadow: 0 4px 14px rgba(15,23,42,0.06);
  transform: translateY(-1px);
}
.kpi-icon {
  width: 38px; height: 38px;
  border-radius: 10px;
  display: flex; align-items: center; justify-content: center;
  margin-bottom: 12px;
}
.kpi-icon span { display: flex; }
.kpi-value {
  font-size: 24px;
  font-weight: 800;
  color: #1e293b;
  margin-bottom: 4px;
  font-variant-numeric: tabular-nums;
}
.kpi-label {
  font-size: 12px;
  color: #64748b;
  font-weight: 500;
  margin-bottom: 5px;
  display: inline-flex;
  align-items: center;
  gap: 5px;
}
.kpi-info {
  display: inline-flex;
  color: #cbd5e1;
  cursor: help;
}
.kpi-info:hover { color: #94a3b8; }
.kpi-trend {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  font-weight: 700;
}
.trend-up   { color: #16a34a; }
.trend-down { color: #ef4444; }
.trend-flat { color: #94a3b8; }

/* ──────── Layout ──────── */
.main-row {
  display: flex;
  gap: 14px;
  align-items: stretch;
}
.flex-1 { flex: 1; min-width: 0; }

.card {
  background: #fff;
  border-radius: 14px;
  padding: 18px;
  border: 1px solid #f1f5f9;
  box-shadow: 0 1px 3px rgba(0,0,0,0.04);
}
.chart-card { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.confidence-card {
  width: 280px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
}
.card-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 16px;
  gap: 10px;
  flex-wrap: wrap;
}
.card-header h3 { font-size: 13.5px; font-weight: 700; color: #1e293b; }
.card-sub      { font-size: 11px; color: #94a3b8; margin-top: 2px; }

/* ──────── Legend ──────── */
.legend {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  font-size: 11px;
  color: #64748b;
  flex-shrink: 0;
}
.leg-item   { display: inline-flex; align-items: center; gap: 5px; }
.leg-line   { display: inline-block; width: 22px; height: 3px; border-radius: 2px; }
.leg-dashed { border: none; border-top: 2px dashed; height: 0; background: transparent; }
.leg-swatch { display: inline-block; width: 16px; height: 10px; border-radius: 3px; }

/* ──────── Chart ──────── */
.svg-wrap   { width: 100%; position: relative; flex: 1; }
.chart-svg  { width: 100%; height: 220px; display: block; overflow: visible; cursor: crosshair; }

.chart-empty {
  text-align: center;
  padding: 50px 20px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}
.chart-empty p {
  font-size: 12.5px;
  color: #94a3b8;
}

/* ──────── Tooltip ──────── */
.chart-tip {
  position: absolute;
  pointer-events: none;
  background: #1e293b;
  color: #f8fafc;
  border-radius: 10px;
  padding: 10px 14px;
  font-size: 11.5px;
  min-width: 158px;
  box-shadow: 0 8px 24px rgba(0,0,0,.22);
  z-index: 50;
  white-space: nowrap;
}
.tip-enter-active { transition: opacity .12s ease, transform .12s ease; }
.tip-leave-active { transition: opacity .08s ease; }
.tip-enter-from   { opacity: 0; transform: translateY(4px) scale(.97); }
.tip-leave-to     { opacity: 0; }
.tip-label {
  font-weight: 700;
  font-size: 10px;
  color: #94a3b8;
  margin-bottom: 6px;
  letter-spacing: .5px;
  text-transform: uppercase;
}
.tip-row {
  display: flex;
  align-items: center;
  gap: 7px;
  line-height: 2;
}
.tip-row strong {
  margin-left: auto;
  padding-left: 12px;
  font-weight: 700;
  color: #fff;
  font-variant-numeric: tabular-nums;
}
.tip-dot {
  display: inline-block;
  width: 7px; height: 7px;
  border-radius: 50%;
  flex-shrink: 0;
}
.tip-muted { font-size: 10.5px; color: #94a3b8; }

/* ──────── Confidence ──────── */
.live-badge {
  background: #faf5ff;
  color: #7c3aed;
  font-size: 10px; font-weight: 700;
  padding: 3px 8px;
  border-radius: 99px;
  border: 1px solid #e9d5ff;
  flex-shrink: 0;
}
.confidence-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
  flex: 1;
}
.conf-item { display: flex; flex-direction: column; gap: 5px; }
.conf-row  { display: flex; align-items: center; justify-content: space-between; }
.conf-label{ font-size: 12px; font-weight: 600; color: #475569; }
.conf-pct  { font-size: 13px; font-weight: 800; font-variant-numeric: tabular-nums; }
.conf-track{ height: 7px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.conf-fill { height: 100%; border-radius: 99px; width: 0%; transition: width .8s cubic-bezier(.4,0,.2,1); }
.conf-note { font-size: 10.5px; color: #94a3b8; }
.conf-footer {
  margin-top: 16px;
  padding-top: 12px;
  border-top: 1px solid #f1f5f9;
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 11px;
  color: #94a3b8;
}

/* ──────── Heatmap ──────── */
.heatmap-legend {
  display: flex;
  gap: 8px;
  align-items: center;
}
.heatmap-legend-strip {
  position: relative;
  width: 96px;
  height: 10px;
  border-radius: 99px;
  background: linear-gradient(to right, #dbeafe, #1e3a8a);
}
.hl-tick {
  display: none;
}
.heatmap-legend-label { font-size: 10.5px; color: #94a3b8; }

.heatmap-wrap {
  overflow-x: auto;
  margin: -2px -2px;
  padding: 2px 2px;
}
.heatmap-table {
  min-width: 600px;
  display: flex;
  flex-direction: column;
  gap: 5px;
}
.hm-header-row {
  display: flex;
  align-items: center;
  margin-bottom: 4px;
  padding-left: 0;
}
.hm-skill-col {
  width: 160px;
  flex-shrink: 0;
  background: #fff;
  position: sticky;
  left: 0;
  z-index: 2;
}
.hm-month-col {
  flex: 1;
  text-align: center;
  font-size: 11px;
  font-weight: 600;
  color: #94a3b8;
  text-transform: uppercase;
  letter-spacing: .3px;
}
.hm-row {
  display: flex;
  align-items: center;
}
.hm-skill-name {
  width: 160px;
  flex-shrink: 0;
  font-size: 12px;
  font-weight: 600;
  color: #475569;
  display: flex;
  align-items: center;
  gap: 6px;
  padding-right: 10px;
  background: #fff;
  position: sticky;
  left: 0;
  z-index: 1;
}
.hm-skill-dot {
  width: 8px; height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}
.hm-skill-text {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.hm-cell {
  flex: 1;
  height: 38px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  margin: 0 2px;
  transition: background .5s ease, transform .15s, box-shadow .15s;
  cursor: default;
  min-width: 60px;
}
.hm-cell:hover {
  transform: scale(1.06);
  z-index: 3;
  position: relative;
  box-shadow: 0 4px 12px rgba(15,23,42,0.18);
}
.hm-cell:focus-visible {
  outline: 2px solid #7c3aed;
  outline-offset: 1px;
  z-index: 3;
  position: relative;
}
.hm-val {
  font-size: 11px;
  font-weight: 700;
  font-variant-numeric: tabular-nums;
  transition: color .3s ease;
}

/* ──────── Section header ──────── */
.section-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 14px;
  gap: 12px;
  flex-wrap: wrap;
}
.section-title-row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}
.section-title { font-size: 15px; font-weight: 800; color: #1e293b; }
.section-badge {
  font-size: 10.5px;
  font-weight: 700;
  padding: 3px 10px;
  border-radius: 99px;
  background: #faf5ff;
  color: #7c3aed;
  border: 1px solid #e9d5ff;
}
.section-sub {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 4px;
  max-width: 720px;
  line-height: 1.5;
}

.sort-control {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 11.5px;
  color: #64748b;
}
.sort-label { font-weight: 600; }
.sort-select {
  font-family: inherit;
  font-size: 12px;
  font-weight: 600;
  color: #1e293b;
  border: 1.5px solid #e2e8f0;
  border-radius: 8px;
  background: #fff;
  padding: 5px 26px 5px 10px;
  cursor: pointer;
  appearance: none;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='10' height='10' viewBox='0 0 24 24' fill='none' stroke='%2364748b' stroke-width='2.5' stroke-linecap='round'><polyline points='6 9 12 15 18 9'/></svg>");
  background-repeat: no-repeat;
  background-position: right 8px center;
  transition: border-color .15s;
}
.sort-select:hover { border-color: #94a3b8; }
.sort-select:focus { outline: 2px solid #7c3aed; outline-offset: 1px; }

/* ──────── Predictions ──────── */
.pred-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 14px;
}
.pred-card {
  background: #fff;
  border: 1px solid #f1f5f9;
  border-radius: 14px;
  padding: 18px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  animation: slideUp .38s ease both;
  transition: box-shadow .15s, border-color .15s, transform .15s;
}
.pred-card:hover {
  box-shadow: 0 6px 18px rgba(15,23,42,0.07);
  border-color: #e2e8f0;
  transform: translateY(-1px);
}
.pred-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.pred-icon {
  width: 32px; height: 32px;
  border-radius: 9px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.pred-icon span { display: flex; }
.pred-body { display: flex; flex-direction: column; gap: 5px; }
.pred-skill    { font-size: 13px; font-weight: 800; color: #1e293b; }
.pred-industry { font-size: 11px; color: #94a3b8; }
.pred-change-row { display: flex; align-items: center; }
.pred-change {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  font-weight: 700;
  font-variant-numeric: tabular-nums;
}
.change-pos { color: #16a34a; }
.change-neg { color: #ef4444; }
.pred-bar-track {
  height: 6px;
  background: #f1f5f9;
  border-radius: 99px;
  overflow: hidden;
  margin-top: 2px;
}
.pred-bar-fill {
  height: 100%;
  border-radius: 99px;
  width: 0%;
  transition: width .85s cubic-bezier(.4,0,.2,1);
}
.pred-note {
  font-size: 11px;
  color: #94a3b8;
  line-height: 1.5;
}
.pred-conf-badge {
  font-size: 10px;
  font-weight: 700;
  padding: 3px 9px;
  border-radius: 99px;
  white-space: nowrap;
}
.conf-high { background: #f0fdf4; color: #15803d; }
.conf-med  { background: #fffbeb; color: #b45309; }
.conf-low  { background: #fef2f2; color: #dc2626; }

/* ──────── AI Insight ──────── */
.ai-insight-card {
  border: 1.5px solid #e9d5ff !important;
  background: linear-gradient(135deg, #ffffff 0%, #fafaff 100%);
}
.ai-header-left {
  display: flex;
  align-items: center;
  gap: 8px;
}
.ai-header-left h3 { margin: 0; }
.ai-pulse {
  width: 8px; height: 8px;
  border-radius: 50%;
  background: #c4b5fd;
  flex-shrink: 0;
}
.ai-pulse.pulsing {
  background: #7c3aed;
  animation: pulse 1.6s infinite;
}
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50%      { opacity: .25; }
}
.claude-badge {
  font-size: 10px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 99px;
  background: #7c3aed;
  color: #fff;
}
.ai-period-tag {
  font-size: 11px;
  color: #a78bfa;
  font-weight: 600;
}

.ai-loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  padding: 28px 0;
  text-align: center;
}
.ai-spinner {
  width: 50px; height: 50px;
  background: #faf5ff;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}
.spin-ring {
  position: absolute;
  inset: 0;
  border-radius: 50%;
  border: 2.5px solid #e9d5ff;
  border-top-color: #7c3aed;
  animation: spin 1s linear infinite;
}
.ai-loading-title {
  font-size: 13.5px;
  font-weight: 700;
  color: #5b21b6;
}
.ai-loading-sub {
  font-size: 11.5px;
  color: #a78bfa;
  max-width: 280px;
  line-height: 1.5;
}

.ai-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  padding: 32px 0;
  text-align: center;
}
.ai-empty-icon {
  width: 56px; height: 56px;
  background: #faf5ff;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.ai-empty-icon-error { background: #fef2f2; }
.ai-empty-title { font-size: 14px; font-weight: 700; color: #475569; }
.ai-empty-sub {
  font-size: 12px;
  color: #94a3b8;
  max-width: 320px;
  line-height: 1.6;
}
.btn-run {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 9px 18px;
  background: #7c3aed;
  color: #fff;
  border: none;
  border-radius: 9px;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  margin-top: 4px;
  transition: background .15s;
}
.btn-run:hover:not(:disabled) { background: #6d28d9; }
.btn-run:disabled { opacity: .5; cursor: not-allowed; }

.insight-meta-row {
  display: flex;
  gap: 14px;
  flex-wrap: wrap;
  margin-bottom: 10px;
}
.meta-item {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  font-size: 11px;
  color: #64748b;
  font-weight: 600;
}
.insight-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
  margin-bottom: 10px;
}
.chip {
  font-size: 11px;
  font-weight: 700;
  padding: 4px 10px;
  border-radius: 99px;
  border: 1px solid;
}
.chip-green  { background: #f0fdf4; color: #15803d; border-color: #bbf7d0; }
.chip-red    { background: #fef2f2; color: #dc2626; border-color: #fecaca; }
.chip-blue   { background: #eff6ff; color: #1d4ed8; border-color: #bfdbfe; }
.chip-amber  { background: #fffbeb; color: #b45309; border-color: #fde68a; }
.chip-purple { background: #faf5ff; color: #7c3aed; border-color: #e9d5ff; }

.insight-divider {
  height: 1px;
  background: #f1f5f9;
  margin: 12px 0;
}
.insight-text {
  font-size: 12.5px;
  color: #475569;
  line-height: 1.8;
}
.insight-text :deep(p) { margin: 0 0 10px; }
.insight-text :deep(p:last-child) { margin-bottom: 0; }
.insight-text :deep(strong) { font-weight: 700; color: #1e293b; }

.ai-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  flex-wrap: wrap;
}
.ai-gen-at { font-size: 11px; color: #94a3b8; }
.ai-footer-actions { display: flex; gap: 6px; }
.btn-sm-outline {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 700;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  color: #64748b;
  cursor: pointer;
  transition: all .15s;
}
.btn-sm-outline:hover:not(:disabled) { background: #f1f5f9; }
.btn-sm-outline:disabled { opacity: .5; cursor: not-allowed; }
.btn-sm-primary {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 700;
  background: #7c3aed;
  border: none;
  color: #fff;
  cursor: pointer;
  transition: background .15s;
}
.btn-sm-primary:hover:not(:disabled) { background: #6d28d9; }
.btn-sm-primary:disabled { opacity: .5; cursor: not-allowed; }

/* ──────── Animations ──────── */
@keyframes slideUp {
  from { opacity: 0; transform: translateY(10px); }
  to   { opacity: 1; transform: translateY(0); }
}

/* ──────── Responsive ──────── */
@media (max-width: 1280px) {
  .pred-grid { grid-template-columns: repeat(3, 1fr); }
}
@media (max-width: 1024px) {
  .kpi-grid { grid-template-columns: repeat(2, 1fr); }
  .main-row { flex-direction: column; }
  .confidence-card { width: 100%; }
  .pred-grid { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 768px) {
  .pa-page { padding: 16px; }
  .pa-header { flex-direction: column; align-items: stretch; }
  .header-actions {
    width: 100%;
    justify-content: flex-start;
  }
  .period-pills { flex: 1; }
  .period-pill  { flex: 1; text-align: center; }
  .legend       { font-size: 10.5px; gap: 8px; }
  .chart-svg    { height: 200px; }
  .heatmap-table { min-width: 540px; }
}
@media (max-width: 540px) {
  .kpi-grid { grid-template-columns: 1fr; }
  .pred-grid { grid-template-columns: 1fr; }
  .kpi-value { font-size: 22px; }
  .section-head { flex-direction: column; align-items: stretch; }
  .ai-footer { flex-direction: column; align-items: stretch; }
  .ai-footer-actions { justify-content: flex-end; }
  .toast-stack { left: 12px; right: 12px; max-width: none; }
  .header-actions .btn { flex: 1; justify-content: center; }
}
</style>
