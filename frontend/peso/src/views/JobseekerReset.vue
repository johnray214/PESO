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
            <span class="brand-name">PESO Connect</span>
            <span class="brand-tag">Jobseeker Portal</span>
          </div>
        </div>

        <div class="panel-text">
          <h1 class="panel-headline">Create your new<br/><span class="sky">secure password.</span></h1>
          <p class="panel-sub">Make sure it's strong and something you haven't used before to protect your account.</p>
        </div>

        <!-- Steps visual -->
        <div class="recovery-steps">
          <div v-for="(s, i) in recoverySteps" :key="s.title"
            class="rec-step"
            :class="{ active: step >= i + 1, done: step > i + 1 }"
          >
            <div class="rec-dot">
              <svg v-if="step > i + 1" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
              <span v-else>{{ i + 1 }}</span>
            </div>
            <div class="rec-info">
              <p class="rec-title">{{ s.title }}</p>
              <p class="rec-sub">{{ s.sub }}</p>
            </div>
            <div v-if="i < recoverySteps.length - 1" class="rec-connector"></div>
          </div>
        </div>
      </div>

      <!-- Bottom card -->
      <div class="panel-card">
        <div class="pc-icon">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#08BDDE" stroke-width="2">
            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
          </svg>
        </div>
        <div>
          <p class="pc-heading">Your account is safe</p>
          <p class="pc-desc">The secure reset link is verified. Changing your password forces a secure logout across all your devices.</p>
        </div>
      </div>
    </div>

    <!-- RIGHT PANEL -->
    <div class="right-panel">
      <div class="auth-box">

        <!-- ── STEP 1: Enter New Password ── -->
        <transition name="slide-fade" mode="out-in">
          <div v-if="step === 1" key="step1">
            <div class="back-link" @click="$router.push('/jobseeker/login')">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="15 18 9 12 15 6"/></svg>
              Back to Sign In
            </div>

            <div class="form-header">
              <div class="step-icon-wrap blue">
                <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2">
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                  <path d="M7 11V7a5 5 0 0110 0v4"/>
                </svg>
              </div>
              <h2 class="form-title">Reset password</h2>
              <p class="form-sub">Enter a new password for {{ email }} below to regain access.</p>
            </div>

            <div class="form-group">
              <label class="form-label">New Password</label>
              <div class="input-wrap" :class="{ 'input-error': error }">
                <span class="input-icon">
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
                </span>
                <input
                  class="form-input"
                  :type="showPassword ? 'text' : 'password'"
                  v-model="password"
                  placeholder="At least 8 characters"
                  @keyup.enter="handleReset"
                />
                <div class="pass-toggle" @click="showPassword = !showPassword">
                  <svg v-if="showPassword" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                  </svg>
                  <svg v-else width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/>
                  </svg>
                </div>
              </div>
            </div>

            <div class="form-group">
              <label class="form-label">Confirm Password</label>
              <div class="input-wrap" :class="{ 'input-error': error }">
                <span class="input-icon">
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
                </span>
                <input
                  class="form-input"
                  :type="showPassword ? 'text' : 'password'"
                  v-model="password_confirmation"
                  placeholder="Repeat your new password"
                  @keyup.enter="handleReset"
                />
              </div>
              <p v-if="error" class="field-error">{{ error }}</p>
            </div>

            <button class="btn-submit" @click="handleReset" :disabled="!password || !password_confirmation || password.length < 8" :class="{ loading: submitting }">
              <span v-if="!submitting" class="btn-content">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
                Save new password
              </span>
              <span v-else class="btn-content">
                <span class="spinner"></span>
                Saving...
              </span>
            </button>
          </div>

          <!-- ── STEP 2: Password Changed Successfully ── -->
          <div v-else-if="step === 2" key="step2">
            <div class="success-state">
              <div class="success-ring">
                <div class="success-circle">
                  <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                </div>
              </div>

              <h2 class="form-title" style="text-align:center;">Password Updated!</h2>
              <p class="form-sub" style="text-align:center;">Your password has been successfully reset. You can now use your new password to log in to your account.</p>

              <router-link to="/jobseeker/login" class="btn-submit" style="margin-top:20px; text-decoration: none;">
                Sign in to Dashboard
              </router-link>
            </div>
          </div>
        </transition>

      </div>
    </div>

  </div>
</template>

<script>
import api from '@/services/api'

