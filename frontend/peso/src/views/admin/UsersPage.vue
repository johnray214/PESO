<template>
  <div class="layout-wrapper">
    <div class="main-area">
      <div class="page">

        <!-- SKELETON -->
        <template v-if="loading && !users.length">
          <div class="users-header" style="justify-content: flex-end;">
            <div class="skel" style="width: 110px; height: 36px; border-radius: 10px;"></div>
          </div>
          <div class="filters-bar" style="margin-bottom: 20px;">
            <div class="skel" style="width: 300px; height: 38px; border-radius: 10px;"></div>
            <div style="display:flex; gap:8px;">
              <div class="skel" style="width: 120px; height: 36px; border-radius: 8px;"></div>
              <div class="skel" style="width: 120px; height: 36px; border-radius: 8px;"></div>
            </div>
          </div>
          <div class="table-card" style="padding: 20px;">
            <div v-for="i in 6" :key="i" class="skel" style="width: 100%; height: 50px; border-radius: 8px; margin-bottom: 10px;"></div>
          </div>
        </template>

        <!-- ACTUAL CONTENT -->
        <template v-else>
          <div class="users-header">
            <button class="btn-primary" @click="openModal(null)">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
              Add Staff
            </button>
          </div>
          <div class="filters-bar">
            <div class="search-box">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
              <input v-model="search" type="text" placeholder="Search by name, email, role…" class="search-input"/>
            </div>
            <div class="filter-group">
              <select v-model="filterRole" class="filter-select">
                <option value="">All Roles</option>
                <option>Admin</option>
                <option>Staff</option>
              </select>
              <select v-model="filterStatus" class="filter-select">
                <option value="">All Status</option>
                <option>Active</option>
                <option>Inactive</option>
              </select>
            </div>
          </div>

          <div class="table-card">

            <!-- PAGE CHANGE SKELETON -->
            <template v-if="pageLoading">
              <div style="padding: 16px 20px;">
                <div v-for="i in 15" :key="i" class="skel" style="width: 100%; height: 48px; border-radius: 8px; margin-bottom: 8px;"></div>
              </div>
            </template>

            <template v-else>
            <table class="data-table">
              <thead>
                <tr>
                  <th>No.</th>
                  <th>Name</th><th>Email</th><th>Role</th><th>Sex</th>
                  <th>Contact</th><th>Address</th><th>Status</th><th>Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(u, index) in filteredUsers" :key="u.id" class="table-row" @click="openModal(u)">
                  <td @click.stop style="font-weight: 600; color: #64748b; font-size: 12px; padding-left: 18px;">{{ (currentPage - 1) * 15 + index + 1 }}</td>
                  <td>
                    <div class="person-cell">
                      <div class="avatar" :style="{ background: u.avatarBg }">{{ initials(u) }}</div>
                      <div>
                        <p class="person-name">{{ u.firstName }} {{ u.lastName }}</p>
                        <p class="person-meta">{{ u.middleName || '—' }}</p>
                      </div>
                    </div>
                  </td>
                  <td class="email-cell">{{ u.email }}</td>
                  <td><span class="role-badge" :class="u.role === 'Admin' ? 'role-admin' : 'role-staff'">{{ u.role }}</span></td>
                  <td class="meta-cell">{{ u.sex }}</td>
                  <td class="meta-cell">{{ u.number }}</td>
                  <td class="address-cell">{{ u.address }}</td>
                  <td @click.stop><span class="status-badge" :class="u.status === 'Active' ? 'active-s' : 'inactive-s'">{{ u.status }}</span></td>
                  <td @click.stop>
                    <div class="action-btns">
                      <button class="act-btn edit" @click="openModal(u)"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg></button>
                      <button class="act-btn delete" @click.stop="deleteUser(u)"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a1 1 0 011-1h4a1 1 0 011 1v2"/></svg></button>
                    </div>
                  </td>
                </tr>
                <tr v-if="filteredUsers.length === 0">
                  <td colspan="9" class="empty-cell">
                    <div class="empty-state">
                      <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.5"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                      <p>No staff found</p>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
            </template>

            <div class="pagination">
              <span class="page-info">Showing {{ (currentPage - 1) * 15 + 1 }}–{{ Math.min(currentPage * 15, totalUsers) }} of {{ totalUsers }} staff</span>
              <div class="page-btns">
                <button class="page-btn" :disabled="currentPage === 1 || pageLoading" @click="changePage(currentPage - 1)">‹</button>
                <button
                  v-for="p in paginationPages" :key="p"
                  class="page-btn" :class="{ active: currentPage === p }"
                  :disabled="pageLoading"
                  @click="changePage(p)">{{ p }}</button>
                <button class="page-btn" :disabled="currentPage === lastPage || pageLoading" @click="changePage(currentPage + 1)">›</button>
              </div>
            </div>
          </div>
        </template>
      </div>
    </div>

    <!-- Toast -->
    <transition name="toast">
      <div v-if="toast.show" class="toast" :class="toast.type">
        <span class="toast-icon" v-html="toast.icon"></span>
        <span class="toast-msg">{{ toast.text }}</span>
      </div>
    </transition>

    <!-- ADD / EDIT MODAL -->
    <transition name="modal">
      <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
        <div class="modal">
          <div class="modal-header">
            <div class="modal-title-wrap">
              <div class="modal-icon"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><line x1="20" y1="8" x2="20" y2="14"/><line x1="23" y1="11" x2="17" y2="11"/></svg></div>
              <div>
                <h3 class="modal-title">{{ editingUser ? 'Edit Staff' : 'Create Staff Account' }}</h3>
                <p class="modal-sub">{{ editingUser ? 'Update staff details' : 'Add a new internal staff account' }}</p>
              </div>
            </div>
            <button class="modal-close" @click="showModal = false">✕</button>
          </div>
          <div class="modal-body">
            <div class="form-section-label">Personal Information</div>
            <div class="form-row three">
              <div class="form-group">
                <label class="form-label">First Name <span class="req">*</span></label>
                <input v-model="form.firstName" class="form-input" :class="{ error: errors.firstName }" placeholder="e.g. Maria"/>
                <span v-if="errors.firstName" class="error-msg">Required</span>
              </div>
              <div class="form-group">
                <label class="form-label">Middle Name</label>
                <input v-model="form.middleName" class="form-input" placeholder="Optional"/>
              </div>
              <div class="form-group">
                <label class="form-label">Last Name <span class="req">*</span></label>
                <input v-model="form.lastName" class="form-input" :class="{ error: errors.lastName }" placeholder="e.g. Santos"/>
                <span v-if="errors.lastName" class="error-msg">Required</span>
              </div>
            </div>
            <div class="form-row two">
              <div class="form-group">
                <label class="form-label">Sex <span class="req">*</span></label>
                <select v-model="form.sex" class="form-input" :class="{ error: errors.sex }">
                  <option value="">Select sex</option>
                  <option>Male</option><option>Female</option>
                </select>
                <span v-if="errors.sex" class="error-msg">Required</span>
              </div>
              <div class="form-group">
                <label class="form-label">Contact Number <span class="req">*</span></label>
                <input v-model="form.number" class="form-input" :class="{ error: errors.number }" placeholder="e.g. 09171234567"/>
                <span v-if="errors.number" class="error-msg">Required</span>
              </div>
            </div>
            <div class="form-group">
              <label class="form-label">Address <span class="req">*</span></label>
              <input v-model="form.address" class="form-input" :class="{ error: errors.address }" placeholder="e.g. 123 Rizal St., Quezon City"/>
              <span v-if="errors.address" class="error-msg">Required</span>
            </div>
            <div class="form-section-label" style="margin-top:8px">Account Details</div>
            <div class="form-row two">
              <div class="form-group">
                <label class="form-label">Email <span class="req">*</span></label>
                <input v-model="form.email" type="email" class="form-input" :class="{ error: errors.email }" placeholder="e.g. maria@peso.gov.ph"/>
                <span v-if="errors.email" class="error-msg">Required</span>
              </div>
              <div class="form-group">
                <label class="form-label">Role <span class="req">*</span></label>
                <select v-model="form.role" class="form-input" :class="{ error: errors.role }">
                  <option value="">Select role</option>
                  <option>Admin</option><option>Staff</option>
                </select>
                <span v-if="errors.role" class="error-msg">Required</span>
              </div>
            </div>
            <div class="form-row two" v-if="!editingUser">
              <div class="form-group">
                <label class="form-label">Password <span class="req">*</span></label>
                <div class="input-eye">
                  <input v-model="form.password" :type="showPassword ? 'text' : 'password'" class="form-input" :class="{ error: errors.password }" placeholder="Create password"/>
                  <button type="button" class="eye-btn" @click="showPassword = !showPassword">
                    <svg v-if="!showPassword" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    <svg v-else width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                  </button>
                </div>
                <span v-if="errors.password" class="error-msg">Required</span>
              </div>
              <div class="form-group">
                <label class="form-label">Confirm Password <span class="req">*</span></label>
                <div class="input-eye">
                  <input v-model="form.confirmPassword" :type="showConfirm ? 'text' : 'password'" class="form-input" :class="{ error: errors.confirmPassword }" placeholder="Repeat password"/>
                  <button type="button" class="eye-btn" @click="showConfirm = !showConfirm">
                    <svg v-if="!showConfirm" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    <svg v-else width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                  </button>
                </div>
                <span v-if="errors.confirmPassword" class="error-msg">{{ errors.confirmPassword }}</span>
              </div>
            </div>
            <div v-if="editingUser" class="form-group">
              <label class="form-label">Status</label>
              <div class="status-toggle">
                <button :class="['toggle-opt', { active: form.status === 'Active' }]" @click="form.status = 'Active'">Active</button>
                <button :class="['toggle-opt', { active: form.status === 'Inactive' }]" @click="form.status = 'Inactive'">Inactive</button>
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn-ghost" @click="showModal = false">Cancel</button>
            <button type="button" class="btn-primary" @click="saveUser" :disabled="savingUser">
              <span v-if="savingUser" class="spinner-sm"></span>
              {{ savingUser ? 'Saving…' : (editingUser ? 'Save Changes' : 'Create Account') }}
            </button>
          </div>
        </div>
      </div>
    </transition>

    <!-- DELETE CONFIRM -->
    <transition name="modal">
      <div v-if="showDeleteConfirm" class="modal-overlay" @click.self="showDeleteConfirm = false">
        <div class="modal confirm-modal">
          <div class="confirm-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a1 1 0 011-1h4a1 1 0 011 1v2"/></svg></div>
          <h3 class="confirm-title">Delete Staff?</h3>
          <p class="confirm-msg">Are you sure you want to delete <strong>{{ deletingUser?.firstName }} {{ deletingUser?.lastName }}</strong>? This cannot be undone.</p>
          <div class="delete-actions">
            <button class="btn-ghost" @click="showDeleteConfirm = false">Cancel</button>
            <button class="btn-danger" @click="confirmDelete" :disabled="deletingUserLoading">
              <span v-if="deletingUserLoading" class="spinner-sm"></span>
              {{ deletingUserLoading ? 'Deleting…' : 'Delete User' }}
            </button>
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
  name: 'UsersPage',
  async mounted() {
    await this.fetchUsers()
  },
  data() {
    return {
      search: '', filterRole: '', filterStatus: '',
      showModal: false, showDeleteConfirm: false,
      editingUser: null, deletingUser: null,
      showPassword: false, showConfirm: false,
      errors: {},
      form: { firstName:'',middleName:'',lastName:'',email:'',role:'',sex:'',address:'',number:'',password:'',confirmPassword:'',status:'Active' },
      savingUser: false, deletingUserLoading: false, loading: true,
      toast: { show: false, text: '', type: 'success', icon: CHECK_SVG, _timer: null },
      avatarColors: ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#06b6d4'],
      users: [],
      currentPage: 1,
      lastPage: 1,
      totalUsers: 0,
      pageLoading: false,
    }
  },
  computed: {
    paginationPages() {
      const pages = []
      const start = Math.max(1, this.currentPage - 2)
      const end   = Math.min(this.lastPage, this.currentPage + 2)
      for (let i = start; i <= end; i++) pages.push(i)
      return pages
    },
    filteredUsers() {
      return this.users.filter(u => {
        const q = this.search.toLowerCase()
        const match = !q || `${u.firstName} ${u.lastName}`.toLowerCase().includes(q) || u.email.toLowerCase().includes(q) || u.role.toLowerCase().includes(q)
        return match && (!this.filterRole || u.role === this.filterRole) && (!this.filterStatus || u.status === this.filterStatus)
      })
    }
  },
  methods: {
    async fetchUsers(isPaginating = false) {
      if (isPaginating) { this.pageLoading = true } else { this.loading = true }
      try {
        const params = { page: this.currentPage }
        const { data } = await api.get('/admin/users', { params })
        // Backend returns { success, data: { data: [...], current_page, last_page, total } }
        const payload = data.data || data
        this.currentPage = payload.current_page || 1
        this.lastPage    = payload.last_page    || 1
        this.totalUsers  = payload.total        || 0
        const list = payload.data || payload || []
        this.users = (Array.isArray(list) ? list : []).map((u, i) => ({
          ...u,
          firstName:  u.first_name  || u.firstName  || '',
          middleName: u.middle_name || u.middleName || '',
          lastName:   u.last_name   || u.lastName   || '',
          number:     u.contact     || u.number      || '',
          sex:        u.sex    ? (u.sex.charAt(0).toUpperCase()    + u.sex.slice(1))    : '',
          role:       u.role   ? (u.role.charAt(0).toUpperCase()   + u.role.slice(1))   : '',
          status:     u.status ? (u.status.charAt(0).toUpperCase() + u.status.slice(1)) : 'Active',
          avatarBg:   this.avatarColors[i % this.avatarColors.length],
        }))
      } catch (e) { console.error(e) } finally { this.loading = false; this.pageLoading = false }
    },
    changePage(page) {
      if (page >= 1 && page <= this.lastPage && !this.pageLoading) {
        this.currentPage = page
        this.fetchUsers(true)
      }
    },
    initials(u) { return `${u.firstName?.[0]??''}${u.lastName?.[0]??''}`.toUpperCase() },
    openModal(user) {
      this.errors = {}; this.showPassword = false; this.showConfirm = false
      this.editingUser = user
      this.form = user ? { ...user, password:'', confirmPassword:'', number: user.number||user.contact } : { firstName:'',middleName:'',lastName:'',email:'',role:'',sex:'',address:'',number:'',password:'',confirmPassword:'',status:'Active' }
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
    validate() {
      const e = {}
      if (!(this.form.firstName||'').trim()) e.firstName = true
      if (!(this.form.lastName||'').trim())  e.lastName  = true
      if (!(this.form.email||'').trim())     e.email     = true
      if (!this.form.role)                   e.role       = true
      if (!this.form.sex)                    e.sex       = true
      if (!(this.form.number||'').trim())    e.number    = true
      if (!(this.form.address||'').trim())   e.address   = true
      if (!this.editingUser) {
        if (!this.form.password) e.password = true
        if (!this.form.confirmPassword) e.confirmPassword = 'Required'
        else if (this.form.password !== this.form.confirmPassword) e.confirmPassword = 'Passwords do not match'
      }
      this.errors = e; return Object.keys(e).length === 0
    },
    async saveUser() {
      if (!this.validate()) return
      this.savingUser = true
      try {
        const payload = {
          first_name:  this.form.firstName,
          middle_name: this.form.middleName,
          last_name:   this.form.lastName,
          email:       this.form.email,
          role:        (this.form.role   || '').toLowerCase(),
          sex:         (this.form.sex    || '').toLowerCase(),
          contact:     this.form.number,
          address:     this.form.address,
          status:      (this.form.status || 'active').toLowerCase(),
        }
        if (!this.editingUser) {
          payload.password = this.form.password
          payload.password_confirmation = this.form.confirmPassword
        }
        if (this.editingUser) {
          const { data } = await api.put(`/admin/users/${this.editingUser.id}`, payload)
          const updated = {
            ...(data.data || data),
            firstName:  this.form.firstName,
            lastName:   this.form.lastName,
            middleName: this.form.middleName,
            number:     this.form.number,
            sex:        this.form.sex    ? (this.form.sex.charAt(0).toUpperCase()    + this.form.sex.slice(1))    : '',
            role:       this.form.role   ? (this.form.role.charAt(0).toUpperCase()   + this.form.role.slice(1))   : '',
            status:     this.form.status ? (this.form.status.charAt(0).toUpperCase() + this.form.status.slice(1)) : 'Active',
            avatarBg:   this.editingUser.avatarBg
          }
          const i = this.users.findIndex(u => u.id === this.editingUser.id)
          if (i !== -1) this.users[i] = updated
          this.showToastMsg('User updated successfully', 'success')
        } else {
          const { data } = await api.post('/admin/users', payload)
          const nu = data.data || data
          this.users.unshift({
            ...nu,
            firstName:  this.form.firstName,
            lastName:   this.form.lastName,
            middleName: this.form.middleName,
            number:     this.form.number,
            sex:        this.form.sex    ? (this.form.sex.charAt(0).toUpperCase()    + this.form.sex.slice(1))    : '',
            role:       this.form.role   ? (this.form.role.charAt(0).toUpperCase()   + this.form.role.slice(1))   : '',
            status:     this.form.status ? (this.form.status.charAt(0).toUpperCase() + this.form.status.slice(1)) : 'Active',
            avatarBg:   this.avatarColors[this.users.length % this.avatarColors.length]
          })
          this.showToastMsg('User added successfully', 'success')
        }
        this.showModal = false
      } catch (e) {
        const errs = e.response?.data?.errors
        if (errs) Object.keys(errs).forEach(k => { this.errors[k] = errs[k][0] })
        this.showToastMsg(e.response?.data?.message || 'Failed to save user.', 'error')
      } finally {
        this.savingUser = false
      }
    },
    deleteUser(u) { this.deletingUser = u; this.showDeleteConfirm = true },
    async confirmDelete() {
      this.deletingUserLoading = true
      try {
        await api.delete(`/admin/users/${this.deletingUser.id}`)
        this.users = this.users.filter(u => u.id !== this.deletingUser.id)
        this.showToastMsg('User deleted successfully', 'success')
      } catch (e) {
        console.error(e)
        this.showToastMsg('Failed to delete user', 'error')
      } finally {
        this.showDeleteConfirm = false; this.deletingUser = null; this.deletingUserLoading = false
      }
    }
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

@keyframes shimmer { 0% { background-position: -400px 0; } 100% { background-position: 400px 0; } }
.skel {
  background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%);
  background-size: 400px 100%; animation: shimmer 1.4s infinite linear;
  border-radius: 6px; flex-shrink: 0;
}

.layout-wrapper { display: flex; min-height: 100vh; background: #f8fafc; font-family: 'Plus Jakarta Sans', sans-serif; }
.main-area { flex: 1; display: flex; flex-direction: column; }
.page { flex: 1; padding: 24px; display: flex; flex-direction: column; gap: 16px; }
.users-header { display: flex; justify-content: flex-end; }
.filters-bar { display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; }
.search-box { display: flex; align-items: center; gap: 8px; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; flex: 1; max-width: 360px; }
.search-input { border: none; outline: none; font-size: 13px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.search-input::placeholder { color: #cbd5e1; }
.filter-group { display: flex; gap: 8px; }
.filter-select { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; font-size: 12.5px; color: #475569; cursor: pointer; outline: none; font-family: inherit; }
.btn-primary { display: flex; align-items: center; justify-content: center; gap: 6px; background: #2563eb; color: #fff; border: none; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; transition: background 0.15s; min-width: 130px; }
.btn-primary:hover:not(:disabled) { background: #1d4ed8; }
.btn-primary:disabled { opacity: 0.7; cursor: not-allowed; }
.table-card { background: #fff; border-radius: 14px; overflow: hidden; border: 1px solid #f1f5f9; }
.data-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.data-table thead tr { background: #f8fafc; }
.data-table th { text-align: left; padding: 11px 14px; font-size: 11px; font-weight: 700; color: #94a3b8; letter-spacing: 0.04em; text-transform: uppercase; border-bottom: 1px solid #f1f5f9; white-space: nowrap; }
.table-row { cursor: pointer; transition: background 0.12s; }
.table-row:hover { background: #f8fafc; }
.data-table td { padding: 12px 14px; border-bottom: 1px solid #f8fafc; vertical-align: middle; }
.person-cell { display: flex; align-items: center; gap: 10px; }
.avatar { width: 34px; height: 34px; border-radius: 50%; color: #fff; font-size: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.person-name { font-size: 13px; font-weight: 600; color: #1e293b; }
.person-meta { font-size: 11px; color: #94a3b8; margin-top: 1px; }
.email-cell { font-size: 12px; color: #475569; }
.meta-cell { font-size: 12.5px; color: #475569; }
.address-cell { font-size: 12px; color: #64748b; max-width: 180px; }
.role-badge { font-size: 11px; font-weight: 700; padding: 3px 10px; border-radius: 6px; white-space: nowrap; }
.role-admin { background: #dbeafe; color: #2563eb; }
.role-staff { background: #fff7ed; color: #f97316; }
.status-badge { padding: 4px 10px; border-radius: 99px; font-size: 11px; font-weight: 600; white-space: nowrap; }
.active-s { background: #dcfce7; color: #22c55e; }
.inactive-s { background: #f1f5f9; color: #94a3b8; }
.action-btns { display: flex; gap: 4px; }
.act-btn { width: 28px; height: 28px; border-radius: 7px; border: none; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.15s; }
.act-btn.edit { background: #eff6ff; color: #2563eb; }
.act-btn.edit:hover { background: #dbeafe; }
.act-btn.delete { background: #fef2f2; color: #ef4444; }
.act-btn.delete:hover { background: #fee2e2; }
.empty-cell { padding: 40px !important; }
.empty-state { display: flex; flex-direction: column; align-items: center; gap: 10px; color: #cbd5e1; font-size: 13px; }
.pagination { display: flex; align-items: center; justify-content: space-between; padding: 14px 18px; border-top: 1px solid #f1f5f9; }
.page-info { font-size: 12px; color: #94a3b8; }
.page-btns { display: flex; gap: 4px; }
.page-btn { width: 30px; height: 30px; border-radius: 7px; border: 1px solid #e2e8f0; background: #fff; font-size: 12px; color: #64748b; cursor: pointer; font-family: inherit; display: flex; align-items: center; justify-content: center; transition: all 0.15s; }
.page-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.page-btn.active { background: #2563eb; color: #fff; border-color: #2563eb; }
.page-btn:hover:not(.active):not(:disabled) { background: #f8fafc; }

/* Modal */
.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.4); z-index: 100; display: flex; align-items: center; justify-content: center; backdrop-filter: blur(2px); }
.modal { background: #fff; border-radius: 16px; width: 580px; max-width: 95vw; box-shadow: 0 20px 60px rgba(0,0,0,0.15); max-height: 90vh; display: flex; flex-direction: column; }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 20px 24px; border-bottom: 1px solid #f1f5f9; flex-shrink: 0; }
.modal-title-wrap { display: flex; align-items: center; gap: 12px; }
.modal-icon { width: 40px; height: 40px; background: #eff6ff; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.modal-title { font-size: 16px; font-weight: 800; color: #1e293b; }
.modal-sub { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.modal-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 18px; padding: 4px; border-radius: 6px; line-height: 1; }
.modal-close:hover { background: #f1f5f9; color: #1e293b; }
.modal-body { padding: 20px 24px; display: flex; flex-direction: column; gap: 14px; overflow-y: auto; flex: 1; }
.modal-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 16px 24px; border-top: 1px solid #f1f5f9; flex-shrink: 0; }
.form-section-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.08em; padding-bottom: 2px; border-bottom: 1px solid #f1f5f9; }
.form-row { display: grid; gap: 12px; }
.form-row.three { grid-template-columns: 1fr 1fr 1fr; }
.form-row.two   { grid-template-columns: 1fr 1fr; }
.form-group { display: flex; flex-direction: column; gap: 5px; }
.form-label { font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; }
.req { color: #ef4444; }
.form-input { border: 1px solid #e2e8f0; border-radius: 8px; padding: 9px 12px; font-size: 13px; color: #1e293b; font-family: inherit; outline: none; background: #f8fafc; transition: border 0.15s; }
.form-input:focus { border-color: #93c5fd; background: #fff; }
.form-input.error { border-color: #fca5a5; background: #fff5f5; }
.error-msg { font-size: 11px; color: #ef4444; }
.input-eye { position: relative; }
.input-eye .form-input { width: 100%; padding-right: 36px; }
.eye-btn { position: absolute; right: 10px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; color: #94a3b8; display: flex; align-items: center; }
.eye-btn:hover { color: #475569; }
.status-toggle { display: flex; gap: 8px; }
.toggle-opt { padding: 8px 20px; border-radius: 8px; border: 2px solid #e2e8f0; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; background: #f8fafc; color: #64748b; transition: all 0.15s; }
.toggle-opt.active { border-color: #2563eb; background: #eff6ff; color: #2563eb; }
.btn-ghost { background: #f1f5f9; color: #64748b; border: none; border-radius: 10px; padding: 9px 18px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-ghost:hover { background: #e2e8f0; }
.btn-danger { display: flex; align-items: center; justify-content: center; gap: 6px; background: #ef4444; color: #fff; border: none; border-radius: 10px; padding: 9px 18px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; min-width: 120px; }
.btn-danger:hover:not(:disabled) { background: #dc2626; }
.btn-danger:disabled { opacity: 0.7; cursor: not-allowed; }
.confirm-modal { width: 380px; padding: 32px 28px; display: flex; flex-direction: column; align-items: center; text-align: center; gap: 12px; }
.confirm-icon { width: 60px; height: 60px; background: #fef2f2; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.confirm-title { font-size: 18px; font-weight: 800; color: #1e293b; }
.confirm-msg { font-size: 13px; color: #64748b; line-height: 1.6; }
.delete-actions { display: flex; gap: 10px; margin-top: 8px; }
.modal-enter-active, .modal-leave-active { transition: opacity 0.2s; }
.modal-enter-active .modal, .modal-leave-active .modal { transition: transform 0.2s, opacity 0.2s; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
.modal-enter-from .modal, .modal-leave-to .modal { transform: scale(0.95); opacity: 0; }

/* Toast */
.toast { position: fixed; top: 20px; right: 24px; z-index: 9999; display: flex; align-items: center; gap: 10px; padding: 12px 18px; border-radius: 12px; font-size: 13px; font-weight: 600; box-shadow: 0 8px 30px rgba(0,0,0,0.12); min-width: 240px; max-width: 380px; }
.toast.success { background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; }
.toast.error   { background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; }
.toast-icon { display: flex; align-items: center; flex-shrink: 0; }
.toast-msg { word-break: break-word; line-height: 1.4; }
.toast-enter-active, .toast-leave-active { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
.toast-enter-from, .toast-leave-to { opacity: 0; transform: translateY(-15px) scale(0.95); }

.spinner-sm { width: 15px; height: 15px; flex-shrink: 0; border: 2px solid rgba(255,255,255,0.4); border-top-color: #fff; border-radius: 50%; animation: spin 0.7s linear infinite; display: inline-block; }
@keyframes spin { to { transform: rotate(360deg); } }

@media (max-width: 768px) {
  .page { padding: 16px; }
  .filters-bar { flex-direction: column; align-items: stretch; }
  .search-box { max-width: none; }
  .toast { top: 16px; right: 16px; left: 16px; min-width: auto; max-width: none; }
}
</style>