<template>
  <div class="page">
    <div class="page-header">
      <div>
        <h1 class="page-title">Job Listings Map</h1>
        <p class="page-sub">View and manage job posting locations across the area</p>
      </div>
      <button class="btn-primary" @click="openAddPin">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        Add Location
      </button>
    </div>

    <div class="map-layout">
      <!-- Sidebar Panel -->
      <div class="map-sidebar">
        <!-- Search -->
        <div class="side-search">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <input v-model="search" type="text" placeholder="Search jobs or companies…" class="side-search-input"/>
        </div>

        <!-- Filters -->
        <div class="side-filters">
          <select v-model="filterCategory" class="side-select">
            <option value="">All Categories</option>
            <option v-for="c in categories" :key="c" :value="c">{{ c }}</option>
          </select>
          <select v-model="filterType" class="side-select">
            <option value="">All Types</option>
            <option value="Full-time">Full-time</option>
            <option value="Part-time">Part-time</option>
            <option value="Contract">Contract</option>
          </select>
          <select v-model="filterStatus" class="side-select">
            <option value="">All Status</option>
            <option value="Open">Open</option>
            <option value="Filled">Filled</option>
          </select>
        </div>

        <!-- Count -->
        <p class="listings-count-label">{{ filteredPins.length }} listings found</p>

        <!-- Listings List -->
        <div class="listings-scroll">
          <div
            v-for="pin in filteredPins"
            :key="pin.id"
            :class="['listing-item', { active: selectedPin?.id === pin.id }]"
            @click="selectPin(pin)"
          >
            <div class="listing-item-top">
              <div class="listing-logo" :style="{ background: pin.logoBg }">{{ pin.company[0] }}</div>
              <div class="listing-item-info">
                <p class="listing-item-title">{{ pin.jobTitle }}</p>
                <p class="listing-item-company">{{ pin.company }}</p>
              </div>
              <span class="status-badge" :class="pin.status === 'Open' ? 'open-s' : 'filled-s'">{{ pin.status }}</span>
            </div>
            <div class="listing-item-meta">
              <span class="meta-chip">{{ pin.category }}</span>
              <span class="meta-chip">{{ pin.type }}</span>
              <span class="meta-chip slots">{{ pin.slots }} slots</span>
            </div>
            <div class="listing-item-loc">
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
              {{ pin.address }}
            </div>
          </div>
        </div>
      </div>

      <!-- Map Area -->
      <div class="map-area">
        <!-- Map placeholder with pins rendered as positioned elements -->
        <div class="map-container" ref="mapContainer">
          <!-- Simulated map background -->
          <div class="map-bg">
            <svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
                  <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#e2e8f0" stroke-width="0.5"/>
                </pattern>
              </defs>
              <rect width="100%" height="100%" fill="url(#grid)"/>
              <!-- Simulated roads -->
              <line x1="0" y1="35%" x2="100%" y2="35%" stroke="#d1d5db" stroke-width="6"/>
              <line x1="0" y1="65%" x2="100%" y2="65%" stroke="#d1d5db" stroke-width="4"/>
              <line x1="30%" y1="0" x2="30%" y2="100%" stroke="#d1d5db" stroke-width="6"/>
              <line x1="70%" y1="0" x2="70%" y2="100%" stroke="#d1d5db" stroke-width="4"/>
              <line x1="10%" y1="0" x2="10%" y2="100%" stroke="#e5e7eb" stroke-width="2"/>
              <line x1="50%" y1="0" x2="50%" y2="100%" stroke="#e5e7eb" stroke-width="2"/>
              <line x1="90%" y1="0" x2="90%" y2="100%" stroke="#e5e7eb" stroke-width="2"/>
              <line x1="0" y1="20%" x2="100%" y2="20%" stroke="#e5e7eb" stroke-width="2"/>
              <line x1="0" y1="50%" x2="100%" y2="50%" stroke="#e5e7eb" stroke-width="2"/>
              <line x1="0" y1="80%" x2="100%" y2="80%" stroke="#e5e7eb" stroke-width="2"/>
              <!-- Simulated blocks -->
              <rect x="32%" y="37%" width="16%" height="11%" rx="4" fill="#f8fafc" stroke="#e2e8f0"/>
              <rect x="52%" y="37%" width="16%" height="11%" rx="4" fill="#f8fafc" stroke="#e2e8f0"/>
              <rect x="32%" y="52%" width="16%" height="11%" rx="4" fill="#f8fafc" stroke="#e2e8f0"/>
              <rect x="52%" y="52%" width="16%" height="11%" rx="4" fill="#f8fafc" stroke="#e2e8f0"/>
              <rect x="12%" y="37%" width="14%" height="26%" rx="4" fill="#f0f9ff" stroke="#e0f2fe"/>
              <rect x="72%" y="37%" width="14%" height="26%" rx="4" fill="#fefce8" stroke="#fef9c3"/>
              <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" font-size="11" fill="#cbd5e1" font-family="Plus Jakarta Sans, sans-serif">Interactive map — connect Leaflet.js or Google Maps API</text>
            </svg>
          </div>

          <!-- Map Pins -->
          <div
            v-for="pin in filteredPins"
            :key="pin.id"
            class="map-pin"
            :style="{ left: pin.mapX + '%', top: pin.mapY + '%' }"
            :class="{ active: selectedPin?.id === pin.id, filled: pin.status === 'Filled' }"
            @click="selectPin(pin)"
          >
            <div class="pin-marker" :style="{ background: pin.status === 'Open' ? '#2563eb' : '#94a3b8' }">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>
            </div>
            <div class="pin-label">{{ pin.company }}</div>
            <!-- Popup on active -->
            <div v-if="selectedPin?.id === pin.id" class="pin-popup">
              <button class="popup-close" @click.stop="selectedPin = null">✕</button>
              <p class="popup-title">{{ pin.jobTitle }}</p>
              <p class="popup-company">{{ pin.company }}</p>
              <div class="popup-chips">
                <span class="meta-chip">{{ pin.category }}</span>
                <span class="meta-chip">{{ pin.type }}</span>
              </div>
              <div class="popup-detail"><strong>{{ pin.slots }}</strong> slots available</div>
              <div class="popup-detail popup-loc">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                {{ pin.address }}
              </div>
              <div class="popup-coords">
                <span>Lat: {{ pin.lat }}</span>
                <span>Lng: {{ pin.lng }}</span>
              </div>
              <button class="popup-btn" @click.stop="openEditPin(pin)">Edit Pin</button>
            </div>
          </div>

          <!-- Map Controls -->
          <div class="map-controls">
            <button class="map-ctrl-btn">+</button>
            <button class="map-ctrl-btn">−</button>
          </div>

          <!-- Legend -->
          <div class="map-legend">
            <p class="legend-title">Legend</p>
            <div class="legend-item"><span class="legend-dot blue"></span> Open Position</div>
            <div class="legend-item"><span class="legend-dot gray"></span> Filled Position</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Add / Edit Pin Modal -->
    <transition name="modal">
      <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
        <div class="modal">
          <div class="modal-header">
            <h3>{{ editingPin ? 'Edit Job Location' : 'Add Job Location' }}</h3>
            <button class="modal-close" @click="showModal = false">✕</button>
          </div>
          <div class="modal-body">
            <div class="form-row">
              <div class="form-group">
                <label class="form-label">Job Title</label>
                <input v-model="form.jobTitle" class="form-input" placeholder="e.g. Web Developer"/>
              </div>
              <div class="form-group">
                <label class="form-label">Company Name</label>
                <input v-model="form.company" class="form-input" placeholder="e.g. Accenture PH"/>
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label class="form-label">Category</label>
                <select v-model="form.category" class="form-input">
                  <option v-for="c in categories" :key="c" :value="c">{{ c }}</option>
                </select>
              </div>
              <div class="form-group">
                <label class="form-label">Employment Type</label>
                <select v-model="form.type" class="form-input">
                  <option>Full-time</option>
                  <option>Part-time</option>
                  <option>Contract</option>
                </select>
              </div>
            </div>
            <div class="form-group">
              <label class="form-label">Address</label>
              <input v-model="form.address" class="form-input" placeholder="Full address"/>
            </div>
            <div class="form-row coord-row">
              <div class="form-group">
                <label class="form-label">Latitude</label>
                <input v-model="form.lat" type="number" step="0.000001" class="form-input" placeholder="e.g. 14.5995"/>
              </div>
              <div class="form-group">
                <label class="form-label">Longitude</label>
                <input v-model="form.lng" type="number" step="0.000001" class="form-input" placeholder="e.g. 120.9842"/>
              </div>
            </div>
            <p class="coord-hint">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              Enter the exact coordinates to automatically place the pin on the map.
            </p>
            <div class="form-row">
              <div class="form-group">
                <label class="form-label">Available Slots</label>
                <input v-model="form.slots" type="number" class="form-input" placeholder="10"/>
              </div>
              <div class="form-group">
                <label class="form-label">Status</label>
                <select v-model="form.status" class="form-input">
                  <option>Open</option>
                  <option>Filled</option>
                </select>
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn-ghost" @click="showModal = false">Cancel</button>
            <button class="btn-primary" @click="savePin">{{ editingPin ? 'Save Changes' : 'Add Pin' }}</button>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
