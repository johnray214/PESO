<template>
  <div class="page">

    <!-- Toast -->
    <transition name="toast">
      <div v-if="toast.show" class="toast" :class="toast.type">
        <span class="toast-icon" v-html="toast.icon"></span>
        <span class="toast-msg">{{ toast.text }}</span>
      </div>
    </transition>

    <!-- SKELETON -->
    <template v-if="loading || tabsLoading">
      <div class="filters-bar" style="margin-bottom: 20px;">
        <div class="skel" style="width: 300px; height: 38px; border-radius: 10px;"></div>
        <div style="display:flex; gap:8px;">
          <div class="skel" style="width: 120px; height: 36px; border-radius: 8px;"></div>
          <div class="skel" style="width: 120px; height: 36px; border-radius: 8px;"></div>
        </div>
      </div>
      <div class="skel" style="width: 360px; height: 42px; border-radius: 12px; margin-bottom: 16px;"></div>
      <div class="table-card" style="padding: 20px;">
        <div v-for="i in 6" :key="i" class="skel" style="width: 100%; height: 50px; border-radius: 8px; margin-bottom: 10px;"></div>
      </div>
    </template>

    <!-- ACTUAL CONTENT -->
    <template v-else>
      <div class="filters-bar">
        <div style="display: flex; gap: 8px; flex: 1; max-width: 480px;">
          <div class="search-box" style="flex: 1; max-width: none;">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            <input v-model="search" type="text" :placeholder="mainTab === 'potential' ? 'Search by name or skill…' : 'Search applicant, skill, location…'" class="search-input" @keyup.enter="applySearch"/>
          </div>
          <button type="button" class="search-btn" @click="applySearch" :disabled="pageLoading || potentialLoading || searching">
            <span v-if="searching" class="spinner-search"></span>
            <template v-else>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            </template>
            {{ searching ? 'Searching…' : 'Search' }}
          </button>
        </div>
        <!-- Applied filters -->
        <div class="filter-group" v-if="mainTab !== 'potential'">
          <select v-model="filterStatus" class="filter-select" @change="applyDropdownFilter">
            <option value="">All Status</option>
            <option value="reviewing">Reviewing</option>
            <option value="shortlisted">Shortlisted</option>
            <option value="interview">Interview</option>
            <option value="for_job_offer">For Job Offer</option>
            <option value="hired">Hired</option>
            <option value="rejected">Rejected</option>
          </select>
          <select v-model="filterSkill" class="filter-select" @change="applyDropdownFilter">
            <option value="">All Skills</option>
            <option v-for="sk in skillOptions" :key="sk" :value="sk">{{ sk }}</option>
          </select>
          <select v-model="filterDate" class="filter-select" @change="applyDropdownFilter">
            <option value="">All Time</option>
            <option value="today">Today</option>
            <option value="week">This Week</option>
            <option value="month">This Month</option>
          </select>
        </div>
        <!-- Potential filters -->
        <div class="filter-group" v-if="mainTab === 'potential'">
          <select v-model="potentialEmployerFilter" @change="applyPotentialDropdownFilter" class="filter-select">
            <option value="">All Employers</option>
            <option v-for="emp in potentialEmployerOptions" :key="emp" :value="emp">{{ emp }}</option>
          </select>
        </div>
      </div>

      <!-- Main Tabs -->
      <div class="main-tabs">
        <button :class="['main-tab', { active: mainTab !== 'potential' }]" @click="switchMainTab('applied')">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
          Applied Applicants <span class="main-count">{{ totalApplicants }}</span>
        </button>
        <button :class="['main-tab', 'potential-tab', { active: mainTab === 'potential' }]" @click="switchMainTab('potential')">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
          Potential Applicants <span class="main-count potential-count">{{ potentialApplicants.length }}</span>
        </button>
      </div>

      <!-- ===== APPLIED VIEW ===== -->
      <template v-if="mainTab !== 'potential'">
        <!-- Status Tabs -->
        <div class="status-tabs">
          <button v-for="tab in statusTabs" :key="tab.value" :class="['tab-btn', { active: activeTab === tab.value }]" @click="switchTab(tab.value)">
            {{ tab.label }}<span class="tab-count" :class="tab.value">{{ tab.count }}</span>
          </button>
        </div>

        <!-- Table -->
        <div class="table-card" style="overflow-x: auto;">
          <template v-if="pageLoading">
            <div style="padding: 16px 20px;">
              <div v-for="i in 15" :key="i" class="skel" style="width: 100%; height: 48px; border-radius: 8px; margin-bottom: 8px;"></div>
            </div>
          </template>
          <template v-else>
            <table class="data-table" style="min-width: 860px;">
              <thead>
                <tr>
                  <th style="width:40px">No.</th><th>Applicant</th><th>Skills</th><th>Job Applied</th><th>Employer</th><th style="width:110px">Match</th><th style="width:90px">Date</th><th style="width:90px">Status</th><th style="width:70px">Files</th><th style="width:60px">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(a, index) in filteredApplicants" :key="a.id" class="table-row" @click="openDrawer(a, false)">
                  <td @click.stop style="font-weight:600;color:#64748b;font-size:12px;padding-left:18px;">{{ totalApplicants - ((currentPage - 1) * 15) - index }}</td>
                  <td>
                    <div class="person-cell">
                      <div class="avatar" :style="{ background: a.avatarBg }">{{ initials(a.name) }}</div>
                      <div><p class="person-name">{{ a.name }}</p><p class="person-meta">{{ a.location }}</p></div>
                    </div>
                  </td>
                  <td>
                    <div class="skill-tags">
                      <span v-for="sk in a.skills.slice(0,2)" :key="sk" class="skill-tag">{{ sk }}</span>
                      <span v-if="a.skills.length > 2" class="skill-more">+{{ a.skills.length - 2 }}</span>
                    </div>
                  </td>
                  <td class="job-cell">{{ a.jobApplied }}</td>
                  <td class="employer-cell">{{ a.employer }}</td>
                  <td @click.stop>
                    <div class="score-cell">
                      <div class="score-bar-bg"><div class="score-bar-fill" :style="{ width: a.matchScore+'%', background: scoreColor(a.matchScore) }"></div></div>
                      <span class="score-val" :style="{ color: scoreColor(a.matchScore) }">{{ a.matchScore }}%</span>
                    </div>
                  </td>
                  <td class="date-cell">{{ a.date }}</td>
                  <td @click.stop><span class="status-badge" :class="statusClass(a.status)">{{ a.status }}</span></td>
                  <td @click.stop>
                    <div class="file-icons">
                      <button class="file-btn" :class="{ has: a.files.resume }" title="Resume"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg></button>
                      <button class="file-btn" :class="{ has: a.files.cert }" title="Certificate"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="6"/><path d="M15.477 12.89L17 22l-5-3-5 3 1.523-9.11"/></svg></button>
                      <button class="file-btn" :class="{ has: a.files.clearance }" title="Clearance"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></button>
                    </div>
                  </td>
                  <td @click.stop>
                    <!-- Applied applicants: view only. Invite is only for Potential tab -->
                    <button class="act-btn view" @click="openDrawer(a, false)" title="View Details">
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    </button>
                  </td>
                </tr>
                <tr v-if="filteredApplicants.length === 0 && !loading && !pageLoading">
                  <td colspan="10">
                    <div class="empty-state">
                      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/><path d="M11 8v2"/><path d="M11 14h.01"/></svg>
                      <p>No matches found</p><span>Try adjusting your filters or search terms.</span>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </template>
          <!-- Pagination -->
          <div v-if="lastPage > 1" class="pagination">
            <span class="page-info">Showing {{ (currentPage-1)*15+1 }}–{{ Math.min(currentPage*15, totalApplicants) }} of {{ totalApplicants }} applicants</span>
            <div class="page-btns">
              <button class="page-btn" :disabled="currentPage===1||pageLoading" @click="changePage(currentPage-1)">‹</button>
              <button v-for="p in paginationPages" :key="p" class="page-btn" :class="{ active: currentPage===p }" :disabled="pageLoading" @click="changePage(p)">{{ p }}</button>
              <button class="page-btn" :disabled="currentPage===lastPage||pageLoading" @click="changePage(currentPage+1)">›</button>
            </div>
          </div>
        </div>
      </template>

      <!-- ===== POTENTIAL VIEW ===== -->
      <template v-if="mainTab === 'potential'">
        <div class="potential-notice">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2" style="flex-shrink:0;margin-top:1px"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          These are active jobseekers whose skills match <strong>&nbsp;any job listing across all employers</strong> — but have not applied yet.
        </div>

        <!-- Listing filter tabs -->
        <div class="listing-tabs">
          <button class="listing-tab" :class="{ active: potentialEmployerFilter === '' }" @click="potentialEmployerFilter = ''; search = ''; potentialSearchApplied = ''; potentialPage = 1">All <span class="ltab-count">{{ potentialApplicants.length }}</span></button>
          <button v-for="emp in potentialEmployerOptions" :key="emp" class="listing-tab" :class="{ active: potentialEmployerFilter === emp }" @click="potentialEmployerFilter = emp; search = ''; potentialSearchApplied = ''; potentialPage = 1">{{ emp }} <span class="ltab-count">{{ potentialApplicants.filter(a => a.bestEmployer === emp).length }}</span></button>
        </div>

        <div v-if="potentialLoading" class="table-card" style="padding:20px;">
          <div v-for="i in 8" :key="i" class="skel" style="width:100%;height:48px;border-radius:8px;margin-bottom:8px;"></div>
        </div>

        <div v-else class="table-card" style="overflow-x: auto;">
          <table class="data-table" style="min-width: 780px;">
            <thead>
              <tr><th>No.</th><th>Jobseeker</th><th>Matched Skills</th><th>Matches Listing</th><th>Match Score</th><th>Location</th><th>Status</th><th style="width:80px">Actions</th></tr>
            </thead>
            <tbody>
              <tr v-for="(a, index) in pagedPotential" :key="a.id" class="table-row" @click="openDrawer(a, true)">
                <td @click.stop style="font-weight:600;color:#64748b;font-size:12px;padding-left:18px;">{{ filteredPotential.length - ((potentialPage - 1) * 15) - index }}</td>
                <td>
                  <div class="person-cell">
                    <div class="avatar" :style="{ background: a.color }">{{ a.name[0] }}</div>
                    <div><p class="person-name">{{ a.name }}</p><p class="person-meta">{{ a.education }}</p></div>
                  </div>
                </td>
                <td>
                  <div class="skill-tags">
                    <span v-for="sk in a.skills" :key="sk" class="skill-tag matched-tag">{{ sk }}</span>
                  </div>
                </td>
                <td>
                  <div class="listing-match-cell">
                    <div class="listing-bar" :style="{ background: a.jobColor }"></div>
                    <div>
                      <p class="person-name" style="font-size:12.5px">{{ a.bestFor }}</p>
                      <p class="person-meta">{{ a.bestEmployer }}</p>
                    </div>
                  </div>
                </td>
                <td>
                  <div class="score-cell">
                    <div class="score-bar-bg"><div class="score-bar-fill" :style="{ width: a.score+'%', background: scoreColor(a.score) }"></div></div>
                    <span class="score-val" :style="{ color: scoreColor(a.score) }">{{ a.score }}%</span>
                  </div>
                </td>
                <td>
                  <div class="loc-cell">
                    <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                    {{ a.location }}
                  </div>
                </td>
                <td><span class="not-applied-badge"><span class="na-dot"></span>Not Applied</span></td>
                <td @click.stop>
                  <div class="action-btns">
                    <button class="act-btn view" @click="openDrawer(a, true)" title="View">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    </button>
                    <button class="act-btn invite-act" @click.stop="openInviteConfirm({ jobseekerId: a.id, jobListingId: a.bestJobId, name: a.name, matchScore: a.score, jobTitle: a.bestFor, employer: a.bestEmployer, _ref: a })" :disabled="a.invited" title="Invite (PESO)">
                      <svg v-if="!a.invited" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
                      <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="pagedPotential.length === 0">
                <td colspan="8">
                  <div class="empty-state">
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/><path d="M11 8v2"/><path d="M11 14h.01"/></svg>
                    <p>No potential applicants found</p><span>No active jobseekers match any current job listings.</span>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
          <div class="pagination">
            <span class="page-info">Showing {{ filteredPotential.length === 0 ? 0 : (potentialPage-1)*15+1 }}–{{ Math.min(potentialPage*15, filteredPotential.length) }} of {{ filteredPotential.length }} potential applicants</span>
            <div class="page-btns">
              <button class="page-btn" :disabled="potentialPage===1" @click="potentialPage--">‹</button>
              <button v-for="p in potentialTotalPages" :key="p" class="page-btn" :class="{ active: potentialPage===p }" @click="potentialPage=p">{{ p }}</button>
              <button class="page-btn" :disabled="potentialPage===potentialTotalPages" @click="potentialPage++">›</button>
            </div>
          </div>
        </div>
      </template>

      <!-- DRAWER -->
      <transition name="drawer">
        <div v-if="drawerOpen" class="drawer-overlay" @click.self="drawerOpen = false">
          <div class="drawer">
            <div class="drawer-header">
              <div class="drawer-avatar" :style="{ background: selected?.avatarBg || selected?.color }">
                {{ selected ? initials(selected.name) : '' }}
              </div>
              <div class="drawer-title-wrap">
                <h2 class="drawer-name">{{ selected?.name }}</h2>
                <p class="drawer-loc">{{ selected?.location }}</p>
              </div>
              <span v-if="selected && !selected._isPotential" class="status-badge lg" :class="statusClass(selected.status)">{{ selected?.status }}</span>
              <button class="drawer-close" @click="drawerOpen = false">✕</button>
            </div>

            <!-- Match Banner -->
            <div class="match-banner" :style="{ background: scoreBg(selected?._isPotential ? selected?.score : selected?.matchScore) }">
              <div class="match-info">
                <span class="match-label">Match Score</span>
                <span class="match-val" :style="{ color: scoreColor(selected?._isPotential ? selected?.score : selected?.matchScore) }">{{ selected?._isPotential ? selected?.score : selected?.matchScore }}%</span>
              </div>
              <div class="match-bar-bg"><div class="match-bar-fill" :style="{ width: (selected?._isPotential ? selected?.score : selected?.matchScore) + '%', background: scoreColor(selected?._isPotential ? selected?.score : selected?.matchScore) }"></div></div>
            </div>

            <!-- Drawer Tabs -->
            <div class="drawer-tabs">
              <button v-for="dt in (selected?._isPotential ? ['Profile'] : drawerTabList)" :key="dt" :class="['dtab', { active: drawerTab === dt }]" @click="onDrawerTabChange(dt)">{{ dt }}</button>
            </div>

            <div class="drawer-body">
              <!-- Profile Tab -->
              <div v-if="drawerTab === 'Profile'">
                <div class="info-grid">
                  <div class="info-item"><span class="info-label">Full Name</span><span class="info-val">{{ selected?.name }}</span></div>
                  <div class="info-item"><span class="info-label">Location</span><span class="info-val">{{ selected?.location }}</span></div>
                  <div class="info-item"><span class="info-label">Contact</span><span class="info-val">{{ selected?.contact || 'N/A' }}</span></div>
                  <div class="info-item"><span class="info-label">Email</span><span class="info-val">{{ selected?.email || 'N/A' }}</span></div>
                  <div class="info-item"><span class="info-label">Sex</span><span class="info-val" style="text-transform:capitalize;">{{ selected?.sex || 'Not specified' }}</span></div>
                  <div class="info-item"><span class="info-label">Date of Birth</span><span class="info-val">{{ selected?.dateOfBirth ? formatDate(selected.dateOfBirth) : 'Not specified' }}</span></div>
                  <div class="info-item"><span class="info-label">Education</span><span class="info-val">{{ selected?.education }}</span></div>
                  <div class="info-item"><span class="info-label">Experience</span><span class="info-val">{{ selected?.experience || 'N/A' }}</span></div>
                </div>
                <div class="section-label">Skills</div>
                <div class="skill-tags mt4">
                  <span v-for="sk in selected?.skills" :key="sk" class="skill-tag">{{ sk }}</span>
                </div>

                <!-- Applied applicants: job applied -->
                <template v-if="!selected?._isPotential">
                  <div class="section-label">Job Applied For</div>
                  <div class="applied-job-box">
                    <p class="applied-job">{{ selected?.jobApplied }}</p>
                    <p class="applied-employer">{{ selected?.employer }}</p>
                    <p class="applied-date">Applied {{ selected?.date }}</p>
                  </div>
                </template>

                <!-- Potential applicants: best matching job -->
                <template v-else>
                  <div class="section-label">Best Matching Listing</div>
                  <div class="applied-job-box">
                    <p class="applied-job">{{ selected?.bestFor }}</p>
                    <p class="applied-employer">{{ selected?.bestEmployer }}</p>
                    <p class="applied-date">Has not applied yet</p>
                  </div>
                  <template v-if="selected?.bestJobSkills?.length">
                    <div class="section-label" style="margin-top:14px;">Required Skills for This Listing</div>
                    <div class="skill-tags mt4">
                      <span v-for="sk in selected.bestJobSkills" :key="sk" :class="['skill-tag', selected.skills?.includes(sk) ? 'matched-tag' : 'missing-tag']">{{ sk }}</span>
                    </div>
                    <p style="font-size:11px;color:#94a3b8;margin-top:6px;">
                      <span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:#22c55e;margin-right:4px;"></span>Green = candidate has ·
                      <span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:#f1f5f9;border:1px solid #cbd5e1;margin-right:4px;margin-left:8px;"></span>White = missing
                    </p>
                  </template>
                </template>
              </div>

              <!-- Files Tab -->
              <div v-if="drawerTab === 'Files'">
                <div class="files-list">
                  <div v-for="file in fileList" :key="file.label" class="file-row">
                    <div class="file-icon-lg" :class="{ uploaded: selected?.files[file.key] }">
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                    </div>
                    <div class="file-info">
                      <p class="file-name">{{ file.label }}</p>
                      <p class="file-status">{{ selected?.files[file.key] ? 'Uploaded' : 'Not uploaded' }}</p>
                    </div>
                    <button v-if="selected?.files[file.key]" type="button" class="btn-view" @click.stop="viewApplicantDocument(file.key)">View</button>
                  </div>
                </div>
              </div>

              <!-- History Tab -->
              <div v-if="drawerTab === 'History'">
                <div v-if="historyLoading" class="history-loading">
                  <div v-for="i in 4" :key="i" class="skel" style="width:100%;height:56px;border-radius:10px;margin-bottom:10px;"></div>
                </div>
                <div v-else-if="history.length === 0" class="empty-state" style="padding:32px 16px;">
                  <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                  <p style="margin-top:12px;font-size:14px;color:#64748b;font-weight:600;">No activity yet</p>
                  <span style="font-size:12px;color:#94a3b8;">Events will appear here as this application progresses.</span>
                </div>
                <div v-else class="history-list">
                  <div v-for="log in history" :key="log.id" class="history-item">
                    <div class="history-dot" :class="historyClass(log.action)"></div>
                    <div class="history-content">
                      <div class="history-top">
                        <span class="history-action-chip" :class="historyClass(log.action)">{{ log.action }}</span>
                        <span class="history-time">{{ formatDateTime(log.created_at) }}</span>
                      </div>
                      <div class="history-actor">by <strong>{{ log.actor_label }}</strong></div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </transition>

      <!-- CONFIRMATION MODAL -->
      <transition name="modal-pop">
        <div v-if="confirmModal.show" class="modal-overlay" @click.self="confirmModal.show = false">
          <div class="cmodal">
            <div class="cmodal-strip blue"></div>
            <div class="cmodal-body">
              <div class="cmodal-icon blue"><svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg></div>
              <h3 class="cmodal-title">Send PESO Invitation?</h3>
              <p class="cmodal-desc">PESO will personally invite <strong>{{ confirmModal.name }}</strong> to apply. They will receive an email labeled "Invited by PESO".</p>
              <div v-if="confirmModal.jobTitle" class="cmodal-job-card">
                <div class="cj-title">{{ confirmModal.jobTitle }}</div>
                <div class="cj-meta">{{ confirmModal.employer }}</div>
                <div class="cj-score">
                  <div class="score-bar-bg" style="flex:1"><div class="score-bar-fill" :style="{ width: confirmModal.matchScore+'%', background: scoreColor(confirmModal.matchScore) }"></div></div>
                  <span class="score-val" :style="{ color: scoreColor(confirmModal.matchScore) }">{{ confirmModal.matchScore }}% match</span>
                </div>
                <div class="cj-invited-label">Invited By: <strong>PESO</strong></div>
              </div>
            </div>
            <div class="cmodal-footer">
              <button class="cmodal-cancel" @click="confirmModal.show = false">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                Cancel
              </button>
              <button class="cmodal-ok blue" @click="confirmModal.onConfirm">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="margin-right:6px"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
                Yes, Send as PESO
              </button>
            </div>
          </div>
        </div>
      </transition>
    </template>
  </div>
