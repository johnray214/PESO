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
            <span class="brand-name">PESO</span>
            <span class="brand-tag">Employer Portal</span>
          </div>
        </div>

        <div class="panel-headline-wrap">
          <h1 class="panel-headline">Welcome <span class="sky">back</span> to<br/>your hiring hub.</h1>
          <p class="panel-sub">Sign in to manage your job listings, review applicants, and hire with confidence — all in one place.</p>
        </div>

        <div class="panel-stats">
          <div v-for="s in stats" :key="s.label" class="pstat">
            <span class="pstat-val">{{ s.val }}</span>
            <span class="pstat-label">{{ s.label }}</span>
          </div>
        </div>
      </div>

      <div class="panel-card">
        <div class="pc-top-row">
          <span class="pc-title">Recent Applicants</span>
          <span class="pc-badge">Live</span>
        </div>
        <div class="pc-applicants">
          <div v-for="a in previewApps" :key="a.name" class="pca-row">
            <div class="pca-avatar" :style="{ background: a.color }">{{ a.init }}</div>
            <div class="pca-info">
              <p class="pca-name">{{ a.name }}</p>
              <p class="pca-role">{{ a.role }}</p>
            </div>
            <span class="pca-score" :style="{ color: a.match >= 85 ? '#4ade80' : '#38bdf8' }">{{ a.match }}%</span>
          </div>
        </div>
        <div class="pc-divider"></div>
        <div class="pc-footer">
          <span class="pc-footer-label">7 Jobs Open</span>
          <span class="pc-footer-val">View All →</span>
        </div>
      </div>
    </div>

    <!-- RIGHT PANEL -->
    <div class="right-panel">
      <div class="auth-box">

        <div class="form-header">
          <h2 class="form-title">Welcome back 👋</h2>
          <p class="form-sub">Sign in to your employer account.</p>
        </div>

        <!-- Social -->
        <div class="social-row">
          <button class="social-btn">
            <svg width="16" height="16" viewBox="0 0 24 24"><path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/><path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/><path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"/><path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/></svg>
            Continue with Google
          </button>
          <button class="social-btn">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="#1877F2"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
            Facebook
          </button>
        </div>

        <div class="divider"><span>or sign in with email</span></div>

        <div class="form-group">
          <label class="form-label">Email Address</label>
          <div class="input-wrap">
            <span class="input-icon">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
            </span>
            <input class="form-input" type="email" v-model="form.email" placeholder="you@company.com"/>
          </div>
        </div>

        <div class="form-group">
          <label class="form-label">Password</label>
          <div class="input-wrap">
            <span class="input-icon">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
            </span>
            <input class="form-input" :type="showPw ? 'text' : 'password'" v-model="form.password" placeholder="••••••••"/>
            <button class="pw-toggle" @click="showPw = !showPw" type="button">
              <svg v-if="!showPw" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
              <svg v-else width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
            </button>
          </div>
        </div>

        <div class="forgot-row">
          <router-link to="/employer/forgot-password" class="forgot-link">Forgot password?</router-link>
        </div>

        <div class="remember-row">
          <input type="checkbox" id="remember" v-model="form.remember"/>
          <label for="remember">Keep me signed in for 30 days</label>
        </div>

        <p v-if="error" style="color:#dc2626;font-size:13px;background:#fef2f2;border:1px solid #fecaca;border-radius:8px;padding:10px 14px;margin-bottom:4px;">{{ error }}</p>

        <button class="btn-submit" @click="handleLogin" :disabled="loading">
          <span v-if="loading" style="display:flex;align-items:center;gap:8px;">
            <span style="width:14px;height:14px;border:2px solid rgba(255,255,255,0.4);border-top-color:#fff;border-radius:50%;animation:spin 0.6s linear infinite;display:inline-block;"></span>
            Signing in…
          </span>
          <span v-else style="display:flex;align-items:center;gap:8px;">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M15 3h4a2 2 0 012 2v14a2 2 0 01-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" y1="12" x2="3" y2="12"/></svg>
            Sign In to Portal
          </span>
        </button>

        <p class="switch-link">
          Don't have an account?
          <router-link to="/employer/register">Register for free →</router-link>
        </p>

      </div>
    </div>

  </div>
</template>

<script>
import api from '@/services/api'

