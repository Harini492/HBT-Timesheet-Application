const db = require('../../config/database');
const { hashPassword, verifyPassword } = require('../../utils/password');
const { signToken, hashToken, getExpiryDate } = require('../../utils/jwt');
const { AppError } = require('../../middleware/errorHandler');

function login(employeeCode, password) {
  const employee = db
    .prepare('SELECT * FROM employees WHERE employee_code = ?')
    .get(employeeCode);

  if (!employee || !employee.is_active) {
    throw new AppError('Invalid employee ID or password', 401);
  }
  if (!verifyPassword(password, employee.password_hash)) {
    throw new AppError('Invalid employee ID or password', 401);
  }

  const token = signToken({ employeeId: employee.id, role: employee.role });
  const expiresAt = getExpiryDate();

  db.prepare(`
    INSERT INTO sessions (employee_id, token_hash, expires_at) VALUES (?, ?, ?)
  `).run(employee.id, hashToken(token), expiresAt);

  return {
    token,
    user: {
      id: employee.id,
      employeeCode: employee.employee_code,
      name: employee.name,
      email: employee.email,
      role: employee.role,
    },
  };
}

function logout(sessionId) {
  db.prepare(`
    UPDATE sessions SET is_active = 0, logout_time = datetime('now') WHERE id = ?
  `).run(sessionId);
}

function changePassword(employeeId, currentPassword, newPassword) {
  const employee = db.prepare('SELECT * FROM employees WHERE id = ?').get(employeeId);
  if (!employee) throw new AppError('Employee not found', 404);
  if (!verifyPassword(currentPassword, employee.password_hash)) {
    throw new AppError('Current password is incorrect', 400);
  }
  db.prepare(`
    UPDATE employees SET password_hash = ?, updated_at = datetime('now') WHERE id = ?
  `).run(hashPassword(newPassword), employeeId);
}

module.exports = { login, logout, changePassword };
