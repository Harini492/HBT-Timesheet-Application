const svc = require('./holidays.service');

function list(req, res, next) {
  try { res.json({ success: true, holidays: svc.list(req.query.year) }); } catch (err) { next(err); }
}
function create(req, res, next) {
  try { res.status(201).json({ success: true, holiday: svc.create(req.body) }); } catch (err) { next(err); }
}
function remove(req, res, next) {
  try { svc.remove(req.params.id); res.json({ success: true, message: 'Holiday deleted' }); } catch (err) { next(err); }
}

module.exports = { list, create, remove };
