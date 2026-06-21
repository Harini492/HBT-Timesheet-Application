import 'package:equatable/equatable.dart';

class MonthlyReportJobRow extends Equatable {
  final int jobId;
  final String jobCode;
  final String jobDescription;
  final double total;
  final Map<String, double> dailyHours; // ISO date -> hours

  const MonthlyReportJobRow({
    required this.jobId,
    required this.jobCode,
    required this.jobDescription,
    required this.total,
    required this.dailyHours,
  });

  factory MonthlyReportJobRow.fromJson(Map<String, dynamic> json) {
    final daily = (json['dailyHours'] as Map<String, dynamic>? ?? {});
    return MonthlyReportJobRow(
      jobId: json['jobId'] as int,
      jobCode: json['jobCode'] as String,
      jobDescription: json['jobDescription'] as String,
      total: (json['total'] as num? ?? 0).toDouble(),
      dailyHours: daily.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  @override
  List<Object?> get props => [jobId, jobCode, jobDescription, total, dailyHours];
}

class MonthlyReport extends Equatable {
  final int year;
  final int month;
  final String start;
  final String end;
  final List<MonthlyReportJobRow> jobs;
  final double totalHours;

  const MonthlyReport({
    required this.year,
    required this.month,
    required this.start,
    required this.end,
    required this.jobs,
    required this.totalHours,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      year: json['year'] as int,
      month: json['month'] as int,
      start: json['start'] as String,
      end: json['end'] as String,
      jobs: (json['jobs'] as List<dynamic>)
          .map((e) => MonthlyReportJobRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalHours: (json['totalHours'] as num? ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [year, month, start, end, jobs, totalHours];
}

class AbsenceReport extends Equatable {
  final int employeeId;
  final String start;
  final String end;
  final List<String> absentDates;
  final int absentDayCount;

  const AbsenceReport({
    required this.employeeId,
    required this.start,
    required this.end,
    required this.absentDates,
    required this.absentDayCount,
  });

  factory AbsenceReport.fromJson(Map<String, dynamic> json) {
    return AbsenceReport(
      employeeId: json['employeeId'] as int,
      start: json['start'] as String,
      end: json['end'] as String,
      absentDates: (json['absentDates'] as List<dynamic>).map((e) => e as String).toList(),
      absentDayCount: json['absentDayCount'] as int,
    );
  }

  @override
  List<Object?> get props => [employeeId, start, end, absentDates, absentDayCount];
}
