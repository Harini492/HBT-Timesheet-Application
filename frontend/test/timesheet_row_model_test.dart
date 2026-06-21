import 'package:flutter_test/flutter_test.dart';
import 'package:hbt_timesheet/features/timesheet/data/timesheet_models.dart';

void main() {
  test('TimesheetRow.copyWithHour updates hours and recalculates rowTotal', () {
    const row = TimesheetRow(
      jobId: 1,
      jobCode: '8888006',
      jobDescription: 'Aftermarket',
      hoursByDate: {'2026-06-15': 8, '2026-06-16': 0},
      rowTotal: 8,
    );

    final updated = row.copyWithHour('2026-06-16', 6);

    expect(updated.hoursByDate['2026-06-16'], 6);
    expect(updated.rowTotal, 14);
    // Original row is unchanged (immutability).
    expect(row.hoursByDate['2026-06-16'], 0);
  });

  test('WeekGrid.fromJson parses nested rows correctly', () {
    final json = {
      'weekStart': '2026-06-15',
      'weekEnd': '2026-06-21',
      'dates': ['2026-06-15', '2026-06-16'],
      'totalHours': 8,
      'rows': [
        {
          'jobId': 1,
          'jobCode': '8888006',
          'jobDescription': 'Aftermarket',
          'hoursByDate': {'2026-06-15': 8, '2026-06-16': 0},
          'rowTotal': 8,
        }
      ],
    };

    final grid = WeekGrid.fromJson(json);

    expect(grid.rows.length, 1);
    expect(grid.rows.first.jobDescription, 'Aftermarket');
    expect(grid.totalHours, 8);
  });
}
