# HBT Timesheet Management System

A full-stack employee timesheet application built for the HBT Group Technical Assessment.

**Stack:** Flutter · Node.js / Express · SQLite · JWT Auth · Docker

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Quick Start](#2-quick-start)
3. [Architecture & Design Decisions](#3-architecture--design-decisions)
4. [Database Schema](#4-database-schema)
5. [API Reference](#5-api-reference)
6. [Features Implemented](#6-features-implemented)
7. [Assumptions](#7-assumptions)

---

## 1. Project Structure

```
Timesheet-app/
├── backend/
│   ├── src/
│   │   ├── config/          # DB connection (better-sqlite3)
│   │   ├── db/              # schema.sql · migrate.js · seed.js
│   │   ├── middleware/      # JWT auth · error handler · request validator
│   │   ├── modules/
│   │   │   ├── auth/        # login · logout · change-password · /me
│   │   │   ├── employees/   # CRUD + job assignment (admin-only)
│   │   │   ├── jobs/        # CRUD (admin-only write; employees read own jobs)
│   │   │   ├── timesheet/   # weekly upsert · GET · DELETE
│   │   │   ├── week/        # GET /week/:date — enriched week metadata
│   │   │   ├── reports/     # monthly hours · absence tracking
│   │   │   ├── holidays/    # CRUD public holidays
│   │   │   └── dashboard/   # admin summary (headcount + hours)
│   │   └── utils/           # JWT helpers · bcrypt · date utilities
│   ├── tests/               # node:test unit tests
│   └── Dockerfile
├── frontend/
│   ├── lib/
│   │   ├── core/            # theme · router · Dio client · token storage · shared widgets
│   │   └── features/
│   │       ├── auth/        # login screen · change-password dialog
│   │       ├── dashboard/   # responsive shell · sidebar · top bar
│   │       ├── timesheet/   # weekly grid · row widget · job picker
│   │       ├── report/      # monthly report · Excel export
│   │       ├── absences/    # absence list screen
│   │       ├── holidays/    # holidays screen
│   │       └── admin/       # dashboard · employees · jobs (admin-only)
│   ├── test/                # Flutter unit + widget tests
│   └── Dockerfile
└── docker-compose.yml
```

---

## 2. Quick Start

### Prerequisites

- Node.js ≥ 18
- Flutter SDK ≥ 3.3.0
- (Optional) Docker + Docker Compose

---

### Backend

```bash
cd backend
npm install
cp .env.example .env        # Edit JWT_SECRET if desired
npm run setup               # Runs migrations + seeds demo data
npm run dev                 # Starts on http://localhost:4000
```

Health check: `GET http://localhost:4000/health`

---

### Frontend

```bash
cd frontend
flutter pub get

# Android emulator (default baseUrl targets 10.0.2.2:4000):
flutter run

# Web / Desktop:
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000

# iOS Simulator:
flutter run --dart-define=API_BASE_URL=http://localhost:4000
```

---

### Docker (Backend + Web Frontend together)

```bash
docker compose up --build
# API  → http://localhost:4000
# Web  → http://localhost:8080
```

> Docker only builds the **web** target for Flutter. For Android/iOS, run `flutter run` locally pointing at the backend (dockerized or local).

---

### Demo Credentials (seeded automatically)

| Role     | Employee ID | Password     |
|----------|-------------|--------------|
| Admin    | ADMIN001    | Admin@123    |
| Employee | EMP1001     | Employee@123 |
| Employee | EMP1002     | Employee@123 |
| Employee | EMP1003     | Employee@123 |

---

## 3. Architecture & Design Decisions

### Backend

Follows a **layered module structure**: `routes → controller → service → DB` — each feature owns its own validation, business rules, and SQL queries. Cross-cutting concerns (auth, error formatting, request validation) live in `middleware/`.

**Key decisions:**

- **Session-backed JWT auth:** Tokens are signed JWTs, but each login also inserts a session row (storing a SHA-256 hash of the token, not the raw token). Logout invalidates the session immediately — the token is unusable even before its expiry. This avoids the stateless-JWT pitfall where a stolen token works until expiry.

- **Idempotent timesheet upsert:** `POST /timesheet` and `PUT /timesheet` are semantically identical — both do a full-week upsert keyed on `(timesheet_id, job_id, entry_date)`. Re-saving the same week updates existing rows; it never duplicates them.

- **Three-layer validation:** DB-level `CHECK (hours BETWEEN 0 AND 24)`, request-level `express-validator` schemas, and service-level checks (employees can only log hours against jobs explicitly assigned to them by an admin).

- **`login_time` timezone fix:** SQLite stores timestamps via `datetime('now')` in UTC. The dashboard's present/absent query uses `strftime('%Y-%m-%d', login_time, 'localtime')` to convert to local time before comparing with today's date, preventing a timezone mismatch (relevant for IST = UTC+5:30).

### Frontend

Uses a **feature-first folder structure** (`features/<name>/{data, domain, presentation}`), Riverpod `StateNotifierProvider`s for screen state, and Go Router with an auth-aware `redirect` callback.

**Key decisions:**

- **`PageHeader` is a plain widget, not `Scaffold.appBar`:** Each screen needs different trailing controls (Save + week nav on Timesheet, month nav on Report, Add button on Jobs/Employees). Making `PageHeader` a standalone widget lets every screen inject its own actions while sharing one consistent navy bar.

- **Responsive shell:** Permanent sidebar on screens ≥ 900 px; a `Drawer` on narrower viewports. Same nav content either way — one `Sidebar` widget handles both.

- **Absence detection logic:** Only past weekdays with zero logged hours count as an absence. Weekends, public holidays, today, and future dates are all excluded.

---

## 4. Database Schema

```sql
employees        (id, employee_code, name, email, password_hash, role, is_active, ...)
jobs             (id, job_code, job_description, is_active, ...)
employee_jobs    (id, employee_id → employees, job_id → jobs)          -- many-to-many
timesheets       (id, employee_id → employees, week_start_date, ...)   -- one per employee per week
timesheet_entries(id, timesheet_id → timesheets, job_id → jobs,
                  entry_date, hours CHECK(0..24), comment, ...)
holidays         (id, holiday_date UNIQUE, name, ...)
sessions         (id, employee_id → employees, token_hash,
                  login_time, logout_time, expires_at, is_active)
```

Indexes on: `timesheet_entries(entry_date)`, `timesheets(employee_id, week_start_date)`, `sessions(token_hash)`.

---

## 5. API Reference

All endpoints except `POST /auth/login` and `GET /health` require:
`Authorization: Bearer <token>`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/auth/login` | — | `{ employeeCode, password }` → `{ token, user }` |
| POST | `/auth/logout` | Employee | Invalidates current session |
| POST | `/auth/change-password` | Employee | Change own password |
| GET | `/auth/me` | Employee | Current user profile |
| GET | `/jobs` | Employee | Own assigned jobs / all jobs (admin) |
| POST | `/jobs` | Admin | Create job |
| PUT | `/jobs/:id` | Admin | Update job |
| DELETE | `/jobs/:id` | Admin | Delete job |
| GET | `/employees` | Admin | List all employees |
| POST | `/employees` | Admin | Create employee |
| PUT | `/employees/:id` | Admin | Update employee |
| DELETE | `/employees/:id` | Admin | Delete employee |
| POST | `/employees/:id/jobs` | Admin | Assign job to employee |
| DELETE | `/employees/:id/jobs/:jobId` | Admin | Unassign job |
| GET | `/timesheet?weekStart=YYYY-MM-DD` | Employee | Full week grid |
| POST | `/timesheet` | Employee | Save/upsert week entries |
| PUT | `/timesheet` | Employee | Update week entries (same as POST) |
| DELETE | `/timesheet/:id` | Employee | Delete a single entry |
| GET | `/week/:date` | Employee | Week metadata (days, dayNames, isToday flags) |
| GET | `/report/monthly?year=&month=` | Employee | Per-job monthly hours |
| GET | `/report/absence?start=&end=` | Admin | Absence report for date range |
| GET | `/holidays` | Employee | List public holidays |
| POST | `/holidays` | Admin | Add holiday |
| DELETE | `/holidays/:id` | Admin | Remove holiday |
| GET | `/dashboard/summary` | Admin | Today's headcount + weekly/monthly hours |

---

## 6. Features Implemented

### Core Requirements (Assessment)
- [x] Create Job Codes and Job Descriptions (admin)
- [x] View current week's timesheet
- [x] Enter hours per day (per job per date)
- [x] Save timesheet (POST/PUT upsert)
- [x] Edit previously saved entries
- [x] Calculate total weekly hours
- [x] Navigate to previous/next week
- [x] Load saved data from backend
- [x] Validate daily hours do not exceed 24

### Bonus Features
- [x] **Authentication** — JWT + server-side sessions, login/logout/change-password
- [x] **Admin module** — employee management, job management, dashboard
- [x] **Dark mode** — system-adaptive via Material 3 theme
- [x] **Monthly report** — per-job hour breakdown with Excel export
- [x] **Absence tracking** — flags past working days with no logged hours
- [x] **Public holidays** — admin-managed; excluded from absence detection
- [x] **Docker** — `docker compose up --build` runs both services
- [x] **Unit tests** — backend (node:test) + Flutter (flutter test)
- [x] **Clean architecture** — feature-first, layered, no god files
- [x] **Reusable widgets** — `PageHeader`, `LoadingView`, `ErrorView`, `EmptyView`, `AppTextField`, `PrimaryButton`
- [x] **Error handling** — global error middleware, Dio interceptors, user-facing error views
- [x] **Responsive UI** — sidebar on wide screens, drawer on narrow

---

## 7. Assumptions

- `PUT /timesheet` and `POST /timesheet` are treated as identical full-week upserts (the spec listed both without distinguishing semantics).
- Employees cannot add arbitrary jobs to their timesheet — they pick from jobs an admin has assigned to them (matches the dropdown-style job picker in the UI).
- Absence detection covers only *past working weekdays* (no weekends, no public holidays, not today, not future).
- Monthly report omits jobs with zero hours for the selected month.
- Roles are binary: `admin` or `employee`. No granular permissions.
- Present/Absent on the admin dashboard is based on **login sessions** (who has logged into the app today), not on whether timesheet hours have been submitted yet.
