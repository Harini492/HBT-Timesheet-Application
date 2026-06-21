import '../../../core/network/api_client.dart';
import '../../../core/config/api_constants.dart';
import 'timesheet_models.dart';

class TimesheetRepository {
  final ApiClient apiClient;
  TimesheetRepository({required this.apiClient});

  Future<WeekGrid> getWeek(String weekStartISO) async {
    final response = await apiClient.get(ApiConstants.timesheet, query: {'weekStart': weekStartISO});
    return WeekGrid.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AssignableJob>> getAssignedJobs() async {
    final response = await apiClient.get(ApiConstants.jobs);
    final data = response.data as Map<String, dynamic>;
    return (data['jobs'] as List<dynamic>)
        .map((e) => AssignableJob.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WeekGrid> saveWeek({
    required String weekStartISO,
    required List<Map<String, dynamic>> entries,
  }) async {
    final response = await apiClient.post(ApiConstants.timesheet, data: {
      'weekStart': weekStartISO,
      'entries': entries,
    });
    return WeekGrid.fromJson(response.data as Map<String, dynamic>);
  }
}
