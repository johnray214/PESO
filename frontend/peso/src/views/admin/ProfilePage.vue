<template>
  <div class="page">

    <!-- Toast -->
    <transition name="toast">
      <div v-if="toast.show" class="toast" :class="toast.type">
        <span class="toast-icon" v-html="toast.icon"></span>
        <span class="toast-msg">{{ toast.text }}</span>
      </div>
    </transition>

    <input ref="photoInput" type="file" accept="image/*" style="display:none" @change="previewPhoto" />

    <!-- SKELETON -->
    <template v-if="loading">
      <div class="profile-grid">
        <div class="left-col">
          <div class="profile-card skel" style="height: 250px; border-radius: 14px;"></div>
          <div class="section-card account-settings-card skel" style="height: 200px; border-radius: 14px;"></div>
        </div>
        <div class="right-col">
          <div class="section-card skel" style="height: 480px; border-radius: 14px;"></div>
          <div class="section-card skel" style="height: 320px; border-radius: 14px;"></div>
        </div>
      </div>
    </template>

    <!-- ACTUAL CONTENT -->
    <template v-else>
    <div class="profile-grid">

      <!-- LEFT COLUMN -->
      <div class="left-col">

        <!-- Profile Card -->
        <div class="profile-card">
          <div class="profile-avatar-section">

            <!-- Avatar with inline preview overlay -->
            <div class="avatar-wrapper">
              <div class="profile-avatar">
                <img
                  v-if="photoPreview || user.photo"
                  :src="photoPreview || user.photo"
                  class="avatar-img"
                  alt="Profile photo"
                />
                <span v-else>{{ user.firstName[0] || '?' }}{{ user.lastName[0] || '' }}</span>
              </div>

              <!-- Preview badge when a new photo is staged -->
              <transition name="fade">
                <span v-if="photoPreview" class="preview-badge">Preview</span>
              </transition>
            </div>

            <!-- Upload / action buttons -->
            <div class="upload-actions">
              <button class="upload-btn" @click="$refs.photoInput.click()" :disabled="uploadingPhoto">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
                {{ photoPreview ? 'Change' : 'Upload Photo' }}
              </button>

              <!-- Confirm / Cancel only shown when a preview is staged -->
              <transition name="fade">
                <div v-if="photoPreview" class="preview-actions">
                  <button class="btn-confirm" @click="confirmUpload" :disabled="uploadingPhoto">
                    <span v-if="uploadingPhoto" class="spinner-sm"></span>
                    <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                    {{ uploadingPhoto ? 'Saving…' : 'Save' }}
                  </button>
                  <button class="btn-cancel-photo" @click="cancelPhoto" :disabled="uploadingPhoto">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                    Discard
                  </button>
                </div>
              </transition>
            </div>

          </div>

          <div class="profile-info">
            <h3 class="profile-name">{{ user.firstName }} {{ user.lastName }}</h3>
            <p class="profile-email">{{ user.email }}</p>
            <div class="profile-badges">
              <span class="role-badge">{{ user.role }}</span>
              <span class="status-badge active">{{ user.status }}</span>
            </div>
          </div>
        </div>

        <!-- Account Settings — stretched to match Change Password card -->
        <div class="section-card account-settings-card">
          <h3 class="section-title">Account Settings</h3>
          <div class="form-grid two-col">
            <div class="form-field">
              <label class="form-label">Role</label>
              <select v-model="user.role" class="form-input" disabled>
                <option value="Admin">Admin</option>
                <option value="Staff">Staff</option>
              </select>
            </div>
            <div class="form-field">
              <label class="form-label">Status</label>
              <select v-model="user.status" class="form-input" disabled>
                <option value="Active">Active</option>
                <option value="Inactive">Inactive</option>
              </select>
            </div>
          </div>
          <!-- Spacer pushes nothing here; card height is controlled by grid stretch -->
        </div>

      </div><!-- /left-col -->

      <!-- RIGHT COLUMN -->
      <div class="right-col">

        <!-- Personal Information -->
        <div class="section-card">
          <h3 class="section-title">Personal Information</h3>
          <div class="form-grid">
            <div class="form-field">
              <label class="form-label">First Name</label>
              <input v-model="user.firstName" type="text" class="form-input" />
            </div>
            <div class="form-field">
              <label class="form-label">Middle Name</label>
              <input v-model="user.middleName" type="text" class="form-input" />
            </div>
            <div class="form-field">
              <label class="form-label">Last Name</label>
              <input v-model="user.lastName" type="text" class="form-input" />
            </div>
            <div class="form-field">
              <label class="form-label">Email Address</label>
              <input v-model="user.email" type="email" class="form-input" />
            </div>
            <div class="form-field">
              <label class="form-label">Contact Number</label>
              <input v-model="user.number" type="text" class="form-input" />
            </div>
            <div class="form-field">
              <label class="form-label">Sex</label>
              <select v-model="user.sex" class="form-input">
                <option value="">Select</option>
                <option value="Male">Male</option>
                <option value="Female">Female</option>
              </select>
            </div>
            <div class="form-field full-width">
              <label class="form-label">Address</label>
              <input v-model="user.address" type="text" class="form-input" />
            </div>
          </div>
          <div class="section-footer">
            <button class="btn-primary" @click="saveProfile" :disabled="savingProfile">
              <span v-if="savingProfile" class="spinner-sm"></span>
              <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg>
              {{ savingProfile ? 'Saving…' : 'Save Changes' }}
            </button>
          </div>
        </div>

        <!-- Change Password -->
        <div class="section-card">
          <h3 class="section-title">Change Password</h3>
          <div class="form-grid">
            <div class="form-field">
              <label class="form-label">Current Password</label>
              <div class="input-eye">
                <input v-model="password.current" :type="showPw.current ? 'text' : 'password'" class="form-input" placeholder="Enter current password" />
                <button type="button" class="eye-btn" @click="showPw.current = !showPw.current">
                  <svg v-if="!showPw.current" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  <svg v-else width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                </button>
              </div>
            </div>
            <div class="form-field">
              <label class="form-label">New Password</label>
              <div class="input-eye">
                <input v-model="password.new" :type="showPw.new ? 'text' : 'password'" class="form-input" placeholder="Enter new password" />
                <button type="button" class="eye-btn" @click="showPw.new = !showPw.new">
                  <svg v-if="!showPw.new" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  <svg v-else width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                </button>
              </div>
            </div>
            <div class="form-field">
              <label class="form-label">Confirm Password</label>
              <div class="input-eye">
                <input v-model="password.confirm" :type="showPw.confirm ? 'text' : 'password'" class="form-input" placeholder="Confirm new password" />
                <button type="button" class="eye-btn" @click="showPw.confirm = !showPw.confirm">
                  <svg v-if="!showPw.confirm" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  <svg v-else width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                </button>
              </div>
            </div>
          </div>
          <div class="section-footer">
            <button class="btn-primary" @click="updatePassword" :disabled="savingPw">
              <span v-if="savingPw" class="spinner-sm"></span>
              <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
              {{ savingPw ? 'Updating…' : 'Update Password' }}
            </button>
          </div>
        </div>

      </div><!-- /right-col -->
    </div>
    </template>
  </div>
