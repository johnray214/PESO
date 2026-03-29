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
      <EmployerTopbar title="Job Listings" subtitle="Create and manage your open positions" />
      <div class="page">

        <!-- Filters + Add Skeleton -->
        <div v-if="isLoading" class="filters-bar" style="align-items: center;">
          <div class="skeleton" style="width: 250px; height: 42px; border-radius: 99px; flex: 1; max-width: 320px;"></div>
          <div class="filter-group">
            <div class="skeleton" style="width: 130px; height: 42px; border-radius: 99px;"></div>
            <div class="skeleton" style="width: 130px; height: 42px; border-radius: 99px;"></div>
            <div class="skeleton" style="width: 140px; height: 42px; border-radius: 99px;"></div>
          </div>
        </div>

        <!-- Filters + Add -->
        <div v-else class="filters-bar">
          <div class="search-box">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            <input v-model="search" type="text" placeholder="Search by job title, type…" class="search-input"/>
          </div>
          <div class="filter-group">
            <select v-model="filterType" class="filter-select">
              <option value="">All Types</option>
              <option value="Full-time">Full-time</option>
              <option value="Part-time">Part-time</option>
              <option value="Contract">Contract</option>
              <option value="Internship">Internship</option>
            </select>
            <button class="btn-amber" @click="openModal(null)">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
              Post a Job
            </button>
          </div>
        </div>

        <!-- Active / Archived Tabs -->
        <div v-if="!isLoading" class="listing-tabs-bar">
          <button :class="['listing-main-tab', { active: listingTab === 'active' }]" @click="listingTab = 'active'">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
            Active
            <span class="ltab-pill">{{ activeJobs.length }}</span>
          </button>
          <button :class="['listing-main-tab', 'archived-tab', { active: listingTab === 'archived' }]" @click="listingTab = 'archived'">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="21 8 21 21 3 21 3 8"/><rect x="1" y="3" width="22" height="5"/><line x1="10" y1="12" x2="14" y2="12"/></svg>
            Archived
            <span class="ltab-pill archived-pill">{{ archivedJobs.length }}</span>
          </button>
        </div>

        <!-- Skeleton Loading Grid -->
        <div v-if="isLoading" class="jobs-grid">
          <div v-for="i in 6" :key="'skel'+i" class="job-card">
            <div class="job-card-header">
              <div class="skeleton" style="width: 40px; height: 40px; border-radius: 12px;"></div>
              <div class="skeleton" style="width: 50px; height: 20px; border-radius: 99px;"></div>
            </div>
            <div class="skeleton" style="width: 60%; height: 18px; margin-top: 5px;"></div>
            <div class="job-tags" style="margin-top: 4px;">
              <div class="skeleton" style="width: 60px; height: 18px; border-radius: 6px;"></div>
              <div class="skeleton" style="width: 80px; height: 18px; border-radius: 6px;"></div>
            </div>
            <div class="skeleton" style="width: 100px; height: 15px; margin-top: 2px;"></div>
            <div class="job-desc" style="display: flex; flex-direction: column; gap: 4px; margin-top: 4px;">
              <div class="skeleton" style="width: 100%; height: 10px;"></div>
              <div class="skeleton" style="width: 85%; height: 10px;"></div>
            </div>
            <div class="job-skills" style="margin-top: 4px;">
              <div class="skeleton" style="width: 50px; height: 17px; border-radius: 6px;"></div>
              <div class="skeleton" style="width: 55px; height: 17px; border-radius: 6px;"></div>
              <div class="skeleton" style="width: 45px; height: 17px; border-radius: 6px;"></div>
            </div>
            <div class="applicant-progress" style="margin-top: 6px;">
              <div class="progress-labels">
                <div class="skeleton" style="width: 50px; height: 12px;"></div>
                <div class="skeleton" style="width: 40px; height: 12px;"></div>
              </div>
              <div class="skeleton" style="width: 100%; height: 5px; border-radius: 99px;"></div>
            </div>
            <div class="job-card-footer" style="margin-top: 4px;">
              <div class="skeleton" style="width: 70px; height: 12px;"></div>
              <div class="skeleton" style="width: 55px; height: 16px; border-radius: 99px;"></div>
            </div>
            <div class="job-card-actions" style="margin-top: 6px;">
              <div class="skeleton" style="flex: 1; height: 28px; border-radius: 8px;"></div>
              <div class="skeleton" style="flex: 1; height: 28px; border-radius: 8px;"></div>
              <div class="skeleton" style="flex: 1; height: 28px; border-radius: 8px;"></div>
            </div>
          </div>
        </div>

        <!-- Jobs Grid -->
        <div v-else class="jobs-grid">
          <div
            v-for="job in filteredJobs"
            :key="job.id"
            class="job-card"
            :class="{ 'card-archived': listingTab === 'archived' }"
            @click="openDrawer(job)"
            style="cursor:pointer;"
          >
            <div class="job-card-header">
              <div class="job-icon-lg" :style="{ background: job.bg }">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" :stroke="job.color" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
              </div>
              <div class="job-status-wrap">
                <span class="job-status" :class="jobStatusClass(job.status)">{{ job.status }}</span>
              </div>
            </div>

            <h3 class="job-card-title">{{ job.title }}</h3>
            <div class="job-tags">
              <span class="job-tag type-tag">{{ job.type }}</span>
              <span class="job-tag">{{ job.location }}</span>
            </div>

            <!-- Salary -->
            <p class="job-salary">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:4px;vertical-align:middle"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/></svg>
              {{ job.salary }}
            </p>

            <p class="job-desc">{{ job.description }}</p>
            <div class="job-skills">
              <span v-for="sk in job.skills.slice(0,3)" :key="sk" class="skill-chip">{{ sk }}</span>
              <span v-if="job.skills.length > 3" class="skill-more">+{{ job.skills.length - 3 }}</span>
            </div>

            <!-- Applicants Progress -->
            <div class="applicant-progress">
              <div class="progress-labels">
                <span class="prog-label">{{ job.applicants }} applicants</span>
                <span class="prog-label">{{ job.slots }} slots</span>
              </div>
              <div class="prog-bar-bg">
                <div class="prog-bar-fill" :style="{ width: Math.min(job.applicants/Math.max(job.slots,1)*100,100)+'%', background: job.color }"></div>
              </div>
            </div>

            <!-- Hired row -->
            <div class="hired-row" @click.stop="viewHired(job)">
              <div class="hired-left">
                <span class="hired-dot"></span>
                <span class="hired-label">Hired</span>
                <span class="hired-count">{{ job.hired }}</span>
              </div>
              <span class="hired-link">View hired →</span>
            </div>

            <div class="job-card-footer">
              <span class="post-date">Posted  {{ job.postedDate }}</span>
              <span v-if="listingTab === 'active'" class="deadline-badge" :class="{ urgent: job.daysLeft <= 3 }">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                {{ job.daysLeft }}d left
              </span>
              <span v-else class="deadline-badge expired-badge">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="21 8 21 21 3 21 3 8"/><rect x="1" y="3" width="22" height="5"/></svg>
                Archived
              </span>
            </div>

            <!-- Card Actions -->
            <div class="job-card-actions" @click.stop>
              <button class="card-btn view-btn" @click="openDrawer(job)">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                View
              </button>

              <!-- Active: Edit + Close + Remove -->
              <template v-if="listingTab === 'active'">
                <button class="card-btn edit-btn" @click="openModal(job)">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                  Edit
                </button>
                <button class="card-btn close-btn" v-if="job.status === 'Open'" @click="closeJob(job)">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                  Close
                </button>
                <button class="card-btn remove-btn" @click="promptRemove(job)">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg>
                  Remove
                </button>
              </template>

              <!-- Archived: Repost + Remove only -->
              <template v-else>
                <button class="card-btn repost-btn" @click="repostJob(job)">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 .49-5"/></svg>
                  Repost
                </button>
                <button class="card-btn remove-btn" @click="promptRemove(job)">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg>
                  Remove
                </button>
              </template>
            </div>
          </div>

          <!-- Empty state -->
          <div v-if="filteredJobs.length === 0" class="empty-state">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
            <p v-if="listingTab === 'archived'">No archived listings yet.</p>
            <p v-else>No active listings match your filters.</p>
          </div>
        </div>

      </div>
    </div>

    <!-- JOB DRAWER -->
    <transition name="drawer">
      <div v-if="drawerOpen" class="drawer-overlay" @click.self="drawerOpen = false">
        <div class="drawer">
          <div class="drawer-header">
            <div class="drawer-icon" :style="{ background: selected?.bg }">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" :stroke="selected?.color" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
            </div>
            <div class="drawer-title-wrap">
              <h2 class="drawer-name">{{ selected?.title }}</h2>
              <p class="drawer-loc">{{ selected?.type }} · {{ selected?.location }}</p>
            </div>
            <span class="job-status" :class="jobStatusClass(selected?.status)">{{ selected?.status }}</span>
            <button class="drawer-close" @click="drawerOpen = false">✕</button>
          </div>

          <!-- Drawer Tabs -->
          <div class="drawer-tabs">
            <button v-for="dt in ['Overview', 'Hired']" :key="dt"
              :class="['dtab', { active: drawerTab === dt }]"
              @click="drawerTab = dt; dt === 'Hired' && fetchHiredApplicants(selected)">
              {{ dt }}
              <span v-if="dt === 'Hired'" class="dtab-pill">{{ selected?.hired }}</span>
            </button>
          </div>

          <div class="drawer-body">

            <!-- Overview Tab -->
            <div v-if="drawerTab === 'Overview'">
              <div class="info-grid">
                <div class="info-item"><span class="info-label">Salary</span><span class="info-val">{{ selected?.salary }}</span></div>
                <div class="info-item"><span class="info-label">Slots</span><span class="info-val">{{ selected?.slots }} positions</span></div>
                <div class="info-item"><span class="info-label">Education</span><span class="info-val">{{ formatEducation(selected?.education_level) }}</span></div>
                <div class="info-item"><span class="info-label">Experience</span><span class="info-val">{{ formatExperience(selected?.experience_required) }}</span></div>
                <div class="info-item"><span class="info-label">Posted</span><span class="info-val">{{ selected?.postedDate }}</span></div>
                <div class="info-item"><span class="info-label">Deadline</span><span class="info-val">{{ selected?.daysLeft > 0 ? selected?.daysLeft + ' days left' : 'Expired' }}</span></div>
                <div class="info-item"><span class="info-label">Applicants</span><span class="info-val">{{ selected?.applicants }}</span></div>
                <div class="info-item">
                  <span class="info-label">Hired</span>
                  <span class="info-val hired-val" @click="drawerTab = 'Hired'; fetchHiredApplicants(selected)">
                    {{ selected?.hired }}
                  </span>
                </div>
              </div>
              <div class="section-label">Description</div>
              <p class="desc-text">{{ selected?.description }}</p>
              <div class="section-label">Required Skills</div>
              <div class="skill-tags mt4">
                <span v-for="sk in selected?.skills" :key="sk" class="skill-chip">{{ sk }}</span>
              </div>

              <!-- Drawer actions for archived -->
              <div v-if="listingTab === 'archived'" style="margin-top:20px;">
                <button class="btn-amber" style="width:100%;justify-content:center;" @click="repostJob(selected); drawerOpen = false">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:6px"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 .49-5"/></svg>
                  Repost this Job
                </button>
              </div>
            </div>

            <!-- Hired Tab -->
            <div v-if="drawerTab === 'Hired'">
              <div v-if="hiredLoading" style="display:flex;flex-direction:column;gap:10px;padding-top:4px;">
                <div v-for="i in 4" :key="i" class="skeleton" style="width:100%;height:56px;border-radius:10px;"></div>
              </div>
              <div v-else-if="hiredApplicants.length === 0" style="text-align:center;padding:40px 20px;color:#94a3b8;font-size:13px;">
                <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5" style="margin-bottom:8px"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
                <p>No hired applicants yet.</p>
              </div>
              <div v-else class="hired-list">
                <div v-for="h in hiredApplicants" :key="h.id" class="hired-row-item">
                  <div class="avatar-circle" :style="{ background: h.color }">
                    <img v-if="h.photo" :src="h.photo" :alt="h.name" style="width:100%;height:100%;object-fit:cover;border-radius:inherit;" />
                    <span v-else>{{ h.name?.[0] }}</span>
                  </div>
                  <div class="hired-info">
                    <p class="hired-name">{{ h.name }}</p>
                    <p class="hired-job">{{ h.course || h.school || '—' }}</p>
                  </div>
                  <div class="hired-right">
                    <span class="hired-badge-chip">Hired</span>
                    <p class="hired-date">{{ h.hiredDate }}</p>
                  </div>
                </div>
              </div>
            </div>

          </div>
        </div>
      </div>
    </transition>

    <!-- POST / EDIT MODAL -->
    <transition name="modal">
      <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
        <div class="modal">
          <div class="modal-header">
            <div class="modal-icon-wrap">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
            </div>
            <div>
              <h3 class="modal-title">{{ editingJob ? 'Edit Job Listing' : 'Post a New Job' }}</h3>
              <p class="modal-sub">{{ editingJob ? 'Update the details of this position' : 'Fill in the details to post a new opening' }}</p>
            </div>
            <button class="modal-close" @click="showModal = false">✕</button>
          </div>
          <div class="modal-body">

            <!-- Row 1: Title + Type -->
            <div class="form-row two">
              <div class="form-group">
                <label class="form-label">Job Title <span class="req">*</span></label>
                <input v-model="form.title" class="form-input" placeholder="e.g. Frontend Developer"/>
              </div>
              <div class="form-group">
                <label class="form-label">Employment Type <span class="req">*</span></label>
                <select v-model="form.type" class="form-input">
                  <option value="">Select type</option>
                  <option>Full-time</option>
                  <option>Part-time</option>
                  <option>Contract</option>
                  <option>Internship</option>
                </select>
              </div>
            </div>

            <!-- Row 2: Education + Experience (NEW) -->
            <div class="form-row two">
              <div class="form-group">
                <label class="form-label">Minimum Education Level <span class="req">*</span></label>
                <select v-model="form.education_level" class="form-input">
                  <option value="">Select education</option>
                  <option value="no_requirement">No requirement</option>
                  <option value="elementary">Elementary Graduate</option>
                  <option value="highschool">High School Graduate</option>
                  <option value="senior_highschool">Senior High School / K-12</option>
                  <option value="vocational">Vocational / TESDA</option>
                  <option value="college_level">At least College Level</option>
                  <option value="college_graduate">College Graduate (Any Course)</option>
                  <option value="related_course">College Graduate (Related Course)</option>
                  <option value="postgraduate">Post-Graduate / Master's</option>
                </select>
              </div>
              <div class="form-group">
                <label class="form-label">Years of Experience <span class="req">*</span></label>
                <select v-model="form.experience_required" class="form-input">
                  <option value="">Select experience</option>
                  <option value="fresh_grad">Fresh Graduate / No experience needed</option>
                  <option value="less_than_1">Less than 1 year</option>
                  <option value="1_year">At least 1 year</option>
                  <option value="2_years">At least 2 years</option>
                  <option value="3_years">At least 3 years</option>
                  <option value="5_years">At least 5 years</option>
                  <option value="10_years">10 years or more</option>
                </select>
              </div>
            </div>

            <!-- Salary selector -->
            <div class="form-group">
              <label class="form-label">Salary <span class="req">*</span></label>
              <div class="salary-options">
                <button
                  type="button"
                  :class="['salary-opt', { active: form.salary === 'Minimum Wage' }]"
                  @click="form.salary = 'Minimum Wage'"
                >
                  <span class="salary-opt-icon">₱</span>
                  <div>
                    <p class="salary-opt-title">Minimum Wage</p>
                    <p class="salary-opt-sub">As per DOLE standard</p>
                  </div>
                  <span class="salary-opt-check" v-if="form.salary === 'Minimum Wage'">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  </span>
                </button>
                <button
                  type="button"
                  :class="['salary-opt', { active: form.salary === 'Above Minimum Wage' }]"
                  @click="form.salary = 'Above Minimum Wage'"
                >
                  <span class="salary-opt-icon">₱+</span>
                  <div>
                    <p class="salary-opt-title">Above Minimum Wage</p>
                    <p class="salary-opt-sub">Higher than DOLE standard</p>
                  </div>
                  <span class="salary-opt-check" v-if="form.salary === 'Above Minimum Wage'">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  </span>
                </button>
              </div>
            </div>

            <!-- Row 3: Slots + Status -->
            <div class="form-row two">
              <div class="form-group">
                <label class="form-label">Number of Slots <span class="req">*</span></label>
                <input v-model="form.slots" type="number" class="form-input" placeholder="e.g. 5"/>
              </div>
              <div class="form-group">
                <label class="form-label">Status <span class="req">*</span></label>
                <select v-model="form.status" class="form-input">
                  <option value="Open">Open</option>
                  <option value="Draft">Draft</option>
                  <option value="Closed">Closed</option>
                </select>
              </div>
            </div>

            <!-- Row 4: Location (pre-filled) + Deadline -->
            <div class="form-row two">
              <div class="form-group">
                <label class="form-label" style="display:flex;align-items:center;gap:5px;">
                  Location
                  <span v-if="locationPrefilled" style="display:inline-flex;align-items:center;gap:3px;font-size:10px;font-weight:700;color:#22c55e;background:#f0fdf4;border:1px solid #bbf7d0;border-radius:99px;padding:2px 7px;text-transform:none;letter-spacing:0;">
                    <svg width="9" height="9" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
                    Auto-filled
                  </span>
                </label>
                <input v-model="form.location" class="form-input" placeholder="e.g. Quezon City / Remote"/>
                <p style="font-size:11px;color:#94a3b8;margin-top:3px;">Edit if the job is at a different branch or remote.</p>
              </div>
              <div class="form-group">
                <label class="form-label">Deadline (Days)</label>
                <input v-model="form.daysLeft" type="number" class="form-input" placeholder="e.g. 30"/>
              </div>
            </div>

            <!-- Description -->
            <div class="form-group">
              <label class="form-label">Job Description <span class="req">*</span></label>
              <textarea v-model="form.description" class="form-input textarea" rows="3" placeholder="Describe the role, responsibilities, and requirements…"></textarea>
            </div>

            <!-- Skills -->
            <div class="form-group">
              <label class="form-label">Required Skills <span class="req">*</span></label>
              <div class="skills-picker">
                <div class="picked-chips" v-if="selectedSkills.length">
                  <span v-for="sk in selectedSkills" :key="sk" class="picked-chip">
                    {{ sk }}
                    <button type="button" class="chip-remove" @click="removeSkill(sk)">×</button>
                  </span>
                </div>
                <div class="skill-autocomplete-zone">
                  <div class="skill-input-wrap">
                    <span class="skill-search-icon">⌕</span>
                    <input
                      v-model="skillQuery"
                      class="form-input skill-input"
                      placeholder="Search from catalog or type custom skill"
                      @focus="showSkillSuggestions = true"
                      @input="onSkillInput"
                      @keydown.enter.prevent="addSkillFromInput"
                      @blur="onSkillBlur"
                    />
                    <button type="button" class="skill-add-btn" @click="addSkillFromInput">Add</button>
                    <button type="button" class="skill-browse-btn" @click="toggleCatalogBrowser">Browse</button>
                  </div>
                  <div v-if="showSkillSuggestions && skillSuggestions.length" class="skills-suggestions">
                    <div class="skill-suggestions-head">Suggested skills <span>{{ skillSuggestions.length }}</span></div>
                    <div v-for="opt in skillSuggestions.slice(0, 8)" :key="opt" class="skill-suggestion-item" @mousedown.prevent="addSkill(opt)">
                      <span class="skill-suggestion-plus">+</span>{{ opt }}
                    </div>
                  </div>
                  <div v-else-if="showSkillSuggestions && skillQuery.trim()" class="skills-custom-hint">
                    Press <strong>Enter</strong> to add "<em>{{ skillQuery.trim() }}</em>" as a custom skill.
                  </div>
                </div>
                <p class="skills-helper">Tips: pick from suggestions for best matches. Custom skills are allowed.</p>
                <div v-if="showCatalogBrowser" class="catalog-browser">
                  <div class="catalog-browser-head">
                    <h4>Skills Catalog</h4>
                    <button type="button" class="catalog-close-btn" @click="showCatalogBrowser = false">Close</button>
                  </div>
                  <div class="catalog-controls">
                    <input v-model="catalogSearch" class="form-input catalog-search" placeholder="Search all skills..."/>
                    <select v-model="catalogCategory" class="form-input catalog-category">
                      <option value="">All Categories</option>
                      <option v-for="cat in catalogCategories" :key="cat" :value="cat">{{ cat }}</option>
                    </select>
                  </div>
                  <div class="catalog-list">
                    <div v-for="item in filteredCatalogItems.slice(0, 120)" :key="item.name" class="catalog-row">
                      <div class="catalog-meta">
                        <div class="catalog-skill">{{ item.name }}</div>
                        <div class="catalog-cat">{{ item.category || 'Other' }}</div>
                      </div>
                      <button type="button" class="catalog-action" :class="{ selected: isSkillSelected(item.name) }" @click="toggleSkill(item.name)">
                        {{ isSkillSelected(item.name) ? 'Remove' : 'Add' }}
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>

          </div>
          <div class="modal-footer">
            <button class="btn-ghost" @click="showModal = false" :disabled="savingJob">Cancel</button>
            <button class="btn-amber" @click="saveJob" :disabled="savingJob">
              <span v-if="savingJob" class="spinner-sm" style="margin-right:6px;"></span>
              {{ editingJob ? (savingJob ? 'Saving…' : 'Save Changes') : (savingJob ? 'Posting…' : 'Post Job') }}
            </button>
          </div>
        </div>
      </div>
    </transition>

  </div>

  <!-- REMOVE CONFIRMATION MODAL -->
  <transition name="modal">
    <div v-if="removeTarget" class="modal-overlay" @click.self="removeTarget = null">
      <div class="modal confirm-modal">
        <div class="modal-header">
          <div class="modal-icon-wrap" style="background:#fef2f2">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg>
          </div>
          <div>
            <h3 class="modal-title">Remove Job Listing</h3>
            <p class="modal-sub">This will remove the listing from your view.</p>
          </div>
          <button class="modal-close" @click="removeTarget = null">✕</button>
        </div>
        <div class="modal-body" style="padding:16px 24px">
          <p style="font-size:13px;color:#475569;line-height:1.6">
            Are you sure you want to remove <strong>{{ removeTarget?.title }}</strong>? This action cannot be undone from the employer portal.
          </p>
        </div>
        <div class="modal-footer">
          <button class="btn-ghost" @click="removeTarget = null">Cancel</button>
          <button class="btn-remove" @click="confirmRemove" :disabled="removingJob">
            <span v-if="removingJob" class="spinner-sm"></span>
            {{ removingJob ? 'Removing…' : 'Yes, Remove' }}
          </button>
        </div>
      </div>
    </div>
  </transition>

