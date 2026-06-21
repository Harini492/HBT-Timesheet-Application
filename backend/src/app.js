const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const { notFoundHandler, errorHandler } = require('./middleware/errorHandler');

const authRoutes = require('./modules/auth/auth.routes');
const employeeRoutes = require('./modules/employees/employees.routes');
const jobRoutes = require('./modules/jobs/jobs.routes');
const timesheetRoutes = require('./modules/timesheet/timesheet.routes');
const weekRoutes = require('./modules/week/week.routes');
const reportRoutes = require('./modules/reports/reports.routes');
const holidayRoutes = require('./modules/holidays/holidays.routes');
const dashboardRoutes = require('./modules/dashboard/dashboard.routes');

const app = express();

app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN || '*', credentials: true }));
app.use(express.json());
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

app.get('/health', (req, res) => {
  res.json({ success: true, status: 'ok', timestamp: new Date().toISOString() });
});

app.use('/auth', authRoutes);
app.use('/employees', employeeRoutes);
app.use('/jobs', jobRoutes);
app.use('/timesheet', timesheetRoutes);
app.use('/week', weekRoutes);
app.use('/report', reportRoutes);
app.use('/holidays', holidayRoutes);
app.use('/dashboard', dashboardRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;