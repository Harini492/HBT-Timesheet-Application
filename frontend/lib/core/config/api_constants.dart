/// API endpoint configuration.
///
/// `baseUrl` defaults to the Android emulator loopback (10.0.2.2) which maps
/// to the host machine's localhost. Override with --dart-define=API_BASE_URL=...
/// for iOS simulator (use http://localhost:4000) or a real device (use your
/// machine's LAN IP).
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );

  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String changePassword = '/auth/change-password';
  static const String me = '/auth/me';

  static const String employees = '/employees';
  static const String jobs = '/jobs';
  static const String timesheet = '/timesheet';
  static const String week = '/week';
  static const String reportMonthly = '/report/monthly';
  static const String reportAbsence = '/report/absence';
  static const String holidays = '/holidays';
  static const String dashboardSummary = '/dashboard/summary';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}