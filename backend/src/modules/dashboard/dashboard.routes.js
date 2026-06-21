const express = require('express');
const ctrl = require('./dashboard.controller');
const { authenticate, requireAdmin } = require('../../middleware/auth');

const router = express.Router();
router.use(authenticate, requireAdmin);

router.get('/summary', ctrl.summary);

module.exports = router;