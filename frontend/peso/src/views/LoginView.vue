<script setup>
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import pesoLogo from '@/assets/PESOLOGO.jpg'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const email = ref('')
const password = ref('')
const isSubmitting = ref(false)
const error = ref(null)
const showPassword = ref(false)

async function handleSubmit() {
  if (!email.value.trim() || !password.value.trim()) {
    error.value = 'Please enter your email and password.'
    return
  }
  isSubmitting.value = true
  error.value = null
  try {
    await authStore.login(email.value.trim(), password.value)
    const redirect = (typeof route.query.redirect === 'string' ? route.query.redirect : null) || '/dashboard'
    await router.push(redirect)
  } catch (e) {
    error.value = e.response?.data?.message || e.message || 'Login failed. Please try again.'
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <div class="auth-page">

    <!-- PAGE BACKGROUND BLOBS -->
    <div class="page-bg" aria-hidden="true">
      <div class="blob b1"/><div class="blob b2"/><div class="blob b3"/>
    </div>

    <div class="auth-card">

      <!-- ══ LEFT PANEL ══ -->
      <aside class="panel-left">

        <!-- Decorative SVG layer (full-bleed) -->
        <svg class="deco-svg" viewBox="0 0 320 560" fill="none"
             xmlns="http://www.w3.org/2000/svg" aria-hidden="true"
             preserveAspectRatio="xMidYMid slice">
          <defs>
            <pattern id="dotgrid" x="0" y="0" width="22" height="22" patternUnits="userSpaceOnUse">
              <circle cx="1.5" cy="1.5" r="1.2" fill="rgba(255,255,255,0.13)"/>
            </pattern>
            <radialGradient id="radFade" cx="50%" cy="50%" r="65%">
              <stop offset="0%"   stop-color="white" stop-opacity="1"/>
              <stop offset="100%" stop-color="white" stop-opacity="0"/>
            </radialGradient>
            <mask id="dotmask">
              <rect width="320" height="560" fill="url(#radFade)"/>
            </mask>
          </defs>

          <!-- dot grid with fade mask -->
          <rect width="320" height="560" fill="url(#dotgrid)" mask="url(#dotmask)"/>

          <!-- top-right concentric rings -->
          <circle cx="285" cy="55"  r="135" stroke="rgba(255,255,255,0.06)" stroke-width="1"/>
          <circle cx="285" cy="55"  r="98"  stroke="rgba(255,255,255,0.09)" stroke-width="1"/>
          <circle cx="285" cy="55"  r="62"  stroke="rgba(255,255,255,0.07)" stroke-width="1"/>
          <!-- orbiting accent dot (top-right) -->
          <circle cx="285" cy="-80" r="4.5" fill="rgba(147,197,253,0.75)">
            <animateTransform attributeName="transform" type="rotate"
              from="0 285 55" to="360 285 55" dur="18s" repeatCount="indefinite"/>
          </circle>

          <!-- bottom-left rings -->
          <circle cx="18"  cy="510" r="108" stroke="rgba(255,255,255,0.055)" stroke-width="1"/>
          <circle cx="18"  cy="510" r="68"  stroke="rgba(255,255,255,0.085)" stroke-width="1"/>
          <!-- orbiting accent dot (bottom-left) -->
          <circle cx="18"  cy="402" r="3.5" fill="rgba(167,243,208,0.7)">
            <animateTransform attributeName="transform" type="rotate"
              from="0 18 510" to="-360 18 510" dur="14s" repeatCount="indefinite"/>
          </circle>

          <!-- centre dashed orbit -->
          <circle cx="160" cy="280" r="145" stroke="rgba(147,197,253,0.11)"
                  stroke-width="0.8" stroke-dasharray="5 9"/>

          <!-- diagonal slash -->
          <line x1="-20" y1="560" x2="340" y2="0"
                stroke="rgba(255,255,255,0.035)" stroke-width="1.2"/>

          <!-- corner triangle fill -->
          <polygon points="0,0 78,0 0,78" fill="rgba(255,255,255,0.045)"/>

          <!-- hexagon bottom-right -->
          <polygon points="290,454 314,467 314,493 290,506 266,493 266,467"
                   stroke="rgba(255,255,255,0.1)" stroke-width="1" fill="none"/>
          <polygon points="290,464 308,474 308,492 290,502 272,492 272,474"
                   stroke="rgba(147,197,253,0.14)" stroke-width="0.6" fill="none"/>

          <!-- plus accent mid-left -->
          <line x1="34" y1="214" x2="58" y2="214" stroke="rgba(255,255,255,0.22)" stroke-width="1.3"/>
          <line x1="46" y1="202" x2="46" y2="226" stroke="rgba(255,255,255,0.22)" stroke-width="1.3"/>

          <!-- diamond accent centre-top -->
          <rect x="150" y="62" width="12" height="12"
                transform="rotate(45 156 68)"
                stroke="rgba(255,255,255,0.2)" stroke-width="1" fill="none"/>

          <!-- twinkling dots -->
          <circle cx="90"  cy="152" r="3.5" fill="rgba(147,197,253,0.65)">
            <animate attributeName="opacity" values="0.3;1;0.3" dur="3.2s" repeatCount="indefinite"/>
          </circle>
          <circle cx="228" cy="322" r="2.8" fill="rgba(167,243,208,0.65)">
            <animate attributeName="opacity" values="1;0.3;1" dur="4.1s" repeatCount="indefinite"/>
          </circle>
          <circle cx="54"  cy="270" r="2.2" fill="rgba(253,186,116,0.55)">
            <animate attributeName="opacity" values="0.5;1;0.5" dur="2.6s" repeatCount="indefinite"/>
          </circle>
          <circle cx="276" cy="198" r="2"   fill="rgba(216,180,254,0.5)">
            <animate attributeName="opacity" values="0.4;1;0.4" dur="5s" repeatCount="indefinite"/>
          </circle>
        </svg>

        <!-- Logo -->
        <div class="logo-wrap">
          <div class="logo-halo"/>
          <img :src="pesoLogo" alt="PESO logo" class="logo-img"/>
        </div>

        <!-- Brand -->
        <div class="brand-block">
          <h2 class="brand-name">PESO</h2>
          <p class="brand-full">Public Employment<br/>Service Office</p>
          <div class="brand-rule"/>
          <p class="brand-tagline">Connecting talent with opportunity<br/>across the region.</p>
        </div>

        <!-- Online badge -->
        <div class="live-badge">
          <!-- signal / wifi SVG icon -->
          <svg width="13" height="11" viewBox="0 0 22 18" fill="none" stroke="currentColor"
               stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M1 6.5C5.5 2 16.5 2 21 6.5"/>
            <path d="M4.5 10C7.5 7.2 14.5 7.2 17.5 10"/>
            <path d="M8 13.5c1.5-1.3 5-1.3 6.5 0"/>
            <circle cx="11" cy="17" r="1" fill="currentColor" stroke="none"/>
          </svg>
          STGO · Official Portal
          <span class="live-dot"/>
        </div>

      </aside>

      <!-- ══ RIGHT PANEL ══ -->
      <section class="panel-right">
        <div class="panel-inner">

          <!-- Heading -->
          <header class="heading">
            <div class="heading-chip">
              <!-- shield-check SVG -->
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                   stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                <path d="M12 2l9 4v6c0 5-3.9 9.7-9 11C3.9 21.7 3 17 3 12V6l9-4z"/>
                <polyline points="9 12 11 14 15 10"/>
              </svg>
              Secure Login
            </div>
            <h1 class="auth-title">Welcome back</h1>
            <p class="auth-sub">Sign in to your PESO portal account</p>
          </header>

          <!-- Form -->
          <form class="auth-form" @submit.prevent="handleSubmit" novalidate>

            <!-- Email -->
            <div class="field">
              <label class="field-label" for="inp-email">Email</label>
              <div class="inp-shell">
                <svg class="inp-ico" width="15" height="15" viewBox="0 0 24 24" fill="none"
                     stroke="currentColor" stroke-width="2" stroke-linecap="round"
                     stroke-linejoin="round" aria-hidden="true">
                  <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                  <polyline points="22,6 12,13 2,6"/>
                </svg>
                <input id="inp-email" v-model="email" type="email" class="inp"
                       placeholder="Enter your email" autocomplete="email"/>
              </div>
            </div>

            <!-- Password -->
            <div class="field">
              <div style="display: flex; justify-content: space-between; align-items: baseline;">
                <label class="field-label" for="inp-pw">Password</label>
                <router-link to="/admin/forgot-password" class="forgot-link">Forgot password?</router-link>
              </div>
              <div class="inp-shell">
                <!-- lock SVG -->
                <svg class="inp-ico" width="15" height="15" viewBox="0 0 24 24" fill="none"
                     stroke="currentColor" stroke-width="2" stroke-linecap="round"
                     stroke-linejoin="round" aria-hidden="true">
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                  <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                </svg>
                <input id="inp-pw" v-model="password"
                       :type="showPassword ? 'text' : 'password'"
                       class="inp" placeholder="Enter your password"
                       autocomplete="current-password"/>
                <button type="button" class="eye-btn"
                        @click="showPassword = !showPassword" tabindex="-1"
                        :aria-label="showPassword ? 'Hide password' : 'Show password'">
                  <!-- eye-open SVG -->
                  <svg v-if="!showPassword" width="15" height="15" viewBox="0 0 24 24" fill="none"
                       stroke="currentColor" stroke-width="2" stroke-linecap="round"
                       stroke-linejoin="round" aria-hidden="true">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                    <circle cx="12" cy="12" r="3"/>
                  </svg>
                  <!-- eye-off SVG -->
                  <svg v-else width="15" height="15" viewBox="0 0 24 24" fill="none"
                       stroke="currentColor" stroke-width="2" stroke-linecap="round"
                       stroke-linejoin="round" aria-hidden="true">
                    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/>
                    <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/>
                    <line x1="1" y1="1" x2="23" y2="23"/>
                  </svg>
                </button>
              </div>
            </div>

            <!-- Error message -->
            <transition name="err">
              <p v-if="error" class="error-msg" role="alert">
                <!-- alert-circle SVG -->
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                     stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                     style="flex-shrink:0" aria-hidden="true">
                  <circle cx="12" cy="12" r="10"/>
                  <line x1="12" y1="8"  x2="12" y2="12"/>
                  <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                {{ error }}
              </p>
            </transition>

            <!-- Submit -->
            <button class="submit-btn" type="submit" :disabled="isSubmitting">
              <span class="btn-inner">
                <template v-if="!isSubmitting">
                  <!-- log-in SVG -->
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                       stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                    <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/>
                    <polyline points="10 17 15 12 10 7"/>
                    <line x1="15" y1="12" x2="3" y2="12"/>
                  </svg>
                  Sign in
                </template>
                <template v-else>
                  <span class="spin-ring" aria-hidden="true"/>
                  Signing in…
                </template>
              </span>
            </button>

          </form>

          <p class="footer-note">PESO · STGO · {{ new Date().getFullYear() }}</p>
        </div>
      </section>

    </div>
  </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:ital,wght@0,400;0,500;0,600;0,700;1,400&family=Syne:wght@700;800&display=swap');

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

/* ── Design tokens ── */
:root {
  --blue-600: #2563eb;
  --blue-700: #1d4ed8;
  --blue-800: #1e3a8a;
  --blue-900: #172554;
  --slate-50:  #f8fafc;
  --slate-100: #f1f5f9;
  --slate-200: #e2e8f0;
  --slate-400: #94a3b8;
  --slate-500: #64748b;
  --slate-700: #374151;
  --slate-900: #0f172a;
  --font-ui:   'Plus Jakarta Sans', sans-serif;
  --font-head: 'Syne', sans-serif;
}

/* ── Page wrapper ── */
.auth-page {
  min-height: 100vh;
  display: flex;
  align-items: stretch;
  justify-content: center;
  background: #eef2ff;
  padding: 0;
  font-family: var(--font-ui);
  position: relative;
  overflow: hidden;
}

/* Background blobs */
.page-bg { position: fixed; inset: 0; pointer-events: none; z-index: 0; }
.blob     { position: absolute; border-radius: 50%; filter: blur(90px); }
.b1 { width: 640px; height: 640px; top: -160px; left: -160px;
      background: rgba(37,99,235,0.1);
      animation: blobDrift 13s ease-in-out infinite; }
.b2 { width: 440px; height: 440px; bottom: -110px; right: -110px;
      background: rgba(99,102,241,0.09);
      animation: blobDrift 17s ease-in-out 4s infinite reverse; }
.b3 { width: 320px; height: 320px; top: 45%; left: 48%;
      background: rgba(14,165,233,0.07);
      animation: blobDrift 11s ease-in-out 2s infinite; }

/* ── Card (full width, no edge) ── */
.auth-card {
  position: relative;
  z-index: 1;
  width: 100%;
  max-width: none;
  min-height: 100vh;
  display: grid;
  grid-template-columns: 1fr 1.28fr;
  border-radius: 0;
  overflow: hidden;
  box-shadow: none;
  animation: cardRise 0.75s cubic-bezier(0.16,1,0.3,1) both;
}

/* ── Left panel ── */
.panel-left {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 3rem 2rem 2.5rem;
  background: linear-gradient(155deg, #1e40af 0%, #1e3a8a 50%, #172554 100%);
  overflow: hidden;
  color: #fff;
  min-height: 520px;
}

/* SVG art sits behind everything */
.deco-svg {
  position: absolute;
  inset: 0;
  width: 100%; height: 100%;
  pointer-events: none;
}

/* Logo */
.logo-wrap {
  position: relative;
  margin-bottom: 1.75rem;
  z-index: 1;
}
.logo-halo {
  position: absolute;
  inset: -16px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(147,197,253,0.28), transparent 70%);
  animation: haloPulse 3.5s ease-in-out infinite;
}
.logo-img {
  position: relative;
  width: 110px; height: 110px;
  border-radius: 50%;
  object-fit: cover;
  border: 3px solid rgba(255,255,255,0.3);
  box-shadow:
    0 0 0 7px rgba(255,255,255,0.07),
    0 14px 36px rgba(15,23,42,0.38);
  display: block;
}

/* Brand text */
.brand-block { text-align: center; z-index: 1; }

.brand-name {
  font-family: var(--font-head);
  font-weight: 800;
  font-size: 3.2rem;      /* ← tall, bold, unmistakably Syne */
  letter-spacing: 0.2em;
  line-height: 1;
  color: #fff;
  text-shadow:
    0 1px 0   rgba(255,255,255,0.15),
    0 4px 24px rgba(15,23,42,0.4);
}
.brand-full {
  margin-top: 0.5rem;
  font-size: 0.77rem;
  font-weight: 500;
  color: rgba(219,234,254,0.85);
  line-height: 1.6;
  letter-spacing: 0.03em;
}
.brand-rule {
  width: 38px; height: 2px;
  background: rgba(255,255,255,0.2);
  border-radius: 99px;
  margin: 1.1rem auto;
}
.brand-tagline {
  font-size: 0.72rem;
  color: rgba(186,213,255,0.62);
  line-height: 1.75;
  font-style: italic;
  max-width: 22ch;
  margin: 0 auto;
}

/* Live badge */
.live-badge {
  margin-top: 2.25rem;
  z-index: 1;
  display: flex;
  align-items: center;
  gap: 0.45rem;
  font-size: 0.61rem;
  font-weight: 700;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: rgba(147,197,253,0.72);
}
.live-dot {
  width: 7px; height: 7px;
  background: #4ade80;
  border-radius: 50%;
  box-shadow: 0 0 8px #4ade80;
  animation: liveBlink 2s ease-in-out infinite;
}

/* ── Right panel ── */
.panel-right {
  background: #fff;
  display: flex;
  align-items: center;
}
.panel-inner {
  width: 100%;
  padding: 2.75rem 2.5rem 2.25rem;
}

/* Heading */
.heading { margin-bottom: 2rem; }
.heading-chip {
  display: inline-flex;
  align-items: center;
  gap: 0.38rem;
  font-size: 0.68rem;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--blue-600);
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  border-radius: 99px;
  padding: 0.3rem 0.75rem;
  margin-bottom: 1rem;
}
.auth-title {
  font-family: var(--font-head);
  font-weight: 800;
  font-size: 2.4rem;      /* ← bumped up */
  line-height: 1.08;
  letter-spacing: -0.025em;
  color: var(--slate-900);
  margin-bottom: 0.4rem;
}
.auth-sub {
  font-size: 0.875rem;
  color: var(--slate-500);
  font-weight: 400;
}

/* Form layout */
.auth-form {
  display: flex;
  flex-direction: column;
  gap: 1.15rem;
}
.field {
  display: flex;
  flex-direction: column;
  gap: 0.42rem;
}
.field-label {
  font-size: 0.78rem;
  font-weight: 700;
  color: var(--slate-700);
  letter-spacing: 0.02em;
}

/* Input shell */
.inp-shell {
  position: relative;
  display: flex;
  align-items: center;
}
.inp-ico {
  position: absolute;
  left: 0.9rem;
  color: var(--slate-400);
  pointer-events: none;
  flex-shrink: 0;
}
.inp {
  width: 100%;
  padding: 0.72rem 2.6rem;
  border-radius: 0.7rem;
  border: 1.5px solid var(--slate-200);
  font-size: 0.875rem;
  font-family: var(--font-ui);
  color: var(--slate-900);
  background: var(--slate-50);
  outline: none;
  transition: border-color 0.2s, box-shadow 0.2s, background 0.2s;
  appearance: none;
}
.inp::placeholder { color: #b0bbc8; }
.inp:focus {
  border-color: var(--blue-600);
  box-shadow: 0 0 0 3.5px rgba(37,99,235,0.11);
  background: #fff;
}

/* Eye toggle */
.eye-btn {
  position: absolute;
  right: 0.75rem;
  background: none;
  border: none;
  padding: 0.25rem;
  cursor: pointer;
  color: var(--slate-400);
  display: flex;
  align-items: center;
  border-radius: 5px;
  transition: color 0.18s;
}
.eye-btn:hover { color: #475569; }

/* Error */
.error-msg {
  display: flex;
  align-items: center;
  gap: 0.45rem;
  font-size: 0.8rem;
  color: #b91c1c;
  background: #fef2f2;
  border: 1.5px solid #fecaca;
  border-radius: 0.6rem;
  padding: 0.6rem 0.85rem;
}
.err-enter-active, .err-leave-active { transition: all 0.22s ease; }
.err-enter-from, .err-leave-to { opacity: 0; transform: translateY(-6px); }

/* Submit button */
.submit-btn {
  margin-top: 0.35rem;
  width: 100%;
  padding: 0;
  border-radius: 0.8rem;
  border: none;
  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
  cursor: pointer;
  box-shadow:
    0 4px 14px rgba(37,99,235,0.36),
    0 1px 3px  rgba(37,99,235,0.22);
  transition: transform 0.14s ease, box-shadow 0.14s ease, opacity 0.14s;
  overflow: hidden;
  position: relative;
}
.submit-btn::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, rgba(255,255,255,0.13), transparent);
  pointer-events: none;
}
.submit-btn:hover:enabled {
  transform: translateY(-1.5px);
  box-shadow:
    0 8px 22px rgba(37,99,235,0.42),
    0 2px 6px  rgba(37,99,235,0.26);
}
.submit-btn:active:enabled {
  transform: translateY(0);
  box-shadow: 0 3px 8px rgba(37,99,235,0.28);
}
.submit-btn:disabled { opacity: 0.62; cursor: default; }
.submit-btn:disabled { opacity: 0.62; cursor: default; }
.btn-inner {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.88rem 1rem;
  font-family: var(--font-ui);
  font-size: 0.9rem;
  font-weight: 700;
  color: #fff;
  letter-spacing: 0.01em;
}

/* Forgot Password Link */
.forgot-link {
  font-size: 0.78rem;
  font-weight: 600;
  color: var(--blue-600);
  text-decoration: none;
  transition: color 0.15s ease;
}
.forgot-link:hover { color: var(--blue-800); text-decoration: underline; }

/* Spinner */
.spin-ring {
  width: 16px; height: 16px;
  border: 2px solid rgba(255,255,255,0.3);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spinIt 0.65s linear infinite;
  flex-shrink: 0;
}

/* Footer */
.footer-note {
  margin-top: 1.6rem;
  font-size: 0.68rem;
  color: #c4cfdc;
  text-align: center;
  letter-spacing: 0.07em;
}

/* ── Keyframes ── */
@keyframes cardRise {
  from { opacity: 0; transform: translateY(28px) scale(0.975); }
  to   { opacity: 1; transform: translateY(0)    scale(1); }
}
@keyframes blobDrift {
  0%, 100% { transform: translate(0,0) scale(1); }
  50%       { transform: translate(18px,22px) scale(1.06); }
}
@keyframes haloPulse {
  0%, 100% { opacity: 0.55; transform: scale(1); }
  50%       { opacity: 0.9;  transform: scale(1.1); }
}
@keyframes liveBlink {
  0%, 100% { opacity: 0.65; transform: scale(1); }
  50%       { opacity: 1;    transform: scale(1.35); }
}
@keyframes spinIt { to { transform: rotate(360deg); } }

/* ── Responsive ── */
@media (max-width: 640px) {
  .auth-card { grid-template-columns: 1fr; }
  .panel-left { padding: 2.25rem 1.5rem 1.75rem; min-height: unset; }
  .brand-name { font-size: 2.6rem; }
  .brand-tagline, .brand-rule { display: none; }
  .panel-inner { padding: 2.25rem 1.5rem 2rem; }
  .auth-title { font-size: 2rem; }
}
</style>