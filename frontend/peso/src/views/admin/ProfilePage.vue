<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Profile</h1>
        <p class="page-sub">Manage your account settings and preferences</p>
      </div>
      <button class="btn-primary" @click="saveProfile">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg>
        Save Changes
      </button>
    </div>

    <div class="profile-grid">
      <!-- Profile Card -->
      <div class="profile-card">
        <div class="profile-avatar-section">
          <div class="profile-avatar">
            <span>{{ user.firstName[0] }}{{ user.lastName[0] }}</span>
          </div>
          <button class="upload-btn">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
            Upload Photo
          </button>
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
              <option value="Male">Male</option>
              <option value="Female">Female</option>
            </select>
          </div>
          <div class="form-field full-width">
            <label class="form-label">Address</label>
            <input v-model="user.address" type="text" class="form-input" />
          </div>
        </div>
      </div>

      <!-- Account Settings -->
      <div class="section-card">
        <h3 class="section-title">Account Settings</h3>
        <div class="form-grid">
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
      </div>

      <!-- Change Password -->
      <div class="section-card">
        <h3 class="section-title">Change Password</h3>
        <div class="form-grid">
          <div class="form-field">
            <label class="form-label">Current Password</label>
            <input v-model="password.current" type="password" class="form-input" placeholder="Enter current password" />
          </div>
          <div class="form-field">
            <label class="form-label">New Password</label>
            <input v-model="password.new" type="password" class="form-input" placeholder="Enter new password" />
          </div>
          <div class="form-field">
            <label class="form-label">Confirm Password</label>
            <input v-model="password.confirm" type="password" class="form-input" placeholder="Confirm new password" />
          </div>
        </div>
        <button class="btn-secondary" @click="updatePassword">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
          Update Password
        </button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ProfilePage',
  data() {
    return {
      user: {
        firstName: 'Maria',
        middleName: 'Cruz',
        lastName: 'Santos',
        email: 'maria.santos@peso.gov.ph',
        role: 'Admin',
        sex: 'Female',
        number: '09171234567',
        address: 'Quezon City',
        status: 'Active',
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
      alert('Profile updated successfully!')
    },
    updatePassword() {
      if (!this.password.current || !this.password.new || !this.password.confirm) {
        alert('Please fill all password fields')
        return
      }
      if (this.password.new !== this.password.confirm) {
        alert('Passwords do not match')
        return
      }
      alert('Password updated successfully!')
      this.password = { current: '', new: '', confirm: '' }
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

.page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  padding: 24px;
  background: #f8fafc;
  min-height: 0;
  display: flex;
  flex-direction: column;
  gap: 20px;
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

.btn-primary {
  display: flex;
  align-items: center;
  gap: 6px;
  background: #2563eb;
  color: #fff;
  border: none;
  border-radius: 10px;
  padding: 10px 18px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
  transition: background 0.15s;
}

.btn-primary:hover {
  background: #1d4ed8;
}

.btn-secondary {
  display: flex;
  align-items: center;
  gap: 6px;
  background: #fff;
  color: #475569;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 9px 16px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.15s;
  margin-top: 12px;
}

.btn-secondary:hover {
  background: #f8fafc;
  border-color: #cbd5e1;
}

.profile-grid {
  display: grid;
  grid-template-columns: 300px 1fr;
  gap: 20px;
}

.profile-card {
  background: #fff;
  border: 1px solid #f1f5f9;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.profile-avatar-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

.profile-avatar {
  width: 90px;
  height: 90px;
  border-radius: 50%;
  background: linear-gradient(135deg, #2563eb, #3b82f6);
  color: #fff;
  font-size: 28px;
  font-weight: 800;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 4px solid #dbeafe;
}

.upload-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 7px 14px;
  font-size: 12px;
  font-weight: 600;
  color: #475569;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.15s;
}

.upload-btn:hover {
  background: #f1f5f9;
  border-color: #cbd5e1;
}

.profile-info {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.profile-name {
  font-size: 16px;
  font-weight: 700;
  color: #1e293b;
  text-align: center;
}

.profile-email {
  font-size: 12px;
  color: #64748b;
  text-align: center;
}

.profile-badges {
  display: flex;
  gap: 6px;
  margin-top: 4px;
}

.role-badge {
  background: #eff6ff;
  color: #2563eb;
  font-size: 11px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 6px;
}

.status-badge {
  font-size: 11px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 6px;
}

.status-badge.active {
  background: #f0fdf4;
  color: #22c55e;
}

.section-card {
  background: #fff;
  border: 1px solid #f1f5f9;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.section-title {
  font-size: 15px;
  font-weight: 700;
  color: #1e293b;
  padding-bottom: 12px;
  border-bottom: 1px solid #f1f5f9;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}

.form-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-field.full-width {
  grid-column: 1 / -1;
}

.form-label {
  font-size: 12px;
  font-weight: 600;
  color: #475569;
}

.form-input {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 12px;
  font-size: 13px;
  color: #1e293b;
  font-family: inherit;
  outline: none;
  transition: all 0.15s;
}

.form-input:focus {
  border-color: #2563eb;
  box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
}

.form-input:disabled {
  background: #f8fafc;
  color: #94a3b8;
  cursor: not-allowed;
}

@media (max-width: 1200px) {
  .profile-grid {
    grid-template-columns: 1fr;
  }
  .form-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .form-grid {
    grid-template-columns: 1fr;
  }
}
</style>
