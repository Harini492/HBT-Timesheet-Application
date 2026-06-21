# HBT Timesheet Management System

A full-stack employee timesheet application: weekly hour entry per job, monthly reporting, absence tracking, global holidays, and admin management of employees and job codes — built on the HBT Group technical assessment brief, extended to the fuller scope requested (auth, admin module, reports, Docker, tests).

**Stack:** Flutter (Material 3, Riverpod, Go Router, Dio) · Node.js/Express · SQLite (`better-sqlite3`) · JWT auth · Docker

---

## 1. Project Structure

```
hbt-timesheet/
├── backend/                 Node/Express REST API
│   ├── src/
│   │   ├── config/          DB connection
│   │   ├── db/               schema.sql, migrate.js, seed.js
│   │   ├── middleware/       auth, error handling, validation
│   │   ├── modules/          auth, employees, jobs, timesheet, week, reports, holidays
│   │   ├── utils/             jwt, password hashing, date helpers
│   │   ├── app.js, server.js
│   ├── tests/                 node:test unit/integration tests
│   └── Dockerfile
├── frontend/                 Flutter app
│   ├── lib/
│   │   ├── core/              theme, networking, storage, router, shared widgets
│   │   └── features/          auth, dashboard, timesheet, report, holidays, absences, admin/*
│   ├── test/                   widget + unit tests
│   └── Dockerfile
└── docker-compose.yml
```

## 2. Quick Start

### Backend

```bash
cd backend
npm install
cp .env.example .env        # adjust JWT_SECRET etc. if you like
npm run setup                # runs migrations + seeds demo data
npm run dev                  # starts on http://localhost:4000
```

Health check: `GET http://localhost:4000/health`

### Frontend

```bash
cd frontend
flutter pub get
# Android emulator (default baseUrl already targets 10.0.2.2:4000):
flutter run
# flutter chrome 
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000
# iOS simulator / web / desktop — point at your host's localhost explicitly:
flutter run --dart-define=API_BASE_URL=http://localhost:4000
```

### Docker (backend + web frontend)

```bash
docker compose up --build
# API:  http://localhost:4000
# Web:  http://localhost:8080
```

> Docker only builds the **web** target for Flutter (mobile builds can't run in a container). For Android/iOS, run `flutter run` locally against the dockerized or locally-run backend.

### Demo Credentials (seeded)

| Role     | Employee ID | Password      |
|----------|-------------|---------------|
| Admin    | ADMIN001    | Admin@123     |
| Employee | EMP1001     | Employee@123  |
| Employee | EMP1002     | Employee@123  |
| Employee | EMP1003     | Employee@123  |

## 3. Architecture

**Backend** follows a layered module structure (`routes → controller → service → DB`) per feature, rather than a monolithic router file. Each module owns its own validation, business rules, and SQL. Cross-cutting concerns (auth, error formatting, request validation) live in `middleware/`.

- **Auth:** JWT bearer tokens, but sessions are *also* tracked server-side in a `sessions` table (hash of the token, not the raw token). This means logout immediately invalidates access even though the JWT itself hasn't technically expired — a deliberate design choice over stateless-only JWT.
- **Timesheet data model:** `timesheets` (one per employee per week) + `timesheet_entries` (one per job per day). An upsert keyed on `(timesheet_id, job_id, entry_date)` makes saving idempotent — re-saving the same week just updates existing rows instead of duplicating them.
- **Validation in three layers:** DB-level CHECK constraint (`hours BETWEEN 0 AND 24`), request-level `express-validator`, and service-level checks (e.g. an employee can only log hours against jobs explicitly assigned to them).

**Frontend** uses a feature-first folder structure (`features/<feature>/{data,domain,presentation}`), Riverpod `StateNotifierProvider`s for screen state, and Go Router with an auth-aware `redirect` callback that reacts to auth state changes via a custom `ChangeNotifier` bridge.

- **PageHeader is intentionally not `Scaffold.appBar`.** Each screen needs different controls on its navy header bar (Save + week nav on Timesheet, month nav on Report, an Add button on Holidays/Jobs/Employees) — exactly as shown in the provided screenshots, where these controls sit directly on the title bar. Making `PageHeader` a plain widget (not tied to a single Scaffold) lets every screen inject its own trailing actions while still sharing one consistent component. The hamburger menu inside it calls `Scaffold.of(context).openDrawer()`, which correctly bubbles up to the single Scaffold owned by `DashboardShell`.
- **Responsive shell:** a permanent sidebar on screens ≥900px wide; a `Drawer` on narrower viewports — same nav content either way.

## 4. API Reference

| Method | Endpoint | Notes |
|---|---|---|
| POST | `/auth/login` | `{ employeeCode, password }` → `{ token, user }` |
| POST | `/auth/logout` | invalidates the current session row |
| POST | `/auth/change-password` | |
| GET | `/auth/me` | |
| GET/POST/PUT/DELETE | `/employees` | admin-only |
| POST/DELETE | `/employees/:id/jobs[/:jobId]` | assign/unassign a job to an employee |
| GET/POST/PUT/DELETE | `/jobs` | GET is role-aware: employees see only their assigned jobs |
| GET | `/timesheet?weekStart=YYYY-MM-DD` | full week grid for the authenticated employee (or `?employeeId=` for admins) |
| POST/PUT | `/timesheet` | `{ weekStart, entries: [{ jobId, date, hours }] }` — full-week upsert |
| DELETE | `/timesheet/:id` | deletes a single entry by its row id |
| GET | `/week/:date` | `{ weekStart, weekEnd, days, rows, totalHours }` — `days` enriched with `dayName`/`isToday` |
| GET | `/report/monthly?year=&month=` | per-job rows with `dailyHours` map; jobs with 0 hours are omitted |
| GET | `/report/absence?start=&end=` | flags past weekdays with no logged hours, excluding weekends/holidays/today/future |
| GET/POST/DELETE | `/holidays` | GET open to all; POST/DELETE admin-only |

All endpoints except `/auth/login` and `/health` require `Authorization: Bearer <token>`.

## 5. Assumptions Made

- **`PUT /timesheet` behaves identically to `POST /timesheet`** (full-week upsert) — the assessment spec lists both without distinguishing semantics, so both are treated as "save/update this week's entries."
- **Employees can't freely type a new job onto their timesheet** — they pick from jobs an admin has assigned to them (matches the screenshot's dropdown-styled job picker, and the info banner text about contacting a Team Lead to get added to a job).
- **Absence detection excludes weekends, holidays, today, and future dates** — only *past working weekdays* with zero logged hours count as an absence.
- **Monthly report omits jobs with zero hours** for the selected month, per the "do not show empty jobs" expectation implied by the screenshot (every visible row has at least one logged day).
- **Roles are binary** (`admin` / `employee`) — no granular permission system, matching the assessment's scope.
- **Sessions table stores a SHA-256 hash of the JWT**, not the raw token, so a compromised DB doesn't directly leak usable bearer tokens.

## 6. Known Limitations

- **This codebase was written without a live runtime available in the build environment** (no network access to fetch npm/pub packages, no Flutter SDK installed). Every backend `.js` file was syntax-checked with `node --check`, but nothing was executed end-to-end. **You must run `npm install` and `flutter pub get` locally and validate the app before relying on it** — treat this as a strong first draft, not a verified-working build.
- Flutter test coverage is illustrative (a handful of unit + widget tests), not exhaustive.
- No CI pipeline is included.
- The frontend Docker target only builds for web; mobile targets must be run via `flutter run`.

## 7. Testing

```bash
# Backend
cd backend && npm test

# Frontend
cd frontend && flutter test
```
