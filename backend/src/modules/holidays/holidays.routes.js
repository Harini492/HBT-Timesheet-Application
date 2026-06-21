const express = require('express');
const { body } = require('express-validator');
const ctrl = require('./holidays.controller');
const validate = require('../../middleware/validate');
const { authenticate, requireAdmin } = require('../../middleware/auth');

const router = express.Router();
router.use(authenticate);

router.get('/', ctrl.list);
router.post('/', requireAdmin, [body('date').isISO8601(), body('name').trim().notEmpty()], validate, ctrl.create);
router.delete('/:id', requireAdmin, ctrl.remove);

module.exports = router;
