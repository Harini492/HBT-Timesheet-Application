const svc = require('./dashboard.service');

function summary(req, res, next) {
  try {
    res.json({ success: true, ...svc.summary() });
  } catch (err) {
    next(err);
  }
}

module.exports = { summary };