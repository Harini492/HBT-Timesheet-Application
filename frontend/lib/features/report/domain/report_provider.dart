import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/errors/exceptions.dart';
import '../data/report_models.dart';

enum ReportLoadStatus { initial, loading, loaded, error }

class ReportState {
  final ReportLoadStatus status;
  final MonthlyReport? report;
  final int year;
  final int month;
  final String? errorMessage;

  ReportState({
    this.status = ReportLoadStatus.initial,
    this.report,
    int? year,
    int? month,
    this.errorMessage,
  })  : year = year ?? DateTime.now().year,
        month = month ?? DateTime.now().month;

  ReportState copyWith({
    ReportLoadStatus? status,
    MonthlyReport? report,
    int? year,
    int? month,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReportState(
      status: status ?? this.status,
      report: report ?? this.report,
      year: year ?? this.year,
      month: month ?? this.month,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  final Ref ref;
  ReportNotifier(this.ref) : super(ReportState());

  Future<void> load({int? year, int? month}) async {
    final y = year ?? state.year;
    final m = month ?? state.month;
    state = state.copyWith(status: ReportLoadStatus.loading, year: y, month: m, clearError: true);
    try {
      final repo = ref.read(reportRepositoryProvider);
      final report = await repo.getMonthlyReport(year: y, month: m);
      state = state.copyWith(status: ReportLoadStatus.loaded, report: report);
    } on AppException catch (e) {
      state = state.copyWith(status: ReportLoadStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(status: ReportLoadStatus.error, errorMessage: 'Failed to load report.');
    }
  }

  Future<void> previousMonth() async {
    var y = state.year;
    var m = state.month - 1;
    if (m < 1) {
      m = 12;
      y -= 1;
    }
    await load(year: y, month: m);
  }

  Future<void> nextMonth() async {
    var y = state.year;
    var m = state.month + 1;
    if (m > 12) {
      m = 1;
      y += 1;
    }
    await load(year: y, month: m);
  }
}

final reportNotifierProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  return ReportNotifier(ref);
});
