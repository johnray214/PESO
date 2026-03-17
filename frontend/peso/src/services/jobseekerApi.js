import api from './api'

export const jobseekerApi = {
  // Profile
  getProfile: () => api.get('/jobseeker/profile'),
  updateProfile: (data) => api.put('/jobseeker/profile', data),
  changePassword: (data) => api.post('/jobseeker/profile/password', data),
  uploadResume: (formData) => api.post('/jobseeker/profile/resume', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  }),

  // Job Listings
  getJobs: (params) => api.get('/jobseeker/jobs', { params }),
  getJob: (id) => api.get(`/jobseeker/jobs/${id}`),

  // Applications
  getApplications: (params) => api.get('/jobseeker/applications', { params }),
  getApplication: (id) => api.get(`/jobseeker/applications/${id}`),
  applyForJob: (jobListingId) => api.post('/jobseeker/applications', { job_listing_id: jobListingId }),
  withdrawApplication: (id) => api.delete(`/jobseeker/applications/${id}`),

  // Notifications
  getNotifications: (params) => api.get('/jobseeker/notifications', { params }),
  getNotification: (id) => api.get(`/jobseeker/notifications/${id}`),
  getUnreadCount: () => api.get('/jobseeker/notifications/unread-count'),
  markAllAsRead: () => api.post('/jobseeker/notifications/mark-all-read'),
}

export default jobseekerApi
