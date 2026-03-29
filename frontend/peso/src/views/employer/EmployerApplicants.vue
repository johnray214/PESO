<template>
  <div class="layout-wrapper">
    <!-- Toast -->
    <transition name="toast">
      <div v-if="toast.show" class="toast" :class="toast.type">
        <span class="toast-icon" v-html="toast.icon"></span>
        <span class="toast-msg">{{ toast.text }}</span>
      </div>
    </transition>
    <EmployerSidebar />
    <div class="main-area">
      <EmployerTopbar title="Applicants" subtitle="Review and manage people who applied to your job listings" />
      <div class="page">

        <div v-if="isLoading">
          <div class="filters-bar skeleton" style="height: 52px; width: 100%; border-radius: 12px; margin-bottom: 16px;"></div>
          <div class="main-tabs skeleton" style="height: 42px; width: 400px; border-radius: 12px; margin-bottom: 16px;"></div>
          <div class="table-card skeleton" style="height: 500px; width: 100%; border-radius: 14px;"></div>
        </div>

        <div v-else>
          <!-- Filters -->
          <div class="filters-bar">
            <div class="search-box">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
              <input v-model="search" type="text" :placeholder="activeTab === 'potential' ? 'Search by name or skill…' : 'Search by name, skill, position…'" class="search-input"/>
            </div>
            <div class="filter-group">
              <template v-if="activeTab !== 'potential'">
                <select v-model="filterJob" class="filter-select"><option value="">All Positions</option><option v-for="j in jobOptions" :key="j" :value="j">{{ j }}</option></select>
                <select v-model="filterStatus" class="filter-select"><option value="">All Status</option><option value="Reviewing">Reviewing</option><option value="Shortlisted">Shortlisted</option><option value="Interview">Interview</option><option value="Hired">Hired</option><option value="Rejected">Rejected</option></select>
              </template>
              <template v-else>
                <select v-model="potentialJobFilter" @change="potentialPage = 1" class="filter-select"><option value="">All Job Listings</option><option v-for="j in jobOptions" :key="j" :value="j">{{ j }}</option></select>
              </template>
            </div>
          </div>

          <!-- Main Tabs -->
          <div class="main-tabs">
            <button :class="['main-tab', { active: activeTab !== 'potential' }]" @click="activeTab = activeStatusTab">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
              Applied Applicants <span class="main-count">{{ applicants.length }}</span>
            </button>
            <button :class="['main-tab', 'potential-tab', { active: activeTab === 'potential' }]" @click="activeTab = 'potential'">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
              Potential Applicants <span class="main-count potential-count">{{ potentialApplicants.length }}</span>
            </button>
          </div>

          <!-- ===== APPLIED VIEW ===== -->
          <template v-if="activeTab !== 'potential'">
            <div class="status-tabs">
              <button v-for="tab in statusTabs" :key="tab.value" :class="['tab-btn', { active: activeTab === tab.value }]" @click="activeTab = tab.value; activeStatusTab = tab.value">
                {{ tab.label }}<span class="tab-count" :class="tab.cls">{{ tab.count }}</span>
              </button>
            </div>
            <div class="table-card">
              <table class="data-table">
                <thead><tr><th>No.</th><th>Applicant</th><th>Skills</th><th>Applied For</th><th>Applied Date</th><th>Match Score</th><th>Status</th><th>Actions</th></tr></thead>
                <tbody>
                  <tr v-for="(a, index) in pagedApplicants" :key="a.id" class="table-row" @click="openDrawer(a)">
                    <td @click.stop style="font-weight:600;color:#64748b;font-size:12px;padding-left:18px;">{{ (appliedPage - 1) * perPage + index + 1 }}</td>
                    <td><div class="person-cell"><div class="avatar" :style="{ background: a.avatarBg }">{{ a.name[0] }}</div><div><p class="person-name">{{ a.name }}</p><p class="person-meta">{{ a.location }}</p></div></div></td>
                    <td><div class="skill-tags"><span v-for="sk in a.skills.slice(0,2)" :key="sk" class="skill-tag">{{ sk }}</span><span v-if="a.skills.length > 2" class="skill-more">+{{ a.skills.length - 2 }}</span></div></td>
                    <td class="job-cell">{{ a.jobApplied }}</td>
                    <td class="date-cell">{{ a.date }}</td>
                    <td @click.stop><div class="score-cell"><div class="score-bar-bg"><div class="score-bar-fill" :style="{ width: a.matchScore + '%', background: scoreColor(a.matchScore) }"></div></div><span class="score-val" :style="{ color: scoreColor(a.matchScore) }">{{ a.matchScore }}%</span></div></td>
                    <td @click.stop><span class="status-badge" :class="statusClass(a.status)">{{ a.status }}</span></td>
                    <td @click.stop>
                      <div class="action-btns">
                        <button class="act-btn view" @click="openDrawer(a)" title="View"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg></button>
                        <button v-if="a.status !== 'Hired' && a.status !== 'Rejected'" class="act-btn advance" :class="advanceBtnClass(a.status)" @click.stop="confirmAdvance(a)" :disabled="updatingStatusId === a.id" :title="advanceTitle(a.status)">
                          <span v-if="updatingStatusId === a.id" class="spinner-action"></span>
                          <template v-else>
                            <svg v-if="a.status === 'Reviewing'" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><polyline points="20 6 9 17 4 12"/></svg>
                            <svg v-else-if="a.status === 'Shortlisted'" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                            <svg v-else-if="a.status === 'Interview'" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>
                          </template>
                        </button>
                        <button v-if="a.status !== 'Hired' && a.status !== 'Rejected'" class="act-btn reject" @click.stop="confirmReject(a)" :disabled="updatingStatusId === a.id" title="Reject">
                          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                        </button>
                      </div>
                    </td>
                  </tr>
                  <tr v-if="pagedApplicants.length === 0"><td colspan="8" class="empty-cell">No applicants found.</td></tr>
                </tbody>
              </table>
              <div class="pagination">
                <span class="page-info">Showing {{ filteredApplicants.length === 0 ? 0 : (appliedPage - 1) * perPage + 1 }}–{{ Math.min(appliedPage * perPage, filteredApplicants.length) }} of {{ filteredApplicants.length }} applicants</span>
                <div class="page-btns">
                  <button class="page-btn" :disabled="appliedPage === 1" @click="appliedPage--">‹</button>
                  <button v-for="p in appliedTotalPages" :key="p" class="page-btn" :class="{ active: appliedPage === p }" @click="appliedPage = p">{{ p }}</button>
                  <button class="page-btn" :disabled="appliedPage === appliedTotalPages" @click="appliedPage++">›</button>
                </div>
              </div>
            </div>
          </template>

          <!-- ===== POTENTIAL VIEW ===== -->
          <template v-if="activeTab === 'potential'">
            <div class="potential-notice"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2" style="flex-shrink:0;margin-top:1px"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>These are registered jobseekers whose skills match your active listings — but <strong>&nbsp;have not applied yet</strong>.</div>
            <div class="listing-tabs">
              <button class="listing-tab" :class="{ active: potentialJobFilter === '' }" @click="potentialJobFilter = ''; potentialPage = 1">All <span class="ltab-count">{{ potentialApplicants.length }}</span></button>
              <button v-for="j in jobOptions" :key="j" class="listing-tab" :class="{ active: potentialJobFilter === j }" @click="potentialJobFilter = j; potentialPage = 1">{{ j }} <span class="ltab-count">{{ potentialApplicants.filter(a => a.bestFor === j).length }}</span></button>
            </div>
            <div class="table-card">
              <table class="data-table">
                <thead><tr><th>Jobseeker</th><th>Matched Skills</th><th>Matches Your Listing</th><th>Skill Match Score</th><th>Location</th><th>Status</th><th>Actions</th></tr></thead>
                <tbody>
                  <tr v-for="a in pagedPotential" :key="a.name" class="table-row" style="cursor:pointer;" @click="openPotentialDrawer(a)">
                    <td><div class="person-cell"><div class="avatar" :style="{ background: a.color }">{{ a.name[0] }}</div><div><p class="person-name">{{ a.name }}</p><p class="person-meta">{{ a.education }}</p></div></div></td>
                    <td><div class="skill-tags"><span v-for="sk in a.skills" :key="sk" class="skill-tag matched-tag">{{ sk }}</span></div></td>
                    <td><div class="listing-match-cell"><div class="listing-bar" :style="{ background: a.jobColor }"></div><div><p class="person-name" style="font-size:12.5px">{{ a.bestFor }}</p><p class="person-meta">Active listing</p></div></div></td>
                    <td><div class="score-cell"><div class="score-bar-bg"><div class="score-bar-fill" :style="{ width: a.score + '%', background: scoreColor(a.score) }"></div></div><span class="score-val" :style="{ color: scoreColor(a.score) }">{{ a.score }}%</span></div></td>
                    <td><div class="loc-cell"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>{{ a.location }}</div></td>
                    <td><span class="not-applied-badge"><span class="na-dot"></span>Not Applied</span></td>
                    <td><div class="action-btns">
                      <button class="act-btn view" @click.stop="openPotentialDrawer(a)"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg></button>
                      <button class="act-btn invite-act" @click.stop="confirmSendInvite(a)" :disabled="a.invited">
                        <svg v-if="!a.invited" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
                        <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
                      </button>
                    </div></td>
                  </tr>
                  <tr v-if="pagedPotential.length === 0"><td colspan="7" class="empty-cell">No jobseekers match your current filters.</td></tr>
                </tbody>
              </table>
              <div class="pagination">
                <span class="page-info">Showing {{ filteredPotential.length === 0 ? 0 : (potentialPage - 1) * perPage + 1 }}–{{ Math.min(potentialPage * perPage, filteredPotential.length) }} of {{ filteredPotential.length }} potential applicants</span>
                <div class="page-btns">
                  <button class="page-btn" :disabled="potentialPage === 1" @click="potentialPage--">‹</button>
                  <button v-for="p in potentialTotalPages" :key="p" class="page-btn" :class="{ active: potentialPage === p }" @click="potentialPage = p">{{ p }}</button>
                  <button class="page-btn" :disabled="potentialPage === potentialTotalPages" @click="potentialPage++">›</button>
                </div>
              </div>
            </div>
          </template>
        </div>
      </div>
    </div>

    <!-- DRAWER -->
    <transition name="drawer">
      <div v-if="drawerOpen" class="drawer-overlay" @click.self="drawerOpen = false">
        <div class="drawer">
          <div class="drawer-header">
            <div class="drawer-avatar" :style="{ background: selected?.avatarBg }">{{ selected?.name[0] }}</div>
            <div class="drawer-title-wrap"><h2 class="drawer-name">{{ selected?.name }}</h2><p class="drawer-loc">{{ selected?.location }} · {{ selected?.jobApplied }}</p></div>
            <span v-if="!selected?._isPotential" class="status-badge" :class="statusClass(selected?.status)">{{ selected?.status }}</span>
            <button class="drawer-close" @click="drawerOpen = false">✕</button>
          </div>
          <div class="match-banner" :style="{ background: scoreBg(selected?.matchScore) }">
            <div class="match-info"><span class="match-label">Match Score</span><span class="match-val" :style="{ color: scoreColor(selected?.matchScore) }">{{ selected?.matchScore }}%</span></div>
            <div class="match-bar-bg"><div class="match-bar-fill" :style="{ width: selected?.matchScore + '%', background: scoreColor(selected?.matchScore) }"></div></div>
          </div>
          <div class="drawer-tabs">
            <button v-for="dt in (selected?._isPotential ? ['Profile'] : ['Profile', 'Resume', 'Status'])" :key="dt" :class="['dtab', { active: drawerTab === dt }]" @click="drawerTab = dt">{{ dt }}</button>
          </div>
          <div class="drawer-body">
            <div v-if="drawerTab === 'Profile'">
              <div class="info-grid">
                <div class="info-item"><span class="info-label">Full Name</span><span class="info-val">{{ selected?.name }}</span></div>
                <div class="info-item"><span class="info-label">Location</span><span class="info-val">{{ selected?.location }}</span></div>
                <div class="info-item"><span class="info-label">Contact</span><span class="info-val">{{ selected?.contact }}</span></div>
                <div class="info-item"><span class="info-label">Email</span><span class="info-val">{{ selected?.email }}</span></div>
                <div class="info-item"><span class="info-label">Sex</span><span class="info-val" style="text-transform: capitalize;">{{ selected?.sex || 'Not specified' }}</span></div>
                <div class="info-item"><span class="info-label">Date of Birth</span><span class="info-val">{{ selected?.dateOfBirth ? formatDate(selected.dateOfBirth) : 'Not specified' }}</span></div>
                <div class="info-item"><span class="info-label">Education</span><span class="info-val">{{ selected?.education }}</span></div>
                <div class="info-item"><span class="info-label">Experience</span><span class="info-val">{{ selected?.experience }}</span></div>
              </div>
              <div class="section-label">Skills</div>
              <div class="skill-tags mt4"><span v-for="sk in selected?.skills" :key="sk" class="skill-tag">{{ sk }}</span></div>
              <!-- For actual applicants show applied date; for potential show best matching listing -->
              <template v-if="!selected?._isPotential">
                <div class="section-label">Applied Position</div>
                <div class="applied-box"><p class="applied-job">{{ selected?.jobApplied }}</p><p class="applied-date">Applied {{ selected?.date }}</p></div>
              </template>
              <template v-else>
                <div class="section-label">Best Matching Listing</div>
                <div class="applied-box"><p class="applied-job">{{ selected?.jobApplied || selected?.bestFor }}</p><p class="applied-date">Has not applied yet</p></div>
                <template v-if="selected?.bestJobSkills?.length">
                  <div class="section-label" style="margin-top:14px;">Required Skills for This Listing</div>
                  <div class="skill-tags mt4">
                    <span
                      v-for="sk in selected.bestJobSkills"
                      :key="sk"
                      :class="['skill-tag', selected.skills?.includes(sk) ? 'matched-tag' : 'missing-tag']"
                    >{{ sk }}</span>
                  </div>
                  <p style="font-size:11px;color:#94a3b8;margin-top:6px;">
                    <span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:#22c55e;margin-right:4px;"></span>Green = candidate has · <span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:#f1f5f9;border:1px solid #cbd5e1;margin-right:4px;margin-left:8px;"></span>White = missing
                  </p>
                </template>
              </template>
            </div>
            <div v-if="drawerTab === 'Resume'">
              <div class="resume-panel">
                <p class="resume-hint">Resume / CV (PDF only)</p>
                <div class="resume-placeholder" :class="{ 'resume-placeholder--has': selected?.hasResume }">
                  <svg width="40" height="40" viewBox="0 0 24 24" fill="none" :stroke="selected?.hasResume ? '#2872A1' : '#e2e8f0'" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
                  <p class="resume-msg">Resume / CV</p>
                  <p class="resume-status-line">{{ selected?.hasResume ? 'Uploaded' : 'Not uploaded' }}</p>
                  <button type="button" class="btn-blue" :disabled="!selected?.hasResume || openingResume" @click="viewApplicantResume">
                    <span v-if="openingResume" class="spinner-action" style="margin-right:8px;"></span>
                    {{ openingResume ? 'Opening…' : (selected?.hasResume ? 'View Document' : 'No document') }}
                  </button>
                </div>
              </div>
            </div>
            <div v-if="drawerTab === 'Status'">
              <div class="section-label">Update Status</div>
              <div class="status-options">
                <button v-for="st in ['Reviewing','Shortlisted','Interview','Hired','Rejected']" :key="st" :class="['status-option', statusClass(st), { active: selected?.status === st }]" @click="selected.status = st">{{ st }}</button>
              </div>
              <div class="section-label mt16">Internal Notes</div>
              <textarea class="notes-area" placeholder="Add notes about this applicant…" rows="4" v-model="selected.notes"></textarea>
              <button class="btn-blue-full mt12" @click="handleDrawerSave" :disabled="savingStatus">
                <span v-if="savingStatus" class="spinner-action" style="margin-right:6px;"></span>
                {{ savingStatus ? 'Saving…' : 'Save Changes' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </transition>

    <!-- PROFILE MODAL -->
    <div v-if="profileModal" class="modal-overlay" @click.self="profileModal = null">
      <div class="modal-box">
        <div class="modal-header">
          <div class="modal-avatar" :style="{ background: profileModal.color }">{{ profileModal.name[0] }}</div>
          <div class="modal-info"><h4 class="modal-name">{{ profileModal.name }}</h4><p class="modal-edu">{{ profileModal.education }}</p><div class="modal-loc"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>{{ profileModal.location }}</div></div>
          <button class="modal-close" @click="profileModal = null"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
        </div>
        <div class="modal-body">
          <div class="modal-row"><p class="modal-label">Skills</p><div class="skill-tags"><span v-for="sk in profileModal.skills" :key="sk" class="skill-tag matched-tag">{{ sk }}</span></div></div>
          <div class="modal-row"><p class="modal-label">Best Match For</p><div class="listing-match-cell"><div class="listing-bar" :style="{ background: profileModal.jobColor }"></div><div><p class="person-name">{{ profileModal.bestFor }}</p><p class="person-meta">Active listing · {{ profileModal.score }}% skill match</p></div></div></div>
          <div class="modal-row"><p class="modal-label">Skill Match Score</p><div class="score-cell"><div class="score-bar-bg" style="flex:1"><div class="score-bar-fill" :style="{ width: profileModal.score + '%', background: scoreColor(profileModal.score) }"></div></div><span class="score-val" :style="{ color: scoreColor(profileModal.score) }">{{ profileModal.score }}%</span></div></div>
          <div class="modal-row"><p class="modal-label">Status</p><span class="not-applied-badge"><span class="na-dot"></span>Not Applied</span></div>
        </div>
        <div class="modal-footer">
          <button class="btn-blue-full" @click="sendInvite(profileModal); profileModal = null" :disabled="profileModal.invited">
            <template v-if="!profileModal.invited"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="margin-right:6px"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>Invite to Apply for {{ profileModal.bestFor }}</template>
            <template v-else>✓ Invitation Already Sent</template>
          </button>
        </div>
      </div>
    </div>
  </div>

  <!-- ═══════════ CONFIRMATION MODAL ═══════════ -->
  <transition name="modal-pop">
    <div v-if="confirmModal.show" class="modal-overlay" @click.self="confirmModal.show = false">
      <div class="cmodal">
        <div class="cmodal-strip" :class="confirmModal.theme"></div>
        <div class="cmodal-body">
          <div class="cmodal-icon" :class="confirmModal.theme" v-html="confirmModal.icon"></div>
          <h3 class="cmodal-title">{{ confirmModal.title }}</h3>
          <p class="cmodal-desc">{{ confirmModal.desc }}</p>
        </div>
        <div class="cmodal-footer">
          <button class="cmodal-cancel" @click="confirmModal.show = false">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            Cancel
          </button>
          <button class="cmodal-ok" :class="confirmModal.theme" @click="confirmModal.onConfirm" v-html="confirmModal.okHtml"></button>
        </div>
      </div>
    </div>
  </transition>

  <!-- ═══════════ INTERVIEW MODAL ═══════════ -->
  <transition name="modal-pop">
    <div v-if="interviewModal.show" class="modal-overlay" @click.self="interviewModal.show = false">
      <div class="fancy-modal">
        <div class="fm-header purple-grad">
          <div class="fm-header-left">
            <div class="fm-hicon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg></div>
            <div>
              <h3 class="fm-title">Schedule Interview</h3>
              <p class="fm-subtitle">for <strong>{{ interviewModal.applicant?.name }}</strong> · {{ interviewModal.applicant?.jobApplied }}</p>
            </div>
          </div>
          <button class="fm-close" @click="interviewModal.show = false"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
        </div>
        <div class="fm-body">
          <div class="fm-2col">
            <div class="fm-field">
              <label class="fm-label"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>Date</label>
              <input type="date" v-model="interviewModal.date" class="fm-input purple-focus" />
            </div>
            <div class="fm-field">
              <label class="fm-label"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>Time</label>
              <input type="time" v-model="interviewModal.time" class="fm-input purple-focus" />
            </div>
          </div>
          <div class="fm-field">
            <label class="fm-label"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="23 7 16 12 23 17 23 7"/><rect x="1" y="5" width="15" height="14" rx="2"/></svg>Format</label>
            <div class="fm-pills">
              <button v-for="fmt in ['In-person','Online / Video Call','Phone Call']" :key="fmt" :class="['fm-pill', 'purple-pill', { active: interviewModal.format === fmt }]" @click="interviewModal.format = fmt">{{ fmt }}</button>
            </div>
          </div>
          <div class="fm-field">
            <label class="fm-label"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>Location / Link</label>
            <input type="text" v-model="interviewModal.location" placeholder="e.g. 3rd Floor HR Office  or  https://zoom.us/j/..." class="fm-input purple-focus" />
          </div>
          <div class="fm-field">
            <label class="fm-label"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>Interviewer Name</label>
            <input type="text" v-model="interviewModal.interviewer" placeholder="e.g. Maria Santos, HR Manager" class="fm-input purple-focus" />
          </div>

          <!-- Email preview -->
          <div class="email-preview purple-preview">
            <div class="ep-head">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
              What the applicant will receive
            </div>
            <div class="ep-rows">
              <div class="ep-row"><span class="ep-k">To</span><span class="ep-v">{{ interviewModal.applicant?.name }}</span></div>
              <div class="ep-row"><span class="ep-k">Date</span><span class="ep-v ep-chip purple-chip">{{ interviewModal.date ? formatDate(interviewModal.date) : '—' }}</span></div>
              <div class="ep-row"><span class="ep-k">Time</span><span class="ep-v ep-chip purple-chip">{{ interviewModal.time ? formatTime(interviewModal.time) : '—' }}</span></div>
              <div class="ep-row"><span class="ep-k">Format</span><span class="ep-v">{{ interviewModal.format }}</span></div>
              <div class="ep-row"><span class="ep-k">Location</span><span class="ep-v">{{ interviewModal.location || '—' }}</span></div>
              <div class="ep-row"><span class="ep-k">Interviewer</span><span class="ep-v">{{ interviewModal.interviewer || '—' }}</span></div>
            </div>
          </div>
        </div>
        <div class="fm-footer">
          <button class="fm-cancel" @click="interviewModal.show = false">Cancel</button>
          <button class="fm-submit purple-btn" @click="submitInterview" :disabled="savingStatus">
            <span v-if="savingStatus" class="spinner-action" style="border-color:#fff;border-right-color:transparent;margin-right:7px;width:12px;height:12px;"></span>
            <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" style="margin-right:7px"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
            {{ savingStatus ? 'Sending email…' : 'Schedule & Send Email' }}
          </button>
        </div>
      </div>
    </div>
  </transition>

  <!-- ═══════════ HIRE MODAL ═══════════ -->
  <transition name="modal-pop">
    <div v-if="hireModal.show" class="modal-overlay" @click.self="hireModal.show = false">
      <div class="fancy-modal">
        <div class="fm-header green-grad">
          <div class="fm-header-left">
            <div class="fm-hicon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg></div>
            <div>
              <h3 class="fm-title">Confirm Hire</h3>
              <p class="fm-subtitle">Extending offer to <strong>{{ hireModal.applicant?.name }}</strong></p>
            </div>
          </div>
          <button class="fm-close" @click="hireModal.show = false"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>
        </div>
        <div class="fm-body">
          <div class="fm-field">
            <label class="fm-label"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>Start Date</label>
            <input type="date" v-model="hireModal.startDate" class="fm-input green-focus" />
          </div>

          <!-- Email preview -->
          <div class="email-preview green-preview">
            <div class="ep-head">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
              Offer email — what the applicant will receive
            </div>
            <div class="ep-rows">
              <div class="ep-row"><span class="ep-k">To</span><span class="ep-v">{{ hireModal.applicant?.name }}</span></div>
              <div class="ep-row"><span class="ep-k">Position</span><span class="ep-v ep-chip green-chip">{{ hireModal.applicant?.jobApplied || '—' }}</span></div>
              <div class="ep-row"><span class="ep-k">Employer</span><span class="ep-v">{{ hireModal.companyName || '—' }}</span></div>
              <div class="ep-row"><span class="ep-k">Start Date</span><span class="ep-v ep-chip green-chip">{{ hireModal.startDate ? formatDate(hireModal.startDate) : '—' }}</span></div>
              <div class="ep-row"><span class="ep-k">Salary</span><span class="ep-v">{{ hireModal.salary || 'Negotiable' }}</span></div>
              <div class="ep-row"><span class="ep-k">Employment Type</span><span class="ep-v">{{ hireModal.employmentType || 'Full-time' }}</span></div>
            </div>
          </div>

          <div class="fm-info-note">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink:0;margin-top:1px"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            Salary and employment type are pulled from the job listing. To update them, edit the listing first.
          </div>
        </div>
        <div class="fm-footer">
          <button class="fm-cancel" @click="hireModal.show = false">Cancel</button>
          <button class="fm-submit green-btn" @click="submitHire" :disabled="savingStatus">
            <span v-if="savingStatus" class="spinner-action" style="border-color:#fff;border-right-color:transparent;margin-right:7px;width:12px;height:12px;"></span>
            <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" style="margin-right:7px"><polyline points="20 6 9 17 4 12"/></svg>
            {{ savingStatus ? 'Sending offer…' : 'Confirm & Send Offer Email' }}
          </button>
        </div>
      </div>
    </div>
  </transition>

</template>

<script>
import EmployerSidebar from '@/components/EmployerSidebar.vue'
import EmployerTopbar  from '@/components/EmployerTopbar.vue'
import employerApi from '@/services/employerApi'
import { useEmployerApplicantsStore } from '@/stores/employerApplicantsStore'
import { useEmployerAuthStore } from '@/stores/employerAuth'

export default {
  name: 'EmployerApplicants',
  components: { EmployerSidebar, EmployerTopbar },
  setup() {
    const applicantsStore = useEmployerApplicantsStore()
    const authStore = useEmployerAuthStore()
    return { applicantsStore, authStore }
  },
  data() {
    return {
      isLoading: true,
      activeTab: 'all', activeStatusTab: 'all',
      search: '', filterJob: '', filterStatus: '',
      appliedPage: 1, perPage: 15,
      drawerOpen: false, drawerTab: 'Profile', selected: null,
      openingResume: false,
      hireModal: { show: false, applicant: null, startDate: '', companyName: '', salary: '', employmentType: '' },
      interviewModal: { show: false, applicant: null, date: '', time: '', format: 'In-person', location: '', interviewer: '' },
      confirmModal: { show: false, title: '', desc: '', icon: '', theme: 'blue', okHtml: '', onConfirm: null },
      potentialJobFilter: '', potentialPage: 1,
      profileModal: null,
      updatingStatusId: null, savingStatus: false,
      toast: { show: false, text: '', type: 'success', icon: '', _timer: null },
    }
  },
  computed: {
    applicants()          { return this.applicantsStore.applicants },
    potentialApplicants() { return this.applicantsStore.potentialApplicants },
    jobOptions() { return [...new Set(this.applicants.map((a) => a.jobApplied).filter(Boolean))] },
    statusTabs() {
      return [
        { label: 'All',         value: 'all',         count: this.applicantsStore.totalApplicants,  cls: '' },
        { label: 'Reviewing',   value: 'Reviewing',   count: this.applicantsStore.reviewingCount,   cls: 'reviewing' },
        { label: 'Shortlisted', value: 'Shortlisted', count: this.applicantsStore.shortlistedCount, cls: 'shortlisted' },
        { label: 'Interview',   value: 'Interview',   count: this.applicantsStore.interviewCount,   cls: 'interview' },
        { label: 'Hired',       value: 'Hired',       count: this.applicantsStore.hiredCount,       cls: 'hired' },
        { label: 'Rejected',    value: 'Rejected',    count: this.applicantsStore.rejectedCount,    cls: 'rejected' },
      ]
    },
    filteredApplicants() {
      return this.applicants.filter((a) => {
        const matchTab    = this.activeTab === 'all' || a.status === this.activeTab
        const matchSearch = !this.search || a.name.toLowerCase().includes(this.search.toLowerCase()) || a.skills.some((s) => s.toLowerCase().includes(this.search.toLowerCase()))
        const matchJob    = !this.filterJob    || a.jobApplied === this.filterJob
        const matchStatus = !this.filterStatus || a.status === this.filterStatus
        return matchTab && matchSearch && matchJob && matchStatus
      })
    },
    appliedTotalPages() { return Math.max(1, Math.ceil(this.filteredApplicants.length / this.perPage)) },
    pagedApplicants() { const s = (this.appliedPage - 1) * this.perPage; return this.filteredApplicants.slice(s, s + this.perPage) },
    filteredPotential() {
      let list = [...this.potentialApplicants]
      if (this.search) { const q = this.search.toLowerCase(); list = list.filter((a) => a.name.toLowerCase().includes(q) || a.skills.some((s) => s.toLowerCase().includes(q)) || a.bestFor.toLowerCase().includes(q)) }
      if (this.potentialJobFilter) list = list.filter((a) => a.bestFor === this.potentialJobFilter)
      return list.sort((a, b) => b.score - a.score)
    },
    potentialTotalPages() { return Math.max(1, Math.ceil(this.filteredPotential.length / this.perPage)) },
    pagedPotential() { const s = (this.potentialPage - 1) * this.perPage; return this.filteredPotential.slice(s, s + this.perPage) },
    todayFormatted() { return new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }) },
  },
  methods: {
    statusClass(s) { return { Reviewing:'reviewing', Shortlisted:'shortlisted', Interview:'interview', Hired:'hired', Rejected:'rejected' }[s] || '' },
    scoreColor(v)  { return v >= 85 ? '#22c55e' : v >= 70 ? '#2872A1' : '#ef4444' },
    scoreBg(v)     { return v >= 85 ? '#f0fdf4' : v >= 70 ? '#eff8ff' : '#fef2f2' },
    openDrawer(a)  { this.selected = { ...a }; this.drawerTab = 'Profile'; this.drawerOpen = true },
    openPotentialDrawer(a) {
      // Build a drawer-compatible object from the potential applicant
      this.selected = {
        ...a,
        avatarBg: a.color,
        matchScore: a.score,
        jobApplied: a.bestFor,
        date: '',
        status: 'Not Applied',
        hasResume: false,
        notes: '',
        _isPotential: true,
      }
      this.drawerTab = 'Profile'
      this.drawerOpen = true
    },

    formatDate(d) {
      if (!d) return '—'
      return new Date(d + 'T00:00:00').toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
    },
    formatTime(t) {
      if (!t) return '—'
      const [h, m] = t.split(':')
      const hour = parseInt(h)
      return `${hour % 12 || 12}:${m} ${hour >= 12 ? 'PM' : 'AM'}`
    },

    advanceBtnClass(s) {
      return s === 'Reviewing' ? 'advance-blue' : s === 'Shortlisted' ? 'advance-purple' : s === 'Interview' ? 'advance-green' : 'advance-blue'
    },
    advanceTitle(s) {
      return s === 'Reviewing' ? 'Shortlist Applicant' : s === 'Shortlisted' ? 'Schedule Interview' : s === 'Interview' ? 'Hire Applicant' : 'Advance'
    },

    confirmAdvance(applicant) {
      if (applicant.status === 'Shortlisted') { this.openInterviewModal(applicant); return }
      if (applicant.status === 'Interview')   { this.openHireModal(applicant);      return }
      this.confirmShortlist(applicant)
    },

    confirmShortlist(applicant) {
      this.confirmModal = {
        show: true, theme: 'blue',
        title: 'Shortlist this applicant?',
        desc: `${applicant.name} will be moved to Shortlisted and notified by email.`,
        icon: `<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><polyline points="20 6 9 17 4 12"/></svg>`,
        okHtml: `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="margin-right:6px"><polyline points="20 6 9 17 4 12"/></svg>Yes, Shortlist`,
        onConfirm: () => { this.confirmModal.show = false; this.updateStatus(applicant, 'Shortlisted', true) },
      }
    },

    confirmSendInvite(a) {
      if (a.invited || a._inviting) return;
      this.confirmModal = {
        show: true, theme: 'blue',
        title: 'Invite this jobseeker?',
        desc: `Are you sure you want to personally invite ${a.name} to apply for ${a.bestFor}? They will be notified by email.`,
        icon: `<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>`,
        okHtml: `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="margin-right:6px"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>Yes, Invite`,
        onConfirm: () => { this.confirmModal.show = false; this.sendInvite(a) },
      }
    },

    confirmReject(applicant) {
      this.confirmModal = {
        show: true, theme: 'red',
        title: 'Reject this applicant?',
        desc: `${applicant.name} will be marked as Rejected and notified by email. You can still change the status manually afterward.`,
        icon: `<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`,
        okHtml: `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="margin-right:6px"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>Yes, Reject`,
        onConfirm: () => { this.confirmModal.show = false; this.updateStatus(applicant, 'Rejected', true) },
      }
    },

    async viewApplicantResume() {
      if (!this.selected?.id || !this.selected?.hasResume) return
      this.openingResume = true
      try {
        const res = await employerApi.downloadApplicationResume(this.selected.id)
        const blob = new Blob([res.data], { type: 'application/pdf' })
        const url = URL.createObjectURL(blob)
        const win = window.open(url, '_blank', 'noopener,noreferrer')
        if (!win) this.showToastMsg('Pop-up blocked — allow pop-ups to view the PDF.', 'error')
        setTimeout(() => URL.revokeObjectURL(url), 120000)
      } catch (e) { this.showToastMsg('Could not open resume.', 'error') }
      finally { this.openingResume = false }
    },

    async sendInvite(a) {
      if (a.invited || a._inviting) return
      if (!a.jobId) {
        this.showToastMsg('No matching job listing found for this applicant.', 'error')
        return
      }
      a._inviting = true
      try {
        await employerApi.sendInvitation(a.id, a.jobId)
        this.applicantsStore.markInvited(a.id)
        const found = this.potentialApplicants.find((x) => x.id === a.id)
        if (found) found.invited = true
        this.showToastMsg('Invitation sent successfully!', 'success')
      } catch (e) {
        const msg = e?.response?.data?.message || 'Failed to send invitation. Please try again.'
        this.showToastMsg(msg, 'error')
      } finally {
        a._inviting = false
      }
    },

    openHireModal(applicant) {
      this.hireModal = {
        show: true, applicant,
        startDate: '',
        companyName: this.authStore.user?.company_name || applicant.companyName || '',
        salary: applicant.salary || 'Negotiable',
        employmentType: applicant.employmentType || 'Full-time',
      }
    },

    openInterviewModal(applicant) {
      this.interviewModal = { show: true, applicant, date: '', time: '', format: 'In-person', location: '', interviewer: '' }
    },

    async submitInterview() {
      if (!this.interviewModal.date || !this.interviewModal.time || !this.interviewModal.location || !this.interviewModal.interviewer) {
        this.showToastMsg('Please fill in all interview details.', 'error'); return
      }
      this.savingStatus = true
      try {
        await this.applicantsStore.updateStatus(this.interviewModal.applicant.id, 'Interview', {
          interview_date:     this.interviewModal.date,
          interview_time:     this.interviewModal.time,
          interview_format:   this.interviewModal.format,
          interview_location: this.interviewModal.location,
          interviewer_name:   this.interviewModal.interviewer,
        })
        if (this.selected?.id === this.interviewModal.applicant.id) this.selected.status = 'Interview'
        this.showToastMsg('Interview scheduled & email sent!', 'success')
        this.interviewModal.show = false; this.drawerOpen = false
      } catch (e) { this.showToastMsg('Failed to schedule interview', 'error') }
      finally { this.savingStatus = false }
    },

    async submitHire() {
      if (!this.hireModal.startDate) { this.showToastMsg('Please enter a start date.', 'error'); return }
      this.savingStatus = true
      try {
        await this.applicantsStore.updateStatus(this.hireModal.applicant.id, 'Hired', { start_date: this.hireModal.startDate })
        if (this.selected?.id === this.hireModal.applicant.id) this.selected.status = 'Hired'
        this.showToastMsg('Offer sent and status updated to Hired!', 'success')
        this.hireModal.show = false; this.drawerOpen = false
      } catch (e) { this.showToastMsg('Failed to process hiring', 'error') }
      finally { this.savingStatus = false }
    },

    handleDrawerSave() {
      const oldStatus = this.applicants.find(a => a.id === this.selected.id)?.status
      const newStatus = this.selected.status
      if (newStatus === 'Hired'       && oldStatus !== 'Hired')       { this.openHireModal(this.selected);      return }
      if (newStatus === 'Interview'   && oldStatus !== 'Interview')   { this.openInterviewModal(this.selected); return }
      if (newStatus === 'Rejected'    && oldStatus !== 'Rejected')    { this.confirmReject(this.selected);      return }
      if (newStatus === 'Shortlisted' && oldStatus !== 'Shortlisted') { this.confirmShortlist(this.selected);   return }
      this.updateStatus(this.selected, newStatus, true)
    },

    async updateStatus(applicant, status, isDrawer = false) {
      if (isDrawer) this.savingStatus = true; else this.updatingStatusId = applicant.id
      try {
        await this.applicantsStore.updateStatus(applicant.id, status)
        if (this.selected?.id === applicant.id) this.selected.status = status
        this.showToastMsg(`Status updated to ${status}`, 'success')
        if (isDrawer) this.drawerOpen = false
      } catch (e) { this.showToastMsg('Failed to update status', 'error') }
      finally { if (isDrawer) this.savingStatus = false; else this.updatingStatusId = null }
    },

    showToastMsg(text, type = 'success') {
      const CHECK = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>`
      const X     = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`
      if (this.toast._timer) clearTimeout(this.toast._timer)
      this.toast = { show: true, text, type, icon: type === 'success' ? CHECK : X, _timer: setTimeout(() => { this.toast.show = false }, 3500) }
    },
  },
  async mounted() {
    await this.applicantsStore.fetch()
    this.isLoading = false
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
.layout-wrapper { display: flex; height: 100vh; overflow: hidden; background: #f8fafc; font-family: 'Plus Jakarta Sans', sans-serif; }
.main-area { flex: 1; display: flex; flex-direction: column; min-height: 0; overflow: hidden; }
.page { flex: 1; overflow-y: auto; overflow-x: hidden; padding: 24px; min-height: 0; }

.filters-bar { display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; flex: 1; max-width: 360px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-group { display: flex; align-items: center; gap: 8px; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }
.btn-icon { display: flex; align-items: center; gap: 6px; background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; font-family: inherit; }
.main-tabs { display: flex; gap: 6px; background: #fff; border: 1px solid #f1f5f9; border-radius: 12px; padding: 5px; width: fit-content; }
.main-tab { display: flex; align-items: center; gap: 7px; padding: 8px 16px; border-radius: 9px; border: none; background: none; font-size: 13px; font-weight: 600; color: #64748b; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.main-tab:hover { background: #f8fafc; color: #1e293b; }
.main-tab.active { background: #eff8ff; color: #1a5f8a; }
.potential-tab.active { background: #faf5ff; color: #7c3aed; }
.main-count { font-size: 10.5px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }
.potential-count { background: #ede9fe; color: #7c3aed; }
.status-tabs { display: flex; gap: 4px; }
.tab-btn { display: flex; align-items: center; gap: 6px; background: none; border: none; padding: 8px 14px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; border-radius: 8px; font-family: inherit; }
.tab-btn:hover { background: #f1f5f9; }
.tab-btn.active { background: #eff8ff; color: #1a5f8a; font-weight: 700; }
.tab-count { font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }
.tab-count.reviewing   { background: #eff6ff; color: #3b82f6; }
.tab-count.shortlisted { background: #eff8ff; color: #1a5f8a; }
.tab-count.interview   { background: #faf5ff; color: #8b5cf6; }
.tab-count.hired       { background: #f0fdf4; color: #22c55e; }
.tab-count.rejected    { background: #fef2f2; color: #ef4444; }
.potential-notice { background: #eff8ff; border: 1px solid #bae6fd; border-radius: 10px; padding: 11px 14px; font-size: 12.5px; color: #1a5f8a; display: flex; align-items: flex-start; gap: 8px; }
.listing-tabs { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.listing-tab { display: inline-flex; align-items: center; gap: 6px; font-size: 12px; font-weight: 600; color: #64748b; background: #fff; border: 1.5px solid #e2e8f0; border-radius: 8px; padding: 5px 12px; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.listing-tab:hover { border-color: #94a3b8; color: #1e293b; }
.listing-tab.active { color: #2872A1; border-color: #2872A1; background: #eff8ff; }
.ltab-count { font-size: 10px; font-weight: 700; background: #f1f5f9; color: #64748b; padding: 1px 6px; border-radius: 99px; }
.table-card { background: #fff; border-radius: 14px; overflow: visible; border: 1px solid #f1f5f9; }
.data-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.data-table thead tr { background: #f8fafc; }
.data-table th { text-align: left; padding: 11px 14px; font-size: 11px; font-weight: 700; color: #94a3b8; letter-spacing: 0.04em; text-transform: uppercase; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.table-row { cursor: pointer; transition: background 0.12s; }
.table-row:hover { background: #eff8ff; }
.data-table td { padding: 12px 14px; border-bottom: 1px solid #f8fafc; vertical-align: middle; }
.empty-cell { text-align: center; color: #94a3b8; font-size: 13px; padding: 36px !important; }
.person-cell { display: flex; align-items: center; gap: 10px; }
.avatar { width: 34px; height: 34px; border-radius: 50%; color: #fff; font-size: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.person-name { font-size: 13px; font-weight: 600; color: #1e293b; }
.person-meta { font-size: 11px; color: #94a3b8; margin-top: 1px; }
.skill-tags { display: flex; align-items: center; gap: 4px; flex-wrap: wrap; }
.skill-tag { background: #f1f5f9; color: #475569; font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
.matched-tag { background: #f0fdf4; color: #15803d; border: 1px solid #bbf7d0; }
.missing-tag { background: #fff; color: #64748b; border: 1px solid #e2e8f0; }
.skill-more { font-size: 11px; color: #94a3b8; }
.job-cell { color: #475569; font-size: 12.5px; }
.date-cell { color: #94a3b8; font-size: 12px; white-space: nowrap; }
.score-cell { display: flex; align-items: center; gap: 8px; }
.score-bar-bg { width: 60px; height: 5px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.score-bar-fill { height: 100%; border-radius: 99px; }
.score-val { font-size: 12px; font-weight: 700; min-width: 32px; }
.status-badge { padding: 4px 10px; border-radius: 99px; font-size: 11px; font-weight: 600; white-space: nowrap; }
.reviewing   { background: #eff6ff; color: #3b82f6; }
.shortlisted { background: #eff8ff; color: #1a5f8a; }
.interview   { background: #faf5ff; color: #8b5cf6; }
.hired       { background: #f0fdf4; color: #22c55e; }
.rejected    { background: #fef2f2; color: #ef4444; }
.not-applied-badge { display: inline-flex; align-items: center; gap: 6px; background: #fef9ec; color: #92400e; font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 99px; border: 1px solid #fde68a; white-space: nowrap; }
.na-dot { width: 6px; height: 6px; border-radius: 50%; background: #f59e0b; flex-shrink: 0; }
.listing-match-cell { display: flex; align-items: center; gap: 9px; }
.listing-bar { width: 4px; height: 32px; border-radius: 99px; flex-shrink: 0; }
.loc-cell { display: flex; align-items: center; gap: 5px; font-size: 12px; color: #475569; white-space: nowrap; }
.action-btns { display: flex; gap: 4px; }
.act-btn { width: 28px; height: 28px; border-radius: 7px; border: none; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.15s; }
.act-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.act-btn.view { background: #f1f5f9; color: #64748b; }
.act-btn.view:hover { background: #e2e8f0; }
.advance-blue   { background: #eff8ff; color: #2872A1; }
.advance-blue:hover:not(:disabled)   { background: #2872A1; color: #fff; }
.advance-purple { background: #faf5ff; color: #8b5cf6; }
.advance-purple:hover:not(:disabled) { background: #8b5cf6; color: #fff; }
.advance-green  { background: #f0fdf4; color: #22c55e; }
.advance-green:hover:not(:disabled)  { background: #22c55e; color: #fff; }
.act-btn.reject { background: #fef2f2; color: #ef4444; }
.act-btn.reject:hover:not(:disabled) { background: #ef4444; color: #fff; }
.act-btn.invite-act { background: #eff8ff; color: #2872A1; }
.act-btn.invite-act:hover:not(:disabled) { background: #2872A1; color: #fff; }
.act-btn.invite-act:disabled { background: #f0fdf4; color: #16a34a; cursor: default; }
.pagination { display: flex; align-items: center; justify-content: space-between; padding: 14px 18px; border-top: 1px solid #f1f5f9; }
.page-info { font-size: 12px; color: #94a3b8; }
.page-btns { display: flex; gap: 4px; }
.page-btn { width: 30px; height: 30px; border-radius: 7px; border: 1px solid #e2e8f0; background: #fff; font-size: 12px; color: #64748b; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; transition: all 0.15s; }
.page-btn:hover:not(:disabled) { border-color: #2872A1; color: #2872A1; }
.page-btn.active { background: #2872A1; color: #fff; border-color: #2872A1; }
.page-btn:disabled { opacity: 0.35; cursor: default; }

/* DRAWER */
.drawer-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.3); z-index: 100; display: flex; justify-content: flex-end; backdrop-filter: blur(2px); }
.drawer { width: 420px; height: 100vh; background: #fff; display: flex; flex-direction: column; overflow: hidden; box-shadow: -8px 0 32px rgba(0,0,0,0.12); }
.drawer-header { display: flex; align-items: center; gap: 12px; padding: 20px; border-bottom: 1px solid #f1f5f9; }
.drawer-avatar { width: 46px; height: 46px; border-radius: 50%; color: #fff; font-size: 16px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.drawer-title-wrap { flex: 1; }
.drawer-name { font-size: 16px; font-weight: 800; color: #1e293b; }
.drawer-loc { font-size: 12px; color: #94a3b8; margin-top: 2px; }
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
.dtab.active { color: #1a5f8a; border-bottom-color: #2872A1; font-weight: 700; }
.drawer-body { flex: 1; overflow-y: auto; padding: 20px; }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 18px; }
.info-item { display: flex; flex-direction: column; gap: 3px; }
.info-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
.info-val { font-size: 13px; font-weight: 500; color: #1e293b; }
.section-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.06em; margin: 16px 0 8px; }
.mt4{margin-top:4px;}.mt12{margin-top:12px;}.mt16{margin-top:16px;}
.applied-box { background: #eff8ff; border-radius: 10px; padding: 12px 14px; border: 1px solid #bae6fd; }
.applied-job { font-size: 14px; font-weight: 700; color: #1e293b; }
.applied-date { font-size: 12px; color: #94a3b8; margin-top: 3px; }
.resume-panel { width: 100%; }
.resume-hint { font-size: 11px; font-weight: 600; color: #64748b; margin: 0 0 12px; }
.resume-placeholder { display: flex; flex-direction: column; align-items: center; gap: 10px; padding: 36px 20px; border: 1px solid #e2e8f0; border-radius: 14px; background: #fafafa; }
.resume-placeholder--has { background: #f8fafc; border-color: #bae6fd; }
.resume-msg { font-size: 15px; font-weight: 700; color: #1e293b; }
.resume-status-line { font-size: 12px; font-weight: 600; color: #64748b; margin: -4px 0 4px; }
.btn-blue { background: #2872A1; color: #fff; border: none; border-radius: 10px; padding: 9px 20px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; display: inline-flex; align-items: center; justify-content: center; min-width: 160px; }
.btn-blue:disabled { opacity: 0.55; cursor: not-allowed; }
.status-options { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.status-option { padding: 10px; border-radius: 10px; border: 2px solid transparent; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; transition: all 0.15s; background: #f8fafc; color: #64748b; }
.status-option.active.reviewing   { background: #eff6ff; color: #3b82f6; border-color: #3b82f6; }
.status-option.active.shortlisted { background: #eff8ff; color: #1a5f8a; border-color: #2872A1; }
.status-option.active.interview   { background: #faf5ff; color: #8b5cf6; border-color: #8b5cf6; }
.status-option.active.hired       { background: #f0fdf4; color: #22c55e; border-color: #22c55e; }
.status-option.active.rejected    { background: #fef2f2; color: #ef4444; border-color: #ef4444; }
.notes-area { width: 100%; border: 1px solid #e2e8f0; border-radius: 10px; padding: 10px 12px; font-size: 13px; color: #1e293b; font-family: inherit; resize: vertical; outline: none; background: #f8fafc; }
.notes-area:focus { border-color: #08BDDE; background: #fff; }
.btn-blue-full { width: 100%; background: #2872A1; color: #fff; border: none; border-radius: 10px; padding: 11px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; }
.btn-blue-full:disabled { opacity: 0.6; cursor: not-allowed; }

/* PROFILE MODAL */
.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.5); z-index: 200; display: flex; align-items: center; justify-content: center; padding: 24px; backdrop-filter: blur(3px); }
.modal-box { background: #fff; border-radius: 18px; width: 100%; max-width: 440px; box-shadow: 0 20px 60px rgba(0,0,0,0.18); overflow: hidden; }
.modal-header { display: flex; align-items: flex-start; gap: 14px; padding: 20px 20px 16px; border-bottom: 1px solid #f1f5f9; }
.modal-avatar { width: 46px; height: 46px; border-radius: 50%; color: #fff; font-size: 17px; font-weight: 800; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.modal-info { flex: 1; }
.modal-name { font-size: 16px; font-weight: 800; color: #1e293b; margin-bottom: 2px; }
.modal-edu { font-size: 12px; color: #64748b; margin-bottom: 4px; }
.modal-loc { display: flex; align-items: center; gap: 4px; font-size: 11.5px; color: #94a3b8; }
.modal-close { background: #f8fafc; border: 1px solid #f1f5f9; border-radius: 8px; width: 30px; height: 30px; display: flex; align-items: center; justify-content: center; cursor: pointer; flex-shrink: 0; }
.modal-close:hover { background: #f1f5f9; }
.modal-body { padding: 18px 20px; display: flex; flex-direction: column; gap: 16px; }
.modal-row { display: flex; flex-direction: column; gap: 7px; }
.modal-label { font-size: 10.5px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
.modal-footer { padding: 14px 20px 18px; border-top: 1px solid #f1f5f9; }

/* ══════════════════════════════
   CONFIRMATION MODAL
══════════════════════════════ */
.cmodal { background: #fff; border-radius: 20px; width: 100%; max-width: 360px; overflow: hidden; box-shadow: 0 24px 64px rgba(0,0,0,0.22); }
.cmodal-strip { height: 4px; }
.cmodal-strip.blue { background: linear-gradient(90deg, #2872A1, #08BDDE); }
.cmodal-strip.red  { background: linear-gradient(90deg, #ef4444, #f97316); }
.cmodal-body { padding: 28px 26px 16px; display: flex; flex-direction: column; align-items: center; text-align: center; gap: 10px; }
.cmodal-icon { width: 58px; height: 58px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.cmodal-icon.blue { background: #eff8ff; color: #2872A1; border: 2px solid #bae6fd; }
.cmodal-icon.red  { background: #fef2f2; color: #ef4444; border: 2px solid #fecaca; }
.cmodal-title { font-size: 16px; font-weight: 800; color: #1e293b; margin-top: 4px; }
.cmodal-desc  { font-size: 13px; color: #64748b; line-height: 1.65; max-width: 280px; }
.cmodal-footer { display: flex; gap: 8px; padding: 16px 20px 22px; }
.cmodal-cancel { flex: 1; padding: 10px; border-radius: 10px; border: 1.5px solid #e2e8f0; background: #fff; font-size: 13px; font-weight: 600; color: #64748b; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; gap: 6px; transition: all 0.15s; }
.cmodal-cancel:hover { background: #f8fafc; }
.cmodal-ok { flex: 1.5; padding: 10px 14px; border-radius: 10px; border: none; font-size: 13px; font-weight: 700; color: #fff; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; transition: all 0.15s; }
.cmodal-ok.blue { background: #2872A1; }
.cmodal-ok.blue:hover { filter: brightness(1.08); }
.cmodal-ok.red  { background: #ef4444; }
.cmodal-ok.red:hover  { filter: brightness(1.08); }

/* ══════════════════════════════
   FANCY MODALS (Interview + Hire)
══════════════════════════════ */
.fancy-modal { background: #fff; border-radius: 20px; width: 100%; max-width: 510px; max-height: 88vh; overflow: hidden; display: flex; flex-direction: column; box-shadow: 0 24px 64px rgba(0,0,0,0.22); }
.fm-header { padding: 18px 20px 16px; display: flex; align-items: center; justify-content: space-between; flex-shrink: 0; }
.purple-grad { background: linear-gradient(135deg, #4c1d95 0%, #7c3aed 100%); }
.green-grad  { background: linear-gradient(135deg, #064e3b 0%, #059669 100%); }
.fm-header-left { display: flex; align-items: center; gap: 13px; }
.fm-hicon { width: 42px; height: 42px; border-radius: 11px; background: rgba(255,255,255,0.18); display: flex; align-items: center; justify-content: center; color: #fff; flex-shrink: 0; }
.fm-title { font-size: 16px; font-weight: 800; color: #fff; margin-bottom: 1px; }
.fm-subtitle { font-size: 12px; color: rgba(255,255,255,0.65); }
.fm-subtitle strong { color: rgba(255,255,255,0.92); }
.fm-close { width: 28px; height: 28px; border-radius: 8px; background: rgba(255,255,255,0.15); border: none; color: rgba(255,255,255,0.75); cursor: pointer; display: flex; align-items: center; justify-content: center; flex-shrink: 0; transition: all 0.15s; }
.fm-close:hover { background: rgba(255,255,255,0.28); color: #fff; }
.fm-body { padding: 18px 20px; overflow-y: auto; flex: 1; min-height: 0; display: flex; flex-direction: column; gap: 14px; }
.fm-body > * { flex-shrink: 0; }
.fm-field { display: flex; flex-direction: column; gap: 6px; }
.fm-label { font-size: 10.5px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.06em; display: flex; align-items: center; gap: 5px; }
.fm-input { border: 1.5px solid #e2e8f0; border-radius: 10px; padding: 9px 12px; font-size: 13.5px; color: #1e293b; background: #f8fafc; font-family: inherit; outline: none; transition: border-color 0.15s, background 0.15s; width: 100%; }
.fm-input:focus { background: #fff; }
.purple-focus:focus { border-color: #8b5cf6; }
.green-focus:focus  { border-color: #059669; }
.fm-2col { display: flex; gap: 11px; }
.fm-2col .fm-field { flex: 1; }
.fm-pills { display: flex; gap: 6px; flex-wrap: wrap; }
.fm-pill { padding: 6px 13px; border-radius: 99px; border: 1.5px solid #e2e8f0; background: #f8fafc; font-size: 12px; font-weight: 600; color: #64748b; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.purple-pill:hover  { border-color: #8b5cf6; color: #7c3aed; }
.purple-pill.active { background: #faf5ff; border-color: #8b5cf6; color: #7c3aed; }

/* Email preview card */
.email-preview { border-radius: 12px; overflow: hidden; border: 1.5px solid; }
.purple-preview { border-color: #ddd6fe; }
.green-preview  { border-color: #a7f3d0; }
.ep-head { padding: 9px 13px; font-size: 10.5px; font-weight: 700; display: flex; align-items: center; gap: 6px; letter-spacing: 0.04em; text-transform: uppercase; }
.purple-preview .ep-head { background: #ede9fe; color: #6d28d9; }
.green-preview  .ep-head { background: #d1fae5; color: #065f46; }
.ep-rows { }
.ep-row { display: flex; align-items: baseline; gap: 10px; padding: 7px 13px; border-bottom: 1px solid #f8fafc; }
.ep-row:last-child { border-bottom: none; }
.ep-k { font-size: 11px; font-weight: 700; color: #94a3b8; min-width: 100px; flex-shrink: 0; }
.ep-v { font-size: 12.5px; color: #1e293b; font-weight: 500; }
.ep-chip { font-weight: 700; padding: 2px 8px; border-radius: 6px; font-size: 11.5px; }
.purple-chip { background: #ede9fe; color: #6d28d9; }
.green-chip  { background: #dcfce7; color: #065f46; }
.fm-info-note { background: #fffbeb; border: 1px solid #fde68a; border-radius: 10px; padding: 10px 13px; font-size: 12px; color: #92400e; line-height: 1.55; display: flex; align-items: flex-start; gap: 8px; }
.fm-footer { padding: 14px 20px 18px; display: flex; gap: 10px; border-top: 1px solid #f1f5f9; flex-shrink: 0; }
.fm-cancel { flex: 1; padding: 11px; border-radius: 11px; border: 1.5px solid #e2e8f0; background: #fff; font-size: 13px; font-weight: 600; color: #475569; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.fm-cancel:hover { background: #f8fafc; }
.fm-submit { flex: 2.4; padding: 11px; border-radius: 11px; border: none; font-size: 13px; font-weight: 700; color: #fff; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; transition: all 0.15s; }
.purple-btn { background: linear-gradient(135deg, #6d28d9, #8b5cf6); }
.purple-btn:hover:not(:disabled) { filter: brightness(1.08); }
.green-btn  { background: linear-gradient(135deg, #059669, #22c55e); }
.green-btn:hover:not(:disabled)  { filter: brightness(1.08); }
.fm-submit:disabled { opacity: 0.6; cursor: not-allowed; }

/* Transitions */
.drawer-enter-active, .drawer-leave-active { transition: opacity 0.2s; }
.drawer-enter-active .drawer, .drawer-leave-active .drawer { transition: transform 0.25s cubic-bezier(0.4,0,0.2,1); }
.drawer-enter-from, .drawer-leave-to { opacity: 0; }
.drawer-enter-from .drawer, .drawer-leave-to .drawer { transform: translateX(100%); }
.modal-pop-enter-active { transition: all 0.22s cubic-bezier(0.34,1.56,0.64,1); }
.modal-pop-leave-active { transition: all 0.15s ease-in; }
.modal-pop-enter-from { opacity: 0; transform: scale(0.9); }
.modal-pop-leave-to   { opacity: 0; transform: scale(0.95); }

/* Toast */
.toast { position: fixed; top: 20px; right: 24px; z-index: 9999; display: flex; align-items: center; gap: 10px; padding: 12px 18px; border-radius: 12px; font-size: 13px; font-weight: 600; box-shadow: 0 8px 30px rgba(0,0,0,0.12); min-width: 240px; max-width: 380px; font-family: 'Plus Jakarta Sans', sans-serif; }
.toast.success { background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; }
.toast.error   { background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; }
.toast-icon { display: flex; align-items: center; flex-shrink: 0; }
.toast-msg { word-break: break-word; line-height: 1.4; }
.toast-enter-active, .toast-leave-active { transition: all 0.3s cubic-bezier(0.4,0,0.2,1); }
.toast-enter-from, .toast-leave-to { opacity: 0; transform: translateY(-15px) scale(0.95); }
.spinner-action { width: 13px; height: 13px; flex-shrink: 0; border: 2px solid currentColor; border-right-color: transparent; border-radius: 50%; display: inline-block; animation: spin 0.7s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.skeleton { background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%); background-size: 200% 100%; animation: shimmer 1.5s infinite; border: none !important; }
@keyframes shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }
</style>