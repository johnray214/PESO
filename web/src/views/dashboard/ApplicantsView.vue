<script setup lang="ts">
import { computed, ref } from 'vue'
import { useApplicantsStore, type Applicant } from '../../stores/applicants'
import { useEmployersStore } from '../../stores/employers'

const applicantsStore = useApplicantsStore()
const employersStore = useEmployersStore()

const search = ref('')
const statusFilter = ref<'all' | 'hired' | 'not-hired'>('all')
const selected = ref<{ mode: 'view' | 'edit'; applicant: Applicant } | null>(null)

const editableApplicant = ref<Partial<Applicant>>({})

const filteredApplicants = computed(() => {
  const term = search.value.trim().toLowerCase()
  return applicantsStore.applicants.filter((applicant) => {
    if (statusFilter.value !== 'all' && applicant.status !== statusFilter.value) {
      return false
    }

    if (!term) {
      return true
    }

    return (
      applicant.name.toLowerCase().includes(term)
      || applicant.email.toLowerCase().includes(term)
      || applicant.desiredPosition.toLowerCase().includes(term)
    )
  })
})

function openDetails(applicant: Applicant, mode: 'view' | 'edit') {
  selected.value = { mode, applicant }
  editableApplicant.value = { ...applicant }
}

function closeDetails() {
  selected.value = null
}

function saveApplicant() {
  const current = selected.value
  if (!current) return

  applicantsStore.updateApplicant(current.applicant.id, {
    name: editableApplicant.value.name,
    email: editableApplicant.value.email,
    phone: editableApplicant.value.phone,
    desiredPosition: editableApplicant.value.desiredPosition,
    notes: editableApplicant.value.notes,
  })

  closeDetails()
}

function toggleHired(applicant: Applicant) {
  const nextStatus = applicant.status === 'hired' ? 'not-hired' : 'hired'
  applicantsStore.setStatus(applicant.id, nextStatus)
}

const jobOptions = computed(() => {
  const options: { label: string; jobId: number }[] = []
  for (const employer of employersStore.employers) {
    for (const job of employer.jobs) {
      options.push({
        label: `${job.title} · ${employer.name}`,
        jobId: job.id,
      })
    }
  }
  return options
})

const hireJobId = ref<number | null>(null)

function hireForJob(applicant: Applicant) {
  if (!hireJobId.value) return
  employersStore.markApplicantHired(hireJobId.value, applicant.id)
  hireJobId.value = null
}
</script>

