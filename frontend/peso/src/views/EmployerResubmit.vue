<template>
  <div class="auth-wrapper">

    <!-- LEFT PANEL -->
    <div class="left-panel">
      <div class="orb orb1"></div>
      <div class="orb orb2"></div>
      <div class="orb orb3"></div>

      <div class="panel-top">
        <div class="brand">
          <div class="brand-mark">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.5">
              <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/>
              <circle cx="9" cy="7" r="4"/>
              <path d="M23 21v-2a4 4 0 00-3-3.87"/>
              <path d="M16 3.13a4 4 0 010 7.75"/>
            </svg>
          </div>
          <div>
            <span class="brand-name">PESO Santiago</span>
            <span class="brand-tag">Employer Portal</span>
          </div>
        </div>

        <div class="panel-headline-wrap">
          <h1 class="panel-headline">
            Resubmit your<br/><span class="sky">documents</span>
          </h1>
          <p class="panel-sub">
            Your account was rejected. Upload fresh, valid copies of your Business Permit and BIR Certificate to request re-verification by our PESO staff.
          </p>
        </div>

        <div class="steps-wrap">
          <div class="step" :class="{ 'step-done': step > 1, 'step-active': step === 1 }">
            <div class="step-circle">
              <svg v-if="step > 1" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
              <span v-else>1</span>
            </div>
            <div class="step-text">
              <span class="step-label">Verify identity</span>
              <span class="step-hint">Enter your login credentials</span>
            </div>
          </div>
          <div class="step-connector"></div>
          <div class="step" :class="{ 'step-done': step > 2, 'step-active': step === 2 }">
            <div class="step-circle">
              <svg v-if="step > 2" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
              <span v-else>2</span>
            </div>
            <div class="step-text">
              <span class="step-label">Upload documents</span>
              <span class="step-hint">Business permit & BIR certificate</span>
            </div>
          </div>
          <div class="step-connector"></div>
          <div class="step" :class="{ 'step-done': step > 3, 'step-active': step === 3 }">
            <div class="step-circle">
              <svg v-if="step > 3" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
              <span v-else>3</span>
            </div>
            <div class="step-text">
              <span class="step-label">Submitted</span>
              <span class="step-hint">Awaiting PESO re-verification</span>
            </div>
          </div>
        </div>
      </div>

      <div class="panel-note">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
        Accepted formats: PDF, JPG, JPEG, PNG · Max 2 MB each
      </div>
    </div>

    <!-- RIGHT PANEL -->
    <div class="right-panel">
      <div class="auth-box">

        <!-- SUCCESS STATE -->
        <div v-if="submitted" class="success-card">
          <div class="success-icon">
            <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
          </div>
          <h2 class="success-title">Documents Submitted!</h2>
          <p class="success-text">
            Your documents have been resubmitted successfully. Our PESO staff will review them and notify you by email once a decision is made.
          </p>
          <router-link to="/employer/login" class="btn-submit" style="display:inline-flex;margin-top:8px;text-decoration:none;justify-content:center;">
            ← Back to Login
          </router-link>
        </div>

        <!-- STEP 1 — Verify Credentials -->
        <form v-else-if="step === 1" @submit.prevent="verifyCredentials">
          <div class="form-header">
            <h2 class="form-title">Verify your identity</h2>
            <p class="form-sub">Enter your account credentials to continue.</p>
          </div>

          <div v-if="error" class="error-box">{{ error }}</div>

          <div class="form-group">
            <label class="form-label">Email Address</label>
            <div class="input-wrap">
              <span class="input-icon">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                  <polyline points="22,6 12,13 2,6"/>
                </svg>
              </span>
              <input class="form-input" type="email" v-model="form.email" placeholder="you@company.com" required/>
            </div>
          </div>

          <div class="form-group">
            <label class="form-label">Password</label>
            <div class="input-wrap">
              <span class="input-icon">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect x="3" y="11" width="18" height="11" rx="2"/>
                  <path d="M7 11V7a5 5 0 0110 0v4"/>
                </svg>
              </span>
              <input
                class="form-input"
                :type="showPw ? 'text' : 'password'"
                v-model="form.password"
                placeholder="••••••••"
                required
              />
              <button class="pw-toggle" @click="showPw = !showPw" type="button">👁</button>
            </div>
          </div>

          <button class="btn-submit" type="submit" :disabled="loading">
            <span v-if="loading" style="display:flex;align-items:center;gap:8px;">
              <span class="spinner"></span>Verifying…
            </span>
            <span v-else>Continue →</span>
          </button>

          <p class="switch-link">
            Remember your password?
            <router-link to="/employer/login">Back to login</router-link>
          </p>
        </form>

        <!-- STEP 2 — Upload Documents -->
        <form v-else-if="step === 2" @submit.prevent="submitDocuments">
          <div class="form-header">
            <h2 class="form-title">Upload new documents</h2>
            <p class="form-sub">At least one document is required. Upload both for faster approval.</p>
          </div>

          <div v-if="error" class="error-box">{{ error }}</div>

          <!-- Biz Permit -->
          <div class="form-group">
            <label class="form-label">Business Permit</label>
            <div
              class="drop-zone"
              :class="{ 'drop-zone--active': dragOver.biz, 'drop-zone--filled': files.biz_permit }"
              @dragover.prevent="dragOver.biz = true"
              @dragleave="dragOver.biz = false"
              @drop.prevent="onDrop($event, 'biz_permit')"
              @click="$refs.bizInput.click()"
            >
              <input ref="bizInput" type="file" accept=".pdf,.jpg,.jpeg,.png" style="display:none" @change="onFileChange($event, 'biz_permit')"/>
              <div v-if="!files.biz_permit" class="drop-placeholder">
                <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
                <span>Drag & drop or <strong>click to browse</strong></span>
                <span class="drop-hint">PDF, JPG, PNG · max 2 MB</span>
              </div>
              <div v-else class="drop-filled">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                <span>{{ files.biz_permit.name }}</span>
                <button type="button" class="remove-file" @click.stop="files.biz_permit = null">✕</button>
              </div>
            </div>
          </div>

          <!-- BIR Cert -->
          <div class="form-group">
            <label class="form-label">BIR Certificate (optional)</label>
            <div
              class="drop-zone"
              :class="{ 'drop-zone--active': dragOver.bir, 'drop-zone--filled': files.bir_cert }"
              @dragover.prevent="dragOver.bir = true"
              @dragleave="dragOver.bir = false"
              @drop.prevent="onDrop($event, 'bir_cert')"
              @click="$refs.birInput.click()"
            >
              <input ref="birInput" type="file" accept=".pdf,.jpg,.jpeg,.png" style="display:none" @change="onFileChange($event, 'bir_cert')"/>
              <div v-if="!files.bir_cert" class="drop-placeholder">
                <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
                <span>Drag & drop or <strong>click to browse</strong></span>
                <span class="drop-hint">PDF, JPG, PNG · max 2 MB</span>
              </div>
              <div v-else class="drop-filled">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                <span>{{ files.bir_cert.name }}</span>
                <button type="button" class="remove-file" @click.stop="files.bir_cert = null">✕</button>
              </div>
            </div>
          </div>

          <div style="display:flex;gap:10px;margin-top:4px;">
            <button type="button" class="btn-back" @click="step = 1">← Back</button>
            <button class="btn-submit" type="submit" :disabled="loading || (!files.biz_permit && !files.bir_cert)" style="flex:1">
              <span v-if="loading" style="display:flex;align-items:center;gap:8px;">
                <span class="spinner"></span>Submitting…
              </span>
              <span v-else>Submit for Re-verification</span>
            </button>
          </div>
        </form>

      </div>
    </div>
  </div>
