const svc = require('./employees.service');

function list(req, res, next) {
  try { res.json({ success: true, employees: svc.list() }); } catch (err) { next(err); }
}
function getOne(req, res, next) {
  try { res.json({ success: true, employee: svc.getById(req.params.id) }); } catch (err) { next(err); }
}
function create(req, res, next) {
  try { res.status(201).json({ success: true, employee: svc.create(req.body) }); } catch (err) { next(err); }
}
function update(req, res, next) {
  try { res.json({ success: true, employee: svc.update(req.params.id, req.body) }); } catch (err) { next(err); }
}
function remove(req, res, next) {
  try { svc.remove(req.params.id); res.json({ success: true, message: 'Employee deleted' }); } catch (err) { next(err); }
}
function resetPassword(req, res, next) {
  try { svc.resetPassword(req.params.id, req.body.newPassword); res.json({ success: true, message: 'Password reset' }); } catch (err) { next(err); }
}
function assignJob(req, res, next) {
  try { svc.assignJob(req.params.id, req.body.jobId); res.json({ success: true, message: 'Job assigned' }); } catch (err) { next(err); }
}
function unassignJob(req, res, next) {
  try { svc.unassignJob(req.params.id, req.params.jobId); res.json({ success: true, message: 'Job unassigned' }); } catch (err) { next(err); }
}
function assignedJobs(req, res, next) {
  try { res.json({ success: true, jobs: svc.getAssignedJobs(req.params.id) }); } catch (err) { next(err); }
}

module.exports = { list, getOne, create, update, remove, resetPassword, assignJob, unassignJob, assignedJobs };
