import { ref, computed } from 'vue'
import { defineStore } from 'pinia'

export type UserRole = 'applicant' | 'employer' | 'admin'

export interface AuthUser {
  id: number
  name: string
  role: UserRole
}

const STORAGE_KEY = 'peso_user'

function loadInitialUser(): AuthUser | null {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return null
    return JSON.parse(raw) as AuthUser
  } catch {
    return null
  }
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<AuthUser | null>(loadInitialUser())

  const isAuthenticated = computed(() => user.value !== null)

  function login(name: string, role: UserRole) {
    const newUser: AuthUser = {
      id: Date.now(),
      name: name.trim() || 'User',
      role,
    }

    user.value = newUser
    localStorage.setItem(STORAGE_KEY, JSON.stringify(newUser))
  }

  function logout() {
    user.value = null
    localStorage.removeItem(STORAGE_KEY)
  }

  return {
    user,
    isAuthenticated,
    login,
    logout,
  }
})

