<template>
  <div class="page">
    <!-- Toast -->
    <transition name="toast">
      <div v-if="toast.show" class="toast" :class="toast.type">
        <span class="toast-icon" v-html="toast.icon"></span>
        <span class="toast-msg">{{ toast.text }}</span>
      </div>
    </transition>

    <div class="map-header">
      <div class="header-left">
        <h2 class="page-title">Job Location Map</h2>
        <p class="page-sub">Pin employer accounts to their workplace location</p>
      </div>
    </div>

    <div class="map-layout">
      <!-- Sidebar -->
      <div class="map-sidebar">
        <!-- SKELETON -->
        <template v-if="loading">
          <div class="side-search skel" style="height: 38px; border-radius: 10px; margin-bottom: 10px; width: 100%;"></div>
          <div class="side-filters skel" style="height: 60px; border-radius: 8px; margin-bottom: 10px; width: 100%;"></div>
          <div v-for="i in 5" :key="i" class="skel" style="width: 100%; height: 60px; border-radius: 10px; margin-bottom: 7px;"></div>
        </template>

        <!-- ACTUAL CONTENT -->
        <template v-else>
        <div class="side-search">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <input v-model="search" type="text" placeholder="Search employer or job…" class="side-search-input"/>
        </div>

        <div class="side-filters">
          <select v-model="filterCategory" class="side-select">
            <option value="">All Categories</option>
            <option v-for="c in categories" :key="c" :value="c">{{ c }}</option>
          </select>
          <select v-model="filterStatus" class="side-select">
            <option value="">All Status</option>
            <option value="unpinned">Unpinned</option>
            <option value="pinned">Pinned</option>
          </select>
        </div>

        <!-- Count label -->
        <div class="count-row">
          <span class="count-badge">{{ unpinnedFiltered.length }}</span>
          <span class="count-label">Employer Account{{ unpinnedFiltered.length !== 1 ? 's' : '' }} without a pin</span>
        </div>

        <!-- Unpinned List -->
        <div class="listings-scroll">
          <p v-if="unpinnedFiltered.length === 0" class="empty-msg">All accounts are pinned 🎉</p>
          <div
            v-for="emp in unpinnedFiltered"
            :key="emp.id"
            :class="['listing-item', { 'pin-mode': pinningEmp?.id === emp.id }]"
            @click="startPinning(emp)"
          >
            <div class="listing-item-top">
              <div class="listing-logo" :style="{ background: emp.logoBg }">{{ emp.company[0] }}</div>
              <div class="listing-item-info">
                <p class="listing-item-title">{{ emp.company }}</p>
                <p class="listing-item-company">{{ emp.category }}</p>
              </div>
              <span class="status-badge unpinned-s">
                <svg width="9" height="9" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                No Pin
              </span>
            </div>
            <div class="listing-item-meta">
              <span class="meta-chip">{{ emp.category }}</span>
            </div>
            <div v-if="pinningEmp?.id === emp.id" class="pin-hint-inline">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
              Click on the map to place pin…
            </div>
            <div v-else class="click-to-pin">Click to place pin on map →</div>
          </div>
        </div>

        <!-- Divider: Pinned accounts -->
        <div class="divider-label">
          <span>Pinned ({{ pinnedFiltered.length }})</span>
        </div>
        <div class="listings-scroll pinned-scroll">
          <p v-if="pinnedFiltered.length === 0" class="empty-msg">No pinned accounts yet.</p>
          <div
            v-for="emp in pinnedFiltered"
            :key="emp.id"
            :class="['listing-item pinned-item', { active: selectedPin?.id === emp.id }]"
            @click="focusPin(emp)"
          >
            <div class="listing-item-top">
              <div class="listing-logo" :style="{ background: emp.logoBg }">{{ emp.company[0] }}</div>
              <div class="listing-item-info">
                <p class="listing-item-title">{{ emp.company }}</p>
                <p class="listing-item-company">{{ emp.category }}</p>
              </div>
              <span class="status-badge" :class="emp.status === 'Open' ? 'open-s' : 'filled-s'">{{ emp.status }}</span>
            </div>
            <div class="listing-item-loc">
              <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
              {{ emp.address || `${Number(emp.lat).toFixed(4)}, ${Number(emp.lng).toFixed(4)}` }}
            </div>
          </div>
        </div>
        </template>
      </div>

      <!-- Map Area -->
      <div class="map-area" :class="{ 'pin-cursor': !!pinningEmp }">
        <!-- Pinning mode overlay -->
        <transition name="fade">
          <div v-if="pinningEmp" class="pin-mode-banner">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
            Placing pin for <strong>{{ pinningEmp.company }}</strong> — click anywhere on the map
            <button class="cancel-pin-btn" @click="cancelPinning">✕ Cancel</button>
          </div>
        </transition>

        <!-- Mapbox container -->
        <div id="mapbox-map" ref="mapRef" class="mapbox-container"></div>

        <!-- Map loading state -->
        <div v-if="mapLoading" class="map-loading">
          <div class="map-loading-spinner"></div>
          <p>Loading map…</p>
        </div>

        <!-- Map error state -->
        <div v-if="mapError" class="map-error">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="1.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          <p>{{ mapError }}</p>
        </div>

        <!-- Legend -->
        <div v-if="!mapLoading && !mapError" class="map-legend">
          <p class="legend-title">Legend</p>
          <div class="legend-item"><span class="legend-dot blue"></span> Open</div>
          <div class="legend-item"><span class="legend-dot gray"></span> Filled</div>
          <div class="legend-item"><span class="legend-dot orange"></span> Placing…</div>
        </div>
      </div>
    </div>

    <!-- Confirm Pin Modal — only lat/lng editable -->
    <transition name="modal">
      <div v-if="showConfirmModal" class="modal-overlay" @click.self="cancelConfirm">
        <div class="modal">
          <div class="modal-header">
            <div>
              <h3>{{ isEditing ? 'Edit Pin Location' : 'Confirm Pin Location' }}</h3>
              <p class="modal-sub">{{ confirmForm.company }}</p>
            </div>
            <button class="modal-close" @click="cancelConfirm">✕</button>
          </div>

          <div class="modal-body">
            <!-- Read-only info -->
            <div class="info-grid">
              <div class="info-item">
                <span class="info-label">Company</span>
                <span class="info-val">{{ confirmForm.company }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Category</span>
                <span class="info-val">{{ confirmForm.category }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Address</span>
                <span class="info-val">{{ confirmForm.address || '—' }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Status</span>
                <span class="info-val">{{ confirmForm.status }}</span>
              </div>
            </div>

            <div class="coord-divider">
              <span>Pin Coordinates</span>
            </div>

            <!-- Editable coords -->
            <div class="form-row coord-row">
              <div class="form-group">
                <label class="form-label">Latitude</label>
                <input v-model.number="confirmForm.lat" type="number" step="0.000001" class="form-input" placeholder="e.g. 14.5995"/>
              </div>
              <div class="form-group">
                <label class="form-label">Longitude</label>
                <input v-model.number="confirmForm.lng" type="number" step="0.000001" class="form-input" placeholder="e.g. 120.9842"/>
              </div>
            </div>

            <p class="coord-hint">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              You can adjust the coordinates manually or go back and click a different spot on the map.
            </p>
          </div>

          <div class="modal-footer">
            <button class="btn-ghost" @click="cancelConfirm" :disabled="savingPin">
              {{ isEditing ? 'Cancel' : 'Re-place Pin' }}
            </button>
            <button class="btn-primary" @click="confirmPin" :disabled="savingPin">
              <span v-if="savingPin" class="spinner-sm" style="margin-right:4px;"></span>
              <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
              {{ isEditing ? 'Save Location' : 'Confirm Pin' }}
            </button>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
import api from '@/services/api'

const MAPBOX_CSS = 'https://api.mapbox.com/mapbox-gl-js/v3.4.0/mapbox-gl.css'
const MAPBOX_JS  = 'https://api.mapbox.com/mapbox-gl-js/v3.4.0/mapbox-gl.js'

export default {
  name: 'MapPage',

  data() {
    return {
      map: null,
      markers: {},
      tempMarker: null,

      loading: true,
      mapLoading: true,
      mapError: null,

      search: '',
      filterCategory: '',
      filterStatus: '',

      pinningEmp: null,
      selectedPin: null,

      showConfirmModal: false,
      isEditing: false,
      confirmForm: {},
      savingPin: false,

      toast: { show: false, text: '', type: 'success', icon: '', _timer: null },

      categories: ['IT / Dev', 'BPO', 'Healthcare', 'Retail', 'Food & Beverage', 'Manufacturing', 'Education', 'Construction'],
      employers: [],
    }
  },

  computed: {
    unpinned() { return this.employers.filter(e => !e.lat || !e.lng) },
    pinned()   { return this.employers.filter(e =>  e.lat &&  e.lng) },

    unpinnedFiltered() {
      return this.unpinned.filter(e => {
        const s = this.search.toLowerCase()
        const matchSearch = !s || e.jobTitle.toLowerCase().includes(s) || e.company.toLowerCase().includes(s)
        const matchCat    = !this.filterCategory || e.category === this.filterCategory
        const matchStatus = !this.filterStatus   || this.filterStatus === 'unpinned'
        return matchSearch && matchCat && matchStatus
      })
    },

    pinnedFiltered() {
      return this.pinned.filter(e => {
        const s = this.search.toLowerCase()
        const matchSearch = !s || e.jobTitle.toLowerCase().includes(s) || e.company.toLowerCase().includes(s)
        const matchCat    = !this.filterCategory || e.category === this.filterCategory
        const matchStatus = !this.filterStatus   || this.filterStatus === 'pinned'
        return matchSearch && matchCat && matchStatus
      })
    },
  },

  async mounted() {
    await this.fetchEmployers()
    await this.loadMapbox()
  },

  beforeUnmount() {
    if (this.map) { this.map.remove(); this.map = null }
  },

  methods: {
    /* ─── Data ─────────────────────────────────────────────── */
    async fetchEmployers() {
      try {
        const res     = await api.get('/admin/employers', { params: { per_page: 500, status: 'verified' } })
        const rawData = res.data.data?.data || res.data.data || res.data
        const colors  = ['#2563eb', '#22c55e', '#f97316', '#ef4444', '#8b5cf6', '#06b6d4', '#14b8a6']

        this.employers = rawData.map(e => ({
          id:       e.id,
          company:  e.company_name,
          category: e.industry || 'Other',
          address:  e.address_full || e.city || '',
          lat:      parseFloat(e.latitude)  || null,
          lng:      parseFloat(e.longitude) || null,
          status:   'Open',
          logoBg:   colors[e.id % colors.length],
        }))
      } catch (err) {
        console.error('Error fetching employers for map:', err)
      } finally {
        this.loading = false
      }
    },

    /* ─── Mapbox ────────────────────────────────────────────── */
    loadMapbox() {
      return new Promise((resolve) => {
        if (window.mapboxgl) { this.initMap(); resolve(); return }

        if (!document.querySelector(`link[href="${MAPBOX_CSS}"]`)) {
          const link = document.createElement('link')
          link.rel = 'stylesheet'; link.href = MAPBOX_CSS
          document.head.appendChild(link)
        }

        if (!document.querySelector(`script[src="${MAPBOX_JS}"]`)) {
          const script = document.createElement('script')
          script.src = MAPBOX_JS; script.async = true
          script.onload  = () => { this.initMap(); resolve() }
          script.onerror = () => { this.mapLoading = false; this.mapError = 'Failed to load the map library.'; resolve() }
          document.head.appendChild(script)
        } else {
          const poll = setInterval(() => {
            if (window.mapboxgl) { clearInterval(poll); this.initMap(); resolve() }
          }, 50)
          setTimeout(() => { clearInterval(poll); if (!window.mapboxgl) { this.mapLoading = false; this.mapError = 'Map library took too long to load.'; resolve() } }, 10000)
        }
      })
    },

    initMap() {
      const token = process.env.VUE_APP_MAPBOX_TOKEN
      if (!token) { this.mapLoading = false; this.mapError = 'Mapbox token missing. Set VUE_APP_MAPBOX_TOKEN in .env'; return }
      if (!this.$refs.mapRef) { this.mapLoading = false; return }

      try {
        window.mapboxgl.accessToken = token
        this.map = new window.mapboxgl.Map({
          container: this.$refs.mapRef,
          style:     'mapbox://styles/mapbox/satellite-streets-v12',
          center:    [121.55585897821551, 16.689288062554454],
          zoom:      12,
        })
        this.map.addControl(new window.mapboxgl.NavigationControl(), 'bottom-right')
        this.map.on('load', () => {
          this.mapLoading = false
          this.pinned.forEach(emp => this.addMarker(emp))
          this.map.on('click', (e) => {
            if (!this.pinningEmp) return
            const { lng, lat } = e.lngLat
            this.onMapClick(lng, lat)
          })
        })
        this.map.on('error', (e) => {
          console.error('Mapbox error:', e)
          if (this.mapLoading) { this.mapLoading = false; this.mapError = 'The map failed to load.' }
        })
      } catch (err) {
        this.mapLoading = false
        this.mapError   = 'Could not initialise the map: ' + (err.message || err)
      }
    },

    /* ─── Markers ───────────────────────────────────────────── */
    addMarker(emp) {
      if (!emp.lat || !emp.lng || !this.map) return
      if (this.markers[emp.id]) { this.markers[emp.id].remove(); delete this.markers[emp.id] }

      const el    = document.createElement('div')
      el.className = 'custom-marker'
      el.style.cssText = 'width:36px;height:36px;cursor:pointer;'

      const inner = document.createElement('div')
      inner.style.cssText = `
        width:36px;height:36px;
        background:${emp.status === 'Open' ? '#2563eb' : '#94a3b8'};
        border-radius:50% 50% 50% 0;transform:rotate(-45deg);
        display:flex;align-items:center;justify-content:center;
        box-shadow:0 4px 14px rgba(0,0,0,0.25);border:3px solid white;
        transition:transform 0.15s,box-shadow 0.15s;
      `
      inner.innerHTML = `<span style="transform:rotate(45deg);font-size:14px;font-weight:800;color:white;">${emp.company[0]}</span>`
      el.appendChild(inner)

      el.addEventListener('mouseenter', () => { inner.style.transform = 'rotate(-45deg) scale(1.15)' })
      el.addEventListener('mouseleave', () => { inner.style.transform = 'rotate(-45deg)' })
      el.addEventListener('click',      (e) => { e.stopPropagation(); this.openEditForPin(emp) })

      const popup = new window.mapboxgl.Popup({ offset: 25, closeButton: false })
        .setHTML(`
          <div style="font-family:Plus Jakarta Sans,sans-serif;min-width:170px;">
            <p style="font-weight:800;font-size:13px;color:#1e293b;margin:0 0 6px">${emp.company}</p>
            <div style="display:flex;gap:4px;flex-wrap:wrap;margin-bottom:6px">
              <span style="background:#f1f5f9;color:#64748b;font-size:10px;padding:2px 7px;border-radius:5px">${emp.category}</span>
            </div>
            ${emp.address ? `<p style="font-size:11px;color:#94a3b8;margin:0">${emp.address}</p>` : ''}
            <p style="font-size:10px;color:#cbd5e1;margin:4px 0 0">${Number(emp.lat).toFixed(5)}, ${Number(emp.lng).toFixed(5)}</p>
          </div>
        `)

      const marker = new window.mapboxgl.Marker(el)
        .setLngLat([emp.lng, emp.lat])
        .setPopup(popup)
        .addTo(this.map)

      this.markers[emp.id] = marker
    },

    removeMarker(empId) {
      if (this.markers[empId]) { this.markers[empId].remove(); delete this.markers[empId] }
    },

    /* ─── Pin placement flow ─────────────────────────────────── */
    startPinning(emp) {
      this.pinningEmp  = emp
      this.selectedPin = null
      Object.values(this.markers).forEach(m => m.getPopup()?.remove())
    },

    cancelPinning() {
      this.pinningEmp = null
      if (this.tempMarker) { this.tempMarker.remove(); this.tempMarker = null }
    },

    onMapClick(lng, lat) {
      if (!this.pinningEmp) return
      if (this.tempMarker) { this.tempMarker.remove(); this.tempMarker = null }

      const el = document.createElement('div')
      el.style.cssText = `
        width:36px;height:36px;background:#f97316;
        border-radius:50% 50% 50% 0;transform:rotate(-45deg);
        display:flex;align-items:center;justify-content:center;
        border:3px solid white;box-shadow:0 4px 14px rgba(249,115,22,0.4);
        animation:pulse 1s infinite;
      `
      el.innerHTML = `<span style="transform:rotate(45deg);font-size:14px;font-weight:800;color:white;">${(this.pinningEmp.company || '?')[0].toUpperCase()}</span>`

      this.tempMarker = new window.mapboxgl.Marker(el)
        .setLngLat([lng, lat])
        .addTo(this.map)

      // Only carry lat/lng into the confirm form — all other fields read-only from emp
      this.confirmForm = {
        ...this.pinningEmp,
        lat: parseFloat(lat.toFixed(6)),
        lng: parseFloat(lng.toFixed(6)),
      }
      this.isEditing        = false
      this.showConfirmModal = true
    },

    async confirmPin() {
      if (this.savingPin) return
      this.savingPin = true

      const idx = this.employers.findIndex(e => e.id === this.confirmForm.id)
      if (idx !== -1) {
        const updated = {
          ...this.employers[idx],
          lat: this.confirmForm.lat ? Number(this.confirmForm.lat) : null,
          lng: this.confirmForm.lng ? Number(this.confirmForm.lng) : null,
        }
        this.employers.splice(idx, 1, updated)

        try {
          await api.put(`/admin/employers/${updated.id}`, {
            latitude:  updated.lat,
            longitude: updated.lng,
          })

          if (this.tempMarker) { this.tempMarker.remove(); this.tempMarker = null }
          await this.$nextTick()

          if (!updated.lat || !updated.lng) {
            this.removeMarker(updated.id)
          } else {
            this.addMarker(updated)
          }

          this.showToastMsg('Pin saved successfully!', 'success')
        } catch (e) {
          console.error('Failed to save employer location:', e)
          this.showToastMsg('Failed to save pin.', 'error')
        }
      }

      this.pinningEmp       = null
      this.showConfirmModal = false
      this.savingPin        = false
    },

    cancelConfirm() {
      if (this.tempMarker) { this.tempMarker.remove(); this.tempMarker = null }
      this.showConfirmModal = false
      if (this.isEditing) this.isEditing = false
    },

    openEditForPin(emp) {
      // Only lat/lng editable — pass full emp so modal can show read-only info
      this.confirmForm      = { ...emp }
      this.isEditing        = true
      this.showConfirmModal = true
    },

    focusPin(emp) {
      this.selectedPin = emp
      if (this.map && emp.lat && emp.lng) {
        this.map.flyTo({ center: [emp.lng, emp.lat], zoom: 15 })
        this.markers[emp.id]?.togglePopup()
      }
    },

    /* ─── Toast ─────────────────────────────────────────────── */
    showToastMsg(text, type = 'success') {
      const CHECK = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>`
      const X     = `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`
      if (this.toast._timer) clearTimeout(this.toast._timer)
      this.toast = { show: true, text, type, icon: type === 'success' ? CHECK : X, _timer: setTimeout(() => { this.toast.show = false }, 3500) }
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

@keyframes shimmer { 0% { background-position: -400px 0; } 100% { background-position: 400px 0; } }
.skel {
  background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%);
  background-size: 400px 100%; animation: shimmer 1.4s infinite linear;
  border-radius: 6px; flex-shrink: 0;
}

.page { font-family: 'Plus Jakarta Sans', sans-serif; padding: 24px; background: #f8fafc; min-height: 0; flex: 1; display: flex; flex-direction: column; gap: 16px; overflow: hidden; }

.map-header { display: flex; align-items: center; justify-content: space-between; }
.header-left h2.page-title { font-size: 20px; font-weight: 800; color: #1e293b; }
.header-left .page-sub { font-size: 12px; color: #94a3b8; margin-top: 2px; }

.btn-primary { display: flex; align-items: center; gap: 6px; background: #2563eb; color: #fff; border: none; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; transition: background 0.15s; }
.btn-primary:hover:not(:disabled) { background: #1d4ed8; }
.btn-primary:disabled { opacity: 0.6; cursor: not-allowed; }
.btn-ghost { background: #f1f5f9; color: #64748b; border: none; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-ghost:disabled { opacity: 0.6; cursor: not-allowed; }

/* Toast */
.toast { position: fixed; top: 20px; right: 24px; z-index: 9999; display: flex; align-items: center; gap: 10px; padding: 12px 18px; border-radius: 12px; font-size: 13px; font-weight: 600; box-shadow: 0 8px 30px rgba(0,0,0,0.12); min-width: 240px; max-width: 380px; font-family: 'Plus Jakarta Sans', sans-serif; }
.toast.success { background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; }
.toast.error   { background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; }
.toast-icon { display: flex; align-items: center; flex-shrink: 0; }
.toast-msg { word-break: break-word; line-height: 1.4; }
.toast-enter-active, .toast-leave-active { transition: all 0.3s cubic-bezier(0.4,0,0.2,1); }
.toast-enter-from, .toast-leave-to { opacity: 0; transform: translateY(-15px) scale(0.95); }

.spinner-sm { width: 14px; height: 14px; flex-shrink: 0; border: 2px solid rgba(255,255,255,0.4); border-top-color: #fff; border-radius: 50%; animation: spin 0.7s linear infinite; display: inline-block; }
@keyframes spin { to { transform: rotate(360deg); } }

.map-layout { display: flex; gap: 16px; flex: 1; overflow: hidden; }

/* SIDEBAR */
.map-sidebar { width: 310px; min-width: 310px; background: #fff; border-radius: 14px; display: flex; flex-direction: column; gap: 10px; padding: 14px; border: 1px solid #f1f5f9; overflow: hidden; }
.side-search { display: flex; align-items: center; gap: 8px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; }
.side-search-input { border: none; outline: none; font-size: 12.5px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.side-search-input::placeholder { color: #cbd5e1; }
.side-filters { display: flex; flex-direction: column; gap: 6px; }
.side-select { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 7px 10px; font-size: 12px; color: #475569; cursor: pointer; outline: none; font-family: inherit; width: 100%; }

.count-row { display: flex; align-items: center; gap: 8px; padding: 2px 0; }
.count-badge { background: #2563eb; color: #fff; font-size: 13px; font-weight: 800; padding: 2px 10px; border-radius: 99px; min-width: 28px; text-align: center; }
.count-label { font-size: 11.5px; font-weight: 600; color: #64748b; }

.listings-scroll { flex: 1; overflow-y: auto; display: flex; flex-direction: column; gap: 7px; padding-right: 2px; min-height: 0; }
.pinned-scroll { flex: 0 0 auto; max-height: 180px; }
.listings-scroll::-webkit-scrollbar { width: 3px; }
.listings-scroll::-webkit-scrollbar-thumb { background: #e2e8f0; border-radius: 99px; }

.empty-msg { font-size: 12px; color: #cbd5e1; text-align: center; padding: 12px 0; }

.listing-item { padding: 10px 12px; border-radius: 10px; border: 1.5px solid #f1f5f9; cursor: pointer; transition: all 0.15s; }
.listing-item:hover { border-color: #bfdbfe; background: #f8fafc; }
.listing-item.pin-mode { border-color: #f97316; background: #fff7ed; box-shadow: 0 0 0 3px rgba(249,115,22,0.15); }
.listing-item.active { border-color: #2563eb; background: #eff6ff; }
.listing-item.pinned-item { opacity: 0.85; }

.listing-item-top { display: flex; align-items: center; gap: 8px; margin-bottom: 7px; }
.listing-logo { width: 34px; height: 34px; border-radius: 9px; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 800; color: #fff; flex-shrink: 0; }
.listing-item-info { flex: 1; min-width: 0; }
.listing-item-title { font-size: 12.5px; font-weight: 700; color: #1e293b; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.listing-item-company { font-size: 11px; color: #94a3b8; margin-top: 1px; }

.status-badge { display: flex; align-items: center; gap: 3px; padding: 3px 8px; border-radius: 99px; font-size: 10px; font-weight: 700; white-space: nowrap; }
.open-s      { background: #dcfce7; color: #22c55e; }
.filled-s    { background: #f1f5f9; color: #94a3b8; }
.unpinned-s  { background: #fef9c3; color: #ca8a04; }

.listing-item-meta { display: flex; gap: 4px; flex-wrap: wrap; margin-bottom: 5px; }
.meta-chip { background: #f1f5f9; color: #64748b; font-size: 10px; font-weight: 500; padding: 2px 7px; border-radius: 5px; }
.listing-item-loc { display: flex; align-items: center; gap: 4px; font-size: 11px; color: #94a3b8; }

.pin-hint-inline { display: flex; align-items: center; gap: 5px; font-size: 11px; font-weight: 600; color: #2563eb; background: #eff6ff; padding: 5px 8px; border-radius: 7px; margin-top: 4px; animation: blink 1.2s ease-in-out infinite; }
.click-to-pin { font-size: 11px; color: #bfdbfe; margin-top: 2px; }

.divider-label { display: flex; align-items: center; gap: 8px; font-size: 10px; font-weight: 700; color: #cbd5e1; text-transform: uppercase; letter-spacing: 0.06em; }
.divider-label::before, .divider-label::after { content: ''; flex: 1; height: 1px; background: #f1f5f9; }

/* MAP */
.map-area { flex: 1; border-radius: 14px; overflow: hidden; border: 1px solid #f1f5f9; position: relative; background: #e2e8f0; }
.map-area.pin-cursor { cursor: crosshair; }
.mapbox-container { width: 100%; height: 100%; }

.map-loading, .map-error { position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 12px; background: #f8fafc; z-index: 20; font-size: 13px; font-weight: 600; color: #94a3b8; }
.map-error { color: #ef4444; }
.map-loading-spinner { width: 32px; height: 32px; border: 3px solid #e2e8f0; border-top-color: #2563eb; border-radius: 50%; animation: spin 0.8s linear infinite; }

.pin-mode-banner { position: absolute; top: 14px; left: 50%; transform: translateX(-50%); z-index: 10; background: #1e293b; color: #fff; font-size: 12.5px; font-weight: 600; display: flex; align-items: center; gap: 8px; padding: 9px 16px; border-radius: 99px; box-shadow: 0 4px 20px rgba(0,0,0,0.2); white-space: nowrap; font-family: 'Plus Jakarta Sans', sans-serif; }
.cancel-pin-btn { background: rgba(255,255,255,0.15); border: none; color: #fff; font-size: 11px; font-weight: 600; padding: 3px 10px; border-radius: 99px; cursor: pointer; margin-left: 8px; font-family: inherit; }
.cancel-pin-btn:hover { background: rgba(255,255,255,0.25); }

.map-legend { position: absolute; right: 50px; top: 14px; background: #fff; border-radius: 10px; padding: 10px 14px; border: 1px solid #f1f5f9; box-shadow: 0 2px 8px rgba(0,0,0,0.06); z-index: 5; }
.legend-title { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 7px; }
.legend-item { display: flex; align-items: center; gap: 7px; font-size: 11px; color: #475569; margin-bottom: 3px; }
.legend-dot { width: 10px; height: 10px; border-radius: 50%; }
.legend-dot.blue   { background: #2563eb; }
.legend-dot.gray   { background: #94a3b8; }
.legend-dot.orange { background: #f97316; }

/* MODAL */
.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.45); z-index: 100; display: flex; align-items: center; justify-content: center; backdrop-filter: blur(3px); }
.modal { background: #fff; border-radius: 16px; width: 460px; max-width: 95vw; box-shadow: 0 20px 60px rgba(0,0,0,0.15); }
.modal-header { display: flex; align-items: flex-start; justify-content: space-between; padding: 18px 20px; border-bottom: 1px solid #f1f5f9; }
.modal-header h3 { font-size: 16px; font-weight: 800; color: #1e293b; }
.modal-sub { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.modal-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 16px; padding: 4px; }
.modal-body { padding: 20px; display: flex; flex-direction: column; gap: 14px; }
.modal-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 16px 20px; border-top: 1px solid #f1f5f9; }

/* Read-only info grid */
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; background: #f8fafc; border-radius: 10px; padding: 14px; border: 1px solid #f1f5f9; }
.info-item { display: flex; flex-direction: column; gap: 3px; }
.info-label { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
.info-val { font-size: 13px; font-weight: 600; color: #1e293b; }

/* Coord divider */
.coord-divider { display: flex; align-items: center; gap: 10px; font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.06em; }
.coord-divider::before, .coord-divider::after { content: ''; flex: 1; height: 1px; background: #f1f5f9; }

.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.form-group { display: flex; flex-direction: column; gap: 5px; }
.form-label { font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; }
.form-input { border: 1px solid #e2e8f0; border-radius: 8px; padding: 9px 12px; font-size: 13px; color: #1e293b; font-family: inherit; outline: none; background: #f8fafc; transition: border-color 0.15s, background 0.15s; }
.form-input:focus { border-color: #93c5fd; background: #fff; }
.coord-hint { display: flex; align-items: center; gap: 6px; font-size: 11.5px; color: #94a3b8; background: #f8fafc; padding: 8px 12px; border-radius: 8px; }

/* Transitions */
.modal-enter-active, .modal-leave-active { transition: opacity 0.2s; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
.fade-enter-active, .fade-leave-active { transition: opacity 0.2s, transform 0.2s; }
.fade-enter-from, .fade-leave-to { opacity: 0; transform: translate(-50%, -8px); }

@keyframes blink { 0%,100% { opacity:1; } 50% { opacity:0.6; } }
@keyframes pulse { 0%,100% { box-shadow:0 4px 14px rgba(249,115,22,0.4); } 50% { box-shadow:0 4px 24px rgba(249,115,22,0.7); } }

:global(.mapboxgl-popup-content) { font-family:'Plus Jakarta Sans',sans-serif !important; border-radius:12px !important; padding:14px !important; box-shadow:0 8px 30px rgba(0,0,0,0.12) !important; }
:global(.mapboxgl-popup-tip) { display:none; }
</style>