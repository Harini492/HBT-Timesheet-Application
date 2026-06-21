import '../../../core/network/api_client.dart';
import '../../../core/config/api_constants.dart';
import 'holiday_model.dart';

class HolidaysRepository {
  final ApiClient apiClient;
  HolidaysRepository({required this.apiClient});

  Future<List<Holiday>> list({int? year}) async {
    final response = await apiClient.get(
      ApiConstants.holidays,
      query: year != null ? {'year': year} : null,
    );
    final data = response.data as Map<String, dynamic>;
    return (data['holidays'] as List<dynamic>)
        .map((e) => Holiday.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Holiday> create({required String date, required String name}) async {
    final response = await apiClient.post(ApiConstants.holidays, data: {'date': date, 'name': name});
    final data = response.data as Map<String, dynamic>;
    return Holiday.fromJson(data['holiday'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await apiClient.delete('${ApiConstants.holidays}/$id');
  }
}