export default {
  name: 'EmployerLogin',
  data() {
    return {
      showPw: false,
      loading: false,
      error: '',
      form: {
        email: '',
        password: '',
        remember: false,
      },
      stats: [
        { val: '5,000+', label: 'Active Jobseekers' },
        { val: '300+',   label: 'Employers' },
        { val: '1,200+', label: 'Hires Made' },
      ],
      previewApps: [
        { init: 'C', name: 'Carlo Reyes',  role: 'Frontend Dev',  match: 94, color: '#2872A1' },
        { init: 'A', name: 'Ana Santos',   role: 'UI/UX Designer', match: 88, color: '#08BDDE' },
        { init: 'M', name: 'Mark Cruz',    role: 'Backend Dev',   match: 76, color: '#8b5cf6' },
      ],
    }
  },
  methods: {
    async handleLogin() {
      if (!this.form.email || !this.form.password) {
        this.error = 'Please enter your email and password.'
        return
      }
      this.loading = true
      this.error = ''
      try {
        const { data } = await api.post('/employer/login', {
          email: this.form.email,
          password: this.form.password,
        })
        localStorage.setItem('employer_token', data.token)
        localStorage.setItem('employer_user', JSON.stringify(data.employer))
        this.$router.push('/employer/dashboard')
      } catch (e) {
        this.error = e.response?.data?.message || 'Invalid email or password.'
      } finally {
        this.loading = false
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

.panel-headline { font-size: 40px; font-weight: 900; color: #fff; line-height: 1.12; letter-spacing: -0.025em; margin-bottom: 14px; }
.panel-headline .sky {
  background: linear-gradient(90deg, #08BDDE, #38bdf8);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;
}
.panel-sub { font-size: 14.5px; color: rgba(255,255,255,0.52); line-height: 1.7; }

.panel-stats { display: flex; gap: 0; }
.pstat { display: flex; flex-direction: column; }
.pstat + .pstat { padding-left: 24px; margin-left: 24px; border-left: 1px solid rgba(255,255,255,0.1); }
.pstat-val   { font-size: 24px; font-weight: 900; color: #fff; }
.pstat-label { font-size: 11px; color: rgba(255,255,255,0.4); margin-top: 2px; font-weight: 500; }

/* floating card */
.panel-card {
  position: relative; z-index: 1;
  background: rgba(255,255,255,0.06);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 18px; padding: 20px 22px;
  backdrop-filter: blur(8px);
  display: flex; flex-direction: column; gap: 12px;
}
.pc-top-row { display: flex; align-items: center; justify-content: space-between; }
.pc-title { font-size: 11px; font-weight: 700; color: rgba(255,255,255,0.45); text-transform: uppercase; letter-spacing: 0.08em; }
.pc-badge {
  background: rgba(34,197,94,0.15); border: 1px solid rgba(34,197,94,0.3);
  color: #4ade80; font-size: 10px; font-weight: 700; padding: 3px 10px; border-radius: 99px;
  display: flex; align-items: center; gap: 5px;
}
.pc-badge::before { content: ''; width: 6px; height: 6px; border-radius: 50%; background: #4ade80; display: block; }
.pc-applicants { display: flex; flex-direction: column; gap: 8px; }
.pca-row { display: flex; align-items: center; gap: 10px; }
.pca-avatar {
  width: 30px; height: 30px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 11px; font-weight: 800; color: #fff; flex-shrink: 0;
}
.pca-info { flex: 1; }
.pca-name { font-size: 12px; font-weight: 600; color: #f1f5f9; }
.pca-role { font-size: 10px; color: rgba(255,255,255,0.4); }
.pca-score { font-size: 12px; font-weight: 800; }
.pc-divider { height: 1px; background: rgba(255,255,255,0.07); }
.pc-footer { display: flex; align-items: center; justify-content: space-between; }
.pc-footer-label { font-size: 11px; color: rgba(255,255,255,0.4); }
.pc-footer-val { font-size: 12px; font-weight: 700; color: #08BDDE; }

/* ── RIGHT PANEL ── */
.right-panel {
  flex: 1; display: flex; align-items: center; justify-content: center;
  padding: 48px 52px; overflow-y: auto; background: #f8fafc;
}
.auth-box { width: 100%; max-width: 440px; }

.form-header { margin-bottom: 28px; }
.form-title { font-size: 28px; font-weight: 900; color: #0f172a; letter-spacing: -0.02em; margin-bottom: 6px; }
.form-sub { font-size: 13.5px; color: #64748b; line-height: 1.6; }

/* social */
.social-row { display: flex; gap: 10px; margin-bottom: 20px; }
.social-btn {
  flex: 1; display: flex; align-items: center; justify-content: center; gap: 8px;
  padding: 10px 14px; border: 1.5px solid #e2e8f0; border-radius: 10px;
  background: #fff; font-family: 'Plus Jakarta Sans', sans-serif;
  font-size: 13px; font-weight: 600; color: #1e293b; cursor: pointer; transition: all 0.15s;
}
.social-btn:hover { border-color: #2872A1; color: #2872A1; background: #f8faff; }

.divider { display: flex; align-items: center; gap: 14px; margin-bottom: 20px; }
.divider::before, .divider::after { content: ''; flex: 1; height: 1px; background: #e2e8f0; }
.divider span { font-size: 12px; color: #94a3b8; font-weight: 600; white-space: nowrap; }

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
.pw-toggle:hover { color: #475569; }

.forgot-row { display: flex; justify-content: flex-end; margin-top: -6px; margin-bottom: 10px; }
.forgot-link { font-size: 12px; color: #2872A1; font-weight: 600; text-decoration: none; }
.forgot-link:hover { text-decoration: underline; }

.remember-row { display: flex; align-items: center; gap: 8px; margin-bottom: 4px; }
.remember-row input[type=checkbox] { width: 16px; height: 16px; accent-color: #2872A1; cursor: pointer; }
.remember-row label { font-size: 13px; color: #475569; cursor: pointer; font-weight: 500; }

.btn-submit {
  width: 100%; padding: 13px; margin-top: 20px;
  background: linear-gradient(135deg, #2872A1, #08BDDE);
  color: #fff; border: none; border-radius: 10px;
  font-family: 'Plus Jakarta Sans', sans-serif; font-size: 14px; font-weight: 700;
  cursor: pointer; transition: all 0.2s;
  box-shadow: 0 4px 16px rgba(40,114,161,0.35);
  display: flex; align-items: center; justify-content: center; gap: 8px;
}
.btn-submit:hover { transform: translateY(-1px); box-shadow: 0 8px 24px rgba(40,114,161,0.45); }
.btn-submit:active { transform: translateY(0); }

.switch-link { text-align: center; margin-top: 20px; font-size: 13px; color: #64748b; }
.switch-link a { color: #2872A1; font-weight: 700; text-decoration: none; }
.switch-link a:hover { text-decoration: underline; }
</style>