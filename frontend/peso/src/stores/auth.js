import { defineStore } from 'pinia'
import api from '@/services/api'

const TOKEN_KEY = 'peso_auth_token'

export const ROLES = {
  ADMIN: 'admin',
  STAFF: 'staff',
  EMPLOYER: 'employer',
}

export const useAuthStore = defineStore('auth', {
  state: () => ({
    initialized: false,
    user: null,
    role: null,
    token: null,
    photo: null,
  }),

  getters: {
    isAuthenticated: (state) => !!state.user && !!state.token,
  },

  actions: {
    async init() {
      if (this.initialized) return
      const token = localStorage.getItem(TOKEN_KEY)
      const saved = localStorage.getItem('peso-auth')
      if (token && saved) {
        try {
          const { user, role, photo } = JSON.parse(saved)
          this.token = token
          this.user = user
          this.role = role
          this.photo = photo ?? null
        } catch (_) { /* ignore invalid saved auth */ }
      }
      this.initialized = true
    },

    async login(email, password) {
      const { data } = await api.post('/peso-employee/login', { email, password })
      if (!data.success || !data.data) throw new Error(data.message || 'Login failed')
      const { user, token } = data.data
      this.user = {
        id: user.id,
        name: user.full_name,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
      }
      this.role = user.role
      this.token = token
      this.photo = user.photo ?? null
      localStorage.setItem(TOKEN_KEY, token)
      localStorage.setItem('peso-auth', JSON.stringify({ user: this.user, role: this.role, photo: this.photo }))
    },

    async logout() {
      try {
        await api.post('/peso-employee/logout')
      } catch (_) { void _; }
      this.initialized = false
      this.user = null
      this.role = null
      this.token = null
      this.photo = null
      // auth keys
      localStorage.removeItem(TOKEN_KEY)
      localStorage.removeItem('peso-auth')
      // adminAppStore cache keys
      localStorage.removeItem('reviewing_count')
      localStorage.removeItem('reviewing_count_time')
      localStorage.removeItem('admin_notifications')
      localStorage.removeItem('admin_notifications_time')
    },
  },
})