export default {
  name: 'JobseekerReset',
  data() {
    return {
      step: 1,
      email: this.$route.query.email || '',
      token: this.$route.query.token || '',
      password: '',
      password_confirmation: '',
      error: '',
      submitting: false,
      showPassword: false,
      recoverySteps: [
        { title: 'Click reset link',   sub: 'Verified from your email' },
        { title: 'New password',       sub: 'Create a new secure key' },
        { title: 'Access account',     sub: 'Sign in to PESO Connect' },
      ],
    }
  },
  mounted() {
    if (!this.email || !this.token) {
      this.error = 'Invalid or missing password reset token.'
    }
  },
  methods: {
    async handleReset() {
      if (!this.password || !this.password_confirmation || this.password !== this.password_confirmation) {
          this.error = 'Passwords do not match.'
          return
      }
      if (this.password.length < 8) {
          this.error = 'Password must be at least 8 characters long.'
          return
      }

      this.submitting = true
      this.error = ''

      try {
        await api.post('/jobseeker/reset-password', { 
            email: this.email,
            token: this.token,
            password: this.password,
            password_confirmation: this.password_confirmation
        })
        this.step = 2
      } catch (e) {
        this.error = e.response?.data?.message || 'The reset link has expired or is invalid.'
      } finally {
        this.submitting = false
      }
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800;900&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

.auth-wrapper {
  font-family: 'Plus Jakarta Sans', sans-serif;
  display: flex;
  min-height: 100vh;
  overflow: hidden;
}

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
  position: absolute; inset: 0;
  background-image:
    linear-gradient(rgba(8,189,222,0.07) 1px, transparent 1px),
    linear-gradient(90deg, rgba(8,189,222,0.07) 1px, transparent 1px);
  background-size: 44px 44px;
}
.orb { position: absolute; border-radius: 50%; filter: blur(80px); pointer-events: none; }
.orb1 { width: 360px; height: 360px; background: #2872A1; opacity: 0.22; top: -80px; right: -80px; }
.orb2 { width: 260px; height: 260px; background: #08BDDE; opacity: 0.16; bottom: -60px; left: -60px; }
.orb3 { width: 180px; height: 180px; background: #0ea5e9; opacity: 0.1; top: 50%; left: 50%; transform: translate(-50%, -50%); }

.panel-top { position: relative; z-index: 1; display: flex; flex-direction: column; gap: 36px; }

.brand { display: flex; align-items: center; gap: 12px; }
.brand-mark {
  width: 44px; height: 44px; border-radius: 13px;
  background: linear-gradient(135deg, #2872A1, #08BDDE);
  display: flex; align-items: center; justify-content: center;
  box-shadow: 0 4px 16px rgba(8,189,222,0.35); flex-shrink: 0;
}
.brand-name { font-size: 18px; font-weight: 900; color: #fff; letter-spacing: 0.07em; display: block; line-height: 1; }
.brand-tag  { font-size: 10px; font-weight: 600; color: rgba(8,189,222,0.85); display: block; margin-top: 2px; }

.panel-headline { font-size: 36px; font-weight: 900; color: #fff; line-height: 1.15; letter-spacing: -0.025em; margin-bottom: 12px; }
.panel-headline .sky {
  background: linear-gradient(90deg, #08BDDE, #38bdf8);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;
}
.panel-sub { font-size: 13.5px; color: rgba(255,255,255,0.5); line-height: 1.7; }

.recovery-steps {
  background: rgba(255,255,255,0.05);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 16px; padding: 20px 22px;
  display: flex; flex-direction: column; gap: 0;
}
.rec-step {
  display: flex; align-items: flex-start; gap: 14px;
  padding: 10px 0; opacity: 0.4;
  position: relative; transition: opacity 0.3s;
}
.rec-step.active { opacity: 1; }
.rec-step.done   { opacity: 0.6; }
.rec-dot {
  width: 28px; height: 28px; border-radius: 50%; flex-shrink: 0;
  background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.15);
  display: flex; align-items: center; justify-content: center;
  font-size: 11px; font-weight: 800; color: rgba(255,255,255,0.5);
  transition: all 0.3s; margin-top: 2px;
}
.rec-step.active .rec-dot {
  background: linear-gradient(135deg, #2872A1, #08BDDE);
  border-color: #08BDDE; color: #fff;
  box-shadow: 0 0 0 4px rgba(8,189,222,0.2);
}
.rec-step.done .rec-dot { background: rgba(34,197,94,0.2); border-color: rgba(34,197,94,0.5); color: #4ade80; }
.rec-title { font-size: 12.5px; font-weight: 700; color: #f1f5f9; }
.rec-sub   { font-size: 11px; color: rgba(255,255,255,0.4); margin-top: 2px; }
.rec-connector {
  position: absolute; left: 13px; bottom: 0; top: 38px;
  width: 2px; background: rgba(255,255,255,0.08); border-radius: 99px;
}
.rec-step.done .rec-connector { background: rgba(34,197,94,0.3); }

.panel-card {
  position: relative; z-index: 1;
  background: rgba(255,255,255,0.06);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 16px; padding: 20px 22px;
  display: flex; align-items: flex-start; gap: 14px;
  backdrop-filter: blur(8px);
}
.pc-icon {
  width: 44px; height: 44px; border-radius: 12px;
  background: rgba(8,189,222,0.1); border: 1px solid rgba(8,189,222,0.2);
  display: flex; align-items: center; justify-content: center; flex-shrink: 0;
}
.pc-heading { font-size: 13px; font-weight: 700; color: #f1f5f9; margin-bottom: 5px; }
.pc-desc    { font-size: 12px; color: rgba(255,255,255,0.45); line-height: 1.6; }

/* ── RIGHT PANEL ── */
.right-panel {
  flex: 1; display: flex; align-items: center; justify-content: center;
  padding: 48px 52px; overflow-y: auto; background: #f8fafc;
}
.auth-box { width: 100%; max-width: 440px; }

.back-link {
  display: inline-flex; align-items: center; gap: 6px;
  font-size: 13px; font-weight: 600; color: #64748b;
  cursor: pointer; margin-bottom: 28px;
  transition: color 0.15s, gap 0.15s;
}
.back-link:hover { color: #2872A1; gap: 8px; }

.step-icon-wrap {
  width: 56px; height: 56px; border-radius: 16px;
  display: flex; align-items: center; justify-content: center;
  margin-bottom: 18px;
}
.step-icon-wrap.blue { background: #eff8ff; border: 1px solid #bae6fd; }

.form-header { margin-bottom: 28px; }
.form-title { font-size: 26px; font-weight: 900; color: #0f172a; letter-spacing: -0.02em; margin-bottom: 8px; }
.form-sub   { font-size: 13.5px; color: #64748b; line-height: 1.65; }

.form-group { margin-bottom: 14px; display: flex; flex-direction: column; gap: 6px; }
.form-label { font-size: 11.5px; font-weight: 700; color: #475569; text-transform: uppercase; letter-spacing: 0.06em; }
.input-wrap { position: relative; }
.input-icon {
  position: absolute; left: 13px; top: 50%; transform: translateY(-50%);
  color: #94a3b8; pointer-events: none; display: flex;
}
.pass-toggle {
  position: absolute; right: 13px; top: 50%; transform: translateY(-50%);
  color: #94a3b8; cursor: pointer; display: flex;
}
.form-input {
  width: 100%; padding: 11px 40px 11px 40px;
  border: 1.5px solid #e2e8f0; border-radius: 10px;
  font-family: 'Plus Jakarta Sans', sans-serif; font-size: 13.5px; color: #1e293b;
  background: #fff; outline: none; transition: border 0.15s, box-shadow 0.15s;
}
.form-input:focus { border-color: #08BDDE; box-shadow: 0 0 0 3px rgba(8,189,222,0.1); }
.form-input::placeholder { color: #cbd5e1; }
.input-error .form-input  { border-color: #fca5a5; box-shadow: 0 0 0 3px rgba(239,68,68,0.08); }
.field-error { font-size: 12px; color: #ef4444; font-weight: 500; display: flex; align-items: center; gap: 5px; margin-top: 4px; }

.btn-submit {
  width: 100%; padding: 13px;
  background: linear-gradient(135deg, #2872A1, #08BDDE);
  color: #fff; border: none; border-radius: 10px;
  font-family: 'Plus Jakarta Sans', sans-serif; font-size: 14px; font-weight: 700;
  cursor: pointer; transition: all 0.2s;
  box-shadow: 0 4px 16px rgba(40,114,161,0.35);
  display: flex; align-items: center; justify-content: center;
  margin-top: 24px;
}
.btn-submit:hover:not(:disabled) { transform: translateY(-1px); box-shadow: 0 8px 24px rgba(40,114,161,0.45); }
.btn-submit:disabled { opacity: 0.55; cursor: not-allowed; transform: none; box-shadow: none; }
.btn-content { display: flex; align-items: center; gap: 8px; }

.spinner {
  width: 16px; height: 16px; border-radius: 50%;
  border: 2px solid rgba(255,255,255,0.35);
  border-top-color: #fff;
  animation: spin 0.7s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }

/* ── SUCCESS STATE ── */
.success-state { display: flex; flex-direction: column; align-items: center; gap: 14px; }

.success-ring {
  width: 88px; height: 88px; border-radius: 50%;
  background: rgba(34,197,94,0.1);
  display: flex; align-items: center; justify-content: center;
  animation: ringPop 0.5s cubic-bezier(.22,.68,0,1.4) both;
}
.success-circle {
  width: 64px; height: 64px; border-radius: 50%;
  background: linear-gradient(135deg, #22c55e, #16a34a);
  display: flex; align-items: center; justify-content: center;
  box-shadow: 0 8px 24px rgba(34,197,94,0.4);
}
@keyframes ringPop {
  from { opacity: 0; transform: scale(0.5); }
  to   { opacity: 1; transform: scale(1); }
}

.slide-fade-enter-active { transition: all 0.35s cubic-bezier(.22,.68,0,1.2); }
.slide-fade-leave-active { transition: all 0.2s ease; }
.slide-fade-enter        { opacity: 0; transform: translateX(24px); }
.slide-fade-leave-to     { opacity: 0; transform: translateX(-24px); }
</style>
