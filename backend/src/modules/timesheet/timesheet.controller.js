const svc = require('./timesheet.service');
const { toISODate } = require('../../utils/dateUtils');

function getWeek(req, res, next) {
  try {
    const weekStart = req.query.weekStart || toISODate(new Date());
    const employeeId = req.user.role === 'admin' && req.query.employeeId ? req.query.employeeId : req.user.id;
    res.json({ success: true, ...svc.getWeekGrid(employeeId, weekStart) });
  } catch (err) {
    next(err);
  }
}

function save(req, res, next) {
  try {
    const { weekStart, entries } = req.body;
    const employeeId = req.user.role === 'admin' && req.body.employeeId ? req.body.employeeId : req.user.id;
    const result = svc.saveWeek(employeeId, weekStart, entries);
    res.json({ success: true, ...result });
  } catch (err) {
    next(err);
  }
}

function update(req, res, next) {
  // PUT behaves the same as POST here (full-week upsert) per the spec's PUT /timesheet.
  save(req, res, next);
}

function remove(req, res, next) {
  try {
    svc.deleteEntry(req.params.id, req.user);
    res.json({ success: true, message: 'Timesheet entry deleted' });
  } catch (err) {
    next(err);
  }
}

module.exports = { getWeek, save, update, remove };
