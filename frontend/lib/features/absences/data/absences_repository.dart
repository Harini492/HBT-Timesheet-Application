import '../../../core/network/api_client.dart';
import '../../../core/config/api_constants.dart';
import '../../report/data/report_models.dart';

class AbsencesRepository {
  final ApiClient apiClient;
  AbsencesRepository({required this.apiClient});

  Future<AbsenceReport> getAbsences({String? start, String? end, int? employeeId}) async {
    final query = <String, dynamic>{};
    if (start != null) query['start'] = start;
    if (end != null) query['end'] = end;
    if (employeeId != null) query['employeeId'] = employeeId;
    final response = await apiClient.get(ApiConstants.reportAbsence, query: query);
    return AbsenceReport.fromJson(response.data as Map<String, dynamic>);
  }
}
