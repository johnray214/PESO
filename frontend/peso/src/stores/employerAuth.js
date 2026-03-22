import { defineStore } from 'pinia'
import api from '@/services/api'

const EMPLOYER_TOKEN_KEY = 'employer_token'
const EMPLOYER_USER_KEY = 'employer_user'

export const useEmployerAuthStore = defineStore('employerAuth', {
  state: () => ({
    initialized: false,
    user: null,
    token: null,
    isAppReady: false,
  }),

  getters: {
    isAuthenticated: (state) => !!state.user && !!state.token,
    isApproved: (state) => state.user?.status === 'approved',
  },

  actions: {
    setAppReady() {
      if (!this.isAppReady) {
        setTimeout(() => {
          this.isAppReady = true
        }, 2000)
      }
    },

    async init() {
      if (this.initialized) return
      const token = localStorage.getItem(EMPLOYER_TOKEN_KEY)
      const saved = localStorage.getItem(EMPLOYER_USER_KEY)
      if (token && saved) {
        try {
          this.user = JSON.parse(saved)
          this.token = token
        } catch (_) { /* ignore invalid saved auth */ }
      }
      this.initialized = true
    },

    async login(email, password) {
      const { data } = await api.post('/employer/login', { email, password })
      if (!data.success || !data.data) throw new Error(data.message || 'Login failed')
      const { employer, token } = data.data
      
      let photoUrl = employer.photo
      if (photoUrl && !photoUrl.startsWith('http')) {
        photoUrl = api.defaults.baseURL.replace(/\/api\/?$/, '') + '/storage/' + photoUrl
      }
      
      this.user = {
        id: employer.id,
        name: employer.name,
        company_name: employer.company_name,
        legal_name: employer.legal_name,
        contact_person: employer.contact_person,
        email: employer.email,
        industry: employer.industry,
        city: employer.city,
        status: employer.status,
        photo: photoUrl,
      }
      this.token = token
      
      localStorage.setItem(EMPLOYER_TOKEN_KEY, token)
      localStorage.setItem(EMPLOYER_USER_KEY, JSON.stringify(this.user))
      
      // Set default auth header
      api.defaults.headers.common['Authorization'] = `Bearer ${token}`
    },

    async register(formData) {
      const { data } = await api.post('/employer/register', formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      })
      if (!data.success || !data.data) throw new Error(data.message || 'Registration failed')
      const { employer, token } = data.data
      
      let photoUrl = employer.photo
      if (photoUrl && !photoUrl.startsWith('http')) {
        photoUrl = api.defaults.baseURL.replace(/\/api\/?$/, '') + '/storage/' + photoUrl
      }
      
      this.user = {
        id: employer.id,
        name: employer.name,
        company_name: employer.company_name,
        legal_name: employer.legal_name,
        contact_person: employer.contact_person,
        email: employer.email,
        industry: employer.industry,
        city: employer.city,
        status: employer.status,
        photo: photoUrl,
      }
      this.token = token
      
      localStorage.setItem(EMPLOYER_TOKEN_KEY, token)
      localStorage.setItem(EMPLOYER_USER_KEY, JSON.stringify(this.user))
      
      api.defaults.headers.common['Authorization'] = `Bearer ${token}`
    },

    async logout() {
      try {
        await api.post('/employer/logout')
      } catch (_) { void _; }
      this.initialized = false
      this.user = null
      this.token = null
      this.isAppReady = false
      
      // auth keys
      localStorage.removeItem(EMPLOYER_TOKEN_KEY)
      localStorage.removeItem(EMPLOYER_USER_KEY)
      // employerApplicantsStore cache keys
      localStorage.removeItem('employer_applicants_counts')
      // employerNotificationStore cache keys
      localStorage.removeItem('employer_notifications')
      localStorage.removeItem('employer_unread_count')
      localStorage.removeItem('employer_notifications_time')
      delete api.defaults.headers.common['Authorization']
    },

    async fetchProfile() {
      const { data } = await api.get('/employer/profile')
      if (data.success && data.data) {
        this.user = { ...this.user, ...data.data }
        localStorage.setItem(EMPLOYER_USER_KEY, JSON.stringify(this.user))
      }
      return data.data
    },
  },
})
