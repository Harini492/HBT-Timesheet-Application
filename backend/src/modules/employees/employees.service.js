const db = require('../../config/database');
const { hashPassword } = require('../../utils/password');
const { AppError } = require('../../middleware/errorHandler');

const PUBLIC_FIELDS = 'id, employee_code, name, email, role, is_active, created_at, updated_at';

function list() {
  return db.prepare(`SELECT ${PUBLIC_FIELDS} FROM employees ORDER BY name`).all();
}

function getById(id) {
  const emp = db.prepare(`SELECT ${PUBLIC_FIELDS} FROM employees WHERE id = ?`).get(id);
  if (!emp) throw new AppError('Employee not found', 404);
  return emp;
}

function create({ employeeCode, name, email, password, role }) {
  const existing = db.prepare('SELECT id FROM employees WHERE employee_code = ?').get(employeeCode);
  if (existing) throw new AppError('Employee code already exists', 409);

  const result = db.prepare(`
    INSERT INTO employees (employee_code, name, email, password_hash, role)
    VALUES (?, ?, ?, ?, ?)
  `).run(employeeCode, name, email || null, hashPassword(password), role || 'employee');

  return getById(result.lastInsertRowid);
}

function update(id, { name, email, role, isActive }) {
  getById(id);
  db.prepare(`
    UPDATE employees
    SET name = COALESCE(?, name),
        email = COALESCE(?, email),
        role = COALESCE(?, role),
        is_active = COALESCE(?, is_active),
        updated_at = datetime('now')
    WHERE id = ?
  `).run(name ?? null, email ?? null, role ?? null, isActive === undefined ? null : (isActive ? 1 : 0), id);
  return getById(id);
}

function remove(id) {
  getById(id);
  db.prepare('DELETE FROM employees WHERE id = ?').run(id);
}

function resetPassword(id, newPassword) {
  getById(id);
  db.prepare(`
    UPDATE employees SET password_hash = ?, updated_at = datetime('now') WHERE id = ?
  `).run(hashPassword(newPassword), id);
}

function assignJob(employeeId, jobId) {
  getById(employeeId);
  const job = db.prepare('SELECT id FROM jobs WHERE id = ?').get(jobId);
  if (!job) throw new AppError('Job not found', 404);
  const existing = db.prepare('SELECT id FROM employee_jobs WHERE employee_id = ? AND job_id = ?').get(employeeId, jobId);
  if (existing) return;
  db.prepare('INSERT INTO employee_jobs (employee_id, job_id) VALUES (?, ?)').run(employeeId, jobId);
}

function unassignJob(employeeId, jobId) {
  db.prepare('DELETE FROM employee_jobs WHERE employee_id = ? AND job_id = ?').run(employeeId, jobId);
}

function getAssignedJobs(employeeId) {
  return db.prepare(`
    SELECT j.id, j.job_code, j.job_description
    FROM jobs j
    JOIN employee_jobs ej ON ej.job_id = j.id
    WHERE ej.employee_id = ? AND j.is_active = 1
    ORDER BY j.job_description
  `).all(employeeId);
}

module.exports = { list, getById, create, update, remove, resetPassword, assignJob, unassignJob, getAssignedJobs };
