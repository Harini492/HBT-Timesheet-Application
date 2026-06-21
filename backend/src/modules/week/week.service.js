const timesheetService = require('../timesheet/timesheet.service');
const { getWeekStart, getWeekDates, dayNameFor, isToday, toISODate } = require('../../utils/dateUtils');

// Implements GET /week/:date exactly: { weekStart, weekEnd, days }
// `days` is enriched with dayName/isToday/saved rows so the frontend can
// hydrate the whole grid (including "Go To Last Week") from one call.
function getWeek(employeeId, anyDateISO) {
  const grid = timesheetService.getWeekGrid(employeeId, anyDateISO);

  const days = grid.dates.map((date) => ({
    date,
    dayName: dayNameFor(date),
    isToday: isToday(date),
    totalHours: grid.rows.reduce((sum, r) => sum + (r.hoursByDate[date] || 0), 0),
  }));

  return {
    weekStart: grid.weekStart,
    weekEnd: grid.weekEnd,
    days,
    rows: grid.rows,
    totalHours: grid.totalHours,
  };
}

module.exports = { getWeek };