</template>

<script>
import api from '@/services/api'
import EmployerSidebar from '@/components/EmployerSidebar.vue'
import EmployerTopbar from '@/components/EmployerTopbar.vue'
import { useEmployerAuthStore } from '@/stores/employerAuth'

export default {
  name: 'EmployerJobListings',
  components: { EmployerSidebar, EmployerTopbar },
  async mounted() {
    await this.fetchJobs()
  },
  data() {
    return {
      isLoading: true,
      listingTab: 'active',
      search: '', filterType: '',
      drawerOpen: false, selected: null,
      drawerTab: 'Overview',
      hiredApplicants: [],
      hiredLoading: false,
      showModal: false, editingJob: null, savingJob: false,
      locationPrefilled: false,
      removeTarget: null, removingJob: false,
      form: {
        title: '', type: '',
        education_level: '', experience_required: '',
        salary: 'Minimum Wage', slots: '',
        location: '', daysLeft: '',
        description: '', status: 'Open',
      },
      selectedSkills: [],
      skillCatalog: [],
      skillCatalogItems: [],
      skillQuery: '',
      showSkillSuggestions: false,
      showCatalogBrowser: false,
      catalogSearch: '',
      catalogCategory: '',
      jobs: [],
      toast: { show: false, text: '', type: 'success', icon: '', _timer: null },
    }
  },
  computed: {
    activeJobs() {
      return this.jobs.filter(j => {
        const expired = j.daysLeft <= 0
        const isClosed = j.status === 'Closed'
        return !expired && !isClosed
      })
    },
    archivedJobs() {
      return this.jobs.filter(j => {
        const expired = j.daysLeft <= 0
        const isClosed = j.status === 'Closed'
        return expired || isClosed
      })
    },
    filteredJobs() {
      const source = this.listingTab === 'archived' ? this.archivedJobs : this.activeJobs
      return source.filter(j => {
        const matchSearch = !this.search || j.title.toLowerCase().includes(this.search.toLowerCase())
        const matchType   = !this.filterType || j.type === this.filterType
        return matchSearch && matchType
      })
    },
    skillSuggestions() {
      const q = this.skillQuery.trim().toLowerCase()
      if (!q) return []
      return this.skillCatalog
        .filter(s => !this.selectedSkills.includes(s))
        .filter(s => s.toLowerCase().includes(q))
    },
    catalogCategories() {
      const set = new Set(
        this.skillCatalogItems
          .map(s => (s.category || 'Other').trim())
          .filter(Boolean)
      )
      return Array.from(set).sort((a, b) => a.localeCompare(b))
    },
    filteredCatalogItems() {
      const q = this.catalogSearch.trim().toLowerCase()
      return this.skillCatalogItems.filter(item => {
        const cat = (item.category || 'Other').trim()
        const matchCat = !this.catalogCategory || cat === this.catalogCategory
        const matchQ   = !q || item.name.toLowerCase().includes(q)
        return matchCat && matchQ
      })
    },
  },
  methods: {
    mapJobFromApi(j, idx) {
      const colors = [
        ['#eff6ff','#2563eb'],
        ['#faf5ff','#8b5cf6'],
        ['#fdf4ff','#d946ef'],
        ['#f0fdf4','#22c55e'],
        ['#eff8ff','#2872A1'],
      ]
      let skills = []
      if (Array.isArray(j.skills)) {
        skills = j.skills.map(s => typeof s === 'string' ? s : s.skill || s).filter(Boolean)
      } else if (j.skills) {
        skills = (j.skills || '').split(',').map(s => s.trim()).filter(Boolean)
      }

      const rawSalary = j.salary_range || j.salary || ''
      let salary = 'Minimum Wage'
      if (rawSalary.toLowerCase().includes('above') || rawSalary === 'Above Minimum Wage') {
        salary = 'Above Minimum Wage'
      } else if (rawSalary === 'Minimum Wage') {
        salary = 'Minimum Wage'
      } else if (rawSalary) {
        salary = rawSalary
      }

      return {
        id:                  j.id,
        title:               j.title,
        type:                j.type ? j.type.charAt(0).toUpperCase() + j.type.slice(1) : '',
        location:            j.location,
        salary,
        slots:               j.slots || 0,
        applicants:          Number(j.applications_count) || 0,
        hired:               Number(j.hired_count) || 0,
        status:              j.status ? j.status.charAt(0).toUpperCase() + j.status.slice(1) : '',
        education_level:     j.education_level     || '',
        experience_required: j.experience_required || '',
        daysLeft:            j.deadline
          ? Math.ceil((new Date(j.deadline) - new Date()) / (1000 * 60 * 60 * 24))
          : 30,
        postedDate:  j.posted_date
          ? new Date(j.posted_date).toLocaleDateString('en-US', { month: 'short', day: '2-digit', year: 'numeric' })
          : '—',
        description: j.description,
        skills,
        bg:    colors[idx % colors.length][0],
        color: colors[idx % colors.length][1],
      }
    },

    formatEducation(val) {
      const map = {
        no_requirement:   'No requirement',
        elementary:       'Elementary Graduate',
        highschool:       'High School Graduate',
        senior_highschool:'Senior High School / K-12',
        vocational:       'Vocational / TESDA',
        college_level:    'At least College Level',
        college_graduate: 'College Graduate (Any Course)',
        related_course:   'College Graduate (Related Course)',
        postgraduate:     'Post-Graduate / Master\'s',
      }
      return map[val] || val || '—'
    },

    formatExperience(val) {
      const map = {
        fresh_grad:   'Fresh Graduate / No experience',
        less_than_1:  'Less than 1 year',
        '1_year':     'At least 1 year',
        '2_years':    'At least 2 years',
        '3_years':    'At least 3 years',
        '5_years':    'At least 5 years',
        '10_years':   '10 years or more',
      }
      return map[val] || val || '—'
    },

    async fetchJobs() {
      this.isLoading = true
      try {
        const params = {}
        if (this.search)     params.search = this.search
        if (this.filterType) params.type   = this.filterType
        const { data } = await api.get('/employer/jobs', { params })
        const jobsData  = data.data?.data || data.data || data || []
        const jobsArray = Array.isArray(jobsData) ? jobsData : []
        this.jobs = jobsArray.map((j, idx) => this.mapJobFromApi(j, idx))
      } catch (e) {
        console.error('Failed to fetch jobs:', e)
        this.jobs = []
      } finally {
        this.isLoading = false
      }
    },

    async fetchHiredApplicants(job) {
      if (!job) return
      this.hiredLoading = true
      this.hiredApplicants = []
      try {
        const { data } = await api.get('/employer/applications', {
          params: { job_listing_id: job.id, status: 'hired' }
        })

        console.log('RAW hired response:', JSON.stringify(data, null, 2))

        const list = data.data?.data || data.data || data || []
        const colorPool = ['#2563eb','#22c55e','#f97316','#8b5cf6','#ef4444','#06b6d4','#14b8a6']
        this.hiredApplicants = list.map((a, i) => ({
          id:        a.id,
          name:      a.jobseeker?.full_name
                    || `${a.jobseeker?.first_name || ''} ${a.jobseeker?.last_name || ''}`.trim()
                    || 'Unknown',
          photo:     a.jobseeker?.photo
                    ? (a.jobseeker.photo.startsWith('http') ? a.jobseeker.photo : '/storage/' + a.jobseeker.photo)
                    : null,
          course:    a.jobseeker?.education_level || null,
          school:    a.jobseeker?.address || null,
          hiredDate: a.updated_at
            ? new Date(a.updated_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
            : '—',
          color: colorPool[i % colorPool.length],
        }))
      } catch (e) {
        console.error('Failed to fetch hired applicants:', e)
        this.hiredApplicants = []
      } finally {
        this.hiredLoading = false
      }
    },

    jobStatusClass(s) {
      return { Open:'status-open', Closed:'status-closed', Draft:'status-draft' }[s] || ''
    },

    openDrawer(job) {
      this.selected         = job
      this.drawerTab        = 'Overview'
      this.hiredApplicants  = []
      this.drawerOpen       = true
    },

    viewHired(job) {
      if (!job) return
      this.selected        = job
      this.drawerTab       = 'Hired'
      this.drawerOpen      = true
      this.fetchHiredApplicants(job)
    },

    openModal(job) {
      this.editingJob = job
      if (job) {
        this.form = {
          ...job,
          education_level:     job.education_level     || '',
          experience_required: job.experience_required || '',
          salary: job.salary === 'Above Minimum Wage' ? 'Above Minimum Wage' : 'Minimum Wage',
        }
        this.selectedSkills    = Array.isArray(job.skills) ? [...job.skills] : []
        this.locationPrefilled = false
      } else {
        // Pre-fill location from employer's registered address
        const employer = useEmployerAuthStore().user
        const formatTitle = (str) => str ? str.split(' ').map(w => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase()).join(' ') : ''
        const parts = [
          employer?.barangay,
          formatTitle(employer?.city),
          formatTitle(employer?.province)
        ].filter(Boolean)
        const prefilled = parts.join(', ') || formatTitle(employer?.city) || ''

        this.form = {
          title: '', type: '',
          education_level: '', experience_required: '',
          salary: 'Minimum Wage', slots: '',
          location: prefilled,
          daysLeft: '', description: '', status: 'Open',
        }
        this.selectedSkills    = []
        this.locationPrefilled = !!prefilled
      }
      this.skillQuery           = ''
      this.showSkillSuggestions = false
      this.showCatalogBrowser   = false
      this.catalogSearch        = ''
      this.catalogCategory      = ''
      this.showModal            = true
    },

    repostJob(job) {
      this.editingJob = null
      this.form = {
        title:               job.title,
        type:                job.type,
        education_level:     job.education_level     || '',
        experience_required: job.experience_required || '',
        salary:              job.salary === 'Above Minimum Wage' ? 'Above Minimum Wage' : 'Minimum Wage',
        slots:               job.slots,
        location:            job.location,
        daysLeft:            30,
        description:         job.description,
        status:              'Open',
      }
      this.selectedSkills       = [...job.skills]
      this.locationPrefilled    = false
      this.skillQuery           = ''
      this.showSkillSuggestions = false
      this.showCatalogBrowser   = false
      this.catalogSearch        = ''
      this.catalogCategory      = ''
      this.showModal            = true
      this.showToastMsg('Listing pre-filled — review and post to reactivate.', 'success')
    },

    async ensureCatalogLoaded() {
      if (this.skillCatalog.length) return
      try {
        const { data } = await api.get('/public/skills')
        const rows = data.data || []
        this.skillCatalogItems = rows
          .map(r => ({
            name:     (typeof r === 'string' ? r : r.name || '').trim(),
            category: (typeof r === 'string' ? null : r.category || null),
          }))
          .filter(r => r.name)
        this.skillCatalog = this.skillCatalogItems.map(r => r.name)
      } catch (_) {
        this.skillCatalog      = []
        this.skillCatalogItems = []
      }
    },

    async onSkillInput() {
      await this.ensureCatalogLoaded()
      this.showSkillSuggestions = true
    },

    toggleCatalogBrowser() {
      this.showCatalogBrowser = !this.showCatalogBrowser
      if (this.showCatalogBrowser) this.ensureCatalogLoaded()
    },

    addSkill(skillName) {
      const raw = (skillName || '').trim()
      if (!raw) return
      const catalogExact = this.skillCatalog.find(s => s.toLowerCase() === raw.toLowerCase())
      const canonical    = catalogExact || raw
      if (!this.selectedSkills.some(s => s.toLowerCase() === canonical.toLowerCase())) {
        this.selectedSkills.push(canonical)
      }
      this.skillQuery           = ''
      this.showSkillSuggestions = false
    },
    addSkillFromInput() { this.addSkill(this.skillQuery) },
    isSkillSelected(skillName) {
      return this.selectedSkills.some(s => s.toLowerCase() === skillName.toLowerCase())
    },
    toggleSkill(skillName) {
      if (this.isSkillSelected(skillName)) this.removeSkill(skillName)
      else this.addSkill(skillName)
    },
    onSkillBlur() { setTimeout(() => { this.showSkillSuggestions = false }, 120) },
    removeSkill(skillName) {
      this.selectedSkills = this.selectedSkills.filter(s => s !== skillName)
    },

    async saveJob() {
      if (this.savingJob) return
      this.savingJob = true
      const skillsArr = [...this.selectedSkills]
      try {
        const payload = { ...this.form, skills: skillsArr }
        if (this.editingJob) {
          const { data } = await api.put(`/employer/jobs/${this.editingJob.id}`, payload)
          const idx = this.jobs.findIndex(j => j.id === this.editingJob.id)
          if (idx !== -1) {
            const updated = data.data || data
            this.jobs[idx] = this.mapJobFromApi({ ...updated, skills: skillsArr }, idx)
          }
        } else {
          const { data } = await api.post('/employer/jobs', payload)
          const newJob   = data.data || data
          const mapped   = this.mapJobFromApi({ ...newJob, skills: skillsArr }, 0)
          this.jobs.unshift(mapped)   // insert at TOP so newest appears first
          this.listingTab = 'active'
        }
        this.showModal = false
        this.showToastMsg(this.editingJob ? 'Job updated successfully' : 'Job posted successfully', 'success')
      } catch (e) {
        console.error(e)
        this.showToastMsg('An error occurred. Please check details.', 'error')
      } finally {
        this.savingJob = false
      }
    },

    async closeJob(job) {
      try {
        await api.patch(`/employer/jobs/${job.id}/close`)
        const idx = this.jobs.findIndex(j => j.id === job.id)
        if (idx !== -1) this.jobs[idx].status = 'Closed'
        if (this.selected?.id === job.id) this.selected.status = 'Closed'
        this.showToastMsg('Job closed and moved to Archived', 'success')
      } catch (e) {
        console.error(e)
        this.showToastMsg('Failed to close job', 'error')
      }
    },

    async deleteJob(job) {
      try {
        await api.delete(`/employer/jobs/${job.id}`)
        this.jobs = this.jobs.filter(j => j.id !== job.id)
        this.drawerOpen = false
        this.showToastMsg('Job deleted successfully', 'success')
      } catch (e) {
        console.error(e)
        this.showToastMsg('Failed to delete job', 'error')
      }
    },

    promptRemove(job) { this.removeTarget = job },

    async confirmRemove() {
      if (!this.removeTarget || this.removingJob) return
      this.removingJob = true
      try {
        await this.deleteJob(this.removeTarget)
        this.removeTarget = null
      } finally {
        this.removingJob = false
      }
    },

    showToastMsg(text, type = 'success') {
      const CHECK = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>`
      const X     = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`
      if (this.toast._timer) clearTimeout(this.toast._timer)
      this.toast = {
        show: true, text, type,
        icon: type === 'success' ? CHECK : X,
        _timer: setTimeout(() => { this.toast.show = false }, 3500),
      }
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
.layout-wrapper { display: flex; height: 100vh; overflow: hidden; background: #f8fafc; font-family: 'Plus Jakarta Sans', sans-serif; }
.main-area { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
.page { flex: 1; overflow-y: auto; padding: 24px; display: flex; flex-direction: column; gap: 16px; }

.filters-bar { display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; flex: 1; max-width: 360px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-group { display: flex; align-items: center; gap: 8px; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }
.btn-amber { display: flex; align-items: center; justify-content: center; gap: 6px; background: #2872A1; color: #fff; border: none; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; transition: background 0.15s; }
.btn-amber:hover:not(:disabled) { background: #1a5f8a; }
.btn-amber:disabled { opacity: 0.7; cursor: not-allowed; }

.skeleton { background: #e2e8f0; border-radius: 4px; animation: pulse 1.5s infinite; }
@keyframes pulse { 0% { opacity: 0.6; } 50% { opacity: 0.3; } 100% { opacity: 0.6; } }

.spinner-sm { width: 14px; height: 14px; flex-shrink: 0; border: 2px solid rgba(255,255,255,0.4); border-top-color: #fff; border-radius: 50%; animation: spin 0.7s linear infinite; display: inline-block; }
@keyframes spin { to { transform: rotate(360deg); } }

.jobs-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; }
.job-card { background: #fff; border-radius: 14px; padding: 18px; border: 1px solid #f1f5f9; display: flex; flex-direction: column; gap: 10px; transition: box-shadow 0.15s; }
.job-card:hover { box-shadow: 0 4px 20px rgba(0,0,0,0.07); }
.job-card-header { display: flex; align-items: center; justify-content: space-between; }
.job-icon-lg { width: 40px; height: 40px; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.job-status { font-size: 11px; font-weight: 700; padding: 3px 10px; border-radius: 99px; }
.status-open   { background: #f0fdf4; color: #22c55e; }
.status-closed { background: #f1f5f9; color: #94a3b8; }
.status-draft  { background: #eff8ff; color: #1a5f8a; }
.job-card-title { font-size: 15px; font-weight: 800; color: #1e293b; line-height: 1.2; }
.job-tags { display: flex; gap: 6px; flex-wrap: wrap; }
.job-tag { font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; background: #f1f5f9; color: #64748b; }
.type-tag { background: #eff6ff; color: #2563eb; }
.job-salary { font-size: 13px; font-weight: 700; color: #2872A1; }
.job-desc { font-size: 12px; color: #64748b; line-height: 1.5; display: -webkit-box; -webkit-line-clamp: 2; line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.job-skills { display: flex; gap: 5px; flex-wrap: wrap; }
.skill-chip { font-size: 11px; font-weight: 500; padding: 3px 8px; border-radius: 6px; background: #f8fafc; color: #64748b; border: 1px solid #f1f5f9; }
.skill-more { font-size: 11px; color: #94a3b8; }

.applicant-progress { display: flex; flex-direction: column; gap: 5px; }
.progress-labels { display: flex; justify-content: space-between; }
.prog-label { font-size: 11px; color: #94a3b8; }
.prog-bar-bg { height: 5px; background: #f1f5f9; border-radius: 99px; overflow: hidden; }
.prog-bar-fill { height: 100%; border-radius: 99px; }

.job-card-footer { display: flex; align-items: center; justify-content: space-between; }
.post-date { font-size: 11px; color: #94a3b8; }
.deadline-badge { display: flex; align-items: center; gap: 4px; font-size: 11px; font-weight: 600; color: #64748b; background: #f1f5f9; padding: 3px 8px; border-radius: 99px; }
.deadline-badge.urgent { background: #fef2f2; color: #ef4444; }
.job-card-actions { display: flex; gap: 6px; margin-top: 2px; }
.card-btn { flex: 1; display: flex; align-items: center; justify-content: center; gap: 5px; padding: 8px; border-radius: 8px; font-size: 12px; font-weight: 600; cursor: pointer; font-family: inherit; border: none; transition: all 0.15s; }
.view-btn   { background: #f1f5f9; color: #64748b; }
.view-btn:hover   { background: #e2e8f0; }
.edit-btn   { background: #eff8ff; color: #1a5f8a; }
.edit-btn:hover   { background: #bae6fd; }
.close-btn  { background: #fef2f2; color: #ef4444; }
.close-btn:hover  { background: #fee2e2; }
.remove-btn { background: #fef2f2; color: #ef4444; }
.remove-btn:hover { background: #fee2e2; }
.btn-remove { display: flex; align-items: center; gap: 6px; background: #ef4444; color: #fff; border: none; border-radius: 10px; padding: 9px 18px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-remove:hover:not(:disabled) { background: #dc2626; }
.btn-remove:disabled { opacity: 0.65; cursor: not-allowed; }
.confirm-modal { max-width: 420px; }

/* DRAWER */
.drawer-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.3); z-index: 100; display: flex; justify-content: flex-end; backdrop-filter: blur(2px); }
.drawer { width: 420px; height: 100vh; background: #fff; display: flex; flex-direction: column; overflow: hidden; box-shadow: -8px 0 32px rgba(0,0,0,0.12); }
.drawer-header { display: flex; align-items: center; gap: 12px; padding: 20px; border-bottom: 1px solid #f1f5f9; }
.drawer-icon { width: 46px; height: 46px; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.drawer-title-wrap { flex: 1; }
.drawer-name { font-size: 16px; font-weight: 800; color: #1e293b; }
.drawer-loc { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.drawer-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 16px; padding: 4px; border-radius: 6px; }
.drawer-close:hover { background: #f1f5f9; }
.drawer-body { flex: 1; overflow-y: auto; padding: 20px; display: flex; flex-direction: column; gap: 4px; }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 16px; }
.info-item { display: flex; flex-direction: column; gap: 3px; }
.info-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
.info-val { font-size: 13px; font-weight: 500; color: #1e293b; }
.section-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.06em; margin: 14px 0 8px; }
.desc-text { font-size: 13px; color: #64748b; line-height: 1.6; }
.skill-tags { display: flex; gap: 6px; flex-wrap: wrap; }
.mt4 { margin-top: 4px; }

/* MODAL */
.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.4); z-index: 100; display: flex; align-items: center; justify-content: center; backdrop-filter: blur(2px); }
.modal { background: #fff; border-radius: 16px; width: 560px; max-width: 95vw; box-shadow: 0 20px 60px rgba(0,0,0,0.15); max-height: 90vh; display: flex; flex-direction: column; }
.modal-header { display: flex; align-items: center; gap: 12px; padding: 20px 24px; border-bottom: 1px solid #f1f5f9; }
.modal-icon-wrap { width: 40px; height: 40px; background: #eff8ff; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.modal-title { font-size: 16px; font-weight: 800; color: #1e293b; }
.modal-sub { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.modal-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 18px; padding: 4px; border-radius: 6px; margin-left: auto; line-height: 1; }
.modal-close:hover { background: #f1f5f9; }
.modal-body { padding: 20px 24px; display: flex; flex-direction: column; gap: 14px; overflow-y: auto; flex: 1; }
.modal-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 16px 24px; border-top: 1px solid #f1f5f9; }
.form-row { display: grid; gap: 12px; }
.form-row.two { grid-template-columns: 1fr 1fr; }
.form-group { display: flex; flex-direction: column; gap: 5px; }
.form-label { font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; }
.req { color: #ef4444; }
.form-input { border: 1px solid #e2e8f0; border-radius: 8px; padding: 9px 12px; font-size: 13px; color: #1e293b; font-family: inherit; outline: none; background: #f8fafc; transition: border 0.15s; box-sizing: border-box; height: 40px; }
select.form-input { -webkit-appearance: none; appearance: none; background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='2.5'%3E%3Cpolyline points='6 9 12 15 18 9'/%3E%3C/svg%3E"); background-repeat: no-repeat; background-position: right 10px center; padding-right: 30px; cursor: pointer; }
.form-input:focus { border-color: #08BDDE; background: #fff; }
.form-input.textarea { resize: vertical; }
.btn-ghost { background: #f1f5f9; color: #64748b; border: none; border-radius: 10px; padding: 9px 18px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-ghost:hover { background: #e2e8f0; }

/* Skills picker */
.skills-picker { position: relative; border: 1px solid #e2e8f0; border-radius: 12px; background: #fff; padding: 10px; overflow: visible; }
.picked-chips { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 8px; }
.picked-chip { display: inline-flex; align-items: center; gap: 6px; font-size: 12px; font-weight: 600; color: #1e3a8a; background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 999px; padding: 5px 10px; }
.chip-remove { border: none; background: transparent; color: #1d4ed8; font-size: 14px; line-height: 1; cursor: pointer; padding: 0; }
.skill-input-wrap { display: flex; align-items: center; gap: 8px; }
.skill-autocomplete-zone { position: relative; z-index: 30; }
.skill-search-icon { color: #94a3b8; font-size: 14px; width: 14px; text-align: center; }
.skill-input { flex: 1; background: #f8fafc; }
.skill-add-btn { border: none; border-radius: 8px; background: #e2e8f0; color: #334155; font-size: 12px; font-weight: 700; padding: 8px 12px; cursor: pointer; transition: all 0.15s; }
.skill-add-btn:hover { background: #cbd5e1; }
.skill-browse-btn { border: 1px solid #cbd5e1; border-radius: 8px; background: #fff; color: #334155; font-size: 12px; font-weight: 700; padding: 8px 10px; cursor: pointer; }
.skill-browse-btn:hover { background: #f8fafc; }
.skills-suggestions { position: absolute; left: 0; right: 0; top: calc(100% + 6px); background: #fff; border: 1px solid #e2e8f0; border-radius: 12px; box-shadow: 0 10px 24px rgba(15,23,42,0.12); max-height: 220px; overflow-y: auto; z-index: 50; }
.skill-suggestions-head { display: flex; align-items: center; justify-content: space-between; font-size: 11px; font-weight: 700; color: #64748b; background: #f8fafc; padding: 8px 10px; border-bottom: 1px solid #f1f5f9; }
.skill-suggestions-head span { color: #0f172a; }
.skill-suggestion-item { display: flex; align-items: center; gap: 8px; font-size: 13px; color: #0f172a; padding: 10px; cursor: pointer; }
.skill-suggestion-item:hover { background: #f8fafc; }
.skill-suggestion-plus { display: inline-flex; align-items: center; justify-content: center; width: 18px; height: 18px; border-radius: 999px; background: #ecfeff; color: #0e7490; font-weight: 700; }
.skills-custom-hint { position: absolute; left: 0; right: 0; top: calc(100% + 6px); margin-top: 8px; font-size: 12px; color: #475569; background: #fff; border: 1px dashed #cbd5e1; border-radius: 8px; padding: 8px 10px; z-index: 50; }
.skills-helper { margin-top: 8px; font-size: 11px; color: #94a3b8; }
.catalog-browser { margin-top: 10px; border: 1px solid #e2e8f0; border-radius: 10px; background: #f8fafc; padding: 10px; }
.catalog-browser-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px; }
.catalog-browser-head h4 { font-size: 13px; font-weight: 800; color: #0f172a; }
.catalog-close-btn { border: none; background: #e2e8f0; color: #334155; border-radius: 6px; font-size: 11px; font-weight: 700; padding: 6px 10px; cursor: pointer; }
.catalog-controls { display: grid; grid-template-columns: 1fr 180px; gap: 8px; margin-bottom: 8px; }
.catalog-search, .catalog-category { background: #fff; }
.catalog-list { max-height: 220px; overflow-y: auto; border: 1px solid #e2e8f0; border-radius: 8px; background: #fff; }
.catalog-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; padding: 8px 10px; border-bottom: 1px solid #f1f5f9; }
.catalog-row:last-child { border-bottom: none; }
.catalog-meta { min-width: 0; }
.catalog-skill { font-size: 12px; font-weight: 700; color: #0f172a; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.catalog-cat { font-size: 11px; color: #64748b; }
.catalog-action { border: none; border-radius: 6px; background: #dbeafe; color: #1d4ed8; font-size: 11px; font-weight: 700; padding: 6px 10px; cursor: pointer; }
.catalog-action.selected { background: #fee2e2; color: #b91c1c; }

.drawer-enter-active, .drawer-leave-active { transition: opacity 0.2s; }
.drawer-enter-active .drawer, .drawer-leave-active .drawer { transition: transform 0.25s cubic-bezier(0.4,0,0.2,1); }
.drawer-enter-from, .drawer-leave-to { opacity: 0; }
.drawer-enter-from .drawer, .drawer-leave-to .drawer { transform: translateX(100%); }
.modal-enter-active, .modal-leave-active { transition: opacity 0.2s; }
.modal-enter-active .modal, .modal-leave-active .modal { transition: transform 0.2s, opacity 0.2s; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
.modal-enter-from .modal, .modal-leave-to .modal { transform: scale(0.95); opacity: 0; }

/* Toast */
.toast { position: fixed; top: 20px; right: 24px; z-index: 9999; display: flex; align-items: center; gap: 10px; padding: 12px 18px; border-radius: 12px; font-size: 13px; font-weight: 600; box-shadow: 0 8px 30px rgba(0,0,0,0.12); min-width: 240px; max-width: 380px; font-family: 'Plus Jakarta Sans', sans-serif; }
.toast.success { background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; }
.toast.error   { background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; }
.toast-icon { display: flex; align-items: center; flex-shrink: 0; }
.toast-msg { word-break: break-word; line-height: 1.4; }
.toast-enter-active, .toast-leave-active { transition: all 0.3s cubic-bezier(0.4,0,0.2,1); }
.toast-enter-from, .toast-leave-to { opacity: 0; transform: translateY(-15px) scale(0.95); }

/* Tabs */
.listing-tabs-bar { display: flex; gap: 6px; background: #fff; border: 1px solid #f1f5f9; border-radius: 12px; padding: 5px; width: fit-content; }
.listing-main-tab { display: flex; align-items: center; gap: 7px; padding: 8px 16px; border-radius: 9px; border: none; background: none; font-size: 13px; font-weight: 600; color: #64748b; cursor: pointer; font-family: inherit; transition: all 0.15s; }
.listing-main-tab:hover { background: #f8fafc; color: #1e293b; }
.listing-main-tab.active { background: #eff8ff; color: #1a5f8a; }
.archived-tab.active { background: #fef9ec; color: #92400e; }
.ltab-pill { font-size: 10.5px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }
.archived-pill { background: #fde68a; color: #92400e; }

/* Hired row on card */
.hired-row { display: flex; align-items: center; justify-content: space-between; background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px; padding: 7px 10px; cursor: pointer; transition: background 0.15s; }
.hired-row:hover { background: #dcfce7; }
.hired-left { display: flex; align-items: center; gap: 7px; }
.hired-dot { width: 7px; height: 7px; border-radius: 50%; background: #22c55e; flex-shrink: 0; }
.hired-label { font-size: 12px; font-weight: 600; color: #15803d; }
.hired-count { font-size: 13px; font-weight: 800; color: #15803d; }
.hired-link { font-size: 11px; font-weight: 700; color: #16a34a; }

/* Hired value in drawer */
.hired-val { display: flex; align-items: center; gap: 8px; cursor: pointer; }

/* Archived card */
.card-archived { opacity: 0.85; border-color: #f1f5f9; }
.card-archived .job-card-title { color: #64748b; }
.expired-badge { background: #fef9ec; color: #92400e; border: 1px solid #fde68a; }

/* Repost */
.repost-btn { background: #fef9ec; color: #92400e; }
.repost-btn:hover { background: #fde68a; }

/* Salary selector */
.salary-options { display: flex; gap: 10px; }
.salary-opt { flex: 1; display: flex; align-items: center; gap: 10px; padding: 12px 14px; border-radius: 10px; border: 2px solid #e2e8f0; background: #f8fafc; cursor: pointer; font-family: inherit; text-align: left; transition: all 0.15s; position: relative; }
.salary-opt:hover { border-color: #94a3b8; background: #fff; }
.salary-opt.active { border-color: #2872A1; background: #eff8ff; }
.salary-opt-icon { font-size: 16px; font-weight: 800; color: #2872A1; min-width: 28px; text-align: center; }
.salary-opt-title { font-size: 13px; font-weight: 700; color: #1e293b; }
.salary-opt-sub { font-size: 11px; color: #94a3b8; margin-top: 1px; }
.salary-opt-check { margin-left: auto; width: 22px; height: 22px; border-radius: 50%; background: #2872A1; color: #fff; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }

/* Empty state */
.empty-state { grid-column: 1 / -1; display: flex; flex-direction: column; align-items: center; gap: 10px; padding: 60px 20px; color: #94a3b8; font-size: 13px; font-weight: 500; }

/* Drawer tabs */
.drawer-tabs { display: flex; border-bottom: 1px solid #f1f5f9; padding: 0 20px; }
.dtab { background: none; border: none; padding: 12px 16px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; font-family: inherit; border-bottom: 2px solid transparent; transition: all 0.15s; margin-bottom: -1px; display: flex; align-items: center; gap: 6px; }
.dtab.active { color: #2872A1; border-bottom-color: #2872A1; font-weight: 700; }
.dtab-pill { font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 99px; background: #f1f5f9; color: #64748b; }

/* Hired list in drawer */
.hired-list { display: flex; flex-direction: column; gap: 10px; padding-top: 4px; }
.hired-row-item { display: flex; align-items: center; gap: 10px; padding: 12px; background: #f8fafc; border-radius: 10px; border: 1px solid #f1f5f9; }
.avatar-circle { width: 34px; height: 34px; border-radius: 50%; color: #fff; font-size: 13px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.hired-info { flex: 1; }
.hired-name { font-size: 13px; font-weight: 600; color: #1e293b; }
.hired-job  { font-size: 11px; color: #94a3b8; margin-top: 2px; }
.hired-right { display: flex; flex-direction: column; align-items: flex-end; gap: 4px; }
.hired-badge-chip { font-size: 10px; font-weight: 700; background: #f0fdf4; color: #22c55e; border-radius: 99px; padding: 3px 9px; }
.hired-date { font-size: 11px; color: #94a3b8; }
</style>