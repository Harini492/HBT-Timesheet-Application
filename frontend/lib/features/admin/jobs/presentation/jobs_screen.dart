import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../dashboard/presentation/top_bar.dart';
import '../data/job_admin_model.dart';

/// Admin-only "Job Codes" management screen: create/edit/deactivate jobs.
class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  List<JobAdminModel>? _jobs;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final jobs = await ref.read(jobsRepositoryProvider).list();
      setState(() => _jobs = jobs);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to load jobs.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showJobDialog({JobAdminModel? existing}) {
    final codeController = TextEditingController(text: existing?.jobCode ?? '');
    final descController = TextEditingController(text: existing?.jobDescription ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Create Job Code' : 'Edit Job Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Job Code'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Job Description'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.trim().isEmpty || descController.text.trim().isEmpty) return;
              try {
                final repo = ref.read(jobsRepositoryProvider);
                if (existing == null) {
                  await repo.create(
                    jobCode: codeController.text.trim(),
                    jobDescription: descController.text.trim(),
                  );
                } else {
                  await repo.update(
                    existing.id,
                    jobCode: codeController.text.trim(),
                    jobDescription: descController.text.trim(),
                  );
                }
                if (mounted) {
                  Navigator.of(context).pop();
                  _load();
                }
              } on AppException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(JobAdminModel job) async {
    try {
      await ref.read(jobsRepositoryProvider).update(job.id, isActive: !job.isActive);
      _load();
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        PageHeader(title: 'Job Codes'),
        Expanded(
          child: Builder(builder: (context) {
            if (_isLoading) return const LoadingView();
            if (_error != null) return ErrorView(message: _error!, onRetry: _load);
            final jobs = _jobs ?? [];
            if (jobs.isEmpty) {
              return const EmptyView(message: 'No job codes yet. Tap + to create one.', icon: Icons.work_outline);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final job = jobs[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: job.isActive ? AppColors.rowHighlight : Colors.grey[300],
                    child: Icon(Icons.work_outline,
                        color: job.isActive ? AppColors.navyPrimary : Colors.grey, size: 18),
                  ),
                  title: Text(job.jobDescription, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${job.jobCode}${job.isActive ? '' : '  ·  inactive'}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _showJobDialog(existing: job);
                      if (value == 'toggle') _toggleActive(job);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'toggle', child: Text(job.isActive ? 'Deactivate' : 'Activate')),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    );

    return Stack(
      children: [
        body,
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            backgroundColor: AppColors.navyPrimary,
            onPressed: () => _showJobDialog(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
