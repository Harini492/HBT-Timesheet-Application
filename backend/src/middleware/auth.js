const db = require('../config/database');
const { verifyToken, hashToken } = require('../utils/jwt');
const { AppError } = require('./errorHandler');

function authenticate(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) return next(new AppError('Authentication required', 401));

    let decoded;
    try {
      decoded = verifyToken(token);
    } catch (e) {
      return next(new AppError('Invalid or expired token', 401));
    }

    const tokenHash = hashToken(token);
    const session = db
      .prepare('SELECT * FROM sessions WHERE token_hash = ? AND is_active = 1')
      .get(tokenHash);

    if (!session) {
      return next(new AppError('Session is no longer active. Please log in again.', 401));
    }
    if (new Date(session.expires_at) < new Date()) {
      return next(new AppError('Session expired. Please log in again.', 401));
    }

    const employee = db
      .prepare('SELECT id, employee_code, name, email, role, is_active FROM employees WHERE id = ?')
      .get(decoded.employeeId);

    if (!employee || !employee.is_active) {
      return next(new AppError('Account is inactive', 401));
    }

    req.user = employee;
    req.sessionId = session.id;
    next();
  } catch (err) {
    next(err);
  }
}

function requireAdmin(req, res, next) {
  if (!req.user || req.user.role !== 'admin') {
    return next(new AppError('Admin access required', 403));
  }
  next();
}

module.exports = { authenticate, requireAdmin };