<template>
  <section class="panel">
    <header class="panel-header">
      <div>
        <h2 class="panel-title">
          Applicants
        </h2>
        <p class="panel-subtitle">
          View and update applicant profiles, hiring status, and job placements.
        </p>
      </div>

      <div class="filters">
        <input
          v-model="search"
          type="search"
          class="search"
          placeholder="Search by name, email, or position"
        />
        <select v-model="statusFilter" class="status-filter">
          <option value="all">
            All statuses
          </option>
          <option value="not-hired">
            Not hired
          </option>
          <option value="hired">
            Hired
          </option>
        </select>
      </div>
    </header>

    <div class="table-wrapper">
      <table class="table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Position</th>
            <th>Status</th>
            <th>Email</th>
            <th>Phone</th>
            <th />
          </tr>
        </thead>
        <tbody>
          <tr v-if="filteredApplicants.length === 0">
            <td colspan="6" class="empty-state">
              No applicants found.
            </td>
          </tr>

          <tr
            v-for="applicant in filteredApplicants"
            :key="applicant.id"
          >
            <td>{{ applicant.name }}</td>
            <td>{{ applicant.desiredPosition }}</td>
            <td>
              <span
                class="badge"
                :class="{
                  'badge--hired': applicant.status === 'hired',
                  'badge--not-hired': applicant.status === 'not-hired',
                }"
              >
                {{ applicant.status === 'hired' ? 'Hired' : 'Not Hired' }}
              </span>
            </td>
            <td>{{ applicant.email }}</td>
            <td>{{ applicant.phone || '—' }}</td>
            <td class="actions">
              <button
                type="button"
                class="link-btn"
                @click="openDetails(applicant, 'view')"
              >
                View
              </button>
              <button
                type="button"
                class="link-btn"
                @click="openDetails(applicant, 'edit')"
              >
                Edit
              </button>
              <button
                type="button"
                class="link-btn"
                @click="toggleHired(applicant)"
              >
                {{ applicant.status === 'hired' ? 'Mark Not Hired' : 'Mark Hired' }}
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="selected" class="drawer-backdrop" @click.self="closeDetails">
      <div class="drawer">
        <header class="drawer-header">
          <h3 class="drawer-title">
            Applicant details
          </h3>
          <button class="close-btn" type="button" @click="closeDetails">
            ✕
          </button>
        </header>

        <section v-if="selected?.mode === 'view'" class="drawer-body">
          <p><strong>Name:</strong> {{ selected?.applicant.name }}</p>
          <p><strong>Email:</strong> {{ selected?.applicant.email }}</p>
          <p>
            <strong>Desired position:</strong>
            {{ selected?.applicant.desiredPosition }}
          </p>
          <p><strong>Phone:</strong> {{ selected?.applicant.phone || '—' }}</p>
          <p><strong>Status:</strong> {{ selected?.applicant.status === 'hired' ? 'Hired' : 'Not Hired' }}</p>
          <p><strong>Notes:</strong> {{ selected?.applicant.notes || '—' }}</p>
          <p><strong>Resume:</strong> {{ selected?.applicant.resumeUrl || 'No file linked' }}</p>
        </section>

        <section v-else class="drawer-body">
          <label class="field">
            <span class="field-label">Name</span>
            <input
              v-model="editableApplicant.name"
              class="field-input"
              type="text"
            />
          </label>

          <label class="field">
            <span class="field-label">Email</span>
            <input
              v-model="editableApplicant.email"
              class="field-input"
              type="email"
            />
          </label>

          <label class="field">
            <span class="field-label">Phone</span>
            <input
              v-model="editableApplicant.phone"
              class="field-input"
              type="tel"
            />
          </label>

          <label class="field">
            <span class="field-label">Desired position</span>
            <input
              v-model="editableApplicant.desiredPosition"
              class="field-input"
              type="text"
            />
          </label>

          <label class="field">
            <span class="field-label">Notes</span>
            <textarea
              v-model="editableApplicant.notes"
              class="field-input"
              rows="3"
            />
          </label>

          <label class="field">
            <span class="field-label">Resume link</span>
            <input
              v-model="editableApplicant.resumeUrl"
              class="field-input"
              type="url"
              placeholder="https://..."
            />
          </label>
        </section>

        <footer class="drawer-footer">
          <div class="drawer-footer-row">
            <select v-model="hireJobId" class="assign-select">
              <option :value="null">
                Assign to job…
              </option>
              <option
                v-for="option in jobOptions"
                :key="option.jobId"
                :value="option.jobId"
              >
                {{ option.label }}
              </option>
            </select>
            <button
              class="capsule-btn"
              type="button"
              :disabled="!hireJobId"
              @click="selected && hireForJob(selected.applicant)"
            >
              Mark Hired
            </button>
          </div>

          <div v-if="selected?.mode === 'edit'" class="drawer-footer-actions">
            <button class="primary capsule-btn" type="button" @click="saveApplicant">
              Save changes
            </button>
            <button class="ghost capsule-btn" type="button" @click="closeDetails">
              Cancel
            </button>
          </div>
        </footer>
      </div>
    </div>
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
.status-filter {
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

.table-wrapper {
  border-radius: 0.9rem;
  border: 1px solid #dbeafe;
  overflow: hidden;
  background-color: #ffffff;
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

.empty-state {
  text-align: center;
  color: #9ca3af;
}

.badge {
  display: inline-flex;
  align-items: center;
  padding: 0.15rem 0.5rem;
  border-radius: 999px;
  font-size: 0.7rem;
}

.badge--hired {
  background-color: rgba(34, 197, 94, 0.12);
  color: #15803d;
}

.badge--not-hired {
  background-color: rgba(248, 113, 113, 0.12);
  color: #b91c1c;
}

.actions {
  display: flex;
  gap: 0.35rem;
  justify-content: flex-end;
}

.link-btn {
  border: none;
  background: none;
  color: #1565c0;
  font-size: 0.75rem;
  cursor: pointer;
  padding: 0;
}

.link-btn:hover {
  text-decoration: underline;
}

.drawer-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.85);
  display: flex;
  justify-content: flex-end;
  z-index: 40;
}

.drawer {
  width: 380px;
  max-width: 100%;
  height: 100vh;
  max-height: 100vh;
  background-color: #ffffff;
  border-left: 1px solid #e5e7eb;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.drawer-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}

.drawer-title {
  margin: 0;
  font-size: 1rem;
  font-weight: 600;
}

.close-btn {
  border: none;
  background: none;
  color: #9ca3af;
  font-size: 1.1rem;
  cursor: pointer;
}

.drawer-body {
  flex: 1;
  min-height: 0;
  overflow: auto;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  font-size: 0.85rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.field-label {
  font-size: 0.78rem;
  color: #6b7280;
}

.field-input {
  padding: 0.4rem 0.55rem;
  border-radius: 0.6rem;
  border: 1px solid #cbd5f5;
  background-color: #f9fafb;
  color: #0f172a;
  font-size: 0.8rem;
}

.drawer-footer {
  margin-top: 0.75rem;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.drawer-footer-row {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.assign-select {
  flex: 0 1 140px;
  min-width: 0;
  padding: 0.4rem 0.6rem;
  border-radius: 999px;
  border: 1px solid #d1d5db;
  background-color: #f9fafb;
  color: #0f172a;
  font-size: 0.8rem;
  font-family: inherit;
}

.capsule-btn {
  border-radius: 999px;
  font-size: 0.8rem;
  padding: 0.4rem 0.75rem;
  cursor: pointer;
  white-space: nowrap;
}

.drawer-footer-actions {
  display: flex;
  gap: 0.5rem;
  margin-top: auto;
}

.primary {
  border: 1px solid transparent;
  background: linear-gradient(135deg, #1565c0, #0d47a1);
  color: #ecfeff;
}

.primary.capsule-btn:disabled,
.capsule-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.capsule-btn:not(.primary):not(.ghost) {
  background-color: #0f172a;
  border: 1px solid #0f172a;
  color: #f9fafb;
}

.capsule-btn:not(.primary):not(.ghost):hover:not(:disabled) {
  background-color: #1e293b;
  border-color: #1e293b;
}

.ghost {
  background: none;
  border: 1px solid #d1d5db;
  color: #6b7280;
}

@media (max-width: 800px) {
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

