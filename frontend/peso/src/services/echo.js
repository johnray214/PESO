import Echo from 'laravel-echo'
import Pusher from 'pusher-js'

window.Pusher = Pusher
// Enable Pusher logging to debug connection issues
Pusher.logToConsole = true

// Shared Echo instance — created once, reused across all Pinia stores
let _echo = null

function _buildEcho(token) {
  return new Echo({
    broadcaster: 'pusher',
    key: process.env.VUE_APP_PUSHER_KEY,
    cluster: process.env.VUE_APP_PUSHER_CLUSTER,
    forceTLS: true,
    // Auth endpoint for private channels (employer only)
    authEndpoint: 'https/localhost:8000/api/broadcasting/auth',
    auth: {
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: 'application/json',
      },
    },
  })
}

export function getEcho(bearerToken = null) {
  if (_echo) return _echo

  const token =
    bearerToken ||
    localStorage.getItem('employer_token') ||
    localStorage.getItem('peso_auth_token') ||
    localStorage.getItem('auth_token') ||
    ''

  _echo = _buildEcho(token)
  return _echo
}

/**
 * Destroy the current Echo instance and create a fresh one with the
 * latest token from localStorage (or the supplied token).
 * Call this right before subscribing to a private channel so the
 * Bearer token used for Pusher auth is always up-to-date.
 */
export function refreshEcho(bearerToken = null) {
  if (_echo) {
    try { _echo.disconnect() } catch (_) { /* ignore */ }
    _echo = null
  }

  const token =
    bearerToken ||
    localStorage.getItem('employer_token') ||
    localStorage.getItem('peso_auth_token') ||
    localStorage.getItem('auth_token') ||
    ''

  _echo = _buildEcho(token)
  return _echo
}

/**
 * Call this on logout to close the WebSocket and allow re-init on next login.
 */
export function destroyEcho() {
  if (_echo) {
    _echo.disconnect()
    _echo = null
  }
}
