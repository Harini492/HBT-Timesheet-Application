import 'package:equatable/equatable.dart';

class TimesheetRow extends Equatable {
  final int jobId;
  final String jobCode;
  final String jobDescription;
  final Map<String, double> hoursByDate; // ISO date -> hours
  final double rowTotal;

  const TimesheetRow({
    required this.jobId,
    required this.jobCode,
    required this.jobDescription,
    required this.hoursByDate,
    required this.rowTotal,
  });

  factory TimesheetRow.fromJson(Map<String, dynamic> json) {
    final hoursJson = (json['hoursByDate'] as Map<String, dynamic>? ?? {});
    return TimesheetRow(
      jobId: json['jobId'] as int,
      jobCode: json['jobCode'] as String,
      jobDescription: json['jobDescription'] as String,
      hoursByDate: hoursJson.map((k, v) => MapEntry(k, (v as num).toDouble())),
      rowTotal: (json['rowTotal'] as num? ?? 0).toDouble(),
    );
  }

  TimesheetRow copyWithHour(String date, double hours) {
    final updated = Map<String, double>.from(hoursByDate);
    updated[date] = hours;
    final total = updated.values.fold<double>(0, (sum, h) => sum + h);
    return TimesheetRow(
      jobId: jobId,
      jobCode: jobCode,
      jobDescription: jobDescription,
      hoursByDate: updated,
      rowTotal: total,
    );
  }

  @override
  List<Object?> get props => [jobId, jobCode, jobDescription, hoursByDate, rowTotal];
}

class WeekGrid extends Equatable {
  final String weekStart;
  final String weekEnd;
  final List<String> dates;
  final List<TimesheetRow> rows;
  final double totalHours;

  const WeekGrid({
    required this.weekStart,
    required this.weekEnd,
    required this.dates,
    required this.rows,
    required this.totalHours,
  });

  factory WeekGrid.fromJson(Map<String, dynamic> json) {
    return WeekGrid(
      weekStart: json['weekStart'] as String,
      weekEnd: json['weekEnd'] as String,
      dates: (json['dates'] as List<dynamic>).map((e) => e as String).toList(),
      rows: (json['rows'] as List<dynamic>)
          .map((e) => TimesheetRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalHours: (json['totalHours'] as num? ?? 0).toDouble(),
    );
  }

  WeekGrid copyWith({List<TimesheetRow>? rows, double? totalHours}) {
    return WeekGrid(
      weekStart: weekStart,
      weekEnd: weekEnd,
      dates: dates,
      rows: rows ?? this.rows,
      totalHours: totalHours ?? this.totalHours,
    );
  }

  @override
  List<Object?> get props => [weekStart, weekEnd, dates, rows, totalHours];
}

class AssignableJob extends Equatable {
  final int id;
  final String jobCode;
  final String jobDescription;

  const AssignableJob({required this.id, required this.jobCode, required this.jobDescription});

  factory AssignableJob.fromJson(Map<String, dynamic> json) {
    return AssignableJob(
      id: json['id'] as int,
      jobCode: (json['job_code'] ?? json['jobCode']) as String,
      jobDescription: (json['job_description'] ?? json['jobDescription']) as String,
    );
  }

  @override
  List<Object?> get props => [id, jobCode, jobDescription];
}
