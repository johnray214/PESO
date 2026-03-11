<template>
  <div class="layout-wrapper">
    <EmployerSidebar />
    <div class="main-area">
      <EmployerTopbar title="Company Profile" subtitle="Manage your company information and account settings" />
      <div class="page">
        <div class="profile-layout">

          <!-- Left Col -->
          <div class="left-col">
            <div class="card profile-card">
              <div class="cover-banner">
              </div>
              <div class="profile-info">
                <div class="company-logo-wrap">
                  <div class="company-logo">N</div>
                </div>
                <h2 class="company-name-lg">{{ company.name }}</h2>
                <p class="company-tagline">{{ company.tagline }}</p>
                <div class="company-meta-row">
                  <span class="meta-chip">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>
                    {{ company.industry }}
                  </span>
                  <span class="meta-chip">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                    {{ company.city }}
                  </span>
                  <span class="meta-chip">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                    {{ company.size }}
                  </span>
                </div>
                <div class="verified-badge">
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="#22c55e"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01" stroke="#fff" stroke-width="2" fill="none"/></svg>
                  Verified Employer
                </div>
                <button class="edit-profile-btn" @click="openEditProfile">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                  Edit Profile
                </button>
              </div>
            </div>

            <div class="card stats-card">
              <h4 class="card-title">Account Overview</h4>
              <div class="stats-list">
                <div v-for="s in accountStats" :key="s.label" class="stat-row">
                  <div class="stat-icon-sm" :style="{ background: s.bg }">
                    <span v-html="s.icon" :style="{ color: s.color }"></span>
                  </div>
                  <div class="stat-info">
                    <span class="stat-row-label">{{ s.label }}</span>
                    <span class="stat-row-val" :style="{ color: s.color }">{{ s.value }}</span>
                  </div>
                </div>
              </div>
            </div>

            <div class="card contact-card">
              <div class="card-header-row">
                <h4 class="card-title">Contact Info</h4>
                <button class="edit-link" @click="activeTab = 'Settings'">Edit</button>
              </div>
              <div class="contact-list">
                <div class="contact-row">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07A19.5 19.5 0 013.07 9.8 19.79 19.79 0 01.07 1.2 2 2 0 012.05 0h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L6.09 7.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 14.92z"/></svg>
                  <span>{{ company.phone }}</span>
                </div>
                <div class="contact-row">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                  <span>{{ company.email }}</span>
                </div>
                <div class="contact-row">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 014 10 15.3 15.3 0 01-4 10 15.3 15.3 0 01-4-10 15.3 15.3 0 014-10z"/></svg>
                  <span>{{ company.website }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Right Col -->
          <div class="right-col">
            <div class="card tabs-card">
              <div class="tab-bar">
                <button v-for="tab in ['Company Info', 'Job Listings', 'Settings']" :key="tab"
                  :class="['profile-tab', { active: activeTab === tab }]" @click="activeTab = tab">{{ tab }}</button>
              </div>

              <!-- ── COMPANY INFO TAB ── -->
              <div v-if="activeTab === 'Company Info'" class="tab-body">

                <!-- Single Edit Button for entire Company Info -->
                <div class="section-header-row" style="margin-bottom: -8px;">
                  <span></span>
                  <button class="btn-edit-all" @click="toggleEditAll">
                    <svg v-if="!editAll" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                    <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                    {{ editAll ? 'Cancel' : 'Edit Profile' }}
                  </button>
                </div>

                <!-- VIEW MODE -->
                <div v-if="!editAll">
                  <div class="section-block">
                    <h4 class="section-title">About the Company</h4>
                    <p class="about-text">{{ company.about }}</p>
                  </div>
                  <div class="section-block" style="margin-top: 16px;">
                    <h4 class="section-title">Company Details</h4>
                    <div class="details-grid">
                      <div class="detail-item" style="grid-column: 1 / -1"><span class="detail-label">Tagline</span><span class="detail-val">{{ company.tagline }}</span></div>
                      <div class="detail-item"><span class="detail-label">Company Name</span><span class="detail-val">{{ company.legalName }}</span></div>
                      <div class="detail-item"><span class="detail-label">Industry</span><span class="detail-val">{{ company.industry }}</span></div>
                      <div class="detail-item"><span class="detail-label">Company Size</span><span class="detail-val">{{ company.size }}</span></div>
                      <div class="detail-item"><span class="detail-label">Founded</span><span class="detail-val">{{ company.founded }}</span></div>
                      <div class="detail-item"><span class="detail-label">Business Type</span><span class="detail-val">{{ company.businessType }}</span></div>
                      <div class="detail-item"><span class="detail-label">TIN / Registration</span><span class="detail-val">{{ company.tin }}</span></div>
                      <div class="detail-item" style="grid-column: 1 / -1"><span class="detail-label">Head Office Address</span><span class="detail-val">{{ company.address }}</span></div>
                    </div>
                  </div>
                  <div class="section-block" style="margin-top: 16px;">
                    <h4 class="section-title">Benefits & Perks</h4>
                    <div class="perks-grid">
                      <div v-for="perk in company.perks" :key="perk" class="perk-chip">✓ {{ perk }}</div>
                    </div>
                  </div>
                </div>

                <!-- EDIT MODE -->
                <div v-else class="edit-form">
                  <div class="edit-section-label">About the Company</div>
                  <div class="form-group">
                    <textarea class="form-input textarea" v-model="editCompany.about" rows="4"></textarea>
                  </div>

                  <div class="edit-section-label" style="margin-top: 8px;">Company Details</div>
                  <div class="form-group">
                    <label class="form-label">Tagline</label>
                    <input v-model="editCompany.tagline" class="form-input" placeholder="Short company tagline"/>
                  </div>
                  <div class="form-row two">
                    <div class="form-group">
                      <label class="form-label">Company Name</label>
                      <input v-model="editCompany.legalName" class="form-input"/>
                    </div>
                    <div class="form-group">
                      <label class="form-label">Industry</label>
                      <input v-model="editCompany.industry" class="form-input"/>
                    </div>
                    <div class="form-group">
                      <label class="form-label">Company Size</label>
                      <select v-model="editCompany.size" class="form-input">
                        <option>1–10 employees</option>
                        <option>11–50 employees</option>
                        <option>50–100 employees</option>
                        <option>100–500 employees</option>
                        <option>500+ employees</option>
                      </select>
                    </div>
                    <div class="form-group">
                      <label class="form-label">Founded</label>
                      <input v-model="editCompany.founded" class="form-input" type="number"/>
                    </div>
                    <div class="form-group">
                      <label class="form-label">Business Type</label>
                      <input v-model="editCompany.businessType" class="form-input"/>
                    </div>
                    <div class="form-group">
                      <label class="form-label">TIN / Registration</label>
                      <input v-model="editCompany.tin" class="form-input"/>
                    </div>
                  </div>
                  <div class="form-group">
                    <label class="form-label">Head Office Address</label>
                    <input v-model="editCompany.address" class="form-input"/>
                  </div>

                  <div class="edit-section-label" style="margin-top: 8px;">Benefits & Perks</div>
                  <div class="perks-edit-grid">
                    <div v-for="(perk, i) in editCompany.perks" :key="i" class="perk-edit-row">
                      <input v-model="editCompany.perks[i]" class="form-input perk-input"/>
                      <button class="perk-remove-btn" @click="removePerk(i)" title="Remove">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                      </button>
                    </div>
                  </div>
                  <button class="add-perk-btn" @click="addPerk">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                    Add Perk
                  </button>

                  <div class="edit-actions" style="margin-top: 12px;">
                    <button class="btn-ghost-sm" @click="cancelEditAll">Cancel</button>
                    <button class="btn-blue-sm" @click="saveAll">Save All Changes</button>
                  </div>
                </div>

              </div>

              <!-- ── JOB LISTINGS TAB ── -->
              <div v-if="activeTab === 'Job Listings'" class="tab-body">
                <p class="jl-sub">Your posted job openings visible to jobseekers on PESO</p>
                <div class="jl-list">
                  <div v-for="job in previewJobs" :key="job.title" class="jl-row">
                    <div class="jl-icon" :style="{ background: job.bg }">
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" :stroke="job.color" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
                    </div>
                    <div class="jl-info">
                      <p class="jl-title">{{ job.title }}</p>
                      <p class="jl-meta">{{ job.type }} · {{ job.location }} · {{ job.salary }}</p>
                    </div>
                    <span class="job-status" :class="job.status === 'Open' ? 'status-open' : job.status === 'Draft' ? 'status-draft' : 'status-closed'">{{ job.status }}</span>
                    <span class="jl-applicants">{{ job.applicants }} applicants</span>
                  </div>
                </div>
              </div>

              <!-- ── SETTINGS TAB ── -->
              <div v-if="activeTab === 'Settings'" class="tab-body">
                <div class="section-block">
                  <h4 class="section-title">Account Settings</h4>
                  <div class="form-group">
                    <label class="form-label">Company Display Name</label>
                    <input class="form-input" v-model="editCompany.name"/>
                  </div>
                  <div class="form-row two">
                    <div class="form-group">
                      <label class="form-label">Contact Person</label>
                      <input class="form-input" v-model="editCompany.contactPerson"/>
                    </div>
                    <div class="form-group">
                      <label class="form-label">Contact Number</label>
                      <input class="form-input" v-model="editCompany.phone"/>
                    </div>
                  </div>
                  <div class="form-row two">
                    <div class="form-group">
                      <label class="form-label">Email Address</label>
                      <input class="form-input" v-model="editCompany.email" type="email"/>
                    </div>
                    <div class="form-group">
                      <label class="form-label">Website</label>
                      <input class="form-input" v-model="editCompany.website"/>
                    </div>
                  </div>

                </div>

                <div class="section-block">
                  <h4 class="section-title">Change Password</h4>
                  <div class="form-group">
                    <label class="form-label">Current Password</label>
                    <input class="form-input" type="password" placeholder="Enter current password"/>
                  </div>
                  <div class="form-row two">
                    <div class="form-group">
                      <label class="form-label">New Password</label>
                      <input class="form-input" type="password" placeholder="New password"/>
                    </div>
                    <div class="form-group">
                      <label class="form-label">Confirm Password</label>
                      <input class="form-input" type="password" placeholder="Repeat password"/>
                    </div>
                  </div>
                </div>

                <div class="settings-footer">
                  <button class="btn-ghost" @click="resetSettings">Cancel</button>
                  <button class="btn-amber" @click="saveSettings">Save Changes</button>
                </div>
              </div>

            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import api from '@/services/api'
import EmployerSidebar from '@/components/EmployerSidebar.vue'
import EmployerTopbar from '@/components/EmployerTopbar.vue'

export default {
  name: 'EmployerProfile',
  components: { EmployerSidebar, EmployerTopbar },
  data() {
    return {
      activeTab: 'Company Info',
      editAll: false,
      company: {
        name: 'Nexus Tech Solutions',
        legalName: 'Nexus Tech Solutions Inc.',
        tagline: 'Building the future, one line of code at a time.',
        about: 'Nexus Tech Solutions is a leading software development company based in Quezon City. We specialize in building web applications, mobile solutions, and enterprise software for clients across Southeast Asia. Our team of passionate engineers and designers work together to deliver high-quality products that drive business growth.',
        industry: 'IT / Software',
        location: 'Quezon City, PH',
        size: '50–100 employees',
        founded: '2015',
        businessType: 'Private Corporation',
        tin: '123-456-789-000',
        address: '4F Nexus Building, Diliman, Quezon City, Metro Manila, 1101',
        city: 'Quezon City, PH',
        phone: '+63 917 123 4567',
        email: 'hr@nexustech.com.ph',
        website: 'www.nexustech.com.ph',
        contactPerson: 'John Dela Cruz',
        perks: ['Health Insurance', 'Hybrid Setup', '13th Month Pay', 'HMO Day 1', 'Performance Bonus', 'Paid Leaves', 'Training & Dev', 'Team Events'],
      },
      editCompany: {},
      accountStats: [
        { label: 'Active Job Listings', value: '7',   bg: '#eff6ff', color: '#2563eb', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>` },
        { label: 'Total Applicants',    value: '142', bg: '#eff8ff', color: '#2872A1', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>` },
        { label: 'Total Hired',         value: '12',  bg: '#f0fdf4', color: '#22c55e', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>` },
        { label: 'Member Since',        value: '2022', bg: '#f8fafc', color: '#64748b', icon: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>` },
      ],
      previewJobs: [
        { title:'Frontend Developer', type:'Full-time', location:'Quezon City', salary:'₱30K–₱45K/mo', status:'Open',   applicants:38, bg:'#eff6ff', color:'#2563eb' },
        { title:'Backend Developer',  type:'Full-time', location:'Remote',      salary:'₱35K–₱50K/mo', status:'Open',   applicants:29, bg:'#faf5ff', color:'#8b5cf6' },
        { title:'UI/UX Designer',     type:'Full-time', location:'Hybrid',      salary:'₱25K–₱40K/mo', status:'Open',   applicants:22, bg:'#fdf4ff', color:'#d946ef' },
        { title:'QA Engineer',        type:'Part-time', location:'Hybrid',      salary:'₱20K–₱30K/mo', status:'Closed', applicants:11, bg:'#f0fdf4', color:'#16a34a' },
        { title:'Data Analyst',       type:'Internship',location:'Quezon City', salary:'₱15K–₱18K/mo', status:'Draft',  applicants:0,  bg:'#f8fafc', color:'#94a3b8' },
      ]
    }
  },
  async created() {
    try {
      const { data } = await api.get('/employer/profile')
      const p = data.data || data
      this.company = {
        name:          p.company_name  || p.name || '',
        legalName:     p.legal_name    || '',
        tagline:       p.tagline       || '',
        about:         p.about         || '',
        industry:      p.industry      || '',
        location:      p.city          || '',
        size:          p.company_size  || '',
        founded:       p.founded       || '',
        businessType:  p.business_type || '',
        tin:           p.tin           || '',
        address:       p.address       || '',
        city:          p.city          || '',
        phone:         p.contact_role  || '',
        email:         p.email         || '',
        website:       p.website       || '',
        contactPerson: `${p.first_name||''} ${p.last_name||''}`.trim(),
        perks:         Array.isArray(p.perks) ? p.perks : [],
      }
      if (p.stats) {
        if (p.stats.active_listings !== undefined) this.accountStats[0].value = String(p.stats.active_listings)
        if (p.stats.total_applicants !== undefined) this.accountStats[1].value = String(p.stats.total_applicants)
        if (p.stats.total_hired !== undefined) this.accountStats[2].value = String(p.stats.total_hired)
        if (p.stats.member_since !== undefined) this.accountStats[3].value = String(p.stats.member_since)
      }
      if (p.jobs) this.previewJobs = p.jobs
    } catch (e) { console.error(e) }
    this.editCompany = { ...this.company, perks: [...(this.company.perks || [])] }
  },
  methods: {
    toggleEditAll() {
      if (!this.editAll) this.editCompany = { ...this.company, perks: [...this.company.perks] }
      this.editAll = !this.editAll
    },
    cancelEditAll() {
      this.editAll = false
    },
    async saveAll() {
      try {
        await api.put('/employer/profile', {
          about:         this.editCompany.about,
          legal_name:    this.editCompany.legalName,
          industry:      this.editCompany.industry,
          company_size:  this.editCompany.size,
          founded:       this.editCompany.founded,
          business_type: this.editCompany.businessType,
          tin:           this.editCompany.tin,
          address:       this.editCompany.address,
          tagline:       this.editCompany.tagline,
          perks:         this.editCompany.perks,
        })
        Object.assign(this.company, { ...this.editCompany, perks: [...this.editCompany.perks] })
        this.editAll = false
      } catch (e) { console.error(e) }
    },
    addPerk() {
      this.editCompany.perks.push('')
    },
    removePerk(i) {
      this.editCompany.perks.splice(i, 1)
    },
    async saveSettings() {
      try {
        await api.put('/employer/profile', {
          company_name:  this.editCompany.name,
          tagline:       this.editCompany.tagline,
          phone:         this.editCompany.phone,
          email:         this.editCompany.email,
          website:       this.editCompany.website,
          first_name:    this.editCompany.contactPerson?.split(' ')[0] || '',
          last_name:     this.editCompany.contactPerson?.split(' ').slice(1).join(' ') || '',
        })
        Object.assign(this.company, {
          name:          this.editCompany.name,
          tagline:       this.editCompany.tagline,
          phone:         this.editCompany.phone,
          email:         this.editCompany.email,
          website:       this.editCompany.website,
          contactPerson: this.editCompany.contactPerson,
        })
      } catch (e) { console.error(e) }
    },
    resetSettings() {
      this.editCompany = { ...this.company, perks: [...(this.company.perks || [])] }
    },
    openEditProfile() {
      this.activeTab = 'Company Info'
      this.editCompany = { ...this.company, perks: [...this.company.perks] }
      this.editAll = true
      this.$nextTick(() => {
        const el = document.querySelector('.right-col')
        if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' })
      })
    }
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
.layout-wrapper { display: flex; height: 100vh; overflow: hidden; background: #f8fafc; font-family: 'Plus Jakarta Sans', sans-serif; }
.main-area { flex: 1; display: flex; flex-direction: column; min-height: 0; overflow: hidden; }
.page { flex: 1; overflow-y: auto; padding: 24px; }

.profile-layout { display: grid; grid-template-columns: 280px 1fr; gap: 16px; align-items: start; }
.left-col { display: flex; flex-direction: column; gap: 14px; }
.right-col { display: flex; flex-direction: column; gap: 14px; }
.card { background: #fff; border-radius: 14px; border: 1px solid #f1f5f9; overflow: hidden; }

/* PROFILE CARD */
.cover-banner { height: 80px; background: linear-gradient(135deg, #2872A1, #08BDDE); position: relative; }
.cover-edit-btn { position: absolute; top: 8px; right: 8px; background: rgba(255,255,255,0.3); border: none; border-radius: 6px; padding: 5px; cursor: pointer; color: #fff; display: flex; align-items: center; }
.profile-info { padding: 0 18px 18px; display: flex; flex-direction: column; align-items: center; text-align: center; gap: 6px; }
.company-logo-wrap { position: relative; margin-top: -26px; }
.company-logo { width: 52px; height: 52px; border-radius: 14px; background: linear-gradient(135deg, #2872A1, #08BDDE); color: #fff; font-size: 22px; font-weight: 800; display: flex; align-items: center; justify-content: center; border: 3px solid #fff; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
.company-name-lg { font-size: 15px; font-weight: 800; color: #1e293b; }
.company-tagline { font-size: 11.5px; color: #94a3b8; line-height: 1.4; }
.company-meta-row { display: flex; flex-direction: column; gap: 5px; width: 100%; }
.meta-chip { display: flex; align-items: center; gap: 6px; font-size: 11.5px; color: #64748b; background: #f8fafc; padding: 5px 10px; border-radius: 8px; }
.verified-badge { display: flex; align-items: center; gap: 5px; font-size: 11px; font-weight: 700; color: #22c55e; background: #f0fdf4; padding: 5px 12px; border-radius: 99px; margin-top: 2px; }

/* STATS CARD */
.stats-card { padding: 16px; }
.card-title { font-size: 13px; font-weight: 700; color: #1e293b; margin-bottom: 12px; }
.stats-list { display: flex; flex-direction: column; gap: 10px; }
.stat-row { display: flex; align-items: center; gap: 10px; }
.stat-icon-sm { width: 32px; height: 32px; border-radius: 8px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.stat-info { display: flex; flex-direction: column; }
.stat-row-label { font-size: 11px; color: #94a3b8; }
.stat-row-val { font-size: 14px; font-weight: 700; }

/* CONTACT */
.contact-card { padding: 16px; }
.card-header-row { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; }
.edit-link { background: none; border: none; font-size: 12px; color: #2872A1; font-weight: 600; cursor: pointer; font-family: inherit; padding: 0; }
.contact-list { display: flex; flex-direction: column; gap: 10px; }
.contact-row { display: flex; align-items: center; gap: 8px; font-size: 12.5px; color: #475569; }

/* TABS */
.tabs-card { padding: 0; }
.tab-bar { display: flex; border-bottom: 1px solid #f1f5f9; padding: 0 20px; }
.profile-tab { background: none; border: none; padding: 14px 16px; font-size: 13px; font-weight: 500; color: #64748b; cursor: pointer; font-family: inherit; border-bottom: 2px solid transparent; margin-bottom: -1px; transition: all 0.15s; }
.profile-tab.active { color: #1a5f8a; border-bottom-color: #2872A1; font-weight: 700; }
.tab-body { padding: 20px; display: flex; flex-direction: column; gap: 20px; }

/* SECTIONS */
.section-block { display: flex; flex-direction: column; gap: 12px; }
.section-header-row { display: flex; align-items: center; justify-content: space-between; }
.section-title { font-size: 13px; font-weight: 700; color: #1e293b; }
.about-text { font-size: 13px; color: #64748b; line-height: 1.7; }
.details-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
.detail-item { display: flex; flex-direction: column; gap: 3px; }
.detail-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
.detail-val { font-size: 13px; font-weight: 500; color: #1e293b; }
.perks-grid { display: flex; flex-wrap: wrap; gap: 6px; }
.perk-chip { font-size: 12px; font-weight: 500; padding: 5px 12px; border-radius: 8px; background: #eff8ff; color: #1a5f8a; border: 1px solid #bae6fd; }

/* EDIT FORMS */
.edit-form { display: flex; flex-direction: column; gap: 12px; background: #f8fafc; padding: 16px; border-radius: 10px; border: 1px solid #f1f5f9; }
.edit-actions { display: flex; justify-content: flex-end; gap: 8px; margin-top: 4px; }
.btn-ghost-sm { background: #f1f5f9; color: #64748b; border: none; border-radius: 8px; padding: 7px 14px; font-size: 12px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-ghost-sm:hover { background: #e2e8f0; }
.btn-blue-sm { background: #2872A1; color: #fff; border: none; border-radius: 8px; padding: 7px 14px; font-size: 12px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-amber-sm:hover { background: #1a5f8a; }

/* FORM */
.form-group { display: flex; flex-direction: column; gap: 5px; }
.form-label { font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; }
.form-input { border: 1px solid #e2e8f0; border-radius: 8px; padding: 9px 12px; font-size: 13px; color: #1e293b; font-family: inherit; outline: none; background: #fff; transition: border 0.15s; width: 100%; }
.form-input:focus { border-color: #08BDDE; }
.form-input.textarea { resize: vertical; }
.form-row { display: grid; gap: 12px; }
.form-row.two { grid-template-columns: 1fr 1fr; }

/* JOB LISTINGS TAB */
.jl-sub { font-size: 12px; color: #94a3b8; margin-bottom: 4px; }
.jl-list { display: flex; flex-direction: column; gap: 10px; }
.jl-row { display: flex; align-items: center; gap: 12px; padding: 12px 14px; background: #f8fafc; border-radius: 10px; border: 1px solid #f1f5f9; }
.jl-icon { width: 36px; height: 36px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.jl-info { flex: 1; }
.jl-title { font-size: 13px; font-weight: 600; color: #1e293b; }
.jl-meta { font-size: 11px; color: #94a3b8; margin-top: 2px; }
.job-status { font-size: 11px; font-weight: 700; padding: 3px 10px; border-radius: 99px; }
.status-open   { background: #f0fdf4; color: #22c55e; }
.status-closed { background: #f1f5f9; color: #94a3b8; }
.status-draft  { background: #eff8ff; color: #1a5f8a; }
.jl-applicants { font-size: 12px; font-weight: 600; color: #2872A1; white-space: nowrap; }

/* SETTINGS */
.settings-footer { display: flex; justify-content: flex-end; gap: 10px; padding-top: 8px; border-top: 1px solid #f1f5f9; }
.btn-ghost { background: #f1f5f9; color: #64748b; border: none; border-radius: 10px; padding: 9px 18px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-ghost:hover { background: #e2e8f0; }
.btn-amber { background: #2872A1; color: #fff; border: none; border-radius: 10px; padding: 9px 18px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-amber:hover { background: #1a5f8a; }

.btn-edit-all {
  display: flex; align-items: center; gap: 6px;
  background: #eff8ff; color: #2872A1; border: 1px solid #bae6fd;
  border-radius: 8px; padding: 7px 14px; font-size: 12px; font-weight: 600;
  cursor: pointer; font-family: inherit; transition: all 0.15s;
}
.btn-edit-all:hover { background: #dbeafe; }
.edit-section-label {
  font-size: 10px; font-weight: 700; color: #2872A1;
  text-transform: uppercase; letter-spacing: 0.08em;
  padding-bottom: 6px; border-bottom: 1px solid #e0f2fe;
}
.perks-edit-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.perk-edit-row { display: flex; align-items: center; gap: 6px; }
.perk-input { flex: 1; }
.perk-remove-btn {
  width: 26px; height: 26px; border-radius: 6px; border: none;
  background: #fef2f2; color: #ef4444; cursor: pointer;
  display: flex; align-items: center; justify-content: center; flex-shrink: 0;
}
.perk-remove-btn:hover { background: #fee2e2; }
.add-perk-btn {
  display: flex; align-items: center; gap: 6px;
  background: none; border: 1px dashed #bae6fd;
  border-radius: 8px; padding: 7px 14px; font-size: 12px;
  color: #2872A1; cursor: pointer; font-family: inherit;
  width: fit-content; margin-top: 4px;
}
.add-perk-btn:hover { background: #eff8ff; }

.edit-profile-btn {
  display: flex; align-items: center; gap: 6px; margin-top: 4px;
  background: #eff8ff; color: #2872A1; border: 1px solid #bae6fd;
  border-radius: 99px; padding: 6px 16px; font-size: 12px; font-weight: 600;
  cursor: pointer; font-family: inherit; transition: all 0.15s;
}
.edit-profile-btn:hover { background: #dbeafe; border-color: #93c5fd; }

</style>