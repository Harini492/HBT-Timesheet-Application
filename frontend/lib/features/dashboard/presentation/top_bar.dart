import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/domain/auth_notifier.dart';
import '../../auth/presentation/change_password_dialog.dart';

/// A page header bar styled like a Material AppBar but used as a plain
/// widget (NOT Scaffold.appBar). This lets the hamburger button reach up to
/// the nearest ancestor Scaffold (owned by DashboardShell, which holds the
/// Drawer) via Scaffold.of(context), while still letting each screen inject
/// its own trailing actions (Save, week nav, month nav, etc.) next to the
/// title — matching the screenshots, where those controls live on the same
/// navy bar as the page title.
class PageHeader extends ConsumerWidget {
  final String title;
  final Widget? helpTooltip;
  final List<Widget> trailing;

  const PageHeader({
    super.key,
    required this.title,
    this.helpTooltip,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final user = ref.watch(authNotifierProvider).user;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    return Material(
      color: AppColors.navyPrimary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              if (!isWide)
                Builder(
                  builder: (innerContext) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(innerContext).openDrawer(),
                  ),
                )
              else
                const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.start,
                  spacing: 6,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (helpTooltip != null) helpTooltip!,
                  ],
                ),
              ),
              ...trailing,
              const SizedBox(width: 8),
              if (isWide)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'H\u00B7B\u00B7T',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: Colors.white),
                tooltip: 'Toggle dark mode',
                onPressed: () => ref.read(themeModeProvider.notifier).state = !isDark,
              ),
              PopupMenuButton<String>(
                icon: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
                onSelected: (value) {
                  if (value == 'change_password') {
                    showDialog(context: context, builder: (_) => const ChangePasswordDialog());
                  } else if (value == 'logout') {
                    ref.read(authNotifierProvider.notifier).logout();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Text(user?.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'change_password', child: Text('Change Password')),
                  const PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
