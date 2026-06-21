import 'package:excel/excel.dart' as xls;
import 'package:intl/intl.dart';
import '../data/report_models.dart';

/// Builds and downloads a .xlsx file for a [MonthlyReport].
///
/// One sheet, one row per job code, one column per day of the month plus a
/// Total column. On Flutter Web, `excel.save()` triggers the browser
/// download directly — no extra platform-specific code needed.
class ReportExcelExporter {
  ReportExcelExporter._();

  static void exportMonthlyReport(MonthlyReport report) {
    final workbook = xls.Excel.createExcel();
    final sheetName = DateFormat('MMMM yyyy').format(DateTime(report.year, report.month));
    final sheet = workbook[sheetName];
    // Remove the default empty "Sheet1" so the workbook only has our sheet.
    if (workbook.sheets.keys.contains('Sheet1') && sheetName != 'Sheet1') {
      workbook.delete('Sheet1');
    }

    final daysInMonth = DateTime(report.year, report.month + 1, 0).day;
    final dayDates = List<DateTime>.generate(
      daysInMonth,
      (i) => DateTime(report.year, report.month, i + 1),
    );

    // Header row: Job Code | Job Description | 1 | 2 | ... | n | Total
    final headerCells = <xls.CellValue>[
      xls.TextCellValue('Job Code'),
      xls.TextCellValue('Job Description'),
      ...dayDates.map((d) => xls.TextCellValue('${d.day} ${DateFormat('EEE').format(d)}')),
      xls.TextCellValue('Total'),
    ];
    sheet.appendRow(headerCells);

    for (final job in report.jobs) {
      final row = <xls.CellValue>[
        xls.TextCellValue(job.jobCode),
        xls.TextCellValue(job.jobDescription),
        ...dayDates.map((d) {
          final key = DateFormat('yyyy-MM-dd').format(d);
          final hours = job.dailyHours[key] ?? 0;
          return xls.DoubleCellValue(hours);
        }),
        xls.DoubleCellValue(job.total),
      ];
      sheet.appendRow(row);
    }

    // Totals row across all jobs for each day, plus grand total.
    final totalsRow = <xls.CellValue>[
      xls.TextCellValue(''),
      xls.TextCellValue('Daily Total'),
      ...dayDates.map((d) {
        final key = DateFormat('yyyy-MM-dd').format(d);
        final dayTotal = report.jobs.fold<double>(0, (sum, j) => sum + (j.dailyHours[key] ?? 0));
        return xls.DoubleCellValue(dayTotal);
      }),
      xls.DoubleCellValue(report.totalHours),
    ];
    sheet.appendRow(totalsRow);

    final fileName =
        'HBT_Timesheet_${DateFormat('yyyy_MM').format(DateTime(report.year, report.month))}.xlsx';
    workbook.save(fileName: fileName);
  }
}