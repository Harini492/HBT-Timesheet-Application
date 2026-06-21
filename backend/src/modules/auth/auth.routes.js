const express = require('express');
const { body } = require('express-validator');
const ctrl = require('./auth.controller');
const validate = require('../../middleware/validate');
const { authenticate } = require('../../middleware/auth');

const router = express.Router();

router.post(
  '/login',
  [
    body('employeeCode').trim().notEmpty().withMessage('Employee ID is required'),
    body('password').notEmpty().withMessage('Password is required'),
  ],
  validate,
  ctrl.login
);

router.post('/logout', authenticate, ctrl.logout);

router.post(
  '/change-password',
  authenticate,
  [
    body('currentPassword').notEmpty().withMessage('Current password is required'),
    body('newPassword').isLength({ min: 6 }).withMessage('New password must be at least 6 characters'),
  ],
  validate,
  ctrl.changePassword
);

router.get('/me', authenticate, ctrl.me);

module.exports = router;
