const db = require('../../config/database');
const { AppError } = require('../../middleware/errorHandler');

function listAll() {
  return db.prepare('SELECT * FROM jobs WHERE is_active = 1 ORDER BY job_description').all();
}

// Role-aware: employees only see jobs assigned to them; admins see everything.
function listForUser(user) {
  if (user.role === 'admin') return listAll();
  return db.prepare(`
    SELECT j.* FROM jobs j
    JOIN employee_jobs ej ON ej.job_id = j.id
    WHERE ej.employee_id = ? AND j.is_active = 1
    ORDER BY j.job_description
  `).all(user.id);
}

function getById(id) {
  const job = db.prepare('SELECT * FROM jobs WHERE id = ?').get(id);
  if (!job) throw new AppError('Job not found', 404);
  return job;
}

function create({ jobCode, jobDescription }) {
  const existing = db.prepare('SELECT id FROM jobs WHERE job_code = ?').get(jobCode);
  if (existing) throw new AppError('Job code already exists', 409);
  const result = db.prepare(`
    INSERT INTO jobs (job_code, job_description) VALUES (?, ?)
  `).run(jobCode, jobDescription);
  return getById(result.lastInsertRowid);
}

function update(id, { jobCode, jobDescription, isActive }) {
  getById(id);
  db.prepare(`
    UPDATE jobs
    SET job_code = COALESCE(?, job_code),
        job_description = COALESCE(?, job_description),
        is_active = COALESCE(?, is_active),
        updated_at = datetime('now')
    WHERE id = ?
  `).run(jobCode ?? null, jobDescription ?? null, isActive === undefined ? null : (isActive ? 1 : 0), id);
  return getById(id);
}

function remove(id) {
  getById(id);
  db.prepare('DELETE FROM jobs WHERE id = ?').run(id);
}

module.exports = { listAll, listForUser, getById, create, update, remove };