</template>

<script>
import api from '@/services/api'

export default {
  name: 'EmployerResubmit',

  data() {
    return {
      step: 1,
      submitted: false,
      loading: false,
      error: '',
      showPw: false,

      form: {
        email: '',
        password: '',
      },

      files: {
        biz_permit: null,
        bir_cert:   null,
      },

      dragOver: {
        biz: false,
        bir: false,
      },
    }
  },

  methods: {
    async verifyCredentials() {
      if (!this.form.email || !this.form.password) {
        this.error = 'Please enter your email and password.'
        return
      }

      this.error   = ''
      this.loading = true

      try {
        // Use the login endpoint to verify credentials.
        // A rejected account returns HTTP 403 with status:'rejected' — that confirms identity
        // without touching the database (the resubmit endpoint would reset status prematurely).
        await api.post('/employer/login', {
          email:    this.form.email,
          password: this.form.password,
        })

        // If somehow the account is verified/approved, don't let them resubmit
        this.error = 'Your account is already verified. Please log in normally.'
      } catch (err) {
        const httpStatus   = err?.response?.status
        const accountStatus = err?.response?.data?.status || ''
        const msg           = err?.response?.data?.message || ''

        if (httpStatus === 401) {
          this.error = 'Invalid email or password. Please try again.'
        } else if (httpStatus === 403 && accountStatus === 'rejected') {
          // ✅ Correct state — credentials valid, account is rejected → proceed
          this.step = 2
        } else if (httpStatus === 403 && accountStatus === 'pending') {
          this.error = 'Your account is pending verification, not rejected. No resubmission needed.'
        } else if (httpStatus === 403 && accountStatus === 'suspended') {
          this.error = 'Your account has been suspended. Please contact PESO directly.'
        } else {
          this.error = msg || 'Unable to verify credentials. Please try again.'
        }
      } finally {
        this.loading = false
      }
    },

    onFileChange(e, field) {
      const file = e.target.files[0]
      if (file) this.files[field] = file
    },

    onDrop(e, field) {
      const file = e.dataTransfer.files[0]
      if (file) this.files[field] = file
      this.dragOver.biz = false
      this.dragOver.bir = false
    },

    async submitDocuments() {
      if (!this.files.biz_permit && !this.files.bir_cert) {
        this.error = 'Please upload at least one document.'
        return
      }

      this.error   = ''
      this.loading = true

      try {
        const fd = new FormData()
        fd.append('email',    this.form.email)
        fd.append('password', this.form.password)
        if (this.files.biz_permit) fd.append('biz_permit', this.files.biz_permit)
        if (this.files.bir_cert)   fd.append('bir_cert',   this.files.bir_cert)

        await api.post('/employer/resubmit', fd, {
          headers: { 'Content-Type': 'multipart/form-data' },
        })

        this.submitted = true
        this.step      = 3
      } catch (err) {
        const status = err?.response?.status
        const msg    = err?.response?.data?.message || 'Submission failed. Please try again.'
        if (status === 401) {
          this.error = 'Session expired. Please go back and re-enter your credentials.'
          this.step  = 1
        } else {
          this.error = msg
        }
      } finally {
        this.loading = false
      }
    },
  },
}
</script>

