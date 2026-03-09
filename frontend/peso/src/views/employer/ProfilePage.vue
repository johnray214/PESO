<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Company Profile</h1>
        <p class="page-sub">Manage your company information and settings</p>
      </div>
    </div>

    <div class="profile-grid">
      <!-- Company Info Card -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Company Information</h3>
          <button class="btn-edit" @click="editing = !editing">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
            {{ editing ? 'Cancel' : 'Edit' }}
          </button>
        </div>
        <div class="form-grid">
          <div class="form-group">
            <label class="form-label">Company Name</label>
            <input v-model="company.name" type="text" class="form-input" :disabled="!editing"/>
          </div>
          <div class="form-group">
            <label class="form-label">Industry</label>
            <input v-model="company.industry" type="text" class="form-input" :disabled="!editing"/>
          </div>
          <div class="form-group">
            <label class="form-label">Email</label>
            <input v-model="company.email" type="email" class="form-input" :disabled="!editing"/>
          </div>
          <div class="form-group">
            <label class="form-label">Contact Number</label>
            <input v-model="company.contact" type="text" class="form-input" :disabled="!editing"/>
          </div>
          <div class="form-group">
            <label class="form-label">Contact Person</label>
            <input v-model="company.contactPerson" type="text" class="form-input" :disabled="!editing"/>
          </div>
          <div class="form-group">
            <label class="form-label">Address</label>
            <input v-model="company.address" type="text" class="form-input" :disabled="!editing"/>
          </div>
        </div>
        <button v-if="editing" class="btn-primary full" @click="saveProfile">Save Changes</button>
      </div>

      <!-- Account Settings Card -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Account Settings</h3>
        </div>
        <div class="form-grid">
          <div class="form-group">
            <label class="form-label">Account Status</label>
            <div class="status-display">
              <span class="status-badge status-active">Active</span>
              <span class="verified-badge">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                Email Verified
              </span>
            </div>
          </div>
          <div class="form-group">
            <label class="form-label">Member Since</label>
            <p class="info-text">January 10, 2023</p>
          </div>
          <div class="form-group">
            <label class="form-label">Total Job Postings</label>
            <p class="info-text">8 active · 12 all-time</p>
          </div>
          <div class="form-group">
            <label class="form-label">Total Hired</label>
            <p class="info-text">45 applicants</p>
          </div>
        </div>
      </div>

      <!-- Change Password Card -->
      <div class="card full-width">
        <div class="card-header">
          <h3 class="card-title">Change Password</h3>
        </div>
        <div class="form-grid">
          <div class="form-group">
            <label class="form-label">Current Password</label>
            <input v-model="password.current" type="password" class="form-input" placeholder="Enter current password"/>
          </div>
          <div class="form-group">
            <label class="form-label">New Password</label>
            <input v-model="password.new" type="password" class="form-input" placeholder="Enter new password"/>
          </div>
          <div class="form-group">
            <label class="form-label">Confirm New Password</label>
            <input v-model="password.confirm" type="password" class="form-input" placeholder="Confirm new password"/>
          </div>
        </div>
        <button class="btn-primary" @click="updatePassword">Update Password</button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'EmployerProfile',
  data() {
    return {
      editing: false,
      company: {
        name: 'Accenture Philippines',
        industry: 'Information Technology',
        email: 'hr@accenture.ph',
        contact: '+63 2 8888 8888',
        contactPerson: 'Maria Santos',
        address: 'BGC, Taguig City',
      },
      password: {
        current: '',
        new: '',
        confirm: '',
      },
    }
  },
  methods: {
    saveProfile() {
      this.editing = false
    },
    updatePassword() {
      this.password = { current: '', new: '', confirm: '' }
    },
  },
}
</script>

<style scoped>
.page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  padding: 24px;
  background: #f8fafc;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
}

.page-title {
  font-size: 20px;
  font-weight: 800;
  color: #1e293b;
}

.page-sub {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 2px;
}

.profile-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 18px;
}

.card {
  background: #fff;
  border-radius: 12px;
  padding: 20px;
  border: 1px solid #f1f5f9;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.card.full-width {
  grid-column: 1 / -1;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.card-title {
  font-size: 15px;
  font-weight: 800;
  color: #1e293b;
}

.btn-edit {
  display: flex;
  align-items: center;
  gap: 5px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 6px 12px;
  font-size: 12px;
  font-weight: 600;
  color: #64748b;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.15s;
}

.btn-edit:hover {
  background: #f1f5f9;
  border-color: #cbd5e1;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 14px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-label {
  font-size: 12px;
  font-weight: 700;
  color: #1e293b;
}

.form-input {
  padding: 10px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-family: inherit;
  color: #1e293b;
  background: #fff;
  transition: all 0.15s;
}

.form-input:disabled {
  background: #f8fafc;
  color: #94a3b8;
  cursor: not-allowed;
}

.form-input:focus {
  outline: none;
  border-color: #2563eb;
}

.btn-primary {
  padding: 10px 16px;
  background: #2563eb;
  color: #fff;
  border: none;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
  transition: background 0.15s;
}

.btn-primary:hover {
  background: #1d4ed8;
}

.btn-primary.full {
  width: 100%;
}

.status-display {
  display: flex;
  gap: 10px;
}

.status-badge {
  padding: 5px 12px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 700;
}

.status-active {
  background: #dcfce7;
  color: #16a34a;
}

.verified-badge {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 5px 10px;
  background: #eff6ff;
  color: #2563eb;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
}

.info-text {
  font-size: 13px;
  color: #64748b;
  font-weight: 500;
}
</style>
