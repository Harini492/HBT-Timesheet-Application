import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/errors/exceptions.dart';
import '../../dashboard/presentation/top_bar.dart';
import '../../report/data/report_models.dart';

/// "Employee Absences" screen — lists any past weekday with zero logged
/// hours for the current employee (or, for admins, the selected employee),
/// for the current month-to-date by default.
class AbsencesScreen extends ConsumerStatefulWidget {
  const AbsencesScreen({super.key});

  @override
  ConsumerState<AbsencesScreen> createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends ConsumerState<AbsencesScreen> {
  AbsenceReport? _report;
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
      final report = await ref.read(absencesRepositoryProvider).getAbsences();
      setState(() => _report = report);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to load absences.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(title: 'Employee Absences'),
        Expanded(
          child: Builder(builder: (context) {
            if (_isLoading) return const LoadingView();
            if (_error != null) return ErrorView(message: _error!, onRetry: _load);
            final report = _report;
            if (report == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: report.absentDayCount > 0
                          ? AppColors.error.withOpacity(0.06)
                          : AppColors.success.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: report.absentDayCount > 0
                            ? AppColors.error.withOpacity(0.3)
                            : AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          report.absentDayCount > 0 ? Icons.warning_amber : Icons.check_circle_outline,
                          color: report.absentDayCount > 0 ? AppColors.error : AppColors.success,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${report.absentDayCount} day(s) with no logged hours between '
                            '${DateFormat('MMM d').format(DateTime.parse(report.start))} and '
                            '${DateFormat('MMM d, yyyy').format(DateTime.parse(report.end))} '
                            '(weekends and holidays excluded).',
                            style: const TextStyle(fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (report.absentDates.isEmpty)
                    const Expanded(
                      child: EmptyView(
                        message: 'No absences found — every working day has logged hours.',
                        icon: Icons.celebration_outlined,
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: report.absentDates.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final date = DateTime.parse(report.absentDates[i]);
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFFBE9E7),
                              child: Icon(Icons.event_busy, color: AppColors.error, size: 18),
                            ),
                            title: Text(DateFormat('EEEE, MMMM d, yyyy').format(date)),
                            subtitle: const Text('No hours logged'),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
