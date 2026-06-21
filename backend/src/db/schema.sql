-- HBT Timesheet Management System - SQLite Schema

CREATE TABLE IF NOT EXISTS employees (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  employee_code   TEXT NOT NULL UNIQUE,
  name            TEXT NOT NULL,
  email           TEXT UNIQUE,
  password_hash   TEXT NOT NULL,
  role            TEXT NOT NULL DEFAULT 'employee' CHECK (role IN ('admin', 'employee')),
  is_active       INTEGER NOT NULL DEFAULT 1,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS jobs (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  job_code        TEXT NOT NULL UNIQUE,
  job_description TEXT NOT NULL,
  is_active       INTEGER NOT NULL DEFAULT 1,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS employee_jobs (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  employee_id     INTEGER NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  job_id          INTEGER NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(employee_id, job_id)
);

CREATE TABLE IF NOT EXISTS timesheets (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  employee_id     INTEGER NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  week_start_date TEXT NOT NULL,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(employee_id, week_start_date)
);

CREATE TABLE IF NOT EXISTS timesheet_entries (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  timesheet_id    INTEGER NOT NULL REFERENCES timesheets(id) ON DELETE CASCADE,
  job_id          INTEGER NOT NULL REFERENCES jobs(id) ON DELETE RESTRICT,
  entry_date      TEXT NOT NULL,
  hours           REAL NOT NULL DEFAULT 0 CHECK (hours >= 0 AND hours <= 24),
  comment         TEXT,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(timesheet_id, job_id, entry_date)
);

CREATE TABLE IF NOT EXISTS holidays (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  holiday_date    TEXT NOT NULL UNIQUE,
  name            TEXT NOT NULL,
  created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS sessions (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  employee_id     INTEGER NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  token_hash      TEXT NOT NULL,
  login_time      TEXT NOT NULL DEFAULT (datetime('now')),
  logout_time     TEXT,
  expires_at      TEXT NOT NULL,
  is_active       INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_entries_timesheet ON timesheet_entries(timesheet_id);
CREATE INDEX IF NOT EXISTS idx_entries_date ON timesheet_entries(entry_date);
CREATE INDEX IF NOT EXISTS idx_timesheets_employee_week ON timesheets(employee_id, week_start_date);
CREATE INDEX IF NOT EXISTS idx_employee_jobs_employee ON employee_jobs(employee_id);
CREATE INDEX IF NOT EXISTS idx_sessions_employee ON sessions(employee_id);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(token_hash);
