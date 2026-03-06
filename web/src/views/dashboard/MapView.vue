<script setup lang="ts">
import { computed } from 'vue'
import { useEventsStore } from '../../stores/events'
import { useEmployersStore } from '../../stores/employers'

const eventsStore = useEventsStore()
const employersStore = useEmployersStore()

interface MapMarker {
  id: string
  label: string
  type: 'event' | 'job'
  latitude: number
  longitude: number
}

const markers = computed<MapMarker[]>(() => {
  const items: MapMarker[] = []

  for (const event of eventsStore.activeEvents) {
    if (typeof event.latitude === 'number' && typeof event.longitude === 'number') {
      items.push({
        id: `event-${event.id}`,
        label: event.title,
        type: 'event',
        latitude: event.latitude,
        longitude: event.longitude,
      })
    }
  }

  for (const employer of employersStore.employers) {
    for (const job of employer.jobs) {
      if (typeof job.latitude === 'number' && typeof job.longitude === 'number') {
        items.push({
          id: `job-${job.id}`,
          label: `${job.title} · ${employer.name}`,
          type: 'job',
          latitude: job.latitude,
          longitude: job.longitude,
        })
      }
    }
  }

  return items
})

const bounds = computed(() => {
  if (markers.value.length === 0) {
    return null
  }

  let minLat = markers.value[0].latitude
  let maxLat = markers.value[0].latitude
  let minLng = markers.value[0].longitude
  let maxLng = markers.value[0].longitude

  for (const marker of markers.value) {
    minLat = Math.min(minLat, marker.latitude)
    maxLat = Math.max(maxLat, marker.latitude)
    minLng = Math.min(minLng, marker.longitude)
    maxLng = Math.max(maxLng, marker.longitude)
  }

  const padding = 0.02

  return {
    minLat: minLat - padding,
    maxLat: maxLat + padding,
    minLng: minLng - padding,
    maxLng: maxLng + padding,
  }
})

function markerStyle(marker: MapMarker) {
  if (!bounds.value) {
    return {}
  }

  const { minLat, maxLat, minLng, maxLng } = bounds.value

  const latRange = maxLat - minLat || 1
  const lngRange = maxLng - minLng || 1

  const topPercent = 100 - ((marker.latitude - minLat) / latRange) * 100
  const leftPercent = ((marker.longitude - minLng) / lngRange) * 100

  return {
    top: `${topPercent}%`,
    left: `${leftPercent}%`,
  }
}
</script>

<template>
  <section class="panel">
    <header class="panel-header">
      <div>
        <h2 class="panel-title">
          Map
        </h2>
        <p class="panel-subtitle">
          Visual overview of jobs and events with mapped coordinates.
        </p>
      </div>
    </header>

    <div v-if="markers.length === 0" class="empty">
      No markers to display yet. Add latitude/longitude to events or jobs to see them on the map.
    </div>
    <div v-else class="map">
      <div class="map-grid">
        <div class="grid-line horizontal" />
        <div class="grid-line horizontal" />
        <div class="grid-line vertical" />
        <div class="grid-line vertical" />
      </div>

      <div
        v-for="marker in markers"
        :key="marker.id"
        class="marker"
        :class="marker.type === 'event' ? 'marker--event' : 'marker--job'"
        :style="markerStyle(marker)"
      >
        <div class="marker-dot" />
        <div class="marker-label">
          {{ marker.label }}
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.panel {
  border-radius: 1rem;
  padding: 1.25rem 1.25rem 1rem;
  background-color: #ffffff;
  border: 1px solid #e5e7eb;
  box-shadow: 0 16px 30px rgba(15, 23, 42, 0.06);
  color: #0f172a;
}

.panel-header {
  margin-bottom: 0.75rem;
}

.panel-title {
  margin: 0;
  font-size: 1.1rem;
  font-weight: 600;
}

.panel-subtitle {
  margin: 0.15rem 0 0;
  font-size: 0.8rem;
  color: #64748b;
}

.map {
  position: relative;
  height: 420px;
  border-radius: 1rem;
  background-color: #ffffff;
  border: 2px solid #ffffff;
  overflow: hidden;
  box-shadow:
    inset 0 0 0 1px #000000,
    0 0 0 1px #000000;
}

.map-grid {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.grid-line {
  position: absolute;
  background-color: rgba(0, 0, 0, 0.65);
}

.grid-line.horizontal {
  left: 0;
  right: 0;
  height: 1px;
}

.grid-line.horizontal:first-of-type {
  top: 33%;
}

.grid-line.horizontal:last-of-type {
  top: 66%;
}

.grid-line.vertical {
  top: 0;
  bottom: 0;
  width: 1px;
}

.grid-line.vertical:first-of-type {
  left: 33%;
}

.grid-line.vertical:last-of-type {
  left: 66%;
}

.marker {
  position: absolute;
  transform: translate(-50%, -50%);
  display: flex;
  align-items: center;
  gap: 0.3rem;
}

.marker-dot {
  width: 10px;
  height: 10px;
  border-radius: 999px;
  box-shadow: 0 0 0 6px rgba(34, 197, 94, 0.25);
}

.marker--event .marker-dot {
  background: radial-gradient(circle at 30% 30%, #f59e0b, #fbbf24);
}

.marker--job .marker-dot {
  background: radial-gradient(circle at 30% 30%, #0ea5e9, #2563eb);
  box-shadow: 0 0 0 6px rgba(59, 130, 246, 0.3);
}

.marker-label {
  max-width: 220px;
  padding: 0.25rem 0.45rem;
  border-radius: 0.65rem;
  background-color: #0f172a;
  border: 1px solid #000000;
  font-size: 0.76rem;
  color: #e5e7eb;
  backdrop-filter: blur(6px);
}

.empty {
  padding: 1.5rem 1rem;
  border-radius: 0.85rem;
  border: 1px dashed #000000;
  background-color: #ffffff;
  color: #6b7280;
  font-size: 0.85rem;
}
</style>

