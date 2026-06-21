const svc = require('./jobs.service');

function list(req, res, next) {
  try { res.json({ success: true, jobs: svc.listForUser(req.user) }); } catch (err) { next(err); }
}
function getOne(req, res, next) {
  try { res.json({ success: true, job: svc.getById(req.params.id) }); } catch (err) { next(err); }
}
function create(req, res, next) {
  try { res.status(201).json({ success: true, job: svc.create(req.body) }); } catch (err) { next(err); }
}
function update(req, res, next) {
  try { res.json({ success: true, job: svc.update(req.params.id, req.body) }); } catch (err) { next(err); }
}
function remove(req, res, next) {
  try { svc.remove(req.params.id); res.json({ success: true, message: 'Job deleted' }); } catch (err) { next(err); }
}

module.exports = { list, getOne, create, update, remove };
