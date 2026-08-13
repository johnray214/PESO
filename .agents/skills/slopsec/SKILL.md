---
name: slopsec
description: Security-audit skill for vibe-coded / AI-generated SaaS applications and mobile APIs. Evaluates a 50-point checklist for authentication, authorization (IDOR), secret leaks, rate limiting, and storage access.
---

# Slopsec: Security Audit Skill for Vibe-Coded Applications

Use this skill when auditing a codebase for common security oversights, data leaks, and resource abuse vectors typical in AI-generated software.

## The 50-Point Audit Checklist

### 1. Authentication & Session Management (Checks 1–10)
- [ ] **1. Missing Auth Middleware**: Verify all private API endpoints require valid session / bearer token guards (`auth:sanctum`, JWT, etc.).
- [ ] **2. Plaintext Password Storage**: Ensure passwords use strong hashing (Bcrypt, Argon2).
- [ ] **3. OTP Brute Force Protection**: Check that OTP verification endpoints enforce strict rate limiting (max 5–6 attempts per minute).
- [ ] **4. Stale Session Tokens**: Verify tokens are revoked upon logout or password resets.
- [ ] **5. Unauthenticated User Registration Options**: Check if admin roles or elevated permissions can be self-assigned during registration.
- [ ] **6. Insecure Password Reset Flow**: Ensure reset tokens are cryptographically random, single-use, and time-bounded.
- [ ] **7. Weak Default Secrets**: Check for default `APP_KEY`, JWT secrets, or fallback credentials left in code.
- [ ] **8. Unverified Email Changes**: Ensure email updates require re-verification or current password confirmation.
- [ ] **9. Public Auth State Endpoints**: Verify sensitive user session objects aren't leaked to unauthenticated visitors.
- [ ] **10. Cleartext Transport (HTTP)**: Enforce HTTPS on all non-local API communication.

### 2. Authorization & Access Control / IDOR (Checks 11–20)
- [ ] **11. Insecure Direct Object References (IDOR)**: Ensure record fetching (e.g. `/api/applications/{id}`) verifies resource ownership via Policies/Gates.
- [ ] **12. Horizontal Privilege Escalation**: Verify User A cannot edit or delete User B's profile or data.
- [ ] **13. Vertical Privilege Escalation**: Ensure regular users cannot trigger admin controllers or routes.
- [ ] **14. Exposed Sequential Primary Keys**: Use UUIDs or strict ownership checks on integer IDs.
- [ ] **15. Public File Download Routes**: Verify private user uploads (resumes, IDs) are not served on unauthenticated public URLs.
- [ ] **16. Missing Scope Guards on API Tokens**: Ensure Sanctum/OAuth tokens enforce specific capabilities (`read`, `write`, `admin`).
- [ ] **17. Soft Delete Bypass**: Ensure soft-deleted records cannot be read or manipulated via public APIs.
- [ ] **18. Multi-Tenant Data Leakage**: Verify tenant queries include strict tenant boundary scoping.
- [ ] **19. CORS Over-Permissiveness**: Check that `Access-Control-Allow-Origin` is restricted to trusted origins, avoiding `*` with credentials.
- [ ] **20. Admin Route Alias Leaks**: Ensure admin aliases (`/peso-employee/login`, `/admin/...`) require administrative guards.

### 3. Secrets & Configuration Hygiene (Checks 21–30)
- [ ] **21. Git-Committed Secrets**: Scan repository history for committed `.env` files, private keys, or API tokens.
- [ ] **22. Hardcoded Mobile Client Secrets**: Verify mobile binaries (Dart/Swift/Kotlin) do not contain backend private keys or DB credentials.
- [ ] **23. Debug / Test Endpoints Left Active**: Ensure `/debug-notifs`, `/test-email`, or sandbox routes are disabled outside `local` environments.
- [ ] **24. Verbose Production Error Logs**: Verify `APP_DEBUG=false` in production so stack traces are hidden from users.
- [ ] **25. Exposed Environment File**: Confirm `.env` and `.env.backup` are blocked by web server configuration.
- [ ] **26. Insecure Local Storage**: Ensure client-side session tokens are stored using secure encryption (`flutter_secure_storage`).
- [ ] **27. Public Database Admin Panels**: Ensure PhpMyAdmin, Adminer, or Laravel Telescope are disabled or auth-gated in production.
- [ ] **28. Hardcoded Encryption Keys**: Verify encryption keys are loaded dynamically from environment variables.
- [ ] **29. Exposed Cloud Bucket Credentials**: Check that S3/R2 secret keys are kept strictly on the backend.
- [ ] **30. Unrestricted Webhook Endpoints**: Ensure external webhooks verify cryptographic signatures (e.g., Stripe, Pusher).

### 4. Input Validation & Data Integrity (Checks 31–40)
- [ ] **31. Mass Assignment Vulnerabilities**: Ensure Eloquent models define explicit `$fillable` attributes.
- [ ] **32. Unsanitized SQL Queries**: Verify dynamic queries use parameterized bindings instead of raw string concatenation.
- [ ] **33. Path Traversal Hazards**: Ensure file download/upload routes sanitize relative path sequences (`../`).
- [ ] **34. File Upload Extension Bypasses**: Validate uploaded MIME types and file extensions (e.g., restricting to PDF, PNG, JPG).
- [ ] **35. File Size Exhaustion**: Enforce max upload file sizes (e.g. `max:5120` KB).
- [ ] **36. Cross-Site Scripting (XSS)**: Ensure user HTML inputs are escaped or sanitized before rendering.
- [ ] **37. Parameter Tampering on Prices/Status**: Verify state fields (like `status = 'approved'` or `price = 0`) cannot be sent in public POST payloads.
- [ ] **38. Open Redirect Vulnerabilities**: Verify redirect parameters validate destination URLs.
- [ ] **39. JSON Payload Depth Exhaustion**: Set parsing caps on deeply nested JSON payloads.
- [ ] **40. Loose Type Comparisons**: Ensure strict strict-type validation on request inputs.

### 5. Denial of Service & Resource Abuse (Checks 41–50)
- [ ] **41. Unthrottled Expensive Heavy Endpoints**: Rate-limit PDF generation, Excel exports, and search queries.
- [ ] **42. Unbound Pagination Limits**: Cap `per_page` query parameters to prevent fetching 100,000 records at once.
- [ ] **43. Unrestricted Eager Loading**: Prevent client requests from requesting arbitrary nested database relations.
- [ ] **44. Replay Attack Vulnerabilities**: Add timestamp / nonce validation on high-value transaction requests.
- [ ] **45. Unmonitored Outbound Third-Party API Calls**: Set connection timeouts on external API requests (e.g. SMS gateways, AI services).
- [ ] **46. Public Push Notification Triggers**: Ensure FCM/Pusher broadcast endpoints require authentication.
- [ ] **47. Excessive Logging of Sensitive Data**: Verify passwords, credit cards, and tokens are redacted from application log files.
- [ ] **48. Database Connection Starvation**: Ensure connection pool size limits and query execution timeouts are configured.
- [ ] **49. Memory Leak / Queue Accumulation**: Set job retry limits and queue worker memory thresholds.
- [ ] **50. Missing Audit Logs on Critical Actions**: Log administrative state changes (status updates, user deletions, permission modifications).
