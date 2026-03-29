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
    counts: { applicants: 0, potential: 0 },
    loaded: false,
    loading: false,
  }),

  getters: {
    totalApplicants:  (state) => state.applicants.length || state.counts.applicants,
    totalPotential:   (state) => state.potentialApplicants.length || state.counts.potential,
    reviewingCount:   (state) => state.applicants.filter((a) => a.status === 'Reviewing').length,
    shortlistedCount: (state) => state.applicants.filter((a) => a.status === 'Shortlisted').length,
    interviewCount:   (state) => state.applicants.filter((a) => a.status === 'Interview').length,
    hiredCount:       (state) => state.applicants.filter((a) => a.status === 'Hired').length,
    rejectedCount:    (state) => state.applicants.filter((a) => a.status === 'Rejected').length,
  },

  actions: {
    async fetch() {
      if (this.loading) return

      // Load counts from cache for initial render
      const cachedCounts = localStorage.getItem('employer_applicants_counts')
      if (cachedCounts) {
        try {
          this.counts = JSON.parse(cachedCounts)
        } catch {
          this.counts = { applicants: 0, potential: 0 }
        }
      }

      if (this.loaded) return
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
        const potential = potRes.data.data?.data || potRes.data.data || []

        this.applicants = apps.map((a, i) => {
          const js     = a.jobseeker || {}
          const skills = Array.isArray(js.skills) ? js.skills : []
          return {
            id:         a.id,
            name:       js.full_name  || 'Unknown',
            location:   js.address    || 'Unknown',
            contact:    js.contact    || '',
            email:      js.email      || '',
            education:  js.education_level  || '',
            experience: js.job_experience  || '',
            skills,
            jobApplied: a.job_listing?.title || 'Unknown Position',
            date:       new Date(a.applied_at).toLocaleDateString('en-US', { month: 'short', day: '2-digit', year: 'numeric' }),
            matchScore: a.match_score || 0,
            status:     (a.status?.charAt(0).toUpperCase() + a.status?.slice(1)) || 'Reviewing',
            avatarBg:   AVATAR_COLORS[i % AVATAR_COLORS.length],
            notes:      a.notes || '',
            hasResume:  !!js.has_resume,
          }
        })
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
            jobId:     a.best_job_id || null,
            jobColor:  AVATAR_COLORS[i % AVATAR_COLORS.length],
            skills,
            location:  a.address   || 'Unknown',
              education: a.education_level || 'Not specified',
              experience: a.job_experience || '',
            invited:   false,
          }
        })

        // Update counts and save minimum data to cache
        this.counts.applicants = apps.length
        this.counts.potential = potential.length
        localStorage.setItem('employer_applicants_counts', JSON.stringify(this.counts));

        this.loaded = true
      } catch (e) {
        console.error('[ApplicantsStore] fetch error:', e)
      } finally {
        this.loading = false
      }
    },

    async updateStatus(applicantId, newStatus, extraData = {}) {
      const item = this.applicants.find((a) => a.id === applicantId)
      const prevStatus = item?.status
      if (item) item.status = newStatus
      try {
        await employerApi.updateApplicationStatus(applicantId, newStatus.toLowerCase(), extraData)
      } catch (e) {
        if (item && prevStatus) item.status = prevStatus
        console.error('[ApplicantsStore] updateStatus error:', e)
        throw e
      }
    },

    markInvited(applicantId) {
      const item = this.potentialApplicants.find((a) => a.id === applicantId)
      if (item) {
        item.invited = true
      }
    },
  },
})