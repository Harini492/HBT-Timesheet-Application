// Date helpers used across timesheet/week/report/absence features.
// All dates are treated as plain ISO strings (YYYY-MM-DD) in local/server time,
// matching the screenshots which show plain calendar dates with no timezone math.

const DAY_NAMES = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

function toISODate(date) {
  const d = date instanceof Date ? date : new Date(date);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function parseISODate(isoString) {
  const [y, m, d] = isoString.split('-').map(Number);
  return new Date(y, m - 1, d);
}

// Returns the Monday of the week containing `date` (any input date/string).
function getWeekStart(date) {
  const d = date instanceof Date ? new Date(date) : parseISODate(date);
  const day = d.getDay(); // 0=Sun..6=Sat
  const diff = day === 0 ? -6 : 1 - day; // shift back to Monday
  d.setDate(d.getDate() + diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

function getWeekEnd(weekStartDate) {
  const start = weekStartDate instanceof Date ? new Date(weekStartDate) : parseISODate(weekStartDate);
  const end = new Date(start);
  end.setDate(end.getDate() + 6);
  return end;
}

// Returns an array of 7 ISO date strings, Monday -> Sunday, for the given week start.
function getWeekDates(weekStartISO) {
  const start = parseISODate(weekStartISO);
  const dates = [];
  for (let i = 0; i < 7; i++) {
    const d = new Date(start);
    d.setDate(d.getDate() + i);
    dates.push(toISODate(d));
  }
  return dates;
}

function addDays(isoString, days) {
  const d = parseISODate(isoString);
  d.setDate(d.getDate() + days);
  return toISODate(d);
}

function dayNameFor(isoString) {
  const d = parseISODate(isoString);
  return DAY_NAMES[d.getDay()];
}

function isToday(isoString) {
  return isoString === toISODate(new Date());
}

function isPast(isoString) {
  return parseISODate(isoString) < parseISODate(toISODate(new Date()));
}

function previousWeekStart(weekStartISO) {
  return addDays(weekStartISO, -7);
}

function nextWeekStart(weekStartISO) {
  return addDays(weekStartISO, 7);
}

function monthRange(year, month) {
  // month: 1-12. Returns ISO start/end (inclusive) for that calendar month.
  const start = new Date(year, month - 1, 1);
  const end = new Date(year, month, 0);
  return { start: toISODate(start), end: toISODate(end) };
}

module.exports = {
  toISODate,
  parseISODate,
  getWeekStart,
  getWeekEnd,
  getWeekDates,
  addDays,
  dayNameFor,
  isToday,
  isPast,
  previousWeekStart,
  nextWeekStart,
  monthRange,
};
