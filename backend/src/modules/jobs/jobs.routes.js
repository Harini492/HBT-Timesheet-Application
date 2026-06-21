const express = require('express');
const { body } = require('express-validator');
const ctrl = require('./jobs.controller');
const validate = require('../../middleware/validate');
const { authenticate, requireAdmin } = require('../../middleware/auth');

const router = express.Router();

router.use(authenticate);

router.get('/', ctrl.list);
router.get('/:id', ctrl.getOne);

router.post(
  '/',
  requireAdmin,
  [body('jobCode').trim().notEmpty(), body('jobDescription').trim().notEmpty()],
  validate,
  ctrl.create
);
router.put('/:id', requireAdmin, ctrl.update);
router.delete('/:id', requireAdmin, ctrl.remove);

module.exports = router;
