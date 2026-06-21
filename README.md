# 🕒 HBT Timesheet Management System

A full-stack employee timesheet application built for the HBT Group
Flutter Technical Assessment: weekly hour entry per job, monthly
reporting (with Excel export), absence tracking, global holidays, and
admin management of employees and job codes. Employees never self-register
— accounts and job assignments are entirely admin-controlled. Fully
local, no paid services required.

## 🔗 Quick Navigation
- [How It Works](#️-how-it-works)
- [Tech Stack](#️-tech-stack)
- [Project Structure](#-project-structure)
- [Setup & Installation](#-setup--installation)
  - [Option A — Docker](#option-a--docker-recommended)
  - [Option B — Local (Node + Flutter)](#option-b--local-node--flutter)
- [Architecture](#️-architecture)
- [Features](#-features)
- [Bonus Features Implemented](#-bonus-features-implemented)
- [Assumptions](#-assumptions)
- [Known Issues & Fixes Applied](#-known-issues--fixes-applied)
- [Challenges Faced](#-challenges-faced)

## ⚙️ How It Works

1. **Authenticate** — admin or employee signs in with an Employee ID +
   password issued by an admin (no self-registration); a JWT is issued
   and a matching row is written to a server-side `sessions` table
2. **Restore session** — on app relaunch, the stored token is read from
   secure storage and validated against `/auth/me` before any screen
   renders as "logged in"
3. **Load the week** — `GET /week/:date` resolves the Monday–Sunday range
   for any given date; `GET /timesheet` returns that week's saved entries
   joined with the jobs assigned to the employee
4. **Enter hours** — employee picks a job from their assigned list (job
   code auto-fills, read-only), types hours per day (0–24, validated
   client- and server-side), optionally adds remarks
5. **Save** — `POST`/`PUT /timesheet` upserts the full week in one call,
   keyed on `(timesheet_id, job_id, entry_date)` — re-saving never
   duplicates rows
6. **Report** — `GET /report/monthly` aggregates hours per job per day
   for a chosen month (jobs with zero hours are omitted); the report
   screen can also export the visible month directly to `.xlsx`
7. **Track absences** — `GET /report/absence` flags past weekdays with
   no logged hours, automatically excluding weekends, holidays, today,
   and future dates
8. **Admin manages the org** — admins create/edit/deactivate employees,
   reset passwords, create job codes, and assign jobs to employees —
   all from a dedicated admin dashboard

## 🛠️ Tech Stack

| Layer | Tool |
|---|---|
| Frontend / UI | Flutter (Material 3) |
| State Management | Riverpod (`StateNotifierProvider`) |
| Routing | Go Router, with an auth-aware `redirect` callback |
| HTTP Client | Dio |
| Secure Storage | `flutter_secure_storage` (JWT), `shared_preferences` (theme/prefs) |
| Excel Export | `excel` package (monthly report → `.xlsx`) |
| Backend | Node.js + Express |
| Database | SQLite via `better-sqlite3` |
| Auth | JWT bearer tokens + server-side `sessions` table (SHA-256-hashed token) |
| Validation | `express-validator` + DB-level `CHECK` constraints |
| Security Middleware | `helmet`, `cors` |
| Logging | `morgan` |
| Containerisation | Docker + Docker Compose |
| Language | JavaScript (Node 18+), Dart (Flutter 3.24+) |

## 📁 Project Structure

```
hbt-timesheet/
├── backend/
│   ├── src/
│   │   ├── app.js, server.js
│   │   ├── config/             # DB connection
│   │   ├── db/
│   │   │   ├── schema.sql       # employees, jobs, employee_jobs, timesheets,
│   │   │   │                     timesheet_entries, holidays, sessions
│   │   │   ├── migrate.js
│   │   │   └── seed.js          # demo admin + 3 employees + sample jobs/holidays
│   │   ├── middleware/          # JWT auth, error handling, request validation
│   │   ├── modules/             # one folder per feature, each with
│   │   │   ├── auth/             #   routes.js → controller.js → service.js
│   │   │   ├── employees/
│   │   │   ├── jobs/
│   │   │   ├── timesheet/
│   │   │   ├── week/
│   │   │   ├── reports/
│   │   │   └── holidays/
│   │   └── utils/                # jwt, password hashing, date helpers
│   ├── tests/                     # node:test unit/integration tests
│   └── Dockerfile
│
├── frontend/
│   ├── lib/
│   │   ├── core/
│   │   │   ├── theme/             # Material 3 light/dark ThemeData
│   │   │   ├── network/            # Dio client + interceptors
│   │   │   ├── storage/             # TokenStorage (flutter_secure_storage)
│   │   │   ├── router/               # GoRouter + auth redirect
│   │   │   ├── errors/                # typed AppException hierarchy
│   │   │   ├── config/                 # ApiConstants, AppConstants
│   │   │   └── providers/               # shared core providers
│   │   └── features/
│   │       ├── auth/                     # login, change password, auth_notifier
│   │       ├── dashboard/                  # responsive shell, sidebar, top bar
│   │       ├── timesheet/                   # weekly grid + hour inputs
│   │       ├── report/                       # monthly report + Excel exporter
│   │       ├── holidays/                       # holiday calendar
│   │       ├── absences/                        # absence list
│   │       └── admin/
│   │           ├── employees/                    # CRUD + reset password
│   │           └── jobs/                           # CRUD + assign to employees
│   ├── test/                                        # widget + unit tests
│   └── Dockerfile
│
└── docker-compose.yml
```

## 🚀 Setup & Installation

### Prerequisites

| Requirement | Notes |
|---|---|
| Docker Desktop | Required for Option A |
| Node.js 18+ | Required for Option B backend |
| Flutter SDK (stable) | Required for Option B frontend — tested against 3.24.3/Dart 3.5.3, see [Known Issues](#-known-issues--fixes-applied) |

### Option A — Docker (Recommended)

1. **Copy the environment file**
   ```bash
   cd backend
   cp .env.example .env
   ```
   Defaults work out of the box:
   ```
   PORT=4000
   JWT_SECRET=change_this_to_a_long_random_secret_in_production
   JWT_EXPIRES_IN=8h
   ```

2. **Build and start both services**
   ```bash
   docker compose up --build
   ```
   This will:
   - Build the backend image and run migrations + seed on first boot
   - Build the Flutter **web** target and serve it via nginx
   - Wire the two together over the internal Docker network

3. **Open the app**
   - Web app: http://localhost:8080
   - API health check: http://localhost:4000/health

4. **Stopping the services**
   ```bash
   docker compose down
   ```

> Docker only builds the **web** target for Flutter (mobile builds can't
> run in a container). For Android/iOS, run `flutter run` locally against
> the dockerized or locally-run backend.

### Option B — Local (Node + Flutter)

**1. Backend**
```bash
cd backend
npm install
cp .env.example .env
npm run setup        # runs migrations + seeds demo data
npm run dev           # starts on http://localhost:4000
```

**2. Frontend**
```bash
cd frontend
flutter pub get

# Android emulator (default baseUrl already targets 10.0.2.2:4000):
flutter run

# Chrome / web:
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000

# iOS simulator / desktop:
flutter run --dart-define=API_BASE_URL=http://localhost:4000
```

**3. Demo credentials (seeded)**

| Role | Employee ID | Password |
|---|---|---|
| Admin | `ADMIN001` | `Admin@123` |
| Employee | `EMP1001` | `Employee@123` |
| Employee | `EMP1002` | `Employee@123` |
| Employee | `EMP1003` | `Employee@123` |

**Change these before any real deployment.**

## 🏗️ Architecture

### High-Level Data Flow

```
Employee opens the app (Flutter)
        │
        ▼
   main.dart                          — boots ProviderScope, MaterialApp.router
        │
        ▼
   core/router/app_router.dart        — GoRouter redirect checks auth state
        │
   ┌────┴──────────────────────────────────────────┐
   │              Auth Path (cold start)             │
   └────┬──────────────────────────────────────────┘
        │
   auth_notifier.dart                 — restores token from secure storage
        │
        ▼
   auth_repository.dart               — POST /auth/login
        │
        ▼
   auth.routes.js → auth.controller.js → auth.service.js
        │                                   bcrypt verify + JWT sign
        │                                   + insert row into sessions table
        ▼
   { token, user } → TokenStorage (flutter_secure_storage)
        │
   ┌────┴──────────────────────────────────────────┐
   │            Timesheet Path (runtime)             │
   └────┬──────────────────────────────────────────┘
        │
   timesheet_screen.dart              — renders weekly grid
        │
        ▼
   GET /week/:date    → week.service.js          (Mon–Sun range, day flags)
        ▼
   GET /timesheet      → timesheet.service.js      (joins entries + assigned jobs)
        ▼
   Employee edits hours → POST/PUT /timesheet
                            (upsert on timesheet_id+job_id+entry_date,
                             0–24 hour validation, DB CHECK constraint)
        ▼
   SQLite (better-sqlite3)
        │
   ┌────┴──────────────────────────────────────────┐
   │       Reporting & Admin Paths (on demand)       │
   └────┬──────────────────────────────────────────┘
        │
   GET /report/monthly → reports.service.js   — per-job dailyHours rollup
        │                                          → report_excel_exporter.dart (.xlsx)
   GET /report/absence  → reports.service.js   — flags zero-hour past weekdays
   GET /holidays          → holidays.service.js  — calendar lookup
   /employees, /jobs       → admin CRUD modules    — employee & job management
        │
        ▼
   JSON → Dio → Riverpod StateNotifierProvider → widget rebuild
```

### Docker Service Architecture

```
docker-compose.yml
├── backend      (port 4000)   — Express API, SQLite file persisted via named volume
└── frontend     (port 8080:80) — nginx serving the Flutter web build
         ↕
    CORS_ORIGIN=http://localhost:8080  (set for the containerized frontend's origin)
```

### Auth & Session Model

```
Login request
  │
  ▼
bcrypt.compare(password, hash) ──fail──▶ 401 Invalid credentials
  │ pass
  ▼
jwt.sign({ id, role }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN })
  │
  ▼
INSERT INTO sessions (employee_id, token_hash, login_time)
  │   token_hash = SHA-256(token) — raw token never stored
  ▼
{ token, user } returned to client
  │
  ▼
Every subsequent request: verify JWT signature AND check sessions
table for a matching, non-logged-out row — logout/password-change closes
that row, instantly revoking access even though the JWT itself hasn't
technically expired yet.
```

## ⚡ Features

- 🔐 **JWT + server-side session revocation** — logout and password
  changes invalidate access immediately, not just at JWT expiry
- 🚫 **No self-registration** — employees only ever sign in with
  credentials an admin created for them
- 📅 **Weekly timesheet grid** — job dropdown (assigned jobs only),
  auto-derived read-only job code, per-day 0–24 hour validation, optional
  remarks, running weekly total, previous/next week navigation
- 📊 **Monthly report** — per-job, per-day hours table; jobs with zero
  hours for the month are hidden; one-click **Excel export**
- 🏖️ **Absence tracking** — automatically excludes weekends, holidays,
  today, and future dates — only genuine missed working days count
- 🗓️ **Global holidays calendar**
- 👤 **Admin module** — create/update/deactivate employees, reset
  passwords, create job codes, assign jobs to employees
- 🌗 **Dark mode** toggle, persisted across sessions
- 📱 **Responsive shell** — permanent sidebar ≥900px wide, collapsible
  Drawer on narrower viewports, same nav content either way
- 🐳 **Docker deployment** — `docker compose up --build` starts the
  full stack (backend + web frontend)
- 🧩 **Modular architecture** — backend organized as one
  routes/controller/service module per feature; frontend organized
  feature-first with `data/domain/presentation` separation

## 🌟 Bonus Features Implemented

| Feature | Status | Details |
|---|---|---|
| Excel export | ✅ | Monthly report exports directly to `.xlsx` via the `excel` package |
| Dark mode | ✅ | Persisted theme preference, toggle in the top bar |
| Server-side session revocation | ✅ | `sessions` table with hashed tokens; logout/password-change closes sessions immediately |
| Secure token storage | ✅ | `flutter_secure_storage` rather than plain shared preferences |
| Responsive sidebar/drawer shell | ✅ | Single `AppSidebar` shared across permanent-sidebar and drawer layouts |
| Docker deployment | ✅ | Full Compose stack (API + nginx-served web build) |
| Unit + widget test coverage | ✅ | `node:test` on the backend; `flutter_test` widget/unit tests on the frontend |

## 📝 Assumptions

- `PUT /timesheet` behaves identically to `POST /timesheet` (full-week
  upsert) — the assessment spec lists both without distinguishing
  semantics, so both are treated as "save/update this week's entries."
- Employees can't freely type a new job onto their timesheet — they pick
  from jobs an admin has explicitly assigned to them, matching the
  screenshot's dropdown-styled job picker and its info banner about
  contacting a Team Lead to get added to a job.
- Absence detection excludes weekends, holidays, today, and future dates
  — only past working weekdays with zero logged hours count as an
  absence.
- Monthly report omits jobs with zero hours for the selected month, per
  the "do not show empty jobs" expectation implied by the screenshot.
- Roles are binary (admin / employee) — no granular permission system.
- Sessions table stores a SHA-256 hash of the JWT, not the raw token, so
  a compromised DB doesn't directly leak usable bearer tokens.
- CPU/standard hosting is acceptable — there's no GPU dependency anywhere
  in this stack; SQLite is sufficient for the assessment's "localhost
  only" deployment scope.

## 🐛 Known Issues & Fixes Applied

This codebase was originally written without a live runtime available in
its build environment — nothing was executed end-to-end before being
handed over. The issues below were found and fixed by actually running it:

1. **`CardThemeData` doesn't exist before Flutter 3.27.** On Flutter
   3.24.x you'll see:
   ```
   lib/core/theme/app_theme.dart:36:18: Error: Method not found: 'CardThemeData'.
   ```
   **Fix:** change `cardTheme: CardThemeData(...)` to
   `cardTheme: CardTheme(...)`.

2. **CORS silently blocked every request from `flutter run -d chrome`.**
   Chrome's dev server binds to a different random port every launch
   (e.g. `localhost:52964`), but CORS only allowed one fixed origin from
   `.env`. Every request was blocked client-side before it reached the
   network tab, surfacing as "Could not reach the server" even with the
   backend demonstrably running. **Fix:** `backend/src/app.js` now allows
   any `localhost`/`127.0.0.1` origin when `NODE_ENV !== 'production'`,
   and still enforces a single strict origin in production.

3. **Native module install risk (`better-sqlite3`).** Usually fine on
   Windows (prebuilt binaries ship for most Node versions), but if
   `npm install` fails specifically on `better-sqlite3`, you're missing
   native build tools — install a Node LTS with prebuilt binary support
   and retry.

## 🧗 Challenges Faced

**1. Reconciling two slightly different specs (case study PDF vs. UI
screenshots).** The original case-study brief sketched a minimal schema
(`Employee`, `Job`, `Timesheet`, `TimesheetEntry`) with no auth or admin
module, while the supplied UI screenshots clearly implied per-employee
job assignment, an admin role, monthly reports, holidays, and absence
tracking. **Solution:** built to the fuller, screenshot-implied scope
(separate `employees`/`jobs`/`employee_jobs`/`timesheets`/
`timesheet_entries`/`holidays`/`sessions` tables) since that's what the
actual feature list and UI require.

**2. Making "edit a previous timesheet" idempotent.** A naive
implementation could duplicate `timesheet_entries` rows every time an
employee re-saved a week. **Solution:** upsert keyed on
`(timesheet_id, job_id, entry_date)` — re-saving the same week always
updates existing rows rather than inserting new ones.

**3. Enumeration-style absence rules.** "Don't show today, don't show
the future, don't count weekends or holidays as absences" required
careful date-range construction rather than a single SQL `WHERE` clause.
**Solution:** the absence service builds the candidate weekday range
first, then subtracts holidays and days with any logged hours, rather
than trying to express all the exclusions in one query.

**4. Revoking access before JWT expiry.** A pure stateless-JWT design
means a logged-out token stays technically valid until it expires.
**Solution:** added a server-side `sessions` table (storing a hashed
token, not the raw value) that's checked on every authenticated request;
logout and password-change close the relevant session row, which the
auth middleware treats as immediate revocation regardless of the JWT's
own expiry.

**5. Picking a token storage mechanism that's actually safe on web.**
`shared_preferences` stores data in plain, easily-inspectable browser
storage. **Solution:** used `flutter_secure_storage` for the JWT
specifically, while keeping lower-stakes preferences (theme mode) in
`shared_preferences`.

**6. Verifying a project that was authored without a live runtime.**
The codebase was originally written without network/Flutter SDK access
in its build environment, so issues like the `CardThemeData` Flutter-
version mismatch and the CORS-vs-random-port conflict only surfaced once
it was actually run on a real machine. **Solution:** documented every
fix found this way directly in this README's [Known Issues](#-known-issues--fixes-applied)
section instead of silently patching and hoping nothing else breaks.

---

Made with ❤️ by Harini R

⚡ Turning employee hours into organized, validated, and trackable timesheets