const db = require('../config/database');
const migrate = require('./migrate');
const { hashPassword } = require('../utils/password');
const { toISODate } = require('../utils/dateUtils');

function seed() {
  migrate();

  const employeeCount = db.prepare('SELECT COUNT(*) AS c FROM employees').get().c;
  if (employeeCount > 0) {
    console.log('Seed skipped: employees table is not empty. Delete the DB file to reseed.');
    return;
  }

  const insertEmployee = db.prepare(`
    INSERT INTO employees (employee_code, name, email, password_hash, role)
    VALUES (@employee_code, @name, @email, @password_hash, @role)
  `);

  const admin = insertEmployee.run({
    employee_code: 'ADMIN001',
    name: 'System Administrator',
    email: 'admin@hbt.com',
    password_hash: hashPassword('Admin@123'),
    role: 'admin',
  });

  const emp1 = insertEmployee.run({
    employee_code: 'EMP1001',
    name: 'Akilan Veerabatheren',
    email: 'akilan@hbt.com',
    password_hash: hashPassword('Employee@123'),
    role: 'employee',
  });

  const emp2 = insertEmployee.run({
    employee_code: 'EMP1002',
    name: 'Priya Raman',
    email: 'priya@hbt.com',
    password_hash: hashPassword('Employee@123'),
    role: 'employee',
  });

  const emp3 = insertEmployee.run({
    employee_code: 'EMP1003',
    name: 'John Mathew',
    email: 'john@hbt.com',
    password_hash: hashPassword('Employee@123'),
    role: 'employee',
  });

  const insertJob = db.prepare(`
    INSERT INTO jobs (job_code, job_description) VALUES (@job_code, @job_description)
  `);

  const jobAftermarket = insertJob.run({ job_code: '8888006', job_description: 'Aftermarket' });
  const jobVacation = insertJob.run({ job_code: '9999991', job_description: 'Vacation/Sick' });
  const jobInternal = insertJob.run({ job_code: '7777002', job_description: 'Internal Projects' });
  const jobSupport = insertJob.run({ job_code: '6666003', job_description: 'Customer Support' });
  const jobTraining = insertJob.run({ job_code: '5555004', job_description: 'Training' });

  const assign = db.prepare(`
    INSERT INTO employee_jobs (employee_id, job_id) VALUES (?, ?)
  `);

  const employeeIds = [emp1.lastInsertRowid, emp2.lastInsertRowid, emp3.lastInsertRowid];
  const allJobIds = [
    jobAftermarket.lastInsertRowid,
    jobVacation.lastInsertRowid,
    jobInternal.lastInsertRowid,
    jobSupport.lastInsertRowid,
    jobTraining.lastInsertRowid,
  ];

  for (const empId of employeeIds) {
    // Every employee gets Aftermarket + Vacation/Sick (matches screenshot), plus one extra.
    assign.run(empId, jobAftermarket.lastInsertRowid);
    assign.run(empId, jobVacation.lastInsertRowid);
  }
  assign.run(emp1.lastInsertRowid, jobInternal.lastInsertRowid);
  assign.run(emp2.lastInsertRowid, jobSupport.lastInsertRowid);
  assign.run(emp3.lastInsertRowid, jobTraining.lastInsertRowid);

  // Seed a sample saved week for emp1 matching the screenshot (15-21 Jun 2026, 8 hrs Monday on Aftermarket).
  const weekStart = '2026-06-15';
  const ts = db.prepare(`
    INSERT INTO timesheets (employee_id, week_start_date) VALUES (?, ?)
  `).run(emp1.lastInsertRowid, weekStart);

  db.prepare(`
    INSERT INTO timesheet_entries (timesheet_id, job_id, entry_date, hours)
    VALUES (?, ?, ?, ?)
  `).run(ts.lastInsertRowid, jobAftermarket.lastInsertRowid, weekStart, 8);

  const insertHoliday = db.prepare(`
    INSERT INTO holidays (holiday_date, name) VALUES (?, ?)
  `);
  const holidays2026 = [
    ['2026-01-01', "New Year's Day"],
    ['2026-01-26', 'Republic Day'],
    ['2026-03-29', 'Holi'],
    ['2026-05-01', 'Labour Day'],
    ['2026-08-15', 'Independence Day'],
    ['2026-10-02', 'Gandhi Jayanti'],
    ['2026-11-08', 'Diwali'],
    ['2026-12-25', 'Christmas Day'],
  ];
  for (const [date, name] of holidays2026) {
    insertHoliday.run(date, name);
  }

  console.log('Seed complete.');
  console.log('  Admin login:    ADMIN001 / Admin@123');
  console.log('  Employee login: EMP1001  / Employee@123  (Akilan Veerabatheren)');
  console.log('  Employee login: EMP1002  / Employee@123  (Priya Raman)');
  console.log('  Employee login: EMP1003  / Employee@123  (John Mathew)');
}

if (require.main === module) {
  seed();
}

module.exports = seed;
