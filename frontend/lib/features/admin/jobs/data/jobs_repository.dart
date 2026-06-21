import '../../../../core/network/api_client.dart';
import '../../../../core/config/api_constants.dart';
import 'job_admin_model.dart';

class JobsRepository {
  final ApiClient apiClient;
  JobsRepository({required this.apiClient});

  Future<List<JobAdminModel>> list() async {
    final response = await apiClient.get(ApiConstants.jobs);
    final data = response.data as Map<String, dynamic>;
    return (data['jobs'] as List<dynamic>)
        .map((e) => JobAdminModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<JobAdminModel> create({required String jobCode, required String jobDescription}) async {
    final response = await apiClient.post(ApiConstants.jobs, data: {
      'jobCode': jobCode,
      'jobDescription': jobDescription,
    });
    final data = response.data as Map<String, dynamic>;
    return JobAdminModel.fromJson(data['job'] as Map<String, dynamic>);
  }

  Future<void> update(int id, {String? jobCode, String? jobDescription, bool? isActive}) async {
    await apiClient.put('${ApiConstants.jobs}/$id', data: {
      if (jobCode != null) 'jobCode': jobCode,
      if (jobDescription != null) 'jobDescription': jobDescription,
      if (isActive != null) 'isActive': isActive,
    });
  }

  Future<void> delete(int id) async {
    await apiClient.delete('${ApiConstants.jobs}/$id');
  }
}
