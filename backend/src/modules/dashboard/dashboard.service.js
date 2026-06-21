const db = require('../../config/database');
const { getWeekStart, getWeekDates, monthRange, toISODate } = require('../../utils/dateUtils');

// Admin-only summary: headcount + hours for the current week/month, plus
// "present today" = employees who have logged into the app today (session exists).
// "absent today"  = active employees who have NOT logged in today.
// Both are shown every day (including weekends) — isWorkingDay only controls
// whether the "not a working day" banner appears, not whether counts are shown.
function summary() {
  const today = toISODate(new Date()); // local date YYYY-MM-DD (e.g. IST)
  const weekStartISO = toISODate(getWeekStart(today));
  const weekDates = getWeekDates(weekStartISO);
  const weekEnd = weekDates[weekDates.length - 1];

  const { start: monthStart, end: monthEnd } = monthRange(
    new Date().getFullYear(),
    new Date().getMonth() + 1
  );

  const dayOfWeek = new Date(today).getDay(); // 0=Sun..6=Sat
  const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;
  const isHoliday = !!db.prepare('SELECT 1 FROM holidays WHERE holiday_date = ?').get(today);
  const isWorkingDay = !isWeekend && !isHoliday;

  const activeEmployees = db.prepare(`
    SELECT id FROM employees WHERE role = 'employee' AND is_active = 1
  `).all();
  const totalEmployees = activeEmployees.length;

  // Present = employees with at least one session whose login_time falls on today
  // (local date). SQLite stores login_time as UTC via datetime('now'), so we
  // convert it to local time using strftime with the localtime modifier.
  const presentTodayCount = db.prepare(`
    SELECT COUNT(DISTINCT s.employee_id) AS cnt
    FROM sessions s
    JOIN employees e ON e.id = s.employee_id
    WHERE strftime('%Y-%m-%d', s.login_time, 'localtime') = ?
      AND e.role = 'employee'
      AND e.is_active = 1
  `).get(today).cnt;

  const weekTotalHours = db.prepare(`
    SELECT COALESCE(SUM(te.hours), 0) AS total
    FROM timesheet_entries te
    JOIN timesheets t ON t.id = te.timesheet_id
    JOIN employees e ON e.id = t.employee_id
    WHERE te.entry_date BETWEEN ? AND ?
      AND te.hours > 0
      AND e.role = 'employee'
      AND e.is_active = 1
  `).get(weekStartISO, weekEnd).total;

  const monthTotalHours = db.prepare(`
    SELECT COALESCE(SUM(te.hours), 0) AS total
    FROM timesheet_entries te
    JOIN timesheets t ON t.id = te.timesheet_id
    JOIN employees e ON e.id = t.employee_id
    WHERE te.entry_date BETWEEN ? AND ?
      AND te.hours > 0
      AND e.role = 'employee'
      AND e.is_active = 1
  `).get(monthStart, monthEnd).total;

  // Show present/absent counts always — even on weekends/holidays.
  // The "not a working day" banner informs the admin contextually.
  const presentToday = presentTodayCount;
  const absentToday = Math.max(totalEmployees - presentTodayCount, 0);

  return {
    today,
    isWorkingDay,
    weekStart: weekStartISO,
    weekEnd,
    monthStart,
    monthEnd,
    totalEmployees,
    presentToday,
    absentToday,
    weekTotalHours,
    monthTotalHours,
    averageWeekHoursPerEmployee: totalEmployees > 0 ? weekTotalHours / totalEmployees : 0,
  };
}

module.exports = { summary };
