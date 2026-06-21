import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../dashboard/presentation/top_bar.dart';
import '../data/employee_admin_model.dart';
import '../../jobs/data/job_admin_model.dart';

/// Admin-only "Employees" management screen: create employees, edit basic
/// details, deactivate, reset password, and assign/unassign jobs.
class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  List<EmployeeAdminModel>? _employees;
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
      final employees = await ref.read(employeesRepositoryProvider).list();
      setState(() => _employees = employees);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to load employees.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateDialog() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String role = 'employee';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Employee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Employee ID')),
                const SizedBox(height: 10),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 10),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email (optional)')),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Temporary Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'employee', child: Text('Employee')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setDialogState(() => role = v ?? 'employee'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (codeController.text.trim().isEmpty ||
                    nameController.text.trim().isEmpty ||
                    passwordController.text.length < 6) {
                  return;
                }
                try {
                  await ref.read(employeesRepositoryProvider).create(
                        employeeCode: codeController.text.trim(),
                        name: nameController.text.trim(),
                        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                        password: passwordController.text,
                        role: role,
                      );
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
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(EmployeeAdminModel emp) async {
    try {
      await ref.read(employeesRepositoryProvider).update(emp.id, isActive: !emp.isActive);
      _load();
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _showResetPasswordDialog(EmployeeAdminModel emp) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password — ${emp.name}'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length < 6) return;
              try {
                await ref.read(employeesRepositoryProvider).resetPassword(emp.id, controller.text);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset successfully')),
                  );
                }
              } on AppException catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _showJobAssignmentDialog(EmployeeAdminModel emp) async {
    List<JobAdminModel> allJobs;
    Set<int> assignedIds;
    try {
      allJobs = await ref.read(jobsRepositoryProvider).list();
      final assigned = await ref.read(employeesRepositoryProvider).assignedJobs(emp.id);
      assignedIds = assigned.map((j) => j['id'] as int).toSet();
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign Jobs — ${emp.name}'),
          content: SizedBox(
            width: 360,
            child: ListView(
              shrinkWrap: true,
              children: allJobs.map((job) {
                final isAssigned = assignedIds.contains(job.id);
                return CheckboxListTile(
                  title: Text(job.jobDescription),
                  subtitle: Text(job.jobCode),
                  value: isAssigned,
                  onChanged: (checked) async {
                    try {
                      final repo = ref.read(employeesRepositoryProvider);
                      if (checked == true) {
                        await repo.assignJob(emp.id, job.id);
                        assignedIds.add(job.id);
                      } else {
                        await repo.unassignJob(emp.id, job.id);
                        assignedIds.remove(job.id);
                      }
                      setDialogState(() {});
                    } on AppException catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    }
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        PageHeader(title: 'Employees'),
        Expanded(
          child: Builder(builder: (context) {
            if (_isLoading) return const LoadingView();
            if (_error != null) return ErrorView(message: _error!, onRetry: _load);
            final employees = _employees ?? [];
            if (employees.isEmpty) {
              return const EmptyView(message: 'No employees yet. Tap + to add one.', icon: Icons.people_outline);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: employees.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final emp = employees[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: emp.isActive ? AppColors.rowHighlight : Colors.grey[300],
                    child: Text(
                      emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                      style: TextStyle(color: emp.isActive ? AppColors.navyPrimary : Colors.grey),
                    ),
                  ),
                  title: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${emp.employeeCode}  ·  ${emp.role}${emp.isActive ? '' : '  ·  inactive'}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'jobs') _showJobAssignmentDialog(emp);
                      if (value == 'reset') _showResetPasswordDialog(emp);
                      if (value == 'toggle') _toggleActive(emp);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'jobs', child: Text('Assign Jobs')),
                      const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
                      PopupMenuItem(value: 'toggle', child: Text(emp.isActive ? 'Deactivate' : 'Activate')),
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
            onPressed: _showCreateDialog,
child: const Icon(Icons.add, color: Colors.white),          ),
        ),
      ],
    );
  }
}
