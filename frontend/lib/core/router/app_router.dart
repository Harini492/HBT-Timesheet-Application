import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_notifier.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_shell.dart';
import '../../features/timesheet/presentation/timesheet_screen.dart';
import '../../features/report/presentation/report_screen.dart';
import '../../features/holidays/presentation/holidays_screen.dart';
import '../../features/absences/presentation/absences_screen.dart';
import '../../features/admin/employees/presentation/employees_screen.dart';
import '../../features/admin/jobs/presentation/jobs_screen.dart';
import '../../features/admin/dashboard/presentation/admin_dashboard_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const login = '/login';
  static const timesheet = '/timesheet';
  static const report = '/report';
  static const holidays = '/holidays';
  static const absences = '/absences';
  static const adminEmployees = '/admin/employees';
  static const adminJobs = '/admin/jobs';
  static const adminDashboard = '/admin/dashboard';
}

/// Notifies GoRouter to re-evaluate `redirect` whenever auth state changes.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen<AuthState>(authNotifierProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthRefreshListenable(ref);

  return GoRouter(
    initialLocation: AppRoutes.timesheet,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final loggingIn = state.matchedLocation == AppRoutes.login;

      if (authState.status == AuthStatus.initial) {
        return null; // still restoring session; splash handled by router builder
      }
      if (!authState.isAuthenticated && !loggingIn) {
        return AppRoutes.login;
      }
      if (authState.isAuthenticated && loggingIn) {
        return authState.user?.isAdmin == true ? AppRoutes.adminDashboard : AppRoutes.timesheet;
      }
      // Admins manage Employees/Job Codes from their own Dashboard; the
      // personal timesheet entry, report, and absence screens are
      // employee-only (admins don't log their own hours), so block direct
      // URL access to them.
      final isAdmin = authState.user?.isAdmin == true;
      final isEmployeeOnlyRoute = state.matchedLocation == AppRoutes.timesheet ||
          state.matchedLocation == AppRoutes.report ||
          state.matchedLocation == AppRoutes.absences;
      if (isAdmin && isEmployeeOnlyRoute) {
        return AppRoutes.adminDashboard;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.timesheet, builder: (context, state) => const TimesheetScreen()),
          GoRoute(path: AppRoutes.report, builder: (context, state) => const ReportScreen()),
          GoRoute(path: AppRoutes.holidays, builder: (context, state) => const HolidaysScreen()),
          GoRoute(path: AppRoutes.absences, builder: (context, state) => const AbsencesScreen()),
          GoRoute(path: AppRoutes.adminEmployees, builder: (context, state) => const EmployeesScreen()),
          GoRoute(path: AppRoutes.adminJobs, builder: (context, state) => const JobsScreen()),
          GoRoute(path: AppRoutes.adminDashboard, builder: (context, state) => const AdminDashboardScreen()),
        ],
      ),
    ],
  );
});