</template>

<script>
import api from '@/services/api'
import { useAuthStore } from '@/stores/auth'

const CHECK_SVG = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>`
const X_SVG    = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`

export default {
  name: 'ProfilePage',
  async mounted() {
    try {
      const { data } = await api.get('/admin/profile')
      const p = data.data || data
      this.user = {
        firstName:  p.first_name  || '',
        middleName: p.middle_name || '',
        lastName:   p.last_name   || '',
        email:      p.email       || '',
        role:       p.role        || '',
        sex:        p.sex ? (p.sex.charAt(0).toUpperCase() + p.sex.slice(1)) : '',
        number:     p.contact     || '',
        address:    p.address     || '',
        status:     p.status      || 'Active',
        photo:      p.photo       || null,
      }
    } catch (e) { console.error(e) } finally { this.loading = false }
  },
  data() {
    return {
      user: { firstName: '', middleName: '', lastName: '', email: '', role: '', sex: '', number: '', address: '', status: 'Active', photo: null },
      password: { current: '', new: '', confirm: '' },
      showPw: { current: false, new: false, confirm: false },
      loading: true,
      savingProfile: false,
      savingPw: false,
      uploadingPhoto: false,
      photoPreview: null,
      pendingFile: null,
      toast: { show: false, text: '', type: 'success', icon: CHECK_SVG, _timer: null },
    }
  },
  methods: {
    showToast(text, type = 'success') {
      if (this.toast._timer) clearTimeout(this.toast._timer)
      this.toast = {
        show: true, text, type,
        icon: type === 'success' ? CHECK_SVG : X_SVG,
        _timer: setTimeout(() => { this.toast.show = false }, 3500)
      }
    },
    async saveProfile() {
      this.savingProfile = true
      try {
        await api.put('/admin/profile', {
          first_name:  this.user.firstName,
          middle_name: this.user.middleName,
          last_name:   this.user.lastName,
          email:       this.user.email,
          sex:         this.user.sex,
          contact:     this.user.number,
          address:     this.user.address,
        })
        this.showToast('Personal Information Updated', 'success')
      } catch (e) {
        const msg = e.response?.data?.message
          || (e.response?.data?.errors ? Object.values(e.response.data.errors).flat().join(' ') : null)
        this.showToast(msg || 'Failed to update profile.', 'error')
      } finally {
        this.savingProfile = false
      }
    },
    async updatePassword() {
      if (!this.password.current || !this.password.new || !this.password.confirm) {
        this.showToast('Please fill all password fields.', 'error'); return
      }
      if (this.password.new !== this.password.confirm) {
        this.showToast('New passwords do not match.', 'error'); return
      }
      this.savingPw = true
      try {
        await api.post('/admin/profile/password', {
          current_password:      this.password.current,
          password:              this.password.new,
          password_confirmation: this.password.confirm,
        })
        this.showToast('Password Updated Successfully', 'success')
        this.password = { current: '', new: '', confirm: '' }
        this.showPw   = { current: false, new: false, confirm: false }
      } catch (e) {
        this.showToast(e.response?.data?.message || 'Failed to update password.', 'error')
      } finally {
        this.savingPw = false
      }
    },
    previewPhoto(e) {
      const file = e.target.files[0]
      if (!file) return
      this.pendingFile  = file
      this.photoPreview = URL.createObjectURL(file)
      this.$refs.photoInput.value = ''
    },
    cancelPhoto() {
      this.photoPreview = null
      this.pendingFile  = null
    },
    async confirmUpload() {
      if (!this.pendingFile) return
      this.uploadingPhoto = true
      try {
        const form = new FormData()
        form.append('photo', this.pendingFile)
        const { data } = await api.post('/admin/profile/photo', form, {
          headers: { 'Content-Type': 'multipart/form-data' }
        })
        const newPhotoUrl = data.data?.photo || this.photoPreview
        this.user.photo   = newPhotoUrl

        const authStore = useAuthStore()
        authStore.photo = newPhotoUrl
        localStorage.setItem('peso-auth', JSON.stringify({ user: authStore.user, role: authStore.role, photo: newPhotoUrl }))

        this.photoPreview = null
        this.pendingFile  = null
        this.showToast('Profile Photo Updated', 'success')
      } catch (e) {
        this.showToast(e.response?.data?.message || 'Failed to upload photo.', 'error')
      } finally {
        this.uploadingPhoto = false
      }
    },
  },
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

.page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  padding: 24px; background: #f8fafc;
  display: flex; flex-direction: column; gap: 20px;
}

