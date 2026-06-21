import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/domain/auth_notifier.dart';

/// Replica of the provided sidebar screenshot: greeting header, nav items
/// with icons, Logout pinned at the bottom. Admin users additionally see
/// the Employees / Job Codes management items.
class AppSidebar extends ConsumerWidget {
  final String currentPath;
  final VoidCallback? onNavigate;

  const AppSidebar({super.key, required this.currentPath, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    final isAdmin = user?.isAdmin == true;

    final items = <_NavItem>[
      if (isAdmin) _NavItem(Icons.dashboard_outlined, 'Dashboard', AppRoutes.adminDashboard),
      if (!isAdmin) ...[
        _NavItem(Icons.edit_calendar_outlined, 'Update Timesheet', AppRoutes.timesheet),
        _NavItem(Icons.grid_on_outlined, 'Timesheet Report', AppRoutes.report),
      ],
      _NavItem(Icons.event_note_outlined, 'Global Holidays', AppRoutes.holidays),
      if (!isAdmin) _NavItem(Icons.beach_access_outlined, 'Employee Absences', AppRoutes.absences),
      if (isAdmin) ...[
        _NavItem(Icons.people_alt_outlined, 'Employees', AppRoutes.adminEmployees),
        _NavItem(Icons.work_outline, 'Job Codes', AppRoutes.adminJobs),
      ],
    ];

    return Container(
      color: AppColors.navyPrimary,
      width: 280,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hi,', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    user?.name ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: items.map((item) => _buildNavTile(context, item)).toList(),
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text('Logout', style: TextStyle(color: Colors.white70)),
              onTap: () async {
                onNavigate?.call();
                await ref.read(authNotifierProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile(BuildContext context, _NavItem item) {
    final isActive = currentPath == item.route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isActive ? AppColors.navyLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          leading: Icon(item.icon, color: Colors.white),
          title: Text(
            item.label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: () {
            onNavigate?.call();
            context.go(item.route);
          },
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.label, this.route);
}