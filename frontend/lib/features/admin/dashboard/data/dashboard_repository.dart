import '../../../../core/network/api_client.dart';
import '../../../../core/config/api_constants.dart';
import 'dashboard_models.dart';

class DashboardRepository {
  final ApiClient apiClient;
  DashboardRepository({required this.apiClient});

  Future<DashboardSummary> getSummary() async {
    final response = await apiClient.get(ApiConstants.dashboardSummary);
    return DashboardSummary.fromJson(response.data as Map<String, dynamic>);
  }
}