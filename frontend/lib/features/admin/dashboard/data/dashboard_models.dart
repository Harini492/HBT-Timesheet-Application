import 'package:equatable/equatable.dart';

class DashboardSummary extends Equatable {
  final String today;
  final bool isWorkingDay;
  final String weekStart;
  final String weekEnd;
  final String monthStart;
  final String monthEnd;
  final int totalEmployees;
  final int presentToday;
  final int absentToday;
  final double weekTotalHours;
  final double monthTotalHours;
  final double averageWeekHoursPerEmployee;

  const DashboardSummary({
    required this.today,
    required this.isWorkingDay,
    required this.weekStart,
    required this.weekEnd,
    required this.monthStart,
    required this.monthEnd,
    required this.totalEmployees,
    required this.presentToday,
    required this.absentToday,
    required this.weekTotalHours,
    required this.monthTotalHours,
    required this.averageWeekHoursPerEmployee,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      today: json['today'] as String,
      isWorkingDay: json['isWorkingDay'] as bool? ?? true,
      weekStart: json['weekStart'] as String,
      weekEnd: json['weekEnd'] as String,
      monthStart: json['monthStart'] as String,
      monthEnd: json['monthEnd'] as String,
      totalEmployees: json['totalEmployees'] as int? ?? 0,
      presentToday: json['presentToday'] as int? ?? 0,
      absentToday: json['absentToday'] as int? ?? 0,
      weekTotalHours: (json['weekTotalHours'] as num? ?? 0).toDouble(),
      monthTotalHours: (json['monthTotalHours'] as num? ?? 0).toDouble(),
      averageWeekHoursPerEmployee: (json['averageWeekHoursPerEmployee'] as num? ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        today,
        isWorkingDay,
        weekStart,
        weekEnd,
        monthStart,
        monthEnd,
        totalEmployees,
        presentToday,
        absentToday,
        weekTotalHours,
        monthTotalHours,
        averageWeekHoursPerEmployee,
      ];
}