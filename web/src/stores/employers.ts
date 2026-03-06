import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { useAuthStore } from './auth'
import { useAuditLogsStore } from './auditLogs'
import { useApplicantsStore } from './applicants'

export interface JobListing {
  id: number
  title: string
  description: string
  location: string
  latitude?: number
  longitude?: number
  hiredApplicantIds: number[]
}

export interface Employer {
  id: number
  name: string
  contactPerson: string
  email: string
  phone?: string
  jobs: JobListing[]
}

const initialEmployers: Employer[] = [
  {
    id: 1,
    name: 'ABC Corporation',
    contactPerson: 'Ana Manager',
    email: 'hr@abc-corp.example.com',
    phone: '0917 987 6543',
    jobs: [
      {
        id: 11,
        title: 'Customer Service Representative',
        description: 'Handle inbound calls and assist customers.',
        location: 'City Hall PESO Office',
        latitude: 14.5995,
        longitude: 120.9842,
        hiredApplicantIds: [2],
      },
    ],
  },
  {
    id: 2,
    name: 'Local Hardware Store',
    contactPerson: 'Pedro Owner',
    email: 'jobs@hardware.example.com',
    phone: '0918 222 3344',
    jobs: [
      {
        id: 21,
        title: 'Warehouse Staff',
        description: 'Assist in inventory and deliveries.',
        location: 'Barangay 5',
        latitude: 14.578,
        longitude: 121.012,
        hiredApplicantIds: [],
      },
    ],
  },
]

export const useEmployersStore = defineStore('employers', () => {
  const employers = ref<Employer[]>([...initialEmployers])

  const totalEmployers = computed(() => employers.value.length)
  const totalJobs = computed(
    () =>
      employers.value.reduce(
        (sum, employer) => sum + employer.jobs.length,
        0,
      ),
  )

  function markApplicantHired(jobId: number, applicantId: number) {
    const applicantsStore = useApplicantsStore()
    const applicant = applicantsStore.applicants.find(
      (a) => a.id === applicantId,
    )

    for (const employer of employers.value) {
      const job = employer.jobs.find((j) => j.id === jobId)
      if (!job) continue

      if (!job.hiredApplicantIds.includes(applicantId)) {
        job.hiredApplicantIds.push(applicantId)
      }

      if (applicant) {
        applicantsStore.setStatus(applicantId, 'hired')
      }

      const authStore = useAuthStore()
      const auditStore = useAuditLogsStore()
      auditStore.addEntry({
        action: 'hire',
        entityType: 'job',
        entityId: String(job.id),
        description: `Marked applicant "${applicant?.name ?? applicantId}" as hired for job "${job.title}" at ${employer.name}`,
        performedBy: authStore.user?.name ?? 'System',
      })

      break
    }
  }

  return {
    employers,
    totalEmployers,
    totalJobs,
    markApplicantHired,
  }
})

