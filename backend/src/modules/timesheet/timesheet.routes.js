const express = require('express');
const { body, query } = require('express-validator');
const ctrl = require('./timesheet.controller');
const validate = require('../../middleware/validate');
const { authenticate } = require('../../middleware/auth');

const router = express.Router();
router.use(authenticate);

router.get('/', [query('weekStart').optional().isISO8601()], validate, ctrl.getWeek);

const saveValidation = [
  body('weekStart').isISO8601().withMessage('weekStart must be an ISO date (YYYY-MM-DD)'),
  body('entries').isArray().withMessage('entries must be an array'),
  body('entries.*.jobId').isInt(),
  body('entries.*.date').isISO8601(),
  body('entries.*.hours').isFloat({ min: 0, max: 24 }),
];

router.post('/', saveValidation, validate, ctrl.save);
router.put('/', saveValidation, validate, ctrl.update);
router.delete('/:id', ctrl.remove);

module.exports = router;
