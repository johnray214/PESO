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
          const { user, role } = JSON.parse(saved)
          this.token = token
          this.user = user
          this.role = role
        } catch (_) { /* ignore invalid saved auth */ }
      }
      this.initialized = true
    },

    async login(email, password) {
      const { data } = await api.post('/peso-employee/login', { email, password })
      if (!data.success || !data.data) throw new Error(data.message || 'Login failed')
      const { employee, token } = data.data
      this.user = {
        name: employee.full_name,
        email: employee.email,
        first_name: employee.first_name,
        last_name: employee.last_name,
      }
      this.role = employee.role
      this.token = token
      localStorage.setItem(TOKEN_KEY, token)
      localStorage.setItem('peso-auth', JSON.stringify({ user: this.user, role: this.role }))
    },

    async logout() {
      try {
        await api.post('/peso-employee/logout')
      } catch (_) { void _; }
      this.user = null
      this.role = null
      this.token = null
      localStorage.removeItem(TOKEN_KEY)
      localStorage.removeItem('peso-auth')
    },
  },
})