/* Toast */
.toast {
  position: fixed; top: 20px; right: 24px; z-index: 9999;
  display: flex; align-items: center; gap: 10px;
  padding: 12px 18px; border-radius: 12px;
  font-size: 13px; font-weight: 600;
  box-shadow: 0 8px 30px rgba(0,0,0,0.12);
  min-width: 240px; max-width: 380px;
}
.toast.success { background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; }
.toast.error   { background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; }
.toast-icon { display: flex; align-items: center; flex-shrink: 0; }
.toast-enter-active, .toast-leave-active { transition: all 0.3s ease; }
.toast-enter-from, .toast-leave-to { opacity: 0; transform: translateY(-10px) scale(0.95); }

/* Fade transition for inline preview elements */
.fade-enter-active, .fade-leave-active { transition: all 0.2s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; transform: translateY(4px); }

/* Spinners */
.spinner-sm {
  width: 14px; height: 14px; flex-shrink: 0;
  border: 2px solid rgba(255,255,255,0.35); border-top-color: #fff;
  border-radius: 50%; animation: spin 0.6s linear infinite; display: inline-block;
}
@keyframes spin { to { transform: rotate(360deg); } }

/* Buttons */
.btn-primary {
  display: flex; align-items: center; gap: 7px;
  background: #2563eb; color: #fff; border: none; border-radius: 10px;
  padding: 10px 18px; font-size: 13px; font-weight: 600; cursor: pointer;
  font-family: inherit; transition: background 0.15s; min-width: 140px; justify-content: center;
}
.btn-primary:hover:not(:disabled) { background: #1d4ed8; }
.btn-primary:disabled { opacity: 0.7; cursor: not-allowed; }

.upload-btn {
  display: flex; align-items: center; gap: 6px;
  background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px;
  padding: 7px 14px; font-size: 12px; font-weight: 600; color: #475569;
  cursor: pointer; font-family: inherit; transition: all 0.15s;
}
.upload-btn:hover:not(:disabled) { background: #f1f5f9; border-color: #cbd5e1; }
.upload-btn:disabled { opacity: 0.7; cursor: not-allowed; }

/* Inline preview confirm/cancel buttons */
.preview-actions {
  display: flex; gap: 6px; margin-top: 4px;
}
.btn-confirm {
  display: flex; align-items: center; gap: 5px;
  background: #2563eb; color: #fff; border: none; border-radius: 7px;
  padding: 6px 12px; font-size: 12px; font-weight: 600; cursor: pointer;
  font-family: inherit; transition: background 0.15s;
}
.btn-confirm:hover:not(:disabled) { background: #1d4ed8; }
.btn-confirm:disabled { opacity: 0.7; cursor: not-allowed; }

.btn-cancel-photo {
  display: flex; align-items: center; gap: 5px;
  background: #f1f5f9; color: #475569; border: none; border-radius: 7px;
  padding: 6px 12px; font-size: 12px; font-weight: 600; cursor: pointer;
  font-family: inherit; transition: background 0.15s;
}
.btn-cancel-photo:hover:not(:disabled) { background: #e2e8f0; }
.btn-cancel-photo:disabled { opacity: 0.7; cursor: not-allowed; }

/* ── Layout ──────────────────────────────────────────────────
   4-cell grid: 2 columns × 2 rows.
   All four cards are direct grid children so the browser
   can equalize row heights automatically.                    */
.profile-grid {
  display: grid;
  grid-template-columns: 280px 1fr;
  grid-template-rows: auto auto;
  gap: 20px;
}

/* Flatten both columns into the outer grid */
.left-col, .right-col { display: contents; }

/* Explicit placement */
.profile-card          { grid-column: 1; grid-row: 1; }
.account-settings-card { grid-column: 1; grid-row: 2; }
.right-col > .section-card:nth-child(1) { grid-column: 2; grid-row: 1; }
.right-col > .section-card:nth-child(2) { grid-column: 2; grid-row: 2; }

/* Base card styles (shared by all four) */
.profile-card,
.account-settings-card,
.section-card {
  background: #fff;
  border: 1px solid #f1f5f9;
  border-radius: 14px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.04);
}

/* Profile card internals */
.profile-avatar-section { display: flex; flex-direction: column; align-items: center; gap: 12px; }

.avatar-wrapper { position: relative; display: inline-flex; }

.profile-avatar {
  width: 90px; height: 90px; border-radius: 50%;
  background: linear-gradient(135deg, #2563eb, #3b82f6);
  color: #fff; font-size: 28px; font-weight: 800;
  display: flex; align-items: center; justify-content: center;
  border: 4px solid #dbeafe; overflow: hidden; flex-shrink: 0;
  transition: border-color 0.2s;
}
/* Highlight ring when a preview is staged */
.avatar-wrapper:has(.preview-badge) .profile-avatar {
  border-color: #fbbf24;
  box-shadow: 0 0 0 3px rgba(251,191,36,0.2);
}
.avatar-img { width: 100%; height: 100%; object-fit: cover; }

/* "Preview" badge sits bottom-right of the avatar */
.preview-badge {
  position: absolute; bottom: 2px; right: -2px;
  background: #fbbf24; color: #78350f;
  font-size: 9px; font-weight: 700; letter-spacing: 0.03em;
  padding: 2px 7px; border-radius: 20px;
  border: 2px solid #fff;
  white-space: nowrap;
}

.upload-actions { display: flex; flex-direction: column; align-items: center; gap: 6px; }

.profile-info { display: flex; flex-direction: column; align-items: center; gap: 8px; }
.profile-name { font-size: 16px; font-weight: 700; color: #1e293b; text-align: center; }
.profile-email { font-size: 12px; color: #64748b; text-align: center; }
.profile-badges { display: flex; gap: 6px; margin-top: 4px; }
.role-badge { background: #eff6ff; color: #2563eb; font-size: 11px; font-weight: 600; padding: 4px 10px; border-radius: 6px; }
.status-badge { font-size: 11px; font-weight: 600; padding: 4px 10px; border-radius: 6px; }
.status-badge.active { background: #f0fdf4; color: #22c55e; }

/* Section titles & footers */
.section-title {
  font-size: 15px; font-weight: 700; color: #1e293b;
  padding-bottom: 12px; border-bottom: 1px solid #f1f5f9;
}
.section-footer { display: flex; justify-content: flex-end; padding-top: 4px; margin-top: auto; }

/* Forms */
.form-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
.form-grid.two-col { grid-template-columns: repeat(2, 1fr); }
.form-field { display: flex; flex-direction: column; gap: 6px; }
.form-field.full-width { grid-column: 1 / -1; }
.form-label { font-size: 12px; font-weight: 600; color: #475569; }
.form-input {
  background: #fff; border: 1px solid #e2e8f0; border-radius: 8px;
  padding: 10px 12px; font-size: 13px; color: #1e293b;
  font-family: inherit; outline: none; transition: all 0.15s; width: 100%;
}
.form-input:focus { border-color: #2563eb; box-shadow: 0 0 0 3px rgba(37,99,235,0.1); }
.form-input:disabled { background: #f8fafc; color: #94a3b8; cursor: not-allowed; }

/* Eye toggle */
.input-eye { position: relative; }
.input-eye .form-input { padding-right: 38px; }
.eye-btn {
  position: absolute; right: 10px; top: 50%; transform: translateY(-50%);
  background: none; border: none; cursor: pointer; color: #94a3b8;
  display: flex; align-items: center; padding: 2px;
}
.eye-btn:hover { color: #475569; }

@media (max-width: 1100px) {
  .profile-grid {
    display: flex;
    flex-direction: column;
    gap: 20px;
  }
  /* Restore from display:contents back to normal flex columns */
  .left-col, .right-col {
    display: flex;
    flex-direction: column;
    gap: 20px;
  }
  .form-grid { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 640px) {
  .form-grid, .form-grid.two-col { grid-template-columns: 1fr; }
}
</style>