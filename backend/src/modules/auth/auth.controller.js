const authService = require('./auth.service');

function login(req, res, next) {
  try {
    const { employeeCode, password } = req.body;
    const result = authService.login(employeeCode, password);
    res.json({ success: true, ...result });
  } catch (err) {
    next(err);
  }
}

function logout(req, res, next) {
  try {
    authService.logout(req.sessionId);
    res.json({ success: true, message: 'Logged out successfully' });
  } catch (err) {
    next(err);
  }
}

function changePassword(req, res, next) {
  try {
    const { currentPassword, newPassword } = req.body;
    authService.changePassword(req.user.id, currentPassword, newPassword);
    res.json({ success: true, message: 'Password changed successfully' });
  } catch (err) {
    next(err);
  }
}

function me(req, res) {
  res.json({ success: true, user: req.user });
}

module.exports = { login, logout, changePassword, me };
