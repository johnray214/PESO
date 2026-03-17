import { defineStore } from 'pinia'
import api from '@/services/api'

const JOBSEEKER_TOKEN_KEY = 'jobseeker_token'
const JOBSEEKER_USER_KEY = 'jobseeker_user'

export const useJobseekerAuthStore = defineStore('jobseekerAuth', {
  state: () => ({
    initialized: false,
    user: null,
    token: null,
  }),

  getters: {
    isAuthenticated: (state) => !!state.user && !!state.token,
    hasVerifiedEmail: (state) => !!state.user?.email_verified_at,
  },

  actions: {
    async init() {
      if (this.initialized) return
      const token = localStorage.getItem(JOBSEEKER_TOKEN_KEY)
      const saved = localStorage.getItem(JOBSEEKER_USER_KEY)
      if (token && saved) {
        try {
          this.user = JSON.parse(saved)
          this.token = token
        } catch (_) { /* ignore invalid saved auth */ }
      }
      this.initialized = true
    },

    async login(email, password) {
      const { data } = await api.post('/jobseeker/login', { email, password })
      if (!data.success || !data.data) throw new Error(data.message || 'Login failed')
      const { jobseeker, token } = data.data
      
      this.user = {
        id: jobseeker.id,
        first_name: jobseeker.first_name,
        last_name: jobseeker.last_name,
        full_name: jobseeker.full_name,
        email: jobseeker.email,
        email_verified_at: jobseeker.email_verified_at,
        status: jobseeker.status,
      }
      this.token = token
      
      localStorage.setItem(JOBSEEKER_TOKEN_KEY, token)
      localStorage.setItem(JOBSEEKER_USER_KEY, JSON.stringify(this.user))
      
      api.defaults.headers.common['Authorization'] = `Bearer ${token}`
    },

    async register(formData) {
      const { data } = await api.post('/jobseeker/register', formData)
      if (!data.success || !data.data) throw new Error(data.message || 'Registration failed')
      const { jobseeker, token } = data.data
      
      this.user = {
        id: jobseeker.id,
        first_name: jobseeker.first_name,
        last_name: jobseeker.last_name,
        full_name: jobseeker.full_name,
        email: jobseeker.email,
        status: jobseeker.status,
      }
      this.token = token
      
      localStorage.setItem(JOBSEEKER_TOKEN_KEY, token)
      localStorage.setItem(JOBSEEKER_USER_KEY, JSON.stringify(this.user))
      
      api.defaults.headers.common['Authorization'] = `Bearer ${token}`
    },

    async logout() {
      try {
        await api.post('/jobseeker/logout')
      } catch (_) { void _; }
      this.user = null
      this.token = null
      localStorage.removeItem(JOBSEEKER_TOKEN_KEY)
      localStorage.removeItem(JOBSEEKER_USER_KEY)
      delete api.defaults.headers.common['Authorization']
    },

    async fetchProfile() {
      const { data } = await api.get('/jobseeker/me')
      if (data.success && data.data) {
        this.user = { ...this.user, ...data.data }
        localStorage.setItem(JOBSEEKER_USER_KEY, JSON.stringify(this.user))
      }
      return data.data
    },

    async verifyEmail(id, hash) {
      const { data } = await api.post(`/jobseeker/verify-email/${id}/${hash}`)
      if (data.success && this.user) {
        this.user.email_verified_at = new Date().toISOString()
        localStorage.setItem(JOBSEEKER_USER_KEY, JSON.stringify(this.user))
      }
      return data
    },
  },
})
