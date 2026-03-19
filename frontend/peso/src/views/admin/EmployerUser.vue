<template>
  <div class="layout-wrapper">
    <div class="main-area">
      <div class="page">

        <!-- Toast -->
        <transition name="toast">
          <div v-if="toast.show" class="toast" :class="toast.type">
            <span class="toast-icon" v-html="toast.icon"></span>
            <span class="toast-msg">{{ toast.text }}</span>
          </div>
        </transition>

        <!-- Filters -->
        <div class="filters-bar">
          <div class="search-box">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            <input v-model="search" type="text" placeholder="Search by company, contact, email…" class="search-input"/>
          </div>
          <div class="filter-group">
            <select v-model="filterStatus" class="filter-select">
              <option value="">All Status</option>
              <option>Pending</option>
              <option>Verified</option>
              <option>Rejected</option>
            </select>
          </div>
        </div>

        <!-- Table -->
        <div class="table-card">
          <table class="data-table">
            <thead>
              <tr>
                <th>Company</th>
                <th>Contact Person</th>
                <th>Email</th>
                <th>Industry</th>
                <th>City</th>
                <th>Registered</th>
                <th>Verification</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="e in filteredEmployers" :key="e.id" class="table-row" @click="viewEmployer(e)">
                <td>
                  <div class="company-cell">
                    <div class="company-avatar" :style="{ background: e.avatarBg }">{{ e.companyName[0] }}</div>
                    <div>
                      <p class="company-name">{{ e.companyName }}</p>
                      <p class="company-size">{{ e.companySize }} employees</p>
                    </div>
                  </div>
                </td>
                <td>
                  <p class="person-name">{{ e.contactPerson }}</p>
                  <p class="person-meta">{{ e.phone }}</p>
                </td>
                <td class="email-cell">{{ e.email }}</td>
                <td class="meta-cell">{{ e.industry }}</td>
                <td class="meta-cell">{{ e.city }}</td>
                <td class="meta-cell">{{ e.registeredDate }}</td>
                <td @click.stop>
                  <span class="vstatus-badge" :class="`vstatus-${e.verificationStatus.toLowerCase()}`">
                    <span class="vstatus-dot"></span>
                    {{ e.verificationStatus }}
                  </span>
                </td>
                <td @click.stop>
                  <div class="action-btns">
                    <button class="act-btn view" @click="viewEmployer(e)" title="View Details">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    </button>
                    <button v-if="e.verificationStatus === 'Pending'" class="act-btn approve" @click.stop="quickVerify(e, 'Verified')" title="Approve">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
                    </button>
                    <button v-if="e.verificationStatus === 'Pending'" class="act-btn reject" @click.stop="quickVerify(e, 'Rejected')" title="Reject">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="filteredEmployers.length === 0">
                <td colspan="8" class="empty-cell">
                  <div class="empty-state">
                    <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.5"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>
                    <p>No employers found</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>

          <div class="pagination">
            <span class="page-info">Showing {{ filteredEmployers.length }} of {{ employers.length }} employers</span>
            <div class="page-btns">
              <button class="page-btn">‹</button>
              <button class="page-btn active">1</button>
              <button class="page-btn">›</button>
            </div>
          </div>
        </div>

      </div>
    </div>

    <!-- EMPLOYER DETAIL / VERIFY MODAL -->
    <transition name="modal">
      <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
        <div class="modal modal-wide">
          <div class="modal-header">
            <div class="modal-title-wrap">
              <div class="modal-icon">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>
              </div>
              <div>
                <h3 class="modal-title">{{ selectedEmployer?.companyName }}</h3>
                <p class="modal-sub">Employer Registration Review</p>
              </div>
            </div>
            <div style="display:flex;align-items:center;gap:10px">
              <span class="vstatus-badge" :class="`vstatus-${selectedEmployer?.verificationStatus?.toLowerCase()}`">
                <span class="vstatus-dot"></span>
                {{ selectedEmployer?.verificationStatus }}
              </span>
              <button class="modal-close" @click="showModal = false">✕</button>
            </div>
          </div>

          <div class="modal-body" v-if="selectedEmployer">

            <!-- Two column layout -->
            <div class="detail-grid">
              <!-- Left: Company Info -->
              <div class="detail-section">
                <p class="detail-section-title">Company Information</p>
                <div class="detail-rows">
                  <div class="detail-row"><span class="detail-key">Company Name</span><span class="detail-val">{{ selectedEmployer.companyName }}</span></div>
                  <div class="detail-row"><span class="detail-key">Industry</span><span class="detail-val">{{ selectedEmployer.industry }}</span></div>
                  <div class="detail-row"><span class="detail-key">Company Size</span><span class="detail-val">{{ selectedEmployer.companySize }} employees</span></div>
                  <div class="detail-row"><span class="detail-key">City</span><span class="detail-val">{{ selectedEmployer.city }}</span></div>
                  <div class="detail-row"><span class="detail-key">TIN</span><span class="detail-val">{{ selectedEmployer.tin }}</span></div>
                  <div class="detail-row"><span class="detail-key">Website</span><span class="detail-val">{{ selectedEmployer.website || '—' }}</span></div>
                </div>
              </div>

              <!-- Right: Contact Info -->
              <div class="detail-section">
                <p class="detail-section-title">Contact Person</p>
                <div class="detail-rows">
                  <div class="detail-row"><span class="detail-key">Name</span><span class="detail-val">{{ selectedEmployer.contactPerson }}</span></div>
                  <div class="detail-row"><span class="detail-key">Email</span><span class="detail-val">{{ selectedEmployer.email }}</span></div>
                  <div class="detail-row"><span class="detail-key">Phone</span><span class="detail-val">{{ selectedEmployer.phone }}</span></div>
                  <div class="detail-row"><span class="detail-key">Registered</span><span class="detail-val">{{ selectedEmployer.registeredDate }}</span></div>
                </div>
              </div>
            </div>

            <!-- Documents -->
            <div class="detail-section" style="margin-top:4px">
              <p class="detail-section-title">Submitted Documents</p>
              <div class="doc-cards">

                <!-- Business Permit -->
                <div class="doc-card" :class="selectedEmployer.hasBizPermit ? 'doc-card-ok' : 'doc-card-missing'">
                  <div class="doc-card-preview" @click="selectedEmployer.hasBizPermit && openDocViewer(selectedEmployer, 'bizPermit')">
                    <template v-if="selectedEmployer.hasBizPermit">
                      <div class="doc-thumb">
                        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
                        <span class="doc-thumb-label">{{ selectedEmployer.bizPermitName || 'business_permit.pdf' }}</span>
                      </div>
                      <div class="doc-hover-overlay">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                        <span>View Document</span>
                      </div>
                    </template>
                    <template v-else>
                      <div class="doc-missing-thumb">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#fca5a5" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
                        <span>Not uploaded</span>
                      </div>
                    </template>
                  </div>
                  <div class="doc-card-info">
                    <p class="doc-card-name">Business Permit / DTI</p>
                    <div class="doc-card-footer">
                      <span class="doc-tag" :class="selectedEmployer.hasBizPermit ? 'doc-tag-ok' : 'doc-tag-missing'">
                        {{ selectedEmployer.hasBizPermit ? 'Uploaded' : 'Missing' }}
                      </span>
                      <button v-if="selectedEmployer.hasBizPermit" class="doc-view-btn" @click="openDocViewer(selectedEmployer, 'bizPermit')">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                        View
                      </button>
                    </div>
                  </div>
                </div>

                <!-- BIR Certificate -->
                <div class="doc-card" :class="selectedEmployer.hasBirCert ? 'doc-card-ok' : 'doc-card-neutral'">
                  <div class="doc-card-preview" @click="selectedEmployer.hasBirCert && openDocViewer(selectedEmployer, 'birCert')">
                    <template v-if="selectedEmployer.hasBirCert">
                      <div class="doc-thumb">
                        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
                        <span class="doc-thumb-label">{{ selectedEmployer.birCertName || 'bir_certificate.pdf' }}</span>
                      </div>
                      <div class="doc-hover-overlay">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                        <span>View Document</span>
                      </div>
                    </template>
                    <template v-else>
                      <div class="doc-missing-thumb" style="color:#94a3b8">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                        <span>Not provided</span>
                      </div>
                    </template>
                  </div>
                  <div class="doc-card-info">
                    <p class="doc-card-name">BIR Certificate <span class="optional-label">Optional</span></p>
                    <div class="doc-card-footer">
                      <span class="doc-tag" :class="selectedEmployer.hasBirCert ? 'doc-tag-ok' : 'doc-tag-optional'">
                        {{ selectedEmployer.hasBirCert ? 'Uploaded' : 'Not provided' }}
                      </span>
                      <button v-if="selectedEmployer.hasBirCert" class="doc-view-btn" @click="openDocViewer(selectedEmployer, 'birCert')">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                        View
                      </button>
                    </div>
                  </div>
                </div>

              </div>
            </div>

            <!-- Remarks -->
            <div class="detail-section" style="margin-top:4px" v-if="selectedEmployer.verificationStatus === 'Pending'">
              <p class="detail-section-title">Remarks / Notes <span style="font-weight:400;color:#94a3b8;font-size:10px">(Optional)</span></p>
              <textarea v-model="verifyRemarks" class="remarks-input" placeholder="Add remarks for this employer (e.g. reason for rejection, notes for approval)…" rows="3"></textarea>
            </div>

            <div v-if="selectedEmployer.remarks" class="remarks-display">
              <p class="detail-section-title" style="margin-bottom:6px">Remarks</p>
              <p class="remarks-text">{{ selectedEmployer.remarks }}</p>
            </div>

          </div>

          <!-- Footer actions -->
          <div class="modal-footer">
            <button class="btn-ghost" @click="showModal = false" :disabled="actionLoading">Close</button>
            <template v-if="selectedEmployer?.verificationStatus === 'Pending'">
              <button class="btn-reject" @click="verifyEmployer('Rejected')" :disabled="actionLoading">
                <span v-if="actionLoading" class="spinner-sm"></span>
                <span v-else style="display:flex;align-items:center"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></span>
                Reject
              </button>
              <button class="btn-verify" @click="verifyEmployer('Verified')" :disabled="actionLoading">
                <span v-if="actionLoading" class="spinner-sm"></span>
                <span v-else style="display:flex;align-items:center"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg></span>
                Verify & Approve
              </button>
            </template>
            <template v-else-if="selectedEmployer?.verificationStatus === 'Verified'">
              <button class="btn-reject" @click="verifyEmployer('Suspended')" :disabled="actionLoading">
                <span v-if="actionLoading" class="spinner-sm"></span>
                Revoke Verification
              </button>
            </template>
            <template v-else-if="['Rejected', 'Suspended'].includes(selectedEmployer?.verificationStatus)">
              <button class="btn-verify" @click="verifyEmployer('Verified')" :disabled="actionLoading">
                <span v-if="actionLoading" class="spinner-sm"></span>
                Re-approve
              </button>
            </template>
          </div>
        </div>
      </div>
    </transition>

    <!-- DOCUMENT VIEWER LIGHTBOX -->
    <transition name="lightbox">
      <div v-if="showDocViewer" class="lightbox-overlay" @click.self="showDocViewer = false">
        <div class="lightbox">
          <div class="lightbox-header">
            <div class="lightbox-title-wrap">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
              <span class="lightbox-title">{{ activeDoc?.name }}</span>
              <span class="lightbox-company">— {{ activeDoc?.company }}</span>
            </div>
            <div class="lightbox-actions">
              <button @click="downloadDoc(activeDoc)" class="lightbox-btn">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                Download
              </button>
              <button class="lightbox-close" @click="showDocViewer = false">✕</button>
            </div>
          </div>
          <div class="lightbox-body">
            <template v-if="activeDoc?.type === 'image'">
              <img :src="activeDoc.url" class="doc-preview-img" alt="Document preview"/>
            </template>
            <template v-else-if="activeDoc?.type === 'pdf'">
              <iframe :src="activeDoc.url" class="doc-preview-iframe" frameborder="0"></iframe>
            </template>
            <template v-else>
              <div class="doc-preview-fallback">
                <div class="doc-preview-icon">
                  <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="1.2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
                </div>
                <p class="doc-preview-filename">{{ activeDoc?.name }}</p>
                <p class="doc-preview-hint">Document preview will appear here when connected to your backend.<br/>In production, render the uploaded file URL via &lt;iframe&gt; or &lt;img&gt;.</p>
                <div class="doc-preview-mock">
                  <div class="mock-line w80"></div>
                  <div class="mock-line w60"></div>
                  <div class="mock-line w90"></div>
                  <div class="mock-line w50"></div>
                  <div class="mock-gap"></div>
                  <div class="mock-line w70"></div>
                  <div class="mock-line w85"></div>
                  <div class="mock-line w40"></div>
                </div>
              </div>
            </template>
          </div>
        </div>
      </div>
    </transition>

  </div>
