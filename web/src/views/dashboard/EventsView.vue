<script setup lang="ts">
import { ref } from 'vue'
import { useEventsStore, type EventItem } from '../../stores/events'

const eventsStore = useEventsStore()

const title = ref('')
const description = ref('')
const date = ref(new Date().toISOString().slice(0, 10))
const location = ref('')
const latitude = ref<string | ''>('')
const longitude = ref<string | ''>('')

function handleCreate() {
  if (!title.value.trim() || !date.value || !location.value.trim()) {
    return
  }

  eventsStore.createEvent({
    title: title.value,
    description: description.value,
    date: date.value,
    location: location.value,
    latitude: latitude.value ? Number.parseFloat(latitude.value) : undefined,
    longitude: longitude.value ? Number.parseFloat(longitude.value) : undefined,
  })

  title.value = ''
  description.value = ''
  location.value = ''
  latitude.value = ''
  longitude.value = ''
}

function handleSoftDelete(event: EventItem) {
  eventsStore.softDeleteEvent(event.id)
}
</script>

<template>
  <section class="layout">
    <form class="form" @submit.prevent="handleCreate">
      <h2 class="panel-title">
        Create event
      </h2>

      <label class="field">
        <span class="field-label">Title</span>
        <input
          v-model="title"
          class="field-input"
          type="text"
          required
        />
      </label>

      <label class="field">
        <span class="field-label">Description</span>
        <textarea
          v-model="description"
          class="field-input"
          rows="3"
        />
      </label>

      <div class="field-row">
        <label class="field">
          <span class="field-label">Date</span>
          <input
            v-model="date"
            class="field-input"
            type="date"
            required
          />
        </label>

        <label class="field">
          <span class="field-label">Location</span>
          <input
            v-model="location"
            class="field-input"
            type="text"
            required
          />
        </label>
      </div>

      <div class="field-row">
        <label class="field">
          <span class="field-label">Latitude (optional)</span>
          <input
            v-model="latitude"
            class="field-input"
            type="number"
            step="0.0001"
          />
        </label>

        <label class="field">
          <span class="field-label">Longitude (optional)</span>
          <input
            v-model="longitude"
            class="field-input"
            type="number"
            step="0.0001"
          />
        </label>
      </div>

      <button class="primary" type="submit">
        Add event
      </button>
    </form>

    <section class="list">
      <h2 class="panel-title">
        Active events
      </h2>

      <table class="table">
        <thead>
          <tr>
            <th>Title</th>
            <th>Date</th>
            <th>Location</th>
            <th>Description</th>
            <th />
          </tr>
        </thead>
        <tbody>
          <tr v-if="eventsStore.activeEvents.length === 0">
            <td colspan="5" class="empty">
              No active events.
            </td>
          </tr>
          <tr
            v-for="event in eventsStore.activeEvents"
            :key="event.id"
          >
            <td>{{ event.title }}</td>
            <td>{{ event.date }}</td>
            <td>{{ event.location }}</td>
            <td>{{ event.description }}</td>
            <td class="actions">
              <button
                type="button"
                class="link-btn"
                @click="handleSoftDelete(event)"
              >
                Move to archive
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </section>
  </section>
</template>

<style scoped>
.layout {
  display: grid;
  grid-template-columns: minmax(0, 1.2fr) minmax(0, 2fr);
  gap: 1.25rem;
}

.panel-title {
  margin: 0 0 0.75rem;
  font-size: 1.05rem;
  font-weight: 600;
  color: #0f172a;
}

.form,
.list {
  border-radius: 1rem;
  padding: 1rem 1.1rem;
  background-color: #ffffff;
  border: 1px solid #dbeafe;
  box-shadow: 0 16px 30px rgba(15, 23, 42, 0.06);
  color: #0f172a;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  margin-bottom: 0.75rem;
}

.field-row {
  display: flex;
  gap: 0.75rem;
}

.field-label {
  font-size: 0.8rem;
  color: #64748b;
}

.field-input {
  padding: 0.45rem 0.6rem;
  border-radius: 0.75rem;
  border: 1px solid #cbd5f5;
  background-color: #f9fafb;
  color: #0f172a;
  font-size: 0.85rem;
}

.primary {
  margin-top: 0.25rem;
  border-radius: 0.75rem;
  border: none;
  padding: 0.5rem 0.8rem;
  font-size: 0.85rem;
  font-weight: 500;
  background: linear-gradient(135deg, #1565c0, #0d47a1);
  color: #ecfeff;
  cursor: pointer;
}

.table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.78rem;
}

th,
td {
  padding: 0.45rem 0.5rem;
  border-bottom: 1px solid #e5e7eb;
}

th {
  text-align: left;
  font-weight: 500;
  color: #64748b;
  background-color: #eff6ff;
}

.empty {
  text-align: center;
  color: #9ca3af;
}

.actions {
  text-align: right;
}

.link-btn {
  border: none;
  background: none;
  color: #cc2229;
  font-size: 0.78rem;
  cursor: pointer;
}

.link-btn:hover {
  text-decoration: underline;
}

@media (max-width: 900px) {
  .layout {
    grid-template-columns: minmax(0, 1fr);
  }

  .field-row {
    flex-direction: column;
  }
}
</style>

