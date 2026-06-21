import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/errors/exceptions.dart';
import '../data/timesheet_models.dart';

enum TimesheetLoadStatus { initial, loading, loaded, error }

class TimesheetState {
  final TimesheetLoadStatus status;
  final WeekGrid? grid;
  final List<AssignableJob> assignableJobs;
  final bool isSaving;
  final bool isDirty;
  final String? errorMessage;

  const TimesheetState({
    this.status = TimesheetLoadStatus.initial,
    this.grid,
    this.assignableJobs = const [],
    this.isSaving = false,
    this.isDirty = false,
    this.errorMessage,
  });

  TimesheetState copyWith({
    TimesheetLoadStatus? status,
    WeekGrid? grid,
    List<AssignableJob>? assignableJobs,
    bool? isSaving,
    bool? isDirty,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TimesheetState(
      status: status ?? this.status,
      grid: grid ?? this.grid,
      assignableJobs: assignableJobs ?? this.assignableJobs,
      isSaving: isSaving ?? this.isSaving,
      isDirty: isDirty ?? this.isDirty,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TimesheetNotifier extends StateNotifier<TimesheetState> {
  final Ref ref;
  TimesheetNotifier(this.ref) : super(const TimesheetState());

  Future<void> loadWeek(String weekStartISO) async {
    state = state.copyWith(status: TimesheetLoadStatus.loading, clearError: true);
    try {
      final repo = ref.read(timesheetRepositoryProvider);
      final grid = await repo.getWeek(weekStartISO);
      final jobs = await repo.getAssignedJobs();
      state = state.copyWith(
        status: TimesheetLoadStatus.loaded,
        grid: grid,
        assignableJobs: jobs,
        isDirty: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(status: TimesheetLoadStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        status: TimesheetLoadStatus.error,
        errorMessage: 'Failed to load timesheet.',
      );
    }
  }

  Future<void> goToPreviousWeek() async {
    final grid = state.grid;
    if (grid == null) return;
    final prev = DateTime.parse(grid.weekStart).subtract(const Duration(days: 7));
    await loadWeek(_toISO(prev));
  }

  Future<void> goToNextWeek() async {
    final grid = state.grid;
    if (grid == null) return;
    final next = DateTime.parse(grid.weekStart).add(const Duration(days: 7));
    await loadWeek(_toISO(next));
  }

  void updateHour(int jobId, String date, double hours) {
    final grid = state.grid;
    if (grid == null) return;
    final updatedRows = grid.rows.map((row) {
      if (row.jobId == jobId) return row.copyWithHour(date, hours);
      return row;
    }).toList();
    final newTotal = updatedRows.fold<double>(0, (sum, r) => sum + r.rowTotal);
    state = state.copyWith(
      grid: grid.copyWith(rows: updatedRows, totalHours: newTotal),
      isDirty: true,
    );
  }

  void addJobRow(AssignableJob job) {
    final grid = state.grid;
    if (grid == null) return;
    if (grid.rows.any((r) => r.jobId == job.id)) return;
    final hoursByDate = {for (final d in grid.dates) d: 0.0};
    final newRow = TimesheetRow(
      jobId: job.id,
      jobCode: job.jobCode,
      jobDescription: job.jobDescription,
      hoursByDate: hoursByDate,
      rowTotal: 0,
    );
    state = state.copyWith(grid: grid.copyWith(rows: [...grid.rows, newRow]), isDirty: true);
  }

  void removeJobRow(int jobId) {
    final grid = state.grid;
    if (grid == null) return;
    final updatedRows = grid.rows.where((r) => r.jobId != jobId).toList();
    final newTotal = updatedRows.fold<double>(0, (sum, r) => sum + r.rowTotal);
    state = state.copyWith(grid: grid.copyWith(rows: updatedRows, totalHours: newTotal), isDirty: true);
  }

  /// Returns a validation error string, or null if the grid is valid.
  String? validate() {
    final grid = state.grid;
    if (grid == null) return null;
    for (final row in grid.rows) {
      for (final entry in row.hoursByDate.entries) {
        if (entry.value < 0 || entry.value > 24) {
          return '${row.jobDescription}: hours on ${entry.key} must be between 0 and 24';
        }
      }
    }
    return null;
  }

  Future<bool> save() async {
    final grid = state.grid;
    if (grid == null) return false;

    final validationError = validate();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final entries = <Map<String, dynamic>>[];
      for (final row in grid.rows) {
        for (final entry in row.hoursByDate.entries) {
          entries.add({'jobId': row.jobId, 'date': entry.key, 'hours': entry.value});
        }
      }
      final repo = ref.read(timesheetRepositoryProvider);
      final updated = await repo.saveWeek(weekStartISO: grid.weekStart, entries: entries);
      state = state.copyWith(grid: updated, isSaving: false, isDirty: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(isSaving: false, errorMessage: 'Failed to save timesheet.');
      return false;
    }
  }

  String _toISO(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

final timesheetNotifierProvider =
    StateNotifierProvider<TimesheetNotifier, TimesheetState>((ref) {
  return TimesheetNotifier(ref);
});