</template>

<script>
import api from '@/services/api'

const CHECK_SVG = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>`
const X_SVG     = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`

export default {
  name: 'EmployersPage',
  async mounted() {
    await this.fetchEmployers()
  },
  data() {
    return {
      search: '',
      filterStatus: '',
      showModal: false,
      showDocViewer: false,
      activeDoc: null,
      selectedEmployer: null,
      verifyRemarks: '',
      loading: false,
      actionLoading: false,
      toast: { show: false, text: '', type: 'success', icon: CHECK_SVG, _timer: null },
      employers: []
    }
  },
  computed: {
    filteredEmployers() {
      const q = this.search.toLowerCase()
      return this.employers.filter(e => {
        const match = !q ||
          e.companyName.toLowerCase().includes(q) ||
          e.contactPerson.toLowerCase().includes(q) ||
          e.email.toLowerCase().includes(q) ||
          e.city.toLowerCase().includes(q)
        return match && (!this.filterStatus || e.verificationStatus === this.filterStatus)
      })
    }
  },
  methods: {
    async downloadDoc(doc) {
      if (!doc?.url) return
      try {
        const path = doc.url.split('/storage/')[1]

        const response = await api.get('/admin/download', {
          params: { path },
          responseType: 'blob',
        })

        const blobUrl = URL.createObjectURL(response.data)
        const a = document.createElement('a')
        a.href = blobUrl
        a.download = doc.name || 'document'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(blobUrl)
      } catch (e) {
        console.error('Download failed:', e)
        this.showToastMsg('Download failed. Please try again.', 'error')
      }
    },

    async fetchEmployers() {
      this.loading = true
      try {
        const params = {}
        if (this.search)       params.search = this.search
        if (this.filterStatus) params.status = this.filterStatus.toLowerCase()
        const { data } = await api.get('/admin/employers', { params })
        const avatarColors = ['#2563eb', '#22c55e', '#f97316', '#ef4444', '#8b5cf6', '#06b6d4', '#14b8a6']

        // EmployerResource::collection wraps paginated data under data.data (the paginator items)
        // Shape: { success, data: { data: [...items], current_page, ... } }
        const list = data.data?.data || data.data || data || []

        this.employers = (Array.isArray(list) ? list : []).map((e, i) => {
          // EmployerResource exposes: contact_person, phone, biz_permit_url, bir_cert_url
          // Fallback to raw path fields in case resource is not used
          const bizPermitUrl = e.biz_permit_url
            || (e.biz_permit_path ? `/storage/${e.biz_permit_path}` : null)
          const birCertUrl = e.bir_cert_url
            || (e.bir_cert_path ? `/storage/${e.bir_cert_path}` : null)

          return {
            id:                 e.id,
            companyName:        e.company_name   || 'Unknown',
            industry:           e.industry       || '—',
            companySize:        e.company_size   || '—',
            city:               e.city           || '—',
            tin:                e.tin            || '—',
            website:            e.website        || '',
            contactPerson:      e.contact_person || '',
            phone:              e.phone          || e.contact_number || '',
            email:              e.email          || '',
            registeredDate:     e.created_at
              ? new Date(e.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
              : '—',
            verificationStatus: e.status
              ? (e.status.charAt(0).toUpperCase() + e.status.slice(1))
              : 'Pending',
            hasBizPermit:  !!bizPermitUrl,
            hasBirCert:    !!birCertUrl,
            bizPermitUrl,
            birCertUrl,
            bizPermitName: bizPermitUrl ? bizPermitUrl.split('/').pop() : null,
            birCertName:   birCertUrl   ? birCertUrl.split('/').pop()   : null,
            remarks:       e.remarks    || '',
            avatarBg:      avatarColors[i % avatarColors.length],
          }
        })
      } catch (e) { console.error(e) } finally { this.loading = false }
    },
    openDocViewer(employer, docType) {
      const isImage = (url) => url && /\.(jpg|jpeg|png|gif|webp)$/i.test(url)
      const isPdf   = (url) => url && /\.pdf$/i.test(url)
      const url  = docType === 'bizPermit' ? employer.bizPermitUrl : employer.birCertUrl
      const name = docType === 'bizPermit'
        ? (employer.bizPermitName || 'business_permit.pdf')
        : (employer.birCertName  || 'bir_certificate.pdf')
      this.activeDoc = {
        name,
        company: employer.companyName,
        url: url || null,
        type: isImage(url) ? 'image' : isPdf(url) ? 'pdf' : 'fallback'
      }
      console.log('Doc URL:', url)
      this.showDocViewer = true
    },
    viewEmployer(employer) {
      this.selectedEmployer = employer
      this.verifyRemarks = ''
      this.showModal = true
    },
    showToastMsg(text, type = 'success') {
      if (this.toast._timer) clearTimeout(this.toast._timer)
      this.toast = {
        show: true, text, type,
        icon: type === 'success' ? CHECK_SVG : X_SVG,
        _timer: setTimeout(() => { this.toast.show = false }, 3500)
      }
    },
    async quickVerify(employer, status) {
      if (this.actionLoading) return
      this.actionLoading = true
      try {
        const mappedStatus = status.toLowerCase()
        await api.patch(`/admin/employers/${employer.id}/status`, { status: mappedStatus })
        const idx = this.employers.findIndex(e => e.id === employer.id)
        if (idx !== -1) this.employers[idx].verificationStatus = status
        this.showToastMsg(`Employer ${mappedStatus} successfully`, 'success')
      } catch (e) {
        console.error(e)
        this.showToastMsg('Failed to update status', 'error')
      } finally {
        this.actionLoading = false
      }
    },
    async verifyEmployer(status) {
      if (this.actionLoading) return
      this.actionLoading = true
      try {
        const mappedStatus = status.toLowerCase()
        await api.patch(`/admin/employers/${this.selectedEmployer.id}/status`, {
          status: mappedStatus,
          remarks: this.verifyRemarks,
        })
        const idx = this.employers.findIndex(e => e.id === this.selectedEmployer.id)
        if (idx !== -1) {
          this.employers[idx].verificationStatus = status
          if (this.verifyRemarks) this.employers[idx].remarks = this.verifyRemarks
          this.selectedEmployer = { ...this.employers[idx] }
        }
        this.showToastMsg(`Employer ${mappedStatus} successfully`, 'success')
      } catch (e) {
        console.error(e)
        this.showToastMsg('Failed to verify employer', 'error')
      } finally {
        this.verifyRemarks = ''
        this.actionLoading = false
        this.showModal = false
      }
    }
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
.layout-wrapper { display: flex; height: 100vh; overflow: hidden; background: #f8fafc; font-family: 'Plus Jakarta Sans', sans-serif; }
.main-area { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
.page { flex: 1; overflow-y: auto; padding: 24px; display: flex; flex-direction: column; gap: 16px; }
.page-header { display: flex; align-items: flex-start; justify-content: space-between; }
.page-title { font-size: 20px; font-weight: 800; color: #1e293b; }
.page-sub { font-size: 12px; color: #94a3b8; margin-top: 2px; }

/* filters */
.filters-bar { display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; flex: 1; max-width: 360px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-group { display: flex; gap: 8px; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }

.table-card { background: #fff; border-radius: 14px; overflow: hidden; border: 1px solid #f1f5f9; }
.data-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.data-table thead tr { background: #f8fafc; }
.data-table th { text-align: left; padding: 11px 14px; font-size: 11px; font-weight: 700; color: #94a3b8; letter-spacing: 0.04em; text-transform: uppercase; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.table-row { cursor: pointer; transition: background 0.12s; }
.table-row:hover { background: #f8fafc; }
.data-table td { padding: 12px 14px; border-bottom: 1px solid #f8fafc; vertical-align: middle; }

.company-cell { display: flex; align-items: center; gap: 10px; }
.company-avatar { width: 34px; height: 34px; border-radius: 9px; color: #fff; font-size: 14px; font-weight: 800; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.company-name { font-size: 13px; font-weight: 700; color: #1e293b; }
.company-size { font-size: 11px; color: #94a3b8; margin-top: 1px; }
.person-name { font-size: 13px; font-weight: 600; color: #1e293b; }
.person-meta { font-size: 11px; color: #94a3b8; margin-top: 1px; }
.email-cell { font-size: 12px; color: #475569; }
.meta-cell { font-size: 12.5px; color: #475569; }

/* verification status badge */
.vstatus-badge { display: inline-flex; align-items: center; gap: 5px; padding: 4px 10px; border-radius: 99px; font-size: 11px; font-weight: 700; white-space: nowrap; }
.vstatus-dot { width: 6px; height: 6px; border-radius: 50%; flex-shrink: 0; }
.vstatus-pending  { background: #fffbeb; color: #d97706; }
.vstatus-pending .vstatus-dot  { background: #f59e0b; }
.vstatus-verified { background: #dcfce7; color: #16a34a; }
.vstatus-verified .vstatus-dot { background: #22c55e; }
.vstatus-rejected { background: #fef2f2; color: #dc2626; }
.vstatus-rejected .vstatus-dot { background: #ef4444; }
.vstatus-suspended { background: #fef2f2; color: #dc2626; }
.vstatus-suspended .vstatus-dot { background: #ef4444; }

.action-btns { display: flex; gap: 4px; }
.act-btn { width: 28px; height: 28px; border-radius: 7px; border: none; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.15s; }
.act-btn.view   { background: #f1f5f9; color: #64748b; }
.act-btn.view:hover { background: #e2e8f0; color: #1e293b; }
.act-btn.approve { background: #dcfce7; color: #16a34a; }
.act-btn.approve:hover { background: #bbf7d0; }
.act-btn.reject  { background: #fef2f2; color: #ef4444; }
.act-btn.reject:hover { background: #fee2e2; }

.empty-cell { padding: 40px !important; }
.empty-state { display: flex; flex-direction: column; align-items: center; gap: 10px; color: #cbd5e1; font-size: 13px; }
.pagination { display: flex; align-items: center; justify-content: space-between; padding: 14px 18px; border-top: 1px solid #f1f5f9; }
.page-info { font-size: 12px; color: #94a3b8; }
.page-btns { display: flex; gap: 4px; }
.page-btn { width: 30px; height: 30px; border-radius: 7px; border: 1px solid #e2e8f0; background: #fff; font-size: 12px; color: #64748b; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; }
.page-btn.active { background: #2563eb; color: #fff; border-color: #2563eb; }
.page-btn:hover:not(.active) { background: #f8fafc; }

/* Modal */
.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.4); z-index: 100; display: flex; align-items: center; justify-content: center; backdrop-filter: blur(2px); }
.modal { background: #fff; border-radius: 16px; width: 580px; max-width: 95vw; box-shadow: 0 20px 60px rgba(0,0,0,0.15); max-height: 90vh; display: flex; flex-direction: column; }
.modal-wide { width: 700px; }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 20px 24px; border-bottom: 1px solid #f1f5f9; flex-shrink: 0; }
.modal-title-wrap { display: flex; align-items: center; gap: 12px; }
.modal-icon { width: 40px; height: 40px; background: #eff6ff; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.modal-title { font-size: 16px; font-weight: 800; color: #1e293b; }
.modal-sub { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.modal-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 18px; padding: 4px; border-radius: 6px; line-height: 1; }
.modal-close:hover { background: #f1f5f9; color: #1e293b; }
.modal-body { padding: 20px 24px; display: flex; flex-direction: column; gap: 16px; overflow-y: auto; flex: 1; }
.modal-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 16px 24px; border-top: 1px solid #f1f5f9; flex-shrink: 0; }

/* detail layout */
.detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.detail-section { display: flex; flex-direction: column; gap: 10px; }
.detail-section-title { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.08em; padding-bottom: 6px; border-bottom: 1px solid #f1f5f9; }
.detail-rows { display: flex; flex-direction: column; gap: 8px; }
.detail-row { display: flex; flex-direction: column; gap: 2px; }
.detail-key { font-size: 10.5px; color: #94a3b8; font-weight: 600; }
.detail-val { font-size: 13px; color: #1e293b; font-weight: 500; }

/* doc cards */
.doc-cards { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.doc-card { border-radius: 12px; border: 1px solid #f1f5f9; overflow: hidden; background: #fff; }
.doc-card-ok      { border-color: #bbf7d0; }
.doc-card-missing { border-color: #fecaca; }
.doc-card-neutral { border-color: #e2e8f0; }
.doc-card-preview { height: 120px; background: #f8fafc; display: flex; align-items: center; justify-content: center; cursor: pointer; position: relative; overflow: hidden; transition: background 0.15s; }
.doc-card-ok .doc-card-preview     { background: #f0fdf4; }
.doc-card-missing .doc-card-preview { background: #fef2f2; cursor: default; }
.doc-card-neutral .doc-card-preview { cursor: default; }
.doc-thumb { display: flex; flex-direction: column; align-items: center; gap: 8px; }
.doc-thumb-label { font-size: 11px; color: #64748b; font-weight: 500; max-width: 140px; text-align: center; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.doc-hover-overlay { position: absolute; inset: 0; background: rgba(37,99,235,0.85); display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 6px; opacity: 0; transition: opacity 0.2s; color: #fff; font-size: 12px; font-weight: 600; }
.doc-card-preview:hover .doc-hover-overlay { opacity: 1; }
.doc-missing-thumb { display: flex; flex-direction: column; align-items: center; gap: 8px; font-size: 12px; color: #94a3b8; }
.doc-card-info { padding: 10px 12px; border-top: 1px solid #f1f5f9; }
.doc-card-name { font-size: 12.5px; font-weight: 700; color: #1e293b; margin-bottom: 6px; }
.optional-label { font-size: 10px; font-weight: 500; color: #94a3b8; margin-left: 4px; }
.doc-card-footer { display: flex; align-items: center; justify-content: space-between; }
.doc-view-btn { display: flex; align-items: center; gap: 4px; background: #eff6ff; border: none; border-radius: 6px; padding: 4px 10px; font-size: 11.5px; font-weight: 600; color: #2563eb; cursor: pointer; font-family: inherit; transition: background 0.15s; }
.doc-view-btn:hover { background: #dbeafe; }

/* lightbox */
.lightbox-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.75); z-index: 200; display: flex; align-items: center; justify-content: center; backdrop-filter: blur(4px); }
.lightbox { background: #fff; border-radius: 16px; width: 860px; max-width: 95vw; max-height: 92vh; display: flex; flex-direction: column; box-shadow: 0 30px 80px rgba(0,0,0,0.4); }
.lightbox-header { display: flex; align-items: center; justify-content: space-between; padding: 16px 20px; border-bottom: 1px solid #f1f5f9; flex-shrink: 0; }
.lightbox-title-wrap { display: flex; align-items: center; gap: 8px; }
.lightbox-title { font-size: 14px; font-weight: 700; color: #1e293b; }
.lightbox-company { font-size: 12px; color: #94a3b8; }
.lightbox-actions { display: flex; align-items: center; gap: 8px; }
.lightbox-btn { display: flex; align-items: center; gap: 6px; background: #f1f5f9; border: none; border-radius: 8px; padding: 7px 14px; font-size: 12.5px; font-weight: 600; color: #475569; cursor: pointer; font-family: inherit; text-decoration: none; transition: background 0.15s; }
.lightbox-btn:hover { background: #e2e8f0; }
.lightbox-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 18px; padding: 4px 8px; border-radius: 6px; line-height: 1; }
.lightbox-close:hover { background: #f1f5f9; color: #1e293b; }
.lightbox-body { flex: 1; overflow: auto; display: flex; align-items: center; justify-content: center; min-height: 0; background: #f8fafc; border-radius: 0 0 16px 16px; }
.doc-preview-img { max-width: 100%; max-height: 100%; object-fit: contain; border-radius: 0 0 16px 16px; }
.doc-preview-iframe { width: 100%; height: 600px; border: none; }
.doc-preview-fallback { display: flex; flex-direction: column; align-items: center; gap: 14px; padding: 40px; text-align: center; max-width: 480px; }
.doc-preview-icon { width: 80px; height: 80px; background: #eff6ff; border-radius: 20px; display: flex; align-items: center; justify-content: center; }
.doc-preview-filename { font-size: 14px; font-weight: 700; color: #1e293b; }
.doc-preview-hint { font-size: 12.5px; color: #94a3b8; line-height: 1.65; }
.doc-preview-mock { width: 100%; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 20px; display: flex; flex-direction: column; gap: 8px; }
.mock-line { height: 8px; background: #e2e8f0; border-radius: 4px; }
.mock-gap { height: 8px; }
.w40 { width: 40%; } .w50 { width: 50%; } .w60 { width: 60%; }
.w70 { width: 70%; } .w80 { width: 80%; } .w85 { width: 85%; } .w90 { width: 90%; }

.lightbox-enter-active, .lightbox-leave-active { transition: opacity 0.2s; }
.lightbox-enter-active .lightbox, .lightbox-leave-active .lightbox { transition: transform 0.25s, opacity 0.2s; }
.lightbox-enter-from, .lightbox-leave-to { opacity: 0; }
.lightbox-enter-from .lightbox, .lightbox-leave-to .lightbox { transform: scale(0.94); opacity: 0; }
.doc-tag { font-size: 10.5px; font-weight: 700; padding: 2px 9px; border-radius: 99px; white-space: nowrap; }
.doc-tag-ok      { background: #dcfce7; color: #16a34a; }
.doc-tag-missing { background: #fee2e2; color: #ef4444; }
.doc-tag-optional { background: #f1f5f9; color: #94a3b8; }

.remarks-input { width: 100%; border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px 12px; font-size: 13px; color: #1e293b; font-family: inherit; outline: none; background: #f8fafc; resize: vertical; transition: border 0.15s; }
.remarks-input:focus { border-color: #93c5fd; background: #fff; }
.remarks-display { background: #fffbeb; border: 1px solid #fde68a; border-radius: 10px; padding: 12px 14px; }
.remarks-text { font-size: 13px; color: #92400e; line-height: 1.6; }

.btn-ghost { background: #f1f5f9; color: #64748b; border: none; border-radius: 10px; padding: 9px 18px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-ghost:hover:not(:disabled) { background: #e2e8f0; }
.btn-ghost:disabled { opacity: 0.7; cursor: not-allowed; }
.btn-verify { display: flex; align-items: center; justify-content: center; gap: 6px; background: #22c55e; color: #fff; border: none; border-radius: 10px; padding: 9px 18px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; transition: background 0.15s; min-width: 130px; }
.btn-verify:hover:not(:disabled) { background: #16a34a; }
.btn-verify:disabled { opacity: 0.7; cursor: not-allowed; }
.btn-reject { display: flex; align-items: center; justify-content: center; gap: 6px; background: #fef2f2; color: #ef4444; border: 1.5px solid #fecaca; border-radius: 10px; padding: 9px 18px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; transition: all 0.15s; min-width: 130px; }
.btn-reject:hover:not(:disabled) { background: #fee2e2; }
.btn-reject:disabled { opacity: 0.7; cursor: not-allowed; }

.toast { position: fixed; top: 20px; right: 24px; z-index: 9999; display: flex; align-items: center; gap: 10px; padding: 12px 18px; border-radius: 12px; font-size: 13px; font-weight: 600; box-shadow: 0 8px 30px rgba(0,0,0,0.12); min-width: 240px; max-width: 380px; }
.toast.success { background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; }
.toast.error   { background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; }
.toast-icon { display: flex; align-items: center; flex-shrink: 0; }
.toast-msg { word-break: break-word; line-height: 1.4; }
.toast-enter-active, .toast-leave-active { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
.toast-enter-from, .toast-leave-to { opacity: 0; transform: translateY(-15px) scale(0.95); }

.spinner-sm { width: 15px; height: 15px; flex-shrink: 0; border: 2px solid rgba(255,255,255,0.4); border-top-color: #fff; border-radius: 50%; animation: spin 0.7s linear infinite; display: inline-block; }
@keyframes spin { to { transform: rotate(360deg); } }
.btn-reject .spinner-sm { border: 2px solid rgba(239, 68, 68, 0.4); border-top-color: #ef4444; }

.modal-enter-active, .modal-leave-active { transition: opacity 0.2s; }
.modal-enter-active .modal, .modal-leave-active .modal { transition: transform 0.2s, opacity 0.2s; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
.modal-enter-from .modal, .modal-leave-to .modal { transform: scale(0.95); opacity: 0; }

@media (max-width: 768px) {
  .toast { top: 16px; right: 16px; left: 16px; min-width: auto; max-width: none; }
}
</style>