export default {
  name: 'MapPage',
  data() {
    return {
      search: '',
      filterCategory: '',
      filterType: '',
      filterStatus: '',
      selectedPin: null,
      showModal: false,
      editingPin: null,
      form: { jobTitle: '', company: '', category: 'IT / Dev', type: 'Full-time', address: '', lat: '', lng: '', slots: '', status: 'Open' },
      categories: ['IT / Dev', 'BPO', 'Healthcare', 'Retail', 'Food & Beverage', 'Manufacturing', 'Education', 'Construction'],
      pins: [
        { id: 1, jobTitle: 'Web Developer', company: 'Accenture PH', category: 'IT / Dev', type: 'Full-time', address: 'BGC, Taguig City', lat: 14.5547, lng: 121.0503, slots: 5, status: 'Open', logoBg: '#dbeafe', mapX: 68, mapY: 43 },
        { id: 2, jobTitle: 'Store Crew', company: 'Jollibee Foods', category: 'Food & Beverage', type: 'Part-time', address: 'Ortigas, Pasig City', lat: 14.5873, lng: 121.0615, slots: 20, status: 'Open', logoBg: '#fff7ed', mapX: 55, mapY: 34 },
        { id: 3, jobTitle: 'Electrician', company: 'SM Supermalls', category: 'Retail', type: 'Full-time', address: 'SM MegaMall, Mandaluyong', lat: 14.5832, lng: 121.0555, slots: 4, status: 'Open', logoBg: '#eff6ff', mapX: 48, mapY: 58 },
        { id: 4, jobTitle: 'Staff Nurse', company: 'Makati Medical', category: 'Healthcare', type: 'Full-time', address: 'Makati City', lat: 14.5547, lng: 121.0130, slots: 3, status: 'Filled', logoBg: '#fdf4ff', mapX: 35, mapY: 45 },
        { id: 5, jobTitle: 'Customer Support', company: 'Accenture PH', category: 'BPO', type: 'Full-time', address: 'Eastwood, Quezon City', lat: 14.6090, lng: 121.0765, slots: 10, status: 'Open', logoBg: '#dbeafe', mapX: 74, mapY: 25 },
      ]
    }
  },
  computed: {
    filteredPins() {
      return this.pins.filter(p => {
        const matchSearch = !this.search || p.jobTitle.toLowerCase().includes(this.search.toLowerCase()) || p.company.toLowerCase().includes(this.search.toLowerCase())
        const matchCat = !this.filterCategory || p.category === this.filterCategory
        const matchType = !this.filterType || p.type === this.filterType
        const matchStatus = !this.filterStatus || p.status === this.filterStatus
        return matchSearch && matchCat && matchType && matchStatus
      })
    }
  },
  methods: {
    selectPin(pin) { this.selectedPin = this.selectedPin?.id === pin.id ? null : pin },
    openAddPin() {
      this.editingPin = null
      this.form = { jobTitle: '', company: '', category: 'IT / Dev', type: 'Full-time', address: '', lat: '', lng: '', slots: '', status: 'Open' }
      this.showModal = true
    },
    openEditPin(pin) {
      this.editingPin = pin
      this.form = { ...pin }
      this.showModal = true
    },
    savePin() {
      if (this.editingPin) {
        Object.assign(this.editingPin, this.form)
      } else {
        this.pins.push({ id: Date.now(), ...this.form, logoBg: '#dbeafe', mapX: Math.random() * 60 + 20, mapY: Math.random() * 50 + 20 })
      }
      this.showModal = false
      this.selectedPin = null
    }
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

.page { font-family: 'Plus Jakarta Sans', sans-serif; padding: 24px; background: #f8fafc; min-height: 0; flex: 1; display: flex; flex-direction: column; gap: 16px; overflow: hidden; }
.page-header { display: flex; align-items: flex-start; justify-content: space-between; flex-shrink: 0; }
.page-title { font-size: 20px; font-weight: 800; color: #1e293b; }
.page-sub { font-size: 12px; color: #94a3b8; margin-top: 2px; }
.btn-primary { display: flex; align-items: center; gap: 6px; background: #2563eb; color: #fff; border: none; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }
.btn-primary:hover { background: #1d4ed8; }
.btn-ghost { background: #f1f5f9; color: #64748b; border: none; border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; font-family: inherit; }

.map-layout { display: flex; gap: 16px; flex: 1; overflow: hidden; }

/* SIDEBAR */
.map-sidebar { width: 300px; min-width: 300px; background: #fff; border-radius: 14px; display: flex; flex-direction: column; gap: 10px; padding: 14px; border: 1px solid #f1f5f9; overflow: hidden; }
.side-search { display: flex; align-items: center; gap: 8px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 8px 12px; }
.side-search-input { border: none; outline: none; font-size: 12.5px; color: #1e293b; background: none; width: 100%; font-family: inherit; }
.side-search-input::placeholder { color: #cbd5e1; }

.side-filters { display: flex; flex-direction: column; gap: 6px; }
.side-select { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 7px 10px; font-size: 12px; color: #475569; cursor: pointer; outline: none; font-family: inherit; width: 100%; }

.listings-count-label { font-size: 11px; font-weight: 700; color: #94a3b8; padding: 4px 0 0; text-transform: uppercase; letter-spacing: 0.05em; }

.listings-scroll { flex: 1; overflow-y: auto; display: flex; flex-direction: column; gap: 8px; padding-right: 2px; }
.listings-scroll::-webkit-scrollbar { width: 4px; }
.listings-scroll::-webkit-scrollbar-track { background: transparent; }
.listings-scroll::-webkit-scrollbar-thumb { background: #e2e8f0; border-radius: 99px; }

.listing-item { padding: 12px; border-radius: 10px; border: 1px solid #f1f5f9; cursor: pointer; transition: all 0.15s; }
.listing-item:hover { border-color: #bfdbfe; background: #f8fafc; }
.listing-item.active { border-color: #2563eb; background: #eff6ff; }

.listing-item-top { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; }
.listing-logo { width: 30px; height: 30px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 13px; font-weight: 800; color: #2563eb; flex-shrink: 0; }
.listing-item-info { flex: 1; min-width: 0; }
.listing-item-title { font-size: 12.5px; font-weight: 700; color: #1e293b; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.listing-item-company { font-size: 11px; color: #94a3b8; margin-top: 1px; }

.status-badge { padding: 3px 8px; border-radius: 99px; font-size: 10px; font-weight: 700; white-space: nowrap; }
.open-s { background: #dcfce7; color: #22c55e; }
.filled-s { background: #f1f5f9; color: #94a3b8; }

.listing-item-meta { display: flex; gap: 4px; flex-wrap: wrap; margin-bottom: 6px; }
.meta-chip { background: #f1f5f9; color: #64748b; font-size: 10px; font-weight: 500; padding: 2px 7px; border-radius: 5px; }
.meta-chip.slots { background: #dbeafe; color: #2563eb; }

.listing-item-loc { display: flex; align-items: center; gap: 4px; font-size: 11px; color: #94a3b8; }

/* MAP AREA */
.map-area { flex: 1; border-radius: 14px; overflow: hidden; border: 1px solid #f1f5f9; position: relative; }
.map-container { width: 100%; height: 100%; position: relative; background: #f1f5f9; }
.map-bg { position: absolute; inset: 0; }

/* PINS */
.map-pin { position: absolute; transform: translate(-50%, -100%); cursor: pointer; z-index: 10; }
.pin-marker { width: 34px; height: 34px; border-radius: 50% 50% 50% 0; transform: rotate(-45deg); display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 12px rgba(0,0,0,0.2); transition: transform 0.15s; }
.pin-marker > svg { transform: rotate(45deg); }
.map-pin:hover .pin-marker, .map-pin.active .pin-marker { transform: rotate(-45deg) scale(1.15); }
.map-pin.active .pin-marker { box-shadow: 0 0 0 4px rgba(37,99,235,0.25); }

.pin-label { font-size: 10px; font-weight: 700; color: #1e293b; background: #fff; padding: 2px 7px; border-radius: 6px; box-shadow: 0 2px 6px rgba(0,0,0,0.1); white-space: nowrap; margin-top: 4px; text-align: center; transform: translateX(-30%); }

/* POPUP */
.pin-popup { position: absolute; bottom: calc(100% + 10px); left: 50%; transform: translateX(-50%); background: #fff; border-radius: 12px; padding: 14px; width: 220px; box-shadow: 0 8px 30px rgba(0,0,0,0.15); border: 1px solid #f1f5f9; z-index: 20; }
.pin-popup::after { content: ''; position: absolute; top: 100%; left: 50%; transform: translateX(-50%); border: 6px solid transparent; border-top-color: #fff; }
.popup-close { position: absolute; top: 8px; right: 8px; background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 12px; }
.popup-title { font-size: 14px; font-weight: 800; color: #1e293b; margin-bottom: 2px; }
.popup-company { font-size: 12px; color: #64748b; margin-bottom: 8px; }
.popup-chips { display: flex; gap: 4px; flex-wrap: wrap; margin-bottom: 8px; }
.popup-detail { font-size: 12px; color: #64748b; margin-bottom: 4px; }
.popup-detail strong { color: #2563eb; }
.popup-loc { display: flex; align-items: center; gap: 4px; color: #94a3b8; margin-bottom: 6px; }
.popup-coords { display: flex; gap: 10px; font-size: 10px; color: #94a3b8; font-family: monospace; margin-bottom: 10px; background: #f8fafc; padding: 4px 8px; border-radius: 6px; }
.popup-btn { width: 100%; background: #2563eb; color: #fff; border: none; border-radius: 8px; padding: 7px; font-size: 12px; font-weight: 600; cursor: pointer; font-family: inherit; }

/* MAP CONTROLS */
.map-controls { position: absolute; right: 14px; bottom: 80px; display: flex; flex-direction: column; gap: 4px; }
.map-ctrl-btn { width: 32px; height: 32px; background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 18px; cursor: pointer; color: #475569; display: flex; align-items: center; justify-content: center; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }

/* LEGEND */
.map-legend { position: absolute; right: 14px; top: 14px; background: #fff; border-radius: 10px; padding: 10px 14px; border: 1px solid #f1f5f9; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
.legend-title { font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 8px; }
.legend-item { display: flex; align-items: center; gap: 8px; font-size: 11.5px; color: #475569; margin-bottom: 4px; }
.legend-dot { width: 10px; height: 10px; border-radius: 50%; }
.legend-dot.blue { background: #2563eb; }
.legend-dot.gray { background: #94a3b8; }

/* MODAL */
.modal-overlay { position: fixed; inset: 0; background: rgba(15,23,42,0.4); z-index: 100; display: flex; align-items: center; justify-content: center; backdrop-filter: blur(2px); }
.modal { background: #fff; border-radius: 16px; width: 520px; max-width: 95vw; box-shadow: 0 20px 60px rgba(0,0,0,0.15); }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 18px 20px; border-bottom: 1px solid #f1f5f9; }
.modal-header h3 { font-size: 16px; font-weight: 800; color: #1e293b; }
.modal-close { background: none; border: none; cursor: pointer; color: #94a3b8; font-size: 16px; padding: 4px; border-radius: 6px; }
.modal-body { padding: 20px; display: flex; flex-direction: column; gap: 12px; max-height: 70vh; overflow-y: auto; }
.modal-footer { display: flex; justify-content: flex-end; gap: 8px; padding: 16px 20px; border-top: 1px solid #f1f5f9; }

.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.form-group { display: flex; flex-direction: column; gap: 5px; }
.form-label { font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; }
.form-input { border: 1px solid #e2e8f0; border-radius: 8px; padding: 9px 12px; font-size: 13px; color: #1e293b; font-family: inherit; outline: none; background: #f8fafc; }
.form-input:focus { border-color: #93c5fd; background: #fff; }
.coord-hint { display: flex; align-items: center; gap: 6px; font-size: 11.5px; color: #94a3b8; background: #f8fafc; padding: 8px 12px; border-radius: 8px; }

.modal-enter-active, .modal-leave-active { transition: opacity 0.2s; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
</style>
