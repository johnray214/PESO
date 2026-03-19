import { defineStore } from 'pinia'
import employerApi from '@/services/employerApi'

const AVATAR_COLORS = [
  '#2563eb','#f97316','#22c55e','#06b6d4',
  '#a855f7','#ef4444','#3b82f6','#14b8a6',
  '#6366f1','#f43f5e',
]

export const useEmployerApplicantsStore = defineStore('employerApplicants', {
  state: () => ({
    applicants: [],
    potentialApplicants: [],
    loaded: false,
    loading: false,
  }),

  getters: {
    totalApplicants:  (state) => state.applicants.length,
    totalPotential:   (state) => state.potentialApplicants.length,
    reviewingCount:   (state) => state.applicants.filter((a) => a.status === 'Reviewing').length,
    shortlistedCount: (state) => state.applicants.filter((a) => a.status === 'Shortlisted').length,
    interviewCount:   (state) => state.applicants.filter((a) => a.status === 'Interview').length,
    hiredCount:       (state) => state.applicants.filter((a) => a.status === 'Hired').length,
    rejectedCount:    (state) => state.applicants.filter((a) => a.status === 'Rejected').length,
  },

  actions: {
    async fetch() {
      if (this.loaded || this.loading) return

      // load from cache first so data shows instantly on reload
      const cachedApplicants = localStorage.getItem('employer_applicants')
      const cachedPotential  = localStorage.getItem('employer_potential_applicants')
      if (cachedApplicants) {
        try { this.applicants = JSON.parse(cachedApplicants) } catch { this.applicants = [] }
      }
      if (cachedPotential) {
        try { this.potentialApplicants = JSON.parse(cachedPotential) } catch { this.potentialApplicants = [] }
      }

      await this._load()
    },

    async refresh() {
      this.loaded = false
      await this._load()
    },

    async _load() {
      this.loading = true
      try {
        const [appRes, potRes] = await Promise.all([
          employerApi.getApplications(),
          employerApi.getPotentialApplicants(),
        ])

        const apps = appRes.data.data?.data || appRes.data.data || []
        this.applicants = apps.map((a, i) => {
          const js     = a.jobseeker || {}
          const skills = Array.isArray(js.skills) ? js.skills : []
          return {
            id:         a.id,
            name:       js.full_name  || 'Unknown',
            location:   js.address    || 'Unknown',
            contact:    js.contact    || '',
            email:      js.email      || '',
            education:  js.education  || '',
            experience: js.experience || '',
            skills,
            jobApplied: a.job_listing?.title || 'Unknown Position',
            date:       new Date(a.applied_at).toLocaleDateString('en-US', { month: 'short', day: '2-digit', year: 'numeric' }),
            matchScore: a.match_score || 0,
            status:     (a.status?.charAt(0).toUpperCase() + a.status?.slice(1)) || 'Reviewing',
            avatarBg:   AVATAR_COLORS[i % AVATAR_COLORS.length],
            notes:      a.notes || '',
          }
        })
        // save to cache
        localStorage.setItem('employer_applicants', JSON.stringify(this.applicants))

        const potential = potRes.data.data?.data || potRes.data.data || []
        this.potentialApplicants = potential.map((a, i) => {
          const skillsData = a.skills || []
          const skills = Array.isArray(skillsData)
            ? (typeof skillsData[0] === 'string' ? skillsData : skillsData.map((s) => s.skill || s))
            : []
          return {
            id:        a.id,
            name:      a.full_name || `${a.first_name || ''} ${a.last_name || ''}`.trim() || 'Unknown',
            color:     AVATAR_COLORS[i % AVATAR_COLORS.length],
            score:     Math.round(a.match_score || 70),
            bestFor:   a.best_job_match || '',
            jobColor:  AVATAR_COLORS[i % AVATAR_COLORS.length],
            skills,
            location:  a.address   || 'Unknown',
            education: a.education || 'Not specified',
            invited:   false,
          }
        })
        // save to cache
        localStorage.setItem('employer_potential_applicants', JSON.stringify(this.potentialApplicants))

        this.loaded = true
      } catch (e) {
        console.error('[ApplicantsStore] fetch error:', e)
      } finally {
        this.loading = false
      }
    },

    async updateStatus(applicantId, newStatus) {
      const item = this.applicants.find((a) => a.id === applicantId)
      const prevStatus = item?.status
      if (item) item.status = newStatus
      try {
        await employerApi.updateApplicationStatus(applicantId, newStatus.toLowerCase())
        // update cache after status change
        localStorage.setItem('employer_applicants', JSON.stringify(this.applicants))
      } catch (e) {
        if (item && prevStatus) item.status = prevStatus
        localStorage.setItem('employer_applicants', JSON.stringify(this.applicants))
        console.error('[ApplicantsStore] updateStatus error:', e)
        throw e
      }
    },

    markInvited(applicantId) {
      const item = this.potentialApplicants.find((a) => a.id === applicantId)
      if (item) {
        item.invited = true
        localStorage.setItem('employer_potential_applicants', JSON.stringify(this.potentialApplicants))
      }
    },
  },
})