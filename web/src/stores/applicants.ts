import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { useAuthStore } from './auth'
import { useAuditLogsStore } from './auditLogs'

export type ApplicantStatus = 'hired' | 'not-hired'

export interface Applicant {
  id: number
  name: string
  email: string
  phone?: string
  desiredPosition: string
  resumeUrl?: string
  notes?: string
  status: ApplicantStatus
  createdAt: string
}

const initialApplicants: Applicant[] = [
  {
    id: 1,
    name: 'Juan Dela Cruz',
    email: 'juan.delacruz@example.com',
    phone: '0917 123 4567',
    desiredPosition: 'Customer Service Representative',
    status: 'not-hired',
    resumeUrl: '',
    notes: 'Walk-in applicant from local job fair.',
    createdAt: new Date().toISOString(),
  },
  {
    id: 2,
    name: 'Maria Santos',
    email: 'maria.santos@example.com',
    phone: '0918 456 7890',
    desiredPosition: 'Office Staff',
    status: 'hired',
    resumeUrl: '',
    notes: 'Shortlisted by ABC Corporation.',
    createdAt: new Date().toISOString(),
  },
]

export interface ApplicantPayload {
  name: string
  email: string
  phone?: string
  desiredPosition: string
  resumeUrl?: string
  notes?: string
  status?: ApplicantStatus
}

export const useApplicantsStore = defineStore('applicants', () => {
  const applicants = ref<Applicant[]>([...initialApplicants])

  const total = computed(() => applicants.value.length)
  const hiredCount = computed(
    () => applicants.value.filter((a) => a.status === 'hired').length,
  )
  const notHiredCount = computed(
    () => applicants.value.filter((a) => a.status === 'not-hired').length,
  )

  function addApplicant(payload: ApplicantPayload) {
    const now = new Date()
    const applicant: Applicant = {
      id: now.getTime(),
      name: payload.name.trim(),
      email: payload.email.trim(),
      phone: payload.phone?.trim(),
      desiredPosition: payload.desiredPosition.trim(),
      resumeUrl: payload.resumeUrl?.trim(),
      notes: payload.notes?.trim(),
      status: payload.status ?? 'not-hired',
      createdAt: now.toISOString(),
    }

    applicants.value.push(applicant)

    const authStore = useAuthStore()
    const auditStore = useAuditLogsStore()
    auditStore.addEntry({
      action: 'create',
      entityType: 'applicant',
      entityId: String(applicant.id),
      description: `Created applicant "${applicant.name}"`,
      performedBy: authStore.user?.name ?? 'System',
    })
  }

  function updateApplicant(id: number, updates: Partial<ApplicantPayload>) {
    const index = applicants.value.findIndex((a) => a.id === id)
    if (index === -1) return

    const before = applicants.value[index]
    const updated: Applicant = {
      ...before,
      ...updates,
      name: updates.name !== undefined ? updates.name.trim() : before.name,
      email: updates.email !== undefined ? updates.email.trim() : before.email,
      phone: updates.phone !== undefined ? updates.phone.trim() : before.phone,
      desiredPosition:
        updates.desiredPosition !== undefined
          ? updates.desiredPosition.trim()
          : before.desiredPosition,
      resumeUrl:
        updates.resumeUrl !== undefined
          ? updates.resumeUrl.trim()
          : before.resumeUrl,
      notes:
        updates.notes !== undefined ? updates.notes.trim() : before.notes,
      status: updates.status ?? before.status,
    }

    applicants.value[index] = updated

    const authStore = useAuthStore()
    const auditStore = useAuditLogsStore()
    auditStore.addEntry({
      action: 'update',
      entityType: 'applicant',
      entityId: String(updated.id),
      description: `Updated applicant "${updated.name}"`,
      performedBy: authStore.user?.name ?? 'System',
    })
  }

  function setStatus(id: number, status: ApplicantStatus) {
    updateApplicant(id, { status })
  }

  return {
    applicants,
    total,
    hiredCount,
    notHiredCount,
    addApplicant,
    updateApplicant,
    setStatus,
  }
})

