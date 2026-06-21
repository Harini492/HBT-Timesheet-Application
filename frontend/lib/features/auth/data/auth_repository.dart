import '../../../core/network/api_client.dart';
import '../../../core/config/api_constants.dart';
import '../../../core/models/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;
  AuthRepository({required this.apiClient});

  Future<({String token, UserModel user})> login({
    required String employeeCode,
    required String password,
  }) async {
    final response = await apiClient.post(ApiConstants.login, data: {
      'employeeCode': employeeCode,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    return (token: token, user: user);
  }

  Future<void> logout() async {
    await apiClient.post(ApiConstants.logout);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await apiClient.post(ApiConstants.changePassword, data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<UserModel> me() async {
    final response = await apiClient.get(ApiConstants.me);
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }
}
