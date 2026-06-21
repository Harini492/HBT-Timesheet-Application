const db = require('../../config/database');
const { monthRange, toISODate, isPast, getWeekDates } = require('../../utils/dateUtils');

// Monthly report: matches screenshot 2 — per job row, total + per-day hours,
// only jobs with at least one hour logged in the month are returned.
function monthlyReport(employeeId, year, month) {
  const { start, end } = monthRange(year, month);

  const entries = db.prepare(`
    SELECT te.entry_date, te.hours, j.id AS job_id, j.job_code, j.job_description
    FROM timesheet_entries te
    JOIN timesheets t ON t.id = te.timesheet_id
    JOIN jobs j ON j.id = te.job_id
    WHERE t.employee_id = ? AND te.entry_date BETWEEN ? AND ? AND te.hours > 0
    ORDER BY j.job_description, te.entry_date
  `).all(employeeId, start, end);

  const jobMap = new Map();
  for (const row of entries) {
    if (!jobMap.has(row.job_id)) {
      jobMap.set(row.job_id, {
        jobId: row.job_id,
        jobCode: row.job_code,
        jobDescription: row.job_description,
        total: 0,
        dailyHours: {},
      });
    }
    const job = jobMap.get(row.job_id);
    job.dailyHours[row.entry_date] = row.hours;
    job.total += row.hours;
  }

  const jobs = Array.from(jobMap.values()); // empty jobs already excluded by `hours > 0` filter
  const totalHours = jobs.reduce((sum, j) => sum + j.total, 0);

  return { year, month, start, end, jobs, totalHours };
}

// Absence report: any past weekday (excludes today/future) in the range with
// zero logged hours across all the employee's assigned jobs is flagged.
function absenceReport(employeeId, startISO, endISO) {
  const today = toISODate(new Date());
  let start = startISO;
  let end = endISO;
  if (!start || !end) {
    const r = monthRange(new Date().getFullYear(), new Date().getMonth() + 1);
    start = r.start;
    end = today; // month-to-date
  }

  const loggedDates = new Set(
    db.prepare(`
      SELECT DISTINCT te.entry_date FROM timesheet_entries te
      JOIN timesheets t ON t.id = te.timesheet_id
      WHERE t.employee_id = ? AND te.entry_date BETWEEN ? AND ? AND te.hours > 0
    `).all(employeeId, start, end).map((r) => r.entry_date)
  );

  const holidaySet = new Set(
    db.prepare(`SELECT holiday_date FROM holidays WHERE holiday_date BETWEEN ? AND ?`).all(start, end)
      .map((r) => r.holiday_date)
  );

  const absences = [];
  let cursor = new Date(start);
  const endDate = new Date(end);
  while (cursor <= endDate) {
    const iso = toISODate(cursor);
    const dow = cursor.getDay();
    const isWeekend = dow === 0 || dow === 6;
    if (
      isPast(iso) &&
      iso !== today &&
      !isWeekend &&
      !holidaySet.has(iso) &&
      !loggedDates.has(iso)
    ) {
      absences.push(iso);
    }
    cursor.setDate(cursor.getDate() + 1);
  }

  return { employeeId: Number(employeeId), start, end, absentDates: absences, absentDayCount: absences.length };
}

module.exports = { monthlyReport, absenceReport };
