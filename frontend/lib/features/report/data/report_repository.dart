import '../../../core/network/api_client.dart';
import '../../../core/config/api_constants.dart';
import 'report_models.dart';

class ReportRepository {
  final ApiClient apiClient;
  ReportRepository({required this.apiClient});

  Future<MonthlyReport> getMonthlyReport({required int year, required int month}) async {
    final response = await apiClient.get(ApiConstants.reportMonthly, query: {
      'year': year,
      'month': month,
    });
    return MonthlyReport.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AbsenceReport> getAbsenceReport({String? start, String? end}) async {
    final query = <String, dynamic>{};
    if (start != null) query['start'] = start;
    if (end != null) query['end'] = end;
    final response = await apiClient.get(ApiConstants.reportAbsence, query: query);
    return AbsenceReport.fromJson(response.data as Map<String, dynamic>);
  }
}
