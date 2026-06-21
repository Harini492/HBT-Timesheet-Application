const db = require('../../config/database');
const { getWeekStart, getWeekDates, monthRange, toISODate } = require('../../utils/dateUtils');

// Admin-only summary: headcount + hours for the current week/month, plus
// "present today" based on whether each active employee has logged at
// least one hour today. Daily presence is a much clearer signal than
// weekly presence (a Monday morning would otherwise make almost everyone
// look "absent" for the week before anyone's had a chance to log time).
function summary() {
  const today = toISODate(new Date());
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

  // Distinct employees who logged at least one hour entry today.
  const presentTodayCount = db.prepare(`
    SELECT COUNT(DISTINCT t.employee_id) AS cnt
    FROM timesheet_entries te
    JOIN timesheets t ON t.id = te.timesheet_id
    JOIN employees e ON e.id = t.employee_id
    WHERE te.entry_date = ? AND te.hours > 0 AND e.role = 'employee' AND e.is_active = 1
  `).get(today).cnt;

  const weekTotalHours = db.prepare(`
    SELECT COALESCE(SUM(te.hours), 0) AS total
    FROM timesheet_entries te
    JOIN timesheets t ON t.id = te.timesheet_id
    JOIN employees e ON e.id = t.employee_id
    WHERE te.entry_date BETWEEN ? AND ? AND te.hours > 0 AND e.role = 'employee' AND e.is_active = 1
  `).get(weekStartISO, weekEnd).total;

  const monthTotalHours = db.prepare(`
    SELECT COALESCE(SUM(te.hours), 0) AS total
    FROM timesheet_entries te
    JOIN timesheets t ON t.id = te.timesheet_id
    JOIN employees e ON e.id = t.employee_id
    WHERE te.entry_date BETWEEN ? AND ? AND te.hours > 0 AND e.role = 'employee' AND e.is_active = 1
  `).get(monthStart, monthEnd).total;

  const presentToday = isWorkingDay ? presentTodayCount : 0;
  const absentToday = isWorkingDay ? Math.max(totalEmployees - presentTodayCount, 0) : 0;

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