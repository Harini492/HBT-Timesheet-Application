const test = require('node:test');
const assert = require('node:assert');
const {
  getWeekStart, getWeekDates, dayNameFor, addDays, toISODate, monthRange,
} = require('../src/utils/dateUtils');

test('getWeekStart returns Monday for a mid-week date', () => {
  // 2026-06-17 is a Wednesday
  const start = getWeekStart('2026-06-17');
  assert.strictEqual(toISODate(start), '2026-06-15'); // Monday
});

test('getWeekStart returns same date when already Monday', () => {
  const start = getWeekStart('2026-06-15');
  assert.strictEqual(toISODate(start), '2026-06-15');
});

test('getWeekDates returns 7 consecutive days Mon-Sun', () => {
  const dates = getWeekDates('2026-06-15');
  assert.strictEqual(dates.length, 7);
  assert.strictEqual(dates[0], '2026-06-15');
  assert.strictEqual(dates[6], '2026-06-21');
});

test('dayNameFor matches expected weekday', () => {
  assert.strictEqual(dayNameFor('2026-06-15'), 'Mon');
  assert.strictEqual(dayNameFor('2026-06-21'), 'Sun');
});

test('addDays moves forward and backward correctly', () => {
  assert.strictEqual(addDays('2026-06-15', 7), '2026-06-22');
  assert.strictEqual(addDays('2026-06-15', -7), '2026-06-08');
});

test('monthRange returns correct start/end for June 2026', () => {
  const r = monthRange(2026, 6);
  assert.strictEqual(r.start, '2026-06-01');
  assert.strictEqual(r.end, '2026-06-30');
});
