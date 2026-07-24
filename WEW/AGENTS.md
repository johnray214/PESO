# Project Instructions

## Project Shape
- Mobile app: Flutter in `untitled1/`.
- Web admin: Vue 3 + Vite + TypeScript in `web/`.
- Backend API: Laravel 12 in `backend/`.
- Treat `backend/` as the source of truth for authorization, validation, data rules, and persistence.
- Preserve existing project structure and naming unless a task explicitly calls for a broader refactor.

## Core Workflow
- Read the relevant app area before editing. Prefer existing components, services, controllers, models, request classes, stores, and styling patterns.
- Keep changes scoped to the requested behavior. Do not rewrite unrelated screens, routes, API contracts, or schema.
- When a change crosses layers, update the backend contract first, then the Vue admin and/or Flutter client.
- Include loading, empty, error, offline, and success states where the user flow needs them.
- Do not perform destructive git or filesystem operations unless explicitly requested.

## Commands

### Flutter Mobile (`untitled1/`)
- Install dependencies: `flutter pub get`
- Analyze: `flutter analyze`
- Test: `flutter test`
- Run: `flutter run`
- Build Android: `flutter build apk`

### Vue Admin (`web/`)
- Install dependencies: `npm install`
- Dev server: `npm run dev`
- Type-check and build: `npm run build`
- Type-check only: `npm run type-check`
- Lint/fix: `npm run lint`
- Preview build: `npm run preview`

### Laravel Backend (`backend/`)
- Install PHP dependencies: `composer install`
- Install JS dependencies: `npm install`
- Dev stack: `composer run dev`
- Tests: `composer test` or `php artisan test`
- Format PHP: `vendor/bin/pint`
- Migrate: `php artisan migrate`
- Clear config/cache when needed: `php artisan config:clear`

## Mobile App Standards
- Build real Flutter screens and flows, not static mockups.
- Keep API calls, persistence, and business rules out of widgets where practical; use existing services/helpers.
- Respect existing localization, assets, fonts, navigation, and theme choices.
- Handle slow network, no connection, denied permissions, expired sessions, and server validation errors.
- Keep layouts responsive across common Android and iOS sizes. Avoid fixed dimensions unless they are required by assets or platform UI.
- Use accessible tap targets and clear form validation.

## Web Admin Standards
- Use Vue 3 Composition API and TypeScript patterns already present in `web/`.
- Prefer existing Pinia stores, router patterns, composables, and components before adding new abstractions.
- Admin UI should be dense, calm, and task-focused. Avoid landing-page sections, decorative gradients, and oversized marketing layouts.
- Tables, filters, forms, modals, and detail pages should support scanning, keyboard-friendly controls, validation feedback, and clear destructive-action confirmation.
- All admin flows must work on desktop; keep tablet/mobile behavior usable when practical.

## Backend Standards
- Validate requests server-side, preferably with Laravel Form Request classes when the endpoint has non-trivial rules.
- Enforce permissions in policies, gates, middleware, or controller/service checks. Never rely on Flutter or Vue for authorization.
- Use Eloquent relationships and query builder features instead of ad hoc SQL unless raw SQL is justified.
- Use transactions for multi-step writes and state transitions.
- Return consistent JSON responses and validation errors that clients can display directly.
- Avoid leaking secrets, stack traces, tokens, or provider responses to clients.
- Keep database migrations backward-aware. Note data migration risks when changing existing columns or relationships.
- Add or update tests for changed backend behavior, especially validation, authorization, and state changes.

## API Contract Rules
- Keep request/response shapes explicit when connecting Laravel to Flutter or Vue.
- If an endpoint changes, update all affected clients in the same task unless asked otherwise.
- Prefer stable identifiers and server-generated timestamps.
- Treat pagination, filtering, sorting, and search behavior as part of the contract.
- Handle token/session expiry consistently in both clients.

## Verification
- Run the smallest relevant checks after changes:
  - Flutter-only: `flutter analyze` and targeted `flutter test`.
  - Vue-only: `npm run type-check` and `npm run lint` when applicable.
  - Laravel-only: `php artisan test` or targeted tests, plus `vendor/bin/pint` for PHP formatting.
  - Cross-layer changes: run backend tests plus the affected client type/analyze checks.
- If a check cannot run because dependencies, environment variables, services, or databases are unavailable, report that clearly.

## UI/UX Quality Bar
- Implement the complete user workflow, including disabled states, validation, server errors, empty states, and confirmation where appropriate.
- Match existing visual language before inventing new styles.
- Keep text concise and useful. Avoid in-app explanations of obvious controls.
- Use real data from APIs where available; mock data only when explicitly requested or when isolating a visual prototype.

## Security And Data
- Do not hard-code secrets, tokens, API keys, private URLs, or credentials.
- Keep `.env` usage consistent with the existing projects.
- Sanitize and validate uploaded files, user-entered content, and IDs.
- Be careful with personally identifiable information, employment records, documents, notifications, and location data.