</template>

<script>
import api from '@/services/api'

const EDU_LABELS = {
  no_requirement: 'No Requirement', elementary: 'Elementary Graduate',
  highschool: 'High School Graduate', senior_highschool: 'Senior High School / K-12',
  vocational: 'Vocational / TESDA', college_level: 'At Least College Level',
  college_graduate: 'College Graduate', related_course: 'College Graduate (Related Course)',
  postgraduate: "Post-Graduate / Master's",
}
const COLORS = ['#2563eb','#f97316','#22c55e','#06b6d4','#a855f7','#ef4444','#3b82f6','#14b8a6']

export default {
  name: 'ApplicantsPage',
  async mounted() {
    // Fetch applied data + tab counts in parallel (awaited — blocks until ready)
    await Promise.all([
      this.fetchApplicants(),
      this.fetchTabCounts(),
    ])
    // Pre-fetch potential applicants in the background so the tab badge count
    // is correct immediately without blocking the applied tab from loading.
    this.fetchPotentialApplicants()
  },
  data() {
    return {
      // Main tabs
      mainTab: 'applied',
      // Applied
      search: '', filterStatus: '', filterSkill: '', filterDate: '',
      activeTab: 'all',
      applicants: [], currentPage: 1, lastPage: 1, totalApplicants: 0,
      loading: false, tabsLoading: true, pageLoading: false, searching: false,
      tabCounts: { all:0, reviewing:0, shortlisted:0, interview:0, for_job_offer:0, hired:0, rejected:0 },
      statusTabs: [
        { label:'All', value:'all', count:0 }, { label:'Reviewing', value:'reviewing', count:0 },
        { label:'Shortlisted', value:'shortlisted', count:0 }, { label:'Interview', value:'interview', count:0 },
        { label:'For Job Offer', value:'for_job_offer', count:0 },
        { label:'Hired', value:'hired', count:0 }, { label:'Rejected', value:'rejected', count:0 },
      ],
      skillOptions: ['Accounting','IT / Dev','Nursing','Electrical','Teaching','BPO','Welding','Driving'],
      // Potential
      potentialApplicants: [], potentialLoading: false,
      potentialSearchApplied: '', potentialPage: 1, potentialEmployerFilter: '',
      // Drawer
      drawerOpen: false, drawerTab: 'Profile', selected: null,
      drawerTabList: ['Profile', 'Files', 'History'],
      fileList: [
        { label:'Resume / CV', key:'resume' },
        { label:'Certificate / Diploma', key:'cert' },
        { label:'Barangay Clearance', key:'clearance' },
      ],
      history: [], historyLoading: false,
      // Confirm modal
      confirmModal: { show: false, name: '', jobTitle: '', employer: '', matchScore: 0, onConfirm: null },
      // Toast
      toast: { show: false, text: '', type: 'success', icon: '', _timer: null },
    }
  },
  computed: {
    paginationPages() {
      const pages = [], start = Math.max(1, this.currentPage-2), end = Math.min(this.lastPage, this.currentPage+2)
      for (let i = start; i <= end; i++) pages.push(i)
      return pages
    },
    filteredApplicants() { return this.applicants },
    filteredPotential() {
      let list = [...this.potentialApplicants]
      const q = (this.potentialSearchApplied || '').toLowerCase()
      if (q) list = list.filter(a =>
        a.name.toLowerCase().includes(q) ||
        a.skills.some(s => s.toLowerCase().includes(q)) ||
        (a.bestFor||'').toLowerCase().includes(q)
      )
      if (this.potentialEmployerFilter) {
        list = list.filter(a => a.bestEmployer === this.potentialEmployerFilter)
      }
      return list.sort((a, b) => b.score - a.score)
    },
    potentialTotalPages() { return Math.max(1, Math.ceil(this.filteredPotential.length / 15)) },
    pagedPotential() { const s = (this.potentialPage-1)*15; return this.filteredPotential.slice(s, s+15) },
    potentialEmployerOptions() {
      return [...new Set(this.potentialApplicants.map(a => a.bestEmployer).filter(Boolean))].sort()
    },
  },
  methods: {
    switchMainTab(tab) {
      this.mainTab = tab
      this.search = ''
      this.potentialSearchApplied = ''
      this.potentialEmployerFilter = ''
      this.potentialPage = 1
      if (tab === 'potential' && this.potentialApplicants.length === 0) {
        this.fetchPotentialApplicants()
      }
    },

    async applySearch() {
      this.searching = true
      if (this.mainTab === 'potential') {
        this.potentialSearchApplied = this.search
        this.potentialPage = 1
        this.potentialLoading = true
        await new Promise(r => setTimeout(r, 400))
        this.potentialLoading = false
      } else {
        // We no longer clear filters on text search so they can combine
        this.currentPage = 1
        await this.fetchApplicants(true)
      }
      this.searching = false
    },
    async applyDropdownFilter() {
      this.search = '';
      this.potentialSearchApplied = '';
      if (this.mainTab !== 'potential') {
        this.activeTab = this.filterStatus === '' ? 'all' : this.filterStatus
        this.currentPage = 1;
        await this.fetchApplicants(true);
      }
    },
    applyPotentialDropdownFilter() {
      this.search = ''
      this.potentialSearchApplied = ''
      this.potentialLoading = true
      setTimeout(() => {
        this.potentialPage = 1
        this.potentialLoading = false
      }, 400)
    },

    switchTab(tab) {
      this.activeTab = tab
      this.search = ''; 
      // Sync dropdown with active tab
      this.filterStatus = tab === 'all' ? '' : tab;
      this.filterSkill = ''; 
      this.filterDate = ''
      this.currentPage = 1
      this.fetchApplicants(true)
    },

    async fetchTabCounts() {
      this.tabsLoading = true
      try {
        const { data } = await api.get('/admin/applications/counts')
        const counts = data.data
        this.statusTabs.forEach(t => { 
          t.count = counts[t.value] ?? 0
          this.tabCounts[t.value] = counts[t.value] ?? 0
        })
      } catch (e) { console.error('fetchTabCounts error:', e) }
      finally { this.tabsLoading = false }
    },

    async fetchApplicants(isPaginating = false) {
      isPaginating ? (this.pageLoading = true) : (this.loading = true)
      try {
        const params = { page: this.currentPage }
        if (this.search)       params.search    = this.search
        if (this.filterStatus) params.status    = this.filterStatus
        if (this.filterSkill)  params.skill     = this.filterSkill
        if (this.filterDate)   params.date_from = this.filterDate
        if (this.activeTab !== 'all') params.status = this.activeTab

        const { data } = await api.get('/admin/applications', { params })
        const payload = data.data || {}
        this.currentPage = payload.current_page || 1
        this.lastPage    = payload.last_page    || 1
        this.totalApplicants = payload.total    || 0

        this.applicants = (payload.data || []).map((a, i) => {
          const js = a.jobseeker || {}, jl = a.job_listing || {}
          return {
            id: a.id,
            jobseekerId:  js.id ?? null,
            jobListingId: jl.id ?? null,
            name:        `${js.first_name||''} ${js.last_name||''}`.trim() || 'Unknown',
            location:    js.address || 'N/A', contact: js.contact || 'N/A',
            email:       js.email || 'N/A', sex: js.sex || '',
            dateOfBirth: js.date_of_birth || '',
            education:   EDU_LABELS[js.education_level] || js.education_level || 'N/A',
            experience:  js.job_experience || 'N/A',
            skills:      js.skills?.map(s => s.skill) || [],
            jobApplied:  jl.title || 'Unknown',
            employer:    jl.employer?.company_name || 'Unknown',
            date:        new Date(a.created_at || a.applied_at).toLocaleDateString('en-US', { month:'short', day:'numeric', year:'numeric' }),
            status:      (() => { const r = a.status || 'reviewing'; return {for_job_offer:'For Job Offer'}[r] || r.charAt(0).toUpperCase() + r.slice(1) })(),
            matchScore:  a.match_score || 0,
            avatarBg:    COLORS[i % COLORS.length],
            invited:     false,
            files: { resume: !!js.resume_path, cert: !!js.certificate_path, clearance: !!js.barangay_clearance_path },
          }
        })
      } catch (e) { console.error(e) }
      finally { this.loading = false; this.pageLoading = false }
    },

    async fetchPotentialApplicants() {
      this.potentialLoading = true
      try {
        const { data } = await api.get('/admin/potential-applicants', {
          params: this.search ? { search: this.search } : {}
        })
        const JOB_COLORS = ['#2563eb','#f97316','#22c55e','#06b6d4','#a855f7','#ef4444','#3b82f6','#14b8a6']
        const employerColorMap = {}
        let empColorIdx = 0
        this.potentialApplicants = (data.data || []).map((js, i) => {
          const emp = js.best_employer || ''
          if (emp && !employerColorMap[emp]) employerColorMap[emp] = JOB_COLORS[empColorIdx++ % JOB_COLORS.length]
          return {
            id:           js.id,
            name:         `${js.first_name||''} ${js.last_name||''}`.trim(),
            education:    EDU_LABELS[js.education_level] || js.education_display || js.education_level || '',
            contact:      js.contact || '',
            email:        js.email || '',
            sex:          js.sex || '',
            dateOfBirth:  js.date_of_birth || '',
            experience:   js.job_experience || '',
            skills:       (js.skills || []).map(s => s.skill || s),
            bestFor:      js.best_job_title,
            bestJobId:    js.best_job_id,
            bestEmployer: js.best_employer,
            bestJobSkills: js.best_job_skills || [],
            score:        js.match_score || 0,
            location:     js.address || 'N/A',
            color:        COLORS[i % COLORS.length],
            jobColor:     employerColorMap[emp] || JOB_COLORS[0],
            invited:      false,
          }
        })
      } catch (e) { console.error('fetchPotentialApplicants error:', e) }
      finally { this.potentialLoading = false }
    },

    changePage(page) {
      if (page >= 1 && page <= this.lastPage && !this.pageLoading) {
        this.currentPage = page; this.fetchApplicants(true)
      }
    },

    initials(name) { return (name||'').split(' ').map(n => n[0]).slice(0,2).join('').toUpperCase() },
    statusClass(s) { return { Reviewing:'reviewing', Shortlisted:'shortlisted', Interview:'interview', 'For Job Offer':'for-job-offer', Hired:'hired', Rejected:'rejected' }[s] || 'reviewing' },
    scoreColor(v) { return v >= 85 ? '#22c55e' : v >= 70 ? '#2872A1' : '#ef4444' },
    scoreBg(v)    { return v >= 85 ? '#f0fdf4' : v >= 70 ? '#eff8ff' : '#fef2f2' },

    historyClass(action) {
      const a = (action||'').toLowerCase()
      if (a.includes('invited'))   return 'invited'
      if (a === 'reviewing')       return 'reviewing'
      if (a === 'shortlisted')     return 'shortlisted'
      if (a === 'interview')       return 'interview'
      if (a === 'hired')               return 'hired'
      if (a.includes('for_job_offer')) return 'for_job_offer'
      if (a === 'rejected')            return 'rejected'
      return 'default'
    },

    openDrawer(applicant, isPotential) {
      this.selected  = { ...applicant, _isPotential: isPotential }
      this.drawerTab = 'Profile'
      this.history   = []
      this.drawerOpen = true
    },

    onDrawerTabChange(tab) {
      this.drawerTab = tab
      if (tab === 'History' && this.selected && !this.selected._isPotential) {
        this.fetchHistory(this.selected.id)
      }
    },

    async fetchHistory(applicationId) {
      this.historyLoading = true; this.history = []
      try {
        const { data } = await api.get(`/admin/applications/${applicationId}/history`)
        this.history = data.data || []
      } catch (e) { console.error('fetchHistory error:', e) }
      finally { this.historyLoading = false }
    },

    formatDate(d) {
      if (!d) return '—'
      const datePart = d.includes('T') ? d.split('T')[0] : d
      const date = new Date(datePart + 'T00:00:00')
      if (isNaN(date.getTime())) return 'Invalid Date'
      return date.toLocaleDateString('en-US', { year:'numeric', month:'long', day:'numeric' })
    },

    formatDateTime(iso) {
      if (!iso) return '—'
      const d = new Date(iso)
      if (isNaN(d.getTime())) return '—'
      return d.toLocaleDateString('en-US', { month:'short', day:'numeric', year:'numeric' }) +
             ' ' + d.toLocaleTimeString('en-US', { hour:'numeric', minute:'2-digit', hour12:true })
    },

    openInviteConfirm({ jobseekerId, jobListingId, name, matchScore, jobTitle, employer, _ref }) {
      if (!jobListingId) { this.showToastMsg('No job listing found.', 'error'); return }
      this.confirmModal = {
        show: true, name, jobTitle, employer, matchScore,
        onConfirm: () => { this.confirmModal.show = false; this.sendPesoInvite(jobseekerId, jobListingId, _ref) },
      }
    },

    async sendPesoInvite(jobseekerId, jobListingId, _ref) {
      try {
        await api.post(`/admin/invite/${jobseekerId}`, { job_listing_id: jobListingId })
        // Mark invited in applied list
        const idx = this.applicants.findIndex(a => a.jobseekerId === jobseekerId && a.jobListingId === jobListingId)
        if (idx !== -1) this.applicants[idx].invited = true
        // Mark invited in potential list
        const pidx = this.potentialApplicants.findIndex(a => a.id === jobseekerId)
        if (pidx !== -1) this.potentialApplicants[pidx].invited = true
        if (_ref) _ref.invited = true
        if (this.selected?.id === jobseekerId || this.selected?.jobseekerId === jobseekerId) this.selected.invited = true
        this.showToastMsg('PESO invitation sent!', 'success')
      } catch (e) {
        this.showToastMsg(e?.response?.data?.message || 'Failed to send invitation.', 'error')
      }
    },

    async viewApplicantDocument(fileKey) {
      const jid = this.selected?.jobseekerId
      if (!jid) { alert('Applicant record missing.'); return }
      const typeMap = { resume:'resume', cert:'certificate', clearance:'clearance' }
      try {
        const res = await api.get(`/admin/jobseekers/${jid}/documents/${typeMap[fileKey]}`, { responseType:'blob' })
        const url = URL.createObjectURL(new Blob([res.data], { type:'application/pdf' }))
        const win = window.open(url, '_blank', 'noopener,noreferrer')
        if (!win) alert('Pop-up blocked.')
        setTimeout(() => URL.revokeObjectURL(url), 120000)
      } catch (e) { alert('Could not open document.') }
    },

    showToastMsg(text, type = 'success') {
      const CHECK = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>`
      const X     = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`
      if (this.toast._timer) clearTimeout(this.toast._timer)
      this.toast = { show: true, text, type, icon: type==='success' ? CHECK : X, _timer: setTimeout(() => { this.toast.show = false }, 3500) }
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
@keyframes shimmer { 0% { background-position: -400px 0; } 100% { background-position: 400px 0; } }
.skel { background: linear-gradient(90deg,#f1f5f9 25%,#e2e8f0 50%,#f1f5f9 75%); background-size: 400px 100%; animation: shimmer 1.4s infinite linear; border-radius: 6px; flex-shrink: 0; }

.page { font-family: 'Plus Jakarta Sans', sans-serif; padding: 24px; background: #f8fafc; min-height: 100vh; display: flex; flex-direction: column; gap: 16px; }

/* FILTERS */
.filters-bar { display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; flex: 1; max-width: 360px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.search-btn { display: flex; align-items: center; gap: 6px; background: #2872A1; color: #fff; border: none; border-radius: 8px; padding: 8px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; white-space: nowrap; }
.search-btn:hover:not(:disabled) { background: #1a5f8a; }
.search-btn:disabled { opacity: 0.6; cursor: not-allowed; }
.filter-group { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }

/* MAIN TABS */
.main-tabs { display: flex; gap: 6px; background: #fff; border: 1px solid #f1f5f9; border-radius: 12px; padding: 5px; width: fit-content; }
.main-tab { display: flex; align-items: center; gap: 7px; padding: 8px 16px; border-radius: 9px; border: none; background: none; font-size: 13px; font-weight: 600; color: #64748b; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.main-tab:hover { background: #f8fafc; color: #1e293b; }
.main-tab.active { background: #eff8ff; color: #1a5f8a; }
.potential-tab.active { background: #faf5ff; color: #7c3aed; }
.main-count { font-size: 10.5px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }
.potential-count { background: #ede9fe; color: #7c3aed; }

/* STATUS TABS */
.status-tabs { display: flex; gap: 4px; }
.tab-btn { display: flex; align-items: center; gap: 6px; background: none; border: none; padding: 8px 14px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; border-radius: 8px; font-family: inherit; }
.tab-btn:hover { background: #f1f5f9; }
.tab-btn.active { background: #eff8ff; color: #2872A1; font-weight: 700; }
.tab-count { font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }
.tab-count.reviewing   { background: #dbeafe; color: #1d4ed8; }
.tab-count.shortlisted { background: #eff8ff; color: #1a5f8a; }
.tab-count.interview   { background: #ede9fe; color: #8B5CF6; }
.tab-count.hired       { background: #dcfce7; color: #16a34a; }
.tab-count.rejected    { background: #fef2f2; color: #ef4444; }

/* POTENTIAL NOTICE */
.potential-notice { background: #eff8ff; border: 1px solid #bae6fd; border-radius: 10px; padding: 11px 14px; font-size: 12.5px; color: #1a5f8a; display: flex; align-items: flex-start; gap: 8px; }

/* LISTING TABS (Potential) */
.listing-tabs { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.listing-tab { display: inline-flex; align-items: center; gap: 6px; font-size: 12px; font-weight: 600; color: #64748b; background: #fff; border: 1.5px solid #e2e8f0; border-radius: 8px; padding: 5px 12px; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.listing-tab:hover { border-color: #94a3b8; color: #1e293b; }
.listing-tab.active { color: #2872A1; border-color: #2872A1; background: #eff8ff; }
.ltab-count { font-size: 10px; font-weight: 700; background: #f1f5f9; color: #64748b; padding: 1px 6px; border-radius: 99px; }
.listing-match-cell { display: flex; align-items: center; gap: 9px; }
.listing-bar { width: 4px; height: 32px; border-radius: 99px; flex-shrink: 0; }

/* TABLE */
.table-card { background: #fff; border-radius: 14px; overflow: hidden; border: 1px solid #f1f5f9; }
.data-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.data-table thead tr { background: #f8fafc; }
.data-table th { text-align: left; padding: 11px 14px; font-size: 11px; font-weight: 700; color: #94a3b8; letter-spacing: 0.04em; text-transform: uppercase; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.table-row { cursor: pointer; transition: background 0.12s; }
.table-row:hover { background: #eff8ff; }
.data-table td { padding: 12px 14px; border-bottom: 1px solid #f8fafc; vertical-align: middle; }
.empty-state { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 48px 24px; text-align: center; color: #94a3b8; }
.empty-state p { margin: 12px 0 4px; font-size: 15px; font-weight: 600; color: #475569; }
.empty-state span { font-size: 13px; }

.person-cell { display: flex; align-items: center; gap: 10px; }
.avatar { width: 34px; height: 34px; border-radius: 50%; color: #fff; font-size: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.person-name { font-size: 13px; font-weight: 600; color: #1e293b; }
.person-meta { font-size: 11px; color: #94a3b8; margin-top: 1px; }
.skill-tags { display: flex; align-items: center; gap: 4px; flex-wrap: wrap; }
.skill-tag  { background: #eff6ff; color: #2563eb; font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
.matched-tag { background: #f0fdf4; color: #15803d; border: 1px solid #bbf7d0; }
.missing-tag { background: #fff; color: #64748b; border: 1px solid #e2e8f0; }
.skill-more { font-size: 11px; color: #94a3b8; }
.job-cell { color: #475569; font-size: 12.5px; }
.employer-cell { color: #64748b; font-size: 12px; }
.employer-badge { background: #f1f5f9; color: #475569; font-size: 11px; font-weight: 600; padding: 3px 9px; border-radius: 6px; white-space: nowrap; }
.date-cell { color: #94a3b8; font-size: 12px; white-space: nowrap; }
.score-cell { display: flex; align-items: center; gap: 8px; }
.score-bar-bg { width: 60px; height: 5px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.score-bar-fill { height: 100%; border-radius: 99px; }
.score-val { font-size: 12px; font-weight: 700; min-width: 38px; }
.loc-cell { display: flex; align-items: center; gap: 5px; font-size: 12px; color: #475569; white-space: nowrap; }
.not-applied-badge { display: inline-flex; align-items: center; gap: 6px; background: #fef9ec; color: #92400e; font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 99px; border: 1px solid #fde68a; white-space: nowrap; }
.na-dot { width: 6px; height: 6px; border-radius: 50%; background: #f59e0b; flex-shrink: 0; }

/* STATUS BADGES */
.status-badge { padding: 4px 10px; border-radius: 99px; font-size: 11px; font-weight: 600; white-space: nowrap; text-transform: capitalize; }
.status-badge.lg { padding: 5px 14px; font-size: 12px; }
.reviewing   { background: #dbeafe; color: #1d4ed8; }
.shortlisted { background: #eff8ff; color: #1a5f8a; }
.interview   { background: #ede9fe; color: #8B5CF6; }
.for-job-offer { background: #fef3c7; color: #92400e; }
.hired       { background: #dcfce7; color: #16a34a; }
.rejected    { background: #fef2f2; color: #ef4444; }

/* FILE ICONS */
.file-icons { display: flex; gap: 4px; }
.file-btn { width: 26px; height: 26px; border-radius: 6px; border: 1px solid #e2e8f0; background: #f8fafc; display: flex; align-items: center; justify-content: center; cursor: pointer; color: #cbd5e1; transition: all 0.15s; }
.file-btn.has { background: #eff6ff; border-color: #bfdbfe; color: #2563eb; }
.file-btn:hover { background: #eff6ff; border-color: #93c5fd; color: #2563eb; }

/* ACTION BUTTONS */
.action-btns { display: flex; gap: 4px; }
.act-btn { width: 28px; height: 28px; border-radius: 7px; border: none; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.15s; }
.act-btn.view { background: #eff6ff; color: #2563eb; }
.act-btn.view:hover { background: #dbeafe; }
.act-btn.invite-act { background: #f0fdf4; color: #16a34a; }
.act-btn.invite-act:hover:not(:disabled) { background: #16a34a; color: #fff; }
.act-btn.invite-act:disabled { background: #f0fdf4; color: #86efac; cursor: default; }

/* PAGINATION */
.pagination { display: flex; align-items: center; justify-content: space-between; padding: 14px 18px; border-top: 1px solid #f1f5f9; }
.page-info { font-size: 12px; color: #94a3b8; }
.page-btns { display: flex; gap: 4px; }
.page-btn { width: 30px; height: 30px; border-radius: 7px; border: 1px solid #e2e8f0; background: #fff; font-size: 12px; color: #64748b; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; transition: all 0.15s; }
.page-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.page-btn.active { background: #2872A1; color: #fff; border-color: #2872A1; }
.page-btn:hover:not(.active):not(:disabled) { background: #f8fafc; }

/* DRAWER */
.drawer-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.3); z-index: 100; display: flex; justify-content: flex-end; backdrop-filter: blur(2px); }
.drawer { width: 440px; height: 100vh; background: #fff; display: flex; flex-direction: column; overflow: hidden; box-shadow: -8px 0 32px rgba(0,0,0,0.12); }
.drawer-header { display: flex; align-items: center; gap: 12px; padding: 20px; border-bottom: 1px solid #f1f5f9; }
.drawer-avatar { width: 46px; height: 46px; border-radius: 50%; color: #fff; font-size: 16px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.drawer-title-wrap { flex: 1; }
.drawer-name { font-size: 16px; font-weight: 800; color: #1e293b; }
.drawer-loc  { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.drawer-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 16px; padding: 4px; border-radius: 6px; }
.drawer-close:hover { background: #f1f5f9; color: #1e293b; }
.match-banner { padding: 14px 20px; }
.match-info { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.match-label { font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; }
.match-val { font-size: 18px; font-weight: 800; }
.match-bar-bg { height: 6px; background: rgba(0,0,0,0.08); border-radius: 99px; overflow: hidden; }
.match-bar-fill { height: 100%; border-radius: 99px; }
.drawer-tabs { display: flex; border-bottom: 1px solid #f1f5f9; padding: 0 20px; }
.dtab { background: none; border: none; padding: 12px 16px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; font-family: inherit; border-bottom: 2px solid transparent; transition: all 0.15s; margin-bottom: -1px; }
.dtab.active { color: #2872A1; border-bottom-color: #2872A1; font-weight: 700; }
.drawer-body { flex: 1; overflow-y: auto; padding: 20px; }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 18px; }
.info-item { display: flex; flex-direction: column; gap: 3px; }
.info-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
.info-val   { font-size: 13px; font-weight: 500; color: #1e293b; }
.section-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.06em; margin: 16px 0 8px; }
.mt4 { margin-top: 4px; } .mt12 { margin-top: 12px; }
.applied-job-box { background: #f8fafc; border-radius: 10px; padding: 12px 14px; border: 1px solid #f1f5f9; }
.applied-job { font-size: 14px; font-weight: 700; color: #1e293b; }
.applied-employer { font-size: 12px; color: #64748b; margin-top: 3px; }
.applied-date { font-size: 11px; color: #94a3b8; margin-top: 2px; }
.btn-invite-full { width: 100%; background: #2872A1; color: #fff; border: none; border-radius: 10px; padding: 11px; font-size: 13px; font-weight: 700; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; transition: filter 0.15s; }
.btn-invite-full:hover:not(:disabled) { filter: brightness(1.1); }
.btn-invite-full:disabled { opacity: 0.5; cursor: not-allowed; }

/* FILES */
.files-list { display: flex; flex-direction: column; gap: 10px; }
.file-row { display: flex; align-items: center; gap: 12px; padding: 12px 14px; background: #f8fafc; border-radius: 10px; border: 1px solid #f1f5f9; }
.file-icon-lg { width: 38px; height: 38px; border-radius: 10px; background: #e2e8f0; display: flex; align-items: center; justify-content: center; color: #94a3b8; flex-shrink: 0; }
.file-icon-lg.uploaded { background: #dbeafe; color: #2563eb; }
.file-info { flex: 1; }
.file-name { font-size: 13px; font-weight: 600; color: #1e293b; }
.file-status { font-size: 11px; color: #94a3b8; margin-top: 2px; }
.btn-view { background: #eff6ff; color: #2563eb; border: none; border-radius: 7px; padding: 6px 12px; font-size: 12px; font-weight: 600; cursor: pointer; font-family: inherit; }

/* HISTORY — colored by action/status */
.history-list { display: flex; flex-direction: column; }
.history-item { display: flex; gap: 14px; padding: 14px 0; border-bottom: 1px solid #f8fafc; }
.history-item:last-child { border-bottom: none; }
.history-dot { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; margin-top: 6px; }
.history-dot.reviewing   { background: #3b82f6; }
.history-dot.shortlisted { background: #2872A1; }
.history-dot.interview   { background: #8b5cf6; }
.history-dot.for_job_offer { background: #d97706; }
.history-dot.hired       { background: #22c55e; }
.history-dot.rejected    { background: #ef4444; }
.history-dot.invited     { background: #f59e0b; }
.history-dot.default     { background: #94a3b8; }
.history-content { flex: 1; }
.history-top { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; margin-bottom: 4px; }
.history-action-chip { padding: 3px 10px; border-radius: 99px; font-size: 11px; font-weight: 700; white-space: nowrap; }
.history-action-chip.reviewing   { background: #dbeafe; color: #1d4ed8; }
.history-action-chip.shortlisted { background: #eff8ff; color: #2872A1; }
.history-action-chip.interview   { background: #ede9fe; color: #8B5CF6; }
.history-action-chip.for_job_offer { background: #fef3c7; color: #92400e; }
.history-action-chip.hired       { background: #dcfce7; color: #16a34a; }
.history-action-chip.rejected    { background: #fef2f2; color: #ef4444; }
.history-action-chip.invited     { background: #fef3c7; color: #d97706; }
.history-action-chip.default     { background: #f1f5f9; color: #64748b; }
.history-time { font-size: 11px; color: #94a3b8; }
.history-actor { font-size: 12px; color: #94a3b8; }
.history-actor strong { color: #475569; }
.history-loading { display: flex; flex-direction: column; gap: 10px; }

/* CONFIRMATION MODAL */
.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.5); z-index: 200; display: flex; align-items: center; justify-content: center; padding: 24px; backdrop-filter: blur(3px); }
.cmodal { background: #fff; border-radius: 20px; width: 100%; max-width: 400px; overflow: hidden; box-shadow: 0 24px 64px rgba(0,0,0,0.22); }
.cmodal-strip { height: 4px; }
.cmodal-strip.blue { background: linear-gradient(90deg,#16a34a,#22c55e); }
.cmodal-body { padding: 28px 26px 16px; display: flex; flex-direction: column; align-items: center; text-align: center; gap: 10px; }
.cmodal-icon { width: 58px; height: 58px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.cmodal-icon.blue { background: #dcfce7; color: #16a34a; border: 2px solid #bbf7d0; }
.cmodal-title { font-size: 16px; font-weight: 800; color: #1e293b; margin-top: 4px; }
.cmodal-desc  { font-size: 13px; color: #64748b; line-height: 1.65; max-width: 300px; }
.cmodal-job-card { background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 12px; padding: 14px 16px; text-align: left; width: 100%; margin-top: 4px; }
.cj-title { font-size: 14px; font-weight: 800; color: #14532d; margin-bottom: 3px; }
.cj-meta  { font-size: 12px; color: #16a34a; margin-bottom: 10px; }
.cj-score { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; }
.cj-score .score-bar-bg { flex: 1; }
.cj-invited-label { font-size: 11.5px; color: #64748b; }
.cj-invited-label strong { color: #16a34a; }
.cmodal-footer { display: flex; gap: 8px; padding: 16px 20px 22px; }
.cmodal-cancel { flex: 1; padding: 10px; border-radius: 10px; border: 1.5px solid #e2e8f0; background: #fff; font-size: 13px; font-weight: 600; color: #64748b; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; gap: 6px; }
.cmodal-cancel:hover { background: #f8fafc; }
.cmodal-ok { flex: 1.5; padding: 10px 14px; border-radius: 10px; border: none; font-size: 13px; font-weight: 700; color: #fff; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; }
.cmodal-ok.blue { background: linear-gradient(135deg,#064e3b,#16a34a); }
.cmodal-ok.blue:hover { filter: brightness(1.08); }

/* TOAST */
.toast { position: fixed; top: 20px; right: 24px; z-index: 9999; display: flex; align-items: center; gap: 10px; padding: 12px 18px; border-radius: 12px; font-size: 13px; font-weight: 600; box-shadow: 0 8px 30px rgba(0,0,0,0.12); min-width: 240px; max-width: 380px; font-family: 'Plus Jakarta Sans', sans-serif; }
.toast.success { background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; }
.toast.error   { background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; }
.toast-icon { display: flex; align-items: center; flex-shrink: 0; }
.toast-msg  { word-break: break-word; line-height: 1.4; }

/* TRANSITIONS */
.drawer-enter-active, .drawer-leave-active { transition: opacity 0.2s; }
.drawer-enter-active .drawer, .drawer-leave-active .drawer { transition: transform 0.25s cubic-bezier(0.4,0,0.2,1); }
.drawer-enter-from, .drawer-leave-to { opacity: 0; }
.drawer-enter-from .drawer, .drawer-leave-to .drawer { transform: translateX(100%); }
.modal-pop-enter-active { transition: all 0.22s cubic-bezier(0.34,1.56,0.64,1); }
.modal-pop-leave-active { transition: all 0.15s ease-in; }
.modal-pop-enter-from { opacity: 0; transform: scale(0.9); }
.modal-pop-leave-to   { opacity: 0; transform: scale(0.95); }
.spinner-search { width: 12px; height: 12px; flex-shrink: 0; border: 2px solid rgba(255,255,255,0.5); border-top-color: #fff; border-radius: 50%; display: inline-block; animation: spin-s 0.7s linear infinite; }
@keyframes spin-s { to { transform: rotate(360deg); } }
.toast-enter-active, .toast-leave-active { transition: all 0.3s cubic-bezier(0.4,0,0.2,1); }
.toast-enter-from, .toast-leave-to { opacity: 0; transform: translateY(-15px) scale(0.95); }
</style>