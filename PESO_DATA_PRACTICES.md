# PESO platform — data practices (internal summary)

*Generated from codebase review. Align in-app Privacy Policy with this; update this doc when behavior changes.*

## Public contact (PESO Santiago City)

- **Email:** pesosantiago@yahoo.com.ph  
- **Facebook Messenger:** https://www.facebook.com/messages/t/pesosantiagocity  

*(Also wired in-app under Help & Support → Contact Support, and in Terms & Privacy.)*

## Components

| Layer | Stack | Role |
|--------|--------|------|
| Jobseeker mobile | Flutter (`untitled1`) | Registration, profile, documents, jobs, map, events, notifications |
| API | Laravel (`backend`), Sanctum/Bearer auth for jobseeker | Storage, business logic, employer/admin APIs |
| Admin / employer web | Vue (`frontend/peso`) | PESO staff & employer dashboards, job posting, application review |

## Jobseeker data — collected or stored (backend + app)

- **Account & auth:** First/middle/last name, email, hashed password, mobile number, sex, date of birth; email OTP for verification; optional `address` at registration.
- **Profile (API-validated):** Contact, structured PH address (province/city/barangay codes & names, street), bio, education level, job experience, optional longitude; skills as catalog selections (`jobseeker/skills`) plus legacy skill strings on profile update.
- **Documents (uploads):** Resume, certificate, barangay clearance, avatar — stored via Laravel (disk / optional cloud object storage for public assets).
- **Activity:** Job applications (`jobseeker/applications`), offer responses, saved jobs, event registrations.
- **Notifications:** In-app notification list; **FCM token** saved via `jobseeker/save-fcm-token`; push via Firebase Cloud Messaging.
- **Optional:** Satisfaction rating endpoint; email change via OTP (`profile/email/*`).
- **On device only (not necessarily on server):** Map “location profiles” and exact-pick coordinates in `SharedPreferences`; live GPS for map unless user sets manual location.

## Map & third-party (jobseeker app)

- **Map tiles:** OpenStreetMap (`tile.openstreetmap.org`) — device requests tiles; viewport approximate to tile CDN.
- **Location:** `geolocator` (device); clustering and employer pins use your **Laravel** `GET /api/public/map/employers`.
- **Fonts:** `google_fonts` — device may fetch fonts from Google’s font service.
- **Firebase:** `firebase_core`, `firebase_messaging`, local notifications plugin for displaying pushes.

## Who can see jobseeker data (backend routes)

- **Employers (authenticated):** Applications for their jobs, resume download, applicant profile context, invitations, notifications.
- **Admin / PESO staff (`admin/*`, Sanctum):** Jobseekers list/detail, documents by type, applications, statuses, events, notifications, reports, archives, activity feed, LEGS feedback (submissions list).
- **Public (unauthenticated):** Job listings, employer directory, events catalog, map employer pins, public skills catalog, storage proxy for approved public files — **not** jobseeker PII except what you intentionally expose in public payloads.

## Employer / Vue (high level)

- Employer registration, login, company profile, jobs CRUD, application pipeline, potential applicants, Pusher auth for **employer** real-time (not used in Flutter jobseeker app).
- Admin manages employers, jobseekers, jobs, applications, events, system notifications, LMA tooling, etc.

## Operational notes

- Replace `ApiService.baseUrl` in production; all jobseeker API traffic should use **HTTPS**.
- Jobseeker app does **not** call `POST /api/legs-feedback` in-repo; LEGS remains a **web/API** path if used from Vue or other clients.
