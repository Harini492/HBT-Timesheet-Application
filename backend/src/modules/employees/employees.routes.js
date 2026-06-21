const express = require('express');
const { body } = require('express-validator');
const ctrl = require('./employees.controller');
const validate = require('../../middleware/validate');
const { authenticate, requireAdmin } = require('../../middleware/auth');

const router = express.Router();

router.use(authenticate, requireAdmin);

router.get('/', ctrl.list);
router.get('/:id', ctrl.getOne);
router.get('/:id/jobs', ctrl.assignedJobs);

router.post(
  '/',
  [
    body('employeeCode').trim().notEmpty(),
    body('name').trim().notEmpty(),
    body('password').isLength({ min: 6 }),
    body('role').optional().isIn(['admin', 'employee']),
  ],
  validate,
  ctrl.create
);

router.put('/:id', ctrl.update);
router.delete('/:id', ctrl.remove);
router.post('/:id/reset-password', [body('newPassword').isLength({ min: 6 })], validate, ctrl.resetPassword);
router.post('/:id/jobs', [body('jobId').isInt()], validate, ctrl.assignJob);
router.delete('/:id/jobs/:jobId', ctrl.unassignJob);

module.exports = router;
