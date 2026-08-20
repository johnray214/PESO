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
    <template v-if="loading && !pageLoading">
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
            <input
              v-model="search"
              type="text"
              :placeholder="mainTab === 'potential' ? 'Search by name or skill…' : (mainTab === 'dole' ? 'Search DOLE applicant, program, school…' : 'Search applicant, skill, location…')"
              class="search-input"
              @keyup.enter="applySearch"
            />
          </div>
          <button type="button" class="search-btn" @click="applySearch" :disabled="pageLoading || potentialLoading || searching">
            <span v-if="searching" class="spinner-search"></span>
            <template v-else>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            </template>
            {{ searching ? 'Searching…' : 'Search' }}
          </button>
        </div>

        <!-- Applied & DOLE dropdown filters -->
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
        <button :class="['main-tab', { active: mainTab === 'applied' }]" @click="switchMainTab('applied')">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
          Applied Applicants <span class="main-count">{{ totalRegularApplicants }}</span>
        </button>

        <button :class="['main-tab', 'dole-tab', { active: mainTab === 'dole' }]" @click="switchMainTab('dole')">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>
          DOLE Programs <span class="main-count dole-count">{{ totalDoleApplicants }}</span>
        </button>

        <button :class="['main-tab', 'potential-tab', { active: mainTab === 'potential' }]" @click="switchMainTab('potential')">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
          Potential Applicants <span class="main-count potential-count">{{ potentialApplicants.length }}</span>
        </button>
      </div>

      <!-- ===== APPLIED VIEW (Regular Private / General Postings) ===== -->
      <template v-if="mainTab === 'applied'">
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
                  <td style="font-weight:600;color:#64748b;font-size:12px;padding-left:18px;">{{ totalApplicants - ((currentPage - 1) * 15) - index }}</td>
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
                  <td>
                    <div class="score-cell">
                      <div class="score-bar-bg"><div class="score-bar-fill" :style="{ width: a.matchScore+'%', background: scoreColor(a.matchScore) }"></div></div>
                      <span class="score-val" :style="{ color: scoreColor(a.matchScore) }">{{ a.matchScore }}%</span>
                    </div>
                  </td>
                  <td class="date-cell">{{ a.date }}</td>
                  <td>
                    <span class="status-badge" :class="statusClass(a.status)">
                      <span class="status-dot"></span>
                      {{ a.status }}
                    </span>
                  </td>
                  <td>
                    <div class="file-icons">
                      <button class="file-btn" :class="{ has: a.files.resume }" title="Resume"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg></button>
                      <button class="file-btn" :class="{ has: a.files.cert }" title="Certificate"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="6"/><path d="M15.477 12.89L17 22l-5-3-5 3 1.523-9.11"/></svg></button>
                      <button class="file-btn" :class="{ has: a.files.clearance }" title="Clearance"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></button>
                    </div>
                  </td>
                  <td>
                    <button class="act-btn view" title="View Details">
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

      <!-- ===== DOLE PROGRAMS VIEW (SPES, GIP, TUPAD, JobStart) ===== -->
      <template v-if="mainTab === 'dole'">
        <!-- DOLE Notice Banner -->
        <div class="dole-notice">
          <div class="dole-notice-icon">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="2"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>
          </div>
          <div class="dole-notice-text">
            <h4>DOLE &amp; PESO Government Employment Programs</h4>
            <p>Dedicated tracking for student employment (SPES), government internships (GIP), emergency work (TUPAD), and youth bridging (JobStart).</p>
          </div>
        </div>

        <!-- DOLE Program Filter Chips & Batch Interview Action -->
        <div class="dole-filter-action-bar">
          <div class="program-chips-bar">
            <button
              type="button"
              class="prog-chip"
              :class="{ active: selectedDoleProgram === '' }"
              @click="selectDoleProgram('')"
            >
              <span class="prog-chip-dot" style="background:#64748b;"></span>
              All DOLE Programs
              <span class="prog-chip-count">{{ totalDoleApplicants }}</span>
            </button>
            <button
              v-for="prog in doleProgramList"
              :key="prog.value"
              type="button"
              class="prog-chip"
              :class="{ active: selectedDoleProgram === prog.value }"
              :style="selectedDoleProgram === prog.value ? { background: prog.color, color: '#fff', borderColor: prog.color } : {}"
              @click="selectDoleProgram(prog.value)"
            >
              <span class="prog-chip-dot" :style="{ background: selectedDoleProgram === prog.value ? '#fff' : prog.color }"></span>
              {{ prog.label }}
              <span class="prog-chip-count" :style="selectedDoleProgram === prog.value ? { background: 'rgba(255,255,255,0.25)', color: '#fff' } : {}">
                {{ doleProgramCounts[prog.value] || 0 }}
              </span>
            </button>
          </div>

          <button type="button" class="btn-schedule-dole" @click="openDoleInterviewModal()">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
            Schedule Program Interview
          </button>
        </div>

        <!-- Status Tabs for DOLE -->
        <div class="status-tabs">
          <button v-for="tab in statusTabs" :key="tab.value" :class="['tab-btn', { active: activeTab === tab.value }]" @click="switchTab(tab.value)">
            {{ tab.label }}<span class="tab-count" :class="tab.value">{{ tab.count }}</span>
          </button>
        </div>

        <!-- Table for DOLE -->
        <div class="table-card" style="overflow-x: auto;">
          <template v-if="pageLoading">
            <div style="padding: 16px 20px;">
              <div v-for="i in 15" :key="i" class="skel" style="width: 100%; height: 48px; border-radius: 8px; margin-bottom: 8px;"></div>
            </div>
          </template>
          <template v-else>
            <table class="data-table" style="min-width: 920px;">
              <thead>
                <tr>
                  <th style="width:40px">No.</th>
                  <th>Applicant</th>
                  <th>DOLE Program</th>
                  <th>Position Applied</th>
                  <th>Skills</th>
                  <th style="width:110px">Match</th>
                  <th style="width:90px">Date</th>
                  <th style="width:90px">Status</th>
                  <th style="width:70px">Files</th>
                  <th style="width:60px">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(a, index) in filteredApplicants" :key="a.id" class="table-row" @click="openDrawer(a, false)">
                  <td style="font-weight:600;color:#64748b;font-size:12px;padding-left:18px;">{{ totalApplicants - ((currentPage - 1) * 15) - index }}</td>
                  <td>
                    <div class="person-cell">
                      <div class="avatar" :style="{ background: a.avatarBg }">{{ initials(a.name) }}</div>
                      <div>
                        <p class="person-name">{{ a.name }}</p>
                        <p class="person-meta">{{ a.education || a.location }}</p>
                      </div>
                    </div>
                  </td>
                  <td>
                    <span
                      class="program-badge"
                      :style="{ background: getProgramLightBg(a.program), color: getProgramColor(a.program), borderColor: getProgramColor(a.program) }"
                    >
                      {{ a.program || 'DOLE' }}
                    </span>
                  </td>
                  <td class="job-cell" style="font-weight:600; color:#1e293b;">{{ a.jobApplied }}</td>
                  <td>
                    <div class="skill-tags">
                      <span v-for="sk in a.skills.slice(0,2)" :key="sk" class="skill-tag">{{ sk }}</span>
                      <span v-if="a.skills.length > 2" class="skill-more">+{{ a.skills.length - 2 }}</span>
                    </div>
                  </td>
                  <td>
                    <div class="score-cell">
                      <div class="score-bar-bg"><div class="score-bar-fill" :style="{ width: a.matchScore+'%', background: scoreColor(a.matchScore) }"></div></div>
                      <span class="score-val" :style="{ color: scoreColor(a.matchScore) }">{{ a.matchScore }}%</span>
                    </div>
                  </td>
                  <td class="date-cell">{{ a.date }}</td>
                  <td>
                    <span class="status-badge" :class="statusClass(a.status)">
                      <span class="status-dot"></span>
                      {{ a.status }}
                    </span>
                  </td>
                  <td>
                    <div class="file-icons">
                      <button class="file-btn" :class="{ has: a.files.resume }" title="Resume"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg></button>
                      <button class="file-btn" :class="{ has: a.files.cert }" title="Certificate / Grades"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="6"/><path d="M15.477 12.89L17 22l-5-3-5 3 1.523-9.11"/></svg></button>
                      <button class="file-btn" :class="{ has: a.files.clearance }" title="Clearance"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></button>
                    </div>
                  </td>
                  <td>
                    <button class="act-btn view" title="View &amp; Manage">
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    </button>
                  </td>
                </tr>
                <tr v-if="filteredApplicants.length === 0 && !loading && !pageLoading">
                  <td colspan="10">
                    <div class="empty-state">
                      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/><path d="M11 8v2"/><path d="M11 14h.01"/></svg>
                      <p>No {{ selectedDoleProgram || 'DOLE program' }} applicants found</p>
                      <span>When students or jobseekers apply for {{ selectedDoleProgram || 'SPES, GIP, or TUPAD' }} listings, they will appear here.</span>
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
              <tr v-for="(a, index) in pagedPotential" :key="a.id + '-' + a.bestJobId" class="table-row" @click="openDrawer(a, true)">
                <td style="font-weight:600;color:#64748b;font-size:12px;padding-left:18px;">{{ filteredPotential.length - ((potentialPage - 1) * 15) - index }}</td>
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
                <td>
                  <div class="action-btns">
                    <button class="act-btn view" title="View">
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
              <span v-if="selected && !selected._isPotential" class="status-badge lg" :class="statusClass(selected.status)">
                <span class="status-dot"></span>
                {{ selected?.status }}
              </span>
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
              <button v-for="dt in drawerTabsFor(selected)" :key="dt" :class="['dtab', { active: drawerTab === dt }]" @click="onDrawerTabChange(dt)">{{ dt }}</button>
            </div>

            <div class="drawer-body">
              <!-- Profile Tab -->
              <div v-if="drawerTab === 'Profile'">
                <div class="info-grid">
                  <div class="info-item"><span class="info-label">Full Name</span><span class="info-val">{{ selected?.name }}</span></div>
                  <div class="info-item"><span class="info-label">Contact</span><span class="info-val">{{ selected?.contact || 'N/A' }}</span></div>
                  <div class="info-item" style="grid-column: 1 / -1;"><span class="info-label">Full Address</span><span class="info-val">{{ selected?.fullAddress || selected?.location || 'N/A' }}</span></div>
                  <div class="info-item"><span class="info-label">Email</span><span class="info-val">{{ selected?.email || 'N/A' }}</span></div>
                  <div class="info-item"><span class="info-label">Sex</span><span class="info-val" style="text-transform:capitalize;">{{ selected?.sex || 'Not specified' }}</span></div>
                  <div class="info-item"><span class="info-label">Date of Birth</span><span class="info-val">{{ selected?.dateOfBirth ? formatDate(selected.dateOfBirth) : 'Not specified' }}</span></div>
                  <div class="info-item"><span class="info-label">Education</span><span class="info-val">{{ selected?.education }}</span></div>
                  <div class="info-item" style="grid-column: 1 / -1;"><span class="info-label">Experience</span><span class="info-val">{{ selected?.experience || 'N/A' }}</span></div>
                </div>

                <div class="section-label">Skills</div>
                <div class="skill-tags mt4">
                  <span v-for="sk in selected?.skills" :key="sk" class="skill-tag">{{ sk }}</span>
                </div>

                <!-- Applied applicants: job applied -->
                <template v-if="!selected?._isPotential">
                  <div class="section-label">Job / Position Applied For</div>
                  <div class="applied-job-box">
                    <p class="applied-job">{{ selected?.jobApplied }}</p>
                    <p class="applied-employer">{{ selected?.employer }}</p>
                    <p class="applied-date">Applied {{ selected?.date }}</p>
                  </div>

                  <!-- Withdrawal details callout -->
                  <div v-if="selected?.withdrawalReason" class="withdrawal-box">
                    <div class="withdrawal-header">
                      <span class="withdrawal-tag"><i class="bi bi-info-circle-fill"></i> Withdrawn by Jobseeker</span>
                      <span v-if="selected.withdrawnAt" class="withdrawal-date">{{ selected.withdrawnAt }}</span>
                    </div>
                    <div class="withdrawal-detail"><strong>Reason:</strong> {{ selected.withdrawalReason }}</div>
                    <div v-if="selected.withdrawalNotes" class="withdrawal-detail"><strong>Note:</strong> "{{ selected.withdrawalNotes }}"</div>
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

              <!-- Status Tab (Exclusively for DOLE Program Applicants) -->
              <div v-if="drawerTab === 'Status' && isDoleApplicant(selected)">
                <div class="section-label">Update Status</div>
                <div class="status-options">
                  <button
                    v-for="st in statusOptionsFor(selected)"
                    :key="st"
                    :class="['status-option', statusClass(st), { active: selected?.status === st }]"
                    @click="selected.status = st"
                  >
                    <span class="status-dot"></span>
                    {{ st }}
                  </button>
                </div>

                <div class="section-label mt16">Internal Notes (Optional)</div>
                <textarea
                  class="notes-area"
                  placeholder="Add internal notes about this applicant (e.g. interview feedback, documentation status)…"
                  rows="4"
                  v-model="selected.notes"
                ></textarea>
                <button class="btn-blue-full mt12" @click="handleDrawerSave" :disabled="savingStatus">
                  <span v-if="savingStatus" class="spinner-action" style="margin-right:6px;"></span>
                  {{ savingStatus ? 'Saving…' : 'Save Changes' }}
                </button>
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

      <!-- CONFIRMATION MODAL (PESO Invite & Status Changes) -->
      <transition name="modal-pop">
        <div v-if="confirmModal.show" class="modal-overlay" @click.self="confirmModal.show = false">
          <div class="cmodal">
            <div class="cmodal-strip" :class="confirmModal.theme || 'blue'"></div>
            <div class="cmodal-body">
              <div class="cmodal-icon" :class="confirmModal.theme || 'blue'" v-html="confirmModal.icon"></div>
              <h3 class="cmodal-title">{{ confirmModal.title }}</h3>
              <p class="cmodal-desc">{{ confirmModal.desc }}</p>
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
              <button class="cmodal-ok" :class="confirmModal.theme || 'green'" @click="confirmModal.onConfirm" :disabled="inviting || savingStatus">
                <span v-if="inviting || savingStatus" class="spinner-invite"></span>
                <span v-else v-html="confirmModal.okHtml || 'Confirm'"></span>
              </button>
            </div>
          </div>
        </div>
      </transition>

      <!-- ═══════════ DOLE INTERVIEW MODAL ═══════════ -->
      <transition name="modal-pop">
        <div v-if="interviewModal.show" class="modal-overlay" @click.self="interviewModal.show = false">
          <div class="fancy-modal">
            <div class="fm-header purple-grad">
              <div class="fm-header-left">
                <div class="fm-hicon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                </div>
                <div>
                  <h3 class="fm-title">{{ interviewModal.isSingle ? 'Schedule Interview' : 'Schedule Program Interview' }}</h3>
                  <p class="fm-subtitle">
                    <template v-if="interviewModal.isSingle">
                      for <strong>{{ interviewModal.applicant?.name }}</strong> · {{ interviewModal.applicant?.program || interviewModal.applicant?.jobApplied || 'DOLE Program' }}
                    </template>
                    <template v-else>
                      Send interview details via Email &amp; Mobile Notifications
                    </template>
                  </p>
                </div>
              </div>
              <button class="fm-close" @click="interviewModal.show = false">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
              </button>
            </div>

            <div class="fm-body">
              <!-- Bulk-only: Target DOLE Program & Recipients Checklist -->
              <template v-if="!interviewModal.isSingle">
                <!-- Target DOLE Program -->
                <div class="fm-field">
                  <label class="fm-label">
                    <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>
                    DOLE Program
                  </label>
                  <select v-model="interviewModal.program" class="fm-input purple-focus" @change="onInterviewProgramChange">
                    <option value="ALL">All DOLE Programs</option>
                    <option value="SPES">SPES — Special Program for Employment of Students</option>
                    <option value="GIP">GIP — Government Internship Program</option>
                    <option value="TUPAD">TUPAD — Tulong Panghanapbuhay (Displaced Workers)</option>
                    <option value="JobStart">JobStart Philippines</option>
                  </select>
                </div>

                <!-- Recipient Selection Dropdown & Checklist -->
                <div class="fm-field">
                  <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:2px;">
                    <label class="fm-label">
                      <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                      Target Applicants ({{ selectedRecipientCount }} pending selected)
                    </label>
                    <button type="button" class="btn-text-link" @click="toggleSelectAllRecipients">
                      {{ interviewModal.sendToAll ? 'Choose Specific' : 'Select All (' + pendingRecipients.length + ')' }}
                    </button>
                  </div>

                  <!-- Recipient Selector Custom Dropdown / Multi-Select Box -->
                  <div class="recipients-box">
                    <div
                      class="recipient-item select-all-item"
                      :class="{ active: interviewModal.sendToAll }"
                      @click="toggleSelectAllRecipients"
                    >
                      <div class="check-box" :class="{ checked: interviewModal.sendToAll }">
                        <svg v-if="interviewModal.sendToAll" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="3.5"><polyline points="20 6 9 17 4 12"/></svg>
                      </div>
                      <div class="recipient-info">
                        <span class="recipient-name">All Pending {{ interviewModal.program === 'ALL' ? 'DOLE' : interviewModal.program }} Applicants</span>
                        <span class="recipient-sub">
                          Send to all {{ pendingRecipients.length }} pending candidate(s)
                          <template v-if="scheduledRecipients.length > 0">· {{ scheduledRecipients.length }} already scheduled</template>
                        </span>
                      </div>
                      <span class="badge-count">{{ pendingRecipients.length }}</span>
                    </div>

                    <!-- Individual Applicants List if not Send To All -->
                    <div v-if="!interviewModal.sendToAll" class="individual-recipients-list">
                      <div
                        v-for="cand in availableRecipients"
                        :key="cand.id"
                        class="recipient-item"
                        :class="{
                          active: isRecipientSelected(cand.id),
                          'already-scheduled-row': isAlreadyScheduled(cand)
                        }"
                        :title="isAlreadyScheduled(cand) ? 'Interview already scheduled — cannot be scheduled again.' : 'Click to select'"
                        @click="!isAlreadyScheduled(cand) && toggleRecipient(cand.id)"
                      >
                        <!-- If already scheduled, disabled checkmark -->
                        <div v-if="isAlreadyScheduled(cand)" class="check-box checked-disabled" title="Already scheduled">
                          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#7c3aed" stroke-width="3.5"><polyline points="20 6 9 17 4 12"/></svg>
                        </div>
                        <!-- Normal selectable checkbox -->
                        <div v-else class="check-box" :class="{ checked: isRecipientSelected(cand.id) }">
                          <svg v-if="isRecipientSelected(cand.id)" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="3.5"><polyline points="20 6 9 17 4 12"/></svg>
                        </div>

                        <div class="recipient-avatar" :style="{ background: cand.avatarBg }">
                          {{ initials(cand.name) }}
                        </div>
                        <div class="recipient-info">
                          <span class="recipient-name" :style="isAlreadyScheduled(cand) ? { color: '#64748b' } : {}">
                            {{ cand.name }}
                          </span>
                          <span class="recipient-sub">{{ cand.program }} · {{ cand.location }}</span>
                        </div>

                        <!-- Status badge -->
                        <span v-if="isAlreadyScheduled(cand)" class="scheduled-tag">
                          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" style="margin-right:3px"><polyline points="20 6 9 17 4 12"/></svg>
                          Already Scheduled
                        </span>
                        <span v-else class="status-pill" :class="statusClass(cand.status)">{{ cand.status }}</span>
                      </div>
                      <div v-if="availableRecipients.length === 0" class="no-recipients-msg">
                        No eligible applicants found for {{ interviewModal.program }}.
                      </div>
                    </div>
                  </div>
                </div>
              </template>

              <!-- Date & Time (2-column) -->
              <div class="fm-2col">
                <div class="fm-field">
                  <label class="fm-label">
                    <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                    Date
                  </label>
                  <input type="date" v-model="interviewModal.date" class="fm-input purple-focus" />
                </div>
                <div class="fm-field">
                  <label class="fm-label">
                    <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                    Time
                  </label>
                  <input type="time" v-model="interviewModal.time" class="fm-input purple-focus" />
                </div>
              </div>

              <!-- Format Pills -->
              <div class="fm-field">
                <label class="fm-label">
                  <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="23 7 16 12 23 17 23 7"/><rect x="1" y="5" width="15" height="14" rx="2"/></svg>
                  Interview Format
                </label>
                <div class="fm-pills">
                  <button
                    v-for="fmt in ['In-person', 'Online / Video Call', 'Phone Call']"
                    :key="fmt"
                    type="button"
                    :class="['fm-pill', 'purple-pill', { active: interviewModal.format === fmt }]"
                    @click="interviewModal.format = fmt"
                  >
                    {{ fmt }}
                  </button>
                </div>
              </div>

              <!-- Venue / Location -->
              <div class="fm-field">
                <label class="fm-label">
                  <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
                  Location / Venue / Video Link
                </label>
                <input
                  type="text"
                  v-model="interviewModal.location"
                  placeholder="e.g. 2nd Floor PESO Office, Santiago City Hall"
                  class="fm-input purple-focus"
                />
              </div>

              <!-- Interviewer / Officer -->
              <div class="fm-field">
                <label class="fm-label">
                  <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                  Interviewer / Officer Name
                </label>
                <input
                  type="text"
                  v-model="interviewModal.interviewer"
                  placeholder="e.g. DOLE Program Coordinator / PESO Officer"
                  class="fm-input purple-focus"
                />
              </div>

              <!-- Instructions -->
              <div class="fm-field">
                <label class="fm-label">Instructions / Requirements (Optional)</label>
                <textarea
                  v-model="interviewModal.instructions"
                  placeholder="e.g. Please bring original birth certificate, photocopy of grades, and valid school/gov ID."
                  rows="2"
                  class="fm-input purple-focus"
                  style="resize:vertical;"
                ></textarea>
              </div>

              <!-- Email & Notification Preview -->
              <div class="email-preview purple-preview">
                <div class="ep-head">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                  What the applicant{{ interviewModal.isSingle ? '' : 's' }} will receive (Email &amp; Mobile App)
                </div>
                <div class="ep-rows">
                  <div v-if="interviewModal.isSingle" class="ep-row">
                    <span class="ep-k">To</span>
                    <span class="ep-v">{{ interviewModal.applicant?.name }}</span>
                  </div>
                  <template v-else>
                    <div class="ep-row"><span class="ep-k">Recipients</span><span class="ep-v ep-chip purple-chip">{{ selectedRecipientSummary }}</span></div>
                    <div class="ep-row"><span class="ep-k">Program</span><span class="ep-v">{{ interviewModal.program === 'ALL' ? 'All DOLE Programs' : interviewModal.program }}</span></div>
                  </template>
                  <div class="ep-row"><span class="ep-k">Date</span><span class="ep-v ep-chip purple-chip">{{ interviewModal.date ? formatDate(interviewModal.date) : '—' }}</span></div>
                  <div class="ep-row"><span class="ep-k">Time</span><span class="ep-v ep-chip purple-chip">{{ interviewModal.time ? formatTime(interviewModal.time) : '—' }}</span></div>
                  <div class="ep-row"><span class="ep-k">Format</span><span class="ep-v">{{ interviewModal.format }}</span></div>
                  <div class="ep-row"><span class="ep-k">Location</span><span class="ep-v">{{ interviewModal.location || '—' }}</span></div>
                  <div class="ep-row"><span class="ep-k">Interviewer</span><span class="ep-v">{{ interviewModal.interviewer || '—' }}</span></div>
                </div>
              </div>
            </div>

            <div class="fm-footer">
              <button type="button" class="fm-cancel" @click="interviewModal.show = false">Cancel</button>
              <button
                type="button"
                class="fm-submit purple-btn"
                @click="submitDoleInterview"
                :disabled="submittingInterview || (!interviewModal.isSingle && selectedRecipientCount === 0) || !interviewModal.date || !interviewModal.time || !interviewModal.location || !interviewModal.interviewer"
              >
                <span v-if="submittingInterview" class="spinner-action" style="border-color:#fff;border-right-color:transparent;margin-right:7px;width:12px;height:12px;"></span>
                <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" style="margin-right:7px"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                {{ submittingInterview ? (interviewModal.isSingle ? 'Scheduling interview…' : 'Sending invitations…') : (interviewModal.isSingle ? 'Schedule & Send Email' : `Schedule & Send Invites (${selectedRecipientCount})`) }}
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

