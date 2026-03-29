<template>
  <div class="dashboard-page">

    <!-- ── PERIOD FILTER BAR ──────────────────────────────────────── -->
    <div class="period-bar">
      <template v-if="loading">
        <div style="display:flex; gap:8px;">
          <div class="skel" style="width: 80px; height: 34px; border-radius: 99px;"></div>
          <div class="skel" style="width: 80px; height: 34px; border-radius: 99px;"></div>
          <div class="skel" style="width: 80px; height: 34px; border-radius: 99px;"></div>
          <div class="skel" style="width: 80px; height: 34px; border-radius: 99px;"></div>
        </div>
        <div class="skel" style="width: 140px; height: 14px; border-radius: 4px;"></div>
      </template>
      <template v-else>
        <div class="period-pills">
          <button
            v-for="p in periodOptions" :key="p.value"
            :class="['period-pill', { active: activePeriod === p.value }]"
            @click="setPeriod(p.value)"
          >{{ p.label }}</button>
        </div>

        <!-- Custom date range -->
        <transition name="fade-slide">
          <div v-if="activePeriod === 'custom'" class="custom-range">
            <input type="date" v-model="customFrom" class="date-input" :max="customTo || undefined"/>
            <span class="date-sep">→</span>
            <input type="date" v-model="customTo"   class="date-input" :min="customFrom || undefined"/>
            <button class="apply-btn" :disabled="!customFrom || !customTo" @click="applyCustom">Apply</button>
          </div>
        </transition>

        <span v-if="lastUpdated" class="last-updated">Updated {{ lastUpdated }}</span>
      </template>
    </div>

    <!-- SKELETON -->
    <template v-if="loading">
      <!-- Stat Cards Skeleton -->
      <div class="stats-grid">
        <div v-for="i in 4" :key="i" class="stat-card">
          <div class="stat-top">
            <div class="skel skel-icon"></div>
            <div class="skel skel-badge"></div>
          </div>
          <div class="skel skel-val"></div>
          <div class="skel skel-label"></div>
          <div class="skel skel-sub"></div>
        </div>
      </div>

      <!-- Charts Row Skeleton -->
      <div class="mid-row">
        <div class="card">
          <div class="skel-card-header">
            <div class="skel skel-title"></div>
            <div class="skel skel-legend"></div>
          </div>
          <div class="skel skel-chart"></div>
          <div class="skel-summary-row">
            <div class="skel skel-summary-item"></div>
            <div class="skel skel-summary-item"></div>
            <div class="skel skel-summary-item"></div>
          </div>
        </div>
        <div class="card side-card">
          <div class="skel skel-title" style="margin-bottom:16px"></div>
          <div class="skel skel-donut"></div>
          <div v-for="i in 4" :key="i" style="display:flex;justify-content:space-between;margin-top:12px">
            <div class="skel" style="width:100px;height:12px;border-radius:6px"></div>
            <div class="skel" style="width:36px;height:12px;border-radius:6px"></div>
          </div>
        </div>
      </div>

      <!-- Second Charts Row Skeleton -->
      <div class="mid-row">
        <div class="card">
          <div class="skel-card-header">
            <div class="skel skel-title"></div>
            <div class="skel skel-legend"></div>
          </div>
          <div class="skel skel-chart"></div>
          <div class="skel-summary-row">
            <div class="skel skel-summary-item" v-for="i in 4" :key="i"></div>
          </div>
        </div>
        <div class="card side-card">
          <div class="skel skel-title" style="margin-bottom:16px"></div>
          <div v-for="i in 6" :key="i" class="skel-tjob-row">
            <div class="skel" style="width:18px;height:12px;border-radius:4px"></div>
            <div class="skel" style="width:28px;height:28px;border-radius:7px;flex-shrink:0"></div>
            <div style="flex:1;display:flex;flex-direction:column;gap:5px">
              <div class="skel" style="width:80%;height:11px;border-radius:4px"></div>
              <div class="skel" style="width:55%;height:10px;border-radius:4px"></div>
            </div>
            <div style="display:flex;flex-direction:column;gap:4px;align-items:flex-end">
              <div class="skel" style="width:48px;height:11px;border-radius:4px"></div>
              <div class="skel" style="width:36px;height:10px;border-radius:4px"></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Skills + Gap Skeleton -->
      <div class="skills-gap-row">
        <div class="card">
          <div class="skel skel-title" style="margin-bottom:16px"></div>
          <div v-for="i in 6" :key="i" class="skel-skill-row">
            <div class="skel" style="width:14px;height:12px;border-radius:4px;flex-shrink:0"></div>
            <div style="flex:1;display:flex;flex-direction:column;gap:6px">
              <div style="display:flex;justify-content:space-between">
                <div class="skel" style="width:90px;height:12px;border-radius:4px"></div>
                <div class="skel" style="width:60px;height:12px;border-radius:4px"></div>
              </div>
              <div class="skel" style="width:100%;height:7px;border-radius:99px"></div>
            </div>
            <div class="skel" style="width:42px;height:20px;border-radius:6px;flex-shrink:0"></div>
          </div>
        </div>
        <div class="card">
          <div class="skel skel-title" style="margin-bottom:16px"></div>
          <div v-for="i in 6" :key="i" class="skel-gap-row">
            <div class="skel" style="width:110px;height:12px;border-radius:4px;flex-shrink:0"></div>
            <div style="flex:1;display:flex;flex-direction:column;gap:5px">
              <div class="skel" style="width:85%;height:6px;border-radius:99px"></div>
              <div class="skel" style="width:60%;height:6px;border-radius:99px"></div>
            </div>
            <div class="skel" style="width:36px;height:12px;border-radius:4px;flex-shrink:0"></div>
          </div>
        </div>
      </div>

      <!-- Bottom Row Skeleton -->
      <div class="bottom-row">
        <div class="card table-card">
          <div class="skel-card-header">
            <div class="skel skel-title"></div>
            <div class="skel" style="width:50px;height:14px;border-radius:6px"></div>
          </div>
          <div v-for="i in 5" :key="i" class="skel-table-row">
            <div style="display:flex;align-items:center;gap:8px;flex:1">
              <div class="skel" style="width:28px;height:28px;border-radius:50%;flex-shrink:0"></div>
              <div style="display:flex;flex-direction:column;gap:5px">
                <div class="skel" style="width:100px;height:12px;border-radius:4px"></div>
                <div class="skel" style="width:70px;height:10px;border-radius:4px"></div>
              </div>
            </div>
            <div class="skel" style="width:60px;height:22px;border-radius:6px"></div>
            <div class="skel" style="width:90px;height:12px;border-radius:4px"></div>
            <div class="skel" style="width:60px;height:12px;border-radius:4px"></div>
            <div class="skel" style="width:70px;height:22px;border-radius:99px"></div>
          </div>
        </div>

        <div class="right-col">
          <div class="card events-card">
            <div class="skel-card-header">
              <div class="skel skel-title"></div>
              <div class="skel" style="width:50px;height:14px;border-radius:6px"></div>
            </div>
            <div v-for="i in 4" :key="i" class="skel-event-row">
              <div class="skel" style="width:40px;height:44px;border-radius:10px;flex-shrink:0"></div>
              <div style="flex:1;display:flex;flex-direction:column;gap:6px">
                <div class="skel" style="width:85%;height:12px;border-radius:4px"></div>
                <div class="skel" style="width:60%;height:10px;border-radius:4px"></div>
              </div>
              <div class="skel" style="width:56px;height:22px;border-radius:6px;flex-shrink:0"></div>
            </div>
          </div>
          <div class="card employers-card">
            <div class="skel-card-header">
              <div class="skel skel-title"></div>
              <div class="skel" style="width:50px;height:14px;border-radius:6px"></div>
            </div>
            <div v-for="i in 4" :key="i" class="skel-emp-row">
              <div class="skel" style="width:16px;height:12px;border-radius:4px;flex-shrink:0"></div>
              <div class="skel" style="width:32px;height:32px;border-radius:8px;flex-shrink:0"></div>
              <div style="flex:1;display:flex;flex-direction:column;gap:5px">
                <div class="skel" style="width:90px;height:12px;border-radius:4px"></div>
                <div class="skel" style="width:65px;height:10px;border-radius:4px"></div>
              </div>
              <div class="skel" style="width:52px;height:22px;border-radius:6px;flex-shrink:0"></div>
            </div>
          </div>
        </div>
      </div>
    </template>

    <!-- ACTUAL CONTENT -->
    <template v-else>

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
          <h2 class="stat-value" :class="{ 'zero': stat.value === '0' || stat.value === 0 }">
            {{ stat.value }}
          </h2>
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
              <p class="card-sub">{{ chartSubLabel }}</p>
            </div>
            <div class="legend">
              <span class="legend-item"><span class="legend-line blue"></span> Jobseekers</span>
              <span class="legend-item"><span class="legend-line cyan"></span> Employers</span>
            </div>
          </div>

          <div v-if="!hasRegData" class="empty-state">
            <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
              <rect x="8" y="40" width="10" height="20" rx="3" fill="#e2e8f0"/>
              <rect x="22" y="28" width="10" height="32" rx="3" fill="#e2e8f0"/>
              <rect x="36" y="34" width="10" height="26" rx="3" fill="#e2e8f0"/>
              <rect x="50" y="20" width="10" height="40" rx="3" fill="#e2e8f0"/>
              <path d="M6 56h52" stroke="#cbd5e1" stroke-width="2" stroke-linecap="round"/>
              <circle cx="46" cy="12" r="8" fill="#f1f5f9" stroke="#e2e8f0" stroke-width="1.5"/>
              <path d="M43 12h6M46 9v6" stroke="#cbd5e1" stroke-width="1.5" stroke-linecap="round"/>
            </svg>
            <p class="empty-title">No registration data yet</p>
            <p class="empty-sub">Data will appear once jobseekers and employers start registering</p>
          </div>
          <div v-else class="svg-chart-wrap" ref="regWrap" data-animate="reg">
            <transition name="tip">
              <div v-if="regTip" class="chart-tooltip" :style="{ left: regTip.x+'px', top: regTip.y+'px' }">
                <div class="tooltip-label">{{ regTip.label }}</div>
                <div class="tooltip-row"><span class="tooltip-dot" style="background:#2563eb"></span>Jobseekers<strong>{{ regTip.jobseekers }}</strong></div>
                <div class="tooltip-row"><span class="tooltip-dot" style="background:#06b6d4"></span>Employers<strong>{{ regTip.employers }}</strong></div>
              </div>
            </transition>

            <svg ref="regSvg"
                 viewBox="0 0 620 180" preserveAspectRatio="xMidYMid meet" class="svg-chart"
                 @mousemove="onRegMove" @mouseleave="regTip = null">
              <defs>
                <linearGradient id="gradBlue" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stop-color="#2563eb" stop-opacity="0.18"/>
                  <stop offset="100%" stop-color="#2563eb" stop-opacity="0"/>
                </linearGradient>
                <linearGradient id="gradCyan" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stop-color="#06b6d4" stop-opacity="0.15"/>
                  <stop offset="100%" stop-color="#06b6d4" stop-opacity="0"/>
                </linearGradient>
                <clipPath id="regClip">
                  <rect x="50" y="0" height="160"
                        :width="regAnimated ? 560 : 0"
                        :style="{ transition: 'width 1.2s cubic-bezier(.4,0,.2,1)' }"/>
                </clipPath>
              </defs>

              <line v-for="(gl,i) in dynamicGridLines" :key="'g'+i"
                    :x1="50" :y1="gl.y" :x2="610" :y2="gl.y" stroke="#f1f5f9" stroke-width="1"/>
              <text v-for="(gl,i) in dynamicGridLines" :key="'yl'+i"
                    :x="44" :y="gl.y+4" text-anchor="end" font-size="9"
                    fill="#cbd5e1" font-family="Plus Jakarta Sans, sans-serif">{{ gl.label }}</text>

              <g clip-path="url(#regClip)">
                <path :d="jobseekerArea" fill="url(#gradBlue)"/>
                <path :d="employerArea"  fill="url(#gradCyan)"/>
                <path :d="jobseekerLine" fill="none" stroke="#2563eb" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                <path :d="employerLine"  fill="none" stroke="#06b6d4" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
              </g>

              <line v-if="regTip"
                    :x1="getX(regTip.i)" y1="14" :x2="getX(regTip.i)" y2="158"
                    stroke="#1e293b" stroke-width="1" stroke-dasharray="3 3" pointer-events="none" opacity="0.35"/>

              <circle v-for="(pt,i) in jobseekerPoints" :key="'jd'+i"
                      :cx="pt.x" :cy="pt.y"
                      :r="regTip && regTip.i === i ? 5.5 : 3.5"
                      fill="#fff" stroke="#2563eb" stroke-width="2"
                      pointer-events="none"
                      style="transition: r 0.12s ease"/>
              <circle v-for="(pt,i) in employerPoints" :key="'ed'+i"
                      :cx="pt.x" :cy="pt.y"
                      :r="regTip && regTip.i === i ? 5.5 : 3.5"
                      fill="#fff" stroke="#06b6d4" stroke-width="2"
                      pointer-events="none"
                      style="transition: r 0.12s ease"/>

              <text v-for="(m,i) in chartData" :key="'xl'+i"
                    :x="getX(i)" :y="173" text-anchor="middle" font-size="9"
                    fill="#94a3b8" font-family="Plus Jakarta Sans, sans-serif">{{ m.label }}</text>

              <rect v-for="(m,i) in chartData" :key="'hit'+i"
                    :x="getX(i) - 560/Math.max(chartData.length-1,1)/2"
                    y="0" :width="560/Math.max(chartData.length-1,1)" height="165"
                    fill="transparent" style="cursor:crosshair"/>
            </svg>
          </div>

          <div v-if="hasRegData" class="chart-summary">
            <div class="summary-item"><span class="summary-dot blue-dot"></span><span class="summary-label">Total Jobseekers</span><span class="summary-val blue-val">{{ totalJobseekers.toLocaleString() }}</span></div>
            <div class="summary-divider"></div>
            <div class="summary-item"><span class="summary-dot cyan-dot"></span><span class="summary-label">Total Employers</span><span class="summary-val cyan-val">{{ totalEmployers.toLocaleString() }}</span></div>
            <div class="summary-divider"></div>
            <div class="summary-item"><span class="summary-label">Peak</span><span class="summary-val">{{ peakMonth }}</span></div>
          </div>
        </div>

        <div class="card side-card">
          <div class="card-header">
            <div><h3>Placement Rate</h3><p class="card-sub">{{ chartSubLabel }}</p></div>
          </div>
          <div v-if="!hasPlacementData" class="empty-state">
            <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
              <circle cx="32" cy="32" r="24" fill="none" stroke="#e2e8f0" stroke-width="8"/>
              <circle cx="46" cy="10" r="8" fill="#f1f5f9" stroke="#e2e8f0" stroke-width="1.5"/>
              <path d="M43 10h6M46 7v6" stroke="#cbd5e1" stroke-width="1.5" stroke-linecap="round"/>
            </svg>
            <p class="empty-title">No placement data yet</p>
            <p class="empty-sub">Rate will show once applications are processed</p>
          </div>
          <template v-else>
            <div class="donut-wrapper" data-animate="donut">
              <svg width="150" height="150" viewBox="0 0 150 150">
                <circle cx="75" cy="75" r="55" fill="none" stroke="#f1f5f9" stroke-width="18"/>
                <circle v-for="(seg,si) in animatedDonutSegments" :key="seg.color"
                        cx="75" cy="75" r="55" fill="none"
                        :stroke="seg.color" stroke-width="18" stroke-linecap="round"
                        :stroke-dasharray="`${seg.dash} ${seg.gap}`"
                        :stroke-dashoffset="seg.offset"
                        transform="rotate(-90 75 75)"
                        :style="{
                          transition:`stroke-dasharray ${0.6+si*0.15}s cubic-bezier(.4,0,.2,1) ${si*0.12}s,
                                      stroke-dashoffset ${0.6+si*0.15}s cubic-bezier(.4,0,.2,1) ${si*0.12}s`
                        }"/>
                <text x="75" y="68" text-anchor="middle" font-size="20" font-weight="800" fill="#1e293b">{{ placementPct }}%</text>
                <text x="75" y="84" text-anchor="middle" font-size="10" fill="#94a3b8">Placed</text>
              </svg>
            </div>
            <div class="donut-legend">
              <div v-for="item in donutItems" :key="item.label" class="donut-row">
                <div class="donut-label-left"><span class="dot" :style="{ background: item.color }"></span><span>{{ item.label }}</span></div>
                <span class="donut-pct" :style="{ color: item.color }">{{ item.pct }}</span>
              </div>
            </div>
          </template>
        </div>
      </div>

      <!-- Placement Metrics + Trending Jobs Row -->
      <div class="mid-row">
        <div class="card chart-card">
          <div class="card-header">
            <div><h3>Placement Metrics</h3><p class="card-sub">Monthly placement status breakdown — {{ chartSubLabel }}</p></div>
            <div class="legend">
              <span class="legend-item"><span class="legend-line placement-blue"></span> Placement</span>
              <span class="legend-item"><span class="legend-line processing-orange"></span> Processing</span>
              <span class="legend-item"><span class="legend-line registration-cyan"></span> Registration</span>
              <span class="legend-item"><span class="legend-line rejection-red"></span> Rejected</span>
            </div>
          </div>

          <div v-if="!hasPlacementData" class="empty-state">
            <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
              <path d="M8 48 L20 32 L32 38 L44 20 L56 28" stroke="#e2e8f0" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
              <circle cx="8"  cy="48" r="3" fill="#e2e8f0"/>
              <circle cx="20" cy="32" r="3" fill="#e2e8f0"/>
              <circle cx="32" cy="38" r="3" fill="#e2e8f0"/>
              <circle cx="44" cy="20" r="3" fill="#e2e8f0"/>
              <circle cx="56" cy="28" r="3" fill="#e2e8f0"/>
              <circle cx="46" cy="12" r="8" fill="#f1f5f9" stroke="#e2e8f0" stroke-width="1.5"/>
              <path d="M43 12h6M46 9v6" stroke="#cbd5e1" stroke-width="1.5" stroke-linecap="round"/>
            </svg>
            <p class="empty-title">No placement data yet</p>
            <p class="empty-sub">Placement metrics will show once applications are processed</p>
          </div>
          <div v-else class="svg-chart-wrap" ref="pmWrap" data-animate="pm">
            <transition name="tip">
              <div v-if="pmTip" class="chart-tooltip" :style="{ left: pmTip.x+'px', top: pmTip.y+'px' }">
                <div class="tooltip-label">{{ pmTip.label }}</div>
                <div class="tooltip-row"><span class="tooltip-dot" style="background:#2563eb"></span>Placement<strong>{{ pmTip.placement }}</strong></div>
                <div class="tooltip-row"><span class="tooltip-dot" style="background:#f97316"></span>Processing<strong>{{ pmTip.processing }}</strong></div>
                <div class="tooltip-row"><span class="tooltip-dot" style="background:#06b6d4"></span>Registration<strong>{{ pmTip.registration }}</strong></div>
                <div class="tooltip-row"><span class="tooltip-dot" style="background:#ef4444"></span>Rejected<strong>{{ pmTip.rejection }}</strong></div>
              </div>
            </transition>

            <svg ref="pmSvg"
                 viewBox="0 0 620 180" preserveAspectRatio="xMidYMid meet" class="svg-chart"
                 @mousemove="onPmMove" @mouseleave="pmTip = null">
              <defs>
                <linearGradient id="gradP"   x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#2563eb" stop-opacity="0.18"/><stop offset="100%" stop-color="#2563eb" stop-opacity="0"/></linearGradient>
                <linearGradient id="gradPr"  x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#f97316" stop-opacity="0.15"/><stop offset="100%" stop-color="#f97316" stop-opacity="0"/></linearGradient>
                <linearGradient id="gradR"   x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#06b6d4" stop-opacity="0.15"/><stop offset="100%" stop-color="#06b6d4" stop-opacity="0"/></linearGradient>
                <linearGradient id="gradRej" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#ef4444" stop-opacity="0.15"/><stop offset="100%" stop-color="#ef4444" stop-opacity="0"/></linearGradient>
                <clipPath id="pmClip">
                  <rect x="50" y="0" height="160"
                        :width="pmAnimated ? 560 : 0"
                        :style="{ transition: 'width 1.2s cubic-bezier(.4,0,.2,1)' }"/>
                </clipPath>
              </defs>

              <line v-for="(gl,i) in dynamicGridLinesP" :key="'pg'+i"
                    :x1="50" :y1="gl.y" :x2="610" :y2="gl.y" stroke="#f1f5f9" stroke-width="1"/>
              <text v-for="(gl,i) in dynamicGridLinesP" :key="'pyl'+i"
                    :x="44" :y="gl.y+4" text-anchor="end" font-size="9"
                    fill="#cbd5e1" font-family="Plus Jakarta Sans, sans-serif">{{ gl.label }}</text>

              <g clip-path="url(#pmClip)">
                <path :d="placementArea"    fill="url(#gradP)"/>
                <path :d="processingArea"   fill="url(#gradPr)"/>
                <path :d="registrationArea" fill="url(#gradR)"/>
                <path :d="rejectionArea"    fill="url(#gradRej)"/>
                <path :d="placementLine"    fill="none" stroke="#2563eb" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                <path :d="processingLine"   fill="none" stroke="#f97316" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                <path :d="registrationLine" fill="none" stroke="#06b6d4" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
                <path :d="rejectionLine"    fill="none" stroke="#ef4444" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
              </g>

              <line v-if="pmTip"
                    :x1="getXP(pmTip.i)" y1="14" :x2="getXP(pmTip.i)" y2="158"
                    stroke="#1e293b" stroke-width="1" stroke-dasharray="3 3" pointer-events="none" opacity="0.35"/>

              <template v-for="series in pmSeries" :key="series.key">
                <circle v-for="(pt,i) in series.points" :key="series.key+i"
                        :cx="pt.x" :cy="pt.y"
                        :r="pmTip && pmTip.i === i ? 5.5 : 3.5"
                        fill="#fff" :stroke="series.color" stroke-width="2"
                        pointer-events="none"
                        style="transition: r 0.12s ease"/>
              </template>

              <text v-for="(m,i) in placementData" :key="'pxl'+i"
                    :x="getXP(i)" :y="173" text-anchor="middle" font-size="9"
                    fill="#94a3b8" font-family="Plus Jakarta Sans, sans-serif">{{ m.label }}</text>

              <rect v-for="(m,i) in placementData" :key="'phit'+i"
                    :x="getXP(i) - 560/Math.max(placementData.length-1,1)/2"
                    y="0" :width="560/Math.max(placementData.length-1,1)" height="165"
                    fill="transparent" style="cursor:crosshair"/>
            </svg>
          </div>

          <div v-if="placementData.length" class="chart-summary">
            <div class="summary-item"><span class="summary-dot placement-dot"></span><span class="summary-label">Placement</span><span class="summary-val placement-val">{{ totalPlacement }}</span></div>
            <div class="summary-divider"></div>
            <div class="summary-item"><span class="summary-dot processing-dot"></span><span class="summary-label">Processing</span><span class="summary-val processing-val">{{ totalProcessing }}</span></div>
            <div class="summary-divider"></div>
            <div class="summary-item"><span class="summary-dot registration-dot"></span><span class="summary-label">Registration</span><span class="summary-val registration-val">{{ totalRegistration }}</span></div>
            <div class="summary-divider"></div>
            <div class="summary-item"><span class="summary-dot rejection-dot"></span><span class="summary-label">Rejected</span><span class="summary-val rejection-val">{{ totalRejection }}</span></div>
          </div>
        </div>

        <div class="card side-card">
          <div class="card-header">
            <div><h3>Indemand Jobs</h3><p class="card-sub">Highest demand roles this month</p></div>
            <span class="live-badge">Live</span>
          </div>
          <div v-if="!trendingJobs.length" class="empty-state">
            <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
              <rect x="8" y="16" width="48" height="36" rx="6" fill="#f1f5f9" stroke="#e2e8f0" stroke-width="1.5"/>
              <path d="M20 28h24M20 36h16" stroke="#e2e8f0" stroke-width="2" stroke-linecap="round"/>
              <circle cx="48" cy="16" r="10" fill="#f1f5f9" stroke="#e2e8f0" stroke-width="1.5"/>
              <path d="M45 16h6M48 13v6" stroke="#cbd5e1" stroke-width="1.5" stroke-linecap="round"/>
            </svg>
            <p class="empty-title">No job trends yet</p>
            <p class="empty-sub">Trending roles will appear once employers post job listings</p>
          </div>
          <div v-else class="trending-jobs-list">
            <div v-for="(job,i) in trendingJobs" :key="job.title" class="tjob-row" :style="{ animationDelay: (i*0.07)+'s' }">
              <span class="tjob-rank" :style="{ color: i<3 ? '#2563eb' : '#94a3b8' }">#{{ i+1 }}</span>
              <div class="tjob-icon" :style="{ background: job.bg }"><span v-html="job.icon" :style="{ color: job.color }"></span></div>
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

      <!-- Skills + Gap -->
      <div class="skills-gap-row">
        <div class="card">
          <div class="card-header">
            <div><h3>Indemand Skills</h3><p class="card-sub">Most in-demand skills from active job postings</p></div>
            <span class="live-badge">Live</span>
          </div>
          <div v-if="!trendingSkills.length" class="empty-state">
            <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
              <rect x="8" y="14" width="36" height="7" rx="3.5" fill="#f1f5f9" stroke="#e2e8f0" stroke-width="1.5"/>
              <rect x="8" y="27" width="28" height="7" rx="3.5" fill="#f1f5f9" stroke="#e2e8f0" stroke-width="1.5"/>
              <rect x="8" y="40" width="20" height="7" rx="3.5" fill="#f1f5f9" stroke="#e2e8f0" stroke-width="1.5"/>
              <circle cx="50" cy="14" r="10" fill="#f1f5f9" stroke="#e2e8f0" stroke-width="1.5"/>
              <path d="M47 14h6M50 11v6" stroke="#cbd5e1" stroke-width="1.5" stroke-linecap="round"/>
            </svg>
            <p class="empty-title">No skill data yet</p>
            <p class="empty-sub">In-demand skills will appear once job listings are posted</p>
          </div>
          <div v-else class="trending-skills-list" data-animate="skills">
            <div v-for="(skill,i) in trendingSkills" :key="skill.name" class="skill-bar-row">
              <div class="skill-rank">{{ i+1 }}</div>
              <div class="skill-info">
                <div class="skill-name-row">
                  <span class="skill-name">{{ skill.name }}</span>
                  <span class="skill-count">{{ skill.count }} postings</span>
                </div>
                <div class="skill-track">
                  <div class="skill-fill" :style="{
                    width: skillsAnimated ? (trendingSkills[0].count > 0 ? skill.count/trendingSkills[0].count*100 : 0)+'%' : '0%',
                    background: skill.color, transitionDelay: (i*0.1)+'s'
                  }"></div>
                </div>
              </div>
              <span class="mini-trend" :class="skill.up ? 'trend-up' : 'trend-down'">{{ skill.up ? '↑' : '↓' }} {{ skill.change }}</span>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="card-header">
            <div><h3>Skill Gap Analysis</h3><p class="card-sub">Job requirements vs. applicant skill supply</p></div>
          </div>
          <div v-if="!skillGaps.length" class="empty-state">
            <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
              <rect x="8" y="18" width="38" height="6" rx="3" fill="#f1f5f9" stroke="#e2e8f0" stroke-width="1.5"/>
              <rect x="8" y="30" width="30" height="6" rx="3" fill="#f1f5f9" stroke="#e2e8f0" stroke-width="1.5"/>
              <rect x="8" y="42" width="44" height="6" rx="3" fill="#f1f5f9" stroke="#e2e8f0" stroke-width="1.5"/>
              <circle cx="50" cy="10" r="8" fill="#f1f5f9" stroke="#e2e8f0" stroke-width="1.5"/>
              <path d="M47 10h6M50 7v6" stroke="#cbd5e1" stroke-width="1.5" stroke-linecap="round"/>
            </svg>
            <p class="empty-title">No skill gap data yet</p>
            <p class="empty-sub">Gap analysis will show once both job listings and applicant skills are available</p>
          </div>
          <div v-else class="gaps-chart" data-animate="gaps">
            <div v-for="(gap,i) in skillGaps" :key="gap.skill" class="gap-row">
              <span class="gap-label">{{ gap.skill }}</span>
              <div class="gap-bars">
                <div class="gap-bar-wrap">
                  <div class="gap-bar demand-bar" :style="{ width: gapsAnimated ? gap.required+'%' : '0%', transitionDelay: (i*0.08)+'s' }"></div>
                  <span class="gap-pct demand-pct">{{ gap.required }}%</span>
                </div>
                <div class="gap-bar-wrap">
                  <div class="gap-bar supply-bar" :style="{ width: gapsAnimated ? gap.available+'%' : '0%', transitionDelay: (i*0.08+0.04)+'s' }"></div>
                  <span class="gap-pct supply-pct">{{ gap.available }}%</span>
                </div>
              </div>
              <span class="gap-delta" :class="gap.required > gap.available ? 'gap-neg' : 'gap-pos'">
                {{ gap.required > gap.available ? '−' : '+' }}{{ Math.abs(gap.required - gap.available) }}%
              </span>
            </div>
          </div>
          <div v-if="skillGaps.length" class="gaps-legend">
            <div class="gap-legend-item"><span class="gap-legend-dot demand-dot"></span> Required by Jobs</div>
            <div class="gap-legend-item"><span class="gap-legend-dot supply-dot"></span> Available in Applicants</div>
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
          <div v-if="!applicants.length" class="empty-state">
            <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
              <circle cx="32" cy="22" r="12" fill="#f1f5f9" stroke="#e2e8f0" stroke-width="1.5"/>
              <path d="M10 54c0-12.15 9.85-22 22-22s22 9.85 22 22" stroke="#e2e8f0" stroke-width="1.5" stroke-linecap="round"/>
            </svg>
            <p class="empty-title">No applicants yet</p>
            <p class="empty-sub">Recent jobseeker registrations will appear here</p>
          </div>
          <table v-else class="data-table">
            <thead><tr><th>Applicant</th><th>Skills</th><th>Applied For</th><th>Date</th><th>Status</th></tr></thead>
            <tbody>
              <tr v-for="(a,i) in applicants" :key="a.name" class="table-row-anim" :style="{ animationDelay: (i*0.06)+'s' }">
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
            <div v-if="!events.length" class="empty-state sm">
              <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
                <rect x="4" y="8" width="40" height="36" rx="6" fill="#f1f5f9" stroke="#e2e8f0" stroke-width="1.5"/>
                <path d="M4 18h40" stroke="#e2e8f0" stroke-width="1.5"/>
                <line x1="16" y1="4" x2="16" y2="12" stroke="#e2e8f0" stroke-width="2" stroke-linecap="round"/>
                <line x1="32" y1="4" x2="32" y2="12" stroke="#e2e8f0" stroke-width="2" stroke-linecap="round"/>
                <path d="M14 28h20M14 36h12" stroke="#e2e8f0" stroke-width="2" stroke-linecap="round"/>
              </svg>
              <p class="empty-title">No upcoming events</p>
              <p class="empty-sub">Scheduled events will show here</p>
            </div>
            <div v-else class="events-list">
              <div v-for="(event,i) in events" :key="event.title" class="event-item slide-in-right" :style="{ animationDelay: (i*0.08)+'s' }">
                <div class="event-date-box" :style="{ background: event.bg, color: event.color }">
                  <span class="event-day">{{ event.day }}</span>
                  <span class="event-month">{{ event.month }}</span>
                </div>
                <div class="event-info">
                  <p class="event-title">{{ event.title }}</p>
                  <p class="event-meta">{{ event.location }}</p>
                  <p class="event-meta">{{ event.slots }} slots</p>
                </div>
                <span class="event-type" :style="{ background: event.bg, color: event.color }">{{ event.type }}</span>
              </div>
            </div>
          </div>
          <div class="card employers-card">
            <div class="card-header"><h3>Top Employers</h3><a href="#" class="see-all">See All</a></div>
            <div v-if="!topEmployers.length" class="empty-state sm">
              <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
                <rect x="4" y="16" width="40" height="28" rx="5" fill="#f1f5f9" stroke="#e2e8f0" stroke-width="1.5"/>
                <path d="M16 16V12a8 8 0 0116 0v4" stroke="#e2e8f0" stroke-width="1.5" stroke-linecap="round"/>
              </svg>
              <p class="empty-title">No employers yet</p>
              <p class="empty-sub">Top hiring companies will appear here</p>
            </div>
            <div v-else class="employers-list">
              <div v-for="(emp,i) in topEmployers" :key="emp.name" class="employer-item slide-in-right" :style="{ animationDelay: (i*0.07)+'s' }">
                <span class="emp-rank">#{{ i+1 }}</span>
                <div class="emp-logo" :style="{ background: emp.bg }">{{ emp.name[0] }}</div>
                <div class="emp-info"><p class="emp-name">{{ emp.name }}</p><p class="emp-industry">{{ emp.industry }}</p></div>
                <span class="emp-vacancies">{{ emp.vacancies }} open</span>
              </div>
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
  name: 'PESODashboard',

  data() {
    return {
      loading: true,
      lastUpdated: null,

      // Period state
      activePeriod: 'monthly',
      customFrom: '',
      customTo:   '',
      periodOptions: [
        { value: 'weekly',  label: 'Weekly'  },
        { value: 'monthly', label: 'Monthly' },
        { value: 'yearly',  label: 'Yearly'  },
        { value: 'custom',  label: 'Custom'  },
      ],

      stats: [
        { label: 'Registered Jobseekers', value: '0', sub: '—', iconBg: '#dbeafe', iconColor: '#2563eb', trendVal: '0%', trendUp: true,  icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>` },
        { label: 'Active Employers',      value: '0', sub: '—', iconBg: '#fff7ed', iconColor: '#f97316', trendVal: '0%', trendUp: true,  icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>` },
        { label: 'Job Vacancies',         value: '0', sub: '—', iconBg: '#f0fdf4', iconColor: '#22c55e', trendVal: '0%', trendUp: true,  icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>` },
        { label: 'Successful Placements', value: '0', sub: '—', iconBg: '#eff6ff', iconColor: '#3b82f6', trendVal: '0%', trendUp: false, icon: `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>` },
      ],
      chartData:      [],
      placementData:  [],
      trendingSkills: [],
      skillGaps:      [],
      trendingJobs:   [],
      applicants:     [],
      events:         [],
      topEmployers:   [],
      regAnimated: false, pmAnimated: false, donutAnimated: false,
      skillsAnimated: false, gapsAnimated: false,
      regTip: null,
      pmTip:  null,
    }
  },

  async mounted() {
    await this.$nextTick()
    await this.fetchDashboard()
  },

  computed: {
    chartSubLabel() {
      const map = { weekly: 'This week', monthly: `${new Date().getFullYear()}`, yearly: 'Last 5 years', custom: 'Custom range' }
      return map[this.activePeriod] || ''
    },

    hasRegData() {
      return this.chartData.some(d => d.jobseekers > 0 || d.employers > 0)
    },
    hasPlacementData() {
      return this.placementData.some(d => d.placement > 0 || d.processing > 0 || d.registration > 0 || d.rejection > 0)
    },

    chartMax()  { return Math.max(...this.chartData.flatMap(d => [d.jobseekers, d.employers]), 1) },
    chartNice() { return this.niceMax(this.chartMax) },
    dynamicGridLines() {
      const steps = 5
      return Array.from({ length: steps+1 }, (_, i) => ({
        y: 14 + (i/steps)*144,
        label: Math.round((this.chartNice/steps) * (steps-i)),
      }))
    },
    totalJobseekers() { return this.chartData.reduce((s,d) => s+d.jobseekers, 0) },
    totalEmployers()  { return this.chartData.reduce((s,d) => s+d.employers,  0) },
    peakMonth() {
      if (!this.chartData.length) return '—'
      return this.chartData.reduce((a,b) => b.jobseekers > a.jobseekers ? b : a).label ?? '—'
    },
    jobseekerPoints() { return this.chartData.map((d,i) => ({ x: this.getX(i),  y: this.valToY(d.jobseekers) })) },
    employerPoints()  { return this.chartData.map((d,i) => ({ x: this.getX(i),  y: this.valToY(d.employers)  })) },
    jobseekerLine()   { return this.smooth(this.jobseekerPoints) },
    employerLine()    { return this.smooth(this.employerPoints)  },
    jobseekerArea()   { const p=this.jobseekerPoints; return p.length ? this.smooth(p)+` L${p[p.length-1].x},158 L${p[0].x},158 Z`:'' },
    employerArea()    { const p=this.employerPoints;  return p.length ? this.smooth(p)+` L${p[p.length-1].x},158 L${p[0].x},158 Z`:'' },

    placementMax()  { return Math.max(...this.placementData.flatMap(d => [d.placement,d.processing,d.registration,d.rejection]), 1) },
    placementNice() { return this.niceMax(this.placementMax) },
    dynamicGridLinesP() {
      const steps = 5
      return Array.from({ length: steps+1 }, (_, i) => ({
        y: 14 + (i/steps)*144,
        label: Math.round((this.placementNice/steps) * (steps-i)),
      }))
    },
    totalPlacement()    { return this.placementData.reduce((s,d) => s+d.placement,    0) },
    totalProcessing()   { return this.placementData.reduce((s,d) => s+d.processing,   0) },
    totalRegistration() { return this.placementData.reduce((s,d) => s+d.registration, 0) },
    totalRejection()    { return this.placementData.reduce((s,d) => s+d.rejection,    0) },
    placementPoints()   { return this.placementData.map((d,i) => ({ x:this.getXP(i), y:this.valToYP(d.placement)    })) },
    processingPoints()  { return this.placementData.map((d,i) => ({ x:this.getXP(i), y:this.valToYP(d.processing)   })) },
    registrationPoints(){ return this.placementData.map((d,i) => ({ x:this.getXP(i), y:this.valToYP(d.registration) })) },
    rejectionPoints()   { return this.placementData.map((d,i) => ({ x:this.getXP(i), y:this.valToYP(d.rejection)    })) },
    placementLine()     { return this.smooth(this.placementPoints)    },
    processingLine()    { return this.smooth(this.processingPoints)   },
    registrationLine()  { return this.smooth(this.registrationPoints) },
    rejectionLine()     { return this.smooth(this.rejectionPoints)    },
    placementArea()     { const p=this.placementPoints;    return p.length ? this.smooth(p)+` L${p[p.length-1].x},158 L${p[0].x},158 Z`:'' },
    processingArea()    { const p=this.processingPoints;   return p.length ? this.smooth(p)+` L${p[p.length-1].x},158 L${p[0].x},158 Z`:'' },
    registrationArea()  { const p=this.registrationPoints; return p.length ? this.smooth(p)+` L${p[p.length-1].x},158 L${p[0].x},158 Z`:'' },
    rejectionArea()     { const p=this.rejectionPoints;    return p.length ? this.smooth(p)+` L${p[p.length-1].x},158 L${p[0].x},158 Z`:'' },
    pmSeries() {
      return [
        { key:'placement',    color:'#2563eb', points:this.placementPoints    },
        { key:'processing',   color:'#f97316', points:this.processingPoints   },
        { key:'registration', color:'#06b6d4', points:this.registrationPoints },
        { key:'rejection',    color:'#ef4444', points:this.rejectionPoints    },
      ]
    },
    donutTotal() { return Math.max(this.totalPlacement+this.totalProcessing+this.totalRegistration+this.totalRejection, 1) },
    placementPct() { return Math.round((this.totalPlacement/this.donutTotal)*100) || 0 },
    donutSegments() {
      const r=55, circ=2*Math.PI*r
      const raw=[
        { color:'#2563eb', val:this.totalPlacement    },
        { color:'#f97316', val:this.totalProcessing   },
        { color:'#06b6d4', val:this.totalRegistration },
        { color:'#ef4444', val:this.totalRejection    },
      ]
      let cum=0
      return raw.filter(x=>x.val>0).map(item => {
        const dash=(item.val/this.donutTotal)*circ
        const seg={ color:item.color, dash, gap:circ-dash, offset:-cum }
        cum+=dash; return seg
      })
    },
    animatedDonutSegments() {
      if (!this.donutAnimated) {
        const circ=2*Math.PI*55
        return this.donutSegments.map(s=>({ ...s, dash:0, gap:circ }))
      }
      return this.donutSegments
    },
    donutItems() {
      return [
        { label:'Placement',    pct:`${Math.round((this.totalPlacement   /this.donutTotal)*100)||0}%`, color:'#2563eb' },
        { label:'Processing',   pct:`${Math.round((this.totalProcessing  /this.donutTotal)*100)||0}%`, color:'#f97316' },
        { label:'Registration', pct:`${Math.round((this.totalRegistration/this.donutTotal)*100)||0}%`, color:'#06b6d4' },
        { label:'Rejected',    pct:`${Math.round((this.totalRejection   /this.donutTotal)*100)||0}%`, color:'#ef4444' },
      ]
    },
  },

  methods: {
    // ── Period control ───────────────────────────────────────────────
    setPeriod(p) {
      this.activePeriod = p
      if (p !== 'custom') this.fetchDashboard()
    },
    applyCustom() {
      if (this.customFrom && this.customTo) this.fetchDashboard()
    },

    // ── Fetch ────────────────────────────────────────────────────────
    async fetchDashboard() {
      this.loading = true
      this._resetAnimations()

      const params = { period: this.activePeriod }
      if (this.activePeriod === 'custom') {
        params.from = this.customFrom
        params.to   = this.customTo
      }

      try {
        const { data } = await api.get('/admin/dashboard', { params })
        this._applyDashboardData(data.data)
        this.lastUpdated = new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
      } catch (e) {
        console.error('Dashboard load error:', e)
      } finally {
        this.loading = false
        this.$nextTick(() => this._setupObservers())
      }
    },

    _resetAnimations() {
      this.regAnimated = false
      this.pmAnimated  = false
      this.donutAnimated = false
      this.skillsAnimated = false
      this.gapsAnimated = false
      this.regTip = null
      this.pmTip  = null
    },

    _applyDashboardData(d) {
      if (!d) return
      if (d.stats?.length) {
        d.stats.forEach((s, i) => { if (this.stats[i]) Object.assign(this.stats[i], s) })
      }
      if (d.registrationChart?.length) this.chartData     = d.registrationChart
      if (d.placementChart?.length)    this.placementData = d.placementChart
      if (d.trendingJobs?.length) {
        const bgs    = ['#dbeafe','#eff6ff','#f0fdf4','#fff7ed','#fdf4ff','#ecfdf5']
        const colors = ['#2563eb','#6366f1','#22c55e','#f97316','#d946ef','#10b981']
        const icons  = [
          `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07A19.5 19.5 0 013.07 9.81a19.79 19.79 0 01-3.07-8.67A2 2 0 012 0h3a2 2 0 012 1.72"/></svg>`,
          `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>`,
          `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6"/></svg>`,
          `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>`,
          `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 002 1.61h9.72a2 2 0 002-1.61L23 6H6"/></svg>`,
          `<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>`
        ]
        this.trendingJobs = d.trendingJobs.map((j, i) => ({
          title: j.title, industry: j.industry, vacancies: j.vacancies, apps: j.apps,
          bg: bgs[i%bgs.length], color: colors[i%colors.length], icon: icons[i%icons.length],
        }))
      }
      if (d.trendingSkills?.length) {
        const colors = ['#2563eb','#06b6d4','#8b5cf6','#22c55e','#f97316','#f59e0b']
        this.trendingSkills = d.trendingSkills.map((s, i) => ({
          name: s.name, count: s.count,
          color: colors[i%colors.length],
          change: s.change ?? '—',
          up:     s.up     ?? true,
        }))
      }
      if (d.skillGaps?.length)         this.skillGaps    = d.skillGaps
      if (d.recentApplicants?.length) {
        const colors = ['#2563eb','#f97316','#22c55e','#8b5cf6','#06b6d4','#ef4444']
        this.applicants = d.recentApplicants.map((a, i) => ({ ...a, color: colors[i%colors.length] }))
      }
      if (d.upcomingEvents?.length) {
        const typeMap = {
          'Job Fair':           { bg: '#dbeafe', color: '#2563eb' },
          'Seminar':            { bg: '#fff7ed', color: '#f97316' },
          'Training':           { bg: '#dcfce7', color: '#16a34a' },
          'Livelihood Program': { bg: '#fdf4ff', color: '#a21caf' },
          'Workshop':           { bg: '#fef9c3', color: '#ca8a04' },
        }
        this.events = d.upcomingEvents.map(e => ({
          ...e, bg: typeMap[e.type]?.bg ?? '#f1f5f9', color: typeMap[e.type]?.color ?? '#64748b',
        }))
      }
      if (d.topEmployers?.length) {
        const bgs = ['#2563eb','#f97316','#22c55e','#7c3aed','#06b6d4']
        this.topEmployers = d.topEmployers.map((emp, i) => ({ ...emp, bg: bgs[i%bgs.length] }))
      }
    },

    // ── Chart helpers ────────────────────────────────────────────────
    getX(i)    { return 50 + i*(560/Math.max(this.chartData.length-1,    1)) },
    getXP(i)   { return 50 + i*(560/Math.max(this.placementData.length-1,1)) },
    valToY(v)  { return 158 - ((v/this.chartNice)    *144) },
    valToYP(v) { return 158 - ((v/this.placementNice)*144) },

    niceMax(raw) {
      if (raw<=0) return 1
      const mag=Math.pow(10,Math.floor(Math.log10(raw)))
      for (const s of [1,2,2.5,5,10]) {
        const c=Math.ceil(raw/(mag*s))*(mag*s)
        if (c>=raw) return c
      }
      return Math.ceil(raw/mag)*mag
    },

    smooth(pts) {
      if (!pts.length) return ''
      let d=`M${pts[0].x},${pts[0].y}`
      for (let i=1; i<pts.length; i++) {
        const cpx=(pts[i-1].x+pts[i].x)/2
        d+=` C${cpx},${pts[i-1].y} ${cpx},${pts[i].y} ${pts[i].x},${pts[i].y}`
      }
      return d
    },

    _svgPoint(svgEl, clientX, clientY) {
      const pt = svgEl.createSVGPoint()
      pt.x = clientX; pt.y = clientY
      return pt.matrixTransform(svgEl.getScreenCTM().inverse())
    },

    _closestIdx(svgX, getXFn, count) {
      if (!count) return null
      let best=0, bestDist=Infinity
      for (let i=0; i<count; i++) {
        const dist=Math.abs(svgX-getXFn(i))
        if (dist<bestDist) { bestDist=dist; best=i }
      }
      const colW = 560/Math.max(count-1,1)
      return bestDist <= colW/2+4 ? best : null
    },

    _tipPos(clientX, clientY, wrapEl) {
      const r=wrapEl.getBoundingClientRect()
      let x=clientX-r.left+14
      let y=clientY-r.top-12
      if (x+180>r.width) x=clientX-r.left-188
      if (y<0)           y=4
      return { x, y }
    },

    onRegMove(evt) {
      if (!this.chartData.length) return
      const svgPt = this._svgPoint(this.$refs.regSvg, evt.clientX, evt.clientY)
      const idx   = this._closestIdx(svgPt.x, this.getX.bind(this), this.chartData.length)
      if (idx === null) { this.regTip = null; return }
      const raw = this.chartData[idx]
      const pos = this._tipPos(evt.clientX, evt.clientY, this.$refs.regWrap)
      this.regTip = { i: idx, label: String(raw.label ?? ''), jobseekers: Number(raw.jobseekers ?? 0), employers: Number(raw.employers ?? 0), x: pos.x, y: pos.y }
    },

    onPmMove(evt) {
      if (!this.placementData.length) return
      const svgPt = this._svgPoint(this.$refs.pmSvg, evt.clientX, evt.clientY)
      const idx   = this._closestIdx(svgPt.x, this.getXP.bind(this), this.placementData.length)
      if (idx === null) { this.pmTip = null; return }
      const raw = this.placementData[idx]
      const pos = this._tipPos(evt.clientX, evt.clientY, this.$refs.pmWrap)
      this.pmTip = { i: idx, label: String(raw.label ?? ''), placement: Number(raw.placement ?? 0), processing: Number(raw.processing ?? 0), registration: Number(raw.registration ?? 0), rejection: Number(raw.rejection ?? 0), x: pos.x, y: pos.y }
    },

    _setupObservers() {
      const observe = (refName, flag, delay = 0) => {
        const el = this.$el.querySelector(`[data-animate="${refName}"]`)
        if (!el) return
        const observer = new IntersectionObserver(([entry]) => {
          if (entry.isIntersecting) {
            setTimeout(() => { this[flag] = true }, delay)
            observer.disconnect()
          }
        }, { threshold: 0.2 })
        observer.observe(el)
      }
      observe('reg',    'regAnimated',    100)
      observe('pm',     'pmAnimated',     100)
      observe('donut',  'donutAnimated',  100)
      observe('skills', 'skillsAnimated', 100)
      observe('gaps',   'gapsAnimated',   100)
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
.dashboard-page { font-family: 'Plus Jakarta Sans', sans-serif; flex: 1; overflow-y: auto; padding: 20px 24px; display: flex; flex-direction: column; gap: 16px; background: #f1eeff; }

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
.period-pill.active { background: #eff6ff; color: #2563eb; border-color: #2563eb; }

.custom-range {
  display: flex; align-items: center; gap: 8px; flex-wrap: wrap;
}
.date-input {
  border: 1.5px solid #e2e8f0; border-radius: 8px;
  padding: 5px 10px; font-size: 12px; color: #1e293b;
  font-family: inherit; outline: none; background: #f8fafc;
  transition: border-color 0.15s;
}
.date-input:focus { border-color: #2563eb; background: #fff; }
.date-sep { font-size: 12px; color: #94a3b8; }
.apply-btn {
  padding: 6px 14px; background: #2563eb; color: #fff; border: none;
  border-radius: 8px; font-size: 12.5px; font-weight: 600; cursor: pointer;
  font-family: inherit; transition: background 0.15s;
}
.apply-btn:hover:not(:disabled) { background: #1d4ed8; }
.apply-btn:disabled { background: #cbd5e1; cursor: not-allowed; }
.last-updated {
  margin-left: auto; font-size: 11px; color: #94a3b8;
  display: flex; align-items: center; gap: 4px;
}
.last-updated::before {
  content: ''; width: 6px; height: 6px; border-radius: 50%;
  background: #22c55e; display: inline-block;
}

/* Fade-slide transition for custom range */
.fade-slide-enter-active { transition: all 0.2s ease; }
.fade-slide-leave-active { transition: all 0.15s ease; }
.fade-slide-enter-from, .fade-slide-leave-to { opacity: 0; transform: translateX(-8px); }

/* ── SKELETON ────────────────────────────────────────────────────────────── */
@keyframes shimmer {
  0%   { background-position: -600px 0; }
  100% { background-position:  600px 0; }
}
.skel {
  background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%);
  background-size: 600px 100%;
  animation: shimmer 1.4s infinite linear;
  border-radius: 6px;
}
.skel-icon    { width: 42px; height: 42px; border-radius: 12px; }
.skel-badge   { width: 52px; height: 24px; border-radius: 99px; }
.skel-val     { width: 80px; height: 28px; border-radius: 6px; margin-bottom: 8px; }
.skel-label   { width: 120px; height: 13px; border-radius: 6px; margin-bottom: 6px; }
.skel-sub     { width: 90px; height: 11px; border-radius: 6px; }
.skel-title   { width: 160px; height: 15px; border-radius: 6px; }
.skel-legend  { width: 120px; height: 13px; border-radius: 6px; }
.skel-chart   { width: 100%; height: 185px; border-radius: 10px; margin: 12px 0; }
.skel-donut   { width: 150px; height: 150px; border-radius: 50%; margin: 8px auto 16px; }
.skel-card-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px; }
.skel-summary-row { display: flex; align-items: center; gap: 12px; padding-top: 14px; border-top: 1px solid #f1f5f9; margin-top: 14px; }
.skel-summary-item { flex: 1; height: 13px; border-radius: 6px; }
.skel-tjob-row { display: flex; align-items: center; gap: 8px; padding: 7px 8px; border-radius: 9px; background: #f8fafc; margin-bottom: 6px; }
.skel-skill-row { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; }
.skel-gap-row { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; }
.skel-table-row { display: flex; align-items: center; gap: 12px; padding: 10px; border-bottom: 1px solid #f8fafc; }
.skel-event-row { display: flex; align-items: center; gap: 10px; margin-bottom: 10px; }
.skel-emp-row { display: flex; align-items: center; gap: 10px; margin-bottom: 10px; }

/* ── STAT CARDS ──────────────────────────────────────────────────────────── */
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

/* ── LAYOUT ──────────────────────────────────────────────────────────────── */
.mid-row        { display: grid; grid-template-columns: 1fr 252px; gap: 14px; }
.bottom-row     { display: grid; grid-template-columns: 1fr 280px; gap: 14px; }
.right-col      { display: flex; flex-direction: column; gap: 14px; }
.skills-gap-row { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }

/* ── CARD BASE ───────────────────────────────────────────────────────────── */
.card { background: #fff; border-radius: 14px; padding: 18px; border: 1px solid #f1f5f9; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
.side-card { background: #fff; border-radius: 14px; padding: 18px; border: 1px solid #f1f5f9; box-shadow: 0 1px 3px rgba(0,0,0,0.04); min-width: 0; overflow: hidden; }
.card-header { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 16px; gap: 8px; }
.card-header h3 { font-size: 14px; font-weight: 700; color: #1e293b; }
.card-sub { font-size: 11px; color: #94a3b8; margin-top: 2px; }
.see-all { font-size: 12px; color: #2563eb; text-decoration: none; font-weight: 600; white-space: nowrap; flex-shrink: 0; }
.see-all:hover { text-decoration: underline; }

/* ── LIVE BADGE ──────────────────────────────────────────────────────────── */
.live-badge { background: #dcfce7; color: #16a34a; font-size: 10px; font-weight: 700; padding: 3px 8px; border-radius: 99px; display: flex; align-items: center; gap: 4px; height: fit-content; white-space: nowrap; flex-shrink: 0; }
.live-badge::before { content: ''; width: 6px; height: 6px; background: #16a34a; border-radius: 50%; animation: pulse 1.5s infinite; }
@keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.3} }

/* ── LEGEND ──────────────────────────────────────────────────────────────── */
.legend { display: flex; align-items: center; gap: 14px; font-size: 11.5px; color: #64748b; flex-wrap: wrap; flex-shrink: 0; }
.legend-item { display: flex; align-items: center; gap: 6px; }
.legend-line { display: inline-block; width: 22px; height: 3px; border-radius: 2px; }
.legend-line.blue               { background: #2563eb; }
.legend-line.cyan               { background: #06b6d4; }
.legend-line.placement-blue    { background: #2563eb; }
.legend-line.processing-orange { background: #f97316; }
.legend-line.registration-cyan { background: #06b6d4; }
.legend-line.rejection-red     { background: #ef4444; }

/* ── CHART ───────────────────────────────────────────────────────────────── */
.svg-chart-wrap { width: 100%; position: relative; }
.svg-chart { width: 100%; height: 185px; display: block; overflow: visible; cursor: crosshair; }

/* ── TOOLTIP ─────────────────────────────────────────────────────────────── */
.chart-tooltip { position: absolute; pointer-events: none; background: #1e293b; color: #f8fafc; border-radius: 10px; padding: 10px 14px; font-size: 11.5px; min-width: 158px; box-shadow: 0 8px 24px rgba(0,0,0,0.22); z-index: 50; white-space: nowrap; }
.tip-enter-active { transition: opacity 0.12s ease, transform 0.12s ease; }
.tip-leave-active { transition: opacity 0.08s ease; }
.tip-enter-from   { opacity: 0; transform: translateY(4px) scale(0.97); }
.tip-leave-to     { opacity: 0; }
.tooltip-label { font-weight: 700; font-size: 10px; color: #94a3b8; margin-bottom: 7px; letter-spacing: 0.5px; text-transform: uppercase; }
.tooltip-row   { display: flex; align-items: center; gap: 7px; line-height: 2; }
.tooltip-row strong { margin-left: auto; padding-left: 14px; font-weight: 700; color: #fff; }
.tooltip-dot   { display: inline-block; width: 7px; height: 7px; border-radius: 50%; flex-shrink: 0; }

/* ── CHART SUMMARY ───────────────────────────────────────────────────────── */
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

/* ── DONUT ───────────────────────────────────────────────────────────────── */
.donut-wrapper { display: flex; justify-content: center; margin: 4px 0 14px; }
.donut-legend  { display: flex; flex-direction: column; gap: 8px; }
.donut-row     { display: flex; align-items: center; justify-content: space-between; font-size: 12px; color: #64748b; }
.donut-label-left { display: flex; align-items: center; gap: 8px; }
.dot     { display: inline-block; width: 8px; height: 8px; border-radius: 50%; }
.donut-pct { font-size: 12px; font-weight: 700; }

/* ── TRENDING JOBS ───────────────────────────────────────────────────────── */
.trending-jobs-list { display: flex; flex-direction: column; gap: 6px; }
.tjob-row { display: flex; align-items: center; gap: 8px; padding: 7px 8px; border-radius: 9px; background: #f8fafc; border: 1px solid #f1f5f9; animation: slideUp 0.38s ease both; transition: background 0.15s, box-shadow 0.15s; }
.tjob-row:hover { background: #eff6ff; box-shadow: 0 2px 8px rgba(37,99,235,0.07); }
.tjob-rank { font-size: 11px; font-weight: 800; min-width: 18px; flex-shrink: 0; }
.tjob-icon { width: 28px; height: 28px; border-radius: 7px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.tjob-body { flex: 1; min-width: 0; }
.tjob-title    { font-size: 11.5px; font-weight: 700; color: #1e293b; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.tjob-industry { font-size: 10px; color: #94a3b8; margin-top: 1px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.tjob-stats    { display: flex; flex-direction: column; align-items: flex-end; gap: 1px; flex-shrink: 0; }
.tjob-open { font-size: 11px; font-weight: 700; color: #2563eb; }
.tjob-apps { font-size: 10px; color: #94a3b8; }

/* ── TRENDING SKILLS ─────────────────────────────────────────────────────── */
.trending-skills-list { display: flex; flex-direction: column; gap: 12px; }
.skill-bar-row { display: flex; align-items: center; gap: 10px; }
.skill-rank  { font-size: 11px; font-weight: 700; color: #cbd5e1; min-width: 14px; text-align: center; flex-shrink: 0; }
.skill-info  { flex: 1; }
.skill-name-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 5px; }
.skill-name  { font-size: 12.5px; font-weight: 600; color: #1e293b; }
.skill-count { font-size: 11px; color: #94a3b8; }
.skill-track { height: 7px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.skill-fill  { height: 100%; border-radius: 99px; width: 0%; transition: width 0.75s cubic-bezier(.4,0,.2,1); }
.mini-trend  { font-size: 10.5px; font-weight: 700; padding: 2px 7px; border-radius: 6px; white-space: nowrap; flex-shrink: 0; }
.trend-up    { background: #f0fdf4; color: #16a34a; }
.trend-down  { background: #fef2f2; color: #ef4444; }

/* ── SKILL GAP ───────────────────────────────────────────────────────────── */
.gaps-chart { display: flex; flex-direction: column; gap: 12px; margin-bottom: 12px; }
.gap-row { display: flex; align-items: center; gap: 8px; }
.gap-label { font-size: 11.5px; font-weight: 600; color: #475569; min-width: 110px; }
.gap-bars { flex: 1; display: flex; flex-direction: column; gap: 3px; }
.gap-bar-wrap { display: flex; align-items: center; gap: 5px; }
.gap-bar { height: 6px; border-radius: 99px; width: 0%; transition: width 0.75s cubic-bezier(.4,0,.2,1); }
.demand-bar { background: #2563eb; }
.supply-bar { background: #22c55e; }
.gap-pct { font-size: 10px; font-weight: 600; min-width: 26px; }
.demand-pct { color: #2563eb; }
.supply-pct { color: #22c55e; }
.gap-delta { font-size: 11px; font-weight: 700; min-width: 36px; text-align: right; }
.gap-neg { color: #ef4444; }
.gap-pos { color: #22c55e; }
.gaps-legend { display: flex; gap: 16px; padding-top: 12px; border-top: 1px solid #f1f5f9; }
.gap-legend-item { display: flex; align-items: center; gap: 6px; font-size: 11.5px; color: #64748b; }
.gap-legend-dot { width: 10px; height: 10px; border-radius: 3px; }
.demand-dot { background: #2563eb; }
.supply-dot { background: #22c55e; }

/* ── TABLE ───────────────────────────────────────────────────────────────── */
.data-table { width: 100%; border-collapse: collapse; font-size: 12.5px; }
.data-table th { text-align: left; padding: 8px 10px; color: #94a3b8; font-weight: 600; font-size: 11px; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.data-table td { padding: 10px; color: #1e293b; border-bottom: 1px solid #f8fafc; vertical-align: middle; }
.table-row-anim { animation: slideUp 0.35s ease both; }
.data-table tbody tr { transition: background 0.15s; }
.data-table tbody tr:hover { background: #f8fafc; }
.person-cell   { display: flex; align-items: center; gap: 8px; }
.person-avatar { width: 28px; height: 28px; border-radius: 50%; color: #fff; font-size: 11px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.person-name   { display: block; font-weight: 600; font-size: 12.5px; color: #1e293b; }
.person-loc    { display: block; font-size: 10.5px; color: #94a3b8; }
.skill-tag     { background: #f1f5f9; color: #475569; font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
.job-cell      { color: #475569; }
.date-cell     { color: #94a3b8; white-space: nowrap; }
.status-badge  { padding: 3px 10px; border-radius: 99px; font-size: 11px; font-weight: 600; white-space: nowrap; }
.status-badge.matched     { background: #f0fdf4; color: #22c55e; }
.status-badge.pending     { background: #fff7ed; color: #f97316; }
.status-badge.reviewing   { background: #dbeafe; color: #1d4ed8; }
.status-badge.shortlisted { background: #eff8ff; color: #1a5f8a; }
.status-badge.interview   { background: #ede9fe; color: #8B5CF6; }
.status-badge.hired       { background: #dcfce7; color: #16a34a; }
.status-badge.rejected    { background: #fef2f2; color: #ef4444; }

/* ── EVENTS ──────────────────────────────────────────────────────────────── */
.events-list { display: flex; flex-direction: column; gap: 10px; }
.event-item  { display: flex; align-items: center; gap: 10px; }
.event-date-box { min-width: 40px; height: 44px; border-radius: 10px; display: flex; flex-direction: column; align-items: center; justify-content: center; flex-shrink: 0; }
.event-day   { font-size: 15px; font-weight: 800; line-height: 1; }
.event-month { font-size: 9px; font-weight: 60a0; text-transform: uppercase; }
.event-info  { flex: 1; min-width: 0; }
.event-title { font-size: 12px; font-weight: 600; color: #1e293b; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.event-meta  { font-size: 10.5px; color: #94a3b8; margin-top: 2px; }
.event-type  { font-size: 10px; font-weight: 600; padding: 3px 8px; border-radius: 6px; white-space: nowrap; flex-shrink: 0; }

/* ── EMPLOYERS ───────────────────────────────────────────────────────────── */
.employers-list  { display: flex; flex-direction: column; gap: 10px; }
.employer-item   { display: flex; align-items: center; gap: 10px; }
.emp-rank        { font-size: 11px; font-weight: 700; color: #cbd5e1; min-width: 16px; }
.emp-logo        { width: 32px; height: 32px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 13px; font-weight: 800; color: #fff; flex-shrink: 0; }
.emp-info        { flex: 1; }
.emp-name        { font-size: 12.5px; font-weight: 600; color: #1e293b; }
.emp-industry    { font-size: 10.5px; color: #94a3b8; }
.emp-vacancies   { font-size: 11px; font-weight: 600; color: #2563eb; background: #dbeafe; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }

/* ── ENTRANCE ANIMATIONS ─────────────────────────────────────────────────── */
@keyframes slideUp { from { opacity:0; transform:translateY(10px); } to { opacity:1; transform:translateY(0); } }
@keyframes slideInRight { from { opacity:0; transform:translateX(14px); } to { opacity:1; transform:translateX(0); } }
.slide-in-right { animation: slideInRight 0.4s ease both; }

/* ── EMPTY STATES ────────────────────────────────────────────────────────── */
.empty-state { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 40px 20px; gap: 10px; text-align: center; }
.empty-state.sm { padding: 24px 16px; }
.empty-state svg { opacity: 0.85; margin-bottom: 4px; }
.empty-title { font-size: 13px; font-weight: 700; color: #94a3b8; margin: 0; }
.empty-sub { font-size: 11.5px; color: #cbd5e1; margin: 0; max-width: 220px; line-height: 1.5; }
.stat-value.zero { color: #cbd5e1; }
</style>