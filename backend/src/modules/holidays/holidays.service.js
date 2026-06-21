const db = require('../../config/database');
const { AppError } = require('../../middleware/errorHandler');

function list(year) {
  if (year) {
    return db.prepare(`
      SELECT * FROM holidays WHERE holiday_date LIKE ? ORDER BY holiday_date
    `).all(`${year}-%`);
  }
  return db.prepare('SELECT * FROM holidays ORDER BY holiday_date').all();
}

function create({ date, name }) {
  const existing = db.prepare('SELECT id FROM holidays WHERE holiday_date = ?').get(date);
  if (existing) throw new AppError('A holiday already exists on this date', 409);
  const result = db.prepare('INSERT INTO holidays (holiday_date, name) VALUES (?, ?)').run(date, name);
  return db.prepare('SELECT * FROM holidays WHERE id = ?').get(result.lastInsertRowid);
}

function remove(id) {
  const existing = db.prepare('SELECT id FROM holidays WHERE id = ?').get(id);
  if (!existing) throw new AppError('Holiday not found', 404);
  db.prepare('DELETE FROM holidays WHERE id = ?').run(id);
}

module.exports = { list, create, remove };
