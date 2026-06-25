# 🗓️ Timesheet Management System

A full-stack **Timesheet Management Application** built for HBT Group (HBT Engineering Pvt. Limited), enabling employees to log weekly work hours against assigned jobs and allowing admins to manage employees, jobs, holidays, and generate reports.

---

## 📋 Table of Contents

- [Tech Stack](#-tech-stack)
- [Features](#-features)
- [Architecture & Assumptions](#-architecture--assumptions)
- [Folder Structure](#-folder-structure)
- [Setup & Installation](#-setup--installation)
  - [Prerequisites](#prerequisites)
  - [Backend Setup](#backend-setup)
  - [Frontend Setup](#frontend-setup)
  - [Docker Setup (Optional)](#docker-setup-optional)
- [Default Credentials](#-default-credentials)
- [API Overview](#-api-overview)
- [Database Schema](#-database-schema)

---

## 🛠️ Tech Stack

| Layer     | Technology                                                     |
|-----------|----------------------------------------------------------------|
| Frontend  | Flutter (Dart) · flutter_riverpod · go_router · dio           |
| Backend   | Node.js · Express.js                                          |
| Database  | SQLite (via `better-sqlite3`)                                 |
| Auth      | JWT (JSON Web Tokens) · bcryptjs · Session tracking           |
| Export    | Excel (.xlsx) via `excel` Flutter package                     |
| DevOps    | Docker · Docker Compose                                       |

---

## ✨ Features

**Employee**
- Login with Employee Code and password
- View and log hours in a weekly timesheet grid (Mon–Sun)
- Add or remove job rows from assigned jobs only
- View absence/holiday calendar
- Change password
- Export monthly timesheet report to Excel

**Admin**
- Admin dashboard with summary stats
- Manage employees (create, edit, deactivate)
- Manage jobs (create, edit, toggle active)
- Manage public holidays
- View reports across employees
- Full access to all timesheet data

---

## 🏗️ Architecture & Assumptions

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter Frontend                     │
│  go_router (navigation) + flutter_riverpod (state)      │
│  dio (HTTP client) + flutter_secure_storage (JWT)       │
└─────────────────────┬───────────────────────────────────┘
                      │  REST API (HTTP/JSON)
                      │  Base URL: http://localhost:4000
                      ▼
┌─────────────────────────────────────────────────────────┐
│              Node.js / Express Backend                   │
│  Modular structure: auth · employees · jobs ·           │
│  timesheet · reports · holidays · dashboard · week      │
│  Middleware: JWT auth · Helmet · CORS · Morgan          │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│              SQLite Database (better-sqlite3)            │
│  File-based · Persisted via Docker volume or local path │
└─────────────────────────────────────────────────────────┘
```

### Key Assumptions

- **Week starts on Monday.** All timesheet weeks are anchored to the Monday of the selected week.
- **Hours are numeric (decimal).** E.g., `7.5` for 7 hours 30 minutes. Max 24h per day per job.
- **Employees can only log hours against jobs assigned to them** by an admin.
- **JWT tokens expire after 8 hours.** Sessions are tracked server-side; logout invalidates the session.
- **One timesheet record per employee per week.** Saving is an upsert — re-submitting the same week overwrites existing entries.
- **SQLite is sufficient** for the expected single-team scale; no connection pool or replication is required.
- **Flutter Web** is the primary deployment target (served via nginx in Docker). Native mobile/desktop builds are supported but not containerized.
- **Admin role** is set at account creation and cannot be self-assigned.
- **Holidays are global** (not per-employee) and are used to mark non-working days in the timesheet calendar view.

---

## 📁 Folder Structure

```
Timesheet-app-main/
├── docker-compose.yml              # Orchestrates backend + frontend containers
│
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   ├── .env.example                # Environment variable template
│   └── src/
│       ├── server.js               # Entry point — starts HTTP server
│       ├── app.js                  # Express app setup, middleware, route mounting
│       ├── config/
│       │   └── database.js         # SQLite connection (better-sqlite3)
│       ├── db/
│       │   ├── schema.sql          # Table definitions and indexes
│       │   ├── migrate.js          # Runs schema.sql on startup
│       │   └── seed.js             # Seeds default admin, employees, and jobs
│       ├── middleware/
│       │   ├── auth.js             # JWT verification middleware
│       │   ├── errorHandler.js     # Global error handler + AppError class
│       │   └── validate.js         # express-validator result checker
│       ├── modules/                # Feature modules (controller · service · routes)
│       │   ├── auth/
│       │   ├── employees/
│       │   ├── jobs/
│       │   ├── timesheet/
│       │   ├── week/
│       │   ├── reports/
│       │   ├── holidays/
│       │   └── dashboard/
│       ├── utils/
│       │   ├── dateUtils.js        # Week boundary calculations, ISO date helpers
│       │   ├── jwt.js              # Sign, verify, hash token utilities
│       │   └── password.js         # bcrypt hash and verify
│       └── tests/
│           ├── dateUtils.test.js
│           ├── password.test.js
│           └── timesheet.service.test.js
│
└── frontend/
    ├── Dockerfile
    ├── pubspec.yaml                # Flutter dependencies
    └── lib/
        ├── main.dart               # App entry point — ProviderScope + MaterialApp
        ├── core/
        │   ├── config/             # API base URL, app-wide constants
        │   ├── errors/             # Custom exception classes
        │   ├── models/             # Shared models (UserModel)
        │   ├── network/            # Dio client with JWT interceptor
        │   ├── providers/          # Core Riverpod providers (auth, router)
        │   ├── router/             # go_router route definitions + guards
        │   ├── storage/            # flutter_secure_storage wrapper (token)
        │   ├── theme/              # App colors, text styles, Material theme
        │   └── widgets/            # Reusable widgets (button, text field, etc.)
        └── features/
            ├── auth/               # Login screen, auth state, auth notifier
            ├── dashboard/          # Shell layout, sidebar, top bar
            ├── timesheet/          # Weekly grid, row widget, add-job picker
            ├── absences/           # Absence / holiday calendar view
            ├── report/             # Monthly report screen + Excel exporter
            ├── holidays/           # Holiday management screen
            └── admin/
                ├── dashboard/      # Admin stats dashboard
                ├── employees/      # Employee management CRUD
                └── jobs/           # Job management CRUD
```

---

## 🚀 Setup & Installation

### Prerequisites

Make sure the following are installed on your machine:

| Tool           | Version      |
|----------------|--------------|
| Node.js        | ≥ 18.0.0     |
| npm            | ≥ 9.x        |
| Flutter SDK    | ≥ 3.3.0      |
| Dart SDK       | ≥ 3.3.0      |
| Docker         | ≥ 24.x *(optional)* |

---

### Backend Setup

```bash
# 1. Navigate to the backend directory
cd backend

# 2. Install dependencies
npm install

# 3. Create your environment file
cp .env.example .env
```

Edit `.env` with your configuration:

```env
PORT=4000
NODE_ENV=development
JWT_SECRET=your_long_random_secret_here
JWT_EXPIRES_IN=8h
DB_PATH=./data/timesheet.db
CORS_ORIGIN=http://localhost:3000
```

```bash
# 4. Run database migration and seed default data
npm run setup

# 5. Start the development server
npm run dev
```

> The backend will be running at **http://localhost:4000**
>
> Health check: `GET http://localhost:4000/health`

---

### Frontend Setup

```bash
# 1. Navigate to the frontend directory
cd frontend

# 2. Get Flutter packages
flutter pub get

# 3. Verify the API base URL matches your backend
# Edit: lib/core/config/api_constants.dart
# Default: http://localhost:4000
```

**Run on Web (recommended):**
```bash
flutter run -d chrome
```

**Run on Android/Desktop:**
```bash
flutter run                   # select device from list
flutter run -d windows        # Windows desktop
flutter run -d android        # Android device/emulator
```

> The Flutter web app will open at **http://localhost:3000** (or the port Flutter assigns)

---

### Docker Setup (Optional)

To run the entire stack with Docker Compose:

```bash
# From the project root
docker compose up --build
```

| Service  | URL                      |
|----------|--------------------------|
| Backend  | http://localhost:4000    |
| Frontend | http://localhost:8080    |

> **Note:** The Docker setup serves the Flutter **web** build via nginx. For native mobile/desktop targets, run Flutter locally as described above.

To stop and remove containers:
```bash
docker compose down
```

To reset the database volume:
```bash
docker compose down -v
```

---

## 🔑 Default Credentials

After running `npm run setup` (or Docker first boot), the following accounts are seeded:

| Role     | Employee Code | Password       |
|----------|---------------|----------------|
| Admin    | `ADMIN001`    | `Admin@123`    |
| Employee | `EMP1001`     | `Employee@123` |
| Employee | `EMP1002`     | `Employee@123` |
| Employee | `EMP1003`     | `Employee@123` |

> ⚠️ Change the admin password after first login in a production environment.

---

## 📡 API Overview

All routes are prefixed with the backend base URL (default: `http://localhost:4000`).  
Protected routes require the `Authorization: Bearer <token>` header.

| Method | Endpoint                  | Auth     | Description                        |
|--------|---------------------------|----------|------------------------------------|
| POST   | `/auth/login`             | Public   | Login and receive JWT token        |
| POST   | `/auth/logout`            | Required | Invalidate current session         |
| POST   | `/auth/change-password`   | Required | Change logged-in user's password   |
| GET    | `/auth/me`                | Required | Get current user profile           |
| GET    | `/employees`              | Admin    | List all employees                 |
| POST   | `/employees`              | Admin    | Create a new employee              |
| PUT    | `/employees/:id`          | Admin    | Update employee details            |
| GET    | `/jobs`                   | Required | List all active jobs               |
| POST   | `/jobs`                   | Admin    | Create a new job                   |
| GET    | `/timesheet`              | Required | Get timesheet for a given week     |
| POST   | `/timesheet`              | Required | Save / upsert weekly timesheet     |
| GET    | `/week`                   | Required | Get current week boundaries        |
| GET    | `/report`                 | Required | Get monthly hours report           |
| GET    | `/holidays`               | Required | List all holidays                  |
| POST   | `/holidays`               | Admin    | Add a public holiday               |
| DELETE | `/holidays/:id`           | Admin    | Remove a holiday                   |
| GET    | `/dashboard`              | Admin    | Get admin dashboard summary stats  |

---

## 🗄️ Database Schema

The SQLite database consists of the following tables:

```
employees         — Employee accounts with roles (admin / employee)
jobs              — Job codes and descriptions
employee_jobs     — Many-to-many: which jobs each employee is assigned
timesheets        — One record per employee per week (week_start_date)
timesheet_entries — Daily hour entries per job per timesheet
holidays          — Public holiday dates
sessions          — Active JWT sessions with expiry tracking
```

Key constraints:
- An employee can only have **one timesheet per week**.
- A timesheet entry is unique on `(timesheet_id, job_id, entry_date)` — saving re-runs an upsert.
- Hours per entry are validated between `0` and `24`.
- Sessions are soft-invalidated on logout (`is_active = 0`).
