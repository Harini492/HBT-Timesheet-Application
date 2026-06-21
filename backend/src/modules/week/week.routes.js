const express = require('express');
const { param } = require('express-validator');
const ctrl = require('./week.controller');
const validate = require('../../middleware/validate');
const { authenticate } = require('../../middleware/auth');

const router = express.Router();
router.get('/:date', authenticate, [param('date').isISO8601()], validate, ctrl.getWeek);

module.exports = router;
