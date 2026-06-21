import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../dashboard/presentation/top_bar.dart';
import '../domain/timesheet_provider.dart';
import 'timesheet_grid_header.dart';
import 'timesheet_row_widget.dart';
import 'add_job_row_picker.dart';

class TimesheetScreen extends ConsumerStatefulWidget {
  const TimesheetScreen({super.key});

  @override
  ConsumerState<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends ConsumerState<TimesheetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = DateTime.now();
      final iso = DateFormat('yyyy-MM-dd').format(today);
      ref.read(timesheetNotifierProvider.notifier).loadWeek(iso);
    });
  }

  /// Monday of the week containing [date]. Mirrors the backend's
  /// getWeekStart() in dateUtils.js (Mon-Sun weeks, plain calendar dates).
  DateTime _mondayOf(DateTime date) {
    final day = date.weekday; // 1=Mon..7=Sun
    return DateTime(date.year, date.month, date.day - (day - 1));
  }

  void _goToCurrentWeek() {
    final iso = DateFormat('yyyy-MM-dd').format(_mondayOf(DateTime.now()));
    ref.read(timesheetNotifierProvider.notifier).loadWeek(iso);
  }

  Future<void> _handleSave() async {
    final success = await ref.read(timesheetNotifierProvider.notifier).save();
    if (!mounted) return;
    final state = ref.read(timesheetNotifierProvider);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timesheet saved successfully'), backgroundColor: AppColors.success),
      );
    } else if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.error),
      );
    }
  }

  void _showAddJobDialog() {
    // Kept as an alternate entry point for adding a job row (e.g. could be
    // wired to a header icon). The grid's inline AddJobRowPicker is the
    // primary way to add a job row; this bottom sheet offers the same
    // action in a tap-friendly list form, useful on narrow/mobile layouts.
    final state = ref.read(timesheetNotifierProvider);
    final grid = state.grid;
    if (grid == null) return;
    final existingIds = grid.rows.map((r) => r.jobId).toSet();
    final available = state.assignableJobs.where((j) => !existingIds.contains(j.id)).toList();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add a job to this week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              if (available.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('All assigned jobs are already on this timesheet.'),
                ),
              ...available.map((job) => ListTile(
                    title: Text(job.jobDescription),
                    subtitle: Text(job.jobCode),
                    onTap: () {
                      ref.read(timesheetNotifierProvider.notifier).addJobRow(job);
                      Navigator.of(context).pop();
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timesheetNotifierProvider);
    final grid = state.grid;

    final existingIds = grid?.rows.map((r) => r.jobId).toSet() ?? <int>{};
    final availableToAdd =
        state.assignableJobs.where((j) => !existingIds.contains(j.id)).toList();

    return Column(
      children: [
        PageHeader(
          title: 'Update Timesheet',
          helpTooltip: Tooltip(
            message: 'Enter hours per job per day, then Save. Hours must be between 0 and 24.',
            child: Icon(Icons.help_outline, color: Colors.white.withOpacity(0.8), size: 18),
          ),
          trailing: [
            if (grid != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total hours', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(
                      '${grid.totalHours.toStringAsFixed(grid.totalHours == grid.totalHours.roundToDouble() ? 0 : 1)} hrs',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => ref.read(timesheetNotifierProvider.notifier).goToPreviousWeek(),
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 18),
                label: const Text('Go to Last Week', style: TextStyle(color: Colors.white, fontSize: 12)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54)),
              ),
              const SizedBox(width: 8),
              Builder(builder: (context) {
                final isCurrentWeek = grid.weekStart ==
                    DateFormat('yyyy-MM-dd').format(_mondayOf(DateTime.now()));
                return Row(
                  children: [
                    OutlinedButton(
                      onPressed: isCurrentWeek ? null : _goToCurrentWeek,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isCurrentWeek ? Colors.white24 : Colors.white54),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white38,
                      ),
                      child: Text(
                        'Current Week',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCurrentWeek ? Colors.white38 : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: isCurrentWeek
                          ? null
                          : () => ref.read(timesheetNotifierProvider.notifier).goToNextWeek(),
                      icon: Icon(Icons.chevron_right,
                          color: isCurrentWeek ? Colors.white38 : Colors.white, size: 18),
                      label: Text('Next Week',
                          style: TextStyle(color: isCurrentWeek ? Colors.white38 : Colors.white, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isCurrentWeek ? Colors.white24 : Colors.white54),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_box_outlined, color: Colors.white),
                tooltip: 'Add Job',
                onPressed: availableToAdd.isEmpty ? null : _showAddJobDialog,
              ),
              ElevatedButton.icon(
                onPressed: state.isSaving ? null : _handleSave,
                icon: state.isSaving
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyPrimary),
                      )
                    : const Icon(Icons.save, size: 16),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.navyPrimary),
              ),
            ],
          ],
        ),
        Expanded(
          child: Builder(builder: (context) {
            if (state.status == TimesheetLoadStatus.loading) {
              return const LoadingView(message: 'Loading timesheet...');
            }
            if (state.status == TimesheetLoadStatus.error) {
              return ErrorView(
                message: state.errorMessage ?? 'Failed to load timesheet',
                onRetry: () {
                  final iso = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  ref.read(timesheetNotifierProvider.notifier).loadWeek(iso);
                },
              );
            }
            if (grid == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FB),
                      border: Border.all(color: const Color(0xFFBBD6F2)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.accentBlue, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "If you are not seeing your projects, please contact your Team Lead / "
                            "Project Manager to add your name to the Job Code's Team Members list in "
                            "the system. Please contact support if the issue persists even after that.",
                            style: TextStyle(fontSize: 12.5, color: AppColors.navyPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 220 + 110 + (130 * 7) + 40,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TimesheetGridHeader(dates: grid.dates),
                              if (grid.rows.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Text(
                                    'No jobs added yet. Use "Add Job" below to start logging hours.',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                )
                              else
                                ...grid.rows.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final row = entry.value;
                                  return TimesheetRowWidget(
                                    row: row,
                                    dates: grid.dates,
                                    isAlternate: i.isEven,
                                    onHourChanged: (date, hours) => ref
                                        .read(timesheetNotifierProvider.notifier)
                                        .updateHour(row.jobId, date, hours),
                                    onRemove: () => ref
                                        .read(timesheetNotifierProvider.notifier)
                                        .removeJobRow(row.jobId),
                                  );
                                }),
                              AddJobRowPicker(
                                availableJobs: availableToAdd,
                                onAdd: (job) =>
                                    ref.read(timesheetNotifierProvider.notifier).addJobRow(job),
                              ),
                            ],
                          ),
                        ),
                      ),
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