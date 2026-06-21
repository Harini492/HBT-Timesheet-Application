import '../../../../core/network/api_client.dart';
import '../../../../core/config/api_constants.dart';
import 'employee_admin_model.dart';

class EmployeesRepository {
  final ApiClient apiClient;
  EmployeesRepository({required this.apiClient});

  Future<List<EmployeeAdminModel>> list() async {
    final response = await apiClient.get(ApiConstants.employees);
    final data = response.data as Map<String, dynamic>;
    return (data['employees'] as List<dynamic>)
        .map((e) => EmployeeAdminModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EmployeeAdminModel> create({
    required String employeeCode,
    required String name,
    String? email,
    required String password,
    String role = 'employee',
  }) async {
    final response = await apiClient.post(ApiConstants.employees, data: {
      'employeeCode': employeeCode,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
    final data = response.data as Map<String, dynamic>;
    return EmployeeAdminModel.fromJson(data['employee'] as Map<String, dynamic>);
  }

  Future<void> update(int id, {String? name, String? email, bool? isActive}) async {
    await apiClient.put('${ApiConstants.employees}/$id', data: {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (isActive != null) 'isActive': isActive,
    });
  }

  Future<void> delete(int id) async {
    await apiClient.delete('${ApiConstants.employees}/$id');
  }

  Future<void> resetPassword(int id, String newPassword) async {
    await apiClient.post('${ApiConstants.employees}/$id/reset-password', data: {
      'newPassword': newPassword,
    });
  }

  Future<List<dynamic>> assignedJobs(int id) async {
    final response = await apiClient.get('${ApiConstants.employees}/$id/jobs');
    final data = response.data as Map<String, dynamic>;
    return data['jobs'] as List<dynamic>;
  }

  Future<void> assignJob(int employeeId, int jobId) async {
    await apiClient.post('${ApiConstants.employees}/$employeeId/jobs', data: {'jobId': jobId});
  }

  Future<void> unassignJob(int employeeId, int jobId) async {
    await apiClient.delete('${ApiConstants.employees}/$employeeId/jobs/$jobId');
  }
}
