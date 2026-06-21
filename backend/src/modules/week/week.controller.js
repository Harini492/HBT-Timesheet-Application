const svc = require('./week.service');

function getWeek(req, res, next) {
  try {
    const employeeId = req.user.role === 'admin' && req.query.employeeId ? req.query.employeeId : req.user.id;
    const result = svc.getWeek(employeeId, req.params.date);
    res.json({ success: true, ...result });
  } catch (err) {
    next(err);
  }
}

module.exports = { getWeek };