const DOLE_PROGRAMS = [
  {
    value: 'SPES',
    label: 'SPES',
    fullName: 'Special Program for Employment of Students',
    description: 'Youth and student employment support',
    color: '#8b5cf6',
    lightBg: '#f5f3ff',
  },
  {
    value: 'GIP',
    label: 'GIP',
    fullName: 'Government Internship Program',
    description: 'Public service internship for youth',
    color: '#2563eb',
    lightBg: '#eff6ff',
  },
  {
    value: 'TUPAD',
    label: 'TUPAD',
    fullName: 'Tulong Panghanapbuhay (Displaced Workers)',
    description: 'Community-based emergency employment',
    color: '#f97316',
    lightBg: '#fff7ed',
  },
  {
    value: 'JobStart',
    label: 'JobStart',
    fullName: 'JobStart Philippines',
    description: 'Youth employability enhancement',
    color: '#22c55e',
    lightBg: '#f0fdf4',
  },
]

export default {
  name: 'ApplicantsPage',
  async mounted() {
    await Promise.all([
      this.fetchApplicants(),
      this.fetchTabCounts(),
      this.fetchPotentialApplicants(),
    ])
  },
  data() {
    return {
      // Main tabs: 'applied' | 'dole' | 'potential'
      mainTab: 'applied',

      // Applied & Common filters
      search: '', filterStatus: '', filterSkill: '', filterDate: '',
      activeTab: 'all',
      applicants: [], currentPage: 1, lastPage: 1, totalApplicants: 0,
      totalRegularApplicants: 0, totalDoleApplicants: 0,
      loading: false, tabsLoading: true, pageLoading: false, searching: false,
      tabCounts: { all:0, reviewing:0, shortlisted:0, interview:0, for_job_offer:0, hired:0, rejected:0, withdrawn:0 },
      statusTabs: [
        { label:'All', value:'all', count:0 }, { label:'Reviewing', value:'reviewing', count:0 },
        { label:'Shortlisted', value:'shortlisted', count:0 }, { label:'Interview', value:'interview', count:0 },
        { label:'For Job Offer', value:'for_job_offer', count:0 },
        { label:'Hired', value:'hired', count:0 }, { label:'Rejected', value:'rejected', count:0 },
        { label:'Withdrawn', value:'withdrawn', count:0 },
      ],
      skillOptions: ['Accounting','IT / Dev','Nursing','Electrical','Teaching','BPO','Welding','Driving'],

      // DOLE Program Tab State
      selectedDoleProgram: '', // '' = all DOLE programs, or 'SPES', 'GIP', etc.
      doleProgramList: DOLE_PROGRAMS,
      doleProgramCounts: { SPES: 0, GIP: 0, TUPAD: 0, JobStart: 0 },

      // Potential
      potentialApplicants: [], potentialLoading: false,
      potentialSearchApplied: '', potentialPage: 1, potentialEmployerFilter: '',

      // Drawer
      drawerOpen: false, drawerTab: 'Profile', selected: null,
      drawerTabList: ['Profile', 'Files', 'History'],
      fileList: [
        { label:'Resume / CV', key:'resume' },
        { label:'Certificate / Grades / Form 137', key:'cert' },
        { label:'Barangay Clearance / Indigency', key:'clearance' },
      ],
      history: [], historyLoading: false,

      // Confirm modal
      confirmModal: { show: false, name: '', jobTitle: '', employer: '', matchScore: 0, onConfirm: null },
      inviting: false,
      savingStatus: false,

      // Toast
      toast: { show: false, text: '', type: 'success', icon: '', _timer: null },

      // DOLE Interview Modal
      interviewModal: {
        show: false,
        isSingle: false,
        applicant: null,
        program: 'ALL',
        sendToAll: true,
        selectedIds: [],
        date: '',
        time: '',
        format: 'In-person',
        location: '',
        interviewer: '',
        instructions: '',
      },
      submittingInterview: false,
      allDoleApplicantsForModal: [],
      modalApplicantsLoading: false,
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
    availableRecipients() {
      const prog = this.interviewModal.program
      const list = this.allDoleApplicantsForModal.length > 0
        ? this.allDoleApplicantsForModal
        : this.applicants
      
      // Exclude Hired and Rejected applicants from interview eligibility
      const eligibleList = list.filter(a => {
        const st = (a.status || '').toLowerCase()
        return st !== 'hired' && st !== 'rejected'
      })

      if (prog === 'ALL') {
        return eligibleList.filter(a => a.program)
      }
      return eligibleList.filter(a => a.program === prog)
    },
    pendingRecipients() {
      return this.availableRecipients.filter(a => !this.isAlreadyScheduled(a))
    },
    scheduledRecipients() {
      return this.availableRecipients.filter(a => this.isAlreadyScheduled(a))
    },
    selectedRecipientCount() {
      if (this.interviewModal.sendToAll) {
        return this.pendingRecipients.length
      }
      return this.interviewModal.selectedIds.filter(id => {
        const cand = this.availableRecipients.find(a => a.id === id)
        return cand && !this.isAlreadyScheduled(cand)
      }).length
    },
    selectedRecipientSummary() {
      if (this.interviewModal.sendToAll) {
        const prog = this.interviewModal.program === 'ALL' ? 'DOLE' : this.interviewModal.program
        return `All ${this.pendingRecipients.length} Pending ${prog} Applicant(s)`
      }
      const count = this.selectedRecipientCount
      if (count === 1) {
        const firstId = this.interviewModal.selectedIds.find(id => {
          const cand = this.availableRecipients.find(a => a.id === id)
          return cand && !this.isAlreadyScheduled(cand)
        })
        const first = this.availableRecipients.find(a => a.id === firstId)
        return first ? first.name : '1 Applicant'
      }
      return `${count} Applicants Selected`
    },
  },
  methods: {
    async switchMainTab(tab) {
      this.mainTab = tab
      this.search = ''
      this.potentialSearchApplied = ''
      this.potentialEmployerFilter = ''
      this.filterStatus = ''
      this.filterSkill = ''
      this.filterDate = ''
      this.activeTab = 'all'
      this.currentPage = 1
      this.potentialPage = 1

      if (tab === 'potential') {
        if (this.potentialApplicants.length === 0) {
          await this.fetchPotentialApplicants()
        }
      } else {
        await Promise.all([
          this.fetchApplicants(),
          this.fetchTabCounts(),
        ])
      }
    },

    async selectDoleProgram(prog) {
      this.selectedDoleProgram = prog
      this.search = ''
      this.filterStatus = ''
      this.activeTab = 'all'
      this.currentPage = 1
      await Promise.all([
        this.fetchApplicants(),
        this.fetchTabCounts(),
      ])
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
        this.currentPage = 1
        await this.fetchApplicants(true)
      }
      this.searching = false
    },

    async applyDropdownFilter() {
      this.search = ''
      this.potentialSearchApplied = ''
      if (this.mainTab !== 'potential') {
        this.activeTab = this.filterStatus === '' ? 'all' : this.filterStatus
        this.currentPage = 1
        await this.fetchApplicants(true)
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
      this.search = ''
      this.filterStatus = tab === 'all' ? '' : tab
      this.filterSkill = ''
      this.filterDate = ''
      this.currentPage = 1
      this.fetchApplicants(true)
    },

    async fetchTabCounts() {
      this.tabsLoading = true
      try {
        const params = {}
        if (this.mainTab === 'dole') {
          params.program = this.selectedDoleProgram || 'all_dole'
        } else if (this.mainTab === 'applied') {
          params.program = 'regular'
        }

        const { data } = await api.get('/admin/applications/counts', { params })
        const counts = data.data || {}
        this.statusTabs.forEach(t => { 
          t.count = counts[t.value] ?? 0
          this.tabCounts[t.value] = counts[t.value] ?? 0
        })
        this.totalApplicants = counts['all'] ?? this.totalApplicants
        if (counts.total_regular !== undefined) this.totalRegularApplicants = counts.total_regular
        if (counts.total_dole !== undefined) this.totalDoleApplicants = counts.total_dole
        if (counts.programs) {
          this.doleProgramCounts = {
            SPES: counts.programs.SPES || 0,
            GIP: counts.programs.GIP || 0,
            TUPAD: counts.programs.TUPAD || 0,
            JobStart: counts.programs.JobStart || 0,
          }
        }
      } catch (e) {
        console.error('fetchTabCounts error:', e)
      } finally {
        this.tabsLoading = false
      }
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

        if (this.mainTab === 'dole') {
          params.program = this.selectedDoleProgram || 'all_dole'
        } else if (this.mainTab === 'applied') {
          params.program = 'regular'
        }

        const { data } = await api.get('/admin/applications', { params })
        const payload = data.data || {}
        this.currentPage = payload.current_page || 1
        this.lastPage    = payload.last_page    || 1

        if (!this.search && !this.filterStatus && !this.filterSkill && !this.filterDate) {
          if (this.mainTab === 'dole') {
            if (!this.selectedDoleProgram) this.totalDoleApplicants = payload.total || 0
          } else if (this.mainTab === 'applied') {
            this.totalRegularApplicants = payload.total || 0
          }
          this.totalApplicants = payload.total || 0
        }

        this.applicants = (payload.data || []).map((a, i) => {
          const js = a.jobseeker || {}, jl = a.job_listing || {}
          const fullAddr = js.full_address || [js.street_address, js.barangay_name, js.city_name, js.province_name].filter(Boolean).join(', ') || js.address || 'N/A'
          return {
            id: a.id,
            jobseekerId:  js.id ?? null,
            jobListingId: jl.id ?? null,
            name:        `${js.first_name||''} ${js.last_name||''}`.trim() || 'Unknown',
            location:    fullAddr,
            fullAddress: fullAddr,
            contact:     js.contact || 'N/A',
            email:       js.email || 'N/A', sex: js.sex || '',
            dateOfBirth: js.date_of_birth || '',
            education:   EDU_LABELS[js.education_level] || js.education_level || 'N/A',
            experience:  js.job_experience || 'N/A',
            skills:      js.skills?.map(s => s.skill) || [],
            jobApplied:  jl.title || 'Unknown',
            employer:    jl.employer?.company_name || (jl.program ? 'Department of Labor and Employment' : 'PESO Santiago'),
            program:     jl.program || null,
            programBudget: jl.program_budget || null,
            programDuration: jl.program_duration || null,
            programTarget: jl.program_target || null,
            implementingAgency: jl.implementing_agency || null,
            date:        new Date(a.created_at || a.applied_at).toLocaleDateString('en-US', { month:'short', day:'numeric', year:'numeric' }),
            status:      (() => { const r = a.status || 'reviewing'; return {for_job_offer:'For Job Offer', withdrawn:'Withdrawn'}[r] || r.charAt(0).toUpperCase() + r.slice(1) })(),
            withdrawalReason: a.withdrawal_reason || null,
            withdrawalNotes:  a.withdrawal_notes || null,
            withdrawnAt:      a.withdrawn_at ? new Date(a.withdrawn_at).toLocaleDateString('en-US', { month:'short', day:'numeric', year:'numeric' }) : null,
            matchScore:  a.match_score || 0,
            avatarBg:    COLORS[i % COLORS.length],
            invited:     false,
            files: { resume: !!js.resume_path, cert: !!js.certificate_path, clearance: !!js.barangay_clearance_path },
          }
        })
      } catch (e) {
        console.error('fetchApplicants error:', e)
      } finally {
        this.loading = false
        this.pageLoading = false
      }
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
          const fullAddr = js.full_address || [js.street_address, js.barangay_name, js.city_name, js.province_name].filter(Boolean).join(', ') || js.address || 'N/A'
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
            location:     fullAddr,
            fullAddress:  fullAddr,
            color:        COLORS[i % COLORS.length],
            jobColor:     employerColorMap[emp] || JOB_COLORS[0],
            invited:      false,
          }
        })
      } catch (e) {
        console.error('fetchPotentialApplicants error:', e)
      } finally {
        this.potentialLoading = false
      }
    },

    changePage(page) {
      if (page >= 1 && page <= this.lastPage && !this.pageLoading) {
        this.currentPage = page
        this.fetchApplicants(true)
      }
    },

    initials(name) {
      return (name||'').split(' ').map(n => n[0]).slice(0,2).join('').toUpperCase()
    },

    statusClass(s) {
      const str = (s || '').toLowerCase().replace(/_/g, '-').replace(/\s+/g, '-')
      if (str === 'for-job-offer' || str === 'for_job_offer') return 'for-job-offer'
      return {
        reviewing: 'reviewing',
        shortlisted: 'shortlisted',
        interview: 'interview',
        'for-job-offer': 'for-job-offer',
        hired: 'hired',
        rejected: 'rejected',
        withdrawn: 'withdrawn'
      }[str] || 'reviewing'
    },
    scoreColor(v) { return v >= 85 ? '#22c55e' : v >= 70 ? '#2872A1' : '#ef4444' },
    scoreBg(v)    { return v >= 85 ? '#f0fdf4' : v >= 70 ? '#eff8ff' : '#fef2f2' },

    getProgramColor(prog) {
      const p = DOLE_PROGRAMS.find(d => d.value === prog)
      return p ? p.color : '#8b5cf6'
    },
    getProgramLightBg(prog) {
      const p = DOLE_PROGRAMS.find(d => d.value === prog)
      return p ? p.lightBg : '#f5f3ff'
    },
    getProgramFullLabel(prog) {
      const p = DOLE_PROGRAMS.find(d => d.value === prog)
      return p ? p.fullName : (prog || 'DOLE Program')
    },

    historyClass(action) {
      const a = (action || '').toLowerCase()
      if (a.includes('invited')) return 'invited'
      if (a.includes('for_job_offer') || a.includes('for job offer') || a.includes('job offer') || a.includes('offer')) return 'for_job_offer'
      if (a.includes('reviewing')) return 'reviewing'
      if (a.includes('shortlisted')) return 'shortlisted'
      if (a.includes('interview')) return 'interview'
      if (a.includes('hired')) return 'hired'
      if (a.includes('rejected')) return 'rejected'
      return 'default'
    },

    statusOptionsFor(applicant) {
      const base = ['Reviewing', 'Shortlisted', 'Interview', 'For Job Offer']
      if (applicant?.status === 'Hired') base.push('Hired')
      base.push('Rejected')
      return base
    },

    isDoleApplicant(applicant) {
      if (!applicant) return false
      return !!(
        this.mainTab === 'dole' ||
        applicant.program ||
        applicant.isDole ||
        applicant.jobListing?.program ||
        (applicant.employer && applicant.employer.toLowerCase().includes('labor and employment'))
      )
    },

    drawerTabsFor(applicant) {
      if (!applicant) return []
      if (applicant._isPotential) return ['Profile']
      if (this.isDoleApplicant(applicant)) {
        return ['Profile', 'Files', 'Status', 'History']
      }
      return ['Profile', 'Files', 'History']
    },

    onSelectDrawerStatus(st) {
      if (st === 'Interview') {
        if (this.isAlreadyScheduled(this.selected)) {
          this.showToastMsg('This applicant is already scheduled for an interview.', 'error')
          return
        }
        this.openDoleInterviewModal(this.selected)
      } else {
        this.selected.status = st
      }
    },

    handleDrawerSave() {
      if (!this.selected || this.selected._isPotential) return
      const origApplicant = this.applicants.find(a => a.id === this.selected.id)
      const oldStatus = (origApplicant?.status || '').toLowerCase().replace(/[_\s]/g, '-')
      const newStatus = (this.selected.status || '').toLowerCase().replace(/[_\s]/g, '-')

      if (newStatus === 'interview') {
        if (oldStatus === 'interview') {
          this.showToastMsg('This applicant is already scheduled for an interview.', 'error')
          return
        }
        this.openDoleInterviewModal(this.selected)
        return
      }

      if (newStatus === 'shortlisted' && oldStatus !== 'shortlisted') {
        this.confirmShortlist(this.selected)
        return
      }
      if (newStatus === 'for-job-offer' && oldStatus !== 'for-job-offer') {
        this.confirmPass(this.selected)
        return
      }
      if (newStatus === 'hired' && oldStatus !== 'hired') {
        this.confirmDirectHire(this.selected)
        return
      }
      if (newStatus === 'rejected' && oldStatus !== 'rejected') {
        this.confirmReject(this.selected)
        return
      }

      this.executeStatusUpdate(this.selected, this.selected.status)
    },

    confirmShortlist(applicant) {
      this.confirmModal = {
        show: true,
        theme: 'blue',
        title: 'Shortlist this applicant?',
        desc: `${applicant.name} will be marked as Shortlisted for ${applicant.jobApplied || 'this position'}.`,
        icon: `<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>`,
        okHtml: `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="margin-right:6px"><polyline points="20 6 9 17 4 12"/></svg>Yes, Shortlist`,
        onConfirm: () => {
          this.confirmModal.show = false
          this.executeStatusUpdate(applicant, 'shortlisted')
        }
      }
    },

    confirmPass(applicant) {
      this.confirmModal = {
        show: true,
        theme: 'blue',
        title: 'Move to For Job Offer?',
        desc: `${applicant.name} has passed the interview process and will be moved to For Job Offer.`,
        icon: `<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="12" cy="12" r="10"/><path d="M8 14s1.5 2 4 2 4-2 4-2"/><line x1="9" y1="9" x2="9.01" y2="9"/><line x1="15" y1="9" x2="15.01" y2="9"/></svg>`,
        okHtml: `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="margin-right:6px"><polyline points="20 6 9 17 4 12"/></svg>Yes, Move to Job Offer`,
        onConfirm: () => {
          this.confirmModal.show = false
          this.executeStatusUpdate(applicant, 'for_job_offer')
        }
      }
    },

    confirmDirectHire(applicant) {
      this.confirmModal = {
        show: true,
        theme: 'green',
        title: 'Mark as Hired?',
        desc: `${applicant.name} will be officially marked as Hired for ${applicant.jobApplied || 'this program'}.`,
        icon: `<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><polyline points="20 6 9 17 4 12"/></svg>`,
        okHtml: `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="margin-right:6px"><polyline points="20 6 9 17 4 12"/></svg>Yes, Mark as Hired`,
        onConfirm: () => {
          this.confirmModal.show = false
          this.executeStatusUpdate(applicant, 'hired')
        }
      }
    },

    confirmReject(applicant) {
      this.confirmModal = {
        show: true,
        theme: 'red',
        title: 'Reject this applicant?',
        desc: `${applicant.name} will be marked as Rejected. You can still adjust this manually if needed.`,
        icon: `<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`,
        okHtml: `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="margin-right:6px"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>Yes, Reject`,
        onConfirm: () => {
          this.confirmModal.show = false
          this.executeStatusUpdate(applicant, 'rejected')
        }
      }
    },

    async executeStatusUpdate(applicant, status) {
      this.savingStatus = true
      try {
        const rawStatus = status.toLowerCase().replace(/ /g, '_')
        await api.patch(`/admin/applications/${applicant.id}/status`, { status: rawStatus })
        
        const displayStatus = rawStatus === 'for_job_offer' ? 'For Job Offer' : 
                             (rawStatus.charAt(0).toUpperCase() + rawStatus.slice(1))
        
        applicant.status = displayStatus
        if (this.selected?.id === applicant.id) {
          this.selected.status = displayStatus
        }
        const idx = this.applicants.findIndex(a => a.id === applicant.id)
        if (idx !== -1) {
          this.applicants[idx].status = displayStatus
        }

        await this.fetchTabCounts()
        this.showToastMsg(`Status updated to ${displayStatus}`, 'success')
      } catch (e) {
        this.showToastMsg(e?.response?.data?.message || 'Failed to update status', 'error')
      } finally {
        this.savingStatus = false
      }
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
      this.historyLoading = true
      this.history = []
      try {
        const { data } = await api.get(`/admin/applications/${applicationId}/history`)
        this.history = data.data || []
      } catch (e) {
        console.error('fetchHistory error:', e)
      } finally {
        this.historyLoading = false
      }
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
        onConfirm: () => { this.sendPesoInvite(jobseekerId, jobListingId, _ref) },
      }
    },

    async sendPesoInvite(jobseekerId, jobListingId, _ref) {
      this.inviting = true
      try {
        await api.post(`/admin/invite/${jobseekerId}`, { job_listing_id: jobListingId })
        const idx = this.applicants.findIndex(a => a.jobseekerId === jobseekerId && a.jobListingId === jobListingId)
        if (idx !== -1) this.applicants[idx].invited = true
        const pidx = this.potentialApplicants.findIndex(a => a.id === jobseekerId)
        if (pidx !== -1) this.potentialApplicants[pidx].invited = true
        if (_ref) _ref.invited = true
        if (this.selected?.id === jobseekerId || this.selected?.jobseekerId === jobseekerId) this.selected.invited = true
        this.confirmModal.show = false
        this.showToastMsg('PESO invitation sent!', 'success')
      } catch (e) {
        this.showToastMsg(e?.response?.data?.message || 'Failed to send invitation.', 'error')
      } finally {
        this.inviting = false
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
      } catch (e) {
        alert('Could not open document.')
      }
    },

    isAlreadyScheduled(applicant) {
      if (!applicant) return false
      if (this.selected && applicant.id === this.selected.id) {
        const orig = this.applicants.find(a => a.id === applicant.id)
        const origSt = (orig?.status || '').toLowerCase().replace(/[_\s]/g, '-')
        return origSt === 'interview' || origSt === 'for-job-offer'
      }
      const st = (applicant.status || '').toLowerCase().replace(/[_\s]/g, '-')
      return st === 'interview' || st === 'for-job-offer'
    },

    openDoleInterviewModal(preselectedApplicant = null) {
      if (preselectedApplicant) {
        const orig = this.applicants.find(a => a.id === preselectedApplicant.id)
        const origSt = (orig?.status || preselectedApplicant.originalStatus || '').toLowerCase().replace(/[_\s]/g, '-')
        if (origSt === 'interview') {
          this.showToastMsg('This applicant is already scheduled for an interview.', 'error')
          return
        }
      }

      this.interviewModal.date = ''
      this.interviewModal.time = ''
      this.interviewModal.format = 'In-person'
      this.interviewModal.location = ''
      this.interviewModal.interviewer = ''
      this.interviewModal.instructions = ''

      if (preselectedApplicant) {
        this.interviewModal.isSingle = true
        this.interviewModal.applicant = preselectedApplicant
        this.interviewModal.program = preselectedApplicant.program || 'DOLE'
        this.interviewModal.sendToAll = false
        this.interviewModal.selectedIds = [preselectedApplicant.id]
      } else {
        this.interviewModal.isSingle = false
        this.interviewModal.applicant = null
        this.interviewModal.program = this.selectedDoleProgram || 'ALL'
        this.interviewModal.sendToAll = true
        this.interviewModal.selectedIds = []
        this.fetchDoleApplicantsForModal()
      }

      this.interviewModal.show = true
    },

    async fetchDoleApplicantsForModal() {
      this.modalApplicantsLoading = true
      try {
        const { data } = await api.get('/admin/applications', { params: { program: 'all_dole', per_page: 'all' } })
        let list = []
        if (Array.isArray(data.data)) {
          list = data.data
        } else if (data.data?.data && Array.isArray(data.data.data)) {
          list = data.data.data
        }
        const COLORS = ['#3b82f6','#10b981','#f59e0b','#ef4444','#8b5cf6','#06b6d4','#ec4899']
        this.allDoleApplicantsForModal = list.map((a, i) => {
          const js = a.jobseeker || {}, jl = a.job_listing || {}
          const fullAddr = js.full_address || [js.street_address, js.barangay_name, js.city_name, js.province_name].filter(Boolean).join(', ') || js.address || 'N/A'
          const rawStatus = a.status || 'reviewing'
          return {
            id: a.id,
            jobseekerId: a.jobseeker_id || js.id,
            name: `${js.first_name||''} ${js.last_name||''}`.trim() || 'Unknown',
            location: fullAddr,
            program: jl.program || 'DOLE',
            status: rawStatus === 'for_job_offer' ? 'For Job Offer' : (rawStatus.charAt(0).toUpperCase() + rawStatus.slice(1).replace(/_/g, ' ')),
            avatarBg: COLORS[i % COLORS.length],
          }
        })
      } catch (e) {
        console.error(e)
      } finally {
        this.modalApplicantsLoading = false
      }
    },

    onInterviewProgramChange() {
      if (this.interviewModal.sendToAll) {
        this.interviewModal.selectedIds = []
      } else {
        const validIds = new Set(this.pendingRecipients.map(r => r.id))
        this.interviewModal.selectedIds = this.interviewModal.selectedIds.filter(id => validIds.has(id))
      }
    },

    toggleSelectAllRecipients() {
      this.interviewModal.sendToAll = !this.interviewModal.sendToAll
      if (this.interviewModal.sendToAll) {
        this.interviewModal.selectedIds = []
      } else {
        this.interviewModal.selectedIds = this.pendingRecipients.map(r => r.id)
      }
    },

    toggleRecipient(id) {
      const cand = this.availableRecipients.find(a => a.id === id)
      if (this.isAlreadyScheduled(cand)) return
      this.interviewModal.sendToAll = false
      const idx = this.interviewModal.selectedIds.indexOf(id)
      if (idx > -1) {
        this.interviewModal.selectedIds.splice(idx, 1)
      } else {
        this.interviewModal.selectedIds.push(id)
      }
    },

    isRecipientSelected(id) {
      const cand = this.availableRecipients.find(a => a.id === id)
      if (this.isAlreadyScheduled(cand)) return false
      if (this.interviewModal.sendToAll) return true
      return this.interviewModal.selectedIds.includes(id)
    },

    formatTime(timeStr) {
      if (!timeStr) return '—'
      const [h, m] = timeStr.split(':')
      const hour = parseInt(h, 10)
      const ampm = hour >= 12 ? 'PM' : 'AM'
      const h12 = hour % 12 || 12
      return `${h12}:${m} ${ampm}`
    },

    async submitDoleInterview() {
      if (this.submittingInterview) return
      this.submittingInterview = true
      try {
        const payload = {
          all: this.interviewModal.sendToAll,
          program: this.interviewModal.program,
          application_ids: this.interviewModal.sendToAll ? undefined : this.interviewModal.selectedIds,
          interview_date: this.interviewModal.date,
          interview_time: this.interviewModal.time,
          interview_format: this.interviewModal.format,
          interview_location: this.interviewModal.location,
          interviewer_name: this.interviewModal.interviewer,
          instructions: this.interviewModal.instructions,
        }

        const { data } = await api.post('/admin/applications/schedule-interview', payload)
        this.showToastMsg(data.message || 'Interview scheduled and notifications sent!', 'success')
        this.interviewModal.show = false

        if (this.selected) {
          const isTargeted = this.interviewModal.sendToAll || this.interviewModal.selectedIds.includes(this.selected.id)
          if (isTargeted) {
            this.selected.status = 'Interview'
          }
        }

        await Promise.all([
          this.fetchApplicants(),
          this.fetchTabCounts(),
          this.fetchDoleApplicantsForModal(),
        ])
      } catch (e) {
        console.error('submitDoleInterview error:', e)
        const msg = e.response?.data?.message || 'Failed to schedule interview.'
        this.showToastMsg(msg, 'error')
      } finally {
        this.submittingInterview = false
      }
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
.dole-tab.active { background: #f5f3ff; color: #7c3aed; }
.potential-tab.active { background: #faf5ff; color: #7c3aed; }
.main-count { font-size: 10.5px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }
.dole-count { background: #ede9fe; color: #7c3aed; }
.potential-count { background: #ede9fe; color: #7c3aed; }

/* DOLE NOTICE */
.dole-notice { background: #faf5ff; border: 1px solid #e9d5ff; border-radius: 12px; padding: 12px 16px; display: flex; align-items: center; gap: 12px; }
.dole-notice-icon { width: 34px; height: 34px; border-radius: 9px; background: #ede9fe; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.dole-notice-text h4 { font-size: 13px; font-weight: 700; color: #581c87; margin-bottom: 2px; }
.dole-notice-text p { font-size: 12px; color: #7c3aed; }

/* PROGRAM CHIPS */
.program-chips-bar { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.prog-chip { display: inline-flex; align-items: center; gap: 6px; padding: 6px 12px; font-size: 12px; font-weight: 600; border-radius: 99px; border: 1.5px solid #e2e8f0; background: #fff; color: #475569; cursor: pointer; transition: all 0.15s; font-family: inherit; }
.prog-chip:hover { border-color: #cbd5e1; background: #f8fafc; }
.prog-chip.active { font-weight: 700; }
.prog-chip-dot { width: 7px; height: 7px; border-radius: 50%; }
.prog-chip-count { font-size: 10px; font-weight: 700; padding: 1px 6px; border-radius: 99px; background: #f1f5f9; color: #64748b; }
.program-badge { display: inline-flex; align-items: center; padding: 3px 9px; border-radius: 6px; font-size: 11px; font-weight: 700; border: 1px solid transparent; white-space: nowrap; }

/* STATUS TABS */
.status-tabs { display: flex; gap: 4px; flex-wrap: wrap; }
.tab-btn { display: flex; align-items: center; gap: 6px; background: none; border: none; padding: 8px 14px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; border-radius: 8px; font-family: inherit; }
.tab-btn:hover { background: #f1f5f9; }
.tab-btn.active { background: #eff8ff; color: #2872A1; font-weight: 700; }
.tab-count { font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }
.tab-count.reviewing     { background: #dbeafe; color: #1d4ed8; }
.tab-count.shortlisted   { background: #eff8ff; color: #1a5f8a; }
.tab-count.interview     { background: #ede9fe; color: #8B5CF6; }
.tab-count.for_job_offer,
.tab-count.for-job-offer { background: #fef3c7; color: #92400e; }
.tab-count.hired         { background: #dcfce7; color: #16a34a; }
.tab-count.rejected      { background: #fef2f2; color: #ef4444; }

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
.date-cell { color: #94a3b8; font-size: 12px; white-space: nowrap; }
.score-cell { display: flex; align-items: center; gap: 8px; }
.score-bar-bg { width: 60px; height: 5px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.score-bar-fill { height: 100%; border-radius: 99px; }
.score-val { font-size: 12px; font-weight: 700; min-width: 38px; }
.loc-cell { display: flex; align-items: center; gap: 5px; font-size: 12px; color: #475569; white-space: nowrap; }
.not-applied-badge { display: inline-flex; align-items: center; gap: 6px; background: #fef9ec; color: #92400e; font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 99px; border: 1px solid #fde68a; white-space: nowrap; }
.na-dot { width: 6px; height: 6px; border-radius: 50%; background: #f59e0b; flex-shrink: 0; }

/* STATUS BADGES */
.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 5.5px;
  padding: 4px 10px;
  border-radius: 9999px;
  font-size: 11px;
  font-weight: 700;
  white-space: nowrap;
  line-height: 1;
  letter-spacing: 0.01em;
}
.status-badge.lg { padding: 5px 12px; font-size: 12px; }
.status-dot { width: 6px; height: 6px; border-radius: 50%; flex-shrink: 0; }
.status-badge.lg .status-dot { width: 7px; height: 7px; }

.reviewing     { background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe; }
.reviewing     .status-dot { background: #3b82f6; }
.shortlisted   { background: #eff8ff; color: #1a5f8a; border: 1px solid #bae6fd; }
.shortlisted   .status-dot { background: #2872A1; }
.interview     { background: #faf5ff; color: #7c3aed; border: 1px solid #e9d5ff; }
.interview     .status-dot { background: #8b5cf6; }
.for-job-offer,
.for_job_offer { background: #fef3c7; color: #92400e; border: 1px solid #fde68a; }
.for-job-offer .status-dot,
.for_job_offer .status-dot { background: #d97706; }
.hired         { background: #f0fdf4; color: #15803d; border: 1px solid #bbf7d0; }
.hired         .status-dot { background: #22c55e; }
.rejected      { background: #fef2f2; color: #b91c1c; border: 1px solid #fecaca; }
.rejected      .status-dot { background: #ef4444; }
.withdrawn     { background: #f1f5f9; color: #475569; border: 1px solid #cbd5e1; }
.withdrawn     .status-dot { background: #64748b; }

.withdrawal-box { margin-top: 14px; padding: 12px 14px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; border-left: 3px solid #64748b; }
.withdrawal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
.withdrawal-tag { font-size: 11.5px; font-weight: 700; color: #475569; display: flex; align-items: center; gap: 5px; }
.withdrawal-date { font-size: 11px; color: #94a3b8; }
.withdrawal-detail { font-size: 12px; color: #334155; margin-top: 3px; line-height: 1.4; }

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

/* DOLE Card inside drawer */
.dole-card-box { background: #faf5ff; border: 1px solid #e9d5ff; border-radius: 12px; padding: 14px; margin-bottom: 16px; }
.dole-card-top { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; }
.dole-prog-full { font-size: 12px; font-weight: 700; color: #581c87; }
.dole-meta-list { display: flex; flex-direction: column; gap: 4px; font-size: 11.5px; border-top: 1px dashed #e9d5ff; padding-top: 8px; }
.dole-meta-row { display: flex; justify-content: space-between; }
.dm-label { color: #7c3aed; font-weight: 600; }
.dm-val { color: #1e293b; font-weight: 600; }

.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 18px; }
.info-item { display: flex; flex-direction: column; gap: 3px; }
.info-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
.info-val   { font-size: 13px; font-weight: 500; color: #1e293b; }
.section-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.06em; margin: 16px 0 8px; }
.mt4 { margin-top: 4px; }
.applied-job-box { background: #f8fafc; border-radius: 10px; padding: 12px 14px; border: 1px solid #f1f5f9; }
.applied-job { font-size: 14px; font-weight: 700; color: #1e293b; }
.applied-employer { font-size: 12px; color: #64748b; margin-top: 3px; }
.applied-date { font-size: 11px; color: #94a3b8; margin-top: 2px; }

/* STATUS TAB STYLES (Matching Employer Applicants design) */
.status-options { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.status-option {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  padding: 10px 14px;
  border-radius: 10px;
  border: 1.5px solid #e2e8f0;
  font-size: 12.5px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.15s;
  background: #f8fafc;
  color: #64748b;
}
.status-option .status-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #94a3b8;
  flex-shrink: 0;
}
.status-option:hover {
  border-color: #cbd5e1;
  background: #f1f5f9;
}
.status-option.active.reviewing   { background: #eff6ff; color: #1d4ed8; border-color: #3b82f6; }
.status-option.active.reviewing   .status-dot { background: #3b82f6; }
.status-option.active.shortlisted { background: #eff8ff; color: #1a5f8a; border-color: #2872A1; }
.status-option.active.shortlisted .status-dot { background: #2872A1; }
.status-option.active.interview   { background: #faf5ff; color: #7c3aed; border-color: #8b5cf6; }
.status-option.active.interview   .status-dot { background: #8b5cf6; }
.status-option.active.for-job-offer,
.status-option.active.for_job_offer { background: #fef3c7; color: #92400e; border-color: #d97706; }
.status-option.active.for-job-offer .status-dot,
.status-option.active.for_job_offer .status-dot { background: #d97706; }
.status-option.active.hired       { background: #f0fdf4; color: #15803d; border-color: #22c55e; }
.status-option.active.hired       .status-dot { background: #22c55e; }
.status-option.active.rejected    { background: #fef2f2; color: #b91c1c; border-color: #ef4444; }
.status-option.active.rejected    .status-dot { background: #ef4444; }

.notes-area { width: 100%; border: 1px solid #e2e8f0; border-radius: 10px; padding: 10px 12px; font-size: 13px; color: #1e293b; font-family: inherit; resize: vertical; outline: none; background: #f8fafc; }
.notes-area:focus { border-color: #2872A1; background: #fff; }
.btn-blue-full { width: 100%; background: #2872A1; color: #fff; border: none; border-radius: 10px; padding: 11px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; transition: background 0.15s; }
.btn-blue-full:hover:not(:disabled) { background: #1a5f8a; }
.btn-blue-full:disabled { opacity: 0.6; cursor: not-allowed; }
.mt12 { margin-top: 12px; }
.mt16 { margin-top: 16px; }

/* FILES */
.files-list { display: flex; flex-direction: column; gap: 10px; }
.file-row { display: flex; align-items: center; gap: 12px; padding: 12px 14px; background: #f8fafc; border-radius: 10px; border: 1px solid #f1f5f9; }
.file-icon-lg { width: 38px; height: 38px; border-radius: 10px; background: #e2e8f0; display: flex; align-items: center; justify-content: center; color: #94a3b8; flex-shrink: 0; }
.file-icon-lg.uploaded { background: #dbeafe; color: #2563eb; }
.file-info { flex: 1; }
.file-name { font-size: 13px; font-weight: 600; color: #1e293b; }
.file-status { font-size: 11px; color: #94a3b8; margin-top: 2px; }
.btn-view { background: #eff6ff; color: #2563eb; border: none; border-radius: 7px; padding: 6px 12px; font-size: 12px; font-weight: 600; cursor: pointer; font-family: inherit; }

/* HISTORY */
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
.history-action-chip.shortlisted { background: #eff8ff; color: #1a5f8a; }
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
.cmodal-strip.blue  { background: linear-gradient(90deg, #2872A1, #08BDDE); }
.cmodal-strip.red   { background: linear-gradient(90deg, #ef4444, #f97316); }
.cmodal-strip.green { background: linear-gradient(90deg, #10b981, #34d399); }
.cmodal-body { padding: 28px 26px 16px; display: flex; flex-direction: column; align-items: center; text-align: center; gap: 10px; }
.cmodal-icon { width: 58px; height: 58px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.cmodal-icon.blue  { background: #eff8ff; color: #2872A1; border: 2px solid #bae6fd; }
.cmodal-icon.red   { background: #fef2f2; color: #ef4444; border: 2px solid #fecaca; }
.cmodal-icon.green { background: #ecfdf5; color: #10b981; border: 2px solid #a7f3d0; }
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
.cmodal-ok { flex: 1.5; padding: 10px 14px; border-radius: 10px; border: none; font-size: 13px; font-weight: 700; color: #fff; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; gap: 7px; transition: filter 0.15s; }
.cmodal-ok.blue  { background: #2872A1; }
.cmodal-ok.blue:hover:not(:disabled)  { filter: brightness(1.08); }
.cmodal-ok.red   { background: #ef4444; }
.cmodal-ok.red:hover:not(:disabled)   { filter: brightness(1.08); }
.cmodal-ok.green { background: #10b981; }
.cmodal-ok.green:hover:not(:disabled) { filter: brightness(1.08); }
.cmodal-ok:disabled { opacity: 0.7; cursor: not-allowed; }
.spinner-invite { width: 13px; height: 13px; flex-shrink: 0; border: 2px solid rgba(255,255,255,0.45); border-top-color: #fff; border-radius: 50%; animation: spin-s 0.7s linear infinite; }

/* TOAST */
.toast { position: fixed; top: 20px; right: 24px; z-index: 9999; display: flex; align-items: center; gap: 10px; padding: 12px 18px; border-radius: 12px; font-size: 13px; font-weight: 600; box-shadow: 0 8px 30px rgba(0,0,0,0.12); min-width: 240px; max-width: 380px; font-family: 'Plus Jakarta Sans', sans-serif; }
.toast.success { background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; }
.toast.error   { background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; }
.toast-icon { display: flex; align-items: center; flex-shrink: 0; }
.toast-msg  { word-break: break-word; line-height: 1.4; }

/* DOLE Top Action Bar & Button */
.dole-filter-action-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
}
.btn-schedule-dole {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  padding: 8px 16px;
  border-radius: 10px;
  border: none;
  background: linear-gradient(135deg, #6d28d9 0%, #8b5cf6 100%);
  color: #fff;
  font-size: 12.5px;
  font-weight: 700;
  cursor: pointer;
  font-family: inherit;
  box-shadow: 0 4px 14px rgba(109,40,217,0.22);
  transition: all 0.15s;
  white-space: nowrap;
}
.btn-schedule-dole:hover {
  filter: brightness(1.08);
  transform: translateY(-1px);
  box-shadow: 0 6px 18px rgba(109,40,217,0.3);
}

/* ══════════════════════════════
   FANCY MODAL (Interview for DOLE)
══════════════════════════════ */
.fancy-modal {
  background: #fff;
  border-radius: 20px;
  width: 100%;
  max-width: 530px;
  max-height: 88vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 24px 64px rgba(0,0,0,0.22);
}
.fm-header {
  padding: 18px 20px 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-shrink: 0;
}
.purple-grad { background: linear-gradient(135deg, #4c1d95 0%, #7c3aed 100%); }
.fm-header-left { display: flex; align-items: center; gap: 13px; }
.fm-hicon {
  width: 42px;
  height: 42px;
  border-radius: 11px;
  background: rgba(255,255,255,0.18);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  flex-shrink: 0;
}
.fm-title { font-size: 16px; font-weight: 800; color: #fff; margin-bottom: 1px; }
.fm-subtitle { font-size: 12px; color: rgba(255,255,255,0.68); }
.fm-close {
  width: 28px;
  height: 28px;
  border-radius: 8px;
  background: rgba(255,255,255,0.15);
  border: none;
  color: rgba(255,255,255,0.75);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: all 0.15s;
}
.fm-close:hover { background: rgba(255,255,255,0.28); color: #fff; }

.fm-body {
  padding: 18px 20px;
  overflow-y: auto;
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.fm-body > * { flex-shrink: 0; }
.fm-field { display: flex; flex-direction: column; gap: 6px; }
.fm-label {
  font-size: 10.5px;
  font-weight: 700;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  display: flex;
  align-items: center;
  gap: 5px;
}
.fm-input {
  border: 1.5px solid #e2e8f0;
  border-radius: 10px;
  padding: 9px 12px;
  font-size: 13px;
  color: #1e293b;
  background: #f8fafc;
  font-family: inherit;
  outline: none;
  transition: border-color 0.15s, background 0.15s;
  width: 100%;
}
.fm-input:focus { background: #fff; }
.purple-focus:focus { border-color: #8b5cf6; }
.fm-2col { display: flex; gap: 11px; }
.fm-2col .fm-field { flex: 1; }
.fm-pills { display: flex; gap: 6px; flex-wrap: wrap; }
.fm-pill {
  padding: 6px 13px;
  border-radius: 99px;
  border: 1.5px solid #e2e8f0;
  background: #f8fafc;
  font-size: 12px;
  font-weight: 600;
  color: #64748b;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.15s;
}
.purple-pill:hover  { border-color: #8b5cf6; color: #7c3aed; }
.purple-pill.active { background: #faf5ff; border-color: #8b5cf6; color: #7c3aed; }
.btn-text-link {
  background: none;
  border: none;
  font-size: 11.5px;
  font-weight: 700;
  color: #7c3aed;
  cursor: pointer;
  padding: 0;
  font-family: inherit;
}
.btn-text-link:hover { text-decoration: underline; }

/* Recipients Selector Box */
.recipients-box {
  border: 1.5px solid #e2e8f0;
  border-radius: 12px;
  background: #f8fafc;
  overflow: hidden;
}
.recipient-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 9px 12px;
  cursor: pointer;
  transition: background 0.12s;
  border-bottom: 1px solid #f1f5f9;
  user-select: none;
}
.recipient-item:last-child { border-bottom: none; }
.recipient-item:hover { background: #f1f5f9; }
.recipient-item.active { background: #faf5ff; }
.select-all-item {
  background: #fff;
  border-bottom: 1.5px solid #e2e8f0;
  padding: 10px 12px;
}
.check-box {
  width: 18px;
  height: 18px;
  border-radius: 5px;
  border: 1.5px solid #cbd5e1;
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: all 0.12s;
}
.check-box.checked {
  background: #7c3aed;
  border-color: #7c3aed;
}
.recipient-avatar {
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
.recipient-info { flex: 1; min-width: 0; }
.recipient-name { font-size: 12.5px; font-weight: 700; color: #1e293b; display: block; }
.recipient-sub { font-size: 11px; color: #64748b; display: block; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.badge-count {
  font-size: 11px;
  font-weight: 700;
  background: #ede9fe;
  color: #6d28d9;
  padding: 2px 8px;
  border-radius: 99px;
}
.recipient-item.already-scheduled-row {
  background: #f8fafc;
  opacity: 0.72;
  cursor: not-allowed;
}
.recipient-item.already-scheduled-row:hover {
  background: #f8fafc;
}
.check-box.checked-disabled {
  background: #ede9fe;
  border-color: #c4b5fd;
  cursor: not-allowed;
}
.scheduled-tag {
  font-size: 11px;
  font-weight: 700;
  padding: 3px 8px;
  border-radius: 6px;
  background: #ede9fe;
  color: #6d28d9;
  border: 1px solid #ddd6fe;
  display: inline-flex;
  align-items: center;
  white-space: nowrap;
}
.interview-scheduled-badge-card {
  background: #faf5ff;
  border: 1.5px solid #ddd6fe;
  border-radius: 12px;
  padding: 12px 14px;
  display: flex;
  align-items: center;
  gap: 11px;
  margin-top: 12px;
}
.interview-scheduled-badge-card .is-icon {
  width: 34px;
  height: 34px;
  border-radius: 9px;
  background: #ede9fe;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.interview-scheduled-badge-card .is-title {
  font-size: 13px;
  font-weight: 700;
  color: #5b21b6;
  margin-bottom: 2px;
}
.interview-scheduled-badge-card .is-sub {
  font-size: 11.5px;
  color: #7c3aed;
  line-height: 1.35;
}
.btn-schedule-single {
  width: 100%;
  background: linear-gradient(135deg, #6d28d9 0%, #8b5cf6 100%);
  color: #fff;
  border: none;
  border-radius: 10px;
  padding: 11px 14px;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  font-family: inherit;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 7px;
  margin-top: 12px;
  box-shadow: 0 4px 12px rgba(109,40,217,0.2);
  transition: all 0.15s;
}
.btn-schedule-single:hover {
  filter: brightness(1.08);
}
.status-pill {
  font-size: 10.5px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 6px;
  text-transform: capitalize;
}
.status-pill.reviewing   { background: #eff6ff; color: #1d4ed8; }
.status-pill.shortlisted { background: #eff8ff; color: #1a5f8a; }
.status-pill.interview   { background: #faf5ff; color: #7c3aed; }
.status-pill.for-job-offer { background: #fef3c7; color: #92400e; }
.individual-recipients-list {
  max-height: 180px;
  overflow-y: auto;
}
.no-recipients-msg {
  padding: 16px;
  font-size: 12px;
  color: #94a3b8;
  text-align: center;
}

/* Email preview card */
.email-preview { border-radius: 12px; overflow: hidden; border: 1.5px solid; }
.purple-preview { border-color: #ddd6fe; }
.ep-head {
  padding: 9px 13px;
  font-size: 10.5px;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 6px;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}
.purple-preview .ep-head { background: #ede9fe; color: #6d28d9; }
.ep-row {
  display: flex;
  align-items: baseline;
  gap: 10px;
  padding: 7px 13px;
  border-bottom: 1px solid #f8fafc;
}
.ep-row:last-child { border-bottom: none; }
.ep-k { font-size: 11px; font-weight: 700; color: #94a3b8; min-width: 90px; flex-shrink: 0; }
.ep-v { font-size: 12px; color: #1e293b; font-weight: 600; }
.ep-chip { font-weight: 700; padding: 2px 8px; border-radius: 6px; font-size: 11.5px; }
.purple-chip { background: #ede9fe; color: #6d28d9; }

.fm-footer {
  padding: 14px 20px 18px;
  display: flex;
  gap: 10px;
  border-top: 1px solid #f1f5f9;
  flex-shrink: 0;
}
.fm-cancel {
  flex: 1;
  padding: 10px;
  border-radius: 10px;
  border: 1.5px solid #e2e8f0;
  background: #fff;
  font-size: 13px;
  font-weight: 600;
  color: #475569;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.15s;
}
.fm-cancel:hover { background: #f8fafc; }
.fm-submit {
  flex: 2.2;
  padding: 10px 16px;
  border-radius: 10px;
  border: none;
  font-size: 13px;
  font-weight: 700;
  color: #fff;
  cursor: pointer;
  font-family: inherit;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s;
}
.purple-btn { background: linear-gradient(135deg, #6d28d9, #8b5cf6); }
.purple-btn:hover:not(:disabled) { filter: brightness(1.08); }
.fm-submit:disabled { opacity: 0.6; cursor: not-allowed; }

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