<style>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800;900&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

.auth-wrapper {
  font-family: 'Plus Jakarta Sans', sans-serif;
  display: flex;
  min-height: 100vh;
  overflow: hidden;
}

/* ── LEFT PANEL ── */
.left-panel {
  width: 46%;
  min-height: 100vh;
  background: linear-gradient(145deg, #0f172a 0%, #1a3a5c 55%, #0e4d6e 100%);
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 44px 52px;
  overflow: hidden;
  flex-shrink: 0;
}
.left-panel::before {
  content: '';
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(8,189,222,0.07) 1px, transparent 1px),
    linear-gradient(90deg, rgba(8,189,222,0.07) 1px, transparent 1px);
  background-size: 44px 44px;
}
.orb { position: absolute; border-radius: 50%; filter: blur(80px); pointer-events: none; }
.orb1 { width: 380px; height: 380px; background: #2872A1; opacity: 0.25; top: -80px; right: -80px; }
.orb2 { width: 280px; height: 280px; background: #08BDDE; opacity: 0.18; bottom: -60px; left: -60px; }
.orb3 { width: 200px; height: 200px; background: #0ea5e9; opacity: 0.12; top: 50%; left: 50%; transform: translate(-50%, -50%); }

.panel-top { position: relative; z-index: 1; display: flex; flex-direction: column; gap: 36px; }

.brand { display: flex; align-items: center; gap: 12px; }
.brand-mark {
  width: 44px; height: 44px; border-radius: 13px;
  background: linear-gradient(135deg, #2872A1, #08BDDE);
  display: flex; align-items: center; justify-content: center;
  box-shadow: 0 4px 16px rgba(8,189,222,0.35); flex-shrink: 0;
}
.brand-name { font-size: 18px; font-weight: 900; color: #fff; letter-spacing: 0.07em; display: block; line-height: 1; }
.brand-tag  { font-size: 10px; font-weight: 600; color: rgba(8,189,222,0.85); display: block; margin-top: 2px; letter-spacing: 0.04em; }

.panel-headline { font-size: 38px; font-weight: 900; color: #fff; line-height: 1.15; letter-spacing: -0.025em; margin-bottom: 14px; }
.panel-headline .sky {
  background: linear-gradient(90deg, #08BDDE, #38bdf8);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;
}
.panel-sub { font-size: 14px; color: rgba(255,255,255,0.52); line-height: 1.7; }

/* Steps */
.steps-wrap { display: flex; flex-direction: column; gap: 0; }
.step { display: flex; align-items: flex-start; gap: 14px; padding: 10px 0; }
.step-connector { width: 2px; height: 20px; background: rgba(255,255,255,0.12); margin-left: 15px; }
.step-circle {
  width: 32px; height: 32px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 13px; font-weight: 800;
  background: rgba(255,255,255,0.1);
  border: 2px solid rgba(255,255,255,0.15);
  color: rgba(255,255,255,0.4);
  flex-shrink: 0; transition: all 0.3s;
}
.step-active .step-circle {
  background: linear-gradient(135deg, #2872A1, #08BDDE);
  border-color: transparent;
  color: #fff;
  box-shadow: 0 4px 12px rgba(8,189,222,0.4);
}
.step-done .step-circle {
  background: rgba(34,197,94,0.2);
  border-color: #22c55e;
  color: #22c55e;
}
.step-text { display: flex; flex-direction: column; padding-top: 4px; }
.step-label { font-size: 13px; font-weight: 700; color: rgba(255,255,255,0.7); }
.step-active .step-label { color: #fff; }
.step-done  .step-label  { color: #4ade80; }
.step-hint  { font-size: 11px; color: rgba(255,255,255,0.35); margin-top: 1px; }

.panel-note {
  position: relative; z-index: 1;
  display: flex; align-items: center; gap: 8px;
  font-size: 11.5px; color: rgba(255,255,255,0.35);
}

/* ── RIGHT PANEL ── */
.right-panel {
  flex: 1; display: flex; align-items: center; justify-content: center;
  padding: 48px 52px; overflow-y: auto; background: #f8fafc;
}
.auth-box { width: 100%; max-width: 440px; }

.form-header { margin-bottom: 28px; }
.form-title { font-size: 26px; font-weight: 900; color: #0f172a; letter-spacing: -0.02em; margin-bottom: 6px; }
.form-sub { font-size: 13.5px; color: #64748b; line-height: 1.6; }

.error-box {
  background: #fef2f2; border: 1px solid #fecaca; border-radius: 10px;
  padding: 10px 14px; font-size: 13px; color: #dc2626; margin-bottom: 16px;
}

/* fields */
.form-group { margin-bottom: 14px; display: flex; flex-direction: column; gap: 6px; }
.form-label { font-size: 11.5px; font-weight: 700; color: #475569; text-transform: uppercase; letter-spacing: 0.06em; }
.input-wrap { position: relative; }
.input-icon {
  position: absolute; left: 13px; top: 50%; transform: translateY(-50%);
  color: #94a3b8; pointer-events: none; display: flex;
}
.form-input {
  width: 100%; padding: 11px 14px 11px 40px;
  border: 1.5px solid #e2e8f0; border-radius: 10px;
  font-family: 'Plus Jakarta Sans', sans-serif; font-size: 13.5px; color: #1e293b;
  background: #fff; outline: none; transition: border 0.15s, box-shadow 0.15s;
}
.form-input:focus { border-color: #08BDDE; box-shadow: 0 0 0 3px rgba(8,189,222,0.1); }
.form-input::placeholder { color: #cbd5e1; }
.pw-toggle {
  position: absolute; right: 13px; top: 50%; transform: translateY(-50%);
  background: none; border: none; cursor: pointer; color: #94a3b8; padding: 2px;
  display: flex; align-items: center;
}

/* Drop zone */
.drop-zone {
  border: 2px dashed #cbd5e1; border-radius: 12px;
  padding: 24px 20px; cursor: pointer; transition: all 0.2s;
  background: #fff;
  display: flex; align-items: center; justify-content: center;
}
.drop-zone:hover, .drop-zone--active {
  border-color: #08BDDE;
  background: rgba(8,189,222,0.04);
}
.drop-zone--filled {
  border-color: #22c55e;
  background: rgba(34,197,94,0.04);
}
.drop-placeholder {
  display: flex; flex-direction: column; align-items: center; gap: 6px;
  color: #94a3b8; font-size: 13px; text-align: center;
}
.drop-placeholder strong { color: #0f172a; }
.drop-hint { font-size: 11px; color: #cbd5e1; }
.drop-filled {
  display: flex; align-items: center; gap: 10px;
  font-size: 13px; color: #166534; font-weight: 600;
  width: 100%; overflow: hidden;
}
.drop-filled span { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.remove-file {
  background: none; border: none; cursor: pointer; color: #94a3b8;
  font-size: 14px; padding: 2px 4px; flex-shrink: 0;
}
.remove-file:hover { color: #dc2626; }

/* Buttons */
.btn-submit {
  width: 100%; padding: 13px; margin-top: 20px;
  background: linear-gradient(135deg, #2872A1, #08BDDE);
  color: #fff; border: none; border-radius: 10px;
  font-family: 'Plus Jakarta Sans', sans-serif; font-size: 14px; font-weight: 700;
  cursor: pointer; transition: all 0.2s;
  box-shadow: 0 4px 16px rgba(40,114,161,0.35);
  display: flex; align-items: center; justify-content: center; gap: 8px;
}
.btn-submit:hover:not(:disabled) { transform: translateY(-1px); box-shadow: 0 8px 24px rgba(40,114,161,0.45); }
.btn-submit:disabled { opacity: 0.6; cursor: not-allowed; }

.btn-back {
  padding: 13px 20px; margin-top: 20px;
  background: #f1f5f9; color: #475569;
  border: 1.5px solid #e2e8f0; border-radius: 10px;
  font-family: 'Plus Jakarta Sans', sans-serif; font-size: 14px; font-weight: 600;
  cursor: pointer; transition: all 0.2s;
}
.btn-back:hover { background: #e2e8f0; }

.switch-link { text-align: center; margin-top: 20px; font-size: 13px; color: #64748b; }
.switch-link a { color: #2872A1; font-weight: 700; text-decoration: none; }
.switch-link a:hover { text-decoration: underline; }

/* Spinner */
.spinner {
  width: 14px; height: 14px;
  border: 2px solid rgba(255,255,255,0.4);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
  display: inline-block;
}
@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }

/* Success card */
.success-card {
  display: flex; flex-direction: column; align-items: center;
  gap: 16px; text-align: center; padding: 20px 0;
}
.success-icon {
  width: 72px; height: 72px; border-radius: 50%;
  background: linear-gradient(135deg, #16a34a, #22c55e);
  display: flex; align-items: center; justify-content: center;
  box-shadow: 0 8px 24px rgba(34,197,94,0.35);
}
.success-title { font-size: 26px; font-weight: 900; color: #0f172a; letter-spacing: -0.02em; }
.success-text { font-size: 14px; color: #64748b; line-height: 1.7; max-width: 340px; }
</style>
