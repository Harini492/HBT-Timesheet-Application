import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_constants.dart';
import 'sidebar.dart';

/// Responsive shell: a permanent sidebar on wide screens (matches the
/// always-visible nav implied by the screenshots), a Drawer on narrow
/// screens. The page title shown in the top bar is derived per-route by
/// each child screen via [DashboardShell.of] context lookups handled inside
/// each screen's own AppBar usage (screens supply their own AppTopBar).
class DashboardShell extends StatelessWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.wideBreakpoint;
    final currentPath = GoRouterState.of(context).matchedLocation;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar(currentPath: currentPath),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: Drawer(
        child: AppSidebar(
          currentPath: currentPath,
          onNavigate: () => Navigator.of(context).pop(),
        ),
      ),
      body: child,
    );
  }
}
