// src/services/api.js
import axios from "axios";

// Create axios instance
const api = axios.create({
   baseURL: 'http://127.0.0.1:8000/api',
   timeout: 60000,
   headers: {
      Accept: 'application/json',
   },
});

// Request interceptor → attach PESO employee token (dashboard) or regular auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('peso_auth_token') || localStorage.getItem('auth_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

// Response interceptor → clear auth on 401
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('peso_auth_token')
      localStorage.removeItem('auth_token')
      localStorage.removeItem('peso-auth')
      if (window.location.hash !== '#/login') {
        window.location.hash = '#/login'
      }
    }
    return Promise.reject(error)
  }
)

export default api
