<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore, type UserRole } from '../stores/auth'
import pesoLogo from '@/assets/images/PESOLOGO.jpg'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const name = ref('')
const role = ref<UserRole>('applicant')
const password = ref('')
const isSubmitting = ref(false)
const error = ref<string | null>(null)

const roles: { label: string; value: UserRole }[] = [
  { label: 'Applicant', value: 'applicant' },
  { label: 'Employer', value: 'employer' },
  { label: 'Admin', value: 'admin' },
]

async function handleSubmit() {
  if (!name.value.trim() || !password.value.trim()) {
    error.value = 'Please enter your name and password.'
    return
  }

  isSubmitting.value = true
  error.value = null

  try {
    // In a real app, replace this with an API call.
    authStore.login(name.value, role.value)

    const redirect = (route.query.redirect as string | undefined) ?? '/dashboard'
    router.push(redirect)
  } catch (e) {
    console.error(e)
    error.value = 'Login failed. Please try again.'
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <div class="auth-page">
    <div class="auth-card">
      <div class="auth-card-inner">
        <aside class="auth-visual">
          <div class="logo-ring logo-ring-large">
            <img
              :src="pesoLogo"
              alt="PESO logo"
              class="logo-img"
            >
          </div>
          <div class="visual-text">
            <h2>PESO</h2>
            <p>Public Employment Service Office</p>
          </div>
        </aside>

        <section class="auth-body">
          <div class="heading">
            <h1 class="auth-title">PESO Portal</h1>
            <p class="auth-subtitle">
              Sign in to manage applicants, employers, events, and notifications.
            </p>
          </div>

          <form class="auth-form" @submit.prevent="handleSubmit">
            <label class="field">
              <span class="field-label">Name</span>
              <input
                v-model="name"
                type="text"
                class="field-input"
                placeholder="Enter your name"
                autocomplete="name"
              />
            </label>

            <label class="field">
              <span class="field-label">Role</span>
              <select v-model="role" class="field-input">
                <option
                  v-for="option in roles"
                  :key="option.value"
                  :value="option.value"
                >
                  {{ option.label }}
                </option>
              </select>
            </label>

            <label class="field">
              <span class="field-label">Password</span>
              <input
                v-model="password"
                type="password"
                class="field-input"
                placeholder="Enter your password"
                autocomplete="current-password"
              />
            </label>

            <p v-if="error" class="error-message">
              {{ error }}
            </p>

            <button
              class="primary-button"
              type="submit"
              :disabled="isSubmitting"
            >
              {{ isSubmitting ? 'Signing in…' : 'Sign in' }}
            </button>
          </form>

          <p class="helper-text">
            
          </p>

          <p class="footer-text">
            PESO · STGO
          </p>
        </section>
      </div>
    </div>
  </div>
</template>

<style scoped>
.auth-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: radial-gradient(circle at top left, #ffffff, #e5f0fb 45%, #bfdbfe 80%, #1565c0 120%);
  padding: 1.5rem;
}

.auth-card {
  width: 100%;
  max-width: 880px;
  padding: 0;
}

.auth-card-inner {
  display: grid;
  grid-template-columns: minmax(0, 1.05fr) minmax(0, 1.15fr);
}

.auth-visual {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 2.25rem 1.75rem;
  border-radius: 1.25rem 0 0 1.25rem;
  background: radial-gradient(circle at top left, #2563eb, #0d47a1);
  color: #e5e7eb;
  box-shadow:
    0 22px 45px rgba(15, 23, 42, 0.45);
}

.logo-ring {
  width: 80px;
  height: 80px;
  border-radius: 999px;
  padding: 4px;
  background: radial-gradient(circle at 30% 30%, #cfe5f7, #1565c0);
  box-shadow:
    0 14px 30px rgba(15, 23, 42, 0.28),
    0 0 0 1px rgba(15, 23, 42, 0.08);
}

.logo-ring-large {
  width: 120px;
  height: 120px;
}

.logo-img {
  width: 100%;
  height: 100%;
  border-radius: 999px;
  object-fit: cover;
  background-color: #ffffff;
}

.visual-text {
  margin-top: 1.25rem;
  text-align: center;
}

.visual-text h2 {
  margin: 0;
  font-size: 1.4rem;
  font-weight: 700;
  letter-spacing: 0.08em;
}

.visual-text p {
  margin: 0.25rem 0 0;
  font-size: 0.85rem;
  color: #e5e7eb;
  opacity: 0.9;
}

.heading {
  text-align: center;
  margin-bottom: 1.5rem;
}

.auth-title {
  margin: 0;
  font-size: 1.8rem;
  font-weight: 700;
  color: #0f172a;
}

.auth-subtitle {
  margin-top: 0.25rem;
  margin-bottom: 0.25rem;
  font-size: 0.95rem;
  color: #64748b;
}

.auth-tagline {
  margin: 0.2rem 0 0;
  font-size: 0.8rem;
  color: #94a3b8;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}

.field-label {
  font-size: 0.85rem;
  font-weight: 600;
  color: #0f172a;
}

.field-input {
  padding: 0.6rem 0.75rem;
  border-radius: 0.75rem;
  border: 1px solid #e2e8f0;
  font-size: 0.9rem;
  outline: none;
  transition:
    border-color 0.15s ease,
    box-shadow 0.15s ease,
    background-color 0.15s ease;
}

.field-input:focus {
  border-color: #1565c0;
  box-shadow: 0 0 0 1px rgba(21, 101, 192, 0.25);
  background-color: #f9fafb;
}

.error-message {
  margin: 0.25rem 0 0;
  font-size: 0.85rem;
  color: #b91c1c;
}

.primary-button {
  margin-top: 0.5rem;
  width: 100%;
  border-radius: 999px;
  border: none;
  padding: 0.7rem 1rem;
  font-size: 0.95rem;
  font-weight: 600;
  background: linear-gradient(135deg, #1565c0, #0d47a1);
  color: #f9fafb;
  cursor: pointer;
  transition:
    transform 0.1s ease,
    box-shadow 0.1s ease,
    opacity 0.15s ease;
  box-shadow: 0 12px 25px rgba(21, 101, 192, 0.45);
}

.primary-button:hover:enabled {
  transform: translateY(-1px);
  box-shadow: 0 16px 30px rgba(21, 101, 192, 0.55);
}

.primary-button:active:enabled {
  transform: translateY(0);
  box-shadow: 0 10px 20px rgba(21, 101, 192, 0.4);
}

.primary-button:disabled {
  opacity: 0.7;
  cursor: default;
}

.helper-text {
  margin-top: 1.25rem;
  font-size: 0.8rem;
  color: #94a3b8;
  text-align: center;
}

.footer-text {
  margin-top: 0.4rem;
  font-size: 0.75rem;
  color: #cbd5f5;
  text-align: center;
}

.auth-body {
  padding: 2.25rem 2.25rem 2rem;
  margin-left: 0;
  background-color: #ffffff;
  border-radius: 0 1.25rem 1.25rem 0;
  box-shadow:
    0 22px 45px rgba(15, 23, 42, 0.18),
    0 0 0 1px rgba(15, 23, 42, 0.04);
}

@media (max-width: 480px) {
  .auth-card {
    padding: 0;
  }

  .auth-card-inner {
    grid-template-columns: minmax(0, 1fr);
  }

  .auth-visual {
    padding-bottom: 1.75rem;
  }

  .auth-body {
    margin-left: 0;
    margin-top: 1.25rem;
    border-radius: 1.25rem;
    padding-inline: 1.5rem;
  }
}
</style>

