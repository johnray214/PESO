import axios from 'axios'

const api = axios.create({
  baseURL: 'https://newpesobackend-production.up.railway.app/api',
  timeout: 60000,
  headers: { Accept: 'application/json' },
})

// Attach the correct bearer token based on who is logged in
api.interceptors.request.use(
  (config) => {
    const token =
      localStorage.getItem('employer_token') ||
      localStorage.getItem('peso_auth_token') ||
      localStorage.getItem('auth_token')
    if (token) config.headers.Authorization = `Bearer ${token}`
    return config
  },
  (error) => Promise.reject(error)
)

// On 401 clear auth and redirect to the correct login page
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      const currentHash = window.location.hash
      const isEmployer = !!localStorage.getItem('employer_token')

      // Don't redirect if already on login page to prevent loops
      if (currentHash.includes('/employer/login') || currentHash.includes('/login')) {
        return Promise.reject(error)
      }

      // Clear auth data
      localStorage.removeItem('employer_token')
      localStorage.removeItem('employer_user')
      localStorage.removeItem('peso_auth_token')
      localStorage.removeItem('auth_token')
      localStorage.removeItem('peso-auth')

      // Redirect to appropriate login
      if (isEmployer) {
        window.location.hash = '#/employer/login'
      } else {
        window.location.hash = '#/login'
      }
    }
    return Promise.reject(error)
  }
)

export default api
