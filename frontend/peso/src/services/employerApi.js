import api from './api'

export const employerApi = {
  // Dashboard
  getDashboard: (params) => api.get('/employer/dashboard', { params }),

  // Job Listings
  getJobs: (params) => api.get('/employer/jobs', { params }),
  getJob: (id) => api.get(`/employer/jobs/${id}`),
  createJob: (data) => api.post('/employer/jobs', data),
  updateJob: (id, data) => api.put(`/employer/jobs/${id}`, data),
  deleteJob: (id) => api.delete(`/employer/jobs/${id}`),

  // Applications
  getApplications: (params) => api.get('/employer/applications', { params }),
  /** PDF blob — use with employer token */
  downloadApplicationResume: (id) =>
    api.get(`/employer/applications/${id}/resume`, { responseType: 'blob' }),
  getApplication: (id) => api.get(`/employer/applications/${id}`),
  updateApplicationStatus: (id, status, extraData = {}) => api.patch(`/employer/applications/${id}/status`, { status, ...extraData }),
  getPotentialApplicants: (params) => api.get('/employer/potential-applicants', { params }),
  sendInvitation: (jobseekerId, jobListingId) => api.post(`/employer/invite/${jobseekerId}`, { job_listing_id: jobListingId }),

  // Notifications
  getNotifications:       (params) => api.get('/employer/notifications', { params }),
  getNotification:        (id)     => api.get(`/employer/notifications/${id}`),
  getUnreadCount:         ()       => api.get('/employer/notifications/unread-count'),
  markNotificationRead:   (id)     => api.post(`/employer/notifications/${id}/mark-read`),
  markAllAsRead:          ()       => api.post('/employer/notifications/mark-all-read'),

  // Profile
  getProfile: () => api.get('/employer/profile'),
  updateProfile: (data) => api.put('/employer/profile', data),
  changePassword: (data) => api.post('/employer/profile/password', data),
  uploadDocuments: (formData) => api.post('/employer/profile/documents', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  }),
}

export default employerApi
