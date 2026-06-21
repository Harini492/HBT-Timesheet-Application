const svc = require('./reports.service');

function monthly(req, res, next) {
  try {
    const employeeId = req.user.role === 'admin' && req.query.employeeId ? req.query.employeeId : req.user.id;
    const year = parseInt(req.query.year, 10) || new Date().getFullYear();
    const month = parseInt(req.query.month, 10) || new Date().getMonth() + 1;
    res.json({ success: true, ...svc.monthlyReport(employeeId, year, month) });
  } catch (err) {
    next(err);
  }
}

function absence(req, res, next) {
  try {
    const employeeId = req.user.role === 'admin' && req.query.employeeId ? req.query.employeeId : req.user.id;
    res.json({ success: true, ...svc.absenceReport(employeeId, req.query.start, req.query.end) });
  } catch (err) {
    next(err);
  }
}

module.exports = { monthly, absence };
