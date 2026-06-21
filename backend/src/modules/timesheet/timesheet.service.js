const db = require('../../config/database');
const { AppError } = require('../../middleware/errorHandler');
const { getWeekStart, getWeekDates, toISODate } = require('../../utils/dateUtils');

function findOrCreateTimesheet(employeeId, weekStartISO) {
  let ts = db.prepare(`
    SELECT * FROM timesheets WHERE employee_id = ? AND week_start_date = ?
  `).get(employeeId, weekStartISO);

  if (!ts) {
    const result = db.prepare(`
      INSERT INTO timesheets (employee_id, week_start_date) VALUES (?, ?)
    `).run(employeeId, weekStartISO);
    ts = db.prepare('SELECT * FROM timesheets WHERE id = ?').get(result.lastInsertRowid);
  }
  return ts;
}

// Returns the full grid for a week: every job assigned to the employee, with
// hours keyed by date (0 where nothing is saved), matching the screenshot's
// one-row-per-job layout.
function getWeekGrid(employeeId, weekStartISO) {
  const weekStart = getWeekStart(weekStartISO);
  const weekStartStr = toISODate(weekStart);
  const dates = getWeekDates(weekStartStr);

  const assignedJobs = db.prepare(`
    SELECT j.id, j.job_code, j.job_description
    FROM jobs j
    JOIN employee_jobs ej ON ej.job_id = j.id
    WHERE ej.employee_id = ? AND j.is_active = 1
    ORDER BY j.job_description
  `).all(employeeId);

  const ts = db.prepare(`
    SELECT * FROM timesheets WHERE employee_id = ? AND week_start_date = ?
  `).get(employeeId, weekStartStr);

  let entries = [];
  if (ts) {
    entries = db.prepare(`
      SELECT * FROM timesheet_entries WHERE timesheet_id = ?
    `).all(ts.id);
  }

  const entryMap = {}; // jobId -> { date -> entry }
  for (const e of entries) {
    if (!entryMap[e.job_id]) entryMap[e.job_id] = {};
    entryMap[e.job_id][e.entry_date] = e;
  }

  // Only include job rows that have at least one saved entry, plus all assigned jobs
  // (so the employee can always add hours against any assigned job, even with none saved yet).
  const rows = assignedJobs.map((job) => {
    const hoursByDate = {};
    let rowTotal = 0;
    for (const date of dates) {
      const entry = entryMap[job.id] && entryMap[job.id][date];
      const hours = entry ? entry.hours : 0;
      hoursByDate[date] = hours;
      rowTotal += hours;
    }
    return {
      jobId: job.id,
      jobCode: job.job_code,
      jobDescription: job.job_description,
      hoursByDate,
      rowTotal,
    };
  });

  const totalHours = rows.reduce((sum, r) => sum + r.rowTotal, 0);

  return {
    timesheetId: ts ? ts.id : null,
    employeeId: Number(employeeId),
    weekStart: weekStartStr,
    weekEnd: dates[6],
    dates,
    rows,
    totalHours,
  };
}

function saveWeek(employeeId, weekStartISO, entries) {
  // entries: [{ jobId, date, hours, comment? }]
  const weekStart = getWeekStart(weekStartISO);
  const weekStartStr = toISODate(weekStart);
  const validDates = new Set(getWeekDates(weekStartStr));

  const assignedJobIds = new Set(
    db.prepare('SELECT job_id FROM employee_jobs WHERE employee_id = ?').all(employeeId).map((r) => r.job_id)
  );

  for (const e of entries) {
    if (!assignedJobIds.has(Number(e.jobId))) {
      throw new AppError(`Job ${e.jobId} is not assigned to this employee`, 403);
    }
    if (!validDates.has(e.date)) {
      throw new AppError(`Date ${e.date} is not within the week starting ${weekStartStr}`, 400);
    }
    const hours = Number(e.hours);
    if (Number.isNaN(hours) || hours < 0 || hours > 24) {
      throw new AppError(`Hours for ${e.date} must be between 0 and 24`, 422);
    }
  }

  const ts = findOrCreateTimesheet(employeeId, weekStartStr);

  const upsert = db.prepare(`
    INSERT INTO timesheet_entries (timesheet_id, job_id, entry_date, hours, comment)
    VALUES (@timesheetId, @jobId, @date, @hours, @comment)
    ON CONFLICT(timesheet_id, job_id, entry_date)
    DO UPDATE SET hours = excluded.hours, comment = excluded.comment, updated_at = datetime('now')
  `);

  const txn = db.transaction((rows) => {
    for (const e of rows) {
      upsert.run({
        timesheetId: ts.id,
        jobId: e.jobId,
        date: e.date,
        hours: Number(e.hours),
        comment: e.comment || null,
      });
    }
    db.prepare(`UPDATE timesheets SET updated_at = datetime('now') WHERE id = ?`).run(ts.id);
  });
  txn(entries);

  return getWeekGrid(employeeId, weekStartStr);
}

function deleteEntry(entryId, requestingUser) {
  const entry = db.prepare(`
    SELECT te.*, t.employee_id FROM timesheet_entries te
    JOIN timesheets t ON t.id = te.timesheet_id
    WHERE te.id = ?
  `).get(entryId);

  if (!entry) throw new AppError('Timesheet entry not found', 404);
  if (requestingUser.role !== 'admin' && entry.employee_id !== requestingUser.id) {
    throw new AppError('You cannot delete another employee\'s entry', 403);
  }
  db.prepare('DELETE FROM timesheet_entries WHERE id = ?').run(entryId);
}

module.exports = { getWeekGrid, saveWeek, deleteEntry, findOrCreateTimesheet };
