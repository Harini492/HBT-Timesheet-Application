const jwt = require('jsonwebtoken');
const crypto = require('crypto');
require('dotenv').config();

const SECRET = process.env.JWT_SECRET || 'dev_secret_change_me';
const EXPIRES_IN = process.env.JWT_EXPIRES_IN || '8h';

function signToken(payload) {
  return jwt.sign(payload, SECRET, { expiresIn: EXPIRES_IN });
}

function verifyToken(token) {
  return jwt.verify(token, SECRET);
}

// We store a hash of the token (not the raw token) in the sessions table,
// so a leaked DB row can't be replayed as a bearer token.
function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function getExpiryDate() {
  // Mirrors EXPIRES_IN for the sessions.expires_at column.
  const match = /^(\d+)([hmd])$/.exec(EXPIRES_IN);
  const now = new Date();
  if (!match) return new Date(now.getTime() + 8 * 60 * 60 * 1000).toISOString();
  const value = parseInt(match[1], 10);
  const unit = match[2];
  const msPerUnit = { h: 3600000, m: 60000, d: 86400000 };
  return new Date(now.getTime() + value * msPerUnit[unit]).toISOString();
}

module.exports = { signToken, verifyToken, hashToken, getExpiryDate };
