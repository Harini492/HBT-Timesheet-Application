import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/timesheet/data/timesheet_repository.dart';
import '../../features/report/data/report_repository.dart';
import '../../features/holidays/data/holidays_repository.dart';
import '../../features/absences/data/absences_repository.dart';
import '../../features/admin/employees/data/employees_repository.dart';
import '../../features/admin/jobs/data/jobs_repository.dart';
import '../../features/admin/dashboard/data/dashboard_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: storage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(apiClient: ref.watch(apiClientProvider));
});

final timesheetRepositoryProvider = Provider<TimesheetRepository>((ref) {
  return TimesheetRepository(apiClient: ref.watch(apiClientProvider));
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(apiClient: ref.watch(apiClientProvider));
});

final holidaysRepositoryProvider = Provider<HolidaysRepository>((ref) {
  return HolidaysRepository(apiClient: ref.watch(apiClientProvider));
});

final absencesRepositoryProvider = Provider<AbsencesRepository>((ref) {
  return AbsencesRepository(apiClient: ref.watch(apiClientProvider));
});

final employeesRepositoryProvider = Provider<EmployeesRepository>((ref) {
  return EmployeesRepository(apiClient: ref.watch(apiClientProvider));
});

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  return JobsRepository(apiClient: ref.watch(apiClientProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(apiClient: ref.watch(apiClientProvider));
});

/// App-wide theme mode (light/dark), toggled from the top bar.
final themeModeProvider = StateProvider<bool>((ref) => false); // false = light, true = dark