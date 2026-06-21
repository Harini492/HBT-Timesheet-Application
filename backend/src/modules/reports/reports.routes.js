const express = require('express');
const ctrl = require('./reports.controller');
const { authenticate } = require('../../middleware/auth');

const router = express.Router();
router.use(authenticate);

router.get('/monthly', ctrl.monthly);
router.get('/absence', ctrl.absence);

module.exports = router;
