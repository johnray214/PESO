import api from '@/services/api'

/**
 * Origin for public /storage URLs (no /api segment).
 * In development, use the same origin as the SPA (e.g. localhost:8081) so <img> requests
 * go through the Vue devServer proxy to Laravel — avoids ERR_CONNECTION_REFUSED when the
 * browser cannot reach :8000 directly.
 */
export function getApiOrigin() {
  const base = (api.defaults.baseURL || '').trim()
  if (/^https?:\/\//i.test(base)) {
    const apiOrigin = base.replace(/\/api\/?$/, '')
    if (typeof window !== 'undefined' && process.env.NODE_ENV === 'development') {
      return window.location.origin
    }
    return apiOrigin
  }
  if (typeof process !== 'undefined' && process.env?.VUE_APP_API_ORIGIN) {
    return String(process.env.VUE_APP_API_ORIGIN).replace(/\/$/, '')
  }
  if (typeof window !== 'undefined' && process.env.NODE_ENV === 'development') {
    return window.location.origin
  }
  return 'http://127.0.0.1:8000'
}

/**
 * Normalize public storage URLs to the API origin (fixes wrong APP_URL and relative baseURL).
 */
export function normalizeStorageUrl(photo) {
  if (photo == null || photo === '') return null
  const s = String(photo).trim()
  if (s.startsWith('blob:') || s.startsWith('data:')) return s
  const origin = getApiOrigin()
  if (/^https?:\/\//i.test(s)) {
    try {
      const u = new URL(s)
      if (u.pathname.startsWith('/storage/')) {
        return origin + u.pathname + u.search
      }
    } catch {
      return s
    }
    return s
  }
  const path = s.replace(/^\/+/, '').replace(/^storage\//, '').replace(/\\/g, '/')
  return `${origin}/storage/${path}`
}
