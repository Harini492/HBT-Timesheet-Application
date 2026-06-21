// Integration-style tests against an isolated in-memory-like SQLite file.
const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');

const TEST_DB = path.join(__dirname, 'test.db');
if (fs.existsSync(TEST_DB)) fs.unlinkSync(TEST_DB);
process.env.DB_PATH = TEST_DB;

const migrate = require('../src/db/migrate');
const db = require('../src/config/database');
migrate();

const tsService = require('../src/modules/timesheet/timesheet.service');

function setupFixtures() {
  const emp = db.prepare(`
    INSERT INTO employees (employee_code, name, password_hash, role) VALUES ('T001', 'Test User', 'x', 'employee')
  `).run();
  const job = db.prepare(`
    INSERT INTO jobs (job_code, job_description) VALUES ('1234', 'Test Job')
  `).run();
  db.prepare(`INSERT INTO employee_jobs (employee_id, job_id) VALUES (?, ?)`).run(emp.lastInsertRowid, job.lastInsertRowid);
  return { employeeId: emp.lastInsertRowid, jobId: job.lastInsertRowid };
}

test('saveWeek rejects hours over 24', () => {
  const { employeeId, jobId } = setupFixtures();
  assert.throws(() => {
    tsService.saveWeek(employeeId, '2026-06-15', [{ jobId, date: '2026-06-15', hours: 25 }]);
  }, /between 0 and 24/);
});

test('saveWeek rejects jobs not assigned to the employee', () => {
  const { employeeId } = setupFixtures();
  assert.throws(() => {
    tsService.saveWeek(employeeId, '2026-06-15', [{ jobId: 9999, date: '2026-06-15', hours: 4 }]);
  }, /not assigned/);
});

test('saveWeek persists hours and getWeekGrid reflects the total', () => {
  const { employeeId, jobId } = setupFixtures();
  tsService.saveWeek(employeeId, '2026-06-15', [
    { jobId, date: '2026-06-15', hours: 8 },
    { jobId, date: '2026-06-16', hours: 6 },
  ]);
  const grid = tsService.getWeekGrid(employeeId, '2026-06-15');
  assert.strictEqual(grid.totalHours, 14);
  assert.strictEqual(grid.rows[0].hoursByDate['2026-06-15'], 8);
});

test.after(() => {
  db.close();
  if (fs.existsSync(TEST_DB)) fs.unlinkSync(TEST_DB);
  if (fs.existsSync(TEST_DB + '-wal')) fs.unlinkSync(TEST_DB + '-wal');
  if (fs.existsSync(TEST_DB + '-shm')) fs.unlinkSync(TEST_DB + '-shm');
});
