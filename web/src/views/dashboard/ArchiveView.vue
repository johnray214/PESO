<script setup lang="ts">
import { useEventsStore } from '../../stores/events'

const eventsStore = useEventsStore()
</script>

<template>
  <section class="panel">
    <header class="panel-header">
      <div>
        <h2 class="panel-title">
          Archive
        </h2>
        <p class="panel-subtitle">
          Restore events that were previously deleted.
        </p>
      </div>
    </header>

    <table class="table">
      <thead>
        <tr>
          <th>Title</th>
          <th>Date</th>
          <th>Location</th>
          <th>Reason</th>
          <th />
        </tr>
      </thead>
      <tbody>
        <tr v-if="eventsStore.archivedEvents.length === 0">
          <td colspan="5" class="empty">
            No archived events.
          </td>
        </tr>

        <tr
          v-for="event in eventsStore.archivedEvents"
          :key="event.id"
        >
          <td>{{ event.title }}</td>
          <td>{{ event.date }}</td>
          <td>{{ event.location }}</td>
          <td>Soft-deleted from Events</td>
          <td class="actions">
            <button
              class="primary"
              type="button"
              @click="eventsStore.restoreEvent(event.id)"
            >
              Restore
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  </section>
</template>

<style scoped>
.panel {
  border-radius: 1rem;
  padding: 1.25rem 1.25rem 1rem;
  background-color: #ffffff;
  border: 1px solid #dbeafe;
  box-shadow: 0 16px 30px rgba(15, 23, 42, 0.06);
  color: #0f172a;
}

.panel-header {
  margin-bottom: 1rem;
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

.table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.8rem;
}

th,
td {
  padding: 0.5rem 0.65rem;
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

.primary {
  border-radius: 0.6rem;
  border: none;
  padding: 0.35rem 0.7rem;
  font-size: 0.8rem;
  font-weight: 500;
  background: linear-gradient(135deg, #1565c0, #0d47a1);
  color: #ecfeff;
  cursor: pointer;
}
</style>

