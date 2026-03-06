<script setup lang="ts">
import { useEmployersStore } from '../../stores/employers'
import { useApplicantsStore } from '../../stores/applicants'

const employersStore = useEmployersStore()
const applicantsStore = useApplicantsStore()
</script>

<template>
  <section class="panel">
    <header class="panel-header">
      <div>
        <h2 class="panel-title">
          Employers &amp; Job Listings
        </h2>
        <p class="panel-subtitle">
          Review employers, open jobs, and which applicants have been hired per job.
        </p>
      </div>
    </header>

    <div class="employers">
      <article
        v-for="employer in employersStore.employers"
        :key="employer.id"
        class="employer-card"
      >
        <header class="employer-header">
          <div>
            <h3 class="employer-name">
              {{ employer.name }}
            </h3>
            <p class="employer-contact">
              Contact: {{ employer.contactPerson }} · {{ employer.email }} ·
              {{ employer.phone || 'No phone on file' }}
            </p>
          </div>
        </header>

        <table class="jobs-table">
          <thead>
            <tr>
              <th>Job title</th>
              <th>Location</th>
              <th>Description</th>
              <th>Hired applicants</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="job in employer.jobs"
              :key="job.id"
            >
              <td>{{ job.title }}</td>
              <td>{{ job.location }}</td>
              <td>{{ job.description }}</td>
              <td>
                <span
                  v-if="job.hiredApplicantIds.length === 0"
                  class="empty"
                >
                  None
                </span>
                <ul v-else class="hired-list">
                  <li
                    v-for="id in job.hiredApplicantIds"
                    :key="id"
                  >
                    {{
                      applicantsStore.applicants.find((a) => a.id === id)?.name
                      || `Applicant #${id}`
                    }}
                  </li>
                </ul>
              </td>
            </tr>
          </tbody>
        </table>
      </article>
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

.employers {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.employer-card {
  border-radius: 0.85rem;
  border: 1px solid #dbeafe;
  background-color: #ffffff;
  padding: 0.85rem 0.9rem;
}

.employer-header {
  margin-bottom: 0.5rem;
}

.employer-name {
  margin: 0;
  font-size: 0.95rem;
  font-weight: 600;
}

.employer-contact {
  margin: 0.1rem 0 0;
  font-size: 0.78rem;
  color: #64748b;
}

.jobs-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.78rem;
  margin-top: 0.5rem;
}

th,
td {
  border-bottom: 1px solid #e5e7eb;
  padding: 0.4rem 0.5rem;
  text-align: left;
}

th {
  font-weight: 500;
  color: #64748b;
  background-color: #eff6ff;
}

.hired-list {
  margin: 0;
  padding-left: 1.1rem;
}

.empty {
  color: #9ca3af;
}
</style>

