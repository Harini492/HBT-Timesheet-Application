# HBT Timesheet Management System

A full-stack employee timesheet application: weekly hour entry per job,
monthly reporting, absence tracking, global holidays, and admin management
of employees and job codes — built on the HBT Group technical assessment
brief, extended to the fuller scope requested (auth, admin module, reports,
Docker, tests).

**Stack:** Flutter (Material 3, Riverpod, Go Router, Dio) · Node.js/Express
· SQLite (`better-sqlite3`) · JWT auth · Docker

---

## 1. Project Structure

```
hbt-timesheet/
├── backend/                 Node/Express REST API
│   ├── src/
│   │   ├── config/          DB connection
│   │   ├── db/                schema.sql, migrate.js, seed.js
│   │   ├── middleware/        auth, error handling, validation
│   │   ├── modules/           auth, employees, jobs, timesheet, week, reports, holidays
│   │   ├── utils/              jwt, password hashing, date helpers
│   │   ├── app.js, server.js
│   ├── tests/                  node:test unit/integration tests
│   └── Dockerfile
├── frontend/                  Flutter app
│   ├── lib/
│   │   ├── core/               theme, networking, storage, router, shared widgets
│   │   └── features/           auth, dashboard, timesheet, report, holidays, absences, admin/*
│   ├── test/                    widget + unit tests
│   └── Dockerfile
└── docker-compose.yml
```

## 2. Quick Start

### Prerequisites

