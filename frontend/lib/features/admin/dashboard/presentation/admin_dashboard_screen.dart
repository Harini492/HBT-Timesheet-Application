import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../dashboard/presentation/top_bar.dart';
import '../domain/dashboard_provider.dart';

/// Admin-only landing page: headcount + hours summary cards for the
/// current day/week/month. Replaces "Update Timesheet" / "Timesheet
/// Report" / "Employee Absences" as the admin's entry point, since none
/// of those make sense for an account that doesn't log its own hours.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardNotifierProvider);
    final summary = state.summary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const PageHeader(title: 'Dashboard'),
        Expanded(
          child: Builder(builder: (context) {
            if (state.status == DashboardLoadStatus.loading && summary == null) {
              return const LoadingView(message: 'Loading dashboard...');
            }
            if (state.status == DashboardLoadStatus.error) {
              return ErrorView(
                message: state.errorMessage ?? 'Failed to load dashboard',
                onRetry: () => ref.read(dashboardNotifierProvider.notifier).load(),
              );
            }
            if (summary == null) return const SizedBox.shrink();

            return RefreshIndicator(
              onRefresh: () => ref.read(dashboardNotifierProvider.notifier).load(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!summary.isWorkingDay)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFFFF6E0),
                          border: Border.all(
                            color: isDark ? Colors.white24 : const Color(0xFFE6D08A),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_busy_outlined,
                                color: isDark ? Colors.white70 : AppColors.warning, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Today isn't a working day (weekend or holiday), so today's attendance "
                                "isn't tracked.",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? Colors.white70 : AppColors.navyPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      final cards = <Widget>[
                        _StatCard(
                          icon: Icons.groups_outlined,
                          label: 'Total Employees',
                          value: '${summary.totalEmployees}',
                          color: AppColors.accentBlue,
                        ),
                        _StatCard(
                          icon: Icons.check_circle_outline,
                          label: 'Present Today',
                          value: '${summary.presentToday}',
                          color: AppColors.success,
                        ),
                        _StatCard(
                          icon: Icons.cancel_outlined,
                          label: 'Absent Today',
                          value: '${summary.absentToday}',
                          color: AppColors.error,
                        ),
                        _StatCard(
                          icon: Icons.schedule_outlined,
                          label: "This Week's Hours",
                          value: _formatHours(summary.weekTotalHours),
                          color: AppColors.navyLight,
                        ),
                        _StatCard(
                          icon: Icons.calendar_month_outlined,
                          label: "This Month's Hours",
                          value: _formatHours(summary.monthTotalHours),
                          color: AppColors.navyLight,
                        ),
                        _StatCard(
                          icon: Icons.trending_up_outlined,
                          label: 'Avg Hours / Employee (week)',
                          value: _formatHours(summary.averageWeekHoursPerEmployee),
                          color: AppColors.accentBlue,
                        ),
                      ];

                      if (isWide) {
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.1,
                          children: cards,
                        );
                      }
                      return Column(
                        children: cards
                            .map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c))
                            .toList(),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  String _formatHours(double hours) {
    final rounded = hours == hours.roundToDouble() ? hours.toInt().toString() : hours.toStringAsFixed(1);
    return '$rounded hrs';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white24 : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.navyPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}