<script setup lang="ts">
import { computed, ref } from 'vue'
import { useAuditLogsStore } from '../../stores/auditLogs'

const auditLogsStore = useAuditLogsStore()

const search = ref('')
const actionFilter = ref('')
const entityFilter = ref('')

const filteredEntries = computed(() => {
  const term = search.value.trim().toLowerCase()
  return auditLogsStore.entries.filter((entry) => {
    if (actionFilter.value && entry.action !== actionFilter.value) {
      return false
    }

    if (entityFilter.value && entry.entityType !== entityFilter.value) {
      return false
    }

    if (!term) {
      return true
    }

    return (
      entry.description.toLowerCase().includes(term)
      || entry.performedBy.toLowerCase().includes(term)
      || entry.entityType.toLowerCase().includes(term)
    )
  })
})

const uniqueActions = computed(() =>
  Array.from(new Set(auditLogsStore.entries.map((entry) => entry.action))),
)

const uniqueEntities = computed(() =>
  Array.from(new Set(auditLogsStore.entries.map((entry) => entry.entityType))),
)
</script>

<template>
  <section class="panel">
    <header class="panel-header">
      <div>
        <h2 class="panel-title">
          Audit logs
        </h2>
        <p class="panel-subtitle">
          Track who created, edited, deleted, restored items and sent notifications.
        </p>
      </div>

      <div class="filters">
        <input
          v-model="search"
          type="search"
          class="search"
          placeholder="Search description or user"
        />
        <select v-model="actionFilter" class="filter-select">
          <option value="">
            All actions
          </option>
          <option
            v-for="action in uniqueActions"
            :key="action"
            :value="action"
          >
            {{ action }}
          </option>
        </select>
        <select v-model="entityFilter" class="filter-select">
          <option value="">
            All entities
          </option>
          <option
            v-for="entity in uniqueEntities"
            :key="entity"
            :value="entity"
          >
            {{ entity }}
          </option>
        </select>
      </div>
    </header>

    <table class="table">
      <thead>
        <tr>
          <th>Time</th>
          <th>User</th>
          <th>Action</th>
          <th>Entity</th>
          <th>Description</th>
        </tr>
      </thead>
      <tbody>
        <tr v-if="filteredEntries.length === 0">
          <td colspan="5" class="empty">
            No audit entries yet.
          </td>
        </tr>
        <tr
          v-for="entry in filteredEntries"
          :key="entry.id"
        >
          <td>{{ new Date(entry.createdAt).toLocaleString() }}</td>
          <td>{{ entry.performedBy }}</td>
          <td>{{ entry.action }}</td>
          <td>{{ entry.entityType }}</td>
          <td>{{ entry.description }}</td>
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
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  gap: 1rem;
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

.filters {
  display: flex;
  gap: 0.5rem;
}

.search,
.filter-select {
  padding: 0.45rem 0.65rem;
  border-radius: 0.75rem;
  border: 1px solid #cbd5f5;
  background-color: #f9fafb;
  color: #0f172a;
  font-size: 0.85rem;
}

.search::placeholder {
  color: #9ca3af;
}

.table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.8rem;
}

th,
td {
  padding: 0.55rem 0.75rem;
  border-bottom: 1px solid #e5e7eb;
}

th {
  text-align: left;
  font-weight: 500;
  color: #64748b;
  background-color: #eff6ff;
}

tbody tr:nth-child(odd) td {
  background-color: #ffffff;
}

tbody tr:nth-child(even) td {
  background-color: #f9fafb;
}

.empty {
  text-align: center;
  color: #9ca3af;
}

@media (max-width: 900px) {
  .panel-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .filters {
    width: 100%;
    flex-direction: column;
  }
}
</style>