- Node.js 18+
- Flutter SDK (stable channel). Tested against **Flutter 3.24.3 / Dart
  3.5.3** — see [Known Issues](#6-known-limitations--issues-found-while-running-this) below for
  version-specific fixes already applied.

### Backend

```bash
cd backend
npm install
cp .env.example .env        # adjust JWT_SECRET etc. if you like
npm run setup                # runs migrations + seeds demo data
npm run dev                  # starts on http://localhost:4000
```

Health check: `GET http://localhost:4000/health`

Other useful scripts:
```bash
npm run migrate    # just the schema, no seed data
npm run seed        # just the seed data (assumes schema already exists)
npm test              # runs the node:test suite in tests/
```

### Frontend

```bash
cd frontend
flutter pub get

# Android emulator (default baseUrl already targets 10.0.2.2:4000):
flutter run

# Chrome / web:
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000

# iOS simulator / desktop — point at your host's localhost explicitly:
flutter run --dart-define=API_BASE_URL=http://localhost:4000
```

The `--dart-define=API_BASE_URL=...` flag is required for every target
**except** the Android emulator, which has a working default
(`http://10.0.2.2:4000` maps to your host machine's `localhost:4000` from
inside the emulator).

### Docker (backend + web frontend)

```bash
docker compose up --build
# API:  http://localhost:4000
# Web:  http://localhost:8080
```

Docker only builds the **web** target for Flutter (mobile builds can't run
in a container). For Android/iOS, run `flutter run` locally against the
dockerized or locally-run backend. Note that the Docker Compose file sets
`CORS_ORIGIN=http://localhost:8080` for the backend container, since that's
where the containerized nginx serves the web build — this is separate from
the `CORS_ORIGIN` in your local `.env`, which only matters when you run the
backend with `npm run dev` directly.

### Demo Credentials (seeded)

| Role     | Employee ID | Password      |
|----------|-------------|---------------|
| Admin    | ADMIN001    | Admin@123     |
| Employee | EMP1001     | Employee@123  |
| Employee | EMP1002     | Employee@123  |
| Employee | EMP1003     | Employee@123  |

**Change these before any real deployment** — they only exist to make the
seeded demo data immediately usable.

## 3. Architecture

**Backend** follows a layered module structure (`routes → controller →
service → DB`) per feature, rather than a monolithic router file. Each
module owns its own validation, business rules, and SQL. Cross-cutting
concerns (auth, error formatting, request validation) live in
`middleware/`.

- **Auth:** JWT bearer tokens, but sessions are *also* tracked
  server-side in a `sessions` table (a SHA-256 hash of the token, not the
  raw token, so a compromised DB doesn't directly leak usable bearer
  tokens). This means logout immediately invalidates access even though
  the JWT itself hasn't technically expired — a deliberate design choice
  over stateless-only JWT.
- **Timesheet data model:** `timesheets` (one per employee per week) +
  `timesheet_entries` (one per job per day). An upsert keyed on
  `(timesheet_id, job_id, entry_date)` makes saving idempotent —
  re-saving the same week just updates existing rows instead of
  duplicating them.
- **Validation in three layers:** DB-level CHECK constraint (`hours
  BETWEEN 0 AND 24`), request-level `express-validator`, and
  service-level checks (e.g. an employee can only log hours against
  jobs explicitly assigned to them).
- **CORS:** locked to a single origin via `CORS_ORIGIN` in production.
  See [Known Issues](#6-known-limitations--issues-found-while-running-this) for a development-mode gotcha
  with `flutter run -d chrome`.

**Frontend** uses a feature-first folder structure
(`features/<feature>/{data,domain,presentation}`), Riverpod
`StateNotifierProvider`s for screen state, and Go Router with an
auth-aware `redirect` callback that reacts to auth state changes via a
custom `ChangeNotifier` bridge.

- **PageHeader is intentionally not `Scaffold.appBar`.** Each screen
  needs different controls on its navy header bar (Save + week nav on
  Timesheet, month nav on Report, an Add button on Holidays/Jobs/
  Employees) — exactly as shown in the provided screenshots, where these
  controls sit directly on the title bar. Making `PageHeader` a plain
  widget (not tied to a single Scaffold) lets every screen inject its own
  trailing actions while still sharing one consistent component. The
  hamburger menu inside it calls `Scaffold.of(context).openDrawer()`,
  which correctly bubbles up to the single Scaffold owned by
  `DashboardShell`.
- **Responsive shell:** a permanent sidebar on screens ≥900px wide; a
  `Drawer` on narrower viewports — same nav content either way.
- **Session restore is asynchronous.** On cold start, `AuthNotifier`
  awaits reading the stored token before settling into `authenticated` or
  `unauthenticated`. Because `initialLocation` is `/timesheet` and the
  router's `redirect` intentionally does nothing while status is
  `AuthStatus.initial`, you'll briefly render the timesheet shell before
  bouncing to `/login` if no valid session exists — this is expected, not
  a bug, and resolves within a frame or two once `_restoreSession()`
  completes.

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
| GET | `/week/:date` | `{ weekStart, weekEnd, days, rows, totalHours }` — days enriched with `dayName`/`isToday` |
| GET | `/report/monthly?year=&month=` | per-job rows with `dailyHours` map; jobs with 0 hours are omitted |
| GET | `/report/absence?start=&end=` | flags past weekdays with no logged hours, excluding weekends/holidays/today/future |
| GET/POST/DELETE | `/holidays` | GET open to all; POST/DELETE admin-only |

All endpoints except `/auth/login` and `/health` require
`Authorization: Bearer <token>`.

## 5. Assumptions Made

- `PUT /timesheet` behaves identically to `POST /timesheet` (full-week
  upsert) — the assessment spec lists both without distinguishing
  semantics, so both are treated as "save/update this week's entries."
- Employees can't freely type a new job onto their timesheet — they pick
  from jobs an admin has assigned to them (matches the screenshot's
  dropdown-styled job picker, and the info banner text about contacting a
  Team Lead to get added to a job).
- Absence detection excludes weekends, holidays, today, and future dates
  — only past working weekdays with zero logged hours count as an
  absence.
- Monthly report omits jobs with zero hours for the selected month, per
  the "do not show empty jobs" expectation implied by the screenshot
  (every visible row has at least one logged day).
- Roles are binary (admin / employee) — no granular permission system,
  matching the assessment's scope.
- Sessions table stores a SHA-256 hash of the JWT, not the raw token, so
  a compromised DB doesn't directly leak usable bearer tokens.

## 6. Known Limitations / Issues Found While Running This

This codebase was originally written without a live runtime available in
its build environment — nothing was executed end-to-end before being
handed over. The issues below were found and fixed by actually running it:

- **`CardThemeData` doesn't exist in Flutter 3.24.x.** It was introduced
  in Flutter 3.27. If you're on an older stable channel and see:
  ```
  lib/core/theme/app_theme.dart:36:18: Error: Method not found: 'CardThemeData'.
  ```
  change `cardTheme: CardThemeData(...)` to `cardTheme: CardTheme(...)` in
  that file. Run `flutter --version` first if you're unsure which you
  need.

- **CORS breaks `flutter run -d chrome` in local dev.** `flutter run -d
  chrome` binds to a different random port every launch (e.g.
  `localhost:52964`), but the backend's CORS middleware only allowed the
  single origin in `CORS_ORIGIN` (default `http://localhost:3000` per
  `.env.example`). Every API request was silently blocked by the browser
  before it left the page, surfacing in the app as "Could not reach the
  server" even though the backend was demonstrably running (`curl
  http://localhost:4000/health` worked fine). **Fix applied:** in
  `backend/src/app.js`, CORS now allows any `http://localhost:<port>` or
  `http://127.0.0.1:<port>` origin when `NODE_ENV !== 'production'`, and
  falls back to the strict single-origin `CORS_ORIGIN` check in
  production. If you pulled this repo before that fix, apply it manually
  or you'll hit the exact same symptom.

- **Native module installs (`better-sqlite3`) can fail without build
  tools.** On Windows this usually isn't an issue (prebuilt binaries exist
  for most Node versions), but if `npm install` fails specifically on
  `better-sqlite3`, you're missing native build tools. Install Node's
  windows-build-tools or a recent enough Node LTS with prebuilt binary
  support, then retry.

- Flutter test coverage is illustrative (a handful of unit + widget
  tests), not exhaustive.
- No CI pipeline is included.
- The frontend Docker target only builds for web; mobile targets must be
  run via `flutter run`.

## 7. Testing

```bash
# Backend
cd backend && npm test

# Frontend
cd frontend && flutter test
```