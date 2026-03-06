<script setup lang="ts">
import { ref } from 'vue'
import { useNotificationsStore, type NotificationTarget } from '../../stores/notifications'

const notificationsStore = useNotificationsStore()

const title = ref('')
const message = ref('')
const target = ref<NotificationTarget>('applicants')

function handleSubmit() {
  if (!title.value.trim() || !message.value.trim()) {
    return
  }

  notificationsStore.sendNotification(title.value, message.value, target.value)

  title.value = ''
  message.value = ''
}
</script>

<template>
  <section class="layout">
    <form class="form" @submit.prevent="handleSubmit">
      <h2 class="panel-title">
        Send notification
      </h2>

      <label class="field">
        <span class="field-label">Audience</span>
        <select v-model="target" class="field-input">
          <option value="applicants">
            Job seekers (Applicants)
          </option>
          <option value="employers">
            Employers
          </option>
          <option value="all">
            Both Applicants and Employers
          </option>
        </select>
      </label>

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
        <span class="field-label">Message</span>
        <textarea
          v-model="message"
          class="field-input"
          rows="4"
          required
        />
      </label>

      <button class="primary" type="submit">
        Send notification
      </button>
    </form>

    <section class="list">
      <header class="list-header">
        <h2 class="panel-title">
          Sent notifications
        </h2>
        <button
          v-if="notificationsStore.notifications.length"
          class="ghost"
          type="button"
          @click="notificationsStore.clearAll()"
        >
          Clear all
        </button>
      </header>

      <table class="table">
        <thead>
          <tr>
            <th>Title</th>
            <th>Audience</th>
            <th>Message</th>
            <th>Sent at</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="notificationsStore.notifications.length === 0">
            <td colspan="4" class="empty">
              No notifications sent yet.
            </td>
          </tr>
          <tr
            v-for="item in notificationsStore.notifications"
            :key="item.id"
          >
            <td>{{ item.title }}</td>
            <td>{{ item.target.toUpperCase() }}</td>
            <td class="message-cell">
              {{ item.message }}
            </td>
            <td>
              {{ new Date(item.createdAt).toLocaleString() }}
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
  grid-template-columns: minmax(0, 1.15fr) minmax(0, 2fr);
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

.list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.ghost {
  border-radius: 999px;
  border: 1px solid rgba(148, 163, 184, 0.8);
  padding: 0.25rem 0.75rem;
  background: none;
  color: #e5e7eb;
  font-size: 0.78rem;
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

.message-cell {
  max-width: 300px;
}

.empty {
  text-align: center;
  color: #6b7280;
}

@media (max-width: 900px) {
  .layout {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>

